# Consult (Fable -> external reviewer), 2026-08-17 ~10:15 PDT: is the stage-2 transport strategy the right one?

Self-contained. Provenance tags: [V] = verified by exact computation in
this tree (artifact named); [M] = measured cost/number; [C] = claim or
inference, not independently checked. The coordinator suspects the
current approach may be structurally suboptimal and wants that
challenged or confirmed BEFORE more compute is spent.

## 1. Context (one paragraph)

NNLO hard function for pp -> h+X, double-real channel: 347 master
integrals in 91 families of first-order DE systems in two dimensionless
variables (v, w), regulator eps. Stage 1 is closed [V]: the 1119
strongly-connected blocks fall into 173 equivalence classes (basis
permutation, optionally composed with v<->w), and every class has a
certified eps-form — most rational in (v,w), 20 in single-conic charts,
3 only in two-variable charts (v = +-xy, w = (1-x)(1-y)), 1 one-variable
(u^2 = 1-4vw). Certification is always an exact dlog reconstruction
gate, never a return shape. The required depth per master is MEASURED
from the hard-function coefficient columns [V:
`MasterCoefficientValuations.wl`]: 203 masters need eps^0, 131 eps^-1,
7 eps^-2, 1 eps^-3, 1 eps^-4 (demand N_a = -val_a, plus an optional +1
safety that is a convention, not physics).

## 2. The method in production tonight

Per family, one mission (8-way parallel on a kernel pool):

1. ASSEMBLE the family connection block-lower-triangularly from the
   CLASS forms (T block-diagonal = the stored per-class transformations,
   member v<->w swaps applied [V]), in the frame a chart catalog assigns:
   (v,w) for root-free families; a rationalizing chart otherwise
   (Kallen1/2/3, two Q4 charts, one bilinear chart, and JOINT charts for
   families carrying two different roots, built by a rational point on
   the second conic over the base Kallen chart — all verified exactly
   [V: `TransportCharts.wl`, `TransportChartVerify`]). Five-part exact
   assembly certificate (triangularity, flatness, diagonal = declared
   form, eps-linearity of diagonals, conjugated flatness).
2. TRANSPORT with a block-wise engine on the block DAG (recursion
   F_{i,n} = C_{i,n} + Int Sum_j Sum_r Ahat_ij^[r] F_{j,n-r}) in a
   sparse Chen-word algebra along ONE axis-aligned segment (the other
   variable stays symbolic; both directions tried). Letters may be
   ALGEBRAIC: an irreducible tau-quadratic with eps-free discriminant
   contributes the two roots (-b +- k Sqrt[D0])/(2a), D0 square-free in
   the frozen variable; zero tests are exact over the extension
   (reduce mod r^2 - D0) [V: `t_algebraic_letters.wls` 23/23,
   block-wise == monolithic Libra entrywise on the anchor].
   Non-pure couplings (tau-poles order >= 2, polynomial parts) are
   integrated EXACTLY by parts, promoting word coefficients from
   constants to rational functions of tau.
3. CERTIFY: the recursion itself checked word-by-word exactly per block
   and order; Libra Phi cross-check per diagonal block; valuation
   constraints (I_n = 0 below the physical valuation) imposed and
   asserted; the per-order check against the ORIGINAL family DE run
   where the |rmin| window allows (elsewhere the exact gauge identity +
   recursion certificate are the proof, per GPT-Pro's Eq. 19-21 of the
   2026-08-16 review). Boundary constants stay SYMBOLIC (stage 3).
4. Depth: the exact per-block recursion on the measured demands
   ("DepthRule" -> "Exact"), not the clamped global rule.

Fallback route for expensive families: complete the FAMILY eps-form
first (off-diagonal eps-factorization: closed-form strip of
eps-dependent apparent loci, then two-variable Moser-type pole
reduction, then CANONICA's off-diagonal recursion, then an eps-only
finish), gate it exactly, then transport is a pure dlog append.
[V: CF230's family eps-form certified; its transport then took 7.8 s
total where the class-form basis needed 1568 s for ONE order.]

## 3. Results (state 10:05; sweep still running)

- **46 of 91 families transported** to their required depth (up to
  boundary constants), each with the full certificate set. Chen weights
  1-7; per-family word counts 2 - 10,810; walls 0 s - 85 min, median
  ~30 s [M]. Artifact = the master series I(tau) with symbolic
  integration constants, per family.
