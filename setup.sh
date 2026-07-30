#!/bin/sh
# Link this repository's skills and agents into the Claude Code config directory.
#
# Each artifact is linked individually, never the parent skills/ or agents/
# directory. Those are namespaces owned by Claude Code and shared with anything
# else the user installs; replacing one with a link would mean destroying its
# existing contents first. See docs/conventions.md, decision C5.
#
# This script never deletes real content. --force moves it aside instead.

set -eu

DRY_RUN=0
FORCE=0
UNINSTALL=0

usage() {
	cat <<'EOF'
Usage: setup.sh [--dry-run] [--force] [--uninstall] [--help]

Links each skill in skills/ and each agent in agents/ into the Claude Code
config directory ($CLAUDE_CONFIG_DIR, or ~/.claude).

  --dry-run    Print the plan and exit. Creates nothing.
  --force      Replace links that point elsewhere, and move a real file or
               directory in the way into a timestamped backup before linking.
               Never deletes anything.
  --uninstall  Remove only links that resolve into this repository.
  --help       Show this message.

templates/ is deliberately never linked: those files are meant to be copied
into a project and diverge there.

Statuses: CREATED, OK, RELINKED, REPAIRED, BACKED-UP, CONFLICT, OCCUPIED,
          INVALID, REMOVED.
Exit codes: 0 clean, 1 error, 2 finished with items skipped.
EOF
}

for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		--force) FORCE=1 ;;
		--uninstall) UNINSTALL=1 ;;
		--help | -h)
			usage
			exit 0
			;;
		*)
			printf 'setup.sh: unknown option: %s\n\n' "$arg" >&2
			usage >&2
			exit 1
			;;
	esac
done

# Resolve from the script's own location, never the caller's working directory.
REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STAMP=$(date -u +%Y%m%d-%H%M%S)
BACKUP_DIR="$CONFIG_DIR/.backup-$STAMP"

skipped=0
linked=0
total=0

# Absolute, symlink-free form of a path, so two spellings of the same location
# compare equal. Falls back to the input when the parent does not exist, which
# is what a dangling link resolves to.
canon() {
	if [ -d "$1" ]; then
		(CDPATH= cd -- "$1" && pwd -P)
	else
		_parent=$(dirname -- "$1")
		_leaf=$(basename -- "$1")
		if [ -d "$_parent" ]; then
			printf '%s/%s\n' "$(CDPATH= cd -- "$_parent" && pwd -P)" "$_leaf"
		else
			printf '%s\n' "$1"
		fi
	fi
}

report() {
	printf '  %-10s %-6s %s\n' "$1" "$2" "$3"
}

# rm on a symlink removes the link itself and never follows it into the target,
# so no -r is needed here — and none is wanted, given the target is this repo.
drop_link() {
	[ "$DRY_RUN" -eq 1 ] || rm -- "$1"
}

make_link() {
	if [ "$DRY_RUN" -eq 0 ]; then
		mkdir -p -- "$(dirname -- "$2")"
		ln -s -- "$1" "$2"

		# Git Bash without the Windows symlink privilege makes ln -s copy the
		# source instead of linking it, and says nothing: the install reports
		# CREATED, exits 0, and the copy never tracks the repository again. That
		# is the invisible staleness C5 rejects, so fail loudly instead. On a
		# real POSIX system this check never fires.
		if [ ! -L "$2" ]; then
			# Safe to remove: it was created a moment ago and is not a link.
			rm -rf -- "$2"
			printf '\nsetup.sh: ln -s produced a copy, not a link:\n  %s\n' "$2" >&2
			printf 'This shell cannot create symbolic links, so nothing was installed.\n' >&2
			printf 'On Windows run setup.ps1 instead. To use this script anyway, enable\n' >&2
			printf 'Developer Mode and export MSYS=winsymlinks:nativestrict.\n' >&2
			exit 1
		fi
	fi
}

