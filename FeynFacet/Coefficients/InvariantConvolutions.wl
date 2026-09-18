(* Physical collinear actions on an invariant single-inclusive density.
   Rational charts put every singular source argument in the form w/q.
   The physical kernel and Jacobian are pulled back together, including
   their finite endpoint delta term. Regular remainders use subtracted
   one-dimensional integrals and the common explicit GPL backend.
   This is the same action for Born, real, virtual and already-subtracted
   sources. No lower-order process formula is used. *)
BeginPackage["FeynFacet`"];
ConvolvePartonicInvariantKernel::usage="ConvolvePartonicInvariantKernel[source,kernel,request] convolves a common invariant single-inclusive Laurent density with an explicit PDF or FF kernel. Request gives Leg,Scale,Variables and EpsilonRange. Arbitrary delta/plus/regular sources, including poles and positive epsilon coefficients, use the exact invariant rescaling and dimensional FF measure. Output coefficients are explicit functions.";
ConvolvePartonicMappedKernel::usage="ConvolvePartonicMappedKernel[source,kernel,request] applies a PDF/FF convolution in a monotone fraction chart produced by ConstructCollinearMomentumMap. The source endpoint argument maps to w/q; the operator-derived measure and its epsilon dependence use the common sufficient-order audit.";
Begin["`Private`"];
invariantLogPower[x_,0]:=1;
invariantLogPower[x_,n_Integer?Positive]:=Log[x]^n;
invariantEndpointValue[f_,x_]:=Module[{value=Cancel[f/.x->1]},
 If[!FreeQ[value,Indeterminate|_DirectedInfinity],
  collinearKernelFail["SmoothCollinearEndpointCoefficientRequired",<|"Coefficient"->Short[f]|>]];
 value
];
(* Pull back the physical kernel together with its Jacobian. Weight is
   q omega(q) f(S(q),V(q)); its endpoint is the external source coefficient.
   The finite delta shift follows from (sigma^lambda-1)/lambda. *)
invariantMappedKernel[kernel_,weight_,chi_,q_]:=Module[
 {jacobian=D[chi,q],ratio=Cancel[(1-chi)/(1-q)],sigma,g,f0,
  delta,plus=<||>,regular,c,c0},
 sigma=Cancel[D[chi,q]/.q->1];g=Cancel[jacobian/ratio];
 f0=invariantEndpointValue[weight,q];
 delta=f0 kernel["DeltaCoefficient"];
 regular=weight jacobian (kernel["RegularCoefficient"]/.kernel["Variable"]->chi);
 KeyValueMap[Function[{j,a},
  delta+=a f0 invariantLogPower[sigma,j+1]/(j+1);
  Do[
   c=a Binomial[j,k]weight g invariantLogPower[ratio,j-k];
   c0=a Binomial[j,k]f0 invariantLogPower[sigma,j-k];
   AssociateTo[plus,k->(Lookup[plus,k,0]+c0)];
   regular+=(c-c0)invariantLogPower[1-q,k]/(1-q),{k,0,j}]
 ],kernel["PlusCoefficients"]];
 Join[partonicDistribution[delta,plus,regular],<|"Variable"->q|>]
];
invariantExplicitFunctionQ[value_]:=FreeQ[value,
 _Integrate|_NIntegrate|_Inactive|_Limit|_Sum|_Product|_Derivative|_ConditionalExpression|_Failure|_Missing|_SeriesData|
 $Failed|$Aborted|Indeterminate|_DirectedInfinity];
(* Both halves start at the physical endpoints and end at their common
   midpoint. GPL primitives are therefore never evaluated at a divergent
   upper endpoint and no independently discarded endpoint infinities occur. *)
