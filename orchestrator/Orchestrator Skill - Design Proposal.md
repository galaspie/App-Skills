# Orchestrator Skill — Design Proposal

Validated by a manual dry run on a real sprint (GeoWatch Verdict Persistence, in
`App-BoatingGoNoGo`). This proposes automating the mechanical parts of that run —
file routing, round-capping, template application — while keeping every judgment
call with Paul.

## Purpose

Remove the toil of manually running both engines, copying files, and tracking round
state — without automating anything that requires judgment: what counts as a
blocking ambiguity's answer, which proposal to build from, when to deploy.

## Scope for v1

- **Claude's leg**: automatable today via `claude -p` (headless, non-interactive).
- **Codex's leg**: automatable today via `codex exec` — confirmed this session:
  stdin prompt, `-C` for repo selection, `--output-last-message` for file output,
  `--sandbox read-only`, `--ask-for-approval never`, `--ephemeral`, real exit codes.
  Build it headless from v1 — no reason to keep manual relay now that the capability
  is confirmed.
- **Not a daemon.** No background process, no always-on watcher. Invoked on demand,
  one sprint at a time, runs to completion or to the point it needs Paul, then stops.

## Inputs

- `sprint_title` — human-readable; used identically for the folder name and every
  filename. One variable, not two, so folder and contents can't drift the way they
  did on the GeoWatch run (folder said "Verdict Persistence," files just said
  "Persistence").
- `target_project_path` — the repo the sprint is about; `proposals/` lives inside it.
- `problem_statement` — the actual ask, written fresh per invocation.
- Engine list — fixed at two (Claude, Codex) for v1.

## Process (state machine)

1. **Kickoff** (optional per sprint)
2. **Initial Proposal** — both engines, independently, fully blind to each other
3. **Ambiguity check** — if either returns BLOCKING QUESTIONS, aggregate, surface to
   Paul once, wait, resume with his answer injected as a flat settled fact
4. **Revision round** — reusable template, both engines
5. **Convergence gate** — Orchestrator's own bounded, symmetric, binary read of the
   latest pair; loops back to step 4 if unresolved, proceeds if not. The gate's
   finding never re-enters an engine prompt — Paul's visibility only.
6. **Final** — both engines produce a complete document + a verification checklist
7. **Orchestrator's summary** — read-only synthesis for Paul: consolidated picture
   per engine, factual convergence/differences, both checklists, a methodology note
   on anything that deviated from a clean run. No recommendation, ever.

## Mechanics

- Every engine call is bounded by a real timeout — a hang is a reported failure, not
  silence.
- No meta-process information ever reaches either engine: no round count, no "this
  is final," no "Orchestrator noticed a difference." Only flat, Paul-approved facts
  when something is genuinely settled.
- File-based state — the folder contents *are* the state machine. No database. Any
  session can inspect the folder and know exactly what phase a sprint is in.
- One filename convention, always: `{sprint_title} - {stage}.md`.

## Guardrails carried over from the dry run (hard-won — don't relearn these)

- Orchestrator never arbitrates, recommends, or picks a winner.
- Orchestrator never reads proposal content mid-process and volunteers analysis —
  only the explicitly-scoped convergence gate, which is symmetric and binary, never
  a content judgment.
- Anything resolved in a side conversation with Paul gets reduced to a flat fact
  before it reaches either engine — never Orchestrator's own framing of what the
  disagreement was. (This is exactly where the GeoWatch run's one contamination
  happened — a legitimate side conversation's conclusion leaked into a prompt as
  pre-digested analysis.)
- Explicit permission, stated in the prompt itself, to report "unchanged" in one
  line — no rewriting to appear thorough.
- `proposals/` and `intake/` folders are gitignored, never committed. Promotion of a
  winning proposal to `docs/` is a manual, deliberate action by Paul, outside
  Orchestrator's scope entirely.

## Open decisions for Paul before build

1. Kickoff step — standing default-on, or opt-in per sprint?
2. Ambiguity self-check — repeat at every stage, or only at Initial Proposal (current
   assumption, matches what actually ran)?
3. Build as a Claude Code Skill (slash command), or a standalone script? Recommend
   the skill — lowest overhead, reuses existing tool access and the `codex exec`
   capability already confirmed, no new runtime to stand up or maintain.

## Validation plan

Before trusting this for real sprint work: re-run the GeoWatch Verdict Persistence
scenario through the built process, same problem statement, different sprint name so
it doesn't collide with the manual run's folder. Compare its output against this
session's manual run — same convergence, same guard discoveries, same schema, no new
contamination. Any divergence is itself the bug report, not a reason to assume the
manual run was wrong.
