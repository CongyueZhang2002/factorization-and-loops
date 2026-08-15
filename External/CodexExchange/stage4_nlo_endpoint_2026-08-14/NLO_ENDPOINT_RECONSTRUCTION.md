# NLO UU endpoint reconstruction

## Integral and kinematic conventions

The partonic invariants are written as

\[
t=-s(1-v),\qquad u=-svw,\qquad
s_4=s+t+u=sv(1-w),
\]

with

\[
s>0,\qquad 0<v<1,\qquad \rho\equiv 1-w>0.
\]

The endpoint is therefore \(\rho\to0^+\).  The calculation uses
\(D=4-2\epsilon\).

The exact six-master solution was originally stored in the physical cut
phase-space convention.  The coefficient produced by the IBP calculation,
however, multiplies a GLI whose loop measure is

\[
\frac{{\rm d}^Dk}{i\pi^{D/2}}.
\]

For one remaining cut momentum, the two conventions obey

\[
I_{\rm GLI}
=-i\,2^{2-2\epsilon}\pi^{-\epsilon} I_{\rm phys}.
\]

This factor must be applied before the endpoint or Laurent expansion.  It
removes the apparent imaginary hard coefficient.  At \(\epsilon=0.1\), the
measured ratio obtained by inserting the physical masters directly was
\(-0.3220037986611614\,i\).  Since

\[
2^{2-2\epsilon}\pi^{-\epsilon}
=3.1055534256360784,
\]

the converted ratio is \(-1\) to floating-point precision.  This is the
overall real-emission sign difference that had already been identified in the
archived direct calculation; it is not a branch phase.

The result below is the reduced hard coefficient multiplying

\[
{\cal P}_{UU}(\epsilon)=
\frac{C_F\pi^{3+\epsilon}\alpha_s^3}
{x_ax_bz_h^2}
D_1(z_h)f_1(x_a)f_1(x_b),
\]

and the fraction measure

\[
{\rm d}x_a\,{\rm d}x_b\,{\rm d}z_h.
\]

This factor is independent of \(w\), so it does not alter the endpoint
families.  It is retained exactly rather than mixed into the master
coefficients.

## Endpoint decomposition of the six masters

The master basis is ordered as

\[
\{B,cbb,cb,abb,ac,ab\}.
\]

The rational coefficient valuation and the hypergeometric endpoint determine
the power of \(\rho\):

| master | coefficient valuation | hypergeometric argument | resulting power |
|---|---:|---:|---:|
| \(B\) | \(-1\) | no hypergeometric function | \(-1-\epsilon\) |
| \(cbb\) | \(-1\) | \(0\) | \(-1-\epsilon\) |
| \(cb\) | \(0\) | \(1\) | \(-1-2\epsilon\) |
| \(abb\) | \(0\) | \(1\) | \(-1-2\epsilon\) |
| \(ac\) | \(-1\) | \(0\) | \(-1-\epsilon\) |
| \(ab\) | \(0\) | \(1\) | \(-1-2\epsilon\) |

For the three unit-argument branches, the connection formula is

\[
{}_2F_1(1,1;1-\epsilon;z)
=\frac{\epsilon}{1+\epsilon}
 {}_2F_1(1,1;2+\epsilon;1-z)
+\Gamma(1-\epsilon)\Gamma(1+\epsilon)
 \frac{z^\epsilon}{(1-z)^{1+\epsilon}}.
\]

Consequently the hard coefficient has the form

\[
H_{UU}(\rho,\epsilon)
=C_1(\epsilon)\rho^{-1-\epsilon}
+C_2(\epsilon)\rho^{-1-2\epsilon}
+O(\rho^{-\epsilon}).
\]

The earlier raw-expression diagnostic found only the first term because it
did not include

\[
{\tt RealFactor}\propto s_4^{-\epsilon}
=(sv)^{-\epsilon}\rho^{-\epsilon}.
\]

After this factor is restored, the second endpoint family is nonzero.

## Exact endpoint coefficients

Define

\[
q(\epsilon,v)=-(1+v^2)+\epsilon(1-v)^2
\]

and

