#!/usr/bin/env wolframscript
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"FeynFacet", "Solution.m"}]];
args=Rest[$ScriptCommandLine];
If[Length[args]!=3,Print["Expected SOLUTION_DIRECTORY REQUEST.wl OUTPUT.wxf"];Exit[2]];
request=FeynFacetRecords`ReadRecord[args[[2]]];data=FeynFacetSolution`ReadMasterIntegralSolution[args[[1]]];
result=Catch[Module[{options=Lookup[request,"Options",{}],boundary,normalize,ag,pg},
 If[KeyExistsQ[request,"BoundaryDataFile"],
  boundary=FeynFacetSolution`Private`readNumericalFile[request["BoundaryDataFile"]];
  normalize[z_] := z/.s_Symbol /;SymbolName[s]==="GLI":>Global`GLI;
  If[normalize[boundary["OriginalMasterIntegralBasis"]]=!=normalize[data["OriginalMasterIntegralBasis"]]||
    boundary["Point"]=!=data["BasePoint"]||
    Lookup[boundary,"RowIndices",Range[Length[data["OriginalMasterIntegralBasis"]]]]=!=Range[Length[data["OriginalMasterIntegralBasis"]]],
   Throw[Failure["BoundaryBasisOrPointMismatch",<||>]]];
  ag="AccuracyGoal"/.options/."AccuracyGoal"->20;pg="PrecisionGoal"/.options/."PrecisionGoal"->20;
  If[Lookup[boundary,"PrecisionGoal",Infinity]<Max[ag,pg]+5,
   Throw[Failure["BoundaryAccuracyInsufficient",<||>]]];
  options=Join[DeleteCases[options,Rule["InitialConstantValues",_]],
    {"InitialConstantValues"->boundary["InitialConstantValues"]}]];
 FeynFacetSolution`ConstructMasterIntegralTaylorExpansion[data,request["Direction"],Sequence@@options]
]];
output=ExpandFileName[args[[3]]];
If[!DirectoryQ[DirectoryName[output]],CreateDirectory[DirectoryName[output],CreateIntermediateDirectories->True]];
temporary=output<>".tmp-"<>ToString[$ProcessID];Export[temporary,result,"WXF"];
RenameFile[temporary,output,OverwriteTarget->True];
Print[If[AssociationQ[result],KeyTake[result,{"Status","ValidatedParameterRadius","ConstructionSeconds"}],result]];
Exit[If[AssociationQ[result]&&result["Status"]==="TaylorExpansionValidated",0,1]];
