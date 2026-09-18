
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
endpoint=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->vr,"TangentialVariable"->vt,"DimensionalRegulator"->ve,
 "OriginalMasterIntegralBasis"->{vi1,vi2},"NormalConnectionMatrix"->{{1,0},{0,0}},
 "TangentialConnectionMatrix"->ConstantArray[0,{2,2}]|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"A neighborhood of vr=0, 0<vt<1",
 "BranchPrescription"->"Entire scalar functions"|>];
values=<|"Status"->"PhysicalEndpointBoundaryValuesDetermined","MasterIntegralBasis"->{vi1,vi2},
 "NormalVariable"->vr,"TangentialVariable"->vt,"DimensionalRegulator"->ve,
 "NormalExponent"->0,"TangentialRegulatorExponent"->0,
 "RationalCoefficientMatrix"->{{1},{1}},"InitialConstantValues"->{1},"BoundaryConstantCount"->1|>;
(* I1=Exp[vr], I2=1: the exact physical density has a removable double pole. *)
rows=<|"density"-><|vi1->1/vr^2,vi2->-(1+vr)/vr^2|>|>;
request=<|"DensityJacobian"->1,"KinematicRules"->{},"TangentialConditions"->(0<vt<1)|>;
removable=FeynFacet`VerifyRemovableEndpointDivisor[endpoint,values,rows,request];
FTAssert["all low-order strips remove an apparent scalar double pole",
 AssociationQ[removable]&&removable["ScalarPoleOrderCleared"]===2&&
 removable["NegativeCoefficientMatrices"]===<||>];
badRows=<|"density"-><|vi1->1/vr^2,vi2->-(1+2vr)/vr^2|>|>;
FTAssert["cancellation of only the highest pole is insufficient",
 MatchQ[FeynFacet`VerifyRemovableEndpointDivisor[endpoint,values,badRows,request],
 Failure["PhysicalScalarDivisorPolesRemain",_]]];
FTAssert["a nonzero regulated power is not declared an analytic removable seam",
 FailureQ[FeynFacet`VerifyRemovableEndpointDivisor[endpoint,
 Join[values,<|"NormalExponent"->ve|>],rows,request]]];
intersection=FeynFacet`NormalizeEndpointIntersection[endpoint];
scalar=FeynFacet`AnalyzeNormalCrossingScalarCoefficients[intersection,rows,<|"NormalizationFactor"->1|>];
scaled=FeynFacet`ScaleNormalCrossingScalarCoefficients[scalar,{2,0}];
FTAssert["coordinate monomial scaling preserves units and updates exact valuations",
 !scalar["NormalizedScalarCoefficientsAnalyticAtCorner"]&&scaled["NormalizedScalarCoefficientsAnalyticAtCorner"]&&
 scaled["NonCoordinateDenominatorUnits"]===scalar["NonCoordinateDenominatorUnits"]&&
 scaled["RowIntegerLaurentLowerBounds"]==={{0,0}}];
FTReport[];
