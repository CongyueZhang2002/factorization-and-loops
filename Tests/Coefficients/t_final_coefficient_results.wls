#!/usr/bin/env wolframscript
coefficientResultTestRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{coefficientResultTestRoot,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{coefficientResultTestRoot,"FeynFacet","Algebra","RegulatorSeries.wl"}]];
Get[FileNameJoin[{coefficientResultTestRoot,"FeynFacet","Solutions","Orders","LaurentBounds.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{Global`coefficientResultTestRoot,"FeynFacet","Coefficients","FinalResults.wl"}]];
End[];
Clear[coefficientResultTestEpsilon,coefficientResultTestRho];
coefficientResultTestExact[x_,pref_:1] := <|"PreFactor"->pref,"Representation"->"Exact","Coefficient"->x|>;
coefficientResultTestFinite[values_List,lower_,pref_:1,variable_:coefficientResultTestEpsilon] := <|
 "PreFactor"->pref,"Representation"->"LaurentSeries",
 "Coefficient"-><|"SeriesVariable"->variable,
   "Orders"->AssociationThread[Range[lower,lower+Length[values]-1],values],
   "SeriesTruncation"->lower+Length[values]-1|>|>;
coefficientResultTestEntry[terms_,index_:1] := <|"Master"->FeynCalc`GLI["testCoefficientFamily",{index}],"Terms"->terms|>;
coefficientResultTestTable[entries_,variable_:coefficientResultTestEpsilon] := <|
 "Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
 "DimensionalRegulator"->variable,"Masters"->entries,"RemainderTerms"->{},
 "PreFactor"->17/variable,"FractionMeasure"->1,"PhaseSpace"->1,
 "Definitions"-><|"Setup"-><|"UnusedSentinel"->None|>|>,"CompleteTargetSet"->True|>;
coefficientResultTestExpand[entry_,range_] := FeynFacet`ExpandMasterIntegralCoefficient[entry,coefficientResultTestEpsilon,range];
coefficientResultTestTerm=coefficientResultTestFinite[{2,3,5},0,
 (1+7coefficientResultTestEpsilon+11coefficientResultTestEpsilon^2)/coefficientResultTestEpsilon^2];
coefficientResultTestExpansion=coefficientResultTestExpand[coefficientResultTestEntry[{coefficientResultTestTerm}],{-2,0}];
FTAssert["finite coefficient demands include analytic-prefactor poles",
 AssociationQ[coefficientResultTestExpansion] && coefficientResultTestExpansion["Coefficients"]===<|-2->2,-1->17,0->48|>];
FTAssert["a finite coefficient tail cannot be extended through a prefactor pole",
 MatchQ[coefficientResultTestExpand[coefficientResultTestEntry[{coefficientResultTestTerm}],{-2,1}],
   Failure["CoefficientEpsilonOrdersInsufficient",_Association]]];
coefficientResultTestExpansion=coefficientResultTestExpand[coefficientResultTestEntry[{
 coefficientResultTestFinite[{2},0,coefficientResultTestEpsilon^2]}],{0,2}];
FTAssert["positive prefactor valuation permits shallower stored coefficients",
 coefficientResultTestExpansion["Coefficients"]===<|0->0,1->0,2->2|>];
FTAssert["fractional epsilon powers cannot be silently projected to zero",
 FailureQ[coefficientResultTestExpand[coefficientResultTestEntry[{coefficientResultTestExact[Sqrt[coefficientResultTestEpsilon]]}],{0,1}]]];
FTAssert["log epsilon is not accepted as an epsilon-independent Laurent coefficient",
 FailureQ[coefficientResultTestExpand[coefficientResultTestEntry[{coefficientResultTestExact[Log[coefficientResultTestEpsilon]]}],{0,1}]]];
coefficientResultTestRead=FeynFacet`ReadMasterIntegralCoefficients[
 coefficientResultTestTable[{
  coefficientResultTestEntry[{coefficientResultTestExact[0]},1],
  coefficientResultTestEntry[{coefficientResultTestFinite[{0,0,0},-2]},2],
  coefficientResultTestEntry[{coefficientResultTestExact[3]},3]}],
 "DimensionalRegulator"->coefficientResultTestEpsilon];
FTAssert["exact zero masters are distinguished from an all-zero known finite prefix",
 Lookup[coefficientResultTestRead["Masters"],"Master"]===
   {FeynCalc`GLI["testCoefficientFamily",{2}],FeynCalc`GLI["testCoefficientFamily",{3}]} &&
 coefficientResultTestRead["ExactZeroMasterIntegrals"]==={FeynCalc`GLI["testCoefficientFamily",{1}]}];
coefficientResultTestPrefix=coefficientResultTestRead["Masters"][[1]];
FTAssert["a known zero prefix returns explicit zero coefficients within its range",
 coefficientResultTestExpand[coefficientResultTestPrefix,{-2,0}]["Coefficients"]===<|-2->0,-1->0,0->0|>];
FTAssert["a known zero prefix retains its unknown higher-order tail",
 MatchQ[coefficientResultTestExpand[coefficientResultTestPrefix,{-2,1}],
   Failure["CoefficientEpsilonOrdersInsufficient",_Association]]];
FTAssert["the table's global prefactor remains separate from master coefficients",
 coefficientResultTestRead["PreFactor"]===17/coefficientResultTestEpsilon &&
 coefficientResultTestExpand[coefficientResultTestRead["Masters"][[2]],{0,0}]["Coefficients"]===<|0->3|> &&
 coefficientResultTestExpand[coefficientResultTestRead["Masters"][[2]],{0,0}]["GlobalPrefactorIncluded"]===False];
coefficientResultTestCustom=coefficientResultTestTable[{
 coefficientResultTestEntry[{coefficientResultTestFinite[{2,3},0,1/coefficientResultTestRho,coefficientResultTestRho]},1],
 coefficientResultTestEntry[{coefficientResultTestExact[1/coefficientResultTestRho]},2]},coefficientResultTestRho];
coefficientResultTestCustom["PreFactor"]=Gamma[1+coefficientResultTestRho];
coefficientResultTestCustomRead=FeynFacet`ReadMasterIntegralCoefficients[coefficientResultTestCustom,
 "DimensionalRegulator"->coefficientResultTestEpsilon];
FTAssert["declared custom source regulator is normalized in finite, exact and global factors",
 AssociationQ[coefficientResultTestCustomRead] && FreeQ[coefficientResultTestCustomRead,coefficientResultTestRho] &&
 coefficientResultTestCustomRead["PreFactor"]===Gamma[1+coefficientResultTestEpsilon] &&
 coefficientResultTestExpand[coefficientResultTestCustomRead["Masters"][[1]],{-1,0}]["Coefficients"]===<|-1->2,0->3|> &&
 coefficientResultTestExpand[coefficientResultTestCustomRead["Masters"][[2]],{-1,0}]["Coefficients"]===<|-1->1,0->0|>];
coefficientResultTestInferred=KeyDrop[coefficientResultTestCustom,"DimensionalRegulator"];
coefficientResultTestInferred["Definitions"]=<|"Setup"-><||>,"DimensionRule"->(D->4-2coefficientResultTestRho)|>;
coefficientResultTestInferredRead=FeynFacet`ReadMasterIntegralCoefficients[coefficientResultTestInferred,
 "DimensionalRegulator"->coefficientResultTestEpsilon];
FTAssert["canonical DimensionRule supplies a custom source regulator when needed",
 AssociationQ[coefficientResultTestInferredRead] && FreeQ[coefficientResultTestInferredRead,coefficientResultTestRho] &&
 coefficientResultTestExpand[coefficientResultTestInferredRead["Masters"][[1]],{-1,0}]["Coefficients"]===<|-1->2,0->3|>];
coefficientResultTestVersion8=<|"Format"->"FeynFacet-IBP","FormatVersion"->8,
 "Setup"-><|"UnusedSentinel"->None|>,"PreFactor"->1,"FractionMeasure"->1,"PhaseSpace"->1,
 "Masters"->{<|"Master"->FeynCalc`GLI["testCoefficientFamily",{1}],"PreFactor"->1,"Coefficient"->2|>},"Remainder"->0|>;
coefficientResultTestVersion8Read=FeynFacet`ReadMasterIntegralCoefficients[coefficientResultTestVersion8,
 "DimensionalRegulator"->coefficientResultTestEpsilon];
FTAssert["retired coefficient format is rejected",FailureQ[coefficientResultTestVersion8Read]];
coefficientResultTestVersion8Read=FeynFacet`ReadMasterIntegralCoefficients[
 coefficientResultTestTable[{coefficientResultTestEntry[{coefficientResultTestExact[2]}]}],
 "DimensionalRegulator"->coefficientResultTestEpsilon];
FTAssert["None sentinels remain data",coefficientResultTestVersion8Read["Definitions"]["Setup"]["UnusedSentinel"]===None];
coefficientResultTestDirect=coefficientResultTestEntry[{
 coefficientResultTestFinite[{2,3},0,1/coefficientResultTestRho,coefficientResultTestRho]}];
FTAssert["direct finite expansion honors its own SeriesVariable",
 coefficientResultTestExpand[coefficientResultTestDirect,{-1,0}]["Coefficients"]===<|-1->2,0->3|>];
coefficientResultTestDirect=Join[coefficientResultTestEntry[{coefficientResultTestExact[1/coefficientResultTestRho]}],
 <|"DimensionalRegulator"->coefficientResultTestRho|>];
FTAssert["direct exact expansion honors entry regulator metadata",
 coefficientResultTestExpand[coefficientResultTestDirect,{-1,0}]["Coefficients"]===<|-1->1,0->0|>];
coefficientResultTestDim=4-2coefficientResultTestEpsilon;
coefficientResultTestDoubleReal=FeynFacet`MasterIntegralMeasureConversion[<|
 "Dimension"->coefficientResultTestDim,"PhaseSpaceLoopCount"->2,"Prescription"->{0,0},
 "MeasurePrefactor"->(2Pi)^(3-2coefficientResultTestDim),
 "MasterIntegralPrefactor"->3/(1+coefficientResultTestEpsilon)|>];
FTAssert["three-particle double-real conversion includes all phase-space factors and extra normalization",
 FullSimplify[coefficientResultTestDoubleReal["Factor"]+
  2^(2coefficientResultTestDim-3) Pi^(coefficientResultTestDim-3) (1+coefficientResultTestEpsilon)/3,
  Assumptions->Element[coefficientResultTestEpsilon,Reals]]===0];
coefficientResultTestForward=FeynFacet`MasterIntegralMeasureConversion[<|
 "Dimension"->coefficientResultTestDim,"PhaseSpaceLoopCount"->0,"Prescription"->{1},
 "MeasurePrefactor"->1/(I Pi^(coefficientResultTestDim/2))|>];
coefficientResultTestConjugate=FeynFacet`MasterIntegralMeasureConversion[<|
 "Dimension"->coefficientResultTestDim,"PhaseSpaceLoopCount"->0,"Prescription"->{-1},
 "MeasurePrefactor"->-1/(I Pi^(coefficientResultTestDim/2))|>];
FTAssert["forward virtual measure agrees and conjugate virtual measure has the required sign",
 Simplify[coefficientResultTestForward["Factor"]-1]===0 &&
 Simplify[coefficientResultTestConjugate["Factor"]+1]===0 &&
 coefficientResultTestConjugate["NegativePrescriptionLoopCount"]===1];
coefficientResultTestMixed=FeynFacet`MasterIntegralMeasureConversion[<|
 "Dimension"->coefficientResultTestDim,"PhaseSpaceLoopCount"->0,"Prescription"->{1,-1},
 "MeasurePrefactor"->-(I Pi^(coefficientResultTestDim/2))^-2,"MasterIntegralPrefactor"->5|>];
FTAssert["mixed virtual prescriptions preserve the conjugate sign and master prefactor",
 Simplify[coefficientResultTestMixed["Factor"]+1/5]===0];
FTAssert["inconsistent phase-space loop count is rejected",
 FailureQ[FeynFacet`MasterIntegralMeasureConversion[<|"Dimension"->coefficientResultTestDim,
  "PhaseSpaceLoopCount"->1,"Prescription"->{0,0},"MeasurePrefactor"->1|>]]];
