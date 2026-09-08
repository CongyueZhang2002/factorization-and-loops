#!/usr/bin/env wolframscript
densityReferenceTestRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[densityReferenceTestRoot<>"/Tests/TestKit.wl"];
Get[densityReferenceTestRoot<>"/FeynFacet/Coefficients/DensityValidation.wl"];
Clear[drX,drY,drE];
drD=<|"DataType"->"FiniteMasterIntegralDensity","PhysicalBoundaryCoefficientsResolved"->True,
 "KinematicVariables"->{drX,drY},"DimensionalRegulator"->drE,
 "AlgebraicDefinitions"->{3,-6,2,1},"Coefficients"-><|-5->3FeynFacetSolution`a[3]-6FeynFacetSolution`a[4]|>,
 "ScalarRemainderCoefficients"-><||>,
 "MasterCoefficientIndex"->{<|"Column"->1,"Master"->{"A",{1}},"Row"->1,"EpsilonOrder"->0,"Expression"->FeynFacetSolution`a[3]|>,
  <|"Column"->2,"Master"->{"B",{1}},"Row"->1,"EpsilonOrder"->0,"Expression"->FeynFacetSolution`a[4]|>},
 "CoefficientFunctionIndex"->{<|"Master"->{"A",{1}},"EpsilonOrder"->-5,"Expression"->FeynFacetSolution`a[1]|>,
  <|"Master"->{"B",{1}},"EpsilonOrder"->-5,"Expression"->FeynFacetSolution`a[2]|>}|>;
drBundle[family_,value_] := <|
 "AMFlow"-><|"Status"->"AMFlowMastersEvaluated","AMFlowOrderConvention"->"OffsetFromMinusTwoLoops",
  "Point"->{1/4,1/5},"KinematicVariables"->{drX,drY},"PrecisionGoal"->25,
  "IntegralDefinition"-><|"Family"->family|>,"MasterIntegralPrefactors"->{1},
  "RowIndices"->{1},"OriginalMasterIntegralBasis"->{FeynCalc`GLI[family,{1}]},
  "MasterIntegralEpsilonCoefficients"-><|0->{1->value}|>|>,
 "PhysicalEvaluation"-><|"Point"->{1/4,1/5},"PhysicalBoundaryValuesDetermined"->True,
  "PrecisionGoal"->18,"MasterIntegralEpsilonCoefficients"-><|0->{1->value}|>|>,
 "ValidationRequest"-><|"Point"->{1/4,1/5},"KinematicVariables"->{drX,drY}|>,
 "AMFlowRequest"-><|"Point"->{1/4,1/5},"IntegralDefinition"-><|"Family"->family|>,"MasterIntegralPrefactors"->{1}|>,
 "Comparison"-><|"Status"->"Passed","ReferenceNormalizationAndCutsMatched"->True,"SelectedRows"->{1}|>|>;
drRefs=<|"A"->drBundle["A",2],"B"->drBundle["B",1]|>;
drRequest=<|"Point"->{1/4,1/5},"Orders"->{-5},"ExpectedZeroOrders"->{-5},"RelativeTolerance"->10^-12|>;
drResult=FeynFacet`CheckFiniteDensityWithRetainedReferences[drD,drRefs,drRequest];
FTAssert["retained references independently cancel the weighted high pole",
 AssociationQ[drResult]&&drResult["Status"]==="Passed"&&TrueQ[drResult["Reports"][[1,"AMFlowSum"]]==0]&&
 drResult["Reports"][[1,"AMFlowAbsoluteContributionSum"]]==12&&
 drResult["SelectedCoefficientDefinitionIndices"]==={1,2}];
FTAssert["the check preserves nonzero symbolic coefficients and does not evaluate masters",
 drResult["SymbolicCoefficientsChanged"]===False&&drResult["NewMasterEvaluationsPerformed"]===False&&
 drResult["Reports"][[1,"SymbolicCoefficientExactlyZero"]]===False];
drBad=drRefs;drBad["A"]=Join[drBad["A"],<|"PhysicalEvaluation"->Join[drBad["A"]["PhysicalEvaluation"],<|"Point"->{1/3,1/5}|>]|>];
FTAssert["a mismatched retained point is rejected",
 MatchQ[FeynFacet`CheckFiniteDensityWithRetainedReferences[drD,drBad,drRequest],Failure["ReferencePointNormalizationOrValidationMismatch",_]]];
drBad=drRefs;drBad["A"]=Join[drBad["A"],<|"PhysicalEvaluation"->Join[drBad["A"]["PhysicalEvaluation"],<|"MasterIntegralEpsilonCoefficients"-><||>|>]|>];
FTAssert["missing retained epsilon coefficients cannot be replaced by zero",
 MatchQ[FeynFacet`CheckFiniteDensityWithRetainedReferences[drD,drBad,drRequest],Failure["RetainedMasterCoefficientMissing",_]]];
drBad=drRefs;drBad["B"]=drBundle["B",2];
FTAssert["a noncancelling high pole is reported without changing the result",
 FeynFacet`CheckFiniteDensityWithRetainedReferences[drD,drBad,drRequest]["Status"]==="Failed"];

drShared=Join[drD,<|"AlgebraicDefinitions"->{1,2 FeynFacetSolution`a[1],FeynFacetSolution`a[1]+FeynFacetSolution`a[2],
 -2 drColor FeynFacetSolution`a[3]},
 "CoefficientFunctionIndex"->{<|"Master"->{"A",{1}},"EpsilonOrder"->-5,"Expression"->FeynFacetSolution`a[3]|>,
 <|"Master"->{"B",{1}},"EpsilonOrder"->-5,"Expression"->FeynFacetSolution`a[4]|>}|>];
drSharedRequest=Join[drRequest,<|"ParameterValuesByName"-><|"drColor"->1|>|>];
FTAssert["shared color coefficient functions are evaluated recursively with explicit parameter values",
 FeynFacet`CheckFiniteDensityWithRetainedReferences[drShared,drRefs,drSharedRequest]["Status"]==="Passed"];
drCycle=Join[drShared,<|"AlgebraicDefinitions"->{1,FeynFacetSolution`a[3],FeynFacetSolution`a[2],-6}|>];
FTAssert["a forward coefficient dependency is rejected before numeric evaluation",
 MatchQ[FeynFacet`CheckFiniteDensityWithRetainedReferences[drCycle,drRefs,drSharedRequest],
 Failure["CoefficientDefinitionDependencyInvalid",_]]];
FTReport[];
