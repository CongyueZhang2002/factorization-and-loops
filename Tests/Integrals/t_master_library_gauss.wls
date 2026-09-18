Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
(* Test the common library result adapter with a synthetic exact function;
   no physical integral is published by this test. *)
definition=<|"MasterIntegral"->FeynCalc`GLI["GaussFixture",{1}],"DimensionalRegulator"->e|>;
value=<|"ExactValue"->Hypergeometric2F1[e,1,2,x]/e|>;
result=FeynFacet`Private`masterLibraryResult[definition,value,{0,0},<||>];
FTTest`FTAssert["a high requested order retains every lower coefficient of the exact Gauss value",
 AssociationQ[result]&&result["LaurentLowerBound"]===-1&&Sort[Keys[result["Coefficients"]]]==={-1,0}];
FTTest`FTAssert["the omitted lower pole is not silently replaced by zero",result["Coefficients"][-1]===1];
number=FeynFacetSolution`EvaluateGPLExpression[result["Coefficients"][0],{x->1/3},"WorkingPrecision"->40];
FTTest`FTAssert["the finite Gauss coefficient agrees with the independent elementary closed form",
 NumericQ[number]&&Abs[number-N[1+2Log[2/3],40]]<10^-30];
Print["MASTER LIBRARY GAUSS TEST COMPLETE"];FTTest`FTReport[];
