#!/usr/bin/env wolframscript
(* Per-master demand ledger and per-block transport depth, for the NNLO
   double-real families.  NOTHING is transported here: every family is
   entered with "MaxWeight" -> 0, which returns the assembly and the
   depth arithmetic and stops.

   What it computes, per family:

     1. the demand of every canonical master the family OWNS, from the
        MEASURED eps-Laurent valuation of that master's coefficient
        column in the hard function
        (Results/UU_08_10_canonical/MasterCoefficientValuations.wl):

            N_a = 0 - valuation_a + 1

        i.e. "the hard function is wanted through eps^0, and one extra
        order of safety".  The number without the +1 is tabulated beside
        it so the safety margin is visible and can be removed.

     2. the per-block demanded canonical order by GPT-Pro's Eq. (11),

            N_i = max over masters a in block i and over eps-orders t
                  with T_ai^[t] != 0  of  (N_a - t),

        evaluated on the family's ASSEMBLED T (the block-diagonal
        transformation the transport actually uses -- in the chart for
        the two chart families).  A block that owns no canonical master
        gets NO direct demand: its demand comes only from the couplings,
        by the back-propagation inside the depth arithmetic.  This is the
        substantive convention of the ledger and it is stated in the
        artifact: a subsector row of family F is an integral that is a
        canonical master of some OTHER family G, is solved there, and is
        needed inside F only as a source for F's own masters.

     3. the transport weight under both rules: the module's clamped
        jmax + D, and the exact per-block recursion max_i W_i(N_i)
        (masterTransportExactDepth), each with the module's default
        demands and with the Eq. (11) demands.

     4. the FULL Laurent support of every coupling block, and which
        edges are deficit (order <= 0), slack (order >= 2) or MIXED --
        mixed edges are exactly where the two rules can differ.

   Usage:  transport_depth_ledger.wls <outdir> <CF258,CF230,...>
   Writes <outdir>/<family>.wl per family, atomically, and prints one
   progress line per family. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

args = Rest[$ScriptCommandLine];
outdir = args[[1]];
familyList = StringSplit[args[[2]], ","];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
ee = Symbol["Global`eps"]; tauS = Symbol["Global`tau"];

(* The rule list is built EXPLICITLY.  The inline
     expr /. (s_Symbol /; ... :> Symbol["Global`" <> SymbolName[s]])
   spelling was MEASURED (Tests/Infrastructure/t_wolfram_traps.wls, item T2) to insert
   its right-hand side UNEVALUATED on artifacts of this size once a
   package is on $ContextPath, which makes the normalization a silent
   no-op.  Do not "simplify" this back. *)
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x",
  "y", "u", "t", "tau", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    s_Symbol /; MemberQ[$normalizeNames, SymbolName[s]] && Context[s] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}];
  expr /. rules];
normalizeRegulator[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    s_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]],
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> ee, {i, Length[syms]}];
  expr /. rules];
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];

putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

log[a___] := Print["[ledger] ", StringJoin[ToString /@ {a}]];

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];
ftHard = FileNameJoin[{ftData, "HardClasses", "EpsFormRoute"}];

valuations = readArtifact[FileNameJoin[{ftData, "MasterCoefficientValuations.wl"}]];
valuationOf = Association @ Table[
  {r["Family"], r["Indices"]} -> r["Valuation"], {r, valuations}];
routeOf = Association @ Table[
  {r["Family"], r["Indices"]} -> r["Route"], {r, valuations}];
log["valuations: ", Length[valuations], " masters, ",
  Count[Values[valuationOf], _Integer], " with an integer valuation"];

assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];

chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;
classFormFile[cid_] := FileNameJoin[{ftClassForms, "class" <> ToString[cid] <> ".wl"}];
hardArtifact[cid_] := FileNameJoin[{ftHard,
  "c" <> ToString[cid] <> "_epsform_two_variable.wl"}];
