#!/usr/bin/env wolframscript
(* Delegation gate: FeynFacet/Private/FamilyRowGaugeFiniteField.wl
   against the neutral modules MultiquadraticAlgebra.wl +
   MultiquadraticStripSolve.wl (2026-08-23).

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
     - the consumer's canonical root ORDER is the neutral order on the
       randomized frame-realistic class where the two used to disagree
       (measured agreement 7/12 before the deletion; 12/12 required
       now), it is permutation invariant, and it does not change with
       the reader's $Context/$ContextPath (the deleted key was the
       printed text of the root square in the CALLER's symbols and never
       reached FullForm at all -- pool defect 3);
     - the consumer's root records carry the neutral canonical text as
       their sort key, and the relabeling the deletion caused is the
       pinned one: {x, y, x + y} ordered as {x, x + y, y} before and
       orders as {x + y, x, y} now;
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
Get[FileNameJoin[{root, "FeynFacet", "Private", "Core", "MultiquadraticAlgebra.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "EpsForm", "MultiquadraticStripSolve.wl"}]];
(* the consumer is not registered in FeynFacet.m; read it into
   FeynFacet`Private` exactly as Tests/FiniteField/t_family_row_gauge_finite_field.wls
   does *)
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "Prototypes", "FamilyRowGaugeFiniteField.wl"}]];
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
   "multiquadraticMaskFactor", "multiquadraticEvaluateConjugates",
   "multiquadraticProjectConjugates", "multiquadraticSquareRoots",
   "multiquadraticFieldDecompose", "multiquadraticStripRootOrder",
   "multiquadraticStripModRational", "multiquadraticStripSquareClassSquareQ"};
{canonicalize, consumerSquareRoot, consumerRoot, consumerPrepare,
  consumerEvaluate} =
 mq /@ {"familyRowGaugeFFCanonicalizeRoots", "familyRowGaugeFFSquareRoot",
   "familyRowGaugeFFRoot", "familyRowGaugeFiniteFieldPrepare",
   "familyRowGaugeFiniteFieldEvaluate"};

Clear[x, y, eps, v, w, cx, cy];
SeedRandom[20260823];

(* ---- the duplicated implementations are gone ---- *)
retired = {"familyRowGaugeFFStableKey", "familyRowGaugeFFEquivalentQ",
  "familyRowGaugeFFRadicalBases", "familyRowGaugeFFUniqueEquivalent",
  "familyRowGaugeFFRationalSquareConstantQ",
  "familyRowGaugeFFRationalFunctionSquareQ", "familyRowGaugeFFHadamard",
  "familyRowGaugeFFRootProducts", "familyRowGaugeFFProjectConjugates",
  "familyRowGaugeFFUnresolvedRoot"};
delegated = {"multiquadraticHadamardMatrix", "multiquadraticMaskFactor",
  "multiquadraticProjectConjugates", "multiquadraticEvaluateConjugates",
  "multiquadraticSquareRoots", "multiquadraticStripZeroQ",
  "multiquadraticStripCanonicalText", "multiquadraticStripSquareClassSquareQ",
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
declared[squares_] := <|"Root" -> Sqrt[#], "RootSquare" -> #|> & /@ squares;
frameOrder[squares_] := Module[{frame, order},
  frame = BuildAlgebraicTransportFrame[squares /. {x -> v, y -> w}, {v, w},
    {cx, cy}];
  If[! AssociationQ[frame] || frame["Status"] =!= "ExactFrame",
    Return[$Failed]];
  order = rootOrder[frame, {x, y}, Range[Length[squares]], eps];
  If[Lookup[order, "Status", None] =!= "StableRootOrder", Return[order]];
  Together /@ Lookup[order["Roots"], "RootSquare", {}]];
consumerOrder[squares_] := Module[{result},
  result = canonicalize[declared[squares], {x, y}];
  If[Lookup[result, "Status", None] =!= "OK", Return[result]];
  Together /@ Lookup[result["Roots"], "RootSquare", {}]];

orderTrials = 0; orderAgreements = 0; orderStable = 0; orderPermutation = 0;
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
    If[AllTrue[consumerOrders, ListQ] && AllTrue[neutralOrders, ListQ] &&
        Length[DeleteDuplicates[consumerOrders]] === 1 &&
        Length[DeleteDuplicates[neutralOrders]] === 1, orderStable++];
    If[AllTrue[consumerOrders, ListQ] && AllTrue[neutralOrders, ListQ] &&
        Sort[First[consumerOrders]] === Sort[First[neutralOrders]],
      orderPermutation++];
    If[AllTrue[consumerOrders, ListQ] && AllTrue[neutralOrders, ListQ] &&
        DeleteDuplicates[consumerOrders] === DeleteDuplicates[neutralOrders],
      orderAgreements++];
  ],
  {trial, 12}];
check["both root orders are permutation invariant on every trial (" <>
  ToString[orderStable] <> "/" <> ToString[orderTrials] <> ")",
  orderTrials >= 8 && orderStable === orderTrials];
check["both root orders select the same root set on every trial (" <>
  ToString[orderPermutation] <> "/" <> ToString[orderTrials] <> ")",
  orderTrials >= 8 && orderPermutation === orderTrials];
check["the consumer's order IS the neutral order on every trial (" <>
  ToString[orderAgreements] <> "/" <> ToString[orderTrials] <>
  "; 7/12 before the deletion)",
  orderTrials >= 8 && orderAgreements === orderTrials];

