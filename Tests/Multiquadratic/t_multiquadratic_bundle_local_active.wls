#!/usr/bin/env wolframscript
(* Deferred-bundle SplitBranch local-active-subfield regression. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{deferredPrepare, compileBundle, validateBundle, fingerprintBundle,
  frameCanonicalize, directProvider, providerChannels, modRational,
  projectConjugates, providerFingerprint} = mq /@ {
  "blockEquationDeferredPrepare", "blockEquationDeferredCompileBundle",
  "blockEquationDeferredBundleValidate",
  "blockEquationDeferredBundleFingerprint",
  "blockEquationDeferredFrameCanonicalize",
  "multiquadraticStripDirectProvider",
  "multiquadraticStripProviderChannels",
  "multiquadraticStripModRational", "multiquadraticProjectConjugates",
  "multiquadraticStripFingerprint"};
applyBranches = mq["transportChartApplyRootBranches"];

Clear[lx, ly, le];
rootSquares = {1 + lx, 1 + ly, 2 + lx + 2 ly};
declaredRoots = <|"Root" -> Sqrt[#], "RootSquare" -> #|> & /@ rootSquares;
ranges = {{1}, {2}};
baseConnection = {{{0, 0}, {1/(5 + lx), 0}},
  {{0, 0}, {0, 0}}};

activeIndices[mask_, rank_] := Select[Range[rank],
  BitGet[mask, # - 1] === 1 &];

buildMixedBundle[rank_Integer] := Module[
  {preparation, base, frame, roots, squares, rawGrades, grades, operands,
   jobs, bundle},
  preparation = deferredPrepare[baseConnection, ranges, 2, 1, <||>,
    {lx, ly}, le];
  base = compileBundle[preparation,
    "Roots" -> Take[declaredRoots, rank],
    "PruneUnusedRoots" -> False];
  If[Lookup[base, "Status", None] =!= "PreparedDeferredBundle",
    Return[base]];
  frame = base["RootFrame"];
  roots = frame["Roots"];
  squares = Lookup[roots, "RootSquare", {}];
  (* Pair/triple grades start as genuine composite radicals.  The same
     canonicalizer used by bundle construction fixes their declared branch. *)
  rawGrades = Table[If[mask === 0, 1,
      Sqrt[Expand[Times @@ squares[[activeIndices[mask, rank]]]]]],
    {mask, 0, 2^rank - 1}];
  grades = Table[If[mask === 0, 1,
      frameCanonicalize[rawGrades[[mask + 1]], frame,
        {lx, ly}]["Expression"]],
    {mask, 0, 2^rank - 1}];
  operands = Table[Module[{pairs = {{7 + lx + mask, 1}},
      numerator = (mask + 2) grades[[mask + 1]]},
      <|"ID" -> mask + 1, "Numerator" -> numerator,
        "DenominatorFactors" -> pairs, "RootMask" -> mask,
        "Fingerprint" -> Hash[{numerator, pairs}, "SHA256",
          "HexString"]|>],
    {mask, 0, 2^rank - 1}];
  jobs = MapIndexed[<|"Target" -> #1,
      "Terms" -> If[First[#2] === 1,
        Table[{rawGrades[[mask + 1]], {mask + 1}},
          {mask, 0, 2^rank - 1}], {}]|> &,
    base["TargetOrder"]];
  bundle = Join[base, <|"OperandTable" -> operands, "Jobs" -> jobs,
    "DivisorOccurrences" -> {}|>];
  Append[bundle, "BundleFingerprint" -> fingerprintBundle[bundle]]
];

buildProvider[bundle_Association, kind_String] := Module[
  {roots = bundle["RootFrame"]["Roots"], dimensions, zeroE, zeroC,
   zeroB, record},
  dimensions = Rest[bundle["Dimensions"]];
  zeroE = ConstantArray[0, {2, dimensions[[1]], dimensions[[1]]}];
  zeroC = ConstantArray[0, {2, dimensions[[2]], dimensions[[2]]}];
  zeroB = ConstantArray[0, bundle["Dimensions"]];
  record = <|"Variables" -> {lx, ly}, "Regulator" -> le,
    "Strip" -> {zeroE, zeroC, zeroB}, "DeferredBundle" -> bundle|>;
  directProvider[record, roots, "Kind" -> kind, "OneForms" -> {},
    "GaugeDenominator" -> 1, "DeferredBundle" -> bundle,
    "SourceFingerprint" -> "bundle-local-active-fixture"]
];

prime = 2147483423; epsilonValue = 5;
splitPoint[roots_List] := SelectFirst[
  Flatten[Table[{xValue, yValue}, {xValue, 2, 40},
    {yValue, 2, 40}], 1],
  Function[point, Module[{values = Table[modRational[
        roots[[k, "RootSquare"]] /. Thread[{lx, ly} -> point], prime],
      {k, Length[roots]}]},
    values =!= $Failed && ! MemberQ[values, 0] &&
      AllTrue[values, JacobiSymbol[#, prime] === 1 &]]],
  Missing["NoSplitPoint"]];

globalSheetOracle[provider_Association, point_List] := Module[
  {bundle = provider["DeferredBundle"], roots = provider["Roots"],
   rank = provider["RootCount"], gradeCount = provider["GradeCount"],
   expressions = provider["BundleOperandExpressions"],
   coefficients = provider["BundleCoefficientExpressions"], rules,
   rootValues, branchImages, signs, operandValues, jobValues, channels},
  rules = {lx -> point[[1]], ly -> point[[2]], le -> epsilonValue};
  rootValues = mq["multiquadraticSquareRoots"][
    modRational[# /. rules, prime] & /@
      Lookup[roots, "RootSquare", {}], prime];
  branchImages = Table[
    signs = Table[If[BitGet[mask, k - 1] === 1, -1, 1],
      {k, rank}];
    operandValues = Table[modRational[
        applyBranches[expressions[[id]], roots,
          Mod[signs rootValues, prime]] /. rules, prime],
      {id, Length[expressions]}];
    jobValues = Table[Mod[Total[Table[
        modRational[applyBranches[
            coefficients[[jobIndex, termIndex]], roots,
            Mod[signs rootValues, prime]] /. rules, prime]
          Times @@ operandValues[[Last[
            bundle["Jobs"][[jobIndex, "Terms", termIndex]]]]],
        {termIndex, Length[bundle["Jobs"][[jobIndex, "Terms"]]]}]],
      prime], {jobIndex, Length[bundle["Jobs"]]}];
    jobValues,
    {mask, 0, gradeCount - 1}];
  channels = Table[projectConjugates[branchImages[[All, target]],
      rootValues, prime], {target, Length[bundle["Jobs"]]}];
  ArrayReshape[Mod[channels, prime],
    Append[bundle["Dimensions"], gradeCount]]
];

results = Association@Table[Module[
    {bundle, provider, quotient, point, image, oracleTiming, oracle,
     quotientImage, expectedScalarCount, expectedMasks, gradeCount},
    bundle = buildMixedBundle[rank];
    check["rank " <> ToString[rank] <> " mixed bundle validates",
      Lookup[validateBundle[bundle], "Status", None] === "BundleValid"];
    provider = buildProvider[bundle, "SplitBranch"];
    quotient = buildProvider[bundle, "QuotientGrade"];
    gradeCount = provider["GradeCount"];
    point = splitPoint[provider["Roots"]];
    image = providerChannels[provider, epsilonValue, prime, point];
    quotientImage = providerChannels[quotient, epsilonValue, prime, point];
    {oracleTiming, oracle} = AbsoluteTiming[
      globalSheetOracle[provider, point]];
    expectedMasks = Range[0, 2^rank - 1];
    expectedScalarCount = 2 Total[
      2^Length[activeIndices[#, rank]] & /@ expectedMasks];
    check["rank " <> ToString[rank] <>
        " local SplitBranch equals the global-sheet oracle exactly",
      Lookup[image, "Status", None] ===
          "MultiquadraticPointCoefficientsV1" &&
        image["BBar"] === oracle];
    check["rank " <> ToString[rank] <>
        " operand and coefficient masks are derived once and aligned",
      provider["BundleOperandRootMasks"] === expectedMasks &&
        First[provider["BundleCoefficientRootMasks"]] === expectedMasks &&
        provider["BundleOperandActiveRoots"] ===
          (activeIndices[#, rank] & /@ expectedMasks) &&
        First[provider["BundleCoefficientActiveRoots"]] ===
          (activeIndices[#, rank] & /@ expectedMasks)];
    check["rank " <> ToString[rank] <>
        " telemetry counts actual local scalar branch evaluations",
      image["BundleScalarBranchEvaluationCount"] === expectedScalarCount &&
        image["BundleGlobalSheetScalarBranchEvaluationCount"] ===
          2 gradeCount^2 &&
        image["BundleScalarBranchEvaluationReduction"] ===
          2 gradeCount^2 - expectedScalarCount];
    check["rank " <> ToString[rank] <>
        " QuotientGrade ABI and provider seals are unchanged",
      Lookup[quotientImage, "Status", None] ===
          "MultiquadraticPointCoefficientsV1" &&
        quotientImage["BBar"] === image["BBar"] &&
        quotient["CoefficientABIFingerprint"] ===
          provider["CoefficientABIFingerprint"] &&
        provider["ProviderFingerprint"] === providerFingerprint[{
          "SplitBranch", provider["CoefficientABIFingerprint"],
          provider["SourceFingerprint"], bundle["BundleFingerprint"]}]];
    rank -> <|"Bundle" -> bundle, "Provider" -> provider,
      "Image" -> image, "OracleSeconds" -> oracleTiming|>
  ], {rank, 0, 3}];

(* Production compilation keeps only generators that occur in an operand or
   term coefficient.  The synthetic mixed-mask constructor above opts out
   because it deliberately injects new operands after compilation. *)
prunePreparation = deferredPrepare[baseConnection, ranges, 2, 1, <||>,
  {lx, ly}, le];
prunedRational = compileBundle[prunePreparation, "Roots" -> declaredRoots];
check["an unused declared root frame is pruned completely",
  Lookup[validateBundle[prunedRational], "Status", None] === "BundleValid" &&
    prunedRational["RootFrame"]["Roots"] === {} &&
    prunedRational["Statistics"]["PrunedRootCount"] === 3];
partialConnection = {{{0, 0},
    {Sqrt[rootSquares[[1]]] + Sqrt[rootSquares[[3]]], 0}},
  {{0, 0}, {0, 0}}};
partialPreparation = deferredPrepare[partialConnection, ranges, 2, 1, <||>,
  {lx, ly}, le];
prunedPartial = compileBundle[partialPreparation, "Roots" -> declaredRoots];
partialSquares = Together /@
  Lookup[prunedPartial["RootFrame"]["Roots"], "RootSquare", {}];
check["a strict active root subset is retained in canonical order",
  Lookup[validateBundle[prunedPartial], "Status", None] === "BundleValid" &&
    Length[partialSquares] === 2 &&
    ContainsAll[partialSquares, Together /@ rootSquares[[{1, 3}]]] &&
    ContainsAll[Together /@ rootSquares[[{1, 3}]], partialSquares] &&
    prunedPartial["Statistics"]["PrunedRootCount"] === 1];

rank3 = results[3];
check["rank 3 exercises root-free, single, pair, and triple masks",
  Counts[Length /@ rank3["Provider"]["BundleOperandActiveRoots"]] ===
    <|0 -> 1, 1 -> 3, 2 -> 3, 3 -> 1|>];
check["rank 3 mixed masks strictly reduce scalar branch evaluations",
  rank3["Image"]["BundleScalarBranchEvaluationCount"] <
    rank3["Image"]["BundleGlobalSheetScalarBranchEvaluationCount"] &&
    rank3["Image"]["BundleScalarBranchEvaluationCount"] === 54 &&
    rank3["Image"]["BundleGlobalSheetScalarBranchEvaluationCount"] === 128];
check["rank 3 reports both local and global-oracle wall timings",
  NumericQ[rank3["Image"]["BundleEvaluationSeconds"]] &&
    rank3["Image"]["BundleEvaluationSeconds"] >= 0 &&
    NumericQ[rank3["OracleSeconds"]] && rank3["OracleSeconds"] >= 0];
Print["RANK3_BENCH old_global_scalar_branches=",
  rank3["Image"]["BundleGlobalSheetScalarBranchEvaluationCount"],
  " new_local_scalar_branches=",
  rank3["Image"]["BundleScalarBranchEvaluationCount"],
  " old_global_seconds=", N[rank3["OracleSeconds"], 6],
  " new_local_seconds=",
  N[rank3["Image"]["BundleEvaluationSeconds"], 6]];

(* A larger evaluator benchmark: 64 distinct, nontrivial rational operands,
   weighted toward the root-free and rank-one masks seen in real intern
   tables.  Timing is reported, never used as a flaky pass/fail condition. *)
largerMasks = Join[ConstantArray[0, 32], ConstantArray[1, 12],
  ConstantArray[2, 8], ConstantArray[3, 8], ConstantArray[7, 4]];
largerBase = rank3["Bundle"];
largerGrades = Table[
  largerBase["OperandTable"][[mask + 1, "Numerator"]]/(mask + 2),
  {mask, 0, 7}];
largerOperands = MapIndexed[Module[
    {id = First[#2], mask = #1, pairs, numerator, polynomial},
    pairs = {{13 + lx + id, 1}};
    polynomial = Expand[(id + 2 + lx + 2 ly)^6 +
      (3 + Mod[id, 7]) (1 + lx ly)^4];
    numerator = polynomial largerGrades[[mask + 1]];
    <|"ID" -> id, "Numerator" -> numerator,
      "DenominatorFactors" -> pairs, "RootMask" -> mask,
      "Fingerprint" -> Hash[{numerator, pairs}, "SHA256",
        "HexString"]|>] &, largerMasks];
largerJobs = MapIndexed[<|"Target" -> #1,
    "Terms" -> If[First[#2] === 1,
      MapIndexed[{1 + Mod[First[#2], 5] lx, {First[#2]}} &,
        largerMasks], {}]|> &, largerBase["TargetOrder"]];
largerBundle = Join[largerBase, <|"OperandTable" -> largerOperands,
  "Jobs" -> largerJobs, "DivisorOccurrences" -> {}|>];
largerBundle = Append[largerBundle,
  "BundleFingerprint" -> fingerprintBundle[largerBundle]];
largerProvider = buildProvider[largerBundle, "SplitBranch"];
largerPoint = splitPoint[largerProvider["Roots"]];
largerImages = Table[providerChannels[largerProvider, epsilonValue, prime,
    largerPoint], {3}];
largerOldTimings = Table[First[AbsoluteTiming[
    largerOracle = globalSheetOracle[largerProvider, largerPoint]]], {3}];
largerNewTimings = Lookup[largerImages, "BundleEvaluationSeconds"];
check["larger mixed-mask bundle validates and equals the global oracle",
  Lookup[validateBundle[largerBundle], "Status", None] === "BundleValid" &&
    AllTrue[largerImages, Lookup[#, "Status", None] ===
        "MultiquadraticPointCoefficientsV1" &&
      #["BBar"] === largerOracle &]];
check["larger mixed-mask branch telemetry records the exact reduction",
  AllTrue[largerImages,
    #["BundleGlobalSheetScalarBranchEvaluationCount"] === 1024 &&
      #["BundleScalarBranchEvaluationCount"] === 200 &]];
Print["LARGER_RANK3_BENCH operands=", Length[largerOperands],
  " old_global_scalar_branches=1024 new_local_scalar_branches=200",
  " old_global_median_seconds=", N[Median[largerOldTimings], 6],
  " new_local_median_seconds=", N[Median[largerNewTimings], 6],
  " wall_speedup=", N[Median[largerOldTimings]/Median[largerNewTimings], 5]];

tampered = ReplacePart[rank3["Bundle"],
  {Key["OperandTable"], 1, Key["RootMask"]} -> 1];
tampered = Append[tampered,
  "BundleFingerprint" -> fingerprintBundle[tampered]];
check["a refingerprinted tampered operand RootMask is recomputed and refused",
  Lookup[validateBundle[tampered], "Status", None] ===
    "OperandRootMaskMismatch"];
check["a direct provider fails closed on the tampered RootMask",
  Lookup[buildProvider[tampered, "SplitBranch"], "Status", None] ===
    "InvalidDeferredBundle"];

Print["t_multiquadratic_bundle_local_active: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
