#!/usr/bin/env wolframscript
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
base = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsSolving"}];
live = FileNameJoin[{base, "triple_root_2026-08-24_fable", "CF300",
  "sector_state_CF300_standard.wl"}];
frozen = FileNameJoin[{base, "FrozenTestFixtures_2026-08-25",
  "cf300_frozen_stripsolvers.wl"}];
Print["reading ", live, " (", Round[FileByteCount[live]/1024.^2, 0.1], " MB)"];
{seconds, state} = AbsoluteTiming[FeynFacet`FamilyArtifactRead[live, "Global`"]];
Print["read in ", Round[seconds, 0.1], " s; keys ", Length[state]];
solvers = Lookup[state, "StripSolvers", $Failed];
If[! MatchQ[solvers, {___Association}], Print["!! StripSolvers missing"]; Exit[2]];
Print["StripSolvers entries: ", Length[solvers],
  ", positions ", Lookup[solvers, {"Sector", "LowerSector"}]];
payload = <|
  "Schema" -> "FrozenCF300StripSolversV1",
  "Family" -> "CF300",
  "Source" -> "FamilyEpsFormsSolving/triple_root_2026-08-24_fable/CF300/sector_state_CF300_standard.wl",
  "SourceSHA256" -> FileHash[live, "SHA256", "HexString"],
  "SourceByteCount" -> FileByteCount[live],
  "SourceModified" -> DateString[FileDate[live], "ISODateTime"],
  "FrozenAt" -> DateString["ISODateTime"],
  "Sector" -> Lookup[state, "Sector", None],
  "StripSolvers" -> solvers|>;
FeynFacet`FamilyArtifactWrite[payload, frozen];
Print["wrote ", frozen, " (", Round[FileByteCount[frozen]/1024., 0.1], " KB)"];
Print["frozen SHA256 ", FileHash[frozen, "SHA256", "HexString"]];
Exit[0]
