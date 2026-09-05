#!/usr/bin/env wolframscript
(* Round-B deferred-DAG provider acceptance. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{inhomogeneityOf, prepare, layoutBuilder, directProvider, channels, pointRows,
  assembleSample, providerPreflight, splitPlanBuilder, splitPlanValidQ,
  splitEntry, screenCompile, clearCaches, validateBundle,
  presentationRoots, generatorExpression} = mq /@ {
    "blockEquationDeferredInhomogeneity",
    "multiquadraticOffDiagonalBlockPrepare", "multiquadraticOffDiagonalBlockAssemblyLayout",
    "multiquadraticOffDiagonalBlockDirectProvider",
    "multiquadraticOffDiagonalBlockProviderChannels",
    "multiquadraticOffDiagonalBlockAssemblePointRows",
    "multiquadraticOffDiagonalBlockAssembleSample",
    "multiquadraticOffDiagonalBlockProviderPreflight",
    "multiquadraticOffDiagonalBlockSplitSparseEvaluationPlan",
    "multiquadraticOffDiagonalBlockSplitSparseEvaluationPlanValidQ",
    "multiquadraticOffDiagonalBlockSplitBranchEntry",
    "multiquadraticOffDiagonalBlockScreenCompileScalar",
    "multiquadraticOffDiagonalBlockClearCaches",
    "blockEquationDeferredBundleValidate",
    "coefficientPresentationSquareRootsInVariables",
    "squareRootRecordExpression"};
topSolve = mq["solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators"];

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
compat = inhomogeneityOf[connection, ranges, 3, 1, solved, {dx, dy}, de,
  "DivisorRoots" -> {bundleRootRecord}];
bundle = Lookup[compat, "DeferredBundle", <||>];

check["bundle provider fixture is validated",
  Lookup[compat, "Status", None] === "OK" &&
    Lookup[validateBundle[bundle], "Status", None] === "BundleValid"];

dimensions = Rest[bundle["Dimensions"]];
e = Table[Sqrt[delta] IdentityMatrix[dimensions[[1]]], {2}];
c = Table[ConstantArray[0, {dimensions[[2]], dimensions[[2]]}], {2}];
zeroInhomogeneity = ConstantArray[0, bundle["Dimensions"]];
bundleRecord = <|"Family" -> "BUNDLE_PROVIDER", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {dx, dy}, "Regulator" -> de,
  "OffDiagonalBlockEquation" -> {e, c, zeroInhomogeneity}, "DeferredBundle" -> bundle|>;
prepared = prepare[bundleRecord, coefficientPresentation, "RootIndices" -> {1},
  "OneForms" -> {}, "OffDiagonalBasisTransformationDenominator" -> Automatic,
  "Support" -> {{0, 0}}, "CoefficientProvider" -> "SplitBranch"];
layout = layoutBuilder[prepared];
bundleSplit = directProvider[prepared["Record"], prepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
  "OffDiagonalBasisTransformationDenominator" -> prepared["OffDiagonalBasisTransformationDenominator"],
  "DeferredBundle" -> bundle];
bundleQuotient = directProvider[prepared["Record"], prepared["Roots"],
  "Kind" -> "QuotientGrade", "OneForms" -> prepared["OneForms"],
  "OffDiagonalBasisTransformationDenominator" -> prepared["OffDiagonalBasisTransformationDenominator"],
  "DeferredBundle" -> bundle];
oracleRecord = Join[bundleRecord, <|"OffDiagonalBlockEquation" -> {e, c, compat["Inhomogeneity"]}|>];
oracle = directProvider[oracleRecord, prepared["Roots"],
  "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
  "OffDiagonalBasisTransformationDenominator" -> prepared["OffDiagonalBasisTransformationDenominator"],
  "DeferredBundle" -> None];

check["bundle divisor summary supplies the automatic rational denominator",
  Lookup[prepared, "Status", None] === "PreparedMultiquadraticOffDiagonalBlockV1" &&
    AssociationQ[prepared["BundleDivisorProvenance"]] &&
    bundle["SchemaVersion"] === 3 &&
    AssociationQ[bundle["CoefficientPresentation"]] &&
    bundle["SquareRootGeneratorIndices"] === {1} &&
    prepared["CoefficientPresentation"] === coefficientPresentation &&
    FreeQ[prepared["OffDiagonalBasisTransformationDenominator"], Power[_, _Rational]]];

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
    KeyTake[plannedBundleSplitImage, {"E", "C", "Inhomogeneity", "OneForms"}] ===
      KeyTake[bundleSplitImage, {"E", "C", "Inhomogeneity", "OneForms"}] &&
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

check["bundle SplitBranch evaluates complete coefficients without dense Inhomogeneity",
  Lookup[bundleSplitImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    bundleSplitImage["Inhomogeneity"] === oracleImage["Inhomogeneity"] &&
    bundleSplitImage["E"] === oracleImage["E"] &&
    bundleSplitImage["C"] === oracleImage["C"] &&
    bundleSplitImage["Inhomogeneity"] =!= ConstantArray[0,
      Dimensions[bundleSplitImage["Inhomogeneity"]]]];
check["bundle QuotientGrade agrees with split and materialized oracle",
  Lookup[bundleQuotientImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    KeyTake[bundleQuotientImage, {"E", "C", "Inhomogeneity", "OneForms"}] ===
      KeyTake[bundleSplitImage, {"E", "C", "Inhomogeneity", "OneForms"}]];
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
  "OffDiagonalBasisTransformationDenominator" -> prepared["OffDiagonalBasisTransformationDenominator"],
  "DeferredBundle" -> mutated];
mutantImage = channels[mutantProvider, epsilonValue, prime, point];
check["changed valid bundle equations produce changed provider coefficients",
  Lookup[validateBundle[mutated], "Status", None] === "BundleValid" &&
    Lookup[mutantProvider, "Status", None] ===
      "MultiquadraticDirectProviderV1" &&
    Lookup[mutantImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    mutantImage["Inhomogeneity"] =!= bundleSplitImage["Inhomogeneity"]];

(* The production driver intentionally puts a zero tensor in Inhomogeneity when the
   validated deferred bundle is the inhomogeneity source.  A generator used only
   by that bundle must therefore enter preparation through its coefficient
   presentation, not be
   rejected as an extraneous explicit RootIndices request. *)
zeroE = ConstantArray[0, {2, dimensions[[1]], dimensions[[1]]}];
zeroC = ConstantArray[0, {2, dimensions[[2]], dimensions[[2]]}];
inhomogeneityOnlyRecord = <|"Family" -> "BUNDLE_ROOT_CENSUS", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {dx, dy}, "Regulator" -> de,
  "OffDiagonalBlockEquation" -> {zeroE, zeroC, zeroInhomogeneity}, "DeferredBundle" -> bundle|>;
inhomogeneityOnlyPrepared = prepare[inhomogeneityOnlyRecord, coefficientPresentation,
  "OneForms" -> {}, "OffDiagonalBasisTransformationDenominator" -> Automatic,
  "Support" -> {{0, 0}}, "CoefficientProvider" -> "SplitBranch"];
inhomogeneityOnlyProvider = directProvider[inhomogeneityOnlyPrepared["Record"],
  inhomogeneityOnlyPrepared["Roots"], "Kind" -> "SplitBranch", "OneForms" -> {},
  "OffDiagonalBasisTransformationDenominator" -> inhomogeneityOnlyPrepared["OffDiagonalBasisTransformationDenominator"],
  "DeferredBundle" -> bundle];
inhomogeneityOnlyImage = channels[inhomogeneityOnlyProvider, epsilonValue, prime, point];
inhomogeneityOnlyOracleRecord = Join[inhomogeneityOnlyRecord, <|
  "OffDiagonalBlockEquation" -> {zeroE, zeroC, compat["Inhomogeneity"]}, "DeferredBundle" -> None|>];
inhomogeneityOnlyOracle = directProvider[inhomogeneityOnlyOracleRecord,
  inhomogeneityOnlyPrepared["Roots"], "Kind" -> "SplitBranch", "OneForms" -> {},
  "OffDiagonalBasisTransformationDenominator" -> inhomogeneityOnlyPrepared["OffDiagonalBasisTransformationDenominator"],
  "DeferredBundle" -> None];
inhomogeneityOnlyOracleImage = channels[inhomogeneityOnlyOracle, epsilonValue, prime,
  point];
bundleRoots = presentationRoots[bundle["CoefficientPresentation"],
  {dx, dy}][[bundle["SquareRootGeneratorIndices"]]];
check["prepare includes generators used only by a validated deferred inhomogeneity",
  Lookup[inhomogeneityOnlyPrepared, "Status", None] ===
      "PreparedMultiquadraticOffDiagonalBlockV1" &&
    inhomogeneityOnlyPrepared["RootCount"] === 1 &&
    inhomogeneityOnlyPrepared["RootIndices"] === {1} &&
    (generatorExpression /@ inhomogeneityOnlyPrepared["Roots"]) ===
      (generatorExpression /@ bundleRoots)];
check["the inhomogeneity-only bundle reaches the provider without materializing Inhomogeneity",
  Lookup[inhomogeneityOnlyImage, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    inhomogeneityOnlyImage["Inhomogeneity"] === inhomogeneityOnlyOracleImage["Inhomogeneity"] &&
    inhomogeneityOnlyImage["Inhomogeneity"] =!= ConstantArray[0,
      Dimensions[inhomogeneityOnlyImage["Inhomogeneity"]]]];

topLevelInhomogeneityOnly = topSolve[inhomogeneityOnlyRecord, coefficientPresentation,
  "OneForms" -> Automatic,
  "AlgebraicLetters" -> {2 + dx + Sqrt[delta]},
  "AdditionalLetters" -> {}, "DLogKernels" -> 1,
  "CoefficientProvider" -> "SplitBranch",
  "OffDiagonalBasisTransformationDenominator" -> Automatic, "Support" -> {{0, 0}},
  "IntegrabilityScreen" -> False, "OffDiagonalBasisTransformationBlockScreen" -> False,
  "ScreenFirst" -> False, "SamplePrimes" -> {2147483423},
  "HeldOutPrime" -> 2147483323,
  "RegulatorReconstructionValues" -> {1, 2, 3, 5, 7, 11, 13},
  "RegulatorReconstructionCount" -> 7,
  "ReconstructionMinimumGoodPrimeCount" -> 1,
  "ReconstructionMaximumGoodPrimeCount" -> 2,
  "ReconstructionUnseenPrimeCount" -> 1,
  "ReconstructionFreshPointwiseChecksPerPrime" -> 1,
  "PointCount" -> 4, "MaximumAttempts" -> 160];
check["top-level alphabet and provider keep the inhomogeneity-only bundle root",
  AssociationQ[topLevelInhomogeneityOnly] &&
    Lookup[topLevelInhomogeneityOnly, "RootIndices", None] === {1} &&
    Lookup[topLevelInhomogeneityOnly, "OneFormCount", 0] >= 1 &&
    ! MemberQ[{"InvalidDeferredBundle",
       "DeferredBundleCoefficientPresentationMismatch",
       "DeferredBundleRootOrderMismatch",
       "DeferredBundleRootCoverageIncomplete", "OneFormBasisFailed"},
      Lookup[topLevelInhomogeneityOnly, "Status", None]]];

Print["t_multiquadratic_bundle_provider: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
