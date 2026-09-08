#!/usr/bin/env wolframscript
endpointTestRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{endpointTestRoot,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{endpointTestRoot,"FeynFacet","Solutions","Orders","LaurentBounds.wl"}]];
Get[FileNameJoin[{endpointTestRoot,"FeynFacet","Coefficients","EndpointOrders.wl"}]];
Get[FileNameJoin[{endpointTestRoot,"FeynFacet","Coefficients","Distributions.wl"}]];
Clear[endpointTestEpsilon,endpointTestZ,endpointTestV,endpointTestA,endpointTestR];
endpointTestSeries[values_List,lower_:0,exact_:True] := <|
 "LaurentLowerBound"->lower,"KnownThroughOrder"->lower+Length[values]-1,
 "Coefficients"->AssociationThread[Range[lower,lower+Length[values]-1],values],"ExactInEpsilon"->exact|>;
endpointTestTerm[power_,tay_,rem_:0,log_:0,pref_:1] := <|
 "Power"->power,"LogPower"->log,"Prefactor"->pref,
 "TaylorCoefficients"->Association@MapIndexed[(First[#2]-1)->endpointTestSeries[{#1}]&,tay],
 "Remainder"->endpointTestSeries[{rem}],"RemainderEndpointPowerLowerBound"->0|>;
endpointTestData[term_,upper_:1] := <|"DimensionalRegulator"->endpointTestEpsilon,
 "Variable"->endpointTestZ,"Interval"->{0,upper},"Assumptions"->0<endpointTestV<1,
 "EndpointConditions"-><|"NoOtherSingularities"->True,"UniformEpsilonExpansion"->True,"RepresentationValidOnInterval"->True|>,
 "Terms"->{term}|>;
endpointTestExtract[term_,through_:1,upper_:1] := ExtractEndpointDistributions[
 endpointTestData[term,upper],<|"ThroughOrder"->through|>];
endpointTestUnit=endpointTestExtract[endpointTestTerm[-1+2endpointTestEpsilon,{1}],2];
FTAssert["unit interval has full delta mass and explicit log plus coefficients",
 AssociationQ[endpointTestUnit] && Expand[endpointTestUnit["Expression"]-
   (EndpointDeltaDerivative[endpointTestZ,0,1]/(2endpointTestEpsilon)+
    EndpointPlusDistribution[endpointTestZ,-1,0,1,1]+
    2endpointTestEpsilon EndpointPlusDistribution[endpointTestZ,-1,1,1,1]+
    2endpointTestEpsilon^2 EndpointPlusDistribution[endpointTestZ,-1,2,1,1])]===0];
endpointTestVariable=endpointTestExtract[endpointTestTerm[-1+2endpointTestEpsilon,{1}],2,1-endpointTestV];
endpointTestDelta=Total[#["Expression"]& /@ endpointTestVariable["Terms"][[1,"DeltaTerms"]]];
FTAssert["variable upper bound contributes the complete delta normalization",
 Simplify[endpointTestDelta/EndpointDeltaDerivative[endpointTestZ,0,1-endpointTestV]-
   (1/(2endpointTestEpsilon)+Log[1-endpointTestV]+endpointTestEpsilon Log[1-endpointTestV]^2+
    2endpointTestEpsilon^2 Log[1-endpointTestV]^3/3)]===0];
endpointTestLogs=endpointTestExtract[endpointTestTerm[-1+2endpointTestEpsilon,{1},0,2],0,2];
FTAssert["two normal logarithms produce a third-order endpoint pole",
 Simplify[endpointTestLogs["Terms"][[1,"DeltaTerms",1,"Expression"]]/EndpointDeltaDerivative[endpointTestZ,0,2]-
   (1/(4endpointTestEpsilon^3)+Log[2]^3/3)]===0];
endpointTestPlan=DetermineEndpointDistributionOrders[
 endpointTestData[endpointTestTerm[-2+2endpointTestEpsilon,{1,1},0,2,endpointTestEpsilon^-2]],<|"ThroughOrder"->0|>];
FTAssert["Taylor coefficients need three more orders than the regular remainder",
 endpointTestPlan["TermRequirements"][[1,"RequiredTaylorUpperOrders"]]===<|0->5,1->5|> &&
 endpointTestPlan["TermRequirements"][[1,"RequiredRemainderUpperOrder"]]===2 &&
 endpointTestPlan["TermRequirements"][[1,"RequiredPrefactorUpperOrder"]]===3];
endpointTestHigher=endpointTestExtract[endpointTestTerm[-2+2endpointTestEpsilon,{3,5},7],1,2];
FTAssert["higher endpoint powers retain delta derivatives with their signs",
 Simplify[Coefficient[Expand[endpointTestHigher["Expression"]],EndpointDeltaDerivative[endpointTestZ,1,2]]+
   3(1/(2endpointTestEpsilon)+Log[2]+endpointTestEpsilon Log[2]^2)]===0 &&
 !FreeQ[endpointTestHigher["Expression"],EndpointPlusDistribution[endpointTestZ,-2,0,2,2]]];
(* Independent action on a polynomial: integrate the subtracted test function
   directly; compare against analytic continuation of elementary moments. *)
endpointTestAction[result_,test_] := Module[{z=result["Variable"],upper=Last[result["Interval"]],terms=result["Terms"],de,pl,re},
 Total[Table[
  de=Total[(-1)^#["DerivativeOrder"] (D[test,{z,#["DerivativeOrder"]}]/.z->0) # ["Expression"]/
     EndpointDeltaDerivative[z,#["DerivativeOrder"],upper]& /@ term["DeltaTerms"]];
  pl=Total[Function[item,Integrate[Expand[z^item["Power"] Log[z]^item["LogPower"]
    (test-Sum[(D[test,{z,j}]/.z->0) z^j/Factorial[j],{j,0,item["SubtractionOrder"]-1}])],{z,0,upper}]
    item["Expression"]/EndpointPlusDistribution[z,item["Power"],item["LogPower"],item["SubtractionOrder"],upper]] /@ term["PlusTerms"]];
  re=Integrate[term["RegularRemainder"]["Expression"] test,{z,0,upper}];de+pl+re,
 {term,terms}]]
];
endpointTestFunction=1+endpointTestZ+endpointTestZ^2;
endpointTestPolynomial=Expand[(3+5endpointTestZ+7endpointTestZ^2) endpointTestFunction];
endpointTestExact=Sum[Coefficient[endpointTestPolynomial,endpointTestZ,j]
  2^(j-1+2endpointTestEpsilon)/(j-1+2endpointTestEpsilon),{j,0,4}];
FTAssert["generalized plus subtraction agrees with analytically continued test-function moments",
 FullSimplify[endpointTestAction[endpointTestHigher,endpointTestFunction]-Normal[Series[endpointTestExact,{endpointTestEpsilon,0,1}]]]===0];
endpointTestFractional=endpointTestExtract[endpointTestTerm[-3/2+endpointTestEpsilon,{1}],0,4];
FTAssert["noninteger power divergence has a finite delta moment and a generalized plus term",
 Expand[endpointTestFractional["Expression"]-(-EndpointDeltaDerivative[endpointTestZ,0,4]+
   EndpointPlusDistribution[endpointTestZ,-3/2,0,1,4])]===0];
endpointTestRational=endpointTestExtract[endpointTestTerm[-1+endpointTestEpsilon,{1},-1/(1+endpointTestZ)],0];
FTAssert["supplied rational amplitude remainder remains locally integrable",
 endpointTestRational["Terms"][[1,"RegularRemainder","Expression"]]===-1/(1+endpointTestZ) &&
 FullSimplify[endpointTestAction[endpointTestRational,1+endpointTestZ]-1/endpointTestEpsilon]===0];
endpointTestIntegrable=endpointTestExtract[endpointTestTerm[-1/2,{},1],1];
FTAssert["integrable powers need no endpoint subtraction or epsilon regulator",
 endpointTestIntegrable["Expression"]===endpointTestZ^(-1/2) &&
 endpointTestIntegrable["Terms"][[1,"DeltaTerms"]]==={}];
endpointTestSymbolic=endpointTestExtract[endpointTestTerm[-1+endpointTestEpsilon,{endpointTestA[endpointTestV]},endpointTestR[endpointTestZ,endpointTestV]],0];
FTAssert["symbolic smooth amplitudes use supplied Taylor data without taking symbolic limits",
 AssociationQ[endpointTestSymbolic] && !FreeQ[endpointTestSymbolic["Expression"],endpointTestR[endpointTestZ,endpointTestV]]];
endpointTestFinitePrefactor=endpointTestTerm[-1+endpointTestEpsilon,{1},0,0,endpointTestSeries[{2,3,4},-1,False]];
endpointTestFinite=endpointTestExtract[endpointTestFinitePrefactor,0];
FTAssert["finite prefactors are convolved through their required positive orders",
 Coefficient[Expand[endpointTestFinite["Expression"]],EndpointDeltaDerivative[endpointTestZ,0,1]]===
   2/endpointTestEpsilon^2+3/endpointTestEpsilon+4];
endpointTestGamma=endpointTestExtract[endpointTestTerm[-1+endpointTestEpsilon,{1},0,0,Gamma[1+endpointTestEpsilon]],0];
FTAssert["exact Gamma prefactors retain the finite delta contribution",
 Expand[Coefficient[Expand[endpointTestGamma["Expression"]],EndpointDeltaDerivative[endpointTestZ,0,1]]-
   (1/endpointTestEpsilon-EulerGamma)]===0];
endpointTestBad=endpointTestTerm[-1+endpointTestEpsilon,{1}];
endpointTestBad["TaylorCoefficients"]=<|0->endpointTestSeries[{1},0,False]|>;
FTAssert["missing extra delta order is rejected rather than treated as zero",
 MatchQ[endpointTestExtract[endpointTestBad,0],Failure["InsufficientEndpointEpsilonOrders",_Association]]];
endpointTestBad=endpointTestFinitePrefactor;
endpointTestBad["Prefactor"]=endpointTestSeries[{2,3},-1,False];
FTAssert["insufficient finite prefactor orders are rejected",
 MatchQ[endpointTestExtract[endpointTestBad,0],Failure["InsufficientEndpointEpsilonOrders",_Association]]];
endpointTestBad=endpointTestTerm[-1+endpointTestEpsilon,{1}];
endpointTestBad["TaylorCoefficients"]=<|0-><|"LaurentLowerBound"->0,"KnownThroughOrder"->1,"Coefficients"-><|0->1|>|>|>;
FTAssert["holes in a declared finite coefficient range are rejected",
 MatchQ[endpointTestExtract[endpointTestBad,0],Failure["ExplicitFiniteEpsilonCoefficientsRequired",_Association]]];
endpointTestBad=endpointTestData[endpointTestTerm[-1+endpointTestEpsilon,{1}]];
endpointTestBad["EndpointConditions"]=<||>;
FTAssert["missing endpoint and uniform-remainder assumptions are rejected",
 MatchQ[ExtractEndpointDistributions[endpointTestBad,<|"ThroughOrder"->0|>],Failure["EndpointConditionsRequired",_Association]]];
endpointTestBad=endpointTestData[endpointTestTerm[-1+endpointTestEpsilon,{1}]];
endpointTestBad["NormalVariables"]={endpointTestZ,endpointTestV};
FTAssert["intersecting endpoint input is explicitly unsupported",
 MatchQ[ExtractEndpointDistributions[endpointTestBad,<|"ThroughOrder"->0|>],Failure["UnresolvedMultipleEndpoints",_Association]]];
FTAssert["an unregulated nonintegrable power is rejected",
 MatchQ[endpointTestExtract[endpointTestTerm[-1,{1}],0],Failure["EndpointNotRegulated",_Association]]];
endpointTestBad=endpointTestTerm[-1+endpointTestEpsilon,{1}];endpointTestBad["RemainderEndpointPowerLowerBound"]=-1;
FTAssert["nonintegrable declared remainder is rejected",
 MatchQ[endpointTestExtract[endpointTestBad,0],Failure["LocallyIntegrableRemainderBoundRequired",_Association]]];
endpointTestBad=endpointTestData[endpointTestTerm[-1+endpointTestEpsilon,{1}],endpointTestV];
endpointTestBad["Assumptions"]=True;
FTAssert["unproved positive integration interval is rejected",
 MatchQ[ExtractEndpointDistributions[endpointTestBad,<|"ThroughOrder"->0|>],Failure["FinitePositiveEndpointIntervalRequired",_Association]]];
FTAssert["finite output contains no coefficient generators or unresolved series",
 FreeQ[endpointTestHigher,_SeriesCoefficient|_SeriesData|_Series|_Missing|_Failure] &&
 endpointTestHigher["PhysicalNNLOCoverageInferred"]===False];
endpointTestHalfOpen=endpointTestData[endpointTestTerm[-1+endpointTestEpsilon,{1},1/(2-endpointTestZ)],2];
endpointTestHalfOpen["TestFunctionDomain"]="ThresholdCompactSupport";
endpointTestHalfOpen["EndpointConditions"]=<|"NoInteriorSingularities"->True,
 "UniformEpsilonExpansionOnCompactSubsets"->True,"RepresentationValidOnHalfOpenInterval"->True|>;
endpointTestHalfOpenResult=ExtractEndpointDistributions[endpointTestHalfOpen,<|"ThroughOrder"->0|>];
FTAssert["an upper-endpoint-singular remainder is admitted on the explicit half-open test domain",
 AssociationQ[endpointTestHalfOpenResult] &&
 endpointTestHalfOpenResult["DomainConvention"]["UpperEndpointExcluded"]===True &&
 endpointTestHalfOpenResult["Terms"][[1,"RegularRemainder","Expression"]]===1/(2-endpointTestZ)];
FTAssert["the half-open domain retains the full conventional plus subtraction and contact moment",
 Expand[endpointTestHalfOpenResult["Expression"]-
 ((1/endpointTestEpsilon+Log[2])EndpointDeltaDerivative[endpointTestZ,0,2]+
 EndpointPlusDistribution[endpointTestZ,-1,0,1,2]+1/(2-endpointTestZ))]===0];
FTAssert["half-open remainder assumptions do not silently authorize the closed-interval domain",
 MatchQ[ExtractEndpointDistributions[KeyDrop[endpointTestHalfOpen,"TestFunctionDomain"],<|"ThroughOrder"->0|>],
 Failure["EndpointConditionsRequired",_Association]]];
FTAssert["the preexisting full-interval mode remains explicit and stricter",
 endpointTestUnit["DomainConvention"]["IntervalClosure"]==="Closed" &&
 endpointTestUnit["DomainConvention"]["UpperEndpointExcluded"]===False];FTReport[];