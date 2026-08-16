(* EpsilonGraded.wl — eps-graded scalar solve (own implementation).
   Method: expand the monic operator in eps, L = L0 + eps L1 + ...;
   invert L0 through its verified first-order factor chain
   L0 = (D - r_n)...(D - r_1) by n anchored quadratures per order
   (engine: HyperIntica exact primitives, Hlog words);
   f_n = L0^{-1}[ -Sum_{j>=1} L_j f_{n-j} ].
   Anchored primitives fix the particular continuation; the n
   homogeneous functions of the parameter per order are returned as
   an explicit basis and pinned later by the second-variable equation.
   Every order carries an exact residual certificate (HyperD). *)

Needs["HyperIntica`",
  "/home/maxzhang/.Wolfram/Paclets/Repository/SubTropica-1.2.9/HyperIntica.wl"];

EGSeriesCoefficients[expr_, epsSym_, K_] := Module[
  {num = Numerator[Together[expr]], den = Denominator[Together[expr]], nc, dc, q},
  nc = Table[Coefficient[num, epsSym, j], {j, 0, K}];
  dc = Table[Coefficient[den, epsSym, j], {j, 0, K}];
  If[dc[[1]] === 0, Return[$Failed]];  (* pole in eps: caller must Laurent-shift *)
  q = ConstantArray[0, K + 1];
  Do[q[[m + 1]] = Cancel[Together[
      (nc[[m + 1]] - Sum[dc[[k + 1]] q[[m - k + 1]], {k, 1, m}])/dc[[1]]]],
    {m, 0, K}];
  q];

