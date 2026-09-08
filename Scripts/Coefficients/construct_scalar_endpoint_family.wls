#!/usr/bin/env wolframscript
(* Command-line wrapper around the reusable, checkpointed family driver. *)
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
endpointAssemblyRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[endpointAssemblyRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[endpointAssemblyRoot<>"/Scripts/Coefficients/ScalarEndpointDriver.wl"];
endpointAssemblyArgs=Rest[$ScriptCommandLine];
If[Length[endpointAssemblyArgs]=!=2,Print["Expected INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
endpointAssemblyResult=ScalarEndpointDriver`RunScalarEndpointFamily[
 First[endpointAssemblyArgs],Last[endpointAssemblyArgs]];
Print[If[Lookup[endpointAssemblyResult,"Status",None]==="ExplicitPhysicalScalarEndpointCoefficients","PASS ","FAIL "],endpointAssemblyResult];
Exit[If[Lookup[endpointAssemblyResult,"Status",None]==="ExplicitPhysicalScalarEndpointCoefficients",0,1]];
