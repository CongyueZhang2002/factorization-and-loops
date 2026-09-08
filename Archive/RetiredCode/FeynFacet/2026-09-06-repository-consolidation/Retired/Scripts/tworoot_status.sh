#!/usr/bin/env bash
# Progress + estimate of the two-root completion campaign.
# Usage: tworoot_status.sh [output-root]
python3 "$(dirname "${BASH_SOURCE[0]}")/tworoot_status.py" "${1:-$(dirname "${BASH_SOURCE[0]}")/../ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/tworoot}"
