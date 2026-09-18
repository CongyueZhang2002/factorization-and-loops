(* Shared compiled-card views and automatic lower-order source physics.
   Amplitude execution belongs to AmplitudeContributions.wl. *)
BeginPackage["FeynFacet`"];
ProjectAssemblyRequest::usage="ProjectAssemblyRequest[compiledCard] constructs the assembly request from one merged contribution card. ProjectAssemblyRequest[project,channel,contribution] also accepts a project card and an explicit selection.";
ProjectResultIdentity::usage="ProjectResultIdentity[compiledCard,setup] returns the physical result identity. ProjectResultIdentity[project,channel,setup] accepts an explicit channel; setup is retained without re-reading the card.";
CompileBareSourceCard::usage="CompileBareSourceCard[consumer,order,channel,contribution,through] compiles shared source physics in the consumer's directory, independently of lower-order cards or results.";
GenerateBornPartonicSources::usage="GenerateBornPartonicSources[consumer,channelThroughOrders] regenerates each required Born source to its derived epsilon order under the consumer's Counterterm/Sources directory.";
GenerateBarePartonicSourceCatalog::usage="GenerateBarePartonicSourceCatalog[consumer,requirements] combines source epsilon requirements and regenerates bare lower-order contributions from the shared project physics. Requirements use SourceOrder, SourceSpecies (or SourceChannel), and RequiredSourceThroughOrder.";

CompleteBareSourcePhysics::usage="CompleteBareSourcePhysics[project] completes the declared massless-QCD lower-order source catalog by flavor conservation and builds epsilon-independent amplitude templates. Existing physical channel identities are retained.";
Begin["`Private`"];
ProjectAssemblyRequest[card_Association]:=If[ContainsAll[Keys[card],{"Channel","CardName","Order"}],
  ProjectAssemblyRequest[card,card["Channel"],card["Contribution"]],
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
  If[KeyExistsQ[project,"Current"]&&!KeyExistsQ[request,"CurrentProjectors"],
    current=project["Current"];indices=Lookup[current["Indices"],{"Conjugate","Amplitude"}];
    AssociateTo[request,"CurrentProjectors"->Switch[Lookup[current,"Projection",None],
      "DIS",KeyTake[DISCurrentProjectors[First[project["IncomingMomenta"]],current["Momentum"],indices][
        "CoefficientProjectors"],project["StructureFunctions"]],
      "DrellYan",<|"C_DY"->VectorCurrentPolarizationSum[current["Momentum"],indices]|>,
      _,projectFail["CurrentProjectionRequired"]]]];
  If[KeyExistsQ[request,"CurrentProjectors"]&&KeyExistsQ[project,"StructureFunctions"],
   If[Sort[Keys[request["CurrentProjectors"]]]=!=Sort[project["StructureFunctions"]],
    projectFail["CurrentProjectorsMustMatchDeclaredStructureFunctions"]];
   request["CurrentProjectors"]=KeyTake[request["CurrentProjectors"],project["StructureFunctions"]]];
   If[KeyExistsQ[project,"Current"]&&!KeyExistsQ[project,"Components"]&&
     Lookup[project,"Contribution",None]=!="Counterterm",
    AssociateTo[request,"SymmetryFactor"->projectCompileStateFactors[Join[project,<|"Channel"->channel|>]]["SymmetryFactor"]]];
   If[KeyExistsQ[project,"Current"]&&Lookup[request,"CollinearConvolution",None]==="Mellin",
    AssociateTo[request,"CollinearMeasurementDerivation"->projectVerifyMellinMeasurement[project,request]]];
   request
],"ProjectCards"];

