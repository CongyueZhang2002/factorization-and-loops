# Exact endpoint matching for the CF299 and CF407 observable transports

Codex, 2026-08-17 PDT.

## Analytic construction

At the endpoint, the canonical family obeys

\[
 \frac{dF}{d\rho}
 =\epsilon\left(\frac{R}{\rho}
 +\sum_{m\geq0}C_m\rho^m\right)F .
\]

For a local mode (c), write

\[
 F(\rho,\epsilon)=H(\rho,\epsilon)\rho^{\epsilon R}c,
 \qquad
 H=\sum_{n,r\geq0}\rho^n\epsilon^r H_{n,r},
 \qquad H_{0,0}=1.
\]

The matrices (H_{n,r}) were derived recursively from

\[
 nH_{n,r}=RH_{n,r-1}-H_{n,r-1}R
 +\sum_{m+k=n-1}C_mH_{k,r-1}.
\]

An independently assembled truncated differential residual vanishes entry by
entry for both families through (ho^4) and (epsilon^3).  These orders are
sufficient for the original-basis leading terms because the most singular
entry of the stored transformation is (ho^{-3}).

Every boundary period appearing below is an ordinary zero mode,

\[
 Rc_a=0,
\]

with no logarithmic generalized-eigenvector component.  The period
(B_a(\epsilon)) therefore enters the canonical solution as

\[
 F_a(\rho,\epsilon)=H(\rho,\epsilon)c_a B_a(\epsilon).
\]

The observable transport is written in terms of Laurent coordinates
(b_{n i}=[\epsilon^n]F_i(0,\epsilon)).  Their exact relation to the periods is

\[
 b_{n i}=\sum_a[\epsilon^n]\!\left(c_{a,i}(\epsilon)
 B_a(\epsilon)\right).
\]

This relation is retained as an exact coefficient-generating formula.  No
assumption about the unknown Laurent order of (B_a) is inserted.

## CF299 soft endpoint

The chart endpoint is (u=0) at (p=1/2), with

\[
 1-v-w=\frac{u^2}{2}+O(u^4).
\]

The exact local residue has eigenvalues

\[
 -8\;(4),\qquad -6\;(1),\qquad -4\;(1),\qquad 0\;(16),
\]

where the numbers in parentheses are algebraic multiplicities.  The four
period realizations relevant to the stored boundary inventory are:

| period | original masters | original-basis leading behavior | result |
|---:|---|---|---|
| 7 | row 8 | (1+O(u)) | coefficient exactly zero |
| 8 | row 14 | (1+O(u)) | unresolved period (B_8(\epsilon)) |
| 9 | rows 10, 11 | ((1,3\epsilon)+O(u)) | one scalar period (B_9(\epsilon)) |
| 25 | rows 1, 2 | (\left(1,\frac{512\epsilon^3}{1-8\epsilon+64\epsilon^2}u^{-2}\right)+O(u^{-1})) | one scalar period (B_{25}(\epsilon)) |

The (u^{-2}) term in row 2 is not an additional boundary constant.  It is
fixed by the same period as row 1.  Its reconstruction requires the regular
matrix (H) through (u^3); retaining only the residue vector gives the wrong
valuation because poles in the original-basis transformation cancel against
the regular Frobenius series.

After removing the exactly vanishing period 7, periods 8, 9, and 25 enter 20
of the 84 Laurent coordinates used by the two-segment observable map.  Their
contribution occupies 143 nonzero GPL word maps through weight three.

The complete GPL alphabet for the spectator segment is

\[
 \{0,-1,1,-i,i,-\sqrt2,\sqrt2\}.
\]

Complex letters occur in conjugate pairs.  The real physical branch is the
sum of each conjugate pair, not either term separately.

## CF407 (v\)-edge endpoint

The chart endpoint is (y=0) at (x=1/2), with

\[
 v=\frac{y}{2}+O(y^2).
\]

The exact local residue has eigenvalues

\[
 -2\;(6),\qquad 2\;(5),\qquad -1\;(3),\qquad 1\;(1),
 \qquad 0\;(9).
\]

Period 23 is the ordinary zero mode (c_{23}=e_{21}).  In the original basis,

\[
 I_{21}=\frac{2}{y}B_{23}(\epsilon)+O(1)
       =\frac{1}{v}B_{23}(\epsilon)+O(1).
\]

Thus its normalization agrees exactly with the boundary inventory.  It enters
the three Laurent coordinates

\[
 [\epsilon^0]B_{23},\qquad
 [\epsilon^1]B_{23},\qquad
 [\epsilon^2]B_{23},
\]

and contributes to 23 nonzero GPL word maps through weight three.

The spectator GPL alphabet is

\[
 \left\{0,-1,1,-\frac12,\frac12,1-i,1+i,2,\frac32\right\}.
\]

Again the two complex letters must be retained as a conjugate pair on the
real physical branch.

## Exact checks

For every mapped period, an independent script reconstructs (R), (H), and
the original-basis transformation from the family record and verifies:

1. ((R-\lambda_a)^{r_a+1}c_a=0) exactly;
2. the stated generalized-eigenvector level is minimal;
3. the original-basis endpoint valuation agrees with the inventory;
4. the leading coefficient agrees exactly with the stated normalization;
5. the identity-pivot rows of the constrained Laurent embedding are exactly
   the identity matrix.

All equalities vanish as rational functions of (epsilon).  No numerical
kinematic point is used.

## Remaining analytic work

The transport problem is finished for the mapped modes.  The unresolved
physics is the analytic evaluation of

\[
 B_8(\epsilon),\qquad B_9(\epsilon),\qquad
 B_{25}(\epsilon),\qquad B_{23}(\epsilon).
\]

The present files do not claim values for these periods.  Once a period is
known, substituting it into the retained Laurent-coefficient formula produces
its contribution to every requested physical master without rerunning the
transport.

## Machine-readable records

The directory
`Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17/` contains:

- `EndpointFrobenius_CF299.wl`, `EndpointFrobenius_CF407.wl`;
- `BoundaryModeMap_CF299.wl`, `BoundaryModeMap_CF407.wl`;
- `BoundaryModeValidation_CF299.wl`, `BoundaryModeValidation_CF407.wl`;
- `ObservableBoundarySubstitution_CF299.wl`;
- `ObservableBoundarySubstitution_CF407.wl`;
- the scripts that construct and independently verify these records.
