(* Class 77: per-slice exact transformation to the FIXED target sigma*(E_97), and the
   gauge-equivalence T_eq = T_slice77 . (sigma*T_97)^-1 between A_77 and sigma*A_97.
   Slice gate first (certifies Ttot.T2.X against A_77 chart slice), then structure of T_eq. *)
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
T97 = f97["T"];
sig = {x -> 1 - x, y -> 1 - y};
T97s = tog[T97 /. sig];                                  (* sigma*T_97 *)
(* target for 77: letters and residues after pullback *)
lettersS = {1 - x, 1 - y, x, y, x - y, 2 - x - y, 1 - x y};   (* images of {x,y,1-x,1-y,x-y,x+y,x+y-xy} *)
ResS = {Rx, Ry, R1x, R1y, Rxy, Rxpy, Rw};
ExS = eps Sum[ResS[[a]] D[Log[lettersS[[a]]], x], {a, 7}];
EyS = eps Sum[ResS[[a]] D[Log[lettersS[[a]]], y], {a, 7}];
Print["target flat: ", zeroM[D[ExS, y] - D[EyS, x] + ExS . EyS - EyS . ExS]];

cls = Get[R <> "/BlockClasses/classes.wl"];
e77 = SelectFirst[cls, #["ClassID"] == 77 &]; e97 = SelectFirst[cls, #["ClassID"] == 97 &];
xx = Global`xx; sub = {v -> xx y, w -> (1 - xx) (1 - y)};
chartX[Av_, Aw_] := tog[((Av /. sub) y - (Aw /. sub) (1 - y)) /. xx -> x];
chartY[Av_, Aw_] := tog[((Av /. sub) x - (Aw /. sub) (1 - x)) /. xx -> x];
Ax77 = chartX[e77["RepAv"], e77["RepAw"]]; Ay77 = chartY[e77["RepAv"], e77["RepAw"]];
Ax97 = chartX[e97["RepAv"], e97["RepAw"]]; Ay97 = chartY[e97["RepAv"], e97["RepAw"]];
(* sigma* of the 97 chart connection: pull back the 1-form: A'_x(x,y) = -Ax97(1-x,1-y), A'_y = -Ay97(1-x,1-y) *)
Ax97s = tog[-(Ax97 /. sig)]; Ay97s = tog[-(Ay97 /. sig)];
Print["sigma*T97 maps sigma*A97 to target (x): ",
  timed["  gate x", zeroM[Inverse[T97s] . Ax97s . T97s - Inverse[T97s] . D[T97s, x] - ExS]]];
Print["77 chart x-dens: ", dens[Ax77], "  sigma*97 chart x-dens: ", dens[Ax97s]];

(* ---- per slice ---- *)
Uvars = Array[Global`u, {4, 4}];
inter[Nl_, Ml_] := Module[{eqs, mat},
  eqs = Flatten[Table[Nl[[i]] . Uvars - Uvars . Ml[[i]], {i, Length[Nl]}]];
  mat = Normal[CoefficientArrays[eqs, Flatten[Uvars]][[2]]];
  NullSpace[mat]];
resAt[Am_, x0_] := tog[Cancel[Together[(x - x0) Am]] /. x -> x0];
NsigLoci[y0_] := {1 - 0 x, 0} ; (* unused *)
files = Select[FileNames["canonical_slice_c77_y*.wl", Edir], KeyExistsQ[Get[#], "Y0"] &];
Print["slices: ", Length[files]];
results = {};
Do[Module[{d = Get[f], y0, Tt, T2, An, N77, Nsig, ns, X, Tsl, gate, Teq, dTeq, dg, ent, TeqN},
   y0 = d["Y0"]; Tt = d["Ttot"] /. Global`eps -> eps; T2 = d["T2"] /. Global`eps -> eps; An = d["Anew"] /. Global`eps -> eps;
   N77 = tog[resAt[An, #]/eps] & /@ {0, 1, y0, 2 - y0, 1/y0}; N77 = Append[N77, -(Plus @@ N77)];
   Nsig = {R1x, Rx, Rxy, Rxpy, Rw, -(R1x + Rx + Rxy + Rxpy + Rw)};
   ns = inter[N77, Nsig]; X = Partition[ns[[1]], 4];
   Tsl = tog[Tt . T2 . X];
   gate = zeroM[Inverse[Tsl] . (Ax77 /. y -> y0) . Tsl - Inverse[Tsl] . D[Tsl, x] - (ExS /. y -> y0)];
   Teq = tog[Tsl . Inverse[T97s /. y -> y0]];
   dg = Factor[Det[Teq]];
   Print[FileNameTake[f], " y0=", y0, "  slice gate (Ttot.T2.X maps A77|y0 -> target|y0): ", gate];
   Print["   T_slice dens: ", dens[Tsl], "  LeafCount ", LeafCount[Tsl]];
   Print["   T_eq dens: ", dens[Teq], "  LeafCount ", LeafCount[Teq], "  det T_eq = ", InputForm[dg]];
   Print["   T_eq max numerator x-degree: ", Max[Exponent[Numerator[#], x] & /@ Flatten[Teq]],
     "  eps-degrees num max: ", Max[Exponent[Numerator[#], eps] & /@ Flatten[Teq]]];
   (* normalize scalar: divide by entry with smallest LeafCount that is nonzero *)
   ent = First[SortBy[Select[Tuples[Range[4], 2], Teq[[#[[1]], #[[2]]]] =!= 0 &], LeafCount[Teq[[#[[1]], #[[2]]]]] &]];
   TeqN = tog[Teq/Teq[[ent[[1]], ent[[2]]]]];
   Print["   normalized by entry ", ent, ": dens ", dens[TeqN], " LeafCount ", LeafCount[TeqN]];
   Print["   T_eq[[1,1]] = ", InputForm[Teq[[1, 1]]]];
   AppendTo[results, <|"Y0" -> y0, "Tslice" -> Tsl, "Teq" -> Teq, "TeqNorm" -> TeqN, "NormEntry" -> ent, "SliceGate" -> gate|>]],
  {f, files}];
putAtomic[results, out <> "/c77_slice_transformations.wl"];
Print[">>> saved c77_slice_transformations.wl"];
Print["DONE"];
