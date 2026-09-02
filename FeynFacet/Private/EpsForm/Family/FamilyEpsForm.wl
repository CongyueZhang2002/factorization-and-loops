(* Family epsilon-form layer: the one module that owns family-level
   epsilon-form records -- the record schema normalizer and the exact
   whole-family certifier.  The context-safe artifact I/O
   (FamilyArtifactRead/FamilyArtifactWrite) lives in Core/Core.wl since
   the layer pass of 2026-09-02: every layer reads artifacts.

   Terminology (user decision 2026-08-20): "diagonal block" is an
   irreducible diagonal subsystem of a family connection (the stage-1
   unit carrying a class epsilon form); "off-diagonal block (k,j)" is
   its coupling into lower diagonal block j, the unit the family
   completion gauges away.

   The certifier was moved here from ObservableTransport.wl on
   2026-08-20; its mathematics is unchanged apart from the diagonal-
   block normalization, which now accepts both historical "Blocks"
   layouts. *)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[FamilyEpsilonFormRecord,
  CertifyFamilyEpsilonForm, ExactFamilyEpsilonFormQ,
  CertifiedFamilyEpsilonFormQ];
ClearAll[
  familyEpsFormDiagonalBlocks,
  familyEpsFormLegacyChart,
  familyEpsFormRegulatorRootFrames,
  familyEpsFormDegreeData, familyEpsFormEvaluate, familyEpsFormIdentitiesAtPoints
];

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

(* Legacy chart aliases: early census records store a descriptive
   substitution string instead of the catalog name.  The alias map was a
   literal project table here until 2026-08-23 (generality pass, A3); it
   now lives in the campaign's own chart file and is registered through
   TransportFamilyChartRegister as <|"ChartAlias" -> catalogName|>
   entries, so the package ships no inventory of its own.  An alias that
   is not registered leaves the record untouched, and the caller's chart
   resolution then fails typed on the unrecognized string. *)
familyEpsFormLegacyChart[record_Association] := Module[
  {chart = Lookup[record, "Chart", None], alias},
  If[! StringQ[chart], Return[record]];
  alias = transportFamilyChartAlias[chart];
  If[StringQ[alias], Join[record, <|"Chart" -> alias|>], record]
];

(* Root-frame evidence is attached to the factorization which introduced
   it.  Collect both truncation-level and final-family records; a graded
   factorization without its frame is not silently treated as the chart's
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
  familyEpsFormLegacyChart[Join[record, <|"Blocks" -> blocks|>]]
];
FamilyEpsilonFormRecord[_] := <|"Status" -> "InputNotAssociation"|>;

