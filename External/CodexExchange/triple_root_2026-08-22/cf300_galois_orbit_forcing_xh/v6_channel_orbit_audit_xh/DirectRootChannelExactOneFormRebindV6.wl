BeginPackage["CodexDirectRootChannelExactOneFormRebindV6`", {
  "CodexDirectRootChannelAssembler`",
  "CodexTripleRootReconstruction`",
  "CodexTripleRootStrip`"}];

DRCARebindExactOneFormChannels::usage =
  "DRCARebindExactOneFormChannels[assembly,target,appendedChannels] performs a one-form-only ansatz rebind using already-certified exact rational root channels. It verifies that those channels compose to the target suffix, compiles the rational leaves directly, preserves the equation core, and validates the complete assembly ABI without algebraic field decomposition.";

Begin["`Private`"];

ClearAll[
  drceFailure, drceFingerprint, drceZeroQ, drceFormShape,
  drceColumnOrder, drceSemanticPayload, drceCoreCompatibleQ,
  DRCARebindExactOneFormChannels
];

$drceExpectedAssemblerSHA256 =
  "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6";

$drceSemanticKeys = {
  "SourceABIFingerprint", "RootOrderingFingerprint", "RootCount",
  "GradeCount", "Dimensions", "GaugeSupport", "OneForms",
  "GaugeDenominator", "Normalizations", "GaugeUnknownCount",
  "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
  "ColumnOrder", "RowOrder", "ExactChannelFormsFingerprint",
  "CompiledFormsFingerprint", "CompiledFormsShapeFingerprint",
  "SourceSemanticFingerprint", "PrototypeSourceSHA256"};

$drceEquationCoreKeys = {
  "E", "C", "BBar", "RootSquares", "RootLogDerivatives",
  "GaugeDenominator", "GaugeLogDerivatives"};

$drcePreparationCoreKeys = {
  "Record", "Roots", "RootCount", "GradeCount", "Variables",
  "Regulator", "Dimensions", "GaugeSupport", "GaugeDenominator",
  "Normalizations", "GaugeUnknownCount", "EquationsPerPoint",
  "RootOrderingFingerprint"};

drceFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "DirectRootChannelExactOneFormRebindV6Failure",
    "FailureReason" -> reason|>, data];

drceFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

