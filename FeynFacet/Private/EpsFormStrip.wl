(* Exact off-diagonal epsilon-form strip solver.

   For diagonal connections eps e and eps c and an off-diagonal block bbar,
   the gauge D obeys

     d_mu D = eps (e_mu D - D c_mu) + F_mu,

   where the transformed strip must be a dlog one-form.  CANONICA is tried
   first in isolated kernels.  Maple is used only after the configured
   CANONICA ansatz degrees have all failed to produce an exactly checked
   dlog gauge.
*)

ClearAll[
  SolveResidueRationalGauge,
  SolveEpsFormStrip,
  epsFormStripCanonicaSymbol,
  epsFormStripLoadCanonica,
  epsFormStripZeroQ,
  epsFormStripShapeQ,
  epsFormStripAlphabet,
  epsFormStripExactDLogQ,
  epsFormStripBuildResidueCompatibility,
  epsFormStripRunCanonica,
  epsFormStripSafeTag
];

SolveResidueRationalGauge::shape =
  "The two-variable strip matrices e, c, and bbar have incompatible dimensions.";
SolveResidueRationalGauge::canonica =
  "CANONICA functions needed for the residue equations are unavailable.";
SolveResidueRationalGauge::residue =
  "The exact residue-compatibility equations are inconsistent.";
SolveResidueRationalGauge::maple =
  "Maple did not produce a rational gauge satisfying both differential equations exactly.";

SolveEpsFormStrip::shape =
  "The two-variable strip matrices e, c, and bbar have incompatible dimensions.";
SolveEpsFormStrip::canonica =
  "CANONICA could not be loaded from `1`.";
SolveEpsFormStrip::degrees =
  "CANONICA numerator degrees must be a nonempty list of nonnegative integers.";
SolveEpsFormStrip::failed =
  "Neither the configured CANONICA searches nor the exact Maple construction found a gauge.";

$epsFormStripCanonicaFile = FileNameJoin[{
  $feynFacetRoot, "Addon", "Mathematica_Addon", "CANONICA", "src",
  "CANONICA.m"
}];
$epsFormStripMapleLibrary = FileNameJoin[{
  $feynFacetRoot, "Addon", "Other_Addon", "Maple",
  "IntegrableConnections"
}];

epsFormStripCanonicaSymbol[name_String] := Module[{public, private},
  public = ToExpression["CANONICA`" <> name];
  private = ToExpression["CANONICA`Private`" <> name];
  Which[
    DownValues[Evaluate[public]] =!= {}, public,
    DownValues[Evaluate[private]] =!= {}, private,
    True, $Failed
  ]
];

epsFormStripLoadCanonica[] := Module[{findD},
  findD = epsFormStripCanonicaSymbol["FindD"];
  If[findD === $Failed,
    If[! FileExistsQ[$epsFormStripCanonicaFile], Return[False]];
    Quiet[Get[$epsFormStripCanonicaFile]];
    findD = epsFormStripCanonicaSymbol["FindD"]
  ];
  If[findD === $Failed, Return[False]];
  CANONICA`$ComputeParallel = False;
  CANONICA`Private`$ComputeParallel = False;
  True
];

epsFormStripZeroQ[expr_] :=
  AllTrue[Flatten[{expr}], TrueQ[Together[#] === 0] &];

epsFormStripShapeQ[{e_List, c_List, bbar_List}] := Module[
  {de, dc, db, ni, nj},
  If[Length[e] =!= 2 || Length[c] =!= 2 || Length[bbar] =!= 2,
    Return[False]];
  de = Dimensions /@ e;
  dc = Dimensions /@ c;
  db = Dimensions /@ bbar;
  If[! SameQ @@ de || ! SameQ @@ dc || ! SameQ @@ db,
    Return[False]];
  If[Length[de[[1]]] =!= 2 || Length[dc[[1]]] =!= 2 ||
     Length[db[[1]]] =!= 2, Return[False]];
  ni = de[[1, 1]];
  nj = dc[[1, 1]];
  de[[1]] === {ni, ni} && dc[[1]] === {nj, nj} &&
    db[[1]] === {ni, nj}
];

epsFormStripAlphabet[{e_, c_, bbar_}, variables_List, epsilon_Symbol] :=
 Module[{extract, converted, irreducibles},
  If[! epsFormStripLoadCanonica[], Return[$Failed]];
  extract = epsFormStripCanonicaSymbol["ExtractIrreducibles"];
  If[extract === $Failed, Return[$Failed]];
  converted = {e, c, bbar} /. epsilon -> CANONICA`eps;
  irreducibles = extract[
    converted, CANONICA`AllowEpsDependence -> True];
  Union[variables, Select[irreducibles, FreeQ[#, CANONICA`eps] &]]
];

