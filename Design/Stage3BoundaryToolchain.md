# Stage 3: boundary toolchain (measured; joint with Codex)

Decided by the 2026-08-15 package survey (scratch stage3_survey/
SURVEY_REPORT.md) and Codex's boundary findings/plan (their Exchange/
CodexBoundaryFindingsPlan_2026-08-15.md). Every adoption below is
probe-verified against certified controls, by us or by Codex (marked).

## Toolchain by step

1. **Count & name the periods** — our nullity counter
   (Design/BoundaryNullityCounter.md; validated 24/24 vs E13/CF407).
   <=33 upper bound; reductions via zero coefficients, lower-sector
   identities, period equivalences, shared representations.
2. **Construct the parametric period** (cut phase space at the
   ordered limit):
   - Codex's `BuildBaikovCutBoundaryIntegralFromTopology` (their
     tree; acceptance = exact identity with orientations, proved
     physical domain, sign-fixed fractional powers). CF123 test in
     progress on their side GATES our 5-variable parametrization
     build — we build only what that test proves missing.
3. **Region identification** at ordered limits — `asy 2.1`
   (ours-measured: reproduced certified PID-1 structure + 4
   controls; adopted by Codex alongside their own region code).
   Chart selection remains judgment.
4. **Exact evaluation** of region integrals:
   - Mellin-Barnes: `MB.m` + `barnesroutines` (ours-measured: control
     period closed exactly);
   - pFq epsilon-expansion: `HypExp 2.0` (ours-measured, exact
     through eps^4 on the certified control); Gauss/Appell
     recognition per Codex's route;
   - hyperlogarithmic integration for linearly reducible densities
     (Codex route; HyperInt itself is Maple-gated);
   - `SubTropica` high-precision numerics (reference driver in
     qf_pilot PILOT.md sec. 19.4; HyperFLINT present on this box).
5. **Recognition guard (mandatory)**: `FindIntegerNullVector`/PSLQ
   FABRICATES relations for basis-free constants at every tested
   precision (<=50 digits; negative control in the survey). It is a
   candidate generator ONLY; no recognized value enters any ledger
   without exact certification (DE substitution + independent
   high-precision check).
6. **Algebraic-geometry support for hard maximal-cut curves**
   (Codex-measured, adopted into our toolkit probe list):
   - **PassageMath/SageMath**: singularities, geometric genus, exact
     rational parametrization of algebraic curves (CF231's conic:
     genus 0, explicit chart, verified identically);
   - **QEPCAD**: independent exact quantifier-elimination decisions
     of polynomial signs in physical chambers;
   - **ore_algebra**: singularities and indicial equations of scalar
     operators (feeds toolkit R2/R3);
   - **Singular gmssing.lib**: Bernstein polynomials / spectra of
     hypersurface singularities.
7. **Automation boundary (both teams agree)**: no package determines
   the positive-energy physical chain/orientation from an unoriented
   algebraic period, or chooses charts; those stay in the cut
   definition, boundary record, and human/agent judgment.

## Ledger criterion (adopted from Codex, mutual policy)

A period enters the solved ledger only with: the original powered cut
integral + normalization; the exact variable map + physical domain;
the selected Frobenius mode + Laurent depth; an exact analytic value
or exact zero proof; exact substitution into the differential
equations; an independent high-precision comparison at a physical
point. Exchange as exact source files and certificates, not prose.

**Numerics policy (user rule, 2026-08-15):** numerics appear in a
ledger entry ONLY as the independent check. They MAY guide derivation
steps (branch guesses, candidate generation, region sanity), but the
recorded proof chain of every entry must be numerics-free — an
analytic derivation must exist independently for any step numerics
assisted. Audit note: PIDs 6/7 satisfy this (Codex's dominated-
convergence proof replaced the pilot's numeric branch selection);
PID 1's analytic zero proof is an OPEN ITEM to be recorded
explicitly (mirror of the same argument on its kernel) before its
entry is ledger-final.

## Division of work (round-6/Codex-plan state)

- Ours: asy/MB/HypExp campaign over the one-dim tier (pending the
  CF123 Baikov gate), the shared one-dim period census, Libra-based
  transport (MasterTransport.wl), soft/collinear strata.
- Codex: CF123 Baikov construction test; CF231/CF258/CF230
  maximal-cut + Picard-Fuchs route; CF407's four physical-mode
  periods; T121 dimensional recurrence (D+4 quasi-finite
  representative); hard region ({M1, M3, T} catalogue).
- Open joint items: stage-4 NLO distributional pilot format verdict
  (gates production depth — UNANSWERED, follow up); the 12
  realization-transfer checks (needs a named owner); PSLQ warning
  acknowledgment by Codex.
