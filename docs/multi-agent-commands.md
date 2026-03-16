# Multi-Agent Command Pattern

How to write a command that spawns multiple colored subagents and aggregates their results — based on `pr-review-toolkit:review-pr`.

## File Layout

```
plugins/my-plugin/
├── commands/my-command.md   ← orchestrator (the slash command)
└── agents/
    ├── agent-one.md
    └── agent-two.md
```

## Command Frontmatter

Commands that orchestrate agents need `Task` in `allowed-tools`:

```yaml
---
description: "What this command does"
argument-hint: "[optional-args]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task"]
---
```

The body is natural language instructions — no code. Claude reads them and decides which agents to launch, in what order, based on context (e.g. git diff output).

## Agent Frontmatter

```yaml
---
name: agent-name
description: >-
  Detailed trigger description with <example> blocks.
  The more specific, the better — this controls auto-activation.
model: opus       # or "inherit" to use parent model
color: green      # terminal color for this agent's streamed output
---
```

### `color` values

Standard ANSI color names work: `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`.

Each agent in a multi-agent command should have a distinct color so their output is visually separable in the terminal.

### `model` values

| Value | Behavior |
|-------|----------|
| `opus` | Always use Claude Opus |
| `sonnet` | Always use Claude Sonnet |
| `haiku` | Always use Claude Haiku |
| `inherit` | Use whatever model the parent session uses |

## Parallel vs Sequential Launching

**Sequential (default):** The command prose tells Claude to launch agents one at a time via `Task`, wait for each result, then proceed. Easier to read and act on.

**Parallel:** The command prose tells Claude to launch all `Task` calls in a single response turn. Claude Code executes them concurrently.

Example prose in command body:
```
**Parallel approach** (user can request with "parallel" argument):
- Launch all agents simultaneously using multiple Task tool calls in one response
- Results come back together; aggregate after all complete
```

## Conditional Agent Selection

The command body can instruct Claude to only launch certain agents based on context:

```markdown
## Determine Applicable Agents

Based on `git diff --name-only`:
- **Always**: general-reviewer
- **If test files changed**: test-analyzer
- **If new types added**: type-checker
- **If error handling changed**: silent-failure-hunter
```

Claude evaluates these conditions at runtime by reading the diff, not via code.

## Result Aggregation

After all `Task` calls return, the command instructions tell Claude to synthesize a summary. Each agent's return value is a text block Claude can read and organize:

```markdown
## Aggregate Results

After agents complete, summarize:
- **Critical Issues** (must fix)
- **Important Issues** (should fix)
- **Suggestions** (nice to have)
- **Strengths** (what's good)
```

## Agent Body: System Prompt Design

The agent's markdown body is its full system prompt. Effective agent bodies include:

1. **Role statement** — one sentence persona ("You are an elite error handling auditor...")
2. **Non-negotiable principles** — numbered list of core rules
3. **Review process** — step-by-step what to examine
4. **Scoring/severity system** — e.g. CRITICAL / HIGH / MEDIUM, or confidence 0–100
5. **Output format** — exact fields to include per finding (location, severity, description, recommendation, example fix)
6. **Tone guidance** — how to phrase findings

## `description` Field: Most Important Frontmatter

The `description` controls both:
- **Auto-activation** — whether Claude proactively suggests this agent
- **Agent tool routing** — whether Claude chooses this agent when using the `Agent` tool

Make it specific. Include trigger keywords and `<example>` blocks with realistic scenarios:

```yaml
description: >-
  Use this agent when reviewing code changes for silent failures,
  empty catch blocks, or inadequate error handling. Examples:
  <example>
  Context: PR adds try-catch blocks.
  user: "Review PR #123"
  assistant: "I'll use silent-failure-hunter to check error handling."
  </example>
```

## Real Example: pr-review-toolkit

Source: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/pr-review-toolkit/`

| Agent | Color | Model | Specialty |
|-------|-------|-------|-----------|
| code-reviewer | green | opus | CLAUDE.md compliance, bugs, quality |
| silent-failure-hunter | yellow | inherit | Error handling, catch blocks |
| pr-test-analyzer | — | — | Test coverage gaps |
| comment-analyzer | — | — | Comment accuracy vs code |
| type-design-analyzer | — | — | Type encapsulation, invariants |
| code-simplifier | — | opus | Clarity and readability |

The `review-pr` command: checks git diff → decides which agents apply → launches them (sequential by default, parallel if user passes `parallel`) → aggregates into Critical/Important/Suggestions/Strengths summary.
