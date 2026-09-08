(* Exact rational gauge for an off-diagonal CANONICA strip.

   The residue compatibility equations can leave kinematics-independent
   residues free.  Rationality of the gauge fixes the required combination.
   The free residues are embedded into Mratsolde's exact linear system and
   the remaining constants are fixed by the differential equation in all
   variables.  A result is returned only after exact two-variable checks.
*)

ClearAll[SolveResidueRationalGauge];

SolveResidueRationalGauge::builder =
  "BuildResidueCompatibility is not loaded or returned $Failed.";
SolveResidueRationalGauge::canonica =
  "CANONICA RatFunctionZeroCoeffs is not loaded.";
SolveResidueRationalGauge::maple =
  "No exact rational gauge was found by the configured Maple solver.";

Options[SolveResidueRationalGauge] = {
  "MapleExecutable" -> "maple",
  "MapleLibrary" -> Automatic,
  "ScratchDirectory" -> Directory[],
  "Tag" -> "residue_strip",
  "TimeLimit" -> 1800,
  "Verbose" -> False
};

SolveResidueRationalGauge[
    {e_List, c_List, bbar_List}, variables : {_, _}, epsilon_Symbol,
    OptionsPattern[]] :=
 Module[
  {mapleExecutable, mapleLibrary, scratchDirectory, tag, timeLimit, verbose,
   residueData, freeResidues, forcing, shape, dimension, connection,
   externalIndices, mapleUnknownHead, mapleUnknowns, forcingUnknown,
   source, toMaple, normalizeRegulator, ratFunctionZeroCoeffs,
   zeroQ, candidates, firstVariableIndex, mapleFile, outputFile,
   mapleText, process, elapsed, raw, lines, solutionText, residueText,
   indexedConstantIndices, indexedConstantSymbols, indexedConstantRules,
   parseMaple, gaugeVectorParametric, residueValuesParametric,
   gaugeParametric, residueRulesParametric, forcingParametric,
   odeResidualParametric, parameterVariables, parameterEquations,
   parameterSolutions, parameterRules, remainingParameters,
   gauge, residueValues, residueRules, solvedForcing, residueMatrices,
   dlog, odeResidual, transformedResidual, result, log},

  mapleExecutable = OptionValue["MapleExecutable"];
  mapleLibrary = Replace[OptionValue["MapleLibrary"],
    Automatic :> FileNameJoin[{DirectoryName[$InputFileName],
      "IntegrableConnections"}]];
  scratchDirectory = OptionValue["ScratchDirectory"];
  tag = OptionValue["Tag"];
  timeLimit = OptionValue["TimeLimit"];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print[items]];
  If[! DirectoryQ[scratchDirectory],
    CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];

  If[DownValues[BuildResidueCompatibility] === {},
    Message[SolveResidueRationalGauge::builder]; Return[$Failed]];
  residueData = BuildResidueCompatibility[
    {e, c, bbar}, variables, epsilon];
  If[residueData === $Failed,
    Message[SolveResidueRationalGauge::builder]; Return[$Failed]];

  ratFunctionZeroCoeffs = Which[
    DownValues[CANONICA`RatFunctionZeroCoeffs] =!= {},
      CANONICA`RatFunctionZeroCoeffs,
    DownValues[CANONICA`Private`RatFunctionZeroCoeffs] =!= {},
      CANONICA`Private`RatFunctionZeroCoeffs,
    True, Message[SolveResidueRationalGauge::canonica]; Return[$Failed]
  ];

  freeResidues = residueData["FreeResidues"];
  forcing = residueData["Forcing"];
  shape = Dimensions[bbar[[1]]];
  dimension = Times @@ shape;
  connection = Table[
    epsilon (KroneckerProduct[e[[mu]], IdentityMatrix[shape[[2]]]] -
      KroneckerProduct[IdentityMatrix[shape[[1]]], Transpose[c[[mu]]]]),
    {mu, 2}];

  externalIndices = Range[1001, 1000 + Length[freeResidues]];
  mapleUnknownHead = Symbol["Global`c"];
  mapleUnknowns = mapleUnknownHead /@ externalIndices;
  forcingUnknown = forcing /. Thread[freeResidues -> mapleUnknowns];
  source = Flatten /@ forcingUnknown;

  toMaple[expr_] := StringReplace[ToString[expr, InputForm],
    {"Global`" -> "", " " -> ""}];
  normalizeRegulator[expr_] := Module[{symbols},
    symbols = DeleteDuplicates[Cases[expr,
      symbol_Symbol /; MemberQ[
        {"eps", "Eps", "epsilon", "Epsilon", "ep"},
        SymbolName[symbol]], Infinity, Heads -> True]];
    expr /. Thread[symbols -> epsilon]
  ];
  zeroQ[expr_] := AllTrue[Flatten[expr], TrueQ[Together[#] === 0] &];

  candidates = {};
  result = $Failed;
  Do[
    mapleFile = FileNameJoin[{scratchDirectory,
      tag <> "_first_" <> ToString[firstVariableIndex] <> ".mpl"}];
    outputFile = FileNameJoin[{scratchDirectory,
      tag <> "_first_" <> ToString[firstVariableIndex] <> ".out"}];
    If[FileExistsQ[outputFile], DeleteFile[outputFile]];
    mapleText = StringJoin[
      "restart:\nlibname := \"", mapleLibrary, "\", libname:\n",
      "with(IntegrableConnections):\nwith(linalg):\n",
      "A1 := matrix(", ToString[dimension], ",", ToString[dimension],
        ",[", StringRiffle[toMaple /@ Flatten[connection[[1]]], ","],
        "]):\n",
      "A2 := matrix(", ToString[dimension], ",", ToString[dimension],
        ",[", StringRiffle[toMaple /@ Flatten[connection[[2]]], ","],
        "]):\n",
      "b1 := vector(", ToString[dimension], ",[",
        StringRiffle[toMaple /@ source[[1]], ","], "]):\n",
      "b2 := vector(", ToString[dimension], ",[",
        StringRiffle[toMaple /@ source[[2]], ","], "]):\n",
      "fd := fopen(\"", outputFile, "\", WRITE):\n",
      "try\n",
      "  V := Mratsolde(A", ToString[firstVariableIndex], ",",
        ToString[variables[[firstVariableIndex]], InputForm], ",b",
        ToString[firstVariableIndex], "):\n",
      "  if V = {} then fprintf(fd, \"FAIL\\n\") else ",
        "fprintf(fd, \"OK\\n%a\\n%a\\n\",convert(V,list),",
        toMaple[mapleUnknowns], ") end if:\n",
      "catch: fprintf(fd, \"ERROR\\n%a\\n\",lastexception): end try:\n",
      "fclose(fd):\nquit:\n"];
    Export[mapleFile, mapleText, "Text"];
    elapsed = AbsoluteTiming[
      process = TimeConstrained[
        RunProcess[{mapleExecutable, "-q", mapleFile}],
        timeLimit, $TimedOut]][[1]];
    If[process === $TimedOut || ! FileExistsQ[outputFile],
      log["Maple did not produce output for first variable ",
        firstVariableIndex]; Continue[]];
    raw = Import[outputFile, "Text"];
    lines = StringSplit[raw, "\n"];
    If[lines === {} || First[lines] =!= "OK" || Length[lines] < 3,
      log["Maple returned ", If[lines === {}, "empty output", First[lines]],
        " for first variable ", firstVariableIndex]; Continue[]];
    solutionText = lines[[2]];
    residueText = lines[[3]];

    indexedConstantIndices = Union[StringCases[
      solutionText <> residueText,
      "c[" ~~ digits : DigitCharacter .. ~~ "]" :> ToExpression[digits]]];
    indexedConstantSymbols =
      Symbol["Global`cc" <> ToString[#]] & /@ indexedConstantIndices;
    log["First variable ", firstVariableIndex,
      ": indexed constants ", indexedConstantIndices];
    indexedConstantRules = Table[
      "c[" <> ToString[indexedConstantIndices[[i]]] <> "]" ->
        SymbolName[indexedConstantSymbols[[i]]],
      {i, Length[indexedConstantIndices]}];
    parseMaple[text_] := normalizeRegulator[ToExpression[StringReplace[
      text, Join[indexedConstantRules, {"[" -> "{", "]" -> "}"}]]]];
    gaugeVectorParametric = Map[Together, parseMaple[solutionText]];
    residueValuesParametric = Map[Together, parseMaple[residueText]];
    If[Length[gaugeVectorParametric] =!= dimension ||
       Length[residueValuesParametric] =!= Length[freeResidues],
      log["Parsed dimensions do not match the strip."]; Continue[]];

    gaugeParametric = ArrayReshape[gaugeVectorParametric, shape];
    residueRulesParametric =
      Thread[freeResidues -> residueValuesParametric];
    forcingParametric = Map[Together,
      forcing /. residueRulesParametric, {3}];
    odeResidualParametric = Table[
      Map[Together,
        D[gaugeParametric, variables[[mu]]] -
          epsilon (e[[mu]].gaugeParametric -
            gaugeParametric.c[[mu]]) - forcingParametric[[mu]], {2}],
      {mu, 2}];
    parameterVariables = Select[indexedConstantSymbols,
      ! FreeQ[{gaugeParametric, residueValuesParametric}, #] &];
    parameterEquations = DeleteCases[DeleteDuplicates@Flatten[
      ratFunctionZeroCoeffs[#, variables] & /@
        Flatten[odeResidualParametric]], 0];
    parameterSolutions = If[parameterEquations === {}, {{}},
      Quiet[Solve[Thread[parameterEquations == 0], parameterVariables]]];
    log["Parameter equations: ", Length[parameterEquations],
      "; variables: ", parameterVariables];
    If[parameterSolutions === {},
      log["The exact parameter equations are inconsistent."]; Continue[]];
    parameterRules = First[parameterSolutions];
    If[parameterRules =!= {},
      parameterRules = FixedPoint[
        Function[rules,
          Thread[First /@ rules -> Together[(Last /@ rules) /. rules]]],
        parameterRules, 50]];
    remainingParameters = Select[parameterVariables,
      ! FreeQ[{gaugeParametric, residueValuesParametric} /.
        parameterRules, #] &];
    parameterRules = Join[parameterRules, Thread[remainingParameters -> 0]];

    gauge = Map[Together, gaugeParametric /. parameterRules, {2}];
    residueValues = Map[Together,
      residueValuesParametric /. parameterRules];
    residueRules = Thread[freeResidues -> residueValues];
    solvedForcing = Map[Together, forcing /. residueRules, {3}];
    residueMatrices = residueData["ResidueMatrices"] /. residueRules;
    dlog = residueData["DLog"];
    odeResidual = Table[
      Map[Together,
        D[gauge, variables[[mu]]] -
          epsilon (e[[mu]].gauge - gauge.c[[mu]]) -
          solvedForcing[[mu]], {2}], {mu, 2}];
    transformedResidual = Table[
      Map[Together,
        bbar[[mu]] + epsilon (e[[mu]].gauge - gauge.c[[mu]]) -
          D[gauge, variables[[mu]]] - epsilon Sum[
            residueMatrices[[a]] dlog[[a, mu]],
            {a, Length[residueMatrices]}], {2}], {mu, 2}];
    If[zeroQ[odeResidual] && zeroQ[transformedResidual],
      result = <|
        "Gauge" -> gauge,
        "ResidueRules" -> residueRules,
        "ResidueMatrices" -> residueMatrices,
        "FreeResidues" -> freeResidues,
        "ParameterRules" -> parameterRules,
        "ParameterEquationCount" -> Length[parameterEquations],
        "Alphabet" -> residueData["Alphabet"],
        "FirstVariableIndex" -> firstVariableIndex,
        "FirstVariable" -> variables[[firstVariableIndex]],
        "MapleSeconds" -> elapsed,
        "ODEEquationZero" -> True,
        "TransformedDLogZero" -> True
      |>;
      Break[]
    ];
    log["Exact residual did not vanish after parameter specialization: ",
      {Count[Flatten[odeResidual], value_ /; Together[value] =!= 0],
       Count[Flatten[transformedResidual],
        value_ /; Together[value] =!= 0]}];
    AppendTo[candidates, <|"FirstVariableIndex" -> firstVariableIndex,
      "ParameterEquationCount" -> Length[parameterEquations]|>],
    {firstVariableIndex, 1, 2}];

  If[AssociationQ[result], result,
    Message[SolveResidueRationalGauge::maple]; $Failed]
 ]
