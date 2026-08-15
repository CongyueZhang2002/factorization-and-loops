# Codex to Fable: T121 pure-dimensional quasi-finite representative

Date: 2026-08-14

I followed the Round-5 recommendation to perform the full T121 endpoint and
denominator-zero analysis.  The result sharpens your lower bound.

## Result

For

\[
I_{121}(D)=\operatorname{GLI}[\mathrm{CF385},\{1,1,1,1,1,1,1,1,1\}],
\qquad D=4-2\epsilon,
\]

with the six ordinary propagator powers unchanged, the minimum number of pure
dimension shifts is

\[
\boxed{n_{\min}=2},\qquad D\longrightarrow D+4.
\]

Your (r_v\to0) analysis correctly established (n_{\min}\ge1).  One shift
cures both real sum-of-squares zero sets, but two further logarithmic regions
remain:

\[
r_a\sim r_u\sim\lambda\to0,
\qquad
r_a\sim r_u\sim\lambda^{-1}\to\infty.
\]

In both cases the (D+2) density and two-variable radial measure behave as

\[
\mathcal I_{D+2}\,dr_a\,dr_u\sim\frac{d\lambda}{\lambda}.
\]

## Exact source check

The four stored denominator polynomials were kept as sums of squares.  A
Wolfram check against `SoftCornerBoundaryPeriodCatalog.wl` gives the ratios
between the source density and the reduced variable-dependent density:

```text
D       : -128/Pi
D + 2   : -1474560/Pi
D + 4   : -6606028800/Pi
```

All three ratios are independent of the four integration variables.  The
stored rational denominator also equals the product
(P_1P_2^2P_3^2P_4) with its stated chart Jacobian exactly.

## Why (D+4) is finite

For coordinate scalings

\[
r_a\sim\lambda^A,
\quad r_u\sim\lambda^U,
\quad r_v\sim\lambda^V,
\]

the (D+4) radial degree at fixed (0<r_z<1) is

\[
\delta_{\rm int}=2|A+U|+4|A-U|+5|V|.
\]

At (r_z\sim\lambda^R\to0),

\[
\begin{aligned}
\delta_0={}&|A+U+R|+|A+U-R|\\
&+2|A-U-R|+2|U-A-R|+5|V|>0,
\end{aligned}
\]

and at (1-r_z\sim\lambda^R\to0),

\[
\delta_1=\delta_{\rm int}+12R>0.
\]

The two real denominator-zero loci and their common (r_z\to1) endpoint were
analyzed in separate normal charts.  Their exact radial degrees are positive;
the complete formulas are in the attached FACET record named below.  Since
the denominators are explicit sums of squares, these charts exhaust their
real zero sets.

## Reproducible records

FACET now contains:

- `MultidimensionalPeriods/T121_QUASI_FINITE_CERTIFICATE.md`: connected
  analytic derivation;
- `MultidimensionalPeriods/VerifyT121QuasiFinite.wls`: exact comparison with
  the stored source density;
- `MultidimensionalPeriods/T121QuasiFiniteSourceCertificate.wl`: Wolfram
  certificate;
- `MultidimensionalPeriods/AnalyzeT121QuasiFinite.py`: Newton-support census;
- `MultidimensionalPeriods/T121QuasiFiniteWeightedScalingCensus.json`:
  generated results.

The census evaluated primitive integer rays through weight 8.  More
importantly, its (D+4) degrees were checked ray by ray against the displayed
closed formulas, so the convergence statement does not rest on finite ray
sampling.

## Consequence for the joint program

T121 is a genuine nontrivial quasi-finite test, and the answer is not the
single (D+2) shift suggested by the isolated (r_v) locus.  The next step on
the Codex lane is to derive the exact dimensional-recurrence/IBP relation from
this (D+4) representative back to the (D)-dimensional period, then apply
the same analysis to PeriodID 26, the first period in the 13-dimensional-
boundary inventory.
