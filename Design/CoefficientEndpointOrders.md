# Epsilon and normal orders for a scalar master-integral combination

`DetermineMasterCoefficientEndpointOrders` takes coefficient entries aligned
with a symbolic tangential endpoint system. Every source coefficient retains
its analytic prefactor and either its exact expression or its explicitly
known finite Laurent coefficients.

For a normal system written as

    I = T(v,z,epsilon) H(v,z,epsilon) z^R(v,epsilon) c(v,epsilon),

the planner first forms the scalar row W = c_integral^T T. Here
c_integral denotes the coefficients multiplying the master integrals; it is
different from the normalized leading vector c. The minimum normal Laurent
order of W determines how many regular Frobenius coefficients H_n can
contribute a nonintegrable power. With normalized residue eigenvalues of
zero integer part, a sufficient depth is

    N = max(0, -1 - min_j ord_z W_j).

The scalar projector must combine W with the **normalized** H_n matrices.
Truncating every original master at one common order after multiplying by T
can lose a needed coefficient of another row. A diagonal gauge with different
powers of z is already a counterexample.

Epsilon bounds apply separately to regulated primary sectors, including
spectral-projector poles and logarithmic modes. Bounds for the sum of those
sectors may be higher because their poles cancel, and cannot replace the
individual bounds in a distribution-order argument. For a mode with
Log[z]^l and an affine nonzero regulator slope, endpoint contact moments can
lose l+1 epsilon powers. The planner propagates this loss through every
coefficient prefactor.

The current implementation keeps conservative sufficient bounds when exact
leading coefficients have not been simplified. A reported missing order is
therefore an unresolved sufficient-order demand, not proof that the unknown
coefficient contributes. Exact physical projection can remove such a demand.
Known finite prefixes are truncated further when their higher coefficients
are already proved irrelevant; an unknown tail is never set to zero inside
the requested range.

The construction applies on a smooth single boundary divisor. Coalescing
divisors such as z+epsilon invalidate the joint normal/epsilon argument and
are rejected. Uniformity of a retained coefficient remainder and treatment of
the other boundaries remain part of the input's mathematical validity.

The focused test `Tests/Coefficients/t_coefficient_endpoint_orders.wls`
covers coefficient/gauge cancellation, deeper H demands from gauge poles,
Jordan-logarithm contact losses, finite-tail availability, and coalescing
divisor rejection.
