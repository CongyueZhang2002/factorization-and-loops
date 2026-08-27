BeginPackage["CodexDirectRootChannelAssembler`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`",
  "CodexTripleRootPilot`", "CodexTripleRootReconstruction`"}];

DRCACompileSystem::usage =
  "DRCACompileSystem[record,roots,oneForms,gaugeDenominator,support,normalizations] exactly decomposes one multiquadratic strip into root channels and compiles every rational channel into a sparse x/y polynomial ABI with polynomial epsilon coefficients.";
DRCAPrepare::usage =
  "DRCAPrepare[preparation] validates a PreparedReconstruction object and constructs its direct root-channel assembly preparation.";
DRCAAssemblyPreparationValidQ::usage =
  "DRCAAssemblyPreparationValidQ[assembly] verifies the stored semantic payload, source hash, dimensions, column ordering and assembly fingerprint.";
DRCAPrimeForms::usage =
  "DRCAPrimeForms[assembly,p] reduces the exact compiled channel ABI modulo p, memoized per assembly fingerprint and prime.";
DRCACollapseEpsilon::usage =
  "DRCACollapseEpsilon[assembly,p,epsilonValue] Horner-collapses every reduced coefficient polynomial at epsilonValue modulo p.";
DRCAAssemblePoint::usage =
  "DRCAAssemblePoint[assembly,epsilonForms,p,{x,y}] builds packed dense direct-channel rows ordered by output grade, direction and matrix entry.";
DRCAAssembleSample::usage =
  "DRCAAssembleSample[assembly,epsilonValue,p] assembles a deterministic direct-channel finite-field sample, with optional preselected CandidatePoints.";
DRCASignTransform::usage =
  "DRCASignTransform[rootValues,p] returns the character/root-product matrix mapping grade-channel equations to split-sign equations.";
DRCATransformPointToSigns::usage =
  "DRCATransformPointToSigns[pointResult,rootValues,p,flipMask] maps one direct-channel point block into legacy split-sign row order.";
DRCATransformSampleToSigns::usage =
  "DRCATransformSampleToSigns[assembly,sample,p,flipMask] transforms every point block of a direct sample into legacy split-sign rows.";
DRCADifferentialCheckPoint::usage =
  "DRCADifferentialCheckPoint[assembly,epsilonValue,p,point,flipMask] independently compares transformed direct-channel rows with legacy TRSplitPointRows.";
DRCAClearCaches::usage =
  "DRCAClearCaches[] clears the per-kernel prime and epsilon-form caches.";

Begin["`Private`"];

ClearAll[
  drcaFailure, drcaStableFingerprint, drcaZeroQ, drcaModRational,
  drcaCompilePolynomial, drcaCompileRational, drcaDecomposeScalar,
  drcaCompileTensor, drcaMapRationals, drcaReducePolynomial,
  drcaReduceRational, drcaCollapsePolynomial, drcaCollapseRational,
  drcaEvaluatePolynomial, drcaEvaluateRational, drcaEvaluateForms,
  drcaMaximumExponents, drcaMaskFactorMod, drcaCharacter,
  drcaGaugeIndex, drcaResidueIndex, drcaPointRowIndex,
  drcaSemanticPayload, drcaColumnOrderPayload, drcaRowOrderPayload,
  drcaFormShape, drcaPolynomialImageValidQ, drcaRationalImageValidQ,
  drcaEpsilonFormsValidQ,
  drcaAssemblePointInternal, drcaNormalizationRows,
  drcaCacheInsert, drcaPrimeFormsValidated,
  drcaCollapseEpsilonValidated, $drcaPrimeCache, $drcaEpsilonCache,
  $drcaSourceFile, $drcaSourceSHA256
];

$drcaSourceFile = ExpandFileName[$InputFileName];
$drcaSourceSHA256 = FileHash[$drcaSourceFile, "SHA256", "HexString"];
$drcaPrimeCache = <||>;
$drcaEpsilonCache = <||>;
$drcaMaximumRootCount = 3;
$drcaMaximumEpsilonDegree = 256;

drcaFailure[reason_String, data_: <||>] := Join[
  <|"Status" -> "DirectRootChannelAssemblyFailure",
    "FailureReason" -> reason|>, data];

drcaStableFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

