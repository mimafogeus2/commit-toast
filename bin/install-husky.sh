#!/usr/bin/env bash
# install-husky.sh — install commit-toast hooks into .husky/ (Husky v9)
set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$BIN_DIR/.." && pwd)"

FORCE=0
for arg in "$@"; do
  [[ "$arg" == "--force" ]] && FORCE=1
done

# ── locate repo root (where .husky/ should live) ──────────────────────────

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

HUSKY_DIR="$REPO_ROOT/.husky"
mkdir -p "$HUSKY_DIR"

# ── copy commit-toast.sh to repo root ─────────────────────────────────────

DEST="$REPO_ROOT/commit-toast.sh"
cp "$PACKAGE_ROOT/lib/commit-toast.sh" "$DEST"
chmod +x "$DEST"
echo "Installed: $DEST"

# ── install a single husky hook file ──────────────────────────────────────

install_hook() {
  local hook_name="$1"
  local call_line="$2"
  local hook_file="$HUSKY_DIR/$hook_name"

  if [[ -f "$hook_file" ]]; then
    # Idempotency check
    if grep -q '# commit-toast' "$hook_file" 2>/dev/null; then
      if [[ $FORCE -eq 0 ]]; then
        echo "Skipped $hook_name (commit-toast already present, use --force to reinstall)"
        return
      fi
      # Remove existing commit-toast block: the marker comment and the line after it
      local tmp; tmp="$(mktemp)"
      sed '/^# commit-toast$/{N;d;}' "$hook_file" > "$tmp"
      # Also drop any blank line immediately preceding the marker
      sed -i.bak -e '/^$/{ N; /^\n# commit-toast/d; }' "$tmp" && rm -f "$tmp.bak"
      mv "$tmp" "$hook_file"
      chmod +x "$hook_file"
    fi
    # Append to existing hook
    printf '\n# commit-toast\n%s\n' "$call_line" >> "$hook_file"
    echo "Reinstalled: $hook_file"
  else
    # Create fresh Husky v9 hook (plain shell script, no special header needed)
    printf '#!/usr/bin/env bash\n# commit-toast\n%s\n' "$call_line" > "$hook_file"
    echo "Created: $hook_file"
  fi

  chmod +x "$hook_file"
}

# Husky v9 hooks run from the repo root, so reference commit-toast.sh relative to it.
install_hook "post-merge" \
  '"$(git rev-parse --show-toplevel)/commit-toast.sh" post-merge'

install_hook "post-rewrite" \
  'cat | "$(git rev-parse --show-toplevel)/commit-toast.sh" post-rewrite'

echo "Done. commit-toast hooks installed in $HUSKY_DIR"
