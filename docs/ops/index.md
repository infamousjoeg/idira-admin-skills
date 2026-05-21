        # Catalog

        Browseable index of every captured operation. Each op is a Terraform module (`tf/<area>/<op>/`)
        or a script (`scripts/<area>/<op>/`) with a `README.md`, an `AGENTS.md` for AI-driven adaptation,
        and an auto-generated `SKILL.md` so Claude Code (or any AI agent) can re-invoke it.

        <div class="idira-card-grid" markdown>
        <a class="idira-card" href="identity/"><h3>Identity <span class="idira-badge idira-badge--terraform">1</span></h3><p>cyberark/idsec — users, roles, OAuth webapps, policies, auth profiles</p></a>
<a class="idira-card" href="secrets-manager/"><h3>Secrets Manager <span class="idira-badge idira-badge--terraform">1</span></h3><p>cyberark/conjur — policy_branch, host, group, secret, permission</p></a>
<a class="idira-card" href="privilege-cloud/"><h3>Privilege Cloud <span class="idira-badge idira-badge--terraform">0</span></h3><p>cyberark/idsec — pcloud_account, pcloud_safe, pcloud_target_platform</p></a>
<a class="idira-card" href="sia/"><h3>SIA <span class="idira-badge idira-badge--terraform">0</span></h3><p>cyberark/idsec — Secure Infrastructure Access connectors, relays, settings</p></a>
<a class="idira-card" href="secrets-hub/"><h3>Secrets Hub <span class="idira-badge idira-badge--terraform">0</span></h3><p>cyberark/cyberark — sync policies + cloud secret stores</p></a>
<a class="idira-card" href="connector-manager/"><h3>Connector Manager <span class="idira-badge idira-badge--terraform">0</span></h3><p>cyberark/idsec — networks + pools</p></a>
<a class="idira-card" href="scripts/"><h3>Scripts <span class="idira-badge idira-badge--terraform">1</span></h3><p>Procedural ops via ark CLI and conjur CLI</p></a>
        </div>
