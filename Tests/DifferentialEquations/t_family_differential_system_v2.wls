#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Scripts", "DifferentialEquations",
  "FamilyDifferentialSystemV2.wl"}]];

x = Symbol["Global`systemX"];
y = Symbol["Global`systemY"];
eps = Symbol["Global`systemEps"];
flatMatrices = {{{1/x}}, {{1/y}}};
nonflatMatrices = {{{y}}, {{0}}};

l1 = Symbol["Global`systemLoop1"];
l2 = Symbol["Global`systemLoop2"];
p1 = Symbol["Global`systemExternal1"];
p2 = Symbol["Global`systemExternal2"];
p3 = Symbol["Global`systemExternal3"];
s12 = Symbol["Global`systemInvariant12"];
s13 = Symbol["Global`systemInvariant13"];
s23 = Symbol["Global`systemInvariant23"];
quadraticPropagator[momentum_] :=
  FeynCalc`FeynAmpDenominator[
    FeynCalc`StandardPropagatorDenominator[
      FeynCalc`Momentum[momentum], 0, 0, 1]];
bilinearPropagator[first_, second_] :=
  FeynCalc`FeynAmpDenominator[
    FeynCalc`StandardPropagatorDenominator[0,
      FeynCalc`Pair[FeynCalc`Momentum[first],
        FeynCalc`Momentum[second]], 0, 1]];
completeTwoLoopTopology = {"SyntheticTopology", {
    quadraticPropagator[l1], quadraticPropagator[l2],
    bilinearPropagator[l1, l2],
    bilinearPropagator[l1, p1], bilinearPropagator[l1, p2],
    bilinearPropagator[l1, p3], bilinearPropagator[l2, p1],
    bilinearPropagator[l2, p2], bilinearPropagator[l2, p3]},
  {l1, l2}, {p1, p2, p3}};
preparedEulerAlgebra =
  FeynFacetCampaign`DifferentialEquations`Private`familyDEPrepareEulerAlgebra[
    completeTwoLoopTopology, {s12, s13, s23}, {1}];
loopExternalScalarProduct = Lookup[
  preparedEulerAlgebra["ScalarProducts"], Key[Sort[{l1, p1}]]];
quadraticEulerWeight =
  FeynFacetCampaign`DifferentialEquations`Private`familyDEEulerWeight[
    p1, {"Quadratic", l1 + p1}, preparedEulerAlgebra["MomentumBasis"],
    preparedEulerAlgebra["ScalarProducts"]];

finite = FeynFacetCampaign`DifferentialEquations`ValidateFamilyDifferentialSystemFlatness[
  flatMatrices, {x, y}, eps,
    "FiniteFieldPrimes" -> {2147483629}, "PointsPerPrime" -> 2];
exact = FeynFacetCampaign`DifferentialEquations`ValidateFamilyDifferentialSystemFlatness[
  flatMatrices, {x, y}, eps,
    "Method" -> "CharacteristicZeroSymbolicIdentity"];
nonflat = FeynFacetCampaign`DifferentialEquations`ValidateFamilyDifferentialSystemFlatness[
  nonflatMatrices, {x, y}, eps,
    "FiniteFieldPrimes" -> {2147483629}, "PointsPerPrime" -> 1];
record = FeynFacetCampaign`DifferentialEquations`ConstructFamilyDifferentialSystemV2[
  "SyntheticFamily", {mi[1]},
    flatMatrices, {x, y}, eps,
    "FiniteFieldPrimes" -> {2147483629}, "PointsPerPrime" -> 2,
    "MathematicalInputReferences" -> <|
      "CanonicalRegistry" -> <|
        "RelativePath" -> "fixtures/registry.wxf",
        "DataType" -> "FeynFacetCanonicalFamilyRegistryRecord",
        "SchemaVersion" -> 1, "Family" -> "SyntheticFamily"|>,
      "MasterIntegralList" -> <|
        "RelativePath" -> "fixtures/master-integrals.wl",
        "DataType" -> "FeynFacet-KiraStream",
        "SchemaVersion" -> 1, "Family" -> "SyntheticFamily"|>|>,
    "KinematicVariableDefinition" -> <|
      "ScaleNormalization" -> (s12 -> 1),
      "KinematicVariableRules" -> {s13 -> x, s23 -> y}|>,
    "CutIndices" -> {1, 2, 5}];
