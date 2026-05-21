---
title: Idira Admin Skills
description: Prompt Claude — or any AI agent — to administer your Idira (CyberArk Identity Security Platform) tenant. Every successful operation becomes a reusable Terraform module or ark CLI recipe.
template: home.html
hide:
  - navigation
  - toc
---

<!-- ───── HERO ─────────────────────────────────────────────────────── -->

<section class="idira-hero idira-bleed">
  <div class="idira-hero__inner">
    <div>
      <div class="idira-hero__eyebrow">v0.1 · catalog bootstrapping · 23 services discovered</div>

      <h1 class="idira-hero__title">
        Prompt your way to a&nbsp;managed <em>tenant.</em>
      </h1>

      <p class="idira-hero__tagline">
        Describe what you want — <strong>create an OAuth webapp</strong>, provision a privilege account, load a Secrets Manager policy.
        Idira Admin Skills picks the right tool — Terraform, <code>ark</code>, or <code>conjur</code> — runs it idempotently, and auto-captures the successful path into a reusable, browsable, shareable catalog.
      </p>

      <div class="idira-hero__ctas">
        <a class="idira-cta idira-cta--primary" href="getting-started/">
          Get started <span class="idira-cta__arrow">→</span>
        </a>
        <a class="idira-cta idira-cta--secondary" href="ops/">
          Browse the catalog
        </a>
      </div>
    </div>

    <div class="idira-hero__visual">
      <div class="idira-cube" aria-hidden="true">
        <div class="idira-cube__face idira-cube__face--top"></div>
        <div class="idira-cube__face idira-cube__face--front"></div>
        <div class="idira-cube__face idira-cube__face--right"></div>
      </div>

      <dl class="idira-hero__spec">
        <span>Providers</span>        <b>03</b>
        <hr/>
        <span>Resources</span>        <b>80+</b>
        <hr/>
        <span>Discovery</span>        <b>23</b>
        <hr/>
        <span>License</span>          <b>APL-2.0</b>
      </dl>
    </div>
  </div>

  <div class="idira-hero__scroll-cue">Scroll</div>
</section>

<!-- ───── 01 — Why this exists ───────────────────────────────────── -->

<section class="idira-section">
  <header class="idira-section__header">
    <div class="idira-section__index">01</div>
    <div>
      <h2 class="idira-section__heading">Tenant admin <em>that captures itself.</em></h2>
      <p class="idira-section__lede">
        Administering an Idira tenant ad-hoc — <code>curl</code> against Identity REST, <code>conjur policy load</code> from the CLI, click-ops in the admin UI — works <strong>once</strong>.
        The next time you need the same thing, you're back in the docs hunting for the right endpoint, the right flags, the right policy convention.
        This project turns every successful one-off into a reusable Terraform module or <code>ark</code> recipe — published in the open, browsable here, AI-portable to <em>your</em> tenant.
      </p>
    </div>
  </header>
</section>

<!-- ───── Spec sheet ─────────────────────────────────────────────── -->

<section class="idira-spec-sheet" aria-label="Project specifications at a glance">
  <div class="idira-spec">
    <div class="idira-spec__label">Providers</div>
    <div class="idira-spec__value">3</div>
  </div>
  <div class="idira-spec">
    <div class="idira-spec__label">Resources covered</div>
    <div class="idira-spec__value">80<sub>RES</sub></div>
  </div>
  <div class="idira-spec">
    <div class="idira-spec__label">Services discovered</div>
    <div class="idira-spec__value">23</div>
  </div>
  <div class="idira-spec">
    <div class="idira-spec__label">Setup</div>
    <div class="idira-spec__value">≤5<sub>MIN</sub></div>
  </div>
</section>

<!-- ───── 02 — Six principles ────────────────────────────────────── -->

