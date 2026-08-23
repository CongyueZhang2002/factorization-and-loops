# Consult (2026-08-16, 21:20 PDT): status after the hard classes, and the transport depth-vs-cost problem

Self-contained; you are a fresh reviewer. Be adversarial and specific;
name algorithms/packages; for every proposal give the cheapest decisive
test. Provenance tags: [V] = verified today by exact computation and
recorded with artifacts; [M] = measured wall time / resource, single run;
[C] = claim or estimate not yet verified.

## 1. Where the project stands

pp -> h+X at NNLO, double-real emission: 347 master integrals, 91
families of coupled first-order DE systems in (v,w) with regulator eps
(d = 4-2eps). Stage 1 (canonicalization): the 1119 diagonal blocks fall
into 173 classes; **173/173 now carry certified eps-forms** [V]. The last
three (4x4, irreducible at generic eps, one square root each) were closed
today in two-variable rationalizing charts — 97 and 77 in
v = xy, w = (1-x)(1-y) (sqrt(lambda) = x-y, lambda the Källén function),
79 in v = -xy, w = (1-x)(1-y) (Q(v,w) = lambda(-v,w)) — by: symbolic Lee
normalization -> the linear "factor out eps" step (an x-constant U(y,eps)
from the nullspace of M_i U = eps U N_i; when the symbolic nullspace was
slow, U was sampled at 18 rational y and rationally interpolated, then
verified exactly) -> rational scalar gauge -> THE GATE: the ORIGINAL chart
connection pushed through T = Ttot.U.c equals eps Sum_a R_a dlog phi_a
entrywise in BOTH variables with constant R_a; flat. Class 77 = the v<->w
image of 97 (same residue tuple up to conjugation, T_77 = T_eq . sigma*T_97
with a tiny T_eq); class 79's "irreducible quadratic locus" was an
artifact of an earlier one-variable chart. Ledger records + a test
recomputing the gates from the class representatives: 24/24 [V]. Two
traps found and recorded: Libra `Projector` returns a ZERO matrix on
Wolfram 14.2 unless Off[OptionValue::optnf] (Check swallows a benign
message), and `ValidateCanonicalForm` (loads CANONICA) makes later Get
read bare `eps` as CANONICA`eps.

Stage 2 (transport) is the existing `TransportFamily`: assemble a family's
blocks in dependency order against the class forms (block-lower-
triangular conjugated connection Ahat, five-part exact certificate),
call Libra `PexpExpansion` on the whole conjugated system, regrade the
weight-graded result into eps orders, impose physical valuation
constraints, and check order by order against the ORIGINAL family DE.
Benchmarks that set expectations: NLO 7x7 to weight 3 in 0.03 s; CF3
(a tier-3 family with a 1/eps coupling) 37 s in the suite [M]. A
chart-pullback layer added today (`TransportFamilyInChart`) pulls a whole
family into the chart (rational blocks by chain rule, single-conic-chart
blocks composed by an exact identity, v<->w swap members handled) and
calls the same engine; both hard families ASSEMBLE whole in the chart with
the five-part certificate all true (CF258, 24 masters/12 blocks: 132 s;
CF230, 13/6: 26 s) [V,M]; each hard 4x4 block transports standalone with
exact per-order DE checks (97: 103 s at weight 2; 77: 588 s) [M]. Suite
green (68/0, 23/0). Stage 3 (boundary constants: <=33 candidate periods,
mature toolchain asy/MB.m/HypExp/SubTropica probe-verified, one
parametrization build outstanding) and stage 4 (endpoint modes exact in
eps from the canonical form) are next; not the subject here.

## 2. The cost problem, precisely

Depth arithmetic in the module (all exact, from the assembled Ahat):
- ord_eps of every coupling block Ahat[i,j], i>j (Laurent order in eps);
- **shift D** = longest path in the block DAG under edge cost
  max(0, 1 - ord); transport weight = jmax + D (a word descends one block
  per negative-order factor);
- **rmin** = min over couplings of ord (global);
- depth need: need_j = max_i (need_i - rmin_ij) backwards along the DAG;
- **checkable orders**: with I orders n0..n1 requested, order n is
  checkable iff n <= n1 - |rmin| (the check at order n consumes I down to
  n + rmin), so any check at all needs (n1 - n0) >= |rmin|.

Measured on the two hard families [M]:
| family | Ahat | shift D | rmin | Orders -> {0,1}: weight | Orders -> {0,0}: weight | outcome |
|---|---|---|---|---|---|---|
| CF258 (class 97 + 11 blocks) | 24x24 | 5 | -3 | 7 (jmax 2 + 5) | 6 | weight-7 Pexp exceeded the engine's 1800 s backend budget (1859 s CPU, 1.05 GB, no output by construction) |
| CF230 (class 77 + 5 blocks) | 13x13 | 4 | -3 | 6 | 5 | weight-6 likewise; weight-5 run in flight at time of writing |
A CHECKED whole-family result needs Orders -> {0,3} => weight 9 (CF258)
/ 8 (CF230): projected far beyond hours with the monolithic Pexp.
For comparison the class-97 block alone: 4x4, weight 2, 103 s [M] — a
4x4 at weight 2 should be milliseconds in Pexp, so we suspect [C] the
time there is in the exact certificate/verification algebra (Together on
rational functions with T entries of LeafCount ~1e4 and eps-degree ~14),
not in the transport; a stage profile is running now (numbers appended
below when available).

Where the shift comes from [C, consistent with everything measured]: the
hard block's T = Ttot.U.c has eps-poles (det T ~ eps^3 (1+eps)^2 (1+4eps)^2
x rational(x,y); entries with 1/eps^k), so the couplings Ahat[hard,sub] =
T_hard^-1 A_off T_sub carry 1/eps^k, and along the dependency chain the
costs add to 4-5. Residues R_a are dense 4x4 with 10-digit rationals
(no constant similarity applied yet).

Production requirement [C]: masters enter the NNLO assembly against
coefficient poles up to eps^-4 (the reconstructed coefficient columns
start at eps^-4), so masters are needed through eps^4-ish for the finite
hard function, i.e. jmax ~ 4 -> weight ~ 9-10 for these families as the
arithmetic stands. Note this question is NOT specific to the hard
classes: the largest rational families (blocks of dimension 47/45/44 in
CF259/CF385/CF303) have never been transported at production depth; the
"instantaneous" experience is NLO and small blocks.

## 3. Candidate remedies we see (assess, rank, and give the decisive test)

(a) **Per-block eps-rescaling of the canonical bases** F_i -> eps^{m_i} F_i
    (preserves the eps-form; multiplies coupling (i,j) by eps^{m_i-m_j}).
    Choosing m along the DAG makes every coupling O(eps^1) and D -> 0 —
    but the same powers reappear as eps^{-m_i} in T, i.e. in the F-window
    needed for a given I-order. Is the module's accounting (D with the
    clamp max(0,1-ord)) already minimal, or does slack (couplings of
    order >= 2) let a rescaling genuinely lower jmax + D? Give the exact
    optimality statement.
(b) **Block-wise transport instead of one monolithic Pexp**: solve each
    diagonal block's Pexp separately (small matrices, cheap at any weight)
    and integrate the couplings as sources by variation of constants,
    order by order (each source term is a product of known words; the
    integral of dlog-kernel x word is again a word). Does Libra already
    exploit block-triangular structure inside PexpExpansion (we don't
    know), or is a wrapper needed? Expected gain: the word count is
    governed by each block's letters and the depth of its own chain, not
    by 24 x 24 x (all letters)^weight.
(c) **Sparsify the residues** by a rational constant similarity (Jordan /
    echelon normal form of the tuple), done once and reused: cheaper
    matrix products in every word. Cosmetic or material?
(d) **Reduce the demanded depth**: compute per-family required depth from
    the actual coefficient poles the family's masters multiply (not a
    global eps^4), and per-block need_j from the DAG (already there); is
    "checkable" (exact per-order DE check needing a 3-order window)
    over-demanding for a mature backend — could the certificate be the
    five-part assembly certificate + exact per-order checks on a
    truncated window + numeric spot checks (AMFlow / DiffExp) at points,
    per the "certification proportional to code age" rule?
(e) **Representation**: keep Libra's unexpanded word form (its compact
    II[{a},x,x0] words) and never expand to GPL functions until
    evaluation; use PolyLogTools fibration only at the boundary/endpoint
    stage. Where in our pipeline is expression swell actually incurred —
    transport, regrading, or the DE check?
(f) **Numeric-first for the deep orders**: DiffExp / AMFlow series along
    lines for orders that only feed the finite part, keeping symbolic
    words only where endpoint modes need them (stage 4 needs UNEXPANDED
    (1-w)^{a eps + m} modes, so pure numerics is not enough there — but
    is it enough for the bulk?).
(g) Anything standard we are missing for large block-triangular
    canonical systems at high weight (e.g., the way DiffExp/SeaSyde/AMFlow
    users avoid symbolic transport entirely; Duhr–Dulat fibration bases;
    Lee's "adaptive" evaluation; symbol-level bootstrapping of the
    top-sector functions with the alphabet known).

## 4. Questions

Q1. Is our depth arithmetic (jmax + D, checkable n <= n1 - |rmin|)
    correct and minimal? If not, what is the exact minimal weight for a
    block-triangular eps-form with couplings of known Laurent orders?
Q2. Rank (a)-(g) by expected wall-clock gain for CF258 to eps^4 with a
    checked result, and give the first test for the top two.
Q3. Where should the time be going for a 4x4 eps-form at weight 2 (103 s
    measured)? What is a healthy cost model per (dimension, weight,
    letters) for Libra's Pexp so we can spot algebra swell vs genuine
    transport cost?
Q4. Given the production depth question applies to all 91 families, what
    is the right sweep protocol: measure per-family (dim, letters, D,
    rmin) first and sort by cost, transporting cheap families to full
    depth immediately and the few heavy ones by the remedy you rank
    first?
Q5. Anything in §1 you would not accept as established? (Everything
    tagged [V] has an exact artifact + script in the repository.)

Appendix (added when available): stage profile of the class-97 block
transport at Orders {0,1}/{0,2}/{0,3}: [M, 21:40 PDT] class-97 block standalone (4x4), TransportFamilyInChart with
per-stage timestamps:
  Orders {0,1} (weight 2): pullback+certificate 3 s; Libra transport +
    per-weight verification 9 s; regrading/valuation <1 s; exact DE check
    eps^0 8 s, eps^1 ~74 s; total 96 s.
  Orders {0,2} (weight 3): transport 8 s; DE check eps^0 9 s, eps^1 82 s,
    eps^2 ~330 s; total 528 s.
  Orders {0,3} (weight 4): transport 27 s; DE check eps^0 10 s, eps^1 86 s,
    eps^2 and eps^3 still running at the time of writing.
So at BLOCK level the transport is seconds and the exact per-order DE
check (symbolic: words x rational coefficients, shuffle reduction and
Together) dominates by 10-50x and grows ~4x per order; at FAMILY level
the Libra Pexp itself exhausted 1800 s at weight 5-7 (13x13 / 24x24).
Consequence we intend to act on: replace the exact per-order DE check by
a high-precision numeric check at random rational points (PolyLogTools/
GiNaC, handyG, or Libra numerics; keep the exact check opt-in for small
blocks), which also removes the |rmin| = 3 "checkable window" penalty on
the weight; the family-level Pexp cost (shift D = 4-5) remains and is the
subject of Q1/Q2.
