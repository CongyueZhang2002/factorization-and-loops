#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Algebra/RationalFunctions.wl"];
Clear[x,y,z,e];
raw={((x+e)^4-x^4)/(e*(x+e)),((x-y)*(x+y))/(x^2-y^2),1/(x+e)-1/(x-e),
 (2/3+x/7)*(3/2-2*x/5),10^40*(x+1)/((x+1)*7)};
result=FeynFacet`CancelRationalExpressions[raw,{x,y,e}];
FTAssert["FLINT agrees exactly with independent Wolfram rational cancellation",
 ListQ[result]&&And@@Thread[(Cancel[Together[#]]&/@(raw-result))==0]];
FTAssert["a removable pole is eliminated exactly",ListQ[result]&&result[[2]]===1];
FTAssert["undeclared coefficient-field variables are rejected",
 FailureQ[FeynFacet`CancelRationalExpressions[{1/(x+z)},{x}]]];
FTAssert["nonrational functions are rejected unless represented by declared independent symbols",
 FailureQ[FeynFacet`CancelRationalExpressions[{Sin[x]},{x}]]];
x0=123;FeynFacet`Private`x1=321;
FTAssert["generated backend variable names cannot capture caller values",
 FeynFacet`CancelRationalExpressions[{x+y},{x,y}]==={x+y}];
Get[root<>"/FeynFacet/Coefficients/PoleCancellation.wl"];
a=FeynFacet`SimplifyMasterCoefficientEntries[{<|"Terms"->{<|"Representation"->"Exact","PreFactor"->1,
 "Coefficient"->(2^(3(3-2e)+6e)-512)/(x+e)|>}|>}];
FTAssert["equivalent analytic prefactors are combined before independent field symbols are introduced",
 AssociationQ[a]&&a["CoefficientEntries"][[1,"Terms",1,"Coefficient"]]===0];
b=FeynFacet`Private`coefficientRationalFieldReduce[2^(3-4e)+16*2^(-4e-1)];
FTAssert["integer exponent decomposition retains the exact analytic expression",
 FullSimplify[(First[b]/.Last[b])-(2^(3-4e)+16*2^(-4e-1))]===0];
seriesInput={0,(1+x)/(e^2*(1-e*x+e^2*y)),e^4/(1-e),((e+x)^2-x^2)/(e^3*(e+x))};
series=FeynFacet`RationalLaurentCoefficients[seriesInput,{e,x,y},e,{-3,3}];
FTAssert["the rational recurrence agrees with independent Laurent series coefficient by coefficient",
 ListQ[series]&&And@@Flatten[Table[
  Cancel[Together[series[[i]][k]-SeriesCoefficient[seriesInput[[i]],{e,0,k}]]]===0,
 {i,Length[seriesInput]},{k,-3,3}]]];
FTAssert["orders below the valuation and zero functions are explicit zeros",
 ListQ[series]&&Values[series[[1]]]===ConstantArray[0,7]&&Values[series[[3]]]===ConstantArray[0,7]];
FTAssert["an expansion variable must be declared",
 FailureQ[FeynFacet`RationalLaurentCoefficients[{1/(1-e)},{x},e,{0,3}]]];
FTReport[];
