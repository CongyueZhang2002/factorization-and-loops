Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[eps,aa,bb,cc,dd];
matrix=ExpandLaurentCoefficientMatrix[{{1/eps,1},{0,eps}},eps,{0,1}];
vector=ExpandLaurentCoefficientVector[{1+eps aa+eps^2 bb,2/eps+cc+eps dd},
 eps,{{0,1},{-1,1}}];
product=WithEpsilonRemainderChecks[
 MultiplyLaurentCoefficientMatrix[matrix,vector,{{-1,0},{0,0}}]];
FTAssert["pole multiplication includes the positive input coefficient needed at finite order",
 AssociationQ[product["Result"]]&&product["Result"]["Coefficients"]===
 <|{1,-1}->3,{1,0}->aa+cc,{2,0}->2|>&&product["EpsilonRemainderAudit"]["Status"]==="Passed"];
matrix=ExpandLaurentCoefficientMatrix[{{1/eps}},eps,{-1}];
vector=ExpandLaurentCoefficientVector[{1/(1-eps)},eps,{{0,0}}];
FTAssert["a vector truncated before the contributing positive order is rejected",
 MatchQ[MultiplyLaurentCoefficientMatrix[matrix,vector,{{0,0}}],
  Failure["StoredLaurentVectorOrderMissing",_]]];
matrix=ExpandLaurentCoefficientMatrix[{{1/(1-eps)}},eps,{0}];
vector=ExpandLaurentCoefficientVector[{1/eps},eps,{{-1,-1}}];
FTAssert["a matrix truncated before a coefficient multiplying a pole is rejected",
 MatchQ[MultiplyLaurentCoefficientMatrix[matrix,vector,{{0,0}}],
  Failure["LaurentMatrixOrdersInsufficient",_]]];
matrix=ExpandLaurentCoefficientMatrix[{{1/eps}},eps,{-1}];
vector=ExpandLaurentCoefficientVector[{1/(1-eps)},eps,{{0,1}}];
product=WithEpsilonRemainderChecks[MultiplyLaurentCoefficientMatrix[matrix,vector,{{0,0}}],
 "TruncationOrderShift"->-1];
FTAssert["the debug omitted coefficient independently detects a one-order-short tail",
 product["EpsilonRemainderAudit"]["Status"]==="Failed"];
vector=ExpandLaurentCoefficientVector[{1},eps,{{0,0}}];
product=MultiplyLaurentCoefficientMatrix[matrix,vector,{{0,0}}];
FTAssert["an exactly terminating input has zero higher coefficients",
 AssociationQ[product]&&product["Coefficients"]===<|{1,0}->0|>];
FTAssert["an invalid requested window returns a failure rather than an unevaluated call",
 FailureQ[MultiplyLaurentCoefficientMatrix[matrix,vector,Missing["Range"]]]];
matrix=ExpandLaurentCoefficientMatrix[{{1}},eps,{0}];
vector=ExpandLaurentCoefficientVector[{1/(1-eps)},eps,{{0,2}}];
vector["Coefficients"]=KeyDrop[vector["Coefficients"],Key[{1,1}]];
FTAssert["a missing coefficient inside an otherwise sufficient window is rejected",
 FailureQ[MultiplyLaurentCoefficientMatrix[matrix,vector,{{0,2}}]]];
matrix=ExpandLaurentCoefficientMatrix[{{Exp[eps scaleLog]}},eps,{1}];
vector=ExpandLaurentCoefficientVector[{1/eps},eps,{{-1,-1}}];
product=MultiplyLaurentCoefficientMatrix[matrix,vector,{{0,0}}];
FTAssert["analytic normalization factors retain their positive orders multiplying a pole",
 AssociationQ[product]&&product["Coefficients"]===<|{1,0}->scaleLog|>];
matrix=ExpandLaurentCoefficientMatrix[{{Exp[eps scaleLog],Exp[eps scaleLog]},
 {0,Exp[eps scaleLog]}},eps,{1,3}];
FTAssert["a repeated matrix entry is expanded through the largest requested column order",
 matrix["CoefficientMatrices"][3]==={{0,scaleLog^3/6},{0,scaleLog^3/6}}&&
 matrix["CoefficientMatrices"][1]==={{scaleLog,scaleLog},{0,scaleLog}}];
matrix=ExpandLaurentCoefficientMatrix[{{eps^2,0}},eps,{0,0}];
FTAssert["entries beginning above the requested range retain their proved lower bounds",
 matrix["CoefficientMatrices"]===<||>&&matrix["EntryLaurentLowerBounds"]==={{2,Infinity}}];
source=<|"Format"->"FeynFacet-VirtualIntegralFamilies","CoefficientRules"->
 <|"Scalar"-><|FeynCalc`GLI[virtualSource,{1}]->1/eps^2|>|>|>;
reduction=<|"Rules"->{FeynCalc`GLI[virtualSource,{1}]->FeynCalc`GLI[virtualMaster,{1}]}|>;
matching=<|"Status"->"AllMastersMatched","MasterLabels"->{FeynCalc`GLI[virtualMaster,{1}]->"scalar"},
 "Library"->{<|"Name"->"scalar","LaurentLowerBound"->-1|>}|>;
retained=ExpandMatchedVirtualIntegralCombination[source,reduction,matching,eps,{0,0},
 Function[{name,orders},ExpandLaurentCoefficientVector[{1/(eps(1-eps))},eps,{orders}]],
 <|"RetainAllPoles"->True|>];
FTAssert["raw virtual contraction retains derived poles below a caller's requested lower order",
 AssociationQ[retained]&&retained["OutputEpsilonRanges"]==={{-3,0}}&&
 retained["Coefficients"]===<|{1,-3}->1,{1,-2}->1,{1,-1}->1,{1,0}->1|>];
Print["LAURENT SERIES PRODUCT TEST COMPLETE"];
FTReport[];
