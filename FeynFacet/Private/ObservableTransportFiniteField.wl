(* Modular coordinate reconstruction for demand-projected observable transport.

   This file is deliberately separate from ObservableTransport.wl.  Its stable
   integration point is observableTransportModularRowBasis.  Rank samples are
   proposals; a Ratracer reconstruction (including a cached one) is accepted
   only after independent checks at fresh modular points.  Such acceptance is
   probabilistic and is never reported as exact. *)

ClearAll[
  observableTransportModularRowBasis,
  observableTransportModularRowBasisAcceptedQ,
  observableTransportModularMatrixReconstruction,
  observableTransportModularSubspaceInclusion,
  observableTransportModularAlgebraicSubspaceInclusion,
  observableTransportFFFailure,
  observableTransportFFNormalizeSamples,
  observableTransportFFIndependentRows,
  observableTransportFFCompileExpressions,
  observableTransportFFCompile,
  observableTransportFFCompileMatrix,
  observableTransportFFEvaluateExpressions,
  observableTransportFFValue,
  observableTransportFFMatrixValue,
  observableTransportFFAlgebraicRoots,
  observableTransportFFAlgebraicMatrixValue,
  observableTransportFFAlgebraicIndependentRowsAtSamples,
  observableTransportFFSelectMatrixTrials,
  observableTransportFFFreshTrialPool,
  observableTransportFFAliasData,
  observableTransportFFExpressionString,
  observableTransportFFWorkDirectory,
  observableTransportFFResolveRatracer,
  observableTransportFFWriteEquations,
  observableTransportFFRunRatracer,
  observableTransportFFMarker,
  observableTransportFFHeldRationalQ,
  observableTransportFFParseExpression,
  observableTransportFFTraceOutputKeys,
  observableTransportFFParseSolution,
  observableTransportFFFLINTSolve,
  observableTransportFFPivotSolve,
  observableTransportFFValidateCandidate
];

$observableTransportFFTracePrime = 2147483647;
$observableTransportFFAliasNames = {"otffx1", "otffx2"};

Options[observableTransportModularSubspaceInclusion] = {
  "ValidationPrimeCount" -> 2,
  "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> Automatic
};

Options[observableTransportModularAlgebraicSubspaceInclusion] =
  Options[observableTransportModularSubspaceInclusion];

observableTransportFFFailure[status_String, data_Association : <||>] :=
  Join[<|"Status" -> status|>, data];

Options[observableTransportModularRowBasis] = {
  "CoordinateBackend" -> Automatic,
  "CoordinateCacheDirectory" -> Automatic,
  "ReconstructionThreads" -> 1,
  "ValidationPrimeCount" -> 2,
  "ValidationPointsPerPrime" -> 1,
  "Verbose" -> False,
  "CoordinateKey" -> Automatic,
  "RatracerExecutable" -> Automatic,
  "FLINTExecutable" -> Automatic,
  "ValidationSeed" -> Automatic,
  "StructuralIdentityPrefix" -> False
};

Options[observableTransportModularMatrixReconstruction] =
  Options[observableTransportModularRowBasis];

observableTransportModularRowBasisAcceptedQ[value_] :=
  AssociationQ[value] &&
    Lookup[value, "Status", None] === "ModularRowBasisAccepted" &&
    AssociationQ[Lookup[value, "ModularCertificate", None]] &&
    Lookup[value["ModularCertificate"], "Status", None] ===
      "FreshModularIdentityAccepted" &&
    TrueQ[Lookup[value["ModularCertificate"], "Accepted", False]] &&
    TrueQ[Lookup[value["ModularCertificate"], "Probabilistic", False]] &&
    TrueQ[Lookup[value["ModularCertificate"], "Exact", True] === False];

(* Rules for unrelated symbols are harmless (the caller's rank samples can
   include a path variable), but every declared coefficient variable must be
   present exactly once. *)