coefficientResultTestExpansion=coefficientResultTestExpand[coefficientResultTestEntry[{
 coefficientResultTestExact[coefficientResultTestEpsilon^-2+3+7coefficientResultTestEpsilon]}],{0,0}];
FTAssert["a narrow request above a leading pole returns its coefficient",
 coefficientResultTestExpansion["Coefficients"]===<|0->3|>];
coefficientResultTestExpansion=coefficientResultTestExpand[coefficientResultTestEntry[{
 coefficientResultTestExact[(2^coefficientResultTestEpsilon+Pi^coefficientResultTestEpsilon)/
    coefficientResultTestEpsilon]}],{-1,0}];
FTAssert["additive analytic prefactors have explicit finite coefficients",
 coefficientResultTestExpansion["Coefficients"]===<|-1->2,0->Log[2]+Log[Pi]|>];
coefficientResultTestMetadata=Join[coefficientResultTestVersion8Read,<|
 "PhysicalMasterNormalizationApplied"->True,"CoefficientConvention"->"PhysicalMasterAtReferenceScale"|>];
coefficientResultTestMetadata=FeynFacet`ReadMasterIntegralCoefficients[coefficientResultTestMetadata,
 "DimensionalRegulator"->coefficientResultTestEpsilon];
FTAssert["rereading a physical table preserves its normalization declaration",
 TrueQ[coefficientResultTestMetadata["PhysicalMasterNormalizationApplied"]]&&
 coefficientResultTestMetadata["CoefficientConvention"]==="PhysicalMasterAtReferenceScale"];
FTReport[];
