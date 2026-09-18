Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->InclusiveScalarTest,
 "FinalMomenta"->{k1,k2,k3,k4},"TotalMomentum"->q,"ExternalMomenta"->{q},
 "KinematicRules"->{FeynCalc`SPD[q]->s},"Assumptions"->s>0|>];
makeFamily[momenta_]:=FeynFacet`CreateCutIntegralDefinition[Join[phase,<|"Topology"->
 ReplacePart[phase["Topology"],2->Join[phase["Topology"][[2]],
 FeynCalc`FCI[FeynCalc`SFAD[#]&/@(momenta/.phase["MomentumConservationRules"])]]]|>]];
volumeFamily=makeFamily[{}];volume=FeynFacet`EvaluateInclusiveFourParticleMaster[volumeFamily,
 FeynCalc`GLI[phase["Topology"][[1]],{1,1,1,1}],e,{0,0}];
FTTest`FTAssert["unmeasured volume matches the independently normalized recursive phase space",
 AssociationQ[volume]&&Simplify[volume["ExactValue"]-FeynFacet`MasslessPhaseSpaceVolume[4,s,e]]===0];
FTTest`FTAssert["physical scalar formulas reject inconsistent recoil metadata",
 FailureQ[FeynFacet`EvaluateInclusiveFourParticleMaster[
  Join[volumeFamily,<|"MomentumConservationRules"->{k4->2q-k1-k2-k3}|>],
  FeynCalc`GLI[phase["Topology"][[1]],{1,1,1,1}],e,{0,0}]]];
singleFamily=makeFamily[{q-k1}];single=FeynFacet`EvaluateInclusiveFourParticleMaster[singleFamily,
 FeynCalc`GLI[phase["Topology"][[1]],{1,1,1,1,2}],e,{-1,0}];
reference=FeynFacet`MasslessPhaseSpaceVolume[4,1,-1/4]*NIntegrate[t^(-1/2)(1-t)^(3/2),{t,0,1},WorkingPrecision->35]/Beta[5/2,5/2];
FTTest`FTAssert["a singular complementary mass power agrees with convergent cluster-mass quadrature",
 AssociationQ[single]&&Abs[N[single["ExactValue"]/.{s->1,e->-1/4},35]-reference]<10^-28];
pairFamily=makeFamily[{q-k1,q-k2}];pairIntegral=FeynCalc`GLI[phase["Topology"][[1]],{1,1,1,1,1,1}];
pair=FeynFacet`EvaluateInclusiveFourParticleMaster[pairFamily,pairIntegral,e,{0,1}];
(* Integrate eta analytically to avoid unnecessary adaptive sampling at its corner. *)
reference=NIntegrate[-Log[1-xi]/xi-1,{xi,0,1},WorkingPrecision->40,AccuracyGoal->28,PrecisionGoal->28]/(2048Pi^5);
FTTest`FTAssert["the R6 constant agrees with its independent Euler integral",
 AssociationQ[pair]&&Abs[N[pair["Coefficients"][0]/.s->1,30]-reference]<10^-22];
FTTest`FTAssert["unavailable universal scalar orders remain a failure",
 FailureQ[FeynFacet`EvaluateInclusiveFourParticleMaster[pairFamily,pairIntegral,e,{0,3}]]];
FTTest`FTAssert["scalar provenance identifies the universal source and excludes a measured hard function",
 pair["UniversalScalarSources"]["URL"]==="https://arxiv.org/abs/hep-ph/0311276"&&!pair["MeasuredHardFunctionInput"]];
FTTest`FTAssert["dotted particle cuts cannot use physical on-shell scalar formulas",
 FailureQ[FeynFacet`EvaluateInclusiveFourParticleMaster[pairFamily,
 FeynCalc`GLI[phase["Topology"][[1]],{2,1,1,1,1,1}],e,{0,0}]]];
r8Momenta={{k1+k3,k2+k3,k1+k4,k2+k4},
 {k1+k3,q-k2,k2+k3,q-k1},{k1+k3,q-k2,k2+k4,q-k1}};
Do[r8=FeynFacet`EvaluateInclusiveFourParticleMaster[makeFamily[r8Momenta[[i]]],
 FeynCalc`GLI[phase["Topology"][[1]],ConstantArray[1,8]],e,{-4,-4}];
 FTTest`FTAssert["unrestricted scalar matching identifies "<> {"R8a","R8b","R8r"}[[i]],
  AssociationQ[r8]&&r8["ScalarGeometry"]==={"R8a","R8b","R8r"}[[i]]&&
  Simplify[r8["Coefficients"][-4]-{5,3/4,1/4}[[i]]/(2048Pi^5 s^2)]===0],{i,3}];
Print["INCLUSIVE FOUR PARTICLE SCALARS TEST COMPLETE"];FTTest`FTReport[];
