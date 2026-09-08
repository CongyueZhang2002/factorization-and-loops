(* Class 77: lift T_eq(x,y,eps) from the 9 slice samples by rational interpolation in y
   (candidate generator), then the EXACT two-variable gate on the ORIGINAL 77 chart system:
     T77 = T_eq . sigma*T_97 . f,   T77^-1 A77 T77 - T77^-1 dT77 == eps Sum R_a dlog phi_a  (both variables),
   with the sigma*97 constant residues (fixed target) and rational scalar f from the mismatch. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = Edir;   (* outputs live beside the evidence in Results/ *)
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
dens[m_] := DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[m]]]];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

f97 = Get[out <> "/c97_epsform_two_variable.wl"];
{Rx, Ry, R1x, R1y, Rxy, Rxpy, Rw} = f97["Residues"];
T97 = f97["T"]; sig = {x -> 1 - x, y -> 1 - y};
T97s = tog[T97 /. sig];
lettersS = {1 - x, 1 - y, x, y, x - y, 2 - x - y, 1 - x y};
ResS = {Rx, Ry, R1x, R1y, Rxy, Rxpy, Rw};
ExS = eps Sum[ResS[[a]] D[Log[lettersS[[a]]], x], {a, 7}];
EyS = eps Sum[ResS[[a]] D[Log[lettersS[[a]]], y], {a, 7}];

