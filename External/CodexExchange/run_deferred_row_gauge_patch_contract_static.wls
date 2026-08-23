#!/usr/bin/env wolframscript
(* Static source contract for the production-only deferred row-gauge patch.
   This intentionally does not load FeynFacet or start parallel kernels.

   Usage:
     wolframscript -file run_deferred_row_gauge_patch_contract_static.wls \
       [repository-root] [optional-result.wl]
*)

arguments = Rest[$ScriptCommandLine];
defaultRoot = ParentDirectory[
  ParentDirectory[DirectoryName[ExpandFileName[$InputFileName]]]];
repositoryRoot = If[Length[arguments] >= 1,
  ExpandFileName[arguments[[1]]], defaultRoot];
resultFile = If[Length[arguments] >= 2,
  ExpandFileName[arguments[[2]]], None];
sectorFile = FileNameJoin[
  {repositoryRoot, "Scripts", "family_epsform_sector.wls"}];
regulatorFile = FileNameJoin[
  {repositoryRoot, "FeynFacet", "Private", "FamilyRegulatorFactor.wl"}];

If[! FileExistsQ[sectorFile] || ! FileExistsQ[regulatorFile],
  Print["DEFERRED_STATIC unreadable source root=", repositoryRoot];
  Exit[2]];

sectorSource = Import[sectorFile, "Text"];
regulatorSource = Import[regulatorFile, "Text"];
positions[source_, needle_] := StringPosition[source, needle];
singlePosition[source_, needle_] := Module[{found = positions[source, needle]},
  If[Length[found] === 1, First[found], Missing["NotUnique"]]];

modePosition = singlePosition[sectorSource,
  "futureAMode = If[productionQ && installedRow =!= Automatic"];
passPosition = singlePosition[sectorSource, "installedRow, futureAMode]"];
statisticsPosition = singlePosition[sectorSource,
  "\"RowGaugeStatistics\" -> rowGaugeStatistics"];
propagationPosition = singlePosition[sectorSource,
  "familyRegulatorPropagateTruncation["];
propagationInstallPosition = singlePosition[sectorSource,
  "\"A\" -> propagation[\"Connection\"]"];
propagationStatisticsPosition = singlePosition[sectorSource,
  "\"PropagationStatistics\" -> propagation[\"Statistics\"]"];
successfulFactorPosition = singlePosition[sectorSource,
  "If[blockwiseRouteQ, factorTruncated[k]];"];
guardPosition = singlePosition[sectorSource,
  "If[productionQ && AssociationQ[rowGaugeStatistics]"];
censusPosition = singlePosition[sectorSource,
  "remaining = Length[badStrips[state[\"A\"], nb]];"];
