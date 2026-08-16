(* pooled_sweep: slice eps-forms at many y-points, 4 missions at a time
   under ONE main.  Control mission {97, 3/7} must reproduce the known
   letters.  Each mission: build chart slice -> Fuchsify finite+inf ->
   two-point Lee balance descent (integer-guarded) -> CANONICA constant
   transform -> entrywise eps-form check -> save. *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}]];
x = Global`x; y = Global`y; v = Global`v; w = Global`w;
t = Global`t; eps = Global`eps;
here = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/eps0";
SetDirectory[here];

sliceMission[{cid_, ystr_String}] := Module[
  {y0 = ToExpression[ystr], ytag = StringReplace[ystr, "/" -> "_"],
   cls, ent, A, Ttot, ok, out},
  cls = Get[FileNameJoin[{here, "classes.wl"}]];
  ent = SelectFirst[cls, #["ClassID"] == cid &];
  A = Which[
    cid === 79,
    Module[{wt = -t (1 + t + v)/(1 + t)},
     Together[(ent["RepAw"] /. w -> wt) D[wt, t] /. {v -> y0, t -> x}]],
    True,
    Module[{vx = Global`xx y, wx = (1 - Global`xx) (1 - y)},
     Together[((ent["RepAv"] /. {v -> vx, w -> wx}) y -
        (ent["RepAw"] /. {v -> vx, w -> wx}) (1 - y)) /.
       {y -> y0, Global`xx -> x}]]];
  A = Together[A]; Ttot = IdentityMatrix[4];
  (* Fuchsify finite then infinity *)
  Module[{dnsF, TF},
   dnsF = DeleteDuplicates[Flatten[Table[
      Select[First /@ Rest[FactorList[Denominator[Together[A[[i, j]]]]]],
        Exponent[#, x] >= 1 &], {i, 4}, {j, 4}]]];
   TF = Quiet@Check[Libra`Fuchsify[A, x, dnsF], $Failed];
   If[MatrixQ[TF],
    A = Together[Inverse[TF] . A . TF - Inverse[TF] . D[TF, x]];
    Ttot = Together[Ttot . TF]]];
  Module[{xi = Global`xi, Axi, TF},
   Axi = Together[-(A /. x -> 1/xi)/xi^2];
   TF = Quiet@Check[Libra`Fuchsify[Axi, xi, {xi}], $Failed];
   If[MatrixQ[TF],
    Axi = Together[Inverse[TF] . Axi . TF - Inverse[TF] . D[TF, xi]];
    A = Together[-(Axi /. xi -> 1/x)/x^2];
    Ttot = Together[Ttot . (TF /. xi -> 1/x)]]];
  (* balance descent *)
  Module[{poles, resAt, resInf, ipart, spectra, offsets, intQ, badn,
    apply, pairProj, sp},
   poles[Am_] := DeleteDuplicates[Flatten[Table[
      (-Coefficient[#, x, 0]/Coefficient[#, x, 1]) & /@
        Select[First /@ Rest[FactorList[Denominator[Together[Am[[i, j]]]]]],
          Exponent[#, x] == 1 &], {i, 4}, {j, 4}]]];
   resAt[Am_, x0_] := Together[(Cancel[Together[(x - x0) Am]]) /. x -> x0];
   resInf[Am_] := Table[Together[-SeriesCoefficient[
      Series[Am[[i, j]], {x, Infinity, 1}], 1]], {i, 4}, {j, 4}];
   ipart[e_] := Together[e /. eps -> 0];
   spectra[Am_] := Append[
     Table[{p, Eigenvalues[resAt[Am, p]]}, {p, poles[Am]}],
     {Infinity, Eigenvalues[resInf[Am]]}];
   offsets[spp_] := Flatten[Table[
     {spp[[k, 1]], #} & /@ Select[spp[[k, 2]], ipart[#] =!= 0 &],
     {k, Length[spp]}], 1];
   intQ[spp_] := AllTrue[Flatten[spp[[All, 2]]], IntegerQ[ipart[#]] &];
   badn[spp_] := Total[Abs[ipart[#[[2]]]] & /@ offsets[spp]];
   apply[Am_, T_] := Together[Inverse[T] . Am . T - Inverse[T] . D[T, x]];
   pairProj[R1_, l1_, R2_, l2_] := Module[{vv, uu, ip, best = $Failed},
     vv = NullSpace[R1 - l1 IdentityMatrix[4]];
     uu = NullSpace[Transpose[R2 - l2 IdentityMatrix[4]]];
     If[vv === {} || uu === {}, Return[$Failed]];
     Do[ip = Together[uu[[j]] . vv[[i]]];
      If[ip =!= 0, best = Together[Transpose[{vv[[i]]}] . {uu[[j]]}/ip];
       Break[]], {i, Length[vv]}, {j, Length[uu]}];
     best];
   sp = spectra[A];
   Do[Module[{off = offsets[sp], neg, tgt, lam, bad, improved = False},
     If[off === {}, Break[]];
     neg = First[SortBy[off, ipart[#[[2]]] &]];
     {tgt, lam} = neg; bad = badn[sp];
     Module[{R1 = If[tgt === Infinity, resInf[A], resAt[A, tgt]],
       partners = DeleteDuplicates[Append[
         DeleteCases[sp[[All, 1]], tgt], Infinity]]},
      Do[If[! improved,
        Module[{R2 = If[p2 === Infinity, resInf[A], resAt[A, p2]]},
         Do[If[! improved,
           Module[{P = pairProj[R1, lam, R2, lam2], T, A2, sp2, b2},
            If[P =!= $Failed,
             T = Which[
               tgt === Infinity, Libra`Balance[P, {x, Infinity, p2}],
               p2 === Infinity, Libra`Balance[P, {x, tgt, Infinity}],
               True, Libra`Balance[P, {x, tgt, p2}]];
             A2 = apply[A, T]; sp2 = spectra[A2];
             b2 = If[intQ[sp2], badn[sp2], Infinity];
             If[b2 < bad,
              A = A2; Ttot = Together[Ttot . T]; sp = sp2;
              improved = True]]]],
          {lam2, DeleteDuplicates[Eigenvalues[R2]]}]]],
       {p2, partners}]];
     If[! improved, Break[]]],
    {it, 1, 40}]];
  (* CANONICA finish *)
  Module[{mats, bnd, res, T2, An},
   mats = {A} /. (sy_Symbol /; SymbolName[sy] === "eps") :> CANONICA`eps;
   bnd = CANONICA`SectorBoundariesFromDE[mats];
   res = Quiet@CANONICA`RecursivelyTransformSectors[mats, {x}, bnd,
     {1, Length[bnd]},
     CANONICA`TDeltaNumeratorDegree -> 2,
     CANONICA`TDeltaDenominatorDegree -> 2,
     CANONICA`DDeltaNumeratorDegree -> 2,
     CANONICA`DDeltaDenominatorDegree -> 2];
   If[! (ListQ[res] && Length[res] >= 2 && res[[1]] =!= False),
    Return[<|"Tag" -> {cid, ystr}, "Status" -> "CANONICAFailed"|>]];
   T2 = res[[1]];
   An = (If[ListQ[res[[2]]], res[[2, 1]], res[[2]]]) /.
     (sy_Symbol /; SymbolName[sy] === "eps") :> Global`eps;
   ok = AllTrue[Flatten[An], FreeQ[Cancel[Together[#/eps]], eps] &];
   If[! ok, Return[<|"Tag" -> {cid, ystr}, "Status" -> "NotEpsForm"|>]];
   HCTPut[<|"Class" -> cid, "Y0" -> y0, "Anew" -> An,
     "Ttot" -> Ttot, "T2" -> T2|>,
     FileNameJoin[{here, "canonical_slice_c" <> ToString[cid] <>
       "_y" <> ytag <> ".wl"}]];
   <|"Tag" -> {cid, ystr}, "Status" -> "EPSFORM",
     "Letters" -> DeleteDuplicates[Select[Flatten[Map[
        First /@ Rest[FactorList[Denominator[Together[#]]]] &,
        Map[Cancel[Together[#/eps]] &, An, {2}], {2}]],
        ! FreeQ[#, x] &]]|>]];

missions = Join[{{97, "3/7"}},
  Flatten[Table[{c, ys}, {c, {97, 77}},
    {ys, {"5/11", "2/9", "7/13", "4/5", "1/6", "9/14", "5/8", "3/10", "8/17"}}], 1]];
LaunchKernels[4];
With[{lb = "/home/maxzhang/factorization-and-loops/Addon/Mathematica_Addon/Libra/Source/Libra.m",
  cn = "/home/maxzhang/factorization-and-loops/Addon/Mathematica_Addon/CANONICA/src/CANONICA.m",
  tkf = FileNameJoin[{root, "Scripts", "HardClassToolkit.wl"}], hh = here},
 ParallelEvaluate[Get[tkf]; SetDirectory[hh];
  Quiet[Block[{Print = (Null &)}, Get[lb]; Get[cn]], {General::shdw}]]];
DistributeDefinitions[sliceMission, here];
results = HCTMissionPool[missions, sliceMission, "Kernels" -> 4,
  "Progress" -> Function[{res, remaining, elapsed},
    Print["POOL ", res["Tag"], " -> ", res["Status"],
      If[KeyExistsQ[res, "Letters"],
        " " <> ToString[InputForm[res["Letters"]]], ""],
      " | remaining=", remaining, " elapsed=", Round[elapsed], "s"]]];
Print["DONE"];
