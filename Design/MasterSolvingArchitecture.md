# Design: NNLO master solving over the canonical-family lattice

State ledger per block (Codex convention, adopted 2026-08-13; no state
without its certificate):

1. **canonicalized** — exact dlog reconstruction of the stored ε-form
   from constant residues (the only accepted certificate; CANONICA's
   return shape is NOT one).
2. **boundary-determined** — dim ker C = 0 after volume, inherited,
   forbidden-mode, and regularity constraints.
3. **analytically solved** — G = T·U·C to the required ε-depth, with
   the independent checks of the NLO gate (order-independence, slices).

## Frames

A block's sectors need not share one chart. Frame data per sector s:
`{Variables, Chart (subst + root), Tsector, AepsSector}` where
rational sectors have `Variables = {v,w}`, chart = identity; hard
sectors carry their conic chart (six classes, all verified: three
Källén variants via the shift trick u = ℓ+2t; v²+4w, 4v+w²,
and bilinear 1−4vw via direct linear solve). Sqrt objects appear
only when pulling chart-frame functions back to (v,w); represent as
inert `sqrtQ[class]` symbols with `sqrtQ[c]^2 -> q_c` reduction rules.

### Two-variable chart convention (classes 97/77, and 79)

Classes 97 (CF258_B9) and 77 (CF230_B1) have **no** rational ε-form in
(v,w); their form exists only in the chart

    v = x y,  w = (1−x)(1−y),   √λ = x − y,   det ∂(v,w)/∂(x,y) = x − y

(class 79: v = −x y, w = (1−x)(1−y)). A chart record is an Association
`<|"Kind"->"TwoVariable", "Variables"->{x,y}, "Subst"->{v->f, w->g},
"Root"->…, "RootSquare"->…|>`; `Subst` must be rational with a
nondegenerate Jacobian, and `RootSquare` pulled back through `Subst`
must equal `Root²` exactly (checked, not declared).

Direction adopted 2026-08-16: a family carrying such a block is
transported **whole, in the chart variables** —
`TransportFamilyInChart` (`FeynFacet/Private/MasterTransport.wl`,
tests `Tests/Transport/t_chart_transport.wls`) pulls the connection back by the
chain rule (Aₓ = A_v ∂ₓv + A_w ∂ₓw) with an exact flatness certificate
and composes **every** block's stored class form with the chart's
coordinate map, then calls the existing `TransportFamily` in (x,y).
Three record frames compose:

- rational frame `{v,w}` → substitution;
- target chart `{x,y}` → its stored `Subst` must match exactly;
- single-conic chart `{v,t}` → its `Root` is the same algebraic
  function the chart rationalizes, so it is set equal to the chart's
  rational `Root` and solved **linearly** for t (no square root is
  introduced); the solve is a candidate, and what licenses it is the
  exact identity that the conic `Subst` at that t reproduces the chart
  `Subst`. Measured for classes 49/95: t = 1 − y.

Class equivalence is a basis permutation **optionally composed with
v↔w** (that is `ClassifyBlocks`'s definition), so a member's connection
need not equal the representative's — measured: CF258 rows {5}, {24} and
CF230 row {7}. In this chart the swap is the involution
(x,y) → (1−x,1−y), i.e. exchanging the two images of `Subst`; the
pullback **tries** it and the exact re-derivation decides, so a wrong
guess cannot pass. Basis permutations are not attempted (none was
needed: every multi-dimensional block of CF258/CF230 equals its
representative entry by entry).

Every pulled-back ε-form is **re-derived** from the pulled-back block
system as T⁻¹AT − T⁻¹dT; a stored `EpsForm` is compared as provenance
and a mismatch is a rejection. The layer fails closed
(`ChartPullBackFailed`) if any block's form cannot be pulled back, and
it makes **no** physics bookkeeping — no chamber, branch or sign; the
chart and its Jacobian determinant are recorded in `"ChartNotes"` for
the stage that does.

Path convention: the pulled-back alphabet contains bilinear letters
(x+y−xy for class 97, x+y−2xy for the pullback of 1−v−w), which are
**quadratic** in the path parameter on a generic straight segment in
(x,y) — the word backends admit linear denominators only, and the run
is refused with `PathDenominatorsNotLinear`. Chart transports therefore
run on an **axis-aligned** segment (one chart variable held at its
symbolic target value, base anchor x₀ = 1/2 by default), on which every
letter is linear in τ again. The per-order check against the original
DE is then a statement about that direction; the two-directional
statements (flatness, and each diagonal block equalling its declared
form in both chart variables) come from the assembly certificate.

## Canonicalization tiers (per block, cheapest first)

- T1: full-block ε-form in (v,w) — done for the validated set.
- T2: full-block ε-form in a single chart (deg-0 triage; 600s cap).
- T3: **block-diagonal + VoC** (the general fallback, works for every
  block including multi-class and the 4 off-diagonal stragglers):
  - per-sector diagonal ε-forms in each sector's own frame (measured:
    seconds each, ansatz degree 0 suffices for every scanned sector);
  - T_blockdiag = diag(T_1..T_k); conjugate the full A once to get
    the residual couplings B_ij (rational, possibly with sqrtQ);
  - no ε-factorization of B is attempted. Solving proceeds per
    ε-order: sector s at order n obeys dF_s^(n) = (ε-form)_s F_s^(n-1)
    + Σ_{j<s} B_sj F_j^(≤n) — first-order scalar/small-system
    quadratures with already-known sources (variation of constants).
    Depth is fixed by the weight-budget rule (below), so quadratures
    are finitely many explicit integrals.

