#!/usr/bin/env wolframscript
(* CF360 path diagnostic (W5, DEFERRED -- next-session item).

   CF360 is a documented expected-partial: Libra's PexpExpansion aborts
   on its conjugated path connection, TransportFamily catches the abort
   and returns TransportFailed, and Tests/Transport/t_master_transport.wls asserts
   that controlled failure rather than shipping an unverified transport.
   That status is honest and is NOT a defect to be papered over.

   This script measures WHY, so the next attempt starts from data rather
   than from a guess.  Fuchsian behaviour at tau = Infinity requires
   ahat(tau) = O(1/tau); anything tending to a nonzero constant, or
   growing, is an irregular singularity there.  An irregular singularity
   is INTRINSIC -- no reparametrization of tau can remove it, though a
   gauge transformation (Fuchsification) might -- so the first question
   to settle is whether the obstruction is a property of the straight
   path or of the system, and which block it lives in.

   What it prints, per candidate path: the number of entries with a
   nonzero polynomial part in tau, the maximum degree, and the
   block-by-block location of the obstruction.  Read it as: degree -1
   everywhere means Fuchsian at infinity and the path is usable; degree
   0 or more localises the problem.

   Run:  wolframscript -file Scripts/HardClasses/diag_cf360_path.wls
   All paths are resolved relative to the repository root. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
tt = Symbol["Global`tau"];
norm[e_] := e /. s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;

data = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
cf360 = norm[Get[FileNameJoin[{data, "DifferentialEquations", "nnlo_de_CF360.wl"}]]];
assign = Select[Get[FileNameJoin[{data, "BlockClasses", "block_class_assign.wl"}]],
   #["Family"] === "CF360" &];
blocks = Table[{a["Rows"], a["ClassID"]}, {a, assign}];
Print["CF360 blocks: ", blocks];

asm = FeynFacet`Private`masterTransportAssemble[
   <|"Family" -> "CF360", "Basis" -> cf360["BlockBasis"],
     "Av" -> cf360["Av"], "Aw" -> cf360["Aw"]|>,
   ee, {vv, ww},
   "Blocks" -> blocks,
   "FormDirectory" -> FileNameJoin[{data, "ClassForms"}]];
Print["assembly status: ", asm["Status"]];
If[asm["Status"] =!= "OK", Print["assembly failed; stopping"]; Exit[1]];
Print["ranges: ", asm["Ranges"]];

apv = asm["Apv"]; apw = asm["Apw"];

(* the polynomial part in tau IS the obstruction to Fuchsian behaviour
   at infinity: a proper rational function decays, a polynomial part
   does not *)
polyPart[e_] := Module[{t = Together[e], num, den},
  num = Numerator[t]; den = Denominator[t];
  Expand[PolynomialQuotient[num, den, tt]]];

report[label_, sub_, dv_, dw_] := Module[{ahat, pp, bad, degs},
  ahat = Map[Together, (apv /. sub) dv + (apw /. sub) dw, {2}];
  pp = Map[polyPart, ahat, {2}];
  bad = Position[pp, x_ /; ! TrueQ[x === 0], {2}];
  degs = Map[If[TrueQ[# === 0], -1, Exponent[#, tt]] &, pp, {2}];
  Print["--- ", label];
  Print["    entries with nonzero polynomial part: ", Length[bad], " at ", bad];
  Print["    max polynomial degree in tau: ", Max[Flatten[degs]]];
  Print["    degree matrix: ", degs]];

base = {1/4, 1/4};
dv = vv - base[[1]]; dw = ww - base[[2]];
report["straight path {1/4,1/4} -> {v,w} (the attempted one)",
  {vv -> base[[1]] + tt dv, ww -> base[[2]] + tt dw}, dv, dw];
report["segment 1: v varies, w fixed at 1/4",
  {vv -> 1/4 + tt (vv - 1/4), ww -> 1/4}, vv - 1/4, 0];
report["segment 2: w varies, v free",
  {vv -> vv, ww -> 1/4 + tt (ww - 1/4)}, 0, ww - 1/4];
report["straight path from a different base {1/3,1/5}",
  {vv -> 1/3 + tt (vv - 1/3), ww -> 1/5 + tt (ww - 1/5)}, vv - 1/3, ww - 1/5];

Print["=== which BLOCK carries the obstruction (straight path) ==="];
sub0 = {vv -> base[[1]] + tt dv, ww -> base[[2]] + tt dw};
ahat0 = Map[Together, (apv /. sub0) dv + (apw /. sub0) dw, {2}];
Do[
  Module[{ri = asm["Ranges"][[i]], rj = asm["Ranges"][[j]], pp},
    pp = Map[polyPart, ahat0[[ri, rj]], {2}];
    If[! AllTrue[Flatten[pp], TrueQ[# === 0] &],
      Print["  block (", i, ",", j, ") rows ", asm["Blocks"][[i]], " <- ",
        asm["Blocks"][[j]], "  degrees ",
        Map[If[TrueQ[# === 0], -1, Exponent[#, tt]] &, pp, {2}],
        "  types ", asm["Forms"][[i]]["Type"], "/", asm["Forms"][[j]]["Type"]]]],
  {i, Length[asm["Ranges"]]}, {j, Length[asm["Ranges"]]}];
