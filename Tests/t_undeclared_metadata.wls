(* Generality audit F5 (typed-refusal half, 2026-08-23): an UNDECLARED
   class whose matrices are not in the documented {v, w} convention is a
   typed refusal, never a silent {v, w} run; the {v, w} default survives
   only when the matrices verify against it; regulator detection
   distinguishes regulator-free (valid, flagged) from ambiguous (typed
   refusal). *)
root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
rv = FeynFacet`Private`canonicalBlocksResolveVariables;
dr = FeynFacet`Private`canonicalBlocksDetectRegulator;
v = Global`v; w = Global`w; eps = Global`eps;
Clear[Global`a, Global`b, Global`ep, Global`Epsilon];
(* verified default: v,w matrices pass; foreign symbols refuse typed *)
check["undeclared {v,w} matrices keep the convention default",
  rv[Automatic, {{{1/(v + w)}}, {{eps/v}}}] === {v, w}];
check["constant matrices keep the convention default",
  rv[Automatic, {{{2}}, {{3}}}] === {v, w}];
check["undeclared foreign matrices are a typed refusal",
  Module[{r = rv[Automatic, {{{1/(Global`a + Global`b)}}, {{Global`ep/Global`a}}}]},
    AssociationQ[r] && r["Status"] === "ClassVariablesUndeclared" &&
      MemberQ[r["FoundSymbols"], Global`a]]];
check["explicit variables always win",
  rv[{Global`a, Global`b}, {{{1/(v + w)}}}] === {Global`a, Global`b}];
check["no-expression callers keep the historical default",
  rv[Automatic] === {v, w}];
(* regulator: free vs unique vs ambiguous *)
check["regulator-free detection returns None",
  dr[{{{1/(v + w)}}}, {v, w}] === None];
check["unique regulator detected",
  dr[{{{eps/(v + w)}}}, {v, w}] === eps];
check["ambiguous regulator is $Failed",
  dr[{{{eps/(v + w) + Global`Epsilon v}}}, {v, w}] === $Failed];
(* campaign-level typed statuses *)
rec[m_] := <|"ClassID" -> 999, "RepAv" -> m, "RepAw" -> m|>;
cr = FeynFacet`Private`diagonalBlockClassRecord;
r1 = cr[rec[{{Global`a/(1 + Global`b)}}], Automatic, 60, None, False];
check["undeclared foreign class record refused typed",
  AssociationQ[r1] && r1["Status"] === "ClassVariablesUndeclared"];
r2 = cr[rec[{{eps/(1 + v) + Global`Epsilon w}}], Automatic, 60, None, False];
check["ambiguous-regulator class record refused typed",
  AssociationQ[r2] && r2["Status"] === "RegulatorAmbiguous"];
(* the zero block is the minimal genuine regulator-free representative
   (the project's regulator-free classes certify the same way) *)
r3 = cr[rec[{{0}}], Automatic, 60, None, False];
check["regulator-free class record proceeds and is flagged",
  AssociationQ[r3] && r3["Status"] =!= "RegulatorAmbiguous" &&
    r3["Status"] =!= "ClassVariablesUndeclared" &&
    TrueQ[Lookup[r3, "RegulatorFree", False]]];
Print["t_undeclared_metadata: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
