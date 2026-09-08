#!/usr/bin/env wolframscript
$HistoryLength=0;
densityCheckRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[densityCheckRoot<>"/FeynFacet/Coefficients/DensityValidation.wl"];
densityCheckArguments=Rest[$ScriptCommandLine];
If[Length[densityCheckArguments]=!=2,Print["Expected REQUEST.wl OUTPUT.wxf"];Exit[2]];
densityCheckRequestPath=ExpandFileName[densityCheckArguments[[1]]];densityCheckOutput=ExpandFileName[densityCheckArguments[[2]]];
densityCheckInput=Get[densityCheckRequestPath];
densityCheckResolve[p_String] := ExpandFileName[If[StringStartsQ[p,"/"],p,FileNameJoin[{DirectoryName[densityCheckRequestPath],p}]]];
densityCheckLoad[p_String] := If[ToLowerCase[FileExtension[p]]==="wxf",Import[p,"WXF"],Block[{$Context="Global`",$ContextPath={"System`","Global`"}},Get[p]]];
densityCheckData=densityCheckLoad[densityCheckResolve[densityCheckInput["DensityFile"]]];
densityCheckOrders=densityCheckInput["Request"]["Orders"];
densityCheckColumns=DeleteDuplicates@Flatten[
 Table[First/@Most[ArrayRules[densityCheckData["CoefficientConvolutionMatrices"][q]]],{q,densityCheckOrders}]];
densityCheckIndex=Association@Table[r["Column"]->r,{r,densityCheckData["MasterCoefficientIndex"]}];
densityCheckFamilies=DeleteDuplicates[First[densityCheckIndex[#]["Master"]]&/@densityCheckColumns];
densityCheckBundles=<||>;
Do[
 densityCheckDirectory=densityCheckResolve[Lookup[Lookup[densityCheckInput,"ReferenceDirectories",<||>],family,
  FileNameJoin[{densityCheckInput["ReferenceDirectory"],family}]]];
 AssociateTo[densityCheckBundles,family-><|
  "AMFlow"->densityCheckLoad[densityCheckDirectory<>"/amflow_reference.wxf"],
  "PhysicalEvaluation"->densityCheckLoad[densityCheckDirectory<>"/physical_evaluation.wxf"],
  "ValidationRequest"->densityCheckLoad[densityCheckDirectory<>"/request.wxf"],
  "AMFlowRequest"->densityCheckLoad[densityCheckDirectory<>"/amflow_request.wl"],
  "Comparison"->densityCheckLoad[densityCheckDirectory<>"/comparison.wxf"]|>],
 {family,densityCheckFamilies}];
Print["RETAINED_DENSITY_REFERENCE_CHECK ",<|"Families"->densityCheckFamilies,"Columns"->Length[densityCheckColumns]|>];
densityCheckSeconds=First@AbsoluteTiming[
 densityCheckResult=FeynFacet`CheckFiniteDensityWithRetainedReferences[
  densityCheckData,densityCheckBundles,densityCheckInput["Request"]]];
If[!DirectoryQ[DirectoryName[densityCheckOutput]],CreateDirectory[DirectoryName[densityCheckOutput],CreateIntermediateDirectories->True]];
densityCheckStream=OpenWrite[densityCheckOutput,BinaryFormat->True];
BinaryWrite[densityCheckStream,Normal[BinarySerialize[densityCheckResult,PerformanceGoal->"Size"]],"Byte"];Close[densityCheckStream];
If[Import[densityCheckOutput,"WXF"]=!=densityCheckResult,Print["CHECK_REPORT_ROUNDTRIP_FAILED"];Exit[1]];
If[FailureQ[densityCheckResult],
 Export[densityCheckOutput<>".json",<|"Status"->"Failed","FailureTag"->densityCheckResult[[1]],
  "Details"->ToString[densityCheckResult[[2]],InputForm],"Seconds"->densityCheckSeconds|>,"RawJSON"];
 Print["CHECK_FAILED ",densityCheckResult];Exit[1]];
densityCheckNumericFields={"AMFlowSum","PhysicalSum","AMFlowAbsoluteContributionSum","PhysicalAbsoluteContributionSum",
 "AMFlowNormalizedResidual","PhysicalNormalizedResidual","NormalizedReferenceDifference",
 "AMFlowCancellationConditionNumber","PhysicalCancellationConditionNumber"};
densityCheckSummary=Join[KeyDrop[densityCheckResult,{"Reports","SelectedCoefficientDefinitionIndices"}],<|
 "SelectedCoefficientDefinitionCount"->Length[densityCheckResult["SelectedCoefficientDefinitionIndices"]],
 "Seconds"->densityCheckSeconds,
 "Reports"->Table[Join[
   KeyTake[r,{"EpsilonOrder","TermCount","SymbolicCoefficientExactlyZero","ReferenceAgreementObserved","CancellationObserved"}],
   Association@Table[field->ToString[r[field],InputForm],{field,densityCheckNumericFields}],
   <|"Contributions"->Table[Association@KeyValueMap[#1->ToString[#2,InputForm]&,c],{c,r["Contributions"]}]|>],
  {r,densityCheckResult["Reports"]}]|>];
Export[densityCheckOutput<>".json",densityCheckSummary,"RawJSON"];
Print["RETAINED_DENSITY_CHECK_COMPLETE ",densityCheckSummary];
Exit[If[densityCheckResult["Status"]==="Passed",0,1]];