- **45 not**: ~30 TimedOut (1200-2400 s caps), 9
  PathDenominatorsNotLinear in the joint charts (path quadratics with
  EPS-DEPENDENT discriminants — by construction never letters), 3
  triple-root families with no covering chart (CF259: lambda1+lambda3+
  (4v+w^2); CF300/CF303: lambda2+lambda3+(1-4vw); over the two-root
  joint chart the third quadratic is a square-free quartic in the path
  variable [V]), plus stragglers.
- The failure mechanism is UNIFORM and measured: the assembled
  class-form basis has couplings that are NOT eps * dlog * const —
  eps-deformed apparent loci in det T of certain class forms give
  tau-poles up to order 3-5 and polynomial parts [V: e.g. class 49's
  det T carries -3(x+y-2xy) - eps(2+3x+3y-8xy)]; the by-parts
  integrator then produces rational coefficients that swell ~x6 in size
  and ~x9 in time per eps order [M: CF230 block 6: eps^-2 28 words /
  7k leaves / 151 s; eps^-1 172 words / 42k leaves / 1568 s; CF124
  block 9: eps^2 alone 971 s at 110k leaves].
- The family-eps-form fallback gates on only **18 of 36** families
  tried [M]; the 18 failures are ONE mode: the two-variable off-diagonal
  pole reduction cycles (clearing a pole at 1-x in x re-creates one at
  1-y in y). One family (CF360-type) additionally has a polynomial part
  at infinity (needs a Moser step at infinity, not implemented). Cost
  when it works: 20-100 s mid-size, 1600+ s for CF230's 13x13 [M].

So: two-thirds of the demand-weighted work is done cheaply; the
remaining third is blocked not by transport but by BASIS HYGIENE (the
off-diagonal completion), and our current cleanup tooling converges on
half of its targets.

## 4. The strategic worry (why this consult)

Stage 1 canonicalized CLASSES in isolation and deferred the off-diagonal
structure entirely. The couplings' non-purity is a property of the
canonical bases RELATIVE to subsectors, so it could never have been seen
class-by-class — it only appears at assembly. The standard published
workflow (Lee; Henn; the Higgs double-real literature) constructs the
canonical form of the WHOLE system — diagonal blocks first, then the
off-diagonal (Sylvester/homological) steps, which for eps-forms on the
diagonal are LINEAR problems — and only then transports, at which point
transport is trivial. We are discovering that ordering the hard way.

Candidate courses, on which we want a verdict:

(A) Finish as-is: keep the by-parts integrator for the heavy tail with
    bigger caps. [C: looks wrong — the swell is x6-x9 per order and the
    deepest families need 5-7 orders.]
(B) Complete the family eps-forms for the ~30 blocked families with a
    PROPER off-diagonal reduction, then sweep (transport is then
    seconds per family). The open question is the right tool: our
    custom strip/Moser loop cycles; CANONICA's off-diagonal recursion
    worked on CF230 (1601 s) but is slow and was not designed for
    charts; **Libra's Fuchsify is documented to walk exactly the
    off-diagonal blocks** — and our only "Libra can't do it" data
    predates the discovery that Libra's Projector silently returns zero
    matrices unless OptionValue::optnf is Off (all earlier negative
    Libra verdicts on this machine are void [V]). We have NOT retried
    Libra Fuchsify on an assembled family with eps-form diagonals in a
    chart. [C: this looks like the highest-value untested move.]
(C) Global basis: construct ONE canonical form for the whole 347-master
    system (all families share subsectors through the registry), as the
    published gg->H calculations do, and transport once. [C: large
    up-front cost, unclear it beats (B) family-wise.]
(D) Represent differently: stop path-transporting with a symbolic
    frozen variable; instead fibrate (two consecutive one-variable
    transports, y first at fixed x0, then x), landing directly in a
    GPL fibration basis. [C: unclear this changes the swell — the
    swollen objects are the rational coefficients, not the words.]
(E) For the heavy tail only: numeric-first (AMFlow/DiffExp series along
    paths) with analytic reconstruction later. [Rejected by our own
    proof-chain policy and both 2026-08-16 reviews; also loses the
    unexpanded endpoint modes stage 4 needs. Listed for completeness.]

