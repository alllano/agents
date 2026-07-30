# Conventions

Locked architectural decisions for this repository, with the reasoning behind
them.

## Purpose, and the boundary with CLAUDE.md

`CLAUDE.md` is the **instruction set**: imperative, loaded every session, and
therefore kept short. This file is the **decision record**: why each rule
exists, what was considered and rejected, and what breaks if it is reversed. It
is read on demand, not every session.

The test is the kind of sentence, not the topic. If you are writing something
Claude must *do*, it belongs in `CLAUDE.md`. If you are writing *why* — or an
alternative that was rejected — it belongs here. No rule appears here that is
not already stated in `CLAUDE.md`, and no rationale appears in `CLAUDE.md` that
is not recorded here.

Each entry is `locked`. Locked does not mean permanent; it means it is not
reopened casually, and the procedure at the end applies.

---

## C1 — Partition by artifact type, not by agent

**Decision.** `agents/` holds one flat `.md` per agent. `skills/` holds one
folder per skill. Neither is nested inside the other.

**Why.** Claude Code discovers skills by scanning `skills/`. It does not resolve
them relative to whichever agent is running.

**Rejected.** Grouping each agent with the skills it uses. It reads better in a
file tree and breaks discovery outright.

**Consequence.** The relationship between an agent and its skills is expressed
in the agent's body text, not by file location. See C4.

Status: locked, 2026-07-29.

---

## C2 — Mechanical rules are delegated to tooling

**Decision.** Anything a linter, formatter, analyzer, or test can verify is left
to that tooling and is never restated as a rule in a skill.

**Why.** A rule stated in two places drifts. When prose and configuration
disagree, the configuration is what actually runs, so the prose becomes a lie
that still consumes context on every load.

**Rejected.** Documenting the formatting rules "so Claude knows them". Claude
does not need to be told what the formatter will do to the file anyway.

**Consequence.** Skills carry only what needs judgment. A skill that is mostly
mechanical rules is a signal that the project is missing tooling, not that the
skill is incomplete.

Status: locked, 2026-07-29.

---

## C3 — Agnostic separated from stack-specific

**Decision.** What would be identical in any language lives in `skills/base/`.
What changes with the technology lives in `skills/stack-<name>/`.

**Why.** The agnostic half is stable and is loaded for every task. The
stack-specific half changes with framework versions and applies to a subset of
work. Mixing them means every change to a framework convention risks disturbing
the principles that do not depend on it.

**Rejected.** One large skill per stack containing both. It duplicates the
agnostic content once per stack, and the copies diverge.

**Consequence.** A rule that seems to belong in both places is two rules in two
files, not one rule in the wrong file. `base` and the relevant `stack-*` are
loaded together; the stack skill adds to `base` and never restates it.

Status: locked, 2026-07-29.

---

## C4 — Skills are loaded belt and suspenders

**Decision.** An agent gets its skills two ways at once: the skill's own
`description` auto-triggers it, and the agent body carries an explicit
instruction to load it by name.

**Why.** There is no frontmatter field for declaring that an agent depends on a
skill. Auto-triggering alone depends on the description matching the task
wording; the explicit instruction alone depends on the agent being the entry
point.

**Rejected.** Relying on the `description` trigger alone. It fails silently and
invisibly — the work still happens, just without the skill.

**Consequence.** `description` must be written as a trigger, not a summary. It
is the only part of a skill Claude sees before deciding whether to load it.

Status: locked, 2026-07-29.

---

## C5 — Distribution is one link per artifact

**Decision.** `setup.sh` and `setup.ps1` link each skill directory and each
agent file into the Claude Code config directory individually. The parent
`skills/` and `agents/` directories are never linked.

**Why.** `~/.claude/skills` and `~/.claude/agents` are namespaces owned by
Claude Code and shared with everything else installed there. Linking one whole
is destructive by construction: to put a link where a real directory is, that
directory has to be moved or deleted first. Per-artifact linking is purely
additive, and a mistake affects one skill instead of the entire global config.

**Rejected.** Linking the two directories whole. It is simpler and it means a
`git pull` needs no follow-up even when it adds a new artifact — but it
reserves the namespace for this repository alone, and it makes uninstall
undecidable, because undoing it means restoring a directory that was destroyed.

