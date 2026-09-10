(* Laurent bounds and finite cut normal derivatives; convergence is owned by Integrals/Convergence.wl. *)
Begin["FeynFacet`Private`"];

cutOrderNormalDerivatives[d_] := Module[
 {p=d["BaikovPolynomial"],a=d["BaikovExponent"],z=d["IntegrationVariables"],
  cuts=d["CutIndices"],nu=d["PropagatorPowers"],terms=<|0->1|>,next,zero,fac=1,degree,poly},
 Do[
  fac=fac (nu[[j]]-1)!;
  Do[
   next=<||>;
   KeyValueMap[Function[{shift,numerator},
    AssociateTo[next,shift->(Lookup[next,shift,0]+D[numerator,z[[j]]])];
    AssociateTo[next,(shift+1)->(Lookup[next,shift+1,0]+
      (a-shift) numerator D[p,z[[j]]])]],terms];
   terms=Select[Map[Expand,next],!epsOrderZero[#]&],
  {repeat,nu[[j]]-1}],
 {j,cuts}];
 zero=Thread[z[[cuts]]->0];p=Factor[p/.zero];
 If[epsOrderZero[p],epsOrderFail["CutSurfaceHasNoGramInterior"]];
 <|"IntegrationVariables"->Delete[z,List /@ cuts],"Polynomial"->p,
  "DomainConditions"->(d["DomainConditions"]/.zero),
  "Prefactor"->d["ParametricPrefactor"]/fac,
  "Terms"->KeyValueMap[<|"GramPowerShift"->#1,"Exponent"->a-#1,
    "Numerator"->Factor[#2/.zero]|>&,terms],
  "NormalDerivativeOrder"->Total[nu[[cuts]]-1]|>
];



(* Exact dimensional analysis removes one positive homogeneous scale for
   order determination. Every scalar product and inverse polynomial must
   scale together; a sampled value alone is never a proof of scale
   independence. The returned factor restores the original integral. *)
cutOrderScaleNormalization[d_,g_,e_] := Module[
 {scales,t,sp,polys,pref,degree,exponent,normalized,answer=None},
 scales=Select[Variables[Flatten[g["ExternalGramMatrix"]]],
  MatchQ[#,_Symbol]&&#=!=e&];
 sp=cutConvergenceCoordinates[d];t=Unique["positiveScaleRatio"];
 polys=d["InversePropagators"];
 pref=d["MasterIntegralPrefactor"]d["MeasurePrefactor"];
 Do[
  If[!cutConvergenceProve[scale>0,d["KinematicConditions"]],Continue[]];
  If[!AllTrue[Flatten[(g["ExternalGramMatrix"]/.scale->t scale)-t g["ExternalGramMatrix"]],epsOrderZero],
   Continue[]];
  If[!AllTrue[(polys/.Thread[sp->t sp]/.scale->t scale)-t polys,epsOrderZero],Continue[]];
  degree=Cancel[scale D[pref,scale]/pref];
  If[!FreeQ[degree,scale]||!IntegerQ[epsOrderValuation[degree,e]]&&degree=!=0,Continue[]];
  If[!TrueQ[FullSimplify[(pref/.scale->1)scale^degree==pref,
    Assumptions->d["KinematicConditions"]&&Element[e,Reals]]],Continue[]];
  exponent=Length[d["LoopMomenta"]]d["Dimension"]/2-Total[d["PropagatorPowers"]]+degree;
  If[!FreeQ[exponent,scale]||!TrueQ[epsOrderValuation[scale^exponent,e]===0],Continue[]];
  normalized=d/.scale->1;
  If[!TrueQ[FullSimplify[normalized["KinematicConditions"]]],Continue[]];
  normalized=Join[normalized,<|"KinematicConditions"->True|>];
  answer=<|"Scale"->scale,"ScaleSquaredMomentumDegree"->exponent,
   "IntegralScalingFactor"->scale^exponent,"NormalizedDefinition"->normalized,
   "ScalingRules"->{scale->1},"LaurentValuationOfScalingFactor"->0,
   "Proof"->"Every external Gram entry and inverse polynomial is homogeneous of degree one under simultaneous squared-momentum scaling. The loop measures have degree L D/2, each powered cut or ordinary factor degree -nu, and the explicit measure and master prefactors supply their verified Euler degree. The positive scale factor is regular and nonzero in epsilon."|>;
  Break[],
 {scale,scales}];answer
];

(* A finite normal derivative on a measured slice is taken in the common
   high-D domain before meromorphic continuation. Nonempty strict interior
   verifies the residual dimension; it does not prove a regular parameter
   chamber or uniformity at external endpoints. *)
cutOrderMeasuredSlice[d_,nd_,certificate_,seconds_] := Module[
 {xs=nd["IntegrationVariables"],condition,witness,decision,measurements},
 measurements=Lookup[d,"MeasurementCutIndices",{}];
 If[measurements==={},Return[<||>]];
 If[!TrueQ[certificate["UniformGramDomination"]],
  epsOrderFail["UniformParentGramDominationRequired"]];
 condition=nd["DomainConditions"] && nd["Polynomial"]>0;
 If[xs==={},
  If[!TrueQ[condition],epsOrderFail["StrictMeasuredSliceInteriorNotEstablished"]];
  witness={},
  witness=TimeConstrained[With[{variables=xs,physicalCondition=condition},
   Quiet[FindInstance[physicalCondition,variables,Reals]]],seconds,$TimedOut];
  If[!MatchQ[witness,{{__Rule}}]||!TrueQ[FullSimplify[condition/.First[witness]]],
   epsOrderFail["StrictMeasuredSliceInteriorNotEstablished",<|"Condition"->condition|>]];
  witness=First[witness]];
 <|"MeasurementCutCount"->Length[measurements],"StrictInteriorWitness"->witness,
   "FixedFiberLaurentBoundEstablished"->True,
   "FixedFiberDefinition"->"The finite cut-normal derivatives of the high-D forward-domain integral, continued meromorphically in dimension.",
   "PointwiseRegulatedConvergenceEstablished"->False,
   "RegularParameterChamberEstablished"->False,
   "ExternalEndpointUniformityEstablished"->False,
   "NormalDerivativeJustification"->"Uniform parent Gram domination bounds all finite normal derivatives on one compact box. At sufficiently large Re(D), the required jets vanish on the moving Gram and energy boundaries; differentiating the zero extension gives the interior derivatives. Particle derivatives keep the common nonnegative-mass tip continuation.",
   "Scope"->"Fixed measurement slice; no statement about exceptional-point contact terms or endpoint distribution coefficients."|>
];

cutOrderPoleBound[d_,e_,seconds_] := Module[
 {g,certificate,rd,nd,n,a,alpha0,slope,prefVal,ordinary,maximumShift,num,poly,nu,
  zero,termVal,lower,statement,slice,scaleNormalization,normalizedBound},
 certificate=cutIntegralConvergenceCertificate[d,seconds];
 g=certificate["Geometry"];
 If[!TrueQ[d["KinematicConditions"]],
  scaleNormalization=cutOrderScaleNormalization[d,g,e];
  If[AssociationQ[scaleNormalization],
   normalizedBound=cutOrderPoleBound[scaleNormalization["NormalizedDefinition"],e,seconds];
   Return[Join[normalizedBound,<|"Representation"->d,
    "HomogeneousScaleNormalization"->KeyDrop[scaleNormalization,"NormalizedDefinition"]|>]]]];
 rd=cutOrderReduceExternal[d,g];
 If[!TrueQ[rd["KinematicConditions"]],epsOrderFail["PhysicalKinematicConditionsNotEstablished"]];
 nd=cutOrderNormalDerivatives[rd];n=Length[nd["IntegrationVariables"]];
 slice=cutOrderMeasuredSlice[rd,nd,certificate,seconds];
 a=rd["BaikovExponent"];alpha0=Limit[a,e->0];slope=epsOrderValuation[Cancel[a-alpha0],e];
 If[slope===Infinity || !IntegerQ[slope] || slope<1,
  epsOrderFail["NonconstantDimensionRegulatorRequired"]];
 If[!FreeQ[nd["Polynomial"],e],epsOrderFail["RegulatorIndependentGramPolynomialRequired"]];
 prefVal=epsOrderValuation[nd["Prefactor"],e];
 maximumShift=Max[Prepend[Lookup[nd["Terms"],"GramPowerShift"],0]];
 poly=nd["Polynomial"];
 num=Factor[Total[(#["Numerator"] poly^(maximumShift-#["GramPowerShift"])& /@ nd["Terms"])]];
 ordinary=Times@@Table[If[MemberQ[rd["CutIndices"],j],1,
   rd["IntegrationVariables"][[j]]^-rd["PropagatorPowers"][[j]]],
  {j,Length[rd["PropagatorPowers"]]}];
 termVal=epsOrderValuation[num,e];
 lower=If[termVal===Infinity,Infinity,prefVal+termVal-n slope];
 <|"DataType"->"IntegralLaurentBound","Status"->"BoundEstablishedForRepresentation",
  "LowerBound"->lower,"Representation"->d,
  "Method"->"CompactSemialgebraicPoleMultiplicityBound",
  "EffectiveExternalRank"->g["EffectiveExternalRank"],
  "RemainingIntegrationDimension"->n,"RegulatorSlopeValuation"->slope,
  "PrefactorLaurentValuation"->prefVal,"NumeratorLaurentValuation"->termVal,
  "ConvergenceCertificate"->Join[certificate,slice],
  "CutIntegralTerms"-><|"IntegrationVariables"->nd["IntegrationVariables"],
    "Prefactor"->nd["Prefactor"],"RationalFactor"->num ordinary,
    "Polynomial"->poly,"Exponent"->a-maximumShift,
    "DomainConditions"->nd["DomainConditions"],
    "ExternalBasisDefinition"->rd["ExternalBasisDefinition"],
    "NormalDerivativeOrder"->nd["NormalDerivativeOrder"]|>,
  "PoleMultiplicityArgument"->"After normal derivatives in a convergence half-plane, compact semialgebraic normal-crossing resolution has at most n integration coordinates. Every singular divisor is regulated by the Gram power, so each coordinate contributes at most the valuation of its regulator slope. Explicit prefactor and numerator valuations are included.",
  "SectorResolutionPerformed"->False,"IntegralValuesEvaluatedNumerically"->False,
  "BoundIsSufficientNotNecessarilySharp"->True|>
];


End[];