epsFormStripExactDLogQ[
    gauge_List, {e_, c_, bbar_}, variables_List, epsilon_Symbol,
    alphabet_List] := Module[{check, ec, cc, bc, dc, transformed},
  If[! epsFormStripLoadCanonica[], Return[False]];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  If[check === $Failed, Return[False]];
  {ec, cc, bc, dc} = ({e, c, bbar, gauge} /.
    epsilon -> CANONICA`eps);
  transformed = Table[
    Map[Together,
      bc[[mu]] + CANONICA`eps (ec[[mu]].dc - dc.cc[[mu]]) -
        D[dc, variables[[mu]]],
      {2}],
    {mu, Length[variables]}];
  TrueQ[check[transformed, variables, alphabet]]
];

epsFormStripBuildResidueCompatibility[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol] :=
 Module[
  {extract, rationalZeroCoefficients, dimensions, alphabet, residueTag,
   rawResidueMatrices, residueVariables, dlog, forcing, compatibility,
   equations, solutions, residueRules, residueMatrices, freeResidues,
   solvedForcing, solvedCompatibility, compatibilitySeconds,
   equationSeconds, solveSeconds},

  If[! epsFormStripShapeQ[strip], Return[$Failed]];
  If[! epsFormStripLoadCanonica[], Return[$Failed]];
  extract = epsFormStripCanonicaSymbol["ExtractIrreducibles"];
  rationalZeroCoefficients =
    epsFormStripCanonicaSymbol["RatFunctionZeroCoeffs"];
  If[MemberQ[{extract, rationalZeroCoefficients}, $Failed],
    Return[$Failed]];

  dimensions = Dimensions[bbar[[1]]];
  alphabet = epsFormStripAlphabet[strip, variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];

  residueTag = StringReplace[SymbolName[Unique["r"]], "$" -> "u"];
  rawResidueMatrices = Table[
    Table[
      Symbol["Global`k" <> residueTag <> "a" <> ToString[a] <>
        "i" <> ToString[i] <> "j" <> ToString[j]],
      {i, dimensions[[1]]}, {j, dimensions[[2]]}],
    {a, Length[alphabet]}];
  residueVariables = Flatten[rawResidueMatrices];
  dlog = Table[
    Together[D[Log[alphabet[[a]]], variables[[mu]]]],
    {a, Length[alphabet]}, {mu, 2}];
  forcing = Table[
    bbar[[mu]] - epsilon Sum[
      rawResidueMatrices[[a]] dlog[[a, mu]],
      {a, Length[alphabet]}],
    {mu, 2}];

  {compatibilitySeconds, compatibility} = AbsoluteTiming[
    Together[
      D[forcing[[2]], variables[[1]]] -
        epsilon (e[[1]].forcing[[2]] - forcing[[2]].c[[1]]) -
      D[forcing[[1]], variables[[2]]] +
        epsilon (e[[2]].forcing[[1]] - forcing[[1]].c[[2]])]];
  {equationSeconds, equations} = AbsoluteTiming[
    DeleteCases[
      DeleteDuplicates@Flatten[
        rationalZeroCoefficients[#, variables] & /@
          Flatten[compatibility]],
      0]];
  {solveSeconds, solutions} = AbsoluteTiming[
    Quiet[Solve[Thread[equations == 0], residueVariables]]];
  If[solutions === {}, Return[$Failed]];

  residueRules = FixedPoint[
    Function[rules,
      Thread[First /@ rules -> Together[(Last /@ rules) /. rules]]],
    First[solutions],
    50];
  residueMatrices = rawResidueMatrices /. residueRules;
  freeResidues = Select[residueVariables, ! FreeQ[residueMatrices, #] &];
  solvedForcing = Map[Together, forcing /. residueRules, {3}];
  solvedCompatibility = Map[Together, compatibility /. residueRules, {2}];
  If[! epsFormStripZeroQ[solvedCompatibility], Return[$Failed]];

  <|
    "Alphabet" -> alphabet,
    "ResidueMatrices" -> residueMatrices,
    "ResidueVariables" -> residueVariables,
    "ResidueRules" -> residueRules,
    "FreeResidues" -> freeResidues,
    "DLog" -> dlog,
    "Forcing" -> solvedForcing,
    "EquationCount" -> Length[equations],
    "CompatibilityZero" -> True,
    "CompatibilitySeconds" -> compatibilitySeconds,
    "EquationSeconds" -> equationSeconds,
    "SolveSeconds" -> solveSeconds
  |>
];

Options[SolveResidueRationalGauge] = {
  "MapleExecutable" -> "maple",
  "MapleLibrary" -> Automatic,
  "ScratchDirectory" -> Automatic,
  "Tag" -> "residue_strip",
  "TimeLimit" -> 1800,
  "Verbose" -> False
};

SolveResidueRationalGauge[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol,
    OptionsPattern[]] :=
 Module[
  {mapleExecutable, mapleLibrary, scratchDirectory, tag, timeLimit,
   verbose, residueData, freeResidues, forcing, shape, dimension,
   connection, externalIndices, mapleUnknownHead, mapleUnknowns,
   forcingUnknown, source, toMaple, normalizeRegulator,
   rationalZeroCoefficients, firstVariableIndex, mapleFile, outputFile,
   mapleText, process, elapsed, raw, lines, solutionText, residueText,
   indexedConstantIndices, indexedConstantSymbols, indexedConstantRules,
   parseMaple, gaugeVectorParametric, residueValuesParametric,
   gaugeParametric, residueRulesParametric, forcingParametric,
   odeResidualParametric, parameterVariables, parameterEquations,
   parameterSolutions, parameterRules, remainingParameters, gauge,
   residueValues, residueRules, solvedForcing, residueMatrices, dlog,
   odeResidual, transformedResidual, result = $Failed, log},

  If[! epsFormStripShapeQ[strip],
    Message[SolveResidueRationalGauge::shape]; Return[$Failed]];
  mapleExecutable = OptionValue["MapleExecutable"];
  mapleLibrary = Replace[OptionValue["MapleLibrary"],
    Automatic -> $epsFormStripMapleLibrary];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  timeLimit = OptionValue["TimeLimit"];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[items___] := If[verbose, Print[items]];
  If[! DirectoryQ[scratchDirectory],
    CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];

  residueData = epsFormStripBuildResidueCompatibility[
    strip, variables, epsilon];
  If[residueData === $Failed,
    Message[SolveResidueRationalGauge::residue]; Return[$Failed]];
  rationalZeroCoefficients =
    epsFormStripCanonicaSymbol["RatFunctionZeroCoeffs"];
  If[rationalZeroCoefficients === $Failed,
    Message[SolveResidueRationalGauge::canonica]; Return[$Failed]];

  freeResidues = residueData["FreeResidues"];
  forcing = residueData["Forcing"];
  shape = Dimensions[bbar[[1]]];
  dimension = Times @@ shape;
  connection = Table[
    epsilon (
      KroneckerProduct[e[[mu]], IdentityMatrix[shape[[2]]]] -
      KroneckerProduct[IdentityMatrix[shape[[1]]],
        Transpose[c[[mu]]]]),
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
        SymbolName[symbol]],
      Infinity, Heads -> True]];
    expr /. Thread[symbols -> epsilon]
  ];

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
    {elapsed, process} = AbsoluteTiming[
      Quiet[TimeConstrained[
        RunProcess[{mapleExecutable, "-q", mapleFile}],
        timeLimit, $TimedOut]]];
    If[process === $TimedOut || ! FileExistsQ[outputFile],
      log["Maple produced no result for first variable ",
        firstVariableIndex]; Continue[]];
    raw = Import[outputFile, "Text"];
    lines = StringSplit[raw, "\n"];
    If[lines === {} || First[lines] =!= "OK" || Length[lines] < 3,
      log["Maple result for first variable ", firstVariableIndex,
        ": ", If[lines === {}, "empty", First[lines]]];
      Continue[]];
    solutionText = lines[[2]];
    residueText = lines[[3]];

    indexedConstantIndices = Union[StringCases[
      solutionText <> residueText,
      "c[" ~~ digits : DigitCharacter .. ~~ "]" :>
        ToExpression[digits]]];
    indexedConstantSymbols =
      Symbol["Global`cc" <> ToString[#]] & /@ indexedConstantIndices;
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
      log["Maple result has the wrong vector length."]; Continue[]];

    gaugeParametric = ArrayReshape[gaugeVectorParametric, shape];
    residueRulesParametric =
      Thread[freeResidues -> residueValuesParametric];
    forcingParametric = Map[Together,
      forcing /. residueRulesParametric, {3}];
    odeResidualParametric = Table[
      Map[Together,
        D[gaugeParametric, variables[[mu]]] -
          epsilon (e[[mu]].gaugeParametric -
            gaugeParametric.c[[mu]]) - forcingParametric[[mu]],
        {2}],
      {mu, 2}];
    parameterVariables = Select[indexedConstantSymbols,
      ! FreeQ[{gaugeParametric, residueValuesParametric}, #] &];
    parameterEquations = DeleteCases[DeleteDuplicates@Flatten[
      rationalZeroCoefficients[#, variables] & /@
        Flatten[odeResidualParametric]], 0];
    parameterSolutions = If[parameterEquations === {}, {{}},
      Quiet[Solve[
        Thread[parameterEquations == 0], parameterVariables]]];
    If[parameterSolutions === {}, Continue[]];
    parameterRules = First[parameterSolutions];
    If[parameterRules =!= {},
      parameterRules = FixedPoint[
        Function[rules,
          Thread[First /@ rules -> Together[(Last /@ rules) /. rules]]],
        parameterRules,
        50]];
    remainingParameters = Select[parameterVariables,
      ! FreeQ[{gaugeParametric, residueValuesParametric} /.
        parameterRules, #] &];
    parameterRules = Join[
      parameterRules, Thread[remainingParameters -> 0]];

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
          solvedForcing[[mu]],
        {2}],
      {mu, 2}];
    transformedResidual = Table[
      Map[Together,
        bbar[[mu]] + epsilon (e[[mu]].gauge - gauge.c[[mu]]) -
          D[gauge, variables[[mu]]] - epsilon Sum[
            residueMatrices[[a]] dlog[[a, mu]],
            {a, Length[residueMatrices]}],
        {2}],
      {mu, 2}];
    If[epsFormStripZeroQ[odeResidual] &&
       epsFormStripZeroQ[transformedResidual],
      result = <|
        "Status" -> "Solved",
        "Method" -> "MapleResidueCompatibility",
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
        "ResiduePreparationSeconds" -> Total[Lookup[residueData,
          {"CompatibilitySeconds", "EquationSeconds", "SolveSeconds"}]],
        "ODEEquationZero" -> True,
        "TransformedDLogZero" -> True
      |>;
      Break[]],
    {firstVariableIndex, 1, 2}];

  If[AssociationQ[result], result,
    Message[SolveResidueRationalGauge::maple]; $Failed]
];

epsFormStripSafeTag[tag_] := StringReplace[
  ToString[tag], RegularExpression["[^A-Za-z0-9_-]"] -> "_"];

epsFormStripRunCanonica[
    strip : {_, _, _}, variables : {_, _}, epsilon_Symbol,
    alphabet_List, degrees_List, denominatorDegree_Integer,
    timeLimit_, kernelCount_Integer] :=
 Module[
  {needed, launched = {}, canonicaFile, converted, rawResults, attempts = {},
   candidates = {}, raw, exact, summary},

  needed = Min[Length[degrees], Max[1, kernelCount]];
  If[Length[Kernels[]] < needed,
    launched = Quiet[LaunchKernels[needed - Length[Kernels[]]]]];
  If[Length[Kernels[]] < needed,
    If[launched =!= {}, Quiet[CloseKernels[launched]]];
    Return[<|
      "Attempts" -> (<|"NumeratorDegree" -> #,
        "DenominatorDegree" -> denominatorDegree,
        "Status" -> "ParallelKernelUnavailable",
        "ParentExactDLog" -> False|> & /@ degrees),
      "Candidates" -> {}|>]];

  canonicaFile = $epsFormStripCanonicaFile;
  With[{file = canonicaFile},
    ParallelEvaluate[
      Block[{$Output = {}}, Quiet[Get[file], General::shdw]];
      CANONICA`$ComputeParallel = False;
      CANONICA`Private`$ComputeParallel = False;
      Off[General::shdw];
    ]];
  converted = strip /. epsilon -> CANONICA`eps;
  rawResults = With[
    {ec = converted[[1]], cc = converted[[2]], bc = converted[[3]],
     vars = variables, letters = alphabet, denDegree = denominatorDegree,
     seconds = timeLimit, originalEpsilon = epsilon},
    ParallelMap[
      Function[degree,
        Module[{findD, checkDlog, elapsed, gauge, transformed, exactQ},
          findD = Which[
            DownValues[CANONICA`FindD] =!= {}, CANONICA`FindD,
            DownValues[CANONICA`Private`FindD] =!= {},
              CANONICA`Private`FindD,
            True, $Failed];
          checkDlog = Which[
            DownValues[CANONICA`CheckDlogForm] =!= {},
              CANONICA`CheckDlogForm,
            DownValues[CANONICA`Private`CheckDlogForm] =!= {},
              CANONICA`Private`CheckDlogForm,
            True, $Failed];
          If[MemberQ[{findD, checkDlog}, $Failed],
            Return[<|"NumeratorDegree" -> degree,
              "DenominatorDegree" -> denDegree,
              "Status" -> "CANONICAFunctionMissing",
              "ExactDLog" -> False|>]];
          {elapsed, gauge} = AbsoluteTiming[Quiet[TimeConstrained[
            findD[ec, cc, bc, letters, vars, {},
              CANONICA`DDeltaNumeratorDegree -> degree,
              CANONICA`DDeltaDenominatorDegree -> denDegree,
              CANONICA`VerbosityLevel -> 0],
            seconds, $TimedOut]]];
          If[gauge === $TimedOut || gauge === False || ! ListQ[gauge],
            Return[<|
              "NumeratorDegree" -> degree,
              "DenominatorDegree" -> denDegree,
              "Seconds" -> elapsed,
              "Status" -> Which[
                gauge === $TimedOut, "TimedOut",
                gauge === False, "NoGauge",
                True, "InvalidResult"],
              "ExactDLog" -> False|>]];
          transformed = Table[
            Map[Together,
              bc[[mu]] + CANONICA`eps (
                ec[[mu]].gauge - gauge.cc[[mu]]) -
                D[gauge, vars[[mu]]],
              {2}],
            {mu, Length[vars]}];
          exactQ = TrueQ[checkDlog[transformed, vars, letters]];
          <|
            "NumeratorDegree" -> degree,
            "DenominatorDegree" -> denDegree,
            "Seconds" -> elapsed,
            "Status" -> If[exactQ, "ExactDLog", "FailedDLogIdentity"],
            "ExactDLog" -> exactQ,
            "Gauge" -> If[exactQ,
              gauge /. CANONICA`eps -> originalEpsilon,
              Missing["Rejected"]]|>
        ]],
      degrees,
      Method -> "FinestGrained",
      DistributedContexts -> None]];
  ParallelEvaluate[On[General::shdw]];
  If[launched =!= {}, Quiet[CloseKernels[launched]]];

  Do[
    If[AssociationQ[raw],
      exact = TrueQ[Lookup[raw, "ExactDLog", False]] &&
        ListQ[Lookup[raw, "Gauge", $Failed]] &&
        epsFormStripExactDLogQ[
          raw["Gauge"], strip, variables, epsilon, alphabet];
      summary = Join[
        KeyDrop[raw, "Gauge"],
        <|"ParentExactDLog" -> exact|>];
      If[exact,
        AppendTo[candidates,
          <|"NumeratorDegree" -> raw["NumeratorDegree"],
            "Gauge" -> raw["Gauge"], "Attempt" -> summary|>]],
      summary = <|
        "NumeratorDegree" -> Missing["Unknown"],
        "DenominatorDegree" -> denominatorDegree,
        "Status" -> "ParallelEvaluationFailed",
        "ParentExactDLog" -> False|>];
    AppendTo[attempts, summary],
    {raw, rawResults}];

  <|"Attempts" -> SortBy[attempts, Lookup[#, "NumeratorDegree", Infinity] &],
    "Candidates" -> SortBy[candidates, #["NumeratorDegree"] &]|>
];

Options[SolveEpsFormStrip] = {
  "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
  "CANONICADenominatorDegree" -> 0,
  "CANONICATimeLimit" -> 120,
  "CANONICAKernels" -> 4,
  "MapleExecutable" -> "maple",
  "MapleLibrary" -> Automatic,
  "MapleTimeLimit" -> 1800,
  "ScratchDirectory" -> Automatic,
  "Tag" -> "strip",
  "Verbose" -> False
};

SolveEpsFormStrip[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol,
    OptionsPattern[]] :=
 Module[
  {degrees, denominatorDegree, canonicaTime, canonicaKernels,
   mapleExecutable, mapleLibrary, mapleTime, scratchDirectory,
   tag, verbose, alphabet, converted, irreducibles,
   check, alreadyDLog, canonica, selected, maple, result},

  If[! epsFormStripShapeQ[strip],
    Message[SolveEpsFormStrip::shape]; Return[$Failed]];
  degrees = DeleteDuplicates[OptionValue["CANONICANumeratorDegrees"]];
  If[degrees === {} || ! AllTrue[degrees, IntegerQ[#] && # >= 0 &],
    Message[SolveEpsFormStrip::degrees]; Return[$Failed]];
  denominatorDegree = OptionValue["CANONICADenominatorDegree"];
  canonicaTime = OptionValue["CANONICATimeLimit"];
  canonicaKernels = OptionValue["CANONICAKernels"];
  mapleExecutable = OptionValue["MapleExecutable"];
  mapleLibrary = OptionValue["MapleLibrary"];
  mapleTime = OptionValue["MapleTimeLimit"];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! DirectoryQ[scratchDirectory],
    CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];
  If[! epsFormStripLoadCanonica[],
    Message[SolveEpsFormStrip::canonica, $epsFormStripCanonicaFile];
    Return[$Failed]];

  alphabet = epsFormStripAlphabet[strip, variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];
  converted = strip /. epsilon -> CANONICA`eps;
  irreducibles = epsFormStripCanonicaSymbol["ExtractIrreducibles"][
    converted, CANONICA`AllowEpsDependence -> True];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  alreadyDLog = FreeQ[irreducibles, CANONICA`eps] &&
    (epsFormStripZeroQ[converted[[3]]] ||
      TrueQ[check[converted[[3]], variables, alphabet]]);
  If[alreadyDLog,
    Return[<|
      "Status" -> "Solved",
      "Method" -> "AlreadyDLog",
      "Gauge" -> ConstantArray[0, Dimensions[bbar[[1]]]],
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> {}
    |>]];

  If[verbose,
    Print["CANONICA strip search: numerator degrees ", degrees,
      ", ", canonicaTime, " s each"]];
  canonica = epsFormStripRunCanonica[
    strip, variables, epsilon, alphabet, degrees, denominatorDegree,
    canonicaTime, canonicaKernels];
  If[canonica["Candidates"] =!= {},
    selected = First[canonica["Candidates"]];
    result = <|
      "Status" -> "Solved",
      "Method" -> "CANONICA",
      "Gauge" -> selected["Gauge"],
      "NumeratorDegree" -> selected["NumeratorDegree"],
      "DenominatorDegree" -> denominatorDegree,
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> canonica["Attempts"]
    |>;
    Return[result]];

  If[verbose, Print["CANONICA found no exact dlog gauge; invoking Maple"]];
  maple = SolveResidueRationalGauge[
    strip, variables, epsilon,
    "MapleExecutable" -> mapleExecutable,
    "MapleLibrary" -> mapleLibrary,
    "ScratchDirectory" -> scratchDirectory,
    "Tag" -> tag,
    "TimeLimit" -> mapleTime,
    "Verbose" -> verbose];
  If[AssociationQ[maple],
    Return[Join[maple,
      <|"CANONICAAttempts" -> canonica["Attempts"]|>]]];

  Message[SolveEpsFormStrip::failed];
  $Failed
];