**Rejected.** Copying instead of linking. Edits would then require reinstalling,
which is the property the repository exists to provide.

**Rejected.** Hardlinking agent files on Windows where symbolic links are
unavailable. `git pull` replaces the file rather than writing through the inode,
so the hardlink detaches and the installed copy freezes at old content with no
visible symptom. Reporting the artifact as blocked is worse ergonomics and
honest; an opt-in copy states its own staleness.

**Consequence.** A `git pull` that *adds* an artifact requires re-running the
installer. Content edits and renames propagate with no action. Every link stores
an absolute path, so moving or re-cloning the repository requires a re-run,
which the `REPAIRED` state handles.

Status: locked, 2026-07-29.

---

## C6 — Templates are copied, never linked

**Decision.** `templates/` is excluded from the installer. Its files are copied
into a project and edited there.

**Why.** A template exists to be diverged from. The moment a project fills one
in it stops being the template, and a link would either propagate one project's
answers to every other project or make the file unwritable in practice.

**Rejected.** Linking templates for consistency. Consistency is not the goal;
a correct starting point is.

**Consequence.** Improvements to a template do not reach projects already
started from it. That is accepted — retrofitting is a per-project decision.

Status: locked, 2026-07-29.

---

## C7 — Global artifacts are never shadowed locally

**Decision.** A project never defines a skill under the same name as a global
one. Project-specific deviations go in the overrides section of that project's
`context.md`.

**Why.** Resolution order — enterprise, then personal, then project — makes the
global version win, so the local file looks authoritative while having no
effect. Subagents have additionally been reported to ignore the local version
entirely.

**Rejected.** Local overrides by name, the way most configuration systems work.
The resolution order here does not support it.

**Consequence.** Overrides are declarative, in prose, in one known place per
project, and they say what global rule they are contradicting and why.

Status: locked, 2026-07-29.

---

## C8 — Artifact state is stub, draft, or usable

**Decision.** Three states, judged by evidence rather than intent. A **stub**
still contains TODO markers. A **draft** has complete content but no record of
being exercised. **Usable** has been run against a real task.

**Why.** Without the third state, "finished writing it" and "know it works" are
indistinguishable, and an untested skill silently becomes a dependency.

**Rejected.** A binary done/not-done. It collapses precisely the distinction
that matters here.

**Consequence.** An artifact is labeled in its own body until it reaches usable.
Saying "done" about a draft is a reporting error, not a rounding.

Status: locked, 2026-07-29.

---

## C9 — Build order is sequential and exercise-gated

**Decision.** Groups G1 to G7 advance in order, and no group starts until the
previous group's output has been exercised on a real project.

**Why.** These artifacts change how code gets written across every project.
Content designed in the abstract encodes guesses, and guesses that are never
tested accumulate faster than they can be corrected.

**Rejected.** Writing the full set up front and refining later. The refinement
step does not happen once the set looks complete.

**Consequence.** Directories are not pre-created for future artifacts, since
empty placeholders invite filling them. Skills documenting libraries that do
not exist yet stay unwritten rather than speculative.

Status: locked, 2026-07-29.

---

## C10 — English in files, Spanish in conversation

**Decision.** Everything committed — skills, agents, templates, docs, READMEs —
is written in English. Conversation about the work is in Spanish.

**Why.** The repository is public and its artifacts are consumed by a
model whose instruction-following is most reliable in English. The conversation
has one participant and no such constraint.

**Rejected.** Spanish throughout, for consistency with how the work is
discussed. It narrows who can use the repository for no gain.

**Consequence.** A commit whose files are in Spanish is a defect, and the
conversation that produced it is not.

Status: locked, 2026-07-29.

---

## Changing a locked decision

Entries are superseded, not edited. To reverse one, add a new entry that states
the new decision and names what it supersedes, and mark the old entry
`Status: superseded by C<n>, <date>` while leaving its text intact.

The reason for keeping the old text is that the rejected alternatives are the
valuable part. An entry that is quietly rewritten loses the record of what was
already tried, which is exactly what makes the same argument recur.
