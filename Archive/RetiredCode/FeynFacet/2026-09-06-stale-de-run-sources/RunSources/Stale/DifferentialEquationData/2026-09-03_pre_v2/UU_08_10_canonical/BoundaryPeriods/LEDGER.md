# Boundary-period ledger — UU_08_10_canonical

Strict status table for the 20 candidate boundary periods of the stage-3
census. Superseding the pilot's `SOLVED` / `UNRESOLVED` labels, which did
not distinguish an exact identity from a numeric branch check.

Date: 2026-08-15. Deliverable of the stage-3 rework mandated by
`Exchange/Codex/2026-08-15/02_assessment_of_fable_round6.md`.

## Taxonomy

Adopted from Codex's section 2 classification, applied to periods:

| status | meaning |
|---|---|
| **Exact** | every link in the proof chain is an exact symbolic identity. Numerics appear only as independent checks. |
| **AnalyticCandidate** | an analytic argument exists but at least one link is a finite series, a finite set of numeric samples, or an unverified hand step. The missing link must be named. |
| **NotEvaluated** | no evaluation attempted. Structural data (strata, exponents, couplings) may still be recorded. |
| **Rejected** | a residual is nonzero, or the checks cannot be completed. |

The **numerics policy** (`Design/Stage3BoundaryToolchain.md`, user rule
2026-08-15) is stricter than "numerics agree": numerics MAY guide a
derivation (branch guesses, candidate generation, region sanity), but the
recorded proof chain of every entry must be numerics-free. An entry is
`Exact` only if an analytic derivation exists independently for every step
that numerics assisted.

## Ledger criterion (six items)

A period enters the exact ledger only with all six: (1) the original powered
cut integral and its normalization; (2) the exact variable map and physical
domain; (3) the selected Frobenius mode and Laurent depth; (4) an exact
analytic value or exact zero proof; (5) exact substitution into the
differential equations; (6) an independent high-precision comparison at a
physical point.

## Status table

| PID | family | uncut dens. | status | value | 1 | 2 | 3 | 4 | 5 | 6 | transfers |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **1** | CF1 | 1 | **Exact** | `0` | y | y | y | y | y | y | 1/1 exact |
| **6** | CF124 | 1 | **Exact** | `0` | y | y | y | y | y | y | 9/9 exact |
| **7** | CF124 | 1 | **Exact** | `0` | y | y | y | y | y | y | 2/2 exact |
| 2 | CF123 | 3 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 3 | CF123 | 3 | NotEvaluated | — | y | — | y | — | — | — | 7 unchecked |
| 4 | CF124 | 4 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 5 | CF124 | 4 | NotEvaluated | — | y | — | y | — | — | — | 4 unchecked |
| 8 | CF199 | 4 | NotEvaluated | — | y | — | y | — | — | — | 1 unchecked |
| 14 | CF212 | 4 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 15 | CF212 | 4 | NotEvaluated | — | y | — | y | — | — | — | 2 unchecked |
| 16 | CF236 | 4 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 17 | CF236 | 4 | NotEvaluated | — | y | — | y | — | — | — | 2 unchecked |
| 21 | CF267 | 4 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 22 | CF267 | 4 | NotEvaluated | — | y | — | y | — | — | — | 4 unchecked |
| 23 | CF267 | 4 | NotEvaluated | — | y | — | y | — | — | — | 2 unchecked |
| 24 | CF267 | 4 | NotEvaluated | — | y | — | y | — | — | — | 1 unchecked |
| 28 | CF384 | 4 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 30 | CF385 | 6 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 31 | CF413 | 6 | NotEvaluated | — | y | — | y | — | — | — | not reached |
| 32 | CF415 | 4 | NotEvaluated | — | y | — | y | — | — | — | 3 unchecked |

