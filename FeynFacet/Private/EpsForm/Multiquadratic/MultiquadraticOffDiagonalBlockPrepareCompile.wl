(* FeynFacet/Private/EpsForm/Multiquadratic/MultiquadraticOffDiagonalBlockPrepareCompile.wl -- part 4 of 8 of the
   multiquadratic off-diagonal block equation solver (split from MultiquadraticOffDiagonalBlockSolve.wl in
   round 4, 2026-09-02, pure moves): preparation (root order, index data-layout contract, support, normalizations), exact channel
   compilation, the compile architecture (intern pools, core/ansatz split),
   the compiled-assembly validator, the provider-independent row layout and
   coefficient layout.
   Loads after the preceding parts (Private/LoadOrder.wl); the shared data,
   globals and the shared utilities are in MultiquadraticOffDiagonalBlockSolve.wl. *)

Begin["FeynFacet`Private`"];

ClearAll[
  multiquadraticOffDiagonalBlockCompactDLogAdmission,
  multiquadraticOffDiagonalBlockChannelGradeSupport,
  multiquadraticOffDiagonalBlockChannelVectorGradeSupport,
  multiquadraticOffDiagonalBlockCompileCoreKeyFromParts,
  multiquadraticOffDiagonalBlockCompileCoreKey,
  multiquadraticOffDiagonalBlockCompileOneFormKey,
  multiquadraticOffDiagonalBlockLetterData,
  multiquadraticOffDiagonalBlockIntern,
  multiquadraticOffDiagonalBlockInternProbe,
  multiquadraticOffDiagonalBlockInternValidQ,
  multiquadraticOffDiagonalBlockInternReset,
  multiquadraticOffDiagonalBlockInternStatistics,
  multiquadraticOffDiagonalBlockInternValueBytes,
  multiquadraticOffDiagonalBlockCompileCacheClear,
  $multiquadraticOffDiagonalBlockInternPools,
  $multiquadraticOffDiagonalBlockInternCounters,
  $multiquadraticOffDiagonalBlockPoolEntryLimit,
  $multiquadraticOffDiagonalBlockPoolByteLimit,
  $multiquadraticOffDiagonalBlockPoolOversizeBytes,
  multiquadraticOffDiagonalBlockLetterChannelData,
  multiquadraticOffDiagonalBlockRootOrder,
  multiquadraticOffDiagonalBlockRootCensusFromFrameCensus,
  multiquadraticOffDiagonalBlockRootCensus,
  multiquadraticOffDiagonalBlockBundleSquareRootGenerators,
  multiquadraticOffDiagonalBlockRootCensusWithBundle,
  multiquadraticOffDiagonalBlockCanonicalizeRadicals,
  multiquadraticOffDiagonalBlockRationalSquareQ,
  multiquadraticOffDiagonalBlockSquareClassSquareQ,
  multiquadraticOffDiagonalBlockCompileNormalizations,
  multiquadraticOffDiagonalBasisTransformationBlockIndex,
  multiquadraticOffDiagonalBlockResidueIndex,
  multiquadraticOffDiagonalBlockPointRowIndex,
  multiquadraticOffDiagonalBlockColumnOrder,
  multiquadraticOffDiagonalBlockRowOrder,
  multiquadraticOffDiagonalBlockPreparationData,
  multiquadraticOffDiagonalBlockCoreCanonicalData,
  multiquadraticOffDiagonalBlockDecomposeInhomogeneity,
  multiquadraticOffDiagonalBlockPrepare,
  multiquadraticOffDiagonalBlockPreparationValidQ,
  multiquadraticOffDiagonalBlockCompilePolynomial,
  multiquadraticOffDiagonalBlockCompileRational,
  multiquadraticOffDiagonalBlockDecomposeScalar,
  multiquadraticOffDiagonalBlockCompileTensor,
  multiquadraticOffDiagonalBlockFormShape,
  multiquadraticOffDiagonalBlockCompile,
  multiquadraticOffDiagonalBlockCompiledValidQ,
  multiquadraticOffDiagonalBlockCoefficientData,
  multiquadraticOffDiagonalBlockAssemblyLayout,
  multiquadraticOffDiagonalBlockAssemblyLayoutValidQ,
  multiquadraticOffDiagonalBlockAssemblyLayoutHotValidQ,
  multiquadraticOffDiagonalBlockAssemblyLayoutEvaluationValidQ,
  multiquadraticOffDiagonalBlockCompiledProvider
];

(* ------------------------------------------------------------------ *)
(* Preparation: root order, index data-layout contract, support, normalizations          *)
(* ------------------------------------------------------------------ *)

(* The coefficient presentation supplies the authoritative generator order.
   Two generators with the same radicand would receive separate sign bits
   for one quadratic extension and are rejected. *)
(* 2^r independent sign automorphisms need r independent square
   classes: distinct radicands are not enough, {x, y, x y} has rank two
   and would give one generator two sign bits.  Factorization over Q
   detects exactly the rational-function square relations this
   evaluator admits.  The Codex sources check only for DUPLICATE root
   squares; FamilyRowBasisTransformationFiniteField.wl's canonicalizer has this
   stronger check, and the neutral module must carry it or the
   duplicate cannot be deleted in favour of it (handoff External gap
   3).  Kept algorithmically identical to that copy so the differential
   test can compare verdicts. *)
multiquadraticOffDiagonalBlockRationalSquareQ[value : (_Integer | _Rational)] :=
  value >= 0 && IntegerQ[Sqrt[Numerator[value]]] &&
    IntegerQ[Sqrt[Denominator[value]]];
multiquadraticOffDiagonalBlockRationalSquareQ[_] := False;

