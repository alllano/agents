---
name: testing
description: Apply when writing, changing, or reviewing tests, or deciding whether
  something needs one. Judgment on what to assert, how much to arrange, where to
  mock, and what coverage does and does not tell you. Load together with the base
  skill.
---

# testing

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

Any task that writes or changes a test, and any decision about whether something
needs one. Load `base` alongside this.

Nothing here restates what the test runner does. Which runner, where files live,
and how they are named are project facts and tooling, not judgment.

## A test states an expectation, not a procedure

- The name says the behavior and the condition: what it does, when. If you have
  to read the body to know what broke, the name has failed at its only job.
- One reason to fail per test. A test asserting five unrelated things tells you
  something is wrong, not what.
- Assert the outcome the caller cares about, not every intermediate value you can
  reach. Extra assertions do not add confidence, they add reasons to edit the test
  later.
- A test with no assertion passes as long as nothing throws. That is a smoke test,
  and it should say so.

## Test the contract, not the implementation

- Assert on what a caller can observe: the return value, the persisted state, the
  message sent. Not on which private method ran, or in what order.
- Tests coupled to internals turn every refactor into test work, and that is how
  teams learn to stop refactoring. The test that has to change when behavior did
  not is a liability.
- Reaching into private state to set up or verify is a signal that the boundary is
  in the wrong place — usually the thing you are reaching for wants to be its own
  unit with its own contract.
- A test that fails when you rename something internal, and passes when you break
  something users can see, is worse than no test.

## Arrange the minimum

- Build only what this test needs. Setup that exists for other tests makes this
  one's failure non-local, and the test that fails is not the one you broke.
- Prefer building state explicitly in the test over inheriting it from a shared
  mutable fixture. Duplication in setup is cheap; a fixture everything depends on
  is not.
- The test should read as one story: given this, when that, then this. If the
  reader has to jump to three files to learn what "this" is, the test cannot be
  reviewed.
- Tests must not depend on order, on each other, or on a clock, a network, or a
  random value you did not control. Every one of those is a future intermittent
  failure.

## Mock the boundary you do not own

- Replace things outside your control — a third-party API, the clock, the
  filesystem, a payment provider. Mocking your own code means asserting against
  your own assumptions.
- Every mock encodes a belief about how the real thing behaves. When that belief
  is wrong the test passes and production fails, which is the most expensive
  outcome a test suite can produce.
- The more mocks a test needs, the more it is testing wiring. That is a signal
  about the design, not about the test.
- Something has to exercise the real boundary. If every test mocks the database,
  nothing has verified that a query is valid.

## Coverage measures execution, not verification

- Coverage tells you a line ran. It cannot tell you an outcome was checked, so it
  is a floor for finding untested code, never a definition of done.
- A coverage target becomes a coverage-writing exercise. Tests written to move a
  number assert nothing and still have to be maintained.
- Look at what is uncovered rather than at the percentage. Uncovered error paths
  and boundary conditions are where the interesting defects are.
- The paths worth covering are the ones that are hard to trigger on purpose: the
  failure path, the empty case, the limit, the one that only happens when
  something else is down.

## Test what would actually break

- Write the test where a defect would be expensive or invisible: money, data
  loss, permissions, anything a user cannot see going wrong.
- A test that could only fail if the language were broken is cost with no
  information.
- Every fixed bug is a test worth having, and it is the one moment when you know
  the test would have failed for a real reason.
- When behavior is genuinely uncertain, a test is how you find out — write it to
  learn, then keep it or delete it deliberately.

## A flaky test is a failing test

- An intermittent test teaches the team that red does not mean broken, and that
  lesson is more expensive than the test is worth.
- Fix the cause or delete it. Retrying until it passes converts a real signal into
  noise you are paying to generate.
- The usual causes are shared state, real time, real concurrency, and depending on
  order. All four are design problems in the test, not bad luck.
- A test that is skipped and left in place is a claim of coverage that does not
  exist. Delete it or fix it.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| What is an error versus a result, and log content | `error-handling-and-logging` |
| Security testing and threat cases | `security-appsec` |
| Framework-specific test utilities and harnesses | the relevant `stack-*` skill |
| Language-agnostic judgment | `base` |
| Test runner, file layout, naming, coverage tooling | the project's `CLAUDE.md` — facts, not judgment |
| Assertion style and lint rules | tooling, per C2 |

Performance testing, load testing, contract testing between services, and
end-to-end browser automation are absent because no real task has justified them
yet.
