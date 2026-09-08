
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
args=Rest[$ScriptCommandLine];label=First[args];families=Rest[args];
output=FileNameJoin[{$TemporaryDirectory,"feynfacet-stage2-benchmark",label}];
If[label==="baseline",
 Block[{$Context="FeynFacet`Private`",$ContextPath={"System`","FeynFacet`"}},
  Scan[Get[FileNameJoin[{DirectoryName[ExpandFileName[$InputFileName]],"before",#}]]&,
   {"FeynFacet/Private/Transport/Orders/LaurentBounds.wl",
    "FeynFacet/Private/Transport/Solutions/FiniteMasterIntegralSolution.wl",
    "FeynFacet/Private/Transport/Orders/MasterIntegralExpansionOrders.wl",
    "FeynFacet/Private/Transport/Solutions/MasterIntegralSolutionFromOrders.wl"}]]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
reports={};
Do[
 specification=Import[FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","RequestedMasterIntegralSolutions",name,"input.wxf"}],"WXF"];
 Print["Starting ",label," ",name];
 construction=First[AbsoluteTiming[result=ConstructMasterIntegralSolution[
   specification["Data"],specification["Request"],Sequence@@Normal[Join[specification["Options"],<|"Verbose"->False|>]]]]];
 If[FailureQ[result],Print[result];Exit[1]];
 writing=First[AbsoluteTiming[written=WriteMasterIntegralSolution[result,FileNameJoin[{output,name}],"FileFormat"->"WXF"]]];
 If[FailureQ[written],Print[written];Exit[1]];
 report=<|"Family"->name,"ConstructionSeconds"->construction,"WriteSeconds"->writing,
 "TotalSeconds"->construction+writing,"BasePoint"->(ToString[#,InputForm]& /@ result["BasePoint"]),
 "TransformedOrders"->result["TransformedSystemEpsilonOrderRange"],
 "MasterCoefficientCount"->Total[Length /@ Values[result["MasterIntegralCoefficients"]]],
 "IntegralDefinitionCount"->Length[result["IntegralDefinitions"]],
 "KernelDefinitionCount"->Length[result["KernelDefinitions"]],
 "KernelArithmeticDefinitionCount"->Lookup[Lookup[result,"KernelDefinitionCounts",<||>],"SharedScalarExpressionCount",0],
 "CompressedBytes"->FileByteCount[FileNameJoin[{output,name,"solution.wxf"}]],
 "MaximumWolframMemoryBytes"->MaxMemoryUsed[]|>;
 AppendTo[reports,report];Export[FileNameJoin[{output,"measurements.json"}],reports,"RawJSON"];Print[InputForm[report]];
 Clear[result,specification],
{name,families}];
