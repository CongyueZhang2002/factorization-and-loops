(* Cross-chart oracle for a class solved in the conic t-chart while the
   ledger holds the Kallen (x,y) chart: both rationalize the same root,
   so t is a rational function of (x,y): from the conic chart's Root
   expression R(v,w,t) = sqrt(lambda) and the Kallen root x - y, solve
   R == +-(x - y) for t.  Pull the new eps-form back to (x,y) and compare
   letters and residue spectra with the ledger.  Args: CLASSID RECORD_DIR *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
cid = ToExpression[$ScriptCommandLine[[2]]]; dir = $ScriptCommandLine[[3]];
v = Global`v; w = Global`w; x = Global`x; y = Global`y; t = Global`t; eps = Global`eps;
tog[m_] := Map[Cancel[Together[#]] &, m, {2}];
new = FeynFacet`FamilyArtifactRead[FileNameJoin[{dir, "class" <> ToString[cid] <> ".wl"}]];
old = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "ClassForms", "class" <> ToString[cid] <> ".wl"}]];
chart = new["Chart"]; kallen = old["Chart"];
Print["new chart: ", chart]; Print["ledger chart: ", kallen["Subst"], " root ", kallen["Root"]];
(* the conic chart: Fixed v, w = image(t, v); its Root expression equals sqrt(q) *)
fixed = chart["Fixed"]; image = chart["Subst"][[2]]; rootT = chart["Root"];
sub = kallen["Subst"]; (* v -> ..., w -> ... in x, y *)
ef = new["EpsForm"]; (* {A_v, A_t} in (v, t) *)
spectra[form_, vars_] := Module[{dens},
  dens = DeleteDuplicates[Select[Flatten[First /@ Rest[FactorList[Denominator[Together[#]]]] & /@ Flatten[form]], ! FreeQ[#, Alternatives @@ vars] &], NumberQ[Together[#1/#2]] &];
  Sort[Table[Module[{u = SelectFirst[vars, Exponent[l, #] === 1 &, $Failed], r, k},
    If[u === $Failed, {ToString[l], Missing[]},
      k = FirstPosition[vars, u][[1]]; r = -Coefficient[l, u, 0]/Coefficient[l, u, 1];
      {ToString[l], Sort[Eigenvalues[tog[Cancel[Together[(u - r) form[[k]]]] /. u -> r]/eps]]}]], {l, dens}]]];
Do[
  (* t as a rational function of (x,y): solve rootT(v,w,t) == sign (x - y) with v, w in (x,y) *)
  sol = Solve[(rootT /. sub) == sign kallen["Root"] && w == (image /. sub /. t -> tt) /. v -> (v /. sub), tt];
  tsol = Quiet[Solve[(rootT /. {v -> (v /. sub), w -> (w /. sub)}) == sign kallen["Root"], t]];
  If[tsol === {}, Print["sign ", sign, ": no solution"]; Continue[]];
  tXY = Cancel[Together[t /. First[tsol]]];
  wCheck = Cancel[Together[(image /. {v -> (v /. sub), t -> tXY}) - (w /. sub)]];
  Print["sign ", sign, ": t(x,y) = ", tXY, "   chart consistency w == image: ", wCheck === 0];
  If[wCheck =!= 0, Continue[]];
  (* pull back: A_x = A_v dv/dx + A_t dt/dx etc. *)
  pulled = {tog[(ef[[1]] /. {v -> (v /. sub), t -> tXY}) D[v /. sub, x] + (ef[[2]] /. {v -> (v /. sub), t -> tXY}) D[tXY, x]],
            tog[(ef[[1]] /. {v -> (v /. sub), t -> tXY}) D[v /. sub, y] + (ef[[2]] /. {v -> (v /. sub), t -> tXY}) D[tXY, y]]};
  sNew = spectra[pulled, {x, y}]; sOld = spectra[old["EpsForm"], {x, y}];
  Print["  pulled-back letters/spectra: ", sNew];
  Print["  ledger letters/spectra:      ", sOld];
  Print["  MATCH: ", sNew === sOld],
  {sign, {1, -1}}];
Print["DONE"];
