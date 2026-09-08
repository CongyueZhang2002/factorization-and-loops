#!/usr/bin/env wolframscript
finiteDensityTestRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{finiteDensityTestRoot,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{finiteDensityTestRoot,"FeynFacet","Algebra","RegulatorSeries.wl"}]];
Get[FileNameJoin[{finiteDensityTestRoot,"FeynFacet","Algebra","EpsilonRemainders.wl"}]];
Get[FileNameJoin[{finiteDensityTestRoot,"FeynFacet","Solutions","Orders","LaurentBounds.wl"}]];
Get[FileNameJoin[{finiteDensityTestRoot,"FeynFacet","Solutions","Representation.wl"}]];
Get[FileNameJoin[{finiteDensityTestRoot,"FeynFacet","Solutions","SharedDefinitions.wl"}]];
Begin["FeynFacet`Private`"];
Get[FileNameJoin[{Global`finiteDensityTestRoot,"FeynFacet","Coefficients","FinalResults.wl"}]];
$feynFacetEpsilon=Global`finiteDensityTestEpsilon;
End[];
Get[FileNameJoin[{finiteDensityTestRoot,"FeynFacet","Coefficients","FiniteDensity.wl"}]];
Clear[finiteDensityTestEpsilon,finiteDensityTestX,finiteDensityTestY,finiteDensityTestT,finiteDensityTestS];
finiteDensityTestDirectory=CreateDirectory[];
finiteDensityTestSharedFile=FileNameJoin[{finiteDensityTestDirectory,"shared.wxf"}];
finiteDensityTestKernel[value_] := <|"Index"->1,"Parameter"->finiteDensityTestT,"Expression"->value|>;
finiteDensityTestIntegral=<|"Index"->1,"IntegrationVariable"->finiteDensityTestT,
 "UpperLimitVariable"->finiteDensityTestS,"LowerLimit"->0,"Integrand"->FeynFacetSolution`K[1,finiteDensityTestT]|>;
finiteDensityTestShared=<|"DataType"->"SharedBoundaryCoefficientDefinitions",
 "PhysicalBoundaryValuesCompleteForStoredOrders"->True,
 "BoundaryCoefficientDefinitions"-><|{1,-1}->7+FeynFacetSolution`a[1],{1,0}->FeynFacetSolution`a[2]|>,
 "AlgebraicDefinitions"->{11,FeynFacetSolution`a[1]+FeynFacetSolution`K[1,1]},
 "KernelDefinitions"->{finiteDensityTestKernel[2]},"IntegralDefinitions"->{}|>;
Export[finiteDensityTestSharedFile,finiteDensityTestShared,"WXF"];
finiteDensityTestSolution[family_,lower_,algebra_,kernel_,coeff_] := <|
 "DataType"->"MasterIntegralSolution","Family"->family,
 "DimensionalRegulator"->finiteDensityTestEpsilon,"KinematicVariables"->{finiteDensityTestX,finiteDensityTestY},
 "OriginalMasterIntegralBasis"->{FeynCalc`GLI[family,{1}]},
 "RequestedMasterIntegralOrderRanges"-><|1->{lower,0}|>,"MasterIntegralCoefficients"->coeff,
 "PhysicalBoundaryValuesCompleteForStoredOrders"->True,"SharedBoundaryDefinitionFile"->finiteDensityTestSharedFile,
 "AlgebraicDefinitions"->{algebra},"KernelDefinitions"->{finiteDensityTestKernel[kernel]},
 "IntegralDefinitions"->{finiteDensityTestIntegral},"AnalyticDomain"->"The test domain",
 "BranchPrescription"->"Real branches","BasePoint"->{0,0}|>;
finiteDensityTestA=finiteDensityTestSolution["A",-1,2+finiteDensityTestX,1,<|
 -1->{1->FeynFacetSolution`a[1] FeynFacetSolution`B[1,-1]},
 0->{1->FeynFacetSolution`F[1,1]+FeynFacetSolution`a[1]FeynFacetSolution`B[1,0]}|>];
finiteDensityTestB=finiteDensityTestSolution["B",0,5-finiteDensityTestY,3,<|
 0->{1->FeynFacetSolution`a[1]+FeynFacetSolution`F[1,1]+FeynFacetSolution`B[1,-1]}|>];
finiteDensityTestSources=<|"familyA"->finiteDensityTestA,"familyB"->finiteDensityTestB|>;
finiteDensityTestExact[value_] := <|"PreFactor"->1,"Representation"->"Exact","Coefficient"->value|>;
finiteDensityTestFinite=<|"PreFactor"->1,"Representation"->"LaurentSeries","Coefficient"-><|
 "SeriesVariable"->finiteDensityTestEpsilon,"Orders"-><|0->2|>,"SeriesTruncation"->0|>|>;
finiteDensityTestTable=<|"Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
 "DimensionalRegulator"->finiteDensityTestEpsilon,"PreFactor"->3(1+2finiteDensityTestEpsilon),
 "Masters"->{<|"Master"->FeynCalc`GLI["A",{1}],"Terms"->{finiteDensityTestExact[1+finiteDensityTestEpsilon]}|>,
 <|"Master"->FeynCalc`GLI["B",{1}],"Terms"->{finiteDensityTestFinite}|>},
 "RemainderTerms"->{finiteDensityTestExact[4/finiteDensityTestEpsilon]},
 "FractionMeasure"->1,"PhaseSpace"->1,"Definitions"-><|"Setup"-><||>|>,
 "PhysicalMasterNormalizationApplied"->True,"CoefficientConvention"->"PhysicalMasterAtReferenceScale",
 "PhysicalDensityNormalization"-><|"ReferenceScale"->1,"Assumptions"->True|>|>;
finiteDensityTestRequest=<|"ThroughOrder"->0,"KinematicVariables"->{finiteDensityTestX,finiteDensityTestY},"SolutionReferenceScale"->1|>;
finiteDensityTestResult=FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,finiteDensityTestRequest];
finiteDensityTestChecked=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,finiteDensityTestRequest]];
If[finiteDensityTestChecked["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[finiteDensityTestChecked]];
FTAssert["debug remainders protect finite density convolutions without altering their coefficients",
 finiteDensityTestChecked["EpsilonRemainderAudit"]["Status"]==="Passed"&&
 finiteDensityTestChecked["Result"]["Coefficients"]===finiteDensityTestResult["Coefficients"]];
finiteDensityTestChecked=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,finiteDensityTestRequest],
 "TruncationOrderShift"->-1];
