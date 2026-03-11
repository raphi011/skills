# Claude Code Plugin Marketplaces

A marketplace is a git repo that indexes installable plugins for Claude Code. Anthropic ships two official ones; you can create your own.

## Marketplace vs Plugin

| Concept | Manifest file | Purpose |
|---------|--------------|---------|
| **Marketplace** | `.claude-plugin/marketplace.json` | Index of installable plugins |
| **Plugin** | `.claude-plugin/plugin.json` | Single installable unit (skills, commands, agents, hooks) |

A marketplace repo contains one or more plugins. A plugin repo is a standalone installable unit.

## Marketplace Manifest

Located at `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "Your Name",
    "email": "optional@email.com"
  },
  "metadata": {
    "description": "What this marketplace offers",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "description": "What this plugin does",
      "source": "./plugins/plugin-name",
      "category": "development"
    }
  ]
}
```

### Required fields

- `name` — unique marketplace identifier (kebab-case)
- `plugins` — array of plugin entries

### Plugin entry fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Plugin identifier (kebab-case) |
| `description` | yes | What the plugin does |
| `source` | yes | Path to plugin directory or external source |
| `category` | no | Grouping: development, productivity, security, etc. |
| `version` | no | Semver string |
| `author` | no | `{ name, email }` |
| `homepage` | no | URL to docs/repo |
| `strict` | no | Boolean, defaults to true |
| `skills` | no | Array of skill directory paths (skills-only pattern) |
| `lspServers` | no | LSP server definitions (for language server plugins) |
| `tags` | no | Array of strings, e.g. `["community-managed"]` |

### External source formats

Plugins can reference external repos instead of local paths:

```json
// Git URL
"source": {
  "source": "url",
  "url": "https://github.com/user/repo.git"
}

// GitHub shorthand
"source": {
  "source": "github",
  "repo": "user/repo"
}

// Git subdirectory
"source": {
  "source": "git-subdir",
  "url": "https://github.com/user/repo.git",
  "path": "plugin"
}

// Pinned to commit
"source": {
  "source": "url",
  "url": "https://github.com/user/repo.git",
  "sha": "abc123..."
}
```

## Two Marketplace Patterns

### Pattern 1: Multi-plugin (like `claude-plugins-official`)

Each plugin is a full self-contained directory with its own `.claude-plugin/plugin.json`.

```
marketplace-repo/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── plugin-a/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── commands/
│   │   ├── agents/
│   │   ├── skills/
│   │   └── hooks/
│   └── plugin-b/
│       └── ...
└── external_plugins/     # Wrappers for external sources
    └── some-tool/
        └── .claude-plugin/
            └── plugin.json
```

Source in marketplace.json: `"source": "./plugins/plugin-a"`

Best for: diverse, independent plugins from multiple authors.

### Pattern 2: Skills-only (like `anthropic-agent-skills`)

Skills live in a flat directory. The marketplace.json groups them into logical plugins without per-plugin manifests.

```
marketplace-repo/
├── .claude-plugin/
│   └── marketplace.json
└── skills/
    ├── skill-one/
    │   └── SKILL.md
    ├── skill-two/
    │   └── SKILL.md
    └── skill-three/
        └── SKILL.md
```

Marketplace.json references skills directly:

```json
{
  "plugins": [
    {
      "name": "my-skills-bundle",
      "description": "Collection of custom skills",
      "source": "./",
      "skills": [
        "./skills/skill-one",
        "./skills/skill-two"
      ]
    }
  ]
}
```

Best for: personal skill collections, single-author repos.

## Marketplace Registration

### Where marketplaces are tracked

`~/.claude/plugins/known_marketplaces.json`:

```json
{
  "my-marketplace": {
    "source": {
      "source": "git",
      "url": "https://github.com/user/my-marketplace.git"
    },
    "installLocation": "/Users/you/.claude/plugins/marketplaces/my-marketplace",
    "lastUpdated": "2026-01-01T00:00:00.000Z"
  }
}
```

For local development, the `installLocation` can point directly to your repo.

### Where installed plugins are tracked

`~/.claude/plugins/installed_plugins.json`:

```json
{
  "version": 2,
  "plugins": {
    "plugin-name@marketplace-name": [
      {
        "scope": "user",
        "installPath": "/path/to/cached/plugin",
        "version": "1.0.0",
        "installedAt": "2026-01-01T00:00:00.000Z",
        "lastUpdated": "2026-01-01T00:00:00.000Z",
        "gitCommitSha": "abc123..."
      }
    ]
  }
}
```

### Plugin cache

Installed plugins are cached at:
`~/.claude/plugins/cache/<marketplace-name>/<plugin-name>/<version>/`

## Plugin Anatomy

A plugin (whether standalone or inside a marketplace) can contain:

### Skills (`skills/`)

Auto-activated based on task context. Each skill is a subdirectory with `SKILL.md`:

```markdown
---
name: my-skill
description: When to activate this skill
version: 1.0.0
---

Instructions for Claude when this skill activates...
```

### Commands (`commands/`)

User-invoked slash commands. Each is a `.md` file:

```markdown
---
description: What this command does
argument-hint: "[args]"
allowed-tools: ["Bash", "Read", "Write"]
---

Command implementation instructions...
```

Filename becomes the command: `review-pr.md` → `/review-pr`

### Agents (`agents/`)

Subagent definitions. Each is a `.md` file with trigger examples:

```markdown
---
name: code-reviewer
description: When to use this agent (include <example> blocks)
model: inherit
---

Agent instructions...
```

### Hooks (`hooks/`)

Event handlers in `hooks.json`:

```json
{
  "PreToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh",
      "timeout": 30
    }]
  }]
}
```

Events: `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreCompact`, `Notification`

### MCP Servers (`.mcp.json`)

External tool integrations:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/server.js"],
      "env": { "API_KEY": "${API_KEY}" }
    }
  }
}
```

## Portable Paths

Always use `${CLAUDE_PLUGIN_ROOT}` for intra-plugin path references (hooks, MCP servers, scripts). Never hardcode absolute paths — plugins install in different locations depending on user and method.

## Key Rules

- Marketplace manifest is `marketplace.json`, not `plugin.json`
- Component directories (`commands/`, `agents/`, `skills/`, `hooks/`) go at plugin root, NOT inside `.claude-plugin/`
- Skills must have `SKILL.md` (not `README.md`)
- All naming uses kebab-case
- Auto-discovery loads everything in conventional directories — no explicit registration needed per component
- Custom paths in `plugin.json` supplement defaults, they don't replace them
