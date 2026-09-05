(* Blockwise-schema adapter (2026-08-22): compose the established 2026-08-19/20
   blockwise Libra result of a family into a standard family record and
   validate it against the source DE with ValidateFamilyDLogEpsilonForm.
     input record   (LibraTwoRoot_20260819/family_epsform_<CF>.wl): TTotal_in
                    relative to the source, chart, Blocks, assembled EpsForm_in
     blockwise      (blockwise_local_<CF>.wl): Transformation T_b from
                    EpsForm_in to SystemX/Y (Fuchsified)
     factor dep.    (factor_dependence_<CF>_canonicadlog.wl): constant T_fd
                    and the final EpsFormX/Y
   TTotal = TTotal_in . T_b . T_fd; the family-level validation is the
   mathematical statement, and the V2 builder is the sole persisted-record
   boundary.
   Usage: adapt_blockwise_record.wls FAMILY CODEXDIR V2_SYSTEM OUTPUT *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
If[Length[$ScriptCommandLine] =!= 5,
  Print["usage: adapt_blockwise_record.wls FAMILY CODEXDIR V2_SYSTEM OUTPUT"];
  Exit[2]];
{family, codexDir, systemFile, outputFile} = Rest[$ScriptCommandLine];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Scripts", "family_dlog_epsilon_form_v2.wl"}]];
rd = FeynFacet`FamilyArtifactRead;
input = rd[FileNameJoin[{codexDir, "..", "LibraTwoRoot_20260819", "family_epsform_" <> family <> ".wl"}]];
block = rd[FileNameJoin[{codexDir, "blockwise_local_" <> family <> ".wl"}]];
fd = rd[FileNameJoin[{codexDir, "factor_dependence_" <> family <> "_canonicadlog.wl"}]];
system = rd[systemFile];
If[! AllTrue[{input, block, fd, system}, AssociationQ], Print["ADAPT unreadable inputs"]; Exit[3]];
systemReference = <|
  "RelativePath" -> FileNameJoin[
    {FileNameTake[DirectoryName[ExpandFileName[systemFile]]],
      FileNameTake[systemFile]}],
  "DataType" -> "FamilyDifferentialSystem", "SchemaVersion" -> 2,
  "Family" -> family|>;
Print["ranges agree: ", input["Ranges"] === block["Ranges"] === fd["Ranges"], "; variables ", input["Variables"], " ", block["Variables"], " ", fd["Variables"]];
n = Length[input["TTotal"]];
{t, tTotal} = AbsoluteTiming[Map[Together, Map[Together, input["TTotal"] . block["Transformation"], {2}] . fd["Transformation"], {2}]];
Print["TTotal composed in ", Round[t, 0.1], " s"];
{t2, tInv} = AbsoluteTiming[Map[Together, Inverse[fd["Transformation"]] . Map[Together, Inverse[block["Transformation"]], {2}] . input["TTotalInverse"], {2}]];
Print["inverse composed in ", Round[t2, 0.1], " s"];
record = Join[input, <|
  "TTotal" -> tTotal, "TTotalInverse" -> tInv,
  "EpsFormX" -> fd["EpsFormX"], "EpsFormY" -> fd["EpsFormY"],
  "Method" -> "BlockwiseLibra+FactorDependence(2026-08-19/20)+SchemaAdapter(2026-08-22)",
  "Letters" -> Lookup[fd, "Letters", Lookup[input, "Letters", {}]],
  "BlockwiseSource" -> <|"Input" -> "LibraTwoRoot_20260819", "Blockwise" -> "blockwise_local_" <> family <> ".wl",
    "FactorDependence" -> "factor_dependence_" <> family <> "_canonicadlog.wl"|>|>];
{t3, certified} = AbsoluteTiming[
  FeynFacetCampaign`BuildValidatedFamilyDLogEpsilonFormV2[
    record, system, systemReference]];
Print["validation in ", Round[t3, 0.1], " s: ", certified["Status"],
  " ", Lookup[Lookup[certified, "Validation", <||>], "Conditions", "?"]];
If[certified["Status"] === "FamilyDLogEpsilonFormValidated" &&
    FeynFacet`ValidatedFamilyDLogEpsilonFormQ[certified],
  Put[certified, outputFile <> ".partial"]; RenameFile[outputFile <> ".partial", outputFile, OverwriteTarget -> True];
  Print["VALIDATE family=", family, " validated=True method=",
    Lookup[Lookup[certified, "Validation", <||>],
      "Method", "Unknown"], " seconds=", Round[t3, 0.1],
    " bytes=", FileByteCount[outputFile]],
  Print["VALIDATE family=", family, " validated=False status=",
    certified["Status"]]];
