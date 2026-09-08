#!/usr/bin/env wolframscript
(* Off-diagonal eps-factorization, the FINISH after the targeted strip.

   Measured on the way in: CANONICA's fast path in
   TransformOffDiagonalBlock is guarded by

       FreeQ[irredFactors, eps] && CheckDlogForm[...]

   and irredFactors contains EPS-ONLY denominator factors such as
   (1+eps), (1+4eps), (3+5eps).  Those are numbers, not loci, so a block
   can be in perfect dlog form in (x,y) and still be sent down the full
   D-computation.  This script tests the dlog property directly:

     - the letters are the eps-FREE irreducible denominator factors,
     - the residue of each entry at each letter is computed exactly,
     - the identity  A_mu == Sum_a M_a d_mu log phi_a  with M_a free of
       x and y (but allowed to depend on eps) is checked ENTRYWISE in
       BOTH variables.

   If it holds, the only thing between here and a family eps-form is an
   eps-ONLY transformation (Lee's "factor out eps" step), and CANONICA
   ships it as TransformDlogToEpsForm.  That is run next, and the result
   is saved as a state for the gate.

   Usage: epsform_offdiag_cf230_dlog.wls [FAMILY] [INTAG] [OUTTAG] [OUTDIR] *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
inTag = If[Length[argv] >= 2, argv[[2]], "_stripped"];
outTag = If[Length[argv] >= 3, argv[[3]], "_dlogfix"];
If[Length[argv] >= 4, outdir = argv[[4]]];

start = AbsoluteTime[];
log[a___] := Print["[dlog +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
If[Names["FeynFacet`FamilyArtifactRead"] === {},
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
zeroMatQ[m_] := AllTrue[Flatten[m], zeroQ];

asm = normalizeSymbols[Get[FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}]]];
ranges = asm["Ranges"]; nb = Length[ranges]; n = Length[asm["Ax"]];
bounds = Table[{First[ranges[[i]]], Last[ranges[[i]]]}, {i, nb}];
state = normalizeSymbols[Get[FileNameJoin[{outdir, "canonica_state_" <> family <> inTag <> ".wl"}]]];
a = state["A"];
log[family, ": ", n, "x", n, ", state from sector ", state["Sector"], ", tag ", inTag];

(* ---- letters and residues ---- *)
denFactors[m_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e]},
     If[TrueQ[t === 0], {}, FactorList[Denominator[t]][[All, 1]]]]], m, {2}]]];
raw = Select[DeleteDuplicates[Join[denFactors[a[[1]]], denFactors[a[[2]]]]],
   ! FreeQ[#, xx] || ! FreeQ[#, yy] &];
epsLoci = Select[raw, ! FreeQ[#, ee] &];
letters = DeleteDuplicates[Together /@ raw, NumberQ[Together[#1/#2]] &];
log["letters (", Length[letters], "): ", letters];
log["letters that still contain eps: ", epsLoci];

residueAt[mat_, L_, var_] := Module[{sol, d = D[L, var]},
  If[zeroQ[d], Return[None]];
  sol = Solve[L == 0, var];
  If[sol === {}, Return[None]];
  Map[Together, Together[L mat/d] /. First[sol], {2}]];

resX = Association @ Table[Module[{r = residueAt[a[[1]], L, xx]},
    If[r === None, Nothing, L -> r]], {L, letters}];
resY = Association @ Table[Module[{r = residueAt[a[[2]], L, yy]},
    If[r === None, Nothing, L -> r]], {L, letters}];
constX = AllTrue[Flatten[Values[resX]], FreeQ[#, xx] && FreeQ[#, yy] &];
constY = AllTrue[Flatten[Values[resY]], FreeQ[#, xx] && FreeQ[#, yy] &];
log["residues free of x,y (eps allowed): x ", constX, ", y ", constY];
dlogX = zeroMatQ[a[[1]] - Sum[resX[L] D[Log[L], xx], {L, Keys[resX]}]];
dlogY = zeroMatQ[a[[2]] - Sum[resY[L] D[Log[L], yy], {L, Keys[resY]}]];
log["EXACT dlog identity: x ", dlogX, ", y ", dlogY];
sameR = AllTrue[Intersection[Keys[resX], Keys[resY]], zeroMatQ[resX[#] - resY[#]] &];
log["residues agree on shared letters: ", sameR];
epsLinear = AllTrue[Flatten[Values[resX]] ~Join~ Flatten[Values[resY]],
   FreeQ[Together[#/ee], ee] &];
log["residues already eps * constant: ", epsLinear];

If[! (dlogX && dlogY),
  log["!! not in dlog form -- the eps-only finish does not apply"]; Exit[2]];

(* ---- the eps-only finish ---- *)
log["running CANONICA TransformDlogToEpsForm on the full ", n, "x", n];
{secs, res} = AbsoluteTiming[CANONICA`TransformDlogToEpsForm[
   vars, bounds, IdentityMatrix[n], toCanonica[a],
   CANONICA`VerbosityLevel -> 10]];
log["  TransformDlogToEpsForm: ", Round[secs, 0.1], " s"];
If[res[[1]] === False, log["!! returned False"]; Exit[3]];
u = fromCanonica[res[[1]]];
log["  U leaves ", LeafCount[u], ", free of x,y: ", FreeQ[u, xx] && FreeQ[u, yy]];
log["  U block lower triangular: ",
  AllTrue[Flatten[Table[If[i < j, u[[ranges[[i]], ranges[[j]]]], {}],
     {i, nb}, {j, nb}]], zeroQ]];
Do[log["  U diagonal block ", i, ": ", Together[u[[ranges[[i]], ranges[[i]]]]]], {i, nb}];

aNew = Table[Map[Together, Inverse[u] . a[[mu]] . u - Inverse[u] . D[u, vars[[mu]]], {2}], {mu, 2}];
log["  A'/eps eps-free: ", AllTrue[Flatten[aNew], FreeQ[Together[#/ee], ee] &]];

state = <|"Sector" -> state["Sector"], "S" -> Map[Together, state["S"] . u, {2}],
  "A" -> aNew, "Strip" -> Lookup[state, "Strip", None], "U" -> u|>;
putAtomic[state, FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["saved state to ", FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["DONE"];
