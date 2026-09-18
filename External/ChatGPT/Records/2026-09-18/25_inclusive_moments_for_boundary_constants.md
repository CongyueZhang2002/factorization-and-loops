# Inclusive moments for physical DE constants

Actual ChatGPT6 Pro,5m39s, same EEC conversation:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
The prompt supplied pushed76d83b7e0daa035d280424cf8d756808a43b07d6.
This response is mathematical advice, explicitly not a new source audit.
No published measured EEC hard coefficient was consulted or compared.

For a unit measurement cut M=z F-G, F>0, support0<G/F<1, and a
nonmeasurement kernel R independent of z, define J_R,N with numerator RF^(N+1).
For nonnegative p,q,N with N>=p+q:

    integral_0^1 dz z^p (1-z)^q J_R,N(z,e)
      = N_measure integral dPhi R F^(N-p-q) G^p (F-G)^q.

This removes the actual delta-function Jacobian; inserting1 instead ofF is
wrong. For negativeF use absoluteF with explicit sign bookkeeping. No changed
measure, particle labeling, or prescription is introduced. For a dotted cut
C_n(Fz-G), pairing with w gives w^(n-1)(G/F)/((n-1)!F^n), not the unit-cut rule.
Numerator insertion may require extra measured masters even after DE closure.
The unmeasured right side must really reduce to the available scalar input
catalogue at the required orders; the R4/R6/R8 list is not a universal guarantee.

Require a common initial convergence domain and then meromorphic continuation,
or an independently justified subtracted continuation. Integrate complete
rational reduction rows before expanding; their pieces can have artificial
endpoint poles. Regulated Frobenius terms t^(lambda(e)+n) log^k(t) integrate by
d_lambda^k[delta^(lambda+n+1)/(lambda+n+1)] before epsilon expansion. Their
coefficients may remain linear in the unknown constants. Endpoint-vanishing
weights require a proved contact-order bound for these integrals/combinations,
not a bound borrowed from the full observable.

After known donors/local conditions, write I=I_known+Y_U c. Moments give M c=b,
where M contains continued integrals of each moment row against Y_U, and b
subtracts the known part from the independently computed inclusive period.
Test a proposed moment on the residual nullspace before computing many new
inclusive reductions. Acceptance needs exact rank on unresolved modes, not a
count of constraints or numerical rank. A small scalar catalogue can supply
many independent linear functionals; conversely many moments can be redundant.
Keep an inexpensive unused moment for validation. A remaining nullspace defines
the combinations still needing physical boundary integrals.

Order requirements include valuations of inclusive reduction coefficients,
measured rational rows and basis gauges, regulated endpoint integrals, and the
inverse constraint matrix. Rank arising first at epsilon^r costs additional
orders. Use the existing Laurent product/omitted-tail audit; finite donor data
are not exact all-order functions.

For a rational rowv, define D_A v=v'+v A. An exact identity q=D_A v+r gives

    MC integral q I = MC [v I]_0^1 + MC integral r I.

A bounded rational ansatz can prove such identities and remove redundant
moment rows. Evaluate the full boundary product; it need not vanish even when
I does. Some residual periods are genuinely not rational derivatives.
For those, append accumulators V'=Q I with V(z0)=0 and propagate only unresolved
homogeneous columns through the existing DE machinery. This avoids nested
quadrature without promising a rational/GPL primitive in every geometry.

Recommended next artifact: original inserted integral, exact measured row,
exact unmeasured reduction, continuation prescription, endpoint/residual
decomposition, epsilon coverage and rank contribution. Try low-degree moments
first and compute new endpoint integrals only for the remaining nullspace.
This fixes interior master constants; it does not certify the complete RR
observable's endpoint contact order.
