(* Script-side V2 boundary for the family epsilon-form campaign.

   The sector solver still builds an in-memory working record in the format
   used by its long-running algebra. Nothing in that working record is a
   persisted mathematical result. This file supplies the narrow boundary
   that

     1. accepts a V2 FamilyDifferentialSystem,
     2. validates the completed working result through the package's family
        dlog epsilon-form validator, and
     3. returns only the V2 mathematical fields defined by
        Design/DifferentialEquationDataSchemaV2.md.

   In particular, the constant permutation used internally to put diagonal
   blocks in topological order is absorbed into the basis-transformation
   matrix. The persisted matrix therefore acts on the
   OriginalMasterIntegralBasis in the order stored by the differential
   system; no execution-order field is needed in the result. *)

BeginPackage["FeynFacetCampaign`"];

FamilyDifferentialSystemWorkingViewV2::usage =
  "FamilyDifferentialSystemWorkingViewV2[system] returns the private two-matrix working view of a V2 FamilyDifferentialSystem, or a typed refusal.";

BuildValidatedFamilyDLogEpsilonFormV2::usage =
  "BuildValidatedFamilyDLogEpsilonFormV2[workingResult,system,systemReference,opts] validates a completed in-memory sector-solver result against a V2 FamilyDifferentialSystem and returns a V2 FamilyDLogEpsilonForm. Options are those of ValidateFamilyDLogEpsilonForm.";

Begin["`Private`"];

ClearAll[familyDifferentialSystemV2Data,
  sourceVariableRepresentationV2Q,
  FamilyDifferentialSystemWorkingViewV2,
  BuildValidatedFamilyDLogEpsilonFormV2];

