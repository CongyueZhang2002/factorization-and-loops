BeginPackage["CodexDirectRootChannelAnsatzRebind`", {
  "CodexDirectRootChannelAssembler`",
  "CodexTripleRootReconstruction`"}];

DRCARebindAnsatz::usage =
  "DRCARebindAnsatz[assembly,targetPreparation] reuses a validated direct-channel equation core while changing only support, a pure-superset one-form list, and/or the gauge denominator. It compiles only appended one-forms and changed denominator data, then rebuilds and validates the complete assembly ABI.";

DRCARebindCompatibility::usage =
  "DRCARebindCompatibility[assembly,targetPreparation] returns a fail-closed description of which ansatz-only fields can be rebound without recompiling E, C, BBar, or root data.";

Begin["`Private`"];

ClearAll[
  drarFailure, drarFingerprint, drarFormShape, drarColumnOrder,
  drarSemanticPayload, drarSourcePinnedQ, drarCoreCompatibleQ,
  drarCompileTensor, drarChangedQ
];

$drarExpectedAssemblerSHA256 =
  "227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6";

$drarSemanticKeys = {
  "SourceABIFingerprint", "RootOrderingFingerprint", "RootCount",
  "GradeCount", "Dimensions", "GaugeSupport", "OneForms",
  "GaugeDenominator", "Normalizations", "GaugeUnknownCount",
  "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
  "ColumnOrder", "RowOrder", "ExactChannelFormsFingerprint",
  "CompiledFormsFingerprint", "CompiledFormsShapeFingerprint",
  "SourceSemanticFingerprint", "PrototypeSourceSHA256"};

$drarEquationCoreKeys = {
  "E", "C", "BBar", "RootSquares", "RootLogDerivatives"};

$drarPreparationCoreKeys = {
  "Record", "Roots", "RootCount", "GradeCount", "Variables",
  "Regulator", "Dimensions", "Normalizations",
  "RootOrderingFingerprint"};

drarFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "DirectRootChannelAnsatzRebindFailure",
    "FailureReason" -> reason|>, data];

drarFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

drarChangedQ[left_, right_] := ! SameQ[left, right];

drarFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{
      "DRCARationalExactV1", "DRCARationalPrimeV1",
      "DRCARationalImageV1"}, Lookup[expression, "Type", None]],
    "DRCARationalLeaf",
  AssociationQ[expression], Map[drarFormShape, expression],
  ListQ[expression], drarFormShape /@ expression,
  True, "Scalar"];

