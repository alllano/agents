---
name: stack-prisma
description: Apply when writing or changing code that uses Prisma, or when
  changing a Prisma schema or migration. Judgment on the schema as source of
  truth, migration safety, keeping the ORM behind a boundary, query shape, and
  transaction scope. Load together with base and the server stack skill.
---

# stack-prisma

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

Any task touching a Prisma schema, a migration, or code that queries through
Prisma. Load `base` and the server-side stack skill alongside this.

The Prisma major version, the database provider, and whether a driver adapter is
in use are project facts, recorded in the project's `CLAUDE.md`. They change what
is possible; they are not judgment and do not belong here.

Nothing here restates what the CLI or the schema language already enforces.
Field types, relation validity, and formatting are checked for you.

## The schema is the source of truth

- The schema defines the shape of the data, and everything else follows from it:
  the client, the migrations, the types the application sees.
- Generated output is a build artifact. Regenerate it, never edit it — an edit
  survives exactly until the next generate, and the bug it causes appears
  somewhere unrelated.
- Changing the database by hand puts it out of step with the schema, and the
  schema is what the next migration diffs against. The drift is discovered on the
  next deploy, in the worst place.
- Name things in the schema for the domain, not for the storage. The schema is
  read more often than any query written against it.

## Migrations are immutable history

- A migration that has been applied anywhere is history. Editing it means the
  database that ran the old version and the one that runs the new version are
  both "migrated" and are not the same.
- To change what a migration did, add another one on top.
- Destructive changes go in three deploys, not one: add the new shape, backfill
  and move reads and writes over, then remove the old shape. Each step has to be
  safe with both the old and the new code running, because during a deploy they
  are.
- A migration that cannot go forward without losing data is not ready. Say what
  the plan is before writing it, not after it fails in staging.
- Test the migration against data shaped like production. An empty database
  migrates cleanly and tells you nothing.

## Keep Prisma behind a repository boundary

- Domain code should not know which ORM it has. Queries live in a repository;
  services ask the repository for what they need.
- Do not return Prisma model types upward. The moment a generated type crosses
  into the domain, the boundary exists in the folder structure and nowhere else,
  and "we could swap the ORM" stops being true.
- The repository's methods should be named for what the domain wants, not for
  the query they run. `findActiveSubscribers` is a domain question;
  `findManyWhereStatusEquals` is a query with a name.
- A repository that just forwards every Prisma method with a different name is
  not a boundary. Either it expresses domain operations or it should not exist.

## Ask for exactly what you need

- Choose what a query returns deliberately. The default shape is either more than
  the caller uses — which is bandwidth and memory spent on nothing — or less,
  which becomes a second query.
- The N+1 problem is not an ignorance problem, it is a convenience problem: the
  loop that queries per item is the easiest thing to write and looks fine on ten
  rows. Fetch the set in one query, and check the shape of the query the loop
  produces before assuming it is fine.
- Reaching for raw SQL is legitimate when the query is genuinely beyond the
  builder. It also drops the type safety and the parameterization you were
  relying on — so pass parameters, never interpolate, and say why the raw query
  is there.
- Pagination is part of the contract, not an optimization to add later. A query
  with no bound returns whatever the table has grown to.

## Transactions have a boundary and a cost

- Decide what must be atomic and make that the transaction. Wrapping more than
  that holds locks other work is waiting on.
- A transaction that waits on something outside the database — an HTTP call, a
  queue, a model — holds the database open for as long as the other system takes
  to answer. That is not caution, it is a way to exhaust the connection pool.
- Reads and writes inside one transaction see a consistent view; two separate
  calls do not. If a decision depends on what a read returned, the write that
  acts on it belongs in the same transaction.
- Say what happens on rollback. Work already done outside the database does not
  roll back with it, and that is the case that produces the duplicate.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| Where repositories sit in the module graph | the server-side `stack-*` skill |
| Whether a failed query is an error or a result | `error-handling-and-logging` (G4) |
| Testing against a real database versus a mock | `testing` (G4) |
| Access control over rows and fields | `security-appsec` |
| Language-agnostic judgment | `base` |
| Prisma version, provider, driver adapter, connection settings | the project's `CLAUDE.md` — facts, not judgment |
| Schema formatting and lint rules | tooling, per C2 |

Read replicas, sharding, multi-tenancy strategies, and caching layers are absent
because no real task has justified them yet.
