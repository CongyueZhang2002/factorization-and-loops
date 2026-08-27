BeginPackage["CodexDirectRootChannelCompilerV2`", {
  "CodexTripleRoot`", "CodexTripleRootStrip`",
  "CodexTripleRootReconstruction`",
  "CodexDirectRootChannelAssembler`"}];

DRCAV2CompileCore::usage =
  "DRCAV2CompileCore[record,roots,gaugeDenominator,metadata] compiles the ansatz-independent direct-channel equation core with pooled exact scalars and polynomials.";
DRCAV2InstantiateAnsatz::usage =
  "DRCAV2InstantiateAnsatz[core,oneForms,support,normalizations] compiles only the ansatz-dependent one-forms and creates a source-bound V1 compatibility assembly.";
DRCAV2RebindAnsatz::usage =
  "DRCAV2RebindAnsatz[assembly,oneForms,support,normalizations] reuses the core and, for a one-form prefix extension, compiles only the appended forms.";
DRCAV2CompileSystem::usage =
  "DRCAV2CompileSystem[record,roots,oneForms,gaugeDenominator,support,normalizations,metadata] runs the V2 core/ansatz pipeline.";
DRCAV2Prepare::usage =
  "DRCAV2Prepare[preparation] validates a PreparedReconstruction object and compiles it through the V2 pipeline.";
DRCAV2CoreValidQ::usage =
  "DRCAV2CoreValidQ[core] fully validates a V2 equation core and its source bindings.";
DRCAV2AssemblyValidQ::usage =
  "DRCAV2AssemblyValidQ[assembly] fully validates a V2 assembly, core, polynomial pool and V1 compatibility view.";
DRCAV2ToV1Assembly::usage =
  "DRCAV2ToV1Assembly[assembly] returns the independently validated PreparedDirectRootChannelsV1 compatibility view.";

Begin["`Private`"];

ClearAll[
  drcav2Failure, drcav2StableFingerprint, drcav2ZeroQ,
  drcav2CompilePolynomialCanonical, drcav2PolynomialExpression,
  drcav2PolynomialPoolCreate, drcav2PolynomialPoolIntern,
  drcav2PolynomialPoolSeed, drcav2PolynomialPoolValidQ,
  drcav2ScalarPoolCreate, drcav2ScalarPoolIntern,
  drcav2CanonicalPair, drcav2RecursiveFieldInverse,
  drcav2DecomposeCanonical, drcav2CompilePairs,
  drcav2CompileBundle, drcav2BundleTelemetry,
  drcav2ColumnOrderPayload, drcav2RowOrderPayload,
  drcav2V1SemanticPayload, drcav2CoreSemanticPayload,
  drcav2AssemblySemanticPayload, drcav2BuildV1Compatibility,
  drcav2FinalizeAssembly, drcav2ValidSupportQ,
  drcav2ValidNormalizationsQ, drcav2CoreSourceStableQ,
  drcav2AssemblySourceStableQ, $drcav2SourceFile,
  $drcav2SourceSHA256, $drcav2V1SourceFile, $drcav2V1SourceSHA256
];

$drcav2SourceFile = ExpandFileName[$InputFileName];
$drcav2SourceSHA256 = FileHash[$drcav2SourceFile, "SHA256", "HexString"];
$drcav2V1SourceFile =
  CodexDirectRootChannelAssembler`Private`$drcaSourceFile;
$drcav2V1SourceSHA256 =
  CodexDirectRootChannelAssembler`Private`$drcaSourceSHA256;
$drcav2MaximumRootCount = 3;
$drcav2MaximumEpsilonDegree = 256;

drcav2Failure[reason_String, data_: <||>] := Join[
  <|"Status" -> "DirectRootChannelCompilerV2Failure",
    "FailureReason" -> reason|>, data];

drcav2StableFingerprint[value_] := Hash[
  ToString[InputForm[value]], "SHA256", "HexString"];

