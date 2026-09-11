(* Shared resolved-card views and lower-order result dependencies.
   Contribution algorithms belong in their own modules. *)
BeginPackage["FeynFacet`"];
ProjectAssemblyRequest::usage="ProjectAssemblyRequest[compiledCard] constructs the assembly request from one merged contribution card. ProjectAssemblyRequest[project,channel,contribution] also accepts a project card and an explicit selection.";
ProjectResultIdentity::usage="ProjectResultIdentity[compiledCard,setup] returns the physical result identity. ProjectResultIdentity[project,channel,setup] accepts an explicit channel; setup is retained without re-reading the card.";
Begin["`Private`"];
ProjectAssemblyRequest[card_Association]:=If[ContainsAll[Keys[card],{"Channel","CardName","Order"}],
  ProjectAssemblyRequest[card,card["Channel"],First[StringSplit[card["CardName"],"."]]],
  Failure["CompiledContributionCardRequired",<||>]];
ProjectResultIdentity[card_Association,setup_Association]:=
  ProjectResultIdentity[card,card["Channel"],setup];

projectWrite[value_,file_]:=FamilyArtifactWrite[value,file];
projectWeightedPartonicResult[result_Association,weight_]:=Module[{e=result["DimensionalRegulator"]},
 If[!FreeQ[weight,e|_Real|_Missing|_Failure|Indeterminate|_DirectedInfinity],
  projectFail["ExactEpsilonIndependentMultiplicityRequired"]];
 If[weight===1,Return[result]];
 projectCheck[FeynFacet`CreatePartonicResult[(partonicMap[Function[x,weight x],#]& /@ result["Coefficients"]),
  Join[result,<|"AppliedMultiplicity"->weight|>]],"WeightedPartonicResultFailed"]
];
ProjectResultIdentity[project_,channel_,setup_]:=<|
 "Project"->project["Project"],"Channel"->channel,"PhysicalChannel"->project["Channels"][channel],
 "Polarization"->project["Polarization"],"ProcessDefinition"->setup|>;
ProjectAssemblyRequest[project_Association,channel_String,type_String]:=Catch[Module[
  {request,order,increment,current,indices},
  order=Lookup[project,"Order",If[type==="Born","LO",Missing["Order"]]];
  increment=Switch[order,"LO",0,"NLO",1,"NNLO",2,_,projectFail["ExplicitPerturbativeOrderRequired"]];
  request=Join[project["Assembly"],<|
    "Project"->project["Project"],"Channel"->channel,"PhysicalChannel"->project["Channels"][channel],
    "Polarization"->project["Polarization"],"ColorRules"->Lookup[project,"ColorRules",{}],
    "Kernels"->Lookup[Lookup[project,"Execution",<||>],"Kernels",1],
    "KinematicConditions"->project["Kinematics"][
      If[MemberQ[{"Virtual","Born"},type],"BornConditions","RadiativeConditions"]],
    "Coupling"->project["Counterterms"]["Coupling"],
    "DimensionalPrefactor"->project["Counterterms"]["RenormalizationScaleSquared"]^
      (project["BornCouplingPower"] Global`Epsilon),
    "CouplingPower"->project["BornCouplingPower"]+increment,"DimensionalRegulator"->Global`Epsilon|>];
  If[KeyExistsQ[project,"Current"],
    current=project["Current"];indices=Lookup[current["Indices"],{"Conjugate","Amplitude"}];
    AssociateTo[request,"CurrentProjectors"->Switch[Lookup[current,"Projection",None],
      "DIS",KeyTake[DISCurrentProjectors[First[project["IncomingMomenta"]],current["Momentum"],indices][
        "CoefficientProjectors"],project["StructureFunctions"]],
      "DrellYan",<|"C_DY"->VectorCurrentPolarizationSum[current["Momentum"],indices]|>,
      _,projectFail["CurrentProjectionRequired"]]]];
  request
],"ProjectCards"];

(* The caller determines the required epsilon interval from its operator.
   This resolver only validates declarations and ownership. *)
projectLowerOrderDependencies[card_Association,order_String,names_List,need:{_Integer,_Integer}]:=Module[
  {declarations=Lookup[card,"LowerOrderResults",<||>],projectDirectory,dependencies=<||>,entry,range,file,owner},
  projectDirectory=card["ProjectDirectory"];
  Do[
    entry=Lookup[declarations,name,Missing[]];
    If[!AssociationQ[entry]||!ContainsAll[Keys[entry],{"File","EpsilonRange"}],
      projectFail["ExplicitLowerOrderResultRequired",<|"Channel"->name|>]];
    range=entry["EpsilonRange"];
    If[!MatchQ[range,{_Integer,_Integer}]||First[range]>First[need]||Last[range]<Last[need],
      projectFail["DeclaredLowerOrderEpsilonRangeInsufficient",
        <|"Channel"->name,"Declared"->range,"Required"->need|>]];
    If[!MemberQ[Lookup[card["Orders"],order,{}],name],
      projectFail["DeclaredLowerOrderChannelRequired",<|"Order"->order,"Channel"->name|>]];
    file=projectAbsolutePath[FileNameJoin[{DirectoryName[card["CardFile"]],entry["File"]}]];
    owner=FileNameJoin[{projectDirectory,order,name,"Results"}];
    If[!StringStartsQ[file,owner<>$PathnameSeparator],
      projectFail["LowerOrderResultMustBelongToDeclaredChannel",<|"Channel"->name,"File"->file|>]];
    AssociateTo[dependencies,name-><|"Order"->order,"Channel"->name,"File"->file,
      "EpsilonRange"->range,"RequiredEpsilonRange"->need|>],
  {name,names}];
  dependencies
];

projectBornResults[project_Association,dependencies_Association,mode_String]:=Module[
  {results=<||>,timings=<||>,directory,card,setup,range,request,required,file,value,seconds},
  If[!MemberQ[{"all","resume","assemble"},mode],projectFail["ProjectRunModeRequired"]];
  KeyValueMap[Function[{name,dependency},
    directory=FileNameJoin[{project["Directory"],"LO",name}];
    card=projectCheck[ReadContributionCard[directory,"Born"],"BornCardRequired"];
    setup=projectCheck[ReadProcessCard[card],"BornSetupRequired"];
    range={0,Max[Last[card["EpsilonRange"]],Last[dependency["EpsilonRange"]]]};
    request=Join[ProjectAssemblyRequest[card],ProjectResultIdentity[card,setup],
      <|"EpsilonRange"->range,"BornCouplingPower"->project["BornCouplingPower"]|>];
    required=Join[ProjectResultIdentity[card,setup],
      KeyTake[request,{"DimensionalPrefactor","DistributionBasis","StructureFunctions","CurrentNormalization"}],
      <|"Order"->"LO","Contribution"->"Born","EpsilonRange"->range|>];
    file=dependency["File"];
    value=If[mode==="all",$Failed,FeynFacet`ReadPartonicResult[file,required]];
    If[!AssociationQ[value],
      If[mode==="assemble",projectFail["CompleteMatchingBornResultRequired",
        <|"Channel"->name,"File"->file,"EpsilonRange"->range,"Cause"->value|>]];
      {seconds,value}=AbsoluteTiming[FeynFacet`ConstructBornResult[setup,request]];
      projectCheck[value,"BornResultFailed"];projectWrite[value,file];
      AssociateTo[timings,"LO/"<>name->seconds];
      value=FeynFacet`ReadPartonicResult[file,required]];
    AssociateTo[results,name->projectCheck[value,"BornDependencyValidationFailed"]]
  ],dependencies];
  <|"Results"->results,"StageSeconds"->timings|>
];
End[];EndPackage[];
