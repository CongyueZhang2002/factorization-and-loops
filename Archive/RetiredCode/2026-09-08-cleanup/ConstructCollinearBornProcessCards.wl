FeynFacet`ConstructCollinearBornProcessCards::usage="ConstructCollinearBornProcessCards[template,enumeration,speciesMap] builds the distinct Born process cards required by EnumerateNLOCollinearChannels. The template supplies geometry and beam polarization; speciesMap declares the model particle for every abstract quark, antiquark and gluon species. Generated diagram counts determine the complete selected interference set.";
FeynFacet`ConstructCollinearBornProcessCards[template_Association,enumeration_Association,speciesMap_Association]:=Catch[Module[
 {channels,unique,cards=<||>,rows={},row,channel,id,card,partons,old,new,fractions,distribution,replaceDistribution,ids},
 channels=Lookup[enumeration,"Channels",None];If[!ListQ[channels],collinearKernelFail["CollinearChannelEnumerationRequired"]];
 unique=DeleteDuplicates[Lookup[channels,"BornChannel"]];ids=AssociationThread[unique,Table["Born"<>IntegerString[i,10,2],{i,Length[unique]}]];
 fractions=template["MomentumFraction"];
 replaceDistribution[expr_,oldParton_,newParton_,fraction_,side_]:=Module[{rules},
  If[MatchQ[oldParton,FeynArts`V[5]]===MatchQ[newParton,FeynArts`V[5]],Return[expr]];
  rules=If[side==="Incoming",{f1[fraction]->f1g[fraction],g1L[fraction]->g1g[fraction]},
   {D1[fraction]->D1g[fraction],G1L[fraction]->G1g[fraction]}];
  If[MatchQ[oldParton,FeynArts`V[5]],rules=Reverse /@ rules];expr/.rules];
 Do[
  id=ids[channel];new=Join[channel["Incoming"],{channel["Observed"],channel["Recoil"]}];
  If[!AllTrue[new,KeyExistsQ[speciesMap,#]&],collinearKernelFail["CompleteModelSpeciesMapRequired"]];
  new=Lookup[speciesMap,Key[#]]& /@ new;old=Join[First[template["Partons"]],Last[template["Partons"]]];
  If[Length[old]=!=4||Length[Last[fractions]]=!=2||MissingQ[Last[fractions][[1]]],collinearKernelFail["BornTemplateWithFirstFinalPartonObservedRequired"]];
  distribution=template["CoefficientKinematics"]["DistributionFactor"];
  Do[distribution=replaceDistribution[distribution,old[[k]],new[[k]],First[fractions][[k]],"Incoming"],{k,2}];
  distribution=replaceDistribution[distribution,old[[3]],new[[3]],Last[fractions][[1]],"Observed"];
  card=Join[template,<|"Partons"->(Take[new,2]->Drop[new,2]),
   "CoefficientKinematics"->Join[template["CoefficientKinematics"],<|"DistributionFactor"->distribution|>]|>];
  card=FeynFacet`CompleteProcessDiagramSelection[card];
  If[!AssociationQ[card],collinearKernelFail["CollinearBornDiagramGenerationFailed",<|"Channel"->channel|>]];
  AssociateTo[cards,id->card],{channel,unique}];
 rows=(Join[#,<|"BornCard"->ids[#["BornChannel"]]|>]& /@ channels);
 <|"BornCards"->cards,"Channels"->rows,"SpeciesMap"->speciesMap,"DiagramCoverage"->"Complete generated insertion graph sets"|>
 ],"CollinearCounterterms"];
