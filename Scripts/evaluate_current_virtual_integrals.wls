Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: evaluate_current_virtual_integrals.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
directory=root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channelName;
card=FeynFacet`ReadContributionCard[directory,contribution];
If[!AssociationQ[card],Print[card];Exit[1]];
path=card["WorkDirectory"];
source=FeynFacet`FamilyArtifactRead[path<>"/IntegralFamilies.wl"];
reduction=FeynFacet`FamilyArtifactRead[path<>"/Reduction.wl"];
{seconds,audit}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`EvaluateReducedVirtualContribution[card,source,reduction]]];
FeynFacet`FamilyArtifactWrite[audit,path<>"/LaurentAudit.wl"];
If[!AssociationQ[audit]||!AssociationQ[audit["Result"]]||audit["EpsilonRemainderAudit"]["Status"]=!="Passed",
 Print["VIRTUAL EVALUATION FAILED ",InputForm[Short[audit,4]]];Exit[1]];
FeynFacet`FamilyArtifactWrite[audit["Result"],path<>"/Result.wl"];
Print["COMPLETED ",path<>"/Result.wl"," SECONDS ",seconds," SCALAR ORDERS ",audit["Result"]["ScalarMasterUpperOrders"]];
