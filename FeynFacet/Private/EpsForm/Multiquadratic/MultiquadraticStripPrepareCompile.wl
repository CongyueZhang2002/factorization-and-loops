(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticStripPrepareCompile.wl -- part 4 of 8 of the
   multiquadratic strip solver (split from MultiquadraticStripSolve.wl in
   round 4, 2026-09-02, pure moves): preparation (root order, index ABI, support, normalizations), exact channel
   compilation, the compile architecture (intern pools, core/ansatz split),
   the compiled-assembly validator, the provider-independent row layout and
   coefficient layout.
   Loads after the preceding parts (Private/LoadOrder.wl); the shared data,
   globals and the shared utilities are in MultiquadraticStripSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticStripCompactDLogAdmission,
  multiquadraticStripChannelGradeSupport,
  multiquadraticStripChannelVectorGradeSupport,
  multiquadraticStripCompileCoreKeyFromParts,
  multiquadraticStripCompileCoreKey,
  multiquadraticStripCompileOneFormKey,
  multiquadraticStripLetterData,
  multiquadraticStripIntern,
  multiquadraticStripInternProbe,
  multiquadraticStripInternValidQ,
  multiquadraticStripInternReset,
  multiquadraticStripInternStatistics,
  multiquadraticStripInternValueBytes,
  multiquadraticStripCompileCacheClear,
  $multiquadraticStripInternPools,
  $multiquadraticStripInternCounters,
  $multiquadraticStripPoolEntryLimit,
  $multiquadraticStripPoolByteLimit,
  $multiquadraticStripPoolOversizeBytes,
  multiquadraticStripLetterChannelData,
  multiquadraticStripRootOrder,
  multiquadraticStripRootCensusFromFrameCensus,
  multiquadraticStripRootCensus,
  multiquadraticStripBundleSquareRootGenerators,
  multiquadraticStripRootCensusWithBundle,
  multiquadraticStripCanonicalizeRadicals,
  multiquadraticStripRationalSquareQ,
  multiquadraticStripSquareClassSquareQ,
  multiquadraticStripCompileNormalizations,
  multiquadraticStripGaugeIndex,
  multiquadraticStripResidueIndex,
  multiquadraticStripPointRowIndex,
  multiquadraticStripColumnOrder,
  multiquadraticStripRowOrder,
  multiquadraticStripPreparationData,
  multiquadraticStripCoreCanonicalData,
  multiquadraticStripDecomposeForcing,
  multiquadraticStripPrepare,
  multiquadraticStripPreparationValidQ,
  multiquadraticStripCompilePolynomial,
  multiquadraticStripCompileRational,
  multiquadraticStripDecomposeScalar,
  multiquadraticStripCompileTensor,
  multiquadraticStripFormShape,
  multiquadraticStripCompile,
  multiquadraticStripCompiledValidQ,
  multiquadraticStripCoefficientData,
  multiquadraticStripAssemblyLayout,
  multiquadraticStripAssemblyLayoutValidQ,
  multiquadraticStripAssemblyLayoutHotValidQ,
  multiquadraticStripAssemblyLayoutEvaluationValidQ,
  multiquadraticStripCompiledProvider
];

(* ------------------------------------------------------------------ *)
(* Preparation: root order, index ABI, support, normalizations          *)
(* ------------------------------------------------------------------ *)

(* The coefficient presentation supplies the authoritative generator order.
   Two generators with the same radicand would receive separate sign bits
   for one quadratic extension and are rejected. *)
(* 2^r independent sign automorphisms need r independent square
   classes: distinct radicands are not enough, {x, y, x y} has rank two
   and would give one generator two sign bits.  Factorization over Q
   detects exactly the rational-function square relations this
   evaluator admits.  The Codex sources check only for DUPLICATE root
   squares; FamilyRowGaugeFiniteField.wl's canonicalizer has this
   stronger check, and the neutral module must carry it or the
   duplicate cannot be deleted in favour of it (handoff External gap
   3).  Kept algorithmically identical to that copy so the differential
   test can compare verdicts. *)
multiquadraticStripRationalSquareQ[value : (_Integer | _Rational)] :=
  value >= 0 && IntegerQ[Sqrt[Numerator[value]]] &&
    IntegerQ[Sqrt[Denominator[value]]];
multiquadraticStripRationalSquareQ[_] := False;

