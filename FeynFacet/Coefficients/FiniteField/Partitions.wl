(* Literal source partitions preserve exact exceptional terms while only
   the certified regular part is eligible for finite epsilon reconstruction. *)
BeginPackage["FeynFacet`"];Begin["`Private`"];
$reconstructionPartitionBackend=FileNameJoin[{DirectoryName[$InputFileName,3],"Backends","rational_divisors.py"}];
reconstructionPartitionTrace[data_Association,file_String] := Catch[Module[
 {records,validation,files={},metadata={},indices={},kinds={},sourceIndex,entry,part,record},
 records=Import[file,"RawJSON"];
 If[!ListQ[records]||records==={},Throw[Failure["PartitionManifestRequired",<||>]]];
 validation=RunProcess[{"python3",$reconstructionPartitionBackend,"--verify",file}];
 If[validation["ExitCode"]=!=0||!StringContainsQ[validation["StandardOutput"],"LITERAL PARTITIONS VERIFIED"],
  Throw[Failure["LiteralPartitionValidationFailed",<|"Diagnostic"->validation["StandardError"]|>]]];
 Do[
  sourceIndex=FirstPosition[ExpandFileName/@data["OutputFiles"],ExpandFileName[record["Source"]],None];
  If[sourceIndex===None,Throw[Failure["PartitionSourceNotInTrace",<|"Source"->record["Source"]|>]]];
  sourceIndex=First[sourceIndex];
  Do[
   entry=record["Parts"][part];
   AppendTo[files,ExpandFileName[entry["File"]]];
   AppendTo[metadata,data["OutputMetadata"][[sourceIndex]]];
   AppendTo[indices,sourceIndex];AppendTo[kinds,part],
  {part,{"Regular","Exact"}}],
 {record,records}];
 Join[data,<|"OutputFiles"->files,"ExpressionBytes"->(FileByteCount/@files),
  "OutputMetadata"->metadata,"CompleteTargetSet"->False,
  "PartitionSourceIndices"->indices,"PartitionKinds"->kinds,
  "SourcePartitions"->records,"PartitionManifest"->ExpandFileName[file]|>]
]];
End[];EndPackage[];
