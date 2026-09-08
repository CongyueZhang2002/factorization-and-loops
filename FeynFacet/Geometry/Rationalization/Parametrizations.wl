(* Verification, matching and composition of rational coordinate maps. *)
(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[
  FeynFacet`RationalizingParametrizationCatalog,
  FeynFacet`VerifyRationalizingParametrization,
  FeynFacet`LookupCataloguedRationalizingParametrizationForRoots,
  FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations,
  FeynFacet`ComposeRationalizingParametrizations,
  FeynFacet`ExtendRationalizingParametrization,
  FeynFacet`RegisterFamilyRootData,
  FeynFacet`LoadFamilyRootData,
  FeynFacet`FamilyRootData,
  FeynFacet`FamilySquareRootGeneratorCensus
];
ClearAll[
  rationalizingParametrizationCatalogDefinitions,
  rationalizingParametrizationCatalogRecord,
  rationalizingParametrizationNormalize,
  rationalizingParametrizationRekey,
  squareRootGeneratorDataNormalize,
  masterTransportRationalizingParametrizationByName,
  masterTransportComposeTwoVariableRecord,
  masterTransportRecordCoordinateMap,
  familyCoefficientPresentationFromRecord,
  transportChartRationalExpressionQ,
  transportChartLoadRationalizeRoots,
  transportChartExtensionCandidates,
  familyRootDataEntryNormalize,
  familyRootDataEntryKind
];

FeynFacet`RationalizingParametrizationCatalog::usage =
  "RationalizingParametrizationCatalog[] returns the catalogued forward rational parametrizations together with their displayed rationalized square roots. VerifyRationalizingParametrization re-derives the stated identities; catalog membership alone is not a birationality or nonexistence claim.";

FeynFacet`VerifyRationalizingParametrization::usage =
  "VerifyRationalizingParametrization[parametrization] verifies rationality of the forward substitution and rationalized roots, the square-root identities, a nonzero Jacobian, and declared parent compositions. It does not certify a rational inverse or birationality.";

FeynFacet`LookupCataloguedRationalizingParametrizationForRoots::usage =
  "LookupCataloguedRationalizingParametrizationForRoots[rootSquares] returns the least complicated catalogued rationalizing parametrization containing the requested radicands, or Missing[\"NoCataloguedRationalizingParametrization\",...] when the catalog has no such entry. A miss is not a nonexistence result.";

FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations::usage =
  "BuildSquareRootGeneratorsAndQuadraticRelations[rootSquares,{v,w},{x,y}] records explicit square-root generators after the identity variable substitution and verifies only their quadratic relations. It does not assert square-class independence, a function field, or Galois conjugacy.";

FeynFacet`ComposeRationalizingParametrizations::usage =
  "ComposeRationalizingParametrizations[base,rootSquare,rules,newVariables] composes a verified forward rationalizing parametrization with a rational parametrization of one additional square root and re-verifies the resulting forward map.";

FeynFacet`ExtendRationalizingParametrization::usage =
  "ExtendRationalizingParametrization[base,rootSquare] asks RationalizeRoots for forward rational parametrizations of the pulled-back root and returns the least complicated verified result. Failure to find one is not a nonexistence theorem.";



(* the source variables and the chart variables, by NAME; callers
   re-key by SymbolName as everywhere in this module *)
$transportChartV = Symbol["Global`v"];
$transportChartW = Symbol["Global`w"];
$transportChartX = Symbol["Global`x"];
$transportChartY = Symbol["Global`y"];
$transportChartS = Symbol["Global`s"];
$transportChartU = Symbol["Global`u"];
$transportChartP = Symbol["Global`p"];
(* the second parameter of the iterated pencil (KallenQ4a/b); "tau" in
   the derivation note, kept short to match the rest of the catalog *)
$transportChartT = Symbol["Global`t"];

transportChartLambda1[v_, w_] := (1 - v - w)^2 - 4 v w;
transportChartLambda2[v_, w_] := transportChartLambda1[-v, w];
transportChartLambda3[v_, w_] := transportChartLambda1[v, -w];

(* Catalog definitions already use the V2 mathematical field names.  This
   constructor adds the common discriminator and source-variable data once;
   it is not a reader for historical artifacts. *)
rationalizingParametrizationCatalogRecord[definition_Association] := Join[
  <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationDeclared",
    "SourceVariables" ->
      First /@ definition["SourceVariableSubstitution"],
    "ParentParametrizations" -> <||>|>,
  definition];

rationalizingParametrizationNormalize[record_Association] := Module[
  {normalized = algebraCoefficientPresentationNormalize[record]},
  If[Lookup[normalized, "DataType", None] =!=
      "RationalizingParametrization",
    Return[normalized]];
  Join[normalized, KeyTake[record,
    {"ParametrizationExtensionData",
     "RationalizingParametrizationVerification"}]]
];

FeynFacet`RationalizingParametrizationCatalog[] :=
  Join[Map[rationalizingParametrizationCatalogRecord,
    rationalizingParametrizationCatalogDefinitions[]],
    $additionalRationalizingParametrizations];

masterTransportRationalizingParametrizationByName[name_String] :=
  Lookup[FeynFacet`RationalizingParametrizationCatalog[], name, None];

(* Resolve a record's coefficient presentation against the catalog.
   A source-coordinate representation does not require a chart. *)
familyCoefficientPresentationFromRecord[record_Association,
    Automatic] := Lookup[record, "CoefficientPresentation", None];

familyCoefficientPresentationFromRecord[record_Association,
    presentation_] := presentation;

(* Re-derive exactly what a forward rationalizing parametrization proves.
   Rationality of both the source-coordinate images and the displayed root
   images is part of the gate.  No inverse is checked here, so neither the
   result nor its status uses "change of variables", "birational", or
   "chart". *)
FeynFacet`VerifyRationalizingParametrization[input_Association] := Module[
  {parametrization, vars, subst, sourceVariables, f, g, jac, det, roots,
   substitutionRationalChecks, rootRationalChecks, rootChecks, parentMaps,
  parentParametrizations, parentChecks, verified},
  parametrization = rationalizingParametrizationNormalize[input];
  If[Lookup[parametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[Join[parametrization, <|"Verified" -> False|>]]];
  vars = parametrization["ParametrizingVariables"];
  subst = parametrization["SourceVariableSubstitution"];
  roots = parametrization["RationalizedSquareRoots"];
  If[! MatchQ[vars, {_Symbol, _Symbol}] ||
      ! MatchQ[subst, {_Rule, _Rule}] || ! ListQ[roots],
    Return[<|"Status" -> "RationalizingParametrizationNotWellFormed",
      "Verified" -> False|>]];
  sourceVariables = First /@ subst;
  {f, g} = Together /@ (Last /@ subst);
  substitutionRationalChecks =
    transportChartRationalExpressionQ[#, vars] & /@ {f, g};
  rootRationalChecks =
    transportChartRationalExpressionQ[#1["RationalRoot"], vars] & /@ roots;
  jac = {{D[f, vars[[1]]], D[f, vars[[2]]]},
    {D[g, vars[[1]]], D[g, vars[[2]]]}};
  det = Together[Det[jac]];
  rootChecks = Table[
    TrueQ[Together[root["RationalRoot"]^2 -
      (root["SourceRadicand"] /.
        Thread[sourceVariables -> {f, g}])] === 0],
    {root, roots}];
  parentMaps = parametrization["ParentParametrizationMaps"];
  parentParametrizations = parametrization["ParentParametrizations"];
  parentChecks = Association @ KeyValueMap[
    Function[{parentName, map},
      Module[{parent = Lookup[parentParametrizations, parentName,
          masterTransportRationalizingParametrizationByName[parentName]],
        parentSubstitution, pf, pg},
        If[parent === None || ! AssociationQ[parent], parentName -> False,
          parent = rationalizingParametrizationNormalize[parent];
          parentSubstitution = parent["SourceVariableSubstitution"];
          If[! MatchQ[parentSubstitution, {_Rule, _Rule}],
            parentName -> False,
            {pf, pg} = Last /@ parentSubstitution;
            parentName ->
              (TrueQ[Together[(pf /. map) - f] === 0] &&
               TrueQ[Together[(pg /. map) - g] === 0])]]]],
    parentMaps];
  verified = AllTrue[substitutionRationalChecks, TrueQ] &&
    AllTrue[rootRationalChecks, TrueQ] &&
    AllTrue[rootChecks, TrueQ] && ! TrueQ[det === 0] &&
    AllTrue[Values[parentChecks], TrueQ];
  <|
    "DataType" -> "RationalizingParametrizationValidation",
    "SchemaVersion" -> 2,
    "Status" -> If[verified, "RationalizingParametrizationVerified",
      "RationalizingParametrizationVerificationFailed"],
    "Verified" -> verified,
    "Name" -> Lookup[parametrization, "Name", "?"],
    "SourceCoordinateImagesRational" -> substitutionRationalChecks,
    "RationalizedRootImagesRational" -> rootRationalChecks,
    "RationalizedSquareRootIdentities" -> rootChecks,
    "JacobianDeterminant" -> Factor[det],
    "ParentParametrizationIdentities" -> parentChecks,
    "RationalInverseVerified" -> False,
    "BirationalityVerified" -> False
  |>
];
FeynFacet`VerifyRationalizingParametrization[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationArguments",
    "Verified" -> False|>;

FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
    rootSquares_List, sourceVariables : {_Symbol, _Symbol},
    coefficientVariables : {_Symbol, _Symbol}] := Module[
  {substitution, pulledSquares, generators, relationChecks,
   jacobianDeterminant, verified},
  If[Length[DeleteDuplicates[SymbolName /@
        Join[sourceVariables, coefficientVariables]]] =!= 4,
    Return[<|"Status" -> "SquareRootGeneratorVariablesCollide"|>]];
  substitution = Thread[sourceVariables -> coefficientVariables];
  pulledSquares = Together /@ (rootSquares /. substitution);
  generators = MapThread[
    <|
      "Generator" -> Sqrt[#1],
      "QuadraticRadicand" -> #1,
      "SourceRadicand" -> #2
    |> &,
    {pulledSquares, rootSquares}];
  relationChecks = TrueQ[Together[
      #1["Generator"]^2 - #1["QuadraticRadicand"]] === 0] & /@
    generators;
  jacobianDeterminant = Together@Det@Table[
    D[Last[substitution[[i]]], coefficientVariables[[j]]],
    {i, 2}, {j, 2}];
  verified = AllTrue[relationChecks, TrueQ] &&
    ! TrueQ[jacobianDeterminant === 0];
  <|
    "DataType" -> "SquareRootGeneratorsAndQuadraticRelations",
    "SchemaVersion" -> 2,
    "Status" -> If[verified, "SquareRootGeneratorRelationsVerified",
      "SquareRootGeneratorRelationVerificationFailed"],
    "SourceVariables" -> sourceVariables,
    "CoefficientVariables" -> coefficientVariables,
    "SourceToCoefficientVariableRules" -> substitution,
    "SquareRootGenerators" -> generators,
    "QuadraticRelationVerification" -> <|
      "Verified" -> verified,
      "PerGenerator" -> relationChecks,
      "CoordinateJacobianDeterminant" -> Factor[jacobianDeterminant]|>,
    "SquareClassIndependenceStatus" -> "NotChecked",
    "SquareClassIndependenceVerified" -> False,
    "SignChangeImageInterpretation" -> "FormalGeneratorSignChangesOnly",
    "GaloisConjugatesCertified" -> False
  |>
];
FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[___] :=
  <|"Status" -> "InvalidSquareRootGeneratorArguments"|>;

(* The family census accepts only the canonical V2 generator presentation.
   V1 records are refused typed rather than normalized into a guessed
   mathematical object. *)
squareRootGeneratorDataNormalize[data_Association] := If[
  Lookup[data, "DataType", None] ===
      "SquareRootGeneratorsAndQuadraticRelations" &&
    Lookup[data, "SchemaVersion", None] === 2 &&
    ListQ[Lookup[data, "SquareRootGenerators", $Failed]] &&
    KeyExistsQ[data, "SourceToCoefficientVariableRules"],
  algebraCoefficientPresentationNormalize[data],
  <|"Status" -> "LegacyCoefficientPresentationSchemaUnsupported"|>];

FeynFacet`FamilySquareRootGeneratorCensus[assembly_Association,
    generatorData_Association] := Module[
  {normalizedData, generatorRecords, zeroBlockQ, blocks, ranges,
   connection, records, unmatched},
  If[Lookup[assembly, "Status", None] =!= "OK" ||
      ! ListQ[Lookup[assembly, "Blocks", None]] ||
      ! ListQ[Lookup[assembly, "Ranges", None]],
    Return[<|"Status" -> "FamilyAssemblyInvalid"|>]];
  normalizedData = squareRootGeneratorDataNormalize[generatorData];
  If[Lookup[normalizedData, "Status", None] ===
      "LegacyCoefficientPresentationSchemaUnsupported",
    Return[normalizedData]];
  generatorRecords = Lookup[normalizedData, "SquareRootGenerators", $Failed];
  If[! ListQ[generatorRecords],
    Return[<|"Status" -> "SquareRootGeneratorDataInvalid"|>]];
  zeroBlockQ[expr_] := AllTrue[Flatten[expr],
    TrueQ[Together[#] === 0] &];
  blocks = assembly["Blocks"];
  ranges = assembly["Ranges"];
  connection = {assembly["Apv"], assembly["Apw"]};
  records = Flatten[Table[
    If[i > j,
      Module[{block, classification},
        block = connection[[All, ranges[[i]], ranges[[j]]]];
        If[zeroBlockQ[block], Nothing,
          classification = transportChartRootIndices[
            block, generatorRecords];
          <|"BlockPair" -> {i, j},
            "FamilyRows" -> {blocks[[i]], blocks[[j]]},
            "SquareRootGeneratorIndices" -> classification["RootIndices"],
            "SquareRootGeneratorCount" ->
              Length[classification["RootIndices"]],
            "RadicalBases" -> classification["RadicalBases"],
            "UnclassifiedRadicalBases" ->
              classification["UnclassifiedRadicalBases"],
            "DenestedRadicalBases" ->
              Keys[Lookup[classification, "DenestedRadicalBases", <||>]],
            "NumericRadicalClasses" ->
              Lookup[classification, "NumericRadicalClasses", {}]|>]],
      Nothing],
    {i, Length[blocks]}, {j, Length[blocks]}], 1];
  unmatched = DeleteDuplicates[Flatten[
    Lookup[records, "UnclassifiedRadicalBases", {}]]];
  <|"Status" -> If[unmatched === {},
      "ExactSquareRootGeneratorCensus",
      "UnclassifiedRadicals"],
    "Family" -> Lookup[assembly, "Family", None],
    "SourceRadicands" -> Lookup[generatorRecords, "SourceRadicand", {}],
    "NonzeroOffDiagonalBlocks" -> Length[records],
    "SquareRootGeneratorCountHistogram" ->
      Counts[Lookup[records, "SquareRootGeneratorCount", {}]],
    "MaximumSquareRootGeneratorCount" ->
      Max[Append[Lookup[records, "SquareRootGeneratorCount", {}], 0]],
    "BlocksWithAtLeastThreeSquareRootGenerators" ->
      Select[records, #["SquareRootGeneratorCount"] >= 3 &],
    "UnclassifiedRadicalBases" -> unmatched,
    (* radicands accepted by exact denesting rather than by a direct
       match (2026-08-24): classified, but not literally declared *)
    "DenestedRadicalBases" -> DeleteDuplicates[Flatten[
      Lookup[records, "DenestedRadicalBases", {}]]],
    "NumericRadicalClasses" -> DeleteDuplicates[Flatten[
      Lookup[records, "NumericRadicalClasses", {}]]],
    "Blocks" -> records|>
];

FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
    rootSquares_List,
    sourceVariables : {_Symbol, _Symbol}] := Module[
  {wanted, candidates},
  wanted = DeleteDuplicates[Together /@
    (rootSquares /. Thread[sourceVariables ->
      {$transportChartV, $transportChartW}])];
  If[wanted === {}, Return[None]];
  candidates = Select[
    Values[FeynFacet`RationalizingParametrizationCatalog[]],
    Function[parametrization,
    Module[{rationalizedRoots = Lookup[parametrization,
        "RationalizedSquareRoots", {}], cataloguedRadicands},
      If[Length[rationalizedRoots] < Length[wanted], False,
        cataloguedRadicands = Together /@
          Lookup[rationalizedRoots, "SourceRadicand", {}];
        AllTrue[wanted, Function[q, AnyTrue[cataloguedRadicands,
          Function[candidate,
            TrueQ[Together[q - candidate] === 0]]]]]]]]];
  If[candidates === {},
    Missing["NoCataloguedRationalizingParametrization", wanted],
    First[SortBy[candidates,
      {Function[parametrization,
         Length[Lookup[parametrization,
           "RationalizedSquareRoots", {}]]],
       Function[parametrization,
         LeafCount[Lookup[parametrization,
           "SourceVariableSubstitution", {}]]]}]]]
];

FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
    rootSquares_List] :=
  FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[
    rootSquares, {$transportChartV, $transportChartW}];
FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationLookupArguments"|>;

(* Input-only V1 wrapper.  A catalog miss deliberately uses the new Missing
   tag, which states absence from this finite catalog and nothing stronger. *)
transportChartRationalExpressionQ[expr_, variables_List] :=
  FreeQ[Unevaluated[expr], _Root |
    Power[_, exponent_Rational /; Denominator[exponent] > 1]] &&
  PolynomialQ[Numerator[Together[expr]], variables] &&
  PolynomialQ[Denominator[Together[expr]], variables];

FeynFacet`ComposeRationalizingParametrizations[
    baseInput_Association, rootSquare_, extensionRules_List,
    newVariables : {_Symbol, _Symbol}] := Module[
  {baseParametrization, baseVariables, sourceVariables, baseSubstitution,
   pullBack, variableRules, rootRules, extensionRootRule, extensionRoot,
   substitution, inheritedRoots, roots, parentName, name,
   parametrization, verification},

  baseParametrization = rationalizingParametrizationNormalize[baseInput];
  If[Lookup[baseParametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[baseParametrization]];
  baseVariables = Lookup[baseParametrization,
    "ParametrizingVariables", Missing[]];
  baseSubstitution = Lookup[baseParametrization,
    "SourceVariableSubstitution", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubstitution, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseRationalizingParametrizationNotWellFormed"|>]
  ];
  sourceVariables = First /@ baseSubstitution;
  pullBack = Together[rootSquare /. baseSubstitution];
  variableRules = Select[extensionRules,
    MemberQ[baseVariables, First[#]] &];
  If[Sort[First /@ variableRules] =!= Sort[baseVariables],
    Return[<|"Status" -> "BaseParametrizingVariablesNotMapped",
      "Expected" -> baseVariables|>]
  ];
  variableRules = Table[
    variable -> (variable /. variableRules), {variable, baseVariables}];
  If[! AllTrue[Last /@ variableRules,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ExtensionParametrizationNotRational"|>]
  ];

  rootRules = Select[extensionRules,
    ! MemberQ[baseVariables, First[#]] &];
  extensionRootRule = SelectFirst[rootRules,
    TrueQ[Together[(Last[#] /. variableRules)^2 -
          (pullBack /. variableRules)] === 0] &&
      transportChartRationalExpressionQ[
        Last[#] /. variableRules, newVariables] &,
    Missing["NoRootRule"]];
  If[MissingQ[extensionRootRule],
    Return[<|"Status" -> "AdditionalSquareRootNotRationalized",
      "PulledBackRadicand" -> pullBack|>]
  ];
  extensionRoot = Together[Last[extensionRootRule] /. variableRules];

  substitution = Map[
    Function[rule, First[rule] -> Together[Last[rule] /. variableRules]],
    baseSubstitution];
  If[! AllTrue[Last /@ substitution,
      transportChartRationalExpressionQ[#, newVariables] &],
    Return[<|"Status" -> "ComposedParametrizationNotRational"|>]
  ];
  inheritedRoots = Lookup[baseParametrization,
    "RationalizedSquareRoots", {}];
  inheritedRoots = Map[
    <|"RationalRoot" ->
        Together[#["RationalRoot"] /. variableRules],
      "SourceRadicand" -> #["SourceRadicand"]|> &,
    inheritedRoots];
  roots = Append[inheritedRoots,
    <|"RationalRoot" -> extensionRoot,
      "SourceRadicand" -> rootSquare|>];
  parentName = Lookup[baseParametrization, "Name",
    "BaseRationalizingParametrization"];
  name = parentName <> "+AdditionalRoot" <> ToString[Length[roots]];
  parametrization = <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationCandidate",
    "Name" -> name,
    "Kind" -> "TwoVariable",
    "ParametrizingVariables" -> newVariables,
    "SourceVariables" -> sourceVariables,
    "SourceVariableSubstitution" -> substitution,
    "RationalizedSquareRoots" -> roots,
    "ParentParametrizationMaps" -> <|parentName -> variableRules|>,
    "ParentParametrizations" ->
      <|parentName -> baseParametrization|>,
    "ParametrizationExtensionData" -> <|
      "BaseParametrization" -> parentName,
      "PulledBackRadicand" -> pullBack,
      "Rules" -> extensionRules|>
  |>;
  verification = FeynFacet`VerifyRationalizingParametrization[
    parametrization];
  If[! TrueQ[verification["Verified"]],
    Return[<|"Status" -> "RationalizingParametrizationExtensionFailed",
      "RationalizingParametrization" -> parametrization,
      "RationalizingParametrizationVerification" -> verification|>]
  ];
  Join[parametrization,
    <|"Status" -> "RationalizingParametrizationVerified",
      "RationalizingParametrizationVerification" -> verification|>]
];

