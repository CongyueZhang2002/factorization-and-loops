(* Finite-interval analytic continuation of regulated endpoint distributions.
   Public input/output convention: Design/EndpointDistributions.md. *)
BeginPackage["FeynFacet`"];
ExtractEndpointDistributions::usage = "ExtractEndpointDistributions[data,request] returns explicit finite epsilon coefficients of endpoint delta derivatives, generalized plus distributions and a locally integrable remainder on the declared interval.";
DetermineEndpointDistributionOrders::usage = "DetermineEndpointDistributionOrders[data,request] determines separate sufficient epsilon orders of endpoint Taylor coefficients, the locally integrable remainder and explicit prefactors.";
EndpointDeltaDerivative::usage = "EndpointDeltaDerivative[z,j,Z] is the full endpoint delta derivative on [0,Z], acting on f as (-1)^j f^(j)(0).";
EndpointPlusDistribution::usage = "EndpointPlusDistribution[z,a,k,n,Z] acts on f as Integrate[z^a Log[z]^k (f[z]-Sum[f^(j)(0) z^j/j!,{j,0,n-1}]),{z,0,Z}].";
Begin["`Private`"];
Clear[endpointDistributionFail,endpointDistributionNormalize,endpointDistributionGeometry,
 endpointDistributionSeriesMetadata,endpointDistributionSeries,endpointDistributionExactSeries,
 endpointDistributionPlan,endpointDistributionTermPlan,endpointDistributionMoment,
 endpointDistributionMomentSeries,endpointDistributionPower,endpointDistributionConvolve,endpointDistributionPolynomial,
 endpointDistributionExtract,endpointDistributionTerm,endpointDistributionCoefficientSum];