projectVerifyMellinMeasurement[project_Association,request_Association]:=Module[
 {variables,coordinateRules,solutions,definitions={},rules,tagged=None,measurement=None,geometry,reference,total,
  momentumRules,observedDimension=None,check,onShell,coordinateEquations},
 rules=FeynCalc`FCI[Lookup[request,"KinematicRules",{}]];
 variables=Prepend[request["Variables"],request["Scale"]];
 coordinateRules=Select[rules,MatchQ[First[#],FeynCalc`Pair[FeynCalc`Momentum[_,D],FeynCalc`Momentum[_,D]]]&&
   !FreeQ[Last[#],Alternatives@@variables]&];
 coordinateEquations=DeleteDuplicates[(First[#]==Last[#])&/@coordinateRules];
 If[KeyExistsQ[request["PhysicalChannel"],"Observed"]&&coordinateEquations=!={},
  solutions=Solve[coordinateEquations,Select[variables,!FreeQ[coordinateEquations,#]&]];
  If[Length[solutions]=!=1,projectFail["UniqueMeasurementCoordinateDefinitionsRequired"]];definitions=First[solutions]];
 onShell=Select[rules,Last[#]===0&];
 If[KeyExistsQ[request["PhysicalChannel"],"Observed"],
  geometry=Lookup[request,"TwoParticleMeasurement",None];
  If[!AssociationQ[geometry]||Lookup[geometry,"MassesSquared",{0,0}]=!={0,0},
   projectFail["DerivedIntegratedMeasurementRequiredForMellinProjection"]];
  tagged=First[project["FinalMomenta"]];reference=geometry["ReferenceMomentum"];total=geometry["TotalMomentum"];
  momentumRules=Lookup[geometry,"MomentumRules",{}];
  solutions=Solve[(First[#]==Last[#])&/@momentumRules,{total}];
  If[Length[solutions]=!=1,projectFail["UniqueTotalMomentumDefinitionRequired"]];
  measurement=FeynCalc`ExpandScalarProduct[FeynCalc`SPD[reference,tagged]/FeynCalc`SPD[reference,total]/.First[solutions]]/.onShell;
  definitions=Append[definitions,geometry["MeasurementVariable"]->measurement];
  (* This is also the dimension selected by ReadProcessCard for the tagged
     hard insertion, including evanescent components in polarized currents. *)
  observedDimension=Switch[Lookup[project,"ObservedMomentumSpace","IntegratedD"],"IntegratedD",D,"Physical4",4,_,None]];
 check=FeynFacet`VerifyCollinearMeasurementCovariance[<|
   "Kernel"->request["CurrentNormalization"]Values[request["CurrentProjectors"]],
   "Measurement"->measurement,"IncomingMomenta"->project["IncomingMomenta"],"TaggedMomentum"->tagged,
   "Dimension"->D,"TaggedDimension"->observedDimension,"CoordinateDefinitions"->definitions,"OnShellRules"->onShell|>];
 projectCheck[check,"ReducedCollinearMeasurementDoesNotClose"]
];



CompleteBareSourcePhysics[project_Association]:=Catch[Module[
 {card=project,channels,templates,minimum,classes,legs,raw,species,flavors,charge,active,recoils,
  pattern,names,name,definition,real,lo,nlo,types,base,convention,basis,counts,members,forms,label},
 If[Lookup[project,"FlavorSummation",None]=!="MasslessQCD",Return[project]];
 channels=card["Channels"];templates=Lookup[card,"BareSourceContributions",<||>];
 minimum=Lookup[card,"MinimumChannelOrders",<||>];
 species=Select[Keys[card["SpeciesMap"]],collinearKernelSpeciesQ];flavors=qcdFlavorLabels[species];
 label[q_]:=If[q==="g","g",ToString[Last[q]]<>If[First[q]==="qb","b",""]];
 charge[q_]:=If[q==="g",ConstantArray[0,Length[flavors]],
  If[First[q]==="q",1,-1](Boole[#===Last[q]]&/@flavors)];
 (* Every allowed active species tuple is checked against one- and two-parton
    recoil charge conservation. Equivalent massless flavor labels share one
    source during symbolic flavor sums; every explicit physical flavor tuple
    remains available to concrete contribution cards. *)
 Do[
  recoils=Select[species,Total[charge/@Most[active]]===charge[Last[active]]+charge[#]&];
  real=FeynFacet`EnumerateNLORealChannels[<|"Incoming"->Most[active],"Observed"->Last[active]|>,
    <|"Species"->species,"FlavorCount"->card["Counterterms"]["KernelParameters"]["FlavorCount"]|>];
  If[!AssociationQ[real],projectFail["MasslessQCDSourceEnumerationFailed",<|"Cause"->real,"ActiveSpecies"->active|>]];
  If[recoils==={}&&real["Components"]===<||>,Continue[]];
  pattern=bareFlavorPattern[active];
  names=Select[Keys[channels],bareChannelSpecies[channels[#]]===active&];
  If[names==={},
   name=StringRiffle[label/@Most[active],"-"]<>"_"<>label[Last[active]]<>
    If[Length[recoils]===1,"-"<>label[First[recoils]],""];
   definition=<|"Incoming"->Most[active],"Observed"->Last[active]|>;
   If[Length[recoils]===1,AssociateTo[definition,"Recoil"->First[recoils]]];
   AssociateTo[channels,name->definition];names={name}];
  Do[
   definition=channels[name];base=bareChannelSpecies[definition];
   recoils=Select[species,Total[charge/@definition["Incoming"]]===charge[definition["Observed"]]+charge[#]&];
   If[KeyExistsQ[definition,"Recoil"]&&!MemberQ[recoils,definition["Recoil"]],
    projectFail["DeclaredBornRecoilViolatesFlavorConservation",<|"Channel"->name|>]];
   AssociateTo[minimum,name->If[recoils==={},1,0]];
   lo=Lookup[templates,"LO",<||>];nlo=Lookup[templates,"NLO",<||>];
   If[recoils=!={}&&!KeyExistsQ[lo,name],
    If[Length[recoils]=!=1,projectFail["ExplicitBornRecoilChannelRequired"]];
    AssociateTo[lo,name-><|"Born"-><|"Contribution"->"Born","AmplitudeLoops"->{0,0},
      "UnobservedPartons"->recoils|>|>]];
   If[!KeyExistsQ[nlo,name],
    real=projectCheck[FeynFacet`EnumerateNLORealChannels[definition,
      <|"Species"->species,"FlavorCount"->card["Counterterms"]["KernelParameters"]["FlavorCount"]|>],
      "MasslessQCDSourceEnumerationFailed"];
    types=<|"Real"-><|"Contribution"->"Real","AmplitudeLoops"->{0,0},"Components"->real["Components"]|>|>;
    If[recoils=!={},AssociateTo[types,"Virtual"-><|"Contribution"->"Virtual","AmplitudeLoops"->{1,0},
     "LoopMomenta"->{{Global`ell},{}},"UnobservedPartons"->recoils|>]];
    AssociateTo[nlo,name->types]];
   AssociateTo[templates,{"LO"->lo,"NLO"->nlo}],
  {name,names}],
 {active,Tuples[species,3]}];
 classes=Lookup[card,"FlavorClasses",None];
 If[!AssociationQ[classes],
  counts=Lookup[card["ProcessDefaults"],"MasslessQuarkFlavors",<||>];
  classes=Association@Map[Function[type,
   members=Select[flavors,With[{form=card["SpeciesMap"][{"q",#}]},
      MatchQ[form,FeynArts`F[If[type==="UpType",3,4],___]]]&];
   type-><|"Members"->members,"Multiplicity"->counts[type]|>],Keys[counts]];
  If[classes===<||>||!AllTrue[Values[classes],#["Members"]=!={}&],
   projectFail["DeclaredMasslessFlavorClassesRequired"]]];
 legs=card["Assembly"]["FactorizationLegs"];
 raw=Lookup[card,"BareOperatorSchemes",Association@KeyValueMap[Function[{name,definition},
   name->If[If[definition["Role"]==="PDF",card["Polarization"]["Incoming"][[definition["Index"]]],
    card["Polarization"]["Observed"]]==="L","Larin","MSbar"]],legs]];
 basis=Lookup[card["Assembly"],"DistributionBasis",<|
   "Variable"->Last[card["Assembly"]["Variables"]],"Endpoint"->1,"Interval"->{0,1},
   "Distance"->1-Last[card["Assembly"]["Variables"]]|>];
 Join[card,<|"Channels"->channels,"BareSourceContributions"->templates,"MinimumChannelOrders"->minimum,
  "FlavorClasses"->classes,"LowerOrderFlavorCovariance"->"MasslessQCD","BareOperatorSchemes"->raw,
  "CompleteLowerOrderSourceCatalog"->True,
  "StructureFunctions"->Lookup[card,"StructureFunctions",{"Scalar"}],
  "Assembly"->Join[card["Assembly"],<|"DistributionBasis"->basis,
   "DensityConvention"->Lookup[card["Assembly"],"DensityConvention","E_c d sigma/d^(D-1)p_c"]|>]|>]
],"ProjectCards"];

(* Lower-order amplitudes are regenerated for the consuming contribution.
   Shared physics templates have no epsilon truncation and no result paths. *)

CompileBareSourceCard[consumer_Association,order_String,channel_String,type_String,through_Integer]:=Catch[Module[
 {templates,template,compiled,low,base},
 If[!MemberQ[{"LO","NLO"},order]||!ContainsAll[Keys[consumer],
   {"Project","ProjectDirectory","Directory","Order","Channel","CardFile","Channels","BareSourceContributions"}]||
  !KeyExistsQ[consumer["Channels"],channel],
  projectFail["ConsumerAndSharedBareSourcePhysicsRequired"]];
 templates=Lookup[Lookup[consumer["BareSourceContributions"],order,<||>],channel,<||>];
 template=Lookup[templates,type,None];
 If[!AssociationQ[template]||KeyExistsQ[template,"EpsilonRange"]||KeyExistsQ[template,"LowerOrderResults"],
  projectFail["EpsilonIndependentBareSourceContributionRequired",<|"Order"->order,"Channel"->channel,"Contribution"->type|>]];
 low=If[order==="LO",0,-2];
 If[through<low,projectFail["SourceEpsilonUpperOrderBelowLowerBound"]];
 (* Read only the common project physics. Contribution-specific endpoint and
    diagram definitions come from the same templates used by direct runs. *)
 base=projectCheck[FeynFacet`ReadProjectCard[consumer["ProjectDirectory"]],"SharedSourceProjectRequired"];
 (* Preserve effective common physics overrides of the consumer, while the
    source's radiation, loops and endpoint definitions come from its template. *)
 base=projectMerge[base,KeyTake[consumer,Keys[base]]];
 compiled=projectMerge[base,template];
  projectCompileStateFactors[Join[compiled,projectContributionPaths[FileNameJoin[{consumer["WorkDirectory"],"Sources",order,channel,type}]],<|"ProjectDirectory"->consumer["ProjectDirectory"],"Directory"->consumer["Directory"],
   "Order"->order,"Channel"->channel,"CardFile"->consumer["CardFile"],"CardName"->type,
   "Contribution"->type,"ContributionPath"->StringRiffle[{"Counterterm","Sources",order,channel,type},"/"],
   "EpsilonRange"->{low,through},
   "SourceGeneration"-><|"ConsumerOrder"->consumer["Order"],"ConsumerChannel"->consumer["Channel"],
     "SourceOrder"->order,"SourceChannel"->channel,"RequiredSourceThroughOrder"->through,
      "ContributionDefinition"->template,"GeneratedFromSharedPhysics"->True|>|>]]
],"ProjectCards"];

projectRequiredBareContributionTypes[project_Association,order_String,channel_String]:=Module[{minimum},
 If[order==="LO",Return[{"Born"}]];
 If[!MemberQ[{"NLO","NNLO"},order],projectFail["SupportedBareSourceOrderRequired"]];
 minimum=Lookup[Lookup[project,"MinimumChannelOrders",<||>],channel,None];
 If[!IntegerQ[minimum]||minimum<0,projectFail["ExplicitSourceMinimumOrderRequired",<|"SourceChannel"->channel|>]];
 Switch[{order,minimum},
  {"NLO",0},{"Real","Virtual"},{"NLO",1},{"Real"},
  {"NNLO",0},{"DoubleReal","RealVirtual","DoubleVirtual"},
  {"NNLO",1},{"DoubleReal","RealVirtual"},{"NNLO",2},{"DoubleReal"},_,{}]
];

projectGenerateBareSource[consumer_Association,order_String,channel_String,through_Integer]:=Module[
 {definitions,types,requiredTypes,parts=<||>,timings=<||>,card,range,value,seconds,path,combined,metadata,
  cacheKey,cached,output},
 definitions=Lookup[Lookup[consumer["BareSourceContributions"],order,<||>],channel,None];
 If[!AssociationQ[definitions]||definitions===<||>,projectFail["RequiredBareSourcePhysicsMissing",
  <|"Order"->order,"Channel"->channel|>]];
 types=Keys[definitions];requiredTypes=projectRequiredBareContributionTypes[consumer,order,channel];
 If[requiredTypes==={}||Sort[types]=!=Sort[requiredTypes],
  projectFail["CompleteBareContributionSelectionRequired",
   <|"SourceOrder"->order,"SourceChannel"->channel,"Required"->requiredTypes,"Declared"->types|>]];
 cacheKey=KeyDrop[CompileBareSourceCard[consumer,order,channel,#,through],
   {"CardFile","CardName","Directory","ContributionPath","ContributionDirectory","WorkDirectory","ResultFile","SourceGeneration","EpsilonRange"}]&/@types;
 If[AssociationQ[$projectGeneratedBareSourceCache],
  cached=Lookup[$projectGeneratedBareSourceCache,Key[cacheKey],None];
  If[AssociationQ[cached]&&cached["ThroughOrder"]>=through,
   Return[Join[cached["Output"],<|"StageSeconds"->Map[0&,cached["Output"]["StageSeconds"]],
    "SourceReusedWithinConsumerRun"->True|>]]]];
 Do[
  card=projectCheck[CompileBareSourceCard[consumer,order,channel,type,through],"BareSourceCardCompilationFailed"];
  output=projectCheck[FeynFacet`EvaluateBareContribution[card,"resume"],"AutomaticBareSourceGenerationFailed"];
  value=output["Result"];range=card["EpsilonRange"];seconds=Total[Values[output["StageSeconds"]]];
  If[Lookup[value,"RenormalizationStage",None]=!="Bare"||
    FeynFacet`RequirePartonicEpsilonRange[value,range]=!=True,
   projectFail["GeneratedBareSourceIdentityOrOrdersMismatch"]];
  AssociateTo[parts,type->value];AssociateTo[timings,order<>"/"<>channel<>"/"<>type->seconds],
 {type,types}];
 metadata=<|"Contribution"->"Bare","RenormalizationStage"->"Bare",
  "CouplingNormalization"->consumer["Counterterms"]["CouplingNormalization"],
  "SourceGeneration"-><|"ConsumerOrder"->consumer["Order"],"ConsumerChannel"->consumer["Channel"],
    "SourceOrder"->order,"SourceChannel"->channel,"RequiredSourceThroughOrder"->through,
    "ContributionDefinitions"->definitions,"GeneratedFromSharedPhysics"->True|>|>;
 combined=If[Length[parts]===1,FeynFacet`CreatePartonicResult[First[Values[parts]]["Coefficients"],
   Join[KeyDrop[First[Values[parts]],{"Coefficients","EpsilonRange"}],metadata]],
  FeynFacet`CombinePartonicResults[parts,metadata]];
 combined=projectCheck[combined,"GeneratedBareSourceCombinationFailed"];
 path=FileNameJoin[{consumer["WorkDirectory"],"Sources",order,channel,"Results.wl"}];
 projectWrite[combined,path];
 output=<|"Result"->combined,"StageSeconds"->timings,"File"->path|>;
 If[AssociationQ[$projectGeneratedBareSourceCache],
  AssociateTo[$projectGeneratedBareSourceCache,cacheKey-><|"ThroughOrder"->through,"Output"->output|>]];
 output
];

GenerateBornPartonicSources[consumer_Association,requirements_Association]:=Catch[Module[
 {rows=<||>,timings=<||>,provenance=<||>,value},
 If[!AllTrue[Keys[requirements],StringQ]||!AllTrue[Values[requirements],IntegerQ[#]&&#>=0&],
  projectFail["BornChannelEpsilonUpperOrdersRequired"]];
 KeyValueMap[Function[{name,through},
  value=projectGenerateBareSource[consumer,"LO",name,through];
  AssociateTo[rows,name->value["Result"]];timings=Join[timings,value["StageSeconds"]];
  AssociateTo[provenance,name-><|"File"->value["File"],"RequiredSourceThroughOrder"->through|>]
 ],requirements];
 <|"Results"->rows,"StageSeconds"->timings,"GeneratedSources"->provenance|>
],"ProjectCards"];

GenerateBarePartonicSourceCatalog[consumer_Association,requirements_List]:=Catch[Module[
 {needed=<||>,channels,minimum,classes,names,name,pattern,order,through,key,value,rows=<||>,
  timings=<||>,provenance=<||>,byOrder,axes,conditions,coefficients,chargeSymbols},
 If[!ContainsAll[Keys[consumer],{"BareSourceContributions","Channels","MinimumChannelOrders","FlavorClasses",
    "LowerOrderFlavorCovariance","Assembly"}]||
  !MemberQ[{"Identity","SingleMasslessQuarkLine","MasslessQCD"},consumer["LowerOrderFlavorCovariance"]],
  projectFail["ExplicitSourceFlavorCovarianceAndChannelOrdersRequired"]];
 channels=consumer["Channels"];minimum=consumer["MinimumChannelOrders"];classes=consumer["FlavorClasses"];
 If[!AssociationQ[minimum]||!ContainsAll[Keys[minimum],Keys[channels]]||
   !AllTrue[Values[minimum],IntegerQ[#]&&#>=0&]||!AssociationQ[classes],
  projectFail["DeclaredMasslessFlavorCovarianceAndChannelOrdersRequired"]];
 chargeSymbols=If[consumer["LowerOrderFlavorCovariance"]==="SingleMasslessQuarkLine",
  DeleteDuplicates[Lookup[Values[classes],"Charge"]],{}];
 If[!VectorQ[chargeSymbols,MatchQ[#,_Symbol]&],projectFail["SymbolicFlavorChargesRequired"]];
 Do[
  If[!AssociationQ[requirement]||!ContainsAll[Keys[requirement],{"SourceOrder","RequiredSourceThroughOrder"}],
   projectFail["PlannedBareSourceRequirementRequired"]];
  order=requirement["SourceOrder"];through=requirement["RequiredSourceThroughOrder"];
  If[!MemberQ[{0,1},order]||!IntegerQ[through],projectFail["LowerOrderBareSourceRequirementRequired"]];
  If[KeyExistsQ[requirement,"SourceChannel"],name=requirement["SourceChannel"],
   If[!ListQ[Lookup[requirement,"SourceSpecies",None]],projectFail["SourceSpeciesRequired"]];
   pattern=bareFlavorPattern[requirement["SourceSpecies"]];
   names=bareSourceChannelCandidates[channels,requirement["SourceSpecies"]];
   If[names==={}&&TrueQ[Lookup[consumer,"CompleteLowerOrderSourceCatalog",False]],Continue[]];
   If[Length[names]=!=1,projectFail["ExplicitSourceChannelRequired",<|"Species"->requirement["SourceSpecies"],"Candidates"->names|>]];
   name=First[names]];
  If[!KeyExistsQ[channels,name],projectFail["DeclaredSourceChannelRequired"]];
  If[order>=minimum[name],
   key={order,name};AssociateTo[needed,key->Max[through,Lookup[needed,Key[key],through]]]],
 {requirement,requirements}];
 axes=Lookup[consumer["Assembly"]["DistributionBasis"],"Axes",{consumer["Assembly"]["DistributionBasis"]}];
 conditions=Lookup[consumer["Assembly"],"Assumptions",True]&&
   And@@Map[#[["Interval",1]]<#["Variable"]<#[["Interval",2]]&,axes];
 KeyValueMap[Function[{sourceKey,hi},
  value=projectGenerateBareSource[consumer,{"LO","NLO"}[[First[sourceKey]+1]],Last[sourceKey],hi];
  coefficients=FeynFacet`ExpandPositiveLogarithms[value["Result"]["Coefficients"],conditions];
  coefficients=Map[partonicMap[Function[scalar,Cancel[Together[scalar]]],#]&,coefficients];
  byOrder=Lookup[rows,First[sourceKey],<||>];
  AssociateTo[byOrder,Last[sourceKey]->FeynFacet`CreatePartonicResult[coefficients,
    Join[KeyDrop[value["Result"],{"Coefficients","EpsilonRange"}],<|"LogarithmFactorizationAssumptions"->conditions|>]]];
  AssociateTo[rows,First[sourceKey]->byOrder];timings=Join[timings,value["StageSeconds"]];
  AssociateTo[provenance,sourceKey-><|"File"->value["File"],"RequiredSourceThroughOrder"->hi|>]
 ],needed];
 <|"Format"->"FeynFacet-BarePartonicSourceCatalog","Sources"->rows,
  "Channels"->channels,"MinimumChannelOrders"->minimum,"FlavorClasses"->classes,
  "ChargeSymbols"->chargeSymbols,"FlavorCovariance"->consumer["LowerOrderFlavorCovariance"],
  "CompleteLowerOrderSourceCatalog"->Lookup[consumer,"CompleteLowerOrderSourceCatalog",False],
  "Project"->consumer["Project"],"Polarization"->consumer["Polarization"],
  "StageSeconds"->timings,"GeneratedSources"->provenance,
  "ConsumerIdentity"->KeyTake[consumer,{"Project","Order","Channel"}]|>
],"ProjectCards"];
End[];EndPackage[];
