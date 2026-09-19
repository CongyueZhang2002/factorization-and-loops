Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Name"->PoleBoundTest,"FinalMomenta"->{k1,k2,k3,k4},"TotalMomentum"->qq,
 "ExternalMomenta"->{qq},"KinematicRules"->{FeynCalc`SPD[qq]->ss},"Assumptions"->ss>0|>;
measurements=FeynFacet`CreateFinalStateMeasurementDefinitions[geometry,<|"Arguments"->{ka,kb},
 "Observable"->ss FeynCalc`SPD[ka,kb]/(2FeynCalc`SPD[qq,ka]FeynCalc`SPD[qq,kb]),
 "Weight"->1,"Variable"->zz,"Tuples"-><|"Ordered"->True,"IncludeRepeated"->False|>|>];
family=SelectFirst[measurements,MemberQ[#["ParticleTuples"],{1,2}]&]["Definition"];
family=FeynFacet`CreateCutIntegralFamily[Join[family,<|"Topology"->ReplacePart[family["Topology"],
 2->Join[family["Topology"][[2]],FeynCalc`FCI[FeynCalc`SFAD/@{k1+k2,k1+k3,k2+k3,qq-k1,qq-k2}]]]|>]];
master=FeynCalc`GLI[family["Topology"][[1]],Join[ConstantArray[1,5],ConstantArray[0,5]]];
coordinates=FeynFacet`MasslessPairPhaseSpaceCoordinates[{k1,k2,k3,k4},qq,ss,ee,{rr,xx,yy,aa,bb}];
request=<|"ExternalKinematicConditions"->ss>0,"DimensionalRegulator"->ee|>;
bound=FeynFacet`DeterminePolynomialMeasurementLaurentBound[family,master,coordinates,request];
If[!AssociationQ[bound],Print[InputForm[bound]];Exit[1]];
FTTest`FTAssert["the complete physical parent gives a conservative distributional pole bound",
 bound["ParentDimension"]===5&&bound["NormalizationLaurentLowerBound"]===0&&
 bound["DistributionLaurentLowerBound"]===-5&&
 !bound["ResolvedChartsConstructed"]&&!bound["ScalarRestrictionEstablished"]&&
 !bound["EndpointContactOrderEstablished"]&&!bound["PhysicalBoundaryConstantsFixed"]];
slope=bound["PhysicalMomentConstruction"]["AbsoluteMeasurementSlope"]/.coordinates["ScalarProductRules"];
conversion=(family["MeasurePrefactor"]/(2Pi)^(4-3D))/.D->4-2ee;
FTTest`FTAssert["the original scalar density retains the unit-cut absolute Jacobian exactly once",
 FullSimplify[bound["OriginalParentDensity"]slope/(conversion coordinates["Density"]),
  Assumptions->coordinates["PhysicalDomain"]&&ee<0]===1];
shifted=FeynFacet`DeterminePolynomialMeasurementLaurentBound[Join[family,<|"MasterIntegralPrefactor"->ee^-2|>],
 master,coordinates,request];
Print["SHIFTED BOUND ",InputForm[If[AssociationQ[shifted],KeyTake[shifted,{"Normalization","NormalizationLaurentLowerBound","DistributionLaurentLowerBound"}],shifted]]];
FTTest`FTAssert["external regulator poles are included in the normalization budget",
 AssociationQ[shifted]&&shifted["DistributionLaurentLowerBound"]===-7];
FTTest`FTAssert["arbitrary modified density records are not accepted as a physical chart",
 FailureQ[FeynFacet`DeterminePolynomialMeasurementLaurentBound[family,master,
  Join[coordinates,<|"Density"->coordinates["Density"]Log[rr]|>],request]]];
FTTest`FTAssert["nonaffine exponents, moving divisors and explicit singular logs violate the theorem class",
 !FeynFacet`Private`polynomialPeriodAffinePowersQ[rr^(-1+ee^2),{rr},ee,True]&&
 !FeynFacet`Private`polynomialPeriodAffinePowersQ[(rr+ee^2)^-2,{rr},ee,True]&&
 !FeynFacet`Private`polynomialPeriodAffinePowersQ[rr^(-1+ee)Log[rr],{rr},ee,True]];
FTTest`FTAssert["a measurement-dependent prefactor cannot be silently moved outside the distribution",
 FailureQ[FeynFacet`DeterminePolynomialMeasurementLaurentBound[Join[family,<|"MasterIntegralPrefactor"->1/zz|>],
  master,coordinates,request]]];
fiber=FeynFacet`DeterminePolynomialMeasurementFiberLaurentBound[family,master,coordinates,request];
If[!AssociationQ[fiber],Print[InputForm[fiber]];Exit[1]];
FTTest`FTAssert["fixed pair-angle fibers have a separately established scalar pole bound",
 fiber["LaurentLowerBound"]===-4&&fiber["FiberDimension"]===4&&
 fiber["ScalarRestrictionEstablished"]&&fiber["CommonInitialFiberConvergenceEstablished"]&&
 !fiber["EndpointContactOrderEstablished"]&&!fiber["PhysicalBoundaryConstantsFixed"]];
FTTest`FTAssert["the actual parent Gram is matched to the fiber face product",
 fiber["GramFactorization"]["PositiveExternalFactor"]===ss^3&&
 FullSimplify[fiber["ConvergenceGramInChart"]+coordinates["GramDeterminant"]/ss]===0&&
 fiber["SufficientRealEpsilonUpperBound"]===1/2-fiber["FiniteGramLossParameter"]];
shiftedFiber=FeynFacet`DeterminePolynomialMeasurementFiberLaurentBound[
 Join[family,<|"MasterIntegralPrefactor"->ee^-2|>],master,coordinates,request];
FTTest`FTAssert["fixed-fiber bounds include independent dimensional normalization poles",
 AssociationQ[shiftedFiber]&&shiftedFiber["LaurentLowerBound"]===-6];
pointDefinition=FeynFacet`Private`miRepDefinition[
 Join[family,<|"Prescription"->{0,0,0},"KinematicConditions"->ss>0|>],master,ee];
FTTest`FTAssert["ordinary-point selection uses the measured fiber instead of an affine-propagator test",
 AssociationQ[pointDefinition]&&
 FeynFacet`Private`epsOrderPhysicalPointQ[{pointDefinition},{zz},{1/3}]&&
 !FeynFacet`Private`epsOrderPhysicalPointQ[{pointDefinition},{zz},{2}]&&
 !FeynFacet`Private`epsOrderPhysicalPointQ[{pointDefinition},{zz},{0}]];
mappedPoint=Join[pointDefinition,<|"PointKinematicSubstitution"->{zz->4uu/(1+uu)^2}|>];
FTTest`FTAssert["a rational DE coordinate is mapped back before checking physical measurement support",
 FeynFacet`Private`epsOrderPhysicalPointQ[{mappedPoint},{uu},{1/2}]&&
 !FeynFacet`Private`epsOrderPhysicalPointQ[{mappedPoint},{uu},{-1/2}]&&
 !FeynFacet`Private`epsOrderPhysicalPointQ[{mappedPoint},{uu},{1}]];
Print["POLYNOMIAL MEASUREMENT POLE BOUND TEST COMPLETE"];FTTest`FTReport[];
