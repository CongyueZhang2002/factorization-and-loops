#!/usr/bin/env wolframscript
(* Off-diagonal eps-factorization, ROUTE R3: the TARGETED STRIP that
   removes the eps-DEPENDENT apparent locus q(x,y,eps) from the
   assembled canonical connection, in closed form and with no ansatz.

   Ansatz and its justification (stated before the run):

   S = 1 + N, N strictly block lower triangular (identity diagonal
   blocks), supported in the rows of the block that carries the locus
   and the columns of its subsectors.  Because N's row support and
   column support are disjoint, N^2 = 0, so

       S^-1 = 1 - N          and
       A'_mu = A_mu - d_mu N + A_mu N - N A_mu          (exactly).

   Let q be the (unique, measured) eps-dependent irreducible denominator
   factor that depends on x and y, and let k >= 2 be the maximal order of
   the pole of A at q = 0.  Writing N = M/q^(k-1),

       -d_mu N  =  (k-1) M d_mu q / q^k  -  d_mu M / q^(k-1) ,

   so the q^-k coefficient of A'_mu vanishes iff

       (k-1) M d_x q  =  -(q^k A_x)|_{q=0}  .

   d_x q is invertible modulo q (PolynomialExtendedGCD in y over
   Q(x,eps)), so this determines M modulo q -- and any rational
   representative is a valid strip, the difference being a regular term.
   The pole order therefore drops by at least one per step, and the
   iteration stops when no q-pole is left.

   That the residue of a SIMPLE pole must vanish is a theorem here, not a
   hope: the diagonal blocks are regular at q = 0, so the residue is
   strictly block lower triangular, hence nilpotent, so a simple pole
   would give the local monodromy exp(2 pi i R) = 1 + 2 pi i R =!= 1 and
   logarithms -- while the solutions are T^-1 (meromorphic), i.e.
   meromorphic.  So a simple pole with nonzero residue cannot occur, and
   the iteration must terminate at "no pole".

   ACCEPTANCE of this script (measured, printed): after the strip, no
   entry of either connection has q in its denominator, and the
   connection is still block lower triangular with UNCHANGED diagonal
   blocks (the strip is unipotent).  The eps-form gate itself is a
   separate script.

   Usage: epsform_offdiag_cf230_strip.wls [FAMILY] [INTAG] [OUTTAG] [OUTDIR] *)

$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 3];
outdir = "/tmp/claude-1000/-home-maxzhang/97c0fce7-1578-4630-a481-38730c7f8b9d/scratchpad/opus_offdiag";

argv = Rest[$ScriptCommandLine];
family = If[Length[argv] >= 1, argv[[1]], "CF230"];
inTag = If[Length[argv] >= 2, argv[[2]], ""];
outTag = If[Length[argv] >= 3, argv[[3]], "_stripped"];
If[Length[argv] >= 4, outdir = argv[[4]]];
If[! DirectoryQ[outdir], CreateDirectory[outdir]];

start = AbsoluteTime[];
log[a___] := Print["[strip +", ToString[Round[AbsoluteTime[] - start]], "s] ",
  StringJoin[ToString /@ {a}]];

log["loading FACET"];
If[Names["FeynFacet`FamilyArtifactRead"] === {},
  Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];

xx = Symbol["Global`x"]; yy = Symbol["Global`y"]; ee = Symbol["Global`eps"];
normalizeSymbols[expr_] := expr /. (s_Symbol /;
   MemberQ[{"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
     "t", "tau"}, SymbolName[s]] && Context[s] =!= "Global`" :>
   Symbol["Global`" <> SymbolName[s]]);
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"},
  Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

asm = normalizeSymbols[Get[FileNameJoin[{outdir, "assembly_" <> family <> ".wl"}]]];
ranges = asm["Ranges"]; nb = Length[ranges]; n = Length[asm["Ax"]];

inFile = FileNameJoin[{outdir, "canonica_state_" <> family <> inTag <> ".wl"}];
If[! FileExistsQ[inFile], log["!! no input state ", inFile]; Exit[1]];
state = normalizeSymbols[Get[inFile]];
log[family, ": input state at sector ", state["Sector"], ", ", n, "x", n];

a = state["A"];

