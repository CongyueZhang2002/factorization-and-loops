# Consult prompt for Fable Max: how to proceed on the triple-root families

(Provenance: written 2026-08-28 by the working Fable session for a
fresh-context consult; reply to be saved beside this file.)

---

You are consulted as an expert in Feynman-integral differential equations,
computer algebra, and the algebraic geometry of kinematic covers. This is a
fresh-context consult: everything you need is below; a git link to the
repository is attached for detail, but please reason from this summary
first. Give ranked, concrete recommendations, distinguish proven statements
from suggestions, and name the relevant literature.

## Context

NNLO hard function for pp -> h+X, double-real channel: 347 master
integrals in 91 families of first-order coupled differential equations in
two dimensionless variables (v, w) and the dimensional regulator eps.
88 of 91 families have certified eps-forms (dF = eps sum_a R_a dlog
phi_a F, exact reconstruction checks). The remaining 3 — CF259, CF300,
CF303 — are "triple-root" families: the connection involves three
simultaneous square roots.

Root triples:
- CF300 and CF303 (identical triple): sqrt of
  (1+v-w)^2 + 4vw,  (1-v+w)^2 + 4vw,  1 - 4vw.
- CF259: sqrt of
  (1-v-w)^2 - 4vw,  (1-v+w)^2 + 4vw,  4v + w^2.

Each root ALONE is rationalizable (conics; we have explicit charts). Every
PAIR we need is rationalizable (joint charts exist and solved 13 two-root
families). Whether the TRIPLE cover z1^2 = P1, z2^2 = P2, z3^2 = P3 admits
a rational parametrization in two variables is open for both triples.

Current working frame: no chart is assumed; the solver works in the
function field of the triple cover, organized by the deck group (Z/2)^3
into 8 grades. The unit of work is one off-diagonal block: complete block
(k, j) of a family to dlog form via an ansatz gauge transformation with
unknown constant coefficients per regulator value. The concrete hard block
(CF300, sector 12, lower sector 9): 2,260 unknowns (2,048 gauge = 64
support monomials x 2x2 matrix x 8 grades, plus 212 residue coordinates),
affine system of rank 2,208 and nullity 52, 53 simultaneous right-hand
sides, sampled at 37 kinematic points per regulator value over 31- or
61-bit prime fields. Per-image cost is now ~4 s after native-code work, so
assume modular data is cheap.

## The measured impasse (all statements below are measured, with planted
## self-checks, two independent fitters, and confounds excluded)

1. At every regulator value eps the affine system is solvable with exact
   residuals; the solution manifold has dimension 52.
2. The 1,076 coordinates NOT touched by the 52-dimensional freedom are
   CONSTANT in eps (1,024 constants + 52 pinned zeros).
3. The 1,184 coordinates touched by the freedom admit NO rational-in-eps
   representative through TOTAL degree 64, measured on 76 images at one
   fixed set of 37 kinematic points, at two prime widths, surviving:
   pointwise canonical sections, 18 coordinate-order policies, 8 mixed
   evaluation sections, per-column projective normalization, Schur
   elimination to a 160x53 residue frame, quotient by the common
   36-dimensional homogeneous kernel, and a global common-denominator
   ansatz (the last excludes only a common denominator, not
   coordinate-dependent denominators).
4. Solved sibling blocks in the two-root families (rational charts) have
   total eps-degrees 9-13 and needed 17-22 images and 10-22 primes of
   31 bits. Degree > 64 here is anomalous relative to every solved case.
5. Resolution of the input side (measured 2026-08-28 ~02:30): after
   scaling by the known eps-carrying factor Q, the equations ARE
   low-degree. The 2368 x 2260 matrix A(eps) is POLYNOMIAL in eps of
   degree exactly 3 (validated at held-out regulator values, zero
   mismatches). The 888 nontrivial right-hand-side entries are low-degree
   RATIONAL functions of eps: (numerator, denominator) degrees (7,6) for
   518 entries, (8,7) for 222, (5,4) for 148, and 1,480 entries are zero
   — held-out validated, no failures. So: explicitly known low-degree
   equations, yet no solution section through degree 64.
6. The converged plan (the other assistant, Codex, independently endorsed
   by a second outside consult): compute a shifted minimal right kernel
   basis (syzygy basis) of the augmented polynomial matrix
   M(eps) = [A(eps) | -b(eps)] over F_p[eps], recovering rational
   solutions x = u/v from polynomial kernel vectors; never invert a large
   square minor first. Acceptance: disjoint regulator values, the
   original-row residual, and a second prime. Known caveat: degree-3
   input does not bound the output degree — generic determinantal bounds
   allow thousands.

## Questions, in priority order

A. **The eps-degree question, now sharp.** Given the explicitly known
   M(eps) = [A(eps) | -b(eps)] with A polynomial of degree 3, b rational
   with degrees at most (8,7), rank ~2,208 and solution-manifold
   dimension 52 at generic eps: what minimal kernel degree should we
   EXPECT (worst case ~ rank x 3 ~ 6,600 via minors; is the measured
   ">64 in every section tried" simply genuine and moderate on that
   scale)? Is the shifted minimal kernel basis the best tool for
   2368 x 2261 at these degrees, or would you order the alternatives
   differently: x-adic/Newton iteration solvers for polynomial systems,
   Smith/Hermite form, fraction-free elimination, or factoring the known
   Q-structure out of the ansatz analytically (unknowns = Q^m times new
   unknowns) to lower the kernel degree before computing it? If the
   minimal degree really is in the hundreds-to-thousands, what does that
   say PHYSICALLY about the dlog-completion ansatz — in particular,
   should a huge minimal degree be read as evidence that the ansatz
   alphabet is missing letters (question D) rather than as a property of
   the true completed block?

B. **Rationality of the triple cover.** For the two root triples above:
   is there a practical decision procedure for rationality of the
   variety z_i^2 = P_i(v,w), i = 1..3 (conic-bundle structure, del
   Pezzo / quartic classification, unramified covers)? Relevant work:
   Besier–van Straten–Weinzierl on rationalizing square roots,
   Festi–van Straten on double covers in Feynman integrals. If deciding
   rationality is hard, is a PARTIAL chart (rationalize 2 roots, carry
   the third algebraically — reducing 8 grades to 2) clearly better than
   the current fully-algebraic frame, and what should guide the choice of
   which pair to rationalize?

C. **Strategy.** Given the physics target is NNLO phenomenology (the
   masters feed an endpoint expansion and assembly; depth budget known),
   rank these end-games for the 3 families: (i) push the eps-form via the
   module route; (ii) accept a dlog form with algebraic letters and
   regulator-dependent residues, deferring eps-factorization to the
   family-level constant transformation already in the pipeline;
   (iii) abandon canonical forms for these 3 families and use
   high-precision numerical transport (AMFlow/DiffExp-style) with exact
   boundary periods; (iv) hunt the global rational chart first (question
   B) and rerun the cheap rational-chart machinery. Include effort
   estimates and failure modes.

D. **Sanity checks we may have missed.** Anything about the setup that
   strikes you as a likely formulation defect producing artificial
   degree inflation — in particular the interaction of nullity 52 with
   grade structure, or the choice of 37 kinematic points, or the
   possibility that the block's dlog completion genuinely requires
   letters we have not included (the ansatz alphabet has 68 letters:
   8 diagonal, 32 forcing, 8 rational-factor, 20 algebraic).

Answer format: ranked recommendations per question with one-paragraph
justifications; flag anything you believe is provably impossible; name
literature precisely. Assume unlimited cheap modular sampling and a
competent implementation team; do not write code.
