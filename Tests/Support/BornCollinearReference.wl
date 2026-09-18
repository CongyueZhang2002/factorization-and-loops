(* Independent Born-only collinear reference retained for validation.
   Production invariant convolutions use ApplyCountertermDistribution. *)
BeginPackage["FTBornCollinearReference`"];
ConvolveBornCollinearKernel::usage="ConvolveBornCollinearKernel[born,kernel,request] acts on the invariant Born density b(s,t,u;epsilon) delta(s+t+u). Born is a common LO PartonicResult with explicit epsilon coefficients and MandelstamVariables. Request declares Leg (IncomingA, IncomingB, or Observed), Scale s, Variables {v,w}. It returns exact delta/plus/regular coefficients on 0<w<=1, with the complete D-dimensional FF Jacobian.";
Begin["`Private`"];
ClearAll[bornReferenceFail,bornReferenceKernelValidate,bornReferenceMap,bornReferenceInvariantCoefficient];
bornReferenceFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"BornCollinearReference"];
bornReferenceKernelValidate[k_]:=Module[{x,plus},
 If[!AssociationQ[k]||!ContainsAll[Keys[k],{"Variable","DeltaCoefficient","PlusCoefficients","RegularCoefficient"}],
  bornReferenceFail["SplittingKernelDecompositionRequired"]];
 x=k["Variable"];plus=k["PlusCoefficients"];
 If[!MatchQ[x,_Symbol]||!AssociationQ[plus]||!AllTrue[Keys[plus],IntegerQ[#]&&#>=0&]||
  !FreeQ[{k["DeltaCoefficient"],Values[plus]},x]||
  !FreeQ[KeyTake[k,{"Variable","DeltaCoefficient","PlusCoefficients","RegularCoefficient"}],
    _Real|_SeriesData|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity],
  bornReferenceFail["ExplicitCollinearKernelRequired"]];k
];
bornReferenceMap[leg_,s_,v_,w_,e_]:=Switch[leg,
 "IncomingA",<|"Fraction"->w,"Invariants"->{w s,w s(v-1),-s v w},"ConstraintJacobian"->1/(s v),"MeasureWeight"->1|>,
 "IncomingB",With[{xi=(1-v)/(1-v w)},<|"Fraction"->xi,"Invariants"->{xi s,s(v-1),-xi s v w},"ConstraintJacobian"->1/(s(1-v w)),"MeasureWeight"->1|>],
 "Observed",With[{xi=1-v+v w},<|"Fraction"->xi,"Invariants"->{s,s(v-1)/xi,-s v w/xi},"ConstraintJacobian"->xi/s,"MeasureWeight"->xi^(-2+2e)|>],
 _,bornReferenceFail["CollinearLegUnsupported",<|"Leg"->leg|>]];
(* Reconstruct the invariant coefficient needed by the physical convolution.
   This is a kinematic substitution and its delta Jacobian, not a file-format adapter. *)
bornReferenceInvariantCoefficient[born_Association,upper_Integer]:=Module[{check,e,s,v,w,mandel,delta},
 check=FeynFacet`RequirePartonicEpsilonRange[born,{0,upper}];
 If[FailureQ[check],bornReferenceFail["BornEpsilonOrdersInsufficient",<|"Cause"->check|>]];
 If[born["Order"]=!="LO"||!AllTrue[Values[born["Coefficients"]],
  #["RegularCoefficient"]===0&&AllTrue[Values[#["PlusCoefficients"]],#===0&]&],
  bornReferenceFail["BornDeltaResultRequired"]];
 e=born["DimensionalRegulator"];s=born["Scale"];{v,w}=born["Variables"];mandel=born["MandelstamVariables"];
 delta=Sum[born["Coefficients"][j]["DeltaCoefficient"]e^j,{j,0,upper}];
 (s v delta)/.Thread[{s,v}->{mandel[[1]],1+mandel[[2]]/mandel[[1]]}]
];


ConvolveBornCollinearKernel[born_Association,kernel_Association,request_Association]:=Catch[Module[
 {k,xi,e,mandel,s,v,w,leg,map,h,ratio,slope,weight,endpointWeight,
  delta,plus=<||>,regular,coeff,atEndpoint,power,j,bornExpression,assumptions,endpointData},
 k=bornReferenceKernelValidate[kernel];xi=k["Variable"];
 If[!ContainsAll[Keys[born],{"Coefficients","EpsilonRange","MandelstamVariables","DimensionalRegulator"}]||
   !ContainsAll[Keys[request],{"Leg","Scale","Variables"}],bornReferenceFail["BornDensityAndCollinearRequestRequired"]];
 e=born["DimensionalRegulator"];mandel=born["MandelstamVariables"];
 s=request["Scale"];{v,w}=request["Variables"];leg=request["Leg"];
 If[!MatchQ[mandel,{_Symbol,_Symbol,_Symbol}]||!MatchQ[{e,s,v,w,xi},{_Symbol..}]||
  !DuplicateFreeQ[mandel]||!DuplicateFreeQ[{e,s,v,w,xi}],bornReferenceFail["DistinctKinematicVariablesRequired"]];
 bornExpression=bornReferenceInvariantCoefficient[born,Lookup[request,"BornThroughOrder",Last[born["EpsilonRange"]]]];
 If[!FreeQ[bornExpression,v|w|xi],bornReferenceFail["BornCoefficientUsesOutputCoordinates"]];
 If[!FreeQ[bornExpression,_SeriesData|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity|_Real],
  bornReferenceFail["ExactBornCoefficientRequired"]];
 assumptions=0<v<1&&0<w<1&&s>0;
 map=bornReferenceMap[leg,s,v,w,e];h=map["Fraction"];
 ratio=Cancel[(1-h)/(1-w)];slope=Cancel[D[h,w]/.w->1];
 If[!TrueQ[FullSimplify[0<slope<Infinity,0<v<1]],bornReferenceFail["NondegenerateCollinearEndpointRequired"]];
 weight=map["ConstraintJacobian"]map["MeasureWeight"](bornExpression/.Thread[mandel->map["Invariants"]]);
 endpointData={weight,D[weight,w]}/.w->1;
 If[!FreeQ[endpointData,Indeterminate|_DirectedInfinity|Power[0,_]|_ConditionalExpression],bornReferenceFail["SmoothBornEndpointRequired"]];
 endpointWeight=Cancel[(weight/.w->1)/slope];
 If[!FreeQ[endpointWeight,Indeterminate|_DirectedInfinity],bornReferenceFail["RegularBornEndpointRequired"]];
 delta=endpointWeight k["DeltaCoefficient"];
 regular=weight(k["RegularCoefficient"]/.xi->h);
 KeyValueMap[Function[{logPower,kernelCoefficient},
  delta+=kernelCoefficient endpointWeight Log[slope]^(logPower+1)/(logPower+1);
  Do[
   coeff=kernelCoefficient Binomial[logPower,j] weight/ratio If[logPower===j,1,Log[ratio]^(logPower-j)];
   atEndpoint=kernelCoefficient Binomial[logPower,j] endpointWeight If[logPower===j,1,Log[slope]^(logPower-j)];
   AssociateTo[plus,j->(Lookup[plus,j,0]+atEndpoint)];
   regular+=(coeff-atEndpoint)Log[1-w]^j/(1-w),{j,0,logPower}]],k["PlusCoefficients"]];
 <|"Variable"->w,"Endpoint"->1,"Domain"->assumptions,"DimensionalRegulator"->e,
  "DeltaCoefficient"->delta,"PlusCoefficients"->plus,"RegularCoefficient"->regular,
  "CollinearMap"->map,"DensityConvention"->"E_c d sigma / d^(D-1) p_c",
  "BornSupport"->"delta(s+t+u)","KernelDirection"->"daughter <- parent",
  "PlusConvention"->"[Log[1-w]^k/(1-w)]_+ on [0,1]; other endpoint excluded"|>
 ],"BornCollinearReference"];
End[];EndPackage[];
