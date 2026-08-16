(* balance_loop: remove integer eigenvalue offsets from the balanced
   slice systems by manual Libra balances; loud spectra each step.
   Arg: 97 | 77 | 79 *)
x = Global`x; eps = Global`eps;
here = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/eps0";
SetDirectory[here];
cid = ToExpression[$ScriptCommandLine[[2]]];
Get["/home/maxzhang/factorization-and-loops/Addon/Mathematica_Addon/Libra/Source/Libra.m"];
v = Global`v; w = Global`w; t = Global`t; y = Global`y;
cls = Get["classes.wl"];
ent = SelectFirst[cls, #["ClassID"] == cid &];
A = Which[
  cid === 79,
  Module[{wt = -t (1 + t + v)/(1 + t)},
   Together[(ent["RepAw"] /. w -> wt) D[wt, t] /. {v -> 3/7, t -> x}]],
  True,
  Module[{vx = Global`xx y, wx = (1 - Global`xx) (1 - y), Av, Aw},
   Av = ent["RepAv"]; Aw = ent["RepAw"];
   Together[((Av /. {v -> vx, w -> wx}) y -
       (Aw /. {v -> vx, w -> wx}) (1 - y)) /. {y -> 3/7, Global`xx -> x}]]];
A = Together[A];
Ttot = IdentityMatrix[4];
(* Fuchsify FINITE rank>0 points first (e.g. class 79's v+w double
   pole image), then infinity *)
Module[{dnsF, TF},
 dnsF = DeleteDuplicates[Flatten[Table[
    Module[{den = Denominator[Together[A[[i, j]]]]},
     Select[First /@ Rest[FactorList[den]], Exponent[#, x] >= 1 &]],
    {i, 4}, {j, 4}]]];
 TF = Quiet@TimeConstrained[Fuchsify[A, x, dnsF], 900, $TimedOut];
 Which[
  TF === $TimedOut, Print["finite Fuchsify TIMED OUT"],
  MatrixQ[TF],
   A = Together[Inverse[TF] . A . TF - Inverse[TF] . D[TF, x]];
   Ttot = Together[Ttot . TF];
   Print["finite points Fuchsified"],
  True, Print["finite Fuchsify returned ", Head[TF]]]];
(* Fuchsify at infinity: work in xi=1/x *)
Module[{xi = Global`xi, Axi, TF},
 Axi = Together[-(A /. x -> 1/xi)/xi^2];
 TF = Quiet@TimeConstrained[Fuchsify[Axi, xi, {xi}], 600, $TimedOut];
 Which[
  TF === $TimedOut, Print["infinity Fuchsify TIMED OUT"],
  MatrixQ[TF],
   Axi = Together[Inverse[TF] . Axi . TF - Inverse[TF] . D[TF, xi]];
   A = Together[-(Axi /. xi -> 1/x)/x^2];
   Ttot = Together[Ttot . (TF /. xi -> 1/x)];
   Print["infinity Fuchsified; new rank check passed"],
  True, Print["Fuchsify returned ", Head[TF], " — continuing unfixed"]]];

poles[Amat_] := DeleteDuplicates[Flatten[Table[
   Module[{den = Denominator[Together[Amat[[i, j]]]]},
    (-Coefficient[#, x, 0]/Coefficient[#, x, 1]) & /@
      Select[First /@ Rest[FactorList[den]], Exponent[#, x] == 1 &]],
   {i, 4}, {j, 4}]]];
resAt[Amat_, x0_] := Together[(Cancel[Together[(x - x0) Amat]]) /. x -> x0];
resInf[Amat_] := Table[
  Together[-SeriesCoefficient[Series[Amat[[i, j]], {x, Infinity, 1}], 1]],
  {i, 4}, {j, 4}];
ipart[e_] := Together[e /. eps -> 0];
spectra[Amat_] := Module[{ps = poles[Amat], out},
  out = Table[{p, Eigenvalues[resAt[Amat, p]]}, {p, ps}];
  Append[out, {Infinity, Eigenvalues[resInf[Amat]]}]];
offsets[sp_] := Select[Flatten[Table[
   {sp[[k, 1]], #} & /@ Select[sp[[k, 2]], ipart[#] =!= 0 &],
   {k, Length[sp]}], 1], True &];
intSpectraQ[sp_] := AllTrue[Flatten[sp[[All, 2]]],
  IntegerQ[ipart[#]] &];
badnessOf[sp_] := Total[Abs[ipart[#[[2]]]] & /@ offsets[sp]];

apply[Amat_, T_] := Together[Inverse[T] . Amat . T - Inverse[T] . D[T, x]];

(* Lee balance projector: right eigenvector at the lowered point,
   left eigenvector at the raised point *)
pairProj[R1_, lam1_, R2_, lam2_] := Module[{v, u, ip},
  v = NullSpace[R1 - lam1 IdentityMatrix[4]];
  u = NullSpace[Transpose[R2 - lam2 IdentityMatrix[4]]];
  If[v === {} || u === {}, Return[$Failed]];
  Module[{best = $Failed},
   Do[ip = Together[u[[j]] . v[[i]]];
    If[ip =!= 0, best = Together[Transpose[{v[[i]]}] . {u[[j]]}/ip];
     Break[]], {i, Length[v]}, {j, Length[u]}];
   best]];

sp = spectra[A];
Print["initial spectra:"];
Do[Print["  ", InputForm[s[[1]]], ": ", InputForm[Together /@ s[[2]]]], {s, sp}];
Do[
  Module[{off = offsets[sp], neg, tgt, lam, badness, improved = False},
   If[off === {}, Print[">>> all offsets removed at iter ", it]; Break[]];
   neg = First[SortBy[off, ipart[#[[2]]] &]];
   {tgt, lam} = neg;
   badness = badnessOf[sp];
   Module[{R1 = If[tgt === Infinity, resInf[A], resAt[A, tgt]],
     partners = Append[DeleteCases[sp[[All, 1]], tgt], Infinity] //
       DeleteDuplicates},
    Do[If[! improved,
      Module[{R2 = If[p2 === Infinity, resInf[A], resAt[A, p2]], evs2},
       evs2 = DeleteDuplicates[Eigenvalues[R2]];
       Do[If[! improved,
         Module[{P = pairProj[R1, lam, R2, lam2], T, A2, sp2, b2},
          If[P =!= $Failed,
           T = Which[
             tgt === Infinity, Balance[P, {x, Infinity, p2}],
             p2 === Infinity, Balance[P, {x, tgt, Infinity}],
             True, Balance[P, {x, tgt, p2}]];
           A2 = apply[A, T]; sp2 = spectra[A2];
           b2 = If[intSpectraQ[sp2], badnessOf[sp2], Infinity];
           If[b2 < badness,
            A = A2; Ttot = Together[Ttot . T]; sp = sp2; improved = True;
            Print["iter ", it, ": balanced ", InputForm[tgt], " (",
              InputForm[lam], ") vs ", InputForm[p2], " (", InputForm[lam2],
              "); badness ", badness, " -> ", b2]]]]],
        {lam2, evs2}]]],
     {p2, partners}]];
   If[! improved,
    Print["iter ", it, ": NO admissible balance improves (badness ",
      badness, "); stopping"]; Break[]]],
  {it, 1, 40}];
Print["final spectra:"];
Do[Print["  ", InputForm[s[[1]]], ": ", InputForm[Together /@ s[[2]]]],
  {s, spectra[A]}];
Print[">>> EFormQ: ", EFormQ[A, eps]];
Put[<|"Class" -> cid, "A" -> A, "Ttot" -> Ttot|>,
  "balanced_c" <> ToString[cid] <> ".wl"];
Print["DONE"];
