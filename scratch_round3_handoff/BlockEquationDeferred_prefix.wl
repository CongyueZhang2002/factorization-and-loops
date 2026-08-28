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
   (External/CodexExchange/triple_root_cf300_129_2026-08-24/
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
  $blockEquationDeferredABIVersion
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
     2026-08-25 on the algebraic fixture of Tests/t_construction_dag:
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
  "ProgressInterval" -> Automatic, "Label" -> "block"};

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
  roots = Replace[OptionValue["Roots"], Automatic :>
    (<|"Root" -> Sqrt[#1], "RootSquare" -> #1|> & /@ radicalBases)];
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
          If[ListQ[list], Select[Rest[list], ! NumericQ[First[#1]] &], {}]]|>],
    {group, Select[groups, ! FreeQ[First[First[#1]],
      Power[_, _Rational?(Denominator[#1] === 2 &)]] &]}];
  orbitOf = DeleteDuplicates[Lookup[algebraicFactors, "Orbit", {}],
    Sort[ToString[InputForm[#1]] & /@ #1] ===
      Sort[ToString[InputForm[#2]] & /@ #2] &];
  orbits = Table[
    <|"Representative" -> First[orbit], "OrbitSize" -> Length[orbit],
      "Members" -> orbit, "Norm" -> norm[First[orbit]]|>,
    {orbit, orbitOf}];
  <|"Schema" -> $blockEquationDeferredDivisorSchema, "Status" -> "OK",
    "Variables" -> variables,
    "RadicalBases" -> radicalBases,
    "DistinctDenominators" -> Length[denominators],
    "RationalFactors" -> rationalFactors,
    "AlgebraicFactors" -> algebraicFactors,
    "GaloisOrbits" -> orbits,
    "Seconds" -> N[AbsoluteTime[] - started]|>
];
blockEquationDeferredDivisorMetadata[___] := <|"Status" -> "InvalidInput"|>;

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
  "ProgressInterval" -> Automatic};

blockEquationDeferredForcing[connection_, ranges_, k_Integer, j_Integer,
    solved_Association, variables_, regulator_, OptionsPattern[]] :=
  Module[{preparation, triples, census, materialized, dimensions,
    forcing, values},
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
   materialized = blockEquationDeferredMaterialize[preparation,
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
     "Census" -> census, "Materialization" -> KeyDrop[materialized, "Values"],
     "ZeroForcingCandidateQ" -> ! TrueQ[census["NonzeroProvedQ"]]|>
];

blockEquationDeferredForcing[___] := <|"Status" -> "InvalidInput"|>;

End[];
