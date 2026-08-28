(* Deferred (sparse tagged term DAG) construction of the off-diagonal
   block equation's source.

   MEASURED MOTIVATION (2026-08-24 production, two watchdog
   confirmations).  The driver's blockEquation built

     bbar_{ij} = A_{kj} - Sum_{j<m<k} D_{km} A_{mj}

   as one dense Dot per feeder followed by Map[Together, ., {2}] over the
   whole block.  On CF259 sector 21 the single block (21,18) spent 536 s
   there (run log: strip {21,19} announced at +71 s, strip {21,18} at
   +607 s); 28x28 / 37x37 truncations were measured at 2+ h between
   blocks.  The cost is NOT finite-field linear algebra; it is the
   repeated symbolic materialization of a sum of rational functions,
   whose Together does one polynomial gcd per pair of terms.

   THE CONTRACT this file implements is Codex's Q5 review
   (Exchange/Fable/2026-08-24/01_cf300_12_9_state_and_reply/
   codex_response_to_fable_cf300_129_2026-08-24.md), points 1-4, 6 and 8:

     1. a sparse tagged term DAG is kept for the accumulated object; the
        sum is NEVER formed as Together[Total[terms]] during
        construction.  A term stores REFERENCES to its source entries
        (the gauge entry and the connection entry), so preparation
        allocates no new large expressions;
     2. the ABI is pinned -- variable and parameter symbol keys carrying
        their context, regulator, block indices, row/column indices,
        feeder list and a source fingerprint.  Evaluation and
        materialization recompute the fingerprint and fail closed on any
        mismatch;
     3. bad primes, denominator-zero points and unassigned symbols are
        TYPED SAMPLING REJECTIONS, never zero equations;
     4. the structural block precondition of the truncated row formula
        (the strict upper block triangle of A structurally zero on the
        blocks the formula touches) is enforced before any term is
        recorded, and an entry no feeder touches is preserved by SameQ --
        it passes through as the connection entry itself, not as
        Together of it;
     6/8. a modular census decides which entries are provably nonzero (a
        single nonzero image over F_p is an EXACT proof of
        non-vanishing), so the exact zero test is paid only for entries
        no image separated from zero, and only touched entries are
        materialized.

   WHY THE EXACT MATERIALIZATION IS FASTER, AND STILL EXACT.
   Every operand (a gauge entry, a connection entry) is Together'd ONCE
   and interned -- an Association keyed by the expression is a hash map
   with SameQ collision semantics, which is exactly the interning pool
   Codex asks for in Q1.2 -- and its denominator is factored once.  A
   term's denominator is then the multiset union of two already-factored
   denominators, and the common denominator of the whole entry is the
   per-factor maximum: NO polynomial gcd is computed to find it, where
   Together computes one per pair of terms.  The numerator is one Expand
   of the cofactor-weighted sum.  A single cancellation pass divides out
   those factors of the common denominator that divide the numerator;
   each such test is a division against ONE irreducible factor, not a gcd
   against the whole accumulated denominator.  An entry that vanishes
   identically is proved zero by that Expand alone -- no gcd at all --
   which is the cheapest exact zero test available here and replaces the
   driver's Together-based zero-forcing probe.

   SCOPE, MEASURED AND STATED.  The exact materialization is frame
   independent: it is ordinary exact algebra and is used on rational and
   algebraic (multiquadratic) frames alike.  The MODULAR CENSUS is not:
   its evaluator refuses a half-power with the typed rejection
   AlgebraicOperandUnsupported, so on an algebraic frame every point is
   rejected, nothing is proved, and the caller falls back to its own
   exact zero test -- fail closed, no regression.  Accepting points on an
   algebraic frame needs the declared-root ABI of
   FamilyRowGaugeFiniteField.wl (canonical root order, all 2^r sign
   conjugates, the Hadamard grade round trip: Codex Q5 point 5), which
   this layer does not yet carry.  Measured on CF259 (21,18): 8 of 8
   entries algebraic, 8 of 8 census points rejected.

   THE ONE MEASURED DIFFERENCE FROM THE SYMBOLIC ROUTE, and its blast
   radius.  The two routes agree EXACTLY as rational functions (proved
   entry by entry on fixtures and on the real CF259 (21,18) block, and
   against the strip input production itself wrote).  They do not agree
   in FORM on an algebraic frame: Together is not a canonical form on
   algebraic expressions, and the assembled entry keeps one extra power
   of an algebraic denominator factor -- measured on CF259 (21,18), the
   downstream gauge denominator carries
   (-1 - x + y + Sqrt[...])^5 where the symbolic route gives ^4.  The
   consequence is CONSERVATIVE: a larger gauge denominator is a larger
   ansatz, so the solver searches a superset and can never miss a gauge;
   it costs solve time.  It reaches the solver only on the CHARTLESS
   multiquadratic path, because SolveEpsFormStripInFrame pulls the strip
   back into a rational chart first and transportChartPullBackStrip ends
   in Map[Together, ., {2}] on now-rational entries -- and Together IS
   canonical there, so two exactly equal forcings pull back to the same
   strip.  On a rational frame the cancellation is complete and the
   denominators agree outright.  FACET_CONSTRUCTION_ROUTE=Symbolic is the
   revert if a chartless multiquadratic block proves sensitive to it.

   ROUTE.  blockEquationDeferredRouteQ[] reads FACET_CONSTRUCTION_ROUTE.
   The deferred route is the DEFAULT; FACET_CONSTRUCTION_ROUTE=Symbolic
   reverts every caller to the previous symbolic construction, so the
   risk of this change is contained to one environment variable.

   PHASE TELEMETRY AND THE PARALLEL SECOND PHASE (2026-08-25, Codex's
   06:30 items A and B, confirmed by his 08:30 measurement of the CF303
   {17,12} construction: 1868.4 s of which 1604.1 s numerator expansion,
   248.5 s cancellation, 6.5 s the shared interning).  The materializer
   now emits a start record and a RATE-LIMITED progress record, so a
   1868 s construction is no longer one silent interval to a watchdog;
   and its second phase -- per-target numerator expansion, per-factor
   cancellation and the final one-quotient algebraic Together -- is
   farmed to the currently free pool helpers as bounded batches of
   IMMUTABLE jobs over an interned operand table, while the mutable
   interning/factorization phase stays serial on the main kernel in
   deterministic order.  FACET_MATERIALIZE_PARALLEL=Off reverts the
   second phase to serial; FACET_MATERIALIZE_PROGRESS_SECONDS moves the
   telemetry interval.  See the phase note above
   blockEquationDeferredMaterialize. *)

Begin["FeynFacet`Private`"];

ClearAll[
  blockEquationDeferredRoute,
  blockEquationDeferredRouteQ,
  blockEquationDeferredSymbolKey,
  blockEquationDeferredSupport,
  blockEquationDeferredTermExpression,
  blockEquationDeferredUntouchedQ,
  blockEquationDeferredRecordBase,
  blockEquationDeferredSourceFingerprint,
  blockEquationDeferredFingerprint,
  blockEquationDeferredPrepare,
  blockEquationDeferredModEvaluate,
  blockEquationDeferredEvaluate,
  blockEquationDeferredNonzeroCensus,
  blockEquationDeferredCanonicalOperand,
  blockEquationDeferredMaterialize,
  blockEquationDeferredSourceExpression,
  blockEquationDeferredForcing,
  blockEquationDeferredProgressRecord,
  blockEquationDeferredProgressIntervalDefault,
  blockEquationDeferredParallelRouteQ,
  blockEquationDeferredAssembleJob,
  blockEquationDeferredBatchPlan,
  blockEquationDeferredMaterializeTask,
  blockEquationDeferredRootFrame,
  blockEquationDeferredGradeReduceRules,
  blockEquationDeferredGradeReduce,
  blockEquationDeferredGradeChannels,
  blockEquationDeferredAlgebraicZeroQ,
  blockEquationDeferredFrameCanonicalize,
  blockEquationDeferredFactorRootMask,
  blockEquationDeferredFactorOrbit,
  blockEquationDeferredBundleTargetOrder,
  blockEquationDeferredBundleFingerprint,
  blockEquationDeferredBundleValidate,
  blockEquationDeferredBundleEvaluate,
  blockEquationDeferredCompileBundle,
  blockEquationDeferredCompileBundleWithCache,
  $blockEquationDeferredABIVersion,
  $blockEquationDeferredBundleSchema
];

$blockEquationDeferredABIVersion = "BlockEquationDeferredV1";

(* ---- route ---------------------------------------------------------- *)

blockEquationDeferredRoute[] := Module[{value = Environment[
    "FACET_CONSTRUCTION_ROUTE"]},
  If[StringQ[value] && StringMatchQ[value, "Symbolic", IgnoreCase -> True],
    "Symbolic", "Deferred"]];

blockEquationDeferredRouteQ[] := blockEquationDeferredRoute[] === "Deferred";

(* ---- ABI ------------------------------------------------------------ *)

(* a symbol key that carries its context explicitly: unlike printed text
   it does not change with the reader's $ContextPath (the pool defect
   this repository has already paid for once) *)
blockEquationDeferredSymbolKey[symbol_Symbol] :=
  {Context[symbol], SymbolName[symbol]};
blockEquationDeferredSymbolKey[other_] := {"", ToString[other, InputForm]};

blockEquationDeferredSupport[entries_List] :=
  Flatten[Position[entries, Except[0], {1}, Heads -> False]];

(* the term's expression is built ON DEMAND (for the modular evaluator
   and for the symbolic fallback); the record itself stores references *)
blockEquationDeferredTermExpression[term_Association] :=
  Lookup[term, "Coefficient", 1] * (Times @@ Lookup[term, "Operands", {}]);

