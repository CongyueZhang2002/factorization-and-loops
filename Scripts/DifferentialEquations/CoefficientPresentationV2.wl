(* Construction of one schema-V2 coefficient presentation from an explicit
   project specification.  The specification chooses a mathematical
   representation; the package catalog and relation constructors supply and
   verify its actual formulas. *)

BeginPackage["FeynFacetCampaign`DifferentialEquations`"];

ConstructCoefficientPresentationV2::usage =
  "ConstructCoefficientPresentationV2[system,specification,opts] constructs and verifies the coefficient presentation selected for a V2 FamilyDifferentialSystem. The specification must explicitly select unchanged source variables, a named catalogued rationalizing parametrization, or square-root generators with stated source radicands.";
CoefficientPresentationV2Q::usage =
  "CoefficientPresentationV2Q[presentation,sourceVariables] verifies that presentation is one of the three schema-V2 coefficient presentations and that its defining substitution, Jacobian, and square-root relations hold.";
BuildCoefficientPresentationV2::usage =
  "BuildCoefficientPresentationV2[systemFile,specificationFile,outputFile,opts] reads a V2 FamilyDifferentialSystem and a complete family-to-presentation specification, constructs the selected presentation, and writes it atomically.";

Begin["`Private`"];

ClearAll[
  coefficientPresentationFailure,
  coefficientPresentationAbsolutePathQ,
  coefficientPresentationResolvePath,
  coefficientPresentationSystemQ,
  coefficientPresentationSpecificationQ,
  coefficientPresentationPersistedFields,
  coefficientPresentationReference,
  ConstructCoefficientPresentationV2,
  CoefficientPresentationV2Q,
  BuildCoefficientPresentationV2
];

coefficientPresentationFailure[status_String, extra_: <||>] :=
  Join[<|"Status" -> status|>, extra];

coefficientPresentationAbsolutePathQ[path_String] :=
  StringStartsQ[path, "/"] ||
    StringMatchQ[path, RegularExpression["^[A-Za-z]:[\\\\/]"]];

coefficientPresentationResolvePath[root_String, path_String] :=
  ExpandFileName[If[coefficientPresentationAbsolutePathQ[path], path,
    FileNameJoin[{root, path}]]];

