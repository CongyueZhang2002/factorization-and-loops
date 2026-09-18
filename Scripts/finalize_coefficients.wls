(* Consolidate completed rational and Laurent reconstructions into one
   self-contained final coefficient file. No reconstruction is performed.
   Usage: wolframscript -file Scripts/finalize_coefficients.wls request.wl
   See Design/FinalCoefficientResults.md for the request and result schema. *)
$HistoryLength = 0;
root = DirectoryName[ExpandFileName[$InputFileName], 2];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
fail[text_] := (Print["FINALIZATION FAILED: ", text]; Exit[1]);
arguments = Rest[$ScriptCommandLine];
If[Length[arguments] =!= 1, fail["expected one request file"]];
request = FeynFacetRecords`ReadRecord[First[arguments]];
traceDirectory = request["TraceDirectory"];
record = FeynFacet`Private`reconstructionTraceRecord[traceDirectory];
If[! AssociationQ[record], fail["unreadable trace manifest"]];
trace = record["TraceData"];
If[! TrueQ[trace["CompleteTargetSet"]], fail["incomplete target set"]];
columns = <||>;
collectFiles[files_List, variable_, truncation_] := Module[{parsed, entries},
  If[files === {}, Return[Null]];
  parsed = FeynFacet`Private`reconstructionCollectResults[
    DirectoryName[First[files]], traceDirectory, trace, variable, files];
  If[! AssociationQ[parsed], fail["result parsing failed"]];
  If[Intersection[Keys[columns], Keys[parsed["Columns"]]] =!= {},
    fail["duplicate outputs across rational and series inputs"]];
  entries = KeyValueMap[Function[{index, value},
    index -> If[variable === None,
      <|"Representation" -> "Exact", "Coefficient" -> value|>,
      If[! IntegerQ[truncation] || Max[Keys[value]] =!= truncation ||
          ! FreeQ[Values[value], variable],
        fail["series coverage or regulator independence failed"]];
      <|"Representation" -> "LaurentSeries",
        "Coefficient" -> <|"SeriesVariable" -> variable, "Orders" -> value,
          "SeriesTruncation" -> truncation|>|>
    ]], parsed["Columns"]];
  AssociateTo[columns, entries];
];
collectFiles[Lookup[request, "RationalResults", {}], None, None];
Scan[collectFiles[#["Files"], #["Variable"], #["Order"]] &,
  Lookup[request, "SeriesResults", {}]];
If[Sort[Keys[columns]] =!= Range[Length[trace["OutputFiles"]]],
  fail["not every coefficient output has a completed result"]];
terms[master_Integer] := Map[Function[index,
    Join[<|"PreFactor" -> ReleaseHold[
      trace["Signatures"][trace["OutputMetadata"][[index]]["SignatureIndex"]]]|>,
      columns[index]]],
  Select[Range[Length[trace["OutputFiles"]]],
    trace["OutputMetadata"][[#]]["MasterIndex"] === master &]];
definitions = FeynFacet`Private`coefficientReadRecord[request["DefinitionFile"]];
If[! AssociationQ[definitions], fail["unreadable master definitions"]];
result = <|
  "Format" -> "FeynFacet-MasterIntegralCoefficients", "FormatVersion" -> 1,
  "PreFactor" -> trace["PhysicalFactor"], "Variables" -> trace["Variables"],
  "Masters" -> MapIndexed[
    <|"Master" -> #1, "Terms" -> terms[First[#2]]|> &, trace["Masters"]],
  "RemainderTerms" -> terms[0],
  "CompleteTargetSet" -> True,
  "Definitions" -> KeyTake[definitions, {"CardName", "Pairs", "Setup",
    "AnalyticContext", "ReverseRules", "Topologies", "TopologyEquivalence",
    "MassDimensions", "DimensionRule"}],
  "Validation" -> <|"AllOutputsPresent" -> True,
    "Statement" -> "Consolidation of completed reconstructions; no new physical root or cut certification."|>
|>;
output = ExpandFileName[request["OutputFile"]];
If[FileExistsQ[output], fail["output already exists"]];
If[! DirectoryQ[DirectoryName[output]],
  CreateDirectory[DirectoryName[output], CreateIntermediateDirectories -> True]];
temporary = output <> ".partial";
If[FileExistsQ[temporary], fail["partial output already exists"]];
Export[temporary, BinarySerialize[result, PerformanceGoal -> "Size"], "Byte"];
restored = BinaryDeserialize[ByteArray[BinaryReadList[temporary, "Byte"]]];
If[restored =!= result, fail["serialization read-back differs"]];
RenameFile[temporary, output];
summary = <|"File" -> output, "Masters" -> Length[result["Masters"]],
  "ExactOutputs" -> Count[Values[columns], a_Association /; a["Representation"] === "Exact"],
  "SeriesOutputs" -> Count[Values[columns], a_Association /; a["Representation"] === "LaurentSeries"],
  "Bytes" -> FileByteCount[output], "ExactSerializationReadBack" -> True|>;
FeynFacetRecords`WriteRecord[summary, output <> ".summary.wl"];
Print["FINAL RESULT ", InputForm[summary]];
