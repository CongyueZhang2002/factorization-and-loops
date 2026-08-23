(* Class 79 constant gauge by SAMPLING + rational interpolation in y.

   Measured on this system: the linear system M_i(y,eps) U = eps U N_i is
   solved in 8.3 s at a FIXED rational y with eps symbolic, while the same
   NullSpace with y symbolic did not return in 2400 s.  So U is sampled at
   rational y, normalized by one entry (its scale is the only freedom, the
   nullspace being 1-dimensional), rationally interpolated in y over
   Q(eps) -- a CANDIDATE GENERATOR -- and then VERIFIED exactly:
       M_i(y,eps) . U(y,eps) == eps U(y,eps) . N_i   for every locus
   including infinity, symbolically in y and eps.  The certificate is the
   verification, never the interpolation.

   Arg 1 (optional): working directory (default: repository EpsFormRoute). *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = If[Length[$ScriptCommandLine] >= 2 && $ScriptCommandLine[[2]] =!= "", $ScriptCommandLine[[2]], Edir];
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

sn = Get[out <> "/symnorm_c79.wl"]; An = sn["A"]; Tt = sn["Ttot"];
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 79 &];
xx = Global`xx; sub = {v -> -xx y, w -> (1 - xx) (1 - y)};
Ay = tog[((ent["RepAv"] /. sub) (-x) - (ent["RepAw"] /. sub) (1 - x)) /. xx -> x];
lociX = {1, 0, y, 1 - y, 2 - y};
lociLetters = {1 - x, x, x - y, 1 - x - y, 2 - x - y};
resAt[Am_, x0_] := tog[Cancel[Together[(x - x0) Am]] /. x -> x0];
t0 = AbsoluteTime[];
Ms = timed["residues M_i(y,eps)", (resAt[An, #] & /@ lociX); "done"];
Ms = resAt[An, #] & /@ lociX;
Minf = Module[{xi = Global`xi, Axi},
   Axi = tog[-(An /. x -> 1/xi)/xi^2]; tog[Cancel[Together[xi Axi]] /. xi -> 0]];
