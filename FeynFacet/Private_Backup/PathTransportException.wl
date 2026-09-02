
(* ==== moved from Private/PathTransportException.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere (reachability.py 2026-09-02)
   Symbols: pathTransportExceptionPlanQ
   This file is never loaded by FeynFacet.m. *)


pathTransportExceptionPlanQ[plan_] :=
  pathTransportExceptionPlanIssues[plan] === {};
