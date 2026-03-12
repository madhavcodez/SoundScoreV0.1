#!/usr/bin/env bash
# Source this to get Node (project-local) and Java (Android Studio JBR) on PATH.
# Usage: source scripts/run-env.sh   OR   . scripts/run-env.sh
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$REPO_ROOT/.local/node/bin:$PATH"
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"
echo "Node: $(node -v 2>/dev/null || echo 'not found')"
echo "Java: $(java -version 2>&1 | head -1 || echo 'not found')"
