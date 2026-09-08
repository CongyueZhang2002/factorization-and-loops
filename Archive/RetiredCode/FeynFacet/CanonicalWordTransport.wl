(* ==== moved whole from Private/Transport/CanonicalWordTransport.wl on 2026-09-02 (user decision U1) ====
   Evidence: reachable only through the Libra path-ordered transport engines
   (TransportFamily / TransportPathArtifactRun), which the lazy-operator
   observable transport (Transport/ObservableTransport.wl) replaced as the
   production route; route_split.py: no helper of this module is used by
   ObservableTransport*, EpsForm or Geometry.
   This file is never loaded by FeynFacet.m. *)

(* Compiled epsilon-form word engine.

   This is the replacement core for the legacy symbolic-constant recursion
   in BlockwiseTransport.wl.  It deliberately accepts the same assembled
   path connection and returns the same canonical-frame F coefficients, but
   its internal representation is linear from the start:

     wordID -> SparseArray[output component, boundary-constant column].

   Boundary constants are assigned integer columns, letters are interned
   once, and words are cons cells {letterID, tailWordID}.  TransportConstant
   and TransportWord expressions are created only at the output boundary.
   The first implementation covers the common pure-dlog epsilon-form path;
   a non-dlog coupling returns a typed fallback instead of silently using an
   invalid append rule. *)

Begin["FeynFacet`Private`"];

ClearAll[
  masterTransportCanonicalWordSolve,
  masterTransportCWNonzeroSparseQ,
  masterTransportCWFactorSparseRows,
  masterTransportCWMaterialize,
  masterTransportCWModZeroQ,
  masterTransportCWCertificate,
  masterTransportCWExpandWord,
  masterTransportCWMaterializeIR,
  masterTransportCWIdentityValuation,
  masterTransportCanonicalChenOperator,
  masterTransportCanonicalChenWordCoefficient,
  masterTransportCanonicalChenCoefficient,
  masterTransportCanonicalSourceOperator,
  masterTransportCanonicalSourceCoefficient,
  masterTransportCanonicalSourceExpression,
  SourceBoundaryConstant
];

masterTransportCWNonzeroSparseQ[m_SparseArray] :=
  Length[m["NonzeroValues"]] > 0;
