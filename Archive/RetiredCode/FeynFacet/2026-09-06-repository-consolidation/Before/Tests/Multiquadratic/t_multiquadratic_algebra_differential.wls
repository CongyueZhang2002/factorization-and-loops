#!/usr/bin/env wolframscript
(* Delegation gate: FeynFacet/Private/FamilyRowBasisTransformationFiniteField.wl
   against the neutral modules MultiquadraticAlgebra.wl +
   MultiquadraticOffDiagonalBlockSolve.wl (2026-08-23).

   Until 2026-08-23 this file was the AGREEMENT gate of the handoff's
   External gap 3: the unloaded duplicate kept its own root ordering,
   square-class arithmetic and grade masks, and it was shown to agree
   with the neutral ABI on randomized inputs except for three measured
   divergences.  The duplicated implementations have now been deleted in
   favour of the neutral ABI, so the purpose of this test flips: it
   asserts that they are GONE, that the one piece of boundary work the
   consumer must still do (the sign representative) is done, and that
   the delegated oracle is still exact end to end.

   Acceptance criteria, stated before the run:
     - every symbol on the deletion list has NO definitions after the
       consumer is loaded, and every neutral symbol it delegates to
       does have definitions;
     - the consumer and the neutral representation preserve the declared
       generator order, so a permutation of the declarations induces the
       same permutation of the grade-mask convention;
     - the consumer's root records carry neutral canonical text as
       descriptive metadata without using it to reorder generators;
     - the boundary normalization is applied and is not vacuous: at
       p == 3 (mod 4) the consumer's modular square root is
       Min[r, p - r] of the neutral module's raw representative, and at
       least one randomized draw differs from that raw value;
     - the neutral square-class screen decides the consumer's dependence
       verdicts, including the rank-two case {x, y, x y};
     - the oracle's channels are exactly one neutral projection of its
       conjugates, and its recomposed conjugates are exactly one neutral
       conjugate evaluation of its channels;
     - end to end: for a randomized algebraic row block, every channel
       the consumer's finite-field oracle reports at a split point
       equals the exact channel decomposition of the same entry,
       evaluated at that point in F_p.
   ONE divergence remains pinned, because the neutral module cannot
   absorb it: multiquadraticSquareRoots is declared only for
   p == 3 (mod 4), so the general Tonelli--Shanks stays in the consumer
   for p == 1 (mod 4).  It is exercised here, and it is the only algebra
   primitive this consumer still implements. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FeynFacet`Private`feynFacetPrivateFile["MultiquadraticAlgebra.wl"]];
(* the strip solver is eight files since round 4 (2026-09-02); the manifest
   names them in load order *)
