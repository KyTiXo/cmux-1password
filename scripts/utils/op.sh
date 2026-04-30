#!/usr/bin/env bash

# ------------------------------------------------------------------------------

declare -r EXPECTED_MIN_OP_CLI_VERSION="2.0.0"
declare __OP_SESSION_FILE=""

# ------------------------------------------------------------------------------

op::session_file() {
  if [[ -z "$__OP_SESSION_FILE" ]]; then
    __OP_SESSION_FILE="$(mktemp "${TMPDIR:-/tmp}/cmux-1password.XXXXXX")"
    chmod 600 "$__OP_SESSION_FILE"
    trap 'rm -f "$__OP_SESSION_FILE"' EXIT
  fi

  echo "$__OP_SESSION_FILE"
}

op::verify_version() {
  local op_version="$(op --version)"

  semver::compare "$op_version" "$EXPECTED_MIN_OP_CLI_VERSION"

  if [[ $? -eq 2 ]]; then
    tmux::display_message \
      "1Password CLI version is not compatible with this plugin: ${op_version} < ${EXPECTED_MIN_OP_CLI_VERSION}"

    return 1
  fi

  return 0
}

op::verify_session() {
  local connected_accounts_count
  connected_accounts_count="$(
    op account list --format json 2> /dev/null \
      | jq 'length' 2> /dev/null
  )"
  connected_accounts_count="${connected_accounts_count:-0}"

  if [[ "$connected_accounts_count" -le 0 ]]; then
    tmux::set_1password_status "account setup"
    tmux::notify_1password "1Password" "Account setup required"
    prompt::ask "You haven't added any accounts to 1Password CLI. Would you like to add one now?"

    if prompt::answer_is_yes; then
      if ! op account add; then
        return 1
      fi

      tput clear
      tmux::clear_1password_status
      tmux::display_message "Successfully added new account."
    else
      return 1
    fi
  fi

  if ! op::signin; then
    return 1
  fi
}

op::signin() {
  local -r SESSION_FILE="$(op::session_file)"
  local exit_code

  tmux::set_1password_status "unlock required"
  tmux::set_1password_progress "0.5" "Waiting for 1Password"

  op signin \
    --cache \
    --force \
    --raw \
    --account="$(options::op_account)" \
    --session="$(op::get_session)" > "$SESSION_FILE"

  exit_code=$?

  tput clear

  if [[ "$exit_code" -eq 0 ]]; then
    tmux::clear_1password_status
    tmux::clear_1password_progress
  else
    tmux::set_1password_status "unlock failed"
    tmux::notify_1password "1Password" "Unlock failed or was cancelled"
  fi

  return $exit_code
}

op::get_session() {
  cat "$(op::session_file)" 2> /dev/null
}

op::get_all_items() {

  # Returned JSON structure reference:
  # https://developer.1password.com/docs/cli/item-template-json

  local -r JQ_FILTER="
    .[]
    | [
        select(
          (.category == \"LOGIN\") or
          (.category == \"PASSWORD\")
        )?
      ]
    | map(
        [ .title, .id ]
        | @tsv
      )
    | .[]
  "

  op item list \
    --cache \
    --format json \
    --categories="LOGIN,PASSWORD" \
    --tags="$(options::op_filter_tags)" \
    --vault="$(options::op_valut)" \
    --session="$(op::get_session)" \
    2> /dev/null \
    | jq "$JQ_FILTER" --raw-output
}

op::get_item_password() {
  local -r ITEM_UUID="$1"

  # Returned JSON structure reference:
  # https://developer.1password.com/docs/cli/item-template-json
  #
  # In case there are multiple items, we'll take the first one that matches our criteria.

  local -r JQ_FILTER="
      # For cases where we might get a single item - we always want to start with an array
      [.] + [] | flatten

      # Select the items whose purpose is... being a password
      | map(select(.purpose == \"PASSWORD\"))

      # Select the first one
      | .[0]

      # Return the value
      | .value
    "

  op item get "$ITEM_UUID" \
    --cache \
    --fields type=concealed \
    --format json \
    --session="$(op::get_session)" \
    | jq "$JQ_FILTER" --raw-output
}

op::get_item_totp() {
  local -r ITEM_UUID="$1"

  # In this case, the structure looks very similar to the password section, but the type of "OTP".

  local -r JQ_FILTER="
      # For cases where we might get a single item - we always want to start with an array
      [.] + [] | flatten

      # Select the first one
      | .[0]

      # Return the value
      | .totp
    "

  op item get "$ITEM_UUID" \
    --cache \
    --fields type=otp \
    --format json \
    --session="$(op::get_session)" \
    | jq "$JQ_FILTER" --raw-output
}
