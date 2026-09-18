#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
(* REQUEST.wl declares PhysicalCoefficientTable, FiniteSolutions and Request.
   The output is a complete finite interior expression or an explicit order failure. *)
$HistoryLength=0;$MaxExtraPrecision=50;
finiteDensityRoot=DirectoryName[ExpandFileName[$InputFileName],3];
finiteDensityArguments=Rest[$ScriptCommandLine];
If[Length[finiteDensityArguments]=!=2,Print["Expected REQUEST.wl OUTPUT.wxf"];Exit[2]];
finiteDensityRequestFile=ExpandFileName[finiteDensityArguments[[1]]];
finiteDensityOutput=ExpandFileName[finiteDensityArguments[[2]]];
Block[{Print},Get[FileNameJoin[{finiteDensityRoot,"Addon","Load","LoadFACET.wl"}]]];
Get[FileNameJoin[{finiteDensityRoot,"FeynFacet","Solution.m"}]];
Get[FileNameJoin[{finiteDensityRoot,"FeynFacet","Coefficients","FiniteDensity.wl"}]];
$PrePrint=.;
finiteDensityInput=FeynFacetRecords`ReadRecord[finiteDensityRequestFile];
If[!AssociationQ[finiteDensityInput]||!AssociationQ[Lookup[finiteDensityInput,"FiniteSolutions",None]]||
 !AssociationQ[Lookup[finiteDensityInput,"Request",None]]||!KeyExistsQ[finiteDensityInput,"PhysicalCoefficientTable"],
 Print["PhysicalCoefficientTable, FiniteSolutions and Request are required"];Exit[2]];
finiteDensityResolve[path_String] := ExpandFileName[If[StringStartsQ[path,"/"],path,
 FileNameJoin[{DirectoryName[finiteDensityRequestFile],path}]]];
finiteDensityResolve[value_] := value;
finiteDensityWrite[value_,path_] := Module[{temporary=path<>".partial",stream,restored,unequalFields,details},
 If[!DirectoryQ[DirectoryName[path]],CreateDirectory[DirectoryName[path],CreateIntermediateDirectories->True]];
 stream=OpenWrite[temporary,BinaryFormat->True];
 BinaryWrite[stream,Normal[BinarySerialize[value,PerformanceGoal->"Size"]],"Byte"];Close[stream];
 restored=Import[temporary,"WXF"];
 If[!FeynFacet`Private`finiteDensitySerializationEquivalentQ[value,restored],
  unequalFields=If[AssociationQ[value]&&AssociationQ[restored],
   Select[Keys[value],Lookup[value,#]=!=Lookup[restored,#,Missing["Absent"]]&],{"WholeRecord"}];
  details=If[AssociationQ[value]&&AssociationQ[restored],Table[
   <|"Field"->key,"OriginalHead"->ToString[Head[value[key]]],"RestoredHead"->ToString[Head[restored[key]]],
    "OriginalBytes"->ByteCount[value[key]],"RestoredBytes"->ByteCount[restored[key]],
    "FirstUnequalListPosition"->If[ListQ[value[key]]&&ListQ[restored[key]]&&Length[value[key]]===Length[restored[key]],
      SelectFirst[Range[Length[value[key]]],value[key][[#]]=!=restored[key][[#]]&,None],None]|>,
   {key,unequalFields}],{}];
  Export[path<>".roundtrip_failure.json",<|"UnequalFields"->unequalFields,"Details"->details|>,"RawJSON"];
  Print["FINITE_DENSITY_SERIALIZATION_FAILED ",path," fields ",unequalFields];Exit[1]];
 RenameFile[temporary,path,OverwriteTarget->True]
];
finiteDensityCompute[]:=FeynFacet`AssembleFiniteMasterIntegralDensity[
  finiteDensityResolve[finiteDensityInput["PhysicalCoefficientTable"]],
  Map[finiteDensityResolve,finiteDensityInput["FiniteSolutions"]],finiteDensityInput["Request"],"Verbose"->True,
  "CoefficientWorkers"->Lookup[finiteDensityInput,"CoefficientWorkers",1],
  "CoefficientFunctionDirectory"->finiteDensityResolve[Lookup[finiteDensityInput,"CoefficientFunctionDirectory",None]]];
