$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
pmGeometry=FeynFacet`ConstructTwoParticleMeasurement[<|"ReferenceMomentum"->pmp,"TotalMomentum"->pmP,
 "FinalMomenta"->{pmk,pmr},"InvariantMassSquared"->pms,"ReferenceProjection"->pmrho,
 "MeasurementVariable"->pmz,"EvanescentSquare"->pmkappa,"DimensionalRegulator"->pme,
 "Assumptions"->pms>0&&pmrho>0&&0<pmz<1|>];
FTTest`FTAssert["physical massless two-particle measurement is constructed",
 AssociationQ[pmGeometry]&&pmGeometry["DensityIncludesMeasurementJacobian"]===True&&
 pmGeometry["MeasurementCut"]["Jacobian"]===2pmrho];
FTTest`FTAssert["four-dimensional differential phase space has its absolute normalization",
 (pmGeometry["PhaseSpaceDensity"]/.pme->0)===1/(8Pi)];
FTTest`FTAssert["six-dimensional volume includes the beta factor",
 Factor[Integrate[pmGeometry["PhaseSpaceDensity"]/.pme->-1,{pmz,0,1}]-pms/(192Pi^2)]===0];
FTTest`FTAssert["full and physical cut scalar products retain opposite evanescent corrections",
 (FeynCalc`FCI[FeynCalc`SPD[pmk]]/.pmGeometry["ScalarProductRules"])===0&&
 (FeynCalc`FCI[FeynCalc`SP[pmk]]/.pmGeometry["ScalarProductRules"])===-pmkappa&&
 (FeynCalc`FCI[FeynCalc`SP[pmk,pmr]]/.pmGeometry["ScalarProductRules"])===pms/2+pmkappa];
pmMoment=FeynFacet`AverageEvanescentPowers[pmkappa^3,pmkappa,-pmK,pme];
FTTest`FTAssert["every positive evanescent power begins at epsilon one",
 Factor[Coefficient[Normal[Series[pmMoment,{pme,0,1}]],pme,1]-pmK^3/3]===0];
pmAverage=FeynFacet`AverageEvanescentPowers[1+2pmkappa+pmkappa^2,pmkappa,-pmK,pme];
FTTest`FTAssert["angular averaging is linear but cannot be substituted multiplicatively",
 Factor[pmAverage-(1+2pme pmK/(1-pme)-pme pmK^2/(2-pme))]===0&&
 Factor[pmAverage-(1+2pme pmK/(1-pme)+(pme pmK/(1-pme))^2)]=!=0];
FTTest`FTAssert["an unresolved angular denominator is rejected",
 FailureQ[FeynFacet`AverageEvanescentPowers[1/(1+pmkappa),pmkappa,-pmK,pme]]];
pmMeasured=FeynFacet`EvaluateTwoParticleMeasurement[FeynCalc`SP[pmk]^2,pmGeometry];
FTTest`FTAssert["projected scalar evaluation includes the signed second angular moment",
 AssociationQ[pmMeasured]&&Factor[pmMeasured["AngularAverage"]+
 pme*(pms pmz(1-pmz))^2/(2-pme)]===0];
FTTest`FTAssert["an additional unresolved transverse reference is rejected",
 FailureQ[FeynFacet`EvaluateTwoParticleMeasurement[FeynCalc`SP[pmk,pmExtra],pmGeometry]]];
pmMomentDensity=pmGeometry["PhaseSpaceDensity"]*FeynFacet`AverageEvanescentPowers[
 pmkappa^3,pmkappa,pmGeometry["TransverseSquare"],pme];
pmSixMoment=Integrate[pmz^2(1-pmz)(pmMomentDensity/.pme->-1),{pmz,0,1}];
FTTest`FTAssert["positive-dimensional beta moments check measure and angular map together",
 Factor[pmSixMoment+pms^4 Beta[7,6]/(128Pi^2)]===0];
pmBubble=Gamma[pme]Gamma[1-pme]^2/Gamma[2-2pme]*pms^(-pme);
pmRatio=2/(4Pi)^(2-pme)*Sin[Pi pme]*pmBubble/pmGeometry["IntegratedPhaseSpace"];
FTTest`FTAssert["bubble discontinuity and two-particle volume share one loop normalization",
 Abs[N[pmRatio/.{pme->-1/5,pms->7},35]-1]<10^-30];
pmMassive=FeynFacet`ConstructTwoParticleMeasurement[<|"ReferenceMomentum"->pmp,"TotalMomentum"->pmP,
 "FinalMomenta"->{pmk,pmr},"InvariantMassSquared"->pms,"ReferenceProjection"->pms/2,
 "MassesSquared"->{0,pmM2},"MeasurementVariable"->pmz,"EvanescentSquare"->pmkappa,
 "DimensionalRegulator"->pme,"Assumptions"->pms>pmM2>0&&0<pmz<1|>];
FTTest`FTAssert["massive geometry uses the physical velocity and one measurement Jacobian",
 AssociationQ[pmMassive]&&Factor[pmMassive["VelocityFactor"]-(1-pmM2/pms)]===0&&
 Factor[pmMassive["MeasurementCut"]["Jacobian"]-(pms-pmM2)]===0];
FTTest`FTAssert["massive cut legs have their declared full-dimensional squares",
 (FeynCalc`FCI[FeynCalc`SPD[pmk]]/.pmMassive["ScalarProductRules"])===0&&
 (FeynCalc`FCI[FeynCalc`SPD[pmr]]/.pmMassive["ScalarProductRules"])===pmM2];
pmIntegrated=FeynFacet`IntegrateTwoParticleMeasurement[1,pmMassive];
FTTest`FTAssert["exact angular integration reproduces the massive total volume",
 AssociationQ[pmIntegrated]&&FullSimplify[pmIntegrated["Value"]-pmMassive["IntegratedPhaseSpace"],
 Assumptions->pms>pmM2>0]===0];
FTTest`FTAssert["physical four-dimensional massive volume has the velocity factor",
 Factor[(pmIntegrated["Value"]/.pme->0)-(1-pmM2/pms)/(8Pi)]===0];
pmEndpointIntegral=FeynFacet`IntegrateTwoParticleMeasurement[
 (1+pmz^2)/(pmz(1-pmz)),pmGeometry];
FTTest`FTAssert["endpoint-singular angular integrals agree with convergent higher-dimensional quadrature",
 AssociationQ[pmEndpointIntegral]&&Factor[(pmEndpointIntegral["Value"]/.pme->-1)-
 Integrate[(pmGeometry["PhaseSpaceDensity"]*(1+pmz^2)/(pmz(1-pmz))/.pme->-1),{pmz,0,1}]]===0];
FTTest`FTAssert["non-endpoint angular denominators require an additional integration method",
 FailureQ[FeynFacet`IntegrateTwoParticleMeasurement[1/(2-pmz),pmGeometry]]];
FTTest`FTAssert["threshold-degenerate massive angular coordinates are rejected",
 FailureQ[FeynFacet`ConstructTwoParticleMeasurement[<|"ReferenceMomentum"->pmp,"TotalMomentum"->pmP,
 "FinalMomenta"->{pmk,pmr},"InvariantMassSquared"->pmM2,"ReferenceProjection"->pmM2/2,
 "MassesSquared"->{0,pmM2},"MeasurementVariable"->pmz,"EvanescentSquare"->pmkappa,
 "DimensionalRegulator"->pme,"Assumptions"->pmM2>0&&0<pmz<1|>]]];
FTTest`FTReport[];
