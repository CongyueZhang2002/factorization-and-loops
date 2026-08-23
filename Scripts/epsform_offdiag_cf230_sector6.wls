#!/usr/bin/env wolframscript
(* Sector 6 of the off-diagonal eps-factorization, driven SUBSECTOR BY
   SUBSECTOR with a checkpoint after each one.

   CANONICA's TransformOffDiagonalBlock is a NestWhile over
   CalculateNextSubsectorD (one D_k per lower sector, highest first) and
   prints only on entry and exit, so a run that dies -- or a pool that is
   restarted under it -- loses every D_k already found, and a watchdog
   cannot tell a slow success from a runaway search.  This script runs
   the SAME recursion by hand, with

     - a per-subsector wall time and D size printed,
     - the partial D list saved after every subsector, and
     - resumption from that list via the documented userProvidedD
       argument of TransformOffDiagonalBlock.

   Usage: epsform_offdiag_cf230_sector6.wls [FAMILY] [INTAG] [NUMDEG] [DENDEG] [OUTTAG] [OUTDIR] *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
inTag = If[Length[argv] >= 2, argv[[2]], ""];
numDeg = If[Length[argv] >= 3, ToExpression[argv[[3]]], 1];
denDeg = If[Length[argv] >= 4, ToExpression[argv[[4]]], 0];
outTag = If[Length[argv] >= 5, argv[[5]], "_s6"];
If[Length[argv] >= 6, outdir = argv[[6]]];

start = AbsoluteTime[];
log[a___] := Print["[s6 +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
log["loading CANONICA"];
FeynFacet`Private`canonicalBlocksLoadCanonica[];

xx = Symbol["Global`x"]; yy = Symbol["Global`y"]; ee = Symbol["Global`eps"];
vars = {xx, yy};
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau"}, SymbolName[s]] && Context[s] =!= "Global`" :>
   Symbol["Global`" <> SymbolName[s]]);
toCanonica[expr_] := expr /. (s_Symbol /; SymbolName[s] === "eps") :> CANONICA`eps;
fromCanonica[expr_] := expr /. CANONICA`eps -> ee;
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
zeroQ[e_] := TrueQ[Together[e] === 0];

asm = normalizeSymbols[Get[FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}]]];
ranges = asm["Ranges"]; nb = Length[ranges]; n = Length[asm["Ax"]];
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nb}];
state = normalizeSymbols[Get[FileNameJoin[{outdir, "canonica_state_" <> family <> inTag <> ".wl"}]]];
a = state["A"];
log[family, ": ", n, "x", n, ", sectors ", bounds, ", input tag \"", inTag,
  "\", ansatz degrees (num,den) = (", numDeg, ",", denDeg, ")"];

aC = toCanonica[a];
subSize = Length[ranges[[nb]]];

(* resume from a saved partial D list *)
partFile = FileNameJoin[{outdir, "sector6_partialD_" <> family <> inTag <> ".wl"}];
prevD = If[FileExistsQ[partFile],
   Module[{p = toCanonica[normalizeSymbols[Get[partFile]]]},
    log["resuming with ", Length[First[p]], " columns of D already found"]; p],
   Table[{}, {i, subSize}]];

opts = {CANONICA`DDeltaNumeratorDegree -> numDeg,
  CANONICA`Private`DDeltaDenominatorDegree -> denDeg,
  CANONICA`VerbosityLevel -> 10};

While[Length[First[prevD]] + subSize =!= n,
 Module[{secs, res},
  log["-- subsector step: ", Length[First[prevD]], " of ",
    n - subSize, " columns of D done"];
  {secs, res} = AbsoluteTiming[
    CANONICA`CalculateNextSubsectorD[aC, vars, bounds, prevD, Sequence @@ opts]];
  If[res === False || (ListQ[res] && Length[res] === 2 && res[[1]] === False),
   log["!! CalculateNextSubsectorD returned False after ", Round[secs, 0.1], " s"];
   Exit[2]];
  prevD = res;
  log["   step done in ", Round[secs, 0.1], " s; D now ", Length[First[prevD]],
    " columns, leaves ", LeafCount[prevD]];
  putAtomic[fromCanonica[prevD], partFile]]];

log["all subsectors done; assembling the strip"];
trafoD = fromCanonica[CANONICA`Private`InsertDIntoIdentity[bounds, prevD]];
log["strip D leaves ", LeafCount[trafoD], "; unipotent: ",
  AllTrue[Flatten[Table[Together[trafoD[[ranges[[i]], ranges[[j]]]] -
      If[i === j, IdentityMatrix[Length[ranges[[i]]]],
       ConstantArray[0, {Length[ranges[[i]]], Length[ranges[[j]]]}]]],
     {i, nb}, {j, i, nb}]], zeroQ]];

aNew = Table[Map[Together, Inverse[trafoD] . a[[mu]] . trafoD -
     Inverse[trafoD] . D[trafoD, vars[[mu]]], {2}], {mu, 2}];
log["after the strip: A/eps eps-free = ",
  AllTrue[Flatten[aNew], FreeQ[Together[#/ee], ee] &]];

(* the eps-only finish *)
{secs, res} = AbsoluteTiming[CANONICA`TransformDlogToEpsForm[
   vars, bounds, IdentityMatrix[n], toCanonica[aNew], CANONICA`VerbosityLevel -> 10]];
log["TransformDlogToEpsForm: ", Round[secs, 0.1], " s"];
u = If[res[[1]] === False, log["  returned False; keeping identity"]; IdentityMatrix[n],
   fromCanonica[res[[1]]]];
log["  U leaves ", LeafCount[u], ", free of x,y: ", FreeQ[u, xx] && FreeQ[u, yy]];
aFin = Table[Map[Together, Inverse[u] . aNew[[mu]] . u - Inverse[u] . D[u, vars[[mu]]], {2}], {mu, 2}];
log["final: A/eps eps-free = ", AllTrue[Flatten[aFin], FreeQ[Together[#/ee], ee] &]];

state = <|"Sector" -> nb, "S" -> Map[Together, state["S"] . trafoD . u, {2}],
  "A" -> aFin, "Strip" -> Lookup[state, "Strip", None], "SectorSix" -> trafoD, "U" -> u|>;
putAtomic[state, FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["saved state to ", FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["DONE"];
