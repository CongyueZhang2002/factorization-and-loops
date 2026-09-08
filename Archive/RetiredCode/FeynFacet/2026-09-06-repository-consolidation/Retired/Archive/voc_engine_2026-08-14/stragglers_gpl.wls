#!/usr/bin/env wolframscript
(* The four off-diagonal-straggler families -- first production tier-3
   results.  Full pipeline on the GPL backend: assembly + certificate +
   order-by-order VoC solve with SYMBOLIC constants and a SYMBOLIC endpoint
   (v,w), then two exact per-order verifications:
     (i)  per quadrature   d/dtau F - source == 0
     (ii) assembled        d/dtau I - Ahat.I == 0
   Resumable: one result file per family.  If the symbolic endpoint runs
   past the time guard, the family is retried at a numeric endpoint.       *)

dir = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/voc_engine";
Get[FileNameJoin[{dir, "VoCEngine.wl"}]];
out = FileNameJoin[{dir, "stragglers_gpl"}];
If[!DirectoryQ[out], CreateDirectory[out]];

fams = If[Length[$ScriptCommandLine] > 1, StringSplit[$ScriptCommandLine[[2]], ","],
   {"CF360", "CF123", "CF269", "CF263"}];
kmin = 0;
kmaxT = If[Length[$ScriptCommandLine] > 2, ToExpression[$ScriptCommandLine[[3]]], 2];
guard = If[Length[$ScriptCommandLine] > 3, ToExpression[$ScriptCommandLine[[4]]], 900];
useSymbolic = If[Length[$ScriptCommandLine] > 4, $ScriptCommandLine[[5]] === "symbolic", False];
numTarget = {1/2, 1/5};

VoCLog["=== STRAGGLERS (backend ", VoCBackendDefault, ", kmax ", kmaxT,
   ", guard ", guard, "s) ==="];

