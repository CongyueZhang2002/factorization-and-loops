(* Adapter from explicit Gamma/Gauss expressions to the general endpoint
   distribution engine. Coalescing angular directions are expanded before
   epsilon: the noncoincident connection coefficient fixes the delta term.
   The full interior expression supplies the regular part, including the
   analytic complement of the Gauss connection formula. *)
BeginPackage["FeynFacet`"];
ConstructAnalyticEndpointExpansion::usage="ConstructAnalyticEndpointExpansion[expression,request] constructs finite Taylor and remainder records for ExtractEndpointDistributions. Request declares DimensionalRegulator, Variable (endpoint at zero), Assumptions and ThroughOrder. Supported expressions have rational factors, meromorphic normal-independent factors and at most one massless angular Gauss function; endpoint poles deeper than z^-1 are rejected.";
ConstructAngularEndpointExpansion::usage="ConstructAngularEndpointExpansion[expression,request] separates coalescing massless angular branches before expanding epsilon, supports massive Gauss and one-mass Appell seeds and arbitrary finite endpoint Taylor depth, and supplies explicit coefficients to ExtractEndpointDistributions.";
Begin["`Private`"];
analyticEndpointFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"AnalyticEndpoint"];
analyticEndpointLeading[x_,e_,z_,assum_]:=Module[{parts,germ,order,coefficient,rho,arg,power,atOrigin,numerator,denominator,na,da},
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
   germ=If[ByteCount[x]>64000,First[FeynFacet`CancelRationalCoefficients[{x}]],Together[x]];
   numerator=Numerator[germ];denominator=Denominator[germ];
   If[!PolynomialQ[numerator,z]||!PolynomialQ[denominator,z],
    analyticEndpointFail["RationalEndpointFactorRequired",<|"Expression"->x|>]];
   (* The endpoint coordinate and dimensional regulator are independent.
      The epsilon-order API intentionally normalizes regulator aliases, so
      it must not be used for this rational valuation in the coordinate. *)
   na=Exponent[numerator,z,Min];da=Exponent[denominator,z,Min];order=na-da;
   If[!IntegerQ[order],analyticEndpointFail["RationalEndpointFactorRequired",<|"Expression"->x,"Valuation"->order|>]];
   (* The leading rational coefficient is a ratio of polynomial
      coefficients. Asking SeriesCoefficient to differentiate a large
      quotient computes much more than this valuation requires. *)
   coefficient=Cancel[Coefficient[numerator,z,na]/Coefficient[denominator,z,da]];
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
 If[!ContainsAll[Keys[request],{"DimensionalRegulator","Variable","Assumptions","ThroughOrder"}],analyticEndpointFail["AnalyticEndpointRequestIncomplete"]];
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
 conditions=<|"NoInteriorSingularities"->True,"UniformEpsilonExpansionOnCompactSubsets"->True,
   "RepresentationValidOnHalfOpenInterval"->True|>;
 <|"DimensionalRegulator"->e,"Variable"->z,"Interval"->{0,1},"Assumptions"->assum,
  "TestFunctionDomain"->"ThresholdCompactSupport","EndpointConditions"->conditions,"Terms"->terms,
  "AnalyticDomainCheck"->domainCheck,"EndpointLeadingPower"->First[leading],"EndpointLeadingCoefficient"->Last[leading],
  "InteriorCoefficients"->interior,"InteriorEpsilonCheckDomain"->"Fixed interior points and compact sets away from z=0. The separately expanded endpoint coefficient supplies the additional distributional order.","ConstructionMethod"->"Noncoincident Gauss connection before epsilon expansion, followed by subtraction of the full interior Laurent coefficients"|>
 ],"AnalyticEndpoint"];

(* Finite epsilon expansion of a linear angular seed. No unresolved derivative
   of a hypergeometric function is admitted to the returned coefficients. *)
angularEndpointSeedSeries[h_,e_,n_,assum_:True]:=Module[{pars,a,b,l,beta,seed,cs,args,roots,replacement},
 If[Head[h]===AppellF1,
  pars=Expand/@Take[List@@h,4];
  If[pars=!={1,-e,-e,1-2e}||n>2,analyticEndpointFail["AppellEndpointOrderUnsupported",<|"ThroughOrder"->n|>]];
  args=Take[List@@h,-2];
  roots=DeleteDuplicates[Cases[args,Power[_,1/2],{0,Infinity}]];
  Do[
   replacement=angularSeedSquareRoot[root[[1]],assum];
   If[replacement=!=root&&
      Cancel[Together[(args[[1]]/.root->-root)-args[[2]]]]===0&&
      Cancel[Together[(args[[2]]/.root->-root)-args[[1]]]]===0,
    args=args/.root->replacement],{root,roots}];
  {a,b}=args;l=Log[1-a]+Log[1-b];
  Return[KeyTake[<|0->1,1->l,2->l^2/2+2PolyLog[2,a/(a-1)]+2PolyLog[2,b/(b-1)]|>,Range[0,n]]]];
 pars=Expand/@Take[List@@h,3];
 If[pars==={1/2,1,3/2-e},
  If[n>1,analyticEndpointFail["MassiveAngularEndpointOrderUnsupported",<|"ThroughOrder"->n|>]];
  beta=Sqrt[h[[4]]];seed=<|"Type"->"SingleMassive","MassInvariant"->(1-h[[4]])/4,"Assumptions"->assum|>;
  cs=angularSeedCoefficients[seed,e,n];Return[KeyTake[cs,Range[0,n]]]];
 cs=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[pars,h[[4]],e,n];
 If[!AssociationQ[cs],analyticEndpointFail["AngularEndpointSeedSeriesRequired",<|"Cause"->cs|>]];cs
];
angularEndpointSeries[expression_,e_,high_,assum_:True]:=Module[{hs,coefficient,lo,need,cs,expanded,poly},
 hs=DeleteDuplicates[Cases[expression,_Hypergeometric2F1|_AppellF1,{0,Infinity}]];
 If[Length[hs]>1,analyticEndpointFail["OneAngularSeedPerEndpointTermRequired"]];
 coefficient=expression/.Thread[hs->1];
 lo=FeynFacet`DetermineMeromorphicLaurentLowerBound[coefficient,e];
 If[lo===Infinity,lo=0];
 If[!IntegerQ[lo],analyticEndpointFail["MeromorphicEndpointPrefactorRequired"]];
 expanded=expression;
 If[hs=!={},need=Max[0,high-lo];cs=angularEndpointSeedSeries[First[hs],e,need,assum];
  epsilonAuditMultiplier[coefficient,e,0,need,high,"AngularEndpointSeed",First[hs]];
  expanded=expression/.First[hs]->Total[KeyValueMap[#2 e^#1&,cs]]];
 (* Reuse the common exact coefficient-field expander. Large kinematic
    expressions are restored only after the epsilon coefficients have been
    extracted, so symbolic Series never differentiates their internals. *)
 poly=regulatorSeriesCoefficients[expanded,e,{lo,high}];
 If[!AssociationQ[poly]||!FreeQ[poly,_Hypergeometric2F1|_AppellF1|_Series|_SeriesData|_SeriesCoefficient|_Derivative|_Integrate|_Failure|Indeterminate|_DirectedInfinity],
  analyticEndpointFail["ExplicitAngularEndpointSeriesRequired"]];
 <|"LaurentLowerBound"->lo,"KnownThroughOrder"->high,"ExactInEpsilon"->False,
  "Coefficients"->poly|>
];
angularEndpointFactor[expression_,e_,t_,assum_]:=Module[{parts,p,base,germ,leading,power,normal},
 If[FreeQ[expression,t],Return[{0,expression}]];
 Which[
  Head[expression]===Times,parts=angularEndpointFactor[#,e,t,assum]&/@(List@@expression);
   {Total[First/@parts],Times@@(Last/@parts)},
  MemberQ[{Hypergeometric2F1,AppellF1},Head[expression]],
   If[Head[expression]===AppellF1,
    If[!AllTrue[Take[List@@expression,-2],TrueQ[FullSimplify[#<1,assum&&0<=t<1]]&],
     analyticEndpointFail["RegularRealAppellEndpointRequired"]],
    If[!TrueQ[FullSimplify[expression[[4]]<1,assum&&0<=t<1]],
     analyticEndpointFail["RegularRealGaussEndpointRequired",<|"Argument"->expression[[4]]|>]]];
   {0,expression},
  Head[expression]===Power&&!IntegerQ[expression[[2]]],
   {base,power}=List@@expression;
   If[!FreeQ[power,t],analyticEndpointFail["NormalIndependentExponentRequired"]];
   germ=analyticEndpointLeading[base,e,t,assum];normal=Cancel[base/t^First[germ]];
   If[!TrueQ[FullSimplify[base>0,assum&&0<t<1]]||
      !TrueQ[FullSimplify[Last[germ]>0,assum]],analyticEndpointFail["PositiveEndpointPowerBaseRequired",<|"Base"->base|>]];
   {Expand[power First[germ]],normal^power},
  True,germ=analyticEndpointLeading[expression,e,t,assum];
   normal=expression/t^First[germ];
   normal=If[ByteCount[normal]>64000,First[FeynFacet`CancelRationalCoefficients[{normal}]],Cancel[normal]];
   If[!FreeQ[normal,_Failure],analyticEndpointFail["NormalizedAngularRationalFactorRequired"]];
   {First[germ],normal}]
];
angularEndpointBranches[expression_,e_,t_,assum_]:=Module[{hs,aliases,rows,terms={},h,c,v,germ},
 hs=DeleteDuplicates[Cases[expression,_Hypergeometric2F1|_AppellF1,{0,Infinity}]];
 aliases=Table[Unique["endpointSeed$"],{Length[hs]}];
 rows=FeynFacet`PolynomialCoefficientRules[expression/.Thread[hs->aliases],aliases];
 If[!ListQ[rows]||!AllTrue[First/@rows,Total[#]<=1&],analyticEndpointFail["LinearAngularEndpointCombinationRequired"]];
 Do[c=Last[row];h=If[Total[First[row]]===0,1,hs[[First[FirstPosition[First[row],1]]]]];
  If[Head[h]===Hypergeometric2F1&&(Expand/@Take[List@@h,3])==={1,1,1-e},
   v=Cancel[1-h[[4]]];germ=analyticEndpointLeading[v,e,t,assum];
   If[First[germ]>0,
    If[!TrueQ[FullSimplify[0<v<1,assum&&0<t<1]],analyticEndpointFail["PositiveCoalescingAngularInvariantRequired"]];
    AppendTo[terms,c Gamma[1-e]Gamma[1+e]v^(-1-e)(1-v)^e];
    AppendTo[terms,c e/((1+e)(1-v))Hypergeometric2F1[1,1+e,2+e,v/(v-1)]],
    AppendTo[terms,c h]],AppendTo[terms,c h]],{row,rows}];
 DeleteCases[terms,0]
];
ConstructAngularEndpointExpansion[expression_,request_Association]:=Catch[Module[
 {e,t,assum,high,conditions,branches,terms={},factor,power,a,b,n,smooth,series,lo,
  taylor,rem,coefficients,jets,value,coalescing,endpointValue},
 If[!ContainsAll[Keys[request],{"DimensionalRegulator","Variable","Assumptions","ThroughOrder","EndpointConditions"}],
  analyticEndpointFail["AnalyticEndpointRequestIncomplete"]];
 {e,t,assum,high,conditions}=Lookup[request,{"DimensionalRegulator","Variable","Assumptions","ThroughOrder","EndpointConditions"}];
 If[!MatchQ[{e,t},{_Symbol,_Symbol}]||e===t||!IntegerQ[high]||!FreeQ[assum,e|t],
  analyticEndpointFail["AnalyticEndpointVariablesRequired"]];
 If[!AssociationQ[conditions]||!AllTrue[{"NoInteriorSingularities","UniformEpsilonExpansionOnCompactSubsets","RepresentationValidOnHalfOpenInterval"},TrueQ[Lookup[conditions,#,False]]&],
  analyticEndpointFail["AnalyticEndpointDomainConditionsRequired"]];
 branches=angularEndpointBranches[expression,e,t,assum];
 If[TrueQ[Lookup[request,"PrintTimings",False]],Print["ENDPOINT BRANCHES ",Length[branches]," BYTES ",ByteCount[branches]]];
 Do[
  If[TrueQ[Lookup[request,"PrintTimings",False]],Print["START ENDPOINT BRANCH BYTES ",ByteCount[branch]]];
  coalescing=coefficientEndpointCoalescingDivisors[branch/.(_Hypergeometric2F1|_AppellF1)->1,t,e];
  If[coalescing=!={},analyticEndpointFail["JointEndpointRegulatorDenominatorUnsupported",<|"Divisors"->coalescing|>]];
  If[TrueQ[Lookup[request,"PrintTimings",False]],Print["ENDPOINT JOINT DIVISORS CHECKED"]];
  factor=angularEndpointFactor[branch,e,t,assum];{power,smooth}=factor;
  If[TrueQ[Lookup[request,"PrintTimings",False]],Print["ENDPOINT POWER ",power," SMOOTH BYTES ",ByteCount[smooth]]];
  If[!PolynomialQ[power,e]||Exponent[power,e]>1,analyticEndpointFail["AffineEndpointPowerRequired"]];
  a=power/.e->0;b=Coefficient[power,e];
  If[!IntegerQ[a],analyticEndpointFail["IntegerAngularEndpointPowerRequired"]];
  n=Max[0,-a];series=angularEndpointSeries[smooth,e,high+Boole[n>1],assum];
  If[TrueQ[Lookup[request,"PrintTimings",False]],Print["ENDPOINT LAURENT SERIES BYTES ",ByteCount[series]," TAYLOR DEPTH ",n]];
  lo=series["LaurentLowerBound"];coefficients=series["Coefficients"];taylor=<||>;
  If[n===1,
   (* The exact connection already isolates every nonuniform branch.
      For an analytic normalized factor its value at t=0 commutes with
      epsilon expansion. Avoid expanding the extra order in the interior. *)
   endpointValue=smooth/.t->0;
   If[TrueQ[Lookup[request,"PrintTimings",False]],Print["ENDPOINT VALUE BYTES ",ByteCount[endpointValue]]];
   If[!FreeQ[endpointValue,Indeterminate|_DirectedInfinity],analyticEndpointFail["FiniteNormalizedEndpointValueRequired"]];
   AssociateTo[taylor,0->angularEndpointSeries[endpointValue,e,high+1,assum]];
   If[TrueQ[Lookup[request,"PrintTimings",False]],Print["ENDPOINT VALUE SERIES BYTES ",ByteCount[taylor]]],
   Do[
    jets=Map[Function[f,FullSimplify[SeriesCoefficient[f,{t,0,j}],assum]],coefficients];
    If[!FreeQ[Values[jets],t|_SeriesCoefficient|_SeriesData|_Derivative|_Limit|Indeterminate|_DirectedInfinity],
     analyticEndpointFail["ExplicitRegularAngularEndpointTaylorJetRequired",<|"TaylorOrder"->j|>]];
    AssociateTo[taylor,j->Join[series,<|"Coefficients"->jets|>]],{j,0,n-1}]];
  rem=Join[series,<|"KnownThroughOrder"->high,"Coefficients"->Association@Table[k->
    ((coefficients[k]-Sum[If[k<taylor[j]["LaurentLowerBound"],0,taylor[j]["Coefficients"][k]]t^j,{j,0,n-1}])/t^n),{k,lo,high}]|>];
  AppendTo[terms,<|"Power"->power,"Prefactor"->1,"TaylorCoefficients"->taylor,"Remainder"->rem,
    "RemainderEndpointPowerLowerBound"->-1/2|>],{branch,branches}];
 <|"DimensionalRegulator"->e,"Variable"->t,"Interval"->{0,1},"Assumptions"->assum,
  "TestFunctionDomain"->"ThresholdCompactSupport","EndpointConditions"->conditions,"Terms"->terms,
  "ConstructionMethod"->"Exact coalescing angular connection before epsilon expansion, followed by regular Taylor jets and subtraction at each affine endpoint power",
  "BranchCount"->Length[branches]|>
],"AnalyticEndpoint"];

End[];EndPackage[];
