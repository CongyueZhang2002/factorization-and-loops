#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Expected RELATION_REQUEST.wl MATCH.wxf OUTPUT.wxf"];Exit[2]];
read[path_]:=If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],FeynFacetRecords`ReadRecord[path]];
file=ExpandFileName[args[[3]]];
If[ToLowerCase[FileExtension[file]]=!="wxf",Print["Output must have .wxf extension"];Exit[2]];
request=read[ExpandFileName[args[[1]]]];match=read[ExpandFileName[args[[2]]]];
If[!AssociationQ[request]||!ContainsAll[Keys[request],{"Relations","Request"}]||!AssociationQ[request["Relations"]]||!AssociationQ[request["Request"]]||!AssociationQ[match],
 Print["Relations, Request and a bound catalog match are required"];Exit[2]];
seconds=First[AbsoluteTiming[result=FeynFacet`ReduceMatchedIntegralCatalog[
 match,request["Relations"],request["Request"]]]];
If[!AssociationQ[result]||Lookup[result,"DataType",None]=!="CutIntegralCatalogMatch"||
 Lookup[result,"Status",None]=!="Complete"||!ListQ[Lookup[result,"Rules",None]]||
 !AssociationQ[Lookup[result,"IntegralRelationReduction",None]]||
 !MemberQ[{"DirectMatchesSuffice","ExactRelationsComposed"},result["IntegralRelationReduction"]["Status"]],
 Print["Integral relation adapter failed: ",result];Exit[1]];
If[!DirectoryQ[DirectoryName[file]],CreateDirectory[DirectoryName[file],CreateIntermediateDirectories->True]];
temporary=file<>".partial";
If[!StringQ[Quiet[Check[Export[temporary,result,"WXF",PerformanceGoal->"Size"],$Failed]]]||
 Import[temporary,"WXF"]=!=result,
 Print["Integral relation serialization failed"];Exit[1]];
If[!StringQ[Quiet[Check[RenameFile[temporary,file,OverwriteTarget->True],$Failed]]],
 Print["Integral relation output rename failed"];Exit[1]];
summary=<|"Status"->result["IntegralRelationReduction"]["Status"],
 "SourceCount"->result["SourceCount"],"RelationCount"->Length[Lookup[result["IntegralRelationReduction"],"Witnesses",{}]],
 "FinalIntegralCount"->Length[DeleteDuplicates[Cases[Last/@result["Rules"],h_[_,{__Integer}]/;SymbolName[h]==="GLI",Infinity]]],
 "Seconds"->seconds,"OutputBytes"->FileByteCount[file]|>;
Export[file<>".json",summary,"RawJSON"];Print["COMPLETED INTEGRAL RELATIONS ",summary];Exit[0];
