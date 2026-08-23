#!/usr/bin/env wolframscript
(* Real CF300 sector-8 finite-field row-gauge benchmark.

   This is deliberately an unhooked benchmark.  It compares the modular
   channel sampler with an independent evaluation of the exact block-matrix
   formula, at every sign conjugate, on two construction primes and one
   unseen validation prime.  No dense symbolic row gauge is recomputed. *)

repo = "/home/maxzhang/factorization-and-loops";
exchange = FileNameJoin[{repo, "External", "CodexExchange",
  "triple_root_2026-08-22"}];
outDir = FileNameJoin[{exchange, "cf300_row8_ff_benchmark_xh"}];
If[! DirectoryQ[outDir],
  CreateDirectory[outDir, CreateIntermediateDirectories -> True]];
scriptArgs = Rest[$ScriptCommandLine];
sampleCount = If[scriptArgs =!= {} && IntegerQ[Quiet[Check[
    ToExpression[First[scriptArgs]], $Failed]]],
  ToExpression[First[scriptArgs]], 3];
If[! MemberQ[{1, 3}, sampleCount], sampleCount = 3];
resultFile = FileNameJoin[{outDir, If[sampleCount === 3,
  "cf300_sector8_ff_benchmark.wl", "cf300_sector8_ff_debug_sample.wl"]}];

Get[FileNameJoin[{repo, "Addon", "Load", "LoadFACET.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{repo, "FeynFacet", "Private",
  "FamilyRowGaugeFiniteField.wl"}]];
End[];
Get[FileNameJoin[{exchange, "TripleRootAlgebra.wl"}]];
Get[FileNameJoin[{exchange, "TripleRootStripAdapter.wl"}]];

stateFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_state_CF300_codex_triple_root.wl"}];
checkpointFile = FileNameJoin[{exchange, "cf300_sector8_solved_snapshot",
  "sector_CF300_codex_triple_root", "CF300_8_strip_state.wl"}];

memory0 = MemoryInUse[];
state = FeynFacet`FamilyArtifactRead[stateFile];
checkpoint = FeynFacet`FamilyArtifactRead[checkpointFile];
If[! AssociationQ[state] || ! AssociationQ[checkpoint], Exit[2]];
variables = {Symbol["Global`x"], Symbol["Global`y"]};
epsilonCandidates = DeleteDuplicates[Cases[{state["A"], checkpoint["PrevD"]},
  s_Symbol /; SymbolName[s] === "eps", Infinity]];
If[Length[epsilonCandidates] =!= 1, Exit[3]];
epsilon = First[epsilonCandidates];
frame = FeynFacet`TransportFamilyChart["CF300"];
rootsNatural = CodexTripleRootStrip`TRCurrentRoots[frame, variables];
k = checkpoint["Sector"];
rows = state["Ranges"][[k]];
start = First[rows]; stop = Last[rows];
n = Length[state["S"]];
lowerColumns = Range[start - 1];
futureRows = Range[start, n];
gauge = checkpoint["PrevD"];
payload = {state["A"][[All, futureRows, rows]],
  state["A"][[All, lowerColumns, lowerColumns]],
  state["S"][[All, rows]], state["SInverse"][[lowerColumns, All]], gauge};
extendedPayload = Join[payload, {
  state["A"][[All, futureRows, lowerColumns]],
  state["S"][[All, lowerColumns]], state["SInverse"][[rows, All]]}];
classification = CodexTripleRootStrip`TRClassifyStripRecord[
  <|"Family" -> "CF300", "Sector" -> k, "LowerSector" -> 1,
    "Variables" -> variables, "Strip" -> payload|>, frame];
extendedClassification = CodexTripleRootStrip`TRClassifyStripRecord[
  <|"Family" -> "CF300", "Sector" -> k, "LowerSector" -> 1,
    "Variables" -> variables, "Strip" -> extendedPayload|>, frame];

Print["BENCH fixture sector=", k, " rows=", rows, " n=", n,
  " correctionRoots=", classification["RootIndices"],
  " fullFormulaRoots=", extendedClassification["RootIndices"]];

canonicalNatural = FeynFacet`Private`familyRowGaugeFFCanonicalizeRoots[
  rootsNatural, variables];
canonicalReverse = FeynFacet`Private`familyRowGaugeFFCanonicalizeRoots[
  Reverse[rootsNatural], variables];
