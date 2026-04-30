#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

files=()

while IFS= read -r file; do
  files+=("$file")
done < <(rg --files .. -g '*.sh' -g '*.tmux')

shellcheck "${files[@]}"
