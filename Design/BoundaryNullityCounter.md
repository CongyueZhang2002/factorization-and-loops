# Design: exact boundary-period count (the nullity counter)

Purpose: before evaluating ANY boundary integral, compute — exactly and
deduplicated — how many genuinely new boundary periods the 347-master
double-real program requires, and identify each one. Replaces the 20–40
estimate. This is the entry gate of the boundary stage: no period is
evaluated unless the counter names it.

## Inputs (all existing or in flight)

1. Family assemblies from the VoC engine: SCC-sorted A' with per-block
   canonical frames (rational or chart), certificates required.
2. Stratum residue data: for each diagonal block, at each anchor
   stratum (v->0, w->0, soft 1-v-w->0, and the corner charts), the
   residue matrix of the block's canonical connection, its exact
   eigenvalues and Jordan structure. The family-level extractor
   exists (canonica_sweep residues.wls); it must be extended to class
   forms, with chart-frame blocks translated to the stratum's chart
   before residues are read.
3. Physical exponent sets PER CHART, derived from the local residues
   (never the global soft table applied to a foreign chart — Codex
   Q4 correction).
4. Registry/SCC order: which lower sectors are already-solved inputs
   at counting time (structurally: all of them — counting assumes
   lower sectors known, which the SCC order guarantees).

## The count, per family, per anchor stratum

Let block b have canonical stratum residue R_b with Jordan data. Its
local homogeneous modes are z^(eps*lambda) (log^k z / k!) chains; the
inhomogeneous part of the local solution is FIXED by lower-sector data
through the couplings. Unknowns: the homogeneous mode coefficients
c_(b,a) restricted to the physically selected modes.

Constraint rows C:

- **Volume anchors**: rows for blocks whose basis rows are
  normalization-known integrals (V3 = CF1 anchor and its images under
  registry GLIRules).
- **Inheritance/normal-residue rows**: on the stratum, the coupled
  system's solution must lie in the kernel of the normal residue
  acting on the full local vector (Codex framework: R_normal F = 0 on
  the stratum, extended by the tangential-preservation conditions);
  with lower sectors known these are inhomogeneous linear equations
  on the c_(b,a).
- **Branch absence**: coefficients of modes with forbidden branches
  (unphysical w^eps at w->0, v^eps at v->0, wrong soft branch) are
  zero — one row each.
- **Regularity**: where a master is provably regular/integrable at the
  stratum, negative-power modes are excluded.

N_new(family, stratum) = dim ker C on the selected mode space. The
kernel basis NAMES the required periods: (block, mode exponent, log
level) triplets.

## Deduplication

Same class + same stratum (after orbit map and chart translation) +
same mode => the same period. Dedup at class level using the
content-addressed catalogue (representative basis + orbit key + orbit
map — Codex's corrected keying). The global answer is
N_total = |union over families of kernel-named periods|, reported as
the exact list, each entry in the exchange schema:
{representative basis, ordered physical limit, integer valuation,
Frobenius exponent, (period coefficient — filled at evaluation)}.

## Acceptance tests (all must pass before the count is trusted)

1. NLO family: N_new = 0 (volume + six branch-absence rows saturate) —
   matches the validated NLO gate.
2. CF231_B1 corner (Codex's E13 object): reproduce their four
   surviving modes {(-2,-2), (-2,-1), (0,-2)_1, (0,-2)_3} without
   importing their classification.
3. Totals confronted with Codex's 20–40 estimate; discrepancies
   investigated, not averaged.

## Non-goals

- No period evaluation. Values are stage-3 work (SubTropica/regions/
  Beta-Gamma), split with Codex: they hold the hard region, we hold
  soft/collinear.
- No reliance on either side's integer class labels.

## Implementation notes

Exact rational arithmetic only; per-item progress lines; seat
discipline (one main kernel, checks before every invocation);
resumable per family; results file written atomically; every family's
count carries its constraint-matrix rank certificate so the count is
re-derivable.
