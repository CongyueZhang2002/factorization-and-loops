#!/usr/bin/env bash
set -euo pipefail

project_root="${1:-/home/maxzhang/factorization-and-loops}"
mode="${2:-until-rank3}"
output_root="${3:-${project_root}/External/CodexExchange/triple_root_2026-08-22/cf300_dynamic}"
worker_script="${CODEX_TRIPLE_ROOT_WORKER:-Scripts/family_epsform_sector.wls}"

mapfile -t live_kernels < <(pgrep -x WolframKernel || true)
if (( ${#live_kernels[@]} >= 2 )); then
  echo "CF300_CAPTURE BUSY wolfram_kernels=${#live_kernels[@]} (nothing launched)"
  exit 73
fi

available_kib=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
if (( available_kib < 10485760 )); then
  echo "CF300_CAPTURE BUSY available_kib=${available_kib} (need at least 10 GiB; nothing launched)"
  exit 74
fi

cpu_list="${CODEX_TRIPLE_ROOT_CPUS:-0-4}"
if (( ${#live_kernels[@]} == 1 )); then
  affinity=$(taskset -pc "${live_kernels[0]}" 2>/dev/null || true)
  if [[ "$affinity" == *"0-9"* || "$affinity" == *"0-4"* ]]; then
    cpu_list="${CODEX_TRIPLE_ROOT_CPUS:-10-14}"
  fi
fi

mkdir -p "$output_root"
export FACET_KERNEL_COUNT=4
export FACET_CHECK_LEVEL=Production
export FACET_STRIP_ROUTE=FiniteFieldFirst
if [[ "$mode" == "first-strip" ]]; then
  export FACET_RECORD_STRIP_ONLY=True
else
  unset FACET_RECORD_STRIP_ONLY || true
fi

echo "CF300_CAPTURE START mode=${mode} cpus=${cpu_list} output=${output_root} worker=${worker_script}"
cd "$project_root"
exec taskset -c "$cpu_list" wolframscript -file "$worker_script" \
  CF300 "$output_root" 300 codex_triple_root 0
