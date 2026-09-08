(* Construction and validation of one schema-V2 diagonal-block dlog epsilon
   form.  The selected rows are pulled back through the declared family
   coefficient presentation before a candidate is checked.  A block-local
   rationalizing parametrization carried by the current DiagonalBlockEpsForm
   result is composed into that family presentation; it is never persisted as
   a second coefficient representation.

   Production validation evaluates the defining transformation equation at
   independent finite-field points.  For a square-root presentation every
   sign sheet of the displayed quadratic generators is checked.  The stored
   points are replayed by the predicate.  Characteristic-zero symbolic
   validation remains an explicit development option. *)

Clear[ConstructDiagonalBlockDLogEpsilonForm,
  DiagonalBlockDLogEpsilonFormQ];

ClearAll[
  diagonalBlockDLogEpsilonFormFailure,
  diagonalBlockDLogEpsilonFormFlatnessEvidenceQ,
  diagonalBlockDLogEpsilonFormSystemQ,
  diagonalBlockDLogEpsilonFormRowsQ,
  diagonalBlockDLogEpsilonFormPresentationData,
  diagonalBlockDLogEpsilonFormReplaceDeclaredRoots,
  diagonalBlockDLogEpsilonFormPullback,
  diagonalBlockDLogEpsilonFormDerivative,
  diagonalBlockDLogEpsilonFormSymbolicZeroQ,
  diagonalBlockDLogEpsilonFormSymbolicZeroMatrixQ,
  diagonalBlockDLogEpsilonFormLocalParametrization,
  diagonalBlockDLogEpsilonFormCurrentGateQ,
  diagonalBlockDLogEpsilonFormCandidateData,
  diagonalBlockDLogEpsilonFormValidationData,
  diagonalBlockDLogEpsilonFormReplaceGeneratorValues,
  diagonalBlockDLogEpsilonFormModularValue,
  diagonalBlockDLogEpsilonFormModularMatrix,
  diagonalBlockDLogEpsilonFormModularCheck,
  diagonalBlockDLogEpsilonFormGenerateSamples,
  diagonalBlockDLogEpsilonFormReplaySamples,
  diagonalBlockDLogEpsilonFormValidation,
  diagonalBlockDLogEpsilonFormStoredValidationQ
];

diagonalBlockDLogEpsilonFormFailure[status_String, extra_: <||>] :=
  Join[<|"Status" -> status|>, extra];

