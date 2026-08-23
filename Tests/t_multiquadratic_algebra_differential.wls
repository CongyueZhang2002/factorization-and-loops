#!/usr/bin/env wolframscript
(* Differential test: the unloaded duplicate
   FeynFacet/Private/FamilyRowGaugeFiniteField.wl against the neutral
   modules MultiquadraticAlgebra.wl + MultiquadraticStripSolve.wl
   (2026-08-23).  This is the deletion gate of the handoff's External
   gap 3: the duplicate keeps its own root ordering, square-class
   arithmetic and grade masks, and may only be rewritten to consume the
   neutral ABI once the two are shown to agree on randomized inputs.
   The duplicate is called READ-ONLY and is not modified here.

   Acceptance criteria, stated before the run:
     - the character table, the root products and the conjugate
       projection agree exactly, at every rank 0..3 and at two primes,
       on randomized data;
     - grade multiplication agrees: for randomized channel vectors the
       duplicate's conjugate-evaluate/project pipeline returns the same
       channels as one call of the neutral product;
     - each canonical ROOT ORDER is a permutation-invariant function of
       the root set, and the two orders are permutations of each other,
       on randomized declared roots drawn from the class every
       transport frame produces (polynomial root squares in the two
       chart variables);
     - the duplicate's dependence screen and the neutral module's agree
       verdict by verdict, including the rank-two case {x, y, x y};
     - end to end: for a randomized algebraic row block, every channel
       the duplicate's finite-field oracle reports at a split point
       equals the exact channel decomposition of the same entry,
       evaluated at that point in F_p.
   Three measured DIVERGENCES are pinned as such, because a consumer
   swapping in the neutral module must handle them:
     - the two modular square roots return different representatives of
       the same class (the duplicate normalizes to the smaller root,
       the neutral module returns the raw exponentiation);
     - the duplicate's sort key is the printed text of the root square
       in the CALLER's symbols and changes with $ContextPath, while the
       neutral key is a canonical text in formal System` symbols and
       does not (pool defect 3).  A context-free key cannot in general
       reproduce a context-dependent one, so the two ROOT ORDERS are
       different functions of the same set: the deletion of the
       duplicate's copy relabels its grade masks, which is admissible
       only because FamilyRowGaugeFiniteField.wl is not registered in
       FeynFacet.m and no shipped artifact is keyed to its order;
     - the duplicate's key never reaches FullForm at all: the
       Unevaluated wrapper survives into the printed key, so it sorts
       by InputForm text with a constant prefix
       (FamilyRowGaugeFiniteField.wl lines 48-49). *)

root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticAlgebra.wl"}]];
Get[FileNameJoin[{root, "FeynFacet", "Private", "MultiquadraticStripSolve.wl"}]];
(* the duplicate is not registered in FeynFacet.m either; read it into
   its own context exactly as Tests/t_family_row_gauge_finite_field.wls
   does, and only read from it *)
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{root, "FeynFacet", "Private", "FamilyRowGaugeFiniteField.wl"}]];
End[];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];
{multiply, hadamard, maskFactor, evaluateConjugates, projectConjugates,
  squareRoots, fieldDecompose, rootOrder, modRational, squareClassSquareQ} =
 mq /@ {"multiquadraticMultiply", "multiquadraticHadamardMatrix",
   "multiquadraticMaskFactor", "multiquadraticEvaluateConjugates",
   "multiquadraticProjectConjugates", "multiquadraticSquareRoots",
   "multiquadraticFieldDecompose", "multiquadraticStripRootOrder",
   "multiquadraticStripModRational", "multiquadraticStripSquareClassSquareQ"};
{oldHadamard, oldRootProducts, oldProject, oldSquareRoot, oldCanonicalize,
  oldStableKey, oldSquareQ, oldOracle, oldRoot} =
 mq /@ {"familyRowGaugeFFHadamard", "familyRowGaugeFFRootProducts",
   "familyRowGaugeFFProjectConjugates", "familyRowGaugeFFSquareRoot",
   "familyRowGaugeFFCanonicalizeRoots", "familyRowGaugeFFStableKey",
   "familyRowGaugeFFRationalFunctionSquareQ",
   "familyRowGaugeFiniteFieldOracle", "familyRowGaugeFFRoot"};

Clear[x, y, eps, v, w, cx, cy];
primes = {10007, 2147483423};
SeedRandom[20260823];

(* ---- character table, root products, projection, grade product ---- *)
Do[
  Module[{rank = r, rootValues, channels, conjugates, oldChannels, newChannels,
     leftChannels, rightChannels, oldProduct},
    check["rank " <> ToString[r] <> ": character tables are identical",
      oldHadamard[r] === hadamard[r]];
    rootValues = Table[RandomInteger[{2, prime - 2}], {r}];
    check["rank " <> ToString[r] <> " mod " <> ToString[prime] <>
      ": root products are identical",
      oldRootProducts[rootValues, prime] ===
        Table[Mod[maskFactor[mask, rootValues], prime], {mask, 0, 2^r - 1}]];
    channels = Table[RandomInteger[{1, prime - 1}], {2^r}];
    conjugates = evaluateConjugates[channels, rootValues, prime];
    oldChannels = oldProject[conjugates, rootValues, prime];
    newChannels = projectConjugates[conjugates, rootValues, prime];
    check["rank " <> ToString[r] <> " mod " <> ToString[prime] <>
      ": conjugate projection is identical",
      AssociationQ[oldChannels] && oldChannels["Status"] === "OK" &&
        oldChannels["Channels"] === newChannels && newChannels === channels];
    (* grade multiplication: the duplicate multiplies branch by branch
       and projects, the neutral module multiplies in the grade basis *)
    leftChannels = Table[RandomInteger[{1, prime - 1}], {2^r}];
    rightChannels = Table[RandomInteger[{1, prime - 1}], {2^r}];
    oldProduct = oldProject[
      Mod[evaluateConjugates[leftChannels, rootValues, prime]
        evaluateConjugates[rightChannels, rootValues, prime], prime],
      rootValues, prime];
    check["rank " <> ToString[r] <> " mod " <> ToString[prime] <>
      ": grade multiplication is identical",
      AssociationQ[oldProduct] && oldProduct["Status"] === "OK" &&
        oldProduct["Channels"] === multiply[leftChannels, rightChannels,
          Mod[rootValues^2, prime], prime]];
  ],
  {r, 0, 3}, {prime, primes}];

(* ---- modular square roots: same class, different representative ---- *)
Do[
  Module[{p = 2147483423, squares, oldValues, newValues},
    squares = Mod[Table[RandomInteger[{1, p - 1}], {6}]^2, p];
    oldValues = oldSquareRoot[#, p] & /@ squares;
    newValues = squareRoots[squares, p];
    check["modular square roots agree up to the sign representative (trial " <>
      ToString[trial] <> ")",
      ListQ[newValues] && Mod[newValues^2 - squares, p] === ConstantArray[0, 6] &&
        oldValues === (Min[#, p - #] & /@ newValues)];
  ],
  {trial, 2}];

(* ---- canonical root order on the frame-realistic class ---- *)
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
oldOrder[squares_] := Module[{result},
  result = oldCanonicalize[declared[squares], {x, y}];
  If[Lookup[result, "Status", None] =!= "OK", Return[result]];
  Together /@ Lookup[result["Roots"], "RootSquare", {}]];

orderTrials = 0; orderAgreements = 0; orderStable = 0; orderPermutation = 0;
Do[
  Module[{squares, permutations, oldOrders, newOrders},
    squares = RandomSample[squarePool, RandomChoice[{1, 2, 3}]];
    (* only independent square classes are admissible input for either
       implementation; a dependent draw is exercised separately *)
    If[AnyTrue[Rest[Subsets[squares]], squareClassSquareQ[Times @@ #] &],
      Continue[]];
    permutations = RandomSample[Permutations[squares],
      UpTo[Min[3, Length[squares]!]]];
    oldOrders = oldOrder /@ permutations;
    newOrders = frameOrder /@ permutations;
    orderTrials++;
    If[AllTrue[oldOrders, ListQ] && AllTrue[newOrders, ListQ] &&
        Length[DeleteDuplicates[oldOrders]] === 1 &&
        Length[DeleteDuplicates[newOrders]] === 1, orderStable++];
    If[AllTrue[oldOrders, ListQ] && AllTrue[newOrders, ListQ] &&
        Sort[First[oldOrders]] === Sort[First[newOrders]], orderPermutation++];
    If[AllTrue[oldOrders, ListQ] && AllTrue[newOrders, ListQ] &&
        DeleteDuplicates[oldOrders] === DeleteDuplicates[newOrders],
      orderAgreements++];
  ],
  {trial, 12}];
check["both root orders are permutation invariant on every trial (" <>
  ToString[orderStable] <> "/" <> ToString[orderTrials] <> ")",
  orderTrials >= 8 && orderStable === orderTrials];
check["both root orders select the same root set on every trial (" <>
  ToString[orderPermutation] <> "/" <> ToString[orderTrials] <> ")",
  orderTrials >= 8 && orderPermutation === orderTrials];
Print["     measured root-order agreement: ", orderAgreements, "/", orderTrials,
  " (the two orders are different functions of the same set)"];

(* The duplicate's sort key is the printed text of the root square in
   the caller's symbols, and its FullForm is never reached: the
   Unevaluated wrapper survives into the key.  The neutral key is a
   canonical text in formal System` symbols.  A context-free key cannot
   reproduce a context-dependent one, so the orders differ; both facts
   are pinned because they decide what the deletion of the duplicate
   changes. *)
