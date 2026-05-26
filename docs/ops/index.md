# Catalog

Browseable index of every captured operation. Each op is a Terraform module (`tf/<area>/<op>/`)
or a script (`scripts/<area>/<op>/`) with a `README.md`, an `AGENTS.md` for AI-driven adaptation,
and an auto-generated `SKILL.md` so Claude Code (or any AI agent) can re-invoke it.

<div class="idira-card-grid">
<a class="idira-card" href="identity/"><div class="idira-card__title">Identity <span class="idira-badge idira-badge--terraform">1</span></div><div class="idira-card__body">cyberark/idsec — users, roles, OAuth webapps, policies, auth profiles</div></a>
<a class="idira-card" href="secrets-manager/"><div class="idira-card__title">Secrets Manager <span class="idira-badge idira-badge--terraform">1</span></div><div class="idira-card__body">cyberark/conjur — policy_branch, host, group, secret, permission</div></a>
<a class="idira-card" href="privilege-cloud/"><div class="idira-card__title">Privilege Cloud <span class="idira-badge idira-badge--terraform">0</span></div><div class="idira-card__body">cyberark/idsec — pcloud_account, pcloud_safe, pcloud_target_platform</div></a>
<a class="idira-card" href="sia/"><div class="idira-card__title">SIA <span class="idira-badge idira-badge--terraform">0</span></div><div class="idira-card__body">cyberark/idsec — Secure Infrastructure Access connectors, relays, settings</div></a>
<a class="idira-card" href="secrets-hub/"><div class="idira-card__title">Secrets Hub <span class="idira-badge idira-badge--terraform">0</span></div><div class="idira-card__body">cyberark/cyberark — sync policies + cloud secret stores</div></a>
<a class="idira-card" href="connector-manager/"><div class="idira-card__title">Connector Manager <span class="idira-badge idira-badge--terraform">0</span></div><div class="idira-card__body">cyberark/idsec — networks + pools</div></a>
<a class="idira-card" href="scripts/"><div class="idira-card__title">Scripts <span class="idira-badge idira-badge--terraform">1</span></div><div class="idira-card__body">Procedural ops via ark CLI and conjur CLI</div></a>
</div>
