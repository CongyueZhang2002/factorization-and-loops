(* Probe of the diagonal-block finite-field route on one certified hard
   class.  Arg 1: class id (97, 77, 79).  Arg 2: output directory.
   Stages are timed and persisted separately (slice, solve, completion,
   gate) so a failure leaves its evidence.  The stored certified form is
   the ORACLE: the new T must differ from the stored one by a constant
   invertible matrix, and letters / residue eigenvalue lists must agree. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
cid = ToExpression[$ScriptCommandLine[[2]]];
out = $ScriptCommandLine[[3]];
If[! DirectoryQ[out], CreateDirectory[out, CreateIntermediateDirectories -> True]];
x = Global`x; y = Global`y; eps = Global`eps;
oracle = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "HardClasses", "EpsFormRoute",
  "c" <> ToString[cid] <> "_epsform_two_variable.wl"}]];
If[! AssociationQ[oracle], Print["oracle unreadable"]; Exit[1]];
(* the oracle's Ax/Ay are the GATED epsilon forms; the source is the
   class representative pulled back to the chart *)
cls = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "BlockClasses", "classes.wl"}]];
ent = SelectFirst[cls, #["ClassID"] == cid &];
v = Global`v; w = Global`w; xx = Global`xx;
sub = If[cid === 79, {v -> -xx y, w -> (1 - xx) (1 - y)}, {v -> xx y, w -> (1 - xx) (1 - y)}];
sv = If[cid === 79, -xx y, xx y]; sw = (1 - xx) (1 - y);
ax = Map[Cancel[Together[#]] &, ((ent["RepAv"] /. sub) D[sv, xx] + (ent["RepAw"] /. sub) D[sw, xx]) /. xx -> x, {2}];
ay = Map[Cancel[Together[#]] &, ((ent["RepAv"] /. sub) D[sv, y] + (ent["RepAw"] /. sub) D[sw, y]) /. xx -> x, {2}];
Print["source denominators: ", DeleteDuplicates[Flatten[First /@ Rest[FactorList[Denominator[#]]] & /@ Flatten[Join[ax, ay]]]]];
Print["class ", cid, ": block dimension ", Length[ax]];
put[expr_, name_] := FeynFacet`FamilyArtifactWrite[expr,
  FileNameJoin[{out, "c" <> ToString[cid] <> "_" <> name <> ".wl"}]];
stamp[label_, t0_] := Print["[", label, "] ", Round[AbsoluteTime[] - t0, 0.1], " s"];

t0 = AbsoluteTime[];
slice = FeynFacet`DiagonalBlockSliceEpsForm[{ax, ay}, {x, y}, eps, "Verbose" -> True];
stamp["slice", t0];
Print["slice status: ", slice["Status"], "  balances: ", Lookup[slice, "BalanceCount", "-"],
  "  slice point: ", Lookup[slice, "SlicePoint", "-"]];
put[slice, "slice"];
If[slice["Status"] =!= "OK", Print[slice]; Exit[2]];
Print["letters: ", slice["Letters"]];
Print["slice letters: ", slice["SliceLetters"]];
Print["slice residue ranks: ", MatrixRank /@ slice["SliceResidues"]];
Print["slice residue eigenvalues: ", Sort[Eigenvalues[#]] & /@ slice["SliceResidues"]];

t0 = AbsoluteTime[];
solve = FeynFacet`SolveDiagonalBlockBasisTransformationFiniteField[{ax, ay}, {x, y}, eps, slice, "Verbose" -> True];
stamp["solve", t0];
Print["solve status: ", solve["Status"]];
put[solve, "solve"];
If[solve["Status"] =!= "Solved", Print[KeyDrop[solve, "Transformation"]]; Exit[3]];
Print["solve: ", KeyDrop[solve, {"Transformation", "SliceResidues", "Letters", "SliceLetters"}]];

t0 = AbsoluteTime[];
completion = FeynFacet`CompleteDiagonalBlockEpsForm[{ax, ay}, {x, y}, eps, solve];
stamp["completion", t0];
Print["completion status: ", completion["Status"]];
put[completion, "completion"];
If[completion["Status"] =!= "OK", Print[completion]; Exit[4]];
Print["scalar gauge: ", completion["ScalarBasisTransformationFactor"]];
Print["final letters: ", completion["Letters"]];

t0 = AbsoluteTime[];
gate = FeynFacet`CertifyDiagonalBlockEpsForm[{ax, ay}, {x, y}, eps,
  completion["Transformation"], completion["Letters"], completion["Residues"]];
stamp["gate", t0];
Print["gate: ", KeyDrop[gate, "EpsForm"]];
put[Join[completion, <|"Gate" -> KeyDrop[gate, "EpsForm"], "EpsForm" -> gate["EpsForm"]|>], "certified"];

(* oracle comparison *)
t0 = AbsoluteTime[];
Tnew = completion["Transformation"]; Told = oracle["T"];
conj = Map[Cancel[Together[#]] &, Inverse[Told] . Tnew, {2}];
Print["ORACLE: T_old^-1 T_new constant: ", FreeQ[conj, x | y],
  "   invertible: ", ! TrueQ[Together[Det[conj]] === 0]];
sameLetters[a_, b_] := NumberQ[Cancel[Together[a/b]]];
Print["ORACLE: letters match: ",
  Sort[ToString /@ completion["Letters"]] === Sort[ToString /@ oracle["Letters"]] ||
  (Length[completion["Letters"]] === Length[oracle["Letters"]] &&
   AllTrue[completion["Letters"], Function[l, AnyTrue[oracle["Letters"], sameLetters[l, #] &]]])];
evs[res_, lets_] := Sort[Table[{ToString[lets[[i]]], Sort[Eigenvalues[res[[i]]]]}, {i, Length[lets]}]];
newE = Table[With[{l = completion["Letters"][[i]]},
  {First[Select[oracle["Letters"], sameLetters[l, #] &], l], Sort[Eigenvalues[completion["Residues"][[i]]]]}],
  {i, Length[completion["Letters"]]}];
oldE = Table[{oracle["Letters"][[i]], Sort[Eigenvalues[oracle["Residues"][[i]]]]}, {i, Length[oracle["Letters"]]}];
Print["ORACLE: residue eigenvalues match: ", Sort[ToString /@ newE] === Sort[ToString /@ oldE]];
stamp["oracle", t0];
Print["LeafCount T_new ", LeafCount[Tnew], "  T_old ", LeafCount[Told]];
Print["DONE"];