canonicalRules = FeynFacet`Private`multiquadraticStripCanonicalRules[{x, y}, eps];
canonicalText[expression_] :=
  FeynFacet`Private`multiquadraticStripCanonicalText[expression, canonicalRules];
contextSensitiveKey = Block[{$ContextPath = {"System`"}, $Context = "FeynFacet`"},
  oldStableKey[x]];
check["the duplicate's sort key never reaches FullForm",
  StringContainsQ[oldStableKey[1 + x + y], "Unevaluated"] &&
    ! StringContainsQ[oldStableKey[1 + x + y], "Plus["]];
check["the duplicate's sort key is context sensitive, the neutral key is not",
  oldStableKey[x] =!= contextSensitiveKey &&
    StringContainsQ[contextSensitiveKey, "Global`x"] &&
    canonicalText[x] === Block[
      {$ContextPath = {"System`"}, $Context = "FeynFacet`"}, canonicalText[x]]];
check["the two root orders are different functions of the same set",
  oldOrder[{x, 1 + x + y}] === {1 + x + y, x} &&
    frameOrder[{x, 1 + x + y}] === {x, 1 + x + y}];

(* ---- dependence screen ---- *)
check["both reject the rank-two square class {x, y, x y}",
  Lookup[oldCanonicalize[declared[{x, y, x y}], {x, y}], "Status", None] ===
      "DependentRootSquares" &&
    Lookup[frameOrder[{x, y, x y}], "Status", None] === "DependentRootSquares"];
