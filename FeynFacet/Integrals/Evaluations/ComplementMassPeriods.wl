(* Universal scalar periods with complementary invariant masses Q_i=(q-p_i)^2.
   The cut, family measure and labels are matched from typed data. No amplitude,
   energy weight, tuple multiplicity or measured hard coefficient is present. *)
BeginPackage["FeynFacet`"];
EvaluatePairComplementMassPeriod::usage="EvaluatePairComplementMassPeriod[family,integral,epsilon] returns proved finite epsilon coefficients for supported unit-cut four-particle pair-measurement periods containing complementary masses (q-p_i)^2. One untagged complement with nonnegative powers of the tagged pair mass, two tagged complements, and a mixed tagged/untagged pair are holomorphic at epsilon zero. Two untagged complements return only their simple-pole residue, with coverage through -1. Exact normalization and the original prescription certificate are retained; measurement endpoint distributions remain unresolved.";
Begin["`Private`"];
Clear[pairComplementGPLPeriod];
pairComplementGPLPeriod[class_,power_Integer]:=pairComplementGPLPeriod[class,power]=Module[
 {p=Unique["complementParameter$"],t=Unique["complementIntegration$"],logarithm,kernel,value,first,second},
 If[DownValues[FeynFacetSolution`IntegrateGPL]==={},
  Block[{$ContextPath=$ContextPath},Get[FileNameJoin[{$feynFacetDirectory,"Solution.m"}]]]];
 logarithm=Log[(1-p^2 t^2)/(p(1-t^2))];
 kernel=Switch[class,
  "SingleUntaggedComplement",(1-t^2)^power/(1-p^2 t^2)^(power+1) logarithm,
  "MixedComplements",logarithm*(
   Log[(1-p)(1-t)/(2(1+p t))]/((1+t)(1-p t))+
   Log[(1-p)(1+t)/(2(1-p t))]/((1-t)(1+p t))),
  _,Return[Failure["UnsupportedComplementMassGPLKernel",<||>]]];
 (* Two paths end at an ordinary interior point. The second starts at t=1
    after t->1-t, so logarithmic endpoint cancellations are taken together. *)
 first=FeynFacetSolution`IntegrateGPL[kernel,{t,0,1/2},"Assumptions"->0<p<1,"TimeLimit"->120];
 second=FeynFacetSolution`IntegrateGPL[kernel/.t->1-t,{t,0,1/2},"Assumptions"->0<p<1,"TimeLimit"->120];
 If[AnyTrue[{first,second},FailureQ],Return[Failure["ComplementMassGPLIntegrationFailed",<|"Causes"->{first,second}|>]]];
 value=first+second;
 If[!FreeQ[value,_FeynFacetSolution`IntegrateGPL|_Integrate|_Inactive|Indeterminate|_DirectedInfinity],
  Return[Failure["ExplicitFiniteComplementMassCoefficientRequired",<||>]]];
 <|"Expression"->value,"Parameter"->p|>
];
EvaluatePairComplementMassPeriod[family_Association,integral_FeynCalc`GLI,e_Symbol]:=Catch[Module[
 {data,definition,ordinary,chart,coordinates,push,branch,parameters,r,x,y,a,b,s,root,x2,
  kernel,qm,pairMass,jacobianRatio,normalization,scalar,classification=None,ratio,power,
  types,support,candidate,certificate,valuation,coefficient,order,primitive,p,chi,c0,proof},
 data=pairMeasurementIntegralCharts[family,integral,e];
 {definition,ordinary,s,parameters}=Lookup[data,{"Definition","OrdinaryIndices","Scale","Parameters"}];
 {r,x,y,a,b}=parameters;
 chart=First[data["Charts"]];{coordinates,push,branch}=Lookup[chart,{"Coordinates","Pushforward","Branch"}];
 root=branch["Root"];x2=(1-x)y/(1-root x);
 jacobianRatio=Cancel[Together[branch["Jacobian"]s^2 x x2/2]];
 If[!FreeQ[jacobianRatio,Alternatives@@parameters],cutFamilyFail["ConstantRelativePolynomialCutNormalizationRequired"]];
 kernel=Times@@MapThread[Power,{definition["InversePropagators"][[ordinary]],-integral[[2,ordinary]]}];
 kernel=Cancel[Together[kernel/.branch["ScalarProductRules"]]];
 qm=Factor/@(s(1-coordinates["EnergyFractions"])/.branch["EliminationRule"]);
 pairMass=s root x x2;
 types={{"SingleUntaggedComplement",{3}},{"SingleUntaggedComplement",{4}},
  {"TwoTaggedComplements",{1,2}},{"MixedComplements",{1,3}},{"MixedComplements",{1,4}},
  {"MixedComplements",{2,3}},{"MixedComplements",{2,4}},{"TwoUntaggedComplements",{3,4}}};
 Do[
  Do[
   ratio=Cancel[Together[kernel Times@@qm[[candidate[[2]]]]/pairMass^power]];
   If[FreeQ[ratio,Alternatives@@parameters],classification={First[candidate],power};scalar=ratio;Break[]],
   {power,0,If[First[candidate]==="SingleUntaggedComplement",Max[0,-Total[Select[integral[[2,ordinary]],Negative]]],0]}];
  If[classification=!=None,Break[]],{candidate,types}];
 If[classification===None,cutFamilyFail["ComplementMassPeriodOutsideSupportedClasses"]];
 certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[definition,integral,
  <|"ExternalKinematicConditions"->definition["Assumptions"],"DimensionalRegulator"->e|>];
 If[!AssociationQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
  cutFamilyFail["OriginalComplementMassPrescriptionCertificateRequired",<|"Cause"->certificate|>]];
 normalization=jacobianRatio scalar(data["PureCutDefinition"]["MeasurePrefactor"]/(2Pi)^(4-3D))/.D->4-2e;
 valuation=FeynFacet`DetermineMeromorphicLaurentLowerBound[normalization,e];
 If[!(IntegerQ[valuation]&&valuation>=0),cutFamilyFail["HolomorphicComplementMassNormalizationRequired"]];
 normalization=Limit[normalization,e->0];
 c0=FeynFacet`MasslessResolvedPairDensityFactor[4]FeynFacet`MasslessPhaseSpaceVolume[2,1,0];
 If[!NumericQ[c0]||!FreeQ[c0,_Real|_Complex],cutFamilyFail["ExplicitAbsolutePhaseSpaceNormalizationRequired"]];
 p=(1-Sqrt[1-root])/(1+Sqrt[1-root]);power=Last[classification];order=0;
 coefficient=Switch[First[classification],
  "SingleUntaggedComplement",If[power===0,
   2c0/(s root)(2PolyLog[2,root]+Log[root]Log[1-root]),
   primitive=pairComplementGPLPeriod["SingleUntaggedComplement",power];
   If[!AssociationQ[primitive],Throw[primitive,"CutFamily"]];
   2c0 s^(power-1)(1+p)^2 p^power/(2power+1)*(primitive["Expression"]/.primitive["Parameter"]->p)],
  "TwoTaggedComplements",2c0/s^2(Zeta[2]+PolyLog[2,root]+Log[1-root]^2/2),
  "MixedComplements",primitive=pairComplementGPLPeriod["MixedComplements",0];
   If[!AssociationQ[primitive],Throw[primitive,"CutFamily"]];
   -2c0/s^2(1+p)*(primitive["Expression"]/.primitive["Parameter"]->p),
  "TwoUntaggedComplements",order=-1;chi=(1-Sqrt[root])/(1+Sqrt[root]);
   -c0/(s^2 Sqrt[root])(Pi^2/4+PolyLog[2,-chi]-PolyLog[2,chi])];
 coefficient=normalization coefficient;
 If[!FreeQ[coefficient,_FeynCalc`GLI|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity],
  cutFamilyFail["ExplicitComplementMassCoefficientRequired"]];
 proof=<|"InteriorRegulatorStrip"->Abs[Re[e]]<1/4,
  "ExternalScope"->"Locally uniform on compact subintervals of the physical pair angle and positive scale.",
  "RadialCoordinates"->"x1=u*v,x2=u*(1-v),u=2*tau/(1+sqrt(1-4*z*v*(1-v))).",
  "AngularMajorant"->"For fixed 0<delta<1/4, the normalized massive angular average is bounded by C_delta [v(1-v)]^-delta.",
  "MixedCornerMajorant"->"w^-3delta eta^-delta/(w+eta), w=1-v, eta=1-tau; after radial blow-up the power is -4delta > -1.",
  "PoleSubtraction"->If[order===-1,
   "The u radial power tau^(-1-4epsilon) is subtracted before expansion. Its constant endpoint gives -1/(4epsilon); the subtracted remainder is holomorphic on the stated strip.",None]|>;
 <|"Integral"->integral,"DimensionalRegulator"->e,"Coefficients"-><|order->coefficient|>,
  "LaurentLowerBound"->order,"KnownThroughOrder"->order,"ExactTail"->False,
  "Method"->"UniversalComplementMassPeriod","PeriodClass"->First[classification],
  "TaggedPairNumeratorPower"->power,"ParticleOrder"->chart["ParticleOrder"],
  "OriginalOrdinaryPrescriptionCertificate"->certificate,"ConvergenceProof"->proof,
  "PhysicalBoundaryConstantsFixedForStoredOrders"->True,"EndpointDistributionIncluded"->False,
  "Domain"->definition["Assumptions"]&&0<root<1,
  "Scope"->"Only the declared Laurent coefficient is supplied. No vanishing higher tail, measured endpoint distribution, amplitude or observable multiplicity is inferred."|>
],"CutFamily"];
End[];EndPackage[];
