# Charmbracelet TUI — Full Reference

Detailed patterns and reference material for Bubbletea v2, Bubbles v2, and Lipgloss v2. Consult this file when the lean SKILL.md pointers are insufficient.

## Architecture Patterns

### Keep the Event Loop Fast

```go
// GOOD — offload work to Cmd
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) { // ... other cases
    case submitMsg:
        return m, m.doExpensiveWork // runs in goroutine
}

// BAD — blocks the event loop
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) { // ... other cases
    case submitMsg:
        result := doExpensiveWork() // blocks rendering
        m.result = result
        return m, nil
}
```

`View()` must be a **pure render function** — no side effects, no I/O.

### Model Composition (Parent -> Children)

```go
type App struct {
    sidebar  SidebarModel
    content  ContentModel
    active   pane
    width, height int
}

func (m App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.WindowSizeMsg:
        // Broadcast to ALL children
        m.sidebar.SetSize(leftW, msg.Height)
        m.content.SetSize(rightW, msg.Height)

    case tea.KeyPressMsg:
        // Global keys first
        if key.Matches(msg, m.keys.Quit) {
            return m, tea.Quit
        }
        // Route to active child
        switch m.active {
        case paneSidebar:
            return m, m.sidebar.handleKey(msg)
        case paneContent:
            return m, m.content.handleKey(msg)
        }
    }
}
```

**Key rules:**
- Root handles global keys, delegates domain keys to active child
- Broadcast `WindowSizeMsg` to all children (not just active)
- Children communicate via custom messages, not direct references

### Layout Arithmetic

```go
// GOOD — measure rendered content dynamically
header := m.renderHeader()
footer := m.renderFooter()
contentH := m.height - lipgloss.Height(header) - lipgloss.Height(footer)

// BAD — hardcoded magic numbers
contentH := m.height - 3
```

Use `lipgloss.Height()` and `lipgloss.Width()` to measure rendered strings.

## SSE / Channel Streaming

Full pattern for integrating server-sent events or any channel-based data source with bubbletea:

```go
// 1. Start stream — returns channel
func startStream() tea.Cmd {
    return func() tea.Msg {
        ch, err := client.Stream(ctx)
        if err != nil {
            return streamErrMsg{err}
        }
        return streamStartMsg{ch: ch}
    }
}

// 2. Listen for next event — chain Cmds
func listenStream(ch <-chan Event) tea.Cmd {
    return func() tea.Msg {
        event, ok := <-ch
        if !ok {
            return streamDoneMsg{}
        }
        return streamEventMsg{event: event, ch: ch}
    }
}

// 3. In Update — process + chain (inside switch msg := msg.(type))
case streamStartMsg:
    m.streaming = true
    return m, listenStream(msg.ch) // start listening

case streamEventMsg:
    m.handleEvent(msg.event)
    return m, listenStream(msg.ch) // chain next read

case streamDoneMsg:
    m.streaming = false
    return m, m.loadFinalState() // reload after stream ends
```

**Important:** Pass the channel through each message so the next Cmd can read from it. Never store the channel on the model and read from it in a goroutine — always use the Cmd pattern.

### Batch vs Sequence

```go
// Concurrent — independent operations
cmd := tea.Batch(fetchUsers, fetchSettings, startTimer)

// Serial — order matters or results depend on each other
cmd := tea.Sequence(saveFile, reloadView)
```

## Bubbles Components — Detailed API

### TextInput

```go
ti := textinput.New()
ti.Placeholder = "Enter value..."
ti.CharLimit = 156
ti.Prompt = "> "
ti.SetWidth(40)

// Cursor styling
styles := ti.Styles()
styles.Cursor.Shape = tea.CursorBar     // also: tea.CursorBlock, tea.CursorUnderline
styles.Cursor.Blink = true
styles.Focused.Text = myStyle           // style when focused
styles.Blurred.Text = myStyle           // style when blurred
ti.SetStyles(styles)

// Focus management
// WARNING: Do NOT call Focus() in Init() or constructors — see Gotcha #6.
// Defer until WindowSizeMsg arrives to avoid silent input freeze.
ti.Focus()                              // activate input (only after terminal ready)
ti.Blur()                               // deactivate (no Cmd returned)
ti.Focused()                            // check state

// Forward messages in Update
m.input, cmd = m.input.Update(msg)
```

