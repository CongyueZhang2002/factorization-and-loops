#!/usr/bin/env wolframscript

(* Exact physical six-master CF303 system on the soft stratum.  A lexical
   prepass extracts only rows 1--6 before the Wolfram kernel reads Av/Aw. *)

$AllowInternet = False;
$HistoryLength = 0;
$RecursionLimit = Infinity;

repository = ExpandFileName[FileNameJoin[
  {DirectoryName[$InputFileName], "..", "..", ".."}]];
sourceFile = FileNameJoin[{repository, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "DifferentialEquations", "nnlo_de_CF303.wl"}];
extractor = FileNameJoin[{repository, "Scripts", "Transport", "Utilities",
  "extract_wl_matrix_slice.py"}];
outputFile = FileNameJoin[{repository, "Scripts", "Transport", "CF303",
  "Artifacts", "CF303PhysicalSoftSixSystem.wl"}];
sliceFile = FileNameJoin[{$TemporaryDirectory,
  "cf303_physical_soft_six_slice_" <> ToString[$ProcessID] <> ".wl"}];
rows = Range[6];
columns = Range[45];

extractCommand = Join[{"python3", extractor, sourceFile, sliceFile,
    "--key", "Av", "--key", "Aw", "--rows"},
  ToString /@ rows, {"--columns"}, ToString /@ columns];
{extractSeconds, extraction} = AbsoluteTiming[RunProcess[extractCommand]];
If[extraction["ExitCode"] =!= 0,
  Print["REFUSED lexical extraction failed: ", extraction["StandardError"]];
  Exit[2]];
sliceBytes = FileByteCount[sliceFile];
{loadSeconds, slice} = AbsoluteTiming[Get[sliceFile]];
DeleteFile[sliceFile];
If[slice["Rows"] =!= rows || slice["Columns"] =!= columns ||
    Dimensions[slice["Matrices", "Av"]] =!= {6, 45} ||
    Dimensions[slice["Matrices", "Aw"]] =!= {6, 45},
  Print["REFUSED physical six-master slice has the wrong layout"];
  Exit[3]];

av = slice["Matrices", "Av"];
aw = slice["Matrices", "Aw"];
Clear[p, rho, eps, v, w];
uPath = 2 p - rho;
aPath = Together[(4 p (1 - p) - 2 uPath)/
  (uPath^2 + 4 p (1 - p))];
vPath = Together[-aPath p];
wPath = Together[(1 - aPath) (1 - p)];
vParallel = Together[D[vPath, p]];
wParallel = Together[D[wPath, p]];
vNormal = Together[D[vPath, rho]];
wNormal = Together[D[wPath, rho]];

lowestPower[polynomial_] := Module[{rules},
  If[TrueQ[polynomial === 0], Return[Infinity]];
  rules = CoefficientRules[polynomial, rho];
  If[rules === {}, 0, Min[First /@ First /@ rules]]
];
localData[expression_] := Module[
  {rat, numerator, denominator, valuation, principal},
  rat = Cancel[Together[expression]];
  If[TrueQ[rat === 0], Return[<|"Valuation" -> Infinity,
      "Principal" -> <||>, "Finite" -> 0|>]];
  numerator = Numerator[rat];
  denominator = Denominator[rat];
  valuation = lowestPower[numerator] - lowestPower[denominator];
  principal = If[valuation < 0, Association[Table[
      power -> Cancel[Together[
        SeriesCoefficient[rat, {rho, 0, power}]]],
      {power, valuation, -1}]], <||>];
  <|"Valuation" -> valuation, "Principal" -> principal,
    "Finite" -> Cancel[Together[
      SeriesCoefficient[rat, {rho, 0, 0}]]]|>
];

parallelExpressions =
  (vParallel av + wParallel aw) /. {v -> vPath, w -> wPath};
normalExpressions =
  (vNormal av + wNormal aw) /. {v -> vPath, w -> wPath};
timedLocal[expression_] := TimeConstrained[localData[expression], 30,
  <|"Status" -> "TimedOut"|>];

{parallelSeconds, parallelDeck} = AbsoluteTiming[
  Map[timedLocal, parallelExpressions, {2}]];
{normalSeconds, normalDeck} = AbsoluteTiming[
  Map[timedLocal, normalExpressions, {2}]];
