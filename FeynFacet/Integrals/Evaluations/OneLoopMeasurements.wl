(* One remaining energy integral after a three-body measurement. Its regulated
   endpoint powers must permit coefficientwise integration before using GPLs. *)
BeginPackage["FeynFacet`"];
ResolveOneLoopMeasurementIntegrationEndpoints::usage="ResolveOneLoopMeasurementIntegrationEndpoints[density] resolves both ends of the remaining one-dimensional integration in a ConstructOneLoopMeasurementDensity record, at fixed interior measurement. It establishes coefficientwise integration only when every exact regulated term has an integrable integer endpoint power. It does not establish measurement-variable endpoint distributions.";
IntegrateOneLoopMeasurementInterior::usage="IntegrateOneLoopMeasurementInterior[density,range,request] derives integrable regulated energy endpoints, expands the complete scalar density through sufficient orders, and integrates its Laurent coefficients as explicit GPLs. The measurement variable remains on its open domain; no measurement endpoint contact is inferred. ConjugateInterference -> True adds the conjugate of each scalar Laurent coefficient on verified branches before GPL integration. Request may set additional Assumptions, ComplexParameters, GPL TimeLimit and MaxExpressionLeaves.";
Begin["`Private`"];
oneLoopMeasurementValues[branch_Association]:=Map[Function[row,
 Total[KeyValueMap[#2 If[#1===1,1,branch["ScalarFunctions"][#1]]&,row]]*
 Times@@(Power@@#&/@branch["RegulatorFactors"])],branch["Coefficients"]];
ResolveOneLoopMeasurementIntegrationEndpoints[density_Association]:=Catch[Module[
 {e,x,normal=Unique["integrationEndpoint"],records={},values,conditions,resolved,powers,parameters,regularity,mapping},
 If[Lookup[density,"Format",None]=!="FeynFacet-OneLoopMeasurementDensity"||
   !TrueQ[Lookup[density,"ExactInRegulator",False]]||!TrueQ[density["PhaseSpaceDensityIncluded"]],
  cutFamilyFail["ExactMeasuredScalarLoopDensityRequired"]];
 {e,x}=Lookup[density,{"DimensionalRegulator","IntegrationVariable"}];
 Do[
  If[!FreeQ[branch["Prefactor"],x],cutFamilyFail["ExternalLoopMeasurementPrefactorRequired"]];
  If[!TrueQ[Lookup[branch,"ExternalFactorModulusBoundsEstablished",False]]||
    !AssociationQ[Lookup[branch,"ExternalPrescriptionComponents",None]],
   cutFamilyFail["PrescribedExternalProductDecompositionRequired"]];
  (* Bound each originally prescribed external product separately. A
     cancellation between different products after eta->0 would not supply
     a uniform bound for the prescribed product before that limit. *)
  values=Map[#["ScalarCoefficient"]#["InteriorExternalProduct"]*
    Times@@(Power@@#&/@branch["RegulatorFactors"])&,branch["ExternalPrescriptionComponents"]];
  parameters=branch["PhysicalDomain"]/.x->1/2;
  If[!FreeQ[parameters,x|normal]||
    !TrueQ[FullSimplify[Implies[parameters&&0<x<1,branch["PhysicalDomain"]]]],
   cutFamilyFail["WholeUnitEnergyIntervalRequired"]];
  Do[
   mapping=x->If[endpoint===0,normal/2,1-normal/2];
   conditions=parameters&&0<normal<1/4;
   resolved=FeynFacet`ResolveOneLoopScalarEndpointPowers[
     Map[(#/.mapping)/2&,values],e,{normal},conditions];
   If[!AssociationQ[resolved],cutFamilyFail["MeasuredLoopIntegrationEndpointResolutionFailed",<|"Endpoint"->endpoint,"Cause"->resolved|>]];
   powers=Flatten[Lookup[resolved["Terms"],"Powers"]]/.e->0;
   If[!VectorQ[powers,IntegerQ[#]&&#>=0&],
    cutFamilyFail["RegulatedEnergyEndpointSubtractionRequired",<|"Endpoint"->endpoint,"IntegerPowers"->powers,"Resolved"->resolved|>]];
   regularity=FeynFacet`VerifyResolvedEndpointCube[resolved,parameters];
   If[!AssociationQ[regularity],cutFamilyFail["UniformMeasuredEnergyIntervalNotEstablished",
     <|"Endpoint"->endpoint,"Cause"->regularity|>]];
   AppendTo[records,<|"Branch"->index,"Endpoint"->endpoint,"Resolved"->resolved,
     "CoordinateSubstitution"->mapping,"AbsoluteJacobian"->1/2,
     "UniformFactorVerification"->regularity,"IntegerPowers"->powers|>],{endpoint,{0,1}}],
 {index,Length[density["Branches"]]},{branch,{density["Branches"][[index]]}}];
 <|"Format"->"FeynFacet-MeasuredLoopIntegrationEndpoints","Endpoints"->records,
  "IntegrationVariable"->x,"DimensionalRegulator"->e,
  "WholeEnergyIntervalVerified"->True,
  "LaurentExpansionUnderIntegralEstablished"->True,"MeasurementEndpointDistributionsEstablished"->False,
  "ExternalPrescriptionLimitEstablished"->True,
  "ExternalPrescriptionArgument"->"Each original external factor has a real nonzero core on the open domain, positive integer power and eta=+1 or -1. The bound |(g+i eta delta)^(-n)| <= |g|^(-n) holds for delta>0. Every prescribed-product component, with its causal scalar-loop kernel, has separately verified integrable endpoint powers. Dominated convergence therefore removes those external prescriptions under this fixed-measurement energy integral. Virtual loop prescriptions remain.",
  "Argument"->"The energy interval is partitioned into two half-intervals. In each, every original prescribed-product component resolves into nonnegative integer normal powers plus affine regulator corrections. Smooth factors are verified on the entire closed half-interval, including its interior, on supported real scalar branches. On compact tangential domains this gives a common integrable bound for a small regulator disk after clearing finite meromorphic poles. Measurement-variable limits are separate."|>
],"CutFamily"];
IntegrateOneLoopMeasurementInterior[density_Association,range:{_Integer,_Integer},request_Association:<||>]:=Catch[Module[
 {endpoints,e,x,values,expanded,coefficient,parts,answer,entries={},labels=None,seconds,
  timings={},domain,options,coefficients,conjugate,hermitian=Lookup[request,"ConjugateInterference",False]},
 If[!MemberQ[{True,False},hermitian]||!ListQ[Lookup[request,"ComplexParameters",{}]],
  cutFamilyFail["ExplicitMeasuredLoopConjugationRequestRequired"]];
 If[hermitian&&TrueQ[Lookup[density,"ConjugateInterferenceAdded",False]],
  cutFamilyFail["MeasuredLoopConjugateAlreadyIncluded"]];
 endpoints=FeynFacet`ResolveOneLoopMeasurementIntegrationEndpoints[density];
 If[!AssociationQ[endpoints],Throw[endpoints,"CutFamily"]];
 {e,x}=Lookup[density,{"DimensionalRegulator","IntegrationVariable"}];
 If[DownValues[FeynFacetSolution`IntegrateGPL]==={},
  Block[{$ContextPath=$ContextPath},Get[FileNameJoin[{$feynFacetDirectory,"Solution.m"}]]]];
 Do[
  domain=branch["PhysicalDomain"]&&Lookup[request,"Assumptions",True];
  values=Map[# branch["Prefactor"]&,oneLoopMeasurementValues[branch]];
  {seconds,expanded}=AbsoluteTiming[FeynFacet`ExpandOneLoopScalarFunctions[values,e,range,domain]];
  If[!AssociationQ[expanded],cutFamilyFail["MeasuredScalarLoopExpansionFailed",<|"Cause"->expanded|>]];
  AppendTo[timings,<|"Stage"->"ScalarLaurentExpansion","Seconds"->seconds|>];
  If[labels===None,labels=expanded["StructureFunctions"]];
  If[labels=!=expanded["StructureFunctions"],cutFamilyFail["CommonMeasuredLoopStructuresRequired"]];
  If[hermitian,
   conjugate=FeynFacet`ConjugateExplicitScalarFunctions[expanded["Coefficients"],domain,
     Lookup[request,"ComplexParameters",{}]];
   If[!AssociationQ[conjugate],cutFamilyFail["MeasuredScalarLoopConjugationFailed",<|"Cause"->conjugate|>]];
   (* The GPL collector combines equal words and rational coefficients.
      A global Factor here instead combines all transcendental terms over
      one large denominator before that exact cancellation can happen. *)
   expanded["Coefficients"]=Merge[{expanded["Coefficients"],conjugate},Total]];
  options=Normal@Join[<|"TimeLimit"->120,"Assumptions"->domain|>,KeyTake[request,
    {"TimeLimit","MaxExpressionLeaves","MaxTerms","MaxWeight","MaxPoleDegree","MaxEndpointExpansionOrder"}]];
  coefficients=Association@KeyValueMap[Function[{key,value},
   coefficient=value;
   If[coefficient===0,key->0,
    {seconds,parts}=AbsoluteTiming[
     FeynFacetSolution`IntegrateGPL[#,{x,0,1/2},Sequence@@options]&/@{coefficient,coefficient/.x->1-x}];
    If[!FreeQ[parts,_Failure|_Integrate|_NIntegrate|_Inactive|_Series|_SeriesData|Indeterminate|_DirectedInfinity],
     cutFamilyFail["ExplicitMeasuredLoopGPLIntegralRequired",<|"Coefficient"->key,
       "Cause"->Map[If[FailureQ[#],#,<|"IntegratedPartLeafCount"->LeafCount[#]|>]&,parts]|>]];
    AppendTo[timings,<|"Stage"->"GPLIntegration","Coefficient"->key,"Seconds"->seconds|>];
    If[TrueQ[Lookup[request,"PrintTimings",False]],Print["MEASURED LOOP GPL ",key," SECONDS ",seconds]];
    key->Total[parts]]],expanded["Coefficients"]];
  AppendTo[entries,coefficients],{branch,density["Branches"]}];
 <|"Format"->"FeynFacet-OneLoopMeasuredInterior","Coefficients"->Merge[entries,Total],
  "StructureFunctions"->labels,"DimensionalRegulator"->e,"EpsilonRange"->range,
  "Variable"->density["Variable"],"Domain"->density["MeasurementGeometry"]["Domain"],
  "IntegrationEndpointProof"->endpoints,"StageTimings"->timings,
  "ConjugateInterferenceAdded"->(hermitian||TrueQ[density["ConjugateInterferenceAdded"]]),
  "EndpointDistributionIncluded"->False,"IntegralEvaluated"->True,
  "Scope"->"Explicit fixed-interior Laurent coefficients after the remaining energy integration. Measurement-variable contacts remain separate; ConjugateInterferenceAdded records whether Hermitian completion was performed before integration."|>
],"CutFamily"];
End[];EndPackage[];
