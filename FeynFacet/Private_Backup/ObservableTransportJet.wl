(* ==== moved from Private/Transport/Observable/ObservableTransport.wl on 2026-09-02 (round 6, Codex conciseness point) ====
   Evidence: the epsilon-jet Laurent route ("Jet") was measured pathological by
   agent L on real CF259 entries (Design/PrivateOverhaul_2026-09-01_evidence/round4/L_modular_laurent_route.md,
   section 1, route C): the jet COMPILE of the nested-quotient entry (42,20),
   12 KB, does not terminate in 30 s and the first calibration run was killed
   at the 300 s cap inside it -- the common-denominator cross-multiplication
   of nested sums of quotients grows multiplicatively with the nesting depth
   (the plan's 21-minute rejection of 2026-09-02 05:05 was the same effect);
   the production route is "Series" (one Series call per entry, byte-identical
   canonical coefficients).  In the live file $observableTransportLaurentMethod
   === "Jet" now answers the typed refusal
   <|"Status" -> "RouteRetired", "Route" -> "Laurent jet", "Replacement" -> "Series"|>.
   Symbols: observableTransportEpsJetTrim, observableTransportEpsJetAdd,
   observableTransportEpsJetMul, observableTransportEpsJetPow,
   observableTransportEpsJetCompile, observableTransportEpsJetLeading,
   observableTransportEpsJetCoefficients, observableTransportLaurentEntryJet,
   $observableTransportLaurentCanonicalize.
   Test: Private_Backup/Tests/t_observable_transport_laurent_jet.wls (moved with it).
   This file is never loaded by FeynFacet.m. *)

observableTransportEpsJetTrim[p_List] := Module[{q = p},
  While[Length[q] > 1 && TrueQ[Last[q] === 0], q = Most[q]];
  q
];
observableTransportEpsJetAdd[a_List, b_List] := observableTransportEpsJetTrim[
  PadRight[a, Max[Length[a], Length[b]]] +
    PadRight[b, Max[Length[a], Length[b]]]];
observableTransportEpsJetMul[a_List, b_List] := observableTransportEpsJetTrim@Table[
  Sum[a[[i]] b[[k - i + 1]], {i, Max[1, k - Length[b] + 1], Min[Length[a], k]}],
  {k, Length[a] + Length[b] - 1}];
observableTransportEpsJetPow[_, 0] := {1};
observableTransportEpsJetPow[p_List, n_Integer?Positive] := Module[
  {base = p, exponent = n, out = {1}},
  While[exponent > 0,
    If[OddQ[exponent], out = observableTransportEpsJetMul[out, base]];
    exponent = Quotient[exponent, 2];
    If[exponent > 0, base = observableTransportEpsJetMul[base, base]]];
  out
];
(* {numerator, denominator} coefficient lists in eps, lowest order first *)
observableTransportEpsJetCompile[e_, eps_] := Which[
  TrueQ[e === 0], {{0}, {1}},
  e === eps, {{0, 1}, {1}},
  FreeQ[e, eps], {{e}, {1}},
  Head[e] === Plus, Fold[
    Function[{acc, term}, With[{t = observableTransportEpsJetCompile[term, eps]},
      If[SameQ[acc[[2]], t[[2]]],
        {observableTransportEpsJetAdd[acc[[1]], t[[1]]], acc[[2]]},
        {observableTransportEpsJetAdd[
            observableTransportEpsJetMul[acc[[1]], t[[2]]],
            observableTransportEpsJetMul[t[[1]], acc[[2]]]],
          observableTransportEpsJetMul[acc[[2]], t[[2]]]}]]],
    {{0}, {1}}, List @@ e],
  Head[e] === Times, Fold[
    Function[{acc, factor}, With[{t = observableTransportEpsJetCompile[factor, eps]},
      {observableTransportEpsJetMul[acc[[1]], t[[1]]],
       observableTransportEpsJetMul[acc[[2]], t[[2]]]}]],
    {{1}, {1}}, List @@ e],
  Head[e] === Power && IntegerQ[e[[2]]], With[
    {b = observableTransportEpsJetCompile[e[[1]], eps], k = e[[2]]},
    If[k > 0,
      {observableTransportEpsJetPow[b[[1]], k], observableTransportEpsJetPow[b[[2]], k]},
      {observableTransportEpsJetPow[b[[2]], -k], observableTransportEpsJetPow[b[[1]], -k]}]],
  True, Throw[$Failed, "observableTransportEpsJetUnsupported"]
];
(* the leading coefficients decide the valuation: a structural nonzero
   that is an algebraic zero would shift every order, so they are tested
   exactly (masterTransportZeroQ), the rest only structurally *)
observableTransportEpsJetLeading[p_List] := Module[{q = p, k = 1},
  While[k <= Length[q] &&
      (TrueQ[q[[k]] === 0] || (! NumberQ[q[[k]]] && observableTransportZeroQ[q[[k]]])),
    q[[k]] = 0; k++];
  {q, k - 1}
];
observableTransportEpsJetCoefficients[{num_List, den_List}, {low_Integer, high_Integer}] :=
 Module[{nn, dd, n0, d0, valuation, depth, quotient, lead},
  {nn, n0} = observableTransportEpsJetLeading[num];
  If[n0 === Length[nn], Return[ConstantArray[0, high - low + 1]]];
  {dd, d0} = observableTransportEpsJetLeading[den];
  If[d0 === Length[dd], Return[$Failed]];
  valuation = n0 - d0;
  If[valuation > high, Return[ConstantArray[0, high - low + 1]]];
  depth = high - valuation;
  nn = PadRight[Drop[nn, n0], depth + 1];
  dd = PadRight[Drop[dd, d0], depth + 1];
  lead = dd[[1]];
  quotient = ConstantArray[0, depth + 1];
  Do[
    quotient[[k + 1]] = (nn[[k + 1]] -
      Sum[dd[[j + 1]] quotient[[k - j + 1]], {j, 1, k}])/lead,
    {k, 0, depth}];
  (* orders low .. high; orders below the valuation are zero *)
  Table[If[order < valuation, 0, quotient[[order - valuation + 1]]],
    {order, low, high}]
];
observableTransportLaurentEntryJet[e_, eps_, {low_Integer, high_Integer}] :=
 Module[{compiled, coefficients},
  compiled = Catch[observableTransportEpsJetCompile[e, eps],
    "observableTransportEpsJetUnsupported"];
  coefficients = If[compiled === $Failed, $Failed,
    observableTransportEpsJetCoefficients[compiled, {low, high}]];
  If[coefficients === $Failed,
    Table[observableTransportCancel[SeriesCoefficient[e, {eps, 0, order}]],
      {order, low, high}],
    If[TrueQ[$observableTransportLaurentCanonicalize],
      observableTransportCancel /@ coefficients,
      (* uncanonical coefficients: exact expressions built from the entry's
         own subexpressions (shared, not expanded); the consumers evaluate
         them at points or compile them, and cancel the final matrices *)
      coefficients]]
];
(* Whether the jet route canonicalizes every coefficient with
   Cancel[Together[...]] (True: the former route's output form) or leaves
   them as exact uncanonical expressions (False: measured option). *)
$observableTransportLaurentCanonicalize = True;
