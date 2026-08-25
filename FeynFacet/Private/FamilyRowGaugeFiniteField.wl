(* VALIDATION PROTOTYPE (decision F3, Design/GeneralityFixes2.md,
   2026-08-24): NOT in $feynFacetPrivateFiles, not loaded by the package,
   no production caller.  Consumed by tests via explicit Get as the
   row-level finite-field oracle; its algebra delegates to
   MultiquadraticAlgebra.wl.  Revisit when a recapture driver needs a
   production row oracle. *)
(* Finite-field oracle for one completed off-diagonal block row.

   This prototype deliberately is not loaded by FeynFacet.m.  It is the
   sampling half of the algebraic row-gauge path: preparation records the
   exact sparse terms in

     A' = A + A D - D A - dD,
     S' = S + S D,             S'^-1 = S^-1 - D S^-1,

   and a sample evaluates only those terms.  Declared square roots are
   put in one canonical order.  At a split point all 2^r sign conjugates
   are evaluated, projected to the square-root basis by a Hadamard
   transform, and recomposed as an internal oracle.

   No Together is used by the modular evaluator.  In particular, dD is
   differentiated exactly once during preparation and then evaluated as
   an ordinary tagged term at every modular point.

   THE MULTIQUADRATIC ALGEBRA IS NOT IMPLEMENTED HERE (2026-08-23).
   Every grade, character-table, root-product, conjugate-projection,
   square-class and root-ordering operation is one call into the neutral
   ABI -- MultiquadraticAlgebra.wl and the canonical-text / square-class
   helpers of MultiquadraticStripSolve.wl, both registered in
   FeynFacet.m.  This file owns only the ROW ORACLE: sparse support, the
   tagged term records, the recursive modular evaluator, the
   fingerprints, and the typed failures.  The duplicated copies that
   lived here until 2026-08-23 are deleted and are explicitly ClearAll'ed
   below, so that a re-Get in a session which loaded the old file cannot
   leave a second implementation behind.

   Three consequences of that deletion, all measured by
   Tests/t_multiquadratic_algebra_differential.wls (which was the
   agreement gate before the deletion and is the delegation gate after
   it):

     - ROOT ORDER.  The order is now the neutral one: the canonical
       InputForm text of the root square with the chart variables mapped
       to formal System` symbols.  The deleted key was the printed text
       of the root square in the CALLER's symbols, and it never reached
       FullForm at all -- ToString[FullForm[Unevaluated[expr]], InputForm]
       returns the text "FullForm[Unevaluated[<expr as the reader prints
       it>]]", so the key changed with $Context/$ContextPath (pool defect
       3).  Grade masks therefore relabel: {x, y, x + y} used to order as
       {x, x + y, y} and now orders as {x + y, x, y}.  Admissible only
       because this file is unregistered and no shipped artifact is keyed
       to its order.  The fingerprint payloads are the canonical texts
       for the same reason, and their version tags are bumped to V2.

     - SIGN REPRESENTATIVE.  multiquadraticSquareRoots returns the raw
       PowerMod value; this oracle's sign ABI is the SMALLER of the two
       roots, so the normalization Min[r, p - r] is applied here, once,
       at the consumer boundary in familyRowGaugeFFSquareRoot.

     - The neutral ABI declares a modular square root only for
       p == 3 (mod 4).  familyRowGaugeFFTonelliShanks stays in this
       layer for p == 1 (mod 4); it is the one algebra primitive still
       implemented here, and it is not a duplicate of anything.

   The split-point test is deliberately NOT delegated to
   multiquadraticSplitPointQ: that predicate substitutes into the raw
   radicands and reduces with Mod, which is the rational remainder rather
   than the field image on rational coefficients, and it returns one
   boolean where this layer must distinguish a ramified point from a
   non-split one.  The radicands are evaluated here through the same
   modular evaluator as every other term. *)

Begin["FeynFacet`Private`"];

ClearAll[
  familyRowGaugeFiniteFieldPrepare,
  familyRowGaugeFiniteFieldEvaluate,
  familyRowGaugeFiniteFieldOracle,
  familyRowGaugeFFSupport,
  familyRowGaugeFFSymbolKey,
  familyRowGaugeFFZeroQ,
  familyRowGaugeFFCanonicalRules,
  familyRowGaugeFFCanonicalKey,
  familyRowGaugeFFCanonicalizeRoots,
  familyRowGaugeFFReplaceRoots,
  familyRowGaugeFFRoot,
  familyRowGaugeFFFieldFingerprint,
  familyRowGaugeFFPreparationFingerprint,
  familyRowGaugeFFCoefficientDenominators,
  familyRowGaugeFFModEvaluate,
  familyRowGaugeFFTonelliShanks,
  familyRowGaugeFFSquareRoot
];

(* Retired duplicates of the neutral ABI (deleted 2026-08-23).  Cleared,
   not merely removed, so that re-reading this file in a kernel that
   loaded the pre-deletion version leaves no second implementation:

     familyRowGaugeFFStableKey            -> multiquadraticStripCanonicalText
                                             (and familyRowGaugeFFSymbolKey
                                             for symbol sort keys)
     familyRowGaugeFFEquivalentQ          -> multiquadraticStripZeroQ
     familyRowGaugeFFRadicalBases         -> transportChartRadicalBases
     familyRowGaugeFFUniqueEquivalent     -> DeleteDuplicates + the above
     familyRowGaugeFFRationalSquareConstantQ
                                          -> multiquadraticStripRationalSquareQ
     familyRowGaugeFFRationalFunctionSquareQ
                                          -> multiquadraticStripSquareClassSquareQ
     familyRowGaugeFFHadamard             -> multiquadraticHadamardMatrix
     familyRowGaugeFFRootProducts         -> multiquadraticMaskFactor
     familyRowGaugeFFProjectConjugates    -> multiquadraticProjectConjugates
                                             + multiquadraticEvaluateConjugates
     familyRowGaugeFFUnresolvedRoot       -> a leftover fractional power,
                                             detected structurally *)
ClearAll[
  familyRowGaugeFFStableKey,
  familyRowGaugeFFEquivalentQ,
  familyRowGaugeFFRadicalBases,
  familyRowGaugeFFUniqueEquivalent,
  familyRowGaugeFFRationalSquareConstantQ,
  familyRowGaugeFFRationalFunctionSquareQ,
  familyRowGaugeFFHadamard,
  familyRowGaugeFFRootProducts,
  familyRowGaugeFFProjectConjugates,
  familyRowGaugeFFUnresolvedRoot
];

familyRowGaugeFFSupport[entries_List] :=
  Flatten[Position[entries, Except[0], {1}, Heads -> False]];

(* A symbol sort key that carries its context explicitly: unlike printed
   text it does not change with the reader's $ContextPath. *)
familyRowGaugeFFSymbolKey[symbol_Symbol] :=
  {Context[symbol], SymbolName[symbol]};

familyRowGaugeFFZeroQ[value_] := TrueQ[Quiet[multiquadraticStripZeroQ[value]]];

(* The canonical text of a root square, in formal System` symbols, is the
   root sort key and the fingerprint payload.  The regulator slot of
   multiquadraticStripCanonicalRules is filled with the formal regulator
   itself: root squares are regulator-free here (a root square carrying
   any non-chart symbol is refused as NonKinematicRootSquare), so the
   rule is inert, and using the neutral rule builder keeps the variable
   images -- and therefore the order -- identical to
   multiquadraticStripRootOrder's. *)
familyRowGaugeFFCanonicalRules[variables : {_Symbol, _Symbol}] :=
  multiquadraticStripCanonicalRules[variables, \[FormalE]];

familyRowGaugeFFCanonicalKey[expression_, rules_List] :=
  multiquadraticStripCanonicalText[expression, rules];

(* The root order is an ABI: mask bit i always denotes canonical root i.
   Normalize the squares before sorting, and reject duplicate or
   square-class dependent extensions rather than assigning two sign bits
   to the same quadratic generator.  Both screens are the neutral ones;
   the declared (pre-sort) indices are reported, as before. *)
familyRowGaugeFFCanonicalizeRoots[declaredRoots_, variables_List] := Module[
  {rules, standardized, root, square, radicals, fractional, squareSymbols,
   extraSymbols, canonical, duplicate, dependent,
   failureTag = Unique["familyRowGaugeFFRootValidation"]},
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      SameQ[variables[[1]], variables[[2]]],
    Return[<|"Status" -> "InvalidVariables"|>]];
  If[! ListQ[declaredRoots],
    Return[<|"Status" -> "InvalidRootDeclarations"|>]];
  If[Length[declaredRoots] > 3,
    Return[<|"Status" -> "UnsupportedRootRank",
      "MaximumRank" -> 3, "ActualRank" -> Length[declaredRoots]|>]];
  If[! AllTrue[declaredRoots, AssociationQ[#] &&
      KeyExistsQ[#, "Root"] && KeyExistsQ[#, "RootSquare"] &],
    Return[<|"Status" -> "InvalidRootDeclarations"|>]];
  rules = familyRowGaugeFFCanonicalRules[variables];
  standardized = Catch[Table[
    root = declaredRoots[[index, "Root"]];
    square = Quiet[Check[Together[
      declaredRoots[[index, "RootSquare"]]], $Failed]];
    If[square === $Failed,
      Throw[<|"Status" -> "InvalidRootSquare",
        "RootIndex" -> index|>, failureTag]];
    fractional = Cases[square,
      Power[_, exponent_Rational /; Denominator[exponent] =!= 1],
      {0, Infinity}, Heads -> True];
    If[fractional =!= {},
      Throw[<|"Status" -> "AlgebraicRootSquare",
        "RootIndex" -> index|>, failureTag]];
    squareSymbols = DeleteDuplicates[Cases[square,
      symbol_Symbol /; Context[symbol] =!= "System`" :> symbol,
      {0, Infinity}, Heads -> True]];
    extraSymbols = Complement[squareSymbols, variables,
      SameTest -> SameQ];
    If[extraSymbols =!= {},
      Throw[<|"Status" -> "NonKinematicRootSquare",
        "RootIndex" -> index, "Symbols" -> extraSymbols|>,
        failureTag]];
    radicals = DeleteDuplicates[transportChartRadicalBases[root],
      familyRowGaugeFFZeroQ[#1 - #2] &];
    If[Length[radicals] =!= 1 ||
        ! familyRowGaugeFFZeroQ[First[radicals] - square] ||
        ! familyRowGaugeFFZeroQ[root^2 - square],
      Throw[<|"Status" -> "InconsistentRootDeclaration",
        "RootIndex" -> index|>, failureTag]];
    canonical = familyRowGaugeFFCanonicalKey[square, rules];
    If[! StringQ[canonical],
      Throw[<|"Status" -> "NonCanonicalRootSquare",
        "RootIndex" -> index|>, failureTag]];
    <|"Root" -> root, "RootSquare" -> square,
      "CanonicalRootSquare" -> canonical,
      "RootFingerprint" -> Hash[canonical, "SHA256", "HexString"]|>,
    {index, Length[declaredRoots]}], failureTag, #1 &];
  If[AssociationQ[standardized], Return[standardized]];
  duplicate = FirstCase[
    Subsets[Range[Length[standardized]], {2}],
    {left_, right_} /; familyRowGaugeFFZeroQ[
      standardized[[left, "RootSquare"]] -
        standardized[[right, "RootSquare"]]] :> {left, right}, None];
  If[duplicate =!= None,
    Return[<|"Status" -> "DuplicateRootSquare",
      "RootIndices" -> duplicate|>]];
  (* 2^r independent sign automorphisms need r independent square
     classes; distinct radicands are not enough ({x, y, x y} has rank
     two).  The neutral screen decides. *)
  dependent = FirstCase[Rest[Subsets[Range[Length[standardized]]]],
    indices_ /; TrueQ[multiquadraticStripSquareClassSquareQ[
      Times @@ standardized[[indices, "RootSquare"]]]] :> indices, None];
  If[dependent =!= None,
    Return[<|"Status" -> "DependentRootSquares",
      "RootIndices" -> dependent|>]];
  standardized = SortBy[standardized,
    {#1["CanonicalRootSquare"], #1["RootFingerprint"]} &];
  <|"Status" -> "OK", "Roots" -> standardized|>
];

(* Declared half-powers become root placeholders through the package's
   own root substitution.  An UNDECLARED radical is left as a fractional
   power by transportChartApplyRootBranches and is detected structurally
   after compilation. *)
familyRowGaugeFFReplaceRoots[expression_, roots_List] :=
  transportChartApplyRootBranches[expression, roots,
    Table[familyRowGaugeFFRoot[index], {index, Length[roots]}]];

familyRowGaugeFFFieldFingerprint[variables_List, roots_List] := Hash[
  {"FamilyRowGaugeFiniteFieldV2", familyRowGaugeFFSymbolKey /@ variables,
    Lookup[roots, "CanonicalRootSquare", {}]}, "SHA256", "HexString"];

familyRowGaugeFFPreparationFingerprint[variables_List, roots_List,
    parameters_List, rowIndices_List, dimensions_List,
    records_Association] := Hash[
  {"FamilyRowGaugeFiniteFieldPreparationV2",
    familyRowGaugeFFSymbolKey /@ variables,
    Lookup[roots, "CanonicalRootSquare", {}],
    familyRowGaugeFFSymbolKey /@ parameters,
    rowIndices, dimensions,
    Table[{kind,
      ({#1["Target"],
          ({#1["Kind"], #1["Expression"]} & /@ #1["Terms"])} &) /@
        Lookup[records, kind, {}]},
      {kind, {"Connection", "Transformation", "Inverse"}}]},
  "SHA256", "HexString"];

familyRowGaugeFFCoefficientDenominators[expression_] :=
  DeleteDuplicates[Cases[expression,
    Rational[_, denominator_Integer] :> denominator,
    {0, Infinity}, Heads -> True]];

familyRowGaugeFiniteFieldPrepare[
    connection_, transformation_, inverse_, rowIndices_, gauge_,
    variables_, declaredRoots_] := Module[
  {started = AbsoluteTime[], validSquare, n, start, stop,
   lowerColumns, futureRows, rowSize, lowerSize, rootResult, roots,
   rootSquares, rawExpressions, classification, unknownRadicals,
   unsupportedPowers, parameters, parameterExpressions,
   gaugeRowSupport, gaugeColumnSupport, derivatives,
   aProducts = 0, sProducts = 0, siProducts = 0,
   derivativeTerms = 0, aRight, aLower, aRightRowSupport,
   aLowerColumnSupport, supportAD, supportDA, correctionTerms,
   correctionExpressions, base, leftS, leftSRowSupport, supportS,
   rightInverse, rightInverseColumnSupport, supportSi,
   aHarvest, sHarvest, siHarvest, aRecords, sRecords, siRecords,
   tagged, compileRecord, records, dimensions, fieldFingerprint,
   fingerprint, denominators, mu, i, j},

  validSquare[m_] := MatrixQ[m] && Length[m] > 0 &&
    Dimensions[m] === {Length[m], Length[m]};
  If[! MatchQ[connection, {_List, _List}] ||
      ! (validSquare /@ connection === {True, True}) ||
      Dimensions[connection[[1]]] =!= Dimensions[connection[[2]]] ||
      ! validSquare[transformation] || ! validSquare[inverse] ||
      Dimensions[transformation] =!= Dimensions[connection[[1]]] ||
      Dimensions[inverse] =!= Dimensions[connection[[1]]],
    Return[<|"Status" -> "InvalidDimensions",
      "Reason" -> "connection, transformation, and inverse must have one common square dimension"|>]];
  If[! MatchQ[variables, {_Symbol, _Symbol}] ||
      SameQ[variables[[1]], variables[[2]]],
    Return[<|"Status" -> "InvalidVariables"|>]];

  n = Length[transformation];
  If[rowIndices === {} || ! VectorQ[rowIndices, IntegerQ] ||
      rowIndices =!= Range[First[rowIndices], Last[rowIndices]] ||
      First[rowIndices] <= 1 || Last[rowIndices] > n,
    Return[<|"Status" -> "InvalidRowBlock",
      "Reason" -> "row indices must be a nonempty consecutive block after the first row"|>]];
  {start, stop} = {First[rowIndices], Last[rowIndices]};
  lowerColumns = Range[start - 1];
  futureRows = Range[start, n];
  rowSize = Length[rowIndices]; lowerSize = Length[lowerColumns];
  If[! MatrixQ[gauge] || Dimensions[gauge] =!= {rowSize, lowerSize},
    Return[<|"Status" -> "InvalidGaugeDimensions",
      "Expected" -> {rowSize, lowerSize},
      "Actual" -> Quiet[Check[Dimensions[gauge],
        Missing["NotAMatrix"]]]|>]];
  If[! AllTrue[Flatten[connection[[All, lowerColumns, rowIndices]]],
      SameQ[#, 0] &],
    Return[<|"Status" -> "InvalidBlockStructure",
      "Reason" -> "A[[lower columns, row block]] is not structurally zero; D.A.D may be nonzero"|>]];

  rootResult = familyRowGaugeFFCanonicalizeRoots[declaredRoots, variables];
  If[rootResult["Status"] =!= "OK", Return[rootResult]];
  roots = rootResult["Roots"];
  rootSquares = Lookup[roots, "RootSquare", {}];

  (* Exact differentiation is paid once.  These matrices are also part
     of radical validation, so a derivative cannot silently leave the
     declared multiquadratic field. *)
  derivatives = D[gauge, #] & /@ variables;
  rawExpressions = Flatten[{connection, transformation, inverse, gauge,
    derivatives, rootSquares}];
  unsupportedPowers = Cases[rawExpressions,
    Power[_, exponent_Rational /; Denominator[exponent] =!= 1 &&
      Denominator[exponent] =!= 2], {0, Infinity}, Heads -> True];
  If[unsupportedPowers =!= {},
    Return[<|"Status" -> "UnsupportedAlgebraicPower",
      "Count" -> Length[unsupportedPowers]|>]];
  (* the package classifier, level 1 and Heads -> False since 2026-08-23 *)
  classification = transportChartRootIndices[rawExpressions, roots];
  unknownRadicals = DeleteDuplicates[
    Lookup[classification, "UnclassifiedRadicalBases", {}]];
  If[unknownRadicals =!= {},
    Return[<|"Status" -> "UnknownRadicals",
      "RadicalBases" -> unknownRadicals|>]];
  (* 2026-08-24: the classifier now accepts nested and numeric radicands
     by exact denesting (transportChartDenestRadicalBase).  This solver
     samples the declared roots channel by channel over a rational
     coefficient field; a rewritten nested radical or a numeric radical
     constant has never been carried through it, so such an input is
     refused here instead of being sampled on an untested path. *)
  If[Lookup[classification, "DenestedRadicalBases", <||>] =!= <||>,
    Return[<|"Status" -> "DenestedRadicalsNotSupported",
      "RadicalBases" -> Keys[classification["DenestedRadicalBases"]],
      "NumericRadicalClasses" ->
        Lookup[classification, "NumericRadicalClasses", {}]|>]];

  gaugeRowSupport = familyRowGaugeFFSupport /@ gauge;
  gaugeColumnSupport = familyRowGaugeFFSupport /@ Transpose[gauge];
  tagged[kind_, expression_] :=
    <|"Kind" -> kind, "Expression" -> expression|>;

  aHarvest = Reap[
    Do[
      aRight = connection[[mu, futureRows, rowIndices]];
      aLower = connection[[mu, lowerColumns, lowerColumns]];
      aRightRowSupport = familyRowGaugeFFSupport /@ aRight;
      aLowerColumnSupport = familyRowGaugeFFSupport /@ Transpose[aLower];
      Do[
        supportAD = Intersection[
          aRightRowSupport[[i]], gaugeColumnSupport[[j]]];
        supportDA = If[i <= rowSize,
          Intersection[gaugeRowSupport[[i]],
            aLowerColumnSupport[[j]]], {}];
        aProducts += Length[supportAD] + Length[supportDA];
        correctionTerms = Join[
          (tagged["AD", aRight[[i, #]] gauge[[#, j]]] &) /@
            supportAD,
          If[i <= rowSize,
            Join[(tagged["MinusDA",
                -gauge[[i, #]] aLower[[#, j]]] &) /@ supportDA,
              {tagged["MinusDerivative",
                -derivatives[[mu, i, j]]]}], {}]];
        correctionTerms = Select[correctionTerms,
          ! SameQ[#1["Expression"], 0] &];
        derivativeTerms += Count[
          Lookup[correctionTerms, "Kind", {}], "MinusDerivative"];
        correctionExpressions = Lookup[correctionTerms, "Expression", {}];
        If[correctionExpressions =!= {} &&
            ! SameQ[Total[correctionExpressions], 0],
          base = connection[[mu, futureRows[[i]], lowerColumns[[j]]]];
          Sow[<|"Target" -> {mu, futureRows[[i]], lowerColumns[[j]]},
            "Terms" -> If[SameQ[base, 0], correctionTerms,
              Prepend[correctionTerms, tagged["Base", base]]]|>]],
        {i, Length[futureRows]}, {j, lowerSize}],
      {mu, 2}]];
  aRecords = If[Length[aHarvest[[2]]] === 0, {},
    First[aHarvest[[2]]]];

  leftS = transformation[[All, rowIndices]];
  leftSRowSupport = familyRowGaugeFFSupport /@ leftS;
  sHarvest = Reap[
    Do[
      supportS = Intersection[
        leftSRowSupport[[i]], gaugeColumnSupport[[j]]];
      sProducts += Length[supportS];
      correctionTerms = (tagged["SD",
          leftS[[i, #]] gauge[[#, j]]] &) /@ supportS;
      correctionTerms = Select[correctionTerms,
        ! SameQ[#1["Expression"], 0] &];
      correctionExpressions = Lookup[correctionTerms, "Expression", {}];
      If[correctionExpressions =!= {} &&
          ! SameQ[Total[correctionExpressions], 0],
        base = transformation[[i, lowerColumns[[j]]]];
        Sow[<|"Target" -> {i, lowerColumns[[j]]},
          "Terms" -> If[SameQ[base, 0], correctionTerms,
            Prepend[correctionTerms, tagged["Base", base]]]|>]],
      {i, n}, {j, lowerSize}]];
  sRecords = If[Length[sHarvest[[2]]] === 0, {},
    First[sHarvest[[2]]]];

  rightInverse = inverse[[lowerColumns, All]];
  rightInverseColumnSupport =
    familyRowGaugeFFSupport /@ Transpose[rightInverse];
  siHarvest = Reap[
    Do[
      supportSi = Intersection[gaugeRowSupport[[i]],
        rightInverseColumnSupport[[j]]];
      siProducts += Length[supportSi];
      correctionTerms = (tagged["MinusDInverse",
          -gauge[[i, #]] rightInverse[[#, j]]] &) /@ supportSi;
      correctionTerms = Select[correctionTerms,
        ! SameQ[#1["Expression"], 0] &];
      correctionExpressions = Lookup[correctionTerms, "Expression", {}];
      If[correctionExpressions =!= {} &&
          ! SameQ[Total[correctionExpressions], 0],
        base = inverse[[rowIndices[[i]], j]];
        Sow[<|"Target" -> {rowIndices[[i]], j},
          "Terms" -> If[SameQ[base, 0], correctionTerms,
            Prepend[correctionTerms, tagged["Base", base]]]|>]],
      {i, rowSize}, {j, n}]];
  siRecords = If[Length[siHarvest[[2]]] === 0, {},
    First[siHarvest[[2]]]];

  compileRecord[record_Association] := <|
    "Target" -> record["Target"],
    "Terms" -> Map[
      <|"Kind" -> #1["Kind"],
        "Expression" -> familyRowGaugeFFReplaceRoots[
          #1["Expression"], roots]|> &,
      record["Terms"]]|>;
  records = <|
    "Connection" -> (compileRecord /@ aRecords),
    "Transformation" -> (compileRecord /@ sRecords),
    "Inverse" -> (compileRecord /@ siRecords)|>;
  If[! FreeQ[records,
      Power[_, exponent_Rational /; Denominator[exponent] =!= 1]],
    Return[<|"Status" -> "UnknownRadicalsAfterCompilation"|>]];

  parameterExpressions = {rootSquares,
    Cases[records, KeyValuePattern["Expression" -> expression_] :>
      expression, {0, Infinity}]};
  parameters = DeleteDuplicates[Cases[parameterExpressions,
    symbol_Symbol /; Context[symbol] =!= "System`" &&
      ! MemberQ[variables, symbol] &&
      symbol =!= familyRowGaugeFFRoot :> symbol,
    {0, Infinity}, Heads -> True]];
  parameters = SortBy[parameters, familyRowGaugeFFSymbolKey];
  dimensions = {n, rowSize, lowerSize};
  fieldFingerprint = familyRowGaugeFFFieldFingerprint[variables, roots];
  fingerprint = familyRowGaugeFFPreparationFingerprint[
    variables, roots, parameters, rowIndices, dimensions, records];
  denominators = familyRowGaugeFFCoefficientDenominators[
    {rootSquares, records}];

  <|"Status" -> "Prepared", "Version" -> 1,
    "Variables" -> variables, "Parameters" -> parameters,
    "CanonicalRoots" -> roots, "RootCount" -> Length[roots],
    "BranchCount" -> 2^Length[roots],
    "RowIndices" -> rowIndices, "Dimensions" -> dimensions,
    "Records" -> records,
    "CoefficientDenominators" -> denominators,
    "DerivativeMode" -> "PrecomputedExact",
    "FieldFingerprint" -> fieldFingerprint,
    "Fingerprint" -> fingerprint,
    "Statistics" -> <|
      "Connection" -> <|"CandidateEntries" ->
          2 Length[futureRows] lowerSize,
        "Products" -> aProducts, "Touched" -> Length[aRecords],
        "TermCount" -> Total[Length[#1["Terms"]] & /@ aRecords]|>,
      "Transformation" -> <|"CandidateEntries" -> n lowerSize,
        "Products" -> sProducts, "Touched" -> Length[sRecords],
        "TermCount" -> Total[Length[#1["Terms"]] & /@ sRecords]|>,
      "Inverse" -> <|"CandidateEntries" -> rowSize n,
        "Products" -> siProducts, "Touched" -> Length[siRecords],
        "TermCount" -> Total[Length[#1["Terms"]] & /@ siRecords]|>,
      "DerivativeTerms" -> derivativeTerms,
      "PrepareSeconds" -> N[AbsoluteTime[] - started]|>|>
];

familyRowGaugeFiniteFieldPrepare[___] :=
  <|"Status" -> "InvalidInput"|>;

(* Recursive arithmetic in F_p.  Expressions have already had every
   declared half-power replaced by familyRowGaugeFFRoot[i], so only
   rational field operations remain. *)
familyRowGaugeFFModEvaluate[expression_, scalarValues_Association,
    rootValues_List, prime_Integer] := Module[
  {evaluate, tag = Unique["familyRowGaugeFFEvaluate"], result},
  result = Catch[
    evaluate[node_] := Which[
      IntegerQ[node], Mod[node, prime],
      Head[node] === Rational,
        Module[{denominator = Mod[Denominator[node], prime]},
          If[denominator === 0,
            Throw[<|"Status" -> "BadPrime",
              "Denominator" -> Denominator[node]|>, tag]];
          Mod[Numerator[node] PowerMod[denominator, -1, prime], prime]],
      MatchQ[node, familyRowGaugeFFRoot[_Integer]],
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
      True,
        Throw[<|"Status" -> "UnsupportedExpression",
          "Expression" -> HoldForm[node]|>, tag]];
    evaluate[expression], tag, #1 &];
  If[AssociationQ[result], result,
    <|"Status" -> "OK", "Value" -> Mod[result, prime]|>]
];

(* Deterministic Tonelli--Shanks for p == 1 (mod 4).  The neutral ABI
   declares a modular square root only for p == 3 (mod 4)
   (multiquadraticSquareRoots), so this is the one algebra primitive this
   file still implements; it duplicates nothing. *)
familyRowGaugeFFTonelliShanks[value_Integer, prime_Integer] := Module[
  {a = Mod[value, prime], q, s = 0, z = 2, c, x, t, m, i, probe, b},
  If[a === 0, Return[0]];
  If[JacobiSymbol[a, prime] =!= 1, Return[$Failed]];
  q = prime - 1;
  While[EvenQ[q], q = Quotient[q, 2]; s++];
  While[JacobiSymbol[z, prime] =!= -1, z++];
  c = PowerMod[z, q, prime];
  x = PowerMod[a, Quotient[q + 1, 2], prime];
  t = PowerMod[a, q, prime];
  m = s;
  While[t =!= 1,
    i = 1; probe = Mod[t t, prime];
    While[i < m && probe =!= 1,
      probe = Mod[probe probe, prime]; i++];
    If[i >= m, Return[$Failed]];
    b = PowerMod[c, 2^(m - i - 1), prime];
    x = Mod[x b, prime];
    t = Mod[t b b, prime];
    c = Mod[b b, prime];
    m = i];
  x
];

(* The sign ABI at a point is the SMALLER of the two roots.  The neutral
   module returns the raw PowerMod representative, so the normalization
   Min[r, p - r] is applied HERE, at the consumer boundary -- that is the
   second pinned divergence of the deletion gate. *)
familyRowGaugeFFSquareRoot[value_Integer, prime_Integer] := Module[
  {a = Mod[value, prime], raw},
  If[a === 0, Return[0]];
  If[JacobiSymbol[a, prime] =!= 1, Return[$Failed]];
  raw = If[Mod[prime, 4] === 3,
    With[{neutral = multiquadraticSquareRoots[{a}, prime]},
      If[MatchQ[neutral, {_Integer}], First[neutral], $Failed]],
    familyRowGaugeFFTonelliShanks[a, prime]];
  If[raw === $Failed, $Failed, Min[raw, prime - raw]]
];

familyRowGaugeFiniteFieldEvaluate[preparation_Association, point_,
    prime_, parameterRules_: {}] := Module[
  {started = AbsoluteTime[], variables, parameters, roots, rootSquares,
   records, dimensions, expectedFieldFingerprint, expectedFingerprint,
   ruleLeft, missing, extra, scalarValues, badDenominators,
   pointMod, rootSquareResults, rootSquareValues, ramified,
   nonsplit, rootValues, branchCount, signedRootValues, tag,
   evaluateRecord, evaluatedRecords, allRoundTrips, termCount,
   sampleFingerprint},
  If[Lookup[preparation, "Status", None] =!= "Prepared" ||
      Lookup[preparation, "Version", None] =!= 1,
    Return[<|"Status" -> "InvalidPreparation"|>]];
  variables = Lookup[preparation, "Variables", {}];
  parameters = Lookup[preparation, "Parameters", {}];
  roots = Lookup[preparation, "CanonicalRoots", {}];
  records = Lookup[preparation, "Records", <||>];
  dimensions = Lookup[preparation, "Dimensions", {}];
  expectedFieldFingerprint = familyRowGaugeFFFieldFingerprint[
    variables, roots];
  expectedFingerprint = familyRowGaugeFFPreparationFingerprint[
    variables, roots, parameters,
    Lookup[preparation, "RowIndices", {}], dimensions, records];
  If[Lookup[preparation, "FieldFingerprint", None] =!=
      expectedFieldFingerprint || Lookup[preparation, "Fingerprint", None]
      =!= expectedFingerprint,
    Return[<|"Status" -> "PreparationFingerprintMismatch"|>]];
  If[! IntegerQ[prime] || prime <= 3 || prime >= 2^31 ||
      ! TrueQ[PrimeQ[prime]],
    Return[<|"Status" -> "InvalidPrime", "Prime" -> prime|>]];
  If[! MatchQ[point, {_Integer, _Integer}],
    Return[<|"Status" -> "InvalidPoint", "Point" -> point|>]];
  If[! ListQ[parameterRules] ||
      ! AllTrue[parameterRules, MatchQ[#, _Rule] &] ||
      ! AllTrue[Last /@ parameterRules,
        MatchQ[#, _Integer | _Rational] &],
    Return[<|"Status" -> "InvalidParameterRules"|>]];
  ruleLeft = First /@ parameterRules;
  If[! DuplicateFreeQ[ruleLeft, SameQ],
    Return[<|"Status" -> "DuplicateParameterRules"|>]];
  missing = Select[parameters, ! MemberQ[ruleLeft, #] &];
  extra = Select[ruleLeft, ! MemberQ[parameters, #] &];
  If[missing =!= {},
    Return[<|"Status" -> "MissingParameters",
      "Parameters" -> missing|>]];
  If[extra =!= {},
    Return[<|"Status" -> "UnknownParameters",
      "Parameters" -> extra|>]];
  badDenominators = Select[
    Join[Lookup[preparation, "CoefficientDenominators", {}],
      Denominator /@ (Last /@ parameterRules)],
    Mod[#, prime] === 0 &];
  If[badDenominators =!= {},
    Return[<|"Status" -> "BadPrime", "Prime" -> prime,
      "DividingDenominators" -> DeleteDuplicates[badDenominators]|>]];

  pointMod = Mod[point, prime];
  scalarValues = Association[Join[
    Thread[variables -> pointMod], parameterRules]];
  rootSquares = Lookup[roots, "RootSquare", {}];
  rootSquareResults = familyRowGaugeFFModEvaluate[
      #, scalarValues, {}, prime] & /@ rootSquares;
  If[! AllTrue[rootSquareResults, #1["Status"] === "OK" &],
    Return[Join[FirstCase[rootSquareResults,
        result_ /; result["Status"] =!= "OK"],
      <|"Phase" -> "RootSquareEvaluation", "Point" -> pointMod|>]]];
  rootSquareValues = Lookup[rootSquareResults, "Value", {}];
  ramified = Flatten[Position[rootSquareValues, 0,
    {1}, Heads -> False]];
  If[ramified =!= {},
    Return[<|"Status" -> "RamifiedPoint", "Point" -> pointMod,
      "RootIndices" -> ramified|>]];
  nonsplit = Flatten[Position[
    JacobiSymbol[#, prime] & /@ rootSquareValues, Except[1],
    {1}, Heads -> False]];
  If[nonsplit =!= {},
    Return[<|"Status" -> "NonSplitPoint", "Point" -> pointMod,
      "RootIndices" -> nonsplit,
      "RootSquareValues" -> rootSquareValues|>]];
  rootValues = familyRowGaugeFFSquareRoot[#, prime] & /@
    rootSquareValues;
  If[MemberQ[rootValues, $Failed],
    Return[<|"Status" -> "SquareRootFailure", "Point" -> pointMod|>]];
  branchCount = 2^Length[roots];
  signedRootValues = Table[
    MapIndexed[If[BitGet[branch, First[#2] - 1] === 1,
        Mod[-#1, prime], #1] &, rootValues],
    {branch, 0, branchCount - 1}];

  tag = Unique["familyRowGaugeFFRecord"];
  (* One conjugate vector per record, then ONE neutral projection and
     ONE neutral conjugate evaluation as the round-trip certificate. *)
  evaluateRecord[kind_, record_Association] := Module[
    {values, termResults, channels, recomposed},
    values = Table[
      termResults = familyRowGaugeFFModEvaluate[
          #1["Expression"], scalarValues,
          signedRootValues[[branch]], prime] & /@ record["Terms"];
      If[! AllTrue[termResults, #1["Status"] === "OK" &],
        Throw[Join[FirstCase[termResults,
            result_ /; result["Status"] =!= "OK"],
          <|"RecordType" -> kind, "Target" -> record["Target"],
            "BranchMask" -> branch - 1, "Point" -> pointMod|>], tag]];
      Mod[Total[Lookup[termResults, "Value", {}]], prime],
      {branch, branchCount}];
    If[Length[values] =!= branchCount || MemberQ[rootValues, 0],
      Throw[<|"Status" -> "InvalidConjugates", "RecordType" -> kind,
        "Target" -> record["Target"]|>, tag]];
    channels = multiquadraticProjectConjugates[values, rootValues, prime];
    If[! VectorQ[channels, IntegerQ] ||
        Length[channels] =!= branchCount,
      Throw[<|"Status" -> "InvalidConjugates", "RecordType" -> kind,
        "Target" -> record["Target"]|>, tag]];
    recomposed = multiquadraticEvaluateConjugates[
      channels, rootValues, prime];
    If[! VectorQ[recomposed, IntegerQ] ||
        recomposed =!= Mod[values, prime],
      Throw[<|"Status" -> "HadamardRoundTripFailed",
        "RecordType" -> kind, "Target" -> record["Target"]|>, tag]];
    <|"Target" -> record["Target"], "Conjugates" -> values,
      "Channels" -> channels,
      "RecomposedConjugates" -> recomposed,
      "CanonicalValue" -> First[recomposed]|>];
  evaluatedRecords = Catch[
    AssociationMap[
      Function[kind,
        evaluateRecord[kind, #] & /@ Lookup[records, kind, {}]],
      {"Connection", "Transformation", "Inverse"}],
    tag, #1 &];
  If[! AssociationQ[evaluatedRecords] ||
      KeyExistsQ[evaluatedRecords, "Status"], Return[evaluatedRecords]];
  allRoundTrips = AllTrue[
    Flatten[Values[evaluatedRecords]],
    #1["Conjugates"] === #1["RecomposedConjugates"] &];
  If[! allRoundTrips,
    Return[<|"Status" -> "HadamardRoundTripFailed"|>]];
  termCount = Total[Length[#1["Terms"]] & /@
    Flatten[Values[records]]];
  sampleFingerprint = Hash[
    {preparation["Fingerprint"], prime, pointMod,
      SortBy[parameterRules, familyRowGaugeFFSymbolKey[First[#]] &],
      rootValues}, "SHA256", "HexString"];
  <|"Status" -> "OK", "Prime" -> prime, "Point" -> pointMod,
    "ParameterRules" -> parameterRules,
    "FieldFingerprint" -> preparation["FieldFingerprint"],
    "PreparationFingerprint" -> preparation["Fingerprint"],
    "SampleFingerprint" -> sampleFingerprint,
    "CanonicalRootValues" -> rootValues,
    "RootSquareValues" -> rootSquareValues,
    "BranchMasks" -> Range[0, branchCount - 1],
    "Records" -> evaluatedRecords,
    "HadamardRoundTrip" -> True,
    "Statistics" -> <|"Branches" -> branchCount,
      "TouchedEntries" -> Total[Length /@ Values[records]],
      "TermCount" -> termCount,
      "TermEvaluations" -> branchCount termCount,
      "HadamardTransforms" -> Total[Length /@ Values[records]],
      "EvaluateSeconds" -> N[AbsoluteTime[] - started]|>|>
];

familyRowGaugeFiniteFieldEvaluate[___] :=
  <|"Status" -> "InvalidInput"|>;

familyRowGaugeFiniteFieldOracle[connection_, transformation_, inverse_,
    rowIndices_, gauge_, variables_, declaredRoots_, point_, prime_,
    parameterRules_: {}] := Module[{preparation},
  preparation = familyRowGaugeFiniteFieldPrepare[connection,
    transformation, inverse, rowIndices, gauge, variables,
    declaredRoots];
  If[Lookup[preparation, "Status", None] =!= "Prepared",
    preparation,
    familyRowGaugeFiniteFieldEvaluate[
      preparation, point, prime, parameterRules]]
];

End[];
