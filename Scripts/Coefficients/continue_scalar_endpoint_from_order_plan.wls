#!/usr/bin/env wolframscript
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[root<>"/Scripts/Coefficients/ScalarEndpointDriver.wl"];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
result=ScalarEndpointDriver`ContinueScalarEndpointFromOrderPlan[First[args],Last[args]];
Print[KeyTake[result,{"Status","Family","Stage","ElapsedSeconds"}]];
Exit[If[Lookup[result,"Status",None]==="ExplicitPhysicalScalarEndpointCoefficients",0,1]];
