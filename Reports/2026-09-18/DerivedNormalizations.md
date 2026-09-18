# Derived physical normalization and card migration

Completed 18 September 2026. This implements the
[17 September card audit](../2026-09-17/CardNormalizationAudit.md) and the user's
request for a dedicated normalization directory. Accepted coefficient files were
not overwritten. This was an implementation, derivation and regression campaign,
not a cold regeneration of every NLO/NNLO project.

## Ownership and production changes

[FeynFacet/Normalization](../../FeynFacet/Normalization/README.md) now owns:

- Identical-state factorials, inclusive-tag and tuple orbits, external flavor
  multiplicities, overlapping flavor-component rejection, and cut-ghost signs.
- Bare PDF/FF sewing and its adjoint on the declared hard density; coordinate
  maps and endpoint measures derived from momentum rescaling. Both the fixed
  current and invariant ppHX routes use the same mathematical constructor.
- Observable tensor conventions and generated reference normalization, one
  exact bare-coupling conversion, flux and phase-space normalization, and
  physical-to-normalized master-integral measure conversion.
- Exact measurement/projector covariance needed before replacing the full
  operator action by ordinary Mellin convolution of a reduced coefficient.

Ordinary and counterterm distribution operators remain in
`Physics/Distributions.wl`; they are not duplicated in the new folder.

All 355 authored cards load. Every ordinary contribution compiles through the
shared external-state counting. Cards specify unobserved flavor summation labels;
the same model's active flavors and charges determine the resulting multiplicity.
Duplicate model aliases and overlapping equivalent external-state sums fail.
Inclusive tag reduction requires the complete amplitude. Explicit EEC tuple sums
retain the full final-state factorial.

The authored reader rejects independent `SymmetryFactor`, `AssemblyWeight`,
`FlavorMultiplicity`, `CurrentNormalization`, `BareCouplingRules`, `CollinearMaps`,
`EndpointPowers` and `EndpointConditions`. The compiler constructs the necessary
internal quantities. Observable conventions, finite operator schemes, spin
correlations and result-card linear-combination weights remain legitimate inputs.

Endpoint powers and regularity are derived from the actual scalar expression in
`Coefficients/EndpointConditions.wl`. Checks include joint faces, interior poles
and moving regulator singularities. Unsupported geometry or analytic functions
return an unresolved-condition failure instead of a handwritten proof. Five stale
NNLO reduction donor paths and their obsolete driver branch were removed.

## Independent review and normalization anchors

Actual **GPT-6 Pro** completed two reviews: the overall design and a follow-up on
integrated tagged measurements and gluon operator sewing. See the
[review record](../../External/ChatGPT/Records/2026-09-18/01_normalization_and_state_counting_review.md).
It emphasized measurement orbits, indistinguishable flavor-block automorphisms,
the conventional status of the spectral `1/(4 Pi)`, and retaining evanescent
information before dimensional integration.

The implementation checks normalization independently of a generated denominator:
the free-current Wick trace and canonical recoil delta reproduce the DY reference;
physical Born charges and positive epsilon coefficients are checked separately.
Gluon field-strength extraction includes both momentum factors, and tests cover
the unit-delta state and a nontrivial fraction moment. No fitted overall coefficient
or literature formula was added to production.

The Mellin check rejects a physical-only tagged measure used with the dimensional
FF convention, an extra tagged energy weight, and a fixed acceptance cut. Existing
SIDIS UU/LL projectors pass at generic dimension. A different observable may need
an enlarged tensor or measurement basis; that extension is not silently assumed.

## Validation

**211 assertions in 16 suites passed.** The table gives supervised wall time,
including launcher/kernel startup, for the retained successful run of each suite.
These are test timings, not project-production timings. Each used one CPU and
had zero startup retries. No owned computation remains running.

| Check | Assertions | Seconds |
|---|---:|---:|
| State, flavor and measurement counting; ghost signs | 29 | 1.166 |
| Authored/compiled cards and model aliases | 14 | 25.381 |
| Measurement covariance and incoming gluon sewing | 12 | 17.893 |
| Absolute current, phase-space and coupling normalization | 10 | 18.078 |
| Existing complete EEC result against independent reference | 14 | 19.413 |
| Derived endpoint conditions and negative controls | 8 | 18.276 |
| Derived current/scattering momentum maps | 9 | 17.816 |
| Mapped current convolution and modified-weight rejection | 8 | 21.497 |
| Invariant counterterms, plus distributions and mixed insertions | 30 | 24.331 |
| Fresh SIDIS UU/LL Born coefficients | 12 | 21.527 |
| Fresh current real/virtual contributions and pole cancellation | 6 | 39.704 |
| Noncommuting counterterm matrix ordering | 8 | 16.844 |
| Fresh NNLO counterterm sources and custom finite operator | 14 | 17.466 |
| Born kinematic/normalization identities | 8 | 21.381 |
| Production scattering symmetry factors | 7 | 15.812 |
| Master measure conversion and finite coefficient orders | 22 | 0.765 |

The EEC check compares endpoint contacts, logarithmic-plus coefficients and the
regular coefficient with the independent formulas in `Tests/Physics/t_eec_complete.wls`,
and checks inclusive moments. It verifies existing accepted data; it is not a new
EEC production run. Fresh current checks generate amplitudes; fresh counterterm
checks regenerate Born sources in temporary consumer-owned work without reading
a sibling LO result.

Two older regression drivers still referred to retired project paths. They now
use `Raw/<order>/<channel>` and the source-owned counterterm interface; their
assertions pass on the current workflow. The direct coefficient test loads the
new master-normalization module explicitly. The package layout audit covers
279 listed modules with no errors; `git diff --check` passes.

Machine-readable evidence: [NormalizationChecks.json](NormalizationChecks.json).
Exact logs, original migration snapshots and launch records are in
[the run archive](../../Archive/Runs/2026-09-18-DerivedNormalizations).
Existing production timing tables were not changed or relabeled.

## Limits

The new layer removes independent derived inputs and checks the supported
mathematical representations. It is not a claim that all possible observables,
flavor-sensitive measurements or endpoint geometries are implemented. Flavor
compression requires complete unobserved-state equivalence; a leading tag or
flavor-resolving cut must not reuse the inclusive counting rule.
The regressions do not replace a future cold full-project campaign. No discrepancy
in an accepted overall physical coefficient was established in this work.
