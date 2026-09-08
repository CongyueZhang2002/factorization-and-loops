
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/Tests/TestKit.wl"];
base=FeynFacet`ReduceBoundaryAmplitudeSystem[<|"DimensionalRegulator"->ee,
 "CoefficientMatrix"->{{0}},"RightHandSideMatrix"->{{0}},
 "AmplitudeLaurentLowerBounds"->{0},"BoundaryInputLaurentLowerBounds"->{0}|>];
base=Join[base,<|"BoundaryInputs"->{<|"Index"->1,"LaurentLowerBound"->0,"AnalyticExpression"->1|>}|>];
definition=<|"Representation"->"UnitCube","DimensionalRegulator"->ee,"PhysicalLimitEstablished"->True,
 "Terms"->{<|"IntegrationVariables"->{},"Prefactor"->ee^2 Gamma[1+ee]|>}|>;
problem=<|"AmplitudeReduction"->base,"PhysicalCoefficientEquations"-><|
 "LeadingCoefficientRows"->{<|"OriginalRow"->17,"AmplitudeRow"->{0,ee^2}|>}|>,
 "PhysicalBoundaryIntegralDefinitions"-><|17->definition|>,
 "SeedAmplitudeToUnknownMatrix"->{{0},{1}},"SeedAmplitudeToBoundaryInputMatrix"->{{1},{0}},
 "RequestedAmplitudeCoefficients"->{{1,1}},"PreviouslyDeterminedBoundaryInputsArePhysical"->True|>;
answer=FeynFacet`DetermineBoundaryAmplitudes[problem];
FTAssert["physical coefficient equations eliminate the free amplitude",
 AssociationQ[answer]&&answer["RemainingUnknownAmplitudeCount"]===0&&
 TrueQ[answer["PhysicalBoundaryValuesCompleteForStoredOrders"]]];
FTAssert["the amplitude multiplier determines the sufficient integral orders",
 answer["InputOrderDetermination"]["BoundaryIntegralOrderRanges"][2]==={2,3}&&
 answer["BoundaryInputMatrix"][[1,2]]===ee^-2];
FTAssert["actual evaluated coefficients determine the requested amplitude",
 answer["BoundaryInputs"][[2,"LaurentCoefficients"]][3]===-EulerGamma];
bad=problem;bad["PhysicalBoundaryIntegralDefinitions"]=<|17->KeyDrop[definition,"PhysicalLimitEstablished"]|>;
FTAssert["unestablished physical limits cannot determine constants",FailureQ[FeynFacet`DetermineBoundaryAmplitudes[bad]]];
bad=problem;bad["EvaluatedBoundaryIntegrals"]=<|17-><|"IntegralDefinition"->Join[definition,<|"Terms"->{}|>],
 "LaurentCoefficients"-><|2->1,3->0|>|>|>;
FTAssert["cached coefficients must belong to the stated integral",FailureQ[FeynFacet`DetermineBoundaryAmplitudes[bad]]];
FTReport[];