coefficientPresentationSystemQ[system_Association] := Module[
  {variables, regulator, basis, matrices, dimension},
  variables = Lookup[system, "KinematicVariables", Missing[]];
  regulator = Lookup[system, "DimensionalRegulator", Missing[]];
  basis = Lookup[system, "OriginalMasterIntegralBasis", Missing[]];
  matrices = Lookup[system, "ConnectionMatrices", Missing[]];
  dimension = If[ListQ[basis], Length[basis], 0];
  Lookup[system, "DataType", None] === "FamilyDifferentialSystem" &&
    Lookup[system, "SchemaVersion", None] === 2 &&
    Lookup[system, "Status", None] ===
      "FamilyDifferentialSystemValidated" &&
    StringQ[Lookup[system, "Family", None]] &&
    MatchQ[variables, {_Symbol, _Symbol}] &&
    MatchQ[regulator, _Symbol] && ! MemberQ[variables, regulator] &&
    dimension > 0 && MatchQ[matrices, {_?MatrixQ, _?MatrixQ}] &&
    AllTrue[matrices, Dimensions[#] === {dimension, dimension} &]
];
coefficientPresentationSystemQ[_] := False;

coefficientPresentationSpecificationQ[specification_Association] :=
  Switch[Lookup[specification, "CoefficientPresentationType", None],
    "SourceVariableRepresentation",
      Keys[specification] === {"CoefficientPresentationType"},
    "RationalizingParametrization",
      Sort[Keys[specification]] === Sort[{
        "CoefficientPresentationType", "CatalogName"}] &&
        StringQ[Lookup[specification, "CatalogName", None]],
    "SquareRootGeneratorsAndQuadraticRelations",
      Sort[Keys[specification]] === Sort[{
        "CoefficientPresentationType", "SourceRadicands"}] &&
        MatchQ[Lookup[specification, "SourceRadicands", Missing[]], {__}],
    _, False
  ];
coefficientPresentationSpecificationQ[_] := False;

(* Internal verification data include PresentationKind, which is a dispatch
   cache rather than part of the mathematical record. *)
coefficientPresentationPersistedFields[data_Association] := Join[
  KeyDrop[data, {"PresentationKind", "Status"}],
  <|"Status" -> "CoefficientPresentationValidated"|>
];

Options[ConstructCoefficientPresentationV2] = {
  "CoefficientVariables" -> Automatic
};

ConstructCoefficientPresentationV2[system_Association,
    specification_Association, OptionsPattern[]] := Module[
  {family, sourceVariables, coefficientVariables, selected, registered,
   raw, data, output},
  If[! coefficientPresentationSystemQ[system],
    Return[coefficientPresentationFailure[
      "FamilyDifferentialSystemNotWellFormed"]]];
  If[! coefficientPresentationSpecificationQ[specification],
    Return[coefficientPresentationFailure[
      "CoefficientPresentationSpecificationNotWellFormed"]]];
  family = system["Family"];
  sourceVariables = system["KinematicVariables"];
  coefficientVariables = OptionValue["CoefficientVariables"];
  If[coefficientVariables === Automatic,
    coefficientVariables = {Symbol["Global`x"], Symbol["Global`y"]}];
  If[! MatchQ[coefficientVariables, {_Symbol, _Symbol}] ||
      ! DuplicateFreeQ[coefficientVariables],
    Return[coefficientPresentationFailure[
      "CoefficientVariablesInvalid"]]];
  selected = specification["CoefficientPresentationType"];
  raw = Switch[selected,
    "SourceVariableRepresentation", None,
    "RationalizingParametrization",
      registered = FeynFacet`RegisterFamilyRootData[<|family -> <|
        "RationalizingParametrizationName" ->
          specification["CatalogName"]|>|>];
      If[Lookup[registered, "Status", None] =!=
          "FamilyRootDataRegistered", Return[registered]];
      FeynFacet`FamilyRootData[family, sourceVariables,
        coefficientVariables],
    "SquareRootGeneratorsAndQuadraticRelations",
      registered = FeynFacet`RegisterFamilyRootData[<|family -> <|
        "SourceRadicands" -> specification["SourceRadicands"]|>|>];
      If[Lookup[registered, "Status", None] =!=
          "FamilyRootDataRegistered", Return[registered]];
      FeynFacet`FamilyRootData[family, sourceVariables,
        coefficientVariables]
  ];
  If[MissingQ[raw] || (raw =!= None && ! AssociationQ[raw]),
    Return[coefficientPresentationFailure[
      "CoefficientPresentationConstructionFailed",
      <|"Detail" -> raw|>]]];
  data = FeynFacet`Private`masterTransportCoefficientPresentationData[
    raw, sourceVariables];
  If[Lookup[data, "Status", None] =!= "OK",
    Return[coefficientPresentationFailure[
      "CoefficientPresentationValidationFailed", <|"Detail" -> data|>]]];
  output = coefficientPresentationPersistedFields[data];
  If[! CoefficientPresentationV2Q[output, sourceVariables],
    Return[coefficientPresentationFailure[
      "CoefficientPresentationValidationFailed"]]];
  output
];
ConstructCoefficientPresentationV2[___] :=
  coefficientPresentationFailure[
    "CoefficientPresentationConstructionArgumentsInvalid"];

CoefficientPresentationV2Q[presentation_Association,
    sourceVariables : {_Symbol, _Symbol}] := Module[{data},
  data = FeynFacet`Private`masterTransportCoefficientPresentationData[
    presentation, sourceVariables];
  Lookup[data, "Status", None] === "OK" &&
    MemberQ[{"SourceVariableRepresentation",
      "RationalizingParametrization",
      "SquareRootGeneratorsAndQuadraticRelations"},
      Lookup[data, "DataType", None]]
];
CoefficientPresentationV2Q[___] := False;

coefficientPresentationReference[repositoryRoot_String,
    file_String, dataType_String, family_String] := Module[
  {rootParts = FileNameSplit[ExpandFileName[repositoryRoot]],
   fileParts = FileNameSplit[ExpandFileName[file]], path},
  path = If[Length[fileParts] >= Length[rootParts] &&
      Take[fileParts, Length[rootParts]] === rootParts,
    <|"RelativePath" ->
      FileNameJoin[Drop[fileParts, Length[rootParts]]]|>,
    <|"ExplicitPath" -> ExpandFileName[file]|>];
  Join[path, <|"DataType" -> dataType, "SchemaVersion" -> 2,
    "Family" -> family|>]
];

Options[BuildCoefficientPresentationV2] = {
  "RepositoryRoot" -> Automatic,
  "CoefficientVariables" -> Automatic,
  "Overwrite" -> False
};

BuildCoefficientPresentationV2[systemFile_String,
    specificationFile_String, outputFile_String,
    OptionsPattern[]] := Module[
  {root, systemPath, specificationPath, outputPath, system,
   specifications, family, specification, result},
  root = Replace[OptionValue["RepositoryRoot"],
    Automatic :> DirectoryName[ExpandFileName[$InputFileName], 3]];
  If[! StringQ[root] || ! DirectoryQ[ExpandFileName[root]],
    Return[coefficientPresentationFailure["RepositoryRootNotFound"]]];
  root = ExpandFileName[root];
  systemPath = coefficientPresentationResolvePath[root, systemFile];
  specificationPath = coefficientPresentationResolvePath[root,
    specificationFile];
  outputPath = coefficientPresentationResolvePath[root, outputFile];
  If[! FileExistsQ[systemPath] || ! FileExistsQ[specificationPath],
    Return[coefficientPresentationFailure[
      "CoefficientPresentationInputFileMissing"]]];
  If[FileExistsQ[outputPath] && ! TrueQ[OptionValue["Overwrite"]],
    Return[coefficientPresentationFailure[
      "CoefficientPresentationOutputAlreadyExists",
      <|"OutputFile" -> outputPath|>]]];
  system = FeynFacet`FamilyArtifactRead[systemPath];
  specifications = FeynFacet`FamilyArtifactRead[specificationPath];
  If[! coefficientPresentationSystemQ[system] ||
      ! AssociationQ[specifications],
    Return[coefficientPresentationFailure[
      "CoefficientPresentationInputsUnreadable"]]];
  family = system["Family"];
  specification = Lookup[specifications, family,
    Missing["FamilyCoefficientPresentationSpecificationMissing", family]];
  If[MissingQ[specification],
    Return[coefficientPresentationFailure[
      "FamilyCoefficientPresentationSpecificationMissing",
      <|"Family" -> family|>]]];
  result = ConstructCoefficientPresentationV2[system, specification,
    "CoefficientVariables" -> OptionValue["CoefficientVariables"]];
  If[! CoefficientPresentationV2Q[result, system["KinematicVariables"]],
    Return[result]];
  result = Join[result, <|
    "Family" -> family,
    "FamilyDifferentialSystemReference" ->
      coefficientPresentationReference[root, systemPath,
        "FamilyDifferentialSystem", family],
    "CoefficientPresentationSpecificationReference" ->
      coefficientPresentationReference[root, specificationPath,
        "FamilyCoefficientPresentationSpecifications", family]|>];
  If[! DirectoryQ[DirectoryName[outputPath]],
    CreateDirectory[DirectoryName[outputPath],
      CreateIntermediateDirectories -> True]];
  FeynFacet`FamilyArtifactWrite[result, outputPath];
  <|"Status" -> "CoefficientPresentationWritten",
    "Family" -> family, "CoefficientPresentation" -> result,
    "OutputFile" -> outputPath|>
];
BuildCoefficientPresentationV2[___] :=
  coefficientPresentationFailure[
    "CoefficientPresentationBuildArgumentsInvalid"];

End[];
EndPackage[];
