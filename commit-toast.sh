#!/usr/bin/env bash
# commit-toast.sh — display <commit-toast> messages from new commits
# Usage: commit-toast.sh post-merge
#        commit-toast.sh post-rewrite   (reads "old-sha new-sha" lines from stdin)

set -euo pipefail

HOOK="${1:-}"

# ── collect new commit SHAs ────────────────────────────────────────────────

collect_shas() {
  local shas=()

  if [[ "$HOOK" == "post-merge" ]]; then
    # ORIG_HEAD is set by git before the merge
    if [[ -z "$(git rev-parse --verify ORIG_HEAD 2>/dev/null || true)" ]]; then
      return
    fi
    while IFS= read -r sha; do
      [[ -n "$sha" ]] && shas+=("$sha")
    done < <(git log --format="%H" ORIG_HEAD..HEAD 2>/dev/null || true)

  elif [[ "$HOOK" == "post-rewrite" ]]; then
    # stdin: "old-sha new-sha [extra]" one per line
    while IFS=" " read -r _old new _rest; do
      [[ -n "$new" ]] && shas+=("$new")
    done

  else
    echo "commit-toast: unknown hook type '$HOOK'" >&2
    exit 1
  fi

  printf '%s\n' "${shas[@]+"${shas[@]}"}"
}

# ── extract <commit-toast> blocks from a string ────────────────────────────

extract_toasts() {
  local msg="$1"
  local remaining="$msg"
  local found=0

  while true; do
    # Find opening tag
    local before_open="${remaining%%<commit-toast>*}"
    if [[ "$before_open" == "$remaining" ]]; then
      break  # no more opening tags
    fi
    local after_open="${remaining#*<commit-toast>}"

    # Find closing tag
    local body="${after_open%%</commit-toast>*}"
    if [[ "$body" == "$after_open" ]]; then
      break  # no closing tag — malformed, stop
    fi

    # Strip leading/trailing blank lines and whitespace from body
    local trimmed
    trimmed="$(printf '%s' "$body" | sed '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"

    if [[ -n "$trimmed" ]]; then
      render_toast "$trimmed"
      found=1
    fi

    # Advance past this closing tag
    remaining="${after_open#*</commit-toast>}"
  done
}

# ── render a single toast message in a double-line frame ──────────────────

render_toast() {
  local text="$1"

  local cols=50

  # inner_width = cols - 4  (2 border chars + 1 space padding each side)
  local inner=$((cols - 4))

  # Build border lines
  local bar
  bar="$(printf '═%.0s' $(seq 1 $((cols - 2))))"
  local top="╔${bar}╗"
  local bot="╚${bar}╝"
  local blank_inner
  blank_inner="$(printf ' %.0s' $(seq 1 $((cols - 2))))"
  local blank_line="║${blank_inner}║"

  printf '\n'
  printf '%s\n' "$top"
  printf '%s\n' "$blank_line"

  # Word-wrap text to inner width, then print each line padded
  while IFS= read -r line; do
    # pad/truncate line to exactly inner_width chars
    local padded
    padded="$(printf "%-${inner}s" "$line")"
    printf '║ %s ║\n' "$padded"
  done < <(printf '%s\n' "$text" | fold -s -w "$inner")

  printf '%s\n' "$blank_line"
  printf '%s\n' "$bot"
  printf '\n'
}

# ── main ───────────────────────────────────────────────────────────────────

main() {
  local shas=()
  while IFS= read -r sha; do
    [[ -n "$sha" ]] && shas+=("$sha")
  done < <(collect_shas)

  for sha in "${shas[@]+"${shas[@]}"}"; do
    local msg
    msg="$(git log -1 --format="%B" "$sha" 2>/dev/null || true)"
    [[ -n "$msg" ]] && extract_toasts "$msg"
  done
}

main
