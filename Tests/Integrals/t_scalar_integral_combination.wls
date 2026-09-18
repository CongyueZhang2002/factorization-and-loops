Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Module[{rows,values,result,short,hole,expr,reference,conjugate},
 rows=<|"A"-><|ma->1/(ce(1-ce)),mb->ce|>,"B"-><|ma->-1/ce|>|>;
 values=<|ma-><|"LaurentLowerBound"->-1,"KnownThroughOrder"->1,
    "Coefficients"-><|-1->I,0->2,1->3|>|>,
   mb-><|"LaurentLowerBound"->-2,"KnownThroughOrder"->0,
    "Coefficients"-><|-2->4,-1->5,0->6|>|>|>;
 result=FeynFacet`ExpandScalarIntegralCombination[rows,values,ce,{0,0},<|"RetainAllPoles"->True|>];
 FTTest`FTAssert["the contraction retains every implied pole",AssociationQ[result]&&
   result["OutputEpsilonRanges"]==={{-2,0},{-2,0}}&&result["OrderCoverageVerified"]];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 expr={1/(ce(1-ce))(I/ce+2+3ce)+ce(4/ce^2+5/ce+6),-(I/ce+2+3ce)/ce};
 reference=FeynFacet`ExpandLaurentCoefficientVector[expr,ce,{{-2,0},{-2,0}}];
 FTTest`FTAssert["independent exact expressions give the same finite coefficients",
   AllTrue[Values[Merge[{result["Coefficients"],Map[-#&,reference["Coefficients"]]},Total]],Simplify[#]===0&]];
 short=values;short[ma]=Join[values[ma],<|"KnownThroughOrder"->0,"Coefficients"->KeyDrop[values[ma]["Coefficients"],1]|>];
 FTTest`FTAssert["one missing positive master order is rejected",FailureQ[
   FeynFacet`ExpandScalarIntegralCombination[rows,short,ce,{0,0}]]];
 hole=values;hole[ma]=Join[values[ma],<|"Coefficients"->KeyDrop[values[ma]["Coefficients"],0]|>];
 FTTest`FTAssert["holes in a claimed stored window are rejected",FailureQ[
   FeynFacet`ExpandScalarIntegralCombination[rows,hole,ce,{0,0}]]];
 FTTest`FTAssert["missing scalar integrals cannot silently vanish",FailureQ[
   FeynFacet`ExpandScalarIntegralCombination[rows,KeyDrop[values,mb],ce,{0,0}]]];
 conjugate=FeynFacet`ConjugateExplicitScalarFunctions[result["Coefficients"],True];
 FTTest`FTAssert["the scalar contraction leaves Hermitian completion explicit",
   result["ConjugateInterferenceAdded"]===False&&
   FreeQ[Simplify/@Merge[{result["Coefficients"],conjugate},Total],_Complex]];
];
Print["SCALAR INTEGRAL COMBINATION TEST COMPLETE"];FTTest`FTReport[];
