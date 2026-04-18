---
name: mermaid
description: >
  Use when the user asks to create a diagram, visualize a process, draw a flowchart,
  show a sequence diagram, model a state machine, create an ER diagram, visualize
  architecture, or any request involving Mermaid syntax or diagram generation.
tags: [diagram, visualization]
targets: [claude]
allowed-tools: Read Write Edit
metadata:
  argument-hint: "[diagram description or requirements]"
---

# Mermaid Diagram Generator

Generate Mermaid diagram code from user requirements. **Always read the reference doc** for the chosen diagram type before generating — don't rely on memory.

## Diagram Type Selection

**Read the corresponding reference before generating.** Each file contains the full syntax spec with examples.

| Type | Reference | When to use |
| ---- | --------- | ----------- |
| Flowchart | [flowchart.md](references/flowchart.md) | Processes, decisions, workflows, algorithms |
| Sequence | [sequenceDiagram.md](references/sequenceDiagram.md) | API calls, service interactions, message flows |
| Class | [classDiagram.md](references/classDiagram.md) | OOP structure, inheritance, interfaces |
| State | [stateDiagram.md](references/stateDiagram.md) | State machines, lifecycle transitions |
| ER | [entityRelationshipDiagram.md](references/entityRelationshipDiagram.md) | Database schema, entity relationships |
| C4 | [c4.md](references/c4.md) | System architecture (context, container, component) |
| Architecture | [architecture.md](references/architecture.md) | System components with icons and groups |
| Gantt | [gantt.md](references/gantt.md) | Project timelines, task scheduling |
| Mindmap | [mindmap.md](references/mindmap.md) | Hierarchical brainstorming, knowledge graphs |
| Timeline | [timeline.md](references/timeline.md) | Historical events, milestones |
| Git Graph | [gitgraph.md](references/gitgraph.md) | Branch strategies, merge flows |
| User Journey | [userJourney.md](references/userJourney.md) | UX flows with satisfaction scores |
| Kanban | [kanban.md](references/kanban.md) | Task boards, workflow stages |
| Block | [block.md](references/block.md) | System component diagrams, modules |
| Sankey | [sankey.md](references/sankey.md) | Flow quantities, conversions |
| XY Chart | [xyChart.md](references/xyChart.md) | Line/bar charts with data |
| Pie | [pie.md](references/pie.md) | Proportions, distributions |
| Quadrant | [quadrantChart.md](references/quadrantChart.md) | 2x2 analysis matrices |
| Radar | [radar.md](references/radar.md) | Multi-dimensional comparison |
| Treemap | [treemap.md](references/treemap.md) | Hierarchical data visualization |
| Packet | [packet.md](references/packet.md) | Network protocols, binary structures |
| Requirement | [requirementDiagram.md](references/requirementDiagram.md) | Requirements traceability |
| ZenUML | [zenuml.md](references/zenuml.md) | Sequence diagrams (code-style syntax) |

### Configuration references

- [Theming](references/config-theming.md) — custom colors and styles
- [Directives](references/config-directives.md) — per-diagram `%%{init: ...}%%` config
- [Layouts](references/config-layouts.md) — direction and spacing
- [Configuration](references/config-configuration.md) — global settings
- [Math](references/config-math.md) — LaTeX math in labels

## Common Mistakes

### Newlines: use `<br>`, NOT `\n`

`\n` renders as literal text in most shapes. Always use `<br>` and **wrap the label in quotes**:

```
A["Line one<br>Line two"]       %% ✅ works
B("Line one\nLine two")         %% ❌ literal \n
```

### Reserved word "end"

The word `end` in lowercase breaks flowcharts and sequence diagrams. Use `End`, `END`, or wrap in quotes/brackets.

### Edge labels with special chars

Wrap edge labels containing special characters in quotes:
```
A -->|"yes (confirmed)"| B      %% ✅ quoted
A -->|yes (confirmed)| B        %% ❌ breaks on parens
```

### Flowchart node IDs starting with "o" or "x"

`A---oB` creates a circle edge, `A---xB` a cross edge. Add a space or capitalize: `A--- oB` or `A---OB`.

## Output Rules

1. Wrap in ` ```mermaid ` code blocks
2. Use semantic node IDs (`userService`, `authCheck`, not `A`, `B`, `C`)
3. Keep diagrams focused — split complex systems into multiple diagrams rather than one giant one
4. Apply `%%{init: {'theme': 'neutral'}}%%` when the default theme is too colorful

---

User requirements: $ARGUMENTS
