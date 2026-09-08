(* Bounded exact and sampled checks of differential-system expressions. *)
(* A successful algebraic zero test proves vanishing. An unsuccessful or
   time-limited simplification is reported as inconclusive. *)
masterTransportSimplifyZeroQ[e_] :=
  TrueQ[Together[e] === 0] ||
  (masterTransportRadicalQ[e] && TrueQ[masterTransportRadicalZeroQ[e]]) ||
  TrueQ[TimeConstrained[Simplify[e], $masterTransportZeroTimeLimit, $Failed] === 0];

masterTransportZeroQ[e_] :=
  If[e === 0 || masterTransportSimplifyZeroQ[e], True, "Inconclusive"];

masterTransportZeroMatQ[m_] :=
  AllTrue[Flatten[{m}], TrueQ[masterTransportZeroQ[#]] &];

(* Boolean algebraic-zero and block-lower-triangularity predicates used
   by the family epsilon-form algorithms. *)
observableTransportZeroQ[x_] :=
  TrueQ[masterTransportZeroQ[x]];

observableTransportZeroMatrixQ[m_] :=
  AllTrue[Flatten[{Normal[m]}], observableTransportZeroQ];

observableTransportBlockLowerQ[matrices : {_, _}, ranges_List] := Module[
  {n = Length[First[matrices]]},
  If[! AllTrue[ranges, VectorQ[#, IntegerQ] &] ||
      Sort[Flatten[ranges]] =!= Range[n], Return[False]];
  AllTrue[
    Flatten[Table[
      If[i < j,
        {matrices[[1, ranges[[i]], ranges[[j]]]],
         matrices[[2, ranges[[i]], ranges[[j]]]]},
        {}],
      {i, Length[ranges]}, {j, Length[ranges]}]],
    observableTransportZeroMatrixQ
  ]
];


(* Check level (user decision 2026-08-22: checks stay separate from the
   calculation).  "Development": every identity exact (the default).
   "Production" (FACET_CHECK_LEVEL=Production): the identities that only
   guard the bookkeeping of an assembly -- curvature of the source and of
   the conjugated connection, per-block inverses, diagonal-equals-declared-
   form -- are evaluated EXACTLY AT RANDOM RATIONAL POINTS instead of as
   rational-function identities (a wrong matrix passes with probability
   ~ degree / 10^6 per point; two points are used), and the single exact
   statement is the family certificate made afterwards.  Measured on a
   dimension-23 production system (2026-08-22): the exact identities were 446 s of a 626 s
   assembly; the conjugation itself 49 s. *)
masterTransportCheckLevel[requested_: Automatic] := Which[
  MemberQ[{"Production", "Development"}, requested], requested,
  Environment["FACET_CHECK_LEVEL"] === "Production", "Production",
  True, "Development"];

(* exact-rational evaluation of every entry at count random points; a
   point hitting a pole is replaced *)
masterTransportPointZeroQ[expr_, symbols_List, count_Integer: 2] := Module[
  {flat = Flatten[{expr}], tries = 0, done = 0, point, values},
  If[flat === {} || AllTrue[flat, TrueQ[# === 0] &], Return[True]];
  While[done < count && tries < 6 count,
    tries++;
    point = Thread[symbols -> RandomInteger[{3, 10^6}, Length[symbols]]/
      RandomInteger[{10^6, 10^7}, Length[symbols]]];
    (* Substitute first, then normalize the now-small exact numbers.
       Plain ==0 does not reduce relations among square roots and gave a
       false SourceSystemNotFlat on a production multiquadratic subsystem. *)
    values = Quiet[Check[Together /@ (flat /. point), $Failed]];
    If[values === $Failed || ! FreeQ[values, ComplexInfinity | Indeterminate | DirectedInfinity],
      Continue[]];
    If[! AllTrue[values,
        TrueQ[# === 0] ||
          (masterTransportRadicalQ[#] &&
            TrueQ[masterTransportRadicalZeroQ[#]]) &], Return[False]];
    done++];
  done >= count];
