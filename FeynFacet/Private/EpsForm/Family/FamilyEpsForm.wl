(* Family dlog epsilon-form validation: normalize the candidate construction
   record and re-derive the defining mathematical equations.  The
   context-safe artifact I/O
   (FamilyArtifactRead/FamilyArtifactWrite) lives in Core/Core.wl since
   the layer pass of 2026-09-02: every layer reads artifacts.

   Terminology (user decision 2026-08-20): "diagonal block" is an
   irreducible diagonal subsystem of a family connection (the stage-1
   unit carrying a class epsilon form); "off-diagonal block (k,j)" is
   its coupling into lower diagonal block j, the unit the family
   completion solves by an off-diagonal basis-transformation block.

   The validator was moved here from ObservableTransport.wl on
   2026-08-20; its mathematics is unchanged apart from the diagonal-
   block normalization, which now accepts both historical "Blocks"
   layouts. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[FamilyEpsilonFormRecord,
  ValidateFamilyDLogEpsilonForm,
  ExactlyValidatedFamilyDLogEpsilonFormQ,
  ValidatedFamilyDLogEpsilonFormQ];
ClearAll[
  familyEpsFormDiagonalBlocks,
  familyEpsFormRegulatorRootFrames,
  familyEpsFormSquareRootRecords,
  familyEpsFormDegreeData, familyEpsFormEvaluate,
  familyEpsFormIdentitiesAtPoints, familyDLogEpsilonFormV2Q
];

(* A persisted family dlog epsilon form is a complete V2 mathematical record,
   not the non-persisted result returned by the validator.  This schema boundary is
   deliberately structural: the defining equation is validated once, by
   ValidateFamilyDLogEpsilonForm, before the script-side constructor writes the
   complete record. *)
familyDLogEpsilonFormV2Q[record_Association] :=
  Lookup[record, "DataType", None] === "FamilyDLogEpsilonForm" &&
    Lookup[record, "SchemaVersion", None] === 2 &&
    Lookup[record, "Status", None] ===
      "FamilyDLogEpsilonFormValidated" &&
    ContainsAll[Keys[record], {
      "Family", "CoefficientPresentation", "CoefficientVariables",
      "DimensionalRegulator", "OriginalMasterIntegralBasis",
      "BlockDecomposition", "BasisTransformationMatrix", "Letters",
      "ConstantResidueMatrices", "Validation"}];
familyDLogEpsilonFormV2Q[_] := False;

(* Diagonal-block list normalization. Two layouts exist in shipped
   records: plain index lists {{i..}..}, and annotated pairs
   {{{i..}, classId}..} written by some standardized-route runs. Both
   must flatten to a permutation of 1..dimension. *)
familyEpsFormDiagonalBlocks[blocks_, dimension_Integer] := Module[{plain},
  plain = Which[
    MatchQ[blocks, {{__Integer} ..}], blocks,
    MatchQ[blocks, {{{__Integer}, _} ..}], First /@ blocks,
    True, $Failed];
  If[plain === $Failed || Sort[Flatten[plain]] =!= Range[dimension],
    $Failed, plain]
];

(* Root-frame evidence is attached to the factorization which introduced
   it.  Collect both truncation-level and final-family records; a graded
   factorization without its frame is not silently treated as the selected
   coefficient presentation's
   smaller coefficient field. *)
familyEpsFormRegulatorRootFrames[record_Association] := Module[
  {single, multiple, records, graded, missing},
  single = Lookup[record, "RegulatorFactorization", Missing["Absent"]];
  multiple = Lookup[record, "RegulatorFactorizations", {}];
  If[! MatchQ[multiple, {___Association}],
    Return[<|"Status" -> "RegulatorFactorizationMetadataInvalid"|>]];
  records = Join[If[AssociationQ[single], {single}, {}], multiple];
  graded = Select[records,
    AssociationQ[Lookup[#1, "GradedRootFrame", None]] ||
      With[{method = Lookup[#1, "Method", ""]},
        StringQ[method] && StringStartsQ[method,
          "MultiquadraticGradedAlgebra/"]] &];
  missing = Select[graded,
    ! AssociationQ[Lookup[#1, "GradedRootFrame", None]] &];
  If[missing =!= {},
    Return[<|"Status" -> "RegulatorRootFrameMetadataMissing",
      "FactorizationMethods" -> Lookup[missing, "Method", {}]|>]];
  <|"Status" -> "OK", "Frames" -> Lookup[graded, "GradedRootFrame", {}],
    "FactorizationCount" -> Length[records],
    "GradedFactorizationCount" -> Length[graded]|>
];
familyEpsFormRegulatorRootFrames[___] :=
  <|"Status" -> "RegulatorFactorizationMetadataInvalid"|>;

familyEpsFormSquareRootRecords[presentation_Association] := Module[
  {generators, records},
  generators = Lookup[presentation, "SquareRootGenerators", $Failed];
  If[! ListQ[generators], Return[$Failed]];
  records = Map[Function[generator, <|
      "Generator" -> Lookup[generator, "Generator",
        Lookup[generator, "GeneratorExpression", Missing["NotGiven"]]],
      "QuadraticRadicand" -> Lookup[generator, "QuadraticRadicand",
        Missing["NotGiven"]]|>], generators];
  If[FreeQ[records, _Missing], records, $Failed]
];

(* Schema normalization for one family epsilon-form record: canonical
   plain "Blocks", presence check for the required analytic fields.
   Returns the normalized record, or a typed <|"Status" -> ...|>. *)
FamilyEpsilonFormRecord[record_Association] := Module[
  {required, missing, transformation, dimension, blocks},
  required = {"TTotal", "EpsFormX", "EpsFormY", "Variables", "Regulator"};
  missing = Select[required, ! KeyExistsQ[record, #] &];
  If[missing =!= {},
    Return[<|"Status" -> "RecordKeysMissing", "Missing" -> missing|>]];
  transformation = record["TTotal"];
  If[! MatrixQ[transformation],
    Return[<|"Status" -> "RequiredMatricesMissing"|>]];
  dimension = Length[transformation];
  blocks = familyEpsFormDiagonalBlocks[
    Lookup[record, "Blocks", {Range[dimension]}], dimension];
  If[blocks === $Failed,
    Return[<|"Status" -> "BlockBasisPermutationInvalid",
      "Blocks" -> Lookup[record, "Blocks", Missing[]]|>]];
  Join[record, <|"Blocks" -> blocks|>]
];
FamilyEpsilonFormRecord[_] := <|"Status" -> "InputNotAssociation"|>;

Options[ValidateFamilyDLogEpsilonForm] = {
  "SourceVariables" -> Automatic,
  "CoefficientPresentation" -> Automatic,
  (* the four matrix identities (inverse, connection transformation,
     source flatness, transformed flatness):
     "Symbolic" = entrywise Together (the former path, minutes to an hour
     on a 32x32 family); "RandomPoints" = exact rational evaluation of the
     unsimplified identity at random rational points (2026-08-22): a
     nonzero numerator polynomial of total degree d vanishes at a random
     point drawn from S values per coordinate with probability <= d/S
     (Schwartz-Zippel); the degree bound d is computed from the matrices'
     numerator/denominator degrees and the bound d/S per point per entry,
     and its union over entries and points, is recorded in the validation *)
  "IdentityMethod" -> "Modular",
  "Points" -> 4,
  "ModularPoints" -> 12,
  "ModularPrimes" -> 3,
  (* Algebraic frames use a separate all-sign-sheet verifier.  Its point
     counts are smaller because one rank-r point supplies 2^r embeddings. *)
  "MultiquadraticTrainingPoints" -> 3,
  "MultiquadraticValidationPoints" -> 2,
  "MultiquadraticPrimes" -> 3,
  "MultiquadraticMaxPrimes" -> 9,
  "MultiquadraticFreshValidationPrimes" -> 2,
  "MultiquadraticMaxPrimeAttempts" -> 36,
  "MultiquadraticMaxPointAttempts" -> 320,
  "MultiquadraticRootRankLimit" -> Automatic,
  "MultiquadraticPivotSignatureQuorum" -> 2,
  "MultiquadraticPivotPilotPrimes" -> 3,
  "SymbolicPullBack" -> False   (* True: pull the source back symbolically even for the point methods (diagnostics) *)
};

(* degree data of one matrix of rational functions: maximal total degree
   of the numerators and total degree of the LCM of the denominators *)
familyEpsFormDegreeData[matrix_List, symbols_List] := Module[
  {entries = Select[Flatten[matrix], ! TrueQ[# === 0] &], numerators, factors, lcm},
  If[entries === {}, Return[{0, 0}]];
  numerators = Max[Exponent[Numerator[Together[#]], symbols, Max] & /@ entries];
  factors = Merge[Association /@ Flatten[
    ({#[[1]] -> #[[2]]} & /@ Rest[FactorList[Denominator[Together[#]]]]) & /@ entries], Max];
  lcm = Total[Total[Exponent[#, symbols]] & /@ Keys[factors] * Values[factors]];
  {numerators, lcm}];

(* exact evaluation of a matrix of rational functions at a point *)
familyEpsFormEvaluate[matrix_List, rules_List] := Quiet[Check[
  Map[Together[# /. rules] &, matrix, {2}], $Failed]];

(* the identities at random rational points, exact arithmetic; returns
   <|"OK" -> True|False, "Points" -> n, "DegreeBound" -> d, "ErrorBound" -> e|> *)
(* sourceAtPoint: rules -> {Ax(pt), Ay(pt)} (the re-expressed connection at the
   point, by the chain rule on the source connection evaluated at the
   mapped point -- no symbolic pull-back); sourceDegrees: {n, L} bound of
   the re-expressed connection's entries; sourceFlatAtPoints: verdict computed
   separately in the source variables *)
familyEpsFormIdentitiesAtPoints[sourceAtPoint_, sourceDegrees_List, epsilonForm_, transformation_,
    inverse_, variables_List, regulator_Symbol, count_Integer] := Module[
  {symbols = Append[variables, regulator], dS, degS, degSi, degA, degAp, bound,
   size = 10^12, done = 0, tries = 0, rules, S, Si, A1, A2, B1, B2, dSx, dSy, dB, src,
   residuals, ok = True, dimension = Length[transformation]},
  dS = {D[transformation, variables[[1]]], D[transformation, variables[[2]]]};
  (* degree bound of the identities' numerators: for a term that is a
     product of matrices with numerator degrees n_i and denominator-LCM
     degrees L_i, the numerator over the common denominator has degree
     <= Sum (n_i + L_i); a derivative adds L once more; the sum of terms
     is bounded by the sum over terms *)
  {degS, degSi, degAp} = familyEpsFormDegreeData[#, symbols] & /@
    {transformation, inverse, Join @@ epsilonForm};
  degA = sourceDegrees;
  bound = Max[
    2 (degS[[1]] + degS[[2]] + degSi[[1]] + degSi[[2]]),                        (* S Si - 1, Si S - 1 *)
    (degSi[[1]] + degSi[[2]]) + (degA[[1]] + degA[[2]]) + (degS[[1]] + degS[[2]]) +
      (degSi[[1]] + degSi[[2]]) + (degS[[1]] + 2 degS[[2]]) +
        (degAp[[1]] + degAp[[2]]),   (* connection transformation *)
    2 (degAp[[1]] + 2 degAp[[2]]) + 2 (degAp[[1]] + degAp[[2]])];              (* flatness *)
  While[done < count && tries < 4 count,
    tries++;
    rules = Thread[symbols -> RandomInteger[{3, size}, 3]/RandomInteger[{size, 10 size}, 3]];
    {S, Si, B1, B2, dSx, dSy} = familyEpsFormEvaluate[#, rules] & /@
      {transformation, inverse, epsilonForm[[1]], epsilonForm[[2]], dS[[1]], dS[[2]]};
    src = sourceAtPoint[rules];
    If[src === $Failed || MemberQ[{S, Si, B1, B2, dSx, dSy}, $Failed] ||
        ! FreeQ[{src, S, Si, B1, B2, dSx, dSy}, ComplexInfinity | Indeterminate | DirectedInfinity],
      Continue[]];
    {A1, A2} = src;
    dB = familyEpsFormEvaluate[D[epsilonForm[[1]], variables[[2]]] - D[epsilonForm[[2]], variables[[1]]], rules];
    If[dB === $Failed || ! FreeQ[dB, ComplexInfinity | Indeterminate | DirectedInfinity], Continue[]];
    residuals = {
      S . Si - IdentityMatrix[dimension], Si . S - IdentityMatrix[dimension],
      Si . A1 . S - Si . dSx - B1, Si . A2 . S - Si . dSy - B2,
      dB + B1 . B2 - B2 . B1};
    If[! AllTrue[Flatten[residuals], TrueQ[# == 0] &], ok = False; Break[]];
    done++];
  <|"OK" -> ok && done >= count, "Points" -> done, "DegreeBound" -> bound,
    "ErrorBound" -> If[ok && done >= count,
      N[(6 dimension^2 bound/size)^done, 3], 1]|>];

ValidateFamilyDLogEpsilonForm[record_Association, system_Association,
    OptionsPattern[]] := Module[
  {sourceVariablesOption, sourceVariables, regulator,
   coefficientPresentation, presentationData, presentationVerification,
   normalizedSystem, normalizedRecord, systemReexpression, frameSystem,
   variables,
   sourceConnection, transformation, storedInverse, inverse,
   epsilonForm, dimension, inverseResiduals, inverseOK,
   connectionTransformationResiduals, connectionTransformationOK,
   sourceFlatResidual, sourceFlat, flatResidual, flat,
   dlogDetails, dlogValid, dlogResiduals, epsilonLinear, lettersEpsilonFree,
   constantResidues, blocks, permutation, ranges,
   blockLower, validationConditions, identityMethod, identityData,
   identitySeconds, finiteFieldData, checksPassed, exact,
   probabilisticValidation, validation, validationMethod,
   presentationRelationsVerified, squareRootPresentationQ,
   squareRootGenerators, candidateLetters, finiteFieldPresentation,
   rootRankLimit, validatedRootFrame, regulatorRootFrameData,
   regulatorRootFrames, outputBase, outputPresentation},

  sourceVariablesOption = OptionValue["SourceVariables"];
  If[ListQ[sourceVariablesOption] && Length[sourceVariablesOption] =!= 2,
    Return[<|"Status" -> "SourceVariablesInvalid",
      "Expected" -> "exactly two source variables",
      "Actual" -> Length[sourceVariablesOption]|>]];
  sourceVariables = masterTransportResolveVariables[sourceVariablesOption];
  If[sourceVariables === $Failed || ! MatchQ[sourceVariables,
      {_Symbol, _Symbol}],
    Return[<|"Status" -> "SourceVariablesInvalid",
      "Expected" -> "exactly two source variables",
      "Actual" -> If[ListQ[sourceVariables], Length[sourceVariables],
        Missing["NotAList"]]|>]];

  regulator = Lookup[record, "Regulator", Automatic];
  regulator = masterTransportResolveRegulator[regulator,
    {Lookup[system, "Av", 0], Lookup[system, "Aw", 0], record},
    sourceVariables];
  If[regulator === $Failed || ! MatchQ[regulator, _Symbol],
    Return[<|"Status" -> "RegulatorNotResolved"|>]];

  coefficientPresentation = familyCoefficientPresentationFromRecord[
    record,
    OptionValue["CoefficientPresentation"]];
  If[coefficientPresentation === $Failed,
    Return[<|"Status" -> "CoefficientPresentationNotResolved"|>]];

  If[coefficientPresentation === None,
    variables = sourceVariables;
    normalizedSystem = masterTransportNormalize[system, regulator, variables];
    frameSystem = normalizedSystem;
    presentationData = None;
    presentationVerification = <|"Verified" -> True,
      "PresentationKind" -> "SourceVariables"|>;
    systemReexpression = <|
      "SourceAndCoefficientVariablesIdentical" -> True,
      "Exact" -> True|>,
    presentationData = masterTransportCoefficientPresentationData[
      coefficientPresentation, sourceVariables];
    If[! AssociationQ[presentationData] ||
        Lookup[presentationData, "Status", None] =!= "OK",
      Return[<|"Status" -> "CoefficientPresentationRefused",
        "CoefficientPresentation" -> presentationData|>]];
    variables = masterTransportPresentationVariables[presentationData];
    normalizedSystem = masterTransportNormalize[system, regulator,
      Join[sourceVariables, variables]];
    If[MemberQ[{"RandomPoints", "Modular"}, OptionValue["IdentityMethod"]] && ! TrueQ[OptionValue["SymbolicPullBack"]],
      (* No symbolic re-expression (it was about 80 s of a 146 s production
         validation): the transformed connection is evaluated at each
         point by the chain rule, Ax = Av d_x v + Aw d_x w, on the source
         connection at the mapped point; source flatness is tested in the
         source variables at random points *)
      frameSystem = <|"Av" -> normalizedSystem["Av"],
        "Aw" -> normalizedSystem["Aw"],
        "LazyCoefficientPresentation" -> presentationData|>;
      presentationVerification = Switch[
        presentationData["PresentationKind"],
        "RationalizingParametrization",
          VerifyRationalizingParametrization[coefficientPresentation],
        "SquareRootGeneratorsAndQuadraticRelations",
          Join[<|"Verified" -> True|>,
            presentationData["QuadraticRelationVerification"]],
        _, <|"Verified" -> False|>];
      systemReexpression = <|
        "SourceConnectionFlatnessEvaluation" -> "AtValidationPoints",
        "ReexpressedConnectionFlatness" ->
          "FollowsFromChainRuleWhenSourceConnectionIsFlat",
        "SourceCoordinateImagesRational" -> True,
        "DisplayedSquareRootRelationsVerified" ->
          TrueQ[presentationVerification["Verified"]],
        "ChainRule" -> "evaluated at the validation points",
        "Exact" -> False|>,
      systemReexpression = masterTransportPullBackSystem[
        normalizedSystem, presentationData,
        "SourceVariables" -> sourceVariables];
      If[! AssociationQ[systemReexpression] ||
          Lookup[systemReexpression, "Status", None] =!= "OK",
        Return[<|"Status" -> "DifferentialSystemReexpressionFailed",
          "DifferentialSystemReexpression" -> systemReexpression|>]];
      frameSystem = systemReexpression["System"];
      presentationVerification = Switch[
        presentationData["PresentationKind"],
        "RationalizingParametrization",
          VerifyRationalizingParametrization[coefficientPresentation],
        "SquareRootGeneratorsAndQuadraticRelations",
          Join[<|"Verified" -> True|>,
            presentationData["QuadraticRelationVerification"]],
        _, <|"Verified" -> False|>];
      systemReexpression = systemReexpression["Certificate"]]
  ];

  normalizedRecord = masterTransportNormalize[record, regulator,
    Join[sourceVariables, variables]];
  regulatorRootFrameData = familyEpsFormRegulatorRootFrames[normalizedRecord];
  If[Lookup[regulatorRootFrameData, "Status", None] =!= "OK",
    Return[regulatorRootFrameData]];
  regulatorRootFrames = regulatorRootFrameData["Frames"];
  squareRootPresentationQ = (AssociationQ[presentationData] &&
      Lookup[presentationData, "PresentationKind", None] ===
        "SquareRootGeneratorsAndQuadraticRelations") ||
    regulatorRootFrames =!= {};
  sourceConnection = {Lookup[frameSystem, "Av", $Failed],
    Lookup[frameSystem, "Aw", $Failed]};
  transformation = Lookup[normalizedRecord, "TTotal", $Failed];
  storedInverse = Lookup[normalizedRecord, "TTotalInverse", Automatic];
  epsilonForm = {Lookup[normalizedRecord, "EpsFormX", $Failed],
    Lookup[normalizedRecord, "EpsFormY", $Failed]};
  If[! AllTrue[Join[sourceConnection, epsilonForm, {transformation}], MatrixQ],
    Return[<|"Status" -> "RequiredMatricesMissing"|>]];
  dimension = Length[transformation];
  If[Dimensions[transformation] =!= {dimension, dimension} ||
      ! AllTrue[Join[sourceConnection, epsilonForm],
        Dimensions[#] === {dimension, dimension} &],
    Return[<|"Status" -> "MatrixDimensionsInconsistent"|>]];

  (* Whole-family records use the block order returned by the SCC ordering,
     while differential-system artifacts retain their original master order.
     The transformation therefore acts on A[[permutation,permutation]], not A.
     Record the permutation explicitly so no downstream calculation has to
     reconstruct this convention from Ranges. *)
  blocks = familyEpsFormDiagonalBlocks[
    Lookup[normalizedRecord, "Blocks", {Range[dimension]}], dimension];
  If[blocks === $Failed,
    Return[<|"Status" -> "BlockBasisPermutationInvalid",
      "Blocks" -> Lookup[normalizedRecord, "Blocks", Missing[]]|>]];
  permutation = Flatten[blocks];
  sourceConnection = Map[#[[permutation, permutation]] &,
    sourceConnection];

  inverse = If[MatrixQ[storedInverse], storedInverse,
    Quiet[Check[Map[Together, Inverse[transformation], {2}], $Failed]]];
  If[! MatrixQ[inverse] || Dimensions[inverse] =!= {dimension, dimension},
    Return[<|"Status" -> "TransformationInverseUnavailable"|>]];
  If[squareRootPresentationQ,
    squareRootGenerators = If[AssociationQ[presentationData],
      familyEpsFormSquareRootRecords[presentationData], {}];
    finiteFieldPresentation = If[AssociationQ[presentationData],
      presentationData,
      <|"DataType" -> "SourceVariableRepresentation",
        "SchemaVersion" -> 2,
        "PresentationKind" ->
          "SourceVariables",
        "SourceVariables" -> sourceVariables,
        "CoefficientVariables" -> variables,
        "SourceVariableSubstitution" ->
          Thread[sourceVariables -> variables],
        "DifferentialPullbackMatrix" -> IdentityMatrix[2],
        "JacobianDeterminant" -> 1|>];
    rootRankLimit = Replace[
      OptionValue["MultiquadraticRootRankLimit"], Automatic :>
        $familyRegulatorMaximumGradedRank];
    If[! ListQ[squareRootGenerators],
      Return[<|"Status" -> "SquareRootGeneratorMetadataInvalid",
        "SquareRootGenerators" -> squareRootGenerators|>]];
    validatedRootFrame = familyCertMQValidateRegulatorRootFrames[
      squareRootGenerators, regulatorRootFrames, variables, regulator,
      rootRankLimit];
    If[Lookup[validatedRootFrame, "Status", None] =!=
        "ValidatedRegulatorRootFrames",
      Return[<|"Status" -> "RegulatorRootFrameRelationsRefused",
        "Detail" -> validatedRootFrame|>]]];
  identityMethod = OptionValue["IdentityMethod"];
  If[! MemberQ[{"Symbolic", "RandomPoints", "Modular"}, identityMethod],
    Return[<|"Status" -> "IdentityMethodUnsupported",
      "IdentityMethod" -> identityMethod|>]];
  finiteFieldData = None;
  If[identityMethod === "Modular",
    {identitySeconds, finiteFieldData} = AbsoluteTiming[Module[
      {lazy = Lookup[frameSystem, "LazyCoefficientPresentation", None]},
      If[squareRootPresentationQ,
        candidateLetters = Lookup[normalizedRecord, "Letters", {}];
        If[! ListQ[squareRootGenerators] || ! ListQ[candidateLetters],
          familyCertMQFailure["SquareRootValidationMetadataInvalid",
            <|"SquareRootGenerators" -> squareRootGenerators,
              "Letters" -> candidateLetters|>],
          familyCertificateMultiquadratic[epsilonForm, transformation,
            inverse, variables, regulator, sourceConnection,
            sourceVariables, finiteFieldPresentation, squareRootGenerators,
            candidateLetters,
            "TrainingPoints" -> OptionValue["MultiquadraticTrainingPoints"],
            "ValidationPoints" -> OptionValue["MultiquadraticValidationPoints"],
            "Primes" -> OptionValue["MultiquadraticPrimes"],
            "MaxPrimes" -> OptionValue["MultiquadraticMaxPrimes"],
            "FreshValidationPrimes" ->
              OptionValue["MultiquadraticFreshValidationPrimes"],
            "MaxPrimeAttempts" -> OptionValue["MultiquadraticMaxPrimeAttempts"],
            "MaxPointAttempts" -> OptionValue["MultiquadraticMaxPointAttempts"],
            "RootRankLimit" -> OptionValue["MultiquadraticRootRankLimit"],
            "RegulatorRootFrames" -> regulatorRootFrames,
            "PivotSignatureQuorum" ->
              OptionValue["MultiquadraticPivotSignatureQuorum"],
            "PivotSignaturePilotPrimes" ->
              OptionValue["MultiquadraticPivotPilotPrimes"]]],
        candidateLetters = Lookup[normalizedRecord, "Letters", Automatic];
        familyCertificateModular[epsilonForm, transformation, inverse,
          variables, regulator, sourceConnection,
          If[AssociationQ[lazy], sourceVariables, variables], lazy,
          "Points" -> OptionValue["ModularPoints"],
          "Primes" -> OptionValue["ModularPrimes"],
          "CandidateLetters" -> candidateLetters,
          (* Production acceptance is the declared finite-field test.  An
             additional characteristic-zero point repeated the same matrix
             identities symbolically and contradicted that contract. *)
          "CharacteristicZeroGuard" -> False]]]];
    If[! (AssociationQ[finiteFieldData] &&
        KeyExistsQ[finiteFieldData,
          "ConnectionTransformationEquation"]),
      Return[<|"Status" -> "FiniteFieldValidationFailed",
        "FiniteFieldEvidence" -> finiteFieldData|>]];
    identityData = <|
      "Points" -> Lookup[finiteFieldData, "PointsDone", {}],
      "DegreeBound" -> Lookup[finiteFieldData, "DegreeBound", Missing[]],
      "ErrorBound" -> Lookup[finiteFieldData,
        "ErrorBoundGoodCharacteristic", 1], "OK" -> True|>;
    inverseOK = TrueQ[finiteFieldData["TransformationInverse"]];
    connectionTransformationOK =
      TrueQ[finiteFieldData["ConnectionTransformationEquation"]];
    flat = TrueQ[finiteFieldData["Flatness"]];
    sourceFlat = TrueQ[finiteFieldData["SourceFlatness"]]];
  If[identityMethod === "RandomPoints",
    {identitySeconds, identityData} = AbsoluteTiming[Module[
      {lazy = Lookup[frameSystem, "LazyCoefficientPresentation", None],
       substitution, differentialPullback, av, aw, sourceAtPoint, sourceDegrees,
       srcSymbols, srcFlat, dAvw, data},
      If[AssociationQ[lazy],
        substitution = familyCertPresentationSubstitution[lazy];
        differentialPullback =
          familyCertPresentationDifferentialPullbackMatrix[lazy];
        (* Source connection in the source variables (permuted), evaluated
           through the coefficient presentation and its differential
           pullback matrix. *)
        {av, aw} = sourceConnection;
        srcSymbols = Join[sourceVariables, {regulator}];
        dAvw = D[av, sourceVariables[[2]]] - D[aw, sourceVariables[[1]]];
        srcFlat = masterTransportPointZeroQ[dAvw + av . aw - aw . av, srcSymbols, 2];
        sourceAtPoint = Function[{rules}, Module[{map, jac, avP, awP},
          map = Thread[sourceVariables -> (Last /@ substitution /. rules)];
          jac = Quiet[Check[Map[Together[# /. rules] &,
            differentialPullback, {2}], $Failed]];
          avP = familyEpsFormEvaluate[av, Join[map, Select[rules, First[#] === regulator &]]];
          awP = familyEpsFormEvaluate[aw, Join[map, Select[rules, First[#] === regulator &]]];
          If[MemberQ[{jac, avP, awP}, $Failed], $Failed,
            {avP jac[[1, 1]] + awP jac[[2, 1]], avP jac[[1, 2]] + awP jac[[2, 2]]}]]];
        (* Degrees after re-expression: source degrees scaled by the
           substitution degree, plus the differential pullback matrix. *)
        data = familyEpsFormDegreeData[Join[av, aw], srcSymbols];
        sourceDegrees = With[{dm = Max[1, Max[Exponent[Numerator[Together[#]], variables, Max],
            Exponent[Denominator[Together[#]], variables, Max]] & /@
              (Last /@ substitution)],
            dj = Max[Exponent[Numerator[Together[#]], variables, Max] +
              Exponent[Denominator[Together[#]], variables, Max] & /@
                Flatten[differentialPullback]]},
          {data[[1]] dm + dj, data[[2]] dm + dj}],
        sourceAtPoint = Function[{rules}, Module[{a1, a2},
          a1 = familyEpsFormEvaluate[sourceConnection[[1]], rules];
          a2 = familyEpsFormEvaluate[sourceConnection[[2]], rules];
          If[MemberQ[{a1, a2}, $Failed], $Failed, {a1, a2}]]];
        sourceDegrees = familyEpsFormDegreeData[Join @@ sourceConnection, Append[variables, regulator]];
        srcFlat = masterTransportPointZeroQ[
          D[sourceConnection[[1]], variables[[2]]] - D[sourceConnection[[2]], variables[[1]]] +
            sourceConnection[[1]] . sourceConnection[[2]] - sourceConnection[[2]] . sourceConnection[[1]],
          Append[variables, regulator], 2]];
      Join[familyEpsFormIdentitiesAtPoints[sourceAtPoint, sourceDegrees, epsilonForm, transformation,
        inverse, variables, regulator, OptionValue["Points"]], <|"SourceFlat" -> srcFlat|>]]];
    identityData = Join[identityData, <|
      "Status" -> If[TrueQ[identityData["OK"]],
        "RandomPointValidationPassed", "RandomPointValidationFailed"],
      "Method" -> "RandomRationalPointEvaluation",
      "Probabilistic" -> True|>];
    inverseOK = connectionTransformationOK = flat =
      TrueQ[identityData["OK"]];
    sourceFlat = TrueQ[identityData["SourceFlat"]]];
  If[identityMethod === "Symbolic",
    identityData = <|"DegreeBound" -> Missing["Symbolic"], "ErrorBound" -> 0, "Points" -> 0|>;
    {identitySeconds, {inverseOK, connectionTransformationOK,
        sourceFlat, flat}} = AbsoluteTiming[
      inverseResiduals = {
        Map[Together, transformation . inverse - IdentityMatrix[dimension], {2}],
        Map[Together, inverse . transformation - IdentityMatrix[dimension], {2}]};
      connectionTransformationResiduals = Table[
        Map[Together,
          inverse . sourceConnection[[direction]] . transformation -
            inverse . D[transformation, variables[[direction]]] -
            epsilonForm[[direction]], {2}],
        {direction, 2}];
      sourceFlatResidual = Map[Together,
        D[sourceConnection[[1]], variables[[2]]] - D[sourceConnection[[2]], variables[[1]]] +
          sourceConnection[[1]] . sourceConnection[[2]] - sourceConnection[[2]] . sourceConnection[[1]], {2}];
      flatResidual = Map[Together,
        D[epsilonForm[[1]], variables[[2]]] - D[epsilonForm[[2]], variables[[1]]] +
          epsilonForm[[1]] . epsilonForm[[2]] - epsilonForm[[2]] . epsilonForm[[1]], {2}];
      observableTransportZeroMatrixQ /@ {inverseResiduals,
        connectionTransformationResiduals, sourceFlatResidual,
        flatResidual}]];

  dlogDetails = Which[
    identityMethod === "Modular",
    (* the dlog statement is the finite-field verdict: consistent on fresh
       validation points at every prime, residues CRT-reconstructed and
       verified at every prime; no symbolic residual is fabricated *)
    <|"Valid" -> TrueQ[finiteFieldData["DLog"]] &&
        TrueQ[finiteFieldData["ConstantResidues"]] &&
        TrueQ[finiteFieldData["LettersEpsFree"]],
      "Dimension" -> dimension, "Variables" -> variables, "Regulator" -> regulator,
      "Letters" -> finiteFieldData["Letters"],
      "Residues" -> finiteFieldData["Residues"],
      "ConstantResidues" -> TrueQ[finiteFieldData["ConstantResidues"]],
      "ResiduesVerifiedAtAllPrimes" ->
        finiteFieldData["ResiduesVerifiedAtAllPrimes"],
      "ReconstructionResidual" -> Missing["FiniteFieldValidation"]|>,
    observableTransportZeroMatrixQ[epsilonForm],
    <|"Valid" -> True, "Dimension" -> dimension,
      "Variables" -> variables, "Regulator" -> regulator,
      "Letters" -> {}, "Residues" -> {}, "ConstantResidues" -> True,
      "ReconstructionResidual" ->
        ConstantArray[0, {2, dimension, dimension}]|>,
    True,
    Quiet[Check[ValidateCanonicalForm[epsilonForm, variables,
      "Regulator" -> regulator, "Details" -> True], False]]
  ];
  dlogValid = AssociationQ[dlogDetails] &&
    TrueQ[Lookup[dlogDetails, "Valid", False]];
  dlogResiduals = If[AssociationQ[dlogDetails],
    Lookup[dlogDetails, "ReconstructionResidual", $Failed], $Failed];
  epsilonLinear = If[identityMethod === "Modular",
    TrueQ[finiteFieldData["EpsFactored"]],
    AllTrue[Flatten[epsilonForm],
      observableTransportZeroQ[#] || FreeQ[Together[#/regulator], regulator] &]];
  lettersEpsilonFree = AssociationQ[dlogDetails] &&
    FreeQ[Lookup[dlogDetails, "Letters", {regulator}], regulator];
  constantResidues = AssociationQ[dlogDetails] &&
    TrueQ[Lookup[dlogDetails, "ConstantResidues", False]];

  ranges = Lookup[normalizedRecord, "Ranges", {Range[dimension]}];
  blockLower = observableTransportBlockLowerQ[epsilonForm, ranges];
  presentationRelationsVerified = TrueQ[
    Lookup[presentationVerification, "Verified", False]];
  validationConditions = <|
    "EpsilonFactorized" -> epsilonLinear,
    "DLogReconstruction" -> dlogValid,
    "BlockLowerTriangular" -> blockLower,
    "BasisTransformationInverse" -> inverseOK,
    "ConnectionTransformationEquation" -> connectionTransformationOK,
    "SourceConnectionFlatness" -> sourceFlat,
    "TransformedConnectionFlatness" -> flat,
    "LettersIndependentOfDimensionalRegulator" -> lettersEpsilonFree,
    "ResidueMatricesConstant" -> constantResidues,
    "CoefficientPresentationRelations" -> presentationRelationsVerified
  |>;
  checksPassed = And @@ (TrueQ /@ Values[validationConditions]);
  (* Random rational-point and finite-field evaluation are probabilistic for
     every coefficient presentation.  The presence or absence of square-root
     generators cannot turn sampled equalities into characteristic-zero
     identities. *)
  probabilisticValidation =
    MemberQ[{"RandomPoints", "Modular"}, identityMethod];
  exact = checksPassed && identityMethod === "Symbolic";
  validationMethod = Switch[identityMethod,
    "Symbolic", "CharacteristicZeroSymbolicIdentity",
    "RandomPoints", "RandomRationalPointEvaluation",
    "Modular", "ProbabilisticFiniteFieldSampling",
    _, "UnsupportedIdentityMethod"];
  validation = Join[<|
    "SchemaVersion" -> 2,
    "Exact" -> exact,
    "Probabilistic" -> probabilisticValidation,
    "Method" -> validationMethod,
    "Conditions" -> validationConditions,
    "CoefficientPresentationVerification" -> presentationVerification,
    "DifferentialSystemReexpression" -> systemReexpression|>,
    If[identityMethod === "Symbolic",
      <|"CharacteristicZeroResiduals" -> <|
        "BasisTransformationInverse" -> inverseResiduals,
        "ConnectionTransformation" ->
          connectionTransformationResiduals,
        "SourceConnectionFlatness" -> sourceFlatResidual,
        "TransformedConnectionFlatness" -> flatResidual,
        "DLogReconstruction" -> dlogResiduals|>|>,
      <|"SamplingEvidence" -> If[identityMethod === "Modular",
        KeyDrop[finiteFieldData, {"Residues", "Letters"}], identityData]|>],
    If[squareRootPresentationQ,
      <|"RegulatorRootFrameValidation" -> <|
        "FactorizationCount" ->
          regulatorRootFrameData["FactorizationCount"],
        "GradedFactorizationCount" ->
          regulatorRootFrameData["GradedFactorizationCount"],
        "ValidatedFrameCount" -> Lookup[
          If[AssociationQ[finiteFieldData], finiteFieldData, <||>],
          "RegulatorRootFrameCount",
          Lookup[validatedRootFrame, "RegulatorRootFrameCount", 0]]|>|>,
      <||>]];

  If[! checksPassed,
    Return[<|
      "DataType" -> "FamilyDLogEpsilonFormValidationResult",
      "SchemaVersion" -> 2,
      "Status" -> "FamilyDLogEpsilonFormValidationFailed",
      "Family" -> Lookup[normalizedRecord, "Family", Missing["NotGiven"]],
      "Validation" -> validation,
      "ComputationMetrics" -> <|
        "IdentityValidationWallTimeSeconds" -> identitySeconds|>|>]];

  outputPresentation = If[coefficientPresentation === None,
    <|"DataType" -> "SourceVariableRepresentation",
      "SchemaVersion" -> 2,
      "SourceVariables" -> sourceVariables,
      "CoefficientVariables" -> sourceVariables,
      "SourceVariableSubstitution" ->
        Thread[sourceVariables -> sourceVariables],
      "DifferentialPullbackMatrix" -> IdentityMatrix[2],
      "JacobianDeterminant" -> 1|>,
    presentationData];
  outputBase = <|
    "DataType" -> "FamilyDLogEpsilonFormValidationResult",
    "SchemaVersion" -> 2,
    "Status" -> "FamilyDLogEpsilonFormValidationPassed",
    "Family" -> Lookup[normalizedRecord, "Family", Missing["NotGiven"]],
    "CoefficientPresentation" -> outputPresentation,
    "CoefficientVariables" -> variables,
    "DimensionalRegulator" -> regulator,
    "IrreducibleDiagonalBlocks" -> blocks,
    "BasisPermutation" -> permutation,
    "BasisTransformationMatrix" -> transformation,
    "CachedInverseBasisTransformationMatrix" -> inverse,
    "BasisTransformationConvention" ->
      "OriginalMasterIntegralVectorEqualsBasisTransformationMatrixTimesDLogBasisVector",
    "Letters" -> Lookup[dlogDetails, "Letters", {}],
    "ConstantResidueMatrices" -> Lookup[dlogDetails, "Residues", {}],
    "DifferentialEquationConvention" ->
      "dJEqualsDimensionalRegulatorTimesSumOfConstantResidueMatricesTimesDLogLettersTimesJ",
    "Validation" -> validation,
    "ComputationMetrics" -> <|
      "IdentityValidationWallTimeSeconds" -> identitySeconds|>|>;
  outputBase
];

ValidateFamilyDLogEpsilonForm[_, _, OptionsPattern[]] :=
  <|"Status" -> "InputsNotAssociations"|>;

ExactlyValidatedFamilyDLogEpsilonFormQ[record_Association] := Module[
  {validation = Lookup[record, "Validation", <||>], conditions,
   residuals},
  conditions = Lookup[validation, "Conditions", <||>];
  residuals = Lookup[validation, "CharacteristicZeroResiduals", <||>];
  familyDLogEpsilonFormV2Q[record] &&
    AssociationQ[validation] && AssociationQ[conditions] &&
    TrueQ[Lookup[validation, "Exact", False]] &&
    ! TrueQ[Lookup[validation, "Probabilistic", True]] &&
    Lookup[validation, "Method", None] ===
      "CharacteristicZeroSymbolicIdentity" &&
    Length[conditions] > 0 && And @@ (TrueQ /@ Values[conditions]) &&
    AssociationQ[residuals] && Length[residuals] > 0 &&
    AllTrue[Values[residuals], observableTransportZeroMatrixQ]
];

ExactlyValidatedFamilyDLogEpsilonFormQ[_] := False;

ValidatedFamilyDLogEpsilonFormQ[record_Association] := Module[
  {validation = Lookup[record, "Validation", <||>], conditions,
   method, evidence, evidenceConsistent},
  If[ExactlyValidatedFamilyDLogEpsilonFormQ[record], Return[True]];
  conditions = Lookup[validation, "Conditions", <||>];
  method = Lookup[validation, "Method", None];
  evidence = Lookup[validation, "SamplingEvidence", <||>];
  evidenceConsistent = Switch[method,
    "ProbabilisticFiniteFieldSampling",
      AssociationQ[evidence] &&
        Lookup[evidence, "Status", None] ===
          "FiniteFieldValidationPassed" &&
        TrueQ[Lookup[evidence, "Probabilistic", False]],
    "RandomRationalPointEvaluation",
      AssociationQ[evidence] &&
        Lookup[evidence, "Status", None] ===
          "RandomPointValidationPassed" &&
        TrueQ[Lookup[evidence, "OK", False]] &&
        TrueQ[Lookup[evidence, "Probabilistic", False]] &&
        IntegerQ[Lookup[evidence, "Points", None]] &&
        Lookup[evidence, "Points", 0] > 0,
    _, False];
  familyDLogEpsilonFormV2Q[record] &&
    AssociationQ[validation] && AssociationQ[conditions] &&
    ! TrueQ[Lookup[validation, "Exact", True]] &&
    TrueQ[Lookup[validation, "Probabilistic", False]] &&
    MemberQ[{"RandomRationalPointEvaluation",
        "ProbabilisticFiniteFieldSampling"},
      method] && evidenceConsistent && Length[conditions] > 0 &&
    And @@ (TrueQ /@ Values[conditions])
];

ValidatedFamilyDLogEpsilonFormQ[_] := False;
