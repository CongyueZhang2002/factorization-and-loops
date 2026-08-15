# Codex reply: Stage-4 NLO UU distributional pilot

The NLO UU hard coefficient has now been reconstructed from the six exact
masters through its endpoint powers and delta/plus distributions.  The exact
record is in `NLOUUEndpointDistributions.wl`; the connected derivation is in
`NLO_ENDPOINT_RECONSTRUCTION.md`.

The displayed endpoint coefficients multiply the exact analytic factor

\[
{\cal P}_{UU}(\epsilon)=
\frac{C_F\pi^{3+\epsilon}\alpha_s^3}
{x_ax_bz_h^2}D_1(z_h)f_1(x_a)f_1(x_b),
\]

which is retained separately because it is independent of the endpoint
variable.

## Main result

With

\[
t=-s(1-v),\qquad u=-svw,\qquad \rho=1-w,
\]

the hard coefficient contains two endpoint families,

\[
H_{UU}=C_1(\epsilon)\rho^{-1-\epsilon}
      +C_2(\epsilon)\rho^{-1-2\epsilon}
      +O(\rho^{-\epsilon}),
\]

and both coefficients are nonzero.  Their origin in the six-master basis is

| endpoint family | masters |
|---|---|
| \(\rho^{-1-\epsilon}\) | bubble, cbb, ac |
| \(\rho^{-1-2\epsilon}\) | cb, abb, ab |

The second family was absent from an older diagnostic because that diagnostic
acted on the raw real expression without the separate factor
\(s_4^{-\epsilon}=(sv\rho)^{-\epsilon}\).

## Normalization finding

The six analytic masters were stored in the physical cut phase-space
normalization, while the IBP coefficient multiplies GLIs defined with
\({\rm d}^Dk/(i\pi^{D/2})\).  The exact conversion for the one-cut-loop NLO
problem is

\[
I_{\rm GLI}=-i\,2^{2-2\epsilon}\pi^{-\epsilon}I_{\rm phys}.
\]

Applying this factor removes the apparent imaginary hard coefficient.  At
\(\epsilon=0.1\), the direct insertion of physical masters differed from the
archived full real result by \(-0.3220037986611614 i\); the conversion factor
has magnitude \(3.1055534256360784\), giving the exact unit magnitude and the
previously identified overall real-emission sign.

## Distribution coefficients

Writing

\[
C_a=\frac{c_{a,-1}}{\epsilon}+c_{a,0}+c_{a,1}\epsilon+O(\epsilon^2),
\]

the contribution of either \(a=1\) or \(a=2\) through finite order is

\[
\begin{aligned}
\delta(\rho):&\quad
-\frac{c_{a,-1}}{a\epsilon^2}
-\frac{c_{a,0}}{a\epsilon}
-\frac{c_{a,1}}{a},\\
\left[\frac1\rho\right]_+:&\quad
\frac{c_{a,-1}}{\epsilon}+c_{a,0},\\
\left[\frac{\ln\rho}{\rho}\right]_+:&\quad
-a c_{a,-1},\\
\left[\frac{\ln^2\rho}{\rho}\right]_+:&\quad0.
\end{aligned}
\]

The compact exact formulas for all \(c_{a,n}\) are in the attached record and
derivation.  To obtain the complete finite result, the common analytic factor
is needed through \(O(\epsilon^2)\) for the delta coefficient, through
\(O(\epsilon)\) for \([1/\rho]_+\), and at leading order for
\([\ln\rho/\rho]_+\).

## Consequence for the NNLO transport record

Every transported master must carry, for each physical endpoint:

1. the exact loop-measure and cut normalization;
2. the normalized regulator symbol and the convention for \(D\);
3. the endpoint variable and its physical approach direction;
4. the rational-coefficient valuation;
5. every surviving local master exponent;
6. the branch of each root, logarithm, and noninteger power;
7. the Laurent depth required after multiplication by the distribution;
8. exact differential-equation residuals and numerical values at independent
   chamber points.

The NLO example demonstrates that neither the coefficient valuation nor the
master exponent alone determines the required distributional power.

## Exact reconstruction checks

The exact formulas and their Laurent truncations were compared at
\((s,v,C_A,C_F)=(10,2/5,3,4/3)\).  Reducing
\(\epsilon\) from \(10^{-2}\) to \(10^{-3}\) reduces the relative remainder
by approximately \(10^3\), as expected after retaining terms through
\(O(\epsilon)\).

A direct Mathematica calculation against the complete six-master
hypergeometric expression gives

\[
C_1-C_1^{\rm extracted}=0,\qquad
C_2-C_2^{\rm extracted}=0.
\]

At \(\epsilon=1/10\), sequential endpoint extraction at
\(\rho=10^{-100}\) gives

\[
\frac{\rho^{1+2\epsilon}H_{UU}}{C_2}-1
=4.883568893472119\times10^{-11},
\]

\[
\frac{\rho^{1+\epsilon}
 [H_{UU}-C_2\rho^{-1-2\epsilon}]}{C_1}=1
\]

to the displayed 60-digit precision.  The reusable distribution function
also reproduces the stored delta, \([1/\rho]_+\),
\([\ln\rho/\rho]_+\), and \([\ln^2\rho/\rho]_+\) coefficients with exact
zero differences.
