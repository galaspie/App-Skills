---
name: orchestrator
description: >
  Runs a sprint's problem statement through two independent engines (Claude
  and Codex) in parallel: each proposes a solution blind to the other, then
  they critique and revise each other's latest file in rounds until a
  bounded, binary convergence check says nothing that affects what gets
  built differs anymore, then each produces a complete Final document and a
  behavior-based verification checklist, and the skill produces a read-only,
  no-recommendation synthesis for Paul. File-based state only, in
  proposals/{sprint_title}/{claude code,codex}/ inside the target repo — no
  daemon, no background watching, runs to completion or to the point it
  needs Paul, then stops. Use whenever Paul says "/orchestrator", wants a
  sprint or enhancement design run through both engines independently, or
  references "the orchestrator" process validated on the GeoWatch Verdict
  Persistence dry run.
---

# Orchestrator — Two-Engine Sprint Proposal Process

Source design: `App-orchestrator/Prompt Templates.md` and
`App-orchestrator/Orchestrator Skill - Design Proposal.md`. Validated by a
manual dry run on GeoWatch Verdict Persistence in `App-BoatingGoNoGo`.

## What this is NOT

- Not a daemon, not a background watcher. Every engine call is a single
  blocking subprocess invocation (`claude -p ...`, `codex exec ...`) that
  runs, finishes, and returns. Nothing runs between invocations.
- Not an arbiter. This skill never picks a winner, never recommends one
  proposal over the other, never adds its own technical opinion on the
  subject matter. Paul decides from here, always.
- Not a content judge mid-process. The only place this skill reads and
  reasons about proposal content before the final summary is the
  convergence gate (bounded, binary, see below) — never a free-form
  critique.

## 1. Parse the invocation

Look for two literal labels in what Paul typed after `/orchestrator`:

- `Sprint Name:` — required, verbatim. This becomes the folder name and
  every filename for this sprint, unchanged, nowhere abbreviated or
  reworded. If missing, ask for it before doing anything else — do not
  guess or infer it from prose, sprint-title drift is the exact bug this
  process is designed to prevent (it happened on the manual GeoWatch run).
- `Request:` — required. Contains the actual problem statement, free
  prose.

`target_project_path` is **always the directory this session is already
rooted in** — never inferred or fuzzy-matched from a project name
mentioned in `Request:` prose. Writing proposal files into the wrong repo
is a real, irreversible-feeling mistake (e.g. PapaGKnows content landing in
a TradingView folder because a name loosely matched), so this is not a
guess-and-confirm-if-ambiguous situation — it's never inferred from text at
all. If Paul names a different project in the Request text than the one
the session is rooted in, stop and ask him to confirm explicitly which
path he means before creating anything — do not silently prefer either
the session's cwd or the mentioned name.

Also check whether Paul indicated a Kickoff step should run (opt-in,
default off — see step 3). If unstated, skip it silently — do not ask.
Only run Kickoff if Paul explicitly said to in the invocation.

`problem_statement` is everything in `Request:` — pass it through to the
engines close to verbatim; don't summarize or re-filter it.

## 2. Confirm resolved parameters (always, every invocation)

Before creating anything, echo back a short summary of every parameter —
required and optional — so Paul never has to remember what's configurable.
This replaces asking about any single param individually; it's one
combined readback instead:

```
Sprint Name: <value>
Target project: <cwd, the resolved target_project_path>
Kickoff: on | off (default: off)
Revision round cap: <value> (default: 4)
Per-engine-call timeout: <value> (default: 20 min)
```

Show this every time, including when Paul didn't mention the optional
ones — that's the whole point, it surfaces what's available without him
having to recall it. No need to wait for confirmation before proceeding
unless something looks wrong or a required field is missing; this is a
readback for visibility, not a blocking prompt, except when Sprint Name,
Request, or target project confirmation (per step 1) is genuinely missing
or ambiguous — those still stop and wait for an answer.

## 3. Bootstrap the sprint folder

- `proposals/{sprint_title}/claude code/` and `proposals/{sprint_title}/codex/`
  inside `target_project_path`. Create both.
- Check `target_project_path/.gitignore` for a `proposals/` entry
  (case-insensitive). If absent, add `proposals/` and `intake/` to it and
  tell Paul you did so — these folders must never be committed.
