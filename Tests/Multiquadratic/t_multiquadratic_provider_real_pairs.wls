#!/usr/bin/env wolframscript
(* B3 real-expression provider evidence for the three pairwise CF259 fields.

   The inputs are the actual saved strip records, not reduced symbolic toys:
     CF259 (24,16)  {lambda1, lambda3},
     CF259 (21,11)  {Q4, lambda1},
     CF259 (23,11)  {Q4, lambda3}.

   For every record this suite:
     1. rekeys the artifact into Global`, loads the project-owned CF259 frame,
        and requires the strip census to select exactly the stated two roots
        in the frame's canonical order;
     2. prepares only the provider-independent coefficient/layout ABI, with
        no compiled or globally materialized inhomogeneity channels;
     3. finds one deterministic split point and checks that SplitBranch and
        the independent QuotientGrade evaluator return exactly the same
        complete coefficient payload {E,C,Inhomogeneity,OneForms,...};
     4. finds a deterministic nonsplit point and requires SplitBranch
        preflight to reject it by name before any large entry is evaluated.

   OneForms is deliberately empty and the gauge ansatz is the one-column
   constant placeholder: this is a coefficient-provider promotion test, not
   a claim that these three physical strips solve in that ansatz.  The real
   E, C and Inhomogeneity expressions are nevertheless evaluated in full at the
   accepted point.  Each case is bounded independently. *)

(* These symbols are the project chart ABI.  Clear them before loading the
   package so a reused harness cannot snapshot an earlier test's own-values. *)
Quiet[Clear["Global`v", "Global`w", "Global`x", "Global`y", "Global`s",
  "Global`t", "Global`p", "Global`u", "Global`eps"]];

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", InputForm[value]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, layoutBuilder, layoutValidQ, directProvider, providerValidQ,
  preflight, channels} = mq /@ {"multiquadraticOffDiagonalBlockPrepare",
  "multiquadraticOffDiagonalBlockAssemblyLayout",
  "multiquadraticOffDiagonalBlockAssemblyLayoutValidQ",
  "multiquadraticOffDiagonalBlockDirectProvider",
  "multiquadraticOffDiagonalBlockProviderValidQ",
  "multiquadraticOffDiagonalBlockProviderPreflight",
  "multiquadraticOffDiagonalBlockProviderChannels"};

dataDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "triple_root_2026-08-24_fable", "CF259", "sector_CF259_standard"}];
chartFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "TransportFamilyCharts.wl"}];

cases = {
  <|"Name" -> "CF259 (24,16) lambda1/lambda3",
    "File" -> FileNameJoin[{dataDirectory, "CF259_24_16_input.wl"}],
    "Sector" -> 24, "LowerSector" -> 16, "RootIndices" -> {1, 2}|>,
  <|"Name" -> "CF259 (21,11) Q4/lambda1",
    "File" -> FileNameJoin[{dataDirectory, "CF259_21_11_input.wl"}],
    "Sector" -> 21, "LowerSector" -> 11, "RootIndices" -> {1, 3}|>,
  <|"Name" -> "CF259 (23,11) Q4/lambda3",
    "File" -> FileNameJoin[{dataDirectory, "CF259_23_11_input.wl"}],
    "Sector" -> 23, "LowerSector" -> 11, "RootIndices" -> {2, 3}|>
};

check["the project chart table and all three real strip inputs exist",
  FileExistsQ[chartFile] && AllTrue[Lookup[cases, "File"], FileExistsQ]];
If[! (FileExistsQ[chartFile] &&
    AllTrue[Lookup[cases, "File"], FileExistsQ]),
  report["required files", Prepend[Lookup[cases, "File"], chartFile]];
  Print["t_multiquadratic_provider_real_pairs: ", pass, " OK, ", fail,
    " FAIL"];
  Exit[1]];

