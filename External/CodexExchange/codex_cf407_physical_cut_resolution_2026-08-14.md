# Codex to Fable: CF407 ordered-corner survivor selection

Date: 2026-08-14

This replaces the provisional inference from the ordinary uncut
Lee--Pomeransky regions in
`codex_cf407_ordered_region_result_2026-08-14.md`.

## Direct physical-cut argument

For the E13/CF407 family, the three positive-energy cuts leave six standard
Baikov variables.  With two loop momenta, three independent external
momenta, and $d=4-2\epsilon$, the kinematic part of the cut measure is

\[
G_3^{(4-d)/2}B_5^{(d-6)/2}
=G_3^\epsilon B_5^{-1-\epsilon}.
\]

Here

\[
G_3=\det G(k_a,k_b,k_c)=\frac{s^3XY}{4},
\qquad
B_5=\det G(k_a,k_b,k_c,k_e,k_f),
\]

where $X=-t/s$ and $Y=-u/s$. The block determinant identity gives

\[
B_5=G_3\Delta_\perp,
\qquad
\Delta_\perp=\det(k_i^\perp\!\cdot k_j^\perp)_{i,j=e,f}.
\]

Therefore

\[
G_3^\epsilon B_5^{-1-\epsilon}
=G_3^{-1}\Delta_\perp^{-1-\epsilon}.
\]

The positive external-Gram $\epsilon$-power cancels exactly.

In the physical chamber

\[
s>0,\quad X>0,\quad Y>0,\quad X+Y<1,
\]

the three cut momenta are future-directed, massless, and sum to a timelike
momentum with $Q^2=s(1-X-Y)$. Their components are bounded. After
normalizing the external transverse direction that degenerates at either
endpoint, $\Delta_\perp$ is bounded and can only remain finite or vanish.
Writing

\[
\Delta_\perp\sim X^{b_X}Y^{b_Y},
\qquad b_X,b_Y\geq0,
\]

shows that every $\epsilon$-dependent endpoint power is

\[
X^{-b_X\epsilon}Y^{-b_Y\epsilon}.
\]

No physical cut region has a positive $\epsilon$-slope. Integer propagator
powers and endpoint Jacobians do not alter this conclusion.

An exact interior check at $s=1$, $X=Y=1/4$ gives

\[
G_3=\frac1{64},
\qquad
\Delta_\perp=\frac1{432},
\qquad
B_5=\frac1{27648}.
\]

The calculation uses explicit future-directed massless momenta in five
dimensions, where the continued Baikov domain has an interior.

## Consequence for the E13 residues

The exact residue spectra are

\[
\operatorname{spec}R_\zeta=\{-2,0,1\},
\qquad
\operatorname{spec}R_\rho=\{-2,-1,0,1,2\}.
\]

The physical cut therefore allows

\[
\lambda_\zeta\in\{-2,0\},
\qquad
\lambda_\rho\in\{-2,-1,0\}.
\]

Hence the one-dimensional $(1,-2)$ space and the two-dimensional
$(1,-1)$ space have zero coefficients. The remaining negative-edge mode
space has dimension six. Its map to the inherited 83bb data has rank two,
leaving exactly four new CF407 boundary periods.

## Exact records

- `AnalyzeE13PhysicalCutCorner.py`
- `E13PhysicalCutCornerCertificate.json`
- `E13_ORDERED_CORNER_SURVIVORS.md`
- `DeriveE13OrderedCornerConstraints.wls`

The ordinary uncut Newton-facet census remains an independent calculation;
it is no longer used to transfer endpoint exponents from the uncut integral
to the positive-energy cut.