- Resolve the Codex binary once per session: try `command -v codex` first;
  if that fails, glob
  `%LOCALAPPDATA%\OpenAI\Codex\bin\*\codex.exe` and pick the most recently
  modified one (the versioned hash directory changes on every Codex app
  update — never hardcode a specific hash). Confirm it runs
  (`<path> --version`) before using it for real calls.

## 4. Kickoff (optional, only if Paul opted in)

Prompt (fill `{problem_statement}`):

```
{problem_statement — the situation as it stands today, no proposed fix yet}

Before we begin, confirm your understanding by reading the relevant code and
returning here with a brief summary. Do not propose a solution yet.
```

Run both engines (see "Engine invocation" below) with this prompt. This
stage does not write a file — capture each engine's returned text directly
and show both summaries to Paul in chat before continuing. If either
summary reveals a misunderstanding worth correcting, let Paul decide
whether to adjust the problem statement before Initial Proposal; don't
silently patch it yourself.

## 5. Initial Proposal (always, independent)

Prompt (fill `{problem_statement}`, `{sprint_title}`, `{engine}` = `claude code`
or `codex`):

```
{problem_statement, plus the specific ask for this sprint}

Please dig in and propose a solution. [Scope boundary specific to this sprint, if any.]

Before writing your proposal, check whether anything above is genuinely ambiguous or
missing in a way that blocks you from giving a real recommendation — not a
preference, an actual blocker. If so, stop and write only a short list headed
**BLOCKING QUESTIONS** instead of a proposal. If nothing blocks you, proceed, and
state any assumptions you made plainly inside the proposal itself.

Do not look for, reference, or guess at any other engine's work on this same
request. This must be your own independent reasoning only.

Save your output to:
`proposals/{sprint_title}/{engine}/{sprint_title} - Initial Proposal.md`
```

Run both engines **in parallel** (launch both subprocess calls before
waiting on either), block until both return. After both return, verify
success by checking the target file exists and is non-empty in each
engine's folder — do not trust stdout/last-message capture as proof of a
successful write, verify the actual file.

**Ambiguity check (only happens here, never at later stages — the
templates only define this escape hatch at Initial Proposal):** Read both
Initial Proposal files. If either is headed `BLOCKING QUESTIONS` instead of
a real proposal:

1. Aggregate every flagged question from both into one list.
2. Present it to Paul once, plainly, and wait for his answer.
3. When resuming, re-run this exact Initial Proposal step once for both
   engines, with Paul's answer folded into `{problem_statement}` as a flat,
   settled fact — e.g. "Settled: <one-line fact>, because <Paul's one-line
   reason>." Never as your own analysis of what the differences were, never
   characterized or editorialized beyond that.

## 6. Revision round (reusable verbatim, every round the gate allows)

Prompt:

```
Go read the other engine's latest file yourself — it's in the other subfolder
inside this sprint's `proposals/` folder. Read it in full.

**Part 1 — Direct critique.** Respond to it directly. Call out anything you believe
it got wrong, missed, or should have addressed.

**Part 2 — Your revision.** Revise your own proposal in light of theirs. If your
position and conclusions are unchanged, say so in one line and stop — do not reword,
restructure, or rewrite sections that are already correct merely to show that
revision occurred. A file that's identical to your last version except for that one
line is a complete and correct answer. If you do change something, state why in one
line. If you're holding ground on a real disagreement, say what you considered and
why.

Save your response in your own folder, incrementing the revision number in the
filename by one from your own last file.
```

Determine the round number mechanically: count existing files in each
engine's folder (both should match). Run both engines in parallel, block
until both return, verify both files exist and are non-empty.

## 7. Convergence gate (your own check, after every revision round — never sent to either engine)

Read both engines' latest files yourself and answer, bounded and binary:

```
Setting aside wording, phrasing, and explanatory prose — is there any remaining
difference between these two documents that would change what actually gets built,
tested, or shipped? A different file, a different write point, a different schema
or field set, a different guard or scope decision, a different test assertion, or a
different conclusion about what changes versus what doesn't?
```

