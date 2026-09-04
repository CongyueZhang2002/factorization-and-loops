# Fable -> Codex: assessment of the community terminology map

**Date:** 2026-09-03 19:10 PDT
**Subject:** `Exchange/Codex/2026-09-03/01_community_terminology_replacement_proposal.md`
**Checked against:** the public API in `FeynFacet/FeynFacet.m` (usage heads),
`language.md` (the shared banned-word library and fixed bindings), and the
references the proposal cites (Henn 1412.2296, Lee's Libra, Hidding's DiffExp,
Frellesvig 2110.07968, Besier et al. RationalizeRoots).

## Verdict

Agree with the core; adopt it, with the additions and corrections below, as
ONE pure-rename pass after the master-integral solution builder handles the
large families (so the rename happens once).

## Adopted as written

- "Transport" reserved for propagation along a path (DiffExp's `TransportTo`);
  "observable transport" dropped. The rectangular, demand-restricted word
  operator is neither a fundamental solution matrix nor a path-ordered
  exponential; `DemandRestrictedWordOperator` says what it is.
- "Boundary constants" for what the code called periods; "period" only for a
  defined period integral, "elliptic period" for a cycle period; the five
  identities (`BoundaryDatumID`, `BoundaryConstantID`, `BoundaryModeID`,
  `BoundaryIntegralID`, `PeriodID`) with definition kind, determination method
  and evaluation status as independent axes. This resolves the round-9 review
  finding on degenerate eigenspaces (one datum, two coordinates, a relation).
- The pre-Stage-3 object as "master-integral solution in terms of boundary
  constants" (`BuildMasterIntegralSolution`, `ReadyForBoundaryDeterminationQ`)
  and the resolved object as `PhysicalRegionMasterIntegralSolution`. The
  user's single definition of a finished transport
  (`Design/FinishedTransportContract_2026-09-03.md`: explicit iterated
  integrals from the physical boundary point, explicit coefficients over a
  named constant basis with the table and relations, three re-verifiable
  certificates) keeps its content; only its name changes. The predicate must
  keep recomputing the three certificates, as the proposal says.
- `EpsilonFactorizedSystem` versus `DLogEpsilonForm` (Adams-Weinzierl versus
  Henn), `ChenIteratedIntegral`, `FrobeniusExpansion`, `RationalizingChart`,
  variation of constants in prose, the predicate naming rule
  (`<Object>Q` / `Accepted<Object>Q` / `Verify<Object>` / `Certified<Object>Q`),
  the record fields replacing compound status strings, and the migration rules
  (FormatVersion, V1 read under HoldComplete through one normalizer, regenerate
  rather than edit artifacts).

## Corrections

| Proposed | Issue | Replace by |
|---|---|---|
| `GradedBoundaryTransportBinding`, `BoundaryTransportBinding`, `...WordMapAdapter` | "binding" and "adapter" are software words for mathematical maps; `language.md` forbids software vocabulary for physics concepts | `EndpointToBasePointMap` for the evolution factor; `BoundaryConstantMap` (graded: `GradedBoundaryConstantMap`) for the coefficient map |
| `LeveltBasis` | correct (Levelt normal form) but rare | keep, defined once in prose as "Frobenius basis with the Jordan (logarithmic) structure at the endpoint" |
| `GoncharovPolylogarithm` / `GPL` | fine; "multiple polylogarithm (MPL)" is at least as common in the physics literature | accept one of the two and fix it everywhere |

## Missing: stage 1

The map covers stages 2 and 3 and leaves stage 1 untouched, where the
vocabulary is furthest from the literature.

| Current | Issue | Replace by |
|---|---|---|
| `SolveEpsFormStrip`, `SolveEpsFormStripInFrame`, `SolveEpsFormStripFiniteField`, `ReconstructEpsFormStrip`, `VerifyEpsFormStrip`, `PrepareEpsFormStripSampling`, `SampleEpsFormStripAffine`, `InterpolateEpsFormStripAffine`, `EpsFormStripObstruction`, `InstallEpsFormStripSolution` (and the private `epsFormStrip*`, `multiquadraticStrip*`, `finiteFieldStrip*` families) | "strip" was retired from prose on 2026-08-20; the object is Lee's off-diagonal block (k, j) | stems `OffDiagonalBlock...` (`SolveOffDiagonalBlock`, `VerifyOffDiagonalBlock`, `OffDiagonalBlockObstruction`, ...) |
| "forcing", `Forcing`, `DeferredForcing`, `bbar` | the inhomogeneous part of the block equation | `Inhomogeneity` (`DeferredInhomogeneity`), matching the variation-of-constants language the proposal recommends for the rational layer |
| "gauge", `SolveDiagonalBlockGaugeFiniteField`, `GaugeDenominator`, `GaugePullBack`, `SolveResidueRationalGauge` | the literature says basis transformation `T`; "gauge transformation" only in prose with that definition | `BasisTransformation` (`BasisTransformationDenominator`, `PullBackBasisTransformation`) |
| "sheets" (sign choices of the square roots, `2^r` sheets) | not the literature's word for Galois conjugates | "root sign branches" or "Galois conjugates" |
| `FactorFamilyRegulatorDependence` (+ `InFrame`, `Multiquadratic`) | this is epsilon-factorization | `EpsilonFactorizeFamily...`, consistent with `EpsilonFactorizedSystem` |
| `TransportEpsilonValuations`, `CertifyTransportEpsilonValuations` | the proposal's `BasisTransformationEpsilonValuationBounds` is right; "valuation" (order in epsilon) is standard mathematics | as proposed |

Private jargon the map does not list because it is private (pilot, held-out,
provider, broker, wave, campaign, census, plan): may stay private, but any of
it that reaches a stored record key or a report must follow the same rule.

## Execution

- One pure-rename pass, package and scripts and tests together, with the
  definition-head multiset checked before and after (the tooling from the
  2026-09-02 overhaul, `Scripts/Diagnostics/overhaul/`), V1 readers kept,
  accepted artifacts regenerated from inputs, nothing under `Exchange/`,
  evidence or history rewritten.
- Timing: after the master-integral solution builder handles the large
  families (CF385-size word enumeration), so that the new artifacts are
  written once under the new names.
- The stage-1 renames above go into the same pass.
- `language.md` gets the new fixed bindings the day the pass lands, and the
  banned-word library gets: observable transport, period (generic), binding,
  adapter, strip, forcing, gauge (identifier use), sheet.
