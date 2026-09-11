#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
scalarCampaignRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[scalarCampaignRoot<>"/Scripts/Coefficients/ScalarEndpointDriver.wl"];
Get[scalarCampaignRoot<>"/Scripts/Coefficients/ScalarEndpointCampaign.wl"];
scalarCampaignArgs=Rest[$ScriptCommandLine];
If[Length[scalarCampaignArgs]=!=2,Print["Expected CAMPAIGN_INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
scalarCampaignInput=ScalarEndpointDriver`ReadScalarEndpointInput[First[scalarCampaignArgs]];
If[!AssociationQ[scalarCampaignInput],Print["FAIL campaign input ",scalarCampaignInput];Exit[2]];
scalarCampaignResult=ScalarEndpointCampaign`RunScalarEndpointCampaign[scalarCampaignInput,Last[scalarCampaignArgs]];
If[FailureQ[scalarCampaignResult],Print["FAIL ",scalarCampaignResult];Exit[1]];
Print["COMPLETED SCALAR ENDPOINT CAMPAIGN ",scalarCampaignResult["ExplicitContributionCount"]," explicit / ",scalarCampaignResult["RequestedContributionCount"],
 "; ",scalarCampaignResult["DeferredContributionCount"]," deferred; ",scalarCampaignResult["MissingOrdersContributionCount"],
 " missing orders; ",scalarCampaignResult["UnresolvedCoefficientClassContributionCount"]," unresolved coefficient classes; ",
 scalarCampaignResult["OtherFailureContributionCount"]," other failures."];
If[scalarCampaignResult["ExplicitContributionCount"]+scalarCampaignResult["DeferredContributionCount"]<scalarCampaignResult["RequestedContributionCount"],Exit[1]];
Exit[0];
