(* Blockwise-schema adapter (2026-08-22): compose the established 2026-08-19/20
   blockwise Libra result of a family into a standard family record and
   validate it against the source DE with ValidateFamilyDLogEpsilonForm.
     input record   (LibraTwoRoot_20260819/family_epsform_<CF>.wl): TTotal_in
                    relative to the source, chart, Blocks, assembled EpsForm_in
     blockwise      (blockwise_local_<CF>.wl): Transformation T_b from
                    EpsForm_in to SystemX/Y (Fuchsified)
     factor dep.    (factor_dependence_<CF>_canonicadlog.wl): constant T_fd
                    and the final EpsFormX/Y
   TTotal = TTotal_in . T_b . T_fd; the certificate is the statement.
   Usage: adapt_blockwise_record.wls FAMILY CODEXDIR OUTPUT *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
{family, codexDir, outputFile} = Rest[$ScriptCommandLine];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"}];
rd = FeynFacet`FamilyArtifactRead;
input = rd[FileNameJoin[{codexDir, "..", "LibraTwoRoot_20260819", "family_epsform_" <> family <> ".wl"}]];
block = rd[FileNameJoin[{codexDir, "blockwise_local_" <> family <> ".wl"}]];
fd = rd[FileNameJoin[{codexDir, "factor_dependence_" <> family <> "_canonicadlog.wl"}]];
system = rd[FileNameJoin[{R, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"}]];
If[! AllTrue[{input, block, fd, system}, AssociationQ], Print["ADAPT unreadable inputs"]; Exit[3]];
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
  FeynFacet`ValidateFamilyDLogEpsilonForm[record, system]];
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
