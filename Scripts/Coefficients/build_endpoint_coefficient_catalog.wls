Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Expected CUT_CATALOG.wxf ACCEPTED_ENDPOINTS.json OUTPUT.wl"];Exit[2]];
cut=Import[ExpandFileName[args[[1]]],"WXF"];
manifest=Import[ExpandFileName[args[[2]]],"RawJSON"];
directories=Lookup[manifest,"AcceptedDirectories",<||>];
frames=Association@KeyValueMap[#1-><|"Endpoint"->FileNameJoin[{#2,"endpoint_system.wxf"}],
 "Bounds"->FileNameJoin[{#2,"laurent_bounds.wxf"}],
 "BoundaryBasisMatching"->FileNameJoin[{#2,"boundary_basis_matching.wxf"}],
 "SourceInput"->FileNameJoin[{#2,"input.wxf"}],
 "SourceDifferentialSystemFile"->FileNameJoin[{#2,"source_system.wxf"}],
 "AcceptedEndpointDirectory"->#2|>&,directories];
{seconds,result}=AbsoluteTiming[FeynFacet`BuildEndpointCoefficientCatalog[cut,frames]];
If[!AssociationQ[result],Print["ENDPOINT CATALOG FAILED ",result];Exit[1]];
output=ExpandFileName[args[[3]]];
FeynFacet`FamilyArtifactWrite[result,output,"Compression"->True];
If[FeynFacet`FamilyArtifactRead[output]=!=result,Print["ENDPOINT CATALOG READBACK FAILED"];Exit[1]];
Print["ENDPOINT COEFFICIENT CATALOG COMPLETE ",Length[result["Frames"]]," frames; ",seconds," seconds"];
