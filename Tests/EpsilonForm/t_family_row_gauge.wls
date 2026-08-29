#!/usr/bin/env wolframscript
(* Exact unit and adversarial checks for the sparse completed-row gauge. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps, a, b, c, d, e, f];
zeroQ[expression_] := TrueQ[Together[expression] === 0];
matrixZeroQ[matrix_] := AllTrue[Flatten[{matrix}], zeroQ];
sameMatrixQ[left_, right_] := Dimensions[left] === Dimensions[right] &&
  matrixZeroQ[left - right];

n = 7; rows = {4, 5}; columns = Range[3];
r1 = Sqrt[1 + x + x^2];
r2 = Sqrt[1 - 4 x y];
r3 = Sqrt[4 y + x^2];
grades = {1, r1, r2, r1 r2, r3, r1 r3, r2 r3, r1 r2 r3};

connection = Table[
  Table[If[i < j, 0,
    grades[[1 + Mod[5 mu + 3 i + j, Length[grades]]]]
      (eps + mu + i x + j y)/(1 + i + j + x + 2 y)],
    {i, n}, {j, n}],
  {mu, 2}];
gauge = {
  {x/(1 + y), r1 r3/(2 + x), r1 r2 r3/(3 + x + y)},
  {0, r2/(1 + x + y), (r1 + r2 r3)/(2 + y)}};

dFull = ConstantArray[0, {n, n}];
dFull[[rows, columns]] = gauge;
t = IdentityMatrix[n] + dFull;
tInverse = IdentityMatrix[n] - dFull;
expectedConnection = Table[
  Map[Together,
    tInverse . connection[[mu]] . t -
      tInverse . D[t, {x, y}[[mu]]], {2}],
  {mu, 2}];

result = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge, {x, y}];
FTTest`FTAssert["dense rank-three row accepted",
  AssociationQ[result] && result["Status"] === "OK"];
FTTest`FTAssert["D squared is structurally zero", dFull . dFull === ConstantArray[0, {n, n}]];
FTTest`FTAssert["D A D vanishes in both variables",
  And @@ (matrixZeroQ[dFull . # . dFull] & /@ connection)];
FTTest`FTAssert["D dD vanishes in both variables",
  And @@ (matrixZeroQ[dFull . D[dFull, #]] & /@ {x, y})];
FTTest`FTAssert["sparse connection equals full gauge formula",
  sameMatrixQ[result["Connection"], expectedConnection]];
FTTest`FTAssert["forward transformation equals I+D",
  sameMatrixQ[result["Transformation"], t]];
FTTest`FTAssert["inverse transformation equals I-D",
  sameMatrixQ[result["Inverse"], tInverse]];
FTTest`FTAssert["transformation inverse identity",
  matrixZeroQ[result["Transformation"] . result["Inverse"] - IdentityMatrix[n]] &&
    matrixZeroQ[result["Inverse"] . result["Transformation"] - IdentityMatrix[n]]];

untouchedA = Select[Tuples[{Range[2], Range[n], Range[n]}],
  ! (#[[2]] >= First[rows] && #[[3]] < First[rows]) &];
untouchedS = Select[Tuples[{Range[n], Range[n]}], #[[2]] >= First[rows] &];
untouchedInverse = Select[Tuples[{Range[n], Range[n]}],
  ! MemberQ[rows, #[[1]]] &];
FTTest`FTAssert["untouched connection entries remain SameQ",
  AllTrue[untouchedA,
    SameQ[Extract[result["Connection"], #], Extract[connection, #]] &]];
FTTest`FTAssert["untouched forward entries remain SameQ",
  AllTrue[untouchedS,
    SameQ[Extract[result["Transformation"], #],
      Extract[IdentityMatrix[n], #]] &]];
FTTest`FTAssert["untouched inverse entries remain SameQ",
  AllTrue[untouchedInverse,
    SameQ[Extract[result["Inverse"], #], Extract[IdentityMatrix[n], #]] &]];
denseAProducts = 2 (Length[Range[First[rows], n]] Length[columns]
    Length[rows] + Length[rows] Length[columns]^2);
denseSProducts = n Length[columns] Length[rows];
denseInverseProducts = Length[rows] n Length[columns];
FTTest`FTAssert["sparse accounting skips structural products",
  result["Statistics", "A", "Products"] < denseAProducts &&
  result["Statistics", "S", "Products"] < denseSProducts &&
  result["Statistics", "SInverse", "Products"] < denseInverseProducts &&
  result["Statistics", "S", "Touched"] <
    result["Statistics", "S", "CandidateEntries"] &&
  result["Statistics", "SInverse", "Touched"] <
    result["Statistics", "SInverse", "CandidateEntries"]];
FTTest`FTAssert["literal single-term updates bypass normalization",
  Total[result["Statistics", #, "SingleTermFastPath"] & /@
      {"A", "S", "SInverse"}] > 0];

installedRow = expectedConnection[[All, rows, columns]];
installedResult = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge,
  {x, y}, installedRow];
FTTest`FTAssert["materialized transformed row bypasses redundant products",
  installedResult["Status"] === "OK" &&
    installedResult["Statistics", "A", "InstalledRowEntries"] ===
      2 Length[rows] Length[columns] &&
    installedResult["Statistics", "A", "Products"] <
      result["Statistics", "A", "Products"] &&
    sameMatrixQ[installedResult["Connection"], expectedConnection] &&
    sameMatrixQ[installedResult["Transformation"], t] &&
    sameMatrixQ[installedResult["Inverse"], tInverse]];
FTTest`FTAssert["materialized current row preserves future-row A D updates",
  ! matrixZeroQ[
    installedResult["Connection"][[All, Last[rows] + 1 ;; n, columns]] -
      connection[[All, Last[rows] + 1 ;; n, columns]]] &&
    sameMatrixQ[
      installedResult["Connection"][[All, Last[rows] + 1 ;; n, columns]],
      expectedConnection[[All, Last[rows] + 1 ;; n, columns]]]];

deferredResult = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge,
  {x, y}, installedRow, "Deferred"];
futureTargets = Select[
  Tuples[{Range[2], Range[Last[rows] + 1, n], columns}],
  ! SameQ[Total[MapThread[Times,
      {connection[[#[[1]], #[[2]], rows]], gauge[[All, #[[3]]]]}]], 0] &];
futureNonTargets = Complement[
  Tuples[{Range[2], Range[Last[rows] + 1, n], columns}], futureTargets];
FTTest`FTAssert["deferred future A is exactly dense-equivalent",
  deferredResult["Status"] === "OK" &&
    sameMatrixQ[deferredResult["Connection"], expectedConnection] &&
    sameMatrixQ[deferredResult["Transformation"], t] &&
    sameMatrixQ[deferredResult["Inverse"], tInverse]];
FTTest`FTAssert["deferred mode preserves all structurally untouched entries",
  AllTrue[untouchedA,
      SameQ[Extract[deferredResult["Connection"], #],
        Extract[connection, #]] &] &&
    AllTrue[untouchedS,
      SameQ[Extract[deferredResult["Transformation"], #],
        Extract[IdentityMatrix[n], #]] &] &&
    AllTrue[untouchedInverse,
      SameQ[Extract[deferredResult["Inverse"], #],
        Extract[IdentityMatrix[n], #]] &] &&
    AllTrue[futureNonTargets,
      SameQ[Extract[deferredResult["Connection"], #],
        Extract[connection, #]] &] &&
    SameQ[deferredResult["Connection"][[All, rows, columns]],
      installedRow] &&
    SameQ[deferredResult["Transformation"],
      installedResult["Transformation"]] &&
    SameQ[deferredResult["Inverse"], installedResult["Inverse"]]];
FTTest`FTAssert["deferred future target accounting is explicit",
  deferredResult["Statistics", "A", "FutureCandidateEntries"] ===
      2 (n - Last[rows]) Length[columns] &&
    deferredResult["Statistics", "A", "FutureTouched"] ===
      Length[futureTargets] &&
    deferredResult["Statistics", "A", "DeferredFutureEntries"] ===
      Length[futureTargets] &&
    deferredResult["Statistics", "A", "FutureProducts"] ===
      deferredResult["Statistics", "A", "Products"] &&
    deferredResult["Statistics", "A", "FutureAMode"] === "Deferred"];

rawConnection = ConstantArray[0, {2, 3, 3}];
rawConnection[[1, 3, 1]] = 1/y;
rawConnection[[1, 3, 2]] = 1/x;
rawGauge = {{1/(1 + x)}};
rawInstalled = ConstantArray[0, {2, 1, 1}];
rawResult = FeynFacet`Private`familyRowGaugeApply[
  rawConnection, IdentityMatrix[3], IdentityMatrix[3], {2}, rawGauge,
  {x, y}, rawInstalled, "Deferred"];
rawExpected = 1/y + 1/(x (1 + x));
FTTest`FTAssert["deferred future entries remain raw exact sums",
  rawResult["Status"] === "OK" &&
    SameQ[rawResult["Connection"][[1, 3, 1]], rawExpected] &&
    ! SameQ[rawExpected, Together[rawExpected]] &&
    zeroQ[rawResult["Connection"][[1, 3, 1]] -
      Together[rawExpected]]];

rawInverse = {{1, 1/y, 0}, {0, 1, 0}, {0, 0, 1}};
rawTransformation = {{1, -1/y, 0}, {0, 1, 0}, {0, 0, 1}};
rawDeferredInverse = FeynFacet`Private`familyRowGaugeApply[
  rawConnection, rawTransformation, rawInverse, {2}, rawGauge,
  {x, y}, rawInstalled, "Deferred"];
rawD = ConstantArray[0, {3, 3}];
rawD[[2, 1]] = First[First[rawGauge]];
rawExpectedInverse = (IdentityMatrix[3] - rawD) . rawInverse;
FTTest`FTAssert["production inverse normalization is deferred exactly once",
  rawDeferredInverse["Status"] === "OK" &&
    rawDeferredInverse["Statistics", "SInverse",
      "DeferredNormalizationEntries"] > 0 &&
    rawDeferredInverse["Statistics", "SInverse",
      "NormalizationSeconds"] === 0. &&
    sameMatrixQ[rawDeferredInverse["Inverse"], rawExpectedInverse] &&
    ! SameQ[rawDeferredInverse["Inverse"],
      Map[Together, rawExpectedInverse, {2}]]];

missingInstalledDeferred = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge,
  {x, y}, Automatic, "Deferred"];
incompleteInstalled = installedRow;
incompleteInstalled[[1, 1, 1]] = Missing["Unavailable"];
incompleteInstalledDeferred = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge,
  {x, y}, incompleteInstalled, "Deferred"];
badFutureMode = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge,
  {x, y}, installedRow, "Unknown"];
FTTest`FTAssert["future A modes fail closed before mutation",
  missingInstalledDeferred["Status"] ===
      "DeferredFutureARequiresCompleteInstalledRow" &&
    incompleteInstalledDeferred["Status"] ===
      "DeferredFutureARequiresCompleteInstalledRow" &&
    badFutureMode["Status"] === "InvalidFutureAMode"];

badInstalled = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge,
  {x, y}, {{{0}}}];
FTTest`FTAssert["malformed installed row dimensions are typed",
  AssociationQ[badInstalled] &&
    badInstalled["Status"] === "InvalidInstalledRowDimensions"];

residue1 = {{1, 2, 0}, {0, eps, 3}};
residue2 = {{0, -1, 4}, {2, 0, 1}};
dlogSolution = <|"Method" -> "SyntheticDLog", "Alphabet" -> {x, 1 + y},
  "ResidueMatrices" -> {residue1, residue2}|>;
dlogForm = FeynFacet`Private`familyRowGaugeDLogForm[
  dlogSolution, {x, y}, eps, {2, 3}];
expectedDLogForm = {eps residue1/x, eps residue2/(1 + y)};
FTTest`FTAssert["accepted dlog row is materialized without a gauge product",
  sameMatrixQ[dlogForm[[1]], expectedDLogForm[[1]]] &&
    sameMatrixQ[dlogForm[[2]], expectedDLogForm[[2]]]];
framedDLogForm = FeynFacet`Private`familyRowGaugeDLogForm[
  <|"Method" -> "Framed", "Alphabet" -> {x, 1 + y},
    "InnerSolution" -> <|"ResidueMatrices" -> {residue1, residue2}|>|>,
  {x, y}, eps, {2, 3}];
FTTest`FTAssert["framed dlog residues are read from the inner solution",
  sameMatrixQ[framedDLogForm[[1]], expectedDLogForm[[1]]] &&
    sameMatrixQ[framedDLogForm[[2]], expectedDLogForm[[2]]]];
FTTest`FTAssert["zero-forcing dlog materialization is a literal zero pair",
  FeynFacet`Private`familyRowGaugeDLogForm[
    <|"Method" -> "ZeroForcing"|>, {x, y}, eps, {2, 3}] ===
      ConstantArray[0, {2, 2, 3}]];
FTTest`FTAssert["malformed dlog certificate is rejected",
  MissingQ[FeynFacet`Private`familyRowGaugeDLogForm[
    <|"Method" -> "Bad", "Alphabet" -> {x},
      "ResidueMatrices" -> {{{1}}}|>, {x, y}, eps, {2, 3}]]];

canonicaEpsilon = Symbol["CANONICA`eps"];
checkpoint = <|"PrevD" -> {{1 + eps}},
  "SolvedForms" -> <|1 -> {{{eps/x}}, {{2 eps/(1 + y)}}}|>|>;
decodedCheckpoint = FeynFacet`Private`familyRowGaugeDecodeCheckpoint[
  checkpoint, eps, canonicaEpsilon];
FTTest`FTAssert["checkpoint decoding rekeys only the CANONICA gauge state",
  decodedCheckpoint["SolvedForms"] === checkpoint["SolvedForms"] &&
    FreeQ[decodedCheckpoint["PrevD"], eps] &&
    ! FreeQ[decodedCheckpoint["PrevD"], canonicaEpsilon] &&
    (decodedCheckpoint["PrevD"] /. canonicaEpsilon -> eps) ===
      checkpoint["PrevD"]];
FTTest`FTAssert["checkpoint gauges end on complete lower-block boundaries",
  FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ[
    {{a, b}, {c, d}}, 2, {1, 2}] &&
    ! FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ[
      {{a}, {b, c}}, 2, {1, 2}] &&
    ! FeynFacet`Private`familyRowGaugeCheckpointGaugeShapeQ[
      {{a}, {b}}, 2, {1, 2}]];
validStripSummaries = {<|"Sector" -> 3, "LowerSector" -> 2,
  "ExactDLog" -> True|>};
fullStripSummaries = Join[validStripSummaries,
  {<|"Sector" -> 3, "LowerSector" -> 1, "ExactDLog" -> True|>}];
FTTest`FTAssert["checkpoint summaries exactly cover the recovered suffix",
  FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
    validStripSummaries, {{a, b}, {c, d}}, 3, {1, 2}] &&
    FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
      {}, {{}, {}}, 3, {1, 2}]];
FTTest`FTAssert["missing or misordered checkpoint summaries fail closed",
  ! FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
    {}, {{a, b}, {c, d}}, 3, {1, 2}] &&
    ! FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
      Reverse[fullStripSummaries], {{a, b, c}, {d, e, f}}, 3, {1, 2}] &&
    ! FeynFacet`Private`familyRowGaugeCheckpointStripSolversQ[
      {<|"Sector" -> 3, "LowerSector" -> 1|>},
      {{a, b}, {c, d}}, 3, {1, 2}]];

installedForms = <|
  1 -> {{{eps}, {2 eps}}, {{3 eps}, {4 eps}}},
  2 -> {{{x, y}, {1 + x, 1 + y}},
    {{2 x, 2 y}, {2 + x, 2 + y}}}|>;
installedBlocks = <|1 -> {{a}, {b}}, 2 -> {{c, d}, {e, f}}|>;
installedColumns = <|1 -> {1}, 2 -> {2, 3}|>;
assembledInstalledRow =
  FeynFacet`Private`familyRowGaugeAssembleInstalledRow[
    installedForms, installedBlocks, 2, 3, installedColumns];
FTTest`FTAssert["a complete well-formed materialized row is assembled exactly",
  assembledInstalledRow ===
    {{{eps, x, y}, {2 eps, 1 + x, 1 + y}},
      {{3 eps, 2 x, 2 y}, {4 eps, 2 + x, 2 + y}}}];
corruptInstalledForms = installedForms;
corruptInstalledForms[2] = {{{0}}};
FTTest`FTAssert["a malformed materialized row fails closed to the sparse formula",
  FeynFacet`Private`familyRowGaugeAssembleInstalledRow[
    corruptInstalledForms, installedBlocks, 2, 3, installedColumns] ===
      Automatic];

zeroResult = FeynFacet`Private`familyRowGaugeApply[
  connection, t, tInverse, rows, ConstantArray[0, {2, 3}], {x, y}];
FTTest`FTAssert["zero row gauge is an exact SameQ no-op",
  SameQ[zeroResult["Connection"], connection] &&
    SameQ[zeroResult["Transformation"], t] &&
    SameQ[zeroResult["Inverse"], tInverse] &&
    Total[zeroResult["Statistics", #, "Touched"] & /@
      {"A", "S", "SInverse"}] === 0];

badConnection = connection;
badConnection[[1, 1, First[rows]]] = 1;
badResult = FeynFacet`Private`familyRowGaugeApply[
  badConnection, IdentityMatrix[n], IdentityMatrix[n], rows, gauge, {x, y}];
FTTest`FTAssert["non-lower block structure is rejected before mutation",
  AssociationQ[badResult] && badResult["Status"] === "InvalidBlockStructure"];
badDimensions = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows, {{1, 2}}, {x, y}];
FTTest`FTAssert["malformed gauge dimensions are typed",
  AssociationQ[badDimensions] && badDimensions["Status"] === "InvalidGaugeDimensions"];

(* Ordered composition: D2.D1 is nonzero, so flattening the factors to
   I+D1+D2 would be wrong. *)
rows1 = {3}; gauge1 = {{r1/(1 + x), r2/(2 + y)}};
rows2 = {6, 7};
gauge2 = {
  {0, r3/(1 + y), r1 r2/(2 + x), 0, r1 r2 r3/(3 + x + y)},
  {r2 r3/(2 + x), 0, 1/(1 + x + y), r1/(3 + y), 0}};
d1 = ConstantArray[0, {n, n}]; d1[[rows1, Range[2]]] = gauge1;
d2 = ConstantArray[0, {n, n}]; d2[[rows2, Range[5]]] = gauge2;
first = FeynFacet`Private`familyRowGaugeApply[
  connection, IdentityMatrix[n], IdentityMatrix[n], rows1, gauge1, {x, y}];
second = FeynFacet`Private`familyRowGaugeApply[
  first["Connection"], first["Transformation"], first["Inverse"],
  rows2, gauge2, {x, y}];
totalT = Map[Together, (IdentityMatrix[n] + d1) .
  (IdentityMatrix[n] + d2), {2}];
totalInverse = Map[Together, (IdentityMatrix[n] - d2) .
  (IdentityMatrix[n] - d1), {2}];
expectedSequential = Table[
  Map[Together,
    totalInverse . connection[[mu]] . totalT -
      totalInverse . D[totalT, {x, y}[[mu]]], {2}],
  {mu, 2}];
FTTest`FTAssert["sequential control has D2.D1 nonzero",
  ! matrixZeroQ[d2 . d1]];
FTTest`FTAssert["ordered sequential connection is exact",
  second["Status"] === "OK" &&
    sameMatrixQ[second["Connection"], expectedSequential]];
FTTest`FTAssert["ordered sequential transformations are exact",
  sameMatrixQ[second["Transformation"], totalT] &&
    sameMatrixQ[second["Inverse"], totalInverse]];

FTTest`FTReport[];
