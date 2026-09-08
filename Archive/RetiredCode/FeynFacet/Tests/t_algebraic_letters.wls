#!/usr/bin/env wolframscript
(* Algebraic letters in stage-2 transport (2026-08-17).

   MEASURED motivation: the canonical alphabets of the NNLO double-real
   families contain letters QUADRATIC in the moving path variable whose
   discriminant is not a square in the frozen one (e.g. 1 - w + v w in
   the class-97 chart is a genus-1 curve on P^1 x P^1), so no rational
   chart makes them linear.  Such a letter contributes the two roots
   (-b +- k Sqrt[D0])/(2a) as ALGEBRAIC word indices.  Libra's Pexp
   admits them natively (PolesPosition = Solve); the engine's monic gate
   used to refuse them by policy.

   What is pinned here:
     A. the radical discipline (square-free canonical form; the exact
        zero test over Q(vars, Sqrt[D0]) decides true and false
        identities, incl. radicals in denominators and half-integer
        powers);
     B. the engine's linearization / pole parts / partial fractions over
        the extension reconstruct their input EXACTLY;
     C. a synthetic 2x2 epsilon-form dF = eps (R1 dlog v + R2 dlog(v^2-w)) F,
        [R1,R2] = 0, transported along v at fixed symbolic w (roots
        +- Sqrt[w]): Blockwise status OK, recursion certificate zero,
        exact per-order DE check True at eps^0..eps^2, Libra Phi
        cross-check True; the Monolithic engine (Libra Pexp with
        algebraic poles) gives the SAME F entrywise; the monic record
        names the quadratic and its radical;
     D. negative control: an eps-DEPENDENT quadratic denominator is
        refused by name (it is an apparent locus, never a letter);
        "AlgebraicLetters" -> False restores the strict gate.
   Acceptance is stated per assertion; every check is exact. *)

Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]], "TestKit.wl"}]];
root = DirectoryName[ExpandFileName[$InputFileName], 3];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
Quiet[Clear["Global`tau", "Global`v", "Global`w", "Global`eps"]];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
tt = Symbol["Global`tau"];
Needs["FTTest`"];

rz = FeynFacet`Private`masterTransportRadicalZeroQ;
rc = FeynFacet`Private`masterTransportRadicalCanon;
lin = FeynFacet`Private`masterTransportBWLinearize;
pf = FeynFacet`Private`masterTransportBWPartialFractions;
de = FeynFacet`Private`masterTransportBWDlogEntry;
fail = FeynFacet`Private`$masterTransportBlockwiseFailure;
zeroMat = FeynFacet`Private`masterTransportZeroMatQ;

(* ---- A. radical discipline --------------------------------------- *)
FTAssert["A1 square-free canon: Sqrt[4 w^2 (1-w)] -> 2 w Sqrt[1-w]",
  TrueQ[Together[rc[4 ww^2 (1 - ww)] - 2 ww Sqrt[1 - ww]] === 0]];
FTAssert["A2 zero test proves 1/(1+Sqrt[w]) == (1-Sqrt[w])/(1-w)",
  rz[1/(1 + Sqrt[ww]) - (1 - Sqrt[ww])/(1 - ww)] === True];
FTAssert["A3 zero test refutes 1/(1+Sqrt[w]) == (1+Sqrt[w])/(1-w)",
  rz[1/(1 + Sqrt[ww]) - (1 + Sqrt[ww])/(1 - ww)] === False];
FTAssert["A4 zero test: (t-Sqrt[w])(t+Sqrt[w]) == t^2 - w",
  rz[(tt - Sqrt[ww]) (tt + Sqrt[ww]) - (tt^2 - ww)] === True];
FTAssert["A5 zero test with half-integer powers: w^(3/2)/w == Sqrt[w]",
  rz[ww^(3/2)/ww - Sqrt[ww]] === True];
FTAssert["A6 zero test refutes Sqrt[w] == Sqrt[1-w] (two radicals)",
  rz[Sqrt[ww] - Sqrt[1 - ww]] === False];

