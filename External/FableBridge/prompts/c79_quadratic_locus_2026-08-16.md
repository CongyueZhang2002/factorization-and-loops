# Consult: removing integer exponent offsets at an irreducible quadratic locus

Self-contained. Context: one-variable 4x4 Fuchsian system A(x, eps),
rational over Q(eps), obtained by restricting a two-variable
master-integral connection to a numeric slice and Fuchsifying all
points. We are normalizing it toward an eps-form (all residue
eigenvalues proportional to eps) by Lee-style balances
(Balance[P, {x, x1, x2}] with rank-1 projectors built from the right
eigenvector at the lowered point and the left eigenvector at the
raised point), then finishing with CANONICA's rational ansatz.

Measured state after Fuchsification and three successful balances:

- All residues at LINEAR-in-x loci have integer + integer*eps
  eigenvalues; the remaining nonzero integer offsets are
  {0, 2+3eps, 1, 1+eps} at infinity (integer parts {0,2,1,1}).
- The trace identity requires the sum of integer parts over ALL loci
  to vanish, but the visible sum is +4. Therefore offsets totalling
  -4 sit at loci our census does not see. The only denominator
  factors not scanned are irreducible QUADRATICS in x (the census and
  the balance machinery only handle linear factors, i.e. rational
  points).
- Balancing infinity against any linear locus only trades offsets
  back and forth (plateau) — consistent with the true partner being
  the quadratic locus.

Questions:

1. What is the standard way to perform integer-offset balances at an
   irreducible quadratic locus q(x) = 0 while staying rational over
   Q(eps)(x)? Options we see: (a) a "conjugate-pair balance" with a
   projector-valued transform T = 1 - P + c(x) P where c is a degree-1
   rational function with divisor supported on the two conjugate
   roots (i.e. c = l(x)/l~(x) with l a factor of q over the
   extension... which is NOT rational — so what is the rational
   version?); (b) work over the quadratic extension, balance each
   conjugate root, and verify the composite transform is rational
   (Galois-symmetric choices); (c) a polynomial "shear"
   T = 1 - P + q(x)^{+-1} P which shifts BOTH conjugate exponents by
   1 simultaneously and the infinity exponent by 2 on that subspace.
   Assess each; (c) looks like exactly our {2,1,1}-at-infinity vs
   {-2,-1,-1}-at-quadratic situation (the 2 pairs with the 2-shift?).
2. Does Lee's Libra handle balances at algebraic points natively
   (Balance with x1 given as a Root/quadratic), or is the q(x)-shear
   the intended mechanism?
3. CANONICA's rational ansatz sees quadratic loci natively. For a 4x4
   with ~6 linear letters plus one quadratic letter, is its
   eps^1-order linear solve expected to take >> 30 min at ansatz
   degrees (2,2,2,2), and is raising TDelta/DDelta degrees or
   pre-shearing with (c) the better lever?
4. Name the decisive cheapest test to identify WHICH quadratic factor
   hosts the hidden offsets, given we can compute residue matrices
   only at rational points (e.g. evaluating q-adapted trace integrals,
   or the Fuchs-sum per irreducible factor via resultants).

Answer with formulas concrete enough to implement in Mathematica
directly. Flag anything in our setup that looks wrong.