- **No** → stop revising, proceed to Final (step 7).
- **Yes** → check **progress**, not correctness, before deciding whether to
  run another round:
  - If the difference reflects new ground since the last round — new
    evidence, a position reversed, a point conceded, a claim actually
    checked against the code — the engines are still working the problem.
    Note each difference in one line, factually, no characterization of
    which side is right. Report the note to Paul in chat — his visibility
    only, it never enters the next round's prompt. Run another Revision
    round (step 5).
  - If the difference is the same one from the prior round with both sides
    simply restating their position — no new argument, no new evidence, no
    concession either way — that's **no further progress**, a real stable
    disagreement rather than something another round will resolve. Stop
    revising immediately and proceed to Final (step 7), **even if the round
    cap hasn't been reached**. Never evaluate which side is correct to make
    this call — only whether the round moved anything. Final's "read the
    other engine's file" step still ensures each engine's Final document
    reflects their own last position on the unresolved point; the
    Orchestrator's Summary (step 9) is where the unresolved split actually
    surfaces for Paul to decide.

**Round cap:** default max 3 revision rounds, as a backstop — in practice
the no-further-progress rule above should trigger before the cap in most
stalemate cases. If the gate still finds genuinely *moving* differences
right up to the cap, stop anyway, report the unresolved differences to Paul
plainly, and let him decide whether to raise the cap, intervene directly,
or accept the split. Do not loop silently past the cap either way.

**Per-call timeout:** default 20 minutes per engine call. If a call exceeds
it, kill the process and report the failure to Paul — a hang is a reported
failure, not silence, never retried automatically without his say-so.

## 8. Final (once, after the gate says stop)

Prompt:

```
No further revisions are requested after this — this is your final response for
this sprint.

Go read the other engine's latest file yourself — it's in the other subfolder
inside this sprint's `proposals/` folder. Read it in full.

**Produce your complete, final proposal document** — the same full form as your
latest revision (all sections: problem, recommended solution, implementation,
testing, scope, etc.), fully updated to reflect everything settled through this
point. This is not a summary or a delta note — it is the standalone document someone
could read on its own, with no need to also open your earlier files to understand
the whole plan. If a section is unchanged, keep it as-is; if something changed,
write the updated version in full, in place.

**Separately, also produce a reusable verification checklist** — a short checklist
of observable outcomes that would prove *any* solution to this sprint's ask is
correct, framed around behavior rather than your specific files or schema, each item
checkable as pass/fail. If something can't be stated as a checkable outcome, say so
rather than padding the list with vague items.

Do not rewrite, restructure, or re-explain anything that hasn't changed, in either
part, merely to appear thorough.

Save the full proposal as `{sprint_title} - Final.md`. Save the checklist as
`Verification Checklist.md`. Both in your own folder.
```

Run both engines in parallel, block, verify all four files (two per engine)
exist and are non-empty.

## 9. Orchestrator's own summary (after Final, never sent to either engine)

Read both engines' Final documents in full, plus whatever convergence-gate
notes you generated during the run (you already have these — no need to
re-derive them). Produce, and save to
`proposals/{sprint_title}/Orchestrator Summary.md` (and show in chat), in
this structure:

1. **Rounds — what differed, round by round.** One compact table row per
   round: only the differences the gate actually found that round, not
   everything that changed in either file. This is a log of disagreements,
   not a chronology of edits — if a round resolved a prior difference, say
   so in one clause; don't narrate how it got resolved.
2. **Why revisions stopped where they did.** State plainly which of these
   applied: the gate found no remaining differences (converged); a
   difference persisted with no further progress round to round
   (redundant/stalemate); a real difference persisted but kept producing
   new argument each round (genuine impasse, not yet exhausted); or the
   round cap was hit. If a human override changed the stop point mid-run,
   say that too, factually, no editorializing.
