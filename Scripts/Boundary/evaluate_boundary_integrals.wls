#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
SetEnvironment["OMP_NUM_THREADS"->"1"];SetEnvironment["OPENBLAS_NUM_THREADS"->"1"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
If[Length[$ScriptCommandLine]<2,Print["Usage: evaluate_boundary_integrals.wls input.wxf"];Exit[1]];
file=ExpandFileName[Last[$ScriptCommandLine]];base=DirectoryName[file];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{base,path}]]];
read[path_]:=If[FileExtension[path]==="wxf",Import[path,"WXF"],FeynFacetRecords`ReadRecord[path]];
spec=read[file];plan=read[resolve[spec["BoundaryAmplitudeReduction"]]];
output=resolve[spec["OutputDirectory"]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
indices=Lookup[spec,"BoundaryInputIndices",Range[Length[plan["BoundaryInputs"]]]];
reports={};failed=False;
Do[
 boundaryInput=plan["BoundaryInputs"][[index]];
 range=plan["InputOrderDetermination"]["BoundaryIntegralOrderRanges"][index];If[range==={},Continue[]];
 If[!KeyExistsQ[boundaryInput,"IntegralDefinition"],
   AppendTo[reports,<|"Index"->index,"Status"->"NoIntegralDefinition"|>];Continue[]];
 work=If[KeyExistsQ[spec,"ScratchDirectory"],FileNameJoin[{resolve[spec["ScratchDirectory"]],"integral_"<>ToString[index]}],Automatic];
 If[StringQ[work]&&!DirectoryQ[work],CreateDirectory[work,CreateIntermediateDirectories->True]];
 started=AbsoluteTime[];Print["BEGIN BOUNDARY INTEGRAL ",index," orders ",range," ",DateString[]];
 value=FeynFacet`IntegrateEulerBoundaryIntegral[boundaryInput["IntegralDefinition"],range,
  "IntegrationBackend"->Lookup[spec,"IntegrationBackend","Automatic"],"ScratchDirectory"->work,
  "TimeLimit"->Lookup[spec,"TimeLimit",1800],"Verbose"->Lookup[spec,"Verbose",True]];
 path=output<>"/boundary_integral_"<>ToString[index]<>".wxf";
 Export[path<>".tmp",BinarySerialize[value,PerformanceGoal->"Size"],"Byte"];RenameFile[path<>".tmp",path,OverwriteTarget->True];
 If[FailureQ[value],failed=True;Print["FAILED ",index," ",value],
   Print["PASS BOUNDARY INTEGRAL ",index," orders ",range," elapsed seconds ",AbsoluteTime[]-started]];
 AppendTo[reports,<|"Index"->index,"EpsilonOrderRange"->range,"Status"->If[FailureQ[value],"Failed","Evaluated"],
  "ElapsedSeconds"->(AbsoluteTime[]-started),"ResultFile"->path|>],
 {index,indices}];
Export[output<>"/boundary_integral_evaluation_report_"<>StringRiffle[ToString/@indices,"_"]<>".wxf",reports,"WXF"];
Exit[If[failed,1,0]];
