Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
coordinates=FeynFacet`MasslessPairPhaseSpaceCoordinates[{pk1,pk2,pk3,pk4},pq,ps,pe,{pr,px,py,pa,pb}];
If[!AssociationQ[coordinates],Print[InputForm[coordinates]];Exit[1]];
domain=coordinates["PhysicalDomain"];gram=coordinates["GramMatrix"];
FTTest`FTAssert["all invariant momenta conserve the total mass and pair angle",
 FullSimplify[Total[Values[coordinates["PairInvariants"]]]==ps&&
  ps gram[[1,2]]/(2Total[gram[[1]]]Total[gram[[2]]])==pr,domain]===True];
FTTest`FTAssert["the exact Gram determinant includes the dimensional azimuth geometry",
 FullSimplify[Det[gram]-coordinates["GramDeterminant"],domain]===0];
FTTest`FTAssert["the forward and inverse energy maps agree on the complete interior",
 FullSimplify[({px,py}/.coordinates["InverseEnergyMap"]/.coordinates["ScalarProductRules"])-{px,py},domain]==={0,0}];
FTTest`FTAssert["the recoil angle denominators have the derived correlated-limit form",
 FullSimplify[coordinates["RecoilAngleCosine"]^2+coordinates["RecoilAngleSine"]^2-1,domain]===0&&
 Factor[coordinates["RecoilAngleDenominator"]-(1-pr+pr(1-px)(1-py))]===0];
FTTest`FTAssert["the labeled recoil-particle interchange is an angular map, not a factorial",
 FullSimplify[gram/.{pa->1-pa,pb->1-pb},domain]===FullSimplify[gram[[{1,2,4,3},{1,2,4,3}]],domain]];
