(* Adapter from explicit Gamma/Gauss expressions to the general endpoint
   distribution engine. Coalescing angular directions are expanded before
   epsilon: the noncoincident connection coefficient fixes the delta term.
   The full interior expression supplies the regular part, including the
   analytic complement of the Gauss connection formula. *)
BeginPackage["FeynFacet`"];
ConstructAnalyticEndpointExpansion::usage="ConstructAnalyticEndpointExpansion[expression,request] constructs finite Taylor and remainder records for ExtractEndpointDistributions. Request declares DimensionalRegulator, Variable (endpoint at zero), Assumptions and ThroughOrder. Supported expressions have rational factors, meromorphic normal-independent factors and at most one massless angular Gauss function; endpoint poles deeper than z^-1 are rejected.";
Begin["`Private`"];
analyticEndpointFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"AnalyticEndpoint"];
analyticEndpointLeading[x_,e_,z_,assum_]:=Module[{parts,germ,order,coefficient,rho,arg,power,atOrigin},
 If[FreeQ[x,z],Return[{0,x}]];
 Which[
  Head[x]===Times,parts=analyticEndpointLeading[#,e,z,assum]& /@ (List@@x);{Total[First/@parts],Times@@(Last/@parts)},
  Head[x]===Power,
   power=x[[2]];If[!FreeQ[power,z],analyticEndpointFail["EndpointDependentExponentUnsupported"]];
   germ=analyticEndpointLeading[x[[1]],e,z,assum];
   If[!IntegerQ[power]&&!TrueQ[FullSimplify[Last[germ]>0,assum]],
    analyticEndpointFail["PositiveEndpointPowerBaseRequired",<|"Base"->Last[germ]|>]];
   {Expand[power First[germ]],Last[germ]^power},
  Head[x]===Hypergeometric2F1,
   If[(Expand /@ Take[List@@x,3])=!={1,1,1-e},analyticEndpointFail["AnalyticEndpointGaussParametersUnsupported"]];
   rho=Cancel[1-x[[4]]];germ=analyticEndpointLeading[rho,e,z,assum];order=First[germ];coefficient=Last[germ];
   If[!IntegerQ[order]||order<0,analyticEndpointFail["PhysicalAngularEndpointRequired"]];
   If[order>0,
    If[!TrueQ[FullSimplify[coefficient>0,assum]],analyticEndpointFail["PositiveAngularEndpointSlopeRequired"]];
    {-order(1+e),Gamma[1-e]Gamma[1+e]coefficient^(-1-e)},
    arg=FullSimplify[1-coefficient,assum];
    If[!TrueQ[FullSimplify[0<=arg<1,assum]],analyticEndpointFail["NoncoincidentAngularEndpointRequired"]];
    {0,Hypergeometric2F1[1,1,1-e,arg]}],
  True,
   If[!PolynomialQ[Numerator[Together[x]],z]||!PolynomialQ[Denominator[Together[x]],z],
    analyticEndpointFail["RationalEndpointFactorRequired",<|"Expression"->x|>]];
   (* The endpoint coordinate and dimensional regulator are independent.
      The epsilon-order API intentionally normalizes regulator aliases, so
      it must not be used for this rational valuation in the coordinate. *)
   germ=Together[x];
   order=Exponent[Numerator[germ],z,Min]-Exponent[Denominator[germ],z,Min];
   If[!IntegerQ[order],analyticEndpointFail["RationalEndpointFactorRequired",<|"Expression"->x,"Valuation"->order|>]];
   coefficient=Cancel[SeriesCoefficient[x,{z,0,order}]];
   If[!FreeQ[coefficient,z|_SeriesCoefficient|_Failure],analyticEndpointFail["ExplicitEndpointLeadingCoefficientRequired"]];
   {order,coefficient}]
];
analyticEndpointSeries[expr_,e_,lo_,high_]:=Module[{hyper,rest,valuation,n,cs,expanded=expr,poly},
 hyper=DeleteDuplicates[Cases[expr,_Hypergeometric2F1,{0,Infinity}]];
 If[Length[hyper]>1,analyticEndpointFail["OneAngularGaussFunctionPerTermRequired"]];
 If[hyper=!={},
  If[(Expand /@ Take[List@@First[hyper],3])=!={1,1,1-e},analyticEndpointFail["AnalyticGaussParametersUnsupported"]];
  rest=expr/.First[hyper]->1;valuation=FeynFacet`DetermineMeromorphicLaurentLowerBound[rest,e];
  If[!IntegerQ[valuation],analyticEndpointFail["MeromorphicAngularPrefactorRequired"]];
  n=Max[0,high-valuation];
  cs=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{1,1,1-e},Cancel[First[hyper][[4]]],e,n];
  If[!AssociationQ[cs],analyticEndpointFail["ExplicitAngularExpansionFailed"]];
  epsilonAuditMultiplier[rest,e,0,n,high,"AnalyticAngularExpansion",First[hyper]];
  expanded=expr/.First[hyper]->Total[KeyValueMap[#2 e^#1&,cs]]];
 poly=Normal[Series[expanded,{e,0,high}]];
 If[!FreeQ[poly,_Hypergeometric2F1|_SeriesData|_Series|_SeriesCoefficient|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity],
  analyticEndpointFail["ExplicitAnalyticEndpointSeriesRequired"]];
 <|"LaurentLowerBound"->lo,"KnownThroughOrder"->high,"ExactInEpsilon"->False,
  "Coefficients"->Association@Table[j->Coefficient[Expand[e^-lo poly],e,j-lo],{j,lo,high}]|>
];
analyticEndpointDomain[expression_,e_,z_,assum_]:=Module[{bases,base,order,leading,domain=assum&&0<z<1,hyper},
 bases=DeleteDuplicates[Cases[expression,Power[b_,n_Integer?Negative]/;!FreeQ[b,z]:>b,{0,Infinity}]];
 Do[order=FeynFacet`DetermineLaurentValuation[base,e];
  If[!IntegerQ[order],analyticEndpointFail["EndpointDenominatorLaurentClassRequired"]];
  leading=Cancel[SeriesCoefficient[base,{e,0,order}]];
  If[!TrueQ[FullSimplify[leading!=0,domain]],analyticEndpointFail["NoInteriorDenominatorZeroNotEstablished",<|"Denominator"->leading|>]],{base,bases}];
 bases=DeleteDuplicates[Cases[expression,Power[b_,n_]/;!IntegerQ[n]&&!FreeQ[b,z]:>b,{0,Infinity}]];
 Do[If[!TrueQ[FullSimplify[base>0,domain]],analyticEndpointFail["PositiveInteriorPowerBaseNotEstablished",<|"Base"->base|>]],{base,bases}];
 hyper=DeleteDuplicates[Cases[expression,_Hypergeometric2F1,{0,Infinity}]];
 Do[If[!TrueQ[FullSimplify[0<=Cancel[h[[4]]]<1,domain]],analyticEndpointFail["PhysicalInteriorAngularDomainNotEstablished",<|"Argument"->h[[4]]|>]],{h,hyper}];
 <|"RationalDenominatorTests"->Length[DeleteDuplicates[Cases[expression,Power[b_,n_Integer?Negative]/;!FreeQ[b,z]:>b,{0,Infinity}]]],
  "PositivePowerBaseTests"->Length[bases],"GaussArgumentTests"->Length[hyper],"Status"->"Passed"|>
];
ConstructAnalyticEndpointExpansion[expression_,request_Association]:=Catch[Module[
 {e,z,assum,high,leading,a,b,lo,taylor,regular,normalized,interior,terms,need,conditions,coalescing,domainCheck},
 If[!ContainsAll[Keys[request],{"DimensionalRegulator","Variable","Assumptions","ThroughOrder","EndpointConditions"}],analyticEndpointFail["AnalyticEndpointRequestIncomplete"]];
 {e,z,assum,high}=Lookup[request,{"DimensionalRegulator","Variable","Assumptions","ThroughOrder"}];
 If[!MatchQ[{e,z},{_Symbol,_Symbol}]||e===z||!IntegerQ[high]||!FreeQ[assum,e|z],analyticEndpointFail["AnalyticEndpointVariablesRequired"]];
 coalescing=coefficientEndpointCoalescingDivisors[expression/.h_Hypergeometric2F1->1,z,e];
 If[coalescing=!={},analyticEndpointFail["JointEndpointRegulatorDenominatorUnsupported",<|"Divisors"->coalescing|>]];
 domainCheck=analyticEndpointDomain[expression,e,z,assum];
 leading=analyticEndpointLeading[expression,e,z,assum];
 If[!PolynomialQ[First[leading],e]||Exponent[First[leading],e]>1,analyticEndpointFail["AffineEndpointPowerRequired"]];
 a=First[leading]/.e->0;b=Coefficient[First[leading],e];
 If[!IntegerQ[a]||a<-1,analyticEndpointFail["AnalyticEndpointTaylorDepthUnsupported",<|"LeadingPower"->First[leading]|>]];
 lo=FeynFacet`DetermineMeromorphicLaurentLowerBound[expression/.h_Hypergeometric2F1->1,e];
 If[!IntegerQ[lo],analyticEndpointFail["AnalyticInteriorLaurentBoundRequired"]];
 (* The endpoint series receives the extra order required by its moment.
    Expand the full interior first; subtraction is only made afterwards. *)
 interior=analyticEndpointSeries[expression,e,lo,high];
 normalized=Total[KeyValueMap[#2 e^#1&,interior["Coefficients"]]] z^-a Exp[-b e Log[z]];
 regular=analyticEndpointSeries[normalized,e,lo,high];
 taylor=If[a===-1,<|0->analyticEndpointSeries[Last[leading],e,lo,high+1]|>,<||>];
 If[a===-1,regular=Join[regular,<|"Coefficients"->Association@Table[j->(regular["Coefficients"][j]-taylor[0]["Coefficients"][j])/z,{j,lo,high}]|>]];
 terms={<|"Power"->First[leading],"Prefactor"->1,"TaylorCoefficients"->taylor,"Remainder"->regular,
   "RemainderEndpointPowerLowerBound"->-1/2|>};
 conditions=request["EndpointConditions"];
 If[!AssociationQ[conditions]||!AllTrue[{"NoInteriorSingularities","UniformEpsilonExpansionOnCompactSubsets","RepresentationValidOnHalfOpenInterval"},TrueQ[Lookup[conditions,#,False]]&],
  analyticEndpointFail["AnalyticEndpointDomainConditionsRequired"]];
 <|"DimensionalRegulator"->e,"Variable"->z,"Interval"->{0,1},"Assumptions"->assum,
  "TestFunctionDomain"->"ThresholdCompactSupport","EndpointConditions"->conditions,"Terms"->terms,
  "AnalyticDomainCheck"->domainCheck,"EndpointLeadingPower"->First[leading],"EndpointLeadingCoefficient"->Last[leading],
  "InteriorCoefficients"->interior,"InteriorEpsilonCheckDomain"->"Fixed interior points and compact sets away from z=0. The separately expanded endpoint coefficient supplies the additional distributional order.","ConstructionMethod"->"Noncoincident Gauss connection before epsilon expansion, followed by subtraction of the full interior Laurent coefficients"|>
 ],"AnalyticEndpoint"];
End[];EndPackage[];
