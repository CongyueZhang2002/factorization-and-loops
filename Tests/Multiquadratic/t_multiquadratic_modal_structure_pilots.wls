#!/usr/bin/env wolframscript
(* Round-B structural-pilot quorum: an exceptional first-prime signature is
   isolated when the next two primes agree, cached support pilots are never
   sampled or RREFed again, and three distinct signatures fail typed before
   any affine section is locked. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, layoutBuilder, compiledProvider, assembleSample,
  discoverySolve, pilotRecord, reconstruct} = mq /@ {
  "multiquadraticStripPrepare", "multiquadraticStripCompile",
  "multiquadraticStripAssemblyLayout",
  "multiquadraticStripCompiledProvider",
  "multiquadraticStripAssembleSample",
  "multiquadraticStripPlanDiscoverySolve",
  "multiquadraticStripPilotImageRecord",
  "multiquadraticStripReconstructRegulator"};

Clear[px, py, pe];
frame = <|"Name" -> "ModalStructuralPilot", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> {px, py},
  "Subst" -> {px -> px, py -> py}, "Root" -> None,
  "RootSquare" -> None, "Roots" -> {}|>;
primes = Take[FeynFacet`Private`$multiquadraticStripPrimePool, 3];
{primeOne, primeTwo, primeThree} = primes;

buildFixture[diagonal_List] := Module[
  {width = Length[diagonal], upperZero, lowerZero, forcingZero, record,
   prepared, assembly, layout, provider},
  upperZero = ConstantArray[0, {1, 1}];
  lowerZero = ConstantArray[0, {width, width}];
  forcingZero = ConstantArray[0, {1, width}];
  record = <|"Family" -> "MODAL_STRUCTURAL_PILOT_TEST", "Sector" -> 2,
    "LowerSector" -> 1, "Variables" -> {px, py}, "Regulator" -> pe,
    "Strip" -> {{upperZero, upperZero},
      {DiagonalMatrix[diagonal], lowerZero},
      {forcingZero, forcingZero}}|>;
  prepared = prepare[record, frame, "OneForms" -> {},
    "GaugeDenominator" -> 1, "Support" -> {{0, 0}}];
  assembly = compile[prepared];
  layout = layoutBuilder[prepared];
  provider = compiledProvider[assembly];
  <|"Preparation" -> prepared, "Layout" -> layout,
    "Provider" -> provider|>
];

makePilot[fixture_Association, prime_Integer] := Module[{sample, solution},
  sample = assembleSample[fixture["Layout"], fixture["Provider"], 1,
    prime, "PointCount" -> 2, "MaximumAttempts" -> 40,
    "RandomSeed" -> 2026082700 + Mod[prime, 997]];
  solution = discoverySolve[sample["Matrix"], sample["RightHandSide"],
    prime, fixture["Preparation"]["GaugeUnknownCount"],
    fixture["Preparation"]["ResidueUnknownCount"], Automatic, 2,
    Automatic];
  pilotRecord[prime, 1, sample, solution]
];

reconstructWithPilots[fixture_Association, pilots_List, pointCount_: 2] := reconstruct[
  fixture["Preparation"], fixture["Layout"], fixture["Provider"],
  "SamplePrimes" -> Take[primes, 2], "PrimePool" -> primes,
  "MinimumGoodPrimeCount" -> 2, "MaximumGoodPrimeCount" -> 2,
  "MaximumRejectedPrimeCount" -> 3,
  "RegulatorValues" -> {1, 2, 3, 5}, "InitialRegulatorCount" -> 3,
  "MaximumRegulatorCount" -> 4, "InitialConstructionCount" -> 2,
  "HeldOutCount" -> 1, "MaximumTotalDegree" -> 2,
  "UnseenPrimeCount" -> 1, "FreshPointwiseChecksPerPrime" -> 1,
  "PointCount" -> pointCount, "MaximumAttempts" -> Max[40, pointCount],
  "PlanDiscoveryBackend" -> Automatic,
  "PlanDiscoveryBackendThreads" -> 2,
  "PlanDiscoveryBackendMinimumEntries" -> Automatic,
  "PilotImages" -> pilots, "ExactVerification" -> "ProviderPoints"];

(* At primeOne every gauge column vanishes; at the other primes all columns
   pivot.  The first signature is therefore exceptional and the next two are
   the generic two-vote structure. *)
