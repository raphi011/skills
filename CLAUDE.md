# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal Claude Code **skills marketplace** using the "skills-only" pattern (Pattern 2). Skills are auto-activating knowledge resources that surface context when Claude detects relevant topics.

## Repository Structure

```
.claude-plugin/marketplace.json   # Marketplace manifest — defines plugin bundles + skill paths
skills/<skill-name>/SKILL.md      # Skill definition (YAML frontmatter + markdown body)
skills/<skill-name>/references/   # Optional deep-reference docs loaded on demand
docs/                             # Architecture docs (plugin-marketplaces.md)
```

## How Skills Work

- **SKILL.md** has YAML frontmatter (`name`, `description`, `version`) + markdown content
- `description` controls auto-activation — Claude reads it to decide when to trigger
- Content should use **progressive disclosure**: critical gotchas inline in SKILL.md, detailed reference in `references/`
- Skills are grouped into plugin bundles in `marketplace.json` via the `skills` array

## Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md` with frontmatter
2. Optionally add `skills/<skill-name>/references/` for deep docs
3. Add the skill path to the `skills` array in `.claude-plugin/marketplace.json`
4. Install: `claude plugin install personal-skills@my-skills`

## Key Conventions

- All naming: **kebab-case**
- Skill file must be `SKILL.md` (not README.md)
- SKILL.md should stay under ~250 lines — move detailed content to `references/`
- The `description` field is the most important part of frontmatter — it determines when the skill auto-activates. Be specific about trigger keywords and use cases
- Marketplace name is `my-skills`, plugin bundle is `personal-skills`

## Marketplace Manifest Schema

See `docs/plugin-marketplaces.md` for the full marketplace/plugin architecture, including external source formats, plugin anatomy (commands, agents, hooks, MCP), and registration details.