drarColumnOrder[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

drarSemanticPayload[assembly_Association] :=
  KeyTake[assembly, $drarSemanticKeys];

drarSourcePinnedQ[assembly_Association] := Module[
  {source = Lookup[assembly, "PrototypeSourceFile", $Failed],
   stored = Lookup[assembly, "PrototypeSourceSHA256", $Failed],
   observed},
  observed = If[StringQ[source] && FileExistsQ[source],
    Quiet[Check[FileHash[source, "SHA256", "HexString"], $Failed]],
    $Failed];
  TrueQ[stored === $drarExpectedAssemblerSHA256 &&
    observed === stored]
];

drarCoreCompatibleQ[assembly_Association,
    target_Association] := Module[{baseOneForms, targetOneForms},
  baseOneForms = Lookup[assembly, "OneForms", $Failed];
  targetOneForms = Lookup[target, "OneForms", $Failed];
  TrueQ[
    And @@ (SameQ[Lookup[assembly, #1, $Failed],
          Lookup[target, #1, $Failed]] & /@ $drarPreparationCoreKeys) &&
    ListQ[baseOneForms] && ListQ[targetOneForms] &&
    Length[targetOneForms] >= Length[baseOneForms] &&
    Take[targetOneForms, Length[baseOneForms]] === baseOneForms]
];

drarCompileTensor[tensor_, scalarLevel_Integer, roots_List,
    variables_List, epsilon_Symbol] := Quiet[Check[
  CodexDirectRootChannelAssembler`Private`drcaCompileTensor[
    tensor, scalarLevel, roots, variables, epsilon], $Failed]];

DRCARebindCompatibility[assembly_Association,
    target_Association] := Module[
  {baseForms, targetForms, suffix, changedDenominator, changedSupport},
  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        assembly], Return[drarFailure["InvalidBaseAssembly"]]];
  If[! drarSourcePinnedQ[assembly],
    Return[drarFailure["UnpinnedAssemblerSource", <|
      "ExpectedAssemblerSHA256" -> $drarExpectedAssemblerSHA256,
      "ObservedAssemblerSHA256" ->
        Lookup[assembly, "PrototypeSourceSHA256", Missing["Absent"]]|>]]];
  If[Lookup[target, "Status", None] =!= "PreparedReconstruction" ||
      ! CodexTripleRootReconstruction`TRPreparationABIValidQ[target],
    Return[drarFailure["InvalidTargetPreparation"]]];
  If[! drarCoreCompatibleQ[assembly, target],
    Return[drarFailure[
      "TargetChangesEquationCoreOrOneFormsAreNotPureSuperset"]]];
  baseForms = assembly["OneForms"];
  targetForms = target["OneForms"];
  suffix = Drop[targetForms, Length[baseForms]];
  changedDenominator = drarChangedQ[
    Together[assembly["GaugeDenominator"]],
    Together[target["GaugeDenominator"]]];
  changedSupport = drarChangedQ[
    assembly["GaugeSupport"], target["GaugeSupport"]];
  <|"Status" -> "DirectRootChannelAnsatzRebindCompatibleV1",
    "BaseSourceABIFingerprint" -> assembly["SourceABIFingerprint"],
    "TargetSourceABIFingerprint" -> target["ABIFingerprint"],
    "SupportChanged" -> changedSupport,
    "GaugeDenominatorChanged" -> changedDenominator,
    "BaseOneFormCount" -> Length[baseForms],
    "AppendedOneFormCount" -> Length[suffix],
    "TargetOneFormCount" -> Length[targetForms],
    "ReusedCompiledEquationCoreKeys" -> $drarEquationCoreKeys,
    "RequiredCompilation" -> DeleteCases[{
      If[suffix === {}, Nothing, "AppendedOneFormsOnly"],
      If[changedDenominator, "GaugeDenominatorAndDLogOnly", Nothing]},
      Nothing]|>
];

DRCARebindCompatibility[___] :=
  drarFailure["InvalidCompatibilityArguments"];

DRCARebindAnsatz[assembly_Association,
    target_Association] := Module[
  {compatibility, baseForms, targetForms, suffix, variables, epsilon,
   roots, changedDenominator, suffixData, denominatorData,
   denominatorLogData, exactForms, compiledForms, dimensions,
   gradeCount, support, gaugeUnknownCount, residueUnknownCount,
   unknownCount, result, baseCoreExact, baseCoreCompiled},

  compatibility = DRCARebindCompatibility[assembly, target];
  If[Lookup[compatibility, "Status", None] =!=
      "DirectRootChannelAnsatzRebindCompatibleV1",
    Return[compatibility]];

  baseForms = assembly["OneForms"];
  targetForms = target["OneForms"];
  suffix = Drop[targetForms, Length[baseForms]];
  variables = assembly["Variables"];
  epsilon = assembly["Regulator"];
  roots = assembly["Roots"];
  changedDenominator = TrueQ[
    compatibility["GaugeDenominatorChanged"]];
  exactForms = assembly["ExactChannelForms"];
  compiledForms = assembly["CompiledForms"];
  baseCoreExact = KeyTake[exactForms, $drarEquationCoreKeys];
  baseCoreCompiled = KeyTake[compiledForms, $drarEquationCoreKeys];

  If[suffix =!= {},
    suffixData = drarCompileTensor[
      suffix, 2, roots, variables, epsilon];
    If[! AssociationQ[suffixData] ||
        ! AllTrue[{"Channels", "Compiled"},
          KeyExistsQ[suffixData, #1] &] ||
        ! FreeQ[suffixData, $Failed] ||
        Length[suffixData["Channels"]] =!= Length[suffix] ||
        Length[suffixData["Compiled"]] =!= Length[suffix],
      Return[drarFailure["AppendedOneFormCompilationFailed"]]];
    exactForms = ReplacePart[exactForms,
      "OneForms" -> Join[exactForms["OneForms"],
        suffixData["Channels"]]];
    compiledForms = ReplacePart[compiledForms,
      "OneForms" -> Join[compiledForms["OneForms"],
        suffixData["Compiled"]]];
  ];

  If[changedDenominator,
    denominatorData = drarCompileTensor[
      {target["GaugeDenominator"]}, 1, {}, variables, epsilon];
    denominatorLogData = drarCompileTensor[{
        D[target["GaugeDenominator"], variables[[1]]] /
          target["GaugeDenominator"],
        D[target["GaugeDenominator"], variables[[2]]] /
          target["GaugeDenominator"]},
      1, {}, variables, epsilon];
    If[! AssociationQ[denominatorData] ||
        ! AssociationQ[denominatorLogData] ||
        ! FreeQ[{denominatorData, denominatorLogData}, $Failed] ||
        Length[denominatorData["Channels"]] =!= 1 ||
        Length[denominatorLogData["Channels"]] =!= 2,
      Return[drarFailure["GaugeDenominatorCompilationFailed"]]];
    exactForms = ReplacePart[exactForms, {
      "GaugeDenominator" ->
        First[First[denominatorData["Channels"]]],
      "GaugeLogDerivatives" ->
        (First /@ denominatorLogData["Channels"])}];
    compiledForms = ReplacePart[compiledForms, {
      "GaugeDenominator" ->
        First[First[denominatorData["Compiled"]]],
      "GaugeLogDerivatives" ->
        (First /@ denominatorLogData["Compiled"])}];
  ];

  If[KeyTake[exactForms, $drarEquationCoreKeys] =!= baseCoreExact ||
      KeyTake[compiledForms, $drarEquationCoreKeys] =!= baseCoreCompiled,
    Return[drarFailure["EquationCoreChangedDuringRebind"]]];

  dimensions = target["Dimensions"];
  gradeCount = target["GradeCount"];
  support = target["GaugeSupport"];
  gaugeUnknownCount = Times @@ dimensions gradeCount Length[support];
  residueUnknownCount = Length[targetForms] Times @@ dimensions;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  If[gaugeUnknownCount =!= target["GaugeUnknownCount"] ||
      residueUnknownCount =!= target["ResidueUnknownCount"] ||
      unknownCount =!= target["UnknownCount"] ||
      target["EquationsPerPoint"] =!=
        gradeCount 2 Times @@ dimensions,
    Return[drarFailure["TargetUnknownCountContractInvalid"]]];

  result = ReplacePart[assembly, {
    "SourceABIFingerprint" -> target["ABIFingerprint"],
    "GaugeSupport" -> support,
    "OneForms" -> targetForms,
    "GaugeDenominator" -> Together[target["GaugeDenominator"]],
    "Normalizations" -> target["Normalizations"],
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> target["EquationsPerPoint"],
    "ColumnOrder" -> drarColumnOrder[
      dimensions, gradeCount, support, Length[targetForms]],
    "ExactChannelForms" -> exactForms,
    "CompiledForms" -> compiledForms,
    "ExactChannelFormsFingerprint" -> drarFingerprint[exactForms],
    "CompiledFormsFingerprint" -> drarFingerprint[compiledForms],
    "CompiledFormsShapeFingerprint" ->
      drarFingerprint[drarFormShape[compiledForms]]}];
  result = ReplacePart[result,
    "AssemblyFingerprint" ->
      drarFingerprint[drarSemanticPayload[result]]];

  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
        result] ||
      result["SourceABIFingerprint"] =!= target["ABIFingerprint"] ||
      result["GaugeSupport"] =!= target["GaugeSupport"] ||
      result["OneForms"] =!= target["OneForms"] ||
      ! SameQ[result["GaugeDenominator"],
        Together[target["GaugeDenominator"]]] ||
      result["UnknownCount"] =!= target["UnknownCount"] ||
      KeyTake[result["ExactChannelForms"], $drarEquationCoreKeys] =!=
        baseCoreExact ||
      KeyTake[result["CompiledForms"], $drarEquationCoreKeys] =!=
        baseCoreCompiled,
    Return[drarFailure["ReboundAssemblyValidationFailed"]]];
  result
];

DRCARebindAnsatz[___] := drarFailure["InvalidRebindArguments"];

End[];
EndPackage[];
