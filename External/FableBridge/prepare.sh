#!/bin/bash
# prepare.sh <prompt.md> — stamp manifest for a FableBridge consult
set -e
P="$1"
[ -f "$P" ] || { echo "no such prompt: $P"; exit 1; }
D=$(dirname "$P"); B=$(basename "$P" .md)
sha=$(sha256sum "$P" | cut -d' ' -f1)
cat > "$D/$B.manifest.json" <<J
{"prompt": "$B.md", "sha256": "$sha",
 "preparedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
 "model": "claude-fable-5", "transport": "subagent|cli",
 "response": "../responses/${B}_response.md"}
J
echo "manifest written: $D/$B.manifest.json"
