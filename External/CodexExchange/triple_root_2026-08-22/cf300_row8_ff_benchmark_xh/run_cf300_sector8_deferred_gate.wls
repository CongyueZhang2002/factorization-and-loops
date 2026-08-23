#!/usr/bin/env wolframscript
repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
outDir = FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh"}];
resultFile = FileNameJoin[{outDir, "cf300_sector8_deferred_future_A_gate.wl"}];
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
frame = FeynFacet`TransportFamilyChart["CF300"];
roots = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
k = checkpoint["Sector"];
rows = pre["Ranges"][[k]]; start = First[rows]; stop = Last[rows];
lowerColumns = Range[start - 1]; n = Length[pre["S"]];
installedRow = post["A"][[All, rows, lowerColumns]];

memoryBefore = MemoryInUse[];
{deferredSeconds, deferred} = AbsoluteTiming[
  CodexRowGaugeDeferred`ApplyDeferredFutureRowGauge[pre["A"], pre["S"],
    pre["SInverse"], rows, checkpoint["PrevD"], variables,
    installedRow]];
memoryAfter = MemoryInUse[];
If[deferred["Status"] =!= "OK", Exit[2]];
Print["DEFERRED buildSeconds=", N[deferredSeconds],
  " statistics=", deferred["Statistics"]];

{prepareSeconds, prep} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeFiniteFieldPrepare[pre["A"], pre["S"],
    pre["SInverse"], rows, checkpoint["PrevD"], variables, roots]];
