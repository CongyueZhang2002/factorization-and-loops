#!/usr/bin/env wolframscript
(* Candidate repairs for the residual algebraic factor, on the cheap
   fixture that reproduces it. *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Clear[x, y, eps];
ranges = {{1, 2}, {3}, {4, 5}, {6, 7}}; n = 7;
blockOf[i_] := First[Select[Range[Length[ranges]], MemberQ[ranges[[#]], i] &]];
r = Sqrt[1 - 2 x + x^2 - 2 y - 2 x y + y^2];
D0 = 1 - 2 x + x^2 - 2 y - 2 x y + y^2;
entry[i_, j_] := With[{s = i + 2 j},
  (eps s + x (i - j) + y j + 1)/
   ((x + i)^Mod[s, 2] (1 - x - y) (y + j) (1 + x - y + r)^Mod[s, 3])];
connection = Table[
  Table[If[blockOf[i] < blockOf[j], 0, entry[i, j] + muI], {i, n}, {j, n}],
  {muI, 2}];
gauge2 = {{(1 + x)/(y (1 - x) (1 + x - y + r))}, {(2 - y)/((x + 3) (1 + x - y + r)^2)}};
gauge3 = {{x/((1 + y) (1 + x - y + r)), (1 - y)/(x + 2)},
   {0, (3 + x y)/((1 - x) (1 + x - y + r)^2)}};
solved = <|2 -> gauge2, 3 -> gauge3|>;
k = 4; j = 1; rk = ranges[[k]]; rj = ranges[[j]];
sym = Table[Map[Together, connection[[mu, rk, rj]] -
    Sum[solved[m] . connection[[mu, ranges[[m]], rj]], {m, {2, 3}}], {2}],
  {mu, 2}];
prep = FeynFacet`Private`blockEquationDeferredPrepare[
  connection, ranges, k, j, solved, {x, y}, eps];
mat = FeynFacet`Private`blockEquationDeferredMaterialize[prep];
def = Table[mat["Values"][{a, b, c}], {a, 2}, {b, 2}, {c, 2}];

(* candidate A: rationalize by the conjugate, then cancel over Q(x,y,eps) *)
rationalize[e_] := Module[{q, num, den, factors, conj, norm, extra = 1,
   keep = 1},
  q = Together[e]; num = Numerator[q]; den = Denominator[q];
  factors = FactorList[den];
  Do[Module[{f = fp[[1]], p = fp[[2]]},
    If[FreeQ[f, Power[_, _Rational]], keep *= f^p,
      conj = Expand[f /. r -> -r];
      norm = Expand[(f conj) /. r^2 -> D0 /. r -> 0];
      norm = Together[Expand[f conj] /. Power[r, 2] -> D0];
      extra *= conj^p; keep *= norm^p]], {fp, factors}];
  Cancel[Expand[num extra]/Expand[keep]]];
repairA = Map[rationalize, def, {3}];
Print["A exact: ", AllTrue[Flatten[repairA - sym], TrueQ[Together[#] === 0] &]];

(* candidate B: PolynomialGCD with an algebraic extension *)
repairB = Map[Quiet[Check[Cancel[#, Extension -> Automatic], #]] &, def, {3}];
Print["B exact: ", AllTrue[Flatten[repairB - sym], TrueQ[Together[#] === 0] &]];

gaugeDen[b_] := Module[{fp, fs, fpow},
  fp = Flatten[FeynFacet`Private`finiteFieldStripEntryFactorList /@
     Flatten[b], 1];
  fs = If[fp === {}, {}, DeleteDuplicates[fp[[All, 1]], SameQ]];
  fpow = Table[{f, Max[Cases[fp, {c_, p_} /; SameQ[c, f] :> p]]}, {f, fs}];
  Times @@ ((First[#]^(Last[#] - 1)) & /@ Select[fpow, Last[#] > 1 &])];
Print["gauge den symbolic : ", gaugeDen[sym]];
Print["gauge den deferred : ", gaugeDen[def]];
Print["gauge den repair A : ", gaugeDen[repairA]];
Print["gauge den repair B : ", gaugeDen[repairB]];
Print["A equals symbolic gauge den: ",
  TrueQ[Together[gaugeDen[repairA] - gaugeDen[sym]] === 0]];
Print["B equals symbolic gauge den: ",
  TrueQ[Together[gaugeDen[repairB] - gaugeDen[sym]] === 0]];
Print["leaf counts sym ", LeafCount[sym], " def ", LeafCount[def],
  " A ", LeafCount[repairA], " B ", LeafCount[repairB]];
Print[Timing[Map[rationalize, def, {3}];][[1]], " s for A"];
