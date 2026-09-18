(* Inclusive scalar phase-space moments and direct checks of native
   polynomial measurement cuts. No observable or matrix element is built in. *)
BeginPackage["FeynFacet`"];
IntegrateMasslessInvariantMoments::usage="IntegrateMasslessInvariantMoments[prepared,epsilon] evaluates two-body constants or three-body Laurent monomials in pair invariant masses using the normalized Dirichlet measure. It requires no extra external direction, unit particle cuts, no measurement cut, and the original prescription certificate.";
EvaluateThreeParticleMeasurementInterior::usage="EvaluateThreeParticleMeasurementInterior[prepared,request] integrates a native polynomial measurement on massless three-body phase space at epsilon=0, or exactly in a supplied DimensionalRegulator through Euler beta/Gauss functions. It includes all real roots whose membership in the declared open integration interval is proved. Root domains requiring partitions are rejected. This is a direct interior check, not endpoint continuation or a replacement for DE construction.";
Begin["`Private`"];
invariantPhaseSpaceData[prepared_]:=Module[{d,top,particles,total,s,rule,nu},
 If[Lookup[prepared,"Format",None]=!="FeynFacet-MeasuredCutIntegrand",
   cutFamilyFail["PreparedInvariantPhaseSpaceRequired"]];
 d=prepared["SourceDefinition"];top=d["Topology"];particles=Lookup[d,"FinalMomenta",{}];
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
