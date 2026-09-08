#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[testX,testE,testU];
testDirectory=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"coefficient-order-worker-"<>CreateUUID[]}]];
testOutput=testDirectory<>"/result";
testData=<|"Family"->"Toy","KinematicVariables"->{testX},"DimensionalRegulator"->testE,
 "ConnectionMatrices"->{{{testE/testX}}},"OriginalMasterIntegralBasis"->{FeynCalc`GLI[Global`Toy,{1}]}|>;
Export[testDirectory<>"/data.wxf",testData,"WXF"];
testOrders=<|"MasterIntegralInputMap"-><|
 "a"-><|"MasterIntegral"-><|"Family"->"Toy","PropagatorPowers"->{1}|>|>,
 "b"-><|"MasterIntegral"-><|"Family"->"Toy","PropagatorPowers"->{1}|>|>|>,
 "RequiredInputUpperOrders"-><|"a"->0,"b"->2|>,"Scope"->"Test coefficient table"|>;
Export[testDirectory<>"/orders.wxf",testOrders,"WXF"];
testSpec=<|"Family"->"Toy","DataFile"->testDirectory<>"/data.wxf",
 "OrderRequirementsFile"->testDirectory<>"/orders.wxf",
 "RequestOptions"-><|"BasePoint"->{1/4},"MasterIntegralRepresentations"-><|1->
  <|"Representation"->"UnitCube","Terms"->{<|"IntegrationVariables"->{testU},"EndpointPowers"->{-1-testE}|>}|>|>|>|>;
Put[testSpec,testDirectory<>"/specification.wl"];
testRun[]:=Catch[Block[{$ScriptCommandLine={"worker",testDirectory<>"/specification.wl",testOutput}},
 Get[root<>"/Scripts/Transport/solve_family_from_coefficient_orders.wls"]],"KernelPoolExit",Last[#1]&];
testExit=testRun[];
testSummary=Import[testOutput<>"/summary.wxf","WXF"];
FTAssert["symbol family identifiers and duplicate table demands produce the maximal complete range",
 testExit===0 && testSummary["Status"]==="Completed" &&
 testSummary["RequestedMasterIntegralOrderRanges"]===<|1->{-1,2}|> &&
 testSummary["StoredMasterCoefficientCount"]===4];
FTAssert["optional absent metadata still produces a readable JSON completion summary",
 AssociationQ[Import[testOutput<>"/summary.json","RawJSON"]] &&
 Import[testOutput<>"/summary.json","RawJSON"]["Status"]==="Completed"];
testBytes=BinaryReadList[testOutput<>"/solution.wxf"];
testExit=testRun[];
FTAssert["unchanged inputs reuse a completed solution without rewriting it",
 testExit===0 && TrueQ[result["ReusedCompletedResult"]] &&
 BinaryReadList[testOutput<>"/solution.wxf"]===testBytes];
testFullSolution=Import[testOutput<>"/solution.wxf","WXF"];
testOldPlan=Join[testFullSolution["ExpansionOrderDetermination"],
 <|"RequestedMasterIntegralOrderRanges"-><|1->{0,2}|>|>];
testOldSolution=FeynFacet`Private`solutionMasterCoefficientsFromOrders[testFullSolution,testOldPlan];
WriteMasterIntegralSolution[testOldSolution,testOutput,"FileFormat"->"WXF"];
Export[testOutput<>"/summary.wxf",Join[testSummary,
 <|"RequestedMasterIntegralOrderRanges"-><|1->{0,2}|>,"StoredMasterCoefficientCount"->3|>],"WXF"];
testExit=testRun[];
testRepaired=Import[testOutput<>"/solution.wxf","WXF"];
testSummary=Import[testOutput<>"/summary.wxf","WXF"];
FTAssert["a missing lower output coefficient is recovered from the existing finite evolution",
 testExit===0 && TrueQ[testSummary["ReusedFiniteEvolution"]] &&
 testRepaired["MasterIntegralCoefficients"]===testFullSolution["MasterIntegralCoefficients"] &&
 testRepaired["Coefficients"]===testFullSolution["Coefficients"]];
testBytes=BinaryReadList[testOutput<>"/solution.wxf"];
testOrders["RequiredInputUpperOrders"]=<|"a"->0,"b"->3|>;
Export[testDirectory<>"/orders.wxf",testOrders,"WXF"];
testExit=testRun[];
FTAssert["changed coefficient demands are refused and preserve the previous summary and solution",
 testExit===2 && Import[testOutput<>"/summary.wxf","WXF"]===testSummary &&
 BinaryReadList[testOutput<>"/solution.wxf"]===testBytes];
testSpec["Family"]="AnotherFamily";Put[testSpec,testDirectory<>"/specification.wl"];
testExit=testRun[];
FTAssert["invalid specifications cannot overwrite a completed mathematical result",
 testExit===2 && Import[testOutput<>"/summary.wxf","WXF"]===testSummary &&
 BinaryReadList[testOutput<>"/solution.wxf"]===testBytes];
FTReport[];
