(* Canonical two-variable coefficient representations and exact pullback
   of matrix-valued one-forms.  The live cases distinguish unchanged
   source variables, a rationalizing parametrization, and a presentation
   by an ordered list of square-root generators, each carrying its
   quadratic relation.  Generated V1
   records are refused rather than guessed into a mathematical object. *)

Begin["FeynFacet`Private`"];

ClearAll[
  masterTransportFreeSymbols,
  masterTransportRationalQ,
  masterTransportCoefficientPresentationNormalize,
  masterTransportSourceVariableRepresentationRecordQ,
  masterTransportRationalizingParametrizationRecordQ,
  masterTransportSquareRootGeneratorRelationsRecordQ,
  masterTransportCoefficientPresentationData,
  masterTransportPresentationVariables,
  masterTransportPresentationSubstitution,
  masterTransportPullBackOneForm,
  masterTransportMapTogetherSubstitute,
  masterTransportPullBackSystem
];

(* ------------------------------------------------------------------ *)
(*  Two-variable coefficient-presentation pullback                     *)
(* ------------------------------------------------------------------ *)

(* This layer verifies the forward coordinate map, its nondegenerate
   Jacobian, and the displayed square-root identities before applying the
   chain rule.  It neither chooses analytic branches nor promotes formal
   square-root generators to independent field generators. *)

masterTransportFreeSymbols[expr_] := DeleteDuplicates @ Cases[expr,
  s_Symbol /; Context[s] =!= "System`", {0, Infinity}, Heads -> True];

masterTransportRationalQ[e_, vars_List] := Module[{x},
  x = Together[e];
  If[! FreeQ[x, Power[_, _Rational] | _Root | Log | Hypergeometric2F1],
    Return[False]];
  PolynomialQ[Numerator[x], vars] && PolynomialQ[Denominator[x], vars]
];

(* Generated V1 objects may be regenerated, so an Association is accepted
   only as one of the three discriminated V2 coefficient-presentation
   schemas.  A legacy record is refused typed rather than guessed into a
   mathematical object.  None is also accepted by the resolver as a request
   to construct the unchanged-source-variables record. *)