### Progress

```go
prog := progress.New(
    progress.WithWidth(40),
    progress.WithoutPercentage(),
    progress.WithColors(primaryColor, accentColor),  // variadic color.Color
)

bar := prog.ViewAs(0.75)  // render at 75%

// Forward Update for animations
prog, cmd = prog.Update(msg)
```

### Table (lipgloss/v2/table)

```go
t := table.New().
    Headers("NAME", "STATUS", "COUNT").
    Rows(rows...).
    BorderTop(false).
    BorderBottom(false).
    BorderLeft(false).
    BorderRight(false).
    BorderHeader(false).
    BorderColumn(false).
    BorderRow(false).
    StyleFunc(func(row, col int) lipgloss.Style {
        if row == table.HeaderRow {
            return lipgloss.NewStyle().Bold(true).PaddingRight(2)
        }
        return lipgloss.NewStyle().PaddingRight(2)
    })

output := t.String()
```

### Spinner

```go
s := spinner.New()
s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))

// In Init — start the spinner tick
func (m model) Init() tea.Cmd {
    return m.spinner.Tick() // v2: method on model, not package func
}

// In Update — forward spinner messages
case spinner.TickMsg:
    m.spinner, cmd = m.spinner.Update(msg)
    return m, cmd

// In View
m.spinner.View() // renders current frame
```

### Viewport

```go
vp := viewport.New(viewport.WithWidth(80))
vp.SetContent("long content here...")

// In Update — forward messages for scroll handling
vp, cmd = vp.Update(msg)

// Access
vp.YOffset()        // current scroll position (getter method in v2)
vp.SetYOffset(n)    // set scroll position
```

### List

```go
import "charm.land/bubbles/v2/list"

items := []list.Item{...}
l := list.New(items, list.NewDefaultDelegate(), width, height)
l.Title = "My List"
```

## Lipgloss Styling — Full Reference

### Style Creation

```go
style := lipgloss.NewStyle().
    Foreground(lipgloss.Color("62")).   // ANSI color
    Bold(true).
    Italic(true).
    Underline(true).
    Padding(0, 1).
    MarginTop(1)

rendered := style.Render("text")
```

### Colors

```go
lipgloss.Color("62")        // ANSI 256
lipgloss.Color("#ff0000")   // hex
lipgloss.NoColor{}          // terminal default (no color override)
```

`lipgloss.Color()` returns `color.Color` (`image/color`). Use this type for color variables:

```go
import "image/color"
var Primary color.Color = lipgloss.Color("62")
```

### Character-Level Styling (Fuzzy Match Highlights)

```go
lipgloss.StyleRunes(text, matchedIndices, highlightStyle, normalStyle)
```

### Borders

```go
lipgloss.NewStyle().
    Border(lipgloss.RoundedBorder()).       // also: NormalBorder, ThickBorder, DoubleBorder
    BorderForeground(primaryColor).
    BorderLeft(true)                        // enable specific sides
```

### Style Architecture Pattern

Define a central theme with semantic color roles, then build styles as functions (not variables) to support runtime theme switching:

```go
// Theme struct with semantic colors (styles/theme.go)
type Theme struct {
    Primary color.Color   // borders, titles
    Accent  color.Color   // selected/active items
    Success color.Color   // checkmarks
    Error   color.Color   // error messages
    Muted   color.Color   // disabled text
}

// Styles as functions to pick up theme changes (framework/styles.go)
func TitleStyle() lipgloss.Style {
    return lipgloss.NewStyle().Bold(true).Foreground(styles.Primary)
}

func SelectedStyle() lipgloss.Style {
    return lipgloss.NewStyle().Bold(true).Foreground(styles.Accent)
}
```

**Why functions not variables:** Package-level `var` styles capture colors at init time. If the theme changes at runtime (e.g., from config), those variables are stale. Style functions read current color values on each call.

### Background Detection

```go
isDark := lipgloss.HasDarkBackground(os.Stdin, os.Stderr)
```

## All Gotchas (Full Code Examples)

### 1. Message Ordering is NOT Guaranteed