finiteDensityAudit=None;
finiteDensityElapsed=First@AbsoluteTiming[
 If[TrueQ[Lookup[finiteDensityInput,"EpsilonRemainderChecks",False]],
  finiteDensityChecked=FeynFacet`WithEpsilonRemainderChecks[finiteDensityCompute[],
    "TruncationOrderShift"->Lookup[finiteDensityInput,"TruncationOrderShift",0]];
  finiteDensityAudit=finiteDensityChecked["EpsilonRemainderAudit"];finiteDensityResult=finiteDensityChecked["Result"],
  finiteDensityResult=finiteDensityCompute[]]];
If[AssociationQ[finiteDensityAudit],finiteDensityWrite[finiteDensityAudit,finiteDensityOutput<>".epsilon_audit.wxf"]];
If[FailureQ[finiteDensityResult],
 finiteDensityWrite[finiteDensityResult,finiteDensityOutput<>".failure.wxf"];
 finiteDensityReport=<|"Status"->"Failed","FailureTag"->ToString[finiteDensityResult[[1]]],
  "Stage"->Lookup[finiteDensityResult[[2]],"Stage","Unknown"],
  "Master"->ToString[Lookup[finiteDensityResult[[2]],"Master","NotApplicable"],InputForm],
  "MissingMasterCoefficientCount"->Length[Lookup[finiteDensityResult[[2]],"MissingMasterCoefficients",{}]],
  "MissingCoefficientOrderCount"->Length[Lookup[finiteDensityResult[[2]],"MissingCoefficientOrders",{}]],
  "Seconds"->finiteDensityElapsed|>;
 Export[finiteDensityOutput<>".json",finiteDensityReport,"RawJSON"];
 Print["FINITE_DENSITY_FAILED ",finiteDensityReport];Exit[1]];
finiteDensityFormalVariables=DeleteDuplicates@Join[
 Lookup[finiteDensityResult["KernelDefinitions"],"Parameter",{}],
 Lookup[finiteDensityResult["IntegralDefinitions"],"IntegrationVariable",{}],
 Lookup[finiteDensityResult["IntegralDefinitions"],"UpperLimitVariable",{}]];
finiteDensityFormalReport=<|"DistinctCount"->Length[finiteDensityFormalVariables],
 "FirstSymbols"->(ToString[#,InputForm]&/@Take[finiteDensityFormalVariables,UpTo[20]]),
 "KinematicCollisions"->(ToString[#,InputForm]&/@Intersection[finiteDensityFormalVariables,finiteDensityResult["KinematicVariables"]])|>;
Print["FINITE_DENSITY_FORMAL_VARIABLES ",finiteDensityFormalReport];
finiteDensityExactZeroOrders=Keys@Select[finiteDensityResult["Coefficients"],#===0&];
Print["FINITE_DENSITY_EXACT_ZERO_ORDERS ",finiteDensityExactZeroOrders];
finiteDensityWrite[finiteDensityResult,finiteDensityOutput];
finiteDensityWrite[KeyTake[finiteDensityResult,{"DataType","Status","DimensionalRegulator","KinematicVariables",
 "EpsilonOrderRange","MasterCount","SolutionCount","MasterOrderRequirements","MasterCoefficientIndex",
 "CoefficientFunctionIndex","DefinitionScopes","SharedBoundarySources","SourceCoefficientFile","CoefficientFunctionDirectory","EpsilonIndependentPrefactor"}],finiteDensityOutput<>".index.wxf"];
finiteDensityReport=<|"Status"->finiteDensityResult["Status"],"Output"->finiteDensityOutput,
 "MasterCount"->finiteDensityResult["MasterCount"],"SolutionCount"->finiteDensityResult["SolutionCount"],
 "MasterCoefficientCount"->Length[finiteDensityResult["MasterCoefficientIndex"]],
 "CoefficientFunctionCount"->Length[finiteDensityResult["CoefficientFunctionIndex"]],
 "EpsilonOrderRange"->finiteDensityResult["EpsilonOrderRange"],
 "AlgebraicDefinitionCount"->Length[finiteDensityResult["AlgebraicDefinitions"]],
 "IntegralDefinitionCount"->Length[finiteDensityResult["IntegralDefinitions"]],
 "KernelDefinitionCount"->Length[finiteDensityResult["KernelDefinitions"]],
 "SharedBoundarySourceCount"->Length[finiteDensityResult["SharedBoundarySources"]],
 "UnknownInitialConstantCount"->finiteDensityResult["UnknownInitialConstantCount"],
 "EndpointSubtractionsApplied"->False,"FormalVariables"->finiteDensityFormalReport,"ExactZeroEpsilonOrders"->finiteDensityExactZeroOrders,"Seconds"->finiteDensityElapsed,
 "CoefficientWorkers"->Lookup[finiteDensityInput,"CoefficientWorkers",1],
 "EpsilonRemainderAudit"->If[AssociationQ[finiteDensityAudit],KeyTake[finiteDensityAudit,{"Status","ChecksByStage"}],None]|>;
Export[finiteDensityOutput<>".json",finiteDensityReport,"RawJSON"];
Print["FINITE_DENSITY_COMPLETE ",finiteDensityReport];Exit[0];