multiquadraticStripSquareClassSquareQ[expression_] := Module[
  {q, numeratorFactors, denominatorFactors, constant},
  q = Quiet[Together[expression]];
  If[! FreeQ[q, Power[_, exponent_Rational /; Denominator[exponent] =!= 1]],
    Return[False]];
  numeratorFactors = Quiet[FactorList[Numerator[q]]];
  denominatorFactors = Quiet[FactorList[Denominator[q]]];
  If[! ListQ[numeratorFactors] || ! ListQ[denominatorFactors] ||
      numeratorFactors === {} || denominatorFactors === {}, Return[False]];
  constant = First[First[numeratorFactors]]/First[First[denominatorFactors]];
  multiquadraticStripRationalSquareQ[constant] &&
    AllTrue[Rest[numeratorFactors], EvenQ[Last[#1]] &] &&
    AllTrue[Rest[denominatorFactors], EvenQ[Last[#1]] &]
];

multiquadraticStripRootOrder[frame_Association, variables : {_Symbol, _Symbol},
    indices_List, epsilon_Symbol] := Module[
  {current, roots, duplicates, dependent},
  current = coefficientPresentationSquareRootsInVariables[frame, variables];
  If[! ListQ[current], Return[multiquadraticStripFailure["InvalidMultiquadraticFrame"]]];
  If[! AllTrue[indices, IntegerQ[#1] && 1 <= #1 <= Length[current] &],
    Return[multiquadraticStripFailure["InvalidRootIndices"]]];
  roots = current[[indices]];
  If[! AllTrue[roots, AssociationQ[#1] &&
      squareRootRecordExpression[#1] =!= $Failed &&
      squareRootRecordRadicand[#1] =!= $Failed &&
      TrueQ[Together[squareRootRecordExpression[#1]^2 -
        squareRootRecordRadicand[#1]] === 0] &],
    Return[multiquadraticStripFailure["InvalidRootMetadata"]]];
  duplicates = Select[Subsets[Range[Length[roots]], {2}],
    TrueQ[Together[squareRootRecordRadicand[roots[[#1[[1]]]]] -
      squareRootRecordRadicand[roots[[#1[[2]]]]]] === 0] &];
  If[duplicates =!= {},
    Return[multiquadraticStripFailure["DuplicateRootSquares",
      <|"DuplicatePairs" -> duplicates|>]]];
  dependent = FirstCase[Rest[Subsets[Range[Length[roots]]]],
    subset_ /; multiquadraticStripSquareClassSquareQ[
      Times @@ (squareRootRecordRadicand /@ roots[[subset]])] :> subset,
    None];
  If[dependent =!= None,
    Return[multiquadraticStripFailure["DependentRootSquares",
      <|"RootIndices" -> indices[[dependent]]|>]]];
  roots = MapThread[Join[#1, <|"SourceIndex" -> #2|>] &, {roots, indices}];
  <|"Status" -> "StableRootOrder", "Roots" -> roots,
    "SourceIndices" -> indices|>
];

(* Root census.  transportChartRootIndices is the package classifier and
   is called here, but its matcher

     Flatten[Position[rootBases, candidate_ /; Together[base - candidate] === 0]]

   (TransportCharts.wl lines 230-231, identical in Codex's
   TRClassifyStripRecord) searches rootBases at every level and then
   flattens position specifications into root indices.  With frame
   squares {x, y, 1 + x + y} a strip containing only Sqrt[x] is reported
   as rank three: x matches at {1} and again inside 1 + x + y at {3,2},
   and the flattened {3,2} contributes indices 3 and 2.  A superset is
   not harmless -- it multiplies the ansatz by 2^(extra roots), demands
   a split point for roots that do not occur, and can push a genuine
   rank-3 block past the rank ceiling -- so the decision is taken on an
   exact level-1 match here, with the package census kept alongside as a
   diagnostic.  The in-frame dispatcher has already paid for that package
   census; the helper below accepts that exact same-call result so the
   multiquadratic solver need not scan a large strip twice. *)
multiquadraticStripRootCensusFromFrameCensus[frameCensus_Association,
    allRoots_List] := Module[
  {rootBases, radicals, matches, indices, unknown, denested,
   denestedIndices},
  rootBases = Together /@ (squareRootRecordRadicand /@ allRoots);
  radicals = Lookup[frameCensus, "RadicalBases", {}];
  matches[base_] := Flatten[Position[rootBases,
    candidate_ /; TrueQ[Together[base - candidate] === 0], {1},
    Heads -> False]];
  indices = Sort[DeleteDuplicates[Flatten[matches /@ radicals]]];
  unknown = Select[radicals, matches[#1] === {} &];
  (* ONE SHARED FIELD CANONICALIZER (2026-08-26, round-2 item 4, Codex
     review 1.4).  A radicand that is not LITERALLY a declared square may
     still lie in the declared multiquadratic field: with declared roots
     Sqrt[x] and Sqrt[y], Sqrt[x y] is Sqrt[x] Sqrt[y].  The transport
     side has recognized and denested such a base exactly since
     2026-08-24 (transportChartDenestRadicalBase, its square identity
     checked exactly and its global sign fixed numerically); the solver
     refused it as an undeclared radical and multiquadraticFieldDecompose
     then failed on the same strip transport accepts.

     The frame census above has ALREADY run the denester on every base
     the exact matcher missed -- its "DenestedRadicalBases" is exactly
     that -- so consuming it here costs nothing on a strip whose radicals
     are all declared (every CF259/CF300/CF303 strip measured so far)
     and is the whole repair on a strip whose are not.  The level-1
     matcher stays: the frame census's own index set is still only a
     diagnostic, because its all-level Position over-reports rank. *)
  denested = KeySelect[Lookup[frameCensus, "DenestedRadicalBases", <||>],
    Function[base, AnyTrue[unknown, TrueQ[Together[base - #1] === 0] &]]];
  denestedIndices = Sort[DeleteDuplicates[Join[
    Flatten[Lookup[Values[denested], "RootIndices", {}]],
    Flatten[Lookup[Values[denested], "InnerRootIndices", {}]]]]];
  indices = Sort[DeleteDuplicates[Join[indices, denestedIndices]]];
  unknown = Select[unknown,
    Function[base, ! AnyTrue[Keys[denested], TrueQ[Together[base - #1] === 0] &]]];
  <|"Status" -> If[unknown === {}, "ExactRootClassification",
      "UnclassifiedRadicals"],
    "RootIndices" -> indices, "RadicalBases" -> radicals,
    "UnclassifiedRadicalBases" -> unknown,
    (* the bases that needed denesting, with the verified rewrite: a
       consumer that decomposes into channels MUST canonicalize the
       expression with multiquadraticStripCanonicalizeRadicals first *)
    "DenestedRadicalBases" -> denested,
    "DenestedRootIndices" -> denestedIndices,
    "NumericRadicalClasses" ->
      Lookup[frameCensus, "NumericRadicalClasses", {}],
    "FrameCensusRootIndices" -> Lookup[frameCensus, "RootIndices", {}],
    "FrameCensusUnclassified" ->
      Lookup[frameCensus, "UnclassifiedRadicalBases", {}]|>
];
multiquadraticStripRootCensusFromFrameCensus[___] :=
  multiquadraticStripFailure["InvalidFrameRootCensusArguments"];

multiquadraticStripRootCensus[strip_, allRoots_List] :=
  multiquadraticStripRootCensusFromFrameCensus[
    transportChartRootIndices[strip, allRoots], allRoots];

multiquadraticStripBundleSquareRootGenerators[bundle_Association,
    variables : {_Symbol, _Symbol}] := Module[
  {presentation, roots, indices},
  presentation = masterTransportCoefficientPresentationData[
    Lookup[bundle, "CoefficientPresentation",
      Missing["NoCoefficientPresentation"]], variables];
  roots = coefficientPresentationSquareRootsInVariables[
    presentation, variables];
  indices = Lookup[bundle, "SquareRootGeneratorIndices", $Failed];
  If[Lookup[presentation, "Status", None] =!= "OK" ||
      ! ListQ[roots] || ! VectorQ[indices, IntegerQ] ||
      ! ContainsOnly[indices, Range[Length[roots]]] ||
      indices =!= Sort[DeleteDuplicates[indices]],
    Return[$Failed]];
  roots[[indices]]
];
multiquadraticStripBundleSquareRootGenerators[___] := $Failed;

(* Extend the visible-strip census by the authenticated root frame of a
   deferred forcing bundle.  The dense BBar slot is deliberately zero on that
   route, so this union is the single shared authority used both before
   alphabet construction and by preparation.  The union is canonicalized by
   BlockEquationDeferred's stable frame builder, the same route used by the
   transport dispatcher; source indices remain provenance only. *)
multiquadraticStripRootCensusWithBundle[strip_, allRoots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, deferredBundle_,
    frameCensus_: Automatic] := Module[
  {classification, validation, bundleRoots, bundleIndices, selectedIndices,
   stableFrame, requiredRootIndices},
  If[AssociationQ[deferredBundle],
    validation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[validation, "Status", None] =!= "BundleValid",
      Return[multiquadraticStripFailure["InvalidDeferredBundle",
        <|"Detail" -> validation|>]]];
    If[Lookup[deferredBundle, "Variables", None] =!= variables ||
        Lookup[deferredBundle, "Regulator", None] =!= epsilon ||
        Lookup[deferredBundle, "Dimensions", None] =!=
          Prepend[Dimensions[strip[[3, 1]]], 2],
      Return[multiquadraticStripFailure["DeferredBundleFrameMismatch"]]],
    If[! MissingQ[deferredBundle] && deferredBundle =!= Automatic,
      Return[multiquadraticStripFailure["InvalidDeferredBundle"]]]];
  classification = If[AssociationQ[frameCensus],
    multiquadraticStripRootCensusFromFrameCensus[frameCensus, allRoots],
    multiquadraticStripRootCensus[strip, allRoots]];
  If[! AssociationQ[deferredBundle],
    Return[Join[classification, <|"BundleRootIndices" -> {},
      "RequiredRootIndices" -> classification["RootIndices"]|>]]];
  bundleRoots = multiquadraticStripBundleSquareRootGenerators[
    deferredBundle, variables];
  If[! ListQ[bundleRoots],
    Return[multiquadraticStripFailure[
      "DeferredBundleCoefficientPresentationMismatch"]]];
  bundleIndices = Table[Module[{matches},
      matches = Flatten[Position[allRoots,
        candidate_ /; TrueQ[Quiet[Together[
              squareRootRecordRadicand[candidate] -
                squareRootRecordRadicand[bundleRoot]]] === 0] &&
          TrueQ[Quiet[Together[
              squareRootRecordExpression[candidate] -
                squareRootRecordExpression[bundleRoot]]] === 0],
        {1}, Heads -> False]];
      If[Length[matches] =!= 1,
        Return[multiquadraticStripFailure[
          "DeferredBundleSquareRootGeneratorMismatch",
          <|"BundleRoot" -> bundleRoot, "Matches" -> matches|>], Module]];
      First[matches]],
    {bundleRoot, bundleRoots}];
  If[! VectorQ[bundleIndices, IntegerQ],
    Return[FirstCase[bundleIndices, failure_Association :> failure,
      multiquadraticStripFailure[
        "DeferredBundleSquareRootGeneratorMismatch"]]]];
  selectedIndices = DeleteDuplicates[Join[
    classification["RootIndices"], bundleIndices]];
  stableFrame = blockEquationDeferredValidateSquareRootGenerators[
    allRoots[[selectedIndices]],
    variables, epsilon];
  If[Lookup[stableFrame, "Status", None] =!=
      "SquareRootGeneratorsValidated",
    Return[multiquadraticStripFailure["DeferredBundleRootUnionInvalid",
      <|"Detail" -> stableFrame|>]]];
  requiredRootIndices = selectedIndices;
  Join[classification, <|"BundleRootIndices" -> bundleIndices,
    "RequiredRootIndices" -> requiredRootIndices|>]
];
multiquadraticStripRootCensusWithBundle[___] :=
  multiquadraticStripFailure["InvalidBundleRootCensusArguments"];

(* The rewrite side of the same canonicalizer.  Given an expression (a
   strip, a matrix, a letter) and the census that classified it, return
   the expression with every denested radical replaced by its declared
   form, so that transportChartApplyRootBranches and therefore
   multiquadraticFieldDecompose see only declared radicands.

   A census with no denested SYMBOLIC base returns the input untouched
   and does no work: this is the measured common case, and the guard is
   what keeps the canonicalizer free on CF300-shaped input.  A numeric
   class constant is a constant of the coefficient field and is left
   alone, exactly as the transport side leaves it. *)
multiquadraticStripCanonicalizeRadicals[expression_, allRoots_List,
    census_Association] := Module[{denested, variables, canonical},
  denested = KeySelect[Lookup[census, "DenestedRadicalBases", <||>],
    ! NumericQ[#1] &];
  If[denested === <||> || ! ListQ[allRoots] || allRoots === {},
    Return[<|"Status" -> "NoRadicalCanonicalizationNeeded",
      "Expression" -> expression, "Rewritten" -> 0, "Bases" -> {}|>]];
  variables = Select[DeleteDuplicates[Flatten[Variables /@
    (Together /@ (squareRootRecordRadicand /@ allRoots))]],
    MatchQ[#1, _Symbol] &];
  canonical = transportChartCanonicalizeDenestedRadicals[expression, allRoots,
    variables, denested];
  If[Lookup[canonical, "Status", None] =!= "OK",
    Return[multiquadraticStripFailure["RadicalCanonicalizationFailed",
      <|"Detail" -> canonical, "Bases" -> Keys[denested]|>]]];
  <|"Status" -> "RadicalsCanonicalized",
    "Expression" -> canonical["Expression"],
    "Rewritten" -> canonical["Rewritten"],
    "Bases" -> Keys[canonical["Rewrites"]],
    "Signs" -> Lookup[Values[canonical["Rewrites"]], "Sign", {}],
    "Witnesses" -> Lookup[Values[canonical["Rewrites"]], "Witness", {}]|>
];
multiquadraticStripCanonicalizeRadicals[___] :=
  multiquadraticStripFailure["InvalidRadicalCanonicalizationArguments"];

multiquadraticStripGaugeIndex[upperDimension_Integer, lowerDimension_Integer,
    gradeCount_Integer, supportCount_Integer, i_Integer, j_Integer,
    grade_Integer, monomial_Integer] :=
  ((((i - 1) lowerDimension + (j - 1)) gradeCount + grade) supportCount) + monomial;

multiquadraticStripResidueIndex[gaugeUnknownCount_Integer,
    upperDimension_Integer, lowerDimension_Integer, letter_Integer,
    i_Integer, j_Integer] :=
  gaugeUnknownCount + (((letter - 1) upperDimension + (i - 1)) lowerDimension) + j;

multiquadraticStripPointRowIndex[targetGrade_Integer, mu_Integer, i_Integer,
    j_Integer, upperDimension_Integer, lowerDimension_Integer] :=
  ((targetGrade 2 + (mu - 1)) upperDimension + (i - 1)) lowerDimension + j;

multiquadraticStripColumnOrder[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "Gauge" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "GaugeIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "GaugeSupport" -> support, "OneFormCount" -> oneFormCount|>;

multiquadraticStripRowOrder[dimensions_List, gradeCount_Integer] := <|
  "PointRows" -> "{outputGrade0Based,direction,upperRow,lowerColumn}",
  "RowIndexFormula" -> "(((grade*2+(mu-1)) upper+(i-1)) lower+j)",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount|>;

multiquadraticStripCompileNormalizations[specifications_List, dimensions_List,
    gradeCount_Integer, support_List, oneForms_List,
    gaugeUnknownCount_Integer] := Catch[Module[
  {compiled = {}, kind, column, positions, i, j, grade, monomial, letter, value,
   unknownCount},
  unknownCount = gaugeUnknownCount + Length[oneForms] (Times @@ dimensions);
  Do[
    If[! AssociationQ[specification],
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation"]]];
    kind = Lookup[specification, "Kind", Missing["Kind"]];
    value = Lookup[specification, "Value", Missing["Value"]];
    If[MissingQ[value],
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation"]]];
    column = Switch[kind,
      "Column", Lookup[specification, "Column", $Failed],
      "GaugeCoefficient",
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        grade = Lookup[specification, "Grade", $Failed];
        monomial = Lookup[specification, "Monomial", $Failed];
        positions = Flatten[Position[support, monomial, {1}, Heads -> False]];
        If[! IntegerQ[i] || ! IntegerQ[j] || ! IntegerQ[grade] ||
            Length[positions] =!= 1 || i < 1 || i > dimensions[[1]] ||
            j < 1 || j > dimensions[[2]] || grade < 0 || grade >= gradeCount,
          $Failed,
          multiquadraticStripGaugeIndex[dimensions[[1]], dimensions[[2]],
            gradeCount, Length[support], i, j, grade, First[positions]]],
      "Residue",
        letter = Lookup[specification, "Letter", $Failed];
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        If[! IntegerQ[letter] || ! IntegerQ[i] || ! IntegerQ[j] ||
            letter < 1 || letter > Length[oneForms] || i < 1 ||
            i > dimensions[[1]] || j < 1 || j > dimensions[[2]], $Failed,
          multiquadraticStripResidueIndex[gaugeUnknownCount, dimensions[[1]],
            dimensions[[2]], letter, i, j]],
      _, $Failed];
    If[! IntegerQ[column] || column < 1 || column > unknownCount,
      Throw[multiquadraticStripFailure["InvalidNormalizationEquation",
        <|"ResolvedColumn" -> column, "UnknownCount" -> unknownCount|>]]];
    AppendTo[compiled, <|"Column" -> column, "Value" -> value, "Kind" -> kind|>],
    {specification, specifications}];
  If[! DuplicateFreeQ[Lookup[compiled, "Column", {}]],
    Throw[multiquadraticStripFailure["DuplicateNormalizationColumn"]]];
  compiled
]];

(* The context-free canonical forms of the differential equation and roots.
   Both the defining-data record and the compile-core key are built from these
   three, and none of them depends on the ansatz (support, one-forms,
   gauge denominator).  Splitting them out lets prepare key and build the
   compile core BEFORE it has a payload, and then hand the same texts to
   the payload instead of taking the whole-strip InputForm twice
   (2026-08-25). *)
multiquadraticStripCoreCanonicalData[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {rules, strip, deferredBundle, diagonalCanonical, equationCanonical,
   bundleValidation, deferredFastQ, deferredDimensions},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  deferredBundle = Lookup[record, "DeferredBundle",
    Missing["NoDeferredBundle"]];
  deferredDimensions = Quiet[Check[Dimensions[strip[[3, 1]]], $Failed]];
  deferredFastQ = AssociationQ[deferredBundle] &&
    MatchQ[deferredDimensions, {_Integer?Positive, _Integer?Positive}] &&
    Dimensions[strip[[3]]] === Prepend[deferredDimensions, 2] &&
    AllTrue[Flatten[strip[[3]]], SameQ[#1, 0] &] &&
    Lookup[deferredBundle, "Dimensions", None] ===
      Prepend[deferredDimensions, 2];
  equationCanonical = If[deferredFastQ,
    (* On the deferred route BBar is intentionally a zero shape placeholder;
       its authenticated bundle is the forcing.  Re-running Together, Expand
       and InputForm over every large diagonal entry took more than nine
       minutes on CF259 (27,9), even with CompileCore -> False.  A strict
       context-free structural seal of E/C plus the already-authenticated
       bundle binds exactly the representation this call consumes.  An
       equivalent rewrite can conservatively miss a cache/checkpoint, but it
       cannot reuse one for different input. *)
    bundleValidation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
      Return[$Failed]];
    diagonalCanonical = Map[
      multiquadraticStripCanonicalExpression[#1, rules] &,
      strip[[1 ;; 2]], {4}];
    If[! multiquadraticStripContextFreeQ[diagonalCanonical],
      Return[$Failed]];
    <|"DiagonalConnectionBlocks" -> diagonalCanonical,
      "DeferredForcingData" ->
        (KeyTake[deferredBundle, {"Variables", "Regulator", "Parameters",
          "CoefficientPresentation", "Dimensions", "TargetOrder",
          "OperandTable", "Jobs", "DivisorOccurrences", "DivisorSummary"}]
          /. rules)|>,
    Map[multiquadraticStripCanonicalExpression[#1, rules] &, strip, {4}]];
  <|"RootCanonicalSquares" -> (multiquadraticStripCanonicalExpression[
      squareRootRecordRadicand[#1], rules] & /@ roots),
    "RootCanonicalExpressions" -> (multiquadraticStripCanonicalExpression[
      squareRootRecordExpression[#1], rules] & /@ roots),
    "EquationCanonical" -> equationCanonical|>
];
multiquadraticStripCoreCanonicalData[___] := $Failed;

(* The tenth argument accepts canonical data a caller has already computed;
   the shorter form derives it before recording the preparation's defining
   data. *)
multiquadraticStripPreparationData[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    gaugeDenominator_, support_List, oneForms_List,
    normalizations_List] :=
  multiquadraticStripPreparationData[record, roots, variables, epsilon, dimensions,
    gaugeDenominator, support, oneForms, normalizations, Automatic];

multiquadraticStripPreparationData[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    gaugeDenominator_, support_List, oneForms_List,
    normalizations_List, canonicalData_] := Module[
  {rules, canonical, canonicalSquares, canonicalRoots, equationCanonical,
   payload},
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  canonical = If[AssociationQ[canonicalData], canonicalData,
    multiquadraticStripCoreCanonicalData[record, roots, variables, epsilon]];
  If[! AssociationQ[canonical], Return[$Failed]];
  {canonicalSquares, canonicalRoots, equationCanonical} = Lookup[canonical,
    {"RootCanonicalSquares", "RootCanonicalExpressions", "EquationCanonical"}];
  payload = <|
    "Schema" -> "MultiquadraticStripPreparationV3",
    "EquationCanonical" -> equationCanonical,
    "RootCanonicalSquares" -> canonicalSquares,
    "RootCanonicalExpressions" -> canonicalRoots,
    "Dimensions" -> dimensions,
    "GaugeDenominator" ->
      multiquadraticStripCanonicalExpression[gaugeDenominator, rules],
    "GaugeSupport" -> support,
    "OneForms" -> Map[
      multiquadraticStripCanonicalExpression[#1, rules] &, oneForms, {2}],
    "Normalizations" -> Map[Join[KeyDrop[#1, "Value"],
      <|"Value" -> multiquadraticStripCanonicalExpression[
        Lookup[#1, "Value", $Failed], rules]|>] &, normalizations]|>;
  (* Persisted defining data must not depend on the caller's context. *)
  If[! FreeQ[payload, $Failed] || ! multiquadraticStripContextFreeQ[payload],
    Return[$Failed]];
  payload
];

Options[multiquadraticStripPrepare] = {
  "OneForms" -> Automatic,
  (* the BASE gauge denominator (Automatic: derived from the forcing and the
     letters).  A supplied value is canonicalized by
     multiquadraticStripMergeGaugeDenominator (unit leading coefficient per
     factor, factors free of the chart variables dropped) and is then
     ENLARGED by the GaugeDenominatorFactor below unless that is pinned to 1;
     a planted or pinned ansatz must pass "GaugeDenominatorFactor" -> 1
     (t_multiquadratic_installed_family_chain, 2026-09-02). *)
  "GaugeDenominator" -> Automatic,
  (* 2026-08-24: an extra polynomial factor of the gauge denominator, in
     the style of the rational engine's denominator options.  Automatic
     means "the norms of the algebraic letters of the alphabet actually
     used": a multiquadratic gauge acquires exactly those, and the
     Max[0, p-1] rule of multiquadraticRationalGaugeDenominator (which
     drops simple poles and never sees a norm at all) cannot produce
     them.  With no algebraic letter the factor is 1 and every existing
     caller is unchanged. *)
  "GaugeDenominatorFactor" -> Automatic,
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic,
  (* exists for ONE caller: solveEpsFormStripMultiquadratic re-preparing
     at an ADOPTED degree offset in the same call.  The channel
     decomposition depends on the strip and the roots only -- never on the
     support -- so the channels of the first preparation are bit for bit
     the ones this one would recompute, at a measured 807 s on CF300
     (12,9).  A supplied set is shape-checked, and Automatic (the
     default) decomposes as before, so every other caller is unchanged. *)
  "ForcingChannels" -> Automatic,
  (* The preparation owns the ansatz metadata, not the coefficient
     representation.  CompiledChannel preserves the historical exact
     channel preparation.  SplitBranch and QuotientGrade deliberately
     leave ForcingChannels absent and derive an automatic conservative
     denominator from the source/bundle divisors; their provider supplies
     finite-field coefficients later.  Automatic remains CompiledChannel
     for direct callers of Prepare; the top-level production driver
     resolves its own Automatic to SplitBranch. *)
  "CoefficientProvider" -> Automatic,
  (* Optional immutable BlockEquationDeferredBundleV2.  Direct providers
     consume it at modular points and the preparation consumes only its
     divisor summary; no dense forcing need be materialized. *)
  "DeferredBundle" -> Automatic,
  (* True makes the forcing channels come from the SEALED, interned
     compile core (E, C and BBar decomposed and compiled once, keyed on
     the equation and the roots), which the compiler then finds already
     built.  False decomposes the forcing here and leaves E and C to the
     compiler.

     Automatic = FALSE.  Pre-building the core pays only where a core is
     REUSED -- a degree-offset ladder rung, a second ansatz on the same
     equation, a re-prepare -- and costs where it is not, because the
     compiler already receives prepare's sealed channels.  Turning it on
     is a measured decision per shape, never a default.  The measurement
     that fixed this default is in
     Results/UU_08_10_canonical/FamilyEpsFormsSolving/
     MultiquadraticMeasurementNarratives_2026-08-26.md, section 1.

     Either way the result is the same: both routes reach a
     byte-identical preparation and the same assembly fingerprints.  The
     False branch goes through the interned decomposer, which returns
     exactly what multiquadraticStripDecomposeScalar returns and so
     cannot change a value, but decomposes each distinct entry once. *)
  "CompileCore" -> Automatic,
  "NormalizationEquations" -> {},
  "RootIndices" -> Automatic,
  (* Internal same-call reuse.  The top-level solver has already classified
     the exact strip before building its alphabet; on an outer-authenticated
     deferred bundle it passes that result here instead of scanning the same
     very large E/C trees again.  Direct Prepare callers keep Automatic. *)
  "RootClassification" -> Automatic,
  (* candidate letter construction; used only when "OneForms" is
     Automatic (or when "LetterRecords" carries a set built by the
     caller in the same call) *)
  "LetterRecords" -> Automatic,
  "RegulatorSampleCount" -> 4,
  "RegulatorSamplePool" -> Automatic,
  "RowAlphabet" -> Automatic,
  "AdditionalLetters" -> {},
  "AlgebraicLetters" -> Automatic,
  "MaximumNormFactors" -> 2,
  "MaximumNormExponent" -> 2,
  (* 1 = serial; 2..8 = requested Wolfram subkernels.  Automatic uses
     already-live subkernels but launches none. *)
  "DLogKernels" -> Automatic,
  (* absolute AbsoluteTime[] value; Infinity = unbounded, the default, so
     every existing caller is unchanged.  See the note at
     multiquadraticStripDeadlineCheckpoint: until 2026-08-25 this was the
     last stage of the engine outside the sector budget. *)
  "Deadline" -> Infinity,
  (* ---- intermediate persistence (2026-08-25).  None (the default)
     writes and reads nothing, so every existing caller is unchanged.
     A directory turns on BOTH: each expensive substage writes its
     sealed record and a later preparation of the SAME inputs reads it
     back instead of recomputing.  "Write" and "Read" split that for a
     driver that wants one direction only. *)
  "CheckpointDirectory" -> None,
  "CheckpointMode" -> Automatic,
  (* Automatic derives the tag from the record's Family / Sector /
     LowerSector, which is what the sector driver already names its
     strip artifacts by *)
  "CheckpointTag" -> Automatic
};

(* `record` is a Module LOCAL initialized from the argument, not the
   pattern name itself: the shared field canonicalizer (round-2 item 4)
   may rewrite the strip into declared radicals, and everything after
     that point -- the defining data, the stored "Record", the compile core
   key, the forcing decomposition -- must see the SAME canonical strip. *)
multiquadraticStripPrepare[sourceRecord_Association, frame_Association,
    opts : OptionsPattern[]] := Module[
  {record = sourceRecord, radicalCanonicalization,
   gate, variables, epsilon, strip, allRoots, classification, rootIndices,
   bundleIndices, requiredRootIndices,
   order, roots, channelForcing, suppliedChannels, oneFormData, oneForms,
   gaugeDenominator,
   letterRecords, gaugeDenominatorFactor,
   denominatorDegrees, degreeOffset, numeratorDegrees, support, dimensions,
   gradeCount, gaugeUnknownCount, residueUnknownCount, unknownCount,
   equationsPerPoint, normalizations, payload,
   coreEnabled, coreCanonical, coreDimensions, coreKey, coreConsumed = False,
   coefficientProvider, deferredBundle, bundleRoots, bundleRootEmbedding,
   bundleGauge,
   deferredPreparationWrapper, deferredPreparation,
   directPreparationQ, directPresentationData, directPresentationRoots,
   directGeneratorIndices, suppliedClassification, trustedClassificationQ,
   refinedBundleGauge,
   provisionalDegrees, provisionalSupportCount, provisionalUnknownCount,
   provisionalEquationsPerPoint, provisionalPointCount,
   provisionalSampleEstimate,
   checkpointDirectory, checkpointMode, checkpointEnabledQ, checkpointTag,
   checkpointRecords = {},
   checkpointRead, checkpointWrite, checkpointDefiningInput,
   forcingCheckpointInput, checkpointChannels,
   letterCheckpointInput, checkpointLetters,
   denominatorCheckpointInput, denominatorCheckpointNorms,
   checkpointDenominator,
   deadline, prepareProgress, prepareBudget, prepareStop, prepareGuard,
   familyName, sectorId, lowerSectorId, startTime = AbsoluteTime[],
   pathStatisticsBefore = multiquadraticFieldPathStatistics[], pathStatistics},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripPrepare]]]];
  If[AssociationQ[gate], Return[gate]];
  (* a malformed request is a caller error and outranks a budget stop,
     exactly as in solveEpsFormStripMultiquadratic *)
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  (* precomputed, NOT read inside prepareProgress: a pattern variable in
     the body of a delayed definition is substituted when the outer rule
     fires, which would embed the whole strip record in that definition
     (the rule TransportCharts.wl records at its own budgetProgress) *)
  {familyName, sectorId, lowerSectorId} = Lookup[record,
    {"Family", "Sector", "LowerSector"}, None];
  (* resume-safe progress: what this preparation had established when it
     stopped, so the next run can see how far the ansatz got *)
  (* The SHAPE is the engine's common typed-stop shape: the same keys
     solveEpsFormStripMultiquadratic's own budgetProgress carries, so a
     preparation stop is shape-compatible with every other stop of this
     engine (t_solver_budget checks exactly that).  The three sampling
     identifiers do not exist yet at this stage and say so honestly
     rather than being omitted. *)
  prepareProgress[] := <|
    "Family" -> familyName, "Sector" -> sectorId,
    "LowerSector" -> lowerSectorId,
    "Prime" -> Missing["NotSampled"],
    "RegulatorValue" -> Missing["NotSampled"],
    "SamplesDone" -> Missing["NotSampled"],
    "RootCount" -> If[ListQ[roots], Length[roots], Missing["NotOrdered"]],
    "ForcingDimensions" -> If[MatchQ[coreDimensions, {_Integer, _Integer}],
      coreDimensions, Missing["NotClassified"]],
    "ForcingChannelsDone" -> ListQ[channelForcing],
    "ForcingChannelSource" -> If[TrueQ[coreConsumed], "CompileCore",
      Missing["NotDecomposed"]],
    "LetterCount" -> If[MatchQ[letterRecords, {___Association}],
      Length[letterRecords], Missing["NotBuilt"]],
    "OneFormCount" -> If[MatchQ[oneForms, {} | {{_, _} ..}],
      Length[oneForms], Missing["NotBuilt"]],
    "UnknownCount" -> If[IntegerQ[unknownCount], unknownCount,
      Missing["NotBuilt"]],
    "SupportSize" -> If[ListQ[support], Length[support],
      Missing["NotBuilt"]]|>;
  prepareBudget[substage_String, extra_Association : <||>] :=
    multiquadraticStripBudgetExhausted["Preparation:" <> substage,
      AbsoluteTime[] - startTime, deadline,
      Join[prepareProgress[], extra]];
  (* one boundary: check, and stop typed if the budget has passed *)
  prepareGuard[substage_String] :=
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      prepareStop = prepareBudget[substage]; True, False];
  If[prepareGuard["Entry"], Return[prepareStop]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  strip = Lookup[record, "Strip", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[strip, {_List, _List, _List}] ||
      SameQ[variables[[1]], variables[[2]]] || MemberQ[variables, epsilon],
    Return[multiquadraticStripFailure["InvalidStripRecord"]]];
  (* A deferred bundle is mathematical input, not telemetry.  Its forcing
     roots are absent from the deliberate zero BBar placeholder, so it must
     authenticate and join the root census before RootIndices is chosen. *)
  deferredBundle = Replace[OptionValue["DeferredBundle"], Automatic :>
    Lookup[record, "DeferredBundle", Missing["NoDeferredBundle"]]];
  deferredPreparationWrapper = Lookup[record, "DeferredPreparation",
    Missing["NoDeferredPreparation"]];
  deferredPreparation = If[AssociationQ[deferredPreparationWrapper],
    Lookup[deferredPreparationWrapper, "Preparation",
      deferredPreparationWrapper], deferredPreparationWrapper];
  (* The raw native route deliberately has no DeferredBundle: its immutable
     BlockEquationDeferred preparation is the coefficient source.  The outer
     solver has already unioned the wrapper's declared square-root generators
     with the visible strip census. *)
  directPresentationData = If[AssociationQ[deferredPreparationWrapper],
    masterTransportCoefficientPresentationData[
      Lookup[deferredPreparationWrapper, "CoefficientPresentation",
        Missing["NoCoefficientPresentation"]], variables], $Failed];
  directPresentationRoots = If[AssociationQ[directPresentationData],
    coefficientPresentationSquareRootsInVariables[
      directPresentationData, variables], $Failed];
  directGeneratorIndices = If[AssociationQ[deferredPreparationWrapper],
    Lookup[deferredPreparationWrapper, "SquareRootGeneratorIndices", $Failed],
    $Failed];
  directPreparationQ = AssociationQ[deferredPreparationWrapper] &&
    AssociationQ[deferredPreparation] &&
    AssociationQ[directPresentationData] &&
    Lookup[directPresentationData, "Status", None] === "OK" &&
    ListQ[directPresentationRoots] &&
    VectorQ[directGeneratorIndices, IntegerQ] &&
    ContainsOnly[directGeneratorIndices,
      Range[Length[directPresentationRoots]]] &&
    directGeneratorIndices === Sort[DeleteDuplicates[directGeneratorIndices]] &&
    Lookup[deferredPreparation, "Status", None] === "Prepared" &&
    Lookup[deferredPreparation, "Variables", None] === variables &&
    Lookup[deferredPreparation, "Regulator", None] === epsilon &&
    Lookup[deferredPreparation, "Dimensions", None] ===
      Dimensions[strip[[3]]];
  allRoots = coefficientPresentationSquareRootsInVariables[frame, variables];
  If[! ListQ[allRoots],
    Return[multiquadraticStripFailure["AlgebraicFrameNotWellFormed"]]];
  multiquadraticStripStageStart["prepare: root census",
    <|"supplied" -> AssociationQ[OptionValue["RootClassification"]]|>];
  suppliedClassification = OptionValue["RootClassification"];
  trustedClassificationQ = AssociationQ[suppliedClassification] &&
    AllTrue[{"UnclassifiedRadicalBases", "RootIndices",
      "BundleRootIndices", "RequiredRootIndices"},
      KeyExistsQ[suppliedClassification, #1] &] &&
    ((AssociationQ[deferredBundle] &&
        Lookup[blockEquationDeferredBundleValidate[deferredBundle],
          "Status", None] === "BundleValid") || directPreparationQ);
  classification = If[trustedClassificationQ, suppliedClassification,
    multiquadraticStripRootCensusWithBundle[strip, allRoots,
      variables, epsilon, deferredBundle]];
  multiquadraticStripStageDone["prepare: root census",
    <|"source" -> If[trustedClassificationQ, "SameCall", "Fresh"]|>];
  If[! KeyExistsQ[classification, "UnclassifiedRadicalBases"],
    Return[classification]];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[multiquadraticStripFailure["StripContainsUndeclaredRadicals",
      <|"RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]]];
  (* THE SHARED CANONICALIZER (round-2 item 4).  Any radical the census
     classified only by denesting is rewritten into declared radicals
     BEFORE anything decomposes: transportChartApplyRootBranches, and so
     multiquadraticFieldDecompose, substitutes declared radicands only,
     and would otherwise fail on a strip transport happily accepts.
     A strip with no denested base takes the no-op branch. *)
  radicalCanonicalization = multiquadraticStripCanonicalizeRadicals[strip,
    allRoots, classification];
  Which[
    Lookup[radicalCanonicalization, "Status", None] ===
      "NoRadicalCanonicalizationNeeded", Null,
    Lookup[radicalCanonicalization, "Status", None] === "RadicalsCanonicalized",
      strip = radicalCanonicalization["Expression"];
      record = Join[record, <|"Strip" -> strip|>],
    True, Return[radicalCanonicalization]];
  bundleIndices = classification["BundleRootIndices"];
  requiredRootIndices = classification["RequiredRootIndices"];
  rootIndices = Replace[OptionValue["RootIndices"],
    Automatic :> Sort[requiredRootIndices]];
  If[! VectorQ[rootIndices, IntegerQ] || rootIndices =!= Sort[rootIndices] ||
      ! DuplicateFreeQ[rootIndices] ||
      ! SubsetQ[rootIndices, Sort[DeleteDuplicates[Join[
          classification["RootIndices"], bundleIndices]]]],
    Return[multiquadraticStripFailure["InvalidRootIndices"]]];
  If[AssociationQ[deferredBundle] && ! ContainsAll[rootIndices, bundleIndices],
    Return[multiquadraticStripFailure[
      "DeferredBundleRootCoverageIncomplete",
      <|"RequiredRootIndices" -> bundleIndices,
        "RootIndices" -> rootIndices|>]]];
  If[directPreparationQ && ! ContainsAll[rootIndices, bundleIndices],
    Return[multiquadraticStripFailure[
      "DeferredPreparationRootCoverageIncomplete",
      <|"RequiredRootIndices" -> bundleIndices,
        "RootIndices" -> rootIndices|>]]];
  If[Length[rootIndices] > $multiquadraticStripMaximumRootCount,
    Return[multiquadraticStripFailure["UnsupportedRootRank",
      <|"MaximumRank" -> $multiquadraticStripMaximumRootCount,
        "ActualRank" -> Length[rootIndices]|>]]];
  (* before the root order, which denests and square-class-matches every
     declared radical *)
  If[prepareGuard["RootOrder"], Return[prepareStop]];
  multiquadraticStripStageStart["prepare: root order"];
  order = multiquadraticStripRootOrder[frame, variables, rootIndices, epsilon];
  multiquadraticStripStageDone["prepare: root order",
    <|"status" -> Lookup[order, "Status", None]|>];
  If[Lookup[order, "Status", None] =!= "StableRootOrder", Return[order]];
  roots = order["Roots"];
  coefficientProvider = Replace[OptionValue["CoefficientProvider"],
    Automatic -> "CompiledChannel"];
  If[! MemberQ[{"CompiledChannel", "SplitBranch", "QuotientGrade"},
      coefficientProvider],
    Return[multiquadraticStripFailure["InvalidCoefficientProvider",
      <|"CoefficientProvider" -> coefficientProvider|>]]];
  If[! MissingQ[deferredBundle],
    bundleRoots = multiquadraticStripBundleSquareRootGenerators[
      deferredBundle, variables];
    If[! ListQ[bundleRoots],
      Return[multiquadraticStripFailure[
        "DeferredBundleCoefficientPresentationMismatch"]]];
    bundleRootEmbedding = multiquadraticStripBundleRootEmbedding[
      bundleRoots, roots];
    If[bundleRootEmbedding === $Failed,
      Return[multiquadraticStripFailure[
        "DeferredBundleRootOrderMismatch"]]];
    record = Join[record, <|"DeferredBundle" -> deferredBundle|>]];
  (* the exact decomposition WITH the recompose check, so the compiler can
     reuse this result inside the same call instead of decomposing the
     forcing a second time (post-mortem item 5: the second decomposition
     was 807 s of the 4872 s compile of CF300 (12,9)) *)
  suppliedChannels = If[coefficientProvider === "CompiledChannel",
    multiquadraticStripForcingChannelsAccept[
      OptionValue["ForcingChannels"], strip[[3]], roots, variables, epsilon],
    <|"Status" -> "NotRequired"|>];
  If[! MemberQ[{"NotSupplied", "Accepted", "NotRequired"},
      Lookup[suppliedChannels, "Status", None]],
    Return[multiquadraticStripFailure[suppliedChannels["Status"],
      KeyDrop[suppliedChannels, "Status"]]]];
  (* Automatic is FALSE here and TRUE in multiquadraticStripCompile: the
     compiler's own core cache is 0.16 s and earns its keep across
     ansatz changes, while building it EARLY was measured at +99.8 s on
     CF300 (12,9).  See the option note above. *)
  coreEnabled = Replace[OptionValue["CompileCore"], Automatic -> False];
  If[! MemberQ[{True, False}, coreEnabled],
    Return[multiquadraticStripFailure["InvalidPrepareCompileCoreOption",
      <|"CompileCore" -> coreEnabled|>]]];
  (* the core key needs the equation and root canonical texts and the
     forcing dimensions, none of which depends on the ansatz.  The
     dimensions are VALIDATED further down exactly where they were
     validated at HEAD: a malformed strip simply fails to key the core
     and takes the fallback, so no failure status moved. *)
  multiquadraticStripStageStart["prepare: equation identity",
    <|"deferred" -> AssociationQ[deferredBundle]|>];
  coreCanonical = multiquadraticStripCoreCanonicalData[record, roots,
    variables, epsilon];
  multiquadraticStripStageDone["prepare: equation identity",
    <|"status" -> If[AssociationQ[coreCanonical], "Prepared", "Failed"]|>];
  coreDimensions = Quiet[Check[Dimensions[strip[[3, 1]]], $Failed]];
  (* ---- the intermediate-persistence layer of THIS preparation ------
     Resolved once, here, so that every substage below is one
     checkpointRead / checkpointWrite pair and nothing about the file
     layout leaks into the substages themselves. *)
  checkpointDirectory = OptionValue["CheckpointDirectory"];
  checkpointMode = Replace[OptionValue["CheckpointMode"],
    Automatic -> "ReadWrite"];
  If[! (checkpointDirectory === None || StringQ[checkpointDirectory]) ||
      ! MemberQ[{"ReadWrite", "Read", "Write", "None"}, checkpointMode],
    Return[multiquadraticStripFailure["InvalidPrepareCheckpointOption",
      <|"CheckpointDirectory" -> checkpointDirectory,
        "CheckpointMode" -> checkpointMode|>]]];
  checkpointEnabledQ = checkpointDirectory =!= None &&
    checkpointMode =!= "None";
  checkpointTag = Replace[OptionValue["CheckpointTag"], Automatic :>
    StringJoin[Riffle[ToString /@ {Lookup[record, "Family", "family"],
      Lookup[record, "Sector", 0], Lookup[record, "LowerSector", 0]}, "_"]]];
  If[! StringQ[checkpointTag] || StringLength[checkpointTag] === 0 ||
      ! StringFreeQ[checkpointTag, {"/", "\\", ".."}],
    Return[multiquadraticStripFailure["InvalidPrepareCheckpointTag",
      <|"CheckpointTag" -> checkpointTag|>]]];
  (* The mathematical inputs every substage shares: this strip's
     canonical differential equation and ordered square-root generators. A substage
     appends whatever else it consumed. *)
  (* Production normally has persistence disabled.  In that case a
     checkpoint identity has no consumer: checkpointRead and checkpointWrite
     both return before looking at it.  Large algebraic metadata must not be
     serialized merely to manufacture a key that will be discarded. *)
  checkpointDefiningInput[substage_String, extra_] :=
    If[checkpointDirectory === None || checkpointMode === "None",
      Missing["CheckpointsDisabled"],
      {substage,
        If[AssociationQ[coreCanonical],
          Lookup[coreCanonical, {"EquationCanonical", "RootCanonicalSquares",
            "RootCanonicalExpressions"}], $Failed],
        coreDimensions, extra}];
  (* read: Missing if persistence is off, this substage has no file, or
     the file exists and does not authenticate -- and in the last case
     the refusal is RECORDED, so a poisoned checkpoint is visible in the
     preparation rather than silently ignored *)
  checkpointRead[substage_String, definingInput_] := Module[
    {file, raw, verdict, readStatus},
    If[checkpointDirectory === None ||
        ! MemberQ[{"ReadWrite", "Read"}, checkpointMode],
      Return[Missing["CheckpointsDisabled"]]];
    file = multiquadraticStripPrepareCheckpointFile[checkpointDirectory,
      checkpointTag, substage];
    If[! FileExistsQ[file],
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Read", "Status" -> "PrepareCheckpointAbsent",
        "File" -> file|>];
      Return[Missing["CheckpointAbsent"]]];
    raw = multiquadraticStripArtifactLoadRaw[file,
      "FeynFacet`MultiquadraticArtifact`"];
    If[Lookup[raw, "Status", None] =!= "RawMultiquadraticArtifact",
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Read", "Status" -> Lookup[raw, "Status", "ReadFailed"],
        "File" -> file|>];
      Return[Missing["CheckpointUnreadable"]]];
    verdict = multiquadraticStripPrepareCheckpointAccept[raw["Value"],
      substage, definingInput, variables, epsilon];
    readStatus = Lookup[verdict, "Status", None];
    AppendTo[checkpointRecords, <|"Substage" -> substage,
      "Action" -> "Read", "Status" -> readStatus,
      "File" -> file,
      "Refusal" -> KeyDrop[verdict, {"Status", "Payload"}]|>];
    If[readStatus =!= "Accepted",
      Return[Missing["CheckpointRefused"]]];
    verdict["Payload"]];
  checkpointWrite[substage_String, definingInput_, payload_] := Module[
    {file, checkpoint, written},
    If[checkpointDirectory === None ||
        ! MemberQ[{"ReadWrite", "Write"}, checkpointMode], Return[Null]];
    checkpoint = multiquadraticStripPrepareCheckpointRecord[substage,
      definingInput, payload, variables, epsilon];
    If[checkpoint === $Failed,
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Write", "Status" -> "PrepareCheckpointNotContextFree"|>];
      Return[Null]];
    file = multiquadraticStripPrepareCheckpointFile[checkpointDirectory,
      checkpointTag, substage];
    written = Quiet[Check[multiquadraticStripArtifactWrite[checkpoint, file],
      $Failed]];
    AppendTo[checkpointRecords, <|"Substage" -> substage,
      "Action" -> "Write",
      "Status" -> If[AssociationQ[written],
        Lookup[written, "Status", "WriteFailed"], "PrepareCheckpointWriteFailed"],
      "File" -> file|>];
    Null];
  coreKey = If[AssociationQ[coreCanonical] &&
      MatchQ[coreDimensions, {_Integer, _Integer}] &&
      FreeQ[coreCanonical, $Failed],
    multiquadraticStripCompileCoreKeyFromParts[
      coreCanonical["EquationCanonical"],
      coreCanonical["RootCanonicalSquares"],
      coreCanonical["RootCanonicalExpressions"], coreDimensions],
    $Failed];
  (* before the forcing decomposition -- the stage that made this
     coverage necessary *)
  If[prepareGuard["ForcingChannels"], Return[prepareStop]];
  (* CHECKPOINT (2026-08-25).  The payload of the forcing checkpoint IS
     the V2 sealed forcing-channel record, so a checkpoint read is
     authenticated by exactly the code path an in-memory reuse is: the
     envelope proves the file belongs to this strip and this source, and
     the seal inside it proves the channels are the decomposition of
     THIS forcing.  A mutated channel fails the inner seal even if the
     envelope is rebuilt around it. *)
  forcingCheckpointInput = If[checkpointEnabledQ,
    checkpointDefiningInput["ForcingChannels", {}],
    Missing["CheckpointsDisabled"]];
  checkpointChannels = If[coefficientProvider =!= "CompiledChannel" ||
      suppliedChannels["Status"] === "Accepted",
    Missing["ChannelsSupplied"],
    Module[{stored = checkpointRead["ForcingChannels",
        forcingCheckpointInput], accept},
      If[MissingQ[stored], Missing["NoCheckpoint"],
        accept = multiquadraticStripForcingChannelsAccept[stored, strip[[3]],
          roots, variables, epsilon];
        AppendTo[checkpointRecords, <|"Substage" -> "ForcingChannels",
          "Action" -> "Seal", "Status" -> Lookup[accept, "Status", None]|>];
        If[Lookup[accept, "Status", None] === "Accepted", accept["Channels"],
          Missing["CheckpointSealRefused"]]]]];
  channelForcing = Which[
    coefficientProvider =!= "CompiledChannel", Missing["DirectProvider"],
    suppliedChannels["Status"] === "Accepted", suppliedChannels["Channels"],
    ! MissingQ[checkpointChannels],
      multiquadraticStripStageMark["prepare: forcing channel decomposition",
        <|"source" -> "Checkpoint", "forcing" -> coreDimensions|>];
      checkpointChannels,
    True,
    Module[{stage = "prepare: forcing channel decomposition", seconds = 0.,
        built = $Failed},
      multiquadraticStripStageStart[stage,
        <|"family" -> Lookup[record, "Family", None],
          "sector" -> Lookup[record, "Sector", None],
          "lower" -> Lookup[record, "LowerSector", None],
          "forcing" -> coreDimensions, "rank" -> Length[roots],
          "grades" -> 2^Length[roots],
          "route" -> If[TrueQ[coreEnabled] && coreKey =!= $Failed,
            "CompileCore", "Independent"]|>];
      (* the VALUE pools are per call at both ends, exactly as in the
         compiler: they make one call decompose each unique value once
         and are never carried between calls *)
      multiquadraticStripInternReset["Scalar"];
      multiquadraticStripInternReset["Rational"];
      (* the decomposition loops read the deadline per entry and leave by
         Throw; Block restores the dynamic value on every exit path,
         including the Throw *)
      built = Catch[
        Block[{$multiquadraticStripActiveDeadline = deadline},
          {seconds, built} = AbsoluteTiming[
            If[TrueQ[coreEnabled] && coreKey =!= $Failed,
              Module[{core = multiquadraticStripCompileCoreRecord[strip, roots,
                  variables, epsilon, Missing["NotSupplied"], coreKey, True]},
                If[AssociationQ[core],
                  Lookup[Lookup[core, "BBar", <||>], "Channels", $Failed],
                  $Failed]],
              $Failed]];
          coreConsumed = built =!= $Failed && FreeQ[built, $Failed];
          If[! coreConsumed,
            {seconds, built} = AbsoluteTiming[
              multiquadraticStripDecomposeForcing[strip[[3]], roots]]];
          built],
        $multiquadraticStripDeadlineTag,
        Function[{payload, tag},
          prepareStop = prepareBudget[
            Lookup[payload, "Substage", "ForcingChannels"],
            KeyDrop[payload, "Substage"]];
          $Failed]];
      multiquadraticStripInternReset["Scalar"];
      multiquadraticStripInternReset["Rational"];
      multiquadraticStripStageDone[stage,
        <|"seconds" -> N[seconds],
          "source" -> Which[AssociationQ[prepareStop], "BudgetExhausted",
            coreConsumed, "CompileCore", True, "Independent"]|>];
      built]];
  If[AssociationQ[prepareStop], Return[prepareStop]];
  If[! FreeQ[channelForcing, $Failed],
    Return[multiquadraticStripFailure["ForcingChannelDecompositionFailed"]]];
  (* written only when this call actually decomposed: a checkpoint that
     was just read back is not rewritten, and a supplied decomposition
     belongs to its caller, not to this strip's persistence *)
  If[coefficientProvider === "CompiledChannel" &&
      suppliedChannels["Status"] =!= "Accepted" && MissingQ[checkpointChannels],
    checkpointWrite["ForcingChannels", forcingCheckpointInput,
      multiquadraticStripForcingChannelRecord[channelForcing, strip[[3]],
        roots, variables, epsilon]]];
  letterRecords = OptionValue["LetterRecords"];
  oneFormData = OptionValue["OneForms"];
  (* before the candidate-letter construction, a single opaque call *)
  If[prepareGuard["CandidateLetters"], Return[prepareStop]];
  If[oneFormData === Automatic,
    If[! MatchQ[letterRecords, {___Association}],
      (* CHECKPOINT: the whole candidate-letter record, keyed on the
         strip, the root order, the letter-construction options and the
         row alphabet the record supplies -- the complete input of
         multiquadraticStripCandidateLetters. *)
      letterCheckpointInput = If[checkpointEnabledQ,
        checkpointDefiningInput[
          "CandidateLetters",
          {OptionValue["RegulatorSampleCount"],
           OptionValue["RegulatorSamplePool"],
           OptionValue["RowAlphabet"] /.
             multiquadraticStripCanonicalRules[variables, epsilon],
           OptionValue["AdditionalLetters"] /.
             multiquadraticStripCanonicalRules[variables, epsilon],
           OptionValue["AlgebraicLetters"] /.
             multiquadraticStripCanonicalRules[variables, epsilon],
           OptionValue["MaximumNormFactors"],
           OptionValue["MaximumNormExponent"],
           Lookup[record, {"Sector", "LowerSector"}, None],
           Replace[Lookup[record, "StripSolvers", {}], Except[_List] :> {}] /.
             multiquadraticStripCanonicalRules[variables, epsilon]}],
        Missing["CheckpointsDisabled"]];
      checkpointLetters = checkpointRead["CandidateLetters",
        letterCheckpointInput];
      If[! MissingQ[checkpointLetters] &&
          Lookup[checkpointLetters, "Status", None] ===
            "MultiquadraticCandidateLettersV1",
        multiquadraticStripStageMark["prepare: candidate letters",
          <|"source" -> "Checkpoint",
            "letters" -> Length[Lookup[checkpointLetters, "LetterRecords",
              {}]]|>];
        letterRecords = checkpointLetters,
        checkpointLetters = Missing["NoCheckpoint"];
        multiquadraticStripStageStart["prepare: candidate letters",
          <|"family" -> Lookup[record, "Family", None],
            "sector" -> Lookup[record, "Sector", None],
            "lower" -> Lookup[record, "LowerSector", None],
            "rank" -> Length[roots], "forcing" -> coreDimensions|>];
        letterRecords = multiquadraticStripCandidateLetters[strip, roots,
          variables, epsilon, record,
          "RegulatorSampleCount" -> OptionValue["RegulatorSampleCount"],
          "RegulatorSamplePool" -> OptionValue["RegulatorSamplePool"],
          "RowAlphabet" -> OptionValue["RowAlphabet"],
          "AdditionalLetters" -> OptionValue["AdditionalLetters"],
          "AlgebraicLetters" -> OptionValue["AlgebraicLetters"],
          "MaximumNormFactors" -> OptionValue["MaximumNormFactors"],
          "MaximumNormExponent" -> OptionValue["MaximumNormExponent"],
          "DLogKernels" -> OptionValue["DLogKernels"],
          "Deadline" -> deadline];
        multiquadraticStripStageDone["prepare: candidate letters",
          <|"status" -> Lookup[letterRecords, "Status", None],
            "letters" -> Length[Lookup[letterRecords, "LetterRecords", {}]]|>]];
      If[Lookup[letterRecords, "Status", None] =!=
          "MultiquadraticCandidateLettersV1",
        Return[If[AssociationQ[letterRecords], letterRecords,
          multiquadraticStripFailure["OneFormBasisFailed"]]]];
      If[MissingQ[checkpointLetters],
        checkpointWrite["CandidateLetters", letterCheckpointInput,
          letterRecords]];
      oneFormData = letterRecords;
      letterRecords = oneFormData["LetterRecords"],
      oneFormData = <|"OneForms" -> Lookup[letterRecords, "OneForm", {}],
        "DeduplicatedCount" -> Length[letterRecords]|>]];
  oneForms = If[AssociationQ[oneFormData],
    Lookup[oneFormData, "OneForms", $Failed], oneFormData];
  If[! MatchQ[oneForms, {} | {{_, _} ..}],
    Return[multiquadraticStripFailure["OneFormBasisFailed"]]];
  (* after the alphabet is fixed and before the gauge denominator, which
     factors the norms of every algebraic letter actually used *)
  If[prepareGuard["GaugeDenominator"], Return[prepareStop]];
  (* CHECKPOINT: the norm factorization of every algebraic letter plus
     the merge with the rational denominator.  Its inputs are the
     alphabet actually used and the two denominator options. *)
  denominatorCheckpointNorms = If[
    MatchQ[letterRecords, {___Association}],
    DeleteCases[
      Lookup[#1, "Norm", Missing["NoNorm"]] & /@ letterRecords,
      _Missing], {}];
  multiquadraticStripStageStart[
    "prepare: gauge denominator checkpoint identity",
    <|"enabled" -> checkpointEnabledQ,
      "norms" -> Length[denominatorCheckpointNorms]|>];
  denominatorCheckpointInput = If[checkpointEnabledQ,
    checkpointDefiningInput[
      "GaugeDenominator",
      {denominatorCheckpointNorms /.
         multiquadraticStripCanonicalRules[variables, epsilon],
       OptionValue["GaugeDenominatorFactor"] /.
         multiquadraticStripCanonicalRules[variables, epsilon],
       OptionValue["GaugeDenominator"] /.
         multiquadraticStripCanonicalRules[variables, epsilon],
       If[AssociationQ[deferredBundle],
         Lookup[deferredBundle, "DivisorSummary", None], None]}],
    Missing["CheckpointsDisabled"]];
  multiquadraticStripStageDone[
    "prepare: gauge denominator checkpoint identity"];
  checkpointDenominator = checkpointRead["GaugeDenominator",
    denominatorCheckpointInput];
  If[MatchQ[checkpointDenominator,
      {_, _} | {_, _, {_Integer, _Integer}}],
    multiquadraticStripStageMark["prepare: gauge denominator",
      <|"source" -> "Checkpoint"|>];
    If[Length[checkpointDenominator] === 3,
      {gaugeDenominatorFactor, gaugeDenominator, denominatorDegrees} =
        checkpointDenominator,
      {gaugeDenominatorFactor, gaugeDenominator} = checkpointDenominator;
      denominatorDegrees = Missing["NotStored"]],
    checkpointDenominator = Missing["NoCheckpoint"];
    gaugeDenominatorFactor = Replace[OptionValue["GaugeDenominatorFactor"],
      Automatic :> If[MatchQ[letterRecords, {___Association}],
        multiquadraticStripNormDenominatorFactor[letterRecords, variables], 1]];
    gaugeDenominator = Replace[OptionValue["GaugeDenominator"], {
      supplied_ /; supplied =!= Automatic :>
        multiquadraticStripMergeGaugeDenominator[
          supplied, gaugeDenominatorFactor, variables],
      Automatic :> If[coefficientProvider === "CompiledChannel",
        multiquadraticStripMergeGaugeDenominator[
          multiquadraticRationalGaugeDenominator[channelForcing, variables],
          gaugeDenominatorFactor, variables],
        If[AssociationQ[deferredBundle],
          multiquadraticStripStageStart[
            "prepare: bundle gauge denominator"];
          bundleGauge = multiquadraticStripBundleGaugeDenominator[
            deferredBundle, variables,
            If[MatchQ[letterRecords, {___Association}], letterRecords, {}]];
          multiquadraticStripStageDone[
            "prepare: bundle gauge denominator",
            <|"status" -> Lookup[bundleGauge, "Status", None],
              "factors" -> Lookup[bundleGauge, "FactorCount", None],
              "groups" -> Lookup[bundleGauge, "GroupedFactorCount", None],
              "seconds" -> Lookup[bundleGauge, "Seconds", None]|>];
          If[Lookup[bundleGauge, "Status", None] =!=
              "BundleGaugeDenominatorV1", Return[bundleGauge, Module]];
          (* Refine only when the pre-cancellation rectangle would exceed
             the sampler's hard memory ceiling.  Small/easy blocks retain
             the cheap divisor-summary path exactly. *)
          If[OptionValue["Support"] === Automatic &&
              MatchQ[coreDimensions, {_Integer, _Integer}] &&
              MatchQ[OptionValue["DegreeOffset"],
                {_Integer?NonNegative, _Integer?NonNegative}],
            provisionalDegrees =
              bundleGauge["GaugeDenominatorDegrees"] +
                OptionValue["DegreeOffset"];
            provisionalSupportCount = Times @@ (provisionalDegrees + 1);
            provisionalUnknownCount = (Times @@ coreDimensions) *
                2^Length[roots] * provisionalSupportCount +
              Length[oneForms] * (Times @@ coreDimensions);
            provisionalEquationsPerPoint = 2 * (Times @@ coreDimensions) *
              2^Length[roots];
            provisionalPointCount = Max[4, Ceiling[
              (provisionalUnknownCount + provisionalEquationsPerPoint)/
                provisionalEquationsPerPoint]];
            provisionalSampleEstimate = multiquadraticStripSampleSizeEstimate[
              provisionalPointCount, provisionalEquationsPerPoint, 0,
              provisionalUnknownCount];
            If[AssociationQ[provisionalSampleEstimate] &&
                provisionalSampleEstimate["PeakPackedBytesLowerBound"] >
                  $multiquadraticStripSampleMaximumBytes,
              multiquadraticStripStageStart[
                "prepare: exact bundle denominator refinement",
                <|"preCancellationUnknowns" -> provisionalUnknownCount,
                  "preCancellationPeakBytes" ->
                    provisionalSampleEstimate[
                      "PeakPackedBytesLowerBound"],
                  "entries" -> Times @@ coreDimensions,
                  "rank" -> Length[roots]|>];
              refinedBundleGauge =
                multiquadraticStripBundleRefinedGaugeDenominator[
                  deferredBundle, roots, variables, epsilon,
                  If[MatchQ[letterRecords, {___Association}],
                    letterRecords, {}]];
              multiquadraticStripStageDone[
                "prepare: exact bundle denominator refinement",
                <|"status" -> Lookup[refinedBundleGauge, "Status", None],
                  "seconds" -> Lookup[refinedBundleGauge, "Seconds",
                    Missing["NotMeasured"]],
                  "helpers" -> Lookup[refinedBundleGauge,
                    "BrokerHelperCount", 0]|>];
              If[Lookup[refinedBundleGauge, "Status", None] =!=
                  "BundleRefinedGaugeDenominatorV1",
                Return[refinedBundleGauge, Module]];
              bundleGauge = Join[bundleGauge, <|
                "PreCancellationGaugeDenominator" ->
                  bundleGauge["GaugeDenominator"],
                "GaugeDenominator" ->
                  refinedBundleGauge["GaugeDenominator"],
                "GaugeDenominatorDegrees" ->
                  refinedBundleGauge["GaugeDenominatorDegrees"],
                "ExactCancellationRefinement" ->
                  KeyDrop[refinedBundleGauge, "GaugeDenominator"],
                "PreCancellationSampleEstimate" ->
                  provisionalSampleEstimate|>]]];
          denominatorDegrees = bundleGauge["GaugeDenominatorDegrees"];
          bundleGauge["GaugeDenominator"],
          multiquadraticStripConservativeGaugeDenominator[strip, roots,
            letterRecords, variables]]]}]];
  If[TrueQ[Together[gaugeDenominatorFactor] === 0] ||
      ! FreeQ[gaugeDenominatorFactor,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorFactorNotRational",
      <|"GaugeDenominatorFactor" -> gaugeDenominatorFactor|>]]];
  If[TrueQ[gaugeDenominator === 0] ||
      ! FreeQ[gaugeDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticStripFailure["GaugeDenominatorNotRational"]]];
  If[! MatchQ[denominatorDegrees,
      {_Integer?NonNegative, _Integer?NonNegative}],
    multiquadraticStripStageStart[
      "prepare: gauge denominator degrees"];
    denominatorDegrees = Exponent[gaugeDenominator, #1] & /@ variables;
    multiquadraticStripStageDone[
      "prepare: gauge denominator degrees",
      <|"degrees" -> denominatorDegrees|>]];
  If[MissingQ[checkpointDenominator],
    checkpointWrite["GaugeDenominator", denominatorCheckpointInput,
      {gaugeDenominatorFactor, gaugeDenominator, denominatorDegrees}]];
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticStripFailure["InvalidDegreeOffset"]]];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  support = OptionValue["Support"];
  If[support === Automatic,
    support = Flatten[Table[{i, j}, {i, 0, numeratorDegrees[[1]]},
      {j, 0, numeratorDegrees[[2]]}], 1]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support, MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[multiquadraticStripFailure["InvalidSupport"]]];
  support = Sort[DeleteDuplicates[support]];
  dimensions = Dimensions[strip[[3, 1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      Dimensions[strip[[3]]] =!= Prepend[dimensions, 2],
    Return[multiquadraticStripFailure["InvalidForcingDimensions"]]];
  If[Dimensions[strip[[1]]] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[strip[[2]]] =!= {2, dimensions[[2]], dimensions[[2]]},
    Return[multiquadraticStripFailure["InvalidDiagonalDimensions"]]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount Length[support];
  residueUnknownCount = Length[oneForms] (Times @@ dimensions);
  unknownCount = gaugeUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 (Times @@ dimensions);
  normalizations = multiquadraticStripCompileNormalizations[
    OptionValue["NormalizationEquations"], dimensions, gradeCount, support,
    oneForms, gaugeUnknownCount];
  If[! ListQ[normalizations], Return[normalizations]];
  (* Before recording the defining mathematical data. *)
  If[prepareGuard["DefiningData"], Return[prepareStop]];
  (* the canonical equation/root texts were already paid for above, when
     the compile core was keyed; handing them over is what keeps the
     whole-strip InputForm to ONE pass *)
  payload = multiquadraticStripPreparationData[record, roots, variables, epsilon,
    dimensions, gaugeDenominator, support, oneForms, normalizations,
    coreCanonical];
  If[payload === $Failed,
    Return[multiquadraticStripFailure["ContextSensitivePreparationData"]]];
  pathStatistics = multiquadraticFieldPathStatisticsDelta[pathStatisticsBefore,
    multiquadraticFieldPathStatistics[]];
  <|"Status" -> "PreparedMultiquadraticStripV1",
    "PreparationSchema" -> payload["Schema"],
    "Record" -> record, "CoefficientPresentation" -> frame,
    "Variables" -> variables, "Regulator" -> epsilon,
    "Roots" -> roots, "RootCount" -> Length[roots],
    "RootIndices" -> rootIndices,
    "RootCensus" -> KeyTake[classification, {"RootIndices", "RadicalBases",
      "DenestedRootIndices", "NumericRadicalClasses",
      "FrameCensusRootIndices", "FrameCensusUnclassified",
      "BundleRootIndices", "RequiredRootIndices"}],
    (* what the shared field canonicalizer rewrote, if anything: a
       diagnostic field; the defining data already contains the canonical
       differential equation. *)
    "RadicalCanonicalization" -> KeyTake[radicalCanonicalization,
      {"Status", "Rewritten", "Bases", "Signs"}],
    (* Which declaration slot each selected generator came from. *)
    "RootSourceIndices" -> order["SourceIndices"],
    "RootSquares" -> (squareRootRecordRadicand /@ roots),
    "OneForms" -> oneForms, "OneFormMetadata" -> oneFormData,
    (* The letters and exact forcing channels of this call; the compiler reuses
       the channels rather than decomposing the forcing again *)
    "LetterRecords" -> If[MatchQ[letterRecords, {___Association}],
      letterRecords, Missing["LettersSuppliedAsOneForms"]],
    "AlgebraicLetterCount" -> If[MatchQ[letterRecords, {___Association}],
      Count[letterRecords, item_ /; Lookup[item, "Kind", None] === "Algebraic"],
      Missing["LettersSuppliedAsOneForms"]],
    (* ---- CERTIFIED dlog POTENTIALS (round-2 item 7).  The preparation
       states, for the alphabet it actually installed, whether every
       one-form carries a VERIFIED potential omega = dlog L.  A caller
       that supplied bare one-forms has no letters to verify, and the
       verdict is then False with the reason recorded: a closed one-form
       with no verified potential is not installable, which is the
       refusal both reviews asked to keep. *)
    "Potentials" -> If[MatchQ[letterRecords, {___Association}],
      KeyTake[#1, {"Kind", "Letter", "FormKey", "Potential"}] & /@
        letterRecords,
      Missing["LettersSuppliedAsOneForms"]],
    (* since round-3 A2 this is CANDIDATE-POOL telemetry: the terminal
       certification bit is the ACTIVE-support verdict, computed only
       after regulator reconstruction, because an unused candidate with
       zero reconstructed residue cannot obstruct installation *)
    "PotentialsCertified" -> If[MatchQ[letterRecords, {___Association}],
      multiquadraticStripPotentialsCertifiedQ[letterRecords], False],
    "PotentialsCertifiedReason" -> Which[
      ! MatchQ[letterRecords, {___Association}],
        "OneFormsSuppliedWithoutLetters",
      letterRecords === {}, "EmptyAlphabet",
      multiquadraticStripPotentialsCertifiedQ[letterRecords],
        "EveryOneFormCarriesAVerifiedPotential",
      True, "SomeOneFormHasNoVerifiedPotential"],
    (* Map, NOT Lookup[list, key, default]: Lookup reads an EMPTY list as
       an empty list of RULES and returns the DEFAULT rather than an empty
       list, so on an alphabet with nothing unverified this fed Counts a
       bare None (Counts::invrp, found by the round-2 final gate).  Map is
       correct on the empty list and on every other. *)
    "PotentialsUnverifiedKinds" -> If[MatchQ[letterRecords, {___Association}],
      Counts[Lookup[#1, "Kind", None] & /@ Select[letterRecords,
        ! TrueQ[Lookup[Lookup[#1, "Potential", <||>], "Verified", False]] &]],
      Missing["LettersSuppliedAsOneForms"]],
    "GaugeDenominatorFactor" -> Together[gaugeDenominatorFactor],
    (* The record carries the mathematical forcing and ordered generators
       it decomposes. *)
    "ForcingChannels" -> If[coefficientProvider === "CompiledChannel",
      multiquadraticStripForcingChannelRecord[channelForcing, strip[[3]],
        roots, variables, epsilon], Missing["DirectProvider"]],
    "DeferredBundle" -> If[AssociationQ[deferredBundle], deferredBundle,
      Missing["NoDeferredBundle"]],
    "BundleDivisorProvenance" -> If[AssociationQ[bundleGauge],
      KeyDrop[bundleGauge, "GaugeDenominator"],
      Missing["BundleGaugeDenominatorNotUsed"]],
    "CoefficientProvider" -> coefficientProvider,
    "GaugeDenominator" -> Together[gaugeDenominator],
    "GaugeDenominatorDegrees" -> denominatorDegrees,
    "GaugeSupport" -> support, "Dimensions" -> dimensions,
    "GradeCount" -> gradeCount,
    "GaugeUnknownCount" -> gaugeUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> equationsPerPoint,
    "Normalizations" -> normalizations,
    "ColumnOrder" -> multiquadraticStripColumnOrder[dimensions, gradeCount,
      support, Length[oneForms]],
    "RowOrder" -> multiquadraticStripRowOrder[dimensions, gradeCount],
    (* channel-decomposition telemetry of THIS preparation, not of the
       process: the scalar-local root-free fast path count and the
       algebraic (field reduction + inversion) count *)
    "RootFreeFastPathCount" -> pathStatistics["RootFreeFastPathCount"],
    "ChannelPathStatistics" -> pathStatistics,
    (* What this preparation persisted and read back. *)
    "PrepareCheckpoints" -> checkpointRecords,
    "DefiningData" -> payload|>
];
multiquadraticStripPrepare[___] :=
  multiquadraticStripFailure["InvalidPrepareArguments"];

multiquadraticStripPreparationValidQ[preparation_Association] := Module[
  {payload, roots, dimensions, gradeCount, gaugeUnknownCount, residueUnknownCount},
  If[Lookup[preparation, "Status", None] =!= "PreparedMultiquadraticStripV1",
    Return[False]];
  roots = Lookup[preparation, "Roots", $Failed];
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  If[! ListQ[roots] || ! MatchQ[dimensions, {_Integer, _Integer}], Return[False]];
  payload = multiquadraticStripPreparationData[preparation["Record"], roots,
    preparation["Variables"], preparation["Regulator"], dimensions,
    preparation["GaugeDenominator"], preparation["GaugeSupport"],
    preparation["OneForms"], preparation["Normalizations"]];
  If[payload === $Failed, Return[False]];
  gradeCount = 2^Length[roots];
  gaugeUnknownCount = (Times @@ dimensions) gradeCount
    Length[preparation["GaugeSupport"]];
  residueUnknownCount = Length[preparation["OneForms"]] (Times @@ dimensions);
  TrueQ[
    payload === Lookup[preparation, "DefiningData", Missing["Data"]] &&
    Lookup[preparation, "RootCount", Missing["RootCount"]] === Length[roots] &&
    Lookup[preparation, "GradeCount", Missing["GradeCount"]] === gradeCount &&
    Lookup[preparation, "GaugeUnknownCount", Missing["Gauge"]] ===
      gaugeUnknownCount &&
    Lookup[preparation, "ResidueUnknownCount", Missing["Residue"]] ===
      residueUnknownCount &&
    Lookup[preparation, "UnknownCount", Missing["Unknown"]] ===
      gaugeUnknownCount + residueUnknownCount &&
    Lookup[preparation, "EquationsPerPoint", Missing["Equations"]] ===
      gradeCount 2 (Times @@ dimensions)]
];

(* ------------------------------------------------------------------ *)
(* Exact channel compilation into a sparse x/y polynomial ABI           *)
(* ------------------------------------------------------------------ *)

(* Terms sharing an x/y monomial are grouped; the row keeps the exact
   coefficients of eps^0..eps^K, so one compilation serves every
   regulator value and every prime. *)
multiquadraticStripCompilePolynomial[polynomial_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[
  {vars = Append[variables, epsilon], expanded, rules, groups, xExponents,
   yExponents, maximumEpsilonDegree, coefficientRows},
  expanded = Expand[polynomial];
  If[! PolynomialQ[expanded, vars], Return[$Failed]];
  rules = CoefficientRules[expanded, vars];
  If[rules === {}, Return[<|"Type" -> "MultiquadraticPolynomialExactV1",
    "XExponents" -> {}, "YExponents" -> {}, "EpsilonCoefficientRows" -> {}|>]];
  If[! AllTrue[Last /@ rules, IntegerQ[#1] || Head[#1] === Rational &],
    Return[$Failed]];
  maximumEpsilonDegree = Max[rules[[All, 1, 3]]];
  If[maximumEpsilonDegree > $multiquadraticStripMaximumEpsilonDegree,
    Return[$Failed]];
  groups = GatherBy[rules, First[#1][[1 ;; 2]] &];
  xExponents = groups[[All, 1, 1, 1]];
  yExponents = groups[[All, 1, 1, 2]];
  coefficientRows = Table[
    Module[{row = ConstantArray[0, Max[group[[All, 1, 3]]] + 1]},
      Do[row[[rule[[1, 3]] + 1]] += rule[[2]], {rule, group}]; row],
    {group, groups}];
  <|"Type" -> "MultiquadraticPolynomialExactV1",
    "XExponents" -> Developer`ToPackedArray[xExponents],
    "YExponents" -> Developer`ToPackedArray[yExponents],
    "EpsilonCoefficientRows" -> coefficientRows|>
];

multiquadraticStripCompileRational[expression_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[{rational, numerator, denominator},
  rational = Together[expression];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  numerator = multiquadraticStripCompilePolynomial[Numerator[rational],
    variables, epsilon];
  denominator = multiquadraticStripCompilePolynomial[Denominator[rational],
    variables, epsilon];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalExactV1", "Numerator" -> numerator,
    "Denominator" -> denominator|>
];

multiquadraticStripDecomposeScalar[expression_, roots_List] := Module[
  {channels, reconstructed},
  channels = multiquadraticFieldDecompose[expression, roots];
  If[! ListQ[channels] || Length[channels] =!= 2^Length[roots] ||
      MemberQ[channels, $Failed], Return[$Failed]];
  reconstructed = multiquadraticFieldCompose[channels, roots];
  If[! TrueQ[Together[reconstructed - expression] === 0], Return[$Failed]];
  channels
];

multiquadraticStripCompileTensor[tensor_, scalarLevel_Integer, roots_List,
    variables_List, epsilon_Symbol] := Module[{channels, compiled},
  channels = Map[multiquadraticStripDecomposeScalar[#1, roots] &, tensor,
    {scalarLevel}];
  If[! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[multiquadraticStripCompileRational[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

(* ------------------------------------------------------------------ *)
(* The compile architecture (2026-08-25)                                *)
(* ------------------------------------------------------------------ *)

(* Source: Codex's Q1 answer,
   Exchange/Fable/2026-08-24/01_cf300_12_9_state_and_reply/
   codex_response_to_fable_cf300_129_2026-08-24.md, on a compile
   measured at 4872 s against a 0.7 s affine solve on CF300 (12,9).
   Five changes, in Codex's order:

     1 an immutable compiled equation CORE (E, C, BBar, root squares and
       their log derivatives) keyed on the equation, the roots and the
       chart symbols only, plus a separately keyed gauge-denominator
       record.  Neither depends on the ansatz, so a support or
       DegreeOffset change compiles NOTHING and an exact-prefix alphabet
       extension compiles only the suffix (Codex's measured rebind
       evidence: 12 s against 691 s for a fresh compile);

     2 interned exact scalars and channel values: a hash bucket with a
       SameQ collision check, so each unique value is decomposed and
       compiled once.  The zero channel of a 2^r grade vector, and the
       zero entries of a sparse E/C/BBar, are the common case;

     3 compact letter channels.  For a letter L = A + B r_m the one-form
       dlog L is built from the LETTER's own grade channels, its
       derivative in the grade basis and the norm A^2 - B^2 delta_m; the
       expanded D[L]/L tree is never decomposed.  That tree is the
       measured expensive object (the forcing-dlog letters carry 10^4 to
       10^5 leaves).  A general multigrade letter takes the same route
       through the existing field multiplication/inversion ABI;

     4 the canonical rational pair returned by the field decomposition
       feeds CoefficientRules directly; the second Together (a
       multivariate GCD of two large polynomials, for nothing) is gone;

     5 the remaining unique one-form suffix may be brokered into 2 to 4
       IMMUTABLE compile shards.  Naive parallelism duplicates work and
       peak memory, so this is opt-in and last.

   Nothing here changes what is compiled: every acceptance the old
   compiler made (exact decomposition with a recompose check, exact
   inverse product check, polynomial shape checks) is made here, and the
   compact letter path is admitted only when the letter record PROVES
   the stored one-form is the dlog of the record's letter. *)

ClearAll[
  multiquadraticStripInternReset, multiquadraticStripIntern,
  multiquadraticStripInternValidQ,
  multiquadraticStripInternProbe, multiquadraticStripInternStatistics,
  multiquadraticStripCompileCacheClear,
  multiquadraticStripCompileRationalFromPair,
  multiquadraticStripCompileRationalCanonical,
  multiquadraticStripDecomposeScalarInterned,
  multiquadraticStripCompileRationalInterned,
  multiquadraticStripCompileTensorInterned,
  multiquadraticStripCompactInverse, multiquadraticStripLetterChannelPair,
  multiquadraticStripCompileOneFormEntry, multiquadraticStripCompileOneForms,
  multiquadraticStripCompileShardTask,
  multiquadraticStripCompileCoreKey, multiquadraticStripCompileCoreKeyFromParts,
  multiquadraticStripCompileCoreRecord,
  multiquadraticStripCompileDenominatorRecord,
  multiquadraticStripCompileLegacyCore,
  multiquadraticStripCompileLegacyDenominator,
  $multiquadraticStripInternPools, $multiquadraticStripInternCounters,
  $multiquadraticStripInternCounterNames,
  $multiquadraticStripPoolEntryLimit, $multiquadraticStripCompileShardMinimum
];

$multiquadraticStripInternPools = <||>;
$multiquadraticStripInternCounters = <||>;

(* "Scalar" and "Rational" are VALUE pools, reset at both ends of a
   compile call: they exist to make one call compile each unique value
   once, and holding them would grow a long-lived pool kernel without
   bound.  "Core", "GaugeDenominator" and "OneForm" are the persistent
   pools -- they ARE the core/ansatz split -- and are bounded by entry
   count; a pool at its cap starts again rather than growing.

   BYTE BOUNDS (2026-08-25, Codex 14:30 "persistent cache memory bound").
   An entry count is not a memory bound: one CF300-sized compile core is
   hundreds of megabytes and two of them are the whole ceiling, while
   512 small one-forms are nothing.  Each pool therefore also declares a
   MEASURED ByteCount ceiling, and an OVERSIZE value -- one that alone
   exceeds the pool's own oversize allowance -- BYPASSES the cache
   instead of evicting it: returning it to the caller uncached costs one
   recomputation, while admitting it would flush every entry the pool
   holds to store something that cannot be held anyway.  ByteCount is
   measured once per admitted value; it is a traversal, and it is taken
   only on a MISS, never on a hit. *)
$multiquadraticStripPoolEntryLimit = <|
  "Core" -> 2, "GaugeDenominator" -> 16, "OneForm" -> 512|>;

(* the pool's total measured ByteCount ceiling *)
$multiquadraticStripPoolByteLimit = <|
  "Core" -> 2. 10^9, "GaugeDenominator" -> 2. 10^8, "OneForm" -> 1. 10^9|>;

(* a single value above this is never admitted: it bypasses the pool and
   the pool keeps what it already holds.  Automatic = the pool's own byte
   ceiling, i.e. "no single value may fill the pool by itself". *)
$multiquadraticStripPoolOversizeBytes = <|
  "Core" -> Automatic, "GaugeDenominator" -> Automatic,
  "OneForm" -> Automatic|>;

multiquadraticStripInternValueBytes[value_] := N[ByteCount[value]];

(* below this many uncached one-forms a shard cannot pay for its own
   serialization and kernel round trip *)
$multiquadraticStripCompileShardMinimum = 8;

(* Both pools are flat Associations keyed by the actual held data and by
   {pool,
   counter}: a one-level Part assignment on a symbol holding an
   Association is the only update form with a guaranteed constant-time
   semantics, and the compile does thousands of these per call. *)
$multiquadraticStripInternCounterNames = {"Hits", "Misses",
  "Entries", "Resets", "Rejected", "Bytes", "Oversize"};

multiquadraticStripInternReset[pool_String] := (
  $multiquadraticStripInternPools = KeySelect[$multiquadraticStripInternPools,
    First[#1] =!= pool &];
  Scan[($multiquadraticStripInternCounters[[Key[{pool, #1}]]] = 0) &,
    $multiquadraticStripInternCounterNames];);

multiquadraticStripInternStatistics[] := Module[{pools},
  pools = DeleteDuplicates[First /@ Keys[$multiquadraticStripInternCounters]];
  Association[Table[pool -> Association[Table[
      name -> Lookup[$multiquadraticStripInternCounters, Key[{pool, name}], 0],
      {name, $multiquadraticStripInternCounterNames}]],
    {pool, pools}]]
];

multiquadraticStripCompileCacheClear[] := (
  $multiquadraticStripInternPools = <||>;
  $multiquadraticStripInternCounters = <||>;
  <|"Status" -> "MultiquadraticStripCompileCachesCleared"|>);

(* Present without computing: the shard planner needs to know which
   one-forms the pool already holds before it decides what to farm. *)
multiquadraticStripInternProbe[pool_String, key_] :=
  Lookup[$multiquadraticStripInternPools,
    Key[{pool, key}], Missing["NotInterned"]];

(* A NEGATIVE result is never cached (Codex P1, 2026-08-25).  The pools
   used to store whatever compute[] returned, $Failed included, and the
   early-core construction in prepare made that reachable on the public
   path: an early core that failed to build stored $Failed under the core
   key, prepare fell back to its own decomposition and succeeded, and the
   compiler then HIT the cached $Failed and returned
   ExactChannelDecompositionFailed on a block that was perfectly
   solvable.  A failed build is now recomputed rather than remembered --
   the cost of a repeated failure, against a poisoned cache that fails a
   whole solve.

   Per-pool validity is a predicate, not a bare $Failed test: a Core
   record whose five members are not all present is malformed even
   though it contains no $Failed. *)
multiquadraticStripInternValidQ["Core", value_] :=
  AssociationQ[value] && FreeQ[value, $Failed] &&
    AllTrue[{"E", "C", "BBar", "RootSquares", "RootLogDerivatives"},
      AssociationQ[Lookup[value, #1, $Failed]] &];
multiquadraticStripInternValidQ["GaugeDenominator", value_] :=
  AssociationQ[value] && FreeQ[value, $Failed] &&
    AllTrue[{"GaugeDenominator", "GaugeLogDerivatives"},
      AssociationQ[Lookup[value, #1, $Failed]] &];
(* the OneForm pool holds compiled entries only.  A typed REFUSAL (an
   Association carrying "Status") is a negative result and is never
   interned -- the same rule the Core pool's $Failed refusal follows. *)
multiquadraticStripInternValidQ["OneForm", value_] :=
  AssociationQ[value] && ! KeyExistsQ[value, "Status"] &&
    FreeQ[value, $Failed] &&
    AllTrue[{"Channels", "Compiled", "Path"}, KeyExistsQ[value, #1] &];
multiquadraticStripInternValidQ[_String, value_] :=
  value =!= $Failed && FreeQ[value, $Failed];

multiquadraticStripIntern[pool_String, key_, compute_] := Module[
  {entryKey, hit, value, limit, byteLimit, oversizeLimit, bytes,
   poolBytes, hits, misses, resets, oversize, counter},
  counter[name_String] :=
    Lookup[$multiquadraticStripInternCounters, Key[{pool, name}], 0];
  entryKey = Key[{pool, key}];
  hit = Lookup[$multiquadraticStripInternPools, entryKey,
    Missing["NotInterned"]];
  If[! MissingQ[hit],
    $multiquadraticStripInternCounters[[Key[{pool, "Hits"}]]] =
      counter["Hits"] + 1;
    Return[hit]];
  value = compute[];
  (* refused BEFORE any counter or bucket is touched: a rejected value
     leaves the pool exactly as it found it *)
  If[! multiquadraticStripInternValidQ[pool, value],
    $multiquadraticStripInternCounters[[Key[{pool, "Rejected"}]]] =
      counter["Rejected"] + 1;
    Return[value]];
  limit = Lookup[$multiquadraticStripPoolEntryLimit, pool, Infinity];
  byteLimit = Lookup[$multiquadraticStripPoolByteLimit, pool, Infinity];
  oversizeLimit = Replace[
    Lookup[$multiquadraticStripPoolOversizeBytes, pool, Automatic],
    Automatic :> byteLimit];
  (* the measurement is taken ONCE, on a miss, on the value that is about
     to be admitted -- never on a hit, and never on the pool as a whole *)
  bytes = multiquadraticStripInternValueBytes[value];
  (* OVERSIZE BYPASS.  A value that alone exceeds the pool's allowance is
     returned uncached: it is one recomputation against flushing every
     entry the pool holds for something the pool cannot hold. *)
  If[NumericQ[oversizeLimit] && bytes > oversizeLimit,
    $multiquadraticStripInternCounters[[Key[{pool, "Misses"}]]] =
      counter["Misses"] + 1;
    $multiquadraticStripInternCounters[[Key[{pool, "Oversize"}]]] =
      counter["Oversize"] + 1;
    Return[value]];
  poolBytes = counter["Bytes"];
  If[counter["Entries"] >= limit ||
      (NumericQ[byteLimit] && poolBytes + bytes > byteLimit),
    (* bounded on BOTH axes: a pool at either cap starts again rather
       than growing without bound in a long-lived pool kernel *)
    hits = counter["Hits"]; misses = counter["Misses"];
    resets = counter["Resets"]; oversize = counter["Oversize"];
    multiquadraticStripInternReset[pool];
    $multiquadraticStripInternCounters[[Key[{pool, "Hits"}]]] = hits;
    $multiquadraticStripInternCounters[[Key[{pool, "Misses"}]]] = misses;
    $multiquadraticStripInternCounters[[Key[{pool, "Oversize"}]]] = oversize;
    $multiquadraticStripInternCounters[[Key[{pool, "Resets"}]]] = resets + 1;
    poolBytes = 0];
  $multiquadraticStripInternCounters[[Key[{pool, "Misses"}]]] =
    counter["Misses"] + 1;
  $multiquadraticStripInternPools[[entryKey]] = value;
  $multiquadraticStripInternCounters[[Key[{pool, "Entries"}]]] =
    counter["Entries"] + 1;
  $multiquadraticStripInternCounters[[Key[{pool, "Bytes"}]]] =
    poolBytes + bytes;
  value
];

(* Codex item 4.  multiquadraticFieldDecompose ends in Together /@, so
   every channel it returns IS a canonical rational pair and
   Numerator/Denominator are exactly the pair CoefficientRules needs.
   The split is accepted only when both halves are genuine polynomials
   in {x, y, eps}; anything else falls back to the conservative Together
   path, so a caller that hands in a non-canonical expression cannot be
   given a wrong pair. *)
multiquadraticStripCompileRationalFromPair[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {compiledNumerator, compiledDenominator},
  If[! FreeQ[expression, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  compiledNumerator = multiquadraticStripCompilePolynomial[
    Numerator[expression], variables, epsilon];
  If[compiledNumerator === $Failed, Return[$Failed]];
  compiledDenominator = multiquadraticStripCompilePolynomial[
    Denominator[expression], variables, epsilon];
  If[compiledDenominator === $Failed ||
      compiledDenominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalExactV1",
    "Numerator" -> compiledNumerator, "Denominator" -> compiledDenominator|>
];

multiquadraticStripCompileRationalCanonical[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[{fast},
  fast = multiquadraticStripCompileRationalFromPair[expression, variables,
    epsilon];
  If[fast =!= $Failed, fast,
    multiquadraticStripCompileRational[expression, variables, epsilon]]
];

(* The ROOTS are part of the key, not context.  The same scalar is
   decomposed at two different ranks inside ONE compile: the root
   squares and the root/gauge log derivatives are decomposed over the
   EMPTY root set (they are rational by construction), while E, C, BBar
   and the one-forms are decomposed over the declared roots.  Keying on
   the expression alone let 1/x -- the log derivative of the root square
   delta = x, and equally the x-component of dlog x -- return a rank-0
   channel vector of width 1 where the grade ABI demands width 2^r.
   Found 2026-08-25 by t_multiquadratic_strip_solve. *)
multiquadraticStripDecomposeScalarInterned[expression_, roots_List] :=
  multiquadraticStripIntern["Scalar", {roots, expression},
    Function[multiquadraticStripDecomposeScalar[expression, roots]]];

multiquadraticStripCompileRationalInterned[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  multiquadraticStripIntern["Rational", expression,
    Function[multiquadraticStripCompileRationalCanonical[expression,
      variables, epsilon]]];

(* prepare's INDEPENDENT forcing decomposition -- the fallback taken when
   the compile core cannot be built or is switched off.  It differs from
   the HEAD expression Map[multiquadraticStripDecomposeScalar[...], ...,
   {3}] in two ways that cannot change its value: the interned decomposer
   (which memoizes multiquadraticStripDecomposeScalar and returns exactly
   its result, so the repeated zero entries of a sparse forcing are
   decomposed once) and one rate-limited progress line per interval. *)
multiquadraticStripDecomposeForcing[bbar_, roots_List] := Module[
  {stage = "prepare: forcing channel decomposition", total, done = 0,
   started = AbsoluteTime[]},
  total = Quiet[Check[Times @@ Take[Dimensions[bbar], UpTo[3]], 0]];
  Map[Function[entry,
      done++;
      multiquadraticStripDeadlineCheckpoint["ForcingChannels",
        <|"Entry" -> done, "Of" -> total,
          "SubstageSeconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripStageProgress[stage,
        <|"entry" -> done, "of" -> total,
          "seconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripDecomposeScalarInterned[entry, roots]],
    bbar, {3}]
];

multiquadraticStripCompileTensorInterned[tensor_, scalarLevel_Integer,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  multiquadraticStripCompileTensorInterned[tensor, scalarLevel, roots,
    variables, epsilon, None];

(* "stage" is a telemetry label only.  With a label the decomposition
   emits ONE rate-limited progress line per interval naming the entry it
   has reached; without one (the root squares and log derivatives, which
   are a handful of scalars) it is silent.  Nothing else differs, so the
   returned record is byte-identical either way. *)
multiquadraticStripCompileTensorInterned[tensor_, scalarLevel_Integer,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    stage_] := Module[
  {channels, compiled, total, done = 0, started = AbsoluteTime[], decompose},
  If[StringQ[stage],
    total = Times @@ Take[Dimensions[tensor], UpTo[scalarLevel]];
    multiquadraticStripStageStart[stage,
      <|"entries" -> total, "rank" -> Length[roots],
        "grades" -> 2^Length[roots]|>];
    decompose[entry_] := (
      done++;
      multiquadraticStripDeadlineCheckpoint[stage,
        <|"Entry" -> done, "Of" -> total,
          "SubstageSeconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripStageProgress[stage,
        <|"entry" -> done, "of" -> total,
          "seconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticStripDecomposeScalarInterned[entry, roots]),
    decompose[entry_] := (
      multiquadraticStripDeadlineCheckpoint["CompileTensor", <||>];
      multiquadraticStripDecomposeScalarInterned[entry, roots])];
  channels = Map[decompose, tensor, {scalarLevel}];
  If[! FreeQ[channels, $Failed],
    If[StringQ[stage],
      multiquadraticStripStageDone[stage,
        <|"seconds" -> N[AbsoluteTime[] - started], "status" -> "Failed"|>]];
    Return[$Failed]];
  compiled = Map[
    multiquadraticStripCompileRationalInterned[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[StringQ[stage],
    multiquadraticStripStageDone[stage,
      <|"seconds" -> N[AbsoluteTime[] - started],
        "status" -> If[FreeQ[compiled, $Failed], "OK", "Failed"]|>]];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

(* Codex item 3, the inverse.  A element with grade support {0, m} has
   the two-term inverse (A - B r_m)/(A^2 - B^2 delta_m) -- its NORM, not
   a 2^r x 2^r rational solve; a pure single-grade element inverts in
   one division.  Any other support falls through to the general field
   inversion ABI.  Every branch is accepted only after the exact product
   check against the grade identity, which is the same acceptance
   multiquadraticFieldInverse makes. *)
multiquadraticStripCompactInverse[a_List, deltas_List] := Module[
  {dimension = Length[a], nonzero, mask, factor, norm, inverse, check,
   general = False},
  If[dimension =!= 2^Length[deltas], Return[$Failed]];
  (* the channels arrive from the field ABI, which ends in Together, so a
     zero channel IS the integer 0: re-Togethering every channel of a
     full-support letter merely to test it for zero was measured as the
     dominant cost of this routine on the rank-3 fixture (2026-08-25) *)
  nonzero = Flatten[Position[SameQ[#1, 0] & /@ a, False, {1},
    Heads -> False]];
  inverse = Which[
    nonzero === {}, $Failed,
    nonzero === {1},
      ReplacePart[ConstantArray[0, dimension], 1 -> Together[1/a[[1]]]],
    Length[nonzero] === 1,
      mask = First[nonzero] - 1;
      factor = Together[multiquadraticMaskFactor[mask, deltas]];
      If[TrueQ[factor === 0], $Failed,
        ReplacePart[ConstantArray[0, dimension],
          (mask + 1) -> Together[1/(a[[mask + 1]] factor)]]],
    Length[nonzero] === 2 && First[nonzero] === 1,
      mask = Last[nonzero] - 1;
      factor = Together[multiquadraticMaskFactor[mask, deltas]];
      norm = Together[a[[1]]^2 - a[[mask + 1]]^2 factor];
      If[TrueQ[norm === 0], $Failed,
        ReplacePart[ConstantArray[0, dimension],
          {1 -> Together[a[[1]]/norm],
           (mask + 1) -> Together[-a[[mask + 1]]/norm]}]],
    True, general = True; multiquadraticFieldInverse[a, deltas]];
  If[inverse === $Failed || ! ListQ[inverse] || Length[inverse] =!= dimension,
    Return[$Failed]];
  (* multiquadraticFieldInverse already made this exact product check;
     repeating it costs a second 2^r x 2^r symbolic multiply *)
  If[TrueQ[general], Return[inverse]];
  check = multiquadraticMultiply[a, inverse, deltas];
  If[! ListQ[check] ||
      ! multiquadraticStripZeroQ[check - UnitVector[dimension, 1]],
    $Failed, inverse]
];

(* Codex item 3, the one-form.  dlog L = (dL) L^-1 entirely inside the
   grade algebra: decompose the LETTER (the small object), check that it
   recomposes exactly, invert by the norm, differentiate in the grade
   basis (multiquadraticDerivative carries the dlog delta term, so the
   derivative never leaves its grade) and multiply.  The expanded
   D[L]/L tree is never formed and never decomposed.

   Exactness: the recompose check certifies the channels of L; the
   product check inside multiquadraticStripCompactInverse certifies the
   inverse; derivative and product are exact identities of the ABI.  So
   the returned channels are the exact channels of dlog L without any
   check on the materialized tree. *)
multiquadraticStripLetterChannelData[letter_, roots_List,
    variables : {_Symbol, _Symbol}] := Module[
  {rank = Length[roots], deltas, channels, composed, inverse, result},
  deltas = If[rank === 0, {},
    Together /@ (squareRootRecordRadicand /@ roots)];
  If[! FreeQ[deltas, $Failed], Return[$Failed]];
  channels = Quiet[multiquadraticFieldDecompose[letter, roots]];
  If[! ListQ[channels] || Length[channels] =!= 2^rank ||
      ! FreeQ[channels, $Failed], Return[$Failed]];
  composed = multiquadraticFieldCompose[channels, roots];
  If[composed === $Failed ||
      ! TrueQ[Together[composed - letter] === 0], Return[$Failed]];
  inverse = multiquadraticStripCompactInverse[channels, deltas];
  If[inverse === $Failed, Return[$Failed]];
  result = Table[
    Module[{derivative = multiquadraticDerivative[channels, deltas,
        variables[[mu]]]},
      If[! ListQ[derivative] || ! FreeQ[derivative, $Failed], $Failed,
        multiquadraticMultiply[derivative, inverse, deltas]]],
    {mu, 2}];
  If[! MatchQ[result, {_List, _List}] || ! FreeQ[result, $Failed], $Failed,
    <|"LetterChannels" -> channels, "DLogChannels" -> result|>]
];
multiquadraticStripLetterChannelData[___] := $Failed;

multiquadraticStripLetterChannelPair[letter_, roots_List,
    variables : {_Symbol, _Symbol}] := Module[{data},
  data = multiquadraticStripLetterChannelData[letter, roots, variables];
  If[AssociationQ[data], Lookup[data, "DLogChannels", $Failed], $Failed]
];

(* The compact path may reuse retained channels only for a pair already
   known to satisfy omega=dlog(L).  Package-constructed pairs record that
   fact by construction; caller-supplied pairs reach this point only after
   the explicit symbolic dlog equation has been verified.  The retained
   channels are still recomposed and compared with the requested one-form
   before use. *)
multiquadraticStripCompactDLogAdmission[letterRecord_, form_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, mode_] := Module[
  {letter, potential, derived},
  If[! AssociationQ[letterRecord],
    Return[<|"Admitted" -> False, "Reason" -> "NoLetterRecord"|>]];
  letter = Lookup[letterRecord, "Letter", Missing["NoLetter"]];
  If[MissingQ[letter],
    Return[<|"Admitted" -> False, "Reason" -> "NotADLog"|>]];
  If[! SameQ[Lookup[letterRecord, "OneForm", Missing["NoOneForm"]], form],
    Return[<|"Admitted" -> False,
      "Reason" -> "OneFormIsNotTheRecordOneForm"|>]];
  potential = Lookup[letterRecord, "Potential", <||>];
  If[AssociationQ[potential] &&
      Lookup[potential, "Status", None] === "PotentialVerified" &&
      TrueQ[Lookup[potential, "Verified", False]] &&
      SameQ[Lookup[potential, "Letter", Missing[]], letter] &&
      SameQ[Lookup[potential, "OneForm", Missing[]], form],
    Return[<|"Admitted" -> True, "Method" ->
        Lookup[potential, "VerificationMethod", "ExactDLogCheck"],
      "Letter" -> letter|>]];
  If[mode === "Certified",
    Return[<|"Admitted" -> False,
      "Reason" -> "VerifiedDLogPotentialMissing"|>]];
  derived = multiquadraticStripLetterOneForm[letter, variables];
  If[! MatchQ[derived, {_, _}],
    Return[<|"Admitted" -> False, "Reason" -> "LetterHasNoDLog"|>]];
  If[! (TrueQ[Together[derived[[1]] - form[[1]]] === 0] &&
        TrueQ[Together[derived[[2]] - form[[2]]] === 0]),
    Return[<|"Admitted" -> False,
      "Reason" -> "OneFormIsNotTheLetterDLog"|>]];
  <|"Admitted" -> True, "Method" -> "ExactDLogCheck", "Letter" -> letter|>
];

(* the grade masks one channel VECTOR occupies.  The channels arrive from
   the field ABI, which ends in Together, so a zero channel is the
   integer 0 and no normalization is needed here. *)
multiquadraticStripChannelVectorGradeSupport[vector_List] :=
  Flatten[Position[vector, entry_ /; ! TrueQ[entry === 0], {1},
    Heads -> False]] - 1;

(* the union over a list of channel vectors (a one-form is two of them) *)
multiquadraticStripChannelGradeSupport[vectors : {__List}] :=
  Sort[DeleteDuplicates[Flatten[
    multiquadraticStripChannelVectorGradeSupport /@ vectors]]];
multiquadraticStripChannelGradeSupport[vector_List] :=
  Sort[multiquadraticStripChannelVectorGradeSupport[vector]];

(* One compiled one-form. *)
multiquadraticStripCompileOneFormEntry[form : {_, _}, letterRecord_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_] := multiquadraticStripCompileOneFormEntry[form, letterRecord,
  roots, variables, epsilon, compactQ, Automatic, Automatic];

multiquadraticStripCompileOneFormEntry[form : {_, _}, letterRecord_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, gradeSupport_, admissionMode_] := Module[
  {channels = $Failed, admission = <|"Admitted" -> False,
     "Reason" -> "CompactRouteDisabled"|>, path, compiled, support,
   admissible, retainedChannels, recomposed},
  If[TrueQ[compactQ],
    admission = multiquadraticStripCompactDLogAdmission[letterRecord, form,
      variables, epsilon, admissionMode];
    If[TrueQ[admission["Admitted"]],
      retainedChannels = Lookup[letterRecord, "DLogChannels", $Failed];
      If[MatchQ[retainedChannels, {_List, _List}] &&
          Dimensions[retainedChannels] === {2, 2^Length[roots]} &&
          FreeQ[retainedChannels, $Failed],
        recomposed = Quiet[
          multiquadraticFieldCompose[#1, roots] & /@ retainedChannels];
        (* Admission has already bound the raw letter and both channel
           payloads (V2), or checked dlog(letter) exactly (V1/fallback).
           Recompose only the channels that will actually be installed and
           demand exact identity with the requested one-form. *)
        If[SameQ[recomposed, form],
          channels = retainedChannels]];
      If[! MatchQ[channels, {_List, _List}],
        channels = multiquadraticStripLetterChannelPair[
          admission["Letter"], roots, variables]];
      If[! MatchQ[channels, {_List, _List}],
        admission = <|"Admitted" -> False,
          "Reason" -> "LetterChannelsUnavailable"|>]]];
  If[MatchQ[channels, {_List, _List}],
    (* THE GRADE GATE (2026-08-25).  "GradeSupport" declares the grade
       masks the compiled system carries.  A letter whose dlog occupies a
       mask outside that set cannot be represented by the compiled
       residue columns, and admitting it would send the modular solve
       looking for an inconsistency whose cause is this letter.  It is a
       TYPED refusal of the whole compile, not a fallback: the caller
       declared a grade set and this letter leaves it. *)
    admissible = Replace[gradeSupport,
      Automatic :> Range[0, 2^Length[roots] - 1]];
    support = multiquadraticStripChannelGradeSupport[channels];
    If[! VectorQ[admissible, IntegerQ] || ! SubsetQ[admissible, support],
      Return[<|"Status" -> "CompactLetterGradeSupportExceeded",
        "GradeSupport" -> support,
        "AdmissibleGradeSupport" -> admissible,
        "Path" -> "CompactLetterChannels"|>]]];
  path = If[MatchQ[channels, {_List, _List}], "CompactLetterChannels",
    channels = multiquadraticStripDecomposeScalarInterned[#1, roots] & /@ form;
    "DecomposedForm"];
  If[! ListQ[channels] || ! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[
    multiquadraticStripCompileRationalInterned[#1, variables, epsilon] &,
    channels, {2}];
  If[! FreeQ[compiled, $Failed], Return[$Failed]];
  <|"Channels" -> channels, "Compiled" -> compiled, "Path" -> path,
    "CompactAdmission" -> If[path === "CompactLetterChannels",
      admission["Method"], admission["Reason"]]|>
];

(* Helper side of Codex item 5.  The shard receives an IMMUTABLE payload
   file written in formal System` symbols, so nothing it reads depends
   on the helper kernel's $Context (the CANONICA rebinding trap), and it
   acquires no nested kernel of its own. *)
multiquadraticStripCompileShardTask[dataFile_String, indices_List] := Module[
  {payload, forms, records, roots, entries},
  payload = Quiet[CheckAbort[Get[dataFile], $Failed]];
  If[! AssociationQ[payload], Return[$Failed]];
  forms = Lookup[payload, "OneForms", $Failed];
  records = Lookup[payload, "LetterRecords", None];
  roots = Lookup[payload, "Roots", $Failed];
  If[! ListQ[forms] || ! ListQ[roots] ||
      ! VectorQ[indices, IntegerQ], Return[$Failed]];
  entries = Table[
    multiquadraticStripCompileOneFormEntry[forms[[index]],
      If[MatchQ[records, {___Association}] && Length[records] === Length[forms],
        records[[index]], None],
      roots, {\[FormalX], \[FormalY]}, \[FormalE],
      TrueQ[Lookup[payload, "Compact", False]],
      Lookup[payload, "GradeSupport", Automatic],
      Lookup[payload, "AdmissionMode", Automatic]],
    {index, indices}];
  If[! FreeQ[entries, $Failed], $Failed,
    <|"Indices" -> indices, "Entries" -> entries|>]
];

(* The one-form pool key distinguishes compact letter channels from direct
   one-form decomposition.  The pre-2026-08-25 key was {prefix, form}: the same
   form compiled through the compact letter-channel route and through
   the decomposed-form route landed on ONE entry, so a route flip inside
   a session could serve the other route's channels, and two records
   naming DIFFERENT letters for the same stored one-form were
   indistinguishable.  The key now carries the requested ROUTE and the
   actual letter data, so an entry can only ever be served to the
   configuration that produced it.  The stored entry additionally
   reports the route it actually took ("Path"), which the compact route
   may still downgrade after an admission refusal. *)
multiquadraticStripLetterData[record_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[{rules},
  If[! AssociationQ[record], Return["NoLetterRecord"]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  {Lookup[record, "Kind", None],
    Lookup[record, "Letter", Missing["NoLetter"]] /. rules,
    Lookup[record, "OneForm", Missing["NoOneForm"]] /. rules}
];

multiquadraticStripCompileOneFormKey[prefix_, form_, record_, compactQ_,
    gradeSupport_, admissionMode_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := {prefix, form,
  If[TrueQ[compactQ], "CompactLetterChannels", "DecomposedForm"],
  multiquadraticStripLetterData[record, variables, epsilon],
  gradeSupport, admissionMode};

(* The ansatz half of the split: one interned entry per one-form, keyed
   on the chart symbols, the canonical roots, the form itself, the route
   and the letter provenance.  An exact-prefix alphabet extension
   therefore hits the pool on every old letter and compiles only the
   suffix. *)
multiquadraticStripCompileOneForms[oneForms_List, letterRecords_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, shards_] :=
  multiquadraticStripCompileOneForms[oneForms, letterRecords, roots,
    variables, epsilon, compactQ, shards, Automatic, Automatic];

multiquadraticStripCompileOneForms[oneForms_List, letterRecords_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, shards_, gradeSupport_, admissionMode_] := Module[
  {records, aligned, prefix, keys, pending, entries, planned, groups,
   payload, dataFile, results, shardCount, rules, inverseRules, canonical,
   refused},
  aligned = MatchQ[letterRecords, {___Association}] &&
    Length[letterRecords] === Length[oneForms];
  records = If[aligned, letterRecords,
    ConstantArray[None, Length[oneForms]]];
  prefix = {variables, epsilon,
    squareRootRecordExpression /@ roots,
    squareRootRecordRadicand /@ roots};
  keys = Table[
    multiquadraticStripCompileOneFormKey[prefix, oneForms[[index]],
      records[[index]], compactQ, gradeSupport, admissionMode, variables,
      epsilon],
    {index, Length[oneForms]}];
  multiquadraticStripStageStart["compile: one-forms",
    <|"oneForms" -> Length[oneForms], "rank" -> Length[roots],
      "compact" -> TrueQ[compactQ], "shards" -> shards,
      "cached" -> Count[keys,
        key_ /; ! MissingQ[multiquadraticStripInternProbe["OneForm", key]]]|>];
  (* shard plan: only the one-forms the pool does NOT already hold, and
     only when a live broker and enough uncached work justify it *)
  shardCount = If[IntegerQ[shards] && shards >= 2 && shards <= 8, shards, 0];
  If[shardCount >= 2 && TrueQ[Quiet[taskBrokerActiveQ[]]] &&
      Quiet[Check[taskBrokerFreeKernels[], 0]] >= 1,
    pending = Select[Range[Length[oneForms]],
      MissingQ[multiquadraticStripInternProbe["OneForm", keys[[#1]]]] &];
    pending = DeleteDuplicatesBy[pending, keys[[#1]] &];
    If[Length[pending] >= $multiquadraticStripCompileShardMinimum,
      rules = multiquadraticStripCanonicalRules[variables, epsilon];
      inverseRules = Reverse /@ rules;
      payload = <|"OneForms" -> (oneForms /. rules),
        "LetterRecords" -> If[aligned, letterRecords /. rules, None],
        "Roots" -> (roots /. rules), "Compact" -> TrueQ[compactQ],
        "GradeSupport" -> gradeSupport, "AdmissionMode" -> admissionMode|>;
      dataFile = taskBrokerDataFile[
        "mqcompile_" <> CreateUUID[],
        payload];
      If[StringQ[dataFile],
        groups = Partition[pending, UpTo[Ceiling[Length[pending]/shardCount]]];
        results = taskBrokerRun[
          Table["FeynFacet`Private`multiquadraticStripCompileShardTask[\"" <>
            dataFile <> "\", " <> ToString[group, InputForm] <> "]",
            {group, groups}], "Label" -> "mqcompile", "Timeout" -> 7200];
        Do[
          If[AssociationQ[results[[k]]] &&
              Lookup[results[[k]], "Indices", None] === groups[[k]],
            MapThread[Function[{index, entry},
              canonical = If[AssociationQ[entry],
                Append[entry, "Channels" ->
                  (Lookup[entry, "Channels", $Failed] /. inverseRules)],
                entry];
              If[AssociationQ[canonical],
                multiquadraticStripIntern["OneForm", keys[[index]],
                  Function[canonical]]]],
              {groups[[k]], Lookup[results[[k]], "Entries", {}]}]],
          {k, Length[groups]}]]]];
  planned = Table[
    With[{form = oneForms[[index]], record = records[[index]],
        key = keys[[index]]},
      (* BOUNDARY: between letters.  The compile of one letter is a
         decomposition and an inversion in the grade algebra and is not
         interruptible inside; the letter is the finest boundary that
         exists without changing what is computed. *)
      multiquadraticStripDeadlineCheckpoint["Compilation:OneForms",
        <|"Letter" -> index, "Of" -> Length[oneForms]|>];
      multiquadraticStripStageProgress["compile: one-forms",
        <|"letter" -> index, "of" -> Length[oneForms]|>];
      multiquadraticStripIntern["OneForm", key,
        Function[multiquadraticStripCompileOneFormEntry[form, record, roots,
          variables, epsilon, compactQ, gradeSupport, admissionMode]]]],
    {index, Length[oneForms]}];
  (* a TYPED refusal from the grade gate is propagated as itself, not
     collapsed into $Failed: the caller must be able to name the letter *)
  refused = SelectFirst[planned,
    AssociationQ[#1] && KeyExistsQ[#1, "Status"] &, None];
  If[refused =!= None,
    Return[Join[refused, <|"LetterIndex" -> First[Flatten[Position[planned,
      refused, {1}, 1, Heads -> False]], Missing["NotFound"]]|>]]];
  If[! FreeQ[planned, $Failed] || ! MatchQ[planned, {___Association}],
    Return[$Failed]];
  entries = planned;
  <|"Channels" -> Lookup[entries, "Channels", {}],
    "Compiled" -> Lookup[entries, "Compiled", {}],
    "Paths" -> Lookup[entries, "Path", {}],
    "CompactAdmissions" -> Lookup[entries, "CompactAdmission",
      Missing["NotRecorded"]]|>
];

(* The core cache key contains exactly the canonical differential equation,
   ordered generator expressions and radicands, and matrix dimensions.  The
   ansatz support, one-forms and denominator are intentionally absent.  The
   key parts let preparation query the core before its full defining-data
   record exists.  Both callers must land on the same pool entry
   or the core is built twice, which is the whole defect that split
   closes.

   ---- ROOT EXPRESSIONS (2026-08-25, Codex 14:30 P1) -----------------

   Until today the key carried only the root SQUARES.  The core's
   algebra does not depend on the squares alone: every channel of E, C
   and BBar is a coefficient in the basis {1, r_1, r_2, r_1 r_2, ...},
   and replacing r_a by -r_a is a different basis of the same field with
   different coefficients.  Two preparations whose ONLY difference was a
   root sign therefore shared a core key and the second silently
   received the first's channels -- a wrong-basis collision that no
   later exact check could see, because every channel is individually
   well formed.  The ordered canonical root EXPRESSIONS are now keyed as
   well, so a sign mutant misses.  (The squares stay in the key: they are
   what the grade multiplication table is built from, and a root whose
   canonical text is equal while its square differs is not reachable but
   is also not worth relying on.) *)
multiquadraticStripCompileCoreKeyFromParts[equationData_,
    rootCanonicalSquares_, rootCanonicalExpressions_, dimensions_] :=
  {equationData, rootCanonicalSquares, rootCanonicalExpressions, dimensions};

multiquadraticStripCompileCoreKey[preparation_Association,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {payload = Lookup[preparation, "DefiningData", $Failed]},
  If[! AssociationQ[payload], Return[$Failed]];
  If[AnyTrue[{"EquationCanonical", "RootCanonicalSquares",
      "RootCanonicalExpressions", "Dimensions"},
      ! KeyExistsQ[payload, #1] &], Return[$Failed]];
  multiquadraticStripCompileCoreKeyFromParts[
    payload["EquationCanonical"],
    payload["RootCanonicalSquares"], payload["RootCanonicalExpressions"],
    payload["Dimensions"]]
];

(* Takes the STRIP, not a preparation: prepare consumes this record too
   and has no preparation object yet when it does (2026-08-25).  The
   preparation-shaped call site in multiquadraticStripCompile passes
   preparation["Record"]["Strip"], so nothing it compiles changed. *)
multiquadraticStripCompileCoreRecord[strip_, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, reusedChannels_,
    coreKey_, useCacheQ_] := Module[{build},
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  build[] := Module[
    {e, c, bbar, eData, cData, bData, rootSquares, rootSquareData,
     rootLogData},
    {e, c, bbar} = strip;
    eData = multiquadraticStripCompileTensorInterned[e, 3, roots, variables,
      epsilon, "compile core: E"];
    cData = multiquadraticStripCompileTensorInterned[c, 3, roots, variables,
      epsilon, "compile core: C"];
    bData = If[ArrayQ[reusedChannels, 4] &&
        Dimensions[reusedChannels] === Append[Dimensions[bbar],
          2^Length[roots]] && FreeQ[reusedChannels, $Failed],
      Module[{compiled = Map[
          multiquadraticStripCompileRationalInterned[#1, variables, epsilon] &,
          reusedChannels, {4}]},
        If[! FreeQ[compiled, $Failed], $Failed,
          <|"Channels" -> reusedChannels, "Compiled" -> compiled|>]],
      multiquadraticStripCompileTensorInterned[bbar, 3, roots, variables,
        epsilon, "compile core: BBar"]];
    rootSquares = squareRootRecordRadicand /@ roots;
    rootSquareData = multiquadraticStripCompileTensorInterned[rootSquares, 1,
      {}, variables, epsilon];
    rootLogData = multiquadraticStripCompileTensorInterned[
      Table[D[rootSquares[[a]], variables[[mu]]]/rootSquares[[a]],
        {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
    If[MemberQ[{eData, cData, bData, rootSquareData, rootLogData}, $Failed],
      $Failed,
      <|"E" -> eData, "C" -> cData, "BBar" -> bData,
        "RootSquares" -> rootSquareData, "RootLogDerivatives" -> rootLogData|>]];
  If[TrueQ[useCacheQ] && coreKey =!= $Failed,
    multiquadraticStripIntern["Core", coreKey, Function[build[]]],
    build[]]
];

(* The gauge denominator is neither core nor ansatz: an alphabet change
   moves it (the norms of the algebraic letters enter it), a support
   change does not.  It is two rational scalars and their two log
   derivatives, so it gets its own small keyed pool. *)
multiquadraticStripCompileDenominatorRecord[denominator_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, useCacheQ_] := Module[
  {build},
  build[] := Module[{denominatorData, denominatorLogData},
    denominatorData = multiquadraticStripCompileTensorInterned[{denominator},
      1, {}, variables, epsilon];
    denominatorLogData = multiquadraticStripCompileTensorInterned[
      {D[denominator, variables[[1]]]/denominator,
       D[denominator, variables[[2]]]/denominator}, 1, {}, variables, epsilon];
    If[MemberQ[{denominatorData, denominatorLogData}, $Failed], $Failed,
      <|"GaugeDenominator" -> denominatorData,
        "GaugeLogDerivatives" -> denominatorLogData|>]];
  If[TrueQ[useCacheQ],
    multiquadraticStripIntern["GaugeDenominator",
      {variables, epsilon, denominator},
      Function[build[]]],
    build[]]
];

(* The pre-2026-08-25 compiler, kept callable.  "LegacyCompiler" -> True
   routes every part through multiquadraticStripCompileTensor exactly as
   before: no interning, no core cache, no compact letter channels, and
   the second Together that fed CoefficientRules.  It is the reference
   the equivalence test holds the new architecture to (compiled-assembly
   modular images at (prime, eps, point) triples), and a bisect handle;
   it is not a production route. *)
multiquadraticStripCompileLegacyCore[preparation_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, reusedChannels_] := Module[
  {strip = Lookup[preparation, "Record", <||>]["Strip"], e, c, bbar, eData,
   cData, bData, rootSquares, rootSquareData, rootLogData},
  If[! MatchQ[strip, {_List, _List, _List}], Return[$Failed]];
  {e, c, bbar} = strip;
  eData = multiquadraticStripCompileTensor[e, 3, roots, variables, epsilon];
  cData = multiquadraticStripCompileTensor[c, 3, roots, variables, epsilon];
  bData = If[ArrayQ[reusedChannels, 4] &&
      Dimensions[reusedChannels] === Append[Dimensions[bbar],
        2^Length[roots]] && FreeQ[reusedChannels, $Failed],
    Module[{compiled = Map[
        multiquadraticStripCompileRational[#1, variables, epsilon] &,
        reusedChannels, {4}]},
      If[! FreeQ[compiled, $Failed], $Failed,
        <|"Channels" -> reusedChannels, "Compiled" -> compiled|>]],
    multiquadraticStripCompileTensor[bbar, 3, roots, variables, epsilon]];
  rootSquares = squareRootRecordRadicand /@ roots;
  rootSquareData = multiquadraticStripCompileTensor[rootSquares, 1, {},
    variables, epsilon];
  rootLogData = multiquadraticStripCompileTensor[
    Table[D[rootSquares[[a]], variables[[mu]]]/rootSquares[[a]],
      {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
  If[MemberQ[{eData, cData, bData, rootSquareData, rootLogData}, $Failed],
    $Failed,
    <|"E" -> eData, "C" -> cData, "BBar" -> bData,
      "RootSquares" -> rootSquareData, "RootLogDerivatives" -> rootLogData|>]
];

multiquadraticStripCompileLegacyDenominator[denominator_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {denominatorData, denominatorLogData},
  denominatorData = multiquadraticStripCompileTensor[{denominator}, 1, {},
    variables, epsilon];
  denominatorLogData = multiquadraticStripCompileTensor[
    {D[denominator, variables[[1]]]/denominator,
     D[denominator, variables[[2]]]/denominator}, 1, {}, variables, epsilon];
  If[MemberQ[{denominatorData, denominatorLogData}, $Failed], $Failed,
    <|"GaugeDenominator" -> denominatorData,
      "GaugeLogDerivatives" -> denominatorLogData|>]
];

multiquadraticStripFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{"MultiquadraticRationalExactV1",
      "MultiquadraticRationalPrimeV1", "MultiquadraticRationalImageV1"},
    Lookup[expression, "Type", None]], "MultiquadraticRationalLeaf",
  AssociationQ[expression], Map[multiquadraticStripFormShape, expression],
  ListQ[expression], multiquadraticStripFormShape /@ expression,
  True, "Scalar"
];

(* "PreparationValidated" and "ForcingChannels" exist for ONE caller:
   solveEpsFormStripMultiquadratic, which has just built this preparation
   object itself in the same call.  Re-deriving the defining data and
   decomposing the forcing a second time then costs (measured on CF300
   (12,9)) 25 s and 807 s and can only reproduce what the preparation
   already carries.  Both default to the conservative behaviour, so a
   preparation that arrived from an artifact, a cache or another process
   is still validated and still decomposed here. *)
(* "PreparationValidated" and "ForcingChannels" exist for ONE caller:
   solveEpsFormStripMultiquadratic (see the note above).

   "CompileCore", "LetterChannels" and "CompileShards" are the 2026-08-25
   compile architecture.  All three default to Automatic and all three
   are then ON except sharding, which needs a live task broker AND an
   explicit shard count: naive parallelism duplicates work and peak
   memory, so it is last and opt-in.  "CompileCore" -> False and
   "LetterChannels" -> False restore the pre-2026-08-25 compiler exactly,
   which is what the equivalence test uses as its reference.

   ---- "CompileShards" IS A PRIVATE TEST CONTROL (decision 2026-08-25)

   It is NOT a production option and has no production caller.  It is
   absent from Options[solveEpsFormStripMultiquadratic] deliberately, so
   no public route can reach it, and the top-level option gate refuses
   it by name like any other unknown option.

   LEDGER NOTE.  What a production shard contract needs, and what does
   not exist yet: a strict result schema validated per shard (indices,
   entry count, per-entry shape) before anything is interned; a
   helper-leak guarantee (a helper that dies must not leave a claimed
   index uncompiled and unrecomputed); ABSOLUTE deadlines rather than
   the fixed 7200 s "Timeout" below; and a measured per-entry stage cost
   that shows sharding pays at all.  It has not been shown to pay on the
   one real shape measured -- see
   Results/UU_08_10_canonical/FamilyEpsFormsSolving/
   MultiquadraticMeasurementNarratives_2026-08-26.md, section 3.
   Production sharding waits for those measurements (Codex 14:30, shard
   row; agreed disposition).  Until then this option exists so the shard
   PATH stays exercised by its tests and does not rot, and the LEGACY
   compiler beside it is retained for the same reason and for no other:
   both are DIFFERENTIAL-TEST ORACLES, held to the current compiler by
   Tests/Multiquadratic/t_multiquadratic_prepare_core.wls, with no production caller. *)
Options[multiquadraticStripCompile] = {
  "PreparationValidated" -> False,
  "ForcingChannels" -> Automatic,
  "CompileCore" -> Automatic,
  "LetterChannels" -> Automatic,
  (* PRIVATE TEST CONTROL -- see the ledger note above.  Not a public
     option; do not add it to a production option set. *)
  "CompileShards" -> Automatic,
  "LegacyCompiler" -> False,
  (* the grade masks the compiled system carries.  Automatic = all 2^r
     of them (no restriction, the historical behaviour); a declared set
     makes the compact letter-channel route refuse typed any letter
     whose dlog occupies a mask outside it. *)
  "LetterGradeSupport" -> Automatic,
  (* how the compact route may prove form == dlog(Letter): Automatic =
     the package certificate if the record carries one, else the exact
     dlog check; "Certified" = certificate only; "Exact" = always
     recompute and compare. *)
  "CompactDLogAdmission" -> Automatic,
  (* absolute AbsoluteTime[] value; Infinity = unbounded, the default,
     so every existing caller is unchanged.  Read at the compile stage
     boundaries and, through the dynamic deadline, at every decomposed
     entry and every letter. *)
  "Deadline" -> Infinity,
  (* the persistent compile pools' ceilings, as OPTIONS rather than
     dynamic globals: a per-call ceiling belongs to the call
     (2026-08-25).  Automatic on both is the module constant. *)
  "PoolByteLimit" -> Automatic,
  "PoolEntryLimit" -> Automatic
};

multiquadraticStripCompile[preparation_Association,
    opts : OptionsPattern[]] := Module[
  {gate, variables, epsilon, record, roots, rules, dimensions,
   coreKey, core, eData, cData, bData, oneData, rootSquareData,
   rootLogData, reusedChannels, denominatorRecord, denominatorData,
   denominatorLogData, exactForms, compiledForms, result,
   coreEnabled, compactQ, shards, legacyQ, coreSeconds,
   oneFormSeconds, denominatorSeconds, statistics,
   gradeSupport, admissionMode, deadline, compileStop, compileProgress,
   compileBudget, compileGuard, poolByteLimit, poolEntryLimit,
   startTime = AbsoluteTime[]},
  gate = multiquadraticStripProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticStripCompile]]]];
  If[AssociationQ[gate], Return[gate]];
  (* a malformed request is a caller error and outranks a budget stop,
     exactly as in prepare and in the top-level driver *)
  deadline = OptionValue["Deadline"];
  If[! multiquadraticStripDeadlineQ[deadline],
    Return[multiquadraticStripFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  If[! TrueQ[OptionValue["PreparationValidated"]] &&
      ! multiquadraticStripPreparationValidQ[preparation],
    Return[multiquadraticStripFailure["InvalidPreparation"]]];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  record = preparation["Record"];
  roots = preparation["Roots"];
  dimensions = preparation["Dimensions"];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  legacyQ = TrueQ[OptionValue["LegacyCompiler"]];
  coreEnabled = Replace[OptionValue["CompileCore"], Automatic -> ! legacyQ];
  compactQ = Replace[OptionValue["LetterChannels"], Automatic -> ! legacyQ];
  shards = Replace[OptionValue["CompileShards"], Automatic -> 0];
  gradeSupport = Replace[OptionValue["LetterGradeSupport"],
    ell_List :> Sort[DeleteDuplicates[ell]]];
  admissionMode = Replace[OptionValue["CompactDLogAdmission"],
    Automatic -> "CertifiedOrExact"];
  poolByteLimit = Replace[OptionValue["PoolByteLimit"],
    Automatic :> $multiquadraticStripPoolByteLimit];
  poolEntryLimit = Replace[OptionValue["PoolEntryLimit"],
    Automatic :> $multiquadraticStripPoolEntryLimit];
  If[! AssociationQ[poolByteLimit] || ! AssociationQ[poolEntryLimit] ||
      ! AllTrue[Values[poolByteLimit], NumericQ[#1] && #1 > 0 &] ||
      ! AllTrue[Values[poolEntryLimit],
        #1 === Infinity || (IntegerQ[#1] && #1 > 0) &],
    Return[multiquadraticStripFailure["InvalidCompilePoolCeiling",
      <|"PoolByteLimit" -> poolByteLimit,
        "PoolEntryLimit" -> poolEntryLimit|>]]];
  If[! MemberQ[{True, False}, coreEnabled] ||
      ! MemberQ[{True, False}, compactQ] ||
      ! (IntegerQ[shards] && 0 <= shards <= 8),
    Return[multiquadraticStripFailure["InvalidCompileArchitectureOption",
      <|"CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
        "CompileShards" -> shards|>]]];
  If[! (gradeSupport === Automatic ||
      (VectorQ[gradeSupport, IntegerQ] && gradeSupport =!= {} &&
        AllTrue[gradeSupport, 0 <= #1 < preparation["GradeCount"] &])),
    Return[multiquadraticStripFailure["InvalidLetterGradeSupport",
      <|"LetterGradeSupport" -> gradeSupport,
        "GradeCount" -> preparation["GradeCount"]|>]]];
  If[! MemberQ[{"CertifiedOrExact", "Certified", "Exact"}, admissionMode],
    Return[multiquadraticStripFailure["InvalidCompactDLogAdmission",
      <|"CompactDLogAdmission" -> admissionMode,
        "Expected" -> {Automatic, "Certified", "Exact"}|>]]];
  If[legacyQ && (coreEnabled || compactQ || shards =!= 0),
    Return[multiquadraticStripFailure["LegacyCompilerOptionConflict",
      <|"CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
        "CompileShards" -> shards|>]]];
  (* ---- the cooperative compile deadline (2026-08-25, Codex 14:30) ---
     Same shape and same mechanism as prepare's: a typed resumable
     BudgetExhausted whose Stage names a "Compilation:" substage, read
     at the stage boundaries HERE and, through the dynamic deadline
     Blocked below, between decomposed entries and between letters.
     NEVER TimeConstrained: it does not bound task-broker helpers and
     has escaped in pool subkernels (CLAUDE.md). *)
  compileStop = None;
  compileProgress[] := <|
    "Family" -> Lookup[record, "Family", None],
    "Sector" -> Lookup[record, "Sector", None],
    "LowerSector" -> Lookup[record, "LowerSector", None],
    "Prime" -> Missing["NotSampled"],
    "RegulatorValue" -> Missing["NotSampled"],
    "SamplesDone" -> Missing["NotSampled"],
    "RootCount" -> Lookup[preparation, "RootCount", Missing["NotPrepared"]],
    "OneFormCount" -> Length[Lookup[preparation, "OneForms", {}]],
    "UnknownCount" -> Lookup[preparation, "UnknownCount",
      Missing["NotPrepared"]],
    "SupportSize" -> Length[Lookup[preparation, "GaugeSupport", {}]],
    "Architecture" -> If[legacyQ, "Legacy", "CoreAnsatzSplitV1"]|>;
  compileBudget[substage_String, extra_Association : <||>] :=
    multiquadraticStripBudgetExhausted["Compilation:" <> substage,
      AbsoluteTime[] - startTime, deadline,
      Join[compileProgress[], extra]];
  compileGuard[substage_String] :=
    If[multiquadraticStripDeadlineExpiredQ[deadline],
      compileStop = compileBudget[substage]; True, False];
  If[compileGuard["Entry"], Return[compileStop]];
  (* the VALUE pools are per call at both ends: they make one call
     compile each unique value once and are never carried *)
  multiquadraticStripInternReset["Scalar"];
  multiquadraticStripInternReset["Rational"];
  (* a supplied decomposition is accepted only against its own seal
     (Codex 04:30 P2); an unsealed or mismatched one is refused typed,
     never re-derived silently and never installed.  Accepted channels
     flow into the compile core as the raw array; absence flows as
     Missing so the core derives them itself. *)
  reusedChannels = Module[
    {bbarLocal = Last[Lookup[record, "Strip", {$Failed, $Failed, $Failed}]],
     seal},
    seal = multiquadraticStripForcingChannelsAccept[
    OptionValue["ForcingChannels"], bbarLocal, roots, variables, epsilon];
    Which[
      Lookup[seal, "Status", None] === "Accepted", seal["Channels"],
      Lookup[seal, "Status", None] === "NotSupplied",
        Missing["NotSupplied"],
      True, seal]];
  If[AssociationQ[reusedChannels],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure[reusedChannels["Status"],
      KeyDrop[reusedChannels, "Status"]]]];
  coreKey = If[TrueQ[coreEnabled],
    multiquadraticStripCompileCoreKey[preparation, variables, epsilon],
    $Failed];
  (* one Block for the whole compile: the decomposition loops and the
     letter loop read the dynamic deadline and leave by Throw, and Block
     restores it on every exit path including the Throw.  Infinity is
     compared by SameQ before any clock is read, so the default performs
     exactly as no deadline at all. *)
  {coreSeconds, core} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticStripActiveDeadline = deadline,
        $multiquadraticStripPoolByteLimit = poolByteLimit,
        $multiquadraticStripPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticStripCompileLegacyCore[preparation, roots, variables,
            epsilon, reusedChannels],
          multiquadraticStripCompileCoreRecord[
            Lookup[record, "Strip", $Failed], roots, variables,
            epsilon, reusedChannels, coreKey, coreEnabled]]],
      $multiquadraticStripDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["Core",
          Join[<|"Substage" -> Lookup[load, "Substage", "Core"]|>,
            KeyDrop[load, "Substage"]]];
        $Failed]]];
  If[AssociationQ[compileStop],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  If[! AssociationQ[core],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure["ExactChannelDecompositionFailed"]]];
  {eData, cData, bData, rootSquareData, rootLogData} =
    Lookup[core, {"E", "C", "BBar", "RootSquares", "RootLogDerivatives"}];
  If[compileGuard["OneForms"],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  {oneFormSeconds, oneData} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticStripActiveDeadline = deadline,
        $multiquadraticStripPoolByteLimit = poolByteLimit,
        $multiquadraticStripPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticStripCompileTensor[preparation["OneForms"], 2, roots,
            variables, epsilon],
          multiquadraticStripCompileOneForms[preparation["OneForms"],
            Lookup[preparation, "LetterRecords", None], roots, variables,
            epsilon, compactQ, shards, gradeSupport, admissionMode]]],
      $multiquadraticStripDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["OneForms",
          Join[<|"Substage" -> Lookup[load, "Substage", "OneForms"]|>,
            KeyDrop[load, "Substage"]]];
        $Failed]]];
  (* pairs with the start emitted inside multiquadraticStripCompileOneForms:
     that function has typed early exits, this line does not *)
  If[! legacyQ,
    multiquadraticStripStageDone["compile: one-forms",
      <|"seconds" -> N[oneFormSeconds],
        "status" -> Which[AssociationQ[compileStop], "BudgetExhausted",
          AssociationQ[oneData] && ! KeyExistsQ[oneData, "Status"], "OK",
          AssociationQ[oneData], Lookup[oneData, "Status", "Failed"],
          True, "Failed"],
        "paths" -> If[AssociationQ[oneData],
          Counts[Replace[Lookup[oneData, "Paths", {}],
            Except[_List] -> {}]], <||>]|>]];
  If[AssociationQ[compileStop],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  (* the typed grade-gate refusal travels as itself: it names the letter
     and the mask that left the declared grade set *)
  If[AssociationQ[oneData] && KeyExistsQ[oneData, "Status"],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure[oneData["Status"],
      KeyDrop[oneData, "Status"]]]];
  If[! AssociationQ[oneData],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure["ExactChannelDecompositionFailed"]]];
  If[compileGuard["GaugeDenominator"],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  {denominatorSeconds, denominatorRecord} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticStripActiveDeadline = deadline,
        $multiquadraticStripPoolByteLimit = poolByteLimit,
        $multiquadraticStripPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticStripCompileLegacyDenominator[
            preparation["GaugeDenominator"], variables, epsilon],
          multiquadraticStripCompileDenominatorRecord[
            preparation["GaugeDenominator"], variables, epsilon,
            coreEnabled]]],
      $multiquadraticStripDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["GaugeDenominator",
          Join[<|"Substage" -> Lookup[load, "Substage",
            "GaugeDenominator"]|>, KeyDrop[load, "Substage"]]];
        $Failed]]];
  If[AssociationQ[compileStop],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[compileStop]];
  If[! AssociationQ[denominatorRecord],
    multiquadraticStripInternReset["Scalar"];
    multiquadraticStripInternReset["Rational"];
    Return[multiquadraticStripFailure["RationalAssemblyFormCompilationFailed"]]];
  denominatorData = denominatorRecord["GaugeDenominator"];
  denominatorLogData = denominatorRecord["GaugeLogDerivatives"];
  statistics = <|
    "Architecture" -> If[legacyQ, "Legacy", "CoreAnsatzSplitV1"],
    "CoreSeconds" -> coreSeconds, "OneFormSeconds" -> oneFormSeconds,
    "GaugeDenominatorSeconds" -> denominatorSeconds,
    "CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
    (* private test control, echoed here as telemetry only *)
    "CompileShards" -> shards,
    "LetterGradeSupport" -> gradeSupport,
    "CompactDLogAdmission" -> admissionMode,
    "OneFormPaths" -> Counts[Replace[Lookup[oneData, "Paths", {}],
      Except[_List] -> {}]],
    "CompactAdmissions" -> Counts[Replace[
      Lookup[oneData, "CompactAdmissions", {}], Except[_List] -> {}]],
    "Pools" -> multiquadraticStripInternStatistics[]|>;
  multiquadraticStripInternReset["Scalar"];
  multiquadraticStripInternReset["Rational"];
  exactForms = <|"E" -> eData["Channels"], "C" -> cData["Channels"],
    "BBar" -> bData["Channels"], "OneForms" -> oneData["Channels"],
    "RootSquares" -> (First /@ rootSquareData["Channels"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Channels"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Channels"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Channels"]|>;
  compiledForms = <|"E" -> eData["Compiled"], "C" -> cData["Compiled"],
    "BBar" -> bData["Compiled"], "OneForms" -> oneData["Compiled"],
    "RootSquares" -> (First /@ rootSquareData["Compiled"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Compiled"], {2}],
    "GaugeDenominator" -> First[First[denominatorData["Compiled"]]],
    "GaugeLogDerivatives" -> First /@ denominatorLogData["Compiled"]|>;
  If[! FreeQ[compiledForms, $Failed],
    Return[multiquadraticStripFailure["CompiledAssemblyFormsInvalid"]]];
  result = <|
    "Status" -> "CompiledMultiquadraticStripV1",
    "Preparation" -> preparation,
    "Record" -> record, "Roots" -> roots,
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "GaugeSupport" -> preparation["GaugeSupport"],
    "OneForms" -> preparation["OneForms"],
    "GaugeDenominator" -> preparation["GaugeDenominator"],
    "Normalizations" -> preparation["Normalizations"],
    "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
    "ResidueUnknownCount" -> preparation["ResidueUnknownCount"],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ColumnOrder" -> preparation["ColumnOrder"],
    "RowOrder" -> preparation["RowOrder"],
    "ExactChannelForms" -> exactForms,
    "CompiledForms" -> compiledForms|>;
  result = Append[result, "CompileStatistics" -> Append[statistics,
    "Seconds" -> AbsoluteTime[] - startTime]];
  result
];
multiquadraticStripCompile[___] :=
  multiquadraticStripFailure["InvalidCompileArguments"];

multiquadraticStripCompiledValidQ[assembly_Association] := Module[
  {dimensions, rootCount, gradeCount, support, expectedGauge, expectedResidue,
   requiredKeys, preparation},
  If[Lookup[assembly, "Status", None] =!= "CompiledMultiquadraticStripV1",
    Return[False]];
  requiredKeys = {"Preparation", "Record", "Roots",
    "RootCount", "GradeCount", "Variables", "Regulator", "Dimensions",
    "GaugeSupport", "OneForms", "GaugeDenominator", "Normalizations",
    "GaugeUnknownCount", "ResidueUnknownCount", "UnknownCount",
    "EquationsPerPoint", "ColumnOrder", "RowOrder", "ExactChannelForms",
    "CompiledForms"};
  If[! AllTrue[requiredKeys, KeyExistsQ[assembly, #1] &], Return[False]];
  dimensions = assembly["Dimensions"];
  rootCount = assembly["RootCount"];
  gradeCount = assembly["GradeCount"];
  support = assembly["GaugeSupport"];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || ! IntegerQ[rootCount] ||
      ! (0 <= rootCount <= $multiquadraticStripMaximumRootCount) ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {}, Return[False]];
  expectedGauge = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[assembly["OneForms"]] Times @@ dimensions;
  preparation = assembly["Preparation"];
  TrueQ[
    multiquadraticStripPreparationValidQ[preparation] &&
    SameQ[assembly["Record"], preparation["Record"]] &&
    SameQ[assembly["Roots"], preparation["Roots"]] &&
    assembly["GaugeUnknownCount"] === expectedGauge &&
    assembly["ResidueUnknownCount"] === expectedResidue &&
    assembly["UnknownCount"] === expectedGauge + expectedResidue &&
    assembly["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    assembly["ColumnOrder"] === multiquadraticStripColumnOrder[dimensions,
      gradeCount, support, Length[assembly["OneForms"]]] &&
    assembly["RowOrder"] === multiquadraticStripRowOrder[dimensions, gradeCount] &&
    AssociationQ[assembly["ExactChannelForms"]] &&
    AssociationQ[assembly["CompiledForms"]] &&
    FreeQ[assembly["CompiledForms"], $Failed]]
];

(* ------------------------------------------------------------------ *)
(* Provider-independent row layout and coefficient data                *)
(* ------------------------------------------------------------------ *)

(* A coefficient provider is compatible with a row layout only when it
   uses the same ordered square-root generators, one-forms, dimensions and
   denominator.  These mathematical objects are stored directly. *)
multiquadraticStripCoefficientData[
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List,
    dimensions : {_Integer, _Integer}, oneForms_List,
    gaugeDenominator_] := Module[
  {rules, rootSquares, rootExpressions, canonicalSquares,
   canonicalExpressions, canonicalForms, canonicalDenominator},
  If[Min[dimensions] < 1 ||
      ! AllTrue[roots, AssociationQ[#1] &&
        squareRootRecordExpression[#1] =!= $Failed &&
        squareRootRecordRadicand[#1] =!= $Failed &&
        TrueQ[Together[squareRootRecordExpression[#1]^2 -
          squareRootRecordRadicand[#1]] === 0] &] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}], Return[$Failed]];
  rules = multiquadraticStripCanonicalRules[variables, epsilon];
  rootSquares = squareRootRecordRadicand /@ roots;
  rootExpressions = squareRootRecordExpression /@ roots;
  canonicalSquares = multiquadraticStripCanonicalExpression[#1, rules] & /@
    rootSquares;
  canonicalExpressions = multiquadraticStripCanonicalExpression[#1, rules] & /@
    rootExpressions;
  canonicalForms = Map[multiquadraticStripCanonicalExpression[#1, rules] &,
    oneForms, {2}];
  canonicalDenominator = multiquadraticStripCanonicalExpression[
    gaugeDenominator, rules];
  If[! FreeQ[{canonicalSquares, canonicalExpressions, canonicalForms,
      canonicalDenominator}, $Failed], Return[$Failed]];
  <|"Schema" -> "MultiquadraticCoefficientDataV2",
    "Dimensions" -> dimensions,
    "RootSquares" -> canonicalSquares,
    "RootExpressions" -> canonicalExpressions,
    "OneForms" -> canonicalForms,
    "GaugeDenominator" -> canonicalDenominator|>
];
multiquadraticStripCoefficientData[___] := $Failed;

(* The layout owns columns, rows and normalizations, but no coefficient
   source.  In particular it does not claim that characteristic-zero
   channels were compiled. *)
multiquadraticStripAssemblyLayout[preparation_Association] := Module[
  {coefficientData},
  If[! multiquadraticStripPreparationValidQ[preparation],
    Return[multiquadraticStripFailure["InvalidPreparation"]]];
  coefficientData = multiquadraticStripCoefficientData[
    preparation["Variables"], preparation["Regulator"],
    preparation["Roots"], preparation["Dimensions"],
    preparation["OneForms"], preparation["GaugeDenominator"]];
  If[coefficientData === $Failed,
    Return[multiquadraticStripFailure["CoefficientDataConstructionFailed"]]];
  <|
    "Status" -> "MultiquadraticStripAssemblyLayoutV1",
    "Preparation" -> preparation,
    "Record" -> preparation["Record"], "Roots" -> preparation["Roots"],
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Variables" -> preparation["Variables"],
    "Regulator" -> preparation["Regulator"],
    "Dimensions" -> preparation["Dimensions"],
    "GaugeSupport" -> preparation["GaugeSupport"],
    "OneForms" -> preparation["OneForms"],
    "GaugeDenominator" -> preparation["GaugeDenominator"],
    "Normalizations" -> preparation["Normalizations"],
    "GaugeUnknownCount" -> preparation["GaugeUnknownCount"],
    "ResidueUnknownCount" -> preparation["ResidueUnknownCount"],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ColumnOrder" -> preparation["ColumnOrder"],
    "RowOrder" -> preparation["RowOrder"],
    "CoefficientData" -> coefficientData|>
];
multiquadraticStripAssemblyLayout[___] :=
  multiquadraticStripFailure["InvalidAssemblyLayoutArguments"];

multiquadraticStripAssemblyLayoutValidQ[layout_Association] := Module[
  {dimensions, rootCount, gradeCount, support, oneForms, expectedGauge,
   expectedResidue, coefficientData, preparation},
  If[Lookup[layout, "Status", None] =!=
      "MultiquadraticStripAssemblyLayoutV1", Return[False]];
  dimensions = Lookup[layout, "Dimensions", $Failed];
  rootCount = Lookup[layout, "RootCount", $Failed];
  gradeCount = Lookup[layout, "GradeCount", $Failed];
  support = Lookup[layout, "GaugeSupport", $Failed];
  oneForms = Lookup[layout, "OneForms", $Failed];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      ! IntegerQ[rootCount] || rootCount < 0 ||
      rootCount > $multiquadraticStripMaximumRootCount ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {} ||
      ! MatchQ[oneForms, {} | {{_, _} ..}], Return[False]];
  expectedGauge = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[oneForms] Times @@ dimensions;
  coefficientData = multiquadraticStripCoefficientData[
    layout["Variables"], layout["Regulator"], layout["Roots"], dimensions,
    oneForms, layout["GaugeDenominator"]];
  If[coefficientData === $Failed, Return[False]];
  preparation = Lookup[layout, "Preparation", $Failed];
  TrueQ[
    AssociationQ[preparation] &&
    multiquadraticStripPreparationValidQ[preparation] &&
    Lookup[layout, "CoefficientData", None] === coefficientData &&
    layout["GaugeUnknownCount"] === expectedGauge &&
    layout["ResidueUnknownCount"] === expectedResidue &&
    layout["UnknownCount"] === expectedGauge + expectedResidue &&
    layout["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    layout["ColumnOrder"] === multiquadraticStripColumnOrder[dimensions,
      gradeCount, support, Length[oneForms]] &&
    layout["RowOrder"] === multiquadraticStripRowOrder[dimensions,
      gradeCount]]
];
multiquadraticStripAssemblyLayoutValidQ[___] := False;

multiquadraticStripAssemblyLayoutHotValidQ[layout_Association] := TrueQ[
  Lookup[layout, "Status", None] ===
    "MultiquadraticStripAssemblyLayoutV1" &&
  MatchQ[Lookup[layout, "Dimensions", None], {_Integer, _Integer}] &&
  Min[layout["Dimensions"]] >= 1 &&
  IntegerQ[Lookup[layout, "RootCount", None]] && layout["RootCount"] >= 0 &&
  Lookup[layout, "GradeCount", None] === 2^layout["RootCount"] &&
  IntegerQ[Lookup[layout, "UnknownCount", None]] &&
  layout["UnknownCount"] >= 0];
multiquadraticStripAssemblyLayoutHotValidQ[___] := False;

multiquadraticStripAssemblyLayoutEvaluationValidQ[layout_] :=
  multiquadraticStripAssemblyLayoutHotValidQ[layout];

(* A compiled-channel provider is an authenticated compatibility wrapper;
   it remains the characteristic-zero differential oracle, not a second
   row assembler. *)
multiquadraticStripCompiledProvider[assembly_Association] := Module[
  {preparation, layout, result},
  If[! multiquadraticStripCompiledValidQ[assembly],
    Return[multiquadraticStripFailure["InvalidCompiledAssembly"]]];
  preparation = Lookup[assembly, "Preparation", $Failed];
  layout = multiquadraticStripAssemblyLayout[preparation];
  If[! multiquadraticStripAssemblyLayoutValidQ[layout], Return[layout]];
  result = <|"Status" -> "MultiquadraticCoefficientProviderV1",
    "Kind" -> "CompiledChannel", "Assembly" -> assembly,
    "CoefficientData" -> layout["CoefficientData"],
    "RootCount" -> layout["RootCount"],
    "GradeCount" -> layout["GradeCount"],
    "Dimensions" -> layout["Dimensions"]|>;
  result
];
multiquadraticStripCompiledProvider[___] :=
  multiquadraticStripFailure["InvalidCompiledProviderArguments"];

End[];
