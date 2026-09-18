Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Name"->MomentTest,"FinalMomenta"->{k1,k2,k3,k4},"TotalMomentum"->qq,
 "ExternalMomenta"->{qq},"KinematicRules"->{FeynCalc`SPD[qq]->ss},"Assumptions"->ss>0|>;
observable=ss FeynCalc`SPD[ka,kb]/(2FeynCalc`SPD[qq,ka]FeynCalc`SPD[qq,kb]);
make[obs_]:=Module[{records,pure,top},
 records=FeynFacet`CreateFinalStateMeasurementDefinitions[geometry,<|"Arguments"->{ka,kb},
  "Observable"->obs,"Weight"->1,"Variable"->zz,
  "Tuples"-><|"Ordered"->True,"IncludeRepeated"->False|>|>];
 pure=SelectFirst[records,MemberQ[#["ParticleTuples"],{1,2}]&]["Definition"];top=pure["Topology"];
 FeynFacet`CreateCutIntegralFamily[Join[pure,<|"Topology"->ReplacePart[top,2->Join[top[[2]],
  FeynCalc`FCI[FeynCalc`SFAD/@{k1+k2,k1+k3,k2+k3,qq-k1,qq-k2}]]]|>]]];
family=make[observable];If[!AssociationQ[family],Print[InputForm[family]];Exit[1]];
master=FeynCalc`GLI[family["Topology"][[1]],Join[ConstantArray[1,5],ConstantArray[0,5]]];
coordinates=FeynFacet`MasslessPairPhaseSpaceCoordinates[{k1,k2,k3,k4},qq,ss,ee,{rr,xx,yy,aa,bb}];
request=<|"ExternalKinematicConditions"->ss>0,"DimensionalRegulator"->ee|>;
moment=FeynFacet`ConstructPolynomialMeasurementMoment[family,master,coordinates,{0,0},0,request];
If[!AssociationQ[moment],Print[InputForm[moment]];Exit[1]];
FTTest`FTAssert["zeroth Jacobian-corrected moment is the original unmeasured volume",
 moment["UnmeasuredNumeratorInsertion"]===1&&
 moment["UnmeasuredIntegrals"]===FeynCalc`GLI[moment["UnmeasuredFamily"]["Topology"][[1]],
  Join[ConstantArray[1,4],ConstantArray[0,5]]]];
f=moment["MeasurementSlope"];g=moment["MeasurementNumerator"];
FTTest`FTAssert["the polynomial cut Jacobian is compensated once",
 FullSimplify[(f/.coordinates["ScalarProductRules"])/
  (Coefficient[moment["MeasurementPolynomial"],zz]/.coordinates["ScalarProductRules"]),
 coordinates["PhysicalDomain"]]===1&&
 FeynFacet`MultiplyCutIntegral[family,master,f]===moment["MeasuredIntegrals"]];
first=FeynFacet`ConstructPolynomialMeasurementMoment[family,master,coordinates,{1,1},2,request];
FTTest`FTAssert["higher moments have the correct complete polynomial numerator",
 AssociationQ[first]&&Expand[first["UnmeasuredNumeratorInsertion"]-g(f-g)]===0&&
 first["MeasuredIntegrals"]===FeynFacet`MultiplyCutIntegral[family,master,Expand[f^3]]];
FTTest`FTAssert["the same particle measure and the shared convergence proof are retained",
 moment["UnmeasuredFamily"]["MeasurePrefactor"]===family["MeasurePrefactor"]&&
 TrueQ[moment["OriginalConvergenceCertificate"]["EventualHighDimensionHolomorphy"]]&&
 TrueQ[moment["CommonConvergenceDomainExists"]]&&!moment["MomentEvaluated"]&&
 !moment["PhysicalBoundaryConstantsFixed"]&&!moment["EndpointCoefficientsComputed"]];
FTTest`FTAssert["insufficient insertion degree is rejected before negative powers are hidden",
 FailureQ[FeynFacet`ConstructPolynomialMeasurementMoment[family,master,coordinates,{1,1},1,request]]];
FTTest`FTAssert["dotted cuts cannot use the unit-cut moment identity",
 FailureQ[FeynFacet`ConstructPolynomialMeasurementMoment[family,
 ReplacePart[master,{2,5}->2],coordinates,{0,0},0,request]]];
FTTest`FTAssert["measurement-dependent normalization cannot be pulled outside the moment",
 FailureQ[FeynFacet`ConstructPolynomialMeasurementMoment[Join[family,<|
  "MeasurePrefactor"->zz family["MeasurePrefactor"]|>],master,coordinates,{0,0},0,request]]];
FTTest`FTAssert["a scaled observable outside the interval is rejected",
 FailureQ[FeynFacet`ConstructPolynomialMeasurementMoment[make[2observable],master,coordinates,{0,0},0,request]]];
Print["POLYNOMIAL MEASUREMENT MOMENTS TEST COMPLETE"];FTTest`FTReport[];
