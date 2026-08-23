#!/usr/bin/env wolframscript

(* External A3 frozen-fixture prototype.  No package files are modified. *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
bundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_round2_2026-08-21"}];
priorBundle = FileNameJoin[{root, "External", "CodexExchange",
  "codex_ff_m1_m2_2026-08-20"}];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
m1Prototype = FileNameJoin[{priorBundle,
  "CodexM1ConstrainedAffinePrototype.wl"}];
a2Prototype = FileNameJoin[{bundle,
  "CodexA2IncrementalRegulatorPrototype.wl"}];
a3Prototype = FileNameJoin[{bundle,
  "CodexA3SparseNewtonPrototype.wl"}];
primes = {1000003, 2147483423, 2147483477, 2147483489,
  2147483497, 2147483543, 2147483549};
unseenPrime = 2147483563;
epsilonValue = 1/11;
degreeOffset = {1, 0};

fixtures = {
  <|"Name" -> "CF254_9_6",
    "Record" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "fixtures",
      "fixture_CF254_9_6.wl"}],
    "Oracle" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
      "m1_run", "result_M1_CF254_9_6_FiniteField.wl"}],
    "System" -> FileNameJoin[{bundle,
      "a3_system_CF254_9_6_p1000003.wl"}]|>,
  <|"Name" -> "CF254_9_7",
    "Record" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
      "fixture_CF254_9_7.wl"}],
    "Oracle" -> FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
      "UU_08_10_canonical", "BenchmarkStripBackends", "frozen_M0",
      "result_fixture_CF254_9_7_FiniteField.wl"}],
    "System" -> FileNameJoin[{priorBundle,
      "m1_later_system_cache.wl"}]|>
};

Get[loadFile];
Get[m1Prototype];
Get[a2Prototype];
Get[a3Prototype];

