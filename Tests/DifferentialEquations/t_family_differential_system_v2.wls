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
      "TraceManifest" -> <|
        "RelativePath" -> "fixtures/trace.wxf",
        "DataType" -> "FeynFacet-TraceCheckpoint",
        "SchemaVersion" -> 2, "Family" -> "SyntheticFamily"|>|>,
    "KinematicVariableDefinition" -> <|
      "ScaleNormalization" -> (s12 -> 1),
      "KinematicVariableRules" -> {s13 -> x, s23 -> y}|>,
    "CutIndices" -> {1, 2, 5}];
help = FeynFacetCampaign`DifferentialEquations`ParseFamilyDifferentialSystemCLIArguments[
  {"--help"}];

temporary = CreateDirectory[FileNameJoin[{$TemporaryDirectory,
  "family_de_v2_" <> ToString[$ProcessID]}]];
Scan[Export[FileNameJoin[{temporary, #}], "fixture", "String"] &,
  {"registry.wxf", "trace.wxf", "families.yaml", "kinematics.yaml"}];
CreateDirectory[FileNameJoin[{temporary, "scratch"}]];
parsed = FeynFacetCampaign`DifferentialEquations`ParseFamilyDifferentialSystemCLIArguments[{
    "--repository-root", temporary, "--family", "FamilyA",
    "--canonical-registry", "registry.wxf",
    "--trace-manifest", "trace.wxf",
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
