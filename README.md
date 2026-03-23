# commit-toast

> Leave messages in commits that pop up when your teammates pull, merge, or rebase.

Embed a `<commit-toast>` block in any commit message. The next time a teammate runs `git pull`, `git merge`, or `git rebase`, the message is displayed in a framed box in their terminal — no extra apps, no Slack pings, no noise.

```
╔════════════════════════════════════════════════╗
║                                                ║
║  Run `npm install` — new deps were added!      ║
║                                                ║
╚════════════════════════════════════════════════╝
```

---

## Install

```bash
npx commit-toast
```

That's it. The installer adds `post-merge` and `post-rewrite` hooks to `.git/hooks/`.

### Husky (v9)

If your project uses [Husky](https://typicode.github.io/husky/), pass `--husky` to install into `.husky/` instead:

```bash
npx commit-toast --husky
```

### Options

| Flag | Description |
|------|-------------|
| `--husky` | Install into `.husky/` (Husky v9) |
| `--force` | Reinstall even if hooks are already present |
| `--help` | Show usage |

---

## Usage

Add a `<commit-toast>` block anywhere in a commit message:

```
fix: correct off-by-one in pagination

<commit-toast>
Heads up — run `npm install`, a new dep was added.
</commit-toast>
```

When a teammate pulls or merges that commit, they'll see the toast in their terminal automatically.

- Multiple `<commit-toast>` blocks in one message are all shown.
- Works with `git pull`, `git merge`, and `git rebase`.
- If a commit has no `<commit-toast>` block, nothing is shown — zero noise.

---

## How it works

`commit-toast-install` copies `commit-toast.sh` into your repo's git hooks directory and appends a call to it in `post-merge` and `post-rewrite` hooks. It is fully idempotent — running the installer twice won't duplicate hooks.

The hook script:
1. Collects the SHAs of newly-arrived commits (`ORIG_HEAD..HEAD` for merges, stdin for rebases).
2. Reads each commit message with `git log`.
3. Extracts and word-wraps any `<commit-toast>` blocks.
4. Renders them to stdout in a double-line Unicode frame.

No network calls. No dependencies beyond `bash` and `git`.

---

## Requirements

- `bash` 3.2+ (macOS default is fine)
- `git`
- Node.js ≥ 14 (only needed to run `npx commit-toast`)

---

## License

MIT