FTAssert["a one-order-short master or coefficient expansion contaminates the finite density",
 finiteDensityTestChecked["EpsilonRemainderAudit"]["Status"]==="Failed"];
finiteDensityTestParallel=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,finiteDensityTestRequest,
 "CoefficientWorkers"->2]];
If[finiteDensityTestParallel["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[finiteDensityTestParallel]];
FTAssert["independent coefficient workers reproduce the serial density and return their remainder checks",
 finiteDensityTestParallel["EpsilonRemainderAudit"]["Status"]==="Passed"&&
 finiteDensityTestParallel["Result"]["Coefficients"]===finiteDensityTestResult["Coefficients"]&&
 Lookup[finiteDensityTestParallel["EpsilonRemainderAudit"]["ChecksByStage"],"Stage4/FiniteCoefficientPrefactor",0]>0];
FTAssert["the coefficient batch closes its owned workers",Kernels[]==={}];
finiteDensityTestParallel=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,finiteDensityTestRequest,
 "CoefficientWorkers"->2],"TruncationOrderShift"->-1];
FTAssert["a remainder failure inside a worker stops assembly and still closes the worker pool",
 finiteDensityTestParallel["EpsilonRemainderAudit"]["Status"]==="Failed"&&Kernels[]==={}];
FTAssert["all scalar fields and evaluated sparse rows survive the first serialization exactly",
 FeynFacet`Private`finiteDensitySerializationEquivalentQ[finiteDensityTestResult,BinaryDeserialize[BinarySerialize[finiteDensityTestResult,PerformanceGoal->"Size"]]]];
finiteDensityTestAltered=finiteDensityTestResult;
finiteDensityTestAltered["Coefficients"]=Join[finiteDensityTestResult["Coefficients"],<|0->1+finiteDensityTestResult["Coefficients"][0]|>];
FTAssert["serialization comparison rejects altered scalar coefficient values",
 !FeynFacet`Private`finiteDensitySerializationEquivalentQ[finiteDensityTestResult,finiteDensityTestAltered]];