If[prep["Status"] =!= "Prepared", Exit[3]];
futureRecords = Select[prep["Records", "Connection"],
  #1["Target"][[2]] > stop &];
futureRecordSet = <|"Connection" -> futureRecords,
  "Transformation" -> {}, "Inverse" -> {}|>;
prepFuture = Join[prep, <|"Records" -> futureRecordSet,
  "Fingerprint" -> FeynFacet`Private`familyRowGaugeFFPreparationFingerprint[
    prep["Variables"], prep["CanonicalRoots"], prep["Parameters"],
    prep["RowIndices"], prep["Dimensions"], futureRecordSet]|>];
targets = Lookup[futureRecords, "Target"];
canonicalRoots = prep["CanonicalRoots"];
rootSymbols = Array[Unique["cf300DeferredRoot"] &,
  Length[canonicalRoots]];
targetTemplates = CodexTripleRootStrip`TRApplyRootBranches[
  Extract[deferred["Connection"], #] & /@ targets,
  canonicalRoots, rootSymbols];

modNumber[value_, prime_] := Module[{q = Together[value], denominator},
  If[! FreeQ[q, _Symbol], Return[$Failed]];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[q] PowerMod[denominator, -1, prime], prime]];

primes = {1000003, 1000033, 1000037};
points = {{550663, 659718}, {231456, 6616}, {395891, 913580}};
epsilonValues = {7, 11, 13};
sampleChecks = Table[
  {sampleSeconds, sample} = AbsoluteTiming[
    FeynFacet`Private`familyRowGaugeFiniteFieldEvaluate[prepFuture,
      points[[sampleIndex]], primes[[sampleIndex]],
      {epsilon -> epsilonValues[[sampleIndex]]}]];
  branchChecks = Table[
    rules = Join[Thread[variables -> points[[sampleIndex]]],
      {epsilon -> epsilonValues[[sampleIndex]]},
      Thread[rootSymbols -> Table[
        If[BitGet[branch, index - 1] === 1,
          Mod[-sample["CanonicalRootValues"][[index]],
            primes[[sampleIndex]]],
          sample["CanonicalRootValues"][[index]]],
        {index, Length[rootSymbols]}]]];
    directValues = modNumber[# /. rules, primes[[sampleIndex]]] & /@
      targetTemplates;
    oracleValues = #1["Conjugates"][[branch + 1]] & /@
      sample["Records", "Connection"];
    SameQ[directValues, oracleValues],
    {branch, 0, 7}];
  <|"Role" -> If[sampleIndex < 3, "Construction", "UnseenValidation"],
    "Prime" -> primes[[sampleIndex]], "Point" -> points[[sampleIndex]],
    "EpsilonValue" -> epsilonValues[[sampleIndex]],
    "EvaluateSeconds" -> sampleSeconds,
    "BranchMasks" -> sample["BranchMasks"],
    "HadamardRoundTrip" -> sample["HadamardRoundTrip"],
    "AllBranchesMatchDeferred" -> And @@ branchChecks,
    "BranchChecks" -> branchChecks|>,
  {sampleIndex, 3}];

referenceConnection = pre["A"];
referenceConnection[[All, rows, lowerColumns]] = installedRow;
unaffectedChecks = Association@Table[
  nk = Last[pre["Ranges"][[sector]]];
  ToString[sector] -> SameQ[
    deferred["Connection"][[All, Range[nk], Range[nk]]],
    referenceConnection[[All, Range[nk], Range[nk]]]],
  {sector, 9, 11}];

futureExpressions = Extract[deferred["Connection"], #] & /@ targets;
deferredState = Join[pre, <|"Sector" -> 8,
  "A" -> deferred["Connection"], "S" -> deferred["Transformation"],
  "SInverse" -> deferred["Inverse"]|>];
temporaryState = FileNameJoin[{"/tmp",
  "cf300_sector8_deferred_state_" <> ToString[$ProcessID] <> ".wl"}];
{serializeSeconds, Null} = AbsoluteTiming[Put[deferredState, temporaryState]];
serializedBytes = FileByteCount[temporaryState];
DeleteFile[temporaryState];

checks = <|
  "CurrentInstalledRowMatchesPostState" -> SameQ[
    deferred["Connection"][[All, rows, lowerColumns]], installedRow],
  "FutureTargetCount" -> Length[targets] === 36,
  "FutureTargetRows" -> Counts[targets[[All, 2]]] === <|23 -> 18, 24 -> 18|>,
  "AllThreeSamplesAllSigns" -> And @@ Flatten[Lookup[sampleChecks,
    {"HadamardRoundTrip", "AllBranchesMatchDeferred"}]],
  "Sectors9Through11Unaffected" -> And @@ Values[unaffectedChecks],
  "SAndInverseStayOnSingleTermPath" ->
    deferred["Statistics", "S", "TogetherSeconds"] === 0. &&
    deferred["Statistics", "SInverse", "TogetherSeconds"] === 0.|>;
status = If[And @@ Values[checks], "OK", "Failed"];
record = <|"Status" -> status, "Purpose" -> "DeferredFutureARealGate",
  "Family" -> "CF300", "Sector" -> k, "Rows" -> rows,
  "SourceHashes" -> <|
    "PreState" -> FileHash[preFile, "SHA256", "HexString"],
    "Checkpoint" -> FileHash[checkpointFile, "SHA256", "HexString"],
    "PostState" -> FileHash[postFile, "SHA256", "HexString"]|>,
  "Checks" -> checks, "UnaffectedSectorChecks" -> unaffectedChecks,
  "BuildSeconds" -> deferredSeconds, "PreparationSeconds" -> prepareSeconds,
  "Statistics" -> deferred["Statistics"], "Samples" -> sampleChecks,
  "FutureTargets" -> targets,
  "FutureLeafCounts" -> (LeafCount /@ futureExpressions),
  "FutureTotalLeafCount" -> Total[LeafCount /@ futureExpressions],
  "FutureByteCount" -> ByteCount[futureExpressions],
  "ConnectionByteCount" -> ByteCount[deferred["Connection"]],
  "StateSerializationSeconds" -> serializeSeconds,
  "StateSerializedBytes" -> serializedBytes,
  "InputPreStateFileBytes" -> FileByteCount[preFile],
  "MemoryBytes" -> <|"BeforeBuild" -> memoryBefore,
    "AfterBuild" -> memoryAfter, "MaxMemoryUsed" -> MaxMemoryUsed[]|>,
  "ProductionHook" -> False,
  "NextGate" -> "Measure sector-12 block-equation preparation on deferred rows 23-24; do not hook if it normalizes the same sums eagerly."|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["DEFERRED RESULT ", KeyTake[record,
  {"Status", "Checks", "BuildSeconds", "FutureTotalLeafCount",
   "FutureByteCount", "StateSerializationSeconds", "StateSerializedBytes"}],
  " written=", resultFile];
Clear[pre, checkpoint, post, deferred, prep, prepFuture, deferredState,
  futureExpressions, targetTemplates];
Exit[If[status === "OK", 0, 1]];
