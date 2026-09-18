(* Universal unmeasured four-particle scalar periods. Published scalar inputs
   are explicitly identified; no current amplitude or measured hard function
   is contained in this file. *)
BeginPackage["FeynFacet`"];
EvaluateInclusiveFourParticleMaster::usage="EvaluateInclusiveFourParticleMaster[family,integral,epsilon,range] matches supported physical unit-cut massless four-particle integrals to the phase volume, a single complementary mass power, or the universal inclusive R6/R8 scalar geometries. It restores the declared family measure and checks the original prescription. Finite universal scalar input has explicit coverage and provenance; unsupported geometries or insufficient orders fail.";
Begin["`Private`"];
inclusiveFourParticleKernel[family_,integral_,e_]:=Module[
 {definition,top,slots,powers,ordinary,particles,total,s,rules,unit,kernel,normalization,certificate},
 definition=FeynFacet`CreateCutIntegralDefinition[family];
 If[!AssociationQ[definition],Throw[definition,"CutFamily"]];
 top=definition["Topology"];slots=definition["CutIndices"];powers=integral[[2]];
 particles=Lookup[definition,"FinalMomenta",{}];total=definition["TimeDirection"];
 If[Length[particles]=!=4||Length[definition["ParticleCutIndices"]]=!=4||
   definition["MeasurementCutIndices"]=!={}||integral[[1]]=!=First[top]||
   Length[powers]=!=Length[top[[2]]]||!VectorQ[powers,IntegerQ]||powers[[slots]]=!=ConstantArray[1,4]||
   !AllTrue[definition["Cuts"],Lookup[#,"MassSquared",None]===0&&Lookup[#,"EnergyDirection",None]===1&]||
   Length[top[[4]]]=!=1||!MemberQ[{D,4-2e},definition["Dimension"]],
  cutFamilyFail["InclusiveUnitMasslessFourParticleCutsRequired"]];
 s=FeynCalc`FCI[FeynCalc`SPD[total]]/.top[[5]];
 If[!FreeQ[s,_FeynCalc`Pair|_FeynCalc`Momentum],cutFamilyFail["DeclaredPositiveTotalMassInvariantRequired"]];
 ordinary=Complement[Range[Length[powers]],slots];
 unit=FeynFacet`UnitCutScalarProductRules[definition];
 If[!ListQ[unit],cutFamilyFail["InclusiveUnitCutCoordinatesRequired"]];
 rules=Join[top[[5]],unit];
 kernel=Cancel[Together[Times@@MapThread[Power,
   {definition["InversePropagators"][[ordinary]],-powers[[ordinary]]}]/.unit]];
 certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[definition,integral,
  <|"ExternalKinematicConditions"->definition["Assumptions"],"DimensionalRegulator"->e|>];
 If[!AssociationQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
  cutFamilyFail["OriginalInclusivePrescriptionCertificateRequired",<|"Cause"->certificate|>]];
 normalization=(definition["MeasurePrefactor"]/(2Pi)^(4-3D))/.D->4-2e;
 <|"Definition"->definition,"Particles"->particles,"TotalMomentum"->total,"Scale"->s,
  "UnitCutRules"->unit,"Kernel"->kernel,"Normalization"->normalization,"Certificate"->certificate,
  "MaximumPower"->Total[Abs[powers[[ordinary]]]]|>
];
EvaluateInclusiveFourParticleMaster[family_Association,integral_FeynCalc`GLI,e_Symbol,range:{_Integer,_Integer}]:=
 Catch[Module[{data,definition,particles,total,s,unit,kernel,mass,qm,pairs,ratio,class=None,
  power=0,scalar,normalization,exact,series,lower,upper,valuation,factor,matrix,vector,result,
  candidate,permutation,source,sgamma,lo,hi,constantQ,a,b,c,d},
 If[First[range]>Last[range],cutFamilyFail["OrderedInclusiveScalarRangeRequired"]];
 data=inclusiveFourParticleKernel[family,integral,e];
 {definition,particles,total,s,unit,kernel}=Lookup[data,{"Definition","Particles","TotalMomentum","Scale","UnitCutRules","Kernel"}];
 mass[momentum_]:=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[
   momentum/.definition["MomentumConservationRules"]]]]/.definition["Topology"][[5]]/.unit];
 qm=mass[total-#]&/@particles;pairs=Table[If[i===j,0,mass[particles[[i]]+particles[[j]]]],{i,4},{j,4}];
 constantQ[value_]:=FreeQ[value,_FeynCalc`Pair|_FeynCalc`Momentum];
 If[constantQ[kernel],class="PhaseVolume";scalar=kernel];
 If[class===None,Do[
  ratio=Cancel[Together[kernel qm[[i]]^n]];
  If[constantQ[ratio],class="SingleComplement";power=n;scalar=ratio;Break[]],
  {i,4},{n,DeleteCases[Range[-data["MaximumPower"],data["MaximumPower"]],0]}]];
 If[class===None,Do[
  ratio=Cancel[Together[kernel Times@@qm[[pair]]]];
  If[constantQ[ratio],class="R6";scalar=ratio;Break[]],{pair,Subsets[Range[4],{2}]}]];
 If[class===None,Do[
  {a,b,c,d}=permutation;
  Do[ratio=Cancel[Together[kernel Last[candidate]]];
   If[constantQ[ratio],class=First[candidate];scalar=ratio;Break[]],
  {candidate,{{"R8a",pairs[[a,c]]pairs[[b,c]]pairs[[a,d]]pairs[[b,d]]},
    {"R8b",pairs[[a,c]]qm[[b]]pairs[[b,c]]qm[[a]]},
    {"R8r",pairs[[a,c]]qm[[b]]pairs[[b,d]]qm[[a]]}}}];
  If[class=!=None,Break[]],{permutation,Permutations[Range[4]]}]];
 If[class===None,cutFamilyFail["InclusiveScalarGeometryNotRecognized"]];
 normalization=data["Normalization"]scalar;
 If[MemberQ[{"PhaseVolume","SingleComplement"},class],
  exact=normalization FeynFacet`MasslessPhaseSpaceVolume[4,s,e]*If[class==="PhaseVolume",1,
    s^-power Beta[2-2e-power,2-2e]/Beta[2-2e,2-2e]];
  Return[<|"ExactValue"->FunctionExpand[exact],"Integral"->integral,"DimensionalRegulator"->e,
    "EvaluationMethod"->"RecursivePhysicalPhaseSpace","ScalarGeometry"->class,
    "ComplementMassPower"->power,"OriginalOrdinaryPrescriptionCertificate"->data["Certificate"],
    "UniversalScalarSources"->"Derived from dPhi4=s dt/(2Pi) dPhi2(q;p,K) dPhi3(K), K^2=s t; normalized t density Beta(2-2epsilon,2-2epsilon).",
    "Domain"->definition["Assumptions"],"MeasuredHardFunctionInput"->False|>,Module]];
 sgamma=FeynFacet`MasslessPhaseSpaceVolume[2,s,e]*((4Pi)^e/(16Pi^2 Gamma[1-e]))^2;
 {series,lower,upper}=Switch[class,
  "R6",{<|0->-1+Pi^2/6,1->-12+5Pi^2/6+9Zeta[3],
    2->-91+9Pi^2/2+45Zeta[3]+61Pi^4/180|>,0,2},
  "R8a",{<|-4->5,-3->0,-2->-20Pi^2/3,-1->-126Zeta[3],0->7Pi^4/18|>,-4,0},
  "R8b",{<|-4->3/4,-3->0,-2->-17Pi^2/12,-1->-44Zeta[3],0->-61Pi^4/60|>,-4,0},
  "R8r",{<|-4->1/4,-3->0,-2->-Pi^2/12,-1->7Zeta[3],0->23Pi^4/45|>,-4,0}];
 factor=normalization sgamma s^(If[class==="R6",0,-2]-2e);
 valuation=FeynFacet`DetermineMeromorphicLaurentLowerBound[factor,e];
 If[!IntegerQ[valuation]||Last[range]>upper+valuation,
  cutFamilyFail["InclusiveUniversalScalarOrderUnavailable",<|"ScalarGeometry"->class,
    "KnownScalarUpperOrder"->upper,"PrefactorLowerBound"->valuation,"RequestedRange"->range|>]];
 lo=Min[First[range],lower+valuation];hi=Last[range];
 matrix=FeynFacet`ExpandLaurentCoefficientMatrix[{{factor}},e,{hi-lower}];
 vector=<|"DimensionalRegulator"->e,"Dimension"->1,
  "Coefficients"->Association@KeyValueMap[{1,#1}->#2&,series],
  "LaurentLowerBounds"->{lower},"KnownThroughOrders"->{upper},"ExactTails"->{False}|>;
 result=If[AssociationQ[matrix],FeynFacet`MultiplyLaurentCoefficientMatrix[matrix,vector,{{lo,hi}}],matrix];
 If[!AssociationQ[result],cutFamilyFail["InclusiveScalarPrefactorOrderAuditFailed",<|"Cause"->result|>]];
 <|"Integral"->integral,"DimensionalRegulator"->e,"ScalarGeometry"->class,
  "Coefficients"->Association@Table[k->Lookup[result["Coefficients"],Key[{1,k}],0],{k,lo,hi}],
  "LaurentLowerBound"->lo,"KnownThroughOrder"->hi,"ExactTail"->False,
  "OrderCoverageVerified"->result["OrderCoverageVerified"],
  "EvaluationMethod"->"PublishedUniversalFourParticleScalarIntegral",
  "OriginalOrdinaryPrescriptionCertificate"->data["Certificate"],
  "UniversalScalarSources"-><|"URL"->"https://arxiv.org/abs/hep-ph/0311276",
    "Equations"->Switch[class,"R6",{"3.3","4.13","4.25"},"R8a",{"3.4","4.13","4.18"},
     "R8b",{"3.5","4.13","4.29"},"R8r",{"4.13","4.30","4.31"}]|>,
  "Domain"->definition["Assumptions"],"MeasuredHardFunctionInput"->False,
  "Scope"->"Universal unweighted scalar phase-space integral with explicit finite coverage. No amplitude, flavor sum, measured coefficient or endpoint contact is supplied."|>
],"CutFamily"];
End[];EndPackage[];
