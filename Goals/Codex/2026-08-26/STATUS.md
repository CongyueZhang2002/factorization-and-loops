# Codex goal status — 2026-08-26

| # | Goal | Status | Current frontier | Next gate |
|---:|---|---|---|---|
| 01 | [Make the direct multiquadratic solver production-ready](01_multiquadratic_solver_correction.md) | [🟡] **In progress** | A1–A3 and Round B are implemented; focused hardening and the installed-family chain are green. Copied-state CF300 `(12,9)` has passed its zero-defect support ladder and entered adaptive regulator reconstruction with the 8-thread CFFA4 follower available. | Obtain the typed CF300 result, run the final physical gate, then continue CF259/CF303 on the corrected native follower path. |
| 02 | [Integrate the rank-3 performance improvements](02_rank3_multiquadratic_optimization.md) | [🟡] **In progress** | Dlog batching, shared diagonal span, bundle hardening, and the installation prototype are implemented and validated in the designated Codex workspace, but not yet in the live package. | Port the accepted units conflict-aware and retain their measured benefit after integration. |
| 03 | [Reorganize `FeynFacet/Private`](03_private_source_restructure.md) | [ ] **Not started** | The current layout and target architecture are inventoried. | Establish the manifest after active solver interfaces and edits settle. |

The numbered order is fixed. Future status updates change only the colored mark
and explanatory text; they do not move goals around.
