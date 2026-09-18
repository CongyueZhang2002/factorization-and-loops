Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=4,Print["Usage: construct_current_one_loop_endpoints.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channel,contribution}=args;
directory=root<>"/Projects/"<>projectName<>"/Raw/"<>orderName<>"/"<>channel;
card=FeynFacet`ReadContributionCard[directory,contribution];setup=FeynFacet`ReadProcessCard[card];
If[!AssociationQ[card],Print[card];Exit[1]];
path=card["WorkDirectory"];
project=FeynFacet`ReadProjectCard[directory];
request=FeynFacet`ProjectAssemblyRequest[card];
source=FeynFacet`FamilyArtifactRead[path<>"/TensorReducedIntegrands.wl"];
bulk=FeynFacet`FamilyArtifactRead[path<>"/InteriorLaurentCoefficients.wl"];
save[a_,name_]:=FeynFacet`FamilyArtifactWrite[a,path<>"/"<>name<>".wl",Compression->Automatic];
check[a_,name_]:=If[!AssociationQ[a],save[a,name<>"Failure"];Print["FAILED ",name," ",StringTake[ToString[a,InputForm],UpTo[4000]]];Exit[1]];
check[source,"Source"];check[bulk,"Bulk"];
If[FeynFacet`RequireMatchingProcessDefinition[source,setup]=!=True||
 FeynFacet`RequireMatchingProcessDefinition[bulk,setup]=!=True,
 Print["Generated source does not match the current contribution card"];Exit[1]];
definition=FeynFacet`ContributionIntegrationDefinition[card];
If[Lookup[source,"IntegrationDefinition",None]=!=definition||Lookup[bulk,"IntegrationDefinition",None]=!=definition,
 Print["Endpoint construction requires the original matching integration definition"];Exit[1]];
If[TrueQ[Lookup[bulk,"ConjugateInterferenceAdded",False]],Print["One forward interference is required"];Exit[1]];
e=source["DimensionalRegulator"];range=card["EpsilonRange"];target=Last[range];
axes=request["DistributionBasis"]["Axes"];xs=Lookup[axes,"NormalVariable"];
variables=Lookup[axes,"Variable"];
If[!MatchQ[xs,{__Symbol}]||Length[xs]=!=Length[axes],Print["Declare normal variables for every distribution axis"];Exit[1]];
coordinateCheck=Catch[FeynFacet`Private`projectCheckUnitEndpointAxes[axes];True,"ProjectCards"];
If[coordinateCheck=!=True,Print["Supported independent affine endpoint axes are required: ",coordinateCheck];Exit[1]];
normalRules=MapThread[Function[{axis,normal},With[{v=axis["Variable"],distance=axis["Distance"]},
 v->Cancel[(normal-(distance/.v->0))/Coefficient[distance,v]]]],{axes,xs}];
If[!And@@MapThread[Cancel[(#1["Distance"]/.normalRules)-#2]===0&,{axes,xs}],
 Print["Endpoint coordinate substitution does not invert the declared distances"];Exit[1]];
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
projection=<|"JointlyIntegrableSubtractedStrata"->True,"UniformMeromorphicContinuation"->True,
 "CompleteNonintegrableDivisorTerms"->True,"Justification"->collars|>;
input=FeynFacet`CreateEndpointIntegrationInput[card,definition["Processes"],bulk,profiles,projection,
 <|"SourceRowLabels"->card["StructureFunctions"],"BulkCoordinates"->"Physical","BulkToEndpointRules"->normalRules|>];
check[input,"IntegrationInput"];
inputFile=path<>"/IntegrationInput.wxf";FeynFacet`FamilyArtifactWrite[input,inputFile];
plan=FeynFacet`CreateContributionIntegrationPlan[card,card,definition["Processes"],
 <|"Method"->"EndpointProfiles","IntegrationInputFile"->inputFile|>];check[plan,"IntegrationPlan"];save[plan,"IntegrationPlan"];
{seconds,result}=AbsoluteTiming[FeynFacet`RunRawContribution[card,"all"]];
check[result,"RawContribution"];
Print["COMPLETED CURRENT ONE-LOOP ENDPOINT RESULT ",result["File"]," ASSEMBLY ",seconds," s"];
