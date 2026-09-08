(* Family differential-system assembly for the requested-output
   iterated-integral coefficient pipeline.

   The public constructor re-expresses a two-variable family differential
   system in an explicit coefficient presentation, composes and re-verifies
   the certified diagonal-block basis transformations, and returns a
   block-lower-triangular connection whose diagonal blocks are in dlog
   epsilon form.  It performs no path ordering, no boundary evaluation and
   no iterated-integral expansion.

   "Blocks" is an explicit list of {rows, provider} pairs.  Automatic block
   discovery is intentionally not supported here: a provider is part of each
   diagonal-block specification, and the V2 family block decomposition is the
   authoritative source of the irreducible blocks. *)

ClearAll[
  $masterTransportLogStart,
  masterTransportFail,
  masterTransportLog,
  masterTransportLogStream,
  masterTransportEpsOrder,
  masterTransportOrderBlocks,
  masterTransportScalarEpsForm,
  masterTransportBlockProvider,
  masterTransportAcceptedBlockFormQ,
  masterTransportPointFlatQ,
  masterTransportAssemble,
  masterTransportCertificateOK,
  masterTransportClassNormalize,
  masterTransportClassMemberPermutation,
  masterTransportChartSwapData,
  masterTransportPullBackClassFormOnce,
  masterTransportPullBackClassForm,
  masterTransportChartBlockSpec
];

AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks::regulator =
  "Could not resolve the regulator symbol in `1`; give \"Regulator\" explicitly.";
AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks::option =
  "Value `2` is not valid for option \"`1`\" of `3`.";

masterTransportFail[head_, tag_, args___] := (
  Message[MessageName[head, tag], args];
  Throw[$Failed, $masterTransportFailure]
);

$masterTransportLogStart = AbsoluteTime[];

masterTransportLog[verbose_, args___] := If[TrueQ[verbose],
  WriteString[masterTransportLogStream[],
    "[family differential-system assembly ",
    DateString[{"Hour", ":", "Minute", ":", "Second"}], " +",
    ToString[Round[AbsoluteTime[] - $masterTransportLogStart]], "s] ",
    StringJoin[ToString /@ {args}], "\n"];
  Flush[masterTransportLogStream[]]
];

masterTransportLogStream[] :=
  If[ListQ[$Output] && $Output =!= {}, First[$Output],
    OutputStream["stdout", 1]];

(* Exact epsilon valuation of a rational function.  ObservableTransport
   shares this private primitive. *)
masterTransportEpsOrder[e_, eps_] := Module[{x},
  x = Together[e];
  If[x === 0, Infinity,
    Exponent[Numerator[x], eps, Min] -
      Exponent[Denominator[x], eps, Min]]
];

(* Block ordering and the five-part conjugation certificate. *)