Options[CertifyFamilyEpsilonForm] = {
  "SourceVariables" -> Automatic,
  "Chart" -> Automatic,
  (* the four matrix identities (inverse, gauge, source flatness, flatness):
     "Symbolic" = entrywise Together (the former path, minutes to an hour
     on a 32x32 family); "RandomPoints" = exact rational evaluation of the
     unsimplified identity at random rational points (2026-08-22): a
     nonzero numerator polynomial of total degree d vanishes at a random
     point drawn from S values per coordinate with probability <= d/S
     (Schwartz-Zippel); the degree bound d is computed from the matrices'
     numerator/denominator degrees and the bound d/S per point per entry,
     and its union over entries and points, is recorded in the certificate *)
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
(* sourceAtPoint: rules -> {Ax(pt), Ay(pt)} (the chart connection at the
   point, by the chain rule on the source connection evaluated at the
   mapped point -- no symbolic pull-back); sourceDegrees: {n, L} bound of
   the chart connection's entries; sourceFlatAtPoints: verdict computed
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
      (degSi[[1]] + degSi[[2]]) + (degS[[1]] + 2 degS[[2]]) + (degAp[[1]] + degAp[[2]]),   (* gauge *)
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

CertifyFamilyEpsilonForm[record_Association, system_Association,
    OptionsPattern[]] := Module[
  {sourceVariablesOption, sourceVariables, regulator, chart, chartData,
   chartCertificate,
   normalizedSystem, normalizedRecord, pullBack, frameSystem, variables,
   sourceConnection, transformation, storedInverse, inverse,
   epsilonForm, dimension, inverseResiduals, inverseOK, gaugeResiduals,
   gaugeOK, sourceFlatResidual, sourceFlat, flatResidual, flat,
   dlogDetails, dlogValid, dlogResiduals, epsilonLinear, lettersEpsilonFree,
   constantResidues, dlogX, dlogY, blocks, permutation, ranges,
   blockLower, gate, checks, identityMethod, identityData, identitySeconds, modularData,
   checksPassed, certified, exact, highConfidence, certificate, originalStatus,
   algebraicFrameQ, certificateRoots, certificateLetters,
   certificateChart, certificateRankLimit, preauthenticatedRootFrame,
   regulatorRootFrameData, regulatorRootFrames},

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

  chart = observableTransportRecordChart[
    familyEpsFormLegacyChart[record], OptionValue["Chart"]];
  If[chart === $Failed,
    Return[<|"Status" -> "ChartNotResolved",
      "Chart" -> Lookup[record, "Chart", Missing[]]|>]];

  If[chart === None,
    variables = sourceVariables;
    normalizedSystem = masterTransportNormalize[system, regulator, variables];
    frameSystem = normalizedSystem;
    chartData = None;
    chartCertificate = <|"OK" -> True, "Frame" -> "SourceVariables"|>;
    pullBack = <|"SourceFlat" -> True, "ChartFlat" -> True,
      "ChartRational" -> True, "RootSquareConsistent" -> True,
      "Exact" -> True|>,
    chartData = masterTransportChartData[chart, sourceVariables];
    If[! AssociationQ[chartData] || Lookup[chartData, "Status", None] =!= "OK",
      Return[<|"Status" -> "ChartRefused", "Chart" -> chartData|>]];
    variables = chartData["Variables"];
    normalizedSystem = masterTransportNormalize[system, regulator,
      Join[sourceVariables, variables]];
    If[MemberQ[{"RandomPoints", "Modular"}, OptionValue["IdentityMethod"]] && ! TrueQ[OptionValue["SymbolicPullBack"]],
      (* no symbolic pull-back (it was ~80 s of a 146 s certificate on
         CF231, 2026-08-22): the chart connection is evaluated at each
         point by the chain rule, Ax = Av d_x v + Aw d_x w, on the source
         connection at the mapped point; source flatness is tested in the
         source variables at random points *)
      frameSystem = <|"Av" -> normalizedSystem["Av"], "Aw" -> normalizedSystem["Aw"],
        "LazyChart" -> chartData|>;
      chartCertificate = TransportChartVerify[chart];
      pullBack = <|"SourceFlat" -> "AtPoints", "ChartFlat" -> "ImpliedByChainRule",
        "ChartRational" -> True, "RootSquareConsistent" -> chartData["RootSquareConsistent"],
        "ChainRule" -> "evaluated at the certificate's points", "Exact" -> True|>,
      pullBack = masterTransportPullBackSystem[normalizedSystem, chartData,
        "SourceVariables" -> sourceVariables];
      If[! AssociationQ[pullBack] || Lookup[pullBack, "Status", None] =!= "OK",
        Return[<|"Status" -> "ChartPullBackFailed", "PullBack" -> pullBack|>]];
      frameSystem = pullBack["System"];
      chartCertificate = TransportChartVerify[chart];
      pullBack = pullBack["Certificate"]]
  ];

  normalizedRecord = masterTransportNormalize[record, regulator,
    Join[sourceVariables, variables]];
  regulatorRootFrameData = familyEpsFormRegulatorRootFrames[normalizedRecord];
  If[Lookup[regulatorRootFrameData, "Status", None] =!= "OK",
    Return[regulatorRootFrameData]];
  regulatorRootFrames = regulatorRootFrameData["Frames"];
  algebraicFrameQ = (AssociationQ[chartData] &&
      Lookup[chartData, "CoefficientField", "Rational"] ===
        "Multiquadratic") || regulatorRootFrames =!= {};
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
  If[algebraicFrameQ,
    certificateRoots = If[AssociationQ[chartData],
      transportChartCurrentRoots[chartData, variables], {}];
    certificateChart = If[AssociationQ[chartData], chartData,
      <|"Subst" -> Thread[sourceVariables -> variables],
        "Jacobian" -> IdentityMatrix[2],
        "CoefficientField" -> "Multiquadratic",
        "CertificateFrame" -> "IdentitySourceVariables"|>];
    certificateRankLimit = Replace[
      OptionValue["MultiquadraticRootRankLimit"], Automatic :>
        $familyRegulatorMaximumGradedRank];
    If[! ListQ[certificateRoots],
      Return[<|"Status" -> "MultiquadraticCertificateMetadataInvalid",
        "Roots" -> certificateRoots|>]];
    preauthenticatedRootFrame =
      familyCertMQAuthenticateRegulatorRootFrames[certificateRoots,
        regulatorRootFrames, variables, regulator, certificateRankLimit];
    If[Lookup[preauthenticatedRootFrame, "Status", None] =!=
        "AuthenticatedRegulatorRootFrames",
      Return[<|"Status" -> "RegulatorRootFrameCertificateRefused",
        "Detail" -> preauthenticatedRootFrame|>]]];
  identityMethod = OptionValue["IdentityMethod"];
  modularData = None;
  If[identityMethod === "Modular",
    {identitySeconds, modularData} = AbsoluteTiming[Module[{lazy = Lookup[frameSystem, "LazyChart", None]},
      If[algebraicFrameQ,
        certificateLetters = Lookup[normalizedRecord, "Letters", {}];
        If[! ListQ[certificateRoots] || ! ListQ[certificateLetters],
          familyCertMQFailure["MultiquadraticCertificateMetadataInvalid",
            <|"Roots" -> certificateRoots,
              "Letters" -> certificateLetters|>],
          familyCertificateMultiquadratic[epsilonForm, transformation,
            inverse, variables, regulator, sourceConnection,
            sourceVariables, certificateChart, certificateRoots,
            certificateLetters,
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
        familyCertificateModular[epsilonForm, transformation, inverse,
          variables, regulator, sourceConnection,
          If[AssociationQ[lazy], sourceVariables, variables], lazy,
          "Points" -> OptionValue["ModularPoints"],
          "Primes" -> OptionValue["ModularPrimes"]]]]];
    If[! (AssociationQ[modularData] && KeyExistsQ[modularData, "GaugeIdentity"]),
      Return[<|"Status" -> "ModularCertificateFailed", "Modular" -> modularData|>]];
    identityData = <|"Points" -> Lookup[modularData, "PointsDone", {}], "DegreeBound" -> Lookup[modularData, "DegreeBound", Missing[]],
      "ErrorBound" -> Lookup[modularData, "ErrorBoundGoodCharacteristic", 1], "OK" -> True|>;
    inverseOK = TrueQ[modularData["TransformationInverse"]]; gaugeOK = TrueQ[modularData["GaugeIdentity"]];
    flat = TrueQ[modularData["Flatness"]]; sourceFlat = TrueQ[modularData["SourceFlatness"]]];
  If[identityMethod === "RandomPoints",
    {identitySeconds, identityData} = AbsoluteTiming[Module[
      {lazy = Lookup[frameSystem, "LazyChart", None], av, aw, sourceAtPoint, sourceDegrees,
       srcSymbols, srcFlat, dAvw, data},
      If[AssociationQ[lazy],
        (* source connection in the source variables (permuted); chart map and Jacobian *)
        {av, aw} = sourceConnection;
        srcSymbols = Join[sourceVariables, {regulator}];
        dAvw = D[av, sourceVariables[[2]]] - D[aw, sourceVariables[[1]]];
        srcFlat = masterTransportPointZeroQ[dAvw + av . aw - aw . av, srcSymbols, 2];
        sourceAtPoint = Function[{rules}, Module[{map, jac, avP, awP},
          map = Thread[sourceVariables -> (Last /@ lazy["Subst"] /. rules)];
          jac = Quiet[Check[Map[Together[# /. rules] &, lazy["Jacobian"], {2}], $Failed]];
          avP = familyEpsFormEvaluate[av, Join[map, Select[rules, First[#] === regulator &]]];
          awP = familyEpsFormEvaluate[aw, Join[map, Select[rules, First[#] === regulator &]]];
          If[MemberQ[{jac, avP, awP}, $Failed], $Failed,
            {avP jac[[1, 1]] + awP jac[[2, 1]], avP jac[[1, 2]] + awP jac[[2, 2]]}]]];
        (* degrees of the chart connection: source degrees scaled by the
           map's degree, plus the Jacobian *)
        data = familyEpsFormDegreeData[Join[av, aw], srcSymbols];
        sourceDegrees = With[{dm = Max[1, Max[Exponent[Numerator[Together[#]], variables, Max],
            Exponent[Denominator[Together[#]], variables, Max]] & /@ (Last /@ lazy["Subst"])],
            dj = Max[Exponent[Numerator[Together[#]], variables, Max] + Exponent[Denominator[Together[#]], variables, Max] & /@ Flatten[lazy["Jacobian"]]]},
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
    inverseOK = gaugeOK = flat = TrueQ[identityData["OK"]];
    sourceFlat = TrueQ[identityData["SourceFlat"]]];
  If[identityMethod === "Symbolic",
    identityData = <|"DegreeBound" -> Missing["Symbolic"], "ErrorBound" -> 0, "Points" -> 0|>;
    {identitySeconds, {inverseOK, gaugeOK, sourceFlat, flat}} = AbsoluteTiming[Module[
      {inverseResiduals, gaugeResiduals, sourceFlatResidual, flatResidual},
      inverseResiduals = {
        Map[Together, transformation . inverse - IdentityMatrix[dimension], {2}],
        Map[Together, inverse . transformation - IdentityMatrix[dimension], {2}]};
      gaugeResiduals = Table[
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
      observableTransportZeroMatrixQ /@ {inverseResiduals, gaugeResiduals, sourceFlatResidual, flatResidual}]]];

  dlogDetails = Which[
    identityMethod === "Modular",
    (* the dlog statement is the modular verdict: consistent on fresh
       validation points at every prime, residues CRT-reconstructed and
       verified at every prime; no symbolic residual is fabricated *)
    <|"Valid" -> TrueQ[modularData["DLog"]] && TrueQ[modularData["ConstantResidues"]] && TrueQ[modularData["LettersEpsFree"]],
      "Dimension" -> dimension, "Variables" -> variables, "Regulator" -> regulator,
      "Letters" -> modularData["Letters"], "Residues" -> modularData["Residues"],
      "ConstantResidues" -> TrueQ[modularData["ConstantResidues"]],
      "ResiduesVerifiedAtAllPrimes" -> modularData["ResiduesVerifiedAtAllPrimes"],
      "ReconstructionResidual" -> Missing["ModularValidation"]|>,
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
  epsilonLinear = If[identityMethod === "Modular", TrueQ[modularData["EpsFactored"]],
    AllTrue[Flatten[epsilonForm],
      observableTransportZeroQ[#] || FreeQ[Together[#/regulator], regulator] &]];
  lettersEpsilonFree = AssociationQ[dlogDetails] &&
    FreeQ[Lookup[dlogDetails, "Letters", {regulator}], regulator];
  constantResidues = AssociationQ[dlogDetails] &&
    TrueQ[Lookup[dlogDetails, "ConstantResidues", False]];
  dlogX = If[identityMethod === "Modular", TrueQ[modularData["DLog"]],
    ListQ[dlogResiduals] && Length[dlogResiduals] === 2 &&
      observableTransportZeroMatrixQ[dlogResiduals[[1]]]];
  dlogY = If[identityMethod === "Modular", TrueQ[modularData["DLog"]],
    ListQ[dlogResiduals] && Length[dlogResiduals] === 2 &&
      observableTransportZeroMatrixQ[dlogResiduals[[2]]]];

  ranges = Lookup[normalizedRecord, "Ranges", {Range[dimension]}];
  blockLower = observableTransportBlockLowerQ[epsilonForm, ranges];
  gate = <|
    "BlockLowerTriangular" -> blockLower,
    "TTotalInvertible" -> inverseOK,
    "EpsLinear" -> epsilonLinear,
    "LettersEpsFree" -> lettersEpsilonFree,
    "ResiduesConstantX" -> constantResidues,
    "ResiduesConstantY" -> constantResidues,
    "DlogIdentityX" -> dlogX,
    "DlogIdentityY" -> dlogY,
    "ResiduesAgree" -> dlogValid,
    "Flat" -> flat
  |>;
  checks = <|
    "EpsFactored" -> epsilonLinear,
    "DLog" -> dlogValid,
    "BlockLowerTriangular" -> blockLower,
    "TransformationInverse" -> inverseOK,
    "GaugeIdentity" -> gaugeOK,
    "SourceFlatness" -> sourceFlat,
    "Flatness" -> flat,
    "ChartIdentity" -> TrueQ[Lookup[chartCertificate, "OK", False]]
  |>;
  checksPassed = And @@ (TrueQ /@ Values[checks]);
  (* The all-sign-sheet multiquadratic verifier deliberately avoids the
     characteristic-zero numerator expansion needed for a deterministic
     identity proof.  Its independent finite-field points and fresh-prime
     residue replay are accepted high-confidence evidence, not an exact
     characteristic-zero certificate.  Rational and symbolic routes retain
     their established exact contract. *)
  highConfidence = checksPassed && algebraicFrameQ &&
    identityMethod === "Modular";
  exact = checksPassed && ! (algebraicFrameQ &&
    identityMethod =!= "Symbolic");
  certified = exact || highConfidence;
  certificate = <|
    "Version" -> 1,
    "Exact" -> exact,
    "Certified" -> certified,
    "CertificationLevel" -> Which[
      exact, "CharacteristicZeroExact",
      highConfidence, "HighConfidenceFiniteField",
      True, "Failed"],
    "CoefficientField" -> If[algebraicFrameQ,
      "Multiquadratic", "Rational"],
    "IdentityMethod" -> identityMethod,
    "Probabilistic" -> identityMethod =!= "Symbolic",
    "IdentityPoints" -> identityData["Points"],
    "IdentityDegreeBound" -> identityData["DegreeBound"],
    (* conditional on good characteristics (no sampled prime divides the
       content of a nonzero residual); that event is guarded by one exact
       characteristic-zero evaluation of the matrix identities *)
    "IdentityErrorBoundGoodCharacteristic" -> identityData["ErrorBound"],
    "IdentityErrorBoundIdentities" -> If[AssociationQ[modularData], Lookup[modularData, "ErrorBoundIdentities", Missing[]], Missing["NotModular"]],
    "IdentityErrorBoundDLog" -> If[AssociationQ[modularData], Lookup[modularData, "ErrorBoundDLog", Missing[]], Missing["NotModular"]],
    "IdentitySeconds" -> identitySeconds,
    "Modular" -> If[AssociationQ[modularData], KeyDrop[modularData, {"Residues", "Letters"}], Missing["NotUsed"]],
    "RegulatorRootFrameEvidence" -> If[algebraicFrameQ,
      <|"FactorizationCount" ->
          regulatorRootFrameData["FactorizationCount"],
        "GradedFactorizationCount" ->
          regulatorRootFrameData["GradedFactorizationCount"],
        "AuthenticatedFrameCount" ->
          Lookup[If[AssociationQ[modularData], modularData, <||>],
            "RegulatorRootFrameEvidenceCount",
            Lookup[preauthenticatedRootFrame, "EvidenceCount", 0]],
        "AuthenticatedFrameFingerprints" -> If[
          AssociationQ[modularData], Lookup[modularData,
            "RegulatorRootFrameEvidenceFingerprints", {}],
          Lookup[preauthenticatedRootFrame, "EvidenceFingerprints", {}]]|>,
      Missing["RationalCoefficientField"]],
    "Variables" -> variables,
    "Regulator" -> regulator,
    "BasisPermutation" -> permutation,
    "Chart" -> chartCertificate,
    "PullBack" -> pullBack,
    "TransformationInverseResiduals" -> inverseResiduals,
    "GaugeResiduals" -> gaugeResiduals,
    "SourceFlatnessResidual" -> sourceFlatResidual,
    "FlatnessResidual" -> flatResidual,
    "DLog" -> dlogDetails
  |>;
  originalStatus = Lookup[record, "Status", Missing[]];

  Join[normalizedRecord, <|
    "Status" -> Which[
      exact, "ExactEpsilonForm",
      highConfidence, "CertifiedEpsilonForm",
      True, "EpsilonFormCertificationFailed"],
    "OriginalStatus" -> originalStatus,
    "CertificationMethod" -> If[highConfidence,
      "HighConfidenceWholeFamilyFiniteField",
      "ExactWholeFamilyRecalculation"],
    "BasisPermutation" -> permutation,
    "TTotalInverse" -> inverse,
    "GateVerdict" -> certified,
    "Gate" -> gate,
    "Checks" -> checks,
    "TTotalInvertible" -> inverseOK,
    "GaugeIdentity" -> gaugeOK,
    "Flatness" -> flat,
    "ChartCertificate" -> chartCertificate,
    "PullBack" -> pullBack,
    "EpsilonFormCertificate" -> certificate
  |>]
];

CertifyFamilyEpsilonForm[_, _, OptionsPattern[]] :=
  <|"Status" -> "InputsNotAssociations"|>;

ExactFamilyEpsilonFormQ[record_Association] := Module[
  {status, standardizedCertificate, gateRecord, cleanedGate, checks,
   requiredChecks, chartCertificate, pullBack, libraRecord,
   probabilisticMultiquadratic},
  status = Lookup[record, "Status", Missing[]];
  standardizedCertificate = Lookup[record, "EpsilonFormCertificate", <||>];
  probabilisticMultiquadratic =
    AssociationQ[standardizedCertificate] &&
    TrueQ[Lookup[standardizedCertificate, "Probabilistic", False]] &&
    (Lookup[standardizedCertificate, "CoefficientField", None] ===
        "Multiquadratic" ||
      Lookup[Lookup[standardizedCertificate, "Modular", <||>],
        "CoefficientField", None] === "Multiquadratic");
  If[status === "ExactEpsilonForm" && AssociationQ[standardizedCertificate] &&
      Lookup[standardizedCertificate, "Version", 0] >= 1,
    Return[! probabilisticMultiquadratic &&
      TrueQ[Lookup[standardizedCertificate, "Exact", False]] &&
      TrueQ[Lookup[record, "GateVerdict", False]] &&
      TrueQ[Lookup[record, "GaugeIdentity", False]] &&
      TrueQ[Lookup[record, "Flatness", False]] &&
      TrueQ[Lookup[record, "TTotalInvertible", False]]]];
  gateRecord =
    MemberQ[{"ExactEpsilonForm", "CleanedUp"}, status] &&
    TrueQ[Lookup[record, "GateVerdict", False]] &&
    TrueQ[Lookup[record, "GaugeIdentity", False]] &&
    TrueQ[Lookup[record, "Flatness", False]] &&
    TrueQ[Lookup[record, "TTotalInvertible", False]] &&
    (! AssociationQ[Lookup[record, "ChartCertificate", None]] ||
      TrueQ[Lookup[record["ChartCertificate"], "OK", False]]);

  cleanedGate = Lookup[record, "Gate", <||>];
  cleanedGate = status === "CleanedUp" &&
    TrueQ[Lookup[record, "GateVerdict", False]] &&
    AssociationQ[cleanedGate] &&
    And @@ (TrueQ[Lookup[cleanedGate, #, False]] & /@ {
      "BlockLowerTriangular", "TTotalInvertible", "EpsLinear",
      "LettersEpsFree", "ResiduesConstantX", "ResiduesConstantY",
      "DlogIdentityX", "DlogIdentityY", "ResiduesAgree", "Flat"
    });

  checks = Lookup[record, "Checks", <||>];
  requiredChecks = {
    "EpsFactored", "DLog", "TransformationInverse",
    "GaugeIdentity", "Flatness"
  };
  chartCertificate = Lookup[record, "ChartCertificate", <||>];
  pullBack = Lookup[record, "PullBack", <||>];
  libraRecord = status === "EpsForm" && AssociationQ[checks] &&
    And @@ (TrueQ[Lookup[checks, #, False]] & /@ requiredChecks) &&
    (! AssociationQ[chartCertificate] || chartCertificate === <||> ||
      TrueQ[Lookup[chartCertificate, "OK", False]]) &&
    (! AssociationQ[pullBack] || pullBack === <||> ||
      And @@ (TrueQ[Lookup[pullBack, #, False]] & /@
        {"SourceFlat", "ChartFlat", "ChartRational",
         "RootSquareConsistent"}));
  TrueQ[gateRecord || cleanedGate || libraRecord]
];

ExactFamilyEpsilonFormQ[_] := False;

CertifiedFamilyEpsilonFormQ[record_Association] := Module[
  {status, certificate, modular, requiredChecks},
  If[ExactFamilyEpsilonFormQ[record], Return[True]];
  status = Lookup[record, "Status", Missing[]];
  certificate = Lookup[record, "EpsilonFormCertificate", <||>];
  modular = Lookup[certificate, "Modular", <||>];
  requiredChecks = {
    "EpsFactored", "DLog", "BlockLowerTriangular",
    "TransformationInverse", "GaugeIdentity", "SourceFlatness",
    "Flatness", "ChartIdentity"
  };
  status === "CertifiedEpsilonForm" &&
    AssociationQ[certificate] && AssociationQ[modular] &&
    Lookup[certificate, "Version", 0] >= 1 &&
    TrueQ[Lookup[certificate, "Certified", False]] &&
    ! TrueQ[Lookup[certificate, "Exact", True]] &&
    TrueQ[Lookup[certificate, "Probabilistic", False]] &&
    Lookup[certificate, "CertificationLevel", None] ===
      "HighConfidenceFiniteField" &&
    Lookup[certificate, "CoefficientField", None] ===
      "Multiquadratic" &&
    Lookup[modular, "Status", None] ===
      "CertifiedMultiquadraticFamily" &&
    Lookup[modular, "CoefficientField", None] === "Multiquadratic" &&
    TrueQ[Lookup[modular, "Probabilistic", False]] &&
    TrueQ[Lookup[record, "GateVerdict", False]] &&
    TrueQ[Lookup[record, "GaugeIdentity", False]] &&
    TrueQ[Lookup[record, "Flatness", False]] &&
    TrueQ[Lookup[record, "TTotalInvertible", False]] &&
    AssociationQ[Lookup[record, "Checks", None]] &&
    And @@ (TrueQ[Lookup[record["Checks"], #, False]] & /@
      requiredChecks)
];

CertifiedFamilyEpsilonFormQ[_] := False;
