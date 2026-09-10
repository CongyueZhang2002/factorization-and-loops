
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=1,Print["Usage: sample_cut_reduction.wls REQUEST.wl"];Exit[2]];
ipRequestFile=ExpandFileName[First[arguments]];ipRequest=FeynFacet`FamilyArtifactRead[ipRequestFile];
If[!AssociationQ[ipRequest],Print[ipRequest];Exit[1]];
ipPath[value_String]:=If[StringStartsQ[value,"/"],value,
 ExpandFileName[FileNameJoin[{DirectoryName[ipRequestFile],value}]]];
ipInput=FeynFacet`FamilyArtifactRead[ipPath[ipRequest["InputFile"]]];
ipPlans=FeynFacet`FamilyArtifactRead[ipPath[ipRequest["SeedPlanFile"]]];
ipKnown=FeynFacet`FamilyArtifactRead[ipPath[ipRequest["KnownDifferentialSystemFile"]]];
If[!AllTrue[{ipInput,ipPlans,ipKnown},AssociationQ],Print["Complete reduction input, seed plans and known DE are required"];Exit[1]];
ipPlanByName=Association[(#["Family"]->#)&/@ipPlans["Plans"]];
ipUnclassifiedFile=FileNameJoin[{DirectoryName[ipPath[ipRequest["EquationFile"]]],"GeneratedIntegralEquations.wl"}];
ipGenerationDefinition=<|"IntegralDefinitions"->KeyTake[ipInput,{"Families","Targets"}],
 "SeedPlans"->ipPlans,"KnownDifferentialSystem"->ipKnown|>;
ipCheckpoint=If[FileExistsQ[ipUnclassifiedFile],FeynFacet`FamilyArtifactRead[ipUnclassifiedFile],None];
If[AssociationQ[ipCheckpoint]&&Lookup[ipCheckpoint,"GenerationDefinition",None]===ipGenerationDefinition,
 ipRows=ipCheckpoint["Rows"];ipColumns=ipCheckpoint["Columns"];ipTimings=ipCheckpoint["GenerationSeconds"];
 Print["REUSING ",Length[ipRows]," EXACT GENERATED EQUATIONS"],
ipRows={};ipTimings=<||>;
Do[
 ipName=ipFamily["Topology"][[1]];ipSeeds=ipPlanByName[ipName]["Seeds"];
 Print["GENERATING ",ipName," SEEDS ",Length[ipSeeds]];
 {ipSeconds,ipGenerated}=AbsoluteTiming[FeynFacet`GenerateCutIBPEquations[ipFamily,ipSeeds]];
 If[!AssociationQ[ipGenerated],Print[ipGenerated];Exit[1]];
 AppendTo[ipRows,ipGenerated["Rows"]];AssociateTo[ipTimings,ToString[ipName,InputForm]->ipSeconds],
 {ipFamily,ipInput["Families"]}];
ipRows=Flatten[ipRows,1];
ipDERelations=FeynFacet`IntegralRelationsFromCutDifferentialSystem[ipKnown];
If[!AssociationQ[ipDERelations],Print[ipDERelations];Exit[1]];
ipRows=Join[ipRows,ipDERelations["Rows"]];
Print["KNOWN DE EQUATIONS ",Length[ipDERelations["Rows"]]];
ipColumns=DeleteDuplicates[Join[ipInput["Targets"],ipKnown["MasterIntegralBasis"],Flatten[Keys/@ipRows]]];

 FeynFacet`FamilyArtifactWrite[<|"Rows"->ipRows,"Columns"->ipColumns,"GenerationSeconds"->ipTimings,
  "GenerationDefinition"->ipGenerationDefinition|>,ipUnclassifiedFile,Compression->Automatic]
];
Print["CLASSIFYING ",Length[ipColumns]," POWERED INTEGRAL COLUMNS"];
{ipEquivalenceSeconds,ipEquivalences}=AbsoluteTiming[FeynFacet`FindCutIntegralEquivalences[
 ipColumns,ipInput["Families"],"Normalization"->"FullTypedIntegralDefinitions",
 "PreferredMasterIntegrals"->ipKnown["MasterIntegralBasis"]]];
If[!AssociationQ[ipEquivalences],Print[ipEquivalences];Exit[1]];
ipExtra=Map[Function[mapping,If[mapping["Source"]===mapping["Representative"],Nothing,
 <|mapping["Source"]->1,mapping["Representative"]->-mapping["Factor"]|>]],ipEquivalences["Mappings"]];
ipRows=Join[ipRows,ipExtra];
Print["EQUIVALENCE EQUATIONS ",Length[ipExtra]," SECONDS ",ipEquivalenceSeconds];
ipEquationFile=ipPath[ipRequest["EquationFile"]];
FeynFacet`FamilyArtifactWrite[<|"Rows"->ipRows,"Families"->ipInput["Families"],
 "Targets"->ipInput["Targets"],"PreferredMasterIntegrals"->ipKnown["MasterIntegralBasis"],
 "SeedPlans"->ipPlans,"IntegralEquivalences"->ipEquivalences,
 "KnownDifferentialSystem"->ipKnown,"GenerationSeconds"->ipTimings|>,
 ipEquationFile,Compression->Automatic];
Print["SAMPLING ",Length[ipRows]," EQUATIONS ",Length[ipColumns]," COLUMNS"];
ipSample=FeynFacet`SampleCutIBPEquations[ipRows,ipInput["Targets"],ipInput["Families"],
 Join[KeyTake[ipRequest,{"Points","Prime","Threads"}],<|
 "WorkingDirectory"->ipPath[ipRequest["WorkingDirectory"]],
 "PreferredMasterIntegrals"->ipKnown["MasterIntegralBasis"]|>]];
FeynFacet`FamilyArtifactWrite[ipSample,ipPath[ipRequest["OutputFile"]],Compression->Automatic];
If[!AssociationQ[ipSample],Print[ipSample];Exit[1]];
Print["TARGET REMAINDER RANKS ",Lookup[ipSample["Samples"],"TargetRemainderRank"]];
Print["COMPLETED ",ipPath[ipRequest["OutputFile"]]];
