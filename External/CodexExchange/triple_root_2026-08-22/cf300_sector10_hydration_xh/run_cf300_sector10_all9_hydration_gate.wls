#!/usr/bin/env wolframscript
(* External-only all-block hydration and installed-row gate for CF300 sector 10. *)

repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
benchDir = FileNameJoin[{exchange, "cf300_sector10_hydration_xh"}];
scratch = FileNameJoin[{benchDir, "scratch"}];
resultFile = FileNameJoin[{benchDir,
  "cf300_sector10_all9_hydration_gate_result.wl"}];
stateFile = FileNameJoin[{scratch, "sector_state_CF300_post9.wl"}];
checkpointFile = FileNameJoin[{scratch,
  "CF300_10_legacy_strip_state.wl"}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{repo, "FeynFacet", "Private",
  "FamilyRowGaugeFiniteField.wl"}]];
End[];
Get[FileNameJoin[{exchange, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchange, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh",
  "FamilyRowGaugeDeferredPrototype.wl"}]];

hashDirectory[dir_] := If[DirectoryQ[dir], Association@Table[
    FileNameTake[file] -> FileHash[file, "SHA256", "HexString"],
    {file, Sort[FileNames["*.wl", dir]]}], <||>];
modNumber[value_, prime_] := Module[{q, denominator},
  q = Quiet[Check[Together[value], $Failed]];
  If[q === $Failed || ! MatchQ[q, _Integer | _Rational],
    Return[$Failed]];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[q] PowerMod[denominator, -1, prime], prime]];

state = FeynFacet`FamilyArtifactRead[stateFile];
checkpoint = FeynFacet`FamilyArtifactRead[checkpointFile];
If[! AssociationQ[state] || ! AssociationQ[checkpoint], Exit[2]];
If[Lookup[state, "Sector", None] =!= 9 ||
    Lookup[checkpoint, "Sector", None] =!= 10, Exit[3]];
