
(* ==== moved from Private/LibraEpsForm.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: whole-family Libra eps-form route; no script, one test (t_libra_family_eps_form, moved to Private_Backup/Tests); superseded by the finite-field completion + FactorFamilyRegulatorDependence; route_split.py 2026-09-02: 9 route-only symbols. The Libra loader helpers libraEpsFormLoadBackend/libraEpsFormFermatCompatibleQ stay (used by FamilyRegulatorFactor)
   Symbols: LibraFamilyEpsForm, libraEpsFormDLogData, libraEpsFormEpsFactoredQ, libraEpsFormLog, libraEpsFormPoleFactors, libraEpsFormPrepareAssembly, libraEpsFormSpecializeFactorOut, libraEpsFormTimed, libraEpsFormZeroQ
   This file is never loaded by FeynFacet.m. *)


libraEpsFormLog[verbose_, args___] := If[TrueQ[verbose],
  WriteString[masterTransportLogStream[], "[libra-eps] ",
    StringJoin[ToString /@ {args}], "\n"];
  Flush[masterTransportLogStream[]]
];
libraEpsFormTimed[expression_, seconds_] := Quiet[
  TimeConstrained[CheckAbort[expression, "Aborted"], seconds, "TimedOut"]];

(* Together does not clear square-root denominators, so on the
   algebraic frames this module accepts a genuinely zero certificate
   read as nonzero (2026-08-20 review). RootReduce decides the
   algebraic case; it is attempted only when radicals are present. *)
libraEpsFormZeroQ[expr_] := AllTrue[Flatten[{expr}],
  Function[entry, Module[{t = Together[entry]},
    TrueQ[t === 0] || (! FreeQ[t, Power[_, _Rational]] &&
      TrueQ[Quiet[RootReduce[t]] === 0])]]];

