#!/usr/bin/env wolframscript

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["DRCA_RANK1_DIFFERENTIAL_V3 FAIL usage=<project-root> " <>
    "<fresh-output.wl>"];
  Exit[64]];

projectRoot = ExpandFileName[arguments[[1]]];
outputFile = ExpandFileName[arguments[[2]]];
prototypeDirectory = DirectoryName[$InputFileName];
exchangeDirectory = DirectoryName[prototypeDirectory];
assemblerFile = FileNameJoin[{prototypeDirectory,
  "DirectRootChannelAssembler.wl"}];
dependencyFiles = <|
  "LoadFACET" -> FileNameJoin[{projectRoot, "Addon", "Load",
    "LoadFACET.wl"}],
  "TripleRootAlgebra" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAlgebra.wl"}],
  "TripleRootStripAdapter" -> FileNameJoin[{exchangeDirectory,
    "TripleRootStripAdapter.wl"}],
  "TripleRootAffinePilot" -> FileNameJoin[{exchangeDirectory,
    "TripleRootAffinePilot.wl"}],
  "TripleRootReconstructionPrototype" -> FileNameJoin[{exchangeDirectory,
    "TripleRootReconstructionPrototype.wl"}]|>;
If[! DirectoryQ[projectRoot] || ! FileExistsQ[assemblerFile] ||
    ! AllTrue[Values[dependencyFiles], FileExistsQ] ||
    FileExistsQ[outputFile] || ! DirectoryQ[DirectoryName[outputFile]],
  Exit[65]];

