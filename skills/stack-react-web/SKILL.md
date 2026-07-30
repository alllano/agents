---
name: stack-react-web
description: Apply when writing React that runs in a browser. Judgment on the DOM
  and accessibility, what belongs in the URL, browser storage, the network
  boundary, and what the bundle costs the user. Load together with base and
  stack-react.
---

# stack-react-web

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

React code that renders to a browser. Load `base` and `stack-react` first: this
adds only what the browser brings, and never contradicts them.

## The DOM is a platform, not a detail

The browser already implements most of what a UI needs. Reimplementing it is how
behavior gets lost.

- Use the element that means what you mean. A `button` is focusable, activates on
  Enter and Space, and announces itself; a `div` with `onClick` does none of that
  and is broken for keyboard and screen-reader users — not styled differently,
  broken.
- Let native form behavior work: labels tied to inputs, submit on Enter,
  validation and autofill. Intercepting all of it to rebuild it by hand loses
  cases you will not think of.
- Accessibility is correctness, not decoration. Focus order, focus visibility,
  and what an assistive technology announces are part of whether the feature
  works, and they are cheapest to get right while writing it.
- Reach for ARIA when no native element fits, not to describe one that does.
  Correct markup needs less ARIA, not more.

## The URL is state

- Anything a user should be able to reload into, share, or reach with the back
  button belongs in the URL. Filters, the open tab, the selected item, pagination.
- `useState` for that kind of state silently breaks refresh and the back button,
  and the bug report arrives as "it lost my place".
- The reverse is also true: transient UI state — a hover, a half-typed field, an
  animation — does not belong in the URL.
- Treat URL parameters as untrusted input. They are user-editable by definition.

## Browser storage has a contract

Persisting to the browser means owning what happens when the data is stale,
partial, or gone. Decide these before writing, not after a support ticket.

- Say what happens when it is missing. Storage can be cleared, disabled, full, or
  in a private window. The path where there is nothing there must be a designed
  path.
- Stored data outlives the code that wrote it. Version the shape and decide how
  an old record is read by a new version — a migration you did not write is a
  crash on someone's returning visit.
- Name what is authoritative. If the same fact lives both locally and on a
  server, one of them wins, and the code must say which and when.
- Nothing sensitive goes in browser storage. It is readable by any script that
  runs on the page, so it is not a place for tokens or secrets.
- Storage is per-origin and per-device, not per-user. A shared machine shares it.

## The network boundary is visible

- Loading, empty, and error are states of the UI, not exceptions to it. A screen
  designed only for the success case will show something wrong in the other three.
- Distinguish empty from failed. "You have no items" and "we could not load your
  items" require different words and different next steps.
- Assume it can be slow and can happen twice. Guard against a double submit, and
  drop the response of a request whose result is no longer wanted.
- Never render an error object to the user. It says nothing to them and may say
  too much to an attacker.

## What ships is a user cost

- Every dependency and every byte is paid for by the user's device and connection,
  on hardware you do not control and did not test on.
- Split at boundaries that mean something — a route, an interaction, a rarely-used
  feature — not wherever a file happens to be large.
- Before adding a library, check what it pulls in and whether the platform already
  does the job. Date formatting, fetching, and validation often need no dependency.
- Weigh the cost against the frequency. A heavy dependency that loads for every
  visitor to serve a feature few of them use is in the wrong place.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| Components, state, effects, hooks | `stack-react` |
| Error handling and logging | `error-handling-and-logging` (G4) |
| Test design | `testing` (G4) |
| Untrusted input, authorization, secrets | `security-appsec` |
| Language-agnostic judgment | `base` |
| Build tool, router, storage and state libraries | the project's `CLAUDE.md` — facts, not judgment |
| Formatting, class ordering, import order | tooling, per C2 |

CSS architecture, animation, internationalization, and offline-first
synchronization are absent because no real task has justified them yet.
