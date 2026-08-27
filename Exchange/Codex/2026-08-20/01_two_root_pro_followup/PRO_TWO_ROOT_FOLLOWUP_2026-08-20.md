# FACET two-root epsilon-form follow-up

We need a concrete method decision for completing the remaining two-root
differential systems in an exact analytic NNLO QCD calculation.  Please inspect
the attached archive.  It contains exact certificates for the two newly solved
hard strips, solver scripts, current audits, your preceding review, and Fable's
independent assessment.

## Mathematical problem

After rationalizing the two square roots, the differential system is block
lower triangular.  Its diagonal blocks are already in epsilon form.  For an
off-diagonal strip we seek a rational matrix `R` and constant residue matrices
`K_a` satisfying both Pfaffian equations

\[
\partial_\mu R-
\epsilon\left(E_\mu R-RC_\mu\right)
=B_\mu-
\epsilon\sum_a K_a\,\partial_\mu\log W_a,
\qquad \mu=1,2.
\]

The current sharp solver first derives the full affine solution space of the
constant-residue compatibility equations.  It then solves a rational gauge
ansatz modulo several primes, retaining the residue parameters during the
finite-field solves, reconstructs in `epsilon`, lifts by Chinese remaindering
and rational reconstruction, and checks both equations exactly.

## New exact result: CF254

The Kallen-13 representative CF254 now has two consecutive solved strips.

* Strip `(9,8)` was solved earlier and its exact transformed-dlog identity is
  zero.
* Strip `(9,7)` is now solved by a `4 x 4` rational gauge with 17 affine residue
  parameters.  The sparse system had 1953 unknowns, rank 1937, and nullity 16.
  Its reconstructed gauge has denominator bidegree `(9,10)` and numerator
  bidegree `(10,10)`.  Five primes and 161 finite-field samples were used.
  The reconstruction contains 11,883 rational scalar coefficients.
* All 32 entries of the two exact symbolic Pfaffian residual matrices vanish.
  The exact check took 70.565362 seconds.
* Replaying the original CANONICA `NextEquationD` step from the preserved
  `(9,8)` checkpoint reproduces the `(9,7)` input byte-for-byte.  Both hashes
  are
  `fb20b26fd0b4a21bf7b79fe5e1ab4c31ef691d1a166571b500c4e57b13ff461f`.
* The solved `(9,7)` strip has been composed into the sector checkpoint, and
  the exact `(9,6)` strip input has been generated.

This is not yet a complete epsilon-form transformation of CF254.  The lower
strips, sector-level dlog-to-epsilon transformation, full-family composition,
flatness, and exact transformed-connection identity remain.

## New exact result: CF231

The Kallen-23 representative CF231 strip `(8,7)` is also solved exactly.  The
six-, seven-, eight-, and nine-prime lifts all failed exact rational-point
tests, but the ten-prime lift made those tests vanish and then made all 32
symbolic two-PDE residual entries vanish identically.  The reconstruction used

`{2147483423, 2147483477, 2147483489, 2147483497, 2147483543,
2147483549, 2147483563, 2147483587, 2147483629, 2147483647}`.

The residue compatibility space has 208 variables, rank 191, and nullity 17.
The rational-gauge solve has 1408 gauge coefficients and 1425 total affine
unknowns; every sampled system has rank 1409, augmented rank 1409, and affine
nullity 16.  The stable epsilon-degree census contains 820 coordinates of
degree `(3,8)`, 352 of `(2,7)`, 20 of `(1,6)`, 8 of `(0,5)`, 4 of `(1,7)`, 1 of
`(0,6)`, and 220 identically zero coordinates.  Final lifting took 0.36 s and
the exact symbolic closure took 9.43 s using four subkernels.  The obstruction
through nine primes was coefficient height, not a failure of the rational
strip equation.

As with CF254, this solves the first hard strip, not the complete family.

## Independent Fable assessment

