
(* ==== moved from Private/ObservableTransport.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere (reachability.py 2026-09-02)
   Symbols: observableTransportColumnBasis, observableTransportRowBasis
   This file is never loaded by FeynFacet.m. *)


observableTransportRowBasis[m_, rules_List] := Module[{rows},
  rows = observableTransportIndependentRows[m, rules];
  If[rows === $Failed, Return[$Failed]];
  If[rows === {}, ConstantArray[0, {0, If[MatrixQ[m], Dimensions[m][[2]], 0]}],
    m[[rows]]]
];

observableTransportColumnBasis[m_, rules_List] := Module[{basis},
  basis = observableTransportRowBasis[Transpose[m], rules];
  If[basis === $Failed, $Failed, Transpose[basis]]
];