libraEpsFormEpsFactoredQ[matrix_, epsilon_Symbol] :=
  AllTrue[Flatten[matrix],
    TrueQ[Together[#] === 0] || FreeQ[Together[#/epsilon], epsilon] &];

libraEpsFormPoleFactors[matrix_, variable_Symbol] := Module[
  {factors},
  factors = Flatten[Table[
    If[TrueQ[entry === 0], {},
      Select[First /@ Rest[FactorList[Denominator[Together[entry]]]],
        ! FreeQ[#, variable] &]],
    {entry, Flatten[matrix]}]];
  DeleteDuplicates[
    epsFormStripMonicPolynomial[#, variable] & /@ factors]
];

libraEpsFormPrepareAssembly[
    system_Association, chart_, sourceOption_, regulatorOption_,
    blockSpecification_, formDirectory_, conicRoute_, verbose_] := Module[
  {sourceVariables, epsilon, normalized, data, pullback, chartSystem,
   variables, blocks, specifications, resolved, failures, assembly},

  If[! (MatrixQ[Lookup[system, "Av", $Failed]] &&
      MatrixQ[Lookup[system, "Aw", $Failed]] &&
      Dimensions[system["Av"]] === Dimensions[system["Aw"]] &&
      Length[system["Av"]] === Length[First[system["Av"]]]),
    Return[<|"Status" -> "SystemNotASquareMatrixPair"|>]];
  sourceVariables = masterTransportResolveVariables[sourceOption];
  If[sourceVariables === $Failed,
    Return[<|"Status" -> "SourceVariablesInvalid"|>]];
  epsilon = masterTransportResolveRegulator[regulatorOption,
    {system["Av"], system["Aw"]}, sourceVariables];
  If[epsilon === $Failed || ! MatchQ[epsilon, _Symbol],
    Return[<|"Status" -> "RegulatorNotResolved"|>]];

  If[chart === None,
    variables = sourceVariables[[{1, 2}]];
    normalized = masterTransportNormalize[system, epsilon, variables];
    chartSystem = normalized;
    data = None;
    pullback = <|"Status" -> "SourceVariables",
      "Variables" -> variables, "Certificate" -> <||>|>;
    assembly = masterTransportAssemble[chartSystem, epsilon, variables,
      "Blocks" -> blockSpecification, "FormDirectory" -> formDirectory,
      "Verbose" -> verbose],

    data = masterTransportChartData[chart, sourceVariables];
    If[! AssociationQ[data] || data["Status"] =!= "OK",
      Return[<|"Status" -> "ChartRefused", "Chart" -> data|>]];
    variables = data["Variables"];
    normalized = masterTransportNormalize[system, epsilon,
      Join[sourceVariables[[{1, 2}]], variables]];
    pullback = masterTransportPullBackSystem[normalized, data,
      "SourceVariables" -> sourceVariables];
    If[! AssociationQ[pullback] || pullback["Status"] =!= "OK",
      Return[<|"Status" -> "ChartPullBackFailed",
        "PullBack" -> pullback, "Chart" -> data|>]];
    chartSystem = pullback["System"];

    If[blockSpecification === Automatic,
      blocks = masterTransportSCCBlocks[pullback["Ax"], pullback["Ay"]];
      specifications = ConstantArray[Automatic, Length[blocks]],
      If[! MatchQ[blockSpecification, {{_List, _} ..}],
        Return[<|"Status" -> "BlocksInvalid"|>]];
      blocks = blockSpecification[[All, 1]];
      specifications = blockSpecification[[All, 2]]];
    resolved = Table[
      masterTransportChartBlockSpec[specifications[[i]], blocks[[i]],
        pullback["Ax"], pullback["Ay"], data, epsilon, formDirectory,
        conicRoute,
        (* the coefficient field of the class forms, as TransportFamilyInChart
           passes it; the argument was added to masterTransportChartBlockSpec
           on 2026-08-17 and this call was left behind, so the chart route
           returned unevaluated (t_libra_family_eps_form red, found 2026-08-21) *)
        Lookup[data, "CoefficientField", "Rational"]],
      {i, Length[blocks]}];
    failures = Select[Transpose[{blocks, resolved}],
      ! AssociationQ[#[[2]]] || #[[2]]["Status"] =!= "OK" &];
    If[failures =!= {},
      Return[<|"Status" -> "ChartBlockCompositionFailed",
        "Failures" -> failures, "PullBack" -> pullback["Certificate"],
        "Chart" -> data|>]];
    assembly = masterTransportAssemble[chartSystem, epsilon, variables,
      "Blocks" -> Table[{blocks[[i]], resolved[[i]]["Spec"]},
        {i, Length[blocks]}],
      "FormDirectory" -> None, "Verbose" -> verbose]
  ];

  If[! AssociationQ[assembly] || assembly["Status"] =!= "OK",
    Return[<|"Status" -> "AssemblyFailed", "Assembly" -> assembly,
      "PullBack" -> pullback, "Chart" -> data|>]];
  If[! masterTransportCertificateOK[assembly],
    Return[<|"Status" -> "AssemblyCertificateFailed",
      "Certificate" -> assembly["Certificate"],
      "PullBack" -> pullback, "Chart" -> data|>]];

  <|"Status" -> "OK", "Assembly" -> assembly,
    "Variables" -> variables, "Regulator" -> epsilon,
    "Chart" -> data, "PullBack" -> pullback|>
];

libraEpsFormSpecializeFactorOut[transformation_, reference_] := Module[
  {constants, rules},
  constants = DeleteDuplicates[Cases[transformation, _C, Infinity]];
  rules = Thread[constants -> Range[Length[constants]]];
  Map[Together, transformation /. rules /. reference -> 1, {2}]
];

libraEpsFormDLogData[
    connection : {_, _}, variables_List, epsilon_Symbol] := Module[
  {extract, check, converted, alphabet},
  If[! (libraEpsFormEpsFactoredQ[connection[[1]], epsilon] &&
      libraEpsFormEpsFactoredQ[connection[[2]], epsilon]),
    Return[<|"EpsFactored" -> False, "DLog" -> False,
      "Alphabet" -> {}|>]];
  If[! epsFormStripLoadCanonica[],
    Return[<|"EpsFactored" -> True, "DLog" -> False,
      "Alphabet" -> {}, "Reason" -> "CANONICANotLoaded"|>]];
  extract = epsFormStripCanonicaSymbol["ExtractIrreducibles"];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  If[MemberQ[{extract, check}, $Failed],
    Return[<|"EpsFactored" -> True, "DLog" -> False,
      "Alphabet" -> {}, "Reason" -> "CANONICAFunctionsMissing"|>]];
  converted = connection /. epsilon -> CANONICA`eps;
  alphabet = Union[variables,
    Select[extract[converted, CANONICA`AllowEpsDependence -> True],
      FreeQ[#, CANONICA`eps] &]];
  <|"EpsFactored" -> True,
    "DLog" -> TrueQ[check[converted, variables, alphabet]],
    "Alphabet" -> alphabet|>
];

LibraFamilyEpsForm[
    system_Association, chart_, OptionsPattern[]] := Module[
  {start, verbose, timeLimit, fuchsifyRounds, alternatingRounds,
   prepared, assembly, variables, epsilon, backend, libraOptions,
   fermatRequested, fermatCompatible, fermatChoice,
   ax, ay, ranges, blocks, n, xi, reference, totalTransformation,
   totalInverse, transformations = {}, steps = {}, applyTransformation,
   fuchsifyAxis, factorOutAxis, dlogData, triangular, diagonalEps,
   flat, blockTransformation, blockInverse, total, inverse, identity,
   gaugeX, gaugeY, gauge, exact, status, classes},

  start = AbsoluteTime[];
  verbose = TrueQ[OptionValue["Verbose"]];
  timeLimit = OptionValue["TimeLimit"];
  fuchsifyRounds = OptionValue["FuchsifyRounds"];
  alternatingRounds = OptionValue["AlternatingRounds"];
  If[! (IntegerQ[fuchsifyRounds] && fuchsifyRounds > 0 &&
      IntegerQ[alternatingRounds] && alternatingRounds > 0),
    Message[LibraFamilyEpsForm::rounds]; Return[$Failed]];

  prepared = libraEpsFormPrepareAssembly[system, chart,
    OptionValue["SourceVariables"], OptionValue["Regulator"],
    OptionValue["Blocks"], OptionValue["FormDirectory"],
    OptionValue["ConicChartRoute"], verbose];
  If[! AssociationQ[prepared] || prepared["Status"] =!= "OK",
    Message[LibraFamilyEpsForm::chart]; Return[prepared]];
  assembly = prepared["Assembly"];
  variables = prepared["Variables"];
  epsilon = prepared["Regulator"];
  {ax, ay} = {assembly["Apv"], assembly["Apw"]};
  ranges = assembly["Ranges"];
  blocks = assembly["Blocks"];
  n = assembly["N"];
  libraEpsFormLog[verbose, "assembled ", n, " masters in ",
    Length[blocks], " diagonal blocks"];

  fermatRequested = OptionValue["UseFermat"];
  fermatCompatible = libraEpsFormFermatCompatibleQ[{ax, ay}];
  fermatChoice = Which[
    fermatRequested === Automatic, False,
    fermatRequested === True, fermatCompatible,
    fermatRequested === False, False,
    True, fermatRequested];
  backend = libraEpsFormLoadBackend[fermatChoice];
  If[! AssociationQ[backend] || backend["Status"] =!= "OK",
    Message[LibraFamilyEpsForm::backend]; Return[backend]];
  libraOptions = backend["Options"];
  xi = Unique["libraXi"];
  reference = Unique["libraMu"];
  totalTransformation = IdentityMatrix[n];
  totalInverse = IdentityMatrix[n];

  applyTransformation[raw_] := Module[{transformation, transformationInverse},
    If[! MatrixQ[raw] || Dimensions[raw] =!= {n, n}, Return[False]];
    transformation = Map[Together, raw, {2}];
    transformationInverse = Quiet[Check[
      Map[Together, Inverse[transformation], {2}], $Failed]];
    If[! MatrixQ[transformationInverse] ||
        ! libraEpsFormZeroQ[
          transformation . transformationInverse - IdentityMatrix[n]],
      Return[False]];
    ax = Map[Together,
      transformationInverse . ax . transformation -
        transformationInverse . D[transformation, variables[[1]]], {2}];
    ay = Map[Together,
      transformationInverse . ay . transformation -
        transformationInverse . D[transformation, variables[[2]]], {2}];
    totalTransformation = Map[Together,
      totalTransformation . transformation, {2}];
    totalInverse = Map[Together,
      transformationInverse . totalInverse, {2}];
    AppendTo[transformations, transformation];
    True
  ];

  fuchsifyAxis[axis_Integer] := Module[
    {variable = variables[[axis]], component, fuchsian, poles,
     transformation, seconds, inverseConnection, round = 0,
     changed = True},
    component := If[axis === 1, ax, ay];
    fuchsian = libraEpsFormTimed[
      Libra`FuchsianQ[component, variable], Min[300, timeLimit]];
    While[fuchsian =!= True && changed && round < fuchsifyRounds,
      round++; changed = False;
      poles = libraEpsFormPoleFactors[component, variable];
      If[poles =!= {},
        {seconds, transformation} = AbsoluteTiming[
          libraEpsFormTimed[
            Libra`Fuchsify[component, variable, poles,
              Sequence @@ libraOptions], timeLimit]];
        AppendTo[steps, <|"Method" -> "FuchsifyFinite",
          "Axis" -> axis, "Round" -> round, "Seconds" -> seconds,
          "Result" -> If[MatrixQ[transformation], "Matrix", transformation]|>];
        If[MatrixQ[transformation] &&
            ! libraEpsFormZeroQ[transformation - IdentityMatrix[n]],
          changed = TrueQ[applyTransformation[transformation]]]];
      inverseConnection = Map[Together,
        -(component /. variable -> 1/xi)/xi^2, {2}];
      {seconds, transformation} = AbsoluteTiming[
        libraEpsFormTimed[
          Libra`Fuchsify[inverseConnection, xi, {xi},
            Sequence @@ libraOptions], timeLimit]];
      AppendTo[steps, <|"Method" -> "FuchsifyInfinity",
        "Axis" -> axis, "Round" -> round, "Seconds" -> seconds,
        "Result" -> If[MatrixQ[transformation], "Matrix", transformation]|>];
      If[MatrixQ[transformation] &&
          ! libraEpsFormZeroQ[transformation - IdentityMatrix[n]],
        changed = TrueQ[applyTransformation[
          Map[Together, transformation /. xi -> 1/variable, {2}]]] || changed];
      fuchsian = libraEpsFormTimed[
        Libra`FuchsianQ[component, variable], Min[300, timeLimit]]];
    fuchsian
  ];

  factorOutAxis[axis_Integer] := Module[
    {variable = variables[[axis]], component, transformation, seconds},
    component = If[axis === 1, ax, ay];
    If[libraEpsFormEpsFactoredQ[component, epsilon], Return[True]];
    {seconds, transformation} = AbsoluteTiming[
      libraEpsFormTimed[
        Libra`FactorOut[component, variable, epsilon, reference,
          Sequence @@ libraOptions], timeLimit]];
    AppendTo[steps, <|"Method" -> "FactorOut", "Axis" -> axis,
      "Seconds" -> seconds,
      "Result" -> If[MatrixQ[transformation], "Matrix", transformation]|>];
    If[! MatrixQ[transformation], Return[False]];
    transformation = libraEpsFormSpecializeFactorOut[
      transformation, reference];
    If[libraEpsFormZeroQ[transformation - IdentityMatrix[n]], True,
      applyTransformation[transformation]]
  ];

  dlogData = libraEpsFormDLogData[{ax, ay}, variables, epsilon];
  Do[
    If[TrueQ[dlogData["DLog"]], Break[]];
    Do[
      If[TrueQ[fuchsifyAxis[axis]], factorOutAxis[axis]],
      {axis, 2}];
    dlogData = libraEpsFormDLogData[{ax, ay}, variables, epsilon],
    {alternatingRounds}];

  triangular = AllTrue[Flatten[Table[
    If[j > i,
      Join[Flatten[ax[[ranges[[i]], ranges[[j]]]]],
        Flatten[ay[[ranges[[i]], ranges[[j]]]]]], {}],
    {i, Length[ranges]}, {j, Length[ranges]}]],
    TrueQ[Together[#] === 0] &];
  diagonalEps = AllTrue[Flatten[Table[
    {ax[[ranges[[i]], ranges[[i]]]],
      ay[[ranges[[i]], ranges[[i]]]]}, {i, Length[ranges]}]],
    TrueQ[Together[#] === 0] || FreeQ[Together[#/epsilon], epsilon] &];
  flat = libraEpsFormZeroQ[
    D[ax, variables[[2]]] - D[ay, variables[[1]]] + ax . ay - ay . ax];

  blockTransformation = ConstantArray[0, {n, n}];
  blockInverse = ConstantArray[0, {n, n}];
  Do[
    blockTransformation[[ranges[[i]], ranges[[i]]]] =
      assembly["Forms"][[i]]["T"];
    blockInverse[[ranges[[i]], ranges[[i]]]] =
      assembly["TInverse"][[i]],
    {i, Length[ranges]}];
  total = Map[Together, blockTransformation . totalTransformation, {2}];
  inverse = Map[Together, totalInverse . blockInverse, {2}];
  identity = libraEpsFormZeroQ[total . inverse - IdentityMatrix[n]] &&
    libraEpsFormZeroQ[inverse . total - IdentityMatrix[n]];
  gaugeX = Map[Together,
    inverse . assembly["Av"] . total - inverse . D[total, variables[[1]]] - ax,
    {2}];
  gaugeY = Map[Together,
    inverse . assembly["Aw"] . total - inverse . D[total, variables[[2]]] - ay,
    {2}];
  gauge = libraEpsFormZeroQ[{gaugeX, gaugeY}];
  dlogData = libraEpsFormDLogData[{ax, ay}, variables, epsilon];
  exact = And @@ (TrueQ /@ {
    dlogData["EpsFactored"], dlogData["DLog"], triangular,
    diagonalEps, flat, identity, gauge});
  status = If[exact, "EpsForm", "NotEpsForm"];
  classes = Lookup[assembly["Forms"], "ClassID", None];

  <|"Status" -> status, "Family" -> Lookup[system, "Family", None],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Chart" -> prepared["Chart"],
    "PullBack" -> If[AssociationQ[prepared["PullBack"]],
      Lookup[prepared["PullBack"], "Certificate", <||>], <||>],
    "Blocks" -> blocks, "Ranges" -> ranges, "Classes" -> classes,
    "TTotal" -> total, "TTotalInverse" -> inverse,
    "EpsFormX" -> ax, "EpsFormY" -> ay,
    "Letters" -> dlogData["Alphabet"],
    "Checks" -> <|"EpsFactored" -> dlogData["EpsFactored"],
      "DLog" -> dlogData["DLog"], "BlockLowerTriangular" -> triangular,
      "DiagonalEpsForm" -> diagonalEps, "Flatness" -> flat,
      "TransformationInverse" -> identity, "GaugeIdentity" -> gauge|>,
    "Backend" -> <|"Name" -> "Libra", "UseFermat" -> backend["UseFermat"],
      "FermatCompatible" -> fermatCompatible,
      "FermatRequested" -> fermatRequested|>,
    "Steps" -> steps, "TransformationCount" -> Length[transformations],
    "Seconds" -> AbsoluteTime[] - start|>
];
