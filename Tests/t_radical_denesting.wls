#!/usr/bin/env wolframscript
(* Exact denesting of nested and numeric radical bases against a declared
   multiquadratic root set (2026-08-24, CF303).

   WHY.  transportChartRootIndices matched a radical only when its
   radicand IS a declared root square, so the CF303 family connection --
   whose radicands include q2 (u + v Sqrt[q1]) and the bare constant 2 --
   was refused as "ConnectionContainsUndeclaredRadicals" although both
   radicands lie in the declared field.

   THE MATHEMATICS, re-derived here and asserted, not assumed.  With
     q1 = 1 + 2x + x^2 - 2y + 2xy + y^2,  q2 = 1 - 2x + x^2 + 2y + 2xy + y^2,
     u  = 1 + 2x + x^2 + 2xy + y^2,       v  = 1 + x + y,
   one has v^2 = u + 2y and q1 = u - 2y, hence the Fermat discriminant
     w^2 = u^2 - v^2 q1 = 4 y^2,  w = 2y  exactly,
   and u + w = v^2, so
     2 (u + v Sqrt[q1]) = (v + Sqrt[q1])^2,
     2 (u - v Sqrt[q1]) = (v - Sqrt[q1])^2.
   The square class of q2 (u +- v Sqrt[q1]) is therefore 2 q2: declared
   root 2 times the numeric class 2, no new field extension.

   ACCEPTANCE CRITERIA, stated before the run.

   (a) UNIT.  transportChartDenestRadicalBase on q2 (u + v Sqrt[q1])
       returns "Denested" with RootIndices {2} (the declared list is
       {q1, q2, q3}, 1-indexed), NumericClass 2, InnerRootIndices {1},
       Fermat witness w = 2y, alpha = 1 + x + y, beta = 1, c = 2; on the
       numeric radicand 2 it returns RootIndices {} and NumericClass 2.
   (b) SIGN AND EXACTNESS.  The rewrite squares back to the base exactly
       (Together after the r-substitution), the sign returned by
       transportChartDenestSign is +1 here, and the signed rewrite agrees
       with the principal square root numerically at three points of the
       region where every declared square is positive (30 digits, 1e-20).
   (c) ADVERSARIAL.  A genuinely new radicand (1 + x^3 y) stays
       unclassified and stays in UnclassifiedRadicalBases; a radicand
       nesting TWO declared roots returns the typed
       "NestedMultiRootRadical"; a radicand that nests one declared root
       but does not denest (1 + Sqrt[q1]) returns "NotDenestable"
       ("DiscriminantNotASquare"); the SIGN-FLIPPED q2 (u - v Sqrt[q1])
       denests to the SAME class {2} with NumericClass 2 and the rewrite
       Sqrt[q2] (v - Sqrt[q1])/Sqrt[2], which is what the derivation
       above demands -- never a different classification.
       No previously classified input changes: a radical set free of
       nested and numeric radicands produces the identical RootIndices,
       RadicalBases and (empty) UnclassifiedRadicalBases, with an empty
       DenestedRadicalBases.
   (d) REAL DATA, on a FROZEN fixture.  On the 27x27 truncation of the
       frozen CF303 family state (FrozenTestFixtures_2026-08-25/, see the
       README there) the classifier reports ZERO unclassified radical
       bases and RootIndices {1, 2}, and the used root pair selects the
       catalogued chart Kallen23.  Those 27 rows are the sectors the
       producing run had completed, so the connection is the one the
       campaign banked: its radicands are the declared squares q1 and q2
       themselves, with no nested and no numeric radicand, the
       canonicalization is a verified no-op, and
       FactorFamilyRegulatorDependenceInFrame returns "AlreadyEpsFactored"
       -- which is re-derived here directly from the truncation rather
       than believed.  All values MEASURED on the fixture 2026-08-25.
       The denesting rewrite itself is exercised on constructed data in
       (a), (b) and (c); what (d) certifies is that the classifier is
       clean on real campaign data.
   Consumers of the classifier that were NOT extended to nested or
   numeric radicals must still fail closed: SolveEpsFormStripInFrame
   returns the typed "StripContainsDenestedRadicals". *)

