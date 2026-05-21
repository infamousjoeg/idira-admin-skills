---
description: Browse the catalog of captured operations — Terraform modules under tf/<area>/<op>/ and scripts under scripts/<area>/<op>/. Optionally filter by area.
---

# /ca-list — Browse the catalog

Usage:

```
/ca-list                          # everything
/ca-list identity                 # just the identity area
/ca-list secrets-manager
/ca-list privilege-cloud
/ca-list sia
/ca-list secrets-hub
/ca-list connector-manager
/ca-list scripts                  # just the scripts/ tree
```

## What to do

1. Walk the requested area(s) under `tf/` and `scripts/`.
2. For each op, read its `README.md` first line (or `SKILL.md` `description` frontmatter if no README yet) for the one-line summary.
3. Render as a table per area:

```
identity/
  oauth-webapp-pkce  · create OAuth web app with PKCE required (cyberark/idsec)
  service-user       · create CyberArk Identity Service User (cyberark/idsec)
  user               · create CyberArk Identity user (cyberark/idsec)

secrets-manager/
  mcp-namespace      · create data/mcp/server/<n> + data/mcp/user/<n> with !permit linking
  ...
```

4. At the end, summarize: "N ops across M areas (X TF modules, Y scripts)."

## Also surface

- Pending inbox drafts: `_inbox/` count, with a nudge to run `/ca-promote` if > 0.
- A "what's missing" hint: if the user is in a Claude Code session and has been asking about an area that has zero ops captured, gently note "the `<area>/` area is empty — your next ad-hoc op will seed it."
