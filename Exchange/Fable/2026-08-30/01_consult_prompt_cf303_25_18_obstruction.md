# Consult prompt: CF303 block (25,18) — a proven completion obstruction; how to proceed

(Provenance: written 2026-08-30 by the working Fable session for a
fresh-context consult; reply to be saved beside this file. The measured
facts below are from Codex exchange notes 01-07 of 2026-08-30 and their
saved artifacts.)

---

You are consulted as an expert in Feynman-integral differential equations,
canonical forms, twisted cohomology, and the algebraic geometry of
kinematic covers. This is a fresh-context consult: everything you need is
below. Give ranked, concrete recommendations, distinguish proven
statements from suggestions, and name the relevant literature precisely.

## Context

NNLO hard function for pp -> h+X, double-real channel: 347 masters in 91
families of first-order coupled differential equations in two variables
(v, w) and the regulator eps. 88 families have certified eps-forms. Of the
3 "triple-root" families (three simultaneous square roots), CF300 is now
fully certified and CF259 is nearly done. CF303 is complete EXCEPT one
2x2 off-diagonal block, (25, 18), where we have — for the first time in
the campaign — a machine-verified obstruction rather than an unfinished
computation.

Working frame for this block: its two active roots are rationalized by an
explicit chart (the third family root does not appear in the block's
entries), so the block is treated as a rational-function problem in chart
variables (x, y). The completion contract: find a gauge transformation G
so that the completed off-diagonal entry becomes a sum of residues times
dlog(letter), letters regulator-free, residues may depend on eps; a
family-level constant transformation afterwards produces the eps-form,
and one family certificate asserts it.

Fixed data of the block: both diagonal connections are eps-independent
and flat (verified). Six lower blocks (19..24) feed the same rows. The
a-priori gauge denominator (from a valuation census) has numerator total
degree 58 and denominator degree 56; the certified support is 1,770
monomials per gauge entry, 4 entries, so 7,080 gauge unknowns, plus 48
candidate letters x 4 residue slots = 192 residue unknowns, 7,272 total.

## The measured no-go chain (each step survived independent verification)

1. **Assembly is correct.** The optimized finite-field equation rows were
   compared entry-by-entry against an independent raw-PDE oracle (shares
   no code with the packed evaluator) at three points: exact equality of
   all rows and right-hand sides.

2. **The fixed dlog targets are unreachable by ANY gauge.** A
   gauge-eliminated integrability screen (52 generic chart points; system
   208 x 192 for the 48-letter target, 208 x 64 for the 16 polar-factor
   dlogs) has rank 188 vs augmented rank 189 (resp. 60 vs 61) — defect
   exactly 1 — at two configured and one fresh (prime, eps) image. The
   witness rows replay exactly. Because the gauge is eliminated, no
   rational, algebraic, or transcendental gauge can reach these targets.

3. **The letter divisor is geometrically complete.** All 16 affine polar
   factors (degree multiset 1^6, 2^4, 3^6) are absolutely irreducible
   (Maple evala(AFactors) and Singular absFactorize agree); the
   projective divisor is these 16 closures plus the line at infinity, and
   infinity contributes only the projective residue relation. So the 16
   component dlogs already span every rational logarithmic direction
   supported on the known pole divisor: there is no hidden component to
   add a letter for.

4. **Every CLOSED rational target fails inside the certified gauge
   space.** Eliminating the target basis entirely, the closedness
   equation for the gauged forcing (E_x d_y G - E_y d_x G + d_x G C_y -
   d_y G C_x = curl(F)/eps) was sampled at 1,800 generic points: system
   7,200 x 7,080, rank 7,076, augmented rank 7,077 — defect exactly 1 —
   at eps = 1, 3/17, 9, with one shared coefficient elimination. This
   closes strict dlog, polynomial exact-form additions (dH), principal
   rational shells, and every other closed rational target at once,
   within the degree-58 / denominator-degree-56 gauge space. The
   cokernel of this system is 124-dimensional.

5. **A compact certificate exists.** On the captured full system
   (7,280 x 7,272; 38,991,680 nonzeros): rank 7,268, augmented 7,269; a
   sparse left-null witness y on 7,269 rows replays exactly in a second
   system: y^T A = 0 and y^T b = 615,978,110 != 0 mod 2,147,483,423 at
   eps = 1/11.

6. **Side exits already excluded.** (a) The 26 residual gauge directions
   of the six feeder blocks are exactly terminal residue redefinitions
   (checked against explicit constant bases at a fresh prime); they
   cannot alter the obstruction, so a coupled multi-row solve gains
   nothing. (b) Splitting sampled forcing numerators into
   irreducible-factor dlogs is not an enlargement: at a numerator-only
   divisor, strict dlog forces zero total residue, and what survives lies
   in the span of the 16 polar dlogs. (c) A first apparent repair by
   polynomial exact forms ({dx, dy, d(x^2)} spans the 12-dimensional
   full-system cokernel in projection) failed the real functional test:
   the honestly overdetermined solver (7,296 x 7,284) is inconsistent.

