#!/usr/bin/env wolframscript
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];args=Rest[$ScriptCommandLine];
If[!MemberQ[{2,3},Length[args]],Print["Usage: compact_distribution_result.wls SOURCE OUTPUT [compact|verify]"];Exit[2]];
mode=If[Length[args]===3,args[[3]],"compact"];If[!MemberQ[{"compact","verify"},mode],Exit[2]];
Get[root<>"/FeynFacet/Solution.m"];Get[root<>"/FeynFacet/Coefficients/DistributionStorage.wl"];
sourcePath=ExpandFileName[args[[1]]];outputPath=ExpandFileName[args[[2]]];
If[sourcePath===outputPath,Print["Distinct source and output paths required"];Exit[2]];
read[path_]:=If[FileExistsQ[path],Import[path,"WXF"],$Failed];
{loadSeconds,source}=AbsoluteTiming[read[sourcePath]];
If[!AssociationQ[source],Print["SOURCE_READ_FAILED"];Exit[1]];
If[mode==="compact",
 {operationSeconds,result}=AbsoluteTiming[FeynFacet`CompactFiniteDistributionResult[source]];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 {exportSeconds,saved}=AbsoluteTiming[Export[outputPath<>".tmp",result,"WXF",PerformanceGoal->"Size"]];
 If[saved===$Failed,Exit[1]];RenameFile[outputPath<>".tmp",outputPath,OverwriteTarget->True];
 report=<|"Status"->"Passed","SourceBytes"->FileByteCount[sourcePath],"OutputBytes"->FileByteCount[outputPath],
  "SourceLoadSeconds"->loadSeconds,"CompactionAndVerificationSeconds"->operationSeconds,"ExportSeconds"->exportSeconds,
  "Compaction"->result["Compaction"]|>,
 {compactLoadSeconds,result}=AbsoluteTiming[read[outputPath]];
 If[!AssociationQ[result],Print["COMPACT_READ_FAILED"];Exit[1]];
 {operationSeconds,report}=AbsoluteTiming[FeynFacet`VerifyFiniteDistributionCompaction[source,result]];
 If[FailureQ[report],Print[InputForm[report]];Exit[1]];
 report=Join[report,<|"SourceLoadSeconds"->loadSeconds,"CompactLoadSeconds"->compactLoadSeconds,
  "VerificationSeconds"->operationSeconds,"SourceBytes"->FileByteCount[sourcePath],"OutputBytes"->FileByteCount[outputPath]|>]];
 Put[report,outputPath<>"."<>mode<>".report.wl.tmp"];
 RenameFile[outputPath<>"."<>mode<>".report.wl.tmp",outputPath<>"."<>mode<>".report.wl",OverwriteTarget->True];
 Print[InputForm[report]];Print["FINITE_DISTRIBUTION_",ToUpperCase[mode],"_PASSED"];