root = ExpandFileName[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

private[name_String] := Symbol["FeynFacet`Private`" <> name];
{denest, denestSign, canonicalize, rootIndices, currentRoots} = private /@
  {"transportChartDenestRadicalBase", "transportChartDenestSign",
   "transportChartCanonicalizeDenestedRadicals", "transportChartRootIndices",
   "transportChartCurrentRoots"};

v = Symbol["Global`v"]; w = Symbol["Global`w"];
x = Symbol["Global`x"]; y = Symbol["Global`y"]; eps = Symbol["Global`eps"];
Clear[v, w, x, y, eps];

(* zero test for an expression polynomial in the declared radicals *)
zeroRadicalQ[expression_] := TrueQ[Together[Expand[expression]] === 0];
symbolicRadicalBases[expression_] := DeleteDuplicates[Cases[expression,
  Power[b_ /; ! NumericQ[b], e_Rational /; Denominator[e] === 2] :> Together[b],
  {0, Infinity}, Heads -> True]];

lambda1[a_, b_] := (1 - a - b)^2 - 4 a b;
(* the CF303 root set: lambda2, lambda3 and 1 - 4 v w *)
sourceSquares = {lambda1[-v, w], lambda1[v, -w], 1 - 4 v w};
frame = BuildAlgebraicTransportFrame[sourceSquares, {v, w}, {x, y}];
FTAssert["the CF303-shaped multiquadratic frame is exact",
  AssociationQ[frame] && frame["Status"] === "ExactFrame" &&
    Length[frame["Roots"]] === 3 &&
    frame["ChartCertificate", "RootIdentities"] === {True, True, True}];

roots = currentRoots[frame, {x, y}];
q = Lookup[roots, "RootSquare", {}];
{q1, q2, q3} = q;
FTAssert["the declared squares are the CF303 triple in the chart variables",
  TrueQ[Together[q1 - (1 + 2 x + x^2 - 2 y + 2 x y + y^2)] === 0] &&
    TrueQ[Together[q2 - (1 - 2 x + x^2 + 2 y + 2 x y + y^2)] === 0] &&
    TrueQ[Together[q3 - (1 - 4 x y)] === 0]];

u = 1 + 2 x + x^2 + 2 x y + y^2; vv = 1 + x + y;
(* the derivation, asserted independently of the implementation *)
FTAssert["v^2 = u + 2y and q1 = u - 2y, so u^2 - v^2 q1 = (2y)^2",
  TrueQ[Together[vv^2 - (u + 2 y)] === 0] &&
    TrueQ[Together[q1 - (u - 2 y)] === 0] &&
    TrueQ[Together[u^2 - vv^2 q1 - 4 y^2] === 0]];
FTAssert["2 (u +- v Sqrt[q1]) = (v +- Sqrt[q1])^2 exactly",
  zeroRadicalQ[(vv + Sqrt[q1])^2 - 2 (u + vv Sqrt[q1])] &&
    zeroRadicalQ[(vv - Sqrt[q1])^2 - 2 (u - vv Sqrt[q1])]];

base1 = q2 (u + vv Sqrt[q1]);
base1Flipped = q2 (u - vv Sqrt[q1]);
base2 = 2;

(* ------------------------------------------------------------------ *)
(* (a) unit                                                             *)
(* ------------------------------------------------------------------ *)
d1 = denest[base1, roots, {x, y}];
FTAssert["(a) the nested CF303 base denests to root class {2}, numeric class 2",
  AssociationQ[d1] && d1["Status"] === "Denested" &&
    d1["RootIndices"] === {2} && d1["NumericClass"] === 2 &&
    d1["Residual"] === 1 && d1["InnerRootIndices"] === {1}];
FTAssert["(a) the Fermat witness is w = 2y, alpha = 1+x+y, beta = 1, c = 2",
  AssociationQ[d1] && d1["Witness"]["Kind"] === "Fermat" &&
    TrueQ[Together[d1["Witness"]["w"] - 2 y] === 0] &&
    TrueQ[Together[d1["Witness"]["u"] - u] === 0] &&
    TrueQ[Together[d1["Witness"]["v"] - vv] === 0] &&
    TrueQ[Together[d1["Witness"]["Alpha"] - (1 + x + y)] === 0] &&
    TrueQ[Together[d1["Witness"]["Beta"] - 1] === 0] &&
    TrueQ[Together[d1["Witness"]["Coefficient"] - 2] === 0]];
d2 = denest[base2, roots, {x, y}];
FTAssert["(a) the numeric base 2 needs no chart: root class {}, numeric class 2",
  AssociationQ[d2] && d2["Status"] === "Denested" &&
    d2["RootIndices"] === {} && d2["NumericClass"] === 2 &&
    TrueQ[Together[d2["Rewrite"] - Sqrt[2]] === 0]];

(* ------------------------------------------------------------------ *)
(* (b) sign and exactness                                              *)
(* ------------------------------------------------------------------ *)
FTAssert["(b) the rewrite squares back to the base exactly",
  TrueQ[d1["SquareIdentity"]] &&
    zeroRadicalQ[d1["Rewrite"]^2 - base1]];
signData = denestSign[base1, d1["Rewrite"], roots, {x, y}];
FTAssert["(b) the global sign is fixed and is +1, from two agreeing points",
  AssociationQ[signData] && signData["Status"] === "OK" &&
    signData["Sign"] === 1 && Length[signData["Points"]] === 2];
numericPoints = {{x -> 1/4, y -> 1/6}, {x -> 1/7, y -> 1/13}, {x -> 2/9, y -> 3/11}};
FTAssert["(b) the signed rewrite matches the principal root at 3 points (30 digits)",
  AllTrue[numericPoints, Function[point,
    Module[{lhs = Sqrt[N[base1 /. point, 30]],
        rhs = signData["Sign"] N[d1["Rewrite"] /. point, 30]},
      TrueQ[Abs[lhs - rhs] < 10^-20 Max[1, Abs[lhs]]]]]]];
FTAssert["(b) the closed form is Sqrt[q2] (1+x+y+Sqrt[q1])/Sqrt[2]",
  zeroRadicalQ[d1["Rewrite"] - Sqrt[q2] (1 + x + y + Sqrt[q1])/Sqrt[2]]];

(* ------------------------------------------------------------------ *)
(* (c) adversarial                                                      *)
(* ------------------------------------------------------------------ *)
newRadical = 1 + x^3 y;
dNew = denest[newRadical, roots, {x, y}];
FTAssert["(c) a genuinely new radicand is not denested",
  AssociationQ[dNew] && dNew["Status"] === "NotDenestable" &&
    dNew["Reason"] === "UnclassifiedSquareClass"];
clsNew = rootIndices[{Sqrt[newRadical], Sqrt[q1]}, roots];
FTAssert["(c) a new radicand stays in UnclassifiedRadicalBases",
  Length[clsNew["UnclassifiedRadicalBases"]] === 1 &&
    TrueQ[Together[First[clsNew["UnclassifiedRadicalBases"]] - newRadical] === 0] &&
    clsNew["RootIndices"] === {1} && clsNew["DenestedRadicalBases"] === <||>];
dMulti = denest[1 + Sqrt[q1] + Sqrt[q2], roots, {x, y}];
FTAssert["(c) a radicand nesting two declared roots is typed, not classified",
  AssociationQ[dMulti] && dMulti["Status"] === "NestedMultiRootRadical" &&
    dMulti["InnerRootIndices"] === {1, 2} &&
    ! KeyExistsQ[dMulti, "RootIndices"]];
dHard = denest[1 + Sqrt[q1], roots, {x, y}];
FTAssert["(c) a nested radicand that does not denest is typed NotDenestable",
  AssociationQ[dHard] && dHard["Status"] === "NotDenestable" &&
    dHard["Reason"] === "DiscriminantNotASquare"];
clsHard = rootIndices[{Sqrt[1 + Sqrt[q1]]}, roots];
FTAssert["(c) a non-denestable nested radicand stays unclassified",
  Length[clsHard["UnclassifiedRadicalBases"]] === 1 &&
    clsHard["DenestedRadicalBases"] === <||>];
dFlip = denest[base1Flipped, roots, {x, y}];
FTAssert["(c) the sign-flipped base denests to the SAME class {2}, numeric 2",
  AssociationQ[dFlip] && dFlip["Status"] === "Denested" &&
    dFlip["RootIndices"] === {2} && dFlip["NumericClass"] === 2 &&
    dFlip["InnerRootIndices"] === {1}];
FTAssert["(c) the sign-flipped rewrite is Sqrt[q2] (1+x+y-Sqrt[q1])/Sqrt[2]",
  zeroRadicalQ[dFlip["Rewrite"] - Sqrt[q2] (1 + x + y - Sqrt[q1])/Sqrt[2]] &&
    zeroRadicalQ[dFlip["Rewrite"]^2 - base1Flipped]];
flipSign = denestSign[base1Flipped, dFlip["Rewrite"], roots, {x, y}];
FTAssert["(c) the sign-flipped rewrite carries sign +1 (v - Sqrt[q1] > 0 in the region)",
  AssociationQ[flipSign] && flipSign["Status"] === "OK" && flipSign["Sign"] === 1 &&
    AllTrue[numericPoints, Function[point,
      Module[{lhs = Sqrt[N[base1Flipped /. point, 30]],
          rhs = flipSign["Sign"] N[dFlip["Rewrite"] /. point, 30]},
        TrueQ[Abs[lhs - rhs] < 10^-20 Max[1, Abs[lhs]]]]]]];

(* the classifier ABI: nothing changes where nothing is denested *)
plain = {Sqrt[q1], Sqrt[q3], q2, (1 - x - y + Sqrt[q1])/(1 - x - y - Sqrt[q1])};
clsPlain = rootIndices[plain, roots];
FTAssert["(c) a radical set with no nested or numeric radicand is classified as before",
  clsPlain["RootIndices"] === {1, 3} &&
    clsPlain["UnclassifiedRadicalBases"] === {} &&
    clsPlain["DenestedRadicalBases"] === <||> &&
    clsPlain["NumericRadicalClasses"] === {} &&
    Length[clsPlain["RadicalBases"]] === 2];

(* the classifier ABI: a denested base leaves the unclassified list and
   contributes both its square class and the roots inside its rewrite *)
clsMixed = rootIndices[{Sqrt[base1], Sqrt[2], Sqrt[q3]}, roots];
FTAssert["(c) denested bases leave UnclassifiedRadicalBases and gain their indices",
  clsMixed["UnclassifiedRadicalBases"] === {} &&
    clsMixed["RootIndices"] === {1, 2, 3} &&
    clsMixed["NumericRadicalClasses"] === {2} &&
    Length[clsMixed["DenestedRadicalBases"]] === 2];
canMixed = canonicalize[{Sqrt[base1], Sqrt[2], Sqrt[q3]}, roots, {x, y},
  clsMixed["DenestedRadicalBases"]];
FTAssert["(c) canonicalization rewrites only the symbolic nested radical",
  canMixed["Status"] === "OK" && canMixed["Rewritten"] === 1 &&
    Module[{residual = symbolicRadicalBases[canMixed["Expression"]]},
      Length[residual] === 3 && AllTrue[{q1, q2, q3}, Function[declared,
        AnyTrue[residual, TrueQ[Together[# - declared] === 0] &]]]]];
FTAssert["(c) the canonicalized expression is the same function numerically",
  AllTrue[numericPoints, Function[point,
    Max[Abs[N[(canMixed["Expression"] - {Sqrt[base1], Sqrt[2], Sqrt[q3]}) /. point,
      30]]] < 10^-20]]];

(* consumers that were not extended must still fail closed *)
strip = {{{{eps/(1 - x)}}, {{0}}}, {{{0}}, {{0}}}, {{{Sqrt[base1]}}, {{0}}}};
stripResult = SolveEpsFormStripInFrame[strip, {x, y}, eps, frame];
FTAssert["(c) the strip solver stops, typed, on a denested radical",
  AssociationQ[stripResult] &&
    stripResult["Status"] === "StripContainsDenestedRadicals" &&
    stripResult["NumericRadicalClasses"] === {2}];

(* ------------------------------------------------------------------ *)
(* (d) the real CF303 truncation                                        *)
(* ------------------------------------------------------------------ *)
(* THE INPUT IS FROZEN.  Until 2026-08-25 this block read the LIVE campaign
   state FamilyEpsFormsSolving/triple_root_2026-08-24_fable/CF303/... , which
   every mission of the triple-root campaign rewrites; its assertions then
   described whatever sector a run happened to have reached, and went red
   with no code change when round 4 advanced CF303 past sector 16.  The input
   is now the immutable copy under FrozenTestFixtures_2026-08-25/ (provenance
   in that directory's README) and the statements below are properties of
   that FIXED matrix. *)
results = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
stateFile = FileNameJoin[{results, "FamilyEpsFormsSolving",
  "FrozenTestFixtures_2026-08-25", "sector_state_CF303_standard.wl"}];
FTAssert["(d) the frozen CF303 fixture is in the repository",
  FileExistsQ[stateFile] &&
    FileExistsQ[FileNameJoin[{results, "TransportFamilyCharts.wl"}]]];
registration = TransportFamilyChartLoad[
  FileNameJoin[{results, "TransportFamilyCharts.wl"}]];
FTAssert["(d) the project family-chart inventory registers",
  registration["Status"] === "FamilyChartsRegistered"];
cf303Frame = TransportFamilyChart["CF303"];
FTAssert["(d) CF303 is registered on a rank-3 multiquadratic frame",
  AssociationQ[cf303Frame] && cf303Frame["Status"] === "ExactFrame" &&
    cf303Frame["Name"] === "Multiquadratic3"];
state = FamilyArtifactRead[stateFile];
FTAssert["(d) the frozen CF303 fixture reads back with the schema this \
block consumes: a 45x45 two-variable connection in 25 sector ranges",
  AssociationQ[state] &&
    Dimensions[Lookup[state, "A", {}]] === {2, 45, 45} &&
    Length[Lookup[state, "Ranges", {}]] === 25];
truncation = {state["A"][[1, 1 ;; 27, 1 ;; 27]], state["A"][[2, 1 ;; 27, 1 ;; 27]]};
cf303Roots = currentRoots[cf303Frame, {x, y}];
cf303Class = rootIndices[truncation, cf303Roots];
(* MEASURED on the frozen fixture, 2026-08-25.  The 27 rows are exactly the
   sectors 1..16 the producing run had completed, so the connection here is
   the one the campaign BANKED: its radicands are the two declared squares
   q1 and q2 themselves, with no nested and no numeric radicand left.  The
   classifier must therefore leave nothing unclassified and must report NO
   denesting -- the denesting machinery is exercised on constructed data in
   (a), (b) and (c) above; what this block certifies on real data is that
   the classifier is CLEAN on it. *)
FTAssert["(d) the 27x27 truncation has no unclassified radical base",
  cf303Class["UnclassifiedRadicalBases"] === {} &&
    cf303Class["RootIndices"] === {1, 2}];
FTAssert["(d) the frozen truncation carries the declared squares directly: \
no nested and no numeric radicand",
  cf303Class["RadicalBases"] =!= {} &&
    AllTrue[cf303Class["RadicalBases"], Function[base,
      AnyTrue[{q1, q2, q3}, TrueQ[Together[base - #] === 0] &]]] &&
    cf303Class["NumericRadicalClasses"] === {} &&
    cf303Class["DenestedRadicalBases"] === <||>];
cf303Canonical = canonicalize[truncation, cf303Roots, {x, y},
  cf303Class["DenestedRadicalBases"]];
FTAssert["(d) canonicalization is a verified no-op on it, and returns the \
truncation unchanged",
  cf303Canonical["Status"] === "OK" && cf303Canonical["Rewritten"] === 0 &&
    cf303Canonical["Rewrites"] === <||> &&
    cf303Canonical["Expression"] === truncation];
FTAssert["(d) the used root pair selects the catalogued chart Kallen23",
  Module[{chart = TransportRootSetChart[
      Lookup[cf303Roots[[cf303Class["RootIndices"]]], "RootSquare", {}], {x, y}]},
    AssociationQ[chart] && chart["Name"] === "Kallen23"]];

{cf303Seconds, cf303Factor} = AbsoluteTiming[
  FactorFamilyRegulatorDependenceInFrame[truncation, {x, y}, eps, cf303Frame,
    "PointLadder" -> {2, 4, 8}, "TimeLimit" -> 600]];
Print["(d) FactorFamilyRegulatorDependenceInFrame: ",
  Lookup[cf303Factor, "Status", cf303Factor], " in ", Round[cf303Seconds, 0.1], " s"];
(* MEASURED on the frozen fixture, 2026-08-25, 11.1 s:
     <|Status -> "AlreadyEpsFactored", RootIndices -> {}, Chart -> None|>
   The classifier is clean (above), so the factorization reaches the
   regulator question, and on these BANKED rows the answer is that there is
   nothing left to factor.  Asserted as the exact status; the mathematical
   claim behind it is verified separately, not taken from the verdict. *)
FTAssert["(d) the factorization proceeds past the classification, with the \
measured status AlreadyEpsFactored",
  AssociationQ[cf303Factor] &&
    ! MemberQ[{"ConnectionContainsUndeclaredRadicals", "AlgebraicFrameNotWellFormed",
        "DenestSignAmbiguous"}, cf303Factor["Status"]] &&
    cf303Factor["Status"] === "AlreadyEpsFactored"];
FTAssert["(d) the reason is exact: the frozen 27x27 truncation is itself \
eps-factored in the frame, in both variables",
  private["familyRegulatorFactoredQ"][truncation[[1]], eps] &&
    private["familyRegulatorFactoredQ"][truncation[[2]], eps]];

FTReport[];
