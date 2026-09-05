#!/usr/bin/env wolframscript
(* Structural-pilot policy: the first usable image selects the affine section.
   Later images are constrained to that section, so a deliberately exceptional
   first prime produces a typed reconstruction refusal rather than triggering
   extra full RREFs to vote on pivot structures. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, compile, layoutBuilder, compiledProvider, assembleSample,
  discoverySolve, pilotRecord, reconstruct} = mq /@ {
  "multiquadraticOffDiagonalBlockPrepare", "multiquadraticOffDiagonalBlockCompile",
  "multiquadraticOffDiagonalBlockAssemblyLayout",
  "multiquadraticOffDiagonalBlockCompiledProvider",
  "multiquadraticOffDiagonalBlockAssembleSample",
  "multiquadraticOffDiagonalBlockPlanDiscoverySolve",
  "multiquadraticOffDiagonalBlockPilotImageRecord",
  "multiquadraticOffDiagonalBlockReconstructRegulator"};

Clear[px, py, pe, pcx, pcy];
frame = BuildSquareRootGeneratorsAndQuadraticRelations[
  {}, {px, py}, {pcx, pcy}];
primes = Take[FeynFacet`Private`$multiquadraticOffDiagonalBlockPrimePool, 3];
{primeOne, primeTwo, primeThree} = primes;

buildFixture[diagonal_List] := Module[
  {width = Length[diagonal], upperZero, lowerZero, inhomogeneityZero, record,
   prepared, assembly, layout, provider},
  upperZero = ConstantArray[0, {1, 1}];
  lowerZero = ConstantArray[0, {width, width}];
  inhomogeneityZero = ConstantArray[0, {1, width}];
  record = <|"Family" -> "MODAL_STRUCTURAL_PILOT_TEST", "Sector" -> 2,
    "LowerSector" -> 1, "Variables" -> {px, py}, "Regulator" -> pe,
    "OffDiagonalBlockEquation" -> {{upperZero, upperZero},
      {DiagonalMatrix[diagonal], lowerZero},
      {inhomogeneityZero, inhomogeneityZero}}|>;
  prepared = prepare[record, frame, "OneForms" -> {},
    "OffDiagonalBasisTransformationDenominator" -> 1, "Support" -> {{0, 0}}];
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
    prime, fixture["Preparation"]["OffDiagonalBasisTransformationUnknownCount"],
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

(* At primeOne every basis-transformation column vanishes; at the other primes
   all columns pivot.  The first supplied pilot therefore selects an exceptional
   section and the later primes cannot enter that section. *)
exceptionalFixture = buildFixture[{primeOne}];
exceptionalPilots = makePilot[exceptionalFixture, #1] & /@ primes;
check["the adversarial pilots have one isolated pivot structure then two agreeing",
  exceptionalPilots[[1, "Solution", "Rank"]] === 0 &&
    exceptionalPilots[[2, "Solution", "Rank"]] === 1 &&
    exceptionalPilots[[3, "Solution", "Rank"]] === 1 &&
    exceptionalPilots[[2, "Solution", "PivotColumns"]] ===
      exceptionalPilots[[3, "Solution", "PivotColumns"]]];

exceptionalResult = reconstructWithPilots[exceptionalFixture,
  exceptionalPilots];
check["the first usable pilot selects the section without a pivot vote",
  exceptionalResult["Status"] === "ReconstructionPrimePoolExhausted" &&
    exceptionalResult["GoodPrimes"] === {primeOne}];
check["later primes with a different section are rejected typed",
  ContainsAll[exceptionalResult["RejectedPrimes"], {primeTwo, primeThree}] &&
    AllTrue[{primeTwo, primeThree},
      Lookup[exceptionalResult["PrimeRejections"], #1, None] ===
        "ExceptionalRegulatorImagesExhausted" &]];
check["the supplied pilot records retain the requested native backend policy",
  AllTrue[Lookup[exceptionalPilots, "Solution"],
    Lookup[#1, "PlanDiscoveryBackendRequested", None] === Automatic &&
      Lookup[#1, "PlanDiscoveryBackendThreads", None] === 2 &]];

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

Print["t_multiquadratic_modal_structure_pilots: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
