#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Boundary/Integration.wl"];
Get[root<>"/FeynFacet/Boundary/IntegralOrders.wl"];
Get[root<>"/FeynFacet/Solutions/Construction.wl"];
Clear[extensionEpsilon,extensionX];
definition=<|"Representation"->"UnitCube","DimensionalRegulator"->extensionEpsilon,
 "Terms"->{<|"IntegrationVariables"->{extensionX},"EndpointPowers"->{-extensionEpsilon}|>}|>;
input=<|"Index"->1,"LaurentLowerBound"->0,"IntegralDefinition"->definition,
 "LaurentCoefficients"-><|0->1|>,"AnalyticExpression"->Missing["LaurentSeriesOnly"]|>;
red=<|"DimensionalRegulator"->extensionEpsilon,"BoundaryInputs"->{input}|>;
result=FeynFacet`ExtendBoundaryInputOrders[red,{{1,1}},"IntegrationBackend"->"GammaBeta"];
FTAssert["only the missing order is added with an exact overlap check",
 AssociationQ[result]&&result["UpdatedBoundaryInputs"][1]["LaurentCoefficients"]===<|0->1,1->1|>&&
 result["Reports"][[1,"NewOrders"]]==={1}&&TrueQ[result["Reports"][[1,"ExactOverlapChecks"]][0]]];
again=FeynFacet`ExtendBoundaryInputOrders[Join[red,<|"BoundaryInputs"->{result["UpdatedBoundaryInputs"][1]}|>],{{1,1}}];
FTAssert["available orders do not trigger another integration",again["UpdatedBoundaryInputs"]===<||>];
bad=Join[input,<|"LaurentCoefficients"-><|0->2|>|>];
FTAssert["changed overlapping coefficients are rejected",
 MatchQ[FeynFacet`ExtendBoundaryInputOrders[Join[red,<|"BoundaryInputs"->{bad}|>],{{1,1}},"IntegrationBackend"->"GammaBeta"],
 Failure["BoundaryInputExtensionOverlapNotEstablished",_]]];
FTAssert["a missing exact integral definition cannot produce a coefficient",
 MatchQ[FeynFacet`ExtendBoundaryInputOrders[Join[red,<|"BoundaryInputs"->{KeyDrop[input,"IntegralDefinition"]}|>],{{1,1}}],
 Failure["PhysicalBoundaryIntegralDefinitionRequired",_]]];
FTAssert["explicit standard GPL constants are accepted in finite physical coefficients",
 FeynFacet`Private`solutionExplicitExpressionQ[FeynFacetSolution`G[{0,0,-1,-1},1]+Zeta[3]]];
FTAssert["unknown constants and generators remain rejected",
 !FeynFacet`Private`solutionExplicitExpressionQ[FeynFacetSolution`C[1,0]]&&
 !FeynFacet`Private`solutionExplicitExpressionQ[Function[x,x^2]]];
FTReport[];
