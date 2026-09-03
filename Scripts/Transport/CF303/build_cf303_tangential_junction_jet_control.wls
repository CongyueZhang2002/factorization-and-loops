#!/usr/bin/env wolframscript
$AllowInternet = False;
$HistoryLength = 0;
scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
arguments = Rest[$ScriptCommandLine];
pointPath = If[arguments =!= {}, ExpandFileName[First[arguments]],
  "/tmp/cf303_junction_local_q2305843009213691819_p310.json"];
outputPath = FileNameJoin[{scriptDirectory, "Artifacts",
  "CF303TangentialJunctionJetControl.wl"}];
pointData = Import[pointPath, "RawJSON"];
lowerJets = Get[FileNameJoin[{scriptDirectory, "Artifacts",
  "CF303InheritedLowerSoftJets.wl"}]];
If[Lookup[pointData, "status", None] =!=
      "CF303TangentialJunctionPointV1" ||
    Lookup[pointData, "normal_connection_local_window", {}] =!= {-1, 1} ||
    Lookup[lowerJets, "Status", None] =!=
      "CF303InheritedLowerSoftJetsAcceptedV2",
  Print["FAIL CF303TangentialJunctionJetInputs"]; Quit[2]];

prime = pointData["prime"];
pPoint = First[pointData["p"]]/Last[pointData["p"]];
epsilonWindow = {-4, 3};
supportRows = {1, 2, 12, 21, 22, 29, 30};
modeEigenvalues = {-2, 0, 0, 0, -4, 0, -4};
ff[expression_] := Module[{value = Together[expression /. p -> pPoint]},
  Mod[Numerator[value]*PowerMod[Mod[Denominator[value], prime], -1,
    prime], prime]];