\[
\begin{aligned}
B(\epsilon)={}&s^\epsilon v^{3\epsilon}
-2\,[s(1-v)^2]^\epsilon v^{3\epsilon}\\
&+(2-C_A^2)[s(1-v)^2v]^\epsilon.
\end{aligned}
\]

In the GLI convention the two exact coefficients are

\[
C_1(\epsilon)=
\frac{4\,16^\epsilon(\epsilon-1)
 (2-2C_A^2+C_AC_F\epsilon)q(\epsilon,v)}
{\sqrt\pi\,\epsilon s(1-v)^2v(sv)^\epsilon
 \Gamma(3/2-\epsilon)},
\]

\[
C_2(\epsilon)=
-\frac{2^{5+4\epsilon}\sqrt\pi\,v^{-1-3\epsilon}
 q(\epsilon,v)B(\epsilon)\csc(\pi\epsilon)}
{s(1-v)^2[s^2(1-v)v]^\epsilon
 \Gamma(1/2-\epsilon)}.
\]

Every noninteger power has a positive base in the stated physical region.
No `PowerExpand` or continuation across a cut is required.

## Laurent coefficients

Write

\[
C_a(\epsilon)=\frac{c_{a,-1}}{\epsilon}
+c_{a,0}+c_{a,1}\epsilon+O(\epsilon^2).
\]

For \(a=1\), define

\[
\begin{gathered}
A_0=2(1-C_A^2),\qquad A_1=C_AC_F,\\
L_1=2-\gamma_E+\ln\frac{4}{sv},\qquad
K_1=\frac{L_1^2}{2}-\frac{\pi^2}{4}+2,\\
r_{10}=A_0(1+v^2),\\
r_{11}=-2A_0(1-v+v^2)+A_1(1+v^2),\\
r_{12}=A_0(1-v)^2-2A_1(1-v+v^2),\\
P_1=\frac{8}{\pi s v(1-v)^2}.
\end{gathered}
\]

Then

\[
c_{1,-1}=P_1r_{10},\qquad
c_{1,0}=P_1(r_{11}+L_1r_{10}),
\]

\[
c_{1,1}=P_1(r_{12}+L_1r_{11}+K_1r_{10}).
\]

For \(a=2\), let

\[
\begin{aligned}
\ell_1&=\ln s+3\ln v,\\
\ell_2&=\ln s+2\ln(1-v)+3\ln v,\\
\ell_3&=\ln s+2\ln(1-v)+\ln v,\\
B_0&=1-C_A^2,\\
B_1&=\ell_1-2\ell_2+(2-C_A^2)\ell_3,\\
B_2&=\tfrac12[\ell_1^2-2\ell_2^2+(2-C_A^2)\ell_3^2],\\
L_2&=\ln\frac{4}{s^2(1-v)v^4}-\gamma_E,\\
K_2&=\frac{L_2^2}{2}-\frac{\pi^2}{12},\\
r_{20}&=-(1+v^2)B_0,\\
r_{21}&=(1-v)^2B_0-(1+v^2)B_1,\\
r_{22}&=(1-v)^2B_1-(1+v^2)B_2,\\
P_2&=-\frac{32}{\pi s v(1-v)^2}.
\end{aligned}
\]

The coefficients are

\[
c_{2,-1}=P_2r_{20},\qquad
c_{2,0}=P_2(r_{21}+L_2r_{20}),
\]

\[
c_{2,1}=P_2(r_{22}+L_2r_{21}+K_2r_{20}).
\]

At \(s=10\), \(v=2/5\), \(C_A=3\), and \(C_F=4/3\), the relative
difference between each exact coefficient and its truncation through
\(O(\epsilon)\) is

| coefficient | \(\epsilon=10^{-2}\) | \(\epsilon=10^{-3}\) |
|---|---:|---:|
| \(C_1\) | \(-3.4062\times10^{-7}\) | \(-3.4283\times10^{-10}\) |
| \(C_2\) | \(-3.0173\times10^{-6}\) | \(-2.9864\times10^{-9}\) |

The factor of approximately \(10^3\) under
\(\epsilon\mapsto\epsilon/10\) is the expected relative
\(O(\epsilon^3)\) remainder, since \(C_a\) begins at
\(1/\epsilon\).

