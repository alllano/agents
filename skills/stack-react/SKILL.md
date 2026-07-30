---
name: stack-react
description: Apply when writing or changing React code, on any platform. Judgment
  on component boundaries, where state lives, what belongs in an effect, and what
  the compiler now handles. Load together with the base skill, and with
  stack-react-web or stack-react-native for the platform.
---

# stack-react

> Status: draft — complete content, not yet exercised on a real task.

## When this applies

Any task in a React codebase, regardless of what it renders to. Load `base`
alongside this, and the platform skill on top: `stack-react-web` for the browser,
`stack-react-native` for mobile. This file holds only what is true of React
itself.

Nothing here restates what a linter or the type checker can catch. Rules-of-hooks
violations, missing dependencies, and unused props are tooling's job.

## Components are boundaries, not files

- A component exists to own one thing: a piece of UI and the state that UI needs.
  Splitting a file to make it shorter produces two components that are really one.
- Props are the contract. A component that reaches around its props — into a
  global, a context it wasn't given, or the DOM — has a second contract nobody
  can see.
- Compose instead of configuring. Five boolean flags that change what a component
  renders are five components wearing one name.
- Pass children rather than data when the parent shouldn't care what goes inside.
  A component that accepts `children` doesn't need to know the shape of them.

## State belongs where it is used

- Put state in the component that needs it. Lift it only when a second component
  genuinely needs the same value, and only as far as the nearest common owner.
- Derived values are not state. If it can be computed from what you already have,
  compute it — storing it creates two sources of truth that will disagree.
- Remote data is not local state. Copying it into `useState` means owning
  staleness, refetching, and invalidation by hand.
- Two pieces of state that always change together are one piece of state.
- Context is for values that are genuinely ambient — theme, locale, the current
  user. Using it to avoid passing a prop two levels down trades an explicit path
  for an invisible one.

## Effects synchronize with the outside

An effect exists to reconcile React's state with something that is not React. If
it doesn't talk to the outside, it isn't an effect.

- Not for deriving values: compute during render.
- Not for responding to a user action: do the work in the handler, where the
  cause is visible.
- Not for orchestrating a sequence of state updates. A chain of effects that each
  trigger the next is control flow hidden in the render cycle.
- Every effect that starts something must be able to stop it. Subscriptions,
  timers, and in-flight requests need cleanup, or a fast unmount leaves them
  running.
- An effect that runs twice must be safe to run twice.

## Memoization is the compiler's job

React Compiler reached 1.0 in October 2025 and applies memoization at build time.
Hand-memoizing by default is now wasted work and diff noise.

- Do not add `useMemo` or `useCallback` as routine optimization.
- Reach for them when a third-party library depends on reference equality, or
  when you measured a real problem the compiler did not solve. Say which.
- Removing existing hand-memoization from code the compiler covers is a real
  simplification — but it is a change of its own, not something to bundle into an
  unrelated diff.
- Whether the compiler is enabled is a project fact, recorded in the project's
  `CLAUDE.md`. In a framework that turns it on by default it is automatic;
  elsewhere it is opt-in and someone has to have opted in.

## Keys identify, they do not order

- A key answers "which item is this", so it has to come from the item, not from
  its position. An array index as key tells React the third thing is still the
  third thing after you delete the second.
- The symptom is state attached to the wrong row: a focused input, a toggle, a
  half-typed value jumping to a neighbour.
- Changing a key deliberately is how you reset a subtree. That is a real
  technique, and it should be commented as intentional when used.

## Custom hooks name a behavior

- A hook should have a name that says what it does for the caller, not what it
  calls internally. `useUser` is a behavior; `useEffectAndState` is a wrapper.
- Extract a hook to reuse behavior or to hide a subscription, not to shorten a
  component. Moving six lines out of a long component leaves a long component
  plus a hook.
- A hook that only makes sense inside one component belongs inside that
  component.

## What this skill leaves out

Deliberate exclusions, with their owner. Do not add them here.

| Topic | Owner |
|---|---|
| DOM, routing, browser storage, bundles | `stack-react-web` |
| Native platform concerns | `stack-react-native` |
| Error handling and logging | `error-handling-and-logging` (G4) |
| Test design, including component tests | `testing` (G4) |
| Untrusted input, authorization, secrets | `security-appsec` |
| Language-agnostic judgment | `base` |
| React version, compiler setting, state library | the project's `CLAUDE.md` — facts, not judgment |
| Rules of hooks, dependency arrays, prop types | tooling, per C2 |

Server Components, streaming, and server-side rendering are absent because no
real task has justified them yet.
