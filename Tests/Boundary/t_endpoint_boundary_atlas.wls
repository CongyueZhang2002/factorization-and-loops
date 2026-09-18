Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
normal=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->rho,"TangentialVariable"->z,"DimensionalRegulator"->ee,
 "OriginalMasterIntegralBasis"->{master},
 "NormalConnectionMatrix"->{{ee/rho+1/(1+rho)}},
 "TangentialConnectionMatrix"->{{-2ee/(1-z)-1/(2-z)}}|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"rho>0,0<z<1",
  "BranchPrescription"->"Positive real coordinates"|>];
corner=FeynFacet`PrepareSingularBoundarySystem[
 <|"Variable"->sigma,"DimensionalRegulator"->ee,
 "ConnectionMatrix"->{{2ee/sigma+1/(1+sigma)}}|>];
ordered=<|"Status"->"OrderedPhysicalBoundaryValuesDetermined",
 "RecoilVariable"->rho,"MeasurementVariable"->z,"MeasurementEndpointVariable"->sigma,
 "DimensionalRegulator"->ee,"MasterIntegralBasis"->{master},"NormalEndpointSystem"->normal,
 "PhysicalRecoilExponent"->ee,"PhysicalNormalSeedMatrix"->{{1}},
 "BoundaryConstantCount"->1,"CornerPreparation"->corner,
 "PhysicalTangentialSystem"-><|"ConnectionMatrices"->{{{-2ee/(1-z)-1/(2-z)}}}|>,
 "CornerBoundaryValues"-><|"Verification"-><|"FullExactMatchingRank"->True|>,
  "FrobeniusExpansions"-><|2ee->None|>,"NormalizedSeedMatrix"->{{1}},
  "NormalizedSeedLeftInverse"->{{1}},"InitialConstantValues"->{1}|>|>;

cover=FeynFacet`ConstructNewtonEndpointCharts[{rho,sigma},{rho-sigma,rho^2+4sigma(1-rho)},
 <|"Ramification"->2|>];
atlas=FeynFacet`PrepareMonomialEndpointBoundaryAtlas[ordered,cover];
Print["ATLAS ",If[AssociationQ[atlas],atlas["Status"],atlas]];
FTAssert["the physical monomial fan transports the complete constant columns",
 AssociationQ[atlas]&&atlas["BoundaryConstantCount"]===1&&Length[atlas["Charts"]]===3&&
 AllTrue[Values[atlas["Charts"]],#["PhysicalMatching"]["InitialConstantValues"]==={1}&]];
FTAssert["both exceptional axes in an intermediate chart are retained",
 AssociationQ[atlas]&&Sort[Keys[atlas["Charts"][2]["ExceptionalBoundaryValues"]]]==={1,2}&&
 Keys[atlas["Charts"][1]["OrdinaryBoundarySystems"]]==={1}&&
 Keys[atlas["Charts"][3]["OrdinaryBoundarySystems"]]==={2}];
FTAssert["physical transport does not by itself claim an integrable scalar remainder",
 AssociationQ[atlas]&&!atlas["ProjectionConditionsEstablished"]];
FTReport[];
