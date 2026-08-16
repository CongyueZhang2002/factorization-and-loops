# Review request: three non-canonicalizable master-integral classes — is there a faster route?

You are asked to critically assess a solution strategy for the last three
differential-equation classes of an NNLO double-real master-integral
computation, and to propose faster alternatives (community tools or your
own ideas). Everything below is measured/certified unless marked open.

## Setting

pp -> h+X at NNLO, double-real emission. 347 master integrals in 91
families satisfy first-order coupled DE systems in two dimensionless
kinematic variables (v,w) with dimensional regulator eps. The 1119
irreducible diagonal blocks fall into 173 equivalence classes; 170 have
exact validated eps-forms (Henn canonical: dF = eps sum_a R_a dlog
phi_a F, GPL solutions standard). Three 4x4 classes resist:

- class 97 (rep CF258_B9), class 77 (CF230_B1): "Kallen classes" —
  their alphabets contain sqrt(lambda) with lambda = (1-v-w)^2 - 4vw;
- class 79 (CF231_B1): carries its own quadric Q = 1+2v+v^2-2w+2vw+w^2.

Physical target: analytic solutions as generalized polylogarithms (GPL/
hyperlogarithms) to a fixed eps depth (set by a depth budget: target
order + regulator shifts + IBP-coefficient poles), plus boundary
constants, plus UNEXPANDED endpoint Frobenius modes (1-w)^(a eps+m) for
plus-distribution extraction. Numerics only as independent checks.

## Established structural facts (exact)

1. All three operators (after cyclic-vector scalar reduction to one
   4th-order ODE in one variable, second variable spectator) are
   IRREDUCIBLE at generic eps: no right factor of order 1, 2 or 3.
   Evidence: ore_algebra (van Hoeij type) factorization at two
   independent rational specializations of (parameter, eps) per class,
   with positive controls; for class 97 additionally an exact symbolic
   Beke exhaustion at order 1. So no eps-form via factorization ladders;
   CANONICA and Libra (balances/Moser) time out with admission met (in
   the ORIGINAL chart — see open question Q2).
2. At eps=0 every operator factors COMPLETELY into four first-order
   pieces. Exact symbolic factor chains are certified for all three
   (recomposition identities). For 77/79 this required rationalizing
   charts first: raw-chart third factors carry HALF-INTEGER residues
   (-3/2) on quadratic loci — the eps=0 solutions live on the sqrt
   cover. Charts: 97/77 share v=xy, w=(1-x)(1-y) (sqrt(lambda)=x-y);
   79 uses w = -t(1+t+v)/(1+t) making sqrt(Q) rational (verified).
3. Reconstruction subtlety: the cyclic covector stack degenerates at
   eps=0 (det ~ eps); its symbolic inverse has 1/eps poles, so vector
   eps-orders draw on scalar orders one deeper, and one kernel
   direction per class (so far) is an eps-rescaled Laurent family.

## Our route (implemented, certified)

eps-graded recursion ("Frobenius in eps"): grade the monic scalar
operator L = L0 + eps L1 + eps^2 L2; solve L0 f_n = -(L1 f_{n-1} + L2
f_{n-2}) by four anchored quadratures per order through the eps=0
chain. Engine: an Hlog word algebra (letters = rational functions of
the spectator; anchored at 0) with self-verifying primitives — the
community package HyperIntica was found to return HALF the true
primitive on pure-zero words (Log powers) in every available version,
so every package call is certified by an exact derivative identity and
routed to our own by-parts recursion on failure; quadratic letters are
handled by exact sqrt-root splitting where needed. Every order carries
an exact residual certificate (operator applied back, identically
zero). An independent parallel track (a second assistant) verified our
class-97/77 residuals with its own implementation.

Status and measured cost per class (single kernel):

