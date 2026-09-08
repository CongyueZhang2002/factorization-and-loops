#!/usr/bin/env wolframscript

Block[{$HistoryLength = 0}, Module[
 {scriptDirectory, artifact, checks, check, records, expectedDemands,
  family, summary},

scriptDirectory = DirectoryName[ExpandFileName[$InputFileName]];
artifact = Get[FileNameJoin[{DirectoryName[scriptDirectory], "Artifacts",
  "CF303InheritedObservableExtensions.wl"}]];

checks = {};
check[name_, condition_] := AppendTo[checks, name -> TrueQ[condition]];

records = AssociationThread[
  Lookup[artifact["Families"], "Family"], artifact["Families"]];
expectedDemands = <|
  "CF12" -> {{2, 6}},
  "CF199" -> {{2, 8}, {3, 9}},
  "CF53" -> {{2, 11}, {3, 12}}|>;

check["artifact states its intentionally incomplete physical scope",
  artifact["Status"] === "CF303InheritedObservableExtensionsBuiltV1" &&
    artifact["CompleteForCF303TargetComposition"] === False];
check["exactly the three demanded lower families are present",
  Sort[Keys[records]] === Sort[Keys[expectedDemands]]];
check["all pre-existing observable demand rows replay exactly",
  And @@ KeyValueMap[
    Lookup[#2["ExistingDemandReplay"], "Matched"] ===
      Lookup[#2["ExistingDemandReplay"], "Total"] &, records]];
check["only the five requested observable rows were extended",
  And @@ KeyValueMap[
    #2["DemandExtension"]["PhysicalDemandPairs"] === expectedDemands[#1] &,
    records] &&
    Total[Length[# ["DemandExtension"]["PhysicalDemandPairs"]] & /@
      Values[records]] === 5];

check["MovingKernel endpoint coordinates use the ambient base embedding",
  With[{evolution = records["CF199"]["BoundaryEvolution"]},
    evolution["Method"] === "MovingKernel" &&
      First[evolution["BoundaryBaseEmbeddingDimensions"]] ===
        evolution["AmbientSlotCount"] &&
      evolution["BoundaryBaseEmbeddingDimensions"] === {72, 48} &&
      evolution["AutomatonFinalEmbeddingDimensions"] === {48, 48}]];
check["AmbientBasePoint control keeps its already aligned embedding",
  With[{evolution = records["CF53"]["BoundaryEvolution"]},
    evolution["Method"] === "AmbientBasePoint" &&
      evolution["BoundaryBaseEmbeddingDimensions"] === {138, 105} &&
      evolution["AutomatonFinalEmbeddingDimensions"] === {138, 105}]];
check["CF53 zero mode is completed in the full residue kernel",
  records["CF53"]["EndpointPeriodTransport"]["ModeCompletion"]
      ["CompletedModeEntries"] === {{11, 2}, {12, -3}, {13, -2/5}}];
check["CF199 and CF53 formal endpoint period words were built",
  And @@ Table[
    records[family]["EndpointPeriodTransport"]["Status"] ===
        "FormalPhysicalPeriodWordsBuilt" &&
      records[family]["EndpointPeriodTransport"][
        "RetainedConnectorWordCount"] > 0 &&
      Length[records[family]["EndpointPeriodTransport"]["WordMaps"]] ===
        records[family]["EndpointPeriodTransport"][
          "RetainedConnectorWordCount"],
    {family, {"CF199", "CF53"}}]];
check["formal PID9 realizations remain family-local and unevaluated",
  And @@ Table[
    With[{transport = records[family]["EndpointPeriodTransport"]},
      AllTrue[transport["PeriodCoordinates"],
        Lookup[#, "RealizationKey"] === {family, 9} &&
          Lookup[#, "Status"] === "Unevaluated" &] &&
      AllTrue[transport["Stage3NeedsLedger"],
        Lookup[#, "PeriodID"] === 9 &&
          Lookup[#, "Status"] === "Unevaluated" &]],
    {family, {"CF199", "CF53"}}]];
check["CF12 missing physical mode remains typed incomplete",
  records["CF12"]["EndpointPeriodTransport"]["Status"] ===
    "PhysicalModeRealizationRequired"];
check["word maps have exactly the requested output-row shape",
  And @@ Table[
    With[{record = records[family], maps =
        records[family]["EndpointPeriodTransport"]["WordMaps"]},
      AllTrue[maps, First[Dimensions[Normal[Lookup[#, "Map"]]]] ===
        Length[record["DemandExtension"]["PhysicalDemandPairs"]] &]],
    {family, {"CF199", "CF53"}}]];

summary = <|
  "Status" -> If[And @@ Last /@ checks, "PASS", "FAIL"],
  "Checks" -> checks,
  "Performance" -> Association@Table[family -> KeyTake[
    records[family]["EndpointPeriodTransport"],
    {"AdapterSeconds", "CompositionSeconds", "RequiredConnectorWeight",
      "VisitedConnectorStateCount", "EnumeratedConnectorWordCount",
      "RetainedConnectorWordCount", "PrunedConnectorChildCount"}],
    {family, {"CF199", "CF53"}}]
|>;
Print[InputForm[summary]];

summary
]]