Columns 1-6 are the ledger criterion items above. For `NotEvaluated`
entries, item 1 is the Kira family definition and item 3 is the nullity
counter's stratum and exponent data; both are recorded in
`Certificates/period_NN.wl`, but no evaluation has been attempted.

**Summary: 3 Exact, 0 AnalyticCandidate, 17 NotEvaluated, 0 Rejected.**
The three exact entries are precisely the one-uncut-denominator tier; every
remaining period has at least three uncut denominators.

## What changed in this rework

| item | before | after |
|---|---|---|
| PID 1 DE identity | numeric residual `1.25e-9` (5-point stencil) | literal zero under `Together`, both equations, both rows |
| `2F1` contiguous relation | 25-digit numeric spot check | symbolic proof from the Pochhammer recursion, general `a,c` |
| PID 1 zero proof | region argument + 30-digit determination | dominated convergence with an explicit Beta-product bound |
| PID 6/7 zero proof | monotonic decrease of numeric samples at `eps=1/10` | dominated convergence; Codex's argument, machine-checked |
| PID 6/7 reconstruction | 29.7-digit soft-value agreement | exact closed-form soft value (Euler / Pochhammer / Gauss) |
| parametric representation | hand derivation in the pilot report | re-derived symbolically from rest-frame kinematics |
| 12 realization transfers | all unchecked | all 12 verified exactly |
| evidence location | ephemeral `/tmp/.../scratchpad` | this directory, referenced repo-relative |

## Standing caveats

1. **The count is an upper bound.** 20 candidate periods here, `<= 33`
   overall, is not the number of independent boundary evaluations. Codex's
   section 6 applies: exact changes of variables, normalization factors, cut
   orientations and physical chambers must be checked before two candidate
   periods are identified. The transfer verification in
   `Proofs/RealizationTransfers.md` does this for the 12 transfers attached
   to PIDs 1/6/7 only.

2. **`NullityPeriods.wl` cannot be read positionally.** Its `Families` and
   `BlockRows` lists are independently deduplicated, so the family-to-row
   pairing is destroyed whenever two families share a row number (PID 6: 9
   families, 6 rows). See `Proofs/RealizationTransfers.md`. This affects
   any consumer of that record, not just the transfer test.

3. **No closed form is claimed for PIDs 6/7.** What is exact is the
   connection, the soft-stratum indicial structure, the forced value on the
   finite branch, and the vanishing of the free mode — which is what the
   period is. `R(s)` away from `s = 0` is unevaluated and not needed.

4. **The 17 unevaluated periods are gated** on Codex's CF123 cut-Baikov
   construction test (`Design/Stage3BoundaryToolchain.md`, step 2). The
   one-uncut-denominator tier was completed with the reconstruction route;
   the three-and-more tier needs the generator.

## Files

```
BoundaryPeriods/
  LEDGER.md                          this table
  README.md                          layout, conventions, path policy
  QFPilotReport.md                   provenance: the pilot report (was PILOT.md)
  Certificates/
    period_NN.wl                     20 period certificates (exchange schema)
    sweep_all.wl                     the 20-period structural sweep
    NullityPeriods.wl                the period census (see caveat 2)
    FamilyCutData.wl                 propagators and cuts of the 13 families used
    TransferResults.wl               output of verify_transfers.wls
  Proofs/
    SoftEndpointDomination.md        the shared exact zero proof
    Period01.md                      exact ledger entry, PID 1
    Period06_07.md                   exact ledger entries, PIDs 6 and 7
    RealizationTransfers.md          the 12 transfers
  Scripts/
    verify_period_01_de.wls          PID 1 exact DE identity
    verify_soft_domination.wls       the domination lemma, end to end
    verify_parametric_representation.wls   kernels and measure from kinematics
    verify_transfers.wls             the 12 transfers
    extract_families.py              regenerates Certificates/FamilyCutData.wl
```

All scripts locate their inputs relative to the repository root, via
`DirectoryName[$InputFileName]`. None contains an absolute temporary path.
