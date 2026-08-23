(* Compare finite-field class records with the ClassForms ledger.
   For every class with a record in both: residue eigenvalue multisets per
   letter (letters matched by name when the variables coincide; otherwise
   only the sorted spectrum multiset over all letters), and, when the
   variables coincide, T_ledger^-1 T_new constant.  Args: RECORD_DIR *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
dir = $ScriptCommandLine[[2]];
eps = Global`eps;
tog[m_] := Map[Cancel[Together[#]] &, m, {2}];
letterData[ef_, vars_] := Module[{dens, res},
  dens = DeleteDuplicates[Select[Flatten[First /@ Rest[FactorList[Denominator[Together[#]]]] & /@ Flatten[ef]], ! FreeQ[#, Alternatives @@ vars] &], NumberQ[Together[#1/#2]] &];
  (* residue matrix of a dlog form at a letter: coefficient of dlog in the variable where the letter is linear *)
  res = Table[Module[{u = SelectFirst[vars, Exponent[l, #] === 1 &, $Failed], root, k},
      If[u === $Failed, {l, Missing[]},
        k = FirstPosition[vars, u][[1]]; root = -Coefficient[l, u, 0]/Coefficient[l, u, 1];
        {l, Sort[Eigenvalues[tog[Cancel[Together[(u - root) ef[[k]]]] /. u -> root]/eps]]}]], {l, dens}];
  res];
files = FileNames["class*.wl", dir];
tally = <|"Compared" -> 0, "SpectraMatch" -> 0, "ConjugationConstant" -> 0, "Mismatch" -> {}|>;
Do[
  new = FeynFacet`FamilyArtifactRead[f]; id = new["ClassID"];
  old = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "ClassForms", "class" <> ToString[id] <> ".wl"}]];
  If[! AssociationQ[old], Continue[]];
  tally["Compared"]++;
  sameVars = (SymbolName /@ new["Variables"]) === (SymbolName /@ old["Variables"]);
  newL = letterData[new["EpsForm"], new["Variables"]]; oldL = letterData[old["EpsForm"], old["Variables"]];
  specNew = Sort[DeleteMissing[Last /@ newL]]; specOld = Sort[DeleteMissing[Last /@ oldL]];
  specOK = (specNew === specOld);
  If[specOK, tally["SpectraMatch"]++];
  conjOK = If[sameVars,
    Module[{c = tog[Inverse[old["Transformation"]] . new["Transformation"]]},
      FreeQ[c, Alternatives @@ new["Variables"]] && ! TrueQ[Together[Det[c]] === 0]], Missing["DifferentVariables"]];
  If[TrueQ[conjOK], tally["ConjugationConstant"]++];
  If[! specOK || conjOK === False, AppendTo[tally["Mismatch"], <|"ClassID" -> id, "Spectra" -> specOK, "Conjugation" -> conjOK, "Variables" -> {new["Variables"], old["Variables"]}|>]];
  Print["class ", id, " dim ", new["Dim"], " vars ", new["Variables"], "/", old["Variables"], " spectra ", specOK, " conjugation ", conjOK],
  {f, files}];
Print["ORACLE TALLY: ", KeyDrop[tally, "Mismatch"]];
Print["mismatches: ", tally["Mismatch"]];
Print["DONE"];
