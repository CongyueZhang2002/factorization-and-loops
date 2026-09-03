#!/usr/bin/env wolframscript

(* One family mission for the physical endpoint campaign.  The stored object
   is a graded row-space representation of every current transport word and
   its endpoint GPL continuation; it never enumerates the alphabet product. *)
Module[
  {missionTag, repositoryRoot, arguments, outputDirectory, family,
   resultRoot, transportFile, modeFile, formFile, outputFile, writeAtomic,
   transport, modeMap, form, dlog, connectionDataSource, started, binding,
   gradeSummary, result},

  missionTag = Unique["PhysicalEndpointMissionExit$"];
  Catch[
    $AllowInternet = False;
    $HistoryLength = 0;
    repositoryRoot = DirectoryName[ExpandFileName[$InputFileName], 4];
    If[DownValues[FeynFacet`ObservableTransportWordMap] === {},
      Get[FileNameJoin[{repositoryRoot, "Addon", "Load", "LoadFACET.wl"}]]];
    Get[FileNameJoin[{repositoryRoot, "Scripts", "Transport",
      "PhysicalBoundaryCampaignAdapter.wl"}]];

    arguments = Rest[$ScriptCommandLine];
    If[Length[arguments] =!= 2,
      Print["Usage: build_physical_endpoint_transport_family.wls " <>
        "<output-directory> <CFfamily>"];
      Throw[$Failed, missionTag]];
    {outputDirectory, family} = arguments;
    outputDirectory = ExpandFileName[outputDirectory];
    If[! DirectoryQ[outputDirectory],
      CreateDirectory[outputDirectory, CreateIntermediateDirectories -> True]];

    resultRoot = FileNameJoin[{repositoryRoot, "ppHX_NNLO_DoubleReal",
      "Results", "UU_08_10_canonical"}];
    transportFile = FileNameJoin[{resultRoot,
      "ObservableTransport_2026-09-01_codex", "families",
      "observable_transport_" <> family <> ".wl"}];
    modeFile = FileNameJoin[{resultRoot, "PhysicalBoundaryModes",
      "boundary_mode_" <> family <> ".wl"}];
    formFile = FileNameJoin[{resultRoot, "FamilyEpsFormsCertified",
      "family_epsform_" <> family <> ".wl"}];
    outputFile = FileNameJoin[{outputDirectory,
      "physical_endpoint_transport_" <> family <> ".wl"}];
    If[! FileExistsQ[transportFile] || ! FileExistsQ[modeFile],
      Print["Physical endpoint inputs missing for ", family];
      Throw[$Failed, missionTag]];

    writeAtomic[value_, file_] := Module[{temporary = file <> ".tmp-" <>
        ToString[$ProcessID]},
      Put[value, temporary];
      RenameFile[temporary, file, OverwriteTarget -> True]];

    transport = Get[transportFile];
    modeMap = Get[modeFile];
    connectionDataSource = "ObservableTransport";
    If[! ListQ[Lookup[transport, "DLogLetters", Missing[]]] ||
        ! ListQ[Lookup[transport, "DLogResidues", Missing[]]],
      If[! FileExistsQ[formFile],
        Print[family, " certified dlog data missing"];
        Throw[$Failed, missionTag]];
      form = Get[formFile];
      dlog = Lookup[Lookup[form, "EpsilonFormCertificate", <||>],
        "DLog", Missing[]];
      If[! AssociationQ[dlog] || ! TrueQ[Lookup[dlog, "Valid", False]] ||
          Lookup[dlog, "Variables", Missing[]] =!=
            Lookup[transport, "Variables", Missing[]] ||
          Lookup[dlog, "Regulator", Missing[]] =!=
            Lookup[transport, "Regulator", Missing[]] ||
          ! ListQ[Lookup[dlog, "Letters", Missing[]]] ||
          ! ListQ[Lookup[dlog, "Residues", Missing[]]] ||
          Length[dlog["Letters"]] =!= Length[dlog["Residues"]] ||
          Lookup[dlog, "Dimension", Missing[]] =!=
            Lookup[modeMap, "Dimension", Missing[]] ||
          ! AllTrue[dlog["Residues"], MatrixQ[#] &&
            Dimensions[#] === {dlog["Dimension"], dlog["Dimension"]} &],
        Print[family, " certified dlog data are incompatible"];
        Throw[$Failed, missionTag]];
      transport = Join[transport, <|"DLogLetters" -> dlog["Letters"],
        "DLogResidues" -> dlog["Residues"]|>];
      connectionDataSource = "CertifiedEpsilonFormDLog"];
    started = AbsoluteTime[];
    binding =
      FeynFacetCampaign`PhysicalBoundary`BuildGradedPhysicalEndpointTransport[
        transport, modeMap, <||>];
    If[FailureQ[binding] || Lookup[binding, "Status", None] =!=
        "GradedPhysicalEndpointTransportBuilt",
      Print[family, " physical endpoint transport failed: ",
        InputForm[binding]];
      Throw[$Failed, missionTag]];
    gradeSummary = Association@KeyValueMap[#1 -> <|
        "CurrentRowSpaceDimension" -> First[Dimensions[#2["CurrentRowBasis"]]],
        "EndpointWordTerms" -> Length[#2["EndpointWordTerms"]],
        "RequiredConnectorWeight" -> #2["RequiredConnectorWeight"],
        "VisitedConnectorStates" -> #2["VisitedConnectorStateCount"],
        "PrunedConnectorChildren" -> #2["PrunedConnectorChildCount"]|> &,
      binding["GradesByWeight"]];
    result = Join[binding, <|
      "CampaignRecordStatus" -> "PhysicalEndpointTransportAcceptedV1",
      "SourceFiles" -> <|"ObservableTransport" -> transportFile,
        "BoundaryModeMap" -> modeFile,
        "EpsilonForm" -> If[connectionDataSource ===
          "CertifiedEpsilonFormDLog", formFile, None]|>,
      "EndpointConnectionDataSource" -> connectionDataSource,
      "GradeSummary" -> gradeSummary,
      "TotalSeconds" -> AbsoluteTime[] - started|>];
    writeAtomic[result, outputFile];
    Print[family, " physical endpoint transport: ",
      Length[result["PeriodCoordinates"]], " Stage-3 coordinates, grades ",
      Keys[result["GradesByWeight"]], ", ",
      Round[result["TotalSeconds"], .01], " s"];
    result,
    missionTag]
]
