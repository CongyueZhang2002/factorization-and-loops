# Common differential-equation workflow

The core finite constructor, epsilon-order propagation and path solution
already accept an ordered list of kinematic variables. The next work must
consolidate the integral-definition and calculation interfaces around those
implementations. A one-variable restriction and a multivariable connection
are inputs to the same solver, not separate process solvers.

## Completed interface corrections

- All finite preparation/construction/order interfaces apply an explicitly
  declared dimension rule to dense coefficients, including when the input
  matrices are sparse. Saved original connections and basis matrices use the
  same convention. No dimension replacement is applied to geometric momentum
  labels inside integral definitions.
- The shared regulator series routine validates a finite Laurent expansion
  before extracting coefficients. An essential singularity or a fractional/
  logarithmic regulator term is rejected; a regular omitted Taylor tail keeps
  its proven lower bound.
- Exact affine cut equivalences preserve the type and power of every cut.
  Particle cuts carry oriented momenta; measurement cuts carry their exact
  linear polynomials and no energy theta. Only particle momenta select new
  loop coordinates. Ordinary prescriptions, numerator powers, explicit
  measures, time directions and domains remain part of the identity.
- Scripts/reduce_current_master_system.wls obtains component inventory from
  the contribution card and constructs one shared DE with explicit target
  substitutions. It calls the same global-DE reduction used for ppHX.

## Shared definitions and solution interfaces

The common momentum-space builder now accepts both existing topology inputs
and typed particle/measurement cuts. It retains the supplied measure exactly,
and the existing Baikov constructor consumes that same definition. Measurement
cuts do not count as on-shell particles and carry no positive-energy theta.

Finite preparation, order propagation and stored solutions use one code path
for any number of kinematic variables. Regression examples at one, two and
three variables check every differential equation and the constant convolution.
The existing ppHX CF269 workflow regenerates all 92 requested coefficients.
Evolution along a one-parameter path and an expansion normal to a boundary
remain distinct objects; a boundary coefficient may depend on the remaining
kinematic variables.

The elementary measured phase-space provider supplies explicit Gamma/Beta
volumes for any massless particle multiplicity and finite measurement-cut
derivatives. Particle dots require their actual normal extension and are
excluded from this massless formula. Other geometries return the same integral
representation fields for the common boundary and order interfaces.

Remaining consolidation:
1. The fixed-slice normal-derivative extension is implemented and tested;
   see CutIntegralLaurentBounds.md. It uses the existing compact-cut theorem
   and retains endpoint scope restrictions.
2. All 42 shared masters now have derived bounds with exact scale restoration
   and verified finite solutions through epsilon zero at generic kinematics.
   Determine their physical boundary constants and propagate final coefficient
   and endpoint requests before claiming complete NNLO coverage.
3. Extend reusable local geometry providers and boundary matching; preserve
   the distinction between fixed-point bounds and external endpoint limits.
4. Complete mixed virtual/cut typed factorization and the joint helicity
   treatment for real-virtual contributions.

The current SIDIS shared q-q RR system has 42 spanning masters across four
components, after 248 family-basis entries and 57 affine equivalence classes.
This does not modify or retrospectively minimize the previous ppHX system.
The retained ppHX records show 1561 -> 355 -> 348, with 345 requested masters
and a 346-dimensional requested derivative closure.

## Polarized current and finite schemes

Physics/CurrentSpinAverages.wl uses the joint average of the incoming helicity
density and the electromagnetic 2g1 projector. It checks the two-epsilon
scope, full-D remaining tensors and all declared integrated momenta. It does
not redefine the standalone PDF. Both virtual and cut momenta must participate
in the same angular geometry for mixed contributions.

Physics/Counterterms.wl supplies the finite PDF matrix in individual flavor
space through the second power of alpha_s/(2 Pi), including its order-zero
gluon identity. The channel charge comes from the intermediate Born channel
when the inverse matrix acts on hard coefficients. A matching raw operator
definition is required before using the kernels in NNLO assembly.

Sources: [Bonino et al., Appendix A](https://arxiv.org/html/2510.00100v1#A1),
[Moch, Vermaseren and Vogt, Appendix A](https://arxiv.org/pdf/1409.5131).

## Numerical validation with symbolic parameters

Automatic rational sample points include scalar parameters present in the
connection and basis matrices, in addition to every DE variable and epsilon.
The path pullback keeps these parameter assignments, and the initial inverse
basis is checked for each assignment. Explicit incomplete points receive a
missing-parameter failure, not a differential-equation mismatch. The solution
retains the symbolic parameters; sampling is only validation.

The finite constructor also verifies exact cancellations below the connection
entry valuations before sharing expressions as named kernels. This prevents
a proved zero from being treated as an independent formal integrand.