finiteDensityTestAltered=finiteDensityTestResult;
finiteDensityTestAltered["CoefficientConvolutionMatrices"]=Join[finiteDensityTestResult["CoefficientConvolutionMatrices"],<|0->SparseArray[{1->1},{3}]|>];
FTAssert["serialization comparison rejects altered sparse row values",
 !FeynFacet`Private`finiteDensitySerializationEquivalentQ[finiteDensityTestResult,finiteDensityTestAltered]];
FTAssert["all physical masters contribute to an explicit finite interior density",
 AssociationQ[finiteDensityTestResult] && finiteDensityTestResult["MasterCount"]===2 &&
 finiteDensityTestResult["SolutionCount"]===2 && finiteDensityTestResult["EpsilonOrderRange"]==={-1,0}];
(* Independently integrate the tiny scalar functions and substitute their
   definitions in dependency order; no density implementation helper is used. *)
finiteDensityTestResolve[result_] := Module[{ks={},fs={},as={},kr,fr,ar,rewrite,def,value},
 kr=Lookup[result,"KernelDefinitions"];fr=Lookup[result,"IntegralDefinitions"];ar=Lookup[result,"AlgebraicDefinitions"];
 rewrite[x_]:=x/.{FeynFacetSolution`K[j_Integer,u_]:>(ks[[j]]/.kr[[j,"Parameter"]]->u),
  FeynFacetSolution`F[j_Integer,u_]:>(fs[[j]]/.fr[[j,"UpperLimitVariable"]]->u),
  FeynFacetSolution`a[j_Integer]:>as[[j]]};
 Do[AppendTo[ks,rewrite[def["Expression"]]],{def,kr}];
 Do[value=rewrite[def["Integrand"]];AppendTo[fs,Integrate[value,{def["IntegrationVariable"],def["LowerLimit"],def["UpperLimitVariable"]}]],{def,fr}];
 Do[AppendTo[as,rewrite[value]],{value,ar}];rewrite[result["Coefficients"]]
];
finiteDensityTestResolved=finiteDensityTestResolve[finiteDensityTestResult];
FTAssert["finite density agrees with the independently integrated Laurent product",
 Expand[finiteDensityTestResolved[-1]-3(18(2+finiteDensityTestX)+4)]===0 &&
 Expand[finiteDensityTestResolved[0]-3(61+67(2+finiteDensityTestX)-2finiteDensityTestY)]===0];
FTAssert["shared boundary functions are installed once and family-local indices stay distinct",
 Length[finiteDensityTestResult["SharedBoundarySources"]]===1 &&
 Length[finiteDensityTestResult["KernelDefinitions"]]===3 &&
 Length[finiteDensityTestResult["IntegralDefinitions"]]===2 &&
 Length[finiteDensityTestResult["MasterCoefficientIndex"]]===3];
FTAssert["finite scalar definitions contain no unresolved boundary or initial constants",
 FreeQ[KeyTake[finiteDensityTestResult,{"Coefficients","AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions"}],
 _FeynFacetSolution`C|_FeynFacetSolution`B|_Series|_SeriesData|_SeriesCoefficient|_Missing|_Failure]];
FTAssert["coefficient and master upper-order demands are recorded separately",
 Lookup[finiteDensityTestResult["MasterOrderRequirements"],"RequiredMasterUpperOrder"]==={0,0} &&
 Lookup[finiteDensityTestResult["MasterOrderRequirements"],"RequiredCoefficientUpperOrder"]==={1,0}];
FTAssert["unscoped scalar references in a coefficient table cannot alias installed master definitions",
 MatchQ[FeynFacet`AssembleFiniteMasterIntegralDensity[
 Join[finiteDensityTestTable,<|"PreFactor"->FeynFacetSolution`a[1]|>],finiteDensityTestSources,finiteDensityTestRequest],
 Failure["CoefficientTableUnscopedFiniteReferences",_Association]] &&
 MatchQ[FeynFacet`AssembleFiniteMasterIntegralDensity[
 Join[finiteDensityTestTable,<|"PreFactor"->FeynFacetSolution`C[1,0]|>],finiteDensityTestSources,finiteDensityTestRequest],
 Failure["CoefficientTableUnscopedFiniteReferences",_Association]]];
finiteDensityTestHighRemainder=Join[finiteDensityTestTable,<|"RemainderTerms"->{finiteDensityTestExact[finiteDensityTestEpsilon^2]}|>];
finiteDensityTestHighRemainderResult=FeynFacet`AssembleFiniteMasterIntegralDensity[
 finiteDensityTestHighRemainder,finiteDensityTestSources,finiteDensityTestRequest];
FTAssert["scalar remainders above the requested order are omitted with their finite tail",
 AssociationQ[finiteDensityTestHighRemainderResult] &&
 Expand[finiteDensityTestResolve[finiteDensityTestHighRemainderResult][0]-
  (finiteDensityTestResolved[0]-24)]===0];
finiteDensityTestFailure=FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,
 Join[finiteDensityTestRequest,<|"ThroughOrder"->1|>]];
FTAssert["missing master and coefficient orders are both reported without zero filling",
 MatchQ[finiteDensityTestFailure,Failure["FiniteDensityOrdersInsufficient",_Association]] &&
 Length[finiteDensityTestFailure[[2]]["MissingMasterCoefficients"]]===2 &&
 Length[finiteDensityTestFailure[[2]]["MissingCoefficientOrders"]]===1];
finiteDensityTestBad=finiteDensityTestA;
finiteDensityTestBad["MasterIntegralCoefficients"]=<|-1->{1->0},0->{1->FeynFacetSolution`C[1,0]}|>;
FTAssert["selected master coefficients with unresolved constants are rejected",
 MatchQ[FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,
 Join[finiteDensityTestSources,<|"familyA"->finiteDensityTestBad|>],finiteDensityTestRequest],
 Failure["ExplicitPhysicalMasterCoefficientsRequired",_Association]]];
finiteDensityTestBad=finiteDensityTestB;finiteDensityTestBad["KinematicVariables"]={finiteDensityTestY,finiteDensityTestX};
FTAssert["mismatched two-variable solution coordinates are rejected",
 MatchQ[FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,
 Join[finiteDensityTestSources,<|"familyB"->finiteDensityTestBad|>],finiteDensityTestRequest],
 Failure["FiniteSolutionKinematicVariablesMismatch",_Association]]];
FTAssert["a different physical reference scale is rejected",
 MatchQ[FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,
 Join[finiteDensityTestRequest,<|"SolutionReferenceScale"->2|>]],
 Failure["MatchingSolutionKinematicsAndReferenceScaleRequired",_Association]]];
FTAssert["analytic power exponents are normalized before polynomial valuation",
 FeynFacet`DetermineMeromorphicLaurentLowerBound[2^(-6+3(3-2finiteDensityTestEpsilon)+6finiteDensityTestEpsilon),finiteDensityTestEpsilon]===0];
FTAssert["meromorphic sum bounds retain elementary regulator factors",
 FeynFacet`DetermineMeromorphicLaurentLowerBound[2^finiteDensityTestEpsilon/finiteDensityTestEpsilon+
  Pi^finiteDensityTestEpsilon/finiteDensityTestEpsilon^2,finiteDensityTestEpsilon]===-2];
FTAssert["a cancelled meromorphic sum gives a conservative lower bound",
 FeynFacet`DetermineMeromorphicLaurentLowerBound[Exp[finiteDensityTestEpsilon]-1,finiteDensityTestEpsilon]===0];
FTAssert["a reciprocal never negates an unproved structural denominator bound",
 FailureQ[FeynFacet`DetermineMeromorphicLaurentLowerBound[1/(Exp[finiteDensityTestEpsilon]-1),finiteDensityTestEpsilon]]];
finiteDensityTestMeromorphic=finiteDensityTestTable;
finiteDensityTestMeromorphic["Masters"]=ReplacePart[finiteDensityTestMeromorphic["Masters"],
 {1,"Terms"}->{finiteDensityTestExact[2^finiteDensityTestEpsilon+2finiteDensityTestEpsilon]}];
finiteDensityTestMeromorphicResult=FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestMeromorphic,
 finiteDensityTestSources,finiteDensityTestRequest];
finiteDensityTestMeromorphicResolved=finiteDensityTestResolve[finiteDensityTestMeromorphicResult];
FTAssert["finite density expands additive analytic prefactors without giant rational recombination",
 Expand[finiteDensityTestMeromorphicResolved[0]-3(61+(85+18Log[2])(2+finiteDensityTestX)-2finiteDensityTestY)]===0];finiteDensityTestBrokenShared=finiteDensityTestShared;
finiteDensityTestBrokenShared["AlgebraicDefinitions"]={FeynFacetSolution`a[1],FeynFacetSolution`a[1]};
Export[finiteDensityTestSharedFile,finiteDensityTestBrokenShared,"WXF"];
FTAssert["cyclic shared algebraic definitions are rejected",
 MatchQ[FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,finiteDensityTestSources,finiteDensityTestRequest],
 Failure["ExplicitSharedPhysicalBoundaryDefinitionsRequired",_Association]]];
Export[finiteDensityTestSharedFile,finiteDensityTestShared,"WXF"];
finiteDensityTestCacheDirectory=FileNameJoin[{finiteDensityTestDirectory,"coefficient-functions"}];
finiteDensityTestCached=FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,
 finiteDensityTestSources,finiteDensityTestRequest,"CoefficientFunctionDirectory"->finiteDensityTestCacheDirectory];
FTAssert["resumable files contain final explicit coefficient functions for every master and scalar remainder",
 AssociationQ[finiteDensityTestCached] && Length[FileNames["*.wxf",finiteDensityTestCacheDirectory]]===3 &&
 finiteDensityTestCached["Coefficients"]===finiteDensityTestResult["Coefficients"]];
finiteDensityTestResumed=Block[{FeynFacet`ExpandMasterIntegralCoefficient},
 Clear[FeynFacet`ExpandMasterIntegralCoefficient];
 FeynFacet`ExpandMasterIntegralCoefficient[___]:=$Failed;
 FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestTable,
  finiteDensityTestSources,finiteDensityTestRequest,"CoefficientFunctionDirectory"->finiteDensityTestCacheDirectory]];
FTAssert["an identical request resumes without invoking coefficient expansion",
 AssociationQ[finiteDensityTestResumed] && finiteDensityTestResumed["Coefficients"]===finiteDensityTestCached["Coefficients"]];
finiteDensityTestChanged=finiteDensityTestTable;
finiteDensityTestChanged["RemainderTerms"]={finiteDensityTestExact[5/finiteDensityTestEpsilon]};
finiteDensityTestChangedResult=FeynFacet`AssembleFiniteMasterIntegralDensity[finiteDensityTestChanged,
 finiteDensityTestSources,finiteDensityTestRequest,"CoefficientFunctionDirectory"->finiteDensityTestCacheDirectory];
FTAssert["a changed coefficient input receives a distinct resumable function file",
 AssociationQ[finiteDensityTestChangedResult] && Length[FileNames["*.wxf",finiteDensityTestCacheDirectory]]===4 &&
 Expand[finiteDensityTestResolve[finiteDensityTestChangedResult][0]-finiteDensityTestResolved[0]-6]===0];
finiteDensityTestCorruptFile=First[FileNames["*.wxf",finiteDensityTestCacheDirectory]];
finiteDensityTestCorrupt=Import[finiteDensityTestCorruptFile,"WXF"];
finiteDensityTestCorruptExpanded=finiteDensityTestCorrupt["ExpandedCoefficient"];
finiteDensityTestCorruptExpanded["Coefficients"]=Map[#+finiteDensityTestEpsilon&,finiteDensityTestCorruptExpanded["Coefficients"]];
finiteDensityTestCorrupt["ExpandedCoefficient"]=finiteDensityTestCorruptExpanded;
Export[finiteDensityTestCorruptFile,finiteDensityTestCorrupt,"WXF"];
(* Select whichever of the original or changed request owns the deliberately
   corrupted function; every saved function is covered by their union. *)
finiteDensityTestCorruptResults=FeynFacet`AssembleFiniteMasterIntegralDensity[#,finiteDensityTestSources,
 finiteDensityTestRequest,"CoefficientFunctionDirectory"->finiteDensityTestCacheDirectory]& /@
 {finiteDensityTestTable,finiteDensityTestChanged};
FTAssert["a corrupted saved coefficient function is rejected instead of silently reused",
 AnyTrue[finiteDensityTestCorruptResults,MatchQ[#,Failure["SavedCoefficientFunctionInvalid",_Association]]&]];
DeleteDirectory[finiteDensityTestDirectory,DeleteContents->True];

FTReport[];
