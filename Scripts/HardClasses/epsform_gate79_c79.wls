(* Class 79: clean the constant gauge U(y,eps), fix its scalar freedom,
   compose T = Ttot . U . c, and run the EXACT two-variable gate against the
   ORIGINAL chart system:
     T^-1 A_x T - T^-1 d_x T == eps Sum R_a d_x log phi_a,
     T^-1 A_y T - T^-1 d_y T == eps Sum R_a d_y log phi_a,
   with the SAME constant R_a and letters {x, y, 1-x, 1-y, x-y, 1-x-y, 2-x-y}.
   Chart: v = -x y, w = (1-x)(1-y).
   Template: Scripts/HardClasses/epsform_gate_c97_two_variable.wls.
   Arg 1 (optional): working directory (default: repository EpsFormRoute). *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = If[Length[$ScriptCommandLine] >= 2 && $ScriptCommandLine[[2]] =!= "", $ScriptCommandLine[[2]], Edir];
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
dens[m_] := DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[m]]]];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

sn = Get[out <> "/symnorm_c79.wl"]; An = sn["A"]; Tt = sn["Ttot"];
cg = Get[out <> "/c79_constant_gauge_symbolic.wl"]; U0 = cg["U"];
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 79 &];
Av = ent["RepAv"]; Aw = ent["RepAw"];
xx = Global`xx; sub = {v -> -xx y, w -> (1 - xx) (1 - y)};
Ax = tog[((Av /. sub) (-y) - (Aw /. sub) (1 - y)) /. xx -> x];
Ay = tog[((Av /. sub) (-x) - (Aw /. sub) (1 - x)) /. xx -> x];

(* ---- 1. clean U: strip the overall scalar (content) ---- *)
nums = Numerator /@ Flatten[tog[U0]]; dns = Denominator /@ Flatten[tog[U0]];
g = PolynomialGCD @@ nums; l = PolynomialLCM @@ dns;
U1 = tog[U0 l/g];
Print["U cleaned: LeafCount ", LeafCount[U0], " -> ", LeafCount[U1]];
Print["U1 denominators: ", InputForm[dens[U1]]];
Print["det U1: ", InputForm[Factor[Det[U1]]]];

(* ---- 2. x-direction: residues of U1^-1 A_norm U1 must be constant ---- *)
lociX = {1, 0, y, 1 - y, 2 - y};
resAt[Am_, x0_] := tog[Cancel[Together[(x - x0) Am]] /. x -> x0];
Ms = resAt[An, #] & /@ lociX;
U1i = tog[Inverse[U1]];
Rs = timed["x-residues R_a of U1^-1 A_norm U1 / eps are CONSTANT (eps- and y-free)",
  Module[{r = tog[U1i . # . U1/eps] & /@ Ms}, If[AllTrue[r, FreeQ[#, eps] && FreeQ[#, y] &], r, {"NOTCONST", r}]]];
If[! FreeQ[Rs, "NOTCONST"], Print["x-residues not constant; aborting"]; Exit[1]];
{R1, R0, Rxy, R1xy, R2xy} = Rs;  (* letters 1-x, x, x-y, 1-x-y, 2-x-y *)
Print["R_{1-x} = ", InputForm[R1]]; Print["R_x = ", InputForm[R0]];
Print["R_{x-y} = ", InputForm[Rxy]]; Print["R_{1-x-y} = ", InputForm[R1xy]];
Print["R_{2-x-y} = ", InputForm[R2xy]];
Print["eigenvalues: ", InputForm[Eigenvalues /@ Rs], "  ranks: ", MatrixRank /@ Rs];

(* ---- 3. y-direction with U1 (scalar gauge still free) ---- *)
Tti = tog[Inverse[Tt]];
Ayn = timed["A_y,norm built", tog[Tti . Ay . Tt - Tti . D[Tt, y]]];
AyP = timed["A_y' = U1^-1 A_y,norm U1 - U1^-1 dU1/dy built", tog[U1i . Ayn . U1 - U1i . D[U1, y]]];
pred = eps (Rxy D[Log[x - y], y] + R1xy D[Log[1 - x - y], y] + R2xy D[Log[2 - x - y], y]);
rest = tog[AyP - pred];
Print["A_y' minus predicted x-letter part is x-INDEPENDENT: ", FreeQ[rest, x]];
Print["  rest denominators: ", InputForm[dens[rest]]];
trPart = tog[Tr[rest]/4];
rest0 = tog[rest - trPart IdentityMatrix[4]];
Print["traceless part / eps eps-free: ", FreeQ[tog[rest0/eps], eps]];
yden0 = dens[tog[rest0/eps]];
Print["traceless part y-loci: ", InputForm[yden0]];
resY[Am_, p_] := Module[{yy = y /. First[Solve[p == 0, y]]}, tog[Cancel[Together[(y - yy) Am]] /. y -> yy]];
res0 = Table[{p, tog[resY[rest0, p]/eps]}, {p, Select[yden0, Exponent[#, y] == 1 &]}];
Do[Print["  traceless residue at ", InputForm[r[[1]]], " constant? ", FreeQ[r[[2]], eps] && FreeQ[r[[2]], y]], {r, res0}];
Print["  traceless part reconstructed exactly from its linear-locus residues: ",
  zeroM[tog[rest0/eps] - Sum[r[[2]] D[Log[r[[1]]], y], {r, res0}]]];
apT = Apart[trPart, y];
Print["trace/4 part, partial fractions in y: ", InputForm[apT]];
terms = If[Head[apT] === Plus, List @@ apT, {apT}];
Print["  polynomial-in-y part (must be 0): ", InputForm[Total[Select[terms, PolynomialQ[#, y] &]]]];
cFactors = {}; tRes = {};
Do[Module[{den = Denominator[Together[t]], qs, q, ratio, yy, resid, ipa, epa},
   qs = Select[First /@ Rest[FactorList[den]], ! FreeQ[#, y] &];
   If[Length[qs] =!= 1, Print["  unexpected pole term in trace part: ", InputForm[t]]; Continue[]];
   q = qs[[1]];
   ratio = Together[t q/D[q, y]];
   If[IntegerQ[ratio],
     Print["  gauge term: ", InputForm[t], " = ", ratio, " * dlog(", InputForm[q], ")"];
     AppendTo[cFactors, q^ratio]; Continue[]];
   If[Exponent[q, y] =!= 1 || Exponent[den, y] =!= 1,
     Print["  NON-SIMPLE / non-linear non-gauge pole term in trace part: ", InputForm[t]]; Continue[]];
   yy = y /. First[Solve[q == 0, y]];
   resid = tog[Cancel[Together[(y - yy) t]] /. y -> yy];
   ipa = tog[resid /. eps -> 0]; epa = tog[(resid - ipa)/eps];
   Print["  pole at y = ", InputForm[yy], ": residue ", InputForm[resid], " = int ", InputForm[ipa],
     " (integer? ", IntegerQ[ipa], ") + eps * ", InputForm[epa]];
   If[IntegerQ[ipa] && ipa =!= 0, AppendTo[cFactors, (y - yy)^ipa]];
   If[epa =!= 0, AppendTo[tRes, {y - yy, epa}]]],
  {t, Select[terms, ! PolynomialQ[#, y] &]}];
c = tog[Times @@ cFactors];
Print["scalar gauge c(y,eps) = ", InputForm[c]];
Print["trace-part eps-letters {locus, coefficient}: ", InputForm[tRes]];
lin1[p_] := Together[p/y] === 1 || Together[p/y] === -1;
lin2[p_] := Together[p/(1 - y)] === 1 || Together[p/(1 - y)] === -1;
Ry0 = 0 IdentityMatrix[4]; R1y0 = 0 IdentityMatrix[4]; extraY = {};
Do[Which[lin1[r[[1]]], Ry0 = tog[Ry0 + r[[2]]], lin2[r[[1]]], R1y0 = tog[R1y0 + r[[2]]], True, AppendTo[extraY, r]], {r, res0}];
Do[Which[lin1[r[[1]]], Ry0 = tog[Ry0 + r[[2]] IdentityMatrix[4]], lin2[r[[1]]], R1y0 = tog[R1y0 + r[[2]] IdentityMatrix[4]],
   True, AppendTo[extraY, r]], {r, tRes}];
Print["R_y = ", InputForm[Ry0]]; Print["R_{1-y} = ", InputForm[R1y0]];
Print["extra pure-y letters beyond y, 1-y (must be empty): ", InputForm[extraY]];
U2 = tog[U1 c];

(* ---- 4. THE GATE: original chart system through T = Ttot . U2 ---- *)
T = tog[Tt . U2]; Ti = tog[Inverse[T]];
AxG = timed["gate: A_x'' from ORIGINAL chart A_x built", tog[Ti . Ax . T - Ti . D[T, x]]];
AyG = timed["gate: A_y'' from ORIGINAL chart A_y built", tog[Ti . Ay . T - Ti . D[T, y]]];
letters = {x, y, 1 - x, 1 - y, x - y, 1 - x - y, 2 - x - y};
Rlet = {R0, Ry0, R1, R1y0, Rxy, R1xy, R2xy};
predX = eps Sum[Rlet[[a]] D[Log[letters[[a]]], x], {a, Length[letters]}];
predY = eps Sum[Rlet[[a]] D[Log[letters[[a]]], y], {a, Length[letters]}];
gx = timed["GATE x: A_x'' == eps Sum R_a dlog_x phi_a EXACTLY", zeroM[AxG - predX]];
gy = timed["GATE y: A_y'' == eps Sum R_a dlog_y phi_a EXACTLY", zeroM[AyG - predY]];
fl = timed["flatness of the eps-form", zeroM[D[predX, y] - D[predY, x] + predX . predY - predY . predX]];
Print["residue eigenvalues per letter: ", InputForm[Table[{letters[[a]], Eigenvalues[Rlet[[a]]]}, {a, Length[letters]}]]];
putAtomic[<|"Class" -> 79, "Chart" -> {v -> -x y, w -> (1 - x) (1 - y)}, "Variables" -> {x, y},
   "T" -> T, "Ttot" -> Tt, "U" -> U2, "Letters" -> letters, "Residues" -> Rlet,
   "Ax" -> AxG, "Ay" -> AyG, "GateX" -> gx, "GateY" -> gy, "Flat" -> fl,
   "Provenance" -> "Ttot: symnorm_c79.wl (Lee Fuchsify+normalize with y symbolic, Libra primitives); U: x-constant Lee factorization step by linear algebra (epsform_finish_c79_constant_gauge.wls) + scalar gauge fix; gate: epsform_gate_c79_two_variable.wls 2026-08-16"|>,
  out <> "/c79_epsform_two_variable.wl"];
Print[">>> saved c79_epsform_two_variable.wl   GateX=", gx, " GateY=", gy, " Flat=", fl];
Print["DONE"];
