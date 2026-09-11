(* Shared project physics, ordered channels, and small contribution cards. *)
BeginPackage["FeynFacet`"];
ReadProjectCard::usage="ReadProjectCard[directory] reads the root card.wl and attaches its actual directory.";
ReadContributionCard::usage="ReadContributionCard[channelDirectory,name] composes the project settings with one order/channel contribution. A component is selected as DoubleReal.Gluons.";
ReadProcessCard::usage="ReadProcessCard[compiledCard] or ReadProcessCard[channelDirectory,name] builds a complete amplitude setup from the shared project physics and contribution card.";
WriteProjectCard::usage="WriteProjectCard[association,file] writes a human-readable Wolfram card; short nested associations remain on one row.";
ProjectChannelName::usage="ProjectChannelName[project,physicalChannel] returns the explicit catalog name for a physical incoming/observed/recoil channel.";
RequireMatchingProcessDefinition::usage="RequireMatchingProcessDefinition[artifact,process] requires exact agreement between a stored generated process definition and the current compiled card. Changed charges, spin assignments, momentum or diagram selections require regeneration.";
Begin["`Private`"];
RequireMatchingProcessDefinition[artifact_Association,process_Association]:=Module[{stored,fields},
 stored=Lookup[artifact,"ProcessDefinition",None];
 If[!AssociationQ[stored],Return[Failure["StoredProcessDefinitionRequired",<||>]]];
 fields=Select[Union[Keys[stored],Keys[process]],
  Lookup[stored,#,Missing["Absent"]]=!=Lookup[process,#,Missing["Absent"]]&];
 If[fields==={},True,Failure["GeneratedProcessDefinitionMismatch",<|"ChangedFields"->fields|>]]
];
RequireMatchingProcessDefinition[___]:=Failure["GeneratedArtifactAndCompiledProcessRequired",<||>];

projectFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"ProjectCards"];
projectCheck[value_,tag_]:=If[!AssociationQ[value],projectFail[tag,<|"Cause"->value|>],value];
projectMerge[a_Association,b_Association]:=Association@Table[k->If[KeyExistsQ[a,k]&&KeyExistsQ[b,k]&&AssociationQ[a[k]]&&AssociationQ[b[k]],
 projectMerge[a[k],b[k]],If[KeyExistsQ[b,k],b[k],a[k]]],{k,Union[Keys[a],Keys[b]]}];
projectAbsolutePath[path_String]:=With[{parts=FileNameSplit[ExpandFileName[path]]},FileNameJoin[Join[Take[parts,1],DeleteCases[Rest[parts],""]]]];
projectRootDirectory[directory_String]:=Module[{dir=projectAbsolutePath[directory]},
 While[DirectoryName[dir]=!=dir&&!FileExistsQ[FileNameJoin[{dir,"card.wl"}]],dir=DirectoryName[dir]];
 If[!FileExistsQ[FileNameJoin[{dir,"card.wl"}]],projectFail["ProjectCardNotFound",<|"Directory"->directory|>]];FileNameJoin[FileNameSplit[dir]]];
ReadProjectCard[directory_String]:=Catch[Module[{dir,card},
 dir=projectRootDirectory[directory];card=Get[FileNameJoin[{dir,"card.wl"}]];
 projectCheck[card,"ProjectCardAssociationRequired"];
 If[!ContainsAll[Keys[card],{"Project","ProcessDefaults","Channels","SpeciesMap","Kinematics","Counterterms","Orders","Polarization","SpinParameters"}],
  projectFail["ProjectCardIncomplete"]];
 Join[card,<|"Directory"->dir|>]],"ProjectCards"];
projectChannelLocation[directory_String]:=Module[{project,dir,relative},
 dir=projectAbsolutePath[directory];project=projectCheck[ReadProjectCard[dir],"ProjectCardRequired"];
 relative=Drop[FileNameSplit[dir],Length[FileNameSplit[project["Directory"]]]];
 If[Length[relative]=!=2||!KeyExistsQ[project["Orders"],First[relative]]||
   !MemberQ[project["Orders"][First[relative]],Last[relative]],
  projectFail["DeclaredOrderAndChannelRequired",<|"Directory"->dir|>]];
 <|"ProjectCard"->project,"Directory"->dir,"Order"->First[relative],"Channel"->Last[relative]|>];
ReadContributionCard[directory_String,name_String]:=Catch[Module[{location,parts,file,card,component,project},
 location=projectChannelLocation[directory];project=location["ProjectCard"];parts=StringSplit[name,"."];
 If[!MemberQ[{1,2},Length[parts]]||!AllTrue[parts,StringMatchQ[#,LetterCharacter~~(LetterCharacter|DigitCharacter)...]&],
  projectFail["ContributionNameRequired"]];
 file=FileNameJoin[{location["Directory"],"Cards",First[parts]<>".wl"}];
 If[!FileExistsQ[file],projectFail["ContributionCardNotFound",<|"File"->file|>]];
 card=projectCheck[Get[file],"ContributionCardAssociationRequired"];
 If[Length[parts]===2,
  component=Lookup[Lookup[card,"Components",<||>],Last[parts],Missing[]];
  card=projectMerge[KeyDrop[card,"Components"],projectCheck[component,"ContributionComponentRequired"]]];
 Join[projectMerge[project,card],KeyDrop[location,"ProjectCard"],<|"ProjectDirectory"->project["Directory"],
  "CardFile"->file,"CardName"->name,"ContributionPath"->StringRiffle[parts,"/"]|>]],"ProjectCards"];
ProjectChannelName[project_Association,channel_Association]:=Catch[Module[{matches},
 matches=Select[Keys[project["Channels"]],project["Channels"][#]===channel&];
 If[Length[matches]=!=1,projectFail["UniqueDeclaredChannelRequired",<|"PhysicalChannel"->channel,"Matches"->matches|>]];First[matches]],"ProjectCards"];
(* One physical-leg polarization controls the projector, distribution and kernel. *)
projectSpinSetup[setup_Association,project_Association]:=Module[
 {types,helicities,transverse,partons,fractions,selected,heads,available,zeros={},spin,gluon,outgoing},
 types=Join[project["Polarization"]["Incoming"],{project["Polarization"]["Observed"]}];
 {helicities,transverse}=Lookup[project["SpinParameters"],{"Helicity","Transverse"}];
 If[!MatchQ[types,{"U"|"L"|"T","U"|"L"|"T","U"|"L"|"T"}]||
  Length[helicities]=!=3||Length[transverse]=!=3,projectFail["ThreePhysicalLegPolarizationsRequired"]];
 partons=Join[First[setup["Partons"]],{First[Last[setup["Partons"]]]}];
 fractions=Join[First[setup["MomentumFraction"]],{First[Last[setup["MomentumFraction"]]]}];
 selected=Table[
  spin=types[[i]];gluon=MatchQ[partons[[i]],FeynArts`V[5]];
  If[gluon&&spin==="T",projectFail["NoCollinearGluonTransversity"]];
  heads=If[i<=2,If[gluon,{f1g,g1g},{f1,g1L,h1}],If[gluon,{D1g,G1g},{D1,G1L,H1}]];
  available=(#[fractions[[i]]]& /@ heads);
  AppendTo[zeros,Delete[available,First@FirstPosition[{"U","L","T"},spin]]];
  available[[First@FirstPosition[{"U","L","T"},spin]]],{i,3}];
 outgoing=Length[Last[setup["Partons"]]];
 Join[setup,<|
  "HadronLongSpin"->(Take[MapThread[If[#1==="L",#2,0]&,{types,helicities}],2]->
    PadRight[{If[Last[types]==="L",Last[helicities],0]},outgoing,Missing["NotApplicable"]]),
  "HadronTransSpin"->(Take[MapThread[If[#1==="T",#2,0]&,{types,transverse}],2]->
    PadRight[{If[Last[types]==="T",Last[transverse],0]},outgoing,Missing["NotApplicable"]]),
  "SetDistributionZero"->Flatten[zeros],
  "CoefficientKinematics"->Join[setup["CoefficientKinematics"],<|"DistributionFactor"->Times@@selected|>]|>]
];
ReadProcessCard[directory_String,name_String]:=Module[{card=ReadContributionCard[directory,name]},
  If[AssociationQ[card],ReadProcessCard[card],card]];
ReadProcessCard[card_Association]:=Catch[Module[
 {project,setup,channel,species,radiation,unobserved,final,initial,momenta,loops,orders,selection,source,real,kin},
 If[KeyExistsQ[card,"Components"],projectFail["SelectAnAmplitudeComponent"]];
 If[KeyExistsQ[card,"Current"],Return[projectCurrentProcessCard[card]]];
 project=card;channel=project["Channels"][card["Channel"]];
 species=project["SpeciesMap"];radiation=Lookup[card,"Radiation",{}];
 unobserved=Lookup[card,"UnobservedPartons",Prepend[radiation,channel["Recoil"]]];
 If[!ListQ[unobserved]||unobserved==={}||!AllTrue[Join[channel["Incoming"],{channel["Observed"]},unobserved],KeyExistsQ[species,#]&],
  projectFail["CompleteSpeciesMapRequired"]];
 initial=Lookup[species,Key[#]]& /@ channel["Incoming"];
 final=Lookup[species,Key[#]]& /@ Prepend[unobserved,channel["Observed"]];
 setup=Join[project["ProcessDefaults"],KeyTake[project,{"ColorRules"}]];
 If[Length[project["FinalMomenta"]]<Length[final],projectFail["AdditionalFinalMomentaRequired"]];
 momenta=Take[project["FinalMomenta"],Length[final]];
 setup=Join[setup,<|"Partons"->(initial->final),"PartonMomentum"->(project["IncomingMomenta"]->momenta),
  "PhaseSpaceMomentum"->Rest[momenta],"PartonIntegrated"->{momenta[[2]]}|>];
 Do[source=setup[key];AssociateTo[setup,key->(First[source]->PadRight[{First[Last[source]]},Length[final],Missing["NotApplicable"]])],
 {key,{"MomentumFraction","HadronMomentum","HadronLongDirection","HadronDualDirection"}}];
 setup["SetMassZero"]=DeleteDuplicates[Join[setup["SetMassZero"],If[TrueQ[Lookup[project,"MasslessFinalState",False]],momenta,{}]]];
 kin=project["Kinematics"];real=Length[final]>2;
 setup["HadronicVariables"]=Join[setup["HadronicVariables"],<|"Assumptions"->
  (kin["CommonAssumptions"]&&kin[If[real,"RadiativeConditions","BornConditions"]])|>];
 setup["CoefficientKinematics"]=Join[setup["CoefficientKinematics"],<|
  "PhysicalRegion"->kin[If[real,"RadiativeRegion","BornRegion"]]|>];
 setup=projectSpinSetup[setup,project];
 If[KeyExistsQ[setup,"GluonPolarizationReferences"],
  With[{projectedGluons=Cases[Transpose[{Flatten[List@@setup["Partons"]],
    Flatten[List@@setup["PartonMomentum"]],Flatten[List@@setup["HadronMomentum"]]}],
    {FeynArts`V[5],momentum_,hadron_}/;!MissingQ[hadron]:>momentum]},
   setup["GluonPolarizationReferences"]=KeyTake[setup["GluonPolarizationReferences"],projectedGluons]];
  If[setup["GluonPolarizationReferences"]===<||>,setup=KeyDrop[setup,"GluonPolarizationReferences"]]];

 orders=Lookup[card,"AmplitudeLoops",{0,0}];loops=Lookup[card,"LoopMomenta",{{},{}}];
 If[Length[orders]=!=2||!VectorQ[orders,IntegerQ[#]&&#>=0&]||Length[loops]=!=2||Map[Length,loops]=!=orders,
  projectFail["AmplitudeLoopMomentaRequired"]];
 selection=Lookup[card,"DiagramIndices",All];
 Do[AssociateTo[setup,{"ForwardAmplitudes","ConjugateAmplitudes"}[[i]]-><|"LoopOrder"->orders[[i]],"LoopMomenta"->loops[[i]],
  "DiagramIndices"->If[selection===All,{1},selection[[i]]]|>],{i,2}];
 setup=projectMerge[setup,Lookup[card,"ProcessOverrides",<||>]];
 If[selection===All,setup=projectCheck[CompleteProcessDiagramSelection[setup],"DiagramSelectionFailed"]];
 If[KeyExistsQ[card,"AssemblyWeight"]&&!TrueQ[assemblyWeight[setup]===card["AssemblyWeight"]],
  projectFail["DeclaredAssemblyWeightDisagreesWithParticleContent"]];
 setup],"ProjectCards"];

(* Current insertions are external sources, not PDF or FF legs. *)
projectCurrentProcessCard[card_Association]:=Module[
 {channel,species,current,incoming,outgoing,observed,unobserved,initialMomenta,finalMomenta,
  fields,momenta,setup,orders,loops,legs,spin,leg,field,indices,physical,massless},
 channel=card["Channels"][card["Channel"]];species=card["SpeciesMap"];current=card["Current"];
 If[!ContainsAll[Keys[current],{"Momentum","Field","Side","Indices","Coupling","MomentumSpace"}]||
  !MemberQ[{"Incoming","Outgoing"},current["Side"]],projectFail["ExternalCurrentDeclarationRequired"]];
 incoming=channel["Incoming"];observed=Lookup[channel,"Observed",None];
 unobserved=Lookup[card,"UnobservedPartons",{}];outgoing=Join[If[observed===None,{}, {observed}],unobserved];
 If[!AllTrue[Join[incoming,outgoing],KeyExistsQ[species,#]&]||
  Length[incoming]=!=Length[card["IncomingMomenta"]]||Length[outgoing]>Length[card["FinalMomenta"]],
  projectFail["CurrentChannelSpeciesAndMomentaRequired"]];
 initialMomenta=card["IncomingMomenta"];finalMomenta=Take[card["FinalMomenta"],Length[outgoing]];
 fields={Lookup[species,Key[#]]&/@incoming,Lookup[species,Key[#]]&/@outgoing};
 momenta={initialMomenta,finalMomenta};
 If[current["Side"]==="Incoming",fields[[1]]=Append[fields[[1]],current["Field"]];momenta[[1]]=Append[momenta[[1]],current["Momentum"]],
  fields[[2]]=Append[fields[[2]],current["Field"]];momenta[[2]]=Append[momenta[[2]],current["Momentum"]]];
 orders=Lookup[card,"AmplitudeLoops",{0,0}];loops=Lookup[card,"LoopMomenta",{{},{}}];
 If[!MatchQ[orders,{_Integer?NonNegative,_Integer?NonNegative}]||Length[loops]=!=2||Length/@loops=!=orders,
  projectFail["AmplitudeLoopMomentaRequired"]];
 setup=Join[card["ProcessDefaults"],<|"Partons"->(First[fields]->Last[fields]),
  "PartonMomentum"->(First[momenta]->Last[momenta]),
  "Currents"->{KeyTake[current,{"Momentum","Indices","Coupling"}]},
  "ForwardAmplitudes"-><|"LoopOrder"->First[orders],"LoopMomenta"->First[loops],"DiagramIndices"->{1}|>,
  "ConjugateAmplitudes"-><|"LoopOrder"->Last[orders],"LoopMomenta"->Last[loops],"DiagramIndices"->{1}|>|>];
 spin=card["Polarization"]["Incoming"];
 If[Length[spin]=!=Length[incoming],projectFail["IncomingCurrentProcessPolarizationsRequired"]];
 legs=Table[
  leg=<|"Role"->"PDF","Species"->incoming[[i]],"Polarization"->spin[[i]],"Momentum"->initialMomenta[[i]],"MomentumSpace"->"Physical4"|>;
  If[incoming[[i]]==="g",indices=card["GluonSpinIndices"]["Incoming"][[i]];
   leg=Join[leg,<|"ReferenceMomentum"->Lookup[Lookup[card,"GluonPolarizationReferences",<||>],initialMomenta[[i]],current["Momentum"]],"Indices"->indices|>]];leg,
 {i,Length[incoming]}];
 If[observed=!=None,
  leg=<|"Role"->"FF","Species"->observed,"Polarization"->card["Polarization"]["Observed"],
   "Momentum"->First[finalMomenta],"MomentumSpace"->"IntegratedD"|>;
  If[observed==="g",leg=Join[leg,<|"ReferenceMomentum"->First[initialMomenta],"Indices"->card["GluonSpinIndices"]["Observed"]|>]];
  AppendTo[legs,leg]];
 physical=Join[initialMomenta,If[current["MomentumSpace"]==="Physical4",{current["Momentum"]},{}]];
 massless=Join[initialMomenta,finalMomenta];
 setup=Join[setup,<|"SpinDensities"->legs,"PhysicalMomenta"->physical,"MasslessMomenta"->massless,
  "SummedGluons"->Pick[finalMomenta,MapIndexed[#1==="g"&&(observed===None||First[#2]>1)&,outgoing]],
  "UnobservedPartons"->unobserved|>];
 If[KeyExistsQ[card,"UnobservedGluonStates"],
  If[!ListQ[card["UnobservedGluonStates"]]||!AllTrue[card["UnobservedGluonStates"],AssociationQ]||
    Sort[Lookup[card["UnobservedGluonStates"],"Momentum",{}]]=!=Sort[setup["SummedGluons"]],
   projectFail["CompleteUnobservedGluonStateDeclarationRequired"]];
  setup=Join[KeyDrop[setup,"SummedGluons"],KeyTake[card,{"UnobservedGluonStates"}]]];
 setup=projectMerge[setup,Lookup[card,"ProcessOverrides",<||>]];
 projectCheck[CompleteProcessDiagramSelection[setup],"CurrentDiagramSelectionFailed"]
];

(* Locate all levels above Results; preserve order/channel and nested contribution names. *)
projectResultLocation[resultDirectory_String,workspaceRoot_String]:=Module[{parts,base,positions,index,owner,relative},
 parts=DeleteCases[FileNameSplit[ExpandFileName[resultDirectory]],""];
 base=DeleteCases[FileNameSplit[ExpandFileName[workspaceRoot]],""];
 positions=Flatten[Position[parts,"Results"]];
 If[positions==={},Return[Failure["ResultsAncestorRequired",<|"Directory"->resultDirectory|>]]];
 index=Last[positions];owner=Take[parts,index-1];
 If[Length[owner]<Length[base]||Take[owner,Length[base]]=!=base,
  Return[Failure["ResultsOutsideWorkspace",<|"Directory"->resultDirectory,"Workspace"->workspaceRoot|>]]];
 relative=Drop[owner,Length[base]];
 <|"OwnerParts"->relative,"RunParts"->Drop[parts,index],
   "OwnerDirectory"->FileNameJoin[Join[{ExpandFileName[workspaceRoot]},relative]]|>
];

(* Formatting is structural: short associations and short rules stay together. *)
projectCardText[x_,indent_:0]:=Module[{one,pad=StringRepeat[" ",indent],rows},
 one=ToString[x,InputForm,PageWidth->Infinity];
 If[StringLength[one]+indent<=116,Return[one]];
 Which[
 AssociationQ[x],rows=KeyValueMap[projectCardRule[#1,#2,indent+2]&,x];
  "<|\n"<>StringRiffle[rows,",\n"]<>"\n"<>pad<>"|>",
 ListQ[x],"{\n"<>StringRiffle[(StringRepeat[" ",indent+2]<>projectCardText[#,indent+2]& /@ x),",\n"]<>"\n"<>pad<>"}",
 True,one]
];
projectCardRule[key_,value_,indent_]:=Module[{prefix,one},
 prefix=StringRepeat[" ",indent]<>ToString[key,InputForm,PageWidth->Infinity]<>" -> ";
 one=ToString[value,InputForm,PageWidth->Infinity];
 If[StringLength[prefix<>one]<=116,prefix<>one,prefix<>projectCardText[value,indent]]
];
WriteProjectCard[card_Association,path_String]:=Module[{text=projectCardText[card],dir=DirectoryName[path]},
 If[!DirectoryQ[dir],CreateDirectory[dir,CreateIntermediateDirectories->True]];
 Export[path,text<>"\n","Text"];path];
End[];EndPackage[];