<section class="idira-section">
  <header class="idira-section__header">
    <div class="idira-section__index">02</div>
    <div>
      <h2 class="idira-section__heading">Six commitments, <em>opinionated on purpose.</em></h2>
      <p class="idira-section__lede">
        We made hard choices upfront so the catalog stays coherent, the captures stay reusable, and adoption stays low-friction. Each principle below answers a "why" that would otherwise come up every PR.
      </p>
    </div>
  </header>

  <div class="idira-card-grid">

    <article class="idira-card">
      <span class="idira-card__tag">Terraform</span>
      <h3 class="idira-card__title">Declarative first, by default</h3>
      <p class="idira-card__body">
        The three CyberArk-published providers — <code>cyberark/idsec</code>, <code>cyberark/conjur</code>, <code>cyberark/cyberark</code> — cover roughly 80 % of admin surface area. Idempotency, <code>terraform plan</code> dry-run, and drift detection: free.
      </p>
      <span class="idira-card__footnote">› cyberark/idsec v0.3.3 · 60 resources · 68 data sources</span>
    </article>

    <article class="idira-card">
      <span class="idira-card__tag">CLI</span>
      <h3 class="idira-card__title">Procedural, where it matters</h3>
      <p class="idira-card__body">
        The official <code>ark</code> CLI (from <code>ark-sdk-python</code>) handles read-heavy and multi-step ops across Identity, Privilege Cloud, SIA, Session Monitoring, Connector Manager, and Unified Access Policies. For Secrets Manager, <code>conjur</code> takes over.
      </p>
      <span class="idira-card__footnote">› ark-sdk-python v2.1.4 · Apache 2.0</span>
    </article>

    <article class="idira-card">
      <span class="idira-card__tag">Discovery</span>
      <h3 class="idira-card__title">One input. Every URL.</h3>
      <p class="idira-card__body">
        You provide only the tenant subdomain. Every per-product API URL — Identity, Secrets Manager, PCloud, SIA, ITDR, DPA, SCA, audit — is resolved at runtime from CyberArk's Platform Discovery endpoint. Nothing is hardcoded.
      </p>
      <span class="idira-card__footnote">› platform-discovery.cyberark.cloud/api/v2</span>
    </article>

    <article class="idira-card">
      <span class="idira-card__tag">Workflow</span>
      <h3 class="idira-card__title">Auto-draft, manual promote</h3>
      <p class="idira-card__body">
        Ad-hoc successes land in <code>_inbox/</code>. You triage with <code>/ca-promote</code> — name the op, finalize the variables, write the README. The catalog stays curated, not noisy.
      </p>
      <span class="idira-card__footnote">› inbox-then-canon, mirrors a second-brain pattern</span>
    </article>

    <article class="idira-card">
      <span class="idira-card__tag">Portable</span>
      <h3 class="idira-card__title">Built for AI consumers</h3>
      <p class="idira-card__body">
        Every captured op ships with an <code>AGENTS.md</code> that tells Claude Code, Cursor, Codex — or any AI agent — exactly what to change to adapt the op for a different tenant. Adoption is one prompt away.
      </p>
      <span class="idira-card__footnote">› per-op variables, secret store, regional URLs</span>
    </article>

    <article class="idira-card">
      <span class="idira-card__tag">Open</span>
      <h3 class="idira-card__title">Public from day one</h3>
      <p class="idira-card__body">
        Built in the open under Apache 2.0. Install as a Claude Code plugin or fork the repo. PRs welcome for ops we haven't covered yet — especially ITDR, DPA, SCA, and Discovery &amp; Context.
      </p>
      <span class="idira-card__footnote">› github.com/infamousjoeg/idira-admin-skills</span>
    </article>

  </div>
</section>

<!-- ───── Pull quote ────────────────────────────────────────────── -->

<blockquote class="idira-pullquote">
  <p>
    Every prompt that worked once is a candidate for an op <em>anyone</em> can re-run with one line of Terraform — or one <code>ark exec</code> call.
  </p>
  <footer>— THE WHOLE POINT, FOR THE RECORD</footer>
</blockquote>

