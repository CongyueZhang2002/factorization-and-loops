#!/usr/bin/env wolframscript

(* Read-only census of the exact family epsilon-form inventory and the
   hard-function demand.  No transport words are generated here. *)

$HistoryLength = 0;

root = Replace[Environment["FACET_ROOT"],
  Except[_String] | "" -> "/home/maxzhang/factorization-and-loops"];
bundle = DirectoryName[ExpandFileName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{bundle, "CodexProjectedTransportStandard.wl"}]];

certifiedDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "FamilyEpsFormsCertified"}];
differentialDirectory = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "DifferentialEquations"}];
valuationFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
  "UU_08_10_canonical", "MasterCoefficientValuations.wl"}];
cardFile = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Cards",
  "UU_ObservableTransport.wl"}];
outputFile = FileNameJoin[{bundle, "projected_transport_census.wl"}];

valuations = FeynFacet`FamilyArtifactRead[valuationFile];
card = FeynFacet`FamilyArtifactRead[cardFile];
files = Sort@FileNames["family_epsform_CF*.wl", certifiedDirectory];

rows = Table[
  Module[{record, family, systemFile, system, seconds, demand,
    coefficientField},
    record = FeynFacet`FamilyArtifactRead[file];
    family = Lookup[record, "Family", FileBaseName[file]];
    systemFile = FileNameJoin[{differentialDirectory,
      "nnlo_de_" <> family <> ".wl"}];
    system = FeynFacet`FamilyArtifactRead[systemFile];
    {seconds, demand} = AbsoluteTiming[
      CodexProjectedTransportStandard`CodexProjectedTransportBuildDemand[
        record,
        system,
        valuations,
        "HardFunctionOrders" -> Lookup[card, "HardFunctionOrders", {0}],
        "SafetyOrders" -> Lookup[card, "SafetyOrders", 1],
        "MasterValuation" -> Lookup[card, "MasterValuation", 0],
        "Path" -> Lookup[card, "Path", Automatic]
      ]
    ];
    coefficientField = Lookup[Lookup[record, "ChartRecord", <||>],
      "CoefficientField", "Rational"];
    <|
      "Family" -> family,
      "ExactEpsilonForm" -> TrueQ[FeynFacet`ExactFamilyEpsilonFormQ[record]],
      "Dimension" -> Lookup[record, "Dim", Length@Lookup[record,
        "TTotal", {}]],
      "Blocks" -> Length@Lookup[record, "Ranges", {}],
      "Letters" -> Length@Lookup[record, "Letters", {}],
      "Variables" -> Lookup[record, "Variables", Missing[]],
      "CoefficientField" -> coefficientField,
      "RecordBytes" -> FileByteCount[file],
      "DemandStatus" -> Lookup[demand, "Status", Missing[]],
      "DemandPairs" -> Length@Lookup[demand, "PhysicalDemandPairs", {}],
      "PhysicalRows" -> Length@DeleteDuplicates[
        Last /@ Lookup[demand, "PhysicalDemandPairs", {}]],
      "PhysicalOrders" -> Sort@DeleteDuplicates[
        First /@ Lookup[demand, "PhysicalDemandPairs", {}]],
      "DemandSeconds" -> seconds,
      "RecordFile" -> file,
      "SystemFile" -> systemFile
    |>
  ],
  {file, files}
];

result = <|
  "Status" -> If[AllTrue[rows,
      TrueQ[#ExactEpsilonForm] &&
      #DemandStatus === "ExactObservableDemand" &],
    "ExactInventoryAndDemands", "CensusHasFailures"],
  "Families" -> Length[rows],
  "Rows" -> rows,
  "LargestFirst" -> Reverse@SortBy[rows,
    {#Dimension &, #DemandPairs &, #RecordBytes &}],
  "SourceSHA256" -> <|
    "ObservableTransportEngine" -> FileHash[
      FileNameJoin[{root, "FeynFacet", "Private", "ObservableTransport.wl"}],
      "SHA256", "HexString"],
    "CertifiedReport" -> FileHash[
      FileNameJoin[{certifiedDirectory, "certification_report.wl"}],
      "SHA256", "HexString"]
  |>
|>;

FeynFacet`FamilyArtifactWrite[result, outputFile];
Print["Projected transport census: ", result["Status"], ", ",
  result["Families"], " families"];
Scan[Print[InputForm[KeyTake[#,
    {"Family", "Dimension", "Blocks", "Letters", "CoefficientField",
     "DemandStatus", "DemandPairs", "PhysicalRows", "PhysicalOrders",
     "DemandSeconds"}]]] &, Take[result["LargestFirst"], UpTo[20]]];

