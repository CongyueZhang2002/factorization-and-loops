(* Support-strategy benchmark (user request 2026-08-22: "do test of off
   diagonal blocks for 2 approaches to see the cost difference"): one
   block, one strategy, one kernel, production settings (numerical final
   check, no broker), one TSV row.
   Usage (pool mission): benchmark_support_strategy.wls STRATEGY RECORD OUTDIR
   Row: block, dims, strategy, solved, seconds, probes, selected offset,
        support kind, support size, unknowns, primes, sampling s, note *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
{strategy, file, outdir} = $ScriptCommandLine[[2 ;; 4]];
rd[f_] := Block[{$ContextPath = {"System`", "Global`"}, $Context = "Global`"}, Get[f]];
record = rd[file];
If[! (AssociationQ[record] && KeyExistsQ[record, "Strip"]), Print["bad record ", file]; Exit[3]];
If[! MemberQ[$ContextPath, "FeynFacet`"], Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]]];
name = StringReplace[FileBaseName[file], {"_input" -> "", "fixture_" -> ""}];
dims = Dimensions[record["Strip"][[3]][[1]]];
tsv = FileNameJoin[{outdir, strategy <> ".tsv"}];
If[! FileExistsQ[tsv], Export[tsv, "block\tdims\tstrategy\tsolved\tseconds\tprobes\toffset\tkind\tsupport\tunknowns\tprimes\tsampling_s\tnote\n", "Text"]];
row[a__] := Module[{s = OpenAppend[tsv]}, WriteString[s, StringRiffle[ToString[#, InputForm] & /@ {a}, "\t"], "\n"]; Close[s]];
art = FileNameJoin[{outdir, "artifacts", strategy, name}];
{wall, sol} = AbsoluteTiming[
  FeynFacet`SolveEpsFormStripFiniteField[record, "KernelCount" -> 1, "SupportStrategy" -> strategy,
    "ArtifactDirectory" -> art, "ArtifactPrefix" -> name, "FinalCheck" -> "Numerical", "Verbose" -> True]];
If[AssociationQ[sol],
  dp = Lookup[sol, "DegreeProbe", <||>];
  row[name, dims, strategy, True, Round[wall, 0.1], Lookup[sol, "ProbeCount", "?"], sol["SelectedNumeratorDegreeOffset"],
    Lookup[sol, "SelectedSupportKind", "?"], Lookup[dp, "GaugeSupportCount", "?"],
    Lookup[dp, "GaugeUnknownCount", 0] + Lookup[dp, "FreeResidueCount", 0], Lookup[sol, "ModularPrimeCount", "?"],
    Round[Lookup[sol, "TotalSamplingSeconds", 0], 0.1], Lookup[sol, "Certificate", "?"]],
  row[name, dims, strategy, False, Round[wall, 0.1], "?", "-", "-", "-", "-", "-", "-", "failed"]];
Print["BENCH ", name, " ", strategy, " solved=", AssociationQ[sol], " wall=", Round[wall, 0.1]];
