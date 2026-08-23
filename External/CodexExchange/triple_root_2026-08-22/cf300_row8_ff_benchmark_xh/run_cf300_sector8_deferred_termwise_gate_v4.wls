#!/usr/bin/env wolframscript
repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
outDir = FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh"}];
resultFile = FileNameJoin[{outDir,
  "cf300_sector8_deferred_termwise_gate_v4.wl"}];
Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{repo, "FeynFacet", "Private",
  "FamilyRowGaugeFiniteField.wl"}]];
End[];
Get[FileNameJoin[{exchange, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchange, "TripleRootStripAdapter.wl"}]];
Get[FileNameJoin[{outDir, "FamilyRowGaugeDeferredPrototype.wl"}]];
preFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_state_CF300_codex_triple_root.wl"}];
checkpointFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_CF300_codex_triple_root", "CF300_8_strip_state.wl"}];
postFile = FileNameJoin[{repo, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-23", "CF300", "sector_state_CF300_standard.wl"}];
pre = FeynFacet`FamilyArtifactRead[preFile];
checkpoint = FeynFacet`FamilyArtifactRead[checkpointFile];
post = FeynFacet`FamilyArtifactRead[postFile];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilon = First[DeleteDuplicates[Cases[{pre["A"], checkpoint["PrevD"]},
  s_Symbol /; SymbolName[s] === "eps", Infinity]]];
rows = pre["Ranges"][[8]]; stop = Last[rows];
lowerColumns = Range[First[rows] - 1];
installedRow = post["A"][[All, rows, lowerColumns]];
{deferredSeconds, deferred} = AbsoluteTiming[
  CodexRowGaugeDeferred`ApplyDeferredFutureRowGauge[
    pre["A"], pre["S"], pre["SInverse"], rows,
    checkpoint["PrevD"], variables, installedRow]];
rootsNatural = CodexTripleRootStrip`TRCurrentRoots[
  FeynFacet`TransportFamilyChart["CF300"], variables];
{prepareSeconds, prep} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeFiniteFieldPrepare[
    pre["A"], pre["S"], pre["SInverse"], rows,
    checkpoint["PrevD"], variables, rootsNatural]];
If[Lookup[deferred, "Status", None] =!= "OK" ||
    Lookup[prep, "Status", None] =!= "Prepared", Exit[2]];
