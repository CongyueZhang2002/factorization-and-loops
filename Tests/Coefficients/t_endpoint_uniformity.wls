$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
inter=<|"Status"->"ExactLogarithmicIntersectionEstablished","OriginalMasterIntegralBasis"->{master},
 "KinematicVariables"->{r,t},"DimensionalRegulator"->ee,"Dimension"->1,"GaugeMatrix"->{{1}},
 "ConnectionMatrices"->{{{ee/r}},{{ee/t}}}|>;
matching=<|"Status"->"PhysicalJointBoundaryConstantsMatched","MasterIntegralBasis"->{master},
 "KinematicVariables"->{r,t},"BoundaryConstantCount"->1,"OrderedConstantToCornerVectorMatrix"->{{1}},
 "JointResidueExponents"->{ee,ee},"Verification"-><|"ExactPhysicalMatching"->True|>|>;
scalar=<|"MasterIntegralBasis"->{master},"CoefficientRowLabels"->{"row"},
 "ScalarGaugeCoefficientMatrix"->{{(1+r+t)/ee^2}},"NormalizedScalarCoefficientsAnalyticAtCorner"->True|>;
good=FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[inter,matching,scalar,{-1}];
FTAssert["a joint analytic scalar germ retains its finite epsilon pole envelope",
 AssociationQ[good]&&good["CoefficientLaurentLowerBounds"]==={-3}];
bad=Join[scalar,<|"ScalarGaugeCoefficientMatrix"->{{1/(r+ee)}}|>];
FTAssert["fixed-coordinate meromorphy does not imply a joint epsilon pole envelope",
 MatchQ[FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[inter,matching,bad,{0}],
  Failure["JointMeromorphicScalarPoleEnvelopeRequired",_]]];
bad=Join[scalar,<|"ScalarGaugeCoefficientMatrix"->{{r/(r+t)^3}}|>];
FTAssert["mixed coordinate divisors cannot be accepted by an analytic-row label",
 FailureQ[FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[inter,matching,bad,{0}]]];
essential=Join[inter,<|"ConnectionMatrices"->{{{ee/r+1/ee}},{{ee/t}}}|>];
FTAssert["an essential regulator singularity in the connection is rejected",
 FailureQ[FeynFacet`VerifyUniformNormalCrossingPhysicalGerm[essential,matching,scalar,{0}]]];
row=<|master->(r+t)/r|>;
divisors=FeynFacet`AnalyzeNormalCrossingScalarCoefficients[inter,<|"row"->row|>,
 <|"NormalizationFactor"->1,"KinematicRules"->{}|>];
FTAssert["scalar coordinate poles are reported separately from DE normalization",
 AssociationQ[divisors]&&!divisors["NormalizedScalarCoefficientsAnalyticAtCorner"]&&
 divisors["RowIntegerLaurentLowerBounds"]==={{-1,0}}];
vec=FeynFacet`ExpandLaurentCoefficientVector[{1/ee,1+ee+ee^2},ee,{{-1,0},{0,1}}];
selected=FeynFacet`SelectLaurentCoefficientVector[vec,{2,1}];
FTAssert["finite-vector selection preserves missing upper tails and reindexes coefficients",
 selected["KnownThroughOrders"]==={1,0}&&selected["ExactTails"]==={False,True}&&selected["Coefficients"][{1,1}]===1];
FTReport[];
