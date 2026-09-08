#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/FeynFacet/Solution.m"];
If[Length[$ScriptCommandLine]<2,Print["Usage: assemble_evaluated_boundary_amplitudes.wls input.wxf"];Exit[1]];
file=ExpandFileName[Last[$ScriptCommandLine]];base=DirectoryName[file];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{base,path}]]];
spec=Import[file,"WXF"];plan=Import[resolve[spec["BoundaryAmplitudeReduction"]],"WXF"];
inputs=plan["BoundaryInputs"];paths=spec["BoundaryIntegralEvaluationFiles"];
Do[
 value=Import[resolve[paths[index]],"WXF"];
 If[!AssociationQ[value]||Lookup[value,"Status",None]=!="AnalyticallyEvaluated",
  Print["FAILED integral ",index," has no accepted analytic value."];Exit[1]];
 If[value["IntegralDefinition"]=!=inputs[[index,"IntegralDefinition"]],
  Print["FAILED integral definition mismatch at ",index];Exit[1]];
 inputs[[index]]=Join[inputs[[index]],KeyTake[value,{"LaurentCoefficients","EpsilonOrderRange","AnalyticExpression"}],
  <|"IntegralEvaluationFile"->resolve[paths[index]]|>],
 {index,Keys[paths]}];
Do[
 range=plan["InputOrderDetermination"]["BoundaryIntegralOrderRanges"][index];If[range==={},Continue[]];
 input=inputs[[index]];
 If[KeyExistsQ[input,"AnalyticExpression"]&&!MatchQ[input["AnalyticExpression"],_Missing],Continue[]];
 If[!AssociationQ[Lookup[input,"LaurentCoefficients",None]]||
  !AllTrue[Range@@range,KeyExistsQ[input["LaurentCoefficients"],#]&],
  Print["FAILED insufficient boundary integral coefficients at ",index];Exit[1]],
 {index,Length[inputs]}];
plan["BoundaryInputs"]=inputs;path=resolve[spec["OutputFile"]];
Export[path<>".tmp",BinarySerialize[plan,PerformanceGoal->"Size"],"Byte"];RenameFile[path<>".tmp",path,OverwriteTarget->True];
Print["PASS EVALUATED AMPLITUDE ASSEMBLY ",plan["RemainingUnknownAmplitudeCount"]," unknown series."];
Exit[0];