exceptionalFixture = buildFixture[{primeOne}];
exceptionalPilots = makePilot[exceptionalFixture, #1] & /@ primes;
check["the adversarial pilots have one isolated signature then two agreeing",
  exceptionalPilots[[1, "Solution", "Rank"]] === 0 &&
    exceptionalPilots[[2, "Solution", "Rank"]] === 1 &&
    exceptionalPilots[[3, "Solution", "Rank"]] === 1 &&
    exceptionalPilots[[2, "Solution", "PivotSignature"]] ===
      exceptionalPilots[[3, "Solution", "PivotSignature"]]];

exceptionalResult = reconstructWithPilots[exceptionalFixture,
  exceptionalPilots];
check["the next two primes win and their first prime becomes the reference",
  exceptionalResult["Status"] === "ReconstructedRegulatorDependenceV1" &&
    exceptionalResult["ModalReferencePrime"] === primeTwo &&
    exceptionalResult["ModalStructuralSignature"] ===
      {exceptionalPilots[[2, "Solution", "Rank"]],
       exceptionalPilots[[2, "Solution", "Nullity"]],
       exceptionalPilots[[2, "Solution", "PivotSignature"]]}];
check["the isolated first prime remains rejected and exceptional evidence",
  MemberQ[exceptionalResult["RejectedPrimes"], primeOne] &&
    Lookup[Lookup[exceptionalResult["PrimeRejections"], primeOne, <||>],
      "Status", None] === "NonmodalModularStructure" &&
    AnyTrue[exceptionalResult["ExceptionalRegulatorImages"],
      Lookup[#1, "Prime", None] === primeOne &&
        Lookup[#1, "Reason", None] === "NonmodalModularStructure" &]];
check["all three cached pilots incur no repeated sampling or RREF",
  exceptionalResult["StructuralPilotPrimeCount"] === 3 &&
    exceptionalResult["StructuralPilotRREFCount"] === 3 &&
    exceptionalResult["StructuralPilotCacheHitCount"] === 3 &&
    exceptionalResult["StructuralPilotNewSampleCount"] === 0 &&
    exceptionalResult["StructuralPilotNewFullAffineSolveCount"] === 0 &&
    exceptionalResult["ReusedPilotImageCount"] === 3 &&
    exceptionalResult["FullAffineSolveCount"] === 3 &&
    exceptionalResult["FullAffineFallbackCount"] === 0];
check["native selection remains Automatic with the requested thread policy",
  exceptionalResult["PlanDiscoveryBackendRequested"] === Automatic &&
    exceptionalResult["PlanDiscoveryBackendThreads"] === 2];

(* Cache admission checks all three image keys and replays both the particular
   and nullspace residuals. *)
keyMutant = ReplacePart[exceptionalPilots[[2]],
  {"Solution", "RegulatorValue"} -> 2];
keyMutantResult = reconstructWithPilots[exceptionalFixture, {keyMutant}];
check["a solution epsilon-key mismatch is refused",
  keyMutantResult["Status"] === "PilotImageAuthenticationFailed" &&
    keyMutantResult["Reason"] === "PilotSolutionKeyMismatch"];

residualMutant = ReplacePart[exceptionalPilots[[2]],
  {"Sample", "RightHandSide", 1} -> Mod[
    exceptionalPilots[[2]]["Sample"]["RightHandSide"][[1]] + 1,
    primeTwo]];
residualMutantResult = reconstructWithPilots[exceptionalFixture,
  {residualMutant}];
If[Lookup[residualMutantResult, "Reason", None] =!=
    "PilotParticularResidualNonzero",
  Print["RESIDUAL MUTANT DIAGNOSTIC: ", Short[residualMutantResult, 8]]];
check["a sample whose particular residual moved is refused",
  residualMutantResult["Status"] === "PilotImageAuthenticationFailed" &&
    residualMutantResult["Reason"] ===
      "PilotParticularResidualNonzero"];

nullspaceMutant = ReplacePart[exceptionalPilots[[1]],
  {"Solution", "NullspaceBasis", 1} -> ConstantArray[0, Length[
    exceptionalPilots[[1]]["Solution"]["ParticularSolution"]]]];
nullspaceMutantResult = reconstructWithPilots[exceptionalFixture,
  {nullspaceMutant}];
If[Lookup[nullspaceMutantResult, "Reason", None] =!= "PilotNullspaceInvalid",
  Print["NULLSPACE MUTANT DIAGNOSTIC: ", Short[nullspaceMutantResult, 8]]];
check["a dependent nullspace basis is refused",
  nullspaceMutantResult["Status"] === "PilotImageAuthenticationFailed" &&
    nullspaceMutantResult["Reason"] === "PilotNullspaceInvalid"];

(* A sampler admission refusal contains no structural evidence.  It propagates
   as the resource failure that actually occurred, before any RREF is run. *)
resourceResult = reconstructWithPilots[exceptionalFixture, {}, 1000000000];
If[! (resourceResult["Status"] === "SampleMatrixResourceLimit" &&
    resourceResult["Stage"] === "StructuralPilotSampling" &&
    KeyExistsQ[resourceResult, "SizeEstimate"] &&
    KeyExistsQ[resourceResult, "MaximumMatrixBytes"]),
  Print["RESOURCE DIAGNOSTIC: ", Short[resourceResult, 8]]];
check["a matrix admission refusal is not called modular instability",
  resourceResult["Status"] === "SampleMatrixResourceLimit" &&
    resourceResult["Stage"] === "StructuralPilotSampling" &&
    KeyExistsQ[resourceResult, "SizeEstimate"] &&
    KeyExistsQ[resourceResult, "MaximumMatrixBytes"]];

(* Each prime now kills a different column, so rank and nullity agree but the
   pivot signature is different at all three primes. *)
unstableFixture = buildFixture[primes];
unstablePilots = makePilot[unstableFixture, #1] & /@ primes;
check["the failure fixture exposes three distinct pivot signatures",
  Length[DeleteDuplicates[Lookup[Lookup[unstablePilots, "Solution"],
      "PivotSignature"]]] === 3];
unstableResult = reconstructWithPilots[unstableFixture, unstablePilots];
check["three nonrepeating signatures fail typed before normalization locks",
  unstableResult["Status"] === "ModularStructureUnstable" &&
    unstableResult["DistinctPrimeCount"] === 3 &&
    unstableResult["RequiredAgreementCount"] === 2 &&
    Length[unstableResult["StructuralPilotEvidence"]] === 3 &&
    ! KeyExistsQ[unstableResult, "NormalizationColumns"]];
check["the no-repeat failure also pays for no repeated sample or RREF",
  unstableResult["StructuralPilotRREFCount"] === 3 &&
    unstableResult["StructuralPilotCacheHitCount"] === 3 &&
    unstableResult["StructuralPilotNewSampleCount"] === 0 &&
    unstableResult["StructuralPilotNewFullAffineSolveCount"] === 0 &&
    unstableResult["ReusedPilotImageCount"] === 3 &&
    unstableResult["FullAffineSolveCount"] === 3];

Print["t_multiquadratic_modal_structure_pilots: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
