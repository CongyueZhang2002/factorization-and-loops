Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
den=1+Sum[x^j y^(50-j),{j,1,50}];num=Sum[(j+1)x^j,{j,1,50}];
expr=(num+u(1+x)num+u v(num+2))/den;
rows=FeynFacet`PolynomialCoefficientRules[expr,{u,v}];
expected=CoefficientRules[Numerator[expr],{u,v}]/.Rule[a_,b_]:>Rule[a,b/den];
FTTest`FTAssert["scalar rational factors remain outside extracted polynomial coefficients",
 Together[expr-Total[(Last[#]u^First[#][[1]]v^First[#][[2]])&/@rows]]===0];
FTTest`FTAssert["the common denominator is not copied into every numerator monomial",
 ByteCount[rows]<5ByteCount[expr]];
FTTest`FTAssert["nested factored polynomial products retain exact coefficients",
 Together[Total[(Last[#]u^First[#][[1]]v^First[#][[2]])&/@FeynFacet`PolynomialCoefficientRules[(a+b u)(c+d v)/den,{u,v}]]-(a+b u)(c+d v)/den]===0];
FTTest`FTAssert["nonpolynomial active-variable dependence remains rejected",
 FailureQ[FeynFacet`PolynomialCoefficientRules[(1+u)/(2+u),{u}]]];
Print["POLYNOMIAL COEFFICIENT FACTOR TEST COMPLETE"];FTTest`FTReport[];
