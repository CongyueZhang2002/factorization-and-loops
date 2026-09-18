(* Raw contribution evaluation and explicit result selection are separate stages. *)
BeginPackage["FeynFacet`"];
ReadResultCard::usage="ReadResultCard[file] resolves an explicit result selection against Common-Card.wl.";
PlanProjectResult::usage="PlanProjectResult[file] validates the selected contributions and propagates epsilon requirements before any calculation.";
RunRawContribution::usage="RunRawContribution[card,mode] evaluates one contribution, retaining its Laurent poles, with no cross-contribution cancellation requirement.";
AssembleProjectResult::usage="AssembleProjectResult[plan] reads only the selected raw results, checks conventions and required cancellations, and writes Results.wl.";
RunProjectOrder::usage="RunProjectOrder[projectDirectory,order,mode,runtime] plans every result card in one order, computes each selected raw contribution once at the union of required epsilon orders, and assembles all channels. Raw timings are charged to their owning channel. Modes all, resume and assemble.";
RunProjectResult::usage="RunProjectResult[file,mode] plans, generates selected raw contributions, then assembles. Modes all, resume and assemble.";
PrepareProjectChannel::usage="PrepareProjectChannel[projectDirectory,order,channel,lowerBounds] writes initial cards and a complete result selection. lowerBounds maps each ordinary contribution to its established Laurent lower bound, including all prefactors; non-LO bounds must be supplied. Existing cards are not overwritten.";
ReadRawContributionResult::usage="ReadRawContributionResult[compiledCard] reads the selected explicit channel component and validates its common partonic-result definition, conventions and epsilon coverage.";
PrepareProjectResult::usage="PrepareProjectResult[projectDirectory,order,channel] writes an explicit complete result card from existing raw cards, selecting each required source-owned counterterm component. It validates coverage before retaining the card.";
Begin["`Private`"];