(* an entry no feeder touched: Base terms only *)
blockEquationDeferredUntouchedQ[record_Association] :=
  FreeQ[Lookup[#, "Kind", None] & /@ Lookup[record, "Terms", {}], "Feed"];

(* the original connection entry of a record, read back from its Base
   term.  Total of a single summand is that summand, so this is SameQ to
   the entry the connection holds -- Codex 4's untouched-entry
   preservation reads the record through here and never rebuilds it. *)
blockEquationDeferredRecordBase[record_Association] :=
  Total[Cases[Lookup[record, "Terms", {}],
    term_ /; Lookup[term, "Kind", None] === "Base" :>
      First[Lookup[term, "Operands", {0}]]]];

blockEquationDeferredSourceFingerprint[slices_] :=
  Hash[{$blockEquationDeferredABIVersion, slices}, "SHA256", "HexString"];

blockEquationDeferredFingerprint[preparation_Association] := Hash[
  {$blockEquationDeferredABIVersion,
   blockEquationDeferredSymbolKey /@ Lookup[preparation, "Variables", {}],
   blockEquationDeferredSymbolKey[Lookup[preparation, "Regulator", None]],
   blockEquationDeferredSymbolKey /@ Lookup[preparation, "Parameters", {}],
   Lookup[preparation, "Sector", None],
   Lookup[preparation, "LowerSector", None],
   Lookup[preparation, "RowIndices", {}],
   Lookup[preparation, "ColumnIndices", {}],
   Lookup[preparation, "Feeders", {}],
   Lookup[preparation, "Dimensions", {}],
   Lookup[preparation, "SourceFingerprint", None],
   ({#["Target"], ({Lookup[#, "Kind", None], Lookup[#, "Feeder", None],
        Lookup[#, "Index", None], Lookup[#, "Coefficient", 1],
        Lookup[#, "Operands", {}]} & /@ Lookup[#, "Terms", {}])} & /@
     Lookup[preparation, "Records", {}])},
  "SHA256", "HexString"];

(* ---- preparation ---------------------------------------------------- *)

(* connection: {Ax, Ay}; ranges: the block row ranges of the truncation;
   k, j: the block indices of the off-diagonal block (k, j); solved: the
   already installed blocks of row k as an association m -> D_{km};
   variables: the two chart variables; regulator: the epsilon symbol.
   The arguments are exactly what the driver's blockEquation reads, so
   the two routes are interchangeable at the call site. *)
blockEquationDeferredPrepare[connection_, ranges_, k_Integer, j_Integer,
    solved_Association, variables_, regulator_] := Module[
  {started = AbsoluteTime[], n, rk, rj, feeders, involved, pairs,
   upper, records = {}, untouchedCount = 0, terms, base, feedTerms,
   gaugeBlock, feedBlock, gaugeRowSupport, feedColumnSupport,
   support, dimensions, parameters, sliceFingerprint, preparation,
   productCount = 0, termCount = 0, mu, i, jj, m, l},

  If[! MatchQ[connection, {_List, _List}] ||
      ! MatrixQ[connection[[1]]] || ! MatrixQ[connection[[2]]] ||
      Dimensions[connection[[1]]] =!= Dimensions[connection[[2]]] ||
      Length[connection[[1]]] =!= Length[connection[[1, 1]]],
    Return[<|"Status" -> "InvalidDimensions",
      "Reason" -> "connection must be two square matrices of one common dimension"|>]];
  n = Length[connection[[1]]];
  If[! ListQ[ranges] || ranges === {} ||
      ! AllTrue[ranges, VectorQ[#, IntegerQ] && # =!= {} &] ||
      ! IntegerQ[k] || ! IntegerQ[j] ||
      ! (1 <= j < k <= Length[ranges]),
    Return[<|"Status" -> "InvalidBlockIndices",
      "Sector" -> k, "LowerSector" -> j|>]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      SameQ[variables[[1]], variables[[2]]] ||
      ! SymbolQ[regulator] || MemberQ[variables, regulator],
    Return[<|"Status" -> "InvalidVariables"|>]];
  rk = ranges[[k]]; rj = ranges[[j]];
  If[Max[rk] > n || Max[rj] > n,
    Return[<|"Status" -> "InvalidBlockIndices",
      "Reason" -> "block rows exceed the connection dimension"|>]];
  feeders = Sort[Select[Keys[solved], j < # < k &]];
  If[! AllTrue[feeders, MatrixQ[solved[#]] &&
      Dimensions[solved[#]] === {Length[rk], Length[ranges[[#]]]} &],
    Return[<|"Status" -> "InvalidGaugeDimensions",
      "Feeders" -> feeders|>]];

  (* Codex 4: the truncated row formula is valid only on a
     block-lower-triangular connection.  Check the strict upper block
     triangle of every block pair the formula touches, structurally. *)
  involved = Union[{j, k}, feeders];
  pairs = Select[Tuples[involved, 2], First[#] < Last[#] &];
  upper = FirstCase[pairs,
    {a_, b_} /; ! AllTrue[
        Flatten[connection[[All, ranges[[a]], ranges[[b]] ]]],
        SameQ[#, 0] &] :> {a, b}, None];
  If[upper =!= None,
    Return[<|"Status" -> "InvalidBlockStructure",
      "BlockPair" -> upper,
      "Reason" -> "A[[block a, block b]] with a < b is not structurally zero; the truncated row formula does not apply"|>]];

  Do[
    base = connection[[mu, rk[[i]], rj[[jj]] ]];
    feedTerms = {};
    Do[
      gaugeBlock = solved[m];
      feedBlock = connection[[mu, ranges[[m]], rj]];
      gaugeRowSupport = blockEquationDeferredSupport[gaugeBlock[[i]]];
      feedColumnSupport = blockEquationDeferredSupport[
        feedBlock[[All, jj]]];
      support = Intersection[gaugeRowSupport, feedColumnSupport];
      productCount += Length[support];
      feedTerms = Join[feedTerms,
        Table[<|"Kind" -> "Feed", "Feeder" -> m, "Index" -> l,
          "Coefficient" -> -1,
          "Operands" -> {gaugeBlock[[i, l]], feedBlock[[l, jj]]}|>,
          {l, support}]],
      {m, feeders}];
    (* THE BASE IS ONE TERM, MEASURED, NOT ASSUMED.  On CF259 (21,18)
       the eight base entries carry 848337 leaves and their eight
       Together calls are 130 of the 173 s the deferred route spends, so
       splitting a Plus-headed base into one term per summand looks like
       the obvious next win.  It is not: measured 2026-08-25 on that same
       block, the split raised the term count from 46 to 110 and the
       materialization from 166 s to more than 630 s before it was
       stopped.  The reason is structural -- the common denominator is
       the per-factor MAXIMUM over the terms, so every extra term can
       only enlarge it, and each of the other terms then carries a bigger
       cofactor into the one Expand.  Together's progressive cancellation
       is worth more than the gcds it costs once a single term already
       carries most of the denominator.  Keep the base whole. *)
    terms = If[SameQ[base, 0] && feedTerms =!= {}, feedTerms,
      Prepend[feedTerms, <|"Kind" -> "Base", "Coefficient" -> 1,
        "Operands" -> {base}|>]];
    termCount += Length[terms];
    If[feedTerms === {}, untouchedCount++];
    AppendTo[records,
      <|"Target" -> {mu, i, jj}, "Terms" -> terms|>],
    {mu, 2}, {i, Length[rk]}, {jj, Length[rj]}];

  dimensions = {2, Length[rk], Length[rj]};
  parameters = DeleteDuplicates[Cases[
    Lookup[#, "Operands", {}] & /@ Flatten[Lookup[records, "Terms", {}]],
    symbol_Symbol /; Context[symbol] =!= "System`" &&
      ! MemberQ[variables, symbol] && symbol =!= regulator :> symbol,
    {0, Infinity}, Heads -> True]];
  parameters = SortBy[parameters, blockEquationDeferredSymbolKey];
  sliceFingerprint = blockEquationDeferredSourceFingerprint[{
    connection[[All, rk, rj]],
    Table[{m, ranges[[m]], solved[m], connection[[All, ranges[[m]], rj]]},
      {m, feeders}]}];

  preparation = <|"Status" -> "Prepared",
    "ABIVersion" -> $blockEquationDeferredABIVersion,
    "Variables" -> variables, "Regulator" -> regulator,
    "Parameters" -> parameters,
    "Sector" -> k, "LowerSector" -> j,
    "RowIndices" -> rk, "ColumnIndices" -> rj, "Feeders" -> feeders,
    "Dimensions" -> dimensions,
    "Records" -> records,
    "SourceFingerprint" -> sliceFingerprint,
    "Statistics" -> <|
      "CandidateEntries" -> 2 Length[rk] Length[rj],
      "Touched" -> Length[records] - untouchedCount,
      "Untouched" -> untouchedCount,
      "Products" -> productCount, "TermCount" -> termCount,
      "PrepareSeconds" -> N[AbsoluteTime[] - started]|>|>;
  Append[preparation,
    "Fingerprint" -> blockEquationDeferredFingerprint[preparation]]
];

blockEquationDeferredPrepare[___] := <|"Status" -> "InvalidInput"|>;

(* the deferred sum of one target, as a symbolic expression -- the
   SYMBOLIC FALLBACK and the reference the tests compare against.  It is
   never called on the production path. *)
blockEquationDeferredSourceExpression[preparation_Association,
    target_List] := Module[{hit},
  hit = FirstCase[Lookup[preparation, "Records", {}],
    r_ /; r["Target"] === target :> r, None];
  If[hit === None, Missing["NoRecord", target],
    Total[blockEquationDeferredTermExpression /@ hit["Terms"]]]];

(* ---- modular evaluation --------------------------------------------- *)

(* Recursive arithmetic in F_p over a tagged term.  This is the single
   production implementation; the row-gauge oracle
   (FamilyRowGaugeFiniteField.wl, familyRowGaugeFFModEvaluate) delegates
   to it with its own root-placeholder head, exactly as that file already
   delegates every multiquadratic algebra operation to the neutral ABI.
   rootHead = None means "no algebraic placeholders in this expression".
   Every failure is TYPED (Codex 3): a bad prime, a denominator-zero
   point and an unassigned symbol are sampling rejections and must never
   be read as a zero value. *)
blockEquationDeferredModEvaluate[expression_, scalarValues_Association,
    rootValues_List, prime_Integer, rootHead_: None] := Module[
  {evaluate, tag = Unique["blockEquationDeferredEvaluateTag"], result},
  result = Catch[
    evaluate[node_] := Which[
      IntegerQ[node], Mod[node, prime],
      Head[node] === Rational,
        Module[{denominator = Mod[Denominator[node], prime]},
          If[denominator === 0,
            Throw[<|"Status" -> "BadPrime",
              "Denominator" -> Denominator[node]|>, tag]];
          Mod[Numerator[node] PowerMod[denominator, -1, prime], prime]],
      rootHead =!= None && MatchQ[node, rootHead[_Integer]],
        With[{index = First[node]},
          If[1 <= index <= Length[rootValues], rootValues[[index]],
            Throw[<|"Status" -> "InvalidRootPlaceholder",
              "RootIndex" -> index|>, tag]]],
      SymbolQ[node],
        If[KeyExistsQ[scalarValues, node],
          evaluate[scalarValues[node]],
          Throw[<|"Status" -> "UnassignedSymbol",
            "Symbol" -> HoldForm[node]|>, tag]],
      Head[node] === Plus,
        Fold[Mod[#1 + evaluate[#2], prime] &, 0, List @@ node],
      Head[node] === Times,
        Fold[Mod[#1 evaluate[#2], prime] &, 1, List @@ node],
      MatchQ[node, Power[_, _Integer]],
        Module[{baseValue = evaluate[First[node]],
          exponent = Last[node], value},
          If[baseValue === 0 && exponent < 0,
            Throw[<|"Status" -> "SingularPoint"|>, tag]];
          value = Quiet[Check[
            PowerMod[baseValue, exponent, prime], $Failed]];
          If[value === $Failed,
            Throw[<|"Status" -> "SingularPoint"|>, tag], value]],
      (* An ALGEBRAIC operand (a half-power the caller did not replace by
         a declared root placeholder) is its own typed rejection, not a
         generic unsupported node.  MEASURED on CF259 (21,18): all eight
         entries of that block carry square roots, so the census rejects
         every point of an algebraic frame and the caller falls back to
         its exact zero test -- the fail-closed behaviour.  Accepting
         such a point needs the declared-root ABI of
         FamilyRowGaugeFiniteField.wl (canonical root order, all 2^r sign
         conjugates, the Hadamard grade round trip: Codex Q5 point 5),
         which this construction layer does not yet carry. *)
      MatchQ[node, Power[_, _Rational]],
        Throw[<|"Status" -> "AlgebraicOperandUnsupported",
          "RadicalBase" -> HoldForm[First[node]],
          "Exponent" -> Last[node]|>, tag],
      True,
        Throw[<|"Status" -> "UnsupportedExpression",
          "Expression" -> HoldForm[node]|>, tag]];
    evaluate[expression], tag, #1 &];
  If[AssociationQ[result], result,
    <|"Status" -> "OK", "Value" -> Mod[result, prime]|>]
];

(* One accepted point: the mod-p image of EVERY entry of the source.
   Returns a typed rejection instead of a value matrix if any term is
   not evaluable there. *)
blockEquationDeferredEvaluate[preparation_Association, point_,
    epsilonValue_, prime_Integer, parameterRules_: {}] := Module[
  {started = AbsoluteTime[], variables, regulator, parameters,
   dimensions, records, scalarValues, image, ruleLeft, missing, extra,
   termResults, tag = Unique["blockEquationDeferredPointTag"], result},
  If[Lookup[preparation, "Status", None] =!= "Prepared" ||
      Lookup[preparation, "ABIVersion", None] =!=
        $blockEquationDeferredABIVersion,
    Return[<|"Status" -> "InvalidPreparation"|>]];
  (* Codex 2: the ABI is re-derived and must match, or the artifact is
     refused -- fail closed, never best effort *)
  If[Lookup[preparation, "Fingerprint", None] =!=
      blockEquationDeferredFingerprint[KeyDrop[preparation, "Fingerprint"]],
    Return[<|"Status" -> "PreparationFingerprintMismatch"|>]];
  If[! IntegerQ[prime] || prime <= 3 || prime >= 2^31 ||
      ! TrueQ[PrimeQ[prime]],
    Return[<|"Status" -> "InvalidPrime", "Prime" -> prime|>]];
  If[! MatchQ[point, {_Integer, _Integer}],
    Return[<|"Status" -> "InvalidPoint", "Point" -> point|>]];
  If[! MatchQ[epsilonValue, _Integer | _Rational] ||
      Mod[Denominator[epsilonValue], prime] === 0,
    Return[<|"Status" -> "BadPrime", "Regulator" -> epsilonValue,
      "Prime" -> prime|>]];
  If[! ListQ[parameterRules] ||
      ! AllTrue[parameterRules, MatchQ[#, _Rule] &] ||
      ! AllTrue[Last /@ parameterRules, MatchQ[#, _Integer | _Rational] &],
    Return[<|"Status" -> "InvalidParameterRules"|>]];
  variables = preparation["Variables"];
  regulator = preparation["Regulator"];
  parameters = Lookup[preparation, "Parameters", {}];
  ruleLeft = First /@ parameterRules;
  missing = Select[parameters, ! MemberQ[ruleLeft, #] &];
  extra = Select[ruleLeft, ! MemberQ[parameters, #] &];
  If[missing =!= {},
    Return[<|"Status" -> "MissingParameters", "Parameters" -> missing|>]];
  If[extra =!= {},
    Return[<|"Status" -> "UnknownParameters", "Parameters" -> extra|>]];
  dimensions = preparation["Dimensions"];
  records = Lookup[preparation, "Records", {}];
  scalarValues = Association[Join[
    Thread[variables -> Mod[point, prime]],
    {regulator -> epsilonValue}, parameterRules]];
  image = ConstantArray[0, dimensions];
  result = Catch[
    Do[
      termResults = blockEquationDeferredModEvaluate[
          blockEquationDeferredTermExpression[#], scalarValues, {},
          prime] & /@ record["Terms"];
      If[! AllTrue[termResults, #1["Status"] === "OK" &],
        Throw[Join[FirstCase[termResults,
            entry_ /; entry["Status"] =!= "OK"],
          <|"Target" -> record["Target"], "Point" -> Mod[point, prime],
            "Prime" -> prime|>], tag]];
      image[[Sequence @@ record["Target"]]] =
        Mod[Total[Lookup[termResults, "Value", {}]], prime],
      {record, records}];
    "OK", tag, #1 &];
  If[result =!= "OK", Return[result]];
  <|"Status" -> "OK", "Prime" -> prime, "Point" -> Mod[point, prime],
    "Regulator" -> epsilonValue,
    "Fingerprint" -> preparation["Fingerprint"],
    "Image" -> image,
    "EvaluateSeconds" -> N[AbsoluteTime[] - started]|>
];

blockEquationDeferredEvaluate[___] := <|"Status" -> "InvalidInput"|>;

(* ---- census (Codex 6/8) --------------------------------------------- *)

(* A single nonzero image over F_p is an EXACT proof that the entry does
   not vanish identically; that is what makes the modular census a
   replacement for the driver's Together-based zero-forcing probe rather
   than a heuristic.  The converse is not a proof, so entries no image
   separates from zero are reported Undecided and decided exactly by the
   materializer's Expand. *)
blockEquationDeferredNonzeroCensus[preparation_Association,
    triples_List] := Module[
  {started = AbsoluteTime[], nonzero = <||>, rejections = {},
   accepted = 0, evaluation, dimensions, targets, undecided},
  If[Lookup[preparation, "Status", None] =!= "Prepared",
    Return[<|"Status" -> "InvalidPreparation"|>]];
  dimensions = preparation["Dimensions"];
  Do[
    evaluation = blockEquationDeferredEvaluate[preparation,
      triple[[1]], triple[[2]], triple[[3]],
      If[Length[triple] >= 4, triple[[4]], {}]];
    If[Lookup[evaluation, "Status", None] =!= "OK",
      AppendTo[rejections, KeyTake[evaluation,
        {"Status", "Target", "Point", "Prime", "Symbol", "Denominator",
         "Parameters"}]];
      (* These refusals are properties of the FRAME or the
         PREPARATION, not of the point: no further point can succeed, and
         on an algebraic frame every remaining triple would repeat the
         same ~0.6 s ABI re-derivation for nothing.  A denominator-zero
         point or a bad prime IS point-specific and the loop continues. *)
      If[MemberQ[{"AlgebraicOperandUnsupported", "UnsupportedExpression",
          "MissingParameters", "PreparationFingerprintMismatch",
          "InvalidPreparation"},
          Lookup[evaluation, "Status", None]],
        Break[]],
      accepted++;
      Do[If[evaluation["Image"][[mu, i, jj]] =!= 0,
          nonzero[{mu, i, jj}] = True],
        {mu, dimensions[[1]]}, {i, dimensions[[2]]},
        {jj, dimensions[[3]]}]],
    {triple, triples}];
  targets = Flatten[Table[{mu, i, jj}, {mu, dimensions[[1]]},
    {i, dimensions[[2]]}, {jj, dimensions[[3]]}], 2];
  undecided = Select[targets, ! KeyExistsQ[nonzero, #] &];
  <|"Status" -> If[accepted === 0, "AllPointsRejected", "OK"],
    "AcceptedSamples" -> accepted,
    "RequestedSamples" -> Length[triples],
    "Rejections" -> rejections,
    "NonzeroTargets" -> Keys[nonzero],
    "UndecidedTargets" -> undecided,
    "NonzeroProvedQ" -> Length[Keys[nonzero]] > 0,
    "CensusSeconds" -> N[AbsoluteTime[] - started]|>
];

(* ---- exact materialization ------------------------------------------ *)

(* One interned canonical operand: {numerator with the denominator's
   numeric content folded in, the denominator's irreducible factors as
   factor -> exponent}.  The pool is an Association keyed by the
   expression, i.e. a hash bucket with SameQ collision semantics
   (Codex 2 / Q1.2). *)
SetAttributes[blockEquationDeferredCanonicalOperand, HoldRest];
blockEquationDeferredCanonicalOperand[expression_, pool_Symbol] :=
  Module[{q, numerator, denominator, factorList, content, factors},
    If[KeyExistsQ[pool, expression], Return[pool[expression]]];
    q = Together[expression];
    numerator = Numerator[q]; denominator = Denominator[q];
    If[TrueQ[denominator === 1],
      pool[expression] = {numerator, <||>};
      Return[pool[expression]]];
    factorList = FactorList[denominator];
    content = Times @@ ((First[#]^Last[#]) & /@
      Select[factorList, NumericQ[First[#]] &]);
    factors = Association[
      (First[#] -> Last[#]) & /@ Select[factorList, ! NumericQ[First[#]] &]];
    pool[expression] = {
      If[TrueQ[content === 1], numerator, Cancel[numerator/content]],
      factors};
    pool[expression]];

(* ---- phase telemetry (Codex 2026-08-25 06:30, item A) --------------- *)

(* MEASURED MOTIVATION.  The materializer returned its substage totals
   only at the END, so a 1868 s construction (CF303 {17,12}, production
   2026-08-25 08:31) was a single silent interval: the campaign watchdog
   could not tell one expensive entry from a deadlock, and twice escalated
   an interval that was in fact healthy.  A start record and a
   RATE-LIMITED progress record make the distinction without touching the
   exact operation or weakening the cooperative deadline.  The records are
   PRINTED and are never returned in place of a value; the count is
   carried in the statistics so a test can assert the rate limit. *)
blockEquationDeferredProgressIntervalDefault[] :=
  Module[{value = Environment["FACET_MATERIALIZE_PROGRESS_SECONDS"]},
    (* N[...] deliberately: Max[0., 5] returns the INTEGER 5, and a
       caller comparing the interval against a machine number would then
       see a type it did not expect *)
    If[StringQ[value] && StringMatchQ[value, NumberString],
      N[Max[0, ToExpression[value]]], 60.]];

blockEquationDeferredProgressRecord[tag_String, data_Association] :=
  Print["[deferred-materialize] ", tag, ": ",
    StringRiffle[KeyValueMap[
      Function[{key, value},
        key <> " " <> ToString[If[Head[value] === Real, Round[value, 0.1], value],
          InputForm]], data], ", "]];

(* ---- the immutable second phase (Codex 2026-08-25 06:30, item B) ---- *)

(* FACET_MATERIALIZE_PARALLEL=Off reverts every caller to the serial
   assembly, exactly as FACET_CONSTRUCTION_ROUTE=Symbolic reverts the
   whole deferred route: the risk of the parallel phase is contained to
   one environment variable. *)
blockEquationDeferredParallelRouteQ[] := Module[
  {value = Environment["FACET_MATERIALIZE_PARALLEL"]},
  ! (StringQ[value] && StringMatchQ[value, "Off" | "False" | "0",
      IgnoreCase -> True])];

(* ONE TARGET, ON IMMUTABLE DATA.  `operands` is the interned operand
   table -- entry id -> {numerator, factor -> exponent} -- and `job` is
   one target's terms as {coefficient, {operand id, ...}}.  Nothing here
   reads or writes the intern pool, so a batch of these is a set of
   INDEPENDENT jobs a helper kernel can run (Codex's step 3); the mutable
   interning/factorization phase stays on the main kernel, in
   deterministic order, and is never parallelized (his explicit
   prohibition).  The arithmetic below is the arithmetic the serial route
   ran before this split, unchanged, so the two routes agree by
   construction and are asserted to agree on fixtures. *)
blockEquationDeferredAssembleJob[operands_List, job_List, cancelQ_,
    polynomialSymbols_List] := Module[
  {operandData, termNumerators, termFactors, common, numerator,
   denominator, cancelled, exponent, quotient, radicals,
   polynomialVariables, entryValue, timing,
   expandSeconds = 0., cancelSeconds = 0., algebraicSeconds = 0.},
  operandData = Map[
    Function[term, {First[term], operands[[#]] & /@ Last[term]}], job];
  termNumerators = (First[#] * (Times @@ (First /@ Last[#])) & /@
    operandData);
  termFactors = (Merge[Last /@ Last[#], Total] & /@ operandData);
  common = If[termFactors === {}, <||>, Merge[termFactors, Max]];
  (* the common denominator is a per-factor maximum of already-factored
     denominators: no polynomial gcd is computed here *)
  timing = AbsoluteTiming[
    numerator = Expand[Total[Table[
      termNumerators[[index]] * (Times @@ KeyValueMap[
        Function[{factor, power},
          factor^(power - Lookup[termFactors[[index]], factor, 0])],
        common]),
      {index, Length[job]}]]]];
  expandSeconds = First[timing];
  denominator = common;
  If[TrueQ[numerator === 0],
    Return[<|"Value" -> 0, "Zero" -> True, "Algebraic" -> False,
      "ExpandSeconds" -> expandSeconds, "CancelSeconds" -> 0.,
      "AlgebraicSeconds" -> 0.|>]];
  If[TrueQ[cancelQ] && denominator =!= <||>,
    timing = AbsoluteTiming[
      (* The divisibility test is "the quotient is a polynomial".  On
         an ALGEBRAIC frame the quotient is a polynomial in the chart
         variables AND the declared radicals, and PolynomialQ over the
         bare symbols alone answers False for every such quotient -- so
         no algebraic factor ever cancelled.  MEASURED on CF259
         (21,18), 2026-08-25: that left one extra power of
         (-1 - x + y + Sqrt[...]) in the forcing's denominator, which
         the downstream gauge denominator inherits (exponent 5 against
         the symbolic route's 4) and which would enlarge the solver's
         ansatz.  The radicals of the common denominator are therefore
         adjoined to the polynomial variables; a radical the quotient
         carries but the denominator does not still answers False,
         which leaves the entry exact and merely uncancelled. *)
      radicals = DeleteDuplicates[Cases[Keys[denominator],
        Power[_, _Rational], {0, Infinity}, Heads -> True]];
      polynomialVariables = Join[polynomialSymbols, radicals];
      cancelled = <||>;
      KeyValueMap[
        Function[{factor, power},
          exponent = power;
          While[exponent > 0,
            quotient = Quiet[Check[Cancel[numerator/factor], $Failed]];
            If[quotient === $Failed ||
                ! PolynomialQ[quotient, polynomialVariables],
              Break[]];
            numerator = quotient; exponent--];
          If[exponent > 0, cancelled[factor] = exponent]],
        denominator];
      denominator = cancelled];
    cancelSeconds = First[timing]];
  If[denominator === <||>,
    Return[<|"Value" -> numerator, "Zero" -> False, "Algebraic" -> False,
      "ExpandSeconds" -> expandSeconds, "CancelSeconds" -> cancelSeconds,
      "AlgebraicSeconds" -> 0.|>]];
  entryValue = numerator / (Times @@ KeyValueMap[#1^#2 &, denominator]);
  (* A radical still left in the common denominator means the factored
     cancellation could not finish: dividing out (a + Sqrt[D]) needs the
     relation Sqrt[D]^2 = D, which Cancel does not use when Sqrt[D] is
     an opaque polynomial variable.  MEASURED on CF259 (21,18): without
     this step the assembled forcing keeps one extra power of
     (-1 - x + y + Sqrt[...]) and the solver's gauge denominator comes
     out at exponent 5 against the symbolic route's 4 -- a larger
     ansatz, which would give back at the solve what the construction
     saved.  One Together on the ASSEMBLED RATIO restores exactly the
     canonical form the symbolic route produced; it is not the
     expensive object, because the term sum has already been collapsed
     to a single quotient. *)
  (* WHAT IS DELIBERATELY NOT DONE HERE.  The obvious completion is to
     rationalize each algebraic denominator factor A + B r by its norm
     A^2 - B^2 D (Codex Q2's "correct first family").  MEASURED
     2026-08-25 on the algebraic fixture of
     Tests/Multiquadratic/t_construction_dag:
     it is exact, cheap (0.38 s) and yields the SMALLEST entries of all
     three routes -- and it is wrong for this pipeline, because it
     removes the algebraic letters from the forcing's denominators
     altogether: the gauge denominator came out as x^3 (3 + x) (1 + y),
     purely rational, with the letter (1 + x - y + Sqrt[...]) gone,
     since its norm is 4 x.  epsFormStripAlphabet reads the ALPHABET
     off those denominators, so rationalizing would silently delete
     letters the gauge needs -- the Together-destroys-algebraic-words
     trap this repository already records.  The algebraic factor is
     therefore kept, at the price named below. *)
  If[! FreeQ[Keys[denominator], Power[_, _Rational]],
    timing = AbsoluteTiming[entryValue = Together[entryValue]];
    algebraicSeconds = First[timing];
    Return[<|"Value" -> entryValue, "Zero" -> False, "Algebraic" -> True,
      "ExpandSeconds" -> expandSeconds, "CancelSeconds" -> cancelSeconds,
      "AlgebraicSeconds" -> algebraicSeconds|>]];
  <|"Value" -> entryValue, "Zero" -> False, "Algebraic" -> False,
    "ExpandSeconds" -> expandSeconds, "CancelSeconds" -> cancelSeconds,
    "AlgebraicSeconds" -> 0.|>];

(* Batches of CONSECUTIVE jobs in target order: at most one group per
   worker (the free helpers plus this kernel), and any group whose
   ESTIMATED BYTES exceed the cap split further into consecutive chunks.
   Codex's step 3 requires the size to obey a byte cap rather than an
   entry count -- four simultaneous exact assemblies of a multi-GB entry
   would trade a construction wall for a memory wall.  The plan is a
   pure function of (bytes, workers, cap), so it is deterministic and is
   asserted to be in the suite. *)
blockEquationDeferredBatchPlan[bytes_List, workers_Integer, byteCap_] :=
  Module[{n = Length[bytes], share, batches = {}, current, load},
    If[n === 0, Return[{}]];
    share = Max[1, Ceiling[n/Max[1, workers]]];
    Do[
      current = {}; load = 0;
      Do[
        If[current =!= {} && load + bytes[[index]] > byteCap,
          AppendTo[batches, current]; current = {}; load = 0];
        AppendTo[current, index]; load += bytes[[index]],
        {index, group}];
      If[current =!= {}, AppendTo[batches, current]],
      {group, Partition[Range[n], UpTo[share]]}];
    batches];

(* helper side: one task = one batch of independent target jobs.  The
   operand table and the job list are written ONCE per materialization
   and read once per helper kernel (taskBrokerRead memoizes by path and
   modification time), exactly as the finite-field sampler does. *)
blockEquationDeferredMaterializeTask[dataFile_String, indices_List] :=
  Module[{data = taskBrokerRead[dataFile]},
    If[! AssociationQ[data], Return[$Failed]];
    Function[job, Quiet[Check[blockEquationDeferredAssembleJob[
        data["Operands"], job, data["Cancel"], data["PolynomialSymbols"]],
      $Failed]]] /@ data["Jobs"][[indices]]];

(* Exact value of the requested targets.  "Cancel" -> False keeps the
   uncancelled common denominator (still exact, but a larger alphabet for
   the downstream solver); the default cancels factor by factor.
   "Fallback" -> True (default) falls back to Together of the deferred
   sum for any entry the factored assembly cannot complete, so a defect
   here degrades to the previous behaviour instead of failing a run. *)
(* "CanonicalizeUntouched" trades Codex 4's SameQ preservation for the
   canonical form the DOWNSTREAM alphabet builder expects.  The default
   is the contract: an entry no feeder touched is returned unchanged.
   The driver overrides it to True, deliberately, because
   epsFormStripAlphabet reads the entry through CANONICA's
   ExtractIrreducibles, which enumerates the denominators it FINDS -- an
   un-normalized sum of two rational terms would contribute both
   denominators as letters even when the reduced entry has one.  On that
   path the untouched entry costs exactly what it cost before this file
   existed, and the saving is taken only where it was measured. *)
(* PHASES.  The materialization is one shared phase and one independent
   phase, and only the second is ever farmed out (Codex 2026-08-25 06:30,
   item B, confirmed 08:30 by the CF303 {17,12} split: 1604.1 s of 1868.4
   is numerator expansion, 248.5 s cancellation, and only 6.5 s the
   shared interning):

     1. SHARED, SERIAL, MAIN KERNEL.  Walk the records in deterministic
        target order and canonicalize every operand exactly once through
        blockEquationDeferredCanonicalOperand, which mutates the intern
        pool.  Each distinct operand receives an integer ID in
        first-encounter order, and each target's record is replaced by
        the IMMUTABLE job {coefficient, {operand id, ...}}.  This phase
        is never parallelized: naive parallelism would duplicate every
        Together/FactorList and lose the interning benefit outright.

     2. INDEPENDENT, PER TARGET.  Numerator expansion, per-factor
        cancellation and the final one-quotient algebraic Together read
        only the immutable operand table.  Bounded batches of consecutive
        jobs go to AT MOST the currently free pool helpers (the pool may
        be busy: with no free helper every job is computed locally, which
        is the serial route); this kernel always keeps the last batch, so
        it never idles waiting.  Batch size obeys an estimated-byte cap,
        not an entry count.

   Results are reassembled in target order on the main kernel, the typed
   Together fallback runs there, and a batch that fails or times out is
   recomputed locally through the same pure function -- so the returned
   values are what the serial route would have produced, whatever the
   pool did. *)
Options[blockEquationDeferredMaterialize] = {
  "Cancel" -> True, "Targets" -> All, "Fallback" -> True,
  "CanonicalizeUntouched" -> False,
  "Parallel" -> Automatic, "Helpers" -> Automatic,
  "BatchByteCap" -> Automatic, "BatchDispatcher" -> Automatic,
  "BatchTimeout" -> 7200, "Progress" -> True,
  "ProgressInterval" -> Automatic, "Label" -> "block",
  (* an already interned pool (operand expression -> {numerator, factor
     -> exponent}) to seed phase 1 with, so a caller that has ALREADY
     canonicalized every operand -- the round-3 bundle compiler -- does
     not pay the Together/FactorList of each distinct operand a second
     time.  A seed key is reused on a SameQ hit only, exactly like the
     pool's own entries; anything else is re-derived, so a wrong seed
     costs time, never a value. *)
  "SeedPool" -> <||>};

blockEquationDeferredMaterialize[preparation_Association,
    OptionsPattern[]] := Module[
  {started = AbsoluteTime[], records, dimensions, pool = <||>,
   requested, variables, regulator, parameters, symbols, values = <||>,
   algebraicSeconds = 0., algebraicEntries = 0,
   expandSeconds = 0., cancelSeconds = 0., internSeconds = 0.,
   fallbacks = 0, failedEntries = 0, zeroEntries = 0, untouchedEntries = 0,
   timing, entry,
   operandIndex = <||>, operandTable = {}, jobs = {}, jobTargets = {},
   jobRecords = {}, jobBytes = {}, cancelQ, total, results, progressQ,
   progressInterval, progressCount = 0, lastProgress, emit, absorb,
   helpers, byteCap, dispatcher, parallel, batches, dataFile, codes,
   handle, farmed, localBatch, assembleBatch, done = 0, missing, route,
   batchSeconds = 0., dispatchedBatches = 0, planned = 0},
  If[Lookup[preparation, "Status", None] =!= "Prepared" ||
      Lookup[preparation, "ABIVersion", None] =!=
        $blockEquationDeferredABIVersion,
    Return[<|"Status" -> "InvalidPreparation"|>]];
  If[Lookup[preparation, "Fingerprint", None] =!=
      blockEquationDeferredFingerprint[KeyDrop[preparation, "Fingerprint"]],
    Return[<|"Status" -> "PreparationFingerprintMismatch"|>]];
  variables = preparation["Variables"];
  regulator = preparation["Regulator"];
  parameters = Lookup[preparation, "Parameters", {}];
  symbols = Join[variables, {regulator}, parameters];
  records = Lookup[preparation, "Records", {}];
  dimensions = preparation["Dimensions"];
  requested = OptionValue["Targets"];
  If[AssociationQ[OptionValue["SeedPool"]], pool = OptionValue["SeedPool"]];
  cancelQ = TrueQ[OptionValue["Cancel"]];
  progressQ = TrueQ[OptionValue["Progress"]];
  progressInterval = Replace[OptionValue["ProgressInterval"],
    Automatic :> blockEquationDeferredProgressIntervalDefault[]];
  lastProgress = started;

  (* the rate limit is wall-clock: `force` emits the start, the dispatch
     and the final record unconditionally, everything else only after the
     interval has elapsed since the last record *)
  emit[tag_String, data_Association, force_: False] :=
    If[progressQ && (TrueQ[force] ||
        AbsoluteTime[] - lastProgress >= progressInterval),
      lastProgress = AbsoluteTime[]; progressCount++;
      blockEquationDeferredProgressRecord[tag, data]];

  absorb[record_] := (
    If[AssociationQ[record],
      expandSeconds += Lookup[record, "ExpandSeconds", 0.];
      cancelSeconds += Lookup[record, "CancelSeconds", 0.];
      algebraicSeconds += Lookup[record, "AlgebraicSeconds", 0.]];
    record);

  (* ---- phase 1: shared operand interning, serial, main kernel ------- *)
  (* MEASURED 2026-08-25 on the real CF259 (21,18) block: this phase is
     156 of its 196 s, so it needs its own progress records -- a start
     record alone would still leave a watchdog with a silent interval
     longer than the one that prompted the request. *)
  planned = Count[records, candidate_ /;
    (requested === All || MemberQ[requested, candidate["Target"]])];
  emit["start", <|"block" -> {Lookup[preparation, "Sector", None],
      Lookup[preparation, "LowerSector", None]},
    "records" -> planned,
    "terms" -> Total[Length[Lookup[#, "Terms", {}]] & /@ records]|>, True];
  Do[
    If[requested =!= All && ! MemberQ[requested, record["Target"]],
      Continue[]];
    (* Codex 4: an entry no feeder touched is preserved by SameQ *)
    If[blockEquationDeferredUntouchedQ[record],
      untouchedEntries++;
      values[record["Target"]] = If[TrueQ[OptionValue["CanonicalizeUntouched"]],
        Together[blockEquationDeferredRecordBase[record]],
        blockEquationDeferredRecordBase[record]];
      Continue[]];
    timing = AbsoluteTiming[
      AppendTo[jobs, Map[
        Function[term,
          {Lookup[term, "Coefficient", 1],
           Map[Function[operand,
             If[KeyExistsQ[operandIndex, operand], operandIndex[operand],
               AppendTo[operandTable,
                 blockEquationDeferredCanonicalOperand[operand, pool]];
               operandIndex[operand] = Length[operandTable]]],
             Lookup[term, "Operands", {}]]}],
        record["Terms"]]]];
    internSeconds += First[timing];
    AppendTo[jobTargets, record["Target"]];
    AppendTo[jobRecords, record];
    emit["intern", <|"records interned" -> Length[jobs], "of" -> planned,
      "target" -> record["Target"],
      "interned operands" -> Length[operandTable],
      "intern seconds" -> internSeconds|>],
    {record, records}];
  total = Length[jobs];

  (* ---- phase 2: independent per-target assembly -------------------- *)
  (* an estimate, not a measurement: the interned operand data a job
     references plus its own coefficients.  It bounds the payload a
     helper must read and the working set the assembly starts from. *)
  jobBytes = Map[Function[job,
    Total[ByteCount /@ operandTable[[
        DeleteDuplicates[Flatten[job[[All, 2]]]]]]] +
      ByteCount[job[[All, 1]]]], jobs];
  byteCap = Replace[OptionValue["BatchByteCap"], Automatic :> 2^28];
  dispatcher = OptionValue["BatchDispatcher"];
  helpers = OptionValue["Helpers"];
  If[helpers === Automatic,
    helpers = If[dispatcher === Automatic,
      If[taskBrokerActiveQ[], taskBrokerFreeKernels[], 0], 1]];
  If[! IntegerQ[helpers] || helpers < 0, helpers = 0];
  (* at most the currently free helpers, and never more than there are
     independent jobs to give away while this kernel keeps one batch *)
  helpers = Min[helpers, Max[0, total - 1]];
  parallel = With[{requestedParallel = OptionValue["Parallel"]},
    Which[
      requestedParallel === Automatic,
        helpers >= 1 && blockEquationDeferredParallelRouteQ[],
      TrueQ[requestedParallel], helpers >= 1,
      True, False]];
  route = If[parallel, "Parallel", "Serial"];

  (* the local assembly of one batch: used by the serial route, by this
     kernel's own share of the parallel route, and as the recomputation
     of any batch a helper failed to return *)
  assembleBatch[indices_List] := Map[
    Function[index,
      entry = absorb[If[TrueQ[OptionValue["Fallback"]],
        Quiet[Check[blockEquationDeferredAssembleJob[operandTable,
          jobs[[index]], cancelQ, symbols], $Failed]],
        blockEquationDeferredAssembleJob[operandTable, jobs[[index]],
          cancelQ, symbols]]];
      done++;
      emit["progress", <|"targets done" -> done, "of" -> total,
        "interned operands" -> Length[operandTable],
        "intern seconds" -> internSeconds,
        "expand seconds" -> expandSeconds,
        "cancel seconds" -> cancelSeconds,
        "canonicalize seconds" -> algebraicSeconds,
        "route" -> route|>];
      entry],
    indices];

  batches = If[total === 0, {},
    blockEquationDeferredBatchPlan[jobBytes, helpers + 1, byteCap]];
  results = ConstantArray[$Failed, total];

  If[! parallel || Length[batches] <= 1,
    route = "Serial";
    Do[results[[batches[[b]]]] = assembleBatch[batches[[b]]],
      {b, Length[batches]}],
    (* the helpers take the leading batches, this kernel the last one --
       the mission kernel never idles waiting for the pool *)
    dispatchedBatches = Length[batches] - 1;
    emit["dispatch", <|"batches" -> Length[batches],
      "to helpers" -> dispatchedBatches, "helpers free" -> helpers,
      "byte cap" -> byteCap, "batch sizes" -> Length /@ batches|>, True];
    timing = AbsoluteTiming[
      If[dispatcher === Automatic,
        dataFile = taskBrokerDataFile[
          "bedmat_" <> Hash[{operandTable, jobs, cancelQ, symbols},
            "SHA256", "HexString"],
          <|"Operands" -> operandTable, "Jobs" -> jobs,
            "Cancel" -> cancelQ, "PolynomialSymbols" -> symbols|>];
        codes = StringJoin[
          "FeynFacet`Private`blockEquationDeferredMaterializeTask[\"",
          dataFile, "\", ", ToString[#, InputForm], "]"] & /@ Most[batches];
        handle = taskBrokerSubmit[codes,
          "Label" -> "bedmat" <> ToString[OptionValue["Label"]],
          "Timeout" -> OptionValue["BatchTimeout"]];
        localBatch = assembleBatch[Last[batches]];
        farmed = taskBrokerCollect[handle],
        (* an injected dispatcher: the seam the suite uses to exercise
           batching, reassembly and the recomputation path without ever
           asking for a helper kernel *)
        farmed = dispatcher[<|"Operands" -> operandTable, "Jobs" -> jobs,
            "Cancel" -> cancelQ, "PolynomialSymbols" -> symbols|>,
          Most[batches]];
        localBatch = assembleBatch[Last[batches]]]];
    batchSeconds = First[timing];
    results[[Last[batches]]] = localBatch;
    Do[
      If[ListQ[farmed] && b <= Length[farmed] && ListQ[farmed[[b]]] &&
          Length[farmed[[b]]] === Length[batches[[b]]],
        results[[batches[[b]]]] = absorb /@ farmed[[b]];
        done += Length[batches[[b]]]],
      {b, Length[batches] - 1}];
    emit["collected", <|"targets done" -> done, "of" -> total,
      "expand seconds" -> expandSeconds,
      "cancel seconds" -> cancelSeconds,
      "canonicalize seconds" -> algebraicSeconds,
      "batch seconds" -> batchSeconds|>, True];
    (* a helper that failed, timed out or returned the wrong shape costs
       time, never a value: its batch is recomputed here, in order.  This
       kernel's own batch is excluded -- an entry the local assembly
       already refused would only be refused again, and the typed
       Together fallback below is its route. *)
    missing = Select[Complement[Range[total], Last[batches]],
      ! AssociationQ[results[[#]]] &];
    If[missing =!= {},
      emit["recompute", <|"targets" -> Length[missing],
        "reason" -> "no usable helper result"|>, True];
      results[[missing]] = assembleBatch[missing]]];

  (* ---- reassembly in target order, typed fallback on this kernel ---- *)
  Do[
    entry = results[[index]];
    (* the typed fallback is this kernel's, never a helper's, and it is
       taken only when the caller asked for one: with "Fallback" -> False
       an entry the factored assembly could not complete stays $Failed
       rather than being silently Together'd *)
    If[! AssociationQ[entry],
      If[TrueQ[OptionValue["Fallback"]],
        fallbacks++;
        entry = <|"Value" -> Together[Total[
            blockEquationDeferredTermExpression /@ jobRecords[[index]]["Terms"]]],
          "Zero" -> False, "Algebraic" -> False|>,
        failedEntries++;
        entry = <|"Value" -> $Failed, "Zero" -> False,
          "Algebraic" -> False|>]];
    If[TrueQ[Lookup[entry, "Zero", False]], zeroEntries++];
    If[TrueQ[Lookup[entry, "Algebraic", False]], algebraicEntries++];
    values[jobTargets[[index]]] = entry["Value"],
    {index, total}];

  emit["done", <|"targets done" -> total, "of" -> total,
    "interned operands" -> Length[operandTable],
    "intern seconds" -> internSeconds,
    "expand seconds" -> expandSeconds,
    "cancel seconds" -> cancelSeconds,
    "canonicalize seconds" -> algebraicSeconds,
    "route" -> route, "fallbacks" -> fallbacks,
    "seconds" -> N[AbsoluteTime[] - started]|>, True];

  <|"Status" -> "OK", "Values" -> values,
    "ZeroEntries" -> zeroEntries, "UntouchedEntries" -> untouchedEntries,
    "Fallbacks" -> fallbacks, "FailedEntries" -> failedEntries,
    "AlgebraicEntries" -> algebraicEntries,
    "Statistics" -> <|"InternedOperands" -> Length[pool],
      "InternSeconds" -> internSeconds,
      "ExpandSeconds" -> expandSeconds,
      "CancelSeconds" -> cancelSeconds,
      "AlgebraicCanonicalizeSeconds" -> algebraicSeconds,
      "Route" -> route, "Helpers" -> helpers,
      "Batches" -> Length[batches],
      "DispatchedBatches" -> dispatchedBatches,
      "BatchSizes" -> Length /@ batches,
      "BatchByteCap" -> byteCap,
      "EstimatedBytes" -> Total[jobBytes],
      "BatchSeconds" -> batchSeconds,
      "ProgressRecords" -> progressCount,
      "MaterializeSeconds" -> N[AbsoluteTime[] - started]|>|>
];
blockEquationDeferredMaterialize[___] := <|"Status" -> "InvalidInput"|>;

(* ---- THE PRESERVED DAG AND THE DIVISOR METADATA (2026-08-26,
   round-2 item 8; Codex review 2.2) ---------------------------------

   TWO PRODUCTS, NOT ONE.  Until now the public forcing result did
   KeyDrop[preparation, "Records"] and returned only the materialized
   dense matrices, so every downstream consumer had to work from a huge
   symbolic expression that this file had just finished avoiding.  Codex
   2.2: preserve the DAG (or a compiled modular plan) in the strip
   record, and return a SECOND product beside it --

     * a compact arithmetic DAG a coefficient provider can evaluate at a
       point, and
     * explicit divisor / Galois-orbit / multiplicity metadata for
       alphabet and gauge-denominator construction.

   The reason they must be separate is recorded at
   blockEquationDeferredCancelledValue: the arithmetic may rationalize or
   use compact norm denominators, while the ALPHABET still needs the
   original algebraic divisor.  "The visible spelling of a giant rational
   expression should not be the alphabet API."

   The DAG is kept whole by default.  A byte bound is available and the
   measured size is always recorded, but no bound is imposed until a
   measurement says one is needed -- the round-2 disposition is explicit
   that a byte bound enters only if it is measured to matter. *)

$blockEquationDeferredDAGSchema = "BlockEquationDeferredDAGV1";
$blockEquationDeferredDivisorSchema = "BlockEquationDivisorMetadataV1";

blockEquationDeferredDAGRecord[preparation_Association, byteLimit_] := Module[
  {records, bytes, retained},
  records = Lookup[preparation, "Records", {}];
  bytes = ByteCount[records];
  retained = byteLimit === Infinity || ! NumericQ[byteLimit] || bytes <= byteLimit;
  <|"Schema" -> $blockEquationDeferredDAGSchema,
    "ABIVersion" -> Lookup[preparation, "ABIVersion", Missing["NoABIVersion"]],
    "Variables" -> Lookup[preparation, "Variables", Missing["NoVariables"]],
    "Regulator" -> Lookup[preparation, "Regulator", Missing["NoRegulator"]],
    "Parameters" -> Lookup[preparation, "Parameters", {}],
    "Sector" -> Lookup[preparation, "Sector", None],
    "LowerSector" -> Lookup[preparation, "LowerSector", None],
    "RowIndices" -> Lookup[preparation, "RowIndices", {}],
    "ColumnIndices" -> Lookup[preparation, "ColumnIndices", {}],
    "Feeders" -> Lookup[preparation, "Feeders", {}],
    "Dimensions" -> Lookup[preparation, "Dimensions", Missing["NoDimensions"]],
    "SourceFingerprint" -> Lookup[preparation, "SourceFingerprint",
      Missing["NoFingerprint"]],
    "Fingerprint" -> Lookup[preparation, "Fingerprint",
      Missing["NoFingerprint"]],
    "TermCount" -> Total[Length[Lookup[#, "Terms", {}]] & /@ records],
    "RecordCount" -> Length[records],
    (* MEASURED, always -- this is the number a future byte-bound
       decision needs, and it costs one ByteCount *)
    "Bytes" -> bytes, "ByteLimit" -> byteLimit, "Retained" -> retained,
    "Records" -> If[retained, records, Missing["DAGOverByteLimit"]]|>
];

(* ---- divisor / Galois-orbit / multiplicity metadata ---------------- *)

(* The polar divisor of the assembled forcing, kept in the form the
   ALPHABET needs: algebraic factors are NEVER rationalized away (that is
   the measured trap recorded above -- rationalizing an algebraic
   denominator by its norm deletes the letter the gauge needs), each
   distinct irreducible factor carries the highest multiplicity it
   reaches in any single entry, and the algebraic factors are grouped
   into Galois orbits under the declared root sign flips with the orbit
   norm computed exactly.

   Cost: one FactorList per DISTINCT denominator.  That is the work the
   gauge-denominator rule already does, so this product adds no dominant
   stage; what it adds is that the result is recorded instead of being
   re-derived by every consumer from the printed expression. *)
Options[blockEquationDeferredDivisorMetadata] = {"Roots" -> Automatic};

blockEquationDeferredDivisorMetadata[forcing_, variables_List,
    opts : OptionsPattern[]] := Module[
  {started = AbsoluteTime[], entries, denominators, factorPairs, roots,
   radicalBases, rationalFactors, algebraicFactors, canonical, groups,
   orbits, orbitOf, conjugates, norm},
  entries = DeleteCases[Flatten[{forcing}], 0];
  If[entries === {},
    Return[<|"Schema" -> $blockEquationDeferredDivisorSchema,
      "Status" -> "EmptyForcing", "RationalFactors" -> {},
      "AlgebraicFactors" -> {}, "GaloisOrbits" -> {},
      "RadicalBases" -> {}, "Seconds" -> 0.|>]];
  denominators = DeleteDuplicates[
    Denominator[Quiet[Together[#1]]] & /@ entries];
  denominators = DeleteCases[denominators, _?NumericQ];
  factorPairs = Flatten[Map[
    Function[denominator, Module[{list = Quiet[FactorList[denominator]]},
      If[! ListQ[list], {},
        Select[Rest[list], ! NumericQ[First[#1]] &]]]],
    denominators], 1];
  radicalBases = DeleteDuplicates[
    Flatten[transportChartRadicalBases /@ denominators]];
  (* Codex round-3 A3: "Roots" -> Automatic must NOT manufacture an
     independent generator from every observed radical base -- Sqrt[d1 d2]
     is the grade {1,2} product of two declared generators, not a third
     one, and a dependent set inflates the orbit exponentially.  With no
     DECLARED frame the orbit and the norm of an algebraic factor are
     simply not derivable here, and the record says so with a typed
     Missing instead of an invented root tower.  The pre-cancellation
     bundle (blockEquationDeferredCompileBundle below) is the product
     that carries the declared frame. *)
  roots = Replace[OptionValue["Roots"], Automatic -> {}];
  If[! MatchQ[roots, {___Association}], roots = {}];
  (* multiplicity = the highest power the factor reaches in any single
     entry's denominator; a factor's exponent is never summed across
     entries, because the common polar divisor is the per-factor MAXIMUM *)
  canonical[factor_] := Quiet[Expand[Together[factor]]];
  groups = GatherBy[factorPairs, canonical[First[#1]] &];
  rationalFactors = Table[
    <|"Factor" -> canonical[First[First[group]]],
      "MaximumMultiplicity" -> Max[Last /@ group],
      "Occurrences" -> Length[group],
      "Algebraic" -> False|>,
    {group, Select[groups, FreeQ[First[First[#1]],
      Power[_, _Rational?(Denominator[#1] === 2 &)]] &]}];
  (* the exact Galois orbit of an algebraic factor under the declared
     root sign flips, and its orbit norm *)
  conjugates[factor_] := DeleteDuplicates[
    Table[Quiet[Together[transportChartApplyRootBranches[factor, roots,
      Table[If[BitGet[mask, k - 1] === 1, -1, 1] Lookup[roots[[k]], "Root", 0],
        {k, Length[roots]}]]]],
      {mask, 0, 2^Length[roots] - 1}],
    TrueQ[Quiet[Together[#1 - #2]] === 0] &];
  norm[factor_] := Quiet[Expand[Together[Times @@ conjugates[factor]]]];
  algebraicFactors = Table[
    Module[{factor = First[First[group]], orbit},
      If[roots === {},
        <|"Factor" -> factor,
          "MaximumMultiplicity" -> Max[Last /@ group],
          "Occurrences" -> Length[group],
          "Algebraic" -> True,
          "RadicalBases" -> transportChartRadicalBases[factor],
          "OrbitSize" -> Missing["RootFrameRequired"],
          "Orbit" -> Missing["RootFrameRequired"],
          "Norm" -> Missing["RootFrameRequired"],
          "NormFactors" -> {}|>,
        orbit = conjugates[factor];
        <|"Factor" -> factor,
          "MaximumMultiplicity" -> Max[Last /@ group],
          "Occurrences" -> Length[group],
          "Algebraic" -> True,
          "RadicalBases" -> transportChartRadicalBases[factor],
          "OrbitSize" -> Length[orbit],
          "Orbit" -> orbit,
          "Norm" -> norm[factor],
          "NormFactors" -> Module[{list = Quiet[FactorList[norm[factor]]]},
            If[ListQ[list], Select[Rest[list], ! NumericQ[First[#1]] &],
              {}]]|>]],
    {group, Select[groups, ! FreeQ[First[First[#1]],
      Power[_, _Rational?(Denominator[#1] === 2 &)]] &]}];
  (* named Function deliberately: the previous nested-slot comparator
     (ToString[InputForm[#2]]& inside a two-argument &) raised
     Function::slotn on every multi-orbit metadata call *)
  orbitOf = If[roots === {}, {},
    DeleteDuplicates[Lookup[algebraicFactors, "Orbit", {}],
      Function[{orbitA, orbitB},
        Sort[ToString[InputForm[#1]] & /@ orbitA] ===
          Sort[ToString[InputForm[#1]] & /@ orbitB]]]];
  orbits = Table[
    <|"Representative" -> First[orbit], "OrbitSize" -> Length[orbit],
      "Members" -> orbit, "Norm" -> norm[First[orbit]]|>,
    {orbit, orbitOf}];
  <|"Schema" -> $blockEquationDeferredDivisorSchema, "Status" -> "OK",
    "Variables" -> variables,
    "RadicalBases" -> radicalBases,
    "RootFrameDeclared" -> roots =!= {},
    "DistinctDenominators" -> Length[denominators],
    "RationalFactors" -> rationalFactors,
    "AlgebraicFactors" -> algebraicFactors,
    "GaloisOrbits" -> orbits,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
blockEquationDeferredDivisorMetadata[___] := <|"Status" -> "InvalidInput"|>;

(* ---- THE PRE-CANCELLATION DEFERRED BUNDLE (2026-08-26, round 3 A3;
   Codex codex_round3_detailed_fix_instructions section A3) ------------

   THE DEFECT THIS REPLACES.  blockEquationDeferredDivisorMetadata above
   reads Together of the MATERIALIZED forcing, so a divisor lost to
   cancellation before that point cannot be recovered from it; the
   preserved DeferredDAG is the raw record forest, so the measured
   interning phase was repeated by every downstream consumer; and
   "Roots" -> Automatic manufactured an independent generator from every
   observed radical base.  The bundle below is built from the deferred
   term records BEFORE any summation, cancellation or materialization.

   THE CONTRACT (Codex A3, verbatim fields):

     <|"Schema" -> "BlockEquationDeferredBundleV2",
       "Status" -> "PreparedDeferredBundle",
       "ABIVersion", "Variables", "Regulator", "Parameters",
       "RootFrame" -> <|"Roots", "RootFingerprints",
         "OrderingFingerprint"|>,
       "Dimensions" -> {2, nUpper, nLower},
       "TargetOrder" (complete, unique, lexicographic),
       "OperandTable" (canonical numerator, ordered denominator
         factor/exponent pairs, active-root mask, fingerprint),
       "Jobs" (aligned with TargetOrder; terms are
         {exactCoefficient, {operandID..}}),
       "DivisorOccurrences" (source target/term/operand provenance),
       "DivisorSummary", "SourceFingerprint", "BundleFingerprint",
       "Statistics"|>

   IMMUTABILITY.  The returned bundle is plain data: no delayed rules,
   closures, mutable pool symbols or memoized downvalues -- construction
   mutates only builders local to the compiler.  Consumers treat it as
   read-only, keep derived caches OUTSIDE it keyed by BundleFingerprint,
   and validate it first (blockEquationDeferredBundleValidate: schema,
   dimensions, root-order fingerprint, target coverage, operand-ID
   bounds, recomputed bundle fingerprint).  "Statistics" carries wall
   times and is the one field outside the fingerprint.

   BUILD ORDER (Codex A3, mandatory): (1) canonical independent root
   records from the caller's frame -- never synthesized from observed
   radicals; (2) every operand canonicalized/denested into that frame
   through the SHARED exact denester (transportChartDenestRadicalBase +
   the numerically sign-fixed rewrite), so Sqrt[Delta1 Delta2] becomes
   the grade {1,2} product of the two declared generators and is never
   registered as a third one; (3) explicit negative powers and canonical
   denominator factors collected with source target/term/operand
   provenance BEFORE any term is summed; (4) canonical operands interned
   and immutable jobs built; (5) divisor orbits generated from the
   occurrences, each orbit norm validated in the grade algebra; (6)
   materialization only as the explicit oracle/artifact mode of the
   driver entry point.  Typed refusals: DeferredRootFrameRequired
   (algebraic content, no frame), RadicalOutsideDeclaredFrame (a radical
   outside the declared square-class span), DependentRootSquares /
   DuplicateRootSquares (an invalid frame, refused BEFORE orbit
   generation).

   POLE-ORDER LABELS (Codex A3, "do not overstate pre-cancellation
   multiplicities").  Per-term divisor valuations are exact statements
   about the SOURCES; after summation they bound the entry's pole order
   from above, because leading poles can cancel.  The summary therefore
   carries EntryPoleOrderUpperBound (the maximum source pole order,
   safe for candidate-letter discovery, CONSERVATIVE as an ansatz
   denominator) and CertifiedEntryPoleOrder -> None until a divisor
   support census proves noncancellation.  Nothing here labels the
   source maximum as an exact forcing multiplicity. *)

$blockEquationDeferredBundleSchema = "BlockEquationDeferredBundleV2";

(* ---- the canonical independent root frame -------------------------- *)

(* The caller's root records ({<|"Root" -> Sqrt[q], "RootSquare" -> q|>
   ..}, the shape MultiquadraticStripSolve's root order produces) are
   validated and put into the solver's canonical order.  The dependence
   test is the solver's own (multiquadraticStripSquareClassSquareQ,
   called read-only): {x, y, x y} has rank two, and a dependent set must
   be refused BEFORE any orbit is generated. *)
blockEquationDeferredRootFrame[roots_List, variables_List, regulator_] :=
  Module[{squares, duplicates, dependent, rules, decorated},
  If[roots === {},
    Return[<|"Status" -> "StableRootOrder", "Roots" -> {},
      "RootFingerprints" -> {},
      "OrderingFingerprint" -> Hash[{}, "SHA256", "HexString"]|>]];
  If[! AllTrue[roots, AssociationQ[#1] && KeyExistsQ[#1, "Root"] &&
      KeyExistsQ[#1, "RootSquare"] &&
      TrueQ[Together[#1["Root"]^2 - #1["RootSquare"]] === 0] &],
    Return[<|"Status" -> "InvalidRootMetadata"|>]];
  squares = Together /@ Lookup[roots, "RootSquare"];
  duplicates = Select[Subsets[Range[Length[roots]], {2}],
    TrueQ[Together[squares[[#1[[1]]]] - squares[[#1[[2]]]]] === 0] &];
  If[duplicates =!= {},
    Return[<|"Status" -> "DuplicateRootSquares",
      "DuplicatePairs" -> duplicates|>]];
  dependent = FirstCase[Rest[Subsets[Range[Length[roots]]]],
    subset_ /; TrueQ[multiquadraticStripSquareClassSquareQ[
      Times @@ squares[[subset]]]] :> subset, None];
  If[dependent =!= None,
    Return[<|"Status" -> "DependentRootSquares",
      "RootIndices" -> dependent|>]];
  rules = multiquadraticStripCanonicalRules[variables, regulator];
  decorated = MapThread[Function[{root, index}, Module[
      {canonical, canonicalRoot},
      canonical = ToString[InputForm[
        multiquadraticStripCanonicalExpression[root["RootSquare"], rules]]];
      canonicalRoot = ToString[InputForm[
        multiquadraticStripCanonicalExpression[root["Root"], rules]]];
      Join[root, <|"SourceIndex" -> index,
        "CanonicalRootSquare" -> canonical,
        "CanonicalRootExpression" -> canonicalRoot,
        "RootSquareFingerprint" ->
          Hash[canonical, "SHA256", "HexString"],
        (* A root branch is part of the basis ABI.  Opposite roots have
           one square but opposite odd-grade coefficients, so a
           square-only fingerprint can alias two incompatible bundles. *)
        "RootFingerprint" -> Hash[{canonical, canonicalRoot}, "SHA256",
          "HexString"]|>]]],
    {roots, Range[Length[roots]]}];
  decorated = SortBy[decorated,
    {Lookup[#1, "CanonicalRootSquare", ""],
     Lookup[#1, "CanonicalRootExpression", ""],
     Lookup[#1, "RootFingerprint", ""]} &];
  <|"Status" -> "StableRootOrder", "Roots" -> decorated,
    "RootFingerprints" -> Lookup[decorated, "RootFingerprint", {}],
    "OrderingFingerprint" -> Hash[
      Transpose[{Lookup[decorated, "CanonicalRootSquare", {}],
        Lookup[decorated, "CanonicalRootExpression", {}]}],
      "SHA256", "HexString"]|>
];
blockEquationDeferredRootFrame[___] := <|"Status" -> "InvalidRootMetadata"|>;

(* ---- the canonical grade algebra ------------------------------------ *)

(* Declared radicals become polynomial generators s_i with s_i^2 = q_i,
   exactly as the shared denester's internal reduction; every statement
   about an algebraic factor (conjugates, norms, zero tests) is made in
   this basis, never by pattern-matching printed radicals. *)
blockEquationDeferredGradeReduceRules[squares_List, symbols_List] :=
  Table[With[{s = symbols[[i]], q = squares[[i]]},
    s^exponent_Integer /; (exponent < 0 || exponent >= 2) :>
      q^((exponent - Mod[exponent, 2])/2) s^Mod[exponent, 2]],
    {i, Length[symbols]}];

(* an s-polynomial (multilinear after reduction) from an expression whose
   symbolic radical bases all lie in `squares`; $Failed otherwise.  A
   numeric radical (Sqrt[2]) is a constant of the coefficient field and
   rides along. *)
blockEquationDeferredGradeReduce[expr_, squares_List, symbols_List] :=
  Module[{unmatched = {}, substituted, rules},
  substituted = expr /.
    Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
      Module[{position = FirstPosition[squares,
          q_ /; TrueQ[Together[base - q] === 0], Missing["NoRoot"], {1},
          Heads -> False]},
        Which[
          ! MissingQ[position], symbols[[First[position]]]^(2 exponent),
          NumericQ[base], Power[base, exponent],
          True, AppendTo[unmatched, base]; Power[base, exponent]]];
  If[unmatched =!= {}, Return[$Failed]];
  rules = blockEquationDeferredGradeReduceRules[squares, symbols];
  FixedPoint[Expand[#1 /. rules] &, Expand[substituted]]
];

(* mask -> channel coefficient, mask bit i-1 = generator s_i present *)
blockEquationDeferredGradeChannels[reduced_, symbols_List] :=
  Association @ Table[mask -> Fold[
      Function[{value, i}, Coefficient[value, symbols[[i]],
        If[BitGet[mask, i - 1] === 1, 1, 0]]],
      reduced, Range[Length[symbols]]],
    {mask, 0, 2^Length[symbols] - 1}];

(* exact zero over the declared multiquadratic field: substitute, clear
   the generators from the denominator by conjugation, and require every
   grade channel of the numerator to vanish.  $Failed on an undeclared
   symbolic radical -- never a silent False. *)
blockEquationDeferredAlgebraicZeroQ[expr_, squares_List] := Module[
  {symbols, unmatched = {}, substituted, rules, reduce, together,
   numerator, denominator, conjugate, i},
  symbols = Table[Unique["FeynFacet`Private`bedGradeRoot"],
    {Length[squares]}];
  substituted = expr /.
    Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
      Module[{position = FirstPosition[squares,
          q_ /; TrueQ[Together[base - q] === 0], Missing["NoRoot"], {1},
          Heads -> False]},
        Which[
          ! MissingQ[position], symbols[[First[position]]]^(2 exponent),
          NumericQ[base], Power[base, exponent],
          True, AppendTo[unmatched, base]; Power[base, exponent]]];
  If[unmatched =!= {}, Return[$Failed]];
  rules = blockEquationDeferredGradeReduceRules[squares, symbols];
  reduce[p_] := FixedPoint[Expand[#1 /. rules] &, Expand[p]];
  together = Together[substituted];
  numerator = reduce[Numerator[together]];
  denominator = reduce[Denominator[together]];
  Do[If[! FreeQ[denominator, symbols[[i]]],
      conjugate = reduce[denominator /. symbols[[i]] -> -symbols[[i]]];
      numerator = reduce[numerator conjugate];
      denominator = reduce[denominator conjugate]],
    {i, Length[symbols]}];
  If[symbols =!= {} && ! FreeQ[denominator, Alternatives @@ symbols],
    Return[$Failed]];
  AllTrue[Values[blockEquationDeferredGradeChannels[numerator, symbols]],
    TrueQ[Together[#1] === 0] &]
];

(* ---- canonicalization of one operand into the declared frame -------- *)

(* Build-order step 2.  A radical base that is not literally a declared
   square is denested through the SHARED exact denester with its
   numerically sign-fixed rewrite (TransportCharts), so Sqrt[Delta1
   Delta2] is rewritten to the grade {1,2} product of the declared
   generators.  A base outside the declared square-class span is the
   typed RadicalOutsideDeclaredFrame; symbolic radicals with no frame at
   all are DeferredRootFrameRequired.  A numeric radicand is a constant
   of the coefficient field, as everywhere else in this repository. *)
blockEquationDeferredFrameCanonicalize[expr_, frame_Association,
    variables_List] := Module[
  {roots, squares, oddPowers, radicals, symbolic, matched, unmatched,
   denested, failed, canonical, survivors, badSurvivors, indices},
  roots = Lookup[frame, "Roots", {}];
  squares = Together /@ (Lookup[#1, "RootSquare", 0] & /@ roots);
  oddPowers = DeleteDuplicates[Cases[expr,
    Power[base_ /; ! NumericQ[base],
      exponent_Rational /; Denominator[exponent] > 2] :> base,
    {0, Infinity}, Heads -> True]];
  If[oddPowers =!= {},
    Return[<|"Status" -> "UnsupportedAlgebraicPower",
      "Bases" -> oddPowers|>]];
  radicals = transportChartRadicalBases[expr];
  symbolic = Select[radicals, ! NumericQ[#1] &];
  If[symbolic === {},
    Return[<|"Status" -> "OK", "Expression" -> expr,
      "RootIndices" -> {}, "Denested" -> 0|>]];
  If[roots === {},
    Return[<|"Status" -> "DeferredRootFrameRequired",
      "RadicalBases" -> symbolic|>]];
  matched[base_] := FirstPosition[squares,
    q_ /; TrueQ[Together[base - q] === 0], Missing["NoRoot"], {1},
    Heads -> False];
  unmatched = Select[symbolic, MissingQ[matched[#1]] &];
  denested = Association @ Map[
    Function[base, base ->
      transportChartDenestRadicalBase[base, roots, variables]],
    unmatched];
  failed = Select[denested, Lookup[#1, "Status", None] =!= "Denested" &];
  If[failed =!= <||>,
    Return[<|"Status" -> "RadicalOutsideDeclaredFrame",
      "RadicalBases" -> Keys[failed], "Detail" -> Values[failed]|>]];
  canonical = If[denested === <||>,
    <|"Status" -> "OK", "Expression" -> expr, "Rewritten" -> 0|>,
    transportChartCanonicalizeDenestedRadicals[expr, roots, variables,
      denested]];
  If[Lookup[canonical, "Status", None] =!= "OK",
    Return[<|"Status" -> "RadicalOutsideDeclaredFrame",
      "Reason" -> "DenestSignAmbiguous", "Detail" -> canonical|>]];
  survivors = Select[
    transportChartRadicalBases[canonical["Expression"]],
    ! NumericQ[#1] &];
  badSurvivors = Select[survivors, MissingQ[matched[#1]] &];
  If[badSurvivors =!= {},
    Return[<|"Status" -> "RadicalOutsideDeclaredFrame",
      "RadicalBases" -> badSurvivors,
      "Reason" -> "SurvivedCanonicalization"|>]];
  indices = Sort[DeleteDuplicates[Join[
    First[matched[#1]] & /@ survivors,
    Flatten[Lookup[Values[denested], "RootIndices", {}]],
    Flatten[Lookup[Values[denested], "InnerRootIndices", {}]]]]];
  <|"Status" -> "OK", "Expression" -> canonical["Expression"],
    "RootIndices" -> indices,
    "Denested" -> Lookup[canonical, "Rewritten", 0]|>
];

(* bit i-1 of the mask = declared root i occurs in the factor; $Failed
   on a radical outside the declared frame *)
blockEquationDeferredFactorRootMask[factor_, squares_List] := Module[
  {radicals, positions},
  radicals = Select[transportChartRadicalBases[factor], ! NumericQ[#1] &];
  positions = Map[Function[base, FirstPosition[squares,
      q_ /; TrueQ[Together[base - q] === 0], Missing["NoRoot"], {1},
      Heads -> False]], radicals];
  If[AnyTrue[positions, MissingQ], $Failed,
    Total[2^(DeleteDuplicates[First /@ positions] - 1)]]
];

(* ---- orbit generation and validation (build-order step 5) ----------- *)

(* Sign conjugates are generated ONLY from the declared independent
   roots, every conjugate and the orbit product are reduced back to the
   canonical grade basis, and the norm is accepted only on the four
   exact conditions of Codex A3: all nonzero grade channels of the norm
   vanish, the grade-zero channel carries no radical and no generator,
   every generator sign flip permutes the orbit exactly (hence leaves
   the norm invariant exactly), and the orbit size divides 2^rank with
   duplicates removed by exact channel equality.  FreeQ[norm, Sqrt[..]]
   alone is NOT the acceptance. *)
blockEquationDeferredFactorOrbit[factor_, squares_List] := Module[
  {rank = Length[squares], symbols, reduced, channels, rules, masks,
   conjugates, distinct, toPolynomial, product, productChannels, norm,
   certificate, members},
  symbols = Table[Unique["FeynFacet`Private`bedOrbitRoot"], {rank}];
  reduced = blockEquationDeferredGradeReduce[factor, squares, symbols];
  If[reduced === $Failed,
    Return[<|"Status" -> "OrbitReductionFailed", "Factor" -> factor|>]];
  channels = blockEquationDeferredGradeChannels[reduced, symbols];
  masks = Keys[channels];
  conjugates = Table[Association @ Map[
      Function[mask, mask -> channels[mask] *
        (-1)^Total[Table[BitGet[mask, i - 1] BitGet[signMask, i - 1],
          {i, rank}]]],
      masks],
    {signMask, 0, 2^rank - 1}];
  distinct = DeleteDuplicates[conjugates,
    Function[{channelsA, channelsB}, AllTrue[masks,
      TrueQ[Together[channelsA[#1] - channelsB[#1]] === 0] &]]];
  toPolynomial[channelMap_] := Total[KeyValueMap[
    Function[{mask, value}, value Times @@ Table[
      If[BitGet[mask, i - 1] === 1, symbols[[i]], 1], {i, rank}]],
    channelMap]];
  rules = blockEquationDeferredGradeReduceRules[squares, symbols];
  product = Fold[
    Function[{accumulated, channelMap}, FixedPoint[
      Expand[#1 /. rules] &, Expand[accumulated toPolynomial[channelMap]]]],
    1, distinct];
  productChannels = blockEquationDeferredGradeChannels[product, symbols];
  norm = Together[Lookup[productChannels, Key[0], 0]];
  certificate = <|
    "NonzeroGradeChannelsVanish" -> AllTrue[
      Table[TrueQ[Together[Lookup[productChannels, Key[mask], 0]] === 0],
        {mask, 1, 2^rank - 1}], TrueQ],
    "GradeZeroRadicalFree" -> FreeQ[norm, Power[_, _Rational]] &&
      (symbols === {} || FreeQ[norm, Alternatives @@ symbols]),
    "GeneratorSignInvariance" -> AllTrue[Range[rank], Function[generator,
      AllTrue[distinct, Function[channelMap,
        AnyTrue[distinct, Function[other, AllTrue[masks,
          TrueQ[Together[channelMap[#1] *
            If[BitGet[#1, generator - 1] === 1, -1, 1] - other[#1]] ===
            0] &]]]]]]],
    "OrbitSizeDividesTwoPowerRank" ->
      rank === 0 || Divisible[2^rank, Length[distinct]]|>;
  members = Map[Function[channelMap, Total[KeyValueMap[
      Function[{mask, value}, value Times @@ Table[
        If[BitGet[mask, i - 1] === 1, Sqrt[squares[[i]]], 1], {i, rank}]],
      channelMap]]], distinct];
  <|"Status" -> If[AllTrue[Values[certificate], TrueQ], "OK",
      "OrbitNormValidationFailed"],
    "Representative" -> factor, "Members" -> members,
    "OrbitSize" -> Length[distinct], "Norm" -> norm,
    "NormCertificate" -> certificate|>
];

(* ---- bundle target order, fingerprint, validation, evaluation ------- *)

blockEquationDeferredBundleTargetOrder[
    {two_Integer, upper_Integer, lower_Integer}] :=
  Flatten[Table[{mu, i, jj}, {mu, two}, {i, upper}, {jj, lower}], 2];
blockEquationDeferredBundleTargetOrder[___] := $Failed;

(* recomputable content fingerprint; "Statistics" (wall times) and the
   fingerprint itself are the only fields outside it *)
blockEquationDeferredBundleFingerprint[bundle_Association] := Hash[{
  $blockEquationDeferredBundleSchema,
  Lookup[bundle, "Status", None],
  Lookup[bundle, "ABIVersion", None],
  blockEquationDeferredSymbolKey /@ Lookup[bundle, "Variables", {}],
  blockEquationDeferredSymbolKey[Lookup[bundle, "Regulator", None]],
  blockEquationDeferredSymbolKey /@ Lookup[bundle, "Parameters", {}],
  Lookup[Lookup[bundle, "RootFrame", <||>], "Roots", {}],
  Lookup[Lookup[bundle, "RootFrame", <||>], "RootFingerprints", {}],
  Lookup[Lookup[bundle, "RootFrame", <||>], "OrderingFingerprint", None],
  Lookup[bundle, "Dimensions", {}],
  Lookup[bundle, "TargetOrder", {}],
  Lookup[bundle, "OperandTable", {}],
  Lookup[bundle, "Jobs", {}],
  Lookup[bundle, "DivisorOccurrences", {}],
  Lookup[bundle, "DivisorSummary", <||>],
  Lookup[bundle, "SourceFingerprint", None]},
  "SHA256", "HexString"];

(* every consumer's first call.  Schema, dimensions, lexicographic
   target coverage, job alignment, operand-ID bounds, root-order
   fingerprint and the recomputed bundle fingerprint -- the enforceable
   content invariant WL has no const type for. *)
blockEquationDeferredBundleValidate[bundle_Association] := Module[
  {dimensions, targetOrder, expected, jobs, operandTable, operandCount,
   identifiers, frame, roots, variables, regulator, rules,
   canonicalSquares, canonicalRoots, squares, recheckedFrame, summary,
   factors, orbits, factorCount, orbitCount, occurrences, jobIndex,
   termIndex, term, factorIndex, operandID, operandFailure, operandTag,
   occurrenceFailure, occurrenceTag},
  If[Lookup[bundle, "Schema", None] =!= $blockEquationDeferredBundleSchema ||
      Lookup[bundle, "Status", None] =!= "PreparedDeferredBundle" ||
      Lookup[bundle, "ABIVersion", None] =!=
        $blockEquationDeferredABIVersion,
    Return[<|"Status" -> "InvalidBundleSchema"|>]];
  dimensions = Lookup[bundle, "Dimensions", None];
  If[! MatchQ[dimensions, {2, _Integer?Positive, _Integer?Positive}],
    Return[<|"Status" -> "InvalidBundleDimensions"|>]];
  targetOrder = Lookup[bundle, "TargetOrder", {}];
  expected = blockEquationDeferredBundleTargetOrder[dimensions];
  If[targetOrder =!= expected,
    Return[<|"Status" -> "TargetOrderNotLexicographic"|>]];
  jobs = Lookup[bundle, "Jobs", {}];
  If[! ListQ[jobs] || ! AllTrue[jobs,
      AssociationQ[#1] && ListQ[Lookup[#1, "Terms", None]] &&
        AllTrue[Lookup[#1, "Terms", {}],
          MatchQ[#1, {_, ids_List /; VectorQ[ids, IntegerQ]}] &] &],
    Return[<|"Status" -> "InvalidBundleJobs"|>]];
  If[Length[jobs] =!= Length[targetOrder] ||
      ! AllTrue[Range[Length[jobs]],
        Lookup[jobs[[#1]], "Target", None] === targetOrder[[#1]] &],
    Return[<|"Status" -> "JobsMisaligned"|>]];
  frame = Lookup[bundle, "RootFrame", <||>];
  roots = Lookup[frame, "Roots", {}];
  variables = Lookup[bundle, "Variables", {}];
  regulator = Lookup[bundle, "Regulator", None];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! SymbolQ[regulator] ||
      ! ListQ[roots] || ! AllTrue[roots,
        AssociationQ[#1] && KeyExistsQ[#1, "Root"] &&
          KeyExistsQ[#1, "RootSquare"] &&
          TrueQ[Together[#1["Root"]^2 - #1["RootSquare"]] === 0] &],
    Return[<|"Status" -> "RootOrderFingerprintMismatch"|>]];
  (* Re-run the mathematical frame gate: a refingerprinted artifact must
     not be able to smuggle duplicate or dependent square classes past
     the compiler's original check. *)
  recheckedFrame = blockEquationDeferredRootFrame[
    KeyTake[#1, {"Root", "RootSquare"}] & /@ roots, variables, regulator];
  If[Lookup[recheckedFrame, "Status", None] =!= "StableRootOrder",
    Return[<|"Status" -> "InvalidRootFrame",
      "Reason" -> Lookup[recheckedFrame, "Status", None]|>]];
  rules = multiquadraticStripCanonicalRules[variables, regulator];
  canonicalSquares = ToString[InputForm[
      multiquadraticStripCanonicalExpression[#1["RootSquare"], rules]]] & /@
    roots;
  canonicalRoots = ToString[InputForm[
      multiquadraticStripCanonicalExpression[#1["Root"], rules]]] & /@ roots;
  If[Lookup[roots, "CanonicalRootSquare", {}] =!= canonicalSquares ||
      Lookup[roots, "CanonicalRootExpression", {}] =!= canonicalRoots ||
      Lookup[roots, "RootSquareFingerprint", {}] =!=
        (Hash[#1, "SHA256", "HexString"] & /@ canonicalSquares) ||
      Lookup[roots, "RootFingerprint", {}] =!=
        (Hash[#1, "SHA256", "HexString"] & /@
          Transpose[{canonicalSquares, canonicalRoots}]) ||
      Lookup[frame, "RootFingerprints", {}] =!=
        Lookup[roots, "RootFingerprint", {}] ||
      roots =!= SortBy[roots,
        {Lookup[#1, "CanonicalRootSquare", ""],
         Lookup[#1, "CanonicalRootExpression", ""],
         Lookup[#1, "RootFingerprint", ""]} &] ||
      Lookup[frame, "OrderingFingerprint", None] =!= Hash[
        Transpose[{canonicalSquares, canonicalRoots}], "SHA256", "HexString"],
    Return[<|"Status" -> "RootOrderFingerprintMismatch"|>]];

  operandTable = Lookup[bundle, "OperandTable", None];
  If[! ListQ[operandTable],
    Return[<|"Status" -> "InvalidOperandTable"|>]];
  operandCount = Length[operandTable];
  squares = Together /@ Lookup[roots, "RootSquare", {}];
  operandTag = Unique["blockEquationDeferredOperandValidation"];
  operandFailure = Catch[Do[Module[
      {record = operandTable[[index]], recordPairs, expression,
       recomputedMask},
      If[! AssociationQ[record],
        Throw[<|"Status" -> "InvalidOperandTable",
          "OperandID" -> index|>, operandTag]];
      recordPairs = Lookup[record, "DenominatorFactors", None];
      If[! (Lookup[record, "ID", None] === index &&
          KeyExistsQ[record, "Numerator"] && ListQ[recordPairs] &&
          AllTrue[recordPairs,
            MatchQ[#1, {_, exponent_Integer?Positive}] &] &&
          IntegerQ[Lookup[record, "RootMask", None]] &&
          0 <= record["RootMask"] < 2^Length[roots] &&
          Lookup[record, "Fingerprint", None] === Hash[
            {record["Numerator"], recordPairs}, "SHA256", "HexString"]),
        Throw[<|"Status" -> "InvalidOperandTable",
          "OperandID" -> index|>, operandTag]];
      (* RootMask is executable hot-path metadata, not advisory telemetry.
         Recompute it from the immutable canonical operand at every bundle
         authentication boundary.  Merely checking its numeric range lets a
         refingerprinted artifact suppress a root and evaluate the operand in
         the wrong local subfield. *)
      expression = record["Numerator"]/Times @@
        (Power[First[#1], Last[#1]] & /@ recordPairs);
      recomputedMask = blockEquationDeferredFactorRootMask[
        expression, squares];
      If[recomputedMask === $Failed,
        Throw[<|"Status" -> "InvalidOperandRootMask",
          "OperandID" -> index|>, operandTag]];
      If[recomputedMask =!= record["RootMask"],
        Throw[<|"Status" -> "OperandRootMaskMismatch",
          "OperandID" -> index, "ExpectedRootMask" -> recomputedMask,
          "ObservedRootMask" -> record["RootMask"]|>, operandTag]]],
    {index, operandCount}]; None, operandTag, #1 &];
  If[AssociationQ[operandFailure],
    (* Preserve the historical fast integrity verdict for a stale outer
       fingerprint.  If the caller has recomputed that fingerprint, the
       stronger structural refusal above is the meaningful one. *)
    If[Lookup[bundle, "BundleFingerprint", None] =!=
        blockEquationDeferredBundleFingerprint[bundle],
      Return[<|"Status" -> "BundleFingerprintMismatch"|>]];
    Return[operandFailure]];
  identifiers = DeleteDuplicates[Flatten[
    Map[Function[job, Last /@ Lookup[job, "Terms", {}]], jobs]]];
  If[! AllTrue[identifiers, IntegerQ[#1] && 1 <= #1 <= operandCount &],
    Return[<|"Status" -> "OperandIDOutOfBounds",
      "OperandCount" -> operandCount,
      "Invalid" -> Select[identifiers,
        ! (IntegerQ[#1] && 1 <= #1 <= operandCount) &]|>]];
  summary = Lookup[bundle, "DivisorSummary", None];
  If[! AssociationQ[summary] ||
      Lookup[summary, "Schema", None] =!= "BlockEquationDivisorSummaryV2" ||
      ! ListQ[Lookup[summary, "Factors", None]] ||
      ! ListQ[Lookup[summary, "GaloisOrbits", None]],
    Return[<|"Status" -> "InvalidDivisorSummary"|>]];
  factors = summary["Factors"];
  orbits = summary["GaloisOrbits"];
  factorCount = Length[factors]; orbitCount = Length[orbits];
  If[! AllTrue[Range[factorCount], Function[index,
      AssociationQ[factors[[index]]] &&
        Lookup[factors[[index]], "FactorIndex", None] === index &&
        IntegerQ[Lookup[factors[[index]], "OrbitIndex", None]] &&
        0 <= factors[[index]]["OrbitIndex"] <= orbitCount &&
        If[TrueQ[Lookup[factors[[index]], "Algebraic", False]],
          factors[[index]]["OrbitIndex"] >= 1,
          factors[[index]]["OrbitIndex"] === 0]]],
    Return[<|"Status" -> "InvalidDivisorFactorTable"|>]];
  If[! AllTrue[orbits, AssociationQ],
    Return[<|"Status" -> "InvalidDivisorOrbitTable"|>]];

  occurrences = Lookup[bundle, "DivisorOccurrences", None];
  If[! ListQ[occurrences] || ! AllTrue[occurrences, AssociationQ],
    Return[<|"Status" -> "InvalidDivisorOccurrences"|>]];
  occurrenceTag = Unique["blockEquationDeferredOccurrenceValidation"];
  occurrenceFailure = Catch[Do[
    factorIndex = Lookup[occurrence, "FactorIndex", None];
    If[! IntegerQ[factorIndex] || ! (1 <= factorIndex <= factorCount),
      Throw[<|"Status" -> "DivisorFactorIndexOutOfBounds",
        "FactorIndex" -> factorIndex|>, occurrenceTag]];
    jobIndex = FirstPosition[targetOrder,
      Lookup[occurrence, "Target", None], Missing["UnknownTarget"]];
    If[MissingQ[jobIndex],
      Throw[<|"Status" -> "DivisorOccurrenceTargetUnknown"|>,
        occurrenceTag]];
    jobIndex = First[jobIndex];
    termIndex = Lookup[occurrence, "TermIndex", None];
    If[! IntegerQ[termIndex] ||
        ! (1 <= termIndex <= Length[jobs[[jobIndex]]["Terms"]]),
      Throw[<|"Status" -> "DivisorOccurrenceTermOutOfBounds"|>,
        occurrenceTag]];
    term = jobs[[jobIndex]]["Terms"][[termIndex]];
    operandID = Lookup[occurrence, "OperandID", None];
    If[! IntegerQ[operandID] || ! MemberQ[Last[term], operandID],
      Throw[<|"Status" -> "DivisorOccurrenceOperandMismatch"|>,
        occurrenceTag]];
    If[! MatchQ[Lookup[occurrence, "Exponent", None],
        _Integer | _Rational] ||
        ! TrueQ[Lookup[occurrence, "Exponent", None] > 0] ||
        ! MemberQ[{"CanonicalDenominator", "ExplicitNegativePower"},
          Lookup[occurrence, "Provenance", None]],
      Throw[<|"Status" -> "InvalidDivisorOccurrence"|>, occurrenceTag]],
    {occurrence, occurrences}]; None, occurrenceTag, #1 &];
  If[AssociationQ[occurrenceFailure], Return[occurrenceFailure]];
  If[Lookup[bundle, "BundleFingerprint", None] =!=
      blockEquationDeferredBundleFingerprint[bundle],
    Return[<|"Status" -> "BundleFingerprintMismatch"|>]];
  <|"Status" -> "BundleValid"|>
];
blockEquationDeferredBundleValidate[___] :=
  <|"Status" -> "InvalidBundleSchema"|>;

(* Assemble every target from the interned operand table: each operand
   is evaluated EXACTLY ONCE per call (the reuse the raw record forest
   never provided; OperandEvaluations is returned so a test can assert
   it), and every job reads the cached values.  rules = {} is the exact
   symbolic assembly the oracle tests compare against materialization;
   exact rational rules give one point.  Fails closed through the
   validator first. *)
Options[blockEquationDeferredBundleEvaluate] = {
  "Validate" -> True,
  "ExpressionTransform" -> Identity
};
blockEquationDeferredBundleEvaluate[bundle_Association, rules_List,
    OptionsPattern[]] := Module[
  {validation, operands, dimensions, evaluations = 0, singular = None,
   values, image, index, transform},
  If[TrueQ[OptionValue["Validate"]],
    validation = blockEquationDeferredBundleValidate[bundle];
    If[Lookup[validation, "Status", None] =!= "BundleValid",
      Return[validation]]];
  If[! AllTrue[rules, MatchQ[#1, _Rule] &],
    Return[<|"Status" -> "InvalidEvaluationRules"|>]];
  transform = OptionValue["ExpressionTransform"];
  operands = Lookup[bundle, "OperandTable", {}];
  dimensions = bundle["Dimensions"];
  values = Table[Module[
     {record = operands[[id]], numerator, factors},
     evaluations++;
     numerator = transform[record["Numerator"] /. rules];
     factors = ({Together[transform[First[#1] /. rules]], Last[#1]} & /@
       record["DenominatorFactors"]);
     If[AnyTrue[factors, TrueQ[First[#1] === 0] &],
       If[singular === None, singular = id]; 0,
       numerator/(Times @@ (Power[First[#1], Last[#1]] & /@ factors))]],
    {id, Length[operands]}];
  If[singular =!= None,
    Return[<|"Status" -> "SingularPoint", "OperandID" -> singular|>]];
  image = ConstantArray[0, dimensions];
  Do[
    image[[Sequence @@ bundle["TargetOrder"][[index]]]] = Total[Map[
      Function[term, transform[First[term] /. rules] Times @@
        values[[Last[term]]]],
      Lookup[bundle["Jobs"][[index]], "Terms", {}]]],
    {index, Length[bundle["TargetOrder"]]}];
  <|"Status" -> "OK", "Image" -> image,
    "OperandEvaluations" -> evaluations|>
];
blockEquationDeferredBundleEvaluate[___] := <|"Status" -> "InvalidInput"|>;

(* ---- the compiler (build-order steps 1-5) --------------------------- *)

(* The serial interning phase of the materializer, factored into a
   compiler that returns the immutable bundle INSTEAD of materializing:
   the same canonical-operand interning core
   (blockEquationDeferredCanonicalOperand), reached before any term is
   summed.  The WithCache variant additionally returns the finished
   intern pool so the driver's compat mode can seed the materializer
   with it and the Together/FactorList of each distinct operand is paid
   once, not twice. *)
Options[blockEquationDeferredCompileBundle] = {
  "Roots" -> {},
  "PruneUnusedRoots" -> True
};

blockEquationDeferredCompileBundle[preparation_Association,
    opts : OptionsPattern[]] :=
  First[blockEquationDeferredCompileBundleWithCache[preparation, opts]];
blockEquationDeferredCompileBundle[___] := <|"Status" -> "InvalidInput"|>;

blockEquationDeferredCompileBundleWithCache[preparation_Association,
    OptionsPattern[blockEquationDeferredCompileBundle]] := Module[
  {started = AbsoluteTime[], variables, regulator, parameters, records,
   dimensions, rootsOption, frame, squares, targetOrder, recordFor,
   pool = <||>, frameCache = <||>, sourceOperandCache = <||>,
   canonicalOperandIndex = <||>, operandTable = {}, factorTable = {},
   factorMatchQ, registerFactor,
   jobs = {}, occurrences = {}, bounds = <||>, occurrenceCounts = <||>,
   rewrites = 0, failTag, failure, orbitRecords, orbitIndexOf, summary,
   factorSummaries, bundle, statistics, termCount = 0,
   activeRootMask = 0, activeRootIndices, projectMask, projectedFrame,
   originalRootCount},
  If[Lookup[preparation, "Status", None] =!= "Prepared" ||
      Lookup[preparation, "ABIVersion", None] =!=
        $blockEquationDeferredABIVersion,
    Return[{<|"Status" -> "InvalidPreparation"|>, <||>}]];
  If[Lookup[preparation, "Fingerprint", None] =!=
      blockEquationDeferredFingerprint[KeyDrop[preparation, "Fingerprint"]],
    Return[{<|"Status" -> "PreparationFingerprintMismatch"|>, <||>}]];
  variables = preparation["Variables"];
  regulator = preparation["Regulator"];
  parameters = Lookup[preparation, "Parameters", {}];
  records = Lookup[preparation, "Records", {}];
  dimensions = preparation["Dimensions"];
  rootsOption = OptionValue["Roots"];
  If[! ListQ[rootsOption],
    Return[{<|"Status" -> "InvalidRootMetadata"|>, <||>}]];

  (* step 1: the canonical independent root frame, or the typed refusal
     BEFORE anything else is built *)
  frame = blockEquationDeferredRootFrame[rootsOption, variables, regulator];
  If[Lookup[frame, "Status", None] =!= "StableRootOrder",
    Return[{frame, <||>}]];
  squares = Together /@ (Lookup[#1, "RootSquare", 0] & /@ frame["Roots"]);

  targetOrder = blockEquationDeferredBundleTargetOrder[dimensions];
  recordFor = Association[(#1["Target"] -> #1) & /@ records];
  If[! AllTrue[targetOrder, KeyExistsQ[recordFor, #1] &],
    Return[{<|"Status" -> "TargetOrderIncomplete",
      "Missing" -> Select[targetOrder, ! KeyExistsQ[recordFor, #1] &]|>,
      <||>}]];

  factorMatchQ[f_, g_] := Module[
    {algebraic = ! FreeQ[{f, g}, Power[_, _Rational]]},
    If[! algebraic,
      TrueQ[Together[f - g] === 0] || TrueQ[Together[f + g] === 0],
      TrueQ[blockEquationDeferredAlgebraicZeroQ[f - g, squares]] ||
        TrueQ[blockEquationDeferredAlgebraicZeroQ[f + g, squares]]]];
  registerFactor[factor_] := Module[{position, mask},
    position = SelectFirst[Range[Length[factorTable]],
      factorMatchQ[factorTable[[#1]]["Factor"], factor] &, None];
    If[position =!= None, Return[position]];
    mask = blockEquationDeferredFactorRootMask[factor, squares];
    If[mask === $Failed,
      Throw[<|"Status" -> "RadicalOutsideDeclaredFrame",
        "RadicalBases" -> Select[transportChartRadicalBases[factor],
          ! NumericQ[#1] &]|>, failTag]];
    AppendTo[factorTable, <|"Factor" -> factor,
      "Algebraic" -> mask =!= 0, "RootMask" -> mask|>];
    Length[factorTable]];

  failTag = Unique["blockEquationDeferredCompileTag"];
  failure = Catch[
    Do[Module[{record = recordFor[target], terms, jobTerms = {},
       termIndex = 0},
      terms = Lookup[record, "Terms", {}];
      Do[Module[{coefficient, coefficientData, coefficientMask,
         operandIDs = {}, termSources = {}, termValuation, operandID},
        termIndex++; termCount++;
        coefficient = Lookup[term, "Coefficient", 1];
        coefficientData = blockEquationDeferredFrameCanonicalize[
          coefficient, frame, variables];
        If[Lookup[coefficientData, "Status", None] =!= "OK",
          Throw[coefficientData, failTag]];
        coefficient = coefficientData["Expression"];
        coefficientMask = blockEquationDeferredFactorRootMask[
          coefficient, squares];
        If[coefficientMask === $Failed,
          Throw[<|"Status" -> "RadicalOutsideDeclaredFrame"|>, failTag]];
        activeRootMask = BitOr[activeRootMask, coefficientMask];
        Do[Module[{identifier, sourceData},
          If[KeyExistsQ[sourceOperandCache, operand],
            sourceData = sourceOperandCache[operand];
            identifier = sourceData["OperandID"],
            (* A source spelling owns its provenance, while an evaluated
               operand is interned by the canonical numerator/factor
               record.  Conflating these two identities either evaluates
               equivalent spellings twice or assigns one spelling's
               explicit divisors to another. *)
            Module[{canonicalized, canonicalExpr, interned,
              canonicalFactors, explicitFactors = <||>, routeMaps,
              factorRoutes, mergedValuation, pairs, pairData, canonicalKey,
              canonicalValue, canonicalMask},
             canonicalized = If[KeyExistsQ[frameCache, operand],
               frameCache[operand],
               frameCache[operand] = blockEquationDeferredFrameCanonicalize[
                 operand, frame, variables]];
             If[Lookup[canonicalized, "Status", None] =!= "OK",
               Throw[canonicalized, failTag]];
             canonicalExpr = canonicalized["Expression"];
             rewrites += Lookup[canonicalized, "Denested", 0];
             interned = blockEquationDeferredCanonicalOperand[
               canonicalExpr, pool];
             canonicalFactors = interned[[2]];
             (* step 3, the pre-cancellation collection: the explicit
                negative powers of THIS source spelling, kept even when
                its canonical value is shared with another spelling *)
             Do[Module[{list = Quiet[FactorList[First[pair]]]},
               If[ListQ[list],
                 Do[If[! NumericQ[First[entry]],
                    explicitFactors[First[entry]] =
                      Lookup[explicitFactors, First[entry], 0] +
                        Last[entry] Last[pair]],
                   {entry, list}]]],
               {pair, Cases[canonicalExpr,
                 Power[base_, exponent_ /; (IntegerQ[exponent] ||
                     Head[exponent] === Rational) && exponent < 0] :>
                   {base, -exponent}, {0, Infinity}, Heads -> True]}];
             routeMaps = <|
               "CanonicalDenominator" -> Normal[canonicalFactors],
               "ExplicitNegativePower" -> Normal[explicitFactors]|>;
             factorRoutes = Association @ KeyValueMap[
               Function[{route, factorRules}, route -> Map[
                 Function[rule, {registerFactor[First[rule]], Last[rule]}],
                 factorRules]], routeMaps];
             mergedValuation = Merge[
               Map[Function[routeList, Module[{accumulated = <||>},
                   Do[accumulated[First[entry]] =
                       Lookup[accumulated, First[entry], 0] + Last[entry],
                     {entry, routeList}];
                   accumulated]], Values[factorRoutes]], Max];
             pairs = SortBy[Normal[canonicalFactors],
               ToString[InputForm[First[#1]]] &];
             pairData = {First[#1], Last[#1]} & /@ pairs;
             canonicalKey = {interned[[1]], pairData};
             If[KeyExistsQ[canonicalOperandIndex, canonicalKey],
               identifier = canonicalOperandIndex[canonicalKey],
               identifier = Length[operandTable] + 1;
               canonicalOperandIndex[canonicalKey] = identifier;
               canonicalValue = interned[[1]]/
                 Times @@ (Power[First[#1], Last[#1]] & /@ pairData);
               canonicalMask = blockEquationDeferredFactorRootMask[
                 canonicalValue, squares];
               If[canonicalMask === $Failed,
                 Throw[<|"Status" -> "RadicalOutsideDeclaredFrame"|>,
                   failTag]];
               activeRootMask = BitOr[activeRootMask, canonicalMask];
               AppendTo[operandTable, <|"ID" -> identifier,
                 "Numerator" -> interned[[1]],
                 "DenominatorFactors" -> pairData,
                 "RootMask" -> canonicalMask,
                 "Fingerprint" -> Hash[{interned[[1]], pairData},
                   "SHA256", "HexString"]|>]];
             sourceData = <|"OperandID" -> identifier,
               "Routes" -> factorRoutes, "Merged" -> mergedValuation|>;
             sourceOperandCache[operand] = sourceData]];
          AppendTo[operandIDs, identifier];
          AppendTo[termSources, sourceData]],
          {operand, Lookup[term, "Operands", {}]}];
        (* the exact per-term valuation = the sum of the term's operand
           valuations, recorded per route with full provenance *)
        Do[
          operandID = operandIDs[[operandPosition]];
          Do[
            AppendTo[occurrences, <|"FactorIndex" -> First[entry],
              "Exponent" -> Last[entry], "Target" -> target,
              "TermIndex" -> termIndex, "OperandID" -> operandID,
              "Provenance" -> route|>];
            occurrenceCounts[First[entry]] =
              Lookup[occurrenceCounts, First[entry], 0] + 1,
            {entry, Lookup[termSources[[operandPosition]]["Routes"],
              route, {}]}],
          {operandPosition, Length[operandIDs]},
          {route, {"CanonicalDenominator", "ExplicitNegativePower"}}];
        termValuation = If[termSources === {}, <||>,
          Merge[Lookup[termSources, "Merged", <||>], Total]];
        KeyValueMap[Function[{factorIndex, valuation},
          bounds[{factorIndex, target}] = Max[
            Lookup[bounds, Key[{factorIndex, target}], 0], valuation]],
          termValuation];
        AppendTo[jobTerms, {coefficient, operandIDs}]],
        {term, terms}];
      AppendTo[jobs, <|"Target" -> target, "Terms" -> jobTerms|>]],
      {target, targetOrder}];
    None, failTag, #1 &];
  If[failure =!= None, Return[{failure, pool}]];

  (* A declared family frame may be larger than this deferred source.  Keeping
     unused generators doubles every sheet and gauge grade for each one.  The
     compiler has now authenticated every operand mask and coefficient, so it
     can project the immutable bundle to its exact active subfield once. *)
  originalRootCount = Length[frame["Roots"]];
  If[TrueQ[OptionValue["PruneUnusedRoots"]] && originalRootCount > 0,
    activeRootIndices = Select[Range[originalRootCount],
      BitGet[activeRootMask, #1 - 1] === 1 &];
    If[Length[activeRootIndices] < originalRootCount,
      projectMask[mask_Integer] := Total[MapIndexed[
        If[BitGet[mask, #1 - 1] === 1, 2^(First[#2] - 1), 0] &,
        activeRootIndices]];
      operandTable = Map[Function[item, Join[item,
          <|"RootMask" -> projectMask[item["RootMask"]]|>]], operandTable];
      factorTable = Map[Function[item, Module[
          {mask = projectMask[item["RootMask"]]},
          Join[item, <|"Algebraic" -> (mask =!= 0), "RootMask" -> mask|>]]],
        factorTable];
      projectedFrame = blockEquationDeferredRootFrame[
        KeyTake[#1, {"Root", "RootSquare"}] & /@
          frame["Roots"][[activeRootIndices]], variables, regulator];
      If[Lookup[projectedFrame, "Status", None] =!= "StableRootOrder",
        Return[{projectedFrame, pool}]];
      frame = projectedFrame;
      squares = Together /@ Lookup[frame["Roots"], "RootSquare", {}]]];

  (* step 5: one validated orbit per distinct algebraic factor.  Throw,
     never Return, inside Do -- the trap this file already records *)
  orbitRecords = {}; orbitIndexOf = <||>;
  failure = Catch[
    Do[Module[{entry = factorTable[[factorIndex]], orbit, existing},
      If[! entry["Algebraic"], orbitIndexOf[factorIndex] = 0,
        orbit = blockEquationDeferredFactorOrbit[entry["Factor"], squares];
        If[Lookup[orbit, "Status", None] =!= "OK",
          Throw[Join[<|"Status" -> Lookup[orbit, "Status",
              "OrbitNormValidationFailed"]|>, KeyDrop[orbit, "Status"]],
            failTag]];
        existing = SelectFirst[Range[Length[orbitRecords]],
          Function[position, Module[{other = orbitRecords[[position]]},
            other["OrbitSize"] === orbit["OrbitSize"] &&
              AllTrue[orbit["Members"], Function[member,
                AnyTrue[other["Members"], TrueQ[
                  blockEquationDeferredAlgebraicZeroQ[member - #1,
                    squares]] &]]]]], None];
        If[existing === None,
          AppendTo[orbitRecords, KeyDrop[orbit, "Status"]];
          orbitIndexOf[factorIndex] = Length[orbitRecords],
          orbitIndexOf[factorIndex] = existing]]],
      {factorIndex, Length[factorTable]}];
    None, failTag, #1 &];
  If[failure =!= None, Return[{failure, pool}]];

  factorSummaries = Table[Module[{entry = factorTable[[factorIndex]],
     entryBounds},
     entryBounds = Sort[Map[Function[key, {Last[key],
         bounds[key]}], Select[Keys[bounds],
       First[#1] === factorIndex &]]];
     <|"FactorIndex" -> factorIndex, "Factor" -> entry["Factor"],
       "Algebraic" -> entry["Algebraic"],
       "RootMask" -> entry["RootMask"],
       "OrbitIndex" -> Lookup[orbitIndexOf, factorIndex, 0],
       "EntryPoleOrderUpperBounds" -> entryBounds,
       "MaxEntryPoleOrderUpperBound" -> If[entryBounds === {}, 0,
         Max[Last /@ entryBounds]],
       (* an exact final pole order enters ONLY through a
          noncancellation proof (the planned divisor support census);
          the source maximum above is a bound, and is labeled one *)
       "CertifiedEntryPoleOrder" -> None,
       "OccurrenceCount" -> Lookup[occurrenceCounts, factorIndex, 0]|>],
    {factorIndex, Length[factorTable]}];
  summary = <|"Schema" -> "BlockEquationDivisorSummaryV2",
    "Certification" -> "PreCancellationUpperBound",
    "CertifiedEntryPoleOrders" -> None,
    "Factors" -> factorSummaries,
    "GaloisOrbits" -> orbitRecords|>;

  statistics = <|"CompileSeconds" -> N[AbsoluteTime[] - started],
    "OperandCount" -> Length[operandTable],
    "JobCount" -> Length[jobs], "TermCount" -> termCount,
    "DeclaredRootCount" -> Length[rootsOption],
    "BundleRootCount" -> Length[frame["Roots"]],
    "PrunedRootCount" -> Length[rootsOption] - Length[frame["Roots"]],
    "OccurrenceCount" -> Length[occurrences],
    "DistinctFactors" -> Length[factorTable],
    "AlgebraicFactorCount" -> Count[factorTable, entry_ /;
      TrueQ[entry["Algebraic"]]],
    "FrameRewrites" -> rewrites|>;
  bundle = <|"Schema" -> $blockEquationDeferredBundleSchema,
    "Status" -> "PreparedDeferredBundle",
    "ABIVersion" -> $blockEquationDeferredABIVersion,
    "Variables" -> variables, "Regulator" -> regulator,
    "Parameters" -> parameters,
    "RootFrame" -> <|"Roots" -> frame["Roots"],
      "RootFingerprints" -> frame["RootFingerprints"],
      "OrderingFingerprint" -> frame["OrderingFingerprint"]|>,
    "Dimensions" -> dimensions,
    "TargetOrder" -> targetOrder,
    "OperandTable" -> operandTable,
    "Jobs" -> jobs,
    "DivisorOccurrences" -> occurrences,
    "DivisorSummary" -> summary,
    "SourceFingerprint" -> Lookup[preparation, "SourceFingerprint", None],
    "Statistics" -> statistics|>;
  {Append[bundle,
     "BundleFingerprint" -> blockEquationDeferredBundleFingerprint[bundle]],
   pool}
];
blockEquationDeferredCompileBundleWithCache[___] :=
  {<|"Status" -> "InvalidInput"|>, <||>};

(* ---- driver entry point --------------------------------------------- *)

(* The forcing bbar of block (k, j) as the dense matrix pair the strip
   solvers consume, built through the deferred route.  Returns the
   preparation, the census and the materialized forcing so the caller can
   reuse the census as its zero-forcing decision (a nonzero image is an
   exact proof that the block is NOT zero-forced) instead of paying a
   second Together pass over every entry. *)
Options[blockEquationDeferredForcing] = {
  "CensusTriples" -> Automatic, "Cancel" -> True, "Fallback" -> True,
  (* round-2 item 8 (Codex 2.2): the public result no longer discards the
     expression DAG.  Automatic keeps it whole and records its measured
     size; a finite "DAGByteLimit" drops the records above that size and
     says so.  No bound is imposed by default -- a byte bound enters when
     a measurement says it must, not before. *)
  "PreserveDAG" -> Automatic, "DAGByteLimit" -> Infinity,
  "DivisorMetadata" -> Automatic, "DivisorRoots" -> Automatic,
  "CanonicalizeUntouched" -> True,
  "Parallel" -> Automatic, "Helpers" -> Automatic,
  "BatchByteCap" -> Automatic, "BatchDispatcher" -> Automatic,
  "BatchTimeout" -> 7200, "Progress" -> True,
  "ProgressInterval" -> Automatic,
  (* round 3 A3 (Codex): bundle production is the normal result.
     "Output" -> "Bundle" returns the immutable pre-cancellation bundle
     WITHOUT ever materializing -- the early-return mode the direct
     provider consumes; "BundleAndMaterialized" additionally
     materializes as the oracle/artifact.  The default stays
     "BundleAndMaterialized" until the provider consumer lands in
     MultiquadraticStripSolve.wl (its sole production caller reads
     "Forcing"); it then flips to "Bundle" per the Codex instruction. *)
  "Output" -> "BundleAndMaterialized",
  (* the declared independent root records for the bundle's frame.
     Automatic inherits an explicitly given "DivisorRoots" list; with
     neither given, an algebraic block's bundle is the typed
     DeferredRootFrameRequired -- roots are NEVER synthesized from
     observed radicals *)
  "BundleRoots" -> Automatic,
  (* the injected-oracle seam: tests substitute a materializer that
     fails if invoked, proving the early-bundle path never calls it *)
  "MaterializeFunction" -> Automatic};

blockEquationDeferredForcing[connection_, ranges_, k_Integer, j_Integer,
    solved_Association, variables_, regulator_, OptionsPattern[]] :=
  Module[{preparation, triples, census, materialized, dimensions,
    forcing, values, output, bundleRoots, bundle, internCache,
    materializeFunction},
   output = OptionValue["Output"];
   If[! MemberQ[{"Bundle", "BundleAndMaterialized"}, output],
     Return[<|"Status" -> "InvalidOutputMode", "Output" -> output|>]];
   preparation = blockEquationDeferredPrepare[connection, ranges, k, j,
     solved, variables, regulator];
   If[Lookup[preparation, "Status", None] =!= "Prepared",
     Return[preparation]];
   triples = Replace[OptionValue["CensusTriples"], Automatic :>
     Flatten[Table[{censusPoint, censusRegulator, censusPrime},
       {censusPrime, {1000003, 1000033}},
       {censusPoint, {{7717, 9227}, {31627, 44417}}},
       {censusRegulator, {104729, 15485867}}], 2]];
   census = blockEquationDeferredNonzeroCensus[preparation, triples];
   (* round 3 A3: the bundle is compiled from the deferred term records
      BEFORE materialization -- build-order step 6 is the materialization
      below, reached only in the compat mode.  Its intern pool seeds the
      materializer so each distinct operand is canonicalized once. *)
   bundleRoots = Replace[OptionValue["BundleRoots"], Automatic :>
     If[ListQ[OptionValue["DivisorRoots"]], OptionValue["DivisorRoots"],
       {}]];
   {bundle, internCache} = blockEquationDeferredCompileBundleWithCache[
     preparation, "Roots" -> bundleRoots];
   If[output === "Bundle",
     (* the early return: a typed bundle refusal IS the result here, and
        blockEquationDeferredMaterialize is never called on this path *)
     If[Lookup[bundle, "Status", None] =!= "PreparedDeferredBundle",
       Return[bundle]];
     Return[Append[bundle, "Statistics" -> Join[
       Lookup[bundle, "Statistics", <||>],
       <|"Census" -> census,
         "ZeroForcingCandidateQ" ->
           ! TrueQ[census["NonzeroProvedQ"]]|>]]]];
   materializeFunction = Replace[OptionValue["MaterializeFunction"],
     Automatic :> blockEquationDeferredMaterialize];
   materialized = materializeFunction[preparation,
     "SeedPool" -> internCache,
     "Cancel" -> OptionValue["Cancel"],
     "Fallback" -> OptionValue["Fallback"],
     "CanonicalizeUntouched" -> OptionValue["CanonicalizeUntouched"],
     "Parallel" -> OptionValue["Parallel"],
     "Helpers" -> OptionValue["Helpers"],
     "BatchByteCap" -> OptionValue["BatchByteCap"],
     "BatchDispatcher" -> OptionValue["BatchDispatcher"],
     "BatchTimeout" -> OptionValue["BatchTimeout"],
     "Progress" -> OptionValue["Progress"],
     "ProgressInterval" -> OptionValue["ProgressInterval"],
     "Label" -> ToString[k] <> "_" <> ToString[j]];
   If[Lookup[materialized, "Status", None] =!= "OK",
     Return[materialized]];
   dimensions = preparation["Dimensions"];
   values = materialized["Values"];
   forcing = Table[values[{mu, i, jj}],
     {mu, dimensions[[1]]}, {i, dimensions[[2]]}, {jj, dimensions[[3]]}];
   <|"Status" -> "OK", "Forcing" -> forcing,
     "Preparation" -> KeyDrop[preparation, "Records"],
     (* TWO PRODUCTS, not one (round-2 item 8).  The compact arithmetic
        DAG a coefficient provider can evaluate at a point, and the
        explicit divisor / Galois-orbit / multiplicity metadata the
        alphabet and the gauge denominator are built from.  The visible
        spelling of a giant rational expression is not the alphabet API. *)
     "DeferredDAG" -> If[TrueQ[Replace[OptionValue["PreserveDAG"],
         Automatic :> True]],
       blockEquationDeferredDAGRecord[preparation,
         OptionValue["DAGByteLimit"]],
       <|"Schema" -> $blockEquationDeferredDAGSchema,
         "Retained" -> False, "Records" -> Missing["DAGNotPreserved"],
         "Bytes" -> ByteCount[Lookup[preparation, "Records", {}]]|>],
     "DivisorMetadata" -> If[TrueQ[Replace[OptionValue["DivisorMetadata"],
         Automatic :> True]],
       blockEquationDeferredDivisorMetadata[forcing, variables,
         "Roots" -> OptionValue["DivisorRoots"]],
       <|"Schema" -> $blockEquationDeferredDivisorSchema,
         "Status" -> "DivisorMetadataSkipped"|>],
     (* round 3 A3: the pre-cancellation bundle rides beside the
        materialized oracle in the compat mode; on an algebraic block
        with no declared roots it is the typed DeferredRootFrameRequired
        record, deliberately NON-fatal here so the production driver's
        materialized route is unchanged until its provider consumes the
        bundle mode *)
     "DeferredBundle" -> bundle,
     "Census" -> census, "Materialization" -> KeyDrop[materialized, "Values"],
     "ZeroForcingCandidateQ" -> ! TrueQ[census["NonzeroProvedQ"]]|>
];

blockEquationDeferredForcing[___] := <|"Status" -> "InvalidInput"|>;

End[];
