
#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/FeynFacet/Solution.m"];
If[Length[$ScriptCommandLine]<2,Print["Usage: apply_amplitude_relations.wls input.wxf"];Exit[1]];
file=ExpandFileName[Last[$ScriptCommandLine]];base=DirectoryName[file];
read[path_]:=If[FileExtension[path]==="wxf",Import[path,"WXF"],Get[path]];
resolve[path_]:=ExpandFileName[If[StringStartsQ[path,"/"],path,FileNameJoin[{base,path}]]];
relative[from_,to_]:=Module[{left=FileNameSplit[from],right=FileNameSplit[to],k=0},
 While[k<Min[Length[left],Length[right]]&&left[[k+1]]===right[[k+1]],k++];
 FileNameJoin[Join[ConstantArray["..",Length[left]-k],Drop[right,k]]]];
spec=read[file];shared=read[resolve[spec["SharedBoundaryDefinitions"]]];
reduction=read[resolve[spec["AmplitudeReduction"]]];
output=resolve[spec["OutputDirectory"]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
result=FeynFacetSolution`ApplyBoundaryAmplitudeReduction[shared,reduction];
If[FailureQ[result],Print["FAILED ",result];Exit[1]];
result=Join[result,<|"NumericalConstructionFile"->"construction_input.wxf",
 "AmplitudeReductionSource"->relative[output,resolve[spec["AmplitudeReduction"]]]|>];
atomic[value_,path_]:=(Export[path<>".tmp",BinarySerialize[value,PerformanceGoal->"Size"],"Byte"];RenameFile[path<>".tmp",path,OverwriteTarget->True]);
atomic[result,output<>"/shared_boundary_coefficients.wxf"];
construction=read[resolve[spec["SingularBoundaryConstruction"]]];
construction=Join[construction,<|"AmplitudeReduction"->reduction|>];
atomic[construction,output<>"/construction_input.wxf"];
reports={};updated={};
Do[
 path=resolve[solutionFile];record=read[path];
 requested=DeleteDuplicates@Cases[record["MasterIntegralCoefficients"],
   FeynFacetSolution`B[i_Integer,q_Integer]:>{i,q},Infinity];
 selected=Association@Table[key->result["BoundaryCoefficientDefinitions"][[Key[key]]],{key,requested}];
 required=Sort[DeleteDuplicates@Cases[selected,FeynFacetSolution`C[i_Integer,q_Integer]:>{i,q},Infinity]];
 record=Join[record,KeyTake[result,{"BoundaryAmplitudes","InitialConstantLaurentLowerBounds","UnknownBoundarySeriesCount","PhysicalBoundaryValuesComplete","PhysicalBoundaryValuesCompleteForStoredOrders"}],
  <|"RequiredInitialConstantCoefficients"->required,"UnknownLaurentCoefficientCount"->Length[required],
   "SharedBoundaryDefinitionFile"->relative[DirectoryName[path],output<>"/shared_boundary_coefficients.wxf"]|>];
 If[TrueQ[Lookup[spec,"ReplaceSourceSolutions",False]],atomic[record,path];AppendTo[updated,path]];
 AppendTo[reports,<|"SolutionFile"->path,"BoundaryCoefficientCount"->Length[requested],
   "RequiredAmplitudeCoefficientCount"->Length[required],
   "SharedBoundaryPathResolves"->FileExistsQ[ExpandFileName[FileNameJoin[{DirectoryName[path],record["SharedBoundaryDefinitionFile"]}]]]|>],
 {solutionFile,spec["SolutionFiles"]}];
report=<|"DataType"->"BoundaryAmplitudeApplication","UnknownBoundarySeriesCount"->result["UnknownBoundarySeriesCount"],
 "RequiredAmplitudeCoefficientCount"->result["UnknownLaurentCoefficientCount"],
 "SolutionFileCount"->Length[reports],"UpdatedSolutionCount"->Length[updated],"FamilyReports"->reports,
 "PhysicalBoundaryValuesComplete"->TrueQ[result["PhysicalBoundaryValuesComplete"]]|>;
atomic[report,output<>"/amplitude_application_report.wxf"];
If[!AllTrue[reports,TrueQ[#["SharedBoundaryPathResolves"]]&],Print["FAILED PATH CHECK"];Exit[1]];
Print["PASS AMPLITUDE APPLICATION ",KeyDrop[report,"FamilyReports"]];Exit[0];