drcaZeroQ[value_] := AllTrue[Flatten[{value}],
  TrueQ[Together[#1] === 0] &];

drcaModRational[value_, prime_Integer] := Module[
  {rational = Together[value], denominator},
  If[! (IntegerQ[rational] || Head[rational] === Rational),
    Return[$Failed]];
  denominator = Mod[Denominator[rational], prime];
  If[denominator === 0, Return[$Failed]];
  Mod[Numerator[rational] PowerMod[denominator, -1, prime], prime]
];

(* Exact polynomial ABI. Terms with a common x/y monomial are grouped;
   the row stores exact coefficients of eps^0..eps^K. *)
drcaCompilePolynomial[polynomial_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {vars = Append[variables, epsilon], expanded, rules, groups, xExponents,
   yExponents, maximumEpsilonDegree, coefficientRows},
  expanded = Expand[polynomial];
  If[! PolynomialQ[expanded, vars], Return[$Failed]];
  rules = CoefficientRules[expanded, vars];
  If[rules === {}, Return[<|
    "Type" -> "DRCAPolynomialExactV1", "XExponents" -> {},
    "YExponents" -> {}, "EpsilonCoefficientRows" -> {}|>]];
  If[! AllTrue[Last /@ rules,
      IntegerQ[#1] || Head[#1] === Rational &], Return[$Failed]];
  maximumEpsilonDegree = Max[rules[[All, 1, 3]]];
  If[maximumEpsilonDegree > $drcaMaximumEpsilonDegree, Return[$Failed]];
  groups = GatherBy[rules, First[#1][[1 ;; 2]] &];
  xExponents = groups[[All, 1, 1, 1]];
  yExponents = groups[[All, 1, 1, 2]];
  coefficientRows = Table[
    Module[{row = ConstantArray[0, Max[group[[All, 1, 3]]] + 1]},
      Do[row[[rule[[1, 3]] + 1]] += rule[[2]], {rule, group}]; row],
    {group, groups}];
  <|"Type" -> "DRCAPolynomialExactV1",
    "XExponents" -> Developer`ToPackedArray[xExponents],
    "YExponents" -> Developer`ToPackedArray[yExponents],
    "EpsilonCoefficientRows" -> coefficientRows|>
];

drcaCompileRational[expression_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[{rational, numerator, denominator},
  rational = Together[expression];
  If[! FreeQ[rational,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  numerator = drcaCompilePolynomial[Numerator[rational], variables, epsilon];
  denominator = drcaCompilePolynomial[Denominator[rational], variables, epsilon];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "DRCARationalExactV1", "Numerator" -> numerator,
    "Denominator" -> denominator|>
];

drcaDecomposeScalar[expression_, roots_List] := Module[
  {channels, reconstructed},
  channels = CodexTripleRootStrip`TRFieldDecompose[expression, roots];
  If[! ListQ[channels] || Length[channels] =!= 2^Length[roots] ||
      MemberQ[channels, $Failed], Return[$Failed]];
  reconstructed = CodexTripleRootStrip`TRFieldCompose[channels, roots];
  If[! TrueQ[Together[reconstructed - expression] === 0], Return[$Failed]];
  channels
];

drcaCompileTensor[tensor_, scalarLevel_Integer, roots_List,
    variables_List, epsilon_Symbol] := Module[{channels, compiled},
  channels = Map[drcaDecomposeScalar[#1, roots] &, tensor, {scalarLevel}];
  If[! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[drcaCompileRational[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

drcaColumnOrderPayload[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

drcaRowOrderPayload[dimensions_List, gradeCount_Integer] := <|
  "PointRows" -> "{outputGrade0Based,direction,upperRow,lowerColumn}",
  "RowIndexFormula" ->
    "(((grade*2+(mu-1)) upper+(i-1)) lower+j)",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount|>;

drcaSemanticPayload[assembly_Association] := KeyTake[assembly, {
  "SourceABIFingerprint", "RootOrderingFingerprint", "RootCount",
  "GradeCount", "Dimensions", "GaugeSupport", "OneForms",
  "GaugeDenominator", "Normalizations", "GaugeUnknownCount",
  "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
  "ColumnOrder", "RowOrder", "ExactChannelFormsFingerprint",
  "CompiledFormsFingerprint", "CompiledFormsShapeFingerprint",
  "SourceSemanticFingerprint", "PrototypeSourceSHA256"}];

DRCACompileSystem[record_Association, roots_List, oneForms_List,
    gaugeDenominator_, support_List, normalizations_List: {},
    metadata_: <||>] := Module[
  {variables, epsilon, strip, e, c, bbar, dimensions, upperDimension,
   lowerDimension, gradeCount, supportCount, gaugeUnknownCount,
   residueUnknownCount, unknownCount, equationsPerPoint, eData, cData,
   bData, oneData, rootSquares, rootSquareData, rootLogData,
   denominatorData, denominatorLogData, exactForms, compiledForms,
   sourceABIFingerprint, rootOrderingFingerprint, payload, result},
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}] ||
      ! AllTrue[support,
        MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &] ||
      support === {} || ! DuplicateFreeQ[support] ||
      Length[roots] > $drcaMaximumRootCount ||
      ! MatchQ[oneForms, {} | {{_, _} ..}] || ! ListQ[normalizations],
    Return[drcaFailure["InvalidCompileSystemInput"]]];
  {e, c, bbar} = strip;
  dimensions = Dimensions[bbar[[1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      Dimensions[bbar] =!= Prepend[dimensions, 2],
    Return[drcaFailure["InvalidForcingDimensions"]]];
  {upperDimension, lowerDimension} = dimensions;
  If[Dimensions[e] =!= {2, upperDimension, upperDimension} ||
      Dimensions[c] =!= {2, lowerDimension, lowerDimension},
    Return[drcaFailure["InvalidDiagonalDimensions"]]];
  If[! AllTrue[roots, AssociationQ] ||
      ! AllTrue[roots, KeyExistsQ[#1, "Root"] &&
        KeyExistsQ[#1, "RootSquare"] && TrueQ[Together[
          #1["Root"]^2 - #1["RootSquare"]] === 0] &],
    Return[drcaFailure["InvalidRootMetadata"]]];
  If[! DuplicateFreeQ[Lookup[roots, "RootSquare", {}],
      TrueQ[Together[#1 - #2] === 0] &],
    Return[drcaFailure["DuplicateRootSquares"]]];
  gradeCount = 2^Length[roots];
  supportCount = Length[support];
  gaugeUnknownCount = upperDimension lowerDimension gradeCount supportCount;
  residueUnknownCount = Length[oneForms] upperDimension lowerDimension;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 upperDimension lowerDimension;
  If[! AllTrue[normalizations, AssociationQ[#1] &&
      IntegerQ[Lookup[#1, "Column", None]] &&
      1 <= #1["Column"] <= unknownCount &&
      KeyExistsQ[#1, "Value"] &],
    Return[drcaFailure["InvalidNormalizations"]]];
  If[! DuplicateFreeQ[Lookup[normalizations, "Column", {}]],
    Return[drcaFailure["DuplicateNormalizationColumns"]]];

  eData = drcaCompileTensor[e, 3, roots, variables, epsilon];
  cData = drcaCompileTensor[c, 3, roots, variables, epsilon];
  bData = drcaCompileTensor[bbar, 3, roots, variables, epsilon];
  oneData = drcaCompileTensor[oneForms, 2, roots, variables, epsilon];
  If[MemberQ[{eData, cData, bData, oneData}, $Failed],
    Return[drcaFailure["ExactChannelDecompositionFailed"]]];
  rootSquares = Lookup[roots, "RootSquare", {}];
  rootSquareData = drcaCompileTensor[rootSquares, 1, {}, variables, epsilon];
  rootLogData = drcaCompileTensor[
    Table[D[rootSquares[[a]], variables[[mu]]] / rootSquares[[a]],
      {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
  denominatorData = drcaCompileTensor[{gaugeDenominator}, 1, {},
    variables, epsilon];
  denominatorLogData = drcaCompileTensor[
    {D[gaugeDenominator, variables[[1]]] / gaugeDenominator,
      D[gaugeDenominator, variables[[2]]] / gaugeDenominator},
    1, {}, variables, epsilon];
  If[MemberQ[{rootSquareData, rootLogData, denominatorData,
      denominatorLogData}, $Failed],
    Return[drcaFailure["RationalAssemblyFormCompilationFailed"]]];
  exactForms = <|"E" -> eData["Channels"], "C" -> cData["Channels"],
    "BBar" -> bData["Channels"],
    "OneForms" -> oneData["Channels"],
    "RootSquares" -> (First /@ rootSquareData["Channels"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Channels"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Channels"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Channels"]|>;
  compiledForms = <|"E" -> eData["Compiled"],
    "C" -> cData["Compiled"], "BBar" -> bData["Compiled"],
    "OneForms" -> oneData["Compiled"],
    "RootSquares" -> (First /@ rootSquareData["Compiled"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Compiled"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Compiled"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Compiled"]|>;
  If[! FreeQ[compiledForms, $Failed],
    Return[drcaFailure["CompiledAssemblyFormsInvalid"]]];
  sourceABIFingerprint = Lookup[metadata, "SourceABIFingerprint",
    drcaStableFingerprint[{record, roots, oneForms, gaugeDenominator,
      support, normalizations}]];
  rootOrderingFingerprint = Lookup[metadata, "RootOrderingFingerprint",
    drcaStableFingerprint[Lookup[roots, "RootSquare", {}]]];
  result = <|
    "Status" -> "PreparedDirectRootChannelsV1",
    "PrototypeSourceFile" -> $drcaSourceFile,
    "PrototypeSourceSHA256" -> $drcaSourceSHA256,
    "SourceABIFingerprint" -> sourceABIFingerprint,
    "RootOrderingFingerprint" -> rootOrderingFingerprint,
    "Record" -> record, "Roots" -> roots,
    "RootCount" -> Length[roots], "GradeCount" -> gradeCount,
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions, "GaugeSupport" -> support,
    "OneForms" -> oneForms, "GaugeDenominator" -> Together[gaugeDenominator],
    "Normalizations" -> normalizations,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> equationsPerPoint,
    "ColumnOrder" -> drcaColumnOrderPayload[dimensions, gradeCount,
      support, Length[oneForms]],
    "RowOrder" -> drcaRowOrderPayload[dimensions, gradeCount],
    "ExactChannelForms" -> exactForms,
    "CompiledForms" -> compiledForms,
    "ExactChannelFormsFingerprint" -> drcaStableFingerprint[exactForms],
    "CompiledFormsFingerprint" -> drcaStableFingerprint[compiledForms],
    "CompiledFormsShapeFingerprint" ->
      drcaStableFingerprint[drcaFormShape[compiledForms]],
    "SourceSemanticFingerprint" -> drcaStableFingerprint[
      {record, roots, variables, epsilon}]|>;
  payload = drcaSemanticPayload[result];
  Append[result, "AssemblyFingerprint" -> drcaStableFingerprint[payload]]
];

DRCAPrepare[preparation_Association] := Module[{compiled},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation],
    Return[drcaFailure["InvalidSourcePreparationABI"]]];
  compiled = DRCACompileSystem[preparation["Record"], preparation["Roots"],
    preparation["OneForms"], preparation["GaugeDenominator"],
    preparation["GaugeSupport"], preparation["Normalizations"], <|
      "SourceABIFingerprint" -> preparation["ABIFingerprint"],
      "RootOrderingFingerprint" -> preparation["RootOrderingFingerprint"]|>];
  If[Lookup[compiled, "Status", None] =!= "PreparedDirectRootChannelsV1",
    Return[compiled]];
  If[compiled["Dimensions"] =!= preparation["Dimensions"] ||
      compiled["GaugeUnknownCount"] =!= preparation["GaugeUnknownCount"] ||
      compiled["ResidueUnknownCount"] =!= preparation["ResidueUnknownCount"] ||
      compiled["UnknownCount"] =!= preparation["UnknownCount"] ||
      compiled["EquationsPerPoint"] =!= preparation["EquationsPerPoint"],
    drcaFailure["SourcePreparationShapeMismatch"], compiled]
];

DRCAAssemblyPreparationValidQ[assembly_Association] := Module[
  {payload, dimensions, rootCount, gradeCount, support, expectedGauge,
   expectedResidue, sourceHash, requiredKeys},
  If[Lookup[assembly, "Status", None] =!=
      "PreparedDirectRootChannelsV1", Return[False]];
  requiredKeys = {"PrototypeSourceFile", "PrototypeSourceSHA256",
    "SourceABIFingerprint", "RootOrderingFingerprint", "Record", "Roots",
    "RootCount", "GradeCount", "Variables", "Regulator", "Dimensions",
    "GaugeSupport", "OneForms", "GaugeDenominator", "Normalizations",
    "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount",
    "EquationsPerPoint", "ColumnOrder", "RowOrder", "ExactChannelForms",
    "CompiledForms", "ExactChannelFormsFingerprint",
    "CompiledFormsFingerprint", "CompiledFormsShapeFingerprint",
    "SourceSemanticFingerprint", "AssemblyFingerprint"};
  If[! AllTrue[requiredKeys, KeyExistsQ[assembly, #1] &], Return[False]];
  sourceHash = Quiet[Check[FileHash[assembly["PrototypeSourceFile"],
    "SHA256", "HexString"], $Failed]];
  dimensions = Lookup[assembly, "Dimensions", $Failed];
  rootCount = Lookup[assembly, "RootCount", $Failed];
  gradeCount = Lookup[assembly, "GradeCount", $Failed];
  support = Lookup[assembly, "GaugeSupport", $Failed];
  If[! MatchQ[dimensions, {_Integer, _Integer}] ||
      ! IntegerQ[rootCount] || !(0 <= rootCount <= $drcaMaximumRootCount) ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {}, Return[False]];
  expectedGauge = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[assembly["OneForms"]] Times @@ dimensions;
  payload = drcaSemanticPayload[assembly];
  TrueQ[
    sourceHash === assembly["PrototypeSourceSHA256"] &&
    sourceHash === $drcaSourceSHA256 &&
    assembly["GaugeUnknownCount"] === expectedGauge &&
    assembly["ResidueUnknownCount"] === expectedResidue &&
    assembly["UnknownCount"] === expectedGauge + expectedResidue &&
    assembly["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    assembly["ColumnOrder"] === drcaColumnOrderPayload[
      dimensions, gradeCount, support, Length[assembly["OneForms"]]] &&
    assembly["RowOrder"] === drcaRowOrderPayload[dimensions, gradeCount] &&
    assembly["ExactChannelFormsFingerprint"] ===
      drcaStableFingerprint[assembly["ExactChannelForms"]] &&
    assembly["CompiledFormsFingerprint"] ===
      drcaStableFingerprint[assembly["CompiledForms"]] &&
    assembly["CompiledFormsShapeFingerprint"] ===
      drcaStableFingerprint[drcaFormShape[assembly["CompiledForms"]]] &&
    assembly["SourceSemanticFingerprint"] === drcaStableFingerprint[
      {assembly["Record"], assembly["Roots"], assembly["Variables"],
        assembly["Regulator"]}] &&
    assembly["AssemblyFingerprint"] === drcaStableFingerprint[payload]]
];

drcaMapRationals[expression_, sourceType_String, function_] := Which[
  AssociationQ[expression] && Lookup[expression, "Type", None] === sourceType,
    function[expression],
  AssociationQ[expression],
    Map[drcaMapRationals[#1, sourceType, function] &, expression],
  ListQ[expression],
    drcaMapRationals[#1, sourceType, function] & /@ expression,
  True, expression
];

drcaReducePolynomial[polynomial_Association, prime_Integer] := Module[
  {rows},
  rows = Map[drcaModRational[#1, prime] &,
    polynomial["EpsilonCoefficientRows"], {2}];
  If[! FreeQ[rows, $Failed], Return[$Failed]];
  <|"Type" -> "DRCAPolynomialPrimeV1",
    "XExponents" -> polynomial["XExponents"],
    "YExponents" -> polynomial["YExponents"],
    "EpsilonCoefficientRows" -> Developer`ToPackedArray[rows],
    "Prime" -> prime|>
];

drcaReduceRational[rational_Association, prime_Integer] := Module[
  {numerator, denominator},
  numerator = drcaReducePolynomial[rational["Numerator"], prime];
  denominator = drcaReducePolynomial[rational["Denominator"], prime];
  If[numerator === $Failed || denominator === $Failed, Return[$Failed]];
  <|"Type" -> "DRCARationalPrimeV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

SetAttributes[drcaCacheInsert, HoldFirst];
drcaCacheInsert[cacheSymbol_Symbol, key_, value_, maximum_Integer] := Module[
  {},
  If[! AssociationQ[cacheSymbol], cacheSymbol = <||>];
  If[Length[cacheSymbol] >= maximum,
    KeyDropFrom[cacheSymbol, First[Keys[cacheSymbol]]]];
  AssociateTo[cacheSymbol, key -> value];
  value
];

drcaPrimeFormsValidated[assembly_Association, prime_Integer] := Module[
  {key, forms},
  key = {assembly["AssemblyFingerprint"],
    assembly["PrototypeSourceSHA256"], prime};
  If[KeyExistsQ[$drcaPrimeCache, key], Return[$drcaPrimeCache[key]]];
  forms = drcaMapRationals[assembly["CompiledForms"],
    "DRCARationalExactV1", drcaReduceRational[#1, prime] &];
  If[! FreeQ[forms, $Failed], Return[$Failed]];
  drcaCacheInsert[$drcaPrimeCache, key, <|
    "Status" -> "DirectRootChannelPrimeFormsV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "PrototypeSourceSHA256" -> assembly["PrototypeSourceSHA256"],
    "Prime" -> prime, "Forms" -> forms|>, 8]
];

DRCAPrimeForms[assembly_Association, prime_Integer] :=
  If[DRCAAssemblyPreparationValidQ[assembly] && PrimeQ[prime] &&
      3 < prime < 2^31,
    drcaPrimeFormsValidated[assembly, prime], $Failed];

drcaCollapsePolynomial[polynomial_Association, epsilonMod_Integer,
    prime_Integer] := Module[{coefficients, keep},
  If[polynomial["EpsilonCoefficientRows"] === {},
    Return[<|"Type" -> "DRCAPolynomialImageV1", "XExponents" -> {},
      "YExponents" -> {}, "Coefficients" -> {}, "Prime" -> prime|>]];
  coefficients = Fold[Mod[#1 epsilonMod + #2, prime] &, 0,
      Reverse[#1]] & /@ polynomial["EpsilonCoefficientRows"];
  keep = Flatten[Position[coefficients, Except[0], {1}, Heads -> False]];
  <|"Type" -> "DRCAPolynomialImageV1",
    "XExponents" -> Developer`ToPackedArray[
      polynomial["XExponents"][[keep]]],
    "YExponents" -> Developer`ToPackedArray[
      polynomial["YExponents"][[keep]]],
    "Coefficients" -> Developer`ToPackedArray[coefficients[[keep]]],
    "Prime" -> prime|>
];

drcaCollapseRational[rational_Association, epsilonMod_Integer,
    prime_Integer] := Module[{numerator, denominator},
  numerator = drcaCollapsePolynomial[rational["Numerator"], epsilonMod, prime];
  denominator = drcaCollapsePolynomial[rational["Denominator"], epsilonMod, prime];
  If[denominator["Coefficients"] === {}, Return[$Failed]];
  <|"Type" -> "DRCARationalImageV1", "Numerator" -> numerator,
    "Denominator" -> denominator, "Prime" -> prime|>
];

drcaCollapseEpsilonValidated[assembly_Association, prime_Integer,
    epsilonValue_] := Module[{key, primeForms, epsilonMod, forms, max},
  epsilonMod = drcaModRational[epsilonValue, prime];
  If[epsilonMod === $Failed, Return[$Failed]];
  key = {assembly["AssemblyFingerprint"], prime, epsilonMod};
  If[KeyExistsQ[$drcaEpsilonCache, key], Return[$drcaEpsilonCache[key]]];
  primeForms = drcaPrimeFormsValidated[assembly, prime];
  If[! AssociationQ[primeForms], Return[$Failed]];
  forms = drcaMapRationals[primeForms["Forms"],
    "DRCARationalPrimeV1",
    drcaCollapseRational[#1, epsilonMod, prime] &];
  If[! FreeQ[forms, $Failed], Return[$Failed]];
  max = drcaMaximumExponents[forms];
  drcaCacheInsert[$drcaEpsilonCache, key, <|
    "Status" -> "DirectRootChannelEpsilonFormsV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "Prime" -> prime, "EpsilonValue" -> epsilonValue,
    "EpsilonMod" -> epsilonMod, "MaximumExponents" -> max,
    "Forms" -> forms,
    "FormsShapeFingerprint" -> drcaStableFingerprint[drcaFormShape[forms]],
    "FormsFingerprint" -> drcaStableFingerprint[forms]|>, 32]
];

DRCACollapseEpsilon[assembly_Association, prime_Integer,
    epsilonValue_] := If[
  DRCAAssemblyPreparationValidQ[assembly] && PrimeQ[prime] &&
    3 < prime < 2^31,
  drcaCollapseEpsilonValidated[assembly, prime, epsilonValue], $Failed];

drcaMaximumExponents[forms_] := Module[{polynomials, nonzero},
  polynomials = Cases[forms,
    association_Association /;
      Lookup[association, "Type", None] === "DRCAPolynomialImageV1" :>
        association, {0, Infinity}];
  nonzero = Select[polynomials, Lookup[#1, "Coefficients", {}] =!= {} &];
  If[nonzero === {}, {0, 0},
    {Max[Max /@ Lookup[nonzero, "XExponents"]],
      Max[Max /@ Lookup[nonzero, "YExponents"]]}]
];

drcaFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{
      "DRCARationalExactV1", "DRCARationalPrimeV1",
      "DRCARationalImageV1"}, Lookup[expression, "Type", None]],
    "DRCARationalLeaf",
  AssociationQ[expression], Map[drcaFormShape, expression],
  ListQ[expression], drcaFormShape /@ expression,
  True, "Scalar"
];

drcaPolynomialImageValidQ[polynomial_Association,
    prime_Integer, allowZero_: True] := Module[
  {xExponents, yExponents, coefficients},
  If[Sort[Keys[polynomial]] =!= Sort[{"Type", "XExponents",
      "YExponents", "Coefficients", "Prime"}] ||
      polynomial["Type"] =!= "DRCAPolynomialImageV1" ||
      polynomial["Prime"] =!= prime, Return[False]];
  xExponents = polynomial["XExponents"];
  yExponents = polynomial["YExponents"];
  coefficients = polynomial["Coefficients"];
  TrueQ[VectorQ[xExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[yExponents, IntegerQ[#1] && #1 >= 0 &] &&
    VectorQ[coefficients, IntegerQ[#1] && 0 <= #1 < prime &] &&
    Length[xExponents] === Length[yExponents] === Length[coefficients] &&
    (TrueQ[allowZero] || coefficients =!= {})]
];

drcaRationalImageValidQ[rational_Association, prime_Integer] := TrueQ[
  Sort[Keys[rational]] === Sort[
    {"Type", "Numerator", "Denominator", "Prime"}] &&
  rational["Type"] === "DRCARationalImageV1" &&
  rational["Prime"] === prime &&
  AssociationQ[rational["Numerator"]] &&
  AssociationQ[rational["Denominator"]] &&
  drcaPolynomialImageValidQ[rational["Numerator"], prime, True] &&
  drcaPolynomialImageValidQ[rational["Denominator"], prime, False]];

drcaEvaluatePolynomial[polynomial_Association, xPowers_Association,
    yPowers_Association, prime_Integer] := Module[{monomials, terms},
  If[polynomial["Coefficients"] === {}, Return[0]];
  monomials = Mod[
    Lookup[xPowers, polynomial["XExponents"]]
      Lookup[yPowers, polynomial["YExponents"]], prime];
  terms = Mod[polynomial["Coefficients"] monomials, prime];
  Mod[Total[terms], prime]
];

drcaEvaluateRational[rational_Association, xPowers_Association,
    yPowers_Association,
    prime_Integer] := Module[{numerator, denominator},
  numerator = drcaEvaluatePolynomial[rational["Numerator"], xPowers,
    yPowers, prime];
  denominator = drcaEvaluatePolynomial[rational["Denominator"], xPowers,
    yPowers, prime];
  If[denominator === 0, Throw[$Failed, "DRCABadPoint"]];
  Mod[numerator PowerMod[denominator, -1, prime], prime]
];

drcaEvaluateForms[forms_, xPowers_Association, yPowers_Association,
    prime_Integer] :=
  drcaMapRationals[forms, "DRCARationalImageV1",
    drcaEvaluateRational[#1, xPowers, yPowers, prime] &];

drcaMaskFactorMod[mask_Integer, deltaValues_List, prime_Integer] :=
  Fold[Mod[#1 #2, prime] &, 1,
    Pick[deltaValues, BitGet[mask,
      If[deltaValues === {}, {}, Range[0, Length[deltaValues] - 1]]], 1]];

drcaCharacter[signMask_Integer, grade_Integer, rank_Integer] :=
  If[Mod[Total[BitGet[BitAnd[signMask, grade],
      If[rank === 0, {}, Range[0, rank - 1]]]], 2] === 0, 1, -1];

drcaGaugeIndex[i_Integer, j_Integer, grade_Integer,
    monomial_Integer, lowerDimension_Integer, gradeCount_Integer,
    supportCount_Integer] :=
  (((i - 1) lowerDimension + (j - 1)) gradeCount + grade) supportCount +
    monomial;

drcaResidueIndex[letter_Integer, i_Integer, j_Integer,
    gaugeUnknownCount_Integer, upperDimension_Integer,
    lowerDimension_Integer] := gaugeUnknownCount +
  ((letter - 1) upperDimension + (i - 1)) lowerDimension + j;

drcaPointRowIndex[targetGrade_Integer, mu_Integer, i_Integer,
    j_Integer, upperDimension_Integer, lowerDimension_Integer] :=
  ((targetGrade 2 + (mu - 1)) upperDimension + (i - 1)) lowerDimension + j;

drcaAssemblySourceStableQ[assembly_Association] := TrueQ[
  Quiet[Check[FileHash[assembly["PrototypeSourceFile"], "SHA256",
    "HexString"], $Failed]] === assembly["PrototypeSourceSHA256"] ===
      $drcaSourceSHA256];

drcaEpsilonFormsValidQ[assembly_Association, forms_Association,
    prime_Integer] := Module[
  {imageForms, rationalLeaves, epsilonMod, maximumExponents,
   expectedKeys},
  expectedKeys = {"Status", "AssemblyFingerprint", "Prime",
    "EpsilonValue", "EpsilonMod", "MaximumExponents", "Forms",
    "FormsShapeFingerprint", "FormsFingerprint"};
  If[Sort[Keys[forms]] =!= Sort[expectedKeys] ||
      Lookup[forms, "Status", None] =!=
        "DirectRootChannelEpsilonFormsV1" ||
      Lookup[forms, "AssemblyFingerprint", None] =!=
        assembly["AssemblyFingerprint"] ||
      Lookup[forms, "Prime", None] =!= prime, Return[False]];
  epsilonMod = Lookup[forms, "EpsilonMod", $Failed];
  maximumExponents = Lookup[forms, "MaximumExponents", $Failed];
  imageForms = Lookup[forms, "Forms", $Failed];
  If[! IntegerQ[epsilonMod] || !(0 <= epsilonMod < prime) ||
      drcaModRational[forms["EpsilonValue"], prime] =!= epsilonMod ||
      ! MatchQ[maximumExponents,
        {a_Integer, b_Integer} /; a >= 0 && b >= 0] ||
      ! AssociationQ[imageForms], Return[False]];
  rationalLeaves = Cases[imageForms,
    association_Association /;
      Lookup[association, "Type", None] === "DRCARationalImageV1" :>
        association, {0, Infinity}];
  TrueQ[rationalLeaves =!= {} &&
    AllTrue[rationalLeaves, drcaRationalImageValidQ[#1, prime] &] &&
    drcaMaximumExponents[imageForms] === maximumExponents &&
    drcaStableFingerprint[drcaFormShape[imageForms]] ===
      assembly["CompiledFormsShapeFingerprint"] ===
      forms["FormsShapeFingerprint"] &&
    drcaStableFingerprint[imageForms] === forms["FormsFingerprint"]]
];

drcaAssemblePointInternal[assembly_Association, epsilonForms_Association,
    prime_Integer, point : {_Integer, _Integer},
    validatedFingerprint_: Automatic] := Catch[Module[
  {startTime = AbsoluteTime[], dimensions = assembly["Dimensions"],
   upperDimension, lowerDimension, gradeCount = assembly["GradeCount"],
   support = assembly["GaugeSupport"], supportCount, unknownCount,
   gaugeUnknownCount, oneFormCount, epsilonMod, forms, maximumExponents,
   imagePolynomials, requiredXExponents, requiredYExponents,
   x, y, xPowers, yPowers, evaluated, primitiveEvaluated,
   primitiveDeltaValues, primitiveDenominatorValue,
   deltaValues, deltaMaskFactors, denominatorValue, denominatorInverse,
   gaugeLogDerivatives, rootLogDerivatives, eValues, cValues,
   bbarValues, oneFormValues, monomialValues, basisValues,
   basisDerivatives, xInverse, yInverse, half, logarithmicDerivative,
   targetGrade, sourceGrade, productGrade, productFactor, mu, i, j, a,
   b, letter, monomial, productWeight, productGrades, productWeights,
   rowIndex, rowCount, rows, right, row, gaugeRow, residueRow,
   residueRowExpectedWidth,
   assemblySeconds, sourceHashAfter},
  If[validatedFingerprint =!= assembly["AssemblyFingerprint"] &&
      ! drcaEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Throw[drcaFailure["InvalidEpsilonForms"], "DRCAAssemblyFailure"]];
  {upperDimension, lowerDimension} = dimensions;
  supportCount = Length[support];
  unknownCount = assembly["UnknownCount"];
  gaugeUnknownCount = assembly["GaugeUnknownCount"];
  oneFormCount = Length[assembly["OneForms"]];
  residueRowExpectedWidth = assembly["ResidueUnknownCount"];
  epsilonMod = epsilonForms["EpsilonMod"];
  If[epsilonMod === 0,
    Throw[drcaFailure["ZeroEpsilonImage"], "DRCAAssemblyFailure"]];
  {x, y} = Mod[point, prime];
  If[x === 0 || y === 0,
    Throw[drcaFailure["ZeroPointCoordinate", <|"Point" -> point|>],
      "DRCAAssemblyFailure"]];
  maximumExponents = epsilonForms["MaximumExponents"];
  forms = epsilonForms["Forms"];
  imagePolynomials = Cases[forms,
    association_Association /;
      Lookup[association, "Type", None] === "DRCAPolynomialImageV1" :>
        association, {0, Infinity}];
  requiredXExponents = Union[support[[All, 1]],
    Flatten[Lookup[imagePolynomials, "XExponents", {}]]];
  requiredYExponents = Union[support[[All, 2]],
    Flatten[Lookup[imagePolynomials, "YExponents", {}]]];
  xPowers = AssociationThread[requiredXExponents,
    PowerMod[x, #1, prime] & /@ requiredXExponents];
  yPowers = AssociationThread[requiredYExponents,
    PowerMod[y, #1, prime] & /@ requiredYExponents];
  evaluated = Catch[
    drcaEvaluateForms[forms, xPowers, yPowers, prime], "DRCABadPoint"];
  If[evaluated === $Failed,
    primitiveEvaluated = Catch[drcaEvaluateForms[
      KeyTake[forms, {"RootSquares", "GaugeDenominator"}],
      xPowers, yPowers, prime], "DRCABadPoint"];
    If[AssociationQ[primitiveEvaluated],
      primitiveDeltaValues = primitiveEvaluated["RootSquares"];
      If[VectorQ[primitiveDeltaValues, IntegerQ] &&
          Length[primitiveDeltaValues] === assembly["RootCount"] &&
          MemberQ[primitiveDeltaValues, 0],
        Throw[drcaFailure["DegenerateRootImage", <|
          "Point" -> point, "DeltaValues" -> primitiveDeltaValues|>],
          "DRCAAssemblyFailure"]];
      primitiveDenominatorValue =
        primitiveEvaluated["GaugeDenominator"];
      If[IntegerQ[primitiveDenominatorValue] &&
          primitiveDenominatorValue === 0,
        Throw[drcaFailure["ZeroGaugeDenominator", <|
          "Point" -> point|>], "DRCAAssemblyFailure"]]];
    Throw[drcaFailure["RationalChannelPole", <|"Point" -> point|>],
      "DRCAAssemblyFailure"]];
  deltaValues = evaluated["RootSquares"];
  If[! VectorQ[deltaValues, IntegerQ] ||
      Length[deltaValues] =!= assembly["RootCount"] ||
      MemberQ[deltaValues, 0],
    Throw[drcaFailure["DegenerateRootImage", <|
      "Point" -> point, "DeltaValues" -> deltaValues|>],
      "DRCAAssemblyFailure"]];
  denominatorValue = evaluated["GaugeDenominator"];
  If[! IntegerQ[denominatorValue] || denominatorValue === 0,
    Throw[drcaFailure["ZeroGaugeDenominator", <|"Point" -> point|>],
      "DRCAAssemblyFailure"]];
  denominatorInverse = PowerMod[denominatorValue, -1, prime];
  deltaMaskFactors = Developer`ToPackedArray[
    drcaMaskFactorMod[#1, deltaValues, prime] & /@
      Range[0, gradeCount - 1]];
  gaugeLogDerivatives = evaluated["GaugeLogDerivatives"];
  rootLogDerivatives = evaluated["RootLogDerivatives"];
  eValues = evaluated["E"];
  cValues = evaluated["C"];
  bbarValues = evaluated["BBar"];
  oneFormValues = evaluated["OneForms"];
  xInverse = PowerMod[x, -1, prime];
  yInverse = PowerMod[y, -1, prime];
  half = PowerMod[2, -1, prime];
  monomialValues = Developer`ToPackedArray[Table[
    Mod[xPowers[support[[monomial, 1]]]
      yPowers[support[[monomial, 2]]], prime],
    {monomial, supportCount}]];
  basisValues = Developer`ToPackedArray[Table[
    Mod[monomialValues[[monomial]] denominatorInverse, prime],
    {sourceGrade, 0, gradeCount - 1}, {monomial, supportCount}]];
  basisDerivatives = Developer`ToPackedArray[Table[
    logarithmicDerivative = Mod[
      If[mu === 1,
        support[[monomial, 1]] xInverse,
        support[[monomial, 2]] yInverse] -
      gaugeLogDerivatives[[mu]] + half Sum[
        If[BitGet[sourceGrade, a - 1] === 1,
          rootLogDerivatives[[a, mu]], 0],
        {a, assembly["RootCount"]}], prime];
    Mod[basisValues[[sourceGrade + 1, monomial]]
      logarithmicDerivative, prime],
    {mu, 2}, {sourceGrade, 0, gradeCount - 1},
    {monomial, supportCount}]];
  productGrades = Developer`ToPackedArray[Table[
    BitXor[targetGrade, sourceGrade],
    {targetGrade, 0, gradeCount - 1},
    {sourceGrade, 0, gradeCount - 1}]];
  productWeights = Developer`ToPackedArray[Table[
    productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
    productFactor = deltaMaskFactors[[
      BitAnd[productGrade, sourceGrade] + 1]];
    Mod[Mod[epsilonMod
      basisValues[[sourceGrade + 1, monomial]], prime]
        productFactor, prime],
    {targetGrade, 0, gradeCount - 1},
    {sourceGrade, 0, gradeCount - 1},
    {monomial, supportCount}]];
  rowCount = assembly["EquationsPerPoint"];
  rows = Table[ConstantArray[0, unknownCount], rowCount];
  right = ConstantArray[0, rowCount];
  Do[
    rowIndex = drcaPointRowIndex[targetGrade, mu, i, j,
      upperDimension, lowerDimension];
    gaugeRow = Flatten[Table[
      productGrade = productGrades[[targetGrade + 1, sourceGrade + 1]];
      productWeight =
        productWeights[[targetGrade + 1, sourceGrade + 1, monomial]];
      Mod[Mod[
          If[targetGrade === sourceGrade && a === i && b === j,
            basisDerivatives[[mu, sourceGrade + 1, monomial]], 0] +
          If[b === j, -productWeight
            eValues[[mu, i, a, productGrade + 1]], 0], prime] +
        If[a === i, productWeight
          cValues[[mu, b, j, productGrade + 1]], 0], prime],
      {a, upperDimension}, {b, lowerDimension},
      {sourceGrade, 0, gradeCount - 1},
      {monomial, supportCount}]];
    residueRow = Flatten[Table[
      If[a === i && b === j,
        Mod[epsilonMod oneFormValues[[letter, mu, targetGrade + 1]],
          prime], 0],
      {letter, oneFormCount}, {a, upperDimension},
      {b, lowerDimension}]];
    If[Length[residueRow] =!= residueRowExpectedWidth,
      Throw[drcaFailure["DirectResidueRowWidthMismatch", <|
        "Expected" -> residueRowExpectedWidth,
        "Observed" -> Length[residueRow]|>],
        "DRCAAssemblyFailure"]];
    row = Join[gaugeRow, residueRow];
    If[Length[row] =!= unknownCount,
      Throw[drcaFailure["DirectRowWidthMismatch", <|
        "Expected" -> unknownCount, "Observed" -> Length[row]|>],
        "DRCAAssemblyFailure"]];
    rows[[rowIndex]] = Developer`ToPackedArray[row];
    right[[rowIndex]] =
      Mod[bbarValues[[mu, i, j, targetGrade + 1]], prime],
    {targetGrade, 0, gradeCount - 1}, {mu, 2},
    {i, upperDimension}, {j, lowerDimension}];
  rows = Developer`ToPackedArray[rows];
  right = Developer`ToPackedArray[right];
  assemblySeconds = N[AbsoluteTime[] - startTime];
  sourceHashAfter = Quiet[Check[FileHash[assembly["PrototypeSourceFile"],
    "SHA256", "HexString"], $Failed]];
  If[sourceHashAfter =!= assembly["PrototypeSourceSHA256"],
    Throw[drcaFailure["PrototypeSourceChangedDuringPointAssembly"],
      "DRCAAssemblyFailure"]];
  <|"Status" -> "AssembledDirectRootChannelPointV1",
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "PrototypeSourceSHA256" -> assembly["PrototypeSourceSHA256"],
    "Prime" -> prime, "EpsilonValue" -> epsilonForms["EpsilonValue"],
    "EpsilonMod" -> epsilonMod, "Point" -> {x, y},
    "DeltaValues" -> deltaValues, "Rows" -> rows,
    "RightHandSide" -> right, "MatrixDimensions" -> Dimensions[rows],
    "Dimensions" -> dimensions, "RootCount" -> assembly["RootCount"],
    "GradeCount" -> gradeCount,
    "EquationsPerGrade" -> 2 Times @@ dimensions,
    "UnknownCount" -> unknownCount, "RowBasis" ->
      "MultiquadraticGradeBasis", "AssemblySeconds" -> assemblySeconds|>
], "DRCAAssemblyFailure"];

DRCAAssemblePoint[assembly_Association, epsilonForms_Association,
    prime_Integer, point : {_Integer, _Integer}] := Module[{result},
  If[! DRCAAssemblyPreparationValidQ[assembly] ||
      ! drcaAssemblySourceStableQ[assembly] || ! PrimeQ[prime] ||
      !(3 < prime < 2^31), Return[drcaFailure["InvalidPointAssemblyInput"]]];
  result = drcaAssemblePointInternal[assembly, epsilonForms, prime, point];
  If[AssociationQ[result], result,
    drcaFailure["PointAssemblyDidNotReturnAssociation"]]
];

DRCAAssemblePoint[___] := drcaFailure["InvalidPointAssemblyArguments"];

drcaNormalizationRows[assembly_Association, epsilonValue_,
    prime_Integer] := Module[
  {unknownCount = assembly["UnknownCount"], epsilon = assembly["Regulator"],
   rows, right},
  rows = Table[Developer`ToPackedArray[ReplacePart[
      ConstantArray[0, unknownCount], normalization["Column"] -> 1]],
    {normalization, assembly["Normalizations"]}];
  right = drcaModRational[
      #1["Value"] /. epsilon -> epsilonValue, prime] & /@
    assembly["Normalizations"];
  If[MemberQ[right, $Failed], $Failed,
    {Developer`ToPackedArray[rows], Developer`ToPackedArray[right]}]
];

Options[DRCAAssembleSample] = {
  "PointCount" -> Automatic,
  "MaximumAttempts" -> Automatic,
  "RandomSeed" -> 2026082307,
  "CandidatePoints" -> Automatic,
  "BranchFlipMask" -> 0
};

DRCAAssembleSample[assembly_Association, epsilonValue_, prime_Integer,
    OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], epsilonForms, pointCount, maximumAttempts,
   randomSeed, candidatePoints, flipMask, accepted = {}, rejected = {},
   acceptedPointKeys = <||>, pointKey,
   attempts = 0, candidateIndex = 0, point, pointResult, pointRows,
   pointRight, normalization, matrix, right, collapseSeconds,
   materializationStart, materializationSeconds, totalSeconds,
   sourceHashAfter, pointRanges, equationCount, validationSeconds,
   assemblyValid},
  {validationSeconds, assemblyValid} = AbsoluteTiming[
    DRCAAssemblyPreparationValidQ[assembly] &&
      drcaAssemblySourceStableQ[assembly]];
  If[! TrueQ[assemblyValid] || ! PrimeQ[prime] ||
      !(3 < prime < 2^31),
    Return[drcaFailure["InvalidSampleAssemblyInput"]]];
  {collapseSeconds, epsilonForms} = AbsoluteTiming[
    drcaCollapseEpsilonValidated[assembly, prime, epsilonValue]];
  If[! AssociationQ[epsilonForms] ||
      Lookup[epsilonForms, "Status", None] =!=
        "DirectRootChannelEpsilonFormsV1" ||
      epsilonForms["EpsilonMod"] === 0 ||
      ! drcaEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[drcaFailure["EpsilonFormCollapseFailed"]]];
  pointCount = Replace[OptionValue["PointCount"], Automatic :>
    Max[4, Ceiling[(assembly["UnknownCount"] +
      assembly["EquationsPerPoint"])/assembly["EquationsPerPoint"]]]];
  maximumAttempts = Replace[OptionValue["MaximumAttempts"],
    Automatic :> 40 pointCount];
  randomSeed = OptionValue["RandomSeed"];
  candidatePoints = OptionValue["CandidatePoints"];
  flipMask = OptionValue["BranchFlipMask"];
  If[! IntegerQ[pointCount] || pointCount < 1 ||
      ! IntegerQ[maximumAttempts] || maximumAttempts < pointCount ||
      ! IntegerQ[randomSeed] || ! IntegerQ[flipMask] || flipMask < 0 ||
      flipMask >= assembly["GradeCount"] ||
      ! (candidatePoints === Automatic ||
        MatchQ[candidatePoints, {{_Integer, _Integer} ..}]),
    Return[drcaFailure["InvalidSampleAssemblyOptions"]]];
  BlockRandom[
    SeedRandom[randomSeed, Method -> "MersenneTwister"];
    While[Length[accepted] < pointCount && attempts < maximumAttempts,
      attempts++;
      point = If[candidatePoints === Automatic,
        RandomInteger[{2, prime - 2}, 2],
        candidateIndex++;
        If[candidateIndex > Length[candidatePoints], Break[]];
        candidatePoints[[candidateIndex]]];
      pointResult = drcaAssemblePointInternal[assembly, epsilonForms,
        prime, point, assembly["AssemblyFingerprint"]];
      If[Lookup[pointResult, "Status", None] ===
          "AssembledDirectRootChannelPointV1",
        pointKey = ToString[InputForm[Mod[point, prime]]];
        If[KeyExistsQ[acceptedPointKeys, pointKey],
          AppendTo[rejected, <|"Point" -> point,
            "FailureReason" -> "DuplicatePointModuloPrime"|>],
          AssociateTo[acceptedPointKeys, pointKey -> True];
          AppendTo[accepted, pointResult]],
        AppendTo[rejected, <|"Point" -> point,
          "FailureReason" -> Lookup[pointResult, "FailureReason", None]|>]]]
  ];
  If[Length[accepted] < pointCount,
    Return[drcaFailure["InsufficientDirectChannelPoints", <|
      "AcceptedPointCount" -> Length[accepted],
      "AttemptCount" -> attempts, "RejectedPoints" -> rejected|>]]];
  normalization = drcaNormalizationRows[assembly, epsilonValue, prime];
  If[normalization === $Failed,
    Return[drcaFailure["NormalizationValueSingular"]]];
  materializationStart = AbsoluteTime[];
  pointRows = Join @@ Lookup[accepted, "Rows"];
  pointRight = Join @@ Lookup[accepted, "RightHandSide"];
  matrix = Developer`ToPackedArray[Join[pointRows, normalization[[1]]]];
  right = Developer`ToPackedArray[Mod[
    Join[pointRight, normalization[[2]]], prime]];
  materializationSeconds = N[AbsoluteTime[] - materializationStart];
  equationCount = assembly["EquationsPerPoint"];
  pointRanges = Table[
    {1 + (index - 1) equationCount, index equationCount},
    {index, Length[accepted]}];
  totalSeconds = N[AbsoluteTime[] - startTime];
  sourceHashAfter = Quiet[Check[FileHash[assembly["PrototypeSourceFile"],
    "SHA256", "HexString"], $Failed]];
  If[sourceHashAfter =!= assembly["PrototypeSourceSHA256"],
    Return[drcaFailure["PrototypeSourceChangedDuringSampleAssembly"]]];
  <|"Status" -> "AssembledDirectRootChannelSampleV1",
    "ABIFingerprint" -> assembly["SourceABIFingerprint"],
    "AssemblyFingerprint" -> assembly["AssemblyFingerprint"],
    "PrototypeSourceSHA256" -> assembly["PrototypeSourceSHA256"],
    "Prime" -> prime, "EpsilonValue" -> epsilonValue,
    "EpsilonMod" -> epsilonForms["EpsilonMod"], "Matrix" -> matrix,
    "RightHandSide" -> right, "MatrixDimensions" -> Dimensions[matrix],
    "AcceptedPoints" -> Lookup[accepted, "Point"],
    "PointDeltaValues" -> Lookup[accepted, "DeltaValues"],
    "PointRowRanges" -> pointRanges, "AttemptCount" -> attempts,
    "RejectedPoints" -> rejected, "BranchFlipMask" -> flipMask,
    "NormalizationCount" -> Length[normalization[[1]]],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "ColumnOrder" -> assembly["ColumnOrder"],
    "RowOrder" -> assembly["RowOrder"],
    "Telemetry" -> <|"AssemblyValidationSeconds" ->
        N[validationSeconds],
      "EpsilonCollapseSeconds" -> N[collapseSeconds],
      "PointAssemblySeconds" -> Total[Lookup[accepted,
        "AssemblySeconds", 0]],
      "PointAssemblySecondsByPoint" -> Lookup[accepted,
        "AssemblySeconds", {}],
      "DenseMaterializationSeconds" -> materializationSeconds,
      "TotalSeconds" -> totalSeconds|>|>
];

DRCAAssembleSample[___] := drcaFailure["InvalidSampleAssemblyArguments"];

DRCASignTransform[rootValues_List, prime_Integer] := Module[
  {rank = Length[rootValues], gradeCount, rootProducts},
  If[! PrimeQ[prime] || rank > $drcaMaximumRootCount ||
      ! VectorQ[rootValues,
      IntegerQ[#1] && 0 < #1 < prime &], Return[$Failed]];
  gradeCount = 2^rank;
  rootProducts = drcaMaskFactorMod[#1, rootValues, prime] & /@
    Range[0, gradeCount - 1];
  Developer`ToPackedArray[Table[
    Mod[drcaCharacter[signMask, grade, rank]
      rootProducts[[grade + 1]], prime],
    {signMask, 0, gradeCount - 1},
    {grade, 0, gradeCount - 1}]]
];

DRCATransformPointToSigns[pointResult_Association, rootValues_List,
    prime_Integer, flipMask_Integer: 0] := Module[
  {rootCount, gradeCount, equationsPerGrade, unknownCount, deltaValues,
   pointRows, pointRight, transform, rowsByGrade, rightByGrade, rows,
   right, transformedRow, transformedRight, sourceSign, targetGrade},
  If[Lookup[pointResult, "Status", None] =!=
      "AssembledDirectRootChannelPointV1" ||
      Lookup[pointResult, "Prime", None] =!= prime,
    Return[drcaFailure["InvalidPointTransformInput"]]];
  rootCount = Lookup[pointResult, "RootCount", $Failed];
  gradeCount = Lookup[pointResult, "GradeCount", $Failed];
  equationsPerGrade = Lookup[pointResult, "EquationsPerGrade", $Failed];
  unknownCount = Lookup[pointResult, "UnknownCount", $Failed];
  deltaValues = Lookup[pointResult, "DeltaValues", $Failed];
  pointRows = Lookup[pointResult, "Rows", $Failed];
  pointRight = Lookup[pointResult, "RightHandSide", $Failed];
  If[! IntegerQ[rootCount] || rootCount < 0 ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! IntegerQ[equationsPerGrade] || equationsPerGrade < 1 ||
      ! IntegerQ[unknownCount] || unknownCount < 1 ||
      ! MatrixQ[pointRows, IntegerQ] ||
      Dimensions[pointRows] =!= {gradeCount equationsPerGrade,
        unknownCount} ||
      ! AllTrue[Flatten[pointRows], 0 <= #1 < prime &] ||
      ! VectorQ[pointRight, IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[pointRight] =!= gradeCount equationsPerGrade ||
      ! VectorQ[deltaValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Length[deltaValues] =!= rootCount ||
      Length[rootValues] =!= rootCount ||
      ! VectorQ[rootValues, IntegerQ[#1] && 0 < #1 < prime &] ||
      Mod[rootValues^2 - deltaValues, prime] =!=
        ConstantArray[0, rootCount] ||
      ! IntegerQ[flipMask] || flipMask < 0 || flipMask >= gradeCount,
    Return[drcaFailure["InvalidPointTransformParameters"]]];
  transform = DRCASignTransform[rootValues, prime];
  If[transform === $Failed, Return[drcaFailure["SignTransformFailed"]]];
  rowsByGrade = ArrayReshape[pointRows,
    {gradeCount, equationsPerGrade, unknownCount}];
  rightByGrade = ArrayReshape[pointRight,
    {gradeCount, equationsPerGrade}];
  rows = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRow = ConstantArray[0, unknownCount];
      Do[transformedRow = Mod[transformedRow +
          transform[[sourceSign + 1, targetGrade + 1]]
            rowsByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      Developer`ToPackedArray[transformedRow],
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  right = Flatten[Table[
    sourceSign = BitXor[signMask, flipMask];
    Table[
      transformedRight = 0;
      Do[transformedRight = Mod[transformedRight +
          transform[[sourceSign + 1, targetGrade + 1]]
            rightByGrade[[targetGrade + 1, equation]], prime],
        {targetGrade, 0, gradeCount - 1}];
      transformedRight,
      {equation, equationsPerGrade}],
    {signMask, 0, gradeCount - 1}], 1];
  <|"Status" -> "TransformedDirectPointToSplitSignsV1",
    "Prime" -> prime, "Point" -> pointResult["Point"],
    "RootValues" -> rootValues, "BranchFlipMask" -> flipMask,
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows],
    "SignTransform" -> transform|>
];

DRCATransformPointToSigns[___] :=
  drcaFailure["InvalidPointTransformArguments"];

DRCATransformSampleToSigns[assembly_Association, sample_Association,
    prime_Integer, flipMask_Integer: 0] := Module[
  {pointCount, equationCount, normalizationCount, pointResults,
   transformed, deltaValues, rootValues, rows, right, normalizationRows,
   normalizationRight, index, range, sourceHashAfter, expectedRanges,
   expectedPointRows, totalRows},
  If[! DRCAAssemblyPreparationValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3 ||
      Lookup[sample, "Status", None] =!=
        "AssembledDirectRootChannelSampleV1" ||
      Lookup[sample, "AssemblyFingerprint", None] =!=
        assembly["AssemblyFingerprint"] ||
      Lookup[sample, "PrototypeSourceSHA256", None] =!=
        assembly["PrototypeSourceSHA256"] || sample["Prime"] =!= prime,
    Return[drcaFailure["InvalidSampleTransformInput"]]];
  pointCount = Length[sample["AcceptedPoints"]];
  equationCount = assembly["EquationsPerPoint"];
  normalizationCount = Lookup[sample, "NormalizationCount", $Failed];
  expectedPointRows = pointCount equationCount;
  totalRows = expectedPointRows + normalizationCount;
  expectedRanges = Table[
    {1 + (index - 1) equationCount, index equationCount},
    {index, pointCount}];
  If[pointCount < 1 || ! IntegerQ[normalizationCount] ||
      normalizationCount < 0 ||
      ! MatchQ[sample["AcceptedPoints"], {{_Integer, _Integer} ..}] ||
      ! ListQ[Lookup[sample, "PointDeltaValues", None]] ||
      Length[sample["PointDeltaValues"]] =!= pointCount ||
      ! AllTrue[sample["PointDeltaValues"], Function[deltaVector,
        VectorQ[deltaVector, Function[value,
          IntegerQ[value] && 0 < value < prime]] &&
        Length[deltaVector] === assembly["RootCount"]]] ||
      Lookup[sample, "PointRowRanges", None] =!= expectedRanges ||
      ! MatrixQ[Lookup[sample, "Matrix", None], IntegerQ] ||
      Dimensions[sample["Matrix"]] =!=
        {totalRows, assembly["UnknownCount"]} ||
      ! AllTrue[Flatten[sample["Matrix"]], 0 <= #1 < prime &] ||
      ! VectorQ[Lookup[sample, "RightHandSide", None],
        IntegerQ[#1] && 0 <= #1 < prime &] ||
      Length[sample["RightHandSide"]] =!= totalRows,
    Return[drcaFailure["InvalidSampleTransformShape"]]];
  pointResults = Table[
    range = sample["PointRowRanges"][[index]];
    <|"Status" -> "AssembledDirectRootChannelPointV1",
      "Prime" -> prime, "Point" -> sample["AcceptedPoints"][[index]],
      "Rows" -> sample["Matrix"][[range[[1]] ;; range[[2]]]],
      "RightHandSide" ->
        sample["RightHandSide"][[range[[1]] ;; range[[2]]]],
      "DeltaValues" -> sample["PointDeltaValues"][[index]],
      "RootCount" -> assembly["RootCount"],
      "GradeCount" -> assembly["GradeCount"],
      "EquationsPerGrade" -> 2 Times @@ assembly["Dimensions"],
      "UnknownCount" -> assembly["UnknownCount"]|>,
    {index, pointCount}];
  transformed = Table[
    deltaValues = sample["PointDeltaValues"][[index]];
    If[! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
      Return[drcaFailure["PointNotSplitOverPrime", <|
        "PointIndex" -> index, "DeltaValues" -> deltaValues|>]]];
    rootValues = CodexTripleRoot`TRSquareRoots[deltaValues, prime];
    If[rootValues === $Failed,
      Return[drcaFailure["PointSquareRootFailure", <|
        "PointIndex" -> index|>]]];
    DRCATransformPointToSigns[pointResults[[index]], rootValues, prime,
      flipMask],
    {index, pointCount}];
  If[! AllTrue[transformed, Lookup[#1, "Status", None] ===
      "TransformedDirectPointToSplitSignsV1" &],
    Return[drcaFailure["SamplePointTransformFailed"]]];
  rows = Join @@ Lookup[transformed, "Rows"];
  right = Join @@ Lookup[transformed, "RightHandSide"];
  If[normalizationCount > 0,
    normalizationRows = Take[sample["Matrix"], -normalizationCount];
    normalizationRight = Take[sample["RightHandSide"],
      -normalizationCount];
    rows = Join[rows, normalizationRows];
    right = Join[right, normalizationRight]];
  sourceHashAfter = Quiet[Check[FileHash[assembly["PrototypeSourceFile"],
    "SHA256", "HexString"], $Failed]];
  If[sourceHashAfter =!= assembly["PrototypeSourceSHA256"] ||
      sourceHashAfter =!= $drcaSourceSHA256,
    Return[drcaFailure["PrototypeSourceChangedDuringSampleTransform"]]];
  <|"Status" -> "TransformedDirectSampleToSplitSignsV1",
    "Prime" -> prime, "AssemblyFingerprint" ->
      assembly["AssemblyFingerprint"],
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows],
    "BranchFlipMask" -> flipMask|>
];

DRCATransformSampleToSigns[___] :=
  drcaFailure["InvalidSampleTransformArguments"];

DRCADifferentialCheckPoint[assembly_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    flipMask_Integer: 0] := Module[
  {startTime = AbsoluteTime[], epsilonForms, direct, deltaValues,
   rootValues, transformed, legacyStart, legacy, legacySeconds,
   equationsPerSign, order, legacyRows, legacyRight, matrixEqual,
   rightEqual, sourceHashAfter, passed},
  If[! DRCAAssemblyPreparationValidQ[assembly] || ! PrimeQ[prime] ||
      Mod[prime, 4] =!= 3 ||
      ! drcaAssemblySourceStableQ[assembly],
    Return[drcaFailure["InvalidDifferentialAssembly"]]];
  epsilonForms = drcaCollapseEpsilonValidated[
    assembly, prime, epsilonValue];
  If[! AssociationQ[epsilonForms] ||
      ! drcaEpsilonFormsValidQ[assembly, epsilonForms, prime],
    Return[drcaFailure["DifferentialEpsilonFormCollapseFailed"]]];
  direct = drcaAssemblePointInternal[assembly, epsilonForms, prime, point,
    assembly["AssemblyFingerprint"]];
  If[Lookup[direct, "Status", None] =!=
      "AssembledDirectRootChannelPointV1", Return[direct]];
  deltaValues = direct["DeltaValues"];
  If[! AllTrue[deltaValues, JacobiSymbol[#1, prime] === 1 &],
    Return[drcaFailure["DifferentialPointNotSplit", <|
      "DeltaValues" -> deltaValues|>]]];
  rootValues = CodexTripleRoot`TRSquareRoots[deltaValues, prime];
  If[rootValues === $Failed,
    Return[drcaFailure["DifferentialSquareRootFailure"]]];
  transformed = DRCATransformPointToSigns[direct, rootValues, prime,
    flipMask];
  If[Lookup[transformed, "Status", None] =!=
      "TransformedDirectPointToSplitSignsV1", Return[transformed]];
  legacyStart = AbsoluteTime[];
  legacy = Quiet[CodexTripleRootPilot`TRSplitPointRows[
    assembly["Record"], assembly["Roots"], assembly["OneForms"],
    assembly["GaugeDenominator"], assembly["GaugeSupport"],
    epsilonValue, prime, point]];
  legacySeconds = N[AbsoluteTime[] - legacyStart];
  If[! AssociationQ[legacy],
    Return[drcaFailure["LegacySplitPointAssemblyFailed"]]];
  equationsPerSign = 2 Times @@ assembly["Dimensions"];
  order = Flatten[Table[Range[
      BitXor[signMask, flipMask] equationsPerSign + 1,
      (BitXor[signMask, flipMask] + 1) equationsPerSign],
    {signMask, 0, assembly["GradeCount"] - 1}]];
  legacyRows = Developer`ToPackedArray[
    Mod[Normal /@ legacy["Rows"][[order]], prime]];
  legacyRight = Developer`ToPackedArray[
    Mod[legacy["RightHandSide"][[order]], prime]];
  matrixEqual = TrueQ[transformed["Rows"] === legacyRows];
  rightEqual = TrueQ[transformed["RightHandSide"] === legacyRight];
  sourceHashAfter = Quiet[Check[FileHash[assembly["PrototypeSourceFile"],
    "SHA256", "HexString"], $Failed]];
  passed = TrueQ[matrixEqual && rightEqual &&
    sourceHashAfter === assembly["PrototypeSourceSHA256"] &&
    sourceHashAfter === $drcaSourceSHA256];
  <|"Status" -> If[passed,
      "DirectLegacyPointDifferentialPassed",
      "DirectLegacyPointDifferentialFailed"],
    "Passed" -> passed,
    "MatrixEqual" -> matrixEqual, "RightHandSideEqual" -> rightEqual,
    "Prime" -> prime, "EpsilonValue" -> epsilonValue,
    "Point" -> point, "RootCount" -> assembly["RootCount"],
    "BranchFlipMask" -> flipMask,
    "PrototypeSourceSHA256" -> assembly["PrototypeSourceSHA256"],
    "SourceHashStableAtCompletion" ->
      TrueQ[sourceHashAfter === assembly["PrototypeSourceSHA256"]],
    "Telemetry" -> <|"DirectPointSeconds" -> direct["AssemblySeconds"],
      "LegacyPointSeconds" -> legacySeconds,
      "TotalSeconds" -> N[AbsoluteTime[] - startTime]|>|>
];

DRCADifferentialCheckPoint[___] :=
  drcaFailure["InvalidDifferentialPointArguments"];

DRCAClearCaches[] := ($drcaPrimeCache = <||>; $drcaEpsilonCache = <||>;
  <|"Status" -> "DirectRootChannelCachesCleared"|>);

End[];
EndPackage[];
