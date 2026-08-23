#!/usr/bin/env wolframscript
(* S4 (the target) for the block-wise transport engine: CF230 and CF258
   in the two-variable chart, block-wise, at the requested epsilon
   orders.

   These are the two families whose MONOLITHIC path-ordered exponential
   exceeded the 1800 s budget three times (README, "Transport
   depth-vs-cost", 2026-08-16 night).  Nothing about the family changes
   here: the same chart, the same class forms, the same assembly and the
   same five-part certificate, the same axis-aligned path.  Only the
   transport is different.

   Reported, per family: status, wall time split into decomposition /
   recursion / certificate, the per-block per-order word counts, the
   largest rational coefficient, the peak memory, and the per-block
   per-order recursion certificate.

   Usage: blockwise_target.wls [FAMILY] [ORDERS] [OUTDIR]
     FAMILY  CF230 (default) or CF258
     ORDERS  "0,1" (default)                                          *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_blockwise";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
orders = If[Length[argv] >= 2, ToExpression /@ StringSplit[argv[[2]], ","], {0, 1}];
If[Length[argv] >= 3, outdir = argv[[3]]];
If[! DirectoryQ[outdir], CreateDirectory[outdir]];

start = AbsoluteTime[];
(* Print, not WriteString["stdout"]: inside a KernelPool mission $Output
   is the mission's own log file and a literal "stdout" write would land
   in the pool log instead. *)
log[a___] := Print["[target +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

(* Pool subkernels keep state between missions.  A mission that left an
   OWN VALUE on Global`tau (the "tau = Symbol[\"Global`tau\"]" trap) would
   make every later transport here fail with
   MasterTransport::pathparameter, which is the module refusing correctly
   for a reason that has nothing to do with this run. *)
Quiet[Clear["Global`tau"]];

xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];

normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau", "sqrtLambda", "gli"}, SymbolName[s]] &&
   Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);
normalizeRegulator[expr_] := expr /. s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];

assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
familyBlocks[f_] := Table[{a["Rows"], a["ClassID"]},
  {a, Select[assignments, #["Family"] === f &]}];

chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;

(* the per-block demands measured by the depth agent, when its ledger
   exists in the repository: the engine's order windows come from the
   exact per-block recursion rather than from a global weight *)
ledgerFile = FileNameJoin[{ftData, "TransportDepthLedger.wl"}];
ledger = If[FileExistsQ[ledgerFile], readArtifact[ledgerFile], None];
log["depth ledger: ", If[ledger === None, "absent (module numbers used)", ledgerFile]];

de = readArtifact[FileNameJoin[{ftDE, "nnlo_de_" <> family <> ".wl"}]];
blocks = familyBlocks[family];
log[family, ": ", Length[de["Av"]], " masters, ", Length[blocks], " blocks, orders ", orders];

{seconds, result} = AbsoluteTiming[FeynFacet`TransportFamilyInChart[
   <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
     "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
   chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
   "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
   "PhysicalValuation" -> 0, "Orders" -> orders,
   "Engine" -> "Blockwise", "TransportBackend" -> "Libra",
   "MaxWeight" -> 14, "Verbose" -> True]];

log[family, " status ", Lookup[result, "Status", "?"], " in ",
  Round[seconds, 0.1], " s"];
If[AssociationQ[result], FeynFacet`TransportStatus[result]];

blockwise = Lookup[result, "Blockwise", None];
If[AssociationQ[blockwise],
  log["  recursion certificate all zero: ", blockwise["Certificate"]["AllZero"]];
  log["  Phi cross-check all zero: ", blockwise["Phi"]["AllZero"]];
  log["  max words per block-order: ", blockwise["MaxWordCount"],
    ", max Chen weight ", blockwise["Weight"],
    ", max coefficient leaves ", blockwise["MaxCoefficientLeaves"]];
  log["  timing: ", blockwise["Timing"]];
  log["  peak Wolfram memory: ",
    Round[blockwise["PeakMemory"]/1024.^3, 0.01], " GB"];
  Do[
    log["  words block ", r["Block"], " eps^", r["Order"], ": ", r["Words"],
      " (weight ", r["MaxWeight"], ", ", Round[r["Seconds"], 0.01], " s)"],
    {r, blockwise["WordCounts"]}]];

record = <|
  "Family" -> family, "Orders" -> orders,
  "Status" -> Lookup[result, "Status", "?"],
  "Seconds" -> seconds,
  "Engine" -> Lookup[result, "Engine", "?"],
  "Weight" -> Lookup[result, "Weight", "?"],
  "Certificate" -> Lookup[result, "Certificate", None],
  "Checkable" -> Lookup[result, "Checkable", None],
  "DECheck" -> Table[KeyDrop[r, "Residual"], {r, Lookup[result, "DECheck", {}]}],
  "Valuation" -> Lookup[result, "Valuation", None],
  "Budget" -> Lookup[result, "Budget", None],
  "Shift" -> Lookup[result, "Shift", None],
  "ExactDepth" -> KeyDrop[Lookup[result, "ExactDepth", <||>], {"Table", "Support"}],
  "Blockwise" -> If[AssociationQ[blockwise],
    KeyDrop[blockwise, {"Solution"}], blockwise],
  "PeakMemoryBytes" -> MaxMemoryUsed[],
  "Date" -> DateString[]|>;

FeynFacet`Private`masterTransportPutAtomic[record,
  FileNameJoin[{outdir, "blockwise_" <> family <> ".wl"}]];
log["written ", FileNameJoin[{outdir, "blockwise_" <> family <> ".wl"}]];

(* the full solution is large; it is kept beside the record so a later
   stage (boundary fixing) does not have to re-transport *)
If[AssociationQ[result] && KeyExistsQ[result, "F"],
  FeynFacet`Private`masterTransportPutAtomic[
    <|"Family" -> family, "Orders" -> orders,
      "F" -> result["F"], "I" -> result["I"],
      "Constants" -> result["Constants"],
      "Path" -> result["Path"], "Chart" -> Lookup[result, "ChartNotes", None]|>,
    FileNameJoin[{outdir, "blockwise_solution_" <> family <> ".wl"}]];
  log["solution written (", Round[ByteCount[result["F"]]/1024.^2, 0.1], " MB)"]];
log["DONE"];