futureRecords = Select[prep["Records", "Connection"],
  #1["Target"][[2]] > stop &];
targets = Lookup[futureRecords, "Target"];
roots = prep["CanonicalRoots"];
rootSquares = Lookup[roots, "RootSquare", {}];
targetExpressions = Extract[deferred["Connection"], #] & /@ targets;
{compileSeconds, compiledDeferred} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeFFReplaceRoots[#,
      rootSquares] & /@ targetExpressions];
If[! FreeQ[compiledDeferred,
    _FeynFacet`Private`familyRowGaugeFFUnresolvedRoot], Exit[3]];

primes = {1000003, 1000033, 1000037};
points = {{550663, 659718}, {231456, 6616}, {395891, 913580}};
epsilonValues = {7, 11, 13};
samples = Table[
  prime = primes[[sampleIndex]]; point = points[[sampleIndex]];
  scalarValues = Association[Join[Thread[variables -> point],
    {epsilon -> epsilonValues[[sampleIndex]]}]];
  rootSquareResults = FeynFacet`Private`familyRowGaugeFFModEvaluate[
      #, scalarValues, {}, prime] & /@ rootSquares;
  rootSquareValues = Lookup[rootSquareResults, "Value", {}];
  rootValues = FeynFacet`Private`familyRowGaugeFFSquareRoot[#,
      prime] & /@ rootSquareValues;
  branchResults = Table[
    signedRoots = MapIndexed[
      If[BitGet[branch, First[#2] - 1] === 1,
        Mod[-#1, prime], #1] &, rootValues];
    {deferredEvalSeconds, deferredResults} = AbsoluteTiming[
      FeynFacet`Private`familyRowGaugeFFModEvaluate[
          #, scalarValues, signedRoots, prime] & /@ compiledDeferred];
    {recordEvalSeconds, recordResults} = AbsoluteTiming[
      Table[termResults =
        FeynFacet`Private`familyRowGaugeFFModEvaluate[
            #1["Expression"], scalarValues, signedRoots, prime] & /@
          futureRecords[[recordIndex, "Terms"]];
        If[AllTrue[termResults,
            Lookup[#1, "Status", None] === "OK" &],
          <|"Status" -> "OK", "Value" -> Mod[
            Total[Lookup[termResults, "Value"]], prime]|>,
          <|"Status" -> "TermEvaluationFailed"|>],
        {recordIndex, Length[futureRecords]}]];
    deferredValues = Lookup[deferredResults, "Value", Missing["Failed"]];
    recordValues = Lookup[recordResults, "Value", Missing["Failed"]];
    differing = Pick[targets,
      MapThread[! SameQ[#1, #2] &, {deferredValues, recordValues}], True];
    <|"BranchMask" -> branch,
      "DeferredEvaluateSeconds" -> deferredEvalSeconds,
      "RecordTermEvaluateSeconds" -> recordEvalSeconds,
      "DeferredFailureCount" -> Count[deferredResults,
        a_Association /; Lookup[a, "Status", None] =!= "OK"],
      "RecordFailureCount" -> Count[recordResults,
        a_Association /; Lookup[a, "Status", None] =!= "OK"],
      "DifferingTargetCount" -> Length[differing],
      "FirstDifferingTarget" -> If[differing === {}, None, First[differing]],
      "Exact" -> differing === {} &&
        AllTrue[deferredResults, Lookup[#1, "Status", None] === "OK" &] &&
        AllTrue[recordResults, Lookup[#1, "Status", None] === "OK" &]|>,
    {branch, 0, 2^Length[roots] - 1}];
  Print["TERM GATE sample ", sampleIndex, " prime=", prime,
    " exact=", And @@ Lookup[branchResults, "Exact"]];
  <|"Role" -> If[sampleIndex <= 2, "Construction", "UnseenValidation"],
    "Prime" -> prime, "Point" -> point,
    "EpsilonValue" -> epsilonValues[[sampleIndex]],
    "RootSquareValues" -> rootSquareValues,
    "AllSignsExact" -> And @@ Lookup[branchResults, "Exact"],
    "Branches" -> branchResults|>,
  {sampleIndex, 3}];

checks = <|"Prepared" -> prep["Status"] === "Prepared",
  "DeferredBuilt" -> deferred["Status"] === "OK",
  "TargetCount36" -> Length[targets] === 36,
  "TargetRows23And24" ->
    Counts[targets[[All, 2]]] === <|23 -> 18, 24 -> 18|>,
  "CompiledNoUnknownRadicals" -> FreeQ[compiledDeferred,
    _FeynFacet`Private`familyRowGaugeFFUnresolvedRoot],
  "TwoConstructionPlusUnseenAllSigns" ->
    And @@ Lookup[samples, "AllSignsExact"]|>;
status = If[And @@ Values[checks], "OK", "Failed"];
record = <|"Status" -> status,
  "Purpose" -> "DeferredFutureATermwiseRealGate",
  "Family" -> "CF300", "Sector" -> 8, "Rows" -> rows,
  "Checks" -> checks, "Targets" -> targets,
  "DeferredBuildSeconds" -> deferredSeconds,
  "PreparationSeconds" -> prepareSeconds,
  "CompileSeconds" -> compileSeconds,
  "DeferredLeafCount" -> Total[LeafCount /@ targetExpressions],
  "DeferredByteCount" -> ByteCount[targetExpressions],
  "Samples" -> samples,
  "SourceHashes" -> <|"PreState" ->
      FileHash[preFile, "SHA256", "HexString"],
    "Checkpoint" -> FileHash[checkpointFile, "SHA256", "HexString"],
    "PostState" -> FileHash[postFile, "SHA256", "HexString"]|>,
  "ProductionHook" -> False|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["TERM GATE RESULT ", KeyTake[record,
  {"Status", "Checks", "DeferredBuildSeconds", "PreparationSeconds",
   "CompileSeconds", "DeferredLeafCount", "DeferredByteCount"}],
  " written=", resultFile];
Clear[pre, checkpoint, post, deferred, prep, targetExpressions,
  compiledDeferred, samples, record];
Exit[If[status === "OK", 0, 1]];
