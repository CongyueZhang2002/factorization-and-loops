# Physical normalization

Cards specify the observable, fields, polarization, active model flavors,
operator scheme and coupling convention. This directory derives the factors
that follow from those definitions. It is loaded by `Kernel/Modules.wl`.

| File | Responsibility |
|---|---|
| `StateCounting.wl` | Identical-state factorials, inclusive measurement orbits, external flavor assignments and overlap rejection, cut-ghost signs |
| `CollinearOperators.wl` | Bare scalar operator extraction, longitudinal sewing and the adjoint weight on a stored hard density |
| `MomentumRescaling.wl` | Coordinate maps induced by PDF/FF momentum rescaling, physical endpoint branch and density-prefactor ratio |
| `MeasurementConvolutions.wl` | Exact covariance of the retained measurement/projector kernel; verification that ordinary Mellin convolution is valid |
| `Observables.wl` | Cut-tensor versus measured hadronic-tensor conventions and explicitly generated Born reference normalization |
| `Couplings.wl` | One exact bare-coupling convention for amplitudes and UV/collinear subtraction |
| `PhaseSpace.wl` | Incident flux, canonical on-shell density and invariant cross-section normalization |
| `MasterIntegrals.wl` | Conversion between the physical integration measure and the declared master-integral measure |

Distribution and counterterm **operators** remain in `Physics/Distributions.wl`.
Spin tensors and current projectors remain in `Physics`. Measurements and their
delta Jacobians remain in `Physics/Measurements.wl` and the integration geometry.
This directory consumes their definitions; it does not keep a second copy.
`Coefficients/Normalization.wl` performs rational coefficient extraction and
reconstruction, not an independent set of physical overall factors.

## Card declarations

For example, a current calculation can declare:

```wl
"ObservableNormalization" -> <|"Tensor" -> "HadronicTensor", "Coefficient" -> "TensorProjection"|>
```

`HadronicTensor` means the complete measured spectral sum divided by `4 Pi`;
`CutTensor` means the canonical cut sum itself. This is a choice of observable
definition, not something that can be inferred from particle content alone.
`BornNormalized` additionally selects a generated unit-charge Born reference,
its channel, tensor structure and epsilon order (currently zero).
The same tensor convention applies to the numerator and its reference, so its
constant spectral prefactor cancels in a Born-normalized ratio.

An unobserved flavor sum declares its dummy labels, for example
`"FlavorSum" -> {"c"}`. Their equivalence classes come from the same massless
model/charge declarations used to generate amplitudes. Fixed incoming and
observed flavors are excluded. No separate numerical multiplicity is supplied.

The authored-card reader rejects `SymmetryFactor`, `AssemblyWeight`,
`FlavorMultiplicity`, `CurrentNormalization`, `BareCouplingRules`,
`CollinearMaps`, `EndpointPowers` and `EndpointConditions`. Their compiled forms
are derived internally where needed. `BareCouplingFactor` remains the single
explicit exact coupling convention. Result-card weights describe a requested
linear combination; they are not a place to repair normalization.

## State sums and domain of validity

`FullTupleSum` retains `1/product(N_species!)` and the explicit measurement sum.
`OneTuplePerOrbit` multiplies this by the orbit of an inclusive representative
tuple. For three identical particles, self pairs have orbit 3, ordered distinct
pairs orbit 6, and unordered distinct pairs orbit 3. A leading-particle cut is
not an inclusive tag and cannot use that reduction without a separate proof.
Production inclusive-tag reduction requires the complete amplitude.

Flavor assignment counting applies to fully integrated, equivalent unobserved
flavors. It does not merge separately measured flavor densities or internal
loop charge sums. Components with the same amplitude/measurement context may
not overlap in their external-state flavor sums. New measurements distinguishing
otherwise identical states must retain the explicit state sum or provide the
appropriate covariance derivation.

## Collinear action

For `h_i=N_i H_i`, derive the weight as
`W_i(xi y)/W_j(y) * N_j/N_i(mapped momenta)`.
Canonical current sewing gives `W_PDF=1/x` and `W_FF=z^(-(D-2))`.
The invariant scattering flux can cancel the incoming factor. These are derived
from the declared density, not selected by a process name.

For a dimensionally integrated tagged coefficient, the FF sewing weight,
on-shell measure scaling and linear measurement-delta Jacobian combine to
`d xi/xi`. `VerifyCollinearMeasurementCovariance` checks the full retained
tensor kernel at generic dimension. It substitutes derived coordinates first.
An extra energy weight, a fixed acceptance cut, or a physical-only tagged
measure fails this ordinary Mellin test. Unsupported tensor/measurement
representations fail explicitly; they are not silently certified.

Momentum-map and covariance derivations are cached by their exact mathematical
definitions within a kernel. No persistent hashes are introduced.

## Extending and checking

Add a new convention here with its defining equation and an independent absolute
normalization test. Never infer a conversion from agreement with a final answer.
Keep mathematical regularity checks in `Coefficients/EndpointConditions.wl`;
normalization does not prove an endpoint expansion valid.

See [the Pro review record](../../External/ChatGPT/Records/2026-09-18/01_normalization_and_state_counting_review.md),
[the fragmentation derivation](../../Design/FragmentationNormalization.md),
and [the tests and timings](../../Reports/2026-09-18/DerivedNormalizations.md).