Commands run in goroutines — completion order is unpredictable. Only user input maintains order.

**Fix:** Use `tea.Sequence()` when order matters, or design handlers to be order-independent.

### 2. Never Mutate Model from Goroutines

```go
// BAD — race condition with View()
go func() {
    m.data = fetchData()
}()

// GOOD — send message back through event loop
func fetchCmd() tea.Msg {
    data := fetchData()
    return dataMsg{data}
}
```

### 3. Panics in Commands Don't Recover Terminal

Only event-loop panics trigger terminal recovery. A panic inside a `tea.Cmd` goroutine leaves the terminal in raw mode.

**Fix:** Run `reset` in terminal. In production, add panic recovery in Cmds:

```go
func safeCmd(fn func() tea.Msg) tea.Cmd {
    return func() tea.Msg {
        defer func() {
            if r := recover(); r != nil {
                // log and return error message
            }
        }()
        return fn()
    }
}
```

### 4. SIGINT/SIGQUIT Must Be Handled Manually

v2 doesn't auto-handle signals. Add explicit handling in `Update()`:

```go
case tea.KeyPressMsg:
    if msg.String() == "ctrl+c" {
        return m, tea.Quit
    }
```

### 5. Hot Reload Tools Don't Support TTY

`air` doesn't support TTY programs. Use `watchexec` with separate build/run scripts instead.

### 6. Focus Must Be Deferred Until Terminal Setup Completes

`textinput.Focus()` is a **pointer receiver** that sets `m.focus = true` and returns a cursor blink `tea.Cmd`. When not focused, `textinput.Update()` silently drops all messages — the input appears frozen.

Two issues with early focus:

**Problem 1 — `Init()` value copy**: `Init()` operates on a copy of the model, so `Focus()` mutations are lost.

**Problem 2 — Terminal query responses**: Bubbletea v2 sends DECRQM and OSC queries on startup. If the textinput is focused before these responses are consumed, the escape sequences can appear as typed garbage (e.g. `]11;rgb:3030/3434/4646[?2026;2$y`).

**Fix:** Defer focus until `WindowSizeMsg` arrives (indicates terminal setup is done) AND any other readiness conditions are met:

```go
func NewModel() Model {
    ti := textinput.New()
    // Do NOT focus here — terminal queries haven't been sent yet
    return Model{input: ti}
}

func (m Model) Init() tea.Cmd {
    return m.loadData() // no focus cmd
}

case tea.WindowSizeMsg:
    if !m.termReady {
        m.termReady = true
        return m, m.tryFocus()
    }

func (m *Model) tryFocus() tea.Cmd {
    if m.termReady && m.ready {
        return m.input.Focus() // safe — terminal queries consumed
    }
    return nil
}
```

Also remember: `Blur()` does NOT return a Cmd — just call it directly.

### 7. Never Use `glamour.WithAutoStyle()` or `termenv.HasDarkBackground()` Inside Update()

`glamour.WithAutoStyle()` calls `termenv.HasDarkBackground()` which reads **directly from `/dev/tty`** — the same fd bubbletea's `TerminalReader` is reading. This causes a data race that can split escape sequences, producing garbage in the textinput.

The race: termenv steals bytes meant for `TerminalReader`, causing it to timeout mid-sequence and emit partial escape codes as individual `KeyPressMsg` characters.

**Fix:** Detect dark/light background **before** `p.Run()` starts, then use `glamour.WithStandardStyle()`:

```go
// cmd_ui.go — BEFORE bubbletea starts
isDark := lipgloss.HasDarkBackground(os.Stdin, os.Stderr)
model := NewModel(client, vaultID, isDark)

// model constructor
glamourStyle := "light"
if isDark {
    glamourStyle = "dark"
}
r, _ := glamour.NewTermRenderer(
    glamour.WithStandardStyle(glamourStyle), // NOT WithAutoStyle()
    glamour.WithWordWrap(width),
)

// updateRenderer() — reuses pre-detected style, no TTY read
func (m *Model) updateRenderer() {
    r, err := glamour.NewTermRenderer(
        glamour.WithStandardStyle(m.glamourStyle), // safe
        glamour.WithWordWrap(m.width - 4),
    )
}
```

