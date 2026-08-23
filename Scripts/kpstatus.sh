#!/usr/bin/env bash
POOL="${POOL:-/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/kernelpool}"
cat "$POOL/status.txt" 2>/dev/null || echo "no status (pool not running?)"
