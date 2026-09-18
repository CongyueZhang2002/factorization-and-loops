# Shared master integrals

`Library/MasterIntegrals` stores explicit physical master-integral values shared
by all projects. Process, family and provider names are not integral identities.
The organization uses **integral families, sectors and propagator powers**,
as in [Kira](https://arxiv.org/abs/1705.05610).

## Organization and indexed lookup

```text
Library/MasterIntegrals/
  Families/
    L2-E2-C3-M1-N7/
      Catalog.wl
      F000001/
        Family.wl
        Sectors/
          S127/
            Index.wl
            M000001.wl
            Relations.wl       # only when a verified IBP relation exists
```

Every generated `.wl` has a `.wl.meta.wxf` companion. Text has no context
prefixes; `FamilyArtifactRead` restores exact symbol identities. Keep the pair.
No content hashes are used.

The first directory groups families by loop count, external-momentum count,
particle-cut count, measurement-cut count and active denominator count.
Catalogs map exact canonical definitions to local family identifiers.
`Family.wl` supplies denominator ordering and physical conventions.
The sector number is `sum_i 2^(i-1)` over **positive** propagator powers;
negative powers are numerators. A sector index maps complete power vectors to
value files and epsilon coverage.

These sectors belong to the library's canonical active family/subtopology.
Numbers can differ from source Kira sectors: unused completion denominators
are removed and active denominators reordered. Mandatory cuts remain even
when pinched; numerators remain active. Different powers share one family
definition. Unused source propagators cannot obstruct matching.

Lookup selects a structural directory and uses exact Association keys for
family and powers. It does not compare against every stored master. Batch
lookup reads each needed catalog, sector and value once. The selected catalog
still grows with families in that structural group; solved expressions are
not loaded to search. The frame cache is bounded; no persistent stale read
cache is kept.

Values contain either an exact function of epsilon or contiguous explicit
Laurent coefficients with lower and upper bounds. Physical constants must
already be applied. Free-boundary connections, unresolved integrals, lazy
generators and approximate numerical values are excluded. IBP relations
reference direct value records instead of duplicating expressions.

## Exact equivalences and limits

The affine matcher handles dummy momentum/regulator renaming, denominator
permutations, loop permutations/sign changes, external shifts of loops and
unit-absolute-Jacobian loop mixing represented by its enumerated momentum
frames. It applies to **virtual and cut** integrals. Powers are minimized
under automorphisms after identifying the unpowered family.

Reuse records include the exact momentum transformation and propagator
permutation. Identity retains dimensions, masses, numerators, particle-cut
orientations, measurement cuts, delta-derivative powers, causal prescriptions,
measure, master prefactor, time direction, physical assumptions and scope.

External momenta are named positionally. External crossing, invariant-variable
changes and analytic continuation are not inferred. Only exact unit-Jacobian
affine transformations are adopted. A family without a spanning admissible
frame falls back to direct comparison; mixed cut/virtual families may lack
enough particle cuts. Additional acceptance boundaries restrict mappings.
An interior expansion never establishes endpoint contact terms. Domain
comparison is conservative: unsupported equivalences remain misses.

This is exact scalar-product/affine-frame canonicalization, **not Pak's
parametric algorithm**. The latter can identify broader equivalences, and
not every parametric match provides a momentum shift; see
[FeynCalc's documentation](https://feyncalc.github.io/FeynCalcBookDev/FCLoopFindTopologyMappings.html).
A miss is not a proof of inequivalence.

## Bounded exact IBP reduction

If direct lookup misses but the active family exists, the library can locate
stored values in that family and its admissible subsectors, generate genuine
typed IBP equations and perform exact row reduction. Out-of-window integrals
remain unknown columns. A target is accepted only when its resulting row
contains stored masters alone.

Defaults: 0.5 seconds, 32 subsector patterns, 128 seeds. Options are
`UseIBPRelations`, `IBPTimeLimit`, `MaximumIBPSubsectors` and
`MaximumIBPSeeds`. Larger reductions belong to Kira. An unsuccessful bounded
search is inconclusive.

`Relations.wl` retains exact coefficients, target equation, seed powers,
derivation definition and equation count. Later lookup does not redo IBP.
References point only to direct values, preventing alias cycles. Pure relations
among stored values exposed by the same reduction must also be satisfied;
inconsistent or unproved constraints block adoption. A successful relation
does not prove minimality or independence of the stored basis.

Coefficient valuations determine required source epsilon orders. The common
omitted-order audit checks the contraction. Outcomes distinguish a covered
relation, a proved relation with insufficient coverage and an inconclusive
search.

## Complete and partial DE reuse

`FindMasterIntegralValues` returns `Values` (fully covered rows),
`PartialValues` (available coefficients of insufficient rows),
`UnidentifiedRows`, `InsufficientOrderRows` and `LookupStatistics`.

A complete hit covers every requested coefficient and skips integration.
A partial hit supplies actual coefficients to the physical DE solver.
Missing coefficients are never zeros.

The same prepared system and physical Frobenius subtraction are retained:

```text
J' = N J,    I = O J = P Y,    Y' = B Y,    G = P^(-1) O.
J0 = the sufficiently deep physical Frobenius subtraction.
E = Y - G J0,        E' = B E + G (N J0 - J0').
```

Known coefficients of `P^(-1) I - G J0` are reused directly. Other coefficients
follow increasing epsilon order and the strictly lower-triangular order of
`B(epsilon=0)`. Only requested dependencies are memoized. The exact residual
is not truncated in x. The complete coefficient integrand is assembled before
its endpoint integration, preserving cancellations and constants.

Inverse-gauge poles, Frobenius columns, amplitudes and reconstruction enter
order planning. Missing boundary coefficients fail explicitly. The existing
sufficient subtraction construction supplies a coefficientwise vanishing
remainder; reuse introduces no new boundary constants. Known original
coefficients are retained and overlapping published values must agree.

`ConstructPhysicalBoundarySolution` requires the epsilon-regular prepared
frame, triangular unregulated connection and supported explicit GPL primitives.
It conservatively reuses components determined by the inverse gauge; it does
not promise optimal elimination of every known combination in a dense gauge.

[GPT-6 Pro review 13](../External/ChatGPT/Records/2026-09-16/13_structured_master_library.md)
reviewed this argument. Tests include inverse-gauge poles, coalescing Frobenius
sectors, missing boundary orders and cancellation between divergent terms.

## Automatic publication and timing

Automatic hooks cover `EvaluateOneLoopIntegral`,
`EvaluateOneLoopScalarFunctions` (B0/C0), `EvaluateMasslessBoxIntegral`,
`EvaluateMasslessVertexMaster`, independent two-body angular seeds, integration-free
`ConstructMasterIntegralRepresentations` and the physical measured-DE driver.
B0/C0 are stored before the FeynCalc `pi^(-epsilon)` conversion. Conjugated
bubble products retain their explicit loop-measure sign. Definitions-only
construction does not publish. Other providers use the common public hook.

Amplitude generation, reduction and order planning still precede lookup.
Endpoint data for distributions remain separate; master reuse alone does
not finish a hard function.

Set `FEYNFACET_MASTER_LIBRARY_MODE` before kernel startup or
``FeynFacet`$MasterIntegralLibraryMode`` in the session:

| Mode | Lookup | Publication |
|---|---|---|
| ReadWrite | Yes | Yes |
| ReadOnly | Yes, including bounded IBP derivation | No |
| Recompute | No | Yes, checking overlaps |
| Disabled | No | No |

`FEYNFACET_MASTER_LIBRARY_DIRECTORY` selects another library. Public request
associations accept `LibraryDirectory` and `Mode`. Fresh-project timing
defaults to Recompute. ReadWrite fresh project artifacts are labelled as using
shared masters, not as cold master calculations. Resume requires the same
mode. Reports distinguish startup, lookup, integration and import time.
Historical campaign timings are unchanged.

## API

```wl
definitions = FeynFacet`ConstructMasterIntegralDefinitions[input];
d = definitions["MasterIntegralDefinitions"][1];
FeynFacet`CanonicalMasterIntegral[d]
FeynFacet`FindMasterIntegralValue[d, {-2, 2}]
FeynFacet`FindMasterIntegralValue[d, Automatic]  (* exact function only *)
FeynFacet`FindMasterIntegralValues[
  definitions["MasterIntegralDefinitions"], <|1 -> {-2, 2}, 2 -> {-1, 3}|>]
FeynFacet`ReduceMasterIntegralToLibrary[d, {-2, 2}, <|"IBPTimeLimit" -> 2|>]
FeynFacet`MasterIntegralLibraryInventory[]
FeynFacet`StoreMasterIntegralValue[d,
  <|"Coefficients" -> <|-1 -> cMinus1, 0 -> c0, 1 -> c1|>,
    "LaurentLowerBound" -> -1, "KnownThroughOrder" -> 1|>]
FeynFacet`EvaluateWithMasterIntegralLibrary[d, {-2, 2}, Function[{}, provider[]]]
```

A finite record asserts zeros below its lower bound. Gaps and missing higher
coefficients are never zeros. Overlaps require exact agreement; rational
simplification is allowed, but an unproved special-function identity does
not authorize overwriting.

`StoreMasterIntegralSolution[definitions, solution, request]` accepts original
masters with physical constants applied and coefficients keyed by
`{row, epsilonOrder}`. `CoordinateRules` express solution coordinates in the
definition frame. Import command:

```text
wolframscript -file Scripts/import_master_integrals.wls \
  DEFINITIONS.wl PHYSICAL_SOLUTION.wl IMPORT_REPORT.wl [LIBRARY_DIRECTORY]
```

The wrapper supplies `MasterIntegralDefinitions` and optional
`SolutionToIntegralCoordinates`. Import timing is not calculation timing.

## Persistence, ownership and tests

Writers serialize under a directory lock and use paired atomic writes.
Values precede sector entries; new-family catalogs come last. Unindexed
interrupted files are never reused and their identifiers are skipped.
Corrupt matched records fail. Remove a leftover WriteLock only after verifying
no writer owns it. The old flat layout is not read; it was rebuilt from
accepted physical definitions and values.

- `Integrals/MasterLibrary.wl`: API, coverage, modes and merge checks.
- `Integrals/Library/Canonicalization.wl`: momentum identities.
- `Integrals/Library/Storage.wl`: indexes and publication.
- `Integrals/Library/Relations.wl`: bounded exact IBP.
- `Integrals/Library/Providers.wl`: scalar normalization adapters.
- `Boundary/PhysicalEvolution.wl`: partial physical evolution.

`Tests/Integrals/t_master_library*.wls` test identities, coverage, publication,
conflicts, virtual/cut shifts, indexed reads and IBP poles.
`Tests/Transport/t_partial_master_library_evolution.wls` tests the recurrence.
TestKit disables the production library; tests opt into temporary directories.
Dated reports record production-fixture checks without claiming a new NNLO
endpoint result.

## Two-body angular seeds

`PublishTwoBodyAngularSeeds` publishes the exact normalized physical volume,
massive one-denominator and two-denominator seed integrals. It does not store
every raised-power or numerator target as an independent master. Definitions
retain the original typed cuts, prescribed propagators, exact measure and
generic-kinematic domain. Explicit Gamma/Gauss/Appell functions are physical
values, not lazy integration instructions. Endpoint distributions are separate.

The generic angular combination provider invokes this hook automatically.
For retained results, run `Scripts/publish_angular_masters.wls` with an angular
density file and an owned report path. Publication/import time is recorded
separately and is not retroactively called integration time.
