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
5. Paradox: the equations are nearly eps-free. The E and C coupling
   matrices, the one-forms, and the roots are eps-independent; eps enters
   only through one denominator factor Q, linear in eps. Multiplying each
   equation by Q^2 should give polynomial coefficients of eps-degree at
   most 2-3 (this specific bound is not yet verified — it is the next
   measurement).
6. The current plan (the other assistant, Codex): assemble the Q^2-scaled
   original equations, confirm the low coefficient degree, then compute a
   minimal-degree basis of the solution module over F_p[eps] (shifted
   Popov / minimal approximant basis, block-Toeplitz structure), accepting
   only on disjoint regulator values, the original-row residual, and a
   second prime.

## Questions, in priority order

A. **The eps-degree paradox.** What mechanisms can make the minimal
   rational-in-eps degree of a solution-manifold section exceed 64 when
   the defining equations (after Q^2 scaling) have eps-degree <= 3 and
   nullity 52? Is the minimal-basis plan in (6) the right tool, or would
   you recommend: fraction-free symbolic elimination in eps directly;
   Smith/Hermite normal form over F_p[eps]; a reformulation where the
   known Q-structure is factored out of the ansatz analytically
   (e.g., unknowns = Q^m times new unknowns); or an eigenvalue-style
   decomposition of the eps-dependence? What degree should we EXPECT for
   the minimal section of a degree-3 polynomial system of this size, and
   is there a theorem bounding it (e.g., via minors: degree <= rank x
   coefficient degree ~ 6,600 — is the observed >64 simply genuine and
   moderate on that scale)?

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
