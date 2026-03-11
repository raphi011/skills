---
name: charmbracelet-tui
description: >-
  This skill should be used when the user asks to "build a TUI", "create a
  terminal UI", "use bubbletea", "add a text input", "add a spinner",
  "create a progress bar", "style with lipgloss", "test a bubbletea model",
  "use teatest", or when code imports charm.land or charmbracelet packages.
  Covers Bubbletea v2, Bubbles v2,
  Lipgloss v2, tea.Model implementations, keyboard/mouse input, program
  lifecycle, bubbles components (textinput, progress, spinner, viewport, list),
  teatest, glamour rendering, inline mode, and tea.Println usage.
version: 1.0.0
---

# Charmbracelet TUI Development (v2)

Best practices for building terminal UIs with the Charmbracelet stack: **Bubbletea** (framework), **Bubbles** (components), **Lipgloss** (styling). All libraries are v2 with `charm.land` import paths.

For detailed patterns, component API, all 11 gotchas with full code, inline mode, wizard patterns, and complete testing guide, consult `references/full-reference.md`.

## Import Paths

```go
tea "charm.land/bubbletea/v2"           // framework
"charm.land/bubbles/v2/textinput"       // text input component
"charm.land/bubbles/v2/progress"        // progress bar component
"charm.land/bubbles/v2/spinner"         // spinner component
"charm.land/bubbles/v2/viewport"        // scrollable content
"charm.land/bubbles/v2/list"            // filterable list
lipgloss "charm.land/lipgloss/v2"       // styling
"charm.land/lipgloss/v2/table"          // table component
"github.com/charmbracelet/colorprofile" // terminal color detection
```

## v2 Breaking Changes Cheat Sheet

### Bubbletea v2

| v1 | v2 |
|----|-----|
| `View() string` | `View() tea.View` via `tea.NewView(s)` |
| `tea.KeyMsg` | `tea.KeyPressMsg` |
| `msg.Type == tea.KeySpace` | `msg.String() == "space"` |
| `msg.Alt` | `msg.Mod.Contains(tea.ModAlt)` |
| `msg.Runes` | `msg.Text` (string) |
| `msg.Type` | `msg.Code` (rune) |
| `tea.KeyCtrlC` | `msg.String() == "ctrl+c"` |
| `tea.WithAltScreen()` | `view.AltScreen = true` |
| `tea.WithMouseCellMotion()` | `view.MouseMode = tea.MouseModeCellMotion` |
| `tea.SetWindowTitle("x")` cmd | `view.WindowTitle = "x"` |
| `tea.MouseMsg` direct fields | `tea.MouseClickMsg` etc., call `.Mouse()` |
| `tea.Sequentially()` | `tea.Sequence()` |
| `tea.WindowSize()` | `tea.RequestWindowSize` |
| `spinner.Tick()` package func | `model.Tick()` method |

### Bubbles v2

| v1 | v2 |
|----|-----|
| `viewport.New(w, h)` | `viewport.New(viewport.WithWidth(80))` |
| `vp.YOffset` field | `vp.SetYOffset()` / `vp.YOffset()` |
| `vp.HighPerformanceRendering` | Removed (Cursed Renderer handles it) |
| `textinput.NewModel()` | `textinput.New()` |
| `ti.PromptStyle` | `ti.Styles.Focused.Prompt` |
| `ti.Cursor` field | `ti.Cursor()` method -> `*tea.Cursor` |
| `help.DefaultKeyMap` var | `help.DefaultKeyMap()` func |
| `DefaultStyles()` | `DefaultStyles(isDark bool)` |

## Elm Architecture

Every interactive component implements `tea.Model`:

```go
type Model interface {
    Init() tea.Cmd                          // initial command (e.g., start spinner)
    Update(tea.Msg) (tea.Model, tea.Cmd)    // handle messages, return new state + side effects
    View() tea.View                         // render current state (MUST be pure)
}
```

- **Update is the only place state changes** — View is a pure function of state
- **Side effects are tea.Cmd** (`func() tea.Msg`) — never perform I/O in Update/View
- **Messages drive everything** — keyboard input, window resize, custom events all arrive as `tea.Msg`

## View Returns tea.View

```go
func (m model) View() tea.View {
    return tea.NewView("rendered content")
}
```

`tea.View` has declarative fields that replace v1 commands:

```go
v := tea.NewView(content)
v.AltScreen = true                          // replaces tea.EnterAltScreen
v.MouseMode = tea.MouseModeCellMotion       // replaces tea.EnableMouseCellMotion
v.ReportFocus = true                        // replaces tea.EnableReportFocus
v.WindowTitle = "My App"                    // replaces tea.SetWindowTitle
```

## Keyboard & Mouse Input

Use `tea.KeyPressMsg` (not the v1 `tea.KeyMsg`):

```go
case tea.KeyPressMsg:
    switch msg.String() {
    case "enter", "ctrl+c", "space", "up", "esc", "q":
    }
```

**Field access** for programmatic matching:

```go
msg.Code    // rune: tea.KeyEnter, tea.KeyUp, 'a', ' ', etc.
msg.Text    // string: typed text (e.g., "a")
msg.Mod     // modifier: tea.ModCtrl, tea.ModAlt, tea.ModShift
```

**Common key constants:** `tea.KeyEnter`, `tea.KeyEscape`, `tea.KeyUp`, `tea.KeyDown`, `tea.KeyLeft`, `tea.KeyRight`, `tea.KeyHome`, `tea.KeyEnd`, `tea.KeyTab`, `tea.KeyBackspace`, `tea.KeyDelete`

