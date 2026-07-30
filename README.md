# agents

A reusable set of [Claude Code](https://docs.claude.com/en/docs/claude-code)
agents and skills, shared across personal software projects.

This repository is the single source of truth for those artifacts. The installer
links each skill and each agent into `~/.claude/`, so anything committed here
takes effect globally — in every project, immediately.

> **Status: no artifacts yet.** The conventions are settled (see
> [CLAUDE.md](CLAUDE.md)) and the installer works, but no skill or agent has
> been written. G1 of the build order below is the current work.

## Why

Instructions for an AI coding assistant tend to be rewritten per project, drift
apart, and decay. Centralizing them makes a single improvement propagate
everywhere, and makes each rule reviewable as a change with a diff and history.

Two ideas shape the content:

- **Only what needs judgment.** Anything a linter, formatter, or test can
  verify is delegated to that tooling and never restated as a rule. Skills
  carry the rest: is this abstraction sound, does this name communicate intent,
  is this trade-off worth taking.
- **Agnostic separated from stack-specific.** What would be identical in any
  language lives in `skills/base/`. What changes with the technology lives in
  `skills/stack-*/`.

## Layout

Partitioned by artifact type, not by agent — Claude Code does not resolve
skills by agent folder, so grouping them that way breaks discovery.

| Path | Contents |
|---|---|
| `agents/` | One loose `.md` per agent. Flat, no subfolders. |
| `skills/<name>/SKILL.md` | One folder per skill. The folder name **is** the skill name. |
| `templates/` | Per-project starter files. Copied into projects, never symlinked. |
| `docs/conventions.md` | Locked architectural decisions, and why they are what they are. |
| `setup.sh`, `setup.ps1` | Installers for POSIX and Windows. Same contract. |
| `CLAUDE.md` | Instructions for Claude Code when working inside this repo. |

## Install

```sh
git clone https://github.com/alllano/agents.git
cd agents
./setup.sh --dry-run   # see what it would do
./setup.sh
```

On Windows, use the PowerShell installer instead:

```powershell
.\setup.ps1 -DryRun
.\setup.ps1
```

Both link **each artifact individually** — one link per skill directory, one per
agent file — rather than linking `skills/` and `agents/` whole. Those two are
namespaces owned by Claude Code and shared with anything else you install there,
and replacing one with a link would mean destroying its contents first.

The consequence worth knowing: editing an artifact needs no action, but a
`git pull` that **adds** one requires re-running the installer. Same after
moving or re-cloning the repository, since links store absolute paths.

Nothing here needs a build step, and there is no test suite — this repo contains
no application code.

### Options

| Flag | Effect |
|---|---|
| `--dry-run` / `-DryRun` | Print the plan. Creates nothing. |
| `--force` / `-Force` | Replace links pointing elsewhere; move real content in the way into a timestamped backup first. Never deletes. |
| `--uninstall` / `-Uninstall` | Remove only the links that resolve into this repository. |

Exit code `0` means clean, `2` means it finished but skipped something — so a
partial install is detectable without reading the output.

`templates/` is deliberately never linked. Those files are meant to be copied
into a project and diverge there.

### Windows notes

Skills are directories, so they install as **junctions**, which need neither
administrator rights nor Developer Mode.

Do not use `setup.sh` from Git Bash here. Without the Windows symlink privilege
`ln -s` copies the source instead of linking it and reports success, leaving
copies that never track the repository. `setup.sh` detects this and refuses
rather than installing them.

Agents are single `.md` files, and only a symbolic link can stand in for a file
— which does require a privilege Windows withholds by default. Enable **Developer
Mode** (Settings → System → For developers) and agents link without elevation and
without reopening the terminal.

Note for anyone editing `setup.ps1`: it creates file symbolic links with `mklink`
rather than `New-Item -ItemType SymbolicLink`, because Windows PowerShell 5.1's
`New-Item` does not pass `SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE` and so
still demands administrator even with Developer Mode on. Do not "simplify" it
back.

Where symbolic links are genuinely unavailable, agents are reported `BLOCKED`.
`-AllowCopyFallback` copies them instead, at the cost of re-running with `-Force`
after every pull.

## Scope

Global artifacts hold rules that are true across projects. Project-specific
rules belong in that project's own `CLAUDE.md`, which takes precedence where
the two conflict. A local skill must never reuse the name of a global one:
resolution order makes the global version win, and subagents have been reported
to ignore the local version entirely.

Secrets and literal LLM prompts are never committed — only a summary of what a
prompt does, what it receives, and what it returns.

## Definition of done

An artifact is done when three things hold:

1. Frontmatter is valid and complete.
2. The body covers the core principles of its responsibility, without trying to
   be exhaustive.
3. It has been exercised at least once on a real task.

Anything short of (3) is a draft and is labeled as such. In short: a **stub**
still contains TODO markers, a **draft** has complete content but no record of
being exercised, and **usable** has been run against a real task.

## Build order

Groups advance in sequence. No group starts until the previous group's output
has been exercised on a real project — minimum viable content, exercised, then
iterated, rather than designed to theoretical completeness up front.

| Group | Output |
|---|---|
| G1 | `base` → `stack-nest` → `security-appsec` → Backend agent |
| G2 | `stack-react` → `stack-react-web` → Frontend agent |
| G3 | `stack-react-native` → Mobile agent |
| G4 | `error-handling-and-logging` → `testing` |
| G5 | `auth-lib` and `logging-lib` skills, once those libraries exist |
| G6 | Testing agent → Infra agent → Code Reviewer agent |
| G7 | Requirements Analyst (independent; no ordering constraint) |

## Contributing

This is a personal toolkit, published in case the structure is useful to
others. It is not accepting feature requests, but issues pointing out a rule
that is wrong or a convention that backfires are welcome.

Documentation is written in English. Read [CLAUDE.md](CLAUDE.md) before adding
or changing an artifact.

## License

[MIT](LICENSE) — use it, copy it, adapt it. Keep the copyright notice.
