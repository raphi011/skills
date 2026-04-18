#!/usr/bin/env bash
#
# tui-debug.sh — Launch, interact with, and screenshot TUI apps via Kitty remote control.
#
# Architecture:
#   - One shared Kitty OS window ("TUI Debug") persists across all sessions
#   - Each Claude session gets its own tab via --session <name>
#   - Multiple parallel sessions coexist (each with own tab + state file)
#   - The OS window can be positioned once and stays put
#
# State: /tmp/tui-debug-<session> per session
# Subcommands: launch, screenshot, text, send-key, send-text, close, status, focus
#
# Requires: kitty (with allow_remote_control), jq, macOS screencapture

set -euo pipefail

OS_WINDOW_TITLE="TUI Debug"
SESSION="default"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' NC=''
fi

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
info() { echo -e "${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }

# Parse --session flag from anywhere in args
parse_session() {
  local args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session)
        SESSION="${2:?--session requires a name}"
        shift 2
        ;;
      --session=*)
        SESSION="${1#--session=}"
        shift
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done
  REMAINING_ARGS=("${args[@]}")
}

state_file() { echo "/tmp/tui-debug-${SESSION}"; }
tab_title() { echo "TUI: ${SESSION}"; }
default_screenshot() { echo "/tmp/tui-debug-${SESSION}.png"; }

# Load state file (sets KITTY_WIN_ID and PLATFORM_WIN_ID)
load_state() {
  local sf
  sf=$(state_file)
  [ -f "$sf" ] || die "No active session '$SESSION'. Run 'launch' first."
  # shellcheck source=/dev/null
  source "$sf"
  [ -n "${KITTY_WIN_ID:-}" ] || die "State file missing KITTY_WIN_ID"
  [ -n "${PLATFORM_WIN_ID:-}" ] || die "State file missing PLATFORM_WIN_ID"
}

# Check kitty remote control is available
check_kitty() {
  kitty @ ls >/dev/null 2>&1 || die "Kitty remote control not available. Ensure:
  1. You're running inside Kitty terminal
  2. kitty.conf has: allow_remote_control yes
  3. kitty.conf has: listen_on unix:/tmp/kitty-{kitty_pid}"
}

# Find the shared OS window's platform_window_id, or empty if it doesn't exist
find_os_window() {
  local ls_json
  ls_json=$(kitty @ ls 2>/dev/null) || die "Failed to run 'kitty @ ls'"
  echo "$ls_json" | jq -r \
    "[.[] | select(.tabs[].windows[].title == \"$OS_WINDOW_TITLE\" or .tabs[].title == \"$OS_WINDOW_TITLE\")][0].platform_window_id // empty" 2>/dev/null
}

# Find the kitty window ID for this session's tab
find_session_tab() {
  local title ls_json
  title=$(tab_title)
  ls_json=$(kitty @ ls 2>/dev/null) || return 1
  echo "$ls_json" | jq -r \
    "[.[].tabs[].windows[] | select(.title == \"$title\")][0].id // empty" 2>/dev/null
}

# Get platform_window_id for the OS window containing our session tab
find_platform_id() {
  local title ls_json
  title=$(tab_title)
  ls_json=$(kitty @ ls 2>/dev/null) || return 1
  echo "$ls_json" | jq -r \
    "[.[] | select(.tabs[].windows[].title == \"$title\")][0].platform_window_id // empty" 2>/dev/null
}

