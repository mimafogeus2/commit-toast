#!/usr/bin/env bash
# install-local.sh — install commit-toast git hooks into .git/hooks/
set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$BIN_DIR/.." && pwd)"

FORCE=0
for arg in "$@"; do
  [[ "$arg" == "--force" ]] && FORCE=1
done

# ── locate the git dir ─────────────────────────────────────────────────────

GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || true)"
if [[ -z "$GIT_DIR" ]]; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi
HOOKS_DIR="$(cd "$GIT_DIR" && pwd)/hooks"
mkdir -p "$HOOKS_DIR"

# ── copy commit-toast.sh into .git/hooks/ ─────────────────────────────────

cp "$PACKAGE_ROOT/commit-toast.sh" "$HOOKS_DIR/commit-toast.sh"
chmod +x "$HOOKS_DIR/commit-toast.sh"
echo "Installed: $HOOKS_DIR/commit-toast.sh"

# ── install a single hook file ─────────────────────────────────────────────

install_hook() {
  local hook_name="$1"   # e.g. post-merge
  local call_line="$2"   # the line(s) to append
  local hook_file="$HOOKS_DIR/$hook_name"

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
    # Create fresh hook
    printf '#!/usr/bin/env bash\n# commit-toast\n%s\n' "$call_line" > "$hook_file"
    echo "Created: $hook_file"
  fi

  chmod +x "$hook_file"
}

# post-merge: no stdin needed
install_hook "post-merge" \
  '"$(dirname "$0")/commit-toast.sh" post-merge'

# post-rewrite: pipe stdin through so commit-toast can read it
install_hook "post-rewrite" \
  'cat | "$(dirname "$0")/commit-toast.sh" post-rewrite'

echo "Done. commit-toast hooks installed in $HOOKS_DIR"