diagonalBlockDLogEpsilonFormFlatnessEvidenceQ[evidence_Association] :=
  Lookup[evidence, "Status", None] === "ConnectionFlatnessValidated" &&
    TrueQ[Lookup[evidence, "Accepted", False]] &&
    Switch[Lookup[evidence, "Method", None],
      "CharacteristicZeroSymbolicIdentity",
        TrueQ[Lookup[evidence, "Exact", False]] &&
          ! TrueQ[Lookup[evidence, "Probabilistic", True]],
      "ProbabilisticFiniteFieldSampling",
        ! TrueQ[Lookup[evidence, "Exact", True]] &&
          TrueQ[Lookup[evidence, "Probabilistic", False]] &&
          MatchQ[Lookup[evidence, "Samples", Missing[]],
            {__Association}] &&
          AllTrue[evidence["Samples"],
            TrueQ[Lookup[#, "CurvatureZero", False]] &],
      _, False
    ];
diagonalBlockDLogEpsilonFormFlatnessEvidenceQ[_] := False;

diagonalBlockDLogEpsilonFormSystemQ[system_Association] := Module[
  {variables, regulator, basis, matrices, dimension, flatness},
  variables = Lookup[system, "KinematicVariables", Missing[]];
  regulator = Lookup[system, "DimensionalRegulator", Missing[]];
  basis = Lookup[system, "OriginalMasterIntegralBasis", Missing[]];
  matrices = Lookup[system, "ConnectionMatrices", Missing[]];
  dimension = If[ListQ[basis], Length[basis], 0];
  flatness = Lookup[Lookup[system, "Validation", <||>],
    "ConnectionFlatness", Missing[]];
  Lookup[system, "DataType", None] === "FamilyDifferentialSystem" &&
    Lookup[system, "SchemaVersion", None] === 2 &&
    Lookup[system, "Status", None] ===
      "FamilyDifferentialSystemValidated" &&
    StringQ[Lookup[system, "Family", None]] &&
    MatchQ[variables, {_Symbol, _Symbol}] &&
    DuplicateFreeQ[variables] && MatchQ[regulator, _Symbol] &&
    ! MemberQ[variables, regulator] && dimension > 0 &&
    MatchQ[matrices, {_?MatrixQ, _?MatrixQ}] &&
    AllTrue[matrices, Dimensions[#] === {dimension, dimension} &] &&
    diagonalBlockDLogEpsilonFormFlatnessEvidenceQ[flatness]
];
diagonalBlockDLogEpsilonFormSystemQ[_] := False;

diagonalBlockDLogEpsilonFormRowsQ[rows_, dimension_Integer] :=
  MatchQ[rows, {__Integer}] && DuplicateFreeQ[rows] &&
    AllTrue[rows, 1 <= # <= dimension &];

diagonalBlockDLogEpsilonFormPresentationData[system_Association,
    presentation_Association] := Module[{data, family},
  family = system["Family"];
  If[Lookup[presentation, "Status", None] =!=
      "CoefficientPresentationValidated",
    Return[diagonalBlockDLogEpsilonFormFailure[
      "CoefficientPresentationNotValidated"]]];
  If[KeyExistsQ[presentation, "Family"] &&
      Lookup[presentation, "Family", None] =!= family,
    Return[diagonalBlockDLogEpsilonFormFailure[
      "CoefficientPresentationFamilyMismatch"]]];
  data = masterTransportCoefficientPresentationData[presentation,
    system["KinematicVariables"]];
  If[Lookup[data, "Status", None] =!= "OK",
    Return[diagonalBlockDLogEpsilonFormFailure[
      "CoefficientPresentationValidationFailed", <|
        "Reason" -> Lookup[data, "Status", None]|>]]];
  data
];
diagonalBlockDLogEpsilonFormPresentationData[_, _] :=
  diagonalBlockDLogEpsilonFormFailure[
    "CoefficientPresentationNotWellFormed"];

(* A rationalizing parametrization declares a branch by its RationalRoot.
   Replace only radicals whose squares agree exactly after substitution, and
   do so before rational normalization.  PowerExpand is never used. *)
diagonalBlockDLogEpsilonFormReplaceDeclaredRoots[expression_,
    presentationData_Association] := Module[
  {kind, roots, substitution, replace},
  kind = Lookup[presentationData, "PresentationKind", None];
  If[! MemberQ[{"RationalizingParametrization",
      "SquareRootGeneratorsAndQuadraticRelations"}, kind],
    Return[expression]];
  {roots, substitution} = Switch[kind,
    "RationalizingParametrization",
      {(<|"Image" -> #1["RationalRoot"],
          "SourceRadicand" -> #1["SourceRadicand"]|> & /@
        presentationData["RationalizedSquareRoots"]),
       presentationData["SourceVariableSubstitution"]},
    "SquareRootGeneratorsAndQuadraticRelations",
      {(<|"Image" -> #1["Generator"],
          "SourceRadicand" -> #1["SourceRadicand"]|> & /@
        presentationData["SquareRootGenerators"]),
       presentationData["SourceToCoefficientVariableRules"]}];
  replace[Power[base_, exponent_Rational] /;
      Denominator[exponent] === 2] := Module[{matching},
    matching = SelectFirst[roots,
      TrueQ[Together[base -
        (#1["SourceRadicand"] /. substitution)] === 0] &, None];
    If[matching === None, Power[base, exponent],
      matching["Image"]^(2 exponent)]
  ];
  replace[value_] := value;
  expression /. radical : Power[_, exponent_Rational /;
      Denominator[exponent] === 2] :> replace[radical]
];

diagonalBlockDLogEpsilonFormPullback[system_Association,
    presentationData_Association, rows_List] := Module[
  {sourceBlock, substitution, differentialPullback, substituted, pulled},
  sourceBlock = Normal /@
    system["ConnectionMatrices"][[All, rows, rows]];
  substitution = masterTransportPresentationSubstitution[presentationData];
  differentialPullback =
    presentationData["DifferentialPullbackMatrix"];
  substituted = sourceBlock /. substitution;
  substituted = diagonalBlockDLogEpsilonFormReplaceDeclaredRoots[
    substituted, presentationData];
  If[Lookup[presentationData, "PresentationKind", None] ===
        "RationalizingParametrization" &&
      ! FreeQ[substituted,
        Power[_, exponent_Rational /; Denominator[exponent] > 1]],
    Return[diagonalBlockDLogEpsilonFormFailure[
      "SourceConnectionContainsUndeclaredRadicalAfterPullback"]]];
  substituted = Map[Cancel[Together[#]] &, substituted, {3}];
  pulled = masterTransportPullBackOneForm[
    substituted[[1]], substituted[[2]], differentialPullback];
  <|
    "Status" -> "OK",
    "SourceVariables" -> system["KinematicVariables"],
    "CoefficientVariables" ->
      masterTransportPresentationVariables[presentationData],
    "DimensionalRegulator" -> system["DimensionalRegulator"],
    "PresentationData" -> presentationData,
    "ConnectionMatrices" -> pulled|>
];

(* Differentiate in the quotient defined by rho_i^2 = Delta_i.  Replacing
   every displayed generator by a fresh symbol before differentiating avoids
   both treating a formal rho_i as constant and double-counting Mathematica's
   built-in derivative when the generator is displayed as Sqrt[Delta_i]. *)
diagonalBlockDLogEpsilonFormDerivative[expression_, variable_Symbol,
    presentationData_Association] := Module[
  {records, generators, formalGenerators, toFormal, fromFormal,
   formalExpression, radicands, derivative},
  If[Lookup[presentationData, "PresentationKind", None] =!=
      "SquareRootGeneratorsAndQuadraticRelations",
    Return[D[expression, variable]]];
  records = presentationData["SquareRootGenerators"];
  generators = Lookup[records, "Generator", {}];
  radicands = Lookup[records, "QuadraticRadicand", {}];
  If[generators === {}, Return[D[expression, variable]]];
  formalGenerators = Table[Unique["diagonalBlockRoot"],
    {Length[generators]}];
  toFormal = Thread[generators -> formalGenerators];
  fromFormal = Thread[formalGenerators -> generators];
  formalExpression = expression /. toFormal;
  derivative = D[formalExpression, variable] + Sum[
    D[formalExpression, formalGenerators[[index]]] *
      D[radicands[[index]], variable]/
        (2 formalGenerators[[index]]),
    {index, Length[formalGenerators]}];
  derivative /. fromFormal
];

diagonalBlockDLogEpsilonFormSymbolicZeroQ[expression_,
    presentationData_Association] := Module[{normalized = expression,
      records, generators, radicands},
  If[Lookup[presentationData, "PresentationKind", None] ===
      "SquareRootGeneratorsAndQuadraticRelations",
    records = presentationData["SquareRootGenerators"];
    generators = Lookup[records, "Generator", {}];
    radicands = Lookup[records, "QuadraticRadicand", {}];
    normalized = normalized /.
      Thread[generators -> (Sqrt /@ radicands)];
    records = MapThread[Append[#1, "Generator" -> Sqrt[#2]] &,
      {records, radicands}];
    TrueQ[transportChartAlgebraicZeroQ[normalized, records]],
    TrueQ[Cancel[Together[normalized]] === 0]
  ]
];

diagonalBlockDLogEpsilonFormSymbolicZeroMatrixQ[matrix_,
    presentationData_Association] :=
  AllTrue[Flatten[{matrix}],
    diagonalBlockDLogEpsilonFormSymbolicZeroQ[#,
      presentationData] &];

(* Complete the compact conic record emitted by DiagonalBlockEpsForm using
   the source radicand already declared by the family presentation. *)
diagonalBlockDLogEpsilonFormLocalParametrization[
    candidate_Association, system_Association,
    presentationData_Association] := Module[
  {localPresentation, sourceVariables, declaredSourceVariables,
   localVariables, substitution, root, sourceRadicands, matching},
  localPresentation = Lookup[candidate, "Chart", None];
  If[localPresentation === None || localPresentation === Null,
    Return[None]];
  sourceVariables = system["KinematicVariables"];
  declaredSourceVariables = Lookup[candidate, "SourceVariables",
    Missing[]];
  localVariables = Lookup[candidate, "Variables", Missing[]];
  If[masterTransportRationalizingParametrizationRecordQ[
      localPresentation],
    If[SymbolName /@ localPresentation["SourceVariables"] =!=
          SymbolName /@ sourceVariables ||
        SymbolName /@ localPresentation["ParametrizingVariables"] =!=
          SymbolName /@ localVariables,
      Return[diagonalBlockDLogEpsilonFormFailure[
        "LocalRationalizingParametrizationVariablesMismatch"]]];
    Return[localPresentation]];
  If[! AssociationQ[localPresentation] ||
      ! ContainsAll[Keys[localPresentation],
        {"Fixed", "Subst", "Root"}] ||
      ! MatchQ[localPresentation["Fixed"], _Symbol] ||
      ! MatchQ[localPresentation["Subst"], _Rule] ||
      ! MatchQ[localVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[declaredSourceVariables, {_Symbol, _Symbol}] ||
      SymbolName /@ declaredSourceVariables =!=
        SymbolName /@ sourceVariables ||
      ! MemberQ[sourceVariables, localPresentation["Fixed"]] ||
      ! MemberQ[sourceVariables, First[localPresentation["Subst"]]] ||
      localPresentation["Fixed"] ===
        First[localPresentation["Subst"]],
    Return[diagonalBlockDLogEpsilonFormFailure[
      "LocalRationalizingParametrizationNotWellFormed"]]];
  substitution = (# -> Together[# /. localPresentation["Subst"]]) & /@
    sourceVariables;
  root = Together[localPresentation["Root"] /.
    localPresentation["Subst"]];
  sourceRadicands = Switch[
    Lookup[presentationData, "PresentationKind", None],
    "RationalizingParametrization",
      Lookup[presentationData["RationalizedSquareRoots"],
        "SourceRadicand", {}],
    "SquareRootGeneratorsAndQuadraticRelations",
      Lookup[presentationData["SquareRootGenerators"],
        "SourceRadicand", {}],
    _, {}];
  matching = Select[sourceRadicands,
    TrueQ[Together[(# /. substitution) - root^2] === 0] &];
  If[matching === {},
    Return[diagonalBlockDLogEpsilonFormFailure[
      "LocalRationalizingParametrizationRootNotDeclared"]]];
  <|
    "DataType" -> "RationalizingParametrization",
    "SchemaVersion" -> 2,
    "Status" -> "RationalizingParametrizationDeclared",
    "Name" -> "DiagonalBlockLocalRationalizingParametrization",
    "Kind" -> "TwoVariable",
    "SourceVariables" -> sourceVariables,
    "ParametrizingVariables" -> localVariables,
    "SourceVariableSubstitution" -> substitution,
    "RationalizedSquareRoots" -> {<|
      "RationalRoot" -> root,
      "SourceRadicand" -> First[matching]|>},
    "ParentParametrizationMaps" -> <||>,
    "ParentParametrizations" -> <||>|>
];

diagonalBlockDLogEpsilonFormCurrentGateQ[gate_] :=
  AssociationQ[gate] && Lookup[gate, "Status", None] === "Certified" &&
    AllTrue[{"GateX", "GateY", "ConstantResidues",
      "LettersEpsFree", "Flat", "Invertible"},
      TrueQ[Lookup[gate, #, False]] &];

diagonalBlockDLogEpsilonFormCandidateData[candidate_Association,
    system_Association, rows_List,
    presentationData_Association,
    allowInternallyConstructedCandidate_: False] := Module[
  {transformation, letters, residues, dimension, variables, regulator,
   localVariables, localPresentation, coordinateRecord, coordinateMap,
   rules, mappedTransformation, mappedLetters, internallyConstructed,
   exactGateValidated, constructionPrimes},
  dimension = Length[rows];
  variables = masterTransportPresentationVariables[presentationData];
  regulator = system["DimensionalRegulator"];
  (* Clean V2 mathematical fields in the selected family presentation. *)
  If[Lookup[candidate, "DataType", None] ===
      "DiagonalBlockDLogEpsilonForm",
    transformation = Lookup[candidate, "BasisTransformationMatrix",
      Missing[]];
    letters = Lookup[candidate, "Letters", Missing[]];
    residues = Lookup[candidate, "ConstantResidueMatrices", Missing[]];
    If[Lookup[candidate, "SchemaVersion", None] =!= 2 ||
        Lookup[candidate, "BlockRows", Missing[]] =!= rows ||
        Lookup[candidate, "CoefficientVariables", Missing[]] =!= variables ||
        Lookup[candidate, "DimensionalRegulator", Missing[]] =!= regulator ||
        ! MatrixQ[transformation] ||
        Dimensions[transformation] =!= {dimension, dimension} ||
        ! ListQ[letters] || ! ListQ[residues] ||
        Length[letters] =!= Length[residues] ||
        ! AllTrue[residues,
          MatrixQ[#] && Dimensions[#] === {dimension, dimension} &],
      Return[diagonalBlockDLogEpsilonFormFailure[
        "CandidateDiagonalBlockDLogEpsilonFormNotWellFormed"]]];
    Return[<|"Status" -> "OK",
      "BasisTransformationMatrix" -> transformation,
      "Letters" -> letters,
      "ConstantResidueMatrices" -> residues,
      "CandidateProvenance" -> <|
        "Type" -> "SuppliedV2MathematicalFields",
        "Accepted" -> True|>|>]
  ];
  (* An externally supplied current DiagonalBlockEpsForm result must carry
     its legacy exact gate.  The Automatic route may instead pass the
     unaccepted candidate constructed by that machinery; only the final
     family-presentation modular validation accepts it. *)
  internallyConstructed =
    TrueQ[allowInternallyConstructedCandidate] &&
      Lookup[candidate, "Status", None] === "CandidateConstructed";
  exactGateValidated =
    Lookup[candidate, "Status", None] === "Certified" &&
      diagonalBlockDLogEpsilonFormCurrentGateQ[
        Lookup[candidate, "Gate", Missing[]]];
  constructionPrimes = If[internallyConstructed,
    Lookup[Lookup[candidate, "Solve", <||>], "Primes", {}], {}];
  If[(! internallyConstructed && ! exactGateValidated) ||
      ! MatrixQ[Lookup[candidate, "Transformation", Missing[]]] ||
      ! ListQ[Lookup[candidate, "Letters", Missing[]]] ||
      ! ListQ[Lookup[candidate, "Residues", Missing[]]] ||
      ! MatchQ[Lookup[candidate, "Variables", Missing[]],
        {_Symbol, _Symbol}] ||
      (KeyExistsQ[candidate, "Regulator"] &&
        candidate["Regulator"] =!= regulator),
    Return[diagonalBlockDLogEpsilonFormFailure[
      "CandidateDiagonalBlockDLogEpsilonFormNotWellFormed"]]];
  transformation = candidate["Transformation"];
  letters = candidate["Letters"];
  residues = candidate["Residues"];
  localVariables = candidate["Variables"];
  If[Dimensions[transformation] =!= {dimension, dimension} ||
      Length[letters] =!= Length[residues] ||
      ! AllTrue[residues,
        MatrixQ[#] && Dimensions[#] === {dimension, dimension} &],
    Return[diagonalBlockDLogEpsilonFormFailure[
      "CandidateDiagonalBlockDLogEpsilonFormNotWellFormed"]]];
  If[localVariables === variables &&
      MemberQ[{None, Null}, Lookup[candidate, "Chart", None]],
    rules = Thread[localVariables -> variables],
    localPresentation =
      diagonalBlockDLogEpsilonFormLocalParametrization[
        candidate, system, presentationData];
    If[AssociationQ[localPresentation] &&
        Lookup[localPresentation, "DataType", None] =!=
          "RationalizingParametrization",
      Return[localPresentation]];
    coordinateRecord = <|"CoefficientVariables" -> localVariables|>;
    If[AssociationQ[localPresentation],
      coordinateRecord = Append[coordinateRecord,
        "RationalizingParametrization" -> localPresentation]];
    coordinateMap = masterTransportRecordCoordinateMap[
      coordinateRecord, presentationData];
    If[Lookup[coordinateMap, "Status", None] =!= "OK",
      Return[diagonalBlockDLogEpsilonFormFailure[
        "LocalDiagonalBlockCoefficientPresentationNotComposable", <|
          "Reason" -> Lookup[coordinateMap, "Status", None]|>]]];
    rules = coordinateMap["CoefficientVariableRules"]
  ];
  mappedTransformation = Map[Cancel[Together[#]] &,
    diagonalBlockDLogEpsilonFormReplaceDeclaredRoots[
      transformation /. rules, presentationData], {2}];
  mappedLetters = Cancel[Together[#]] & /@
    diagonalBlockDLogEpsilonFormReplaceDeclaredRoots[
      letters /. rules, presentationData];
  If[localVariables =!= variables &&
      ! FreeQ[{mappedTransformation, mappedLetters},
        Alternatives @@ localVariables],
    Return[diagonalBlockDLogEpsilonFormFailure[
      "LocalDiagonalBlockVariablesSurviveComposition"]]];
  <|"Status" -> "OK",
    "BasisTransformationMatrix" -> mappedTransformation,
    "Letters" -> mappedLetters,
    "ConstantResidueMatrices" -> residues,
    "CandidateProvenance" -> Join[<|
        "Type" -> Which[
          internallyConstructed &&
              AssociationQ[Lookup[candidate, "Chart", None]],
            "ReexpressedLocalDiagonalBlockEpsFormCandidateConstruction",
          internallyConstructed,
            "ReexpressedDiagonalBlockEpsFormCandidateConstruction",
          AssociationQ[Lookup[candidate, "Chart", None]],
            "ReexpressedLocalDiagonalBlockEpsFormExactGate",
          True, "ReexpressedDiagonalBlockEpsFormExactGate"],
        "Accepted" -> True,
        "LocalGateMethod" -> Lookup[candidate, "Method", None]|>,
      If[internallyConstructed,
        <|"ConstructionPrimes" -> constructionPrimes|>, <||>]]|>
];
diagonalBlockDLogEpsilonFormCandidateData[_, _, _, _, ___] :=
  diagonalBlockDLogEpsilonFormFailure[
    "CandidateDiagonalBlockDLogEpsilonFormNotWellFormed"];

diagonalBlockDLogEpsilonFormValidationData[pullback_Association,
    transformation_?MatrixQ, letters_List, residues_List] := Module[
  {variables, sourceVariables, regulator, dimension, target,
   transformationDerivatives, residueVariables, generatorExpressions,
   structuralConditions},
  variables = pullback["CoefficientVariables"];
  sourceVariables = pullback["SourceVariables"];
  regulator = pullback["DimensionalRegulator"];
  dimension = Length[transformation];
  If[Dimensions[transformation] =!= {dimension, dimension} ||
      Length[letters] =!= Length[residues] ||
      ! AllTrue[residues,
        MatrixQ[#] && Dimensions[#] === {dimension, dimension} &],
    Return[diagonalBlockDLogEpsilonFormFailure[
      "DiagonalBlockDLogEpsilonFormCandidateDimensionsInvalid"]]];
  target = Table[
    If[letters === {}, ConstantArray[0, {dimension, dimension}],
      regulator Total[MapThread[
        #1 diagonalBlockDLogEpsilonFormDerivative[#2,
            variables[[direction]], pullback["PresentationData"]]/#2 &,
        {residues, letters}]]],
    {direction, 2}];
  transformationDerivatives = Table[
    Map[diagonalBlockDLogEpsilonFormDerivative[#,
        variables[[direction]], pullback["PresentationData"]] &,
      transformation, {2}], {direction, 2}];
  generatorExpressions = If[
    Lookup[pullback["PresentationData"], "PresentationKind", None] ===
      "SquareRootGeneratorsAndQuadraticRelations",
    Lookup[pullback["PresentationData", "SquareRootGenerators"],
      "Generator", {}], {}];
  residueVariables = DeleteDuplicates[
    Join[sourceVariables, variables, {regulator}, generatorExpressions]];
  structuralConditions = <|
    "DeclaredCoefficientPresentationReverified" -> True,
    "SourceConnectionPulledBackByDeclaredSubstitution" -> True,
    "LettersDimensionalRegulatorFree" -> FreeQ[letters, regulator],
    "LettersUseFamilyCoefficientVariables" ->
      (sourceVariables === variables ||
        FreeQ[letters, Alternatives @@ sourceVariables]),
    "ConstantResidueMatrices" ->
      FreeQ[residues, Alternatives @@ residueVariables]|>;
  <|
    "Status" -> "OK",
    "Variables" -> variables,
    "Regulator" -> regulator,
    "PresentationData" -> pullback["PresentationData"],
    "ConnectionMatrices" -> pullback["ConnectionMatrices"],
    "BasisTransformationMatrix" -> transformation,
    "BasisTransformationDerivatives" -> transformationDerivatives,
    "DLogConnectionMatrices" -> target,
    "StructuralConditions" -> structuralConditions|>
];

diagonalBlockDLogEpsilonFormReplaceGeneratorValues[expression_,
    rootRecords_List, rootValues_List] := Module[
  {generators, result, replace},
  generators = Lookup[rootRecords, "Generator", {}];
  result = expression /. Thread[generators -> rootValues];
  replace[Power[base_, exponent_Rational] /;
      Denominator[exponent] === 2] := Module[{index},
    index = SelectFirst[Range[Length[rootRecords]],
      TrueQ[Together[base -
        rootRecords[[#, "QuadraticRadicand"]]] === 0] &, None];
    If[index === None, Power[base, exponent],
      rootValues[[index]]^(2 exponent)]
  ];
  replace[value_] := value;
  result /. radical : Power[_, exponent_Rational /;
      Denominator[exponent] === 2] :> replace[radical]
];

diagonalBlockDLogEpsilonFormModularValue[expression_, scalarRules_List,
    rootRecords_List, rootValues_List, prime_Integer] := Module[
  {value, numerator, denominator},
  value = Quiet[Check[
    diagonalBlockDLogEpsilonFormReplaceGeneratorValues[
      expression, rootRecords, rootValues] /. scalarRules, $Failed]];
  If[value === $Failed, Return[$Failed]];
  value = Quiet[Check[Together[value], $Failed]];
  If[value === $Failed ||
      ! IntegerQ[Numerator[value]] || ! IntegerQ[Denominator[value]],
    Return[$Failed]];
  numerator = Mod[Numerator[value], prime];
  denominator = Mod[Denominator[value], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

diagonalBlockDLogEpsilonFormModularMatrix[matrix_?MatrixQ,
    scalarRules_List, rootRecords_List, rootValues_List,
    prime_Integer] := Module[
  {values},
  values = Map[diagonalBlockDLogEpsilonFormModularValue[#,
      scalarRules, rootRecords, rootValues, prime] &, matrix, {2}];
  If[FreeQ[values, $Failed], values, $Failed]
];

diagonalBlockDLogEpsilonFormModularCheck[data_Association,
    prime_Integer, coefficientPoint_List, regulatorValue_Integer,
    suppliedRootValues_: Automatic] := Module[
  {variables, regulator, presentationData, rootRecords, scalarRules,
   radicandValues, rootValues, signs, sheetRootValues, transformation,
   transformationDerivatives, connection, target,
   tValue, derivativeValues, connectionValues, targetValues,
   determinant, residuals,
   checkedSheets = 0},
  variables = data["Variables"];
  regulator = data["Regulator"];
  presentationData = data["PresentationData"];
  If[! PrimeQ[prime] || prime <= 3 || Mod[prime, 4] =!= 3 ||
      ! MatchQ[coefficientPoint, {_Integer, _Integer}] ||
      ! IntegerQ[regulatorValue],
    Return[<|"Status" -> "FiniteFieldSamplePointInvalid"|>]];
  scalarRules = Join[Thread[variables -> Mod[coefficientPoint, prime]],
    {regulator -> Mod[regulatorValue, prime]}];
  rootRecords = If[Lookup[presentationData, "PresentationKind", None] ===
      "SquareRootGeneratorsAndQuadraticRelations",
    presentationData["SquareRootGenerators"], {}];
  radicandValues = diagonalBlockDLogEpsilonFormModularValue[
      #["QuadraticRadicand"], scalarRules, {}, {}, prime] & /@
        rootRecords;
  If[! FreeQ[radicandValues, $Failed] ||
      MemberQ[radicandValues, 0] ||
      ! AllTrue[radicandValues,
        PowerMod[#, Quotient[prime - 1, 2], prime] === 1 &],
    Return[<|"Status" -> "FiniteFieldSamplePointUnavailable"|>]];
  rootValues = If[suppliedRootValues === Automatic,
    PowerMod[#, Quotient[prime + 1, 4], prime] & /@ radicandValues,
    Mod[suppliedRootValues, prime]];
  If[Length[rootValues] =!= Length[rootRecords] ||
      ! And @@ MapThread[Mod[#1^2 - #2, prime] === 0 &,
        {rootValues, radicandValues}],
    Return[<|"Status" -> "FiniteFieldSquareRootValuesInvalid"|>]];
  transformation = data["BasisTransformationMatrix"];
  transformationDerivatives = data["BasisTransformationDerivatives"];
  connection = data["ConnectionMatrices"];
  target = data["DLogConnectionMatrices"];
  signs = Tuples[{1, -1}, Length[rootRecords]];
  Do[
    sheetRootValues = Mod[sign rootValues, prime];
    tValue = diagonalBlockDLogEpsilonFormModularMatrix[transformation,
      scalarRules, rootRecords, sheetRootValues, prime];
    derivativeValues =
      diagonalBlockDLogEpsilonFormModularMatrix[#,
        scalarRules, rootRecords, sheetRootValues, prime] & /@
          transformationDerivatives;
    connectionValues =
      diagonalBlockDLogEpsilonFormModularMatrix[#,
        scalarRules, rootRecords, sheetRootValues, prime] & /@ connection;
    targetValues =
      diagonalBlockDLogEpsilonFormModularMatrix[#,
        scalarRules, rootRecords, sheetRootValues, prime] & /@ target;
    If[! FreeQ[{tValue, derivativeValues, connectionValues, targetValues},
          $Failed],
      Return[<|"Status" -> "FiniteFieldSamplePointUnavailable"|>,
        Module]];
    determinant = Mod[Det[tValue], prime];
    If[determinant === 0,
      Return[<|"Status" -> "FiniteFieldSamplePointUnavailable"|>,
        Module]];
    residuals = Table[Mod[
      derivativeValues[[direction]] -
        connectionValues[[direction]] . tValue +
        tValue . targetValues[[direction]], prime],
      {direction, 2}];
    If[! AllTrue[Flatten[residuals], # === 0 &],
      Return[<|"Status" -> "FiniteFieldValidationFailed",
        "FailedSheet" -> sign|>, Module]];
    checkedSheets++,
    {sign, signs}];
  <|"Status" -> "FiniteFieldValidationPassed",
    "Prime" -> prime,
    "CoefficientVariablePoint" ->
      Thread[variables -> Mod[coefficientPoint, prime]],
    "DimensionalRegulatorValue" ->
      (regulator -> Mod[regulatorValue, prime]),
    "SquareRootGeneratorBaseValues" -> rootValues,
    "SquareRootSheetCount" -> checkedSheets,
    "AllSquareRootSheetsChecked" -> True,
    "Passed" -> True|>
];

diagonalBlockDLogEpsilonFormGenerateSamples[data_Association,
    primes_List, pointsPerPrime_Integer, seed_Integer,
    maximumAttempts_Integer] := Module[
  {samples = {}, attempts, accepted, values, check},
  BlockRandom[
    SeedRandom[seed, Method -> "MersenneTwister"];
    Do[
      attempts = 0; accepted = 0;
      While[accepted < pointsPerPrime && attempts < maximumAttempts,
        attempts++;
        values = RandomInteger[{2, prime - 2}, 3];
        check = diagonalBlockDLogEpsilonFormModularCheck[data, prime,
          values[[1 ;; 2]], values[[3]]];
        Which[
          Lookup[check, "Status", None] ===
              "FiniteFieldValidationPassed",
            AppendTo[samples, check]; accepted++,
          Lookup[check, "Status", None] ===
              "FiniteFieldSamplePointUnavailable",
            Null,
          True,
            Return[diagonalBlockDLogEpsilonFormFailure[
              "DiagonalBlockDLogEpsilonFormValidationFailed", <|
                "FailedSample" -> check|>], Module]
        ]
      ];
      If[accepted < pointsPerPrime,
        Return[diagonalBlockDLogEpsilonFormFailure[
          "FiniteFieldValidationPointsInsufficient", <|
            "Prime" -> prime, "AcceptedPoints" -> accepted,
            "RequiredPoints" -> pointsPerPrime,
            "Attempts" -> attempts|>], Module]],
      {prime, primes}]
  ];
  <|"Status" -> "FiniteFieldValidationPassed",
    "Samples" -> samples|>
];

diagonalBlockDLogEpsilonFormReplaySamples[data_Association,
    samples_List] := Module[{checks},
  checks = Map[Function[sample,
    If[! AssociationQ[sample] ||
        ! IntegerQ[Lookup[sample, "Prime", Missing[]]] ||
        ! MatchQ[Lookup[sample, "CoefficientVariablePoint", Missing[]],
          {_Rule, _Rule}] ||
        First /@ sample["CoefficientVariablePoint"] =!= data["Variables"] ||
        ! MatchQ[Lookup[sample, "DimensionalRegulatorValue", Missing[]],
          _Rule] ||
        First[sample["DimensionalRegulatorValue"]] =!= data["Regulator"] ||
        ! ListQ[Lookup[sample, "SquareRootGeneratorBaseValues",
          Missing[]]],
      <|"Status" -> "FiniteFieldStoredSampleInvalid"|>,
      Module[{replayed = diagonalBlockDLogEpsilonFormModularCheck[data,
          sample["Prime"], Last /@ sample["CoefficientVariablePoint"],
          Last[sample["DimensionalRegulatorValue"]],
          sample["SquareRootGeneratorBaseValues"]]},
        If[Lookup[replayed, "Status", None] ===
              "FiniteFieldValidationPassed" &&
            TrueQ[Lookup[sample, "Passed", False]] &&
            TrueQ[Lookup[sample, "AllSquareRootSheetsChecked", False]] &&
            Lookup[sample, "SquareRootSheetCount", Missing[]] ===
              replayed["SquareRootSheetCount"],
          replayed,
          <|"Status" -> "FiniteFieldStoredSampleReplayFailed"|>]]]],
    samples];
  <|"Status" -> If[AllTrue[checks,
      Lookup[#, "Status", None] === "FiniteFieldValidationPassed" &],
      "FiniteFieldValidationPassed", "FiniteFieldValidationFailed"],
    "Checks" -> checks|>
];

diagonalBlockDLogEpsilonFormValidation[pullback_Association,
    transformation_?MatrixQ, letters_List, residues_List,
    candidateProvenance_Association, method_String, primes_List,
    pointsPerPrime_Integer, seed_Integer, maximumAttempts_Integer,
    storedSamples_: Automatic] := Module[
  {data, structuralConditions, validationResult, equationConditions,
   presentationData, determinant, residuals, validation},
  data = diagonalBlockDLogEpsilonFormValidationData[pullback,
    transformation, letters, residues];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  structuralConditions = data["StructuralConditions"];
  If[! AllTrue[Values[structuralConditions], TrueQ],
    Return[diagonalBlockDLogEpsilonFormFailure[
      "DiagonalBlockDLogEpsilonFormValidationFailed", <|
        "Validation" -> <|"Method" -> method,
          "Passed" -> False, "Conditions" -> structuralConditions|>|>]]];
  presentationData = data["PresentationData"];
  Switch[method,
    "CharacteristicZeroSymbolicIdentity",
      determinant = Det[transformation];
      residuals = Table[
        data["BasisTransformationDerivatives"][[direction]] -
          data["ConnectionMatrices"][[direction]] . transformation +
          transformation . data["DLogConnectionMatrices"][[direction]],
        {direction, 2}];
      equationConditions = <|
        "BasisTransformationInvertible" ->
          ! diagonalBlockDLogEpsilonFormSymbolicZeroQ[
            determinant, presentationData],
        "FirstCoefficientVariableTransformationEquation" ->
          diagonalBlockDLogEpsilonFormSymbolicZeroMatrixQ[
            residuals[[1]], presentationData],
        "SecondCoefficientVariableTransformationEquation" ->
          diagonalBlockDLogEpsilonFormSymbolicZeroMatrixQ[
            residuals[[2]], presentationData]|>;
      validationResult = <||>,
    "ProbabilisticFiniteFieldSampling",
      If[! MatchQ[primes, {__Integer}] ||
          ! DuplicateFreeQ[primes] ||
          ! AllTrue[primes,
            PrimeQ[#] && # > 3 && Mod[#, 4] === 3 &] ||
          ! IntegerQ[pointsPerPrime] || pointsPerPrime < 1 ||
          ! IntegerQ[seed] || ! IntegerQ[maximumAttempts] ||
          (storedSamples === Automatic &&
            maximumAttempts < pointsPerPrime),
        Return[diagonalBlockDLogEpsilonFormFailure[
          "FiniteFieldValidationOptionsInvalid"]]];
      validationResult = If[storedSamples === Automatic,
        diagonalBlockDLogEpsilonFormGenerateSamples[data, primes,
          pointsPerPrime, seed, maximumAttempts],
        diagonalBlockDLogEpsilonFormReplaySamples[data, storedSamples]];
      If[Lookup[validationResult, "Status", None] =!=
          "FiniteFieldValidationPassed",
        Return[Join[diagonalBlockDLogEpsilonFormFailure[
          "DiagonalBlockDLogEpsilonFormValidationFailed"],
          KeyDrop[validationResult, "Status"]]]];
      equationConditions = <|
        "BasisTransformationInvertibleAtValidationSamples" -> True,
        "FirstCoefficientVariableTransformationEquationAtValidationSamples" ->
          True,
        "SecondCoefficientVariableTransformationEquationAtValidationSamples" ->
          True|>,
    _, Return[diagonalBlockDLogEpsilonFormFailure[
      "DiagonalBlockDLogEpsilonFormValidationMethodInvalid"]]
  ];
  structuralConditions = Join[structuralConditions, equationConditions];
  validation = Join[<|
    "Method" -> method,
    "Passed" -> AllTrue[Values[structuralConditions], TrueQ],
    "Exact" -> (method === "CharacteristicZeroSymbolicIdentity"),
    "Probabilistic" ->
      (method === "ProbabilisticFiniteFieldSampling"),
    "CandidateProvenance" -> candidateProvenance,
    "CoefficientPresentationType" -> presentationData["DataType"],
    "Conditions" -> structuralConditions|>,
    If[method === "ProbabilisticFiniteFieldSampling", <|
      "Primes" -> primes,
      "PointsPerPrime" -> pointsPerPrime,
      "Seed" -> seed,
      "Samples" -> If[storedSamples === Automatic,
        validationResult["Samples"], storedSamples]|>, <||>]];
  If[TrueQ[validation["Passed"]],
    <|"Status" -> "DiagonalBlockDLogEpsilonFormValidationPassed",
      "Validation" -> validation|>,
    diagonalBlockDLogEpsilonFormFailure[
      "DiagonalBlockDLogEpsilonFormValidationFailed", <|
        "Validation" -> validation|>]]
];

diagonalBlockDLogEpsilonFormStoredValidationQ[validation_] :=
  AssociationQ[validation] &&
    TrueQ[Lookup[validation, "Passed", False]] &&
    AssociationQ[Lookup[validation, "CandidateProvenance", Missing[]]] &&
    TrueQ[Lookup[validation["CandidateProvenance"],
      "Accepted", False]] &&
    AssociationQ[Lookup[validation, "Conditions", Missing[]]] &&
    AllTrue[Values[validation["Conditions"]], TrueQ] &&
    Switch[Lookup[validation, "Method", None],
      "CharacteristicZeroSymbolicIdentity",
        TrueQ[Lookup[validation, "Exact", False]] &&
          ! TrueQ[Lookup[validation, "Probabilistic", True]],
      "ProbabilisticFiniteFieldSampling",
        ! TrueQ[Lookup[validation, "Exact", True]] &&
          TrueQ[Lookup[validation, "Probabilistic", False]] &&
          MatchQ[Lookup[validation, "Primes", Missing[]], {__Integer}] &&
          DuplicateFreeQ[validation["Primes"]] &&
          AllTrue[validation["Primes"],
            PrimeQ[#] && # > 3 && Mod[#, 4] === 3 &] &&
          IntegerQ[Lookup[validation, "PointsPerPrime", Missing[]]] &&
          validation["PointsPerPrime"] >= 1 &&
          IntegerQ[Lookup[validation, "Seed", Missing[]]] &&
          MatchQ[Lookup[validation, "Samples", Missing[]],
            {__Association}] &&
          Length[validation["Samples"]] ===
            Length[validation["Primes"]] validation["PointsPerPrime"] &&
          AllTrue[Lookup[validation["Samples"], "Prime", {}],
            MemberQ[validation["Primes"], #] &] &&
          And @@ (Count[
              Lookup[validation["Samples"], "Prime", {}], #] ===
                validation["PointsPerPrime"] & /@ validation["Primes"]) &&
          AllTrue[validation["Samples"],
            TrueQ[Lookup[#, "Passed", False]] &&
              TrueQ[Lookup[#, "AllSquareRootSheetsChecked", False]] &],
      _, False
    ];

Options[ConstructDiagonalBlockDLogEpsilonForm] = {
  "CandidateDiagonalBlockDLogEpsilonForm" -> Automatic,
  "DiagonalBlockEpsFormOptions" -> {},
  "ValidationMethod" -> "ProbabilisticFiniteFieldSampling",
  "FiniteFieldPrimes" -> {2147482951, 2147482943},
  "PointsPerPrime" -> 2,
  "Seed" -> 20260904,
  "MaximumAttemptsPerPrime" -> 100
};

ConstructDiagonalBlockDLogEpsilonForm[system_Association,
    coefficientPresentation_Association, blockRows_List,
    OptionsPattern[]] := Module[
  {dimension, presentationData, pullback, variables, regulator,
   candidate, solverOptions, allowedOptions, unknownOptions, solved,
   candidateData, transformation, letters, residues, validation,
   sourceBlock, sourceVariables, disallowedOptions, validationPrimes,
   constructionPrimes, internalCandidate},
  If[! diagonalBlockDLogEpsilonFormSystemQ[system],
    Return[diagonalBlockDLogEpsilonFormFailure[
      "FamilyDifferentialSystemNotWellFormed"]]];
  dimension = Length[system["OriginalMasterIntegralBasis"]];
  If[! diagonalBlockDLogEpsilonFormRowsQ[blockRows, dimension],
    Return[diagonalBlockDLogEpsilonFormFailure["BlockRowsInvalid"]]];
  presentationData = diagonalBlockDLogEpsilonFormPresentationData[
    system, coefficientPresentation];
  If[Lookup[presentationData, "Status", None] =!= "OK",
    Return[presentationData]];
  pullback = diagonalBlockDLogEpsilonFormPullback[
    system, presentationData, blockRows];
  If[Lookup[pullback, "Status", None] =!= "OK", Return[pullback]];
  variables = pullback["CoefficientVariables"];
  regulator = pullback["DimensionalRegulator"];
  candidate = OptionValue["CandidateDiagonalBlockDLogEpsilonForm"];
  If[candidate === Automatic,
    solverOptions = OptionValue["DiagonalBlockEpsFormOptions"];
    If[! ListQ[solverOptions] ||
        ! AllTrue[solverOptions, MatchQ[#, _Rule | _RuleDelayed] &],
      Return[diagonalBlockDLogEpsilonFormFailure[
        "DiagonalBlockEpsFormOptionsInvalid"]]];
    allowedOptions = First /@ Options[DiagonalBlockEpsForm];
    unknownOptions = Complement[First /@ solverOptions, allowedOptions];
    disallowedOptions = {"ChartRetry",
      "ReturnCandidateBeforeCertification",
      "ReturnCandidateBeforeExactEquationCheck"};
    If[unknownOptions =!= {} ||
        Intersection[First /@ solverOptions, disallowedOptions] =!= {},
      Return[diagonalBlockDLogEpsilonFormFailure[
        "DiagonalBlockEpsFormOptionsInvalid", <|
          "UnknownOrDisallowedOptions" ->
            Union[unknownOptions,
              Intersection[First /@ solverOptions,
                disallowedOptions]]|>]]];
    sourceVariables = system["KinematicVariables"];
    sourceBlock = Normal /@
      system["ConnectionMatrices"][[All, blockRows, blockRows]];
    solved = Quiet[Check[
      DiagonalBlockEpsForm[sourceBlock, sourceVariables,
        regulator, Sequence @@ solverOptions, "ChartRetry" -> True,
        "ReturnCandidateBeforeCertification" -> True],
      $Failed]];
    If[! AssociationQ[solved] ||
        Lookup[solved, "Status", None] =!= "CandidateConstructed",
      Return[diagonalBlockDLogEpsilonFormFailure[
        "DiagonalBlockDLogEpsilonFormNotConstructed", <|
          "SolverStatus" -> If[AssociationQ[solved],
            Lookup[solved, "Status", None], $Failed]|>]]];
    internalCandidate = solved;
    candidateData = diagonalBlockDLogEpsilonFormCandidateData[
      internalCandidate, system, blockRows, presentationData, True],
    candidateData = diagonalBlockDLogEpsilonFormCandidateData[
      candidate, system, blockRows, presentationData];
    If[Lookup[candidateData, "Status", None] =!= "OK",
      Return[candidateData]]
  ];
  transformation = candidateData["BasisTransformationMatrix"];
  letters = candidateData["Letters"];
  residues = candidateData["ConstantResidueMatrices"];
  validationPrimes = OptionValue["FiniteFieldPrimes"];
  constructionPrimes = Lookup[
    candidateData["CandidateProvenance"], "ConstructionPrimes", {}];
  If[OptionValue["ValidationMethod"] ===
        "ProbabilisticFiniteFieldSampling" &&
      StringContainsQ[
        Lookup[candidateData["CandidateProvenance"], "Type", ""],
        "CandidateConstruction"] &&
      ListQ[validationPrimes] &&
      Intersection[constructionPrimes, validationPrimes] =!= {},
    Return[diagonalBlockDLogEpsilonFormFailure[
      "FiniteFieldValidationPrimesOverlapConstructionPrimes", <|
        "ConstructionPrimes" -> constructionPrimes,
        "ValidationPrimes" -> validationPrimes|>]]];
  validation = diagonalBlockDLogEpsilonFormValidation[pullback,
    transformation, letters, residues,
    candidateData["CandidateProvenance"], OptionValue["ValidationMethod"],
    validationPrimes, OptionValue["PointsPerPrime"],
    OptionValue["Seed"], OptionValue["MaximumAttemptsPerPrime"]];
  If[Lookup[validation, "Status", None] =!=
      "DiagonalBlockDLogEpsilonFormValidationPassed",
    Return[validation]];
  <|
    "DataType" -> "DiagonalBlockDLogEpsilonForm",
    "SchemaVersion" -> 2,
    "BlockRows" -> blockRows,
    "CoefficientVariables" -> variables,
    "DimensionalRegulator" -> regulator,
    "BasisTransformationMatrix" -> transformation,
    "Letters" -> letters,
    "ConstantResidueMatrices" -> residues,
    "Status" -> "DLogEpsilonFormValidated",
    "Validation" -> validation["Validation"]|>
];
ConstructDiagonalBlockDLogEpsilonForm[___] :=
  diagonalBlockDLogEpsilonFormFailure[
    "DiagonalBlockDLogEpsilonFormConstructionArgumentsInvalid"];

DiagonalBlockDLogEpsilonFormQ[record_Association,
    system_Association, coefficientPresentation_Association] := Module[
  {requiredKeys, blockRows, dimension, presentationData, pullback,
   transformation, letters, residues, storedValidation, validation},
  requiredKeys = {"DataType", "SchemaVersion", "BlockRows",
    "CoefficientVariables", "DimensionalRegulator",
    "BasisTransformationMatrix", "Letters", "ConstantResidueMatrices",
    "Status", "Validation"};
  If[Sort[Keys[record]] =!= Sort[requiredKeys] ||
      Lookup[record, "DataType", None] =!=
        "DiagonalBlockDLogEpsilonForm" ||
      Lookup[record, "SchemaVersion", None] =!= 2 ||
      Lookup[record, "Status", None] =!= "DLogEpsilonFormValidated" ||
      ! diagonalBlockDLogEpsilonFormSystemQ[system], Return[False]];
  storedValidation = Lookup[record, "Validation", Missing[]];
  If[! diagonalBlockDLogEpsilonFormStoredValidationQ[storedValidation],
    Return[False]];
  dimension = Length[system["OriginalMasterIntegralBasis"]];
  blockRows = Lookup[record, "BlockRows", Missing[]];
  If[! diagonalBlockDLogEpsilonFormRowsQ[blockRows, dimension],
    Return[False]];
  presentationData = diagonalBlockDLogEpsilonFormPresentationData[
    system, coefficientPresentation];
  If[Lookup[presentationData, "Status", None] =!= "OK" ||
      Lookup[record, "CoefficientVariables", Missing[]] =!=
        masterTransportPresentationVariables[presentationData] ||
      Lookup[record, "DimensionalRegulator", Missing[]] =!=
        system["DimensionalRegulator"], Return[False]];
  pullback = diagonalBlockDLogEpsilonFormPullback[
    system, presentationData, blockRows];
  If[Lookup[pullback, "Status", None] =!= "OK", Return[False]];
  transformation = Lookup[record, "BasisTransformationMatrix", Missing[]];
  letters = Lookup[record, "Letters", Missing[]];
  residues = Lookup[record, "ConstantResidueMatrices", Missing[]];
  If[! MatrixQ[transformation] || ! ListQ[letters] || ! ListQ[residues] ||
      Dimensions[transformation] =!=
        {Length[blockRows], Length[blockRows]} ||
      Length[letters] =!= Length[residues] ||
      ! AllTrue[residues, MatrixQ[#] &&
        Dimensions[#] === {Length[blockRows], Length[blockRows]} &],
    Return[False]];
  validation = diagonalBlockDLogEpsilonFormValidation[pullback,
    transformation, letters, residues,
    storedValidation["CandidateProvenance"],
    storedValidation["Method"],
    Lookup[storedValidation, "Primes", {}],
    Lookup[storedValidation, "PointsPerPrime", 1],
    Lookup[storedValidation, "Seed", 0], 1,
    If[storedValidation["Method"] ===
        "ProbabilisticFiniteFieldSampling",
      storedValidation["Samples"], Automatic]];
  Lookup[validation, "Status", None] ===
    "DiagonalBlockDLogEpsilonFormValidationPassed"
];
DiagonalBlockDLogEpsilonFormQ[___] := False;
