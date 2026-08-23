(* Class 97: x-constant eps-factorizing gauge for the symbolically
   normalized system (Lee's "factor out eps" step), by linear algebra.

   A_norm is Fuchsian in x and normalized (verified: residue eigenvalues
   at every locus incl. infinity are in eps*Z).  Hence
       A_norm = Sum_i M_i(y,eps) / (x - x_i(y)),   x_i in {1, 0, y, -y, y/(y-1)}
   with x-INDEPENDENT M_i, and an eps-form with constant residues N_i is
   reached by an x-independent U(y,eps) iff the LINEAR system
       M_i(y,eps) . U = eps U . N_i        (all i, and infinity)
   has an invertible solution.  Reference N_i := M_i(y0,mu)/mu absorbs the
   unknown constant conjugation (WLOG U(y0,mu) = 1).

   Stage A: y = y0 fixed, eps symbolic (existence + dimension on a slice).
   Stage B: y symbolic.
   Then A_y' = U^-1 Ay_norm U - U^-1 d_y U and its eps-form status. *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = Edir;   (* outputs live beside the evidence in Results/ *)
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w; mu = Global`mu;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

sn = Get[Edir <> "/symnorm_c97.wl"];
An = sn["A"]; Tt = sn["Ttot"];
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 97 &];
Av = ent["RepAv"]; Aw = ent["RepAw"];
xx = Global`xx; sub = {v -> xx y, w -> (1 - xx) (1 - y)};
Ax = tog[((Av /. sub) y - (Aw /. sub) (1 - y)) /. xx -> x];
Ay = tog[((Av /. sub) x - (Aw /. sub) (1 - x)) /. xx -> x];

(* residues M_i(y,eps) at the five finite loci and infinity *)
lociX = {1, 0, y, -y, y/(y - 1)};
resAt[Am_, x0_] := tog[Cancel[Together[(x - x0) Am]] /. x -> x0];
Ms = timed["residues M_i(y,eps) computed", (resAt[An, #] & /@ lociX)];
Minf = timed["residue at infinity", Module[{xi = Global`xi, Axi},
   Axi = tog[-(An /. x -> 1/xi)/xi^2]; tog[Cancel[Together[xi Axi]] /. xi -> 0]]];
Print["sum-rule check (Sum M_i + M_inf == 0): ", zeroM[Plus @@ Ms + Minf]];
Print["partial-fraction check (A_norm == Sum M_i/(x-x_i)) at random point: ",
  Module[{pt = {y -> 2/9, eps -> 1/7, x -> 5/13}},
    zeroM[(An /. pt) - (Sum[Ms[[i]]/(x - lociX[[i]]), {i, 5}] /. pt)]]];
Mall = Append[Ms, Minf];

(* ---- Stage A: slice y0, symbolic eps ---- *)
y0 = 3/7; mu0 = 1/5;
Ns = tog[(# /. {y -> y0, eps -> mu0})/mu0] & /@ Mall;
Print["reference N_i eigenvalues: ", Eigenvalues /@ Ns];
Uvars = Array[Global`u, {4, 4}];
linsys[Mlist_, Nlist_] := Flatten[Table[Mlist[[i]] . Uvars - eps Uvars . Nlist[[i]], {i, Length[Mlist]}]];
solveU[Mlist_, Nlist_] := Module[{eqs, mat, ns},
  eqs = tog /@ linsys[Mlist, Nlist];
  eqs = Numerator /@ eqs;
  mat = Normal[CoefficientArrays[eqs, Flatten[Uvars]][[2]]];
  ns = NullSpace[mat];
  ns];
nsA = timed["Stage A nullspace (y=3/7, eps symbolic)", solveU[tog[# /. y -> y0] & /@ Mall, Ns]];
Print["  Stage A solution-space dimension over Q(eps): ", Length[nsA]];
If[Length[nsA] >= 1,
  Module[{UA = Partition[nsA[[1]], 4], dA, AxA},
    dA = Factor[Det[UA]];
    Print["  det U_A = ", dA];
    If[dA =!= 0,
      AxA = tog[Inverse[UA] . (An /. y -> y0) . UA];
      Print["  A_x' at y0: eps-form (A/eps eps-free)? ", FreeQ[tog[AxA/eps], eps],
        "  residues constant? ", AllTrue[tog[Inverse[UA] . # . UA/eps] & /@ (tog[# /. y -> y0] & /@ Mall), FreeQ[#, eps] &]];
      putAtomic[<|"Y0" -> y0, "Mu" -> mu0, "U" -> UA, "N" -> Ns|>, out <> "/c97_constant_gauge_slice.wl"]]]];

(* ---- Stage B: y symbolic ---- *)
nsB = timed["Stage B nullspace (y AND eps symbolic; 1500 s cap)",
  TimeConstrained[solveU[Mall, Ns], 1500, "TIMEOUT"]];
If[ListQ[nsB],
  Print["  Stage B solution-space dimension over Q(y,eps): ", Length[nsB]];
  If[Length[nsB] >= 1,
    Module[{UB = tog[Partition[nsB[[1]], 4]], dB, ok, AyB, Ui},
      dB = Factor[Det[UB]];
      Print["  det U(y,eps) = ", dB];
      Print["  U denominators: ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ UB]]]];
      Print["  U LeafCount: ", LeafCount[UB]];
      If[dB =!= 0,
        Ui = tog[Inverse[UB]];
        ok = timed["  A_x' = U^-1 A_norm U is eps-form with CONSTANT residues",
          AllTrue[tog[Ui . # . UB/eps] & /@ Mall, FreeQ[#, eps] && FreeQ[#, y] &]];
        Print["  A_x' residues (constant): ", InputForm[tog[Ui . # . UB/eps] & /@ Mall]];
        (* y-direction *)
        AyB = timed["  A_y' built (U^-1 Ay_norm U - U^-1 dU/dy) [Ay_norm via Ttot]",
          Module[{Ti = Inverse[Tt], Ayn}, Ayn = tog[Ti . Ay . Tt - Ti . D[Tt, y]];
            tog[Ui . Ayn . UB - Ui . D[UB, y]]]];
        Print["  A_y' eps-form (A/eps eps-free)? ", FreeQ[tog[AyB/eps], eps]];
        Print["  A_y' denominators: ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ AyB]]]];
        Print["  A_y' at eps=0: ", InputForm[tog[AyB /. eps -> 0]]];
        Print["  A_y' eps^1 coefficient y-loci: ",
          DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[Map[SeriesCoefficient[#, {eps, 0, 1}] &, AyB, {2}]]]]]];
        putAtomic[<|"Y0" -> y0, "Mu" -> mu0, "U" -> UB, "N" -> Ns, "AxPrimeResidues" -> (tog[Ui . # . UB/eps] & /@ Mall),
           "AyPrime" -> AyB, "Loci" -> lociX|>, out <> "/c97_constant_gauge_symbolic.wl"];
        Print[">>> saved c97_constant_gauge_symbolic.wl"]]]]];
Print["DONE"];
