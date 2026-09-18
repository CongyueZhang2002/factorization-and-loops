(* Inclusive scalar phase-space moments and direct checks of native
   polynomial measurement cuts. No observable or matrix element is built in. *)
BeginPackage["FeynFacet`"];
IntegrateMasslessInvariantMoments::usage="IntegrateMasslessInvariantMoments[prepared,epsilon] evaluates two-body constants or three-body Laurent monomials in pair invariant masses using the normalized Dirichlet measure. It requires no extra external direction, unit particle cuts, no measurement cut, and the original prescription certificate.";
EvaluateThreeParticleMeasurementInterior::usage="EvaluateThreeParticleMeasurementInterior[prepared,request] integrates a native polynomial measurement on massless three-body phase space at epsilon=0, or exactly in a supplied DimensionalRegulator through Euler beta/Gauss functions. It includes all real roots whose membership in the declared open integration interval is proved. Root domains requiring partitions are rejected. This is a direct interior check, not endpoint continuation or a replacement for DE construction.";
EvaluatePairMeasurementEulerMaster::usage="EvaluatePairMeasurementEulerMaster[family,integral,epsilon] evaluates a unit-cut massless four-particle scalar integral when a pair-resolved chart leaves angle-independent successive beta/Gauss energy integrals. Positive ordinary propagator powers require the shared original-product prescription certificate and a nonempty initial Euler convergence domain. The explicit meromorphic value fixes this integral's physical constants on the open measured interval; it does not infer endpoint distributions.";
PreparePairMeasurementRecoilIntegration::usage="PreparePairMeasurementRecoilIntegration[family,integral,epsilon] integrates the recoil angles of a unit-cut four-particle pair-measurement master with the shared two-body angular solver. It certifies the original ordinary prescription, derives the recoil frame from actual particle labels and restores the exact dimensional measure. The resulting two-energy integral is an intermediate representation, not a solved master or endpoint distribution.";
Begin["`Private`"];
pairMeasurementIntegralCharts[family_,integral_,e_]:=Module[
 {definition,top,powers,slots,ordinary,pure,cuts,particles,total,s,parameters,orders,coordinates,push,branch,charts={},
  particleSlots,particleDefinition,unit,z,polynomial,f,g,observable,matchedPairs={},pair,pairMomenta},
 definition=FeynFacet`CreateCutIntegralDefinition[family];
 If[!AssociationQ[definition],Throw[definition,"CutFamily"]];
 top=definition["Topology"];powers=integral[[2]];slots=definition["CutIndices"];
 ordinary=Complement[Range[Length[top[[2]]]],slots];particles=Lookup[definition,"FinalMomenta",{}];
 If[integral[[1]]=!=First[top]||Length[powers]=!=Length[top[[2]]]||!VectorQ[powers,IntegerQ]||
   Length[particles]=!=4||Length[definition["ParticleCutIndices"]]=!=4||
   Length[definition["MeasurementCutIndices"]]=!=1||powers[[slots]]=!=ConstantArray[1,Length[slots]],
  cutFamilyFail["UnitFourParticleMeasurementMasterRequired"]];
 total=definition["TimeDirection"];s=FeynCalc`FCI[FeynCalc`SPD[total]]/.top[[5]];
 cuts=Map[Join[#,<|"Index"->First@FirstPosition[slots,#["Index"]]|>]&,definition["Cuts"]];
 pure=FeynFacet`CreateCutIntegralDefinition[Join[definition,<|
  "Topology"->ReplacePart[top,2->top[[2,slots]]],"Cuts"->cuts,"MeasurementNumerator"->1|>]];
 If[!AssociationQ[pure],Throw[pure,"CutFamily"]];
 parameters=Table[Unique["pairIntegration$"],{5}];
 orders=Map[Join[#,Complement[Range[4],#]]&,Permutations[Range[4],{2}]];
 (* Identify an actual rest-frame pair angle on the particle cuts before
    trying coordinate roots. This exact identity selects the two useful
    label orders; a different observable retains the general chart search. *)
 z=First[definition["MeasurementVariables"]];
 polynomial=definition["InversePropagators"][[First[definition["MeasurementCutIndices"]]]];
 If[PolynomialQ[polynomial,z]&&Exponent[polynomial,z]===1,
  f=Coefficient[polynomial,z];g=-polynomial/.z->0;
  particleSlots=definition["ParticleCutIndices"];
  cuts=Map[Join[#,<|"Index"->First@FirstPosition[particleSlots,#["Index"]]|>] &,
    Select[definition["Cuts"],#["Type"]==="Particle"&]];
  particleDefinition=FeynFacet`CreateCutIntegralDefinition[Join[definition,<|
    "Topology"->ReplacePart[top,2->top[[2,particleSlots]]],"Cuts"->cuts|>]];
  unit=FeynFacet`UnitCutScalarProductRules[particleDefinition];
  If[ListQ[unit],Do[
   pairMomenta=particles[[pair]];
   observable=FeynCalc`FCI[s FeynCalc`SPD[pairMomenta[[1]],pairMomenta[[2]]]/
     (2FeynCalc`SPD[total,pairMomenta[[1]]]FeynCalc`SPD[total,pairMomenta[[2]]])];
   observable=FeynCalc`ExpandScalarProduct[observable/.
     Lookup[definition,"MomentumConservationRules",{}]]/.top[[5]];
   If[Cancel[Together[(g-f observable)/.unit]]===0,AppendTo[matchedPairs,pair]],
   {pair,Subsets[Range[4],{2}]}]];
  If[matchedPairs=!={},orders=Map[Join[#,Complement[Range[4],#]] &,
    Flatten[({#,Reverse[#]}&/@matchedPairs),1]]]
 ];
 Do[
  coordinates=FeynFacet`MasslessPairPhaseSpaceCoordinates[particles[[order]],total,s,e,parameters];
  push=FeynFacet`ConstructPhaseSpaceMeasurementPushforward[pure,coordinates];
  If[!AssociationQ[push]||Length[push["Branches"]]=!=1,Continue[]];
  branch=First[push["Branches"]];
  If[!FreeQ[branch["Root"],Alternatives@@Rest[parameters]],Continue[]];
  AppendTo[charts,<|"Coordinates"->coordinates,"Pushforward"->push,"Branch"->branch,"ParticleOrder"->order|>],
 {order,orders}];
 If[charts==={},cutFamilyFail["IndependentPairAngleMeasurementChartRequired"]];
 <|"Definition"->definition,"PureCutDefinition"->pure,"OrdinaryIndices"->ordinary,
   "Scale"->s,"Parameters"->parameters,"Charts"->charts,
   "ExactlyIdentifiedParticlePairs"->matchedPairs|>
];
EvaluatePairMeasurementEulerMaster[family_Association,integral_FeynCalc`GLI,e_Symbol]:=Catch[Module[
 {data,definition,powers,ordinary,pure,s,parameters,r,x,y,a,b,coordinates,push,branch,root,
  moment,inner,outer,value,normalization,domain,failures={},certificate,convergence,realRegulator},
 data=pairMeasurementIntegralCharts[family,integral,e];
 {definition,pure,ordinary,s,parameters}=Lookup[data,{"Definition","PureCutDefinition","OrdinaryIndices","Scale","Parameters"}];
 powers=integral[[2]];{r,x,y,a,b}=parameters;
 certificate=If[AllTrue[powers[[ordinary]],#<=0&],
  <|"Status"->"NoOrdinaryDenominators"|>,
  FeynFacet`CertifyOrdinaryPrescriptionRemoval[definition,integral,
    <|"ExternalKinematicConditions"->definition["Assumptions"],"DimensionalRegulator"->e|>]];
 If[!AssociationQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
  cutFamilyFail["OriginalPairEulerPrescriptionCertificateRequired",<|"Cause"->certificate|>]];
 Do[
  {coordinates,push,branch}=Lookup[chart,{"Coordinates","Pushforward","Branch"}];
  root=branch["Root"];domain=push["Domain"];
  moment=Cancel[Together[branch["Jacobian"]Times@@MapThread[Power,
    {definition["InversePropagators"][[ordinary]],-powers[[ordinary]]}]/.branch["ScalarProductRules"]/.D->4-2e]];
  If[!FreeQ[moment,Alternatives[a,b,_FeynCalc`Pair,_FeynCalc`Momentum]],Continue[]];
  inner=FeynFacet`IntegrateUnivariateEulerProduct[moment,{{y,1-2e},{1-y,-e}},{y,0,1},domain];
  If[!AssociationQ[inner],AppendTo[failures,inner];Continue[]];
  outer=FeynFacet`IntegrateUnivariateEulerProduct[inner["Value"],
   {{x,1-2e},{1-x,2-3e},{1-root x,-2+2e}},{x,0,1},domain];
  If[!AssociationQ[outer],AppendTo[failures,outer];Continue[]];
  convergence=e<0&&And@@(#> -1&/@Join[inner["EndpointPowers"],outer["EndpointPowers"]]);
  realRegulator=Unique["realEulerRegulator$"];
  If[!TrueQ[With[{v=realRegulator,c=convergence/.e->realRegulator},Resolve[Exists[{v},c],Reals]]],
   cutFamilyFail["CommonPairEulerConvergenceDomainRequired"]];
  normalization=(pure["MeasurePrefactor"]/(2Pi)^(4-3D))/.D->4-2e;
  value=normalization coordinates["Prefactor"]s^(2-3e)root^-e(1-root)^-e outer["Value"];
  If[!FreeQ[value,Alternatives@@parameters]||!FreeQ[value,_Integrate|_Failure|_Missing],Continue[]];
  Return[<|"Value"->value,"AnalyticExpression"->value,"ExactInRegulator"->True,
   "DimensionalRegulator"->e,"Integral"->integral,"Variable"->push["Variable"],
   "Domain"->definition["Assumptions"]&&0<push["Variable"]<1,
   "Method"->"PairResolvedEulerIntegral","ParticleOrder"->chart["ParticleOrder"],"MeasurementRoot"->root,
   "ConvergenceEndpointPowers"->{inner["EndpointPowers"],outer["EndpointPowers"]},
   "NoOrdinaryCausalDenominators"->AllTrue[powers[[ordinary]],#<=0&],
   "OriginalOrdinaryPrescriptionCertificate"->certificate,"InitialRealRegulatorDomain"->convergence,
   "PhysicalBoundaryConstantsFixed"->True,
   "EndpointDistributionIncluded"->False,
   "Definition"->"The labeled physical phase-space period, initially convergent and continued meromorphically in epsilon; no measured coefficient or free DE constant is inserted."|>,Module],
 {chart,data["Charts"]}];
 cutFamilyFail["PairResolvedPolynomialEulerIntegralUnsupported",<|"Causes"->DeleteDuplicates[failures]|>]
],"CutFamily"];
PreparePairMeasurementRecoilIntegration[family_Association,integral_FeynCalc`GLI,e_Symbol]:=Catch[Module[
 {data,definition,ordinary,chart,coordinates,push,branch,parameters,r,x,y,a,b,s,particles,total,order,
  rr,pa,pb,l,lb,routing,kin,conditions,x2,rho,kernel,child,prepared,decomposition,angular,
  certificate,normalization,density,mean,scale},
 data=pairMeasurementIntegralCharts[family,integral,e];
 {definition,ordinary,s,parameters}=Lookup[data,{"Definition","OrdinaryIndices","Scale","Parameters"}];
 chart=First[data["Charts"]];{coordinates,push,branch,order}=Lookup[chart,{"Coordinates","Pushforward","Branch","ParticleOrder"}];
 {r,x,y,a,b}=parameters;particles=definition["FinalMomenta"];total=definition["TimeDirection"];
 certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[definition,integral,
  <|"ExternalKinematicConditions"->definition["Assumptions"],"DimensionalRegulator"->e|>];
 If[!AssociationQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
  cutFamilyFail["OriginalFourParticlePrescriptionCertificateRequired",<|"Cause"->certificate|>]];
 {rr,pa,pb,l,lb}=Table[Unique["recoilMomentum$"],{5}];
 x2=(1-x)y/(1-r x);rho=(1-x)(1-y);
 kin={FeynCalc`SPD[pa]->0,FeynCalc`SPD[pb]->0,FeynCalc`SPD[rr]->s rho,
  FeynCalc`SPD[pa,pb]->s r x x2/2,FeynCalc`SPD[rr,pa]->s x(1-r x2)/2,
  FeynCalc`SPD[rr,pb]->s x2(1-r x)/2}/.branch["EliminationRule"];
 conditions=definition["Assumptions"]&&0<x<1&&0<y<1&&0<branch["Root"]<1;
 routing=Append[Thread[particles[[order]]->{pa,pb,l,rr-l}],total->rr+pa+pb];
 (* Preserve the ordinary propagator descriptors through the frame change.
    Converting a shifted propagator prematurely to a generic polynomial
    hides its physical momentum from the shared prescription proof. *)
 kernel=Times@@Table[If[integral[[2,j]]>0,
   definition["Topology"][[2,j]]^integral[[2,j]],
   definition["InversePropagators"][[j]]^(-integral[[2,j]])],{j,ordinary}];
 kernel=FeynCalc`FCI[kernel/.routing];
 child=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->PairRecoilIntegral,
  "FinalMomenta"->{l,lb},"TotalMomentum"->rr,"ExternalMomenta"->{rr,pa,pb},
  "KinematicRules"->kin,"Assumptions"->conditions|>];
 If[!AssociationQ[child],Throw[child,"CutFamily"]];
 prepared=FeynFacet`PrepareCutIntegrand[kernel,child,<|"ExternalKinematicConditions"->conditions,
  "CancelDenominators"->False|>];
 If[!AssociationQ[prepared],cutFamilyFail["RecoilIntegrandPreparationFailed",<|"Cause"->prepared|>]];
 decomposition=FeynFacet`DecomposeMeasuredCutIntegrand[prepared];
 If[!AssociationQ[decomposition],cutFamilyFail["RecoilIntegralDecompositionFailed",<|"Cause"->decomposition|>]];
 angular=FeynFacet`EvaluateTwoBodyIntegralCombination[decomposition,<|"DimensionalRegulator"->e|>];
 If[!AssociationQ[angular],cutFamilyFail["RecoilAngularIntegralUnsupported",<|"Cause"->angular|>]];
 mean=angular["Values"]["Scalar"]/FeynFacet`MasslessPhaseSpaceVolume[2,s rho,e];
 normalization=(data["PureCutDefinition"]["MeasurePrefactor"]/(2Pi)^(4-3D))/.D->4-2e;
 density=normalization branch["Jacobian"](coordinates["RadialDensity"]/.branch["EliminationRule"])mean;
 <|"Format"->"FeynFacet-PairMeasurementRecoilIntegral","Integral"->integral,"Definition"->definition,
  "DimensionalRegulator"->e,"Variable"->push["Variable"],"IntegrationVariables"->{x,y},
  "Density"->density,"NormalizedAngularValue"->mean,"Domain"->conditions,"ParticleOrder"->order,
  "Coordinates"->coordinates,"MeasurementRoot"->branch["Root"],"RecoilAngularIntegral"->angular,
  "OriginalOrdinaryPrescriptionCertificate"->certificate,
  "RemainingIntegrationDimension"->2,"PhysicalBoundaryConstantsFixed"->False,
  "EndpointDistributionIncluded"->False,
  "Scope"->"Exact recoil-angle integration of the original unit-cut period. Tagged energy integrations and all singular measurement-endpoint limits remain."|>
],"CutFamily"];
invariantPhaseSpaceData[prepared_]:=Module[{d,top,particles,total,s,rule,nu},
 If[Lookup[prepared,"Format",None]=!="FeynFacet-MeasuredCutIntegrand",
   cutFamilyFail["PreparedInvariantPhaseSpaceRequired"]];
 d=prepared["SourceDefinition"];top=d["Topology"];particles=Lookup[d,"FinalMomenta",{}];
 If[Lookup[d,"Dimension",D]=!=D,cutFamilyFail["AmbientDPhaseSpaceRequired"]];
 total=d["TimeDirection"];
 If[!MemberQ[{2,3},Length[particles]]||Length[top[[4]]]=!=1||total=!=First[top[[4]]]||
   Length[d["ParticleCutIndices"]]=!=Length[particles]||!AllTrue[prepared["CutPowers"],#===1&],
  cutFamilyFail["UnitTwoOrThreeBodySingleTimelikeSourceRequired"]];
 If[FeynFacet`RequireOrdinaryPrescriptionCertificate[prepared,"GenericKinematics"]=!=True,
  cutFamilyFail["OriginalInvariantProductPrescriptionProofRequired"]];
 s=FeynCalc`FCI[FeynCalc`SPD[total]]/.top[[5]];
 If[!TrueQ[FullSimplify[s>0,Assumptions->d["Assumptions"]]],cutFamilyFail["PositiveTimelikeInvariantRequired"]];
 <|"Definition"->d,"Particles"->particles,"TotalMomentum"->total,"Scale"->s,
   "StandardMeasure"->(2Pi)^(Length[particles]-(Length[particles]-1)D),
   "Assumptions"->d["Assumptions"]|>
];
preparedInvariantExpression[prepared_]:=Total[Map[
 #["Numerator"]Times@@MapThread[Power,{prepared["OrdinaryUnitCutPolynomials"],-#["Powers"]}]&,
 prepared["Terms"]]]/.prepared["ScalarProductVariables"];
invariantParticleRules[particles_,total_,s_,invariants_]:=Module[{gram,n=Length[particles]},
 gram=If[n===2,{{0,s/2},{s/2,0}},
  {{0,invariants[[1]]/2,invariants[[2]]/2},{invariants[[1]]/2,0,invariants[[3]]/2},
    {invariants[[2]]/2,invariants[[3]]/2,0}}];
 Join[Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[particles[[i]],particles[[j]]]]->gram[[i,j]],{i,n},{j,i,n}]],
   Table[FeynCalc`FCI[FeynCalc`SPD[total,particles[[i]]]]->Total[gram[[i]]],{i,n}],
   {FeynCalc`FCI[FeynCalc`SPD[total]]->s}]
];
IntegrateMasslessInvariantMoments[prepared_Association,e_Symbol]:=Catch[Module[
 {data,d,n,s,variables,rules,expression,den,powers,polynomial,rows,a,normalization,result,factors,canonical},
 data=invariantPhaseSpaceData[prepared];d=data["Definition"];n=Length[data["Particles"]];s=data["Scale"];
 If[d["MeasurementCutIndices"]=!={},cutFamilyFail["UnmeasuredMomentIntegralRequired"]];
 variables=Table[Unique["invariantFraction$"],{3}];
 rules=invariantParticleRules[data["Particles"],data["TotalMomentum"],s,s variables];
 expression=Cancel[Together[preparedInvariantExpression[prepared]/.rules]];
 If[!FreeQ[expression,_FeynCalc`Pair|_FeynCalc`Momentum],cutFamilyFail["ScalarInvariantMomentRequired"]];
 normalization=Cancel[d["MeasurePrefactor"]/data["StandardMeasure"]]/.D->4-2e;
 If[n===2,Return[<|"Value"->normalization(expression/.D->4-2e)FeynFacet`MasslessPhaseSpaceVolume[2,s,e],
   "Method"->"TwoBodyInvariantConstant","DimensionalRegulator"->e|>,Module]];
 den=Denominator[expression];
 canonical[f_]:=If[!FreeQ[f,Alternatives@@variables]&&PolynomialQ[f,variables]&&AllTrue[First/@CoefficientRules[f,variables],Total[#]<=1&],
   Expand[Sum[(f/.Thread[variables->UnitVector[3,j]])variables[[j]],{j,3}]],f];
 factors=FactorList[den];
 den=Times@@((canonical[First[#]]^Last[#])&/@factors);
 expression=Cancel[Numerator[expression]/den];
 den=Denominator[expression];powers=Exponent[den,#]&/@variables;
 If[!FreeQ[Cancel[den/Times@@MapThread[Power,{variables,powers}]],Alternatives@@variables],
  cutFamilyFail["PairInvariantLaurentMonomialsRequired"]];
 polynomial=Cancel[expression Times@@MapThread[Power,{variables,powers}]];
 rows=CoefficientRules[polynomial,variables];a=1-e;
 result=Total[Map[Function[row,With[{orders=First[row]-powers},Last[row]*
   Times@@(Pochhammer[a,#]&/@orders)/Pochhammer[3a,Total[orders]]]],rows]];
 <|"Value"->normalization Factor[result/.D->4-2e]FeynFacet`MasslessPhaseSpaceVolume[3,s,e],
   "Method"->"ThreeBodyDirichletMoments","DimensionalRegulator"->e,
   "MonomialPowers"->((First[#]-powers)&/@rows),
   "Definition"->"Initially convergent Dirichlet moments, uniquely continued meromorphically in epsilon."|>
],"CutFamily"];
EvaluateThreeParticleMeasurementInterior[prepared_Association,request_Association]:=Catch[Module[
 {data,pushforward,x,z,assumptions,expression,selected={},density,normalization,result,time,e,euler,dimension},
 data=invariantPhaseSpaceData[prepared];
 pushforward=FeynFacet`ConstructThreeParticleMeasurementPushforward[data["Definition"],request];
 If[!AssociationQ[pushforward],Throw[pushforward,"CutFamily"]];
 {x,z,e,dimension,assumptions,normalization}=Lookup[pushforward,
  {"IntegrationVariable","Variable","DimensionalRegulator","Dimension","Domain","Normalization"}];
 expression=Cancel[Together[preparedInvariantExpression[prepared]/.pushforward["ScalarProductRules"]/.D->dimension]];
 If[!FreeQ[expression,_FeynCalc`Pair|_FeynCalc`Momentum|_Failure|_Missing],cutFamilyFail["RationalScalarDensityRequired"]];
 Do[density=Cancel[(expression/.branch["EliminationRule"])branch["Jacobian"]];
   If[e=!=None,
    euler=FeynFacet`IntegrateUnivariateEulerProduct[density,{{branch["GramPolynomial"],-e}},{x,0,1},assumptions];
    If[!AssociationQ[euler],cutFamilyFail["MeasuredEulerIntegralFailed",<|"Cause"->euler|>]]];
   AppendTo[selected,Join[KeyTake[branch,{"Root","Jacobian"}],<|"Density"->density|>,
     If[e===None,<||>,<|"ExactIntegral"->euler["Value"]|>]]],{branch,pushforward["Branches"]}];
 density=normalization Total[Lookup[selected,"Density",{}]];
 time=Lookup[request,"TimeLimit",120];
 result=If[e===None,
   TimeConstrained[Integrate[density,{x,0,1},Assumptions->assumptions,GenerateConditions->False],time,$TimedOut],
   normalization Total[Lookup[selected,"ExactIntegral",{}]]];
 If[!FreeQ[result,_Integrate|_ConditionalExpression|_Piecewise|$TimedOut|_DirectedInfinity|Indeterminate],
  cutFamilyFail["ExplicitInteriorMeasurementIntegralRequired",<|"Cause"->result|>]];
 <|"Value"->If[e===None,FullSimplify[result,Assumptions->assumptions],result],
  "DimensionalRegulator"->e,"Dimension"->dimension,"ExactInRegulator"->(e=!=None),
  "Variable"->z,"Domain"->assumptions,"ParticleOrder"->pushforward["ParticleOrder"],"Roots"->(KeyDrop[#,"Density"]&/@selected),
  "Method"->"DirectNativePolynomialCutIntegration","EndpointDistributionIncluded"->False,
  "Scope"->"Open measured interval only; all regulator dependence is retained when a DimensionalRegulator is supplied. No endpoint distribution is inferred."|>
],"CutFamily"];
End[];EndPackage[];
