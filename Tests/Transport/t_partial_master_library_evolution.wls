Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
prep=FeynFacet`PrepareSingularBoundarySystem[<|"Variable"->x,"DimensionalRegulator"->ep,
 "ConnectionMatrix"->{{ep/(1-x),0},{1/(1-x),0}}|>];
If[!AssociationQ[prep],Print[prep];Exit[1]];
seed=IdentityMatrix[2];
amps=FeynFacet`ExpandLaurentCoefficientVector[{1,0},ep,{{0,2},{0,2}}];
known=<|"LaurentLowerBound"->0,"KnownThroughOrder"->1,
 "Coefficients"-><|0->1,1->-Log[1-x]|>|>;
req=<|"MasterIntegralUpperOrders"->{2,2},"OriginalMasterLaurentLowerBounds"->{0,0},
 "ColumnUpperOrders"->{2,2},"KnownMasterValues"-><|1->known|>,
 "Assumptions"->0<x<1,"GPLTimeLimit"->30|>;
partial=FeynFacet`ConstructPhysicalBoundarySolution[prep,seed,amps,req];
If[!AssociationQ[partial],Print[partial];Exit[1]];
full=FeynFacet`ConstructPhysicalBoundarySolution[prep,seed,amps,Append[req,"KnownMasterValues"-><||>]];
If[!AssociationQ[full],Print[full];Exit[1]];
simplify[v_]:=Simplify[v/.FeynFacetSolution`G[w_List,x]/;AllTrue[w,#===1&]:>
  Log[1-x]^Length[w]/Length[w]!];
FTTest`FTAssert["partial reuse returns the same complete epsilon coefficients as a fresh solve",
 AllTrue[Keys[full["Coefficients"]],simplify[
 full["Coefficients"][[Key[#]]]-partial["Coefficients"][[Key[#]]]]===0&]];
FTTest`FTAssert["the inhomogeneous unknown agrees with its independent exact solution",
 AllTrue[Range[0,2],simplify[partial["Coefficients"][[Key[{2,#}]]]-
  (-Log[1-x])^(#+1)/(#+1)!]===0&]];
FTTest`FTAssert["completed epsilon coefficients are injected rather than reintegrated",
 Length[partial["PartialReuse"]["IntegratedCoefficients"]]<
  Length[full["PartialReuse"]["IntegratedCoefficients"]]&&
 partial["PartialReuse"]["ReusedPreparedCoefficients"]=!={}];
FTTest`FTAssert["a missing higher order of a known master is actually evolved",
 simplify[partial["Coefficients"][[Key[{1,2}]]]-Log[1-x]^2/2]===0&&
 MemberQ[partial["PartialReuse"]["IntegratedCoefficients"],{1,2}]];
shifted=prep;shifted["NormalizedToOriginalGauge"]={{ep,0},{0,1}};
shifted["PreparedDifferentialSystem"]=Append[shifted["PreparedDifferentialSystem"],
 "BasisTransformationMatrix"->{{ep,0},{0,1}}];
shiftedKnown=<|"LaurentLowerBound"->1,"KnownThroughOrder"->1,"Coefficients"-><|1->1|>|>;
shiftedResult=FeynFacet`ConstructPhysicalBoundarySolution[shifted,seed,amps,
 Join[req,<|"MasterIntegralUpperOrders"->{1,1},"OriginalMasterLaurentLowerBounds"->{1,0},
 "KnownMasterValues"-><|1->shiftedKnown|>|>]];
If[!AssociationQ[shiftedResult],Print[shiftedResult];Exit[1]];
FTTest`FTAssert["an inverse-gauge epsilon pole cannot manufacture missing known orders",
 simplify[shiftedResult["Coefficients"][[Key[{2,1}]]]-Log[1-x]^2/2]===0&&
 MemberQ[shiftedResult["PartialReuse"]["IntegratedCoefficients"],{1,1}]];
singular=FeynFacet`PrepareSingularBoundarySystem[<|"Variable"->x,"DimensionalRegulator"->ep,
 "ConnectionMatrix"->{{ep/x,0},{1/x,0}}|>];
singularResult=FeynFacet`ConstructPhysicalBoundarySolution[singular,seed,amps,
 Append[req,"KnownMasterValues"-><||>]];
FTTest`FTAssert["coalescing Frobenius sectors retain (x^epsilon-1)/epsilon logarithms",
 AssociationQ[singularResult]&&AllTrue[Range[0,2],
 Simplify[singularResult["Coefficients"][[Key[{2,#}]]]-Log[x]^(#+1)/(#+1)!]===0&]];
shortAmps=FeynFacet`ExpandLaurentCoefficientVector[{1+ep^2,0},ep,{{0,1},{0,1}}];
missing=FeynFacet`ConstructPhysicalBoundarySolution[prep,seed,shortAmps,Append[req,"KnownMasterValues"-><||>]];
FTTest`FTAssert["insufficient physical amplitude coverage fails rather than filling zeros",
 FailureQ[missing]];
cancellation=FeynFacetSolution`IntegrateGPL[Log[1+t]/t^2-1/t,{t,0,x},
 "Assumptions"->0<x<1,"TimeLimit"->30];
FTTest`FTAssert["the complete endpoint integrand cancels before its boundary limit",
 !FailureQ[cancellation]&&Simplify[(cancellation/.FeynFacetSolution`G[{-1},x]->Log[1+x])-
  (1-(1+1/x)Log[1+x])] ===0];
FTTest`FTReport[];
