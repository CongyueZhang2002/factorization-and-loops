$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=4,Print["Usage: construct_current_one_loop_endpoints.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channel,contribution}=args;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channel;
path=directory<>"/Results/"<>StringReplace[contribution,"."->"/"];
card=FeynFacet`ReadContributionCard[directory,contribution];setup=FeynFacet`ReadProcessCard[directory,contribution];
project=FeynFacet`ReadProjectCard[directory];
request=FeynFacet`Private`projectAssemblyRequest[card,channel,First[StringSplit[contribution,"."]]];
source=FeynFacet`FamilyArtifactRead[path<>"/TensorReducedIntegrands.wl"];
bulk=FeynFacet`FamilyArtifactRead[path<>"/InteriorLaurentCoefficients.wl"];
save[a_,name_]:=FeynFacet`FamilyArtifactWrite[a,path<>"/"<>name<>".wl",Compression->Automatic];
check[a_,name_]:=If[!AssociationQ[a],save[a,name<>"Failure"];Print["FAILED ",name," ",StringTake[ToString[a,InputForm],UpTo[4000]]];Exit[1]];
check[source,"Source"];check[bulk,"Bulk"];
If[FeynFacet`RequireMatchingProcessDefinition[source,setup]=!=True||
 FeynFacet`RequireMatchingProcessDefinition[bulk,setup]=!=True,
 Print["Generated source does not match the current contribution card"];Exit[1]];
If[TrueQ[Lookup[bulk,"ConjugateInterferenceAdded",False]],Print["One forward interference is required"];Exit[1]];
e=source["DimensionalRegulator"];range=card["EpsilonRange"];target=Last[range];
axes=request["DistributionBasis"]["Axes"];xs=Lookup[axes,"NormalVariable"];
variables=Lookup[axes,"Variable"];
If[!MatchQ[xs,{__Symbol}]||Length[xs]=!=Length[axes],Print["Declare normal variables for every distribution axis"];Exit[1]];
normalRules=MapThread[Function[{axis,normal},With[{v=axis["Variable"],distance=axis["Distance"]},
 v->Cancel[(normal-(distance/.v->0))/Coefficient[distance,v]]]],{axes,xs}];
rawConditions=source["Measurement"]["Assumptions"]&&request["Assumptions"];
conditions=(rawConditions/.normalRules)&&And@@(0<#<1&/@xs);
closedConditions=(request["Assumptions"]/.normalRules)&&And@@(0<=#<1&/@xs);
values=FeynFacet`NormalizeMeasuredCurrentScalarValues[source,
 Join[card["Assembly"],KeyTake[card,{"SymmetryFactor","FlavorMultiplicity","ColorRules"}]]];
check[values,"NormalizedValues"];values=values/.normalRules/.D->4-2e;
(* The hypergeometric endpoint identity is selected near the joint corner.
   Its open-face continuation is checked separately against the full interval. *)
nearConditions=(request["Assumptions"]/.normalRules)&&And@@(0<#<1/3&/@xs);
{seconds,resolved}=AbsoluteTiming[FeynFacet`ResolveOneLoopScalarEndpointPowers[values,e,xs,nearConditions]];
check[resolved,"ResolvedEndpointPowers"];save[resolved,"ResolvedEndpointPowers"];
Print["RESOLVED ",seconds," s; ",Length[resolved["Terms"]]," terms"];
collars=FeynFacet`VerifyResolvedEndpointCollars[resolved,closedConditions];check[collars,"EndpointCollars"];
If[!TrueQ[collars["SimpleCoordinatePowers"]],Print["Higher endpoint poles require additional jets"];Exit[1]];
save[collars,"EndpointCollarVerification"];
profiles=FeynFacet`ConstructResolvedEndpointFaceProfiles[resolved];check[profiles,"ExactProfiles"];save[profiles,"ExactEndpointProfiles"];
groups={};audits=<||>;
Do[
 faceSeries=<||>;
 Do[
  values=group["FaceProfiles"][face];
  {seconds,answer}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
   FeynFacet`ExpandGaussHypergeometricCombinations[values,e,{First[range],target+Length[face]}]]];
  exactZero=AssociationQ[answer["Result"]]&&AllTrue[Values[answer["Result"]["Coefficients"]],#===0&]&&
   AllTrue[Values[values],#===0&];
  If[!AssociationQ[answer["Result"]]||(!exactZero&&answer["EpsilonRemainderAudit"]["Status"]=!="Passed"),
   save[answer,"EndpointProfileFailure"];Print["FAILED PROFILE ",group["Powers"]," ",face];Exit[1]];
  row=answer["Result"];
  conjugate=FeynFacet`ConjugateExplicitScalarFunctions[row["Coefficients"],conditions,Lookup[setup,"ComplexParameters",{}]];
  If[FailureQ[conjugate],save[conjugate,"ProfileConjugationFailure"];Print["PROFILE CONJUGATION FAILED"];Exit[1]];
  coefficients=Merge[{row["Coefficients"],conjugate},Total];
  simple=FeynFacet`CancelRationalCoefficients[Values[coefficients]];
  If[!ListQ[simple],save[simple,"ProfileCollectionFailure"];Exit[1]];
  row["Coefficients"]=AssociationThread[Keys[coefficients],simple];
  AssociateTo[faceSeries,face->row];
  AssociateTo[audits,{Length[groups]+1,face}->If[exactZero,<|"Status"->"ExactZeroNoTruncation"|>,answer["EpsilonRemainderAudit"]]];
  Print["PROFILE ",Length[groups]+1,"/",Length[profiles["ProfileGroups"]]," FACE ",face," ",seconds," s"],
 {face,Keys[group["FaceProfiles"]]}];
 AppendTo[groups,<|"Powers"->group["Powers"],"FaceSeries"->faceSeries|>],
{group,profiles["ProfileGroups"]}];
profiles=Join[KeyDrop[profiles,"ProfileGroups"],<|"ProfileGroups"->groups,"ConjugateInterferenceAdded"->True,
 "ExactInEpsilon"->False,"AllRequestedProfilesCompleted"->True|>];
save[profiles,"HermitianEndpointProfiles"];save[audits,"EndpointProfileAudits"];
conjugate=FeynFacet`ConjugateExplicitScalarFunctions[bulk["Coefficients"],rawConditions,Lookup[setup,"ComplexParameters",{}]];
If[FailureQ[conjugate],save[conjugate,"InteriorConjugationFailure"];Print["INTERIOR CONJUGATION FAILED"];Exit[1]];
bulk["Coefficients"]=Merge[{bulk["Coefficients"],conjugate},Total];bulk["ConjugateInterferenceAdded"]=True;
save[bulk,"HermitianInteriorCoefficients"];
bulk["Coefficients"]=bulk["Coefficients"]/.normalRules;
meta=Join[KeyDrop[request,{"CurrentProjectors","KinematicRules","BornSupportKinematicRules","BornMomentumRules",
 "BornConstraints","TwoParticleMeasurement","BareCouplingRules"}],
 FeynFacet`Private`projectResultIdentity[project,channel,setup],
 <|"Order"->orderName,"Contribution"->contribution,
 "CouplingPower"->project["BornCouplingPower"]+Switch[orderName,"LO",0,"NLO",1,"NNLO",2],
 "EpsilonRange"->range,"ConjugateInterferenceAdded"->True,
 "TestFunctionSupport"->request["EndpointExpansion"]["TestFunctionSupport"]|>];
projection=<|"JointlyIntegrableSubtractedStrata"->True,"UniformMeromorphicContinuation"->True,
 "CompleteNonintegrableDivisorTerms"->True,"Justification"->collars|>;
{seconds,result}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`CreatePartonicResultFromProfileCoefficients[bulk,profiles,meta,projection]]];
save[result,"EndpointAssemblyAudit"];
If[!AssociationQ[result["Result"]]||result["EpsilonRemainderAudit"]["Status"]=!="Passed",
 Print["ENDPOINT ASSEMBLY FAILED ",StringTake[ToString[result,InputForm],UpTo[4000]]];Exit[1]];
save[result["Result"],"Result"];
Print["COMPLETED CURRENT ONE-LOOP ENDPOINT RESULT ",path," ASSEMBLY ",seconds," s"];
