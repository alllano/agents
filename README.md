# agents

A reusable set of [Claude Code](https://docs.claude.com/en/docs/claude-code)
agents and skills, shared across personal software projects.

This repository is the single source of truth for those artifacts. `setup.sh`
symlinks `agents/` and `skills/` into `~/.claude/`, so anything committed here
takes effect globally — in every project, immediately.

> **Status: scaffolding.** The conventions are settled (see
> [CLAUDE.md](CLAUDE.md)); the artifacts are not written yet. The first group of
> the build order below is the current work.

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
| `docs/conventions.md` | Locked architectural decisions. |
| `CLAUDE.md` | Instructions for Claude Code when working inside this repo. |

## Install

```sh
git clone https://github.com/alllano/agents.git
cd agents
./setup.sh
```

`setup.sh` creates symlinks in `~/.claude/`; it does not copy. Pulling new
commits updates every project at once. Nothing here needs a build step, and
there is no test suite — this repo contains no application code.

## Scope

Global artifacts hold rules that are true across projects. Project-specific
rules belong in that project's own `context.md`, which takes precedence where
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
