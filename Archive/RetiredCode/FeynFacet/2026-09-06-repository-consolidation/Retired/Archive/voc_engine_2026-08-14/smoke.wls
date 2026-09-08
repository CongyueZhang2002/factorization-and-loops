#!/usr/bin/env wolframscript
(* fast component smoke test: loaders, sqrt algebra, chart pullback,
   scalar canonicaliser, equivalence maps, CF3 assembly certificate *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];

VoCLog["--- 1. loaders ---"];
VoCLog["blocks: ", Length[VoCBlocksAll[]], "  classes: ", Length[VoCClassesAll[]],
  "  assignments: ", Length[VoCAssignAll[]]];
VoCLog["forms on disk: ", Length[FileNames["class*.wl", VoCFormsDir]]];
VoCLog["class1 form: ", InputForm[VoCClassForm[1]]];

VoCLog["--- 2. inert sqrt algebra ---"];
Module[{k, e},
  k = VoCRegisterRoot[(1 - v - w)^2 - 4 v w];
  e = 1/(1 + sqrtQ[k]);
  VoCLog["  1/(1+sqrtQ) rationalised: ", InputForm[VoCCanon[e]]];
  VoCLog["  sqrtQ^2 - q == 0: ", VoCZeroQ[sqrtQ[k]^2 - VoCRootQ[k]]];
  VoCLog["  d/dv sqrtQ check (numeric): ",
   Module[{d = VoCD[sqrtQ[k], v], pt = {v -> 3/10, w -> 1/5}, qq},
    qq = VoCRootQ[k] /. pt;
    N[(d /. sqrtQ[k] -> Sqrt[VoCRootQ[k]] /. pt) - (D[Sqrt[VoCRootQ[k]], v] /. pt), 20]]];
  VoCLog["  swap of a root: q=", InputForm[VoCRootQ[k]], " -> ",
   InputForm[VoCSwap[sqrtQ[k]]]]];

VoCLog["--- 3. chart pullback (class 130, Kallen chart) ---"];
Module[{rep, bc},
  rep = VoCFormInVW[130];
  If[rep === $Failed, VoCLog["  FAILED"],
   VoCLog["  q = ", InputForm[rep["RootQ"]]];
   VoCLog["  t(v,w) = ", InputForm[rep["TExpr"]]];
   bc = VoCChartBranchCheck[130, {3/10, 1/5}];
   VoCLog["  branch check at (3/10,1/5): q=", bc["q"], " t=", bc["t"],
     " recovered w=", bc["Recovered"], " residual=", bc["Residual"]];
   bc = VoCChartBranchCheck[130, {1/4, 1/4}];
   VoCLog["  branch check at the base point (1/4,1/4): q=", bc["q"],
     " residual=", bc["Residual"]]]];

VoCLog["--- 4. scalar canonicaliser on the NLO diagonal ---"];
Module[{sys = VoCNLOSystem[], r},
  VoCLog["  NLO basis: ", Length[sys["Basis"]], " masters"];
  Do[r = VoCScalarEpsForm[sys["Av"][[i, i]], sys["Aw"][[i, i]]];
   VoCLog["   row ", i, ": T = ", If[r === $Failed, "FAILED", InputForm[r["T"][[1, 1]]]],
     "   Ev = ", If[r === $Failed, "-", InputForm[r["Ev"][[1, 1]]]],
     "   Ew = ", If[r === $Failed, "-", InputForm[r["Ew"][[1, 1]]]]],
   {i, Length[sys["Av"]]}]];

VoCLog["--- 5. NLO assembly certificate ---"];
Module[{sys = VoCNLOSystem[], asm},
  asm = VoCAssemble[sys, "Provider" -> "Scalar"];
  VoCLog["  status ", asm["Status"], "  perm ", asm["Perm"]];
  VoCLog["  certificate: ", InputForm[KeyDrop[asm["Certificate"], "DiagonalPerBlock"]]];
  VoCLog["  overall: ", VoCCertificateOK[asm]]];

VoCLog["--- 6. CF3 assembly through the class forms ---"];
Module[{pf, asm},
  pf = VoCPrepareFamily["CF3"];
  VoCLog["  blocks from file: ", InputForm[pf["Blocks"]], "  SCC recomputation agrees: ", pf["SCCAgrees"]];
  asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"]];
  VoCLog["  status ", asm["Status"], " perm ", asm["Perm"], " classes ", asm["ClassIDs"]];
  If[asm["Status"] === "OK",
   VoCLog["  maps: ", InputForm[Table[asm["Forms"][[i]]["Map"], {i, Length[asm["Blocks"]]}]]];
   VoCLog["  T: ", InputForm[Table[asm["Forms"][[i]]["T"], {i, Length[asm["Blocks"]]}]]];
   VoCLog["  certificate: ", InputForm[KeyDrop[asm["Certificate"], "DiagonalPerBlock"]]];
   VoCLog["  A'v = ", InputForm[asm["Apv"]]];
   VoCLog["  A'w = ", InputForm[asm["Apw"]]];
   VoCLog["  overall: ", VoCCertificateOK[asm]],
   VoCLog["  failures: ", InputForm[asm["Failures"]]]]];

VoCLog["--- 7. 2F1 eps-series against Mathematica ---"];
Module[{co, z = 8/9, e0 = 1/1000, ours, ref},
  co = VoC2F1Series[z, 5, 40];
  ours = Sum[co[[k + 1]] e0^k, {k, 0, 5}];
  ref = N[Hypergeometric2F1[1, 1, 1 - e0, z], 40];
  VoCLog["  z=8/9, eps=1/1000: ours ", ours, "  ref ", ref, "  rel.diff ", N[Abs[ours/ref - 1], 5]];
  co = VoC2F1Series[-2/3, 5, 40];
  ours = Sum[co[[k + 1]] e0^k, {k, 0, 5}];
  ref = N[Hypergeometric2F1[1, 1, 1 - e0, -2/3], 40];
  VoCLog["  z=-2/3: rel.diff ", N[Abs[ours/ref - 1], 5]]];

VoCLog["=== SMOKE DONE ==="];
