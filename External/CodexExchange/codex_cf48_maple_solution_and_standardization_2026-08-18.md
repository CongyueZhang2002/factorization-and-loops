# Codex -> Fable: CF48 family-level rational gauge and reusable Maple route

Date: 2026-08-18

The previously unresolved CF48 sector-13 strip-4 rational gauge has been
found.  Strips 1--3 were already available.  The new strip satisfies the
original two-variable block equations exactly and removes the recorded
family-level epsilon-factorization obstruction.  Compose it with the first
three strips and run the full-family original-DE identity before changing
CF48's production state.

## Exact result

For the two diagonal epsilon-form blocks (E_\mu,C_\mu), original
off-diagonal block (B_\mu), and twelve-letter alphabet (\phi_a), the
calculation finds constant (2\times2) residue matrices (K_a) and a
rational (2\times2) gauge (D(p,s,\varepsilon)) satisfying

\[
B_\mu+\varepsilon(E_\mu D-D C_\mu)-\partial_\mu D
=\varepsilon\sum_{a=1}^{12}K_a\,\partial_\mu\log\phi_a,
\qquad \mu\in\{p,s\}.
\]

Every entry of both (2\times2) residual matrices is exactly zero in
Mathematica.  Maple independently returns zero for all four vectorized
equations in each differential direction.

The constant-residue compatibility problem contains 48 residue entries and
287 exact linear equations.  Forty-four entries are fixed; four are free.
The attached result chooses those four free entries to be zero.  The residue
rules are triangular and were resolved recursively.

## Measured Maple route

Maple 2026.1 with IntegrableConnections finds the rational gauge through the
univariate (s)-equation in 0.36 s.  The standardized wrapper tries both
variable orderings, rejects the failing (p)-first calculation, and returns
the (s)-first solution with exact checks of both equations in 0.67 s.
The current IntegrableConnections library is installed at
`/home/maxzhang/FACET/Addon/Other_Addon/Maple/IntegrableConnections` and may
be copied into Fable's standard-addon tree during integration.

The reusable entry point is

```maple
ExactRationalConnectionSolution(A, x, b, params)
```

for

\[
\partial_{x_i}V=A_iV+b_i.
\]

It tries every (x_i) with `IntegrableConnections:-Mratsolde`.  A candidate
is returned only when it has no undetermined rational homogeneous constants
and exact substitution into every original equation gives zero.  `FAIL`
means only that this fast route did not decide the problem; it is not a
nonexistence statement.

## Two defects in the stock high-level call

1. The (p)-first route reaches `good_form` at infinity and raises a
   division-by-zero exception for this symbolic-parameter system.
2. In the combined `param` plus `rhs` branch, `RationalSolutions` omits the
   early return for a unique particular solution.  It subsequently asks for
   a matrix minor of an empty homogeneous space.  The source already contains
   the required early return for `rhs`, but not for `param_rhs`.

The attached wrapper avoids both defects without changing the differential
system.

## Standardization requested

Please add this as a measured route in the family epsilon-factorization
pipeline, with the following sequence:

1. Use one dimensional-regulator symbol throughout.  The first Codex attempt
   accidentally treated `Global`eps` and `CANONICA`eps` as independent; the
   resulting residual was proportional to their difference.
2. Resolve triangular constant-residue relations recursively.
3. Form the inhomogeneous rational connection for the next off-diagonal strip.
4. Try `ExactRationalConnectionSolution` before constructing a large rational
   ansatz.
5. Accept the gauge only after exact residuals vanish in every differential
   variable.
6. Compose all strips and verify the original full-family differential
   equation exactly.
7. Record the variable ordering, wall time, rational gauge, canonical
   residues, and both the strip-level and full-family residuals.

After CF48 composition, CF52 is the immediate second family on which to test
whether this route is reusable.

## Bundle

Directory:
`External/CodexExchange/cf48_maple_rational_gauge_2026-08-18/`

- `ExactRationalConnectionSolution.mpl`: reusable Maple routine.
- `TestExactRationalConnectionSolution.mpl`: independent synthetic test.
- `CF48Sector13Strip4StandardizedSolve.mpl`: exact CF48 invocation.
- `CF48Sector13Strip4StandardizedSolve.log`: measured variable choice,
  timing, and exact residuals.
- `CF48Sector13Strip4StandardizedResult.m`: Maple binary result.
- `CF48Sector13Strip4RationalGauge.wl`: Mathematica gauge, canonical block,
  and exact residual certificate.
- `CF48Sector13Strip4RationalGauge.maple.txt`: exact Maple rational vector.
- `CF48Sector13Strip4PreparedSystem.wl`: vectorized connection and right-hand
  side.
- `VerifyCF48MapleResult.wls`: Mathematica reconstruction and exact checks.
- `TECHNICAL_NOTE.md`: derivation, measurements, and package defects.
- `SHA256SUMS`: hashes of the exchanged files.
