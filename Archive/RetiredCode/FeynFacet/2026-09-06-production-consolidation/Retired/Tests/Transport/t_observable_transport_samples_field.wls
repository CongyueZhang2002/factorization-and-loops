#!/usr/bin/env wolframscript

(* V2 coefficient presentations are explicit.  Zero-residue letters do not
   constrain finite-field samples, and no coefficient-field inference from
   legacy ChartRecord data remains. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];

x = Symbol["Global`sampleX"];
y = Symbol["Global`sampleY"];
eps = Symbol["Global`eps"];
grid = FeynFacet`Private`$observableTransportSampleFractions;
family = "SampleExhaustionToy";

familySystem = <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> family, "KinematicVariables" -> {x, y},
  "DimensionalRegulator" -> eps,
  "OriginalMasterIntegralBasis" -> {sampleMaster[family, {1}]},
  "ConnectionMatrices" -> {{{eps/x}}, {{0}}}|>;
candidate = <|
  "Family" -> family, "Variables" -> {x, y}, "Regulator" -> eps,
  "Ranges" -> {{1}}, "Blocks" -> {{1}},
  "TTotal" -> {{eps}}, "TTotalInverse" -> {{1/eps}},
  "EpsFormX" -> {{eps/x}}, "EpsFormY" -> {{0}}|>;
baseRecord = FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
  candidate, familySystem, <|
    "RelativePath" -> "sample_exhaustion_toy.wl",
    "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
    "Family" -> family|>, "IdentityMethod" -> "Symbolic"];

(* A zero-residue letter leaves the differential equation unchanged, but it
   remains a declared divisor that admissible finite-field samples avoid. *)
toy[extraLetter_] := Join[baseRecord, <|
  "Letters" -> Append[baseRecord["Letters"], extraLetter],
  "ConstantResidueMatrices" ->
    Append[baseRecord["ConstantResidueMatrices"], {{0}}]|>];
path = <|"FirstVariable" -> x, "SecondVariable" -> y,
  "FirstBase" -> 1/4, "SecondBase" -> 1/4,
  "FirstPathParameterScale" -> 1/28|>;
demand = <|
  "RequestedMasterIntegralEpsilonOrderAndRowPairs" -> {{2, 1}, {3, 1}},
  "MinimumRetainedMasterIntegralEpsilonOrder" -> 2,
  "RegularBasePointAndFirstPathParameterScale" -> path|>;
build[record_, options___] :=
  ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[
    record, demand,
    "BoundaryConstraintSubspaceRepresentation" ->
      "AmbientSpaceWithBasePointConstraints", options];

regularResult = build[toy[1 + y]];
killY = Times @@ ((y - #) & /@ grid);
killX = Times @@ ((x - #) & /@ grid);
rankExhausted = build[toy[killY]];
residueExhausted = build[toy[killX]];
explicitRankSample = build[toy[killY],
  "RankSamples" -> {{Symbol["Global`t"] -> 1/4, y -> 1/4}}];

missingPresentation = KeyDrop[baseRecord, "CoefficientPresentation"];
legacyChartOnly = Join[missingPresentation, <|
  "ChartRecord" -> <|"CoefficientField" -> "Rational"|>|>];
missingPath = ChooseRegularBasePointAndFirstPathParameterScale[
  missingPresentation];
legacyChartPath = ChooseRegularBasePointAndFirstPathParameterScale[
  legacyChartOnly];
missingBuild = build[missingPresentation];

Print["sample-selection statuses: ",
  KeyTake[rankExhausted,
    {"Status", "SampleKind", "Requested", "Available", "Candidates"}],
  " / ",
  KeyTake[residueExhausted,
    {"Status", "SampleKind", "Requested", "Available", "Candidates"}]];

FTAssert["the explicit V2 source-variable presentation is accepted",
  ExactlyValidatedFamilyDLogEpsilonFormQ[baseRecord] &&
    regularResult["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[regularResult]];
FTAssert["zero-residue letters do not constrain rank samples",
  rankExhausted["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[rankExhausted]];
FTAssert["zero-residue letters do not constrain residue samples",
  residueExhausted["Status"] ===
      "IteratedIntegralCoefficientOperatorForRequestedOutputsValidated" &&
    IteratedIntegralCoefficientOperatorForRequestedOutputsQ[
      residueExhausted]];
FTAssert["an explicit rank sample bypasses automatic rank-grid exhaustion",
  explicitRankSample["Status"] =!= "AdmissibleSamplesExhausted" ||
    Lookup[explicitRankSample, "SampleKind", None] =!= "Rank"];
FTAssert["missing coefficient presentation is refused typed",
  missingPath["Status"] === "CoefficientPresentationRequired" &&
    missingBuild["Status"] ===
      "RequestedOutputCoefficientOperatorPresentationMissingOrInvalid"];
FTAssert["a legacy ChartRecord does not restore coefficient-field inference",
  legacyChartPath["Status"] === "CoefficientPresentationRequired"];

FTReport[];
