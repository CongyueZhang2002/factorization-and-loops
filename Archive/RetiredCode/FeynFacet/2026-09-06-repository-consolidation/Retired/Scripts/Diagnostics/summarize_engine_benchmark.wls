(* Summarize bench_CANONICA.wl and bench_FiniteField.wl (same class set,
   same input systems) into a Markdown table.  Arg 1: directory. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
dir = $ScriptCommandLine[[2]];
c = FeynFacet`FamilyArtifactRead[FileNameJoin[{dir, "bench_CANONICA.wl"}]];
f = FeynFacet`FamilyArtifactRead[FileNameJoin[{dir, "bench_FiniteField.wl"}]];
If[! ListQ[c], c = {}]; If[! ListQ[f], f = {}];
byId[list_] := Association[(#["ClassID"] -> #) & /@ list];
C1 = byId[c]; F1 = byId[f];
common = Intersection[Keys[C1], Keys[F1]];
Print["classes measured: CANONICA ", Length[c], ", FiniteField ", Length[f], ", common ", Length[common]];
stat[list_] := Counts[Lookup[list, "Status"]];
Print["CANONICA statuses: ", stat[c]];
Print["FiniteField statuses: ", stat[f]];
median[l_] := If[l === {}, 0, Median[l]];
lines = {"| dim | classes | CANONICA certified | CANONICA total s (median) | FF certified | FF total s (median) | FF slice s | FF solve s |", "|---|---|---|---|---|---|---|---|"};
Do[Module[{ids = Select[common, C1[#]["Dim"] === d &], cs, fs, cok, fok, slice, solve},
   If[ids === {}, Continue[]];
   cs = Lookup[C1 /@ ids, "Seconds"]; fs = Lookup[F1 /@ ids, "Seconds"];
   cok = Count[C1 /@ ids, a_ /; a["Status"] === "Certified"];
   fok = Count[F1 /@ ids, a_ /; a["Status"] === "Certified"];
   slice = Total[Cases[F1 /@ ids, a_ /; AssociationQ[a["Timing"]] :> a["Timing"]["SliceSeconds"]]];
   solve = Total[Cases[F1 /@ ids, a_ /; AssociationQ[a["Timing"]] :> a["Timing"]["SolveSeconds"]]];
   AppendTo[lines, "| " <> StringRiffle[ToString /@ {d, Length[ids], cok,
     ToString[Round[Total[cs], 0.1]] <> " (" <> ToString[Round[median[cs], 0.01]] <> ")",
     fok, ToString[Round[Total[fs], 0.1]] <> " (" <> ToString[Round[median[fs], 0.01]] <> ")",
     Round[slice, 0.1], Round[solve, 0.1]}, " | "] <> " |"]],
  {d, {1, 2, 3, 4}}];
Print[StringRiffle[lines, "\n"]];
Print["\nTotals over common classes: CANONICA ", Round[Total[Lookup[C1 /@ common, "Seconds"]], 0.1], " s, FiniteField ", Round[Total[Lookup[F1 /@ common, "Seconds"]], 0.1], " s"];
Print["\nSlowest 12 classes (seconds CANONICA / FiniteField):"];
Do[Print["  class ", id, " dim ", C1[id]["Dim"], " frame ", C1[id]["Frame"], ": ", Round[C1[id]["Seconds"], 0.1], " (", C1[id]["Status"], ", deg ", Lookup[C1[id], "AnsatzDegree", "-"], ") / ", Round[F1[id]["Seconds"], 0.1], " (", F1[id]["Status"], ")"],
  {id, Take[Reverse[SortBy[common, C1[#]["Seconds"] + F1[#]["Seconds"] &]], UpTo[12]]}];
Print["\nDisagreements (one engine certified, the other not):"];
Do[If[(C1[id]["Status"] === "Certified") =!= (F1[id]["Status"] === "Certified"),
   Print["  class ", id, " dim ", C1[id]["Dim"], ": CANONICA ", C1[id]["Status"], " / FF ", F1[id]["Status"], " ", Lookup[F1[id], "Detail", ""]]], {id, common}];
