---
description: Run `terraform plan` against a captured operation to preview what it would change in the tenant — without applying. Supports both promoted modules in tf/<area>/<op>/ and inbox drafts in _inbox/<draft>/.
---

# /ca-plan — Preview what a captured op would change

Usage:

```
/ca-plan <area>/<op>            # plan a promoted module
/ca-plan _inbox/<draft-dir>     # plan an inbox draft
```

## What to do

1. Validate the path exists.
2. If `<area>/<op>` doesn't include `_inbox/`, prepend `tf/`.
3. Source `lib/discovery.sh` and `lib/auth.sh` so the providers have the right URLs and credentials.
4. Run `lib/tf-wrap.sh plan <path>`.
5. Show me the plan output (truncate if huge — show first 50 lines and last 30 with a "..." in between).
6. Do **not** apply. This command is read-only by design.

## If I want to apply after seeing the plan

I'll explicitly ask. Don't prompt me on every plan output — that becomes annoying for routine checks.
