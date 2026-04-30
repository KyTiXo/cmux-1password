#!/usr/bin/env bash

# ------------------------------------------------------------------------------

declare -r CMUX_STATUS_KEY="onepassword"

# ------------------------------------------------------------------------------

tmux::is_cmux() {
  [[ -n "${CMUX_WORKSPACE_ID:-}" ]] \
    && [[ -n "${CMUX_SURFACE_ID:-}" ]] \
    && cmd::exists "cmux"
}

tmux::get_option() {
  local option=$1
  local default_value=$2
  local option_value; option_value=$(tmux show-option -gqv "$option")

  if [[ -z "$option_value" ]]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

tmux::display_message() {
  if tmux::is_cmux; then
    cmux display-message "cmux-1password: $1" &> /dev/null && return 0
  fi

  tmux display-message "cmux-1password: $1"
}

tmux::disable_synchronize_panes() {
  if tmux::is_cmux; then
    echo "off"
    return 0
  fi

  if [ "$(tmux show-options -wv synchronize-panes)" == "on" ]; then
    tmux::set_synchronize_panes "off"
    echo "on"
  else
    echo "off"
  fi
}

tmux::set_synchronize_panes() {
  if tmux::is_cmux; then
    return 0
  fi

  tmux set-window-option synchronize-panes "${1}"
}

tmux::target_id() {
  if tmux::is_cmux; then
    echo "${CMUX_SURFACE_ID}"
  else
    echo "$1"
  fi
}

tmux::send_secret() {
  local -r TARGET="$1"
  local -r SECRET="$2"

  if tmux::is_cmux; then
    cmux send-surface --surface "$TARGET" "$SECRET" &> /dev/null
  else
    tmux send-keys -t "$TARGET" "$SECRET"
  fi
}

tmux::set_1password_status() {
  local -r VALUE="$1"

  tmux::is_cmux || return 0

  cmux set-status "$CMUX_STATUS_KEY" "$VALUE" --icon lock --color "#ff9500" &> /dev/null
}

tmux::clear_1password_status() {
  tmux::is_cmux || return 0

  cmux clear-status "$CMUX_STATUS_KEY" &> /dev/null
}

tmux::set_1password_progress() {
  local -r VALUE="$1"
  local -r LABEL="$2"

  tmux::is_cmux || return 0

  cmux set-progress "$VALUE" --label "$LABEL" &> /dev/null
}

tmux::clear_1password_progress() {
  tmux::is_cmux || return 0

  cmux clear-progress &> /dev/null
}

tmux::notify_1password() {
  local -r TITLE="$1"
  local -r BODY="$2"

  tmux::is_cmux || return 0

  cmux notify --title "$TITLE" --body "$BODY" &> /dev/null
}
