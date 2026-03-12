#!/usr/bin/env bash
# Close GitHub issues tackled by Phase 1A foundation (commit 59ff227).
# Requires: gh auth login (or GH_TOKEN set) and gh on PATH (run: source scripts/ensure-gh-path.sh).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export PATH="$REPO_ROOT/.local/bin:$PATH"
REPO="madhavcodez/SoundScoreV0.1"
COMMENT="Closed by Phase 1A foundation. Commit: 59ff227 (UI_beta). See commit message for full change summary."

# Issues tackled (contract/API alignment, core path, mobile foundation, CI)
ISSUES=(53 67 68 70 71 73 74 76 77 91 92 94 95 97 98 100 103 104 106 107)

echo "Closing ${#ISSUES[@]} issues in $REPO (comment: $COMMENT)"
for n in "${ISSUES[@]}"; do
  if gh issue view "$n" --repo "$REPO" --json state -q .state 2>/dev/null | grep -qi open; then
    gh issue close "$n" --repo "$REPO" --comment "$COMMENT" && echo "Closed #$n" || echo "Failed #$n"
  else
    echo "Skip #$n (not open)"
  fi
done
echo "Done."
