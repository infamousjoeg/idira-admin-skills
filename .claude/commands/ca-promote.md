---
description: Review pending captures in _inbox/ and promote keepers into the permanent catalog (tf/<area>/<op>/ or scripts/<area>/<op>/) with finalized variables, README, and an auto-generated SKILL.md.
---

# /ca-promote — Promote captured drafts to the catalog

Walk through every directory under `_inbox/` and help me promote the keepers.

## For each pending draft

1. **Read** `_inbox/<draft>/SKILL_NOTES.md`, `inline.tf` (or `run.sh`), and `AGENTS.md`.
2. **Summarize** in 2-3 lines what the op does, when it was captured, and what defaults were assumed.
3. **Ask me**: keep it (and what to name it), skip it, or delete it.

## When I say "keep"

1. **Finalize the name and area** — confirm with me. Use marketing-friendly area names (`identity`, `secrets-manager`, `privilege-cloud`, `sia`, `secrets-hub`, `connector-manager`).
2. **Place files** at the target location:
   - For TF: `tf/<area>/<op-slug>/` with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `AGENTS.md`, and `examples/default/terraform.tfvars` (using Joe's tenant defaults).
   - For scripts: `scripts/<area>/<op-slug>/` with `run.sh`, `README.md`, `AGENTS.md`.
3. **Clean up the TF/script** — extract every tenant-specific literal to a `variable` (or a parameter), tighten descriptions, remove debug output, ensure idempotency where possible.
4. **Write the Idira-branded `README.md`** for the op:
   - **One-line summary** (the kind of thing that goes on a catalog page card)
   - **What it manages** (the underlying resources)
   - **When to use** (the prompt patterns that should match this op)
   - **Variables** (table)
   - **Outputs** (if any)
   - **Example** (snippet)
   - Use **Idira / Secrets Manager** in prose, not CyberArk / Conjur.
5. **Generate `.claude/skills/<op-slug>/SKILL.md`** from `SKILL_NOTES.md`:
   ```markdown
   ---
   name: <op-slug>
   description: <one-paragraph description of when to use this op — used by idira-admin-router to match user prompts>
   ---
   # <Op Title>
   <body that tells Claude how to invoke this op: which area, which tfvars to set, which defaults to use, what to verify after apply>
   ```
6. **Update the per-op `AGENTS.md`** for cross-tenant adaptability (the inbox draft's was best-effort; tighten it now).
7. **Commit** with a structured message:
   ```
   feat(<area>): add <op-slug> module
   
   Captures the <description> pattern.
   Promoted from _inbox/<draft-dir>.
   ```
8. **Remove** the `_inbox/<draft>/` directory.
9. After all drafts processed, suggest pushing to `origin/main` to trigger the GitHub Pages catalog rebuild.

## When I say "skip"

Leave the draft in place for next time.

## When I say "delete"

Remove `_inbox/<draft>/` and confirm. Don't ask me again about it.

## Before you start

Run `ls -la _inbox/` and `git status` to show me current state.