masterTransportCoefficientPresentationNormalize[input_Association] := Which[
  MemberQ[{"LegacyCoefficientPresentationSchemaUnsupported",
      "CoefficientPresentationSchemaAmbiguous"},
    Lookup[input, "Status", None]],
    <|"Status" -> Lookup[input, "Status"]|>,
  Lookup[input, "DataType", None] === "SourceVariableRepresentation" &&
      Lookup[input, "SchemaVersion", None] === 2 &&
      MatchQ[Lookup[input, "SourceVariables", $Failed],
        {_Symbol, _Symbol}] &&
      MatchQ[Lookup[input, "CoefficientVariables", $Failed],
        {_Symbol, _Symbol}] &&
      MatchQ[Lookup[input, "SourceVariableSubstitution", $Failed],
        {_Rule, _Rule}] &&
      MatrixQ[Lookup[input, "DifferentialPullbackMatrix", $Failed]],
    <|
      "DataType" -> "SourceVariableRepresentation",
      "SchemaVersion" -> 2,
      "Status" -> Lookup[input, "Status", "OK"],
      "SourceVariables" -> input["SourceVariables"],
      "CoefficientVariables" -> input["CoefficientVariables"],
      "SourceVariableSubstitution" -> input["SourceVariableSubstitution"],
      "DifferentialPullbackMatrix" ->
        input["DifferentialPullbackMatrix"],
      "JacobianDeterminant" -> Lookup[input, "JacobianDeterminant", 1]|>,
  KeyExistsQ[input, "RationalizedSquareRoots"] &&
      KeyExistsQ[input, "ParametrizingVariables"] &&
      KeyExistsQ[input, "SourceVariableSubstitution"] &&
      KeyExistsQ[input, "SquareRootGenerators"] &&
      KeyExistsQ[input, "SourceToCoefficientVariableRules"],
    <|"Status" -> "CoefficientPresentationSchemaAmbiguous"|>,
  KeyExistsQ[input, "QuadraticRelations"] ||
      (ListQ[Lookup[input, "SquareRootGenerators", $Failed]] &&
        AnyTrue[input["SquareRootGenerators"], Function[generator,
          AssociationQ[generator] &&
            AnyTrue[{"GeneratorIndex", "GeneratorExpression"},
              KeyExistsQ[generator, #] &]]]),
    <|"Status" -> "LegacyCoefficientPresentationSchemaUnsupported"|>,
  Lookup[input, "DataType", None] === "RationalizingParametrization" &&
      Lookup[input, "SchemaVersion", None] === 2 &&
      MatchQ[Lookup[input, "SourceVariables", $Failed],
        {_Symbol, _Symbol}] &&
      ListQ[Lookup[input, "RationalizedSquareRoots", $Failed]] &&
      KeyExistsQ[input, "ParametrizingVariables"] &&
      KeyExistsQ[input, "SourceVariableSubstitution"],
    Join[<|
      "DataType" -> "RationalizingParametrization",
      "SchemaVersion" -> 2,
      "Status" -> Lookup[input, "Status",
        "RationalizingParametrizationDeclared"],
      "Name" -> Lookup[input, "Name",
        "UnnamedRationalizingParametrization"],
      "Kind" -> Lookup[input, "Kind", "TwoVariable"],
      "SourceVariables" -> Lookup[input, "SourceVariables",
        First /@ input["SourceVariableSubstitution"]],
      "ParametrizingVariables" -> input["ParametrizingVariables"],
      "SourceVariableSubstitution" -> input["SourceVariableSubstitution"],
      "RationalizedSquareRoots" -> Map[
        <|"RationalRoot" -> Lookup[#, "RationalRoot", Missing[]],
          "SourceRadicand" -> Lookup[#, "SourceRadicand", Missing[]]|> &,
        input["RationalizedSquareRoots"]],
      "ParentParametrizationMaps" ->
        Lookup[input, "ParentParametrizationMaps", <||>],
      "ParentParametrizations" ->
        Map[If[AssociationQ[#],
            masterTransportCoefficientPresentationNormalize[#], #] &,
          Lookup[input, "ParentParametrizations", <||>]]|>,
      KeyTake[input, {"InverseParametrizationByRootValues", "Notes"}]],
  Lookup[input, "DataType", None] ===
      "SquareRootGeneratorsAndQuadraticRelations" &&
      Lookup[input, "SchemaVersion", None] === 2 &&
      MatchQ[Lookup[input, "SourceVariables", $Failed],
        {_Symbol, _Symbol}] &&
      MatchQ[Lookup[input, "CoefficientVariables", $Failed],
        {_Symbol, _Symbol}] &&
      ListQ[Lookup[input, "SquareRootGenerators", $Failed]] &&
      KeyExistsQ[input, "SourceToCoefficientVariableRules"],
    Module[{generators},
      generators = Map[
        <|"Generator" -> Lookup[#, "Generator", Missing[]],
          "QuadraticRadicand" ->
            Lookup[#, "QuadraticRadicand", Missing[]],
          "SourceRadicand" -> Lookup[#, "SourceRadicand", Missing[]]|> &,
        input["SquareRootGenerators"]];
      <|
        "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
        "SchemaVersion" -> 2,
        "Status" -> Lookup[input, "Status",
          "SquareRootGeneratorRelationsUnverified"],
        "SourceVariables" -> Lookup[input, "SourceVariables", Missing[]],
        "CoefficientVariables" ->
          Lookup[input, "CoefficientVariables", Missing[]],
        "SourceToCoefficientVariableRules" ->
          input["SourceToCoefficientVariableRules"],
        "SquareRootGenerators" -> generators,
        "SquareClassIndependenceStatus" -> "NotChecked",
        "SquareClassIndependenceVerified" -> False,
        "SignChangeImageInterpretation" ->
          "FormalGeneratorSignChangesOnly",
        "GaloisConjugatesCertified" -> False|>],
  AnyTrue[{"Variables", "Subst", "Roots", "RootSquare", "FieldKind",
      "CoefficientField", "GeneratorOrdering"}, KeyExistsQ[input, #] &] ||
      MemberQ[{"SourceVariableRepresentation",
        "RationalizingParametrization",
        "SquareRootGeneratorsAndQuadraticRelations"},
        Lookup[input, "DataType", None]],
    <|"Status" -> "LegacyCoefficientPresentationSchemaUnsupported"|>,
  True, <|"Status" -> "CoefficientPresentationNotWellFormed"|>
];

masterTransportSourceVariableRepresentationRecordQ[input_] :=
  AssociationQ[input] &&
  Lookup[input, "DataType", None] === "SourceVariableRepresentation" &&
  Lookup[input, "SchemaVersion", None] === 2 &&
  MatchQ[Lookup[input, "SourceVariables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "CoefficientVariables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "SourceVariableSubstitution", $Failed],
    {_Rule, _Rule}] &&
  MatrixQ[Lookup[input, "DifferentialPullbackMatrix", $Failed]];

masterTransportRationalizingParametrizationRecordQ[input_] :=
  AssociationQ[input] &&
  Lookup[input, "DataType", None] === "RationalizingParametrization" &&
  Lookup[input, "SchemaVersion", None] === 2 &&
  MatchQ[Lookup[input, "SourceVariables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "ParametrizingVariables", $Failed],
    {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "SourceVariableSubstitution", $Failed],
    {_Rule, _Rule}] &&
  ListQ[Lookup[input, "RationalizedSquareRoots", $Failed]];

masterTransportSquareRootGeneratorRelationsRecordQ[input_] :=
  AssociationQ[input] &&
  Lookup[input, "DataType", None] ===
    "SquareRootGeneratorsAndQuadraticRelations" &&
  Lookup[input, "SchemaVersion", None] === 2 &&
  MatchQ[Lookup[input, "SourceVariables", $Failed], {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "CoefficientVariables", $Failed],
    {_Symbol, _Symbol}] &&
  MatchQ[Lookup[input, "SourceToCoefficientVariableRules", $Failed],
    {_Rule, _Rule}] &&
  ListQ[Lookup[input, "SquareRootGenerators", $Failed]];

masterTransportPresentationVariables[data_Association] := Switch[
  Lookup[data, "PresentationKind", None],
  "SourceVariables", data["SourceVariables"],
  "RationalizingParametrization", data["ParametrizingVariables"],
  "SquareRootGeneratorsAndQuadraticRelations", data["CoefficientVariables"],
  _, $Failed
];

masterTransportPresentationSubstitution[data_Association] := Switch[
  Lookup[data, "PresentationKind", None],
  "SourceVariables", data["SourceVariableSubstitution"],
  "RationalizingParametrization", data["SourceVariableSubstitution"],
  "SquareRootGeneratorsAndQuadraticRelations",
    data["SourceToCoefficientVariableRules"],
  _, $Failed
];

(* Resolve a live representation against the caller's source symbols.
   The map is re-keyed by SymbolName so records read from a different
   context cannot silently fail to substitute. *)
masterTransportCoefficientPresentationData[input_,
    sourceVariables_List] := Module[
  {presentation, kind, targetVariables, substitution, substitutionNames,
   sourceNames, declaredSourceNames, oldSourceVariables, sourceRules,
   f, g, jacobian, det,
   roots, rootChecks, generators, relationChecks,
   sourceRelationChecks, foreignSymbols},
  If[! MatchQ[sourceVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "SourceVariablesInvalid"|>]];
  If[input === None,
    Return[<|
      "DataType" -> "SourceVariableRepresentation",
      "SchemaVersion" -> 2,
      "Status" -> "OK",
      "PresentationKind" -> "SourceVariables",
      "SourceVariables" -> sourceVariables,
      "CoefficientVariables" -> sourceVariables,
      "SourceVariableSubstitution" ->
        Thread[sourceVariables -> sourceVariables],
      "DifferentialPullbackMatrix" -> IdentityMatrix[2],
      "JacobianDeterminant" -> 1|>]];
  If[! AssociationQ[input],
    Return[<|"Status" -> "CoefficientPresentationNotWellFormed"|>]];
  presentation = masterTransportCoefficientPresentationNormalize[input];
  If[MemberQ[{
      "LegacyCoefficientPresentationSchemaUnsupported",
      "CoefficientPresentationSchemaAmbiguous"},
      Lookup[presentation, "Status", None]],
    Return[presentation]];
  kind = Which[
    masterTransportSourceVariableRepresentationRecordQ[presentation],
      "SourceVariables",
    masterTransportRationalizingParametrizationRecordQ[presentation],
      "RationalizingParametrization",
    masterTransportSquareRootGeneratorRelationsRecordQ[presentation],
      "SquareRootGeneratorsAndQuadraticRelations",
    True, None];
  If[kind === None,
    Return[<|"Status" -> "CoefficientPresentationNotWellFormed"|>]];
  If[kind === "SourceVariables",
    sourceNames = SymbolName /@ sourceVariables[[{1, 2}]];
    If[SymbolName /@ presentation["SourceVariables"] =!= sourceNames ||
        SymbolName /@ presentation["CoefficientVariables"] =!= sourceNames,
      Return[<|"Status" ->
        "SourceVariableRepresentationVariablesMismatch"|>]];
    If[presentation["CoefficientVariables"] =!=
          presentation["SourceVariables"] ||
        presentation["SourceVariableSubstitution"] =!=
          Thread[presentation["SourceVariables"] ->
            presentation["SourceVariables"]] ||
        presentation["DifferentialPullbackMatrix"] =!= IdentityMatrix[2] ||
        Lookup[presentation, "JacobianDeterminant", 1] =!= 1,
      Return[<|"Status" ->
        "SourceVariableRepresentationIdentityFailed"|>]];
    Return[<|
      "DataType" -> "SourceVariableRepresentation",
      "SchemaVersion" -> 2,
      "Status" -> "OK",
      "PresentationKind" -> "SourceVariables",
      "SourceVariables" -> sourceVariables[[{1, 2}]],
      "CoefficientVariables" -> sourceVariables[[{1, 2}]],
      "SourceVariableSubstitution" ->
        Thread[sourceVariables[[{1, 2}]] -> sourceVariables[[{1, 2}]]],
      "DifferentialPullbackMatrix" -> IdentityMatrix[2],
      "JacobianDeterminant" -> 1|>]];
  targetVariables = If[kind === "RationalizingParametrization",
    presentation["ParametrizingVariables"],
    presentation["CoefficientVariables"]];
  substitution = If[kind === "RationalizingParametrization",
    presentation["SourceVariableSubstitution"],
    presentation["SourceToCoefficientVariableRules"]];
  sourceNames = SymbolName /@ sourceVariables[[{1, 2}]];
  declaredSourceNames = SymbolName /@ presentation["SourceVariables"];
  If[declaredSourceNames =!= sourceNames,
    Return[<|"Status" -> "CoefficientPresentationSourceVariablesMismatch",
      "Expected" -> sourceNames, "Found" -> declaredSourceNames|>]];
  substitutionNames = SymbolName /@ (First /@ substitution);
  If[substitutionNames =!= sourceNames,
    Return[<|"Status" -> "CoefficientPresentationSourceVariablesMismatch",
      "Expected" -> sourceNames, "Found" -> substitutionNames|>]];
  If[Length[DeleteDuplicates[
        Join[sourceNames, SymbolName /@ targetVariables]]] =!= 4,
    Return[<|"Status" -> "CoefficientPresentationVariablesCollide"|>]];
  oldSourceVariables = First /@ substitution;
  sourceRules = Thread[oldSourceVariables -> sourceVariables[[{1, 2}]]];
  {f, g} = Together /@ (Last /@ substitution);
  If[! AllTrue[{f, g}, masterTransportRationalQ[#, targetVariables] &],
    Return[<|"Status" -> "CoefficientPresentationMapNotRational"|>]];
  foreignSymbols = Complement[masterTransportFreeSymbols[{f, g}],
    targetVariables];
  If[foreignSymbols =!= {},
    Return[<|"Status" -> "CoefficientPresentationCarriesForeignSymbols",
      "Symbols" -> foreignSymbols|>]];
  substitution = Thread[sourceVariables[[{1, 2}]] -> {f, g}];
  jacobian = Map[Together, {
    {D[f, targetVariables[[1]]], D[f, targetVariables[[2]]]},
    {D[g, targetVariables[[1]]], D[g, targetVariables[[2]]]}}, {2}];
  det = Together[Det[jacobian]];
  If[TrueQ[det === 0],
    Return[<|"Status" -> "CoefficientPresentationJacobianDegenerate"|>]];
  If[kind === "RationalizingParametrization",
    roots = Map[
      <|"RationalRoot" -> #["RationalRoot"],
        "SourceRadicand" -> Together[#["SourceRadicand"] /. sourceRules]|> &,
      presentation["RationalizedSquareRoots"]];
    If[! AllTrue[roots,
        masterTransportRationalQ[#["RationalRoot"], targetVariables] &],
      Return[<|"Status" ->
        "RationalizingParametrizationRootImageNotRational"|>]];
    rootChecks = TrueQ[Together[#["RationalRoot"]^2 -
          (#["SourceRadicand"] /. substitution)] === 0] & /@ roots;
    If[! AllTrue[rootChecks, TrueQ],
      Return[<|"Status" ->
        "RationalizingParametrizationSquareRootIdentityFailed",
        "RationalizedSquareRoots" -> roots|>]];
    Return[Join[<|
      "DataType" -> "RationalizingParametrization",
      "SchemaVersion" -> 2,
      "Status" -> "OK",
      "PresentationKind" -> "RationalizingParametrization",
      "Name" -> Lookup[presentation, "Name", None],
      "Kind" -> Lookup[presentation, "Kind", "TwoVariable"],
      "ParametrizingVariables" -> targetVariables,
      "SourceVariables" -> sourceVariables[[{1, 2}]],
      "SourceVariableSubstitution" -> substitution,
      "DifferentialPullbackMatrix" -> jacobian,
      "JacobianDeterminant" -> det,
      "RationalizedSquareRoots" -> roots,
      "RationalizedSquareRootIdentities" -> rootChecks,
      "ParentParametrizationMaps" ->
        Lookup[presentation, "ParentParametrizationMaps", <||>],
      "ParentParametrizations" ->
        Lookup[presentation, "ParentParametrizations", <||>]|>,
      KeyTake[presentation,
        {"InverseParametrizationByRootValues", "Notes"}]]]];
  generators = Map[
    Function[generator,
      <|"Generator" -> generator["Generator"],
        "QuadraticRadicand" -> generator["QuadraticRadicand"],
        "SourceRadicand" ->
          Together[generator["SourceRadicand"] /. sourceRules]|>],
    presentation["SquareRootGenerators"]];
  If[! AllTrue[generators, AssociationQ[#] &&
      ContainsAll[Keys[#],
        {"Generator", "QuadraticRadicand", "SourceRadicand"}] &],
    Return[<|"Status" -> "SquareRootGeneratorRecordNotWellFormed"|>]];
  relationChecks = TrueQ[Together[#["Generator"]^2 -
        #["QuadraticRadicand"]] === 0] & /@ generators;
  sourceRelationChecks = TrueQ[Together[#["QuadraticRadicand"] -
        (#["SourceRadicand"] /. substitution)] === 0] & /@ generators;
  If[! AllTrue[Join[relationChecks, sourceRelationChecks], TrueQ],
    Return[<|"Status" -> "SquareRootGeneratorRelationVerificationFailed",
      "GeneratorRelations" -> relationChecks,
      "SourceRadicandRelations" -> sourceRelationChecks|>]];
  <|
    "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
    "SchemaVersion" -> 2,
    "Status" -> "OK",
    "PresentationKind" ->
      "SquareRootGeneratorsAndQuadraticRelations",
    "SourceVariables" -> sourceVariables[[{1, 2}]],
    "CoefficientVariables" -> targetVariables,
    "SourceToCoefficientVariableRules" -> substitution,
    "DifferentialPullbackMatrix" -> jacobian,
    "JacobianDeterminant" -> det,
    "SquareRootGenerators" -> generators,
    "QuadraticRelationVerification" -> <|
      "Verified" -> True,
      "PerGenerator" -> relationChecks,
      "SourceRadicandRelations" -> sourceRelationChecks|>,
    "SquareClassIndependenceStatus" -> "NotChecked",
    "SquareClassIndependenceVerified" -> False,
    "SignChangeImageInterpretation" ->
      "FormalGeneratorSignChangesOnly",
    "GaloisConjugatesCertified" -> False|>
];

(* Chain rule for a matrix-valued 1-form.  av, aw are already expressed
   in the coefficient variables; the tangent factors come from the
   Jacobian and are NOT substituted into anything (same discipline as
   masterTransportPathMatrix). *)
masterTransportPullBackOneForm[av_, aw_, jacobian_] := {
  Map[Together, av jacobian[[1, 1]] + aw jacobian[[2, 1]], {2}],
  Map[Together, av jacobian[[1, 2]] + aw jacobian[[2, 2]], {2}]};

(* Substitute and normalize only nonzero connection entries.  When the
   caller owns subkernels, largest entries enter the shared queue first;
   otherwise the identical worker runs serially.  The helper never
   launches kernels, so KernelPool remains the resource authority. *)
masterTransportMapTogetherSubstitute[tensor_List, rules_List] := Module[
  {dimensions, level, positions, entries, uniqueEntries, uniqueIndex,
   entryIndices, order, sorted, transformed, uniqueValues, values, out},
  dimensions = Dimensions[tensor];
  level = Length[dimensions];
  positions = Position[tensor, entry_ /; ! TrueQ[entry === 0], {level},
    Heads -> False];
  If[positions === {}, Return[ConstantArray[0, dimensions]]];
  entries = Extract[tensor, positions];
  (* Exact common-subexpression elimination.  Repeated connection entries
     occur throughout sector assemblies; substituting and Together-ing the
     same expression once per matrix position wastes the dominant stage. *)
  uniqueEntries = DeleteDuplicates[entries];
  uniqueIndex = AssociationThread[uniqueEntries,
    Range[Length[uniqueEntries]]];
  entryIndices = Lookup[uniqueIndex, Key[#]] & /@ entries;
  order = Ordering[ByteCount /@ uniqueEntries, All, Greater];
  sorted = uniqueEntries[[order]];
  transformed = If[$KernelCount > 1 && Length[sorted] > 1,
    ParallelMap[Together[# /. rules] &, sorted,
      Method -> "FinestGrained", DistributedContexts -> None],
    Together[# /. rules] & /@ sorted];
  uniqueValues = transformed[[Ordering[order]]];
  values = uniqueValues[[entryIndices]];
  out = ConstantArray[0, dimensions];
  MapThread[(out[[Sequence @@ #1]] = #2) &, {positions, values}];
  out];

Options[masterTransportPullBackSystem] = {
  "SourceVariables" -> Automatic,
  "FlatnessCheck" -> True
};

masterTransportPullBackSystem[system_Association, presentation_,
    opts : OptionsPattern[]] := Module[
  {sourceVariables, data, av, aw, avc, awc, ax, ay, x, y, flatSource,
   flatPulledBack, surviving, substitution, differentialPullback,
   relationVerification},
  sourceVariables = OptionValue["SourceVariables"];
  If[sourceVariables === Automatic,
    sourceVariables = masterTransportDefaultVariables[]];
  If[! MatchQ[sourceVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "SourceVariablesInvalid"|>]];
  (* Re-derive the map and every displayed relation even when the caller
     supplies an already enriched record.  Status -> "OK" is not itself a
     certificate and must not bypass schema verification. *)
  data = masterTransportCoefficientPresentationData[
    presentation, sourceVariables];
  If[data["Status"] =!= "OK", Return[data]];
  {x, y} = masterTransportPresentationVariables[data];
  substitution = masterTransportPresentationSubstitution[data];
  differentialPullback = data["DifferentialPullbackMatrix"];
  av = Lookup[system, "Av", $Failed];
  aw = Lookup[system, "Aw", $Failed];
  If[! (MatrixQ[av] && MatrixQ[aw] && Dimensions[av] === Dimensions[aw] &&
        Length[av] === Length[First[av]]),
    Return[<|"Status" -> "SystemNotASquareMatrixPair"|>]];
  (* Refuse a non-flat source outright: the chain rule would produce a
     pulled-back system whose own flatness check then fails for an
     unrelated reason. *)
  (* Production checks flatness once, after pullback, in the assembly
     certificate.  Building the same 41x41 curvature before substitution
     was a second full matrix-product pass and dominated CF303. *)
  flatSource = If[masterTransportCheckLevel[] === "Production",
    Missing["DeferredToAssembly"],
    masterTransportZeroMatQ[
      D[av, sourceVariables[[2]]] - D[aw, sourceVariables[[1]]] +
        av . aw - aw . av]];
  If[flatSource === False,
    Return[<|"Status" -> "SourceSystemNotFlat"|>]];
  {avc, awc} = masterTransportMapTogetherSubstitute[
    {av, aw}, substitution];
  surviving = If[data["PresentationKind"] === "SourceVariables", {},
    Cases[{avc, awc},
      s_Symbol /; MemberQ[SymbolName /@ sourceVariables[[{1, 2}]],
        SymbolName[s]],
      {0, Infinity}, Heads -> True]];
  If[surviving =!= {},
    Return[<|"Status" -> "SourceVariablesSurviveSubstitution",
      "Symbols" -> DeleteDuplicates[surviving]|>]];
  {ax, ay} = masterTransportPullBackOneForm[
    avc, awc, differentialPullback];
  flatPulledBack = If[TrueQ[OptionValue["FlatnessCheck"]],
    masterTransportZeroMatQ[D[ax, y] - D[ay, x] + ax . ay - ay . ax],
    "NotPerformed"];
  If[flatPulledBack =!= "NotPerformed" && ! TrueQ[flatPulledBack],
    Return[<|"Status" -> "PulledBackSystemNotFlat"|>]];
  relationVerification = Switch[data["PresentationKind"],
    "SourceVariables", "NotApplicable",
    "RationalizingParametrization",
      AllTrue[data["RationalizedSquareRootIdentities"], TrueQ],
    "SquareRootGeneratorsAndQuadraticRelations",
      TrueQ[data["QuadraticRelationVerification", "Verified"]],
    _, False];
  Join[
    <|"Status" -> "OK",
      "System" -> Join[KeyDrop[system, {"Av", "Aw"}],
        <|"Av" -> ax, "Aw" -> ay|>],
      "Ax" -> ax, "Ay" -> ay,
      "CoefficientVariables" -> {x, y},
      "CoefficientPresentation" -> data|>,
    <|"Certificate" -> <|
      "SourceSystemFlat" -> flatSource,
      "SourceSystemFlatnessRoute" -> If[MissingQ[flatSource],
        "DeferredToAssemblyCertificate", "ExactRationalFunction"],
      "PulledBackSystemFlat" -> flatPulledBack,
      "SourceCoordinateImagesRational" -> True,
      "DisplayedSquareRootRelationsVerified" -> relationVerification,
      "ChainRule" ->
        "Ax = Av d_x v + Aw d_x w, Ay = Av d_y v + Aw d_y w (Together'd)",
      "JacobianDeterminant" -> data["JacobianDeterminant"],
      "Exact" -> True|>|>]
];

End[];
