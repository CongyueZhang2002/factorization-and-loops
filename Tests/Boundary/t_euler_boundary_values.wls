Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
endpoint=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->er,"TangentialVariable"->et,"DimensionalRegulator"->ee,
 "NormalConnectionMatrix"->{{-4ee/er}},"TangentialConnectionMatrix"->{{2(1-2ee)/et}},
 "OriginalMasterIntegralBasis"->{1}|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"Positive endpoint coordinates",
 "BranchPrescription"->"Positive real powers"|>];
intersection=FeynFacet`NormalizeEndpointIntersection[endpoint];
matching=<|"Status"->"PhysicalJointBoundaryConstantsMatched",
 "KinematicVariables"->{er,et},"DimensionalRegulator"->ee,"MasterIntegralBasis"->{1},
 "JointResidueExponents"->{-4ee,-4ee},"OrderedConstantToCornerVectorMatrix"->{{1}},
 "InitialConstantValues"->{1},"BoundaryConstantCount"->1|>;
values=FeynFacet`ConstructEulerEndpointBoundaryValues[endpoint,intersection,matching];
FTAssert["factored regulator expressions give the exact integer Euler shift",
 AssociationQ[values]&&values["RationalCoefficientMatrix"]==={{et^2}}&&
 values["TangentialRegulatorExponent"]===-4ee];
FTReport[];
