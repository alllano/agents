---
name: base
description: Apply when writing or changing code in any language. Judgment on
  naming, abstraction, dependency direction, and how much to change. Load
  alongside the relevant stack-* skill, which adds to this and never replaces it.
---

# base

> Status: usable — exercised on the setup.sh / setup.ps1 parity review.

## When this applies

Every task that writes or changes code, in any language. A `stack-*` skill adds
technology-specific judgment on top of this one; it never overrides it.

Nothing here restates what a linter, formatter, or test can check. That is the
tooling's job, and a rule stated in two places drifts.

## Follow the pattern that is already there

Find how the surrounding code solves this problem before writing a line.

- Match the conventions you find, including where you would have chosen otherwise.
- Introducing a second way to do something this codebase already does is a
  decision. Make it deliberately and say why.
- Reuse what exists before adding to it. Go look for it; do not conclude from
  silence that it is absent.
- Consistency with a mediocre local pattern usually beats a better foreign one.
  Improve the pattern in a change of its own, not as a side effect of this one.

## The smallest change that solves it

Change what the task requires, and stop.

- No speculative generality: no parameter, layer, or extension point for a
  requirement that does not exist yet.
- No drive-by refactors inside an unrelated diff. Note them and do them separately.
- Deleting is a change too. Leaving dead code because removing it feels risky
  does not remove the risk, it hides it.

## Names carry intent

A name says what something means in the domain, not what it is made of.

- Name for the caller's understanding, not the implementation's.
- `data`, `info`, `manager`, `helper`, `utils` name nothing. Neither does a name
  that only repeats the type.
- If a name needs a comment to be understood, the name is wrong.
- Length is not the cost, ambiguity is. Prefer the longer unambiguous name.
- Use the domain's own word for a thing. Inventing a synonym creates two things.

## Comments explain why

Write the reason. Never the mechanics.

- A comment restating the line below it is noise, and it goes stale first.
- Comment what is not obvious: the constraint, the alternative that was rejected,
  the reason this looks wrong but is correct.
- If code needs a comment to be followed at all, first try making the code clearer.
- Leave no commentary about the act of working in the source — no "changed this",
  "as requested", "new helper". It addresses one reader at one moment and
  confuses everyone afterwards.

## Duplication versus the wrong abstraction

Abstract on the second real occurrence, not the first anticipated one.

- Two things that look alike today may not change together. Wait for evidence
  that they do.
- Explicit duplication is cheap to undo. A wrong seam gets built on top of, and
  then it is not cheap.
- When you do abstract, the abstraction has to mean something. If you can only
  name it after its shape, it is not one yet.

## Dependency direction and side effects

- Dependencies point one way. If A knows about B, B does not know about A.
- Keep I/O — network, disk, clock, randomness, environment — out of the code that
  makes decisions. Decide in one place, act in another.
- Depend on what you need, not on the container it arrived in.
- A function whose result depends on something absent from its inputs is harder
  to reason about than its size suggests.

## Say the trade-off out loud

- State the assumption you made and what you gave up for it.
- When the requirement is ambiguous, ask. A guess presented as a decision is the
  expensive failure.
- Report what you did not do and what you did not verify. Calling untested work
  done is a reporting error, not a rounding.
- When you disagree with the instruction, say so once with the reason, then follow it.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| Error handling, logging | `error-handling-and-logging` (G4) |
| Test design, coverage judgment | `testing` (G4) |
| Security judgment | `security-appsec` |
| Framework and library architecture | the relevant `stack-*` skill |
| Formatting, casing, import order, line length | project tooling, per C2 |

Performance, git hygiene, and API surface design are absent because no real task
has justified them yet.
