
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/Tests/TestKit.wl"];
form[a_,b_]:=<|"LoopCoefficients"->a,"ExternalCoefficients"->b,"Weight"->1|>;
den[f_]:=<|"Power"->1,"SquaredForms"->{f}|>;
one=<|"DimensionalRegulator"->ee,"LoopDimension"->2-2ee,"ExternalGramMatrix"->{{3/7}},
 "QuadraticDenominators"->{den[form[{1},{0}]],den[form[{1},{1}]]}|>;
two=Join[one,<|"ExternalGramMatrix"->{{1}},
 "QuadraticDenominators"->{den[form[{1},{2}]],den[form[{1},{5}]]}|>];
a=FeynFacet`NormalizeEuclideanIntegralScale[one];b=FeynFacet`NormalizeEuclideanIntegralScale[two];
FTAssert["translation and squared-distance scaling give one explicit integral",
 AssociationQ[a]&&AssociationQ[b]&&a["IntegralEquivalenceKey"]===b["IntegralEquivalenceKey"]];
FTAssert["Gaussian measure and denominator powers determine the scale exponent",
 Simplify[a["IntegralScaleFactor"]-(3/7)^(-1-ee)]===0&&
 Simplify[b["IntegralScaleFactor"]-9^(-1-ee)]===0];
one["ExternalGramMatrix"]={{1}};
one["QuadraticDenominators"]={den[form[{1,0},{0}]],den[form[{0,1},{1}]],den[form[{1,-1},{0}]]};
two=one;changed=two["QuadraticDenominators"];changed[[3,"SquaredForms",1,"LoopCoefficients"]]={-1,1};two["QuadraticDenominators"]=changed;
FTAssert["the sign of a squared linear form does not change its integral",
 one=!=two&&FeynFacet`NormalizeEuclideanIntegralScale[one]["IntegralEquivalenceKey"]===
 FeynFacet`NormalizeEuclideanIntegralScale[two]["IntegralEquivalenceKey"]];
FTReport[];
