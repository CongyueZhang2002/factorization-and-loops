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
   an ordinary tagged term at every modular point. *)

ClearAll[
  familyRowGaugeFiniteFieldPrepare,
  familyRowGaugeFiniteFieldEvaluate,
  familyRowGaugeFiniteFieldOracle,
  familyRowGaugeFFSupport,
  familyRowGaugeFFStableKey,
  familyRowGaugeFFSymbolKey,
  familyRowGaugeFFEquivalentQ,
  familyRowGaugeFFRadicalBases,
  familyRowGaugeFFUniqueEquivalent,
  familyRowGaugeFFRationalSquareConstantQ,
  familyRowGaugeFFRationalFunctionSquareQ,
  familyRowGaugeFFCanonicalizeRoots,
  familyRowGaugeFFReplaceRoots,
  familyRowGaugeFFRoot,
  familyRowGaugeFFUnresolvedRoot,
  familyRowGaugeFFFieldFingerprint,
  familyRowGaugeFFPreparationFingerprint,
  familyRowGaugeFFCoefficientDenominators,
  familyRowGaugeFFModEvaluate,
  familyRowGaugeFFSquareRoot,
  familyRowGaugeFFHadamard,
  familyRowGaugeFFRootProducts,
  familyRowGaugeFFProjectConjugates
];

familyRowGaugeFFSupport[entries_List] :=
  Flatten[Position[entries, Except[0], {1}, Heads -> False]];

familyRowGaugeFFStableKey[expression_] :=
  ToString[FullForm[Unevaluated[expression]], InputForm];

familyRowGaugeFFSymbolKey[symbol_Symbol] :=
  {Context[symbol], SymbolName[symbol]};

familyRowGaugeFFEquivalentQ[left_, right_] :=
  SameQ[left, right] || TrueQ[Quiet[Check[
    Together[left - right] === 0, False]]];

familyRowGaugeFFRadicalBases[expression_] := Cases[
  Unevaluated[expression],
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
    base, {0, Infinity}, Heads -> True];

familyRowGaugeFFUniqueEquivalent[items_List] := Fold[
  Function[{current, item},
    If[AnyTrue[current, Function[existing,
        familyRowGaugeFFEquivalentQ[existing, item]]], current,
      Append[current, item]]], {}, items];

familyRowGaugeFFRationalSquareConstantQ[
    value : (_Integer | _Rational)] := value >= 0 &&
  IntegerQ[Sqrt[Numerator[value]]] &&
  IntegerQ[Sqrt[Denominator[value]]];

(* A Hadamard rank r requires 2^r independent sign automorphisms.  Distinct
   radicands are not sufficient: {x,y,x y}, for example, has square-class
   rank two.  Factorization over Q detects exactly the rational-function
   square relations admitted by this evaluator. *)