writeAtomic[value_] := Module[{temporary, written, renamed},
  If[FileExistsQ[outputFile], Return[$Failed]];
  temporary = outputFile <> ".tmp-" <>
    StringReplace[CreateUUID[], "-" -> ""];
  written = Quiet[Check[Put[value, temporary], $Failed]];
  If[written === $Failed || ! FileExistsQ[temporary], Return[$Failed]];
  renamed = Quiet[Check[RenameFile[temporary, outputFile,
    OverwriteTarget -> False], $Failed]];
  If[renamed === $Failed || ! FileExistsQ[outputFile] ||
      FileExistsQ[temporary], $Failed, outputFile]
];
sourceHashes[] := <|
  "Dependencies" -> Map[
    FileHash[#1, "SHA256", "HexString"] &, dependencyFiles],
  "Assembler" -> FileHash[assemblerFile, "SHA256", "HexString"],
  "Driver" -> FileHash[$InputFileName, "SHA256", "HexString"]|>;
expectedHashes = sourceHashes[];

savedMessages = $Messages;
messageFile = outputFile <> ".messages.tmp-" <>
  StringReplace[CreateUUID[], "-" -> ""];
messageStream = OpenWrite[messageFile, CharacterEncoding -> "UTF8"];
$Messages = {messageStream};
loadOutcome = Check[
  Get[dependencyFiles["LoadFACET"]];
  Get[dependencyFiles["TripleRootAlgebra"]];
  Get[dependencyFiles["TripleRootStripAdapter"]];
  Get[dependencyFiles["TripleRootAffinePilot"]];
  Get[dependencyFiles["TripleRootReconstructionPrototype"]];
  Get[assemblerFile];
  True, $Failed];

modRational[value_, prime_Integer] := Module[{r = Together[value], d},
  If[! MatchQ[r, _Integer | _Rational], Return[$Failed]];
  d = Mod[Denominator[r], prime];
  If[d === 0, Return[$Failed]];
  Mod[Numerator[r] PowerMod[d, -1, prime], prime]
];
character[signMask_Integer, grade_Integer, rank_Integer] := If[
  EvenQ[Total[BitGet[BitAnd[signMask, grade],
    Range[0, rank - 1]]]], 1, -1];
maskProduct[mask_Integer, values_List, prime_Integer] := Fold[
  Mod[#1 #2, prime] &, 1, Pick[values,
    BitGet[mask, Range[0, Length[values] - 1]], 1]];

Clear[x, y, eps];
roots = {<|"Root" -> Sqrt[x + 3], "RootSquare" -> x + 3|>};
makeField[seed_Integer] := CodexTripleRootStrip`TRFieldCompose[
  Table[Together[(seed + 3 grade + eps (1 + grade) x +
      (2 + grade) y)/(1 + x + 2 y)], {grade, 0, 1}], roots];
record = <|"Family" -> "DRCARank1DifferentialV3", "Sector" -> 1,
  "LowerSector" -> 0, "Variables" -> {x, y}, "Regulator" -> eps,
  "Strip" -> {
    Table[makeField[20 mu + 5 i + j], {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[50 mu + 7 i + 2 j],
      {mu, 2}, {i, 2}, {j, 2}],
    Table[makeField[90 mu + 11 i + 3 j],
      {mu, 2}, {i, 2}, {j, 2}]}|>;
oneForms = Table[{makeField[130 + 9 letter],
  makeField[170 + 11 letter]}, {letter, 2}];
gaugeDenominator = (1 + x) (1 + y);
support = {{0, 0}, {0, 1}, {1, 0}};
prime = 10007;
epsilonValue = 1/21;
epsilonMod = modRational[epsilonValue, prime];
point = {3, 39};
flipMask = 1;

assembly = CodexDirectRootChannelAssembler`DRCACompileSystem[
  record, roots, oneForms, gaugeDenominator, support, {}, <|
    "SourceABIFingerprint" -> "rank1-differential-diagnostic-v3",
    "RootOrderingFingerprint" -> Hash[
      Lookup[roots, "RootSquare"], "SHA256", "HexString"]|>];
epsilonForms = If[
  Lookup[assembly, "Status", None] === "PreparedDirectRootChannelsV1",
  CodexDirectRootChannelAssembler`DRCACollapseEpsilon[
    assembly, prime, epsilonValue], $Failed];
direct = If[AssociationQ[epsilonForms],
  CodexDirectRootChannelAssembler`DRCAAssemblePoint[
    assembly, epsilonForms, prime, point], $Failed];
rootValues = If[AssociationQ[direct] &&
    Lookup[direct, "Status", None] ===
      "AssembledDirectRootChannelPointV1",
  CodexTripleRoot`TRSquareRoots[direct["DeltaValues"], prime], $Failed];
transformed = If[ListQ[rootValues],
  CodexDirectRootChannelAssembler`DRCATransformPointToSigns[
    direct, rootValues, prime, flipMask], $Failed];
legacy = Quiet[CodexTripleRootPilot`TRSplitPointRows[
  record, roots, oneForms, gaugeDenominator, support,
  epsilonValue, prime, point]];

gradeCount = 2;
{upperDimension, lowerDimension} = {2, 2};
supportCount = Length[support];
gaugeUnknownCount = upperDimension lowerDimension gradeCount supportCount;
equationsPerSign = 2 upperDimension lowerDimension;
order = Flatten[Table[Range[
    BitXor[signMask, flipMask] equationsPerSign + 1,
    (BitXor[signMask, flipMask] + 1) equationsPerSign],
  {signMask, 0, gradeCount - 1}]];
legacyRows = If[AssociationQ[legacy], Developer`ToPackedArray[
  Mod[Normal /@ legacy["Rows"][[order]], prime]], $Failed];
legacyRight = If[AssociationQ[legacy], Developer`ToPackedArray[
  Mod[legacy["RightHandSide"][[order]], prime]], $Failed];

decodeRowColumn[row_Integer, column_Integer] := Module[
  {rowZero = row - 1, columnZero = column - 1, displaySign,
   sourceSign, equationZero, mu, remainder, i, j, quotient,
   monomial, sourceGrade, b, a},
  displaySign = Quotient[rowZero, equationsPerSign];
  sourceSign = BitXor[displaySign, flipMask];
  equationZero = Mod[rowZero, equationsPerSign];
  mu = Quotient[equationZero,
      upperDimension lowerDimension] + 1;
  remainder = Mod[equationZero, upperDimension lowerDimension];
  i = Quotient[remainder, lowerDimension] + 1;
  j = Mod[remainder, lowerDimension] + 1;
  If[column > gaugeUnknownCount,
    Return[<|"Row" -> row, "Column" -> column,
      "ColumnType" -> "Residue", "DisplaySignMask" -> displaySign,
      "SourceSignMask" -> sourceSign, "Direction" -> mu,
      "UpperEquationRow" -> i, "LowerEquationColumn" -> j|>]];
  monomial = Mod[columnZero, supportCount] + 1;
  quotient = Quotient[columnZero, supportCount];
  sourceGrade = Mod[quotient, gradeCount];
  quotient = Quotient[quotient, gradeCount];
  b = Mod[quotient, lowerDimension] + 1;
  a = Quotient[quotient, lowerDimension] + 1;
  <|"Row" -> row, "Column" -> column, "ColumnType" -> "Gauge",
    "DisplaySignMask" -> displaySign,
    "SourceSignMask" -> sourceSign, "Direction" -> mu,
    "UpperEquationRow" -> i, "LowerEquationColumn" -> j,
    "GaugeUpperRow" -> a, "GaugeLowerColumn" -> b,
    "SourceGrade" -> sourceGrade, "SupportIndex" -> monomial,
    "SupportExponent" -> support[[monomial]]|>
];

deltaValues = If[ListQ[rootValues], direct["DeltaValues"], {}];
rootProducts = If[ListQ[rootValues],
  maskProduct[#1, rootValues, prime] & /@ Range[0, 1], {}];
denominatorValue = modRational[
  gaugeDenominator /. Thread[{x, y} -> point], prime];
denominatorLog = Table[modRational[
  D[gaugeDenominator, variable]/gaugeDenominator /.
    Thread[{x, y} -> point], prime], {variable, {x, y}}];
rootLog = Table[modRational[
  D[roots[[1, "RootSquare"]], variable]/
    roots[[1, "RootSquare"]] /. Thread[{x, y} -> point], prime],
  {variable, {x, y}}];
half = PowerMod[2, -1, prime];

rationalDerivative[semantic_Association] := Module[
  {sourceGrade, monomial, exponents, mu, monomialValue,
   monomialLog, basisRational, rootLogTerm},
  sourceGrade = semantic["SourceGrade"];
  monomial = semantic["SupportIndex"];
  exponents = semantic["SupportExponent"];
  mu = semantic["Direction"];
  monomialValue = Mod[PowerMod[point[[1]], exponents[[1]], prime]
    PowerMod[point[[2]], exponents[[2]], prime], prime];
  monomialLog = If[mu === 1,
    Mod[exponents[[1]] PowerMod[point[[1]], -1, prime], prime],
    Mod[exponents[[2]] PowerMod[point[[2]], -1, prime], prime]];
  basisRational = Mod[monomialValue PowerMod[
    denominatorValue, -1, prime], prime];
  rootLogTerm = If[sourceGrade === 1,
    Mod[half rootLog[[mu]], prime], 0];
  <|"BasisRational" -> basisRational,
    "MonomialLogDerivative" -> monomialLog,
    "MinusGaugeLogDerivative" -> Mod[-denominatorLog[[mu]], prime],
    "RootLogDerivativeHalf" -> rootLogTerm,
    "RationalDerivativeCoefficient" -> Mod[basisRational
      (monomialLog - denominatorLog[[mu]] + rootLogTerm), prime]|>
];
signWeights[sourceSign_Integer] := Table[Mod[
  character[sourceSign, targetGrade, 1]
    rootProducts[[targetGrade + 1]], prime],
  {targetGrade, 0, 1}];

oldRows = If[MatrixQ[Lookup[transformed, "Rows", None], IntegerQ],
  Developer`ToPackedArray[MapIndexed[Function[{value, position}, Module[
    {semantic, derivative, weights, leakage},
    semantic = decodeRowColumn[position[[1]], position[[2]]];
    If[semantic["ColumnType"] =!= "Gauge" ||
        semantic["GaugeUpperRow"] =!= semantic["UpperEquationRow"] ||
        semantic["GaugeLowerColumn"] =!=
          semantic["LowerEquationColumn"],
      value,
      derivative = rationalDerivative[semantic];
      weights = signWeights[semantic["SourceSignMask"]];
      leakage = Mod[derivative["RationalDerivativeCoefficient"]
        (Total[weights] - weights[[semantic["SourceGrade"] + 1]]),
        prime];
      Mod[value + leakage, prime]]
  ]], transformed["Rows"], {2}]], $Failed];
mismatchPositions = If[MatrixQ[oldRows, IntegerQ] &&
    MatrixQ[legacyRows, IntegerQ],
  Position[Mod[oldRows - legacyRows, prime], Except[0], {2},
    Heads -> False], {}];
rootGradeMismatchPositions = Select[mismatchPositions,
  With[{semantic = decodeRowColumn[#[[1]], #[[2]]]},
    semantic["ColumnType"] === "Gauge" &&
      semantic["SourceGrade"] === 1 &&
      semantic["GaugeUpperRow"] === semantic["UpperEquationRow"] &&
      semantic["GaugeLowerColumn"] ===
        semantic["LowerEquationColumn"]] &];
selectedMismatch = If[rootGradeMismatchPositions =!= {},
  First[rootGradeMismatchPositions],
  If[mismatchPositions =!= {}, First[mismatchPositions], $Failed]];

branchValue[expression_, sourceSign_Integer] := Module[
  {sign, branched},
  sign = If[BitGet[sourceSign, 0] === 0, 1, -1];
  branched = CodexTripleRootStrip`TRApplyRootBranches[
    expression, roots, Mod[{sign} rootValues, prime]];
  modRational[branched /. Thread[{x, y} -> point] /.
    eps -> epsilonValue, prime]
];

componentEvidence = If[ListQ[selectedMismatch], Module[
  {row = selectedMismatch[[1]], column = selectedMismatch[[2]],
   semantic, derivativeData, weights, sourceGrade, sourceSign, mu,
   i, j, a, b, monomial, branchBasis, derivativeContribution,
   eContribution, cContribution, expected, oldLeakage},
  semantic = decodeRowColumn[row, column];
  derivativeData = rationalDerivative[semantic];
  weights = signWeights[semantic["SourceSignMask"]];
  sourceGrade = semantic["SourceGrade"];
  sourceSign = semantic["SourceSignMask"];
  mu = semantic["Direction"];
  i = semantic["UpperEquationRow"];
  j = semantic["LowerEquationColumn"];
  a = semantic["GaugeUpperRow"];
  b = semantic["GaugeLowerColumn"];
  monomial = semantic["SupportIndex"];
  branchBasis = Mod[weights[[sourceGrade + 1]]
    derivativeData["BasisRational"], prime];
  derivativeContribution = If[a === i && b === j,
    Mod[weights[[sourceGrade + 1]]
      derivativeData["RationalDerivativeCoefficient"], prime], 0];
  eContribution = If[b === j, Mod[-epsilonMod
    branchValue[record["Strip"][[1, mu, i, a]], sourceSign]
    branchBasis, prime], 0];
  cContribution = If[a === i, Mod[epsilonMod
    branchValue[record["Strip"][[2, mu, b, j]], sourceSign]
    branchBasis, prime], 0];
  expected = Mod[derivativeContribution + eContribution +
    cContribution, prime];
  oldLeakage = If[a === i && b === j, Mod[
    derivativeData["RationalDerivativeCoefficient"]
      (Total[weights] - weights[[sourceGrade + 1]]), prime], 0];
  <|"Position" -> selectedMismatch, "ColumnSemantic" -> semantic,
    "LegacyValue" -> legacyRows[[row, column]],
    "CorrectedDirectValue" -> transformed["Rows"][[row, column]],
    "OldEmulatedValue" -> oldRows[[row, column]],
    "SignWeights" -> weights,
    "DerivativeData" -> derivativeData,
    "DerivativeContribution" -> derivativeContribution,
    "EContribution" -> eContribution,
    "CContribution" -> cContribution,
    "ExpectedSum" -> expected, "OldDerivativeLeakage" -> oldLeakage,
    "ExpectedMatchesLegacy" -> TrueQ[
      expected === legacyRows[[row, column]]],
    "ExpectedMatchesCorrectedDirect" -> TrueQ[
      expected === transformed["Rows"][[row, column]]],
    "OldPredictionExact" -> TrueQ[Mod[expected + oldLeakage, prime] ===
      oldRows[[row, column]]]|>
], <|"FailureReason" -> "NoOldFormulaMismatchFound"|>];

independentTransform = If[ListQ[rootValues],
  Developer`ToPackedArray[Table[Mod[
    character[signMask, grade, 1] rootProducts[[grade + 1]], prime],
    {signMask, 0, 1}, {grade, 0, 1}]], $Failed];
publicTransform = If[ListQ[rootValues],
  CodexDirectRootChannelAssembler`DRCASignTransform[
    rootValues, prime], $Failed];
currentMatrixEqual = TrueQ[AssociationQ[transformed] &&
  transformed["Rows"] === legacyRows];
rightEqual = TrueQ[AssociationQ[transformed] &&
  transformed["RightHandSide"] === legacyRight];
oldMatrixEqual = TrueQ[oldRows === legacyRows];
passed = TrueQ[loadOutcome === True && currentMatrixEqual && rightEqual &&
  ! oldMatrixEqual && mismatchPositions =!= {} &&
  rootGradeMismatchPositions =!= {} &&
  independentTransform === publicTransform &&
  TrueQ[componentEvidence["ExpectedMatchesLegacy"]] &&
  TrueQ[componentEvidence["ExpectedMatchesCorrectedDirect"]] &&
  TrueQ[componentEvidence["OldPredictionExact"]] &&
  componentEvidence["OldDerivativeLeakage"] =!= 0];

Close[messageStream];
$Messages = savedMessages;
messages = Quiet[Check[Import[messageFile, "Text"], $Failed]];
If[FileExistsQ[messageFile], Quiet[DeleteFile[messageFile]]];
completionHashes = sourceHashes[];
hashesStable = TrueQ[completionHashes === expectedHashes];
messagesEmpty = StringQ[messages] && StringTrim[messages] === "";
passed = TrueQ[passed && messagesEmpty && hashesStable];
status = If[passed, "DirectRootChannelRank1DifferentialV3Passed",
  "DirectRootChannelRank1DifferentialV3Failed"];
report = <|"Status" -> status,
  "Protocol" -> "DirectRootChannelRank1DifferentialV3",
  "Prime" -> prime, "EpsilonValue" -> epsilonValue,
  "Point" -> point, "BranchFlipMask" -> flipMask,
  "CurrentMatrixEqual" -> currentMatrixEqual,
  "RightHandSideEqual" -> rightEqual,
  "OldFormulaMatrixEqual" -> oldMatrixEqual,
  "OldFormulaMismatchCount" -> Length[mismatchPositions],
  "FirstOldFormulaMismatch" -> If[mismatchPositions === {},
    Missing["None"], First[mismatchPositions]],
  "SelectedRootGradeMismatchEvidence" -> componentEvidence,
  "SignTransformOrderingEvidence" -> <|
    "IndependentTransform" -> independentTransform,
    "PublicTransform" -> publicTransform,
    "Equal" -> TrueQ[independentTransform === publicTransform],
    "RightHandSideEqual" -> rightEqual|>,
  "CapturedMessages" -> messages, "MessagesEmpty" -> messagesEmpty,
  "ExpectedSourceHashes" -> expectedHashes,
  "CompletionSourceHashes" -> completionHashes,
  "SourceHashesStableAtCompletion" -> hashesStable|>;
If[writeAtomic[report] === $Failed, Exit[98]];
Print["DRCA_RANK1_DIFFERENTIAL_V3 status=", status,
  " output=", outputFile];
Exit[If[passed, 0, 1]];
