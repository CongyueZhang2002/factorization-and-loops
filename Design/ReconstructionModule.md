# Rational coefficient reconstruction

The production path is `Reconstruct.wl` -> `FiniteField/Execution.wl` ->
`ResultAssembly.wl`. It uses scheduled native jobs, then writes the common
master-coefficient format. `Scripts/assemble_scheduled_coefficients.wls`
assembles an explicitly completed plan without launching missing jobs. For a
finite plan, its fourth argument supplies the current order-input request;
stored order proofs alone cannot establish that the current demand is unchanged.

Columns below the configurable size threshold share a rational trace; larger
columns run separately. Each completed job binds its input expressions,
master definitions, analytic signatures, aliases, series mode, executable and
result. A completion marker alone does not authorize reuse.

Native reconstruction threads are resolved from the operating-system CPU
allocation (affinity and FACET_CPU_COUNT), independently of the Wolfram kernel
licence limit and its OpenMP setting. Explicit requests are capped by that
allocation. A single reconstruction queue runs one native job at a time and
passes its full requested CPU budget to each pending job. Ordinary and finite
jobs should use this queue instead of separate fixed 7+1 allocations.

## Exact and finite coefficients

Full rational reconstruction is the default. There is no default epsilon
truncation. An explicitly requested finite reconstruction stores its integer
Laurent orders and truncation; the analytic signature multiplies `PreFactor`.
Gamma functions are not placed inside finite rational `Orders`.

For expensive columns, `PrepareCoefficientReconstructionPlan` derives the
plan before interpolation. A contribution card's `CoefficientReconstruction`
association declares `EndpointCatalog`, `SourceNormalization`,
`PhysicalNormalization`, `KinematicRules` and `Assumptions`; the upper order
defaults to the card's `EpsilonRange`. Dependency paths are relative to the
order/channel directory. These computational inputs do not change amplitude
or diagram identities. `CoefficientSimplification` calls the planner
automatically when these inputs are present; without them coefficients remain
fully rational.

The planner chooses candidate columns by `FiniteAboveBytes` (16 MiB by default).
It matches actual powered-integral definitions to the accepted cut catalog and
derives the complete analytic/physical multiplier through the same normalization
routines used by final assembly, using unit coefficients solely to extract that
multiplier. It does not read previous reconstructed coefficients.

`DetermineCoefficientReconstructionOrders` and the planner share one denominator
classifier. It requires fixed normal divisors and proved joint analytic units on
the stated tangential domain. Its bound includes the endpoint distribution pole,
logarithmic sectors and physical normalization. The planner composes source
alias decoding, color rules, dimensionless coordinates, physical normalization
and endpoint substitutions in their production order. The supported effective
map is affine in the endpoint coordinates and independent of epsilon; rational
parameter coefficients require proved nonzero denominators. This includes
symbols that occur only in numerators. General nonlinear maps remain exact until
their omitted-tail analysis is implemented.

The source integral is explicitly tied to the physical endpoint row: the
AMFlow master convention, unit source/representative/frame factors, reference
scale and physical coordinate identity must agree. A different normalization or
unsupported identity retains that column exactly.

For prefactor lower bound p, uniform physical sector bounds b_s, nilpotency
indices nu_s and target order T, the finite upper order is
N = T - p - min_s(b_s - nu_s). The omitted term then begins above T after
endpoint integration. Moving divisors are excluded before applying this bound.

A coefficient with an unproved divisor is partitioned into literal regular and
exceptional summands. Both parts together must equal the original ordered
summands exactly. The exceptional part remains rational in epsilon. Only the
regular part receives a finite expansion, with source content, definitions,
normalization, accepted frame and endpoint inputs bound to its order plan.
A source with no regular terms or unsupported physical endpoint order bound
remains fully rational, with the reason retained in the discovery report.
Missing, inconsistent or stale declared dependencies fail before native
reconstruction. Unsupported analysis is handled per master, so it does not
prevent independent supported columns from using finite reconstruction.

A saved finite plan is checked against the current request, resolved physical
normalization, accepted endpoint catalog and source differential systems.
Changing the target, normalization, coordinates, bounds or domain requires
preparation again. Even a plan with no finite candidates replaces Plan.wl, so
a previous partition plan cannot survive as the current output. Preparation
refreshes mathematical demands; it need not repeat an accepted reconstruction
whose source expressions and sufficient order coverage remain unchanged.

`FiniteField/Partitions.wl` and `Execution.wl` enforce complete original output
coverage before publication. Preparation alone is available through
`Scripts/prepare_coefficient_reconstruction.wls TRACE_DIRECTORY CHANNEL_DIRECTORY CONTRIBUTION OUTPUT.wl`;
the lower-level form accepts `TRACE_DIRECTORY REQUEST.wl OUTPUT.wl`.
The generated plan contains no preset family names or source-column numbers.

The mixed term format preserves every finite unknown tail, including a zero
known prefix. Arithmetic validation inspects prefactors and coefficient
values; source topology and proof metadata are retained separately.

## Endpoint assembly

`BuildEndpointCoefficientCatalog` indexes actual integral definitions in
accepted closed DE systems. `ConstructEndpointCoefficientGroups` constructs
fresh complete coefficient rows in suitable common frames and verifies exact
cancellation of moving poles before expansion. It preserves finite regular
prefixes and divides only exact exceptional terms when a source contributes
to several groups. See [coefficient pole cancellation](CoefficientPoleCancellation.md).

The generated contribution set, rather than the number of saved alternative
frames, defines the endpoint campaign. Final assembly requires complete
whole-master and exact-piece ownership. Accepted endpoint, physical bounds,
matching and coordinate data are bound to each input.

## Validation

`Scripts/Validation/check_reconstructed_trace.py` checks every reconstructed
rational or Laurent output against its source trace. The manifest explicitly
assigns named variables at finite-field points. It uses the common strict
parser and comparison in `check_rational_trace.py`.

The pinned native evaluator requires the checked 63-bit prime range; small
moduli gave inconsistent evaluations in an earlier diagnostic. This is a
native-backend restriction. The production check uses two distinct primes
and three points each. It is probabilistic identity validation, not a global
symbolic proof.

Working expressions and traces remain under the owning project Results
directory until a complete validated replacement is available.
