Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]<2,Print["Usage: run_measured_contribution.wls CARD {prepare|de|masters|interior|check|virtual|loop|loop-interior|loop-contact-order|loop-inclusive-prepare|loop-inclusive-subtract} [all|resume]"];Exit[2]];
path=ExpandFileName[args[[1]]];stage=args[[2]];mode=If[Length[args]>=3,args[[3]],"resume"];
card=FeynFacet`ReadContributionCard[DirectoryName[path,2],FileNameTake[DirectoryName[path]]];
If[!AssociationQ[card],Print[InputForm[card]];Exit[1]];
If[stage==="loop-inclusive-subtract",result=FeynFacet`ConstructMeasuredCurrentOneLoopInclusiveSubtractions[card,mode];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 Print["MEASURED CONTRIBUTION STAGE COMPLETE loop-inclusive-subtract"];Exit[0]];
If[stage==="loop-inclusive-prepare",result=FeynFacet`PrepareMeasuredCurrentOneLoopInclusiveIntegration[card,mode];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 Print["INCLUSIVE EXTERNAL PRESCRIPTION LIMIT ",result["PrescriptionLimit"]["ExternalPrescriptionLimitEstablished"]];
 Print["MEASURED CONTRIBUTION STAGE COMPLETE loop-inclusive-prepare"];Exit[0]];
If[stage==="loop-contact-order",result=FeynFacet`VerifyMeasuredCurrentOneLoopContactOrder[card,mode];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 Print["CONTACT DERIVATIVE ORDER BOUND ",result["ContactDerivativeOrderBound"]];
 Print["MEASURED CONTRIBUTION STAGE COMPLETE loop-contact-order"];Exit[0]];
If[stage==="loop-interior",result=FeynFacet`IntegrateMeasuredCurrentOneLoopInterior[card,mode];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 Print["INTEGRATION TIMINGS ",InputForm[result["IntegrationTimings"]]];
 Print["MEASURED CONTRIBUTION STAGE COMPLETE loop-interior"];Exit[0]];
If[stage==="loop",result=FeynFacet`PrepareMeasuredCurrentOneLoopContribution[card,mode];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 Print["STAGE SECONDS ",InputForm[result["StageSeconds"]]];
 Print["MEASURED CONTRIBUTION STAGE COMPLETE loop"];Exit[0]];
If[stage==="virtual",result=FeynFacet`IntegrateMeasuredCurrentVirtual[card,mode];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 Print["STAGE SECONDS ",InputForm[result["StageSeconds"]]];
 Print["MEASURED CONTRIBUTION STAGE COMPLETE virtual"];Exit[0]];
prepared=FeynFacet`PrepareMeasuredCurrentContribution[card,mode];
If[!AssociationQ[prepared],Print[InputForm[prepared]];Exit[1]];
result=Switch[stage,"prepare",prepared,
 "de",FeynFacet`ConstructMeasuredContributionDifferentialSystems[card,prepared],
 "masters",de=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/DifferentialSystem.wl"];
 If[!AssociationQ[de],Print[InputForm[de]];Exit[1]];
 FeynFacet`ConstructMeasuredContributionMasterValues[card,prepared,de],
 "interior",de=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/DifferentialSystem.wl"];
 values=FeynFacet`FamilyArtifactRead[card["WorkDirectory"]<>"/MasterValues.wl"];
 If[!AllTrue[{de,values},AssociationQ],Print["Exact physical master inputs required"];Exit[1]];
 FeynFacet`AssembleMeasuredContributionInterior[card,de,values],
 "check",FeynFacet`CheckMeasuredContributionInterior[card,prepared],_,Failure["UnknownMeasuredStage",<||>]];
If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
Print["STAGE SECONDS ",InputForm[Lookup[result,"StageSeconds",<||>]]];
Print["MEASURED CONTRIBUTION STAGE COMPLETE ",stage];Exit[0];
