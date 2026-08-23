#!/usr/bin/env bash
# Two-root completion campaign (user go 2026-08-21 23:00: "solve the
# remaining 2 roots families with our latest machinery, 2 subkernels each").
# Families run SERIALLY, each as one main kernel + FACET_KERNEL_COUNT
# subkernels (the licence allows two main kernels on this machine and one
# is spared for Codex).  Per family: the standardized sector route
# (family_epsform_campaign.sh -> family_epsform_sector.wls), then the exact
# family certificate written into FamilyEpsFormsCertified/.
# Usage: tworoot_campaign.sh <output-root> <family> [family ...]
# Progress: Scripts/tworoot_status.sh <output-root>
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$1"; shift
families=("$@")
R="$root/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"
export FACET_KERNEL_COUNT="${FACET_KERNEL_COUNT:-2}"
export FACET_CPU_LIST="${FACET_CPU_LIST:-0,1,6,7}"
export FACET_RATIONAL_MAPLE_BUDGET="${FACET_RATIONAL_MAPLE_BUDGET:-300}"
mkdir -p "$out"
status="$out/campaign_status.tsv"
[[ -f "$status" ]] || printf 'family\tphase\tstarted\tfinished\tseconds\tresult\n' > "$status"
for family in "${families[@]}"; do
  if [[ -f "$R/FamilyEpsFormsCertified/family_epsform_$family.wl" ]]; then
    printf '%s\tcertified-existing\t-\t-\t0\tskip\n' "$family" >> "$status"; continue
  fi
  t0=$(date +%s)
  printf '%s\tsolving\t%s\t-\t-\t-\n' "$family" "$(date --iso-8601=seconds)" >> "$status"
  "$root/Scripts/family_epsform_campaign.sh" "$out" "$family" > "$out/${family}_campaign.log" 2>&1
  code=$?
  record="$out/$family/family_epsform_$family.wl"
  if (( code != 0 )) || [[ ! -f "$record" ]]; then
    printf '%s\tsolve-failed\t-\t%s\t%d\texit%d\n' "$family" "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" "$code" >> "$status"
    continue
  fi
  printf '%s\tcertifying\t-\t-\t%d\t-\n' "$family" "$(( $(date +%s) - t0 ))" >> "$status"
  "$root/FeynFacet/Tools/RunWithCPUList.sh" "$FACET_CPU_LIST" wolframscript -file \
    "$root/Scripts/certify_family_epsform_record.wls" "$record" \
    "$R/DifferentialEquations/nnlo_de_$family.wl" \
    "$R/FamilyEpsFormsCertified/family_epsform_$family.wl" > "$out/${family}_certify.log" 2>&1
  ccode=$?
  printf '%s\t%s\t-\t%s\t%d\t%s\n' "$family" "$([[ $ccode == 0 ]] && echo certified || echo certify-failed)" \
    "$(date --iso-8601=seconds)" "$(( $(date +%s) - t0 ))" "$(grep -o 'CERTIFY.*' "$out/${family}_certify.log" | tail -1 | cut -c1-120)" >> "$status"
done
printf 'ALL\tdone\t-\t%s\t-\t-\n' "$(date --iso-8601=seconds)" >> "$status"
