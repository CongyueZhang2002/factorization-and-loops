(* Two particles with one normalized longitudinal angular measurement.
   The remaining angular integral is an exact linear polynomial functional. *)
BeginPackage["FeynFacet`"];
ConstructTwoParticleMeasurement::usage="ConstructTwoParticleMeasurement[request] constructs exact two-body phase-space density and full/physical/evanescent scalar-product rules with physical null reference p and timelike P. Optional MassesSquared fixes the physical angular interval; in the massless limit the variable is p.k/(p.P). Both outgoing momenta remain D-dimensional.";
AverageEvanescentPowers::usage="AverageEvanescentPowers[expression,kappa,transverseSquare,epsilon] averages the complete polynomial in the signed Minkowski square kappa=k_hat^2. It rejects angular denominators. Every positive-power angular moment is O(epsilon), rather than O(epsilon^power).";
EvaluateTwoParticleMeasurement::usage="EvaluateTwoParticleMeasurement[projectedScalar,geometry] reduces all scalar products, averages evanescent powers and multiplies the exact measured two-particle phase space. Flux, current normalization, symmetry factors and coupling normalization remain explicit caller factors.";
IntegrateTwoParticleMeasurement::usage="IntegrateTwoParticleMeasurement[projectedScalar,geometry] integrates the declared two-particle angular variable exactly using Dirichlet Beta integrals. The scalar must be rational in that variable with poles confined to its endpoints.";
Begin["`Private`"];
twoParticleFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"TwoParticleMeasurement"];
twoParticleIntegratedPhaseSpace[s_,velocity_,e_]:=(4Pi)^e/(8Pi) s^(-e)velocity^(1-2e) Gamma[1-e]/Gamma[2-2e];
ConstructTwoParticleMeasurement[request_Association]:=Catch[Module[
 {p,total,k,r,s,rho,z,kappa,e,assumptions,momenta,full,evanescent,rules,density,cut,coordinate,labels,masses,m1,m2,discriminant,velocity,offset,fraction,prefactor},
 If[!ContainsAll[Keys[request],{"ReferenceMomentum","TotalMomentum","FinalMomenta","InvariantMassSquared",
  "ReferenceProjection","MeasurementVariable","EvanescentSquare","DimensionalRegulator","Assumptions"}],
  twoParticleFail["TwoParticleMeasurementRequestRequired"]];
 {p,total,s,rho,z,kappa,e,assumptions}=Lookup[request,{"ReferenceMomentum","TotalMomentum","InvariantMassSquared",
  "ReferenceProjection","MeasurementVariable","EvanescentSquare","DimensionalRegulator","Assumptions"}];
 If[!MatchQ[request["FinalMomenta"],{_Symbol,_Symbol}],twoParticleFail["TwoFinalMomentumLabelsRequired"]];
 {k,r}=request["FinalMomenta"];labels={p,total,k,r,z,kappa,e};
 masses=Lookup[request,"MassesSquared",{0,0}];
 If[!MatchQ[masses,{_,_}],twoParticleFail["TwoParticleMassesRequired"]];
 {m1,m2}=masses;
 If[!MatchQ[labels,{_Symbol...}]||!DuplicateFreeQ[labels]||
  !FreeQ[{s,rho,masses},Alternatives@@labels]||
  !TrueQ[FullSimplify[m1>=0&&m2>=0&&s>(Sqrt[m1]+Sqrt[m2])^2&&rho>0&&0<z<1,Assumptions->assumptions]],
  twoParticleFail["PhysicalTwoParticleMeasurementRequired"]];
 discriminant=Expand[(s-m1-m2)^2-4m1 m2];
 velocity=FullSimplify[Sqrt[discriminant]/s,Assumptions->assumptions];
 offset=FullSimplify[(s+m1-m2)/(2s)-velocity/2,Assumptions->assumptions];
 fraction=offset+velocity z;
 momenta={p,total,k,r};
 full={{0,rho,fraction rho,(1-fraction)rho},
  {rho,s,(s+m1-m2)/2,(s+m2-m1)/2},
  {fraction rho,(s+m1-m2)/2,m1,(s-m1-m2)/2},
  {(1-fraction)rho,(s+m2-m1)/2,(s-m1-m2)/2,m2}};
 evanescent={{0,0,0,0},{0,0,0,0},{0,0,kappa,-kappa},{0,0,-kappa,kappa}};
 rules=Flatten[Table[{
  FeynCalc`Pair[FeynCalc`Momentum[momenta[[i]],D],FeynCalc`Momentum[momenta[[j]],D]]->full[[i,j]],
  FeynCalc`Pair[FeynCalc`Momentum[momenta[[i]]],FeynCalc`Momentum[momenta[[j]]]]->full[[i,j]]-evanescent[[i,j]],
  FeynCalc`Pair[FeynCalc`Momentum[momenta[[i]],D-4],FeynCalc`Momentum[momenta[[j]],D-4]]->evanescent[[i,j]]},
 {i,4},{j,i,4}],2];
 prefactor=(4Pi)^e/(8Pi Gamma[1-e]) s^(-e)velocity^(1-2e);
 density=prefactor (z(1-z))^(-e);
 cut=CompileLinearMeasurement[<|"Observable"->(coordinate/(2rho)-offset)/velocity,"Value"->z,
  "IntegrationVariables"->{coordinate},"Assumptions"->assumptions&&Element[coordinate,Reals]|>];
 If[!AssociationQ[cut],twoParticleFail["LinearMeasurementCompilationFailed",<|"Cause"->cut|>]];
 <|"Geometry"->"TwoParticleMeasurement","DimensionalRegulator"->e,
  "Momenta"->momenta,"InvariantMassSquared"->s,"ReferenceProjection"->rho,
  "MeasurementVariable"->z,"EvanescentSquare"->kappa,"TransverseSquare"->-s velocity^2 z(1-z),
  "MassesSquared"->masses,"KallenDiscriminant"->discriminant,"VelocityFactor"->velocity,
  "ReferenceMomentumFraction"->fraction,
  "FullDimensionalScalarProductMatrix"->full,
  "ScalarProductRules"->DeleteDuplicates[rules],"MomentumRules"->Lookup[request,"MomentumRules",{}],
   "PhaseSpacePrefactor"->prefactor,"PhaseSpaceDensity"->density,
  "IntegratedPhaseSpace"->twoParticleIntegratedPhaseSpace[s,velocity,e],
  "MeasurementCut"->Join[cut,<|"CoordinateDefinition"->(coordinate->2FeynCalc`SPD[p,k])|>],
  "DensityIncludesMeasurementJacobian"->True,"ResidualAngularAverageOfOne"->1,
  "EvanescentInvariantConvention"->"Signed Minkowski square k_hat^2",
  "Assumptions"->assumptions|>
],"TwoParticleMeasurement"];
AverageEvanescentPowers[expression_,kappa_Symbol,transverseSquare_,e_Symbol]:=Catch[Module[
 {rational,num,den},
 If[kappa===e||!FreeQ[transverseSquare,kappa|e]||
  !FreeQ[expression,_Failure|_Missing|$Failed|$Aborted|Indeterminate|_DirectedInfinity],
  twoParticleFail["ExplicitEvanescentPolynomialRequired"]];
 rational=Together[expression];num=Numerator[rational];den=Denominator[rational];
 If[!FreeQ[den,kappa]||!PolynomialQ[num,kappa],twoParticleFail["PolynomialAngularDependenceRequired"]];
 Sum[Coefficient[num,kappa,a] transverseSquare^a If[a===0,1,-e/(a-e)],
  {a,0,Max[0,Exponent[num,kappa]]}]/den
],"TwoParticleMeasurement"];
EvaluateTwoParticleMeasurement[expression_,geometry_Association]:=Catch[Module[{scalar,average,e},
 If[Lookup[geometry,"Geometry",None]=!="TwoParticleMeasurement",
  twoParticleFail["TwoParticleMeasurementRequired"]];
 e=geometry["DimensionalRegulator"];
 scalar=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[expression]/.geometry["MomentumRules"]]/.
  geometry["ScalarProductRules"]/.D->4-2e;
 If[!FreeQ[scalar,_FeynCalc`Pair|_FeynCalc`Eps|_FeynCalc`LorentzIndex|_FeynCalc`Momentum|
  _FeynCalc`DiracTrace|_FeynCalc`DiracGamma|_FeynCalc`DOT|_FeynCalc`Spinor|_FeynCalc`Polarization|
  _FeynCalc`SUNIndex|_FeynCalc`SUNFIndex|_Integrate|_NIntegrate],
  twoParticleFail["FullyProjectedTwoParticleScalarRequired"]];
 average=AverageEvanescentPowers[scalar,geometry["EvanescentSquare"],geometry["TransverseSquare"],e];
 If[FailureQ[average],Throw[average,"TwoParticleMeasurement"]];
 <|"Value"->Factor[average]geometry["PhaseSpaceDensity"],"AngularAverage"->Factor[average],
  "PhaseSpaceDensity"->geometry["PhaseSpaceDensity"],"DimensionalRegulator"->e,
  "MeasurementVariable"->geometry["MeasurementVariable"],
  "Normalization"->"Physical measured two-particle phase space; no scattering flux or current factor."|>
],"TwoParticleMeasurement"];
twoParticleRationalBetaIntegral[expression_,variable_Symbol,e_Symbol]:=Module[
 {rational,num,den,factors,constant=1,left=0,right=0,factor,power,degree},
 rational=Together[expression];num=Numerator[rational];den=Denominator[rational];
 If[!PolynomialQ[num,variable]||!PolynomialQ[den,variable],twoParticleFail["RationalAngularIntegrandRequired"]];
 factors=FactorList[den];
 Do[{factor,power}=entry;
  Which[
   FreeQ[factor,variable],constant*=factor^power,
   Exponent[factor,variable]===1&&Factor[factor/.variable->0]===0,
    constant*=Coefficient[factor,variable]^power;left+=power,
   Exponent[factor,variable]===1&&Factor[factor/.variable->1]===0,
    constant*=(-Coefficient[factor,variable])^power;right+=power,
   True,twoParticleFail["AdditionalAngularSingularityRequiresIntegration",<|"Factor"->factor|>]],
 {entry,factors}];
 Sum[Coefficient[num,variable,j]Gamma[1+j-left-e]Gamma[1-right-e]/Gamma[2+j-left-right-2e],
  {j,0,Max[0,Exponent[num,variable]]}]/constant
];
IntegrateTwoParticleMeasurement[expression_,geometry_Association]:=Catch[Module[{measured,integral},
 measured=EvaluateTwoParticleMeasurement[expression,geometry];
 If[FailureQ[measured],Throw[measured,"TwoParticleMeasurement"]];
 integral=twoParticleRationalBetaIntegral[measured["AngularAverage"],geometry["MeasurementVariable"],geometry["DimensionalRegulator"]];
 Join[KeyDrop[measured,{"AngularAverage","PhaseSpaceDensity","Value","Normalization"}],
  <|"Value"->integral geometry["PhaseSpacePrefactor"],"AngularIntegral"->integral,
   "IntegratedVariables"->{geometry["MeasurementVariable"]},"ExactInEpsilon"->True,
   "Normalization"->"Physical two-particle phase space integrated over the declared angular variable; no current factor or scattering flux."|>]
],"TwoParticleMeasurement"];
End[];EndPackage[];
