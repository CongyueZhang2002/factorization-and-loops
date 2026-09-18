# Inclusive scalar values and interval distribution completion

Actual ChatGPT 6 Pro, completed after8m43s on2026-09-18.
Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84
Exact pushed revision inspected:9b5a0e43b0d720b5c6d70d6959f933724272fe1e.
This is a retained summary of source inspection and algebraic review. Pro did
not execute the Wolfram tests or inspect the seven saved production values.
No published measured NLO EEC coefficient was used or compared.

Inspected OneLoopPhaseSpace.wl, both scalar tests and the universal scalar design
note, inclusive stages in MeasuredOneLoop.wl, master-library/provider/definition
interfaces, scalar PaVe conventions, mixed routing, and the full contact proof.

## Normalization and expansion orders

The bubble provider's internal tensor reduction supplies i*pi^2 and its scalar
PaVe evaluator supplies pi^(-epsilon). Together these give raw d^D ell exactly
once. The external family-measure/standard-phase-measure ratio is correct; no
additional PaVe conversion belongs in the amplitude contraction. The unnormalized
Dirichlet Gamma quotient and simplex affine-denominator substitution are correct.

The box family value is familyMeasure/standardPhaseMeasure * i*pi^(D/2) * U8.
For raw loop measure its leading coefficient is5i/(256*pi*s^2); the absorptive
real coefficient at epsilon^-3 is-5/(256*s^2). The Euler-integral expansions in
the design note reproduce the implemented universal scalar coefficients. This
is algebraic review of that separately derived integral, not a hard coefficient
comparison or a new numerical Euler evaluation.

The scalar demand h-min_i val(C_ij) and box coverage h-val(normalization)<=0
are correct. Preserve every implied lower pole and add the conjugate only AFTER
contracting the complex masters with the generated amplitude coefficients.

## Required interface repairs

A count of three positive unit massless cuts does not prove standard decay
geometry. For example changing a declared cut p1 to2p1 changes its delta by1/4
while a label-based Dirichlet evaluator would miss that factor. Require the
actual cut momenta to be p1,p2,q-p1-p2 up to a verified permutation in the stated
frame, or a complete map with its Jacobian. Reject dimensions other than4-2eps.
The exact box reference match already includes these physical conventions.

Fresh Gamma providers returned ExactValue whereas warm library hits returned
finite Coefficients and coverage. Normalize both at one boundary. Exactness of
a Gamma function is not exactness of its truncated Laurent tail. This is now
repaired in EvaluateWithMasterIntegralLibrary for all providers and modes.

The single-minimum mixed-signature caveat remains only a possible false negative;
accepted existing maps are exact. It is not necessary to alter the successful
box match. The later direct common-frame indexing repair is beyond this revision.

## Coefficientwise endpoint theorem

The implemented proof is stronger than a bare contact-order label. It resolves
z(1-z)F(z,x,epsilon), including the complete prefactor, original prescribed
products, all corners and seams, into powers with nonnegative integer parts
and uniformly finite-meromorphic smooth factors. Clearing finitely many epsilon
poles gives a holomorphic L1-valued function on a small complex epsilon disk.
Cauchy extraction and energy integration therefore imply
z(1-z) f_n(z) in L1(0,1) for every retained Laurent coefficient. This applies to
each COMPLETE certified coefficient, not necessarily each expanded GPL summand.

For smooth phi, phi(z)-(1-z)phi(0)-z phi(1)=z(1-z)psi(z), with smooth psi. Thus
E[f_n][phi]=integral_0^1 f_n(z)[phi(z)-(1-z)phi(0)-z phi(1)] dz
is an absolutely convergent distribution. It has vanishing zeroth and first
moments. The ordinary-contact proof then uniquely fixes
S_n=E[f_n]+(m0_n-m1_n)delta(z)+m1_n delta(1-z).
The generated ordered EEC moments m0=T,m1=T/2 include self pairs already.

Interior and inclusive rate must share the exact physical source, normalization,
flavor/state sums, regulator, coupling convention, causal branches and Hermitian
orientation. Store a DISTINCT interpolation finite-part convention. Its equal
contacts need not remain equal in the conventional logarithmic-plus basis.
Multiplication by a nonconstant function requires induced contact corrections.
A complete RV distribution still does not complete the full alpha_s^2 result.
