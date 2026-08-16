(* symrep97: symbolic-y replay of class 97's recorded normalization path.
   Loci map: -3/7 -> -y, 3/7 -> y, -3/4 -> y/(y-1), 0,1,inf fixed. *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}]];
x = Global`x; y = Global`y; v = Global`v; w = Global`w; eps = Global`eps;
here = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/eps0";
SetDirectory[here];
Quiet[Block[{Print = (Null &)},
  Get["/home/maxzhang/factorization-and-loops/Addon/Mathematica_Addon/Libra/Source/Libra.m"]],
  {General::shdw}];
cls = Get["classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == 97 &];
vx = Global`xx y; wx = (1 - Global`xx) (1 - y);
A = Together[((ent["RepAv"] /. {v -> vx, w -> wx}) y -
    (ent["RepAw"] /. {v -> vx, w -> wx}) (1 - y)) /. Global`xx -> x];
Ttot = IdentityMatrix[4];
Print["chart system built (symbolic y)"];
(* Fuchsify finite then infinity, symbolically *)
Module[{dnsF, TF},
 dnsF = DeleteDuplicates[Flatten[Table[
    Select[First /@ Rest[FactorList[Denominator[Together[A[[i, j]]]]]],
      Exponent[#, x] >= 1 &], {i, 4}, {j, 4}]]];
 TF = Quiet@Check[Fuchsify[A, x, dnsF], $Failed];
 If[MatrixQ[TF],
  A = Together[Inverse[TF] . A . TF - Inverse[TF] . D[TF, x]];
  Ttot = Together[Ttot . TF]; Print["finite Fuchsified"]]];
Module[{xi = Global`xi, Axi, TF},
 Axi = Together[-(A /. x -> 1/xi)/xi^2];
 TF = Quiet@Check[Fuchsify[Axi, xi, {xi}], $Failed];
 If[MatrixQ[TF],
  Axi = Together[Inverse[TF] . Axi . TF - Inverse[TF] . D[TF, xi]];
  A = Together[-(Axi /. xi -> 1/x)/x^2];
  Ttot = Together[Ttot . (TF /. xi -> 1/x)];
  Print["infinity Fuchsified"]]];
resAt[Am_, x0_] := Together[(Cancel[Together[(x - x0) Am]]) /. x -> x0];
resInf[Am_] := Table[Together[-SeriesCoefficient[
   Series[Am[[i, j]], {x, Infinity, 1}], 1]], {i, 4}, {j, 4}];
ipart[e_] := Cancel[Together[e /. eps -> 0]];
pickEV[R_, k_] := SelectFirst[DeleteDuplicates[Eigenvalues[R]],
  Together[ipart[#] - k] === 0 &, $Failed];
pairProj[R1_, l1_, R2_, l2_] := Module[{vv, uu, ip, best = $Failed},
  vv = NullSpace[Together[R1 - l1 IdentityMatrix[4]]];
  uu = NullSpace[Transpose[Together[R2 - l2 IdentityMatrix[4]]]];
  If[vv === {} || uu === {}, Return[$Failed]];
  Do[ip = Together[uu[[j]] . vv[[i]]];
   If[ip =!= 0, best = Together[Transpose[{vv[[i]]}] . {uu[[j]]}/ip];
    Break[]], {i, Length[vv]}, {j, Length[uu]}];
  best];
path = {{-y, -4, Infinity, 7/2}, {-y, -3, Infinity, 2}, {-y, -2, y, 1},
  {1, -2, Infinity, 3}, {1, -2, Infinity, 2}, {1, -2, Infinity, 1},
  {-y, -1, Infinity, 2}, {0, -1, Infinity, 1}, {1, -1, Infinity, 1},
  {1, -1, Infinity, 2}, {1, -1, Infinity, 1}};
Do[Module[{tgt, kt, prt, kp, R1, R2, l1, l2, P, T},
  {tgt, kt, prt, kp} = path[[n]];
  R1 = If[tgt === Infinity, resInf[A], resAt[A, tgt]];
  R2 = If[prt === Infinity, resInf[A], resAt[A, prt]];
  l1 = pickEV[R1, kt]; l2 = pickEV[R2, kp];
  If[l1 === $Failed || l2 === $Failed,
   Print["step ", n, ": EIGENVALUE MATCH FAILED (", InputForm[tgt], " k=",
     kt, " found: ", l1 =!= $Failed, "; partner k=", kp, " found: ",
     l2 =!= $Failed, ")"]; Abort[]];
  P = pairProj[R1, l1, R2, l2];
  If[P === $Failed, Print["step ", n, ": PROJECTOR FAILED"]; Abort[]];
  T = Which[
    tgt === Infinity, Balance[P, {x, Infinity, prt}],
    prt === Infinity, Balance[P, {x, tgt, Infinity}],
    True, Balance[P, {x, tgt, prt}]];
  A = Together[Inverse[T] . A . T - Inverse[T] . D[T, x]];
  Ttot = Together[Ttot . T];
  Print["step ", n, ": balanced ", InputForm[tgt], " (", kt, ") vs ",
    InputForm[prt], " (", kp, ")"]],
 {n, Length[path]}];
(* verify: all integer parts gone *)
Module[{pts = {0, 1, y, -y, y/(y - 1)}, bad = 0},
 Do[Module[{ev = Eigenvalues[resAt[A, p]]},
   Do[If[Together[ipart[e]] =!= 0, bad++], {e, ev}]], {p, pts}];
 Module[{ev = Eigenvalues[resInf[A]]},
  Do[If[Together[ipart[e]] =!= 0, bad++], {e, ev}]];
 Print["residual integer offsets: ", bad];
 If[bad === 0, Print[">>> SYMBOLIC NORMALIZATION COMPLETE"]]];
HCTPut[<|"A" -> A, "Ttot" -> Ttot|>, "symnorm_c97.wl"];
Print["DONE"];