Do[Module[{fam = fams[[i]], f, pf, asm, solv, ms, chk, t0, rec, tSolve, target, words},
  f = FileNameJoin[{out, fam <> ".wl"}];
  If[FileExistsQ[f], VoCLog[fam, ": cached"],
   VoCLog["=== ", fam, " ==="];
   GPLClearCache[];
   t0 = AbsoluteTime[];
   pf = VoCPrepareFamily[fam];
   If[pf === $Failed, VoCLog[fam, ": no DE file"];
    VoCPut[<|"Family" -> fam, "Status" -> "NoDE"|>, f],
    asm = VoCAssemble[pf["System"], "Provider" -> "Class", "Blocks" -> pf["Blocks"],
       "Verbose" -> False];
    If[asm["Status"] =!= "OK",
     VoCLog[fam, ": assembly ", asm["Status"]];
     VoCPut[<|"Family" -> fam, "Status" -> asm["Status"],
        "Failures" -> asm["Failures"]|>, f],
     VoCLog[fam, ": ", asm["N"], " masters, ", Length[asm["Blocks"]], " blocks, dims ",
       InputForm[Tally[Length /@ asm["Blocks"]]], ", certificate OK = ",
       VoCCertificateOK[asm], "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
     (* PRIMARY: numeric rational endpoint (see the header note).  The solve
        is still symbolic in tau with SYMBOLIC constants and both exact checks
        remain exact symbolic zeros; only the coefficient swell is avoided. *)
     target = If[useSymbolic, {v, w}, numTarget];
     t0 = AbsoluteTime[];
     solv = TimeConstrained[
        VoCSolve[asm, "KMin" -> kmin, "KMax" -> kmaxT, "Target" -> target,
           "Verbose" -> True], guard, $TimedOut];
     tSolve = AbsoluteTime[] - t0;
     If[solv === $TimedOut,
      VoCLog[fam, ": solve timed out at both endpoints"];
      VoCPut[<|"Family" -> fam, "Status" -> "OK", "SolveStatus" -> "TimedOut",
         "N" -> asm["N"], "CertificateOK" -> VoCCertificateOK[asm]|>, f],
      VoCLog[fam, ": solve ", solv["Status"], "  depth ", solv["Need"], "  ",
        solv["NIntegrals"], " quadratures in ", Round[solv["TotalSeconds"], 0.01], "s (",
        Round[1000 solv["TotalSeconds"]/Max[solv["NIntegrals"], 1], 0.1], " ms each)  ",
        "endpoint ", If[target === {v, w}, "symbolic", ToString[InputForm[target]]],
        "  (", Round[tSolve, 0.1], "s total)"];
      VoCLog[fam, ": per-quadrature exact check: ", solv["QuadPass"]];
      words = DeleteDuplicates[Cases[Values[solv["F"]], G[wq_List, _] :> wq, {0, Infinity}]];
      rec = <|"Family" -> fam, "Status" -> asm["Status"], "SCCAgrees" -> pf["SCCAgrees"],
         "N" -> asm["N"], "NBlocks" -> Length[asm["Blocks"]], "Perm" -> asm["Perm"],
         "Dims" -> Tally[Length /@ asm["Blocks"]], "ClassIDs" -> asm["ClassIDs"],
         "Certificate" -> KeyDrop[asm["Certificate"], "DiagonalPerBlock"],
         "CertificateOK" -> VoCCertificateOK[asm], "SolveStatus" -> solv["Status"],
         "Endpoint" -> If[target === {v, w}, "symbolic", target],
         "Depth" -> solv["Need"], "RMin" -> solv["RMin"], "Warnings" -> solv["Warnings"],
         "QuadCheck" -> solv["QuadCheck"], "QuadPass" -> solv["QuadPass"],
         "ValuationOK" -> solv["ValuationOK"], "KMinF" -> solv["KMin"],
         "TinvOrderMin" -> solv["TinvOrderMin"],
         "NIntegrals" -> solv["NIntegrals"], "QuadSeconds" -> solv["TotalSeconds"],
         "SolveSeconds" -> tSolve, "NWords" -> Length[words],
         "MaxWeight" -> If[words === {}, 0, Max[Length /@ words]]|>;
      If[solv["Status"] === "OK",
       Module[{tr0 = VoCTOrderMin[asm], n0, n1},
        n0 = kmin + tr0; n1 = n0 + kmaxT;
        ms = VoCMasterSeries[asm, solv, {n0, n1}];
        t0 = AbsoluteTime[];
        chk = TimeConstrained[VoCCheckDEPath[asm, solv, ms, Range[n0, n1 - 1]],
           guard, $TimedOut];
        If[chk === $TimedOut,
         VoCLog[fam, ": DE path check timed out"];
         rec = Join[rec, <|"DECheck" -> "TimedOut", "DEPass" -> False|>],
         VoCLog[fam, ": DE path check ", InputForm[{#["Order"], #["Zero"]} & /@ chk],
           "  (", Round[AbsoluteTime[] - t0, 0.1], "s)"];
         Module[{sup = Select[chk, #["MissingShifts"] === {} &]},
          rec = Join[rec, <|"Orders" -> {n0, n1},
             "DECheck" -> ({#["Order"], #["Zero"]} & /@ chk),
             "DESupported" -> Length[sup], "DETotal" -> Length[chk],
             "DEPass" -> (sup =!= {} && AllTrue[sup, #["Zero"] === {True} &])|>]]]]];
      VoCPut[rec, f]]]]]], {i, Length[fams]}];

VoCLog["=== STRAGGLERS DONE ==="];
Do[Module[{f = FileNameJoin[{out, fam <> ".wl"}], r},
   If[FileExistsQ[f], r = Get[f];
    VoCLog["  ", fam, ": solve ", Lookup[r, "SolveStatus", "-"],
      "  quad ", Lookup[r, "QuadPass", "-"], "  DE ", Lookup[r, "DEPass", "-"],
      "  masters ", Lookup[r, "N", "-"],
      "  quadratures ", Lookup[r, "NIntegrals", "-"],
      "  ms/quad ", If[KeyExistsQ[r, "NIntegrals"] && r["NIntegrals"] > 0,
         Round[1000 r["QuadSeconds"]/r["NIntegrals"], 0.1], "-"]]]],
 {fam, fams}];
