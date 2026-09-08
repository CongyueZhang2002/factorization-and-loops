#!/usr/bin/env wolframscript

(* Persist the exact pre-kernel boundary constraint system for one family.
   This is an external optimization diagnostic, not a transport artifact. *)

$HistoryLength = 0;
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 2,
  Print["Usage: ExtractProjectedTransportBoundarySystem.wls FAMILY OUTPUT.wl"];
  Exit[64]
];

family = arguments[[1]];
outputFile = ExpandFileName[arguments[[2]]];
root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
loadFile = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
candidateFile = FileNameJoin[{bundle,
  "CodexObservableTransportCandidate.wl"}];
standardFile = FileNameJoin[{bundle,
  "CodexProjectedTransportStandard.wl"}];
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

If[! And @@ (FileExistsQ /@ {loadFile, candidateFile, standardFile,
    recordFile, systemFile, valuationFile, cardFile}),
  Print["Boundary-system input missing for ", family];
  Exit[66]
];

Get[loadFile];
Block[{$Context = "FeynFacet`Private`",
    $ContextPath = {"FeynFacet`", "System`", "Global`"}},
  Get[candidateFile]];
Get[standardFile];
record = FeynFacet`FamilyArtifactRead[recordFile];
system = FeynFacet`FamilyArtifactRead[systemFile];
valuations = FeynFacet`FamilyArtifactRead[valuationFile];
card = FeynFacet`FamilyArtifactRead[cardFile];

demand = CodexProjectedTransportStandard`CodexProjectedTransportBuildDemand[
  record, system, valuations,
  "HardFunctionOrders" -> Lookup[card, "HardFunctionOrders", {0}],
  "SafetyOrders" -> Lookup[card, "SafetyOrders", 1],
  "MasterValuation" -> Lookup[card, "MasterValuation", 0],
  "Path" -> Lookup[card, "Path", Automatic]];
If[! AssociationQ[demand] ||
    Lookup[demand, "Status", None] =!= "ExactObservableDemand",
  Print["Demand construction failed for ", family];
  Exit[65]
];

Print[DateString[{"ISODate", " ", "Time"}],
  " extracting boundary system family=", family,
  " pid=", $ProcessID, " kernels=", Length[Kernels[]]];
result = FeynFacet`BuildObservableTransport[
  record, demand,
  "WordRepresentation" -> "CompactAutomaton",
  "DiagnosticStopAfter" -> "BoundaryConstraintMatrix",
  "Verbose" -> True];
If[! AssociationQ[result] ||
    Lookup[result, "Status", None] =!=
      "DiagnosticBoundaryConstraintMatrix",
  Print["Extraction failed: ", InputForm[result]];
  Exit[1]
];

result = Join[result, <|
  "ExternalScope" -> "NoPackageEditsDiagnostic",
  "SourceSHA256" -> <|
    "ObservableTransportCandidate" ->
      FileHash[candidateFile, "SHA256", "HexString"],
    "ObservableTransportPackage" -> FileHash[
      FileNameJoin[{root, "FeynFacet", "Private",
        "ObservableTransport.wl"}], "SHA256", "HexString"]|>
  |>];
FeynFacet`FamilyArtifactWrite[result, outputFile];
Print[InputForm[KeyDrop[result, "ConstraintMatrix"]]];