<!-- ───── 03 — How it works (blueprint diagram) ─────────────────── -->

<section class="idira-section">
  <header class="idira-section__header">
    <div class="idira-section__index">03</div>
    <div>
      <h2 class="idira-section__heading">From <em>prompt</em> to permanent catalog.</h2>
      <p class="idira-section__lede">
        Every operation follows the same four-step pipeline. Steps 01–02 happen during your conversation with Claude. Step 03 is a deliberate ritual you control. Step 04 happens automatically in CI.
      </p>
    </div>
  </header>

  <figure class="idira-blueprint" role="img" aria-label="Capture pipeline: prompt, route + execute, promote, publish.">
    <div class="idira-blueprint__title">
      <span>FIG. 01 — Capture pipeline</span>
    </div>

    <div class="idira-flow">

      <div class="idira-flow__step">
        <span class="idira-flow__num">01 · INPUT</span>
        <h3 class="idira-flow__title">You prompt Claude</h3>
        <p class="idira-flow__body">
          Natural language. <code>"Create an OAuth webapp for a new MCP called witty-muffin."</code> No flags. No menus.
        </p>
      </div>

      <div class="idira-flow__step">
        <span class="idira-flow__num">02 · ROUTE + EXECUTE</span>
        <h3 class="idira-flow__title">Pick the right tool</h3>
        <p class="idira-flow__body">
          TF module → inline TF → <code>ark</code> → <code>conjur</code> → raw REST. Plan first, apply on confirmation, audit log on success.
        </p>
      </div>

      <div class="idira-flow__step">
        <span class="idira-flow__num">03 · TRIAGE</span>
        <h3 class="idira-flow__title">Promote from inbox</h3>
        <p class="idira-flow__body">
          <code>/ca-promote</code> reviews drafts in <code>_inbox/</code> with you. Names, variables, README, SKILL.md generated. Commits.
        </p>
      </div>

      <div class="idira-flow__step">
        <span class="idira-flow__num">04 · PUBLISH</span>
        <h3 class="idira-flow__title">Catalog auto-rebuilds</h3>
        <p class="idira-flow__body">
          Push triggers GitHub Pages CI. New op live at <code>/ops/&lt;area&gt;/&lt;op&gt;/</code> with code, examples, AGENTS guidance.
        </p>
      </div>

    </div>
  </figure>
</section>

<!-- ───── 04 — Catalog at a glance ──────────────────────────────── -->

<section class="idira-section">
  <header class="idira-section__header">
    <div class="idira-section__index">04</div>
    <div>
      <h2 class="idira-section__heading">What the catalog will cover.</h2>
      <p class="idira-section__lede">
        Areas seed themselves as you capture ops. Browse what's already landed, or watch a clean area fill in as the first prompts arrive.
      </p>
    </div>
  </header>

  <div class="idira-card-grid idira-card-grid--areas">

    <a class="idira-card" href="ops/identity/">
      <span class="idira-card__tag">cyberark/idsec</span>
      <h3 class="idira-card__title">Identity</h3>
      <p class="idira-card__body">
        OAuth webapps with PKCE, Service Users, Identity users, roles, policies, auth profiles, attributes.
      </p>
    </a>

    <a class="idira-card" href="ops/secrets-manager/">
      <span class="idira-card__tag">cyberark/conjur</span>
      <h3 class="idira-card__title">Secrets Manager</h3>
      <p class="idira-card__body">
        Policy branches, hosts, groups, secrets, permissions. Encodes the <code>data/mcp/server/&lt;n&gt;</code> + <code>data/mcp/user/&lt;n&gt;</code> convention.
      </p>
    </a>

    <a class="idira-card" href="ops/privilege-cloud/">
      <span class="idira-card__tag">cyberark/idsec</span>
      <h3 class="idira-card__title">Privilege Cloud</h3>
      <p class="idira-card__body">
        Accounts, safes, applications, target platforms. The PCloud surface, declared.
      </p>
    </a>

    <a class="idira-card" href="ops/sia/">
      <span class="idira-card__tag">cyberark/idsec</span>
      <h3 class="idira-card__title">SIA</h3>
      <p class="idira-card__body">
        Secure Infrastructure Access — connectors, relays, certificates, secrets, ~30 settings, target sets.
      </p>
    </a>

    <a class="idira-card" href="ops/secrets-hub/">
      <span class="idira-card__tag">cyberark/cyberark</span>
      <h3 class="idira-card__title">Secrets Hub</h3>
      <p class="idira-card__body">
        Sync policies and cloud secret stores for AWS, Azure, GCP. PAM SH bridge included.
      </p>
    </a>

    <a class="idira-card" href="ops/connector-manager/">
      <span class="idira-card__tag">cyberark/idsec</span>
      <h3 class="idira-card__title">Connector Manager</h3>
      <p class="idira-card__body">
        Networks and pools. The plumbing that lets SIA reach into your infrastructure.
      </p>
    </a>

  </div>
