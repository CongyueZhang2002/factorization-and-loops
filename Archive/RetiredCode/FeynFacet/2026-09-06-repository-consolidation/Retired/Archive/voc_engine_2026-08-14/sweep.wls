#!/usr/bin/env wolframscript
(* Assembly sweep: for each family, run SCC ordering + block-diagonal
   assembly + the conjugation certificate (no solving).  Resumable:
   one result file per family under sweep/.  Per-family time cap. *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
out = FileNameJoin[{dir, "sweep"}];
If[!DirectoryQ[out], CreateDirectory[out]];

cap = If[Length[$ScriptCommandLine] > 1, ToExpression[$ScriptCommandLine[[2]]], 900];
budget = If[Length[$ScriptCommandLine] > 2, ToExpression[$ScriptCommandLine[[3]]], 3600];
(* default: the four off-diagonal stragglers (all-rational) plus two
   chart-carrying families, which exercise the sqrtQ machinery in the
   assembly (CF319 is the representative family of chart class 130) *)
fams = If[Length[$ScriptCommandLine] > 3, StringSplit[$ScriptCommandLine[[4]], ","],
   {"CF360", "CF123", "CF269", "CF263", "CF13", "CF319"}];

VoCLog["sweep: ", Length[fams], " families, per-family cap ", cap, "s, total budget ", budget, "s"];
t00 = AbsoluteTime[];
Do[
 Module[{fam = fams[[i]], f, res, t0, pf, asm},
  f = FileNameJoin[{out, fam <> ".wl"}];
  If[FileExistsQ[f], VoCLog[fam, ": cached"],
   If[AbsoluteTime[] - t00 > budget, VoCLog["budget exhausted, stopping"]; Break[]];
   t0 = AbsoluteTime[];
   res = TimeConstrained[
     pf = VoCPrepareFamily[fam];
     asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"], "Verbose" -> False];
     <|"Family" -> fam, "Status" -> asm["Status"], "SCCAgrees" -> pf["SCCAgrees"],
       "N" -> Length[pf["System"]["Av"]], "NBlocks" -> Length[pf["Blocks"]],
       "Dims" -> Tally[Length /@ pf["Blocks"][[All, 1]]],
       "ClassIDs" -> If[asm["Status"] === "OK", asm["ClassIDs"], pf["Blocks"][[All, 2]]],
       "HasChart" -> If[asm["Status"] === "OK",
          AnyTrue[Table[asm["Forms"][[s]]["Chart"], {s, Length[asm["Blocks"]]}], # =!= None &], Missing[]],
       "Certificate" -> If[asm["Status"] === "OK", KeyDrop[asm["Certificate"], "DiagonalPerBlock"], Missing[]],
       "CertificateOK" -> If[asm["Status"] === "OK", VoCCertificateOK[asm], False],
       "Failures" -> If[asm["Status"] === "FormFailed", asm["Failures"][[All, 2]], Missing[]]|>,
     cap, <|"Family" -> fam, "Status" -> "Timeout", "Cap" -> cap|>];
   res = Join[res, <|"Seconds" -> Round[AbsoluteTime[] - t0, 0.1]|>];
   VoCPut[res, f];
   VoCLog[fam, ": ", res["Status"], " certOK=", res["CertificateOK"], " n=", res["N"],
     " blocks=", res["NBlocks"], " chart=", res["HasChart"], "  ", res["Seconds"], "s"]]],
 {i, Length[fams]}];
VoCLog["sweep done, ", Round[AbsoluteTime[] - t00], "s total"];