cmd_launch() {
  [ ${#REMAINING_ARGS[@]} -ge 1 ] || die "Usage: tui-debug.sh [--session NAME] launch <command...>"

  check_kitty

  # Close existing session tab if any
  local sf
  sf=$(state_file)
  if [ -f "$sf" ]; then
    warn "Closing existing session '$SESSION'..."
    cmd_close 2>/dev/null || true
  fi

  local title
  title=$(tab_title)
  info "Launching session '$SESSION': ${REMAINING_ARGS[*]}"

  # Check if shared OS window exists
  local os_window_exists
  os_window_exists=$(find_os_window)

  if [ -n "$os_window_exists" ]; then
    # OS window exists — add a new tab to it
    # Find any window in the OS window to use as --match target
    local any_win_id
    any_win_id=$(kitty @ ls 2>/dev/null | jq -r \
      "[.[] | select(.platform_window_id == $os_window_exists)][0].tabs[0].windows[0].id // empty" 2>/dev/null)

    if [ -n "$any_win_id" ]; then
      kitty @ launch --type=tab --match "id:$any_win_id" --keep-focus --hold \
        --tab-title="$title" --title="$title" -- "${REMAINING_ARGS[@]}" \
        >/dev/null 2>&1 || die "Failed to create tab in existing window"
    else
      die "OS window exists but has no windows to match against"
    fi
  else
    # No OS window yet — create one with this tab
    kitty @ launch --type=os-window --keep-focus --hold \
      --os-window-title="$OS_WINDOW_TITLE" --tab-title="$title" --title="$title" \
      -- "${REMAINING_ARGS[@]}" \
      >/dev/null 2>&1 || die "Failed to launch kitty window"
  fi

  # Wait for window/tab to register
  sleep 0.5

  # Extract IDs (retry once if first attempt fails)
  local kitty_win_id platform_win_id
  kitty_win_id=$(find_session_tab)
  platform_win_id=$(find_platform_id)

  if [ -z "$kitty_win_id" ] || [ -z "$platform_win_id" ]; then
    sleep 1
    kitty_win_id=$(find_session_tab)
    platform_win_id=$(find_platform_id)
  fi

  [ -n "$kitty_win_id" ] || die "Could not find tab for session '$SESSION'"
  [ -n "$platform_win_id" ] || die "Could not find platform_window_id for session '$SESSION'"

  KITTY_WIN_ID="$kitty_win_id"
  PLATFORM_WIN_ID="$platform_win_id"

  # Save state
  cat > "$sf" <<EOF
KITTY_WIN_ID=$KITTY_WIN_ID
PLATFORM_WIN_ID=$PLATFORM_WIN_ID
EOF

  # Wait for TUI to initialize (alt screen, first render)
  sleep 1

  info "Session '$SESSION' started"
  info "  Tab: $title"
  info "  Kitty window ID: $KITTY_WIN_ID"
  info "  Platform window ID: $PLATFORM_WIN_ID"
  info "  State: $sf"
}

cmd_screenshot() {
  load_state

  # Focus our tab first so it's visible in the OS window
  kitty @ focus-window --match "id:$KITTY_WIN_ID" --no-response 2>/dev/null || true
  sleep 0.2

  local output="${REMAINING_ARGS[0]:-$(default_screenshot)}"

  # -o suppresses window shadow for cleaner captures
  screencapture -l "$PLATFORM_WIN_ID" -o "$output" 2>/dev/null \
    || die "screencapture failed. Is the window still open? (check: tui-debug.sh status)"

  info "Screenshot saved: $output"
}

cmd_text() {
  load_state
  kitty @ get-text --match "id:$KITTY_WIN_ID" --extent=screen 2>/dev/null \
    || die "Failed to get text. Is the window still open?"
}

cmd_send_key() {
  [ ${#REMAINING_ARGS[@]} -ge 1 ] || die "Usage: tui-debug.sh [--session NAME] send-key <key...>
Examples: send-key enter, send-key ctrl+c, send-key tab, send-key up"
  load_state
  kitty @ send-key --match "id:$KITTY_WIN_ID" "${REMAINING_ARGS[@]}" 2>/dev/null \
    || die "Failed to send key. Is the window still open?"
  sleep 0.3
}

cmd_send_text() {
  [ ${#REMAINING_ARGS[@]} -ge 1 ] || die "Usage: tui-debug.sh [--session NAME] send-text <text>"
  load_state
  kitty @ send-text --match "id:$KITTY_WIN_ID" -- "${REMAINING_ARGS[*]}" 2>/dev/null \
    || die "Failed to send text. Is the window still open?"
  sleep 0.3
}

cmd_focus() {
  load_state
  kitty @ focus-window --match "id:$KITTY_WIN_ID" 2>/dev/null \
    || die "Failed to focus window. Is the session still open?"
  info "Focused session '$SESSION'"
}

cmd_close() {
  load_state
  # Close just this session's tab/window, not the whole OS window
  kitty @ close-window --match "id:$KITTY_WIN_ID" 2>/dev/null || true
  rm -f "$(state_file)"
  info "Session '$SESSION' closed"
}

cmd_status() {
  local sf
  sf=$(state_file)
  if [ ! -f "$sf" ]; then
    echo "No active session '$SESSION'"
    exit 1
  fi
  load_state

  if kitty @ ls --match "id:$KITTY_WIN_ID" 2>/dev/null | jq -e '.[].tabs[].windows[]' >/dev/null 2>&1; then
    info "Session '$SESSION' alive (kitty window $KITTY_WIN_ID)"
  else
    warn "Session '$SESSION' stale — window no longer exists"
    rm -f "$sf"
    exit 1
  fi
}

cmd_help() {
  cat <<'HELP'
tui-debug.sh — Visual TUI debugging via Kitty remote control

ARCHITECTURE:
  One shared Kitty OS window ("TUI Debug") with one tab per session.
  Position the window once — it persists across sessions.

OPTIONS:
  --session NAME    Session name (default: "default"). Each session gets its own tab.

SUBCOMMANDS:
  launch <cmd...>      Launch command in a new tab
  screenshot [file]    Capture PNG (default: /tmp/tui-debug-<session>.png)
  text                 Dump terminal text content
  send-key <keys...>   Send key presses (e.g. enter, ctrl+c, tab, up)
  send-text <text>     Send text input
  focus                Focus this session's tab
  close                Close this session's tab (OS window stays)
  status               Check if session's tab is alive

EXAMPLES:
  # Single session
  tui-debug.sh launch ./bin/know agent
  tui-debug.sh send-text "hello world"
  tui-debug.sh screenshot

  # Parallel sessions
  tui-debug.sh --session agent launch ./bin/know agent
  tui-debug.sh --session browse launch ./bin/know browse
  tui-debug.sh --session agent send-key enter
  tui-debug.sh --session browse screenshot
HELP
}

# Parse --session from all args first
parse_session "$@"

# Route subcommand (from REMAINING_ARGS after --session extraction)
SUBCMD="${REMAINING_ARGS[0]:-help}"
REMAINING_ARGS=("${REMAINING_ARGS[@]:1}")

case "$SUBCMD" in
  launch)     cmd_launch ;;
  screenshot) cmd_screenshot ;;
  text)       cmd_text ;;
  send-key)   cmd_send_key ;;
  send-text)  cmd_send_text ;;
  focus)      cmd_focus ;;
  close)      cmd_close ;;
  status)     cmd_status ;;
  help|--help|-h) cmd_help ;;
  *) die "Unknown subcommand: $SUBCMD. Run 'tui-debug.sh help' for usage." ;;
esac
