(* Explicit lower-order dependencies and the native NLO project workflow. *)
BeginPackage["FeynFacet`"];
PlanNLOProject::usage="PlanNLOProject[channelDirectory] resolves effective kernels first, then validates every explicit LO result path and epsilon requirement.";
RunNLOProject::usage="RunNLOProject[channelDirectory,mode] computes all NLO contributions through epsilon^0 using the common result format. Mode is all, resume (reuse complete matching stages), or assemble.";
Begin["`Private`"];
PlanNLOProject[directory_String]:=Catch[Module[
 {card,project,ct,channel,enumeration,rows,names,dependencies,need},
 card=projectCheck[ReadContributionCard[directory,"Counterterm"],"CountertermCardRequired"];
 If[card["Order"]=!="NLO",projectFail["NLOChannelRequired"]];
 project=projectCheck[ReadProjectCard[directory],"ProjectCardRequired"];ct=card["Counterterms"];channel=project["Channels"][card["Channel"]];
 enumeration=projectCheck[EnumerateNLOCollinearChannels[channel,<|
  "Species"->Select[Keys[project["SpeciesMap"]],collinearKernelSpeciesQ],
  "Polarization"->card["Polarization"],"Schemes"->ct["Schemes"],
  "SplittingVariable"->ct["SplittingVariable"],"KernelParameters"->ct["KernelParameters"],
  "FlavorSummation"->Lookup[project,"FlavorSummation",None]|>],"CountertermChannelEnumerationFailed"];
 rows=Select[enumeration["Channels"],MemberQ[card["Include"],#["Leg"]]&];
 rows=Map[Function[row,Join[row,<|"BornChannelName"->ProjectChannelName[project,row["BornChannel"]]|>]],rows];
 If[AnyTrue[rows,FailureQ[#["BornChannelName"]]&],projectFail["AdditionalLowerOrderChannelDeclarationRequired",<|"Channels"->Lookup[rows,"BornChannelName"]|>]];
 names=Union[{card["Channel"]},Lookup[rows,"BornChannelName"]];
 need={0,Last[card["EpsilonRange"]]+1};
 dependencies=projectLowerOrderDependencies[card,"LO",names,need];
 <|"Project"->project["Project"],"Order"->"NLO","Channel"->card["Channel"],
  "CountertermCard"->card,"LowerOrderResults"->dependencies,"CollinearChannels"->rows,
  "Reason"->"The NLO UV and collinear kernels have at most one epsilon pole, so a target through epsilon^m requires Born coefficients through epsilon^(m+1)."|>],
 "ProjectCards"];

projectIdentityValue[value_Association]:=Association@KeyValueMap[#1->projectIdentityValue[#2]&,KeySortBy[value,ToString[#,InputForm]&]];
projectIdentityValue[value_List]:=projectIdentityValue/@value;
projectIdentityValue[value_]:=value;
projectAmplitudeIdentity[setup_Association]:=projectIdentityValue[coefficientRegulatorNormalize[KeyDrop[ibpBaseSetup[setup],{"CardName","SourceNotebook","ColorRules"}],$feynFacetEpsilon]];
projectAmplitudeInputs[directory_String,setup_Association,name_String]:=Module[{files,rows,expected,actual,identity},
 files=Sort[FileNames["F*_C*.wl",directory<>"/Pairs"]];
 expected=Sort[Tuples[Lookup[Lookup[setup,{"ForwardAmplitudes","ConjugateAmplitudes"}],"DiagramIndices"]]];
 If[Length[files]=!=Length[expected],Return[$Failed]];
 rows=FamilyArtifactRead/@files;
 If[!Block[{analyticContextQ=coefficientAnalyticContextQ},AllTrue[rows,validPreIBPResultQ]],Return[$Failed]];
 actual=Sort[Lookup[#["Pair"],{"Forward","Conjugate"}]&/@rows];identity=projectAmplitudeIdentity[setup];
 If[actual=!=expected||!AllTrue[rows,#["CardName"]===name&&projectAmplitudeIdentity[#["Setup"]]===identity&],Return[$Failed]];
 rows
];
projectReductionInput[directory_String,setup_Association,name_String]:=Module[{value},
 If[!FileExistsQ[directory<>"/KiraStream/Manifest.wl"],Return[$Failed]];
 value=Quiet[Check[Block[{analyticContextQ=coefficientAnalyticContextQ},KiraStreamResult[directory<>"/KiraStream"]],$Failed]];
 If[!AssociationQ[value]||Lookup[value,"CardName",None]=!=name||
  projectAmplitudeIdentity[value["Setup"]]=!=projectAmplitudeIdentity[setup],Return[$Failed]];
 value
];
projectCoefficientInput[directory_String,setup_Association,reduction_Association]:=Module[{value},
 value=ReadMasterIntegralCoefficients[directory<>"/CoefficientResult.wl"];
 If[!AssociationQ[value]||projectAmplitudeIdentity[value["Definitions"]["Setup"]]=!=projectAmplitudeIdentity[setup]||
  Lookup[value,"ReductionInputFingerprint",None]=!=Lookup[reduction,"ReductionInputFingerprint",Missing[]]||
  Lookup[value,"SourceInputFingerprint",None]=!=Lookup[reduction,"SourceInputFingerprint",Missing[]],Return[$Failed]];
 value
];

RunNLOProject[directory_String,mode_String:"all"]:=Catch[Module[
 {project,channelDir=projectAbsolutePath[directory],location,channel,plan,card,ct,req,bornValues=<||>,
  setup,bornData,file,value,primary,contributions=<||>,parts=<||>,timings=<||>,started=AbsoluteTime[],
  elapsed,pairs,files,table,result,source,reduced,run,check,write,name,id,row,subcard,hard,report,relative,execution,
  amplitudeCard,componentNames,componentName,selectedName,componentResults,componentResult,componentPath,componentWeight,amplitudesChanged,reductionChanged,reductionData},
 If[!MemberQ[{"all","resume","assemble"},mode],projectFail["ProjectRunModeRequired"]];
 location=projectChannelLocation[channelDir];project=location["ProjectCard"];channel=location["Channel"];
 If[KeyExistsQ[project,"Current"],Return[FeynFacet`RunNLOCurrentProject[channelDir,mode]]];
 plan=projectCheck[PlanNLOProject[channelDir],"NLODependencyPlanFailed"];card=plan["CountertermCard"];ct=card["Counterterms"];
 execution=project["Execution"];req=ProjectAssemblyRequest[card];
 write[x_,suffix_]:=projectWrite[x,FileNameJoin[{channelDir,"Results",suffix}]];
 check[x_,tag_]:=If[FailureQ[x]||x===$Failed||x===$Aborted,projectFail[tag,<|"Cause"->x|>],x];
 run[script_,arguments_,label_,marker_]:=Module[{proc,seconds,log},
  {seconds,proc}=AbsoluteTiming[RunProcess[Join[{"wolframscript","-file",FileNameJoin[{$feynFacetRoot,"Scripts",script}]},arguments]]];
  log=FileNameJoin[{channelDir,"Results","Validation",label<>".log"}];
  If[!DirectoryQ[DirectoryName[log]],CreateDirectory[DirectoryName[log],CreateIntermediateDirectories->True]];
  Export[log,proc["StandardOutput"]<>proc["StandardError"],"Text"];
  If[proc["ExitCode"]=!=0||!StringContainsQ[proc["StandardOutput"],marker],projectFail["ProjectStageFailed",<|"Stage"->label,"Log"->log|>]];
  AssociateTo[timings,label->seconds];Print[label," ",Round[seconds,0.01]," seconds"];seconds];
 write[plan,"Counterterm/Dependencies.wl"];
 bornData=projectBornResults[project,plan["LowerOrderResults"],mode];
 bornValues=bornData["Results"];timings=Join[timings,bornData["StageSeconds"]];
 primary=bornValues[channel];
 relative=FileNameDrop[channelDir,Length[FileNameSplit[$feynFacetRoot]]];
 Do[
  amplitudeCard=check[ReadContributionCard[channelDir,kind],"AmplitudeCardRequired"];
  req=ProjectAssemblyRequest[amplitudeCard];
  componentNames=If[KeyExistsQ[amplitudeCard,"Components"],Keys[amplitudeCard["Components"]],{None}];
  If[componentNames==={},projectFail["NonemptyAmplitudeComponentsRequired"]];
  componentResults=<||>;
  Do[
   selectedName=If[componentName===None,kind,kind<>"."<>componentName];
   subcard=check[ReadContributionCard[channelDir,selectedName],"AmplitudeComponentRequired"];
   componentPath=subcard["ContributionPath"];
   source=componentPath<>"/Amplitudes";reduced=componentPath<>"/Reduction";
   setup=check[ReadProcessCard[subcard],"AmplitudeSetupRequired"];
   execution=subcard["Execution"];req=ProjectAssemblyRequest[subcard];
   (* Assembly consumes the completed coefficient/reduction artifacts.
      Their identities and fingerprints are checked without reparsing every
      much larger amplitude pair. A zero amplitude still needs its complete
      generated-pair proof when no coefficient artifact exists. *)
   componentWeight=assemblyWeight[setup] Lookup[subcard,"FlavorMultiplicity",1];
   table=$Failed;componentResult=$Failed;
   If[mode==="assemble",
    reductionData=projectReductionInput[FileNameJoin[{channelDir,"Results",reduced}],setup,selectedName];
    If[AssociationQ[reductionData],
     table=projectCoefficientInput[FileNameJoin[{channelDir,"Results",reduced}],setup,reductionData]]];
   If[!AssociationQ[table],
    pairs=If[mode==="all",$Failed,projectAmplitudeInputs[FileNameJoin[{channelDir,"Results",source}],setup,selectedName]];
    amplitudesChanged=mode==="all"||(mode==="resume"&&pairs===$Failed);
    If[amplitudesChanged,
     run["regenerate_pairs.wls",{relative,selectedName,source,ToString[execution["Kernels"]]},StringReplace[selectedName,"."->""]<>"Amplitudes","FAILURES: 0"];
     pairs=projectAmplitudeInputs[FileNameJoin[{channelDir,"Results",source}],setup,selectedName]];
    If[pairs===$Failed,projectFail["CompleteMatchingAmplitudePairsRequired",<|"Contribution"->selectedName|>]];
    componentResult=ConstructZeroAmplitudeContribution[pairs,Join[req,<|"Contribution"->kind|>]];
    If[!AssociationQ[componentResult],
     reductionData=If[amplitudesChanged,$Failed,projectReductionInput[FileNameJoin[{channelDir,"Results",reduced}],setup,selectedName]];
     reductionChanged=amplitudesChanged||(mode==="resume"&&reductionData===$Failed);
     If[reductionChanged,
      run["canonicalize_and_stream.wls",{relative,source,reduced,"solve",ToString[execution["KiraThreads"]]},StringReplace[selectedName,"."->""]<>"Reduction","STREAMDIRECTORY:"];
      reductionData=projectReductionInput[FileNameJoin[{channelDir,"Results",reduced}],setup,selectedName]];
     If[reductionData===$Failed,projectFail["MatchingReductionRequired",<|"Contribution"->selectedName|>]];
     table=If[reductionChanged,$Failed,projectCoefficientInput[FileNameJoin[{channelDir,"Results",reduced}],setup,reductionData]];
     If[reductionChanged||(mode==="resume"&&table===$Failed),
      run["stream_to_coefficients.wls",{relative,reduced,ToString[execution["ReconstructionThreads"]],ToString[execution["NormalizationKernels"]]},StringReplace[selectedName,"."->""]<>"Coefficients","COEFFICIENTFILE:"];
      table=projectCoefficientInput[FileNameJoin[{channelDir,"Results",reduced}],setup,reductionData]];
     If[table===$Failed,projectFail["MatchingReducedCoefficientResultRequired",<|"Contribution"->selectedName|>]]]];
   If[!AssociationQ[componentResult],
    {elapsed,componentResult}=AbsoluteTiming[If[kind==="Real",ConstructNLORealContribution[table,req],
     ConstructNLOVirtualContribution[table,req]]];
    check[componentResult,"AnalyticContributionFailed"];AssociateTo[timings,selectedName<>"Analytic"->elapsed];Print[selectedName,"Analytic ",Round[elapsed,0.01]," seconds"]];
   componentResult=projectWeightedPartonicResult[componentResult,componentWeight];
   check[RequirePartonicEpsilonRange[componentResult,amplitudeCard["EpsilonRange"]],"ContributionEpsilonOrdersInsufficient"];
   write[componentResult,componentPath<>"/Result.wl"];
   AssociateTo[componentResults,selectedName->componentResult],
  {componentName,componentNames}];
  result=If[componentNames==={None},First[Values[componentResults]],
   check[CombinePartonicResults[componentResults,Join[KeyTake[req,{"Project","Channel","PhysicalChannel","Polarization","Coupling","CouplingPower","DimensionalPrefactor"}],
    <|"Contribution"->kind,"Components"->Keys[componentResults]|>]],"AmplitudeComponentCombinationFailed"]];
  write[result,kind<>"/Result.wl"];AssociateTo[contributions,kind->result],
 {kind,{"Real","Virtual"}}];
 ct=Join[ct,<|"ThroughOrder"->Last[card["EpsilonRange"]]|>];
 Do[row=plan["CollinearChannels"][[i]];id="Collinear"<>IntegerString[i,10,2];
  subcard=Join[ct,KeyTake[row,{"Leg","Daughter","Parent","Spin","Scheme","SplittingKernel","FiniteKernel"}],
   <|"FactorizationScaleSquared"->ct["FactorizationScalesSquared"][row["Leg"]]|>];
  value=check[ConstructNLOCollinearCounterterm[bornValues[row["BornChannelName"]],subcard],"CollinearCountertermFailed"];
  value=projectWeightedPartonicResult[value,Lookup[row,"FlavorMultiplicity",1]];
  AssociateTo[parts,id->value],{i,Length[plan["CollinearChannels"]]}];
 If[MemberQ[card["Include"],"UV"],AssociateTo[parts,"UV"->check[ConstructNLOUVCounterterm[primary,ct],"UVCountertermFailed"]]];
 value=check[CombinePartonicResults[parts,Join[KeyTake[req,{"Project","Channel","PhysicalChannel","Polarization","Coupling","CouplingPower","DimensionalPrefactor"}],
  <|"Contribution"->"Counterterm","Subtractions"->(KeyTake[#,{"Leg","Daughter","Parent","Spin","Scheme","BornChannelName"}]& /@ plan["CollinearChannels"]),
   "LowerOrderResults"->plan["LowerOrderResults"],"Schemes"->ct["Schemes"]|>]],"CountertermCombinationFailed"];
 write[value,"Counterterm/Result.wl"];AssociateTo[contributions,"Counterterm"->value];
 {elapsed,hard}=AbsoluteTiming[AssembleNLOHardFunction[contributions,Join[req,<|
  "RequiredContributions"->{"Real","Virtual","Counterterm"},
  "Assumptions"->project["FinalAssumptions"],"ColorRules"->project["ColorRules"],"Description"->project["Description"]|>]]];
 check[hard,"NLOAssemblyFailed"];AssociateTo[timings,"Assembly"->elapsed];file=write[hard,"Result.wl"];
 report=<|"Status"->"Completed","Project"->project["Project"],"Order"->"NLO","Channel"->channel,
  "Seconds"->AbsoluteTime[]-started,"StageSeconds"->timings,"ResultFile"->file,
  "BornChannels"->Keys[bornValues],"ResultFormat"->hard["Format"],"EpsilonRange"->hard["EpsilonRange"]|>;
 write[report,"Validation/RunReport.wl"];If[mode==="all",write[report,"Validation/FullRunReport.wl"]];report],"ProjectCards"];
End[];EndPackage[];
