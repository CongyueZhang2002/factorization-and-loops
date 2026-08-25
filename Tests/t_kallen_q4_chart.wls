#!/usr/bin/env wolframscript
(* KallenQ4a / KallenQ4b: the joint rationalizing charts of the root pair
   {lambda1, 4 v + w^2} and of its v <-> w image {lambda1, v^2 + 4 w}
   (derived 2026-08-24).

   WHY.  The CF259 family solve stopped with the typed refusal
   NeedsMultiquadraticRegulatorFactorization: the completed rows 1..16
   carry exactly the roots {lambda1, 4 x + y^2} of its three-root
   multiquadratic frame, and the catalog had no chart rationalizing that
   PAIR -- Kallen1 covers lambda1 alone, Q4a covers 4 v + w^2 alone, and
   the joint charts Kallen12/13/23 pair Kallen radicands only.

   THE CONSTRUCTION is an ITERATED PENCIL, not a rational point on a
   second conic (the method of Kallen12/13/23):

     Step 1.  4 v + w^2 is quadratic in w with leading coefficient 1, so
       sqrt(4 v + w^2) = w + t is a rational pencil:
         w = (4 v - t^2)/(2 t),      sqrt(4 v + w^2) = (4 v + t^2)/(2 t).
     Step 2.  lambda1 pulled back through step 1 is N(v,t)/(4 t^2) with
         N = 4 (t-2)^2 v^2 + 4 t (t^2 - 4 t - 4) v + t^2 (2 + t)^2,
       quadratic in v with the PERFECT SQUARE leading coefficient
       4 (t-2)^2, so the pencil applies a second time:
         sqrt(N) = 2 (t-2) v + s
       is linear in v and solves for v rationally.

   Acceptance criteria, stated before any of them is run.

   D. The derivation, re-derived here and not read from the catalog.
      D1  Solve[4 v + w^2 == (w+t)^2, w] is the step-1 pencil and its
          root image squares back to 4 v + w^2 exactly;
      D2  lambda1 pulled back through step 1 is N/(4 t^2) with N exactly
          the quadratic above;
      D3  N's leading coefficient in v is the perfect square (2(t-2))^2;
      D4  Solve[N == (2(t-2)v + s)^2, v] is LINEAR in v (one solution)
          and equals the closed form
          v = (t^2(2+t)^2 - s^2)/(4(t-2)s - 4 t(t^2-4t-4));
      D5  the derived (v, w, sqrt(lambda1), sqrt(4v+w^2)) are exactly the
          catalog record of KallenQ4a;
      D6  the mirror: lambda1 is v<->w symmetric and v^2 + 4 w is
          (4 v + w^2) with v and w exchanged, so running the same two
          pencils on v^2 + 4 w (quadratic in v, leading coefficient 1)
          gives v_b = w_a and w_b = v_a with BOTH root images unchanged;
          the derived record is exactly the catalog record of KallenQ4b.

   A. Both certificates pass: TransportChartVerify returns OK for
      KallenQ4a and KallenQ4b, with every declared root identity True and
      the parent map (Q4a resp. Q4b at {p -> v(s,t), s -> t/2}) True.

   B. The exact identities, re-derived from the catalog record itself:
      the root squares pulled back through "Subst" equal the recorded
      root images squared, as Together-zeros.

   C. The Jacobian determinant d(v,w)/d(s,t) is not identically zero.

   E. Matching.  TransportRootSetChart returns KallenQ4a for
      {lambda1, 4v+w^2}, KallenQ4b for {lambda1, v^2+4w}, in either
      order and in caller-chosen source symbols; and
      Missing["NoRationalChart"] for {lambda1, 1 + v^3}.

   R. Catalog regression.  Every root set built from the SIX distinct
      quadratics the catalog rationalizes (all singletons and all pairs,
      21 sets) resolves exactly as it did before the two charts were
      added -- measured on the base commit f002abb, 2026-08-24 -- except
      the two pairs of criterion E, which were Missing["NoRationalChart"]
      and are the point of this change.

   S. The square class of a radical base.  The kernel AUTOMATICALLY pulls
      a rational square factor out of a radical, so a pulled-back
      radicand is c^2 times the declared root square for some positive
      rational c (MEASURED: 16 and 4 for this chart).  The branch rule
      must substitute c * image then, must be an exact no-op at c = 1,
      and must NOT touch a base that differs by a non-square, negative or
      symbolic factor.

   T. END TO END on the artifact that motivated the chart: the CF259
      sector state of the triple_root_2026-08-24_fable run, its rows
      1..16 truncation (row bound from the state's own "Ranges"), the
      family's registered multiquadratic frame, and
      FactorFamilyRegulatorDependenceInFrame.  The criterion is that the
      call gets PAST the "NoRationalChart" stop; the resulting status is
      recorded verbatim, whatever it is.  Skipped with a typed line when
      the campaign artifact is absent (it is project data, not repository
      data). *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "TestKit.wl"}]];
