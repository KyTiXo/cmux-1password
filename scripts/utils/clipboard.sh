#!/usr/bin/env bash

# ------------------------------------------------------------------------------

clipboard::copy() {
  if [[ "$(uname)" == "Darwin" ]] && cmd::exists "pbcopy"; then
    echo -n "$1" | pbcopy
  elif [[ "$(uname)" == "Linux" ]] && cmd::exists "xsel"; then
    echo -n "$1" | xsel -b
  elif [[ "$(uname)" == "Linux" ]] && cmd::exists "xclip"; then
    echo -n "$1" | xclip -i
  else
    return 1
  fi
}

clipboard::clear() {
  local -r SEC="$1"

  if [[ "$(uname)" == "Darwin" ]] && cmd::exists "pbcopy"; then
    (
      sleep "$SEC"
      echo '' | pbcopy
    ) &> /dev/null &
  elif [[ "$(uname)" == "Linux" ]] && cmd::exists "xclip"; then
    (
      sleep "$SEC"
      echo '' | xclip -i
    ) &> /dev/null &
  else
    return 1
  fi
}
