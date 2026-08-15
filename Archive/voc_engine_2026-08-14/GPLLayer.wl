(* ::Package:: *)

(* GPLLayer.wl -- closed shuffle-algebra quadrature layer for the VoC engine.

   Representation
   --------------
   G[{a1,...,an}, x]   Goncharov polylogarithm, indices a_k constant in x
                       (they may depend on the external kinematics v,w).
       G[{}, x]      = 1
       G[{a,rest},x] = Int_0^x dt/(t-a) G[rest,t]
       G[{0,..,0},x] = Log[x]^n/n!            (shuffle-regularised convention)

   The whole point: every path quadrature of the engine has the form
       Sum_i r_i(tau) F_i(tau),   r_i rational in tau,  F_i in the G-span,
   and this file provides a COMPLETE decision procedure producing the
   primitive in the same span.  No call to Integrate anywhere.

   Conventions: no BeginPackage (matching VoCEngine.wl) -- everything lands
   in Global`.  NEVER load PolyLogTools into a kernel that loads this file:
   it defines its own G.  (Also note Global`D: data files that carry the
   spacetime dimension D shadow System`D once loaded.  This file is parsed
   first, so its D is bound to System`D -- keep it that way.)

   ------------------------------------------------------------------
   VERIFICATION CONTRACT (what "verified" means for this layer)
   ------------------------------------------------------------------
   Distinct G-words are linearly independent over the field of rational
   functions.  After shuffle-normalisation an expression therefore vanishes
   IFF each collected word-coefficient vanishes, and each coefficient is a
   rational function whose vanishing Together decides exactly.  So GPLZeroQ
   is a decision procedure, and the checks below return EXACT symbolic
   zeros -- no Simplify-with-timeout, no numeric probe.

   Two independent exact checks are run by the engine:
     (i)  per quadrature:  d/dtau F_{s,k} - source_{s,k} == 0
     (ii) assembled:       d/dtau I_n - (Ahat . I)_n == 0   vs the ORIGINAL
          family DE, with the integration constants still symbolic.

   We do NOT check the DE in the (v,w) frame, and do not need to.  That
   check would require the Goncharov parameter differential of
   G[{a(v,w),...},1], which this layer does not implement; VoCCheckDEvw
   reports NeedsParamDeriv rather than a meaningless zero.  The path frame
   is already complete, by uniqueness along rays:

       Let K be the unique solution of the full flat system with K(x0)=c.
       Along the ray P(tau) = x0 + tau (x - x0), K(P(tau)) satisfies the
       same linear ODE in tau as the engine's I(tau), with the same value
       at tau=0.  By uniqueness for linear ODEs, I(tau;v,w) = K(P(tau;v,w));
       hence at tau=1 the engine's answer IS the solution of the full (v,w)
       system.  The one extra ingredient -- integrability of the connection
       -- is exactly what the assembly certificate verifies independently
       (FlatnessOriginal, FlatnessConjugated).

   Therefore: path-frame exact zeros + flatness certificate  =>  the full
   DE, with no numerics anywhere in the argument.

   ------------------------------------------------------------------
   ENDPOINT SWELL WARNING
   ------------------------------------------------------------------
   With a SYMBOLIC endpoint (v,w) the G-indices are rational FUNCTIONS of
   the kinematics, and the partial-fraction coefficients (differences of
   those roots) swell fast with the eps order: measured on NLO, leaf counts
   per sector ran 90 -> 1935 -> 16465 -> ~50000 for eps^-1..eps^2, and the
   per-order cost tracked that swell, not the weight.  The integration
   primitive is NOT the bottleneck (it is ms-scale; see gpl_selftest.log).
   Production gates therefore use NUMERIC RATIONAL endpoints, where the
   indices are rational numbers and the swell does not arise.  The symbolic
   endpoint remains available as an optional mode for the general answer.
*)

If[!ValueQ[GPLVerbose], GPLVerbose = False];

GPLLog[args___] := If[TrueQ[GPLVerbose],
   WriteString["stdout", "[GPL] " <> StringJoin[ToString /@ {args}] <> "\n"]];

(* the layer records every assertion it could not discharge here *)
GPLFailures = {};
GPLFail[tag_, data_] := (AppendTo[GPLFailures, {tag, data}];
   GPLLog["FAILURE ", tag, " ", ToString[Short[data, 3], InputForm]]; $Failed);

