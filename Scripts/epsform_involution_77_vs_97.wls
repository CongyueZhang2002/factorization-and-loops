(* Class 77 vs sigma*(class 97), sigma: (x,y) -> (1-x,1-y)  (= v <-> w).
   97 letters {x, y, 1-x, 1-y, x-y, x+y, x+y-xy} with residues R_a (certified).
   sigma pulls letters back:  x->1-x, y->1-y, 1-x->x, 1-y->y, x-y->-(x-y) [same locus],
   x+y -> 2-x-y [locus x=2-y], x+y-xy -> 1-xy [locus x=1/y].
   Test 1: 77's raw chart system: residue eps-parts at sigma-matched loci (needs Fuchsian points).
   Test 2: for each 77 slice eps-form (constant residues at y0), solve N77_a X = X Nsig_a
           (all loci) -> nullspace dim / invertibility.  Also compare eigenvalue lists. *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = Edir;   (* outputs live beside the evidence in Results/ *)
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];

f97 = Get[out <> "/c97_epsform_two_variable.wl"];
{Rx, Ry, R1x, R1y, Rxy, Rxpy, Rw} = f97["Residues"];
Print["97 residue eigenvalues: x:", Eigenvalues[Rx], " y:", Eigenvalues[Ry], " 1-x:", Eigenvalues[R1x],
  " 1-y:", Eigenvalues[R1y], " x-y:", Eigenvalues[Rxy], " x+y:", Eigenvalues[Rxpy], " 1-w:", Eigenvalues[Rw]];
Print["97 residue ranks: ", MatrixRank /@ {Rx, Ry, R1x, R1y, Rxy, Rxpy, Rw}];
Print["97 sum rule (x-letters): ", zeroM[Rx + R1x + Rxy + Rxpy + Rw + f97["Residues"][[1]] 0 - (-(Rx + R1x + Rxy + Rxpy + Rw))]];
(* target tuple for 77 in x at loci {0, 1, y, 2-y, 1/y, inf} *)
Nsig = {R1x, Rx, Rxy, Rxpy, Rw, -(R1x + Rx + Rxy + Rxpy + Rw)};
lociNames = {"x=0", "x=1", "x=y", "x=2-y", "x=1/y", "inf"};
Print["target (sigma*97) eigenvalues at ", lociNames, ": ", Eigenvalues /@ Nsig];

(* ---- Test 1: 77 raw chart system ---- *)
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 77 &];
Av = ent["RepAv"]; Aw = ent["RepAw"];
Print["77 dim ", Dimensions[Av], " (v,w)-loci Av: ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[Av]]]],
  " Aw: ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[Aw]]]]];
xx = Global`xx; sub = {v -> xx y, w -> (1 - xx) (1 - y)};
Ax77 = tog[((Av /. sub) y - (Aw /. sub) (1 - y)) /. xx -> x];
Ay77 = tog[((Av /. sub) x - (Aw /. sub) (1 - x)) /. xx -> x];
Print["77 chart x-loci: ", Select[DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ Ax77]]], ! FreeQ[#, x] &]];
Print["77 chart flat: ", zeroM[D[Ax77, y] - D[Ay77, x] + Ax77 . Ay77 - Ay77 . Ax77]];
(* Poincare rank at each locus and residue eigenvalues where Fuchsian *)
loci77 = {0, 1, y, 2 - y, 1/y};
Do[Module[{x0 = loci77[[i]], ord, res},
   ord = Max[Table[Module[{d = Denominator[Together[Ax77[[a, b]]]], k = 0},
       While[PolynomialQ[Together[d/(x - x0)^(k + 1)], x] && Together[d/(x - x0)^(k + 1)] =!= 0 &&
           FreeQ[Together[d/(x - x0)^(k + 1)], Power[_, _?Negative]] &&
           Denominator[Together[d/(x - x0)^(k + 1)]] === 1, k++]; k], {a, 4}, {b, 4}]];
   Print["  77 locus ", InputForm[x0], ": max pole order ", ord];
   If[ord <= 1, res = tog[Cancel[Together[(x - x0) Ax77]] /. x -> x0];
     Print["     residue eigenvalues: ", InputForm[Eigenvalues[res]]]]],
  {i, Length[loci77]}];
Module[{xi = Global`xi, Axi, ord},
  Axi = tog[-(Ax77 /. x -> 1/xi)/xi^2];
  ord = Max[Exponent[Denominator[#], xi] & /@ Flatten[Axi]];  (* crude *)
  Print["  77 infinity: crude max xi-power in denominators ", ord]];

(* ---- Test 2: 77 slice eps-forms vs sigma*97 constant tuple ---- *)
files = FileNames["canonical_slice_c77_y*.wl", Edir];
Print["77 slice files: ", Length[files]];
Uvars = Array[Global`u, {4, 4}];
inter[Nl_, Ml_] := Module[{eqs, mat},
  eqs = Flatten[Table[Nl[[i]] . Uvars - Uvars . Ml[[i]], {i, Length[Nl]}]];
  mat = Normal[CoefficientArrays[eqs, Flatten[Uvars]][[2]]];
  NullSpace[mat]];
resAt[Am_, x0_] := tog[Cancel[Together[(x - x0) Am]] /. x -> x0];
Do[Module[{d = Get[f], An, y0, N77, ns, X, ok},
   y0 = d["Y0"]; An = d["Anew"] /. Global`eps -> eps;
   N77 = tog[resAt[An, #]/eps] & /@ {0, 1, y0, 2 - y0, 1/y0};
   N77 = Append[N77, -(Plus @@ N77)];
   Print[FileNameTake[f], " y0=", y0, "  77-slice eigenvalues at ", lociNames, ": ", Eigenvalues /@ N77];
   ns = inter[N77, Nsig];
   Print["   intertwiner nullspace dim (77 slice -> sigma*97): ", Length[ns]];
   If[Length[ns] >= 1, X = Partition[ns[[1]], 4]; Print["   det X = ", Det[X], "  X = ", InputForm[X]];
     ok = AllTrue[Table[zeroM[N77[[i]] . X - X . Nsig[[i]]], {i, 6}], TrueQ];
     Print["   intertwines all 6 residues: ", ok]]],
  {f, files}];
Print["DONE"];
