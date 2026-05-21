# AGENTS.md — Instructions for any AI agent adapting this repo

> If you are an AI agent (Claude Code, Cursor, Codex, Aider, etc.) helping a human administer their Idira Identity Security Platform tenant: read this whole file, then the per-op `AGENTS.md` in each `tf/<area>/<op>/` or `scripts/<area>/<op>/` directory you touch.

## What this repo gives you

A growing catalog of Terraform modules (`tf/`) and CLI recipes (`scripts/`) for administering an Idira tenant — built originally for Joe Garcia's `infamous` tenant, designed so you can adapt them to any tenant by changing a small, well-marked set of variables.

## What you need to know before you act

### 1. Tenant subdomain is the only thing to ask for

The user provides their Idira tenant subdomain (e.g., `acme` for `acme.id.cyberark.cloud`-shaped URLs — though note the real Identity URL uses a tenant ID like `xyz1234.id.cyberark.cloud`, not the subdomain).

Resolve every other URL dynamically through CyberArk's Platform Discovery endpoint:

```
GET https://platform-discovery.cyberark.cloud/api/v2/services/subdomain/<subdomain>
```

The response JSON includes the real per-tenant URLs for ~23 services (`identity_administration.api`, `secrets_manager.api`, `pcloud.api`, `sca.api`, `jit.api`, `secrets_hub.api`, `component_manager.api`, `itdr.api`, `recording.api`, `dms.api`, `session_monitoring.api`, `audit.api`, `analytics.api`, etc.).

`lib/discovery.sh` already implements this. It exports the URLs as `CYBERARK_IDENTITY_API_URL`, `CYBERARK_SECRETS_MANAGER_API_URL`, etc., which the Terraform providers and CLI wrappers consume.

**Never hardcode `<subdomain>.id.cyberark.cloud`.** It's wrong. The Identity URL uses a tenant ID.

### 2. Authentication — adapt to the user's secret store

The original setup (Joe's) uses [Conceal](https://github.com/cyberark/conceal) (macOS Keychain via [Summon](https://github.com/cyberark/summon)) for an Idira Identity **Service User** with paths `infamousdev/claudecode/client_id` / `client_secret`. **You almost certainly need to change this for your user.**

Ask the user where their Identity Service User credentials live and swap `lib/auth.sh` accordingly. Reasonable swaps:
- **1Password CLI** (`op read 'op://Personal/Idira Service User/client_id'`)
- **AWS Secrets Manager** (`aws secretsmanager get-secret-value --secret-id ...`)
- **HashiCorp Vault** (`vault read secret/idira/service-user`)
- **Doppler / Infisical / etc.**
- **Plain env vars** (acceptable for ephemeral CI; not for human-driven workflows)

The credentials should be a CyberArk Identity **Service User** (machine-to-machine), not an interactive Identity User. Service Users authenticate via the client_credentials grant; interactive users would need PKCE/authorization-code flow which doesn't fit non-interactive automation.

The token mint endpoint is:

```
POST ${CYBERARK_IDENTITY_API_URL}/Oauth2/Token/cyberark_apis
Authorization: Basic <base64(client_id:client_secret)>
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=api
```

`cyberark_apis` is a default OAuth2 Client app shipped with every Idira tenant. If your tenant has it disabled or you want a dedicated app, register your own and substitute its slug.

### 3. Tool selection order — try Terraform first

For any operation, pick the highest-leverage tool that covers it:

1. **Terraform module in `tf/<area>/<op>/`** — use the existing module. Set tfvars per the example, run `terraform plan` first, apply on confirmation.
2. **No module yet, but `cyberark/idsec`, `cyberark/conjur`, or `cyberark/cyberark` provider has the resource** — write inline TF, run via `lib/tf-wrap.sh`. Idempotency and dry-run are free.
3. **TF doesn't cover it but the `ark` CLI does** (`ark exec identity|pcloud|sia|sm|cmgr|uap ...`) — use `lib/ark-wrap.sh`.
4. **`ark` doesn't cover it but the `conjur` CLI does** (Secrets Manager only) — use `conjur` directly.
5. **None of the above** — raw REST. Mint the token per step 2, call the appropriate `.api` URL from discovery.

The `ark` CLI is `pip install ark-sdk-python` (Python 3.9+). It's the official CyberArk Identity Security Platform CLI.

### 4. Idempotency and safety

- Terraform: always `plan` before `apply`. The `lib/tf-wrap.sh` wrapper enforces this — do not bypass.
- Scripts: declare a `RISK:` header (`read | mutate | destructive`). `mutate` and `destructive` require audit logging; `destructive` requires an `--apply` flag + interactive confirmation.
- Re-running a captured op should be a no-op when nothing has changed. If you write a new op and it isn't naturally idempotent (TF gives it for free; CLIs usually need an explicit "does it exist?" check), make it so.

### 5. Capture pattern — drafts go to `_inbox/`, you don't decide names

When you complete a successful ad-hoc operation (no matching module/script existed), write a draft to `_inbox/<UTC-timestamp>-<descriptive-slug>/` containing:
- `inline.tf` (or `run.sh`) — the exact code used, with best-effort parameterization
- `SKILL_NOTES.md` — what was done, what defaults you assumed
- `AGENTS.md` — flag every value that should become a variable

**Do not promote it yourself.** The human runs `/ca-promote` to review and finalize naming, variables, README, and placement.

## Things to never do

- **Never** commit secrets — even in examples. Synthetic values only.
- **Never** commit the source brand PPTX, extracted Idira logos, or anything marked confidential by the Identity Platform Brand Supplement.
- **Never** commit `audit/`, `_inbox/`, `state/`, `cache/`, real `.tfvars`, or `.env*`.
- **Never** hardcode `<subdomain>.id.cyberark.cloud` — discovery returns the real Identity URL.
- **Never** create a duplicate Identity Service User if the user already has one. Reuse it.
- **Never** invent an endpoint name. If a request fails with "endpoint not found", check `https://api-docs.cyberark.com` and `cyberark/ark-sdk-python` source.

## Things to do every time

- Read the per-op `AGENTS.md` before adapting any op.
- Persist tenant facts the user gives you (subdomain, secret store paths, custom defaults) somewhere durable — your AI agent's memory system, or a local notes file. Don't ask twice.
- Use the user's preferred language for the platform in prose ("Idira" / "Secrets Manager") even though technical identifiers stay `cyberark` / `conjur`.

## Where to find help

- Terraform provider docs: `https://registry.terraform.io/namespaces/cyberark`
- `ark` CLI docs: `https://cyberark.github.io/ark-sdk-python/latest/`
- Idira / CyberArk product docs: `https://docs.cyberark.com`
- This project's catalog (browseable): `https://infamousjoeg.github.io/idira-admin-skills/`
- Issues / PRs: `https://github.com/infamousjoeg/idira-admin-skills`