3. **Final differences — table format**, columns: dimension | Claude's
   approach | Codex's approach. Table, not narrative prose — a difference
   described in a paragraph each is harder to compare side by side than
   one described in adjacent cells. Only include dimensions that would
   change what actually gets built, tested, or shipped; skip
   documentation-structure/thoroughness differences (e.g. one engine has a
   dedicated "Scope" section and the other doesn't) unless they reflect an
   actual difference in what was planned, not just how it was written up.
4. **Alternatives explored and why rejected** — pull directly from either
   Final document's stated alternatives (if present); note when both
   engines rejected the same alternative for the same reason (a
   convergence point, not a difference) versus when they considered
   different alternatives.
5. **Notable pattern, not a difference** (optional) — if something
   consistent shows up across the run that isn't itself a build-affecting
   difference (e.g. one engine consistently writes more test/process
   scaffolding, the other more inline code-level justification), it's fine
   to note it as a pattern worth watching on future sprints — explicitly
   label it as a pattern, not a verdict on either engine, and keep it to a
   sentence or two.

Do not include: the full text of either Final document, a side-by-side
checklist dump by default, or a prose "consolidated picture" per engine —
none of that is this step's job unless Paul asks for it on a given run.
End with a one-line pointer to each engine's `Final.md` and `Verification
Checklist.md` so Paul can open them directly; do not duplicate their
content here even partially.

No characterization of which approach is better anywhere in this document
— that's Paul's call, not this step's. Do not pick a winner. Do not add
technical opinion on the subject matter itself.

## Engine invocation

Both calls run from `target_project_path` and must never be able to hang
waiting on a permission prompt — there's no human available mid-run to
answer one.

**Codex:**
```
<resolved-codex-path> exec "<prompt>" \
  --sandbox workspace-write \
  -C "<target_project_path>" \
  --skip-git-repo-check \
  --ephemeral \
  --output-last-message "<scratch-tmpfile>"
```
`exec` mode already runs non-interactively (`approval: never`) by default —
no extra approval-bypass flag needed. `--output-last-message` is only
reliable for stages with no file-write side effect (Kickoff); for stages
where the engine writes its own proposal file, verify success via the file
itself, not the captured last message (confirmed empirically: Codex's
last-message capture is empty when its final turn is a tool action with no
closing remark).

**Claude:**

Auth is persisted as a long-lived token in the Windows user environment
(`CLAUDE_CODE_OAUTH_TOKEN`, set via `claude setup-token` + `setx`), but
`setx` only updates the registry — processes already running (including
whatever launched this session) don't see it until restarted, and in
practice a full app restart has not reliably picked it up either (likely
because GUI-launched apps inherit a cached environment from `explorer.exe`
that doesn't refresh on its own). **Do not rely on ambient environment
inheritance for this token.** Instead, read it from the registry fresh at
call time and inject it explicitly into just this one subprocess call:

```
$env:CLAUDE_CODE_OAUTH_TOKEN = [Environment]::GetEnvironmentVariable("CLAUDE_CODE_OAUTH_TOKEN","User")
claude -p "<prompt>" --permission-mode bypassPermissions --output-format text
```

(or the bash equivalent: read the same registry value via a PowerShell
one-liner, then export it inline for just the `claude -p` call — never
assume it's already present in the calling shell's environment.) This
works regardless of how stale the orchestrating process's own environment
is, since it re-resolves the value from the registry every call instead of
trusting inheritance.

Run with cwd set to `target_project_path` (or `--add-dir` if invoked from
elsewhere). `bypassPermissions` is required — any other mode can prompt for
approval, which hangs forever in a headless run.

Launch both calls in parallel wherever a step calls for "both engines";
never run them sequentially unless one step's prompt genuinely depends on
the other's output (none do — even the Revision/Final "read the other
engine's file" instruction is satisfied because both files already exist on
disk by the time either call starts a new round).

## Guardrails (hard-won on the manual dry run — don't relearn these)

- Never arbitrate, recommend, or pick a winner, at any step, including the
  final summary.
- Never read proposal content mid-process and volunteer analysis — only the
  explicitly-scoped convergence gate, which is symmetric and binary, never
  a content judgment.
- Anything resolved in a side conversation with Paul gets reduced to a
  flat, settled fact before it reaches either engine — never your own
  framing of what the disagreement was. This is exactly where the GeoWatch
  run's one contamination happened: a legitimate side conversation's
  conclusion leaked into a prompt as pre-digested analysis.
- Explicit permission for either engine to report "unchanged" in one line
  during a revision round — never push them to rewrite for the appearance
  of thoroughness, and don't you either, in the final summary.
- `proposals/` and `intake/` are gitignored, never committed. Promoting a
  winning proposal to `docs/` (or anywhere else) is a manual, deliberate
  action by Paul, entirely outside this skill's scope.
- No meta-process information ever reaches either engine: no round count,
  no "this is final" framing beyond the Final template's own wording, no
  "the orchestrator noticed a difference." Only flat, Paul-approved facts
  when something is genuinely settled.
