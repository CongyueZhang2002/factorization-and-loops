# Consult: last three DE classes of an NNLO master computation — assess the ε-form route and its finish; propose faster alternatives

Self-contained. You are a fresh reviewer; be adversarial, specific, and
name algorithms/packages/papers. For every alternative you propose, give
the single cheapest decisive test. Flag anything below that looks wrong.

Provenance tags (please respect them):
  [V]  = re-verified today by exact symbolic computation from stored
         artifacts, independently of the session that produced them;
  [C]  = claimed by an earlier automated session, NOT re-verified;
  [X]  = the parallel assistant's (Codex) independent work.

## 1. Setting

pp -> h+X at NNLO, double-real emission, collinear factorization +
reverse unitarity. 347 master integrals in 91 families obey coupled
first-order DE systems in two dimensionless variables (v,w), regulator
ε (d = 4−2ε). The 1119 irreducible diagonal blocks fall into 173
equivalence classes; 170 have exact validated ε-forms (Henn canonical,
dF = ε Σ_a R_a dlog φ_a F, constant R_a; validation = exact dlog
reconstruction). Transport is done with Libra (chosen by benchmark);
boundary constants are cut phase-space periods (separate toolchain:
asy / MB.m / HypExp / SubTropica, PSLQ only as candidate generator);
final deliverable per master: GPLs to a fixed ε depth + UNEXPANDED
endpoint Frobenius modes (1−w)^(aε+m) for plus-distribution
extraction; numerics never in a proof chain.

Three 4×4 classes were unresolved:
- class 97 (rep CF258_B9) and class 77 (CF230_B1): "Källén classes",
  alphabet contains sqrt(λ), λ = (1−v−w)² − 4vw;
- class 79 (CF231_B1): its own quadric Q = (1+v−w)² + 4vw.

Structural facts (exact): all three scalar operators (cyclic-vector
reduction, one variable, other spectator) are irreducible at generic ε
(ore_algebra at two independent specializations each; class 97 also by
exact symbolic Beke exhaustion at order 1). At ε=0 each operator factors
completely into four first-order pieces (certified chains). Two routes
exist: an ε-graded scalar recursion ("Frobenius in ε", our engine
`EpsilonGraded.wl`, certified residuals through ε³ for 97 and charted
77 [also re-verified by Codex]) — and the ε-form route below, opened
after a review pointed out that (i) irreducibility does NOT obstruct an
ε-form (a canonical form is a gauge transformation, not a
factorization) and (ii) CANONICA/Libra search RATIONAL transformations,
so in the original (v,w) chart, where the required transform contains
sqrt(λ), their failure carried no information.

Rationalizing charts (verified): 97/77 share v = xy, w = (1−x)(1−y),
giving sqrt(λ) = x − y; 79 uses w = −t(1+t+v)/(1+t) making sqrt(Q)
rational.

## 2. Class 97: state of the ε-form route

Work in the chart, y as spectator, x-connection A_x(x,y,ε) (4×4).

(a) [V] Chart connection: x-loci {0, 1, y, −y, y/(y−1), ∞}; the pair
    (A_x, A_y) is flat. Denominators also carry (1+4ε).

(b) [V] Symbolic normalization. A rational Ttot(x,y,ε) (recorded as an
    infinity-Fuchsification followed by 11 two-point Lee balances,
    replayed with y symbolic; det Ttot = (x−y)/((x−1)^6 x (x+y)^4))
    maps A_x to A_norm = Ttot⁻¹ A_x Ttot − Ttot⁻¹ ∂_x Ttot — verified
    symbolically in y (82 s). A_norm is Fuchsian in x at every locus
    including ∞, and NORMALIZED in Lee's sense: residue eigenvalues
      x=1: {−2ε,−2ε,−2ε, ε};  x=0: {0,0,0, ε};  x=y: {0,0,0, 2ε};
      x=−y: {0,0,0, −6ε};  x=y/(y−1): {0,0,0,0};  ∞: {0, 2ε, 3ε, 3ε}
    (Fuchs sum 0). No ε-dependent x-loci. HOWEVER A_norm and the
    transported y-connection A_y,norm = Ttot⁻¹ A_y Ttot − Ttot⁻¹ ∂_y Ttot
    carry ε-DEPENDENT y-loci: y = ε/(1+4ε) and two quadratics in y with
    ε-dependent coefficients (apparent, introduced by Ttot). The
    normalized pair is flat [V].

(c) [V] Twelve numeric-y slices: at each y0, an x-INDEPENDENT,
    ε-dependent 4×4 T2(y0,ε) (obtained from CANONICA on the slice) maps
    A_norm|_{y0} to a genuine dlog ε-form with constant residues and
    letters {x, 1−x, x−y0, x+y0, x−y0/(y0−1)} — i.e. the physical
    alphabet specialized. So on every slice the finishing
    transformation is a CONSTANT (in x) gauge.

