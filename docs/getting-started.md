---
title: Get started
description: Install the Idira Admin Skills Claude Code plugin (or clone the repo), point it at your Idira tenant, and start prompting.
---

# Get started

You have two onboarding paths. They lead to the same place.

## Path A — Install as a Claude Code plugin (recommended)

```bash
/plugin install github:infamousjoeg/idira-admin-skills
```

That pulls down the skills (`idira-admin-router`, `idira-capture`) and slash commands (`/ca-promote`, `/ca-plan`, `/ca-audit`, `/ca-list`) into your global Claude Code skill registry. You can now invoke them from any directory.

## Path B — Clone the repo

```bash
git clone https://github.com/infamousjoeg/idira-admin-skills.git
cd idira-admin-skills
```

Open the directory in Claude Code — the skills auto-discover from `.claude/skills/`.

---

## Prerequisites

| Tool | Install |
|---|---|
| Terraform | `brew install terraform` · [other](https://developer.hashicorp.com/terraform/install) |
| `ark` CLI (Idira Identity Security Platform) | `pipx install ark-sdk-python` · [docs](https://cyberark.github.io/ark-sdk-python/latest/) |
| `conjur` CLI (Secrets Manager) | [installer](https://github.com/cyberark/cyberark-conjur-cli/releases) |
| `jq` | `brew install jq` |
| (your choice) secret store for the Idira Service User | 1Password / Vault / AWS Secrets Manager / macOS Keychain via [Conceal](https://github.com/cyberark/conceal) + [Summon](https://github.com/cyberark/summon) |

You also need an Idira tenant with an **Identity Service User** (machine-to-machine identity, not interactive). The Service User needs the right roles for the operations you want to run — at minimum "System Administrator" or explicit Application Management rights for OAuth webapp ops.

---

## Configure auth

This project keeps your Service User credentials in **your** secret store of choice — never on disk in this repo.

### Default: Conceal (macOS Keychain via Summon)

This is the original setup. Two Keychain entries:

```bash
conceal set yourorg/idira/service-user-id "your-service-user@yourtenant.cyberark.cloud"
conceal set yourorg/idira/service-user-secret "REDACTED"
```

Then set:

```bash
export CYBERARK_AUTH_PROVIDER=conceal
export CYBERARK_CONCEAL_CLIENT_ID_PATH="yourorg/idira/service-user-id"
export CYBERARK_CONCEAL_CLIENT_SECRET_PATH="yourorg/idira/service-user-secret"
```

### Alternative: 1Password CLI

```bash
export CYBERARK_AUTH_PROVIDER=1password
export CYBERARK_1PASSWORD_CLIENT_ID_REF="op://Personal/Idira Service User/client_id"
export CYBERARK_1PASSWORD_CLIENT_SECRET_REF="op://Personal/Idira Service User/client_secret"
```

### Alternative: HashiCorp Vault

```bash
export CYBERARK_AUTH_PROVIDER=vault
export CYBERARK_VAULT_PATH="secret/idira/service-user"  # KV v2 path
```

### Alternative: AWS Secrets Manager

```bash
export CYBERARK_AUTH_PROVIDER=aws-secrets-manager
export CYBERARK_AWS_SECRET_ID="arn:aws:secretsmanager:us-east-1:123456789012:secret:idira-service-user"
# Secret value must be JSON: {"client_id": "...", "client_secret": "..."}
```

### Alternative: plain env vars (ephemeral / CI)

```bash
export CYBERARK_AUTH_PROVIDER=env
export CYBERARK_SERVICE_USER="..."
export CYBERARK_SERVICE_USER_SECRET="..."
```

If your secret store isn't listed, add a `_auth_get_<provider>` function to `lib/auth.sh` (5–10 lines — see the existing implementations for patterns) and PR it back.

---

## Point at your tenant

The only tenant-specific thing you need to set is the subdomain:

```bash
export CYBERARK_TENANT_SUBDOMAIN=yourtenant
```

Everything else — the real Identity URL, Secrets Manager URL, Privilege Cloud URL, SIA URL, etc. — is resolved dynamically through CyberArk's [Platform Discovery](https://platform-discovery.cyberark.cloud/api/v2/services/subdomain/yourtenant) endpoint. Don't hardcode `yourtenant.id.cyberark.cloud` — the real Identity URL uses a tenant ID like `xyz1234.id.cyberark.cloud`.

To verify discovery works:

```bash
./lib/discovery.sh yourtenant
```

You should see ~15–20 `CYBERARK_*_API_URL` env vars exported, including `CYBERARK_IDENTITY_API_URL` resolved to its real tenant-ID-shaped URL.

---

## Your first prompt

Open Claude Code in the repo (or with the plugin installed in any directory) and just describe what you want:

> _"Create an OAuth webapp for a new MCP called `my-test-app`."_

Claude will:
1. Notice there's no matching module yet → write inline Terraform using `cyberark/idsec`'s `identity_webapp` resource.
2. Apply sensible defaults: PKCE required, callback `http://localhost:3000/callback`, scope `api`.
3. Run `terraform plan` first; show you the diff; wait for your confirmation.
4. Apply.
5. Auto-draft the parameterized version to `_inbox/<timestamp>-create-oauth-webapp/` for later promotion.
6. Append an audit entry to `audit/$(date +%Y-%m-%d).jsonl`.

Re-run the same prompt → `terraform plan` shows zero changes (it's idempotent).

When you're ready to make the op part of the permanent catalog, run `/ca-promote`. Claude reviews the inbox draft with you, finalizes naming and variables, writes the Idira-branded README, and places it under `tf/identity/oauth-webapp/` with a generated SKILL.md.

---

## What's next

- Browse the [Catalog](ops/index.md) to see what's already been captured.
- Read [Adapt for your tenant](adapt-for-your-tenant.md) for details on parameterizing captured ops for non-Idira-employee admins.
- Skim the project [README](https://github.com/infamousjoeg/idira-admin-skills) for the philosophy + tool-selection-order details.