invariantFiniteIntegral[body_,xi_,h_,assumptions_]:=
 invariantFiniteIntegral[body,xi,h,assumptions]=Module[
 {f=body,answer,z=Unique["collinearParameter"],half,parts},
 If[f===0,Return[0]];
 If[FreeQ[f,xi],Return[(1-h)f]];
 (* Preserve the sparse rational/logarithmic sum. A common denominator
    expands every transcendental coefficient and can dominate this step.
    The GPL engine performs Hermite reduction word by word instead. *)
 answer=If[LeafCount[f]>3000,$Failed,TimeConstrained[Quiet[Integrate[f,{xi,h,1},
   Assumptions->assumptions,GenerateConditions->False]],3,$Failed]];
 If[invariantExplicitFunctionQ[answer],Return[answer]];
 If[DownValues[FeynFacetSolution`IntegrateGPL]==={},
  Block[{$ContextPath=$ContextPath},Get[FileNameJoin[{$feynFacetDirectory,"Solution.m"}]]]];
 half=(1-h)/2;
 parts={f/.xi->h+z,f/.xi->1-z};
 answer=FeynFacetSolution`IntegrateGPL[#,{z,0,half},"TimeLimit"->60,"Assumptions"->assumptions]&/@parts;
 If[!AllTrue[answer,invariantExplicitFunctionQ],
  collinearKernelFail["ExplicitInvariantConvolutionIntegralRequired",
   <|"Cause"->answer,"Integrand"->Short[f],"Interval"->{h,1}|>]];
 Total[answer]
];
invariantUnitMellinPlus[i_,j_,h_]:=invariantUnitMellinPlus[i,j,h]=Module[{a},
 a=FeynFacet`MellinConvolveDistributions[
  partonicDistribution[0,<|i->1|>,0],partonicDistribution[0,<|j->1|>,0],h];
 If[!AssociationQ[a],collinearKernelFail["EndpointMellinProductFailed",<|"Cause"->a|>]];
 KeyTake[a,{"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]
];
invariantConvolveKernelPlus[kernel_,i_,w_,q_,assumptions_]:=Module[
 {out={partonicDistribution[0,<|i->kernel["DeltaCoefficient"]|>,0]},
  regular=0,kr=kernel["RegularCoefficient"],atLower},
 If[kr=!=0,
  atLower=kr/.q->w;
  regular=invariantFiniteIntegral[
    (kr-w atLower/q)invariantLogPower[1-w/q,i]/(q-w),q,w,assumptions]+
    atLower invariantLogPower[1-w,i+1]/(i+1)];
 KeyValueMap[Function[{j,b},If[b=!=0,
  AppendTo[out,partonicMap[Function[value,b value],invariantUnitMellinPlus[i,j,w]]]
 ]],kernel["PlusCoefficients"]];
 AppendTo[out,partonicDistribution[0,<||>,regular]];
 partonicDistributionSum[out,1]
];
invariantApplyRegularSource[body_,kernel_,lower_,xi_,assumptions_]:=Module[
 {endpoint=body/.xi->1,kr=kernel["RegularCoefficient"]/.kernel["Variable"]->xi,answer},
 answer=kernel["DeltaCoefficient"]endpoint;
 If[kr=!=0,answer+=invariantFiniteIntegral[kr body,xi,lower,assumptions]];
 KeyValueMap[Function[{j,b},If[b=!=0,
  answer+=b(invariantFiniteIntegral[
    invariantLogPower[1-xi,j](body-endpoint)/(1-xi),xi,lower,assumptions]+
    endpoint invariantLogPower[1-lower,j+1]/(j+1))
 ]],kernel["PlusCoefficients"]];
 answer
];
invariantConvolutionChart[source_,request_,xi_]:=Module[
 {map,variable,chi,w=Last[source["Variables"]],s,v,e=source["DimensionalRegulator"],r,leg,conditions,
   expected,endpointRules,regularRules,derivation,geometry,generated,pa=collinearBeamA,pb=collinearBeamB,k=collinearObservedMomentum},
 If[KeyExistsQ[request,"CollinearMap"],
  map=request["CollinearMap"];
   If[!AssociationQ[map]||!ContainsAll[Keys[map],{"Variable","Fraction","EndpointRules","RegularRules",
      "LowerFraction","EndpointMeasure","RegularMeasure"}],collinearKernelFail["ExplicitCollinearRescalingMapRequired"]];
   derivation=Lookup[map,"Derivation",<||>];
   If[!ContainsAll[Keys[derivation],{"Geometry","LegDefinition"}],collinearKernelFail["OperatorAndMomentumDerivedCollinearMapRequired"]];
   generated=FeynFacet`ConstructCollinearMomentumMap[derivation["Geometry"],derivation["LegDefinition"]];
   If[!AssociationQ[generated]||KeyTake[map,Keys[generated]]=!=generated,
    collinearKernelFail["CollinearMapDisagreesWithItsPhysicalDefinition"]];
  variable=map["Variable"];
  If[!MatchQ[variable,_Symbol]||MemberQ[source["Variables"],variable]||variable===e,
   collinearKernelFail["IndependentCollinearIntegrationVariableRequired"]];
  map=KeyDrop[map,"Variable"]/.variable->xi;
  chi=map["Fraction"];endpointRules=map["EndpointRules"];regularRules=map["RegularRules"];
  conditions=Lookup[request,"Assumptions",True]&&0<xi<1;
  If[!MatchQ[endpointRules,{_Rule...}]||!MatchQ[regularRules,{_Rule...}]||
    !TrueQ[FullSimplify[(chi/.xi->1)==1&&D[chi,xi]>0&&map["LowerFraction"]==(chi/.xi->w)&&
      ((w/.regularRules)/.xi->chi)==w/xi&&
      And@@Thread[(Prepend[source["Variables"],source["Scale"]]/.regularRules/.xi->1)==
        Prepend[source["Variables"],source["Scale"]]],Assumptions->conditions]],
   collinearKernelFail["MonotoneEndpointPreservingCollinearChartRequired"]];
  expected=(DeleteCases[source["Variables"],w]/.regularRules)/.xi->chi;
  If[!TrueQ[FullSimplify[And@@Thread[expected==(DeleteCases[source["Variables"],w]/.endpointRules)]&&
    map["EndpointMeasure"]==(map["RegularMeasure"]/.xi->chi),Assumptions->conditions]],
   collinearKernelFail["ConsistentSourceRescalingAndPhysicalMeasureRequired"]];
  Return[Join[map,<|"Assumptions"->Lookup[request,"Assumptions",True]|>]]];
  {s,{v,w}}=Lookup[source,{"Scale","Variables"}];leg=request["Leg"];
  geometry=<|"Coordinates"->{s,v,w},"EndpointVariable"->w,"DimensionalRegulator"->e,
   "ExternalMomenta"->{pa,pb,k},"KinematicRules"->{FeynCalc`SPD[pa]->0,FeynCalc`SPD[pb]->0,FeynCalc`SPD[k]->0,
     FeynCalc`SPD[pa,pb]->s/2,FeynCalc`SPD[pa,k]->s(1-v)/2,FeynCalc`SPD[pb,k]->s v w/2},
   "DensityPrefactor"->1/FeynFacet`LorentzInvariantIncidentFlux[s,0,0,s>0],
   "Assumptions"->s>0&&0<v<1&&0<w<1&&Lookup[request,"Assumptions",True]|>;
  generated=FeynFacet`ConstructCollinearMomentumMap[geometry,<|"Role"->If[leg==="Observed","FF","PDF"],
   "Momentum"->Switch[leg,"IncomingA",pa,"IncomingB",pb,"Observed",k],"Variable"->collinearChartFraction|>];
  If[!AssociationQ[generated],collinearKernelFail["InvariantConvolutionMapDerivationFailed",<|"Cause"->generated|>]];
  invariantConvolutionChart[source,Join[request,<|"CollinearMap"->generated,"Assumptions"->geometry["Assumptions"]|>],xi]
];

invariantScalarConvolution[source_,kernel_,request_]:=Module[
 {s,v,w,e,leg,range,xi=Unique["collinearFraction"],r,chi,
  mappedScale,mappedAngle,lowerFraction,directScale,directAngle,directVariable,
  assumptions,lower,sourceLower,needed,upper,kvalues,kseries,krow,sourceRows,
  weighted=<||>,rows=<||>,out,coeff,weight,d,plus,regular,part,n,a,b,
  mapped,endpointTerms,chart,endpointRules,regularRules,endpointMeasure,regularMeasure},
 e=source["DimensionalRegulator"];w=Last[source["Variables"]];
 range=request["EpsilonRange"];chart=invariantConvolutionChart[source,request,xi];
 lower=partonicKernelValuation[kernel,e];sourceLower=source["LaurentLowerBound"];
 If[lower===Infinity,Return[MultiplyPartonicLaurentFactor[source,0,range]]];
 needed=Last[range]-lower;upper=Last[range]-sourceLower;
 If[needed>=sourceLower&&FailureQ[RequirePartonicEpsilonRange[source,{sourceLower,needed}]],
  collinearKernelFail["InvariantConvolutionEpsilonOrdersInsufficient",
   <|"RequiredThroughOrder"->needed,"Available"->source["EpsilonRange"]|>]];
 (* xi denotes q in the Mellin representation and the physical fraction
    in the separate regular-source integral. Both integrations are local.
    In each Mellin chart the third source argument is exactly w/q. *)
 {chi,lowerFraction,endpointRules,regularRules,endpointMeasure,regularMeasure,assumptions}=
  Lookup[chart,{"Fraction","LowerFraction","EndpointRules","RegularRules","EndpointMeasure","RegularMeasure","Assumptions"}];
 epsilonAuditProduct[{
  <|"Source"->"PartonicCoefficients","LowerBound"->sourceLower,"ThroughOrder"->needed|>,
  <|"Source"->"CollinearKernel","LowerBound"->lower,"ThroughOrder"->upper|>,
  <|"Source"->"DimensionalCollinearMeasure","LowerBound"->0,"Exact"->True|>},
  Last[range],"InvariantCollinearConvolution"];
 sourceRows=Association@Table[n->With[{row=source["Coefficients"][n]},
  partonicDistribution[
   row["DeltaCoefficient"]/.endpointRules,
   Map[#/.endpointRules&,row["PlusCoefficients"]],
   row["RegularCoefficient"]/.regularRules]],
  {n,sourceLower,needed}];
 Do[
  d=0;plus=<||>;regular=0;
  Do[
   coeff=sourceRows[n-a];
   weight=xi FullSimplify[SeriesCoefficient[endpointMeasure,{e,0,a}],Assumptions->assumptions&&0<xi<1];
   If[weight===0,Continue[]];
   d+=weight coeff["DeltaCoefficient"];
   KeyValueMap[AssociateTo[plus,#1->(Lookup[plus,#1,0]+weight #2)]&,coeff["PlusCoefficients"]];
   regular+=FullSimplify[SeriesCoefficient[regularMeasure,{e,0,a}],Assumptions->assumptions&&0<xi<1]coeff["RegularCoefficient"],
   {a,0,n-sourceLower}];
  AssociateTo[weighted,n->partonicDistribution[Cancel[d],Cancel/@plus,regular]],
 {n,sourceLower,needed}];
 kvalues=Join[{kernel["DeltaCoefficient"],kernel["RegularCoefficient"]},Values[kernel["PlusCoefficients"]]];
 kseries=partonicLaurentScalarCoefficients[#,e,lower,upper]&/@kvalues;
 Do[
  krow=Join[partonicDistribution[kseries[[1]][b],
   AssociationThread[Keys[kernel["PlusCoefficients"]],#[b]&/@Drop[kseries,2]],
   kseries[[2]][b]],<|"Variable"->kernel["Variable"]|>];
  If[partonicZeroTreeQ[KeyDrop[krow,"Variable"]],Continue[]];
  Do[n=a+b;If[n<First[range]||n>Last[range],Continue[]];
   coeff=weighted[a];endpointTerms={};
   If[coeff["DeltaCoefficient"]=!=0,
    mapped=invariantMappedKernel[krow,coeff["DeltaCoefficient"],chi,xi];
    AppendTo[endpointTerms,KeyTake[mapped,
      {"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]/.xi->w]];
   KeyValueMap[Function[{i,f},If[f=!=0,
    mapped=invariantMappedKernel[krow,f,chi,xi];
    AppendTo[endpointTerms,invariantConvolveKernelPlus[mapped,i,w,xi,assumptions]]
   ]],coeff["PlusCoefficients"]];
   If[coeff["RegularCoefficient"]=!=0,
    AppendTo[endpointTerms,partonicDistribution[0,<||>,invariantApplyRegularSource[
     coeff["RegularCoefficient"],krow,lowerFraction,xi,assumptions]]]];
   part=partonicDistributionSum[endpointTerms,1];
   AssociateTo[rows,n->Append[Lookup[rows,n,{}],part]],
   {a,sourceLower,Min[needed,Last[range]-b]}],
 {b,lower,upper}];
 out=Association@Table[n->partonicDistributionSum[Lookup[rows,n,{}],1],
  {n,First[range],Last[range]}];
 out=Map[partonicMap[Function[value,FeynFacet`ExpandPositiveLogarithms[
   value,assumptions]],#]&,out];
 If[!FreeQ[out,xi]||!invariantExplicitFunctionQ[out],
  collinearKernelFail["ExplicitParameterFreeConvolutionResultRequired"]];
 CreatePartonicResult[out,partonicLaurentProductMetadata[source]]
];
ConvolvePartonicInvariantKernel[source_Association,kernel_Association,request_Association]:=
 convolvePartonicKinematicKernel[source,kernel,request];
ConvolvePartonicMappedKernel[source_Association,kernel_Association,request_Association]:=
 If[KeyExistsQ[request,"CollinearMap"],convolvePartonicKinematicKernel[source,kernel,request],
 Failure["ExplicitCollinearRescalingMapRequired",<||>]];
convolvePartonicKinematicKernel[source_Association,kernel_Association,request_Association]:=
 Catch[Internal`InheritedBlock[{invariantFiniteIntegral,invariantUnitMellinPlus},
 Module[{leg,range,e,variables,axes,values,sizes,n,component,answers,rows},
 {leg,range}=Lookup[request,{"Leg","EpsilonRange"},None];
 e=Lookup[source,"DimensionalRegulator",None];variables=Lookup[source,"Variables",None];
 axes=With[{basis=Lookup[source,"DistributionBasis",<||>]},Lookup[basis,"Axes",{basis}]];
 If[(!KeyExistsQ[request,"CollinearMap"]&&!MemberQ[{"IncomingA","IncomingB","Observed"},leg])||
   !MatchQ[range,{_Integer,_Integer}]||First[range]>Last[range]||
   !MatchQ[variables,{__Symbol}]||(!KeyExistsQ[request,"CollinearMap"]&&Length[variables]=!=2)||Length[axes]=!=1||
   axes[[1]]["Variable"]=!=Last[variables]||
   axes[[1]]["Endpoint"]=!=1||axes[[1]]["Interval"]=!={0,1}||
   Lookup[request,"Scale",None]=!=Lookup[source,"Scale",None]||
   Lookup[request,"Variables",None]=!=variables||
   !FreeQ[{kernel["DeltaCoefficient"],kernel["PlusCoefficients"]},Alternatives@@variables],
  collinearKernelFail["InvariantSingleInclusiveConvolutionRequestRequired"]];
 collinearKernelValidate[kernel];
 If[KeyExistsQ[request,"CollinearMap"],invariantConvolutionChart[source,request,Unique["collinearMapCheck$"]]];
 If[FailureQ[RequirePartonicEpsilonRange[source,source["EpsilonRange"]]],
  collinearKernelFail["CompleteInvariantPartonicSourceRequired"]];
 (* Every declared map and its physical weight are the identity at xi=1.
    A delta-only kernel is exactly a scalar Laurent product, also for vectors. *)
 If[kernel["RegularCoefficient"]===0&&AllTrue[Values[kernel["PlusCoefficients"]],#===0&],
  Return[FeynFacet`MultiplyPartonicLaurentFactor[source,kernel["DeltaCoefficient"],range]]];
 values=Flatten[Table[With[{r=source["Coefficients"][i]},
   Join[{r["DeltaCoefficient"],r["RegularCoefficient"]},Values[r["PlusCoefficients"]]]],
  {i,First[source["EpsilonRange"]],Last[source["EpsilonRange"]]}],1];
 sizes=DeleteDuplicates[Length/@Select[values,ListQ]];
 If[sizes==={},Return[invariantScalarConvolution[source,kernel,request]]];
 If[Length[sizes]=!=1||!AllTrue[values,ListQ[#]||#===0&],
  collinearKernelFail["MatchingStructureFunctionVectorsRequired"]];
 n=First[sizes];
 answers=Table[
  component=CreatePartonicResult[
   Map[partonicMap[Function[value,If[ListQ[value],value[[j]],0]],#]&,source["Coefficients"]],
   Join[partonicLaurentProductMetadata[source],<|"StructureFunctions"->{source["StructureFunctions"][[j]]}|>]];
  If[!AssociationQ[component],collinearKernelFail["ScalarStructureFunctionProjectionFailed",<|"Cause"->component|>]];
  invariantScalarConvolution[component,kernel,request],{j,n}];
 If[AnyTrue[answers,FailureQ],Return[SelectFirst[answers,FailureQ]]];
 rows=Association@Table[i->partonicDistributionVector[#["Coefficients"][i]&/@answers],
  {i,First[range],Last[range]}];
 CreatePartonicResult[rows,partonicLaurentProductMetadata[source]]
 ]],"CollinearCounterterms"];
End[];EndPackage[];