(d) [C] The earlier session then tried to interpolate T2 in y, found
    the samples "not a function of y" (CANONICA's per-slice free
    constant conjugation), tried normalizing them at a point, found
    that "destroys the ε-form because the gauge is ε-dependent", and
    concluded slice interpolation needs an ε-independent gauge fix; it
    then launched a two-variable CANONICA on the normalized pair
    (ansatz degrees (2,2,2,2)), which ran 35 min at 1.2 GB flat and was
    stopped for the handoff (no verdict).

(e) [V, today] Our reading of (c)+(d): since A_norm is Fuchsian and
    normalized with y SYMBOLIC, A_norm = Σ_i M_i(y,ε)/(x − x_i(y)) with
    x-independent residues M_i, and the finish is Lee's linear
    "factor out ε" step: solve   M_i(y,ε) U = ε U N_i   for all six loci
    (five finite + ∞), N_i := M_i(y0,μ)/μ at one reference point
    (absorbs the unknown constant conjugation), U ∈ Mat_4(Q(y,ε)).
    Then U⁻¹ A_norm U = ε Σ_i N_i dlog(x − x_i(y)) with no derivative
    term (U is x-free) — an ε-form in x with constant residues by
    construction. Measured so far: on the y=3/7 slice the solution
    space is 1-dimensional over Q(ε) with det U ≠ 0 (Schur: the block
    is irreducible, so U is unique up to a scalar), and U⁻¹ A_norm U
    on that slice IS an ε-form with constant residues [V] — i.e. the
    slice finish is reproduced by a 4-second linear solve. The
    y-symbolic solve (nullspace over Q(y,ε) of a 96×16 system whose
    entries are polynomials of ε-degree ≤ 14) is running at the time of
    writing; if it is slow, the fallback is: solve at ~10 rational y,
    fix the scalar by normalizing one fixed entry, rationally
    interpolate U(y,ε), then apply the exact gate.
    Then A_y' = U⁻¹ A_y,norm U − U⁻¹ ∂_y U must be checked to be an
    ε-form as well (letters expected {y, 1−y, …}); the residual freedom
    is a scalar c(y,ε).

## 3. Class 77 (same chart)

[C] Slice ε-forms at 10 y-values, letters at y=3/7 {x, 1−x, 3x−7,
7x−11, 7x−3} = specializations of {x, 1−x, xy−1, x+y−2, x−y}
(consistent with the alphabet {0,1,2−y,1/y,y} found on the ε-graded
route [X]). The recorded slice path is 1 balance + CANONICA's internal
rational ansatz, so no symbolic-y replay exists yet, and the stored
balanced slice still carries an ε-DEPENDENT apparent x-locus
(−9 − 23ε − 3x + 3εx = 0) [V from the artifact]. Right now the parallel
assistant is running the ε-graded VECTOR-frame route on class 77 with
the full physical closure (lower-sector sources) through O(ε²),
building Ψ0, Ψ1, Ψ2 and the y-frame connections Γ0, Γ1, Γ2 with GPL
parameter derivatives [X, in progress].

## 4. Class 79 (chart w = −t(1+t+v)/(1+t))

[C] Slice Fuchsified, three successful balances; all residues at
LINEAR loci have integer + integer·ε eigenvalues; remaining integer
offsets at ∞ are {0, 2, 1, 1} (with 2+3ε, 1+ε), i.e. visible sum +4,
so offsets totalling −4 sit at loci the linear-factor census does not
see — necessarily an IRREDUCIBLE QUADRATIC x-locus. Balancing ∞ against
linear loci only trades offsets back and forth. Machinery in hand
handles rational points only.

## 5. Constraints

Mathematica 14.2 with CANONICA, Libra, PolyLogTools, HPL, HypExp, MB.m,
asy, SubTropica, AMFlow; python3 with ore_algebra; Kira/FireFly/
Ratracer. Shared box: ≤1 main kernel + 4 subkernels, ≤10 cores. Every
long run needs per-item progress and a cheap-scale test first.
Acceptance for any candidate transformation is the same exact gate:
push the ORIGINAL chart system through it and check entrywise that the
result is ε × (ε-free matrix) with constant dlog residues; then the
stage-1 exact dlog-reconstruction validator.

## 6. Questions

