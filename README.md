# claudeinstall

Install software on any Linux distro (or macOS) by **name or by description** — Claude Haiku
figures out what the package is called *on your machine*, you confirm, it installs.

```
$ claudeinstall htop                     # exact name in your repo -> installs, no AI call at all
$ claudeinstall "python dev headers"     # -> python (Arch) / python3-dev (Debian) / python3-devel (Fedora)
$ claudeinstall "command nvtop"          # -> the package that provides that command
$ claudeinstall "a light image viewer"   # -> a real package, with a one-line why + alternatives
```

```
:: asking Claude (cli/haiku) what 'python dev headers' is on Arch Linux …

  package  python  via pacman (Arch official repos)  [verified]
  why      Python development headers (Python.h, etc.) included in the main package
  command  sudo -A pacman -S --needed python

  note     Arch includes dev headers directly in python package, unlike Debian/Ubuntu.

Run it? [y/N]
```

## Why

Package names differ everywhere (`libssl-dev` / `openssl-devel` / `openssl`), and half the
time you know the *command* or *what it does* but not the package. An LLM is very good at
exactly that mapping — and only that. Everything else stays deterministic and local.

## How it works

1. Detects your distro (`/etc/os-release`) and which package managers exist:
   pacman, paru/yay (AUR), apt, dnf/yum, zypper, apk, xbps, emerge, nix, brew, pipx, cargo, npm, flatpak, snap.
2. If the query is an exact package name in a native repo → **no AI call**, straight to step 5.
3. Otherwise asks Claude Haiku for `{manager, packages, why, alternatives}` as JSON.
   The model **never returns shell commands** — only a manager + package names.
4. Verifies the package really exists with that manager (`pacman -Si`, `apt-cache show`, `dnf info`, …).
   If it doesn't, alternatives are tried; if nothing checks out, it refuses unless you pass `-y`.
5. Builds the install command itself from a fixed table, shows it, asks `y/N`, runs it
   (`sudo -A` when `SUDO_ASKPASS` is set, plain `sudo` otherwise, nothing when root).

Preference order given to the model: native repo → AUR helper → brew → pipx/cargo → flatpak → snap.
Flatpak/snap are last resort. `curl | bash` is never an option.

Answers are cached in `~/.cache/claudeinstall/` (keyed by distro + managers + query), so
repeating a query is free and instant.

## Install

```sh
git clone https://github.com/cjpsms/claudeinstall
cd claudeinstall && ./install.sh        # symlinks into ~/.local/bin
```

Needs Python ≥ 3.10 (stdlib only) and one of:

| backend | how | cost |
|---|---|---|
| `claude` CLI (default) | [Claude Code](https://claude.com/claude-code) logged in | your Claude subscription, ~1k tokens/query |
| Anthropic API | `export ANTHROPIC_API_KEY=…` + `pip install anthropic` | Haiku 4.5, fractions of a cent/query |

`--backend auto` (default) picks the API when `ANTHROPIC_API_KEY` is set, else the CLI.

## Usage

```
claudeinstall [-y] [-n] [--no-ai] [--no-cache] [--backend auto|cli|api] [--model M] [-v] <query…>

  -y, --yes       skip the y/N confirmation (also needed when stdin isn't a tty)
  -n, --dry-run   show the plan, install nothing
  --no-ai         exact local package names only, never call Claude
  --no-cache      bypass the answer cache
  --backend       cli (claude CLI) or api (Anthropic SDK)
  --model         override the model ('haiku' for cli, 'claude-haiku-4-5' for api)
  -v              show detected managers, token usage, cache path
```

Exit codes: `0` ok / dry run · `1` error · `2` package not found (refused) · `130` aborted.

## Safety model

- The LLM only ever produces *data* (manager + package names). The command is assembled
  from a hard-coded template per manager — nothing the model says is executed as shell.
- Every package is checked against the real package manager before you see the plan.
- You always confirm (unless `-y`). The package manager's own dependency prompt still shows.
- No network access except the one model call; no telemetry.

## License

MIT
