# Joint endpoint projection of solved cut integrals

The general production interface is AssembleProjectedEndpointDistributions.
It accepts a finite bulk Laurent series and complete profiles on every
nonempty coordinate face. Profiles may have integrable tangential logarithms.
They are not treated as jointly smooth test functions. Several regulator
power classes can share one complete bulk expression.

For two simple endpoint powers, p(t)=t^(-1-2 epsilon), the SIDIS calculation
establishes the all-epsilon identity

F = p(rho) A(sigma) + p(sigma) B(rho) - p(rho) p(sigma) C + R.

The finite target through epsilon^q requires A and B through q+1, C through
q+2, and the bulk through q. All lower Laurent tails must be retained.
An omitted-coefficient audit verifies these demands using the actual
distribution-valued monomial multipliers.

## Uniformity required before distribution assembly

A logarithmic master DE alone does not establish scalar endpoint regularity.
AnalyzeNormalCrossingScalarCoefficients includes every physical coefficient
row and the complete gauge. VerifyUniformNormalCrossingPhysicalGerm additionally
checks a common epsilon rescaling of both connections and their scalar rows
and seed. Every rational denominator, after cancellation, must be an epsilon
power times an analytic unit in the joint coordinate/regulator local ring.
Fixed-coordinate epsilon valuations do not suffice: 1/(r+epsilon) is a
counterexample. The nonresonant compatible Frobenius normalizer is convergent
and epsilon-analytic on a smaller common polydisc. The selected physical
joint eigenvector retains only its prescribed scalar powers.

VerifyRadialEndpointCollar extends this reasoning over compact subsets of
the remaining open tangential intervals. A physically invariant boundary
subspace is checked against its own epsilon-regular tangential connection.
A positive rational tangential change can move an ordinary point to a new
origin; PullBackEndpointBoundaryValues retains any regulator-dependent
analytic unit and checks the full gauge comparison and boundary equation.

## The resolved two-variable example

With rho=1-x and sigma=1-z, the verified charts are

1. rho=r, sigma=r^2 t, Jacobian r^2.
2. rho=r^2 t, sigma=r^2 t^2, Jacobian 2 r^3 t^2.
3. rho=r^2 t, sigma=r^2, Jacobian 2 r^3.

Write J F = K Q with K=J p(rho)p(sigma). The exact exceptional profiles give
Q_j(0,t)=C, and Q_2(r,0)=C. Analytic coordinate division yields

a(sigma)=A(sigma)-C p(sigma)
        =sigma^(-1/2-2 epsilon) aSharp(sqrt(sigma)),
b(rho)=B(rho)-C p(rho)=rho^(-2 epsilon) bSharp(rho).

The square-root estimate is sufficient; analyticity in sigma is not claimed.
The subtracted remainder satisfies

J_1 R = r^(-6 epsilon)t^(-2 epsilon) H_1
      - r^(-6 epsilon)t^(-1/2-2 epsilon) aSharp(r sqrt(t)),
J_2 R = 2 r^(-8 epsilon)t^(-6 epsilon)
          (H_2-aSharp(rt)-r bSharp(r^2 t)),
J_3 R = 2 r^(-8 epsilon)t^(-2 epsilon)
          (H_3-r bSharp(r^2 t)).

All analytic factors have a common finite epsilon pole envelope. On a
sufficiently small epsilon disc contained in |epsilon|<1/32, the worst
coordinate powers are strictly greater than -1. Dominated Cauchy integration
then proves L1-valued meromorphy, allowing coefficient extraction inside
test-function integrals.

The positive-t collar of chart1 covers the chart2 r=1 seam. At the diagonal
seam use x=1-r^2(1+u), z=1-r^2. The complete u^2-normalized scalar numerator
is jointly meromorphic and analytic. Direct specialized loop IBPs cancel
its first two u jets for every r>0; analyticity extends those identities
to r=0. The finite Taylor integral quotient preserves the uniform pole
envelope. An ordinary-point cancellation without this joint bound would
not suffice.

## Physical continuation and result storage

The original prepared integrands, before partial fractions, have jointly
integrable high-dimension representatives certified by the existing single
prescription-removal theorem. Polynomial source numerators are dominated on
the compact timelike cut domain without expanding their large numerators.
The algebraic subtraction holds there, and fixed physical boundary data
continue the equality meromorphically. This excludes additional arbitrary
face, corner or artificial-seam contacts.

Specialized integral families are checked for affine scalar-product rank,
mandatory-cut rank, nonzero ordinary propagators on the cut ideal,
external Gram nondegeneracy and a timelike energy reference. The direct
diagonal IBP rows are generated after restriction; solved rational
reductions containing 1/(x-z) are not specialized.

The driver Scripts/assemble_endpoint_profiles.wls reads an explicit shared
solution/profile manifest and current channel cards. It writes the common
PartonicResult format. Distribution extraction collects only in delta/plus
symbols and keeps large GPL coefficient functions factored. Auxiliary
normal-coordinate names are absent from the physical distribution basis.

The process proof records live under its own Results directory. The above
example was reviewed with verified GPT-6 Pro; record35 is in
External/ChatGPT/Records/2026-09-10/35_uniform_corner_remainder.md.
