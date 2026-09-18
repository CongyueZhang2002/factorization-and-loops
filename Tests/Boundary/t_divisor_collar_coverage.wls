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

collars=FeynFacet`VerifyNormalCrossingDivisorCollars[intersection,matching,scalar,uniform];
FTAssert["all open divisor intervals inherit the verified Frobenius class",
 AssociationQ[collars]&&Length[collars["DivisorCollars"]]===2];
hiddenRows=<|"density"-><|1->4er et/( (et^2-1/4)^2+er^4)|>|>;
hidden=FeynFacet`AnalyzeNormalCrossingScalarCoefficients[intersection,hiddenRows,
 <|"NormalizationFactor"->er et|>];
hiddenUniform=FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[intersection,matching,hidden,{0}];
FTAssert["an interior exceptional ratio can pass the origin check",
 AssociationQ[hiddenUniform]];
FTAssert["the full divisor collar rejects a hidden concentration at ratio one half",
 MatchQ[FeynFacet`VerifyNormalCrossingDivisorCollars[intersection,matching,hidden,hiddenUniform],
 Failure["OpenDivisorUnitFactorsUnresolved",_]]];
FTReport[];