canonicalRules = FeynFacet`Private`multiquadraticStripCanonicalRules[{x, y}, eps];
canonicalText[expression_] :=
  FeynFacet`Private`multiquadraticStripCanonicalText[expression, canonicalRules];
check["the consumer's sort key is the neutral canonical text",
  Lookup[canonicalize[declared[{x, 1 + x + y}], {x, y}]["Roots"],
      "CanonicalRootSquare", {}] === (canonicalText /@ {x, 1 + x + y})];
check["the consumer's root order does not depend on the reader's context",
  consumerOrder[{x, 1 + x + y}] ===
      Block[{$ContextPath = {"System`"}, $Context = "FeynFacet`"},
        consumerOrder[{x, 1 + x + y}]] &&
    consumerOrder[{x, y, x + y}] ===
      Block[{$ContextPath = {"System`"}, $Context = "FeynFacet`"},
        consumerOrder[{x, y, x + y}]]];
(* the relabeling the deletion caused, pinned: the deleted key sorted
   {x, 1 + x + y} as {1 + x + y, x} and {x, y, x + y} as {x, x + y, y} *)
check["the grade masks relabel exactly as the deletion gate measured",
  consumerOrder[{x, 1 + x + y}] === {x, 1 + x + y} &&
    consumerOrder[{x, y, x + y}] === {x + y, x, y} &&
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
(* the pinned residual divergence: no neutral square root at p == 1 (mod 4) *)
check["p == 1 (mod 4) has no neutral entry point and keeps Tonelli--Shanks",
  Mod[101, 4] === 1 && ! ListQ[squareRoots[{5}, 101]] &&
    Head[squareRoots[{5}, 101]] === FeynFacet`Private`multiquadraticSquareRoots &&
    Mod[consumerSquareRoot[5, 101]^2, 101] === 5 &&
    consumerSquareRoot[5, 101] <= Quotient[101, 2] &&
    definitionCount["familyRowGaugeFFTonelliShanks"] > 0];

(* ---- dependence screen ---- *)
check["both reject the rank-two square class {x, y, x y}",
  Lookup[canonicalize[declared[{x, y, x y}], {x, y}], "Status", None] ===
      "DependentRootSquares" &&
    Lookup[frameOrder[{x, y, x y}], "Status", None] === "DependentRootSquares"];
check["both accept the independent class {x, y, 1 + x + y}",
  Lookup[canonicalize[declared[{x, y, 1 + x + y}], {x, y}], "Status", None] ===
      "OK" && ListQ[frameOrder[{x, y, 1 + x + y}]]];
squareProbes = {x, x y, x^2, 4 x^2, x^2 y^2, (1 + x)^2/y^2, 9/4, x/y, 2, -x^2};
squareVerdicts = squareClassSquareQ /@ squareProbes;
Print["     square-class verdicts: ", squareVerdicts];
check["the neutral square-class predicate is the only one left, verdicts pinned",
  squareVerdicts === {False, False, True, True, True, True, True, False,
      False, False} &&
    definitionCount["familyRowGaugeFFRationalFunctionSquareQ"] === 0];

(* ---- end to end: the consumer's oracle channels are the exact
   channel decomposition evaluated in F_p ---- *)
Module[{n = 5, rows = {4, 5}, prime = 2147483423, regulator = 7/11, roots,
   declaredRoots, grades, connection, gauge, identity, preparation, evaluation,
   canonical, orderedRoots, point, deltaValues, rootValues, kinds, comparisons},
  declaredRoots = {<|"Root" -> Sqrt[1 + x + y], "RootSquare" -> 1 + x + y|>,
    <|"Root" -> Sqrt[x], "RootSquare" -> x|>,
    <|"Root" -> Sqrt[y], "RootSquare" -> y|>};
  canonical = canonicalize[declaredRoots, {x, y}];
  check["the consumer canonicalizes the declared rank-three roots",
    AssociationQ[canonical] && canonical["Status"] === "OK"];
  orderedRoots = canonical["Roots"];
  roots = Lookup[orderedRoots, "Root", {}];
  grades = Table[Times @@ Pick[roots, Reverse[IntegerDigits[mask, 2, 3]], 1],
    {mask, 0, 7}];
  connection = Table[Table[If[i < j, 0,
      grades[[1 + Mod[5 mu + 3 i + j, 8]]] (eps + mu + i x + j y)/
        (1 + x + y + i + j)], {i, n}, {j, n}], {mu, 2}];
  gauge = {{roots[[1]]/(1 + y), roots[[2]] roots[[3]]/(2 + x), x/(3 + y)},
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
  preparation = consumerPrepare[connection, identity, identity, rows, gauge,
    {x, y}, declaredRoots];
  evaluation = consumerEvaluate[preparation, point, prime, {eps -> regulator}];
  check["the consumer's oracle evaluates the randomized rank-three block",
    AssociationQ[preparation] && preparation["Status"] === "Prepared" &&
      AssociationQ[evaluation] && evaluation["Status"] === "OK" &&
      TrueQ[evaluation["HadamardRoundTrip"]]];
  deltaValues = Lookup[evaluation, "RootSquareValues", {}];
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
          consumerRoot[index_] :> orderedRoots[[index, "Root"]];
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