familyRowGaugeFFRationalFunctionSquareQ[expression_] := Module[
  {q, numeratorFactors, denominatorFactors, constant},
  q = Quiet[Check[Together[expression], $Failed]];
  If[q === $Failed || ! FreeQ[q,
      Power[_, exponent_Rational] /; Denominator[exponent] =!= 1],
    Return[False]];
  numeratorFactors = Quiet[Check[FactorList[Numerator[q]], $Failed]];
  denominatorFactors = Quiet[Check[FactorList[Denominator[q]], $Failed]];
  If[numeratorFactors === $Failed || denominatorFactors === $Failed ||
      numeratorFactors === {} || denominatorFactors === {},
    Return[False]];
  constant = First[First[numeratorFactors]] /
    First[First[denominatorFactors]];
  familyRowGaugeFFRationalSquareConstantQ[constant] &&
    AllTrue[Rest[numeratorFactors], EvenQ[Last[#]] &] &&
    AllTrue[Rest[denominatorFactors], EvenQ[Last[#]] &]
];

(* The root order is an ABI: mask bit i always denotes canonical root i.
   Normalize the squares before sorting, and reject duplicate extensions
   rather than assigning two sign bits to the same quadratic generator. *)
familyRowGaugeFFCanonicalizeRoots[declaredRoots_, variables_List] := Module[
  {standardized, root, square, radicals, fractional, squareSymbols,
   extraSymbols, duplicate, dependent,
   failureTag = Unique["familyRowGaugeFFRootValidation"]},
  If[! ListQ[declaredRoots],
    Return[<|"Status" -> "InvalidRootDeclarations"|>]];
  If[Length[declaredRoots] > 3,
    Return[<|"Status" -> "UnsupportedRootRank",
      "MaximumRank" -> 3, "ActualRank" -> Length[declaredRoots]|>]];
  If[! AllTrue[declaredRoots, AssociationQ[#] &&
      KeyExistsQ[#, "Root"] && KeyExistsQ[#, "RootSquare"] &],
    Return[<|"Status" -> "InvalidRootDeclarations"|>]];
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
    radicals = familyRowGaugeFFUniqueEquivalent[
      familyRowGaugeFFRadicalBases[root]];
    If[Length[radicals] =!= 1 ||
        ! familyRowGaugeFFEquivalentQ[First[radicals], square] ||
        ! TrueQ[Quiet[Check[Together[root^2 - square] === 0, False]]],
      Throw[<|"Status" -> "InconsistentRootDeclaration",
        "RootIndex" -> index|>, failureTag]];
    <|"Root" -> root, "RootSquare" -> square|>,
    {index, Length[declaredRoots]}], failureTag, #1 &];
  If[AssociationQ[standardized], Return[standardized]];
  duplicate = FirstCase[
    Subsets[Range[Length[standardized]], {2}],
    {left_, right_} /; familyRowGaugeFFEquivalentQ[
      standardized[[left, "RootSquare"]],
      standardized[[right, "RootSquare"]]] :> {left, right}, None];
  If[duplicate =!= None,
    Return[<|"Status" -> "DuplicateRootSquare",
      "RootIndices" -> duplicate|>]];
  dependent = FirstCase[Rest[Subsets[Range[Length[standardized]]]],
    indices_ /; familyRowGaugeFFRationalFunctionSquareQ[
      Times @@ standardized[[indices, "RootSquare"]]] :> indices, None];
  If[dependent =!= None,
    Return[<|"Status" -> "DependentRootSquares",
      "RootIndices" -> dependent|>]];
  standardized = SortBy[standardized,
    {familyRowGaugeFFStableKey[#1["RootSquare"]],
       familyRowGaugeFFStableKey[#1["Root"]]} &];
  <|"Status" -> "OK", "Roots" -> standardized|>
];

familyRowGaugeFFReplaceRoots[expression_, rootSquares_List] := Replace[
  expression,
  Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
    With[{index = FirstCase[Range[Length[rootSquares]],
        candidate_ /; familyRowGaugeFFEquivalentQ[
          base, rootSquares[[candidate]]], Missing["UnknownRoot"]]},
      If[MissingQ[index],
        familyRowGaugeFFUnresolvedRoot[base, exponent],
        familyRowGaugeFFRoot[index]^(2 exponent)]],
  {0, Infinity}];

familyRowGaugeFFFieldFingerprint[variables_List, roots_List] := Hash[
  {"FamilyRowGaugeFiniteFieldV1", familyRowGaugeFFSymbolKey /@ variables,
    Lookup[roots, "RootSquare", {}]}, "SHA256", "HexString"];

familyRowGaugeFFPreparationFingerprint[variables_List, roots_List,
    parameters_List, rowIndices_List, dimensions_List,
    records_Association] := Hash[
  {"FamilyRowGaugeFiniteFieldPreparationV1",
    familyRowGaugeFFSymbolKey /@ variables,
    Lookup[roots, "RootSquare", {}],
    familyRowGaugeFFSymbolKey /@ parameters,
    rowIndices, dimensions,
    Table[{kind,
      ({#1["Target"],
          ({#1["Kind"], #1["Expression"]} & /@ #1["Terms"])} &) /@
        Lookup[records, kind, {}]},
      {kind, {"Connection", "Transformation", "Inverse"}}]},
  "SHA256", "HexString"];

familyRowGaugeFFCoefficientDenominators[expression_] :=
  DeleteDuplicates[Cases[Unevaluated[expression],
    Rational[_, denominator_Integer] :> denominator,
    {0, Infinity}, Heads -> True]];

familyRowGaugeFiniteFieldPrepare[
    connection_, transformation_, inverse_, rowIndices_, gauge_,
    variables_, declaredRoots_] := Module[
  {started = AbsoluteTime[], validSquare, n, start, stop,
   lowerColumns, futureRows, rowSize, lowerSize, rootResult, roots,
   rootSquares, rawExpressions, radicals, unknownRadicals,
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
  radicals = familyRowGaugeFFUniqueEquivalent[
    familyRowGaugeFFRadicalBases[rawExpressions]];
  unknownRadicals = Select[radicals, Function[radical,
    ! AnyTrue[rootSquares, Function[square,
      familyRowGaugeFFEquivalentQ[radical, square]]]]];
  If[unknownRadicals =!= {},
    Return[<|"Status" -> "UnknownRadicals",
      "RadicalBases" -> unknownRadicals|>]];

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
          #1["Expression"], rootSquares]|> &,
      record["Terms"]]|>;
  records = <|
    "Connection" -> (compileRecord /@ aRecords),
    "Transformation" -> (compileRecord /@ sRecords),
    "Inverse" -> (compileRecord /@ siRecords)|>;
  If[! FreeQ[records, _familyRowGaugeFFUnresolvedRoot],
    Return[<|"Status" -> "UnknownRadicalsAfterCompilation"|>]];

  parameterExpressions = {rootSquares,
    Cases[records, KeyValuePattern["Expression" -> expression_] :>
      expression, {0, Infinity}]};
  parameters = DeleteDuplicates[Cases[parameterExpressions,
    symbol_Symbol /; Context[symbol] =!= "System`" &&
      ! MemberQ[variables, symbol] &&
      symbol =!= familyRowGaugeFFRoot &&
      symbol =!= familyRowGaugeFFUnresolvedRoot :> symbol,
    {0, Infinity}, Heads -> True]];
  parameters = SortBy[parameters, familyRowGaugeFFStableKey];
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

(* Deterministic Tonelli--Shanks, including the p == 3 (mod 4) fast
   path.  The smaller of the two roots fixes the sign ABI at a point. *)
familyRowGaugeFFSquareRoot[value_Integer, prime_Integer] := Module[
  {a = Mod[value, prime], q, s = 0, z = 2, c, x, t, m, i, probe, b},
  If[a === 0, Return[0]];
  If[JacobiSymbol[a, prime] =!= 1, Return[$Failed]];
  If[Mod[prime, 4] === 3,
    x = PowerMod[a, Quotient[prime + 1, 4], prime];
    Return[Min[x, prime - x]]];
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
  Min[x, prime - x]
];

familyRowGaugeFFHadamard[rank_Integer?NonNegative] := Table[
  If[EvenQ[DigitCount[BitAnd[row, column], 2, 1]], 1, -1],
  {row, 0, 2^rank - 1}, {column, 0, 2^rank - 1}];

familyRowGaugeFFRootProducts[rootValues_List, prime_Integer] := Table[
  Mod[Product[If[BitGet[mask, index - 1] === 1,
      rootValues[[index]], 1], {index, Length[rootValues]}], prime],
  {mask, 0, 2^Length[rootValues] - 1}];

familyRowGaugeFFProjectConjugates[values_List, rootValues_List,
    prime_Integer] := Module[
  {rank = Length[rootValues], branchCount, hadamard, rootProducts,
   weighted, channels, recomposed},
  branchCount = 2^rank;
  If[Length[values] =!= branchCount || MemberQ[rootValues, 0],
    Return[<|"Status" -> "InvalidConjugates"|>]];
  hadamard = familyRowGaugeFFHadamard[rank];
  rootProducts = familyRowGaugeFFRootProducts[rootValues, prime];
  weighted = Mod[PowerMod[branchCount, -1, prime]
    hadamard.values, prime];
  channels = Mod[MapThread[#1 PowerMod[#2, -1, prime] &,
    {weighted, rootProducts}], prime];
  recomposed = Mod[hadamard.(channels rootProducts), prime];
  <|"Status" -> If[recomposed === Mod[values, prime], "OK",
      "HadamardRoundTripFailed"],
    "Channels" -> channels,
    "RecomposedConjugates" -> recomposed,
    "CanonicalValue" -> First[recomposed]|>
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
  evaluateRecord[kind_, record_Association] := Module[
    {values, termResults, projection},
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
    projection = familyRowGaugeFFProjectConjugates[
      values, rootValues, prime];
    If[projection["Status"] =!= "OK",
      Throw[Join[projection, <|"RecordType" -> kind,
        "Target" -> record["Target"]|>], tag]];
    <|"Target" -> record["Target"], "Conjugates" -> values,
      "Channels" -> projection["Channels"],
      "RecomposedConjugates" -> projection["RecomposedConjugates"],
      "CanonicalValue" -> projection["CanonicalValue"]|>];
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
      SortBy[parameterRules, familyRowGaugeFFStableKey[First[#]] &],
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