rootOrderCanonicalQ = canonicalNatural["Status"] === "OK" &&
  canonicalReverse["Status"] === "OK" &&
  canonicalNatural["Roots"] === canonicalReverse["Roots"] &&
  FeynFacet`Private`familyRowGaugeFFFieldFingerprint[
    variables, canonicalNatural["Roots"]] ===
   FeynFacet`Private`familyRowGaugeFFFieldFingerprint[
    variables, canonicalReverse["Roots"]];

memoryBeforePrepare = MemoryInUse[];
{prepareFullSeconds, prepFull} = AbsoluteTiming[
  FeynFacet`Private`familyRowGaugeFiniteFieldPrepare[state["A"],
    state["S"], state["SInverse"], rows, gauge, variables, rootsNatural]];
memoryAfterFullPrepare = MemoryInUse[];
If[prepFull["Status"] =!= "Prepared",
  Print["BENCH preparation failed status=", Lookup[prepFull, "Status", None],
    " diagnostic=", KeyDrop[prepFull, "Records"]];
  Exit[4]];

(* Production-target view after installing the current certified dlog row:
   only future-row A entries remain candidates for reconstruction. *)
futureConnectionRecords = Select[prepFull["Records", "Connection"],
  #1["Target"][[2]] > stop &];
futureRecords = <|"Connection" -> futureConnectionRecords,
  "Transformation" -> {}, "Inverse" -> {}|>;
prepFuture = Join[prepFull, <|"Records" -> futureRecords,
  "Fingerprint" -> FeynFacet`Private`familyRowGaugeFFPreparationFingerprint[
    prepFull["Variables"], prepFull["CanonicalRoots"],
    prepFull["Parameters"], prepFull["RowIndices"],
    prepFull["Dimensions"], futureRecords]|>];
sSiRecords = <|"Connection" -> {},
  "Transformation" -> prepFull["Records", "Transformation"],
  "Inverse" -> prepFull["Records", "Inverse"]|>;
prepSSi = Join[prepFull, <|"Records" -> sSiRecords,
  "Fingerprint" -> FeynFacet`Private`familyRowGaugeFFPreparationFingerprint[
    prepFull["Variables"], prepFull["CanonicalRoots"],
    prepFull["Parameters"], prepFull["RowIndices"],
    prepFull["Dimensions"], sSiRecords]|>];

Print["BENCH prepared fullSeconds=", N[prepareFullSeconds],
  " fullStats=", prepFull["Statistics"],
  " fullBranches=", prepFull["BranchCount"],
  " futureATouched=", Length[futureConnectionRecords]];

(* Independent exact templates use the exchange adapter, not the finite-field
   oracle's root replacement.  Numeric evaluation happens only after all
   variables, eps, and signed roots have exact integer images. *)
canonicalRoots = prepFull["CanonicalRoots"];
rootSymbols = Array[Unique["cf300ExactRoot"] &, Length[canonicalRoots]];
baseAExact = state["A"][[All, futureRows, lowerColumns]];
aRightExact = state["A"][[All, futureRows, rows]];
aLowerExact = state["A"][[All, lowerColumns, lowerColumns]];
baseSExact = state["S"][[All, lowerColumns]];
sLeftExact = state["S"][[All, rows]];
baseSiExact = state["SInverse"][[rows, All]];
siRightExact = state["SInverse"][[lowerColumns, All]];
dGaugeExact = D[gauge, #] & /@ variables;
{exactTemplateSeconds, exactTemplates} = AbsoluteTiming[
  CodexTripleRootStrip`TRApplyRootBranches[#1, canonicalRoots, rootSymbols] & /@
    {baseAExact, aRightExact, aLowerExact, baseSExact, sLeftExact,
      baseSiExact, siRightExact, gauge, dGaugeExact}];
{baseATemplate, aRightTemplate, aLowerTemplate, baseSTemplate,
  sLeftTemplate, baseSiTemplate, siRightTemplate, gaugeTemplate,
  dGaugeTemplate} = exactTemplates;
Clear[baseAExact, aRightExact, aLowerExact, baseSExact, sLeftExact,
  baseSiExact, siRightExact, dGaugeExact, exactTemplates];

lastModFailure = None;
modNumber[value_, prime_] := Module[{q, denominator, symbols},
  q = Quiet[Check[Together[value], $Failed]];
  symbols = If[q === $Failed, {}, DeleteDuplicates[Cases[q, _Symbol,
    Infinity]]];
  If[q === $Failed || symbols =!= {},
    lastModFailure = <|"Status" -> If[q === $Failed,
      "TogetherFailed", "UnresolvedSymbols"], "Symbols" -> symbols,
      "HeldValue" -> HoldForm[value]|>;
    Return[$Failed]];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0,
    lastModFailure = <|"Status" -> "SingularDenominator"|>;
    Return[$Failed]];
  Mod[Numerator[q] PowerMod[denominator, -1, prime], prime]];
modArray[array_, rules_, prime_] := Map[
  modNumber[#1 /. rules, prime] &, array, {ArrayDepth[array]}];

directFormulaCheck[sample_Association, point_List, epsilonValue_Integer] :=
 Module[{prime = sample["Prime"], branchCount, branchResults, rules,
   baseA, aRight, aLower, baseS, sLeft, baseSi, siRight, dBlock, dGauge,
   directA, directS, directSi, assembledA, assembledS, assembledSi,
   target, branch},
  branchCount = sample["Statistics", "Branches"];
  branchResults = Table[
    rules = Join[Thread[variables -> point], {epsilon -> epsilonValue},
      Thread[rootSymbols -> Table[
        If[BitGet[branch, index - 1] === 1,
          Mod[-sample["CanonicalRootValues"][[index]], prime],
          sample["CanonicalRootValues"][[index]]],
        {index, Length[rootSymbols]}]]];
    {baseA, aRight, aLower, baseS, sLeft, baseSi, siRight, dBlock,
      dGauge} = modArray[#, rules, prime] & /@
       {baseATemplate, aRightTemplate, aLowerTemplate, baseSTemplate,
        sLeftTemplate, baseSiTemplate, siRightTemplate, gaugeTemplate,
        dGaugeTemplate};
    If[! FreeQ[{baseA, aRight, aLower, baseS, sLeft, baseSi, siRight,
        dBlock, dGauge}, $Failed],
      Return[<|"AllBranchesExact" -> False,
        "Status" -> "IndependentEvaluationFailed",
        "Branch" -> branch, "Diagnostic" -> lastModFailure|>]];
    directA = Table[
      Module[{right = Mod[baseA[[mu]] + aRight[[mu]].dBlock, prime]},
        right[[Range[Length[rows]]]] =
          Mod[right[[Range[Length[rows]]]] - dBlock.aLower[[mu]] -
            dGauge[[mu]], prime];
        right], {mu, 2}];
    directS = Mod[baseS + sLeft.dBlock, prime];
    directSi = Mod[baseSi - dBlock.siRight, prime];
    assembledA = baseA; assembledS = baseS; assembledSi = baseSi;
    Do[target = entry["Target"];
      assembledA[[target[[1]], target[[2]] - start + 1,
        target[[3]]]] = entry["Conjugates"][[branch + 1]],
      {entry, sample["Records", "Connection"]}];
    Do[target = entry["Target"];
      assembledS[[target[[1]], target[[2]]]] =
        entry["Conjugates"][[branch + 1]],
      {entry, sample["Records", "Transformation"]}];
    Do[target = entry["Target"];
      assembledSi[[target[[1]] - start + 1, target[[2]]]] =
        entry["Conjugates"][[branch + 1]],
      {entry, sample["Records", "Inverse"]}];
    <|"Connection" -> SameQ[Mod[assembledA, prime], directA],
      "Transformation" -> SameQ[Mod[assembledS, prime], directS],
      "Inverse" -> SameQ[Mod[assembledSi, prime], directSi]|>,
    {branch, 0, branchCount - 1}];
  <|"AllBranchesExact" -> And @@ Flatten[Values /@ branchResults],
    "Status" -> "Compared",
    "BranchExact" -> branchResults|>
 ];

prime1 = 1000003;
prime2 = NextPrime[prime1];
prime3 = NextPrime[prime2];
primes = {prime1, prime2, prime3};
epsilonValues = {7, 11, 13};
samples = {};
sampleSummaries = {};
Do[
  SeedRandom[2026082300 + sampleIndex];
  accepted = False; attempts = 0;
  While[! accepted && attempts < 500,
    attempts++;
    point = RandomInteger[{2, primes[[sampleIndex]] - 2}, 2];
    If[! CodexTripleRoot`TRSplitPointQ[point,
      Lookup[canonicalRoots, "RootSquare", {}], variables,
      primes[[sampleIndex]]], Continue[]];
    {fullEvaluateSeconds, fullSample} = AbsoluteTiming[
      FeynFacet`Private`familyRowGaugeFiniteFieldEvaluate[prepFull,
        point, primes[[sampleIndex]],
        {epsilon -> epsilonValues[[sampleIndex]]}]];
    accepted = AssociationQ[fullSample] && fullSample["Status"] === "OK"];
  If[! accepted,
    Print["BENCH no accepted point prime=", primes[[sampleIndex]]]; Exit[5]];
  {futureEvaluateSeconds, futureSample} = AbsoluteTiming[
    FeynFacet`Private`familyRowGaugeFiniteFieldEvaluate[prepFuture,
      point, primes[[sampleIndex]],
      {epsilon -> epsilonValues[[sampleIndex]]}]];
  {sSiEvaluateSeconds, sSiSample} = AbsoluteTiming[
    FeynFacet`Private`familyRowGaugeFiniteFieldEvaluate[prepSSi,
      point, primes[[sampleIndex]],
      {epsilon -> epsilonValues[[sampleIndex]]}]];
  {directSeconds, directCheck} = AbsoluteTiming[
    directFormulaCheck[fullSample, point, epsilonValues[[sampleIndex]]]];
  AppendTo[samples, fullSample];
  AppendTo[sampleSummaries, <|
    "Role" -> If[sampleIndex <= 2, "Construction", "UnseenValidation"],
    "Prime" -> primes[[sampleIndex]], "Point" -> point,
    "EpsilonValue" -> epsilonValues[[sampleIndex]],
    "SplitSearchAttempts" -> attempts,
    "FullRankEvaluateSeconds" -> fullEvaluateSeconds,
    "FutureAOnlyEvaluateSeconds" -> futureEvaluateSeconds,
    "TransformationInverseOnlyEvaluateSeconds" -> sSiEvaluateSeconds,
    "FullRankBranches" -> fullSample["BranchMasks"],
    "FullHadamardRoundTrip" -> fullSample["HadamardRoundTrip"],
    "FutureHadamardRoundTrip" -> futureSample["HadamardRoundTrip"],
    "TransformationInverseHadamardRoundTrip" ->
      sSiSample["HadamardRoundTrip"],
    "FutureARecordsMatchFull" ->
      futureSample["Records", "Connection"] ===
        Select[fullSample["Records", "Connection"],
          #1["Target"][[2]] > stop &],
    "TransformationInverseRecordsMatchFull" ->
      sSiSample["Records"] === <|"Connection" -> {},
        "Transformation" -> fullSample["Records", "Transformation"],
        "Inverse" -> fullSample["Records", "Inverse"]|>,
    "IndependentDirectSeconds" -> directSeconds,
    "IndependentDirectCheck" -> directCheck,
    "SampleFingerprint" -> fullSample["SampleFingerprint"]|>];
  Print["BENCH sample ", sampleIndex, " prime=", primes[[sampleIndex]],
    " point=", point, " full=", N[fullEvaluateSeconds],
    " future=", N[futureEvaluateSeconds], " S/Si=", N[sSiEvaluateSeconds],
    " direct=", N[directSeconds],
    " exact=", directCheck["AllBranchesExact"]],
  {sampleIndex, sampleCount}];

(* Real-fixture corruption must fail before arithmetic. *)
firstRecord = First[prepFull["Records", "Connection"]];
firstTerm = First[firstRecord["Terms"]];
badTerm = Join[firstTerm,
  <|"Expression" -> firstTerm["Expression"] + 1|>];
badRecord = Join[firstRecord,
  <|"Terms" -> ReplacePart[firstRecord["Terms"], 1 -> badTerm]|>];
badRecords = Join[prepFull["Records"],
  <|"Connection" -> ReplacePart[prepFull["Records", "Connection"],
    1 -> badRecord]|>];
badPreparation = Join[prepFull, <|"Records" -> badRecords|>];
corruptionStatus = FeynFacet`Private`familyRowGaugeFiniteFieldEvaluate[
  badPreparation, sampleSummaries[[1, "Point"]], primes[[1]],
  {epsilon -> epsilonValues[[1]]}]["Status"];

allIndependentExact = And @@ Lookup[
  Lookup[sampleSummaries, "IndependentDirectCheck"],
  "AllBranchesExact"];
allRoundTrips = And @@ Flatten[Lookup[sampleSummaries,
  {"FullHadamardRoundTrip", "FutureHadamardRoundTrip",
   "TransformationInverseHadamardRoundTrip"}]];
allTargetRecordsMatch = And @@ Flatten[Lookup[sampleSummaries,
  {"FutureARecordsMatchFull", "TransformationInverseRecordsMatchFull"}]];
twoConstructionPlusUnseenQ = Lookup[sampleSummaries, "Role"] ===
  {"Construction", "Construction", "UnseenValidation"} &&
  DuplicateFreeQ[Lookup[sampleSummaries, "Prime"]];
status = If[rootOrderCanonicalQ && allIndependentExact && allRoundTrips &&
  allTargetRecordsMatch &&
  (sampleCount === 1 || twoConstructionPlusUnseenQ) &&
  corruptionStatus === "PreparationFingerprintMismatch", "OK", "Failed"];

record = <|
  "Status" -> status, "Purpose" -> If[sampleCount === 3,
    "UnhookedRealRowGaugeBenchmark", "TypedComparatorDebug"],
  "Family" -> "CF300", "Sector" -> k, "Rows" -> rows,
  "Fixture" -> <|"StateFile" -> stateFile,
    "StateSHA256" -> FileHash[stateFile, "SHA256", "HexString"],
    "CheckpointFile" -> checkpointFile,
    "CheckpointSHA256" -> FileHash[checkpointFile, "SHA256", "HexString"]|>,
  "CorrectionClassification" -> classification,
  "FullFormulaClassification" -> extendedClassification,
  "RootOrderCanonical" -> rootOrderCanonicalQ,
  "FullRootCount" -> prepFull["RootCount"],
  "FullPreparationSeconds" -> prepareFullSeconds,
  "ExactIndependentTemplateSeconds" -> exactTemplateSeconds,
  "FullStatistics" -> prepFull["Statistics"],
  "FutureAOnlyTouched" -> Length[futureConnectionRecords],
  "FutureAOnlyTermCount" -> Total[Length[#1["Terms"]] & /@
    futureConnectionRecords],
  "Samples" -> sampleSummaries,
  "AllIndependentExact" -> allIndependentExact,
  "AllHadamardRoundTrips" -> allRoundTrips,
  "AllTargetRecordsMatchFull" -> allTargetRecordsMatch,
  "TwoConstructionPlusUnseen" -> twoConstructionPlusUnseenQ,
  "CorruptionStatus" -> corruptionStatus,
  "MemoryBytes" -> <|"BeforeLoad" -> memory0,
    "BeforePrepare" -> memoryBeforePrepare,
    "AfterFullPrepare" -> memoryAfterFullPrepare,
    "MaxMemoryUsed" -> MaxMemoryUsed[]|>,
  "ProductionDecision" -> <|
    "HookNow" -> False,
    "Reason" -> "The finite-field evaluator is certified on the 36 explicit future targets, but at about 34 seconds per modular sample it is not yet a production speedup and interpolation/CRT/rational reconstruction is absent.  The exact deferred-sum path is the current optimization candidate and still requires its real sector-12 consumption gate.",
    "EligibleScope" -> "The 36 future-row connection targets after installing the materialized current dlog row.  Transformation and inverse are already exact single-term paths and need no finite-field work."|>|>;
FeynFacet`FamilyArtifactWrite[record, resultFile];
Print["BENCH RESULT ", KeyTake[record,
  {"Status", "RootOrderCanonical", "AllIndependentExact",
   "AllHadamardRoundTrips", "AllTargetRecordsMatchFull",
   "CorruptionStatus", "FullRootCount",
   "FutureAOnlyTouched"}], " written=", resultFile];
Clear[state, checkpoint, gauge, payload, extendedPayload, prepFull, prepFuture,
  prepSSi,
  samples, baseATemplate, aRightTemplate, aLowerTemplate, baseSTemplate,
  sLeftTemplate, baseSiTemplate, siRightTemplate, gaugeTemplate,
  dGaugeTemplate];
Exit[If[status === "OK", 0, 1]];