- 97: scalar continuations through eps^3 (0.15 s / 94 s / 785 s per
  order); all four kernel elements continued through eps^2; two-variable
  completion: order-0 y-connection Gamma extracted exactly (pure dlog in
  {y, 1-y}, triangular), kappa0 closed forms verified, order-1 frame
  connection Omega1 extracted exactly (x-independence = integrability
  certificate). Remaining: kappa1 quadratures (kappa_n' = Gamma kappa_n
  - sum_j Omega_j kappa_{n-j}), Omega_2/3 (needs kernel depth 3),
  boundary constants, endpoint modes, AMFlow check.
- 77: same machinery through its chart; scalar eps^3 certified; all four
  kernels eps^2; order-0 y-connection extracted. Remaining: as 97.
- 79: scalar eps^2 certified (1.9 s then 68 min per order — the heavy
  one; eps^3 est. ~9 h in this gauge); kernel continuations 3/4 done at
  ~5.3 h each; y-completion pending. Its clean gauge is the v-direction
  reduction; the t-direction chain has an apparent irreducible cubic in
  its integrating factors (unusable without cubic-root letters).

Two-variable completion method: reconstruct vector solutions via the
Laurent-graded covector inverse, certify the x-system order by order,
then extract the moving-frame connection Omega(y,eps) =
Psi^{-1}(Ay Psi - d_y Psi) order by order via exact word-basis
projection; kappa' = -Omega kappa pins the y-functions up to true
constants (= boundary data). Parameter-derivatives of Hlog words use
the Goncharov total-differential formula (certified by mixed-partial
identities).

## Known cost pain points

- Per-order cost grows ~8x per eps order in our representation; class
  79's 68-minute order is the bottleneck. The parallel track's sparse
  word representation measured ~15x faster on class 97's low orders.
- Kernel-element continuations (words as seeds) cost multiples of the
  seed-mode solve.
- Everything downstream (Omega_n, kappa_n) reuses those continuations,
  so scalar-depth extensions dominate the budget.

## Questions for you

Q1. Is there a fundamentally faster route we are missing for
    irreducible-at-generic-eps but eps0-completely-reducible 4x4
    two-variable systems? Candidates we want your judgment on:
    (a) solving the SYSTEM (not a scalar reduction) eps-graded with
        matrix variation of constants around the eps=0 fundamental
        matrix (avoids covector Laurent poles entirely?);
    (b) FiniteFlow/finite-field reconstruction of the rational data in
        the recursion (Peraro) to kill the swell;
    (c) symbol/coproduct-level bootstrap: fix the weight-n symbol over
        the known alphabet from differential constraints, then match
        boundary — alphabet is known and small (5-7 letters/class);
    (d) series solutions along lines (DiffExp/SeaSyde class) + exact
        reconstruction, given we need symbolic output;
    (e) anything from the elliptic/Calabi-Yau community for
        eps-degenerate towers (Primo-Tancredi style with certified
        quadratures) that automates the two-variable completion.
Q2. We never re-ran CANONICA/Libra ON THE RATIONALIZED CHARTS (the
    charts were found later). Given the alphabets become rational
    there, is a retry of a global eps-form search in-chart worth the
    compute, or does generic-eps irreducibility already doom it?
    (Our understanding: irreducibility does NOT preclude an eps-form —
    eps-forms need no factorization — so this may be a real gap in our
    reasoning. Assess.)
Q3. For the endpoint data: we plan exact resummation of the eps-graded
    log towers onto the local Frobenius modes using the exact indicial
    exponents. Standard? Better tool?
Q4. Boundary constants: the systems' <=33 candidate periods are being
    evaluated separately (Mellin-Barnes/HypExp/asy toolchain). Any
    shortcut specific to Kallen-type 4x4 blocks (e.g. known closed
    forms for the homogeneous-solution normalizations at v->0/w->1)?
Q5. Sanity-check the depth-budget logic: masters enter the observable
    against 1/eps^k prefactors (measure + IBP + subtraction), so
    per-ingredient depth = target + max pole it multiplies; the
    reconstruction adds +1 (Laurent pole). Anything we're missing that
    would change the required depth by more than one unit?

Be specific: name packages, papers, or algorithms, and give the
decisive test we should run first for any alternative you propose.