endpointDistributionFail[tag_,details_:<||>] := Throw[Failure[tag,details],"EndpointDistributions"];
endpointDistributionNormalize[d_] := Module[{e=Lookup[d,"DimensionalRegulator",None]},
 If[!MatchQ[e,_Symbol] || e===None,endpointDistributionFail["DimensionalRegulatorRequired"]];
 If[Length[DownValues[epsOrderNormalize]]===0,
   endpointDistributionFail["EpsilonOrderPlannerNotLoaded"]];
 epsOrderNormalize[d,e]
];
endpointDistributionGeometry[d_,r_] := Module[{e,z,interval,upper,assumptions,conditions,terms,testDomain,requiredConditions,domainConvention},
 e=Lookup[d,"DimensionalRegulator",None];z=Lookup[d,"Variable",None];
 interval=Lookup[d,"Interval",None];assumptions=Lookup[d,"Assumptions",True];
 conditions=Lookup[d,"EndpointConditions",<||>];terms=Lookup[d,"Terms",None];
 If[!MatchQ[z,_Symbol] || z===None || z===e ||
    Lookup[d,"NormalVariables",{z}]=!={z} ||
    Lookup[d,"EndpointGeometry","SingleEndpoint"]=!="SingleEndpoint",
   endpointDistributionFail["UnresolvedMultipleEndpoints",<|"Required"->"One resolved normal variable, with all other endpoint singularities excluded on the declared tangential domain."|>]];
 If[!MatchQ[interval,{0,_}],endpointDistributionFail["FinitePositiveEndpointIntervalRequired"]];
 upper=Last[interval];
 If[!FreeQ[upper,z|e] || !FreeQ[assumptions,e] ||
    !TrueQ[FullSimplify[0<upper<Infinity,Assumptions->assumptions]],
   endpointDistributionFail["FinitePositiveEndpointIntervalRequired",<|"Interval"->interval,"Assumptions"->assumptions|>]];
 testDomain=Lookup[d,"TestFunctionDomain","SmoothOnClosedInterval"];
 Switch[testDomain,
  "SmoothOnClosedInterval",
   requiredConditions={"NoOtherSingularities","UniformEpsilonExpansion","RepresentationValidOnInterval"};
   domainConvention=<|"IntervalClosure"->"Closed","TestFunctionDomain"->testDomain,
    "TestFunctions"->"Smooth test functions on the full closed interval, on the supplied tangential domain",
    "RemainderIntegrability"->"Integrable on the full interval","UpperEndpointExcluded"->False|>,
  "ThresholdCompactSupport",
   requiredConditions={"NoInteriorSingularities","UniformEpsilonExpansionOnCompactSubsets","RepresentationValidOnHalfOpenInterval"};
   domainConvention=<|"IntervalClosure"->"LeftClosedRightOpen","TestFunctionDomain"->testDomain,
    "TestFunctions"->"Smooth up to z=0, with compact support away from z=Z and tangential-domain boundaries; the value at z=0 may be nonzero",
    "RemainderIntegrability"->"Locally integrable on [0,Z), locally uniformly on compact tangential subsets",
    "UpperEndpointExcluded"->True,"UpperEndpointDistributionExtensionAsserted"->False|>,
  _,endpointDistributionFail["UnsupportedEndpointTestFunctionDomain",<|"TestFunctionDomain"->testDomain|>]];
 If[!AssociationQ[conditions] || !AllTrue[requiredConditions,TrueQ[Lookup[conditions,#,False]]&],
   endpointDistributionFail["EndpointConditionsRequired",<|"TestFunctionDomain"->testDomain,"Required"->requiredConditions|>]];
 If[!ListQ[terms] || !AllTrue[terms,AssociationQ] || !IntegerQ[Lookup[r,"ThroughOrder",None]],
   endpointDistributionFail["FiniteEndpointTermsAndTargetOrderRequired"]];
 <|"DimensionalRegulator"->e,"Variable"->z,"UpperBound"->upper,
   "Assumptions"->assumptions,"ThroughOrder"->r["ThroughOrder"],"DomainConvention"->domainConvention|>
];
endpointDistributionSeriesMetadata[s_,label_] := Module[{lo,hi},
 If[!AssociationQ[s],endpointDistributionFail["FiniteEpsilonSeriesRequired",<|"Input"->label|>]];
 lo=Lookup[s,"LaurentLowerBound",None];hi=Lookup[s,"KnownThroughOrder",None];
 If[!IntegerQ[lo] || !IntegerQ[hi] || hi<lo-1 ||
   !MemberQ[{True,False},Lookup[s,"ExactInEpsilon",False]],
   endpointDistributionFail["FiniteEpsilonSeriesBoundsRequired",<|"Input"->label|>]];
 <|"LaurentLowerBound"->lo,"KnownThroughOrder"->hi,
   "ExactInEpsilon"->Lookup[s,"ExactInEpsilon",False]|>
];
endpointDistributionSeries[s_,need_,e_,z_,normalIndependent_,label_] := Module[{meta,lo,hi,cs,keys},
 meta=endpointDistributionSeriesMetadata[s,label];lo=meta["LaurentLowerBound"];hi=meta["KnownThroughOrder"];
 cs=Lookup[s,"Coefficients",None];keys=Range[lo,hi];
 If[!AssociationQ[cs] || Sort[Keys[cs]]=!=keys ||
   !FreeQ[Values[cs],e|_SeriesData|_SeriesCoefficient|_Missing|_Failure|Indeterminate|_DirectedInfinity] ||
   (TrueQ[normalIndependent] && !FreeQ[Values[cs],z]),
   endpointDistributionFail["ExplicitFiniteEpsilonCoefficientsRequired",<|"Input"->label,"RequiredKeys"->keys|>]];
 If[need>hi && !TrueQ[meta["ExactInEpsilon"]],
   endpointDistributionFail["InsufficientEndpointEpsilonOrders",<|"Input"->label,
     "KnownThroughOrder"->hi,"RequiredThroughOrder"->need|>]];
 Join[meta,<|"KnownThroughOrder"->Min[hi,need],
   "ExactInEpsilon"->(TrueQ[meta["ExactInEpsilon"]]&&AllTrue[Values[KeySelect[cs,#>need&]],#===0&]),
   "Coefficients"->KeySelect[cs,#<=need&]|>]
];
endpointDistributionExactSeries[x_,lo_,hi_,e_,assumptions_] := Module[{poly,scaled},
 If[hi<lo,Return[<|"LaurentLowerBound"->lo,"KnownThroughOrder"->hi,"Coefficients"-><||>,"ExactInEpsilon"->TrueQ[x===0]|>]];
 poly=Quiet[Check[Normal[Series[x,{e,0,hi}]],$Failed]];
 If[poly===$Failed || !FreeQ[poly,_SeriesData|_Series|_SeriesCoefficient|Indeterminate|_DirectedInfinity],
   endpointDistributionFail["ExplicitPrefactorExpansionRequired",<|"Expression"->x,"ThroughOrder"->hi|>]];
 scaled=Expand[e^-lo poly];
 If[!PolynomialQ[scaled,e],endpointDistributionFail["ExplicitPrefactorExpansionRequired",<|"Expression"->x|>]];
 <|"LaurentLowerBound"->lo,"KnownThroughOrder"->hi,
   "Coefficients"->Association@Table[k->FullSimplify[Coefficient[scaled,e,k-lo],Assumptions->assumptions],{k,lo,hi}],
   "ExactInEpsilon"->False|>
];
endpointDistributionTermPlan[t_,g_,index_] := Module[
 {e=g["DimensionalRegulator"],z=g["Variable"],target=g["ThroughOrder"],power,a,b,p,n,pref,pv,
  tay,rem,rho,tm,rm,demands,momentLower,prefNeed,oldPlan},
 power=Lookup[t,"Power",None];p=Lookup[t,"LogPower",0];pref=Lookup[t,"Prefactor",1];
 If[!PolynomialQ[power,e] || Exponent[power,e]>1 || !FreeQ[power,z] ||
   !IntegerQ[p] || p<0,endpointDistributionFail["AffineRegulatedEndpointPowerRequired",<|"Term"->index|>]];
 a=power/.e->0;b=Coefficient[power,e];
 If[!MatchQ[a,_Integer|_Rational],endpointDistributionFail["RationalEndpointPowerRequired",<|"Term"->index|>]];
 If[a<=-1 && !TrueQ[FullSimplify[b!=0,Assumptions->g["Assumptions"]]],
   endpointDistributionFail["EndpointNotRegulated",<|"Term"->index,"Power"->power|>]];
 n=Max[0,Floor[-a]];
 If[AssociationQ[pref],pv=endpointDistributionSeriesMetadata[pref,{index,"Prefactor"}]["LaurentLowerBound"],
   If[!FreeQ[pref,z],endpointDistributionFail["NormalIndependentPrefactorRequired",<|"Term"->index|>]];
   pv=FeynFacet`DetermineLaurentValuation[pref,e];
   If[FailureQ[pv] || (!IntegerQ[pv] && pv=!=Infinity),
     endpointDistributionFail["PrefactorLaurentLowerBoundRequired",<|"Term"->index,"Reason"->pv|>]]
 ];
 If[pv===Infinity,Return[<|"TermIndex"->index,"Status"->"ZeroPrefactor","SubtractionOrder"->n|>]];
 tay=Lookup[t,"TaylorCoefficients",<||>];rem=Lookup[t,"Remainder",None];
 rho=Lookup[t,"RemainderEndpointPowerLowerBound",None];
 If[!AssociationQ[tay] || Sort[Keys[tay]]=!=Range[0,n-1],
   endpointDistributionFail["EndpointTaylorCoefficientsRequired",<|"Term"->index,"RequiredTaylorOrders"->Range[0,n-1]|>]];
 If[!MatchQ[rho,_Integer|_Rational] || !TrueQ[a+n+rho>-1],
   endpointDistributionFail["LocallyIntegrableRemainderBoundRequired",<|"Term"->index,"SubtractedPower"->a+n|>]];
 tm=Association@Table[j->endpointDistributionSeriesMetadata[tay[j],{index,"TaylorCoefficient",j}],{j,0,n-1}];
 rm=endpointDistributionSeriesMetadata[rem,{index,"Remainder"}];
 momentLower=If[IntegerQ[a] && a<=-1,-p-1,0];
 demands=Association@Table[j->target-pv-momentLower,{j,0,n-1}];
 prefNeed=Max[Join[{target-rm["LaurentLowerBound"]},
   Table[target-tm[j]["LaurentLowerBound"]-momentLower,{j,0,n-1}]]];
 oldPlan=FeynFacet`DetermineEndpointEpsilonOrders[<|"DimensionalRegulator"->e,
   "NormalVariables"->{z},"EndpointPowers"->{power},"LogPowers"->{p},"Prefactor"->e^pv|>,
   <|"ThroughOrder"->target|>];
 If[FailureQ[oldPlan],endpointDistributionFail["EndpointOrderPlanningFailed",<|"Reason"->oldPlan|>]];
 <|"TermIndex"->index,"Status"->"SufficientOrdersDetermined","PowerAtZero"->a,
   "RegulatorSlope"->b,"LogPower"->p,"SubtractionOrder"->n,
   "PrefactorLaurentLowerBound"->pv,"RequiredPrefactorUpperOrder"->prefNeed,
   "RequiredTaylorUpperOrders"->demands,"RequiredRemainderUpperOrder"->target-pv,
   "EndpointMomentLaurentLowerBound"->momentLower,
   "InputLaurentLowerBounds"-><|"TaylorCoefficients"->Association@Table[j->tm[j]["LaurentLowerBound"],{j,0,n-1}],
      "Remainder"->rm["LaurentLowerBound"]|>,
   "EndpointProjectionOrderPlan"->oldPlan|>
];
endpointDistributionPlan[d_,r_] := Module[{g,plans},
 g=endpointDistributionGeometry[d,r];
 plans=MapIndexed[endpointDistributionTermPlan[#1,g,First[#2]]&,d["Terms"]];
 <|"DataType"->"EndpointDistributionEpsilonOrders","Status"->"SufficientOrdersDetermined",
   "ThroughOrder"->g["ThroughOrder"],"TermRequirements"->plans,"DomainConvention"->g["DomainConvention"],
   "Scope"->"Single resolved endpoint with the supplied uniform amplitude decomposition and explicit prefactors.",
   "PhysicalNNLOCoverageInferred"->False|>
];
endpointDistributionPower[x_,0] := 1;
endpointDistributionPower[x_,n_] := x^n;
(* M_p(c,Z)=d^p/dc^p (Z^c/c). This finite expression also fixes every
   nonresonant delta coefficient for higher powers and nonunit intervals. *)
endpointDistributionMoment[c_,p_,upper_] := upper^c Sum[
   Binomial[p,j] endpointDistributionPower[Log[upper],p-j] (-1)^j Factorial[j]/c^(j+1),{j,0,p}];
endpointDistributionMomentSeries[c_,b_,p_,upper_,lo_,hi_] := Module[{cs},
 cs=Association@Table[k->If[c===0,
   Which[k===-p-1,(-1)^p Factorial[p]/b^(p+1),k<0,0,
     True,endpointDistributionPower[b,k] Log[upper]^(k+p+1)/(Factorial[k] (k+p+1))],
   If[k<0,0,endpointDistributionPower[b,k]/Factorial[k] endpointDistributionMoment[c,p+k,upper]]],{k,lo,hi}];
 <|"LaurentLowerBound"->lo,"KnownThroughOrder"->hi,"Coefficients"->cs|>
];
endpointDistributionConvolve[records_List,lo_,hi_] := Module[{states=<|0->1|>,next,cs},
 epsilonAuditProduct[MapIndexed[epsilonAuditStoredSpec[#1,First[#2]]&,records],hi,
   "Stage4/DistributionConvolution",{lo,hi}];
 Do[cs=record["Coefficients"];next=<||>;
   KeyValueMap[Function[{k,a},KeyValueMap[Function[{j,b},
     AssociateTo[next,k+j->(Lookup[next,k+j,0]+a b)]],cs]],states];states=next,
 {record,records}];
 Association@Table[k->Lookup[states,k,0],{k,lo,hi}]
];
endpointDistributionPolynomial[cs_,e_] := Total[KeyValueMap[#2 e^#1&,cs]];
endpointDistributionCoefficientSum[records_,lo_,hi_] := Association@Table[
   k->Total[Lookup[#,k,0]& /@ records],{k,lo,hi}];
endpointDistributionTerm[t_,g_,plan_] := Module[
 {e=g["DimensionalRegulator"],z=g["Variable"],upper=g["UpperBound"],target=g["ThroughOrder"],
  index=plan["TermIndex"],a,b,p,n,pv,pref,tay,rem,lower,delta={},plus={},regular,
  coeff,lo,hi,moment,series,polynomial,expression,regularSeries,kmax,
  auditPref,auditTaylor,auditMoment,u},
 If[plan["Status"]==="ZeroPrefactor",Return[<|"TermIndex"->index,
   "Labels"->Lookup[t,"Labels",<||>],"DeltaTerms"->{},"PlusTerms"->{},
   "RegularRemainder"-><|"Coefficients"-><||>,"Expression"->0|>,"Coefficients"-><||>,"Expression"->0|>]];
 {a,b,p,n,pv}=Lookup[plan,{"PowerAtZero","RegulatorSlope","LogPower","SubtractionOrder","PrefactorLaurentLowerBound"}];
 pref=Lookup[t,"Prefactor",1];
 pref=If[AssociationQ[pref],endpointDistributionSeries[pref,plan["RequiredPrefactorUpperOrder"],e,z,True,{index,"Prefactor"}],
   endpointDistributionExactSeries[pref,pv,plan["RequiredPrefactorUpperOrder"],e,g["Assumptions"]]];
 tay=Association@Table[j->endpointDistributionSeries[t["TaylorCoefficients"][j],
    plan["RequiredTaylorUpperOrders"][j],e,z,True,{index,"TaylorCoefficient",j}],{j,0,n-1}];
 rem=endpointDistributionSeries[t["Remainder"],plan["RequiredRemainderUpperOrder"],e,z,False,{index,"Remainder"}];
 lower=Min[Join[{pv+rem["LaurentLowerBound"]},
   Table[pv+tay[j]["LaurentLowerBound"]+plan["EndpointMomentLaurentLowerBound"],{j,0,n-1}]]];
 Do[
   lo=pv+tay[r]["LaurentLowerBound"];
   Do[
     hi=target-lo;
     moment=endpointDistributionMomentSeries[a+r+j+1,b,p,upper,
        If[a+r+j+1===0,-p-1,0],hi];
     If[TrueQ[$epsilonRemainderChecks],
      auditPref=epsilonAuditStoredSpec[pref,"Prefactor"];auditTaylor=epsilonAuditStoredSpec[tay[r],"TaylorCoefficient"];
      u=Unique["momentExponent"];
      auditMoment=D[upper^u/u,{u,p}]/.u->a+r+j+1+b e;
      If[!TrueQ[auditTaylor["Exact"]],
       epsilonAuditMultiplier[auditMoment,e,auditTaylor["LowerBound"],auditTaylor["ThroughOrder"],
        target-auditPref["LowerBound"],"Stage4/EndpointMoment",{index,r,j,"TaylorCoefficient"}]];
      If[!TrueQ[auditPref["Exact"]],
       epsilonAuditMultiplier[auditMoment,e,auditPref["LowerBound"],auditPref["ThroughOrder"],
        target-auditTaylor["LowerBound"],"Stage4/EndpointMoment",{index,r,j,"Prefactor"}]]];
     coeff=endpointDistributionConvolve[{pref,tay[r],moment},lower,target];
     coeff=Map[(-1)^j #/Factorial[j]&,coeff];
     AppendTo[delta,<|"AmplitudeTaylorOrder"->r,"DerivativeOrder"->j,
       "Coefficients"->coeff,"Expression"->endpointDistributionPolynomial[coeff,e] EndpointDeltaDerivative[z,j,upper]|>],
   {j,0,n-r-1}];
   kmax=target-lo;
   Do[
     coeff=endpointDistributionConvolve[{pref,tay[r]},lower-k,target-k];
     coeff=Association@KeyValueMap[(#1+k)->(#2 endpointDistributionPower[b,k]/Factorial[k])&,coeff];
     AppendTo[plus,<|"AmplitudeTaylorOrder"->r,"Power"->a+r,"LogPower"->p+k,"SubtractionOrder"->n-r,
       "Coefficients"->coeff,"Expression"->endpointDistributionPolynomial[coeff,e] EndpointPlusDistribution[z,a+r,p+k,n-r,upper]|>],
   {k,0,kmax}],
 {r,0,n-1}];
 lo=pv+rem["LaurentLowerBound"];
 regularSeries=<|"LaurentLowerBound"->0,"KnownThroughOrder"->target-lo,
   "Coefficients"->Association@Table[k->endpointDistributionPower[b,k] Log[z]^(p+k) z^(a+n)/Factorial[k],{k,0,target-lo}]|>;
 regular=endpointDistributionConvolve[{pref,rem,regularSeries},lower,target];
 expression=Total[Lookup[delta,"Expression",{}]]+Total[Lookup[plus,"Expression",{}]]+
   endpointDistributionPolynomial[regular,e];
 polynomial=Association@Table[k->(Total[Lookup[#["Coefficients"],k,0] EndpointDeltaDerivative[z,#["DerivativeOrder"],upper]& /@ delta]+
   Total[Lookup[#["Coefficients"],k,0] EndpointPlusDistribution[z,#["Power"],#["LogPower"],#["SubtractionOrder"],upper]& /@ plus]+
   Lookup[regular,k,0]),{k,lower,target}];
 <|"TermIndex"->index,"Labels"->Lookup[t,"Labels",<||>],"LaurentLowerBound"->lower,"ThroughOrder"->target,
   "DeltaTerms"->delta,"PlusTerms"->plus,
   "RegularRemainder"-><|"Coefficients"->regular,"Expression"->endpointDistributionPolynomial[regular,e],
     "EndpointPowerLowerBound"->a+n+t["RemainderEndpointPowerLowerBound"]|>,
   "Coefficients"->polynomial,"Expression"->expression|>
];
endpointDistributionExtract[d_,r_] := Module[{g,orderPlan,terms,groups,components,lower,coeff},
 g=endpointDistributionGeometry[d,r];orderPlan=endpointDistributionPlan[d,r];
 terms=MapThread[endpointDistributionTerm[#1,g,#2]&,{d["Terms"],orderPlan["TermRequirements"]}];
 groups=GatherBy[terms,#["Labels"]&];
 components=Table[lower=Min[Append[Lookup[group,"LaurentLowerBound",g["ThroughOrder"]],g["ThroughOrder"]]];
   coeff=endpointDistributionCoefficientSum[Lookup[group,"Coefficients"],lower,g["ThroughOrder"]];
   <|"Labels"->group[[1,"Labels"]],"LaurentLowerBound"->lower,"ThroughOrder"->g["ThroughOrder"],
     "Coefficients"->coeff,"Expression"->endpointDistributionPolynomial[coeff,g["DimensionalRegulator"]],
     "TermIndices"->Lookup[group,"TermIndex"]|>,{group,groups}];
 <|"DataType"->"FiniteEndpointDistributions","Status"->"ExplicitFiniteCoefficients",
   "DimensionalRegulator"->g["DimensionalRegulator"],"Variable"->g["Variable"],"Interval"->d["Interval"],
   "Assumptions"->g["Assumptions"],"EndpointConditions"->d["EndpointConditions"],
   "DomainConvention"->g["DomainConvention"],
   "ThroughOrder"->g["ThroughOrder"],"OmittedEpsilonOrderLowerBound"->g["ThroughOrder"]+1,
   "Terms"->terms,"Components"->components,"Expression"->Total[Lookup[terms,"Expression",{}]],
   "OrderRequirements"->orderPlan,
   "Convention"-><|"Measure"->"dz (all Jacobians and normalization factors must be explicit in the input terms)",
      "EndpointDeltaNormalization"->"Full endpoint mass: delta^(j) acts as (-1)^j f^(j)(0)",
      "PlusSubtraction"->"Taylor polynomial of the test function at zero, subtracted over the entire interval [0,Z], including the tail beyond the support of the test function",
      "Logarithm"->"Log[z], with z positive and dimensionless; no implicit scale or rescaling by Z"|>,
   "PhysicalNNLOCoverageInferred"->False|>
];
FeynFacet`DetermineEndpointDistributionOrders[d_Association,r_Association] :=
 Catch[If[Lookup[d,"EndpointGeometry",None]==="NormalCrossings",tensorEndpointPlan,endpointDistributionPlan][endpointDistributionNormalize[d],r],"EndpointDistributions"];
FeynFacet`ExtractEndpointDistributions[d_Association,r_Association] :=
 Catch[If[Lookup[d,"EndpointGeometry",None]==="NormalCrossings",tensorEndpointExtract,endpointDistributionExtract][endpointDistributionNormalize[d],r],"EndpointDistributions"];
End[];
EndPackage[];
