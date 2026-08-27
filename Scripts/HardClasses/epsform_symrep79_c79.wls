(* class 79: symbolic-y REPLAY of a balance path recorded on a numeric
   slice (pattern: Scripts/HardClasses/symrep97.wls).  Each step re-derives the Lee
   subspaces from the SYMBOLIC residues at the same locus and selects the
   same towers by the recorded mask, so the projectors are symbolic and
   the integer-part choices are the recorded ones.
   Arg 1: recorded path file (from lee79b.wls on a slice)
   Arg 2: tag *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
R = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical";
here = FileNameJoin[{R, "HardClasses", "EpsFormRoute"}];
x = Global`x; y = Global`y; eps = Global`eps; v = Global`v; w = Global`w;
pathFile = $ScriptCommandLine[[2]]; tag = $ScriptCommandLine[[3]];
Quiet[Block[{Print = (Null &)},
   Get[root <> "/Addon/Mathematica_Addon/Libra/Source/Libra.m"]], {General::shdw}];
Off[OptionValue::optnf];
tog[m_] := Map[Cancel[Together[#]] &, m, {2}];
ipart[e_] := Cancel[Together[e /. eps -> 0]];
putAtomic[expr_, file_] := Module[{tmp = file <> ".tmp"}, Put[expr, tmp]; RenameFile[tmp, file, OverwriteTarget -> True]];
cls = Get[R <> "/BlockClasses/classes.wl"];
e79 = SelectFirst[cls, #["ClassID"] == 79 &];
xx = Global`xx; sub = {v -> -xx y, w -> (1 - xx) (1 - y)};
A = tog[((e79["RepAv"] /. sub) (-y) - (e79["RepAw"] /. sub) (1 - y)) /. xx -> x];
xa = Together[-(3 y + 5 eps y - 2 eps)/(3 + 5 eps)];
symLoci = {0, 1, y, 1 - y, 2 - y, xa, Infinity};
symNames = {"0", "1", "y", "1-y", "2-y", "xa", "Infinity"};
rec = Get[pathFile]; path = rec["Path"];
Print["=== symbolic-y replay of ", Length[path], " balances recorded at y0 = ", InputForm[rec["Y"]], " ==="];
resAt[Am_, r_] := tog[Cancel[Together[(x - r) Am]] /. x -> r];
resInf[Am_] := Table[Together[-SeriesCoefficient[Series[Am[[i, j]], {x, Infinity, 1}], 1]], {i, 4}, {j, 4}];
prank[Am_, p_] := PoincareRank[Am, {x, p}];
specOf[Am_] := Table[Module[{p = symLoci[[k]], r = prank[Am, symLoci[[k]]]},
    {symNames[[k]], r, If[r > 0, "PRANK>0", If[r < 0, "regular",
      Together /@ Eigenvalues[If[p === Infinity, resInf[Am], resAt[Am, p]]]]]}], {k, Length[symLoci]}];
showSpec[s_] := Do[Print["   ", e[[1]], "  prank=", e[[2]], "  spec ", InputForm[e[[3]]]], {e, s}];
normQ[s_] := AllTrue[s, #[[2]] <= 0 &] && AllTrue[Flatten[Select[#[[3]] & /@ s, ListQ]],
   Together[ipart[#]] === 0 &];
idx[name_] := FirstPosition[symNames, name][[1]];

t0 = AbsoluteTime[];
Print["initial spectra (y symbolic):"]; showSpec[specOf[A]];
Ttot = IdentityMatrix[4]; ok = True;
Do[Module[{st = path[[n]], li, ri, left, right, uu, vv2, P, T},
  li = idx[st[[1]]]; ri = idx[st[[3]]];
  left = Quiet@GetSubspaces[A, {x, symLoci[[li]]}, eps, Left];
  right = Quiet@GetSubspaces[A, {x, symLoci[[ri]]}, eps, Right];
  If[Length[left] =!= Length[st[[2]]] || Length[right] =!= Length[st[[4]]],
   Print["step ", n, ": TOWER COUNT MISMATCH  left ", Length[left], " vs mask ", st[[2]],
     "   right ", Length[right], " vs mask ", st[[4]]]; ok = False; Break[]];
  uu = Flatten[Pick[left, st[[2]], 1], 1];
  vv2 = Flatten[Pick[right, st[[4]], 1], 1];
  P = Quiet@Projector[uu, vv2];
  If[! MatrixQ[P] || Union @@ P === {0},
   Print["step ", n, ": PROJECTOR FAILED (zero or not a matrix)"]; ok = False; Break[]];
  T = tog[Balance[P, {x, symLoci[[li]], symLoci[[ri]]}]];
  A = tog[Inverse[T] . A . T - Inverse[T] . D[T, x]];
  Ttot = tog[Ttot . T];
  Print["step ", n, ": raise ", st[[1]], " mask ", st[[2]], " / lower ", st[[3]], " mask ", st[[4]],
    "   (", Round[AbsoluteTime[] - t0, .1], " s)  LeafCount[A]=", LeafCount[A]];
  showSpec[specOf[A]]],
 {n, Length[path]}];
sp = specOf[A];
Print["final spectra (y symbolic; normalized: ", normQ[sp], "):"]; showSpec[sp];
Print["replay clean: ", ok, "   wall ", Round[AbsoluteTime[] - t0, .1], " s"];
If[ok && normQ[sp],
 putAtomic[<|"A" -> A, "Ttot" -> Ttot, "Path" -> path, "Spectra" -> sp,
    "Provenance" -> "symbolic-y replay of the slice balance path (symrep79 pattern); Libra GetSubspaces/Projector/Balance, Off[OptionValue::optnf]"|>,
   here <> "/symnorm_c79.wl"];
 Print[">>> saved symnorm_c79.wl"]];
Print["DONE"];
