# Hard classes 97/77/79 — the eps-form route (state at 2026-08-16, 19:45 PDT): ALL THREE CERTIFIED

This directory is the PRODUCTION record for the last three connection
classes.  The eps-graded solutions in the parent directory remain valid
and are the independent verification track (see Q7 of the consult
reply below for what they do and do not add).

## State (2026-08-16 afternoon)

| class | status | certificate |
|---|---|---|
| 97 (CF258_B9) | **two-variable eps-form, exact gate PASSED in x and y** on the ORIGINAL chart system | `c97_epsform_two_variable.wl` (T, letters, constant residues, gates); reproduce with `Scripts/epsform_finish_c97_constant_gauge.wls` + `Scripts/epsform_gate_c97_two_variable.wls` |
| 77 (CF230_B1) | **two-variable eps-form, exact gate PASSED in x and y** on the ORIGINAL chart system; residues = sigma*(class-97 residues) | `c77_epsform_two_variable.wl`; slice data `c77_slice_transformations.wl`; reproduce with `Scripts/epsform_involution_77_vs_97.wls`, `Scripts/epsform_teq_77_slices.wls`, `Scripts/epsform_lift_c77.wls` |
| 79 (CF231_B1) | **two-variable eps-form, exact gate PASSED in x and y** on the ORIGINAL chart system (chart v = -xy, w = (1-x)(1-y)); independently re-derived by the coordinator | `c79_epsform_two_variable.wl`; `symnorm_c79.wl` (A_norm, Ttot, balance path); `c79_constant_gauge_symbolic.wl`; `balanced_c79_y3_7.wl`; logs in `logs_c79/`; reproduce with `Scripts/epsform_lee79b_c79.wls` (slice normalization, 10 balances) -> `Scripts/epsform_symrep79_c79.wls` (symbolic replay) -> `Scripts/epsform_finish79i_c79.wls` (constant gauge by sampling + rational interpolation, verified exactly) -> `Scripts/epsform_gate79_c79.wls`; independent check `Scripts/epsform_independent_gate_c79.wls` |

Chart for 97 and 77: v = x y, w = (1-x)(1-y)  (sqrt(lambda) = x - y).
Chart for 79:        v = -x y, w = (1-x)(1-y)  (sqrt(Q) = x - y; Q(v,w) = lambda(-v,w)).

The class-97 form: letters {x, y, 1-x, 1-y, x-y, x+y, x+y-xy} (= pullback
of the (v,w) alphabet {v, w, 1-w, lambda, 1+v-w}), constant 4x4
residues with eigenvalues x:{1,0,0,0}, y:{1,0,0,0}, 1-x:{-2,-2,-2,1},
1-y:{-2,-2,-2,1}, x-y:{2,0,0,0}, x+y:{-6,0,0,0}, x+y-xy:{0,0,0,0}
(nilpotent, rank 1).  T = Ttot . U . c with Ttot the symbolic
normalization (`symnorm_c97.wl`), U the x-constant Lee factorization
gauge (linear solve, unique up to scalar), c the rational scalar gauge
1/((y-1)^2 y^2 (y - eps/(1+4eps)) q1 q2) that removes exactly the
eps-dependent apparent y-loci.

The class-79 form: letters {x, y, 1-x, 1-y, x-y, 1-x-y, 2-x-y} (= pullback
of the (v,w) alphabet {v, w, v+w, 1+v+w, Q}), constant residues with
eigenvalues x:{-2,-2,-2,1} y:{-2,-2,-2,1} 1-x:{-2,1,1,0} 1-y:{-2,1,1,0}
x-y:{2,0,0,0} 1-x-y:{0,0,0,0} (nilpotent, rank 1) 2-x-y:{-6,0,0,0}
(ranks {4,4,3,3,1,1,1}) — NOT conjugate to the class-97 tuple (measured:
no eigenvalue-list match at x=1 and infinity), so its reference came from
its own normalized system.  T = Ttot . U . c: Ttot from a 10-balance
path found on the y=3/7 slice (224 s) and replayed with y symbolic
(53 min); U(y,eps) by sampling the linear factorization system at 18
rational y (8 s each; the direct nullspace over Q(y,eps) did not return
in 40 min) and rational interpolation in y (degrees <= (8,9)), then
VERIFIED exactly (M_i U == eps U N_i at every locus, y and eps symbolic);
c the rational scalar gauge that removes the eps-dependent apparent
y-loci.  Deck-covariant (intertwiner unique, S^2 scalar).  T's
denominators are pure letters; det T vanishes only on the raw
representative's own eps-dependent apparent locus (where the original
basis is degenerate — expected).

