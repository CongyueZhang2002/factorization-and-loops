(* Resolve correlated one-mass-box arguments before an endpoint expansion.
   F'_epsilon(A)=-epsilon |A|^-epsilon/[A(1-A)] implies
   F(A)-F(A+B-AB)=epsilon B/A |A|^-epsilon
     AppellF1[1,1,1+epsilon,2,B,-B(1-A)/A].
   The Appell factor is analytic when B and B(1-A)/A vanish at the corner.
   This identity, not a numerical cancellation, removes mixed corner ratios.
   Review: External/ChatGPT/Records/2026-09-09/23_sidis_rv_endpoints_vv.md. *)
BeginPackage["FeynFacet`"];
ResolveMasslessBoxEndpointPowers::usage="ResolveMasslessBoxEndpointPowers[{s,t,m},epsilon,normalVariables,conditions] rewrites a one-off-shell box into exact normal-crossing powers times analytic Gauss/Appell factors where the correlated difference or simultaneous inversion applies. It retains causal phases and returns its endpoint-domain conditions. It is an endpoint representation, not an epsilon-expanded hard result.";
ExpandMasslessBoxCornerJets::usage="ExpandMasslessBoxCornerJets[resolved,orders] constructs explicit rectangular Taylor jets of every analytic factor, exact in epsilon, after the box endpoint powers have been resolved. Each order belongs to one normal variable. These corner jets do not replace edge data or the full interior coefficient.";
ExpandAnalyticEndpointFaceJets::usage="ExpandAnalyticEndpointFaceJets[resolved,normalOrders] takes exact face jets of verified analytic Gamma, power, Gauss and Appell endpoint factors. Inactive Gauss functions remain analytic until after their face restriction.";
ExpandMasslessBoxFaceJets::usage="ExpandMasslessBoxFaceJets[resolved,normalOrders] computes exact-in-epsilon Taylor coefficients of each smooth box factor on a declared face. normalOrders associates any nonempty subset of normal variables to nonnegative jet orders. Tangential variables remain unevaluated functions; coincident or zero Appell arguments reduce exactly to Gauss functions.";
Begin["`Private`"];
boxCornerValue[expr_,variables_]:=Cancel[expr]/.Thread[variables->0];
boxAnalyticZeroAtCornerQ[expr_,variables_,conditions_]:=Module[{value=Cancel[expr],denominator},
 denominator=Denominator[value]/.Thread[variables->0];
 TrueQ[FullSimplify[denominator!=0,Assumptions->conditions]]&&
 TrueQ[boxCornerValue[value,variables]===0]
];
boxRationalNormalFactors[expr_,variables_,conditions_,positive_:False]:=Module[
 {value=Cancel[expr],powers,unit,corner},
 powers=Table[Exponent[Numerator[value],x,Min]-Exponent[Denominator[value],x,Min],{x,variables}];
 If[!VectorQ[powers,IntegerQ],boxFail["RationalCoordinateValuationsRequired"]];
 unit=Cancel[value/Times@@MapThread[Power,{variables,powers}]];
 corner=boxCornerValue[unit,variables];
 If[!FreeQ[corner,Indeterminate|_DirectedInfinity]||
  !TrueQ[FullSimplify[If[positive,corner>0,corner!=0],Assumptions->conditions]],
  boxFail["NonvanishingAnalyticCoordinateUnitRequired",<|"Unit"->unit|>]];
 {powers,unit}
];
ResolveMasslessBoxEndpointPowers[{s_,t_,mass_},e_Symbol,variables:{__Symbol},conditions_]:=
 Catch[Module[
 {u=Factor[mass-s-t],args,phases,invariantSigns,terms={},rGamma,make,pair=None,
  a,b,h,scales,leftover,domain=conditions,method,inverses,constant,signs,coefficient},
 If[!DuplicateFreeQ[variables]||MemberQ[variables,e]||
  !FreeQ[{s,t,mass,conditions},e|_Real],
  boxFail["ExactBoxEndpointCoordinatesRequired"]];
 invariantSigns=boxSign[#,conditions]&/@{s,t,mass};
 args=Factor/@{-u/s,-u/t,-u mass/(s t)};
 phases=If[#===1,Exp[I Pi e],1]&/@invariantSigns;
 scales=FullSimplify[Abs[#],Assumptions->conditions]&/@{t,s,mass};
 rGamma=Gamma[1+e]Gamma[1-e]^2/Gamma[1-2e];
 make[rational_,prefactor_,scale_,exponent_,analytic_]:=Module[{rf,sf},
  If[TrueQ[prefactor===0]||TrueQ[rational===0],Return[Null]];
  rf=boxRationalNormalFactors[rational,variables,conditions];
  sf=boxRationalNormalFactors[scale,variables,conditions,True];
  AppendTo[terms,<|"Powers"->(rf[[1]]+exponent sf[[1]]),
   "SmoothFactor"->rf[[2]]prefactor sf[[2]]^exponent analytic|>]
 ];
 Do[
  a=args[[i]];b=args[[3-i]];h=Factor[b(1-a)/a];
  If[phases[[3-i]]===phases[[3]]&&
   boxAnalyticZeroAtCornerQ[b,variables,conditions]&&
   boxAnalyticZeroAtCornerQ[h,variables,conditions],
   pair=i;Break[]],
 {i,2}];
 If[pair=!=None,
  a=args[[pair]];b=args[[3-pair]];h=Factor[b(1-a)/a];
  make[Factor[2b/(a s t)],rGamma phases[[3-pair]]/e,scales[[pair]],-e,
   AppellF1[1,1,1+e,2,b,-h]];
  make[2/(s t),rGamma phases[[pair]]/e^2,scales[[3-pair]],-e,
   Hypergeometric2F1[1,-e,1-e,b]];
  domain=conditions&&b<1&&h>-1;
  method="CorrelatedHypergeometricDifference",
  inverses=Factor[1/#]&/@args;
  If[!AllTrue[inverses,boxAnalyticZeroAtCornerQ[#,variables,conditions]&],
   boxFail["BoxCornerRequiresAdditionalResolution",<|"Arguments"->args|>]];
  signs=boxSign[#,conditions]&/@args;
  constant=phases[[2]]If[signs[[1]]===1,Pi e Cot[Pi e],Pi e Csc[Pi e]]+
   phases[[1]]If[signs[[2]]===1,Pi e Cot[Pi e],Pi e Csc[Pi e]]-
   phases[[3]]If[signs[[3]]===1,Pi e Cot[Pi e],Pi e Csc[Pi e]];
  make[2/(s t),rGamma constant/e^2,
   FullSimplify[Abs[u/(s t)],Assumptions->conditions],e,1];
  Do[coefficient={phases[[2]],phases[[1]],-phases[[3]]}[[i]];
   make[2inverses[[i]]/(s t),-rGamma coefficient/(e(1+e)),scales[[i]],-e,
    Hypergeometric2F1[1,1+e,2+e,inverses[[i]]]],{i,3}];
  domain=conditions&&And@@Thread[Abs[inverses]<1];
  method="CorrelatedHypergeometricInversion"
 ];
 <|"DataType"->"ResolvedMasslessBoxEndpointPowers","DimensionalRegulator"->e,
  "NormalVariables"->variables,"Invariants"->{s,t,mass},"Terms"->terms,
  "EndpointDomain"->domain,"ResolutionMethod"->method,
  "Normalization"->"d^D ell/(i pi^(D/2)); no internal dimensional scale factor",
  "UniformCornerExpansion"->True,
  "Scope"->"Positive normal coordinates near the declared corner; analytic factors require their stated endpoint domain. Interior evaluation is separate.",
  "OriginalCausalPrescription"->1|>
],"MasslessBox"];
ExpandMasslessBoxCornerJets[resolved_Association,orders:{__Integer}]:=Catch[Module[
 {e,variables,degree,terms,replace,jet},
 If[Lookup[resolved,"DataType",None]=!="ResolvedMasslessBoxEndpointPowers",
  boxFail["ResolvedBoxEndpointPowersRequired"]];
 e=resolved["DimensionalRegulator"];variables=resolved["NormalVariables"];
 If[Length[orders]=!=Length[variables]||!AllTrue[orders,#>=0&],boxFail["RectangularBoxTaylorOrdersRequired"]];
 degree=Total[orders];
 replace={
  HoldPattern[AppellF1[1,1,bb_,2,y_,w_]]:>
   Sum[y^j w^k Pochhammer[bb,k]/(Factorial[k](j+k+1)),{j,0,degree},{k,0,degree-j}],
  HoldPattern[Hypergeometric2F1[1,bb_,cc_,y_]]/;TrueQ[Expand[cc-bb]===1]:>
   (1+Sum[bb/(bb+j)y^j,{j,1,degree}])};
 terms=Map[Function[term,
  jet=Normal[Series[term["SmoothFactor"]/.replace,
    Sequence@@MapThread[{#1,0,#2}&,{variables,orders}]]];
  If[!FreeQ[jet,_Series|_SeriesData|_AppellF1|_Hypergeometric2F1|Indeterminate|_DirectedInfinity],
   boxFail["ExplicitBoxCornerJetRequired"]];
  Join[KeyDrop[term,"SmoothFactor"],<|"SmoothFactorTaylorPolynomial"->jet|>]
 ],resolved["Terms"]];
 Join[KeyDrop[resolved,"Terms"],<|"DataType"->"MasslessBoxCornerTaylorJets","TaylorOrders"->orders,
  "Terms"->terms,"ExactInEpsilon"->True,
  "TaylorRemainder"->"Omitted analytic monomials have at least one coordinate power above its stored Taylor order; expansion is locally convergent in the stated domain.",
  "Coverage"->"Corner jets only; not full edge data or interior coefficients"|>]
],"MasslessBox"];

(* Euler's integral has a polynomial numerator when c=a+1 and a is a
   positive integer. This identity is exact in the second parameter. *)
boxIntegerGauss[a_Integer?Positive,b_,z_]:=If[z===0,1,
 a/z^a Sum[(-1)^j Binomial[a-1,j]With[{lambda=Cancel[j+1-b]},
  If[lambda===0,-Log[1-z],(1-(1-z)^lambda)/lambda]],{j,0,a-1}]];
(* Keep the analytic hypergeometric functions intact while differentiating.
   Automatic special-case evaluation can create 0/0 before the face limit. *)
Derivative[0,0,0,0,m_Integer?NonNegative,n_Integer?NonNegative][boxFaceAppell][a_,b_,c_,d_,y_,z_]/;m+n>0:=
 Pochhammer[a,m+n]Pochhammer[b,m]Pochhammer[c,n]/Pochhammer[d,m+n]*
 boxFaceAppell[a+m+n,b+m,c+n,d+m+n,y,z];
Derivative[0,0,0,n_Integer?Positive][boxFaceGauss][a_,b_,c_,z_]:=
 Pochhammer[a,n]Pochhammer[b,n]/Pochhammer[c,n]*boxFaceGauss[a+n,b+n,c+n,z];
boxFaceSpecialFunctions[expression_]:=Module[{value},
 value=FixedPoint[ReplaceAll[#,{
  HoldPattern[boxFaceAppell[a_,b_,c_,d_,y_,z_]]/;TrueQ[Cancel[Together[y-z]]===0]:>
   boxFaceGauss[a,b+c,d,y],
  HoldPattern[boxFaceAppell[a_,b_,c_,d_,0,z_]]:>boxFaceGauss[a,c,d,z],
  HoldPattern[boxFaceAppell[a_,b_,c_,d_,y_,0]]:>boxFaceGauss[a,b,d,y],
  HoldPattern[boxFaceGauss[a_,b_,c_,0]]:>1,
  HoldPattern[boxFaceGauss[a_Integer?Positive,b_,c_,z_]]/;TrueQ[c===a+1]:>
   boxIntegerGauss[a,b,z]}]&,expression,4];
 value/.boxFaceGauss->Hypergeometric2F1
];
ExpandMasslessBoxFaceJets[resolved_Association,normalOrders_Association]:=FeynFacet`ExpandAnalyticEndpointFaceJets[resolved,normalOrders];
ExpandAnalyticEndpointFaceJets[resolved_Association,normalOrders_Association]:=Catch[Module[
 {variables,selected,orders,e,indices,terms,jet,conditions},
 If[!MemberQ[{"ResolvedMasslessBoxEndpointPowers","ResolvedOneLoopScalarEndpointPowers"},Lookup[resolved,"DataType",None]],
  boxFail["ResolvedBoxEndpointPowersRequired"]];
 variables=resolved["NormalVariables"];e=resolved["DimensionalRegulator"];
 selected=Keys[normalOrders];orders=Values[normalOrders];
 If[selected==={}||!ContainsAll[variables,selected]||
  !VectorQ[orders,IntegerQ[#]&&#>=0&],boxFail["DeclaredNormalFaceJetOrdersRequired"]];
 indices=Tuples[Range[0,#]&/@orders];
 terms=Map[Function[term,
  jet=Association@Table[multiIndex->(
   boxFaceSpecialFunctions[
    (Fold[D[#1,{First[#2],Last[#2]}]&,(term["SmoothFactor"]/.{Inactive[Hypergeometric2F1]->boxFaceGauss,AppellF1->boxFaceAppell,Hypergeometric2F1->boxFaceGauss}),Transpose[{selected,multiIndex}]]/
     Times@@(Factorial/@multiIndex))/.Thread[selected->0]]),
   {multiIndex,indices}];
  If[!FreeQ[jet,_Series|_SeriesData|_Derivative|_AppellF1|_boxFaceAppell|_boxFaceGauss|Indeterminate|_DirectedInfinity]||
    !FreeQ[Values[jet],Alternatives@@selected],
   boxFail["ExplicitTangentialBoxFaceJetRequired",<|"NormalVariables"->selected|>]];
  Join[KeyDrop[term,"SmoothFactor"],<|"NormalTaylorCoefficients"->jet|>]
 ],resolved["Terms"]];
 Join[KeyDrop[resolved,"Terms"],<|"DataType"->"AnalyticEndpointFaceTaylorJets",
  "FaceNormalVariables"->selected,"TangentialVariables"->Complement[variables,selected],
  "TaylorOrders"->normalOrders,"Terms"->terms,"ExactInEpsilon"->True,
  "CoefficientConvention"->"Coefficients multiply the stated normal-coordinate monomials; derivatives include their Taylor factorials.",
  "Coverage"->"The declared face, with full tangential dependence in the endpoint domain. These jets do not replace the interior density or establish cancellation of stronger powers."|>]
],"MasslessBox"];
End[];EndPackage[];
