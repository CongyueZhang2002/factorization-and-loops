#!/usr/bin/env wolframscript
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
Print[scalarCampaignResult["ExplicitFamilyCount"]," explicit / ",scalarCampaignResult["RequestedFamilyCount"],
 "; ",scalarCampaignResult["DeferredFamilyCount"]," deferred; ",scalarCampaignResult["MissingOrdersFamilyCount"],
 " missing orders; ",scalarCampaignResult["UnresolvedCoefficientClassFamilyCount"]," unresolved coefficient classes; ",
 scalarCampaignResult["OtherFailureFamilyCount"]," other failures."];
If[scalarCampaignResult["ExplicitFamilyCount"]+scalarCampaignResult["DeferredFamilyCount"]<scalarCampaignResult["RequestedFamilyCount"],Exit[1]];
Exit[0];
