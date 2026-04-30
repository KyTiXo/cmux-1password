# cmux-1password

> summon secrets. stay frosty.

Shell-first 1Password picker for `tmux`, tuned to behave better inside `cmux`.

It keeps the raw `.sh` shape from [`tmux-1password`](https://github.com/yardnsm/tmux-1password), but if it detects `CMUX_WORKSPACE_ID` and `CMUX_SURFACE_ID` it will:

- send the selected secret back through the active `cmux` surface
- set a sidebar status pill / progress hint when 1Password needs attention
- fire a `cmux notify` when unlock/sign-in gets blocked

No Electron blob. No framework sermon. Just shell, `fzf`, `op`, and a keybind.

## What It Does

- `prefix + u` opens the picker
- `Enter` sends the password
- `Ctrl+u` sends the OTP/TOTP
- optional clipboard mode still works
- tmux path stays intact

## Requirements

- [`op`](https://developer.1password.com/docs/cli)
- [`jq`](https://jqlang.org/)
- [`fzf`](https://github.com/junegunn/fzf)
- [`tmux`](https://github.com/tmux/tmux) for the plugin bind path
- [`cmux`](https://github.com/manaflow-ai/cmux) if you want the extra workspace-aware behavior

## Install

### TPM

```tmux
set -g @plugin 'KyTiXo/cmux-1password'
```

Reload TPM. Hit `prefix + I`. Carry on.

### Manual

```bash
git clone https://github.com/KyTiXo/cmux-1password ~/.config/cmux-1password
```

```tmux
run-shell ~/.config/cmux-1password/plugin.tmux
```

Then:

```bash
tmux source-file ~/.tmux.conf
```

## Config

```tmux
set -g @1password-key 'u'
set -g @1password-account 'my'
set -g @1password-vault ''
set -g @1password-filter-tags ''
set -g @1password-copy-to-clipboard 'off'
set -g @1password-debug 'off'
```

## cmux Notes

Inside a real `cmux` terminal, this repo treats:

- `CMUX_WORKSPACE_ID` as the workspace boolean
- `CMUX_SURFACE_ID` as the secret send target
- `cmux set-status` / `cmux set-progress` as the "hey idiot unlock 1Password" workspace flag

If 1Password blocks on sign-in or biometric unlock, the workspace can light up without leaking the secret itself.

## Smoke Test

Run this inside a `cmux` terminal:

```bash
./smoke-test.sh
```

What it does:

- pings `cmux`
- prints `identify` / current workspace state
- creates a new left split
- renames the tab to `1Password Smoke`
- sets a status pill + progress bar
- sends a harmless notification
- dumps pane / surface / sidebar state so you can inspect the graph

Cleanup mode:

```bash
./smoke-test.sh --cleanup
```

## Security

- no secret text is written to README-land logs
- selected item lookup uses item IDs, not title-grep roulette
- session token cache uses a private temp file, not a fixed world-readable path

## Demo

Drop in a screenshot or clip later. Repo is staged for it.

## Prior Art

- [`yardnsm/tmux-1password`](https://github.com/yardnsm/tmux-1password)
- [`manaflow-ai/cmux`](https://github.com/manaflow-ai/cmux)

## License

MIT