drceZeroQ[value_] := AllTrue[Flatten[{value}],
  TrueQ[Together[#1] === 0] &];

drceFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{
      "DRCARationalExactV1", "DRCARationalPrimeV1",
      "DRCARationalImageV1"}, Lookup[expression, "Type", None]],
    "DRCARationalLeaf",
  AssociationQ[expression], Map[drceFormShape, expression],
  ListQ[expression], drceFormShape /@ expression,
  True, "Scalar"];

drceColumnOrder[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

drceSemanticPayload[assembly_Association] :=
  KeyTake[assembly, $drceSemanticKeys];

drceCoreCompatibleQ[assembly_Association, target_Association] :=
  TrueQ[And @@ (SameQ[Lookup[assembly, #1, $Failed],
      Lookup[target, #1, $Failed]] & /@ $drcePreparationCoreKeys)];

DRCARebindExactOneFormChannels[assembly_Association,
    target_Association, appendedChannels_List] := Module[
  {sourceFile, sourceHash, baseForms, targetForms, suffixForms,
   variables, epsilon, roots, gradeCount, dimensions, support,
   composedSuffix, compiledSuffix, exactForms, compiledForms,
   baseCoreExact, baseCoreCompiled, gaugeUnknownCount,
   residueUnknownCount, unknownCount, result},

  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        assembly],
    Return[drceFailure["InvalidBaseAssembly"]]];
  If[Lookup[target, "Status", None] =!= "PreparedReconstruction" ||
      ! CodexTripleRootReconstruction`TRPreparationABIValidQ[target],
    Return[drceFailure["InvalidTargetPreparation"]]];
  sourceFile = Lookup[assembly, "PrototypeSourceFile", $Failed];
  sourceHash = If[StringQ[sourceFile] && FileExistsQ[sourceFile],
    Quiet[Check[FileHash[sourceFile, "SHA256", "HexString"], $Failed]],
    $Failed];
  If[sourceHash =!= $drceExpectedAssemblerSHA256 ||
      Lookup[assembly, "PrototypeSourceSHA256", $Failed] =!= sourceHash,
    Return[drceFailure["UnpinnedAssemblerSource"]]];
  If[! drceCoreCompatibleQ[assembly, target],
    Return[drceFailure["TargetChangesNonOneFormAnsatzData"]]];

  baseForms = assembly["OneForms"];
  targetForms = target["OneForms"];
  If[! ListQ[baseForms] || ! ListQ[targetForms] ||
      Length[targetForms] < Length[baseForms] ||
      Take[targetForms, Length[baseForms]] =!= baseForms,
    Return[drceFailure["TargetOneFormsAreNotPureSuperset"]]];
  suffixForms = Drop[targetForms, Length[baseForms]];
  variables = assembly["Variables"];
  epsilon = assembly["Regulator"];
  roots = assembly["Roots"];
  gradeCount = assembly["GradeCount"];
  dimensions = assembly["Dimensions"];
  support = assembly["GaugeSupport"];
  If[Dimensions[appendedChannels] =!=
      {Length[suffixForms], 2, gradeCount},
    Return[drceFailure["AppendedChannelShapeInvalid", <|
      "ExpectedDimensions" -> {Length[suffixForms], 2, gradeCount},
      "ObservedDimensions" -> Dimensions[appendedChannels]|>]]];

  composedSuffix = Map[
    CodexTripleRootStrip`TRFieldCompose[#1, roots] &,
    appendedChannels, {2}];
  If[! drceZeroQ[composedSuffix - suffixForms],
    Return[drceFailure["AppendedChannelsDoNotComposeToTargetSuffix"]]];

  (* RATIONAL HOT PATH: compile the certified channel leaves directly.  The
     private compiler is source-pinned above and performs no field
     decomposition or root substitution. *)
  compiledSuffix = Map[
    CodexDirectRootChannelAssembler`Private`drcaCompileRational[
      #1, variables, epsilon] &,
    appendedChannels, {3}];
  If[! FreeQ[compiledSuffix, $Failed] ||
      Dimensions[compiledSuffix] =!= Dimensions[appendedChannels],
    Return[drceFailure["DirectRationalChannelCompilationFailed"]]];

  exactForms = assembly["ExactChannelForms"];
  compiledForms = assembly["CompiledForms"];
  baseCoreExact = KeyTake[exactForms, $drceEquationCoreKeys];
  baseCoreCompiled = KeyTake[compiledForms, $drceEquationCoreKeys];
  exactForms = ReplacePart[exactForms,
    "OneForms" -> Join[exactForms["OneForms"], appendedChannels]];
  compiledForms = ReplacePart[compiledForms,
    "OneForms" -> Join[compiledForms["OneForms"], compiledSuffix]];
  If[KeyTake[exactForms, $drceEquationCoreKeys] =!= baseCoreExact ||
      KeyTake[compiledForms, $drceEquationCoreKeys] =!= baseCoreCompiled,
    Return[drceFailure["EquationCoreChangedDuringExactChannelRebind"]]];

  gaugeUnknownCount = Times @@ dimensions gradeCount Length[support];
  residueUnknownCount = Length[targetForms] Times @@ dimensions;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  If[gaugeUnknownCount =!= target["GaugeUnknownCount"] ||
      residueUnknownCount =!= target["ResidueUnknownCount"] ||
      unknownCount =!= target["UnknownCount"] ||
      target["EquationsPerPoint"] =!=
        gradeCount 2 Times @@ dimensions,
    Return[drceFailure["TargetUnknownCountContractInvalid"]]];

  result = ReplacePart[assembly, {
    "SourceABIFingerprint" -> target["ABIFingerprint"],
    "OneForms" -> targetForms,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "ColumnOrder" -> drceColumnOrder[
      dimensions, gradeCount, support, Length[targetForms]],
    "ExactChannelForms" -> exactForms,
    "CompiledForms" -> compiledForms,
    "ExactChannelFormsFingerprint" -> drceFingerprint[exactForms],
    "CompiledFormsFingerprint" -> drceFingerprint[compiledForms],
    "CompiledFormsShapeFingerprint" ->
      drceFingerprint[drceFormShape[compiledForms]]}];
  result = ReplacePart[result,
    "AssemblyFingerprint" ->
      drceFingerprint[drceSemanticPayload[result]]];

  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        result] ||
      result["SourceABIFingerprint"] =!= target["ABIFingerprint"] ||
      result["OneForms"] =!= targetForms ||
      result["UnknownCount"] =!= target["UnknownCount"] ||
      KeyTake[result["ExactChannelForms"], $drceEquationCoreKeys] =!=
        baseCoreExact ||
      KeyTake[result["CompiledForms"], $drceEquationCoreKeys] =!=
        baseCoreCompiled,
    Return[drceFailure["ExactChannelReboundAssemblyValidationFailed"]]];
  Append[result, "ExactOneFormChannelRebindV6" -> <|
    "Status" -> "ExactOneFormChannelRebindV6",
    "AppendedOneFormCount" -> Length[suffixForms],
    "AppendedChannelDimensions" -> Dimensions[appendedChannels],
    "AlgebraicFieldDecompositionCalls" -> 0,
    "AlgebraicRootBranchSubstitutions" -> 0,
    "EquationCorePreservedExactly" -> True|>]
];

DRCARebindExactOneFormChannels[___] :=
  drceFailure["InvalidExactChannelRebindArguments"];

End[];
EndPackage[];
