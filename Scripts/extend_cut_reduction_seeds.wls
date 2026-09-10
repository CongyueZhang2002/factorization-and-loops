
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=2,Print["Usage: extend_cut_reduction_seeds.wls PREVIOUS_EQUATIONS.wl REQUEST.wl"];Exit[2]];
{esPreviousFile,esRequestFile}=ExpandFileName/@arguments;
esPrevious=FeynFacet`FamilyArtifactRead[esPreviousFile];
esRequest=FeynFacet`FamilyArtifactRead[esRequestFile];
esPath[value_String]:=If[StringStartsQ[value,"/"],value,
 ExpandFileName[FileNameJoin[{DirectoryName[esRequestFile],value}]]];
esSample=FeynFacet`FamilyArtifactRead[esPath[esRequest["PreviousSampleFile"]]];
If[!AllTrue[{esPrevious,esRequest,esSample},AssociationQ]||
 Lookup[esSample,"Format",None]=!="FeynFacet-FiniteFieldIBPSamples",
 Print["A completed previous finite-field sample is required"];Exit[1]];
esFrontier=DeleteDuplicates[Flatten[Lookup[esSample["Samples"],"NonpreferredIntegralColumns"],1]];
esPlans=Association[(#["Family"]->#)&/@esPrevious["SeedPlans"]["Plans"]];
esNewRows={};esCounts=<||>;esSeconds=<||>;esAllNewSeeds={};
Do[
 esName=esFamily["Topology"][[1]];esLocal=Select[esFrontier,#[[1]]===esName&];
 If[esLocal==={},Continue[]];
 esSelection=FeynFacet`FindCutIBPPredecessorSeeds[esFamily,esLocal,esPlans[esName]["Seeds"],
 KeyTake[esRequest,{"MaximumCandidates","FrontierNeighborDepth"}]];
 If[!AssociationQ[esSelection],Print[esSelection];Exit[1]];
 esSeeds=esSelection["Seeds"];If[esSeeds==={},Continue[]];
 Print["EXTENDING ",esName," BY ",Length[esSeeds]," SEEDS"];
 {esTime,esGenerated}=AbsoluteTiming[FeynFacet`GenerateCutIBPEquations[esFamily,esSeeds]];
 If[!AssociationQ[esGenerated],Print[esGenerated];Exit[1]];
 AppendTo[esNewRows,esGenerated["Rows"]];AppendTo[esAllNewSeeds,esSeeds];
 AssociateTo[esCounts,ToString[esName,InputForm]->Length[esSeeds]];
 AssociateTo[esSeconds,ToString[esName,InputForm]->esTime];
 esPlan=esPlans[esName];
 esJoinedSeeds=Union[esPlan["Seeds"],esSeeds];
 AssociateTo[esPlans,esName->Join[KeyDrop[esPlan,{"Seeds","Sectors"}],<|
  "InitialSectorProfiles"->Lookup[esPlan,"InitialSectorProfiles",Lookup[esPlan,"Sectors",{}]],
  "Seeds"->esJoinedSeeds,"SeedCount"->Length[esJoinedSeeds],
  "ExpansionMethod"->"ExactIBPPredecessors"|>]],
 {esFamily,esPrevious["Families"]}];
esNewRows=Flatten[esNewRows,1];
If[esNewRows==={},Print["No new admissible predecessor seeds; a broader declared seed region is needed"];Exit[1]];
esRows=Join[esPrevious["Rows"],esNewRows];
esColumns=DeleteDuplicates[Join[esPrevious["Targets"],esPrevious["PreferredMasterIntegrals"],Flatten[Keys/@esRows]]];
Print["CLASSIFYING ",Length[esColumns]," INTEGRAL COLUMNS"];
{esEquivalenceSeconds,esEquivalences}=AbsoluteTiming[FeynFacet`FindCutIntegralEquivalences[
 esColumns,esPrevious["Families"],"Normalization"->"FullTypedIntegralDefinitions",
 "PreferredMasterIntegrals"->esPrevious["PreferredMasterIntegrals"]]];
If[!AssociationQ[esEquivalences],Print[esEquivalences];Exit[1]];
esExtra=Map[Function[mapping,If[mapping["Source"]===mapping["Representative"],Nothing,
 <|mapping["Source"]->1,mapping["Representative"]->-mapping["Factor"]|>]],esEquivalences["Mappings"]];
esRows=DeleteDuplicates[Join[esRows,esExtra]];
esPlanRecord=Join[esPrevious["SeedPlans"],<|"Plans"->Values[esPlans],
 "SeedCount"->Total[Lookup[Values[esPlans],"SeedCount"]]|>];
esOutput=Join[esPrevious,<|"Rows"->esRows,"SeedPlans"->esPlanRecord,
 "IntegralEquivalences"->esEquivalences,"PreviousEquationFile"->esPreviousFile,
 "PredecessorSeedCounts"->esCounts,"PredecessorGenerationSeconds"->esSeconds,
 "EquivalenceSeconds"->esEquivalenceSeconds|>];
FeynFacet`FamilyArtifactWrite[esOutput,esPath[esRequest["EquationFile"]],Compression->Automatic];
Print["SAMPLING ",Length[esRows]," EQUATIONS AFTER ",Total[Values[esCounts]]," NEW SEEDS"];
esResult=FeynFacet`SampleCutIBPEquations[esRows,esPrevious["Targets"],esPrevious["Families"],
 Join[KeyTake[esRequest,{"Points","Prime","Threads","MaximumSelectionClosureIterations"}],<|
 "WorkingDirectory"->esPath[esRequest["WorkingDirectory"]],
 "PreferredMasterIntegrals"->esPrevious["PreferredMasterIntegrals"]|>]];
FeynFacet`FamilyArtifactWrite[esResult,esPath[esRequest["OutputFile"]],Compression->Automatic];
If[!AssociationQ[esResult],Print["FAILED ",If[FailureQ[esResult],esResult[[1]],Head[esResult]]];Exit[1]];
Print["TARGET REMAINDER RANKS ",Lookup[esResult["Samples"],"TargetRemainderRank"]];
Print["COMPLETED ",esPath[esRequest["OutputFile"]]];
