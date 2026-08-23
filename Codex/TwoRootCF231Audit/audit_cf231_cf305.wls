#!/usr/bin/env wolframscript

(* Exact audit of the Kallen-23 adjacent extension CF231/CF305, pair (8,7). *)

$HistoryLength = 0;

root = If[$OperatingSystem === "Windows",
  "\\\\wsl.localhost\\Ubuntu\\home\\maxzhang\\factorization-and-loops",
  "/home/maxzhang/factorization-and-loops"];
auditDirectory = FileNameJoin[{root, "Codex", "TwoRootCF231Audit"}];
checkpointDirectory = If[$OperatingSystem === "Windows",
  "\\\\wsl.localhost\\Ubuntu\\home\\maxzhang\\FACET\\Codex\\General\\LibraTwoRootBlockwise_20260819",
  "/home/maxzhang/FACET/Codex/General/LibraTwoRootBlockwise_20260819"];
mode = If[Length[Rest[$ScriptCommandLine]] >= 1,
  First[Rest[$ScriptCommandLine]], "all"];

If[! MemberQ[{"extract", "residue", "all"}, mode],
  Print["usage: audit_cf231_cf305.wls [extract|residue|all]"];
  Exit[64]
];
If[! DirectoryQ[auditDirectory],
  CreateDirectory[auditDirectory, CreateIntermediateDirectories -> True]];

checkpointFiles = <|
  "CF231" -> FileNameJoin[{checkpointDirectory, "blockwise_local_CF231.wl"}],
  "CF305" -> FileNameJoin[{checkpointDirectory, "blockwise_local_CF305.wl"}]
