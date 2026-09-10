$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]=!=2,Print["Usage: compact_partonic_results.wls PROJECT ORDER"];Exit[2]];
project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>First[args]];order=Last[args];before=0;after=0;
Do[
 file=project["Directory"]<>"/"<>order<>"/"<>channel<>"/Results/Result.wl";
 result=FeynFacet`ReadPartonicResult[file];If[!AssociationQ[result],Print["Complete result required"];Exit[1]];
 before+=FileByteCount[file];
 FeynFacet`FamilyArtifactWrite[result,file,"Compression"->True];
 reread=FeynFacet`ReadPartonicResult[file];
 If[!AssociationQ[reread]||KeyDrop[reread,"Coefficients"]=!=KeyDrop[result,"Coefficients"]||
 KeySort[FeynFacet`PartonicScalarCoefficientRules[reread]]=!=KeySort[FeynFacet`PartonicScalarCoefficientRules[result]],
 Print["Compaction changed the result ",channel];Exit[1]];
 after+=FileByteCount[file],
{channel,project["Orders"][order]}];
Print["COMPLETED LOSSLESS PARTONIC COMPACTION ",First[args]," ",before," -> ",after," BYTES"];
