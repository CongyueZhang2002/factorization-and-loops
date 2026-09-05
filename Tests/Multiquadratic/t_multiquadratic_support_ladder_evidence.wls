#!/usr/bin/env wolframscript
(* The provider support ladder replaces unusable images within its declared
   attempt schedule, but mixed usable evidence is never promoted to a gauge
   obstruction.  The fixture is rank zero and one unknown; only the evidence
   protocol is inherited-blocked. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{prepare, compile, layoutBuilder, compiledProvider, ladderSolve,
  affineSolve, authenticatePilot} =
 mq /@ {"multiquadraticOffDiagonalBlockPrepare", "multiquadraticOffDiagonalBlockCompile",
   "multiquadraticOffDiagonalBlockAssemblyLayout",
   "multiquadraticOffDiagonalBlockCompiledProvider",
   "multiquadraticOffDiagonalBlockProviderSupportLadder",
   "multiquadraticOffDiagonalBlockAffineSolve",
   "multiquadraticOffDiagonalBlockPilotImageAuthenticate"};

Clear[slx, sly, sle];
variables = {slx, sly};
frame = <|"Name" -> "SupportEvidenceRankZero", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> variables,
  "Subst" -> {slx -> slx, sly -> sly}, "Root" -> None,
  "RootSquare" -> None, "Roots" -> {}|>;
zero = {{{0}}, {{0}}};
record = <|"Family" -> "SUPPORT_EVIDENCE_TEST", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> variables, "Regulator" -> sle,
  "OffDiagonalBlockEquation" -> {zero, zero, zero}|>;
preparation = prepare[record, frame, "OneForms" -> {},
  "OffDiagonalBasisTransformationDenominator" -> 1, "Support" -> {{0, 0}}];
assembly = compile[preparation];
layout = layoutBuilder[preparation];
provider = compiledProvider[assembly];
primes = Take[FeynFacet`Private`$multiquadraticOffDiagonalBlockPrimePool, 4];
images = MapThread[List, {primes, Range[Length[primes]]}];

fakeSample[prime_, value_] := Module[{point = {2, 3}, normalizationCount,
    rowCount, matrix},
  normalizationCount = Length[layout["Normalizations"]];
  rowCount = layout["EquationsPerPoint"] + normalizationCount;
  matrix = ConstantArray[0, {rowCount, layout["UnknownCount"]}];
  <|
  "Status" -> "AssembledMultiquadraticSampleV1",
  "CoefficientData" -> layout["CoefficientData"],
  "Provider" -> provider["Kind"],
  "Prime" -> prime, "EpsilonValue" -> value,
  "EpsilonMod" -> Mod[value, prime],
  "TrainingImageKeys" -> {{prime, value, point}},
  "Matrix" -> matrix, "RightHandSide" -> ConstantArray[0, rowCount],
  "MatrixDimensions" -> Dimensions[matrix], "AcceptedPoints" -> {point},
  "NormalizationCount" -> normalizationCount,
  "ColumnOrder" -> layout["ColumnOrder"],
  "RowOrder" -> layout["RowOrder"],
  "PhaseSeconds" -> <||>|>];

runScenario[scenario_Association] := Internal`InheritedBlock[
  {FeynFacet`Private`multiquadraticOffDiagonalBlockAssembleSample,
   FeynFacet`Private`multiquadraticOffDiagonalBlockAffineConsistencyEvidence},
  Unprotect[FeynFacet`Private`multiquadraticOffDiagonalBlockAssembleSample,
    FeynFacet`Private`multiquadraticOffDiagonalBlockAffineConsistencyEvidence];
  Clear[FeynFacet`Private`multiquadraticOffDiagonalBlockAssembleSample,
    FeynFacet`Private`multiquadraticOffDiagonalBlockAffineConsistencyEvidence];
  FeynFacet`Private`multiquadraticOffDiagonalBlockAssembleSample[
      _Association, _Association, value_, prime_Integer, ___] :=
    If[Lookup[scenario, prime, "Unavailable"] === "Unavailable",
      <|"Status" -> "SyntheticImageUnavailable", "Prime" -> prime,
        "RegulatorValue" -> value|>, fakeSample[prime, value]];
  FeynFacet`Private`multiquadraticOffDiagonalBlockAffineConsistencyEvidence[
      matrix_, right_, prime_Integer, ___] := Module[{status, solution},
    status = Lookup[scenario, prime, "Unavailable"];
    If[status === "Consistent",
      solution = affineSolve[matrix, right, prime];
      <|"Status" -> "ProviderSupportImageConsistent", "Prime" -> prime,
        "Rank" -> solution["Rank"], "AugmentedRank" -> solution["Rank"],
        "Defect" -> 0, "MatrixDimensions" -> Dimensions[matrix],
        "Solution" -> solution|>,
      <|"Status" -> "ProviderSupportImageInconsistent", "Prime" -> prime,
        "Rank" -> 0, "AugmentedRank" -> 1, "Defect" -> 1,
        "MatrixDimensions" -> Dimensions[matrix]|>]];
  Protect[FeynFacet`Private`multiquadraticOffDiagonalBlockAssembleSample,
    FeynFacet`Private`multiquadraticOffDiagonalBlockAffineConsistencyEvidence];
  ladderSolve[preparation, layout, provider, Function[ignored, <||>],
    "DegreeOffsetLadder" -> {}, "Images" -> images,
    "MaximumImageAttempts" -> 4, "PointCount" -> 1,
    "MaximumAttempts" -> 1, "PlanDiscoveryBackend" -> "Wolfram"]];

replacementConsistent = runScenario[<|primes[[1]] -> "Unavailable",
  primes[[2]] -> "Consistent", primes[[3]] -> "Consistent"|>];
replacementRung = First[replacementConsistent["LadderRungs"]];
FTAssert["SL0 an unusable first image is replaced within the bounded schedule",
  replacementConsistent["Status"] ===
      "DeferredProviderSupportLadderAdopted" &&
    replacementRung["AttemptCount"] === 3 &&
    replacementRung["ImageCount"] === 2 &&
    Length[replacementRung["UnusableImageEvidence"]] === 1 &&
    replacementRung["Status"] === "ProviderSupportRungConsistent"];
FTAssert["SL1 replacement pilots pass exact affine authentication",
  Length[replacementConsistent["PilotImages"]] === 2 &&
    AllTrue[replacementConsistent["PilotImages"],
      Lookup[authenticatePilot[#, layout, provider], "Status", None] ===
        "AuthenticatedMultiquadraticPilotImageV1" &]];

replacementInconsistent = runScenario[<|primes[[1]] -> "Unavailable",
  primes[[2]] -> "Inconsistent", primes[[3]] -> "Inconsistent"|>];
FTAssert["SL2 only two unanimous usable inconsistencies certify exhaustion",
  replacementInconsistent["Status"] ===
      "DeferredProviderSupportLadderExhausted" &&
    TrueQ[replacementInconsistent["FiniteFieldAnsatzInconsistencyEvidenceComplete"]] &&
    First[replacementInconsistent["LadderRungs"]]["AttemptCount"] === 3 &&
    First[replacementInconsistent["LadderRungs"]]["Defects"] === {1, 1}];

mixed = runScenario[<|primes[[1]] -> "Consistent",
  primes[[2]] -> "Inconsistent"|>];
FTAssert["SL3 mixed usable evidence is typed inconclusive, never obstruction",
  mixed["Status"] === "DeferredProviderSupportLadderInconclusive" &&
    mixed["Reason"] === "MixedConsistencyEvidence" &&
    ! TrueQ[mixed["FiniteFieldAnsatzInconsistencyEvidenceComplete"]] &&
    First[mixed["LadderRungs"]]["Status"] ===
      "ProviderSupportRungMixedEvidence"];

unavailable = runScenario[<||>];
FTAssert["SL4 an exhausted replacement schedule without quorum is inconclusive",
  unavailable["Status"] === "DeferredProviderSupportLadderInconclusive" &&
    unavailable["Reason"] === "UsableImageQuorumUnavailable" &&
    First[unavailable["LadderRungs"]]["AttemptCount"] === 4 &&
    First[unavailable["LadderRungs"]]["ImageCount"] === 0 &&
    Length[First[unavailable["LadderRungs"]][
      "UnusableImageEvidence"]] === 4];

FTSummary[];