masterTransportOrderBlocks[av_, aw_, blocks_] := Module[
  {nb, edges, order, zeroBlock},
  nb = Length[blocks];
  (* Pullback has already Together-normalized every entry.  In production
     a structural-zero scan therefore recovers the DAG without repeating
     a rational-function zero proof for every one of nb^2 block pairs. *)
  zeroBlock[m_] := If[masterTransportCheckLevel[] === "Production",
    AllTrue[Flatten[m], TrueQ[# === 0] &], masterTransportZeroMatQ[m]];
  edges = DeleteCases[
    Flatten @ Table[
      If[i =!= j &&
         ! (zeroBlock[av[[blocks[[i]], blocks[[j]]]]] &&
            zeroBlock[aw[[blocks[[i]], blocks[[j]]]]]),
        j -> i, Null],
      {i, nb}, {j, nb}],
    Null];
  order = TopologicalSort[Graph[Range[nb], edges]];
  If[Head[order] =!= List || Length[order] =!= nb, $Failed, order]
];

(* Cheap 1x1 provider: an explicit dlog prefactor.  Only entries regular
   at eps = 0 are handled by this route. *)
masterTransportScalarEpsForm[av_, aw_, eps_, variables_] := Module[
  {v, w, a0v, a0w, letters, unknowns, dlv, dlw, equations, solution,
   free, t, ev, ew},
  {v, w} = variables[[{1, 2}]];
  If[masterTransportEpsOrder[av, eps] < 0 ||
     masterTransportEpsOrder[aw, eps] < 0, Return[$Failed]];
  a0v = Together[av /. eps -> 0];
  a0w = Together[aw /. eps -> 0];
  letters = DeleteDuplicates @ Select[
    Join @@ (FactorList[Denominator[#]][[All, 1]] & /@ {a0v, a0w}),
    ! FreeQ[#, v | w] &];
  If[letters === {},
    If[TrueQ[Together[a0v] === 0] && TrueQ[Together[a0w] === 0],
      Return[<|"Status" -> "OK", "Type" -> "EpsForm", "T" -> {{1}},
        "Ev" -> {{Together[av]}}, "Ew" -> {{Together[aw]}},
        "Source" -> "scalar-dlog"|>],
      Return[$Failed]]];
  unknowns = Table[Unique["masterTransportC"], {Length[letters]}];
  dlv = Sum[unknowns[[i]] D[letters[[i]], v]/letters[[i]], {i, Length[letters]}];
  dlw = Sum[unknowns[[i]] D[letters[[i]], w]/letters[[i]], {i, Length[letters]}];
  equations = Flatten[{
    CoefficientList[Numerator[Together[a0v - dlv]], {v, w}],
    CoefficientList[Numerator[Together[a0w - dlw]], {v, w}]}];
  solution = Quiet @ Solve[Thread[DeleteDuplicates[equations] == 0], unknowns];
  If[solution === {} || Head[solution] =!= List, Return[$Failed]];
  unknowns = unknowns /. First[solution];
  free = Cases[unknowns,
    s_Symbol /; StringMatchQ[SymbolName[s], "masterTransportC*"], {0, Infinity}];
  unknowns = unknowns /. Thread[free -> 0];
  t = Times @@ Table[letters[[i]]^unknowns[[i]], {i, Length[letters]}];
  If[! (TrueQ[Together[a0v - D[Log[t], v]] === 0] &&
        TrueQ[Together[a0w - D[Log[t], w]] === 0]), Return[$Failed]];
  ev = Together[av - D[Log[t], v]];
  ew = Together[aw - D[Log[t], w]];
  If[! (FreeQ[Together[ev/eps], eps] && FreeQ[Together[ew/eps], eps]),
    Return[$Failed]];
  <|"Status" -> "OK", "Type" -> "EpsForm", "T" -> {{t}}, "Ev" -> {{ev}},
    "Ew" -> {{ew}}, "Source" -> "scalar-dlog"|>
];

(* The V2 assembly consumes only an explicit epsilon-form provider, or
   Automatic for a scalar block.  Class files are loaded and re-expressed by
   masterTransportChartBlockSpec before this boundary. *)
masterTransportAcceptedBlockFormQ[form_] :=
  AssociationQ[form] && Lookup[form, "Status", None] === "OK" &&
    Lookup[form, "Type", None] === "EpsForm";

masterTransportBlockProvider[specification_, av_, aw_, eps_, variables_] :=
  Module[{scalar},
    Which[
      specification === Automatic && Length[av] === 1,
        scalar = masterTransportScalarEpsForm[
          av[[1, 1]], aw[[1, 1]], eps, variables];
        If[scalar === $Failed, <|"Status" -> "ScalarFailed"|>, scalar],
      specification === Automatic,
        <|"Status" -> "DiagonalBlockProviderRequired"|>,
      AssociationQ[specification] &&
          Lookup[specification, "Type", "EpsForm"] === "EpsForm" &&
          MatrixQ[Lookup[specification, "T", $Failed]],
        <|"Status" -> "OK", "Type" -> "EpsForm",
          "T" -> specification["T"],
          "TInverse" -> Lookup[specification, "TInverse", Automatic],
          "Ev" -> Lookup[specification, "Ev",
            Together[Inverse[specification["T"]] . av .
              specification["T"] -
              Inverse[specification["T"]] .
                D[specification["T"], variables[[1]]]]],
          "Ew" -> Lookup[specification, "Ew",
            Together[Inverse[specification["T"]] . aw .
              specification["T"] -
              Inverse[specification["T"]] .
                D[specification["T"], variables[[2]]]]],
          "Alphabet" -> Lookup[specification, "Alphabet", {}],
          "Source" -> "explicit"|>,
      True,
        <|"Status" -> "DiagonalBlockProviderUnknown"|>
    ]
  ];

(* Production curvature check: differentiate the entries once, but
   substitute the point BEFORE matrix multiplication.  This avoids
   constructing a giant symbolic A_v A_w - A_w A_v only to evaluate it
   immediately afterwards. *)
masterTransportPointFlatQ[av_, aw_, variables_List,
    count_Integer: 2] := Module[
  {symbols, davw, dawv, tries = 0, done = 0, point, avp, awp,
   values},
  symbols = DeleteDuplicates@Join[variables,
    Cases[{av, aw}, s_Symbol /; Context[s] =!= "System`",
      {0, Infinity}]];
  davw = D[av, variables[[2]]];
  dawv = D[aw, variables[[1]]];
  While[done < count && tries < 6 count,
    tries++;
    point = Thread[symbols ->
      RandomInteger[{3, 10^6}, Length[symbols]]/
        RandomInteger[{10^6, 10^7}, Length[symbols]]];
    values = Quiet[Check[
      avp = av /. point; awp = aw /. point;
      Flatten[Map[Together,
        (davw /. point) - (dawv /. point) + avp . awp - awp . avp,
        {2}]], $Failed]];
    If[values === $Failed ||
        ! FreeQ[values,
          ComplexInfinity | Indeterminate | DirectedInfinity], Continue[]];
    If[! AllTrue[values,
        TrueQ[# === 0] ||
          (masterTransportRadicalQ[#] &&
            TrueQ[masterTransportRadicalZeroQ[#]]) &], Return[False]];
    done++];
  done >= count];

Options[masterTransportAssemble] = {
  "Blocks" -> Automatic,
  "ConjugatedFlatnessCheck" -> Automatic,
  "CheckLevel" -> Automatic,
  "Verbose" -> False
};

masterTransportAssemble[system_Association, eps_Symbol, variables_List,
    opts : OptionsPattern[]] := Module[
  {av, aw, n, blocks, providers, order, permutation, pav, paw, nb, ranges,
   forms, tInverse, conjugated, certificate, triangular, diagonalOK,
   apv, apw, verbose, v, w, family, blockSpecification,
   inversePerBlock, directFlatnessCheck, algebraicConnectionQ,
   checkLevel, productionQ, zeroMat, suppliedFlatness, suppliedFlatnessQ,
   identityBlocks, pendingExpressions, pendingBlocks, blockV, blockW,
   simplifiedRow, cursor, entryCount, dimensions, blockIndex,
   rowInputBytes, rowSeconds},
  verbose = TrueQ[OptionValue["Verbose"]];
  checkLevel = masterTransportCheckLevel[OptionValue["CheckLevel"]];
  productionQ = checkLevel === "Production";
  {v, w} = variables[[{1, 2}]];
  zeroMat[m_] := If[productionQ,
    masterTransportPointZeroQ[m, {v, w, eps}], masterTransportZeroMatQ[m]];
  family = Lookup[system, "Family", "unnamed"];
  av = system["Av"];
  aw = system["Aw"];
  suppliedFlatness = Lookup[system, "FlatnessCertificate", None];
  suppliedFlatnessQ = AssociationQ[suppliedFlatness] &&
    Lookup[suppliedFlatness, "Status", None] === "Accepted" &&
    TrueQ[Lookup[suppliedFlatness, "SourceFlatness", False]];
  n = Length[av];

  blockSpecification = OptionValue["Blocks"];
  If[blockSpecification === Automatic,
    Return[<|"Status" -> "DiagonalBlockSpecificationsRequired"|>]];
  If[! ListQ[blockSpecification] || blockSpecification === {} ||
      ! AllTrue[blockSpecification,
        MatchQ[#, {{__Integer}, _}] &],
    Return[<|"Status" -> "DiagonalBlockSpecificationsNotWellFormed"|>]];
  blocks = blockSpecification[[All, 1]];
  providers = blockSpecification[[All, 2]];

  masterTransportLog[verbose, family, ": ", n, " masters, ",
    Length[blocks], " blocks, dims ", Tally[Length /@ blocks]];
  order = masterTransportOrderBlocks[av, aw, blocks];
  If[order === $Failed, Return[<|"Status" -> "OrderFailed"|>]];
  blocks = blocks[[order]];
  providers = providers[[order]];
  permutation = Flatten[blocks];
  If[Sort[permutation] =!= Range[n],
    Return[<|"Status" -> "BlocksNotAPartition"|>]];
  pav = av[[permutation, permutation]];
  paw = aw[[permutation, permutation]];
  nb = Length[blocks];
  ranges = FoldList[Plus, 0, Length /@ blocks];
  ranges = Table[Range[ranges[[i]] + 1, ranges[[i + 1]]], {i, nb}];

  certificate = <||>;
  triangular = AllTrue[
    Flatten@Table[
      If[i < j,
        {pav[[ranges[[i]], ranges[[j]]]],
         paw[[ranges[[i]], ranges[[j]]]]}, {}],
      {i, nb}, {j, nb}],
    TrueQ[masterTransportZeroQ[#]] &];
  certificate["BlockLowerTriangular"] = triangular;
  certificate["CheckLevel"] = checkLevel;
  certificate["FlatnessOriginal"] = If[suppliedFlatnessQ, True,
    If[productionQ,
      masterTransportPointFlatQ[av, aw, {v, w, eps}],
      masterTransportZeroMatQ[
        D[av, w] - D[aw, v] + av . aw - aw . av]]];
  certificate["FlatnessOriginalRoute"] = If[suppliedFlatnessQ,
    "CallerCertificate",
    If[productionQ, "TwoPointExactRational", "ExactRationalFunction"]];
  If[suppliedFlatnessQ,
    certificate["FlatnessOriginalProvenance"] = suppliedFlatness];

  forms = Table[
    Module[{rows = blocks[[i]], sav, saw},
      sav = av[[rows, rows]];
      saw = aw[[rows, rows]];
      masterTransportBlockProvider[
        providers[[i]], sav, saw, eps, variables]],
    {i, nb}];
  If[! AllTrue[forms, masterTransportAcceptedBlockFormQ],
    Return[<|"Status" -> "FormFailed", "Blocks" -> blocks,
      "Failures" -> Select[Transpose[{blocks, forms}],
        ! masterTransportAcceptedBlockFormQ[#[[2]]] &]|>]];

  tInverse = Table[
    If[MissingQ[forms[[i]]["TInverse"]] ||
        forms[[i]]["TInverse"] === Automatic,
      Map[Together, Inverse[forms[[i]]["T"]], {2}],
      forms[[i]]["TInverse"]],
    {i, nb}];
  identityBlocks = Table[
    SameQ[forms[[i]]["T"],
      IdentityMatrix[Length[forms[[i]]["T"]]]] &&
      SameQ[tInverse[[i]],
        IdentityMatrix[Length[tInverse[[i]]]]],
    {i, nb}];
  inversePerBlock = If[productionQ,
    ConstantArray[Missing["DeferredToFamilyCertificate"], nb],
    Table[
      zeroMat[
        forms[[i]]["T"] . tInverse[[i]] -
          IdentityMatrix[Length[forms[[i]]["T"]]]] &&
      zeroMat[
        tInverse[[i]] . forms[[i]]["T"] -
          IdentityMatrix[Length[forms[[i]]["T"]]]],
      {i, nb}]];
  certificate["TransformationInversePerBlock"] = inversePerBlock;
  certificate["TransformationInverseVerified"] = If[productionQ,
    Missing["DeferredToFamilyCertificate"],
    AllTrue[inversePerBlock, TrueQ]];

  conjugated = <||>;
  Do[
    pendingExpressions = {};
    pendingBlocks = {};
    Do[
      If[i >= j,
        If[productionQ && i === j,
          (* The input dlog connection is already the diagonal block to
             install.  Its equality to the conjugated source block is one
             of the identities checked by the final family validator. *)
          conjugated[{i, i}] = {forms[[i]]["Ev"], forms[[i]]["Ew"]},
        If[TrueQ[identityBlocks[[i]]] &&
              TrueQ[identityBlocks[[j]]],
          conjugated[{i, j}] = {
            pav[[ranges[[i]], ranges[[j]]]],
            paw[[ranges[[i]], ranges[[j]]]]},
          blockV = tInverse[[i]] .
            pav[[ranges[[i]], ranges[[j]]]] . forms[[j]]["T"];
          blockW = tInverse[[i]] .
            paw[[ranges[[i]], ranges[[j]]]] . forms[[j]]["T"];
          If[i === j,
            blockV = blockV -
              tInverse[[i]] . D[forms[[i]]["T"], v];
            blockW = blockW -
              tInverse[[i]] . D[forms[[i]]["T"], w]];
          AppendTo[pendingBlocks, {j, Dimensions[blockV]}];
          pendingExpressions = Join[pendingExpressions,
            Flatten[blockV], Flatten[blockW]]]]],
      {j, nb}];
    If[pendingExpressions =!= {},
      rowInputBytes = ByteCount[pendingExpressions];
      simplifiedRow = If[rowInputBytes >= 2^20,
        taskBrokerParallelTogether[pendingExpressions, {},
          "family_assembly_row_" <> ToString[i]],
        {rowSeconds, blockV} = AbsoluteTiming[
          Together /@ pendingExpressions];
        <|"Status" -> "OK", "Result" -> blockV,
          "Route" -> "Serial", "Helpers" -> 0,
          "Tasks" -> 0, "Seconds" -> rowSeconds|>];
      If[Lookup[simplifiedRow, "Status", None] =!= "OK",
        Return[<|"Status" -> "BlockRowSimplificationFailed",
          "BlockRow" -> i, "Detail" -> simplifiedRow|>]];
      cursor = 1;
      Do[
        blockIndex = pendingBlocks[[k, 1]];
        dimensions = pendingBlocks[[k, 2]];
        entryCount = Times @@ dimensions;
        conjugated[{i, blockIndex}] = {
          ArrayReshape[
            Take[simplifiedRow["Result"],
              {cursor, cursor + entryCount - 1}], dimensions],
          ArrayReshape[
            Take[simplifiedRow["Result"],
              {cursor + entryCount, cursor + 2 entryCount - 1}],
            dimensions]};
        cursor += 2 entryCount,
        {k, Length[pendingBlocks]}];
      masterTransportLog[verbose, "  simplified block row ", i,
        " with ", Lookup[simplifiedRow, "Helpers", 0], " helpers in ",
        Round[Lookup[simplifiedRow, "Seconds", 0.], 0.1], " s"]];
    masterTransportLog[verbose, "  conjugated block row ", i, "/", nb,
      " (dim ", Length[ranges[[i]]], ", leaves ",
      LeafCount[Table[conjugated[{i, j}], {j, i}]], ")"],
    {i, nb}];

  diagonalOK = If[productionQ,
    ConstantArray[Missing["DeferredToFamilyCertificate"], nb],
    Table[
      zeroMat[conjugated[{i, i}][[1]] - forms[[i]]["Ev"]] &&
        zeroMat[conjugated[{i, i}][[2]] - forms[[i]]["Ew"]],
      {i, nb}]];
  certificate["DiagonalEqualsDeclaredForm"] = If[productionQ,
    Missing["DeferredToFamilyCertificate"],
    AllTrue[diagonalOK, TrueQ]];
  certificate["DiagonalPerBlock"] = diagonalOK;
  certificate["EpsFormLinear"] = If[productionQ, True,
    AllTrue[
      Flatten[Table[
        {forms[[i]]["Ev"], forms[[i]]["Ew"]}, {i, nb}]],
      (TrueQ[Together[#] === 0] ||
         FreeQ[Together[#/eps], eps]) &]];
  certificate["OffDiagonalUpperZero"] =
    "by construction (T block-diagonal, A block-lower-triangular)";

  apv = ConstantArray[0, {n, n}];
  apw = ConstantArray[0, {n, n}];
  If[Head[apv] =!= List || Length[apv] =!= n,
    Return[<|"Status" -> "ZeroMatrixShape"|>]];
  Do[
    If[i >= j,
      apv[[ranges[[i]], ranges[[j]]]] =
        conjugated[{i, j}][[1]];
      apw[[ranges[[i]], ranges[[j]]]] =
        conjugated[{i, j}][[2]]],
    {i, nb}, {j, nb}];

  algebraicConnectionQ = ! FreeQ[{apv, apw},
    _Root | Power[_, exponent_Rational /;
      Denominator[exponent] > 1]];
  directFlatnessCheck = Replace[
    OptionValue["ConjugatedFlatnessCheck"],
    Automatic -> (! algebraicConnectionQ && ! productionQ)];
  certificate["FlatnessConjugated"] = If[productionQ,
    Missing["DeferredToFamilyCertificate"],
    If[TrueQ[directFlatnessCheck],
      masterTransportZeroMatQ[
        D[apv, w] - D[apw, v] + apv . apw - apw . apv],
      Missing["ImpliedByGaugeCovariance"]]];
  certificate["FlatnessConjugatedRoute"] = Which[
    productionQ, "DeferredToFamilyCertificate",
    TrueQ[certificate["FlatnessConjugated"]], "Verified",
    ! TrueQ[directFlatnessCheck] &&
      TrueQ[certificate["FlatnessOriginal"]] &&
      TrueQ[certificate["TransformationInverseVerified"]],
        "ByGaugeCovariance",
    True, "Failed"];

  masterTransportLog[verbose, "  certificate: triangular ",
    certificate["BlockLowerTriangular"], ", flat(A) ",
    certificate["FlatnessOriginal"], ", diagonal ",
    certificate["DiagonalEqualsDeclaredForm"], ", eps-linear ",
    certificate["EpsFormLinear"], ", inverse(T) ",
    certificate["TransformationInverseVerified"], ", flat(A') ",
    certificate["FlatnessConjugatedRoute"]];

  <|"Status" -> "OK", "Family" -> family, "N" -> n,
    "Perm" -> permutation, "Blocks" -> blocks, "Ranges" -> ranges,
    "Forms" -> forms, "TInverse" -> tInverse,
    "Apv" -> apv, "Apw" -> apw, "Av" -> pav, "Aw" -> paw,
    "Basis" ->
      If[MissingQ[system["Basis"]] || system["Basis"] === None,
        None, system["Basis"][[permutation]]],
    "Certificate" -> certificate|>
];

(* Development accepts the assembly from its direct identities.  Production
   performs only the computation here and deliberately defers the repeated
   diagonal, inverse and full-connection identities to the single
   whole-family finite-field validator. *)
masterTransportCertificateOK[assembly_] := Module[
  {certificate, productionQ},
  If[! (AssociationQ[assembly] && assembly["Status"] === "OK"),
    Return[False]];
  certificate = assembly["Certificate"];
  productionQ = Lookup[certificate, "CheckLevel", None] === "Production";
  If[productionQ,
    Return[TrueQ[certificate["BlockLowerTriangular"]] &&
      TrueQ[certificate["FlatnessOriginal"]] &&
      TrueQ[certificate["EpsFormLinear"]] &&
      certificate["FlatnessConjugatedRoute"] ===
        "DeferredToFamilyCertificate"]];
  And @@ (TrueQ /@ {
    certificate["BlockLowerTriangular"],
    certificate["FlatnessOriginal"],
    certificate["DiagonalEqualsDeclaredForm"],
    certificate["EpsFormLinear"],
    certificate["TransformationInverseVerified"]}) &&
  (* The fifth part passes on the direct computation or on gauge
     covariance with the hypotheses certified above. *)
  MemberQ[{"Verified", "ByGaugeCovariance"},
    Lookup[certificate, "FlatnessConjugatedRoute",
      If[TrueQ[certificate["FlatnessConjugated"]],
        "Verified", "Failed"]]]
];

(* A class member can differ from its representative by a constant basis
   permutation.  The coefficient-presentation pullback recovers that
   permutation and then runs the same exact epsilon-form gates as the
   identity candidate. *)
masterTransportClassNormalize[pair_, variables_List, eps_Symbol] :=
  canonicalBlocksMatrix[#, variables[[{1, 2}]], eps] & /@ pair;

masterTransportClassMemberPermutation[
    repPair_, memberPair_, variables_List, eps_Symbol] :=
  Module[{vars = variables[[{1, 2}]], repN, memN},
    repN = masterTransportClassNormalize[repPair, vars, eps];
    memN = masterTransportClassNormalize[memberPair, vars, eps];
    SelectFirst[canonicalBlocksOrbitCandidates[memN, repN],
      {repN[[1]][[#, #]], repN[[2]][[#, #]]} === memN &, None]
  ];

Options[masterTransportPullBackClassForm] = {
  "SourceVariables" -> Automatic,
  "Regulator" -> Automatic,
  "BlockSystem" -> None,
  "Swap" -> Automatic,
  "ClassID" -> None
};

(* Class equivalence permits exchange of the two source variables.  The
   swap is tried, never assumed; the re-derived epsilon-form identities
   decide whether the candidate is accepted. *)
masterTransportChartSwapData[data_Association] :=
  Module[{f, g, sourceVariables, presentationVariables, substitution,
    substitutionKey, jacobian},
    sourceVariables = data["SourceVariables"];
    presentationVariables = masterTransportPresentationVariables[data];
    substitution = masterTransportPresentationSubstitution[data];
    substitutionKey = Switch[data["PresentationKind"],
      "SourceVariables", "SourceVariableSubstitution",
      "RationalizingParametrization", "SourceVariableSubstitution",
      "SquareRootGeneratorsAndQuadraticRelations",
        "SourceToCoefficientVariableRules"];
    {f, g} = Last /@ substitution;
    jacobian = Map[Together, {
      {D[g, presentationVariables[[1]]],
        D[g, presentationVariables[[2]]]},
      {D[f, presentationVariables[[1]]],
        D[f, presentationVariables[[2]]]}}, {2}];
    Join[data, Association[
      substitutionKey -> {sourceVariables[[1]] -> g,
        sourceVariables[[2]] -> f},
      "DifferentialPullbackMatrix" -> jacobian,
      "JacobianDeterminant" -> Together[Det[jacobian]],
      "SourceVariablesSwapped" -> True]]
  ];


masterTransportPullBackClassFormOnce[rec_Association, data_Association,
    eps_Symbol, blockSystem_, classID_, swapped_,
    presentationKind_] := Module[
  {coordinates, x, y, t, tx, detTx, tInverse, inverseOK, ax, ay, ex, ey,
   epsLinear, stored, storedPulled, matches, jacobian, images, foreign,
   evaluate, identity, result, repChart, permutation,
   rationalTransformation, recordVariables, recordAlphabet, pulledAlphabet,
   rootClassification, declaredSquareRootGeneratorsOnly, storedResidues,
   storedInverse, productionDirectQ},
  If[! MemberQ[{"SourceVariables", "RationalizingParametrization",
      "SquareRootGeneratorsAndQuadraticRelations"}, presentationKind],
    Return[<|"Status" -> "ClassFormCoefficientPresentationKindInvalid",
      "PresentationKind" -> presentationKind|>]];
  {x, y} = masterTransportPresentationVariables[data];
  coordinates = masterTransportRecordCoordinateMap[rec, data];
  If[coordinates["Status"] =!= "OK", Return[coordinates]];
  t = Lookup[rec, "BasisTransformationMatrix", $Failed];
  If[! MatrixQ[t],
    Return[<|"Status" -> "DiagonalBlockBasisTransformationMissing"|>]];
  recordVariables = Lookup[rec, "CoefficientVariables",
    First /@ coordinates["CoefficientVariableRules"]];
  recordAlphabet = Lookup[rec, "Letters", Missing["NotStored"]];
  storedResidues = Lookup[rec, "ConstantResidueMatrices",
    Missing["NotStored"]];
  productionDirectQ = masterTransportCheckLevel[] === "Production" &&
    ! TrueQ[swapped] &&
    coordinates["CoordinateRepresentation"] ===
      "SelectedFamilyCoefficientPresentation" &&
    Lookup[rec, "DataType", None] === "DiagonalBlockDLogEpsilonForm" &&
    Lookup[rec, "Status", None] === "DLogEpsilonFormValidated" &&
    TrueQ[Lookup[Lookup[rec, "Validation", <||>], "Passed", False]] &&
    ListQ[recordAlphabet] && ListQ[storedResidues] &&
    Length[recordAlphabet] === Length[storedResidues];
  images = coordinates["CoefficientVariableImages"];
  tx = Map[Together,
    t /. coordinates["CoefficientVariableRules"], {2}];
  foreign = Complement[masterTransportFreeSymbols[tx], {x, y, eps}];
  If[foreign =!= {},
    Return[<|"Status" -> "ClassFormCarriesForeignSymbols", "Symbols" -> foreign|>]];

  (* Production already has a validated V2 diagonal form in these exact
     coefficient variables, and the completed family is accepted only by
     ValidateFamilyDLogEpsilonForm.  Re-deriving this same diagonal block
     here performed a symbolic inverse check and two full conjugations, then
     masterTransportAssemble repeated them once more.  On a measured 4x4
     algebraic block those duplicate calculations cost minutes.  Build the declared dlog
     connection directly and compute only the inverse needed by the actual
     off-diagonal conjugations; the one whole-family finite-field validation
     checks both identities after construction. *)
  If[productionDirectQ,
    storedInverse = Lookup[rec, "InverseBasisTransformationMatrix", None];
    tInverse = If[MatrixQ[storedInverse] &&
        Dimensions[storedInverse] === Dimensions[tx],
      Map[Together,
        storedInverse /. coordinates["CoefficientVariableRules"], {2}],
      Quiet[Check[Map[Together, Inverse[tx], {2}], $Failed]]];
    If[! MatrixQ[tInverse] || Dimensions[tInverse] =!= Dimensions[tx],
      Return[<|"Status" ->
        "DiagonalBlockBasisTransformationInverseUnavailable"|>]];
    stored = Table[
      eps Total[MapThread[
        #1 D[Log[#2], recordVariables[[j]]] &,
        {storedResidues, recordAlphabet}]],
      {j, 2}] /. coordinates["CoefficientVariableRules"];
    pulledAlphabet = DeleteDuplicates[
      recordAlphabet /. coordinates["CoefficientVariableRules"]];
    Return[<|
      "DataType" -> "DiagonalBlockDLogEpsilonForm",
      "SchemaVersion" -> 2,
      "Status" -> "DiagonalBlockDLogEpsilonFormReexpressed",
      "BasisTransformationMatrix" -> tx,
      "InverseBasisTransformationMatrix" -> tInverse,
      "CachedTransformedConnectionMatrices" -> stored,
      "Letters" -> pulledAlphabet,
      "Source" -> "selected-coefficient-variables",
      "ClassID" -> classID,
      "CoordinateRepresentation" ->
        coordinates["CoordinateRepresentation"],
      "CoefficientVariables" -> {x, y},
      "Coordinates" -> coordinates, "Swapped" -> False,
      "Permutation" -> Range[Length[tx]],
      "Certificate" -> <|
        "CoordinateRepresentation" ->
          coordinates["CoordinateRepresentation"],
        "CompositionVerified" -> coordinates["CompositionVerified"],
        "CompositionStatement" -> coordinates["CompositionStatement"],
        "CoefficientPresentationKind" -> presentationKind,
        "BasisTransformationRationalInCoefficientVariables" ->
          Missing["NotApplicableForSquareRootPresentation"],
        "BasisTransformationUsesOnlyDeclaredSquareRootGenerators" ->
          Missing["DeferredToFamilyCertificate"],
        "TransformationInvertible" ->
          Missing["DeferredToFamilyCertificate"],
        "TransformationInverseVerified" ->
          Missing["DeferredToFamilyCertificate"],
        "EpsFormReDerivedFromBlockSystem" ->
          Missing["DeferredToFamilyCertificate"],
        "EpsFormLinear" -> True,
        "StoredEpsFormPullbackMatches" ->
          Missing["DeferredToFamilyCertificate"],
        "FinalFamilyValidationRequired" -> True,
        "Swapped" -> False,
        "Permutation" -> Range[Length[tx]],
        "Exact" -> False|>|>]];
  rationalTransformation =
    AllTrue[Flatten[tx], masterTransportRationalQ[#, {x, y}] &];
  If[MemberQ[{"SourceVariables", "RationalizingParametrization"},
      presentationKind] &&
      ! TrueQ[rationalTransformation],
    Return[<|"Status" ->
      "BasisTransformationNotRationalInParametrizingVariables"|>]];
  rootClassification = If[presentationKind ===
      "SquareRootGeneratorsAndQuadraticRelations",
    transportChartRootIndices[tx, data["SquareRootGenerators"]], <||>];
  declaredSquareRootGeneratorsOnly = presentationKind =!=
      "SquareRootGeneratorsAndQuadraticRelations" ||
    (Lookup[rootClassification, "UnclassifiedRadicalBases", {}] === {} &&
      VectorQ[Lookup[rootClassification, "RootIndices", {}], IntegerQ]);
  If[! TrueQ[declaredSquareRootGeneratorsOnly],
    Return[<|"Status" ->
      "BasisTransformationOutsideDeclaredSquareRootAlgebra",
      "UnclassifiedRadicands" -> Lookup[rootClassification,
        "UnclassifiedRadicalBases", {}]|>]];
  detTx = Together[Det[tx]];
  If[TrueQ[detTx === 0],
    Return[<|"Status" ->
      "DiagonalBlockBasisTransformationSingular"|>]];
  (* The inverse is computed once and RE-MULTIPLIED OUT, both ways, so
     that handing it to the assembly is a certified shortcut and not a
     trusted one -- the same discipline as a closed-form sector's
     PhiInverse. *)
  tInverse = Map[Together, Inverse[tx], {2}];
  inverseOK = masterTransportZeroMatQ[tx . tInverse - IdentityMatrix[Length[tx]]] &&
    masterTransportZeroMatQ[tInverse . tx - IdentityMatrix[Length[tx]]];
  If[! TrueQ[inverseOK],
    Return[<|"Status" -> "ClassFormTransformationInverseNotVerified"|>]];

  (* The chart epsilon-form is RE-DERIVED from the pulled-back block
     system.  Without that system there is nothing to re-derive it from,
     and a transformation pulled back but never re-verified is exactly
     the "stored flag as evidence" this module refuses everywhere else. *)
  If[! MatchQ[blockSystem, {_?MatrixQ, _?MatrixQ}],
    Return[<|"Status" -> "ClassFormNoBlockSystemToVerifyAgainst"|>]];
  {ax, ay} = blockSystem;
  If[Dimensions[ax] =!= Dimensions[tx] || Dimensions[ay] =!= Dimensions[tx],
    Return[<|"Status" -> "ClassFormBlockDimensionMismatch"|>]];

  (* The stored EpsForm is provenance.  It is pulled back by the same
     chain rule and COMPARED; a disagreement means the record does not
     describe this block as it stands, and that is a refusal, not a note.
     It is pulled back HERE, before the gate, because it is also what the
     member's basis permutation is recovered from (below). *)
  stored = Lookup[rec, "CachedTransformedConnectionMatrices", None];
  If[! MatchQ[stored, {_?MatrixQ, _?MatrixQ}] &&
      ListQ[recordAlphabet] && ListQ[storedResidues] &&
      Length[recordAlphabet] === Length[storedResidues],
    stored = Table[
      eps Total[MapThread[#1 D[Log[#2], recordVariables[[j]]] &,
        {storedResidues, recordAlphabet}]],
      {j, 2}]];
  storedPulled = None;
  If[MatchQ[stored, {_?MatrixQ, _?MatrixQ}] &&
      Dimensions[stored[[1]]] === Dimensions[tx] &&
      Dimensions[stored[[2]]] === Dimensions[tx],
    jacobian = Map[Together, {
      {D[images[[1]], x], D[images[[1]], y]},
      {D[images[[2]], x], D[images[[2]], y]}}, {2}];
    storedPulled = masterTransportPullBackOneForm[
      Map[Together,
        stored[[1]] /. coordinates["CoefficientVariableRules"], {2}],
      Map[Together,
        stored[[2]] /. coordinates["CoefficientVariableRules"], {2}],
      jacobian]];
  (* A dlog alphabet pulls back functorially: dlog L becomes
       dlog (L o chart).
     Preserve that information while the class chart is still known.
     Recover it from the rational class form when older records did not
     store an explicit Alphabet; factoring the already algebraic target
     form later can lose conjugate letters even when every basis-change
     identity passes. *)
  If[! ListQ[recordAlphabet] && MatchQ[stored, {_?MatrixQ, _?MatrixQ}] &&
      ListQ[recordVariables],
    recordAlphabet = Quiet[Check[
      familyCertLetters[stored, recordVariables, eps], {}]]];
  pulledAlphabet = If[ListQ[recordAlphabet],
    DeleteDuplicates[DeleteCases[
      Quiet[Check[Together[
        #1 /. coordinates["CoefficientVariableRules"]], $Failed]] & /@
        Select[recordAlphabet, FreeQ[#1, eps] &], $Failed]],
    {}];

  (* One candidate basis permutation q, put through both exact gates.
     (P T P^T)^-1 = P T^-1 P^T exactly, so the inverse that was just
     re-multiplied out both ways is permuted rather than recomputed, and
     the epsilon-form of a permuted member is the representative's
     permuted the same way. *)
  evaluate[q_] := Module[{qx, qi, qex, qey, qstored, qlinear, qmatch},
    qx = tx[[q, q]];
    qi = tInverse[[q, q]];
    qex = Map[Together, qi . ax . qx - qi . D[qx, x], {2}];
    qey = Map[Together, qi . ay . qx - qi . D[qx, y], {2}];
    qlinear = AllTrue[Flatten[{qex, qey}],
      (TrueQ[Together[#] === 0] || FreeQ[Together[#/eps], eps]) &];
    qstored = If[storedPulled === None, None,
      {storedPulled[[1]][[q, q]], storedPulled[[2]][[q, q]]}];
    qmatch = If[qstored === None, None,
      masterTransportZeroMatQ[qstored[[1]] - qex] &&
        masterTransportZeroMatQ[qstored[[2]] - qey]];
    <|"Permutation" -> q, "T" -> qx, "TInverse" -> qi, "Ex" -> qex, "Ey" -> qey,
      "EpsFormLinear" -> qlinear, "Matches" -> qmatch,
      "OK" -> TrueQ[qlinear] && (qmatch === None || TrueQ[qmatch])|>];

  identity = Range[Length[tx]];
  result = evaluate[identity];
  permutation = None;
  (* Class equivalence is a basis PERMUTATION composed with the optional
     v <-> w swap.  The swap is the caller's business -- in this chart it
     is the involution (x,y) -> (1-x,1-y), which the caller applies by
     exchanging the two chart images -- but the PERMUTATION was missing
     here, so a permuted member was refused as
     a diagonal-block epsilon-form mismatch.  It is recovered from the
     representative's own coefficient-representation connection,
     A_rep = (T . E + dT) . T^-1, and then put through the same two exact
     gates, so a wrong candidate cannot pass. *)
  If[! TrueQ[result["OK"]] && storedPulled =!= None && Length[tx] > 1,
    repChart = {
      Map[Together, (tx . storedPulled[[1]] + D[tx, x]) . tInverse, {2}],
      Map[Together, (tx . storedPulled[[2]] + D[tx, y]) . tInverse, {2}]};
    permutation = masterTransportClassMemberPermutation[repChart, {ax, ay},
      {x, y}, eps];
    If[ListQ[permutation] && permutation =!= identity,
      Module[{candidate = evaluate[permutation]},
        If[TrueQ[candidate["OK"]], result = candidate]]]];

  {ex, ey} = {result["Ex"], result["Ey"]};
  epsLinear = result["EpsFormLinear"];
  matches = result["Matches"];
  If[! TrueQ[epsLinear],
    Return[<|"Status" ->
        "DiagonalBlockNotEpsilonFactorizedAfterReexpression",
      "ClassID" -> classID,
      "CoordinateRepresentation" ->
        coordinates["CoordinateRepresentation"],
      "PermutationTried" -> permutation|>]];
  If[matches =!= None && ! TrueQ[matches],
    Return[<|"Status" -> "StoredDiagonalBlockEpsilonFormMismatch",
      "ClassID" -> classID,
      "CoordinateRepresentation" ->
        coordinates["CoordinateRepresentation"],
      "PermutationTried" -> permutation|>]];

  <|"DataType" -> "DiagonalBlockDLogEpsilonForm",
    "SchemaVersion" -> 2,
    "Status" -> "DiagonalBlockDLogEpsilonFormReexpressed",
    "BasisTransformationMatrix" -> result["T"],
    "InverseBasisTransformationMatrix" -> result["TInverse"],
    "CachedTransformedConnectionMatrices" -> {ex, ey},
    "Letters" -> pulledAlphabet,
    "Source" -> "coefficient-variable-reexpression", "ClassID" -> classID,
    "CoordinateRepresentation" ->
      coordinates["CoordinateRepresentation"],
    "CoefficientVariables" -> {x, y},
    "Coordinates" -> coordinates, "Swapped" -> swapped,
    "Permutation" -> result["Permutation"],
    "Certificate" -> <|
      "CoordinateRepresentation" ->
        coordinates["CoordinateRepresentation"],
      "CompositionVerified" -> coordinates["CompositionVerified"],
      "CompositionStatement" -> coordinates["CompositionStatement"],
      "CoefficientPresentationKind" -> presentationKind,
      "BasisTransformationRationalInCoefficientVariables" ->
        rationalTransformation,
      "BasisTransformationUsesOnlyDeclaredSquareRootGenerators" ->
        declaredSquareRootGeneratorsOnly,
      "TransformationInvertible" -> True,
      "TransformationInverseVerified" -> inverseOK,
      "EpsFormReDerivedFromBlockSystem" -> True,
      "EpsFormLinear" -> epsLinear,
      "StoredEpsFormPullbackMatches" -> matches,
      "Swapped" -> swapped,
      "Permutation" -> result["Permutation"],
      "Exact" -> True|>|>
];

masterTransportPullBackClassForm[record_Association, coefficientPresentation_,
    opts : OptionsPattern[]] := Module[
  {sourceVariables, data, eps, rec, swap, attempts, results, found, attempt,
   presentationKind, presentationVariables},
  sourceVariables = OptionValue["SourceVariables"];
  If[sourceVariables === Automatic,
    sourceVariables = masterTransportDefaultVariables[]];
  data = masterTransportCoefficientPresentationData[
    coefficientPresentation, sourceVariables];
  If[data["Status"] =!= "OK", Return[data]];
  presentationKind = Lookup[data, "PresentationKind", None];
  If[! MemberQ[{"SourceVariables", "RationalizingParametrization",
      "SquareRootGeneratorsAndQuadraticRelations"}, presentationKind],
    Return[<|"Status" -> "ClassFormCoefficientPresentationKindInvalid",
      "PresentationKind" -> presentationKind|>]];
  presentationVariables = masterTransportPresentationVariables[data];
  eps = OptionValue["Regulator"];
  If[eps === Automatic,
    eps = masterTransportDetectRegulator[record,
      Join[data["SourceVariables"], presentationVariables]]];
  If[! MatchQ[eps, _Symbol],
    Return[<|"Status" -> "ClassFormRegulatorUnresolved"|>]];
  (* One normalization for the whole record, by SymbolName, before any
     substitution: a record read from a file carries its own v, w, x, y
     and eps, and substituting the caller's symbols into a record written
     with different ones matches nothing while reporting success. *)
  rec = masterTransportNormalize[record, eps,
    Join[data["SourceVariables"], presentationVariables]];
  swap = OptionValue["Swap"];
  attempts = Switch[swap, True, {True}, False, {False}, _, {False, True}];
  (* M2: no Return inside the Do -- it would return from the Do, and an
     inner Module would swallow a Return[..., Module] as well. *)
  results = {}; found = None;
  Do[
    If[found === None,
      attempt = masterTransportPullBackClassFormOnce[rec,
        If[TrueQ[s], masterTransportChartSwapData[data], data], eps,
        OptionValue["BlockSystem"], OptionValue["ClassID"], TrueQ[s],
        presentationKind];
      results = Append[results, attempt];
      If[AssociationQ[attempt] && attempt["Status"] ===
          "DiagonalBlockDLogEpsilonFormReexpressed",
        found = attempt]],
    {s, attempts}];
  (* the UNSWAPPED refusal is the one reported, because it names what the
     record actually is *)
  If[found =!= None, found, First[results]]
];


(* Re-express one diagonal-block specification in the selected coefficient
   presentation.  The inner assembly independently recomputes the
   transformed diagonal block and compares it with this result. *)
masterTransportChartBlockSpec[specification_, rows_List, ax_, ay_,
    data_Association, eps_Symbol, formDirectory_] := Module[
  {record, file, classID, blockSystem, pulled, loaded},
  blockSystem = {ax[[rows, rows]], ay[[rows, rows]]};
  classID = None;
  record = Which[
    specification === Automatic,
      If[Length[rows] === 1,
        Return[<|"Status" -> "OK", "Spec" -> Automatic,
          "Certificate" -> <|
            "CoefficientRepresentation" -> "ScalarAutomatic",
            "CoefficientVariables" ->
              masterTransportPresentationVariables[data],
            "Note" -> "1x1 block; the scalar dlog provider runs in the selected \
coefficient variables and its form is certified by the assembly"|>|>],
        Return[<|"Status" -> "DiagonalBlockProviderRequired",
          "Rows" -> rows|>]],
    IntegerQ[specification],
      classID = specification;
      If[! StringQ[formDirectory] || ! DirectoryQ[formDirectory],
        Return[<|"Status" -> "DiagonalBlockEpsilonFormDirectoryMissing",
          "Rows" -> rows|>]];
      file = FileNameJoin[{formDirectory, "class" <> ToString[specification] <> ".wl"}];
      If[! FileExistsQ[file],
        Return[<|"Status" -> "FormFileMissing", "File" -> file, "Rows" -> rows|>]];
      (* M2/scoping: the read is NOT wrapped in an inner Module, because
         Return inside one exits that Module and its value would then be
         used as the record instead of refusing. *)
      loaded = FamilyArtifactRead[file];
      If[! AssociationQ[loaded],
        Return[<|"Status" -> "FormFileUnreadable", "File" -> file, "Rows" -> rows|>]];
      loaded,
    AssociationQ[specification] &&
        KeyExistsQ[specification, "DiagonalBlockDLogEpsilonForm"],
      classID = Lookup[specification, "ClassID", None];
      specification["DiagonalBlockDLogEpsilonForm"],
    AssociationQ[specification] &&
        MatrixQ[Lookup[specification, "BasisTransformationMatrix", $Failed]],
      classID = Lookup[specification, "ClassID", None];
      specification,
    True, Return[<|"Status" -> "DiagonalBlockProviderUnknown",
      "Rows" -> rows|>]];
  pulled = masterTransportPullBackClassForm[record, data,
    "SourceVariables" -> data["SourceVariables"], "Regulator" -> eps,
    "BlockSystem" -> blockSystem,
    "ClassID" -> classID];
  If[pulled["Status"] =!= "DiagonalBlockDLogEpsilonFormReexpressed",
    Return[Join[pulled, <|"Rows" -> rows, "ClassID" -> classID|>]]];
  (* Ev, Ew and TInverse travel with the specification because they were
     just derived and CERTIFIED here (the inverse re-multiplied out both
     ways, the epsilon-form re-derived from this very block system).  The
     assembly still recomputes the conjugated diagonal block from T and
     compares it against them -- "DiagonalEqualsDeclaredForm" -- so the
     statement is still made twice, independently, and what is saved is
     one redundant 4x4 symbolic inverse per hard block, not a check. *)
  <|"Status" -> "OK", "Rows" -> rows, "ClassID" -> classID,
    "Spec" -> <|"Type" -> "EpsForm",
      "T" -> pulled["BasisTransformationMatrix"],
      "TInverse" -> pulled["InverseBasisTransformationMatrix"],
      "Ev" -> pulled["CachedTransformedConnectionMatrices"][[1]],
      "Ew" -> pulled["CachedTransformedConnectionMatrices"][[2]],
      "Alphabet" -> Lookup[pulled, "Letters", {}]|>,
    "Form" -> pulled, "Certificate" -> pulled["Certificate"]|>
];

Options[AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks] = {
  "SourceVariables" -> Automatic,
  "Blocks" -> Automatic,
  "FormDirectory" -> None,
  "Regulator" -> Automatic,
  "Verbose" -> False
};

AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[
    system_, rootData_, opts : OptionsPattern[]] := Catch[
  Module[{sourceVariables, data, eps, normalized, pullback, chartSystem,
    chartVariables, blockSpecification, blocks, specs, resolved, failures,
    formDirectory, verbose, forms, presentationKind, assembled},
    verbose = TrueQ[OptionValue["Verbose"]];
    (* OptionValue is resolved once, in the body, and never from inside a
       nested Table or Function where the enclosing definition is no
       longer the innermost one. *)
    sourceVariables = masterTransportResolveVariables[OptionValue["SourceVariables"]];
    If[sourceVariables === $Failed,
      masterTransportFail[
        AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks,
        "option", "SourceVariables", OptionValue["SourceVariables"],
        AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks]];
    If[! AssociationQ[system],
      masterTransportFail[
        AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks,
        "option", "input", system,
        AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks]];
    data = masterTransportCoefficientPresentationData[
      rootData, sourceVariables];
    If[data["Status"] =!= "OK",
      Return[<|"Status" -> "FamilyRootDataRefused", "RootData" -> data,
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    presentationKind = Lookup[data, "PresentationKind", None];
    If[! MemberQ[{"SourceVariables", "RationalizingParametrization",
        "SquareRootGeneratorsAndQuadraticRelations"}, presentationKind],
      Return[<|"Status" -> "CoefficientPresentationKindInvalid",
        "PresentationKind" -> presentationKind,
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    chartVariables = masterTransportPresentationVariables[data];

    eps = masterTransportResolveRegulator[OptionValue["Regulator"],
      {Lookup[system, "Av", 0], Lookup[system, "Aw", 0]}, sourceVariables];
    If[eps === $Failed || ! MatchQ[eps, _Symbol],
      masterTransportFail[
        AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks,
        "regulator",
        Lookup[system, "Family", system]]];
    (* P2 again: normalize BEFORE any pullback and long before a backend
       package can claim v, w, x, y or eps for itself. *)
    normalized = masterTransportNormalize[system, eps,
      Join[sourceVariables[[{1, 2}]], chartVariables]];

    masterTransportLog[verbose, "coefficient presentation: ",
      masterTransportPresentationSubstitution[data],
      ", Jacobian determinant = ", data["JacobianDeterminant"]];

    pullback = masterTransportPullBackSystem[normalized, data,
      "SourceVariables" -> sourceVariables,
      "FlatnessCheck" -> (masterTransportCheckLevel[] =!= "Production")];
    If[pullback["Status"] =!= "OK",
      Return[<|"Status" -> "DifferentialSystemReexpressionFailed",
        "Reason" -> pullback["Status"],
        "DifferentialSystemReexpression" -> <|"System" -> pullback|>,
        "RootData" -> rootData,
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    chartSystem = pullback["System"];
    masterTransportLog[verbose,
      "  differential system re-expressed: flat after substitution ",
      pullback["Certificate"]["PulledBackSystemFlat"]];

    formDirectory = OptionValue["FormDirectory"];
    If[formDirectory === Automatic, formDirectory = None];

    blockSpecification = OptionValue["Blocks"];
    If[blockSpecification === Automatic,
      Return[<|"Status" -> "DiagonalBlockSpecificationsRequired",
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    If[! ListQ[blockSpecification] || blockSpecification === {} ||
        ! AllTrue[blockSpecification,
          MatchQ[#, {{__Integer}, _}] &],
      Return[<|"Status" -> "DiagonalBlockSpecificationsNotWellFormed",
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    blocks = blockSpecification[[All, 1]];
    specs = blockSpecification[[All, 2]];

    resolved = Table[
      Module[{r, resolvedSpecification, transformation},
        r = masterTransportChartBlockSpec[specs[[i]], blocks[[i]],
          pullback["Ax"], pullback["Ay"], data, eps, formDirectory];
        resolvedSpecification = Lookup[r, "Spec", None];
        transformation = If[AssociationQ[resolvedSpecification],
          Lookup[resolvedSpecification, "T", None], None];
        (* Per-block progress records the block, its dimension, the
           coefficient representation and the object size. *)
        masterTransportLog[verbose, "  block ", i, "/", Length[blocks],
          " rows ", blocks[[i]], " dim ", Length[blocks[[i]]],
          " class ", Lookup[r, "ClassID", "-"], " -> ", r["Status"],
          " coefficient representation ",
          Lookup[Lookup[r, "Certificate", <||>],
            "CoefficientRepresentation", "-"],
          If[TrueQ[Lookup[Lookup[r, "Certificate", <||>], "Swapped", False]],
            " swapped", ""],
          " T leaves ", If[MatrixQ[transformation],
            LeafCount[transformation], "-"],
          " bytes ", If[MatrixQ[transformation],
            ByteCount[transformation], "-"]];
        r],
      {i, Length[blocks]}];
    failures = Select[Transpose[{blocks, resolved}], #[[2]]["Status"] =!= "OK" &];
    (* Every diagonal-block form is re-expressed in the selected
       coefficient presentation and re-derived from that block's
       differential equation before it enters the family assembly. *)
    If[failures =!= {},
      Return[<|"Status" -> "DiagonalBlockReexpressionFailed",
        "Reason" -> "ClassFormNotPullable",
        "DifferentialSystemReexpression" -> <|
          "System" -> pullback["Certificate"],
          "Forms" -> resolved|>,
        "Failures" -> failures, "RootData" -> rootData,
        "Family" -> Lookup[system, "Family", None]|>, Module]];

    forms = Association @ Table[
      blocks[[i]] -> resolved[[i]]["Certificate"], {i, Length[blocks]}];
    assembled = masterTransportAssemble[chartSystem, eps, chartVariables,
      "Blocks" -> Table[{blocks[[i]], resolved[[i]]["Spec"]},
        {i, Length[blocks]}],
      "Verbose" -> verbose];
    If[! AssociationQ[assembled] || assembled["Status"] =!= "OK" ||
        ! TrueQ[masterTransportCertificateOK[assembled]],
      Return[<|"Status" -> "FamilyDifferentialSystemAssemblyFailed",
        "FamilyDifferentialSystem" -> assembled,
        "RootData" -> rootData,
        "DifferentialSystemReexpression" -> <|
          "System" -> pullback["Certificate"], "Forms" -> forms|>,
        "Family" -> Lookup[system, "Family", None]|>, Module]];
    <|
      "DataType" ->
        "FamilyDifferentialSystemWithEpsilonFormDiagonalBlocks",
      "SchemaVersion" -> 2,
      "Status" ->
        "FamilyDifferentialSystemAssembledWithEpsilonFormDiagonalBlocks",
      "Family" -> Lookup[system, "Family", None],
      "CoefficientPresentation" -> data,
      "FamilyDifferentialSystem" -> assembled,
      "DifferentialSystemReexpression" -> <|
        "System" -> pullback["Certificate"], "Forms" -> forms|>,
      "SourceVariables" -> sourceVariables[[{1, 2}]]|>
  ],
  $masterTransportFailure
];
