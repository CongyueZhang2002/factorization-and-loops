
(* ==== moved from Private/Core/MultiquadraticAlgebra.wl on 2026-09-02 (user decision N8) ====
   Evidence: no caller in the package or scripts; the shared modularSplitPointQ
   (Core/ModularArithmetic.wl) is the implementation.
   Symbols: multiquadraticSplitPointQ
   This file is never loaded by FeynFacet.m. *)
(* one implementation (Core/ModularArithmetic.wl, overhaul 2026-09-02) *)
multiquadraticSplitPointQ[point : {_, _}, radicands_List, vars : {_, _},
    p_Integer?Positive] := TrueQ[modularSplitPointQ[point, radicands, vars, p]];
