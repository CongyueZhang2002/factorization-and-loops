#!/usr/bin/env bash
set -euo pipefail

if (( $# < 1 )); then
  echo "Usage: pro_bridge.sh new|send|new-files|send-files|resend|status|wait|retrieve|cancel [PATH] [TIMEOUT_SECONDS]" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bridge="$(wslpath -w "${script_dir}/ProBridge.ps1")"
command="$1"
shift

case "$command" in
  new|send|new-files|send-files|retrieve)
    (( $# == 1 )) || { echo "$command requires one file path" >&2; exit 2; }
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$bridge" \
      -Command "$command" -Path "$(wslpath -w "$1")"
    ;;
  wait)
    (( $# >= 1 && $# <= 2 )) || { echo "wait requires an output path and optional timeout" >&2; exit 2; }
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$bridge" \
      -Command wait -Path "$(wslpath -w "$1")" -TimeoutSeconds "${2:-7200}"
    ;;
  resend|status|cancel)
    (( $# == 0 )) || { echo "$command does not take a path" >&2; exit 2; }
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$bridge" -Command "$command"
    ;;
  *)
    echo "Unknown command: $command" >&2
    exit 2
    ;;
esac
