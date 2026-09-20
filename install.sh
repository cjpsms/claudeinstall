#!/usr/bin/env bash
# Installs `claudeinstall` into ~/.local/bin as a symlink to this checkout.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="${HOME}/.local/bin"

command -v python3 >/dev/null || { echo "python3 is required (>= 3.10)"; exit 1; }
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)' || { echo "python3 >= 3.10 required"; exit 1; }

if ! command -v claude >/dev/null && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "note: neither the 'claude' CLI nor ANTHROPIC_API_KEY was found."
  echo "      exact package names will still work (--no-ai), but descriptions need one of them:"
  echo "        claude CLI : https://claude.com/claude-code   (uses your Claude subscription)"
  echo "        API key    : export ANTHROPIC_API_KEY=...  and  pip install anthropic"
fi

mkdir -p "$bin"
ln -sf "$here/claudeinstall" "$bin/claudeinstall"
chmod +x "$here/claudeinstall"
echo "installed: $bin/claudeinstall -> $here/claudeinstall"
case ":$PATH:" in *":$bin:"*) ;; *) echo "add $bin to your PATH";; esac
