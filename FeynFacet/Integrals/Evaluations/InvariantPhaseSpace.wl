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
 {data,d,s,particles,order,parameters,x,y,z,assumptions,rules,expression,g,slot,roots,selected={},
  root,inside,outside,slope,jacobian,density,normalization,result,time,e,gram,euler,dimension},
 data=invariantPhaseSpaceData[prepared];d=data["Definition"];s=data["Scale"];particles=data["Particles"];
 If[Length[particles]=!=3||Length[d["MeasurementCutIndices"]]=!=1,
  cutFamilyFail["ThreeParticleSingleMeasurementRequired"]];
 order=Lookup[request,"ParticleOrder",Range[3]];
 If[Sort[order]=!={1,2,3},cutFamilyFail["ParticlePermutationRequired"]];particles=particles[[order]];
 parameters=Lookup[request,"Parameters",{Unique["energyFraction$"],Unique["energyFraction$"]}];
 If[!MatchQ[parameters,{_Symbol,_Symbol}]||!DuplicateFreeQ[parameters],cutFamilyFail["TwoIndependentPhaseSpaceParametersRequired"]];
 {x,y}=parameters;z=First[d["MeasurementVariables"]];
 assumptions=Lookup[request,"Assumptions",data["Assumptions"]&&0<z<1];
 rules=invariantParticleRules[particles,data["TotalMomentum"],s,{s(x+y-1),s(1-y),s(1-x)}];
 slot=First[d["MeasurementCutIndices"]];g=Factor[d["InversePropagators"][[slot]]/.rules];
 e=Lookup[request,"DimensionalRegulator",None];
 If[e=!=None&&!MatchQ[e,_Symbol],cutFamilyFail["SymbolicDimensionalRegulatorRequired"]];
 dimension=If[e===None,4,4-2e];
 expression=Cancel[Together[preparedInvariantExpression[prepared]/.rules/.D->dimension]];
 If[!FreeQ[{g,expression},_FeynCalc`Pair|_FeynCalc`Momentum|_Failure|_Missing]||
   !PolynomialQ[g,y]||!MemberQ[{1,2},Exponent[g,y]],cutFamilyFail["PolynomialRootAndRationalScalarDensityRequired"]];
 roots=DeleteDuplicates[y/.Solve[g==0,y]];
 Do[
  inside=TrueQ[FullSimplify[Element[root,Reals]&&1-x<root<1,Assumptions->assumptions&&0<x<1]];
  outside=TrueQ[FullSimplify[!Element[root,Reals]||root<=1-x||root>=1,Assumptions->assumptions&&0<x<1]];
  If[!inside&&!outside,cutFamilyFail["MeasurementRootDomainPartitionRequired",<|"Root"->root|>]];
  If[inside,
   slope=Factor[D[g,y]/.y->root];
   If[!TrueQ[FullSimplify[slope!=0,Assumptions->assumptions&&0<x<1]],cutFamilyFail["SimpleInteriorMeasurementRootsRequired"]];
   jacobian=FullSimplify[1/Abs[slope],Assumptions->assumptions&&0<x<1];
   density=Cancel[(expression/.y->root)jacobian];
   If[e=!=None,
    gram=Factor[(1-x)(1-y)(x+y-1)/.y->root];
    euler=FeynFacet`IntegrateUnivariateEulerProduct[density,{{gram,-e}},{x,0,1},assumptions];
    If[!AssociationQ[euler],cutFamilyFail["MeasuredEulerIntegralFailed",<|"Cause"->euler|>]]];
   AppendTo[selected,Join[<|"Root"->root,"Jacobian"->jacobian,"Density"->density|>,
     If[e===None,<||>,<|"ExactIntegral"->euler["Value"]|>]]]],
 {root,roots}];
 normalization=(d["MeasurePrefactor"]/data["StandardMeasure"]/.D->dimension)*
   If[e===None,s/(128Pi^3),s^(1-2e)(4Pi)^(2e)/(128Pi^3 Gamma[2-2e])];
 density=normalization Total[Lookup[selected,"Density",{}]];
 time=Lookup[request,"TimeLimit",120];
 result=If[e===None,
   TimeConstrained[Integrate[density,{x,0,1},Assumptions->assumptions,GenerateConditions->False],time,$TimedOut],
   normalization Total[Lookup[selected,"ExactIntegral",{}]]];
 If[!FreeQ[result,_Integrate|_ConditionalExpression|_Piecewise|$TimedOut|_DirectedInfinity|Indeterminate],
  cutFamilyFail["ExplicitInteriorMeasurementIntegralRequired",<|"Cause"->result|>]];
 <|"Value"->If[e===None,FullSimplify[result,Assumptions->assumptions],result],
  "DimensionalRegulator"->e,"Dimension"->dimension,"ExactInRegulator"->(e=!=None),
  "Variable"->z,"Domain"->assumptions,"ParticleOrder"->order,"Roots"->(KeyDrop[#,"Density"]&/@selected),
  "Method"->"DirectNativePolynomialCutIntegration","EndpointDistributionIncluded"->False,
  "Scope"->"Open measured interval only; all regulator dependence is retained when a DimensionalRegulator is supplied. No endpoint distribution is inferred."|>
],"CutFamily"];
End[];EndPackage[];
