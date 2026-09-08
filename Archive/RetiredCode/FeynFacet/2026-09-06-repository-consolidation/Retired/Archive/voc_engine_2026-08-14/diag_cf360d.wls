#!/usr/bin/env wolframscript
(* Bookkeeping bug, or insufficient depth?
   Build I directly as the UN-expanded product T(eps).F(eps) from the same F,
   expand the residual in eps, and compare with the engine's per-order result.
   Same answer => not a bookkeeping bug; the assembled check simply needs F to
   greater depth than the SOLVE budget provides. *)
dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
kmin = 0; kmaxT = 2; target = {1/2, 1/5}; base = VoCBasePoint;
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> False];
n = asm["N"]; ranges = asm["Ranges"];
VoCLog["need = ", InputForm[solv["Need"]], "  A' rmin = ", solv["RMin"]];
dv = target[[1]] - base[[1]]; dw = target[[2]] - base[[2]];
sub = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
ahatO = Map[Together, (asm["Av"] dv + asm["Aw"] dw) /. sub, {2}];
Tfull = ConstantArray[0, {n, n}];
Do[Tfull[[ranges[[s]], ranges[[s]]]] = asm["Forms"][[s]]["T"], {s, Length[ranges]}];
Tp = Map[Together, Tfull /. sub, {2}];

(* F as an explicit eps-polynomial, each sector to ITS available depth *)
maxAvail[s_] := Max[Cases[Keys[solv["F"]], {s, m_} :> m]];
Ffull = Sum[eps^k VoCFVector[asm, solv, k], {k, kmin, Max[solv["Need"]]}];
VoCLog["F depth used per sector: ", InputForm[Table[{s, maxAvail[s]}, {s, Length[ranges]}]]];

Ifull = Tp.Ffull;
resid = VoCDtau /@ Ifull;
resid = resid - ahatO.Ifull;
(* expand the residual in eps and test order by order *)
Do[Module[{co},
  co = Map[Together, Coefficient[#, eps, kk] & /@ Map[Expand, resid], {1}];
  VoCLog["direct-product residual at eps^", kk, " per row: ",
    InputForm[Table[VoCZeroFn[co[[i]]], {i, n}]]]],
 {kk, 0, 1}];
VoCLog["=== DONE ==="];
