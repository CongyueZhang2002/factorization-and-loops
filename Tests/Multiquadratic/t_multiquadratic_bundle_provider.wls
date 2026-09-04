#!/usr/bin/env wolframscript
(* Round-B deferred-DAG provider acceptance. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{forcingOf, prepare, layoutBuilder, directProvider, channels, pointRows,
  assembleSample, providerPreflight, splitPlanBuilder, splitPlanValidQ,
  splitEntry, screenCompile, clearCaches, validateBundle,
  presentationRoots, generatorExpression} = mq /@ {
    "blockEquationDeferredForcing",
    "multiquadraticStripPrepare", "multiquadraticStripAssemblyLayout",
    "multiquadraticStripDirectProvider",
    "multiquadraticStripProviderChannels",
    "multiquadraticStripAssemblePointRows",
    "multiquadraticStripAssembleSample",
    "multiquadraticStripProviderPreflight",
    "multiquadraticStripSplitSparseEvaluationPlan",
    "multiquadraticStripSplitSparseEvaluationPlanValidQ",
    "multiquadraticStripSplitBranchEntry",
    "multiquadraticStripScreenCompileScalar",
    "multiquadraticStripClearCaches",
    "blockEquationDeferredBundleValidate",
    "coefficientPresentationSquareRootsInVariables",
    "squareRootRecordExpression"};
topSolve = mq["solveEpsFormStripMultiquadratic"];

Clear[dx, dy, de, dsx, dsy, dcx, dcy];
ranges = {{1}, {2}, {3, 4}};
blockOf[i_] := First[Select[Range[Length[ranges]],
  MemberQ[ranges[[#1]], i] &]];
delta = 1 + dx;
coefficientPresentation = BuildSquareRootGeneratorsAndQuadraticRelations[
  {1 + dsx}, {dsx, dsy}, {dcx, dcy}];
rootRecord = First[presentationRoots[coefficientPresentation, {dx, dy}]];
bundleRootRecord = Join[rootRecord, <|"SourceRadicand" -> delta|>];
entry[mu_, i_, j_] := (de + mu + i dx + j dy)/
  ((2 + dx + Sqrt[delta])^If[mu === 1, 2, 1] (i + j));
connection = Table[Table[If[blockOf[i] < blockOf[j], 0,
    entry[mu, i, j]], {i, 4}, {j, 4}], {mu, 2}];
solved = <|2 -> {{(1 + dx)/(1 - dy)}, {dy/(1 + dx)}}|>;
compat = forcingOf[connection, ranges, 3, 1, solved, {dx, dy}, de,
  "DivisorRoots" -> {bundleRootRecord}];
bundle = Lookup[compat, "DeferredBundle", <||>];

check["bundle provider fixture is validated",
  Lookup[compat, "Status", None] === "OK" &&
    Lookup[validateBundle[bundle], "Status", None] === "BundleValid"];

dimensions = Rest[bundle["Dimensions"]];
e = Table[Sqrt[delta] IdentityMatrix[dimensions[[1]]], {2}];
c = Table[ConstantArray[0, {dimensions[[2]], dimensions[[2]]}], {2}];
zeroForcing = ConstantArray[0, bundle["Dimensions"]];
bundleRecord = <|"Family" -> "BUNDLE_PROVIDER", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {dx, dy}, "Regulator" -> de,
  "Strip" -> {e, c, zeroForcing}, "DeferredBundle" -> bundle|>;
prepared = prepare[bundleRecord, coefficientPresentation, "RootIndices" -> {1},
  "OneForms" -> {}, "GaugeDenominator" -> Automatic,
  "Support" -> {{0, 0}}, "CoefficientProvider" -> "SplitBranch"];
layout = layoutBuilder[prepared];
bundleSplit = directProvider[prepared["Record"], prepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "DeferredBundle" -> bundle];
bundleQuotient = directProvider[prepared["Record"], prepared["Roots"],
  "Kind" -> "QuotientGrade", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "DeferredBundle" -> bundle];
oracleRecord = Join[bundleRecord, <|"Strip" -> {e, c, compat["Forcing"]}|>];
oracle = directProvider[oracleRecord, prepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "DeferredBundle" -> None];

check["bundle divisor summary supplies the automatic rational denominator",
  Lookup[prepared, "Status", None] === "PreparedMultiquadraticStripV1" &&
    AssociationQ[prepared["BundleDivisorProvenance"]] &&
    bundle["SchemaVersion"] === 3 &&
    AssociationQ[bundle["CoefficientPresentation"]] &&
    bundle["SquareRootGeneratorIndices"] === {1} &&
    prepared["CoefficientPresentation"] === coefficientPresentation &&
    FreeQ[prepared["GaugeDenominator"], Power[_, _Rational]]];

prime = 2147483423; epsilonValue = 5; point = {3, 7};
bundleSplitImage = channels[bundleSplit, epsilonValue, prime, point];
bundleQuotientImage = channels[bundleQuotient, epsilonValue, prime, point];
oracleImage = channels[oracle, epsilonValue, prime, point];

clearCaches[];
splitPlan = splitPlanBuilder[bundleSplit, prime];
splitPreflight = providerPreflight[bundleSplit, epsilonValue, prime, point];
plannedBundleSplitImage = channels[bundleSplit, epsilonValue, prime, point,
  splitPreflight, splitPlan];
check["the split plan validates and covers every positional occurrence",
  splitPlanValidQ[splitPlan, bundleSplit, prime] &&
    ! TrueQ[splitPlan["PlanCacheHit"]] &&
    splitPlan["UniqueLeafCount"] < splitPlan["OccurrenceCount"] &&
    splitPlan["CompileInvocationCount"] === splitPlan["UniqueLeafCount"] &&
    Keys[splitPlan["OccurrenceMaps", "Entries"]] ===
      Keys[bundleSplit["Entries"]] &&
    Dimensions[splitPlan["OccurrenceMaps", "Entries", "E"]] ===
      Dimensions[bundleSplit["Entries", "E"]] &&
    Dimensions[splitPlan["OccurrenceMaps", "Entries", "C"]] ===
      Dimensions[bundleSplit["Entries", "C"]] &&
    Length[splitPlan["OccurrenceMaps", "BundleOperands"]] ===
      Length[bundleSplit["BundleOperandExpressions"]] &&
    Dimensions[splitPlan["OccurrenceMaps", "BundleCoefficients"]] ===
      Dimensions[bundleSplit["BundleCoefficientExpressions"]]];
check["planned and unplanned provider channels are exactly identical",
  Lookup[plannedBundleSplitImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    KeyTake[plannedBundleSplitImage, {"E", "C", "BBar", "OneForms"}] ===
      KeyTake[bundleSplitImage, {"E", "C", "BBar", "OneForms"}] &&
    plannedBundleSplitImage["SplitSparseCompileAttemptCount"] === 0 &&
    plannedBundleSplitImage["SplitSparseUniqueLeafCount"] ===
      splitPlan["UniqueLeafCount"] &&
    NumericQ[plannedBundleSplitImage[
      "SplitSparseUniqueLeafEvaluationSeconds"]] &&
    NumericQ[plannedBundleSplitImage[
      "SplitSparseOccurrenceGatherSeconds"]] &&
    NumericQ[plannedBundleSplitImage[
      "SplitSparseDeferredBundleCompositionSeconds"]]];

cachedSplitPlan = splitPlanBuilder[bundleSplit, prime];
check["a second fibre reuses the exact provider-prime plan without compiling",
  TrueQ[cachedSplitPlan["PlanCacheHit"]] &&
    cachedSplitPlan["CoefficientData"] === splitPlan["CoefficientData"] &&
    cachedSplitPlan["Leaves"] === splitPlan["Leaves"] &&
    cachedSplitPlan["OccurrenceMaps"] === splitPlan["OccurrenceMaps"] &&
    cachedSplitPlan["BuildCompileInvocationCount"] === 0];

samplePoints = {{3, 7}, {8, 11}, {15, 13}, {24, 17}};
unplannedSample = assembleSample[layout, bundleSplit, epsilonValue, prime,
  "PointCount" -> 4, "MaximumAttempts" -> 4,
  "CandidatePoints" -> samplePoints,
  "SplitSparseEvaluationPlan" -> None];
plannedSample = assembleSample[layout, bundleSplit, epsilonValue, prime,
  "PointCount" -> 4, "MaximumAttempts" -> 4,
  "CandidatePoints" -> samplePoints,
  "SplitSparseEvaluationPlan" -> splitPlan];
hotFibreSample = assembleSample[layout, bundleSplit, 7, prime,
  "PointCount" -> 4, "MaximumAttempts" -> 4,
  "CandidatePoints" -> samplePoints];
check["planned and unplanned complete samples have identical row data",
  Lookup[unplannedSample, "Status", None] ===
      "AssembledMultiquadraticSampleV1" &&
    Lookup[plannedSample, "Status", None] ===
      "AssembledMultiquadraticSampleV1" &&
    KeyTake[plannedSample, {"Matrix", "RightHandSide", "AcceptedPoints",
        "TrainingImageKeys", "ImageStoreKey"}] ===
      KeyTake[unplannedSample, {"Matrix", "RightHandSide", "AcceptedPoints",
        "TrainingImageKeys", "ImageStoreKey"}] &&
    plannedSample["SplitSparseCompileAttemptCount"] === 0 &&
    plannedSample["SplitSparsePlanUniqueLeafCount"] ===
      splitPlan["UniqueLeafCount"] &&
    plannedSample["SplitSparseEvaluationCount"] +
        plannedSample["SplitSubstitutionFallbackCount"] ===
      plannedSample["ProviderCallCount"] splitPlan["UniqueLeafCount"]];
check["Automatic reuses the same plan across epsilon fibres",
  Lookup[hotFibreSample, "Status", None] ===
      "AssembledMultiquadraticSampleV1" &&
    TrueQ[hotFibreSample["SplitSparsePlanCacheHit"]] &&
    hotFibreSample["SplitSparsePlanCompileInvocationCount"] === 0 &&
    hotFibreSample["CoefficientData"] === splitPlan["CoefficientData"]];

reorderedPlan = ReplacePart[splitPlan, Key["Leaves"] ->
  Reverse[splitPlan["Leaves"]]];
entryMapKey = First[Keys[splitPlan["OccurrenceMaps", "Entries"]]];
oldOccurrence = splitPlan[
  "OccurrenceMaps", "Entries", entryMapKey][[1, 1, 1]];
mutatedOccurrencePlan = ReplacePart[splitPlan,
  {Key["OccurrenceMaps"], Key["Entries"], Key[entryMapKey], 1, 1, 1} ->
    1 + Mod[oldOccurrence, splitPlan["UniqueLeafCount"]]];
otherPrime = 2147483399;
invalidPlans = {
  splitPlanValidQ[reorderedPlan, bundleSplit, prime],
  splitPlanValidQ[mutatedOccurrencePlan, bundleSplit, prime],
  splitPlanValidQ[splitPlan, oracle, prime],
  splitPlanValidQ[splitPlan, bundleSplit, otherPrime]};
check["reordered, occurrence-mutated, cross-provider and cross-prime plans fail closed",
  invalidPlans === ConstantArray[False, 4]];

poleExpression = 1/(dx - 3);
poleRules = <|dx -> 3, dy -> 7, de -> epsilonValue|>;
poleCompiled = screenCompile[poleExpression, {}, {}, {dx, dy, de}, prime];
unplannedPole = splitEntry[poleExpression, {}, {}, poleRules, {}, {}, prime];
plannedPole = splitEntry[poleExpression, {}, {}, poleRules, {}, {}, prime,
  poleCompiled];
check["a planned zero denominator preserves the exact substitution fallback",
  AssociationQ[unplannedPole] && plannedPole === unplannedPole &&
    Lookup[plannedPole, "Status", None] =!= "OK"];

check["bundle SplitBranch evaluates complete coefficients without dense BBar",
  Lookup[bundleSplitImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    bundleSplitImage["BBar"] === oracleImage["BBar"] &&
    bundleSplitImage["E"] === oracleImage["E"] &&
    bundleSplitImage["C"] === oracleImage["C"] &&
    bundleSplitImage["BBar"] =!= ConstantArray[0,
      Dimensions[bundleSplitImage["BBar"]]]];
check["bundle QuotientGrade agrees with split and materialized oracle",
  Lookup[bundleQuotientImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    KeyTake[bundleQuotientImage, {"E", "C", "BBar", "OneForms"}] ===
      KeyTake[bundleSplitImage, {"E", "C", "BBar", "OneForms"}]];
check["bundle evaluator reuses its interned operands",
  bundleSplitImage["BundleOperandEntryEvaluationCount"] ===
      Length[bundle["OperandTable"]] &&
    bundleSplitImage["BundleOperandEvaluationCount"] === Total[
      2^Length[#] & /@ bundleSplit["BundleOperandActiveRoots"]] &&
    bundleSplitImage["BundleOperandEvaluationCount"] <
      2 Length[bundle["OperandTable"]] &&
    bundleQuotientImage["BundleOperandEvaluationCount"] ===
      Length[bundle["OperandTable"]]];
check["bundle coefficients enter the one shared row assembler",
  pointRows[layout, bundleSplitImage]["Rows"] ===
    pointRows[layout, oracleImage]["Rows"] &&
  pointRows[layout, bundleSplitImage]["RightHandSide"] ===
    pointRows[layout, oracleImage]["RightHandSide"]];

mutated = ReplacePart[bundle,
  {Key["Jobs"], 1, Key["Terms"], 1, 1} -> 17];
mutantProvider = directProvider[prepared["Record"], prepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"],
  "DeferredBundle" -> mutated];
mutantImage = channels[mutantProvider, epsilonValue, prime, point];
check["changed valid bundle equations produce changed provider coefficients",
  Lookup[validateBundle[mutated], "Status", None] === "BundleValid" &&
    Lookup[mutantProvider, "Status", None] ===
      "MultiquadraticDirectProviderV1" &&
    Lookup[mutantImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    mutantImage["BBar"] =!= bundleSplitImage["BBar"]];

(* The production driver intentionally puts a zero tensor in BBar when the
   validated deferred bundle is the forcing source.  A generator used only
   by that bundle must therefore enter preparation through its coefficient
   presentation, not be
   rejected as an extraneous explicit RootIndices request. *)
zeroE = ConstantArray[0, {2, dimensions[[1]], dimensions[[1]]}];
zeroC = ConstantArray[0, {2, dimensions[[2]], dimensions[[2]]}];
forcingOnlyRecord = <|"Family" -> "BUNDLE_ROOT_CENSUS", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {dx, dy}, "Regulator" -> de,
  "Strip" -> {zeroE, zeroC, zeroForcing}, "DeferredBundle" -> bundle|>;
forcingOnlyPrepared = prepare[forcingOnlyRecord, coefficientPresentation,
  "OneForms" -> {}, "GaugeDenominator" -> Automatic,
  "Support" -> {{0, 0}}, "CoefficientProvider" -> "SplitBranch"];
forcingOnlyProvider = directProvider[forcingOnlyPrepared["Record"],
  forcingOnlyPrepared["Roots"], "Kind" -> "SplitBranch", "OneForms" -> {},
  "GaugeDenominator" -> forcingOnlyPrepared["GaugeDenominator"],
  "DeferredBundle" -> bundle];
forcingOnlyImage = channels[forcingOnlyProvider, epsilonValue, prime, point];
forcingOnlyOracleRecord = Join[forcingOnlyRecord, <|
  "Strip" -> {zeroE, zeroC, compat["Forcing"]}, "DeferredBundle" -> None|>];
forcingOnlyOracle = directProvider[forcingOnlyOracleRecord,
  forcingOnlyPrepared["Roots"], "Kind" -> "SplitBranch", "OneForms" -> {},
  "GaugeDenominator" -> forcingOnlyPrepared["GaugeDenominator"],
  "DeferredBundle" -> None];
forcingOnlyOracleImage = channels[forcingOnlyOracle, epsilonValue, prime,
  point];
bundleRoots = presentationRoots[bundle["CoefficientPresentation"],
  {dx, dy}][[bundle["SquareRootGeneratorIndices"]]];
check["prepare includes generators used only by a validated deferred forcing",
  Lookup[forcingOnlyPrepared, "Status", None] ===
      "PreparedMultiquadraticStripV1" &&
    forcingOnlyPrepared["RootCount"] === 1 &&
    forcingOnlyPrepared["RootIndices"] === {1} &&
    (generatorExpression /@ forcingOnlyPrepared["Roots"]) ===
      (generatorExpression /@ bundleRoots)];
check["the forcing-only bundle reaches the provider without materializing BBar",
  Lookup[forcingOnlyImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    forcingOnlyImage["BBar"] === forcingOnlyOracleImage["BBar"] &&
    forcingOnlyImage["BBar"] =!= ConstantArray[0,
      Dimensions[forcingOnlyImage["BBar"]]]];

topLevelForcingOnly = topSolve[forcingOnlyRecord, coefficientPresentation,
  "OneForms" -> Automatic,
  "AlgebraicLetters" -> {2 + dx + Sqrt[delta]},
  "AdditionalLetters" -> {}, "DLogKernels" -> 1,
  "CoefficientProvider" -> "SplitBranch",
  "GaugeDenominator" -> Automatic, "Support" -> {{0, 0}},
  "IntegrabilityScreen" -> False, "GaugeScreen" -> False,
  "ScreenFirst" -> False, "SamplePrimes" -> {2147483423},
  "HeldOutPrime" -> 2147483323,
  "RegulatorReconstructionValues" -> {1, 2, 3, 5, 7, 11, 13},
  "RegulatorReconstructionCount" -> 7,
  "ReconstructionMinimumGoodPrimeCount" -> 1,
  "ReconstructionMaximumGoodPrimeCount" -> 2,
  "ReconstructionUnseenPrimeCount" -> 1,
  "ReconstructionFreshPointwiseChecksPerPrime" -> 1,
  "PointCount" -> 4, "MaximumAttempts" -> 160];
check["top-level alphabet and provider keep the forcing-only bundle root",
  AssociationQ[topLevelForcingOnly] &&
    Lookup[topLevelForcingOnly, "RootIndices", None] === {1} &&
    Lookup[topLevelForcingOnly, "OneFormCount", 0] >= 1 &&
    ! MemberQ[{"InvalidDeferredBundle",
       "DeferredBundleCoefficientPresentationMismatch",
       "DeferredBundleRootOrderMismatch",
       "DeferredBundleRootCoverageIncomplete", "OneFormBasisFailed"},
      Lookup[topLevelForcingOnly, "Status", None]]];

Print["t_multiquadratic_bundle_provider: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
