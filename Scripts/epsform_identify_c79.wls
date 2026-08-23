(* Class 79: identify the irreducible quadratic locus of the chart system.
   Chart (as used in balance_loop5): w -> -t (1 + t + v)/(1 + t), v spectator.
   Questions: (a) is lambda = (1-v-w)^2 - 4vw a perfect square in the chart? (b) which chart
   denominator factors are quadratic in t, and what are they in (v,w)?  (c) eps-dependent loci? *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w; t = Global`t;
tog[m_] := Map[Together, m, {2}];
dens[m_] := DeleteDuplicates[Flatten[First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ tog[m]]]];
cls = Get[R <> "/BlockClasses/classes.wl"];
e79 = SelectFirst[cls, #["ClassID"] == 79 &];
Av = e79["RepAv"]; Aw = e79["RepAw"];
Print["79: dim ", Dimensions[Av], " members ", Length[e79["Members"]], " family ", e79["RepFamily"], " rows ", e79["RepRows"]];
Print["79 (v,w)-loci Av: ", dens[Av]];
Print["79 (v,w)-loci Aw: ", dens[Aw]];
lam = (1 - v - w)^2 - 4 v w;  Q = (1 + v - w)^2 + 4 v w;
Print["Q = ", Expand[Q], "   lambda = ", Expand[lam]];
Print["79 loci that equal Q or lambda (up to sign): ",
  Select[Join[dens[Av], dens[Aw]], (Together[#/Q] === 1 || Together[#/Q] === -1 || Together[#/lam] === 1 || Together[#/lam] === -1) &]];
wt = -t (1 + t + v)/(1 + t);
Print["chart w(t) = ", wt, ";  Q(v,w(t)) = ", Factor[Q /. w -> wt], "   (perfect square? ",
  Module[{f = Factor[Q /. w -> wt]}, MatchQ[f, _^2 | Times[_?NumericQ, _^2] | _^2 Times[_?NumericQ] | (a_^2 b_^2 ...)] || Head[Sqrt[Factor[Q /. w -> wt]] // PowerExpand // Simplify] =!= Power], ")"];
Print["lambda(v,w(t)) = ", Factor[lam /. w -> wt]];
Print["  discriminant of lambda(v,w(t)) in t (as polynomial numerator): ",
  Module[{num = Numerator[Together[lam /. w -> wt]]}, Factor[Discriminant[num, t]]]];
(* chart t-connection: A_t = Aw . dw/dt (v fixed) *)
At = tog[(Aw /. w -> wt) D[wt, t]];
Print["chart t-loci (all denominator factors): ", dens[At]];
Print["  quadratic-in-t factors: ", Select[dens[At], Exponent[#, t] == 2 &]];
Print["  eps-dependent factors: ", Select[dens[At], ! FreeQ[#, eps] &]];
Print["  factors involving t: ", Select[dens[At], ! FreeQ[#, t] &]];
(* also the v-connection in the chart: A_v|_t = Av + Aw dw/dv *)
Avc = tog[(Av /. w -> wt) + (Aw /. w -> wt) D[wt, v]];
Print["chart v-loci: ", dens[Avc]];
Print["chart flat: ", AllTrue[Flatten[tog[D[At, v] - D[Avc, t] + At . Avc - Avc . At]], # === 0 &]];
(* which (v,w)-loci pull back to which t-factors *)
Do[Print["  ", InputForm[d], "  ->  ", InputForm[Factor[Numerator[Together[d /. w -> wt]]]]], {d, Join[dens[Av], dens[Aw]] // DeleteDuplicates}];
Print["DONE"];
