(* Independent re-derivation of the class-79 two-variable eps-form gate from the artifact's T,
   Letters and Residues ONLY (the stored Ax/Ay/GateX/GateY are NOT trusted): rebuild the chart
   connection from the class representative in BlockClasses/classes.wl with v = -x y,
   w = (1-x)(1-y), push it through T, compare entrywise with eps Sum R_a dlog phi_a in x and y,
   and check flatness of the form.  Then the same audits as for 97/77 (deck intertwiner,
   eps-free letters, T regular at eps-dependent loci). *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
src = FileNameJoin[{R, "HardClasses", "EpsFormRoute",
  "c79_epsform_two_variable.wl"}];
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
dens[m_] := DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[m]]]];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
f = Get[src];
Print["keys: ", Keys[f], "  Chart: ", f["Chart"], "  Variables: ", f["Variables"]];
T = f["T"] /. (s_Symbol /; SymbolName[s] === "eps") :> eps;
letters = f["Letters"]; Rs = f["Residues"];
Print["letters: ", letters];
Print["residue eigenvalues: ", Eigenvalues /@ Rs, "  ranks: ", MatrixRank /@ Rs,
  "  all rational entries: ", AllTrue[Flatten[Rs], MatchQ[#, _Integer | _Rational] &]];
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 79 &];
Av = ent["RepAv"]; Aw = ent["RepAw"];
xx = Global`xx; sub = {v -> -xx y, w -> (1 - xx) (1 - y)};
Ax = tog[((Av /. sub) (-y) - (Aw /. sub) (1 - y)) /. xx -> x];
Ay = tog[((Av /. sub) (-x) - (Aw /. sub) (1 - x)) /. xx -> x];
timed["chart system flat", zeroM[D[Ax, y] - D[Ay, x] + Ax . Ay - Ay . Ax]];
predX = eps Sum[Rs[[a]] D[Log[letters[[a]]], x], {a, Length[letters]}];
predY = eps Sum[Rs[[a]] D[Log[letters[[a]]], y], {a, Length[letters]}];
timed["predicted eps-form flat", zeroM[D[predX, y] - D[predY, x] + predX . predY - predY . predX]];
Ti = timed["T inverted", tog[Inverse[T]]; "ok"]; Ti = tog[Inverse[T]];
Print["det T: ", InputForm[Factor[Det[T]]]];
AxG = timed["A_x'' built from ORIGINAL rep", tog[Ti . Ax . T - Ti . D[T, x]]];
gx = timed["INDEPENDENT GATE x: A_x'' == eps Sum R_a dlog_x phi_a", zeroM[AxG - predX]];
AyG = timed["A_y'' built from ORIGINAL rep", tog[Ti . Ay . T - Ti . D[T, y]]];
gy = timed["INDEPENDENT GATE y: A_y'' == eps Sum R_a dlog_y phi_a", zeroM[AyG - predY]];
(* audits *)
Print["A1 final denominators eps-free: ", AllTrue[Join[dens[predX], dens[predY]], FreeQ[#, eps] &]];
dT = dens[T]; Print["A2 T denominators: ", dT];
Print["A2 eps-dependent (x,y)-loci in T denominators: ", Select[dT, ! FreeQ[#, eps] && (! FreeQ[#, x] || ! FreeQ[#, y]) &]];
Print["A2 det T eps-dependent (x,y)-factors: ",
  Select[First /@ Rest[FactorList[Numerator[Together[Det[T]]] Denominator[Together[Det[T]]]]], ! FreeQ[#, eps] && (! FreeQ[#, x] || ! FreeQ[#, y]) &]];
(* deck: (x,y)->(y,x): letters {x,y,1-x,1-y,x-y,1-x-y,2-x-y} -> {y,x,1-y,1-x,-(x-y),1-x-y,2-x-y}: perm {2,1,4,3,5,6,7} *)
Uv = Array[Global`u, {4, 4}];
inter[Nl_, Ml_] := Module[{eqs, mat}, eqs = Flatten[Table[Nl[[i]] . Uv - Uv . Ml[[i]], {i, Length[Nl]}]];
  mat = Normal[CoefficientArrays[eqs, Flatten[Uv]][[2]]]; NullSpace[mat]];
ns = inter[Rs, Rs[[{2, 1, 4, 3, 5, 6, 7}]]];
Print["A4 deck intertwiner nullspace dim: ", Length[ns]];
If[Length[ns] >= 1, Module[{S = Partition[ns[[1]], 4]},
  Print["A4 det S = ", Det[S], "  S^2 scalar: ", zeroM[S . S - (S . S)[[1, 1]] IdentityMatrix[4]],
    "  intertwines all: ", AllTrue[Table[zeroM[Rs[[k]] . S - S . Rs[[{2, 1, 4, 3, 5, 6, 7}]][[k]]], {k, 7}], TrueQ]]]];
Print["RESULT class 79: GATE x = ", gx, "  GATE y = ", gy];
Print["DONE"];
