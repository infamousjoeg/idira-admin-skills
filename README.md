# Idira Admin Skills

> **Prompt Claude (or any AI agent) to administer your Idira Identity Security Platform tenant. Every successful operation becomes a reusable Terraform module or `ark` CLI recipe — published, browsable, and shareable.**

[![Apache 2.0 License](https://img.shields.io/badge/license-Apache_2.0-265BFF.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built_for-Claude_Code-061D63.svg)](https://docs.claude.com/en/docs/claude-code)
[![Terraform Providers](https://img.shields.io/badge/terraform-cyberark%2Fidsec_%2B_cyberark%2Fconjur-173EB8.svg)](https://registry.terraform.io/namespaces/cyberark)

---

## What this is

A Claude Code plugin + Terraform catalog for administering the CyberArk Identity Security Platform (marketed as **Idira by Palo Alto Networks**) via natural-language prompts. You describe what you want; Claude picks the right tool — Terraform, the `ark` CLI, or the `conjur` CLI — runs it idempotently, and auto-drafts the successful path into a reusable module you can promote into a permanent catalog.

The catalog grows organically. Every prompt that worked once is a candidate for an op you (or anyone with their own AI agent) can re-run with one line of Terraform or one `ark exec` call.

## Why it's shaped this way

- **Terraform-first** because CyberArk publishes three official providers (`cyberark/idsec` for Identity + Privilege Cloud + SIA + CMGR + CCE + policies, `cyberark/conjur` for Secrets Manager, `cyberark/cyberark` for Secrets Hub + PAM Self-Hosted) covering ~80% of admin surface area. Idempotency, dry-run via `terraform plan`, and drift detection come free.
- **`ark` CLI** for procedural and read-heavy ops the providers don't cover yet (`ark-sdk-python`, the official Identity Security Platform SDK).
- **`conjur` CLI** for Secrets Manager operations where the provider doesn't reach.
- **Auto-draft → manual promote** so the catalog stays curated. Successful ad-hoc ops land in `_inbox/`; `/ca-promote` reviews and lands keepers as proper TF modules with auto-generated skill manifests.
- **Platform Discovery** so users only ever provide their subdomain. All per-tenant URLs (Identity, Secrets Manager, Privilege Cloud, SIA, etc.) are resolved dynamically.
- **Built in the open** so other admins can adapt these ops to their tenant using their own AI agent (Claude Code, Cursor, Codex). Every captured op ships with an `AGENTS.md` that tells an AI exactly what to change.

## Quick start (using this with your tenant)

You'll need: [Terraform](https://developer.hashicorp.com/terraform/install), [`ark` CLI](https://github.com/cyberark/ark-sdk-python) (`pipx install ark-sdk-python`), [`conjur` CLI](https://github.com/cyberark/cyberark-conjur-cli), and a secret store of your choice for your Idira Identity Service User credentials.

```bash
# 1. Clone, or install as a Claude Code plugin:
/plugin install github:infamousjoeg/idira-admin-skills

# 2. Set your tenant subdomain (the only thing we ask for — everything else is discovered):
export CYBERARK_TENANT_SUBDOMAIN=your-tenant

# 3. Source the auth helpers (uses your secret store — see lib/auth.sh):
source lib/discovery.sh && discover "$CYBERARK_TENANT_SUBDOMAIN"

# 4. Prompt Claude in this directory:
#    "Create an OAuth webapp for a new MCP called 'my-app'"
#    Claude will plan it, show the diff, apply on confirmation, and auto-draft to _inbox/.
```

## How operations get captured

```
You prompt Claude ─→ Claude routes (TF → ark → conjur → REST)
       │
       ▼
  Successful op ──→ Auto-drafts to _inbox/2026-05-20-1145-<slug>/
       │
       ▼
   /ca-promote ──→ Review draft → place in tf/<area>/<op>/ → commit
       │
       ▼
  Push to main ──→ GitHub Pages catalog rebuilds → new op is browsable
```

The catalog at `https://infamousjoeg.github.io/idira-admin-skills/` grows every time you (or any contributor) promote a draft. Each op page includes the Terraform, the example tfvars, and the `AGENTS.md` guidance for adapting it to a different tenant.

## Catalog overview

| Area | Tool | Status |
|---|---|---|
| `tf/identity/` | `cyberark/idsec` (60 resources for Identity, OAuth webapps, roles, policies, auth profiles) | bootstrapping |
| `tf/secrets-manager/` | `cyberark/conjur` (policy_branch, host, group, secret, permission) | bootstrapping |
| `tf/privilege-cloud/` | `cyberark/idsec` (pcloud_account, pcloud_safe, pcloud_target_platform) | bootstrapping |
| `tf/sia/` | `cyberark/idsec` (sia_* — connectors, relays, settings, secrets) | bootstrapping |
| `tf/secrets-hub/` | `cyberark/cyberark` (sync_policy, secret_store_*) | bootstrapping |
| `tf/connector-manager/` | `cyberark/idsec` (cmgr_network, cmgr_pool) | bootstrapping |
| `scripts/` | `ark` CLI + `conjur` CLI for procedural ops | bootstrapping |

## Adapting this to your tenant

If you're cloning this rather than `/plugin install`-ing it, point your AI agent (Claude Code, Cursor, Codex, etc.) at `AGENTS.md` in the repo root and at the per-op `AGENTS.md` files. They describe exactly what to change for your tenant — secret store, subdomain, optional defaults, regional URLs.

## Naming convention

To save you from one source of confusion: this project deliberately uses **two naming systems**.

- **Prose and product names** use the current Palo Alto Networks brand names: **Idira** (the Identity Security Platform) and **Secrets Manager** (the SaaS formerly known as Conjur Cloud).
- **Technical identifiers** keep the historical names where they haven't migrated yet: `cyberark/idsec` and `cyberark/conjur` Terraform providers, the `conjur` CLI, `*.cyberark.cloud` URLs, `CYBERARK_*` and `CONJUR_*` environment variables.

This is intentional and matches how CyberArk/Idira themselves manage the transition.

## Contributing

This is a personal admin tooling tree shared publicly. PRs welcome for:
- New `tf/<area>/<op>/` modules using one of the three CyberArk providers
- New `scripts/<area>/<op>/` recipes using `ark` or `conjur` CLI
- Documentation improvements to per-op `AGENTS.md` files

Please don't PR changes to `lib/`, the plugin manifest, or workflows without discussion first.

## License & trademarks

Apache 2.0. See [LICENSE](LICENSE).

Not affiliated with, endorsed by, or sponsored by Palo Alto Networks, CyberArk Software Ltd., or the Idira brand team. "Idira", "CyberArk", and related marks belong to their respective owners and are used here for descriptive purposes only.

The visual identity is inspired by the Idira brand palette (publicly attested hex codes from the November 2025 Identity Platform Brand Supplement). Official Idira logos and trademarked assets are **not** used or redistributed.