# Link src to dst, deciding from the current state of dst.
install_one() {
	kind=$1
	name=$2
	src=$3
	dst=$4

	# A skill without a SKILL.md is invisible to Claude Code, so say so rather
	# than linking a directory that will never load. Checked on install only:
	# uninstall just removes whatever link exists under that name.
	if [ "$kind" = skill ] && [ ! -f "$src/SKILL.md" ]; then
		report INVALID "$kind" "$name (no SKILL.md)"
		skipped=$((skipped + 1))
		return 0
	fi

	if [ -L "$dst" ]; then
		target=$(readlink -- "$dst")
		if [ ! -e "$dst" ]; then
			report REPAIRED "$kind" "$name (link was dangling)"
			drop_link "$dst"
			make_link "$src" "$dst"
			linked=$((linked + 1))
		elif [ "$(canon "$target")" = "$(canon "$src")" ]; then
			report OK "$kind" "$name"
			linked=$((linked + 1))
		elif [ "$FORCE" -eq 1 ]; then
			report RELINKED "$kind" "$name (was -> $target)"
			drop_link "$dst"
			make_link "$src" "$dst"
			linked=$((linked + 1))
		else
			report CONFLICT "$kind" "$name -> $target (use --force to replace)"
			skipped=$((skipped + 1))
		fi
	elif [ -e "$dst" ]; then
		if [ "$FORCE" -eq 1 ]; then
			report BACKED-UP "$kind" "$name (moved to ${BACKUP_DIR##*/}/)"
			if [ "$DRY_RUN" -eq 0 ]; then
				mkdir -p -- "$BACKUP_DIR"
				mv -- "$dst" "$BACKUP_DIR/"
			fi
			make_link "$src" "$dst"
			linked=$((linked + 1))
		else
			report OCCUPIED "$kind" "$name is real content, not a link (use --force to back it up)"
			skipped=$((skipped + 1))
		fi
	else
		report CREATED "$kind" "$name"
		make_link "$src" "$dst"
		linked=$((linked + 1))
	fi
}

# Remove dst only when it is a link into this repository. Anything else is the
# user's, and stays.
uninstall_one() {
	kind=$1
	name=$2
	src=$3
	dst=$4

	if [ -L "$dst" ]; then
		target=$(readlink -- "$dst")
		if [ "$(canon "$target")" = "$(canon "$src")" ]; then
			report REMOVED "$kind" "$name"
			drop_link "$dst"
		else
			report CONFLICT "$kind" "$name -> $target is not ours, left alone"
			skipped=$((skipped + 1))
		fi
	elif [ -e "$dst" ]; then
		report OCCUPIED "$kind" "$name is real content, left alone"
		skipped=$((skipped + 1))
	fi
}

# A skill is an immediate subdirectory of skills/, named after the folder.
walk_skills() {
	for dir in "$REPO"/skills/*/; do
		[ -d "$dir" ] || continue
		name=${dir%/}
		name=${name##*/}
		total=$((total + 1))
		"$1" skill "$name" "${dir%/}" "$CONFIG_DIR/skills/$name"
	done
}

# Agents are loose .md files, flat, no recursion. The glob excludes .gitkeep and
# any dotfile on its own.
walk_agents() {
	for file in "$REPO"/agents/*.md; do
		[ -f "$file" ] || continue
		name=${file##*/}
		total=$((total + 1))
		"$1" agent "$name" "$file" "$CONFIG_DIR/agents/$name"
	done
}

for required in "$REPO/skills" "$REPO/agents"; do
	if [ ! -d "$required" ]; then
		printf 'setup.sh: expected directory is missing: %s\n' "$required" >&2
		exit 1
	fi
done

printf 'repo:   %s\n' "$REPO"
printf 'target: %s\n' "$CONFIG_DIR"
if [ "$DRY_RUN" -eq 1 ]; then
	printf 'mode:   dry run, nothing will be written\n'
fi
printf '\n'

if [ "$UNINSTALL" -eq 1 ]; then
	walk_skills uninstall_one
	walk_agents uninstall_one
	if [ "$DRY_RUN" -eq 0 ]; then
		# Only if now empty and only these two. ~/.claude itself is never touched.
		rmdir -- "$CONFIG_DIR/skills" 2>/dev/null || true
		rmdir -- "$CONFIG_DIR/agents" 2>/dev/null || true
	fi
	printf '\nuninstalled, %d skipped\n' "$skipped"
else
	if [ "$DRY_RUN" -eq 0 ] && [ ! -d "$CONFIG_DIR" ]; then
		mkdir -p -- "$CONFIG_DIR"
	fi
	walk_skills install_one
	walk_agents install_one
	if [ "$total" -eq 0 ]; then
		printf 'no artifacts found yet - nothing to link\n'
		exit 0
	fi
	printf '\n%d of %d linked, %d skipped\n' "$linked" "$total" "$skipped"
	if [ -d "$BACKUP_DIR" ]; then
		printf 'existing content was moved to %s\n' "$BACKUP_DIR"
	fi
fi

if [ "$skipped" -gt 0 ]; then
	exit 2
fi
exit 0
