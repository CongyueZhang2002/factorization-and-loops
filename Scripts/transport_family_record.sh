#!/usr/bin/env bash
# Requested-output iterated-integral coefficient operator for one family record:
# scripted form of the manual launch used for the triple-root stragglers.
# Runs Scripts/family_observable_transport.wls as one standalone main kernel
# under a hard allowance (setsid + kill of the process group), retries a
# licence refusal after a jittered 60-180 s pause, and leaves the log,
# the result and any diagnostic dump under the output directory.
#
# Usage: transport_family_record.sh <family> <epsilon-form-record.wl> <output-dir> [card.wl] [allowance-seconds=3600]
#   <epsilon-form-record.wl>  a certified family record, or a compact
#                             TransportReadyEpsilonConnection record that
#                             carries TransportEpsilonValuations
#   card.wl                   optional coefficient-operator settings
#                             (RegularBasePointAndFirstPathParameterScale,
#                             DiagnosticDirectory,
#                             IteratedIntegralCoefficientRepresentation, ...)
# Environment: CORES (cpu list, default 2-5,10-13), FACET_CHECK_LEVEL (default Production),
#              REPO (repository root, default: the directory above this script).
set -u
if (( $# < 3 )); then sed -n '2,16p' "$0"; exit 64; fi
family="$1"; record="$2"; out="$3"; card="${4:-}"; allowance="${5:-3600}"
repo="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
results="$repo/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"
de="$results/DifferentialEquations/nnlo_de_${family}.wl"
valuations="$results/MasterCoefficientValuations.wl"
for f in "$record" "$de" "$valuations"; do [[ -f "$f" ]] || { echo "missing input: $f" >&2; exit 66; }; done
[[ -n "$card" && ! -f "$card" ]] && { echo "missing card: $card" >&2; exit 66; }
mkdir -p "$out"
export FACET_CHECK_LEVEL="${FACET_CHECK_LEVEL:-Production}" FACET_KERNEL_COUNT=1
log="$out/transport.log"
for attempt in $(seq 1 20); do
  echo "=== attempt $attempt $(date -Is) family $family record $record card ${card:-none} allowance ${allowance}s" >> "$log"
  ( cd "$repo" && CORES="${CORES:-2,3,4,5,10,11,12,13}" "$repo/Scripts/run_with_allowance.sh" "$allowance" "$log" \
      Scripts/family_observable_transport.wls "$record" "$de" "$valuations" "$out/observable_transport_${family}.wl" ${card:+"$card"} )
  code=$?
  if tail -c 3000 "$log" | grep -a -q "not activated or is experiencing a license"; then
    echo "licence refusal; retrying after pause" >> "$log"; sleep $((60 + RANDOM % 120)); continue
  fi
  exit "$code"
done
echo "gave up after 20 licence refusals" >> "$log"; exit 75
