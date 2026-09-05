#!/usr/bin/env wolframscript
(* The Kallen23 coordinate map into the declared field, and the exact
   algebraic round-trip zero test it feeds (commit 5a8cf88, 2026-08-25).

   WHY THIS TEST EXISTS.  Commit 5a8cf88 removed the production blocker
   of CF303 {17,12}: the inverse of the Kallen23 chart map carries a
   NESTED radical, the strip-gauge round trip compared its images with
   Together, and Together is not canonical on an expression carrying a
   radical -- so a correct gauge was rejected at every sign branch.  The
   fix rewrites the nested radical into the frame's DECLARED radicals and
   decides the comparison with the r-symbol reduction.  The production
   CF303 run is strong evidence, but it is not a test; this suite is the
   deterministic one, ported from the diagnostic mutants of 2026-08-25.

   It is CLONE-GREEN and self-contained: the frame is registered here
   from CF303's three exact root squares (five short polynomials), not
   read from campaign state, and every check is exact symbolic algebra --
   no kernel arithmetic, no fixture file, seconds of wall time.

   ACCEPTANCE CRITERIA, stated before the run.
   A  The algebraic zero test decides the declared field: exact zeros
      that Together cannot see are True, honest inequalities are False,
      rational-square multiples of a declared square are the same
      generator, and a radical OUTSIDE the declared field is refused
      typed ($Failed) -- never silently answered False.
   B  The canonicalization of the Kallen23 inverse rewrites exactly the
      one nested base, leaves only declared radicals standing, and is
      value-preserving.
   C  The round trip ACCEPTS the exact canonical map on exactly one sign
      branch, and the RAW nested map is rejected at every branch with the
      typed undeclared-radical refusal (the production failure mode).
   D  MUTANTS: a multiplicatively scaled map image, an additively
      perturbed map image, a scaled root image and swapped root images
      are each rejected -- and rejected by an HONEST zero test, with no
      refusal raised, so the comparator is not merely failing closed. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, got_, want_] := If[got === want, pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label, ": got ", Short[got, 6], " want ",
    Short[want, 6]]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
fp[name_String] := Symbol["FeynFacet`Private`" <> name];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"];

(* CF303's declared field, verbatim from the project's family-chart table
   (three root squares in the source variables).  Kept inline so a fresh
   clone runs this suite without any campaign artifact. *)
cf303RootSquares = {
  (1 + vv - ww)^2 + 4 vv ww,
  (1 - vv + ww)^2 + 4 vv ww,
  1 - 4 vv ww};
registration = FeynFacet`RegisterFamilyRootData[
  <|"CF303CoordinateMapTest" ->
    <|"SourceRadicands" -> cf303RootSquares|>|>];
check["the three-root generator presentation registers",
  Lookup[registration, "Status", None], "FamilyRootDataRegistered"];
frame = FeynFacet`FamilyRootData["CF303CoordinateMapTest"];
check["the registered data is a V2 square-root-generator presentation",
  AssociationQ[frame] && Lookup[frame, "DataType", None] ===
    "SquareRootGeneratorsAndQuadraticRelations" &&
    Lookup[frame, "SchemaVersion", None] === 2, True];
variables = {vv, ww};
{xv, yv} = variables;
allRoots = fp["coefficientPresentationSquareRootsInVariables"][
  frame, variables];
check["the frame carries three declared roots", Length[allRoots], 3];
usedRoots = allRoots[[{1, 2}]];
rootSquares = Lookup[usedRoots, "QuadraticRadicand", {}];
{q1, q2, q3} = Lookup[allRoots, "QuadraticRadicand", {}];
r1 = Sqrt[q1]; r2 = Sqrt[q2];
algebraicZeroQ = fp["transportChartAlgebraicZeroQ"];

(* ---------------- A: the exact algebraic zero test ---------------- *)
e1 = 1/(1 + r1) - (1 - r1)/(1 - q1);
check["A1 an exact zero over the declared field is True",
  algebraicZeroQ[e1, allRoots], True];
e2 = Sqrt[4 q1] Sqrt[9 q2] - 6 r1 r2;
check["A1b a two-root exact zero is True", algebraicZeroQ[e2, allRoots], True];
report["MEASURED Together sees these zeros",
  {TrueQ[Together[e1] === 0], TrueQ[Together[e2] === 0]}];