frame = FeynFacet`TransportFamilyChart["CF300"];
rows = state["Ranges"][[10]];
start = First[rows]; stop = Last[rows]; n = Length[state["S"]];
lowerColumns = Range[start - 1]; futureRows = Range[start, n];
rowSize = Length[rows]; lowerSize = Length[lowerColumns];
gauge = checkpoint["PrevD"];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = First[DeleteDuplicates[Cases[{state["A"], gauge},
  s_Symbol /; SymbolName[s] === "eps", Infinity]]];

solutions = <||>; solvedBlocks = <||>; solvedForms = <||>;
replayRecords = {};
memoryBefore = MemoryInUse[];
Do[
  inputFile = FileNameJoin[{scratch,
    "CF300_10_" <> ToString[nlow] <> "_input.wl"}];
  artifactDir = FileNameJoin[{scratch,
    "CF300_10_" <> ToString[nlow] <> "_finite_field"}];
  input = FeynFacet`FamilyArtifactRead[inputFile];
  hashesBefore = hashDirectory[artifactDir];
  Print["ALL9 hydrate block (10,", nlow, ") zero=",
    AllTrue[Flatten[input["Strip"][[3]]], SameQ[#, 0] &],
    " cached=", Length[hashesBefore]];
  {seconds, solution} = AbsoluteTiming[
    FeynFacet`SolveEpsFormStripInFrame[
      input["Strip"], input["Variables"], input["Regulator"], frame,
      "FiniteFieldFirst" -> True,
      "FiniteFieldOptions" -> {
        "KernelCount" -> 1,
        "FinalCheck" -> "Numerical",
        "Verbose" -> True},
      "ScratchDirectory" -> scratch,
      "Tag" -> "CF300_10_" <> ToString[nlow],
      "Verbose" -> True]];
  hashesAfter = hashDirectory[artifactDir];
  blockGauge = If[AssociationQ[solution],
    Lookup[solution, "Gauge", Missing["NoGauge"]],
    Missing["NoSolution"]];
  blockDimensions = If[MatrixQ[blockGauge], Dimensions[blockGauge], {}];
  blockForm = If[MatchQ[blockDimensions, {_Integer, _Integer}],
    FeynFacet`Private`familyRowGaugeDLogForm[solution,
      variables, epsilon, blockDimensions], Missing["NoDimensions"]];
  AssociateTo[solutions, nlow -> solution];
  AssociateTo[solvedBlocks, nlow -> blockGauge];
  AssociateTo[solvedForms, nlow -> blockForm];
  AppendTo[replayRecords, <|"LowerSector" -> nlow,
    "ZeroForcing" -> AllTrue[Flatten[input["Strip"][[3]]],
      SameQ[#, 0] &],
    "CachedPrimeCount" -> Length[hashesBefore],
    "Seconds" -> seconds,
    "Status" -> If[AssociationQ[solution],
      Lookup[solution, "Status", None], "NotAssociation"],
    "Method" -> If[AssociationQ[solution],
      Lookup[solution, "Method", None], None],
    "Certificate" -> If[AssociationQ[solution],
      Lookup[solution, "Certificate", None], None],
    "GaugeDimensions" -> blockDimensions,
    "SolvedFormDimensions" -> If[ListQ[blockForm],
      Dimensions[blockForm], {}],
    "SolvedFormHash" -> If[ListQ[blockForm],
      Hash[blockForm, "SHA256", "HexString"], None],
    "ArtifactHashesPreserved" -> hashesBefore === hashesAfter|>],
  {nlow, 9}];
memoryAfterHydration = MemoryInUse[];

blockColumns = Association@Table[nlow -> state["Ranges"][[nlow]],
  {nlow, 9}];
{assemblySeconds, installedRow} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeAssembleInstalledRow[
    solvedForms, solvedBlocks, rowSize, lowerSize, blockColumns]];
installedQ = ListQ[installedRow] &&
  Dimensions[installedRow] === {2, rowSize, lowerSize};
{deferredSeconds, deferred} = AbsoluteTiming[
  If[installedQ,
    CodexRowGaugeDeferred`ApplyDeferredFutureRowGauge[
      state["A"], state["S"], state["SInverse"], rows, gauge,
      variables, installedRow], <|"Status" -> "AssemblyFailed"|>]];

(* Independent numeric formula.  Root placeholders are fixed formal symbols,
   not mutable Unique names; the same branch rules are applied to observed
   deferred slices and to independently multiplied base matrices. *)
roots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
rootSymbols = Table[Symbol["CodexCF300HydrationGate`r" <>
  ToString[index]], {index, Length[roots]}];
dGauge = D[gauge, #] & /@ variables;
rawArrays = If[Lookup[deferred, "Status", None] === "OK", {
    deferred["Connection"][[All, futureRows, lowerColumns]],
    deferred["Transformation"][[All, lowerColumns]],
    deferred["Inverse"][[rows, All]],
    state["A"][[All, futureRows, lowerColumns]],
    state["A"][[All, futureRows, rows]],
    state["A"][[All, lowerColumns, lowerColumns]],
    state["S"][[All, lowerColumns]], state["S"][[All, rows]],
    state["SInverse"][[rows, All]],
    state["SInverse"][[lowerColumns, All]], gauge, dGauge}, {}];
{templateSeconds, templates} = AbsoluteTiming[
  CodexTripleRootStrip`TRApplyRootBranches[#,
      roots, rootSymbols] & /@ rawArrays];

primes = {1000003, 1000037};
points = {{550663, 659718}, {395891, 913580}};
epsilonValues = {17, 19};
heldOutChecks = If[templates === {}, {}, Table[
  prime = primes[[sampleIndex]];
  point = points[[sampleIndex]];
  variableRules = Thread[variables -> point];
  rootSquareValues = modNumber[# /. variableRules, prime] & /@
    Lookup[roots, "RootSquare", {}];
  rootValues = If[AllTrue[rootSquareValues,
      IntegerQ[#] && # =!= 0 && JacobiSymbol[#, prime] === 1 &],
    FeynFacet`Private`familyRowGaugeFFSquareRoot[#, prime] & /@
      rootSquareValues, ConstantArray[$Failed, Length[roots]]];
  branchResults = Table[
    signedRoots = MapIndexed[
      If[BitGet[branch, First[#2] - 1] === 1,
        Mod[-#1, prime], #1] &, rootValues];
    rules = Join[variableRules, {epsilon -> epsilonValues[[sampleIndex]]},
      Thread[rootSymbols -> signedRoots]];
    modArray[array_] := Map[modNumber[# /. rules, prime] &,
      array, {ArrayDepth[array]}];
    evaluated = modArray /@ templates;
    If[! FreeQ[evaluated, $Failed],
      <|"BranchMask" -> branch, "Exact" -> False,
        "Status" -> "ModularEvaluationFailed"|>,
      {observedA, observedS, observedSi, baseA, aRight, aLower,
        baseS, leftS, baseSi, rightSi, numericGauge,
        numericDGauge} = evaluated;
      directA = Table[Module[{right =
          Mod[baseA[[mu]] + aRight[[mu]].numericGauge, prime]},
        right[[Range[rowSize]]] = Mod[
          right[[Range[rowSize]]] - numericGauge.aLower[[mu]] -
            numericDGauge[[mu]], prime];
        right], {mu, 2}];
      directS = Mod[baseS + leftS.numericGauge, prime];
      directSi = Mod[baseSi - numericGauge.rightSi, prime];
      <|"BranchMask" -> branch,
        "Connection" -> SameQ[Mod[observedA, prime], directA],
        "Transformation" -> SameQ[Mod[observedS, prime], directS],
        "Inverse" -> SameQ[Mod[observedSi, prime], directSi],
        "Exact" -> And[
          SameQ[Mod[observedA, prime], directA],
          SameQ[Mod[observedS, prime], directS],
          SameQ[Mod[observedSi, prime], directSi]]|>],
    {branch, 0, 2^Length[roots] - 1}];
  <|"Prime" -> prime, "Point" -> point,
    "EpsilonValue" -> epsilonValues[[sampleIndex]],
    "SplitRootSquareValues" -> rootSquareValues,
    "AllSignsExact" -> And @@ Lookup[branchResults, "Exact"],
    "Branches" -> branchResults|>,
  {sampleIndex, Length[primes]}]];

checks = <|
  "AllNineHydrated" -> AllTrue[replayRecords,
    #1["Status"] === "Solved" &],
  "ThreeZeroSixCached" ->
    Count[replayRecords, a_Association /; TrueQ[a["ZeroForcing"]]] === 3 &&
    Count[replayRecords, a_Association /; ! TrueQ[a["ZeroForcing"]] &&
      a["CachedPrimeCount"] >= 3] === 6,
  "AllCopiedArtifactsPreserved" -> AllTrue[replayRecords,
    TrueQ[#1["ArtifactHashesPreserved"]] &],
  "SolvedBlockKeyCoverage" -> Sort[Keys[solvedBlocks]] === Range[9],
  "SolvedFormKeyCoverage" -> Sort[Keys[solvedForms]] === Range[9],
  "InstalledRowAssembled" -> installedQ,
  "DeferredApplyOK" -> Lookup[deferred, "Status", None] === "OK",
  "TwoHeldOutPointsAllSigns" -> Length[heldOutChecks] === 2 &&
    And @@ Lookup[heldOutChecks, "AllSignsExact"]|>;
status = If[And @@ Values[checks], "OK", "Failed"];
record = <|"Status" -> status,
  "Purpose" -> "All9LegacyHydrationInstalledRowGate",
  "Family" -> "CF300", "Sector" -> 10, "Rows" -> rows,
  "Checks" -> checks, "ReplayRecords" -> replayRecords,
  "TotalHydrationSeconds" -> Total[Lookup[replayRecords, "Seconds"]],
  "AssemblySeconds" -> assemblySeconds,
  "InstalledRowDimensions" -> If[ListQ[installedRow],
    Dimensions[installedRow], {}],
  "InstalledRowLeafCount" -> If[ListQ[installedRow],
    LeafCount[installedRow], 0],
  "InstalledRowByteCount" -> If[ListQ[installedRow],
    ByteCount[installedRow], 0],
  "DeferredBuildSeconds" -> deferredSeconds,
  "DeferredStatistics" -> Lookup[deferred, "Statistics", <||>],
  "TemplateSeconds" -> templateSeconds,
  "HeldOutChecks" -> heldOutChecks,
  "SourceHashes" -> <|
    "PostSector9State" -> FileHash[stateFile, "SHA256", "HexString"],
    "LegacyCheckpoint" -> FileHash[checkpointFile,
      "SHA256", "HexString"]|>,
  "MemoryBytes" -> <|"Before" -> memoryBefore,
    "AfterHydration" -> memoryAfterHydration,
    "MaxMemoryUsed" -> MaxMemoryUsed[]|>,
  "ProductionCheckpointTouched" -> False|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["ALL9 RESULT ", KeyTake[record,
  {"Status", "Checks", "TotalHydrationSeconds", "AssemblySeconds",
   "InstalledRowDimensions", "DeferredBuildSeconds", "TemplateSeconds"}],
  " written=", resultFile];
Clear[state, checkpoint, solutions, solvedBlocks, solvedForms, installedRow,
  deferred, rawArrays, templates, record];
Exit[If[status === "OK", 0, 1]];
