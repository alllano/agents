---
name: security-appsec
description: Apply when handling untrusted input, authentication, authorization,
  secrets, or anything crossing a trust boundary. Judgment on where to place
  checks and what must never be assumed. Load together with the base skill.
---

# security-appsec

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

Any change that touches a trust boundary: input arriving from outside, a
decision about who may do what, a secret, or a call to something you do not
control. Load `base` alongside this.

This skill carries judgment, not an inventory of vulnerability classes. The
enumeration is maintained elsewhere and better: the current edition is the
**OWASP Top 10:2025**. Consult it when you want coverage; use this when you want
to know where a check belongs and what not to assume.

Security is not a review stage at the end. A check in the wrong place is a
design defect, and no amount of later review relocates it.

## Trust boundaries are the unit of analysis

- Name where untrusted data enters before deciding anything else. Almost every
  question that follows has a different answer on each side of that line.
- Untrusted means "not produced by this system", not "produced by a stranger".
  Another team's service, a webhook, a queue message, and your own database
  after a migration are all outside.
- The client is not a boundary you control. Anything it validates, it can be
  made not to validate. Client-side checks are ergonomics.
- Data that crossed a boundary once does not become trusted by being stored.
  Persisting it launders nothing.

## Authorization belongs where the decision is

Broken access control remains the most consequential flaw in practice, and it is
almost always a placement mistake rather than a missing feature.

- Deny by default. A path that is allowed because nothing denied it is not a
  policy, it is an accident.
- Check the object, not just the endpoint. Being allowed to read invoices is not
  being allowed to read *this* invoice.
- Authorize where the action happens, not where the UI decides what to show.
  Absence of a button is not a control.
- Identity is not permission. Knowing who someone is answers a different
  question from what they may do.
- Do not let the caller name the target of a server-side request. A
  server-fetched URL taken from input is the caller acting with your privileges.

## Data is never code

Injection is one mistake wearing many costumes: something built a command out of
data, and the data escaped into the command.

- Pass data as data — parameters, arguments, structured values. Do not assemble a
  statement, a shell line, a path, or a template out of input.
- Escaping is the fallback when a structured interface does not exist, and it is
  the fallback because it depends on getting every case right.
- The same rule holds for anything that interprets text, including a prompt sent
  to a model. Untrusted text placed where instructions are read is an injection,
  and the model does not distinguish the two either.
- Validate against what is allowed, not against what is known to be bad.
  Denylists enumerate the attacks someone already thought of.

## Fail closed, and leak nothing

- When a security check cannot complete, deny. An authorization path that
  proceeds on error has no authorization path.
- An error is a disclosure channel. Stack traces, query fragments, internal
  hostnames, and library versions belong in the log, never in the response.
- Distinguish "not permitted" from "does not exist" deliberately. Which one you
  return tells the caller something, and sometimes that is the leak.
- Timing and message differences are answers too. An authentication path that is
  faster for unknown users has told you who exists.

## Secrets

- A secret in the repository is compromised, including in history, including in
  a private repository, including if removed in a later commit. Rotate, do not
  edit.
- Never log a secret, and never include one in an error, a URL, or an analytics
  event. Assume every log is read by more people than you expect.
- Design for rotation from the start. A secret that cannot be changed without
  downtime will not be changed.
- Encrypt, hash, and sign with the standard primitive for the job. Inventing
  scheme details is where this goes wrong, not choosing the algorithm.

## Dependencies are attack surface you did not write

- Adding a dependency is a decision with a security cost, not a convenience.
  Weigh what it pulls in transitively, not just what it does.
- Pin what you install and know what changed when it moves. A build that
  silently resolves differently tomorrow is not reproducible or reviewable.
- Treat build and release tooling as production. It runs with more privilege
  than the application and is a more valuable target.
- A dependency that is unmaintained is a liability regardless of how well it
  works today.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| The enumeration of vulnerability classes | OWASP Top 10:2025, upstream |
| How to log and what to log | `error-handling-and-logging` (G4) |
| Test design, including security tests | `testing` (G4) |
| Framework-specific placement of guards and pipes | the relevant `stack-*` skill |
| Language-agnostic judgment | `base` |
| Scanner and dependency-audit configuration | project tooling, per C2 |

Infrastructure hardening, network policy, and incident response are absent:
they are not application code, and no real task has justified them here.
