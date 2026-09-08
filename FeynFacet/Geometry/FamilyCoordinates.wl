(* Externally supplied family root data and coordinate reconciliation. No process data are registered on load. *)
(* ------------------------------------------------------------------ *)
(*  Per-family root data registry                                      *)
(* ------------------------------------------------------------------ *)
(* The live registry stores either a catalogued rationalizing-parametrization
   name or source radicands for explicit square-root generators and quadratic
   relations.  Generated V1 registries are regenerated, not normalized here. *)
$familyRootDataRegistry = <||>;

familyRootDataEntryNormalize[value_] := Which[
  ! AssociationQ[value],
    <|"Status" -> "FamilyRootDataEntryNotAssociation",
      "Head" -> ToString[Head[value], InputForm]|>,
  KeyExistsQ[value, "SourceRadicands"], value,
  KeyExistsQ[value, "RationalizingParametrizationName"], value,
  AnyTrue[{"RootSquares", "ChartAlias",
      "RationalizingParametrizationAlias"}, KeyExistsQ[value, #] &],
    <|"Status" -> "LegacyFamilyRootDataSchemaUnsupported"|>,
  True,
    <|"Status" -> "FamilyRootDataEntryKeysNotRecognized",
      "Keys" -> Keys[value]|>
];

familyRootDataEntryKind[value_Association] := Module[
  {radicands, name},
  Which[
    KeyExistsQ[value, "Status"], value,
    KeyExistsQ[value, "SourceRadicands"],
      If[Keys[value] =!= {"SourceRadicands"},
        Return[<|"Status" -> "SourceRadicandEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      radicands = value["SourceRadicands"];
      Which[
        ! ListQ[radicands] || radicands === {},
          <|"Status" -> "SourceRadicandsNotANonemptyList"|>,
        ! AllTrue[radicands,
            FreeQ[#, _Root | Power[_, _Rational]] &],
          <|"Status" -> "SourceRadicandContainsRadicals"|>,
        ! AllTrue[radicands, PolynomialQ[#, Variables[#]] &],
          <|"Status" -> "SourceRadicandNotPolynomial"|>,
        ! AllTrue[radicands, Variables[#] =!= {} &],
          <|"Status" -> "SourceRadicandHasNoVariables"|>,
        True, "SquareRootGeneratorsAndQuadraticRelations"],
    KeyExistsQ[value, "RationalizingParametrizationName"],
      name = value["RationalizingParametrizationName"];
      If[Keys[value] =!= {"RationalizingParametrizationName"},
        Return[<|"Status" ->
          "RationalizingParametrizationNameEntryHasExtraKeys",
          "Keys" -> Keys[value]|>]];
      If[StringQ[name] &&
          KeyExistsQ[FeynFacet`RationalizingParametrizationCatalog[], name],
        "RationalizingParametrization",
        <|"Status" -> "RationalizingParametrizationNameNotInCatalog",
          "Value" -> name|>],
    True,
      <|"Status" -> "FamilyRootDataEntryKeysNotRecognized",
        "Keys" -> Keys[value]|>]
];

FeynFacet`RegisterFamilyRootData[entries_Association] := Module[
  {normalizedEntries, kinds, invalid},
  If[! AllTrue[Keys[entries], StringQ],
    Return[<|"Status" -> "FamilyRootDataKeysNotStrings",
      "Keys" -> Select[Keys[entries], ! StringQ[#] &]|>]];
  normalizedEntries = Association @ KeyValueMap[
    #1 -> familyRootDataEntryNormalize[#2] &, entries];
  kinds = Association @ KeyValueMap[
    #1 -> familyRootDataEntryKind[#2] &, normalizedEntries];
  invalid = Select[kinds, ! StringQ[#] &];
  If[invalid =!= <||>,
    Return[<|"Status" -> "InvalidFamilyRootDataEntries",
      "Invalid" -> invalid|>]];
  $familyRootDataRegistry = Join[$familyRootDataRegistry, normalizedEntries];
  <|"Status" -> "FamilyRootDataRegistered",
    "Registered" -> Length[normalizedEntries],
    "Families" -> Sort[Keys[normalizedEntries]],
    "Kinds" -> Counts[Values[kinds]],
    "RegistrySize" -> Length[$familyRootDataRegistry]|>
];
FeynFacet`RegisterFamilyRootData[___] :=
  <|"Status" -> "InvalidFamilyRootDataRegistration"|>;

FeynFacet`LoadFamilyRootData[file_String] := Module[{value},
  If[! FileExistsQ[file],
    Return[<|"Status" -> "FamilyRootDataFileMissing", "File" -> file|>]];
  value = FamilyArtifactRead[file];
  If[! AssociationQ[value],
    Return[<|"Status" -> "FamilyRootDataFileNotAnAssociation",
      "File" -> file|>]];
  Join[FeynFacet`RegisterFamilyRootData[value], <|"File" -> file|>]
];
FeynFacet`LoadFamilyRootData[___] :=
  <|"Status" -> "InvalidFamilyRootDataRegistration"|>;

rationalizingParametrizationRekey[input_Association,
    sourceVariables : {_Symbol, _Symbol},
    parametrizingVariables : {_Symbol, _Symbol}] := Module[
  {parametrization, oldSubstitution, oldSourceVariables,
   oldParametrizingVariables, sourceRules, variableRules, substitution,
   roots, result},
  parametrization = rationalizingParametrizationNormalize[input];
  If[Lookup[parametrization, "DataType", None] =!=
      "RationalizingParametrization",
    Return[parametrization]];
  oldSubstitution = parametrization["SourceVariableSubstitution"];
  oldParametrizingVariables = parametrization["ParametrizingVariables"];
  If[! MatchQ[oldSubstitution, {_Rule, _Rule}] ||
      ! MatchQ[oldParametrizingVariables, {_Symbol, _Symbol}],
    Return[<|"Status" -> "RationalizingParametrizationNotWellFormed"|>]];
  oldSourceVariables = First /@ oldSubstitution;
  sourceRules = Thread[oldSourceVariables -> sourceVariables];
  variableRules = Thread[oldParametrizingVariables -> parametrizingVariables];
  substitution = Map[
    Function[rule, (First[rule] /. sourceRules) ->
      Together[Last[rule] /. variableRules]], oldSubstitution];
  roots = Map[
    <|"RationalRoot" -> Together[#["RationalRoot"] /. variableRules],
      "SourceRadicand" ->
        Together[#["SourceRadicand"] /. sourceRules]|> &,
    parametrization["RationalizedSquareRoots"]];
  result = <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationDeclared",
    "Name" -> Lookup[parametrization, "Name",
        "RationalizingParametrization"] <> "Rekeyed",
    "Kind" -> "TwoVariable",
    "SourceVariables" -> sourceVariables,
    "ParametrizingVariables" -> parametrizingVariables,
    "SourceVariableSubstitution" -> substitution,
    "RationalizedSquareRoots" -> roots,
    "ParentParametrizationMaps" -> <||>,
    "ParentParametrizations" -> <||>
  |>;
  If[KeyExistsQ[parametrization, "InverseParametrizationByRootValues"],
    result = Append[result, "InverseParametrizationByRootValues" ->
      parametrization["InverseParametrizationByRootValues"]]];
  result
];

FeynFacet`FamilyRootData[family_String] := FeynFacet`FamilyRootData[family,
  {$transportChartV, $transportChartW}, Automatic];
FeynFacet`FamilyRootData[family_String,
    sourceVariables : {_Symbol, _Symbol}] :=
  FeynFacet`FamilyRootData[family, sourceVariables, Automatic];
FeynFacet`FamilyRootData[family_String,
    sourceVariables : {_Symbol, _Symbol},
    parametrizingVariables : ({_Symbol, _Symbol} | Automatic)] := Module[
  {entry, kind, record, targetVariables, name},
  entry = Lookup[$familyRootDataRegistry, family,
    Missing["FamilyRootDataNotRegistered", family]];
  If[MissingQ[entry], Return[Missing["FamilyRootDataNotRegistered", family]]];
  kind = familyRootDataEntryKind[entry];
  If[! StringQ[kind],
    Return[Join[<|"Status" -> "RegisteredFamilyRootDataInvalid",
      "Family" -> family|>, kind]]];
  Switch[kind,
    "SquareRootGeneratorsAndQuadraticRelations",
      targetVariables = Replace[parametrizingVariables,
        Automatic -> {$transportChartX, $transportChartY}];
      FeynFacet`BuildSquareRootGeneratorsAndQuadraticRelations[
        entry["SourceRadicands"] /. Thread[
          {$transportChartV, $transportChartW} -> sourceVariables],
        sourceVariables, targetVariables],
    "RationalizingParametrization",
      name = entry["RationalizingParametrizationName"];
      record = masterTransportRationalizingParametrizationByName[name];
      If[parametrizingVariables === Automatic &&
          sourceVariables === {$transportChartV, $transportChartW},
        record,
        rationalizingParametrizationRekey[record, sourceVariables,
          Replace[parametrizingVariables,
            Automatic -> Lookup[record, "ParametrizingVariables",
              {$transportChartX, $transportChartY}]]]],
    _, Missing["FamilyRootDataNotRegistered", family]]
];

(* Express the parameters of one rationalizing parametrization through a
   second coefficient presentation.  Candidate inverse images are accepted
   only when forward substitution reproduces both source-coordinate images
   exactly.  A declared inverse is a candidate generator, never trusted as
   the proof. *)
masterTransportComposeTwoVariableRecord[recordParametrization_Association,
    targetData_Association, sourceVariables_List] := Module[
  {recVars, recSubst, recRoot, recSquare, tgtVars, tf, tg, tgtRoots,
   matching, recRoots, inverseByRoots, rootMatches, declaredCandidates,
   candidates, verified, eqs, presentationKind, compositionZeroQ,
   route = "Solve"},
  recVars = Lookup[recordParametrization, "ParametrizingVariables", $Failed];
  recSubst = Lookup[recordParametrization,
    "SourceVariableSubstitution", $Failed];
  recRoots = Lookup[recordParametrization, "RationalizedSquareRoots", {}];
  recRoot = If[recRoots === {}, None,
    recRoots[[1, "RationalRoot"]]];
  recSquare = If[recRoots === {}, None,
    recRoots[[1, "SourceRadicand"]]];
  If[! MatchQ[recVars, {_Symbol, _Symbol}] || ! MatchQ[recSubst, {_Rule, _Rule}],
    Return[<|"Status" -> "RecordRationalizingParametrizationNotWellFormed"|>]];
  presentationKind = Lookup[targetData, "PresentationKind", None];
  tgtVars = masterTransportPresentationVariables[targetData];
  {tf, tg} = Together /@
    (Last /@ masterTransportPresentationSubstitution[targetData]);
  tgtRoots = Switch[presentationKind,
    "RationalizingParametrization",
      <|"Expression" -> #1["RationalRoot"],
        "SourceRadicand" -> #1["SourceRadicand"]|> & /@
        Lookup[targetData, "RationalizedSquareRoots", {}],
    "SquareRootGeneratorsAndQuadraticRelations",
      <|"Expression" -> #1["Generator"],
        "SourceRadicand" -> #1["SourceRadicand"]|> & /@
        Lookup[targetData, "SquareRootGenerators", {}],
    _, {}];
  compositionZeroQ[expression_] := If[
    presentationKind === "SquareRootGeneratorsAndQuadraticRelations",
    TrueQ[transportChartAlgebraicZeroQ[expression,
      Switch[presentationKind,
        "SquareRootGeneratorsAndQuadraticRelations",
          targetData["SquareRootGenerators"],
        _, {}]]],
    TrueQ[Together[expression] === 0]];
  inverseByRoots = Lookup[recordParametrization,
    "InverseParametrizationByRootValues", None];
  rootMatches = If[ListQ[recRoots], Table[
    SelectFirst[tgtRoots,
      TrueQ[Together[#1["SourceRadicand"] -
        recRoot["SourceRadicand"]] === 0] &,
      Missing["RootNotAvailable"]], {recRoot, recRoots}], {}];
  (* the target root that rationalizes the RECORD's quadratic *)
  matching = If[recSquare === None || recRoot === None, {},
    Select[tgtRoots,
      TrueQ[Together[#["SourceRadicand"] - recSquare] === 0] &]];
  (* the record's variables are renamed to FRESH symbols before solving:
     a joint chart keeps the parent's y as its own y, so the record's y
     and the target's y are the same symbol, and Solve would otherwise be
     asked to solve for a symbol that also appears on the right *)
  Module[{fresh, rename, back, fRec, gRec, rhoRec},
    fresh = Table[Unique["masterTransportChartVar"], {2}];
    rename = Thread[recVars -> fresh];
    back = Thread[fresh -> recVars];
    fRec = Last[recSubst[[1]]] /. rename;
    gRec = Last[recSubst[[2]]] /. rename;
    rhoRec = If[recRoot === None, None, recRoot /. rename];
    eqs = {fRec == tf, gRec == tg};
    declaredCandidates = If[MatchQ[inverseByRoots, _Function] &&
        recRoots =!= {} && AllTrue[rootMatches, AssociationQ],
      DeleteDuplicates[Function[signs, Module[{images},
        images = Quiet[Check[inverseByRoots[{tf, tg},
          MapThread[Times, {signs,
            Lookup[rootMatches, "Expression"]}]], $Failed]];
        If[MatchQ[images, {_, _}], Thread[fresh -> images], Nothing]]]
        /@ Tuples[{1, -1}, Length[recRoots]]], {}];
    candidates = If[declaredCandidates =!= {},
      route = "DeclaredInverseByRoots"; declaredCandidates,
      If[matching === {},
        (* no root available: try the plain algebraic solve and keep only
           rational solutions *)
        Quiet[Solve[eqs, fresh]],
        (* Table over {root, sign} of Solve's solution LISTS: flatten two
           levels to a plain list of rule lists (one level left each
           candidate as {{rules}} and the identity check below then compared
           a LIST -- measured 2026-08-17 03:20 on class 79 in Kallen23) *)
        Flatten[Table[
          Quiet[Solve[Append[eqs, rhoRec == sign m["Expression"]], fresh]],
          {m, matching}, {sign, {1, -1}}], 2]]];
    candidates = Select[candidates,
      Which[
        presentationKind === "RationalizingParametrization" ||
            matching === {},
          FreeQ[#, Power[_, _Rational] | _Root],
        presentationKind ===
            "SquareRootGeneratorsAndQuadraticRelations",
          FreeQ[#, _Root],
        True, False] &];
    verified = Select[candidates,
      compositionZeroQ[(fRec /. #) - tf] &&
      compositionZeroQ[(gRec /. #) - tg] &];
    If[verified === {},
      Return[<|"Status" -> "TwoVariableParametrizationsNotComposable",
        "RecordVariables" -> recVars, "TargetVariables" -> tgtVars,
        "MatchingRoots" -> Length[matching], "Candidates" -> Length[candidates],
        "Route" -> route|>]];
    <|"Status" -> "OK",
      "CoefficientVariableRules" ->
        Map[Together, First[verified] /. back, {2}],
      "CoefficientVariableImages" ->
        Map[Together, fresh /. First[verified]],
      "CandidateCount" -> Length[candidates],
      "VerifiedCandidateCount" -> Length[verified],
      "Route" -> route|>]];

(* A diagonal-block record may already be written in the selected family
   coefficient variables, may be written in the source variables, or may
   carry one complete block-local rationalizing parametrization.  Equality of
   its coefficient-variable list with the selected presentation gives the
   identity map; the downstream transformed-system equation still decides
   acceptance, so this is coordinate routing rather than trusted evidence. *)
masterTransportRecordCoordinateMap[record_Association,
    data_Association] := Module[
  {sourceVariables, targetVariables, sourceNames, targetNames,
   targetSubstitution, targetImages, recordVariables, recordNames,
   recordParametrization, recordSubstitution, recordSourceNames,
   recordParametrizingNames, identity, composed},
  sourceVariables = data["SourceVariables"];
  targetVariables = masterTransportPresentationVariables[data];
  targetSubstitution = masterTransportPresentationSubstitution[data];
  targetImages = Together /@ (Last /@ targetSubstitution);
  sourceNames = SymbolName /@ sourceVariables;
  targetNames = SymbolName /@ targetVariables;
  recordVariables = Lookup[record, "CoefficientVariables", $Failed];
  If[! MatchQ[recordVariables, {_Symbol, _Symbol}],
    Return[<|"Status" ->
      "LegacyDiagonalBlockCoefficientVariableSchemaUnsupported"|>]];
  recordNames = SymbolName /@ recordVariables;
  recordParametrization = Lookup[record,
    "RationalizingParametrization", None];
  If[recordParametrization === None || recordParametrization === Null,
    If[recordNames === targetNames,
      Return[<|
        "Status" -> "OK",
        "CoordinateRepresentation" ->
          "SelectedFamilyCoefficientPresentation",
        "CoefficientVariableRules" ->
          Thread[recordVariables -> targetVariables],
        "CoefficientVariableImages" -> targetVariables,
        "CompositionStatement" ->
          "the diagonal block is already written in the selected family coefficient variables",
        "CompositionVerified" -> True|>]
    ];
    If[recordNames =!= sourceNames,
      Return[<|"Status" ->
        "DiagonalBlockSourceVariableRepresentationMismatch",
        "Expected" -> sourceNames, "Found" -> recordNames|>]];
    Return[<|
      "Status" -> "OK",
      "CoordinateRepresentation" -> "SourceVariables",
      "CoefficientVariableRules" -> Thread[recordVariables -> targetImages],
      "CoefficientVariableImages" -> targetImages,
      "CompositionStatement" ->
        "the diagonal-block coefficients are written in the source variables",
      "CompositionVerified" -> True|>]
  ];
  If[! masterTransportRationalizingParametrizationRecordQ[
      recordParametrization],
    Return[<|"Status" ->
      "DiagonalBlockRationalizingParametrizationNotWellFormed"|>]];
  recordSubstitution =
    recordParametrization["SourceVariableSubstitution"];
  recordSourceNames = SymbolName /@ (First /@ recordSubstitution);
  recordParametrizingNames = SymbolName /@
    recordParametrization["ParametrizingVariables"];
  If[recordSourceNames =!= sourceNames ||
      recordParametrizingNames =!= recordNames,
    Return[<|"Status" ->
      "DiagonalBlockRationalizingParametrizationVariablesMismatch"|>]];
  identity = recordNames === targetNames && And @@ MapThread[
    TrueQ[Together[#1 - #2] === 0] &,
    {Last /@ recordSubstitution, targetImages}];
  If[identity,
    Return[<|
      "Status" -> "OK",
      "CoordinateRepresentation" ->
        "SelectedRationalizingParametrization",
      "CoefficientVariableRules" ->
        Thread[recordVariables -> targetVariables],
      "CoefficientVariableImages" -> targetVariables,
      "CompositionStatement" ->
        "the diagonal block and family use the same rationalizing parametrization",
      "CompositionVerified" -> True|>]
  ];
  composed = masterTransportComposeTwoVariableRecord[
    recordParametrization, data, sourceVariables];
  If[! AssociationQ[composed] || composed["Status"] =!= "OK",
    Return[<|"Status" ->
      "DiagonalBlockRationalizingParametrizationNotComposable",
      "Composition" -> composed|>]];
  <|
    "Status" -> "OK",
    "CoordinateRepresentation" ->
      "ComposedRationalizingParametrizations",
    "CoefficientVariableRules" -> composed["CoefficientVariableRules"],
    "CoefficientVariableImages" ->
      composed["CoefficientVariableImages"],
    "CompositionRoute" -> Lookup[composed, "Route", "Solve"],
    "CompositionStatement" ->
      "substitution of the solved coefficient variables reproduces the selected family parametrization",
    "CompositionVerified" -> True|>
];
