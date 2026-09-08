#!/usr/bin/env wolframscript
(* Extract a REAL block-equation construction input from a saved sector
   state, so the deferred/symbolic comparison can be iterated without
   re-reading the 86 MB state.  Read-only with respect to the campaign
   artifacts. *)
$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
base = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
   "UU_08_10_canonical", "FamilyEpsFormsSolving",
   "triple_root_2026-08-24_fable"}];
family = $ScriptCommandLine[[2]];
sector = ToExpression[$ScriptCommandLine[[3]]];
lower = ToExpression[$ScriptCommandLine[[4]]];
out = $ScriptCommandLine[[5]];

ee = Global`eps; xx = Global`x; yy = Global`y;
$normalizeNames = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w",
   "x", "y", "u", "t", "tau", "s", "p", "sqrtLambda", "gli"};
normalizeSymbols[expr_] := Module[{syms, rules},
  syms = DeleteDuplicates[Cases[expr,
     sy_Symbol /; MemberQ[$normalizeNames, SymbolName[sy]] &&
       Context[sy] =!= "Global`", {0, Infinity}, Heads -> True]];
  rules = Table[syms[[i]] -> Symbol["Global`" <> SymbolName[syms[[i]]]],
    {i, Length[syms]}]; expr /. rules];

t0 = AbsoluteTime[];
stateFile = FileNameJoin[{base, family,
   "sector_state_" <> family <> "_standard.wl"}];
state = normalizeSymbols[Get[stateFile]];
Print["state read ", Round[AbsoluteTime[] - t0, 0.1], " s; sector ",
  state["Sector"], "; masters ", Length[state["A"][[1]]]];

ranges = state["Ranges"];
blockRows[m_] := ranges[[m]];
cpFile = FileNameJoin[{base, family, "sector_" <> family <> "_standard",
   family <> "_" <> ToString[sector] <> "_strip_state.wl"}];
cp = normalizeSymbols[Get[cpFile]];
prevD = cp["PrevD"];
Print["checkpoint: SubSize ", cp["SubSize"], ", truncation ",
  cp["Truncation"], ", prevD ", Dimensions[prevD]];

solved = Module[{len = Length[prevD[[1]]], assoc = <||>,
   m = sector - 1, col},
  col = len;
  While[col > 0 && m >= 1,
   assoc[m] = prevD[[All, col - Length[blockRows[m]] + 1 ;; col]];
   col -= Length[blockRows[m]]; m--];
  assoc];
Print["solved blocks recovered: ", Sort[Keys[solved]]];

rk = blockRows[sector]; rj = blockRows[lower];
feeders = Select[Sort[Keys[solved]], lower < # < sector &];
Print["block ", {sector, lower}, ": rk ", rk, " rj ", rj,
  ", feeders ", feeders];

fixture = <|"Family" -> family, "Sector" -> sector,
  "LowerSector" -> lower, "Ranges" -> ranges,
  "RowIndices" -> rk, "ColumnIndices" -> rj, "Feeders" -> feeders,
  "ABlockKJ" -> Table[state["A"][[mu, rk, rj]], {mu, 2}],
  "ADiagK" -> Table[state["A"][[mu, rk, rk]], {mu, 2}],
  "ADiagJ" -> Table[state["A"][[mu, rj, rj]], {mu, 2}],
  "AFeed" -> Association[Table[
     m -> Table[state["A"][[mu, blockRows[m], rj]], {mu, 2}],
     {m, feeders}]],
  "Gauge" -> Association[Table[m -> solved[m], {m, feeders}]]|>;
tmp = out <> ".tmp"; Put[fixture, tmp];
RenameFile[tmp, out, OverwriteTarget -> True];
Print["fixture written ", out, " ", FileByteCount[out], " bytes, total ",
  Round[AbsoluteTime[] - t0, 0.1], " s"];
