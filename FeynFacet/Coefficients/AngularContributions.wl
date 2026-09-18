(* From an exact two-body current density to the common partonic result.
   The original products supply the endpoint prescription proof; partial
   fractions and angular IBP are used only to compute the same integral. *)
BeginPackage["FeynFacet`"];
ConstructFixedObservedRealContribution::usage="ConstructFixedObservedRealContribution[density,prepared,request] certifies the original unit-cut products uniformly at the declared threshold, expands exact angular functions before epsilon, and returns explicit delta/plus/regular Laurent coefficients in the common partonic format.";
Begin["`Private`"];
ConstructFixedObservedRealContribution[source_Association,prepared_Association,request_Association]:=Catch[Module[
 {axes,axis,e,t,w,rules,assum,conditions,certificates=<||>,expansions=<||>,timings=<||>,rows={},
  seconds,certificate,expansion,data,value,coefficients,result,path,realGeometry,scalarGeometry},
 If[Lookup[source,"Format",None]=!="FeynFacet-TwoBodyAngularDensity"||!TrueQ[Lookup[source,"ExactInEpsilon",False]],
  partonicResultFail["ExactTwoBodyAngularDensityRequired"]];
 axes=request["DistributionBasis"]["Axes"];
 If[Length[axes]=!=1,partonicResultFail["SingleFixedObservedEndpointRequired"]];
 axis=First[axes];e=request["DimensionalRegulator"];t=axis["NormalVariable"];w=axis["Variable"];
 If[axis["Endpoint"]=!=1||axis["Distance"]=!=1-w,partonicResultFail["UnitUpperEndpointRequired"]];
 If[Keys[source["Values"]]=!=Keys[prepared],partonicResultFail["OriginalProductsForEachAngularStructureRequired"]];
 realGeometry=request["RealPhaseSpace"];scalarGeometry=request["ScalarIntegration"];
 rules={w->1-t};assum=Lookup[request,"Assumptions",True]/.w->1;
 conditions=<|"NoInteriorSingularities"->True,"UniformEpsilonExpansionOnCompactSubsets"->True,"RepresentationValidOnHalfOpenInterval"->True|>;
 path=Lookup[request,"WorkDirectory",None];
 Do[
  Print["ENDPOINT CERTIFICATE ",name];
  {seconds,certificate}=facetElapsedTiming[FeynFacet`CertifyOrdinaryPrescriptionRemoval[prepared[name],Automatic,<|
   "DimensionalRegulator"->e,"ExternalKinematicConditions"->realGeometry["Assumptions"],
   "AngularEndpointDomain"-><|"Variable"->t,"CoordinateRules"->rules,"Assumptions"->assum,
    "TangentialVariables"->DeleteDuplicates[Append[DeleteCases[request["Variables"],w],request["Scale"]]],
    "TimeDirection"->scalarGeometry["TimelikeMomentum"]|>|>]];
  If[!AssociationQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"EndpointDistributions"]=!=True,
   partonicResultFail["UniformRealEndpointPrescriptionProofRequired",<|"Structure"->name,"Cause"->certificate|>]];
  AssociateTo[certificates,name->certificate];AssociateTo[timings,name<>"Certificate"->seconds];
  Print["EXPANDING ANGULAR ENDPOINT ",name];
  {seconds,expansion}=facetElapsedTiming[FeynFacet`WithEpsilonRemainderChecks[
   data=FeynFacet`ConstructAngularEndpointExpansion[source["Values"][name]/.rules,<|
    "DimensionalRegulator"->e,"Variable"->t,"Assumptions"->assum,"ThroughOrder"->Last[request["EpsilonRange"]],
    "EndpointConditions"->conditions,"PrintTimings"->True|>];
   If[AssociationQ[data],FeynFacet`ExtractEndpointDistributions[data,<|"ThroughOrder"->Last[request["EpsilonRange"]]|>],data]]];
  If[!AssociationQ[expansion]||!AssociationQ[Lookup[expansion,"Result",None]]||
   expansion["EpsilonRemainderAudit"]["Status"]=!="Passed",
   partonicResultFail["ExplicitAngularEndpointExpansionRequired",<|"Structure"->name,"Cause"->expansion|>]];
  If[StringQ[path],FeynFacet`FamilyArtifactWrite[expansion,path<>"/Endpoint-"<>name<>".wl",Compression->Automatic]];
  AssociateTo[expansions,name->expansion];AssociateTo[timings,name<>"EndpointExpansion"->seconds];
  Print["EXTRACTED ENDPOINT ",name," SECONDS ",seconds," BYTES ",ByteCount[expansion]];
  value=FeynFacet`CreatePartonicResultFromEndpointExpansion[expansion["Result"],
   Join[request,<|"Contribution"->"Real","StructureFunctions"->{name}|>]];
  If[!AssociationQ[value],partonicResultFail["ExplicitFixedObservedRealResultRequired",<|"Cause"->value|>]];
  Print["CONVERTED PARTONIC RESULT ",name," BYTES ",ByteCount[value]];
  AppendTo[rows,value],{name,Keys[source["Values"]]}];
 coefficients=partonicDistributionVector[Lookup[rows,"Coefficients"]];
 coefficients=Association@Table[k->Lookup[coefficients,k,partonicDistributionZero[1]],
  {k,Min[First[request["EpsilonRange"]],Min[Keys[coefficients]]],Max[Keys[coefficients]]}];
 result=FeynFacet`CreatePartonicResult[coefficients,Join[request,<|"Contribution"->"Real",
  "StructureFunctions"->Keys[source["Values"]],"OrdinaryPrescriptionCertificates"->certificates,
  "EndpointOrderRequirements"->Map[#["Result"]["OrderRequirements"]&,expansions],"StageSeconds"->timings|>]];
 result
],"PartonicResults"];
End[];EndPackage[];
