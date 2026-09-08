#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
If[Length[$ScriptCommandLine]<2,Print["Usage: determine_boundary_amplitudes.wls input.wxf"];Exit[1]];
file=ExpandFileName[Last[$ScriptCommandLine]];base=DirectoryName[file];
read[path_]:=If[FileExtension[path]==="wxf",Import[path,"WXF"],Get[path]];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{base,path}]]];
materialize[path_String]:=read[resolve[path]];materialize[value_]:=value;
spec=read[file];problem=materialize[spec["Problem"]];
Do[If[KeyExistsQ[problem,key],problem[key]=materialize[problem[key]]],
 {key,{"AmplitudeReduction","PhysicalCoefficientEquations","PhysicalBoundaryIntegralDefinitions","EvaluatedBoundaryIntegrals","RequestedAmplitudeCoefficients"}}];
result=FeynFacet`DetermineBoundaryAmplitudes[problem,
 "IntegrationBackend"->Lookup[spec,"IntegrationBackend",Automatic],
 "ScratchDirectory"->If[KeyExistsQ[spec,"ScratchDirectory"],resolve[spec["ScratchDirectory"]],Automatic],
 "GenericRankWitness"->Lookup[spec,"GenericRankWitness",Automatic],
 "TimeLimit"->Lookup[spec,"TimeLimit",1800],"Verbose"->Lookup[spec,"Verbose",True]];
If[FailureQ[result],Print["FAILED ",result];Exit[1]];
path=resolve[spec["OutputFile"]];
If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
Export[path<>".tmp",BinarySerialize[result,PerformanceGoal->"Size"],"Byte"];
RenameFile[path<>".tmp",path,OverwriteTarget->True];
Print["PASS PHYSICAL AMPLITUDE DETERMINATION ",KeyTake[result,
 {"RemainingUnknownAmplitudeCount","NewPhysicalIntegralCount","PhysicalCoefficientRowsUsed","PhysicalBoundaryValuesCompleteForStoredOrders"}]];
Exit[0];