EGGradeOperator[ps_List, epsSym_, K_] := Module[{mon, tabs},
  mon = Together[ps/Last[ps]];
  tabs = EGSeriesCoefficients[#, epsSym, K] & /@ mon;
  If[MemberQ[tabs, $Failed], Return[$Failed]];
  (* result[[j+1]] = coefficient list of eps^j *)
  Table[tabs[[All, j + 1]], {j, 0, K}]];

EGStageWeight[r_, var_] := Module[{ap, terms, h, chk},
  ap = Apart[Together[r], var];
  terms = If[Head[ap] === Plus, List @@ ap, {ap}];
  h = 1;
  Do[Module[{t = Together[term], den, ex, root, cf},
     Which[
      t === 0, Null,
      FreeQ[t, var], Return[$Failed, Module],  (* nonzero constant: exp weight *)
      True,
       den = Denominator[t];
       ex = Exponent[den, var];
       If[ex =!= 1, Return[$Failed, Module]];
       root = -Coefficient[den, var, 0]/Coefficient[den, var, 1];
       cf = Cancel[t (var - root)];
       If[! FreeQ[cf, var] || ! IntegerQ[cf], Return[$Failed, Module]];
       h = h (var - root)^cf]],
    {term, terms}];
  chk = Together[D[h, var]/h - r];
  If[chk =!= 0 && Simplify[chk] =!= 0, $Failed, Together[h]]];

EGChainData[chain_List, var_] := Module[{hs},
  hs = EGStageWeight[#, var] & /@ chain;
  If[MemberQ[hs, $Failed], $Failed, hs]];

(* ---- self-verifying primitive ----------------------------------------
   HyperInticaPrimitive mishandles pure-zero words (Log powers): measured
   2026-08-15, primitive of Hlog[x,{0,0}] returns HALF the true value in
   every on-box version; words with any nonzero letter are exact.  Every
   package result is therefore certified by HyperD before acceptance;
   failures (and pure-zero content) route to our own exact by-parts
   recursion EGOwnPrimitive, which handles c*x^k*Hlog and c/(x-a)^j*Hlog
   for arbitrary words.  A term neither engine handles aborts loudly. *)

EGPureZeroQ[w_List] := w =!= {} && AllTrue[w, # === 0 &];

(* own exact primitive of R(x) * Hlog[x, w]; R rational, any word w *)
EGNorm[e_] := e /. Hlog[_, {}] -> 1;

EGOwnPrimitive[f_, var_] := Module[{expanded, terms},
  expanded = Expand[Together[f] /.
    Power[Hlog[var, w_List], p_Integer /; p > 1] :>
      EGShufflePower[var, w, p]];
  terms = If[Head[expanded] === Plus, List @@ expanded, {expanded}];
  EGNorm[Together[Total[EGOwnPrimTerm[#, var] & /@ terms]]]];

(* shuffle power expansion: only needed for equal-word powers *)
EGShufflePower[var_, w_List, p_Integer] :=
  Nest[EGShuffleMul[var, w, #] &, Hlog[var, w], p - 1];

EGShuffleMul[var_, w_List, expr_] := Expand[expr /. Hlog[var, u_List] :>
    Total[Hlog[var, #] & /@ EGShuffles[w, u]]];

EGShuffles[{}, u_List] := {u};
EGShuffles[w_List, {}] := {w};
EGShuffles[w_List, u_List] := Join[
  Prepend[#, First[w]] & /@ EGShuffles[Rest[w], u],
  Prepend[#, First[u]] & /@ EGShuffles[w, Rest[u]]];

EGOwnPrimTerm[term_, var_] := Module[{hl, rat, w},
  hl = Cases[{term}, Hlog[var, ww_List] :> ww, Infinity];
  Which[
   Length[hl] == 0,
    (* pure rational: prepend-letter form via Apart *)
    EGOwnRatPrim[Together[term], {}, var],
   Length[hl] == 1,
    w = First[hl];
    rat = Together[term /. Hlog[var, w] -> 1];
    EGOwnRatPrim[rat, w, var],
   True,
    (* product of distinct Hlogs: shuffle into single words first *)
    EGOwnPrimitive[term //. Hlog[var, a_List] Hlog[var, b_List] :>
       Total[Hlog[var, #] & /@ EGShuffles[a, b]], var]]];

(* primitive of R(x)*Hlog[var,w] with R = this rational function *)
EGOwnRatPrim[rat_, w_List, var_] := Module[{ap, terms},
  ap = Apart[rat, var];
  terms = If[Head[ap] === Plus, List @@ ap, {ap}];
  Total[EGOwnSimplePrim[#, w, var] & /@ terms]];

EGOwnSimplePrim[t_, w_List, var_] := Module[
  {c, k, a, j, den, num, rest, w1},
  Which[
   t === 0, 0,
   (* polynomial piece: c * var^k *)
   PolynomialQ[t, var],
    Total[Function[kk, Module[{cc = Coefficient[t, var, kk]},
       If[cc === 0, 0,
        cc (var^(kk + 1)/(kk + 1) Hlog[var, w] -
          If[w === {}, 0,
           EGOwnRatPrim[var^(kk + 1)/((kk + 1) (var - First[w])),
             Rest[w], var]])]]] /@ Range[0, Exponent[t, var]]],
   True,
    den = Denominator[Together[t]]; num = Numerator[Together[t]];
    (* strip var-free content of the denominator into the numerator *)
    Module[{fl = FactorList[den], xpart = 1, vfree = 1},
      Do[If[FreeQ[f[[1]], var], vfree *= f[[1]]^f[[2]],
         xpart *= f[[1]]^f[[2]]], {f, fl}];
      den = xpart; num = Together[num/vfree]];
    j = Exponent[den, var];
    Which[
     j == 0, EGOwnSimplePrim[Together[t], w, var],  (* shouldn't occur *)
     (* simple pole c/(var-a): definitional prepend *)
     j == 1 && FreeQ[num, var],
      a = -Coefficient[den, var, 0]/Coefficient[den, var, 1];
      (num/Coefficient[den, var, 1]) Hlog[var, Prepend[w, Together[a]]],
     (* higher pole c/(var-a)^j: integrate by parts to lower j *)
     FreeQ[num, var] && Length[FactorList[den]] == 2 &&
       Exponent[FactorList[den][[2, 1]], var] == 1,
      Module[{fac = FactorList[den][[2]], lead, aa, jj, cc},
       lead = Coefficient[fac[[1]], var, 1]; jj = fac[[2]];
       aa = -Coefficient[fac[[1]], var, 0]/lead;
       cc = num/lead^jj;
       cc (-Hlog[var, w]/((jj - 1) (var - aa)^(jj - 1))) +
        If[w === {}, 0,
         EGOwnRatPrim[cc/((jj - 1) (var - aa)^(jj - 1) (var - First[w])),
           Rest[w], var]]],
     True, Throw[{"EGOwnSimplePrim unhandled", t, w}, egprim]]]];

EGPrimitive[f_, var_] := Module[{ff = Together[EGNorm[f]], cand, res},
  res = Catch[
   (* route pure-zero content directly to own engine *)
   If[! FreeQ[ff, Hlog[var, ww_List /; EGPureZeroQ[ww]]] ||
      ! FreeQ[ff, Power[Hlog[var, _List], _Integer]],
     Return[EGOwnPrimitive[ff, var], Module]];
   cand = Catch[Quiet@Check[HyperInticaPrimitive[ff, var], $Failed],
     _, $Failed &];
   If[cand =!= $Failed && FreeQ[cand, $Failed] &&
      TrueQ[Quiet@Catch[EGZeroQ[EGOwnD[cand, var] - ff, var], _, False &]],
     Return[cand, Module]];
   EGOwnPrimitive[ff, var],
   egprim];
  If[ListQ[res] && Length[res] >= 1 && res[[1]] === "EGOwnSimplePrim unhandled",
    Print["EGPrimitive HARD FAIL: ", InputForm[res]];
    Throw[res, egfatal]];
  res];

EGChainSolve[chain_List, hs_List, rhs_, var_] := Module[{u = rhs, n = Length[chain]},
  Do[u = Together[hs[[k]]] EGPrimitive[Together[u/hs[[k]]], var],
    {k, n, 1, -1}];
  u];

(* own exact Hlog derivative: definitional rule, no package call *)
EGOwnD[expr_, var_] := Module[{e2, d2},
  e2 = expr /. Hlog[var, ww_List] :> EGHH[ww][var];
  d2 = D[e2, var];
  d2 /. {Derivative[1][EGHH[ww_List]][var] :>
      If[ww === {}, 0, Hlog[var, Rest[ww]]/(var - First[ww])],
    EGHH[ww_List][var] :> Hlog[var, ww]}];

EGApplyOperator[coeffs_List, f_, var_] := Module[{ders},
  ders = NestList[Together[EGOwnD[#, var]] &, f, Length[coeffs] - 1];
  Total[MapThread[Times, {coeffs, ders}]]];

(* own exact zero test: shuffle-expand products to single words (which
   are linearly independent over rational functions), collect, and test
   every coefficient *)
EGZeroQ[expr_, var_] := Module[{e, words, coefs},
  e = Expand[Together[EGNorm[expr]] /.
     Power[Hlog[var, ww_List], p_Integer /; p > 1] :>
       EGShufflePower[var, ww, p]];
  e = e //. Hlog[var, a_List] Hlog[var, b_List] :>
     Total[Hlog[var, #] & /@ EGShuffles[a, b]];
  e = Expand[e];
  words = DeleteDuplicates[Cases[{e}, Hlog[var, ww_List] :> ww, Infinity]];
  coefs = Append[
    Table[Coefficient[e, Hlog[var, ww]], {ww, words}],
    e /. Hlog[var, _List] -> 0];
  AllTrue[coefs, Together[#] === 0 || Simplify[#] === 0 &]];

EGResidualZeroQ[expr_, var_] := EGZeroQ[expr, var];

Options[EGSolve] = {"Depth" -> 2, "Verify" -> True};
EGSolve[ps_List, chain_List, f0_, var_, epsSym_, OptionsPattern[]] := Module[
  {K = OptionValue["Depth"], grading, hs, fs, rhs, res, certs, times, t0},
  grading = EGGradeOperator[ps, epsSym, K];
  If[grading === $Failed,
    Return[<|"Status" -> "GradingFailed(eps pole in monic coefficients)"|>]];
  hs = EGChainData[chain, var];
  If[hs === $Failed,
    Return[<|"Status" -> "NonRationalStageWeight", "Chain" -> chain|>]];
  fs = {f0}; certs = {}; times = {};
  Do[
    t0 = AbsoluteTime[];
    rhs = -Sum[EGApplyOperator[grading[[j + 1]], fs[[n - j + 1]], var],
        {j, 1, Min[n, Length[grading] - 1]}] // Together;
    AppendTo[fs, EGChainSolve[chain, hs, rhs, var]];
    If[OptionValue["Verify"],
      res = Sum[EGApplyOperator[grading[[j + 1]], fs[[n - j + 1]], var],
        {j, 0, Min[n, Length[grading] - 1]}];
      AppendTo[certs, EGResidualZeroQ[res, var]],
      AppendTo[certs, Missing["NotChecked"]]];
    AppendTo[times, Round[AbsoluteTime[] - t0, 0.01]],
    {n, 1, K}];
  <|"Status" -> If[AllTrue[certs, TrueQ[#] || MissingQ[#] &],
      "OK", "ResidualFailed"],
    "Orders" -> fs, "ResidualZero" -> certs, "SecondsPerOrder" -> times,
    "HomogeneousBasis" -> EGKernelBasis[chain, hs, var],
    "StageWeights" -> hs|>];

(* kernel basis of the chain: s^(k) uses k-1 nested anchored primitives *)
EGKernelBasis[chain_List, hs_List, var_] := Module[{n = Length[chain]},
  Table[
    hs[[1]] Fold[Function[{acc, k},
        EGPrimitive[Together[hs[[k]]/hs[[k - 1]]] acc, var]],
      1, Reverse[Range[2, k]]],
    {k, 1, n}]];
