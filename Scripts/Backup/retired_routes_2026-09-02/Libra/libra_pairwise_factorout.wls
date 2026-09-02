#!/usr/bin/env wolframscript
(* Exploratory sectorwise completion of an assembled block-triangular
   differential system.  Each off-diagonal block is treated together with
   its two diagonal epsilon-form blocks.  Libra therefore solves the
   covariant matrix equation jointly in epsilon; no entrywise primitive is
   assumed.  Transformations are embedded in increasing block distance and
   the final result is accepted only after exact full-family checks.

   Usage: libra_pairwise_factorout.wls <family> <outdir> [budgetSeconds] *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]],
  Get[FileNameJoin[{root, "FeynFacet", "FeynFacet.m"}]]];

clearGlobalSymbol[name_String] := ToExpression["Global`" <> name, InputForm,
  Function[symbol, Quiet[Unprotect[symbol]]; ClearAll[symbol], HoldAll]];
Scan[clearGlobalSymbol, {"tau", "s", "u", "p", "x", "y", "xi", "mu"}];

args = Rest[$ScriptCommandLine];
family = args[[1]];
outdir = args[[2]];
budget = If[Length[args] >= 3, ToExpression[args[[3]]], 300];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];

start = AbsoluteTime[];
log[a___] := Print["[pairE1 ", family, " +", ToString[Round[AbsoluteTime[] - start]],
  "s] ", StringJoin[ToString /@ {a}]];

vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
ee = Symbol["Global`eps"]; xiS = Symbol["Global`xi"];
muS = Symbol["Global`mu"];
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w",
  "x", "y", "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
    sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] && Context[sy] =!= "Global`",
    {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}];
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

