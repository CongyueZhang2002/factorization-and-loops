(*
  Drop-in V6 replacement for V5 lines 458--670.  The surrounding driver must:

    1. pin and load GaloisChannelOrbitCoreV6.wl and
       DirectRootChannelExactOneFormRebindV6.wl before entering its dedicated
       artifact context;
    2. include "CodexCF300GaloisChannelOrbitV6`" and
       "CodexDirectRootChannelExactOneFormRebindV6`" on that context path;
    3. retain V5's already-completed hydration, ABI, physical-dimension and
       metadata gates through line 456;
    4. retain V5 from gaugeCount/residueCount/payload construction onward.

  This block deliberately prints a census milestone before DRCARebindAnsatz,
  separating the two formerly silent phases.
*)

{censusSeconds, orbitBuild} = AbsoluteTiming[
  CodexCF300GaloisChannelOrbitV6`GCOBuildOrbitBasis[
    basePreparation, baseAssembly,
    "EpsilonSamples" -> epsilonSamples,
    "Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 9]];
If[Lookup[orbitBuild, "Status", None] =!=
    "ExactGaloisChannelOrbitBasisV6",
  finish["GaloisChannelOrbitBasisBuildFailed", <|
    "CensusSeconds" -> censusSeconds,
    "OrbitBuildFailure" -> orbitBuild|>, 72]];

potentialSourceCount = orbitBuild["PotentialSourceCount"];
conjugateCandidateCount = orbitBuild["ConjugateCandidateCount"];
forcingLetterRecords = orbitBuild["ForcingLetterRecords"];
additionalLetterCount = orbitBuild["AdditionalLetterCount"];
additionalOneFormChannels = orbitBuild["AdditionalOneFormChannels"];
maxOneForms = orbitBuild["MaxOneForms"];
sourceOrbitRecords = orbitBuild["SourceOrbitRecords"];
orbitClosureExact = orbitBuild["OrbitClosureExact"];
orbitPerformanceCounters = orbitBuild["PerformanceCounters"];
characterCertificates = orbitBuild["CharacterCertificates"];

If[potentialSourceCount =!= 28 ||
    conjugateCandidateCount =!= 112 ||
    ! TrueQ[orbitClosureExact] ||
    ! And @@ Lookup[characterCertificates, {
      "InvolutionExact", "XorCompositionExact",
      "FieldMultiplicationEquivarianceExact",
      "GradeDiagonalDerivativeEquivarianceExact"}, False] ||
    Lookup[orbitPerformanceCounters,
      "LegacyAlgebraicFieldDecomposeCallsInCensus", -1] =!= 0 ||
    Lookup[orbitPerformanceCounters,
      "LegacyAlgebraicRootBranchSubstitutionsInCensus", -1] =!= 0,
  finish["GaloisChannelOrbitBasisPostconditionFailed", <|
    "CensusSeconds" -> censusSeconds,
    "PerformanceCounters" -> orbitPerformanceCounters,
    "CharacterCertificates" -> characterCertificates|>, 73]];

Print["CF300_GALOIS_ORBIT milestone=channel_orbit_ready census_s=",
  censusSeconds,
  " sources=", potentialSourceCount,
  " distinct_source_cores=",
    orbitPerformanceCounters["DistinctPotentialCoreCount"],
  " candidates=", conjugateCandidateCount,
  " forcing_letters=", Length[forcingLetterRecords],
  " appended=", additionalLetterCount,
  " unique_compositions=",
    orbitPerformanceCounters["UniqueOneFormCompositionCount"]];

(* Continue with V5's gaugeCount/residueCount/payload/maxPreparation
   construction through its validation at old line 698.  Replace old lines
   700--711 with the exact-channel rebind below. *)

{rebindSeconds, maxAssembly} = AbsoluteTiming[
  CodexDirectRootChannelExactOneFormRebindV6`
    DRCARebindExactOneFormChannels[
      baseAssembly, maxPreparation, additionalOneFormChannels]];
exactRebindDiagnostics = Lookup[maxAssembly,
  "ExactOneFormChannelRebindV6", <||>];
If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      maxAssembly] ||
    maxAssembly["SourceABIFingerprint"] =!=
      maxPreparation["ABIFingerprint"] ||
    Take[maxAssembly["OneForms"], Length[baseOneForms]] =!=
      baseOneForms ||
    Lookup[exactRebindDiagnostics, "Status", None] =!=
      "ExactOneFormChannelRebindV6" ||
    Lookup[exactRebindDiagnostics,
      "AppendedOneFormCount", -1] =!=
      additionalLetterCount ||
    Lookup[exactRebindDiagnostics,
      "AlgebraicFieldDecompositionCalls", -1] =!= 0 ||
    Lookup[exactRebindDiagnostics,
      "AlgebraicRootBranchSubstitutions", -1] =!= 0,
  finish["MaximalOrbitExactChannelRebindInvalid", <|
    "RebindStatus" -> Lookup[maxAssembly, "Status", None],
    "ExactRebindDiagnostics" -> exactRebindDiagnostics,
    "RebindSeconds" -> rebindSeconds|>, 79]];

(* Rename status/nonce labels from V5 to V6 and add
   orbitPerformanceCounters, characterCertificates and
   exactRebindDiagnostics to final output. *)
pointCount = Max[21, Ceiling[(unknownCount + 32)/32]];
If[unknownCount > 960 || pointCount > 31,
  finish["Rank2OrbitUnknownBoundViolated", <|
    "UnknownCount" -> unknownCount, "PointCount" -> pointCount|>, 79]];
Print["CF300_GALOIS_ORBIT milestone=target_ready census_s=",
  censusSeconds, " rebind_s=", rebindSeconds,
  " sources=", potentialSourceCount,
  " forcing_letters=", Length[forcingLetterRecords],
  " appended=", additionalLetterCount,
  " unknowns=", unknownCount, " points=", pointCount];