observableTransportFFNormalizeSamples[sampleRules_List,
    variables_List] := Module[{samples, clean},
  samples = If[MatchQ[sampleRules, {_Rule ...}], {sampleRules}, sampleRules];
  If[! ListQ[samples], Return[{}]];
  clean = Cases[samples, rules_List :>
    DeleteDuplicatesBy[
      Select[rules, MatchQ[#, (_Symbol -> _)] &&
          MemberQ[variables, First[#]] &], First]];
  Select[clean, SortBy[First /@ #, SymbolName] ===
      SortBy[variables, SymbolName] &]
];

(* This matches ObservableTransport.wl's established pivot convention. *)
observableTransportFFIndependentRows[m_, rules_List] := Module[
  {evaluated, reduced, pivots},
  If[Length[m] === 0, Return[{}]];
  evaluated = Quiet[Check[Normal[m] /. rules, $Failed]];
  If[evaluated === $Failed ||
      ! MatrixQ[evaluated, MatchQ[#, _Integer | _Rational] &] ||
      ! FreeQ[evaluated,
        Indeterminate | ComplexInfinity | DirectedInfinity[_]],
    Return[$Failed]];
  reduced = Quiet[Check[RowReduce[Transpose[evaluated]], $Failed]];
  If[reduced === $Failed, Return[$Failed]];
  pivots = DeleteMissing[(Replace[
       FirstPosition[#, value_ /; ! TrueQ[value === 0],
         Missing["ZeroRow"], {1}, Heads -> False],
       {position_Integer} :> position] &) /@ reduced];
  DeleteDuplicates[pivots]
];

(* Compile the already-rational operation tree without Together, Expand, or
   CoefficientRules.  Numerator/Denominator below are used only on an atomic
   Rational number, never on a symbolic expression. *)
observableTransportFFCompileExpressions[expressions_List,
    variables_List] := Module[
  {compile},
  compile[value_] := compile[value] = Which[
    IntegerQ[value], {"Integer", value},
    Head[value] === Rational,
      {"Rational", Numerator[value], Denominator[value]},
    MatchQ[value, _Symbol] && MemberQ[variables, Unevaluated[value]],
      {"Variable", First@FirstPosition[variables, Unevaluated[value]]},
    Head[value] === Plus,
      With[{children = compile /@ (List @@ value)},
        If[FreeQ[children, $Failed], {"Plus", children}, $Failed]],
    Head[value] === Times,
      With[{children = compile /@ (List @@ value)},
        If[FreeQ[children, $Failed], {"Times", children}, $Failed]],
    Head[value] === Power && IntegerQ[value[[2]]],
      With[{base = compile[value[[1]]]},
        If[base === $Failed, $Failed, {"Power", base, value[[2]]}]],
    True, $Failed
  ];
  compile /@ expressions
];

observableTransportFFCompile[expression_, variables_List] :=
  First[observableTransportFFCompileExpressions[{expression}, variables]];

observableTransportFFCompileMatrix[m_, variables_List] := Module[
  {normal, dimensions, compiledEntries, compiled},
  normal = Normal[m];
  dimensions = Dimensions[normal];
  If[Length[dimensions] =!= 2, Return[$Failed]];
  (* Compile the whole matrix through one memoized tree walker.  Transport
     matrices share most operator subexpressions, so an entry-local compiler
     repeats the same traversal thousands of times. *)
  compiledEntries = observableTransportFFCompileExpressions[
    Catenate[normal], variables];
  (* The compiled entries are nested Lists themselves.  Indexed Table keeps
     those ASTs opaque; ArrayReshape/level-based Map can descend into them. *)
  compiled = Table[
    compiledEntries[[(row - 1) dimensions[[2]] + column]],
    {row, dimensions[[1]]}, {column, dimensions[[2]]}];
  If[FreeQ[compiled, $Failed], compiled, $Failed]
];

(* Evaluate with modular reduction at every node.  One memoized evaluator is
   shared by a whole batch: transport word maps reuse the same operator
   subtrees heavily, so entry-local evaluation repeats nearly all work. *)
observableTransportFFEvaluateExpressions[compiledExpressions_List,
    point_List, prime_Integer] := Module[{evaluate, evaluateRaw},
  evaluate[node_] := evaluate[node] = evaluateRaw[node];
  (* Pattern dispatch keeps payloads opaque.  A Switch-based dispatcher can
     evaluate part-extractions in nonselected branch expressions when nested
     inside held arithmetic, which leaked rational AST payloads on CF27. *)
  evaluateRaw[{"Integer", value_Integer}] := Mod[value, prime];
  evaluateRaw[{"Rational", numerator_Integer, denominator_Integer}] :=
    With[{d = Mod[denominator, prime]},
      If[d === 0, $Failed,
        Mod[numerator PowerMod[d, -1, prime], prime]]];
  evaluateRaw[{"Variable", position_Integer}] /;
      1 <= position <= Length[point] := point[[position]];
  evaluateRaw[{"Plus", children_List}] := With[
    {values = evaluate /@ children},
    If[MemberQ[values, $Failed], $Failed, Mod[Total[values], prime]]];
  evaluateRaw[{"Times", children_List}] := With[
    {values = evaluate /@ children},
    If[MemberQ[values, $Failed], $Failed,
      Mod[Times @@ values, prime]]];
  evaluateRaw[{"Power", child_, exponent_Integer}] := With[
    {base = evaluate[child]},
    If[base === $Failed || (base === 0 && exponent < 0), $Failed,
      Quiet[Check[PowerMod[base, exponent, prime], $Failed]]]];
  evaluateRaw[_] := $Failed;
  evaluate /@ compiledExpressions
];

observableTransportFFValue[compiled_, point_List, prime_Integer] :=
  First[observableTransportFFEvaluateExpressions[
    {compiled}, point, prime]];

observableTransportFFMatrixValue[compiled_List, point_List,
    prime_Integer] := Module[{dimensions, entries, values, value},
  dimensions = Dimensions[compiled, 2];
  If[Length[dimensions] =!= 2, Return[$Failed]];
  entries = Catenate[compiled];
  values = observableTransportFFEvaluateExpressions[
    entries, point, prime];
  (* As above, keep list-valued operation trees opaque while restoring the
     matrix shape. *)
  value = Table[
    values[[(row - 1) dimensions[[2]] + column]],
    {row, dimensions[[1]]}, {column, dimensions[[2]]}];
  If[FreeQ[value, $Failed], value, $Failed]
];

(* Complete a declared root list with any radical square classes visible in
   the matrices.  Production algebraic frames supply the declared generators;
   the census fallback keeps small standalone records usable. *)
observableTransportFFAlgebraicRoots[expressions_, declaredSquares_List] :=
    Module[{bases, squares = {}},
  bases = transportChartRadicalBases[expressions];
  Do[
    If[! AnyTrue[squares,
        transportChartRootBranchScale[square, #] =!= None &],
      AppendTo[squares, square]],
    {square, Join[declaredSquares, bases]}];
  (<|"Root" -> Sqrt[#], "RootSquare" -> #|> &) /@ squares
];

observableTransportFFAlgebraicMatrixValue[m_, variables_List,
    point_List, roots_List, rootValues_List, signs_List,
    prime_Integer] := Module[{branched, values},
  branched = Quiet[Check[transportChartApplyRootBranches[
    Normal[m], roots, Mod[signs rootValues, prime]], $Failed]];
  If[branched === $Failed, Return[$Failed]];
  values = Map[multiquadraticStripModRational[
      # /. Thread[variables -> point], prime] &, branched, {2}];
  If[MatrixQ[values, IntegerQ], values, $Failed]
];

(* Rank samples guide the symbolic closure but do not certify it.  Evaluating
   a multiquadratic matrix exactly at a rational point leaves algebraic
   numbers in every entry, making even a small RowReduce pathologically
   expensive.  Select the same pivot convention in one split finite-field
   image instead; the closure's existing fresh all-branch modular inclusion
   remains the acceptance test. *)
observableTransportFFAlgebraicIndependentRowsAtSamples[m_, variables_List,
    samples_List, declaredSquares_List] := Module[
  {dimensions, roots, rootSquares, rootCompiler, rootCount,
   maximumAttempts = 128, proposal},
  dimensions = Quiet[Check[Dimensions[m], {}]];
  If[Length[dimensions] =!= 2 ||
      ! MatchQ[variables, {_Symbol ..}],
    Return[ConstantArray[$Failed, Length[samples]]]];
  roots = observableTransportFFAlgebraicRoots[m, declaredSquares];
  rootSquares = Lookup[roots, "RootSquare", {}];
  rootCount = Length[roots];
  If[rootCount === 0,
    Return[ConstantArray[$Failed, Length[samples]]]];
  rootCompiler = observableTransportFFCompileExpressions[
    rootSquares, variables];
  If[MemberQ[rootCompiler, $Failed],
    Return[ConstantArray[$Failed, Length[samples]]]];
  proposal[rules_List, sampleIndex_Integer] := Module[
    {point, deltaValues, rootValues, image, reduced, pivots, prime},
    If[Sort[First /@ rules] =!= Sort[variables], Return[$Failed]];
    BlockRandom[
      SeedRandom[97531 + 1009 dimensions[[1]] +
        9176 dimensions[[2]] + sampleIndex];
      Do[
        prime = RandomPrime[{2^30, 2^31 - 1}];
        If[Mod[prime, 4] =!= 3 ||
            prime === $observableTransportFFTracePrime, Continue[]];
        point = multiquadraticStripModRational[#, prime] & /@
          (variables /. rules);
        If[MemberQ[point, $Failed], Continue[]];
        deltaValues = observableTransportFFEvaluateExpressions[
          rootCompiler, point, prime];
        If[MemberQ[deltaValues, $Failed | 0] ||
            ! AllTrue[deltaValues, JacobiSymbol[#, prime] === 1 &],
          Continue[]];
        rootValues = multiquadraticSquareRoots[deltaValues, prime];
        If[rootValues === $Failed, Continue[]];
        image = observableTransportFFAlgebraicMatrixValue[
          m, variables, point, roots, rootValues,
          ConstantArray[1, rootCount], prime];
        If[image === $Failed, Continue[]];
        reduced = Quiet[Check[
          RowReduce[Transpose[image], Modulus -> prime], $Failed]];
        If[reduced === $Failed, Continue[]];
        pivots = DeleteMissing[(Replace[
            FirstPosition[#, value_ /; value =!= 0,
              Missing["ZeroRow"], {1}, Heads -> False],
            {position_Integer} :> position] &) /@ reduced];
        Return[DeleteDuplicates[pivots], Module],
        {maximumAttempts}]
    ];
    $Failed
  ];
  MapIndexed[proposal[#1, First[#2]] &, samples]
];

(* Verify row-space inclusion directly at fresh finite-field points.  This is
   used for the ambient boundary evolution, where constructing a symbolic
   moving nullspace would defeat the purpose of the sparse-state route.  Trial
   points are generated and evaluated one at a time; reserve points are not
   evaluated unless a pole or exceptional rank is actually encountered. *)
observableTransportModularSubspaceInclusion[space_, candidates_,
    variables_List, OptionsPattern[]] := Module[
  {spaceDimensions, candidateDimensions, primeCount, pointsPerPrime,
   seed, compiledSpace, compiledCandidates, trialPool, primes, accepted = {},
   rejected = {}, required, spaceImage, candidateImage, spaceRank,
   joinedRank, acceptedForPrime, trial, invalidSpacePositions,
   invalidCandidatePositions, invalidExamples, remainingSymbols},
  spaceDimensions = Quiet[Check[Dimensions[space], {}]];
  candidateDimensions = Quiet[Check[Dimensions[candidates], {}]];
  If[Length[spaceDimensions] =!= 2 ||
      Length[candidateDimensions] =!= 2 ||
      Last[spaceDimensions] =!= Last[candidateDimensions] ||
      ! MatchQ[variables, {_Symbol ..}] ||
      ! Between[Length[variables], {1, 2}],
    Return[observableTransportFFFailure[
      "ModularSubspaceInputsInvalid"]]];
  primeCount = OptionValue["ValidationPrimeCount"];
  pointsPerPrime = OptionValue["ValidationPointsPerPrime"];
  seed = Replace[OptionValue["ValidationSeed"],
    Automatic :> RandomInteger[{1, 2^31 - 1}]];
  If[! IntegerQ[primeCount] || primeCount < 1 ||
      ! IntegerQ[pointsPerPrime] || pointsPerPrime < 1 ||
      ! IntegerQ[seed],
    Return[observableTransportFFFailure[
      "ModularSubspaceOptionsInvalid"]]];
  compiledSpace = observableTransportFFCompileMatrix[space, variables];
  compiledCandidates = observableTransportFFCompileMatrix[
    candidates, variables];
  If[compiledSpace === $Failed || compiledCandidates === $Failed,
    invalidSpacePositions = If[compiledSpace === $Failed,
      Select[Tuples[Range /@ spaceDimensions],
        observableTransportFFCompile[Extract[space, #], variables] ===
          $Failed &], {}];
    invalidCandidatePositions = If[compiledCandidates === $Failed,
      Select[Tuples[Range /@ candidateDimensions],
        observableTransportFFCompile[Extract[candidates, #], variables] ===
          $Failed &], {}];
    invalidExamples = Join[
      Extract[space, Take[invalidSpacePositions, UpTo[2]]],
      Extract[candidates, Take[invalidCandidatePositions, UpTo[2]]]];
    remainingSymbols = DeleteDuplicates[Cases[
      invalidExamples, symbol_Symbol /;
        ! MemberQ[variables, Unevaluated[symbol]] :>
          HoldForm[symbol], Infinity]];
    Return[observableTransportFFFailure[
      "ModularSubspaceEntriesNotRational", <|
        "InvalidSpacePositions" ->
          Take[invalidSpacePositions, UpTo[10]],
        "InvalidCandidatePositions" ->
          Take[invalidCandidatePositions, UpTo[10]],
        "InvalidExamples" -> invalidExamples,
        "RemainingSymbols" -> remainingSymbols|>]]];
  trialPool = observableTransportFFFreshTrialPool[
    primeCount, pointsPerPrime, Length[variables],
    {$observableTransportFFTracePrime}, seed];
  primes = trialPool["Primes"];
  Do[
    acceptedForPrime = 0;
    Do[
      If[acceptedForPrime >= pointsPerPrime, Break[]];
      trial = candidateTrial;
      spaceImage = observableTransportFFMatrixValue[
        compiledSpace, trial["Point"], prime];
      candidateImage = observableTransportFFMatrixValue[
        compiledCandidates, trial["Point"], prime];
      If[spaceImage === $Failed || candidateImage === $Failed,
        AppendTo[rejected, Join[trial, <|"Reason" -> "Pole"|>]];
        Continue[]];
      spaceRank = Quiet[Check[MatrixRank[spaceImage,
        Modulus -> prime], $Failed]];
      joinedRank = Quiet[Check[MatrixRank[
        Join[spaceImage, candidateImage], Modulus -> prime], $Failed]];
      If[spaceRank === $Failed || joinedRank === $Failed,
        AppendTo[rejected, Join[trial,
          <|"Reason" -> "RankEvaluationFailed"|>]];
        Continue[]];
      If[joinedRank =!= spaceRank,
        Return[observableTransportFFFailure[
          "FreshModularSubspaceInclusionRejected", <|
            "Prime" -> prime, "Point" -> trial["Point"],
            "SpaceRank" -> spaceRank,
            "JoinedRank" -> joinedRank|>], Module]];
      AppendTo[accepted, Join[trial, <|
        "SpaceRank" -> spaceRank, "JoinedRank" -> joinedRank|>]];
      acceptedForPrime++,
      {candidateTrial, Select[trialPool["Trials"],
        #1["Prime"] === prime &]}];
    If[acceptedForPrime < pointsPerPrime,
      Return[observableTransportFFFailure[
        "InsufficientFreshModularSubspacePoints", <|
          "Prime" -> prime, "Accepted" -> acceptedForPrime,
          "Required" -> pointsPerPrime|>], Module]],
    {prime, primes}];
  required = primeCount pointsPerPrime;
  If[Length[accepted] =!= required,
    Return[observableTransportFFFailure[
      "FreshModularSubspaceInventoryIncomplete", <|
        "Accepted" -> Length[accepted], "Required" -> required|>]]];
  <|"Status" -> "FreshModularSubspaceInclusionAccepted",
    "Accepted" -> True, "Probabilistic" -> True, "Exact" -> False,
    "AcceptedTrials" -> accepted, "RejectedTrials" -> rejected|>
];

(* The same containment certificate over a multiquadratic coefficient field.
   Points are chosen where every declared root splits over F_p and every sign
   embedding is checked.  Thus no symbolic radical simplification is part of
   the production acceptance path. *)
observableTransportModularAlgebraicSubspaceInclusion[space_, candidates_,
    variables_List, declaredSquares_List, OptionsPattern[]] := Module[
  {spaceDimensions, candidateDimensions, primeCount, pointsPerPrime, seed,
   roots, rootSquares, rootCompiler, rootCount, branchCount, primes,
   constantRootSquares, constantRootCompiler, constantRootValues,
   primeAttemptLimit,
   accepted = {}, rejected = {}, attemptsPerPrime, acceptedForPrime,
   candidatePoints, point, deltaValues, rootValues, signs, mask,
   spaceImage, candidateImage, spaceRank, joinedRank, branchFailed},
  spaceDimensions = Quiet[Check[Dimensions[space], {}]];
  candidateDimensions = Quiet[Check[Dimensions[candidates], {}]];
  If[Length[spaceDimensions] =!= 2 ||
      Length[candidateDimensions] =!= 2 ||
      Last[spaceDimensions] =!= Last[candidateDimensions] ||
      ! MatchQ[variables, {_Symbol ..}] ||
      ! Between[Length[variables], {1, 2}],
    Return[observableTransportFFFailure[
      "ModularAlgebraicSubspaceInputsInvalid"]]];
  primeCount = OptionValue["ValidationPrimeCount"];
  pointsPerPrime = OptionValue["ValidationPointsPerPrime"];
  seed = Replace[OptionValue["ValidationSeed"],
    Automatic :> RandomInteger[{1, 2^31 - 1}]];
  If[! IntegerQ[primeCount] || primeCount < 1 ||
      ! IntegerQ[pointsPerPrime] || pointsPerPrime < 1 ||
      ! IntegerQ[seed],
    Return[observableTransportFFFailure[
      "ModularAlgebraicSubspaceOptionsInvalid"]]];
  roots = observableTransportFFAlgebraicRoots[
    {space, candidates}, declaredSquares];
  rootSquares = Lookup[roots, "RootSquare", {}];
  rootCount = Length[roots];
  If[rootCount === 0,
    Return[observableTransportModularSubspaceInclusion[
      space, candidates, variables,
      "ValidationPrimeCount" -> primeCount,
      "ValidationPointsPerPrime" -> pointsPerPrime,
      "ValidationSeed" -> seed]]];
  rootCompiler = observableTransportFFCompileExpressions[
    rootSquares, variables];
  If[MemberQ[rootCompiler, $Failed],
    Return[observableTransportFFFailure[
      "AlgebraicRootSquaresNotRational"]]];
  constantRootSquares = Select[rootSquares,
    FreeQ[#, Alternatives @@ variables] &];
  constantRootCompiler = observableTransportFFCompileExpressions[
    constantRootSquares, variables];
  branchCount = 2^rootCount;
  attemptsPerPrime = Max[64, 16 branchCount pointsPerPrime];
  primeAttemptLimit = Max[1000, 200 primeCount 2^Length[
    constantRootSquares]];
  primes = BlockRandom[Module[{selected = {}, prime, primeAttempts = 0},
    SeedRandom[seed];
    While[Length[selected] < primeCount &&
        primeAttempts < primeAttemptLimit,
      primeAttempts++;
      prime = RandomPrime[{2^30, 2^31 - 1}];
      If[Mod[prime, 4] =!= 3 ||
          MemberQ[Join[{$observableTransportFFTracePrime}, selected],
            prime], Continue[]];
      constantRootValues = observableTransportFFEvaluateExpressions[
        constantRootCompiler, ConstantArray[0, Length[variables]], prime];
      If[FreeQ[constantRootValues, $Failed | 0] &&
          AllTrue[constantRootValues,
            JacobiSymbol[#, prime] === 1 &],
        AppendTo[selected, prime]]];
    selected]];
  If[Length[primes] < primeCount,
    Return[observableTransportFFFailure[
      "InsufficientSplitValidationPrimes", <|
        "AcceptedPrimeCount" -> Length[primes],
        "RequiredPrimeCount" -> primeCount,
        "PrimeAttemptLimit" -> primeAttemptLimit,
        "ConstantRootSquares" -> constantRootSquares|>]]];
  Do[
    acceptedForPrime = 0;
    candidatePoints = BlockRandom[
      SeedRandom[Mod[seed + prime, 2^31 - 1]];
      Table[RandomInteger[{2, prime - 2}, Length[variables]],
        {attemptsPerPrime}]];
    Do[
      If[acceptedForPrime >= pointsPerPrime, Break[]];
      point = candidatePoint;
      deltaValues = observableTransportFFEvaluateExpressions[
        rootCompiler, point, prime];
      If[MemberQ[deltaValues, $Failed | 0] ||
          ! AllTrue[deltaValues, JacobiSymbol[#, prime] === 1 &],
        AppendTo[rejected, <|"Prime" -> prime, "Point" -> point,
          "Reason" -> "NonsplitOrSingularRootImage"|>]; Continue[]];
      rootValues = multiquadraticSquareRoots[deltaValues, prime];
      If[rootValues === $Failed,
        AppendTo[rejected, <|"Prime" -> prime, "Point" -> point,
          "Reason" -> "SquareRootFailure"|>]; Continue[]];
      branchFailed = False;
      Do[
        signs = Table[If[BitGet[mask, index - 1] === 1, -1, 1],
          {index, rootCount}];
        spaceImage = observableTransportFFAlgebraicMatrixValue[
          space, variables, point, roots, rootValues, signs, prime];
        candidateImage = observableTransportFFAlgebraicMatrixValue[
          candidates, variables, point, roots, rootValues, signs, prime];
        If[spaceImage === $Failed || candidateImage === $Failed,
          branchFailed = True; Break[]];
        spaceRank = Quiet[Check[MatrixRank[spaceImage,
          Modulus -> prime], $Failed]];
        joinedRank = Quiet[Check[MatrixRank[
          Join[spaceImage, candidateImage], Modulus -> prime], $Failed]];
        If[spaceRank === $Failed || joinedRank === $Failed,
          branchFailed = True; Break[]];
        If[joinedRank =!= spaceRank,
          Return[observableTransportFFFailure[
            "FreshModularSubspaceInclusionRejected", <|
              "CoefficientField" -> "Multiquadratic", "Prime" -> prime,
              "Point" -> point, "BranchMask" -> mask,
              "SpaceRank" -> spaceRank,
              "JoinedRank" -> joinedRank|>], Module]],
        {mask, 0, branchCount - 1}];
      If[branchFailed,
        AppendTo[rejected, <|"Prime" -> prime, "Point" -> point,
          "Reason" -> "BranchEvaluationFailed"|>]; Continue[]];
      AppendTo[accepted, <|"Prime" -> prime, "Point" -> point,
        "RootCount" -> rootCount, "BranchesChecked" -> branchCount|>];
      acceptedForPrime++,
      {candidatePoint, candidatePoints}];
    If[acceptedForPrime < pointsPerPrime,
      Return[observableTransportFFFailure[
        "InsufficientFreshModularAlgebraicPoints", <|
          "Prime" -> prime, "Accepted" -> acceptedForPrime,
          "Required" -> pointsPerPrime,
          "RootSquares" -> rootSquares,
          "RejectedReasons" -> Counts[Lookup[
            Select[rejected, Lookup[#, "Prime", None] === prime &],
            "Reason", "Unknown"]]|>], Module]],
    {prime, primes}];
  <|"Status" -> "FreshModularSubspaceInclusionAccepted",
    "Accepted" -> True, "Probabilistic" -> True, "Exact" -> False,
    "CoefficientField" -> "Multiquadratic", "RootCount" -> rootCount,
    "AcceptedTrials" -> accepted, "RejectedTrials" -> rejected|>
];

(* A bounded reserve of points is generated up front, so a very large result
   file never has to be parsed a second time merely because one point is a
   pole or has a singular pivot minor. *)
observableTransportFFFreshTrialPool[primeCount_Integer,
    pointsPerPrime_Integer, variableCount_Integer, usedPrimes_List,
    seed_Integer] := BlockRandom[Module[
  {primes = {}, trials = {}, prime, point, seen = <||>, attempts,
   pointCount},
  SeedRandom[seed];
  attempts = Max[pointsPerPrime + 4, 3 pointsPerPrime];
  While[Length[primes] < primeCount,
    prime = RandomPrime[{2^30, 2^31 - 1}];
    If[MemberQ[Join[usedPrimes, primes], prime], Continue[]];
    AppendTo[primes, prime]];
  Do[
    pointCount = 0;
    While[pointCount < attempts,
      point = RandomInteger[{2, prime - 2}, variableCount];
      If[KeyExistsQ[seen, ToString[{prime, point}, InputForm]], Continue[]];
      AssociateTo[seen, ToString[{prime, point}, InputForm] -> True];
      AppendTo[trials, <|"Prime" -> prime, "Point" -> point|>];
      pointCount++],
    {prime, primes}];
  <|"Primes" -> primes, "Trials" -> trials,
    "AttemptsPerPrime" -> attempts, "Seed" -> seed|>
]];

(* Evaluate only enough matrix points to supply the requested validation and
   an optional reserve.  Identity-prefix matrix reconstruction has no sampled
   pivot minor, so it does not pay for a reserve that it cannot need. *)
observableTransportFFSelectMatrixTrials[compiledMatrix_, trialPool_,
    pointsPerPrime_Integer, reservePerPrime_Integer : 1] := Module[
  {selectedTrials = {}, selectedImages = {}, rejected = {}, target,
   acceptedForPrime, image, trial},
  target = pointsPerPrime + Max[0, reservePerPrime];
  Do[
    acceptedForPrime = 0;
    Do[
      If[acceptedForPrime >= target, Break[]];
      trial = candidateTrial;
      image = observableTransportFFMatrixValue[
        compiledMatrix, trial["Point"], prime];
      If[image === $Failed,
        AppendTo[rejected, Join[trial, <|"Reason" -> "MatrixPole"|>]],
        AppendTo[selectedTrials, trial];
        AppendTo[selectedImages, image];
        acceptedForPrime++],
      {candidateTrial, Select[trialPool["Trials"],
        #1["Prime"] === prime &]}];
    If[acceptedForPrime < pointsPerPrime,
      Return[observableTransportFFFailure[
        "InsufficientFreshMatrixPoints", <|"Prime" -> prime,
          "Accepted" -> acceptedForPrime,
          "Required" -> pointsPerPrime|>], Module]],
    {prime, trialPool["Primes"]}];
  <|"Status" -> "FreshMatrixTrialsSelected",
    "Trials" -> selectedTrials, "Images" -> selectedImages,
    "RejectedTrials" -> rejected|>
];

observableTransportFFAliasData[variables_List] := Module[
  {names, symbols},
  names = Take[$observableTransportFFAliasNames, Length[variables]];
  symbols = Symbol["Global`" <> #] & /@ names;
  <|"Names" -> names, "Symbols" -> symbols,
    "ForwardRules" -> Thread[variables -> symbols],
    "OriginalByName" -> AssociationThread[names, variables]|>
];

observableTransportFFExpressionString[expression_, aliasData_Association] :=
 Module[{text},
  text = ToString[expression /. aliasData["ForwardRules"], InputForm,
    PageWidth -> Infinity];
  Fold[StringReplace[#1, "Global`" <> #2 -> #2] &,
    text, aliasData["Names"]]
];

observableTransportFFWorkDirectory[requested_, key_] := Module[
  {directory, name, persistent},
  Which[
    requested === Automatic || requested === None,
      directory = CreateDirectory[]; persistent = False,
    StringQ[requested] && requested =!= "",
      directory = ExpandFileName[requested];
      If[! DirectoryQ[directory],
        Quiet[Check[CreateDirectory[directory,
          CreateIntermediateDirectories -> True], Return[$Failed]]]];
      name = If[key === Automatic, CreateUUID["coordinate-"],
        StringReplace[If[StringQ[key], key, ToString[key, InputForm]],
          Except[LetterCharacter | DigitCharacter | "-" | "_" | "."] ->
            "_"]];
      If[name === "", name = CreateUUID["coordinate-"]];
      directory = FileNameJoin[{directory, name}];
      If[! DirectoryQ[directory],
        Quiet[Check[CreateDirectory[directory,
          CreateIntermediateDirectories -> True], Return[$Failed]]]];
      persistent = True,
    True, Return[$Failed]
  ];
  <|"Directory" -> directory, "Persistent" -> persistent|>
];

observableTransportFFResolveRatracer[requested_] := Module[
  {environment, candidates, found},
  If[StringQ[requested] && requested =!= "",
    found = ExpandFileName[requested];
    Return[If[FileExistsQ[found], found, $Failed]]];
  If[requested =!= Automatic, Return[$Failed]];
  environment = Environment["FACET_RATRACER"];
  candidates = DeleteCases[{
      If[ValueQ[Global`$FACETRatracerExecutable],
        Global`$FACETRatracerExecutable, Nothing],
      If[StringQ[environment] && environment =!= "", environment, Nothing],
      If[ValueQ[$feynFacetAddonRoot],
        FileNameJoin[{$feynFacetAddonRoot, "Addon", "Other_Addon",
          "Ratracer", "bin", "ratracer"}], Nothing],
      Quiet[Check[FindExecutable["ratracer"], Nothing]]},
    Except[_String]];
  found = SelectFirst[candidates, FileExistsQ, $Failed];
  If[StringQ[found], ExpandFileName[found], $Failed]
];

observableTransportFFWriteEquations[pivotBasis_, pivotTargets_,
    aliasData_Association, directory_String] := Module[
  {rank, rhsColumns, blocks, terms, coefficient, text, file, temporary,
   written, render},
  render[value_] := render[value] =
    observableTransportFFExpressionString[value, aliasData];
  rank = Length[pivotBasis];
  rhsColumns = Dimensions[pivotTargets][[2]];
  blocks = Table[
    terms = Join[
      Table[
        coefficient = pivotBasis[[row, column]];
        If[TrueQ[coefficient === 0], Nothing,
          "dep@" <> ToString[column] <> "*(" <>
            render[-coefficient] <> ")"],
        {column, rank}],
      Table[
        coefficient = pivotTargets[[row, column]];
        If[TrueQ[coefficient === 0], Nothing,
          "master@" <> ToString[column] <> "*(" <>
            render[coefficient] <> ")"],
        {column, rhsColumns}]];
    StringRiffle[terms, "\n"],
    {row, rank}];
  text = StringRiffle[blocks, "\n\n"] <> "\n";
  file = FileNameJoin[{directory, "coordinate_system_ratracer.eqns"}];
  temporary = file <> ".partial-" <> ToString[$ProcessID];
  written = Quiet[Check[
    Export[temporary, text, "Text"];
    RenameFile[temporary, file, OverwriteTarget -> True]; True, False]];
  If[TrueQ[written], file, $Failed]
];

observableTransportFFRunRatracer[directory_String, executable_String,
    aliasData_Association, threads_Integer] := Module[
  {traceFile, solutionFile, traceInputFile, traceOutputFile, traceLog,
   reconstructLog, tracePoint, setArguments, traceCommand,
   reconstructCommand, traceResult, reconstructResult, traceSeconds,
   reconstructSeconds, render},
  traceFile = FileNameJoin[{directory, "coordinate_system.trace.gz"}];
  solutionFile = FileNameJoin[{directory, "coordinate_solution.txt"}];
  traceInputFile = FileNameJoin[{directory, "trace_inputs.txt"}];
  traceOutputFile = FileNameJoin[{directory, "trace_outputs.txt"}];
  traceLog = FileNameJoin[{directory, "trace_build.log"}];
  reconstructLog = FileNameJoin[{directory, "reconstruct.log"}];
  tracePoint = Take[{123457, 765431}, Length[aliasData["Names"]]];
  setArguments = Flatten[MapThread[
    {"--set", #1, ToString[#2]} &,
    {aliasData["Names"], tracePoint}]];
  traceCommand = Join[{executable, "configure-tracing",
      "--modulus=" <> ToString[$observableTransportFFTracePrime]},
    setArguments,
    {"define-family", "master", "define-family", "dep",
      "load-equations", "coordinate_system_ratracer.eqns",
      "solve-equations", "choose-equation-outputs", "--family=dep",
      "optimize", "finalize", "save-trace", FileNameTake[traceFile],
      "list-inputs", "--to=" <> FileNameTake[traceInputFile],
      "list-outputs", "--to=" <> FileNameTake[traceOutputFile], "stat"}];
  {traceSeconds, traceResult} = AbsoluteTiming[
    Quiet[Check[RunProcess[traceCommand, All,
      ProcessDirectory -> directory], $Failed]]];
  render = If[AssociationQ[traceResult],
    Lookup[traceResult, "StandardOutput", ""] <>
      Lookup[traceResult, "StandardError", ""], "RunProcess failed\n"];
  Quiet[Export[traceLog, render, "Text"]];
  If[! AssociationQ[traceResult] ||
      Lookup[traceResult, "ExitCode", 1] =!= 0 ||
      ! FileExistsQ[traceFile],
    Return[observableTransportFFFailure["RatracerTraceBuildFailed", <|
      "TraceSeconds" -> traceSeconds, "TraceLog" -> traceLog|>]]];
  reconstructCommand = {executable, "load-trace", FileNameTake[traceFile],
    "reconstruct", "--to=" <> FileNameTake[solutionFile],
    "--threads=" <> ToString[threads], "--inmem", "--factor-scan",
    "--shift-scan"};
  {reconstructSeconds, reconstructResult} = AbsoluteTiming[
    Quiet[Check[RunProcess[reconstructCommand, All,
      ProcessDirectory -> directory], $Failed]]];
  render = If[AssociationQ[reconstructResult],
    Lookup[reconstructResult, "StandardOutput", ""] <>
      Lookup[reconstructResult, "StandardError", ""],
    "RunProcess failed\n"];
  Quiet[Export[reconstructLog, render, "Text"]];
  If[! AssociationQ[reconstructResult] ||
      Lookup[reconstructResult, "ExitCode", 1] =!= 0 ||
      ! FileExistsQ[solutionFile],
    Return[observableTransportFFFailure["RatracerReconstructionFailed", <|
      "TraceSeconds" -> traceSeconds,
      "ReconstructionSeconds" -> reconstructSeconds,
      "ReconstructionLog" -> reconstructLog|>]]];
  <|"Status" -> "RatracerCandidateReconstructed",
    "SolutionFile" -> solutionFile, "TraceFile" -> traceFile,
    "TraceOutputFile" -> traceOutputFile,
    "TracePrime" -> $observableTransportFFTracePrime,
    "TracePoint" -> tracePoint, "TraceSeconds" -> traceSeconds,
    "ReconstructionSeconds" -> reconstructSeconds|>
];

observableTransportFFMarker[line_String] := Module[{matches},
  matches = StringCases[StringTrim[line],
    RegularExpression[
      "^CO\\[dep@([0-9]+),master@([0-9]+)\\]\\s*=\\s*$"] :>
      {"$1", "$2"}];
  If[Length[matches] === 1, ToExpression /@ First[matches], None]
];

observableTransportFFHeldRationalQ[held_HoldComplete,
    aliasNames_List] := Module[{symbols, allowed},
  symbols = DeleteDuplicates[Cases[held, _Symbol, Infinity,
    Heads -> True]];
  allowed = {HoldComplete, Plus, Times, Power, Rational};
  AllTrue[symbols,
    MemberQ[allowed, Unevaluated[#]] ||
      MemberQ[aliasNames, SymbolName[Unevaluated[#]]] &] &&
    FreeQ[held, HoldPattern[Power[_, exponent_]] /;
      ! IntegerQ[Unevaluated[exponent]]]
];

observableTransportFFParseExpression[text_String,
    aliasData_Association, variables_List] := Module[
  {trimmed, held, parsedSymbols, rules, expression, compiled},
  trimmed = StringTrim[text];
  If[! StringEndsQ[trimmed, ";"],
    Return[observableTransportFFFailure[
      "CoordinateCandidateExpressionUnterminated"]]];
  trimmed = StringTrim[StringDrop[trimmed, -1]];
  If[trimmed === "",
    Return[observableTransportFFFailure[
      "CoordinateCandidateExpressionEmpty"]]];
  held = Quiet[Check[ToExpression[trimmed, InputForm, HoldComplete],
    $Failed]];
  If[Head[held] =!= HoldComplete ||
      ! observableTransportFFHeldRationalQ[held, aliasData["Names"]],
    Return[observableTransportFFFailure[
      "CoordinateCandidateExpressionGrammarRejected"]]];
  parsedSymbols = DeleteDuplicates[Cases[held,
    symbol_Symbol /; MemberQ[aliasData["Names"],
      SymbolName[Unevaluated[symbol]]] :> symbol, Infinity]];
  rules = Dispatch[(# -> aliasData["OriginalByName"][
        SymbolName[Unevaluated[#]]]) & /@ parsedSymbols];
  expression = ReleaseHold[held] /. rules;
  compiled = observableTransportFFCompile[expression, variables];
  If[compiled === $Failed,
    observableTransportFFFailure[
      "CoordinateCandidateExpressionNotRational"],
    <|"Status" -> "CoordinateCandidateExpressionParsed",
      "Expression" -> expression, "Compiled" -> compiled|>]
];

observableTransportFFTraceOutputKeys[file_String, rank_Integer,
    rhsColumns_Integer] := Module[{lines, matches, keys},
  If[! FileExistsQ[file], Return[Automatic]];
  lines = Quiet[Check[Import[file, "Lines"], $Failed]];
  If[lines === $Failed, Return[$Failed]];
  matches = Flatten[StringCases[lines,
    RegularExpression[
      "^[0-9]+\\s+CO\\[dep@([0-9]+),master@([0-9]+)\\]\\s*$"] :>
      {"$1", "$2"}], 1];
  keys = (ToExpression /@ #) & /@ matches;
  If[Length[DeleteDuplicates[keys]] =!= Length[keys] ||
      ! AllTrue[keys, 1 <= #[[1]] <= rank &&
          1 <= #[[2]] <= rhsColumns &], $Failed, keys]
];

(* Stream one output at a time.  The final sparse rules necessarily retain the
   requested result, but the complete text and an additional parsed copy never
   coexist in memory.  All validation images are filled during this pass. *)
observableTransportFFParseSolution[file_String, aliasData_Association,
    variables_List, rank_Integer, rhsColumns_Integer, trials_List,
    initialValidity_List, expectedKeys_] := Catch[Module[
  {stream, line, marker, current = None, lines = {}, seen = <||>,
   validity = initialValidity, images, parsed = 0, reaped, parsedBlock,
   compiled, values, keyString, finish, resultRules, expected},
  If[! FileExistsQ[file],
    Throw[observableTransportFFFailure["CoordinateCandidateMissing", <|
      "SolutionFile" -> file|>], "parse"]];
  images = Table[ConstantArray[0, {rank, rhsColumns}],
    {Length[trials]}];
  finish[] := Module[{text},
    If[current === None, Return[Null]];
    text = StringRiffle[lines, "\n"];
    parsedBlock = observableTransportFFParseExpression[
      text, aliasData, variables];
    If[Lookup[parsedBlock, "Status", None] =!=
        "CoordinateCandidateExpressionParsed",
      Throw[Join[parsedBlock, <|"Coordinate" -> current|>], "parse"]];
    keyString = ToString[current, InputForm];
    If[KeyExistsQ[seen, keyString],
      Throw[observableTransportFFFailure[
        "CoordinateCandidateDuplicate", <|"Coordinate" -> current|>],
        "parse"]];
    AssociateTo[seen, keyString -> True];
    compiled = parsedBlock["Compiled"];
    values = MapThread[
      If[TrueQ[#2], observableTransportFFValue[compiled,
          #1["Point"], #1["Prime"]], $Failed] &,
      {trials, validity}];
    Do[
      If[TrueQ[validity[[trial]]],
        If[values[[trial]] === $Failed,
          validity[[trial]] = False,
          images[[trial, current[[1]], current[[2]]]] = values[[trial]]]],
      {trial, Length[trials]}];
    Sow[current -> parsedBlock["Expression"], "rules"];
    parsed++;
    Null
  ];
  stream = Quiet[Check[OpenRead[file], $Failed]];
  If[Head[stream] =!= InputStream,
    Throw[observableTransportFFFailure[
      "CoordinateCandidateUnreadable"], "parse"]];
  reaped = Reap[
    While[(line = ReadLine[stream]) =!= EndOfFile,
      marker = observableTransportFFMarker[line];
      If[ListQ[marker],
        finish[];
        If[! (1 <= marker[[1]] <= rank &&
              1 <= marker[[2]] <= rhsColumns),
          Quiet[Close[stream]];
          Throw[observableTransportFFFailure[
            "CoordinateCandidateIndexOutOfRange", <|
              "Coordinate" -> marker|>], "parse"]];
        current = marker; lines = {},
        If[current =!= None, AppendTo[lines, line],
          If[StringTrim[line] =!= "",
            Quiet[Close[stream]];
            Throw[observableTransportFFFailure[
              "CoordinateCandidatePreambleRejected"], "parse"]]]]
    ];
    finish[], "rules"];
  Quiet[Close[stream]];
  resultRules = If[Length[reaped[[2]]] === 0, {}, First[reaped[[2]]]];
  expected = If[ListQ[expectedKeys], Sort[expectedKeys], Automatic];
  If[ListQ[expected] && Sort[First /@ resultRules] =!= expected,
    Throw[observableTransportFFFailure[
      "CoordinateCandidateOutputInventoryMismatch", <|
        "ExpectedOutputs" -> Length[expected],
        "ParsedOutputs" -> Length[resultRules]|>], "parse"]];
  <|"Status" -> "CoordinateCandidateParsed", "Rules" -> resultRules,
    "Images" -> images, "Validity" -> validity,
    "ParsedOutputs" -> parsed|>
], "parse"];

(* Use the existing CFFA4 multi-RHS wire protocol with an explicitly resolved
   adapter.  Keeping the tiny transport here makes this new file testable before
   FeynFacet.m loads it and permits a caller to name an installed adapter. *)
observableTransportFFFLINTSolve[core_, rhs_, prime_Integer,
    threads_Integer, binary_String] := Module[
  {directory, input, output, stream = None, rows, columns, rhsColumns,
   process, magic, header, values, solution, cleanup},
  {rows, columns} = Dimensions[core];
  rhsColumns = Dimensions[rhs][[2]];
  If[rows =!= columns || rows < 1 || rhsColumns < 1 ||
      ! FileExistsQ[binary], Return[$Failed]];
  directory = CreateDirectory[];
  input = FileNameJoin[{directory, "core.bin"}];
  output = FileNameJoin[{directory, "solution.bin"}];
  cleanup[] := Quiet[Check[
    If[stream =!= None, Close[stream]; stream = None];
    If[DirectoryQ[directory], DeleteDirectory[directory,
      DeleteContents -> True]], Null]];
  Catch[
    stream = OpenWrite[input, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["CFFA4V1\000"],
      "UnsignedInteger8"];
    BinaryWrite[stream, {rows, columns, rhsColumns, prime},
      "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[Mod[Normal[core], prime]],
      "UnsignedInteger64", ByteOrdering -> -1];
    BinaryWrite[stream, Flatten[Mod[Normal[rhs], prime]],
      "UnsignedInteger64", ByteOrdering -> -1];
    Close[stream]; stream = None;
    process = Quiet[Check[RunProcess[{binary, input, output,
      ToString[Clip[threads, {1, 4}]]}], $Failed]];
    If[! AssociationQ[process] || process["ExitCode"] =!= 0,
      Throw[$Failed, "flint"]];
    stream = OpenRead[output, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    header = BinaryReadList[stream, "UnsignedInteger64", 3,
      ByteOrdering -> -1];
    values = BinaryReadList[stream, "UnsignedInteger64",
      If[Length[header] === 3, header[[1]] header[[2]], 0],
      ByteOrdering -> -1];
    Close[stream]; stream = None;
    If[magic =!= ToCharacterCode["CFFA4X1\000"] ||
        header =!= {columns, rhsColumns, prime} ||
        Length[values] =!= columns rhsColumns,
      Throw[$Failed, "flint"]];
    solution = ArrayReshape[values, {columns, rhsColumns}];
    cleanup[];
    solution,
    "flint", (cleanup[]; $Failed) &]
];

(* Prefer the existing CFFA4 multi-RHS adapter when installed.  Failure of an
   installed adapter is fatal.  Its absence selects the explicitly recorded
   Wolfram modular solve; this is not a silent fallback. *)
observableTransportFFPivotSolve[a_, b_, prime_Integer,
    threads_Integer, requestedFLINT_: Automatic] := Module[
  {binary, solution},
  binary = Which[
    StringQ[requestedFLINT] && requestedFLINT =!= "",
      ExpandFileName[requestedFLINT],
    requestedFLINT === Automatic &&
        Length[DownValues[finiteFieldStripFLINTBinary]] > 0,
      Quiet[Check[finiteFieldStripFLINTBinary[], None]],
    requestedFLINT === None, None,
    True, $Failed];
  If[binary === $Failed || (StringQ[binary] && ! FileExistsQ[binary]),
    Return[observableTransportFFFailure[
      "FreshModularFLINTExecutableInvalid"]]];
  If[StringQ[binary] && FileExistsQ[binary],
    solution = observableTransportFFFLINTSolve[
      a, b, prime, threads, binary];
    If[solution === $Failed ||
        ! (MatrixQ[solution, IntegerQ] &&
          Dimensions[solution] === {Dimensions[a][[2]],
            Dimensions[b][[2]]} &&
          AllTrue[Flatten[Mod[a . solution - b, prime]], # === 0 &]),
      observableTransportFFFailure["FreshModularFLINTSolveFailed"],
      <|"Status" -> "FreshModularPivotSolved",
        "Solver" -> "FLINTMultiRHS", "Solution" -> solution|>],
    solution = Quiet[Check[LinearSolve[a, b, Modulus -> prime], $Failed]];
    If[solution === $Failed || ! MatrixQ[solution, IntegerQ] ||
        ! AllTrue[Flatten[Mod[a . solution - b, prime]], # === 0 &],
      observableTransportFFFailure["FreshModularWolframSolveFailed"],
      <|"Status" -> "FreshModularPivotSolved",
        "Solver" -> "WolframModularLinearSolve",
        "Solution" -> Mod[solution, prime]|>]
  ]
];

observableTransportFFValidateCandidate[matrixImages_List,
    solutionImages_List, validity_List, trials_List, primes_List,
    pivots_List, nonbasisRows_List, pivotRows_List,
    pointsPerPrime_Integer, threads_Integer,
    requestedFLINT_: Automatic] := Module[
  {rank = Length[pivots], accepted = {}, rejected = {}, solvers = {},
   prime, primeIndex = 1, pointPosition, index, indices,
   acceptedForPrime, matrix, basis, a, b, square, rhs, solution,
   solveRecord, complementRows, residual},
  While[primeIndex <= Length[primes],
    prime = primes[[primeIndex]];
    acceptedForPrime = 0;
    indices = Select[Range[Length[trials]], Function[trialIndex,
      Lookup[trials[[trialIndex]], "Prime", None] === prime]];
    pointPosition = 1;
    While[pointPosition <= Length[indices] &&
        acceptedForPrime < pointsPerPrime,
      index = indices[[pointPosition]];
      pointPosition++;
      If[! TrueQ[validity[[index]]],
        AppendTo[rejected, Join[trials[[index]],
          <|"Reason" -> "DenominatorZero"|>]]; Continue[]];
      matrix = matrixImages[[index]];
      If[rank === 0,
        If[AllTrue[Flatten[Mod[matrix, prime]], # === 0 &],
          AppendTo[accepted, Join[trials[[index]], <|
            "PivotNonsingular" -> True, "PivotSolve" -> "ZeroRank",
            "ComplementRowsChecked" -> Dimensions[matrix][[2]],
            "FullResidualZero" -> True|>]];
          acceptedForPrime++,
          Return[observableTransportFFFailure[
            "FreshModularIdentityRejected", <|
              "Prime" -> prime, "Point" -> trials[[index]]["Point"],
              "Reason" -> "ProposedZeroRankIsNonzero"|>]]];
        Continue[]];
      basis = matrix[[pivots]];
      a = Transpose[basis];
      square = a[[pivotRows]];
      If[MatrixRank[square, Modulus -> prime] =!= rank,
        AppendTo[rejected, Join[trials[[index]],
          <|"Reason" -> "PivotMinorSingular"|>]]; Continue[]];
      If[nonbasisRows === {},
        AppendTo[accepted, Join[trials[[index]], <|
          "PivotNonsingular" -> True,
          "PivotSolve" -> "IdentityCoordinates",
          "ComplementRowsChecked" -> Length[a] - Length[pivotRows],
          "FullResidualZero" -> True|>]];
        acceptedForPrime++; Continue[]];
      b = Transpose[matrix[[nonbasisRows]]];
      rhs = b[[pivotRows]];
      solution = solutionImages[[index]];
      solveRecord = observableTransportFFPivotSolve[
        square, rhs, prime, threads, requestedFLINT];
      If[Lookup[solveRecord, "Status", None] =!=
          "FreshModularPivotSolved",
        Return[Join[solveRecord, <|"Prime" -> prime,
          "Point" -> trials[[index]]["Point"]|>]]];
      If[Mod[solveRecord["Solution"] - solution, prime] =!=
          ConstantArray[0, Dimensions[solution]],
        Return[observableTransportFFFailure[
          "FreshModularIdentityRejected", <|
            "Prime" -> prime, "Point" -> trials[[index]]["Point"],
            "Reason" -> "IndependentPivotSolutionMismatch"|>]]];
      complementRows = Complement[Range[Length[a]], pivotRows];
      residual = If[complementRows === {}, {},
        Mod[a[[complementRows]] . solution - b[[complementRows]], prime]];
      If[! AllTrue[Flatten[residual], # === 0 &],
        Return[observableTransportFFFailure[
          "FreshModularIdentityRejected", <|
            "Prime" -> prime, "Point" -> trials[[index]]["Point"],
            "Reason" -> "ComplementaryRowResidualNonzero"|>]]];
      If[! AllTrue[Flatten[Mod[a . solution - b, prime]], # === 0 &],
        Return[observableTransportFFFailure[
          "FreshModularIdentityRejected", <|
            "Prime" -> prime, "Point" -> trials[[index]]["Point"],
            "Reason" -> "FullResidualNonzero"|>]]];
      AppendTo[solvers, solveRecord["Solver"]];
      AppendTo[accepted, Join[trials[[index]], <|
        "PivotNonsingular" -> True,
        "PivotSolve" -> solveRecord["Solver"],
        "ComplementRowsChecked" -> Length[complementRows],
        "FullResidualZero" -> True|>]];
      acceptedForPrime++
    ];
    If[acceptedForPrime < pointsPerPrime,
      Return[observableTransportFFFailure[
        "InsufficientFreshModularPoints", <|"Prime" -> prime,
          "Accepted" -> acceptedForPrime,
          "Required" -> pointsPerPrime|>]]];
    primeIndex++
  ];
  If[Length[accepted] =!= Length[primes] pointsPerPrime,
    Return[observableTransportFFFailure[
      "FreshModularAcceptanceInventoryIncomplete", <|
        "Accepted" -> Length[accepted],
        "Required" -> Length[primes] pointsPerPrime|>]]];
  <|"Status" -> "FreshModularIdentityAccepted",
    "AcceptedTrials" -> accepted, "RejectedTrials" -> rejected,
    "PivotSolvers" -> DeleteDuplicates[solvers],
    "ComplementRowsChecked" -> True|>
];

observableTransportModularRowBasis[m_, variables_List,
    sampleRules_List, OptionsPattern[]] := Module[
  {dimensions, rowCount, columnCount, backend, cacheDirectory, threads,
   primeCount, pointsPerPrime, verbose, coordinateKey, executableOption,
   flintExecutable, validationSeed, samples, fallbackSamples, proposals,
   selected, pivots, rank, basis,
   nonbasisRows, transposeBasis, pivotRows, candidatePivotRows,
   aliasData, workRecord, directory, solutionFile, outputFile,
   candidateSource, executable, pivotBasis, pivotTargets, equationFile,
   runRecord = <||>, traceExpected, trialPool, trials, compiledMatrix,
   invalidCompilePositions, invalidCompileEntries, unsupportedHeads,
   matrixImages, initialValidity, trialSelection, parseRecord, solutionRules,
   solutionImages, validation, coordinateRules, coordinates, certificate,
   start, cachePersistent, structuralIdentityPrefix},
  start = AbsoluteTime[];
  dimensions = Quiet[Check[Dimensions[m], {}]];
  If[Length[dimensions] =!= 2 || ! MatrixQ[m],
    Return[observableTransportFFFailure["ModularRowBasisMatrixInvalid"]]];
  {rowCount, columnCount} = dimensions;
  If[! MatchQ[variables, {_Symbol ..}] ||
      ! Between[Length[variables], {1, 2}] ||
      ! DuplicateFreeQ[variables],
    Return[observableTransportFFFailure[
      "ModularRowBasisVariablesInvalid"]]];
  backend = OptionValue["CoordinateBackend"];
  cacheDirectory = OptionValue["CoordinateCacheDirectory"];
  threads = Replace[OptionValue["ReconstructionThreads"], Automatic -> 1];
  primeCount = OptionValue["ValidationPrimeCount"];
  pointsPerPrime = OptionValue["ValidationPointsPerPrime"];
  verbose = TrueQ[OptionValue["Verbose"]];
  coordinateKey = OptionValue["CoordinateKey"];
  executableOption = OptionValue["RatracerExecutable"];
  flintExecutable = OptionValue["FLINTExecutable"];
  validationSeed = Replace[OptionValue["ValidationSeed"],
    Automatic :> RandomInteger[{1, 2^31 - 1}]];
  structuralIdentityPrefix =
    TrueQ[OptionValue["StructuralIdentityPrefix"]];
  If[! MemberQ[{Automatic, "Ratracer"}, backend],
    Return[observableTransportFFFailure[
      "CoordinateBackendUnsupported", <|"CoordinateBackend" -> backend|>]]];
  If[! IntegerQ[threads] || ! Between[threads, {1, 64}] ||
      ! IntegerQ[primeCount] || primeCount < 1 ||
      ! IntegerQ[pointsPerPrime] || pointsPerPrime < 1 ||
      ! IntegerQ[validationSeed],
    Return[observableTransportFFFailure[
      "ModularRowBasisOptionsInvalid"]]];
  samples = observableTransportFFNormalizeSamples[sampleRules, variables];
  If[samples === {},
    Return[observableTransportFFFailure[
      "ModularRowBasisSamplesInvalid"]]];
  If[structuralIdentityPrefix,
    If[rowCount < columnCount ||
        ! TrueQ[Take[Normal[m], columnCount] ===
          IdentityMatrix[columnCount]],
      Return[observableTransportFFFailure[
        "StructuralIdentityPrefixInvalid"]]];
    selected = <|"Rules" -> First[samples],
      "Method" -> "StructuralIdentityPrefix"|>;
    pivots = Range[columnCount];
    rank = columnCount;
    basis = IdentityMatrix[columnCount];
    nonbasisRows = Range[columnCount + 1, rowCount];
    transposeBasis = basis;
    pivotRows = Range[columnCount],

    proposals = DeleteCases[Table[
      With[{candidate = observableTransportFFIndependentRows[m, rules]},
        If[candidate === $Failed, Nothing,
          <|"Rules" -> rules, "Pivots" -> candidate|>]],
      {rules, samples}], Nothing];
    (* Path base/target samples are chosen for letter regularity, not for every
       later quotient minor.  Use a deterministic reserve only if none of the
       caller's samples is evaluable; do not silently replace an evaluable
       rank proposal, whose rejected complement is an important safety test. *)
    If[proposals === {},
      fallbackSamples = Table[
        Thread[variables -> Table[
          (2 attempt + variableIndex + 1)/
            (19 + 2 attempt + 3 variableIndex),
          {variableIndex, Length[variables]}]],
        {attempt, 1, 8}];
      proposals = DeleteCases[Table[
        With[{candidate = observableTransportFFIndependentRows[m, rules]},
          If[candidate === $Failed, Nothing,
            <|"Rules" -> rules, "Pivots" -> candidate|>]],
        {rules, fallbackSamples}], Nothing]
    ];
    If[proposals === {}, Return[observableTransportFFFailure[
      "ModularRowBasisRankProposalFailed"]]];
    selected = First@MaximalBy[proposals, Length[#1["Pivots"]] &];
    pivots = selected["Pivots"];
    rank = Length[pivots];
    basis = If[rank === 0,
      SparseArray[{}, {0, columnCount}], m[[pivots]]];
    nonbasisRows = Complement[Range[rowCount], pivots];
    transposeBasis = Transpose[basis];
    pivotRows = If[rank === 0, {},
      observableTransportFFIndependentRows[
        transposeBasis, selected["Rules"]]];
    If[rank > 0 && (pivotRows === $Failed || Length[pivotRows] =!= rank),
      candidatePivotRows = DeleteCases[
        observableTransportFFIndependentRows[transposeBasis, #] & /@ samples,
        $Failed];
      pivotRows = SelectFirst[candidatePivotRows,
        Length[#] === rank &, $Failed]];
    If[rank > 0 && (pivotRows === $Failed || Length[pivotRows] =!= rank),
      Return[observableTransportFFFailure[
        "ModularRowBasisPivotRowsFailed"]]]
  ];

  (* Compile only the existing arithmetic trees.  No characteristic-zero
     rational normalization is performed here or in the candidate parser. *)
  compiledMatrix = observableTransportFFCompileMatrix[m, variables];
  If[compiledMatrix === $Failed,
    invalidCompilePositions = Select[
      Tuples[Range /@ Dimensions[m]],
      observableTransportFFCompile[Extract[m, #], variables] === $Failed &];
    invalidCompileEntries = Extract[m,
      Take[invalidCompilePositions, UpTo[3]]];
    unsupportedHeads = DeleteDuplicates[Cases[invalidCompileEntries,
      head_[___] /; ! MemberQ[{Plus, Times, Power},
          Unevaluated[head]] :> Unevaluated[head], Infinity]];
    Return[observableTransportFFFailure[
      "ModularRowBasisEntriesNotRational", <|
        "InvalidEntryCount" -> Length[invalidCompilePositions],
        "InvalidEntryPositions" ->
          Take[invalidCompilePositions, UpTo[20]],
        "UnsupportedHeads" -> unsupportedHeads,
        "InvalidEntryExamples" -> invalidCompileEntries|>]]];
  trialPool = observableTransportFFFreshTrialPool[
    primeCount, pointsPerPrime, Length[variables],
    {$observableTransportFFTracePrime}, validationSeed];
  trialSelection = observableTransportFFSelectMatrixTrials[
    compiledMatrix, trialPool, pointsPerPrime,
    If[structuralIdentityPrefix, 0, 1]];
  If[! AssociationQ[trialSelection] ||
      Lookup[trialSelection, "Status", None] =!=
        "FreshMatrixTrialsSelected",
    Return[If[AssociationQ[trialSelection], trialSelection,
      observableTransportFFFailure[
        "FreshMatrixTrialSelectionFailed"]]]];
  trials = trialSelection["Trials"];
  matrixImages = trialSelection["Images"];
  initialValidity = ConstantArray[True, Length[trials]];

  aliasData = observableTransportFFAliasData[variables];
  workRecord = observableTransportFFWorkDirectory[
    cacheDirectory, coordinateKey];
  If[workRecord === $Failed,
    Return[observableTransportFFFailure[
      "CoordinateWorkDirectoryInvalid"]]];
  directory = workRecord["Directory"];
  cachePersistent = workRecord["Persistent"];
  solutionFile = FileNameJoin[{directory, "coordinate_solution.txt"}];
  outputFile = FileNameJoin[{directory, "trace_outputs.txt"}];

  If[rank === 0 || nonbasisRows === {},
    candidateSource = "Structural";
    solutionRules = {};
    solutionImages = Table[ConstantArray[0,
      {rank, Length[nonbasisRows]}], {Length[trials]}],

    candidateSource = If[FileExistsQ[solutionFile],
      "Cache", "Reconstructed"];
    If[candidateSource === "Reconstructed",
      executable = observableTransportFFResolveRatracer[executableOption];
      If[executable === $Failed,
        Return[observableTransportFFFailure[
          "RatracerExecutableMissing", <|"WorkDirectory" -> directory|>]]];
      pivotBasis = Normal[transposeBasis[[pivotRows]]];
      pivotTargets = Normal[Transpose[m[[nonbasisRows]]][[pivotRows]]];
      equationFile = observableTransportFFWriteEquations[
        pivotBasis, pivotTargets, aliasData, directory];
      If[equationFile === $Failed,
        Return[observableTransportFFFailure[
          "RatracerEquationWriteFailed", <|"WorkDirectory" -> directory|>]]];
      runRecord = observableTransportFFRunRatracer[
        directory, executable, aliasData, threads];
      If[Lookup[runRecord, "Status", None] =!=
          "RatracerCandidateReconstructed", Return[runRecord]]];
    traceExpected = observableTransportFFTraceOutputKeys[
      outputFile, rank, Length[nonbasisRows]];
    If[traceExpected === $Failed,
      Return[observableTransportFFFailure[
        "RatracerOutputInventoryInvalid", <|"WorkDirectory" -> directory|>]]];
    parseRecord = observableTransportFFParseSolution[
      solutionFile, aliasData, variables, rank, Length[nonbasisRows],
      trials, initialValidity, traceExpected];
    If[Lookup[parseRecord, "Status", None] =!=
        "CoordinateCandidateParsed",
      Return[Join[parseRecord, <|"CandidateSource" -> candidateSource,
        "WorkDirectory" -> directory|>]]];
    solutionRules = parseRecord["Rules"];
    solutionImages = parseRecord["Images"];
    initialValidity = parseRecord["Validity"]
  ];

  validation = observableTransportFFValidateCandidate[
    matrixImages, solutionImages, initialValidity, trials,
    trialPool["Primes"], pivots, nonbasisRows, pivotRows,
    pointsPerPrime, threads, flintExecutable];
  If[Lookup[validation, "Status", None] =!=
      "FreshModularIdentityAccepted",
    Return[Join[validation, <|"CandidateSource" -> candidateSource,
      "WorkDirectory" -> directory|>]]];

  coordinateRules = Join[
    Table[{pivots[[index]], index} -> 1, {index, rank}],
    (({nonbasisRows[[First[#][[2]]]], First[#][[1]]} -> Last[#]) &) /@
      solutionRules];
  coordinates = SparseArray[coordinateRules, {rowCount, rank}];
  certificate = <|
    "Status" -> "FreshModularIdentityAccepted",
    "Accepted" -> True,
    "Probabilistic" -> True,
    "Exact" -> False,
    "CoordinateBackendRequested" -> backend,
    "CoordinateBackendUsed" -> If[candidateSource === "Structural",
      "Structural", "RatracerTracedMultiRHS"],
    "CandidateSource" -> candidateSource,
    "CoefficientVariables" -> variables,
    "RatracerAliases" -> AssociationThread[
      SymbolName /@ variables, aliasData["Names"]],
    "RankProposalRules" -> selected["Rules"],
    "PivotRows" -> pivotRows,
    "ValidationSeed" -> validationSeed,
    "ValidationPrimeCount" -> primeCount,
    "ValidationPointsPerPrime" -> pointsPerPrime,
    "FreshPrimes" -> trialPool["Primes"],
    "GeneratedFreshTrialCount" -> Length[trialPool["Trials"]],
    "EvaluatedFreshTrialCount" -> Length[trials],
    "RejectedMatrixTrials" -> trialSelection["RejectedTrials"],
    "FreshTrials" -> validation["AcceptedTrials"],
    "RejectedFreshTrials" -> validation["RejectedTrials"],
    "PivotSolvers" -> validation["PivotSolvers"],
    "AllComplementaryRowsChecked" -> True,
    "GoodCharacteristicErrorBound" -> Missing["DegreeBoundNotComputed"],
    "BadCharacteristicBound" -> Missing["NotComputed"],
    "WorkDirectory" -> directory,
    "PersistentWorkDirectory" -> cachePersistent,
    "SolutionFile" -> If[FileExistsQ[solutionFile], solutionFile, None],
    "SolutionBytes" -> If[FileExistsQ[solutionFile],
      FileByteCount[solutionFile], 0],
    "TraceSeconds" -> Lookup[runRecord, "TraceSeconds", 0.],
    "ReconstructionSeconds" -> Lookup[runRecord,
      "ReconstructionSeconds", 0.],
    "Seconds" -> AbsoluteTime[] - start|>;
  If[verbose, Print[
    "Observable transport modular row basis accepted: rank ", rank,
    ", rows ", rowCount, ", nonbasis ", Length[nonbasisRows],
    ", candidate ", candidateSource, ", fresh trials ",
    Length[certificate["FreshTrials"]]]];
  <|"Status" -> "ModularRowBasisAccepted", "Basis" -> basis,
    "Rank" -> rank, "Pivots" -> pivots,
    "Coordinates" -> coordinates,
    "ModularCertificate" -> certificate|>
];

(* Reconstruct a final rational matrix, rather than an intermediate gauge.
   Appending its rows below an identity basis turns every requested entry into
   one coordinate of a single traced multi-RHS system and reuses the same
   fresh full-row validation path. *)
observableTransportModularMatrixReconstruction[m_, variables_List,
    sampleRules_List, OptionsPattern[]] := Module[
  {dimensions, rows, columns, augmented, record, reconstructed},
  dimensions = Quiet[Check[Dimensions[m], {}]];
  If[Length[dimensions] =!= 2,
    Return[observableTransportFFFailure[
      "ModularMatrixReconstructionInputInvalid"]]];
  {rows, columns} = dimensions;
  If[rows === 0 || columns === 0,
    Return[<|"Status" -> "ModularMatrixReconstructionAccepted",
      "Matrix" -> m, "ModularCertificate" -> <|
        "Status" -> "StructuralZeroMatrix", "Accepted" -> True,
        "Probabilistic" -> False, "Exact" -> True|>|>]];
  augmented = Join[IdentityMatrix[columns], Normal[m]];
  record = observableTransportModularRowBasis[
    augmented, variables, sampleRules,
    "CoordinateBackend" -> OptionValue["CoordinateBackend"],
    "CoordinateCacheDirectory" ->
      OptionValue["CoordinateCacheDirectory"],
    "ReconstructionThreads" -> OptionValue["ReconstructionThreads"],
    "ValidationPrimeCount" -> OptionValue["ValidationPrimeCount"],
    "ValidationPointsPerPrime" ->
      OptionValue["ValidationPointsPerPrime"],
    "Verbose" -> OptionValue["Verbose"],
    "CoordinateKey" -> OptionValue["CoordinateKey"],
    "RatracerExecutable" -> OptionValue["RatracerExecutable"],
    "FLINTExecutable" -> OptionValue["FLINTExecutable"],
    "ValidationSeed" -> OptionValue["ValidationSeed"],
    "StructuralIdentityPrefix" -> True];
  If[! observableTransportModularRowBasisAcceptedQ[record] ||
      record["Rank"] =!= columns ||
      record["Pivots"] =!= Range[columns],
    Return[If[AssociationQ[record], record,
      observableTransportFFFailure[
        "ModularMatrixReconstructionFailed"]]]];
  reconstructed = Normal[record["Coordinates"]][[
    columns + Range[rows], All]];
  <|"Status" -> "ModularMatrixReconstructionAccepted",
    "Matrix" -> reconstructed,
    "ModularCertificate" -> record["ModularCertificate"]|>
];
