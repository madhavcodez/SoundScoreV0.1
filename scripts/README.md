# Scripts

## GitHub CLI (gh)

`gh` is installed under `.local/bin/` so it stays out of the repo (`.local/` is in `.gitignore`).

### Make gh available in your shell

```bash
# From repo root, one-time in this terminal:
export PATH="$PWD/.local/bin:$PATH"

# Or source the helper (from repo root):
source scripts/ensure-gh-path.sh
```

To have `gh` available in every new terminal from this project, add to your `~/.zshrc` (or equivalent):

```bash
export PATH="/Users/madhavschauhan/Desktop/SoundScorev0.1/.local/bin:$PATH"
```

### Authenticate

You must be logged in to close issues or use other GitHub API features:

```bash
gh auth login
```

Follow the prompts (browser or token). Alternatively set a token:

```bash
export GH_TOKEN=your_github_pat_or_token
```

### Close Phase 1A–tackled issues

After `gh` is on your PATH and you’re authenticated:

```bash
# From repo root
source scripts/ensure-gh-path.sh   # or export PATH="$PWD/.local/bin:$PATH"
./scripts/close-phase1a-issues.sh
```

This closes issues #53, #67, #68, #70, #71, #73, #74, #76, #77, #91, #92, #94, #95, #97, #98, #100, #103, #104, #106, #107 in `madhavcodez/SoundScoreV0.1` with a comment pointing to commit 59ff227.

### Phase 1B bootstrap + issue status

```bash
./scripts/bootstrap-phase1b.sh
./scripts/phase1b-open-issues.sh
```

- `bootstrap-phase1b.sh`: starts Postgres/Redis, installs npm dependencies, and runs backend migrations.
- `phase1b-open-issues.sh`: prints current open issues with milestone and labels.
