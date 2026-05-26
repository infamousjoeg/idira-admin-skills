#!/usr/bin/env python3
"""
docs/_build.py — generates docs/ops/ pages from the catalog (tf/ and scripts/).

Walks tf/<area>/<op>/ and scripts/<area>/<op>/ directories, reads each op's
README.md, AGENTS.md, and SKILL.md (under .claude/skills/<op>/), and emits
a corresponding docs/ops/<area>/<op>.md that combines them into one page.

Also generates docs/ops/index.md (the catalog landing) and per-area index files.

Run as part of CI before `mkdocs build` (see .github/workflows/docs.yml).
"""

from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DOCS_OPS = REPO / "docs" / "ops"

AREAS = [
    ("identity", "Identity", "cyberark/idsec — users, roles, OAuth webapps, policies, auth profiles"),
    ("secrets-manager", "Secrets Manager", "cyberark/conjur — policy_branch, host, group, secret, permission"),
    ("privilege-cloud", "Privilege Cloud", "cyberark/idsec — pcloud_account, pcloud_safe, pcloud_target_platform"),
    ("sia", "SIA", "cyberark/idsec — Secure Infrastructure Access connectors, relays, settings"),
    ("secrets-hub", "Secrets Hub", "cyberark/cyberark — sync policies + cloud secret stores"),
    ("connector-manager", "Connector Manager", "cyberark/idsec — networks + pools"),
    ("scripts", "Scripts", "Procedural ops via ark CLI and conjur CLI"),
]


def read_first_line(p: Path, fallback: str = "") -> str:
    """Read the first non-empty line of a file, stripping headers/whitespace."""
    if not p.exists():
        return fallback
    for raw in p.read_text(encoding="utf-8").splitlines():
        line = raw.strip().lstrip("#").strip()
        if line:
            return line
    return fallback


def slugify(s: str) -> str:
    return re.sub(r"[^a-z0-9-]+", "-", s.lower()).strip("-")


def op_page_body(area: str, op: str, kind: str) -> str:
    """Compose a single op page from README + AGENTS + SKILL."""
    source_dir = REPO / kind / area / op
    readme = (source_dir / "README.md").read_text(encoding="utf-8") if (source_dir / "README.md").exists() else "_(no README yet)_"
    agents = (source_dir / "AGENTS.md").read_text(encoding="utf-8") if (source_dir / "AGENTS.md").exists() else ""
    skill = (REPO / ".claude" / "skills" / op / "SKILL.md")
    skill_body = ""
    if skill.exists():
        # strip frontmatter
        body = skill.read_text(encoding="utf-8")
        m = re.match(r"^---\s*\n.*?\n---\s*\n", body, flags=re.DOTALL)
        skill_body = body[m.end():] if m else body

    parts = [
        f"# {op.replace('-', ' ').title()}",
        "",
        f"**Area:** `{area}`  ·  **Kind:** {kind}/{area}/{op}",
        "",
        readme,
    ]
    if skill_body:
        parts += ["", "## How Claude routes this", "", skill_body]
    if agents:
        parts += ["", "## Adapting for your tenant", "", agents]
    return "\n".join(parts) + "\n"


def area_index(area_slug: str, area_label: str, area_desc: str, ops: list[tuple[str, str, str]]) -> str:
    """Render a catalog landing for an area."""
    # NOTE: templates are written flush-left (no indentation, no `dedent`). `dedent`
    # was previously used here, but its common-leading-whitespace algorithm gets
    # defeated by multi-line `{cards}` interpolation — once `cards` contains a
    # newline-joined block, the lines after the first are at column 0, dedent
    # finds 0 common indent, and the surrounding template lines keep their
    # original 4-/8-space indent — which Markdown then treats as a code block.
    if not ops:
        return (
            f"# {area_label}\n"
            f"\n"
            f"> {area_desc}\n"
            f"\n"
            f"_No ops captured yet in this area. "
            f"The next ad-hoc op you ask Claude to do here will seed it._\n"
        )
    # Grid div has no `markdown` attribute — contents are raw HTML, so
    # Python-Markdown leaves them alone (previously it mangled the first card,
    # hoisting its inner h3/p out of the <a> and duplicating the wrapper).
    # Inner markup uses BEM classes (.idira-card__title / .idira-card__body)
    # so card-specific styles in idira.css apply instead of the global
    # .md-typeset h3/p rules.
    cards = "\n".join(
        f'<a class="idira-card" href="{op_slug}/">'
        f'<div class="idira-card__title">{op_label}</div>'
        f'<div class="idira-card__body">{op_summary}</div>'
        f'</a>'
        for op_slug, op_label, op_summary in ops
    )
    return (
        f"# {area_label}\n"
        f"\n"
        f"> {area_desc}\n"
        f"\n"
        f'<div class="idira-card-grid">\n'
        f"{cards}\n"
        f"</div>\n"
    )