(* ---- B. engine helpers over the extension ------------------------- *)
lr = Catch[lin[(tt^2 - ww) (tt - 3), tt], fail];
FTAssert["B1 linearize (t^2-w)(t-3): three simple poles {3, +Sqrt[w], -Sqrt[w]}",
  AssociationQ[lr] && Length[lr["Poles"]] === 3 &&
  Sort[Together /@ (#["Letter"] & /@ lr["Poles"]) /. Sqrt[ww] -> 0.5] ===
    Sort[{3, 0.5, -0.5}]];
e1 = (tt + 1)/((tt^2 - ww)^2 (tt - 3));
terms = Catch[pf[e1, tt], fail];
FTAssert["B2 partial fractions of (t+1)/((t^2-w)^2 (t-3)) reconstruct exactly (checked inside; no failure thrown)",
  ListQ[terms] && Length[terms] > 0];
FTAssert["B3 partial fractions: every residue is tau-free and every letter algebraic or rational",
  ListQ[terms] && AllTrue[terms, #["Kind"] === "Poly" || FreeQ[#["Residue"], tt] &]];
d1 = Catch[de[2 tt/(tt^2 - ww), tt], fail];
FTAssert["B4 dlog entry 2t/(t^2-w): residues 1 at +-Sqrt[w]",
  AssociationQ[d1] && d1["Status"] === "OK" && Sort[Values[d1["Poles"]]] === {1, 1}];

(* ---- C. synthetic 2x2 with the algebraic letter v^2 - w ------------ *)
R1 = {{0, 1}, {0, 0}}; R2 = {{1, 2}, {0, 1}};
av = ee (R1/vv + R2 (2 vv)/(vv^2 - ww));
aw = ee (R2 (-1)/(vv^2 - ww));
FTAssert["C0 synthetic system is flat",
  Together[D[av, ww] - D[aw, vv] + av . aw - aw . av] === {{0, 0}, {0, 0}}];
blocks = {{{1, 2}, <|"Type" -> "EpsForm", "T" -> IdentityMatrix[2],
   "TInverse" -> IdentityMatrix[2], "Ev" -> av, "Ew" -> aw|>}};
run[engine_, alg_] := FeynFacet`TransportFamily[
  <|"Family" -> "synth_alg", "Av" -> av, "Aw" -> aw|>,
  "Variables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> blocks,
  "FormDirectory" -> None, "PhysicalValuation" -> 0, "Orders" -> {0, 2},
  "Engine" -> engine, "TransportBackend" -> "Libra", "AlgebraicLetters" -> alg,
  "BasePoint" -> {1/4, ww}, "Target" -> {vv, ww}, "MaxWeight" -> 8, "Verbose" -> False];
bw = run["Blockwise", Automatic];
FTAssert["C1 Blockwise status OK", AssociationQ[bw] && bw["Status"] === "OK"];
FTAssert["C2 monic record: not linear, algebraic-admissible, one quadratic with radical proportional to Sqrt[w]",
  AssociationQ[bw] && bw["Monic"]["Linear"] === False && bw["Monic"]["AlgebraicAdmissible"] === True &&
  Length[bw["Monic"]["Quadratics"]] === 1 &&
  FreeQ[Together[bw["Monic"]["Quadratics"][[1]]["Radical"]/Sqrt[ww]], Power[_, _Rational]]];
FTAssert["C3 recursion certificate all zero",
  AssociationQ[bw] && TrueQ[bw["Blockwise"]["Certificate"]["AllZero"]]];
FTAssert["C4 exact DE check True at eps^0, eps^1, eps^2",
  AssociationQ[bw] && (#["Zero"] & /@ bw["DECheck"]) === {{True}, {True}, {True}}];
FTAssert["C5 Libra Phi cross-check True (letters normalized to the same radical form)",
  AssociationQ[bw] && TrueQ[bw["Blockwise"]["Phi"]["AllZero"]]];
FTAssert["C6 three distinct letters, two of them algebraic",
  AssociationQ[bw] && bw["Blockwise"]["Letters"]["Count"] === 3 &&
  Count[bw["Blockwise"]["Letters"]["Letters"], _?(! FreeQ[#, Sqrt[ww]] &)] === 2];
mono = run["Monolithic", Automatic];
FTAssert["C7 Monolithic (Libra Pexp with algebraic poles) status OK and DE check True",
  AssociationQ[mono] && mono["Status"] === "OK" &&
  (#["Zero"] & /@ mono["DECheck"]) === {{True}, {True}, {True}}];
FTAssert["C8 Blockwise and Monolithic F agree entrywise at every order",
  AssociationQ[bw] && AssociationQ[mono] &&
  AllTrue[Keys[bw["F"]], KeyExistsQ[mono["F"], #] && zeroMat[bw["F"][#] - mono["F"][#]] &]];

(* ---- D. negative controls ---------------------------------------- *)
strict = run["Blockwise", False];
FTAssert["D1 AlgebraicLetters -> False restores the strict refusal PathDenominatorsNotLinear",
  AssociationQ[strict] && strict["Status"] === "PathDenominatorsNotLinear"];
(* an eps-dependent locus: v^2 - w - eps has an eps-dependent discriminant *)
avBad = ee (R1/vv + R2 (2 vv)/(vv^2 - ww - ee));
awBad = ee (R2 (-1)/(vv^2 - ww - ee));
blocksBad = {{{1, 2}, <|"Type" -> "EpsForm", "T" -> IdentityMatrix[2],
   "TInverse" -> IdentityMatrix[2], "Ev" -> avBad, "Ew" -> awBad|>}};
bad = FeynFacet`TransportFamily[
  <|"Family" -> "synth_bad", "Av" -> avBad, "Aw" -> awBad|>,
  "Variables" -> {vv, ww}, "Regulator" -> ee, "Blocks" -> blocksBad,
  "FormDirectory" -> None, "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "Engine" -> "Blockwise", "TransportBackend" -> "Libra",
  "BasePoint" -> {1/4, ww}, "Target" -> {vv, ww}, "MaxWeight" -> 8, "Verbose" -> False];
FTAssert["D2 eps-dependent quadratic locus is refused by name (assembly certificate: EpsFormLinear False -> CertificateFailed; never admitted as a letter)",
  AssociationQ[bad] && bad["Status"] === "CertificateFailed" &&
  bad["Certificate"]["EpsFormLinear"] === False];
(* and the monic gate itself refuses an eps-dependent discriminant when
   asked directly, independent of the assembly *)
mc = FeynFacet`Private`masterTransportMonicCheck[
  {{1/(tt^2 - ww - ee), 0}, {0, 1/(tt - 1)}}, tt, ee];
FTAssert["D3 monic gate: eps-dependent discriminant -> not algebraic-admissible",
  AssociationQ[mc] && mc["Linear"] === False && mc["AlgebraicAdmissible"] === False &&
  mc["Quadratics"][[1]]["EpsFree"] === False];
mc2 = FeynFacet`Private`masterTransportMonicCheck[
  {{1/(tt^2 - ww), 0}, {0, 1/(tt - 1)}}, tt, ee];
FTAssert["D4 monic gate: eps-free discriminant -> algebraic-admissible with radical 2 Sqrt[w]",
  AssociationQ[mc2] && mc2["AlgebraicAdmissible"] === True &&
  TrueQ[Together[mc2["Quadratics"][[1]]["Radical"] - 2 Sqrt[ww]] === 0]];

FTReport[];
