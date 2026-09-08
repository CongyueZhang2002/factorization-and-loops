# Codex result: exact CF407 ordered-corner region constraint

Date: 2026-08-14

## Status correction

The cut-specific question is now resolved in
`codex_cf407_physical_cut_resolution_2026-08-14.md`. Use that direct
physical-cut derivation for the survivor constraint; retain the calculation
below only as the independent ordinary-uncut region census.

Do not use the transfer from the uncut Newton facets to the physical cut in
the text below. The six ordinary-uncut regions and their powers remain exact,
but the physical-cut conclusion now comes from the separate Gram-factorization
derivation named above.

The intended calculation is to resolve the `(1,-1)` question from Round 5
without using the inherited 83bb rows.

## Exact region calculation

For the E13/CF407 top integral with three cut and six ordinary denominators,
we constructed the Lee--Pomeransky polynomial directly from the stored
nine-denominator `FCTopology`. Normaliz enumeration through
`pySecDec.find_regions` gives six regions for

\[
Y=-u/s\to0^+\quad\text{at fixed}\quad X=-t/s:
\]

| multiplicity | power |
|---:|:---|
| 1 | \(Y^0\) |
| 2 | \(Y^{-1-\epsilon}\) |
| 2 | \(Y^{-1-2\epsilon}\) |
| 1 | \(Y^{-2-2\epsilon}\) |

For each leading `Y` polynomial, a second exact Newton-facet enumeration as
`X -> 0+` again gives only epsilon slopes `{-2,-1,0}`.

In the ordered Kallen chart,

\[
y=(1-\zeta)(1-\bar\zeta)\sim\delta,
\qquad
x=\zeta\bar\zeta\sim\rho,
\]

where `delta=1-zeta` is taken to zero before `rho=zetab`. The rational
canonical-to-physical transformation changes only integer powers. Therefore
the local canonical eigenvalues must obey

\[
\lambda_\zeta,\lambda_\rho\in\{-2,-1,0\}.
\]

The three cuts form a finite reverse-unitarity linear combination of
prescriptions with the same Newton polytope. That combination and the
positive-energy restrictions may remove regions, but cannot introduce an
epsilon slope absent from the uncut parametric integral. The exclusion of
positive slopes therefore applies to the physical cut integral.

## Consequence for the local modes

The exact spectral projectors are

\[
P_{\zeta,+}=R_\zeta^2(R_\zeta+2)/3,
\]

\[
P_{\rho,1}=-(R_\rho+2)(R_\rho+1)R_\rho^2(R_\rho-2)/6,
\]

\[
P_{\rho,2}=(R_\rho+2)(R_\rho+1)R_\rho^2(R_\rho-1)/48.
\]

The physical corner vector satisfies

\[
P_{\zeta,+}c=0,
\qquad
(P_{\rho,1}+P_{\rho,2})c=0.
\]

Thus the one `(1,-2)` mode and both `(1,-1)` modes have zero coefficients.
The remaining negative-edge space is

\[
E_{(-2,-2)}\oplus E_{(-2,-1)}\oplus
E_{(0,-2)}\oplus E_{(0,-1)},
\]

of dimension `1+1+3+1=6`. Its inherited 83bb image has exact rank two, so
the number of genuinely new periods remains four.

## Files for independent checking

- `/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/E13/AnalyzeE13RegionsPySecDec.py`
- `/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/E13/E13OrderedRegionCensus.json`
- `/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/E13/DeriveE13OrderedCornerConstraints.wls`
- `/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/E13/E13_ORDERED_CORNER_SURVIVORS.md`

The Mathematica projector calculation and independent SubTropica ray
enumeration are queued until one of Fable's two active Wolfram kernels
finishes. Please compare the Newton slopes and projector rows against the
counter's exact CF407 basis map. In particular, this gives a direct physical
reason for omitting the two `(1,-1)` modes that the 83bb projection could not
provide.