(* ------------------------------------------------------------------ *)
(* 0.  index / word normalisation                                      *)
(* ------------------------------------------------------------------ *)

ClearAll[G];
G[{}, _] := 1;

(* canonical form for an index: rational functions of the kinematics get a
   unique normal form, so equal indices are structurally equal *)
GPLIdx[a_] := Cancel[Together[a]];
GPLWord[w_List] := GPLIdx /@ w;

GPLSameIdxQ[a_, b_] := TrueQ[a === b] || Together[a - b] === 0 ||
   (!FreeQ[{a, b}, Sqrt | Root] && TrueQ[Quiet[RootReduce[a - b] === 0]]);

GPLWeight[G[w_List, _]] := Length[w];

(* ------------------------------------------------------------------ *)
(* 1.  shuffle product                                                 *)
(* ------------------------------------------------------------------ *)

GPLShuffle[{}, b_List] := {b};
GPLShuffle[a_List, {}] := {a};
GPLShuffle[a_List, b_List] := Join[
   Prepend[#, First[a]] & /@ GPLShuffle[Rest[a], b],
   Prepend[#, First[b]] & /@ GPLShuffle[a, Rest[b]]];

(* reduce every product/power of G's at the SAME argument to a linear
   combination of G's (this is what keeps the basis linear) *)
GPLShuffleNormal[e_] := Module[{p = Expand[e], q, guard = 0},
  While[guard++ < 40,
   q = Expand[p /. {
      G[u_List, x_]^n_Integer /; n >= 2 :>
         G[u, x]^(n - 2) Total[G[#, x] & /@ GPLShuffle[u, u]],
      HoldPattern[Times[aa___, G[u_List, x_], bb___, G[ww_List, x_], cc___]] :>
         Times[aa, bb, cc] Total[G[#, x] & /@ GPLShuffle[u, ww]]}];
   If[q === p, Break[]];
   p = q];
  p];

(* ------------------------------------------------------------------ *)
(* 2.  canonical linear form  { {coef, word}, ... }                     *)
(* ------------------------------------------------------------------ *)

GPLTermList[e_, x_] := Module[{s, terms},
  s = Expand[GPLShuffleNormal[e]];
  terms = If[Head[s] === Plus, List @@ s, {s}];
  Catch[
   Map[Function[tm,
     Module[{fs, gg, rest},
      fs = If[Head[tm] === Times, List @@ tm, {tm}];
      gg = Cases[fs, _G];
      rest = Times @@ DeleteCases[fs, _G];
      Which[
       Length[gg] > 1, Throw[GPLFail["shuffle-normalisation-incomplete", tm], "gplT"],
       !FreeQ[rest, G], Throw[GPLFail["G-in-coefficient", tm], "gplT"],
       gg === {}, {rest, {}},
       gg[[1, 2]] =!= x, Throw[GPLFail["G-at-foreign-argument", tm], "gplT"],
       True, {rest, GPLWord[gg[[1, 1]]]}]]], terms],
   "gplT"]];

(* association  word -> coefficient  (coefficients Together'd) *)
GPLCollect[e_, x_] := Module[{tl = GPLTermList[e, x]},
  If[tl === $Failed, $Failed,
   GroupBy[tl, #[[2]] &, Together[Total[#[[All, 1]]]] &]]];

GPLFromCollect[as_Association, x_] :=
  Total[KeyValueMap[#2 G[#1, x] &, as]];

(* exact zero test: linear independence of distinct words over the field of
   rational functions makes this a decision procedure *)
GPLZeroQ[e_, x_] := Module[{c = GPLCollect[e, x]},
  If[c === $Failed, False, AllTrue[Values[c], Together[#] === 0 &]]];

GPLResidual[e_, x_] := Module[{c = GPLCollect[e, x]},
  If[c === $Failed, $Failed, DeleteCases[Together /@ c, 0]]];

(* ------------------------------------------------------------------ *)
(* 3.  derivative in the path variable                                  *)
(* ------------------------------------------------------------------ *)

GPLDeriv[e_, x_] := Module[{tl = GPLTermList[e, x]},
  If[tl === $Failed, Return[$Failed]];
  Total[Map[Function[tm,
     Module[{c = tm[[1]], w = tm[[2]]},
      D[c, x] G[w, x] +
       If[w === {}, 0, c G[Rest[w], x]/(x - First[w])]]], tl]]];

(* ------------------------------------------------------------------ *)
(* 4.  partial fractions in x with symbolic parameters                  *)
(* ------------------------------------------------------------------ *)

(* roots of an irreducible-over-Q(params) factor, linear or quadratic *)
GPLFactorRoots[p_, x_] := Module[{d = Exponent[p, x], a2, a1, a0, disc, sol},
  Which[
   d === 1, With[{c = Coefficient[p, x, 1]},
     {c, {GPLIdx[-Coefficient[p, x, 0]/c]}}],
   d === 2,
   a2 = Coefficient[p, x, 2]; a1 = Coefficient[p, x, 1]; a0 = Coefficient[p, x, 0];
   disc = Together[a1^2 - 4 a2 a0];
   {a2, {GPLIdx[(-a1 + Sqrt[disc])/(2 a2)], GPLIdx[(-a1 - Sqrt[disc])/(2 a2)]}},
   True,
   sol = Quiet[Solve[p == 0, x]];
   If[Head[sol] === List && Length[sol] === d,
    {Coefficient[p, x, d], GPLIdx[x /. #] & /@ sol},
    GPLFail["unfactorable-denominator", p]]]];

GPLMergeRoots[rs_] := Module[{out = {}},
  Do[Module[{r = rs[[i]], pos},
    pos = Catch[Do[If[GPLSameIdxQ[out[[j, 1]], r[[1]]], Throw[j, "gplM"]],
        {j, Length[out]}]; None, "gplM"];
    If[pos === None, AppendTo[out, r], out[[pos, 2]] += r[[2]]]],
   {i, Length[rs]}];
  out];

(* {leadcoef, {{root, multiplicity}, ...}} *)
GPLDenRoots[den_, x_] := Module[{fl = FactorList[Expand[den]], lead = 1, roots = {}, bad = False},
  Do[Module[{f = fl[[i, 1]], k = fl[[i, 2]], rr},
    If[FreeQ[f, x],
     lead *= f^k,
     rr = GPLFactorRoots[f, x];
     If[rr === $Failed, bad = True,
      lead *= rr[[1]]^k;
      roots = Join[roots, ({#, k} & /@ rr[[2]])]]]],
   {i, Length[fl]}];
  If[bad, $Failed, {lead, GPLMergeRoots[roots]}]];

(* r(x) = Poly(x) + Sum  c/(x-a)^k   -- exact, parameters symbolic *)
If[!ValueQ[GPLPFracCache], GPLPFracCache = <||>];
GPLPFrac[r0_, x_] := Module[{key = {r0, x}, val},
  val = Lookup[GPLPFracCache, Key[key], Missing[]];
  If[!MissingQ[val], Return[val]];
  val = GPLPFracRaw[r0, x];
  AssociateTo[GPLPFracCache, key -> val];
  val];

GPLPFracRaw[r0_, x_] := Module[
  {r, num, den, quo, rem, dr, lead, roots, poles = {}},
  r = Together[Cancel[r0]];
  If[FreeQ[r, x], Return[<|"Poly" -> r, "Poles" -> {}|>]];
  num = Numerator[r]; den = Denominator[r];
  If[!PolynomialQ[num, x] || !PolynomialQ[den, x],
   Return[GPLFail["non-rational-coefficient", r0]]];
  If[FreeQ[den, x],
   Return[<|"Poly" -> Expand[Cancel[num/den]], "Poles" -> {}|>]];
  quo = Cancel[Together[PolynomialQuotient[num, den, x]]];
  rem = Expand[PolynomialRemainder[num, den, x]];
  dr = GPLDenRoots[den, x];
  If[dr === $Failed, Return[$Failed]];
  {lead, roots} = dr;
  If[rem =!= 0,
   Do[Module[{a = roots[[i, 1]], m = roots[[i, 2]], h},
     (* h regular at a: the (x-a)^m factor is simply omitted, never cancelled *)
     h = Together[rem/(lead Product[
          If[j === i, 1, (x - roots[[j, 1]])^roots[[j, 2]]], {j, Length[roots]}])];
     Do[AppendTo[poles, {a, m - tt, Together[(h /. x -> a)/tt!]}];
        If[tt < m - 1, h = D[h, x]],
      {tt, 0, m - 1}]],
    {i, Length[roots]}]];
  <|"Poly" -> quo, "Poles" -> DeleteCases[poles, {_, _, 0}]|>];

(* ------------------------------------------------------------------ *)
(* 5.  THE INTEGRATION PRIMITIVES                                       *)
(* ------------------------------------------------------------------ *)

(* Int x^m G[w,x] dx  -- integration by parts, weight strictly decreases *)
If[!ValueQ[GPLIntCache], GPLIntCache = <||>];

GPLIntMonG[m_Integer, w_List, x_] := Module[{key = {"mon", m, w, x}, val},
  val = Lookup[GPLIntCache, Key[key], Missing[]];
  If[!MissingQ[val], Return[val]];
  val = Module[{inner},
    If[w === {}, x^(m + 1)/(m + 1),
     inner = GPLIntRatG[x^(m + 1)/((m + 1) (x - First[w])), Rest[w], x];
     If[inner === $Failed, $Failed, x^(m + 1)/(m + 1) G[w, x] - inner]]];
  AssociateTo[GPLIntCache, key -> val];
  val];

(* Int G[w,x]/(x-a)^k dx *)
GPLIntPole[a_, k_Integer, w_List, x_] := Module[{key = {"pole", a, k, w, x}, val},
  If[k === 1, Return[G[Prepend[w, a], x]]];          (* depth extension *)
  val = Lookup[GPLIntCache, Key[key], Missing[]];
  If[!MissingQ[val], Return[val]];
  val = Module[{inner},
    If[w === {}, -1/((k - 1) (x - a)^(k - 1)),
     inner = GPLIntRatG[1/((k - 1) (x - First[w]) (x - a)^(k - 1)), Rest[w], x];
     If[inner === $Failed, $Failed,
      -G[w, x]/((k - 1) (x - a)^(k - 1)) + inner]]];
  AssociateTo[GPLIntCache, key -> val];
  val];

(* Int r(x) G[w,x] dx for rational r -- the complete procedure *)
GPLIntRatG[r_, w_List, x_] := Module[{pf = GPLPFrac[r, x], acc = 0, pl, bad = False},
  If[pf === $Failed, Return[$Failed]];
  pl = CoefficientList[Expand[pf["Poly"]], x];
  Do[If[pl[[m + 1]] =!= 0,
    Module[{u = GPLIntMonG[m, w, x]},
     If[u === $Failed, bad = True, acc += pl[[m + 1]] u]]],
   {m, 0, Length[pl] - 1}];
  Do[Module[{a = pf["Poles"][[i, 1]], k = pf["Poles"][[i, 2]],
             c = pf["Poles"][[i, 3]], u},
    u = GPLIntPole[a, k, w, x];
    If[u === $Failed, bad = True, acc += c u]],
   {i, Length[pf["Poles"]]}];
  If[bad, $Failed, acc]];

(* primitive of a whole GPL expression *)
GPLPrimitive[e_, x_] := Module[{cl = GPLCollect[e, x], acc = 0, bad = False},
  If[cl === $Failed, Return[$Failed]];
  Do[Module[{w = k, c = Lookup[cl, Key[k]], u},
    If[Together[c] =!= 0,
     u = GPLIntRatG[c, w, x];
     If[u === $Failed, bad = True, acc += u]]],
   {k, Keys[cl]}];
  If[bad, $Failed, acc]];

(* ------------------------------------------------------------------ *)
(* 6.  behaviour at x -> 0 and the regularised definite integral        *)
(* ------------------------------------------------------------------ *)

(* antiderivative of x^n Log[x]^m as {coef, power, logpower} triples *)
GPLIntMono[n_Integer, m_Integer] := GPLIntMono[n, m] =
  If[n === -1,
   {{1/(m + 1), 0, m + 1}},
   Table[{(-1)^i m!/(m - i)!/(n + 1)^(i + 1), n + 1, m - i}, {i, 0, m}]];

GPLSerCollect[terms_] := Module[{gb},
  If[terms === {}, Return[{}]];
  gb = GroupBy[terms, {#[[2]], #[[3]]} &, Together[Total[#[[All, 1]]]] &];
  DeleteCases[KeyValueMap[{#2, #1[[1]], #1[[2]]} &, gb], {0, _, _}]];

(* expansion of G[w,x] at x=0:  Sum coef x^n Log[x]^m, truncated at n<=ord *)
If[!ValueQ[GPLSeriesCache], GPLSeriesCache = <||>];

GPLSeries0[{}, ord_Integer] := {{1, 0, 0}};
GPLSeries0[w_List, ord_Integer] := Module[{key = {w, ord}, val},
  val = Lookup[GPLSeriesCache, Key[key], Missing[]];
  If[!MissingQ[val], Return[val]];
  val = GPLSeries0Raw[w, ord];
  AssociateTo[GPLSeriesCache, key -> val];
  val];

GPLSeries0Raw[w_List, ord_Integer] := Module[{a, tail, out},
  If[w === {}, Return[{{1, 0, 0}}]];
  a = First[w];
  tail = GPLSeries0[Rest[w], ord];
  If[a === 0 || Together[a] === 0,
   out = Flatten[Table[Module[{c = s[[1]], n = s[[2]], m = s[[3]]},
       {c #[[1]], #[[2]], #[[3]]} & /@ GPLIntMono[n - 1, m]], {s, tail}], 1],
   out = Flatten[Table[Module[{c = s[[1]], n = s[[2]], m = s[[3]]},
       Flatten[Table[
         {-c #[[1]]/a^(j + 1), #[[2]], #[[3]]} & /@ GPLIntMono[n + j, m],
         {j, 0, ord - n - 1}], 1]], {s, tail}], 1]];
  GPLSerCollect[Select[out, #[[2]] <= ord &]]];

(* Taylor coefficients t_0..t_ord of  num/den  at x=0, den(0) != 0 *)
GPLTaylorCoeffs[nl0_, dl0_, ord_] := Module[{nl, dl, t},
  nl = PadRight[nl0, ord + 1, 0];
  dl = PadRight[dl0, ord + 1, 0];
  If[Together[dl[[1]]] === 0, Return[$Failed]];
  t = ConstantArray[0, ord + 1];
  Do[t[[j + 1]] = Together[(nl[[j + 1]] -
      Sum[dl[[i + 1]] t[[j - i + 1]], {i, 1, j}])/dl[[1]]], {j, 0, ord}];
  t];

(* Laurent data of a rational c at x=0.
   Returns {pmax, co} with pmax = Max[poleorder,0] and
   co[[j]] = coefficient of x^(j-1-pmax), j = 1 .. ord+pmax+1. *)
GPLLaurent0[c_, x_, ord_] := Module[{cc, num, den, nl, dl, pn, pd, p, pmax, t, co},
  cc = Together[Cancel[c]];
  If[FreeQ[cc, x], Return[{0, Join[{cc}, ConstantArray[0, ord]]}]];
  num = Numerator[cc]; den = Denominator[cc];
  If[!PolynomialQ[num, x] || !PolynomialQ[den, x],
   Return[GPLFail["non-rational-coefficient", c]]];
  nl = CoefficientList[Expand[num], x];
  dl = CoefficientList[Expand[den], x];
  pn = LengthWhile[nl, Together[#] === 0 &];
  pd = LengthWhile[dl, Together[#] === 0 &];
  nl = Drop[nl, pn]; dl = Drop[dl, pd];
  p = pd - pn;                                   (* c = x^-p * (nl/dl) *)
  pmax = Max[p, 0];
  t = GPLTaylorCoeffs[nl, dl, ord + pmax];
  If[t === $Failed, Return[GPLFail["laurent-failed", c]]];
  co = Table[If[n + p >= 0 && n + p + 1 <= Length[t], t[[n + p + 1]], 0],
     {n, -pmax, ord}];
  {pmax, co}];

(* regularised limit x -> 0 of a GPL expression.
   Asserts that all 1/x^k and all Log[x]^m pieces cancel; returns $Failed
   (recorded in GPLFailures) rather than silently dropping them. *)
GPLLimit0[e_, x_] := Module[{cl = GPLCollect[e, x], acc = <||>, bad = False, fin = 0, div},
  If[cl === $Failed, Return[$Failed]];
  Do[Module[{w = k, c = Lookup[cl, Key[k]], lp, tc, ser, pmax},
    If[Together[c] =!= 0,
     lp = GPLLaurent0[c, x, 0];
     If[lp === $Failed, bad = True,
      pmax = lp[[1]]; tc = lp[[2]];
      ser = GPLSeries0[w, pmax];
      Do[Module[{n = nn, cn = tc[[nn + pmax + 1]]},
        If[Together[cn] =!= 0,
         Do[Module[{q = n + ser[[j, 2]], mm = ser[[j, 3]], cf},
           If[q <= 0,
            cf = Together[cn ser[[j, 1]]];
            acc = Append[acc, {q, mm} -> Lookup[acc, Key[{q, mm}], 0] + cf]]],
          {j, Length[ser]}]]],
       {nn, -pmax, 0}]]]],
   {k, Keys[cl]}];
  If[bad, Return[$Failed]];
  div = Select[KeyValueMap[{#1, Together[#2]} &, acc],
     (#[[1]] =!= {0, 0} && #[[2]] =!= 0) &];
  If[div =!= {},
   Return[GPLFail["divergent-limit-at-0", div]]];
  fin = Together[Lookup[acc, Key[{0, 0}], 0]];
  fin];

(* THE quadrature the engine calls:  Int_0^x e(sigma) dsigma *)
GPLDefInt[e_, x_] := Module[{prim, lim},
  If[Together[e] === 0, Return[0]];
  prim = GPLPrimitive[e, x];
  If[prim === $Failed, Return[$Failed]];
  lim = GPLLimit0[prim, x];
  If[lim === $Failed, Return[$Failed]];
  If[Together[lim] === 0, prim, prim - lim]];

(* value at a regular endpoint (checks the letters do not pinch it) *)
GPLAtPoint[e_, x_, val_] := Module[{cl = GPLCollect[e, x], bad = {}, out},
  If[cl === $Failed, Return[$Failed]];
  Do[Module[{w = k, c = Lookup[cl, Key[k]], den},
    den = Denominator[Together[Cancel[c]]];
    If[!FreeQ[den, x] && Together[den /. x -> val] === 0,
     AppendTo[bad, {"coefficient-pole", k}]];
    If[w =!= {} && GPLSameIdxQ[First[w], val],
     AppendTo[bad, {"leading-index-hits-endpoint", k}]]],
   {k, Keys[cl]}];
  If[bad =!= {}, Return[GPLFail["endpoint-singular", bad]]];
  out = Total[KeyValueMap[Together[#2 /. x -> val] G[#1, val] &, cl]];
  out];

(* ------------------------------------------------------------------ *)
(* 7.  numerics                                                        *)
(* ------------------------------------------------------------------ *)

(* ---- deterministic Taylor stepper for the chain (primary evaluator) ----

   g_i(t) = G[{a_i,...,a_n}, t] satisfies  g_i' = g_{i+1}/(t - a_i), g_{n+1}=1.
   Around t, with d_i = t - a_i,  1/(d_i+h) = (1/d_i) Sum_p (-h/d_i)^p, so
       (m+1) c_{i,m+1} = Sum_{p=0..m} c_{i+1,m-p} (-1)^p / d_i^(p+1).
   Stepping with h = theta*min_i|d_i| makes the truncation error theta^ord,
   which we control exactly -- unlike an adaptive ODE solver, which can stop
   short and hand back a silently extrapolated value.                        *)

GPLChainStep[w_List, t_, gv_List, h_, ord_Integer] := Module[
  {n = Length[w], c, d, u, cn, hp},
  c = ConstantArray[0, {n + 1, ord + 1}];
  c[[n + 1, 1]] = 1;
  Do[
   d = t - w[[i]];
   u = Table[(-1)^p/d^(p + 1), {p, 0, ord - 1}];   (* fixed convolution kernel *)
   cn = c[[i + 1]];
   c[[i, 1]] = gv[[i]];
   (* Dot is far faster than Sum on high-precision vectors *)
   Do[c[[i, m + 2]] = (Take[cn, m + 1] . Reverse[Take[u, m + 1]])/(m + 1),
    {m, 0, ord - 1}],
   {i, n, 1, -1}];
  hp = h^Range[0, ord];
  Table[c[[i]] . hp, {i, n}]];

GPLChainValue[w_List, t0_, gv0_List, y_, wp_] := Module[
  {t = t0, gv = gv0, dmin, h, ord, theta = 1/4, guard = 0, eps0},
  ord = Ceiling[(wp + 10)/Log10[1/theta]] + 5;
  eps0 = Abs[y] 10^(-wp);
  While[t < y - eps0 && guard++ < 20000,
   dmin = Min[Abs[t - #] & /@ w];
   If[!(dmin > 0), Return[$Failed]];
   h = Min[theta dmin, y - t];
   If[!(h > eps0), Break[]];
   gv = GPLChainStep[w, t, gv, h, ord];
   t = t + h];
  If[t < y - Abs[y] 10^(-wp + 5), $Failed, First[gv]]];

(* series evaluation of G[w,y] (valid for |y| well inside min|a_i|) *)
GPLSeriesValue[w_List, y_, ord_Integer, prec_] := Module[{ser},
  ser = GPLSeries0[w, ord];
  Total[Table[SetPrecision[ser[[j, 1]], prec] y^ser[[j, 2]] Log[y]^ser[[j, 3]],
    {j, Length[ser]}]]];

(* high-precision value of G[w,y] by the recursive definition, solved as the
   triangular ODE chain  d/dt G[w_i,t] = G[w_{i+1},t]/(t-a_i)  with initial
   conditions supplied by the exact expansion at a small t0. *)
(* Hoelder convolution at p=2, for G(w;1) whose word touches the endpoint:
     G(a_1..a_n;1) = Sum_j (-1)^j G(1-a_j,..,1-a_1; 1/2) G(a_{j+1}..a_n; 1/2)
   Requires a_1 != 1 and a_n != 0.  Every sub-evaluation sits at 1/2, where
   an index equal to 1 is safely off the segment. *)
GPLHolder2[w_List, prec_] := Module[{n = Length[w], half},
  half = SetPrecision[1/2, prec + 25];
  Total[Table[
    (-1)^j GPLNValue[Reverse[1 - Take[w, j]], half, "Precision" -> prec, "Holder" -> False]*
           GPLNValue[Drop[w, j], half, "Precision" -> prec, "Holder" -> False],
    {j, 0, n}]]];

If[!ValueQ[GPLNCache], GPLNCache = <||>];

Options[GPLNValue] = {"Precision" -> 40, "Ratio" -> 100, "StartOrder" -> Automatic,
   "Holder" -> True};
GPLNValue[w0_List, y0_, opts : OptionsPattern[]] := Module[{key, val},
  key = {w0, y0, OptionValue["Precision"], OptionValue["Holder"]};
  val = Lookup[GPLNCache, Key[key], Missing[]];
  If[!MissingQ[val], Return[val]];
  val = GPLNValueRaw[w0, y0, opts];
  AssociateTo[GPLNCache, key -> val];
  val];

Options[GPLNValueRaw] = Options[GPLNValue];
GPLNValueRaw[w0_List, y0_, OptionsPattern[]] := Module[
  {prec = OptionValue["Precision"], wp, w, y, n, nz, minA, t0, ord, tails,
   ff, tt, eqs, ics, sol, ratio = OptionValue["Ratio"], val, tol, inside, atEnd},
  n = Length[w0];
  wp = prec + 25;
  If[n === 0, Return[SetPrecision[1, prec]]];
  If[!AllTrue[Append[w0, y0], NumericQ],
   Return[GPLFail["non-numeric-G", {w0, y0}]]];
  w = SetPrecision[N[w0, wp], wp];
  y = SetPrecision[N[y0, wp], wp];
  tol = 10^(-wp/2);
  nz = Select[w, Abs[#] > tol &];
  (* an index strictly inside the segment makes the integral ill-defined *)
  inside = Select[nz, (Abs[Im[#]] < tol && Re[#] > 0 && Re[#] < Abs[y] (1 - tol)) &];
  If[inside =!= {},
   Return[GPLFail["index-on-integration-path", {w0, y0}]]];
  (* an index AT the endpoint: divergent iff it is the leading one; otherwise
     finite, but the ODE sub-chain diverges there -- go through Hoelder *)
  atEnd = Select[nz, (Abs[Im[#]] < tol && Abs[Re[#] - Abs[y]] <= Abs[y] tol) &];
  If[atEnd =!= {},
   If[Abs[First[w] - y] <= Abs[y] tol,
    Return[GPLFail["leading-index-at-endpoint", {w0, y0}]]];
   If[!TrueQ[OptionValue["Holder"]] || Abs[Last[w]] <= tol,
    Return[GPLFail["endpoint-index-needs-Holder", {w0, y0}]]];
   (* scale to argument 1 (needs a_n != 0), then convolve *)
   Return[SetPrecision[GPLHolder2[w/y, prec], prec]]];
  If[nz === {},                                  (* all indices zero *)
   Return[SetPrecision[Log[y]^n/n!, prec]]];
  minA = Min[Abs /@ nz];
  t0 = Min[minA, Abs[y]]/ratio;
  ord = OptionValue["StartOrder"];
  If[ord === Automatic,
   ord = Ceiling[(wp + 10)/Log10[minA/t0]] + 5];
  tails = Table[Drop[w, i - 1], {i, 1, n}];
  If[Abs[y] <= minA/4,                            (* pure series suffices *)
   ord = Ceiling[(wp + 10)/Log10[minA/Abs[y]]] + 5;
   Return[SetPrecision[GPLSeriesValue[w, y, ord, wp], prec]]];
  (* primary: deterministic Taylor stepping from t0, initial values from the
     exact expansion at 0 (which also supplies the logarithms for zero indices).
     NB Return must sit at the top level of THIS Module (the function body):
     inside a nested Module it would only exit that inner Module. *)
  val = GPLChainValue[w, t0, Table[GPLSeriesValue[tails[[i]], t0, ord, wp], {i, n}], y, wp];
  If[NumericQ[val] && Precision[val] >= prec + 2, Return[SetPrecision[val, prec]]];
  (* fallback: adaptive ODE solve, with the domain checked explicitly *)
  eqs = Table[ff[i]'[tt] == If[i === n, 1, ff[i + 1][tt]]/(tt - w[[i]]), {i, n}];
  ics = Table[ff[i][t0] == GPLSeriesValue[tails[[i]], t0, ord, wp], {i, n}];
  (* Goals must leave real headroom below WorkingPrecision, and the returned
     domain MUST be checked: an NDSolve that stops early otherwise hands back
     a silently extrapolated value (this cost us ~5-digit answers once). *)
  val = $Failed;
  Do[If[val === $Failed,
    Module[{goal = wp - 20 - 10 gtry, ifun, dom, cand},
     sol = Quiet[NDSolve[Join[eqs, ics], Table[ff[i], {i, n}], {tt, t0, y},
        WorkingPrecision -> wp, AccuracyGoal -> goal, PrecisionGoal -> goal,
        MaxSteps -> 10^7, MaxStepFraction -> 1/50,
        Method -> "StiffnessSwitching"], {NDSolve::precw, NDSolve::mxsst}];
     If[Head[sol] === List && sol =!= {},
      ifun = ff[1] /. First[sol];
      dom = Quiet[ifun["Domain"]];
      (* the domain must actually reach y: no silent extrapolation *)
      If[MatchQ[dom, {{_?NumericQ, _?NumericQ}}] &&
         Abs[y] <= Abs[dom[[1, 2]]] (1 + 10^-30),
       cand = Quiet[ifun[y]];
       (* and the value must really carry the precision we are about to claim *)
       If[NumericQ[cand] && Precision[cand] >= prec + 2, val = cand]]]]],
   {gtry, 0, 2}];
  If[val === $Failed,
   Return[GPLFail["NDSolve-short-domain", {w0, y0}]]];
  SetPrecision[val, prec]];

(* numeric value of a whole GPL expression at x = val (parameters must
   already be substituted) *)
GPLNumeric[e_, x_, val_, prec_: 40] := Module[{cl = GPLCollect[e, x], acc = 0, bad = False},
  If[cl === $Failed, Return[$Failed]];
  Do[Module[{w = k, c = Lookup[cl, Key[k]], cv, gv},
    cv = N[Together[c] /. x -> val, prec + 15];
    If[!NumericQ[cv], bad = True,
     gv = If[w === {}, 1, GPLNValue[N[w, prec + 15], val, "Precision" -> prec + 10]];
     If[gv === $Failed, bad = True, acc += cv gv]]],
   {k, Keys[cl]}];
  If[bad, $Failed, SetPrecision[acc, prec]]];

(* ------------------------------------------------------------------ *)
(* 8.  cache control                                                   *)
(* ------------------------------------------------------------------ *)

GPLClearCache[] := (GPLPFracCache = <||>; GPLIntCache = <||>; GPLSeriesCache = <||>; GPLNCache = <||>;);
GPLCacheSizes[] := <|"PFrac" -> Length[GPLPFracCache], "Int" -> Length[GPLIntCache],
   "Series" -> Length[GPLSeriesCache]|>;

GPLLoaded = True;
GPLLog["GPLLayer loaded"];
