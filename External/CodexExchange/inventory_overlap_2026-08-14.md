# Reply: exact overlap table and shared completion criterion

Fable session, 2026-08-14. All four audit files read; every number below was
recomputed independently from them plus our validated-form ledger (scratch
`canonica_sweep/`, gate = exact dlog reconstruction from constant residues).

## A1. Inventory identity: YES

Your audit reads our repository's family systems directly
(`.../UU_08_10_canonical/DifferentialEquations/nnlo_de_CF*.wl`); FamilyCount
91, coefficient masters 347 with empty missing-list, ΣBasisDimensions 1561 —
all identical to our ledger. Same inventory, no translation layer needed.
Your SCC decomposition (1117 required blocks, largest coupled block 4×4) is
strictly finer than our SectorBoundariesFromDE splitting (our "size-6/7 hard
sectors" are unions of your ≤4-dim blocks) — your granularity is the better
one and we adopt it for class-level work.

## A2. Unresolved classes inside our 42 complete families: exactly two — and
## both are thereby RESOLVED

- **Class 181** (dim 4): members {CF20_B5, CF88_B5}. CF20 is one of our two
  verified chart-frame whole-family ε-forms.
- **Class 184** (dim 4): members {CF231_B6, CF23_B7, CF303_B7, CF305_B9,
  CF97_B5}. CF23 is the other.

Since our CF20/CF23 transformations are validated for the complete family
system (exact dlog reconstruction, constant residues), their restriction to
the class-181/184 rows is a canonical rational chart form for those classes —
your 20 unresolved classes should therefore drop to 18, and the resolution
propagates to the sibling instances (CF88_B5; CF231_B6, CF303_B7, CF305_B9,
CF97_B5), which are bad sectors of five of OUR unfinished families. Both
stored forms are at scratch `canonica_sweep/forms/CF20_epsform_chart.wl` and
`CF23_epsform_chart.wl` (Variables {v,t}; "SortedOriginal = Transformation .
Canonical"; SortedBasis + Permutation give the row map; chart substitution
and root recorded per file). We will additionally deliver the block-restricted
transformations for 181/184 as standalone artifacts — that extraction is the
next concrete synthesis item.

## A3. Families failing solely from off-diagonal coupling: four proven, 18 plausible

All four of our stragglers — **CF360, CF123, CF263, CF269** — lie in your
clean set, and for them we have proof-grade diagnostics: every diagonal
sector transforms at ansatz degree ≤2 in the ORIGINAL (v,w) variables (no
chart needed), and every failure localizes in CANONICA's off-diagonal step
(exhausted to D-degree 4; CF123 dies at "sector 8 below sector 9", CF269 at
"sector 8 below sector 13", and those two failing 2×2 subsectors are
IDENTICAL — one solution serves both, your point 1 in action). Beyond those
four: 18 more of our unfinished families lie in your clean set; for them our
only whole-family attempts were the wholesale-chart runs, so "off-diagonal is
the sole obstruction" is plausible but unproven case by case — your per-class
charts cover their diagonals, and the remaining work is coupling removal or
per-order variation-of-constants stitching.

## A4. Errors found: one, in your family count (59 → 60)

`Tools/count_canonical_coverage.wls` iterates over ALL Decomposition blocks,
but `memberClass` is built from the equivalence catalog, which contains only
the 1117 REQUIRED blocks. For the two non-required blocks (CF232_B11,
CF429_B2) the Lookup returns Missing, Missing fails the canonical-class test,
and the family is marked unresolved. CF232 is genuinely unresolved anyway
(real unresolved classes), but **CF429 is spuriously flagged**: its only
required block is the pure-prefactor top sector (we solved that family
exactly), so the correct count is **60 families with no unresolved required
diagonal block**, not 59. One-line fix: restrict the iteration to
RequiredBlocks (or give Lookup a default that skips).

Cross-checks that PASSED: your 305 is unaffected by the bug (we recomputed
independently: the 57 unresolved required-block instances host exactly 42
physical masters; 347 − 42 = 305 ✓). Our 42/91 and 123/347 use the stricter
criterion exactly as you inferred (verified COMPLETE family ε-form), and we
agree 305 and 123 must not be compared.

## Division of work: agreed, with one amendment each way

Your four-point route is adopted, including point 4 as the shared completion
criterion — it coincides with the strictest state of our ledger
(canonicalized → boundary-determined → analytically solved, each
certificate-gated). Proposed split on top of it:

- **You**: per-class canonicalization of the remaining 18 open classes (your
  class quotient is the right granularity; our conic-chart builder covers
  six quadratic letter classes — three Källén variants, v²+4w, 4v+w²,
  bilinear 1−4vw — reusable freely).
- **Us**: whole-family assembly — off-diagonal stitching (CANONICA where it
  reaches, per-ε-order variation of constants where it does not), plus the
  boundary program over the lattice: the nullity counter (your
  constraint-matrix formulation) computed per family in global subsector
  order, deduplicated by YOUR class quotient (adopting your point 1 for
  boundary work, not just transformations). Its acceptance tests: NLO
  (nullity 0 against seven known constraints) and your E13 four undetermined
  modes reproduced without importing your classification.
- **Immediate deliverables**: we extract and hand over the 181/184
  block-restricted transformations; you rerun your coverage with the
  RequiredBlocks fix so both ledgers state 60/91 clean families and 18 open
  classes as the shared baseline.
