Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
bsRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[bsRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[bsRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
bsConsumer=FeynFacet`BuildCountertermProjectCard[bsRoot<>"/Projects/ppHX_UU/Raw/NNLO/qqp-qqp"];
bsReject[card_]:=Catch[FeynFacet`Private`projectGenerateBareSource[card,"NLO","qqp-qqp",0],"ProjectCards"];
Do[
 bsTemplates=bsConsumer["BareSourceContributions"];
 bsNLO=bsTemplates["NLO"];
 AssociateTo[bsNLO,"qqp-qqp"->KeyTake[bsNLO["qqp-qqp"],bsTypes]];
 bsBad=Join[bsConsumer,<|"BareSourceContributions"->Join[bsTemplates,<|"NLO"->bsNLO|>]|>];
 bsFailure=bsReject[bsBad];
 FTTest`FTAssert["complete Born-capable source rejects the narrowed "<>StringRiffle[bsTypes,"+"]<>" template",
   MatchQ[bsFailure,Failure["CompleteBareContributionSelectionRequired",_Association]]],
 {bsTypes,{{"Real"},{"Virtual"}}}];
bsUnknown=Join[bsConsumer,<|"MinimumChannelOrders"->KeyDrop[bsConsumer["MinimumChannelOrders"],"qqp-qqp"]|>];
FTTest`FTAssert["unknown source minimum order cannot certify a complete declared subset",
 MatchQ[bsReject[bsUnknown],Failure["ExplicitSourceMinimumOrderRequired",_Association]]];
FTTest`FTAssert["unknown minimum order also rejects directly requested contribution discovery",
 MatchQ[Catch[FeynFacet`Private`projectRequiredBareContributionTypes[
   <|"BareSourceContributions"-><|"NLO"-><|"test"-><|"Virtual"-><||>|>|>|>|>,"NLO","test"],"ProjectCards"],
  Failure["ExplicitSourceMinimumOrderRequired",_Association]]];
bsDY=FeynFacet`ReadProjectCard[bsRoot<>"/Projects/DrellYan_UU"];
FTTest`FTAssert["current two-beam project explicitly declares Born and real-only minimum orders",
 AssociationQ[bsDY]&&Sort[DeleteDuplicates[Values[bsDY["MinimumChannelOrders"]]]]==={0,1}];
bsMetadata=<|"DimensionalRegulator"->Global`Epsilon,"Variable"->w,"Endpoint"->1,
 "Scale"->s,"Variables"->{v,w},"Order"->"LO","Contribution"->"Born",
 "DistributionBasis"-><|"Variable"->w,"Endpoint"->1,"Interval"->{0,1}|>,"Coupling"->bsAlpha,"CouplingPower"->2|>;
bsResult=FeynFacet`CreatePartonicResult[<|0-><|"DeltaCoefficient"->bsAlpha^2,
 "PlusCoefficients"-><||>,"RegularCoefficient"->2 bsAlpha^2 w|>|>,bsMetadata];
bsCheck[result_,power_]:=Catch[FeynFacet`Private`projectValidateBareCouplingPower[result,bsAlpha,power],"ProjectCards"];
FTTest`FTAssert["actual homogeneous scalar coefficients satisfy the declared coupling power",AssociationQ[bsCheck[bsResult,2]]];
FTTest`FTAssert["metadata does not certify a wrong actual coupling power",
 MatchQ[bsCheck[bsResult,3],Failure["BareContributionCouplingPowerMismatch",_Association]]];
bsZero=FeynFacet`CreatePartonicResult[
 <|0-><|"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>,bsMetadata];
FTTest`FTAssert["identically zero coefficients are exempt from coupling power inference",AssociationQ[bsCheck[bsZero,3]]];
FTTest`FTReport[];
