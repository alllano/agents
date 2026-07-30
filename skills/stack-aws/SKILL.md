---
name: stack-aws
description: Apply when writing or changing code, configuration, or deployment
  that runs on AWS. Judgment on identity and permissions, how configuration and
  secrets reach a workload, choosing compute, trust between services, and cost as
  a design output. Load together with base and security-appsec.
---

# stack-aws

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

Work that runs on AWS or configures it: application code using AWS services,
deployment configuration, CI that deploys.

Load `base` and `security-appsec` alongside this. `security-appsec` is the natural
pair — most of what goes wrong here is an access-control or secret-handling
decision that happens to be expressed in AWS terms.

Which services a project uses, in which regions, at what instance sizes, are
project facts recorded in its `CLAUDE.md`. This skill holds the judgment that
applies regardless of which services those are.

## Identity is the perimeter

- Grant permissions to the workload, not to a person. A role a service assumes
  can be scoped to exactly what that service does; a human's credentials in a
  deployment cannot.
- Scope to the specific actions and the specific resources. A wildcard is a
  decision to allow everything that gets added later, made before it exists.
- Long-lived access keys are the thing to eliminate, not the thing to rotate more
  often. A key that exists can leak; identity federation for CI exists so there is
  no key to leak in the first place.
- Grant what the task needs now. "We might need it later" permissions are
  indistinguishable from a mistake when someone audits them, and nobody removes
  them.
- Separate what must not be reachable from one identity. If one compromised
  component can do everything, the blast radius is the whole system.

## Configuration is delivered, not stored, in the environment

- An environment variable is how a value reaches the process. It is not where the
  value lives. The store is a parameter or secret service, with access controlled
  and reads auditable.
- Nothing sensitive goes in the code, the image, the build log, or the task
  definition in plain text. All four are copied and retained in places nobody is
  thinking about.
- Design for rotation before there is anything to rotate. A secret that cannot be
  changed without downtime will not be changed, and that decision gets made once,
  early, by accident.
- Validate configuration when the workload starts and refuse to start when it is
  wrong. A missing value should fail the deploy, not the first request that needs
  it.
- Configuration differs between environments; the code that reads it must not.
  Branching on the environment name inside application code puts deployment
  topology in the domain.

## Each compute choice has a shape

Choosing where something runs is accepting its constraints, not just its price.

- Functions are stateless, time-bounded, and start cold. Work that is long-running,
  stateful, or latency-critical on the first call is fighting the model.
- Anything you keep in memory or on local disk is gone when the instance is
  replaced, and it will be replaced. If it must survive, it belongs somewhere
  designed to hold it.
- A workload that scales to zero costs nothing idle and pays a cold start; one
  that stays warm does the opposite. Pick according to the traffic shape you
  actually have.
- Heavy or unusual runtime dependencies constrain where a workload can run. Decide
  that placement deliberately and record it — the reason will not be obvious to
  whoever moves it later.
- Retries exist at layers you did not write. Anything invoked by a queue, an
  event, or a scheduler may run twice, so it has to be safe to run twice.

## Trust between services is asymmetric

- The service holding a signing key is the only one that can issue. Everything
  else verifies with the public half, locally.
- A service that calls its issuer on every request has converted a startup
  dependency into a runtime one: now the issuer's availability is its availability,
  and its latency is on every path.
- Dependencies between services should point one way. Two services that call each
  other are one service with a network in the middle, and they will fail together
  in a way neither was designed for.
- Say what happens when a dependency is unavailable. Degraded is a design;
  hanging is what you get without one.
- Never let a caller choose which internal address a service reaches. A
  server-side request built from input is the caller acting with your permissions
  — see `security-appsec`.

## The bill is a design output

- Cost follows from architecture, so it is decided when the design is, not when
  the invoice arrives.
- Know which of the two you just added: something that scales with traffic, or
  something that costs the same whether it is used or not. Both are fine; not
  knowing which is not.
- Data transfer and storage growth are the costs that surprise people, because
  they accumulate quietly instead of spiking.
- Anything that retains data forever is a growing cost and a growing liability.
  Decide the retention when you create the store, because nobody comes back to it.
- Set a budget alarm before the first deploy, not after the first surprise. It is
  the cheapest thing in this section.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| Trust boundaries, authorization placement, secret handling in general | `security-appsec` |
| What to log and at what level | `error-handling-and-logging` (G4) |
| Framework-level configuration and validation | the relevant `stack-*` skill |
| Language-agnostic judgment | `base` |
| Which services, regions, instance sizes, account layout | the project's `CLAUDE.md` — facts, not judgment |
| Infrastructure-as-code linting and policy scanning | tooling, per C2 |

Networking topology, disaster recovery, multi-region strategy, and organization
and account structure are absent: they are operational design rather than code
judgment, and no real task has justified them here.
