---
name: error-handling-and-logging
description: Apply when code can fail, when deciding what to do with a caught
  error, or when adding a log. Judgment on which outcomes are errors, what an
  error must carry, what belongs in a log, and when a retry is safe. Load together
  with the base skill.
---

# error-handling-and-logging

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

Any code that can fail, and any decision about what to record. Load `base`
alongside this.

Errors and logs are treated together because they answer the same question from
two sides: what went wrong, and how the person who has to fix it finds out.

Nothing here restates the language's mechanics. Whether your language uses
exceptions, result types, or error returns is not the subject — the judgment is
the same either way.

## Expected outcomes are not errors

- "Not found", "already exists", "invalid credentials", "insufficient funds" are
  things the system is designed to encounter. They are results, and the caller is
  supposed to handle them.
- Reserve the failure channel for what the caller cannot be expected to handle: a
  broken invariant, a dependency that is down, a bug.
- The test is whether the caller has a reasonable response. If every caller will
  catch it and continue, it was a value pretending to be an error.
- Using exceptions for routine outcomes makes the normal path invisible — the
  reader cannot tell from the signature what usually happens.
- Distinguish "the caller sent something wrong" from "we failed". They have
  different audiences, different fixes, and in an API different status codes.

## Never swallow a failure

- An empty `catch` turns a failure into a mystery. The symptom appears somewhere
  else, later, with nothing connecting it to the cause.
- When you catch, either handle it — do something that makes the situation
  correct — or let it propagate. Logging and continuing as if nothing happened is
  neither.
- Catch narrowly. A broad catch around a block of unrelated calls will one day
  absorb a bug you needed to see.
- Never catch to make a test pass or a log quiet. That is hiding the signal you
  built the mechanism to receive.
- A failure in a security-relevant path must deny, not proceed. See
  `security-appsec`.

## An error must carry enough to act on

- Say what operation failed, on what, and with what input. "Request failed" sends
  the reader to the debugger; "failed to fetch profile 41c9 from the store" sends
  them to the cause.
- Preserve the original cause when wrapping. Throwing a new error and discarding
  the one you caught destroys the only evidence of what actually happened.
- Add context as it crosses a boundary — each layer knows something the one below
  did not. Do not re-wrap at every function; wrap where you can add meaning.
- Do not put remediation advice in an error thrown deep inside. The code that
  catches it knows the user and the situation; the code that raised it does not.
- Errors leaving the system are a disclosure channel. Internal detail belongs in
  the log, not in the response.

## Logs are read at 3am by someone who was not there

- Write for a reader with no context, looking at one line. What happened, to
  what, and enough identifiers to follow the thread.
- One event per entry, structured, with stable field names. Prose assembled from
  string concatenation cannot be searched or aggregated.
- Log the decision, not the traversal. "Rejected the upload: over quota" is
  useful; "entering validateUpload" is noise that hides the useful line.
- Never log a secret, a token, or a credential, and treat personal data as
  something you must justify recording. Assume every log is read by more people,
  for longer, than you intend.
- Log at the point where you know the outcome. Logging on the way in tells you
  something was attempted, which is rarely the question being asked.
- If a log line has never been read, it is not free — it costs money to store and
  attention to skip.

## Levels are a promise about attention

- `error` means a human has to do something. If routine conditions log as errors,
  the level stops meaning anything and real errors get skipped.
- `warn` means degraded but working — a fallback was used, a retry succeeded, a
  deprecated path was taken.
- `info` records state transitions someone would want to reconstruct later.
- `debug` is for development and is expected to be off in production.
- Decide the level from what the reader should do, not from how bad it feels.

## Retries need idempotence, a ceiling, and a reason

- Only retry what is safe to run twice. Retrying a non-idempotent operation
  duplicates its effects, and the duplicate is usually harder to find than the
  original failure.
- Only retry what might succeed next time. A timeout might; a validation error
  will not, and retrying it just multiplies the failure.
- Always have a ceiling and back off between attempts. Immediate retries against
  a struggling dependency are indistinguishable from an attack on it.
- Say what happens when the retries run out. That path is the one that runs on
  the worst day.
- Make the retry visible. A silent retry that keeps a system limping hides the
  fault until it is much larger.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| Test design, including failure-path tests | `testing` |
| Failing closed, disclosure through errors, secret handling | `security-appsec` |
| Where a framework wants error translation to live | the relevant `stack-*` skill |
| Language-agnostic judgment | `base` |
| Logging library, transports, levels config, log sinks | the project's `CLAUDE.md` — facts, not judgment |
| Log formatting and lint rules | tooling, per C2 |

Metrics, tracing, alerting thresholds, and incident response are absent: they are
operational concerns rather than code judgment, and no real task has justified
them here.