The class-77 form: letters {x, y, 1-x, 1-y, x-y, 2-x-y, 1-xy} =
sigma-images of the class-97 letters under sigma: (x,y) -> (1-x,1-y)
(= v <-> w), with residues sigma*(class-97 residues) — every 77 slice
eps-form is simultaneously conjugate to that tuple (intertwiner unique).
T_77 = T_eq . sigma*T_97 where T_eq is the small (LeafCount 363,
y-degrees <= 2) gauge equivalence between the 77 chart system and the
sigma-image of the 97 chart system, reconstructed by rational
interpolation in y from nine slice-gated transformations; det T_eq
carries the eps-dependent apparent locus of the raw 77 representative,
which T_eq therefore removes.

## What was verified independently before this state was written

The claims of the earlier (automated) session were re-derived from the
stored artifacts by fresh computation (`Scripts/epsform_verify_c97_chain.wls`):
Ttot maps chart -> A_norm symbolically in y (82 s); A_norm is Fuchsian
and normalized at all six loci (residue eigenvalues in eps*Z, incl.
infinity); (A_x,A_y)_norm flat; all 12 phase-2 slice files hold genuine
dlog eps-forms with x-INDEPENDENT T2.  `c97_T2_symbolic.wl` (identity
matrix) was a placeholder, not a result.  The "interpolation
obstruction" of the earlier session was real as a phenomenon (CANONICA's
per-slice free constant conjugation) but the plan drawn from it was
wrong: no interpolation and no two-variable CANONICA are needed once
the system is normalized with y symbolic — the finish is a linear solve
(Lee's factor-out-eps step; Libra ships it as `FactorOut`).

## Method record (for reuse on class 79 and any future hard class)

1. Chart in which every letter of the block is a product of linear
   factors in (x,y) — check the pulled-back alphabet BEFORE anything else
   (class 79 in the old t-chart carried three hidden quadratic loci; in
   v = -xy, w = (1-x)(1-y) it has none).
2. Fuchsify (finite loci then infinity) and normalize with the
   spectator y SYMBOLIC (Lee balances; the symbolic replay of a numeric
   balance path is viable — 82 s for class 97).
3. Constant gauge: solve M_i(y,eps) U = eps U N_i (all loci, N_i from
   one reference point) over Q(y,eps); nullspace is 1-dimensional and
   automatically invertible when the block is irreducible.
4. Scalar gauge c from the identity component of the y-mismatch (integer
   residues, incl. at eps-dependent apparent loci and irreducible
   quadratics in y: each term is n * dlog q).
5. THE GATE (only acceptance): push the ORIGINAL chart (A_x, A_y)
   through T and check entrywise equality with eps Sum R_a dlog phi_a in
   BOTH variables, constant R_a; then flatness of the eps-form.
6. Cross-class shortcut: if another class shares the alphabet up to a
   chart involution, compare residue tuples at matched loci; a
   1-dimensional intertwiner means the target form is known and only a
   (small) gauge equivalence T_eq remains — interpolate it from slices.

## Consult record

`FableMax_consult_2026-08-16_afternoon.md` (prompt, provenance-tagged),
`FableMax_reply_2026-08-16_afternoon.md` (verbatim reply) and
`GPTPro_reply_2026-08-16_afternoon.md` (the user ran the same prompt past
GPT Pro; its logical warnings were already discharged by computation, its
class-79 q-adic prescription is superseded by the chart finding, its
stage-2/3 constraints are adopted).  The reply's
Q1 argument (why A_y' is automatically an eps-form up to a rational
scalar) is the proof sketch behind step 4; its Q6/Q8 items (deck
invariance at x=y instead of "regularity"; endpoint modes exact in eps
from the canonical form in the local coordinate u = 1-w, at family
level) set the design of the boundary and endpoint stages for these
classes.  Its Q4 suspicion (class 79's quadratic is lambda) is
DISPROVED by `Scripts/epsform_identify_c79.wls`: lambda does not occur
in class 79; the quadratics were chart artifacts.

## Ledger and audits (done 2026-08-16, 19:00-19:45 PDT)

- `ClassForms/class97.wl`, `class77.wl`, `class79.wl` written by
  `Scripts/build_hard_class_ledger.wls` (schema: Chart of Kind
  "TwoVariable" with Subst/Root/RootSquare/Inverse/RootSymbol/Variables;
  Variables {x,y}; EpsForm in (x,y)); `ValidateCanonicalForm` True on all
  three; `Tests/t_hard_class_epsforms.wls` 24/24 (gates recomputed from
  the class representatives, chart identities, eps-linearity, validator,
  flatness).  Class ledger **173/173**.
- Audits (`Scripts/epsform_audits_c97_c77.wls`, `epsform_independent_gate_c79.wls`):
  final letters eps-free (all three); T's denominators are pure letters —
  the eps-dependent apparent loci created by the balances cancel INSIDE
  T (all three); det T carries no eps-dependent (x,y)-factor for 97, and
  for 77/79 exactly the raw representative's own apparent locus (expected:
  the original basis is degenerate there); deck intertwiner
  (x,y)->(y,x) exists for all three (dim 1, S^2 scalar; the same S for 97
  and 77).  Not done: residue sparsification (cosmetic).

## Next steps (in order)

Calibration (2026-08-16, corrected after user pushback): stage 2 for all
173 classes is on-demand and cheap (Libra returns symbolic words with
symbolic constants; the hard classes cost minutes instead of
milliseconds because their T is large and their letters bilinear in the
path parameter — measured 103 s for the class-97 block at weight 2).
Stage 3 is a BOUNDED campaign, not an open-ended one: <=33 candidate
periods, the 1-uncut-denominator tier ledger-Exact, the open item is the
17-period one-dimensional tier (13 multi-dimensional ones on Codex's
side per the round-5 split); every step is a probe-verified mature
package (asy regions, MB.m + barnesroutines, HypExp, SubTropica) and the
one non-package piece is the multi-variable cut phase-space
parametrization feeding MB (gating experiment: Codex's Baikov
cut-boundary integrals on CF123).  Expect days once that build exists;
the cost driver is the numerics-free exactness bar per ledger entry.
The three hard families add only deck-invariance conditions at x = y.

1. Stage-2 integration: transport of the three families in chart
   variables (subsector letters pull back rationally; chamber policy per
   Q6); boundary conditions at x = y by deck invariance; endpoint modes
   per Q8.  Compare the eps-graded eps^2 towers with the eps-form
   solutions once (bug-catcher), then AMFlow at scattered physical
   points incl. one lambda < 0 point as the independent check.

## Traps found on the way (recorded in CLAUDE.md as well)

- **Libra `Projector` returns a ZERO matrix on Wolfram 14.2** unless
  `Off[OptionValue::optnf]` is set before use: `OInverse` emits a benign
  `OptionValue::optnf` message and `Projector`'s internal `Check` treats
  it as failure (measured: `Projector[{{1,0,0,0}},{{1,1,0,0}}]` is all
  zeros as shipped, correct after `Off`; `Quiet` does NOT help).  Every
  "Libra found no balance" verdict on this machine before 2026-08-16 is
  suspect.  `Fuchsify` only walks off-diagonal blocks — on an irreducible
  block it is a no-op even when it returns a matrix; the double poles of
  class 79 were removed by the balance loop itself.
- After `ValidateCanonicalForm` (it loads CANONICA), a later `Get` in the
  same kernel reads bare `eps`/`x`/`y` as `CANONICA`` symbols; normalize by
  `SymbolName` after every read (t_hard_class_epsforms failed 6/24 from
  this until fixed).

## CORRECTION (2026-08-16, later the same night): the "no slack" reading was wrong

The paragraph below says CF258/CF230 have "no coupling of order >= 2 (no
slack), so per-chain and per-edge clamped longest paths coincide".  That
was read off `masterTransportDepthBudget`'s `RMin` table, which stores
only the **minimum** eps-order of each coupling BLOCK.  With the FULL
Laurent support of every coupling (`masterTransportLaurentSupport`, new
this session) the slack is there: for CF230 in the chart every coupling
into the hard block, `{6,1}` ... `{6,5}`, carries orders both `<= 0` and
`>= 2` -- e.g. `{6,1} -> {-3,-2,-1,0,1,2,3,4,5}`.  Those are MIXED edges
and they are exactly where the exact per-block recursion and the clamped
rule differ: on the measured per-master demands CF230 needs weight **6**
exactly where the clamped rule charges **7**, a MIXED edge is present in
**28 of the 36** families measured, and the exact rule is strictly lower
in **11 of 36** (CF12, CF20, CF26, CF27, CF50, CF88, CF207, CF209,
CF211, CF230, CF360).

The measurement, the per-master demands it rests on, and the per-edge
supports are in `../../TransportDepthLedger.md` (+ `.wl`) and
`../../MasterCoefficientValuations.wl`; the rule is
`FeynFacet/Private/MasterTransport.wl` `masterTransportExactDepth`
(option `"DepthRule" -> "Exact"`, default still `"Clamped"`), pinned by
`Tests/t_exact_depth.wls`.  Also measured: the deepest hard-function
coefficient column is eps^-4 (ONE master); 203 of 347 columns start at
eps^0.  The planning estimate "every master through roughly eps^4" is
superseded.

## Transport depth-vs-cost (2026-08-16 night): measured, reviewed, plan

Measured (`Scripts/epsform_depth_diag_cf258.wls`, no transport): CF258 in
the chart has 12 blocks with EVERY deep coupling (eps-orders -1..-3)
issuing from block 1 (class 1, the 1x1 volume anchor); no coupling of
order >= 2 (no slack), so per-chain and per-edge clamped longest paths
coincide, D_i = pi_i = {0,2,1,3,3,1,3,4,3,4,3,5}; CF230: {0,1,1,3,3,4}.
Per-block eps-rescaling F_i -> eps^{m_i} F_i is therefore a relabeling
here (the depth moves into the constants / T-window; both reviewers
agree the intrinsic Chen weight is invariant), and "completing the
family eps-form" (off-diagonal cleanup) is hygiene, not the transport
fix, for the same reason. Block-level profile (class-97 block,
`Scripts`-level run 21:27-21:48): Libra transport 8-27 s at weights 2-4;
the EXACT per-order DE check (Together on words x rational coefficients)
8 s / ~80 s / ~330 s / ... per order — it dominates 10-50x and grows
~4x per order. Family-level: the monolithic 13x13 / 24x24 Pexp at
weight 5-7 exceeded the engine's 1800 s budget three times (word
combinatorics over the union alphabet, not algebra swell).

Probe (2026-08-16 22:50, `probe_libra_blocks.wls` as a pool mission): on
CF230's assembled chart x-connection at y = 3/7 (13x13, 6 blocks), Libra
Pexp on the COUPLINGS-ZEROED matrix costs 0.2 / 0.3 / 1.8 s at weights
3/4/5, while the FULL matrix returns BackendAborted in 2.7 s at every
weight (off the path frame the couplings are not Fuchsian at infinity —
a polynomial part in x — which Libra refuses; on the path frame the
family runs did not abort but exhausted 1800 s). The "+1" in jmax is
real: the class-97 block at Orders {0,0} passes the eps^0 DE check at the
module's weight 1 and returns RegradingIncomplete at forced weight 0 (the
constants' 1/eps valuation). Together with the depth diagnostics this
localizes the family cost entirely in the coupling words.

Reviews (`FableMax_reply_2026-08-16_night_transport_cost.md`,
`GPTPro_reply_2026-08-16_night_transport_cost.md`) converge on the plan:
1. Depth: replace the global jmax + clamped-D rule by the exact per-block
   recursion (GPT Eq. 4 / Fable-Max W* with Bellman potentials): per-block
   demands N_i from the ACTUAL hard-coefficient poles each master
   multiplies (through T, GPT Eq. 11), per-chain signed sums; the
   "checkable window" |rmin| penalty is an artifact of checking in the
   original frame — check in the assembled canonical frame (T certified
   once), then every computed order is checkable.
2. Block-wise transport on the DAG with cached class solutions
   (F_i = Phi_i [B_i + Sum_j Int Phi_i^-1 C_ij F_j], sparse Chen words,
   no union alphabet, no unused columns; transport only the physical
   boundary subspace once nullity is known) — the highest-value change.
3. Certificate: the recursion itself checked word-wise exactly (sparse
   collection + exact zero tests per rational coefficient; finite-field /
   degree-bounded evaluation if simplification is slow) — NOT floating
   point (the coordinator's earlier suggestion to use high-precision
   numerics as the production check is withdrawn; numerics stay an
   independent validation layer: AMFlow/DiffExp/GiNaC).
4. Constant residue sparsification: material 2-5x, do once per class.
5. Keep Libra's II-word form; fibrate only at boundary/endpoint stage.
6. Do not launch weight-9/10 monolithic Pexps; a budget-exceeded Pexp
   must checkpoint per-weight partials.
Block-wise engine (Opus agent, 2026-08-16 22:30-23:20; `FeynFacet/Private/
BlockwiseTransport.wl`, `TransportFamily[..., "Engine" -> "Blockwise"]`,
`Tests/t_blockwise_transport.wls` 27/27, drivers `Scripts/blockwise_*.wls`,
artifacts `blockwise_structure_CF230.wl`, `blockwise_structure_CF258.wl`,
`blockwise_polestructure_CF230.wl`, `blockwise_anchor.wl` in this
directory) — measured:
- S1 FALSIFIES the assumption both reviews built on: the couplings of the
  assembled chart connections are NOT all pure dlog. CF230: 13 of 18
  nonzero coupling pairs pure dlog, 5 (all issuing from block 6 = class
  49) with tau-poles up to order 3 and a polynomial part; CF258: 29/50
  pure, 21 (from blocks 8/10/12) with poles up to order 5. Mechanism
  (measured on class 49, `class49_locus_CF230.wl`): det T of the class-49
  form carries the factor -3(x+y-2xy) - eps(2+3x+3y-8xy) — an
  eps-DEFORMATION of the genuine letter 1-v-w (pullback x+y-2xy); T^-1
  therefore has a simple pole at that eps-dependent locus, and expanding
  the coupling T_6^-1 A_6j T_j in eps turns 1/(f0 + eps f1) into poles
  of order 2, 3, ... AT THE REAL LETTER. Because the canonical connection
  Ahat is independent of the original basis (det T must vanish where the
  original Wronskian does), no change of the original masters removes
  this; what does is a change of the CANONICAL bases mixing block 6 with
  its subsectors, i.e. the off-diagonal eps-factorization by strip
  transformations (CANONICA's off-diagonal steps with the diagonals
  already canonical / Libra's block workflow) — the reviews' item 5.
  Its payoff here is concrete: pure-dlog couplings make the block-wise
  integrator a plain append instead of integration by parts. (An earlier
  sentence here said "remove the apparent loci from the class forms' T";
  that was imprecise — corrected.) Confirmed by measurement on CF258
  (`blockwise_class_locus_CF258.wl`): its non-pure source blocks 8 and 12
  carry NO eps-dependent kinematic factor in their own det T yet their
  couplings have poles up to order 2 — the higher poles are a property of
  the canonical bases RELATIVE to the subsectors, not of the block's own
  T; block 10 carries the same deformed letter x+y-2xy as CF230's class
  49, so that one locus recurs across families and is the first target.
- Engine: recursion F_{i,n} = C_{i,n} + Int Sum_j Sum_r Ahat_ij^[r]
  F_{j,n-r} in the sparse Chen-word algebra (no Phi^-1, no shuffle
  products by design; Phi_i via Libra, cached, used only as a
  cross-check), pure-dlog append fast path + exact integration-by-parts
  for higher poles/polynomial parts, certificate = the recursion checked
  word-wise (single words over distinct tau-free letters, so
  coefficient-wise vanishing is sufficient — checked, not assumed).
- Anchors: NLO 7x7 monolith 5.5 s vs block-wise 3.9 s, CF3 55.8 s vs
  8.0 s, F and I equal ENTRYWISE and exactly on both, recursion
  certificate and Phi cross-check all zero.
- Soundness fix (Codex review, `External/CodexExchange/codex_review_blockwise_transport_2026-08-16.md`):
  the dlog "append" integration assumed tau-free word coefficients; after
  a higher-pole coupling produces rational c(tau), a later dlog step must
  integrate the PRODUCT (with c'). Four tests added and run FIRST (3 of 4
  failed as predicted, X1 reproducing Codex's example verbatim), then
  fixed: tau-dependent coefficients route through the full-product
  integration by parts, the append is guarded by FreeQ[c, tau], the
  term-list path throws on a tau-dependent coefficient; 31/31, anchors
  unchanged and exact; partial-fraction cache hoisted. Review items 3-4
  (transport only the admissible boundary combinations; make the
  original-family DE check optional / at demanded orders) recorded as
  engine work; item 5 (exact-depth cost) fixed by the depth agent.
- Quantified ceiling of the rational-coefficient path (old integrator, block
  6 of CF230): eps^-3 4 words 3.3 s; eps^-2 28 words / 7 123 leaves 166 s;
  eps^-1 172 words / 42 271 leaves 1568 s — coefficient size x6 and time
  x9 per order, so even the refactored engine (2.2x) projects ~2 h for
  eps^0 and ~19 h for eps^1: the off-diagonal cleanup is a PRECONDITION
  for S4, not an optimization.
- S4 (CF230 end to end) not completed at the time of writing: the first
  integrator implementation was too slow on block 6 (166 s for 28 words
  at eps^-2); an entry-wise-Apart refactor is in the tree, validation
  pending on the pool.
Depth ledger (Opus agent, 2026-08-16 22:30-23:45; `Results/UU_08_10_canonical/
TransportDepthLedger.wl/.md`, `MasterCoefficientValuations.wl`,
`Scripts/master_coefficient_valuations.py`, `Scripts/transport_depth_ledger.wls`,
`Tests/t_exact_depth.wls` 17/17, `Tests/t_transport_checkpoint.wls` 5/5,
`Tests/t_wolfram_traps.wls` 9/9; `t_master_transport.wls` 68/68) — measured:
- Per-master coefficient valuations, exact, all 347 masters (from the
  2026-08-13 reconstruction columns; bound-meeting method, no
  probabilistic step): 203 masters start at eps^0, 131 at eps^-1, 7 at
  eps^-2, 1 at eps^-3, 1 at eps^-4, 2 at eps^+1, 2 zero columns. Demand
  N_a = -val + 1 (through eps^0 with one order of safety) is therefore
  1 for most masters; "everything through eps^4" was wrong by a lot.
- CF258's two masters (class 97) have valuation 0 -> the hard family is
  needed through eps^1 only; exact per-block rule gives weight 6 (module
  rule 7); CF230 likewise 6 (module 6/7 depending on demands).
- Exact per-block depth recursion (`masterTransportExactDepth`, option
  "DepthRule" -> "Exact", opt-in "DepthReport"; runs lazily — the default
  pre-transport stage on CF230 is 90 s vs 315 s with it on) with full
  Laurent supports per coupling; MIXED couplings (orders <= 0 and >= 2)
  in 30 of 38 families with per-block records; exact < clamped in 11.
- Libra's PexpExpansion is a NestList over weights, so it can be driven
  weight by weight: a budget-exceeded transport now returns the completed
  weights (1.02x overhead measured); the CF360 backend abort is again
  reported as BackendAborted (an abort inside TimeConstrained had been
  misread as a budget overrun).
- Two Wolfram traps pinned as tests (Libra Projector zero matrix; CANONICA
  context reads); a third measured, not root-caused: the inline
  conditional-ReplaceAll symbol normalizer can leave its RHS unevaluated
  once CANONICA is loaded — use the explicit-rule-list form.
Open items flagged by the reviews: derive/test the "+1" in jmax (it is
the constants' 1/eps valuation — test by one weight lower, queued);
state in the ledger that the couplings are dlog with constant Laurent
residues (certificate part or add it); pin the class-79 chart branch
conventions (v = -xy) and one word-orientation convention for the 77/97
pair; block equivalence != physical-boundary equivalence (77/97 swap
must preserve chamber, cut orientations, boundary map); turn the two
Wolfram traps into pinned regression tests.

## Family eps-forms moved

Family eps-forms (the off-diagonal cleanup) now live in
`Results/UU_08_10_canonical/FamilyEpsForms/` — one certified record per
family plus its `README.md` ledger; the CF230 record produced here on
2026-08-17 is kept there as `family_epsform_CF230_offdiag_2026-08-17.wl`
(with its `_state_*` / `_sector6_D` files).

## Superseded

`Scripts/canonica2var.wls` (two-variable CANONICA on the normalized
pair) and `Scripts/phase3b_interp.wls` (slice interpolation) are
superseded by the linear finish; kept for the record.  The historical
slice artifacts (`canonical_slice_c*`, `p2_c97_y*`, `balanced_c*`,
`symnorm_c97.wl`) remain the inputs of the certified chain.
