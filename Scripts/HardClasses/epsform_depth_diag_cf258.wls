(* Depth diagnostics for CF258 (and CF230) in the chart WITHOUT transporting:
   MaxWeight -> 0 makes TransportFamilyInChart stop at DepthExceedsCap and return
   Budget (per-pair coupling eps-orders RMin, per-block Need) and Shift (clamped
   per-block longest paths).  From those, compare three accountings of the required
   transport weight:
     (1) module: wmax = jmax + D_global   (jmax = kmaxF - kminF over all blocks)
     (2) per-block clamped: w_i = (need_i - kmin_i) + D_i(clamped)
     (3) per-block unclamped = eps-rescaled potentials: w_i = (need_i - kmin_i) + LP_i,
         LP_i = longest path into i under edge weight (1 - ord) WITHOUT clamping
         (negative edges allowed) — this is what F_i -> eps^{m_i} F_i can realize.
   Also the block-wise transport cost proxy: sum_i dim_i * (letters)^{w_i}. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"]; vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; ee = Symbol["Global`eps"];
normalizeRegulator[expr_] := expr /. s_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep"}, SymbolName[s]] :> ee;
normalizeSymbols[expr_] := expr /. (s_Symbol /; MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y", "t", "tau", "sqrtLambda", "gli"}, SymbolName[s]] && Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);
readArtifact[file_String] := normalizeRegulator[normalizeSymbols[Get[file]]];
ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
ftClassForms = FileNameJoin[{ftData, "ClassForms"}];
ftDE = FileNameJoin[{ftData, "DifferentialEquations"}];
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
familyBlocks[family_] := Table[{a["Rows"], a["ClassID"]}, {a, Select[assignments, #["Family"] === family &]}];
chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy}, "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;

diag[family_, orders_] := Module[{de, blocks, r, budget, shift, need, rmin, perBlock, nb, kmin, tinv, ranges, dims, jmax, D, w1, w2, w3, LP, ords, edges, classes},
  de = readArtifact[FileNameJoin[{ftDE, "nnlo_de_" <> family <> ".wl"}]];
  blocks = familyBlocks[family];
  Print["==== ", family, ": ", Length[de["Av"]], " masters, ", Length[blocks], " blocks, Orders ", orders, " ===="];
  r = FeynFacet`TransportFamilyInChart[
    <|"Family" -> family, "Basis" -> Lookup[de, "BlockBasis", None], "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
    chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> blocks, "FormDirectory" -> ftClassForms,
    "PhysicalValuation" -> 0, "Orders" -> orders,
    "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False];
  Print["status: ", Lookup[r, "Status", "?"], "  requested weight: ", Lookup[r, "Requested", "?"]];
  If[! KeyExistsQ[r, "Budget"], Print["no Budget in result; keys: ", Keys[r]]; Return[$Failed]];
  budget = r["Budget"]; shift = r["Shift"];
  need = budget["Need"]; rmin = budget["RMin"]; perBlock = shift["PerBlock"];
  nb = Length[need];
  ranges = r["Assembly"]["Ranges"]; dims = Length /@ ranges;
  classes = blocks[[All, 2]];
  Print["block dims: ", dims];
  Print["block classes: ", classes];
  Print["diagonal orders (min eps-order of A_ii): ", shift["DiagonalOrder"]];
  Print["per-block Need (top F order needed): ", need];
  Print["per-block clamped shift D_i: ", perBlock, "   D_global = ", shift["Shift"]];
  ords = Table[If[i > j && rmin[[i, j]] =!= Infinity, rmin[[i, j]], "-"], {i, nb}, {j, nb}];
  Print["coupling eps-orders ord[i,j] (i depends on j; '-' = no coupling):"];
  Do[Print["  block ", i, " (dim ", dims[[i]], ", class ", classes[[i]], "): ", ords[[i]]], {i, nb}];
  edges = Flatten[Table[If[i > j && rmin[[i, j]] =!= Infinity, {i, j, rmin[[i, j]]}, Nothing], {i, nb}, {j, nb}], 1];
  Print["couplings with ord <= 0: ", Select[edges, #[[3]] <= 0 &]];
  Print["couplings with ord >= 2 (slack): ", Select[edges, #[[3]] >= 2 &]];
  (* unclamped longest path into each block, edge weight (1 - ord) *)
  LP = ConstantArray[0, nb];
  Do[LP[[i]] = Max[Append[Table[If[j < i && rmin[[i, j]] =!= Infinity, LP[[j]] + (1 - rmin[[i, j]]), -Infinity], {j, i - 1}], 0]], {i, nb}];
  Print["per-block UNCLAMPED longest path LP_i (rescaling potential): ", LP];
  (* kmin per block is not in the returned record; the module's KMinPerBlock is only in diagnostics on the transport path.
     Use the global constants window instead: jmax = requested weight - D_global. *)
  jmax = r["Requested"] - shift["Shift"];
  Print["module: jmax = ", jmax, ", D_global = ", shift["Shift"], "  => wmax = ", r["Requested"]];
  (* per-block need relative to the global bottom: needRel_i = need_i - min(need) + (jmax - (max need - min need))?  Simpler and honest:
     take the block's own window as (need_i - min over blocks of need) + (jmax - (max need - min need)) so that the top block reproduces jmax. *)
  Module[{base = jmax - (Max[need] - Min[need])},
    w2 = Table[(need[[i]] - Min[need]) + base + perBlock[[i]], {i, nb}];
    w3 = Table[(need[[i]] - Min[need]) + base + LP[[i]], {i, nb}];
    Print["per-block window (need_i - min need) + base(", base, "): ", Table[(need[[i]] - Min[need]) + base, {i, nb}]];
    Print["(2) per-block clamped weights w_i: ", w2, "   max = ", Max[w2]];
    Print["(3) per-block UNCLAMPED (eps-rescaled) weights w_i: ", w3, "   max = ", Max[w3]];
    Print["block-wise transport cost proxy sum_i dim_i * 10^w_i  — module: ", N[Total[dims] 10^r["Requested"]],
      "  clamped per-block: ", N[Total[dims 10^w2]], "  rescaled per-block: ", N[Total[dims 10^w3]]]];
  r];

r258 = diag["CF258", {0, 1}];
r230 = diag["CF230", {0, 1}];
Print["DONE"];
