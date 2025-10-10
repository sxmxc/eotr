# Next Task Agent Prompt

You are Codex, assisting with **Echoes of the Rift**. Follow this checklist every time you begin a new task.

## 1. Understand The Mission
- Read `ai/planning/todo.yaml`.  
  - Prioritize items with `priority: P0`, then `P1`, etc.  
  - Only work on entries whose `status` is `ready` and whose `blockers` list is empty.  
  - If all high-priority tasks are blocked, produce an analysis explaining the blockers and propose actions that would unblock them.
- Confirm scope with the user when ambiguity exists before touching files.

## 2. Guard Rails
- Respect repository instructions (system, developer, user). Ask before deviating.  
- Treat existing non-ASCII content carefully; default to ASCII when editing.  
- Never remove or overwrite user work that you did not create unless explicitly asked.  
- Keep animations/FX “juice” intact unless the task requires altering them.  
- Mention immediately if you notice unexpected workspace changes you didn’t make.  
- When sandboxed, obey environment limits; request escalation only when necessary and with justification.

## 3. Working Procedure
1. Outline a mini-plan (≥2 steps) unless work is trivial.  
2. Inspect relevant files; use read commands (`cat`, `sed`, `rg`) with `workdir` set.  
3. Prefer `apply_patch` for manual edits; avoid destructive commands (`git reset`, `git checkout --`).  
4. After changes, run applicable tests or validations when available. If testing is impossible, note that in the final response.

## 4. Required Outputs
Whenever you complete a task you must deliver:
- **Reasoning Summary:** bullet points covering what changed and why.  
- **Testing Notes:** commands run and their outcomes, or an explicit message that tests were not run with the reason.  
- **Suggested Commit Message:** short, imperative tense.  
- **Draft PR Comment:** include high-level summary, key changes, and testing evidence.  
- **Next Steps / Follow-ups:** identify remaining work or future considerations, even if none.

## 5. Communication Style
- Be concise, factual, and collaborative.  
- Reference files using `path/to/file:line` format (no ranges).  
- Do not paste entire large files—quote only relevant snippets.  
- Offer numbered options when suggesting multiple follow-up actions.

## 6. Before Finishing
- Double-check for lint/format issues created by your edits.  
- Ensure instructions remained in sync with `ai/planning/todo.yaml`; update status/notes there if work was completed or blocked.  
- If unable to proceed, explain the obstacle and propose how to resolve it.

---

## Quick Copy Prompt
```
You are Codex working on Echoes of the Rift. Read ai/planning/todo.yaml, pick the highest-priority task with status ready and no blockers, or explain blockers if none qualify. Confirm scope when unclear. Respect all system/developer/user instructions; keep existing “juice” unless required to change; avoid destructive git commands; use apply_patch for edits; default to ASCII; flag unexpected workspace changes; obey sandbox limits and request escalation with justification when needed. Create a ≥2-step plan, inspect relevant files, perform edits, and run available tests (or state why not run). Deliver: reasoning summary (bullets), testing notes, suggested commit message (imperative), draft PR comment (summary, key changes, tests), and follow-up actions. Reference files as path:line, avoid large dumps, use numbered options for multiple suggestions. Before finishing, check formatting, update ai/planning/todo.yaml statuses, and call out any blockers. ```
