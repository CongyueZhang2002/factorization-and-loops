#!/usr/bin/env wolframscript
(* Cheap reproduction of the one measured difference between the routes:
   on an ALGEBRAIC frame the deferred entry's denominator carries an
   extra power of an algebraic factor.  Small fixture, so a repair can be
   iterated in seconds instead of 173 s per real-block run. *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Clear[x, y, eps];
ranges = {{1, 2}, {3}, {4, 5}, {6, 7}}; n = 7;
blockOf[i_] := First[Select[Range[Length[ranges]], MemberQ[ranges[[#]], i] &]];
r = Sqrt[1 - 2 x + x^2 - 2 y - 2 x y + y^2];
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
Print["status ", mat["Status"], " algebraic entries ",
  Lookup[mat, "AlgebraicEntries", 0], " fallbacks ", mat["Fallbacks"]];
Print["exact equality: ", AllTrue[Flatten[def - sym],
  TrueQ[Together[#] === 0] &]];
gaugeDen[b_] := Module[{fp, fs, fpow},
  fp = Flatten[FeynFacet`Private`finiteFieldStripEntryFactorList /@
     Flatten[b], 1];
  fs = If[fp === {}, {}, DeleteDuplicates[fp[[All, 1]], SameQ]];
  fpow = Table[{f, Max[Cases[fp, {c_, p_} /; SameQ[c, f] :> p]]}, {f, fs}];
  Times @@ ((First[#]^(Last[#] - 1)) & /@ Select[fpow, Last[#] > 1 &])];
gs = gaugeDen[sym]; gd = gaugeDen[def];
Print["gauge denominator equal: ", TrueQ[Together[gs - gd] === 0]];
Print["symbolic : ", gs];
Print["deferred : ", gd];
Print["leaf counts: symbolic ", LeafCount[sym], " deferred ", LeafCount[def]];
Print["per-entry denominators:"];
Do[Print["  ", {a, b, c}, "  sym ", Denominator[Together[sym[[a, b, c]]]],
   "\n           def ", Denominator[Together[def[[a, b, c]]]]],
  {a, 1, 1}, {b, 1, 2}, {c, 1, 2}];
