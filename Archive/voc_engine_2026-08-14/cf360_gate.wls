#!/usr/bin/env wolframscript
(* CF360 end-to-end, numeric endpoint, with the master series carried far
   enough that the assembled path-frame DE check is actually SUPPORTED.
   CF360 has global rmin = -3 (1/eps^3 off-diagonal couplings), so checking
   order nn needs the master series up to nn+3; with kmax=2 (orders 0..2) no
   order was checkable at all and the old run reported a spurious False. *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

kmin = 0;
kmaxT = If[Length[$ScriptCommandLine] > 1, ToExpression[$ScriptCommandLine[[2]]], 3];
target = {1/2, 1/5};

VoCLog["=== CF360 GATE (numeric endpoint ", InputForm[target], ", kmax ", kmaxT, ") ==="];
pf = VoCPrepareFamily["CF360"];
asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
VoCLog["assembly ", asm["Status"], "  ", asm["N"], " masters, ", Length[asm["Blocks"]],
  " blocks, dims ", InputForm[Tally[Length /@ asm["Blocks"]]], ", classes ",
  InputForm[asm["ClassIDs"]]];
If[asm["Status"] =!= "OK", VoCLog["failures ", InputForm[asm["Failures"]]]; Quit[1]];
VoCLog["certificate OK: ", VoCCertificateOK[asm], "   ",
  InputForm[KeyDrop[asm["Certificate"], "DiagonalPerBlock"]]];
VoCLog["SCC recomputation agrees: ", pf["SCCAgrees"]];

t0 = AbsoluteTime[];
solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> True];
VoCLog["solve ", solv["Status"], ": ", solv["NIntegrals"], " quadratures in ",
  Round[solv["TotalSeconds"], 0.01], "s (",
  Round[1000 solv["TotalSeconds"]/Max[solv["NIntegrals"], 1], 0.1], " ms each), total ",
  Round[AbsoluteTime[] - t0, 0.1], "s"];
If[solv["Status"] =!= "OK", VoCLog["CF360 FAILED in the quadratures"]; Quit[1]];
VoCLog["valuation: KMin(physical) = ", solv["KMinPhysical"], "  ord(T^-1)min = ",
  solv["TinvOrderMin"], "  F solved from eps^", solv["KMin"],
  "  constrained orders ", InputForm[solv["ValuationOrders"]],
  "  equations ", solv["ValuationEqs"], "  ValuationOK = ", solv["ValuationOK"]];
If[!TrueQ[solv["ValuationOK"]], VoCLog["CF360 FAILED the valuation assertion"]; Quit[1]];
VoCLog["per-quadrature exact check: ", solv["QuadPass"], "   [",
  Count[Flatten[solv["QuadCheck"][[All, "Zero"]]], True], " of ",
  Length[Flatten[solv["QuadCheck"][[All, "Zero"]]]], " exact zeros]"];
words = DeleteDuplicates[Cases[Values[solv["F"]], G[wq_List, _] :> wq, {0, Infinity}]];
VoCLog["distinct G words ", Length[words], "  max weight ",
  If[words === {}, 0, Max[Length /@ words]], "  indices ",
  InputForm[DeleteDuplicates[Flatten[words]]]];

tr0 = VoCTOrderMin[asm]; n0 = kmin + tr0; n1 = n0 + kmaxT;
ms = VoCMasterSeries[asm, solv, {n0, n1}];
VoCLog["master series orders ", n0, "..", n1, " leaves ", LeafCount /@ ms["I"]];

t0 = AbsoluteTime[];
chk = VoCCheckDEPath[asm, solv, ms, Range[n0, n1 - 1]];
Do[VoCLog["  order eps^", c["Order"], ": ", InputForm[c["Zero"]],
   If[c["MissingShifts"] =!= {}, "   (needs master series up to eps^" <>
      ToString[c["NeedUpTo"]] <> ")", ""]], {c, chk}];
supported = Select[chk, #["MissingShifts"] === {} &];
pass = supported =!= {} && AllTrue[supported, #["Zero"] === {True} &];
VoCLog["path-frame exact DE check: ", Length[supported], " of ", Length[chk],
  " orders supported; PASS on supported orders = ", pass, "  (",
  Round[AbsoluteTime[] - t0, 0.1], "s)"];

VoCLog["=== CF360: quadrature ", solv["QuadPass"], " ; assembled DE ", pass, " ==="];
VoCPut[<|"Family" -> "CF360", "N" -> asm["N"], "NBlocks" -> Length[asm["Blocks"]],
   "ClassIDs" -> asm["ClassIDs"], "CertificateOK" -> VoCCertificateOK[asm],
   "SolveStatus" -> solv["Status"], "QuadPass" -> solv["QuadPass"],
   "ValuationOK" -> solv["ValuationOK"], "ValuationOrders" -> solv["ValuationOrders"],
   "KMinF" -> solv["KMin"], "TinvOrderMin" -> solv["TinvOrderMin"],
   "NIntegrals" -> solv["NIntegrals"], "QuadSeconds" -> solv["TotalSeconds"],
   "Depth" -> solv["Need"], "KMax" -> kmaxT,
   "DECheck" -> ({#["Order"], #["Zero"]} & /@ chk),
   "DESupported" -> Length[supported], "DEPass" -> pass|>,
  FileNameJoin[{dir, "stragglers_gpl", "CF360.wl"}]];
VoCLog["=== CF360 DONE ==="];