|>;
If[! AllTrue[Values[checkpointFiles], FileExistsQ],
  Print["retained checkpoint missing: ",
    Select[checkpointFiles, ! FileExistsQ[#] &]];
  Exit[2]
];

ClearAll[Global`y, Global`s, Global`eps, Global`v, Global`w];
auditSymbols = AssociationMap[Symbol["Global`" <> #] &,
  {"y", "s", "eps", "v", "w"}];

normalizeSymbols[expr_] := Module[{symbols, rules},
  symbols = DeleteDuplicates@Cases[expr,
    symbol_Symbol /; KeyExistsQ[auditSymbols, SymbolName[symbol]],
    {0, Infinity}, Heads -> True];
  rules = Thread[symbols -> Lookup[auditSymbols, SymbolName /@ symbols]];
  expr /. rules
];

readExpression[file_String, context_String] := normalizeSymbols@Block[
  {$Context = context, $ContextPath = {context, "System`"}}, Get[file]];

exactZeroQ[expr_] :=
  AllTrue[Flatten[{expr}], TrueQ[Cancel[Together[#]] === 0] &];

matrixNormalize[matrix_List] := Map[Cancel[Together[#]] &, matrix, {2}];

sha256[file_String] := IntegerString[FileHash[file, "SHA256"], 16, 64];

putAtomic[expr_, file_String] := Module[{temporary = file <> ".tmp"},
  Put[expr, temporary];
  RenameFile[temporary, file, OverwriteTarget -> True]
];

extractStrip[family_String, record_Association] := Module[
  {variables, epsilon, ranges, targetRows, sourceRows, ax, ay,
   upper, lower, forcing, upperFlat, lowerFlat, forcingClosed, checks},
  variables = record["Variables"];
  epsilon = record["Regulator"];
  ranges = record["Ranges"];
  targetRows = ranges[[8]];
  sourceRows = ranges[[7]];
  ax = record["SystemX"];
  ay = record["SystemY"];
  upper = {
    matrixNormalize[ax[[targetRows, targetRows]]/epsilon],
    matrixNormalize[ay[[targetRows, targetRows]]/epsilon]};
  lower = {
    matrixNormalize[ax[[sourceRows, sourceRows]]/epsilon],
    matrixNormalize[ay[[sourceRows, sourceRows]]/epsilon]};
  forcing = {
    matrixNormalize[ax[[targetRows, sourceRows]]],
    matrixNormalize[ay[[targetRows, sourceRows]]]};
  upperFlat = exactZeroQ[
    D[upper[[2]], variables[[1]]] - D[upper[[1]], variables[[2]]] +
      epsilon (upper[[1]].upper[[2]] - upper[[2]].upper[[1]])];
  lowerFlat = exactZeroQ[
    D[lower[[2]], variables[[1]]] - D[lower[[1]], variables[[2]]] +
      epsilon (lower[[1]].lower[[2]] - lower[[2]].lower[[1]])];
  forcingClosed = exactZeroQ[
    D[forcing[[2]], variables[[1]]] -
      D[forcing[[1]], variables[[2]]] -
      epsilon (upper[[1]].forcing[[2]] - forcing[[2]].lower[[1]]) +
      epsilon (upper[[2]].forcing[[1]] - forcing[[1]].lower[[2]])];
  checks = <|
    "TwoDirectionsPresent" ->
      And @@ (KeyExistsQ[record, #] & /@ {"SystemX", "SystemY"}),
    "Shape" ->
      Dimensions /@ Join[upper, lower, forcing] ===
        ConstantArray[{4, 4}, 6],
    "DiagonalEpsilonFree" ->
      AllTrue[Flatten[Join[upper, lower]], FreeQ[#, epsilon] &],
    "UpperDiagonalFlat" -> upperFlat,
    "LowerDiagonalFlat" -> lowerFlat,
    "ForcingCompatibility" -> forcingClosed
  |>;
  <|
    "Family" -> family,
    "Pair" -> {8, 7},
    "Chart" -> "Kallen23",
    "Variables" -> variables,
    "Regulator" -> epsilon,
    "FamilyDimension" -> Length[ax],
    "BlockCount" -> Length[ranges],
    "TargetRows" -> targetRows,
    "SourceRows" -> sourceRows,
    "TargetDimension" -> Length[targetRows],
    "SourceDimension" -> Length[sourceRows],
    "E" -> upper,
    "C" -> lower,
    "Bbar" -> forcing,
    "Checks" -> checks,
    "ExactTwoPDERecordComplete" -> And @@ Values[checks],
    "CheckpointFailure" -> Lookup[record, "Failure", Missing["Absent"]],
    "CheckpointSHA256" -> sha256[checkpointFiles[family]],
    "CheckpointFile" -> checkpointFiles[family]
  |>
];

canonicalFactor[factor_] := Module[{polynomial, coefficients},
  polynomial = Expand[factor];
  If[! PolynomialQ[polynomial, Values[auditSymbols]], Return[polynomial]];
  coefficients = Values@CoefficientRules[polynomial, Values[auditSymbols]];
  If[coefficients =!= {} && TrueQ[First[coefficients] < 0],
    -polynomial, polynomial]
];

factorPowers[entry_] := Module[{denominator, factors},
  If[TrueQ[entry === 0], Return[{}]];
  denominator = Denominator[Cancel[Together[entry]]];
  If[TrueQ[denominator === 1], Return[{}]];
  factors = Rest[FactorList[denominator]];
  {canonicalFactor[#[[1]]], #[[2]]} & /@ factors
];

directionDivisors[matrix_List] := Module[{pairs, factors},
  pairs = Flatten[factorPowers /@ Flatten[matrix], 1];
  factors = DeleteDuplicates[pairs[[All, 1]] /. {} -> Sequence[], SameQ];
  SortBy[Table[
    <|"Factor" -> factor,
      "MaxOrder" -> Max[Cases[pairs,
        {candidate_, power_Integer} /; SameQ[candidate, factor] :> power]]|>,
    {factor, factors}], ToString[Lookup[#, "Factor"], InputForm] &]
];

factorClass[factor_, variables_List, epsilon_] := Which[
  FreeQ[factor, Alternatives @@ variables], "EpsilonOnly",
  FreeQ[factor, epsilon], "KinematicEpsilonFree",
  True, "KinematicEpsilonDependent"
];

divisorCensus[pair : {_List, _List}, variables_List, epsilon_] := Module[
  {directions, factors, orderInDirection, rows},
  directions = directionDivisors /@ pair;
  factors = DeleteDuplicates[
    Join @@ (Lookup[#, "Factor"] & /@ directions), SameQ];
  orderInDirection[factor_, direction_] := Replace[
    SelectFirst[direction, SameQ[Lookup[#, "Factor"], factor] &,
      <|"MaxOrder" -> 0|>], association_Association :>
      Lookup[association, "MaxOrder"]];
  rows = Table[With[{orders = orderInDirection[factor, #] & /@ directions},
    <|"Factor" -> factor,
      "Class" -> factorClass[factor, variables, epsilon],
      "OrdersByDirection" -> orders,
      "MaxOrder" -> Max[orders]|>], {factor, factors}];
  <|
    "Divisors" -> SortBy[rows, ToString[Lookup[#, "Factor"], InputForm] &],
    "DivisorCount" -> Length[rows],
    "MaxPoleOrder" -> If[rows === {}, 0, Max[Lookup[rows, "MaxOrder"]]]
  |>
];

totalDegree[polynomial_, variables_List] := Module[{rules},
  If[TrueQ[polynomial === 0], Return[-Infinity]];
  rules = CoefficientRules[Expand[polynomial], variables];
  If[rules === {}, 0, Max[Total /@ Keys[rules]]]
];

entryDegrees[entry_, variables_List] := Module[{rational, numerator, denominator},
  rational = Cancel[Together[entry]];
  If[TrueQ[rational === 0], Return[Nothing]];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  <|
    "NumeratorBidegree" -> (Exponent[numerator, #] & /@ variables),
    "DenominatorBidegree" -> (Exponent[denominator, #] & /@ variables),
    "GrowthBidegree" ->
      ((Exponent[numerator, #] - Exponent[denominator, #]) & /@ variables),
    "NumeratorTotalDegree" -> totalDegree[numerator, variables],
    "DenominatorTotalDegree" -> totalDegree[denominator, variables],
    "TotalGrowth" ->
      totalDegree[numerator, variables] - totalDegree[denominator, variables]
  |>
];

componentMax[rows_List, key_String] := Module[{values = Lookup[rows, key]},
  If[VectorQ[First[values]], Max /@ Transpose[values], Max[values]]
];

directionDegrees[matrix_List, variables_List] := Module[{rows},
  rows = DeleteCases[entryDegrees[#, variables] & /@ Flatten[matrix], Nothing];
  <|
    "NumeratorBidegree" -> componentMax[rows, "NumeratorBidegree"],
    "DenominatorBidegree" -> componentMax[rows, "DenominatorBidegree"],
    "GrowthBidegree" -> componentMax[rows, "GrowthBidegree"],
    "NumeratorTotalDegree" -> componentMax[rows, "NumeratorTotalDegree"],
    "DenominatorTotalDegree" -> componentMax[rows, "DenominatorTotalDegree"],
    "TotalGrowth" -> componentMax[rows, "TotalGrowth"]
  |>
];

infinityCensus[pair : {_List, _List}, variables_List] := Module[
  {directions, ownGrowth, ownPoleOrder},
  directions = directionDegrees[#, variables] & /@ pair;
  ownGrowth = Table[directions[[mu, "GrowthBidegree", mu]], {mu, 2}];
  ownPoleOrder = Max[0, # + 2] & /@ ownGrowth;
  <|
    "ByDirection" -> directions,
    "OwnAxisGrowth" -> ownGrowth,
    "OwnAxisOneFormPoleOrderAtInfinity" -> ownPoleOrder,
    "OwnAxisFuchsianAtInfinity" -> (# <= 1 & /@ ownPoleOrder)
  |>
];

summarizeStrip[strip_Association] := Module[{variables, epsilon},
  variables = strip["Variables"];
  epsilon = strip["Regulator"];
  <|
    "Family" -> strip["Family"],
    "FamilyDimension" -> strip["FamilyDimension"],
    "BlockCount" -> strip["BlockCount"],
    "Pair" -> strip["Pair"],
    "TargetDimension" -> strip["TargetDimension"],
    "SourceDimension" -> strip["SourceDimension"],
    "Variables" -> variables,
    "Chart" -> strip["Chart"],
    "E" -> <|"Divisors" -> divisorCensus[strip["E"], variables, epsilon],
      "Infinity" -> infinityCensus[strip["E"], variables]|>,
    "C" -> <|"Divisors" -> divisorCensus[strip["C"], variables, epsilon],
      "Infinity" -> infinityCensus[strip["C"], variables]|>,
    "Bbar" -> <|"Divisors" -> divisorCensus[strip["Bbar"], variables, epsilon],
      "Infinity" -> infinityCensus[strip["Bbar"], variables]|>,
    "Checks" -> strip["Checks"],
    "ExactTwoPDERecordComplete" -> strip["ExactTwoPDERecordComplete"],
    "CheckpointSHA256" -> strip["CheckpointSHA256"]
  |>
];

matrixPairIdentityQ[left_, right_] := And @@ MapThread[
  If[SameQ[#1, #2], True, exactZeroQ[#1 - #2]] &,
  {Join @@ left, Join @@ right}];

(* The family relation is checked directly from the propagators in the Kira
   family file.  Momentum vectors use the order {ka,kb,kc,ke,kf}. *)
p1 = Symbol["Global`ffecfp1"];
p2 = Symbol["Global`ffecfp2"];
p3 = Symbol["Global`ffecfp3"];
kae = Symbol["Global`kae"]; kaf = Symbol["Global`kaf"];
kbe = Symbol["Global`kbe"]; kbf = Symbol["Global`kbf"];
kce = Symbol["Global`kce"]; kcf = Symbol["Global`kcf"];
kee = Symbol["Global`kee"]; kef = Symbol["Global`kef"];
kff = Symbol["Global`kff"];
gram = {
  {0, p1/2, p2/2, kae, kaf},
  {p1/2, 0, p3/2, kbe, kbf},
  {p2/2, p3/2, 0, kce, kcf},
  {kae, kbe, kce, kee, kef},
  {kaf, kbf, kcf, kef, kff}
};
ka = {1, 0, 0, 0, 0}; kb = {0, 1, 0, 0, 0};
kc = {0, 0, 1, 0, 0}; ke = {0, 0, 0, 1, 0};
kf = {0, 0, 0, 0, 1};
square[momentum_] := Expand[momentum . gram . momentum];
bilinear[left_, right_] := Expand[left . gram . right];
swapLoops[momentum_List] := momentum[[{1, 2, 3, 5, 4}]];

momenta231 = {kf, ke, -ka + ke, -kc - kf, ka - kc - ke,
  -kc - ke - kf, ka - kc - ke - kf,
  ka + kb - kc - ke - kf};
momenta305 = {kf, ke, -ka + kf, -ka + kc + kf, -kc - ke,
  -ka - kb + kc + kf, -kc - ke - kf,
  ka - kc - ke - kf, ka + kb - kc - ke - kf};
denominators231 = square /@ momenta231;
denominators305 = square /@ momenta305;
isp231 = bilinear[kb, ke];
denominatorImage = {2, 1, 3, 5, 4, 7, 8, 9};
denominatorIdentity = exactZeroQ[
  (square /@ (swapLoops /@ momenta231)) -
    denominators305[[denominatorImage]]];
ispIdentity = exactZeroQ[
  2 bilinear[kb, swapLoops[ke]] -
    (denominators305[[4]] - denominators305[[6]] + p1 - p3)];

mapExponents231To305[indices_List] :=
  {indices[[2]], indices[[1]], indices[[3]], indices[[5]], indices[[4]],
   0, indices[[6]], indices[[7]], indices[[8]]};

familyDefinitionFile = FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal",
  "Kira", "UU_08_10_canonical", "kira", "config",
  "integralfamilies.yaml"}];
deFiles = AssociationMap[
  FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations",
    "nnlo_de_" <> # <> ".wl"}] &, {"CF231", "CF305"}];
de231 = readExpression[deFiles["CF231"], "AuditDE231`"];
de305 = readExpression[deFiles["CF305"], "AuditDE305`"];
basis231 = Last /@ de231["BlockBasis"];
basis305 = Last /@ de305["BlockBasis"];
mappedBasis231 = mapExponents231To305 /@ basis231;
masterPositions = Replace[
  FirstPosition[basis305, #, Missing["NotFound"]] & /@ mappedBasis231,
  {position : {_Integer} :> First[position]}, {1}];
masterEmbeddingComplete = FreeQ[masterPositions, _Missing] &&
  AllTrue[basis231, Last[#] === 0 &];

If[masterEmbeddingComplete,
  complement305 = Complement[Range[Length[basis305]], masterPositions];
  deIdentity = {
    exactZeroQ[de231["Av"] - de305["Av"][[masterPositions, masterPositions]]],
    exactZeroQ[de231["Aw"] - de305["Aw"][[masterPositions, masterPositions]]]};
  deClosure = {
    exactZeroQ[de305["Av"][[masterPositions, complement305]]],
    exactZeroQ[de305["Aw"][[masterPositions, complement305]]]};,
  complement305 = {};
  deIdentity = {False, False};
  deClosure = {False, False};
];

familyMap = <|
  "LoopMomentumMap" -> "ke <-> kf",
  "CF231QuadraticDenominatorImageInCF305" -> denominatorImage,
  "QuadraticDenominatorIdentity" -> denominatorIdentity,
  "CutIndexImage" -> ({1, 2, 8} -> {2, 1, 9}),
  "CutDirectionsPreserved" -> True,
  "CF305OmittedQuadraticIndex" -> 6,
  "CF231ISPAfterLoopSwap" ->
    "2 (kb.kf) = D4_CF305 - D6_CF305 + ffecfp1 - ffecfp3",
  "ISPIdentity" -> ispIdentity,
  "PoweredMasterCondition" -> HoldForm[a9 == 0],
  "PoweredMasterIndexMap" ->
    HoldForm[{a1,a2,a3,a4,a5,a6,a7,a8,0} ->
      {a2,a1,a3,a5,a4,0,a6,a7,a8}],
  "CF231MasterCount" -> Length[basis231],
  "CF305MasterCount" -> Length[basis305],
  "AllRetainedCF231MastersMeetCondition" ->
    AllTrue[basis231, Last[#] === 0 &],
  "MasterEmbeddingComplete" -> masterEmbeddingComplete,
  "CF305MasterPositionsInCF231Order" -> masterPositions,
  "DifferentialEquationIdentityVW" -> deIdentity,
  "CF305SubsystemClosedVW" -> deClosure,
  "ExactSubsystemTransformation" ->
    If[masterEmbeddingComplete && And @@ Join[deIdentity, deClosure],
      "Permutation induced by the displayed powered-master index map",
      Missing["NotEstablished"]],
  "RelationType" ->
    "Exact denominator-set embedding and powered-master equivalence for a9=0; not denominator-set equality for arbitrary powers of the CF231 ISP"
|>;

records = AssociationMap[
  readExpression[checkpointFiles[#], "AuditCheckpoint" <> # <> "`"] &,
  Keys[checkpointFiles]];
strips = AssociationMap[extractStrip[#, records[#]] &, Keys[records]];

Scan[Function[family,
  putAtomic[strips[family], FileNameJoin[{auditDirectory,
    family <> "_8_7_exact_strip.wl"}]]], Keys[strips]];

summaries = AssociationMap[summarizeStrip[strips[#]] &, Keys[strips]];
stripIdentity = And[
  matrixPairIdentityQ[strips["CF231"]["E"], strips["CF305"]["E"]],
  matrixPairIdentityQ[strips["CF231"]["C"], strips["CF305"]["C"]],
  matrixPairIdentityQ[strips["CF231"]["Bbar"], strips["CF305"]["Bbar"]]
];

baseAudit = <|
  "Subject" -> "Kallen23 adjacent hard strip",
  "Pair" -> {8, 7},
  "Representatives" -> summaries,
  "CF231CF305StripIdentity" -> stripIdentity,
  "FamilyMap" -> familyMap,
  "ResidueCompatibility" -> Missing["NotRun"],
  "AcceptanceCriterion" ->
    "Both diagonal flatness identities and the off-diagonal compatibility identity vanish exactly in both chart variables",
  "AcceptanceCriterionSatisfied" ->
    And @@ Lookup[Values[summaries], "ExactTwoPDERecordComplete"],
  "PackageFilesRead" -> {
    FileNameJoin[{root, "FeynFacet", "Private", "EpsFormStrip.wl"}],
    FileNameJoin[{root, "FeynFacet", "Private", "TransportCharts.wl"}]},
  "ResultFilesRead" -> Values[deFiles],
  "FamilyDefinitionFileRead" -> familyDefinitionFile,
  "FamilyDefinitionSHA256" -> sha256[familyDefinitionFile],
  "CheckpointFilesRead" -> Values[checkpointFiles]
|>;

auditFile = FileNameJoin[{auditDirectory, "CF231_CF305_exact_audit.wl"}];
putAtomic[baseAudit, auditFile];
Print[InputForm@KeyTake[baseAudit,
  {"Subject", "Pair", "CF231CF305StripIdentity",
   "AcceptanceCriterionSatisfied"}]];

If[mode === "extract", Exit[0]];

(* The retained solver's compatibility construction is exact, but its final
   alphabet intentionally drops epsilon-dependent divisors.  The audit keeps
   that convention visible and separately records every divisor above. *)
FeynFacet`Private`$feynFacetRoot = root;
Block[{$Context = "FeynFacet`Private`",
   $ContextPath = {"FeynFacet`Private`", "FeynFacet`", "System`"}},
  Get[FileNameJoin[{root, "FeynFacet", "Private", "EpsFormStrip.wl"}]]];
residueBuilder =
  Symbol["FeynFacet`Private`epsFormStripBuildResidueCompatibility"];
alphabetBuilder = Symbol["FeynFacet`Private`epsFormStripAlphabet"];

residueInput = {strips["CF231"]["E"], strips["CF231"]["C"],
  strips["CF231"]["Bbar"]};
residueAlphabet = alphabetBuilder[residueInput,
  strips["CF231"]["Variables"], strips["CF231"]["Regulator"]];
rawResidueVariableCount = Length[residueAlphabet] Times @@
  Dimensions[First[strips["CF231"]["Bbar"]]];
{residueSeconds, residueData} = AbsoluteTiming[
  TimeConstrained[
    residueBuilder[residueInput, strips["CF231"]["Variables"],
      strips["CF231"]["Regulator"], 1],
    1200, $TimedOut]];

residueSummary = Which[
  residueData === $TimedOut,
    <|"Status" -> "TimedOut", "Seconds" -> residueSeconds,
      "Alphabet" -> residueAlphabet,
      "AlphabetCount" -> Length[residueAlphabet],
      "RawResidueVariableCount" -> rawResidueVariableCount,
      "FreeResidueParameterCount" -> Missing["NotAvailable", "TimedOut"]|>,
  ! AssociationQ[residueData],
    <|"Status" -> "Failed", "Seconds" -> residueSeconds,
      "Alphabet" -> residueAlphabet,
      "AlphabetCount" -> Length[residueAlphabet],
      "RawResidueVariableCount" -> rawResidueVariableCount,
      "FreeResidueParameterCount" -> Missing["NotAvailable", "Failed"],
      "FailureStage" ->
        FeynFacet`Private`$epsFormStripResidueFailureStage|>,
  True,
    <|
      "Status" -> "ExactCompatibilitySolved",
      "ComputedRepresentative" -> "CF231",
      "AppliesToCF305ByExactStripIdentity" -> stripIdentity,
      "Seconds" -> residueSeconds,
      "Alphabet" -> residueData["Alphabet"],
      "AlphabetCount" -> Length[residueData["Alphabet"]],
      "RawResidueVariableCount" -> Length[residueData["ResidueVariables"]],
      "FreeResidueParameterCount" -> Length[residueData["FreeResidues"]],
      "EquationCount" -> residueData["EquationCount"],
      "CompatibilityZero" -> residueData["CompatibilityZero"],
      "ExistingSolverAlphabetDropsEpsilonDependentDivisors" -> True,
      "CompatibleForcingDivisors" -> divisorCensus[
        residueData["Forcing"], strips["CF231"]["Variables"],
        strips["CF231"]["Regulator"]],
      "CompatibleForcingInfinity" -> infinityCensus[
        residueData["Forcing"], strips["CF231"]["Variables"]]
    |>
];

finalAudit = Append[baseAudit, "ResidueCompatibility" -> residueSummary];
putAtomic[finalAudit, auditFile];
putAtomic[residueSummary, FileNameJoin[{auditDirectory,
  "residue_compatibility_summary.wl"}]];
Print[InputForm[residueSummary]];
Exit[If[AssociationQ[residueData] &&
  TrueQ[residueData["CompatibilityZero"]], 0, 1]];
