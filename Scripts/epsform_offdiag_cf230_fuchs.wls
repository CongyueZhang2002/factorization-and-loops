#!/usr/bin/env wolframscript
(* Off-diagonal eps-factorization, ROUTE R3b: CLOSED-FORM POLE REDUCTION
   of the off-diagonal blocks (Moser/Fuchs reduction by strip
   transformations, with the strip read off the leading pole instead of
   searched for in an ansatz).

   Same mechanism as the eps-dependent-locus strip, now at an ordinary
   eps-FREE letter L, where the DIAGONAL blocks are not regular but are
   eps-forms with constant residues.  For a strip supported in ONE block
   pair (i,j), N^2 = 0, so exactly

       A'_mu = A_mu - d_mu N + A_mu N - N A_mu ,

   and with N_ij = M / L^(k-1) (k = pole order of A_x[i,j] at L >= 2) the
   L^-k coefficient of A'_x[i,j] is

       C_k + [ (k-1) M + eps (R_i M - M R_j) ] d_x L  =  0 ,

   where R_i, R_j are the CONSTANT residue matrices of the diagonal
   eps-forms at L and C_k = (L^k A_x[i,j]) at L = 0.  That is a Sylvester
   equation whose operator is (k-1) + eps(lambda_i - lambda_j): invertible
   over Q(eps) for every k >= 2 because the diagonal eigenvalues are
   numbers times eps.  So M is DETERMINED, not searched: one linear solve
   of size dim_i * dim_j <= 16 per step, and each step lowers the pole
   order at L by at least one while creating poles at no other letter.

   ACCEPTANCE of this script (measured, printed): every off-diagonal block
   has at most SIMPLE poles at every letter afterwards, the diagonal
   blocks are unchanged, and the composed strip is block-unipotent.  The
   eps-form gate remains separate.

   Usage: epsform_offdiag_cf230_fuchs.wls [FAMILY] [INTAG] [OUTTAG] [OUTDIR] *)

$HistoryLength = 0;
root = "/home/maxzhang/factorization-and-loops";
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
inTag = If[Length[argv] >= 2, argv[[2]], "_stripped"];
outTag = If[Length[argv] >= 3, argv[[3]], "_fuchs"];
If[Length[argv] >= 4, outdir = argv[[4]]];

start = AbsoluteTime[];
log[a___] := Print["[fuchs +", ToString[Round[AbsoluteTime[] - start]], "s] ",
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
ranges = asm["Ranges"]; nb = Length[ranges]; n = Length[asm["Ax"]];
state = normalizeSymbols[Get[FileNameJoin[{outdir, "canonica_state_" <> family <> inTag <> ".wl"}]]];
a = state["A"];
a0 = a;
log[family, ": ", n, "x", n, ", ", nb, " blocks, input tag ", inTag];

(* ---- letters ---- *)
denFactors[m_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e]},
     If[TrueQ[t === 0], {}, FactorList[Denominator[t]][[All, 1]]]]], m, {2}]]];