(* ---- the eps-dependent, (x,y)-dependent denominator factors ---- *)
epsXYDen[m_] := DeleteDuplicates[Flatten[Map[
   Function[e, Module[{t = Together[e]},
     If[TrueQ[t === 0], {},
      Select[FactorList[Denominator[t]][[All, 1]],
       ! FreeQ[#, ee] && (! FreeQ[#, xx] || ! FreeQ[#, yy]) &]]]], m, {2}]]];

loci = DeleteDuplicates[Join[epsXYDen[a[[1]]], epsXYDen[a[[2]]]]];
log["eps-dependent (x,y) loci in the connection: ", loci];
If[Length[loci] =!= 1,
  log["!! expected exactly one locus, got ", Length[loci]]; Exit[1]];
q = First[loci];
log["locus q = ", q, "    (q at eps=0: ", Factor[q /. ee -> 0], ")"];

(* order of the pole at q = 0 of one entry *)
poleOrder[e_] := Module[{t = Together[e], fl},
  If[TrueQ[t === 0], 0,
   fl = FactorList[Denominator[t]];
   Total[Cases[fl, {f_, p_} /; NumberQ[Together[f/q]] :> p]]]];
maxPole[m_] := Max[Append[Map[poleOrder, Flatten[m]], 0]];

(* which block rows carry the pole *)
poleRows[a_] := Select[Range[nb], Function[i,
   Max[maxPole[a[[1]][[ranges[[i]], All]]], maxPole[a[[2]][[ranges[[i]], All]]]] > 0]];

(* inverse of d_x q modulo q, as a rational function *)
{gcd, cofac} = PolynomialExtendedGCD[q, D[q, xx], yy];
log["PolynomialExtendedGCD[q, d_x q, y]: gcd = ", gcd];
If[! FreeQ[gcd, yy], log["!! gcd depends on y -- q and d_x q are not coprime"]; Exit[1]];
dxqInv = Together[cofac[[2]]/gcd];
log["check (d_x q) * inv == 1 mod q: ",
  TrueQ[Together[PolynomialRemainder[Together[D[q, xx] dxqInv - 1] //
      Numerator, q, yy]] === 0]];

strip = IdentityMatrix[n];
step = 0;
While[True,
 Module[{k, rows, cols, mat, nmat, aNew},
  k = Max[maxPole[a[[1]]], maxPole[a[[2]]]];
  log["---- step ", step, ": max pole order at q = ", k,
    "   (rows carrying it: ", poleRows[a], ")"];
  If[k === 0, Break[]];
  If[k === 1,
   log["!! a SIMPLE pole survives -- the nilpotency/monodromy argument says this cannot happen; stopping"];
   Break[]];
  rows = Flatten[ranges[[poleRows[a]]]];
  cols = Complement[Range[n], rows];
  (* M from the leading pole in the x-connection *)
  mat = Map[Together[q^k #] &, a[[1]][[rows, cols]], {2}];
  mat = Map[Together[-# dxqInv/(k - 1)] &, mat, {2}];
  nmat = ConstantArray[0, {n, n}];
  nmat[[rows, cols]] = Map[Together[#/q^(k - 1)] &, mat, {2}];
  (* N^2 = 0 by disjoint support, so S^-1 = 1 - N exactly *)
  If[! AllTrue[Flatten[Together[nmat . nmat]], TrueQ[# === 0] &],
   log["!! N^2 is not zero -- support assumption violated"]; Exit[1]];
  aNew = Table[Map[Together,
     a[[mu]] - D[nmat, {xx, yy}[[mu]]] + a[[mu]] . nmat - nmat . a[[mu]], {2}],
    {mu, 2}];
  a = aNew;
  strip = Together[strip . (IdentityMatrix[n] + nmat)];
  step++;
  log["   applied strip of leaves ", LeafCount[nmat],
    "; new max pole ", Max[maxPole[a[[1]]], maxPole[a[[2]]]]];
  If[step > 6, log["!! more than 6 steps -- stopping"]; Break[]]]];

log["==== after the strip"];
log["eps-dependent (x,y) loci left: ",
  DeleteDuplicates[Join[epsXYDen[a[[1]]], epsXYDen[a[[2]]]]]];
log["strip leaves ", LeafCount[strip], "; unipotent (identity diagonal blocks, zero above)? ",
  AllTrue[Flatten[Table[Together[strip[[ranges[[i]], ranges[[j]]]] -
      If[i === j, IdentityMatrix[Length[ranges[[i]]]],
       ConstantArray[0, {Length[ranges[[i]]], Length[ranges[[j]]]}]]],
     {i, nb}, {j, i, nb}]], TrueQ[# === 0] &]];
log["diagonal blocks unchanged? ",
  AllTrue[Flatten[Table[Together[a[[mu]][[ranges[[i]], ranges[[i]]]] -
      state["A"][[mu]][[ranges[[i]], ranges[[i]]]]], {mu, 2}, {i, nb}]],
   TrueQ[# === 0] &]];
Do[Module[{sub},
   sub = Table[a[[mu]][[ranges[[i]], ranges[[j]]]], {mu, 2}];
   If[AllTrue[Flatten[sub], TrueQ[Together[#] === 0] &], Null,
    log["  (", i, ",", j, ") min eps order ",
     Min[FeynFacet`Private`masterTransportEpsOrder[#, ee] & /@
       Select[Flatten[sub], ! TrueQ[Together[#] === 0] &]]]]],
  {i, nb}, {j, i}];

state = <|"Sector" -> state["Sector"], "S" -> Together[state["S"] . strip],
  "A" -> a, "Strip" -> strip|>;
putAtomic[state, FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["saved state to ", FileNameJoin[{outdir, "canonica_state_" <> family <> outTag <> ".wl"}]];
log["DONE"];