PrepareProjectChannel[directory_String,order_String,channel_String,lowerBounds_Association:<||>]:=Catch[Module[
 {project,raw,resultFile,types,names,range,bounds,definitions,cards,definition,path,inputs},
 project=projectCheck[FeynFacet`ReadProjectCard[directory],"ProjectCardRequired"];
 raw=FileNameJoin[{project["Directory"],"Raw",order,channel}];
 projectChannelLocation[raw];
 resultFile=FileNameJoin[{project["Directory"],"Results",order,channel,"Result_Card.wl"}];
 If[FileExistsQ[resultFile]||AnyTrue[FileNames["*/Card.wl",raw],
   Lookup[Get[#],"Contribution",None]=!="Counterterm"&],projectFail["InitialChannelCardsAlreadyExist"]];
 types=projectRequiredBareContributionTypes[project,order,channel];
 range=Lookup[Lookup[project,"ResultEpsilonRanges",<||>],order,{0,0}];
 bounds=If[order==="LO",Join[AssociationThread[types,ConstantArray[0,Length[types]]],lowerBounds],lowerBounds];
 If[!ContainsAll[Keys[bounds],types]||!AllTrue[Lookup[bounds,types],IntegerQ[#]&&#<=Last[range]&],
  projectFail["EstablishedContributionLaurentBoundsRequired",<|"ContributionTypes"->types,
   "Includes"->"Integrated amplitude, measure and all prefactors"|>]];
 names=types;cards=<||>;
 Do[FeynFacet`WriteProjectCard[<|"Contribution"->type,
   "EpsilonRange"->{bounds[type],Last[range]}|>,FileNameJoin[{raw,type,"Card.wl"}]],{type,types}];
 If[order=!="LO",
  definitions=FeynFacet`PlanCountertermContributionCards[raw];
  If[!MatchQ[definitions,{___Association}],projectFail["CountertermDefinitionsRequired"]];
  cards=projectCheck[FeynFacet`WriteCountertermCards[raw,definitions],"CountertermCardsRequired"];
  ];
 inputs=Join[
  (<|"Path"->StringRiffle[{"..","..","..","Raw",order,channel,#},"/"],"Weight"->1|>&/@names),
  (<|"Path"->"../../../Raw/"<>order<>"/"<>#,"OutputChannel"->channel,"Weight"->1|>&/@Keys[cards])];
 names=Join[names,Keys[cards]];
 FeynFacet`WriteProjectCard[<|"ResultType"->"CompleteCoefficient","EpsilonRange"->range,
  "RequireFinite"->True,"Inputs"->inputs|>,resultFile];
 <|"RawDirectory"->raw,"ResultCard"->resultFile,"Contributions"->names|>
],"ProjectCards"];

PrepareProjectResult[directory_String,order_String,channel_String]:=Catch[Module[
 {project,raw,file,types,ordinary,counterterms,inputs,range,card,plan},
 project=projectCheck[FeynFacet`ReadProjectCard[directory],"ProjectCardRequired"];
 raw=FileNameJoin[{project["Directory"],"Raw",order,channel}];
 projectChannelLocation[raw];
 file=FileNameJoin[{project["Directory"],"Results",order,channel,"Result_Card.wl"}];
 If[FileExistsQ[file],projectFail["ResultCardAlreadyExists"]];
 types=projectRequiredBareContributionTypes[project,order,channel];
 ordinary=Select[FileNames["*/Card.wl",raw],MemberQ[types,Lookup[Get[#],"Contribution",None]]&];
 If[Sort[Lookup[Get/@ordinary,"Contribution"]]=!=Sort[types],projectFail["RequiredOrdinaryRawCardsMissing"]];
 inputs=(<|"Path"->"../../../Raw/"<>order<>"/"<>channel<>"/"<>FileNameTake[DirectoryName[#]],"Weight"->1|>&/@ordinary);
 If[order=!="LO",
  counterterms=projectCheck[FeynFacet`ReadCountertermCards[raw],"DeclaredCountertermCardsRequired"];
  inputs=Join[inputs,(<|"Path"->"../../../Raw/"<>order<>"/"<>#,"OutputChannel"->channel,"Weight"->1|>&/@Keys[counterterms])]];
 range=project["ResultEpsilonRanges"][order];
 card=<|"ResultType"->"CompleteCoefficient","EpsilonRange"->range,"RequireFinite"->True,"Inputs"->inputs|>;
 FeynFacet`WriteProjectCard[card,file];
 plan=FeynFacet`PlanProjectResult[file];
 If[!AssociationQ[plan],DeleteFile[file];projectFail["CompleteResultCardPlanFailed",<|"Cause"->plan|>]];
 <|"ResultCard"->file,"Contributions"->Length[inputs],"Coverage"->plan["Coverage"]|>
],"ProjectCards"];


projectRawDefinition[card_Association]:=projectIdentityValue[
 coefficientRegulatorNormalize[KeyDrop[card,{"Directory","ProjectDirectory","CardFile","CardName",
  "ContributionPath","ContributionDirectory","WorkDirectory","ResultFile","Execution",
  "EpsilonRange","Orders","ResultEpsilonRanges","Description","SourceGeneration","RawCollectionFile","RawOutputChannel"}],$feynFacetEpsilon]];

ReadResultCard[file_String]:=Catch[Module[{path,location,card,range,inputs,paths,project},
 path=projectAbsolutePath[file];
 If[FileNameTake[path]=!="Result_Card.wl"||!FileExistsQ[path],projectFail["ResultCardFileRequired"]];
 location=projectChannelLocation[DirectoryName[path]];project=location["ProjectCard"];
 If[projectAbsolutePath[DirectoryName[path]]=!=FileNameJoin[{project["Directory"],"Results",location["Order"],location["Channel"]}],
  projectFail["ResultCardMustBelongToResultsOrderChannel"]];
 card=projectCheck[Get[path],"ResultCardAssociationRequired"];
 range=Lookup[card,"EpsilonRange",None];inputs=Lookup[card,"Inputs",None];
 If[!MatchQ[range,{_Integer,_Integer}]||First[range]>Last[range]||
   !MatchQ[inputs,{_Association..}]||
   !MemberQ[{"CompleteCoefficient","SelectedSum"},Lookup[card,"ResultType",None]]||
   !MemberQ[{True,False},Lookup[card,"RequireFinite",None]],
  projectFail["ExplicitResultSelectionAndEpsilonRangeRequired"]];
 If[card["ResultType"]==="CompleteCoefficient"&&!TrueQ[card["RequireFinite"]],projectFail["CompleteCoefficientRequiresFiniteness"]];
 If[TrueQ[card["RequireFinite"]]&&First[range]<0,projectFail["NonnegativeFiniteResultRangeRequired"]];
 paths=Map[Function[input,
  If[!StringQ[Lookup[input,"Path",None]]||!KeyExistsQ[input,"Weight"],projectFail["InputPathAndWeightRequired"]];
  projectAbsolutePath[FileNameJoin[{DirectoryName[path],input["Path"]}]]],inputs];
 If[!DuplicateFreeQ[paths]||!AllTrue[paths,Function[input,
   With[{relative=Drop[FileNameSplit[input],Length[FileNameSplit[project["Directory"]]]]},
    Length[relative]===4&&Take[relative,2]==={"Raw",location["Order"]}&&
    KeyExistsQ[project["Channels"],relative[[3]]]&&
    projectAbsolutePath[projectRootDirectory[input]]===project["Directory"]]]],
  projectFail["DistinctRawContributionsOfProjectAndOrderRequired"]];
 Join[card,<|"ProjectCard"->project,"Directory"->DirectoryName[path],"RawDirectory"->location["Directory"],
  "Order"->location["Order"],"Channel"->location["Channel"],"CardFile"->path,
  "ResolvedInputs"->MapThread[Join[#1,<|"Directory"->#2|>] &,{inputs,paths}]|>]
],"ProjectCards"];

PlanProjectResult[file_String]:=projectWithCountertermPlanning[Catch[Module[
 {result,project,cards=<||>,weights=<||>,card,name,range,input,required,ordinary,ct,coverage,plan,
  sourceOrders=<||>,weight,definition,identities,expected,owner,outputChannel},
 result=projectCheck[FeynFacet`ReadResultCard[file],"ResultCardRequired"];
 project=result["ProjectCard"];range=result["EpsilonRange"];
 Do[
  name=FileNameTake[input["Directory"]];
  If[KeyExistsQ[input,"OutputChannel"],
   outputChannel=input["OutputChannel"];
   If[outputChannel=!=result["Channel"],projectFail["ExplicitMatchingCountertermOutputChannelRequired"]];
   card=projectCheck[FeynFacet`ReadContributionCard[DirectoryName[input["Directory"]],name,outputChannel],"SelectedRawCardRequired"];
   name=card["SourceChannel"]<>"/"<>name,
   card=projectCheck[FeynFacet`ReadContributionCard[DirectoryName[input["Directory"]],name],"SelectedRawCardRequired"];
   If[KeyExistsQ[card,"TargetCards"],projectFail["ExplicitMatchingCountertermOutputChannelRequired"]];
   If[card["Channel"]=!=result["Channel"],projectFail["OrdinaryContributionMustMatchResultChannel"]]];
  weight=input["Weight"];
  If[!FreeQ[coefficientRegulatorNormalize[weight,$feynFacetEpsilon],
     Alternatives@@Join[{$feynFacetEpsilon,_Real,_Missing,_Failure,Indeterminate,_DirectedInfinity},
       card["Assembly"]["Variables"],{card["Counterterms"]["Coupling"],card["Counterterms"]["SplittingVariable"]}]]||TrueQ[weight===0],
   projectFail["ConstantExactResultWeightRequired"]];
  If[!MatchQ[Lookup[card,"EpsilonRange",None],{_Integer,_Integer}],projectFail["RawLaurentRangeRequired"]];
  card=Join[card,<|"EpsilonRange"->{Min[First[card["EpsilonRange"]],First[range]],
      Max[Last[card["EpsilonRange"]],Last[range]]}|>];
  If[card["Contribution"]==="Counterterm",
   plan=projectCheck[FeynFacet`PlanCountertermContribution[card],"CountertermOrderPlanningFailed"];
   AssociateTo[sourceOrders,name->If[KeyExistsQ[plan,"Terms"],
    <|"SourceRenormalizationStage"->card["SourceRenormalizationStage"],
      "SourceRequirements"->DeleteDuplicates[KeyTake[#,
        {"SourceOrder","SourceChannel","SourceSpecies","RequiredSourceThroughOrder"}]&/@plan["Terms"]]|>,
    KeyTake[plan,{"BornSourceOrders","SourceRequirements","RequiredSourceOrders"}]]]];
  AssociateTo[cards,name->card];AssociateTo[weights,name->weight],
 {input,result["ResolvedInputs"]}];
 identities=projectRawDefinition/@Values[cards];
 If[!DuplicateFreeQ[identities],projectFail["DuplicateMathematicalRawContribution"]];
 coverage=<|"Status"->"SelectedSum"|>;
 If[result["ResultType"]==="CompleteCoefficient",
  required=projectRequiredBareContributionTypes[project,result["Order"],result["Channel"]];
  ordinary=Select[cards,#["Contribution"]=!="Counterterm"&];
  If[Sort[Lookup[Values[ordinary],"Contribution"]]=!=Sort[required]||
    !AllTrue[KeyTake[weights,Keys[ordinary]],#===1&],
   projectFail["CompleteAmplitudeContributionCoverageRequired",<|"Required"->required,
    "Selected"->Lookup[Values[ordinary],"Contribution"]|>]];
  KeyValueMap[Function[{name,entry},
   expected=Lookup[Lookup[Lookup[Lookup[project,"BareSourceContributions",<||>],
     result["Order"],<||>],result["Channel"],<||>],entry["Contribution"],None];
   If[AssociationQ[expected],
    expected=projectMerge[project,expected];
    expected=Join[expected,KeyTake[entry,{"Order","Channel","Contribution"}]];
    If[projectRawDefinition[entry]=!=projectRawDefinition[expected],
     projectFail["CompleteDensityDefinitionRequired",<|"Card"->name,
      "Reason"->"The selected density differs from the declared amplitude template."|>]],
    (* For stages prepared through explicit integral plans, the checked source
       amplitude definitions supply the same density contract. They need not
       also be copied into the lower-order counterterm-source catalog. *)
    If[Lookup[entry["Assembly"],"IntegrationMethod",None]==="FixedObservedCurrent",
     (* Generated current amplitudes are defined directly by their raw cards.
        They do not require a precomputed integral plan or a duplicate entry
        in the lower-order counterterm source catalog. Compile every declared
        component here; the producer still binds and verifies its artifacts. *)
     expected=projectCheck[FeynFacet`ContributionIntegrationDefinition[entry],
       "GeneratedCurrentDensityDefinitionRequired"],
    expected=FeynFacet`FamilyArtifactRead[FileNameJoin[{entry["WorkDirectory"],"IntegrationPlan.wl"}]];
    If[!AssociationQ[expected]||
      projectIdentityValue[Lookup[expected,"IntegrationDefinition",None]]=!=
       projectIdentityValue[FeynFacet`ContributionIntegrationDefinition[entry]],
     projectFail["MatchingPreparedDensityDefinitionRequired",<|"Card"->name|>]];
    If[expected["Method"]==="EndpointProfiles",
     projectCheckEndpointIntegrationInput[FeynFacet`FamilyArtifactRead[
      expected["IntegrationInputFile"]],entry]]]]],ordinary];
  ct=Select[cards,#["Contribution"]==="Counterterm"&];
  If[result["Order"]==="LO",
   If[ct=!=<||>,projectFail["NoCountertermAtRelativeOrderZero"]];coverage=<|"Status"->"Passed"|>,
   ct=Association@KeyValueMap[#1->Join[#2,<|"FlavorMultiplicity"->Lookup[#2,"FlavorMultiplicity",1]weights[#1]|>]&,ct];
   coverage=projectCheck[FeynFacet`VerifyCountertermCardCoverage[result["RawDirectory"],ct],"CountertermCoverageFailed"];
   If[coverage["Status"]=!="Passed",projectFail["CompleteCountertermCoverageRequired",<|"Check"->coverage|>]]]];
 <|"ResultCard"->result,"RawCards"->cards,"Weights"->weights,"Coverage"->coverage,
   "SourceOrders"->sourceOrders,"RawEpsilonRanges"->Map[#["EpsilonRange"]&,cards]|>
],"ProjectCards"]];

ReadRawContributionResult[card_Association]:=Catch[Module[{record,collection,requirements},
 requirements=<|"RawDefinition"->projectRawDefinition[card],"EpsilonRange"->card["EpsilonRange"],
   "Channel"->card["Channel"],"PhysicalChannel"->card["Channels"][card["Channel"]],
   "CouplingNormalization"->card["Counterterms"]["CouplingNormalization"]|>;
 If[KeyExistsQ[card,"RawOutputChannel"],
  If[!FileExistsQ[card["RawCollectionFile"]],projectFail["RawCountertermResultsMissing"]];
  collection=FeynFacet`FamilyArtifactRead[card["RawCollectionFile"]];
  If[!AssociationQ[collection]||Lookup[collection,"Format",None]=!="FeynFacet-PartonicChannelResults"||
    Lookup[collection,"Project",None]=!=card["Project"]||Lookup[collection,"Order",None]=!=card["Order"]||
    Lookup[collection,"SourceChannel",None]=!=card["SourceChannel"]||
    !AssociationQ[Lookup[collection,"Results",None]]||!KeyExistsQ[collection["Results"],card["RawOutputChannel"]],
   projectFail["SelectedCountertermChannelResultRequired"]];
  record=collection["Results"][card["RawOutputChannel"]];
  FeynFacet`ReadPartonicResult[record,requirements],
  FeynFacet`ReadPartonicResult[card["ResultFile"],requirements]]
],"ProjectCards"];

(* Compare the common mathematical record, including every scalar and
   convention. Nested association storage order and scalar zero versus a zero
   structure-function vector are equivalent representations in this format. *)
projectPartonicRecordSameQ[a_,b_]:=partonicResultValidQ[a]&&partonicResultValidQ[b]&&
 partonicConventionValue[KeyDrop[a,"Coefficients"]]===partonicConventionValue[KeyDrop[b,"Coefficients"]]&&
 KeySort[FeynFacet`PartonicScalarCoefficientRules[a]]===KeySort[FeynFacet`PartonicScalarCoefficientRules[b]];

SetAttributes[projectWithRawResultLock,HoldRest];
projectWithRawResultLock[file_String,body_]:=Module[{process,lock=file<>".lock"},
 If[!DirectoryQ[DirectoryName[lock]],CreateDirectory[DirectoryName[lock],CreateIntermediateDirectories->True]];
 process=StartProcess[{"python3",FileNameJoin[{$feynFacetWorkspaceRoot,"Scripts","raw_result_lock.py"}],lock}];
 If[!MatchQ[process,_ProcessObject],projectFail["RawResultLockProcessRequired"]];
 Internal`WithLocalSettings[Null,
  If[TimeConstrained[ReadLine[process],600,$Failed]=!="LOCKED",projectFail["RawResultLockUnavailable"]];
  body,
  Quiet[KillProcess[process]]]
];

projectRunCountertermChannel[card_Association,mode_String]:=Catch[
 projectWithRawResultLock[FileNameJoin[{DirectoryName[card["RawCollectionFile"]],"Work","Results"}],
  Module[{existing,record,scalar,report,value,collection,file=card["RawCollectionFile"],key=card["RawOutputChannel"]},
   If[mode==="resume",
    value=ReadRawContributionResult[card];
    If[AssociationQ[value],Return[<|"Status"->"Completed","Seconds"->0,"Reused"->True,"File"->file,"OutputChannel"->key|>]]];
   scalar=Join[KeyDrop[card,{"RawCollectionFile","RawOutputChannel"}],
    <|"ResultFile"->FileNameJoin[{card["WorkDirectory"],"Results.wl"}]|>];
   report=projectCheck[projectRunSingleRawContribution[scalar,mode],"CountertermChannelEvaluationFailed"];
   value=projectCheck[FeynFacet`ReadPartonicResult[scalar["ResultFile"]],"CountertermChannelResultRequired"];
   existing=If[FileExistsQ[file],FeynFacet`FamilyArtifactRead[file],<||>];
   record=If[AssociationQ[existing]&&Lookup[existing,"Format",None]==="FeynFacet-PartonicChannelResults"&&
     Lookup[existing,"Project",None]===card["Project"]&&Lookup[existing,"Order",None]===card["Order"]&&
     Lookup[existing,"SourceChannel",None]===card["SourceChannel"],
     Lookup[existing,"Results",<||>],<||>];
   collection=<|"Format"->"FeynFacet-PartonicChannelResults","FormatVersion"->1,
    "Project"->card["Project"],"Order"->card["Order"],"SourceChannel"->card["SourceChannel"],
    "SourceOrder"->card["SourceOrder"],"Contribution"->"Counterterm","Results"->Join[record,<|key->value|>]|>;
   projectWrite[collection,file];
   If[!projectPartonicRecordSameQ[ReadRawContributionResult[card],value],projectFail["CountertermChannelReadbackFailed"]];
   Join[report,<|"File"->file,"OutputChannel"->key|>]
  ]],"ProjectCards"];

RunRawContribution[card_Association,mode_String:"all"]:=Catch[Module[{reports},
 If[!MemberQ[{"all","resume"},mode],projectFail["RawRunModeRequired"]];
 If[Lookup[card["Assembly"],"IntegrationMethod",None]==="PolynomialMeasurement"&&card["Contribution"]=!="Counterterm",
  With[{started=facetElapsedClock[]},reports=projectCheck[FeynFacet`RunMeasuredRawContribution[card,mode],"MeasuredRawExecutionFailed"];
   Return[<|"Status"->"Completed","Seconds"->facetElapsedClock[]-started,"File"->card["ResultFile"]|>,Module]]];
 If[KeyExistsQ[card,"TargetCards"],
  reports=Map[projectCheck[RunRawContribution[#,mode],"CountertermChannelFailed"]&,card["TargetCards"]];
  Return[<|"Status"->"Completed","Seconds"->Total[Lookup[Values[reports],"Seconds",0]],
   "File"->card["ResultFile"],"ChannelResults"->reports|>]];
 If[KeyExistsQ[card,"RawOutputChannel"],projectRunCountertermChannel[card,mode],
  projectRunSingleRawContribution[card,mode]]
],"ProjectCards"];

projectRunSingleRawContribution[card_Association,mode_String:"all"]:=Catch[Module[
 {audit,value,output,started=facetElapsedClock[],seconds,report,file=card["ResultFile"],definition},
 If[!MemberQ[{"all","resume"},mode],projectFail["RawRunModeRequired"]];
 If[!MemberQ[{"LO","NLO","NNLO"},card["Order"]],projectFail["SupportedPerturbativeOrderRequired"]];
 definition=projectRawDefinition[card];
 If[mode==="resume"&&FileExistsQ[file],
  value=FeynFacet`ReadPartonicResult[file,<|"RawDefinition"->definition,"EpsilonRange"->card["EpsilonRange"]|>];
  If[AssociationQ[value],Return[<|"Status"->"Completed","Seconds"->0,"Reused"->True,"File"->file|>]]];
 Print["RAW_STARTED ",card["Project"]," ",card["Channel"]," ",card["CardName"]];
 audit=FeynFacet`WithEpsilonRemainderChecks[
  If[card["Contribution"]==="Counterterm",
   FeynFacet`ConstructCountertermContribution[card],
   output=If[card["Order"]==="NNLO",
    FeynFacet`EvaluatePreparedContribution[card],FeynFacet`EvaluateBareContribution[card,mode]];
   If[AssociationQ[output],output["Result"],output]]];
 If[!AssociationQ[audit]||!AssociationQ[audit["Result"]]||
   !MemberQ[{"Passed","NoChecksExecuted"},audit["EpsilonRemainderAudit"]["Status"]],
  projectFail["RawContributionFailed",<|"Card"->card["CardName"],"Cause"->audit|>]];
 value=audit["Result"];
 If[FeynFacet`RequirePartonicEpsilonRange[value,card["EpsilonRange"]]=!=True||
   First[value["EpsilonRange"]]=!=value["LaurentLowerBound"],projectFail["CompleteRawLaurentCoverageRequired"]];
 value=Join[value,<|"RawDefinition"->definition,"RawCard"->card["CardFile"],
  "CouplingNormalization"->card["Counterterms"]["CouplingNormalization"]|>];
 projectWrite[value,file];
 If[!projectPartonicRecordSameQ[FeynFacet`ReadPartonicResult[file],value],projectFail["RawResultReadbackFailed"]];
 seconds=facetElapsedClock[]-started;
 report=<|"Status"->"Completed","Seconds"->seconds,"Clock"->facetElapsedClockType[],"Reused"->False,"File"->file,
  "EpsilonRange"->value["EpsilonRange"],"EpsilonRemainderAudit"->audit["EpsilonRemainderAudit"],
  "StageSeconds"->If[AssociationQ[output],output["StageSeconds"],Lookup[value,"SourceGenerationSeconds",<||>]]|>;
 projectWrite[report,FileNameJoin[{card["WorkDirectory"],"RunReport.wl"}]];
 Print["RAW_COMPLETED ",card["CardName"]," SECONDS ",seconds];report
],"ProjectCards"];

AssembleProjectResult[plan_Association]:=Catch[Module[
 {result=plan["ResultCard"],project,cards,parts=<||>,value,card,range,conditions,color,
  coefficients,combined,check,final,file,metadata,started=facetElapsedClock[],request,raw,poleRequest,method},
 project=result["ProjectCard"];cards=plan["RawCards"];range=result["EpsilonRange"];
 Print["ASSEMBLING_RESULT ",project["Project"]," ",result["Order"]," ",result["Channel"]];
 poleRequest=Lookup[result,"PoleCancellation",<|"Method"->"ExactSymbolic"|>];
 method=Lookup[poleRequest,"Method",None];
 If[!MemberQ[{"ExactSymbolic","Numerical"},method],projectFail["ExplicitPoleCancellationMethodRequired"]];
 If[method==="Numerical"&&DownValues[FeynFacetSolution`EvaluateGPLExpression]==={},
  Get[FileNameJoin[{$feynFacetDirectory,"Solution.m"}]]];
 KeyValueMap[Function[{name,selected},
  raw=projectCheck[ReadRawContributionResult[selected],"MatchingRawResultRequired"];
  AssociateTo[parts,name->projectWeightedPartonicResult[raw,plan["Weights"][name]]]],cards];
 combined=projectCheck[FeynFacet`CombinePartonicResults[parts,<|"Contribution"->"Total"|>],"ResultConventionMismatch"];
 If[FeynFacet`RequirePartonicEpsilonRange[combined,range]=!=True,projectFail["SelectedResultOrdersInsufficient"]];
 card=First[Values[cards]];request=projectCheck[FeynFacet`ProjectAssemblyRequest[card],"AssemblyRequestRequired"];
 conditions=Lookup[project,"FinalAssumptions",Lookup[request,"Assumptions",True]]&&
   Lookup[project["Kinematics"],"CommonAssumptions",True]&&project["Kinematics"]["RadiativeConditions"]&&
   And@@(#>0&/@Values[card["Counterterms"]["FactorizationScalesSquared"]]);
 color=Join[Lookup[result,"ColorRules",{}],Lookup[project,"ColorRules",{}]];
 If[!MatchQ[color,{___Rule}],projectFail["ExplicitResultColorRulesRequired"]];
 (* Exact-zero proof benefits from symbolic collection. A numerical pole
    check does not require expansion and factorization of the full GPL answer. *)
 coefficients=KeySelect[combined["Coefficients"],#<=Last[range]&];
 coefficients=If[method==="ExactSymbolic",
  coefficients=FeynFacet`ExpandPositiveLogarithms[partonicExplicitConstants[coefficients/.color],conditions];
  If[FailureQ[coefficients],projectFail["CoefficientLogarithmNormalizationFailed",<|"Cause"->coefficients|>]];
  Map[partonicMap[partonicCollect,#]&,coefficients],
  coefficients/.color];
 combined=projectCheck[FeynFacet`CreatePartonicResult[coefficients,combined],"SimplifiedResultRequired"];
 Print["CHECKING_RESULT_POLES ",method];
 check=If[method==="Numerical",
  FeynFacet`VerifyPartonicPoleCancellation[<|"Total"->combined|>,
   Lookup[poleRequest,"ParameterPoints",{}],Lookup[poleRequest,"NumericalOptions",<||>]],
  FeynFacet`VerifyPartonicPoleCancellation[<|"Total"->combined|>]];
 If[method==="ExactSymbolic"&&TrueQ[result["RequireFinite"]]&&(!AssociationQ[check]||check["Status"]=!="Passed"),
  (* Simplify residual identities only; ordinary rational/log collection is much cheaper. *)
  coefficients=Association@KeyValueMap[Function[{n,tree},n->If[n<0,
    partonicMap[Function[x,If[x===0,0,FullSimplify[x,Assumptions->conditions]]],tree],tree]],
    combined["Coefficients"]];
  combined=projectCheck[FeynFacet`CreatePartonicResult[coefficients,combined],"SimplifiedResultRequired"];
  check=FeynFacet`VerifyPartonicPoleCancellation[<|"Total"->combined|>]];
 metadata=<|"ResultType"->result["ResultType"],"ResultSelection"->result["Inputs"],
  "ColorRules"->color,
  "CoverageCheck"->plan["Coverage"],
  Sequence@@Normal[KeyTake[project["Assembly"],{"Domain","Assumptions"}]],
  "InputRenormalizationStages"->DeleteDuplicates[Lookup[Values[parts],"RenormalizationStage",Missing["Undeclared"]]],
  Sequence@@If[result["ResultType"]==="CompleteCoefficient",
    {"RenormalizationStage"->"Renormalized"},{}],
  "OperatorSchemes"->card["Counterterms"]["Schemes"],"CouplingNormalization"->card["Counterterms"]["CouplingNormalization"],
  Sequence@@Normal[KeyTake[Lookup[result,"Metadata",<||>],{"GPLContinuation","PhysicalTestFunctionSupport"}]]|>;
 projectWrite[combined,FileNameJoin[{result["Directory"],"CombinedLaurentResult.wl"}]];
 projectWrite[check,FileNameJoin[{result["Directory"],"Validation","PoleCancellation.wl"}]];
 If[TrueQ[result["RequireFinite"]],
  final=projectCheck[FeynFacet`FinalizePartonicResults[<|"Total"->combined|>,check,<|
   "RequireAlgebraicIdentityProof"->(method==="ExactSymbolic"),"EpsilonRanges"-><|"Total"->range|>,
   "Metadata"->metadata|>],"FiniteIntegralFreeResultRequired"];value=final["Total"],
  value=projectCheck[FeynFacet`CreatePartonicResult[
    KeySelect[combined["Coefficients"],First[range]<=#<=Last[range]&],Join[combined,metadata]],"SelectedLaurentResultRequired"]];
 If[Lookup[result,"RemovableKinematicLimits",{}]=!={},
  value=projectCheck[FeynFacet`CompleteRemovablePartonicLimits[value,result["RemovableKinematicLimits"]],
   "RemovableResultLimitsRequired"]];
 file=FileNameJoin[{result["Directory"],"Results.wl"}];projectWrite[value,file];
 If[!projectPartonicRecordSameQ[FeynFacet`ReadPartonicResult[file],value],
  projectWrite[value,FileNameJoin[{result["Directory"],"Validation","FailedResultWrite.wxf"}]];
  projectFail["FinalResultReadbackFailed"]];
 <|"Status"->"Completed","AssemblySeconds"->facetElapsedClock[]-started,
  "ResultFile"->file,"ResultBytes"->Total[FileByteCount/@Select[{file,file<>".meta.wxf"},FileExistsQ]],"EpsilonRange"->range,
  "PoleCancellation"->Lookup[check,"Status","NotChecked"]|>
],"ProjectCards"];

RunProjectResult[file_String,mode_String:"all"]:=Block[{$projectGeneratedBareSourceCache=<||>},
 Catch[Module[{started=facetElapsedClock[],plan,raw=<||>,assembled,report,card,seconds},
 If[!MemberQ[{"all","resume","assemble"},mode],projectFail["ResultRunModeRequired"]];
 card=projectCheck[FeynFacet`ReadResultCard[file],"ResultCardRequired"];
 If[Lookup[card["ProjectCard"]["Assembly"],"IntegrationMethod",None]==="PolynomialMeasurement",
  assembled=projectCheck[FeynFacet`RunMeasuredProjectResult[file,mode],"MeasuredResultExecutionFailed"];
  Return[<|"Status"->"Completed","Project"->card["ProjectCard"]["Project"],"Order"->card["Order"],
   "Channel"->card["Channel"],"Mode"->mode,"Seconds"->facetElapsedClock[]-started,
   "AssemblySeconds"->assembled["StageSeconds"]["ResultAssembly"],"PoleCancellation"->"Exact",
   "ResultFile"->card["Directory"]<>"/Results.wl",
   "ResultBytes"->Total[FileByteCount/@{card["Directory"]<>"/Results.wl",card["Directory"]<>"/Results.wl.meta.wxf"}]|>,Module]];
 {seconds,plan}=facetElapsedTiming[FeynFacet`PlanProjectResult[file]];
 plan=projectCheck[plan,"ResultPlanRequired"];
 If[mode=!="assemble",KeyValueMap[Function[{name,compiled},
  AssociateTo[raw,name->projectCheck[FeynFacet`RunRawContribution[compiled,mode],"RawExecutionFailed"]]],plan["RawCards"]]];
 assembled=projectCheck[FeynFacet`AssembleProjectResult[plan],"ResultAssemblyFailed"];
 card=plan["ResultCard"];
 report=Join[assembled,<|"Project"->card["ProjectCard"]["Project"],"Order"->card["Order"],"Channel"->card["Channel"],
   "Mode"->mode,"Seconds"->facetElapsedClock[]-started,"PlanningSeconds"->seconds,
   "RawContributions"->raw,"RawEpsilonRanges"->plan["RawEpsilonRanges"],"SourceOrders"->plan["SourceOrders"]|>];
 projectWrite[report,FileNameJoin[{card["Directory"],"RunReport.wl"}]];report
 ],"ProjectCards"]];
(* A project/order is the sharing boundary for a fresh campaign. Result
   selection remains explicit; matching file names never identify physics. *)
RunProjectOrder[directory_String,order_String,mode_String:"all",runtime_Association:<||>] :=
 Block[{$projectGeneratedBareSourceCache=<||>},Catch[Module[
 {started=facetElapsedClock[],project,files,plans,cards=<||>,owners=<||>,raw=<||>,
  timings=<||>,assembled,reports=<||>,key,previous,range,compiled,planningSeconds,
  rawSeconds,channel,report,output,upstream,upstreamPlanning,localSeconds},
 If[!MemberQ[{"all","resume","assemble"},mode],projectFail["ResultRunModeRequired"]];
 upstream=Lookup[runtime,"UpstreamSecondsByOwnerChannel",<||>];
 upstreamPlanning=Lookup[runtime,"UpstreamPlanningSeconds",0];
 If[!AssociationQ[upstream]||!AllTrue[Keys[upstream],StringQ]||
  !AllTrue[Append[Values[upstream],upstreamPlanning],NumberQ[#]&&TrueQ[#>=0]&],
  projectFail["MeasuredNonnegativeUpstreamTimingsRequired"]];
 timings=upstream;
 project=projectCheck[FeynFacet`ReadProjectCard[directory],"ProjectCardRequired"];
 If[!MemberQ[Keys[project["Orders"]],order],projectFail["DeclaredProjectOrderRequired"]];
 output=FileNameJoin[{project["Directory"],"Results",order}];
 files=FileNameJoin[{output,#,"Result_Card.wl"}]&/@project["Orders"][order];
 If[!AllTrue[files,FileExistsQ],projectFail["EveryDeclaredResultCardRequired"]];
 {planningSeconds,plans}=facetElapsedTiming[projectWithCountertermPlanning[
   projectCheck[FeynFacet`PlanProjectResult[#],"ResultPlanRequired"]&/@files]];
 Do[KeyValueMap[Function[{name,card},
   key={card["CardFile"],Lookup[card,"RawOutputChannel",None]};
   If[KeyExistsQ[cards,key],
    previous=cards[key];
    If[projectRawDefinition[previous]=!=projectRawDefinition[card],
     projectFail["ConflictingSharedRawContribution",<|"Card"->card["CardFile"]|>]];
    range={Min[First[previous["EpsilonRange"]],First[card["EpsilonRange"]]],
      Max[Last[previous["EpsilonRange"]],Last[card["EpsilonRange"]]]};
    AssociateTo[cards,key->Join[card,<|"EpsilonRange"->range|>]],
    AssociateTo[cards,key->card];
    AssociateTo[owners,key->Lookup[card,"SourceChannel",card["Channel"]]]]],
  plan["RawCards"]],{plan,plans}];
 Print["PROJECT_ORDER_PLANNED ",project["Project"]," ",order,
  " RESULTS ",Length[plans]," DISTINCT RAW ",Length[cards]];
 If[mode=!="assemble",KeyValueMap[Function[{identity,card},
   report=projectCheck[FeynFacet`RunRawContribution[card,mode],"RawExecutionFailed"];
   AssociateTo[raw,identity->report];
   AssociateTo[timings,owners[identity]->(Lookup[timings,owners[identity],0]+report["Seconds"])]],cards]];
 Do[
  assembled=projectCheck[FeynFacet`AssembleProjectResult[plan],"ResultAssemblyFailed"];
  channel=plan["ResultCard"]["Channel"];rawSeconds=Lookup[timings,channel,0];
  report=Join[assembled,<|"Project"->project["Project"],"Order"->order,"Channel"->channel,
   "Mode"->mode,"LocalClock"->facetElapsedClockType[],"UpstreamClock"->"PythonMonotonic",
   "ChannelTimingReliable"->True,"RawSeconds"->rawSeconds,"UpstreamSeconds"->Lookup[upstream,channel,0],
   "Seconds"->rawSeconds+assembled["AssemblySeconds"],
   "TimingScope"->"Raw computation owned by this channel plus its result assembly; project kernel startup and joint planning are reported separately.",
   "RawEpsilonRanges"->plan["RawEpsilonRanges"],"SourceOrders"->plan["SourceOrders"]|>];
  projectWrite[report,FileNameJoin[{plan["ResultCard"]["Directory"],"RunReport.wl"}]];
  Export[FileNameJoin[{plan["ResultCard"]["Directory"],"Timing.json"}],
   KeyTake[report,{"Status","Project","Order","Channel","Mode","Seconds","RawSeconds","UpstreamSeconds","AssemblySeconds","LocalClock","UpstreamClock","ChannelTimingReliable","TimingScope","ResultBytes","PoleCancellation"}],"RawJSON"];
  AssociateTo[reports,channel->report],
 {plan,plans}];
 localSeconds=facetElapsedClock[]-started;
 report=<|"Status"->"Completed","Project"->project["Project"],"Order"->order,"Mode"->mode,
  "Seconds"->localSeconds+Total[Values[upstream]]+upstreamPlanning,
  "LocalExecutionSeconds"->localSeconds,"LocalClock"->facetElapsedClockType[],"PlanningSeconds"->planningSeconds,
  "UpstreamPlanningSeconds"->upstreamPlanning,"UpstreamSecondsByOwnerChannel"->upstream,
  "RawSecondsByOwnerChannel"->timings,
  "DistinctRawContributions"->Length[cards],"RawContributions"->raw,"Channels"->reports|>;
 projectWrite[report,FileNameJoin[{output,"RunReport.wl"}]];
 report
],"ProjectCards"]];
End[];EndPackage[];
