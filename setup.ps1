#Requires -Version 5.1
<#
.SYNOPSIS
Links this repository's skills and agents into the Claude Code config directory.

.DESCRIPTION
Each artifact is linked individually, never the parent skills/ or agents/
directory. Those are namespaces owned by Claude Code and shared with anything
else installed there; replacing one with a link would mean destroying its
contents first. See docs/conventions.md, decision C5.

Skills are directories, so they are linked with a junction, which needs neither
elevation nor Developer Mode. Agents are single .md files, for which only a
symbolic link will do, and that does require the privilege. Agents are reported
as BLOCKED when it is missing rather than silently substituting a hardlink,
which git pull would detach without any visible symptom.

This script never deletes real content. -Force moves it aside instead.

.PARAMETER DryRun
Print the plan and exit. Creates nothing.

.PARAMETER Force
Replace links that point elsewhere, and move a real file or directory in the
way into a timestamped backup before linking. Never deletes anything.

.PARAMETER Uninstall
Remove only links that resolve into this repository.

.PARAMETER AllowCopyFallback
When symbolic links are unavailable, copy agent files instead of skipping them.
Copies do not track git pull and must be refreshed with -Force after each one.

.NOTES
The config directory is $env:CLAUDE_CONFIG_DIR, or ~/.claude when it is unset.

templates/ is deliberately never linked: those files are meant to be copied into
a project and diverge there.

Statuses: CREATED, OK, RELINKED, REPAIRED, BACKED-UP, CONFLICT, OCCUPIED,
          INVALID, BLOCKED, REMOVED.
Exit codes: 0 clean, 1 error, 2 finished with items skipped.
#>
[CmdletBinding()]
param(
	[switch]$DryRun,
	[switch]$Force,
	[switch]$Uninstall,
	[switch]$AllowCopyFallback
)

$ErrorActionPreference = 'Stop'

# Resolve from the script's own location, never the caller's working directory.
$RepoRoot = $PSScriptRoot
if ([string]::IsNullOrEmpty($env:CLAUDE_CONFIG_DIR)) {
	$ConfigDir = Join-Path $env:USERPROFILE '.claude'
} else {
	$ConfigDir = $env:CLAUDE_CONFIG_DIR
}
$BackupDir = Join-Path $ConfigDir (".backup-" + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))

$script:Skipped = 0
$script:Linked = 0
$script:Total = 0
$script:BlockedAgents = 0
$script:MadeBackup = $false

function Write-Status([string]$Status, [string]$Kind, [string]$Message) {
	Write-Host ("  {0,-10} {1,-6} {2}" -f $Status, $Kind, $Message)
}

