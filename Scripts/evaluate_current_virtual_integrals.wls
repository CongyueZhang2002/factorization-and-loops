
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
arguments=Rest[$ScriptCommandLine];
If[Length[arguments]=!=4,Print["Usage: evaluate_current_virtual_integrals.wls PROJECT ORDER CHANNEL CONTRIBUTION"];Exit[2]];
{projectName,orderName,channelName,contribution}=arguments;
directory=root<>"/Projects/"<>projectName<>"/"<>orderName<>"/"<>channelName;
path=directory<>"/Results/"<>StringReplace[contribution,"."->"/"];
card=FeynFacet`ReadContributionCard[directory,contribution];setup=FeynFacet`ReadProcessCard[directory,contribution];
request=FeynFacet`Private`projectAssemblyRequest[card,channelName,First[StringSplit[contribution,"."]]];
source=FeynFacet`FamilyArtifactRead[path<>"/IntegralFamilies.wl"];
reduction=FeynFacet`FamilyArtifactRead[path<>"/Reduction.wl"];
If[!AllTrue[{card,setup,request,source,reduction},AssociationQ],Print["Completed virtual inputs required"];Exit[1]];
If[FeynFacet`RequireMatchingProcessDefinition[source,setup]=!=True,
 Print["Generated inputs do not match the current process card; regenerate the contribution"];Exit[1]];
definition=Lookup[card["Assembly"],"ScalarIntegralLibrary",None];
If[!AssociationQ[definition]||definition["Name"]=!="MasslessTwoLoopVertex",Print["Declare a supported scalar integral library"];Exit[1]];
e=request["DimensionalRegulator"];range=card["EpsilonRange"];
loops=source["LoopMomenta"];external=source["ExternalMomenta"];kin=source["KinematicRules"];
If[Length[loops]=!=2,Print["This library requires two loop momenta"];Exit[1]];
pnull=definition["NullMomenta"];scale=definition["ScaleSquared"];
invariants=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[{
 FeynCalc`SPD[pnull[[1]]],FeynCalc`SPD[pnull[[2]]],FeynCalc`SPD[Total[pnull]]}+{0,0,scale}]]/.FeynCalc`FCI[kin];
If[!AllTrue[Factor/@invariants,#===0&],Print["Scalar library external invariants do not match ",invariants];Exit[1]];
library=FeynFacet`MasslessVertexMasterLibrary[loops,pnull,external,kin,scale,e];
matching=FeynFacet`MatchVirtualMastersToLibrary[reduction["Masters"],reduction["Families"],library];
FeynFacet`FamilyArtifactWrite[matching,path<>"/VerifiedMasterLibraryMatching.wl",Compression->Automatic];
If[!AssociationQ[matching]||matching["Status"]=!="AllMastersMatched",Print[System`Short[matching,3]];Exit[1]];
support=Catch[FeynFacet`Private`currentBornSupport[request],"PartonicResults"];
If[!AssociationQ[support],Print[support];Exit[1]];
prefactor=(source["IntegrationMeasureConversion"]support["Measure"]Lookup[card,"SymmetryFactor",1])/.support["Point"];
{seconds,expanded}=AbsoluteTiming[FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ExpandMatchedVirtualIntegralCombination[source,reduction,matching,e,range,
 Function[{name,orders},FeynFacet`EvaluateMasslessVertexMaster[name,scale,e,orders]],
 <|"Prefactor"->prefactor,"ScalarCoefficientRules"->Join[request["BareCouplingRules"],
 Lookup[request,"ColorRules",{}],support["Point"]]|>]]];
FeynFacet`FamilyArtifactWrite[expanded,path<>"/LaurentAudit.wl",Compression->Automatic];
If[!AssociationQ[expanded["Result"]]||expanded["EpsilonRemainderAudit"]["Status"]=!="Passed",
 Print[ToString[System`Short[expanded,4],InputForm]];Exit[1]];
scalar=expanded["Result"];
FeynFacet`FamilyArtifactWrite[scalar,path<>"/IntegratedScalarCoefficients.wl",Compression->Automatic];
addConjugate=card["AmplitudeLoops"]==={2,0};
conditions=request["Assumptions"]&&scale>0;
rows=Association@Table[n->FeynFacet`Private`partonicCornerDistribution[
 vector=Table[Lookup[scalar["Coefficients"],Key[{i,n}],0],{i,Length[scalar["StructureFunctions"]]}];
 If[addConjugate,vector=vector+Conjugate[vector]];
 FullSimplify[ComplexExpand[vector,Lookup[setup,"ComplexParameters",{}]],Assumptions->conditions],
 Length[support["Axes"]]],{n,First[range],Last[range]}];
meta=Join[KeyDrop[request,{"CurrentProjectors","KinematicRules","BornSupportKinematicRules",
 "BornMomentumRules","BornConstraints","TwoParticleMeasurement","BareCouplingRules"}],
 FeynFacet`Private`projectResultIdentity[FeynFacet`ReadProjectCard[directory],channelName,setup],
 <|"Order"->orderName,"Contribution"->contribution,"CouplingPower"->2,
 "StructureFunctions"->scalar["StructureFunctions"],"ConjugateInterferenceAdded"->addConjugate,
 "BornSupportJacobian"->support["JacobianDeterminant"],"ScalarMasterUpperOrders"->scalar["ScalarMasterUpperOrders"],
 "LoopNormalization"->"Generated d^D ell/(2 pi)^D; verified normalized scalar master library"|>];
result=FeynFacet`CreatePartonicResult[rows,meta];
If[!AssociationQ[result]||!FreeQ[result["Coefficients"],_FeynCalc`GLI|_Integrate|_Inactive|_HypergeometricPFQ|_Conjugate|_Re|_Im],
 Print["Incomplete explicit virtual coefficient ",System`Short[result,3]];Exit[1]];
FeynFacet`FamilyArtifactWrite[result,path<>"/Result.wl",Compression->Automatic];
Print["COMPLETED ",path<>"/Result.wl"," SECONDS ",seconds," SCALAR ORDERS ",scalar["ScalarMasterUpperOrders"]];