ftData = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
Get[FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra", "Source", "Libra.m"}]];
Off[OptionValue::optnf];

zeroQ[expr_] := AllTrue[Flatten[expr], TrueQ[Together[#] === 0] &];
epsFactoredQ[expr_] := AllTrue[Flatten[expr],
  TrueQ[Together[#] === 0] || FreeQ[Together[#/ee], ee] &];
blockDiagonal[a_, b_] := ArrayFlatten[{{a, ConstantArray[0, {Length[a], Length[b]}]},
  {ConstantArray[0, {Length[b], Length[a]}], b}}];

specialize[tf_] := Module[{constants},
  constants = DeleteDuplicates[Cases[tf, _C, Infinity]];
  Map[Together, tf /. Thread[constants -> Range[Length[constants]]] /. muS -> 1, {2}]];

(* FactorOut and Fuchsify may return constant changes of the two diagonal
   canonical bases.  Remove those constants so transformations from
   distinct pairs at the same block distance do not alter one another's
   already-treated couplings. *)
unitLower[tf_, dj_Integer, di_Integer, x1_, x2_] := Module[
  {t = specialize[tf], a, b, c, upper, norm, out},
  a = t[[1 ;; dj, 1 ;; dj]];
  upper = t[[1 ;; dj, dj + 1 ;; dj + di]];
  b = t[[dj + 1 ;; dj + di, 1 ;; dj]];
  c = t[[dj + 1 ;; dj + di, dj + 1 ;; dj + di]];
  If[! zeroQ[upper], Return[<|"Status" -> "UpperBlockNonzero"|>]];
  If[! FreeQ[{a, c}, x1 | x2], Return[<|"Status" -> "KinematicDiagonal"|>]];
  norm = blockDiagonal[Inverse[a], Inverse[c]];
  out = Map[Together, t . norm, {2}];
  If[! zeroQ[out[[1 ;; dj, 1 ;; dj]] - IdentityMatrix[dj]] ||
     ! zeroQ[out[[dj + 1 ;; dj + di, dj + 1 ;; dj + di]] - IdentityMatrix[di]] ||
     ! zeroQ[out[[1 ;; dj, dj + 1 ;; dj + di]]],
    Return[<|"Status" -> "NormalizationFailed"|>]];
  <|"Status" -> "OK", "T" -> out, "Leaves" -> LeafCount[out]|>];

poleFactors[m_, var_] := DeleteDuplicates[Flatten[Table[
  Select[First /@ Rest[FactorList[Denominator[Together[e]]]], ! FreeQ[#, var] &],
  {e, Flatten[m]}]]];

(* ---- assemble the family from the certified diagonal class forms --- *)
de = readArtifact[FileNameJoin[{ftData, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
assignments = readArtifact[FileNameJoin[{ftData, "BlockClasses", "block_class_assign.wl"}]];
blocks = Table[{a["Rows"], a["ClassID"]},
  {a, Select[assignments, #["Family"] === family &]}];
chart = FeynFacet`TransportFamilyChart[family];
system = <|"Family" -> family, "Basis" -> de["BlockBasis"],
  "Av" -> de["Av"], "Aw" -> de["Aw"]|>;
log["assembling in ", If[AssociationQ[chart], chart["Name"], "SourceVW"]];
rec = If[AssociationQ[chart],
  FeynFacet`TransportFamilyInChart[system, chart, "SourceVariables" -> {vv, ww},
    "Regulator" -> ee, "Blocks" -> blocks,
    "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}],
    "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False],
  FeynFacet`TransportFamily[system, "Variables" -> {vv, ww}, "Regulator" -> ee,
    "Blocks" -> blocks, "FormDirectory" -> FileNameJoin[{ftData, "ClassForms"}],
    "BasePoint" -> {1/4, 1/4}, "PhysicalValuation" -> 0, "Orders" -> {0, 1},
    "TransportBackend" -> "Libra", "MaxWeight" -> 0, "Verbose" -> False]];
If[! (AssociationQ[rec] && AssociationQ[Lookup[rec, "Assembly", None]]),
  log["assembly failed: ", Lookup[rec, "Status", "?"]]; Exit[1]];

assembly = rec["Assembly"];
{x1, x2} = If[AssociationQ[chart], chart["Variables"], {vv, ww}];
Ax = assembly["Apv"]; Ay = assembly["Apw"];
ranges = assembly["Ranges"]; nb = Length[ranges]; n = Length[Ax];
Astart = {Ax, Ay}; Stot = IdentityMatrix[n]; pairLog = {}; failure = None;
log["assembled ", n, "x", n, " with ", nb, " blocks"];

applyFull[tf_] := Module[{inv = Map[Together, Inverse[tf], {2}]},
  Ax = Map[Together, inv . Ax . tf - inv . D[tf, x1], {2}];
  Ay = Map[Together, inv . Ay . tf - inv . D[tf, x2], {2}];
  Stot = Map[Together, Stot . tf, {2}]];

(* ---- solve each coupling in increasing block distance --------------- *)
Do[
  Do[
    If[i - j === dist && failure === None,
      Module[{ri = ranges[[i]], rj = ranges[[j]], di, dj, idx, mx, my,
        pairT, applyPair, makeFuchsian, factorOne, result, fullT, t0},
        If[zeroQ[{Ax[[ri, rj]], Ay[[ri, rj]]}] ||
           (epsFactoredQ[Ax[[ri, rj]]] && epsFactoredQ[Ay[[ri, rj]]]),
          Null,
          t0 = AbsoluteTime[]; di = Length[ri]; dj = Length[rj]; idx = Join[rj, ri];
          mx = ArrayFlatten[{{Ax[[rj, rj]], ConstantArray[0, {dj, di}]},
            {Ax[[ri, rj]], Ax[[ri, ri]]}}];
          my = ArrayFlatten[{{Ay[[rj, rj]], ConstantArray[0, {dj, di}]},
            {Ay[[ri, rj]], Ay[[ri, ri]]}}];
          pairT = IdentityMatrix[di + dj];
          applyPair[tf_] := Module[{inv = Map[Together, Inverse[tf], {2}]},
            mx = Map[Together, inv . mx . tf - inv . D[tf, x1], {2}];
            my = Map[Together, inv . my . tf - inv . D[tf, x2], {2}];
            pairT = Map[Together, pairT . tf, {2}]];
          makeFuchsian[var_, component_] := Module[{m = component[], tf, norm, mxi},
            If[TrueQ[Quiet[TimeConstrained[FuchsianQ[m, var], 60, False]]], Return[True]];
            tf = Quiet[TimeConstrained[Fuchsify[m, var, poleFactors[m, var]], budget, "TimedOut"]];
            If[MatrixQ[tf],
              norm = unitLower[tf, dj, di, x1, x2];
              If[norm["Status"] =!= "OK", Return[norm]];
              applyPair[norm["T"]]];
            m = component[];
            mxi = Map[Together, -(m /. var -> 1/xiS)/xiS^2, {2}];
            tf = Quiet[TimeConstrained[Fuchsify[mxi, xiS, {xiS}], budget, "TimedOut"]];
            If[MatrixQ[tf],
              norm = unitLower[tf /. xiS -> 1/var, dj, di, x1, x2];
              If[norm["Status"] =!= "OK", Return[norm]];
              applyPair[norm["T"]]];
            TrueQ[Quiet[TimeConstrained[FuchsianQ[component[], var], 60, False]]]];
          factorOne[var_, component_] := Module[{tf, norm},
            result = makeFuchsian[var, component];
            If[result =!= True, Return[result]];
            tf = Quiet[TimeConstrained[FactorOut[component[], var, ee, muS], budget, "TimedOut"]];
            If[! MatrixQ[tf], Return[tf]];
            norm = unitLower[tf, dj, di, x1, x2];
            If[norm["Status"] =!= "OK", Return[norm]];
            applyPair[norm["T"]]; True];
          result = factorOne[x1, Function[{}, mx]];
          If[result === True && !(epsFactoredQ[mx] && epsFactoredQ[my]),
            result = factorOne[x2, Function[{}, my]]];
          If[result === True && epsFactoredQ[mx] && epsFactoredQ[my],
            fullT = IdentityMatrix[n]; fullT[[idx, idx]] = pairT;
            applyFull[fullT];
            AppendTo[pairLog, <|"Pair" -> {i, j}, "Status" -> "EpsFactored",
              "Seconds" -> AbsoluteTime[] - t0, "Leaves" -> LeafCount[pairT]|>];
            log["pair ", {i, j}, " factored in ", Round[AbsoluteTime[] - t0, 0.1],
              " s; T leaves ", LeafCount[pairT]],
            failure = <|"Pair" -> {i, j}, "Reason" -> result,
              "PairFactored" -> {epsFactoredQ[mx], epsFactoredQ[my]}|>;
            log["pair ", {i, j}, " stopped: ", ToString[Short[failure, 3]]]]]]],
    {i, nb}, {j, nb}],
  {dist, 1, nb - 1}];

(* ---- exact full-family checks -------------------------------------- *)
triangularOK = zeroQ[Flatten[Table[If[j > i,
  {Ax[[ranges[[i]], ranges[[j]]]], Ay[[ranges[[i]], ranges[[j]]]]}, {}],
  {i, nb}, {j, nb}]]];
diagonalOK = AllTrue[Range[nb],
  epsFactoredQ[{Ax[[ranges[[#]], ranges[[#]]]], Ay[[ranges[[#]], ranges[[#]]]]}] &];
allFactored = epsFactoredQ[Ax] && epsFactoredQ[Ay];
inv = Map[Together, Inverse[Stot], {2}];
inverseOK = zeroQ[{Stot . inv - IdentityMatrix[n], inv . Stot - IdentityMatrix[n]}];
gaugeOK = zeroQ[{inv . Astart[[1]] . Stot - inv . D[Stot, x1] - Ax,
  inv . Astart[[2]] . Stot - inv . D[Stot, x2] - Ay}];
flatOK = zeroQ[D[Ax, x2] - D[Ay, x1] + Ax . Ay - Ay . Ax];
gate = failure === None && triangularOK && diagonalOK && allFactored &&
  inverseOK && gaugeOK && flatOK;
log["gate: factored ", allFactored, ", triangular ", triangularOK,
  ", diagonal epsilon forms ", diagonalOK, ", inverse ", inverseOK,
  ", gauge identity ", gaugeOK, ", flat ", flatOK];

record = <|"Family" -> family,
  "Status" -> If[gate, "EpsFactored", "NotFactored"],
  "GateVerdict" -> gate, "Failure" -> failure, "PairLog" -> pairLog,
  "Frame" -> If[AssociationQ[chart], chart["Name"], "SourceVW"],
  "Variables" -> {x1, x2}, "Ranges" -> ranges, "Blocks" -> assembly["Blocks"],
  "S" -> If[gate, Stot, None], "EpsFormX" -> If[gate, Ax, None],
  "EpsFormY" -> If[gate, Ay, None],
  "Gate" -> <|"EpsFactoredBoth" -> allFactored, "Triangular" -> triangularOK,
    "DiagonalsEpsForm" -> diagonalOK, "Invertible" -> inverseOK,
    "GaugeIdentity" -> gaugeOK, "Flat" -> flatOK|>,
  "WallSeconds" -> AbsoluteTime[] - start,
  "Provenance" -> "Scripts/Libra/libra_pairwise_factorout.wls; Libra Fuchsify and FactorOut on covariant two-block subsystems, embedded by increasing block distance"|>;
putAtomic[record, FileNameJoin[{outdir, "pairwise_" <> family <> ".wl"}]];
log["DONE ", record["Status"], " in ", Round[AbsoluteTime[] - start], " s"];
If[! gate, Exit[1]];
