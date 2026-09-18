Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Name"->PushforwardTest,"FinalMomenta"->{pk1,pk2,pk3},"TotalMomentum"->pq,
 "ExternalMomenta"->{pq},"KinematicRules"->{FeynCalc`SPD[pq]->ps},"Assumptions"->ps>0|>;
observable=ps FeynCalc`SPD[pk1,pk2]/(2FeynCalc`SPD[pq,pk1]FeynCalc`SPD[pq,pk2]);
definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[geometry,<|
 "Measurements"->{<|"Variable"->pz,"Observable"->observable|>}|>]];
assumptions=ps>0&&0<pz<1;
chart=FeynFacet`ConstructThreeParticleMeasurementPushforward[definition,<|
 "Parameters"->{px,py},"DimensionalRegulator"->pe,"Assumptions"->assumptions|>];
FTTest`FTAssert["the physical measurement has one proved root on the entire open interval",
 AssociationQ[chart]&&Length[chart["Branches"]]===1&&chart["Interval"]==={0,1}];
If[!AssociationQ[chart],Print[InputForm[chart]];Exit[1]];
branch=First[chart["Branches"]];
FTTest`FTAssert["the energy root is derived from the measurement polynomial",
 Factor[branch["Root"]-(1-px)/(1-pz px)]===0];
weight=FeynCalc`FCI[FeynCalc`SPD[pq,pk1]FeynCalc`SPD[pq,pk2]/ps^2]/.branch["ScalarProductRules"];
kernel=weight branch["MeasurementDensity"];
expectedKernel=chart["Normalization"](pz(1-pz))^-pe (px(1-px))^(2-2pe)/(4(1-pz px)^(3-2pe));
FTTest`FTAssert["the dimensional phase space, energy weight and delta numerator occur exactly once",
 FullSimplify[kernel/expectedKernel,assumptions&&0<px<1]===1];
pairFraction=Factor[(2FeynCalc`FCI[FeynCalc`SPD[pk1,pk2]]/ps)/.branch["ScalarProductRules"]];
bubble=FeynFacet`EvaluateOneLoopScalarFunctions[FeynCalc`B0[ps,0,0],pe,ps>0];
rational=Cancel[weight branch["Jacobian"]branch["MeasurementNumerator"]];
integral=FeynFacet`IntegrateUnivariateEulerProduct[rational,
 {{branch["GramPolynomial"],-pe},{pairFraction,-pe}},{px,0,1},assumptions];
exact=chart["Normalization"]bubble integral["Value"];
expected=chart["Normalization"]bubble pz^(-2pe)(1-pz)^-pe/4*
 Beta[3-3pe,3-3pe]Hypergeometric2F1[3-3pe,3-3pe,6-6pe,pz];
FTTest`FTAssert["a timelike bubble insertion integrates to its independent beta/Gauss form",
 AssociationQ[integral]&&FullSimplify[exact/expected,assumptions&&0<pe<1/2]===1];
point={ps->2,pz->1/3,pe->1/5};
numerical=NIntegrate[Evaluate[(kernel bubble pairFraction^-pe)/.point],{px,0,1},
 WorkingPrecision->40,AccuracyGoal->23,PrecisionGoal->23];
FTTest`FTAssert["the causal bubble phase survives the measured integration",
 NumberQ[numerical]&&Abs[numerical-N[exact/.point,35]]<10^-22&&Abs[Im[numerical]]>10^-8];
FTTest`FTAssert["raised measurement cuts are rejected by the unit-delta pushforward contract",
 FailureQ[FeynFacet`ConstructThreeParticleMeasurementPushforward[
  Join[definition,<|"CutPowers"->{1,1,1,2}|>],<|"Parameters"->{px,py}|>]]];
FTTest`FTAssert["the complete unit-range observable is a proved inclusive coordinate",
 AssociationQ[FeynFacet`VerifyThreeParticleInclusiveChart[chart,ps>0]]];
twiceDefinition=FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[geometry,<|
 "Measurements"->{<|"Variable"->pz,"Observable"->2observable|>}|>]];
twiceChart=FeynFacet`ConstructThreeParticleMeasurementPushforward[twiceDefinition,<|
 "Parameters"->{px,py},"DimensionalRegulator"->pe,"Assumptions"->assumptions|>];
FTTest`FTAssert["a valid measured square can cover only part of phase space and must not be called inclusive",
 AssociationQ[twiceChart]&&MatchQ[FeynFacet`VerifyThreeParticleInclusiveChart[twiceChart,ps>0],
  Failure["InclusiveMeasurementChartNotExhaustive",_]]];
FTTest`FTAssert["a restriction hidden in the chart domain cannot define an inclusive rate",
 FailureQ[FeynFacet`VerifyThreeParticleInclusiveChart[Join[chart,<|"Domain"->(assumptions&&pz<1/2)|>],ps>0]]];
FTTest`FTAssert["missing physical roots cannot pass the inclusive coverage proof",
 FailureQ[FeynFacet`VerifyThreeParticleInclusiveChart[Join[chart,<|"Branches"->{}|>],ps>0]]];
Print["MEASUREMENT PUSHFORWARD TEST COMPLETE"];
FTTest`FTReport[];
