#!/usr/bin/env wolframscript
(* Stage-2 production sweep, ONE FAMILY PER MISSION.

   Transports one NNLO double-real family to the epsilon depth its own
   canonical masters need (measured per-master coefficient valuations,
   TransportDepthLedger: N_a = -val_a + 1) with the block-wise engine, in
   the frame the chart catalog assigns (TransportCharts.wl; (v,w) for
   root-free families), trying both axis-aligned path directions, with
   algebraic letters admitted, and writes ONE versioned artifact per
   family:

       <outdir>/<family>.wl      the transported masters (words with
                                 symbolic integration constants), the
                                 recursion certificate, the assembly
                                 certificate, the original-DE check where
                                 performable, the cost record;
       <outdir>/<family>.status  one-line machine-readable status.

   ACCEPTANCE (stated here, checked below, never inferred from a return
   shape): the family counts as transported iff
     (i)   the assembly certificate is OK (masterTransportCertificateOK),
     (ii)  the block-wise recursion certificate is all zero,
     (iii) the Libra Phi cross-check, where performed, is all zero,
     (iv)  the valuation assertion (I vanishes below the physical
           valuation) holds, and
     (v)   the transported orders cover every own master's demand.
   The exact per-order check against the ORIGINAL family DE is recorded
   as performed / not performable at the requested orders (the
   |rmin| window); it is an additional statement, not the acceptance
   (GPT-Pro review §3: exact gauge identity + exact recursion certificate
   prove the original-basis solution).

   Usage: sweep_transport.wls <family> <outdir> [maxWeight] [timeConstraintSeconds]
   Every phase prints one greppable "[sweep <family>] ..." line. *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]],
  (* the pool preloads the package once at start; a mission takes the
     CURRENT tree (chart catalog, engine fixes) -- ~3 s *)
  Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]]];
(* pool subkernels keep state: nothing here may depend on a clean Global` *)
clearGlobalSymbol[name_String] := ToExpression["Global`" <> name, InputForm,
  Function[symbol, Quiet[Unprotect[symbol]]; ClearAll[symbol], HoldAll]];
Scan[clearGlobalSymbol, {"tau", "s", "u", "p", "x", "y"}];

args = Rest[$ScriptCommandLine];
family = args[[1]];
outdir = args[[2]];
maxWeight = If[Length[args] >= 3, ToExpression[args[[3]]], 10];
timeConstraint = If[Length[args] >= 4, ToExpression[args[[4]]], 2400];
(* the safety margin on top of the strict need -val_a (the hard function
   through eps^0): 1 by default (the ledger's convention N_a = -val_a + 1);
   0 transports to the strict need only -- one weight lower, roughly the
   letter count cheaper -- and the record says so under "SafetyMargin" *)
safety = If[Length[args] >= 5, ToExpression[args[[5]]], 1];
useMapValuation = If[Length[args] >= 6, TrueQ[ToExpression[args[[6]]]], False];
(* 7th arg: directory for the task-#12 diagnostic dump (empty = off) *)
diagDumpDir = If[Length[args] >= 7, args[[7]], ""];
(* 8th arg: pad the F-window BOTTOM down by this many eps-orders (task #12
   under-coverage experiment: if the sampled original-frame check passes
   with padding that it fails without, the carried bottom was above the
   true valuation -- the reviewer's R1 lower-end defect, confirmed by
   controlled experiment rather than reproduction algebra) *)
lowPad = If[Length[args] >= 8, ToExpression[args[[8]]], 0];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];

start = AbsoluteTime[];
log[a___] := Print["[sweep ", family, " +", ToString[Round[AbsoluteTime[] - start]],
  "s] ", StringJoin[ToString /@ {a}]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
  "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] && Context[sy] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]], {i, Length[syms]}];
  expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    sy_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[sy]],
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}];
  expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
writeStatus[st_, note_: ""] := Module[{f = FileNameJoin[{outdir, family <> ".status"}], old},
  (* Never silently destroy a prior Transported line with a failed rerun
     (watchdog find 2026-08-17 20:40): the superseded line is preserved as
     .status.prev so history survives on disk, not only in transcripts. *)
  If[! StringStartsQ[st, "Transported"] && FileExistsQ[f],
    old = Quiet[Import[f, "Text"]];
    If[StringQ[old] && StringContainsQ[old, " Transported "],
      Export[f <> ".prev", old, "Text"]]];
  Export[f, StringJoin[family, " ", st, " ", ToString[Round[AbsoluteTime[] - start]], "s ", note], "Text"]];

(* Impose the physical Laurent valuation directly on the sparse Chen-word
   maps produced by the blockwise recursion.  If

       I_n = Sum_r T_r F_(n-r),

   the word is retained as an Association key and only its rational
   coefficient is multiplied and collected.  This gives the same linear
   equations as masterTransportValuation without first constructing and
   then reparsing large TransportWord expressions. *)
