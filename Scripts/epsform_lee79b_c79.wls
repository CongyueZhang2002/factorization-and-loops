(* class 79 Lee loop, v2: same search as v1 but
     - points with prank < 0 are dropped from the census each step,
     - the Poincare-rank>0 points are tried FIRST as the raise point
       (Fuchsify before normalize), which keeps the entries small,
     - per-point GetSubspaces timing is printed (v1 stalled with no
       visibility into which point was expensive),
     - entries are Cancel[Together[.]]-reduced after every balance.
   Arg 1: y value ("sym" or a rational)   Arg 2: tag *)
root = "/home/maxzhang/factorization-and-loops";
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
here = "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/HardClasses/EpsFormRoute";
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
yarg = $ScriptCommandLine[[2]]; tag = $ScriptCommandLine[[3]];
Quiet[Block[{Print = (Null &)},
   Get[root <> "/Addon/Mathematica_Addon/Libra/Source/Libra.m"]], {General::shdw}];
Off[OptionValue::optnf];   (* else Check inside Projector returns a ZERO matrix *)
tog[m_] := Map[Cancel[Together[#]] &, m, {2}];
ipart[e_] := Cancel[Together[e /. eps -> 0]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
cls = Get[R <> "/BlockClasses/classes.wl"];
e79 = SelectFirst[cls, #["ClassID"] == 79 &];
xx = Global`xx; sub = {v -> -xx y, w -> (1 - xx) (1 - y)};
Axs = tog[((e79["RepAv"] /. sub) (-y) - (e79["RepAw"] /. sub) (1 - y)) /. xx -> x];
xa = Together[-(3 y + 5 eps y - 2 eps)/(3 + 5 eps)];
symLoci = {0, 1, y, 1 - y, 2 - y, xa, Infinity};
symNames = {"0", "1", "y", "1-y", "2-y", "xa", "Infinity"};
yv = If[yarg === "sym", y, ToExpression[yarg]];
allPoints = symLoci /. y -> yv;
A = tog[Axs /. y -> yv];
Print["=== class 79 Lee loop v2, y = ", InputForm[yv], " ==="];
resAt[Am_, r_] := tog[Cancel[Together[(x - r) Am]] /. x -> r];
resInf[Am_] := Table[Together[-SeriesCoefficient[Series[Am[[i, j]], {x, Infinity, 1}], 1]], {i, 4}, {j, 4}];
prank[Am_, p_] := PoincareRank[Am, {x, p}];
specOf[Am_] := Table[Module[{p = allPoints[[k]], r = prank[Am, allPoints[[k]]]},
    {symNames[[k]], r, If[r > 0, "PRANK>0", If[r < 0, "regular",
      Together /@ Eigenvalues[If[p === Infinity, resInf[Am], resAt[Am, p]]]]]}], {k, Length[allPoints]}];
showSpec[s_] := Do[Print["   ", e[[1]], "  prank=", e[[2]], "  spec ", InputForm[e[[3]]]], {e, s}];
normQ[s_] := AllTrue[s, #[[2]] <= 0 &] && AllTrue[Flatten[Select[#[[3]] & /@ s, ListQ]],
   Together[ipart[#]] === 0 &];
combos[lens_] := Module[{n = Length[lens]},
  If[n === 0, {}, ({#, Total[Pick[lens, #, 1]]} &[IntegerDigits[#, 2, n]]) & /@ (Range[2^n] - 1)]];

t0 = AbsoluteTime[];
sp = specOf[A];
Print["initial spectra (normalized: ", normQ[sp], "):"]; showSpec[sp];

leeStep[Am_, sp_] := Module[{act, left, right, leftss, rightss, tt},
  act = Select[Range[Length[allPoints]], sp[[#, 2]] >= 0 &];
  left = <||>; right = <||>;
  Do[tt = AbsoluteTime[];
     left[k] = Quiet@GetSubspaces[Am, {x, allPoints[[k]]}, eps, Left];
     right[k] = Quiet@GetSubspaces[Am, {x, allPoints[[k]]}, eps, Right];
     Print["      subspaces at ", symNames[[k]], ": L", Length /@ left[k], " R", Length /@ right[k],
       "  (", Round[AbsoluteTime[] - tt, .1], " s)"], {k, act}];
  leftss = DeleteCases[Reverse@SortBy[Flatten[Table[
       {k, #[[1]], #[[2]]} & /@ combos[Length /@ left[k]], {k, act}], 1],
     {If[sp[[#[[1]], 2]] > 0, 1, 0] &, Last}], {_, _, 0}];
  rightss = DeleteCases[Reverse@SortBy[Flatten[Table[
       {k, #[[1]], #[[2]]} & /@ combos[Length /@ right[k]], {k, act}], 1], Last], {_, _, 0}];
  Catch[
   Do[Do[Module[{P, uu, vv},
       uu = Flatten[Pick[left[lss[[1]]], lss[[2]], 1], 1];
       vv = Flatten[Pick[right[rss[[1]]], rss[[2]], 1], 1];
       P = Quiet@Projector[uu, vv];
       If[MatrixQ[P] && Union @@ P =!= {0} && lss[[1]] =!= rss[[1]],
        Throw[{lss, rss, tog[Balance[P, {x, allPoints[[lss[[1]]]], allPoints[[rss[[1]]]]}]]}]]],
      {rss, Select[rightss, Last[#] === Last[lss] &]}], {lss, leftss}];
   $Failed]];

Ttot = IdentityMatrix[4]; path = {}; stat = "RUNNING";
Do[Module[{st, T, lss, rss, tt = AbsoluteTime[]},
  st = TimeConstrained[leeStep[A, sp], 1500, $TimedOut];
  If[st === $TimedOut, Print["step ", it, ": leeStep TIMED OUT"]; stat = "TIMEOUT"; Break[]];
  If[st === $Failed, Print["step ", it, ": no further balance found"]; stat = "NOBALANCE"; Break[]];
  {lss, rss, T} = st;
  A = tog[Inverse[T] . A . T - Inverse[T] . D[T, x]];
  Ttot = tog[Ttot . T];
  AppendTo[path, {symNames[[lss[[1]]]], lss[[2]], symNames[[rss[[1]]]], rss[[2]], lss[[3]]}];
  sp = specOf[A];
  Print["step ", it, ": raise ", symNames[[lss[[1]]]], " mask ", lss[[2]], " / lower ",
    symNames[[rss[[1]]]], " mask ", rss[[2]], "  rank ", lss[[3]],
    "   (step ", Round[AbsoluteTime[] - tt, .1], " s, total ", Round[AbsoluteTime[] - t0, .1],
    " s)   LeafCount[A]=", LeafCount[A]];
  showSpec[sp];
  putAtomic[<|"Class" -> 79, "Y" -> yv, "A" -> A, "Ttot" -> Ttot, "Path" -> path,
     "Spectra" -> sp, "Status" -> "PARTIAL", "SymLoci" -> symLoci, "SymNames" -> symNames|>,
    here <> "/lee_c79_" <> tag <> ".wl"];
  If[normQ[sp], Print[">>> NORMALIZED at step ", it]; stat = "NORMALIZED"; Break[]]],
 {it, 1, 60}];

sp = specOf[A];
Print["final spectra (normalized: ", normQ[sp], "):"]; showSpec[sp];
Print["status: ", stat, "   steps: ", Length[path], "   wall ", Round[AbsoluteTime[] - t0, .1], " s"];
Print["path: ", InputForm[path]];
Print["A denominators: ", InputForm[DeleteDuplicates[Flatten[
   First /@ Rest[FactorList[#]] & /@ Flatten[Denominator /@ A]]]]];
putAtomic[<|"Class" -> 79, "Y" -> yv, "A" -> A, "Ttot" -> Ttot, "Path" -> path,
   "Spectra" -> sp, "Status" -> stat, "SymLoci" -> symLoci, "SymNames" -> symNames|>,
  here <> "/lee_c79_" <> tag <> ".wl"];
Print["DONE"];