check["both accept the independent class {x, y, 1 + x + y}",
  Lookup[oldCanonicalize[declared[{x, y, 1 + x + y}], {x, y}], "Status", None] ===
      "OK" && ListQ[frameOrder[{x, y, 1 + x + y}]]];
squareProbes = {x, x y, x^2, 4 x^2, x^2 y^2, (1 + x)^2/y^2, 9/4, x/y, 2, -x^2};
check["the square-class predicates agree verdict by verdict",
  AllTrue[squareProbes, oldSquareQ[#] === squareClassSquareQ[#] &] &&
    Sort[DeleteDuplicates[squareClassSquareQ /@ squareProbes]] === {False, True}];

(* ---- end to end: the duplicate's oracle channels are the exact
   channel decomposition evaluated in F_p ---- *)
Module[{n = 5, rows = {4, 5}, prime = 2147483423, regulator = 7/11, roots,
   declaredRoots, grades, connection, gauge, identity, preparation, evaluation,
   canonical, orderedRoots, point, deltaValues, rootValues, kinds, comparisons},
  declaredRoots = {<|"Root" -> Sqrt[1 + x + y], "RootSquare" -> 1 + x + y|>,
    <|"Root" -> Sqrt[x], "RootSquare" -> x|>,
    <|"Root" -> Sqrt[y], "RootSquare" -> y|>};
  canonical = oldCanonicalize[declaredRoots, {x, y}];
  check["the duplicate canonicalizes the declared rank-three roots",
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
  (* the duplicate refuses a point that is not split, so choose one *)
  point = SelectFirst[Table[{7 k + 3, 11 k + 5}, {k, 1, 400}],
    Function[candidate, AllTrue[{x, y, 1 + x + y},
      Function[delta, Module[{value = Mod[delta /. Thread[{x, y} -> candidate],
          prime]}, value =!= 0 && JacobiSymbol[value, prime] === 1]]]],
    Missing["NoSplitPoint"]];
  check["a split point exists for the declared rank-three frame",
    MatchQ[point, {_Integer, _Integer}]];
  preparation = mq["familyRowGaugeFiniteFieldPrepare"][connection, identity,
    identity, rows, gauge, {x, y}, declaredRoots];
  evaluation = mq["familyRowGaugeFiniteFieldEvaluate"][preparation, point,
    prime, {eps -> regulator}];
  check["the duplicate's oracle evaluates the randomized rank-three block",
    AssociationQ[preparation] && preparation["Status"] === "Prepared" &&
      AssociationQ[evaluation] && evaluation["Status"] === "OK" &&
      TrueQ[evaluation["HadamardRoundTrip"]]];
  deltaValues = Lookup[evaluation, "RootSquareValues", {}];
  rootValues = Lookup[evaluation, "CanonicalRootValues", {}];
  check["the canonical root values square to the reported root squares",
    Mod[rootValues^2 - deltaValues, prime] === ConstantArray[0, 3]];
  kinds = {"Connection", "Transformation", "Inverse"};
  comparisons = Flatten[Table[
    MapThread[
      Function[{compiled, evaluated}, Module[{expression, channels, images},
        (* the exact entry the duplicate compiled, with its root
           placeholders resolved back to the canonical roots *)
        expression = Total[Lookup[compiled["Terms"], "Expression", {}]] /.
          oldRoot[index_] :> orderedRoots[[index, "Root"]];
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
