# Recoil-mass bound for three-particle phase space

This is a sufficient bound on physical DE solution space. It does not count
independent boundary integrals or supply their connection to ordinary-point
constants. The proof was checked with Pro; the complete exchange is in
[the consultation record](../External/ChatGPT/Records/2026-09-06/14_recoil_mass_scaling_bound.md).

## Hypotheses checked by the code

Let three future-directed massless momenta sum to \(Q\), with \(z=Q^2\to0^+\).
Use standard Lorentz-invariant phase space, without a kinematic normalization
\(z^{c\epsilon}\). Every cut has unit power. The loop routing has full rank
and constant rational coefficients.

An active ordinary denominator must be the square of a sum \(R\) of cut
momenta, or \((P\pm R)^2\), up to an overall sign of its momentum. Here \(P\)
is a future-null external momentum and \(P\cdot Q\) stays bounded away from
zero on the selected boundary neighborhood. Identically zero ordinary
denominators on the cut support are excluded. Scalar polynomial numerators
are allowed. Massive propagators and unrecognized positive-power linear
denominators are not included in this sufficient test.

For the current process, \(Q=a+b-c\), \(2a\cdot b=1\), \(v=2a\cdot c\),
\(w=2b\cdot c\), and \(z=1-v-w\). At fixed interior \(v\),

\[
a\cdot Q=(1-v)/2,\qquad b\cdot Q=(v+z)/2,\qquad
c\cdot Q=(1-z)/2.
\]

The implementation checks the propagator identities and these positive
projections. It does not infer eligibility from a family name.

## Uniform estimate in a real interval of large dimensions

The three-body measure scales as \(z^{D-3}\). Write \(R+S=Q\), with \(R,S\)
future causal. In the rest frame of \(Q\),

\[
R^0+|\mathbf R|\le \sqrt z,\qquad
R^2\le \frac{z}{P\cdot Q}\,P\cdot R.
\]

Thus, uniformly on the entire phase-space domain,

\[
|(P-R)^2|\ge
\left(1-\frac{z}{2P\cdot Q}\right)2P\cdot R,\qquad
(P+R)^2\ge 2P\cdot R.
\]

Also \(P\cdot R\ge P\cdot k_i\) for any constituent of a nonempty \(R\).
A two-particle invariant is \(R^2=zU\). The dimensionally continued positive
phase-space measure gives, with \(\alpha=D/2-1\),

\[
\left\langle X^{-p}\right\rangle_D
=\frac{\Gamma(\alpha-p)\Gamma(3\alpha)}
       {\Gamma(\alpha)\Gamma(3\alpha-p)},\qquad \alpha>p,
\]

both for \(X=(k_i+k_j)^2/z\) and for \(X=P\cdot k_i/(P\cdot Q)\).
For the latter, the energy and polar fractions have independent
\(\mathrm{Beta}(2\alpha,\alpha)\) and \(\mathrm{Beta}(\alpha,\alpha)\)
distributions. This supplies the displayed inverse moment.

For a product with total inverse power \(N=\sum_j p_j\), weighted Hölder
bounds it by individual inverse moments of order \(N\). These are finite for
real \(D>2N+2\), independently of the relative external directions. Polynomial
numerators are bounded. There is consequently a fixed integer \(M\), independent
of \(D\), such that

\[
|I(z,v,D)|\le C(D)z^{D-3-M}.
\]

The constant can be uniform in an interior neighborhood of \(v\). This argument
uses positive beta/Gram weights for a real interval of large \(D\), not only
integer-dimensional spheres. It controls simultaneous soft and collinear
regions without enumerating them.

## Consequence for complete regular-singular solutions

Work at generic \(\epsilon\), before expanding in it. A local component has
power/log germs with exponents \(a+b\epsilon+n\). With \(D=4-2\epsilon\), its
power relative to the bound is

\[
a+n+2b+3+M-(1+b/2)D.
\]

For \(b>-2\), this becomes negative at sufficiently large fixed real \(D\).
No finite integer shift or logarithmic polynomial can compensate. A complete
nonzero component of that slope violates the estimate. Leading-vector
cancellations are handled by taking its first nonzero later coefficient.

The forbidden coefficient functions vanish on a real interval away from
exceptional dimensions. Meromorphic continuation of the same physical integral
and local coefficient maps makes those coefficients identically zero near
\(D=4\). The inequality itself is not analytically continued.

The code verifies the integer diagonal gauges and characteristic polynomials
symbolically in epsilon. A non-Fuchsian block or an unresolved exponent is
retained conservatively. Algebraic multiplicities, including Jordan chains,
are counted in full.

## Raised cuts and sourced blocks

The estimate is not asserted directly for differentiated delta distributions.
Eligible unit-cut rows must observe a complete homogeneous block through the
differential row span

\[
E,\quad \partial_i E+EA_i,\quad\ldots .
\]

An exact rational specialization of full rank proves generic full rank.
Tangential derivatives are used only because the physical estimate is uniform
on an open tangential neighborhood. Unobserved blocks retain their freedom.

For an inhomogeneous block, compare two solutions with the same lower-sector
data. Their difference is homogeneous and satisfies the same estimate. The
count bounds the dimension of this affine freedom over inherited data; it
does **not** set the corresponding ordinary-point constants to zero.

The upper bound is the sum of retained block multiplicities. Exact derivative
closure first removes directions that cannot affect the requested masters.
A known scalar normalization fixes its one-dimensional source sector.

## Implementation

- `Integrals/Asymptotics/PhaseSpace.wl`: denominator and normalization eligibility.
- `Boundary/LocalLimits.wl`: generic-epsilon residues, multiplicities and
  differential observation tests.
- `DifferentialEquations/GlobalSystem.wl`: shared integral identities and exact
  closure of the requested masters.

The resulting dimension bound must remain distinct from a completed boundary
matching map and from a minimal list of new integrals to evaluate.
