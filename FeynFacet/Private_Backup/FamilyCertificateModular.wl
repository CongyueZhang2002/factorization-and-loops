
(* ==== moved from Private/FamilyCertificateModular.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere (reachability.py 2026-09-02)
   Symbols: familyCertMQEvaluateMatrix
   This file is never loaded by FeynFacet.m. *)


(* eval is supplied by familyCertMQTrial and memoized there for one sheet;
   repeated zeroes, diagonal entries and repeated residues are evaluated
   once rather than once per matrix occurrence. *)
familyCertMQEvaluateMatrix[matrix_List, eval_] := Module[{value},
  value = Map[eval, matrix, {2}];
  If[FreeQ[value, $Failed], value, $Failed]
];
