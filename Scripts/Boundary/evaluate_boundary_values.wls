
#!/usr/bin/env wolframscript
(* Generic numerical boundary driver. Input is an explicit WL/WXF record. *)
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Solution.m"];
If[Length[$ScriptCommandLine]<2,Print["Usage: evaluate_boundary_values.wls input.wl"];Exit[1]];
inputFile=ExpandFileName[Last[$ScriptCommandLine]];base=DirectoryName[inputFile];
read[path_]:=If[FileExtension[path]==="wxf",Import[path,"WXF"],FeynFacetRecords`ReadRecord[path]];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{base,path}]]];
spec=read[inputFile];
If[!AssociationQ[spec],Print["Input association required"];Exit[1]];
output=resolve[spec["OutputDirectory"]];
If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
shared=read[resolve[spec["SharedBoundaryDefinitions"]]];
construction=read[resolve[spec["SingularBoundaryConstruction"]]];
amplitudes=If[KeyExistsQ[spec,"AmplitudeCoefficientFile"],
 read[resolve[spec["AmplitudeCoefficientFile"]]],spec["AmplitudeCoefficients"]];
requests=If[KeyExistsQ[spec,"SolutionFiles"],
 DeleteDuplicates[Flatten[Table[
  record=read[resolve[path]];
  Cases[record["MasterIntegralCoefficients"],FeynFacetSolution`B[i_Integer,k_Integer]:>{i,k},Infinity],
 {path,spec["SolutionFiles"]}],1]],Automatic];
Print["BEGIN NUMERICAL BOUNDARY EVALUATION ",DateString[]];
result=FeynFacetSolution`EvaluateSharedBoundaryCoefficients[shared,construction,amplitudes,
 "BoundaryCoefficientRequests"->requests,Sequence@@Normal[Lookup[spec,"NumericalOptions",<||>]]];
file=output<>"/boundary_coefficient_values.wxf";
Export[file<>".tmp",result,"WXF"];RenameFile[file<>".tmp",file,OverwriteTarget->True];
If[FailureQ[result],Print["FAILED ",result];Exit[1]];
Print["PASS BOUNDARY COEFFICIENTS ",Length[result["BoundaryCoefficientValues"]],
 " normalized order range ",result["NormalizedOrderRange"],
 " active components ",Length[result["ActiveNormalizedRows"]],
 " refinement ratios ",result["OriginalCoefficientRefinementRatios"]];
Print["END ",DateString[]];Exit[0];
