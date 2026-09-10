# Code cleanup and regenerated NLO workflows

The source audit covered all 171 manifest modules and calls from active drivers
and tests. Single-reference symbols used by external drivers (including AMFlow
runtime/cache entry points and package loaders) were retained.

Removed or consolidated:
- Deleted 142,319,587 bytes in 2,265 old NLO generated files.
- Retired old NLO replay tests that needed those outputs; active tests no longer
  refer to the deleted result directories.
- Removed the duplicate Born-card factory and three unused private helpers.
- Removed the version-8 master-coefficient reader branch. Reconstruction now
  writes the current table format at its production boundary.
- Consolidated physical distribution construction, scalar collection and NLO
  contribution summation. Removed stored virtual master copies and counterterm
  convolution intermediates from final contribution records.
- Separated generic result storage from Born physics, collinear convolution
  and NNLO endpoint finalization.
- Made physical-leg polarization one shared declaration for projectors,
  distribution functions, channel dependencies and subtraction kernels.
- Retained unknown tails of all-zero finite reconstructed epsilon prefixes.
- Removed eager expansion from exact rational zero testing. Dimensional shifts
  prune only structural zeros, retaining all other terms until aggregation.
- Large generated records use lossless compression above 8 MiB; they remain
  directly readable by Get. Small final physical results stay readable text.

Measured hard case: TT spin-transfer real interference {4,5}, with arbitrary
azimuths retained. The original zero tests did not finish after more than
13 minutes; structural pruning completed it in 34.52 seconds. A separate TT
interference agrees exactly with its earlier result. A bounded exact-pruning
experiment took 40.51 seconds and retained the same terms, so it was not chosen.
The extra retained terms are exact expressions, not estimates or zero guesses.

No claim is made that every supported mathematical algorithm is globally
optimal. Optional epsilon-form methods, exact finite DE construction, AMFlow,
and numerical backends solve distinct supported problems and remain active.

The virtual order planner and analytic contraction now use the proven
meromorphic Laurent lower bound for sums of analytic prefactors. An exact
valuation is still required for reciprocal denominators. This avoids rejecting
a supported analytic sum and preserves the unknown-tail order checks.

Both compressed and plain records qualify stored symbols, including
Global regulators and System names shadowed by imported packages. This fixes the
otherwise context-dependent meaning of a subsequent Get or guarded read.
The final campaign regenerates the contributions with this writer and checks
exact equality with the previously validated complete hard functions.

Five distinct physical results cover the requested cases: UU is shared between
the two arrangements; LL and TT have separate incoming-correlation and
incoming-A-to-observed-quark spin-transfer projects. The five finite hard
functions occupy 42,461 bytes in total. All are explicit delta, plus and regular
coefficients with no remaining integrals.

Current machine-readable measurements are in
[the process validation directory](../ppHX_UU_NNLO/NLO/qqp-qqp/Results/Validation/).
The [completed cleanup report](../ppHX_UU_NNLO/NLO/qqp-qqp/Results/Validation/CodeCleanupReport.json) records all runs and checks.

Local workers now start in batches of two. This removes the observed lost
WSTP connection when many local workers start simultaneously. All eight workers
connect and execute; new workers can be closed without disturbing an existing
caller pool. The complete incoming-TT run fell from 42.60 to 27.90 seconds.
TT virtual coefficient preparation with all eight workers takes 59.24 seconds,
and its complete coefficients are exactly identical to the prior result.
The standalone numerical reader retains its separate minimal runtime.

| Polarization | Full NLO result | Bytes |
|---|---|---:|
| UU | [Result.wl](../ppHX_UU_NNLO/NLO/qqp-qqp/Results/Result.wl) | 11,203 |
| Both incoming LL | [Result.wl](../ppHX_LL_NLO/NLO/qqp-qqp/Results/Result.wl) | 8,362 |
| Both incoming TT | [Result.wl](../ppHX_TT_NLO/NLO/qqp-qqp/Results/Result.wl) | 1,522 |
| LL, incoming A to observed quark | [Result.wl](../ppHX_LL_SpinTransfer_NLO/NLO/qqp-qqp/Results/Result.wl) | 11,215 |
| TT, incoming A to observed quark | [Result.wl](../ppHX_TT_SpinTransfer_NLO/NLO/qqp-qqp/Results/Result.wl) | 10,159 |

Each result includes real emission, virtual interference, PDF/FF subtraction
and UV renormalization. LO dependencies are generated through epsilon one.
UU is common to both polarization arrangements. The incoming-TT zero is
established by all generated interferences, not inferred from a channel label.

Verification passed 244 unit assertions, 53 reference-driver checks (49 external
comparisons and four TT coverage/control checks), and 88 spin-transfer/scale checks. The external comparisons are UU against INCNLO and
LL against Vogelsang's coefficients; the TT spin-transfer checks constrain
helicity structure, Born limits, soft emission and scale dependence, but do not
constitute an independent complete finite TT reference.

Regenerate any project through the same driver:
```sh
wolframscript -file Scripts/run_nlo_hard_function.wls ppHX_TT_SpinTransfer_NLO qqp-qqp all
```

The result fields are `result["Coefficients"][0]["DeltaCoefficient"]`,
`result["Coefficients"][0]["PlusCoefficients"]` and
`result["Coefficients"][0]["RegularCoefficient"]`. All five projects use the
same schema and the same production code.

All 324 regenerated amplitude and canonical-pair records also passed exact
read-back checks through both ordinary Get and the guarded reader, including
symbolic contexts. Reserialization preserved their evaluated data exactly.
