(* Uniform expansion at vanishing recoil mass, with a fixed interior null
   fraction. The physical input is a unit-cut integral definition and the
   coordinate curve, not a process name or selected family. *)
BeginPackage["FeynFacet`"];
ConstructMeasuredRecoilBoundaryIntegral::usage="ConstructMeasuredRecoilBoundaryIntegral[chart,boundary] constructs the whole-domain leading coefficient when the timelike recoil mass vanishes at a fixed interior measured fraction. It verifies exact scale-factor or null-reference/subset denominator identities and retains the Euler integral and normalization.";
Begin["`Private`"];
measuredNormalLeading[expression_,rho_] := Module[{num,den,lo,hi},
 {num,den}=NumeratorDenominator[Together[expression]];
 If[!PolynomialQ[num,rho]||!PolynomialQ[den,rho],
  cutFamilyFail["RationalNormalDependenceRequired"]];
 If[num===0,Return[<|"Order"->Infinity,"Coefficient"->0|>]];
 lo=Exponent[num,rho,Min];hi=Exponent[den,rho,Min];
 <|"Order"->lo-hi,"Coefficient"->Factor[Coefficient[num,rho,lo]/Coefficient[den,rho,hi]]|>
];
ConstructMeasuredRecoilBoundaryIntegral[chart_Association,boundary_Association]:=
 Catch[Module[
 {rho,rules,assumptions,d,cm,p,total,e,z,s,j,sData,jData,normalization,nData,
  core,coreCurve,coreData,proofs=<||>,subsets,candidate,matched,kin,dot,nu,
  scalarLeading=1,scalarOrder=0,prefactor,exponent,curveCores,coefficient,i},
 If[Lookup[chart,"DataType",None]=!="MeasuredThreeParticleIntegral",
  cutFamilyFail["MeasuredThreeParticleIntegralRequired"]];
 rho=Lookup[boundary,"NormalVariable",None];rules=Lookup[boundary,"SourceVariableSubstitution",{}];
 assumptions=Lookup[boundary,"Assumptions",True];
 If[!MatchQ[rho,_Symbol]||!MatchQ[rules,{__Rule}]||assumptions===False,
  cutFamilyFail["PhysicalNormalCoordinateCurveRequired"]];
 d=chart["Definition"];cm=d["OrientedCutMomenta"];p=d["SourceCutDefinition"]["ReferenceMomentum"];
 total=Expand[Total[cm]];e=chart["DimensionalRegulator"];z=chart["MeasurementVariable"];
 kin=d["KinematicRules"];nu=d["PropagatorPowers"];
 If[!FreeQ[{z,chart["BetaShapes"],Lookup[chart,"RegularMeasureFactor",1]}/.rules,rho],cutFamilyFail["FixedTangentialMeasurementRequired"]];
 s=Factor[chart["InvariantMassSquared"]/.rules];j=Factor[chart["ReferenceProjectionTwice"]/.rules];
 sData=measuredNormalLeading[s,rho];jData=measuredNormalLeading[j,rho];
 If[!IntegerQ[sData["Order"]]||sData["Order"]<1||jData["Order"]=!=0||
  !cutConvergenceProve[sData["Coefficient"]>0&&jData["Coefficient"]>0,assumptions],
  cutFamilyFail["VanishingTimelikeRecoilAndFiniteNullProjectionRequired"]];
 If[!TrueQ[chart["ConvergenceCertificate"]["UniformGramDomination"]],
  cutFamilyFail["ParentCompactCutConvergenceRequired"]];
 normalization=chart["MeasureConversionFactor"]/.rules;
 nData=measuredNormalLeading[normalization,rho];
 If[!IntegerQ[nData["Order"]],cutFamilyFail["FiniteRationalMasterNormalizationRequired"]];
 dot[a_,b_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[a,b]]]/.kin];
 subsets=Total[cm[[#]]]&/@Rest[Most[Subsets[Range[3]]]];
 curveCores=Lookup[chart,"RationalInversePropagatorExpressions",chart["InversePropagatorExpressions"]]/.rules;
 Do[
  If[nu[[i]]===0,Continue[]];
  core=d["InversePropagators"][[i]];coreCurve=curveCores[[i]];
  coreData=measuredNormalLeading[coreCurve,rho];
  If[!IntegerQ[coreData["Order"]]||coreData["Coefficient"]===0,
   cutFamilyFail["NonzeroLeadingOrdinaryFactorRequired"]];
  scalarLeading*=coreData["Coefficient"]^-nu[[i]];
  scalarOrder-=nu[[i]]coreData["Order"];
  If[nu[[i]]<0,
   AssociateTo[proofs,i-><|"Type"->"PolynomialNumerator","NormalOrder"->coreData["Order"]|>];Continue[]];
  Which[
   FreeQ[Cancel[coreCurve/s],rho],
    AssociateTo[proofs,i-><|"Type"->"ExactRecoilScaleFactor","NormalOrder"->coreData["Order"]|>],
   FreeQ[Cancel[coreCurve/j],rho],
    AssociateTo[proofs,i-><|"Type"->"ExactNullProjectionFactor","NormalOrder"->coreData["Order"]|>],
   True,
    matched=None;
    Do[candidate=dot[p-subset,p-subset];
     If[AnyTrue[{1,-1},epsOrderZero[core-# candidate]&],
      matched=subset;Break[]],{subset,subsets}];
    If[matched===None,cutFamilyFail["UniformRecoilDenominatorExpansionNotEstablished",
     <|"PropagatorIndex"->i,"InversePropagator"->core|>]];
    AssociateTo[proofs,i-><|"Type"->"NullReferenceMinusFutureSubset","SubsetMomentum"->matched,
     "NormalOrder"->coreData["Order"],
     "UniformRatioBound"->"0 <= (K^2/S)/(2 p.K/J) <= 1 on the forward particle domain. The ratio S/J tends to zero, so the binomial expansion and every fixed Taylor remainder are uniformly bounded."|>]
  ],{i,chart["OrdinaryIndices"]}];
 exponent=sData["Order"](1-2e)+nData["Order"]+scalarOrder;
 prefactor=nData["Coefficient"]FeynFacet`MasslessMeasuredPhaseSpace[3,sData["Coefficient"],z,e];
 <|"DataType"->"MeasuredRecoilBoundaryIntegral","MasterIntegral"->chart["MasterIntegral"],
  "NormalVariable"->rho,"NormalExponent"->exponent,
  "RegulatorSlope"->Coefficient[exponent,e],
  "Parameters"->chart["Parameters"],"DimensionalRegulator"->e,"MeasurementVariable"->z,
  "Prefactor"->prefactor,"ScalarIntegrand"->Factor[scalarLeading],
  "NormalizedMeasureFactors"->chart["NormalizedMeasureFactors"],"BetaShapes"->chart["BetaShapes"],
  "AngularAxis"->Lookup[chart,"AngularAxis","ReferenceMomentum"],
  "AngularFractionSymbol"->Lookup[chart,"AngularFractionSymbol",None],
  "AngularFractionExpression"->Lookup[chart,"AngularFractionExpression",None],
  "RegularMeasureFactor"->(Lookup[chart,"RegularMeasureFactor",1]/.rules),
  "ParameterDomain"->chart["ParameterDomain"],"KinematicConditions"->assumptions,
  "DenominatorCertificates"->proofs,"SourceVariableSubstitution"->rules,
  "UniformAnalyticFactorization"->True,
  "FactorizationStatement"->"The original integral is rho^NormalExponent times a function analytic in rho near zero in a common sufficiently large-D convergence domain; continue the coefficients meromorphically in dimension.",
  "Scope"->"Fixed interior measured fraction. No interchange of recoil and measurement-endpoint limits.",
  "NormalizationConvention"->"The original declared integral measure, including its exact loop routing and measurement Jacobian."|>
 ],"CutFamily"];

FeynFacet`ConstructMeasuredCornerBoundaryTerms::usage =
 "ConstructMeasuredCornerBoundaryTerms[recoilBoundary] evaluates the leading ordinary and additive-denominator endpoint branches as the measured fraction tends to one after the recoil limit. Supported rotated angular factors are recognized exactly; both regulator exponents and the next omitted order of each branch are retained.";

measuredRadialBetaMoment[expression_,r_,alpha_,shift_] := Module[
 {expanded,terms,answer=0,data},
 expanded=Expand[Apart[expression,r]];
 terms=If[Head[expanded]===Plus,List@@expanded,{expanded}];
 Do[
  data=sphericalBetaMonomial[term,{r}];
  If[FailureQ[data],Return[data,Module]];
  answer+=data["Constant"]Beta[alpha+shift+data["Exponents"][[1,1]],
   alpha+data["Exponents"][[1,2]]]/Beta[alpha,alpha],
 {term,terms}];answer
];

(* Taylor coefficients of the azimuthal average, before the endpoint
   scaling u=lambda r v. Odd cosine powers vanish; even powers are retained.
   This includes the square-root angular variation without introducing roots
   into the coefficient algebra. *)
measuredAngularTaylorCoefficient[a_,r_,y_,alpha_,order_Integer] := Module[
 {answer=0,l,m,j,weight},
 Do[
  weight=Sum[j=order-l+m;
   If[0<=j<=m,Binomial[l,2m](1-2r)^(l-2m)(4r(1-r))^m*
     Pochhammer[1/2,m]/Pochhammer[alpha,m]*(-1)^j Binomial[m,j],0],
   {m,0,Floor[l/2]}];
  If[weight=!=0,answer+=weight/Factorial[l](D[a,{y,l}]/.y->r)],
 {l,0,2order}];
 Together[answer]
];

measuredWeightedEndpointTerms[scalar_,pref_,h_,{z_,r_,u_,y_,e_},request_] := Module[
 {lambda=Unique["endpointRatio"],alpha=1-e,zvalue,radial,rational,lambdaLow,uLow,
  smooth,lambdaJets=<||>,coefficientCache=<||>,angularCache=<||>,getCoefficient,getAngular,
  requested,limit,degree,j,k,p,coefficient,radialValue,total,base,values=<||>,
  found=False,target,terms={},sigmaOrder,value,converted},
 zvalue=1/(1+lambda);radial=zvalue+(1-zvalue)r;
 rational=Cancel[(scalar (z u+(1-z)r)^h pref)/.z->zvalue];
 lambdaLow=measuredNormalLeading[rational,lambda]["Order"];
 uLow=measuredNormalLeading[rational,u]["Order"];
 If[!IntegerQ[lambdaLow]||!IntegerQ[uLow],
  Return[Failure["FiniteWeightedEndpointOrdersRequired",<||>]]];
 smooth=rational/(lambda^lambdaLow u^uLow)*
   zvalue^(1-2e-h)radial^(-2alpha)(1-u)^(alpha-1);
 getCoefficient[jj_,pp_]:=If[KeyExistsQ[coefficientCache,{jj,pp}],
   coefficientCache[[Key[{jj,pp}]]],
   If[!KeyExistsQ[lambdaJets,jj],AssociateTo[lambdaJets,jj->SeriesCoefficient[smooth,{lambda,0,jj}]]];
   With[{answer=Together[SeriesCoefficient[lambdaJets[jj],{u,0,pp}]]},
    AssociateTo[coefficientCache,{jj,pp}->answer];answer]];
 getAngular[expression_,kk_]:=If[KeyExistsQ[angularCache,{expression,kk}],
   angularCache[[Key[{expression,kk}]]],
   With[{answer=measuredAngularTaylorCoefficient[expression,r,y,alpha,kk]},
    AssociateTo[angularCache,{expression,kk}->answer];answer]];
 requested=Lookup[request,"EndpointSeriesOrder",Automatic];
 limit=Lookup[request,"MaximumEndpointJetOrder",8];
 If[!(requested===Automatic||IntegerQ[requested]&&requested>=0)||
   !IntegerQ[limit]||limit<0,
  Return[Failure["NonnegativeEndpointJetOrderRequired",<||>]]];
 target=If[requested===Automatic,limit,requested];
 base=lambdaLow+alpha+uLow-h;
 Do[
  total=0;
  Do[k=degree-j;
   coefficient=Sum[getAngular[getCoefficient[j,p],k-p],{p,0,k}];
   If[epsOrderZero[coefficient],Continue[]];
   radialValue=measuredRadialBetaMoment[coefficient,r,alpha,alpha+uLow+k-h];
   If[FailureQ[radialValue],Return[radialValue,Module]];
   total+=Gamma[alpha+uLow+k]Gamma[h-alpha-uLow-k]/
    (Gamma[h]Beta[alpha,alpha])radialValue,
   {j,0,degree}];
  total=Together[FunctionExpand[total]];AssociateTo[values,degree->total];
  If[!epsOrderZero[total],found=True];
  If[requested===Automatic&&found,Break[]],
 {degree,0,target}];
 If[requested===Automatic&&!found,
  Return[Failure["EndpointLeadingCoefficientRequiresFurtherAngularJets",
   <|"ComputedJetOrder"->target,"Coefficients"->values|>]]];
 target=Max[Keys[values]];
 (* lambda= sigma/(1-sigma). Collect equal sigma powers only after all
    lambda/u terms of the same weighted degree have been included. *)
 Do[
  converted=Sum[values[j]Pochhammer[base+j,sigmaOrder-j]/Factorial[sigmaOrder-j],
   {j,0,sigmaOrder}];
  AppendTo[terms,<|"Branch"->"AdditiveDenominatorEndpoint",
   "Exponent"->1-2e+base+sigmaOrder,"Value"->converted,
   "NextPossibleOrder"->1-2e+base+target+1|>],
 {sigmaOrder,0,target}];
 <|"Terms"->terms,"WeightedLambdaOrder"->lambdaLow,"WeightedAngularOrder"->uLow,
  "ComputedWeightedJetOrder"->target,
  "Derivation"->"Joint lambda/u Taylor coefficients after the exact azimuthal average, followed by the meromorphically continued Euler endpoint coefficient. All j+k contributions are collected. lambda=(1-z)/z.",
  "RemainderCertifiedThrough"->None|>
];

FeynFacet`ConstructMeasuredCornerBoundaryTerms[boundary_Association,request_Association:<||>] := Catch[Module[
 {e,z,r,u,y,sigma,alpha,scalar,allowed,factors,gauge,h=0,q,k,rat,found,
  normal,core,hard,hardExponent,pref,prefData,terms,removed,polar,extra,value,radial,
  reverseGauge,reversePower=0,sourceScalar,ordinaryOrder,scalarJet,smoothJet,j,weighted},
 If[Lookup[boundary,"DataType",None]=!="MeasuredRecoilBoundaryIntegral"||
   Lookup[boundary,"AngularAxis",None]=!="TaggedParticle"||
   !TrueQ[Lookup[boundary,"UniformAnalyticFactorization",False]],
  cutFamilyFail["UniformRotatedRecoilBoundaryRequired"]];
 {e,z}=Lookup[boundary,{"DimensionalRegulator","MeasurementVariable"}];
 {r,u}=Take[boundary["Parameters"],2];y=boundary["AngularFractionSymbol"];
 alpha=1-e;sigma=Unique["measurementEndpoint"];
 ordinaryOrder=Lookup[request,"MaximumOrdinarySeriesOrder",0];
 If[!IntegerQ[ordinaryOrder]||ordinaryOrder<0,
  cutFamilyFail["NonnegativeOrdinaryEndpointOrderRequired"]];
 sourceScalar=boundary["ScalarIntegrand"];scalar=sourceScalar;
 If[!FreeQ[scalar,Last[boundary["Parameters"]]]||
   !AllTrue[NumeratorDenominator[Together[scalar]],PolynomialQ[#,{z,r,u,y}]&],
  cutFamilyFail["RationalFullScalarAngularGeneratorsRequired"]];
 gauge=z u+(1-z)r;reverseGauge=z(1-u)+(1-z)r;
 factors=Rest[FactorList[Denominator[Cancel[scalar]]]];
 Do[
  If[FreeQ[Cancel[First[factor]/reverseGauge],Alternatives[r,u,y]],
   reversePower+=Last[factor]],{factor,factors}];
 If[reversePower>0,
  scalar=scalar/.{u->1-u,y->1-y}];
 allowed={r,u,1-u,y,1-y,z,1-z,z+(1-z)r,1-(1-z)y,z+(1-z)y,gauge};
 factors=Rest[FactorList[Denominator[Cancel[scalar]]]];
 Do[
  {q,k}=factor;
  If[FreeQ[q,Alternatives[r,u,y]],Continue[]];
  found=SelectFirst[allowed,FreeQ[Cancel[q/#],Alternatives[r,u,y]]&,None];
  If[found===None,cutFamilyFail["MeasuredCornerDenominatorUnsupported",<|"Factor"->q|>]];
  If[found===gauge,h+=k],
 {factor,factors}];
 (* All other positive factors reduce to r,u,1-u,y,1-y and smooth
    positive factors 1-sigma v. The latter have uniform Taylor remainders. *)
 normal=measuredNormalLeading[scalar/.z->1-sigma,sigma];
 core=normal["Coefficient"];
 hard=FeynFacet`EvaluateSphericalBetaMoment[core,{r,u,y},alpha];
 If[FailureQ[hard],Throw[hard,"CutFamily"]];
 pref=PowerExpand[boundary["Prefactor"]/(z^-e(1-z)^(1-2e))];
 prefData=measuredNormalLeading[pref/.z->1-sigma,sigma];
 hardExponent=1-2e+prefData["Order"]+normal["Order"];
 terms={<|"Branch"->"Ordinary","Exponent"->hardExponent,
   "Value"->prefData["Coefficient"]hard,"NextPossibleOrder"->hardExponent+ordinaryOrder+1|>};
 If[ordinaryOrder>0,
  scalarJet=Table[Cancel[SeriesCoefficient[(scalar/.z->1-sigma)/sigma^normal["Order"],
    {sigma,0,j}]],{j,0,ordinaryOrder}];
  smoothJet=Table[SeriesCoefficient[(pref/.z->1-sigma)/sigma^prefData["Order"]*
    (1-sigma)^(1-2e)(1-sigma+sigma r)^(-2+2e),{sigma,0,j}],{j,0,ordinaryOrder}];
  Do[
   hard=FeynFacet`EvaluateSphericalBetaMoment[
    Sum[scalarJet[[j+1]]smoothJet[[k-j+1]],{j,0,k}],{r,u,y},alpha];
   If[FailureQ[hard],Throw[hard,"CutFamily"]];
   AppendTo[terms,<|"Branch"->"Ordinary","Exponent"->hardExponent+k,
    "Value"->hard,"NextPossibleOrder"->hardExponent+ordinaryOrder+1|>],
   {k,1,ordinaryOrder}]];
 If[h>0,
  weighted=measuredWeightedEndpointTerms[scalar,pref,h,{z,r,u,y,e},request];
  If[FailureQ[weighted],Throw[weighted,"CutFamily"]];
  terms=Join[terms,weighted["Terms"]]];

 <|"DataType"->"MeasuredCornerBoundaryTerms","MasterIntegral"->boundary["MasterIntegral"],
  "MeasurementVariable"->z,"DimensionalRegulator"->e,"EndpointDistance"->1-z,
  "RecoilExponent"->boundary["NormalExponent"],"Terms"->terms,
  "AllowedRegulatorSlopes"->If[h===0,{-2},{-2,-3}],
  "EndpointWeightedExpansion"->If[h===0,None,weighted],
  "RemainderCertifiedThrough"->None,
  "AdditiveDenominatorPower"->h,"AngularAxesReversed"->(reversePower>0),
  "AngularReversal"->If[reversePower>0,{u->1-u,y->1-y,Last[boundary["Parameters"]]->1-Last[boundary["Parameters"]]},{}],
  "Scope"->"Ordered recoil then measured-fraction endpoint. Generic regulator; branches are matched before expanding in epsilon.",
  "Derivation"->If[h===0,
   "Uniform Taylor expansion of smooth positive factors and exact spherical convolution in the common convergence domain.",
   "Uniform expansion of smooth factors, then the two Mellin pole families w=n and w=alpha-b-h+n of the single additive angular denominator. The angular 3F2 excesses are 2alpha-a-b-h-m and 2alpha-a-c-m+w; they remain positive on the initial high-D right contour strips. Contour separation is preserved under meromorphic continuation. This establishes the allowed slopes and coefficient residues, not a numerical truncation-error bound."],
  "Normalization"->"All declared measure factors and the rotated chart Jacobian are retained; the latter tends to one at this endpoint."|>
 ],"CutFamily"];
End[];EndPackage[];