stateWrites = positions[sectorSource, "putAtomic[state, stateFile];"];
stateWritesBeforeCensus = If[ListQ[censusPosition],
  Select[stateWrites, Last[#] < First[censusPosition] &], {}];
lastWriteBeforeCensus = If[stateWritesBeforeCensus === {},
  Missing["NoWrite"], Last[stateWritesBeforeCensus]];

checks = <|
  "SourcesReadable" -> StringQ[sectorSource] && StringQ[regulatorSource],
  "ProductionModeSelectionUnique" -> ListQ[modePosition],
  "AutomaticFallsBackTogether" -> StringContainsQ[sectorSource,
    "futureAMode = If[productionQ && installedRow =!= Automatic,\n    \"Deferred\", \"Together\"]"],
  "ModePassedToRowGauge" -> ListQ[passPosition] &&
    ListQ[modePosition] && First[passPosition] > First[modePosition],
  "RowStatisticsPersisted" -> ListQ[statisticsPosition],
  "RegulatorPropagationCalled" -> ListQ[propagationPosition],
  "RegulatorPropagationInstalled" -> ListQ[propagationInstallPosition] &&
    ListQ[propagationPosition] &&
    First[propagationInstallPosition] > First[propagationPosition],
  "RegulatorPropagationStatisticsPersisted" ->
    ListQ[propagationStatisticsPosition],
  "RegulatorTransformationDirections" ->
    StringContainsQ[sectorSource,
      "familyRegulatorSparseDot[state[\"S\"], tFull, False]"] &&
    StringContainsQ[sectorSource,
      "familyRegulatorSparseDot[tInv, state[\"SInverse\"], True]"],
  "RegulatorConstantInverseAndSealGuards" ->
    StringContainsQ[regulatorSource,
      "RegulatorTransformationNotConstant"] &&
    StringContainsQ[regulatorSource,
      "RegulatorTransformationInverseInvalid"] &&
    StringContainsQ[regulatorSource,
      "RegulatorPropagationSealMismatch"],
  "FactorRoutinesCreatePropagationSeal" ->
    Length[StringPosition[regulatorSource,
      "\"PropagationSeal\" -> familyRegulatorPropagationSeal["]] === 2,
  "RegulatorHelperTyped" -> StringContainsQ[regulatorSource,
      "familyRegulatorPropagateTruncation["] &&
    StringContainsQ[regulatorSource,
      "\"Status\" -> \"InvalidBlockStructure\""] &&
    StringContainsQ[regulatorSource,
      "MemberQ[{\"Together\", \"Deferred\"}, futureMode]"],
  "RegulatorDeferredRawMultiTermSum" -> StringContainsQ[regulatorSource,
    "True, deferred++; Total[terms]"],
  "RegulatorSingleTermFastPath" -> StringContainsQ[regulatorSource,
    "Length[terms] === 1, singleTerm++; First[terms]"],
  "BadStripsCensusUnique" -> ListQ[censusPosition],
  "BadStripsGuardUsesAppliedMode" -> ListQ[guardPosition] &&
    ListQ[censusPosition] && First[guardPosition] < First[censusPosition] &&
    StringContainsQ[StringTake[sectorSource,
      {First[guardPosition], First[censusPosition]}],
      "\"FutureAMode\""] &&
    StringContainsQ[StringTake[sectorSource,
      {First[guardPosition], First[censusPosition]}], "=== \"Deferred\""],
  "StateWriteBeforeGuardedCensus" -> ListQ[lastWriteBeforeCensus] &&
    ListQ[successfulFactorPosition] && ListQ[guardPosition] &&
    Last[successfulFactorPosition] < First[lastWriteBeforeCensus] &&
    Last[lastWriteBeforeCensus] < First[guardPosition],
  "FinalCertificateBoundaryRecorded" -> StringContainsQ[sectorSource,
    "CertifyFamilyEpsilonForm is the sole exact acceptance test"]
|>;

result = <|"Status" -> If[And @@ Values[checks], "OK", "Failed"],
  "Purpose" -> "DeferredRowGaugeProductionPatchStaticContract",
  "Checks" -> checks,
  "SourceHashes" -> <|
    "family_epsform_sector.wls" ->
      FileHash[sectorFile, "SHA256", "HexString"],
    "FamilyRegulatorFactor.wl" ->
      FileHash[regulatorFile, "SHA256", "HexString"]|>,
  "Ordering" -> <|"LastStateWriteBeforeCensus" -> lastWriteBeforeCensus,
    "SuccessfulFactorReturn" -> successfulFactorPosition,
    "Guard" -> guardPosition, "Census" -> censusPosition|>|>;

If[StringQ[resultFile],
  outputDirectory = DirectoryName[resultFile];
  If[! DirectoryQ[outputDirectory],
    CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];
  Put[result, resultFile]];
Print["DEFERRED_STATIC status=", result["Status"],
  " checks=", Count[Values[checks], True], "/", Length[checks],
  " result=", If[StringQ[resultFile], resultFile, "stdout-only"]];
If[result["Status"] =!= "OK", Print[InputForm[result]]];
Exit[If[result["Status"] === "OK", 0, 1]];