**Mouse messages** are split by event type: `tea.MouseClickMsg`, `tea.MouseReleaseMsg`, `tea.MouseWheelMsg`, `tea.MouseMotionMsg`. Access data via `msg.Mouse()` -> `.X`, `.Y`.

## Program Creation & Lifecycle

```go
profile := colorprofile.Detect(os.Stderr, os.Environ())
p := tea.NewProgram(model,
    tea.WithOutput(os.Stderr),          // ALWAYS for piping support
    tea.WithColorProfile(profile),      // explicit color profile
    tea.WithoutSignalHandler(),         // for background/embedded programs
)
finalModel, err := p.Run()
```

**Always output to stderr** when stdout needs to be pipeable (e.g., `cd $(mytool select-dir)`).

## Commands & Messages

```go
// A command is func() tea.Msg
func fetchData() tea.Msg { ... }

// Return from Update
return m, fetchData   // runs async, sends result back as message

// Built-in commands
tea.Quit              // quit the program
tea.Batch(cmd1, cmd2) // run commands in parallel
tea.Sequence(cmd1, cmd2) // run commands sequentially
```

For channel-based streaming and SSE integration, see `references/full-reference.md` -> "SSE / Channel Streaming".

## Light/Dark Detection

```go
// In Init() — non-blocking, works over SSH
func (m Model) Init() tea.Cmd {
    return tea.RequestBackgroundColor
}

// In Update()
case tea.BackgroundColorMsg:
    m.isDark = msg.IsDark()
    m.styles = newStyles(m.isDark)

// Quick alternative (blocking, no SSH support)
isDark := lipgloss.HasDarkBackground(os.Stdin, os.Stderr)
```

`lipgloss.AdaptiveColor` is removed in v2 — use `tea.BackgroundColorMsg` instead.

## Critical Gotchas

These five issues bite silently — no error messages, just broken behavior. For all 11 gotchas with full code examples, see `references/full-reference.md` -> "All Gotchas".

### Focus Must Be Deferred (ref #6)

`textinput.Focus()` is a pointer receiver. When not focused, `textinput.Update()` silently drops all messages — the input appears frozen.

**Why it fails early:**
- `Init()` operates on a copy of the model, so `Focus()` mutations are lost
- Bubbletea v2 sends DECRQM/OSC queries on startup; if textinput is focused before responses are consumed, escape sequences appear as typed garbage

**Fix:** Defer focus until `WindowSizeMsg` arrives:

```go
case tea.WindowSizeMsg:
    if !m.termReady {
        m.termReady = true
        return m, m.input.Focus() // safe — terminal queries consumed
    }
```

### Never Mutate Model from Goroutines (ref #2)

```go
// BAD — silent race condition with View()
go func() { m.data = fetchData() }()

// GOOD — send message through event loop
func fetchCmd() tea.Msg { return dataMsg{fetchData()} }
```

### glamour/termenv TTY Race (ref #7)

`glamour.WithAutoStyle()` reads `/dev/tty` directly — the same fd bubbletea's `TerminalReader` uses. This splits escape sequences, producing garbage in textinput.

**Fix:** Detect dark/light **before** `p.Run()`, use `glamour.WithStandardStyle()`:

```go
isDark := lipgloss.HasDarkBackground(os.Stdin, os.Stderr)
// pass isDark to model, use glamour.WithStandardStyle("dark"/"light")
```

### Panics in Cmds Don't Recover Terminal (ref #3)

Only event-loop panics trigger terminal recovery. A panic inside a `tea.Cmd` goroutine leaves the terminal in raw mode (run `reset` to fix).

**Fix:** Add `defer recover()` in production Cmds.

### SIGINT Must Be Handled Manually (ref #4)

v2 doesn't auto-handle ctrl+c. Without explicit handling, the program ignores ctrl+c silently.

```go
case tea.KeyPressMsg:
    if msg.String() == "ctrl+c" {
        return m, tea.Quit
    }
```

## Common Mistakes

Beyond the v2 breaking changes table above, watch for these non-obvious pitfalls:

| Mistake | Fix |
|---------|-----|
| `view.Content == nil` | `view.Content == ""` (string in v2) |
| Printing to stdout | `tea.WithOutput(os.Stderr)` for piping |
| Missing color profile | `colorprofile.Detect()` + `tea.WithColorProfile()` |
| Style variables for themed UI | Style functions that read current theme |
| `glamour.WithAutoStyle()` in Update | Detect before `p.Run()`, use `WithStandardStyle()` |
| `lipgloss.AdaptiveColor` | `tea.BackgroundColorMsg` + `IsDark()` |
| `os.Getwd()` in commands | Use context-injected working directory |

## Testing Quick Reference

Drive `Update()` directly with synthetic keys — no `tea.Program` needed:

```go
tea.KeyPressMsg{Code: tea.KeyEnter}           // enter
tea.KeyPressMsg{Code: 'c', Mod: tea.ModCtrl}  // ctrl+c
tea.KeyPressMsg{Code: rune('a'), Text: "a"}   // character
```

For teatest integration testing, golden files, and debug helpers, see `references/full-reference.md` -> "Complete Testing Guide".

## Additional Resources

`references/full-reference.md` covers: architecture patterns (composition, layout arithmetic), SSE/channel streaming, full bubbles component API (TextInput, Progress, Table, Viewport, List, Spinner), lipgloss styling (colors, borders, style architecture), all 11 gotchas with code, inline mode (`tea.Println`, scrollback chat), wizard framework, and the complete testing guide (teatest, golden files, debug helpers).
