(* Joint rotational average of the physical transverse two-plane.
   This is an observable tensor identity, not a universal equivalence of all
   gamma5 prescriptions. See Pro review 15 and arXiv:1409.5131, 2510.00100. *)
BeginPackage["FeynFacet`"];
AverageLongitudinalEpsilonProduct::usage="AverageLongitudinalEpsilonProduct[{a,b},{c,d},p,q,request] averages E4(a,b,p,q) E4(c,d,p,q) over the orientation of the physical transverse two-plane at fixed full-D scalar products. p is null and p.q is nonzero. Request supplies exact KinematicRules and Assumptions. All integrated vectors must rotate jointly; additional fixed transverse directions are outside this identity.";
AveragedDISHelicityDensity::usage="AveragedDISHelicityDensity[leg,p,q,{mu,nu},request] gives the joint average of one incoming PDF helicity spin density and the 2g1 current coefficient projector. It replaces their product, not the standalone PDF definition. Quark, antiquark and gluon are supported; all other tensors, state sums and measurement factors must be full-D covariant under the joint transverse rotation.";
Begin["`Private`"];
currentSpinAverageFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"CurrentSpinAverage"];
AverageLongitudinalEpsilonProduct[{a_Symbol,b_Symbol},{c_Symbol,d_Symbol},
 p_Symbol,q_Symbol,request_Association]:=Catch[Module[
 {kin,conditions,pq,p2,q2,transverse,weight,value},
 If[!DuplicateFreeQ[{a,b,c,d,p,q}]||
    !ContainsAll[Keys[request],{"KinematicRules","Assumptions"}],
  currentSpinAverageFail["DistinctTensorIndicesAndLongitudinalFrameRequired"]];
 kin=FeynCalc`FCI[request["KinematicRules"]];conditions=request["Assumptions"];
 If[!MatchQ[kin,{(_Rule)..}],currentSpinAverageFail["ExactLongitudinalKinematicRulesRequired"]];
 {p2,q2,pq}=FeynCalc`FCI[{FeynCalc`SPD[p],FeynCalc`SPD[q],FeynCalc`SPD[p,q]}]/.kin;
 If[!FreeQ[{p2,q2,pq},_FeynCalc`Pair|_Real|_Failure|_Missing]||
   !TrueQ[FullSimplify[p2==0&&Element[{p2,q2,pq},Reals]&&pq!=0,Assumptions->conditions]],
  currentSpinAverageFail["RealNullLongitudinalMomentumAndNonzeroProjectionRequired"]];
 transverse[i_,j_]:=FeynCalc`MTD[i,j]-
  (FeynCalc`FVD[p,i]FeynCalc`FVD[q,j]+FeynCalc`FVD[q,i]FeynCalc`FVD[p,j])/pq+
  q2 FeynCalc`FVD[p,i]FeynCalc`FVD[p,j]/pq^2;
 (* Contracting both tensor pairs fixes the coefficient uniquely:
    weight (D-2)(D-3) = 2, the norm of an oriented physical area form. *)
 weight=2/((D-2)(D-3));
 value=FeynCalc`FCI[pq^2 weight(transverse[a,c]transverse[b,d]-transverse[a,d]transverse[b,c])];
 <|"Value"->value,"TransverseDimension"->D-2,"PhysicalPlaneDimension"->2,
  "IsotropicWeight"->weight,"LarinNormalizationRatio"->(D-2)(D-3)/2,
  "PhysicalMomenta"->{p,q},"KinematicRules"->kin,"Assumptions"->conditions,
  "Scope"->"Two longitudinally anchored physical epsilon tensors; joint rotations of every integrated vector, with no additional fixed transverse direction."|>
],"CurrentSpinAverage"];
AveragedDISHelicityDensity[leg_Association,p_Symbol,q_Symbol,{mu_Symbol,nu_Symbol},
 request_Association]:=Catch[Module[
 {density,species,spin,average,pq,a,b,indices,sign,kin},
 If[Lookup[leg,"Role",None]=!="PDF"||Lookup[leg,"Polarization",None]=!="L"||
   Lookup[leg,"Momentum",None]=!=p||Lookup[leg,"MomentumSpace",None]=!="Physical4",
  currentSpinAverageFail["OnePhysicalIncomingHelicityPDFRequired"]];
 density=FeynFacet`PartonicSpinDensity[leg];
 If[!AssociationQ[density],currentSpinAverageFail["NormalizedHelicityDensityRequired"]];
 species=leg["Species"];kin=FeynCalc`FCI[Lookup[request,"KinematicRules",{}]];
 pq=FeynCalc`FCI[FeynCalc`SPD[p,q]]/.kin;
 If[species==="g",
  If[Lookup[leg,"ReferenceMomentum",None]=!=q,currentSpinAverageFail["GluonReferenceInDeclaredCurrentFrameRequired"]];
  indices=leg["Indices"];
  average=AverageLongitudinalEpsilonProduct[indices,{mu,nu},p,q,request];
  If[FailureQ[average],Throw[average,"CurrentSpinAverage"]];
  spin=-average["Value"]/(2pq^2),
  If[!MatchQ[species,{"q"|"qbar",_}],currentSpinAverageFail["QuarkAntiquarkOrGluonRequired"]];
  a=Unique["helicityIndex$"];b=Unique["helicityIndex$"];
  average=AverageLongitudinalEpsilonProduct[{a,b},{mu,nu},p,q,request];
  If[FailureQ[average],Throw[average,"CurrentSpinAverage"]];
  sign=If[First[species]==="q",1,-1];
  spin=sign average["Value"]FeynCalc`FCI[FeynCalc`GAD[a].FeynCalc`GAD[b].FeynCalc`GSD[p]]/(4pq^2)];
 <|"SpinDensity"->spin,"ColorAverage"->density["ColorAverage"],
  "OriginalSpinDensity"->density["SpinDensity"],
  "ReplacesCurrentCoefficientProjector"->FeynFacet`DISCurrentProjectors[p,q,{mu,nu}]["CoefficientProjectors"]["2g1"],
  "Average"->KeyDrop[average,"Value"],
  "RawOperatorContract"->"Normalized massless Larin electromagnetic g1, equal to the joint angular average of the declared BMHV density-current pair.",
  "AdditionalPhysicalTransverseTensorsAllowed"->False,
  "StandalonePDFDefinitionChanged"->False|>
],"CurrentSpinAverage"];

(* Applicability is checked from the actual legs, projector and integration
   geometry. A failed optional preparation leaves the exact BMHV path available.
   The scalar measurement must be invariant under this same joint rotation. *)
currentJointHelicityDensityData[setup_Association,projection_,geometry_Association]:=Catch[Module[
 {legs,polarized,p,q,current,indices,frame,all,integrated,other,densities,average,
  momentumRules,momenta,references,geometryCheck,position},
 legs=Lookup[setup,"SpinDensities",{}];
 polarized=Select[legs,Lookup[#,"Polarization",None]=!="U"&];
 If[Length[polarized]=!=1||Lookup[First[polarized],"Role",None]=!="PDF"||
   Lookup[First[polarized],"Polarization",None]=!="L",
  currentSpinAverageFail["OneIncomingHelicityAndUnpolarizedRemainingLegsRequired"]];
 current=Lookup[setup,"Currents",{}];
 If[Length[current]=!=1,currentSpinAverageFail["OneElectromagneticCurrentRequired"]];
 current=First[current];p=First[polarized]["Momentum"];q=current["Momentum"];
 indices=Lookup[current["Indices"],{"Conjugate","Amplitude"}];frame={p,q};
 If[Sort[Lookup[setup,"PhysicalMomenta",{}]]=!=Sort[frame]||
   Sort[Lookup[geometry,"PhysicalMomenta",{}]]=!=Sort[frame]||
   FeynCalc`FCI[projection]=!=FeynCalc`FCI[
    FeynFacet`DISCurrentProjectors[p,q,indices]["CoefficientProjectors"]["2g1"]],
  currentSpinAverageFail["PhysicalDISHelicityProjectorAndLongitudinalFrameRequired"]];
 other=Select[legs,#["Momentum"]=!=p&];
 If[!AllTrue[other,Lookup[#,"MomentumSpace",None]==="IntegratedD"&],
  currentSpinAverageFail["RemainingSpinDensitiesMustBeFullDimensional"]];
 geometryCheck=FeynFacet`AverageEvanescentScalarProducts[0,geometry];
 If[!AssociationQ[geometryCheck],Throw[geometryCheck,"CurrentSpinAverage"]];
 integrated=geometry["IntegratedMomenta"];all=Join[frame,integrated];
 momentumRules=Lookup[geometry,"MomentumRules",{}];
 momenta=DeleteDuplicates[Join[Flatten[List@@setup["PartonMomentum"]],
   setup["ForwardAmplitudes"]["LoopMomenta"],setup["ConjugateAmplitudes"]["LoopMomenta"]]];
 If[!AllTrue[momenta,angularLinearMomentumQ[#/.momentumRules,all]&],
  currentSpinAverageFail["EveryCutAndVirtualMomentumMustShareTheJointAverage"]];
 references=Join[Lookup[Select[legs,KeyExistsQ[#,"ReferenceMomentum"]&],"ReferenceMomentum",{}],
  Lookup[Select[Lookup[setup,"UnobservedGluonStates",{}],KeyExistsQ[#,"ReferenceMomentum"]&],"ReferenceMomentum",{}]];
 If[!AllTrue[references,angularLinearMomentumQ[#/.momentumRules,all]&],
  currentSpinAverageFail["GluonReferencesMustRotateWithTheDeclaredMomenta"]];
 average=FeynFacet`AveragedDISHelicityDensity[First[polarized],p,q,indices,geometry];
 If[!AssociationQ[average],Throw[average,"CurrentSpinAverage"]];
 densities=FeynFacet`PartonicSpinDensity/@legs;
 If[!AllTrue[densities,AssociationQ],currentSpinAverageFail["NormalizedPartonicDensitiesRequired"]];
 position=First[FirstPosition[Lookup[legs,"Momentum"],p,Missing[],{1},Heads->False]];
 densities[[position]]=Join[densities[[position]],KeyTake[average,{"SpinDensity","ColorAverage"}]];
 <|"Densities"->densities,"PhysicalMomenta"->frame,"JointMomenta"->all,
  "MomentumRules"->momentumRules,"Metadata"->KeyDrop[average,{"SpinDensity","OriginalSpinDensity",
   "ReplacesCurrentCoefficientProjector"}]|>
],"CurrentSpinAverage"];
(* Before insertion, all amplitude tensors must be D-dimensional. An existing
   physical metric, epsilon or axial vertex would invalidate the two-epsilon
   derivation. Physical longitudinal vectors alone are allowed. *)
currentJointHelicityAmplitudeQ[expression_,data_Association]:=Module[{value,vectors},
 value=FeynCalc`FCI[expression];
 If[!FreeQ[value,_FeynCalc`Eps|FeynCalc`DiracGamma[5|6|7]|
   FeynCalc`LorentzIndex[_]|FeynCalc`LorentzIndex[_,4]|
   FeynCalc`DiracGamma[_]|FeynCalc`DiracGamma[_,4]],Return[False]];
 vectors=DeleteDuplicates[Cases[value,_FeynCalc`Momentum,{0,Infinity}]];
 AllTrue[vectors,Function[vector,Which[
  MatchQ[vector,FeynCalc`Momentum[_FeynCalc`Polarization,D]],True,
  Length[vector]===2&&Last[vector]===D,
   angularLinearMomentumQ[First[vector]/.data["MomentumRules"],data["JointMomenta"]],
  Length[vector]===1,
   angularLinearMomentumQ[First[vector],data["PhysicalMomenta"]],
  True,False]]]
];

End[];EndPackage[];
