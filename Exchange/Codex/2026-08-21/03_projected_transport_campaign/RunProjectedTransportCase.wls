#!/usr/bin/env wolframscript

(* One isolated, single-kernel projected-transport case.  The surrounding
   campaign limits concurrency and CPU affinity; this script never launches
   subkernels and never writes into FeynFacet or production result folders. *)

$HistoryLength = 0;

arguments = Rest[$ScriptCommandLine];
If[! MemberQ[{2, 3}, Length[arguments]],
  Print["Usage: RunProjectedTransportCase.wls FAMILY OUTPUT.wl [VERBOSE]"];
  Exit[64]
];

family = arguments[[1]];
outputFile = ExpandFileName[arguments[[2]]];
verbose = Length[arguments] === 3 &&
  MemberQ[{"1", "true", "True", "yes"}, arguments[[3]]];

root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
standardFile = FileNameJoin[{bundle, "CodexProjectedTransportStandard.wl"}];
certifiedDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsCertified"}];
differentialDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "DifferentialEquations"}];
valuationFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "MasterCoefficientValuations.wl"}];
cardFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Cards",
  "UU_ObservableTransport.wl"}];
recordFile = FileNameJoin[{certifiedDirectory,
  "family_epsform_" <> family <> ".wl"}];
systemFile = FileNameJoin[{differentialDirectory,
  "nnlo_de_" <> family <> ".wl"}];

If[! And @@ (FileExistsQ /@ {loadFile, standardFile, recordFile,
    systemFile, valuationFile, cardFile}),
  Print["Missing input for ", family];
  Exit[66]
];

Get[loadFile];
Get[standardFile];

existing = If[FileExistsQ[outputFile],
  FeynFacet`FamilyArtifactRead[outputFile], $Failed];
If[CodexProjectedTransportStandard`CodexProjectedTransportExactQ[existing],
  Print[family, " already has an exact external projected transport"];
  Exit[0]
];

record = FeynFacet`FamilyArtifactRead[recordFile];
system = FeynFacet`FamilyArtifactRead[systemFile];
valuations = FeynFacet`FamilyArtifactRead[valuationFile];
card = FeynFacet`FamilyArtifactRead[cardFile];
If[! AssociationQ[record] || ! AssociationQ[system] ||
    ! ListQ[valuations] || ! AssociationQ[card],
  Print["Malformed input for ", family];
  Exit[65]
];

Print[DateString[{"ISODate", " ", "Time"}], " ", family,
  " projected transport started; dim=", Lookup[record, "Dim", "?"],
  ", pid=", $ProcessID];

result = CodexProjectedTransportStandard`CodexProjectedTransportSolve[
  record,
  system,
  valuations,
  "HardFunctionOrders" -> Lookup[card, "HardFunctionOrders", {0}],
  "SafetyOrders" -> Lookup[card, "SafetyOrders", 1],
  "MasterValuation" -> Lookup[card, "MasterValuation", 0],
  "Path" -> Lookup[card, "Path", Automatic],
  "Verbose" -> verbose
];

result = If[AssociationQ[result], Join[result, <|
    "ExternalScope" -> "NoPackageEdits",
    "SourceFiles" -> <|
      "EpsilonForm" -> recordFile,
      "DifferentialSystem" -> systemFile,
      "Valuations" -> valuationFile,
      "Card" -> cardFile,
      "StandardWrapper" -> standardFile
    |>,
    "SourceSHA256" -> <|
      "EpsilonForm" -> FileHash[recordFile, "SHA256", "HexString"],
      "DifferentialSystem" -> FileHash[systemFile, "SHA256", "HexString"],
      "Valuations" -> FileHash[valuationFile, "SHA256", "HexString"],
      "Card" -> FileHash[cardFile, "SHA256", "HexString"],
      "ObservableTransportEngine" -> FileHash[
        FileNameJoin[{root, "FeynFacet", "Private", "ObservableTransport.wl"}],
        "SHA256", "HexString"],
      "StandardWrapper" -> FileHash[standardFile, "SHA256", "HexString"]
    |>,
    "Runtime" -> <|
      "KernelVersion" -> $Version,
      "SystemID" -> $SystemID,
      "ProcessID" -> $ProcessID,
      "SubkernelsLaunched" -> Length[Kernels[]]
    |>
  |>], result];

If[! CodexProjectedTransportStandard`CodexProjectedTransportExactQ[result],
  Print[family, " failed: ",
    InputForm[If[AssociationQ[result],
      KeyTake[result, {"Status", "Certificates", "EngineResult",
        "Demand"}], result]]];
  Exit[1]
];

FeynFacet`FamilyArtifactWrite[result, outputFile];
summaryFile = FileNameJoin[{DirectoryName[outputFile],
  FileBaseName[outputFile] <> "_summary.wl"}];
summary = CodexProjectedTransportStandard`CodexProjectedTransportSummary[result];
FeynFacet`FamilyArtifactWrite[summary, summaryFile];

Print[DateString[{"ISODate", " ", "Time"}], " ", family,
  " exact projected transport finished: ", InputForm[summary]];
