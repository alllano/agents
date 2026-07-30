---
name: stack-nest
description: Apply when writing or changing NestJS code. Judgment on module
  boundaries, layer responsibilities, injection, validation at the edge, and
  which Nest primitive fits a concern. Load together with the base skill.
---

# stack-nest

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

Any task in a NestJS codebase. Load `base` alongside this: `base` covers
judgment that holds in any language, and this adds only what Nest changes.
Where they seem to disagree, `base` is the general rule and this is the
specialization.

This skill assumes the modular architecture the official documentation teaches:
a module per domain feature, controller into service, dependency injection as
the default way things find each other. It is what most Nest code in the world
looks like, which makes it the cheapest thing to read and to hand over. A
project that genuinely needs hexagonal layering or CQRS adds that on top and
says so in its `context.md`; it is not assumed here.

Generate new projects as **ESM**. Nest 12 moves every official package to ESM,
and starting a new project in CommonJS today is signing up for a migration
later. An existing CommonJS project stays CommonJS — that is a fact about the
project, recorded in its `context.md`, not something to change opportunistically.

## Modules are the unit of encapsulation

- One module per domain feature, holding its controller, service, and DTOs
  together. Deleting a feature should be deleting a folder.
- Export only what another module actually injects. Exporting everything
  recreates the global scope that modules exist to prevent.
- Reach for `@Global()` when a provider is genuinely infrastructure for the
  whole application, not when wiring a module properly feels tedious.
- Organize by feature, not by technical layer. A folder of every service in the
  application tells you nothing about the application.
- Watch the depth of the tree. Every extra level is something a reader has to
  hold to see one feature whole.

## Each layer answers one question

- The controller translates HTTP into a call and back. Routing, status, shape of
  the response. Nothing else.
- The decision lives in the service. If reading the controller tells you the
  business rule, the rule is in the wrong place.
- Below the controller, HTTP does not exist: no `Request` or `Response` objects,
  no status codes, no headers. A service that knows it is being called over HTTP
  cannot be called any other way.
- A service that only forwards to another service is not a layer, it is a
  detour. Delete it or give it a reason.

## Injection reflects the boundary

- Constructor injection is the default. Reserve the alternatives for cases that
  cannot use it, and say which case.
- Depend on what you need, not on the module it lives in.
- A `forwardRef` is a diagnosis, not a tool: two modules that need each other
  are one module, or they are missing a third that both depend on. Fix the
  boundary before reaching for the escape hatch.
- Providers are singletons unless stated otherwise. Request scope is a real
  cost and it spreads to everything that injects it — use it when the state is
  genuinely per-request, and record why.
- Inject an abstraction when you have a second implementation or a boundary you
  intend to defend. Introducing an interface and a token for a single concrete
  class is ceremony, not decoupling.

## Validate at the edge, trust inward

- The DTO is the contract. It says what this endpoint accepts, and it is the
  only place that question is answered.
- Reject unknown fields rather than ignoring them. Silently dropping input is
  how a caller finds out months later that their field never applied.
- Validate once, at the boundary, then trust the value inward. Re-validating in
  the service means neither place is authoritative.
- Parse into the type you want to work with at the edge, so the inside deals in
  domain types rather than strings that happen to look right.
- The validation library is the project's choice — `class-validator`, or a
  Standard Schema library like Zod through the `schema` option in Nest 12. The
  boundary is not a choice. Record the project's pick in its `context.md` and
  do not mix two in one codebase.

## Use the primitive that matches the concern

Nest gives a specific place for each cross-cutting concern. Putting logic in the
wrong one is the mistake that ages worst, because the behavior looks right until
something reorders.

- **Pipe** — transform and validate the input to a handler.
- **Guard** — decide whether this request is allowed to proceed.
- **Interceptor** — wrap the call: shape the response, add timing, retry.
- **Exception filter** — translate a thrown error into a response.
- **Middleware** — framework-level work that needs the raw request.

Authorization belongs in a guard, not in the service's first three lines, and
not in an interceptor. Error translation belongs in a filter, not in every
controller.

## Configuration is validated once, at startup

- Validate the whole configuration when the application boots, and refuse to
  start when it is wrong. A missing variable should fail at deploy, not on the
  first request that needs it.
- Inject configuration. `process.env` read deep inside a service is an
  undeclared dependency and it hides what the service needs to run.
- Configuration is values, not decisions. A flag that changes which code path
  runs is a design choice wearing an environment variable.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| Persistence, ORM choice and repository patterns | its own skill, once a real project fixes the choice |
| Error handling, logging | `error-handling-and-logging` (G4) |
| Test design, coverage judgment | `testing` (G4) |
| Authentication and authorization design | `security-appsec` |
| Language-agnostic judgment | `base` |
| Nest version, module format, test runner, linter, builder | the project's `context.md` — facts, not judgment |

Microservices, GraphQL, WebSockets, and queues are absent because no real task
has justified them yet.
