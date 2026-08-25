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
   risk of this change is contained to one environment variable. *)

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
Options[blockEquationDeferredMaterialize] = {
  "Cancel" -> True, "Targets" -> All, "Fallback" -> True,
  "CanonicalizeUntouched" -> False};

blockEquationDeferredMaterialize[preparation_Association,
    OptionsPattern[]] := Module[
  {started = AbsoluteTime[], records, dimensions, pool = <||>,
   requested, terms, operandData, termNumerators, termFactors,
   common, numerator, denominator, cancelled, exponent, quotient,
   radicals, polynomialVariables, entryValue, algebraicSeconds = 0.,
   algebraicEntries = 0,
   variables, regulator, parameters, symbols, values = <||>,
   expandSeconds = 0., cancelSeconds = 0., internSeconds = 0.,
   fallbacks = 0, zeroEntries = 0, untouchedEntries = 0, timing, entry,
   assemble},
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

  assemble[record_Association] := Module[{},
    terms = record["Terms"];
    timing = AbsoluteTiming[
      operandData = Map[
        Function[term,
          {Lookup[term, "Coefficient", 1],
            blockEquationDeferredCanonicalOperand[#, pool] & /@
              Lookup[term, "Operands", {}]}],
        terms]];
    internSeconds += First[timing];
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
        {index, Length[terms]}]]]];
    expandSeconds += First[timing];
    denominator = common;
    If[TrueQ[numerator === 0], zeroEntries++; Return[0]];
    If[TrueQ[OptionValue["Cancel"]] && denominator =!= <||>,
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
        polynomialVariables = Join[symbols, radicals];
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
      cancelSeconds += First[timing]];
    If[denominator === <||>, Return[numerator]];
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
       expensive object, because the 46-term sum has already been
       collapsed to a single quotient. *)
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
      algebraicSeconds += First[timing];
      algebraicEntries++];
    entryValue];

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
    entry = If[TrueQ[OptionValue["Fallback"]],
      Quiet[Check[assemble[record], $Failed]], assemble[record]];
    If[entry === $Failed,
      fallbacks++;
      entry = Together[Total[
        blockEquationDeferredTermExpression /@ record["Terms"]]]];
    values[record["Target"]] = entry,
    {record, records}];

  <|"Status" -> "OK", "Values" -> values,
    "ZeroEntries" -> zeroEntries, "UntouchedEntries" -> untouchedEntries,
    "Fallbacks" -> fallbacks,
    "AlgebraicEntries" -> algebraicEntries,
    "Statistics" -> <|"InternedOperands" -> Length[pool],
      "InternSeconds" -> internSeconds,
      "ExpandSeconds" -> expandSeconds,
      "CancelSeconds" -> cancelSeconds,
      "AlgebraicCanonicalizeSeconds" -> algebraicSeconds,
      "MaterializeSeconds" -> N[AbsoluteTime[] - started]|>|>
];

blockEquationDeferredMaterialize[___] := <|"Status" -> "InvalidInput"|>;

(* ---- driver entry point --------------------------------------------- *)

(* The forcing bbar of block (k, j) as the dense matrix pair the strip
   solvers consume, built through the deferred route.  Returns the
   preparation, the census and the materialized forcing so the caller can
   reuse the census as its zero-forcing decision (a nonzero image is an
   exact proof that the block is NOT zero-forced) instead of paying a
   second Together pass over every entry. *)
Options[blockEquationDeferredForcing] = {
  "CensusTriples" -> Automatic, "Cancel" -> True, "Fallback" -> True,
  "CanonicalizeUntouched" -> True};

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
     "CanonicalizeUntouched" -> OptionValue["CanonicalizeUntouched"]];
   If[Lookup[materialized, "Status", None] =!= "OK",
     Return[materialized]];
   dimensions = preparation["Dimensions"];
   values = materialized["Values"];
   forcing = Table[values[{mu, i, jj}],
     {mu, dimensions[[1]]}, {i, dimensions[[2]]}, {jj, dimensions[[3]]}];
   <|"Status" -> "OK", "Forcing" -> forcing,
     "Preparation" -> KeyDrop[preparation, "Records"],
     "Census" -> census, "Materialization" -> KeyDrop[materialized, "Values"],
     "ZeroForcingCandidateQ" -> ! TrueQ[census["NonzeroProvedQ"]]|>
];

blockEquationDeferredForcing[___] := <|"Status" -> "InvalidInput"|>;

End[];
