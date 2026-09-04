(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticStripProviders.wl -- part 6 of 8 of the
   multiquadratic strip solver (split from MultiquadraticStripSolve.wl in
   round 4, 2026-09-02, pure moves): the direct coefficient providers: modular grade arithmetic, the
   evaluator, split-branch and quotient-grade entries, sparse evaluation
   plans, the native sparse/deferred/row backends, the chart-forcing
   provider, preflight, provider channels, and the conservative and bundle
   gauge denominators.
   Loads after the preceding parts (Private/LoadOrder.wl); the schema, the
   globals and the shared utilities are in MultiquadraticStripSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripProviderValidQ,
  multiquadraticStripProviderHotValidQ,
  multiquadraticStripProviderEvaluationValidQ,
  multiquadraticStripProviderPreflight,
  multiquadraticStripCompiledProviderChannels,
  multiquadraticStripModularInverse,
  multiquadraticStripModularGradePower,
  multiquadraticStripModularGradeEvaluate,
  $multiquadraticStripGradeEvaluateTag,
  multiquadraticStripEntryActiveRoots,
  multiquadraticStripRootMaskActiveRoots,
  multiquadraticStripBundleRootEmbedding,
  multiquadraticStripBundleLocalData,
  multiquadraticStripQuotientGradeEntry,
  multiquadraticStripSplitBranchEntry,
  $multiquadraticStripSplitRootSymbols,
  $multiquadraticStripSplitSparseCompilation,
  $multiquadraticStripSplitSparsePlanCache,
  $multiquadraticStripSplitSparseExactPlanCache,
  multiquadraticStripSplitSparseEvaluationPlan,
  multiquadraticStripSplitSparseEvaluationPlanValidQ,
  multiquadraticStripSplitSparseEvaluationPlanHotValidQ,
  multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ,
  multiquadraticStripSplitSparsePlannedEntry,
  multiquadraticStripNativeSparseBinary,
  multiquadraticStripNativeSparseWritePlan,
  multiquadraticStripNativeSparseEvaluateBatch,
  multiquadraticStripNativeDeferredBinary,
  multiquadraticStripNativeDeferredWriteRequest,
  multiquadraticStripNativeDeferredReadOutput,
  multiquadraticStripNativeDeferredEvaluateBatch,
  multiquadraticStripAttachDeferredPreparation,
  multiquadraticStripChartForcingProvider,
  multiquadraticStripChartForcingProviderValidQ,
  multiquadraticStripChartForcingProviderHotValidQ,
  multiquadraticStripChartForcingPreflight,
  multiquadraticStripChartForcingFoldTensor,
  multiquadraticStripNativeDeferredChartEvaluateBatch,
  multiquadraticStripNativePreflightBatch,
  multiquadraticStripNativeRowBinary,
  multiquadraticStripNativeRowAssembleBatch,
  multiquadraticStripPointResult,
  multiquadraticStripPlannedProviderChannels,
  multiquadraticStripDirectProvider,
  multiquadraticStripProviderChannels,
  multiquadraticStripBundleGaugeDenominator,
  multiquadraticStripBundleExactChannelTask,
  multiquadraticStripBundleExactChannels,
  multiquadraticStripBundleRefinedGaugeDenominator,
  multiquadraticStripBundleProviderChannels,
  multiquadraticStripConservativeGaugeDenominator
];

(* ------------------------------------------------------------------ *)
(* DIRECT COEFFICIENT PROVIDERS (2026-08-26, round-2 item 9)            *)
(* ------------------------------------------------------------------ *)

(* THE MEASUREMENT THAT DRIVES THIS.  Preparation of the real CF300
   (12,9) block is 1439.7 s, of which 1400.5 s (97.3%) is
   multiquadraticFieldDecompose of the whole forcing into global
   characteristic-zero channels.  The modular solve does not need those
   FUNCTIONS: it needs their VALUES at finite-field points.  Codex's
   bounded benchmark on the same frozen block
   (Exchange/Codex/2026-08-25/09_direct_branch_benchmark.wls) evaluated
   the original forcing directly on
   every Galois branch at one point and reproduced all 32 frozen exact
   channel projections; the first entry cost 2.727 s to decompose
   exactly and 0.0745 s to evaluate on all four branches.

   TWO PROVIDERS, both exact statements about F_p:

   SPLIT-BRANCH.  At a point where every declared radicand is a quadratic
   residue, each root has a value r_i in F_p and the 2^d sign branches
   sigma give

       f(sigma_1 r_1, ..., sigma_d r_d) = Sum_S c_S chi_S(sigma) r_S.

   A Walsh-Hadamard transform over the branches recovers c_S r_S, and
   division by the nonzero r_S recovers c_S -- which is exactly
   multiquadraticProjectSignChangeImages in the algebra module.  Simple,
   independently checkable, and validated against the frozen block.  It
   needs a split point.

   QUOTIENT-GRADE.  Evaluate the expression directly in

       F_p[r_1, ..., r_d] / (r_i^2 - Delta_i)

   on grade vectors, inverting denominators with the recursive tower
   norm.  Valid at NONSPLIT points too -- no one-in-2^d residue
   restriction, which is what matters at rank three -- and it is the
   better production provider.  A zero norm is a typed rejection of the
   POINT, never a zero value.

   Both are cross-checked at split points: the split-branch provider is
   the independent oracle for the quotient-grade one, exactly as Pro
   prescribes.  Neither reconstructs a global channel function, and
   neither needs one.

   PER-ENTRY ACTIVE-ROOT REDUCTION (Pro item 1, which Pro ranks first).
   Most scalar entries of a rank-3 bundle use fewer than three
   generators.  The active subset is determined once per entry, the
   evaluation runs in that local subfield of rank d' <= d, and the local
   channels are lifted to the declared global grade order with
   multiquadraticLiftLocalChannels.  A rank-one scalar does not pay
   rank-three costs because the family declares three roots. *)

(* ---- modular grade arithmetic ------------------------------------- *)

(* The recursive quadratic-tower inverse of the exact route, in F_p.
   Same recursion, same acceptance: a zero norm at any level means the
   element is a zero divisor there, and the caller must reject the POINT
   rather than record a value. *)
