#!/usr/bin/env wolframscript
(* (a) CF360 end-to-end after the Chart-key schema fix.
   (b) DIAGNOSIS of the CF123/CF269/CF263 900 s timeouts: print the depth
       budget WITHOUT solving, to test whether the depth explodes along
       chains of 1/eps off-diagonal couplings.  No tuning. *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

kmin = 0; kmaxT = 2; target = {1/2, 1/5};

VoCLog["=== (b) DEPTH BUDGETS (no solve) ==="];
Do[Module[{pf, asm, ahat, budget, t0},
  t0 = AbsoluteTime[];
  pf = VoCPrepareFamily[fam];
  asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"],
     "Verbose" -> False];
  If[asm["Status"] =!= "OK",
   VoCLog[fam, ": assembly ", asm["Status"], "  ", InputForm[asm["Failures"]]],
   ahat = VoCPathMatrix[asm, target, VoCBasePoint];
   budget = VoCDepthBudget[asm, ahat, kmaxT];
   VoCLog[fam, ": ", asm["N"], " masters, ", Length[asm["Blocks"]], " blocks"];
   VoCLog["   depth budget need = ", InputForm[budget["Need"]],
     "   MAX DEPTH = ", Max[budget["Need"]], "  (kmax asked = ", kmaxT, ")"];
   VoCLog["   distinct rmin values = ",
     InputForm[DeleteDuplicates[DeleteCases[Flatten[budget["RMin"]], Infinity]]]];
   VoCLog["   orders to solve = ", Total[budget["Need"] - kmin + 1],
     "   (", Round[AbsoluteTime[] - t0, 0.1], "s to here)"]]],
 {fam, {"CF123", "CF263", "CF269"}}];

VoCLog["=== (a) CF360 END-TO-END ==="];
Module[{pf, asm, solv, ms, chk, t0, tr0, n0, n1, words},
 t0 = AbsoluteTime[];
 pf = VoCPrepareFamily["CF360"];
 asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"],
    "Verbose" -> False];
 VoCLog["CF360: assembly ", asm["Status"], "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
 If[asm["Status"] =!= "OK",
  VoCLog["  failures ", InputForm[asm["Failures"]]],
  VoCLog["  ", asm["N"], " masters, ", Length[asm["Blocks"]], " blocks, dims ",
    InputForm[Tally[Length /@ asm["Blocks"]]], ", classes ", InputForm[asm["ClassIDs"]]];
  VoCLog["  certificate = ", InputForm[KeyDrop[asm["Certificate"], "DiagonalPerBlock"]]];
  VoCLog["  certificate OK: ", VoCCertificateOK[asm]];
  ahat = VoCPathMatrix[asm, target, VoCBasePoint];
  VoCLog["  depth budget = ", InputForm[VoCDepthBudget[asm, ahat, kmaxT]["Need"]]];
  t0 = AbsoluteTime[];
  solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target, "Verbose" -> True];
  VoCLog["  solve ", solv["Status"], ": ", solv["NIntegrals"], " quadratures in ",
    Round[solv["TotalSeconds"], 0.01], "s (",
    Round[1000 solv["TotalSeconds"]/Max[solv["NIntegrals"], 1], 0.1], " ms each), total ",
    Round[AbsoluteTime[] - t0, 0.1], "s"];
  If[solv["Status"] === "OK",
   VoCLog["  per-quadrature exact check: ", solv["QuadPass"], "   [",
     Count[Flatten[solv["QuadCheck"][[All, "Zero"]]], True], " of ",
     Length[Flatten[solv["QuadCheck"][[All, "Zero"]]]], " exact zeros]"];
   words = DeleteDuplicates[Cases[Values[solv["F"]], G[wq_List, _] :> wq, {0, Infinity}]];
   VoCLog["  distinct G words ", Length[words], "  max weight ",
     If[words === {}, 0, Max[Length /@ words]]];
   tr0 = VoCTOrderMin[asm]; n0 = kmin + tr0; n1 = n0 + kmaxT;
   ms = VoCMasterSeries[asm, solv, {n0, n1}];
   VoCLog["  master series orders ", n0, "..", n1, " leaves ", LeafCount /@ ms["I"]];
   t0 = AbsoluteTime[];
   chk = VoCCheckDEPath[asm, solv, ms, Range[n0, n1 - 1]];
   VoCLog["  path-frame exact DE check: ", InputForm[{#["Order"], #["Zero"]} & /@ chk],
     "   PASS=", AllTrue[chk, #["Zero"] === {True} &],
     "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
   VoCPut[<|"Family" -> "CF360", "N" -> asm["N"], "CertificateOK" -> VoCCertificateOK[asm],
      "SolveStatus" -> solv["Status"], "QuadPass" -> solv["QuadPass"],
      "NIntegrals" -> solv["NIntegrals"], "QuadSeconds" -> solv["TotalSeconds"],
      "Depth" -> solv["Need"], "DECheck" -> ({#["Order"], #["Zero"]} & /@ chk),
      "DEPass" -> AllTrue[chk, #["Zero"] === {True} &]|>,
     FileNameJoin[{dir, "stragglers_gpl", "CF360.wl"}]]]]];

VoCLog["=== DIAG DONE ==="];
