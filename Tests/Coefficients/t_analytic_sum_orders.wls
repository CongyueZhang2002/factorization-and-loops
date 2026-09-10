$HistoryLength=0;$MaxExtraPrecision=50;
sumRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[sumRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[sumRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
sumMaster=FeynCalc`GLI["analyticSum",{1}];
sumTable=<|"DimensionalRegulator"->sumE,"PreFactor"->1,"RemainderTerms"->{},
 "Masters"->{<|"Master"->sumMaster,"Terms"->{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->Exp[sumE]+2^sumE|>}|>}|>;
sumValues=<|1-><|"MasterIntegral"->sumMaster,"DimensionalRegulator"->sumE,
 "LaurentLowerBound"->-1,"KnownThroughOrder"->0,"Coefficients"-><|-1->3,0->5|>|>|>;
sumRequest=<|"EpsilonOrderRange"->{-1,0},"Normalization"->1,"MeasureConversions"-><|sumMaster->1|>|>;
sumResult=FeynFacet`WithEpsilonRemainderChecks[FeynFacet`ContractAnalyticMasterCoefficients[sumTable,sumValues,sumRequest]];
FTTest`FTAssert["analytic sums use a sufficient Laurent bound",
 AssociationQ[sumResult["Result"]]&&(Expand /@ sumResult["Result"]["Coefficients"])===<|-1->6,0->13+3Log[2]|>];
FTTest`FTAssert["the computed lower bound is recorded",
 sumResult["Result"]["MasterContributions"][[1]]["CoefficientLaurentLowerBound"]===0];
sumShort=<|1->Join[sumValues[1],<|"KnownThroughOrder"->-1,"Coefficients"-><|-1->3|>|>]|>;
FTTest`FTAssert["an insufficient master tail still fails",FailureQ[FeynFacet`ContractAnalyticMasterCoefficients[sumTable,sumShort,sumRequest]]];

valuationDenominator=-2^(2+4orderE) Pi^(4orderE)+2^(1+4orderE) orderE Pi^(4orderE)+
 3(2Pi)^(4orderE)-orderE^2(2Pi)^(4orderE);
FTTest`FTAssert["equivalent exponential prefactors in a denominator have an exact leading order",
 FeynFacet`DetermineLaurentValuation[valuationDenominator,orderE]===0&&
 FeynFacet`DetermineMeromorphicLaurentLowerBound[1/valuationDenominator,orderE]===0];
FTTest`FTAssert["cancelling analytic denominator coefficients are counted before inversion",
 FeynFacet`DetermineMeromorphicLaurentLowerBound[1/(Exp[orderE]-1-orderE),orderE]===-2];
FTTest`FTAssert["higher cancellations in analytic sums retain their exact valuation",
 FeynFacet`DetermineLaurentValuation[Exp[orderE]-Sum[orderE^j/j!,{j,0,7}],orderE]===8];
FTTest`FTReport[];