hardRecord[cid_, repFamily_, repRows_] := Module[{raw},
  If[FileExistsQ[classFormFile[cid]], Return[readArtifact[classFormFile[cid]]]];
  raw = readArtifact[hardArtifact[cid]];
  <|"ClassID" -> cid, "RepFamily" -> repFamily, "RepRows" -> repRows,
    "Dim" -> Length[raw["T"]], "Transformation" -> raw["T"],
    "EpsForm" -> {raw["Ax"], raw["Ay"]}, "Variables" -> {xx, yy},
    "Chart" -> <|"Kind" -> "TwoVariable",
      "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
      "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww,
      "Variables" -> {xx, yy}|>,
    "AnsatzDegree" -> None, "Validated" -> True|>];

(* the two families whose hard block only has an eps-form in the chart *)
chartFamilies = <|"CF258" -> 97, "CF230" -> 77|>;
chartRecord = <||>;

(* All 173 class forms are stored, including 77/97/79, so a block is
   always addressed by its ClassID; the hardRecord fallback above stays
   for a tree in which a hard class has not been promoted yet. *)
familyBlocks[family_] := Module[{rows},
  rows = Select[assignments, #["Family"] === family &];
  Table[{a["Rows"],
    If[FileExistsQ[classFormFile[a["ClassID"]]], a["ClassID"],
      hardRecord[a["ClassID"], family, a["Rows"]]]}, {a, rows}]];

epsOrder = FeynFacet`Private`masterTransportEpsOrder;
exactDepth = FeynFacet`Private`masterTransportExactDepth;
pathMatrix = FeynFacet`Private`masterTransportPathMatrix;

(* ---------------------------------------------------------------- one family *)

ledgerFor[family_String] := Module[
  {de, blocks, chartQ, record, assembly, ahat, nb, ranges, kmin, demandRow,
   ownMasters, basis, canonical, rowDemand, rowDemandNoSafety,
   blockDemand, blockDemandNoSafety, exactModule, exactEq11, exactEq11NoSafety,
   variables, base, target, forms, t, seconds, status, notes},
  de = readArtifact[FileNameJoin[{ftDE, "nnlo_de_" <> family <> ".wl"}]];
  basis = de["BlockBasis"];
  canonical = Lookup[de, "CanonicalMasters", {}];
  blocks = familyBlocks[family];
  chartQ = KeyExistsQ[chartFamilies, family];
  variables = If[chartQ, {xx, yy}, {vv, ww}];
  base = If[chartQ, {1/2, yy}, {1/4, 1/4}];
  target = variables;

  (* (1) per-master demands.  A row that is one of the family's OWN
     canonical masters carries the hard-function demand; every other row
     carries none (it is a master of another family, solved there). *)
  rowDemand = Table[
    Module[{g = basis[[r]], key, val},
      key = {g[[1]], g[[2]]};
      If[! MemberQ[canonical, g] || ! KeyExistsQ[valuationOf, key], -Infinity,
        val = valuationOf[key];
        If[IntegerQ[val], -val + 1, -Infinity]]],
    {r, Length[basis]}];
  rowDemandNoSafety = Table[
    Module[{g = basis[[r]], key, val},
      key = {g[[1]], g[[2]]};
      If[! MemberQ[canonical, g] || ! KeyExistsQ[valuationOf, key], -Infinity,
        val = valuationOf[key];
        If[IntegerQ[val], -val, -Infinity]]],
    {r, Length[basis]}];
  ownMasters = Table[
    Module[{g = canonical[[k]], key = {canonical[[k]][[1]], canonical[[k]][[2]]}},
      <|"GLI" -> g, "Valuation" -> Lookup[valuationOf, Key[key], Missing["NotFound"]],
        "Route" -> Lookup[routeOf, Key[key], Missing["NotFound"]],
        "Demand" -> Module[{v = Lookup[valuationOf, Key[key], Missing["NotFound"]]},
          If[IntegerQ[v], -v + 1, Missing["ZeroColumn"]]],
        "DemandNoSafety" -> Module[{v = Lookup[valuationOf, Key[key], Missing["NotFound"]]},
          If[IntegerQ[v], -v, Missing["ZeroColumn"]]],
        "Row" -> FirstPosition[basis, g, {Missing["NotInBasis"]}, {1}]|>],
    {k, Length[canonical]}];

  (* (2) the assembly, WITHOUT transporting.

     A family whose blocks are all (v,w) eps-forms assembles in (v,w).
     Many do NOT: a class whose certified form lives in a conic or
     two-variable chart is refused by the plain entry point BY NAME
     (ClassFormNotEpsForm / ClassFormTwoVariableChartNeedsChartTransport),
     which is the correct behaviour -- using such a form in the (v,w)
     frame would differentiate it with respect to symbols it does not
     contain.  Those families are retried through the CHART route, which
     is the same route the two hard families take. *)
  {seconds, record} = AbsoluteTiming[
    If[chartQ,
      FeynFacet`TransportFamilyInChart[
        <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
          "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
        chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
        "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
        "PhysicalValuation" -> 0, "Orders" -> {0, 1},
        "TransportBackend" -> "Libra", "MaxWeight" -> 0, "DepthReport" -> True,
        "Verbose" -> False],
      FeynFacet`TransportFamily[
        <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
          "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
        "Variables" -> {vv, ww}, "Regulator" -> ee,
        "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
        "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> 0, "Orders" -> {0, 1},
        "TransportBackend" -> "Libra", "MaxWeight" -> 0, "DepthReport" -> True,
        "Verbose" -> False]]];
  status = If[AssociationQ[record], Lookup[record, "Status", "?"], ToString[record]];
  If[! chartQ && ! (AssociationQ[record] && KeyExistsQ[record, "Assembly"] &&
        AssociationQ[record["Assembly"]] && KeyExistsQ[record["Assembly"], "Ranges"]),
    log["  ", family, ": (v,w) assembly ", status, " (",
      ToString[Short[Lookup[record, "Reason", "-"], 3]], ") -- retrying in the chart"];
    chartQ = True;
    variables = {xx, yy}; base = {1/2, yy}; target = variables;
    {seconds, record} = AbsoluteTiming[
      FeynFacet`TransportFamilyInChart[
        <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None],
          "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
        chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
        "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
        "PhysicalValuation" -> 0, "Orders" -> {0, 1},
        "TransportBackend" -> "Libra", "MaxWeight" -> 0, "DepthReport" -> True,
        "Verbose" -> False]];
    status = If[AssociationQ[record], Lookup[record, "Status", "?"], ToString[record]]];
  If[! (AssociationQ[record] && KeyExistsQ[record, "Assembly"] &&
        AssociationQ[record["Assembly"]] && KeyExistsQ[record["Assembly"], "Ranges"]),
    Return[<|"Family" -> family, "Status" -> status, "Seconds" -> seconds,
      "Frame" -> If[chartQ, "Chart", "SourceVW"],
      "Reason" -> Lookup[record, "Reason", Missing["-"]],
      "Masters" -> ownMasters, "Note" -> "no assembly returned"|>]];

  assembly = record["Assembly"];
  nb = Length[assembly["Blocks"]];
  ranges = assembly["Ranges"];
  kmin = Lookup[record, "KMinPerBlock", Automatic];
  ahat = pathMatrix[assembly["Apv"], assembly["Apw"], target, base, tauS, variables];

  (* (3) Eq. (11): push the per-master demands through the assembled T *)
  forms = assembly["Forms"];
  blockDemand = Table[
    Module[{rows = assembly["Blocks"][[i]], tt = forms[[i]]["T"], best},
      best = -Infinity;
      Do[
        If[rowDemand[[rows[[p]]]] =!= -Infinity,
          Do[
            Module[{o = epsOrder[tt[[p, c]], ee]},
              If[o =!= Infinity, best = Max[best, rowDemand[[rows[[p]]]] - o]]],
            {c, Length[tt]}]],
        {p, Length[rows]}];
      best],
    {i, nb}];
  blockDemandNoSafety = Table[
    Module[{rows = assembly["Blocks"][[i]], tt = forms[[i]]["T"], best},
      best = -Infinity;
      Do[
        If[rowDemandNoSafety[[rows[[p]]]] =!= -Infinity,
          Do[
            Module[{o = epsOrder[tt[[p, c]], ee]},
              If[o =!= Infinity, best = Max[best, rowDemandNoSafety[[rows[[p]]]] - o]]],
            {c, Length[tt]}]],
        {p, Length[rows]}];
      best],
    {i, nb}];

  (* The module already ran the exact recursion with its own demands
     inside TransportFamily; only the Eq. (11) demands need a second
     pass.  The no-safety variant is tabulated as demands only -- its
     recursion would be a third full pass over every coupling's Laurent
     support for a number that differs from the Eq. (11) one by a
     constant shift of the demands. *)
  exactModule = Lookup[record, "ExactDepth", Missing["NotComputed"]];
  exactEq11 = exactDepth[assembly, ahat,
    <|"Demands" -> blockDemand, "KMin" -> kmin|>, ee];
  exactEq11NoSafety = Missing["NotComputed: demands tabulated only"];

  notes = <|
    "Frame" -> If[chartQ, "chart v = x y, w = (1-x)(1-y)", "(v,w)"],
    "Path" -> <|"Base" -> base, "Target" -> target|>,
    "DemandConvention" ->
      "N_a = 0 - valuation_a + 1 (hard function through eps^0, one extra order of safety); \
DemandNoSafety drops the +1",
    "SubsectorConvention" ->
      "a family row that is not one of the family's OWN canonical masters carries NO direct \
demand: it is a canonical master of another family, solved there, and is needed inside this \
family only as a source for this family's masters"|>;

  <|"Family" -> family, "Status" -> status, "Seconds" -> seconds,
    "Frame" -> If[chartQ, "Chart", "SourceVW"],
    "Masters" -> ownMasters,
    "Dim" -> assembly["N"],
    "Blocks" -> assembly["Blocks"],
    "BlockClasses" -> blocks[[All, 2]] /. r_Association :> Lookup[r, "ClassID", "record"],
    "BlockDims" -> Length /@ ranges,
    "KMinPerBlock" -> kmin,
    "TInverseOrder" -> Lookup[record, "TInverseOrder", Missing["-"]],
    "ClampedWeight" -> Lookup[record, "ClampedWeight", Missing["-"]],
    "RequestedWeight" -> Lookup[record, "Requested", Lookup[record, "Weight", Missing["-"]]],
    "Budget" -> Lookup[record, "Budget", Missing["-"]],
    "Shift" -> Lookup[record, "Shift", Missing["-"]],
    "ExactDepthModuleDemands" -> KeyDrop[exactModule, "Table"],
    "BlockDemandEq11" -> blockDemand,
    "BlockDemandEq11NoSafety" -> blockDemandNoSafety,
    "ExactDepthEq11" -> KeyDrop[exactEq11, "Table"],
    "ExactDepthEq11NoSafety" -> KeyDrop[exactEq11NoSafety, "Table"],
    "Notes" -> notes|>
];

Do[
  Module[{fam = familyList[[k]], r, file},
    file = FileNameJoin[{outdir, fam <> ".wl"}];
    r = TimeConstrained[ledgerFor[fam], 2400,
      <|"Family" -> fam, "Status" -> "LedgerTimedOut", "Limit" -> 2400|>];
    If[! AssociationQ[r], r = <|"Family" -> fam, "Status" -> "LedgerFailed"|>];
    putAtomic[r, file];
    log[k, "/", Length[familyList], "  ", fam, "  status ", r["Status"],
      "  blocks ", Length[Lookup[r, "Blocks", {}]],
      "  clamped ", Lookup[r, "ClampedWeight", "-"],
      "  exact(module) ", Lookup[Lookup[r, "ExactDepthModuleDemands", <||>], "WMax", "-"],
      "  Eq11 demands ", Lookup[r, "BlockDemandEq11", "-"],
      "  exact(Eq11) ", Lookup[Lookup[r, "ExactDepthEq11", <||>], "WMax", "-"],
      "  ", ToString[NumberForm[N[Lookup[r, "Seconds", 0.]], {6, 1}]], " s"]],
  {k, Length[familyList]}];

log["DONE ", Length[familyList], " families -> ", outdir];
"transport_depth_ledger complete"
