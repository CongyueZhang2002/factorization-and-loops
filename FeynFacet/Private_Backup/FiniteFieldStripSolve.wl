
(* ==== moved from Private/FiniteFieldStripSolve.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere (reachability.py 2026-09-02)
   Symbols: finiteFieldStripArtifactTag
   This file is never loaded by FeynFacet.m. *)


finiteFieldStripArtifactTag[value_] := StringReplace[
  ToString[value, InputForm],
  {"/" -> "_", "-" -> "m", " " -> ""}];
