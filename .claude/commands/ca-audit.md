---
description: Query the local audit log of every mutating operation run against the tenant. Filter by date, op slug, or tool. Useful for "what did I change today?", incident review, or building a changelog.
---

# /ca-audit — Query the audit log

Usage:

```
/ca-audit                                     # today's entries
/ca-audit 2026-05-20                          # specific date
/ca-audit week                                # last 7 days
/ca-audit month                               # last 30 days
/ca-audit --op create-identity-webapp          # filter by op slug
/ca-audit --tool ark                           # filter by tool used
/ca-audit --subdomain infamous                 # filter by tenant subdomain (for multi-tenant users)
```

## What to do

1. Find the relevant `audit/YYYY-MM-DD.jsonl` files based on the date filter.
2. `jq` the entries, applying the optional `--op` / `--tool` / `--subdomain` filters.
3. Render as a table (timestamp · op · tool · result · subdomain), most-recent first.
4. Summarize: "N total operations, M unique ops, X subdomains."

## If the audit file doesn't exist

Tell me — it means no operations were captured on that date. Do not infer or fabricate entries.

## Format reminder

Audit entries are JSONL with shape:
```json
{"ts": "2026-05-20T14:23:01Z", "op": "create-identity-webapp", "tool": "terraform:cyberark/idsec", "params": {"app_name": "witty-muffin"}, "result": "applied", "subdomain": "infamous"}
```

`audit/` is gitignored — these stay local.