registration = FeynFacet`LoadFamilyRootData[chartFile];
check["the project family-chart inventory authenticates",
  Lookup[registration, "Status", None] === "FamilyChartsRegistered"];

prime = 2147483423;
epsilonValue = 5;
caseBudgetSeconds = 180;
coefficientKeys = {"Prime", "Point", "RegulatorValue", "EpsilonMod",
  "QuadraticRadicands", "SquareRootGeneratorValues", "SplitPointQ",
  "OffDiagonalBasisTransformationDenominator",
  "OffDiagonalBasisTransformationDenominatorLogDerivatives", "RootLogDerivatives", "E", "C", "Inhomogeneity",
  "OneForms", "CoefficientData"};
coefficientPayload[value_Association] := KeyTake[value, coefficientKeys];

runCase[case_Association] := Module[
  {record, variables, epsilon, frame, allRoots, expectedIndices,
   expectedRoots, prepared, layout, splitProvider, quotientProvider,
   candidateGrid, squareValues, splitPointQ, nonsplitPointQ,
   splitCandidates, nonsplitPoint, nonsplitPreflight, splitPoint,
   splitImage, quotientImage, attemptedSplitPoints = {}, point,
   frameExactQ, sourceShape, payloadSameQ = False},

  record = FeynFacet`FamilyArtifactRead[case["File"], "Global`"];
  If[! AssociationQ[record],
    Return[<|"Status" -> "InputUnreadable"|>]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  sourceShape = Quiet[Check[Dimensions /@ record["OffDiagonalBlockEquation"], $Failed]];
  If[Lookup[record, "Family", None] =!= "CF259" ||
      Lookup[record, "Sector", None] =!= case["Sector"] ||
      Lookup[record, "LowerSector", None] =!= case["LowerSector"] ||
      ! MatchQ[variables, {_Symbol, _Symbol}] || ! SymbolQ[epsilon] ||
      ! MatchQ[Lookup[record, "OffDiagonalBlockEquation", None], {_List, _List, _List}],
    Return[<|"Status" -> "InputABIInvalid", "Shape" -> sourceShape|>]];

  (* The saved inputs are already written in the registered frame's target
     variables {x,y}.  Keep its authenticated source {v,w} -> target {x,y}
     identity map; rebuilding with {x,y} as BOTH source and target would
     destroy the distinction that BuildSquareRootGeneratorsAndQuadraticRelations certifies. *)
  frame = FeynFacet`FamilyRootData["CF259"];
  allRoots = If[AssociationQ[frame],
    mq["transportChartCurrentRoots"][frame, variables], $Failed];
  expectedIndices = case["RootIndices"];
  If[! (AssociationQ[frame] && frame["Status"] === "ExactFrame" &&
      TrueQ[frame["ChartCertificate", "OK"]] &&
      MatchQ[allRoots, {__Association}] && Length[allRoots] === 3),
    Return[<|"Status" -> "FamilyFrameInvalid"|>]];
  expectedRoots = allRoots[[expectedIndices]];

  prepared = prepare[record, frame, "RootIndices" -> Automatic,
    "OneForms" -> {}, "OffDiagonalBasisTransformationDenominator" -> 1,
    "Support" -> {{0, 0}}, "CoefficientProvider" -> "SplitBranch",
    "CompileCore" -> False];
  If[Lookup[prepared, "Status", None] =!=
      "PreparedMultiquadraticOffDiagonalBlockV1",
    Return[<|"Status" -> "PreparationFailed",
      "DetailStatus" -> Lookup[prepared, "Status", None]|>]];
  frameExactQ = prepared["RootSourceIndices"] === expectedIndices &&
    Length[prepared["Roots"]] === 2 && And @@ MapThread[
      TrueQ[Together[#1["QuadraticRadicand"] -
          #2["QuadraticRadicand"]] === 0] &&
        TrueQ[Together[#1["Generator"] - #2["Generator"]] === 0] &,
      {prepared["Roots"], expectedRoots}];
  If[! frameExactQ,
    Return[<|"Status" -> "PairwiseRootFrameMismatch",
      "ObservedRootIndices" -> prepared["RootSourceIndices"],
      "ExpectedRootIndices" -> expectedIndices|>]];

  layout = layoutBuilder[prepared];
  splitProvider = directProvider[prepared["Record"], prepared["Roots"],
    "Kind" -> "SplitBranch", "OneForms" -> prepared["OneForms"],
    "OffDiagonalBasisTransformationDenominator" ->
      prepared["OffDiagonalBasisTransformationDenominator"]];
  quotientProvider = directProvider[prepared["Record"], prepared["Roots"],
    "Kind" -> "QuotientGrade", "OneForms" -> prepared["OneForms"],
    "OffDiagonalBasisTransformationDenominator" ->
      prepared["OffDiagonalBasisTransformationDenominator"]];
  If[! (TrueQ[layoutValidQ[layout]] &&
      TrueQ[providerValidQ[splitProvider]] &&
      TrueQ[providerValidQ[quotientProvider]]),
    Return[<|"Status" -> "ProviderABIInvalid",
      "SplitStatus" -> Lookup[splitProvider, "Status", None],
      "QuotientStatus" -> Lookup[quotientProvider, "Status", None]|>]];

  squareValues[point_] := Mod[
    Lookup[prepared["Roots"], "QuadraticRadicand", {}] /.
      Thread[variables -> point], prime];
  splitPointQ[point_] := Module[{values = squareValues[point]},
    VectorQ[values, IntegerQ] && FreeQ[values, 0] &&
      AllTrue[values, JacobiSymbol[#1, prime] === 1 &]];
  nonsplitPointQ[point_] := Module[{values = squareValues[point]},
    VectorQ[values, IntegerQ] && FreeQ[values, 0] &&
      AnyTrue[values, JacobiSymbol[#1, prime] === -1 &]];
  candidateGrid = Select[Tuples[Range[2, 48], 2],
    First[#1] =!= Last[#1] &];
  splitCandidates = Select[candidateGrid, splitPointQ, 12];
  nonsplitPoint = SelectFirst[candidateGrid, nonsplitPointQ,
    Missing["NoNonsplitPoint"]];
  If[splitCandidates === {} || MissingQ[nonsplitPoint],
    Return[<|"Status" -> "DeterministicPointSearchFailed",
      "SplitCandidateCount" -> Length[splitCandidates],
      "NonsplitPoint" -> nonsplitPoint|>]];

  nonsplitPreflight = preflight[splitProvider, epsilonValue, prime,
    nonsplitPoint];
  If[Lookup[nonsplitPreflight, "Status", None] =!=
        "PointNotSplitOverPrime" ||
      Lookup[nonsplitPreflight, "LargeEntryEvaluationCount", -1] =!= 0,
    Return[<|"Status" -> "NonsplitPreflightContractFailed",
      "PreflightStatus" -> Lookup[nonsplitPreflight, "Status", None],
      "LargeEntryEvaluationCount" -> Lookup[nonsplitPreflight,
        "LargeEntryEvaluationCount", Missing["NotRecorded"]]|>]];

  splitPoint = Missing["NoUsableSplitPoint"];
  Do[
    AppendTo[attemptedSplitPoints, point];
    splitImage = channels[splitProvider, epsilonValue, prime, point];
    quotientImage = channels[quotientProvider, epsilonValue, prime, point];
    If[Lookup[splitImage, "Status", None] ===
          "MultiquadraticPointCoefficientsV1" &&
        Lookup[quotientImage, "Status", None] ===
          "MultiquadraticPointCoefficientsV1",
      splitPoint = point;
      payloadSameQ = coefficientPayload[splitImage] ===
        coefficientPayload[quotientImage];
      Break[]],
    {point, Take[splitCandidates, UpTo[6]]}];
  If[MissingQ[splitPoint],
    Return[<|"Status" -> "NoUsableRealSplitPoint",
      "AttemptedSplitPoints" -> attemptedSplitPoints,
      "SplitStatus" -> Lookup[splitImage, "Status", None],
      "QuotientStatus" -> Lookup[quotientImage, "Status", None]|>]];

  <|"Status" -> If[payloadSameQ, "RealPairwiseProviderAgreement",
      "RealPairwiseProviderMismatch"],
    "InputShape" -> sourceShape,
    "RootIndices" -> prepared["RootSourceIndices"],
    "RootCount" -> prepared["RootCount"],
    "GradeCount" -> prepared["GradeCount"],
    "LayoutValid" -> True,
    "NoGlobalInhomogeneityChannels" -> MissingQ[prepared["InhomogeneityChannels"]],
    "ProviderKinds" -> Lookup[{splitProvider, quotientProvider}, "Kind"],
    "SplitPoint" -> splitPoint, "NonsplitPoint" -> nonsplitPoint,
    "NonsplitStatus" -> nonsplitPreflight["Status"],
    "NonsplitLargeEntryEvaluationCount" ->
      nonsplitPreflight["LargeEntryEvaluationCount"],
    "CoefficientPayloadEqual" -> payloadSameQ|>
];

Do[
  outcome = TimeConstrained[runCase[case], caseBudgetSeconds,
    <|"Status" -> "CaseBudgetExhausted",
      "BudgetSeconds" -> caseBudgetSeconds|>];
  report[case["Name"], KeyDrop[outcome, {"InputShape"}]];
  check[case["Name"] <> " authenticates exactly its pairwise root frame",
    Lookup[outcome, "RootIndices", None] === case["RootIndices"] &&
      Lookup[outcome, "RootCount", None] === 2 &&
      Lookup[outcome, "GradeCount", None] === 4];
  check[case["Name"] <> " uses direct providers and no global inhomogeneity channels",
    TrueQ[Lookup[outcome, "LayoutValid", False]] &&
      TrueQ[Lookup[outcome, "NoGlobalInhomogeneityChannels", False]] &&
      Lookup[outcome, "ProviderKinds", None] ===
        {"SplitBranch", "QuotientGrade"}];
  check[case["Name"] <> " rejects a nonsplit point before entry evaluation",
    Lookup[outcome, "NonsplitStatus", None] === "PointNotSplitOverPrime" &&
      Lookup[outcome, "NonsplitLargeEntryEvaluationCount", -1] === 0];
  check[case["Name"] <> " SplitBranch equals QuotientGrade on real expressions",
    Lookup[outcome, "Status", None] === "RealPairwiseProviderAgreement" &&
      TrueQ[Lookup[outcome, "CoefficientPayloadEqual", False]]],
  {case, cases}];

Print["t_multiquadratic_provider_real_pairs: ", pass, " OK, ", fail,
  " FAIL"];
Exit[If[fail === 0, 0, 1]];
