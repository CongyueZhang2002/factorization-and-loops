#!/usr/bin/env wolframscript

(* The native deferred evaluator replaces only BBar.  E, C, Q, one-forms,
   preflight and row assembly remain the package's existing provider path. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{prepare, layoutBuilder, directProvider, attachDeferred, preflight,
  nativeBatchEvaluator, assembleSample, forcingOf, solve,
  wideScheduleQ, presentationRoots, generatorExpression} = mq /@ {
  "multiquadraticStripPrepare", "multiquadraticStripAssemblyLayout",
  "multiquadraticStripDirectProvider",
  "multiquadraticStripAttachDeferredPreparation",
  "multiquadraticStripProviderPreflight",
  "multiquadraticStripNativeDeferredEvaluateBatch",
  "multiquadraticStripAssembleSample",
  "blockEquationDeferredForcing",
  "solveEpsFormStripMultiquadratic",
  "multiquadraticStripWidePrimeScheduleQ",
  "coefficientPresentationSquareRootsInVariables",
  "squareRootRecordExpression"};

Clear[x, y, eps, sx, sy, cx, cy];
(* The package's word-prime square-root path uses p == 3 (mod 4). *)
prime = 103;
coefficientPresentation = BuildSquareRootGeneratorsAndQuadraticRelations[
  {sx, sy, 1 + sx + sy}, {sx, sy}, {cx, cy}];
roots = presentationRoots[coefficientPresentation, {x, y}];
zero11 = {{{0}}, {{0}}};
(* Keep every declared root visible to the ordinary root census.  The native
   source below supplies only the off-diagonal forcing. *)
e = {{{Total[generatorExpression /@ roots]}}, {{0}}};
record = <|"Family" -> "DEFERRED_AST_NATIVE_PROVIDER", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {e, zero11, zero11}|>;

expression = 7 + 5*Sqrt[x] + 11*Sqrt[y] + 13*Sqrt[1 + x + y] +
  17*Sqrt[x]*Sqrt[y] + 19*Sqrt[x]*Sqrt[1 + x + y] +
  23*Sqrt[y]*Sqrt[1 + x + y] +
  29*Sqrt[x]*Sqrt[y]*Sqrt[1 + x + y];
sourcePreparation = <|"DataType" -> "DeferredBlockEquation",
  "SchemaVersion" -> 2, "Status" -> "Prepared",
  "Variables" -> {x, y},
  "Regulator" -> eps, "Dimensions" -> {2, 1, 1},
  "Records" -> {
    <|"Target" -> {1, 1, 1}, "Terms" -> {
      <|"Coefficient" -> 1, "Operands" -> {expression}|>}|>,
    <|"Target" -> {2, 1, 1}, "Terms" -> {
      <|"Coefficient" -> 2, "Operands" -> {expression}|>}|>}
  |>;
sourceFile = CreateTemporary[];
Put[<|"DeferredPreparation" ->
    <|"Preparation" -> sourcePreparation|>|>, sourceFile];

prepared = prepare[record, coefficientPresentation, "RootIndices" -> {1, 2, 3},
  "OneForms" -> {}, "GaugeDenominator" -> 1,
  "Support" -> {{0, 0}}, "CoefficientProvider" -> "QuotientGrade"];
layout = layoutBuilder[prepared];
provider = directProvider[prepared["Record"], prepared["Roots"],
  "Kind" -> "QuotientGrade", "OneForms" -> prepared["OneForms"],
  "GaugeDenominator" -> prepared["GaugeDenominator"]];
provider = attachDeferred[provider, sourcePreparation, sourceFile];
wrongSourcePreparation = ReplacePart[sourcePreparation,
  {Key["Records"], 1, Key["Terms"], 1, Key["Coefficient"]} -> 37];
wrongSourceFile = CreateTemporary[];
Put[<|"DeferredPreparation" ->
    <|"Preparation" -> wrongSourcePreparation|>|>, wrongSourceFile];
FTAssert["deferred preparation attachment checks the file's exact mathematical data",
  Lookup[attachDeferred[provider, sourcePreparation, wrongSourceFile],
    "Status", None] === "DeferredPreparationFileDataMismatch"];
point = preflight[provider, 7, prime, {4, 9}];
batch = nativeBatchEvaluator[provider, {point}];
derivativeBatch = nativeBatchEvaluator[provider, {point},
  "Derivatives" -> True];

expectedGrades = {7, 5, 11, 17, 13, 19, 23, 29};
expectedBBar = ArrayReshape[
  Join[expectedGrades, Mod[2 expectedGrades, prime]], {2, 1, 1, 8}];
FTAssert["native deferred provider emits the exact grade channels",
  Lookup[batch, "Status", None] ===
      "MultiquadraticNativeDeferredBatchV1" &&
    batch["BBarBatch"] === {expectedBBar}];
expectedDerivativeX = {0, 65, 0, 15, 63, 38, 56, 58};
expectedDerivativeY = {0, 0, 75, 41, 63, 100, 63, 66};
expectedDerivatives = ({ArrayReshape[Join[#1, Mod[2 #1, prime]],
      {2, 1, 1, 8}]} &) /@ {expectedDerivativeX, expectedDerivativeY};
FTAssert["native deferred provider differentiates the radical DAG exactly",
  Lookup[derivativeBatch, "Status", None] ===
      "MultiquadraticNativeDeferredDerivativeBatchV1" &&
    derivativeBatch["BBarBatch"] === {expectedBBar} &&
    derivativeBatch["BBarDerivativeBatch"] === expectedDerivatives];

sample = assembleSample[layout, provider, 7, prime,
  "PointCount" -> 1, "MaximumAttempts" -> 1,
  "CandidatePoints" -> {{4, 9}}, "SplitPointsOnly" -> True];
expectedRight = Flatten[Table[
  expectedBBar[[mu, 1, 1, grade]], {grade, 8}, {mu, 2}]];
FTAssert["provider sampler injects native BBar into the existing rows",
  Lookup[sample, "Status", None] ===
      "AssembledMultiquadraticSampleV1" &&
    sample["RightHandSide"] === expectedRight &&
    sample["NativeDeferredSourceQ"] === True &&
    sample["NativeDeferredBatchSuccessCount"] === 1 &&
    sample["NativeDeferredBatchFailureCount"] === 0];

(* Exercise the actual top-level provider constructor.  The bundle compiler
   preserves the same raw preparation as acceleration metadata, and the
   production strip file contains that nested payload. *)
connection = {
  {{0, 0}, {expression, 0}},
  {{0, 0}, {2 expression, 0}}
};
bundle = forcingOf[connection, {{1}, {2}}, 2, 1, <||>, {x, y}, eps,
  "Output" -> "Bundle", "BundleRoots" -> roots,
  "Progress" -> False];
productionRecord = Join[record, <|"DeferredBundle" -> bundle|>];
productionFile = CreateTemporary[];
Put[productionRecord, productionFile];

constructorResult = Block[
  {FeynFacet`Private`multiquadraticStripReconstructRegulator},
  FeynFacet`Private`multiquadraticStripReconstructRegulator[
      constructorPreparation_Association, constructorLayout_Association,
      constructorProvider_Association, ___] := Module[{constructorSample},
    constructorSample = assembleSample[constructorLayout,
      constructorProvider, 7, prime,
      "PointCount" -> 1, "MaximumAttempts" -> 1,
      "CandidatePoints" -> {{4, 9}}, "SplitPointsOnly" -> True];
    <|"Status" -> "NativeDeferredConstructorProbe",
      "ProviderAttached" ->
        AssociationQ[Lookup[constructorProvider,
          "DeferredPreparation", None]],
      "ProviderCarriesBundle" ->
        AssociationQ[Lookup[constructorProvider, "DeferredBundle", None]],
      "LayoutCarriesBundle" ->
        AssociationQ[Lookup[constructorLayout["Record"],
          "DeferredBundle", None]],
      "WideScheduleQ" -> wideScheduleQ[constructorProvider],
      "ProviderDeferredPreparation" ->
        Lookup[constructorProvider, "DeferredPreparation", None],
      "ProviderCoefficientData" ->
        Lookup[constructorProvider, "CoefficientData", None],
      "ConstructorSample" -> constructorSample|>];
  solve[productionRecord, coefficientPresentation,
    "DeferredBundle" -> bundle,
    "DeferredPreparationFile" -> productionFile,
    "RootIndices" -> {1, 2, 3}, "OneForms" -> {},
    "GaugeDenominator" -> 1, "Support" -> {{0, 0}},
    "CoefficientProvider" -> "SplitBranch",
    "IntegrabilityScreen" -> False, "ScreenFirst" -> False,
    "GaugeScreen" -> False, "DegreeOffsetLadder" -> None,
    "SamplePrimes" -> {prime}, "HeldOutPrime" -> 107,
    "RegulatorValues" -> {2}, "HeldOutRegulatorValue" -> 3,
    "Verbose" -> False]
];
constructorSample = Lookup[constructorResult, "ConstructorSample", <||>];
Print["native deferred production-route telemetry: ", InputForm[<|
  "BundleCompileSeconds" -> Lookup[Lookup[bundle, "Statistics", <||>],
    "CompileSeconds", Missing["NotMeasured"]],
  "NativeBatchSeconds" -> Lookup[constructorSample,
    "NativeDeferredBatchSeconds", Missing["NotMeasured"]],
  "NativeParseSeconds" -> Lookup[constructorSample,
    "NativeDeferredParseSeconds", Missing["NotMeasured"]],
  "NativeEvaluationSeconds" -> Lookup[constructorSample,
    "NativeDeferredEvaluationSeconds", Missing["NotMeasured"]],
  "SplitPlanSeconds" -> Lookup[constructorSample,
    "SplitSparsePlanConstructionSeconds", Missing["NotMeasured"]],
  "BundleCompositionSeconds" -> Lookup[constructorSample,
    "SplitSparseDeferredBundleCompositionSeconds",
    Missing["NotMeasured"]]|>]];
FTAssert["production constructor attaches the bundle DAG and bypasses bundle BBar",
  Lookup[bundle, "Status", None] === "PreparedDeferredBundle" &&
    AssociationQ[Lookup[bundle, "DeferredPreparation", None]] &&
    Lookup[constructorResult, "Status", None] ===
      "NativeDeferredConstructorProbe" &&
    TrueQ[constructorResult["ProviderAttached"]] &&
    ! TrueQ[constructorResult["ProviderCarriesBundle"]] &&
    ! TrueQ[constructorResult["LayoutCarriesBundle"]] &&
    TrueQ[constructorResult["WideScheduleQ"]] &&
    constructorResult["ProviderDeferredPreparation"] ===
      KeyTake[bundle["DeferredPreparation", "Preparation"],
        {"DataType", "SchemaVersion", "Status", "Variables",
         "Regulator", "Dimensions"}] &&
    AssociationQ[constructorResult["ProviderCoefficientData"]] &&
    Lookup[constructorSample, "Status", None] ===
      "AssembledMultiquadraticSampleV1" &&
    constructorSample["RightHandSide"] === expectedRight &&
    TrueQ[constructorSample["NativeDeferredSourceQ"]] &&
    constructorSample["NativeDeferredBatchSuccessCount"] === 1 &&
    constructorSample["NativeDeferredBatchFailureCount"] === 0 &&
    constructorSample["SplitSparsePlanUniqueLeafCount"] === 0 &&
    constructorSample["SplitSparseDeferredBundleCompositionSeconds"] === 0.];

Quiet[DeleteFile[sourceFile]];
Quiet[DeleteFile[wrongSourceFile]];
Quiet[DeleteFile[productionFile]];
FTReport[];