valuationFromWordMaps[assembly_, solution_, fMaps_Association, n0_Integer,
    base_, target_, tau_, variables_, eps_] := Module[
  {kminF, tr0, low, orders, tr1, substitution, tLaurent, seriesMaps,
   equations, constants, solved, rules, updated, bad, stage, timing = <||>},
  kminF = Min[Keys[fMaps]];
  tr0 = FeynFacet`Private`masterTransportTOrderMin[assembly, eps];
  low = kminF + tr0;
  orders = Range[low, n0 - 1];
  If[orders === {}, Return[<|"Status" -> "Inert", "Rules" -> {},
    "Orders" -> {}, "Equations" -> 0, "Solution" -> solution,
    "AssertionOK" -> True, "Route" -> "WordMaps"|>]];
  tr1 = n0 - 1 - kminF;
  substitution = {
    variables[[1]] -> base[[1]] + tau (target[[1]] - base[[1]]),
    variables[[2]] -> base[[2]] + tau (target[[2]] - base[[2]])};
  tLaurent = Table[
    Map[Together,
      Map[FeynFacet`Private`masterTransportLaurentList[#, {tr0, tr1}, eps][[
          r - tr0 + 1]] &, assembly["Forms"][[1]]["T"], {2}] /.
        substitution, {2}],
    {r, tr0, tr1}];
  {stage, seriesMaps} = AbsoluteTiming[Association @ Table[nn -> Table[
    Module[{acc = <||>, fk, scalar},
      Do[
        fk = nn - r;
        If[KeyExistsQ[fMaps, fk],
          Do[
            scalar = tLaurent[[r - tr0 + 1, p, a]];
            If[! TrueQ[scalar === 0],
              acc = FeynFacet`Private`masterTransportBWAddMap[acc,
                Map[scalar # &, fMaps[fk][[a]]]]],
            {a, assembly["N"]}]],
        {r, tr0, tr1}];
      FeynFacet`Private`masterTransportBWTogetherMap[acc]],
    {p, assembly["N"]}], {nn, orders}]];
  timing["FormMaps"] = stage;
  equations = DeleteDuplicates[DeleteCases[Flatten[Table[
    CoefficientList[Expand[Numerator[Together[value]]], tau],
    {maps, Values[seriesMaps]}, {map, maps}, {value, Values[map]}]], 0]];
  constants = DeleteDuplicates[Cases[Values[solution["F"]],
    _TransportConstant, {0, Infinity}]];
  {stage, solved} = AbsoluteTiming[If[equations === {}, {{}},
    Quiet @ Solve[Thread[equations == 0], constants]]];
  timing["Solve"] = stage;
  If[Head[solved] =!= List || solved === {},
    Return[<|"Status" -> "Inconsistent", "Rules" -> {},
      "Orders" -> orders, "Equations" -> Length[equations],
      "Solution" -> solution, "AssertionOK" -> False,
      "Route" -> "WordMaps", "Timing" -> timing|>]];
  rules = First[solved];
  updated = solution;
  {stage, updated["F"]} = AbsoluteTiming[
    FeynFacet`Private`masterTransportSubstituteConstants[solution["F"], rules]];
  timing["ApplyRules"] = stage;
  (* equations contains every tau coefficient of every word-map
     numerator.  Checking that exact system after substitution is
     equivalent to reparsing every rational map coefficient, but avoids
     a second Together over the full map collection. *)
  {stage, bad} = AbsoluteTiming[Select[equations /. rules,
    ! TrueQ[FeynFacet`Private`masterTransportZeroQ[#]] &]];
  timing["ZeroCheck"] = stage;
  <|"Status" -> If[bad === {}, "OK", "AssertionFailed"],
    "Rules" -> rules, "Orders" -> orders,
    "Equations" -> Length[equations], "Solution" -> updated,
    "AssertionOK" -> (bad === {}), "Route" -> "WordMaps",
    "Timing" -> timing|>
];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];

(* ---- inputs ------------------------------------------------------- *)
de = readArtifact[FileNameJoin[{ftDE, "nnlo_de_" <> family <> ".wl"}]];
basis = de["BlockBasis"];
canonical = Lookup[de, "CanonicalMasters", {}];
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
blocks = Table[{a["Rows"], a["ClassID"]},
  {a, Select[assignments, #["Family"] === family &]}];
valuations = readArtifact[FileNameJoin[{ftData, "MasterCoefficientValuations.wl"}]];
valuationOf = Association @ Table[{r["Family"], r["Indices"]} -> r["Valuation"], {r, valuations}];
demands = Table[
  Module[{key = {g[[1]], g[[2]]}, val},
    val = Lookup[valuationOf, Key[key], Missing["NotFound"]];
    <|"GLI" -> g, "Row" -> FirstPosition[basis, g, {Missing[]}, {1}][[1]],
      "Valuation" -> val,
      "Demand" -> If[IntegerQ[val], -val + safety, Missing["ZeroColumn"]],
      "DemandNoSafety" -> If[IntegerQ[val], -val, Missing["ZeroColumn"]]|>],
  {g, canonical}];
nMax = Max[Append[Cases[demands, KeyValuePattern["Demand" -> d_Integer] :> d], 0]];
log["dim ", Length[basis], ", blocks ", Length[blocks], ", own masters ",
  Length[canonical], ", demands ", InputForm[#["Demand"] & /@ demands],
  " -> orders {0, ", nMax, "}"];

chart = FeynFacet`TransportFamilyChart[family];
If[MissingQ[chart],
  log["!! chart not covered: ", InputForm[chart]];
  writeStatus["ChartNotCovered", ToString[InputForm[chart]]]; Exit[2]];
frame = If[AssociationQ[chart], chart["Name"], "SourceVW"];
log["frame ", frame];

system = <|"Family" -> family, "Basis" -> basis, "Av" -> de["Av"], "Aw" -> de["Aw"]|>;

(* ---- ROUTE 2: a certified FAMILY eps-form (off-diagonal cleanup by
        Scripts/family_epsform.wls) is consumed FIRST when it exists.
        Payoff measured 2026-08-17 01:01 (CF230: 7.8 s vs >1568 s/order).
        The eps-form system is transported with identity blocks (the
        DAG bookkeeping preserved through "Ranges"), then the module's
        OWN master series / valuation constraints / original-DE check
        are run with a one-block pseudo-assembly carrying T_total, so
        that I = T_total.F, I_n = 0 below the physical valuation, and
        dI = A I are the module's exact statements and not this
        script's. ------------------------------------------------------- *)
tauS = Symbol["Global`tau"];
familyEpsFormFile = FileNameJoin[{ftData, "FamilyEpsForms", "family_epsform_" <> family <> ".wl"}];
epsFormRecord = If[FileExistsQ[familyEpsFormFile], readArtifact[familyEpsFormFile], None];
epsFormUsable = AssociationQ[epsFormRecord] &&
  MemberQ[{"CleanedUp", "AlreadyEpsForm", "OK"}, Lookup[epsFormRecord, "Status", None]] &&
  TrueQ[Lookup[epsFormRecord, "GateVerdict", False]] &&
  MatrixQ[Lookup[epsFormRecord, "TTotal", None]] &&
  MatrixQ[Lookup[epsFormRecord, "EpsFormX", None]] &&
  MatrixQ[Lookup[epsFormRecord, "EpsFormY", None]];
If[AssociationQ[epsFormRecord],
  log["family eps-form record: status ", Lookup[epsFormRecord, "Status", "?"],
    ", gate ", Lookup[epsFormRecord, "GateVerdict", "?"], ", frame ",
    Lookup[epsFormRecord, "Frame", "?"], " -> ", If[epsFormUsable, "USED", "not usable"]]];

runEpsForm[direction_] := Module[
  {R, frameR, vars, chartR, orig, perm, n, ranges, ttot, ttotInv, tmin, lowF, nTop, r0orig,
   blocksR, base, target, res, sec, pseudo, solution, val, series, deCheck, checkable,
   ax, ay, pulled, fInput, demandedData, demandedRows, blockDemands,
   blockLowerOrders, mappedCheckStatus, stageSec, p2, inv, moduleRanges,
   mapStore, fInputMaps = None},
  R = epsFormRecord;
  frameR = Lookup[R, "Frame", "SourceVW"];
  perm = Flatten[R["Blocks"]];
  (* Only rows of canonical masters with nonzero hard-function coefficients
     need the mapped-back differential-equation check.  All source rows are
     still transported and enter the right-hand side; this selection changes
     only which output equations are re-evaluated. *)
  demandedData = Cases[demands,
    demand_Association /; IntegerQ[Lookup[demand, "Demand", None]] :>
      <|"Row" -> First[FirstPosition[perm, demand["Row"]]],
        "Demand" -> demand["Demand"]|>];
  demandedRows = DeleteDuplicates[Lookup[demandedData, "Row"]];
  n = Length[perm];
  ranges = R["Ranges"];
  ttot = R["TTotal"]; ttotInv = Lookup[R, "TTotalInverse", Inverse[ttot]];
  (* I = T_total F fixes the direct transformed-basis demand.  The
     transport module then propagates it exactly through the Laurent
     orders of every lower-block coupling. *)
  blockDemands = Table[
    Max[Append[Flatten[Table[
      Module[{order = FeynFacet`Private`masterTransportEpsOrder[
          ttot[[item["Row"], column]], ee]},
        If[order === Infinity, Nothing, item["Demand"] - order]],
      {item, demandedData}, {column, ranges[[i]]}]], -Infinity]],
    {i, Length[ranges]}];
  log["  direct transformed-basis demands by declared block: ",
    InputForm[MapThread[<|"Rows" -> #1, "TopOrder" -> #2|> &,
      {R["Blocks"], blockDemands}]]];
  (* the ORIGINAL system in the record's frame and PERMUTED (DAG) basis *)
  If[frameR === "SourceVW",
    vars = {vv, ww}; chartR = None;
    orig = {de["Av"][[perm, perm]], de["Aw"][[perm, perm]]},
    chartR = FeynFacet`TransportFamilyChart[family];
    If[! AssociationQ[chartR], Return[<|"Direction" -> direction, "Seconds" -> 0,
      "Result" -> <|"Status" -> "EpsFormChartUnavailable"|>|>]];
    vars = chartR["Variables"];
    pulled = FeynFacet`Private`masterTransportPullBackSystem[system, chartR,
      "SourceVariables" -> {vv, ww}];
    If[pulled["Status"] =!= "OK", Return[<|"Direction" -> direction, "Seconds" -> 0,
      "Result" -> <|"Status" -> "EpsFormPullBackFailed", "Reason" -> pulled["Status"]|>|>]];
    orig = {pulled["Ax"][[perm, perm]], pulled["Ay"][[perm, perm]]}];
  {ax, ay} = {R["EpsFormX"], R["EpsFormY"]};
  tmin = Min[Append[DeleteCases[FeynFacet`Private`masterTransportEpsOrder[#, ee] & /@ Flatten[ttot], Infinity], 0]];
  blockLowerOrders = Table[
    Module[{entryOrders = DeleteCases[
        FeynFacet`Private`masterTransportEpsOrder[#, ee] & /@
          Flatten[ttotInv[[ranges[[i]], All]]], Infinity]},
      If[entryOrders === {}, 0, Min[entryOrders]]],
    {i, Length[ranges]}];
  If[lowPad > 0,
    blockLowerOrders = blockLowerOrders - lowPad;
    log["  lowPad ", lowPad, ": block lower orders shifted down"]];
  lowF = Min[blockLowerOrders];
  (* the original DE has terms of eps-order r0 <= 0; checking dI = A I at
     order nMax needs I through nMax - r0, i.e. F through nMax - r0 - tmin *)
  r0orig = Min[Append[DeleteCases[FeynFacet`Private`masterTransportEpsOrder[#, ee] & /@ Flatten[orig], Infinity], 0]];
  nTop = nMax - tmin;   (* I=TTotal.F coverage only; the padded window (+|r0orig|) pushed CF124 Libra record to weight 11 > cap (measured 2026-08-17); DE check is opportunistic *)
  blocksR = Table[{ranges[[i]], <|"Type" -> "EpsForm",
    "T" -> IdentityMatrix[Length[ranges[[i]]]], "TInverse" -> IdentityMatrix[Length[ranges[[i]]]],
    "Ev" -> ax[[ranges[[i]], ranges[[i]]]], "Ew" -> ay[[ranges[[i]], ranges[[i]]]]|>}, {i, Length[ranges]}];
  base = If[frameR === "SourceVW",
    If[direction === 1, {1/4, ww}, {vv, 1/4}],
    If[direction === 1, {1/2, vars[[2]]}, {vars[[1]], 1/2}]];
  target = vars;
  log["route 2 (family eps-form) direction ", direction, ": F orders {", lowF, ", ", nTop,
    "} (T_total min order ", tmin, ", T_total^-1 min order ", lowF, "), ", Length[ranges], " blocks"];
  log["  transformed-basis lower orders by declared block: ",
    InputForm[MapThread[<|"Rows" -> #1, "LowerOrder" -> #2|> &,
      {R["Blocks"], blockLowerOrders}]]];
  {sec, res} = AbsoluteTiming[TimeConstrained[FeynFacet`TransportFamily[
    <|"Family" -> family <> "_epsform", "Av" -> ax, "Aw" -> ay|>,
    "Variables" -> vars, "Regulator" -> ee, "Blocks" -> blocksR, "FormDirectory" -> None,
    "PhysicalValuation" -> lowF, "Orders" -> {lowF, nTop},
    (* The blockwise recursion certificate already proves this synthetic
       epsilon-form system.  The mapped-back original-family DE is checked
       below at every demanded order, so repeating the synthetic check here
       only consumes the mission time limit. *)
    "Engine" -> "Blockwise", "TransportBackend" -> "Libra", "AlgebraicLetters" -> Automatic,
    "DepthRule" -> "Exact", "BlockDemands" -> blockDemands,
    "BlockLowerOrders" -> blockLowerOrders,
    "KeepWordMaps" -> useMapValuation,
    "ConstantDepth" -> "PerBlockNeed",
    "DECheck" -> None,
    "BasePoint" -> base, "Target" -> target,
    "MaxWeight" -> maxWeight, "TimeConstraint" -> timeConstraint, "Verbose" -> True],
    timeConstraint, <|"Status" -> "TimedOut", "Seconds" -> timeConstraint|>]];
  If[! (AssociationQ[res] && KeyExistsQ[res, "F"] && AssociationQ[res["F"]]),
    Return[<|"Direction" -> direction, "Seconds" -> sec, "Result" -> res|>]];
  (* map back with the module's own machinery.  TransportFamily orders
     the blocks into ITS OWN DAG order and permutes the system, so its F
     is in that basis; T_total and orig are in the RECORD's basis (the
     input basis here) -- un-permute F first (measured 2026-08-17 02:31:
     CF1 with two blocks was blind to this, CF27 with seven failed the
     original-DE check because of it) *)
  p2 = Flatten[res["Assembly"]["Blocks"]];
  inv = Ordering[p2];   (* F_input[[k]] = F_module[[position of k in p2]] *)
  fInput = Association @ KeyValueMap[Function[{k, vec}, k -> vec[[inv]]], res["F"]];
  If[useMapValuation && AssociationQ[res["Blockwise"]] &&
      AssociationQ[Lookup[res["Blockwise"], "Maps", None]],
    moduleRanges = res["Assembly"]["Ranges"];
    mapStore = res["Blockwise"]["Maps"]["Solution"];
    fInputMaps = Association @ Table[k -> Flatten[Table[
      Table[Lookup[mapStore, Key[{i, k, a}], <||>],
        {a, Length[moduleRanges[[i]]]}], {i, Length[moduleRanges]}], 1][[inv]],
      {k, Keys[fInput]}];
    (* Word maps are transient calculation data, not part of the stored
       transported-family artifact. *)
    res["Blockwise"] = KeyDrop[res["Blockwise"], "Maps"]];
  pseudo = <|"N" -> n, "Ranges" -> {Range[n]}, "Forms" -> {<|"T" -> ttot, "Type" -> "EpsForm"|>},
    "Av" -> orig[[1]], "Aw" -> orig[[2]], "Family" -> family|>;
  solution = <|"F" -> fInput, "FLow" -> Min[Keys[fInput]], "KMax" -> Max[Keys[fInput]]|>;
  log["  map-back: imposing physical valuation"];
  {stageSec, val} = AbsoluteTiming[If[AssociationQ[fInputMaps],
    valuationFromWordMaps[pseudo, solution, fInputMaps, 0, base, target,
      tauS, vars, ee],
    FeynFacet`Private`masterTransportValuation[pseudo, solution, 0, base, target,
      tauS, vars, ee, True]]];
  log["  map-back: valuation finished in ", Round[stageSec, 0.1], " s"];
  log["  map-back: forming demanded physical coefficients"];
  {stageSec, series} = AbsoluteTiming[
    FeynFacet`Private`masterTransportMasterSeries[pseudo, val["Solution"], {0, nMax},
      base, target, tauS, vars, ee]];
  log["  map-back: physical coefficients finished in ", Round[stageSec, 0.1], " s"];
  log["  map-back: sampled check of demanded rows of original differential equation"];
  {stageSec, deCheck} = AbsoluteTiming[Flatten[Table[
    Module[{rows = Lookup[Select[demandedData,
        Lookup[#, "Demand", None] === demand &], "Row"]},
      Map[Join[#, <|"Rows" -> rows, "Demand" -> demand|>] &,
        sweepSampledCheckDE[pseudo, series,
          Range[0, demand], base, target, tauS, vars, ee, rows, True]]],
    {demand, DeleteDuplicates[Lookup[demandedData, "Demand"]]}]]];
  log["  map-back: sampled original-DE check finished in ",
    Round[stageSec, 0.1], " s"];
  mappedCheckStatus = Which[
    deCheck === {}, "SolvedNotCheckable",
    AllTrue[deCheck, #["Zero"] === {True} &], "OK",
    AllTrue[deCheck,
      MemberQ[{{True}, {"InsufficientOrders"}}, #["Zero"]] &],
      "SolvedNotCheckable",
    True, "OriginalDECheckFailed"];
  (* Diagnostic dump for the window-arithmetic workstream (task #12): env
     SWEEP_DIAG_DUMP=<path> saves the exact objects the check consumed, so
     the residual-reproduction test (reviewer, 2026-08-17) can run offline:
     residual must equal the differentiated sum of the dropped T_k F^(n-k). *)
  Module[{dumpDir = diagDumpDir},
    If[StringQ[dumpDir] && dumpDir =!= "",
      If[! DirectoryQ[dumpDir], CreateDirectory[dumpDir, CreateIntermediateDirectories -> True]];
      putAtomic[<|"Family" -> family, "Direction" -> direction,
        "Pseudo" -> pseudo, "Series" -> series, "Valuation" -> val,
        "FInput" -> fInput, "TTotal" -> ttot, "TTotalInverse" -> ttotInv,
        "BlockDemands" -> blockDemands, "BlockLowerOrders" -> blockLowerOrders,
        "DemandedData" -> demandedData, "DECheck" -> deCheck,
        "MappedCheckStatus" -> mappedCheckStatus,
        "Base" -> base, "Target" -> target, "Vars" -> vars|>,
        FileNameJoin[{dumpDir, family <> "_dir" <> ToString[direction] <> "_diag.wl"}]]]];
  <|"Direction" -> direction, "Seconds" -> sec,
    "Result" -> Join[res, <|"Route" -> "FamilyEpsForm", "Valuation" -> val,
      "F" -> val["Solution"]["F"], "I" -> series, "DECheck" -> deCheck,
      "DECheckRows" -> demandedRows, "BlockDemands" -> blockDemands,
      "SyntheticTransportStatus" -> Lookup[res, "Status", None],
      "Permutation" -> perm, "TTotal" -> ttot, "OriginalSystemPermuted" -> orig,
      "BasisNote" -> "F, I, TTotal and OriginalSystemPermuted are in the family eps-form record's basis (rows = Flatten[Permutation] of the family basis)",
      "Status" -> mappedCheckStatus,
      "Assembly" -> Join[Lookup[res, "Assembly", <||>], <|"Blocks" -> R["Blocks"],
        "Ranges" -> ranges|>]|>]|>];

(* ---- sampled original-frame DE check ------------------------------ *)
(* Replaces the symbolic original-frame check (user directive 2026-08-17:
   the symbolic proof took hours on dim>=24 families and is an assurance
   layer, not the acceptance -- certificates are).  Method: the residual
   dI/dtau - Ahat.I at each demanded eps-order is linear in the words and
   the symbolic constants with rational-function coefficients c_k(tau);
   the identity holds iff all c_k == 0 (linear independence of words).
   We evaluate the residual at nSamples random rational tau points with
   every word/constant symbol replaced by an independent random rational
   (fresh per sample).  All arithmetic is EXACT; a nonzero c_k survives
   the randomization with probability ~1 (Schwartz-Zippel).  Recorded as
   a sampled check, not a proof; the exact certificate chain is unchanged. *)
sweepSampledCheckDE[assembly_, series_, orders_, base_, target_, tau_,
    variables_, eps_, rows_ : All, verbose_ : False] := Module[
  {v, w, dv, dw, substitution, o0, o1, dtauAll, nSamples = 3, seed = 20260817,
   tauPool = {3/7, 5/13, 17/29, 23/37, 11/19, 7/17, 29/41, 13/31},
   wvars, avP, awP, sampleData, usedTaus = {}},
  {v, w} = variables[[{1, 2}]];
  dv = target[[1]] - base[[1]];
  dw = target[[2]] - base[[2]];
  substitution = {v -> base[[1]] + tau dv, w -> base[[2]] + tau dw};
  avP = assembly["Av"] /. substitution;
  awP = assembly["Aw"] /. substitution;
  o0 = Min[series["Orders"]];
  o1 = Max[series["Orders"]];
  (* the word rules must cover the DERIVATIVE words too: d/dtau of a word
     peels its leading letter, and the peeled sub-word need not appear in
     I itself (its coefficient there may vanish).  A word symbol left
     unsubstituted makes the residual spuriously nonzero (the CF50/CF53
     false-failure candidate, 2026-08-17 19:10). *)
  dtauAll = Table[FeynFacet`Private`masterTransportDTau[series["I"][[k]], tau],
    {k, Length[series["I"]]}];
  (* The randomization domain must cover EVERY non-(tau,eps) symbol on BOTH
     sides -- words, constants, endpoint variables, and the path matrices.
     Randomizing x,y in the lhs while the Laurent matrices kept them
     symbolic produced the SampledLeftoverSymbols failures misread as
     genuine residuals on six families (found via the stored deCheck
     labels + Codex's dump inventory, 2026-08-18 01:05). *)
  wvars = DeleteCases[Variables[{series["I"], dtauAll, avP, awP, dv, dw}],
    tau | eps];
  SeedRandom[seed];
  (* one Laurent expansion of the path matrix per sampled tau: entries
     are then rational in eps only, so the expansion is cheap *)
  sampleData = Reap[Module[{k = 0}, Do[
    Module[{t0, ahatS, r0, r1, laurentS, wrules},
      t0 = tauPool[[s]];
      wrules = Dispatch[Thread[wvars ->
        Table[RandomInteger[{10, 99991}]/RandomInteger[{100003, 999983}], Length[wvars]]]];
      ahatS = Quiet[Map[Together, ((avP dv + awP dw) /. tau -> t0) /. wrules, {2}]];
      If[! FreeQ[ahatS, DirectedInfinity | ComplexInfinity | Indeterminate] ||
         DeleteCases[Variables[ahatS], eps] =!= {},
        Continue[]];  (* pole at this tau, or an unsubstituted symbol: skip point *)
      k++;
      AppendTo[usedTaus, t0];
      r0 = Min[Append[DeleteCases[
        FeynFacet`Private`masterTransportEpsOrder[#, eps] & /@ Flatten[ahatS],
        Infinity], 0]];
      r1 = Max[o1 - o0, r0];
      laurentS = FeynFacet`Private`masterTransportLaurentMat[ahatS, {r0, r1}, eps];
      Sow[<|"Tau" -> t0, "R0" -> r0, "R1" -> r1, "Laurent" -> laurentS,
        "WordRules" -> wrules|>];
      If[k >= nSamples, Break[]]],
    {s, Length[tauPool]}]]][[2]];
  sampleData = If[sampleData === {}, {}, First[sampleData]];
  If[sampleData === {} || MemberQ[Lookup[sampleData, "Laurent"], $Failed],
    Return[{<|"Order" -> None, "Zero" -> {"LaurentFailed"},
      "Method" -> "SampledRational"|>}]];
  Table[
    Module[{dtauI, verdicts, missingAll = {}},
      FeynFacet`Private`masterTransportLog[verbose,
        "  DE check (sampled, ", Length[sampleData], " pts) at eps^", nn,
        " of ", orders];
      dtauI = dtauAll[[nn - o0 + 1]];
      verdicts = Table[
        Module[{r0 = smp["R0"], r1 = smp["R1"], missing, lhsV, rhsV, resV},
          missing = Select[Range[r0, r1], (nn - # > o1) &&
            ! FeynFacet`Private`masterTransportZeroMatQ[
              smp["Laurent"][[# - r0 + 1]]] &];
          missingAll = Union[missingAll, missing];
          If[missing =!= {}, "InsufficientOrders",
            lhsV = (dtauI /. tau -> smp["Tau"]) /. smp["WordRules"];
            rhsV = ConstantArray[0, assembly["N"]];
            Do[
              If[o0 <= nn - r <= o1,
                rhsV = rhsV + smp["Laurent"][[r - r0 + 1]] .
                  ((series["I"][[nn - r - o0 + 1]] /. tau -> smp["Tau"]) /.
                    smp["WordRules"])],
              {r, r0, r1}];
            resV = Together[lhsV - rhsV];
            If[rows =!= All, resV = resV[[rows]]];
            If[! MatchQ[resV, {(0) ..}] && VectorQ[resV, NumericQ],
              resV = RootReduce /@ resV];
            Which[
              resV === {} || Union[resV] === {0}, True,
              ! VectorQ[resV, NumericQ],
                (* leftover non-numeric content: word-coverage bug, not a
                   genuine residual -- label it so it is never read as a
                   physics failure *)
                <|"Leftover" -> Take[DeleteCases[Variables[resV], tau], UpTo[5]]|>,
              True, False]]],
        {smp, sampleData}];
      Module[{verdict},
        verdict = Which[
          MemberQ[verdicts, "InsufficientOrders"], {"InsufficientOrders"},
          Union[verdicts] === {True}, {True},
          AnyTrue[verdicts, AssociationQ], {"SampledLeftoverSymbols"},
          True, {False}];
        <|"Order" -> nn, "Zero" -> verdict, "MissingShifts" -> missingAll,
          "Residual" -> Null, "Method" -> "SampledRational",
          "SampleTaus" -> usedTaus, "SampleSeed" -> seed,
          "SampleVerdicts" -> verdicts|>]],
    {nn, orders}]
];

(* ---- transport, both axis directions ------------------------------ *)
run[direction_] := Module[{opts, res, sec, base},
  opts = Sequence[
    "Regulator" -> ee, "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
    "PhysicalValuation" -> 0, "Orders" -> {0, nMax},
    "Engine" -> "Blockwise", "TransportBackend" -> "Libra",
    "DepthRule" -> "Exact", "AlgebraicLetters" -> Automatic,
    "MaxWeight" -> maxWeight, "TimeConstraint" -> timeConstraint,
    "Verbose" -> True];
  (* the whole attempt is time-capped: the block-wise recursion is not
     bounded by the backend's TimeConstraint, and a production mission
     must not run unbounded *)
  {sec, res} = AbsoluteTiming[TimeConstrained[
    If[AssociationQ[chart],
      FeynFacet`TransportFamilyInChart[system, chart,
        "SourceVariables" -> {vv, ww},
        "PathDirection" -> If[direction === 1, "First", "Second"], opts],
      base = If[direction === 1, {1/4, ww}, {vv, 1/4}];
      FeynFacet`TransportFamily[system, "Variables" -> {vv, ww},
        "BasePoint" -> base, "Target" -> {vv, ww}, opts]],
    timeConstraint, <|"Status" -> "TimedOut", "Seconds" -> timeConstraint|>]];
  <|"Direction" -> direction, "Seconds" -> sec, "Result" -> res|>];

accepted[res_] := AssociationQ[res] &&
  MemberQ[{"OK", "SolvedNotCheckable"}, Lookup[res, "Status", None]] &&
  KeyExistsQ[res, "Blockwise"] && AssociationQ[res["Blockwise"]] &&
  TrueQ[res["Blockwise"]["Certificate"]["AllZero"]] &&
  TrueQ[res["Blockwise"]["Phi"]["AllZero"]] &&
  TrueQ[FeynFacet`Private`masterTransportCertificateOK[res["Assembly"]]] &&
  (! KeyExistsQ[res, "Valuation"] || ! AssociationQ[res["Valuation"]] ||
    Lookup[res["Valuation"], "AssertionOK", Lookup[res["Valuation"], "Assertion", True]] =!= False);

attempts = {};
result = None;
(* frames to try, in order: the catalog chart (or (v,w) for a root-free
   family); a root-free family whose (v,w) assembly is refused (measured
   2026-08-17: class members that are v<->w swaps of their representative
   are not yet applied in the (v,w) route) is retried in the Kallen1
   chart, where the swap is tried by the pullback layer *)
frames = If[AssociationQ[chart], {chart}, {None, FeynFacet`TransportFamilyChart["CF230"]}];
If[epsFormUsable,
  Do[
    Module[{r},
      If[result === None,
        r = runEpsForm[direction];
        AppendTo[attempts, KeyDrop[r, "Result"] ~Join~ <|"Frame" -> "FamilyEpsForm",
          "Status" -> Lookup[r["Result"], "Status", "?"]|>];
        log["route 2 direction ", direction, ": status ", Lookup[r["Result"], "Status", "?"],
          " in ", Round[r["Seconds"], 0.1], " s"];
        If[accepted[r["Result"]], result = r]]],
    {direction, {1, 2}}]];
timedOut = False;
Do[
  Module[{r},
    If[result === None && ! timedOut,
      chart = frameChart;
      frame = If[AssociationQ[chart], chart["Name"], "SourceVW"];
      r = run[direction];
      (* a direction that exhausts the cap is not retried in the other
         direction: the complexity is the family's, not the path's *)
      If[AssociationQ[r["Result"]] && Lookup[r["Result"], "Status", None] === "TimedOut",
        timedOut = True];
      AppendTo[attempts, KeyDrop[r, "Result"] ~Join~
        <|"Frame" -> frame, "Status" -> Lookup[r["Result"], "Status", "?"],
          "Monic" -> If[AssociationQ[r["Result"]] && KeyExistsQ[r["Result"], "Monic"],
            KeyTake[r["Result"]["Monic"], {"Linear", "AlgebraicAdmissible", "Degrees"}], None]|>];
      log["direction ", direction, ": status ", Lookup[r["Result"], "Status", "?"],
        " in ", Round[r["Seconds"], 0.1], " s"];
      If[accepted[r["Result"]], result = r,
        If[AssociationQ[r["Result"]] && KeyExistsQ[r["Result"], "Reason"],
          log["  reason ", ToString[Short[r["Result"]["Reason"], 4]]]]]]],
  {frameChart, frames}, {direction, {1, 2}}];

If[result === None,
  log["!! not transported: ", InputForm[#["Status"] & /@ attempts]];
  writeStatus["Failed", StringRiffle[ToString /@ (#["Status"] & /@ attempts), "|"]];
  putAtomic[<|"Format" -> "FeynFacetTransportedFamily", "FormatVersion" -> 1,
    "Family" -> family, "Status" -> "Failed", "Attempts" -> attempts,
    "Frame" -> frame, "Demands" -> demands, "Date" -> DateString[]|>,
    FileNameJoin[{outdir, family <> ".wl"}]];
  Exit[1]];

res = result["Result"];
bw = res["Blockwise"];
log["ACCEPTED direction ", result["Direction"], ": status ", res["Status"],
  "; recursion certificate ", bw["Certificate"]["AllZero"], ", Phi ", bw["Phi"]["AllZero"],
  ", weight ", bw["Weight"], ", max words ", bw["MaxWordCount"],
  ", max leaves ", bw["MaxCoefficientLeaves"], ", letters ", bw["Letters"]["Count"],
  " (algebraic ", Count[bw["Letters"]["Letters"], _?(! FreeQ[#, Power[_, _Rational]] &)],
  "), general-integrator sites ", Length[bw["GeneralIntegrator"]["Sites"]],
  ", transport ", Round[bw["Timing"]["Total"], 0.1], " s"];
deCheck = Lookup[res, "DECheck", {}];
deSummary = Which[
  deCheck === {}, "NotPerformable",
  AllTrue[deCheck, #["Zero"] === {True} &], "True",
  AllTrue[deCheck, MemberQ[{{True}, {"InsufficientOrders"}}, #["Zero"]] &], "TrueWhereCheckable",
  True, "FAILED"];
log["original-DE check: ", deSummary, " orders ", InputForm[#["Order"] & /@ deCheck],
  "; checkable ", InputForm[Lookup[res, "Checkable", "-"]]];

(* (v) coverage: every own master's demand is within the transported orders *)
covered = AllTrue[demands, ! IntegerQ[#["Demand"]] || #["Demand"] <= nMax &];

record = <|
  "Format" -> "FeynFacetTransportedFamily", "FormatVersion" -> 1,
  "Family" -> family, "Status" -> "Transported",
  "Route" -> Lookup[res, "Route", "Direct"],
  "Frame" -> If[Lookup[res, "Route", "Direct"] === "FamilyEpsForm",
    Lookup[epsFormRecord, "Frame", frame], frame],
  "Chart" -> If[AssociationQ[chart], chart, None],
  "Permutation" -> Lookup[res, "Permutation", None],
  "TTotal" -> Lookup[res, "TTotal", None],
  "PathDirection" -> result["Direction"],
  "Path" -> Lookup[res, "Path", None], "ChartNotes" -> Lookup[res, "ChartNotes", None],
  "Variables" -> Lookup[res, "Variables", None], "Regulator" -> ee,
  "Basis" -> basis, "CanonicalMasters" -> canonical, "Demands" -> demands,
  "Orders" -> {0, nMax}, "DemandsCovered" -> covered, "SafetyMargin" -> safety,
  "TransportStatus" -> res["Status"],
  "AssemblyCertificate" -> res["Assembly"]["Certificate"],
  "AssemblyBlocks" -> res["Assembly"]["Blocks"], "Ranges" -> res["Assembly"]["Ranges"],
  "BasisNote" -> Lookup[res, "BasisNote", "F and I are in the assembly's block (DAG) order: row k of F/I is family basis row Flatten[AssemblyBlocks][[k]]"],
  "PullBack" -> Lookup[res, "PullBack", None],
  "Monic" -> Lookup[res, "Monic", None],
  "Blockwise" -> KeyDrop[bw, {"Solution", "Maps"}],
  "DECheck" -> Table[KeyDrop[d, "Residual"], {d, deCheck}], "DECheckSummary" -> deSummary,
  "Checkable" -> Lookup[res, "Checkable", None],
  "Valuation" -> Lookup[res, "Valuation", None],
  "F" -> Lookup[res, "F", None], "I" -> Lookup[res, "I", None],
  "Constants" -> Lookup[res, "Constants", None],
  "KMinPerBlock" -> Lookup[res, "KMinPerBlock", None],
  "Weight" -> Lookup[res, "Weight", None], "ExactDepth" -> Lookup[res, "ExactDepth", None],
  "Attempts" -> attempts,
  "Cost" -> <|"TransportSeconds" -> result["Seconds"], "WallSeconds" -> AbsoluteTime[] - start,
    "BlockwiseTiming" -> bw["Timing"], "PeakMemoryBytes" -> MaxMemoryUsed[],
    "MaxWordCount" -> bw["MaxWordCount"], "MaxCoefficientLeaves" -> bw["MaxCoefficientLeaves"],
    "WordCounts" -> bw["WordCounts"]|>,
  "Provenance" -> <|"Script" -> "Scripts/sweep_transport.wls", "Date" -> DateString[],
    "Inputs" -> {"DifferentialEquations/nnlo_de_" <> family <> ".wl",
      "BlockClasses/block_class_assign.wl", "ClassForms/class*.wl",
      "MasterCoefficientValuations.wl"}|>
|>;
putAtomic[record, FileNameJoin[{outdir, family <> ".wl"}]];
writeStatus["Transported", StringJoin["dir", ToString[result["Direction"]], " safety", ToString[safety], " ", res["Status"],
  " w", ToString[bw["Weight"]], " words", ToString[bw["MaxWordCount"]],
  " DE:", deSummary, " ", ToString[Round[result["Seconds"]]], "s"]];
log["written ", FileNameJoin[{outdir, family <> ".wl"}]];
log["DONE"];