check["A2 an honest inequality is False",
  algebraicZeroQ[e1 + 1/1000, allRoots], False];
check["A2b a difference of two distinct roots is False",
  algebraicZeroQ[r1 - r2, allRoots], False];
check["A2c a rational multiple of a root is False",
  algebraicZeroQ[2 r1 - r1, allRoots], False];
check["A3 a rational-square multiple is the same generator",
  algebraicZeroQ[Sqrt[4 q1] - 2 r1, allRoots], True];
check["A3b with the wrong factor it is False",
  algebraicZeroQ[Sqrt[4 q1] - 3 r1, allRoots], False];
check["A4 the product of two declared roots reduces",
  algebraicZeroQ[(r1 r2)^2 - q1 q2, allRoots], True];
check["A5 a radical OUTSIDE the declared field is REFUSED typed, not rejected",
  algebraicZeroQ[Sqrt[1 + xv + 3 yv] - r1, allRoots], $Failed];
check["A6 a radical-free zero keeps the rational fast path",
  algebraicZeroQ[xv/(1 + xv) - 1 + 1/(1 + xv), allRoots], True];
check["A6b a radical-free nonzero is False",
  algebraicZeroQ[xv/(1 + xv), allRoots], False];

(* ------- B: canonicalization of the real Kallen23 inverse -------- *)
chart = FeynFacet`LookupCataloguedRationalizingParametrizationForRoots[rootSquares, variables];
check["the two-root subset of CF303 is the catalogued Kallen23 chart",
  AssociationQ[chart] && Lookup[chart, "Name", None] === "Kallen23", True];
chartVariables = {Symbol["FeynFacet`Private`kallen23TestX"],
  Symbol["FeynFacet`Private`kallen23TestY"]};
rekeyed = fp["rekeyCoefficientPresentation"][
  chart, variables, chartVariables];
data = fp["masterTransportCoefficientPresentationData"][
  rekeyed, variables];
check["the chart data is well formed", Lookup[data, "Status", None], "OK"];
chartRoots = Lookup[rekeyed, "RationalizedSquareRoots", {}];
rootImages = Table[Module[{matching = SelectFirst[chartRoots,
     TrueQ[Together[#1["SourceRadicand"] -
       usedRoots[[i]]["SourceRadicand"]] === 0] &,
     Missing["RootNotRationalized"]]},
   If[MissingQ[matching], matching, matching["RationalRoot"]]],
  {i, Length[usedRoots]}];
check["both declared roots become RATIONAL images in the chart",
  AllTrue[rootImages, ! MissingQ[#1] && FreeQ[#1, Power[_, _Rational]] &], True];
identityData = fp["masterTransportCoefficientPresentationData"][
  frame, variables];
coordinateMap = fp["masterTransportRecordCoordinateMap"][
  <|"CoefficientVariables" -> chartVariables,
    "RationalizingParametrization" -> rekeyed|>, identityData];
presentationToVariables = Thread[
  frame["CoefficientVariables"] -> variables];
rawCoordinateRules = coordinateMap["CoefficientVariableRules"] /.
  presentationToVariables;
rawImages = coordinateMap["CoefficientVariableImages"] /.
  presentationToVariables;
check["the RAW inverse map carries a radical the declared field does not name",
  AnyTrue[Cases[rawImages, Power[base_, _Rational] :> Together[base],
    {0, Infinity}],
    Function[base, ! AnyTrue[{q1, q2, q3},
      TrueQ[Together[base/#1] === 1] &] &&
      ! FreeQ[base, Power[_, _Rational]]]], True];
canon = fp["transportChartCanonicalizeFrameImages"][
  rawImages, allRoots, variables];
report["canonicalization", KeyTake[canon, {"Status", "Rewritten"}]];
check["B1 the canonicalization succeeds", Lookup[canon, "Status", None], "OK"];
check["B2 exactly ONE nested base is rewritten", canon["Rewritten"], 1];
check["B3 only the two declared radicals survive",
  Sort[DeleteDuplicates[Cases[canon["Images"],
    Power[base_, _Rational] :> Together[base], {0, Infinity}]]] ===
    Sort[{Together[q1], Together[q2]}], True];
check["B4 the rewrite is value preserving (40-digit witness at two points)",
  AllTrue[{{xv -> 17/97, yv -> 23/89}, {xv -> 11/53, yv -> 7/61}},
    Function[point, AllTrue[Range[2], Function[i,
      Abs[N[(canon["Images"][[i]] - rawImages[[i]]) /. point, 40]] <
        10^-30]]]], True];

(* ------ C: the round trip, canonical map versus the raw map ------ *)
{cx, cy} = chartVariables;
refusals = {};
zeroMatrixQ[matrix_] := Module[{entries},
  entries = Flatten[Map[Together, matrix, {2}]];
  AllTrue[entries, Function[entry,
    If[FreeQ[entry, Power[_, _Rational]], TrueQ[entry === 0],
      Module[{verdict = algebraicZeroQ[entry, allRoots]},
        If[verdict === $Failed, AppendTo[refusals, entry]; False,
          TrueQ[verdict]]]]]]];
roundTrip[gauge_, map_, images_] := Select[Tuples[{1, -1}, 2],
  Function[signs, Module[{branchImages, brancheoffDiagonalBasisTransformationBlock},
    branchImages = MapThread[Times, {signs, images}];
    brancheoffDiagonalBasisTransformationBlock = fp["transportChartApplyRootBranches"][
      Map[Together, gauge /. map, {2}], usedRoots, branchImages];
    zeroMatrixQ[(brancheoffDiagonalBasisTransformationBlock /.
      data["SourceVariableSubstitution"]) - gauge]]]];
canonicalMap = MapThread[Rule, {chartVariables, canon["Images"]}];
gaugeOne = {{1/(cx - cy)}};
gaugeTwo = {{cx^2 cy^3/((cx - cy) (1 + cx) (1 - cy)), cy/(1 + cx)},
  {1, cx cy}};
refusals = {};
check["C1 the canonical map is accepted on exactly the all-plus branch",
  roundTrip[gaugeOne, canonicalMap, rootImages], {{1, 1}}];
check["C2 it is accepted for a 2x2 gauge as well",
  roundTrip[gaugeTwo, canonicalMap, rootImages], {{1, 1}}];
refusals = {};
check["C3 the RAW nested map is rejected at EVERY branch (the production \
failure of CF303 {17,12})",
  roundTrip[gaugeOne, rawCoordinateRules, rootImages], {}];
check["C3b and it is refused TYPED as an undeclared radical, never silently \
answered False", refusals =!= {}, True];

(* ---------------------- D: the mutants -------------------------- *)
mutantScaled = MapThread[Rule, {chartVariables,
  {canon["Images"][[1]] (1 + xv), canon["Images"][[2]]}}];
refusals = {};
check["D1 a multiplicatively scaled map image is rejected",
  roundTrip[gaugeOne, mutantScaled, rootImages], {}];
check["D1b rejected by an honest zero test, with no refusal raised",
  refusals, {}];
mutantShifted = MapThread[Rule, {chartVariables,
  {canon["Images"][[1]] + 1/1000, canon["Images"][[2]]}}];
refusals = {};
check["D2 an additively perturbed map image is rejected",
  roundTrip[gaugeOne, mutantShifted, rootImages], {}];
check["D2b rejected honestly", refusals, {}];
refusals = {};
check["D3 a scaled ROOT image is rejected",
  roundTrip[gaugeOne, canonicalMap, {rootImages[[1]] (1 + cx),
    rootImages[[2]]}], {}];
check["D3b rejected honestly", refusals, {}];
refusals = {};
check["D4 SWAPPED root images are rejected",
  roundTrip[gaugeOne, canonicalMap, Reverse[rootImages]], {}];
check["D4b rejected honestly", refusals, {}];
check["D5 a nonzero matrix over the field is not zero",
  zeroMatrixQ[{{r1 - r2}}], False];
check["D5b a zero matrix over the field is zero",
  zeroMatrixQ[{{1/(1 + r1) - (1 - r1)/(1 - q1)}}], True];

Print["t_kallen23_coordinate_map: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