Ref: [bubbletea#1590](https://github.com/charmbracelet/bubbletea/issues/1590)

### 8. Viewport Content Accumulation

Viewports store all content in memory. For long-running sessions (chat apps), content can grow unbounded.

**Fix:** Implement pagination or a sliding window for message history. Or use inline mode with `tea.Println` scrollback instead of a viewport.

### 9. Glamour Renderer and Window Resize

`glamour.NewTermRenderer()` is moderately expensive. Don't recreate on every `WindowSizeMsg`.

**Fix:** Cache the renderer and only recreate when width actually changes.

### 10. Two-Phase ESC Pattern

Better UX: first ESC clears input, second ESC cancels/quits.

```go
case tea.KeyPressMsg:
    if msg.String() == "esc" {
        if m.input.Value() != "" {
            m.input.SetValue("")
            return m, nil
        }
        return m, tea.Quit // or navigate back
    }
```

### 11. AdaptiveColor Removed in v2

`lipgloss.AdaptiveColor` is gone. Use `tea.BackgroundColorMsg` to detect dark/light and select styles accordingly.

## Inline Mode (Non-Alt-Screen)

When `View.AltScreen` is `false` (the default), bubbletea uses **inline mode** with a dynamically-sized managed region.

### How It Works

- `View()` content height **defines** the managed region size — it resizes every frame
- The managed region repaints in-place at the bottom of the terminal
- `tea.Println(...)` returns a `tea.Cmd` that prints text **above** the managed region into permanent terminal scrollback
- On quit, scrollback is preserved — user can scroll up to see everything

### `tea.Println` / `tea.Printf`

```go
// Both return tea.Cmd — usable with tea.Sequence, tea.Batch
tea.Println("message")
tea.Printf("hello %s", name)

// Silent in alt-screen mode — no output produced
// Always prints on its own line with trailing \r\n
```

Program-level methods for use from outside the event loop:
```go
p.Println(...)  // blocks until message accepted
p.Printf(...)
```

### Scrollback Chat Pattern

Used for Claude-Code-style inline chat UIs:

```go
// 1. Completed messages -> scrollback (permanent)
func (m *Model) sendMessage() tea.Cmd {
    return tea.Sequence(
        tea.Println(renderUserMessage(content)),  // user msg to scrollback
        startStreamCmd,                            // begin SSE stream
    )
}

// 2. Active streaming -> View() managed region (repaints in-place)
func (m Model) View() tea.View {
    var content strings.Builder
    if m.streaming {
        content.WriteString(renderStreamParts(m.renderer, m.streamParts, m.pendingApproval, m.width))
    }
    content.WriteString(m.input.View())
    return tea.NewView(content.String())
}

// 3. When stream completes -> commit to scrollback
func (m *Model) finalizeStream() tea.Cmd {
    rendered := renderAssistantMessage(m.renderer, m.streamParts)
    m.streamParts = nil
    return tea.Println(rendered)  // View() shrinks back to just input
}
```

No viewport component needed — terminal scrollback handles history.

### Key Differences from Alt-Screen

| Behavior | Inline | Alt-Screen |
|---|---|---|
| Terminal scrollback | Preserved | Replaced (separate buffer) |
| `tea.Println` | Works | No-op |
| Region height | Dynamic (= content height) | Fixed (= terminal height) |
| On quit | Cursor moves to bottom, scrollback preserved | Exits alt buffer, restores main screen |
| Frame > terminal height | Top lines dropped | Should not happen |

### Inline Mode Gotchas

- `WindowSizeMsg` arrives automatically at startup and on SIGWINCH — no need to request it
- Very long streaming responses grow the managed region toward terminal height; top lines are dropped if it exceeds
- Inline mode cursor sits at end of managed region by default; set `View.Cursor` explicitly for text input positioning

## Wizard Framework Patterns

### Step Interface

Each wizard step implements a uniform interface:
- `Init() tea.Cmd` — setup (focus text input, etc.)
- `Update(tea.KeyPressMsg) (Step, tea.Cmd, StepResult)` — only handles key events
- `View() string` — render
- `Value() StepValue` — extract result
- `HasClearableInput() / ClearInput()` — two-phase ESC support

The wizard orchestrator handles navigation (advance/back/skip) and summary display.

### Disabled Options with Auto-Skip

```go
func findNextEnabled(options []Option, from int) int {
    for i := from + 1; i < len(options); i++ {
        if !options[i].Disabled {
            return i
        }
    }
    return from
}
```

### Scroll Indicators for Bounded Lists

```go
if start > 0 {
    sb.WriteString("  more above\n")
}
// render visible items
if end < len(options) {
    sb.WriteString("  more below\n")
}
```

## Complete Testing Guide

### teatest — Integration Testing

```go
func TestModel(t *testing.T) {
    m := NewModel()
    tm := teatest.NewTestModel(t, m,
        teatest.WithInitialTermSize(80, 24),
    )

    // Send input
    tm.Send(tea.KeyPressMsg{Code: 'q'})

    // Wait for condition
    teatest.WaitFor(t, tm.Output(), func(bts []byte) bool {
        return bytes.Contains(bts, []byte("expected"))
    })

    // Assert final state
    fm := tm.FinalModel(t).(Model)
    assert.Equal(t, expected, fm.someField)
}
```

### Golden File Testing

```go
out, _ := io.ReadAll(tm.FinalOutput(t))
teatest.RequireEqualOutput(t, out)
// Update with: go test -v ./... -update
```

**CI tip:** Force ASCII color profile for consistent golden files:
```go
func init() {
    lipgloss.SetDefaultColorProfile(colorprofile.Ascii)
}
```

Add to `.gitattributes`: `*.golden -text`

### Pure Model Testing (No teatest)

Drive `Update()` directly with messages and assert state:

```go
func TestUpdate(t *testing.T) {
    m := NewModel()
    m, cmd := m.Update(someMsg{data: "x"})
    assert.Equal(t, "x", m.(Model).data)
    assert.Nil(t, cmd)
}
```

### Synthetic Key Events Helper

```go
func keyMsg(key string) tea.KeyPressMsg {
    switch key {
    case "enter":
        return tea.KeyPressMsg{Code: tea.KeyEnter}
    case "up":
        return tea.KeyPressMsg{Code: tea.KeyUp}
    case "down":
        return tea.KeyPressMsg{Code: tea.KeyDown}
    case "left":
        return tea.KeyPressMsg{Code: tea.KeyLeft}
    case "right":
        return tea.KeyPressMsg{Code: tea.KeyRight}
    case "esc":
        return tea.KeyPressMsg{Code: tea.KeyEscape}
    case "ctrl+c":
        return tea.KeyPressMsg{Code: 'c', Mod: tea.ModCtrl}
    default:
        if len(key) == 1 {
            return tea.KeyPressMsg{Code: rune(key[0]), Text: key}
        }
        return tea.KeyPressMsg{}
    }
}
```

### Type-Safe Step Testing (Generic Helper)

For testing subcomponents that return their own type (not `tea.Model`):

```go
func updateStep[T framework.Step](t *testing.T, s T, msg tea.KeyPressMsg) (T, framework.StepResult) {
    t.Helper()
    newStep, _, result := s.Update(msg)
    return newStep.(T), result
}
```

### Debugging: Message Dump

```go
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    if m.debugFile != nil {
        spew.Fdump(m.debugFile, msg)
    }
    // ...
}
```

Tail the debug file during development to see message types, ordering, and timing.

## Performance Notes

- **Cursed Renderer (v2):** Based on ncurses algorithms, much faster than v1. Handles synchronized output automatically.
- **Auto color downsampling:** v2 adjusts colors to terminal capabilities automatically.
- **Declarative View fields:** Eliminates race conditions from v1's imperative command approach.

## Sources

- [Bubbletea v2 Upgrade Guide](https://github.com/charmbracelet/bubbletea/blob/main/UPGRADE_GUIDE_V2.md)
- [Bubbles v2 Upgrade Guide](https://github.com/charmbracelet/bubbles/blob/main/UPGRADE_GUIDE_V2.md)
- [Tips for Building Bubble Tea Programs](https://leg100.github.io/en/posts/building-bubbletea-programs/)
- [Writing Bubble Tea Tests](https://carlosbecker.com/posts/teatest/)
- [The Bubbletea State Machine Pattern](https://zackproser.com/blog/bubbletea-state-machine)