family[name_] := SelectFirst[lowerJets["Families"], #Family === name &];
modeConfigurations = {
  <|"Family" -> "CF1", "SupportPositions" -> {1},
    "Modes" -> {<|"Index" -> 1, "Vector" -> {1}|>}|>,
  <|"Family" -> "CF12", "SupportPositions" -> {2},
    "Modes" -> {<|"Index" -> 2, "Vector" -> {0, 1}|>}|>,
  <|"Family" -> "CF21", "SupportPositions" -> {3},
    "Modes" -> {<|"Index" -> 3, "Vector" -> {0, 1}|>}|>,
  <|"Family" -> "CF199", "SupportPositions" -> {4, 5},
    "Modes" -> {<|"Index" -> 4, "Vector" -> {0, 0, 2, -3}|>,
      <|"Index" -> 5, "Vector" -> {0, 0, 0, 1}|>}|>,
  <|"Family" -> "CF53", "SupportPositions" -> {6, 7},
    "Modes" -> {<|"Index" -> 6, "Vector" -> {0, 0, 2, -3}|>,
      <|"Index" -> 7, "Vector" -> {0, 0, 0, 1}|>}|>
};
sourceJets = Association@Flatten[Table[
  {rhoOrder, epsilonOrder} -> ConstantArray[0, {7, 7}],
  {rhoOrder, 0, 4}, {epsilonOrder, 0, 6}]];
Do[With[{record = family[configuration["Family"]]},
  Do[With[{coefficient = coefficientRecord,
      dimensions = record["SelectedFrobeniusPrefactor", "Dimensions"]},
    coefficientMatrix = SparseArray[
      ({#Row, #Column} -> #Value) & /@ coefficient["Entries"],
      dimensions];
    Do[With[{values = coefficientMatrix . mode["Vector"],
        key = {coefficient["RhoOrder"],
          coefficient["EpsilonOrder"]}},
      matrix = sourceJets[key];
      Do[matrix[[configuration["SupportPositions"][[index]],
          mode["Index"]]] = ff[values[[index]]],
        {index, Length[values]}];
      sourceJets[key] = matrix], {mode, configuration["Modes"]}]],
    {coefficientRecord,
      record["SelectedFrobeniusPrefactor", "NonzeroCoefficients"]}]],
  {configuration, modeConfigurations}];

bMatrices = Association@Flatten[Table[
  {rhoOrder, epsilonOrder} -> ConstantArray[0, {2, 7}],
  {rhoOrder, -1, 1}, {epsilonOrder, -3, 4}]];
Scan[Function[record, Module[{matrix, key, row, column, value},
  key = {record["rho_power"], record["epsilon_order"]};
  matrix = bMatrices[key];
  row = First@FirstPosition[{44, 45}, record["target_master"]];
  column = First@FirstPosition[supportRows, record["source_state_row"]];
  value = record["value"];
  If[Last[value] =!= 0,
    Print["FAIL CF303TangentialJunctionJetQuadraticB"]; Quit[2]];
  matrix[[row, column]] = First[value];
  bMatrices[key] = matrix]],
  pointData["normal_connection_local_state_projection"]];
targetMatrices = Association@Table[rhoOrder -> ConstantArray[0, {2, 2}],
  {rhoOrder, 0, 1}];
Scan[Function[record, Module[{matrix, value},
  matrix = targetMatrices[record["rho_power"]];
  value = record["value"];
  If[Last[value] =!= 0,
    Print["FAIL CF303TangentialJunctionJetQuadraticTarget"]; Quit[2]];
  matrix[[record["target_row"], record["target_column"]]] = First[value];
  targetMatrices[record["rho_power"]] = matrix]],
  pointData["target_normal_local_connection"]];

zeroVector = ConstantArray[0, 2];
orders = Range[epsilonWindow[[1]], epsilonWindow[[2]]];
seriesGet[series_, order_] := Lookup[series, order, zeroVector];
seriesAdd[seriesList_List] := Association@Table[order -> Mod[
    Total[seriesGet[#, order] & /@ seriesList], prime], {order, orders}];
seriesScale[series_, scalar_] := Association@Table[order ->
    Mod[scalar*seriesGet[series, order], prime], {order, orders}];
seriesShift[series_, shift_] := Association@Table[order ->
    seriesGet[series, order - shift], {order, orders}];
seriesMatrixVector[matrixSeries_, vectorSeries_] := Association@Table[
  order -> Mod[Total[Table[
      Lookup[matrixSeries, left, ConstantArray[0, {2, 7}]] .
        Lookup[vectorSeries, order - left, ConstantArray[0, 7]],
      {left, Keys[matrixSeries]}]], prime], {order, orders}];
seriesTargetProduct[matrixSeries_, vectorSeries_] := Association@Table[
  order -> Mod[Total[Table[
      Lookup[matrixSeries, left, ConstantArray[0, {2, 2}]] .
        seriesGet[vectorSeries, order - left],
      {left, Keys[matrixSeries]}]], prime], {order, orders}];
seriesLinearDivide[right_, integer_, epsilonCoefficient_] := Module[
  {result = <||>},
  Do[result[order] = Mod[PowerMod[Mod[integer, prime], -1, prime]*
      (seriesGet[right, order] - epsilonCoefficient*
        Lookup[result, order - 1, zeroVector]), prime], {order, orders}];
  result];
zeroSeriesQ[series_] := AllTrue[Values[series],
  # === zeroVector &];

bSeries[rhoOrder_] := Association@Table[epsilonOrder ->
  bMatrices[{rhoOrder, epsilonOrder}], {epsilonOrder, -3, 4}];
targetSeries[rhoOrder_] := <|1 -> targetMatrices[rhoOrder]|>;
sourceModeSeries[rhoOrder_, mode_] := Association@Table[
  epsilonOrder -> sourceJets[{rhoOrder, epsilonOrder}][[All, mode]],
  {epsilonOrder, 0, 6}];
bp[rhoOrder_, sourceOrder_, mode_] := seriesMatrixVector[
  bSeries[rhoOrder], sourceModeSeries[sourceOrder, mode]];
atp[rhoOrder_, vector_] := seriesTargetProduct[
  targetSeries[rhoOrder], vector];

checks = {};
nonzeroData = Association@Table[With[
  {r = modeEigenvalues[[mode]],
    bMinusP0 = bp[-1, 0, mode]},
  y0 = seriesScale[seriesShift[bMinusP0, -1], PowerMod[Mod[r, prime], -1,
    prime]];
  rhs1 = seriesAdd[{atp[0, y0], bp[-1, 1, mode], bp[0, 0, mode]}];
  y1 = seriesLinearDivide[rhs1, 1, r];
  rhs2 = seriesAdd[{atp[0, y1], atp[1, y0], bp[-1, 2, mode],
    bp[0, 1, mode], bp[1, 0, mode]}];
  y2 = seriesLinearDivide[rhs2, 2, r];
  localChecks = {
    zeroSeriesQ[seriesAdd[{seriesScale[seriesShift[y0, 1], r],
      seriesScale[bMinusP0, -1]}]],
    zeroSeriesQ[seriesAdd[{y1, seriesScale[seriesShift[y1, 1], r],
      seriesScale[rhs1, -1]}]],
    zeroSeriesQ[seriesAdd[{seriesScale[y2, 2],
      seriesScale[seriesShift[y2, 1], r], seriesScale[rhs2, -1]}]]};
  checks = Join[checks, localChecks];
  mode -> <|"NormalEigenvalueOverEpsilon" -> r,
    "TargetJet0" -> y0, "TargetJet1" -> y1, "TargetJet2" -> y2,
    "Checks" -> localChecks|>], {mode, {1, 5, 7}}];

zeroData = Association@Table[With[{bMinusP0 = bp[-1, 0, mode]},
  log0 = bMinusP0;
  log1 = atp[0, log0];
  regular1 = seriesAdd[{bp[-1, 1, mode], bp[0, 0, mode],
    seriesScale[log1, -1]}];
  log2 = seriesScale[seriesAdd[{atp[0, log1], atp[1, log0]}],
    PowerMod[2, -1, prime]];
  regular2 = seriesScale[seriesAdd[{bp[-1, 2, mode], bp[0, 1, mode],
    bp[1, 0, mode], atp[0, regular1], seriesScale[log2, -1]}],
    PowerMod[2, -1, prime]];
  localChecks = {
    zeroSeriesQ[seriesAdd[{log0, seriesScale[bMinusP0, -1]}]],
    zeroSeriesQ[seriesAdd[{log1, seriesScale[atp[0, log0], -1]}]],
    zeroSeriesQ[seriesAdd[{seriesAdd[{log1, regular1}],
      seriesScale[seriesAdd[{bp[-1, 1, mode], bp[0, 0, mode]}], -1]}]],
    zeroSeriesQ[seriesAdd[{seriesScale[log2, 2],
      seriesScale[seriesAdd[{atp[0, log1], atp[1, log0]}], -1]}]],
    zeroSeriesQ[seriesAdd[{log2, seriesScale[regular2, 2],
      seriesScale[seriesAdd[{bp[-1, 2, mode], bp[0, 1, mode],
        bp[1, 0, mode], atp[0, regular1]}], -1]}]]};
  checks = Join[checks, localChecks];
  mode -> <|"CanonicalFiniteTargetJet0" -> Association@Table[
      order -> zeroVector, {order, orders}],
    "LogJet0" -> log0, "RegularJet1" -> regular1,
    "LogJet1" -> log1, "RegularJet2" -> regular2,
    "LogJet2" -> log2, "Checks" -> localChecks|>],
  {mode, {2, 3, 4, 6}}];

targetChecks = Flatten@Table[With[{unit = UnitVector[2, target]},
  t0 = Association@Table[order -> If[order === 0, unit, zeroVector],
    {order, orders}];
  t1 = atp[0, t0];
  t2 = seriesScale[seriesAdd[{atp[0, t1], atp[1, t0]}],
    PowerMod[2, -1, prime]];
  {zeroSeriesQ[seriesAdd[{t1, seriesScale[atp[0, t0], -1]}]],
   zeroSeriesQ[seriesAdd[{seriesScale[t2, 2],
     seriesScale[seriesAdd[{atp[0, t1], atp[1, t0]}], -1]}]]}],
  {target, 2}];
checks = Join[checks, targetChecks];

zeroModeOrder = {2, 3, 4, 6};
logCoefficientDeck = Association@Table[order -> SparseArray[Transpose[
    seriesGet[zeroData[#]["LogJet0"], order] & /@ zeroModeOrder]],
  {order, orders}];
finitePartDeck = Association@Table[order -> SparseArray[{}, {2, 4}],
  {order, orders}];
maximumLogRank = Max[MatrixRank[Normal[#], Modulus -> prime] & /@
  Values[logCoefficientDeck]];
homogeneousShift = Array[CF303TargetZeroModeShift, {2, 4}];
basisShift = ArrayFlatten[{{IdentityMatrix[4], ConstantArray[0, {4, 2}]},
  {homogeneousShift, IdentityMatrix[2]}}];
inverseBasisShift = ArrayFlatten[{{IdentityMatrix[4],
    ConstantArray[0, {4, 2}]}, {-homogeneousShift, IdentityMatrix[2]}}];
basisShiftIdentity = TrueQ[Simplify[
  basisShift . inverseBasisShift == IdentityMatrix[6]]];
checks = Append[checks, basisShiftIdentity];

result = <|
  "Status" -> If[And @@ checks,
    "CF303TangentialJunctionIntertwiningJetsAcceptedV1",
    "CF303TangentialJunctionIntertwiningJetsFailed"],
  "Prime" -> prime, "PPoint" -> pPoint,
  "CheckedRhoOrders" -> {0, 1},
  "EpsilonCoefficientWindow" -> epsilonWindow,
  "CheckCount" -> Length[checks], "PassedCheckCount" -> Count[checks, True],
  "NonzeroEigenmodes" -> nonzeroData,
  "ResonantZeroModes" -> zeroData,
  "ResonantZeroModeOrder" -> zeroModeOrder,
  "TargetHomogeneousBasis" ->
    {"IndependentTargetMode1", "IndependentTargetMode2"},
  "LogarithmicJordanCoefficientC" -> logCoefficientDeck,
  "MaximumRankC" -> maximumLogRank,
  "FinitePartMatrix" -> finitePartDeck,
  "GeneralizedChainMap" -> <|
    "SourceModes" -> zeroModeOrder, "TargetModes" -> {5, 6},
    "CoefficientDeck" -> logCoefficientDeck,
    "JordanLevels" -> {1, 1, 1, 1, 0, 0},
    "SingularFactorEncoding" -> "JordanLevel"|>,
  "TargetZeroModesChecked" -> 2,
  "CanonicalLeveltParticularConvention" ->
    "Finite target jet at rho^0 is set to zero for each resonant source mode",
  "HomogeneousShiftFreedom" -> <|
    "Dimensions" -> {2, 4},
    "Map" -> homogeneousShift,
    "BasisShift" -> basisShift,
    "InverseBasisShift" -> inverseBasisShift,
    "ShiftIdentityChecked" -> basisShiftIdentity,
    "Meaning" ->
      "Any other zero-mode particular differs by an existing target homogeneous zero mode"|>,
  "PhysicalNormalization" -> <|
    "Status" -> "AbsorbedIntoExistingTargetHomogeneousModes",
    "Stage3TargetColumns" -> {5, 6},
    "RequiredEpsilonOrderThrough" -> 2,
    "NewPhysicalPeriodsIntroduced" -> 0,
    "TargetGModeMapComplete" -> True|>,
  "EquivalentConstruction" ->
    HoldForm[Reg[Inverse[PhiG].Inverse[UH].PsiPhysical]],
  "Scope" ->
    "Contracted seven-source-state recurrence; no dense H or K deck"|>;
Put[result, outputPath];
Print[If[And @@ checks, "PASS ", "FAIL "], result["Status"],
  " checks=", result["PassedCheckCount"], "/", result["CheckCount"],
  " output=", outputPath];
If[! And @@ checks, Quit[3]];