## 5. Questions

Q1 (the decision). Given the measurements in §3, is (B) — proper
off-diagonal completion family-wise, then sweep — the course you would
commit to? If yes, what is the RIGHT reduction algorithm for the
off-diagonal steps when every diagonal block is already an eps-form in
a two-variable chart: Libra Fuchsify on the assembled system? the
linear Sylvester solve order-by-order in eps (since diagonals are
O(eps), the homological equation at each pole order is linear with a
known invertible operator except at resonances)? CANONICA's recursion?
Name the decisive 1-hour test.

Q2 (our cycling Moser loop). The two-variable pole reduction cycles
(x-step recreates y-poles). Is this a known phenomenon with a known
cure (e.g. reduce in ONE variable only along the transport direction
and tolerate y-poles as apparent; or work at the level of the
eps-graded Sylvester equations where no letter-by-letter choice
exists)? Or is cycling evidence that the strip ansatz (block-unipotent,
one pair at a time) is simply the wrong parametrization?

Q3 (is the by-parts integrator ever the right tool?). For a family
whose couplings are non-pure ONLY because of eps-deformed apparent
loci, is there a cheap closed-form gauge (scalar, per coupling block)
that removes exactly those loci without the full off-diagonal
completion — i.e. is our measured "strip of the eps-dependent locus in
closed form" (44-66 s on CF230 [V]) generalizable to ALL such loci, so
that the remaining couplings are pure dlog and the append fast path
applies, WITHOUT running any recursion at all?

Q4 (triple-root families, 3 of 91). The three quadratics per family do
not admit a common rational chart via our rational-point construction
(third root becomes a square-free quartic [V]). Options we see:
RationalizeRoots on the triple (does a joint parametrization exist at
all — is the double cover branched on three conics rational here?);
per-sector frames + variation of constants for just these families
(the old tier-3 architecture); or algebraic letters of higher degree
(currently refused). Which, and what is the 30-minute feasibility
check?

Q5 (safety margin). We now transport at the STRICT need N_a = -val_a
(hard function through eps^0), having measured that the ledger's +1 was
"one extra order of safety" and that the module's old +1-in-jmax is the
constants' 1/eps valuation, handled by the window bookkeeping. Given
the recursion certificate + valuation constraints, is there any
consumer (boundary fixing at stage 3, endpoint modes at stage 4,
scale/renormalization terms in the subtracted assembly) that genuinely
requires one order beyond -val_a? If yes, name it — we will re-run at
+1 only where needed.

Q6 (acceptance without the original-DE check). For ~half the
transported families the per-order original-frame DE check is
NotPerformable at the demanded orders (the |rmin| window). We accept on:
exact gauge identity (assembly certificate) + exact word-wise recursion
certificate + Libra Phi cross-check + valuation assertion. Both
2026-08-16 reviews endorsed this in principle. Do you co-sign it as the
production acceptance, or do you want the DE check re-stated in the
canonical frame (cheap) as a mandatory part?

Q7 (sanity of scale). 46 families: weights 1-7, <= 11k words/family,
artifacts 8 KB - 46 MB, total 71 MB+ [M]. Anything pathological in
those numbers that suggests the REPRESENTATION (one path, symbolic
frozen variable, II-words with rational coefficients) is wrong for the
stage-3/4 consumers (boundary fixing at strata, endpoint modes in
u = 1-w, then convolution with the hard coefficients)?

Q8 (the road not taken). Is there a standard route we are missing
entirely — e.g. deriving the endpoint/threshold expansion of the hard
function directly (regions/Mellin-Barnes per master at the strata that
stage 4 needs) so that full (v,w) functions are never required for the
heavy tail? State the condition under which that shortcut is sound for
a hadronic hard function needed at generic (v,w).

## 6. What NOT to re-derive

Stage-1 class forms are certified [V]; the depth demands are measured
[V]; the block-wise engine is exact and cross-checked against Libra on
anchors [V]; Libra Projector/Fuchsify traps and the CANONICA context
trap are recorded in CLAUDE.md; the two-assistant setup (Codex owns a
parallel derivation; exchange via `External/CodexExchange/`) is
unchanged; numerics never enter a proof chain.
