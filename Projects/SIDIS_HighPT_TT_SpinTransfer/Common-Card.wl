(* Physical spin relations are constructed from the external Gram matrix. *)
Module[{tau,rules,frame},
 tau=(1-x)(1-z)(1-w);
 rules={FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->-Q2,FeynCalc`SPD[k1]->0,
  FeynCalc`SPD[p,q]->Q2/(2 x),FeynCalc`SPD[p,k1]->Q2 z/(2 x),
  FeynCalc`SPD[q,k1]->Q2(1-x-z-tau)/(2 x)};
 frame=FeynFacet`ScatteringPlaneSpinFrame[<|
  "ExternalMomenta"->{p,q,k1},"KinematicRules"->rules,
  "TimelikeVector"->(q+2 x p)/Sqrt[Q2],"BeamMomentum"->p,"ObservedMomentum"->k1,
  "SpinVectors"->{spinX,spinOutX,spinY},"Assumptions"->Q2>0&&0<x<1&&0<z<1&&0<w<=1|>];
 If[!AssociationQ[frame],Return[frame]];
 <|
 "Project"->"SIDIS_HighPT_TT_SpinTransfer",
 "Observable"->"IndependentAzimuthSpinTransferMoment",
 "StructureFunctions"->{"TransversePhoton","LongitudinalPhoton"},
 "Orders"-><|"LO"->{"q-q"},"NLO"->{"q-q","q-qb"}|>,
 "Channels"-><|
  "q-q"-><|"Incoming"->{{"q","u"}},"Observed"->{"q","u"}|>,
  "q-qb"-><|"Incoming"->{{"q","u"}},"Observed"->{"qb","u"}|>|>,
 "MinimumChannelOrders"-><|"q-q"->0,"q-qb"->1|>,
 "SpeciesMap"-><|
  {"q","u"}->FeynArts`F[3,{1}], {"qb","u"}->-FeynArts`F[3,{1}],
  {"q","c"}->FeynArts`F[3,{2}], {"qb","c"}->-FeynArts`F[3,{2}],
  {"q","d"}->FeynArts`F[4,{1}], {"qb","d"}->-FeynArts`F[4,{1}], "g"->FeynArts`V[5]|>,
 "Current"-><|"Field"->FeynArts`V[1],"Side"->"Incoming","Momentum"->q,"MomentumSpace"->"Physical4",
  "Indices"-><|"Conjugate"->mu,"Amplitude"->nu|>,"Coupling"->FeynCalc`SMP["e"]|>,
 "IncomingMomenta"->{p}, "FinalMomenta"->{k1,k2,k3}, "ObservedMomentumSpace"->"Physical4",
 "Polarization"-><|"Incoming"->{"T"},"Observed"->"T"|>,
 "SpinParameters"-><|"Transverse"->{spinX,spinOutX}|>,
 "ProcessDefaults"-><|
  "Model"->"SMQCD", "InsertionLevel"->{FeynArts`Classes},
  "ExcludeTopologies"->{FeynArts`Tadpoles,FeynArts`WFCorrections},
  "ExcludeParticles"->{FeynArts`S[_],FeynArts`V[1],FeynArts`V[2],FeynArts`V[3]},
  "MasslessQuarkFlavors"-><|"UpType"->nU,"DownType"->nD|>,
  "ElectromagneticCharges"-><|"UpType"->eU,"DownType"->eD|>|>,
 "Kinematics"-><|
  "BornConditions"->Q2>0&&0<x<1&&0<z<1&&w==1,
  "RadiativeConditions"->Q2>0&&0<x<1&&0<z<1&&0<w<1|>,
 "Assembly"-><|
  "IntegrationMethod"->"FixedObservedCurrent", "ApplyKinematicsInFORM"->True,
  "ContractLorentzIndices"->True,
  "Scale"->Q2, "Variables"->{x,z,w},
  "Assumptions"->Q2>0&&muR2>0&&0<x<1&&0<z<1&&0<w<=1,
  "Domain"->Q2>0&&0<x<1&&0<z<1&&0<w<=1,
  "DensityConvention"->"Current tensor per physical observed d^3 k/((2 Pi)^3 2 E_k), no lepton flux or QED coupling",
  "ObservableNormalization" -> <|"Tensor" -> "CutTensor", "Coefficient" -> "TensorProjection"|>,
  "CurrentProjectors"-><|
   "TransversePhoton"->(FeynCalc`FV[spinX,mu]FeynCalc`FV[spinX,nu]+
    FeynCalc`FV[spinY,mu]FeynCalc`FV[spinY,nu])/2,
   "LongitudinalPhoton"->FeynCalc`FV[q+2 x p,mu]FeynCalc`FV[q+2 x p,nu]/Q2|>,
  "SpinCorrelations"->{
   <|"Weight"->1/2,"SpinVectors"-><|p->spinX,k1->spinOutX|>|>,
   <|"Weight"->1/2,"SpinVectors"-><|p->spinY,k1->spinY|>|>},
  "KinematicRules"->frame["KinematicRules"],
  "ScalarIntegration"-><|
   "PhysicalMomenta"->frame["PhysicalMomenta"],"NormalMomentum"->spinY,"KinematicRules"->frame["PhysicalKinematicRules"],
   "MomentumRules"->frame["MomentumRules"],"TimelikeMomentum"->frame["Basis"]["Time"],
   "DimensionalRegulator"->Global`Epsilon,"Assumptions"->frame["Assumptions"]
  |>,
  "RealPhaseSpace"-><|"FinalMomenta"->{k2,k3},"TotalMomentum"->p+q-k1,
   "ExternalMomenta"->{p,q,k1},"KinematicRules"->rules,
   "Assumptions"->Q2>0&&0<x<1&&0<z<1&&0<w<1,
   "AuxiliaryScalarProducts"->{FeynCalc`SPD[k2,p],FeynCalc`SPD[k2,k1]}|>,
  "BornMomentumRules"->{k2->p+q-k1},
  "BornConstraints"->{FeynCalc`SPD[p+q-k1]},
  "DistributionBasis"-><|"Axes"->{<|"Variable"->w,"Endpoint"->1,"Interval"->{0,1},"Distance"->1-w,"NormalVariable"->endpointW|>}|>,
  "CollinearConvolution"->"MomentumRescaling",
  "FactorizationLegs"-><|
   "Incoming"-><|"Role"->"PDF","Index"->1,"Variable"->xi|>,
   "Observed"-><|"Role"->"FF","Variable"->zeta|>|>
 |>,
 "Counterterms"-><|
  "BareCouplingFactor"->(4 Pi)^(-Global`Epsilon) Exp[EulerGamma Global`Epsilon],
  "Coupling"->FeynFacet`\[Alpha]s,"RenormalizationScaleSquared"->muR2,
  "FactorizationScalesSquared"-><|"Incoming"->muF2,"Observed"->muD2|>,
  "Schemes"-><|"Incoming"->"MSbar","Observed"->"MSbar"|>,
  "KernelParameters"-><|"CA"->FeynCalc`CA,"CF"->FeynCalc`CF,"TR"->1/2,"FlavorCount"->nU+nD|>|>,
 "BareOperatorSchemes"-><|"Incoming"->"MSbar","Observed"->"MSbar"|>,
 "ColorRules"->{}, "BornCouplingPower"->1,
 "ResultEpsilonRanges"-><|"LO"->{0,0},"NLO"->{0,0}|>,
 "Execution"-><|"Kernels"->8,"KiraThreads"->8,"ReconstructionThreads"->8|>,
 "BareSourceContributions"-><|"LO"-><|"q-q"-><|"Born"-><|
  "Contribution"->"Born","AmplitudeLoops"->{0,0},"UnobservedPartons"->{"g"}|>|>|>|>
 |>
]
