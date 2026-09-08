root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Clear[e,x,z];
system=<|"KinematicVariables"->{x},"DimensionalRegulator"->e,"ConnectionMatrices"->{{{e/(1-e)}}}|>;
request=<|"BasePoint"->{1/5},"RequestedEpsilonOrders"->{0,1,2},
 "AnalyticDomain"->"Ordinary neighborhood of 1/5","BranchPrescription"->"Real interval"|>;
normal=ConstructMasterIntegralSolution[system,request,"FlatnessCheck"->"Exact"];
checked=WithEpsilonRemainderChecks[ConstructMasterIntegralSolution[system,request,"FlatnessCheck"->"Exact"]];
If[checked["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[checked]];
FTAssert["stage 2 recurrence and basis checks pass without altering the finite solution",
 checked["EpsilonRemainderAudit"]["Status"]==="Passed"&&checked["Result"]["Coefficients"]===normal["Coefficients"]];
saved=CheckMasterIntegralSolutionEpsilonRemainders[normal];
If[saved["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[saved]];
FTAssert["saved stage 2 orders can be audited without constructing new integrals",
 saved["EpsilonRemainderAudit"]["Status"]==="Passed"&&saved["Result"]["NewIntegralEvaluations"]===0];
saved=CheckMasterIntegralSolutionEpsilonRemainders[normal,"TruncationOrderShift"->-1];
FTAssert["saved stage 2 audit catches deliberately reduced cutoffs",saved["EpsilonRemainderAudit"]["Status"]==="Failed"];
zeroSystem=Join[system,<|"ConnectionMatrices"->{{{0,e^2/(1-e)},{0,e/(1-e)}}}|>];
zeroSolution=ConstructMasterIntegralSolution[zeroSystem,Join[request,<|"RequestedRows"->{1}|>],"FlatnessCheck"->"Exact"];
zeroIndex=Length[zeroSolution["KernelDefinitions"]]+1;
zeroSolution["KernelDefinitions"]=Append[zeroSolution["KernelDefinitions"],
 <|"Index"->zeroIndex,"Parameter"->x,"Expression"->(1-x^2)/(1-x)-1-x,"Kind"->"IntegrationKernel"|>];
zeroMatrices=zeroSolution["KernelMatrices"];
zeroMatrices[1]=ReplacePart[zeroMatrices[1],{1,2}->FeynFacetSolution`K[zeroIndex,x]];
zeroSolution["KernelMatrices"]=zeroMatrices;
saved=CheckMasterIntegralSolutionEpsilonRemainders[zeroSolution];
If[saved["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[saved]];
FTAssert["a shared kernel that vanishes algebraically does not create a false order demand",
 saved["EpsilonRemainderAudit"]["Status"]==="Passed"&&
 Lookup[saved["EpsilonRemainderAudit"]["ChecksByStage"],"Stage2/ZeroCoefficientIdentity",0]>0];
zeroSolution["KernelDefinitions"]=ReplacePart[zeroSolution["KernelDefinitions"],{zeroIndex,"Expression"}->1];
saved=CheckMasterIntegralSolutionEpsilonRemainders[zeroSolution];
FTAssert["the saved audit proves kernel zeros instead of trusting the planner's larger valuation",
 saved["EpsilonRemainderAudit"]["Status"]==="Failed"];
broken=WithEpsilonRemainderChecks[ConstructMasterIntegralSolution[system,request,"FlatnessCheck"->"Exact"],"TruncationOrderShift"->-1];
FTAssert["stage 2 rejects a deliberately shortened connection expansion",broken["EpsilonRemainderAudit"]["Status"]==="Failed"];
matrix={{1,x/e},{0,1}};
bs=<|"KinematicVariables"->{x},"DimensionalRegulator"->e,"ConnectionMatrices"->{e{{0,0},{1,0}}},"BasisTransformationMatrix"->matrix|>;
br=Join[request,<|"RequestedEpsilonOrders"->{-1,0,1}|>];
checked=WithEpsilonRemainderChecks[ConstructMasterIntegralSolution[bs,br,"FlatnessCheck"->"Exact"]];
If[checked["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[checked]];
FTAssert["stage 2 handles epsilon poles on both sides of the evolution matrix",checked["EpsilonRemainderAudit"]["Status"]==="Passed"];
Clear[loopMomentum,toyFamily];
topology=FeynCalc`FCTopology[toyFamily,{FeynCalc`SFAD[{loopMomentum,x}]},{loopMomentum},{},{},{}];
masterSystem=Join[system,<|"Topology"->topology,"OriginalMasterIntegralBasis"->{FeynCalc`GLI[toyFamily,{2}]}|>];
checked=WithEpsilonRemainderChecks[ConstructMasterIntegralSolution[masterSystem,
 <|"BasePoint"->{1/5},"RequestedMasterIntegralOrderRanges"-><|1->{-1,0}|>|>]];
If[checked["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[checked]];
FTAssert["requested master orders check the final evolution times boundary convolution",
 checked["EpsilonRemainderAudit"]["Status"]==="Passed"&&
 Lookup[checked["EpsilonRemainderAudit"]["ChecksByStage"],"Stage2/BoundaryConvolution",0]>0];
problem=<|"BoundaryAmplitudeReduction"-><|"DimensionalRegulator"->e,"ReductionMatrix"->{{1/e^2}},
 "BoundaryIntegralLaurentLowerBounds"->{0}|>,"RequestedAmplitudeCoefficients"->{{1,0}},
 "BoundaryIntegralDefinitions"-><|1-><|"Representation"->"UnitCube","DimensionalRegulator"->e,
 "Terms"->{<|"IntegrationVariables"->{},"Prefactor"->1/(1-e)|>}|>|>|>;
checked=WithEpsilonRemainderChecks[EvaluateBoundaryIntegralSystem[problem,"IntegrationBackend"->"GammaBeta"]];
If[checked["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[checked]];
FTAssert["stage 3 includes boundary orders pulled down by reduction poles",
 checked["EpsilonRemainderAudit"]["Status"]==="Passed"&&checked["Result"]["AmplitudeLaurentCoefficients"][[Key[{1,0}]]]===1];
broken=WithEpsilonRemainderChecks[EvaluateBoundaryIntegralSystem[problem,"IntegrationBackend"->"GammaBeta"],"TruncationOrderShift"->-1];
FTAssert["stage 3 rejects a deliberately shortened boundary expansion",broken["EpsilonRemainderAudit"]["Status"]==="Failed"];
series[vals_,lo_:0,exact_:False]:=<|"LaurentLowerBound"->lo,"KnownThroughOrder"->lo+Length[vals]-1,
 "Coefficients"->AssociationThread[Range[lo,lo+Length[vals]-1],vals],"ExactInEpsilon"->exact|>;
d=<|"DimensionalRegulator"->e,"Variable"->z,"Interval"->{0,3/4},"Assumptions"->True,
 "EndpointConditions"-><|"NoOtherSingularities"->True,"UniformEpsilonExpansion"->True,"RepresentationValidOnInterval"->True|>,
 "Terms"->{<|"Power"->-1+2e,"LogPower"->1,"Prefactor"->Gamma[1+e]/e,
 "TaylorCoefficients"-><|0->series[{1,2,3,4}]|>,"Remainder"->series[{0},0,True],"RemainderEndpointPowerLowerBound"->0|>}|>;
normal=ExtractEndpointDistributions[d,<|"ThroughOrder"->0|>];
checked=WithEpsilonRemainderChecks[ExtractEndpointDistributions[d,<|"ThroughOrder"->0|>]];
If[checked["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[checked]];
FTAssert["stage 4 checks Gamma normalization and logarithmic endpoint moments independently of the pole planner",
 checked["EpsilonRemainderAudit"]["Status"]==="Passed"&&checked["Result"]["Expression"]===normal["Expression"]];
broken=WithEpsilonRemainderChecks[ExtractEndpointDistributions[d,<|"ThroughOrder"->0|>],"TruncationOrderShift"->-1];
FTAssert["stage 4 catches contamination of the finite delta coefficient by an omitted positive epsilon order",
 broken["EpsilonRemainderAudit"]["Status"]==="Failed"];
(* Known amplitude 1+epsilon, multiplied by a boundary connection 1/epsilon.
   The epsilon^0 output requires the amplitude through epsilon^1. *)
connection=<|"DimensionalRegulator"->e,"KinematicVariables"->{x},"BoundaryDimension"->1,"Dimension"->1,
 "Coefficients"-><|-1->{1->{1}},0->{1->{0}}|>,"ColumnUpperOrders"->{0},"MatrixEntryLaurentLowerBounds"->{{-1}},
 "AlgebraicDefinitions"->{},"IntegralDefinitions"->{},"KernelDefinitions"->{},"Path"-><||>,
 "ContourDeformation"->0,"EndpointPower"->-2e,"BranchPrescription"->"Positive normal coordinate","CountertermNormalOrder"->0|>;
spec=<|"OrdinaryPointBoundaryBasis"->{1},"SourceMasterRows"->{1},"RequiredBoundaryCoefficients"->{{1,0}},
 "ReferencePointCoordinates"->{{1/5}},"AmplitudeLaurentLowerBounds"->{0},"KnownAmplitudeExpressions"-><|1->1+e|>,
 "UnknownAmplitudeDefinitions"->{}|>;
checked=WithEpsilonRemainderChecks[ConstructSharedBoundaryCoefficientDefinitions[connection,spec]];
If[checked["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[checked]];
got=checked["Result"];
value=If[AssociationQ[got],got["BoundaryCoefficientDefinitions"][[Key[{1,0}]]]/.
 FeynFacetSolution`a[i_Integer]:>got["AlgebraicDefinitions"][[i]],$Failed];
FTAssert["known boundary amplitudes are expanded deeply enough for a singular matching matrix",
 checked["EpsilonRemainderAudit"]["Status"]==="Passed"&&value===1];
FTReport[];
