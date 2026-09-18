Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
normal=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->rho,"TangentialVariable"->z,"DimensionalRegulator"->ee,
 "OriginalMasterIntegralBasis"->{master},
 "NormalConnectionMatrix"->{{ee/rho+1/(1+rho)+1/(rho+1-z)}},
 "TangentialConnectionMatrix"->{{-2ee/(1-z)-1/(2-z)-1/(rho+1-z)}}|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"rho>0,0<z<1",
 "BranchPrescription"->"Positive real coordinates"|>];
corner=FeynFacet`PrepareSingularBoundarySystem[
 <|"Variable"->sigma,"DimensionalRegulator"->ee,
 "ConnectionMatrix"->{{(1+2ee)/sigma+1/(1+sigma)}}|>];
ordered=<|"Status"->"OrderedPhysicalBoundaryValuesDetermined",
 "RecoilVariable"->rho,"MeasurementVariable"->z,"MeasurementEndpointVariable"->sigma,
 "DimensionalRegulator"->ee,"MasterIntegralBasis"->{master},"NormalEndpointSystem"->normal,
 "PhysicalRecoilExponent"->ee,"PhysicalNormalSeedMatrix"->{{1}},
 "BoundaryConstantCount"->1,"CornerPreparation"->corner,
 "PhysicalTangentialSystem"-><|"ConnectionMatrices"->{{{-(1+2ee)/(1-z)-1/(2-z)}}}|>,
 "CornerBoundaryValues"-><|"Verification"-><|"FullExactMatchingRank"->True|>,
  "FrobeniusExpansions"-><|2ee->None|>,"NormalizedSeedMatrix"->{{1}},
  "NormalizedSeedLeftInverse"->{{1}},"InitialConstantValues"->{1}|>|>;
rows=<|"density"-><|master->1/(rho(1-z)(rho+1-z))|>|>;
request=<|"KinematicRules"->{z->1-sigma},"Assumptions"->True,
 "TestFunctionSupport"-><|"ExcludedFaces"->{rho->1,sigma->1}|>|>;
result=FeynFacet`PrepareResolvedEndpointProfiles[ordered,rows,request];
If[FailureQ[result],Print[result]];
FTTest`FTAssert["an apparent non-normal-crossing basis gives the exact product corner",
 AssociationQ[result]&&result["Powers"]==={-1+ee,-1+2ee}&&
 result["CornerCoefficientMatrix"]==={{1}}&&result["InitialConstantValues"]==={1}];
FTTest`FTAssert["both ordinary faces and every internal interface are established",
 AssociationQ[result]&&Sort[Keys[result["CoefficientJets"]]]==={1,2}&&
 Length[result["ProjectionConditions"]["Justification"]["ChartInterfaces"]]===1&&
 result["ProjectionConditions"]["JointlyIntegrableSubtractedStrata"]];
FTTest`FTAssert["the resolved proof retains complete support and ordinary corner matching",
 AssociationQ[result]&&result["ProjectionConditions"]["TestFunctionSupport"]===request["TestFunctionSupport"]&&
 result["ProjectionConditions"]["Justification"]["OrdinaryFaceCornerValuesVerified"]];
FTTest`FTReport[];
