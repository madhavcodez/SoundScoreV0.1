#!/usr/bin/env bash
# Add project .local/bin to PATH so gh is available. Source this or run: source scripts/ensure-gh-path.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export PATH="$REPO_ROOT/.local/bin:$PATH"
