# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal skills collection managed with [skillshare](https://skillshare.runkids.cc/). Skills are auto-activating knowledge resources that surface context when Claude detects relevant topics.

## Repository Structure

```
skills/<skill-name>/SKILL.md        # Skill definition (YAML frontmatter + markdown body)
skills/<skill-name>/references/     # Optional deep-reference docs loaded on demand
skills/<skill-name>/scripts/        # Optional executable scripts
extras/rules/                       # Shareable rules (synced via skillshare extras)
```

## How Skills Work

- **SKILL.md** has YAML frontmatter (`name`, `description`, `version`, `tags`, `targets`) + markdown content
- `description` controls auto-activation — Claude reads it to decide when to trigger
- Content should use **progressive disclosure**: critical gotchas inline in SKILL.md, detailed reference in `references/`
- `allowed-tools` and `argument-hint` are Claude-specific extensions preserved by skillshare
- Skillshare discovers skills by walking for `SKILL.md` files — no manifest needed

## Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md` with frontmatter
2. Optionally add `skills/<skill-name>/references/` for deep docs
3. Run `skillshare sync` to propagate

## Installing This Collection

```bash
# Browse and select skills interactively
skillshare install raphi011/skills

# Install specific skills
skillshare install raphi011/skills -s go-quality,codecov

# Install all
skillshare install raphi011/skills --all
```

## Key Conventions

- All naming: **kebab-case**
- Skill file must be `SKILL.md` (not README.md)
- SKILL.md should stay under ~250 lines — move detailed content to `references/`
- The `description` field is the most important part of frontmatter — it determines when the skill auto-activates. Be specific about trigger keywords and use cases
- All skills target Claude Code (`targets: [claude]`)
- `.skillignore` excludes non-skill directories (`extras/`, `.claude/`) from discovery
