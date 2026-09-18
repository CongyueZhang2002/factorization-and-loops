Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Usage: prepare_counterterm_cards.wls PROJECT ORDER CHANNEL|all"];Exit[2]];
{project,order,selection}=args;
common=FeynFacet`ReadProjectCard[FileNameJoin[{root,"Projects",project}]];
If[!AssociationQ[common]||!MemberQ[{"NLO","NNLO"},order],Print["Invalid project/order"];Exit[2]];
channels=If[selection==="all",common["Orders"][order],{selection}];report=<||>;
Do[
 directory=FileNameJoin[{root,"Projects",project,"Raw",order,channel}];
 {seconds,definitions}=AbsoluteTiming[FeynFacet`PlanCountertermContributionCards[directory]];
 If[!ListQ[definitions],Print["FAILED ",channel," ",definitions];Exit[1]];
 cards=FeynFacet`WriteCountertermCards[directory,definitions];
 If[!AssociationQ[cards],Print["FAILED ",channel," ",cards];Exit[1]];
 AssociateTo[report,channel-><|"Cards"->Keys[cards],"PlanningSeconds"->seconds|>];
 Print["COUNTERTERM CARDS ",channel," ",Length[cards]," SECONDS ",seconds],
{channel,channels}];
Print["COMPLETED COUNTERTERM CARDS ",Length[report]];
