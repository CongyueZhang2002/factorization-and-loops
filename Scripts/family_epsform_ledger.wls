#!/usr/bin/env wolframscript
(* Build the FamilyEpsForms ledger (README.md) from the records written by
   Scripts/family_epsform.wls and the payoff records written by
   Scripts/epsform_offdiag_cf230_payoff.wls.

   Usage: family_epsform_ledger.wls <outdir> <payoffdir> [skippedfile]

   The records are read for their SCALAR fields only (no matrices are
   touched), so this is cheap even on the 24x24 families.  The ledger is
   the reviewers' item "the ledger must state the coupling-dlog assumption
   as a certificate part": after this sweep the coupling structure is a
   MEASURED field of every family record and the five-part gate is a
   per-family certificate, not an assumption. *)

$HistoryLength = 0;
argv = Rest[$ScriptCommandLine];
outdir = argv[[1]];
payoffdir = If[Length[argv] >= 2, argv[[2]], outdir];
skippedFile = If[Length[argv] >= 3, argv[[3]], ""];

Quiet[Clear["Global`x", "Global`y", "Global`v", "Global`w", "Global`eps"]];

$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x",
  "y", "u", "t", "tau", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    s_Symbol /; MemberQ[$normalizeNames, SymbolName[s]] && Context[s] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}];
  expr /. rules];

(* exactly family_epsform_CF<digits>.wl: the _xyview copies, the
   pre-driver _offdiag_ artifact and its _state_/_sector6_D side files are
   not records and one of them is a bare List, which would leak
   unevaluated Lookups into the table *)