Mall = Append[Ms, Minf];
Print["sum rule: ", zeroM[Plus @@ Ms + Minf], "   (", Round[AbsoluteTime[] - t0, .1], " s)"];
y0 = 3/7; mu0 = 1/5;
Ns = tog[(# /. {y -> y0, eps -> mu0})/mu0] & /@ Mall;
Print["reference N_i eigenvalue lists: ", InputForm[Sort[Eigenvalues[#]] & /@ Ns]];

Uvars = Array[Global`u, {4, 4}];
solveAt[yk_] := Module[{Mk, eqs, mat, ns},
  Mk = tog[# /. y -> yk] & /@ Mall;
  eqs = Numerator /@ (tog /@ Flatten[Table[Mk[[i]] . Uvars - eps Uvars . Ns[[i]], {i, Length[Mk]}]]);
  mat = Normal[CoefficientArrays[eqs, Flatten[Uvars]][[2]]];
  ns = NullSpace[mat];
  If[Length[ns] =!= 1, $Failed, Partition[ns[[1]], 4]]];

ys = {3/7, 2/9, 5/8, 1/6, 4/5, 5/11, 7/13, 3/10, 8/17, 9/14, 2/3, 6/7, 1/12, 10/13, 4/9, 7/15, 11/17, 5/17};
samples = {}; usedYs = {};
Do[Module[{U = TimeConstrained[solveAt[yk], 300, $TimedOut]},
   If[MatrixQ[U],
    AppendTo[samples, U]; AppendTo[usedYs, yk];
    Print["  sample y=", InputForm[yk], " solved  (", Round[AbsoluteTime[] - t0, .1], " s)"],
    Print["  sample y=", InputForm[yk], " FAILED: ", U]]],
 {yk, ys}];
Print["samples: ", Length[samples]];
If[Length[samples] < 6, Print["too few samples"]; Print["DONE"]; Exit[0]];
(* common normalization: an entry nonzero in every sample *)
pos = SelectFirst[Flatten[Table[{i, j}, {i, 4}, {j, 4}], 1],
   Function[p, AllTrue[samples, Together[#[[p[[1]], p[[2]]]]] =!= 0 &]], $Failed];
If[pos === $Failed, Print["no common nonzero entry to normalize by"]; Print["DONE"]; Exit[0]];
Print["normalizing every sample by entry ", pos];
samples = Table[tog[s/s[[pos[[1]], pos[[2]]]]], {s, samples}];

ratInterp[svals_List, ypts_List] := Module[{n = Length[svals], best = $Failed},
  Do[Do[Module[{dN = tot - dD, a, b, unk, eqs, mat, ns},
     If[dN < 0, Continue[]];
     If[dN + dD + 2 > n, Continue[]];
     a = Array[Global`aa, dN + 1, 0]; b = Array[Global`bb, dD + 1, 0];
     unk = Join[a, b];
     eqs = Table[Together[Sum[a[[m + 1]] ypts[[k]]^m, {m, 0, dN}] -
         svals[[k]] Sum[b[[m + 1]] ypts[[k]]^m, {m, 0, dD}]], {k, n}];
     mat = Normal[CoefficientArrays[eqs, unk][[2]]];
     ns = NullSpace[mat];
     If[Length[ns] == 1,
      Module[{den = Together[Sum[ns[[1, dN + 2 + m]] y^m, {m, 0, dD}]]},
       If[den =!= 0,
        best = {Together[Sum[ns[[1, m + 1]] y^m, {m, 0, dN}]/den], {dN, dD}}]]]],
    {dD, 0, tot}];
   If[best =!= $Failed, Break[]], {tot, 0, Length[svals] - 2}];
  best];

Uint = ConstantArray[0, {4, 4}]; degs = ConstantArray[Null, {4, 4}];
Do[Module[{sv = Table[s[[i, j]], {s, samples}], r},
   If[AllTrue[sv, # === 0 &], Uint[[i, j]] = 0; degs[[i, j]] = {0, 0}; Continue[]];
   r = TimeConstrained[ratInterp[sv, usedYs], 600, $TimedOut];
   If[! ListQ[r], Print["  entry ", {i, j}, ": interpolation ", r]; Uint[[i, j]] = $Failed,
    Uint[[i, j]] = r[[1]]; degs[[i, j]] = r[[2]]]],
 {i, 4}, {j, 4}];
Print["interpolation degrees (num,den) in y: ", degs, "   (", Round[AbsoluteTime[] - t0, .1], " s)"];
If[! FreeQ[Uint, $Failed], Print["interpolation incomplete"]; Print["DONE"]; Exit[0]];
UB = tog[Uint];
Print["U LeafCount ", LeafCount[UB]];
dU = timed["det U factored", Factor[Det[UB]]];
If[dU === 0, Print["singular U"]; Print["DONE"]; Exit[0]];
okAll = timed["VERIFY (exact, y and eps symbolic): M_i U == eps U N_i at every locus incl. infinity",
  AllTrue[Range[Length[Mall]], zeroM[Mall[[#]] . UB - eps UB . Ns[[#]]] &]];
Ui = tog[Inverse[UB]];
Rs = tog[Ui . # . UB/eps] & /@ Mall;
okConst = timed["residues R_a = U^-1 M_i U / eps are CONSTANT (y- and eps-free)",
  AllTrue[Rs, FreeQ[#, eps] && FreeQ[#, y] &]];
Print["A_x' residues: ", InputForm[Rs]];
AyB = timed["A_y' = U^-1 A_y,norm U - U^-1 dU/dy built",
  Module[{Ti = tog[Inverse[Tt]], Ayn}, Ayn = tog[Ti . Ay . Tt - Ti . D[Tt, y]];
    tog[Ui . Ayn . UB - Ui . D[UB, y]]]];
Print["A_y'/eps eps-free: ", FreeQ[tog[AyB/eps], eps]];
putAtomic[<|"Y0" -> y0, "Mu" -> mu0, "U" -> UB, "N" -> Ns,
   "Reference" -> "self reference M_i(y0=3/7,mu=1/5)/mu; U sampled at " <> ToString[Length[usedYs]] <>
     " rational y, normalized by entry " <> ToString[pos] <> ", rationally interpolated in y, VERIFIED exactly",
   "SampleYs" -> usedYs, "InterpolationDegrees" -> degs,
   "AxPrimeResidues" -> Rs, "AyPrime" -> AyB, "Loci" -> lociX, "LociLetters" -> lociLetters,
   "VerifiedAllLoci" -> okAll, "ConstantResidues" -> okConst|>,
  out <> "/c79_constant_gauge_symbolic.wl"];
Print[">>> saved c79_constant_gauge_symbolic.wl"];
Print["DONE"];
