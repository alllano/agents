# agents

A reusable set of [Claude Code](https://docs.claude.com/en/docs/claude-code)
agents and skills, shared across personal software projects.

This repository is the single source of truth for those artifacts. The installer
links each skill and each agent into `~/.claude/`, so anything committed here
takes effect globally — in every project, immediately.

> **Status: written, not yet proven.** Nine skills and six agents exist and
> install. All but one are **drafts** — complete content that has not yet been
> exercised on a real project. Treat them as a considered starting point, not as
> tested guidance.

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

## What is here

Skills:

| Skill | Covers | State |
|---|---|---|
| `base` | Language-agnostic judgment. Loaded for every code task. | usable |
| `stack-nest` | NestJS: module boundaries, layers, injection, validation at the edge. | draft |
| `stack-react` | React on any platform: components, state, effects, hooks. | draft |
| `stack-react-web` | The browser: DOM and accessibility, the URL, storage, bundle cost. | draft |
| `stack-prisma` | Schema as source of truth, migration safety, the repository boundary. | draft |
| `stack-aws` | Permissions, config delivery, compute choice, cost as a design output. | draft |
| `security-appsec` | Trust boundaries, authorization placement, secrets, failing closed. | draft |
| `error-handling-and-logging` | Which outcomes are errors, what an error carries, what to log. | draft |
| `testing` | What to assert, how much to arrange, where to mock. | draft |

Agents:

| Agent | Role | Notable |
|---|---|---|
| `backend` | Server-side implementation and review. | |
| `frontend` | Browser front-end implementation and review. | |
| `tester` | Writes and reviews tests. | Will not change production code to make a test pass. |
| `infra` | Deployment, CI, cloud configuration. | Proposes changes; does not apply them to live systems. |
| `code-reviewer` | Reviews a change and reports findings. | **Read-only by design** — no `Edit`, no `Write`. |
| `requirements-analyst` | Turns a request into something buildable. | Does not design the solution. |

Every skill ends with a table of what it deliberately leaves out and who owns
that topic instead, so a gap is visible rather than implied.

### Not built, on purpose

- **React Native and a Mobile agent** — no project needs them, so they could only
  be written speculatively and would never be corrected.
- **`auth-lib` and `logging-lib`** — the libraries they would document do not
  exist yet.

An artifact with no consumer cannot be exercised, and by this repo's own
definition of done that makes it permanently a draft. Better absent than
pretending.

## Contributing

This is a personal toolkit, published in case the structure is useful to
others. It is not accepting feature requests, but issues pointing out a rule
that is wrong or a convention that backfires are welcome.

Documentation is written in English. Read [CLAUDE.md](CLAUDE.md) before adding
or changing an artifact.

## License

[MIT](LICENSE) — use it, copy it, adapt it. Keep the copyright notice.
