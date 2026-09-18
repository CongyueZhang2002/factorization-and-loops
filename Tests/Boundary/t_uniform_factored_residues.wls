Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
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

matching=Join[matching,<|"JointResidueExponents"->{2(1-2ee)-2,-4ee},
 "Verification"-><|"SyntheticExactScalarSeed"->True|>|>];
scalar=FeynFacet`AnalyzeNormalCrossingScalarCoefficients[intersection,<|"density"-><|1->1/(er et^3)|>|>,
 <|"NormalizationFactor"->er et|>];
uniform=FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[intersection,matching,scalar,{0}];
FTAssert["factored but equal residue exponents pass the exact uniform-germ check",
 AssociationQ[uniform]];
bad=Join[matching,<|"JointResidueExponents"->{-3ee,-4ee}|>];
FTAssert["a truly different physical exponent remains rejected",
 FailureQ[FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[intersection,bad,scalar,{0}]]];
FTReport[];