</section>

<!-- ───── 05 — Install ──────────────────────────────────────────── -->

<section class="idira-section">
  <header class="idira-section__header">
    <div class="idira-section__index">05</div>
    <div>
      <h2 class="idira-section__heading">Five lines, <em>two install paths.</em></h2>
      <p class="idira-section__lede">
        Install as a Claude Code plugin (recommended — works from any workspace) or clone the repo (works without Claude Code, useful for CI). Both lead to the same place.
      </p>
    </div>
  </header>

  <div class="idira-terminal">
    <div class="idira-terminal__chrome"><span>~ · claude code · install plugin</span></div>
    <pre><code><span class="idira-comment"># 1. Install the plugin into Claude Code (works from any workspace).</span>
<span class="idira-prompt">$</span> /plugin install github:infamousjoeg/idira-admin-skills

<span class="idira-comment"># 2. Tell it which tenant you're administering — subdomain only.</span>
<span class="idira-prompt">$</span> <span class="idira-keyword">export</span> CYBERARK_TENANT_SUBDOMAIN=<span class="idira-string">"your-tenant"</span>

<span class="idira-comment"># 3. Point at your secret store. Five backends supported out of the box;</span>
<span class="idira-comment">#    add yours in lib/auth.sh if it's not there.</span>
<span class="idira-prompt">$</span> <span class="idira-keyword">export</span> CYBERARK_AUTH_PROVIDER=1password

<span class="idira-comment"># 4. Prompt Claude in this directory:</span>
<span class="idira-prompt">$</span> <span class="idira-comment"># "Create an OAuth webapp for a new MCP called 'my-app'"</span>

<span class="idira-comment"># 5. Watch Claude plan, apply, audit, and auto-draft to _inbox/.</span>
<span class="idira-comment">#    When you're ready to land it:  /ca-promote</span></code></pre>
  </div>

  <p style="font-family: var(--font-body); margin-top: 2rem; color: var(--idira-neutral-700);">
    Need details? The full setup walk-through covers every secret store, the discovery flow, the routing logic, and the first prompt end-to-end.
    <a href="getting-started/">Read the full guide →</a>
  </p>
</section>

<!-- ───── Footer ────────────────────────────────────────────────── -->

<footer class="idira-page-footer">
  <div class="idira-page-footer__sig">— Joe Garcia</div>
  <div class="idira-page-footer__meta">
    <a href="https://github.com/infamousjoeg/idira-admin-skills">Github</a> · APL-2.0 · 2026
  </div>
  <div class="idira-page-footer__disclaimer">
    Not affiliated with, endorsed by, or sponsored by Palo Alto Networks, CyberArk Software Ltd., or the Idira brand team.
    "Idira", "CyberArk", and related marks belong to their respective owners and are used here for descriptive purposes only.
    The visual identity is inspired by the publicly-attested Idira Identity Blue palette; no official marks or trademarked assets are used or redistributed.
  </div>
</footer>
