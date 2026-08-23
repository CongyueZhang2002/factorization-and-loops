(* Re-run ONLY the oracle comparison of a stored certified diagonal-block
   record against the 2026-08-16 form.  Arg 1: class id.  Arg 2: record dir.
   (The first probe runs assigned to the Protected symbol C, which made
   the constancy check vacuous; caught by the watchdog 2026-08-21 04:10.) *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
cid = ToExpression[$ScriptCommandLine[[2]]]; dir = $ScriptCommandLine[[3]];
x = Global`x; y = Global`y; eps = Global`eps;
oracle = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "HardClasses", "EpsFormRoute", "c" <> ToString[cid] <> "_epsform_two_variable.wl"}]];
rec = FeynFacet`FamilyArtifactRead[FileNameJoin[{dir, "c" <> ToString[cid] <> "_certified.wl"}]];
Tnew = rec["Transformation"]; Told = oracle["T"];
conj = Map[Cancel[Together[#]] &, Inverse[Told] . Tnew, {2}];
Print["class ", cid, " ORACLE: T_old^-1 T_new constant (x,y-free): ", FreeQ[conj, x | y],
  "   eps-free: ", FreeQ[conj, eps], "   invertible: ", ! TrueQ[Together[Det[conj]] === 0]];
Print["conjugator: ", InputForm[conj]];
Print["DONE"];