multiquadraticOffDiagonalBlockSquareClassSquareQ[expression_] := Module[
  {q, numeratorFactors, denominatorFactors, constant},
  q = Quiet[Together[expression]];
  If[! FreeQ[q, Power[_, exponent_Rational /; Denominator[exponent] =!= 1]],
    Return[False]];
  numeratorFactors = Quiet[FactorList[Numerator[q]]];
  denominatorFactors = Quiet[FactorList[Denominator[q]]];
  If[! ListQ[numeratorFactors] || ! ListQ[denominatorFactors] ||
      numeratorFactors === {} || denominatorFactors === {}, Return[False]];
  constant = First[First[numeratorFactors]]/First[First[denominatorFactors]];
  multiquadraticOffDiagonalBlockRationalSquareQ[constant] &&
    AllTrue[Rest[numeratorFactors], EvenQ[Last[#1]] &] &&
    AllTrue[Rest[denominatorFactors], EvenQ[Last[#1]] &]
];

multiquadraticOffDiagonalBlockRootOrder[frame_Association, variables : {_Symbol, _Symbol},
    indices_List, epsilon_Symbol] := Module[
  {current, roots, duplicates, dependent},
  current = coefficientPresentationSquareRootsInVariables[frame, variables];
  If[! ListQ[current], Return[multiquadraticOffDiagonalBlockFailure["InvalidMultiquadraticFrame"]]];
  If[! AllTrue[indices, IntegerQ[#1] && 1 <= #1 <= Length[current] &],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidRootIndices"]]];
  roots = current[[indices]];
  If[! AllTrue[roots, AssociationQ[#1] &&
      squareRootRecordExpression[#1] =!= $Failed &&
      squareRootRecordRadicand[#1] =!= $Failed &&
      TrueQ[Together[squareRootRecordExpression[#1]^2 -
        squareRootRecordRadicand[#1]] === 0] &],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidRootMetadata"]]];
  duplicates = Select[Subsets[Range[Length[roots]], {2}],
    TrueQ[Together[squareRootRecordRadicand[roots[[#1[[1]]]]] -
      squareRootRecordRadicand[roots[[#1[[2]]]]]] === 0] &];
  If[duplicates =!= {},
    Return[multiquadraticOffDiagonalBlockFailure["DuplicateRootSquares",
      <|"DuplicatePairs" -> duplicates|>]]];
  dependent = FirstCase[Rest[Subsets[Range[Length[roots]]]],
    subset_ /; multiquadraticOffDiagonalBlockSquareClassSquareQ[
      Times @@ (squareRootRecordRadicand /@ roots[[subset]])] :> subset,
    None];
  If[dependent =!= None,
    Return[multiquadraticOffDiagonalBlockFailure["DependentRootSquares",
      <|"RootIndices" -> indices[[dependent]]|>]]];
  roots = MapThread[Join[#1, <|"SourceIndex" -> #2|>] &, {roots, indices}];
  <|"Status" -> "StableRootOrder", "Roots" -> roots,
    "SourceIndices" -> indices|>
];

(* Root census.  transportChartRootIndices is the package classifier and
   is called here, but its matcher

     Flatten[Position[rootBases, candidate_ /; Together[base - candidate] === 0]]

   (TransportCharts.wl lines 230-231, identical in Codex's
   The retired prototype classifier searched rootBases at every level and then
   flattens position specifications into root indices.  With frame
   squares {x, y, 1 + x + y} a off-diagonal block equation containing only Sqrt[x] is reported
   as rank three: x matches at {1} and again inside 1 + x + y at {3,2},
   and the flattened {3,2} contributes indices 3 and 2.  A superset is
   not harmless -- it multiplies the ansatz by 2^(extra roots), demands
   a split point for roots that do not occur, and can push a genuine
   rank-3 block past the rank ceiling -- so the decision is taken on an
   exact level-1 match here, with the package census kept alongside as a
   diagnostic.  The in-frame dispatcher has already paid for that package
   census; the helper below accepts that exact same-call result so the
   multiquadratic solver need not scan a large off-diagonal block equation twice. *)
multiquadraticOffDiagonalBlockRootCensusFromFrameCensus[frameCensus_Association,
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
     then failed on the same off-diagonal block equation transport accepts.

     The frame census above has ALREADY run the denester on every base
     the exact matcher missed -- its "DenestedRadicalBases" is exactly
     that -- so consuming it here costs nothing on an off-diagonal block equation whose radicals
     are all declared (the measured common case)
     and is the whole repair on a off-diagonal block equation whose are not.  The level-1
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
       expression with multiquadraticOffDiagonalBlockCanonicalizeRadicals first *)
    "DenestedRadicalBases" -> denested,
    "DenestedRootIndices" -> denestedIndices,
    "NumericRadicalClasses" ->
      Lookup[frameCensus, "NumericRadicalClasses", {}],
    "FrameCensusRootIndices" -> Lookup[frameCensus, "RootIndices", {}],
    "FrameCensusUnclassified" ->
      Lookup[frameCensus, "UnclassifiedRadicalBases", {}]|>
];
multiquadraticOffDiagonalBlockRootCensusFromFrameCensus[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidFrameRootCensusArguments"];

multiquadraticOffDiagonalBlockRootCensus[offDiagonalBlockEquation_, allRoots_List] :=
  multiquadraticOffDiagonalBlockRootCensusFromFrameCensus[
    transportChartRootIndices[offDiagonalBlockEquation, allRoots], allRoots];

multiquadraticOffDiagonalBlockBundleSquareRootGenerators[bundle_Association,
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
multiquadraticOffDiagonalBlockBundleSquareRootGenerators[___] := $Failed;

(* Extend the visible-off-diagonal block equation census by the authenticated root frame of a
   deferred inhomogeneity bundle.  The dense Inhomogeneity slot is deliberately zero on that
   route, so this union is the single shared authority used both before
   alphabet construction and by preparation.  The union is canonicalized by
   BlockEquationDeferred's stable frame builder, the same route used by the
   transport dispatcher; source indices remain provenance only. *)
multiquadraticOffDiagonalBlockRootCensusWithBundle[offDiagonalBlockEquation_, allRoots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, deferredBundle_] := Module[
  {classification, validation, bundleRoots, bundleIndices, selectedIndices,
   stableFrame, requiredRootIndices},
  If[AssociationQ[deferredBundle],
    validation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[validation, "Status", None] =!= "BundleValid",
      Return[multiquadraticOffDiagonalBlockFailure["InvalidDeferredBundle",
        <|"Detail" -> validation|>]]];
    If[Lookup[deferredBundle, "Variables", None] =!= variables ||
        Lookup[deferredBundle, "Regulator", None] =!= epsilon ||
        Lookup[deferredBundle, "Dimensions", None] =!=
          Prepend[Dimensions[offDiagonalBlockEquation[[3, 1]]], 2],
      Return[multiquadraticOffDiagonalBlockFailure["DeferredBundleFrameMismatch"]]],
    If[! MissingQ[deferredBundle] && deferredBundle =!= Automatic,
      Return[multiquadraticOffDiagonalBlockFailure["InvalidDeferredBundle"]]]];
  classification = multiquadraticOffDiagonalBlockRootCensus[
    offDiagonalBlockEquation, allRoots];
  If[! AssociationQ[deferredBundle],
    Return[Join[classification, <|"BundleRootIndices" -> {},
      "RequiredRootIndices" -> classification["RootIndices"]|>]]];
  bundleRoots = multiquadraticOffDiagonalBlockBundleSquareRootGenerators[
    deferredBundle, variables];
  If[! ListQ[bundleRoots],
    Return[multiquadraticOffDiagonalBlockFailure[
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
        Return[multiquadraticOffDiagonalBlockFailure[
          "DeferredBundleSquareRootGeneratorMismatch",
          <|"BundleRoot" -> bundleRoot, "Matches" -> matches|>], Module]];
      First[matches]],
    {bundleRoot, bundleRoots}];
  If[! VectorQ[bundleIndices, IntegerQ],
    Return[FirstCase[bundleIndices, failure_Association :> failure,
      multiquadraticOffDiagonalBlockFailure[
        "DeferredBundleSquareRootGeneratorMismatch"]]]];
  selectedIndices = DeleteDuplicates[Join[
    classification["RootIndices"], bundleIndices]];
  stableFrame = blockEquationDeferredValidateSquareRootGenerators[
    allRoots[[selectedIndices]],
    variables, epsilon];
  If[Lookup[stableFrame, "Status", None] =!=
      "SquareRootGeneratorsValidated",
    Return[multiquadraticOffDiagonalBlockFailure["DeferredBundleRootUnionInvalid",
      <|"Detail" -> stableFrame|>]]];
  requiredRootIndices = selectedIndices;
  Join[classification, <|"BundleRootIndices" -> bundleIndices,
    "RequiredRootIndices" -> requiredRootIndices|>]
];
multiquadraticOffDiagonalBlockRootCensusWithBundle[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidBundleRootCensusArguments"];

(* The rewrite side of the same canonicalizer.  Given an expression (a
   off-diagonal block equation, a matrix, a letter) and the census that classified it, return
   the expression with every denested radical replaced by its declared
   form, so that transportChartApplyRootBranches and therefore
   multiquadraticFieldDecompose see only declared radicands.

   A census with no denested SYMBOLIC base returns the input untouched
   and does no work: this is the measured common case, and the guard keeps
   the canonicalizer free on production-scale input.  A numeric
   class constant is a constant of the coefficient field and is left
   alone, exactly as the transport side leaves it. *)
multiquadraticOffDiagonalBlockCanonicalizeRadicals[expression_, allRoots_List,
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
    Return[multiquadraticOffDiagonalBlockFailure["RadicalCanonicalizationFailed",
      <|"Detail" -> canonical, "Bases" -> Keys[denested]|>]]];
  <|"Status" -> "RadicalsCanonicalized",
    "Expression" -> canonical["Expression"],
    "Rewritten" -> canonical["Rewritten"],
    "Bases" -> Keys[canonical["Rewrites"]],
    "Signs" -> Lookup[Values[canonical["Rewrites"]], "Sign", {}],
    "Witnesses" -> Lookup[Values[canonical["Rewrites"]], "Witness", {}]|>
];
multiquadraticOffDiagonalBlockCanonicalizeRadicals[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidRadicalCanonicalizationArguments"];

multiquadraticOffDiagonalBasisTransformationBlockIndex[upperDimension_Integer, lowerDimension_Integer,
    gradeCount_Integer, supportCount_Integer, i_Integer, j_Integer,
    grade_Integer, monomial_Integer] :=
  ((((i - 1) lowerDimension + (j - 1)) gradeCount + grade) supportCount) + monomial;

multiquadraticOffDiagonalBlockResidueIndex[offDiagonalBasisTransformationUnknownCount_Integer,
    upperDimension_Integer, lowerDimension_Integer, letter_Integer,
    i_Integer, j_Integer] :=
  offDiagonalBasisTransformationUnknownCount + (((letter - 1) upperDimension + (i - 1)) lowerDimension) + j;

multiquadraticOffDiagonalBlockPointRowIndex[targetGrade_Integer, mu_Integer, i_Integer,
    j_Integer, upperDimension_Integer, lowerDimension_Integer] :=
  ((targetGrade 2 + (mu - 1)) upperDimension + (i - 1)) lowerDimension + j;

multiquadraticOffDiagonalBlockColumnOrder[dimensions_List, gradeCount_Integer,
    support_List, oneFormCount_Integer] := <|
  "OffDiagonalBasisTransformationBlock" -> "{upperRow,lowerColumn,grade0Based,supportIndex}",
  "OffDiagonalBasisTransformationBlockIndexFormula" ->
    "((((i-1) lower+(j-1)) gradeCount+grade) supportCount+monomial)",
  "Residue" -> "{oneForm,upperRow,lowerColumn}",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount,
  "OffDiagonalBasisTransformationNumeratorSupport" -> support, "OneFormCount" -> oneFormCount|>;

multiquadraticOffDiagonalBlockRowOrder[dimensions_List, gradeCount_Integer] := <|
  "PointRows" -> "{outputGrade0Based,direction,upperRow,lowerColumn}",
  "RowIndexFormula" -> "(((grade*2+(mu-1)) upper+(i-1)) lower+j)",
  "Dimensions" -> dimensions, "GradeCount" -> gradeCount|>;

multiquadraticOffDiagonalBlockCompileNormalizations[specifications_List, dimensions_List,
    gradeCount_Integer, support_List, oneForms_List,
    offDiagonalBasisTransformationUnknownCount_Integer] := Catch[Module[
  {compiled = {}, kind, column, positions, i, j, grade, monomial, letter, value,
   unknownCount},
  unknownCount = offDiagonalBasisTransformationUnknownCount + Length[oneForms] (Times @@ dimensions);
  Do[
    If[! AssociationQ[specification],
      Throw[multiquadraticOffDiagonalBlockFailure["InvalidNormalizationEquation"]]];
    kind = Lookup[specification, "Kind", Missing["Kind"]];
    value = Lookup[specification, "Value", Missing["Value"]];
    If[MissingQ[value],
      Throw[multiquadraticOffDiagonalBlockFailure["InvalidNormalizationEquation"]]];
    column = Switch[kind,
      "Column", Lookup[specification, "Column", $Failed],
      "OffDiagonalBasisTransformationCoefficient",
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        grade = Lookup[specification, "Grade", $Failed];
        monomial = Lookup[specification, "Monomial", $Failed];
        positions = Flatten[Position[support, monomial, {1}, Heads -> False]];
        If[! IntegerQ[i] || ! IntegerQ[j] || ! IntegerQ[grade] ||
            Length[positions] =!= 1 || i < 1 || i > dimensions[[1]] ||
            j < 1 || j > dimensions[[2]] || grade < 0 || grade >= gradeCount,
          $Failed,
          multiquadraticOffDiagonalBasisTransformationBlockIndex[dimensions[[1]], dimensions[[2]],
            gradeCount, Length[support], i, j, grade, First[positions]]],
      "Residue",
        letter = Lookup[specification, "Letter", $Failed];
        i = Lookup[specification, "Upper", $Failed];
        j = Lookup[specification, "Lower", $Failed];
        If[! IntegerQ[letter] || ! IntegerQ[i] || ! IntegerQ[j] ||
            letter < 1 || letter > Length[oneForms] || i < 1 ||
            i > dimensions[[1]] || j < 1 || j > dimensions[[2]], $Failed,
          multiquadraticOffDiagonalBlockResidueIndex[offDiagonalBasisTransformationUnknownCount, dimensions[[1]],
            dimensions[[2]], letter, i, j]],
      _, $Failed];
    If[! IntegerQ[column] || column < 1 || column > unknownCount,
      Throw[multiquadraticOffDiagonalBlockFailure["InvalidNormalizationEquation",
        <|"ResolvedColumn" -> column, "UnknownCount" -> unknownCount|>]]];
    AppendTo[compiled, <|"Column" -> column, "Value" -> value, "Kind" -> kind|>],
    {specification, specifications}];
  If[! DuplicateFreeQ[Lookup[compiled, "Column", {}]],
    Throw[multiquadraticOffDiagonalBlockFailure["DuplicateNormalizationColumn"]]];
  compiled
]];

(* The context-free canonical forms of the differential equation and roots.
   Both the defining-data record and the compile-core key are built from these
   three, and none of them depends on the ansatz (support, one-forms,
   basis-transformation block denominator).  Splitting them out lets prepare key and build the
   compile core BEFORE it has a payload, and then hand the same texts to
   the payload instead of taking the whole-off-diagonal block equation InputForm twice
   (2026-08-25). *)
multiquadraticOffDiagonalBlockCoreCanonicalData[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {rules, offDiagonalBlockEquation, deferredBundle, diagonalCanonical, equationCanonical,
   bundleValidation, deferredFastQ, deferredDimensions},
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  offDiagonalBlockEquation = Lookup[record, "OffDiagonalBlockEquation", $Failed];
  If[! MatchQ[offDiagonalBlockEquation, {_List, _List, _List}], Return[$Failed]];
  deferredBundle = Lookup[record, "DeferredBundle",
    Missing["NoDeferredBundle"]];
  deferredDimensions = Quiet[Check[Dimensions[offDiagonalBlockEquation[[3, 1]]], $Failed]];
  deferredFastQ = AssociationQ[deferredBundle] &&
    MatchQ[deferredDimensions, {_Integer?Positive, _Integer?Positive}] &&
    Dimensions[offDiagonalBlockEquation[[3]]] === Prepend[deferredDimensions, 2] &&
    AllTrue[Flatten[offDiagonalBlockEquation[[3]]], SameQ[#1, 0] &] &&
    Lookup[deferredBundle, "Dimensions", None] ===
      Prepend[deferredDimensions, 2];
  equationCanonical = If[deferredFastQ,
    (* On the deferred route Inhomogeneity is intentionally a zero shape placeholder;
       its authenticated bundle is the inhomogeneity.  Re-running Together, Expand
       and InputForm over every large diagonal entry took more than nine
       minutes on a measured production block, even with CompileCore -> False.  A strict
       context-free structural seal of E/C plus the already-authenticated
       bundle binds exactly the representation this call consumes.  An
       equivalent rewrite can conservatively miss a cache/checkpoint, but it
       cannot reuse one for different input. *)
    bundleValidation = blockEquationDeferredBundleValidate[deferredBundle];
    If[Lookup[bundleValidation, "Status", None] =!= "BundleValid",
      Return[$Failed]];
    diagonalCanonical = Map[
      multiquadraticOffDiagonalBlockCanonicalExpression[#1, rules] &,
      offDiagonalBlockEquation[[1 ;; 2]], {4}];
    If[! multiquadraticOffDiagonalBlockContextFreeQ[diagonalCanonical],
      Return[$Failed]];
    <|"DiagonalConnectionBlocks" -> diagonalCanonical,
      "DeferredInhomogeneityData" ->
        (KeyTake[deferredBundle, {"Variables", "Regulator", "Parameters",
          "CoefficientPresentation", "Dimensions", "TargetOrder",
          "OperandTable", "Jobs", "DivisorOccurrences", "DivisorSummary"}]
          /. rules)|>,
    Map[multiquadraticOffDiagonalBlockCanonicalExpression[#1, rules] &, offDiagonalBlockEquation, {4}]];
  <|"RootCanonicalSquares" -> (multiquadraticOffDiagonalBlockCanonicalExpression[
      squareRootRecordRadicand[#1], rules] & /@ roots),
    "RootCanonicalExpressions" -> (multiquadraticOffDiagonalBlockCanonicalExpression[
      squareRootRecordExpression[#1], rules] & /@ roots),
    "EquationCanonical" -> equationCanonical|>
];
multiquadraticOffDiagonalBlockCoreCanonicalData[___] := $Failed;

(* The tenth argument accepts canonical data a caller has already computed;
   the shorter form derives it before recording the preparation's defining
   data. *)
multiquadraticOffDiagonalBlockPreparationData[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    offDiagonalBasisTransformationDenominator_, support_List, oneForms_List,
    normalizations_List] :=
  multiquadraticOffDiagonalBlockPreparationData[record, roots, variables, epsilon, dimensions,
    offDiagonalBasisTransformationDenominator, support, oneForms, normalizations, Automatic];

multiquadraticOffDiagonalBlockPreparationData[record_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, dimensions_List,
    offDiagonalBasisTransformationDenominator_, support_List, oneForms_List,
    normalizations_List, canonicalData_] := Module[
  {rules, canonical, canonicalSquares, canonicalRoots, equationCanonical,
   payload},
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  canonical = If[AssociationQ[canonicalData], canonicalData,
    multiquadraticOffDiagonalBlockCoreCanonicalData[record, roots, variables, epsilon]];
  If[! AssociationQ[canonical], Return[$Failed]];
  {canonicalSquares, canonicalRoots, equationCanonical} = Lookup[canonical,
    {"RootCanonicalSquares", "RootCanonicalExpressions", "EquationCanonical"}];
  payload = <|
    "Schema" -> "MultiquadraticOffDiagonalBlockPreparationV3",
    "EquationCanonical" -> equationCanonical,
    "RootCanonicalSquares" -> canonicalSquares,
    "RootCanonicalExpressions" -> canonicalRoots,
    "Dimensions" -> dimensions,
    "OffDiagonalBasisTransformationDenominator" ->
      multiquadraticOffDiagonalBlockCanonicalExpression[offDiagonalBasisTransformationDenominator, rules],
    "OffDiagonalBasisTransformationNumeratorSupport" -> support,
    "OneForms" -> Map[
      multiquadraticOffDiagonalBlockCanonicalExpression[#1, rules] &, oneForms, {2}],
    "Normalizations" -> Map[Join[KeyDrop[#1, "Value"],
      <|"Value" -> multiquadraticOffDiagonalBlockCanonicalExpression[
        Lookup[#1, "Value", $Failed], rules]|>] &, normalizations]|>;
  (* Persisted defining data must not depend on the caller's context. *)
  If[! FreeQ[payload, $Failed] || ! multiquadraticOffDiagonalBlockContextFreeQ[payload],
    Return[$Failed]];
  payload
];

Options[multiquadraticOffDiagonalBlockPrepare] = {
  "OneForms" -> Automatic,
  (* the BASE basis-transformation block denominator (Automatic: derived from the inhomogeneity and the
     letters).  A supplied value is canonicalized by
     multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator (unit leading coefficient per
     factor, factors free of the chart variables dropped) and is then
     ENLARGED by the OffDiagonalBasisTransformationDenominatorFactor below unless that is pinned to 1;
     a planted or pinned ansatz must pass "OffDiagonalBasisTransformationDenominatorFactor" -> 1
     (t_multiquadratic_installed_family_chain, 2026-09-02). *)
  "OffDiagonalBasisTransformationDenominator" -> Automatic,
  (* 2026-08-24: an extra polynomial factor of the basis-transformation block denominator, in
     the style of the rational engine's denominator options.  Automatic
     means "the norms of the algebraic letters of the alphabet actually
     used": a multiquadratic basis-transformation block acquires exactly those, and the
     Max[0, p-1] rule of multiquadraticRationalOffDiagonalBasisTransformationDenominator (which
     drops simple poles and never sees a norm at all) cannot produce
     them.  With no algebraic letter the factor is 1 and every existing
     caller is unchanged. *)
  "OffDiagonalBasisTransformationDenominatorFactor" -> Automatic,
  "DegreeOffset" -> {0, 0},
  "Support" -> Automatic,
  (* exists for ONE caller: solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators re-preparing
     at an ADOPTED degree offset in the same call.  The channel
     decomposition depends on the off-diagonal block equation and the roots only -- never on the
     support -- so the channels of the first preparation are bit for bit
     the ones this one would recompute, at a measured 807 s.  A supplied
     set is shape-checked, and Automatic (the
     default) decomposes as before, so every other caller is unchanged. *)
  "InhomogeneityChannels" -> Automatic,
  (* The preparation owns the ansatz metadata, not the coefficient
     representation.  CompiledChannel preserves the historical exact
     channel preparation.  SplitBranch and QuotientGrade deliberately
     leave InhomogeneityChannels absent and derive an automatic conservative
     denominator from the source/bundle divisors; their provider supplies
     finite-field coefficients later.  Automatic remains CompiledChannel
     for direct callers of Prepare; the top-level production driver
     resolves its own Automatic to SplitBranch. *)
  "CoefficientProvider" -> Automatic,
  (* Optional immutable BlockEquationDeferredBundleV2.  Direct providers
     consume it at modular points and the preparation consumes only its
     divisor summary; no dense inhomogeneity need be materialized. *)
  "DeferredBundle" -> Automatic,
  (* True makes the inhomogeneity channels come from the SEALED, interned
     compile core (E, C and Inhomogeneity decomposed and compiled once, keyed on
     the equation and the roots), which the compiler then finds already
     built.  False decomposes the inhomogeneity here and leaves E and C to the
     compiler.

     Automatic = FALSE.  Pre-building the core pays only where a core is
     REUSED -- a degree-offset ladder rung, a second ansatz on the same
     equation, a re-prepare -- and costs where it is not, because the
     compiler already receives prepare's sealed channels.  Turning it on
     is a measured decision per shape, never a default.  Production
     measurements fixed this default.

     Either way the result is the same: both routes reach a
     byte-identical preparation and the same assembly data records.  The
     False branch goes through the interned decomposer, which returns
     exactly what multiquadraticOffDiagonalBlockDecomposeScalar returns and so
     cannot change a value, but decomposes each distinct entry once. *)
  "CompileCore" -> Automatic,
  "NormalizationEquations" -> {},
  "RootIndices" -> Automatic,
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
     multiquadraticOffDiagonalBlockDeadlineCheckpoint: until 2026-08-25 this was the
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
     off-diagonal block equation artifacts by *)
  "CheckpointTag" -> Automatic
};

(* `record` is a Module LOCAL initialized from the argument, not the
   pattern name itself: the shared field canonicalizer (round-2 item 4)
   may rewrite the off-diagonal block equation into declared radicals, and everything after
     that point -- the defining data, the stored "Record", the compile core
   key, the inhomogeneity decomposition -- must see the SAME canonical off-diagonal block equation. *)
multiquadraticOffDiagonalBlockPrepare[sourceRecord_Association, frame_Association,
    opts : OptionsPattern[]] := Module[
  {record = sourceRecord, radicalCanonicalization,
   gate, variables, epsilon, offDiagonalBlockEquation, allRoots, classification, rootIndices,
   bundleIndices, requiredRootIndices,
   order, roots, channelInhomogeneity, suppliedChannels, oneFormData, oneForms,
   offDiagonalBasisTransformationDenominator,
   letterRecords, offDiagonalBasisTransformationDenominatorFactor,
   denominatorDegrees, degreeOffset, numeratorDegrees, support,
   completeNumeratorSupport, denominatorMonomialSupport,
   automaticSupportSelection = "CompleteRectangle", dimensions,
   gradeCount, offDiagonalBasisTransformationUnknownCount, residueUnknownCount, unknownCount,
   equationsPerPoint, normalizations, payload,
   coreEnabled, coreCanonical, coreDimensions, coreKey, coreConsumed = False,
   coefficientProvider, deferredBundle, bundleRoots, bundleRootEmbedding,
   refinedBundleBasisTransformationBlock,
   deferredPreparationWrapper, deferredPreparation,
   directPreparationQ, directPresentationData, directPresentationRoots,
   directGeneratorIndices,
   provisionalDegrees, provisionalSupportCount, provisionalUnknownCount,
   provisionalEquationsPerPoint, provisionalPointCount,
   provisionalSampleEstimate,
   checkpointDirectory, checkpointMode, checkpointEnabledQ, checkpointTag,
   checkpointRecords = {},
   checkpointRead, checkpointWrite, checkpointDefiningInput,
   inhomogeneityCheckpointInput, checkpointChannels,
   letterCheckpointInput, checkpointLetters,
   denominatorCheckpointInput, denominatorCheckpointNorms,
   checkpointDenominator,
   deadline, prepareProgress, prepareBudget, prepareStop, prepareGuard,
   familyName, sectorId, lowerSectorId, startTime = AbsoluteTime[],
   pathStatisticsBefore = multiquadraticFieldPathStatistics[], pathStatistics},
  gate = multiquadraticOffDiagonalBlockProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticOffDiagonalBlockPrepare]]]];
  If[AssociationQ[gate], Return[gate]];
  (* a malformed request is a caller error and outranks a budget stop,
     exactly as in solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators *)
  deadline = OptionValue["Deadline"];
  If[! multiquadraticOffDiagonalBlockDeadlineQ[deadline],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  (* precomputed, NOT read inside prepareProgress: a pattern variable in
     the body of a delayed definition is substituted when the outer rule
     fires, which would embed the whole off-diagonal block equation record in that definition
     (the rule TransportCharts.wl records at its own budgetProgress) *)
  {familyName, sectorId, lowerSectorId} = Lookup[record,
    {"Family", "Sector", "LowerSector"}, None];
  (* resume-safe progress: what this preparation had established when it
     stopped, so the next run can see how far the ansatz got *)
  (* The SHAPE is the engine's common typed-stop shape: the same keys
     solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators's own budgetProgress carries, so a
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
    "InhomogeneityDimensions" -> If[MatchQ[coreDimensions, {_Integer, _Integer}],
      coreDimensions, Missing["NotClassified"]],
    "InhomogeneityChannelsDone" -> ListQ[channelInhomogeneity],
    "InhomogeneityChannelSource" -> If[TrueQ[coreConsumed], "CompileCore",
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
    multiquadraticOffDiagonalBlockBudgetExhausted["Preparation:" <> substage,
      AbsoluteTime[] - startTime, deadline,
      Join[prepareProgress[], extra]];
  (* one boundary: check, and stop typed if the budget has passed *)
  prepareGuard[substage_String] :=
    If[multiquadraticOffDiagonalBlockDeadlineExpiredQ[deadline],
      prepareStop = prepareBudget[substage]; True, False];
  If[prepareGuard["Entry"], Return[prepareStop]];
  variables = Lookup[record, "Variables", $Failed];
  epsilon = Lookup[record, "Regulator", $Failed];
  offDiagonalBlockEquation = Lookup[record, "OffDiagonalBlockEquation", $Failed];
  If[! MatchQ[variables, {_Symbol, _Symbol}] || ! MatchQ[epsilon, _Symbol] ||
      ! MatchQ[offDiagonalBlockEquation, {_List, _List, _List}] ||
      SameQ[variables[[1]], variables[[2]]] || MemberQ[variables, epsilon],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidOffDiagonalBlockEquationRecord"]]];
  (* A deferred bundle is mathematical input, not telemetry.  Its inhomogeneity
     roots are absent from the deliberate zero Inhomogeneity placeholder, so it must
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
     with the visible off-diagonal block equation census. *)
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
      Dimensions[offDiagonalBlockEquation[[3]]];
  allRoots = coefficientPresentationSquareRootsInVariables[frame, variables];
  If[! ListQ[allRoots],
    Return[multiquadraticOffDiagonalBlockFailure["AlgebraicFrameNotWellFormed"]]];
  multiquadraticOffDiagonalBlockStageStart["prepare: root census"];
  classification = multiquadraticOffDiagonalBlockRootCensusWithBundle[
    offDiagonalBlockEquation, allRoots, variables, epsilon, deferredBundle];
  multiquadraticOffDiagonalBlockStageDone["prepare: root census",
    <|"source" -> "DirectEvaluation"|>];
  If[! KeyExistsQ[classification, "UnclassifiedRadicalBases"],
    Return[classification]];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[multiquadraticOffDiagonalBlockFailure["OffDiagonalBlockEquationContainsUndeclaredRadicals",
      <|"RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]]];
  (* THE SHARED CANONICALIZER (round-2 item 4).  Any radical the census
     classified only by denesting is rewritten into declared radicals
     BEFORE anything decomposes: transportChartApplyRootBranches, and so
     multiquadraticFieldDecompose, substitutes declared radicands only,
     and would otherwise fail on a off-diagonal block equation transport happily accepts.
     A off-diagonal block equation with no denested base takes the no-op branch. *)
  radicalCanonicalization = multiquadraticOffDiagonalBlockCanonicalizeRadicals[offDiagonalBlockEquation,
    allRoots, classification];
  Which[
    Lookup[radicalCanonicalization, "Status", None] ===
      "NoRadicalCanonicalizationNeeded", Null,
    Lookup[radicalCanonicalization, "Status", None] === "RadicalsCanonicalized",
      offDiagonalBlockEquation = radicalCanonicalization["Expression"];
      record = Join[record, <|"OffDiagonalBlockEquation" -> offDiagonalBlockEquation|>],
    True, Return[radicalCanonicalization]];
  bundleIndices = classification["BundleRootIndices"];
  requiredRootIndices = classification["RequiredRootIndices"];
  rootIndices = Replace[OptionValue["RootIndices"],
    Automatic :> Sort[requiredRootIndices]];
  If[! VectorQ[rootIndices, IntegerQ] || rootIndices =!= Sort[rootIndices] ||
      ! DuplicateFreeQ[rootIndices] ||
      ! SubsetQ[rootIndices, Sort[DeleteDuplicates[Join[
          classification["RootIndices"], bundleIndices]]]],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidRootIndices"]]];
  If[AssociationQ[deferredBundle] && ! ContainsAll[rootIndices, bundleIndices],
    Return[multiquadraticOffDiagonalBlockFailure[
      "DeferredBundleRootCoverageIncomplete",
      <|"RequiredRootIndices" -> bundleIndices,
        "RootIndices" -> rootIndices|>]]];
  If[directPreparationQ && ! ContainsAll[rootIndices, bundleIndices],
    Return[multiquadraticOffDiagonalBlockFailure[
      "DeferredPreparationRootCoverageIncomplete",
      <|"RequiredRootIndices" -> bundleIndices,
        "RootIndices" -> rootIndices|>]]];
  If[Length[rootIndices] > $multiquadraticOffDiagonalBlockMaximumRootCount,
    Return[multiquadraticOffDiagonalBlockFailure["UnsupportedRootRank",
      <|"MaximumRank" -> $multiquadraticOffDiagonalBlockMaximumRootCount,
        "ActualRank" -> Length[rootIndices]|>]]];
  (* before the root order, which denests and square-class-matches every
     declared radical *)
  If[prepareGuard["RootOrder"], Return[prepareStop]];
  multiquadraticOffDiagonalBlockStageStart["prepare: root order"];
  order = multiquadraticOffDiagonalBlockRootOrder[frame, variables, rootIndices, epsilon];
  multiquadraticOffDiagonalBlockStageDone["prepare: root order",
    <|"status" -> Lookup[order, "Status", None]|>];
  If[Lookup[order, "Status", None] =!= "StableRootOrder", Return[order]];
  roots = order["Roots"];
  coefficientProvider = Replace[OptionValue["CoefficientProvider"],
    Automatic -> "CompiledChannel"];
  If[! MemberQ[{"CompiledChannel", "SplitBranch", "QuotientGrade"},
      coefficientProvider],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidCoefficientProvider",
      <|"CoefficientProvider" -> coefficientProvider|>]]];
  If[! MissingQ[deferredBundle],
    bundleRoots = multiquadraticOffDiagonalBlockBundleSquareRootGenerators[
      deferredBundle, variables];
    If[! ListQ[bundleRoots],
      Return[multiquadraticOffDiagonalBlockFailure[
        "DeferredBundleCoefficientPresentationMismatch"]]];
    bundleRootEmbedding = multiquadraticOffDiagonalBlockBundleRootEmbedding[
      bundleRoots, roots];
    If[bundleRootEmbedding === $Failed,
      Return[multiquadraticOffDiagonalBlockFailure[
        "DeferredBundleRootOrderMismatch"]]];
    record = Join[record, <|"DeferredBundle" -> deferredBundle|>]];
  (* the exact decomposition WITH the recompose check, so the compiler can
     reuse this result inside the same call instead of decomposing the
     inhomogeneity a second time (post-mortem item 5: the second decomposition
     was 807 s of a measured 4872 s compile). *)
  suppliedChannels = If[coefficientProvider === "CompiledChannel",
    multiquadraticOffDiagonalBlockInhomogeneityChannelsAccept[
      OptionValue["InhomogeneityChannels"], offDiagonalBlockEquation[[3]], roots, variables, epsilon],
    <|"Status" -> "NotRequired"|>];
  If[! MemberQ[{"NotSupplied", "Accepted", "NotRequired"},
      Lookup[suppliedChannels, "Status", None]],
    Return[multiquadraticOffDiagonalBlockFailure[suppliedChannels["Status"],
      KeyDrop[suppliedChannels, "Status"]]]];
  (* Automatic is FALSE here and TRUE in multiquadraticOffDiagonalBlockCompile: the
     compiler's own core cache is 0.16 s and earns its keep across
     ansatz changes, while building it EARLY added 99.8 s in a measured
     production case.  See the option note above. *)
  coreEnabled = Replace[OptionValue["CompileCore"], Automatic -> False];
  If[! MemberQ[{True, False}, coreEnabled],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPrepareCompileCoreOption",
      <|"CompileCore" -> coreEnabled|>]]];
  (* the core key needs the equation and root canonical texts and the
     inhomogeneity dimensions, none of which depends on the ansatz.  The
     dimensions are VALIDATED further down exactly where they were
     validated at HEAD: a malformed off-diagonal block equation simply fails to key the core
     and takes the fallback, so no failure status moved. *)
  multiquadraticOffDiagonalBlockStageStart["prepare: equation identity",
    <|"deferred" -> AssociationQ[deferredBundle]|>];
  coreCanonical = multiquadraticOffDiagonalBlockCoreCanonicalData[record, roots,
    variables, epsilon];
  multiquadraticOffDiagonalBlockStageDone["prepare: equation identity",
    <|"status" -> If[AssociationQ[coreCanonical], "Prepared", "Failed"]|>];
  coreDimensions = Quiet[Check[Dimensions[offDiagonalBlockEquation[[3, 1]]], $Failed]];
  (* ---- the intermediate-persistence layer of THIS preparation ------
     Resolved once, here, so that every substage below is one
     checkpointRead / checkpointWrite pair and nothing about the file
     layout leaks into the substages themselves. *)
  checkpointDirectory = OptionValue["CheckpointDirectory"];
  checkpointMode = Replace[OptionValue["CheckpointMode"],
    Automatic -> "ReadWrite"];
  If[! (checkpointDirectory === None || StringQ[checkpointDirectory]) ||
      ! MemberQ[{"ReadWrite", "Read", "Write", "None"}, checkpointMode],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPrepareCheckpointOption",
      <|"CheckpointDirectory" -> checkpointDirectory,
        "CheckpointMode" -> checkpointMode|>]]];
  checkpointEnabledQ = checkpointDirectory =!= None &&
    checkpointMode =!= "None";
  checkpointTag = Replace[OptionValue["CheckpointTag"], Automatic :>
    StringJoin[Riffle[ToString /@ {Lookup[record, "Family", "family"],
      Lookup[record, "Sector", 0], Lookup[record, "LowerSector", 0]}, "_"]]];
  If[! StringQ[checkpointTag] || StringLength[checkpointTag] === 0 ||
      ! StringFreeQ[checkpointTag, {"/", "\\", ".."}],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPrepareCheckpointTag",
      <|"CheckpointTag" -> checkpointTag|>]]];
  (* The mathematical inputs every substage shares: this off-diagonal block equation's
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
    file = multiquadraticOffDiagonalBlockPrepareCheckpointFile[checkpointDirectory,
      checkpointTag, substage];
    If[! FileExistsQ[file],
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Read", "Status" -> "PrepareCheckpointAbsent",
        "File" -> file|>];
      Return[Missing["CheckpointAbsent"]]];
    raw = multiquadraticOffDiagonalBlockArtifactLoadRaw[file,
      "FeynFacet`MultiquadraticArtifact`"];
    If[Lookup[raw, "Status", None] =!= "RawMultiquadraticArtifact",
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Read", "Status" -> Lookup[raw, "Status", "ReadFailed"],
        "File" -> file|>];
      Return[Missing["CheckpointUnreadable"]]];
    verdict = multiquadraticOffDiagonalBlockPrepareCheckpointAccept[raw["Value"],
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
    checkpoint = multiquadraticOffDiagonalBlockPrepareCheckpointRecord[substage,
      definingInput, payload, variables, epsilon];
    If[checkpoint === $Failed,
      AppendTo[checkpointRecords, <|"Substage" -> substage,
        "Action" -> "Write", "Status" -> "PrepareCheckpointNotContextFree"|>];
      Return[Null]];
    file = multiquadraticOffDiagonalBlockPrepareCheckpointFile[checkpointDirectory,
      checkpointTag, substage];
    written = Quiet[Check[multiquadraticOffDiagonalBlockArtifactWrite[checkpoint, file],
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
    multiquadraticOffDiagonalBlockCompileCoreKeyFromParts[
      coreCanonical["EquationCanonical"],
      coreCanonical["RootCanonicalSquares"],
      coreCanonical["RootCanonicalExpressions"], coreDimensions],
    $Failed];
  (* before the inhomogeneity decomposition -- the stage that made this
     coverage necessary *)
  If[prepareGuard["InhomogeneityChannels"], Return[prepareStop]];
  (* CHECKPOINT (2026-08-25).  The payload of the inhomogeneity checkpoint IS
     the V2 sealed inhomogeneity-channel record, so a checkpoint read is
     authenticated by exactly the code path an in-memory reuse is: the
     envelope proves the file belongs to this off-diagonal block equation and this source, and
     the seal inside it proves the channels are the decomposition of
     THIS inhomogeneity.  A mutated channel fails the inner seal even if the
     envelope is rebuilt around it. *)
  inhomogeneityCheckpointInput = If[checkpointEnabledQ,
    checkpointDefiningInput["InhomogeneityChannels", {}],
    Missing["CheckpointsDisabled"]];
  checkpointChannels = If[coefficientProvider =!= "CompiledChannel" ||
      suppliedChannels["Status"] === "Accepted",
    Missing["ChannelsSupplied"],
    Module[{stored = checkpointRead["InhomogeneityChannels",
        inhomogeneityCheckpointInput], accept},
      If[MissingQ[stored], Missing["NoCheckpoint"],
        accept = multiquadraticOffDiagonalBlockInhomogeneityChannelsAccept[stored, offDiagonalBlockEquation[[3]],
          roots, variables, epsilon];
        AppendTo[checkpointRecords, <|"Substage" -> "InhomogeneityChannels",
          "Action" -> "Seal", "Status" -> Lookup[accept, "Status", None]|>];
        If[Lookup[accept, "Status", None] === "Accepted", accept["Channels"],
          Missing["CheckpointSealRefused"]]]]];
  channelInhomogeneity = Which[
    coefficientProvider =!= "CompiledChannel", Missing["DirectProvider"],
    suppliedChannels["Status"] === "Accepted", suppliedChannels["Channels"],
    ! MissingQ[checkpointChannels],
      multiquadraticOffDiagonalBlockStageMark["prepare: inhomogeneity channel decomposition",
        <|"source" -> "Checkpoint", "inhomogeneity" -> coreDimensions|>];
      checkpointChannels,
    True,
    Module[{stage = "prepare: inhomogeneity channel decomposition", seconds = 0.,
        built = $Failed},
      multiquadraticOffDiagonalBlockStageStart[stage,
        <|"family" -> Lookup[record, "Family", None],
          "sector" -> Lookup[record, "Sector", None],
          "lower" -> Lookup[record, "LowerSector", None],
          "inhomogeneity" -> coreDimensions, "rank" -> Length[roots],
          "grades" -> 2^Length[roots],
          "route" -> If[TrueQ[coreEnabled] && coreKey =!= $Failed,
            "CompileCore", "Independent"]|>];
      (* the VALUE pools are per call at both ends, exactly as in the
         compiler: they make one call decompose each unique value once
         and are never carried between calls *)
      multiquadraticOffDiagonalBlockInternReset["Scalar"];
      multiquadraticOffDiagonalBlockInternReset["Rational"];
      (* the decomposition loops read the deadline per entry and leave by
         Throw; Block restores the dynamic value on every exit path,
         including the Throw *)
      built = Catch[
        Block[{$multiquadraticOffDiagonalBlockActiveDeadline = deadline},
          {seconds, built} = AbsoluteTiming[
            If[TrueQ[coreEnabled] && coreKey =!= $Failed,
              Module[{core = multiquadraticOffDiagonalBlockCompileCoreRecord[offDiagonalBlockEquation, roots,
                  variables, epsilon, Missing["NotSupplied"], coreKey, True]},
                If[AssociationQ[core],
                  Lookup[Lookup[core, "Inhomogeneity", <||>], "Channels", $Failed],
                  $Failed]],
              $Failed]];
          coreConsumed = built =!= $Failed && FreeQ[built, $Failed];
          If[! coreConsumed,
            {seconds, built} = AbsoluteTiming[
              multiquadraticOffDiagonalBlockDecomposeInhomogeneity[offDiagonalBlockEquation[[3]], roots]]];
          built],
        $multiquadraticOffDiagonalBlockDeadlineTag,
        Function[{payload, tag},
          prepareStop = prepareBudget[
            Lookup[payload, "Substage", "InhomogeneityChannels"],
            KeyDrop[payload, "Substage"]];
          $Failed]];
      multiquadraticOffDiagonalBlockInternReset["Scalar"];
      multiquadraticOffDiagonalBlockInternReset["Rational"];
      multiquadraticOffDiagonalBlockStageDone[stage,
        <|"seconds" -> N[seconds],
          "source" -> Which[AssociationQ[prepareStop], "BudgetExhausted",
            coreConsumed, "CompileCore", True, "Independent"]|>];
      built]];
  If[AssociationQ[prepareStop], Return[prepareStop]];
  If[! FreeQ[channelInhomogeneity, $Failed],
    Return[multiquadraticOffDiagonalBlockFailure["InhomogeneityChannelDecompositionFailed"]]];
  (* written only when this call actually decomposed: a checkpoint that
     was just read back is not rewritten, and a supplied decomposition
     belongs to its caller, not to this off-diagonal block equation's persistence *)
  If[coefficientProvider === "CompiledChannel" &&
      suppliedChannels["Status"] =!= "Accepted" && MissingQ[checkpointChannels],
    checkpointWrite["InhomogeneityChannels", inhomogeneityCheckpointInput,
      multiquadraticOffDiagonalBlockInhomogeneityChannelRecord[channelInhomogeneity, offDiagonalBlockEquation[[3]],
        roots, variables, epsilon]]];
  letterRecords = OptionValue["LetterRecords"];
  oneFormData = OptionValue["OneForms"];
  (* before the candidate-letter construction, a single opaque call *)
  If[prepareGuard["CandidateLetters"], Return[prepareStop]];
  If[oneFormData === Automatic,
    If[! MatchQ[letterRecords, {___Association}],
      (* CHECKPOINT: the whole candidate-letter record, keyed on the
         off-diagonal block equation, the root order, the letter-construction options and the
         row alphabet the record supplies -- the complete input of
         multiquadraticOffDiagonalBlockCandidateLetters. *)
      letterCheckpointInput = If[checkpointEnabledQ,
        checkpointDefiningInput[
          "CandidateLetters",
          {OptionValue["RegulatorSampleCount"],
           OptionValue["RegulatorSamplePool"],
           OptionValue["RowAlphabet"] /.
             multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon],
           OptionValue["AdditionalLetters"] /.
             multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon],
           OptionValue["AlgebraicLetters"] /.
             multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon],
           OptionValue["MaximumNormFactors"],
           OptionValue["MaximumNormExponent"],
           Lookup[record, {"Sector", "LowerSector"}, None],
           Replace[Lookup[record, "OffDiagonalBlockSolutions", {}], Except[_List] :> {}] /.
             multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon]}],
        Missing["CheckpointsDisabled"]];
      checkpointLetters = checkpointRead["CandidateLetters",
        letterCheckpointInput];
      If[! MissingQ[checkpointLetters] &&
          Lookup[checkpointLetters, "Status", None] ===
            "MultiquadraticCandidateLettersV1",
        multiquadraticOffDiagonalBlockStageMark["prepare: candidate letters",
          <|"source" -> "Checkpoint",
            "letters" -> Length[Lookup[checkpointLetters, "LetterRecords",
              {}]]|>];
        letterRecords = checkpointLetters,
        checkpointLetters = Missing["NoCheckpoint"];
        multiquadraticOffDiagonalBlockStageStart["prepare: candidate letters",
          <|"family" -> Lookup[record, "Family", None],
            "sector" -> Lookup[record, "Sector", None],
            "lower" -> Lookup[record, "LowerSector", None],
            "rank" -> Length[roots], "inhomogeneity" -> coreDimensions|>];
        letterRecords = multiquadraticOffDiagonalBlockCandidateLetters[offDiagonalBlockEquation, roots,
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
        multiquadraticOffDiagonalBlockStageDone["prepare: candidate letters",
          <|"status" -> Lookup[letterRecords, "Status", None],
            "letters" -> Length[Lookup[letterRecords, "LetterRecords", {}]]|>]];
      If[Lookup[letterRecords, "Status", None] =!=
          "MultiquadraticCandidateLettersV1",
        Return[If[AssociationQ[letterRecords], letterRecords,
          multiquadraticOffDiagonalBlockFailure["OneFormBasisFailed"]]]];
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
    Return[multiquadraticOffDiagonalBlockFailure["OneFormBasisFailed"]]];
  (* after the alphabet is fixed and before the basis-transformation block denominator, which
     factors the norms of every algebraic letter actually used *)
  If[prepareGuard["OffDiagonalBasisTransformationDenominator"], Return[prepareStop]];
  (* CHECKPOINT: the norm factorization of every algebraic letter plus
     the merge with the rational denominator.  Its inputs are the
     alphabet actually used and the two denominator options. *)
  denominatorCheckpointNorms = If[
    MatchQ[letterRecords, {___Association}],
    DeleteCases[
      Lookup[#1, "Norm", Missing["NoNorm"]] & /@ letterRecords,
      _Missing], {}];
  multiquadraticOffDiagonalBlockStageStart[
    "prepare: basis-transformation block denominator checkpoint identity",
    <|"enabled" -> checkpointEnabledQ,
      "norms" -> Length[denominatorCheckpointNorms]|>];
  denominatorCheckpointInput = If[checkpointEnabledQ,
    checkpointDefiningInput[
      "OffDiagonalBasisTransformationDenominator",
      {denominatorCheckpointNorms /.
         multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon],
       OptionValue["OffDiagonalBasisTransformationDenominatorFactor"] /.
         multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon],
       OptionValue["OffDiagonalBasisTransformationDenominator"] /.
         multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon],
       If[AssociationQ[deferredBundle],
         Lookup[deferredBundle, "DivisorSummary", None], None]}],
    Missing["CheckpointsDisabled"]];
  multiquadraticOffDiagonalBlockStageDone[
    "prepare: basis-transformation block denominator checkpoint identity"];
  checkpointDenominator = checkpointRead["OffDiagonalBasisTransformationDenominator",
    denominatorCheckpointInput];
  If[MatchQ[checkpointDenominator,
      {_, _} | {_, _, {_Integer, _Integer}}],
    multiquadraticOffDiagonalBlockStageMark["prepare: basis-transformation block denominator",
      <|"source" -> "Checkpoint"|>];
    If[Length[checkpointDenominator] === 3,
      {offDiagonalBasisTransformationDenominatorFactor, offDiagonalBasisTransformationDenominator, denominatorDegrees} =
        checkpointDenominator,
      {offDiagonalBasisTransformationDenominatorFactor, offDiagonalBasisTransformationDenominator} = checkpointDenominator;
      denominatorDegrees = Missing["NotStored"]],
    checkpointDenominator = Missing["NoCheckpoint"];
    offDiagonalBasisTransformationDenominatorFactor = Replace[OptionValue["OffDiagonalBasisTransformationDenominatorFactor"],
      Automatic :> If[MatchQ[letterRecords, {___Association}],
        multiquadraticOffDiagonalBlockNormDenominatorFactor[letterRecords, variables], 1]];
    offDiagonalBasisTransformationDenominator = Replace[OptionValue["OffDiagonalBasisTransformationDenominator"], {
      supplied_ /; supplied =!= Automatic :>
        multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator[
          supplied, offDiagonalBasisTransformationDenominatorFactor, variables],
      Automatic :> If[coefficientProvider === "CompiledChannel",
        multiquadraticOffDiagonalBlockMergeOffDiagonalBasisTransformationDenominator[
          multiquadraticRationalOffDiagonalBasisTransformationDenominator[channelInhomogeneity, variables],
          offDiagonalBasisTransformationDenominatorFactor, variables],
        If[AssociationQ[deferredBundle],
          multiquadraticOffDiagonalBlockStageStart[
            "prepare: bundle basis-transformation block denominator"];
          refinedBundleBasisTransformationBlock = multiquadraticOffDiagonalBlockBundleOffDiagonalBasisTransformationDenominator[
            deferredBundle, variables,
            If[MatchQ[letterRecords, {___Association}], letterRecords, {}]];
          multiquadraticOffDiagonalBlockStageDone[
            "prepare: bundle basis-transformation block denominator",
            <|"status" -> Lookup[refinedBundleBasisTransformationBlock, "Status", None],
              "factors" -> Lookup[refinedBundleBasisTransformationBlock, "FactorCount", None],
              "groups" -> Lookup[refinedBundleBasisTransformationBlock, "GroupedFactorCount", None],
              "seconds" -> Lookup[refinedBundleBasisTransformationBlock, "Seconds", None]|>];
          If[Lookup[refinedBundleBasisTransformationBlock, "Status", None] =!=
              "BundleOffDiagonalBasisTransformationDenominatorV1", Return[refinedBundleBasisTransformationBlock, Module]];
          (* Refine only when the pre-cancellation rectangle would exceed
             the sampler's hard memory ceiling.  Small/easy blocks retain
             the cheap divisor-summary path exactly. *)
          If[OptionValue["Support"] === Automatic &&
              MatchQ[coreDimensions, {_Integer, _Integer}] &&
              MatchQ[OptionValue["DegreeOffset"],
                {_Integer?NonNegative, _Integer?NonNegative}],
            provisionalDegrees =
              refinedBundleBasisTransformationBlock["OffDiagonalBasisTransformationDenominatorDegrees"] +
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
            provisionalSampleEstimate = multiquadraticOffDiagonalBlockSampleSizeEstimate[
              provisionalPointCount, provisionalEquationsPerPoint, 0,
              provisionalUnknownCount];
            If[AssociationQ[provisionalSampleEstimate] &&
                provisionalSampleEstimate["PeakPackedBytesLowerBound"] >
                  $multiquadraticOffDiagonalBlockSampleMaximumBytes,
              multiquadraticOffDiagonalBlockStageStart[
                "prepare: exact bundle denominator refinement",
                <|"preCancellationUnknowns" -> provisionalUnknownCount,
                  "preCancellationPeakBytes" ->
                    provisionalSampleEstimate[
                      "PeakPackedBytesLowerBound"],
                  "entries" -> Times @@ coreDimensions,
                  "rank" -> Length[roots]|>];
              refinedBundleBasisTransformationBlock =
                multiquadraticOffDiagonalBlockBundleRefinedOffDiagonalBasisTransformationDenominator[
                  deferredBundle, roots, variables, epsilon,
                  If[MatchQ[letterRecords, {___Association}],
                    letterRecords, {}]];
              multiquadraticOffDiagonalBlockStageDone[
                "prepare: exact bundle denominator refinement",
                <|"status" -> Lookup[refinedBundleBasisTransformationBlock, "Status", None],
                  "seconds" -> Lookup[refinedBundleBasisTransformationBlock, "Seconds",
                    Missing["NotMeasured"]],
                  "helpers" -> Lookup[refinedBundleBasisTransformationBlock,
                    "BrokerHelperCount", 0]|>];
              If[Lookup[refinedBundleBasisTransformationBlock, "Status", None] =!=
                  "BundleRefinedOffDiagonalBasisTransformationDenominatorV1",
                Return[refinedBundleBasisTransformationBlock, Module]];
              refinedBundleBasisTransformationBlock = Join[refinedBundleBasisTransformationBlock, <|
                "PreCancellationOffDiagonalBasisTransformationDenominator" ->
                  refinedBundleBasisTransformationBlock["OffDiagonalBasisTransformationDenominator"],
                "OffDiagonalBasisTransformationDenominator" ->
                  refinedBundleBasisTransformationBlock["OffDiagonalBasisTransformationDenominator"],
                "OffDiagonalBasisTransformationDenominatorDegrees" ->
                  refinedBundleBasisTransformationBlock["OffDiagonalBasisTransformationDenominatorDegrees"],
                "ExactCancellationRefinement" ->
                  KeyDrop[refinedBundleBasisTransformationBlock, "OffDiagonalBasisTransformationDenominator"],
                "PreCancellationSampleEstimate" ->
                  provisionalSampleEstimate|>]]];
          denominatorDegrees = refinedBundleBasisTransformationBlock["OffDiagonalBasisTransformationDenominatorDegrees"];
          refinedBundleBasisTransformationBlock["OffDiagonalBasisTransformationDenominator"],
          multiquadraticOffDiagonalBlockConservativeOffDiagonalBasisTransformationDenominator[offDiagonalBlockEquation, roots,
            letterRecords, variables]]]}]];
  If[TrueQ[Together[offDiagonalBasisTransformationDenominatorFactor] === 0] ||
      ! FreeQ[offDiagonalBasisTransformationDenominatorFactor,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticOffDiagonalBlockFailure["OffDiagonalBasisTransformationDenominatorFactorNotRational",
      <|"OffDiagonalBasisTransformationDenominatorFactor" -> offDiagonalBasisTransformationDenominatorFactor|>]]];
  If[TrueQ[offDiagonalBasisTransformationDenominator === 0] ||
      ! FreeQ[offDiagonalBasisTransformationDenominator,
        Power[_, exponent_Rational /; Denominator[exponent] === 2]],
    Return[multiquadraticOffDiagonalBlockFailure["OffDiagonalBasisTransformationDenominatorNotRational"]]];
  If[! MatchQ[denominatorDegrees,
      {_Integer?NonNegative, _Integer?NonNegative}],
    multiquadraticOffDiagonalBlockStageStart[
      "prepare: basis-transformation block denominator degrees"];
    denominatorDegrees = Exponent[offDiagonalBasisTransformationDenominator, #1] & /@ variables;
    multiquadraticOffDiagonalBlockStageDone[
      "prepare: basis-transformation block denominator degrees",
      <|"degrees" -> denominatorDegrees|>]];
  If[MissingQ[checkpointDenominator],
    checkpointWrite["OffDiagonalBasisTransformationDenominator", denominatorCheckpointInput,
      {offDiagonalBasisTransformationDenominatorFactor, offDiagonalBasisTransformationDenominator, denominatorDegrees}]];
  degreeOffset = OptionValue["DegreeOffset"];
  If[! MatchQ[degreeOffset, {a_Integer, b_Integer} /; a >= 0 && b >= 0],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDegreeOffset"]]];
  numeratorDegrees = denominatorDegrees + degreeOffset;
  support = OptionValue["Support"];
  completeNumeratorSupport = Flatten[Table[{i, j},
    {i, 0, numeratorDegrees[[1]]}, {j, 0, numeratorDegrees[[2]]}], 1];
  If[support === Automatic,
    support = completeNumeratorSupport;
    (* The direct finite-field provider does not need the full bidegree
       rectangle as its first hypothesis.  For a Fuchsian off-diagonal
       equation the numerator normally follows the known denominator's
       Newton support, enlarged by one derivative step.  This candidate is
       used only when it removes at least one quarter of the rectangle; a
       failed solve is retried on completeNumeratorSupport by the driver. *)
    If[TrueQ[directPreparationQ] &&
        coefficientProvider =!= "CompiledChannel" &&
        ! AssociationQ[deferredBundle],
      denominatorMonomialSupport = First /@ CoefficientRules[
        Expand[offDiagonalBasisTransformationDenominator], variables];
      denominatorMonomialSupport = Sort@DeleteDuplicates@Select[
        Flatten[Outer[Plus, denominatorMonomialSupport,
          {{0, 0}, {1, 0}, {0, 1}}, 1], 1],
        And @@ Thread[# <= numeratorDegrees] &];
      If[MatchQ[denominatorMonomialSupport,
          {{_Integer, _Integer} ..}] &&
          4 Length[denominatorMonomialSupport] <
            3 Length[completeNumeratorSupport],
        support = denominatorMonomialSupport;
        automaticSupportSelection = "DenominatorNewtonSupport"]]];
  If[! ListQ[support] || support === {} ||
      ! AllTrue[support, MatchQ[#1, {a_Integer, b_Integer} /; a >= 0 && b >= 0] &],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidSupport"]]];
  support = Sort[DeleteDuplicates[support]];
  dimensions = Dimensions[offDiagonalBlockEquation[[3, 1]]];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      Dimensions[offDiagonalBlockEquation[[3]]] =!= Prepend[dimensions, 2],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidInhomogeneityDimensions"]]];
  If[Dimensions[offDiagonalBlockEquation[[1]]] =!= {2, dimensions[[1]], dimensions[[1]]} ||
      Dimensions[offDiagonalBlockEquation[[2]]] =!= {2, dimensions[[2]], dimensions[[2]]},
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDiagonalDimensions"]]];
  gradeCount = 2^Length[roots];
  offDiagonalBasisTransformationUnknownCount = (Times @@ dimensions) gradeCount Length[support];
  residueUnknownCount = Length[oneForms] (Times @@ dimensions);
  unknownCount = offDiagonalBasisTransformationUnknownCount + residueUnknownCount;
  equationsPerPoint = gradeCount 2 (Times @@ dimensions);
  normalizations = multiquadraticOffDiagonalBlockCompileNormalizations[
    OptionValue["NormalizationEquations"], dimensions, gradeCount, support,
    oneForms, offDiagonalBasisTransformationUnknownCount];
  If[! ListQ[normalizations], Return[normalizations]];
  (* Before recording the defining mathematical data. *)
  If[prepareGuard["DefiningData"], Return[prepareStop]];
  (* the canonical equation/root texts were already paid for above, when
     the compile core was keyed; handing them over is what keeps the
     whole-off-diagonal block equation InputForm to ONE pass *)
  payload = multiquadraticOffDiagonalBlockPreparationData[record, roots, variables, epsilon,
    dimensions, offDiagonalBasisTransformationDenominator, support, oneForms, normalizations,
    coreCanonical];
  If[payload === $Failed,
    Return[multiquadraticOffDiagonalBlockFailure["ContextSensitivePreparationData"]]];
  pathStatistics = multiquadraticFieldPathStatisticsDelta[pathStatisticsBefore,
    multiquadraticFieldPathStatistics[]];
  <|"Status" -> "PreparedMultiquadraticOffDiagonalBlockV1",
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
    (* The letters and exact inhomogeneity channels of this call; the compiler reuses
       the channels rather than decomposing the inhomogeneity again *)
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
      multiquadraticOffDiagonalBlockPotentialsCertifiedQ[letterRecords], False],
    "PotentialsCertifiedReason" -> Which[
      ! MatchQ[letterRecords, {___Association}],
        "OneFormsSuppliedWithoutLetters",
      letterRecords === {}, "EmptyAlphabet",
      multiquadraticOffDiagonalBlockPotentialsCertifiedQ[letterRecords],
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
    "OffDiagonalBasisTransformationDenominatorFactor" -> Together[offDiagonalBasisTransformationDenominatorFactor],
    (* The record carries the mathematical inhomogeneity and ordered generators
       it decomposes. *)
    "InhomogeneityChannels" -> If[coefficientProvider === "CompiledChannel",
      multiquadraticOffDiagonalBlockInhomogeneityChannelRecord[channelInhomogeneity, offDiagonalBlockEquation[[3]],
        roots, variables, epsilon], Missing["DirectProvider"]],
    "DeferredBundle" -> If[AssociationQ[deferredBundle], deferredBundle,
      Missing["NoDeferredBundle"]],
    "BundleDivisorProvenance" -> If[AssociationQ[refinedBundleBasisTransformationBlock],
      KeyDrop[refinedBundleBasisTransformationBlock, "OffDiagonalBasisTransformationDenominator"],
      Missing["BundleOffDiagonalBasisTransformationDenominatorNotUsed"]],
    "CoefficientProvider" -> coefficientProvider,
    "OffDiagonalBasisTransformationDenominator" -> Together[offDiagonalBasisTransformationDenominator],
    "OffDiagonalBasisTransformationDenominatorDegrees" -> denominatorDegrees,
    "OffDiagonalBasisTransformationNumeratorSupport" -> support,
    "CompleteOffDiagonalBasisTransformationNumeratorSupport" ->
      completeNumeratorSupport,
    "AutomaticSupportSelection" -> automaticSupportSelection,
    "Dimensions" -> dimensions,
    "GradeCount" -> gradeCount,
    "OffDiagonalBasisTransformationUnknownCount" -> offDiagonalBasisTransformationUnknownCount,
    "ResidueUnknownCount" -> residueUnknownCount,
    "UnknownCount" -> unknownCount,
    "EquationsPerPoint" -> equationsPerPoint,
    "Normalizations" -> normalizations,
    "ColumnOrder" -> multiquadraticOffDiagonalBlockColumnOrder[dimensions, gradeCount,
      support, Length[oneForms]],
    "RowOrder" -> multiquadraticOffDiagonalBlockRowOrder[dimensions, gradeCount],
    (* channel-decomposition telemetry of THIS preparation, not of the
       process: the scalar-local root-free fast path count and the
       algebraic (field reduction + inversion) count *)
    "RootFreeFastPathCount" -> pathStatistics["RootFreeFastPathCount"],
    "ChannelPathStatistics" -> pathStatistics,
    (* What this preparation persisted and read back. *)
    "PrepareCheckpoints" -> checkpointRecords,
    "DefiningData" -> payload|>
];
multiquadraticOffDiagonalBlockPrepare[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidPrepareArguments"];

multiquadraticOffDiagonalBlockPreparationValidQ[preparation_Association] := Module[
  {payload, roots, dimensions, gradeCount, offDiagonalBasisTransformationUnknownCount, residueUnknownCount},
  If[Lookup[preparation, "Status", None] =!= "PreparedMultiquadraticOffDiagonalBlockV1",
    Return[False]];
  roots = Lookup[preparation, "Roots", $Failed];
  dimensions = Lookup[preparation, "Dimensions", $Failed];
  If[! ListQ[roots] || ! MatchQ[dimensions, {_Integer, _Integer}], Return[False]];
  payload = multiquadraticOffDiagonalBlockPreparationData[preparation["Record"], roots,
    preparation["Variables"], preparation["Regulator"], dimensions,
    preparation["OffDiagonalBasisTransformationDenominator"], preparation["OffDiagonalBasisTransformationNumeratorSupport"],
    preparation["OneForms"], preparation["Normalizations"]];
  If[payload === $Failed, Return[False]];
  gradeCount = 2^Length[roots];
  offDiagonalBasisTransformationUnknownCount = (Times @@ dimensions) gradeCount
    Length[preparation["OffDiagonalBasisTransformationNumeratorSupport"]];
  residueUnknownCount = Length[preparation["OneForms"]] (Times @@ dimensions);
  TrueQ[
    payload === Lookup[preparation, "DefiningData", Missing["Data"]] &&
    Lookup[preparation, "RootCount", Missing["RootCount"]] === Length[roots] &&
    Lookup[preparation, "GradeCount", Missing["GradeCount"]] === gradeCount &&
    Lookup[preparation, "OffDiagonalBasisTransformationUnknownCount", Missing["OffDiagonalBasisTransformationBlock"]] ===
      offDiagonalBasisTransformationUnknownCount &&
    Lookup[preparation, "ResidueUnknownCount", Missing["Residue"]] ===
      residueUnknownCount &&
    Lookup[preparation, "UnknownCount", Missing["Unknown"]] ===
      offDiagonalBasisTransformationUnknownCount + residueUnknownCount &&
    Lookup[preparation, "EquationsPerPoint", Missing["Equations"]] ===
      gradeCount 2 (Times @@ dimensions)]
];

(* ------------------------------------------------------------------ *)
(* Exact channel compilation into a sparse x/y polynomial data-layout contract           *)
(* ------------------------------------------------------------------ *)

(* Terms sharing an x/y monomial are grouped; the row keeps the exact
   coefficients of eps^0..eps^K, so one compilation serves every
   regulator value and every prime. *)
multiquadraticOffDiagonalBlockCompilePolynomial[polynomial_, variables : {_Symbol, _Symbol},
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
  If[maximumEpsilonDegree > $multiquadraticOffDiagonalBlockMaximumEpsilonDegree,
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

multiquadraticOffDiagonalBlockCompileRational[expression_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := Module[{rational, numerator, denominator},
  rational = Together[expression];
  If[! FreeQ[rational, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  numerator = multiquadraticOffDiagonalBlockCompilePolynomial[Numerator[rational],
    variables, epsilon];
  denominator = multiquadraticOffDiagonalBlockCompilePolynomial[Denominator[rational],
    variables, epsilon];
  If[numerator === $Failed || denominator === $Failed ||
      denominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalExactV1", "Numerator" -> numerator,
    "Denominator" -> denominator|>
];

multiquadraticOffDiagonalBlockDecomposeScalar[expression_, roots_List] := Module[
  {channels, reconstructed},
  channels = multiquadraticFieldDecompose[expression, roots];
  If[! ListQ[channels] || Length[channels] =!= 2^Length[roots] ||
      MemberQ[channels, $Failed], Return[$Failed]];
  reconstructed = multiquadraticFieldCompose[channels, roots];
  If[! TrueQ[Together[reconstructed - expression] === 0], Return[$Failed]];
  channels
];

multiquadraticOffDiagonalBlockCompileTensor[tensor_, scalarLevel_Integer, roots_List,
    variables_List, epsilon_Symbol] := Module[{channels, compiled},
  channels = Map[multiquadraticOffDiagonalBlockDecomposeScalar[#1, roots] &, tensor,
    {scalarLevel}];
  If[! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[multiquadraticOffDiagonalBlockCompileRational[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

(* ------------------------------------------------------------------ *)
(* The compile architecture (2026-08-25)                                *)
(* ------------------------------------------------------------------ *)

(* This design follows an audited analysis of a compile measured at
   4872 s against a 0.7 s affine solve.  Five changes, in dependency order:

     1 an immutable compiled equation CORE (E, C, Inhomogeneity, root squares and
       their log derivatives) keyed on the equation, the roots and the
       chart symbols only, plus a separately keyed basis-transformation block-denominator
       record.  Neither depends on the ansatz, so a support or
       DegreeOffset change compiles NOTHING and an exact-prefix alphabet
       extension compiles only the suffix (Codex's measured rebind
       evidence: 12 s against 691 s for a fresh compile);

     2 interned exact scalars and channel values: a hash bucket with a
       SameQ collision check, so each unique value is decomposed and
       compiled once.  The zero channel of a 2^r grade vector, and the
       zero entries of a sparse E/C/Inhomogeneity, are the common case;

     3 compact letter channels.  For a letter L = A + B r_m the one-form
       dlog L is built from the LETTER's own grade channels, its
       derivative in the grade basis and the norm A^2 - B^2 delta_m; the
       expanded D[L]/L tree is never decomposed.  That tree is the
       measured expensive object (the inhomogeneity-dlog letters carry 10^4 to
       10^5 leaves).  A general multigrade letter takes the same route
       through the existing field multiplication/inversion data-layout contract;

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
  multiquadraticOffDiagonalBlockInternReset, multiquadraticOffDiagonalBlockIntern,
  multiquadraticOffDiagonalBlockInternValidQ,
  multiquadraticOffDiagonalBlockInternProbe, multiquadraticOffDiagonalBlockInternStatistics,
  multiquadraticOffDiagonalBlockCompileCacheClear,
  multiquadraticOffDiagonalBlockCompileRationalFromPair,
  multiquadraticOffDiagonalBlockCompileRationalCanonical,
  multiquadraticOffDiagonalBlockDecomposeScalarInterned,
  multiquadraticOffDiagonalBlockCompileRationalInterned,
  multiquadraticOffDiagonalBlockCompileTensorInterned,
  multiquadraticOffDiagonalBlockCompactInverse, multiquadraticOffDiagonalBlockLetterChannelPair,
  multiquadraticOffDiagonalBlockCompileOneFormEntry, multiquadraticOffDiagonalBlockCompileOneForms,
  multiquadraticOffDiagonalBlockCompileShardTask,
  multiquadraticOffDiagonalBlockCompileCoreKey, multiquadraticOffDiagonalBlockCompileCoreKeyFromParts,
  multiquadraticOffDiagonalBlockCompileCoreRecord,
  multiquadraticOffDiagonalBlockCompileDenominatorRecord,
  multiquadraticOffDiagonalBlockCompileLegacyCore,
  multiquadraticOffDiagonalBlockCompileLegacyDenominator,
  $multiquadraticOffDiagonalBlockInternPools, $multiquadraticOffDiagonalBlockInternCounters,
  $multiquadraticOffDiagonalBlockInternCounterNames,
  $multiquadraticOffDiagonalBlockPoolEntryLimit, $multiquadraticOffDiagonalBlockCompileShardMinimum
];

$multiquadraticOffDiagonalBlockInternPools = <||>;
$multiquadraticOffDiagonalBlockInternCounters = <||>;

(* "Scalar" and "Rational" are VALUE pools, reset at both ends of a
   compile call: they exist to make one call compile each unique value
   once, and holding them would grow a long-lived pool kernel without
   bound.  "Core", "OffDiagonalBasisTransformationDenominator" and "OneForm" are the persistent
   pools -- they ARE the core/ansatz split -- and are bounded by entry
   count; a pool at its cap starts again rather than growing.

   BYTE BOUNDS (2026-08-25, Codex 14:30 "persistent cache memory bound").
   An entry count is not a memory bound: one production-sized compile core is
   hundreds of megabytes and two of them are the whole ceiling, while
   512 small one-forms are nothing.  Each pool therefore also declares a
   MEASURED ByteCount ceiling, and an OVERSIZE value -- one that alone
   exceeds the pool's own oversize allowance -- BYPASSES the cache
   instead of evicting it: returning it to the caller uncached costs one
   recomputation, while admitting it would flush every entry the pool
   holds to store something that cannot be held anyway.  ByteCount is
   measured once per admitted value; it is a traversal, and it is taken
   only on a MISS, never on a hit. *)
$multiquadraticOffDiagonalBlockPoolEntryLimit = <|
  "Core" -> 2, "OffDiagonalBasisTransformationDenominator" -> 16, "OneForm" -> 512|>;

(* the pool's total measured ByteCount ceiling *)
$multiquadraticOffDiagonalBlockPoolByteLimit = <|
  "Core" -> 2. 10^9, "OffDiagonalBasisTransformationDenominator" -> 2. 10^8, "OneForm" -> 1. 10^9|>;

(* a single value above this is never admitted: it bypasses the pool and
   the pool keeps what it already holds.  Automatic = the pool's own byte
   ceiling, i.e. "no single value may fill the pool by itself". *)
$multiquadraticOffDiagonalBlockPoolOversizeBytes = <|
  "Core" -> Automatic, "OffDiagonalBasisTransformationDenominator" -> Automatic,
  "OneForm" -> Automatic|>;

multiquadraticOffDiagonalBlockInternValueBytes[value_] := N[ByteCount[value]];

(* below this many uncached one-forms a shard cannot pay for its own
   serialization and kernel round trip *)
$multiquadraticOffDiagonalBlockCompileShardMinimum = 8;

(* Both pools are flat Associations keyed by the actual held data and by
   {pool,
   counter}: a one-level Part assignment on a symbol holding an
   Association is the only update form with a guaranteed constant-time
   semantics, and the compile does thousands of these per call. *)
$multiquadraticOffDiagonalBlockInternCounterNames = {"Hits", "Misses",
  "Entries", "Resets", "Rejected", "Bytes", "Oversize"};

multiquadraticOffDiagonalBlockInternReset[pool_String] := (
  $multiquadraticOffDiagonalBlockInternPools = KeySelect[$multiquadraticOffDiagonalBlockInternPools,
    First[#1] =!= pool &];
  Scan[($multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, #1}]]] = 0) &,
    $multiquadraticOffDiagonalBlockInternCounterNames];);

multiquadraticOffDiagonalBlockInternStatistics[] := Module[{pools},
  pools = DeleteDuplicates[First /@ Keys[$multiquadraticOffDiagonalBlockInternCounters]];
  Association[Table[pool -> Association[Table[
      name -> Lookup[$multiquadraticOffDiagonalBlockInternCounters, Key[{pool, name}], 0],
      {name, $multiquadraticOffDiagonalBlockInternCounterNames}]],
    {pool, pools}]]
];

multiquadraticOffDiagonalBlockCompileCacheClear[] := (
  $multiquadraticOffDiagonalBlockInternPools = <||>;
  $multiquadraticOffDiagonalBlockInternCounters = <||>;
  <|"Status" -> "MultiquadraticOffDiagonalBlockCompileCachesCleared"|>);

(* Present without computing: the shard planner needs to know which
   one-forms the pool already holds before it decides what to farm. *)
multiquadraticOffDiagonalBlockInternProbe[pool_String, key_] :=
  Lookup[$multiquadraticOffDiagonalBlockInternPools,
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
multiquadraticOffDiagonalBlockInternValidQ["Core", value_] :=
  AssociationQ[value] && FreeQ[value, $Failed] &&
    AllTrue[{"E", "C", "Inhomogeneity", "RootSquares", "RootLogDerivatives"},
      AssociationQ[Lookup[value, #1, $Failed]] &];
multiquadraticOffDiagonalBlockInternValidQ["OffDiagonalBasisTransformationDenominator", value_] :=
  AssociationQ[value] && FreeQ[value, $Failed] &&
    AllTrue[{"OffDiagonalBasisTransformationDenominator", "OffDiagonalBasisTransformationDenominatorLogDerivatives"},
      AssociationQ[Lookup[value, #1, $Failed]] &];
(* the OneForm pool holds compiled entries only.  A typed REFUSAL (an
   Association carrying "Status") is a negative result and is never
   interned -- the same rule the Core pool's $Failed refusal follows. *)
multiquadraticOffDiagonalBlockInternValidQ["OneForm", value_] :=
  AssociationQ[value] && ! KeyExistsQ[value, "Status"] &&
    FreeQ[value, $Failed] &&
    AllTrue[{"Channels", "Compiled", "Path"}, KeyExistsQ[value, #1] &];
multiquadraticOffDiagonalBlockInternValidQ[_String, value_] :=
  value =!= $Failed && FreeQ[value, $Failed];

multiquadraticOffDiagonalBlockIntern[pool_String, key_, compute_] := Module[
  {entryKey, hit, value, limit, byteLimit, oversizeLimit, bytes,
   poolBytes, hits, misses, resets, oversize, counter},
  counter[name_String] :=
    Lookup[$multiquadraticOffDiagonalBlockInternCounters, Key[{pool, name}], 0];
  entryKey = Key[{pool, key}];
  hit = Lookup[$multiquadraticOffDiagonalBlockInternPools, entryKey,
    Missing["NotInterned"]];
  If[! MissingQ[hit],
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Hits"}]]] =
      counter["Hits"] + 1;
    Return[hit]];
  value = compute[];
  (* refused BEFORE any counter or bucket is touched: a rejected value
     leaves the pool exactly as it found it *)
  If[! multiquadraticOffDiagonalBlockInternValidQ[pool, value],
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Rejected"}]]] =
      counter["Rejected"] + 1;
    Return[value]];
  limit = Lookup[$multiquadraticOffDiagonalBlockPoolEntryLimit, pool, Infinity];
  byteLimit = Lookup[$multiquadraticOffDiagonalBlockPoolByteLimit, pool, Infinity];
  oversizeLimit = Replace[
    Lookup[$multiquadraticOffDiagonalBlockPoolOversizeBytes, pool, Automatic],
    Automatic :> byteLimit];
  (* the measurement is taken ONCE, on a miss, on the value that is about
     to be admitted -- never on a hit, and never on the pool as a whole *)
  bytes = multiquadraticOffDiagonalBlockInternValueBytes[value];
  (* OVERSIZE BYPASS.  A value that alone exceeds the pool's allowance is
     returned uncached: it is one recomputation against flushing every
     entry the pool holds for something the pool cannot hold. *)
  If[NumericQ[oversizeLimit] && bytes > oversizeLimit,
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Misses"}]]] =
      counter["Misses"] + 1;
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Oversize"}]]] =
      counter["Oversize"] + 1;
    Return[value]];
  poolBytes = counter["Bytes"];
  If[counter["Entries"] >= limit ||
      (NumericQ[byteLimit] && poolBytes + bytes > byteLimit),
    (* bounded on BOTH axes: a pool at either cap starts again rather
       than growing without bound in a long-lived pool kernel *)
    hits = counter["Hits"]; misses = counter["Misses"];
    resets = counter["Resets"]; oversize = counter["Oversize"];
    multiquadraticOffDiagonalBlockInternReset[pool];
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Hits"}]]] = hits;
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Misses"}]]] = misses;
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Oversize"}]]] = oversize;
    $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Resets"}]]] = resets + 1;
    poolBytes = 0];
  $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Misses"}]]] =
    counter["Misses"] + 1;
  $multiquadraticOffDiagonalBlockInternPools[[entryKey]] = value;
  $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Entries"}]]] =
    counter["Entries"] + 1;
  $multiquadraticOffDiagonalBlockInternCounters[[Key[{pool, "Bytes"}]]] =
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
multiquadraticOffDiagonalBlockCompileRationalFromPair[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {compiledNumerator, compiledDenominator},
  If[! FreeQ[expression, Power[_, exponent_Rational /; ! IntegerQ[exponent]]],
    Return[$Failed]];
  compiledNumerator = multiquadraticOffDiagonalBlockCompilePolynomial[
    Numerator[expression], variables, epsilon];
  If[compiledNumerator === $Failed, Return[$Failed]];
  compiledDenominator = multiquadraticOffDiagonalBlockCompilePolynomial[
    Denominator[expression], variables, epsilon];
  If[compiledDenominator === $Failed ||
      compiledDenominator["EpsilonCoefficientRows"] === {}, Return[$Failed]];
  <|"Type" -> "MultiquadraticRationalExactV1",
    "Numerator" -> compiledNumerator, "Denominator" -> compiledDenominator|>
];

multiquadraticOffDiagonalBlockCompileRationalCanonical[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[{fast},
  fast = multiquadraticOffDiagonalBlockCompileRationalFromPair[expression, variables,
    epsilon];
  If[fast =!= $Failed, fast,
    multiquadraticOffDiagonalBlockCompileRational[expression, variables, epsilon]]
];

(* The ROOTS are part of the key, not context.  The same scalar is
   decomposed at two different ranks inside ONE compile: the root
   squares and the root/basis-transformation block log derivatives are decomposed over the
   EMPTY root set (they are rational by construction), while E, C, Inhomogeneity
   and the one-forms are decomposed over the declared roots.  Keying on
   the expression alone let 1/x -- the log derivative of the root square
   delta = x, and equally the x-component of dlog x -- return a rank-0
   channel vector of width 1 where the grade data-layout contract demands width 2^r.
   Found 2026-08-25 by t_multiquadratic_off-diagonal block equation_solve. *)
multiquadraticOffDiagonalBlockDecomposeScalarInterned[expression_, roots_List] :=
  multiquadraticOffDiagonalBlockIntern["Scalar", {roots, expression},
    Function[multiquadraticOffDiagonalBlockDecomposeScalar[expression, roots]]];

multiquadraticOffDiagonalBlockCompileRationalInterned[expression_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  multiquadraticOffDiagonalBlockIntern["Rational", expression,
    Function[multiquadraticOffDiagonalBlockCompileRationalCanonical[expression,
      variables, epsilon]]];

(* prepare's INDEPENDENT inhomogeneity decomposition -- the fallback taken when
   the compile core cannot be built or is switched off.  It differs from
   the HEAD expression Map[multiquadraticOffDiagonalBlockDecomposeScalar[...], ...,
   {3}] in two ways that cannot change its value: the interned decomposer
   (which memoizes multiquadraticOffDiagonalBlockDecomposeScalar and returns exactly
   its result, so the repeated zero entries of a sparse inhomogeneity are
   decomposed once) and one rate-limited progress line per interval. *)
multiquadraticOffDiagonalBlockDecomposeInhomogeneity[inhomogeneity_, roots_List] := Module[
  {stage = "prepare: inhomogeneity channel decomposition", total, done = 0,
   started = AbsoluteTime[]},
  total = Quiet[Check[Times @@ Take[Dimensions[inhomogeneity], UpTo[3]], 0]];
  Map[Function[entry,
      done++;
      multiquadraticOffDiagonalBlockDeadlineCheckpoint["InhomogeneityChannels",
        <|"Entry" -> done, "Of" -> total,
          "SubstageSeconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticOffDiagonalBlockStageProgress[stage,
        <|"entry" -> done, "of" -> total,
          "seconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticOffDiagonalBlockDecomposeScalarInterned[entry, roots]],
    inhomogeneity, {3}]
];

multiquadraticOffDiagonalBlockCompileTensorInterned[tensor_, scalarLevel_Integer,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol] :=
  multiquadraticOffDiagonalBlockCompileTensorInterned[tensor, scalarLevel, roots,
    variables, epsilon, None];

(* "stage" is a telemetry label only.  With a label the decomposition
   emits ONE rate-limited progress line per interval naming the entry it
   has reached; without one (the root squares and log derivatives, which
   are a handful of scalars) it is silent.  Nothing else differs, so the
   returned record is byte-identical either way. *)
multiquadraticOffDiagonalBlockCompileTensorInterned[tensor_, scalarLevel_Integer,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    stage_] := Module[
  {channels, compiled, total, done = 0, started = AbsoluteTime[], decompose},
  If[StringQ[stage],
    total = Times @@ Take[Dimensions[tensor], UpTo[scalarLevel]];
    multiquadraticOffDiagonalBlockStageStart[stage,
      <|"entries" -> total, "rank" -> Length[roots],
        "grades" -> 2^Length[roots]|>];
    decompose[entry_] := (
      done++;
      multiquadraticOffDiagonalBlockDeadlineCheckpoint[stage,
        <|"Entry" -> done, "Of" -> total,
          "SubstageSeconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticOffDiagonalBlockStageProgress[stage,
        <|"entry" -> done, "of" -> total,
          "seconds" -> N[AbsoluteTime[] - started]|>];
      multiquadraticOffDiagonalBlockDecomposeScalarInterned[entry, roots]),
    decompose[entry_] := (
      multiquadraticOffDiagonalBlockDeadlineCheckpoint["CompileTensor", <||>];
      multiquadraticOffDiagonalBlockDecomposeScalarInterned[entry, roots])];
  channels = Map[decompose, tensor, {scalarLevel}];
  If[! FreeQ[channels, $Failed],
    If[StringQ[stage],
      multiquadraticOffDiagonalBlockStageDone[stage,
        <|"seconds" -> N[AbsoluteTime[] - started], "status" -> "Failed"|>]];
    Return[$Failed]];
  compiled = Map[
    multiquadraticOffDiagonalBlockCompileRationalInterned[#1, variables, epsilon] &,
    channels, {scalarLevel + 1}];
  If[StringQ[stage],
    multiquadraticOffDiagonalBlockStageDone[stage,
      <|"seconds" -> N[AbsoluteTime[] - started],
        "status" -> If[FreeQ[compiled, $Failed], "OK", "Failed"]|>]];
  If[! FreeQ[compiled, $Failed], $Failed,
    <|"Channels" -> channels, "Compiled" -> compiled|>]
];

(* Codex item 3, the inverse.  A element with grade support {0, m} has
   the two-term inverse (A - B r_m)/(A^2 - B^2 delta_m) -- its NORM, not
   a 2^r x 2^r rational solve; a pure single-grade element inverts in
   one division.  Any other support falls through to the general field
   inversion data-layout contract.  Every branch is accepted only after the exact product
   check against the grade identity, which is the same acceptance
   multiquadraticFieldInverse makes. *)
multiquadraticOffDiagonalBlockCompactInverse[a_List, deltas_List] := Module[
  {dimension = Length[a], nonzero, mask, factor, norm, inverse, check,
   general = False},
  If[dimension =!= 2^Length[deltas], Return[$Failed]];
  (* the channels arrive from the field data-layout contract, which ends in Together, so a
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
      ! multiquadraticOffDiagonalBlockZeroQ[check - UnitVector[dimension, 1]],
    $Failed, inverse]
];

(* Codex item 3, the one-form.  dlog L = (dL) L^-1 entirely inside the
   grade algebra: decompose the LETTER (the small object), check that it
   recomposes exactly, invert by the norm, differentiate in the grade
   basis (multiquadraticDerivative carries the dlog delta term, so the
   derivative never leaves its grade) and multiply.  The expanded
   D[L]/L tree is never formed and never decomposed.

   Exactness: the recompose check certifies the channels of L; the
   product check inside multiquadraticOffDiagonalBlockCompactInverse certifies the
   inverse; derivative and product are exact identities of the data-layout contract.  So
   the returned channels are the exact channels of dlog L without any
   check on the materialized tree. *)
multiquadraticOffDiagonalBlockLetterChannelData[letter_, roots_List,
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
  inverse = multiquadraticOffDiagonalBlockCompactInverse[channels, deltas];
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
multiquadraticOffDiagonalBlockLetterChannelData[___] := $Failed;

multiquadraticOffDiagonalBlockLetterChannelPair[letter_, roots_List,
    variables : {_Symbol, _Symbol}] := Module[{data},
  data = multiquadraticOffDiagonalBlockLetterChannelData[letter, roots, variables];
  If[AssociationQ[data], Lookup[data, "DLogChannels", $Failed], $Failed]
];

(* The compact path may reuse retained channels only for a pair already
   known to satisfy omega=dlog(L).  Package-constructed pairs record that
   fact by construction; caller-supplied pairs reach this point only after
   the explicit symbolic dlog equation has been verified.  The retained
   channels are still recomposed and compared with the requested one-form
   before use. *)
multiquadraticOffDiagonalBlockCompactDLogAdmission[letterRecord_, form_,
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
  derived = multiquadraticOffDiagonalBlockLetterOneForm[letter, variables];
  If[! MatchQ[derived, {_, _}],
    Return[<|"Admitted" -> False, "Reason" -> "LetterHasNoDLog"|>]];
  If[! (TrueQ[Together[derived[[1]] - form[[1]]] === 0] &&
        TrueQ[Together[derived[[2]] - form[[2]]] === 0]),
    Return[<|"Admitted" -> False,
      "Reason" -> "OneFormIsNotTheLetterDLog"|>]];
  <|"Admitted" -> True, "Method" -> "ExactDLogCheck", "Letter" -> letter|>
];

(* the grade masks one channel VECTOR occupies.  The channels arrive from
   the field data-layout contract, which ends in Together, so a zero channel is the
   integer 0 and no normalization is needed here. *)
multiquadraticOffDiagonalBlockChannelVectorGradeSupport[vector_List] :=
  Flatten[Position[vector, entry_ /; ! TrueQ[entry === 0], {1},
    Heads -> False]] - 1;

(* the union over a list of channel vectors (a one-form is two of them) *)
multiquadraticOffDiagonalBlockChannelGradeSupport[vectors : {__List}] :=
  Sort[DeleteDuplicates[Flatten[
    multiquadraticOffDiagonalBlockChannelVectorGradeSupport /@ vectors]]];
multiquadraticOffDiagonalBlockChannelGradeSupport[vector_List] :=
  Sort[multiquadraticOffDiagonalBlockChannelVectorGradeSupport[vector]];

(* One compiled one-form. *)
multiquadraticOffDiagonalBlockCompileOneFormEntry[form : {_, _}, letterRecord_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_] := multiquadraticOffDiagonalBlockCompileOneFormEntry[form, letterRecord,
  roots, variables, epsilon, compactQ, Automatic, Automatic];

multiquadraticOffDiagonalBlockCompileOneFormEntry[form : {_, _}, letterRecord_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, gradeSupport_, admissionMode_] := Module[
  {channels = $Failed, admission = <|"Admitted" -> False,
     "Reason" -> "CompactRouteDisabled"|>, path, compiled, support,
   admissible, retainedChannels, recomposed},
  If[TrueQ[compactQ],
    admission = multiquadraticOffDiagonalBlockCompactDLogAdmission[letterRecord, form,
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
        channels = multiquadraticOffDiagonalBlockLetterChannelPair[
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
    support = multiquadraticOffDiagonalBlockChannelGradeSupport[channels];
    If[! VectorQ[admissible, IntegerQ] || ! SubsetQ[admissible, support],
      Return[<|"Status" -> "CompactLetterGradeSupportExceeded",
        "GradeSupport" -> support,
        "AdmissibleGradeSupport" -> admissible,
        "Path" -> "CompactLetterChannels"|>]]];
  path = If[MatchQ[channels, {_List, _List}], "CompactLetterChannels",
    channels = multiquadraticOffDiagonalBlockDecomposeScalarInterned[#1, roots] & /@ form;
    "DecomposedForm"];
  If[! ListQ[channels] || ! FreeQ[channels, $Failed], Return[$Failed]];
  compiled = Map[
    multiquadraticOffDiagonalBlockCompileRationalInterned[#1, variables, epsilon] &,
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
multiquadraticOffDiagonalBlockCompileShardTask[dataFile_String, indices_List] := Module[
  {payload, forms, records, roots, entries},
  payload = Quiet[CheckAbort[Get[dataFile], $Failed]];
  If[! AssociationQ[payload], Return[$Failed]];
  forms = Lookup[payload, "OneForms", $Failed];
  records = Lookup[payload, "LetterRecords", None];
  roots = Lookup[payload, "Roots", $Failed];
  If[! ListQ[forms] || ! ListQ[roots] ||
      ! VectorQ[indices, IntegerQ], Return[$Failed]];
  entries = Table[
    multiquadraticOffDiagonalBlockCompileOneFormEntry[forms[[index]],
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
multiquadraticOffDiagonalBlockLetterData[record_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[{rules},
  If[! AssociationQ[record], Return["NoLetterRecord"]];
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  {Lookup[record, "Kind", None],
    Lookup[record, "Letter", Missing["NoLetter"]] /. rules,
    Lookup[record, "OneForm", Missing["NoOneForm"]] /. rules}
];

multiquadraticOffDiagonalBlockCompileOneFormKey[prefix_, form_, record_, compactQ_,
    gradeSupport_, admissionMode_, variables : {_Symbol, _Symbol},
    epsilon_Symbol] := {prefix, form,
  If[TrueQ[compactQ], "CompactLetterChannels", "DecomposedForm"],
  multiquadraticOffDiagonalBlockLetterData[record, variables, epsilon],
  gradeSupport, admissionMode};

(* The ansatz half of the split: one interned entry per one-form, keyed
   on the chart symbols, the canonical roots, the form itself, the route
   and the letter provenance.  An exact-prefix alphabet extension
   therefore hits the pool on every old letter and compiles only the
   suffix. *)
multiquadraticOffDiagonalBlockCompileOneForms[oneForms_List, letterRecords_,
    roots_List, variables : {_Symbol, _Symbol}, epsilon_Symbol,
    compactQ_, shards_] :=
  multiquadraticOffDiagonalBlockCompileOneForms[oneForms, letterRecords, roots,
    variables, epsilon, compactQ, shards, Automatic, Automatic];

multiquadraticOffDiagonalBlockCompileOneForms[oneForms_List, letterRecords_,
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
    multiquadraticOffDiagonalBlockCompileOneFormKey[prefix, oneForms[[index]],
      records[[index]], compactQ, gradeSupport, admissionMode, variables,
      epsilon],
    {index, Length[oneForms]}];
  multiquadraticOffDiagonalBlockStageStart["compile: one-forms",
    <|"oneForms" -> Length[oneForms], "rank" -> Length[roots],
      "compact" -> TrueQ[compactQ], "shards" -> shards,
      "cached" -> Count[keys,
        key_ /; ! MissingQ[multiquadraticOffDiagonalBlockInternProbe["OneForm", key]]]|>];
  (* shard plan: only the one-forms the pool does NOT already hold, and
     only when a live broker and enough uncached work justify it *)
  shardCount = If[IntegerQ[shards] && shards >= 2 && shards <= 8, shards, 0];
  If[shardCount >= 2 && TrueQ[Quiet[taskBrokerActiveQ[]]] &&
      Quiet[Check[taskBrokerFreeKernels[], 0]] >= 1,
    pending = Select[Range[Length[oneForms]],
      MissingQ[multiquadraticOffDiagonalBlockInternProbe["OneForm", keys[[#1]]]] &];
    pending = DeleteDuplicatesBy[pending, keys[[#1]] &];
    If[Length[pending] >= $multiquadraticOffDiagonalBlockCompileShardMinimum,
      rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
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
          Table["FeynFacet`Private`multiquadraticOffDiagonalBlockCompileShardTask[\"" <>
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
                multiquadraticOffDiagonalBlockIntern["OneForm", keys[[index]],
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
      multiquadraticOffDiagonalBlockDeadlineCheckpoint["Compilation:OneForms",
        <|"Letter" -> index, "Of" -> Length[oneForms]|>];
      multiquadraticOffDiagonalBlockStageProgress["compile: one-forms",
        <|"letter" -> index, "of" -> Length[oneForms]|>];
      multiquadraticOffDiagonalBlockIntern["OneForm", key,
        Function[multiquadraticOffDiagonalBlockCompileOneFormEntry[form, record, roots,
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
   and Inhomogeneity is a coefficient in the basis {1, r_1, r_2, r_1 r_2, ...},
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
multiquadraticOffDiagonalBlockCompileCoreKeyFromParts[equationData_,
    rootCanonicalSquares_, rootCanonicalExpressions_, dimensions_] :=
  {equationData, rootCanonicalSquares, rootCanonicalExpressions, dimensions};

multiquadraticOffDiagonalBlockCompileCoreKey[preparation_Association,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {payload = Lookup[preparation, "DefiningData", $Failed]},
  If[! AssociationQ[payload], Return[$Failed]];
  If[AnyTrue[{"EquationCanonical", "RootCanonicalSquares",
      "RootCanonicalExpressions", "Dimensions"},
      ! KeyExistsQ[payload, #1] &], Return[$Failed]];
  multiquadraticOffDiagonalBlockCompileCoreKeyFromParts[
    payload["EquationCanonical"],
    payload["RootCanonicalSquares"], payload["RootCanonicalExpressions"],
    payload["Dimensions"]]
];

(* Takes the STRIP, not a preparation: prepare consumes this record too
   and has no preparation object yet when it does (2026-08-25).  The
   preparation-shaped call site in multiquadraticOffDiagonalBlockCompile passes
   preparation["Record"]["OffDiagonalBlockEquation"], so nothing it compiles changed. *)
multiquadraticOffDiagonalBlockCompileCoreRecord[offDiagonalBlockEquation_, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, reusedChannels_,
    coreKey_, useCacheQ_] := Module[{build},
  If[! MatchQ[offDiagonalBlockEquation, {_List, _List, _List}], Return[$Failed]];
  build[] := Module[
    {e, c, inhomogeneity, eData, cData, bData, rootSquares, rootSquareData,
     rootLogData},
    {e, c, inhomogeneity} = offDiagonalBlockEquation;
    eData = multiquadraticOffDiagonalBlockCompileTensorInterned[e, 3, roots, variables,
      epsilon, "compile core: E"];
    cData = multiquadraticOffDiagonalBlockCompileTensorInterned[c, 3, roots, variables,
      epsilon, "compile core: C"];
    bData = If[ArrayQ[reusedChannels, 4] &&
        Dimensions[reusedChannels] === Append[Dimensions[inhomogeneity],
          2^Length[roots]] && FreeQ[reusedChannels, $Failed],
      Module[{compiled = Map[
          multiquadraticOffDiagonalBlockCompileRationalInterned[#1, variables, epsilon] &,
          reusedChannels, {4}]},
        If[! FreeQ[compiled, $Failed], $Failed,
          <|"Channels" -> reusedChannels, "Compiled" -> compiled|>]],
      multiquadraticOffDiagonalBlockCompileTensorInterned[inhomogeneity, 3, roots, variables,
        epsilon, "compile core: Inhomogeneity"]];
    rootSquares = squareRootRecordRadicand /@ roots;
    rootSquareData = multiquadraticOffDiagonalBlockCompileTensorInterned[rootSquares, 1,
      {}, variables, epsilon];
    rootLogData = multiquadraticOffDiagonalBlockCompileTensorInterned[
      Table[D[rootSquares[[a]], variables[[mu]]]/rootSquares[[a]],
        {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
    If[MemberQ[{eData, cData, bData, rootSquareData, rootLogData}, $Failed],
      $Failed,
      <|"E" -> eData, "C" -> cData, "Inhomogeneity" -> bData,
        "RootSquares" -> rootSquareData, "RootLogDerivatives" -> rootLogData|>]];
  If[TrueQ[useCacheQ] && coreKey =!= $Failed,
    multiquadraticOffDiagonalBlockIntern["Core", coreKey, Function[build[]]],
    build[]]
];

(* The basis-transformation block denominator is neither core nor ansatz: an alphabet change
   moves it (the norms of the algebraic letters enter it), a support
   change does not.  It is two rational scalars and their two log
   derivatives, so it gets its own small keyed pool. *)
multiquadraticOffDiagonalBlockCompileDenominatorRecord[denominator_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, useCacheQ_] := Module[
  {build},
  build[] := Module[{denominatorData, denominatorLogData},
    denominatorData = multiquadraticOffDiagonalBlockCompileTensorInterned[{denominator},
      1, {}, variables, epsilon];
    denominatorLogData = multiquadraticOffDiagonalBlockCompileTensorInterned[
      {D[denominator, variables[[1]]]/denominator,
       D[denominator, variables[[2]]]/denominator}, 1, {}, variables, epsilon];
    If[MemberQ[{denominatorData, denominatorLogData}, $Failed], $Failed,
      <|"OffDiagonalBasisTransformationDenominator" -> denominatorData,
        "OffDiagonalBasisTransformationDenominatorLogDerivatives" -> denominatorLogData|>]];
  If[TrueQ[useCacheQ],
    multiquadraticOffDiagonalBlockIntern["OffDiagonalBasisTransformationDenominator",
      {variables, epsilon, denominator},
      Function[build[]]],
    build[]]
];

(* The pre-2026-08-25 compiler, kept callable.  "LegacyCompiler" -> True
   routes every part through multiquadraticOffDiagonalBlockCompileTensor exactly as
   before: no interning, no core cache, no compact letter channels, and
   the second Together that fed CoefficientRules.  It is the reference
   the equivalence test holds the new architecture to (compiled-assembly
   modular images at (prime, eps, point) triples), and a bisect handle;
   it is not a production route. *)
multiquadraticOffDiagonalBlockCompileLegacyCore[preparation_Association, roots_List,
    variables : {_Symbol, _Symbol}, epsilon_Symbol, reusedChannels_] := Module[
  {offDiagonalBlockEquation = Lookup[preparation, "Record", <||>]["OffDiagonalBlockEquation"], e, c, inhomogeneity, eData,
   cData, bData, rootSquares, rootSquareData, rootLogData},
  If[! MatchQ[offDiagonalBlockEquation, {_List, _List, _List}], Return[$Failed]];
  {e, c, inhomogeneity} = offDiagonalBlockEquation;
  eData = multiquadraticOffDiagonalBlockCompileTensor[e, 3, roots, variables, epsilon];
  cData = multiquadraticOffDiagonalBlockCompileTensor[c, 3, roots, variables, epsilon];
  bData = If[ArrayQ[reusedChannels, 4] &&
      Dimensions[reusedChannels] === Append[Dimensions[inhomogeneity],
        2^Length[roots]] && FreeQ[reusedChannels, $Failed],
    Module[{compiled = Map[
        multiquadraticOffDiagonalBlockCompileRational[#1, variables, epsilon] &,
        reusedChannels, {4}]},
      If[! FreeQ[compiled, $Failed], $Failed,
        <|"Channels" -> reusedChannels, "Compiled" -> compiled|>]],
    multiquadraticOffDiagonalBlockCompileTensor[inhomogeneity, 3, roots, variables, epsilon]];
  rootSquares = squareRootRecordRadicand /@ roots;
  rootSquareData = multiquadraticOffDiagonalBlockCompileTensor[rootSquares, 1, {},
    variables, epsilon];
  rootLogData = multiquadraticOffDiagonalBlockCompileTensor[
    Table[D[rootSquares[[a]], variables[[mu]]]/rootSquares[[a]],
      {a, Length[rootSquares]}, {mu, 2}], 2, {}, variables, epsilon];
  If[MemberQ[{eData, cData, bData, rootSquareData, rootLogData}, $Failed],
    $Failed,
    <|"E" -> eData, "C" -> cData, "Inhomogeneity" -> bData,
      "RootSquares" -> rootSquareData, "RootLogDerivatives" -> rootLogData|>]
];

multiquadraticOffDiagonalBlockCompileLegacyDenominator[denominator_,
    variables : {_Symbol, _Symbol}, epsilon_Symbol] := Module[
  {denominatorData, denominatorLogData},
  denominatorData = multiquadraticOffDiagonalBlockCompileTensor[{denominator}, 1, {},
    variables, epsilon];
  denominatorLogData = multiquadraticOffDiagonalBlockCompileTensor[
    {D[denominator, variables[[1]]]/denominator,
     D[denominator, variables[[2]]]/denominator}, 1, {}, variables, epsilon];
  If[MemberQ[{denominatorData, denominatorLogData}, $Failed], $Failed,
    <|"OffDiagonalBasisTransformationDenominator" -> denominatorData,
      "OffDiagonalBasisTransformationDenominatorLogDerivatives" -> denominatorLogData|>]
];

multiquadraticOffDiagonalBlockFormShape[expression_] := Which[
  AssociationQ[expression] && MemberQ[{"MultiquadraticRationalExactV1",
      "MultiquadraticRationalPrimeV1", "MultiquadraticRationalImageV1"},
    Lookup[expression, "Type", None]], "MultiquadraticRationalLeaf",
  AssociationQ[expression], Map[multiquadraticOffDiagonalBlockFormShape, expression],
  ListQ[expression], multiquadraticOffDiagonalBlockFormShape /@ expression,
  True, "Scalar"
];

(* "InhomogeneityChannels" lets the same-call producer reuse its expensive
   channel decomposition.  Its defining mathematical data are compared
   directly before reuse; the preparation itself is always validated.

   "CompileCore", "LetterChannels" and "CompileShards" are the 2026-08-25
   compile architecture.  All three default to Automatic and all three
   are then ON except sharding, which needs a live task broker AND an
   explicit shard count: naive parallelism duplicates work and peak
   memory, so it is last and opt-in.  "CompileCore" -> False and
   "LetterChannels" -> False restore the pre-2026-08-25 compiler exactly,
   which is what the equivalence test uses as its reference.

   ---- "CompileShards" IS A PRIVATE TEST CONTROL (decision 2026-08-25)

   It is NOT a production option and has no production caller.  It is
   absent from Options[solveOffDiagonalBasisTransformationBlockWithSquareRootGenerators] deliberately, so
   no public route can reach it, and the top-level option gate refuses
   it by name like any other unknown option.

   LEDGER NOTE.  What a production shard contract needs, and what does
   not exist yet: a strict result schema validated per shard (indices,
   entry count, per-entry shape) before anything is interned; a
   helper-leak guarantee (a helper that dies must not leave a claimed
   index uncompiled and unrecomputed); ABSOLUTE deadlines rather than
   the fixed 7200 s "Timeout" below; and a measured per-entry stage cost
   that shows sharding pays at all.  It has not been shown to pay on the
   one production shape measured.
   Production sharding waits for those measurements (Codex 14:30, shard
   row; agreed disposition).  Until then this option exists so the shard
   PATH stays exercised by its tests and does not rot, and the LEGACY
   compiler beside it is retained for the same reason and for no other:
   both are DIFFERENTIAL-TEST ORACLES, held to the current compiler by
   Tests/Multiquadratic/t_multiquadratic_prepare_core.wls, with no production caller. *)
Options[multiquadraticOffDiagonalBlockCompile] = {
  "InhomogeneityChannels" -> Automatic,
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

multiquadraticOffDiagonalBlockCompile[preparation_Association,
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
  gate = multiquadraticOffDiagonalBlockProductionOptionGate[{opts},
    Keys[Association[Options[multiquadraticOffDiagonalBlockCompile]]]];
  If[AssociationQ[gate], Return[gate]];
  (* a malformed request is a caller error and outranks a budget stop,
     exactly as in prepare and in the top-level driver *)
  deadline = OptionValue["Deadline"];
  If[! multiquadraticOffDiagonalBlockDeadlineQ[deadline],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidDeadline",
      <|"Deadline" -> deadline,
        "Expected" -> "an absolute AbsoluteTime[] value, or Infinity"|>]]];
  If[! multiquadraticOffDiagonalBlockPreparationValidQ[preparation],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPreparation"]]];
  variables = preparation["Variables"];
  epsilon = preparation["Regulator"];
  record = preparation["Record"];
  roots = preparation["Roots"];
  dimensions = preparation["Dimensions"];
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  legacyQ = TrueQ[OptionValue["LegacyCompiler"]];
  coreEnabled = Replace[OptionValue["CompileCore"], Automatic -> ! legacyQ];
  compactQ = Replace[OptionValue["LetterChannels"], Automatic -> ! legacyQ];
  shards = Replace[OptionValue["CompileShards"], Automatic -> 0];
  gradeSupport = Replace[OptionValue["LetterGradeSupport"],
    ell_List :> Sort[DeleteDuplicates[ell]]];
  admissionMode = Replace[OptionValue["CompactDLogAdmission"],
    Automatic -> "CertifiedOrExact"];
  poolByteLimit = Replace[OptionValue["PoolByteLimit"],
    Automatic :> $multiquadraticOffDiagonalBlockPoolByteLimit];
  poolEntryLimit = Replace[OptionValue["PoolEntryLimit"],
    Automatic :> $multiquadraticOffDiagonalBlockPoolEntryLimit];
  If[! AssociationQ[poolByteLimit] || ! AssociationQ[poolEntryLimit] ||
      ! AllTrue[Values[poolByteLimit], NumericQ[#1] && #1 > 0 &] ||
      ! AllTrue[Values[poolEntryLimit],
        #1 === Infinity || (IntegerQ[#1] && #1 > 0) &],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidCompilePoolCeiling",
      <|"PoolByteLimit" -> poolByteLimit,
        "PoolEntryLimit" -> poolEntryLimit|>]]];
  If[! MemberQ[{True, False}, coreEnabled] ||
      ! MemberQ[{True, False}, compactQ] ||
      ! (IntegerQ[shards] && 0 <= shards <= 8),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidCompileArchitectureOption",
      <|"CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
        "CompileShards" -> shards|>]]];
  If[! (gradeSupport === Automatic ||
      (VectorQ[gradeSupport, IntegerQ] && gradeSupport =!= {} &&
        AllTrue[gradeSupport, 0 <= #1 < preparation["GradeCount"] &])),
    Return[multiquadraticOffDiagonalBlockFailure["InvalidLetterGradeSupport",
      <|"LetterGradeSupport" -> gradeSupport,
        "GradeCount" -> preparation["GradeCount"]|>]]];
  If[! MemberQ[{"CertifiedOrExact", "Certified", "Exact"}, admissionMode],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidCompactDLogAdmission",
      <|"CompactDLogAdmission" -> admissionMode,
        "Expected" -> {Automatic, "Certified", "Exact"}|>]]];
  If[legacyQ && (coreEnabled || compactQ || shards =!= 0),
    Return[multiquadraticOffDiagonalBlockFailure["LegacyCompilerOptionConflict",
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
    "SupportSize" -> Length[Lookup[preparation, "OffDiagonalBasisTransformationNumeratorSupport", {}]],
    "Architecture" -> If[legacyQ, "Legacy", "CoreAnsatzSplitV1"]|>;
  compileBudget[substage_String, extra_Association : <||>] :=
    multiquadraticOffDiagonalBlockBudgetExhausted["Compilation:" <> substage,
      AbsoluteTime[] - startTime, deadline,
      Join[compileProgress[], extra]];
  compileGuard[substage_String] :=
    If[multiquadraticOffDiagonalBlockDeadlineExpiredQ[deadline],
      compileStop = compileBudget[substage]; True, False];
  If[compileGuard["Entry"], Return[compileStop]];
  (* the VALUE pools are per call at both ends: they make one call
     compile each unique value once and are never carried *)
  multiquadraticOffDiagonalBlockInternReset["Scalar"];
  multiquadraticOffDiagonalBlockInternReset["Rational"];
  (* a supplied decomposition is accepted only against its own seal
     (Codex 04:30 P2); an unsealed or mismatched one is refused typed,
     never re-derived silently and never installed.  Accepted channels
     flow into the compile core as the raw array; absence flows as
     Missing so the core derives them itself. *)
  reusedChannels = Module[
    {inhomogeneityLocal = Last[Lookup[record, "OffDiagonalBlockEquation", {$Failed, $Failed, $Failed}]],
     seal},
    seal = multiquadraticOffDiagonalBlockInhomogeneityChannelsAccept[
    OptionValue["InhomogeneityChannels"], inhomogeneityLocal, roots, variables, epsilon];
    Which[
      Lookup[seal, "Status", None] === "Accepted", seal["Channels"],
      Lookup[seal, "Status", None] === "NotSupplied",
        Missing["NotSupplied"],
      True, seal]];
  If[AssociationQ[reusedChannels],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[multiquadraticOffDiagonalBlockFailure[reusedChannels["Status"],
      KeyDrop[reusedChannels, "Status"]]]];
  coreKey = If[TrueQ[coreEnabled],
    multiquadraticOffDiagonalBlockCompileCoreKey[preparation, variables, epsilon],
    $Failed];
  (* one Block for the whole compile: the decomposition loops and the
     letter loop read the dynamic deadline and leave by Throw, and Block
     restores it on every exit path including the Throw.  Infinity is
     compared by SameQ before any clock is read, so the default performs
     exactly as no deadline at all. *)
  {coreSeconds, core} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticOffDiagonalBlockActiveDeadline = deadline,
        $multiquadraticOffDiagonalBlockPoolByteLimit = poolByteLimit,
        $multiquadraticOffDiagonalBlockPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticOffDiagonalBlockCompileLegacyCore[preparation, roots, variables,
            epsilon, reusedChannels],
          multiquadraticOffDiagonalBlockCompileCoreRecord[
            Lookup[record, "OffDiagonalBlockEquation", $Failed], roots, variables,
            epsilon, reusedChannels, coreKey, coreEnabled]]],
      $multiquadraticOffDiagonalBlockDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["Core",
          Join[<|"Substage" -> Lookup[load, "Substage", "Core"]|>,
            KeyDrop[load, "Substage"]]];
        $Failed]]];
  If[AssociationQ[compileStop],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[compileStop]];
  If[! AssociationQ[core],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[multiquadraticOffDiagonalBlockFailure["ExactChannelDecompositionFailed"]]];
  {eData, cData, bData, rootSquareData, rootLogData} =
    Lookup[core, {"E", "C", "Inhomogeneity", "RootSquares", "RootLogDerivatives"}];
  If[compileGuard["OneForms"],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[compileStop]];
  {oneFormSeconds, oneData} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticOffDiagonalBlockActiveDeadline = deadline,
        $multiquadraticOffDiagonalBlockPoolByteLimit = poolByteLimit,
        $multiquadraticOffDiagonalBlockPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticOffDiagonalBlockCompileTensor[preparation["OneForms"], 2, roots,
            variables, epsilon],
          multiquadraticOffDiagonalBlockCompileOneForms[preparation["OneForms"],
            Lookup[preparation, "LetterRecords", None], roots, variables,
            epsilon, compactQ, shards, gradeSupport, admissionMode]]],
      $multiquadraticOffDiagonalBlockDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["OneForms",
          Join[<|"Substage" -> Lookup[load, "Substage", "OneForms"]|>,
            KeyDrop[load, "Substage"]]];
        $Failed]]];
  (* pairs with the start emitted inside multiquadraticOffDiagonalBlockCompileOneForms:
     that function has typed early exits, this line does not *)
  If[! legacyQ,
    multiquadraticOffDiagonalBlockStageDone["compile: one-forms",
      <|"seconds" -> N[oneFormSeconds],
        "status" -> Which[AssociationQ[compileStop], "BudgetExhausted",
          AssociationQ[oneData] && ! KeyExistsQ[oneData, "Status"], "OK",
          AssociationQ[oneData], Lookup[oneData, "Status", "Failed"],
          True, "Failed"],
        "paths" -> If[AssociationQ[oneData],
          Counts[Replace[Lookup[oneData, "Paths", {}],
            Except[_List] -> {}]], <||>]|>]];
  If[AssociationQ[compileStop],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[compileStop]];
  (* the typed grade-gate refusal travels as itself: it names the letter
     and the mask that left the declared grade set *)
  If[AssociationQ[oneData] && KeyExistsQ[oneData, "Status"],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[multiquadraticOffDiagonalBlockFailure[oneData["Status"],
      KeyDrop[oneData, "Status"]]]];
  If[! AssociationQ[oneData],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[multiquadraticOffDiagonalBlockFailure["ExactChannelDecompositionFailed"]]];
  If[compileGuard["OffDiagonalBasisTransformationDenominator"],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[compileStop]];
  {denominatorSeconds, denominatorRecord} = AbsoluteTiming[
    Catch[
      Block[{$multiquadraticOffDiagonalBlockActiveDeadline = deadline,
        $multiquadraticOffDiagonalBlockPoolByteLimit = poolByteLimit,
        $multiquadraticOffDiagonalBlockPoolEntryLimit = poolEntryLimit},
        If[legacyQ,
          multiquadraticOffDiagonalBlockCompileLegacyDenominator[
            preparation["OffDiagonalBasisTransformationDenominator"], variables, epsilon],
          multiquadraticOffDiagonalBlockCompileDenominatorRecord[
            preparation["OffDiagonalBasisTransformationDenominator"], variables, epsilon,
            coreEnabled]]],
      $multiquadraticOffDiagonalBlockDeadlineTag,
      Function[{load, tag},
        compileStop = compileBudget["OffDiagonalBasisTransformationDenominator",
          Join[<|"Substage" -> Lookup[load, "Substage",
            "OffDiagonalBasisTransformationDenominator"]|>, KeyDrop[load, "Substage"]]];
        $Failed]]];
  If[AssociationQ[compileStop],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[compileStop]];
  If[! AssociationQ[denominatorRecord],
    multiquadraticOffDiagonalBlockInternReset["Scalar"];
    multiquadraticOffDiagonalBlockInternReset["Rational"];
    Return[multiquadraticOffDiagonalBlockFailure["RationalAssemblyFormCompilationFailed"]]];
  denominatorData = denominatorRecord["OffDiagonalBasisTransformationDenominator"];
  denominatorLogData = denominatorRecord["OffDiagonalBasisTransformationDenominatorLogDerivatives"];
  statistics = <|
    "Architecture" -> If[legacyQ, "Legacy", "CoreAnsatzSplitV1"],
    "CoreSeconds" -> coreSeconds, "OneFormSeconds" -> oneFormSeconds,
    "OffDiagonalBasisTransformationDenominatorSeconds" -> denominatorSeconds,
    "CompileCore" -> coreEnabled, "LetterChannels" -> compactQ,
    (* private test control, echoed here as telemetry only *)
    "CompileShards" -> shards,
    "LetterGradeSupport" -> gradeSupport,
    "CompactDLogAdmission" -> admissionMode,
    "OneFormPaths" -> Counts[Replace[Lookup[oneData, "Paths", {}],
      Except[_List] -> {}]],
    "CompactAdmissions" -> Counts[Replace[
      Lookup[oneData, "CompactAdmissions", {}], Except[_List] -> {}]],
    "Pools" -> multiquadraticOffDiagonalBlockInternStatistics[]|>;
  multiquadraticOffDiagonalBlockInternReset["Scalar"];
  multiquadraticOffDiagonalBlockInternReset["Rational"];
  exactForms = <|"E" -> eData["Channels"], "C" -> cData["Channels"],
    "Inhomogeneity" -> bData["Channels"], "OneForms" -> oneData["Channels"],
    "RootSquares" -> (First /@ rootSquareData["Channels"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Channels"], {2}],
    "OffDiagonalBasisTransformationDenominator" -> First[First[denominatorData["Channels"]]],
    "OffDiagonalBasisTransformationDenominatorLogDerivatives" -> First /@ denominatorLogData["Channels"]|>;
  compiledForms = <|"E" -> eData["Compiled"], "C" -> cData["Compiled"],
    "Inhomogeneity" -> bData["Compiled"], "OneForms" -> oneData["Compiled"],
    "RootSquares" -> (First /@ rootSquareData["Compiled"]),
    "RootLogDerivatives" -> Map[First, rootLogData["Compiled"], {2}],
    "OffDiagonalBasisTransformationDenominator" -> First[First[denominatorData["Compiled"]]],
    "OffDiagonalBasisTransformationDenominatorLogDerivatives" -> First /@ denominatorLogData["Compiled"]|>;
  If[! FreeQ[compiledForms, $Failed],
    Return[multiquadraticOffDiagonalBlockFailure["CompiledAssemblyFormsInvalid"]]];
  result = <|
    "Status" -> "CompiledMultiquadraticOffDiagonalBlockV1",
    "Preparation" -> preparation,
    "Record" -> record, "Roots" -> roots,
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Variables" -> variables, "Regulator" -> epsilon,
    "Dimensions" -> dimensions,
    "OffDiagonalBasisTransformationNumeratorSupport" -> preparation["OffDiagonalBasisTransformationNumeratorSupport"],
    "OneForms" -> preparation["OneForms"],
    "OffDiagonalBasisTransformationDenominator" -> preparation["OffDiagonalBasisTransformationDenominator"],
    "Normalizations" -> preparation["Normalizations"],
    "OffDiagonalBasisTransformationUnknownCount" -> preparation["OffDiagonalBasisTransformationUnknownCount"],
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
multiquadraticOffDiagonalBlockCompile[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidCompileArguments"];

multiquadraticOffDiagonalBlockCompiledValidQ[assembly_Association] := Module[
  {dimensions, rootCount, gradeCount, support, expectedBasisTransformationBlock, expectedResidue,
   requiredKeys, preparation},
  If[Lookup[assembly, "Status", None] =!= "CompiledMultiquadraticOffDiagonalBlockV1",
    Return[False]];
  requiredKeys = {"Preparation", "Record", "Roots",
    "RootCount", "GradeCount", "Variables", "Regulator", "Dimensions",
    "OffDiagonalBasisTransformationNumeratorSupport", "OneForms", "OffDiagonalBasisTransformationDenominator", "Normalizations",
    "OffDiagonalBasisTransformationUnknownCount", "ResidueUnknownCount", "UnknownCount",
    "EquationsPerPoint", "ColumnOrder", "RowOrder", "ExactChannelForms",
    "CompiledForms"};
  If[! AllTrue[requiredKeys, KeyExistsQ[assembly, #1] &], Return[False]];
  dimensions = assembly["Dimensions"];
  rootCount = assembly["RootCount"];
  gradeCount = assembly["GradeCount"];
  support = assembly["OffDiagonalBasisTransformationNumeratorSupport"];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || ! IntegerQ[rootCount] ||
      ! (0 <= rootCount <= $multiquadraticOffDiagonalBlockMaximumRootCount) ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {}, Return[False]];
  expectedBasisTransformationBlock = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[assembly["OneForms"]] Times @@ dimensions;
  preparation = assembly["Preparation"];
  TrueQ[
    multiquadraticOffDiagonalBlockPreparationValidQ[preparation] &&
    SameQ[assembly["Record"], preparation["Record"]] &&
    SameQ[assembly["Roots"], preparation["Roots"]] &&
    assembly["OffDiagonalBasisTransformationUnknownCount"] === expectedBasisTransformationBlock &&
    assembly["ResidueUnknownCount"] === expectedResidue &&
    assembly["UnknownCount"] === expectedBasisTransformationBlock + expectedResidue &&
    assembly["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    assembly["ColumnOrder"] === multiquadraticOffDiagonalBlockColumnOrder[dimensions,
      gradeCount, support, Length[assembly["OneForms"]]] &&
    assembly["RowOrder"] === multiquadraticOffDiagonalBlockRowOrder[dimensions, gradeCount] &&
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
multiquadraticOffDiagonalBlockCoefficientData[
    variables : {_Symbol, _Symbol}, epsilon_Symbol, roots_List,
    dimensions : {_Integer, _Integer}, oneForms_List,
    offDiagonalBasisTransformationDenominator_] := Module[
  {rules, rootSquares, rootExpressions, canonicalSquares,
   canonicalExpressions, canonicalForms, canonicalDenominator},
  If[Min[dimensions] < 1 ||
      ! AllTrue[roots, AssociationQ[#1] &&
        squareRootRecordExpression[#1] =!= $Failed &&
        squareRootRecordRadicand[#1] =!= $Failed &&
        TrueQ[Together[squareRootRecordExpression[#1]^2 -
          squareRootRecordRadicand[#1]] === 0] &] ||
      ! MatchQ[oneForms, {} | {{_, _} ..}], Return[$Failed]];
  rules = multiquadraticOffDiagonalBlockCanonicalRules[variables, epsilon];
  rootSquares = squareRootRecordRadicand /@ roots;
  rootExpressions = squareRootRecordExpression /@ roots;
  canonicalSquares = multiquadraticOffDiagonalBlockCanonicalExpression[#1, rules] & /@
    rootSquares;
  canonicalExpressions = multiquadraticOffDiagonalBlockCanonicalExpression[#1, rules] & /@
    rootExpressions;
  canonicalForms = Map[multiquadraticOffDiagonalBlockCanonicalExpression[#1, rules] &,
    oneForms, {2}];
  canonicalDenominator = multiquadraticOffDiagonalBlockCanonicalExpression[
    offDiagonalBasisTransformationDenominator, rules];
  If[! FreeQ[{canonicalSquares, canonicalExpressions, canonicalForms,
      canonicalDenominator}, $Failed], Return[$Failed]];
  <|"Schema" -> "MultiquadraticCoefficientDataV2",
    "Dimensions" -> dimensions,
    "RootSquares" -> canonicalSquares,
    "RootExpressions" -> canonicalExpressions,
    "OneForms" -> canonicalForms,
    "OffDiagonalBasisTransformationDenominator" -> canonicalDenominator|>
];
multiquadraticOffDiagonalBlockCoefficientData[___] := $Failed;

(* The layout owns columns, rows and normalizations, but no coefficient
   source.  In particular it does not claim that characteristic-zero
   channels were compiled. *)
multiquadraticOffDiagonalBlockAssemblyLayout[preparation_Association] := Module[
  {coefficientData},
  If[! multiquadraticOffDiagonalBlockPreparationValidQ[preparation],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidPreparation"]]];
  coefficientData = multiquadraticOffDiagonalBlockCoefficientData[
    preparation["Variables"], preparation["Regulator"],
    preparation["Roots"], preparation["Dimensions"],
    preparation["OneForms"], preparation["OffDiagonalBasisTransformationDenominator"]];
  If[coefficientData === $Failed,
    Return[multiquadraticOffDiagonalBlockFailure["CoefficientDataConstructionFailed"]]];
  <|
    "Status" -> "MultiquadraticOffDiagonalBlockAssemblyLayoutV1",
    "Preparation" -> preparation,
    "Record" -> preparation["Record"], "Roots" -> preparation["Roots"],
    "RootCount" -> preparation["RootCount"],
    "GradeCount" -> preparation["GradeCount"],
    "Variables" -> preparation["Variables"],
    "Regulator" -> preparation["Regulator"],
    "Dimensions" -> preparation["Dimensions"],
    "OffDiagonalBasisTransformationNumeratorSupport" -> preparation["OffDiagonalBasisTransformationNumeratorSupport"],
    "OneForms" -> preparation["OneForms"],
    "OffDiagonalBasisTransformationDenominator" -> preparation["OffDiagonalBasisTransformationDenominator"],
    "Normalizations" -> preparation["Normalizations"],
    "OffDiagonalBasisTransformationUnknownCount" -> preparation["OffDiagonalBasisTransformationUnknownCount"],
    "ResidueUnknownCount" -> preparation["ResidueUnknownCount"],
    "UnknownCount" -> preparation["UnknownCount"],
    "EquationsPerPoint" -> preparation["EquationsPerPoint"],
    "ColumnOrder" -> preparation["ColumnOrder"],
    "RowOrder" -> preparation["RowOrder"],
    "CoefficientData" -> coefficientData|>
];
multiquadraticOffDiagonalBlockAssemblyLayout[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidAssemblyLayoutArguments"];

multiquadraticOffDiagonalBlockAssemblyLayoutValidQ[layout_Association] := Module[
  {dimensions, rootCount, gradeCount, support, oneForms, expectedBasisTransformationBlock,
   expectedResidue, coefficientData, preparation},
  If[Lookup[layout, "Status", None] =!=
      "MultiquadraticOffDiagonalBlockAssemblyLayoutV1", Return[False]];
  dimensions = Lookup[layout, "Dimensions", $Failed];
  rootCount = Lookup[layout, "RootCount", $Failed];
  gradeCount = Lookup[layout, "GradeCount", $Failed];
  support = Lookup[layout, "OffDiagonalBasisTransformationNumeratorSupport", $Failed];
  oneForms = Lookup[layout, "OneForms", $Failed];
  If[! MatchQ[dimensions, {_Integer, _Integer}] || Min[dimensions] < 1 ||
      ! IntegerQ[rootCount] || rootCount < 0 ||
      rootCount > $multiquadraticOffDiagonalBlockMaximumRootCount ||
      ! IntegerQ[gradeCount] || gradeCount =!= 2^rootCount ||
      ! ListQ[support] || support === {} ||
      ! MatchQ[oneForms, {} | {{_, _} ..}], Return[False]];
  expectedBasisTransformationBlock = Times @@ dimensions gradeCount Length[support];
  expectedResidue = Length[oneForms] Times @@ dimensions;
  coefficientData = multiquadraticOffDiagonalBlockCoefficientData[
    layout["Variables"], layout["Regulator"], layout["Roots"], dimensions,
    oneForms, layout["OffDiagonalBasisTransformationDenominator"]];
  If[coefficientData === $Failed, Return[False]];
  preparation = Lookup[layout, "Preparation", $Failed];
  TrueQ[
    AssociationQ[preparation] &&
    multiquadraticOffDiagonalBlockPreparationValidQ[preparation] &&
    Lookup[layout, "CoefficientData", None] === coefficientData &&
    layout["OffDiagonalBasisTransformationUnknownCount"] === expectedBasisTransformationBlock &&
    layout["ResidueUnknownCount"] === expectedResidue &&
    layout["UnknownCount"] === expectedBasisTransformationBlock + expectedResidue &&
    layout["EquationsPerPoint"] === gradeCount 2 Times @@ dimensions &&
    layout["ColumnOrder"] === multiquadraticOffDiagonalBlockColumnOrder[dimensions,
      gradeCount, support, Length[oneForms]] &&
    layout["RowOrder"] === multiquadraticOffDiagonalBlockRowOrder[dimensions,
      gradeCount]]
];
multiquadraticOffDiagonalBlockAssemblyLayoutValidQ[___] := False;

multiquadraticOffDiagonalBlockAssemblyLayoutHotValidQ[layout_Association] := TrueQ[
  Lookup[layout, "Status", None] ===
    "MultiquadraticOffDiagonalBlockAssemblyLayoutV1" &&
  MatchQ[Lookup[layout, "Dimensions", None], {_Integer, _Integer}] &&
  Min[layout["Dimensions"]] >= 1 &&
  IntegerQ[Lookup[layout, "RootCount", None]] && layout["RootCount"] >= 0 &&
  Lookup[layout, "GradeCount", None] === 2^layout["RootCount"] &&
  IntegerQ[Lookup[layout, "UnknownCount", None]] &&
  layout["UnknownCount"] >= 0];
multiquadraticOffDiagonalBlockAssemblyLayoutHotValidQ[___] := False;

multiquadraticOffDiagonalBlockAssemblyLayoutEvaluationValidQ[layout_] :=
  multiquadraticOffDiagonalBlockAssemblyLayoutHotValidQ[layout];

(* A compiled-channel provider is an authenticated compatibility wrapper;
   it remains the characteristic-zero differential oracle, not a second
   row assembler. *)
multiquadraticOffDiagonalBlockCompiledProvider[assembly_Association] := Module[
  {preparation, layout, result},
  If[! multiquadraticOffDiagonalBlockCompiledValidQ[assembly],
    Return[multiquadraticOffDiagonalBlockFailure["InvalidCompiledAssembly"]]];
  preparation = Lookup[assembly, "Preparation", $Failed];
  layout = multiquadraticOffDiagonalBlockAssemblyLayout[preparation];
  If[! multiquadraticOffDiagonalBlockAssemblyLayoutValidQ[layout], Return[layout]];
  result = <|"Status" -> "MultiquadraticCoefficientProviderV1",
    "Kind" -> "CompiledChannel", "Assembly" -> assembly,
    "CoefficientData" -> layout["CoefficientData"],
    "RootCount" -> layout["RootCount"],
    "GradeCount" -> layout["GradeCount"],
    "Dimensions" -> layout["Dimensions"]|>;
  result
];
multiquadraticOffDiagonalBlockCompiledProvider[___] :=
  multiquadraticOffDiagonalBlockFailure["InvalidCompiledProviderArguments"];

End[];