FeynFacet`ComposeRationalizingParametrizations[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationCompositionArguments"|>;

transportChartLoadRationalizeRoots[] := Module[{file, function},
  function = ToExpression["RationalizeRoots`RationalizeRoot"];
  If[DownValues[Evaluate[function]] =!= {}, Return[True]];
  file = FileNameJoin[{$feynFacetAddonRoot, "Addon", "Mathematica_Addon",
    "RationalizeRoots", "RationalizeRoots.m"}];
  If[! FileExistsQ[file], Return[False]];
  Quiet[Check[Get[file], Return[False]]];
  DownValues[Evaluate[function]] =!= {}
];

transportChartExtensionCandidates[raw_, baseVariables_List] :=
  DeleteDuplicates[Cases[raw,
    rules : {__Rule} /;
      ContainsAll[First /@ rules, baseVariables] :> rules,
    {0, Infinity}], SameTest -> SameQ];

Options[FeynFacet`ExtendRationalizingParametrization] = {
  "Name" -> Automatic,
  "OutputVariables" -> Automatic,
  "AllCharts" -> True,
  "AllPoints" -> True,
  "TimeConstraint" -> 1800
};
FeynFacet`ExtendRationalizingParametrization[
    baseInput_Association, rootSquare_,
    OptionsPattern[]] := Module[
  {baseParametrization, baseVariables, baseSubstitution, pullBack,
   outputVariables, allCharts, allPoints, timeConstraint, raw, candidates,
   parametrizations, verifiedParametrizations,
   selected, requestedName},

  If[! transportChartLoadRationalizeRoots[],
    Return[<|"Status" -> "RationalizeRootsUnavailable"|>]
  ];
  baseParametrization = rationalizingParametrizationNormalize[baseInput];
  If[Lookup[baseParametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[baseParametrization]];
  baseVariables = Lookup[baseParametrization,
    "ParametrizingVariables", Missing[]];
  baseSubstitution = Lookup[baseParametrization,
    "SourceVariableSubstitution", Missing[]];
  If[! MatchQ[baseVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[baseSubstitution, {_Rule, _Rule}],
    Return[<|"Status" -> "BaseRationalizingParametrizationNotWellFormed"|>]
  ];
  pullBack = Together[rootSquare /. baseSubstitution];
  (* C4 (generality pass 2026-08-23): the default output variables were
     Global`r and Global`t, which collide with any caller working in those
     symbols (and with packages that dump short names into Global`).  The
     default is now a fresh package-private pair, and an explicit choice
     that meets the base chart's own variables is refused rather than
     silently identified with them. *)
  outputVariables = Replace[OptionValue["OutputVariables"],
    Automatic :> {Unique["FeynFacet`Private`chartExtensionU"],
      Unique["FeynFacet`Private`chartExtensionV"]}];
  If[! MatchQ[outputVariables, {_Symbol, _Symbol}] ||
      ! DuplicateFreeQ[outputVariables],
    Return[<|"Status" -> "InvalidOutputVariables"|>]
  ];
  If[Intersection[outputVariables, baseVariables] =!= {},
    Return[<|"Status" -> "OutputVariablesCollideWithBaseParametrization",
      "OutputVariables" -> outputVariables,
      "BaseVariables" -> baseVariables|>]
  ];
  allCharts = TrueQ[OptionValue["AllCharts"]];
  allPoints = TrueQ[OptionValue["AllPoints"]];
  timeConstraint = OptionValue["TimeConstraint"];
  raw = TimeConstrained[
    RationalizeRoots`RationalizeRoot[
      Sqrt[pullBack],
      Variables -> baseVariables,
      RationalizeRoots`OutputVariables -> outputVariables,
      RationalizeRoots`RootOutput -> True,
      RationalizeRoots`MultipleSolutions -> True,
      RationalizeRoots`AllCharts -> allCharts,
      RationalizeRoots`AllPoints -> allPoints],
    timeConstraint, $TimedOut];
  If[raw === $TimedOut,
    Return[<|"Status" -> "RationalizationTimedOut",
      "Seconds" -> timeConstraint,
      "PulledBackRadicand" -> pullBack|>]
  ];
  candidates = transportChartExtensionCandidates[raw, baseVariables];
  parametrizations = FeynFacet`ComposeRationalizingParametrizations[
      baseParametrization, rootSquare, #, outputVariables] & /@ candidates;
  verifiedParametrizations = Select[parametrizations,
    Lookup[#, "Status", None] ===
      "RationalizingParametrizationVerified" &];
  If[verifiedParametrizations === {},
    Return[<|"Status" -> "NoVerifiedRationalizingParametrizationFound",
      "PulledBackRadicand" -> pullBack,
      "CandidateCount" -> Length[candidates],
      "CandidateResults" -> parametrizations,
      "NonexistenceProved" -> False|>]
  ];
  selected = First@MinimalBy[verifiedParametrizations,
    LeafCount[Lookup[#, "SourceVariableSubstitution", {}]] +
      LeafCount[Lookup[#, "RationalizedSquareRoots", {}]] &];
  requestedName = OptionValue["Name"];
  If[StringQ[requestedName], selected["Name"] = requestedName];
  Join[selected, <|
    "RationalizeRootsCandidateCount" -> Length[candidates],
    "VerifiedCandidateCount" -> Length[verifiedParametrizations]|>]
];

FeynFacet`ExtendRationalizingParametrization[___] :=
  <|"Status" -> "InvalidRationalizingParametrizationExtensionArguments"|>;

