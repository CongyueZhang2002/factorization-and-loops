#!/usr/bin/env wolframscript
(* Diagnostic: exactly WHERE the connection fails to be a dlog form with
   constant residues, per letter and per block pair.

   Residues are taken with Residue[] at the root of each letter (safe for
   higher-order poles, which are reported separately) rather than by
   substituting the root into L*A/dL, which divides by zero whenever two
   letters meet on the locus.

   Usage: epsform_offdiag_cf230_dlogdiag.wls [FAMILY] [TAG] [OUTDIR]     *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
tag = If[Length[argv] >= 2, argv[[2]], "_stripped"];
If[Length[argv] >= 3, outdir = argv[[3]]];

start = AbsoluteTime[];
log[a___] := Print["[dlogdiag +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
xx = Symbol["Global`x"]; yy = Symbol["Global`y"]; ee = Symbol["Global`eps"];
vars = {xx, yy};
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau"}, SymbolName[s]] && Context[s] =!= "Global`" :>
   Symbol["Global`" <> SymbolName[s]]);
zeroQ[e_] := TrueQ[Together[e] === 0];
zeroMatQ[m_] := AllTrue[Flatten[m], zeroQ];

asm = normalizeSymbols[Get[FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}]]];
ranges = asm["Ranges"]; nb = Length[ranges]; n = Length[asm["Ax"]];
state = normalizeSymbols[Get[FileNameJoin[{outdir, "canonica_state_" <> family <> tag <> ".wl"}]]];
a = state["A"];
log[family, " ", n, "x", n, ", tag ", tag];

denFactors[m_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e]},
     If[TrueQ[t === 0], {}, FactorList[Denominator[t]][[All, 1]]]]], m, {2}]]];
letters = DeleteDuplicates[
   Select[DeleteDuplicates[Join[denFactors[a[[1]]], denFactors[a[[2]]]]],
    ! FreeQ[#, xx] || ! FreeQ[#, yy] &], NumberQ[Together[#1/#2]] &];
log["letters: ", letters];

poleOrderAt[e_, L_] := Module[{t = Together[e]},
  If[TrueQ[t === 0], 0,
   Total[Cases[FactorList[Denominator[t]], {f_, p_} /; NumberQ[Together[f/L]] :> p]]]];

Do[Module[{k1, k2},
   k1 = Max[Map[poleOrderAt[#, L] &, Flatten[a[[1]]]]];
   k2 = Max[Map[poleOrderAt[#, L] &, Flatten[a[[2]]]]];
   log["letter ", L, ": max pole order  x-connection ", k1, ", y-connection ", k2]],
 {L, letters}];

resid[m_, L_, var_] := Module[{sol},
  If[zeroQ[D[L, var]], Return[None]];
  sol = First[Solve[L == 0, var]];
  Map[Together[Residue[#, {var, var /. sol}]] &, m, {2}]];

log["---- residues (Residue at the root), per letter"];
resX = <||>; resY = <||>;
Do[Module[{rx, ry},
   rx = resid[a[[1]], L, xx]; ry = resid[a[[2]], L, yy];
   If[rx =!= None, resX[L] = rx];
   If[ry =!= None, resY[L] = ry];
   log["letter ", L, ":  x-residue constant ",
     If[rx === None, "-", AllTrue[Flatten[rx], FreeQ[#, xx] && FreeQ[#, yy] &]],
     ", eps-linear ",
     If[rx === None, "-", AllTrue[Flatten[rx], FreeQ[Together[#/ee], ee] &]],
     " |  y-residue constant ",
     If[ry === None, "-", AllTrue[Flatten[ry], FreeQ[#, xx] && FreeQ[#, yy] &]],
     ", eps-linear ",
     If[ry === None, "-", AllTrue[Flatten[ry], FreeQ[Together[#/ee], ee] &]]];
   If[rx =!= None,
    Module[{bad = Flatten[Table[If[
         AllTrue[Flatten[rx[[ranges[[i]], ranges[[j]]]]], FreeQ[#, xx] && FreeQ[#, yy] &],
         Nothing, {i, j}], {i, nb}, {j, nb}], 1]},
     If[bad =!= {}, log["    x-residue NON-CONSTANT in block pairs ", bad]]]];
   If[ry =!= None,
    Module[{bad = Flatten[Table[If[
         AllTrue[Flatten[ry[[ranges[[i]], ranges[[j]]]]], FreeQ[#, xx] && FreeQ[#, yy] &],
         Nothing, {i, j}], {i, nb}, {j, nb}], 1]},
     If[bad =!= {}, log["    y-residue NON-CONSTANT in block pairs ", bad]]]]],
 {L, letters}];

log["---- exact dlog reconstruction"];
recX = Sum[resX[L]/(xx - (xx /. First[Solve[L == 0, xx]])), {L, Keys[resX]}];
recY = Sum[resY[L]/(yy - (yy /. First[Solve[L == 0, yy]])), {L, Keys[resY]}];
log["A_x == sum_L Res_L/(x - x_L): ", zeroMatQ[a[[1]] - recX]];
log["A_y == sum_L Res_L/(y - y_L): ", zeroMatQ[a[[2]] - recY]];
Module[{d = Map[Together, a[[1]] - recX, {2}], bad},
 bad = Flatten[Table[If[zeroMatQ[d[[ranges[[i]], ranges[[j]]]]], Nothing, {i, j}],
    {i, nb}, {j, nb}], 1];
 log["  x-direction nonzero in block pairs ", bad]];
Module[{d = Map[Together, a[[2]] - recY, {2}], bad},
 bad = Flatten[Table[If[zeroMatQ[d[[ranges[[i]], ranges[[j]]]]], Nothing, {i, j}],
    {i, nb}, {j, nb}], 1];
 log["  y-direction nonzero in block pairs ", bad]];
log["DONE"];