## Delta and plus distributions

For \(a=1,2\),

\[
\rho^{-1-a\epsilon}
=-\frac{\delta(\rho)}{a\epsilon}
+\sum_{n=0}^\infty
 \frac{(-a\epsilon)^n}{n!}
 \left[\frac{\ln^n\rho}{\rho}\right]_+.
\]

Through finite order in \(\epsilon\), one endpoint family contributes

\[
\begin{aligned}
\delta(\rho):\quad&
-\frac{c_{a,-1}}{a\epsilon^2}
-\frac{c_{a,0}}{a\epsilon}
-\frac{c_{a,1}}{a},\\
\left[\frac1\rho\right]_+:\quad&
\frac{c_{a,-1}}{\epsilon}+c_{a,0},\\
\left[\frac{\ln\rho}{\rho}\right]_+:\quad&
-a c_{a,-1},\\
\left[\frac{\ln^2\rho}{\rho}\right]_+:\quad&0.
\end{aligned}
\]

The full UU coefficients are the sums of these expressions for \(a=1\) and
\(a=2\), multiplied by \({\cal P}_{UU}(\epsilon)\).  If the complete result
is expanded through \(O(\epsilon^0)\), the analytic prefactor is required
through \(O(\epsilon^2)\) for the delta term, through \(O(\epsilon)\) for
\([1/\rho]_+\), and only at \(O(\epsilon^0)\) for
\([\ln\rho/\rho]_+\).

## Exact reconstruction tests

The compact coefficients above were compared in Mathematica 14.2 with the
coefficients obtained independently from the six-master expression.  In the
physical region, after applying the physical-to-GLI normalization, the exact
symbolic differences are

\[
C_1-C_1^{\rm extracted}=0,\qquad
C_2-C_2^{\rm extracted}=0.
\]

The two endpoint families were then isolated sequentially from the complete
hypergeometric expression.  Define

\[
R_2(\rho)=\frac{\rho^{1+2\epsilon}H_{UU}(\rho,\epsilon)}{C_2(\epsilon)},
\]

\[
R_1(\rho)=\frac{\rho^{1+\epsilon}
 [H_{UU}(\rho,\epsilon)-C_2(\epsilon)\rho^{-1-2\epsilon}]}
 {C_1(\epsilon)}.
\]

At \(s=10\), \(v=2/5\), \(C_A=3\), \(C_F=4/3\), and
\(\epsilon=1/10\), the calculation gives

\[
R_2(10^{-100})-1=4.883568893472119\times10^{-11},
\qquad R_1(10^{-100})=1
\]

to the displayed 60-digit precision.  The slower convergence of \(R_2\) is
the predicted contamination \(O(\rho^\epsilon)\) from the \(a=1\) family.
After subtracting the \(a=2\) term, \(R_1-1\) decreases with the next local
endpoint power.

Finally, the reusable endpoint-expansion function was applied to the two
families using only their slopes \(a\) and Laurent coefficients
\(c_{a,n}\).  Its independently assembled coefficients satisfy

\[
\Delta_{\delta}=\Delta_{[1/\rho]_+}
=\Delta_{[\ln\rho/\rho]_+}
=\Delta_{[\ln^2\rho/\rho]_+}=0
\]

exactly against the stored NLO distribution record.

## Endpoint data required from an NNLO master calculation

For each master and each physical endpoint, the transport calculation must
provide:

1. the exact loop-measure and cut normalization;
2. the regulator symbol and the convention for \(D\);
3. the endpoint variable and the physical side from which it approaches zero;
4. the rational-coefficient valuation in that variable;
5. every local master exponent that survives the physical boundary
   conditions;
6. the branch of every logarithm, root, and noninteger power;
7. the Laurent depth needed after multiplication by the endpoint
   distribution;
8. an exact residual for the differential equations and numerical values at
   independent chamber points.

This NLO calculation shows why the rational valuation alone is insufficient:
the unit-argument hypergeometric branch changes the endpoint exponent by
\(-1-\epsilon\), and the separate phase-space normalization contributes an
additional \(-\epsilon\).
