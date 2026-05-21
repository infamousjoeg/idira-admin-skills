# Project: idira-admin-skills — Claude Code instructions

Use `docs.cyberark.com` to research how to do things asked in this project. The published Idira / CyberArk docs are authoritative; SDK/CLI source on GitHub is the next fallback.

## What this repo is

This is Joe's control surface for administering his `infamous` Idira tenant via natural-language prompts. Successful ad-hoc operations are auto-drafted to `_inbox/` and later promoted to the permanent catalog (`tf/<area>/<op>/` for Terraform-captured ops; `scripts/<area>/<op>/` for `ark`-/`conjur`-CLI-captured ops). The repo is also published as a Claude Code plugin so other admins can install it and adapt with their own AI agent.

## The two locked naming conventions

When you write prose, page titles, READMEs, blog content, marketing copy → **"Idira"** (not CyberArk) and **"Secrets Manager"** (not Conjur).

When you write technical identifiers — Terraform provider names, CLI names, URLs, env vars, package names → **keep `cyberark` and `conjur` verbatim**. These haven't migrated. Examples: `cyberark/idsec`, `cyberark/conjur`, `cyberark/cyberark`, `*.cyberark.cloud`, `CYBERARK_*`, `CONJUR_*`, `conjur` CLI, `ark` CLI.

Directory names in this repo use the marketing-friendly form: `tf/secrets-manager/`, `tf/privilege-cloud/`, `tf/identity/`, `tf/sia/`, `tf/secrets-hub/`, `tf/connector-manager/`.

## Tool selection order (the routing logic)

For any admin operation Joe requests:

1. **Does a Terraform module already exist in `tf/<area>/<op>/`?** → use it. Run via `lib/tf-wrap.sh` (which handles `terraform init/plan/apply` and always shows the plan before applying).
2. **No TF module, but a provider supports the resource?** → write inline TF using the right provider, run via `lib/tf-wrap.sh`, auto-draft to `_inbox/<timestamp>-<slug>/inline.tf` for promotion later.
3. **Provider doesn't cover this but the `ark` CLI does?** → use `lib/ark-wrap.sh` to call `ark exec <service> <action>`. Capture as a script in `_inbox/`.
4. **`ark` doesn't cover it (it doesn't cover Secrets Manager), but `conjur` does?** → use the `conjur` CLI directly. Capture as a script.
5. **None of the above?** → raw REST via curl with discovered URLs + minted token. Capture as a script and flag in its `AGENTS.md` to migrate as soon as provider/CLI coverage exists.

## Autonomy expectations

Do not ask for things you can figure out. Apply sensible defaults and note them in the inbox draft for review at promote-time:

- **OAuth webapp callback**: `http://localhost:3000/callback` (standard MCP dev pattern)
- **OAuth scope**: `api`
- **PKCE**: `required` (per `~/Documents/Projects/panw/memory/cyberark-tenant.md`)
- **App ID slug**: derive from name (kebab-case, lowercased)
- **Secrets Manager branch**: `data/` root; MCP convention `data/mcp/server/<name>` + `data/mcp/user/<name>`
- **TF state**: `state/<area>/<op>/terraform.tfstate` (local)
- **Tenant subdomain**: `$CYBERARK_TENANT_SUBDOMAIN` env var (default `infamous` for Joe)

## Auth — never hardcode tenant URLs

User provides only `CYBERARK_TENANT_SUBDOMAIN`. Everything else is resolved through Platform Discovery:

```
GET https://platform-discovery.cyberark.cloud/api/v2/services/subdomain/<subdomain>
```

`lib/discovery.sh` calls this once per session, caches the response in `cache/discovery-<subdomain>.json`, and exports `CYBERARK_IDENTITY_API_URL`, `CYBERARK_SECRETS_MANAGER_API_URL`, `CYBERARK_PCLOUD_API_URL`, etc. **Never** assume `<subdomain>.id.cyberark.cloud` — the real Identity URL uses a tenant ID (e.g., `ack4386.id.cyberark.cloud`).

Identity Service User credentials live in Joe's Conceal/Keychain at `infamousdev/claudecode/client_id` / `client_secret`. Use `summon -p conceal` to inject them into a process; never echo, log, write to disk, or pass them on a command line.

For Identity Service User OAuth2 token mint, the correct endpoint is `POST ${CYBERARK_IDENTITY_API_URL}/Oauth2/Token/cyberark_apis` with HTTP Basic + `grant_type=client_credentials&scope=api`. (Do NOT use `/oauth2/platformtoken` — that endpoint does not exist.)

## Capture workflow

When you successfully complete an ad-hoc op (i.e., no matching module/script existed yet):

1. Apply the change via the chosen tool.
2. Append a JSONL record to `audit/YYYY-MM-DD.jsonl` with: timestamp, op slug, tool used, parameters, response.
3. Write a draft to `_inbox/<timestamp>-<slug>/` containing:
   - `inline.tf` (or `run.sh`) — the exact code used, best-effort parameterized
   - `SKILL_NOTES.md` — what was done, what defaults were assumed
   - `AGENTS.md` — flags for variables that need parameterization for other tenants

Don't try to perfect the draft. Perfection happens at promote-time when Joe reviews.

## Safety

- TF wrappers always run `terraform plan` before `apply`. Don't bypass.
- `terraform destroy` requires the explicit `--apply-destroy` flag in `lib/tf-wrap.sh`.
- Scripts declare `RISK: read | mutate | destructive` in their header. `mutate` triggers audit. `destructive` requires `--apply` + interactive confirmation.
- Never commit anything in `_inbox/`, `audit/`, `state/`, `cache/`, `*.tfvars` (except `.example`), `*.pptx` (brand source is confidential), or `.env*`.

## Second Brain reach

Joe's canonical memory lives at `~/Documents/Projects/panw/memory/`. Especially relevant for this repo:
- `cyberark-tenant.md` — Joe's `infamous` tenant, Conceal paths, Identity OAuth2 token endpoint correction, Secrets Manager SaaS naming convention, Platform Discovery endpoint, `ark` CLI.
- `preferences.md` — plan-before-action, persist-everything, PKCE/no-secrets stance, security-conscious dependency choices.
- `projects.md` — references this initiative as [[idira-admin-skills-plugin]].

When you learn something new about Joe's tenant or the platform, persist it to the right memory file *during the turn it's learned*, not later.

## Public-repo discipline

Anything committed here is world-readable. Specifically:
- **Never** commit the brand PPTX, extracted Idira logos/icons, or anything from the November 2025 Brand Supplement marked "CONFIDENTIAL — NOT FOR GENERAL RELEASE".
- **Never** commit real client_id / client_secret / token values, even in examples.
- **Never** commit tenant-specific tfvars to anywhere except `examples/*/*.tfvars.example` (with synthetic values).
- The `audit/` directory contains tenant identifiers and is gitignored. Keep it that way.

## Local toolchain on Joe's Mac (relevant paths)

- `terraform` — Terraform CLI
- `conjur` v9.1.3 — `/Users/joe.garcia/.local/bin/conjur`
- `summon` v0.10.3 — `/Users/joe.garcia/brew/bin/summon`
- `conceal` v4.1.0 — `/Users/joe.garcia/brew/Cellar/conceal/4.1.0/bin/conceal`
- `docker` v29.4.3 (Apple Silicon — use `--platform linux/amd64` for amd64-only images)
- `gh`, `jq`, `rg` — available
- `ark` — to be installed via `pipx install ark-sdk-python` (see Phase 0 in `~/Documents/Projects/panw/plans/idira-admin-skills-plugin.md`)
