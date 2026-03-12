#!/usr/bin/env bash
set -euo pipefail

REPO="madhavcodez/SoundScoreV0.1"
TOKEN="${GH_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -f "ghpat.txt" ]; then
  TOKEN="$(tr -d '\r\n' < ghpat.txt)"
fi
if [ -z "$TOKEN" ] && [ -f "gh.pat" ]; then
  TOKEN="$(tr -d '\r\n' < gh.pat)"
fi

if [ -z "$TOKEN" ]; then
  echo "Missing GH_TOKEN (or ghpat.txt/gh.pat)."
  exit 1
fi

curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/issues?state=open&per_page=100" \
  | jq -r '.[] | select(.pull_request|not) | "#\(.number)\t\(.title)\t\(.milestone.title // "NoMilestone")\t\(.labels|map(.name)|join(","))"'