Fable recommends testing exact cross-class Kallen involutions before further
interpolation.  Its suggested maps exchange Kallen-12, Kallen-13, and
Kallen-23 representatives by permutations of the physical channels, followed
by the corresponding chart pullback and a rational basis map.  It also points
out that the earlier Maple implementation discarded homogeneous affine
freedom.  Our finite-field solve now retains that freedom while solving, but
the installed CF254 checkpoint stores one normalized representative rather
than a parameterized affine family.

## Methods to rank

Please rank the following routes for the attached systems, and state the exact
acceptance criterion for each.

1. **Exact cross-class involution.**  Search for a differential-module
   isomorphism between the solved Kallen-12 or Kallen-13 systems and CF231/CF254,
   including the kinematic permutation, chart pullback, Jacobian, and rational
   basis conjugation.  This is cheapest if it exists.

2. **Full augmented Maple `IntegrableConnections` solve.**  Vectorize `R` and
   adjoin the affine residue parameters as constant components,
   \[
   Y=(\operatorname{vec}R,1,\kappa_1,\ldots,\kappa_N)^T,
   \qquad \partial_\mu Y=\mathcal A^{\rm aug}_\mu Y.
   \]
   Use `RationalSolutions` on the complete two-variable integrable connection,
   rather than a one-variable `Mratsolde` call followed by a second-equation
   check.

3. **Propagate the complete affine family down a block row.**  Instead of
   fixing one representative at `(9,7)`, retain the homogeneous parameters and
   solve all remaining source blocks in the row simultaneously.

4. **Targeted balance or another rational gauge.**  Apply a balance only at a
   divisor whose local exponents prove it is needed, while preserving the
   already normalized diagonal blocks.

5. **Continue the sharp modular method on lower strips.**  Reuse the measured
   divisor bounds, preserve the full affine residue space, and determine a
   coefficient-height stopping rule from reconstruction uniqueness plus exact
   residual checks.

## Questions requiring a decisive answer

1. For the exact CF254 `(9,7)` result, does selecting one normalized element of
   the affine gauge space risk making `(9,6)` or a later strip insoluble even
   though another representative would extend?  If yes, write the coupled row
   equations and identify the minimal parameter data that must be retained.

2. Can Maple `IntegrableConnections:-RationalSolutions` be applied directly to
   the augmented system above over `Q(epsilon)(x,y)`?  Please give the exact
   object construction and command sequence.  In particular, explain how to
   represent affine forcing and constant residue parameters without creating
   spurious variable-dependent solutions for those parameters.

3. What exact calculation establishes that a Kallen permutation is a genuine
   isomorphism of these cut differential modules?  State the pullback and basis
   identity that must vanish.  Which solved class is the most plausible source
   for CF231 and CF254?

4. CF231 demonstrates that a candidate can look stable in degree yet remain
   wrong through nine 31-bit primes because of coefficient height.  What is the
   best deterministic stopping criterion for modular rational reconstruction?
   Can one derive a coefficient-height bound from the exact linear system, or
   should the algorithm add primes until reconstruction is unchanged under one
   unused prime and the exact residual vanishes?

5. If a targeted balance is worthwhile, which divisor should be tested first
   and what local residue/exponent criterion justifies it?  We do not want a
   generic balance that makes the rational ansatz larger.

6. Should lower strips be completed before calling CANONICA's
   `TransformDlogToEpsForm`, or can the exact solved strips already reduce the
   remaining work through a sector-level transformation?  State this separately
   for CF231 and CF254.

7. Give a prioritized finite sequence of calculations.  For each, state what
   result would make us continue that route or abandon it.  Please challenge
   the premises where necessary and recommend established software or methods
   used in multiloop differential-equation calculations when they materially
   improve this sequence.

The required outcome is an exact rational epsilon-form transformation and,
later, exact analytic boundary data.  Fixed-kinematics numerics may check the
result but cannot replace it.
