(* Class 79: x-constant eps-factorizing gauge for the symbolically normalized
   system (Lee's "factor out eps" step), by linear algebra.  Template:
   Scripts/epsform_finish_c97_constant_gauge.wls.

   Chart:  v = -x y, w = (1-x)(1-y);  dv/dx = -y, dw/dx = -(1-y),
                                      dv/dy = -x, dw/dy = -(1-x).
   A_norm = Sum_i M_i(y,eps)/(x - x_i),  x_i in {1, 0, y, 1-y, 2-y},
   and an eps-form with constant residues N_i is reached by an x-independent
   U(y,eps) iff  M_i . U = eps U . N_i  has an invertible solution.
   Reference N_i: FIRST the class-97 constant residues matched by eigenvalue
   list; fallback N_i := M_i(y0,mu)/mu.

   Arg 1 (optional): working directory for symnorm_c79.wl and outputs
   (default: the repository EpsFormRoute directory). *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = If[Length[$ScriptCommandLine] >= 2 && $ScriptCommandLine[[2]] =!= "", $ScriptCommandLine[[2]], Edir];
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w; mu = Global`mu;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

sn = Get[out <> "/symnorm_c79.wl"];
An = sn["A"]; Tt = sn["Ttot"];
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 79 &];
Av = ent["RepAv"]; Aw = ent["RepAw"];
xx = Global`xx; sub = {v -> -xx y, w -> (1 - xx) (1 - y)};
Ax = tog[((Av /. sub) (-y) - (Aw /. sub) (1 - y)) /. xx -> x];
Ay = tog[((Av /. sub) (-x) - (Aw /. sub) (1 - x)) /. xx -> x];
Print["Ttot maps chart -> A_norm: ",
  timed["  Ttot^-1 Ax Ttot - Ttot^-1 dTtot == A_norm",
    Module[{Ti = tog[Inverse[Tt]]}, zeroM[Ti . Ax . Tt - Ti . D[Tt, x] - An]]]];

lociX = {1, 0, y, 1 - y, 2 - y};
lociLetters = {1 - x, x, x - y, 1 - x - y, 2 - x - y};
resAt[Am_, x0_] := tog[Cancel[Together[(x - x0) Am]] /. x -> x0];
Ms = timed["residues M_i(y,eps) computed", (resAt[An, #] & /@ lociX)];
Minf = timed["residue at infinity", Module[{xi = Global`xi, Axi},
   Axi = tog[-(An /. x -> 1/xi)/xi^2]; tog[Cancel[Together[xi Axi]] /. xi -> 0]]];
Print["sum-rule check (Sum M_i + M_inf == 0): ", zeroM[Plus @@ Ms + Minf]];
Print["partial-fraction check (A_norm == Sum M_i/(x-x_i)) at a random point: ",
  Module[{pt = {y -> 2/9, eps -> 1/7, x -> 5/13}},
    zeroM[(An /. pt) - (Sum[Ms[[i]]/(x - lociX[[i]]), {i, Length[lociX]}] /. pt)]]];
Mall = Append[Ms, Minf];
Print["normalized residue eigenvalues / eps: ",
  InputForm[Table[Sort[Together /@ Eigenvalues[tog[m/eps]]], {m, Mall}]]];

(* ---- reference residue tuples ---------------------------------- *)
y0 = 3/7; mu0 = 1/5;
Nself = tog[(# /. {y -> y0, eps -> mu0})/mu0] & /@ Mall;
evsOf[m_] := Sort[Together /@ Eigenvalues[m]];
f97 = Get[Edir <> "/c97_epsform_two_variable.wl"];
R97 = f97["Residues"];        (* letter order {x, y, 1-x, 1-y, x-y, x+y, x+y-xy} *)
L97 = f97["Letters"];
R97inf = tog[-(R97[[1]] + R97[[3]] + R97[[5]] + R97[[6]] + R97[[7]])];  (* x-letters only *)
Print["class-97 residue eigenvalues (letter order ", InputForm[L97], "): ",
  InputForm[evsOf /@ R97]];
(* only the FINITE loci are matched; the residue at infinity is imposed *)
matchTuple := Module[{ok = True, res},
  res = Table[
    Module[{ev = evsOf[tog[Ms[[k]]/eps]], hits},
     hits = Select[Range[Length[R97]], evsOf[R97[[#]]] === ev &];
     If[hits === {}, ok = False; {k, {}}, {k, hits}]],
    {k, Length[Ms]}];
  Print["  per-locus eigenvalue-list hits against the 97 residues: ", InputForm[res]];
  If[! ok, $Failed, res]];
mt = matchTuple;
Print["eigenvalue-list match of the 79 loci ", InputForm[Append[lociLetters, Infinity]],
  " against the 97 residues: ", InputForm[mt]];
Print["self-reference N_i eigenvalues: ", InputForm[evsOf /@ Nself]];

Uvars = Array[Global`u, {4, 4}];
solveU[Mlist_, Nlist_] := Module[{eqs, mat},
  eqs = Numerator /@ (tog /@ Flatten[Table[
      Mlist[[i]] . Uvars - eps Uvars . Nlist[[i]], {i, Length[Mlist]}]]);
  mat = Normal[CoefficientArrays[eqs, Flatten[Uvars]][[2]]];
  NullSpace[mat]];

tryRef[label_, Ns_] := Module[{nsA, nsB, res = $Failed},
  Print["=== reference tuple: ", label, " ==="];
  Print["  reference eigenvalues: ", InputForm[evsOf /@ Ns]];
  nsA = timed["  Stage A nullspace (y=3/7, eps symbolic)",
    solveU[tog[# /. y -> y0] & /@ Mall, Ns]];
  Print["  Stage A dimension over Q(eps): ", Length[nsA]];
  If[Length[nsA] >= 1,
   Module[{UA = Partition[nsA[[1]], 4]}, Print["  det U_A = ", InputForm[Factor[Det[UA]]]]]];
  If[Length[nsA] === 0, Return[$Failed]];
  nsB = timed["  Stage B nullspace (y AND eps symbolic; 2400 s cap)",
    TimeConstrained[solveU[Mall, Ns], 2400, "TIMEOUT"]];
  If[! ListQ[nsB], Print["  Stage B: ", nsB]; Return[$Failed]];
  Print["  Stage B dimension over Q(y,eps): ", Length[nsB]];
  If[Length[nsB] === 0, Return[$Failed]];
  Module[{UB = tog[Partition[nsB[[1]], 4]], dB, Ui, okX},
   dB = Factor[Det[UB]];
   Print["  det U(y,eps) = ", InputForm[dB], "   LeafCount ", LeafCount[UB]];
   If[dB === 0, Print["  singular U"]; Return[$Failed]];
   Ui = tog[Inverse[UB]];
   okX = timed["  A_x' = U^-1 A_norm U has CONSTANT residues R_a = M_i/eps",
     AllTrue[tog[Ui . # . UB/eps] & /@ Mall, FreeQ[#, eps] && FreeQ[#, y] &]];
   res = <|"U" -> UB, "N" -> Ns, "Label" -> label, "ConstantX" -> okX,
      "AxPrimeResidues" -> (tog[Ui . # . UB/eps] & /@ Mall)|>];
  res];

result = $Failed;
(* The reference at infinity is NOT free: for a dlog form the residue at
   infinity is minus the sum of the finite ones, so it is imposed, never
   matched. *)
If[mt =!= $Failed && AllTrue[mt, Length[#[[2]]] >= 1 &],
  Module[{Nf = Table[R97[[mt[[k, 2, 1]]]], {k, Length[Ms]}], Ns},
   Ns = Append[Nf, tog[-Total[Nf]]];
   Print["  imposed N_inf eigenvalues: ", InputForm[evsOf[Last[Ns]]],
     "   measured: ", InputForm[evsOf[tog[Minf/eps]]]];
   result = tryRef["class-97 residues matched by eigenvalue list (N_inf imposed as -Sum N_i)", Ns]]];
If[result === $Failed,
  result = tryRef["self reference M_i(y0=3/7, mu=1/5)/mu", Nself]];
If[result === $Failed, Print["NO constant gauge found"]; Print["DONE"]; Exit[0]];

Module[{UB = result["U"], Ui, AyB},
 Ui = tog[Inverse[UB]];
 Print["A_x' residues (constant): ", InputForm[result["AxPrimeResidues"]]];
 AyB = timed["A_y' built (U^-1 Ay_norm U - U^-1 dU/dy)",
   Module[{Ti = tog[Inverse[Tt]], Ayn}, Ayn = tog[Ti . Ay . Tt - Ti . D[Tt, y]];
     tog[Ui . Ayn . UB - Ui . D[UB, y]]]];
 Print["A_y' eps-form (A/eps eps-free)? ", FreeQ[tog[AyB/eps], eps]];
 Print["A_y' denominators: ", InputForm[DeleteDuplicates[Flatten[
    First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ AyB]]]]];
 putAtomic[<|"Y0" -> y0, "Mu" -> mu0, "U" -> UB, "N" -> result["N"], "Reference" -> result["Label"],
    "AxPrimeResidues" -> result["AxPrimeResidues"], "AyPrime" -> AyB, "Loci" -> lociX,
    "LociLetters" -> lociLetters|>, out <> "/c79_constant_gauge_symbolic.wl"];
 Print[">>> saved c79_constant_gauge_symbolic.wl"]];
Print["DONE"];
