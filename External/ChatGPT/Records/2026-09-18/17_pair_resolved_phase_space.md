# General pair-resolved four-particle phase space — completed mathematical review

Actual ChatGPT6Pro, existing conversation:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

The request supplied pushed revision8c92f11b5e1539f748e85b36d3f8235d7e65dcda
and identified this as a mathematical proposal, not a new implementation.
See Design/PairResolvedPhaseSpace.md for the complete proposed coordinate map,
all six invariants, normalized angular measures, absolute density and inclusive
beta-function normalization derivation transmitted to Pro.

Pro was asked to independently check constants, signs, coverage and dimensional
angular continuation, suitability as a general coordinate option before arbitrary
polynomial measurement pushforward, and which endpoint/degenerate charts must
be analyzed before fixing actual master constants or contact orders. The request
explicitly forbids accessing the published measured NLO EEC coefficient. Universal
phase-space and scalar-integral mathematics is allowed. Full derivative closure
of DifferentQuarks was reported as37 spanning integrals, separately from physical
values and the other double-real components.

Completed after 9m7s. Pro independently checked normalization, invariant identities,
Gram determinant and beta-function volume algebra symbolically. It did not inspect
this implementation or run Wolfram tests. It confirms the proposed constants,
Jacobian, energy coverage and dimensional angular weights without modification.

The chart is one-to-one for generic scalar-product data with residual rotations
and reflections integrated. Oriented Levi-Civita observables require an additional
orientation label. Both parity orientations are already included; no factor two
or recoil-particle factorial is missing. Labeled recoil exchange sends
(a,b) to (1-a,1-b). The angular moments are <c^2>=1/(3-2epsilon),
<h^2>=1/(2-2epsilon); their mixed invariant correlation checks dimensional geometry.

Pro derived an independent unweighted pair-angle phase-space benchmark:
C(epsilon) s^(2-3epsilon) [z(1-z)]^(-epsilon)
 B(2-2epsilon,1-epsilon) B(2-2epsilon,3-3epsilon)
 2F1(2-2epsilon,2-2epsilon;5-5epsilon;z).
This is a universal phase-space period, not a measured hard coefficient.

Endpoint qualifications:
- d=1-z*x and K=1-z+z*rho are distinct mixed denominators. In t=1-z,
  X=1-x,Y=1-y, d=t+X-tX and K=t+(1-t)XY: both t~X and t~XY matter.
- z=1 at fixed rho>0 means antiparallel tags, not necessarily massless recoil.
  Correlated rho,t limits give different recoil-angle fractions zeta=z*rho/K.
- rho=0 degenerates the recoil rest frame. Keep rho^(-epsilon) before integration.
- Moving angular collinear loci are (b=0,a=zeta) and (b=1,a=1-zeta).
  Locally p2.p3/B=(a-zeta)^2/[4zeta(1-zeta)]+4zeta(1-zeta)b+... .
  Split at the moving polar position and use weighted sectors or b=v^2.
  These loci collide with polar faces as zeta tends to zero or one.
- Polynomial measurements can become algebraic in this chart. Every physical
  root, multiplicity and Jacobian must still be derived from the actual card.
- Only unit particle cuts use this on-shell measure; dotted cuts need reduction
  or an off-shell construction with all domain derivatives.
- Physical DE constants need enough independent period/moment/region constraints
  and a rank certificate. Coordinates or volume checks alone do not fix them.
- RR internal divergences persist even at interior z. For example 1/s34 makes
  rho^(-1-epsilon). Integrate or subtract those internal strata before proving
  a weighted L1 bound for the measured distribution and its contact order.

Recommendation accepted: retain the measure, store d,K,zeta,Gram and inverse
maps explicitly, evaluate supported unit-cut physical periods first, and resolve
actual singular strata rather than assuming endpoint cancellation. The complete
conversation retains the original detailed derivation and review.
