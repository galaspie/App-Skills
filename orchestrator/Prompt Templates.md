# Orchestrator Prompt Templates

Reusable, sprint-agnostic. Fill in `{sprint_title}` (human-readable, used for both the
folder name and every filename — pick one name and use it everywhere, so the folder
and its contents never drift the way they did on the GeoWatch run) and `{engine}`
(`claude code` or `codex`) wherever they appear. `{problem_statement}` is the actual
sprint ask, written fresh each time.

Filename pattern, stated once, used by both engines for every file they produce in a
sprint: `{sprint_title} - {stage}.md`, where `{stage}` progresses:
`Initial Proposal` → `Revision 1` → `Revision 2` → ... (as many as the gate allows) →
`Final`.

Folder contract: `proposals/{sprint_title}/{engine}/`, inside the target project,
gitignored.

---

## 1. Kickoff (optional, recommended)

```
{problem_statement — the situation as it stands today, no proposed fix yet}

Before we begin, confirm your understanding by reading the relevant code and
returning here with a brief summary. Do not propose a solution yet.
```

## 2. Initial Proposal (always, independent — run identically, separately, for each engine)

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

**If either engine returns BLOCKING QUESTIONS:** aggregate every flagged question
from both into one list, present it to Paul once, wait for his answer. When
resuming, give both engines the answer as a flat, settled fact — never as Orchestrator's
own analysis of what the differences were. State only the decision and the one-line
reason Paul gave for it. Do not characterize, compare, or editorialize beyond that.

## 3. Revision round (reusable verbatim, every round the gate allows)

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

## 4. Convergence gate (Orchestrator's own check, after every revision round — never
sent to either engine)

```
Setting aside wording, phrasing, and explanatory prose — is there any remaining
difference between these two documents that would change what actually gets built,
tested, or shipped? A different file, a different write point, a different schema
or field set, a different guard or scope decision, a different test assertion, or a
different conclusion about what changes versus what doesn't?

- If no: stop. Proceed to Final.
- If yes: note each such difference in one line, factually, with no characterization
  of which side is right. Run another Revision round (template 3, unchanged). This
  note is for Paul's visibility only — it never gets added to the next round's prompt.
```

## 5. Final (once, after the gate says stop)

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

## 6. Orchestrator's own summary (after Final, never sent to either engine)

```
Read every file in each engine's folder, in chronological order. Do not regenerate,
rewrite, or paraphrase their content — only read and organize what already exists.

Produce:
1. For each engine, its consolidated final picture — the Final document as the base,
   noting anything the record shows changed along the way. Present what already
   exists; do not author a new merged document.
2. A factual list of where the two engines' final designs still differ, if anything
   — no characterization of which is better.
3. A factual list of where they've fully converged.
4. Both verification checklists, presented side by side, unedited.
5. A methodology note disclosing any deviation from a clean run — anything resolved
   outside the formal process and fed back in, any prompt that didn't match this
   template, anything else that could have influenced independence.

Do not pick a winner. Do not recommend one proposal over the other. Do not add
technical opinion on the subject matter itself. Paul decides from here.
```
