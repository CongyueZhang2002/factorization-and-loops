# Fable -> Codex: assessment of the Fable Max consult and the distilled action list

> 2026-08-28 ~03:15. The verbatim reply is in
> 03_fablemax_reply_triple_roots.md. Verdict: high quality — one genuinely
> new theorem-level reframing, two concrete defect hypotheses we had not
> considered, a geometry verdict that is checkable in days, and a strategy
> ranking consistent with our existing contract. One of its two repo-level
> uncertainties I have already resolved (below). This note extracts what
> to act on and in what order.

## The reframing that changes how we read our own no-goes (A0 — correct)

Rank[A|b] = rank A = 2,208 at 76 regulator values over two prime widths
implies solvability over the rational function field: **a rational-in-eps
solution provably exists**, with degree bounded by ~3 x 2,208 ~ 6.6e3
(Cramer on any fixed nonsingular minor). Every section policy we tried IS
a rational section — of some degree in (64, 6600]. What none of them can
measure is the MINIMAL degree, because the minimal section differs from
any fixed-coordinate policy by eps-dependent combinations of the 16
eps-varying kernel directions. So our no-go series never contradicted
existence and never measured minimality. On the 6.6e3 scale, ">64" is 1%
of the allowed range. Caveat to close: the Schwartz-Zippel argument wants
random eps samples; ours were structured — re-verify the rank statement
at ~20 random eps values (minutes).

## Repo-level fact resolved: the kinematic points are safe at source

The consult's top worry (D1, first branch): if the 37 points came from a
parametrized curve on which all three P_i are simultaneously squares,
every downstream degree statement is void. Checked in source
(`MultiquadraticStripSolve.wl` ~3172/3981): points are
`RandomInteger[{2, p-2}, 2]` with rejection requiring
`JacobiSymbol[P_i, p] == 1` for all roots — independent rejection
sampling, exactly the safe scheme the consult prescribes. The second
branch of D1 remains live and cheap: a `BlockRandom` seed could still
share one point set across all measurements, so the fresh-disjoint-set
and 74-point stability re-probes (rank 2,208 and nullity 52 must
survive, including the 16 eps-varying kernel directions) are still
mandatory, plus the in-vitro control: re-measure one solved two-root
sibling at the same ~5% overdetermination and confirm its degrees stay
at 9-13.

## Action list in the consult's cost-ordered spirit, adjusted to our state

1. **D1 (today, minutes-hours):** fresh random point set; 74-point
   variant; rank/nullity/kernel-direction stability; solved-sibling
   control at matched overdetermination; random-eps rank confirmation.
2. **D3 (half day):** deck-orbit closure of the 20 algebraic letters
   under the seven nontrivial involutions of (Z/2)^3 — the images' dlogs
   must lie in the Z-span of the 68. Since our algebraic letters were
   carried over from the solved two-root families, truncated orbits are
   a live risk, and a truncated orbit is exactly the mechanism that
   keeps per-eps solvability while inflating minimal eps-degree
   (the completion imitates missing letters with high-degree
   coefficients). Also: polar-divisor coverage of the input block by
   letter zeros/poles.
3. **D5 (cheap):** predict the 36-dimensional constant kernel as the
   constant intertwiner space of the two diagonal blocks (bookkeeping
   check), and compute the minimal indices of the 16 eps-varying kernel
   directions of A alone — a smaller homogeneous kernel-basis run that
   brackets where the solution degree can live.
4. **D4 (a day, after D3 passes):** Fourier-split the system over
   (Z/2)^3 into eight ~296x283 character blocks. Kernel bases per block
   cost minutes; the pathology localizes per character; cross-tabulate
   the 1,076/1,184 split and the 36/16 kernel split against grade
   labels — clean alignment would indicate a missing per-grade
   normalization Q^{m_g}. Failure to split at all is itself a grade-
   arithmetic bug detector.
5. **A3 preprocessing before the big run:** factor b's denominator
   classes (7,6)/(8,7)/(5,4) into their (a eps + b) factors and absorb
   them into the ansatz per column/per grade so b becomes polynomial;
   additive-degree effect only, but it aligns the normalization with
   the solved siblings.
6. **A1 (the main run):** shifted minimal kernel basis of
   [A | -b-cleared] over F_p[eps] — PML (github.com/vneiger/pml,
   Hyun-Neiger-Schost ISSAC 2019) over our 61-bit primes, adaptive
   order doubling; then reduce the solution modulo the 52 homogeneous
   minimal kernel vectors. Cross-check with **A2**: Dixon lifting on one
   fixed 2,208-minor at a shifted eps, rational reconstruction per
   coordinate — reuses our existing modular solver almost unchanged, and
   even the 6.6e3 worst case is ~15 h/prime of embarrassingly parallel
   images. Acceptance additions: polynomial identity at more eps-probes
   than the degree bound; a held-out kinematic point set; 200-300 images
   on any exclusion statement (D6).
7. **D2 (half day, gates the dlog target):** maximal-cut audit of
   sectors 12 and 9 on the triple cover (Baikov cuts; dlog-integrand
   construction). All leading singularities algebraic -> dlog stands and
   we get an independent per-grade check of Q. A non-algebraic period ->
   stop pushing dlog for these sectors (consult C4; eps-factorized
   non-dlog forms or numerical transport carry the physics).

## Consult predictions worth recording (suggested, not proven)

- The minimal section will land at sibling scale (<= ~30); the tell is
  the exact eps-constancy of the 1,076 untouched coordinates.
- Defect likelihood ordering: kinematic-point structure (now largely
  excluded at source), deck-incomplete alphabet, per-grade
  normalization, support truncation — genuine hugeness last.
- Physics likely polylogarithmic with algebraic letters even if the
  cover is unrationalizable (Heller-von Manteuffel-Schabinger Drell-Yan
  precedent, arXiv:1907.00491).

## Geometry and strategy (decisions for the user, recorded not started)

- **B0/B1:** both triple covers are expected to be K3 surfaces (pair
  cover = quartic del Pezzo; third root branched in |-2K|; smooth
  (2,2,2) in P^5 is a degree-8 K3) — hence PROVABLY no rational chart
  (Castelnuovo kills unirational too), pending a 2-5 day branch-
  singularity computation (RationalizeRoots first, then Castelnuovo
  q = P_2 = 0 / Schicho parametrization; Festi-van Straten
  arXiv:1809.04970 is the precedent). Time-boxed and worth doing once
  for the record — also a paper paragraph.
- **B2:** regardless of the verdict, a PARTIAL chart (rationalize the
  best pair, carry the third root as one quadratic extension: 8 grades
  -> 2, ~4x fewer gauge unknowns) transfers our entire two-root
  technology; calibrate pullback letter degrees on a solved sibling
  before refactoring. The consult's simplification of our triple —
  P1 = (1+v+w)^2 - 4w, P2 = (1+v+w)^2 - 4v, P3 = 1 - 4vw — is verified
  correct by direct expansion and makes the pair charts concrete.
- **C ranking (matches our existing contract):** primary = dlog with
  algebraic letters and eps-dependent residues, family-level
  factorization afterward — this is literally our off-diagonal-rung
  contract; the consult adds the pragmatic delta-adic series bypass at
  fixed eps-depth for the NNLO budget while the exact computation
  certifies. Parallel insurance = numerical transport of the three
  families (DiffExp/SeaSyde/AMFlow-style) — also the natural independent
  validation. Chart hunting strictly time-boxed at the B1 classification.

Production note: items 1-7 are diagnostics within the assigned work;
B1/B2/C2 are new work streams and start only on the user's explicit go.

— Fable, 2026-08-28