familyDifferentialSystemV2Data[system_Association] := Module[
  {family, variables, regulator, basis, connections, dimension},
  If[Lookup[system, "DataType", None] =!= "FamilyDifferentialSystem" ||
      Lookup[system, "SchemaVersion", None] =!= 2,
    Return[<|"Status" -> "LegacyDifferentialEquationSchemaUnsupported"|>]];
  family = Lookup[system, "Family", Missing["NotGiven"]];
  variables = Lookup[system, "KinematicVariables", $Failed];
  regulator = Lookup[system, "DimensionalRegulator", $Failed];
  basis = Lookup[system, "OriginalMasterIntegralBasis", $Failed];
  connections = Lookup[system, "ConnectionMatrices", $Failed];
  If[! StringQ[family] || ! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[regulator, _Symbol] || ! ListQ[basis] ||
      ! MatchQ[connections, {_List, _List}],
    Return[<|"Status" -> "FamilyDifferentialSystemNotWellFormed"|>]];
  dimension = Length[basis];
  If[dimension < 1 || ! AllTrue[connections,
      MatrixQ[#] && Dimensions[#] === {dimension, dimension} &],
    Return[<|"Status" -> "FamilyDifferentialSystemDimensionsInconsistent",
      "BasisDimension" -> dimension,
      "ConnectionMatrixDimensions" -> Dimensions /@ connections|>]];
  <|"Status" -> "FamilyDifferentialSystemV2Accepted",
    "Family" -> family, "KinematicVariables" -> variables,
    "DimensionalRegulator" -> regulator,
    "OriginalMasterIntegralBasis" -> basis,
    "ConnectionMatrices" -> connections|>
];
familyDifferentialSystemV2Data[_] :=
  <|"Status" -> "FamilyDifferentialSystemNotAssociation"|>;

sourceVariableRepresentationV2Q[presentation_Association,
    sourceVariables_List] :=
  Lookup[presentation, "DataType", None] ===
      "SourceVariableRepresentation" &&
    Lookup[presentation, "SchemaVersion", None] === 2 &&
    Lookup[presentation, "SourceVariables", Missing[]] ===
      sourceVariables &&
    Lookup[presentation, "CoefficientVariables", Missing[]] ===
      sourceVariables &&
    Lookup[presentation, "SourceVariableSubstitution", Missing[]] ===
      Thread[sourceVariables -> sourceVariables] &&
    Lookup[presentation, "DifferentialPullbackMatrix", Missing[]] ===
      IdentityMatrix[Length[sourceVariables]];
sourceVariableRepresentationV2Q[___] := False;

FamilyDifferentialSystemWorkingViewV2[system_Association] := Module[
  {data = familyDifferentialSystemV2Data[system]},
  If[Lookup[data, "Status", None] =!=
      "FamilyDifferentialSystemV2Accepted", Return[data]];
  <|"Status" -> "FamilyDifferentialSystemWorkingViewConstructed",
    "Family" -> data["Family"],
    "Basis" -> data["OriginalMasterIntegralBasis"],
    "BlockBasis" -> data["OriginalMasterIntegralBasis"],
    "Regulator" -> data["DimensionalRegulator"],
    "Av" -> data["ConnectionMatrices"][[1]],
    "Aw" -> data["ConnectionMatrices"][[2]]|>
];
FamilyDifferentialSystemWorkingViewV2[_] :=
  <|"Status" -> "FamilyDifferentialSystemNotAssociation"|>;

Options[BuildValidatedFamilyDLogEpsilonFormV2] =
  Options[FeynFacet`ValidateFamilyDLogEpsilonForm];

BuildValidatedFamilyDLogEpsilonFormV2[
    workingResult_Association, system_Association,
    systemReference_Association, opts : OptionsPattern[]] := Module[
  {data, family, sourceVariables, basis, dimension, referenceValid,
   presentation, validationPresentation, workingSystem, validationOptions,
   validationResult, permutation,
   permutationMatrix, transformation, inverseTransformation, blocks,
   blockDecomposition, validation, retained},
  data = familyDifferentialSystemV2Data[system];
  If[Lookup[data, "Status", None] =!=
      "FamilyDifferentialSystemV2Accepted", Return[data]];
  family = data["Family"];
  sourceVariables = data["KinematicVariables"];
  basis = data["OriginalMasterIntegralBasis"];
  dimension = Length[basis];
  If[Lookup[workingResult, "Family", family] =!= family,
    Return[<|"Status" -> "FamilyDifferentialSystemFamilyMismatch",
      "SystemFamily" -> family,
      "WorkingResultFamily" ->
        Lookup[workingResult, "Family", Missing[]]|>]];
  referenceValid =
    Lookup[systemReference, "DataType", None] ===
        "FamilyDifferentialSystem" &&
      Lookup[systemReference, "SchemaVersion", None] === 2 &&
      Lookup[systemReference, "Family", None] === family &&
      StringQ[Lookup[systemReference, "RelativePath", None]] &&
      StringLength[systemReference["RelativePath"]] > 0;
  If[! referenceValid,
    Return[<|"Status" -> "FamilyDifferentialSystemReferenceInvalid"|>]];
  presentation = Lookup[workingResult, "CoefficientPresentation", None];
  (* The validator's historical internal interface denotes unchanged source
     variables by None.  The V2 campaign may already carry the explicit
     SourceVariableRepresentation, so translate it only at this private
     boundary; the validator emits the explicit V2 presentation again. *)
  validationPresentation = If[
    AssociationQ[presentation] &&
      Lookup[presentation, "DataType", None] ===
        "SourceVariableRepresentation",
    If[! sourceVariableRepresentationV2Q[presentation, sourceVariables],
      Return[<|"Status" -> "SourceVariableRepresentationInvalid",
        "ExpectedSourceVariables" -> sourceVariables,
        "CoefficientPresentation" -> presentation|>]];
    None,
    presentation];
  workingSystem = FamilyDifferentialSystemWorkingViewV2[system];
  validationOptions = DeleteCases[
    FilterRules[{opts}, Options[FeynFacet`ValidateFamilyDLogEpsilonForm]],
    Rule[key_, _] /; MemberQ[
      {"SourceVariables", "CoefficientPresentation"}, key]];
  validationResult = FeynFacet`ValidateFamilyDLogEpsilonForm[
    workingResult, workingSystem,
    "SourceVariables" -> sourceVariables,
    "CoefficientPresentation" -> validationPresentation,
    Sequence @@ validationOptions];
  If[! AssociationQ[validationResult] ||
      Lookup[validationResult, "DataType", None] =!=
        "FamilyDLogEpsilonFormValidationResult" ||
      Lookup[validationResult, "SchemaVersion", None] =!= 2 ||
      Lookup[validationResult, "Status", None] =!=
        "FamilyDLogEpsilonFormValidationPassed",
    Return[<|"Status" -> "FamilyDLogEpsilonFormValidationFailed",
      "ValidationResult" -> validationResult|>]];
  permutation = Lookup[validationResult, "BasisPermutation", Range[dimension]];
  If[! MatchQ[permutation, {__Integer}] ||
      Sort[permutation] =!= Range[dimension],
    Return[<|"Status" -> "BasisPermutationInvalid"|>]];
  permutationMatrix = IdentityMatrix[dimension][[permutation]];
  transformation = Transpose[permutationMatrix] .
    validationResult["BasisTransformationMatrix"];
  inverseTransformation =
    validationResult["CachedInverseBasisTransformationMatrix"] .
      permutationMatrix;
  blocks = validationResult["IrreducibleDiagonalBlocks"];
  blockDecomposition = <|
    "DataType" -> "FamilyDifferentialSystemBlockDecomposition",
    "SchemaVersion" -> 2,
    "FamilyDifferentialSystemReference" -> systemReference,
    "IrreducibleDiagonalBlocks" -> blocks|>;
  validation = validationResult["Validation"];
  retained = KeyTake[validationResult,
    {"Family", "CoefficientPresentation", "CoefficientVariables",
      "DimensionalRegulator", "Letters", "ConstantResidueMatrices",
      "BasisTransformationConvention", "DifferentialEquationConvention"}];
  Join[<|"DataType" -> "FamilyDLogEpsilonForm",
      "SchemaVersion" -> 2|>, retained, <|
    "Status" -> "FamilyDLogEpsilonFormValidated",
    "OriginalMasterIntegralBasis" -> basis,
    "BlockDecomposition" -> blockDecomposition,
    "BasisTransformationMatrix" -> transformation,
    "CachedInverseBasisTransformationMatrix" -> inverseTransformation,
    "Validation" -> validation|>]
];
BuildValidatedFamilyDLogEpsilonFormV2[___] :=
  <|"Status" -> "InvalidFamilyDLogEpsilonFormV2Arguments"|>;

End[];
EndPackage[];