# Absolute, comparable form of a path. Junction targets come back with the
# \??\ device prefix on some builds, and trailing separators vary.
function Resolve-Comparable([string]$Path) {
	if ([string]::IsNullOrEmpty($Path)) { return '' }
	$p = $Path
	if ($p.StartsWith('\??\')) { $p = $p.Substring(4) }
	try { $p = [IO.Path]::GetFullPath($p) } catch { }
	return $p.TrimEnd('\', '/').ToLowerInvariant()
}

# Returns the link's target, or $null when the path is not a link at all.
function Get-LinkTarget([string]$Path) {
	$item = Get-Item -LiteralPath $Path -Force
	if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $null }

	$target = $item.Target
	if ($target -is [array]) {
		if ($target.Count -gt 0) { $target = $target[0] } else { $target = $null }
	}

	# PowerShell 5.1 leaves .Target empty for junctions on some builds, so ask
	# the filesystem directly rather than concluding the link is dangling.
	if ([string]::IsNullOrEmpty($target)) {
		try {
			$query = & fsutil.exe reparsepoint query "$Path"
			$line = $query | Where-Object { $_ -match 'Print Name:' } | Select-Object -First 1
			if ($line) { $target = ($line -split 'Print Name:')[-1].Trim() }
		} catch { }
	}
	return $target
}

function Test-IsLink([string]$Path) {
	$item = Get-Item -LiteralPath $Path -Force
	return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

# Is there anything at this path, link or not, without following it? Test-Path
# answers for the target of a file symbolic link, so it reports $false for a
# dangling agent link -- which does exist, and is the one case that has to be
# repaired. Enumerating the parent sees the directory entry either way. This is
# the counterpart of `[ -L ] || [ -e ]` in setup.sh.
function Test-EntryExists([string]$Path) {
	if (Test-Path -LiteralPath $Path) { return $true }
	$parent = Split-Path -Parent $Path
	if (-not (Test-Path -LiteralPath $parent -PathType Container)) { return $false }
	$leaf = Split-Path -Leaf $Path
	return [bool](Get-ChildItem -LiteralPath $parent -Force | Where-Object { $_.Name -eq $leaf })
}

# Where a link target points, as an absolute path. A relative target is relative
# to the directory holding the link, not to the caller's working directory.
function Resolve-LinkTarget([string]$Target, [string]$LinkPath) {
	if ([string]::IsNullOrEmpty($Target)) { return '' }
	if ([IO.Path]::IsPathRooted($Target)) { return $Target }
	return (Join-Path (Split-Path -Parent $LinkPath) $Target)
}

# Remove-Item -Recurse is banned in this script. Against a reparse point it has
# historically recursed into the target, and the target here is the git repo, so
# a careless uninstall could delete real source files. These two calls remove the
# link itself and cannot touch what it points at.
function Remove-Link([string]$Path) {
	if ($DryRun) { return }
	$item = Get-Item -LiteralPath $Path -Force
	if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
		throw "refusing to remove '$Path': it is real content, not a link"
	}
	if ($item.PSIsContainer) {
		[IO.Directory]::Delete($Path, $false)
	} else {
		[IO.File]::Delete($Path)
	}
}

# Create a file symbolic link, via cmd's mklink rather than New-Item.
#
# New-Item -ItemType SymbolicLink in Windows PowerShell 5.1 does not pass
# SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE, so it demands administrator even
# when Developer Mode is enabled. mklink does pass it. Verified on Windows 11
# with Developer Mode on and no elevation: New-Item fails with "administrator
# privileges are required", mklink succeeds. PowerShell 7 does not have this
# problem, but this script supports 5.1.
function New-FileSymlink([string]$Link, [string]$Target) {
	$output = & cmd.exe /c mklink "$Link" "$Target"
	if ($LASTEXITCODE -ne 0) {
		throw "mklink could not create '$Link': $output"
	}
}

# One probe, cached: attempt a real symbolic link in the temp directory and see
# whether this session can create one at all.
$script:SymlinkOk = $null
function Test-SymlinkCapability {
	if ($null -ne $script:SymlinkOk) { return $script:SymlinkOk }
	$id = [Guid]::NewGuid().ToString('N')
	$target = Join-Path $env:TEMP "claude-probe-target-$id"
	$link = Join-Path $env:TEMP "claude-probe-link-$id"
	try {
		Set-Content -LiteralPath $target -Value 'probe' -Encoding utf8
		New-FileSymlink $link $target
		$script:SymlinkOk = $true
	} catch {
		$script:SymlinkOk = $false
	} finally {
		if (Test-Path -LiteralPath $link) { try { [IO.File]::Delete($link) } catch { } }
		if (Test-Path -LiteralPath $target) { try { Remove-Item -LiteralPath $target -Force } catch { } }
	}
	return $script:SymlinkOk
}

function New-ArtifactLink([string]$Kind, [string]$Source, [string]$Dest) {
	if ($DryRun) { return }
	$parent = Split-Path -Parent $Dest
	if (-not (Test-Path -LiteralPath $parent)) {
		New-Item -ItemType Directory -Path $parent -Force | Out-Null
	}
	if ($Kind -eq 'skill') {
		New-Item -ItemType Junction -Path $Dest -Target $Source | Out-Null
	} elseif (Test-SymlinkCapability) {
		New-FileSymlink $Dest $Source
	} else {
		Copy-Item -LiteralPath $Source -Destination $Dest -Force
	}
}

function Move-Aside([string]$Dest) {
	if ($DryRun) { return }
	if (-not (Test-Path -LiteralPath $BackupDir)) {
		New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
	}
	Move-Item -LiteralPath $Dest -Destination $BackupDir
	$script:MadeBackup = $true
}

function Install-Artifact([string]$Kind, [string]$Name, [string]$Source, [string]$Dest) {
	# A skill without a SKILL.md is invisible to Claude Code, so say so rather
	# than linking a directory that will never load. Checked on install only:
	# uninstall just removes whatever link exists under that name.
	if ($Kind -eq 'skill' -and -not (Test-Path -LiteralPath (Join-Path $Source 'SKILL.md'))) {
		Write-Status 'INVALID' $Kind "$Name (no SKILL.md)"
		$script:Skipped++
		return
	}

	# An agent is a file, and only a symbolic link can stand in for a file.
	if ($Kind -eq 'agent' -and -not (Test-SymlinkCapability) -and -not $AllowCopyFallback) {
		Write-Status 'BLOCKED' $Kind "$Name needs the symbolic link privilege"
		$script:BlockedAgents++
		$script:Skipped++
		return
	}

	if (Test-EntryExists $Dest) {
		if (Test-IsLink $Dest) {
			$target = Get-LinkTarget $Dest
			$resolved = Resolve-LinkTarget $target $Dest
			$resolves = $false
			if (-not [string]::IsNullOrEmpty($resolved)) { $resolves = Test-Path -LiteralPath $resolved }

			if (-not $resolves) {
				Write-Status 'REPAIRED' $Kind "$Name (link was dangling)"
				Remove-Link $Dest
				New-ArtifactLink $Kind $Source $Dest
				$script:Linked++
			} elseif ((Resolve-Comparable $target) -eq (Resolve-Comparable $Source)) {
				Write-Status 'OK' $Kind $Name
				$script:Linked++
			} elseif ($Force) {
				Write-Status 'RELINKED' $Kind "$Name (was -> $target)"
				Remove-Link $Dest
				New-ArtifactLink $Kind $Source $Dest
				$script:Linked++
			} else {
				Write-Status 'CONFLICT' $Kind "$Name -> $target (use -Force to replace)"
				$script:Skipped++
			}
		} elseif ($Force) {
			Write-Status 'BACKED-UP' $Kind "$Name (moved to $(Split-Path -Leaf $BackupDir)\)"
			Move-Aside $Dest
			New-ArtifactLink $Kind $Source $Dest
			$script:Linked++
		} else {
			Write-Status 'OCCUPIED' $Kind "$Name is real content, not a link (use -Force to back it up)"
			$script:Skipped++
		}
	} else {
		Write-Status 'CREATED' $Kind $Name
		New-ArtifactLink $Kind $Source $Dest
		$script:Linked++
	}
}

# Remove Dest only when it is a link into this repository. Anything else is the
# user's, and stays.
function Uninstall-Artifact([string]$Kind, [string]$Name, [string]$Source, [string]$Dest) {
	if (-not (Test-EntryExists $Dest)) { return }

	if (Test-IsLink $Dest) {
		$target = Get-LinkTarget $Dest
		if ((Resolve-Comparable $target) -eq (Resolve-Comparable $Source)) {
			Write-Status 'REMOVED' $Kind $Name
			Remove-Link $Dest
		} else {
			Write-Status 'CONFLICT' $Kind "$Name -> $target is not ours, left alone"
			$script:Skipped++
		}
	} else {
		Write-Status 'OCCUPIED' $Kind "$Name is real content, left alone"
		$script:Skipped++
	}
}

# A skill is an immediate subdirectory of skills/, named after the folder.
function Invoke-OverSkills([string]$Action) {
	$skillsRoot = Join-Path $RepoRoot 'skills'
	foreach ($dir in (Get-ChildItem -LiteralPath $skillsRoot -Directory | Sort-Object Name)) {
		$script:Total++
		& $Action 'skill' $dir.Name $dir.FullName (Join-Path $ConfigDir "skills\$($dir.Name)")
	}
}

# Agents are loose .md files, flat, no recursion. The filter excludes .gitkeep.
function Invoke-OverAgents([string]$Action) {
	$agentsRoot = Join-Path $RepoRoot 'agents'
	foreach ($file in (Get-ChildItem -LiteralPath $agentsRoot -Filter '*.md' -File | Sort-Object Name)) {
		$script:Total++
		& $Action 'agent' $file.Name $file.FullName (Join-Path $ConfigDir "agents\$($file.Name)")
	}
}

foreach ($required in @((Join-Path $RepoRoot 'skills'), (Join-Path $RepoRoot 'agents'))) {
	if (-not (Test-Path -LiteralPath $required -PathType Container)) {
		Write-Error "expected directory is missing: $required"
		exit 1
	}
}

Write-Host "repo:   $RepoRoot"
Write-Host "target: $ConfigDir"
if ($DryRun) { Write-Host 'mode:   dry run, nothing will be written' }
Write-Host ''

if ($Uninstall) {
	Invoke-OverSkills 'Uninstall-Artifact'
	Invoke-OverAgents 'Uninstall-Artifact'
	if (-not $DryRun) {
		# Only if now empty, and only these two. $ConfigDir itself is never touched.
		foreach ($dir in @((Join-Path $ConfigDir 'skills'), (Join-Path $ConfigDir 'agents'))) {
			if ((Test-Path -LiteralPath $dir) -and -not (Test-IsLink $dir)) {
				if (-not (Get-ChildItem -LiteralPath $dir -Force)) {
					[IO.Directory]::Delete($dir, $false)
				}
			}
		}
	}
	Write-Host ''
	Write-Host "uninstalled, $script:Skipped skipped"
} else {
	if (-not $DryRun -and -not (Test-Path -LiteralPath $ConfigDir)) {
		New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
	}
	Invoke-OverSkills 'Install-Artifact'
	Invoke-OverAgents 'Install-Artifact'

	if ($script:Total -eq 0) {
		Write-Host 'no artifacts found yet - nothing to link'
		exit 0
	}

	Write-Host ''
	Write-Host "$script:Linked of $script:Total linked, $script:Skipped skipped"
	if ($script:MadeBackup) { Write-Host "existing content was moved to $BackupDir" }
	if ($script:BlockedAgents -gt 0) {
		Write-Host ''
		Write-Host "$script:BlockedAgents agent file(s) could not be linked: this session cannot"
		Write-Host 'create a symbolic link to a file. Pick one:'
		Write-Host '  - enable Developer Mode: Settings > System > For developers. It applies to'
		Write-Host '    the next run, with no need to reopen the terminal or elevate'
		Write-Host '  - or re-run this script from an elevated PowerShell'
		Write-Host '  - or pass -AllowCopyFallback to copy them instead. Copies do not track'
		Write-Host '    git pull; re-run with -Force after every pull to refresh them.'
	}
}

if ($script:Skipped -gt 0) { exit 2 }
exit 0