ClearAll[codexA3PutAtomic];
codexA3PutAtomic[expression_, file_String] := Module[
  {temporary = file <> ".tmp"},
  Put[expression, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

ClearAll[codexA3Support];
codexA3Support[polynomial_, variables_List] := Module[{rules},
  rules = CoefficientRules[Expand[polynomial], variables];
  If[rules === {}, {}, Sort[rules[[All, 1]]]]
];

results = Table[
  name = fixture["Name"];
  Print["A3 frozen sparse-Newton run: ", name, "."];
  record = Get[fixture["Record"]];
  oracleRun = Get[fixture["Oracle"]];
  oracle = Lookup[oracleRun, "BackendResult", oracleRun];
  preparation = PrepareEpsFormStripSampling[record];
  If[! AssociationQ[preparation],
    Print["FAILED preparation for ", name]; Exit[2]];
  supportPlan = CodexA3PoleBoundPlan[
    record, preparation, degreeOffset];
  If[! AssociationQ[supportPlan],
    Print["FAILED support plan for ", name]; Exit[3]];
  closureValues = Values[KeySelect[
    supportPlan["ClosureCertificate"], StringEndsQ[#, "Q"] &]];
  If[! And @@ closureValues,
    Print["FAILED closure certificate for ", name, ": ",
      InputForm[supportPlan["ClosureCertificate"]]]; Exit[4]];
  sparseSupport = supportPlan["SparseSupport"];
  rectangularSupport = supportPlan["RectangularSupport"];
  dimensions = preparation["Dimensions"];
  entryCount = Times @@ dimensions;
  equationCount = 2 entryCount;
  freeResidueCount = Length[preparation["FreeResidues"]];
  fullGaugeCount = entryCount Length[rectangularSupport];
  sparseGaugeCount = entryCount Length[sparseSupport];
  fullUnknownCount = fullGaugeCount + freeResidueCount;
  sparseUnknownCount = sparseGaugeCount + freeResidueCount;
  fullPointCount = Max[16,
    Ceiling[(fullUnknownCount + equationCount)/equationCount]];
  sparsePointCount = Max[16,
    Ceiling[(sparseUnknownCount + equationCount)/equationCount]];
  keepColumns = CodexA3KeepColumns[dimensions,
    rectangularSupport, sparseSupport, freeResidueCount];
  If[! ListQ[keepColumns],
    Print["FAILED column map for ", name]; Exit[5]];

  If[name === "CF254_9_6" && ! FileExistsQ[fixture["System"]],
    Print["  capturing one full p=1000003 sampled system."];
    {systemBuildWallSeconds, system} = AbsoluteTiming[
      CodexM1BuildSampleSystem[
        record, epsilonValue, First[primes],
        "NumeratorDegreeOffset" -> degreeOffset,
        "CaptureMinimumDimension" -> 500]];
    If[! AssociationQ[system] || ! KeyExistsQ[system, "Matrix"],
      Print["FAILED full-system capture for ", name]; Exit[6]];
    system = Join[system,
      <|"A3CaptureWallSeconds" -> systemBuildWallSeconds|>];
    codexA3PutAtomic[system, fixture["System"]],
    system = Get[fixture["System"]]
  ];
  If[! AssociationQ[system] || system["Prime"] =!= First[primes] ||
      Dimensions[system["Matrix"]][[2]] =!= fullUnknownCount,
    Print["FAILED incompatible sampled system for ", name]; Exit[7]];

  reduced = CodexA3ReduceSystem[
    system, keepColumns, sparsePointCount, equationCount];
  If[! AssociationQ[reduced],
    Print["FAILED reduced system for ", name]; Exit[8]];
  nullity = Length[oracle["NormalizationColumns"]];
  localNormalizationColumns =
    oracle["NormalizationColumns"] - fullGaugeCount;
  newNormalizationColumns =
    sparseGaugeCount + localNormalizationColumns;
  rank = sparseUnknownCount - nullity;
  selector = SparseArray[
    MapIndexed[{First[#2], #1} -> 1 &, newNormalizationColumns],
    {nullity, sparseUnknownCount}];
  core = Join[reduced["Matrix"][[Range[rank]]], selector];
  rhsMatrix = Join[
    Join[List /@ reduced["RightHandSide"][[Range[rank]]],
      ConstantArray[0, {rank, nullity}], 2],
    Join[ConstantArray[0, {nullity, 1}],
      IdentityMatrix[nullity], 2]];
  {solveWallSeconds, solutionMatrix} = AbsoluteTiming[
    Quiet[Check[LinearSolve[core, rhsMatrix,
      Modulus -> First[primes]], $Failed]]];
  If[! MatrixQ[solutionMatrix, IntegerQ] ||
      Dimensions[solutionMatrix] =!=
        {sparseUnknownCount, nullity + 1},
    Print["FAILED reduced constrained solve for ", name]; Exit[9]];
  particular = solutionMatrix[[All, 1]];
  nullspace = Transpose[solutionMatrix[[All, 2 ;;]]];
  allRowParticularCheck = AllTrue[
    Mod[reduced["Matrix"].particular - reduced["RightHandSide"],
      First[primes]], # === 0 &];
  allRowNullspaceCheck = AllTrue[
    Flatten[Mod[reduced["Matrix"].Transpose[nullspace],
      First[primes]]], # === 0 &];
  normalizationCheck =
    particular[[newNormalizationColumns]] ===
      ConstantArray[0, nullity] &&
    nullspace[[All, newNormalizationColumns]] ===
      IdentityMatrix[nullity];
  oracleVector = CodexA3OracleVector[
    record, oracle, sparseSupport, epsilonValue, First[primes]];
  modularOracleSameQ = SameQ[particular, oracleVector];
  If[! TrueQ[allRowParticularCheck && allRowNullspaceCheck &&
      normalizationCheck && modularOracleSameQ],
    Print["FAILED modular oracle regression for ", name]; Exit[10]];

  oracleNumerators = Expand /@ Flatten[
    Map[Cancel[Together[# oracle["GaugeDenominator"]]] &,
      oracle["Gauge"], {2}]];
  oracleSupportUnion = Sort[Union @@
    (codexA3Support[#, record["Variables"]] & /@ oracleNumerators)];
  oracleSupportRegressionSameQ = SameQ[
    sparseSupport, oracleSupportUnion];

  modularData = Table[
    data = Get[FileNameJoin[{bundle, "a2_real_" <> name,
      "a2_mod_" <> ToString[prime] <> ".wl"}]];
    Join[data, <|
      "Interpolations" -> data["Interpolations"][[keepColumns]],
      "GaugeUnknownCount" -> sparseGaugeCount,
      "FreeResidueCount" -> freeResidueCount,
      "NormalizationColumns" -> newNormalizationColumns
    |>],
    {prime, primes}];
  {liftWallSeconds, candidate} = AbsoluteTiming[
    CodexA3SparseLiftCandidate[record, modularData, sparseSupport]];
  If[! AssociationQ[candidate],
    Print["FAILED sparse lift for ", name]; Exit[11]];
  unseenCheck = CodexA2UnseenPrimeResidualCheck[
    record, candidate, unseenPrime];
  If[! AssociationQ[unseenCheck] ||
      ! TrueQ[unseenCheck["AllResidualsZero"]],
    Print["FAILED unseen-prime sparse residual for ", name]; Exit[12]];
  {exactCheckWallSeconds, verification} = AbsoluteTiming[
    VerifyEpsFormStrip[record, candidate, "KernelCount" -> 4]];
  If[! AssociationQ[verification] ||
      ! TrueQ[verification["ExactPfaffianResidualsZero"]],
    Print["FAILED exact sparse residual for ", name]; Exit[13]];
  exactOracleAgreement = <|
    "GaugeSameQ" -> SameQ[candidate["Gauge"], oracle["Gauge"]],
    "AlphabetSameQ" -> SameQ[
      candidate["Alphabet"], oracle["Alphabet"]],
    "ResidueMatricesSameQ" -> SameQ[
      candidate["ResidueMatrices"], oracle["ResidueMatrices"]]
  |>;
  exactOracleAgreement = Join[exactOracleAgreement,
    <|"AllSameQ" -> And @@ Values[exactOracleAgreement]|>];
  If[! TrueQ[exactOracleAgreement["AllSameQ"]],
    Print["FAILED exact sparse oracle SameQ for ", name]; Exit[14]];

  result = <|
    "Status" -> "Solved",
    "Scope" -> "ExternalA3NoPackageEdits",
    "Fixture" -> name,
    "DegreeOffset" -> degreeOffset,
    "PoleBoundPlan" -> KeyDrop[supportPlan,
      {"GaugeDenominator", "RectangularSupport", "SparseSupport"}],
    "SparseSupport" -> sparseSupport,
    "OracleSupportUsedAsInput" -> False,
    "OracleSupportRegressionSameQ" -> oracleSupportRegressionSameQ,
    "FullUnknownCount" -> fullUnknownCount,
    "SparseUnknownCount" -> sparseUnknownCount,
    "FullPointCount" -> fullPointCount,
    "SparsePointCount" -> sparsePointCount,
    "ReducedMatrixDimensions" -> Dimensions[reduced["Matrix"]],
    "ReducedCoreDimensions" -> Dimensions[core],
    "ReducedRank" -> rank,
    "Nullity" -> nullity,
    "ReducedSolveWallSeconds" -> solveWallSeconds,
    "AllReducedRowsParticularCheckZero" -> allRowParticularCheck,
    "AllReducedRowsNullspaceCheckZero" -> allRowNullspaceCheck,
    "NormalizationCheck" -> normalizationCheck,
    "ModularParticularOracleSameQ" -> modularOracleSameQ,
    "SparseLiftWallSeconds" -> liftWallSeconds,
    "UnseenPrimeResidual" -> unseenCheck,
    "ExactCheckWallSeconds" -> exactCheckWallSeconds,
    "ExactPfaffianResidualsZero" ->
      verification["ExactPfaffianResidualsZero"],
    "ExactOracleAgreement" -> exactOracleAgreement
  |>;
  outputFile = FileNameJoin[{bundle,
    "a3_sparse_newton_result_" <> name <> ".wl"}];
  codexA3PutAtomic[result, outputFile];
  Print[InputForm[KeyDrop[result,
    {"SparseSupport", "UnseenPrimeResidual"}]]];
  result,
  {fixture, fixtures}];

summary = KeyTake[#, {"Fixture", "FullUnknownCount",
  "SparseUnknownCount", "FullPointCount", "SparsePointCount",
  "ReducedSolveWallSeconds", "ExactPfaffianResidualsZero",
  "ExactOracleAgreement"}] & /@ results;
codexA3PutAtomic[summary,
  FileNameJoin[{bundle, "a3_sparse_newton_summary.wl"}]];
Print["A3 summary: ", InputForm[summary]];

