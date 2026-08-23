(* Fully automatic stage-1 campaign on the finite-field route:
   DiagonalBlockClassCampaign over BlockClasses/classes.wl (raw (v,w)
   representatives; charts discovered automatically), ledger-schema
   records into OUTDIR, then an oracle comparison against ClassForms/:
   letters (by name, chart variables permitting) and residue spectra.
   Args: OUTDIR [KERNELS=4] [CLASSIDS | ALL] [FALLBACK None|CANONICA] *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"}];
out = $ScriptCommandLine[[2]];
kernels = If[Length[$ScriptCommandLine] >= 3, ToExpression[$ScriptCommandLine[[3]]], 4];
which = If[Length[$ScriptCommandLine] >= 4, $ScriptCommandLine[[4]], "ALL"];
fallback = If[Length[$ScriptCommandLine] >= 5 && $ScriptCommandLine[[5]] === "CANONICA", "CANONICA", None];
cls = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "BlockClasses", "classes.wl"}]];
If[which =!= "ALL", With[{ids = ToExpression /@ StringSplit[which, ","]}, cls = Select[cls, MemberQ[ids, #["ClassID"]] &]]];
t0 = AbsoluteTime[];
summary = FeynFacet`DiagonalBlockClassCampaign[cls, out, "Kernels" -> kernels, "Fallback" -> fallback];
Print["CAMPAIGN ", summary["Canonicalized"], "/", summary["Attempted"], " canonicalized in ", Round[AbsoluteTime[] - t0, 0.1], " s"];
FeynFacet`FamilyArtifactWrite[summary, FileNameJoin[{out, "campaign_summary.wl"}]];
Print["failures: ", Select[summary["Results"], #["Status"] =!= "CANONICALIZED" &]];
Print["methods: ", Counts[Lookup[Select[summary["Results"], #["Status"] === "CANONICALIZED" &], "Method"]]];
Print["frames: ", Counts[Lookup[Select[summary["Results"], #["Status"] === "CANONICALIZED" &], "Frame"]]];
Print["DONE"];