FTTest`FTAssert["the absolute pair prefactor follows the two one-particle measures",
 FullSimplify[FunctionExpand[coordinates["Prefactor"]/
  ((4Pi)^(3pe)Gamma[1-pe]/(2048Pi^5 Gamma[2-2pe]^2))],pe<0]===1];
integrated=coordinates["Prefactor"]ps^(2-3pe)*
 Beta[2-2pe,1-pe]Beta[1-pe,1-pe]Beta[2-2pe,2-2pe];
FTTest`FTAssert["the analytic beta integrals equal independent recursive four-body phase space",
 FullSimplify[FunctionExpand[integrated/FeynFacet`MasslessPhaseSpaceVolume[4,ps,pe]],pe<0&&ps>0]===1];
(* The azimuth has mean zero. Integrate the remaining quadratic polar moment
   against its beta measure, probing D-dependent angular correlation. *)
averagedAzimuth=(gram[[1,3]]gram[[2,3]])/.pb->1/2;
polar=Expand[averagedAzimuth];
angularMoment=Total[Coefficient[polar,pa,#]Pochhammer[1-pe,#]/Pochhammer[2-2pe,#]&/@Range[0,2]];
expectedMoment=Times@@coordinates["ResolvedRecoilProducts"]/4*(1+coordinates["RecoilAngleCosine"]/(3-2pe));
FTTest`FTAssert["the recoil angular correlation has the full-dimensional rotational average",
 Factor[angularMoment-expectedMoment]===0];
zeta=coordinates["RecoilAngleFraction"];
FTTest`FTAssert["moving angular collinear loci agree with the exact invariants",
 FullSimplify[gram[[2,3]]/.{pa->zeta,pb->0},domain]===0&&
 FullSimplify[gram[[2,4]]/.{pa->1-zeta,pb->1},domain]===0];
FTTest`FTAssert["the coordinate record does not claim orientation or endpoint completion",
 TrueQ[coordinates["ScalarProductObservablesOnly"]]&&!coordinates["OrientationSignRetained"]&&
 !coordinates["EndpointResolved"]&&!coordinates["IntegralEvaluated"]];

geometry=<|"Name"->PairChartTest,"FinalMomenta"->{pk1,pk2,pk3,pk4},"TotalMomentum"->pq,
 "ExternalMomenta"->{pq},"KinematicRules"->{FeynCalc`SPD[pq]->ps},"Assumptions"->ps>0|>;
observable=ps FeynCalc`SPD[pfirst,psecond]/(2FeynCalc`SPD[pq,pfirst]FeynCalc`SPD[pq,psecond]);
makeDefinition[obs_]:=Module[{records},
 records=FeynFacet`CreateFinalStateMeasurementDefinitions[geometry,<|"Arguments"->{pfirst,psecond},
  "Observable"->obs,"Weight"->1,"Variable"->pz,
  "Tuples"-><|"Ordered"->True,"IncludeRepeated"->False|>|>];
 SelectFirst[records,MemberQ[#["ParticleTuples"],{1,2}]&]["Definition"]];
definition=makeDefinition[observable];
push=FeynFacet`ConstructPhaseSpaceMeasurementPushforward[definition,coordinates];
FTTest`FTAssert["a card-generated pair-angle cut selects its coordinate",
 AssociationQ[push]&&Length[push["Branches"]]===1&&First[push["Branches"]]["Root"]===pz];
If[!AssociationQ[push],Print[InputForm[push]];FTTest`FTReport[];Exit[1]];
FTTest`FTAssert["the physical measurement Jacobian is present exactly once",
 FullSimplify[First[push["Branches"]]["MeasurementDensity"]/(coordinates["Density"]/.pr->pz),
  (domain/.pr->pz)&&pe<0]===1];
scaled=FeynFacet`ConstructPhaseSpaceMeasurementPushforward[makeDefinition[2observable],coordinates,
 <|"Assumptions"->0<pz<2|>];
FTTest`FTAssert["a rescaled card observable derives its own nonunit Jacobian",
 AssociationQ[scaled]&&First[scaled["Branches"]]["Root"]===pz/2&&
 FullSimplify[First[scaled["Branches"]]["MeasurementDensity"]/(coordinates["Density"]/.pr->pz/2),
  (domain/.pr->pz/2)&&pe<0]===1/2];
energyFraction=2FeynCalc`SPD[pq,pfirst]/ps;
quadratic=FeynFacet`ConstructPhaseSpaceMeasurementPushforward[
 makeDefinition[energyFraction(1-energyFraction)],coordinates,
 <|"EliminateVariable"->px,"Assumptions"->0<pz<1/4|>];
FTTest`FTAssert["a nonlinear card observable retains both physical roots and their derivatives",
 AssociationQ[quadratic]&&Length[quadratic["Branches"]]===2&&
 AllTrue[quadratic["Branches"],Function[branch,
  FullSimplify[branch["MeasurementDensity"]/(coordinates["Density"]/.branch["EliminationRule"]),
   (domain/.branch["EliminationRule"])&&0<pz<1/4&&pe<0]===1/Sqrt[1-4pz]]]];
FTTest`FTAssert["dotted particle cuts cannot use the on-shell scalar chart",
 FailureQ[FeynFacet`ConstructPhaseSpaceMeasurementPushforward[Join[definition,<|"CutPowers"->{2,1,1,1,1}|>],coordinates]]];
seed=FeynFacet`EvaluatePairMeasurementEulerMaster[definition,
 FeynCalc`GLI[definition["Topology"][[1]],ConstantArray[1,5]],pe];
seedExpected=2coordinates["Prefactor"]ps^(-3pe)(pz(1-pz))^-pe*
 Beta[1-2pe,1-pe]Beta[1-2pe,2-3pe]Hypergeometric2F1[1-2pe,1-2pe,3-5pe,pz];
FTTest`FTAssert["the physical polynomial-cut period agrees with independent sequential beta integrals",
 AssociationQ[seed]&&AllTrue[{{pe->-1/3,ps->2,pz->2/7},{pe->-1/5,ps->3,pz->3/5}},
  Abs[(N[seed["Value"]/.#,35]-N[seedExpected/.#,35])/N[seedExpected/.#,35]]<10^-28&]];
FTTest`FTAssert["explicit seed periods have no coordinates or free boundary constants",
 AssociationQ[seed]&&FreeQ[seed["Value"],_Integrate|_Inactive|_FeynCalc`GLI]&&
 TrueQ[seed["PhysicalBoundaryConstantsFixed"]]&&!seed["EndpointDistributionIncluded"]];
FTTest`FTAssert["the physical seed evaluator rejects dotted cut periods",
 FailureQ[FeynFacet`EvaluatePairMeasurementEulerMaster[definition,
  FeynCalc`GLI[definition["Topology"][[1]],{1,1,1,1,2}],pe]]];
FTTest`FTAssert["a dimension declaration cannot be silently replaced by four minus two epsilon",
 FailureQ[FeynFacet`ConstructPhaseSpaceMeasurementPushforward[Join[definition,<|"Dimension"->6-2pe|>],coordinates]]&&
 FailureQ[FeynFacet`ConstructPhaseSpaceMeasurementPushforward[definition,Join[coordinates,<|"Dimension"->6-2pe|>]]]];
complementFamily=FeynFacet`CreateCutIntegralDefinition[Join[definition,<|"Topology"->
 ReplacePart[definition["Topology"],2->Join[definition["Topology"][[2]],
  FeynCalc`FCI[{FeynCalc`SFAD[pq-pk1],FeynCalc`SFAD[pq-pk1-pk2]}]]]|>]];
complementIntegral=FeynCalc`GLI[definition["Topology"][[1]],{1,1,1,1,1,1,0}];
recoilIntegral=FeynCalc`GLI[definition["Topology"][[1]],{1,1,1,1,1,0,1}];
complementPeriod=FeynFacet`EvaluatePairMeasurementEulerMaster[complementFamily,complementIntegral,pe];
recoilPeriod=FeynFacet`EvaluatePairMeasurementEulerMaster[complementFamily,recoilIntegral,pe];
complementExpected=2coordinates["Prefactor"]ps^(-1-3pe)(pz(1-pz))^-pe*
 Beta[1-2pe,1-pe]Beta[1-2pe,1-3pe]Hypergeometric2F1[1-2pe,1-2pe,2-5pe,pz];
recoilExpected=complementExpected*Beta[1-2pe,-pe]/Beta[1-2pe,1-pe];
FTTest`FTAssert["positive complement masses require and obtain the original-product prescription certificate",
 AssociationQ[complementPeriod]&&AssociationQ[recoilPeriod]&&
 FeynFacet`RequireOrdinaryPrescriptionCertificate[complementPeriod["OriginalOrdinaryPrescriptionCertificate"],"GenericKinematics"]===True&&
 FeynFacet`RequireOrdinaryPrescriptionCertificate[recoilPeriod["OriginalOrdinaryPrescriptionCertificate"],"GenericKinematics"]===True];
FTTest`FTAssert["tagged complement and internal-collinear periods agree with independent beta integration",
 AssociationQ[complementPeriod]&&AssociationQ[recoilPeriod]&&AllTrue[
  {{complementPeriod["Value"],complementExpected},{recoilPeriod["Value"],recoilExpected}},
  Abs[(N[First[#]/.{pe->-1/3,ps->2,pz->2/7},35]-N[Last[#]/.{pe->-1/3,ps->2,pz->2/7},35])/
    N[Last[#]/.{pe->-1/3,ps->2,pz->2/7},35]]<10^-28&]];
Print["PAIR PHASE SPACE COORDINATES TEST COMPLETE"];
FTTest`FTReport[];
