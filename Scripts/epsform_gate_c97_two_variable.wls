(* Class 97: clean the constant gauge U(y,eps), fix its scalar freedom,
   compose T = Ttot . U, and run the EXACT two-variable gate against the
   ORIGINAL chart system:  T^-1 A_x T - T^-1 d_x T == eps Sum R_a d_x log phi_a,
   T^-1 A_y T - T^-1 d_y T == eps Sum R_a d_y log phi_a, with the SAME
   constant R_a and letters phi in {x, y, 1-x, 1-y, x-y, x+y, x+y-xy}.
   Reads only repository artifacts + the finisher output. *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
Edir = R <> "/HardClasses/EpsFormRoute";
out = Edir;   (* outputs live beside the evidence in Results/ *)
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];
timed[label_, body_] := Module[{t0 = AbsoluteTime[], r},
  r = body; Print["CHECK ", label, ": ", r, "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]; r];
SetAttributes[timed, HoldRest];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];

sn = Get[Edir <> "/symnorm_c97.wl"]; An = sn["A"]; Tt = sn["Ttot"];
cg = Get[out <> "/c97_constant_gauge_symbolic.wl"]; U0 = cg["U"];
cls = Get[R <> "/BlockClasses/classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 97 &];
Av = ent["RepAv"]; Aw = ent["RepAw"];
xx = Global`xx; sub = {v -> xx y, w -> (1 - xx) (1 - y)};
Ax = tog[((Av /. sub) y - (Aw /. sub) (1 - y)) /. xx -> x];
Ay = tog[((Av /. sub) x - (Aw /. sub) (1 - x)) /. xx -> x];

(* ---- 1. clean U: strip the overall scalar (content) ---- *)
nums = Numerator /@ Flatten[tog[U0]]; dens = Denominator /@ Flatten[tog[U0]];
g = PolynomialGCD @@ nums; l = PolynomialLCM @@ dens;
U1 = tog[U0 l / g];
Print["U cleaned: LeafCount ", LeafCount[U0], " -> ", LeafCount[U1]];
Print["U1 denominators: ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ U1]]]];
Print["U1 numerator content: ", Factor[PolynomialGCD @@ (Numerator /@ Flatten[U1])]];
Print["det U1: ", Factor[Det[U1]]];

(* ---- 2. x-direction: residues of U1^-1 A_norm U1 must be constant ---- *)
lociX = {1, 0, y, -y, y/(y - 1)};
resAt[Am_, x0_] := tog[Cancel[Together[(x - x0) Am]] /. x -> x0];
Ms = resAt[An, #] & /@ lociX;
U1i = tog[Inverse[U1]];
Rs = timed["x-residues R_a of U1^-1 A_norm U1 / eps are CONSTANT (eps- and y-free)",
  Module[{r = tog[U1i . # . U1/eps] & /@ Ms}, If[AllTrue[r, FreeQ[#, eps] && FreeQ[#, y] &], r, {"NOTCONST", r}]]];
If[! FreeQ[Rs, "NOTCONST"], Print["x-residues not constant; aborting"]; Exit[1]];
{R1, R0, Rxy, Rxpy, Rw} = Rs;   (* letters: x-1, x, x-y, x+y, x+y-xy  (x = y/(y-1) is the root of x+y-xy) *)
Print["R_{x-1} = ", InputForm[R1]]; Print["R_x = ", InputForm[R0]]; Print["R_{x-y} = ", InputForm[Rxy]];
Print["R_{x+y} = ", InputForm[Rxpy]]; Print["R_{x+y-xy} = ", InputForm[Rw]];
Print["eigenvalues: ", Eigenvalues /@ Rs, "  ranks: ", MatrixRank /@ Rs];

(* ---- 3. y-direction with U1 (scalar gauge still free) ---- *)
Tti = tog[Inverse[Tt]];
Ayn = timed["A_y,norm built", tog[Tti . Ay . Tt - Tti . D[Tt, y]]];
AyP = timed["A_y' = U1^-1 A_y,norm U1 - U1^-1 dU1/dy built", tog[U1i . Ayn . U1 - U1i . D[U1, y]]];
(* subtract the y-derivative part of the x-dependent letters (same constant residues) *)
pred = eps (Rxy D[Log[x - y], y] + Rxpy D[Log[x + y], y] + Rw D[Log[x + y - x y], y]);
rest = tog[AyP - pred];
Print["A_y' minus predicted x-letter part is x-INDEPENDENT: ", FreeQ[rest, x]];
Print["  rest denominators: ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ rest]]]];
(* rest = eps * Sum_b R_b d_y log psi_b(y)  +  s(y,eps) * Identity,   s = d_y log c, c rational.
   Traceless part is free of s; trace part carries s plus the identity components of the R_b. *)
trPart = tog[Tr[rest]/4];
rest0 = tog[rest - trPart IdentityMatrix[4]];
Print["traceless part / eps eps-free: ", FreeQ[tog[rest0/eps], eps]];
yden0 = DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[rest0/eps]]]];
Print["traceless part y-loci: ", yden0];
resY[Am_, p_] := Module[{y0 = y /. First[Solve[p == 0, y]]}, tog[Cancel[Together[(y - y0) Am]] /. y -> y0]];
res0 = Table[{p, tog[resY[rest0, p]/eps]}, {p, Select[yden0, Exponent[#, y] == 1 &]}];
Do[Print["  traceless residue at ", InputForm[r[[1]]], " constant? ", FreeQ[r[[2]], eps] && FreeQ[r[[2]], y]], {r, res0}];
Print["  traceless part reconstructed exactly from its linear-locus residues: ",
  zeroM[tog[rest0/eps] - Sum[r[[2]] D[Log[r[[1]]], y], {r, res0}]]];
(* trace part: partial fractions in y; each simple pole n(eps)/(y-y0): integer part -> scalar gauge, eps part -> letter *)
apT = Apart[trPart, y];
Print["trace/4 part, partial fractions in y: ", InputForm[apT]];
terms = If[Head[apT] === Plus, List @@ apT, {apT}];
Print["  polynomial-in-y part (must be 0): ", InputForm[Total[Select[terms, PolynomialQ[#, y] &]]]];
cFactors = {}; tRes = {};
Do[Module[{den = Denominator[Together[t]], qs, q, ratio, y0, resid, ipart, epart},
   qs = Select[First /@ Rest[FactorList[den]], ! FreeQ[#, y] &];
   If[Length[qs] =!= 1, Print["  unexpected pole term in trace part: ", InputForm[t]]; Continue[]];
   q = qs[[1]];
   (* pure gauge term?  t == n * d_y log q with integer n *)
   ratio = Together[t q/D[q, y]];
   If[IntegerQ[ratio],
     Print["  gauge term: ", InputForm[t], " = ", ratio, " * dlog(", InputForm[q], ")"];
     AppendTo[cFactors, q^ratio]; Continue[]];
   If[Exponent[q, y] =!= 1 || Exponent[den, y] =!= 1,
     Print["  NON-SIMPLE / non-linear non-gauge pole term in trace part (eps-form would fail): ", InputForm[t]]; Continue[]];
   y0 = y /. First[Solve[q == 0, y]];
   resid = tog[Cancel[Together[(y - y0) t]] /. y -> y0];
   ipart = tog[resid /. eps -> 0]; epart = tog[(resid - ipart)/eps];
   Print["  pole at y = ", InputForm[y0], ": residue ", InputForm[resid], " = int ", InputForm[ipart],
     " (integer? ", IntegerQ[ipart], ") + eps * ", InputForm[epart]];
   If[IntegerQ[ipart] && ipart =!= 0, AppendTo[cFactors, (y - y0)^ipart]];
   If[epart =!= 0, AppendTo[tRes, {y - y0, epart}]]],
  {t, Select[terms, ! PolynomialQ[#, y] &]}];
c = tog[Times @@ cFactors];
Print["scalar gauge c(y,eps) = ", InputForm[c]];
Print["trace-part eps-letters {locus, coefficient}: ", InputForm[tRes]];
(* constant residues for the pure-y letters.  Convention: rest contains eps R_y dlog(y) + eps R_{1-y} dlog(1-y);
   dlog(1-y) = -1/(1-y) = 1/(y-1)  =>  residue of rest at y=1 is +eps R_{1-y}; at y=0 it is +eps R_y. *)
lin1[p_] := Together[p/y] === 1 || Together[p/y] === -1;             (* locus y = 0 *)
lin2[p_] := Together[p/(1 - y)] === 1 || Together[p/(1 - y)] === -1; (* locus y = 1 *)
Ry0 = 0 IdentityMatrix[4]; R1y0 = 0 IdentityMatrix[4]; extraY = {};
Do[Which[lin1[r[[1]]], Ry0 = tog[Ry0 + r[[2]]], lin2[r[[1]]], R1y0 = tog[R1y0 + r[[2]]], True, AppendTo[extraY, r]], {r, res0}];
Do[Which[lin1[r[[1]]], Ry0 = tog[Ry0 + r[[2]] IdentityMatrix[4]], lin2[r[[1]]], R1y0 = tog[R1y0 + r[[2]] IdentityMatrix[4]],
   True, AppendTo[extraY, r]], {r, tRes}];
Print["R_y = ", InputForm[Ry0]]; Print["R_{1-y} = ", InputForm[R1y0]];
Print["extra pure-y letters beyond y, 1-y (must be empty): ", InputForm[extraY]];
U2 = tog[U1 c];
Ry = tog[eps Ry0]; R1y = tog[eps R1y0];
(* ---- 4. THE GATE: original chart system through T = Ttot . U2 ---- *)
T = tog[Tt . U2]; Ti = tog[Inverse[T]];
AxG = timed["gate: A_x'' from ORIGINAL chart A_x built", tog[Ti . Ax . T - Ti . D[T, x]]];
AyG = timed["gate: A_y'' from ORIGINAL chart A_y built", tog[Ti . Ay . T - Ti . D[T, y]]];
letters = {x, y, 1 - x, 1 - y, x - y, x + y, x + y - x y};
Rlet = {R0, tog[Ry/eps], R1, tog[R1y/eps], Rxy, Rxpy, Rw};
predX = eps Sum[Rlet[[a]] D[Log[letters[[a]]], x], {a, 7}];
predY = eps Sum[Rlet[[a]] D[Log[letters[[a]]], y], {a, 7}];
gx = timed["GATE x: A_x'' == eps Sum R_a dlog_x phi_a EXACTLY", zeroM[AxG - predX]];
gy = timed["GATE y: A_y'' == eps Sum R_a dlog_y phi_a EXACTLY", zeroM[AyG - predY]];
Print["R_{1-x} sign convention note: R1 above is the residue at x=1 of A/(x-1); dlog(1-x) has the same residue -> consistent."];
Print["flatness of the eps-form (must hold): ", zeroM[D[predX, y] - D[predY, x] + predX . predY - predY . predX]];
putAtomic[<|"Class" -> 97, "Chart" -> {v -> x y, w -> (1 - x) (1 - y)}, "Variables" -> {x, y},
   "T" -> T, "Ttot" -> Tt, "U" -> U2, "Letters" -> letters, "Residues" -> Rlet,
   "Ax" -> AxG, "Ay" -> AyG, "GateX" -> gx, "GateY" -> gy,
   "Provenance" -> "Ttot: symnorm_c97.wl (symbolic replay of the balance path); U: x-constant Lee factorization step by linear algebra (finish_c97_constant_gauge.wls) + scalar gauge fix; gate: gate_c97_two_variable.wls 2026-08-16"|>,
  out <> "/c97_epsform_two_variable.wl"];
Print[">>> saved c97_epsform_two_variable.wl   GateX=", gx, " GateY=", gy];
Print["DONE"];
