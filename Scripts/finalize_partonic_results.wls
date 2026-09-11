Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=1,Print["Usage: finalize_partonic_results.wls PLAN.wl"];Exit[2]];
file=ExpandFileName[First[args]];plan=FeynFacet`FamilyArtifactRead[file];
resolve[path_]:=If[StringStartsQ[path,$PathnameSeparator],path,ExpandFileName[DirectoryName[file]<>"/"<>path]];
results=Map[FeynFacet`ReadPartonicResult[resolve[#["SourceResult"]]]&,plan["Results"]];
If[!AllTrue[Values[results],AssociationQ],Print["Complete combined results are required"];Exit[1]];
{sec,check}=AbsoluteTiming[FeynFacet`VerifyPartonicPoleCancellation[results,plan["ParameterPoints"],plan["NumericalOptions"]]];
FeynFacet`FamilyArtifactWrite[check,resolve[plan["PoleCheckFile"]],Compression->Automatic];
If[!AssociationQ[check]||check["Status"]=!="Passed",Print["POLE CHECK FAILED"];Exit[1]];
Print["COMPLETE POLE CHECK ",check["CoefficientCount"]," COEFFICIENTS ",sec," s"];
ranges=Map[#["EpsilonRange"]&,plan["Results"]];
final=FeynFacet`FinalizePartonicResults[results,check,<|"EpsilonRanges"->ranges,
 "MetadataByResult"->Map[Lookup[#,"Metadata",<||>]&,plan["Results"]]|>];
If[!AssociationQ[final]||!AllTrue[Values[final],AssociationQ],Print["FINALIZATION FAILED ",InputForm[final]];Exit[1]];
Do[
 target=resolve[plan["Results"][name]["OutputFile"]];
 FeynFacet`FamilyArtifactWrite[final[name],target,"Compression"->True];
 reread=FeynFacet`ReadPartonicResult[target];
 If[!AssociationQ[reread]||KeyDrop[reread,"Coefficients"]=!=KeyDrop[final[name],"Coefficients"]||
   KeySort[FeynFacet`PartonicScalarCoefficientRules[reread]]=!=KeySort[FeynFacet`PartonicScalarCoefficientRules[final[name]]],
  Print["SERIALIZATION FAILED ",name];Exit[1]];
 Print["FINAL RESULT ",name," ",FileByteCount[target]," BYTES"],
{name,Keys[final]}];
Print["COMPLETED FINITE PARTONIC RESULTS ",Length[final]];