help = FeynFacetCampaign`DifferentialEquations`ParseFamilyDifferentialSystemCLIArguments[
  {"--help"}];

temporary = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "family_de_v2_" <> ToString[$ProcessID]}]];
Scan[Export[FileNameJoin[{temporary, #}], "fixture", "String"] &,
  {"registry.wxf", "master-integrals.wl", "families.yaml",
    "kinematics.yaml"}];
CreateDirectory[FileNameJoin[{temporary, "scratch"}]];
parsed = FeynFacetCampaign`DifferentialEquations`ParseFamilyDifferentialSystemCLIArguments[{
    "--repository-root", temporary, "--family", "FamilyA",
    "--canonical-registry", "registry.wxf",
    "--master-integral-list", "master-integrals.wl",
    "--integral-families", "families.yaml",
    "--kinematics", "kinematics.yaml", "--scratch", "scratch",
    "--output", "results/system.wl", "--variables", "alpha,beta",
    "--regulator", "delta", "--invariants", "s12,s13,s23",
    "--kira", "/bin/true", "--fermat", "/bin/true"}];
resolved = FeynFacetCampaign`DifferentialEquations`ResolveFamilyDifferentialSystemBuildSpecification[
  parsed];
explicitResolved = FeynFacetCampaign`DifferentialEquations`ResolveFamilyDifferentialSystemBuildSpecification[
  Join[parsed, <|"CanonicalRegistryFile" ->
    FileNameJoin[{temporary, "registry.wxf"}]|>]];
tooManyThreads = FeynFacetCampaign`DifferentialEquations`ResolveFamilyDifferentialSystemBuildSpecification[
    Join[parsed, <|"KiraThreads" -> 9|>]];
metrics = FeynFacetCampaign`DifferentialEquations`Private`familyDEComputationMetricsRecord[
  "SyntheticFamily",
  <|"InputReadSeconds" -> 0.1, "TotalSeconds" -> 0.5|>,
  <|"EulerOperatorCount" -> 3, "SeedMasterIntegralCount" -> 1,
    "ClosedMasterIntegralCount" -> 1, "KiraClosureIterations" -> 1|>,
  {<|"RuleCount" -> 2, "Seconds" -> 0.2|>}, 4];
metricsFile = FeynFacetCampaign`DifferentialEquations`Private`familyDEComputationMetricsFile[
  resolved["OutputFile"]];

yaml = StringRiffle[{"integralfamilies:", "  - name: FamilyA",
  "    top_level_sectors: [b11100]", "    cut_propagators: [1, 2, 5]",
  "  - name: FamilyB", "    top_level_sectors: [b10100]",
  "    cut_propagators: [1, 3]"}, "\n"];
configuration = FeynFacetCampaign`DifferentialEquations`Private`familyDEExtractKiraFamilyConfiguration[
  yaml, "FamilyA"];

FTAssert["bounded finite-field curvature validation succeeds",
  finite["Status"] === "ConnectionFlatnessValidated" &&
    finite["Method"] === "ProbabilisticFiniteFieldSampling" &&
    TrueQ[finite["Probabilistic"]] && ! TrueQ[finite["Exact"]] &&
    Length[finite["Samples"]] === 2];
FTAssert["the two-loop scalar-product basis contains the mixed loop product and has dimension nine",
  Lookup[preparedEulerAlgebra, "Status", None] ===
      "EulerScalarProductAlgebraPrepared" &&
    Length[preparedEulerAlgebra["Propagators"]] === 9 &&
    Length[preparedEulerAlgebra["ScalarProductSolution"]] === 9 &&
    KeyExistsQ[preparedEulerAlgebra["ScalarProducts"],
      Sort[{l1, l2}]]];
FTAssert["quadratic-propagator Euler weights retain the scalar product",
  Together[quadraticEulerWeight - 2 loopExternalScalarProduct] === 0];
FTAssert["development symbolic curvature validation is exact",
  exact["Status"] === "ConnectionFlatnessValidated" &&
    exact["Method"] === "CharacteristicZeroSymbolicIdentity" &&
    TrueQ[exact["Exact"]] && ! TrueQ[exact["Probabilistic"]]];
FTAssert["nonzero curvature is refused",
  nonflat["Status"] === "ConnectionFlatnessValidationFailed" &&
    ! TrueQ[nonflat["Accepted"]]];
FTAssert["the no-Kira constructor emits only the V2 mathematical schema",
  FeynFacetCampaign`DifferentialEquations`FamilyDifferentialSystemV2Q[record] &&
    record["DataType"] === "FamilyDifferentialSystem" &&
    record["SchemaVersion"] === 2 &&
    record["Status"] === "FamilyDifferentialSystemValidated" &&
    record["KinematicVariables"] === {x, y} &&
    record["DimensionalRegulator"] === eps &&
    record["OriginalMasterIntegralBasis"] === {mi[1]} &&
    Dimensions /@ record["ConnectionMatrices"] === {{1, 1}, {1, 1}} &&
    record["MathematicalInputReferences", "CanonicalRegistry",
      "RelativePath"] === "fixtures/registry.wxf" &&
    ! KeyExistsQ[record, "PhaseTimings"] &&
    ! KeyExistsQ[record, "ConstructionMetrics"] &&
    FreeQ[record, _String?(StringContainsQ[ToLowerCase[#],
      "hash" | "fingerprint"] &)]];
FTAssert["execution data has the sibling V2 ComputationMetrics shape",
  metrics["DataType"] === "ComputationMetrics" &&
    metrics["SchemaVersion"] === 2 &&
    metrics["MathematicalStage"] ===
      "FamilyDifferentialSystemConstruction" &&
    metrics["Family"] === "SyntheticFamily" &&
    metrics["WallTimeSeconds"] === 0.5 &&
    metrics["Backend"] === "Kira" &&
    metrics["NativeThreadCount"] === 4 &&
    AssociationQ[metrics["PhaseTimings"]] &&
    AssociationQ[metrics["ConstructionCounts"]] &&
    ListQ[metrics["BackendRuns"]] &&
    IntegerQ[metrics["PeakMemoryBytes"]] &&
    ! KeyExistsQ[record, "ComputationMetrics"]];
FTAssert["computation metrics use a deterministic sibling path",
  metricsFile === FileNameJoin[{temporary, "results",
    "system.computation-metrics.wl"}]];
FTAssert["CLI parsing retains arbitrary declared variable and regulator symbols",
  parsed["Status"] === "FamilyDifferentialSystemCLIArgumentsParsed" &&
    parsed["KinematicVariables"] === {Global`alpha, Global`beta} &&
    parsed["DimensionalRegulator"] === Global`delta &&
    parsed["KiraThreads"] === 8];
FTAssert["CLI help is available without reading artifacts or invoking Kira",
  help["Status"] === "HelpRequested" &&
    StringContainsQ[help["Usage"], "--canonical-registry"] &&
    StringContainsQ[help["Usage"], "--master-integral-list"] &&
    StringContainsQ[help["Usage"], "--kira-threads 8"]];
FTAssert["repository-relative paths resolve without hidden project paths",
  resolved["Status"] ===
      "FamilyDifferentialSystemBuildSpecificationResolved" &&
    resolved["CanonicalRegistryFile"] ===
      FileNameJoin[{temporary, "registry.wxf"}] &&
    resolved["OutputFile"] ===
      FileNameJoin[{temporary, "results", "system.wl"}]];
FTAssert["explicit absolute input paths are retained",
  explicitResolved["Status"] ===
      "FamilyDifferentialSystemBuildSpecificationResolved" &&
    explicitResolved["CanonicalRegistryFile"] ===
      FileNameJoin[{temporary, "registry.wxf"}]];
FTAssert["more than eight Kira native threads is refused",
  tooManyThreads["Status"] === "KiraThreadCountInvalid" &&
    tooManyThreads["MaximumKiraThreads"] === 8];
FTAssert["family selection preserves the matching Kira block and cuts",
  configuration["Status"] === "KiraFamilyConfigurationSelected" &&
    configuration["TopLevelSector"] === "b11100" &&
    configuration["CutIndices"] === {1, 2, 5} &&
    StringContainsQ[configuration["FamilyBlock"], "name: FamilyA"] &&
    ! StringContainsQ[configuration["FamilyBlock"], "name: FamilyB"]];

DeleteDirectory[temporary, DeleteContents -> True];
FTReport[];
