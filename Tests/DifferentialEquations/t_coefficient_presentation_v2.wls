root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "DifferentialEquations",
  "CoefficientPresentationV2.wl"}]];

Clear[a, b, c, d, delta, master, internalX, internalY];

system = <|
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Status" -> "FamilyDifferentialSystemValidated",
  "Family" -> "SyntheticPresentation",
  "KinematicVariables" -> {a, b},
  "DimensionalRegulator" -> delta,
  "OriginalMasterIntegralBasis" -> {master[1]},
  "ConnectionMatrices" -> {{{delta/a}}, {{delta/b}}}|>;

source = FeynFacetCampaign`DifferentialEquations`ConstructCoefficientPresentationV2[
  system,
    <|"CoefficientPresentationType" ->
      "SourceVariableRepresentation"|>];

rationalizing =
  FeynFacetCampaign`DifferentialEquations`ConstructCoefficientPresentationV2[
    system,
    <|"CoefficientPresentationType" ->
        "RationalizingParametrization",
      "CatalogName" -> "Kallen1"|>,
    "CoefficientVariables" -> {c, d}];

radicands = {(1 - a - b)^2 - 4 a b, 1 - 4 a b,
  4 a + b^2};
squareRoots =
  FeynFacetCampaign`DifferentialEquations`ConstructCoefficientPresentationV2[
    system,
    <|"CoefficientPresentationType" ->
        "SquareRootGeneratorsAndQuadraticRelations",
      "SourceRadicands" -> radicands|>,
    "CoefficientVariables" -> {c, d}];

internalSquareRoots = FeynFacet`Private`rekeyCoefficientPresentation[
  squareRoots, {internalX, internalY}, {internalX, internalY}];
renamePotential = Sqrt[First[radicands]];
renameConnection = <|
  "Av" -> {{D[renamePotential, a]}},
  "Aw" -> {{D[renamePotential, b]}}|>;
renamePullback = FeynFacet`Private`masterTransportPullBackSystem[
  renameConnection, squareRoots,
  "SourceVariables" -> {a, b}, "FlatnessCheck" -> False];

badCatalog =
  FeynFacetCampaign`DifferentialEquations`ConstructCoefficientPresentationV2[
    system,
    <|"CoefficientPresentationType" ->
        "RationalizingParametrization",
      "CatalogName" -> "NotInCatalog"|>];

badSpecification =
  FeynFacetCampaign`DifferentialEquations`ConstructCoefficientPresentationV2[
    system,
    <|"CoefficientPresentationType" ->
      "SourceVariableRepresentation", "Unexpected" -> True|>];

projectSpecifications = FeynFacet`FamilyArtifactRead[FileNameJoin[{root,
  "ppHX_NNLO_DoubleReal", "Cards", "DifferentialEquations",
  "FamilyCoefficientPresentationSpecifications.wl"}]];
projectPresentations = Association@KeyValueMap[
  Function[{family, specification}, family ->
    FeynFacetCampaign`DifferentialEquations`ConstructCoefficientPresentationV2[
      Join[system, <|"Family" -> family|>], specification]],
  projectSpecifications];

tests = <|
  "SourceVariablesRemainUnchanged" ->
    source["DataType"] === "SourceVariableRepresentation" &&
      source["SourceVariables"] === {a, b} &&
      source["CoefficientVariables"] === {a, b} &&
      source["SourceVariableSubstitution"] === {a -> a, b -> b},
  "NamedParametrizationIsRekeyedAndVerified" ->
    rationalizing["DataType"] === "RationalizingParametrization" &&
      rationalizing["SourceVariables"] === {a, b} &&
      rationalizing["ParametrizingVariables"] === {c, d} &&
      And @@ rationalizing["RationalizedSquareRootIdentities"],
  "ThreeSquareRootRelationsAreVerified" ->
    squareRoots["DataType"] ===
        "SquareRootGeneratorsAndQuadraticRelations" &&
      Length[squareRoots["SquareRootGenerators"]] === 3 &&
      TrueQ[squareRoots["QuadraticRelationVerification", "Verified"]],
  "PureRenameSquareRootPresentationCanUseOneInternalVariablePair" ->
    internalSquareRoots["Status"] ===
        "SquareRootGeneratorRelationsVerified" &&
      internalSquareRoots["SourceVariables"] ===
        {internalX, internalY} &&
      internalSquareRoots["CoefficientVariables"] ===
        {internalX, internalY} &&
      internalSquareRoots["SourceToCoefficientVariableRules"] ===
        {internalX -> internalX, internalY -> internalY},
  "PureVariableRenameDoesNotRationallyResimplifyTheConnection" ->
    renamePullback["Status"] === "OK" &&
      renamePullback["Ax"] ===
        (renameConnection["Av"] /. {a -> c, b -> d}) &&
      renamePullback["Ay"] ===
        (renameConnection["Aw"] /. {a -> c, b -> d}) &&
      renamePullback["Certificate", "ChainRule"] ===
        "Pure variable rename with identity differential pullback",
  "AllConstructedRecordsPassTheIndependentPredicate" ->
    And @@ (FeynFacetCampaign`DifferentialEquations`CoefficientPresentationV2Q[
          #, {a, b}] & /@
        {source, rationalizing, squareRoots}),
  "UnknownCatalogEntryIsRefused" ->
    Lookup[badCatalog, "Status", None] ===
      "InvalidFamilyRootDataEntries",
  "ExtraSpecificationKeysAreRefused" ->
    Lookup[badSpecification, "Status", None] ===
      "CoefficientPresentationSpecificationNotWellFormed",
  "ProjectCardExplicitlyCoversAllFamilies" ->
    Length[projectSpecifications] === 91 &&
      Counts[Lookup[Values[projectSpecifications],
        "CoefficientPresentationType"]] === <|
        "SourceVariableRepresentation" -> 44,
        "RationalizingParametrization" -> 44,
        "SquareRootGeneratorsAndQuadraticRelations" -> 3|> &&
      AllTrue[Values[projectPresentations],
        FeynFacetCampaign`DifferentialEquations`CoefficientPresentationV2Q[
          #, {a, b}] &],
  "NoExecutionDigestFields" ->
    FreeQ[Keys /@ {source, rationalizing, squareRoots},
      key_String /; StringContainsQ[ToLowerCase[key],
        "hash" | "fingerprint" | "digest"]]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
