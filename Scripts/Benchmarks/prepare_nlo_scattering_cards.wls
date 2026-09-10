#!/usr/bin/env wolframscript
(* Add a physical NLO scattering channel and its explicit Born dependencies.
   Usage: prepare_nlo_scattering_cards.wls PROJECT CHANNEL CHANNEL_EXPRESSION
   CHANNEL_EXPRESSION is <|"Incoming"->{a,b},"Observed"->c,"Recoil"->d|>.
   This produces input cards only; it never imports a hard coefficient. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Usage: prepare_nlo_scattering_cards.wls PROJECT CHANNEL CHANNEL_EXPRESSION"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
$PrePrint=.;
projectDirectory=ExpandFileName[FileNameJoin[{root,"Projects",args[[1]]}]];
project=FeynFacet`ReadProjectCard[projectDirectory];
channel=ToExpression[args[[3]]];channelName=args[[2]];
If[!AssociationQ[project]||!AssociationQ[channel],Print["Project and physical channel required."];Exit[2]];
project=Join[KeyDrop[project,"Directory"],<|"FlavorSummation"->"MasslessQCD"|>];
species=Select[Keys[project["SpeciesMap"]],FeynFacet`Private`collinearKernelSpeciesQ];
enumeration=FeynFacet`EnumerateNLOCollinearChannels[channel,<|
 "Species"->species,"Polarization"->project["Polarization"],
 "Schemes"->project["Counterterms"]["Schemes"],
 "SplittingVariable"->project["Counterterms"]["SplittingVariable"],
 "KernelParameters"->project["Counterterms"]["KernelParameters"],"FlavorSummation"->"MasslessQCD"|>];
If[!AssociationQ[enumeration],Print[enumeration];Exit[1]];
label["g"]:="g";
label[{"q",flavor_}]:=ToString[flavor];
label[{"qbar",flavor_}]:=ToString[flavor]<>"bar";
channelLabel[ch_]:=StringRiffle[label/@ch["Incoming"],"-"]<>"_"<>
 StringRiffle[label/@{ch["Observed"],ch["Recoil"]},"-"];
catalog=project["Channels"];
If[KeyExistsQ[catalog,channelName]&&catalog[channelName]=!=channel,
 Print["Channel name already represents different physics."];Exit[1]];
AssociateTo[catalog,channelName->channel];
bornChannels=DeleteDuplicates[Prepend[Lookup[enumeration["Channels"],"BornChannel"],channel],SameQ];
dependencies=<||>;
Do[
 matches=Select[Keys[catalog],catalog[#]===ch&];
 If[Length[matches]>1,Print["Duplicate physical channel names."];Exit[1]];
 name=If[matches==={},channelLabel[ch],First[matches]];
 If[KeyExistsQ[catalog,name]&&catalog[name]=!=ch,Print["Generated channel name collision."];Exit[1]];
 AssociateTo[catalog,name->ch];
 FeynFacet`WriteProjectCard[<|"Contribution"->"Born","AmplitudeLoops"->{0,0},
  "EpsilonRange"->{0,1}|>,projectDirectory<>"/LO/"<>name<>"/Cards/Born.wl"];
 AssociateTo[dependencies,name-><|"File"->"../../../LO/"<>name<>"/Results/Result.wl",
  "EpsilonRange"->{0,1}|>],
 {ch,bornChannels}];
orders=project["Orders"];
AssociateTo[orders,{"LO"->Union[Lookup[orders,"LO",{}],Keys[dependencies]],
 "NLO"->Union[Lookup[orders,"NLO",{}],{channelName}]}];
AssociateTo[project,{"Orders"->orders,"Channels"->catalog}];
FeynFacet`WriteProjectCard[project,projectDirectory<>"/card.wl"];
channelDirectory=projectDirectory<>"/NLO/"<>channelName;
realChannels=FeynFacet`EnumerateNLORealChannels[channel,<|"Species"->species,
 "FlavorCount"->project["Counterterms"]["KernelParameters"]["FlavorCount"]|>];
If[!AssociationQ[realChannels],Print[realChannels];Exit[1]];
FeynFacet`WriteProjectCard[<|"Contribution"->"Real","AmplitudeLoops"->{0,0},
 "Components"->realChannels["Components"],"EpsilonRange"->{-2,0}|>,channelDirectory<>"/Cards/Real.wl"];
FeynFacet`WriteProjectCard[<|"Contribution"->"Virtual","AmplitudeLoops"->{1,0},
 "LoopMomenta"->{{ell},{}},"EpsilonRange"->{-2,0}|>,channelDirectory<>"/Cards/Virtual.wl"];
FeynFacet`WriteProjectCard[<|"Contribution"->"Counterterm","EpsilonRange"->{-1,0},
 "Include"->{"UV","IncomingA","IncomingB","Observed"},
 "LowerOrderResults"->dependencies|>,channelDirectory<>"/Cards/Counterterm.wl"];
plan=FeynFacet`PlanNLOProject[channelDirectory];
If[!AssociationQ[plan],Print[plan];Exit[1]];
Print["NLO_SCATTERING_CARDS_READY ",channelDirectory," Born dependencies: ",Keys[dependencies]];
