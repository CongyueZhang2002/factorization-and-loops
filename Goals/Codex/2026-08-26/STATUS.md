# Codex goal status — 2026-08-26

| # | Goal | Status | Current frontier | Next gate |
|---:|---|---|---|---|
| 01 | [Make the direct multiquadratic solver production-ready](01_multiquadratic_solver_correction.md) | [🟡] **In progress** | Generic regulator reconstruction and several correctness fixes landed; active-support certification, fresh-obstruction semantics, pre-cancellation bundles, provider promotion, and production hardening remain. | Finish A1–A3, then B1–B3 and measure the integrated solver. |
| 02 | [Integrate the rank-3 performance improvements](02_rank3_multiquadratic_optimization.md) | [🟡] **In progress** | Dlog batching, shared diagonal span, bundle hardening, and the installation prototype are implemented and validated in the designated Codex workspace, but not yet in the live package. | Port the accepted units conflict-aware and retain their measured benefit after integration. |
| 03 | [Reorganize `FeynFacet/Private`](03_private_source_restructure.md) | [ ] **Not started** | The current layout and target architecture are inventoried. | Establish the manifest after active solver interfaces and edits settle. |

The numbered order is fixed. Future status updates change only the colored mark
and explanatory text; they do not move goals around.
