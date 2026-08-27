(* The hard classes (97 = CF258_B9, 77 = CF230_B1, 79 = CF231_B1) and
   their two-variable eps-forms.

   These three classes are the ones the conic-chart canonicalizer cannot
   reach: their square root is rationalized only by a TWO-variable chart
   (v, w) -> (x, y), so their ClassForms records carry a chart of kind
   "TwoVariable" and their EpsForm lives in (x, y), not (v, w).

   Acceptance criteria (each is one assertion below, and each is checked
   by RECOMPUTATION from the class representative in
   Results/UU_08_10_canonical/BlockClasses/classes.wl -- never from a
   stored flag):

   A. Schema.  The record carries ClassID, RepFamily, RepRows, Dim,
      Transformation, EpsForm, Variables, Chart, AnsatzDegree,
      Validated, and its Chart is an Association of kind "TwoVariable"
      carrying Subst, Root, RootSquare, Inverse and Variables.
   B. Chart identity.  The chart's RootSquare pulled back through Subst
      equals Root^2 EXACTLY (this is the statement that the chart
      rationalizes the block's square root).
   C. Gate in x.  With A_x built from the ORIGINAL class representative
      by the chain rule through Subst, and T the record's stored
      Transformation,
          T^-1 A_x T - T^-1 d_x T  ==  EpsForm[[1]]     entrywise, exactly.
   D. Gate in y.  The same in the second chart variable.
   E. The form is an eps-form: EpsForm/eps is free of eps.
   F. ValidateCanonicalForm re-derives the dlog letters and constant
      residues from the matrices and returns True.
   G. Flatness of the stored eps-form pair.

   A class whose artifact is absent is reported as NOT PERFORMABLE and
   fails the suite: an unfinished class stays red (house rule), it is
   never skipped silently. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

xx = Symbol["Global`x"]; yy = Symbol["Global`y"];
vv = Symbol["Global`v"]; ww = Symbol["Global`w"];
epsG = Symbol["Global`eps"];

dataRoot = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
formDir = FileNameJoin[{dataRoot, "ClassForms"}];
classFile = FileNameJoin[{dataRoot, "BlockClasses", "classes.wl"}];

tog[m_] := Map[Together, m, {2}];
zeroM[m_] := AllTrue[Flatten[tog[m]], # === 0 &];

(* Boundary normalization (repository trap list): ValidateCanonicalForm loads
   CANONICA, which puts CANONICA` on $ContextPath; every LATER Get in this
   kernel would then read a bare `eps` (or x, y, v, w) as the package's symbol
   and the exact comparisons below would silently fail.  Normalize every read
   artifact by SymbolName, never by symbol identity. *)
normalizeSymbols[expr_] := expr /. (s_Symbol /; MemberQ[{"eps", "x", "y", "v", "w"}, SymbolName[s]] &&
    Context[s] =!= "Global`" :> Symbol["Global`" <> SymbolName[s]]);

If[! FileExistsQ[classFile],
  Print["FAIL  missing repository input: ", classFile]; Exit[1]];
classes = normalizeSymbols[Get[classFile]];

hardClasses = {97, 77, 79};

Do[
 Module[{file, rec, ent, chart, subst, ax, ay, t, ti, gx, gy, ok},
  file = FileNameJoin[{formDir, "class" <> ToString[cid] <> ".wl"}];
  If[! FileExistsQ[file],
   FTAssert["class " <> ToString[cid] <> " A. ledger record exists (" <> file <> ")", False];
   Continue[]];
  rec = normalizeSymbols[Get[file]];
  FTAssert["class " <> ToString[cid] <> " A. record carries the ClassForms schema with a TwoVariable chart",
   AssociationQ[rec] &&
    AllTrue[{"ClassID", "RepFamily", "RepRows", "Dim", "Transformation",
      "EpsForm", "Variables", "Chart", "AnsatzDegree", "Validated"}, KeyExistsQ[rec, #] &] &&
    AssociationQ[rec["Chart"]] && rec["Chart"]["Kind"] === "TwoVariable" &&
    AllTrue[{"Subst", "Root", "RootSquare", "Inverse", "Variables"},
      KeyExistsQ[rec["Chart"], #] &] &&
    rec["Variables"] === {xx, yy} && rec["ClassID"] === cid];

  chart = rec["Chart"]; subst = chart["Subst"];
  FTAssert["class " <> ToString[cid] <> " B. chart RootSquare pulls back to Root^2 exactly",
   Together[(chart["RootSquare"] /. subst) - chart["Root"]^2] === 0];

  ent = SelectFirst[classes, #["ClassID"] == cid &];
  If[! AssociationQ[ent],
   FTAssert["class " <> ToString[cid] <> " C. class representative found in classes.wl", False];
   Continue[]];
  FTAssert["class " <> ToString[cid] <> " A'. record RepFamily/RepRows/Dim agree with classes.wl",
   rec["RepFamily"] === ent["RepFamily"] && rec["RepRows"] === ent["RepRows"] &&
    rec["Dim"] === ent["Dim"]];

  (* chain rule through the stored chart: A_x = Av dv/dx + Aw dw/dx *)
  ax = tog[(ent["RepAv"] /. subst) D[vv /. subst, xx] + (ent["RepAw"] /. subst) D[ww /. subst, xx]];
  ay = tog[(ent["RepAv"] /. subst) D[vv /. subst, yy] + (ent["RepAw"] /. subst) D[ww /. subst, yy]];
  t = rec["Transformation"]; ti = tog[Inverse[t]];
  gx = zeroM[ti . ax . t - ti . D[t, xx] - rec["EpsForm"][[1]]];
  gy = zeroM[ti . ay . t - ti . D[t, yy] - rec["EpsForm"][[2]]];
  FTAssert["class " <> ToString[cid] <> " C. GATE x: T^-1 A_x T - T^-1 d_x T == EpsForm[[1]] exactly, from the class representative", gx];
  FTAssert["class " <> ToString[cid] <> " D. GATE y: T^-1 A_y T - T^-1 d_y T == EpsForm[[2]] exactly, from the class representative", gy];

  FTAssert["class " <> ToString[cid] <> " E. EpsForm/eps is free of eps (it is an eps-form)",
   AllTrue[Flatten[rec["EpsForm"]], FreeQ[Together[#/epsG], epsG] &]];

  ok = FeynFacet`ValidateCanonicalForm[rec, "Variables" -> {xx, yy}, "Regulator" -> epsG];
  FTAssert["class " <> ToString[cid] <> " F. ValidateCanonicalForm re-derives dlog letters with constant residues",
   TrueQ[ok]];

  FTAssert["class " <> ToString[cid] <> " G. the stored eps-form pair is flat",
   zeroM[D[rec["EpsForm"][[1]], yy] - D[rec["EpsForm"][[2]], xx] +
     rec["EpsForm"][[1]] . rec["EpsForm"][[2]] - rec["EpsForm"][[2]] . rec["EpsForm"][[1]]]]],
 {cid, hardClasses}];

FTReport[];
