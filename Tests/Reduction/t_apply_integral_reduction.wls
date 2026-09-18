Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
m1=FeynCalc`GLI[af,{1,0}];m2=FeynCalc`GLI[af,{0,1}];target=FeynCalc`GLI[af,{1,1}];
expression=(1-ax)(m1/(1-ax)+ax m2/(ax-1))+(ax^2-1)(m1+m2)/(ax-1);
reduction=<|"Masters"->{m1,m2},"Rules"->{target->expression}|>;
rows=<|"first"-><|target->1/(ax+1)|>,"second"-><|target->ax,m2->-ax|>|>;
answer=FeynFacet`ApplyIntegralReduction[rows,reduction];
expected=<|"first"->expression/(ax+1),"second"->ax expression-ax m2|>;
FTTest`FTAssert["nested factored linear rules contract exactly for multiple rows",
 AssociationQ[answer]&&AllTrue[Keys[rows],
  Together[Total[KeyValueMap[Times,answer[#]]]-expected[#]]===0&]];
FTTest`FTAssert["rule linearity validation rejects products of masters",
 FailureQ[FeynFacet`ApplyIntegralReduction[rows,Join[reduction,<|"Rules"->{target->m1 m2}|>]]]];
FTTest`FTAssert["rule linearity validation rejects a nonzero scalar remainder",
 FailureQ[FeynFacet`ApplyIntegralReduction[rows,Join[reduction,<|"Rules"->{target->m1+1}|>]]]];
FTTest`FTAssert["undeclared masters remain a closure failure",
 FailureQ[FeynFacet`ApplyIntegralReduction[rows,Join[reduction,<|"Masters"->{m1}|>]]]];
FTTest`FTReport[];
