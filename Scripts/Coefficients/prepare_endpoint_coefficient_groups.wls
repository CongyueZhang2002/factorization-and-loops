Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Expected REQUEST.wl ENDPOINT_CATALOG.wl OUTPUT_DIRECTORY"];Exit[2]];
request=Get[ExpandFileName[args[[1]]]];
table=FeynFacet`ReadMasterIntegralCoefficients[request["CoefficientFile"]];
catalog=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[2]]]];
If[!AssociationQ[table]||!AssociationQ[catalog],Print["COEFFICIENT INPUTS FAILED"];Exit[1]];
options=Join[KeyTake[request,{"ThroughOrder","KinematicRules","Assumptions","FrameTimeLimit","MaximumFrameAttempts"}],
 <|"SourceCoefficientFile"->ExpandFileName[request["CoefficientFile"]]|>];
{seconds,result}=AbsoluteTiming[FeynFacet`ConstructEndpointCoefficientGroups[table,catalog,options]];
If[!AssociationQ[result],Print["ENDPOINT GROUP PLANNING FAILED ",result];Exit[1]];
output=ExpandFileName[args[[3]]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
files=Association@KeyValueMap[Function[{name,input},Module[{file=FileNameJoin[{output,name<>".wxf"}]},
 Export[file,Append[input,"DataType"->"EndpointCoefficientInput"],"WXF"];
 name->file]],result["CoefficientInputs"]];
FeynFacet`FamilyArtifactWrite[KeyDrop[result,"CoefficientInputs"],output<>"/groups.wl","Compression"->True];
Export[output<>"/manifest.json",<|"Status"->"ExactCoefficientGroupsPrepared","InputFiles"->files,
 "CoefficientContributionCount"->Length[files],"MovingDivisorCount"->Length[result["PoleGroups"]],
 "SourceMasterCount"->Length[result["ExactSourceRecombinations"]],"Seconds"->seconds|>,"RawJSON"];
Print["ENDPOINT COEFFICIENT GROUPS COMPLETE ",Length[files]," contributions; ",seconds," seconds"];
