---
status: accepted
date: 2026-07-31
---

# Plan and brainstorm documents are untracked working memory, not history

## Context and Problem Statement

Agent-assisted workflows produce plan and brainstorm documents under
`docs/plans/` and `docs/brainstorms/`. They are shared memory for a task —
written and repeatedly revised by an agent, read by its subagents and by a
human, argued over, corrected mid-flight. They describe *intended* work.

Committing them puts a snapshot of intent into permanent history, where it
competes with the code as a description of the system and immediately begins to
rot. The failure is concrete: this repo's own capture-toolchain plan documented
nineteen review findings against code whose history was then rewritten so those
defects never shipped — leaving a tracked document describing defects the
history no longer contains.

## Decision Drivers

- History should describe the system as built, not the intentions or the route.
- Long-lived documentation has to be maintained; nobody maintains a plan after
  the work lands.
- Agent working files churn heavily — many revisions per task, most superseded
  within the same session.

## Considered Options

- **Ignore `docs/plans/` and `docs/brainstorms/`** — chosen.
- Commit them as historical artifacts — they go stale on landing, duplicate ADRs
  badly, and can contradict a curated history (see above).
- Commit while in progress, delete when the work lands — still permanent in
  history, and adds a churn commit per task.
- Keep them in a side-car or separate branch — per-task ephemera do not justify
  the plumbing, and [0004](0004-private-sidecar-repo.md)'s side-car exists for
  private machine-specific config, not scratch.

## Decision Outcome

`docs/plans/` and `docs/brainstorms/` are listed in the repo `.gitignore`,
alongside the existing `notes/` and `/.claude/` scratch entries. They live in the
working tree only.

Durable documentation is exactly two things: **`docs/decisions/`** (ADRs — why
the system is shaped as it is) and **READMEs** (how to use it). Anything in a
plan worth keeping is promoted into an ADR or a README *before* the plan is
discarded; the plan is not the record, it is the scaffolding that produces one.

### Consequences

- Good: history describes the system as built. No stale statement of intent
  competing with the code, and no tracked document that a later history rewrite
  can contradict.
- Good: agents and humans revise plans freely — no commit noise, no review
  burden on a file that is scaffolding.
- Bad: plans are not backed up or shareable through the repo. They exist in one
  working tree and in the agent session that wrote them; a lost plan is
  re-derivable from the ADRs and the code, but not recoverable.
- Promotion into an ADR is manual and easy to forget. The mitigation is that the
  planning workflow treats ADR-writing as explicit work rather than a side
  effect — the capture-toolchain plan carries three such units.