cls = Get[R <> "/BlockClasses/classes.wl"];
e77 = SelectFirst[cls, #["ClassID"] == 77 &];
xx = Global`xx; sub = {v -> xx y, w -> (1 - xx) (1 - y)};
Ax77 = tog[((e77["RepAv"] /. sub) y - (e77["RepAw"] /. sub) (1 - y)) /. xx -> x];
Ay77 = tog[((e77["RepAv"] /. sub) x - (e77["RepAw"] /. sub) (1 - x)) /. xx -> x];

sl = Get[out <> "/c77_slice_transformations.wl"];
Print["slices: ", Length[sl], "  y0s: ", sl[[All, "Y0"]]];
(* consistent scalar normalization: divide every slice T_eq by its (1,1) entry *)
samples = Table[<|"Y0" -> s["Y0"], "T" -> tog[s["Teq"]/s["Teq"][[1, 1]]]|>, {s, sl}];
Print["all (1,1) entries nonzero: ", AllTrue[sl, #["Teq"][[1, 1]] =!= 0 &]];
ys = samples[[All, "Y0"]];

(* rational interpolation in y of one scalar function given samples s_k in Q(x,eps) *)
ratInterp[svals_List, ypts_List] := Module[{n = Length[svals], best = $Failed},
  Do[
    Do[Module[{dN = tot - dD, a, b, unk, eqs, mat, ns, cand},
       If[dN < 0, Continue[]];
       If[dN + dD + 2 > n, Continue[]];
       a = Array[Global`aa, dN + 1, 0]; b = Array[Global`bb, dD + 1, 0];
       unk = Join[a, b];
       eqs = Table[Together[Sum[a[[m + 1]] ypts[[k]]^m, {m, 0, dN}] - svals[[k]] Sum[b[[m + 1]] ypts[[k]]^m, {m, 0, dD}]], {k, n}];
       mat = Normal[CoefficientArrays[eqs, unk][[2]]];
       ns = NullSpace[mat];
       If[Length[ns] == 1,
         cand = Together[Sum[ns[[1, m + 1]] y^m, {m, 0, dN}]/Sum[ns[[1, dN + 2 + m]] y^m, {m, 0, dD}]];
         If[Together[Sum[ns[[1, dN + 2 + m]] y^m, {m, 0, dD}]] =!= 0, best = {cand, {dN, dD}}; Break[]]]],
      {dD, 0, tot}];
    If[best =!= $Failed, Break[]],
    {tot, 0, Length[svals] - 2}];
  best];

Teq = ConstantArray[0, {4, 4}]; degs = ConstantArray[Null, {4, 4}];
Do[Module[{svals = Table[s["T"][[i, j]], {s, samples}], r},
   If[AllTrue[svals, # === 0 &], Teq[[i, j]] = 0; degs[[i, j]] = {0, 0}; Continue[]];
   r = ratInterp[svals, ys];
   If[r === $Failed, Print["  entry ", {i, j}, ": NO rational interpolant within sample budget"]; Teq[[i, j]] = $Failed,
     Teq[[i, j]] = r[[1]]; degs[[i, j]] = r[[2]]]],
  {i, 4}, {j, 4}];
Print["interpolation degrees (num,den) in y per entry: ", degs];
If[! FreeQ[Teq, $Failed], Print["interpolation failed; more slices needed"]; Exit[1]];
Teq = tog[Teq];
Print["T_eq(x,y,eps) candidate: dens ", dens[Teq], "  LeafCount ", LeafCount[Teq], "  det ", InputForm[Factor[Det[Teq]]]];

(* ---- candidate T77 and the exact gate ---- *)
T77 = tog[Teq . T97s];
Ti = tog[Inverse[T77]];
AxG = timed["A_x'' from ORIGINAL 77 chart built", tog[Ti . Ax77 . T77 - Ti . D[T77, x]]];
mismX = tog[AxG - ExS];
Print["x-mismatch is scalar*Identity: ", zeroM[mismX - mismX[[1, 1]] IdentityMatrix[4]], "   mismatch[[1,1]] = ", InputForm[mismX[[1, 1]]]];
AyG = timed["A_y'' from ORIGINAL 77 chart built", tog[Ti . Ay77 . T77 - Ti . D[T77, y]]];
mismY = tog[AyG - EyS];
Print["y-mismatch is scalar*Identity: ", zeroM[mismY - mismY[[1, 1]] IdentityMatrix[4]], "   mismatch[[1,1]] = ", InputForm[mismY[[1, 1]]]];
(* scalar f: mismatch = -(dlog f);  find rational f from integer residues *)
scal = {mismX[[1, 1]], mismY[[1, 1]]};
gaugeFactor[s_, var_] := Module[{ap = Apart[s, var], terms, facs = {}},
  terms = If[Head[ap] === Plus, List @@ ap, {ap}];
  Do[Module[{den = Denominator[Together[t]], qs, q, ratio},
     If[PolynomialQ[t, var], If[t =!= 0, Print["   polynomial part in ", var, ": ", InputForm[t]]]; Continue[]];
     qs = Select[First /@ Rest[FactorList[den]], ! FreeQ[#, var] &];
     If[Length[qs] =!= 1, Print["   unexpected term ", InputForm[t]]; Continue[]];
     q = qs[[1]]; ratio = Together[t q/D[q, var]];
     If[IntegerQ[ratio], AppendTo[facs, q^ratio], Print["   NON-integer dlog coefficient ", InputForm[ratio], " at ", InputForm[q]]]],
    {t, terms}];
  facs];
fx = gaugeFactor[-mismX[[1, 1]], x]; fy = gaugeFactor[-mismY[[1, 1]], y];
Print["dlog f factors from x: ", InputForm[fx], "  from y: ", InputForm[fy]];
f = Times @@ DeleteDuplicates[Join[fx, fy]];
Print["scalar f candidate = ", InputForm[f]];
(* if a factor appears in both lists (mixed letters), avoid double counting: rebuild from union of bases with max exponent *)
T77f = tog[T77 f]; Tif = tog[Inverse[T77f]];
gx = timed["GATE x (77): T77^-1 A77 T77 - T77^-1 dT77 == eps Sum R dlog phi EXACTLY", zeroM[Tif . Ax77 . T77f - Tif . D[T77f, x] - ExS]];
gy = timed["GATE y (77): EXACTLY", zeroM[Tif . Ay77 . T77f - Tif . D[T77f, y] - EyS]];
Print["T77 dens: ", dens[T77f], "  LeafCount ", LeafCount[T77f]];
putAtomic[<|"Class" -> 77, "Chart" -> {v -> x y, w -> (1 - x) (1 - y)}, "Variables" -> {x, y},
   "T" -> T77f, "Teq" -> Teq, "ScalarF" -> f, "Letters" -> lettersS, "Residues" -> ResS,
   "Ax" -> ExS, "Ay" -> EyS, "GateX" -> gx, "GateY" -> gy,
   "Provenance" -> "T77 = T_eq . sigma*T_97 . f; T_eq rationally interpolated in y from 9 slice transformations (Ttot.T2.X, each slice-gated), sigma:(x,y)->(1-x,1-y); residues = sigma*(class-97 residues); gate = lift_c77.wls 2026-08-16"|>,
  out <> "/c77_epsform_two_variable.wl"];
Print[">>> saved c77_epsform_two_variable.wl  GateX=", gx, " GateY=", gy];
Print["DONE"];
