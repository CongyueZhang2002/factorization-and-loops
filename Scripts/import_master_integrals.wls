Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[!MemberQ[{3,4},Length[args]],
 Print["Usage: import_master_integrals.wls DEFINITIONS SOLUTION REPORT [LIBRARY_DIRECTORY]"];Exit[2]];
definitions=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[1]]]];
solution=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[2]]]];
If[!AssociationQ[definitions]||!AssociationQ[solution],Print["Definition and solution records required"];Exit[1]];
request=<|"Mode"->"ReadWrite",
 "CoordinateRules"->Lookup[definitions,"SolutionToIntegralCoordinates",{}],
 "Provenance"-><|"Producer"->"import_master_integrals.wls",
  "SourceFile"->ExpandFileName[args[[2]]]|>|>;
If[Length[args]===4,request=Append[request,"LibraryDirectory"->ExpandFileName[args[[4]]]]];
{seconds,result}=AbsoluteTiming[FeynFacet`StoreMasterIntegralSolution[
 definitions["MasterIntegralDefinitions"],solution,request]];
If[!AssociationQ[result],Print[result];Exit[1]];
report=Join[result,<|"PublicationSeconds"->seconds,"LibraryDirectory"->Lookup[
 request,"LibraryDirectory",FeynFacet`MasterIntegralLibraryDirectory[]]|>];
target=ExpandFileName[args[[3]]];
If[FeynFacet`FamilyArtifactWrite[report,target]=!=target,Print["Import report write failed"];Exit[1]];
Print["IMPORTED PHYSICAL MASTER VALUES ",result["MasterCount"]," SECONDS ",seconds];