Get[FeynFacet`Private`feynFacetPrivateFile[#]] & /@
  Select[Lookup[Get[FileNameJoin[{root, "FeynFacet", "Private", "LoadOrder.wl"}]],
    "EpsForm"], StringStartsQ[FileNameTake[#], "MultiquadraticOffDiagonalBlock"] &];
(* the consumer is not registered in FeynFacet.m; read it into
   FeynFacet`Private` exactly as Tests/FiniteField/t_family_row_basis_transformation_finite_field.wls
   does *)
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "Prototypes", "FamilyRowBasisTransformationFiniteField.wl"}]];
End[];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
definitionCount[name_String] := Module[{symbol = mq[name]},
  Total[Length /@ {DownValues @@ {symbol}, OwnValues @@ {symbol},
    SubValues @@ {symbol}, UpValues @@ {symbol}}]];

{multiply, hadamard, maskFactor, evaluateConjugates, projectConjugates,
  squareRoots, fieldDecompose, rootOrder, modRational, squareClassSquareQ} =
 mq /@ {"multiquadraticMultiply", "multiquadraticHadamardMatrix",
   "multiquadraticMaskFactor", "multiquadraticEvaluateSignChangeImages",
   "multiquadraticProjectSignChangeImages", "multiquadraticSquareRoots",
   "multiquadraticFieldDecompose", "multiquadraticOffDiagonalBlockRootOrder",
   "multiquadraticOffDiagonalBlockModRational", "multiquadraticOffDiagonalBlockSquareClassSquareQ"};
{canonicalize, consumerSquareRoot, consumerRoot, consumerPrepare,
  consumerEvaluate} =
 mq /@ {"familyRowBasisTransformationFFCanonicalizeRoots", "familyRowBasisTransformationFFSquareRoot",
   "familyRowBasisTransformationFFRoot", "familyRowBasisTransformationFiniteFieldPrepare",
   "familyRowBasisTransformationFiniteFieldEvaluate"};

Clear[x, y, eps, v, w, cx, cy];
SeedRandom[20260823];

(* ---- the duplicated implementations are gone ---- *)
retired = {"familyRowBasisTransformationFFStableKey", "familyRowBasisTransformationFFEquivalentQ",
  "familyRowBasisTransformationFFRadicalBases", "familyRowBasisTransformationFFUniqueEquivalent",
  "familyRowBasisTransformationFFRationalSquareConstantQ",
  "familyRowBasisTransformationFFRationalFunctionSquareQ", "familyRowBasisTransformationFFHadamard",
  "familyRowBasisTransformationFFRootProducts", "familyRowBasisTransformationFFProjectConjugates",
  "familyRowBasisTransformationFFUnresolvedRoot"};
delegated = {"multiquadraticHadamardMatrix", "multiquadraticMaskFactor",
  "multiquadraticProjectSignChangeImages", "multiquadraticEvaluateSignChangeImages",
  "multiquadraticSquareRoots", "multiquadraticOffDiagonalBlockZeroQ",
  "multiquadraticOffDiagonalBlockCanonicalText", "multiquadraticOffDiagonalBlockSquareClassSquareQ",
  "transportChartRadicalBases", "transportChartApplyRootBranches",
  "transportChartRootIndices"};
check["every duplicated algebra implementation is deleted (" <>
  ToString[Count[definitionCount /@ retired, 0]] <> "/" <>
  ToString[Length[retired]] <> " definition-free)",
  AllTrue[retired, definitionCount[#] === 0 &]];
check["every neutral symbol the consumer delegates to is defined (" <>
  ToString[Count[definitionCount /@ delegated, _?Positive]] <> "/" <>
  ToString[Length[delegated]] <> ")",
  AllTrue[delegated, definitionCount[#] > 0 &]];

(* ---- root order: the consumer's order IS the neutral order ---- *)
squarePool = {x, y, 1 + x + y, 1 - x, 1 - y, x + y, 1 + x - y, 2 + x + 3 y,
  x^2 + y, 1 + 2 x + y^2, 3 - x - 2 y, x y + 1};
declared[squares_] := <|"Generator" -> Sqrt[#], "QuadraticRadicand" -> #|> & /@ squares;
frameOrder[squares_] := Module[{frame, order},
  frame = BuildSquareRootGeneratorsAndQuadraticRelations[squares /. {x -> v, y -> w}, {v, w},
    {x, y}];
  If[! AssociationQ[frame] ||
      frame["Status"] =!= "SquareRootGeneratorRelationsVerified",
    Return[$Failed]];
  order = rootOrder[frame, {x, y}, Range[Length[squares]], eps];
  If[Lookup[order, "Status", None] =!= "StableRootOrder", Return[order]];
  Together /@ Lookup[order["Roots"], "QuadraticRadicand", {}]];
consumerOrder[squares_] := Module[{result},
  result = canonicalize[declared[squares], {x, y}];
  If[Lookup[result, "Status", None] =!= "OK", Return[result]];
  Together /@ Lookup[result["Roots"], "QuadraticRadicand", {}]];

orderTrials = 0; orderAgreements = 0; declarationOrderPreserved = 0;
Do[
  Module[{squares, permutations, consumerOrders, neutralOrders},
    squares = RandomSample[squarePool, RandomChoice[{1, 2, 3}]];
    (* only independent square classes are admissible input for either
       implementation; a dependent draw is exercised separately *)
    If[AnyTrue[Rest[Subsets[squares]], squareClassSquareQ[Times @@ #] &],
      Continue[]];
    permutations = RandomSample[Permutations[squares],
      UpTo[Min[3, Length[squares]!]]];
    consumerOrders = consumerOrder /@ permutations;
    neutralOrders = frameOrder /@ permutations;
    orderTrials++;
    If[consumerOrders === permutations && neutralOrders === permutations,
      declarationOrderPreserved++];
    If[consumerOrders === neutralOrders,
      orderAgreements++];
  ],
  {trial, 12}];
check["both paths preserve declaration order on every trial (" <>
  ToString[declarationOrderPreserved] <> "/" <> ToString[orderTrials] <> ")",
  orderTrials >= 8 && declarationOrderPreserved === orderTrials];
check["the consumer's order equals the neutral order on every trial (" <>
  ToString[orderAgreements] <> "/" <> ToString[orderTrials] <> ")",
  orderTrials >= 8 && orderAgreements === orderTrials];

canonicalRules = FeynFacet`Private`multiquadraticOffDiagonalBlockCanonicalRules[{x, y}, eps];
canonicalText[expression_] :=
  FeynFacet`Private`multiquadraticOffDiagonalBlockCanonicalText[expression, canonicalRules];
check["the consumer's sort key is the neutral canonical text",
  Lookup[canonicalize[declared[{x, 1 + x + y}], {x, y}]["Roots"],
      "CanonicalQuadraticRadicand", {}] === (canonicalText /@ {x, 1 + x + y})];
check["the consumer's root order does not depend on the reader's context",
  consumerOrder[{x, 1 + x + y}] ===
      Block[{$ContextPath = {"System`"}, $Context = "FeynFacet`"},
        consumerOrder[{x, 1 + x + y}]] &&
    consumerOrder[{x, y, x + y}] ===
      Block[{$ContextPath = {"System`"}, $Context = "FeynFacet`"},
        consumerOrder[{x, y, x + y}]]];
check["the grade masks follow the declared generator order",
  consumerOrder[{x, 1 + x + y}] === {x, 1 + x + y} &&
    consumerOrder[{x, y, x + y}] === {x, y, x + y} &&
    frameOrder[{x, 1 + x + y}] === {x, 1 + x + y}];

(* ---- the sign representative is normalized at the consumer boundary ---- *)
Do[
  Module[{p = 2147483423, squares, consumerValues, neutralValues},
    squares = Mod[Table[RandomInteger[{1, p - 1}], {6}]^2, p];
    neutralValues = squareRoots[squares, p];
    consumerValues = consumerSquareRoot[#, p] & /@ squares;
    check["the consumer normalizes the neutral representative (trial " <>
      ToString[trial] <> ")",
      ListQ[neutralValues] &&
        Mod[neutralValues^2 - squares, p] === ConstantArray[0, 6] &&
        consumerValues === (Min[#, p - #] & /@ neutralValues)];
    check["the normalization is not vacuous (trial " <> ToString[trial] <> ")",
      consumerValues =!= neutralValues &&
        AllTrue[consumerValues, # <= Quotient[p, 2] &]];
  ],
  {trial, 2}];
(* the residual divergence closed by the overhaul (2026-09-02): the neutral
   entry point and the consumer share ONE modular square root
   (Private/Core/ModularArithmetic.wl, Tonelli--Shanks for p == 1 (mod 4)),
   so p == 1 (mod 4) is served instead of refused *)
check["p == 1 (mod 4) is served by the shared modular square root",
  Mod[101, 4] === 1 && ListQ[squareRoots[{5}, 101]] &&
    Mod[First[squareRoots[{5}, 101]]^2, 101] === 5 &&
    Mod[consumerSquareRoot[5, 101]^2, 101] === 5 &&
    consumerSquareRoot[5, 101] <= Quotient[101, 2] &&
    consumerSquareRoot[5, 101] === Min[#, 101 - #] &[First[squareRoots[{5}, 101]]] &&
    definitionCount["modularTonelliShanks"] > 0];

(* ---- dependence screen ---- *)
check["both reject the rank-two square class {x, y, x y}",
  Lookup[canonicalize[declared[{x, y, x y}], {x, y}], "Status", None] ===
      "DependentQuadraticRadicands" &&
    Lookup[frameOrder[{x, y, x y}], "Status", None] === "DependentQuadraticRadicands"];
check["both accept the independent class {x, y, 1 + x + y}",
  Lookup[canonicalize[declared[{x, y, 1 + x + y}], {x, y}], "Status", None] ===
      "OK" && ListQ[frameOrder[{x, y, 1 + x + y}]]];
squareProbes = {x, x y, x^2, 4 x^2, x^2 y^2, (1 + x)^2/y^2, 9/4, x/y, 2, -x^2};
squareVerdicts = squareClassSquareQ /@ squareProbes;
Print["     square-class verdicts: ", squareVerdicts];
check["the neutral square-class predicate is the only one left, verdicts pinned",
  squareVerdicts === {False, False, True, True, True, True, True, False,
      False, False} &&
    definitionCount["familyRowBasisTransformationFFRationalFunctionSquareQ"] === 0];

(* ---- end to end: the consumer's oracle channels are the exact
   channel decomposition evaluated in F_p ---- *)
Module[{n = 5, rows = {4, 5}, prime = 2147483423, regulator = 7/11, roots,
   declaredRoots, grades, connection, basisTransformationBlock, identity, preparation, evaluation,
   canonical, orderedRoots, point, deltaValues, rootValues, kinds, comparisons},
  declaredRoots = {<|"Generator" -> Sqrt[1 + x + y], "QuadraticRadicand" -> 1 + x + y|>,
    <|"Generator" -> Sqrt[x], "QuadraticRadicand" -> x|>,
    <|"Generator" -> Sqrt[y], "QuadraticRadicand" -> y|>};
  canonical = canonicalize[declaredRoots, {x, y}];
  check["the consumer canonicalizes the declared rank-three roots",
    AssociationQ[canonical] && canonical["Status"] === "OK"];
  orderedRoots = canonical["Roots"];
  roots = Lookup[orderedRoots, "Generator", {}];
  grades = Table[Times @@ Pick[roots, Reverse[IntegerDigits[mask, 2, 3]], 1],
    {mask, 0, 7}];
  connection = Table[Table[If[i < j, 0,
      grades[[1 + Mod[5 mu + 3 i + j, 8]]] (eps + mu + i x + j y)/
        (1 + x + y + i + j)], {i, n}, {j, n}], {mu, 2}];
  basisTransformationBlock = {{roots[[1]]/(1 + y), roots[[2]] roots[[3]]/(2 + x), x/(3 + y)},
    {0, (roots[[1]] + roots[[2]])/(2 + x + y),
      roots[[1]] roots[[2]] roots[[3]]/(4 + x)}};
  identity = IdentityMatrix[n];
  (* the consumer refuses a point that is not split, so choose one *)
  point = SelectFirst[Table[{7 k + 3, 11 k + 5}, {k, 1, 400}],
    Function[candidate, AllTrue[{x, y, 1 + x + y},
      Function[delta, Module[{value = Mod[delta /. Thread[{x, y} -> candidate],
          prime]}, value =!= 0 && JacobiSymbol[value, prime] === 1]]]],
    Missing["NoSplitPoint"]];
  check["a split point exists for the declared rank-three frame",
    MatchQ[point, {_Integer, _Integer}]];
  preparation = consumerPrepare[connection, identity, identity, rows, basisTransformationBlock,
    {x, y}, declaredRoots];
  evaluation = consumerEvaluate[preparation, point, prime, {eps -> regulator}];
  check["the consumer's oracle evaluates the randomized rank-three block",
    AssociationQ[preparation] && preparation["Status"] === "Prepared" &&
      AssociationQ[evaluation] && evaluation["Status"] === "OK" &&
      TrueQ[evaluation["HadamardRoundTrip"]]];
  deltaValues = Lookup[evaluation, "QuadraticRadicandValues", {}];
  rootValues = Lookup[evaluation, "CanonicalRootValues", {}];
  check["the canonical root values square to the reported root squares",
    Mod[rootValues^2 - deltaValues, prime] === ConstantArray[0, 3]];
  check["every reported root value is the normalized representative",
    AllTrue[rootValues, # <= Quotient[prime, 2] &]];
  check["every oracle channel is one neutral projection of its conjugates",
    AllTrue[Flatten[Values[evaluation["Records"]]],
      #["Channels"] === projectConjugates[#["Conjugates"], rootValues, prime] &&
        #["RecomposedConjugates"] ===
          evaluateConjugates[#["Channels"], rootValues, prime] &]];
  kinds = {"Connection", "Transformation", "Inverse"};
  comparisons = Flatten[Table[
    MapThread[
      Function[{compiled, evaluated}, Module[{expression, channels, images},
        (* the exact entry the consumer compiled, with its root
           placeholders resolved back to the canonical roots *)
        expression = Total[Lookup[compiled["Terms"], "Expression", {}]] /.
          consumerRoot[index_] :> orderedRoots[[index, "Generator"]];
        channels = fieldDecompose[expression, orderedRoots];
        compiled["Target"] === evaluated["Target"] && ListQ[channels] &&
          Module[{values = modRational[
              # /. eps -> regulator /. Thread[{x, y} -> point], prime] & /@
            channels},
            FreeQ[values, $Failed] && values === evaluated["Channels"]]]],
      {Lookup[preparation["Records"], kind, {}],
       Lookup[evaluation["Records"], kind, {}]}],
    {kind, kinds}], 1];
  check["the oracle touched a nonempty set of entries", Length[comparisons] > 10];
  check["every oracle channel equals the exact channel decomposition in F_p (" <>
    ToString[Count[comparisons, True]] <> "/" <> ToString[Length[comparisons]] <>
    ")", comparisons =!= {} && AllTrue[comparisons, TrueQ]];
];

Print["t_multiquadratic_algebra_differential: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
