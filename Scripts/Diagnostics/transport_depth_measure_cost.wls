(* Measured wall of the exact-depth recursion on CF230, before/after the
   laziness + support-cache fix.  One assembly, then the recursion timed
   COLD (cache cleared) and WARM (cache populated), plus the default
   entry point which must not run it at all. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
If[Names["FeynFacet`TransportFamily"] === {}, Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"]; xx = Symbol["Global`x"];
yy = Symbol["Global`y"]; ee = Symbol["Global`eps"]; tauS = Symbol["Global`tau"];
$nn = {"eps","v","w","x","y","u","t","tau","gli"};
norm[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr, s_Symbol /; MemberQ[$nn, SymbolName[s]] && Context[s] =!= "Global`", {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]], {i, Length[syms]}]; expr /. rules];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
assign = norm[Get[FileNameJoin[{R, "BlockClasses", "block_class_assign.wl"}]]];
de = norm[Get[FileNameJoin[{R, "DifferentialEquations", "nnlo_de_CF230.wl"}]]];
blocks = Table[{a["Rows"], a["ClassID"]}, {a, Select[assign, #["Family"] === "CF230" &]}];
chart97 = <|"Kind" -> "TwoVariable", "Variables" -> {xx, yy},
  "Subst" -> {vv -> xx yy, ww -> (1 - xx) (1 - yy)},
  "Root" -> xx - yy, "RootSquare" -> (1 - vv - ww)^2 - 4 vv ww|>;
call[opts___] := FeynFacet`TransportFamilyInChart[
  <|"Family" -> "CF230", "Av" -> de["Av"], "Aw" -> de["Aw"]|>,
  chart97, "SourceVariables" -> {vv, ww}, "Regulator" -> ee,
  "Blocks" -> blocks, "FormDirectory" -> FileNameJoin[{R, "ClassForms"}],
  "PhysicalValuation" -> 0, "Orders" -> {0, 1},
  "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False, opts];
FeynFacet`Private`masterTransportSupportCacheClear[];
{tDefault, rDefault} = AbsoluteTiming[call[]];
Print["DEFAULT  (no DepthRule/DepthReport): ", tDefault, " s   status ", Lookup[rDefault, "Status", "?"],
  "   ExactDepth -> ", Lookup[rDefault, "ExactDepth", "absent"],
  "   ClampedWeight ", Lookup[rDefault, "ClampedWeight", "-"]];
assembly = rDefault["Assembly"];
ahat = FeynFacet`Private`masterTransportPathMatrix[assembly["Apv"], assembly["Apw"],
  {xx, yy}, {1/2, yy}, tauS, {xx, yy}];
dem = <|"Demands" -> rDefault["Budget"]["Need"], "KMin" -> rDefault["KMinPerBlock"]|>;
FeynFacet`Private`masterTransportSupportCacheClear[];
{tCold, xCold} = AbsoluteTiming[FeynFacet`Private`masterTransportExactDepth[assembly, ahat, dem, ee]];
Print["EXACT DEPTH cold cache: ", tCold, " s   WMax ", xCold["WMax"]];
{tWarm, xWarm} = AbsoluteTiming[FeynFacet`Private`masterTransportExactDepth[assembly, ahat, dem, ee]];
Print["EXACT DEPTH warm cache: ", tWarm, " s   WMax ", xWarm["WMax"], "   identical ", xCold === xWarm];
{tWarm2, xW2} = AbsoluteTiming[FeynFacet`Private`masterTransportExactDepth[assembly, ahat,
  <|"Demands" -> {-Infinity,-Infinity,-Infinity,-Infinity,-Infinity,2}, "KMin" -> rDefault["KMinPerBlock"]|>, ee]];
Print["EXACT DEPTH warm, Eq.11 demands: ", tWarm2, " s   WMax ", xW2["WMax"], "  clamped ", xW2["ClampedMax"]];
Print["DONE"]; "measure_depth_cost ok"
