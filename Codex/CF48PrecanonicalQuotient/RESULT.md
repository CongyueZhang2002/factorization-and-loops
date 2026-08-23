# CF48 quotient before epsilon factorization

Date: 2026-08-18

## Question

Can the physical projection and Laurent regularity be imposed directly on the
original CF48 differential system, so that only a smaller quotient needs to be
transformed to epsilon form?

## Exact measurements

The original system has 27 masters. The hard contribution demands the first 14
masters in the stored IBP basis.

Starting with those 14 row vectors, close under the two covariant derivatives

\[
\nabla_v q=\partial_v q+qA_v,
\qquad
\nabla_w q=\partial_w q+qA_w.
\]

After one derivative the rank is 27. The rank is 27 at each of the three exact
rational points

\[
(v,w,\varepsilon)=
\left(\frac15,\frac14,\frac1{11}\right),
\left(\frac27,\frac15,\frac1{13}\right),
\left(\frac3{10},\frac16,\frac2{17}\right).
\]

Therefore the differential module visible to the demanded masters is the full
27-dimensional family. There is no nontrivial output quotient to canonicalize.

The original connection begins at order \(\varepsilon^{-2}\). Finiteness of
\(I=I^{(0)}+\varepsilon I^{(1)}+\cdots\) imposes

\[
A_{-2}^{(v)}I^{(0)}=A_{-2}^{(w)}I^{(0)}=0,
\]

and at the next order

\[
A_{-2}^{(x)}I^{(1)}+A_{-1}^{(x)}I^{(0)}=0,
\qquad x\in\{v,w\}.
\]

At the same three points, the first constraints have rank 1 on the 27
components of \(I^{(0)}\). The combined constraints have rank 3 on the 54
components of \((I^{(0)},I^{(1)})\). Thus regularity removes only one leading
direction and three two-jet directions.

## Why the CF27 construction cannot be moved earlier

In epsilon form,

\[
dF=\varepsilon\sum_a R_a\,d\log\phi_a\,F,
\]

the equation for \(F^{(n)}\) depends only on \(F^{(n-1)}\). A finite Laurent
window is therefore invariant and can be quotiented exactly before generating
transport words.

For the original CF48 connection, \(A\sim\varepsilon^{-2}A_{-2}+\cdots\), so
the equation for \(I^{(n)}\) depends on \(I^{(n+2)}\). Repeated differentiation
of a finite window introduces arbitrarily high Laurent coefficients. Removing
this upward coupling is the epsilon-factorization problem itself.

## Conclusion

The pre-canonical physical quotient is not a useful speedup for CF48. The full
family epsilon form must still be constructed. Once that is done, the CF27
pre-transport valuation and observable-only word recursion remain applicable
and may substantially reduce the later transport.

The measurements are reproduced by `MeasurePhysicalClosure.wls` and
`MeasureRegularityKernel.wls`; their exact records are
`PhysicalClosure_CF48.wl` and `RegularityKernel_CF48.wl`.

