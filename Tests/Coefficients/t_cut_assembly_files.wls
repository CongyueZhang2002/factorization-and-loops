#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=CreateDirectory[];e=FeynFacet`Private`$feynFacetEpsilon;
base=<|"FinalMomenta"->{k1,k2,k3},"TotalMomentum"->p+q,
 "ExternalMomenta"->{p,q},"ReferenceMomentum"->p,"TaggedMomentum"->k1,
 "MeasurementVariable"->z,"KinematicRules"->{
  FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->0,FeynCalc`SPD[p,q]->s/2},
 "Assumptions"->s>0&&0<z<1|>;
family=FeynFacet`CreateMeasuredPhaseSpaceDefinition[Join[base,<|"Name"->"FileSource",
 "OrdinaryPropagators"->{FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[p-k2,D],0,0,{1,1}]]}|>]];
targetFamily=Join[family,<|"Topology"->ReplacePart[family["Topology"],1->"FileTarget"]|>];
master=FeynCalc`GLI["FileSource",{1,1,1,1,1}];
targetMaster=FeynCalc`GLI["FileTarget",{1,1,1,1,1}];
setup=<|"Partons"->({FeynArts`F[3,{1}],FeynArts`F[4,{1}]}->
 {FeynArts`F[3,{1}],FeynArts`F[4,{1}],FeynArts`V[5],FeynArts`V[5]}),
 "HadronMomentum"->({pa,pb}->{ph,FeynFacet`NA,FeynFacet`NA,FeynFacet`NA})|>;
record=<|"Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
 "DimensionalRegulator"->e,"PreFactor"->1,"FractionMeasure"->1,"PhaseSpace"->1,
 "Masters"->{<|"Master"->master,"Terms"->{<|"Representation"->"Exact","PreFactor"->1,
 "Coefficient"->2+3e|>}|>},"RemainderTerms"->{},
 "Definitions"-><|"Setup"->setup,"Topologies"->{family}|>|>;
catalog=<|"Families"->{targetFamily},"Integrals"->{targetMaster},"Normalization"->1|>;
sourceFile=dir<>"/source.wxf";targetFile=dir<>"/target.wxf";mapFile=dir<>"/map.wxf";
Export[sourceFile,record,"WXF"];Export[targetFile,catalog,"WXF"];
matchRequest=dir<>"/match.wl";
Put[<|"SourceCoefficientFile"->sourceFile,"TargetCatalogFile"->targetFile,
 "SourceNormalization"->1|>,matchRequest];
run[script_,arguments_]:=RunProcess[Join[{"wolframscript","-file",root<>"/"<>script},arguments],
 ProcessDirectory->root];
matched=run["Scripts/match_cut_integral_catalogs.wls",{matchRequest,mapFile}];
FTTest`FTAssert["the real catalog producer writes a complete definition-bound match",
 matched["ExitCode"]===0&&Import[mapFile,"WXF"]["Status"]==="Complete"];
If[matched["ExitCode"]=!=0,Print[matched];DeleteDirectory[dir,DeleteContents->True];FTTest`FTReport[]];
assemblyRequest=dir<>"/assemble.wl";
assemble[changes_Association]:=Module[{input},
 input=Join[<|"CoefficientFiles"->{sourceFile},"MasterIntegralRulesFile"->mapFile,
  "Weights"->{1},"OutputFile"->dir<>"/assembled.wxf"|>,changes];
 Put[input,assemblyRequest];run["Scripts/Coefficients/assemble_cut_coefficients.wls",{assemblyRequest}]
];
assembled=assemble[<||>];
FTTest`FTAssert["a singular map file survives the producer-consumer WXF round-trip",
 assembled["ExitCode"]===0&&With[{result=Import[dir<>"/assembled.wxf","WXF"]},
  Length[result["Masters"]]===1&&result["Masters"][[1,"Master"]]===targetMaster&&
  result["Masters"][[1,"Terms",1,"Coefficient"]]===2+3e]];
Put[{},dir<>"/empty.wl"];
plural=assemble[<|"MasterIntegralRulesFile"->dir<>"/empty.wl","MasterIntegralRulesFiles"->{mapFile}|>];
FTTest`FTAssert["per-contribution map files use the same bound-record checks",plural["ExitCode"]===0];
badSource=Import[mapFile,"WXF"];badSource=Append[badSource,"SourceIntegrals"->{}];
Export[dir<>"/wrong-source.wxf",badSource,"WXF"];
wrong=assemble[<|"MasterIntegralRulesFile"->dir<>"/wrong-source.wxf"|>];
FTTest`FTAssert["the singular file path rejects a source mismatch",
 wrong["ExitCode"]=!=0&&StringContainsQ[wrong["StandardOutput"],"MatchingCompleteSourceCatalogRequired"]];
wrong=assemble[<|"TargetTopologies"->{Append[targetFamily,"MeasurePrefactor"->2]}|>];
FTTest`FTAssert["direct target topology input cannot bypass a map-file binding",
 wrong["ExitCode"]=!=0&&StringContainsQ[wrong["StandardOutput"],"BoundTargetTopologyMismatch"]];
wrong=assemble[<|"OutputFile"->dir<>"/wrong-format.wl"|>];
FTTest`FTAssert["a WXF writer rejects a misleading Wolfram text extension",
 wrong["ExitCode"]=!=0&&!FileExistsQ[dir<>"/wrong-format.wl"]];
CreateDirectory[dir<>"/occupied.wxf"];
wrong=assemble[<|"OutputFile"->dir<>"/occupied.wxf"|>];
FTTest`FTAssert["a failed final rename cannot report successful assembly",
 wrong["ExitCode"]=!=0&&!StringContainsQ[wrong["StandardOutput"],"COMPLETED CUT ASSEMBLY"]];
changed=Join[family,<|"Cuts"->ReplacePart[family["Cuts"],{1,"EnergyDirection"}->-1]|>];
unmapped=FeynFacet`AssembleCutContributions[{record},"Weights"->{1},
 "TargetTopologies"->{changed}];
FTTest`FTAssert["typed energy directions remain part of identity-fallback checks",
 MatchQ[unmapped,Failure["UnmappedMasterTopologyMismatch",_Association]]];
Put[<|"Relations"->42,"Request"-><||>|>,dir<>"/malformed-relation.wl"];
wrong=run["Scripts/reduce_matched_integral_catalog.wls",
 {dir<>"/malformed-relation.wl",mapFile,dir<>"/malformed-relation-output.wxf"}];
FTTest`FTAssert["a malformed relation request cannot publish an unevaluated function",
 wrong["ExitCode"]=!=0&&!FileExistsQ[dir<>"/malformed-relation-output.wxf"]];
DeleteDirectory[dir,DeleteContents->True];
FTTest`FTReport[];
