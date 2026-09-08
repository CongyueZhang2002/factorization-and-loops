(* Independent re-check of the Opus-era class-97 eps-form-route claims.
   Reads ONLY repository artifacts.  Pure algebra, no package loads.
   Every check prints one line "CHECK <name>: <verdict> (<seconds>)". *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];

(* ---- 0. class-97 representative from the repo ---- *)
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 97 &];
Print["class 97 keys: ", Keys[ent]];
Av = ent["RepAv"]; Aw = ent["RepAw"];
Print["dim: ", Dimensions[Av], " members: ", Length[Lookup[ent, "Members", {}]]];
Print["family/block: ", Lookup[ent, "Representative", Missing[]]];
loci[m_, var_] := DeleteDuplicates[Select[
   Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[m]]],
   ! FreeQ[#, var] &]];
Print["(v,w)-loci of Av: ", loci[Av, v | w]];
Print["(v,w)-loci of Aw: ", loci[Aw, v | w]];
timed["orig (v,w) flatness", zeroM[D[Av, w] - D[Aw, v] + Av . Aw - Aw . Av]];

(* ---- 1. chart system  v = x y, w = (1-x)(1-y) ---- *)
xx = Global`xx;
sub = {v -> xx y, w -> (1 - xx) (1 - y)};
Ax = tog[((Av /. sub) y - (Aw /. sub) (1 - y)) /. xx -> x];
Ay = tog[((Av /. sub) x - (Aw /. sub) (1 - x)) /. xx -> x];
Print["chart Ax loci (x): ", loci[Ax, x]];
Print["chart Ax loci (all): ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ Ax]]]];
timed["chart flatness", zeroM[D[Ax, y] - D[Ay, x] + Ax . Ay - Ay . Ax]];

(* ---- 2. symnorm_c97: Ttot maps chart Ax to A_norm?  ---- *)
sn = Get[Edir <> "/symnorm_c97.wl"];
An = sn["A"]; Tt = sn["Ttot"];
Print["symnorm keys: ", Keys[sn], "  LeafCount A: ", LeafCount[An], "  T: ", LeafCount[Tt]];
Print["A_norm denominators (all factors): ",
  DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ An]]]];
Print["Ttot denominators (all factors): ",
  DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[Tt]]]]];
Print["det Ttot: ", Factor[Det[Tt]]];
y0 = 3/7;
timed["Ttot maps chart->A_norm at y=3/7",
  Module[{T0 = Tt /. y -> y0, A0 = Ax /. y -> y0, Ti},
    Ti = Inverse[T0];
    zeroM[(An /. y -> y0) - (Ti . A0 . T0 - Ti . D[T0, x])]]];
timed["Ttot maps chart->A_norm at y=2/9",
  Module[{T0 = Tt /. y -> 2/9, A0 = Ax /. y -> 2/9, Ti},
    Ti = Inverse[T0];
    zeroM[(An /. y -> 2/9) - (Ti . A0 . T0 - Ti . D[T0, x])]]];
timed["Ttot maps chart->A_norm SYMBOLIC y (600 s cap)",
  TimeConstrained[
    Module[{Ti = Inverse[Tt]}, zeroM[An - (Ti . Ax . Tt - Ti . D[Tt, x])]],
    600, "TIMEOUT"]];

(* ---- 3. Is A_norm normalized (all residue eigenvalues in eps*Q, Fuchsian, incl. infinity)? ---- *)
xloci = loci[An, x];
Print["A_norm x-loci: ", xloci];
resAt[Am_, p_] := Module[{s = Solve[p == 0, x]},
  If[Length[s] =!= 1, Print["  (locus ", p, " not linear in x: ", s, ")"]];
  Table[tog[Cancel[Together[(x - (x /. s[[k]])) Am]] /. s[[k]]], {k, Length[s]}]];
Do[
  Module[{rs = resAt[An, p]},
    Do[Print["  residue at ", p, " root ", k, ": eigen = ",
       Simplify[Eigenvalues[rs[[k]]]], "  polar order check (double pole?): ",
       AnyTrue[Flatten[An], Exponent[Denominator[Together[#]], x] > 0 &&
          ! FreeQ[Cancel[Together[Denominator[Together[#]]/p^2]] , p] === False &]],
      {k, Length[rs]}]],
  {p, xloci}];
(* infinity: xi = 1/x *)
Module[{xi = Global`xi, Axi, R},
  Axi = tog[-(An /. x -> 1/xi)/xi^2];
  Print["  order of pole at infinity (max xi-power in denominators): ",
    Max[Exponent[Denominator[#], xi] & /@ Flatten[Axi]]];
  R = tog[Cancel[Together[xi Axi]] /. xi -> 0];
  Print["  residue at infinity eigen = ", Simplify[Eigenvalues[R]]]];
(* eps-dependent apparent singularities? *)
Print["A_norm denominator factors involving BOTH eps and x: ",
  Select[DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ An]]],
    ! FreeQ[#, eps] && ! FreeQ[#, x] &]];
Print["A_norm denominator factors involving eps only: ",
  Select[DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ An]]],
    ! FreeQ[#, eps] && FreeQ[#, x] && FreeQ[#, y] &]];
Print["A_norm eps-order range of entries (min/max eps power appearing): ",
  {Min[#], Max[#]} &[Exponent[Numerator[#], eps, Min] & /@ Flatten[An]],
  " ; ", {Min[#], Max[#]} &[Exponent[Numerator[#], eps] & /@ Flatten[An]]];

(* ---- 4. y-connection of the normalized system + integrability ---- *)
timed["Ay_norm build + integrability (900 s cap)",
  TimeConstrained[
    Module[{Ti = Inverse[Tt], Ayn},
      Ayn = tog[Ti . Ay . Tt - Ti . D[Tt, y]];
      Print["  Ay_norm y-loci: ", loci[Ayn, y], "  x-loci: ", loci[Ayn, x]];
      zeroM[D[An, y] - D[Ayn, x] + An . Ayn - Ayn . An]],
    900, "TIMEOUT"]];

(* ---- 5. Phase-2 slice files: T2 maps A_norm|y0 to An2, and An2 is a dlog eps-form ---- *)
epsFormQ[Am_] := Module[{B = tog[Am/eps]}, FreeQ[B, eps]];
dlogQ[Am_] := Module[{B = tog[Am/eps], ap},
  ap = Apart[#, x] & /@ Flatten[B];
  AllTrue[Flatten[List @@@ (Plus @@@ (List /@ ap))],
    Function[t, PolynomialQ[Denominator[t], x] && Exponent[Denominator[t], x] <= 1 &&
      FreeQ[Numerator[t], x]]]];
letters[Am_] := DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[Am/eps]]]];
files = FileNames["p2_c97_y*.wl", Edir];
Print["phase-2 slice files: ", Length[files]];
Do[
  Module[{d = Get[f], y0v, T2, An2, A0, Ti, ok1, ok2, ok3},
    y0v = d["Y0"]; T2 = d["T2"] /. Global`eps -> eps; An2 = d["An"] /. Global`eps -> eps;
    A0 = An /. y -> y0v; Ti = Inverse[T2];
    ok1 = zeroM[An2 - (Ti . A0 . T2 - Ti . D[T2, x])];
    ok2 = epsFormQ[An2]; ok3 = dlogQ[An2];
    Print["  ", FileNameTake[f], " y0=", y0v, "  T2 maps A_norm->An: ", ok1,
      "  An/eps eps-free: ", ok2, "  dlog (simple poles, const residues): ", ok3,
      "  letters: ", letters[An2], "  T2 eps-dependent: ", ! FreeQ[T2, eps],
      "  T2 x-dependent: ", ! FreeQ[T2, x]]],
  {f, files}];

(* ---- 6. the interpolation-obstruction claim: gauge C=T2(x0) eps-dependent? ---- *)
Module[{d = Get[Edir <> "/p2_c97_y3_7.wl"], T2, C0},
  T2 = d["T2"] /. Global`eps -> eps; C0 = T2 /. x -> 1/2;
  Print["T2(y=3/7) at x=1/2 eps-dependent: ", ! FreeQ[tog[C0], eps],
    "  det: ", Factor[Det[T2]]]];

(* ---- 7. c97_T2_symbolic.wl content ---- *)
Print["c97_T2_symbolic.wl: ", Get[Edir <> "/c97_T2_symbolic.wl"]];
Print["DONE"];