multiquadraticStripModularInverse[a_List, deltas_List, prime_Integer] := Module[
  {rank = Length[deltas], half, u, v, subDeltas, uSquare, vSquare, norm,
   normInverse, low, high},
  If[! IntegerQ[prime] || prime <= 1 || Length[a] =!= 2^rank ||
      ! VectorQ[a, IntegerQ], Return[$Failed]];
  If[rank === 0,
    Return[If[Mod[First[a], prime] === 0, $Failed,
      {PowerMod[First[a], -1, prime]}]]];
  half = 2^(rank - 1);
  u = Take[a, half];
  v = Drop[a, half];
  subDeltas = Most[deltas];
  If[AllTrue[v, Mod[#1, prime] === 0 &],
    Return[Module[{inner = multiquadraticStripModularInverse[u, subDeltas,
        prime]},
      If[inner === $Failed, $Failed,
        Join[inner, ConstantArray[0, half]]]]]];
  uSquare = multiquadraticMultiply[u, u, subDeltas, prime];
  vSquare = multiquadraticMultiply[v, v, subDeltas, prime];
  If[! ListQ[uSquare] || ! ListQ[vSquare], Return[$Failed]];
  norm = Mod[uSquare - Last[deltas] vSquare, prime];
  normInverse = multiquadraticStripModularInverse[norm, subDeltas, prime];
  If[normInverse === $Failed, Return[$Failed]];
  low = multiquadraticMultiply[u, normInverse, subDeltas, prime];
  high = multiquadraticMultiply[v, normInverse, subDeltas, prime];
  If[! ListQ[low] || ! ListQ[high], Return[$Failed]];
  Join[Mod[low, prime], Mod[-high, prime]]
];
multiquadraticStripModularInverse[___] := $Failed;

multiquadraticStripModularGradePower[a_List, exponent_Integer, deltas_List,
    prime_Integer] := Module[{result, base = a, n = Abs[exponent], inverse,
   width = Length[a]},
  If[exponent === 0, Return[PadRight[{Mod[1, prime]}, width, 0]]];
  If[exponent < 0,
    inverse = multiquadraticStripModularInverse[a, deltas, prime];
    If[inverse === $Failed, Return[$Failed]];
    base = inverse];
  result = PadRight[{Mod[1, prime]}, width, 0];
  While[n > 0,
    If[BitAnd[n, 1] === 1,
      result = multiquadraticMultiply[result, base, deltas, prime];
      If[! ListQ[result], Return[$Failed]]];
    n = BitShiftRight[n, 1];
    If[n > 0,
      base = multiquadraticMultiply[base, base, deltas, prime];
      If[! ListQ[base], Return[$Failed]]]];
  result
];

(* ---- the evaluator ------------------------------------------------- *)

(* ONE recursive modular evaluator over the RAW expression tree.  It
   never forms a symbolic intermediate: every node is reduced to a grade
   vector over F_p as it is met, so no Together, no Expand and no
   characteristic-zero rational growth.

   Both providers are this evaluator with a different radical rule --
   split-branch binds each root to its branch VALUE (a rank-0
   evaluation), quotient-grade binds it to the grade UNIT VECTOR -- which
   is why they cannot disagree for a structural reason, and a
   disagreement between them is always a real defect.

   Every refusal is typed and separate: a zero denominator, a zero norm,
   an undeclared radical and an unsupported node are four different
   statements and none of them is a zero value. *)
$multiquadraticStripGradeEvaluateTag = "MultiquadraticStripGradeEvaluate";

(* radicalRules: a list of {rootSquare, gradeValue} pairs.  The radicand
   is matched up to a POSITIVE RATIONAL SQUARE scale by
   transportChartRootBranchScale -- the same rule the exact branch
   substitution uses, because the kernel pulls rational square factors
   out of a radical (Sqrt[4 N] -> 2 Sqrt[N]). *)
multiquadraticStripModularGradeEvaluate[expression_, scalarRules_Association,
    radicalRules_List, deltas_List, prime_Integer] := Catch[Module[
  {width = 2^Length[deltas], evaluate, embed, radicalValue, scaleImage},
  embed[value_Integer] := PadRight[{Mod[value, prime]}, width, 0];
  scaleImage[scale_] := Mod[Numerator[scale] PowerMod[
    Mod[Denominator[scale], prime], -1, prime], prime];
  (* Sqrt[base] as a grade vector, or Missing when the base is not a
     declared square class *)
  radicalValue[base_] := radicalValue[base] = Module[{index, scale},
    index = SelectFirst[Range[Length[radicalRules]],
      transportChartRootBranchScale[base, radicalRules[[#1, 1]]] =!= None &,
      Missing["NoRadical"]];
    If[MissingQ[index], Return[Missing["NoRadical"]]];
    scale = transportChartRootBranchScale[base, radicalRules[[index, 1]]];
    If[Mod[Denominator[scale], prime] === 0,
      Throw[<|"Status" -> "BadPrimeForRadicalScale", "Scale" -> scale|>,
        $multiquadraticStripGradeEvaluateTag]];
    Mod[scaleImage[scale] radicalRules[[index, 2]], prime]];
  evaluate[node_] := Which[
    IntegerQ[node], embed[node],
    Head[node] === Rational,
      Module[{denominator = Mod[Denominator[node], prime]},
        If[denominator === 0,
          Throw[<|"Status" -> "BadPrimeForRationalCoefficient",
            "Denominator" -> Denominator[node]|>,
            $multiquadraticStripGradeEvaluateTag]];
        embed[Mod[Numerator[node] PowerMod[denominator, -1, prime], prime]]],
    MatchQ[node, _Symbol],
      If[KeyExistsQ[scalarRules, node], embed[scalarRules[node]],
        Throw[<|"Status" -> "UnassignedSymbol", "Symbol" -> HoldForm[node]|>,
          $multiquadraticStripGradeEvaluateTag]],
    Head[node] === Plus,
      Fold[Mod[#1 + evaluate[#2], prime] &, ConstantArray[0, width],
        List @@ node],
    Head[node] === Times,
      Fold[Module[{product = multiquadraticMultiply[#1, evaluate[#2], deltas,
          prime]},
        If[! ListQ[product],
          Throw[<|"Status" -> "GradeProductFailed"|>,
            $multiquadraticStripGradeEvaluateTag]];
        Mod[product, prime]] &, embed[1], List @@ node],
    (* a HALF power: Power[b, m/2] with m odd is (Sqrt[b])^m *)
    MatchQ[node, Power[_, _Rational]] && Denominator[Last[node]] === 2,
      Module[{root = radicalValue[First[node]], value},
        If[MissingQ[root],
          Throw[<|"Status" -> "UndeclaredRadical",
            "RadicalBase" -> HoldForm[First[node]]|>,
            $multiquadraticStripGradeEvaluateTag]];
        value = multiquadraticStripModularGradePower[root,
          Numerator[Last[node]], deltas, prime];
        If[value === $Failed,
          Throw[<|"Status" -> "SingularPoint",
            "Reason" -> "ZeroRadicalValueOrZeroNorm"|>,
            $multiquadraticStripGradeEvaluateTag]];
        value],
    MatchQ[node, Power[_, _Integer]],
      Module[{value = multiquadraticStripModularGradePower[
          evaluate[First[node]], Last[node], deltas, prime]},
        If[value === $Failed,
          Throw[<|"Status" -> "SingularPoint",
            "Reason" -> "ZeroNormOrZeroDenominator"|>,
            $multiquadraticStripGradeEvaluateTag]];
        value],
    MatchQ[node, Power[_, _Rational]],
      Throw[<|"Status" -> "UnsupportedFractionalPower",
        "Exponent" -> Last[node]|>, $multiquadraticStripGradeEvaluateTag],
    True,
      Throw[<|"Status" -> "UnsupportedExpression",
        "Head" -> ToString[Head[node]]|>,
        $multiquadraticStripGradeEvaluateTag]];
  <|"Status" -> "OK", "Channels" -> evaluate[expression]|>],
  $multiquadraticStripGradeEvaluateTag];

(* ---- per-entry active root subset --------------------------------- *)

(* Which DECLARED roots actually occur in one scalar entry.  The same
   square-class matcher the census and the branch substitution use, so an
   entry that carries Sqrt[4 delta_2] is reported as using root 2. *)
multiquadraticStripEntryActiveRoots[entry_, roots_List] := Module[{bases},
  bases = transportChartRadicalBases[entry];
  If[bases === {}, Return[{}]];
  Sort[DeleteDuplicates[Flatten[Table[
    Select[Range[Length[roots]],
      transportChartRootBranchScale[base,
        squareRootRecordRadicand[roots[[#1]]]] =!= None &],
    {base, bases}]]]]
];

(* Convert validated bit-mask metadata to the ordered local root subset.
   This is deliberately a tiny integer operation: operand masks were already
   recomputed by blockEquationDeferredBundleValidate, so the direct provider
   must not repeat a symbolic radical census for every interned operand. *)
multiquadraticStripRootMaskActiveRoots[mask_Integer, rank_Integer] /;
    rank >= 0 && 0 <= mask < 2^rank :=
  Select[Range[rank], BitGet[mask, #1 - 1] === 1 &];
multiquadraticStripRootMaskActiveRoots[___] := $Failed;

(* Embed the bundle's ordered square-root generators into the solver's ordered
   square-root generators.  Bundle compilation deliberately prunes generators
   absent from the deferred forcing, while E and C may still require them;
   equality of the two lists is therefore too strong.  Exact generator and
   quadratic-radicand matching preserves the declared sign, and unique
   positions give the mask relabelling below. *)
multiquadraticStripBundleRootEmbedding[bundleRoots_List, roots_List] :=
 Module[{positions},
  positions = Table[Module[{matches = Select[Range[Length[roots]],
       TrueQ[Quiet[Together[
           squareRootRecordRadicand[roots[[#1]]] -
             squareRootRecordRadicand[bundleRoot]]] === 0] &&
         TrueQ[Quiet[Together[
           squareRootRecordExpression[roots[[#1]]] -
             squareRootRecordExpression[bundleRoot]]] === 0] &]},
      If[Length[matches] === 1, First[matches], $Failed]],
    {bundleRoot, bundleRoots}];
  If[VectorQ[positions, IntegerQ] && DuplicateFreeQ[positions], positions,
    $Failed]
];
multiquadraticStripBundleRootEmbedding[___] := $Failed;

(* Immutable, derived hot-path data for one deferred bundle.  Operand masks
   come from the validator-checked table.  Coefficients have no bundle
   mask field, so canonicalize composite radicals and compute their masks once
   when the provider is constructed.  The full provider validator recomputes
   this record; hot point loops only read the derived copy. *)
multiquadraticStripBundleLocalData[bundle_Association, roots_List,
    variables : {_Symbol, _Symbol}] := Catch[Module[
  {rank = Length[roots], bundlePresentation, bundlePresentationRoots,
   bundleGeneratorIndices, bundleRoots, bundleRank,
   bundleRootEmbedding, squares, operands, expressions, localMasks,
   localActiveRoots, masks, activeRoots, coefficientData, tag},
  tag = Unique["MultiquadraticBundleLocalDataFailure"];
  bundlePresentation = masterTransportCoefficientPresentationData[
    Lookup[bundle, "CoefficientPresentation",
      Missing["NoCoefficientPresentation"]], variables];
  bundlePresentationRoots =
    coefficientPresentationSquareRootsInVariables[
      bundlePresentation, variables];
  bundleGeneratorIndices = Lookup[bundle,
    "SquareRootGeneratorIndices", $Failed];
  If[Lookup[bundlePresentation, "Status", None] =!= "OK" ||
      ! ListQ[bundlePresentationRoots] ||
      ! VectorQ[bundleGeneratorIndices, IntegerQ] ||
      ! ContainsOnly[bundleGeneratorIndices,
        Range[Length[bundlePresentationRoots]]] ||
      bundleGeneratorIndices =!=
        Sort[DeleteDuplicates[bundleGeneratorIndices]],
    Throw[multiquadraticStripFailure[
      "DeferredBundleCoefficientPresentationMismatch"], tag]];
  bundleRoots = bundlePresentationRoots[[bundleGeneratorIndices]];
  bundleRootEmbedding = multiquadraticStripBundleRootEmbedding[
    bundleRoots, roots];
  If[bundleRootEmbedding === $Failed,
    Throw[multiquadraticStripFailure[
      "DeferredBundleRootOrderMismatch"], tag]];
  bundleRank = Length[bundleRoots];
  squares = Together /@ (squareRootRecordRadicand /@ roots);
  operands = Lookup[bundle, "OperandTable", {}];
  expressions = Map[Function[operand,
    operand["Numerator"]/Times @@
      (Power[First[#1], Last[#1]] & /@
        operand["DenominatorFactors"])], operands];
  localMasks = Lookup[operands, "RootMask", $Failed];
  localActiveRoots =
    multiquadraticStripRootMaskActiveRoots[#1, bundleRank] & /@ localMasks;
  If[MemberQ[localActiveRoots, $Failed],
    Throw[multiquadraticStripFailure[
      "InvalidBundleOperandRootMask"], tag]];
  activeRoots = Map[Function[indices, bundleRootEmbedding[[indices]]],
    localActiveRoots];
  masks = Total[2^(#1 - 1)] & /@ activeRoots;
  coefficientData = Map[Function[job,
      Map[Function[term, Module[{canonical, expression, mask, active},
        canonical =
          blockEquationDeferredCanonicalizeWithSquareRootGenerators[
            First[term], bundleRoots, variables];
        If[Lookup[canonical, "Status", None] =!= "OK",
          Throw[Join[multiquadraticStripFailure[
            "BundleCoefficientCanonicalizationFailed"],
            <|"Detail" -> canonical|>], tag]];
        expression = canonical["Expression"];
        mask = blockEquationDeferredFactorRootMask[expression, squares];
        active = multiquadraticStripRootMaskActiveRoots[mask, rank];
        If[mask === $Failed || active === $Failed,
          Throw[multiquadraticStripFailure[
            "InvalidBundleCoefficientRootMask"], tag]];
        <|"Expression" -> expression, "RootMask" -> mask,
          "ActiveRoots" -> active|>]], Lookup[job, "Terms", {}]]],
    Lookup[bundle, "Jobs", {}]];
  <|"Status" -> "MultiquadraticBundleLocalDataV1",
    "OperandExpressions" -> expressions,
    "OperandRootMasks" -> masks,
    "OperandActiveRoots" -> activeRoots,
    "CoefficientExpressions" -> Map[Lookup[#1, "Expression"] &,
      coefficientData, {2}],
    "CoefficientRootMasks" -> Map[Lookup[#1, "RootMask"] &,
      coefficientData, {2}],
    "CoefficientActiveRoots" -> Map[Lookup[#1, "ActiveRoots"] &,
      coefficientData, {2}]|>
], tag, #1 &];
multiquadraticStripBundleLocalData[___] :=
  multiquadraticStripFailure["InvalidBundleLocalDataArguments"];

(* ---- the two providers, per entry ---------------------------------- *)

(* Both return a GLOBAL grade vector of width 2^rank: the local channels
   of the entry's active subfield, lifted through
   multiquadraticLiftLocalChannels.  Both take the root VALUES mod p of
   the declared roots (split-branch needs them to be genuine square
   roots; quotient-grade uses only the squares). *)

multiquadraticStripQuotientGradeEntry[entry_, roots_List, activeIndices_List,
    scalarRules_Association, deltaValues_List, prime_Integer] := Module[
  {localDeltas, radicalRules, evaluated, lifted, rank = Length[roots]},
  localDeltas = deltaValues[[activeIndices]];
  (* local grade unit vector of root k: mask 2^(k-1), index mask + 1 *)
  radicalRules = Table[
    {squareRootRecordRadicand[roots[[activeIndices[[k]]]]],
     UnitVector[2^Length[activeIndices], 2^(k - 1) + 1]},
    {k, Length[activeIndices]}];
  evaluated = multiquadraticStripModularGradeEvaluate[entry, scalarRules,
    radicalRules, localDeltas, prime];
  If[Lookup[evaluated, "Status", None] =!= "OK", Return[evaluated]];
  lifted = multiquadraticLiftLocalChannels[evaluated["Channels"],
    activeIndices, rank];
  If[lifted === $Failed,
    Return[<|"Status" -> "LocalChannelLiftFailed",
      "ActiveRoots" -> activeIndices|>]];
  <|"Status" -> "OK", "Channels" -> Mod[lifted, prime],
    "ActiveRoots" -> activeIndices, "LocalRank" -> Length[activeIndices]|>
];

(* Stable formal roots for the sparse branch compiler.  They are implementation
   variables, never part of provider coefficient data, and the compile
   cache is reset on every load of this source. *)
$multiquadraticStripSplitRootSymbols = Table[
  Unique["FeynFacet`Private`mqSplitRoot$"],
  {$multiquadraticStripMaximumRootCount}];
$multiquadraticStripSplitSparseCompilation = True;
$multiquadraticStripSplitSparsePlanCache = <||>;
$multiquadraticStripSplitSparseExactPlanCache = <||>;

(* THE SPLIT FAST PATH.  Applying root branches and point rules directly is
   cheap for a small expression but still walks the entire raw tree once per
   sign and per point.  A rank-r entry sampled at P points therefore paid
   P 2^r full-tree substitutions.  The screen subsystem already has the exact
   representation we need: replace the active radicals by formal roots once,
   compile the resulting rational function to sparse modular monomials once
   per prime, then evaluate each sign by packed dot products.  Its cache is
   expression/root/variable/prime data exact and byte bounded.

   Compilation is only an optimization.  Any compile or evaluation refusal
   takes the historical substitution path, and that path retains the recursive
   grade evaluator as its typed diagnostic fallback.  Thus cache availability
   can change time and telemetry, never the accepted coefficient channels. *)
multiquadraticStripSplitBranchEntry[entry_, roots_List, activeIndices_List,
    scalarRules_Association, deltaValues_List, rootValues_List,
    prime_Integer, suppliedCompiled_: Automatic] := Module[
  {localRank = Length[activeIndices], localRoots, branchValues, mask, signs,
    radicalRules, evaluated, channels, lifted, rank = Length[roots],
    pointRules, localRootRecords, fast, method = "SparseRootPlaceholder",
    localRootSymbols, scalarVariables, compiled, compileSeconds = 0.,
    evaluationSeconds = 0., fallbackSeconds = 0., cacheHitsBefore,
    cacheHit = False, values, powerTables, pair,
    substitutionBranches, fallbackMethod = "Substitution",
    plannedQ = suppliedCompiled =!= Automatic},
  localRoots = rootValues[[activeIndices]];
  If[MemberQ[Mod[localRoots, prime], 0],
    Return[<|"Status" -> "SingularPoint", "Reason" -> "ZeroRootValue"|>]];
  pointRules = Normal[scalarRules];
  localRootRecords = roots[[activeIndices]];
  localRootSymbols = Take[$multiquadraticStripSplitRootSymbols, localRank];
  scalarVariables = Keys[scalarRules];
  (* The packed Wolfram sparse dot product is a 31-bit compatibility path:
     products of 61-bit residues do not stay in signed machine integers.
     Wide production normally supplies native FLINT leaf channels and never
     enters here; an explicit-wide or exceptional native fallback uses the
     exact substitution evaluator instead. *)
  If[prime < 2^31,
    If[plannedQ,
      compiled = suppliedCompiled,
     If[TrueQ[$multiquadraticStripSplitSparseCompilation],
      cacheHitsBefore = Lookup[$multiquadraticStripScreenCompileStatistics,
        "Hits", 0];
      {compileSeconds, compiled} = AbsoluteTiming[
        multiquadraticStripScreenCompileCached[entry, localRootRecords,
          localRootSymbols, scalarVariables, prime]];
      cacheHit = Lookup[$multiquadraticStripScreenCompileStatistics, "Hits", 0] >
        cacheHitsBefore,
      compiled = $Failed]],
    compiled = $Failed];
  If[AssociationQ[compiled],
    {evaluationSeconds, branchValues} = AbsoluteTiming[Catch[
      Quiet[Check[Table[
      signs = Table[If[BitGet[mask, k - 1] === 1, -1, 1],
        {k, localRank}];
      values = Join[Values[scalarRules], Mod[signs localRoots, prime]];
      powerTables = multiquadraticStripScreenPowerTables[values,
        compiled["MaximumExponents"], prime];
      pair = multiquadraticStripScreenEvaluateRationalValue[compiled,
        powerTables, prime];
      If[pair === $Failed, Throw[$Failed,
        "MultiquadraticSplitCompiledEvaluation"]];
      pair, {mask, 0, 2^localRank - 1}], $Failed]],
      "MultiquadraticSplitCompiledEvaluation", Function[{value, tag}, value]]],
    branchValues = $Failed];
  substitutionBranches[] := Module[{result},
    result = Table[
      signs = Table[If[BitGet[mask, k - 1] === 1, -1, 1], {k, localRank}];
      fast = Quiet[Check[
        multiquadraticStripModRational[
          transportChartApplyRootBranches[entry, localRootRecords,
            Mod[signs localRoots, prime]] /. pointRules, prime], $Failed]];
      If[IntegerQ[fast], fast,
        fallbackMethod = "GradeEvaluator";
        radicalRules = Table[
          {squareRootRecordRadicand[roots[[activeIndices[[k]]]]],
            {Mod[signs[[k]] localRoots[[k]], prime]}},
          {k, localRank}];
        evaluated = multiquadraticStripModularGradeEvaluate[entry, scalarRules,
          radicalRules, {}, prime];
        If[Lookup[evaluated, "Status", None] =!= "OK",
          Return[evaluated, Module]];
        First[evaluated["Channels"]]],
      {mask, 0, 2^localRank - 1}];
    result];
  If[! VectorQ[branchValues, IntegerQ],
    {fallbackSeconds, branchValues} = AbsoluteTiming[substitutionBranches[]];
    method = fallbackMethod;
    If[! VectorQ[branchValues, IntegerQ], Return[branchValues]]];
  (* Walsh-Hadamard back to channels, then divide by the evaluated r_S *)
  channels = multiquadraticProjectSignChangeImages[branchValues,
    Mod[localRoots, prime], prime];
  If[channels === $Failed,
    Return[<|"Status" -> "BranchProjectionFailed"|>]];
  lifted = multiquadraticLiftLocalChannels[channels, activeIndices, rank];
  If[lifted === $Failed,
    Return[<|"Status" -> "LocalChannelLiftFailed",
      "ActiveRoots" -> activeIndices|>]];
  <|"Status" -> "OK", "Channels" -> Mod[lifted, prime],
    "ActiveRoots" -> activeIndices, "LocalRank" -> localRank,
    "Method" -> method, "BranchValues" -> branchValues,
    "SparsePlanUsed" -> plannedQ,
    "SparseCompileCacheHit" -> cacheHit,
    "SparseCompileSeconds" -> compileSeconds,
    "SparseEvaluationSeconds" -> evaluationSeconds,
    "SubstitutionFallbackSeconds" -> fallbackSeconds|>
];

(* ---- the provider object ------------------------------------------ *)

(* THE PROVIDER INTERFACE (round-2 item 10).  A provider answers exactly
   one question: at (point, regulator image, prime), what are the
   coefficient values the row assembler needs?  Three implementations
   answer it -- the compiled-channel one that already existed, and the
   two direct ones here -- and ONE multiquadraticStripAssemblePointRows
   turns any of those answers into rows.  That is what removes the
   duplication Codex 4.1 names, and it is what makes the split-branch
   route an independent DIFFERENTIAL TEST of the compiled route instead
   of a fourth copy of the same loop.

   The per-entry active-root census, the gauge-denominator log
   derivatives and the root log derivatives are symbolic objects computed
   ONCE, when the provider is built.  They are the only symbolic work the
   direct route does; the global exact channel decomposition -- 97.3% of
   preparation on the real block -- is not done at all. *)
Options[multiquadraticStripDirectProvider] = {
  "Kind" -> "QuotientGrade",
  "OneForms" -> {},
  "GaugeDenominator" -> 1,
  "DeferredBundle" -> Automatic
};

multiquadraticStripDirectProvider[record_Association, roots_List,
    opts : OptionsPattern[]] := Module[
  {gate, kind, variables, epsilon, strip, entries, activeRoots, oneForms,
   gaugeDenominator, gaugeLog, rootLog, oneFormActive, dimensions,
   coefficientData, result, deferredBundle,
   bundleValidation, bundlePresentation, bundlePresentationRoots,
   bundleGeneratorIndices, bundleRootEmbedding,
   bundleLocalData = Missing["NoDeferredBundle"],
   startTime = AbsoluteTime[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripDirectProvider]]]];
  If[AssociationQ[gate], Return[gate]];
  kind = OptionValue["Kind"];
  If[! MemberQ[{"QuotientGrade", "SplitBranch"}, kind],
    Return[multiquadraticStripFailure["InvalidProviderKind",
      <|"Kind" -> kind|>]]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  deferredBundle = Replace[OptionValue["DeferredBundle"], Automatic :>
    Lookup[record, "DeferredBundle", Missing["NoDeferredBundle"]]];
  If[AssociationQ[deferredBundle],
    bundleValidation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
      Return[multiquadraticStripFailure["InvalidDeferredBundle",
        <|"Detail" -> bundleValidation|>]]];
    bundlePresentation = masterTransportCoefficientPresentationData[
      Lookup[deferredBundle, "CoefficientPresentation",
        Missing["NoCoefficientPresentation"]], variables];
    bundlePresentationRoots =
      coefficientPresentationSquareRootsInVariables[
        bundlePresentation, variables];
    bundleGeneratorIndices = Lookup[deferredBundle,
      "SquareRootGeneratorIndices", $Failed];
    If[Lookup[bundlePresentation, "Status", None] =!= "OK" ||
        ! ListQ[bundlePresentationRoots] ||
        ! VectorQ[bundleGeneratorIndices, IntegerQ] ||
        ! ContainsOnly[bundleGeneratorIndices,
          Range[Length[bundlePresentationRoots]]] ||
        bundleGeneratorIndices =!=
          Sort[DeleteDuplicates[bundleGeneratorIndices]],
      Return[multiquadraticStripFailure[
        "DeferredBundleCoefficientPresentationMismatch"]]];
    bundleRootEmbedding = multiquadraticStripBundleRootEmbedding[
      bundlePresentationRoots[[bundleGeneratorIndices]], roots];
    If[bundleRootEmbedding === $Failed,
      Return[multiquadraticStripFailure[
        "DeferredBundleRootOrderMismatch"]]];
    bundleLocalData = multiquadraticStripBundleLocalData[deferredBundle,
      roots, variables];
    If[Lookup[bundleLocalData, "Status", None] =!=
        "MultiquadraticBundleLocalDataV1",
      Return[bundleLocalData]]];
  dimensions = If[AssociationQ[deferredBundle],
    Rest[deferredBundle["Dimensions"]],
    Quiet[Check[Dimensions[strip[[3, 1]]], $Failed]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      (! AssociationQ[deferredBundle] &&
        Dimensions[strip[[3]]] =!= Prepend[dimensions, 2]) ||
      Dimensions[strip[[1]]] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[strip[[2]]] =!= {2, dimensions[[2]], dimensions[[2]]},
    Return[multiquadraticStripFailure["InvalidStripDimensions"]]];
  oneForms = OptionValue["OneForms"];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["OneFormBasisFailed"]]];
  gaugeDenominator = Together[OptionValue["GaugeDenominator"]];
  If[TrueQ[gaugeDenominator === 0],
    Return[multiquadraticStripFailure["ZeroGaugeDenominator"]]];
  coefficientData = multiquadraticStripCoefficientData[
    variables, epsilon, roots, dimensions, oneForms, gaugeDenominator];
  If[coefficientData === $Failed,
    Return[multiquadraticStripFailure[
      "CoefficientDataConstructionFailed"]]];
  entries = If[AssociationQ[deferredBundle],
    <|"E" -> strip[[1]], "C" -> strip[[2]]|>,
    <|"E" -> strip[[1]], "C" -> strip[[2]], "BBar" -> strip[[3]]|>];
  activeRoots = Map[multiquadraticStripEntryActiveRoots[#1, roots] &,
    entries, {4}];
  oneFormActive = Map[multiquadraticStripEntryActiveRoots[#1, roots] &,
    oneForms, {2}];
  (* symbolic ONCE: d_mu Q / Q and d_mu Delta_a / Delta_a.  Both are
     small rational objects, and both are what the row assembler needs to
     differentiate the gauge basis without differentiating anything at a
     point. *)
  gaugeLog = Table[Together[D[gaugeDenominator, variables[[mu]]]/
    gaugeDenominator], {mu, 2}];
  rootLog = Table[Together[D[squareRootRecordRadicand[roots[[a]]],
      variables[[mu]]]/squareRootRecordRadicand[roots[[a]]]],
    {a, Length[roots]}, {mu, 2}];
  result = <|"Status" -> "MultiquadraticDirectProviderV1",
    "Kind" -> kind, "Roots" -> roots, "RootCount" -> Length[roots],
    "GradeCount" -> 2^Length[roots],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "Entries" -> entries, "ActiveRoots" -> activeRoots,
    "DeferredBundle" -> If[AssociationQ[deferredBundle], deferredBundle,
      Missing["NoDeferredBundle"]],
    "BundleOperandExpressions" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["OperandExpressions"],
      Missing["NoDeferredBundle"]],
    "BundleOperandRootMasks" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["OperandRootMasks"], Missing["NoDeferredBundle"]],
    "BundleOperandActiveRoots" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["OperandActiveRoots"], Missing["NoDeferredBundle"]],
    "BundleCoefficientExpressions" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["CoefficientExpressions"],
      Missing["NoDeferredBundle"]],
    "BundleCoefficientRootMasks" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["CoefficientRootMasks"],
      Missing["NoDeferredBundle"]],
    "BundleCoefficientActiveRoots" -> If[AssociationQ[bundleLocalData],
      bundleLocalData["CoefficientActiveRoots"],
      Missing["NoDeferredBundle"]],
    "OneForms" -> oneForms, "OneFormActiveRoots" -> oneFormActive,
    "GaugeDenominator" -> gaugeDenominator,
    "GaugeLogDerivatives" -> gaugeLog, "RootLogDerivatives" -> rootLog,
    "CoefficientData" -> coefficientData,
    "ActiveRootHistogram" -> Counts[Flatten[
      Values[Map[Length, activeRoots, {4}]]]],
    "CensusSeconds" -> AbsoluteTime[] - startTime|>;
  result
];
multiquadraticStripDirectProvider[___] :=
  multiquadraticStripFailure["InvalidDirectProviderArguments"];

multiquadraticStripProviderValidQ[provider_Association] := Module[
  {kind, assembly, coefficientData, expectedProvider, bundle,
   bundleValidation, bundleLocalData, expectedActiveRoots,
   expectedOneFormActiveRoots, expectedGaugeLog, expectedRootLog},
  kind = Lookup[provider, "Kind", None];
  Which[
    Lookup[provider, "Status", None] ===
        "MultiquadraticCoefficientProviderV1" && kind === "CompiledChannel",
      assembly = Lookup[provider, "Assembly", $Failed];
      If[! multiquadraticStripCompiledValidQ[assembly], Return[False]];
      expectedProvider = multiquadraticStripCompiledProvider[assembly];
      TrueQ[provider === expectedProvider],
    Lookup[provider, "Status", None] === "MultiquadraticDirectProviderV1" &&
        MemberQ[{"SplitBranch", "QuotientGrade"}, kind],
      coefficientData = multiquadraticStripCoefficientData[
        provider["Variables"], provider["Regulator"], provider["Roots"],
        provider["Dimensions"], provider["OneForms"],
        provider["GaugeDenominator"]];
      If[coefficientData === $Failed, Return[False]];
      bundle = Lookup[provider, "DeferredBundle", None];
      If[AssociationQ[bundle],
        bundleValidation = blockEquationDeferredBundleValidate[bundle];
        If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
          Return[False]];
        bundleLocalData = multiquadraticStripBundleLocalData[bundle,
          provider["Roots"], provider["Variables"]];
        If[Lookup[bundleLocalData, "Status", None] =!=
              "MultiquadraticBundleLocalDataV1" ||
            KeyTake[provider, {"BundleOperandExpressions",
                "BundleOperandRootMasks", "BundleOperandActiveRoots",
                "BundleCoefficientExpressions",
                "BundleCoefficientRootMasks",
                "BundleCoefficientActiveRoots"}] =!= <|
              "BundleOperandExpressions" ->
                bundleLocalData["OperandExpressions"],
              "BundleOperandRootMasks" ->
                bundleLocalData["OperandRootMasks"],
              "BundleOperandActiveRoots" ->
                bundleLocalData["OperandActiveRoots"],
              "BundleCoefficientExpressions" ->
                bundleLocalData["CoefficientExpressions"],
              "BundleCoefficientRootMasks" ->
                bundleLocalData["CoefficientRootMasks"],
              "BundleCoefficientActiveRoots" ->
                bundleLocalData["CoefficientActiveRoots"]|>,
          Return[False]],
        If[! MissingQ[bundle], Return[False]]];
      expectedActiveRoots = Map[
        multiquadraticStripEntryActiveRoots[#1, provider["Roots"]] &,
        provider["Entries"], {4}];
      expectedOneFormActiveRoots = Map[
        multiquadraticStripEntryActiveRoots[#1, provider["Roots"]] &,
        provider["OneForms"], {2}];
      expectedGaugeLog = Table[Together[
        D[provider["GaugeDenominator"], provider["Variables"][[mu]]] /
          provider["GaugeDenominator"]], {mu, 2}];
      expectedRootLog = Table[Together[
        D[squareRootRecordRadicand[provider["Roots"][[a]]],
            provider["Variables"][[mu]]] /
          squareRootRecordRadicand[provider["Roots"][[a]]]],
        {a, Length[provider["Roots"]]}, {mu, 2}];
      TrueQ[provider["CoefficientData"] === coefficientData &&
        provider["RootCount"] === Length[provider["Roots"]] &&
        provider["GradeCount"] === 2^provider["RootCount"] &&
        provider["ActiveRoots"] === expectedActiveRoots &&
        provider["OneFormActiveRoots"] === expectedOneFormActiveRoots &&
        provider["GaugeLogDerivatives"] === expectedGaugeLog &&
        provider["RootLogDerivatives"] === expectedRootLog],
    True, False]
];
multiquadraticStripProviderValidQ[___] := False;

(* Hot loops check only shape and direct mathematical data.  Callers entering
   a sampling or plan-construction boundary run the full validator once; point
   preflights then reuse the already validated immutable provider value. *)
multiquadraticStripProviderHotValidQ[provider_Association] := Module[
  {kind = Lookup[provider, "Kind", None], status, rootCount, gradeCount,
   dimensions, bundle, assembly},
  status = Lookup[provider, "Status", None];
  rootCount = Lookup[provider, "RootCount", $Failed];
  gradeCount = Lookup[provider, "GradeCount", $Failed];
  dimensions = Lookup[provider, "Dimensions", $Failed];
  If[! IntegerQ[rootCount] || rootCount < 0 ||
      gradeCount =!= 2^rootCount ||
      ! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      ! AssociationQ[Lookup[provider, "CoefficientData", None]],
    Return[False]];
  Which[
    status === "MultiquadraticCoefficientProviderV1" &&
        kind === "CompiledChannel",
      assembly = Lookup[provider, "Assembly", $Failed];
      AssociationQ[assembly],
    status === "MultiquadraticDirectProviderV1" &&
        MemberQ[{"SplitBranch", "QuotientGrade"}, kind],
      If[! ListQ[Lookup[provider, "Roots", $Failed]] ||
          Length[provider["Roots"]] =!= rootCount,
        Return[False]];
      bundle = Lookup[provider, "DeferredBundle", None];
      AssociationQ[bundle] || MissingQ[bundle],
    True, False]
];
multiquadraticStripProviderHotValidQ[___] := False;

multiquadraticStripProviderEvaluationValidQ[provider_] :=
  multiquadraticStripProviderHotValidQ[provider];

(* A SplitBranch plan binds one provider and prime to UNIQUE
   (expression, active-root subset) leaves plus integer occurrence maps.
   Construction uses an in-memory bucket and exact SameQ collision resolution;
   hot points and later epsilon fibres reach leaves solely by integer position.
   Compilation failures retain the exact historical substitution/grade
   fallback. *)
multiquadraticStripSplitSparseEvaluationPlan[provider_Association,
    prime_Integer] := Module[
  {startTime = AbsoluteTime[], providerCacheData, cached, roots,
   scalarVariables,
   leaves = {}, buckets = <||>, register, entries, entryActive, entryMaps,
   registerAtLevel, oneFormMap, bundle, operandMap = {}, coefficientMap = {},
   operandTable = {}, structuredOperands = <||>, compileLeaf, compileSeconds,
   compiled, compileInvocationCount = 0, compiledLeafCount, plan,
   occurrenceCount, exactCached, exactLeaves,
   exactPlanCacheHit = False, exactCompileSeconds = 0., leafIndex},
  If[! multiquadraticStripProviderValidQ[provider] ||
      Lookup[provider, "Kind", None] =!= "SplitBranch" ||
      ! PrimeQ[prime] ||
      ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[multiquadraticStripFailure[
      "InvalidSplitSparseEvaluationPlanInput"]]];
  providerCacheData = KeyDrop[provider, "CensusSeconds"];
  cached = multiquadraticStripCacheLookup[
    $multiquadraticStripSplitSparsePlanCache,
    SameQ[Lookup[#1, "ProviderData", Missing[]], providerCacheData] &&
      Lookup[#1, "Prime", None] === prime &];
  If[AssociationQ[cached] &&
      multiquadraticStripSplitSparseEvaluationPlanHotValidQ[
        cached, provider, prime],
    Return[Join[cached, <|"PlanCacheHit" -> True,
      "BuildCompileInvocationCount" -> 0,
      "BuildSeconds" -> N[AbsoluteTime[] - startTime]|>]]];
  roots = provider["Roots"];
  scalarVariables = Join[provider["Variables"], {provider["Regulator"]}];
  exactCached = multiquadraticStripCacheLookup[
    $multiquadraticStripSplitSparseExactPlanCache,
    SameQ[Lookup[#1, "ProviderData", Missing[]], providerCacheData] &];
  If[AssociationQ[exactCached],
    leaves = exactCached["Leaves"];
    entryMaps = exactCached["OccurrenceMaps", "Entries"];
    oneFormMap = exactCached["OccurrenceMaps", "OneForms"];
    operandMap = exactCached["OccurrenceMaps", "BundleOperands"];
    coefficientMap = exactCached["OccurrenceMaps", "BundleCoefficients"];
    exactLeaves = exactCached["ExactLeaves"];
    exactPlanCacheHit = True,
    register[expression_, activeIndices_List] := Module[
      {bucketKey, candidates, index},
      bucketKey = HoldComplete[expression, activeIndices];
      candidates = Lookup[buckets, bucketKey, {}];
      index = SelectFirst[candidates,
        SameQ[leaves[[#1, "Expression"]], expression] &&
          SameQ[leaves[[#1, "ActiveRoots"]], activeIndices] &,
        Missing["NotFound"]];
      If[MissingQ[index],
        AppendTo[leaves, <|"Expression" -> expression,
          "ActiveRoots" -> activeIndices|>];
        index = Length[leaves];
        AssociateTo[buckets, bucketKey -> Append[candidates, index]]];
      index];
    (* Active-root subsets are themselves lists, so MapThread at the scalar
       level descends one dimension too far.  Ragged deferred-job term lists
       make that especially visible: scalar coefficients are paired against
       the elements of their root-index lists instead of against the lists.
       Position-based pairing preserves the tensor/job structure exactly. *)
    registerAtLevel[expressions_, active_, level_Integer] :=
      MapIndexed[Function[{expression, position},
        register[expression, Extract[active, position]]],
        expressions, {level}];
    entries = provider["Entries"];
    entryActive = provider["ActiveRoots"];
    entryMaps = Association[Table[key -> registerAtLevel[
        entries[key], entryActive[key], 3], {key, Keys[entries]}]];
    oneFormMap = If[provider["OneForms"] === {}, {},
      registerAtLevel[provider["OneForms"],
        provider["OneFormActiveRoots"], 2]];
    bundle = Lookup[provider, "DeferredBundle", None];
    If[AssociationQ[bundle],
      operandMap = registerAtLevel[provider["BundleOperandExpressions"],
        provider["BundleOperandActiveRoots"], 1];
      coefficientMap = registerAtLevel[
        provider["BundleCoefficientExpressions"],
        provider["BundleCoefficientActiveRoots"], 2];
      operandTable = Lookup[bundle, "OperandTable", {}];
      If[Length[operandTable] === Length[operandMap],
        Do[If[! KeyExistsQ[structuredOperands, operandMap[[index]]],
          AssociateTo[structuredOperands,
            operandMap[[index]] -> operandTable[[index]]]],
          {index, Length[operandMap]}]]];
    compileLeaf[leaf_Association, index_Integer] := Module[
      {activeRoots = roots[[leaf["ActiveRoots"]]], rootSymbols},
      rootSymbols = Take[$multiquadraticStripSplitRootSymbols,
        Length[leaf["ActiveRoots"]]];
      If[KeyExistsQ[structuredOperands, index],
        multiquadraticStripScreenCompileFactoredScalarExact[
          structuredOperands[index, "Numerator"],
          structuredOperands[index, "DenominatorFactors"], activeRoots,
          rootSymbols, scalarVariables],
        multiquadraticStripScreenCompileScalarExact[leaf["Expression"],
          activeRoots, rootSymbols, scalarVariables]]];
    {exactCompileSeconds, exactLeaves} = AbsoluteTiming[
      If[TrueQ[$multiquadraticStripSplitSparseCompilation],
        MapIndexed[compileLeaf[#1, First[#2]] &, leaves],
        ConstantArray[$Failed, Length[leaves]]]];
    multiquadraticStripCacheInsert[
      $multiquadraticStripSplitSparseExactPlanCache,
      CreateUUID["SplitSparseExactPlan-"],
      <|"ProviderData" -> providerCacheData,
        "Data" -> <|"Leaves" -> leaves, "ExactLeaves" -> exactLeaves,
          "OccurrenceMaps" -> <|"Entries" -> entryMaps,
            "OneForms" -> oneFormMap, "BundleOperands" -> operandMap,
            "BundleCoefficients" -> coefficientMap|>|>|>, 2]];
  leaves = MapIndexed[Function[{leaf, position},
    leafIndex = First[position];
    If[TrueQ[$multiquadraticStripSplitSparseCompilation],
      compileInvocationCount++;
      {compileSeconds, compiled} = AbsoluteTiming[
        If[AssociationQ[exactLeaves[[leafIndex]]],
          multiquadraticStripScreenReduceScalar[
            exactLeaves[[leafIndex]], prime], $Failed]],
      compileSeconds = 0.; compiled = $Failed];
    Join[leaf, <|"Compiled" -> If[AssociationQ[compiled], compiled, $Failed],
      "CompileSeconds" -> compileSeconds|>]], leaves];
  compiledLeafCount = Count[Lookup[leaves, "Compiled", {}], _Association];
  occurrenceCount = Total[Length[Flatten[#1]] & /@ Join[
    Values[entryMaps], {oneFormMap, operandMap, coefficientMap}]];
  plan = <|"Status" -> "MultiquadraticSplitSparseEvaluationPlanV1",
    "Schema" -> "MultiquadraticSplitSparseEvaluationPlanV1",
    "CoefficientData" -> provider["CoefficientData"],
    "Prime" -> prime, "RootCount" -> provider["RootCount"],
    "Leaves" -> leaves,
    "OccurrenceMaps" -> <|"Entries" -> entryMaps,
      "OneForms" -> oneFormMap, "BundleOperands" -> operandMap,
      "BundleCoefficients" -> coefficientMap|>,
    "UniqueLeafCount" -> Length[leaves],
    "OccurrenceCount" -> occurrenceCount,
    "CompileInvocationCount" -> compileInvocationCount,
    "CompiledLeafCount" -> compiledLeafCount,
    "FallbackLeafCount" -> Length[leaves] - compiledLeafCount,
    "CompileSeconds" -> Total[Lookup[leaves, "CompileSeconds", 0.]],
    "ExactPlanCacheHit" -> exactPlanCacheHit,
    "ExactCompileSeconds" -> exactCompileSeconds,
    "PlanCacheHit" -> False,
    "BuildCompileInvocationCount" -> compileInvocationCount|>;
  plan = Append[plan, "BuildSeconds" -> N[AbsoluteTime[] - startTime]];
  multiquadraticStripCacheInsert[$multiquadraticStripSplitSparsePlanCache,
    CreateUUID["SplitSparsePlan-"],
    <|"ProviderData" -> providerCacheData, "Prime" -> prime,
      "Data" -> plan|>, 8];
  plan
];
multiquadraticStripSplitSparseEvaluationPlan[___] :=
  multiquadraticStripFailure[
    "InvalidSplitSparseEvaluationPlanArguments"];

multiquadraticStripSplitSparseEvaluationPlanHotValidQ[plan_Association,
    provider_Association, prime_Integer] := Module[
  {leaves = Lookup[plan, "Leaves", $Failed], maps, indices},
  maps = Lookup[plan, "OccurrenceMaps", $Failed];
  indices = If[AssociationQ[maps] &&
      AssociationQ[Lookup[maps, "Entries", $Failed]],
    Flatten[Join[Values[maps["Entries"]],
      {Lookup[maps, "OneForms", {}],
       Lookup[maps, "BundleOperands", {}],
       Lookup[maps, "BundleCoefficients", {}]}]], $Failed];
  TrueQ[Lookup[plan, "Status", None] ===
      "MultiquadraticSplitSparseEvaluationPlanV1" &&
    Lookup[plan, "Schema", None] ===
      "MultiquadraticSplitSparseEvaluationPlanV1" &&
    Lookup[provider, "Kind", None] === "SplitBranch" &&
    SameQ[Lookup[plan, "CoefficientData", None],
      Lookup[provider, "CoefficientData", Missing["NoCoefficientData"]]] &&
    Lookup[plan, "Prime", None] === prime && PrimeQ[prime] &&
    Lookup[plan, "RootCount", None] === Lookup[provider, "RootCount", None] &&
    ListQ[leaves] && AssociationQ[maps] &&
    VectorQ[indices, IntegerQ[#1] && 1 <= #1 <= Length[leaves] &]]
];
multiquadraticStripSplitSparseEvaluationPlanHotValidQ[___] := False;

multiquadraticStripSplitSparseEvaluationPlanValidQ[plan_Association,
    provider_Association, prime_Integer] := Module[
  {leaves, maps, entryMaps, match, matchAtLevel, entries, active, entryOK,
   oneFormOK, bundle, operandOK, coefficientOK, leafOK},
  If[! multiquadraticStripProviderValidQ[provider] ||
      ! multiquadraticStripSplitSparseEvaluationPlanHotValidQ[plan,
        provider, prime], Return[False]];
  leaves = plan["Leaves"]; maps = plan["OccurrenceMaps"];
  entryMaps = Lookup[maps, "Entries", $Failed];
  If[! AssociationQ[entryMaps] ||
      Sort[Keys[entryMaps]] =!= Sort[Keys[provider["Entries"]]],
    Return[False]];
  leafOK = AllTrue[leaves, Function[leaf,
    AssociationQ[leaf] &&
      VectorQ[Lookup[leaf, "ActiveRoots", $Failed], IntegerQ] &&
      DuplicateFreeQ[leaf["ActiveRoots"]] &&
      Sort[leaf["ActiveRoots"]] === leaf["ActiveRoots"] &&
      AllTrue[leaf["ActiveRoots"],
        1 <= #1 <= provider["RootCount"] &] &&
      (AssociationQ[Lookup[leaf, "Compiled", None]] ||
        Lookup[leaf, "Compiled", None] === $Failed)]];
  If[! leafOK, Return[False]];
  match[expression_, activeIndices_, index_] := IntegerQ[index] &&
    1 <= index <= Length[leaves] &&
    SameQ[leaves[[index, "Expression"]], expression] &&
    SameQ[leaves[[index, "ActiveRoots"]], activeIndices];
  matchAtLevel[expressions_, activeRoots_, indices_, level_Integer] :=
    TrueQ[And @@ Flatten[MapIndexed[Function[{expression, position},
      match[expression, Extract[activeRoots, position],
        Extract[indices, position]]], expressions, {level}]]];
  entries = provider["Entries"]; active = provider["ActiveRoots"];
  entryOK = And @@ Flatten[Table[
    matchAtLevel[entries[key], active[key], entryMaps[key], 3],
    {key, Keys[entries]}]];
  oneFormOK = If[provider["OneForms"] === {},
    Lookup[maps, "OneForms", $Failed] === {},
    matchAtLevel[provider["OneForms"], provider["OneFormActiveRoots"],
      Lookup[maps, "OneForms", $Failed], 2]];
  bundle = Lookup[provider, "DeferredBundle", None];
  If[AssociationQ[bundle],
    operandOK = matchAtLevel[provider["BundleOperandExpressions"],
      provider["BundleOperandActiveRoots"],
      Lookup[maps, "BundleOperands", $Failed], 1];
    coefficientOK = matchAtLevel[
      provider["BundleCoefficientExpressions"],
      provider["BundleCoefficientActiveRoots"],
      Lookup[maps, "BundleCoefficients", $Failed], 2],
    operandOK = Lookup[maps, "BundleOperands", $Failed] === {};
    coefficientOK = Lookup[maps, "BundleCoefficients", $Failed] === {}];
  TrueQ[entryOK && oneFormOK && operandOK && coefficientOK &&
    plan["UniqueLeafCount"] === Length[leaves] &&
    plan["OccurrenceCount"] === Total[Length[Flatten[#1]] & /@
      Join[Values[entryMaps], {maps["OneForms"], maps["BundleOperands"],
        maps["BundleCoefficients"]}]]]
];
multiquadraticStripSplitSparseEvaluationPlanValidQ[___] := False;

multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ[plan_,
    provider_, prime_] :=
  multiquadraticStripSplitSparseEvaluationPlanHotValidQ[
    plan, provider, prime];

multiquadraticStripSplitSparsePlannedEntry[plan_Association,
    index_Integer, provider_Association, scalarRules_Association,
    deltaValues_List, rootValues_List, prime_Integer] := Module[{leaf},
  If[index < 1 || index > Length[plan["Leaves"]],
    Return[multiquadraticStripFailure[
      "SplitSparsePlanOccurrenceIndexInvalid", <|"Index" -> index|>]]];
  leaf = plan["Leaves"][[index]];
  multiquadraticStripSplitBranchEntry[leaf["Expression"], provider["Roots"],
    leaf["ActiveRoots"], scalarRules, deltaValues, rootValues, prime,
    leaf["Compiled"]]
];
multiquadraticStripSplitSparsePlannedEntry[___] :=
  multiquadraticStripFailure["InvalidSplitSparsePlannedEntryArguments"];

(* Native value arithmetic for an already compiled split plan.  The adapter
   receives one plan and all preflight-approved points of an image, evaluates
   every local sign branch with FLINT nmod arithmetic, projects to local
   channels and lifts to the declared global grade order.  The protocol is a
   temporary-file transport only: correctness is tested against the existing
   Wolfram evaluator, not against metadata or a second cache identity. *)
multiquadraticStripNativeSparseBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_sparse_eval"}]}, If[FileExistsQ[file], file, None]];

multiquadraticStripNativeSparseWritePlan[plan_Association,
    file_String] := Module[
  {stream = None, leaves = Lookup[plan, "Leaves", $Failed], prime,
   rootCount, numeratorFactors, denominatorFactors, numeratorTerms,
   denominatorTerms, active, sideFactors, writePolynomial,
   writeFactor, ok = False},
  If[! ListQ[leaves] || leaves === {} ||
      ! AllTrue[Lookup[leaves, "Compiled", {}], AssociationQ],
    Return[False]];
  prime = Lookup[plan, "Prime", $Failed];
  rootCount = Lookup[plan, "RootCount", $Failed];
  If[! PrimeQ[prime] || ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}],
    Return[False]];
  sideFactors[compiled_Association, side_String] := If[
    Lookup[compiled, "Representation", None] ===
      "SplitValueFactoredRationalV1",
    Lookup[compiled, side <> "Factors", $Failed],
    {<|"Polynomial" -> Lookup[compiled, side, $Failed], "Power" -> 1|>}];
  numeratorFactors = sideFactors[#1["Compiled"], "Numerator"] & /@ leaves;
  denominatorFactors = sideFactors[#1["Compiled"], "Denominator"] & /@ leaves;
  If[! MatchQ[numeratorFactors, {{__Association} ..}] ||
      ! MatchQ[denominatorFactors, {{__Association} ..}] ||
      ! AllTrue[Flatten[{numeratorFactors, denominatorFactors}],
        MatchQ[#1, _Association] &&
          AssociationQ[Lookup[#1, "Polynomial", None]] &&
          IntegerQ[Lookup[#1, "Power", None]] && #1["Power"] > 0 &],
    Return[False]];
  numeratorTerms = Total[Length[#1["Polynomial", "Coefficients"]] & /@
    Flatten[numeratorFactors]];
  denominatorTerms = Total[Length[#1["Polynomial", "Coefficients"]] & /@
    Flatten[denominatorFactors]];
  writePolynomial[polynomial_Association] := Module[{rows},
    rows = MapThread[Prepend,
      {polynomial["Exponents"], polynomial["Coefficients"]}];
    BinaryWrite[stream, Flatten[rows], "UnsignedInteger64",
      ByteOrdering -> -1]];
  writeFactor[factor_Association] := (
    BinaryWrite[stream, {factor["Power"],
        Length[factor["Polynomial", "Coefficients"]]},
      "UnsignedInteger64", ByteOrdering -> -1];
    writePolynomial[factor["Polynomial"]]);
  Quiet[Check[
    stream = OpenWrite[file, BinaryFormat -> True];
    BinaryWrite[stream, ToCharacterCode["MQSE1P2\000"],
      "UnsignedInteger8"];
    BinaryWrite[stream, {prime, rootCount, Length[leaves],
        Total[Length /@ numeratorFactors],
        Total[Length /@ denominatorFactors], numeratorTerms,
        denominatorTerms}, "UnsignedInteger64", ByteOrdering -> -1];
    Do[
      active = leaves[[index, "ActiveRoots"]];
      BinaryWrite[stream, {Total[2^(active - 1)], Length[active],
          Length[numeratorFactors[[index]]],
          Length[denominatorFactors[[index]]]},
        "UnsignedInteger64", ByteOrdering -> -1];
      writeFactor /@ numeratorFactors[[index]];
      writeFactor /@ denominatorFactors[[index]],
      {index, Length[leaves]}];
    Close[stream]; stream = None; ok = True,
    If[Head[stream] === OutputStream, Quiet[Close[stream]]]; ok = False]];
  ok
];
multiquadraticStripNativeSparseWritePlan[___] := False;

multiquadraticStripNativeSparseEvaluateBatch[plan_Association,
    preflights_List, threads_Integer: 1] := Module[
  {startTime = AbsoluteTime[], binary, prime, rootCount, leafCount,
   gradeCount, directory = None, planFile, pointFile, outputFile,
   stream = None, rows, process, magic, header, statuses, channels,
   planWriteSeconds = 0., pointWriteSeconds = 0., adapterSeconds = 0.,
   readSeconds = 0., result, tag},
  tag = Unique["MultiquadraticNativeSparseBatchFailure"];
  binary = multiquadraticStripNativeSparseBinary[];
  prime = Lookup[plan, "Prime", $Failed];
  rootCount = Lookup[plan, "RootCount", $Failed];
  leafCount = Length[Lookup[plan, "Leaves", {}]];
  gradeCount = If[IntegerQ[rootCount], 2^rootCount, 0];
  If[! StringQ[binary] || preflights === {} ||
      ! Between[threads, {1, 8}] || ! PrimeQ[prime] ||
      ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}] ||
      leafCount < 1 || ! AllTrue[preflights,
        Lookup[#1, "Status", None] ===
            "MultiquadraticProviderPreflightV1" &&
          Lookup[#1, "Prime", None] === prime &&
          Length[Lookup[#1, "SquareRootGeneratorValues", {}]] === rootCount &],
    Return[multiquadraticStripFailure[
      "InvalidNativeSparseBatchInput"]]];
  result = Catch[
    directory = CreateDirectory[];
    planFile = FileNameJoin[{directory, "plan.bin"}];
    pointFile = FileNameJoin[{directory, "points.bin"}];
    outputFile = FileNameJoin[{directory, "channels.bin"}];
    {planWriteSeconds, result} = AbsoluteTiming[
      multiquadraticStripNativeSparseWritePlan[plan, planFile]];
    If[! TrueQ[result],
      Throw[multiquadraticStripFailure[
        "NativeSparsePlanWriteFailed"], tag]];
    rows = Join[Lookup[#1, "Point", {}],
        {Lookup[#1, "EpsilonMod", $Failed]},
        Lookup[#1, "SquareRootGeneratorValues", {}]] & /@ preflights;
    {pointWriteSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenWrite[pointFile, BinaryFormat -> True];
      BinaryWrite[stream, ToCharacterCode["MQSE1Q1\000"],
        "UnsignedInteger8"];
      BinaryWrite[stream, {prime, rootCount, leafCount, Length[preflights]},
        "UnsignedInteger64", ByteOrdering -> -1];
      BinaryWrite[stream, Flatten[rows], "UnsignedInteger64",
        ByteOrdering -> -1];
      Close[stream]; stream = None; True, False]]];
    If[! TrueQ[result],
      If[Head[stream] === OutputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeSparsePointWriteFailed"], tag]];
    {adapterSeconds, process} = AbsoluteTiming[RunProcess[
      taskBrokerNativeCommand[
        {binary, planFile, pointFile, outputFile, ToString[threads]}, threads]]];
    If[! AssociationQ[process] || process["ExitCode"] =!= 0,
      Throw[multiquadraticStripFailure[
        "NativeSparseAdapterFailed"], tag]];
    {readSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenRead[outputFile, BinaryFormat -> True];
      magic = BinaryReadList[stream, "UnsignedInteger8", 8];
      header = BinaryReadList[stream, "UnsignedInteger64", 4,
        ByteOrdering -> -1];
      statuses = BinaryReadList[stream, "UnsignedInteger64",
        Length[preflights] leafCount, ByteOrdering -> -1];
      channels = BinaryReadList[stream, "UnsignedInteger64",
        Length[preflights] leafCount gradeCount, ByteOrdering -> -1];
      Close[stream]; stream = None;
      If[magic =!= ToCharacterCode["MQSE1X1\000"] ||
          header =!= {prime, rootCount, leafCount, Length[preflights]} ||
          Length[statuses] =!= Length[preflights] leafCount ||
          ! AllTrue[statuses, MemberQ[{0, 1}, #1] &] ||
          Length[channels] =!= Length[preflights] leafCount gradeCount ||
          ! AllTrue[channels, 0 <= #1 < prime &], $Failed,
        <|"Status" -> "MultiquadraticNativeSparseBatchV1",
          "LeafStatuses" -> ArrayReshape[statuses,
            {Length[preflights], leafCount}],
          "Channels" -> ArrayReshape[channels,
            {Length[preflights], leafCount, gradeCount}],
          "Threads" -> threads|>], $Failed]]];
    If[! AssociationQ[result],
      If[Head[stream] === InputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeSparseResponseInvalid"], tag]];
    Join[result, <|"PlanWriteSeconds" -> planWriteSeconds,
      "PointWriteSeconds" -> pointWriteSeconds,
      "AdapterSeconds" -> adapterSeconds,
      "ResponseReadSeconds" -> readSeconds|>],
    tag, #1 &];
  If[StringQ[directory] && DirectoryQ[directory],
    Quiet[DeleteDirectory[directory, DeleteContents -> True]]];
  If[AssociationQ[result],
    Append[result, "Seconds" -> N[AbsoluteTime[] - startTime]], result]
];
multiquadraticStripNativeSparseEvaluateBatch[___] :=
  multiquadraticStripFailure["InvalidNativeSparseBatchArguments"];

(* A preserved BlockEquationDeferred preparation is already the arithmetic
   DAG of the forcing.  Evaluate that DAG at every split point in one native
   batch instead of first materializing and canonicalizing its whole rational
   functions.  The provider still owns E, C, Q and the one-form basis; this
   adapter replaces only BBar before the existing row assembler is called. *)
multiquadraticStripNativeDeferredBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_deferred_ast_eval"}]}, If[FileExistsQ[file], file, None]];

multiquadraticStripAttachDeferredPreparation[provider_Association,
    preparation_Association, inputFile_String] := Module[
  {preparationData, filePayload, filePreparations},
  If[! multiquadraticStripProviderValidQ[provider] ||
      ! FileExistsQ[inputFile] ||
      ! TrueQ[blockEquationDeferredPreparationQ[preparation]] ||
      Lookup[preparation, "Variables", None] =!= provider["Variables"] ||
      Lookup[preparation, "Regulator", None] =!= provider["Regulator"] ||
      Lookup[preparation, "Dimensions", None] =!=
        Prepend[provider["Dimensions"], 2],
    Return[multiquadraticStripFailure[
      "InvalidDeferredPreparationProvider"]]];
  filePayload = Quiet[Check[FamilyArtifactRead[inputFile], $Failed]];
  filePreparations = DeleteDuplicates[Cases[filePayload,
    candidate_Association /;
        TrueQ[blockEquationDeferredPreparationQ[candidate]] :> candidate,
    {0, Infinity}], SameQ];
  If[! AnyTrue[filePreparations, SameQ[#1, preparation] &],
    Return[multiquadraticStripFailure[
      "DeferredPreparationFileDataMismatch"]]];
  (* Never attach the large Records forest to a provider that is serialized
     for every image.  The V2 type and mathematical dimensions are the small
     runtime data; the exactly checked preparation file remains authoritative. *)
  preparationData = KeyTake[preparation, {"DataType", "SchemaVersion", "Status",
    "Variables", "Regulator", "Dimensions"}];
  Join[provider, <|"DeferredPreparation" -> preparationData,
    "DeferredPreparationFile" -> inputFile|>]
];
multiquadraticStripAttachDeferredPreparation[___] :=
  multiquadraticStripFailure[
    "InvalidDeferredPreparationProviderArguments"];

multiquadraticStripNativeDeferredWriteRequest[file_String,
    provider_Association, preflights_List] := Module[
  {variables, regulator, roots, prime, lines, rootLines, imageLines},
  variables = Lookup[provider, "Variables", $Failed];
  regulator = Lookup[provider, "Regulator", $Failed];
  roots = Lookup[provider, "Roots", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      ! MatchQ[regulator, _Symbol] ||
      ! MatchQ[roots, {___Association}] || preflights === {},
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredRequestInput"]]];
  prime = Lookup[First[preflights], "Prime", $Failed];
  If[! PrimeQ[prime] || ! AllTrue[preflights,
      Lookup[#1, "Status", None] ===
          "MultiquadraticProviderPreflightV1" &&
        Lookup[#1, "Prime", None] === prime &&
        SameQ[Lookup[#1, "CoefficientData", None],
          provider["CoefficientData"]] &&
        Length[Lookup[#1, "QuadraticRadicands", {}]] === Length[roots] &&
        Length[Lookup[#1, "SquareRootGeneratorValues", {}]] ===
          Length[roots] &],
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredPreflightBatch", <|
        "Statuses" -> Lookup[preflights, "Status", None],
        "ObservedPrimes" -> Lookup[preflights, "Prime", None],
        "ExpectedPrime" -> prime,
        "CoefficientDataMatches" ->
          (SameQ[Lookup[#1, "CoefficientData", None],
              provider["CoefficientData"]] & /@ preflights),
        "QuadraticRadicandCounts" ->
          (Length[Lookup[#1, "QuadraticRadicands", {}]] & /@ preflights),
        "SquareRootGeneratorValueCounts" ->
          (Length[Lookup[#1, "SquareRootGeneratorValues", {}]] & /@
            preflights),
        "ExpectedRootCount" -> Length[roots]|>]]];
  rootLines = ("root " <> ToString[squareRootRecordRadicand[#1],
      InputForm, PageWidth -> Infinity]) & /@ roots;
  imageLines = Function[preflight,
      "image " <> StringRiffle[ToString /@ Join[
        preflight["Point"], {preflight["EpsilonMod"]},
        Flatten[Transpose[{preflight["QuadraticRadicands"],
          preflight["SquareRootGeneratorValues"]}]]], " "]] /@ preflights;
  lines = Join[{"DeferredASTRequestV1", "prime " <> ToString[prime],
      "variables " <> StringRiffle[
        SymbolName /@ Join[variables, {regulator}], " "],
      "rank " <> ToString[Length[roots]]}, rootLines,
    {"base_count " <> ToString[Length[preflights]]}, imageLines];
  If[Quiet[Check[
      Export[file, StringRiffle[lines, "\n"] <> "\n", "Text"]; True,
      False]],
    <|"Status" -> "MultiquadraticNativeDeferredRequestV1",
      "Prime" -> prime, "BaseCount" -> Length[preflights],
      "RootCount" -> Length[roots]|>,
    multiquadraticStripFailure["NativeDeferredRequestWriteFailed"]]
];
multiquadraticStripNativeDeferredWriteRequest[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredRequestArguments"];

Options[multiquadraticStripNativeDeferredReadOutput] = {
  "Derivatives" -> False
};
multiquadraticStripNativeDeferredReadOutput[file_String,
    provider_Association, expectedPrime_Integer,
    expectedBaseCount_Integer, opts : OptionsPattern[]] := Module[
  {stream = None, magic, status, header, prime, rank, baseCount, gradeCount,
   recordCount, termCount, uniqueCount, dimensions, parseNanoseconds,
   evaluationNanoseconds, targets, values, trailing, expectedDimensions,
   expectedTargets, result, derivatives, componentCount, componentValues,
   batch},
  derivatives = TrueQ[OptionValue["Derivatives"]];
  componentCount = If[derivatives, 3, 1];
  result = Catch[Quiet[Check[
    stream = OpenRead[file, BinaryFormat -> True];
    magic = BinaryReadList[stream, "UnsignedInteger8", 8];
    status = BinaryRead[stream, "UnsignedInteger64", ByteOrdering -> -1];
    header = BinaryReadList[stream, "UnsignedInteger64", 12,
      ByteOrdering -> -1];
    If[magic =!= ToCharacterCode[
          If[derivatives, "DAGO2V1\000", "DAGO1V1\000"]] ||
        ! IntegerQ[status] || Length[header] =!= 12,
      Throw[multiquadraticStripFailure[
        "NativeDeferredOutputHeaderInvalid"]]];
    If[status =!= 0,
      Throw[multiquadraticStripFailure["NativeDeferredEvaluatorRefused",
        <|"NativeStatusCode" -> status,
          "DetailIndex" -> header[[8]],
          "DetailOffset" -> header[[9]]|>]]];
    {prime, rank, baseCount, gradeCount, recordCount, termCount,
      uniqueCount} = Take[header, 7];
    dimensions = header[[8 ;; 10]];
    {parseNanoseconds, evaluationNanoseconds} = header[[11 ;; 12]];
    expectedDimensions = Prepend[provider["Dimensions"], 2];
    If[prime =!= expectedPrime || rank =!= provider["RootCount"] ||
        gradeCount =!= provider["GradeCount"] ||
        baseCount =!= expectedBaseCount ||
        dimensions =!= expectedDimensions ||
        recordCount =!= Times @@ expectedDimensions,
      Throw[multiquadraticStripFailure[
        "NativeDeferredOutputShapeMismatch",
        <|"Observed" -> {prime, rank, baseCount, gradeCount, dimensions,
            recordCount},
          "Expected" -> {expectedPrime, provider["RootCount"],
            expectedBaseCount, provider["GradeCount"], expectedDimensions,
            Times @@ expectedDimensions}|>]]];
    targets = ConstantArray[{}, recordCount];
    values = ConstantArray[{}, recordCount];
    Do[
      targets[[index]] = BinaryReadList[stream, "UnsignedInteger64", 3,
        ByteOrdering -> -1];
      values[[index]] = BinaryReadList[stream, "UnsignedInteger64",
        componentCount baseCount gradeCount, ByteOrdering -> -1],
      {index, recordCount}];
    trailing = BinaryRead[stream, "UnsignedInteger8"];
    Close[stream]; stream = None;
    expectedTargets = Flatten[Table[{mu, i, j},
      {mu, expectedDimensions[[1]]}, {i, expectedDimensions[[2]]},
      {j, expectedDimensions[[3]]}], 2];
    If[targets =!= expectedTargets || trailing =!= EndOfFile ||
        ! AllTrue[Flatten[values], IntegerQ[#1] && 0 <= #1 < prime &],
      Throw[multiquadraticStripFailure[
        "NativeDeferredOutputPayloadInvalid"]]];
    componentValues = Table[
      values[[All, (component - 1) baseCount gradeCount +
        Range[baseCount gradeCount]]], {component, componentCount}];
    batch[component_Integer] := Table[ArrayReshape[
      componentValues[[component, All,
        (base - 1) gradeCount + Range[gradeCount]]],
      Append[dimensions, gradeCount]], {base, baseCount}];
    Join[<|"Status" -> If[derivatives,
          "MultiquadraticNativeDeferredDerivativeBatchV1",
          "MultiquadraticNativeDeferredBatchV1"],
      "Prime" -> prime, "RootCount" -> rank,
      "GradeCount" -> gradeCount, "BaseCount" -> baseCount,
      "Dimensions" -> dimensions, "RecordCount" -> recordCount,
      "TermCount" -> termCount, "UniqueExpressionCount" -> uniqueCount,
      "ParseSeconds" -> N[parseNanoseconds/10.^9],
      "EvaluationSeconds" -> N[evaluationNanoseconds/10.^9],
      "BBarBatch" -> batch[1]|>,
      If[derivatives, <|"BBarDerivativeBatch" -> {batch[2], batch[3]}|>,
        <||>]],
    multiquadraticStripFailure["NativeDeferredOutputReadFailed"]]]];
  If[Head[stream] === InputStream, Quiet[Close[stream]]];
  result
];
multiquadraticStripNativeDeferredReadOutput[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredOutputArguments"];

Options[multiquadraticStripNativeDeferredEvaluateBatch] = {
  "Derivatives" -> False,
  "Threads" -> Automatic
};
multiquadraticStripNativeDeferredEvaluateBatch[provider_Association,
    preflights_List, opts : OptionsPattern[]] := Module[
  {started = AbsoluteTime[], binary, preparation, inputFile, directory = None,
   requestFile, outputFile, request, process, result, prime, derivatives,
   command, threads, actualThreads},
  derivatives = TrueQ[OptionValue["Derivatives"]];
  threads = Replace[OptionValue["Threads"],
    Automatic :> Clip[$ProcessorCount, {1, 8}]];
  If[! IntegerQ[threads] || ! Between[threads, {1, 8}],
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredThreadCount", <|"Threads" -> threads|>]]];
  actualThreads = Min[threads, Length[preflights]];
  binary = multiquadraticStripNativeDeferredBinary[];
  preparation = Lookup[provider, "DeferredPreparation", None];
  inputFile = Lookup[provider, "DeferredPreparationFile", None];
  If[! StringQ[binary] || ! AssociationQ[preparation] ||
      ! StringQ[inputFile] || ! FileExistsQ[inputFile] ||
      Lookup[preparation, "DataType", None] =!= "DeferredBlockEquation" ||
      Lookup[preparation, "SchemaVersion", None] =!= 2 ||
      Lookup[preparation, "Status", None] =!= "Prepared" ||
      preflights === {},
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredBatchInput"]]];
  prime = Lookup[First[preflights], "Prime", $Failed];
  If[! PrimeQ[prime] ||
      ! AllTrue[preflights, Lookup[#1, "Prime", None] === prime &],
    Return[multiquadraticStripFailure[
      "MixedNativeDeferredBatchPrimes"]]];
  result = Internal`WithLocalSettings[
    directory = CreateDirectory[];
    requestFile = FileNameJoin[{directory, "request.txt"}];
    outputFile = FileNameJoin[{directory, "output.bin"}];,
    request = multiquadraticStripNativeDeferredWriteRequest[requestFile,
      provider, preflights];
    If[Lookup[request, "Status", None] =!=
        "MultiquadraticNativeDeferredRequestV1", request,
      command = Join[{binary, inputFile, requestFile, outputFile},
        If[derivatives, {"--derivatives"}, {}],
        {"--threads", ToString[actualThreads]}];
      process = RunProcess[taskBrokerNativeCommand[command, actualThreads]];
      If[! AssociationQ[process] || process["ExitCode"] =!= 0,
        multiquadraticStripFailure["NativeDeferredEvaluatorProcessFailed",
          <|"ExitCode" -> If[AssociationQ[process],
              process["ExitCode"], None],
            "StandardError" -> If[AssociationQ[process],
              process["StandardError"], Missing["NoProcess"]]|>],
        multiquadraticStripNativeDeferredReadOutput[outputFile, provider,
          prime, Length[preflights], "Derivatives" -> derivatives]]],
    If[StringQ[directory] && DirectoryQ[directory],
      Quiet[DeleteDirectory[directory, DeleteContents -> True]]]];
  If[AssociationQ[result],
    Join[result, <|"Threads" -> actualThreads,
      "Seconds" -> N[AbsoluteTime[] - started]|>], result]
];
multiquadraticStripNativeDeferredEvaluateBatch[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredBatchArguments"];

(* A deferred forcing may remain in its source variables even when the
   integrability screen is run in a rational chart.  This wrapper records the
   small exact frame map and one image, in the target multiquadratic field, for
   every source radical.  The large preserved DAG remains untouched. *)
multiquadraticStripChartForcingProvider[sourceProvider_Association,
    targetRoots_List, chartData_Association,
    sourceRootImages_List] := Module[
  {sourceVariables, targetVariables, regulator, sourceRoots, substitution,
   substitutionValues, suppliedJacobian, jacobian, jacobianDet,
   pulledSourceSquares, rootImageChannels, rootIdentities},
  If[! multiquadraticStripProviderValidQ[sourceProvider] ||
      ! AssociationQ[Lookup[sourceProvider, "DeferredPreparation", None]] ||
      ! StringQ[Lookup[sourceProvider, "DeferredPreparationFile", None]] ||
      ! FileExistsQ[sourceProvider["DeferredPreparationFile"]] ||
      ! MatchQ[targetRoots, {___Association}] ||
      Length[targetRoots] > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure[
      "InvalidChartForcingSourceProvider"]]];
  sourceVariables = Lookup[sourceProvider, "Variables", $Failed];
  targetVariables = masterTransportPresentationVariables[chartData];
  regulator = Lookup[sourceProvider, "Regulator", $Failed];
  sourceRoots = Lookup[sourceProvider, "Roots", $Failed];
  substitution = masterTransportPresentationSubstitution[chartData];
  suppliedJacobian = Lookup[chartData, "DifferentialPullbackMatrix",
    Automatic];
  If[! MatchQ[sourceVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[targetVariables, {_Symbol, _Symbol}] ||
      ! MatchQ[regulator, _Symbol] ||
      ! MatchQ[sourceRoots, {___Association}] ||
      Length[sourceRoots] =!= Length[sourceRootImages] ||
      ! MatchQ[substitution, {_Rule, _Rule}] ||
      First /@ substitution =!= sourceVariables ||
      ! AllTrue[targetRoots,
        AssociationQ[#1] &&
          ! MissingQ[squareRootRecordExpression[#1]] &&
          ! MissingQ[squareRootRecordRadicand[#1]] &&
          TrueQ[Together[squareRootRecordExpression[#1]^2 -
            squareRootRecordRadicand[#1]] === 0] &],
    Return[multiquadraticStripFailure[
      "InvalidChartForcingFrame"]]];
  substitutionValues = Last /@ substitution;
  If[! FreeQ[{substitutionValues, sourceRootImages}, regulator],
    Return[multiquadraticStripFailure[
      "RegulatorDependentChartForcingFrame"]]];
  jacobian = Quiet[Check[Map[Together, Table[
      D[substitutionValues[[i]], targetVariables[[a]]],
      {i, 2}, {a, 2}], {2}], $Failed]];
  If[! MatchQ[jacobian, {{_, _}, {_, _}}] ||
      (suppliedJacobian =!= Automatic &&
        (! MatchQ[suppliedJacobian, {{_, _}, {_, _}}] ||
          ! AllTrue[Flatten[jacobian - suppliedJacobian],
            TrueQ[Quiet[Check[Together[#1], $Failed]] === 0] &])),
    Return[multiquadraticStripFailure[
      "ChartForcingJacobianMismatch"]]];
  jacobianDet = Quiet[Check[Together[Det[jacobian]], $Failed]];
  If[jacobianDet === $Failed || TrueQ[jacobianDet === 0],
    Return[multiquadraticStripFailure[
      "ChartForcingJacobianDegenerate"]]];
  pulledSourceSquares = Quiet[Check[
    Together /@ ((squareRootRecordRadicand /@ sourceRoots) /.
      substitution), $Failed]];
  If[pulledSourceSquares === $Failed ||
      ! FreeQ[pulledSourceSquares, $Failed],
    Return[multiquadraticStripFailure[
      "ChartForcingRootSquarePullBackFailed"]]];
  rootIdentities = MapThread[TrueQ[Quiet[Check[
        Together[#1^2 - #2], $Failed]] === 0] &,
    {sourceRootImages, pulledSourceSquares}];
  If[! AllTrue[rootIdentities, TrueQ],
    Return[multiquadraticStripFailure[
      "ChartForcingRootImageMismatch",
      <|"RootIdentities" -> rootIdentities|>]]];
  rootImageChannels = Map[
    multiquadraticFieldDecompose[#1, targetRoots] &,
    sourceRootImages];
  If[! ListQ[rootImageChannels] ||
      Length[rootImageChannels] =!= Length[sourceRoots] ||
      ! AllTrue[rootImageChannels,
        ListQ[#1] && Length[#1] === 2^Length[targetRoots] &] ||
      ! FreeQ[rootImageChannels, $Failed],
    Return[multiquadraticStripFailure[
      "ChartForcingRootImageFieldMismatch"]]];
  <|"Status" -> "MultiquadraticChartForcingProviderV1",
    "Kind" -> "NativeDeferredChart", "SourceProvider" -> sourceProvider,
    "Variables" -> targetVariables, "Regulator" -> regulator,
    "Roots" -> targetRoots, "RootCount" -> Length[targetRoots],
    "GradeCount" -> 2^Length[targetRoots],
    "Dimensions" -> sourceProvider["Dimensions"],
    "CoefficientData" -> sourceProvider["CoefficientData"],
    "CoefficientPresentation" -> chartData,
    "SourceRootImages" -> sourceRootImages,
    "SourceRootImageChannels" -> rootImageChannels,
    "JacobianDeterminant" -> jacobianDet|>
];
multiquadraticStripChartForcingProvider[___] :=
  multiquadraticStripFailure[
    "InvalidChartForcingProviderArguments"];

multiquadraticStripChartForcingProviderValidQ[provider_Association] := Module[
  {expected, sourceProvider, chartData, targetRoots, sourceRootImages},
  If[Lookup[provider, "Status", None] =!=
        "MultiquadraticChartForcingProviderV1" ||
      Lookup[provider, "Kind", None] =!= "NativeDeferredChart",
    Return[False]];
  sourceProvider = Lookup[provider, "SourceProvider", $Failed];
  chartData = Lookup[provider, "CoefficientPresentation", $Failed];
  targetRoots = Lookup[provider, "Roots", $Failed];
  sourceRootImages = Lookup[provider, "SourceRootImages", $Failed];
  If[! AssociationQ[sourceProvider] || ! AssociationQ[chartData] ||
      ! ListQ[targetRoots] || ! ListQ[sourceRootImages], Return[False]];
  expected = multiquadraticStripChartForcingProvider[sourceProvider,
    targetRoots, chartData, sourceRootImages];
  If[Lookup[expected, "Status", None] =!=
      "MultiquadraticChartForcingProviderV1", Return[False]];
  TrueQ[provider === expected]
];
multiquadraticStripChartForcingProviderValidQ[___] := False;

(* The screen validates the full wrapper once.  Point evaluation subsequently
   checks only this immutable small data record; the source evaluator retains
   its own preparation and request validation. *)
multiquadraticStripChartForcingProviderHotValidQ[provider_Association] :=
 Module[{sourceProvider, roots, sourceRoots, channels, chartData},
  sourceProvider = Lookup[provider, "SourceProvider", $Failed];
  roots = Lookup[provider, "Roots", $Failed];
  sourceRoots = If[AssociationQ[sourceProvider],
    Lookup[sourceProvider, "Roots", $Failed], $Failed];
  channels = Lookup[provider, "SourceRootImageChannels", $Failed];
  chartData = Lookup[provider, "CoefficientPresentation", $Failed];
  If[Lookup[provider, "Status", None] =!=
        "MultiquadraticChartForcingProviderV1" ||
      Lookup[provider, "Kind", None] =!= "NativeDeferredChart" ||
      ! multiquadraticStripProviderHotValidQ[sourceProvider] ||
      ! AssociationQ[Lookup[sourceProvider, "DeferredPreparation", None]] ||
      ! StringQ[Lookup[sourceProvider, "DeferredPreparationFile", None]] ||
      ! FileExistsQ[sourceProvider["DeferredPreparationFile"]] ||
      ! ListQ[roots] || ! ListQ[sourceRoots] ||
      Lookup[provider, "RootCount", -1] =!= Length[roots] ||
      Lookup[provider, "GradeCount", -1] =!= 2^Length[roots] ||
      Lookup[provider, "Dimensions", None] =!=
        Lookup[sourceProvider, "Dimensions", Missing["NoDimensions"]] ||
      ! AssociationQ[chartData] ||
      masterTransportPresentationVariables[chartData] =!=
        Lookup[provider, "Variables", Missing["NoVariables"]] ||
      ! SameQ[Lookup[provider, "CoefficientData", None],
        Lookup[sourceProvider, "CoefficientData",
          Missing["NoCoefficientData"]]] ||
      ! MatchQ[channels, {___List}] ||
      Length[channels] =!= Length[sourceRoots] ||
      ! AllTrue[channels, Length[#1] === 2^Length[roots] &],
    Return[False]];
  True
];
multiquadraticStripChartForcingProviderHotValidQ[___] := False;

multiquadraticStripChartForcingPreflight[provider_Association, epsilonValue_,
    prime_Integer, targetPoint : {_Integer, _Integer},
    targetRootValues_List] := Module[
  {startTime = AbsoluteTime[], sourceProvider, targetVariables, regulator,
   targetRoots, sourceRoots, chartData, epsilonMod, scalarRules,
   evaluateScalar, sourcePoint, jacobian, jacobianDet, targetDeltaValues,
   sourceRootImageChannels, sourceRootImageChannelValues,
   targetSheetMonomials, sourceRootSheetValues, sourcePreflight,
  sourceRootSquares, failure},
  failure[status_String, data_: <||>] := multiquadraticStripFailure[status,
    Join[<|"Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "Point" -> Mod[targetPoint, prime],
      "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>, data]];
  If[! multiquadraticStripChartForcingProviderHotValidQ[provider] ||
      ! PrimeQ[prime] || ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[failure["InvalidChartForcingPreflightInput"]]];
  sourceProvider = provider["SourceProvider"];
  targetVariables = provider["Variables"];
  regulator = provider["Regulator"];
  targetRoots = provider["Roots"];
  sourceRoots = sourceProvider["Roots"];
  chartData = provider["CoefficientPresentation"];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0 ||
      Length[targetRootValues] =!= Length[targetRoots] ||
      ! VectorQ[targetRootValues, IntegerQ] ||
      MemberQ[Mod[targetRootValues, prime], 0],
    Return[failure["InvalidChartForcingTargetImage"]]];
  scalarRules = Join[
    AssociationThread[targetVariables, Mod[targetPoint, prime]],
    <|regulator -> epsilonMod|>];
  evaluateScalar[expression_] := Module[{evaluated},
    evaluated = multiquadraticStripModularGradeEvaluate[expression,
      scalarRules, {}, {}, prime];
    If[Lookup[evaluated, "Status", None] =!= "OK" ||
        Length[Lookup[evaluated, "Channels", {}]] =!= 1,
      $Failed, First[evaluated["Channels"]]]];
  sourcePoint = evaluateScalar /@
    (Last /@ masterTransportPresentationSubstitution[chartData]);
  jacobian = Map[evaluateScalar,
    chartData["DifferentialPullbackMatrix"], {2}];
  jacobianDet = evaluateScalar[chartData["JacobianDeterminant"]];
  targetDeltaValues = evaluateScalar /@
    (squareRootRecordRadicand /@ targetRoots);
  If[! VectorQ[sourcePoint, IntegerQ] ||
      ! MatrixQ[jacobian, IntegerQ] || Dimensions[jacobian] =!= {2, 2} ||
      ! IntegerQ[jacobianDet] || jacobianDet === 0 ||
      Mod[Det[jacobian] - jacobianDet, prime] =!= 0 ||
      ! VectorQ[targetDeltaValues, IntegerQ] ||
      Length[targetDeltaValues] =!= Length[targetRoots] ||
      ! AllTrue[Range[Length[targetRoots]],
        Mod[targetRootValues[[#1]]^2 - targetDeltaValues[[#1]], prime] ===
          0 &],
    Return[failure["ChartForcingFrameImageSingular"]]];
  sourceRootImageChannels = provider["SourceRootImageChannels"];
  sourceRootImageChannelValues =
    Map[evaluateScalar, sourceRootImageChannels, {2}];
  If[! MatrixQ[sourceRootImageChannelValues, IntegerQ] ||
      Dimensions[sourceRootImageChannelValues] =!=
        {Length[sourceRoots], 2^Length[targetRoots]},
    Return[failure["ChartForcingRootImageEvaluationFailed"]]];
  targetSheetMonomials = Table[
    Table[Product[
      If[BitGet[grade - 1, a - 1] === 1,
        Mod[If[BitGet[mask, a - 1] === 1, -1, 1]
          targetRootValues[[a]], prime], 1],
      {a, Length[targetRoots]}],
      {grade, 1, 2^Length[targetRoots]}],
    {mask, 0, 2^Length[targetRoots] - 1}];
  sourceRootSheetValues = Mod[
    targetSheetMonomials . Transpose[sourceRootImageChannelValues], prime];
  If[! MatrixQ[sourceRootSheetValues, IntegerQ] ||
      MemberQ[Flatten[sourceRootSheetValues], 0],
    Return[failure["ChartForcingSourceRootImageDegenerate"]]];
  sourcePreflight = multiquadraticStripProviderPreflight[sourceProvider,
    epsilonValue, prime, sourcePoint];
  If[Lookup[sourcePreflight, "Status", None] =!=
      "MultiquadraticProviderPreflightV1",
    Return[failure["ChartForcingSourcePreflightFailed",
      <|"Detail" -> sourcePreflight|>]]];
  sourceRootSquares = Lookup[sourcePreflight, "QuadraticRadicands", {}];
  If[Length[sourceRootSquares] =!= Length[sourceRoots] ||
      ! AllTrue[Range[Length[sourceRoots]], Mod[
          sourceRootSheetValues[[1, #1]]^2 - sourceRootSquares[[#1]],
          prime] === 0 &],
    Return[failure["ChartForcingSourceSquareRootImageMismatch"]]];
  sourcePreflight = Join[sourcePreflight, <|
    "SquareRootGeneratorValues" -> First[sourceRootSheetValues],
    "SplitPointQ" -> True|>];
  <|"Status" -> "MultiquadraticChartForcingPreflightV1",
    "CoefficientData" -> provider["CoefficientData"],
    "Prime" -> prime, "RegulatorValue" -> epsilonValue,
    "EpsilonMod" -> epsilonMod, "Point" -> Mod[targetPoint, prime],
    "TargetSquareRootGeneratorValues" -> Mod[targetRootValues, prime],
    "SourceRootSheetValues" -> sourceRootSheetValues,
    "SourcePreflight" -> sourcePreflight,
    "Jacobian" -> Mod[jacobian, prime],
    "JacobianDeterminant" -> Mod[jacobianDet, prime],
    "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripChartForcingPreflight[___] :=
  multiquadraticStripFailure[
    "InvalidChartForcingPreflightArguments"];

(* Fold a source-grade tensor onto the target grade basis by evaluating the
   source basis on each target sheet and applying the target Walsh projector.
   This handles rationalized roots, retained roots and products of retained
   roots uniformly; no hard-coded embedding of grade bits is needed. *)
multiquadraticStripChartForcingFoldTensor[tensor_,
    sourceRootSheetValues_List, targetRootValues_List,
    prime_Integer] := Module[
  {targetGradeCount, sourceRank, sourceGradeCount, dimensions, mapLevel,
   sourceSheetMonomials, fold, result},
  targetGradeCount = 2^Length[targetRootValues];
  If[Length[sourceRootSheetValues] =!= targetGradeCount ||
      ! MatrixQ[sourceRootSheetValues, IntegerQ] ||
      ! PrimeQ[prime] || MemberQ[Mod[targetRootValues, prime], 0],
    Return[$Failed]];
  sourceRank = If[sourceRootSheetValues === {}, 0,
    Length[First[sourceRootSheetValues]]];
  sourceGradeCount = 2^sourceRank;
  dimensions = Dimensions[tensor];
  If[dimensions === {} || Last[dimensions] =!= sourceGradeCount,
    Return[$Failed]];
  sourceSheetMonomials = Table[
    Table[Product[If[BitGet[grade - 1, a - 1] === 1,
        sourceRootSheetValues[[sheet, a]], 1], {a, sourceRank}],
      {grade, 1, sourceGradeCount}],
    {sheet, targetGradeCount}];
  fold[channelVector_List] := multiquadraticProjectSignChangeImages[
    Mod[sourceSheetMonomials . channelVector, prime],
    Mod[targetRootValues, prime], prime];
  mapLevel = Length[dimensions] - 1;
  result = Map[fold, tensor, {mapLevel}];
  If[FreeQ[result, $Failed] &&
      Dimensions[result] === ReplacePart[dimensions, -1 -> targetGradeCount],
    Mod[result, prime], $Failed]
];
multiquadraticStripChartForcingFoldTensor[___] := $Failed;

Options[multiquadraticStripNativeDeferredChartEvaluateBatch] = {
  "Threads" -> Automatic
};
multiquadraticStripNativeDeferredChartEvaluateBatch[
    provider_Association, preflights_List,
    opts : OptionsPattern[]] := Module[
  {startTime = AbsoluteTime[], sourceProvider, prime, sourcePreflights,
   threads, native, bbarBatch = {}, curlBatch = {}, base, sourceBBar,
   sourceDerivatives, foldedBBar, sourceCurl, foldedCurl, jacobian,
   jacobianDet, chartBBar},
  If[! multiquadraticStripChartForcingProviderHotValidQ[provider] ||
      preflights === {} || ! AllTrue[preflights,
        Lookup[#1, "Status", None] ===
            "MultiquadraticChartForcingPreflightV1" &&
          SameQ[Lookup[#1, "CoefficientData", None],
            provider["CoefficientData"]] &],
    Return[multiquadraticStripFailure[
      "InvalidNativeDeferredChartBatchInput"]]];
  prime = Lookup[First[preflights], "Prime", $Failed];
  If[! PrimeQ[prime] || ! AllTrue[preflights,
      Lookup[#1, "Prime", None] === prime &],
    Return[multiquadraticStripFailure[
      "MixedNativeDeferredChartBatchPrimes"]]];
  threads = OptionValue["Threads"];
  sourceProvider = provider["SourceProvider"];
  sourcePreflights = Lookup[preflights, "SourcePreflight", {}];
  native = multiquadraticStripNativeDeferredEvaluateBatch[sourceProvider,
    sourcePreflights, "Derivatives" -> True, "Threads" -> threads];
  If[Lookup[native, "Status", None] =!=
      "MultiquadraticNativeDeferredDerivativeBatchV1",
    Return[multiquadraticStripFailure[
      "NativeDeferredChartSourceEvaluationFailed",
      <|"Detail" -> native|>]]];
  Do[
    sourceBBar = native["BBarBatch"][[base]];
    sourceDerivatives = native["BBarDerivativeBatch"][[All, base]];
    foldedBBar = multiquadraticStripChartForcingFoldTensor[sourceBBar,
      preflights[[base, "SourceRootSheetValues"]],
      preflights[[base, "TargetSquareRootGeneratorValues"]], prime];
    sourceCurl = Mod[sourceDerivatives[[2, 1]] -
      sourceDerivatives[[1, 2]], prime];
    foldedCurl = multiquadraticStripChartForcingFoldTensor[sourceCurl,
      preflights[[base, "SourceRootSheetValues"]],
      preflights[[base, "TargetSquareRootGeneratorValues"]], prime];
    If[foldedBBar === $Failed || foldedCurl === $Failed,
      Return[multiquadraticStripFailure[
        "NativeDeferredChartGradeFoldFailed",
        <|"BaseIndex" -> base|>]]];
    jacobian = preflights[[base, "Jacobian"]];
    jacobianDet = preflights[[base, "JacobianDeterminant"]];
    chartBBar = {
      Mod[jacobian[[1, 1]] foldedBBar[[1]] +
        jacobian[[2, 1]] foldedBBar[[2]], prime],
      Mod[jacobian[[1, 2]] foldedBBar[[1]] +
        jacobian[[2, 2]] foldedBBar[[2]], prime]};
    AppendTo[bbarBatch, chartBBar];
    AppendTo[curlBatch, Mod[jacobianDet foldedCurl, prime]],
    {base, Length[preflights]}];
  <|"Status" -> "MultiquadraticNativeDeferredChartBatchV1",
    "Prime" -> prime, "RootCount" -> provider["RootCount"],
    "GradeCount" -> provider["GradeCount"],
    "BaseCount" -> Length[preflights],
    "Dimensions" -> Prepend[provider["Dimensions"], 2],
    "BBarBatch" -> bbarBatch, "BBarCurlBatch" -> curlBatch,
    "SourceRootCount" -> sourceProvider["RootCount"],
    "SourceNative" -> KeyDrop[native,
      {"BBarBatch", "BBarDerivativeBatch"}],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripNativeDeferredChartEvaluateBatch[___] :=
  multiquadraticStripFailure[
    "InvalidNativeDeferredChartBatchArguments"];

(* The split-point census is the same finite-field problem on a much smaller
   root-free list: root squares, Q, d log Q and d log Delta.  Evaluate the
   complete candidate pool in one native call, then perform only the Legendre
   tests and square roots in Wolfram.  This replaces hundreds of repeated
   symbolic substitutions without changing the accepted point sequence. *)
multiquadraticStripNativePreflightBatch[provider_Association,
    epsilonValue_, prime_Integer, points_List, threads_Integer: 1] := Module[
  {startTime = AbsoluteTime[], rootCount, variables, epsilon, epsilonMod,
   expressions, compileSeconds, compiled, nativePlan, dummy, native,
   values, decodeSeconds, records, decode, perPointSeconds = 0.},
  rootCount = Lookup[provider, "RootCount", $Failed];
  variables = Lookup[provider, "Variables", $Failed];
  epsilon = Lookup[provider, "Regulator", $Failed];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[Lookup[provider, "Kind", None] =!= "SplitBranch" ||
      ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}] ||
      ! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      epsilonMod === $Failed || epsilonMod === 0 || points === {} ||
      ! MatchQ[points, {{_Integer, _Integer} ..}] ||
      ! Between[threads, {1, 8}],
    Return[multiquadraticStripFailure[
      "InvalidNativePreflightBatchInput"]]];
  expressions = Join[squareRootRecordRadicand /@ provider["Roots"],
    {provider["GaugeDenominator"]}, provider["GaugeLogDerivatives"],
    Flatten[provider["RootLogDerivatives"]]];
  {compileSeconds, compiled} = AbsoluteTiming[
    multiquadraticStripScreenCompileScalar[#1, {}, {},
        Join[variables, {epsilon}], prime] & /@ expressions];
  If[! AllTrue[compiled, AssociationQ],
    Return[multiquadraticStripFailure[
      "NativePreflightCompileFailed"]]];
  nativePlan = <|"Prime" -> prime, "RootCount" -> rootCount,
    "Leaves" -> Map[<|"ActiveRoots" -> {}, "Compiled" -> #1|> &,
      compiled]|>;
  dummy = Map[<|"Status" -> "MultiquadraticProviderPreflightV1",
      "Prime" -> prime, "Point" -> Mod[#1, prime],
      "EpsilonMod" -> epsilonMod,
      "SquareRootGeneratorValues" ->
        ConstantArray[1, rootCount]|> &, points];
  native = multiquadraticStripNativeSparseEvaluateBatch[nativePlan, dummy,
    threads];
  If[Lookup[native, "Status", None] =!=
      "MultiquadraticNativeSparseBatchV1",
    Return[multiquadraticStripFailure[
      "NativePreflightEvaluationFailed",
      <|"Detail" -> native, "CompileSeconds" -> compileSeconds,
        "Seconds" -> N[AbsoluteTime[] - startTime]|>]]];
  values = native["Channels"][[All, All, 1]];
  decode[index_] := Module[{point = Mod[points[[index]], prime], scalars,
      deltas, denominator, gaugeLog, rootLog, splitQ, rootValues,
      failure},
    failure[status_String, data_: <||>] := multiquadraticStripFailure[status,
      Join[<|"Prime" -> prime, "RegulatorValue" -> epsilonValue,
        "Point" -> point, "PreflightRejected" -> True,
        "LargeEntryEvaluationCount" -> 0,
        "PreflightSeconds" -> perPointSeconds|>, data]];
    If[! VectorQ[native["LeafStatuses"][[index]], #1 === 0 &],
      Return[failure["RationalChannelPole"]]];
    scalars = values[[index]];
    deltas = Take[scalars, rootCount];
    denominator = scalars[[rootCount + 1]];
    gaugeLog = scalars[[rootCount + 2 ;; rootCount + 3]];
    rootLog = If[rootCount === 0, {},
      ArrayReshape[Drop[scalars, rootCount + 3], {rootCount, 2}]];
    If[MemberQ[deltas, 0],
      Return[failure["DegenerateRootImage",
        <|"QuadraticRadicandValues" -> deltas|>]]];
    If[denominator === 0,
      Return[failure["ZeroGaugeDenominator"]]];
    splitQ = AllTrue[deltas, modularResidueQ[#1, prime] &];
    If[! splitQ,
      Return[failure["PointNotSplitOverPrime",
        <|"QuadraticRadicandValues" -> deltas|>]]];
    rootValues = multiquadraticSquareRoots[deltas, prime];
    If[rootValues === $Failed,
      Return[failure["ModularSquareRootFailed"]]];
    <|"Status" -> "MultiquadraticProviderPreflightV1",
      "Provider" -> "SplitBranch",
      "CoefficientData" -> provider["CoefficientData"],
      "Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "EpsilonMod" -> epsilonMod, "Point" -> point,
      "ScalarRules" -> Join[AssociationThread[variables, point],
        <|epsilon -> epsilonMod|>],
      "QuadraticRadicands" -> deltas,
      "SquareRootGeneratorValues" -> rootValues,
      "SplitPointQ" -> True, "GaugeDenominator" -> denominator,
      "GaugeLogDerivatives" -> gaugeLog,
      "RootLogDerivatives" -> rootLog,
      "PreflightRejected" -> False, "LargeEntryEvaluationCount" -> 0,
      "PreflightSeconds" -> perPointSeconds|>];
  {decodeSeconds, records} = AbsoluteTiming[decode /@ Range[Length[points]]];
  <|"Status" -> "MultiquadraticNativePreflightBatchV1",
    "Records" -> records, "PointCount" -> Length[points],
    "ExpressionCount" -> Length[expressions],
    "CompileSeconds" -> compileSeconds,
    "NativeBatchSeconds" -> native["Seconds"],
    "DecodeSeconds" -> decodeSeconds,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripNativePreflightBatch[___] :=
  multiquadraticStripFailure["InvalidNativePreflightBatchArguments"];

multiquadraticStripNativeRowBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_row_assemble"}]}, If[FileExistsQ[file], file, None]];

multiquadraticStripNativeRowAssembleBatch[assembly_Association,
    coefficients_List, threads_Integer: 1] := Module[
  {startTime = AbsoluteTime[], binary, prime, rootCount, gradeCount,
   dimensions, upper, lower, support, oneFormCount, pointCount, rowCount,
   unknownCount, directory = None, inputFile, outputFile, stream = None,
   payload, process, magic, header, rows, right, writeSeconds = 0.,
   adapterSeconds = 0., readSeconds = 0., result, tag},
  tag = Unique["MultiquadraticNativeRowBatchFailure"];
  binary = multiquadraticStripNativeRowBinary[];
  prime = If[coefficients === {}, $Failed,
    Lookup[First[coefficients], "Prime", $Failed]];
  rootCount = Lookup[assembly, "RootCount", $Failed];
  gradeCount = If[IntegerQ[rootCount], 2^rootCount, 0];
  dimensions = Lookup[assembly, "Dimensions", $Failed];
  support = Lookup[assembly, "GaugeSupport", $Failed];
  oneFormCount = Length[Lookup[assembly, "OneForms", {}]];
  pointCount = Length[coefficients];
  If[! StringQ[binary] || ! Between[threads, {1, 8}] ||
      ! PrimeQ[prime] || ! IntegerQ[rootCount] ||
      ! Between[rootCount, {0, $multiquadraticStripMaximumRootCount}] ||
      ! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      ! MatchQ[support, {{_Integer?NonNegative, _Integer?NonNegative} ..}] ||
      pointCount < 1 || ! AllTrue[coefficients,
        Lookup[#1, "Status", None] ===
            "MultiquadraticPointCoefficientsV1" &&
          Lookup[#1, "Prime", None] === prime &],
    Return[multiquadraticStripFailure["InvalidNativeRowBatchInput"]]];
  {upper, lower} = dimensions;
  rowCount = gradeCount 2 upper lower;
  unknownCount = upper lower gradeCount Length[support] +
    oneFormCount upper lower;
  result = Catch[
    directory = CreateDirectory[];
    inputFile = FileNameJoin[{directory, "rows-input.bin"}];
    outputFile = FileNameJoin[{directory, "rows-output.bin"}];
    payload = Flatten[{
          Lookup[#1, "Point", {}], Lookup[#1,
            {"EpsilonMod", "GaugeDenominator"}, {$Failed, $Failed}],
          Lookup[#1, "QuadraticRadicands", {}],
          Lookup[#1, "GaugeLogDerivatives", {}],
          Lookup[#1, "RootLogDerivatives", {}], Lookup[#1, "E", {}],
          Lookup[#1, "C", {}], Lookup[#1, "BBar", {}],
          Lookup[#1, "OneForms", {}]}] & /@ coefficients;
    {writeSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenWrite[inputFile, BinaryFormat -> True];
      BinaryWrite[stream, ToCharacterCode["MQRA1V1\000"],
        "UnsignedInteger8"];
      BinaryWrite[stream, {prime, rootCount, upper, lower, Length[support],
          oneFormCount, pointCount}, "UnsignedInteger64",
        ByteOrdering -> -1];
      BinaryWrite[stream, Flatten[support], "UnsignedInteger64",
        ByteOrdering -> -1];
      BinaryWrite[stream, Flatten[payload], "UnsignedInteger64",
        ByteOrdering -> -1];
      Close[stream]; stream = None; True, False]]];
    If[! TrueQ[result],
      If[Head[stream] === OutputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeRowInputWriteFailed"], tag]];
    {adapterSeconds, process} = AbsoluteTiming[RunProcess[
      taskBrokerNativeCommand[
        {binary, inputFile, outputFile, ToString[threads]}, threads]]];
    If[! AssociationQ[process] || process["ExitCode"] =!= 0,
      Throw[multiquadraticStripFailure[
        "NativeRowAdapterFailed"], tag]];
    {readSeconds, result} = AbsoluteTiming[Quiet[Check[
      stream = OpenRead[outputFile, BinaryFormat -> True];
      magic = BinaryReadList[stream, "UnsignedInteger8", 8];
      header = BinaryReadList[stream, "UnsignedInteger64", 4,
        ByteOrdering -> -1];
      rows = BinaryReadList[stream, "UnsignedInteger64",
        pointCount rowCount unknownCount, ByteOrdering -> -1];
      right = BinaryReadList[stream, "UnsignedInteger64",
        pointCount rowCount, ByteOrdering -> -1];
      Close[stream]; stream = None;
      If[magic =!= ToCharacterCode["MQRA1X1\000"] ||
          header =!= {prime, pointCount, rowCount, unknownCount} ||
          Length[rows] =!= pointCount rowCount unknownCount ||
          Length[right] =!= pointCount rowCount, $Failed,
        <|"Status" -> "MultiquadraticNativeRowBatchV1",
          "Rows" -> ArrayReshape[rows,
            {pointCount, rowCount, unknownCount}],
          "RightHandSides" -> ArrayReshape[right,
            {pointCount, rowCount}], "Threads" -> threads|>], $Failed]]];
    If[! AssociationQ[result],
      If[Head[stream] === InputStream, Quiet[Close[stream]]];
      Throw[multiquadraticStripFailure[
        "NativeRowResponseInvalid"], tag]];
    Join[result, <|"InputWriteSeconds" -> writeSeconds,
      "AdapterSeconds" -> adapterSeconds,
      "ResponseReadSeconds" -> readSeconds|>],
    tag, #1 &];
  If[StringQ[directory] && DirectoryQ[directory],
    Quiet[DeleteDirectory[directory, DeleteContents -> True]]];
  If[AssociationQ[result],
    Append[result, "Seconds" -> N[AbsoluteTime[] - startTime]], result]
];
multiquadraticStripNativeRowAssembleBatch[___] :=
  multiquadraticStripFailure["InvalidNativeRowBatchArguments"];

multiquadraticStripPointResult[assembly_Association,
    coefficients_Association, rows_List, right_List, assemblySeconds_] :=
  <|"Status" -> "AssembledMultiquadraticPointV1",
    "CoefficientData" -> coefficients["CoefficientData"],
    "Prime" -> coefficients["Prime"],
    "Provider" -> Lookup[coefficients, "Provider", "CompiledChannel"],
    "EpsilonValue" -> Lookup[coefficients, "RegulatorValue",
      Missing["NoRegulatorValue"]],
    "EpsilonMod" -> coefficients["EpsilonMod"],
    "Point" -> coefficients["Point"],
    "QuadraticRadicandValues" -> coefficients["QuadraticRadicands"],
    "Rows" -> Developer`ToPackedArray[rows],
    "RightHandSide" -> Developer`ToPackedArray[right],
    "MatrixDimensions" -> Dimensions[rows],
    "Dimensions" -> assembly["Dimensions"],
    "RootCount" -> assembly["RootCount"],
    "GradeCount" -> assembly["GradeCount"],
    "EquationsPerGrade" -> 2 Times @@ assembly["Dimensions"],
    "UnknownCount" -> assembly["UnknownCount"],
    "RowBasis" -> "MultiquadraticGradeBasis",
    "AssemblySeconds" -> assemblySeconds|>;
multiquadraticStripPointResult[___] :=
  multiquadraticStripFailure["InvalidPointResultArguments"];

(* Cheap validated point preflight.  It evaluates only the root
   squares, the gauge denominator and their logarithmic derivatives.  A
   split provider rejects a nonsplit point here, before one large matrix
   entry is touched.  The returned primitives are reused by the full
   coefficient evaluation. *)
multiquadraticStripProviderPreflight[provider_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer}] := Module[
  {startTime = AbsoluteTime[], kind, roots, rank, variables, epsilon,
   epsilonMod, scalarRules, evaluateScalar, deltaValues, denominatorValue,
   gaugeLogValues, rootLogValues, splitQ, rootValues, assembly,
   epsilonForms, forms, imagePolynomials, requiredXExponents,
   requiredYExponents, x, y, xPowers, yPowers, primitiveForms,
   primitiveEvaluated, failure},
  failure[status_String, data_: <||>] := multiquadraticStripFailure[status,
    Join[<|"Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "Point" -> Mod[point, prime], "PreflightRejected" -> True,
      "LargeEntryEvaluationCount" -> 0,
      "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>, data]];
  If[! multiquadraticStripProviderEvaluationValidQ[provider],
    Return[failure["InvalidCoefficientProvider"]]];
  If[! PrimeQ[prime] ||
      ! (3 < prime < $multiquadraticStripWordPrimeLimit),
    Return[failure["InvalidPrime"]]];
  epsilonMod = multiquadraticStripModRational[epsilonValue, prime];
  If[epsilonMod === $Failed || epsilonMod === 0,
    Return[failure["BadPrimeForRegulatorValue"]]];
  If[MemberQ[Mod[point, prime], 0],
    Return[failure["ZeroPointCoordinate"]]];
  kind = provider["Kind"];
  If[kind === "CompiledChannel",
    assembly = provider["Assembly"];
    epsilonForms = multiquadraticStripCollapseEpsilon[assembly, prime,
      epsilonValue];
    If[Lookup[epsilonForms, "Status", None] =!=
          "MultiquadraticStripEpsilonFormsV1" ||
        ! multiquadraticStripEpsilonFormsValidQ[assembly, epsilonForms,
          prime], Return[failure["RegulatorFormsInvalid"]]];
    forms = epsilonForms["Forms"];
    imagePolynomials = Cases[forms, association_Association /;
      Lookup[association, "Type", None] ===
        "MultiquadraticPolynomialImageV1" :> association, {0, Infinity}];
    requiredXExponents = Union[assembly["GaugeSupport"][[All, 1]],
      Flatten[Lookup[imagePolynomials, "XExponents", {}]]];
    requiredYExponents = Union[assembly["GaugeSupport"][[All, 2]],
      Flatten[Lookup[imagePolynomials, "YExponents", {}]]];
    {x, y} = Mod[point, prime];
    xPowers = AssociationThread[requiredXExponents,
      PowerMod[x, #1, prime] & /@ requiredXExponents];
    yPowers = AssociationThread[requiredYExponents,
      PowerMod[y, #1, prime] & /@ requiredYExponents];
    primitiveForms = KeyTake[forms, {"RootSquares", "GaugeDenominator"}];
    primitiveEvaluated = Catch[multiquadraticStripEvaluateForms[
      primitiveForms, xPowers, yPowers, prime],
      "MultiquadraticStripBadPoint"];
    If[! AssociationQ[primitiveEvaluated],
      Return[failure["RationalChannelPole"]]];
    deltaValues = primitiveEvaluated["RootSquares"];
    denominatorValue = primitiveEvaluated["GaugeDenominator"];
    If[! VectorQ[deltaValues, IntegerQ] ||
        Length[deltaValues] =!= assembly["RootCount"] ||
        MemberQ[deltaValues, 0],
      Return[failure["DegenerateRootImage",
        <|"DeltaValues" -> deltaValues|>]]];
    If[! IntegerQ[denominatorValue] || denominatorValue === 0,
      Return[failure["ZeroGaugeDenominator"]]];
    splitQ = AllTrue[deltaValues, modularResidueQ[#1, prime] &];
    Return[<|"Status" -> "MultiquadraticProviderPreflightV1",
      "Provider" -> kind,
      "CoefficientData" -> provider["CoefficientData"],
      "Prime" -> prime, "RegulatorValue" -> epsilonValue,
      "EpsilonMod" -> epsilonMod, "Point" -> {x, y},
      "QuadraticRadicands" -> deltaValues,
      "SquareRootGeneratorValues" -> If[splitQ,
        multiquadraticSquareRoots[deltaValues, prime],
        ConstantArray[0, Length[deltaValues]]],
      "SplitPointQ" -> splitQ,
      "GaugeDenominator" -> denominatorValue,
      "EpsilonForms" -> epsilonForms, "XPowers" -> xPowers,
      "YPowers" -> yPowers, "PrimitiveValues" -> primitiveEvaluated,
      "PreflightRejected" -> False, "LargeEntryEvaluationCount" -> 0,
      "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>]];
  roots = provider["Roots"];
  rank = provider["RootCount"];
  variables = provider["Variables"];
  epsilon = provider["Regulator"];
  scalarRules = Join[AssociationThread[variables, Mod[point, prime]],
    <|epsilon -> epsilonMod|>];
  evaluateScalar[expression_] := Module[{evaluated},
    evaluated = multiquadraticStripModularGradeEvaluate[expression,
      scalarRules, {}, {}, prime];
    If[Lookup[evaluated, "Status", None] =!= "OK", $Failed,
      First[evaluated["Channels"]]]];
  deltaValues = Table[evaluateScalar[
      squareRootRecordRadicand[roots[[k]]]],
    {k, rank}];
  If[MemberQ[deltaValues, $Failed],
    Return[failure["QuadraticRadicandNotEvaluable",
      <|"SquareRootGeneratorIndices" ->
        Flatten[Position[deltaValues, $Failed]]|>]]];
  If[MemberQ[deltaValues, 0],
    Return[failure["DegenerateRootImage",
      <|"DeltaValues" -> deltaValues|>]]];
  denominatorValue = evaluateScalar[provider["GaugeDenominator"]];
  If[denominatorValue === $Failed || denominatorValue === 0,
    Return[failure["ZeroGaugeDenominator"]]];
  gaugeLogValues = evaluateScalar /@ provider["GaugeLogDerivatives"];
  rootLogValues = Map[evaluateScalar, provider["RootLogDerivatives"], {2}];
  If[MemberQ[Flatten[{gaugeLogValues, rootLogValues}], $Failed],
    Return[failure["RationalChannelPole"]]];
  splitQ = AllTrue[deltaValues, modularResidueQ[#1, prime] &];
  If[kind === "SplitBranch" && ! splitQ,
    Return[failure["PointNotSplitOverPrime",
      <|"DeltaValues" -> deltaValues|>]]];
  rootValues = If[splitQ, multiquadraticSquareRoots[deltaValues, prime],
    ConstantArray[0, rank]];
  If[splitQ && rootValues === $Failed,
    Return[failure["ModularSquareRootFailed"]]];
  <|"Status" -> "MultiquadraticProviderPreflightV1",
    "Provider" -> kind,
    "CoefficientData" -> provider["CoefficientData"],
    "Prime" -> prime, "RegulatorValue" -> epsilonValue,
    "EpsilonMod" -> epsilonMod, "Point" -> Mod[point, prime],
    "ScalarRules" -> scalarRules, "QuadraticRadicands" -> deltaValues,
    "SquareRootGeneratorValues" -> rootValues, "SplitPointQ" -> splitQ,
    "GaugeDenominator" -> denominatorValue,
    "GaugeLogDerivatives" -> gaugeLogValues,
    "RootLogDerivatives" -> rootLogValues,
    "PreflightRejected" -> False, "LargeEntryEvaluationCount" -> 0,
    "PreflightSeconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripProviderPreflight[___] :=
  multiquadraticStripFailure["InvalidProviderPreflightArguments"];

(* The compiled oracle now produces the same coefficient record as the
   direct providers and reaches the same row assembler. *)
multiquadraticStripCompiledProviderChannels[provider_Association,
    preflight_Association] := Module[
  {startTime = AbsoluteTime[], assembly, prime, forms, evaluated,
   remaining, coefficients, entryCount},
  If[! multiquadraticStripProviderEvaluationValidQ[provider] ||
      provider["Kind"] =!= "CompiledChannel" ||
      Lookup[preflight, "Status", None] =!=
        "MultiquadraticProviderPreflightV1" ||
      ! SameQ[Lookup[preflight, "CoefficientData", None],
        provider["CoefficientData"]],
    Return[multiquadraticStripFailure["InvalidCompiledProviderPreflight"]]];
  assembly = provider["Assembly"];
  prime = preflight["Prime"];
  forms = preflight["EpsilonForms"]["Forms"];
  remaining = KeyDrop[forms, {"RootSquares", "GaugeDenominator"}];
  evaluated = Catch[multiquadraticStripEvaluateForms[remaining,
    preflight["XPowers"], preflight["YPowers"], prime],
    "MultiquadraticStripBadPoint"];
  If[! AssociationQ[evaluated],
    Return[multiquadraticStripFailure["RationalChannelPole",
      <|"Prime" -> prime, "Point" -> preflight["Point"],
        "LargeEntryEvaluationCount" -> 0|>]]];
  evaluated = Join[preflight["PrimitiveValues"], evaluated];
  entryCount = Total[Times @@ Dimensions[#1] & /@
    Lookup[evaluated, {"E", "C", "BBar", "OneForms"}, {}]];
  coefficients = <|"Status" -> "MultiquadraticPointCoefficientsV1",
    "Provider" -> "CompiledChannel", "Prime" -> prime,
    "Point" -> preflight["Point"],
    "RegulatorValue" -> preflight["RegulatorValue"],
    "EpsilonMod" -> preflight["EpsilonMod"],
    "QuadraticRadicands" -> preflight["QuadraticRadicands"],
    "SquareRootGeneratorValues" ->
      preflight["SquareRootGeneratorValues"],
    "SplitPointQ" -> preflight["SplitPointQ"],
    "GaugeDenominator" -> preflight["GaugeDenominator"],
    "GaugeLogDerivatives" -> evaluated["GaugeLogDerivatives"],
    "RootLogDerivatives" -> evaluated["RootLogDerivatives"],
    "E" -> evaluated["E"], "C" -> evaluated["C"],
    "BBar" -> evaluated["BBar"], "OneForms" -> evaluated["OneForms"],
    "CoefficientData" -> provider["CoefficientData"],
    "PreflightSeconds" -> preflight["PreflightSeconds"],
    "LargeEntryEvaluationCount" -> entryCount,
    "EntryEvaluationCount" -> entryCount,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>;
  coefficients
];
multiquadraticStripCompiledProviderChannels[___] :=
  multiquadraticStripFailure["InvalidCompiledProviderChannelArguments"];

(* Evaluate the deferred forcing DAG at one validated point.  SplitBranch
   evaluates each operand and coefficient only on the sign orbit of its local
   active subfield, lifts those channels to the global grade order, and assembles jobs
   with quotient-algebra multiplication.  Thus a root-free operand costs one
   scalar image and a rank-one operand costs two even in a rank-three frame.
   QuotientGrade retains its existing one-grade-evaluation-per-entry route.
   No dense symbolic BBar and no Together over a target entry is formed. *)
multiquadraticStripBundleProviderChannels[provider_Association,
    preflight_Association, splitPlan_: Automatic,
    plannedLeafChannels_: Automatic] := Catch[Module[
  {startTime = AbsoluteTime[], bundle = provider["DeferredBundle"],
   expressions, operandActiveRoots, coefficientExpressions,
   coefficientActiveRoots, jobs, dimensions, roots = provider["Roots"],
   rank, gradeCount, prime, scalarRules, deltaValues, rootValues, kind, tag,
   evaluateSplit, operandValues, targetChannels, radicalRules,
   evaluateGrade, coefficientValues, multiply, zero, termProducts,
   evaluationCount = 0, coefficientCount = 0,
   operandScalarCount = 0, coefficientScalarCount = 0,
   globalSheetScalarCount = 0, splitCompileAttempts = 0,
   splitCompileCacheHits = 0, splitCompileCacheMisses = 0,
   splitSparseSuccesses = 0, splitSubstitutionFallbacks = 0,
   splitCompileSeconds = 0., splitEvaluationSeconds = 0.,
   splitFallbackSeconds = 0., plannedQ, occurrenceMaps,
   operandIndices, coefficientIndices, gatherSeconds = 0.,
   compositionSeconds = 0.},
  tag = Unique["MultiquadraticBundleProviderFailure"];
  If[! multiquadraticStripProviderEvaluationValidQ[provider] ||
      ! AssociationQ[bundle],
    Throw[multiquadraticStripFailure["InvalidDeferredBundle"], tag]];
  expressions = provider["BundleOperandExpressions"];
  operandActiveRoots = provider["BundleOperandActiveRoots"];
  coefficientExpressions = provider["BundleCoefficientExpressions"];
  coefficientActiveRoots = provider["BundleCoefficientActiveRoots"];
  jobs = bundle["Jobs"];
  dimensions = bundle["Dimensions"];
  rank = provider["RootCount"]; gradeCount = provider["GradeCount"];
  prime = preflight["Prime"]; scalarRules = preflight["ScalarRules"];
  deltaValues = preflight["QuadraticRadicands"];
  rootValues = preflight["SquareRootGeneratorValues"];
  kind = provider["Kind"];
  plannedQ = splitPlan =!= Automatic;
  If[plannedQ,
    If[kind =!= "SplitBranch" ||
        ! multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ[
          splitPlan, provider, prime] ||
        ! ListQ[plannedLeafChannels] ||
        Length[plannedLeafChannels] =!= Length[splitPlan["Leaves"]] ||
        ! AllTrue[plannedLeafChannels,
          VectorQ[#1, IntegerQ] && Length[#1] === gradeCount &],
      Throw[multiquadraticStripFailure[
        "InvalidBundleSplitSparseEvaluationPlan"], tag]];
    occurrenceMaps = splitPlan["OccurrenceMaps"];
    operandIndices = occurrenceMaps["BundleOperands"];
    coefficientIndices = occurrenceMaps["BundleCoefficients"];
    {gatherSeconds, {operandValues, coefficientValues}} = AbsoluteTiming[{
      Map[plannedLeafChannels[[#1]] &, operandIndices],
      Map[plannedLeafChannels[[#1]] &, coefficientIndices, {2}]}];
    operandScalarCount = Total[2^Length[
        splitPlan["Leaves"][[#1, "ActiveRoots"]]] & /@ operandIndices];
    coefficientScalarCount = Total[2^Length[
        splitPlan["Leaves"][[#1, "ActiveRoots"]]] & /@
      Flatten[coefficientIndices]];
    evaluationCount = Length[operandIndices];
    coefficientCount = Length[Flatten[coefficientIndices]];
    globalSheetScalarCount = gradeCount (evaluationCount + coefficientCount);
    zero = ConstantArray[0, gradeCount];
    multiply[left_, right_] := Module[{product =
        multiquadraticMultiply[left, right, deltaValues, prime]},
      If[! ListQ[product],
        Throw[multiquadraticStripFailure[
          "BundleQuotientProductFailed"], tag]];
      Mod[product, prime]];
    {compositionSeconds, targetChannels} = AbsoluteTiming[Table[
      termProducts = Table[
        Fold[multiply, coefficientValues[[jobIndex, termIndex]],
          operandValues[[Last[jobs[[jobIndex, "Terms", termIndex]]]]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}];
      Fold[Mod[#1 + #2, prime] &, zero, termProducts],
      {jobIndex, Length[jobs]}]];
    Return[<|"Status" -> "MultiquadraticBundleChannelsV1",
      "BBar" -> ArrayReshape[targetChannels,
        Append[dimensions, gradeCount]],
      "OperandEvaluationCount" -> operandScalarCount,
      "CoefficientEvaluationCount" -> coefficientScalarCount,
      "OperandEntryEvaluationCount" -> evaluationCount,
      "CoefficientEntryEvaluationCount" -> coefficientCount,
      "OperandScalarBranchEvaluationCount" -> operandScalarCount,
      "CoefficientScalarBranchEvaluationCount" -> coefficientScalarCount,
      "ScalarBranchEvaluationCount" ->
        operandScalarCount + coefficientScalarCount,
      "GlobalSheetScalarBranchEvaluationCount" -> globalSheetScalarCount,
      "ScalarBranchEvaluationReduction" -> globalSheetScalarCount -
        operandScalarCount - coefficientScalarCount,
      "SplitSparseCompileAttemptCount" -> 0,
      "SplitSparseCompileCacheHitCount" -> 0,
      "SplitSparseCompileCacheMissCount" -> 0,
      "SplitSparseEvaluationCount" -> 0,
      "SplitSubstitutionFallbackCount" -> 0,
      "SplitSparseCompileSeconds" -> 0.,
      "SplitSparseEvaluationSeconds" -> 0.,
      "SplitSubstitutionFallbackSeconds" -> 0.,
      "OccurrenceGatherSeconds" -> gatherSeconds,
      "CompositionSeconds" -> compositionSeconds,
      "OperandLocalRankHistogram" -> Counts[Length /@ operandActiveRoots],
      "CoefficientLocalRankHistogram" -> Counts[
        Length /@ Flatten[coefficientActiveRoots, 1]],
      "Seconds" -> N[AbsoluteTime[] - startTime]|>]];
  zero = ConstantArray[0, gradeCount];
  multiply[left_, right_] := Module[{product =
      multiquadraticMultiply[left, right, deltaValues, prime]},
    If[! ListQ[product],
      Throw[multiquadraticStripFailure[
        "BundleQuotientProductFailed"], tag]];
    Mod[product, prime]];
  If[kind === "SplitBranch",
    If[! TrueQ[preflight["SplitPointQ"]],
      Throw[multiquadraticStripFailure["PointNotSplitOverPrime",
        <|"LargeEntryEvaluationCount" -> 0|>], tag]];
    evaluateSplit[expression_, activeIndices_List, role_String] := Module[
      {result, scalarCount},
      result = multiquadraticStripSplitBranchEntry[expression, roots,
        activeIndices, scalarRules, deltaValues, rootValues, prime];
      If[Lookup[result, "Status", None] =!= "OK",
        Throw[Join[multiquadraticStripFailure[
          "BundleSplitEvaluationFailed"],
          <|"Role" -> role, "Detail" -> result|>], tag]];
      scalarCount = Length[Lookup[result, "BranchValues", {}]];
      If[scalarCount =!= 2^Length[activeIndices],
        Throw[multiquadraticStripFailure[
          "BundleSplitEvaluationTelemetryInvalid"], tag]];
      splitCompileAttempts++;
      If[TrueQ[Lookup[result, "SparseCompileCacheHit", False]],
        splitCompileCacheHits++, splitCompileCacheMisses++];
      If[Lookup[result, "Method", None] === "SparseRootPlaceholder",
        splitSparseSuccesses++, splitSubstitutionFallbacks++];
      splitCompileSeconds += Lookup[result, "SparseCompileSeconds", 0.];
      splitEvaluationSeconds += Lookup[result,
        "SparseEvaluationSeconds", 0.];
      splitFallbackSeconds += Lookup[result,
        "SubstitutionFallbackSeconds", 0.];
      If[role === "Operand",
        evaluationCount++; operandScalarCount += scalarCount,
        coefficientCount++; coefficientScalarCount += scalarCount];
      result["Channels"]];
    operandValues = Table[evaluateSplit[expressions[[id]],
        operandActiveRoots[[id]], "Operand"],
      {id, Length[expressions]}];
    coefficientValues = Table[Table[evaluateSplit[
          coefficientExpressions[[jobIndex, termIndex]],
          coefficientActiveRoots[[jobIndex, termIndex]], "Coefficient"],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}],
      {jobIndex, Length[jobs]}];
    targetChannels = Table[
      termProducts = Table[
        Fold[multiply, coefficientValues[[jobIndex, termIndex]],
          operandValues[[Last[jobs[[jobIndex, "Terms", termIndex]]]]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}];
      Fold[Mod[#1 + #2, prime] &, zero, termProducts],
      {jobIndex, Length[jobs]}];
    globalSheetScalarCount = gradeCount (evaluationCount + coefficientCount),
    radicalRules = Table[
      {squareRootRecordRadicand[roots[[k]]],
        UnitVector[gradeCount, 2^(k - 1) + 1]},
      {k, rank}];
    evaluateGrade[expression_] := Module[{evaluated},
      evaluated = multiquadraticStripModularGradeEvaluate[expression,
        scalarRules, radicalRules, deltaValues, prime];
      If[Lookup[evaluated, "Status", None] =!= "OK",
        Throw[Join[multiquadraticStripFailure[
          "BundleQuotientEvaluationFailed"], <|"Detail" -> evaluated|>],
          tag]];
      evaluated["Channels"]];
    operandValues = Table[evaluationCount++; evaluateGrade[expression],
      {expression, expressions}];
    coefficientValues = Table[Table[coefficientCount++;
        evaluateGrade[coefficientExpressions[[jobIndex, termIndex]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}],
      {jobIndex, Length[jobs]}];
    targetChannels = Table[
      termProducts = Table[
        Fold[multiply, coefficientValues[[jobIndex, termIndex]],
          operandValues[[Last[jobs[[jobIndex, "Terms", termIndex]]]]]],
        {termIndex, Length[jobs[[jobIndex, "Terms"]]]}];
      Fold[Mod[#1 + #2, prime] &, zero, termProducts],
      {jobIndex, Length[jobs]}]];
  <|"Status" -> "MultiquadraticBundleChannelsV1",
    "BBar" -> ArrayReshape[targetChannels,
      Append[dimensions, gradeCount]],
    (* Historical counts continue to mean actual scalar work on the split
       route; explicit entry counts remove any ambiguity for telemetry. *)
    "OperandEvaluationCount" -> If[kind === "SplitBranch",
      operandScalarCount, evaluationCount],
    "CoefficientEvaluationCount" -> If[kind === "SplitBranch",
      coefficientScalarCount, coefficientCount],
    "OperandEntryEvaluationCount" -> evaluationCount,
    "CoefficientEntryEvaluationCount" -> coefficientCount,
    "OperandScalarBranchEvaluationCount" -> operandScalarCount,
    "CoefficientScalarBranchEvaluationCount" -> coefficientScalarCount,
    "ScalarBranchEvaluationCount" ->
      operandScalarCount + coefficientScalarCount,
    "GlobalSheetScalarBranchEvaluationCount" -> globalSheetScalarCount,
    "ScalarBranchEvaluationReduction" ->
      globalSheetScalarCount - operandScalarCount - coefficientScalarCount,
    "SplitSparseCompileAttemptCount" -> splitCompileAttempts,
    "SplitSparseCompileCacheHitCount" -> splitCompileCacheHits,
    "SplitSparseCompileCacheMissCount" -> splitCompileCacheMisses,
    "SplitSparseEvaluationCount" -> splitSparseSuccesses,
    "SplitSubstitutionFallbackCount" -> splitSubstitutionFallbacks,
    "SplitSparseCompileSeconds" -> splitCompileSeconds,
    "SplitSparseEvaluationSeconds" -> splitEvaluationSeconds,
    "SplitSubstitutionFallbackSeconds" -> splitFallbackSeconds,
    "OperandLocalRankHistogram" -> Counts[Length /@ operandActiveRoots],
    "CoefficientLocalRankHistogram" -> Counts[
      Length /@ Flatten[coefficientActiveRoots, 1]],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
], tag, #1 &];
multiquadraticStripBundleProviderChannels[___] :=
  multiquadraticStripFailure["InvalidBundleProviderArguments"];

(* Planned SplitBranch evaluation visits every unique leaf exactly once, then
   gathers all E/C/BBar/one-form and deferred-DAG occurrences by integer map.
   No expression, active-root list, or cache key is hashed on this path. *)
multiquadraticStripPlannedProviderChannels[provider_Association,
    preflight_Association, plan_Association,
    suppliedLeafChannels_: Automatic] := Module[
  {startTime = AbsoluteTime[], prime = Lookup[preflight, "Prime", $Failed],
   scalarRules, deltaValues, rootValues, leafEvaluationSeconds,
   leafResults, badIndex, bad, leafChannels, maps, gatherSeconds,
   values, oneFormValues, bundleChannels = None, entryKeys,
   sparseCount, nativeCount, fallbackCount, sparseSeconds, fallbackSeconds,
   bundleGatherSeconds = 0., bundleCompositionSeconds = 0.,
   occurrenceCount, entryCount},
  If[Lookup[preflight, "Status", None] =!=
        "MultiquadraticProviderPreflightV1" ||
      ! SameQ[Lookup[preflight, "CoefficientData", None],
        Lookup[provider, "CoefficientData", None]] ||
      ! multiquadraticStripSplitSparseEvaluationPlanEvaluationValidQ[
        plan, provider, prime],
    Return[multiquadraticStripFailure[
      "InvalidSplitSparseEvaluationPlan"]]];
  scalarRules = preflight["ScalarRules"];
  deltaValues = preflight["QuadraticRadicands"];
  rootValues = preflight["SquareRootGeneratorValues"];
  If[suppliedLeafChannels === Automatic,
    {leafEvaluationSeconds, leafResults} = AbsoluteTiming[MapIndexed[
      multiquadraticStripSplitSparsePlannedEntry[plan, First[#2], provider,
        scalarRules, deltaValues, rootValues, prime] &, plan["Leaves"]]],
    If[! ListQ[suppliedLeafChannels] ||
        Length[suppliedLeafChannels] =!= Length[plan["Leaves"]] ||
        ! AllTrue[suppliedLeafChannels,
          VectorQ[#1, IntegerQ] &&
            Length[#1] === provider["GradeCount"] &],
      Return[multiquadraticStripFailure[
        "InvalidNativeSparseLeafChannels"]]];
    leafEvaluationSeconds = 0.;
    leafResults = Map[<|"Status" -> "OK", "Channels" -> #1,
        "Method" -> "NativeSparseBatch", "SparseEvaluationSeconds" -> 0.,
        "SubstitutionFallbackSeconds" -> 0.|> &,
      suppliedLeafChannels]];
  badIndex = SelectFirst[Range[Length[leafResults]],
    Lookup[leafResults[[#1]], "Status", None] =!= "OK" &,
    Missing["NotFound"]];
  If[! MissingQ[badIndex],
    bad = leafResults[[badIndex]];
    Return[Join[<|"Status" -> Lookup[bad, "Status",
          "SplitSparsePlannedLeafFailed"],
        "SplitSparsePlanLeafIndex" -> badIndex,
        "Prime" -> prime,
        "RegulatorValue" -> preflight["RegulatorValue"],
        "Point" -> preflight["Point"],
        "LargeEntryEvaluationCount" -> 0|>,
      KeyDrop[bad, "Status"]]]];
  leafChannels = Lookup[leafResults, "Channels"];
  maps = plan["OccurrenceMaps"];
  entryKeys = Keys[provider["Entries"]];
  {gatherSeconds, {values, oneFormValues}} = AbsoluteTiming[{
    Association[Table[key -> Map[leafChannels[[#1]] &,
      maps["Entries"][key], {3}], {key, entryKeys}]],
    If[provider["OneForms"] === {}, {},
      Map[leafChannels[[#1]] &, maps["OneForms"], {2}]]}];
  If[AssociationQ[Lookup[provider, "DeferredBundle", None]],
    bundleChannels = multiquadraticStripBundleProviderChannels[provider,
      preflight, plan, leafChannels];
    If[Lookup[bundleChannels, "Status", None] =!=
        "MultiquadraticBundleChannelsV1", Return[bundleChannels]];
    AssociateTo[values, "BBar" -> bundleChannels["BBar"]];
    bundleGatherSeconds = Lookup[bundleChannels,
      "OccurrenceGatherSeconds", 0.];
    bundleCompositionSeconds = Lookup[bundleChannels,
      "CompositionSeconds", 0.]];
  sparseCount = Count[Lookup[leafResults, "Method", None],
    "SparseRootPlaceholder" | "NativeSparseBatch"];
  nativeCount = Count[Lookup[leafResults, "Method", None],
    "NativeSparseBatch"];
  fallbackCount = Length[leafResults] - sparseCount;
  sparseSeconds = Total[Lookup[leafResults, "SparseEvaluationSeconds", 0.]];
  fallbackSeconds = Total[Lookup[leafResults,
    "SubstitutionFallbackSeconds", 0.]];
  occurrenceCount = plan["OccurrenceCount"];
  entryCount = occurrenceCount;
  <|"Status" -> "MultiquadraticPointCoefficientsV1",
    "Provider" -> "SplitBranch", "Prime" -> prime,
    "Point" -> preflight["Point"],
    "RegulatorValue" -> preflight["RegulatorValue"],
    "EpsilonMod" -> preflight["EpsilonMod"],
    "QuadraticRadicands" -> deltaValues,
    "SquareRootGeneratorValues" -> rootValues,
    "SplitPointQ" -> preflight["SplitPointQ"],
    "GaugeDenominator" -> preflight["GaugeDenominator"],
    "GaugeLogDerivatives" -> preflight["GaugeLogDerivatives"],
    "RootLogDerivatives" -> preflight["RootLogDerivatives"],
    "E" -> values["E"], "C" -> values["C"],
    "BBar" -> values["BBar"], "OneForms" -> oneFormValues,
    "CoefficientData" -> provider["CoefficientData"],
    "BundleOperandEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "OperandEvaluationCount", 0], 0],
    "BundleCoefficientEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "CoefficientEvaluationCount", 0], 0],
    "BundleOperandEntryEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "OperandEntryEvaluationCount", 0], 0],
    "BundleCoefficientEntryEvaluationCount" -> If[
      AssociationQ[bundleChannels],
      Lookup[bundleChannels, "CoefficientEntryEvaluationCount", 0], 0],
    "BundleOperandScalarBranchEvaluationCount" -> If[
      AssociationQ[bundleChannels], Lookup[bundleChannels,
        "OperandScalarBranchEvaluationCount", 0], 0],
    "BundleCoefficientScalarBranchEvaluationCount" -> If[
      AssociationQ[bundleChannels], Lookup[bundleChannels,
        "CoefficientScalarBranchEvaluationCount", 0], 0],
    "BundleScalarBranchEvaluationCount" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "ScalarBranchEvaluationCount", 0], 0],
    "BundleGlobalSheetScalarBranchEvaluationCount" -> If[
      AssociationQ[bundleChannels], Lookup[bundleChannels,
        "GlobalSheetScalarBranchEvaluationCount", 0], 0],
    "BundleScalarBranchEvaluationReduction" -> If[
      AssociationQ[bundleChannels],
      Lookup[bundleChannels, "ScalarBranchEvaluationReduction", 0], 0],
    "BundleEvaluationSeconds" -> If[AssociationQ[bundleChannels],
      Lookup[bundleChannels, "Seconds", 0], 0],
    "SplitSparseCompileAttemptCount" -> 0,
    "SplitSparseCompileCacheHitCount" -> 0,
    "SplitSparseCompileCacheMissCount" -> 0,
    "SplitSparseEvaluationCount" -> sparseCount,
    "SplitSparseNativeEvaluationCount" -> nativeCount,
    "SplitSubstitutionFallbackCount" -> fallbackCount,
    "SplitSparseCompileSeconds" -> 0.,
    "SplitSparseEvaluationSeconds" -> sparseSeconds,
    "SplitSubstitutionFallbackSeconds" -> fallbackSeconds,
    "SplitSparseUniqueLeafCount" -> Length[plan["Leaves"]],
    "SplitSparseOccurrenceCount" -> occurrenceCount,
    "SplitSparseUniqueLeafEvaluationSeconds" -> leafEvaluationSeconds,
    "SplitSparseOccurrenceGatherSeconds" ->
      gatherSeconds + bundleGatherSeconds,
    "SplitSparseDeferredBundleCompositionSeconds" ->
      bundleCompositionSeconds,
    "PreflightSeconds" -> preflight["PreflightSeconds"],
    "LargeEntryEvaluationCount" -> entryCount,
    "EntryEvaluationCount" -> entryCount,
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripPlannedProviderChannels[___] :=
  multiquadraticStripFailure[
    "InvalidPlannedProviderChannelArguments"];

(* ONE point, ONE regulator image, ONE prime: every coefficient value the
   row assembler consumes.  Four arguments construct the validated
   preflight; the five-argument form reuses one already drawn by the
   sampler.  A typed rejection of the point is never a zero value. *)
multiquadraticStripProviderChannels[provider_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer}] := Module[{preflight},
  If[! multiquadraticStripProviderValidQ[provider],
    Return[multiquadraticStripFailure["InvalidCoefficientProvider"]]];
  preflight = multiquadraticStripProviderPreflight[provider, epsilonValue,
    prime, point];
  If[Lookup[preflight, "Status", None] =!=
      "MultiquadraticProviderPreflightV1", preflight,
    multiquadraticStripProviderChannels[provider, epsilonValue, prime,
      point, preflight]]
];

multiquadraticStripProviderChannels[provider_Association, epsilonValue_,
    prime_Integer, point : {_Integer, _Integer},
    preflight_Association, splitPlan_: Automatic,
    forcingMode_: Automatic] := Module[
  {startTime = AbsoluteTime[], roots, rank, kind, scalarRules, deltaValues,
    rootValues, evaluateEntry, values, oneFormValues, entryCount = 0,
    tag, evaluated, entryKeys, bundleChannels,
    nativeDeferredForcingQ,
    splitCompileAttempts = 0, splitCompileCacheHits = 0,
    splitCompileCacheMisses = 0, splitSparseSuccesses = 0,
    splitSubstitutionFallbacks = 0, splitCompileSeconds = 0.,
    splitEvaluationSeconds = 0., splitFallbackSeconds = 0.},
  If[Lookup[preflight, "Status", None] =!=
        "MultiquadraticProviderPreflightV1" ||
      ! SameQ[Lookup[preflight, "CoefficientData", None],
        Lookup[provider, "CoefficientData", None]] ||
      Lookup[preflight, "Prime", None] =!= prime ||
      Lookup[preflight, "RegulatorValue", None] =!= epsilonValue ||
      Lookup[preflight, "Point", None] =!= Mod[point, prime],
    Return[multiquadraticStripFailure["ProviderPreflightMismatch"]]];
  If[Lookup[provider, "Kind", None] === "CompiledChannel",
    If[splitPlan =!= Automatic,
      Return[multiquadraticStripFailure[
        "SplitSparseEvaluationPlanNotApplicable"]]];
    Return[multiquadraticStripCompiledProviderChannels[provider, preflight]]];
  If[! multiquadraticStripProviderEvaluationValidQ[provider],
    Return[multiquadraticStripFailure["InvalidDirectProvider"]]];
  roots = provider["Roots"];
  rank = provider["RootCount"];
  kind = provider["Kind"];
  nativeDeferredForcingQ = forcingMode === "NativeDeferredAST" &&
    AssociationQ[Lookup[provider, "DeferredPreparation", None]];
  If[splitPlan =!= Automatic,
    If[kind =!= "SplitBranch",
      Return[multiquadraticStripFailure[
        "SplitSparseEvaluationPlanNotApplicable"]]];
    Return[multiquadraticStripPlannedProviderChannels[provider, preflight,
      splitPlan]]];
  scalarRules = preflight["ScalarRules"];
  deltaValues = preflight["QuadraticRadicands"];
  rootValues = preflight["SquareRootGeneratorValues"];
  tag = Unique["MultiquadraticDirectProviderEntryFailure"];
  evaluateEntry[entry_, activeIndices_] := Module[{result},
    entryCount++;
    result = If[kind === "SplitBranch",
      multiquadraticStripSplitBranchEntry[entry, roots, activeIndices,
        scalarRules, deltaValues, rootValues, prime],
      multiquadraticStripQuotientGradeEntry[entry, roots, activeIndices,
        scalarRules, deltaValues, prime]];
    If[Lookup[result, "Status", None] =!= "OK",
      Throw[Join[<|"Status" -> Lookup[result, "Status",
          "ProviderRejected"], "Point" -> Mod[point, prime],
        "Prime" -> prime, "RegulatorValue" -> epsilonValue,
        "LargeEntryEvaluationCount" -> entryCount|>,
        KeyDrop[result, "Status"]], tag]];
    If[kind === "SplitBranch",
      splitCompileAttempts++;
      If[TrueQ[Lookup[result, "SparseCompileCacheHit", False]],
        splitCompileCacheHits++, splitCompileCacheMisses++];
      If[Lookup[result, "Method", None] === "SparseRootPlaceholder",
        splitSparseSuccesses++, splitSubstitutionFallbacks++];
      splitCompileSeconds += Lookup[result, "SparseCompileSeconds", 0.];
      splitEvaluationSeconds += Lookup[result,
        "SparseEvaluationSeconds", 0.];
      splitFallbackSeconds += Lookup[result,
        "SubstitutionFallbackSeconds", 0.]];
    result["Channels"]];
  evaluated = Catch[
    entryKeys = Keys[provider["Entries"]];
    If[nativeDeferredForcingQ,
      entryKeys = DeleteCases[entryKeys, "BBar"]];
    values = Association[Table[
      key -> MapThread[evaluateEntry, {provider["Entries"][key],
        provider["ActiveRoots"][key]}, 3],
      {key, entryKeys}]];
    If[AssociationQ[Lookup[provider, "DeferredBundle", None]] &&
        ! nativeDeferredForcingQ,
      bundleChannels = multiquadraticStripBundleProviderChannels[provider,
        preflight];
      If[Lookup[bundleChannels, "Status", None] =!=
          "MultiquadraticBundleChannelsV1",
        Throw[Join[<|"Status" -> Lookup[bundleChannels, "Status",
            "BundleProviderRejected"],
          "Point" -> Mod[point, prime], "Prime" -> prime,
          "RegulatorValue" -> epsilonValue,
          "LargeEntryEvaluationCount" -> entryCount +
            Lookup[bundleChannels, "OperandEvaluationCount", 0]|>,
          KeyDrop[bundleChannels, "Status"]], tag]];
      AssociateTo[values, "BBar" -> bundleChannels["BBar"]];
      entryCount += Lookup[bundleChannels, "OperandEvaluationCount", 0];
      splitCompileAttempts += Lookup[bundleChannels,
        "SplitSparseCompileAttemptCount", 0];
      splitCompileCacheHits += Lookup[bundleChannels,
        "SplitSparseCompileCacheHitCount", 0];
      splitCompileCacheMisses += Lookup[bundleChannels,
        "SplitSparseCompileCacheMissCount", 0];
      splitSparseSuccesses += Lookup[bundleChannels,
        "SplitSparseEvaluationCount", 0];
      splitSubstitutionFallbacks += Lookup[bundleChannels,
        "SplitSubstitutionFallbackCount", 0];
      splitCompileSeconds += Lookup[bundleChannels,
        "SplitSparseCompileSeconds", 0.];
      splitEvaluationSeconds += Lookup[bundleChannels,
        "SplitSparseEvaluationSeconds", 0.];
      splitFallbackSeconds += Lookup[bundleChannels,
        "SplitSubstitutionFallbackSeconds", 0.]];
    oneFormValues = If[provider["OneForms"] === {}, {},
      MapThread[evaluateEntry, {provider["OneForms"],
        provider["OneFormActiveRoots"]}, 2]];
    <|"Status" -> "MultiquadraticPointCoefficientsV1",
      "Provider" -> kind, "Prime" -> prime,
      "Point" -> Mod[point, prime], "RegulatorValue" -> epsilonValue,
      "EpsilonMod" -> preflight["EpsilonMod"],
      "QuadraticRadicands" -> deltaValues,
      "SquareRootGeneratorValues" -> rootValues,
      "SplitPointQ" -> preflight["SplitPointQ"],
      "GaugeDenominator" -> preflight["GaugeDenominator"],
      "GaugeLogDerivatives" -> preflight["GaugeLogDerivatives"],
      "RootLogDerivatives" -> preflight["RootLogDerivatives"],
      "E" -> values["E"], "C" -> values["C"],
      "BBar" -> If[nativeDeferredForcingQ,
        Missing["NativeDeferredASTPending"], values["BBar"]],
      "ForcingProvider" -> If[nativeDeferredForcingQ,
        "NativeDeferredASTPending", kind],
      "OneForms" -> oneFormValues,
      "CoefficientData" -> provider["CoefficientData"],
      "BundleOperandEvaluationCount" -> If[AssociationQ[bundleChannels],
        Lookup[bundleChannels, "OperandEvaluationCount", 0], 0],
      "BundleCoefficientEvaluationCount" -> If[AssociationQ[bundleChannels],
        Lookup[bundleChannels, "CoefficientEvaluationCount", 0], 0],
      "BundleOperandEntryEvaluationCount" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "OperandEntryEvaluationCount", 0], 0],
      "BundleCoefficientEntryEvaluationCount" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "CoefficientEntryEvaluationCount", 0], 0],
      "BundleOperandScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels], Lookup[bundleChannels,
          "OperandScalarBranchEvaluationCount", 0], 0],
      "BundleCoefficientScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels], Lookup[bundleChannels,
          "CoefficientScalarBranchEvaluationCount", 0], 0],
      "BundleScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "ScalarBranchEvaluationCount", 0], 0],
      "BundleGlobalSheetScalarBranchEvaluationCount" -> If[
        AssociationQ[bundleChannels], Lookup[bundleChannels,
          "GlobalSheetScalarBranchEvaluationCount", 0], 0],
      "BundleScalarBranchEvaluationReduction" -> If[
        AssociationQ[bundleChannels],
        Lookup[bundleChannels, "ScalarBranchEvaluationReduction", 0], 0],
      "BundleEvaluationSeconds" -> If[AssociationQ[bundleChannels],
        Lookup[bundleChannels, "Seconds", 0], 0],
      "SplitSparseCompileAttemptCount" -> splitCompileAttempts,
      "SplitSparseCompileCacheHitCount" -> splitCompileCacheHits,
      "SplitSparseCompileCacheMissCount" -> splitCompileCacheMisses,
      "SplitSparseEvaluationCount" -> splitSparseSuccesses,
      "SplitSubstitutionFallbackCount" -> splitSubstitutionFallbacks,
      "SplitSparseCompileSeconds" -> splitCompileSeconds,
      "SplitSparseEvaluationSeconds" -> splitEvaluationSeconds,
      "SplitSubstitutionFallbackSeconds" -> splitFallbackSeconds,
      "PreflightSeconds" -> preflight["PreflightSeconds"],
      "LargeEntryEvaluationCount" -> entryCount,
      "EntryEvaluationCount" -> entryCount,
      "Seconds" -> N[AbsoluteTime[] - startTime]|>, tag];
  evaluated
];
multiquadraticStripProviderChannels[___] :=
  multiquadraticStripFailure["InvalidProviderChannelArguments"];

(* ------------------------------------------------------------------ *)
(* A CONSERVATIVE GAUGE DENOMINATOR, WITHOUT ANY CHANNEL DECOMPOSITION  *)
(* (round-2 item 9; Codex 2.3, the screen-first ordering)               *)
(* ------------------------------------------------------------------ *)

(* WHY IT IS A SUPERSET, and why that matters.  The production rule
   multiquadraticRationalGaugeDenominator reads the CHANNEL denominators
   and admits each polar factor one power below its worst order.  A
   channel of f = N/D has denominator dividing the NORM of D, because
   clearing D by its conjugates is exactly what the channel
   decomposition does.  So

     Prod over rational factors  g^(max multiplicity)
     x Prod over algebraic factors Norm(g)^(max multiplicity)
     x the alphabet's own norm factor

   is divisible by the production denominator for every entry, at every
   multiplicity: it is a SUPERSET ansatz, and a screen that refuses a
   superset refuses every subset of it -- which is what makes it sound to
   run the screen BEFORE the expensive exact preparation.

   It is deliberately generous, and that is the point: it costs one
   FactorList per distinct raw denominator (work the gauge-denominator
   rule already does) instead of the 1400.5 s global decomposition it
   replaces in the screen's input. *)
multiquadraticStripConservativeGaugeDenominator[strip_, roots_List,
    letterRecords_, variables_List] := Module[
  {entries, denominators, factorPairs, groups, rational, algebraic,
   normFactor, product, conjugates, norm},
  entries = DeleteCases[Flatten[strip[[3]]], 0];
  denominators = DeleteDuplicates[
    Denominator[Quiet[Together[#1]]] & /@ entries];
  denominators = DeleteCases[denominators, _?NumericQ];
  factorPairs = Flatten[Map[
    Function[denominator, Module[{list = Quiet[FactorList[denominator]]},
      If[! ListQ[list], {}, Select[Rest[list], ! NumericQ[First[#1]] &]]]],
    denominators], 1];
  If[factorPairs === {} && ! MatchQ[letterRecords, {___Association}],
    Return[1]];
  conjugates[factor_] := DeleteDuplicates[
    Table[Quiet[Together[transportChartApplyRootBranches[factor, roots,
      Table[If[BitGet[mask, k - 1] === 1, -1, 1]
        squareRootRecordExpression[roots[[k]]],
        {k, Length[roots]}]]]],
      {mask, 0, 2^Length[roots] - 1}],
    TrueQ[Quiet[Together[#1 - #2]] === 0] &];
  norm[factor_] := Quiet[Expand[Together[Times @@ conjugates[factor]]]];
  groups = GatherBy[factorPairs, Quiet[Expand[Together[First[#1]]]] &];
  rational = Times @@ Table[
    Quiet[Expand[Together[First[First[group]]]]]^Max[Last /@ group],
    {group, Select[groups, FreeQ[First[First[#1]],
      Power[_, _Rational?(Denominator[#1] === 2 &)]] &]}];
  algebraic = Times @@ Table[
    norm[First[First[group]]]^Max[Last /@ group],
    {group, Select[groups, ! FreeQ[First[First[#1]],
      Power[_, _Rational?(Denominator[#1] === 2 &)]] &]}];
  normFactor = If[MatchQ[letterRecords, {___Association}],
    multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1];
  product = Quiet[Together[rational algebraic normFactor]];
  If[TrueQ[product === 0] ||
      ! FreeQ[product, Power[_, _Rational?(Denominator[#1] === 2 &)]],
    Return[$Failed]];
  Quiet[Expand[product]]
];
multiquadraticStripConservativeGaugeDenominator[___] := $Failed;

(* Build the rational gauge pole ansatz from the immutable pre-cancellation
   divisor census.  Algebraic factors enter through their certified Galois
   orbit norm; factors in the same orbit are merged at the largest required
   order rather than multiplied repeatedly. *)
multiquadraticStripBundleGaugeDenominator[bundle_Association,
    variables : {_Symbol, _Symbol}, letterRecords_: {}] := Module[
  {startTime = AbsoluteTime[], validation, summary, factors, orbits, keyGroups,
   collapsedRecords, grouped, forcingSources, forcingFactor, letterFactor,
   mergeData, denominator, records},
  validation = blockEquationDeferredBundleValidate[bundle];
  If[Lookup[validation, "Status", None] =!= "BundleValid",
    Return[multiquadraticStripFailure["InvalidDeferredBundle",
      <|"Detail" -> validation|>]]];
  summary = bundle["DivisorSummary"];
  factors = summary["Factors"];
  orbits = summary["GaloisOrbits"];
  records = DeleteCases[Table[Module[
      {order = Ceiling[Lookup[factor,
          "MaxEntryPoleOrderUpperBound", 0]], base, exponent},
      exponent = Max[0, order - 1];
      If[exponent === 0, Return[Nothing, Module]];
      base = If[TrueQ[Lookup[factor, "Algebraic", False]],
        With[{orbit = Lookup[factor, "OrbitIndex", 0]},
          If[! IntegerQ[orbit] || ! (1 <= orbit <= Length[orbits]),
            Return[Nothing, Module]];
          Lookup[orbits[[orbit]], "Norm", $Failed]],
        Lookup[factor, "Factor", $Failed]];
      If[base === $Failed ||
          FreeQ[base, Alternatives @@ variables], Return[Nothing, Module]];
      <|"Base" -> Quiet[Together[base]], "Exponent" -> exponent,
        "FactorIndex" -> Lookup[factor, "FactorIndex", None],
        "OrbitIndex" -> Lookup[factor, "OrbitIndex", 0],
        "SourcePoleOrderUpperBound" -> order|>],
    {factor, factors}], Nothing];
  (* FactorIndex is unique for a rational divisor; algebraic conjugates that
     share a norm already carry the same validated OrbitIndex.  Collapse those
     guaranteed equalities by integer key before the semantic comparison.
     Different orbits, and an orbit versus a rational factor, can still have
     equal bases, so the final Together-Gather is retained on the much smaller
     collapsed list. *)
  keyGroups = GatherBy[records, If[#1["OrbitIndex"] > 0,
      {"Orbit", #1["OrbitIndex"]}, {"Factor", #1["FactorIndex"]}] &];
  collapsedRecords = Map[Function[group, Append[First[group],
      "Exponent" -> Max[Lookup[group, "Exponent"]]]], keyGroups];
  grouped = Gather[collapsedRecords,
    TrueQ[Quiet[Together[#1["Base"] - #2["Base"]]] === 0] &];
  forcingSources = Table[
    {First[group]["Base"], Max[Lookup[group, "Exponent"]]},
    {group, grouped}];
  forcingFactor = Times @@
    (First[#1]^Last[#1] & /@ forcingSources);
  letterFactor = If[MatchQ[letterRecords, {___Association}],
    multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1];
  mergeData = multiquadraticStripMergeGaugeDenominatorSourceData[
    forcingSources, letterFactor, variables];
  If[! AssociationQ[mergeData] ||
      Lookup[mergeData, "Status", None] =!=
        "GaugeDenominatorSourceDataV1",
    Return[multiquadraticStripFailure[
      "BundleGaugeDenominatorFactorMergeFailed"]]];
  denominator = mergeData["GaugeDenominator"];
  If[denominator === $Failed || TrueQ[denominator === 0] ||
      ! FreeQ[denominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure[
      "BundleGaugeDenominatorNotRational"]]];
  <|"Status" -> "BundleGaugeDenominatorV1",
    "GaugeDenominator" -> denominator,
    "ForcingFactor" -> forcingFactor, "LetterFactor" -> letterFactor,
    "DivisorRecords" -> records,
    "DivisorSummary" -> summary,
    "GaugeDenominatorDegrees" -> mergeData["GaugeDenominatorDegrees"],
    "FactorCount" -> Length[factors], "OrbitCount" -> Length[orbits],
    "ProvenanceGroupCount" -> Length[keyGroups],
    "GroupedFactorCount" -> Length[grouped],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripBundleGaugeDenominator[___] :=
  multiquadraticStripFailure["InvalidBundleGaugeDenominatorArguments"];

(* The bundle divisor census is deliberately pre-cancellation.  That is a
   cheap and safe default, but a large overestimate makes the dense affine
   system grow quadratically in memory.  When the estimated sampler would
   cross its hard byte ceiling, materialize only the small target block and
   decompose its scalar entries exactly.  This is denominator computation,
   not a second acceptance test: the existing block-level modular identity
   remains the production acceptance boundary. *)
multiquadraticStripBundleExactChannelTask[payload_Association,
    indices_List] := Module[{entries, roots, channels},
  If[! AssociationQ[payload], Return[$Failed]];
  entries = Lookup[payload, "Entries", $Failed];
  roots = Lookup[payload, "Roots", $Failed];
  If[! ListQ[entries] || ! ListQ[roots] ||
      ! VectorQ[indices, IntegerQ] ||
      ! AllTrue[indices, Between[#1, {1, Length[entries]}] &],
    Return[$Failed]];
  channels = multiquadraticStripDecomposeScalar[#1, roots] & /@
    entries[[indices]];
  If[! AllTrue[channels,
      ListQ[#1] && Length[#1] === 2^Length[roots] &&
        FreeQ[#1, $Failed] &], $Failed,
    <|"Indices" -> indices, "Channels" -> channels|>]
];
multiquadraticStripBundleExactChannelTask[dataFile_String,
    indices_List] := Module[{payload = taskBrokerRead[dataFile]},
  If[AssociationQ[payload],
    multiquadraticStripBundleExactChannelTask[payload, indices], $Failed]
];
multiquadraticStripBundleExactChannelTask[___] := $Failed;

multiquadraticStripBundleExactChannels[forcing_, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {startTime = AbsoluteTime[], dimensions = Dimensions[forcing], entries,
   gradeCount = 2^Length[roots], rules, inverseRules, payload, dataFile,
   free = 0, workerCount, groups, helperGroups, localGroup, codes, handle,
   helperResults, localResult, results, channelVectors, result, indices,
   channels, missing},
  If[! MatchQ[dimensions, {2, _Integer, _Integer}],
    Return[multiquadraticStripFailure[
      "InvalidBundleExactChannelForcing"]]];
  entries = Flatten[forcing];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  inverseRules = Reverse /@ rules;
  payload = <|"Entries" -> (entries /. rules), "Roots" -> (roots /. rules)|>;
  If[! multiquadraticStripContextFreeQ[payload],
    Return[multiquadraticStripFailure[
      "ContextSensitiveBundleExactChannels"]]];
  If[TrueQ[Quiet[Check[taskBrokerActiveQ[], False]]],
    free = Quiet[Check[taskBrokerFreeKernels[], 0]]];
  If[! IntegerQ[free] || free < 0, free = 0];
  workerCount = Min[Length[entries], free + 1];
  groups = TakeList[Range[Length[entries]],
    Ceiling[(Length[entries] - Range[workerCount] + 1)/workerCount]];
  helperGroups = Most[groups];
  localGroup = Last[groups];
  dataFile = If[helperGroups === {}, None,
    taskBrokerDataFile[CreateUUID["mqbundlechannels-"], payload]];
  If[helperGroups =!= {} && StringQ[dataFile],
    codes = Table[
      "FeynFacet`Private`multiquadraticStripBundleExactChannelTask[" <>
        ToString[dataFile, InputForm] <> "," <>
        ToString[group, InputForm] <> "]", {group, helperGroups}];
    handle = taskBrokerSubmit[codes, "Label" -> "mqbundlechannels",
      "Timeout" -> 7200],
    helperGroups = {};
    localGroup = Range[Length[entries]];
    handle = None];
  localResult = multiquadraticStripBundleExactChannelTask[payload, localGroup];
  helperResults = If[AssociationQ[handle], taskBrokerCollect[handle], {}];
  results = Join[helperResults, {localResult}];
  channelVectors = ConstantArray[Missing["NotComputed"], Length[entries]];
  Do[
    result = results[[k]];
    If[AssociationQ[result],
      indices = Lookup[result, "Indices", {}];
      channels = Lookup[result, "Channels", {}];
      If[VectorQ[indices, IntegerQ] && Length[indices] === Length[channels] &&
          AllTrue[indices, Between[#1, {1, Length[entries]}] &],
        MapThread[(channelVectors[[#1]] = #2) &, {indices, channels}]]],
    {k, Length[results]}];
  missing = Flatten[Position[channelVectors, _Missing, {1}, Heads -> False]];
  If[missing =!= {},
    result = multiquadraticStripBundleExactChannelTask[payload, missing];
    If[! AssociationQ[result],
      Return[multiquadraticStripFailure[
        "BundleExactChannelDecompositionFailed",
        <|"MissingEntryIndices" -> missing|>]]];
    MapThread[(channelVectors[[#1]] = #2) &,
      {result["Indices"], result["Channels"]}]];
  If[! AllTrue[channelVectors,
      ListQ[#1] && Length[#1] === gradeCount && FreeQ[#1, $Failed] &],
    Return[multiquadraticStripFailure[
      "BundleExactChannelDecompositionFailed"]]];
  <|"Status" -> "BundleExactForcingChannelsV1",
    "Channels" -> (ArrayReshape[Flatten[channelVectors],
       Append[dimensions, gradeCount]] /. inverseRules),
    "EntryCount" -> Length[entries],
    "BrokerHelperCount" -> Length[helperGroups],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripBundleExactChannels[___] :=
  multiquadraticStripFailure["InvalidBundleExactChannelArguments"];

multiquadraticStripBundleRefinedGaugeDenominator[bundle_Association,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    letterRecords_: {}] := Module[
  {startTime = AbsoluteTime[], evaluated, exactChannels, forcingFactor,
   letterFactor, denominator},
  evaluated = blockEquationDeferredBundleEvaluate[bundle, {},
    "ExpressionTransform" -> Identity];
  If[Lookup[evaluated, "Status", None] =!= "OK",
    Return[multiquadraticStripFailure[
      "BundleExactMaterializationFailed"]]];
  exactChannels = multiquadraticStripBundleExactChannels[
    evaluated["Image"], roots, variables, epsilon];
  If[Lookup[exactChannels, "Status", None] =!=
      "BundleExactForcingChannelsV1", Return[exactChannels]];
  forcingFactor = multiquadraticRationalGaugeDenominator[
    exactChannels["Channels"], variables];
  letterFactor = If[MatchQ[letterRecords, {___Association}],
    multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1];
  denominator = multiquadraticStripMergeGaugeDenominator[
    forcingFactor, letterFactor, variables];
  If[denominator === $Failed || TrueQ[Quiet[Together[denominator]] === 0] ||
      ! FreeQ[denominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure[
      "BundleRefinedGaugeDenominatorNotRational"]]];
  <|"Status" -> "BundleRefinedGaugeDenominatorV1",
    "GaugeDenominator" -> denominator,
    "GaugeDenominatorDegrees" ->
      (Exponent[denominator, #1] & /@ variables),
    "ForcingFactor" -> forcingFactor, "LetterFactor" -> letterFactor,
    "EntryCount" -> exactChannels["EntryCount"],
    "BrokerHelperCount" -> exactChannels["BrokerHelperCount"],
    "ChannelSeconds" -> exactChannels["Seconds"],
    "Seconds" -> N[AbsoluteTime[] - startTime]|>
];
multiquadraticStripBundleRefinedGaugeDenominator[___] :=
  multiquadraticStripFailure[
    "InvalidBundleRefinedGaugeDenominatorArguments"];

End[];