root = DirectoryName[DirectoryName[$InputFileName]];
If[Names["FeynFacet`TransportChartCatalog"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
Needs["FTTest`"];

(* distinct local names: a script running in Global` must never write
   v = Symbol["Global`v"], which is the self-assignment that poisons
   iteration limits (CLAUDE.md, Wolfram traps) *)
Quiet[Clear["Global`v", "Global`w", "Global`s", "Global`t", "Global`p",
  "Global`x", "Global`y", "Global`eps", "Global`rho"]];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
ss = Symbol["Global`s"]; tt = Symbol["Global`t"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
ee = Symbol["Global`eps"]; rr = Symbol["Global`rho"];

zeroQ[e_] := TrueQ[Together[e] === 0];
lambda1[a_, b_] := (1 - a - b)^2 - 4 a b;
q3a[a_, b_] := 4 a + b^2;
q3b[a_, b_] := a^2 + 4 b;

catalog = FeynFacet`TransportChartCatalog[];
kq4a = Lookup[catalog, "KallenQ4a", Missing["NotInCatalog"]];
kq4b = Lookup[catalog, "KallenQ4b", Missing["NotInCatalog"]];
FTAssert["catalog carries KallenQ4a and KallenQ4b",
  AssociationQ[kq4a] && AssociationQ[kq4b]];
If[! (AssociationQ[kq4a] && AssociationQ[kq4b]), FTReport[]];

(* ---- D. the derivation, from scratch ------------------------------ *)
step1 = Solve[q3a[vv, ww] == (ww + tt)^2, ww];
FTAssert["D1a step-1 pencil has exactly one solution for w",
  MatchQ[step1, {{_Rule}}]];
wOfVT = Together[ww /. First[step1]];
rootQ3 = Together[wOfVT + tt];
FTAssert["D1b w(v,t) = (4 v - t^2)/(2 t)",
  zeroQ[wOfVT - (4 vv - tt^2)/(2 tt)]];
FTAssert["D1c sqrt(4v+w^2) image squares back exactly",
  zeroQ[q3a[vv, wOfVT] - rootQ3^2]];

q1Pull = Together[lambda1[vv, wOfVT]];
nPoly = Together[Numerator[q1Pull]];
FTAssert["D2a lambda1 pulled back has denominator 4 t^2",
  zeroQ[Denominator[q1Pull] - 4 tt^2]];
FTAssert["D2b N = 4(t-2)^2 v^2 + 4 t (t^2-4t-4) v + t^2 (2+t)^2",
  zeroQ[nPoly - (4 (tt - 2)^2 vv^2 +
    4 tt (tt^2 - 4 tt - 4) vv + tt^2 (2 + tt)^2)]];
nCoefficients = CoefficientList[Collect[Expand[nPoly], vv], vv];
FTAssert["D3 the leading coefficient of N in v is the square (2(t-2))^2",
  Length[nCoefficients] === 3 &&
  zeroQ[nCoefficients[[3]] - (2 (tt - 2))^2]];

step2 = Solve[nPoly == (2 (tt - 2) vv + ss)^2, vv];
FTAssert["D4a the second pencil is LINEAR in v (one solution)",
  MatchQ[step2, {{_Rule}}]];
vOfST = Together[vv /. First[step2]];
FTAssert["D4b v(s,t) = (t^2(2+t)^2 - s^2)/(4(t-2)s - 4 t(t^2-4t-4))",
  zeroQ[vOfST - (tt^2 (2 + tt)^2 - ss^2)/
    (4 (tt - 2) ss - 4 tt (tt^2 - 4 tt - 4))]];

derivedV = Together[vOfST];
derivedW = Together[wOfVT /. vv -> derivedV];
derivedRoot1 = Together[(2 (tt - 2) derivedV + ss)/(2 tt)];
derivedRoot3 = Together[(4 derivedV + tt^2)/(2 tt)];
FTAssert["D5a KallenQ4a Subst is the derived (v(s,t), w(s,t))",
  kq4a["Variables"] === {ss, tt} &&
  (First /@ kq4a["Subst"]) === {vv, ww} &&
  zeroQ[Last[kq4a["Subst"][[1]]] - derivedV] &&
  zeroQ[Last[kq4a["Subst"][[2]]] - derivedW]];
FTAssert["D5b KallenQ4a root images are the derived sqrt(lambda1), \
sqrt(4v+w^2)",
  Length[kq4a["Roots"]] === 2 &&
  zeroQ[kq4a["Roots"][[1]]["Root"] - derivedRoot1] &&
  zeroQ[kq4a["Roots"][[1]]["RootSquare"] - lambda1[vv, ww]] &&
  zeroQ[kq4a["Roots"][[2]]["Root"] - derivedRoot3] &&
  zeroQ[kq4a["Roots"][[2]]["RootSquare"] - q3a[vv, ww]]];

(* D6: the mirror, derived by running the SAME two pencils on v^2 + 4 w,
   which is quadratic in v with leading coefficient 1. *)
FTAssert["D6a lambda1 is v<->w symmetric and q3b(v,w) = q3a(w,v)",
  zeroQ[lambda1[vv, ww] - lambda1[ww, vv]] &&
  zeroQ[q3b[vv, ww] - q3a[ww, vv]]];
step1b = Solve[q3b[vv, ww] == (vv + tt)^2, vv];
vOfWT = Together[vv /. First[step1b]];
rootQ3b = Together[vOfWT + tt];
FTAssert["D6b v(w,t) = (4 w - t^2)/(2 t) and its root image squares back",
  MatchQ[step1b, {{_Rule}}] && zeroQ[vOfWT - (4 ww - tt^2)/(2 tt)] &&
  zeroQ[q3b[vOfWT, ww] - rootQ3b^2]];
q1PullB = Together[lambda1[vOfWT, ww]];
nPolyB = Together[Numerator[q1PullB]];
FTAssert["D6c the pulled-back lambda1 is the SAME N with v -> w",
  zeroQ[Denominator[q1PullB] - 4 tt^2] &&
  zeroQ[nPolyB - (nPoly /. vv -> ww)]];
step2b = Solve[nPolyB == (2 (tt - 2) ww + ss)^2, ww];
FTAssert["D6d the mirror's second pencil is LINEAR in w",
  MatchQ[step2b, {{_Rule}}]];
derivedWB = Together[ww /. First[step2b]];
derivedVB = Together[vOfWT /. ww -> derivedWB];
derivedRoot1B = Together[(2 (tt - 2) derivedWB + ss)/(2 tt)];
derivedRoot3B = Together[(4 derivedWB + tt^2)/(2 tt)];
FTAssert["D6e the mirror exchanges the images: v_b = w_a, w_b = v_a",
  zeroQ[derivedVB - derivedW] && zeroQ[derivedWB - derivedV]];
FTAssert["D6f both root images are unchanged by the mirror",
  zeroQ[derivedRoot1B - derivedRoot1] && zeroQ[derivedRoot3B - derivedRoot3]];
FTAssert["D6g KallenQ4b Subst and root images are the derived mirror",
  kq4b["Variables"] === {ss, tt} && (First /@ kq4b["Subst"]) === {vv, ww} &&
  zeroQ[Last[kq4b["Subst"][[1]]] - derivedVB] &&
  zeroQ[Last[kq4b["Subst"][[2]]] - derivedWB] &&
  Length[kq4b["Roots"]] === 2 &&
  zeroQ[kq4b["Roots"][[1]]["Root"] - derivedRoot1B] &&
  zeroQ[kq4b["Roots"][[1]]["RootSquare"] - lambda1[vv, ww]] &&
  zeroQ[kq4b["Roots"][[2]]["Root"] - derivedRoot3B] &&
  zeroQ[kq4b["Roots"][[2]]["RootSquare"] - q3b[vv, ww]]];

(* ---- A. the certificates ------------------------------------------ *)
certificateA = FeynFacet`TransportChartVerify[kq4a];
certificateB = FeynFacet`TransportChartVerify[kq4b];
Print["KallenQ4a certificate: ", InputForm[KeyDrop[certificateA, "JacobianDet"]]];
Print["KallenQ4b certificate: ", InputForm[KeyDrop[certificateB, "JacobianDet"]]];
FTAssert["A1 KallenQ4a certificate OK",
  TrueQ[certificateA["OK"]] && certificateA["RootIdentities"] === {True, True}];
FTAssert["A2 KallenQ4a parent map Q4a at {p -> v(s,t), s -> t/2} exact",
  certificateA["ParentMaps"] === <|"Q4a" -> True|>];
FTAssert["A3 KallenQ4b certificate OK",
  TrueQ[certificateB["OK"]] && certificateB["RootIdentities"] === {True, True}];
FTAssert["A4 KallenQ4b parent map Q4b at {p -> w(s,t), s -> t/2} exact",
  certificateB["ParentMaps"] === <|"Q4b" -> True|>];

(* ---- B. the identities, re-derived from the record ---------------- *)
pullBack[chart_, expr_] := Together[expr /. chart["Subst"]];
FTAssert["B1 KallenQ4a: lambda1 pulled back == (recorded root)^2",
  zeroQ[pullBack[kq4a, lambda1[vv, ww]] - kq4a["Roots"][[1]]["Root"]^2]];
FTAssert["B2 KallenQ4a: 4 v + w^2 pulled back == (recorded root)^2",
  zeroQ[pullBack[kq4a, q3a[vv, ww]] - kq4a["Roots"][[2]]["Root"]^2]];
FTAssert["B3 KallenQ4b: lambda1 pulled back == (recorded root)^2",
  zeroQ[pullBack[kq4b, lambda1[vv, ww]] - kq4b["Roots"][[1]]["Root"]^2]];
FTAssert["B4 KallenQ4b: v^2 + 4 w pulled back == (recorded root)^2",
  zeroQ[pullBack[kq4b, q3b[vv, ww]] - kq4b["Roots"][[2]]["Root"]^2]];
FTAssert["B5 the primary Root/RootSquare pair agrees with Roots[[1]]",
  zeroQ[kq4a["Root"] - kq4a["Roots"][[1]]["Root"]] &&
  zeroQ[kq4a["RootSquare"] - kq4a["Roots"][[1]]["RootSquare"]] &&
  zeroQ[kq4b["Root"] - kq4b["Roots"][[1]]["Root"]] &&
  zeroQ[kq4b["RootSquare"] - kq4b["Roots"][[1]]["RootSquare"]]];

(* ---- C. the Jacobian ---------------------------------------------- *)
jacobianDet[chart_] := Module[{f, g, vars = chart["Variables"]},
  {f, g} = Together /@ (Last /@ chart["Subst"]);
  Together[Det[{{D[f, vars[[1]]], D[f, vars[[2]]]},
    {D[g, vars[[1]]], D[g, vars[[2]]]}}]]];
detA = jacobianDet[kq4a]; detB = jacobianDet[kq4b];
FTAssert["C1 KallenQ4a Jacobian determinant is not identically zero",
  ! TrueQ[detA === 0] && ! zeroQ[detA]];
FTAssert["C2 KallenQ4b Jacobian determinant is not identically zero",
  ! TrueQ[detB === 0] && ! zeroQ[detB]];
FTAssert["C3 the two Jacobian determinants differ by the v<->w sign",
  zeroQ[detA + detB]];

(* ---- E. matching --------------------------------------------------- *)
chartName[r_] := If[AssociationQ[r], r["Name"],
  If[MissingQ[r], "Missing:" <> ToString[First[r]], ToString[InputForm[r]]]];
FTAssert["E1 {lambda1, 4v+w^2} resolves to KallenQ4a",
  chartName[FeynFacet`TransportRootSetChart[
    {lambda1[vv, ww], q3a[vv, ww]}]] === "KallenQ4a"];
FTAssert["E2 {4v+w^2, lambda1} (reversed) resolves to KallenQ4a",
  chartName[FeynFacet`TransportRootSetChart[
    {q3a[vv, ww], lambda1[vv, ww]}]] === "KallenQ4a"];
FTAssert["E3 {lambda1, v^2+4w} resolves to KallenQ4b",
  chartName[FeynFacet`TransportRootSetChart[
    {lambda1[vv, ww], q3b[vv, ww]}]] === "KallenQ4b"];
FTAssert["E4 {v^2+4w, lambda1} (reversed) resolves to KallenQ4b",
  chartName[FeynFacet`TransportRootSetChart[
    {q3b[vv, ww], lambda1[vv, ww]}]] === "KallenQ4b"];
FTAssert["E5 the lookup is symbol-name independent (source variables x, y)",
  chartName[FeynFacet`TransportRootSetChart[
    {lambda1[xx, yy], q3a[xx, yy]}, {xx, yy}]] === "KallenQ4a" &&
  chartName[FeynFacet`TransportRootSetChart[
    {lambda1[xx, yy], q3b[xx, yy]}, {xx, yy}]] === "KallenQ4b"];
FTAssert["E6 {lambda1, 1 + v^3} is Missing[\"NoRationalChart\"]",
  MatchQ[FeynFacet`TransportRootSetChart[{lambda1[vv, ww], 1 + vv^3}],
    Missing["NoRationalChart", _]]];

(* ---- R. catalog regression ---------------------------------------- *)
(* the six distinct quadratics the catalog rationalizes, named rather
   than enumerated, so the table does not depend on catalog order *)
catalogSquares = {lambda1[vv, ww], lambda1[-vv, ww], lambda1[vv, -ww],
  q3a[vv, ww], q3b[vv, ww], 1 - 4 vv ww};
distinctSquares = DeleteDuplicates[Together /@ (#["RootSquare"] & /@
  Flatten[Lookup[Values[catalog], "Roots", {}]])];
FTAssert["R0 the catalog rationalizes exactly these six quadratics",
  Length[distinctSquares] === 6 &&
  AllTrue[catalogSquares,
    Function[q, AnyTrue[distinctSquares, zeroQ[q - #] &]]] &&
  AllTrue[distinctSquares,
    Function[q, AnyTrue[catalogSquares, zeroQ[q - #] &]]]];
(* MEASURED on the base commit f002abb (2026-08-24), before KallenQ4a/b
   existed; the two entries marked NEW were Missing["NoRationalChart"]
   there and are the change under test. *)
baseResolution = <|
  {1} -> "Kallen1", {2} -> "Kallen2", {3} -> "Kallen3",
  {4} -> "Q4a", {5} -> "Q4b", {6} -> "Bilinear115",
  {1, 2} -> "Kallen12", {1, 3} -> "Kallen13",
  {1, 4} -> "KallenQ4a" (* NEW *), {1, 5} -> "KallenQ4b" (* NEW *),
  {1, 6} -> "Missing:NoRationalChart",
  {2, 3} -> "Kallen23",
  {2, 4} -> "Missing:NoRationalChart", {2, 5} -> "Missing:NoRationalChart",
  {2, 6} -> "Missing:NoRationalChart",
  {3, 4} -> "Missing:NoRationalChart", {3, 5} -> "Missing:NoRationalChart",
  {3, 6} -> "Missing:NoRationalChart",
  {4, 5} -> "Missing:NoRationalChart", {4, 6} -> "Missing:NoRationalChart",
  {5, 6} -> "Missing:NoRationalChart"|>;
measuredResolution = Association @ Table[
  index -> chartName[FeynFacet`TransportRootSetChart[
    catalogSquares[[index]], {vv, ww}]],
  {index, Keys[baseResolution]}];
Print["resolution differences against the base commit: ", InputForm[
  Select[Association @ KeyValueMap[
      #1 -> {baseResolution[#1], #2} &, measuredResolution],
    #[[1]] =!= #[[2]] &]]];
FTAssert["R1 all 21 singleton and pair resolutions are unchanged except \
the two new pairs",
  measuredResolution === baseResolution];
FTAssert["R2 every catalog chart still resolves its OWN root set to itself",
  AllTrue[Keys[catalog], Function[name,
    chartName[FeynFacet`TransportRootSetChart[
      #["RootSquare"] & /@ catalog[name]["Roots"], {vv, ww}]] === name]]];
FTAssert["R3 every catalog chart still passes TransportChartVerify",
  AllTrue[Values[catalog], TrueQ[FeynFacet`TransportChartVerify[#]["OK"]] &]];

(* ---- S. the square class of a radical base ------------------------ *)
applyBranches = FeynFacet`Private`transportChartApplyRootBranches;
branchScale = FeynFacet`Private`transportChartRootBranchScale;
radicalBases = FeynFacet`Private`transportChartRadicalBases;
FTAssert["S1 the kernel really does extract a rational square factor",
  First[radicalBases[Sqrt[(4 xx + yy^2)/4]]] === 4 xx + yy^2 &&
  ! zeroQ[First[radicalBases[Sqrt[(4 xx + yy^2)/4]]] - (4 xx + yy^2)/4]];
FTAssert["S2 scale is 1 on an exact match, 2 at base = 4 Q, 1/2 at base = Q/4",
  branchScale[4 xx + yy^2, 4 xx + yy^2] === 1 &&
  branchScale[4 (4 xx + yy^2), 4 xx + yy^2] === 2 &&
  branchScale[(4 xx + yy^2)/4, 4 xx + yy^2] === 1/2];
FTAssert["S3 a non-square, negative or symbolic ratio is refused",
  branchScale[2 (4 xx + yy^2), 4 xx + yy^2] === None &&
  branchScale[-4 (4 xx + yy^2), 4 xx + yy^2] === None &&
  branchScale[xx (4 xx + yy^2), 4 xx + yy^2] === None &&
  branchScale[1 + xx^3, 4 xx + yy^2] === None];
(* the c != 1 direction is the one a pullback produces: the CARRIED base
   has the numeric factor, the DECLARED root square does not *)
FTAssert["S4 the branch rule substitutes c * image and is exact",
  zeroQ[applyBranches[Sqrt[4 xx + yy^2],
      {<|"RootSquare" -> (4 xx + yy^2)/4|>}, {rr}] - 2 rr] &&
  zeroQ[applyBranches[Sqrt[4 xx + yy^2],
      {<|"RootSquare" -> 4 (4 xx + yy^2)|>}, {rr}] - rr/2] &&
  zeroQ[applyBranches[Sqrt[4 xx + yy^2],
      {<|"RootSquare" -> 4 xx + yy^2|>}, {rr}] - rr]];
FTAssert["S5 the branch rule is a no-op on an unrelated or non-square radical",
  applyBranches[Sqrt[1 + xx^3],
    {<|"RootSquare" -> 4 xx + yy^2|>}, {rr}] === Sqrt[1 + xx^3] &&
  applyBranches[Sqrt[4 xx + yy^2],
    {<|"RootSquare" -> 2 (4 xx + yy^2)|>}, {rr}] === Sqrt[4 xx + yy^2]];
FTAssert["S6 half-integer powers of any order are carried",
  zeroQ[applyBranches[(4 xx + yy^2)^(3/2),
      {<|"RootSquare" -> 4 xx + yy^2|>}, {rr}] - rr^3] &&
  zeroQ[applyBranches[(4 xx + yy^2)^(3/2),
      {<|"RootSquare" -> (4 xx + yy^2)/4|>}, {rr}] - 8 rr^3] &&
  zeroQ[applyBranches[1/Sqrt[4 xx + yy^2],
      {<|"RootSquare" -> (4 xx + yy^2)/4|>}, {rr}] - 1/(2 rr)]];
(* the measured statement: pulling the CF259 root pair back through
   KallenQ4a leaves radicands 16 and 4 times the declared squares *)
chartData = FeynFacet`Private`masterTransportChartData[
  FeynFacet`Private`transportChartRekey[kq4a, {xx, yy},
    {Symbol["Global`chartS"], Symbol["Global`chartT"]}], {xx, yy}];
pulledSquares = Together /@ ({lambda1[vv, ww], q3a[vv, ww]} /.
  {vv -> xx, ww -> yy} /. chartData["Subst"]);
carriedBases = Table[First[radicalBases[Sqrt[q]]], {q, pulledSquares}];
Print["carried base / declared square = ", InputForm[
  Table[Together[carriedBases[[i]]/pulledSquares[[i]]], {i, 2}]]];
FTAssert["S7 KallenQ4a's pulled-back squares are carried at 16 and 4",
  chartData["Status"] === "OK" &&
  Together[carriedBases[[1]]/pulledSquares[[1]]] === 16 &&
  Together[carriedBases[[2]]/pulledSquares[[2]]] === 4 &&
  branchScale[carriedBases[[1]], pulledSquares[[1]]] === 4 &&
  branchScale[carriedBases[[2]], pulledSquares[[2]]] === 2];

(* ---- T. end to end on CF259 ---------------------------------------- *)
stateFile = FileNameJoin[{"/home/maxzhang/factorization-and-loops",
  "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical",
  "FamilyEpsFormsSolving", "triple_root_2026-08-24_fable", "CF259",
  "sector_state_CF259_standard.wl"}];
familyChartFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "TransportFamilyCharts.wl"}];
If[! (FileExistsQ[stateFile] && FileExistsQ[familyChartFile]),
  Print["SKIP  T (CF259 end to end): campaign artifact absent -- ",
    Select[{stateFile, familyChartFile}, ! FileExistsQ[#] &]],
  Module[{registration, frame, state, rowBound, truncation, allRoots,
      classification, rootSquares, chart, factor, seconds, status},
    registration = FeynFacet`TransportFamilyChartLoad[familyChartFile];
    FTAssert["T1 the campaign's family charts register",
      Lookup[registration, "Status", None] === "FamilyChartsRegistered"];
    frame = FeynFacet`TransportFamilyChart["CF259"];
    FTAssert["T2 CF259's registered frame is the exact three-root \
multiquadratic identity frame",
      AssociationQ[frame] && Lookup[frame, "Status", None] === "ExactFrame" &&
      Length[Lookup[frame, "Roots", {}]] === 3];
    state = FeynFacet`FamilyArtifactRead[stateFile];
    FTAssert["T3 the sector state stopped with \
NeedsMultiquadraticRegulatorFactorization at rows 1..16",
      AssociationQ[state] &&
      Lookup[Lookup[state, "Stop", <||>], "Status", None] ===
        "NeedsMultiquadraticRegulatorFactorization" &&
      state["Stop"]["Rows"] === 16 &&
      state["Stop"]["RootIndices"] === {1, 3}];
    FTAssert["T4 the state was produced in the frame under test \
(chart fingerprint)",
      Hash[KeyTake[frame, {"Name", "Variables", "Subst", "Roots", "Parents"}],
        "SHA256", "HexString"] === state["ChartFingerprint"]];
    rowBound = Last[state["Ranges"][[16]]];
    truncation = {state["A"][[1, 1 ;; rowBound, 1 ;; rowBound]],
      state["A"][[2, 1 ;; rowBound, 1 ;; rowBound]]};
    Print["T: rows 1..16 is the ", rowBound, "x", rowBound, " truncation"];
    allRoots = FeynFacet`Private`transportChartCurrentRoots[frame, {xx, yy}];
    classification = FeynFacet`Private`transportChartRootIndices[
      truncation, allRoots];
    FTAssert["T5 the truncation carries frame roots {1, 3} and no \
undeclared radical",
      classification["RootIndices"] === {1, 3} &&
      classification["UnclassifiedRadicalBases"] === {}];
    rootSquares = Lookup[allRoots[[classification["RootIndices"]]],
      "RootSquare", {}];
    chart = FeynFacet`TransportRootSetChart[rootSquares, {xx, yy}];
    FTAssert["T6 that root pair now resolves to KallenQ4a (it was \
Missing[\"NoRationalChart\"], which is what stopped the solve)",
      AssociationQ[chart] && chart["Name"] === "KallenQ4a"];
    {seconds, factor} = AbsoluteTiming[
      FeynFacet`FactorFamilyRegulatorDependenceInFrame[
        truncation, {xx, yy}, ee, frame,
        "TimeLimit" -> 900, "Verbose" -> False]];
    status = If[AssociationQ[factor], Lookup[factor, "Status", None], factor];
    Print["T: FactorFamilyRegulatorDependenceInFrame -> ", InputForm[status],
      " in ", Round[seconds, 0.1], " s"];
    Print["T: record = ", InputForm[If[AssociationQ[factor],
      KeyDrop[factor, {"Transformation", "Inverse", "Connection", "Attempts"}],
      factor]]];
    FTAssert["T7 the call gets PAST the NoRationalChart stop",
      AssociationQ[factor] && status =!= "NoRationalChart"];
    If[status === "OK",
      FTAssert["T8 T(eps) is constant in the variables and eps-dependent",
        FreeQ[factor["Transformation"], xx | yy] &&
        ! FreeQ[factor["Transformation"], ee]];
      FTAssert["T9 the source-frame statement is exact: eps-factored and \
exact inverse",
        TrueQ[factor["SourceFrameEpsFactored"]] &&
        TrueQ[factor["InverseExact"]]];
      FTAssert["T10 the chart used is KallenQ4a",
        factor["Chart"] === "KallenQ4a" && factor["RootIndices"] === {1, 3}],
      Print["T8-T10 not applicable: the recorded status is ",
        InputForm[Lookup[factor, "Status", factor]]]];
  ]];

FTReport[];
