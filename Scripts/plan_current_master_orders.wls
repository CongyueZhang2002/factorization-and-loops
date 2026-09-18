Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Usage: plan_current_master_orders.wls COEFFICIENTS.wl REQUEST.wl"];Exit[2]];
coefficients=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[1]]]];
If[!AssociationQ[coefficients]||!TrueQ[coefficients["Complete"]],Print["Complete fresh physical coefficient rows required"];Exit[1]];
e=coefficients["DimensionalRegulator"];basis=coefficients["MasterIntegralBasis"];
rowOrders=<||>;
Do[
 sourceUpper=Table[
  parts=StringSplit[sourceLabel,"/"];
  directory=FileNameJoin[{root,"Projects",parts[[1]],"Raw",parts[[2]],parts[[3]]}];
  card=FeynFacet`ReadContributionCard[directory,parts[[4]]];
  If[!AssociationQ[card],Print[card];Exit[1]];
  Last[card["EpsilonRange"]],
 {sourceLabel,coefficients["SourceGroups"][label]}];
 AssociateTo[rowOrders,label->Max[sourceUpper]],
 {label,Keys[coefficients["Coefficients"]]}];
upper=Table[Max[0,Max[Table[
 value=Lookup[coefficients["Coefficients"][label],Key[master],0];
 If[value===0,-Infinity,
  bound=FeynFacet`DetermineMeromorphicLaurentLowerBound[value,e];
  If[!IntegerQ[bound],Print["Established coefficient Laurent bound required: ",label," ",master];Exit[1]];
  rowOrders[label]-bound],
 {label,Keys[rowOrders]}]]],{master,basis}];
request=<|"MasterIntegralUpperOrders"->upper,
 "CurrentMasterIntegralBasis"->basis,
 "ParameterVerificationRules"->card["Assembly"]["MasterIntegration"]["Boundary"]["ParameterVerificationRules"],
 "GPLTimeLimit"->card["Assembly"]["MasterIntegration"]["GPLTimeLimit"],"Verbose"->True,
 "Coverage"->"Orders derived from every fresh bulk coefficient. Endpoint distribution moment orders are planned separately."|>;
FeynFacet`FamilyArtifactWrite[request,ExpandFileName[args[[2]]]];
Print["COMPLETED MASTER ORDER REQUEST ",upper];