lettersOf[aa_] := DeleteDuplicates[
   Select[DeleteDuplicates[Join[denFactors[aa[[1]]], denFactors[aa[[2]]]]],
    ! FreeQ[#, xx] || ! FreeQ[#, yy] &],
   NumberQ[Together[#1/#2]] &];
letters = lettersOf[a];
log["letters: ", letters];
If[AnyTrue[letters, ! FreeQ[#, ee] &],
  log["!! an eps-dependent locus is still present: ",
    Select[letters, ! FreeQ[#, ee] &], " -- run the q-strip first"]; Exit[1]];

(* pole order of one entry at L *)
poleOrderAt[e_, L_] := Module[{t = Together[e]},
  If[TrueQ[t === 0], 0,
   Total[Cases[FactorList[Denominator[t]], {f_, p_} /; NumberQ[Together[f/L]] :> p]]]];
(* poleOrderAt takes ONE entry.  Handing it a submatrix makes
   FactorList[Denominator[matrix]] nonsense and Total[{}] = 0, i.e. a
   silent "no poles anywhere" -- measured here on 2026-08-17, it turned a
   whole reduction run into a no-op.  Map over the entries. *)
blockPoleOrder[aa_, i_, j_, L_] := Max[Append[Flatten[Table[
     Map[poleOrderAt[#, L] &, Flatten[aa[[mu]][[ranges[[i]], ranges[[j]]]]]],
     {mu, 2}]], 0]];

(* residue of a matrix at L in the direction var, evaluated on L = 0 *)
resAt[m_, L_, var_, root_] := Map[Together, Together[L m/D[L, var]] /. root, {2}];

report[aa_] := Module[{tab, diag},
  tab = Flatten[Table[If[i > j,
      Module[{k = Max[Table[blockPoleOrder[aa, i, j, L], {L, letters}]]},
       If[k > 1, {i, j, k}, Nothing]], Nothing], {i, nb}, {j, nb}], 1];
  diag = Table[Max[Table[blockPoleOrder[aa, i, i, L], {L, letters}]], {i, nb}];
  log["  diagonal blocks max pole order (must be 1): ", diag];
  log["  block pairs with HIGHER-order poles (i,j,max order): ", tab];
  Max[Append[tab[[All, 3]], 1]]];

log["initial off-diagonal pole orders:"];
report[a];

strip = IdentityMatrix[n];
step = 0;
While[step < 60,
 Module[{worst = None, k = 1, L, var, root, dimI, dimJ, ri, rj, ck, op, m, nmat, aNew},
  (* Column order matters and is forced: the strip at (i,j) changes the
     row through (N A)_{i,k} = N_ij A_jk, which is nonzero only for
     k < j.  So a strip at column j never touches a column to its RIGHT,
     and processing columns from the rightmost inwards leaves each
     finished column finished.  Measured on 2026-08-17 with the naive
     "largest pole order anywhere" rule: (6,1) went 4 -> 3, then the
     (6,2) step put it back to 4. *)
  Do[If[i > j && worst === None,
    Module[{ko = Max[Table[blockPoleOrder[a, i, j, LL], {LL, letters}]]},
     If[ko > 1,
      k = ko;
      worst = {i, j, First[Select[letters, blockPoleOrder[a, i, j, #] === ko &]]}]]],
   {i, nb, 1, -1}, {j, nb, 1, -1}];
  If[worst === None, log["---- all off-diagonal poles are simple after ", step, " steps"]; Break[]];
  {i, j, L} = worst;
  var = If[! FreeQ[L, xx], xx, yy];
  root = First[Solve[L == 0, var]];
  log["---- step ", step, ": pair (", i, ",", j, ") letter ", L,
    " pole order ", k, " (direction ", var, ")"];
  dimI = Length[ranges[[i]]]; dimJ = Length[ranges[[j]]];
  (* constant residues of the diagonal eps-forms at L *)
  ri = resAt[a[[If[var === xx, 1, 2]]][[ranges[[i]], ranges[[i]]]], L, var, root];
  rj = resAt[a[[If[var === xx, 1, 2]]][[ranges[[j]], ranges[[j]]]], L, var, root];
  ck = Map[Together, Together[L^k a[[If[var === xx, 1, 2]]][[ranges[[i]], ranges[[j]]]]] /. root, {2}];
  (* [(k-1) M + eps(R_i M - M R_j)] d_var L = -C_k   on L = 0 *)
  op = (k - 1) IdentityMatrix[dimI dimJ] +
    KroneckerProduct[ri, IdentityMatrix[dimJ]] -
    KroneckerProduct[IdentityMatrix[dimI], Transpose[rj]];
  m = LinearSolve[op, Flatten[Map[Together[-#/(D[L, var] /. root)] &, ck, {2}]]];
  If[m === $Failed, log["!! Sylvester solve failed"]; Break[]];
  m = Map[Together, ArrayReshape[m, {dimI, dimJ}], {2}];
  nmat = ConstantArray[0, {n, n}];
  nmat[[ranges[[i]], ranges[[j]]]] = Map[Together[#/L^(k - 1)] &, m, {2}];
  If[! zeroMatQ[nmat . nmat], log["!! N^2 nonzero"]; Break[]];
  aNew = Table[Map[Together,
     a[[mu]] - D[nmat, vars[[mu]]] + a[[mu]] . nmat - nmat . a[[mu]], {2}], {mu, 2}];
  a = aNew;
  strip = Map[Together, strip . (IdentityMatrix[n] + nmat), {2}];
  step++;
  log["   new pole order at that pair/letter: ", blockPoleOrder[a, i, j, L],
    ", strip leaves ", LeafCount[nmat]]]];

log["==== after pole reduction (", step, " steps)"];
maxLeft = report[a];
log["letters now: ", lettersOf[a]];
log["strip block-unipotent: ",
  AllTrue[Flatten[Table[Together[strip[[ranges[[i]], ranges[[j]]]] -
      If[i === j, IdentityMatrix[Length[ranges[[i]]]],
       ConstantArray[0, {Length[ranges[[i]]], Length[ranges[[j]]]}]]],
     {i, nb}, {j, i, nb}]], zeroQ]];
log["diagonal blocks unchanged: ",
  AllTrue[Flatten[Table[Together[a[[mu]][[ranges[[i]], ranges[[i]]]] -
      a0[[mu]][[ranges[[i]], ranges[[i]]]]], {mu, 2}, {i, nb}]], zeroQ]];
Do[Module[{sub = Table[a[[mu]][[ranges[[i]], ranges[[j]]]], {mu, 2}]},
   If[AllTrue[Flatten[sub], zeroQ], Null,
    log["  (", i, ",", j, ") min eps order ",
     Min[FeynFacet`Private`masterTransportEpsOrder[#, ee] & /@
       Select[Flatten[sub], ! zeroQ[#] &]]]]], {i, nb}, {j, i}];

state = <|"Sector" -> state["Sector"], "S" -> Map[Together, state["S"] . strip, {2}],
  "A" -> a, "Strip" -> Lookup[state, "Strip", None], "FuchsStrip" -> strip|>;
putAtomic[state, FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["saved state to ", FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["DONE"];