Q1 (class 97 finish). Assess §2(e). Given that a constant-in-x gauge
   works on every slice and A_norm is normalized with y symbolic, is
   there any way the y-symbolic linear solve can fail (solution space
   empty, or nonzero only up to a y-dependent scalar that cannot be
   made rational)? Given a 1-dim solution and flatness of the
   normalized pair, is A_y' automatically an ε-form up to the scalar
   gauge c(y,ε)? Give the argument or the counter-scenario, and say
   how the ε-dependent y-loci of A_y,norm must disappear (they should
   cancel against U's denominators — is that guaranteed?). What is the
   cleanest way to fix the scalar gauge and to keep U's denominators
   minimal?

Q2 (class 97, if Q1 holds). Anything we should check on the resulting
   two-variable ε-form beyond the exact gate — e.g. that the y-letters
   are exactly {y, 1−y} (from the (v,w) alphabet {v,w,1−w,λ,1+v−w}
   pulled back through the chart) and that no ε-dependent letter
   survives; and whether "letters at ε-dependent positions removed by
   an ε-dependent constant U" ever leaves a spurious singularity in
   the fundamental solution.

Q3 (class 77 finish, cheapest). Options we see: (i) replay the slice
   path symbolically as for 97 (needs the CANONICA-internal part of the
   slice path re-derived as explicit balances); (ii) skip replay: run
   Fuchsify + Lee balances with y symbolic from scratch (all steps
   rational); (iii) directly the linear factorization step of §2(e)
   applied after any y-symbolic normalization. And: is the ε-dependent
   apparent singularity −9−23ε−3x+3εx = 0 on the balanced slice a
   defect that must be removed (it is not a letter of an ε-form) —
   which balance removes it, or does the constant-gauge solve remove
   it automatically because it is only apparent?

Q4 (class 79, quadratic locus). Concretely, in Mathematica-implementable
   formulas: (a) how to perform integer-offset balances at an
   irreducible quadratic locus q(x)=0 while staying rational over
   Q(ε)(x): rank-2 projector onto the q-adapted invariant subspace with
   a q(x)^{±1} shear (moves both conjugate exponents by 1 and ∞ by 2 on
   that subspace — matches our {2,1,1} at ∞ vs a missing {−2,−1,−1}
   pattern?), or work over the extension with Galois-symmetric choices,
   or CANONICA at higher ansatz degrees, or Libra's own mechanism (does
   Libra's Balance accept algebraic points)? (b) The cheapest test that
   tells WHICH quadratic factor hosts the hidden offsets when residues
   can only be evaluated at rational points (Fuchs sum per irreducible
   factor via resultants? q-adapted trace integrals?). (c) Alternatively:
   is there a better second chart for 79 in which all offset loci become
   rational points, and how would we search for it systematically?

Q5 (efficiency / alternatives, all three classes). Judge, with a
   decisive first test each: (a) running Libra's own Fuchsify → Normalize
   → Factorize with the spectator y kept symbolic (does Libra work over
   Q(y,ε)?), instead of our slice-and-replay; (b) continuing the
   two-variable CANONICA on the normalized pair (was 35 min in at
   ansatz (2,2,2,2) with no expression swell); (c) the INITIAL algorithm
   (Dlapa–Henn–Wasser, dlog-integrand ansatz over the known 5–7-letter
   alphabet) or DlogBasis, given we now know the letters exactly;
   (d) Fuchsia / epsilon (Prausa) as independent normalizers; (e) for
   77/79 specifically, is there a shortcut from the KNOWN class-97
   ε-form (same chart, similar alphabet {x,1−x,x±y,…}) — e.g. checking
   whether 77 is a Galois/chart-symmetry image or a shifted-alphabet
   relative of 97 — before doing the full normalization?

Q6 (after 173/173). For these three chart-classes specifically: the
   whole family must then be transported in chart variables (v,w
   rational in x,y, so subsector letters pull back rationally, but the
   physical chamber and the sign of sqrt(λ) = x−y select a branch).
   Any standard pitfall in transporting a mixed family (chart block +
   (v,w) subsectors) — chamber choice, path through x=y, letters that
   become perfect squares? And for boundary constants: the regularity
   conditions at chart-image loci (x=y is a spurious locus for the
   physical masters) — is "regularity at x=y fixes k constants" the
   right first move, and how do we count k from the residues above?

Q7 (two-track setup). Given the ε-form route is close for 97, is the
   ε-graded VECTOR-frame route (currently being run in parallel on 77
   with lower-sector sources, ~hours per ε order) still worth finishing
   as an independent derivation, or should the cross-check be
   AMFlow numerics at physical points only? Where exactly does the
   ε-graded output (per-order towers) add information the ε-form
   solution does not — e.g. for the unexpanded endpoint modes?

Q8 (endpoint modes). With an ε-form in chart variables, the endpoint
   w → 1 is 1−w = x + y − xy → 0 and the soft surface 1−v−w =
   x + y − 2xy → 0. Standard way to extract the UNEXPANDED Frobenius
   modes (1−w)^(aε+m) from the canonical solution (local exponents from
   the residue matrices at the pulled-back locus, then Frobenius
   resummation)? Any tool that does this mechanically for GPL solutions?

Please rank Q1/Q3/Q4/Q5 by expected wall-clock to a certified ε-form
for each class, and say what you would run first tonight.
