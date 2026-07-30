# CLAUDE.md

Instructions for Claude Code when working **inside this repository**.

This repo is the source of truth for a reusable set of agents and skills used
across personal software projects. `setup.sh` symlinks `agents/` and `skills/`
into `~/.claude/`, so anything committed here takes effect globally, in every
project, immediately. Treat every edit as a production change.

## What this repo is not

- Not a project codebase. There is no application to run and no test suite to
  pass. Do not look for build commands.
- Not a place for project-specific rules. Those live in each project's
  `context.md`.
- Not a place for secrets. Never commit keys, credentials, or literal LLM
  prompts — only a summary of what a prompt does, what it receives, and what it
  returns.

## Repository layout

| Path | Contents | Rule |
|---|---|---|
| `agents/` | One loose `.md` per agent | Flat; no subfolders |
| `skills/<name>/SKILL.md` | One folder per skill | Folder name **is** the skill name |
| `templates/` | Per-project starter files | Copied into projects, never symlinked |
| `docs/conventions.md` | Locked architectural decisions | Read before changing structure |
| `README.md` | Human-facing setup and overview | Not agent instructions |

Partition is by **artifact type**, not by agent. Claude Code does not resolve
skills by agent folder, so grouping them that way breaks discovery.

## Where content goes

Two partition rules decide the destination of any new instruction.

**Mechanical vs judgment.** Anything a linter, formatter, analyzer, or test can
verify — formatting, casing, line length, static analysis — is delegated to
tooling and must not be restated as a rule. Skills carry only what needs
judgment: is this abstraction sound, does this name communicate intent, is this
trade-off worth taking.

**Agnostic vs stack-specific.** Anything that would be identical in any
language goes in `skills/base/`. Anything that changes with the technology —
dependency injection, libraries, framework architecture — goes in
`skills/stack-*/`.

If a rule seems to belong in both places, it is two rules in two files, not one
rule in the wrong file.

## Authoring skills

```yaml
---
name: <must match folder name exactly>
description: <what it does + when to use it, with explicit triggers>
when_to_use: <optional; only for triggers the description cannot carry>
---
```

`description` is the only thing Claude sees before deciding whether to load the
skill. Write it as a trigger, not as a summary.

Body rules:

- One responsibility per skill. If it does three things, it is three skills.
- Actionable principles, not essay prose. Short imperative statements.
- Cover the core, then stop. Exhaustiveness is not the goal.
- `base` and `stack-*` exist at global scope only. Never create local copies.

## Authoring agents

```yaml
---
name: <agent name>
description: <what it does + when to delegate to it>
tools: <minimum set required; restrictive by default>
model: inherit
---
```

There is no frontmatter field for importing skills. Loading is belt and
suspenders:

1. The skill's own `description` auto-triggers it.
2. The agent body carries an explicit instruction: load and apply
   `<skill-a>`, `<skill-b>`.

Keep the agent body short. It defines the role and what to load. The substance
lives in the skills.

## Overrides

Never shadow a global skill with a local one of the same name. Resolution order
(enterprise > personal > project) makes the global version win, and subagents
invoked via Task have been reported to ignore the local version entirely.

Project-specific deviations go in the overrides section of that project's
`context.md`, which takes precedence over the general rule when the two
conflict.

## Language

- Committed file content — skills, agents, templates, `README.md`, docs:
  **English**. This includes every README, since the repository is public.
- Conversation: **Spanish**. This covers replies, questions, and the running
  commentary on what is being done and why — not only the final answer.

## Definition of done

A skill or agent is done when all three hold:

1. Frontmatter is valid and complete.
2. The body covers the core principles of its responsibility without trying to
   be exhaustive.
3. It has been exercised at least once on a real task.

Anything short of (3) is a draft — say so rather than implying completeness.
To read the state of a given artifact: a stub still contains TODO markers; a
draft has complete content but no record of being exercised; usable has been
run against a real task.

## Build order

Groups advance in sequence. **No group advances until the previous group's
output has been exercised on a real project.**

```
G1  base → stack-nest → security-appsec (draft) → Backend agent → real test
G2  stack-react → stack-react-web → Frontend agent
G3  stack-react-native → Mobile agent
G4  error-handling-and-logging → testing
G5  auth library → auth-lib skill; logging library → logging-lib skill
G6  Testing agent → Infra agent → Code Reviewer agent
G7  Requirements Analyst (independent; no ordering constraint)
```

`auth-lib` and `logging-lib` stay empty until the libraries they document
exist. Do not speculate about their contents.

Do not build ahead of the sequence, and do not design a skill to theoretical
completeness in the abstract. Minimum viable content, exercised, then iterated.

## Working method

One dedicated session per skill or agent. Within a session:

1. Agree on scope section by section before writing anything.
2. Produce a full draft for review in conversation.
3. Identify a small real task to exercise it.

No files are generated until the content has been approved in conversation.
