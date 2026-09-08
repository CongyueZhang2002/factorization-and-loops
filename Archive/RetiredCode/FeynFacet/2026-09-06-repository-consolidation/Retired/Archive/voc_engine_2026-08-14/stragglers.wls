#!/usr/bin/env wolframscript
(* The four off-diagonal-straggler families: full pipeline (assembly +
   certificate + order-by-order VoC solve with SYMBOLIC constants) at a
   numeric endpoint, then the exact per-order check of the ORIGINAL DE in
   the path frame (d/dtau), which is exact in tau and keeps the constants
   symbolic.  Resumable: one result file per family. *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
out = FileNameJoin[{dir, "stragglers"}];
If[!DirectoryQ[out], CreateDirectory[out]];

fams = If[Length[$ScriptCommandLine] > 1, StringSplit[$ScriptCommandLine[[2]], ","],
   {"CF3", "CF360", "CF123", "CF263", "CF269"}];
kmin = 0; kmaxT = If[Length[$ScriptCommandLine] > 2, ToExpression[$ScriptCommandLine[[3]]], 1];
target = {1/2, 1/5};

Do[Module[{fam = fams[[i]], f, pf, asm, solv, ms, chk, t0, rec},
  f = FileNameJoin[{out, fam <> ".wl"}];
  If[FileExistsQ[f], VoCLog[fam, ": cached"],
   VoCLog["=== ", fam, " ==="];
   t0 = AbsoluteTime[];
   pf = VoCPrepareFamily[fam];
   asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"]];
   If[asm["Status"] =!= "OK",
    VoCLog[fam, ": assembly ", asm["Status"]];
    VoCPut[<|"Family" -> fam, "Status" -> asm["Status"]|>, f],
    VoCLog[fam, ": assembled, certificate OK = ", VoCCertificateOK[asm],
      "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
    t0 = AbsoluteTime[];
    solv = VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target,
       "TimeLimit" -> 120, "Verbose" -> False];
    VoCLog[fam, ": solve ", solv["Status"], "  depth ", solv["Need"],
      "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
    rec = <|"Family" -> fam, "Status" -> asm["Status"], "SCCAgrees" -> pf["SCCAgrees"],
       "N" -> asm["N"], "NBlocks" -> Length[asm["Blocks"]], "Perm" -> asm["Perm"],
       "Dims" -> Tally[Length /@ asm["Blocks"]], "ClassIDs" -> asm["ClassIDs"],
       "Certificate" -> KeyDrop[asm["Certificate"], "DiagonalPerBlock"],
       "CertificateOK" -> VoCCertificateOK[asm], "SolveStatus" -> solv["Status"],
       "Depth" -> solv["Need"], "RMin" -> solv["RMin"], "Warnings" -> solv["Warnings"]|>;
    If[solv["Status"] === "OK",
     Module[{tr0 = VoCTOrderMin[asm], n0, n1},
      n0 = kmin + tr0; n1 = n0 + kmaxT;
      ms = VoCMasterSeries[asm, solv, {n0, n1}];
      t0 = AbsoluteTime[];
      chk = VoCCheckDEPath[asm, solv, ms, Range[n0, n1 - 1]];
      VoCLog[fam, ": DE path check ", InputForm[{#["Order"], #["Zero"]} & /@ chk],
        "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
      rec = Join[rec, <|"Orders" -> {n0, n1}, "DECheck" -> ({#["Order"], #["Zero"]} & /@ chk),
         "DEPass" -> AllTrue[chk, #["Zero"] === {True} &]|>]]];
    VoCPut[rec, f]]]], {i, Length[fams]}];
VoCLog["stragglers done"];
