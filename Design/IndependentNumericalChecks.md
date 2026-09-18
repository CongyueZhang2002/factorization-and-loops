# Independent numerical checks of partonic contributions

Status: feasibility assessment and proposed implementation sequence, 2026-09-11.
No new matrix-element provider, subtraction engine or phase-space checker has
been installed or run. Existing AMFlow and coefficient-reference checks remain
unchanged.

## Purpose and independence

Add a numerical path from amplitudes and measured phase space to weighted
partonic cross sections. Its reference calculation must not read production
IBP coefficients, master solutions, boundary constants, endpoint profiles or
distribution coefficients. Those artifacts are inputs only to the other side
of the comparison.

Share the process card's physical definition: external particles and tagged leg,
polarization, normalization, measurement, coupling, dimensional prescription,
factorization scheme and requested output orders. Sharing these declarations
is necessary to compare the same mathematical quantity. Independently verify
their implementation through phase-space volumes, Born normalization and
pointwise matrix-element comparisons.

Using a production D-dimensional unreduced amplitude in an independently
parameterized integral gives an independent integration check, but not an
independent amplitude check. Record that distinction explicitly.

## Two complementary reference calculations

### Direct regulated phase-space integration

This is the first useful check of the currently available bare double-real
result. Parameterize the original measured phase space, including all
Jacobians and the D-dimensional angular measure, before IBP reduction.
Use a separate sector-decomposition backend to extract numerical Laurent
coefficients of the complete weighted contribution.

[pySecDec](https://secdec.readthedocs.io/en/stable/gettingstarted.html)
accepts dimensionally regulated parameter integrals and generates compiled
integrators. It is a candidate for this path, not an already connected backend.
A cut phase-space integral must be exported as the appropriate parameter
integral; a cut propagator cannot simply be passed as an ordinary Feynman
propagator to the loop-integral interface. Physical interior singularities and
upper-endpoint singularities require valid parameterization and treatment.

Keep the exact regulator dependence of the source numerator, measure and
normalization through the backend's expansion. A four-dimensional amplitude
multiplied by a D-dimensional measure generally loses finite terms from
epsilon-dependent numerators times poles.

Begin with an independently derived two-body phase-space normalization and a
small known NLO real contribution. Then benchmark one actual complete RR
weighted contribution. Large unreduced sums may produce too many sectors;
measure generation, compilation and integration costs before extending coverage.
This approach does not guarantee that a full generic NNLO amplitude is cheap.

### Numerical subtraction for finite observables

The longer-term path follows the amplitude-plus-subtraction organization used in
[pp -> hX at NNLO](https://arxiv.org/html/2503.11489v2#S2).
Required ingredients are independent tree and one-loop amplitudes, the relevant
two-loop finite remainders, unresolved-limit counterterms, integrated
subtraction, UV renormalization and initial/final-state factorization.

[OpenLoops 2](https://arxiv.org/abs/1907.13071) is a candidate provider for
tree and one-loop quantities and the required correlations. Verify the actual
process library and interface coverage before declaring a channel supported.
It does not by itself supply a complete NNLO subtraction calculation.

Fragmentation requires flavor and momentum-fraction mappings that preserve the
observed hadron momentum in singular limits, plus time-like factorization
kernels; see the [fragmentation implementation](https://arxiv.org/html/2102.08267#S3).
Use a complete specified dimensional subtraction scheme and its conversion
terms. Do not mix a four-dimensional amplitude provider with a different
dimensional convention by fitting finite adjustments.

The [STRIPPER project page](https://th.ifj.edu.pl/poncelet/projects/2_stripper/)
describes a general NNLO framework with fragmentation. Availability of a usable
distribution and the relevant process interfaces has not been established here.
Access to the authors' existing implementation would provide a valuable
external comparison; this plan does not assume that it is available.
Implementing the full subtraction engine independently is a substantial
additional project.

## What to compare

For a bare contribution, compare every requested Laurent coefficient of its
action on smooth test functions in the measured variables. Evaluate the
numerical reference directly from the original integrand; apply the stored
distribution to the same test function on the production side.

For the current ppHX RR result, respect 0 < v < 1/3 and support away from w=0.
Use weights whose independent Taylor coefficients at z=1-v-w=0 probe delta
derivatives through order four, together with weights probing the interior
and the generalized plus terms. Ordinary point samples away from z=0 cannot
test endpoint distributions. Finite sets of moments are numerical tests,
not a proof of equality of distributions.

Bare RR remains infrared divergent even at generic measured kinematics.
A four-dimensional Monte Carlo with resolution cuts is useful for checking
amplitudes and resolved phase space, but cannot be compared directly with
the inclusive, dimensionally regulated RR result. The saved inclusive result
also cannot acquire internal resolution cuts after those variables have
already been integrated out. Do not identify cutoff logarithms with
dimensional poles without deriving the complete conversion.

For finite NLO/NNLO checks, sum all required contributions and compare
partonic weighted observables first, then bins with matched PDFs, FFs, scales
and observable definitions. Include the lower-order channels required by
factorization. A single bare RR channel is not a full finite NNLO prediction.

## Implementation sequence

1. Add independent matrix-element and phase-space normalization checks for an
   existing unpolarized NLO channel. Resolved phase-space tests establish only
   their declared coverage.
2. Demonstrate the regulated integration backend on a complete known NLO real
   contribution, then a small collection of current ppHX RR moments including
   endpoint-sensitive weights. Compare negative epsilon orders and finite parts.
3. Complete the finite NLO numerical path, including both PDF and FF
   factorization, and check its weighted observables against existing results.
4. Add a complete NNLO subtraction provider and two-loop input, starting with
   the declared UU channel and all its required contributions.
5. Extend process and polarization coverage only when the amplitude, scheme
   and subtraction interfaces support it. UU coverage does not establish LL/TT.

The immediate recommendation is steps 1-2. They test errors that reuse of our
own master solutions cannot expose, without first constructing an entire
second NNLO event generator.

## Cards, outputs and cost control

Extend the existing contribution/project cards with a validation section
specifying the mathematical observable, reference method, requested orders,
weights or bins and error/time budgets. Do not create a new card per sample.
Use process-independent adapters; forbid process names in integration logic.

Put reference builds, logs, values and comparison reports under the owning
Projects/<project>/<order>/<channel>/Results/Validation/IndependentNumerical.
Retain compact final reports and reusable compiled integrators locally.
Every report identifies shared inputs, independent components and absent
coverage. An unsupported channel or a time-limited estimate is not a pass.

Start with a few diagnostic weights and target errors of order 1e-3 to 1e-4
for nonzero totals, adjusted after measurement. Use absolute error targets
for vanishing pole sums. Retain integration uncertainty and covariance where
samples are correlated; a nominal integrator error is an estimate, not a
rigorous enclosure. Check repeat-seed stability and convergence before
acceptance. Never require AMFlow-like decimal precision from Monte Carlo.

Respect the eight-core aggregate budget. Batch weights, reuse compiled
integrators and allocate work according to contributions to the final
variance. Start on CPU; consider supported GPU evaluation only after an
actual integration bottleneck is demonstrated. Validation cost should remain
proportionate to the production calculation.
