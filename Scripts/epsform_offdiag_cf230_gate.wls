#!/usr/bin/env wolframscript
(* THE GATE for the completed FAMILY eps-form of CF230 in the chart.

   ACCEPTANCE (stated before the run; all five are exact, no numerics,
   no structural shortcut -- a CANONICA/Libra return shape is never the
   criterion):

   (i)   T_total = diag(T_i) . S is applied to the ORIGINAL permuted
         chart connections (A0x, A0y of the assembly record, i.e. the
         family's own differential equations pulled back to the chart),
             Ahat'_mu = T_total^-1 A0_mu T_total - T_total^-1 d_mu T_total,
         and Ahat'_mu / eps is EPS-FREE entrywise (Together, exact).
   (ii)  Every entry is a sum of constant matrices times dlog of EPS-FREE
         letters: with the letters read off as the irreducible
         denominator factors, the residue matrices R_a are extracted at
         each locus and the identity
             Ahat'_mu == eps Sum_a R_a d_mu log phi_a
         is checked ENTRYWISE and EXACTLY in BOTH variables, with every
         R_a free of x and y (and of eps).  No polynomial part is allowed
         (checked by the same identity).
   (iii) The pair is flat: d_y Ahat'_x - d_x Ahat'_y + [Ahat'_x, Ahat'_y] = 0.
   (iv)  S is rational, block lower triangular, and its diagonal blocks
         are free of x and y (unipotent up to an eps-ONLY block-diagonal
         factor, which is a constant change of the canonical basis of
         each block and is reported separately).
   (v)   T_total is invertible: T_total . T_total^-1 = 1 exactly.

   Also reported: the letter list, the residue ranks and eigenvalues, and
   the comparison of the letters with the raw family alphabet.

   Usage: epsform_offdiag_cf230_gate.wls [FAMILY] [TAG] [OUTDIR] [SAVE]  *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
tag = If[Length[argv] >= 2, argv[[2]], "_stripped"];
If[Length[argv] >= 3, outdir = argv[[3]]];
saveTo = If[Length[argv] >= 4, argv[[4]], ""];

start = AbsoluteTime[];
log[a___] := Print["[gate +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
If[Names["FeynFacet`TransportFamily"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

xx = Symbol["Global`x"]; yy = Symbol["Global`y"]; ee = Symbol["Global`eps"];
vars = {xx, yy};
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau"}, SymbolName[s]] && Context[s] =!= "Global`" :>
   Symbol["Global`" <> SymbolName[s]]);
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
zeroQ[e_] := TrueQ[Together[e] === 0];
zeroMatQ[m_] := AllTrue[Flatten[m], zeroQ];

asm = normalizeSymbols[Get[FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}]]];
state = normalizeSymbols[Get[FileNameJoin[{outdir, "canonica_state_" <> family <> tag <> ".wl"}]]];
ranges = asm["Ranges"]; nb = Length[ranges]; n = Length[asm["Ax"]];
s = state["S"];
log[family, ": ", n, "x", n, ", ", nb, " blocks, S leaves ", LeafCount[s]];

(* ---------- (iv) structure of S ---------- *)
upperZero = AllTrue[Flatten[Table[If[i < j, s[[ranges[[i]], ranges[[j]]]], {}],
    {i, nb}, {j, nb}]], zeroQ];
diagBlocks = Table[Map[Together, s[[ranges[[i]], ranges[[i]]]], {2}], {i, nb}];
diagXYFree = AllTrue[Flatten[diagBlocks], FreeQ[#, xx] && FreeQ[#, yy] &];
diagIdentity = AllTrue[Table[
   zeroMatQ[diagBlocks[[i]] - IdentityMatrix[Length[ranges[[i]]]]], {i, nb}], TrueQ];
log["(iv) S block lower triangular: ", upperZero,
  ";  diagonal blocks free of x,y: ", diagXYFree,
  ";  diagonal blocks identity: ", diagIdentity];
log["     S diagonal blocks: ", diagBlocks];

(* ---------- block back-substitution inverse of a block lower matrix ---------- *)
blockLowerInverse[m_] := Module[{inv, dinv, acc},
  dinv = Table[Map[Together, Inverse[m[[ranges[[i]], ranges[[i]]]]], {2}], {i, nb}];
  inv = ConstantArray[0, {n, n}];
  Do[inv[[ranges[[i]], ranges[[i]]]] = dinv[[i]], {i, nb}];
  Do[If[i > j,
    acc = Sum[m[[ranges[[i]], ranges[[k]]]] . inv[[ranges[[k]], ranges[[j]]]],
      {k, j, i - 1}];
    inv[[ranges[[i]], ranges[[j]]]] = Map[Together, -dinv[[i]] . acc, {2}]],
   {i, nb}, {j, nb}];
  inv];

log["building T_total = diag(T_i) . S"];
tbd = ConstantArray[0, {n, n}];
tbdInv = ConstantArray[0, {n, n}];
Do[tbd[[ranges[[i]], ranges[[i]]]] = asm["T"][[i]];
   tbdInv[[ranges[[i]], ranges[[i]]]] = asm["TInverse"][[i]], {i, nb}];
{sec, ttot} = AbsoluteTiming[Map[Together, tbd . s, {2}]];
log["  T_total leaves ", LeafCount[ttot], " in ", Round[sec, 0.1], " s"];
{sec, sInv} = AbsoluteTiming[blockLowerInverse[s]];
log["  S^-1 in ", Round[sec, 0.1], " s (block back-substitution)"];
{sec, ttotInv} = AbsoluteTiming[Map[Together, sInv . tbdInv, {2}]];
log["  T_total^-1 leaves ", LeafCount[ttotInv], " in ", Round[sec, 0.1], " s"];

(* ---------- (v) invertibility ---------- *)
{sec, invOK} = AbsoluteTiming[zeroMatQ[ttot . ttotInv - IdentityMatrix[n]]];
log["(v) T_total . T_total^-1 == 1: ", invOK, " (", Round[sec, 0.1], " s)"];

(* ---------- (i) push the ORIGINAL chart system through T_total ---------- *)
ap = Table[
   Module[{r},
    {sec, r} = AbsoluteTiming[Map[Together,
       ttotInv . asm[{"A0x", "A0y"}[[mu]]] . ttot - ttotInv . D[ttot, vars[[mu]]], {2}]];
    log["  Ahat'_", vars[[mu]], " built in ", Round[sec, 0.1], " s, leaves ", LeafCount[r]];
    r], {mu, 2}];

epsFree = AllTrue[Flatten[ap], FreeQ[Together[#/ee], ee] &];
log["(i) Ahat'_mu / eps eps-free entrywise: ", epsFree];
b = Table[Map[Together[#/ee] &, ap[[mu]], {2}], {mu, 2}];

(* ---------- (ii) letters and constant residues ---------- *)
letterFactors[m_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e]},
     If[TrueQ[t === 0], {}, FactorList[Denominator[t]][[All, 1]]]]], m, {2}]]];
raw = DeleteDuplicates[Join[letterFactors[b[[1]]], letterFactors[b[[2]]]]];
raw = Select[raw, ! FreeQ[#, xx] || ! FreeQ[#, yy] &];
(* normalize each letter to a canonical representative *)
letters = DeleteDuplicates[Together /@ raw,
   NumberQ[Together[#1/#2]] &];
log["(ii) candidate letters (", Length[letters], "): ", letters];
epsInLetters = Select[letters, ! FreeQ[#, ee] &];
log["     letters containing eps: ", epsInLetters];

(* Residue[] rather than (L*mat/dL) evaluated on the locus: the naive
   substitution divides by zero wherever a SECOND letter also vanishes on
   this locus (measured: it poisons the whole matrix with ComplexInfinity).
   Every letter here is linear in x and in y, so dlog L = 1/(var - root)
   and Residue is exactly the dlog coefficient. *)
residueAt[mat_, L_, var_] := Module[{sol, d},
  d = D[L, var];
  If[zeroQ[d], Return[None]];
  If[Exponent[Together[L], var] =!= 1,
   Print["   !! letter ", L, " is not linear in ", var]; Return[None]];
  sol = Solve[L == 0, var];
  If[sol === {}, Return[None]];
  Map[Together[Residue[#, {var, var /. First[sol]}]] &, mat, {2}]];

resX = Association @ Table[
   Module[{r = residueAt[b[[1]], L, xx]}, If[r === None, Nothing, L -> r]], {L, letters}];
resY = Association @ Table[
   Module[{r = residueAt[b[[2]], L, yy]}, If[r === None, Nothing, L -> r]], {L, letters}];
constX = AllTrue[Flatten[Values[resX]], FreeQ[#, xx] && FreeQ[#, yy] && FreeQ[#, ee] &];
constY = AllTrue[Flatten[Values[resY]], FreeQ[#, xx] && FreeQ[#, yy] && FreeQ[#, ee] &];
log["     residue matrices constant (free of x, y, eps):  x-direction ", constX,
  ",  y-direction ", constY];

(* the same R_a must serve both variables: check the dlog identity in both *)
reconX = Sum[resX[L] D[Log[L], xx], {L, Keys[resX]}];
reconY = Sum[resY[L] D[Log[L], yy], {L, Keys[resY]}];
gateX = zeroMatQ[b[[1]] - reconX];
gateY = zeroMatQ[b[[2]] - reconY];
log["(ii) EXACT dlog identity  Ahat'_x == eps Sum R_a dlog phi_a : ", gateX];
log["(ii) EXACT dlog identity  Ahat'_y == eps Sum R_a dlog phi_a : ", gateY];
sameR = AllTrue[Intersection[Keys[resX], Keys[resY]],
   zeroMatQ[resX[#] - resY[#]] &];
log["     residues agree between the two directions on shared letters: ", sameR];

(* ---------- (iii) flatness ---------- *)
flat = zeroMatQ[D[ap[[1]], yy] - D[ap[[2]], xx] + ap[[1]] . ap[[2]] - ap[[2]] . ap[[1]]];
log["(iii) flat: ", flat];

(* ---------- report ---------- *)
allRes = Association[Table[L -> Lookup[resX, L, Lookup[resY, L, None]], {L, letters}]];
Do[Module[{r = allRes[L]},
   If[MatrixQ[r],
    log["   letter ", L, ": rank ", MatrixRank[r], ", eigenvalues ",
     Sort[Eigenvalues[r]]]]], {L, letters}];

verdict = And @@ (TrueQ /@ {upperZero, diagXYFree, invOK, epsFree, constX, constY,
    gateX, gateY, sameR, flat});
log["==== GATE VERDICT: ", If[verdict, "PASSED", "FAILED"],
  "   (unipotent S: ", diagIdentity, ")"];

If[saveTo =!= "" && verdict,
 putAtomic[<|"Family" -> family, "Chart" -> "v = x y, w = (1-x)(1-y)",
   "Variables" -> {xx, yy}, "Regulator" -> ee, "Ranges" -> ranges,
   "Blocks" -> asm["Blocks"], "Classes" -> asm["Classes"],
   "S" -> s, "SInverse" -> sInv, "TBlockDiagonal" -> tbd,
   "TTotal" -> ttot, "TTotalInverse" -> ttotInv,
   "EpsFormX" -> ap[[1]], "EpsFormY" -> ap[[2]],
   "Letters" -> letters, "Residues" -> allRes,
   "Gate" -> <|"BlockLowerTriangular" -> upperZero,
     "SDiagonalFreeOfXY" -> diagXYFree, "SUnipotent" -> diagIdentity,
     "TTotalInvertible" -> invOK, "EpsLinear" -> epsFree,
     "ResiduesConstantX" -> constX, "ResiduesConstantY" -> constY,
     "DlogIdentityX" -> gateX, "DlogIdentityY" -> gateY,
     "ResiduesAgree" -> sameR, "Flat" -> flat|>,
   "Statement" -> "family eps-form of " <> family <> " in the chart: the \
ORIGINAL chart connections pushed through T_total = diag(T_i) . S equal \
eps Sum_a R_a dlog phi_a with constant R_a and eps-free letters, checked \
entrywise and exactly in both variables",
   "Date" -> DateString[]|>, saveTo];
 log["saved to ", saveTo]];
log["DONE"];