files = Select[FileNames["family_epsform_*.wl", outdir],
  StringMatchQ[FileNameTake[#], RegularExpression["family_epsform_CF\\d+\\.wl"]] &];
Print["[ledger] ", Length[files], " family records in ", outdir];

rows = Table[
  Module[{r, fam, payoff, pf, mech, purity, tim, cleanupWall},
   r = normalizeSymbols[Get[f]];
   If[! (AssociationQ[r] && KeyExistsQ[r, "Status"]),
     Print["[ledger] SKIP ", FileNameTake[f], " (not a family record)"];
     Return[Nothing, Module]];
   fam = Lookup[r, "Family", FileBaseName[f]];
   purity = Lookup[r, "Purity", <||>];
   tim = Lookup[r, "Timings", <||>];
   mech = Lookup[r, "Mechanisms", {}];
   cleanupWall = Total[Table[Lookup[tim, k, 0],
     {k, {"M1_STRIP", "M2_FUCHS", "M3_DLOGEPS", "M4_CANONICA", "M5_DLOGEPS"}}]];
   pf = FileNameJoin[{payoffdir, "payoff_blockwise_" <> fam <> ".wl"}];
   payoff = If[FileExistsQ[pf],
     Module[{p = Quiet[Check[normalizeSymbols[Get[pf]], $Failed]]},
      If[AssociationQ[p],
       <|"Status" -> Lookup[p, "Status", "?"],
         "Total" -> Lookup[Lookup[Lookup[p, "Blockwise", <||>], "Timing", <||>],
            "Total", Lookup[p, "Seconds", Missing[]]],
         "Seconds" -> Lookup[p, "Seconds", Missing[]],
         "MaxWords" -> Lookup[Lookup[p, "Blockwise", <||>], "MaxWordCount", Missing[]],
         "MaxLeaves" -> Lookup[Lookup[p, "Blockwise", <||>], "MaxCoefficientLeaves",
            Missing[]],
         "CertificateAllZero" -> Lookup[Lookup[Lookup[p, "Blockwise", <||>],
            "Certificate", <||>], "AllZero", Missing[]]|>,
       <|"Status" -> "unreadable"|>]],
     <|"Status" -> "notrun"|>];
   <|"Family" -> fam,
     "Frame" -> Lookup[r, "Frame", "?"],
     "Dim" -> Lookup[r, "Dim", "?"],
     "Blocks" -> Length[Lookup[r, "Ranges", {}]],
     "BlockDims" -> Lookup[r, "BlockDims", {}],
     "Classes" -> Lookup[r, "Classes", {}],
     "Status" -> Lookup[r, "Status", "?"],
     "Gate" -> Lookup[r, "GateVerdict", False],
     "GateDetail" -> Lookup[r, "Gate", <||>],
     "LiveCouplings" -> Length[Select[
        Lookup[Lookup[Lookup[purity, "Path", <||>], "Measurement", <||>], "Records", {}],
        ! TrueQ[#["Zero"]] && #["I"] =!= #["J"] &]],
     "NonPure" -> Lookup[purity, "NumberOfNonPureCouplingPairs", "?"],
     "PureOnPath" -> Lookup[purity, "PureOnPath", "?"],
     "MaxPoleTau" -> Lookup[Lookup[Lookup[purity, "Path", <||>], "Measurement", <||>],
        "MaxPoleOrder", "?"],
     "EpsLoci" -> Lookup[purity, "EpsDependentKinematicDenominators", {}],
     "Mechanisms" -> mech,
     "CleanupWall" -> Round[N[cleanupWall], 0.1],
     "TotalSeconds" -> Lookup[r, "TotalSeconds", "?"],
     "Timings" -> tim,
     "Letters" -> Length[Lookup[r, "Letters", {}]],
     "Obstruction" -> Lookup[Lookup[Lookup[r, "Cleanup", <||>], "Obstruction", <||>],
        "Classes", {}],
     "M2Note" -> Lookup[Lookup[Lookup[r, "Cleanup", <||>], "M2", <||>], "Note", "-"],
     "Payoff" -> payoff|>],
  {f, files}];
rows = DeleteCases[rows, Nothing];
rows = SortBy[rows, {If[IntegerQ[#["Dim"]], #["Dim"], 999] &, #["Family"] &}];

mechShort[m_List] := If[m === {}, "none",
  StringRiffle[m /. {"EpsLocusStrip" -> "M1", "FuchsPoleReduction" -> "M2",
     "DlogToEpsForm" -> "M3", "CanonicaOffDiagonal" -> "M4"}, "+"]];
num[x_] := If[NumberQ[x], ToString[NumberForm[N[x], {8, 2}]], ToString[x]];

skipped = If[skippedFile =!= "" && FileExistsQ[skippedFile],
  StringSplit[Import[skippedFile, "Text"], "\n"], {}];

md = StringJoin[
  "# Family eps-forms (stage 2, off-diagonal cleanup)\n\n",
  "Produced by `Scripts/family_epsform.wls` (one mission per family through the\n",
  "KernelPool).  One record `family_epsform_<family>.wl` per family; families\n",
  "whose frame is the source (v,w) additionally carry `_xyview.wl`, the same\n",
  "record with the two free symbols renamed v -> x, w -> y, so that\n",
  "`Scripts/epsform_offdiag_cf230_payoff.wls` (which transports in {x,y}) runs\n",
  "on them unchanged.\n\n",
  "## What a record certifies\n\n",
  "A family is ACCEPTED only if THE GATE passes exactly, on the ORIGINAL\n",
  "(permuted) connections pushed through `T_total = diag(T_i) . S`:\n\n",
  "1. `Ahat' = T^-1 A0 T - T^-1 dT` has `Ahat'/eps` eps-free entrywise;\n",
  "2. every entry is a sum of CONSTANT matrices times dlog of EPS-FREE letters\n",
  "   -- residues free of x, y and eps, equal between the two directions, and\n",
  "   the dlog reconstruction exact entrywise in BOTH variables (this also\n",
  "   excludes any polynomial part);\n",
  "3. the eps-form is flat;\n",
  "4. S is block lower triangular with (x,y)-free diagonal blocks;\n",
  "5. `T_total . T_total^-1 == 1` exactly, both ways.\n\n",
  "A CANONICA/Libra return SHAPE is never a criterion.  Each record carries the\n",
  "eleven measured gate flags under `\"Gate\"`.\n\n",
  "**The coupling-dlog property is no longer an assumption.**  Every record\n",
  "carries `\"Purity\"`: the exact decomposition of every coupling entry per\n",
  "(block pair, eps-order) on the transport path AND in each frame variable\n",
  "separately (pole orders, polynomial part, tau-free numerators, eps-dependent\n",
  "denominators).  The reviewers' open item -- state the coupling-dlog\n",
  "assumption as a certificate part -- is discharged per family by that field\n",
  "plus gate condition 2.\n\n",
  "## Consuming a record (the map back to the original masters)\n\n",
  "Everything in a record is indexed in the PERMUTED (DAG) basis:\n\n",
  "- `Perm` is the permutation; `Perm[[k]]` is the ORIGINAL row carried by\n",
  "  permuted index k, so the original system in this basis is\n",
  "  `A0 = Av[[Perm, Perm]]`.  It equals `Flatten[Blocks]`\n",
  "  (`MasterTransport.wl:1261`), and `Blocks` is already topologically\n",
  "  ordered (`blocks = blocks[[order]]`, :1259).  **Consistency check:**\n",
  "  `Length /@ Ranges === Length /@ Blocks` must hold; where it fails the\n",
  "  `Blocks` field is in class-assignment file order and `Flatten[Blocks]`\n",
  "  is NOT the permutation (true of the pre-driver\n",
  "  `family_epsform_CF230_offdiag_2026-08-17.wl`, kept here for reference).\n",
  "- `TTotal = TBlockDiagonal . S = diag(T_i) . S`, and\n",
  "  `EpsFormX = TTotal^-1 . A0x . TTotal - TTotal^-1 d_x TTotal`, so the map\n",
  "  back is **`I = TTotal . F`** with `F` solving the eps-form.\n",
  "- `S` is block lower triangular with (x,y)-free but **eps-DEPENDENT**\n",
  "  diagonal blocks (Lee's factor-out-eps step; `Gate[\"SUnipotent\"]` records\n",
  "  whether they are the identity).  `TTotal` is therefore eps-Laurent with a\n",
  "  per-block grading, and `TTotalEpsOrders` gives its `{min, max}` eps order:\n",
  "  **`I` at eps^n needs `F` at eps^(n - min)**, so a sweep must carry `F` to\n",
  "  `N - min` and regrade.  Measured examples: CF3 `S = diag(eps, 1, eps^-2)`,\n",
  "  CF27 `S = diag(eps^3, 1, eps^2, eps, 1, 1, 1, 1)` times units.\n",
  "- `Frame` / `Variables` say which system `A0` is: `SourceVW` means `(v,w)`\n",
  "  and `A0 = de[\"Av\"]/[\"Aw\"]` permuted; `Chart` means the connection PULLED\n",
  "  BACK to `v = x y, w = (1-x)(1-y)` in `{x,y}` -- comparing a chart record\n",
  "  against the `(v,w)` differential equation fails at every order.\n",
  "- The regulator is stored as ``Global`eps``.  Normalize by `SymbolName` with\n",
  "  an EXPLICIT rule list before use: once CANONICA is loaded in the same\n",
  "  subkernel a bare `eps` parses as ``CANONICA`eps`` and never cancels, and\n",
  "  the inline conditional-`ReplaceAll` spelling of the normalizer is measured\n",
  "  to insert its right-hand side unevaluated.\n\n",
  "## Cleanup mechanisms\n\n",
  "| tag | mechanism | cost class |\n|---|---|---|\n",
  "| M1 | closed-form strip of the eps-DEPENDENT apparent locus (N = M/q^(k-1), M read off the leading pole, d_var q inverted mod q) | seconds |\n",
  "| M2 | closed-form Moser/Fuchs pole reduction at the ordinary eps-FREE letters (Sylvester operator (k-1) + eps(R_i - R_j), forced right-to-left column order) | seconds to a minute |\n",
  "| M3 | CANONICA `TransformDlogToEpsForm`, an eps-ONLY transformation, once the connection is dlog with (x,y)-free residues | seconds |\n",
  "| M4 | CANONICA off-diagonal recursion driven subsector by subsector with per-subsector checkpoints, ansatz degrees escalated (0,0) -> (1,0) -> (1,1) -> (2,1) | minutes to ~30 min |\n\n",
  "## Ledger\n\n",
  "`couplings` = live off-diagonal (block pair) couplings on the path;\n",
  "`non-pure` = how many of them are NOT pure dlog with tau-free constant\n",
  "residues at some eps-order.  `cleanup` is the wall time of M1+M2+M3+M4 only\n",
  "(the assembly, the purity measurement and the gates are excluded and are in\n",
  "`total`).  `payoff` is the block-wise transport `Total` of\n",
  "`epsform_offdiag_cf230_payoff.wls` at orders {0,1} on the record.\n\n",
  "| family | frame | dim | blocks | couplings | non-pure | mechanism | cleanup s | total s | gate | letters | payoff Total s | measured obstruction |\n",
  "|---|---|---|---|---|---|---|---|---|---|---|---|---|\n",
  StringJoin[Table[StringJoin[
    "| ", r["Family"], " | ", ToString[r["Frame"]], " | ", ToString[r["Dim"]],
    " | ", ToString[r["Blocks"]], " | ", ToString[r["LiveCouplings"]],
    " | ", ToString[r["NonPure"]], " | ", mechShort[r["Mechanisms"]],
    " | ", num[r["CleanupWall"]], " | ", num[r["TotalSeconds"]],
    " | ", If[TrueQ[r["Gate"]], "PASSED", "**" <> ToString[r["Status"]] <> "**"],
    " | ", ToString[r["Letters"]],
    " | ", Which[
       r["Payoff"]["Status"] === "notrun", "-",
       NumberQ[r["Payoff"]["Total"]], num[r["Payoff"]["Total"]],
       True, ToString[r["Payoff"]["Status"]]],
    " | ", If[TrueQ[r["Gate"]], "-",
       StringRiffle[Join[
         If[r["M2Note"] === "CycleDetected", {"M2 cycle"}, {}],
         If[r["M2Note"] === "BudgetExhausted", {"M2 budget"}, {}],
         ToString /@ Lookup[r, "Obstruction", {}]], ", "]],
    " |\n"], {r, rows}]],
  "\n",
  "Totals: ", ToString[Length[rows]], " families, ",
  ToString[Count[rows, r_ /; TrueQ[r["Gate"]]]], " with the gate PASSED, ",
  ToString[Count[rows, r_ /; r["Status"] === "AlreadyEpsForm"]],
  " already a family eps-form as assembled, ",
  ToString[Count[rows, r_ /; MemberQ[r["Mechanisms"], "CanonicaOffDiagonal"]]],
  " needed the CANONICA off-diagonal recursion (M4).\n\n",
  "`measured obstruction` names WHY a gate failed, measured on the final state:\n",
  "`HigherPoles` a letter still carries a pole of order >= 2; `ResidueNotXYFree`\n",
  "all poles simple but a residue depends on x or y; `NonDlogRemainder` all poles\n",
  "simple and residues constant, yet `A_mu - Sum_a R_a dlog phi_a =!= 0` -- an\n",
  "ENTIRE part (a singularity at infinity), which no finite-letter strip and no\n",
  "CANONICA D-ansatz over the finite alphabet can remove; `M2 cycle` the\n",
  "two-variable Moser reduction reached a repeated state (guarded: the best\n",
  "state reached is kept, so M2 never hands M4 something worse).\n\n",
  If[skipped === {}, "",
   StringJoin["## Families skipped (they do not assemble today)\n\n",
     "These are the frame-availability blockers of `TransportProductionPlan.md`\n",
     "item B and are being fixed separately; no eps-form is attempted here.\n\n",
     StringJoin[Table["- " <> l <> "\n", {l, Select[skipped, # =!= "" &]}]], "\n"]],
  "## Provenance\n\n",
  "- driver `Scripts/family_epsform.wls`, ledger `Scripts/family_epsform_ledger.wls`\n",
  "- payoff `Scripts/epsform_offdiag_cf230_payoff.wls <family> 0,1 <record> <outdir>`\n",
  "- the CF230 record produced by the 2026-08-17 off-diagonal agent is kept\n",
  "  beside the driver's as `family_epsform_CF230_offdiag_2026-08-17.wl`\n",
  "  (with its `_state_*`/`_sector6_D` files) for comparison.\n",
  "- generated ", DateString[], "\n"];

Export[FileNameJoin[{outdir, "README.md"}], md, "Text"];
Print["[ledger] wrote ", FileNameJoin[{outdir, "README.md"}], " (", StringLength[md], " chars)"];
Do[Print["[ledger] ", r["Family"], " ", r["Frame"], " dim ", r["Dim"],
   " nonpure ", r["NonPure"], "/", r["LiveCouplings"],
   " mech ", mechShort[r["Mechanisms"]],
   " cleanup ", r["CleanupWall"], " total ", r["TotalSeconds"],
   " gate ", If[TrueQ[r["Gate"]], "PASSED", "FAILED:" <> ToString[r["Status"]]],
   " letters ", r["Letters"],
   " payoff ", r["Payoff"]["Status"], " ", Lookup[r["Payoff"], "Total", "-"]], {r, rows}];
"family_epsform_ledger complete"
