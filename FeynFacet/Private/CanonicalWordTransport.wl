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
  masterTransportCWMaterialize,
  masterTransportCWModZeroQ,
  masterTransportCWCertificate,
  masterTransportCWExpandWord,
  masterTransportCWMaterializeIR,
  masterTransportCWIdentityValuation
];

masterTransportCWNonzeroSparseQ[m_SparseArray] :=
  Length[m["NonzeroValues"]] > 0;
masterTransportCWNonzeroSparseQ[m_] :=
  AnyTrue[Flatten[m], ! TrueQ[# === 0] &];

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
  "Materialize" -> True
};

masterTransportCanonicalWordSolve[assembly_Association, ahat_,
    budget_Association, kminPerBlock_List, kmaxF_Integer,
    tau_Symbol, eps_Symbol, opts : OptionsPattern[]] := Module[
  {start, verbose, maxWeight, nb, ranges, dimensions, rmin, need,
   exactDepth, schedule, low, top, qmax, perBlockWeight,
   rawCouplings, compiledCouplings, allLetters, letterTable, letterIndex,
   letterRecord,
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

  (* Compile each required epsilon coefficient once.  The old engine
     carries full symbolic constants during this pass; here the coupling
     is independent of boundary data and becomes a sparse residue matrix. *)
  decompositionStart = AbsoluteTime[];
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
  With[{badDiagonal = Select[Keys[rawCouplings],
      #[[1]] === #[[2]] && #[[3]] <= 0 &]},
    If[badDiagonal =!= {},
      Return[<|"Status" -> "DiagonalNotEpsForm",
        "Block" -> First[badDiagonal][[1]],
        "Order" -> First[badDiagonal][[3]],
        "Schedule" -> schedule|>]]];
  masterTransportSupportCacheDropCoefficients[];

  letterTable = DeleteDuplicates[masterTransportBWCanon /@ allLetters];
  letterRecord = masterTransportBWLetterCheck[letterTable];
  If[! (TrueQ[letterRecord["Distinct"]] &&
      TrueQ[letterRecord["NoneAtBasePoint"]]),
    Return[<|"Status" -> "LetterHypothesisFailed",
      "Letters" -> letterRecord, "Schedule" -> schedule,
      "Seconds" -> AbsoluteTime[] - start|>]];
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

End[];
