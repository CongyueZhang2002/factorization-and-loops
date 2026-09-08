#!/usr/bin/env wolframscript
p[l_, x_] := Print[l, " -> Head=", Head[x], "  Length=", Length[x], "  ", InputForm[x]];
(* same-initializer-list reference, exactly as VoCFVector does it *)
p["Module[{n=3, out=ConstantArray[0,n]}, out]",
  Module[{n = 3, out = ConstantArray[0, n]}, out]];
(* value assigned in the BODY instead *)
p["Module[{n=3, out}, out=ConstantArray[0,n]; out]",
  Module[{n = 3, out}, out = ConstantArray[0, n]; out]];
(* n taken from an enclosing Module (as VoCTLaurent does) *)
p["outer n, inner Module", Module[{n = 3}, Module[{z = ConstantArray[0, {n, n}]}, z]]];
Print["ConstantArray[0, symbolicN] -> ", InputForm[ConstantArray[0, nsym]]];
Print["Length of that            -> ", Length[ConstantArray[0, nsym]]];