masterTransportCWNonzeroSparseQ[m_] :=
  AnyTrue[Flatten[m], ! TrueQ[# === 0] &];

(* Write a sparse row slice G exactly as L.C, assigning one formal row of C
   to each nonzero entry of G.  When the Chen residues are rational
   constants, C can traverse the complete word tree without dragging the
   symbolic gauge entries through every prefix; L is reinserted only for a
   surviving output word. *)
masterTransportCWFactorSparseRows[m_SparseArray] := Module[
  {dimensions, rules, count, leftRules, rightRules},
  dimensions = Dimensions[m];
  rules = Select[ArrayRules[m],
    MatchQ[First[#1], {_Integer, _Integer}] && Last[#1] =!= 0 &];
  count = Length[rules];
  leftRules = MapIndexed[Function[{rule, index},
    {First[rule][[1]], First[index]} -> Last[rule]], rules];
  rightRules = MapIndexed[Function[{rule, index},
    {First[index], First[rule][[2]]} -> 1], rules];
  {SparseArray[leftRules, {dimensions[[1]], count}],
    SparseArray[rightRules, {count, dimensions[[2]]}]}
];

masterTransportCWMaterialize[state_Association, dimension_Integer,
    boundaryConstants_List, expandWord_, tau_] := Module[
  {out, wordFactor, dense},
  out = ConstantArray[0, dimension];
  KeyValueMap[
    Function[{wordID, coefficientMatrix},
      wordFactor = If[wordID === 0, 1,
        TransportWord[expandWord[wordID], tau]];
      dense = Normal[coefficientMatrix];
      out += (dense . boundaryConstants) wordFactor],
    state];
  out];

masterTransportCWModZeroQ[expressions_List, symbols_List, prime_Integer,
    pointCount_Integer] := Module[
  {tries = 0, accepted = 0, rules, values, modular},
  While[accepted < pointCount && tries < 8 pointCount,
    tries++;
    rules = Thread[symbols -> RandomInteger[{101, prime - 101},
      Length[symbols]]];
    values = Quiet[Check[Together /@ (expressions /. rules), $Failed]];
    If[values === $Failed ||
        ! AllTrue[values, MatchQ[#, _Integer | _Rational] &], Continue[]];
    modular = familyCertMQModRational[#, prime] & /@ values;
    If[AnyTrue[modular, # === $Failed &], Continue[]];
    If[AnyTrue[modular, # =!= 0 &], Return[False]];
    accepted++];
  accepted === pointCount];

(* Replays dF=sum A F on the interned representation, but evaluates only
   the coefficient matrices at random points modulo one 61-bit prime.
   A derivative removes one word head, so the independent basis key is
   {letterID, tailWordID}; no GPL expression is ever materialized. *)
masterTransportCWCertificate[states_Association,
    couplings_Association, low_List, top_List, dimensions_List,
    wordHead_Association, wordTail_Association,
    pointCount_Integer, prime_Integer] := Module[
  {started = AbsoluteTime[], nb, records,
   lhs, rhs, residual, source, current, contribution, expressions,
   symbols, zero},
  nb = Length[dimensions];
  records = Flatten@Table[
    Module[{},
      lhs = <||>;
      KeyValueMap[
        Function[{wordID, coefficientMatrix},
          If[wordID =!= 0,
            current = Lookup[lhs,
              Key[{wordHead[wordID], wordTail[wordID]}], None];
            lhs[{wordHead[wordID], wordTail[wordID]}] =
              If[current === None, coefficientMatrix,
                current + coefficientMatrix]]],
        Lookup[states, Key[{i, n}], <||>]];
      rhs = <||>;
      Do[
        KeyValueMap[
          Function[{order, residueByLetter},
            If[low[[j]] <= n - order <= top[[j]],
              source = Lookup[states, Key[{j, n - order}], <||>];
              KeyValueMap[
                Function[{letterID, residueMatrix},
                  KeyValueMap[
                    Function[{tailID, coefficientMatrix},
                      contribution = residueMatrix . coefficientMatrix;
                      If[masterTransportCWNonzeroSparseQ[contribution],
                        current = Lookup[rhs,
                          Key[{letterID, tailID}], None];
                        rhs[{letterID, tailID}] = If[current === None,
                          contribution, current + contribution]]],
                    source]],
                residueByLetter]]],
          Lookup[couplings, Key[{i, j}], <||>]],
        {j, 1, i}];
      residual = lhs;
      KeyValueMap[
        Function[{key, matrix},
          current = Lookup[residual, Key[key], None];
          residual[key] = If[current === None, -matrix, current - matrix]],
        rhs];
      expressions = Flatten[Normal /@ Values[residual]];
      expressions = DeleteCases[expressions, 0];
      symbols = DeleteDuplicates @ Cases[expressions,
        s_Symbol /; Context[s] =!= "System`", {0, Infinity}];
      zero = expressions === {} ||
        masterTransportCWModZeroQ[expressions, symbols, prime, pointCount];
      <|"Block" -> i, "Order" -> n, "Zero" -> zero,
        "CoefficientCount" -> Length[expressions]|>],
    {i, nb}, {n, low[[i]], top[[i]]}];
  <|"AllZero" -> AllTrue[records, TrueQ[#1["Zero"]] &],
    "PerBlockOrder" -> records, "Prime" -> prime,
    "PointCount" -> pointCount, "Route" -> "InternedWordModular",
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

masterTransportCWExpandWord[ir_Association, 0] := {};
masterTransportCWExpandWord[ir_Association, id_Integer] :=
  Prepend[masterTransportCWExpandWord[ir, ir["WordTail"][id]],
    ir["Letters"][[ir["WordHead"][id]]]];

masterTransportCWMaterializeIR[ir_Association, tau_Symbol,
    kmax_Integer] := Module[
  {boundaryConstants, expand, flow, fVector},
  boundaryConstants = (TransportConstant @@ #) & /@
    ir["BoundaryColumns"];
  expand[0] = {};
  expand[id_Integer] := (expand[id] = masterTransportCWExpandWord[ir, id]);
  flow = ir["Flow"];
  fVector = Association@Table[
    k -> Module[{total = ConstantArray[0, ir["N"]]},
      Do[
        If[ir["Low"][[i]] <= k <= ir["Top"][[i]],
          total[[ir["Ranges"][[i]]]] = masterTransportCWMaterialize[
            Lookup[ir["States"], Key[{i, k}], <||>],
            ir["Dimensions"][[i]], boundaryConstants, expand, tau]],
        {i, Length[ir["Ranges"]]}];
      total],
    {k, flow, kmax}];
  <|"F" -> fVector, "FLow" -> flow, "KMax" -> kmax|>
];

(* For an identity original-to-canonical gauge, physical valuation is a
   sparse linear condition on boundary columns.  Row-reduce that matrix
   before any TransportConstant or GPL expression exists, apply the
   resulting projector to every word coefficient, and certify the forbidden
   rows at random modular points. *)
masterTransportCWIdentityValuation[ir_Association, n0_Integer,
    prime_Integer: 2305843009213641971,
    pointCount_Integer: 2] := Module[
  {started = AbsoluteTime[], boundaryDimension, constraintMatrices,
   equations, reduced, nonzeroRows, pivots, free, projectionRules,
   projection, transformedStates, assertionExpressions, symbols,
   assertion, status, rules, forbiddenOrders},
  boundaryDimension = Length[ir["BoundaryColumns"]];
  constraintMatrices = Flatten[Table[
    If[n < n0,
      Values[Lookup[ir["States"], Key[{i, n}], <||>]], {}],
    {i, Length[ir["Ranges"]]},
    {n, ir["Low"][[i]], Min[ir["Top"][[i]], n0 - 1]}], 2];
  equations = If[constraintMatrices === {}, {},
    Flatten[Normal /@ constraintMatrices, 1]];
  equations = Select[equations,
    AnyTrue[#, ! TrueQ[# === 0] &] &];
  If[equations === {},
    reduced = {}; pivots = {}; free = Range[boundaryDimension];
    projection = SparseArray[IdentityMatrix[boundaryDimension]],
    reduced = RowReduce[equations];
    nonzeroRows = Select[reduced,
      AnyTrue[#, ! masterTransportBWZeroQ[#] &] &];
    pivots = Table[First@FirstPosition[row,
        value_ /; ! masterTransportBWZeroQ[value],
        Missing["NoPivot"], {1}, Heads -> False],
      {row, nonzeroRows}];
    free = Complement[Range[boundaryDimension], pivots];
    projectionRules = Join[
      ({#, #} -> 1 & /@ free),
      Flatten[Table[
        If[masterTransportBWZeroQ[nonzeroRows[[row, column]]], Nothing,
          {pivots[[row]], column} ->
            -nonzeroRows[[row, column]]],
        {row, Length[pivots]}, {column, free}], 1]];
    projection = SparseArray[projectionRules,
      {boundaryDimension, boundaryDimension}]];
  transformedStates = Map[
    Function[state,
      Association@KeyValueMap[
        Function[{word, matrix},
          word -> With[{product = matrix . projection},
            If[Head[product] === SparseArray, product,
              SparseArray[product]]]], state]],
    ir["States"]];
  assertionExpressions = If[equations === {}, {},
    DeleteCases[Flatten[equations . projection], 0]];
  symbols = DeleteDuplicates@Cases[assertionExpressions,
    s_Symbol /; Context[s] =!= "System`", {0, Infinity}];
  assertion = assertionExpressions === {} ||
    masterTransportCWModZeroQ[assertionExpressions, symbols,
      prime, pointCount];
  status = If[TrueQ[assertion], "OK", "ValuationProjectionFailed"];
  rules = Table[
    (TransportConstant @@ ir["BoundaryColumns"][[pivot]]) ->
      Sum[projection[[pivot, column]]
        (TransportConstant @@ ir["BoundaryColumns"][[column]]),
        {column, free}],
    {pivot, pivots}];
  forbiddenOrders = If[Min[ir["Low"]] < n0,
    Range[Min[ir["Low"]], n0 - 1], {}];
  <|"Status" -> status, "AssertionOK" -> assertion,
    "IR" -> Join[ir, <|"States" -> transformedStates|>],
    "ConstraintCount" -> Length[equations],
    "Equations" -> Length[equations], "Rules" -> rules,
    "Orders" -> forbiddenOrders,
    "PivotColumns" -> pivots, "FreeColumns" -> free,
    "FixedConstantCount" -> Length[pivots],
    "Route" -> "CompiledIdentityBoundaryProjection",
    "Prime" -> prime, "PointCount" -> pointCount,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];

Options[masterTransportCanonicalWordSolve] = {
  "Verbose" -> False,
  "MaxWeight" -> 10,
  "ConstantDepth" -> "PerBlockNeed",
  "ExactDepth" -> None,
  "Certify" -> True,
  "CertificatePoints" -> 2,
  "CertificatePrime" -> 2305843009213641971,
  "PrecompiledCouplings" -> Automatic,
  "PrecompiledLetters" -> Automatic,
  "Materialize" -> True
};

masterTransportCanonicalWordSolve[assembly_Association, ahat_,
    budget_Association, kminPerBlock_List, kmaxF_Integer,
    tau_Symbol, eps_Symbol, opts : OptionsPattern[]] := Module[
  {start, verbose, maxWeight, nb, ranges, dimensions, rmin, need,
   exactDepth, schedule, low, top, qmax, perBlockWeight,
   rawCouplings, compiledCouplings, allLetters, letterTable, letterIndex,
   letterRecord, precompiledCouplings, precompiledLetters,
   decompositionRoute, badDiagonal,
   failure, decompositionStart, decompositionSeconds,
   boundaryTriples, boundaryIndex, boundaryDimension,
   wordIndex, wordHead, wordTail, wordWeight, nextWordID, intern,
   states, wordCounts, recursionStart, recursionSeconds,
   flow, fVector, ir, memory, materializationStart,
   materializationSeconds, certify, certificate},

  start = AbsoluteTime[];
  verbose = TrueQ[OptionValue["Verbose"]];
  maxWeight = OptionValue["MaxWeight"];
  certify = TrueQ[OptionValue["Certify"]];
  nb = Length[assembly["Blocks"]];
  ranges = assembly["Ranges"];
  dimensions = Length /@ ranges;
  rmin = budget["RMin"];
  need = budget["Need"];
  exactDepth = OptionValue["ExactDepth"];

  schedule = If[
    AssociationQ[exactDepth] &&
      Lookup[exactDepth, "Status", None] === "OK" &&
      ListQ[Lookup[exactDepth, "Lowest", None]] &&
      ListQ[Lookup[exactDepth, "NMax", None]],
    <|"Low" -> exactDepth["Lowest"], "Top" -> exactDepth["NMax"],
      "KMin" -> kminPerBlock, "Route" -> "masterTransportExactDepth",
      "W" -> Lookup[exactDepth, "W", None]|>,
    Join[masterTransportBWSchedule[rmin, kminPerBlock, need],
      <|"Route" -> "DepthBudgetNeed+ForwardLowestRecursion"|>]];
  low = schedule["Low"];
  top = schedule["Top"];
  qmax = Switch[OptionValue["ConstantDepth"],
    "PerBlockNeed", need,
    _, ConstantArray[kmaxF, nb]];
  perBlockWeight = top - low;
  If[Max[perBlockWeight] > maxWeight,
    Return[<|"Status" -> "DepthExceedsCap",
      "Requested" -> Max[perBlockWeight], "Cap" -> maxWeight,
      "Schedule" -> schedule|>]];

  (* Compile each required epsilon coefficient once, unless an accepted
     provider has already supplied the same sparse residue representation.
     The provider seam avoids recreating a symbolic A_tau merely so this
     routine can decompose it again. *)
  decompositionStart = AbsoluteTime[];
  precompiledCouplings = OptionValue["PrecompiledCouplings"];
  precompiledLetters = OptionValue["PrecompiledLetters"];
  If[AssociationQ[precompiledCouplings],
    If[! ListQ[precompiledLetters],
      Return[<|"Status" -> "PrecompiledLettersInvalid",
        "Schedule" -> schedule|>]];
    compiledCouplings = precompiledCouplings;
    letterTable = precompiledLetters;
    (* Distinctness and basepoint regularity belong to the accepted
       provider artifact.  Re-proving them here by pairwise symbolic
       radical simplification would reintroduce the bottleneck this seam
       is meant to bypass. *)
    letterRecord = <|"Distinct" -> True, "Collisions" -> {},
      "NoneAtBasePoint" -> True, "Letters" -> letterTable,
      "Count" -> Length[letterTable],
      "Route" -> "PrecompiledProviderContract"|>;
    badDiagonal = Flatten[Table[
      If[pair[[1]] === pair[[2]],
        {pair, #} & /@ Select[
          Keys[Lookup[compiledCouplings, Key[pair], <||>]], # <= 0 &],
        {}], {pair, Keys[compiledCouplings]}], 1];
    If[badDiagonal =!= {},
      Return[<|"Status" -> "DiagonalNotEpsForm",
        "Block" -> First[badDiagonal][[1, 1]],
        "Order" -> First[badDiagonal][[2]],
        "Schedule" -> schedule|>]];
    decompositionRoute = "PrecompiledResidueProvider",
    rawCouplings = <||>;
    allLetters = {};
    failure = None;
    Do[
      If[i >= j && failure === None,
        Module[{sub, nonzero, r0, r1, laurent, decomposed},
          sub = ahat[[ranges[[i]], ranges[[j]]]];
          nonzero = DeleteCases[Flatten[sub], 0];
          If[nonzero =!= {},
            r0 = rmin[[i, j]];
            If[r0 === Infinity,
              r0 = Min[masterTransportEpsOrder[#, eps] & /@ nonzero]];
            r1 = top[[i]] - low[[j]];
            If[r1 >= r0,
              laurent = masterTransportLaurentMat[sub, {r0, r1}, eps];
              If[laurent === $Failed,
                failure = <|"Status" -> "LaurentFailed",
                  "Block" -> {i, j}|>,
                Do[
                  If[! AllTrue[Flatten[laurent[[r - r0 + 1]]],
                      TrueQ[# === 0] &],
                    decomposed = masterTransportBWCouplingRep[
                      laurent[[r - r0 + 1]], tau];
                    If[decomposed["Kind"] =!= "Dlog",
                      failure = <|"Status" -> "CompiledWordFallbackRequired",
                        "Reason" -> "NonDlogCoupling", "Block" -> {i, j},
                        "EpsOrder" -> r,
                        "LegacyReason" -> decomposed["Reason"]|>,
                      rawCouplings[{i, j, r}] = decomposed["Rep"];
                      allLetters = Join[allLetters,
                        decomposed["Letters"]]]],
                  {r, r0, r1}]]]]]],
      {i, nb}, {j, i}];
    If[failure =!= None,
      Return[Join[failure, <|"Schedule" -> schedule,
        "Seconds" -> AbsoluteTime[] - start|>]]];
    badDiagonal = Select[Keys[rawCouplings],
      #[[1]] === #[[2]] && #[[3]] <= 0 &];
    If[badDiagonal =!= {},
      Return[<|"Status" -> "DiagonalNotEpsForm",
        "Block" -> First[badDiagonal][[1]],
        "Order" -> First[badDiagonal][[3]],
        "Schedule" -> schedule|>]];
    masterTransportSupportCacheDropCoefficients[];
    letterTable = DeleteDuplicates[masterTransportBWCanon /@ allLetters];
    letterRecord = masterTransportBWLetterCheck[letterTable];
    letterIndex = AssociationThread[letterTable, Range[Length[letterTable]]];
    compiledCouplings = <||>;
    KeyValueMap[
      Function[{edgeOrder, representation},
        Module[{pair = edgeOrder[[{1, 2}]], order = edgeOrder[[3]],
          byOrder, byLetter},
          byLetter = Association @ KeyValueMap[
            Function[{letter, residue},
              Lookup[letterIndex, Key[masterTransportBWCanon[letter]]] ->
                SparseArray[residue]],
            representation];
          byOrder = Lookup[compiledCouplings, Key[pair], <||>];
          byOrder[order] = byLetter;
          compiledCouplings[pair] = byOrder]],
      rawCouplings];
    decompositionRoute = "SymbolicPathDecomposition"];
  If[! (TrueQ[letterRecord["Distinct"]] &&
      letterRecord["Count"] === Length[letterTable] &&
      TrueQ[letterRecord["NoneAtBasePoint"]]),
    Return[<|"Status" -> "LetterHypothesisFailed",
      "Letters" -> letterRecord, "Schedule" -> schedule,
      "Seconds" -> AbsoluteTime[] - start|>]];
  decompositionSeconds = AbsoluteTime[] - decompositionStart;

  (* Boundary columns replace symbolic TransportConstant expressions. *)
  boundaryTriples = Flatten[Table[
    Table[{i, q, a}, {q, kminPerBlock[[i]], qmax[[i]]},
      {a, dimensions[[i]]}],
    {i, nb}], 2];
  boundaryIndex = AssociationThread[
    boundaryTriples, Range[Length[boundaryTriples]]];
  boundaryDimension = Length[boundaryTriples];

  (* One interned cons cell per reachable word.  Word 0 is empty. *)
  wordIndex = <||>;
  wordHead = <||>;
  wordTail = <||>;
  wordWeight = <|0 -> 0|>;
  nextWordID = 0;
  intern[letterID_Integer, tailID_Integer] := Module[{key, found, id},
    key = {letterID, tailID};
    found = Lookup[wordIndex, Key[key], Missing[]];
    If[! MissingQ[found], Return[found]];
    id = ++nextWordID;
    wordIndex[key] = id;
    wordHead[id] = letterID;
    wordTail[id] = tailID;
    wordWeight[id] = 1 + wordWeight[tailID];
    id];
  recursionStart = AbsoluteTime[];
  states = <||>;
  wordCounts = {};
  Do[
    Do[
      Module[{accumulate, selectorRules, source, contribution, wordID,
        newWordID, current, seconds},
        seconds = AbsoluteTime[];
        accumulate = <||>;
        If[kminPerBlock[[i]] <= n <= qmax[[i]],
          selectorRules = Table[
            {a, Lookup[boundaryIndex, Key[{i, n, a}]]} -> 1,
            {a, dimensions[[i]]}];
          accumulate[0] = SparseArray[selectorRules,
            {dimensions[[i]], boundaryDimension}]];
        Do[
          KeyValueMap[
            Function[{order, residueByLetter},
              If[low[[j]] <= n - order <= top[[j]],
                source = Lookup[states, Key[{j, n - order}], <||>];
                KeyValueMap[
                  Function[{letterID, residueMatrix},
                    KeyValueMap[
                      Function[{tailID, coefficientMatrix},
                        contribution = residueMatrix . coefficientMatrix;
                        If[masterTransportCWNonzeroSparseQ[contribution],
                          newWordID = intern[letterID, tailID];
                          current = Lookup[accumulate, Key[newWordID], None];
                          accumulate[newWordID] = If[current === None,
                            contribution, current + contribution]]],
                      source]],
                  residueByLetter]]],
            Lookup[compiledCouplings, Key[{i, j}], <||>]],
          {j, 1, i}];
        states[{i, n}] = accumulate;
        AppendTo[wordCounts, <|"Block" -> i, "Order" -> n,
          "Words" -> Length[accumulate],
          "MaxWeight" -> Max[Append[
            wordWeight /@ Keys[accumulate], 0]],
          "Seconds" -> AbsoluteTime[] - seconds|>];
        masterTransportLog[verbose, "  compiled-word block ", i, "/", nb,
          " eps^", n, ": ", Length[accumulate], " interned words, ",
          Round[Last[wordCounts]["Seconds"], 0.01], " s"]],
      {n, low[[i]], top[[i]]}],
    {i, nb}];
  recursionSeconds = AbsoluteTime[] - recursionStart;

  certificate = If[certify,
    masterTransportCWCertificate[states, compiledCouplings, low, top,
      dimensions, wordHead, wordTail,
      OptionValue["CertificatePoints"], OptionValue["CertificatePrime"]],
    <|"AllZero" -> Missing["NotPerformed"], "Performed" -> False,
      "Route" -> "NotPerformed"|>];

  flow = Min[low];

  memory = MaxMemoryUsed[];
  ir = <|
    "BoundaryColumns" -> boundaryTriples,
    "Letters" -> letterTable,
    "WordHead" -> wordHead,
    "WordTail" -> wordTail,
    "WordWeight" -> wordWeight,
    "States" -> states,
    "Couplings" -> compiledCouplings,
    "Ranges" -> ranges, "Dimensions" -> dimensions,
    "Low" -> low, "Top" -> top, "Flow" -> flow,
    "N" -> assembly["N"], "KMax" -> kmaxF|>;
  materializationStart = AbsoluteTime[];
  fVector = If[TrueQ[OptionValue["Materialize"]],
    masterTransportCWMaterializeIR[ir, tau, kmaxF]["F"], None];
  materializationSeconds = AbsoluteTime[] - materializationStart;

  <|"Status" -> Which[
      ! certify, "SolvedNotCertified",
      TrueQ[certificate["AllZero"]], "OK",
      True, "CompiledWordCertificateFailed"],
    "Route" -> "CompiledSparseWord",
    "CouplingRoute" -> decompositionRoute,
    "Solution" -> <|"F" -> fVector,
      "Constants" -> Association@Flatten[Table[
        {i, q} -> Table[TransportConstant[i, q, a],
          {a, dimensions[[i]]}],
        {i, nb}, {q, kminPerBlock[[i]], qmax[[i]]}], 1],
      "KMinPerBlock" -> kminPerBlock, "FLow" -> flow,
      "KMax" -> kmaxF|>,
    "Schedule" -> Join[schedule,
      <|"ConstantTop" -> qmax, "PerBlockWeight" -> perBlockWeight|>],
    "Letters" -> letterRecord,
    "GeneralIntegrator" -> <|"Sites" -> {}, "Used" -> False,
      "Statement" -> "all compiled couplings were pure dlog"|>,
    "WordCounts" -> wordCounts,
    "Certificate" -> Append[certificate, "Performed" -> certify],
    "MaxWordCount" -> Max[Append[wordCounts[[All, "Words"]], 0]],
    "MaxCoefficientLeaves" -> 0,
    "Weight" -> Max[Append[Values[wordWeight], 0]],
    "Timing" -> <|"Decomposition" -> decompositionSeconds,
      "Recursion" -> recursionSeconds,
      "Materialization" -> materializationSeconds,
      "Total" -> AbsoluteTime[] - start|>,
    "PeakMemory" -> memory,
    "IR" -> ir,
    "Maps" -> None,
    "Seconds" -> N[AbsoluteTime[] - start]|>
];

(* Lazy Chen operator for a genuinely epsilon-linear path connection.

     dF = eps Sum_a R_a dlog(tau-a) F

   is already the complete GPL solution: the coefficient of
   G[a1,...,ak;tau] is R_a1 ... R_ak.  Storing the sparse R_a matrices
   keeps that final formula polynomial in the input size; eagerly listing
   every word is exponential and is reserved for requested rows/orders. *)
masterTransportCanonicalChenOperator[assembly_Association,
    compiledCouplings_Association, letters_List, schedule_Association,
    kmin_List, constantTop_List, provider_: <||>] := Module[
  {ranges, dimensions, nb, n, low, top, residues, failure = None,
   localRules, globalRules, boundaryColumns, boundaryIndex,
   boundarySelectors, activeRowsByOrder, nonzeroCoordinates},
  ranges = assembly["Ranges"];
  dimensions = Length /@ ranges;
  nb = Length[ranges];
  n = assembly["N"];
  low = schedule["Low"];
  top = schedule["Top"];
  residues = ConstantArray[SparseArray[{}, {n, n}], Length[letters]];
  KeyValueMap[
    Function[{pair, byOrder},
      If[Sort[Keys[byOrder]] =!= {1},
        failure = <|"Status" -> "LazyChenFallbackRequired",
          "Reason" -> "ConnectionNotEpsilonLinear", "Block" -> pair,
          "Orders" -> Keys[byOrder]|>,
        KeyValueMap[
          Function[{letterID, localMatrix},
            localRules = Select[ArrayRules[localMatrix],
              MatchQ[First[#], {_Integer, _Integer}] &];
            globalRules = ({
                ranges[[pair[[1]], #[[1, 1]]]],
                ranges[[pair[[2]], #[[1, 2]]]]} -> Last[#]) & /@
              localRules;
            residues[[letterID]] += SparseArray[globalRules, {n, n}]],
          byOrder[1]]]],
    compiledCouplings];
  If[failure =!= None, Return[failure]];
  boundaryColumns = Flatten[Table[
    Table[{i, q, a}, {q, kmin[[i]], constantTop[[i]]},
      {a, dimensions[[i]]}], {i, nb}], 2];
  boundaryIndex = AssociationThread[
    boundaryColumns, Range[Length[boundaryColumns]]];
  boundarySelectors = Association@Table[
    q -> SparseArray[Flatten[Table[
        If[kmin[[i]] <= q <= constantTop[[i]],
          Table[{ranges[[i, a]],
              Lookup[boundaryIndex, Key[{i, q, a}]]} -> 1,
            {a, dimensions[[i]]}], {}],
        {i, nb}], 1], {n, Length[boundaryColumns]}],
    {q, Min[kmin], Max[constantTop]}];
  activeRowsByOrder = Association@Table[
    order -> Flatten@MapThread[
      Function[{rows, lo, hi}, If[lo <= order <= hi, rows, {}]],
      {ranges, low, top}],
    {order, Min[low], Max[top]}];
  nonzeroCoordinates = Total[Length[#["NonzeroValues"]] & /@ residues];
  <|"Status" -> "CanonicalGPLChenOperatorV1",
    "Route" -> "LazySparseResidueProducts",
    "Letters" -> letters, "Residues" -> residues,
    "BoundaryColumns" -> boundaryColumns,
    "BoundarySelectors" -> boundarySelectors,
    "ActiveRowsByOrder" -> activeRowsByOrder,
    "Ranges" -> ranges, "Dimensions" -> dimensions, "N" -> n,
    "Low" -> low, "Top" -> top, "KMin" -> kmin,
    "ConstantTop" -> constantTop,
    (* A boundary coefficient can start below the target block's own
       lowest requested order and feed it through off-diagonal residues.
       The safe global word bound is therefore measured from the lowest
       boundary order, not from each target block's Low entry. *)
    "MaximumWeight" -> Max[top] - Min[kmin],
    "NonzeroResidueCoordinates" -> nonzeroCoordinates,
    "GPLConvention" ->
      "G[{a1,...,ak};z]=Integral_0^z dt/(t-a1) G[{a2,...,ak};t]",
    "CoefficientFormula" ->
      "F_n=Sum_q Sum_{|w|=n-q} R_w B_q C G[w]",
    "Provider" -> provider|>
];

masterTransportCanonicalChenWordCoefficient[operator_Association,
    word_List, boundaryOrder_Integer, order_Integer,
    rows_: All] := Module[
  {n, boundaryDimension, selector, coefficient, active, mask},
  n = operator["N"];
  boundaryDimension = Length[operator["BoundaryColumns"]];
  If[Length[word] =!= order - boundaryOrder,
    Return[SparseArray[{}, {If[rows === All, n, Length[rows]],
      boundaryDimension}]]];
  selector = Lookup[operator["BoundarySelectors"], boundaryOrder, None];
  If[selector === None,
    Return[SparseArray[{}, {If[rows === All, n, Length[rows]],
      boundaryDimension}]]];
  coefficient = Fold[
    operator["Residues"][[#2]] . #1 &, selector, Reverse[word]];
  active = Lookup[operator["ActiveRowsByOrder"], order, {}];
  mask = SparseArray[({#, #} -> 1) & /@ active, {n, n}];
  coefficient = mask . coefficient;
  If[rows === All, coefficient, coefficient[[rows, All]]]
];

Options[masterTransportCanonicalChenCoefficient] = {
  "Rows" -> All, "MaxTerms" -> 10000
};

masterTransportCanonicalChenCoefficient[operator_Association,
    order_Integer, OptionsPattern[]] := Module[
  {rows, cap, letterCount, boundaryOrders, estimated, harvested, records},
  rows = OptionValue["Rows"];
  cap = OptionValue["MaxTerms"];
  letterCount = Length[operator["Letters"]];
  boundaryOrders = Select[Keys[operator["BoundarySelectors"]],
    0 <= order - # <= operator["MaximumWeight"] &];
  estimated = Total[letterCount^(order - #) & /@ boundaryOrders];
  If[estimated > cap,
    Return[<|"Status" -> "LazyExpansionRequired",
      "Order" -> order, "EstimatedTerms" -> estimated,
      "Cap" -> cap|>]];
  harvested = Reap[
    Do[
      Do[
        With[{matrix = masterTransportCanonicalChenWordCoefficient[
            operator, word, q, order, rows]},
          If[masterTransportCWNonzeroSparseQ[matrix],
            Sow[<|"BoundaryOrder" -> q, "Word" -> word,
              "Coefficient" -> matrix|>]]],
        {word, Tuples[Range[letterCount], order - q]}],
      {q, boundaryOrders}]][[2]];
  records = If[harvested === {}, {}, First[harvested]];
  <|"Status" -> "OK", "Order" -> order,
    "Rows" -> rows, "Terms" -> records,
    "TermCount" -> Length[records]|>
];

(* Compose the canonical Chen operator with an already expanded source
   gauge and boundary embedding.  Keeping these Laurent coefficients as
   provider data is intentional: a family may obtain them symbolically,
   with Maple, or by modular reconstruction without changing this engine.

     I_n = Sum_{r+q+|w|=n} T_r R_w H_q b G[w].

   Unlike the canonical-demand accessor above, this traversal must not use
   ActiveRowsByOrder: a negative-order source gauge can require canonical
   coefficients beyond the schedule that originally built the provider. *)
masterTransportCanonicalSourceOperator[chen_Association,
    gaugeByOrder_Association, boundaryByOrder_Association,
    boundaryColumns_List, provider_: <||>] := Module[
  {n, sourceDimension, boundaryDimension, gaugeOrders, boundaryOrders,
   gauges, boundaries, badGauge, badBoundary},
  If[Lookup[chen, "Status", None] =!= "CanonicalGPLChenOperatorV1",
    Return[<|"Status" -> "CanonicalSourceOperatorInputInvalid",
      "Reason" -> "ChenOperatorInvalid"|>]];
  n = chen["N"];
  gaugeOrders = Sort[Select[Keys[gaugeByOrder], IntegerQ]];
  boundaryOrders = Sort[Select[Keys[boundaryByOrder], IntegerQ]];
  If[gaugeOrders === {} || boundaryOrders === {},
    Return[<|"Status" -> "CanonicalSourceOperatorInputInvalid",
      "Reason" -> "LaurentProviderEmpty"|>]];
  gauges = AssociationMap[SparseArray[gaugeByOrder[#1]] &, gaugeOrders];
  boundaries = AssociationMap[
    SparseArray[boundaryByOrder[#1]] &, boundaryOrders];
  sourceDimension = First[Dimensions[First[Values[gauges]]]];
  boundaryDimension = Last[Dimensions[First[Values[boundaries]]]];
  badGauge = Select[gaugeOrders,
    Dimensions[gauges[#1]] =!= {sourceDimension, n} &];
  badBoundary = Select[boundaryOrders,
    Dimensions[boundaries[#1]] =!= {n, boundaryDimension} &];
  If[badGauge =!= {} || badBoundary =!= {} ||
      Length[boundaryColumns] =!= boundaryDimension,
    Return[<|"Status" -> "CanonicalSourceOperatorInputInvalid",
      "Reason" -> "LaurentProviderShapeMismatch",
      "BadGaugeOrders" -> badGauge,
      "BadBoundaryOrders" -> badBoundary|>]];
  <|"Status" -> "CanonicalGPLSourceOperatorV1",
    "Route" -> "LazySourceGaugeResidueProducts",
    "ChenOperator" -> chen,
    "GaugeByOrder" -> gauges,
    "BoundaryByOrder" -> boundaries,
    "GaugeOrders" -> gaugeOrders,
    "BoundaryOrders" -> boundaryOrders,
    "BoundaryColumns" -> boundaryColumns,
    "SourceDimension" -> sourceDimension,
    "CanonicalDimension" -> n,
    "BoundaryDimension" -> boundaryDimension,
    "CoefficientFormula" ->
      "I_n=Sum_{r+q+|w|=n} T_r R_w H_q b G[w]",
    "Provider" -> provider|>
];

Options[masterTransportCanonicalSourceCoefficient] = {
  "Rows" -> All,
  "MaxTerms" -> 100000,
  "MaxVisitedPrefixes" -> 1000000
};

masterTransportCanonicalSourceCoefficient[source_Association,
    order_Integer, OptionsPattern[]] := Module[
  {rows, maxTerms, maxVisited, chen, letters, residues, gauges,
   boundaries, gaugeOrders, boundaryOrders, sourceDimension,
   constantResiduesQ, traversalRoute,
   terms = <||>, visited = 0,
   capTag = Unique["CanonicalSourceCap"], outcome, addTerm,
   eligibleBoundaryOrders, maxWeight, boundaryOrder, start, leftFactor,
   factored, states, next, product, coefficient, newWord, existing,
   records},
  If[Lookup[source, "Status", None] =!= "CanonicalGPLSourceOperatorV1",
    Return[<|"Status" -> "CanonicalSourceCoefficientInputInvalid"|>]];
  sourceDimension = source["SourceDimension"];
  rows = Replace[OptionValue["Rows"], All :> Range[sourceDimension]];
  maxTerms = OptionValue["MaxTerms"];
  maxVisited = OptionValue["MaxVisitedPrefixes"];
  If[! MatchQ[rows, {__Integer}] ||
      ! AllTrue[rows, Between[#1, {1, sourceDimension}] &] ||
      ! IntegerQ[maxTerms] || maxTerms <= 0 ||
      ! IntegerQ[maxVisited] || maxVisited <= 0,
    Return[<|"Status" -> "CanonicalSourceCoefficientInputInvalid"|>]];
  chen = source["ChenOperator"];
  letters = chen["Letters"];
  residues = chen["Residues"];
  constantResiduesQ = AllTrue[
    Flatten[(#1["NonzeroValues"] &) /@ residues],
    MatchQ[#1, _Integer | _Rational] &];
  traversalRoute = If[constantResiduesQ,
    "GaugeFactoredConstantResidues", "DirectSymbolicResidues"];
  gauges = source["GaugeByOrder"];
  boundaries = source["BoundaryByOrder"];
  gaugeOrders = source["GaugeOrders"];
  boundaryOrders = source["BoundaryOrders"];
  addTerm[currentWord_, matrix_] := Module[{old},
    If[! masterTransportCWNonzeroSparseQ[matrix], Return[Null]];
    old = Lookup[terms, Key[currentWord], None];
    terms[currentWord] = If[old === None, matrix,
      SparseArray[old + matrix]];
    If[Length[terms] > maxTerms, Throw["TermCap", capTag]]];
  outcome = Catch[
    Do[
      eligibleBoundaryOrders = Select[boundaryOrders,
        order - gaugeOrder - #1 >= 0 &];
      If[eligibleBoundaryOrders === {}, Continue[]];
      maxWeight = Max[order - gaugeOrder - #1 & /@
        eligibleBoundaryOrders];
      start = gauges[gaugeOrder][[rows, All]];
      If[! masterTransportCWNonzeroSparseQ[start], Continue[]];
      If[constantResiduesQ,
        factored = masterTransportCWFactorSparseRows[start];
        leftFactor = factored[[1]];
        start = factored[[2]],
        leftFactor = None];
      states = <|{} -> start|>;
      Do[
        boundaryOrder = order - gaugeOrder - weight;
        If[KeyExistsQ[boundaries, boundaryOrder],
          KeyValueMap[
            Function[{prefix, matrix},
              coefficient = If[constantResiduesQ,
                leftFactor . (matrix . boundaries[boundaryOrder]),
                matrix . boundaries[boundaryOrder]];
              addTerm[prefix, SparseArray[coefficient]]], states]];
        If[weight === maxWeight || states === <||>, Break[]];
        next = <||>;
        KeyValueMap[
          Function[{prefix, matrix},
            Do[
              product = SparseArray[matrix . residues[[letterID]]];
              If[masterTransportCWNonzeroSparseQ[product],
                newWord = Append[prefix, letterID];
                existing = Lookup[next, Key[newWord], None];
                next[newWord] = If[existing === None, product,
                  SparseArray[existing + product]];
                visited++;
                If[visited > maxVisited,
                  Throw["VisitedPrefixCap", capTag]]],
              {letterID, Length[letters]}]],
          states];
        states = next,
        {weight, 0, maxWeight}],
      {gaugeOrder, gaugeOrders}];
    "OK", capTag];
  If[outcome =!= "OK",
    Return[<|"Status" -> "LazyExpansionRequired",
      "Reason" -> outcome, "Order" -> order,
      "VisitedPrefixes" -> visited,
      "TermCountBeforeRefusal" -> Length[terms],
      "TraversalRoute" -> traversalRoute,
      "MaxTerms" -> maxTerms,
      "MaxVisitedPrefixes" -> maxVisited|>]];
  records = KeyValueMap[
    <|"Word" -> #1, "Coefficient" -> #2|> &, terms];
  records = SortBy[records, {Length[#1["Word"]], #1["Word"]} &];
  <|"Status" -> "OK", "Order" -> order, "Rows" -> rows,
    "Terms" -> records, "TermCount" -> Length[records],
    "VisitedPrefixes" -> visited,
    "TraversalRoute" -> traversalRoute,
    "BoundaryColumns" -> source["BoundaryColumns"]|>
];

Options[masterTransportCanonicalSourceExpression] = {
  "BoundarySymbols" -> Automatic
};

masterTransportCanonicalSourceExpression[source_Association,
    coefficient_Association, tau_Symbol, OptionsPattern[]] := Module[
  {symbols, columns, letters, rows, vectors},
  If[Lookup[source, "Status", None] =!= "CanonicalGPLSourceOperatorV1" ||
      Lookup[coefficient, "Status", None] =!= "OK",
    Return[<|"Status" -> "CanonicalSourceExpressionInputInvalid"|>]];
  columns = source["BoundaryColumns"];
  symbols = Replace[OptionValue["BoundarySymbols"], Automatic :>
    Map[If[ListQ[#1], Apply[SourceBoundaryConstant, #1],
      SourceBoundaryConstant[#1]] &, columns]];
  If[Length[symbols] =!= Length[columns],
    Return[<|"Status" -> "CanonicalSourceExpressionInputInvalid",
      "Reason" -> "BoundarySymbolCountMismatch"|>]];
  letters = source["ChenOperator", "Letters"];
  rows = coefficient["Rows"];
  vectors = If[coefficient["Terms"] === {},
    ConstantArray[0, Length[rows]],
    Total[Map[
      Function[term,
        (Normal[term["Coefficient"]] . symbols) *
          If[term["Word"] === {}, 1,
            TransportWord[letters[[term["Word"]]], tau]]],
      coefficient["Terms"]]]];
  <|"Status" -> "OK", "Order" -> coefficient["Order"],
    "Rows" -> rows, "Expression" -> vectors,
    "BoundarySymbols" -> symbols|>
];

End[];