drcav2ZeroQ[value_] := AllTrue[Flatten[{value}],
  TrueQ[Together[#1] === 0] &];

drcav2ValidSupportQ[support_] := TrueQ[
  ListQ[support] && support =!= {} && DuplicateFreeQ[support] &&
  AllTrue[support,
    MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &]];

drcav2ValidNormalizationsQ[normalizations_, unknownCount_Integer] := TrueQ[
  ListQ[normalizations] &&
  AllTrue[normalizations, AssociationQ[#1] &&
    IntegerQ[Lookup[#1, "Column", None]] &&
    1 <= #1["Column"] <= unknownCount && KeyExistsQ[#1, "Value"] &] &&
  DuplicateFreeQ[Lookup[normalizations, "Column", {}]]];

(* This accepts an already canonical, expanded polynomial.  It never calls
   Together and never recanonicalizes a rational expression. *)
drcav2CompilePolynomialCanonical[polynomial_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {vars = Append[variables, epsilon], rules, groups, xExponents,
   yExponents, maximumEpsilonDegree, coefficientRows},
  If[! PolynomialQ[polynomial, vars], Return[$Failed]];
  rules = CoefficientRules[polynomial, vars];
  If[rules === {}, Return[<|
    "Type" -> "DRCAPolynomialExactV1", "XExponents" -> {},
    "YExponents" -> {}, "EpsilonCoefficientRows" -> {}|>]];
  If[! AllTrue[Last /@ rules,
      IntegerQ[#1] || Head[#1] === Rational &], Return[$Failed]];
  maximumEpsilonDegree = Max[rules[[All, 1, 3]]];
  If[maximumEpsilonDegree > $drcav2MaximumEpsilonDegree,
    Return[$Failed]];
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

drcav2PolynomialExpression[compiled_Association,
    variables : {x_Symbol, y_Symbol}, epsilon_Symbol] := Module[
  {xExponents, yExponents, rows},
  If[Lookup[compiled, "Type", None] =!= "DRCAPolynomialExactV1",
    Return[$Failed]];
  xExponents = Lookup[compiled, "XExponents", $Failed];
  yExponents = Lookup[compiled, "YExponents", $Failed];
  rows = Lookup[compiled, "EpsilonCoefficientRows", $Failed];
  If[! ListQ[xExponents] || ! ListQ[yExponents] || ! ListQ[rows] ||
      Length[xExponents] =!= Length[yExponents] ||
      Length[xExponents] =!= Length[rows], Return[$Failed]];
  Total[MapThread[
    Function[{xExponent, yExponent, row},
      x^xExponent y^yExponent Sum[
        row[[degree + 1]] epsilon^degree,
        {degree, 0, Length[row] - 1}]],
    {xExponents, yExponents, rows}]]
];

drcav2PolynomialPoolCreate[seed_: Automatic] := Module[
  {pool, values, compiled, buckets = <||>, key},
  If[seed === Automatic,
    Return[<|"Values" -> {}, "Compiled" -> {}, "Buckets" -> <||>,
      "Hits" -> 0, "Misses" -> 0, "CollisionChecks" -> 0|>]];
  values = Lookup[seed, "Values", $Failed];
  compiled = Lookup[seed, "Compiled", $Failed];
  If[! ListQ[values] || ! ListQ[compiled] ||
      Length[values] =!= Length[compiled], Return[$Failed]];
  Do[
    key = Hash[values[[index]], "SHA256", "HexString"];
    AssociateTo[buckets, key -> Append[Lookup[buckets, key, {}], index]],
    {index, Length[values]}];
  pool = <|"Values" -> values, "Compiled" -> compiled,
    "Buckets" -> buckets, "Hits" -> 0, "Misses" -> 0,
    "CollisionChecks" -> 0|>;
  pool
];

SetAttributes[drcav2PolynomialPoolIntern, HoldFirst];
drcav2PolynomialPoolIntern[pool_Symbol, polynomial_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {key, bucket, buckets, matched, compiled, rebuilt, index},
  key = Hash[polynomial, "SHA256", "HexString"];
  bucket = Lookup[pool["Buckets"], key, {}];
  AssociateTo[pool, "CollisionChecks" ->
    (pool["CollisionChecks"] + Length[bucket])];
  matched = SelectFirst[bucket,
    SameQ[pool["Values"][[#1]], polynomial] &, Missing["NotFound"]];
  If[! MissingQ[matched],
    AssociateTo[pool, "Hits" -> (pool["Hits"] + 1)];
    Return[pool["Compiled"][[matched]]]];
  compiled = drcav2CompilePolynomialCanonical[polynomial,
    variables, epsilon];
  If[compiled === $Failed, Return[$Failed]];
  rebuilt = drcav2PolynomialExpression[compiled, variables, epsilon];
  If[rebuilt === $Failed || ! SameQ[Expand[rebuilt], polynomial],
    Return[$Failed]];
  index = Length[pool["Values"]] + 1;
  AssociateTo[pool,
    "Values" -> Append[pool["Values"], polynomial],
    "Compiled" -> Append[pool["Compiled"], compiled],
    "Misses" -> (pool["Misses"] + 1)];
  buckets = pool["Buckets"];
  AssociateTo[buckets, key -> Append[bucket, index]];
  AssociateTo[pool, "Buckets" -> buckets];
  compiled
];

drcav2PolynomialPoolSeed[pool_Association] := <|
  "Values" -> pool["Values"], "Compiled" -> pool["Compiled"]|>;

drcav2PolynomialPoolValidQ[seed_Association,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {values, compiled, rebuilt},
  values = Lookup[seed, "Values", $Failed];
  compiled = Lookup[seed, "Compiled", $Failed];
  If[! ListQ[values] || ! ListQ[compiled] ||
      Length[values] =!= Length[compiled], Return[False]];
  TrueQ[And @@ Table[
    rebuilt = drcav2PolynomialExpression[compiled[[index]],
      variables, epsilon];
    rebuilt =!= $Failed && SameQ[Expand[rebuilt], values[[index]]],
    {index, Length[values]}]]
];

drcav2ScalarPoolCreate[] := <|
  "Values" -> {}, "Buckets" -> <||>, "Hits" -> 0, "Misses" -> 0,
  "CollisionChecks" -> 0|>;

SetAttributes[drcav2ScalarPoolIntern, HoldFirst];
drcav2ScalarPoolIntern[pool_Symbol, expression_] := Module[
  {key, bucket, buckets, matched, index},
  key = Hash[expression, "SHA256", "HexString"];
  bucket = Lookup[pool["Buckets"], key, {}];
  AssociateTo[pool, "CollisionChecks" ->
    (pool["CollisionChecks"] + Length[bucket])];
  matched = SelectFirst[bucket,
    SameQ[pool["Values"][[#1]], expression] &, Missing["NotFound"]];
  If[! MissingQ[matched],
    AssociateTo[pool, "Hits" -> (pool["Hits"] + 1)];
    Return[matched]];
  index = Length[pool["Values"]] + 1;
  AssociateTo[pool,
    "Values" -> Append[pool["Values"], expression],
    "Misses" -> (pool["Misses"] + 1)];
  buckets = pool["Buckets"];
  AssociateTo[buckets, key -> Append[bucket, index]];
  AssociateTo[pool, "Buckets" -> buckets];
  index
];

drcav2CanonicalPair[rational_] := Module[{numerator, denominator},
  If[! FreeQ[rational,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  numerator = Expand[Numerator[rational]];
  denominator = Expand[Denominator[rational]];
  If[TrueQ[denominator === 0], Return[$Failed]];
  <|"Type" -> "DRCACanonicalRationalPairV2",
    "Numerator" -> numerator, "Denominator" -> denominator|>
];

(* Recursive tower inversion.  For a=u+v r and r^2=delta,
   a^-1=(u-v r) (u^2-delta v^2)^-1.  Every level is followed by an
   independent full algebra product check; there is no dense fallback. *)
drcav2RecursiveFieldInverse[a_List, deltas_List,
    inputStatistics_Association] := Module[
  {rank = Length[deltas], dimension = Length[a], half, lowerDeltas,
   delta, u, v, uSquare, vSquare, norm, normInverse, left, right,
   candidate, check, recursive, statistics = inputStatistics},
  If[dimension =!= 2^rank, Return[$Failed]];
  AssociateTo[statistics, "RecursiveInverseCalls" ->
    (Lookup[statistics, "RecursiveInverseCalls", 0] + 1)];
  AssociateTo[statistics, "MaximumInverseRank" -> Max[
    Lookup[statistics, "MaximumInverseRank", 0], rank]];
  If[rank === 0,
    If[TrueQ[Together[First[a]] === 0], Return[$Failed]];
    candidate = {Together[1/First[a]]};
    check = {Together[First[a] First[candidate]]};
    AssociateTo[statistics, "IndependentInverseChecks" ->
      (Lookup[statistics, "IndependentInverseChecks", 0] + 1)];
    Return[If[drcav2ZeroQ[check - {1}],
      <|"Inverse" -> candidate, "Statistics" -> statistics|>, $Failed]]];
  half = Quotient[dimension, 2];
  lowerDeltas = Most[deltas];
  delta = Last[deltas];
  u = Take[a, half];
  v = Drop[a, half];
  uSquare = CodexTripleRoot`TRMultiply[u, u, lowerDeltas];
  vSquare = CodexTripleRoot`TRMultiply[v, v, lowerDeltas];
  If[! ListQ[uSquare] || ! ListQ[vSquare], Return[$Failed]];
  norm = MapThread[Together[#1 - delta #2] &,
    {uSquare, vSquare}];
  recursive = drcav2RecursiveFieldInverse[
    norm, lowerDeltas, statistics];
  If[recursive === $Failed, Return[$Failed]];
  normInverse = recursive["Inverse"];
  statistics = recursive["Statistics"];
  left = CodexTripleRoot`TRMultiply[u, normInverse, lowerDeltas];
  right = CodexTripleRoot`TRMultiply[v, normInverse, lowerDeltas];
  If[! ListQ[left] || ! ListQ[right], Return[$Failed]];
  candidate = Join[Together /@ left, Together[-#1] & /@ right];
  check = CodexTripleRoot`TRMultiply[a, candidate, deltas];
  AssociateTo[statistics, "IndependentInverseChecks" ->
    (Lookup[statistics, "IndependentInverseChecks", 0] + 1)];
  If[ListQ[check] && drcav2ZeroQ[
      check - UnitVector[dimension, 1]],
    <|"Inverse" -> candidate, "Statistics" -> statistics|>, $Failed]
];

drcav2DecomposeCanonical[expression_, roots_List,
    inputStatistics_Association] := Module[
  {rank = Length[roots], deltas, symbols, replaced, rational,
   numerator, denominator, numeratorChannels, denominatorChannels,
   denominatorInverse, inverseResult, channels, reconstructed, pairs,
   statistics = inputStatistics},
  If[rank === 0,
    AssociateTo[statistics, "RootFreeFastPathCount" ->
      (Lookup[statistics, "RootFreeFastPathCount", 0] + 1)];
    rational = Together[expression];
    If[! FreeQ[rational,
        Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
      Return[$Failed]];
    If[! TrueQ[Together[rational - expression] === 0],
      Return[$Failed]];
    pairs = {drcav2CanonicalPair[rational]};
    If[MemberQ[pairs, $Failed], Return[$Failed]];
    AssociateTo[statistics, "IndependentRoundTripChecks" ->
      (Lookup[statistics, "IndependentRoundTripChecks", 0] + 1)];
    Return[<|"Channels" -> {rational}, "Pairs" -> pairs,
      "Path" -> "RootFree", "Statistics" -> statistics|>]];
  AssociateTo[statistics, "AlgebraicPathCount" ->
    (Lookup[statistics, "AlgebraicPathCount", 0] + 1)];
  deltas = Together /@ Lookup[roots, "RootSquare", {}];
  symbols = Table[Unique["drcav2Root$"], {rank}];
  replaced = CodexTripleRootStrip`TRApplyRootBranches[
    expression, roots, symbols];
  If[! FreeQ[replaced,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  rational = Together[replaced];
  numerator = Numerator[rational];
  denominator = Denominator[rational];
  If[! PolynomialQ[numerator, symbols] ||
      ! PolynomialQ[denominator, symbols], Return[$Failed]];
  numeratorChannels = CodexTripleRoot`TRFromPolynomial[
    numerator, symbols, deltas];
  denominatorChannels = CodexTripleRoot`TRFromPolynomial[
    denominator, symbols, deltas];
  If[! ListQ[numeratorChannels] || ! ListQ[denominatorChannels],
    Return[$Failed]];
  inverseResult = drcav2RecursiveFieldInverse[
    denominatorChannels, deltas, statistics];
  If[inverseResult === $Failed, Return[$Failed]];
  denominatorInverse = inverseResult["Inverse"];
  statistics = inverseResult["Statistics"];
  channels = CodexTripleRoot`TRMultiply[
    numeratorChannels, denominatorInverse, deltas];
  If[! ListQ[channels] || Length[channels] =!= 2^rank,
    Return[$Failed]];
  channels = Together /@ channels;
  reconstructed = CodexTripleRootStrip`TRFieldCompose[channels, roots];
  AssociateTo[statistics, "IndependentRoundTripChecks" ->
    (Lookup[statistics, "IndependentRoundTripChecks", 0] + 1)];
  If[! TrueQ[Together[reconstructed - expression] === 0],
    Return[$Failed]];
  pairs = drcav2CanonicalPair /@ channels;
  If[MemberQ[pairs, $Failed], Return[$Failed]];
  <|"Channels" -> channels, "Pairs" -> pairs,
    "Path" -> "RecursiveMultiquadraticNorm",
    "Statistics" -> statistics|>
];

SetAttributes[drcav2CompilePairs, HoldFirst];
drcav2CompilePairs[polynomialPool_Symbol, pairs_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {compiled},
  compiled = Table[
    If[Lookup[pair, "Type", None] =!= "DRCACanonicalRationalPairV2",
      Return[$Failed]];
    With[{numerator = drcav2PolynomialPoolIntern[
          polynomialPool, pair["Numerator"], variables, epsilon],
        denominator = drcav2PolynomialPoolIntern[
          polynomialPool, pair["Denominator"], variables, epsilon]},
      If[numerator === $Failed || denominator === $Failed ||
          denominator["EpsilonCoefficientRows"] === {},
        Return[$Failed]];
      <|"Type" -> "DRCARationalExactV1", "Numerator" -> numerator,
        "Denominator" -> denominator|>],
    {pair, pairs}];
  compiled
];

drcav2BundleTelemetry[scalarPool_Association,
    polynomialPoolBefore_Association, polynomialPoolAfter_Association,
    statistics_Association] := <|
  "ScalarOccurrences" -> scalarPool["Hits"] + scalarPool["Misses"],
  "UniqueScalars" -> scalarPool["Misses"],
  "ScalarPoolHits" -> scalarPool["Hits"],
  "ScalarCollisionChecks" -> scalarPool["CollisionChecks"],
  "PolynomialPoolHitsThisBundle" ->
    polynomialPoolAfter["Hits"] - polynomialPoolBefore["Hits"],
  "PolynomialPoolMissesThisBundle" ->
    polynomialPoolAfter["Misses"] - polynomialPoolBefore["Misses"],
  "PolynomialCollisionChecksThisBundle" ->
    polynomialPoolAfter["CollisionChecks"] -
      polynomialPoolBefore["CollisionChecks"],
  "RootFreeFastPathCount" -> Lookup[statistics,
    "RootFreeFastPathCount", 0],
  "AlgebraicPathCount" -> Lookup[statistics, "AlgebraicPathCount", 0],
  "RecursiveInverseCalls" -> Lookup[statistics,
    "RecursiveInverseCalls", 0],
  "MaximumInverseRank" -> Lookup[statistics, "MaximumInverseRank", 0],
  "IndependentInverseChecks" -> Lookup[statistics,
    "IndependentInverseChecks", 0],
  "IndependentRoundTripChecks" -> Lookup[statistics,
    "IndependentRoundTripChecks", 0]|>;

(* specs[name] = <|"Tensor"->..., "ScalarLevel"->n|>.  All tensors in
   one bundle share a root basis, while the polynomial pool may be seeded by
   a previous bundle or equation core. *)
drcav2CompileBundle[specs_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    seed_: Automatic] := Module[
  {scalarPool = drcav2ScalarPoolCreate[], polynomialPool,
   polynomialPoolBefore, statistics = <||>, names, indexed,
   decomposed = {}, decomposition, compiledByID, exact, compiled, level,
   result},
  polynomialPool = drcav2PolynomialPoolCreate[seed];
  If[polynomialPool === $Failed, Return[$Failed]];
  polynomialPoolBefore = polynomialPool;
  names = Keys[specs];
  If[! AllTrue[names, AssociationQ[specs[#1]] &&
      KeyExistsQ[specs[#1], "Tensor"] &&
      IntegerQ[Lookup[specs[#1], "ScalarLevel", None]] &&
      specs[#1]["ScalarLevel"] >= 0 &], Return[$Failed]];
  indexed = AssociationMap[
    Function[name,
      level = specs[name]["ScalarLevel"];
      Map[drcav2ScalarPoolIntern[scalarPool, #1] &,
        specs[name]["Tensor"], {level}]], names];
  Do[
    decomposition = drcav2DecomposeCanonical[value, roots, statistics];
    If[decomposition === $Failed, Return[$Failed]];
    statistics = decomposition["Statistics"];
    AppendTo[decomposed, KeyDrop[decomposition, "Statistics"]],
    {value, scalarPool["Values"]}];
  compiledByID = Table[
    drcav2CompilePairs[polynomialPool,
      decomposed[[index, "Pairs"]], variables, epsilon],
    {index, Length[decomposed]}];
  If[MemberQ[compiledByID, $Failed], Return[$Failed]];
  exact = AssociationMap[
    Function[name,
      level = specs[name]["ScalarLevel"];
      Map[decomposed[[#1, "Channels"]] &, indexed[name], {level}]],
    names];
  compiled = AssociationMap[
    Function[name,
      level = specs[name]["ScalarLevel"];
      Map[compiledByID[[#1]] &, indexed[name], {level}]], names];
  result = <|"Exact" -> exact, "Compiled" -> compiled,
    "PolynomialPool" -> polynomialPool,
    "Telemetry" -> drcav2BundleTelemetry[scalarPool,
      polynomialPoolBefore, polynomialPool, statistics]|>;
  result
];

drcav2ColumnOrderPayload[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

drcav2RowOrderPayload[dimensions_List, gradeCount_Integer] := <|
  "PointRows" -> "{outputGrade0Based,direction,upperRow,lowerColumn}",
  "RowIndexFormula" ->
    "(((grade*2+(mu-1)) upper+(i-1)) lower+j)",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount|>;

drcav2V1SemanticPayload[assembly_Association] := KeyTake[assembly, {
  "SourceABIFingerprint", "RootOrderingFingerprint", "RootCount",
  "GradeCount", "Dimensions", "GaugeSupport", "OneForms",
  "GaugeDenominator", "Normalizations", "GaugeUnknownCount",
  "ResidueUnknownCount", "UnknownCount", "EquationsPerPoint",
  "ColumnOrder", "RowOrder", "ExactChannelFormsFingerprint",
  "CompiledFormsFingerprint", "CompiledFormsShapeFingerprint",
  "SourceSemanticFingerprint", "PrototypeSourceSHA256"}];

drcav2CoreSemanticPayload[core_Association] := KeyTake[core, {
  "Status", "FormatVersion", "CompilerSourceSHA256",
  "V1AdapterSourceSHA256", "SourceABIFingerprint",
  "RootOrderingFingerprint", "RootCount", "GradeCount", "Variables",
  "Regulator", "Dimensions", "GaugeDenominator",
  "ExactCoreFormsFingerprint", "CompiledCoreFormsFingerprint",
  "PolynomialPoolFingerprint", "SourceSemanticFingerprint"}];

drcav2AssemblySemanticPayload[assembly_Association] := KeyTake[assembly, {
  "Status", "FormatVersion", "CompilerSourceSHA256",
  "V1AdapterSourceSHA256", "CoreFingerprint", "SourceABIFingerprint",
  "RootOrderingFingerprint", "OneForms", "GaugeSupport",
  "Normalizations", "PolynomialPoolFingerprint",
  "V1AssemblyFingerprint"}];

drcav2CoreSourceStableQ[core_Association] := TrueQ[
  Quiet[Check[FileHash[core["CompilerSourceFile"], "SHA256",
    "HexString"], $Failed]] === core["CompilerSourceSHA256"] ===
      $drcav2SourceSHA256 &&
  Quiet[Check[FileHash[core["V1AdapterSourceFile"], "SHA256",
    "HexString"], $Failed]] === core["V1AdapterSourceSHA256"] ===
      $drcav2V1SourceSHA256];

DRCAV2CompileCore[record_Association, roots_List, gaugeDenominator_,
    metadata_: <||>] := Module[
  {start = AbsoluteTime[], variables, epsilon, strip, e, c, bbar,
   dimensions, rootSquares, rootLogs, gaugeCanonical,
   algebraicBundle, rationalBundle, algebraicSeconds, rationalSeconds,
   exact, compiled, polynomialSeed, sourceABIFingerprint,
   rootOrderingFingerprint, core, fingerprintSeconds,
   fingerprintStart},
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[epsilon, _Symbol] || ! MatchQ[strip, {_List, _List, _List}] ||
      ! AssociationQ[metadata] ||
      Length[roots] > $drcav2MaximumRootCount ||
      ! AllTrue[roots, AssociationQ[#1] &&
        KeyExistsQ[#1, "Root"] && KeyExistsQ[#1, "RootSquare"] &&
        TrueQ[Together[#1["Root"]^2 - #1["RootSquare"]] === 0] &],
    Return[drcav2Failure["InvalidCoreInput"]]];
  If[! DuplicateFreeQ[Lookup[roots, "RootSquare", {}],
      TrueQ[Together[#1 - #2] === 0] &],
    Return[drcav2Failure["DuplicateRootSquares"]]];
  {e, c, bbar} = strip;
  If[Length[bbar] =!= 2 || ! AllTrue[bbar, ListQ],
    Return[drcav2Failure["InvalidCoreDimensions"]]];
  dimensions = Dimensions[bbar[[1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      Dimensions[bbar] =!= Prepend[dimensions, 2] ||
      Dimensions[e] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[c] =!= {2, dimensions[[2]], dimensions[[2]]},
    Return[drcav2Failure["InvalidCoreDimensions"]]];
  rootSquares = Together /@ Lookup[roots, "RootSquare", {}];
  rootLogs = Table[
    Together[D[rootSquares[[root]], variables[[direction]]] /
      rootSquares[[root]]],
    {root, Length[rootSquares]}, {direction, 2}];
  gaugeCanonical = Together[gaugeDenominator];
  If[TrueQ[gaugeCanonical === 0] || ! FreeQ[gaugeCanonical,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[drcav2Failure["NonRationalGaugeDenominator"]]];
  {algebraicSeconds, algebraicBundle} = AbsoluteTiming[
    drcav2CompileBundle[<|
      "E" -> <|"Tensor" -> e, "ScalarLevel" -> 3|>,
      "C" -> <|"Tensor" -> c, "ScalarLevel" -> 3|>,
      "BBar" -> <|"Tensor" -> bbar, "ScalarLevel" -> 3|>|>,
      roots, variables, epsilon]];
  If[algebraicBundle === $Failed,
    Return[drcav2Failure["AlgebraicCoreCompilationFailed"]]];
  {rationalSeconds, rationalBundle} = AbsoluteTiming[
    drcav2CompileBundle[<|
      "RootSquares" -> <|"Tensor" -> rootSquares,
        "ScalarLevel" -> 1|>,
      "RootLogDerivatives" -> <|"Tensor" -> rootLogs,
        "ScalarLevel" -> 2|>,
      "GaugeDenominator" -> <|"Tensor" -> {gaugeCanonical},
        "ScalarLevel" -> 1|>,
      "GaugeLogDerivatives" -> <|"Tensor" -> {
        Together[D[gaugeCanonical, variables[[1]]] / gaugeCanonical],
        Together[D[gaugeCanonical, variables[[2]]] / gaugeCanonical]},
        "ScalarLevel" -> 1|>|>, {}, variables, epsilon,
      drcav2PolynomialPoolSeed[algebraicBundle["PolynomialPool"]]]];
  If[rationalBundle === $Failed,
    Return[drcav2Failure["RationalCoreCompilationFailed"]]];
  exact = <|
    "E" -> algebraicBundle["Exact", "E"],
    "C" -> algebraicBundle["Exact", "C"],
    "BBar" -> algebraicBundle["Exact", "BBar"],
    "RootSquares" -> (First /@ rationalBundle["Exact", "RootSquares"]),
    "RootLogDerivatives" -> Map[First,
      rationalBundle["Exact", "RootLogDerivatives"], {2}],
    "GaugeDenominator" ->
      First[First[rationalBundle["Exact", "GaugeDenominator"]]],
    "GaugeLogDerivatives" ->
      First /@ rationalBundle["Exact", "GaugeLogDerivatives"]|>;
  compiled = <|
    "E" -> algebraicBundle["Compiled", "E"],
    "C" -> algebraicBundle["Compiled", "C"],
    "BBar" -> algebraicBundle["Compiled", "BBar"],
    "RootSquares" ->
      (First /@ rationalBundle["Compiled", "RootSquares"]),
    "RootLogDerivatives" -> Map[First,
      rationalBundle["Compiled", "RootLogDerivatives"], {2}],
    "GaugeDenominator" ->
      First[First[rationalBundle["Compiled", "GaugeDenominator"]]],
    "GaugeLogDerivatives" ->
      First /@ rationalBundle["Compiled", "GaugeLogDerivatives"]|>;
  polynomialSeed = drcav2PolynomialPoolSeed[
    rationalBundle["PolynomialPool"]];
  sourceABIFingerprint = Lookup[metadata, "SourceABIFingerprint",
    drcav2StableFingerprint[{record, roots, gaugeCanonical}]];
  rootOrderingFingerprint = Lookup[metadata, "RootOrderingFingerprint",
    drcav2StableFingerprint[rootSquares]];
  If[! StringQ[sourceABIFingerprint] ||
      ! StringQ[rootOrderingFingerprint],
    Return[drcav2Failure["InvalidCoreFingerprintMetadata"]]];
  fingerprintStart = AbsoluteTime[];
  core = <|
    "Status" -> "PreparedDirectRootChannelCoreV2",
    "FormatVersion" -> 2,
    "CompilerSourceFile" -> $drcav2SourceFile,
    "CompilerSourceSHA256" -> $drcav2SourceSHA256,
    "V1AdapterSourceFile" -> $drcav2V1SourceFile,
    "V1AdapterSourceSHA256" -> $drcav2V1SourceSHA256,
    "SourceABIFingerprint" -> sourceABIFingerprint,
    "RootOrderingFingerprint" -> rootOrderingFingerprint,
    "Record" -> record, "Roots" -> roots,
    "RootCount" -> Length[roots], "GradeCount" -> 2^Length[roots],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "GaugeDenominator" -> gaugeCanonical,
    "ExactCoreForms" -> exact, "CompiledCoreForms" -> compiled,
    "ExactCoreFormsFingerprint" -> drcav2StableFingerprint[exact],
    "CompiledCoreFormsFingerprint" -> drcav2StableFingerprint[compiled],
    "PolynomialPoolSeed" -> polynomialSeed,
    "PolynomialPoolFingerprint" ->
      drcav2StableFingerprint[polynomialSeed],
    "SourceSemanticFingerprint" ->
      drcav2StableFingerprint[{record, roots, variables, epsilon}]|>;
  core = Append[core, "CoreFingerprint" ->
    drcav2StableFingerprint[drcav2CoreSemanticPayload[core]]];
  fingerprintSeconds = N[AbsoluteTime[] - fingerprintStart];
  Append[core, "Telemetry" -> <|
    "AlgebraicBundleSeconds" -> N[algebraicSeconds],
    "RationalFastPathBundleSeconds" -> N[rationalSeconds],
    "FingerprintSeconds" -> fingerprintSeconds,
    "TotalSeconds" -> N[AbsoluteTime[] - start],
    "AlgebraicBundle" -> algebraicBundle["Telemetry"],
    "RationalBundle" -> rationalBundle["Telemetry"],
    "FinalUniquePolynomialCount" -> Length[polynomialSeed["Values"]]|>]
];

DRCAV2CompileCore[___] := drcav2Failure["InvalidCompileCoreArguments"];

DRCAV2CoreValidQ[core_Association] := Module[
  {requiredKeys, variables, epsilon, exact, compiled, seed},
  requiredKeys = {"Status", "FormatVersion", "CompilerSourceFile",
    "CompilerSourceSHA256", "V1AdapterSourceFile",
    "V1AdapterSourceSHA256", "SourceABIFingerprint",
    "RootOrderingFingerprint", "Record", "Roots", "RootCount",
    "GradeCount", "Variables", "Regulator", "Dimensions",
    "GaugeDenominator", "ExactCoreForms", "CompiledCoreForms",
    "ExactCoreFormsFingerprint", "CompiledCoreFormsFingerprint",
    "PolynomialPoolSeed", "PolynomialPoolFingerprint",
    "SourceSemanticFingerprint", "CoreFingerprint", "Telemetry"};
  If[! AllTrue[requiredKeys, KeyExistsQ[core, #1] &] ||
      core["Status"] =!= "PreparedDirectRootChannelCoreV2" ||
      core["FormatVersion"] =!= 2 || ! drcav2CoreSourceStableQ[core] ||
      ! IntegerQ[core["RootCount"]] ||
      !(0 <= core["RootCount"] <= $drcav2MaximumRootCount) ||
      core["GradeCount"] =!= 2^core["RootCount"] ||
      ! MatchQ[core["Dimensions"], {_Integer, _Integer}], Return[False]];
  variables = core["Variables"];
  epsilon = core["Regulator"];
  exact = core["ExactCoreForms"];
  compiled = core["CompiledCoreForms"];
  seed = core["PolynomialPoolSeed"];
  TrueQ[MatchQ[variables, {_Symbol, _Symbol}] && MatchQ[epsilon, _Symbol] &&
    AssociationQ[exact] && AssociationQ[compiled] &&
    drcav2PolynomialPoolValidQ[seed, variables, epsilon] &&
    core["ExactCoreFormsFingerprint"] ===
      drcav2StableFingerprint[exact] &&
    core["CompiledCoreFormsFingerprint"] ===
      drcav2StableFingerprint[compiled] &&
    core["PolynomialPoolFingerprint"] ===
      drcav2StableFingerprint[seed] &&
    core["SourceSemanticFingerprint"] === drcav2StableFingerprint[
      {core["Record"], core["Roots"], variables, epsilon}] &&
    core["CoreFingerprint"] ===
      drcav2StableFingerprint[drcav2CoreSemanticPayload[core]]]
];

DRCAV2CoreValidQ[___] := False;

drcav2BuildV1Compatibility[core_Association, oneForms_List,
    support_List, normalizations_List, exactOneForms_,
    compiledOneForms_] := Module[
  {dimensions = core["Dimensions"], gradeCount = core["GradeCount"],
   upper, lower, gaugeUnknownCount, residueUnknownCount, unknownCount,
   equationsPerPoint, exactCore = core["ExactCoreForms"],
   compiledCore = core["CompiledCoreForms"], exactForms, compiledForms,
   result},
  {upper, lower} = dimensions;
  gaugeUnknownCount = upper lower gradeCount Length[support];
  residueUnknownCount = Length[oneForms] upper lower;
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 upper lower;
  If[! drcav2ValidNormalizationsQ[normalizations, unknownCount],
    Return[$Failed]];
  exactForms = <|"E" -> exactCore["E"], "C" -> exactCore["C"],
    "BBar" -> exactCore["BBar"], "OneForms" -> exactOneForms,
    "RootSquares" -> exactCore["RootSquares"],
    "RootLogDerivatives" -> exactCore["RootLogDerivatives"],
    "GaugeDenominator" -> exactCore["GaugeDenominator"],
    "GaugeLogDerivatives" -> exactCore["GaugeLogDerivatives"]|>;
  compiledForms = <|"E" -> compiledCore["E"],
    "C" -> compiledCore["C"], "BBar" -> compiledCore["BBar"],
    "OneForms" -> compiledOneForms,
    "RootSquares" -> compiledCore["RootSquares"],
    "RootLogDerivatives" -> compiledCore["RootLogDerivatives"],
    "GaugeDenominator" -> compiledCore["GaugeDenominator"],
    "GaugeLogDerivatives" -> compiledCore["GaugeLogDerivatives"]|>;
  result = <|
    "Status" -> "PreparedDirectRootChannelsV1",
    "PrototypeSourceFile" -> core["V1AdapterSourceFile"],
    "PrototypeSourceSHA256" -> core["V1AdapterSourceSHA256"],
    "SourceABIFingerprint" -> core["SourceABIFingerprint"],
    "RootOrderingFingerprint" -> core["RootOrderingFingerprint"],
    "Record" -> core["Record"], "Roots" -> core["Roots"],
    "RootCount" -> core["RootCount"], "GradeCount" -> gradeCount,
    "Variables" -> core["Variables"], "Regulator" -> core["Regulator"],
    "Dimensions" -> dimensions, "GaugeSupport" -> support,
    "OneForms" -> oneForms,
    "GaugeDenominator" -> core["GaugeDenominator"],
    "Normalizations" -> normalizations,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> equationsPerPoint,
    "ColumnOrder" -> drcav2ColumnOrderPayload[dimensions, gradeCount,
      support, Length[oneForms]],
    "RowOrder" -> drcav2RowOrderPayload[dimensions, gradeCount],
    "ExactChannelForms" -> exactForms,
    "CompiledForms" -> compiledForms,
    "ExactChannelFormsFingerprint" ->
      drcav2StableFingerprint[exactForms],
    "CompiledFormsFingerprint" -> drcav2StableFingerprint[compiledForms],
    "CompiledFormsShapeFingerprint" ->
      CodexDirectRootChannelAssembler`Private`drcaStableFingerprint[
        CodexDirectRootChannelAssembler`Private`drcaFormShape[
          compiledForms]],
    "SourceSemanticFingerprint" -> drcav2StableFingerprint[
      {core["Record"], core["Roots"], core["Variables"],
        core["Regulator"]}]|>;
  result = Append[result, "AssemblyFingerprint" ->
    drcav2StableFingerprint[drcav2V1SemanticPayload[result]]];
  If[! CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[
      result], $Failed, result]
];

drcav2FinalizeAssembly[core_Association, oneForms_List, support_List,
    normalizations_List, exactOneForms_, compiledOneForms_,
    polynomialSeed_Association, telemetry_Association] := Module[
  {v1, assembly},
  v1 = drcav2BuildV1Compatibility[core, oneForms, support,
    normalizations, exactOneForms, compiledOneForms];
  If[v1 === $Failed, Return[drcav2Failure[
    "V1CompatibilityAssemblyValidationFailed"]]];
  assembly = <|
    "Status" -> "PreparedDirectRootChannelsV2",
    "FormatVersion" -> 2,
    "CompilerSourceFile" -> $drcav2SourceFile,
    "CompilerSourceSHA256" -> $drcav2SourceSHA256,
    "V1AdapterSourceFile" -> $drcav2V1SourceFile,
    "V1AdapterSourceSHA256" -> $drcav2V1SourceSHA256,
    "Core" -> core, "CoreFingerprint" -> core["CoreFingerprint"],
    "SourceABIFingerprint" -> core["SourceABIFingerprint"],
    "RootOrderingFingerprint" -> core["RootOrderingFingerprint"],
    "OneForms" -> oneForms, "GaugeSupport" -> support,
    "Normalizations" -> normalizations,
    "ExactOneFormChannels" -> exactOneForms,
    "CompiledOneFormChannels" -> compiledOneForms,
    "PolynomialPoolSeed" -> polynomialSeed,
    "PolynomialPoolFingerprint" ->
      drcav2StableFingerprint[polynomialSeed],
    "CompatibilityAssemblyV1" -> v1,
    "V1AssemblyFingerprint" -> v1["AssemblyFingerprint"]|>;
  assembly = Append[assembly, "AssemblyFingerprintV2" ->
    drcav2StableFingerprint[drcav2AssemblySemanticPayload[assembly]]];
  Append[assembly, "Telemetry" -> telemetry]
];

DRCAV2InstantiateAnsatz[core_Association, oneForms_List,
    support_List, normalizations_List: {}] := Module[
  {start = AbsoluteTime[], bundle, compileSeconds, seed, telemetry},
  If[! DRCAV2CoreValidQ[core] || ! drcav2ValidSupportQ[support] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[drcav2Failure["InvalidAnsatzInput"]]];
  {compileSeconds, bundle} = AbsoluteTiming[
    drcav2CompileBundle[<|
      "OneForms" -> <|"Tensor" -> oneForms, "ScalarLevel" -> 2|>|>,
      core["Roots"], core["Variables"], core["Regulator"],
      core["PolynomialPoolSeed"]]];
  If[bundle === $Failed,
    Return[drcav2Failure["OneFormCompilationFailed"]]];
  seed = drcav2PolynomialPoolSeed[bundle["PolynomialPool"]];
  telemetry = <|"Mode" -> "FreshAnsatz",
    "OneFormCompileSeconds" -> N[compileSeconds],
    "AnsatzBundle" -> bundle["Telemetry"],
    "TotalSecondsBeforeFinalFingerprint" -> N[AbsoluteTime[] - start]|>;
  drcav2FinalizeAssembly[core, oneForms, support, normalizations,
    bundle["Exact", "OneForms"], bundle["Compiled", "OneForms"],
    seed, Append[telemetry, "TotalSeconds" ->
      N[AbsoluteTime[] - start]]]
];

DRCAV2InstantiateAnsatz[___] :=
  drcav2Failure["InvalidInstantiateAnsatzArguments"];

DRCAV2RebindAnsatz[assembly_Association, oneForms_List,
    support_List, normalizations_List: {}] := Module[
  {start = AbsoluteTime[], core, oldOneForms, suffix, bundle,
   exactOneForms, compiledOneForms, seed, compileSeconds = 0., mode,
   telemetry},
  If[! DRCAV2AssemblyValidQ[assembly] ||
      ! drcav2ValidSupportQ[support] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[drcav2Failure["InvalidRebindInput"]]];
  core = assembly["Core"];
  oldOneForms = assembly["OneForms"];
  If[Length[oneForms] < Length[oldOneForms] ||
      ! SameQ[Take[oneForms, Length[oldOneForms]], oldOneForms],
    Return[drcav2Failure["OneFormsNotPrefixExtension"]]];
  suffix = Drop[oneForms, Length[oldOneForms]];
  If[suffix === {},
    exactOneForms = assembly["ExactOneFormChannels"];
    compiledOneForms = assembly["CompiledOneFormChannels"];
    seed = assembly["PolynomialPoolSeed"];
    mode = "SupportOrNormalizationOnly",
    {compileSeconds, bundle} = AbsoluteTiming[
      drcav2CompileBundle[<|
        "OneForms" -> <|"Tensor" -> suffix, "ScalarLevel" -> 2|>|>,
        core["Roots"], core["Variables"], core["Regulator"],
        assembly["PolynomialPoolSeed"]]];
    If[bundle === $Failed,
      Return[drcav2Failure["AppendedOneFormCompilationFailed"]]];
    exactOneForms = Join[assembly["ExactOneFormChannels"],
      bundle["Exact", "OneForms"]];
    compiledOneForms = Join[assembly["CompiledOneFormChannels"],
      bundle["Compiled", "OneForms"]];
    seed = drcav2PolynomialPoolSeed[bundle["PolynomialPool"]];
    mode = "OneFormPrefixExtension"];
  telemetry = <|"Mode" -> mode,
    "OldOneFormCount" -> Length[oldOneForms],
    "NewOneFormCount" -> Length[oneForms],
    "AppendedOneFormCount" -> Length[suffix],
    "AppendedCompileSeconds" -> N[compileSeconds],
    "TotalSeconds" -> N[AbsoluteTime[] - start]|>;
  drcav2FinalizeAssembly[core, oneForms, support, normalizations,
    exactOneForms, compiledOneForms, seed, telemetry]
];

DRCAV2RebindAnsatz[___] := drcav2Failure["InvalidRebindArguments"];

DRCAV2CompileSystem[record_Association, roots_List, oneForms_List,
    gaugeDenominator_, support_List, normalizations_List: {},
    metadata_: <||>] := Module[{core},
  core = DRCAV2CompileCore[record, roots, gaugeDenominator, metadata];
  If[Lookup[core, "Status", None] =!=
      "PreparedDirectRootChannelCoreV2", Return[core]];
  DRCAV2InstantiateAnsatz[core, oneForms, support, normalizations]
];

DRCAV2CompileSystem[___] := drcav2Failure["InvalidCompileSystemArguments"];

DRCAV2Prepare[preparation_Association] := Module[{compiled, v1},
  If[Lookup[preparation, "Status", None] =!= "PreparedReconstruction" ||
      ! CodexTripleRootReconstruction`TRPreparationABIValidQ[preparation],
    Return[drcav2Failure["InvalidSourcePreparationABI"]]];
  compiled = DRCAV2CompileSystem[preparation["Record"],
    preparation["Roots"], preparation["OneForms"],
    preparation["GaugeDenominator"], preparation["GaugeSupport"],
    preparation["Normalizations"], <|
      "SourceABIFingerprint" -> preparation["ABIFingerprint"],
      "RootOrderingFingerprint" ->
        preparation["RootOrderingFingerprint"]|>];
  If[Lookup[compiled, "Status", None] =!=
      "PreparedDirectRootChannelsV2", Return[compiled]];
  v1 = compiled["CompatibilityAssemblyV1"];
  If[v1["Dimensions"] =!= preparation["Dimensions"] ||
      v1["GaugeUnknownCount"] =!= preparation["GaugeUnknownCount"] ||
      v1["ResidueUnknownCount"] =!= preparation["ResidueUnknownCount"] ||
      v1["UnknownCount"] =!= preparation["UnknownCount"] ||
      v1["EquationsPerPoint"] =!= preparation["EquationsPerPoint"],
    drcav2Failure["SourcePreparationShapeMismatch"], compiled]
];

DRCAV2Prepare[___] := drcav2Failure["InvalidPrepareArguments"];

drcav2AssemblySourceStableQ[assembly_Association] := TrueQ[
  Quiet[Check[FileHash[assembly["CompilerSourceFile"], "SHA256",
    "HexString"], $Failed]] === assembly["CompilerSourceSHA256"] ===
      $drcav2SourceSHA256 &&
  Quiet[Check[FileHash[assembly["V1AdapterSourceFile"], "SHA256",
    "HexString"], $Failed]] === assembly["V1AdapterSourceSHA256"] ===
      $drcav2V1SourceSHA256];

DRCAV2AssemblyValidQ[assembly_Association] := Module[
  {requiredKeys, core, v1, seed},
  requiredKeys = {"Status", "FormatVersion", "CompilerSourceFile",
    "CompilerSourceSHA256", "V1AdapterSourceFile",
    "V1AdapterSourceSHA256", "Core", "CoreFingerprint",
    "SourceABIFingerprint", "RootOrderingFingerprint", "OneForms",
    "GaugeSupport", "Normalizations", "ExactOneFormChannels",
    "CompiledOneFormChannels", "PolynomialPoolSeed",
    "PolynomialPoolFingerprint", "CompatibilityAssemblyV1",
    "V1AssemblyFingerprint", "AssemblyFingerprintV2", "Telemetry"};
  If[! AllTrue[requiredKeys, KeyExistsQ[assembly, #1] &] ||
      assembly["Status"] =!= "PreparedDirectRootChannelsV2" ||
      assembly["FormatVersion"] =!= 2 ||
      ! drcav2AssemblySourceStableQ[assembly], Return[False]];
  core = assembly["Core"];
  v1 = assembly["CompatibilityAssemblyV1"];
  seed = assembly["PolynomialPoolSeed"];
  TrueQ[DRCAV2CoreValidQ[core] &&
    AssociationQ[v1] &&
    CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[v1] &&
    drcav2ValidSupportQ[assembly["GaugeSupport"]] &&
    MatchQ[assembly["OneForms"], {} | {{_, _} ..}] &&
    drcav2PolynomialPoolValidQ[seed, core["Variables"],
      core["Regulator"]] &&
    assembly["CoreFingerprint"] === core["CoreFingerprint"] &&
    assembly["SourceABIFingerprint"] === core["SourceABIFingerprint"] &&
    assembly["RootOrderingFingerprint"] ===
      core["RootOrderingFingerprint"] &&
    assembly["PolynomialPoolFingerprint"] ===
      drcav2StableFingerprint[seed] &&
    assembly["V1AssemblyFingerprint"] === v1["AssemblyFingerprint"] &&
    v1["OneForms"] === assembly["OneForms"] &&
    v1["GaugeSupport"] === assembly["GaugeSupport"] &&
    v1["Normalizations"] === assembly["Normalizations"] &&
    v1["ExactChannelForms", "OneForms"] ===
      assembly["ExactOneFormChannels"] &&
    v1["CompiledForms", "OneForms"] ===
      assembly["CompiledOneFormChannels"] &&
    assembly["AssemblyFingerprintV2"] ===
      drcav2StableFingerprint[drcav2AssemblySemanticPayload[assembly]]]
];

DRCAV2AssemblyValidQ[___] := False;

DRCAV2ToV1Assembly[assembly_Association] := Module[{v1},
  If[! DRCAV2AssemblyValidQ[assembly], Return[$Failed]];
  v1 = assembly["CompatibilityAssemblyV1"];
  If[CodexDirectRootChannelAssembler`DRCAAssemblyPreparationValidQ[v1],
    v1, $Failed]
];

DRCAV2ToV1Assembly[___] := $Failed;

End[];
EndPackage[];
