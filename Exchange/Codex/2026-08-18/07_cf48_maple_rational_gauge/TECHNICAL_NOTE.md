# CF48 strip-4 rational gauge from IntegrableConnections

Date: 2026-08-18

## Problem

The remaining CF48 sector-13 off-diagonal strip has two (2\times2)
diagonal epsilon-form blocks (E_\mu,C_\mu) and an off-diagonal block
(B_\mu), with variables (p,s).  We sought a rational (2\times2)
matrix (D(p,s,\varepsilon)) and constant residue matrices (K_a) such
that

\[
B'_\mu=B_\mu+\varepsilon(E_\mu D-D C_\mu)-\partial_\mu D
=\varepsilon\sum_{a=1}^{12}K_a\,\partial_\mu\log\phi_a .
\]

The twelve letters are

\[
\{-1+p,p,1+p,p-s,-1+s,s,1+s,p+s,p-s^2,
  p+ps-s^2,p+s^2,-p-ps+p^2s+s^2\}.
\]

## Constant-residue compatibility

Writing

\[
F_\mu=B_\mu-\varepsilon\sum_aK_a\,\partial_\mu\log\phi_a,
\qquad
\partial_\mu D=\varepsilon(E_\mu D-D C_\mu)+F_\mu,
\]

the exact flatness condition gives 287 linear equations for the 48
entries of the (K_a).  It fixes 44 entries and leaves four free:

\[
(K_6)_{11},\quad (K_6)_{12},\quad (K_6)_{22},\quad (K_8)_{21}.
\]

The recorded solution sets these four entries to zero.  The solved
relations are triangular and must be substituted recursively.

An earlier nonzero compatibility residual was not physical.  The
captured matrices contained `Global`eps`, whereas the first script used
`CANONICA`eps` as a second independent symbol.  The residual factored by
their difference.  Identifying the unique dimensional regulator removes
it exactly.

## Maple calculation

The matrix (D) was vectorized into a four-component vector.  Maple
2026.1 with IntegrableConnections obtained the unique rational solution
of the (s)-equation through

```maple
V := IntegrableConnections:-Mratsolde(A2,s,b2):
```

in 0.36 seconds.  It contains no arbitrary homogeneous constants.  The
two independent exact checks are

\[
\partial_s V-A_sV-b_s=0,
\qquad
\partial_p V-A_pV-b_p=0.
\]

After importing the rational vector into Mathematica and reshaping it
to (D), direct substitution into the original block equation gives

\[
B'_p-\varepsilon\sum_aK_a\partial_p\log\phi_a=0,
\qquad
B'_s-\varepsilon\sum_aK_a\partial_s\log\phi_a=0,
\]

entry by entry and with exact arithmetic.

## IntegrableConnections defects encountered

1. Starting with (p), the package reaches `good_form` at infinity and
   raises a division-by-zero exception for this symbolic-parameter
   system.
2. Starting with (s), the first univariate equation has a unique
   rational particular solution.  In the combined `param` plus `rhs`
   branch, `RationalSolutions` fails to take the corresponding early
   return.  It calls `MatrixColumnPrimpartRat` on an empty homogeneous
   space and raises an invalid-minor error.  The same early return exists
   for the `rhs` branch in the package source.

The reliable wrapper rule is therefore: solve one variable with
`Mratsolde`; if no homogeneous constants remain, verify all other
differential equations exactly and return that solution.  Recursive
reduction is needed only when the first equation leaves a nonzero
homogeneous solution space.

## Exact artifacts

- `CF48Sector13Strip4RationalGauge.wl`: Mathematica gauge matrix,
  canonical off-diagonal block, and exact residuals.
- `CF48Sector13Strip4RationalGauge.maple.txt`: exact Maple rational
  vector in text form.
- `CF48Sector13Strip4FirstVariable.m`: Maple binary result.
- `CF48Sector13Strip4FirstVariable.log`: timing and exact residuals.
- `CF48Sector13Strip4PreparedSystem.wl`: vectorized connection and
  inhomogeneous terms.

This calculation removes the recorded strip-4 obstruction without a
large rational ansatz search.
