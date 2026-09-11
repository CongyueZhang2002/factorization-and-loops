#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Expected REQUEST.wl OUTPUT.wxf"];Exit[2]];
read[file_]:=If[ToLowerCase[FileExtension[file]]==="wxf",Import[file,"WXF"],Get[file]];
file=ExpandFileName[Last[args]];
If[ToLowerCase[FileExtension[file]]=!="wxf",Print["Output must have .wxf extension"];Exit[2]];
request=read[ExpandFileName[First[args]]];
If[!AssociationQ[request]||!ContainsAll[Keys[request],{"TargetCatalogFile","SourceNormalization"}]||
 Count[KeyExistsQ[request,#]&/@{"SourceCoefficientFile","SourceReductionMetadataFile"},True]=!=1,
 Print["A source coefficient table or reduction metadata, target catalog and normalization are required"];Exit[2]];
If[KeyExistsQ[request,"SourceCoefficientFile"],
 source=FeynFacet`ReadMasterIntegralCoefficients[request["SourceCoefficientFile"]];
 If[FailureQ[source]||!AssociationQ[source],Print["Coefficient catalog input failed"];Exit[1]];
 definitions=source["Definitions"];integrals=Lookup[source["Masters"],"Master"];
 sourceReference=KeyTake[request,{"SourceCoefficientFile"}],
 source=FeynFacet`Private`coefficientReadRecord[request["SourceReductionMetadataFile"]];
 If[!AssociationQ[source]||!FeynFacet`Private`coefficientKiraReductionQ[Append[source,"KiraRules"->{}]],
  Print["Reduction metadata catalog input failed"];Exit[1]];
 definitions=KeyTake[source,{"CardName","Setup","Pairs","AnalyticContext","Topologies",
  "TopologyEquivalence","ReverseRules","MassDimensions","DimensionRule"}];
 integrals=source["Masters"];sourceReference=KeyTake[request,{"SourceReductionMetadataFile"}]
];
target=read[request["TargetCatalogFile"]];
If[!AssociationQ[target],Print["Target catalog input failed"];Exit[1]];
catalog=<|"Integrals"->integrals,"Families"->definitions["Topologies"],
 "Normalization"->request["SourceNormalization"]|>;
seconds=First[AbsoluteTiming[result=FeynFacet`MatchCutIntegralCatalogs[catalog,target]]];
If[!AssociationQ[result]||Lookup[result,"DataType",None]=!="CutIntegralCatalogMatch"||
 !MemberQ[{"Complete","UnmatchedIntegralsRemain"},Lookup[result,"Status",None]],
 Print["Catalog matching failed: ",result];Exit[1]];
result=Join[result,Map[ExpandFileName,sourceReference],<|"SourceDefinitions"->definitions,"SourceIntegrals"->catalog["Integrals"],"TargetCatalog"->target,
 "TargetCatalogFile"->ExpandFileName[request["TargetCatalogFile"]],
 "Seconds"->seconds|>];
file=ExpandFileName[Last[args]];temporary=file<>".partial";
If[!DirectoryQ[DirectoryName[file]],CreateDirectory[DirectoryName[file],CreateIntermediateDirectories->True]];
If[!StringQ[Quiet[Check[Export[temporary,result,"WXF",PerformanceGoal->"Size"],$Failed]]],
 Print["WXF output failed"];Exit[1]];
If[Import[temporary,"WXF"]=!=result,Print["Catalog match read-back mismatch"];Exit[1]];
If[!StringQ[Quiet[Check[RenameFile[temporary,file,OverwriteTarget->True],$Failed]]],
 Print["WXF output rename failed"];Exit[1]];
summary=Join[KeyTake[result,{"Status","SourceCount","TargetCount","Method","Seconds"}],
 <|"MatchedCount"->Length[result["Mappings"]],
   "UnmatchedIntegrals"->(ToString[#,InputForm]&/@result["UnmatchedIntegrals"])|>];
Export[file<>".json",summary,"RawJSON"];Print["COMPLETED CATALOG MATCH ",summary];
If[result["Status"]=!="Complete",Exit[1]];Exit[0];