7. **The defect is stable.** Dimension exactly 1 at every prime and
   every regulator value tried, wide (61-bit) and fresh primes included.

## What is NOT yet excluded

i.   Larger gauge valuation bounds: extra powers of the divisor
     components or extra infinity degree beyond the census bounds
     (resonant homogeneous modes). The census bounds are saturated by
     the current ansatz but their exhaustiveness is an assumption of
     the no-go, not a theorem we possess.
ii.  Changing the preceding diagonal canonical normalization: both
     diagonal blocks are eps-independent; a different eps-form gauge for
     them changes the coefficients (E, C) of the obstruction equation.
     Unknown to us: whether the obstruction class is invariant under
     such renormalization.
iii. Algebraic targets: one-forms carrying the family's third square
     root (inactive in this block's entries) or deck-orbit images of
     existing letters on the triple cover. Every screen above was
     rational-in-the-chart; algebraic candidates were never in the span
     tested. (An earlier consult on these families warned that a
     deck-incomplete alphabet is exactly the mechanism that preserves
     per-eps solvability while blocking low-degree completion.)
iv.  An algebraic gauge TOGETHER with an enlarged algebraic target
     (excluded only for the fixed rational targets of item 2).
v.   Abandoning strict form for this one entry: an eps-factorized
     non-closed off-diagonal one-form (transport recursion still
     applies), with the family certificate qualified accordingly; or
     high-precision numerical transport for this block as the insurance
     route, exact everywhere else.

## Questions, in priority order

A. **What IS this obstruction, structurally?** A stable one-dimensional
   defect against all closed rational completions, with a geometrically
   complete divisor and saturated valuation bounds. Is the right frame
   twisted/relative cohomology of the divisor complement (the C-terms
   twist the differential), so that the defect is a nonvanishing twisted
   class carried by the forcing? If so: does a nonzero class have a
   standard meaning — e.g. the extension of the two diagonal modules is
   non-split in the dlog category — and is there a canonical invariant
   we should compute once, exactly, to characterize it? Please
   distinguish: which of the escapes (i)-(v) can even in principle kill
   a nonzero class of this kind, and which are provably hopeless given
   the facts above (as the letter-enlargement route already proved to
   be)?

B. **Resonance and the valuation bounds (escape i).** Is there a finite,
   decidable local analysis — indicial exponents of the diagonal systems
   at each of the 17 projective components, integer-difference
   resonances — that yields the EXACT list of admissible extra divisor
   powers / infinity degrees, so that escape (i) is settled by one
   bounded computation instead of an open-ended cap ladder? Name the
   algorithm and any implementation (Moser/Levelt reduction per
   component, local Fuchs relations, or the analogue you recommend).

C. **The cheap oracle we should exploit.** The left-null witness y gives
   an O(1) test per candidate: pair y (or the 124-dimensional closedness
   cokernel) with any proposed new column — extra-valuation gauge
   monomials, algebraic one-forms, deck images — before any solve. Do
   you endorse witness-pairing as the primary discriminator, and in what
   order should candidate families be fed to it? Rank: resonant gauge
   monomials; deck-orbit images of the 16 letters under the third-root
   involution; one-forms odd under that involution built from the
   triple; anything else you expect to span the class. (Note the
   functional trap we already hit: spanning the cokernel in projection
   is necessary, not sufficient — every candidate that passes pairing
   must then pass an honestly overdetermined solve.)

D. **Diagonal renormalization (escape ii).** Is the obstruction class
   invariant under changes of the diagonal blocks' canonical gauges (in
   which case escape ii is provably dead and we should not spend on
   it), or can a different eps-form normalization of eps-independent
   diagonal connections genuinely split the extension? A proof sketch
   either way decides a workstream.

E. **If the block is genuinely not dlog-able (escape v).** What is the
   community-standard target class and acceptance statement for an
   eps-factorized but non-dlog entry (closed fails too, so: rational
   one-form kernels with polynomial-potential pieces? something on the
   K3 geometry of the triple cover?), and what must this block deliver
   so that downstream needs survive: transport recursion, the endpoint
   modes exact in eps (plus-distribution content), and an honest family
   certificate ("eps-form on all blocks except (25,18), which carries
   X")? Is single-block high-precision numerical transport with exact
   boundary data a defensible published endgame for one 2x2 entry of
   one family at NNLO, and what precision/validation standard applies?

F. **Literature.** Precedents for: completion obstructions of this type
   and their cohomological identification; resonance conditions under
   which dlog spans exhaust twisted cohomology (Esnault-Schechtman-
   Viehweg and successors); eps-factorized non-dlog forms (elliptic and
   Calabi-Yau families; Goerges-Nega-Tancredi-Wagner and related);
   apparent-singularity additions to alphabets; intersection-theory
   methods (Mastrolia-Mizera) for computing the class we describe.

Answer format: ranked recommendations per question with one-paragraph
justifications; separate proven from suggested; flag anything you
believe is provably impossible given facts 1-7; name literature
precisely. Assume unlimited cheap modular sampling, the witness-pairing
oracle above, and a competent implementation team; do not write code.
