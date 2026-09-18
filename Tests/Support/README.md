# Independent mathematical references

These files are loaded explicitly by tests, never by the production package:

- FamilyRowBasisTransformationFiniteField.wl independently evaluates row basis
  transformations over finite fields, for comparison with the production
  multiquadratic implementation.
- MultiquadraticMixedGradeLetters.wl supplies the experimental letter-discovery
  reference exercised by the off-diagonal transformation tests.
- NLO/numeric_nlo_masters.wls independently integrates the seven NLO example
  masters over angular variables. It records the origin of the numerical
  reference values in Reconstruction/t_nlo_masters.wls.

The first two implementations moved from Prototypes without changing their
mathematics. They are references for tests, not supported production interfaces.

## Counterterm comparisons

`BornCollinearReference.wl` retains the independent Born delta-density
rescaling and plus-distribution pullback in the `FTBornCollinearReference`
context. It is loaded only by the focused collinear test and the NLO
spin-transfer validation; production uses the general invariant convolution.
The spin-transfer check generates its epsilon-zero Born sources in its own
validation directory and does not read standalone LO results.

`CountertermComparison.wl` independently compares complete delta, plus and
regular Laurent scalars after checking physical conventions and requested
coverage. Exact positive-rational logarithm identities and declared physical
assumptions are applied in validation.

## Complete source generation and analytic orders

`check_nlo_positive_epsilon_sources.wls [Real|Virtual ...]` evaluates accepted
exact reduced qqp inputs through epsilon one and compares all pole and finite
scalars. It independently checks each epsilon-one renormalization-scale
derivative. `check_fresh_scattering_sources.wls [owned-consumer-project]` starts
from shared physics in an empty consuming NNLO project, generates diagrams,
Kira reductions and reconstructed coefficients, then compares the results
through epsilon one with those retained-input calculations.

`check_nlo_only_scattering_source.wls [replay]` covers a genuine real-only
observed-gluon channel with no same-channel Born or Virtual contribution. The
fresh run generates all upstream inputs; `replay` checks its saved coefficients
and component artifact ownership. `check_nlo_only_subtraction.wls` reuses the
source and automatically generates the physical Born counterterm neighbors,
requiring exact pole cancellation and a fraction-independent finite density.

`check_scattering_source_coupling_covariance.wls` checks the shared executor's
physical bare-coupling powers against retained reduced inputs. The complete
real-emission convolution benchmark is
`check_scattering_real_counterterm_convolution.wls`; consult its result report
for completion before treating it as passing evidence.

These checks each require one allocated main Wolfram kernel. They preserve
accepted production results. See the
[unification record](../../Projects/ppHX_UU/NNLO/qqp-qqp/Results/Validation/CountertermUnification_2026-09-12/README.md)
for exact retained inputs, final outputs, timings and intermediate cleanup.

The retired aggregate counterterm migration checks are archived. Use
`Scripts/Validation/check_project_results.wls` for saved result-card and optional
baseline validation, plus the Core source-owned counterterm tests. The shared
`CountertermComparison.wl` implementation remains the exact comparison reference.