def overall_index(area_summaries: list[tuple[str, str, str, int]]) -> str:
    """Catalog top-level page."""
    # See area_index() for why the grid div drops `markdown` and the cards use
    # BEM .idira-card__title / .idira-card__body instead of <h3>/<p>.
    cards = "\n".join(
        f'<a class="idira-card" href="{slug}/">'
        f'<div class="idira-card__title">{label} '
        f'<span class="idira-badge idira-badge--terraform">{count}</span></div>'
        f'<div class="idira-card__body">{desc}</div>'
        f'</a>'
        for slug, label, desc, count in area_summaries
    )
    return (
        "# Catalog\n"
        "\n"
        "Browseable index of every captured operation. Each op is a Terraform module (`tf/<area>/<op>/`)\n"
        "or a script (`scripts/<area>/<op>/`) with a `README.md`, an `AGENTS.md` for AI-driven adaptation,\n"
        "and an auto-generated `SKILL.md` so Claude Code (or any AI agent) can re-invoke it.\n"
        "\n"
        '<div class="idira-card-grid">\n'
        f"{cards}\n"
        "</div>\n"
    )


def main():
    DOCS_OPS.mkdir(parents=True, exist_ok=True)
    summaries = []

    for area_slug, area_label, area_desc in AREAS:
        # Scripts live in scripts/<area>/<op>/, modules in tf/<area>/<op>/.
        # For the "scripts" pseudo-area, walk scripts/ at the top level.
        if area_slug == "scripts":
            roots = [(REPO / "scripts", "scripts")]
        else:
            roots = [(REPO / "tf" / area_slug, "tf")]

        ops: list[tuple[str, str, str]] = []
        for root, kind in roots:
            if not root.exists():
                continue
            for op_dir in sorted(p for p in root.iterdir() if p.is_dir() and not p.name.startswith("_")):
                op_slug = op_dir.name
                if area_slug == "scripts":
                    # scripts/<top-area>/<op>/ — flatten to "top-area/op" in display
                    for sub_op in sorted(p for p in op_dir.iterdir() if p.is_dir() and not p.name.startswith("_")):
                        op_full_slug = f"{op_slug}--{sub_op.name}"
                        op_label = f"{op_slug}/{sub_op.name}"
                        op_summary = read_first_line(sub_op / "README.md", fallback="(no README yet)")
                        ops.append((op_full_slug, op_label, op_summary))
                        page_dir = DOCS_OPS / area_slug / op_full_slug
                        page_dir.mkdir(parents=True, exist_ok=True)
                        (page_dir / "index.md").write_text(
                            op_page_body(op_slug, sub_op.name, "scripts/"),
                            encoding="utf-8",
                        )
                else:
                    op_label = op_slug
                    op_summary = read_first_line(op_dir / "README.md", fallback="(no README yet)")
                    ops.append((op_slug, op_label, op_summary))
                    page_dir = DOCS_OPS / area_slug / op_slug
                    page_dir.mkdir(parents=True, exist_ok=True)
                    (page_dir / "index.md").write_text(
                        op_page_body(area_slug, op_slug, kind),
                        encoding="utf-8",
                    )

        # Per-area index page
        area_dir = DOCS_OPS / area_slug
        area_dir.mkdir(parents=True, exist_ok=True)
        (area_dir / "index.md").write_text(
            area_index(area_slug, area_label, area_desc, ops), encoding="utf-8"
        )
        summaries.append((area_slug, area_label, area_desc, len(ops)))

    # Top-level catalog page
    (DOCS_OPS / "index.md").write_text(overall_index(summaries), encoding="utf-8")
    print(f"_build.py: generated {sum(c for *_, c in summaries)} ops across {len(summaries)} areas")


if __name__ == "__main__":
    main()