parallelFailures = Position[parallelDeck,
  _Association?(KeyExistsQ[#, "Status"] &), {2}, Heads -> False];
normalFailures = Position[normalDeck,
  _Association?(KeyExistsQ[#, "Status"] &), {2}, Heads -> False];
If[parallelFailures =!= {} || normalFailures =!= {},
  Print["INCOMPLETE exact local extraction parallel=",
    InputForm[parallelFailures], " normal=", InputForm[normalFailures]];
  Exit[4]];

(* Exact scalar Jacobian identity validates the fixed-rho pullback for every
   matrix entry, including inherited entries with second/third-order poles. *)
sPath = Together[1 - vPath - wPath];
coordinateDifferences = Map[Cancel[Together[#]] &, {
  vParallel - ((2 p - sPath) - p D[sPath, p]),
  wParallel - ((sPath - 2 p) - (1 - p) D[sPath, p]),
  vNormal - (-p D[sPath, rho]),
  wNormal - (-(1 - p) D[sPath, rho])}];
coordinateAgreement = TrueQ[coordinateDifferences === {0, 0, 0, 0}];
If[! coordinateAgreement,
  Print["REFUSED exact (p,s) and (p,rho) Jacobians disagree"];
  Exit[5]];
normalScale = Cancel[Together[
  SeriesCoefficient[sPath, {rho, 0, 1}]]];

records[deck_, selectedColumns_] := Flatten[Table[
  If[deck[[row, column, "Valuation"]] === Infinity, Nothing,
    <|"Row" -> row, "Column" -> selectedColumns[[column]],
      "Valuation" -> deck[[row, column, "Valuation"]],
      "Principal" -> deck[[row, column, "Principal"]],
      "Finite" -> deck[[row, column, "Finite"]]|>],
  {row, 6}, {column, Length[selectedColumns]}]];
summary[deck_, selectedColumns_] := Module[{part},
  part = deck[[All, selectedColumns]];
  <|"ValuationCounts" -> Counts[Flatten[
      part[[All, All, "Valuation"]]]],
    "FiniteNonzeroCount" -> Count[Flatten[
      part[[All, All, "Finite"]]], Except[0]],
    "MaximumPoleOrder" -> Max[0, -Min[Cases[Flatten[
      part[[All, All, "Valuation"]]], _Integer]]]|>
];

homogeneousColumns = Range[6];
inheritedColumns = Range[7, 45];
artifact = <|
  "Status" -> "CF303PhysicalSoftSixSystemExactV1",
  "Basis" -> "PhysicalBlockBasis",
  "PhysicalRows" -> rows,
  "HomogeneousColumns" -> homogeneousColumns,
  "InheritedColumns" -> inheritedColumns,
  "StateCanonicalRowOrder" -> {42, 43, 40, 41, 44, 45},
  "Coordinate" -> <|"Normal" -> rho,
    "Definition" -> "rho=2p-u",
    "Chart" -> {v -> vPath, w -> wPath},
    "SoftLimit" -> {v -> p^2, w -> 1 - p^2},
    "NormalScale" -> normalScale,
    "CoordinateJacobianAgreement" -> coordinateAgreement|>,
  "Homogeneous" -> <|
    "Tangential" -> records[parallelDeck[[All, homogeneousColumns]],
      homogeneousColumns],
    "Normal" -> records[normalDeck[[All, homogeneousColumns]],
      homogeneousColumns],
    "TangentialSummary" -> summary[parallelDeck, homogeneousColumns],
    "NormalSummary" -> summary[normalDeck, homogeneousColumns]|>,
  "InheritedForcing" -> <|
    "Tangential" -> records[parallelDeck[[All, inheritedColumns]],
      inheritedColumns],
    "Normal" -> records[normalDeck[[All, inheritedColumns]],
      inheritedColumns],
    "TangentialSummary" -> summary[parallelDeck, inheritedColumns],
    "NormalSummary" -> summary[normalDeck, inheritedColumns],
    "UnscaledFiniteProductJetOrder" ->
      summary[parallelDeck, inheritedColumns]["MaximumPoleOrder"]|>,
  "Interpretation" -> <|
    "HomogeneousNormalFuchsian" ->
      (summary[normalDeck, homogeneousColumns]["MaximumPoleOrder"] <= 1),
    "HomogeneousShearNeededForFuchsianity" ->
      (summary[normalDeck, homogeneousColumns]["MaximumPoleOrder"] > 1),
    "InheritedForcingRequiresLowerSectorLaurentData" ->
      (summary[parallelDeck, inheritedColumns]["MaximumPoleOrder"] > 0)|>,
  "TimingsSeconds" -> <|"LexicalExtraction" -> N[extractSeconds],
    "CompactSliceLoad" -> N[loadSeconds],
    "TangentialLocalDeck" -> N[parallelSeconds],
    "NormalLocalDeck" -> N[normalSeconds]|>,
  "Input" -> <|"Source" -> sourceFile,
    "SourceBytes" -> FileByteCount[sourceFile],
    "CompactSliceBytes" -> sliceBytes|>|>;
Put[artifact, outputFile];
Print["CF303 PHYSICAL SOFT SIX SYSTEM status=", artifact["Status"],
  " homogeneous=", InputForm[<|
    "Tangential" -> artifact["Homogeneous", "TangentialSummary"],
    "Normal" -> artifact["Homogeneous", "NormalSummary"]|>],
  " inherited=", InputForm[<|
    "Tangential" -> artifact["InheritedForcing", "TangentialSummary"],
    "Normal" -> artifact["InheritedForcing", "NormalSummary"]|>],
  " seconds=", N[Total[Values[artifact["TimingsSeconds"]]]],
  " output=", outputFile, " bytes=", FileByteCount[outputFile]];
Exit[0];