Tier is recorded in the block artifact; consumers must not care which
tier produced the functions.

## Weight budget (Codex Q3 refinement, adopted)

Required depth per block = reachability computation, NOT the target's
apparent valuation: with G = T U C, T = Σ ε^r T^(r), C = Σ ε^q C^(q),
a weight-n transport term feeds Laurent order k iff r+n+q = k and the
residue-product chain connecting the components is nonzero. Boundary
valuations established by exact rational reduction of C components
(never numerically). The 1/ε-in-T shift (measured at NLO: one extra
weight, relative error 3.08 when omitted) is a special case.

## Boundary program

Anchor strata: soft surface (1−v−w → 0), collinear edges (v → 0,
w → 0), corner. Substrate (built, validated 40): per-letter integer
residue matrices + eigenvalues + Jordan data per stratum
(canonical F-frame; G-frame adds T scaling).

Per-block constraint matrix C over the physical local modes:
- volume rows (CF1 anchor V3 and its subsector images via registry
  GLIRules);
- inherited rows: subsector masters already solved (lattice order) —
  their known expansions constrain the block's boundary vector;
- forbidden-mode rows: branch absence (no unphysical w^ε at w=0 etc.,
  exactly the NLO-gate mechanism), physical-exponent selection from
  the per-chart local spectra (NEVER the global soft table applied to
  a foreign chart — Codex Q4);
- regularity rows where a boundary point is interior to the physical
  region of a subintegral.

`N_new(block) = dim ker C` = number of genuinely new periods; compute
BEFORE evaluating anything (Codex nullity discipline). Deduplicate
periods across blocks by registry sector identity. Residual periods:
SubTropica (Addon; Codex probe scripts as reference), validated first
on NLO edge periods where exact answers exist.

Acceptance tests for the counter: (a) NLO block → nullity 0 with the
seven known constraints; (b) Codex's E13: must reproduce their four
undetermined corner modes {(-2,-2),(-2,-1),(0,-2)_1,(0,-2)_3} without
importing their classification (mapping via registry; their E13
touches CF407).

## Transport

- Alphabet per block from its validated ε-form; letters restricted to
  the path segment must have proven fixed sign (factor the alphabet,
  check every intermediate corner on axis-aligned paths — Codex Q5);
  tangential regularization only for initial zero letters.
- Weight ≤3 in classical {Log, PolyLog, ζ}; weight ≥4 via Libra/GPL
  (PolyLogTools conversion for evaluation). Chart-frame sectors
  transport in chart variables along the pulled-back path.
- Every transport product is checked by the NLO-gate battery:
  independent lower-depth rerun agreement + high-precision numeric
  spot checks at chamber points (30+ digits), plus AMFlow comparison
  for a sample of masters per block (1 main kernel + ≤4 subkernels;
  half the machine stays reserved for Codex).

## Implementation notes

- All heavy runs: per-item progress lines to a log; watchdog with
  ≤30-min visibility; deg-0/cheap-tier triage before any multi-degree
  sweep; resumable via results files keyed by family.
- Opus subagents implement scripts against this spec; Fable reviews
  and owns the physics-critical algebra (boundary rows, exponent
  tables, weight budgets).
- Nothing enters the registry without its tier certificate; failure
  artifacts live in quarantine directories, never in `forms/`.
