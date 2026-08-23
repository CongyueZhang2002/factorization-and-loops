(* Exact, single-kernel adversarial equivalence gate for the staged sparse
   blockEquation construction.  This file is not loaded by FeynFacet and
   writes no artifact. *)

ClearAll[legacyBlockEquation, sparseDot, sparseBlockEquation, zeroQ];

legacyBlockEquation[connection_List, sector_Integer, lowerSector_Integer,
    solved_Association, ranges_List, epsilon_Symbol] := Module[
  {rk = ranges[[sector]], rj = ranges[[lowerSector]], higher},
  higher = Select[Keys[solved], lowerSector < # < sector &];
  {
    Table[Map[Together[#/epsilon] &,
      connection[[mu, rk, rk]], {2}], {mu, 2}],
    Table[Map[Together[#/epsilon] &,
      connection[[mu, rj, rj]], {2}], {mu, 2}],
    Table[Map[Together,
      connection[[mu, rk, rj]] -
        Sum[solved[m] . connection[[mu, ranges[[m]], rj]],
          {m, higher}], {2}], {mu, 2}]
  }
];

sparseDot[left_List, right_List] := Module[
  {leftSupport, rightSupport, common},
  If[! MatrixQ[left] || ! MatrixQ[right] ||
      left === {} || right === {} ||
      Length[First[left]] =!= Length[right], Return[$Failed]];
  leftSupport =
    Flatten[Position[#, Except[0], {1}, Heads -> False]] & /@ left;
  rightSupport =
    Flatten[Position[#, Except[0], {1}, Heads -> False]] & /@
      Transpose[right];
  Table[
    common = Intersection[leftSupport[[i]], rightSupport[[j]]];
    Which[
      common === {}, 0,
      Length[common] === 1,
        left[[i, First[common]]] right[[First[common], j]],
      True, Total[(left[[i, #]] right[[#, j]]) & /@ common]],
    {i, Length[left]}, {j, Length[First[right]]}]
];

sparseBlockEquation[connection_List, sector_Integer,
    lowerSector_Integer, solved_Association, ranges_List,
    epsilon_Symbol] := Module[
  {rk = ranges[[sector]], rj = ranges[[lowerSector]], e, c, bbar,
   higher, products},
  e = Table[Map[Together[#/epsilon] &,
    connection[[mu, rk, rk]], {2}], {mu, 2}];
  c = Table[Map[Together[#/epsilon] &,
    connection[[mu, rj, rj]], {2}], {mu, 2}];
  higher = Select[Keys[solved], lowerSector < # < sector &];
  bbar = Table[
    products = sparseDot[
        solved[m], connection[[mu, ranges[[m]], rj]]] & /@ higher;
    If[MemberQ[products, $Failed], Return[$Failed]];
    Map[Together,
      connection[[mu, rk, rj]] - Total[products], {2}],
    {mu, 2}];
  {e, c, bbar}
];

zeroQ[expression_] := AllTrue[Flatten[{expression}],
  TrueQ[Together[#] === 0] &];

ranges = {{1}, {2, 3}, {4, 5}, {6, 7}};
n = 7;
connection = ConstantArray[0, {2, n, n}];

(* Exact rational/algebraic diagonal blocks. *)
connection[[1, ranges[[1]], ranges[[1]]]] = {{eps/(1 - x)}};
connection[[2, ranges[[1]], ranges[[1]]]] = {{eps/(1 - y)}};
connection[[1, ranges[[2]], ranges[[2]]]] = eps {{1/x, 0},
  {(1 + y)/(1 - x y), -1/(1 + x)}};
connection[[2, ranges[[2]], ranges[[2]]]] = eps {{0, 1/y},
  {0, (1 + x)/(1 - x y)}};
connection[[1, ranges[[3]], ranges[[3]]]] = eps {{1/(1 + x), 0},
  {Sqrt[1 + x + y]/(1 - y), -1/(1 + y)}};
connection[[2, ranges[[3]], ranges[[3]]]] = eps {{1/(1 + y), 0},
  {0, Sqrt[1 + x + y]/(1 - x)}};
connection[[1, ranges[[4]], ranges[[4]]]] = eps {{1/x, 0},
  {0, 1/(1 - x y)}};
connection[[2, ranges[[4]], ranges[[4]]]] = eps {{1/y, 0},
  {0, 1/(1 - x y)}};

(* Lower blocks include literal zeros, shared denominators, radicals, and
   deliberately deferred uncombined Plus/Times trees. *)
connection[[1, ranges[[2]], ranges[[1]]]] =
  {{1/(1 - x)}, {Sqrt[1 + x + y]/(1 - y)}};
connection[[2, ranges[[2]], ranges[[1]]]] =
  {{0}, {(1 + x)/(1 - x y)}};
connection[[1, ranges[[3]], ranges[[1]]]] =
  {{x/(1 - y)}, {0}};
connection[[2, ranges[[3]], ranges[[1]]]] =
  {{1/(1 - x y)}, {y/(1 - x)}};
connection[[1, ranges[[3]], ranges[[2]]]] =
  {{0, 1/(1 + x)}, {Sqrt[1 + x + y]/(1 - y), 0}};
connection[[2, ranges[[3]], ranges[[2]]]] =
  {{1/(1 + y), 0}, {0, x/(1 - x y)}};
connection[[1, ranges[[4]], ranges[[1]]]] =
  {{1/(1 - x) + x/(1 - x y) +
      Sqrt[1 + x + y]/((1 - x) (1 - y))},
   {0}};
connection[[2, ranges[[4]], ranges[[1]]]] =
  {{y/(1 - y) + x y/(1 - x y)},
   {1/(1 + x) + 1/(1 + y)}};
connection[[1, ranges[[4]], ranges[[2]]]] =
  {{1/(1 - x), 0}, {x/(1 - x y), y/(1 - y)}};
connection[[2, ranges[[4]], ranges[[2]]]] =
  {{0, 1/(1 - y)}, {Sqrt[1 + x + y]/(1 - x y), 0}};
connection[[1, ranges[[4]], ranges[[3]]]] =
  {{1/(1 + x), 0}, {0, 1/(1 + y)}};
connection[[2, ranges[[4]], ranges[[3]]]] =
  {{0, 1/(1 - x)}, {y/(1 - y), 0}};

solved32 = {{0, x/(1 - x)}, {1/(1 + y), 0}};
solved43 = {{1/(1 - x y), 0},
  {Sqrt[1 + x + y]/(1 - x), y/(1 - y)}};
solved42 = {{0, 1/(1 + x)},
  {x/(1 - x y), 0}};

solvedDescending = <|3 -> solved43, 2 -> solved42|>;
solvedAscending = <|2 -> solved42, 3 -> solved43|>;

cases = {
  <|"Name" -> "empty-higher", "Sector" -> 4, "Lower" -> 3,
    "Solved" -> solvedDescending|>,
  <|"Name" -> "one-higher", "Sector" -> 4, "Lower" -> 2,
    "Solved" -> solvedDescending|>,
  <|"Name" -> "two-higher-descending", "Sector" -> 4, "Lower" -> 1,
    "Solved" -> solvedDescending|>,
  <|"Name" -> "two-higher-ascending", "Sector" -> 4, "Lower" -> 1,
    "Solved" -> solvedAscending|>
};

caseResults = Table[
  legacy = legacyBlockEquation[connection, item["Sector"], item["Lower"],
    item["Solved"], ranges, eps];
  candidate = sparseBlockEquation[connection, item["Sector"],
    item["Lower"], item["Solved"], ranges, eps];
  <|"Name" -> item["Name"],
    "SameQ" -> SameQ[candidate, legacy],
    "ExactResidualZero" -> zeroQ[candidate - legacy],
    "Dimensions" -> Dimensions[candidate]|>,
  {item, cases}];

dotLeft = {{0, 1/(1 - x), 0},
  {Sqrt[1 + x + y], 0, y/(1 - y)}};
dotRight = {{1, 0}, {0, 1/(1 + x)},
  {x/(1 - x y), 0}};
dotCandidate = sparseDot[dotLeft, dotRight];
dotLegacy = dotLeft . dotRight;

checks = <|
  "AllBlockEquationSameQ" -> AllTrue[caseResults, TrueQ[#SameQ] &],
  "AllBlockEquationResidualsZero" ->
    AllTrue[caseResults, TrueQ[#ExactResidualZero] &],
  "SparseDotSameQAfterTogether" ->
    SameQ[Map[Together, dotCandidate, {2}],
      Map[Together, dotLegacy, {2}]],
  "SparseDotResidualZero" -> zeroQ[dotCandidate - dotLegacy],
  "MalformedInnerDimensionFailsClosed" ->
    sparseDot[{{1, 2}}, {{1, 2}}] === $Failed
|>;

report = <|"Status" -> If[And @@ (TrueQ /@ Values[checks]),
    "PASS", "FAIL"], "Checks" -> checks, "Cases" -> caseResults|>;
Print[report];
If[report["Status"] === "PASS", report, $Failed]
