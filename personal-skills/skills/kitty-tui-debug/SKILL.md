---
name: kitty-tui-debug
description: >-
  Use when visually verifying terminal UI rendering, testing TUI interactions,
  debugging Bubbletea display issues, or when asked to "test the TUI",
  "screenshot the terminal", "check what the TUI looks like", or "visually verify".
  Requires Kitty terminal with allow_remote_control and macOS for screencapture.
version: 1.0.0
allowed-tools: Bash(*/tui-debug.sh*), Bash(just:*), Bash(curl:*), Bash(sleep:*), Read, Glob, Grep
---

# Kitty TUI Debug

Visually verify TUI apps by launching them in a Kitty window, sending keystrokes, and taking PNG screenshots — all without leaving your terminal.

## Architecture

One shared Kitty OS window ("TUI Debug") with one tab per session. The user positions this window once and it persists. Multiple Claude sessions can run in parallel — each gets its own tab via `--session <name>`.

## Prerequisites

- **Kitty** with `allow_remote_control yes` and `listen_on unix:/tmp/kitty-{kitty_pid}` in kitty.conf
- **jq** for JSON parsing
- **macOS** for `screencapture -l` (window-specific PNG capture)

## Workflow

1. **Build**: Run the project's build command (e.g. `just build`)
2. **Launch**: `$SCRIPT --session $ID launch <command>` — creates a tab in the shared debug window
3. **Screenshot**: `$SCRIPT --session $ID screenshot` → then `Read /tmp/tui-debug-<session>.png` to view
4. **Interact**: `$SCRIPT --session $ID send-key enter` or `$SCRIPT --session $ID send-text "hello"`
5. **Screenshot again**: Capture after each meaningful interaction
6. **Close**: `$SCRIPT --session $ID close` when done (closes tab, OS window stays)

**Important**: Shell state does not persist between Bash tool calls. Set these at the start of every command:
```bash
SCRIPT="${CLAUDE_SKILL_DIR}/scripts/tui-debug.sh"
ID="my-session"  # pick a unique name for this session
```

Use distinct screenshot filenames to compare states (e.g. `/tmp/tui-initial.png`, `/tmp/tui-after-input.png`).

## Command Reference

| Command | Description | Example |
|---|---|---|
| `launch <cmd...>` | Start TUI in a new tab | `$SCRIPT --session $ID launch ./bin/app` |
| `screenshot [path]` | Capture PNG (default: `/tmp/tui-debug-<session>.png`) | `$SCRIPT --session $ID screenshot /tmp/after.png` |
| `text` | Dump visible terminal text (no image) | `$SCRIPT --session $ID text` |
| `send-key <keys...>` | Send key presses | `$SCRIPT --session $ID send-key ctrl+c` |
| `send-text <text>` | Type text into the TUI | `$SCRIPT --session $ID send-text "query"` |
| `focus` | Focus this session's tab | `$SCRIPT --session $ID focus` |
| `close` | Close tab (OS window stays) | `$SCRIPT --session $ID close` |
| `status` | Check if tab is alive | `$SCRIPT --session $ID status` |

## Key Names for send-key

Common keys: `enter`, `escape`, `tab`, `shift+tab`, `space`, `backspace`, `delete`

Arrow keys: `up`, `down`, `left`, `right`

Modifiers: `ctrl+c`, `ctrl+d`, `ctrl+l`, `ctrl+a`, `ctrl+e`, `ctrl+k`, `ctrl+u`

Function keys: `f1` through `f12`

## Timing

- The script includes built-in delays (1.5s after launch, 0.3s after key/text input)
- **Add extra `sleep`** before screenshots when the TUI is doing async work:
  - API calls: `sleep 2-5`
  - Search/filtering: `sleep 1-2`
  - File loading: `sleep 1`

## Troubleshooting

| Problem | Fix |
|---|---|
| "Kitty remote control not available" | Add `allow_remote_control yes` to kitty.conf and restart Kitty |
| "Could not find tab for session" | TUI may have crashed — run `launch` again and check for errors |
| Window exists but blank | TUI may need a server running — check if API is reachable |
| Screenshot shows wrong tab | The script auto-focuses before capture, but `sleep 0.2` may need increasing |
