#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
subtractionRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[subtractionRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
subtractionArgs=Rest[$ScriptCommandLine];
If[Length[subtractionArgs]=!=2,Print["Expected INPUT_REQUEST.wl OUTPUT.wxf"];Exit[2]];
subtractionRead[x_]:=If[StringQ[x],If[ToLowerCase[FileExtension[x]]==="wxf",Import[x,"WXF"],FeynFacetRecords`ReadRecord[x]],x];
subtractionInput=subtractionRead[First[subtractionArgs]];
If[!AssociationQ[subtractionInput]||!AssociationQ[Lookup[subtractionInput,"EndpointSolutions",None]],
 Print["EndpointSubtractionRequestRequired"];Exit[2]];
subtractionFormat=Lookup[subtractionInput,"ResultFormat","PartonicResult"];
If[!MemberQ[{"PartonicResult","EndpointDensity"},subtractionFormat]||
 !AssociationQ[Lookup[subtractionInput,"ResultMetadata",None]],
 Print["Explicit ResultMetadata and a supported ResultFormat are required"];Exit[2]];
subtractionInterior=subtractionRead[subtractionInput["InteriorDensity"]];
subtractionEndpoints=Map[subtractionRead,subtractionInput["EndpointSolutions"]];
subtractionCompute[]:=AssembleEndpointSubtractedDensity[subtractionInterior,subtractionEndpoints,subtractionInput["Request"]];
subtractionAudit=None;
subtractionSeconds=First[AbsoluteTiming[
 If[TrueQ[Lookup[subtractionInput,"EpsilonRemainderChecks",False]],
  subtractionChecked=WithEpsilonRemainderChecks[subtractionCompute[],
    "TruncationOrderShift"->Lookup[subtractionInput,"TruncationOrderShift",0]];
  subtractionAudit=subtractionChecked["EpsilonRemainderAudit"];subtractionResult=subtractionChecked["Result"],
  subtractionResult=subtractionCompute[]]]];
If[AssociationQ[subtractionAudit],
 subtractionAuditFile=ExpandFileName[Last[subtractionArgs]]<>".epsilon_audit.wxf";
 If[!DirectoryQ[DirectoryName[subtractionAuditFile]],CreateDirectory[DirectoryName[subtractionAuditFile],CreateIntermediateDirectories->True]];
 Export[subtractionAuditFile,subtractionAudit,"WXF"]];
If[FailureQ[subtractionResult]||!AssociationQ[subtractionResult],Print[subtractionResult];Exit[1]];
subtractionColorSeconds=0;
If[KeyExistsQ[subtractionInput,"ColorDecomposition"],
 subtractionColorSeconds=First[AbsoluteTiming[
  subtractionResult=FeynFacet`CollectDistributionColorFactors[subtractionResult,subtractionInput["ColorDecomposition"]]]];
 If[FailureQ[subtractionResult],Print[subtractionResult];Exit[1]]];
subtractionTermCounts=<|"DeltaTermCount"->Length[subtractionResult["DeltaTerms"]],
 "PlusTermCount"->Length[subtractionResult["PlusTerms"]]|>;
subtractionCompactionSeconds=0;
If[KeyExistsQ[subtractionResult,"ColorComponents"]&&TrueQ[Lookup[subtractionInput,"CompactOutput",True]],
 subtractionCompactionSeconds=First[AbsoluteTiming[
  subtractionResult=FeynFacet`CompactFiniteDistributionResult[subtractionResult]]];
 If[FailureQ[subtractionResult],Print[subtractionResult];Exit[1]]];
(* Generalized endpoint distributions remain explicit when requested.
   This does not identify them with the standard delta/logarithmic-plus basis. *)
subtractionResult=Switch[subtractionFormat,
 "PartonicResult",FeynFacet`PartonicResultFromEndpointDensity[subtractionResult,subtractionInput["ResultMetadata"]],
 "EndpointDensity",Join[subtractionResult,<|"ResultIdentity"->subtractionInput["ResultMetadata"]|>]];
If[FailureQ[subtractionResult],Print[subtractionResult];Exit[1]];
subtractionFile=ExpandFileName[Last[subtractionArgs]];
If[!DirectoryQ[DirectoryName[subtractionFile]],CreateDirectory[DirectoryName[subtractionFile],CreateIntermediateDirectories->True]];
subtractionTemporary=subtractionFile<>".partial";
If[Export[subtractionTemporary,subtractionResult,"WXF",PerformanceGoal->"Size"]===$Failed,Print["EndpointDensityWriteFailed"];Exit[1]];
If[Import[subtractionTemporary,"WXF"]=!=subtractionResult,Print["EndpointDensityReadBackMismatch"];Exit[1]];
RenameFile[subtractionTemporary,subtractionFile,OverwriteTarget->True];
subtractionSummary=Join[KeyTake[subtractionResult,{"Format","DataType","Status","EpsilonRange","EpsilonOrderRange","MasterCount","UnknownInitialConstantCount"}],
 <|"ResultFormat"->subtractionFormat,"AssemblySeconds"->subtractionSeconds,"ColorCollectionSeconds"->subtractionColorSeconds,"CompactionAndVerificationSeconds"->subtractionCompactionSeconds,
 "ComputationTimings"->Lookup[subtractionResult,"ComputationTimings",<||>],
 "EpsilonRemainderAudit"->If[AssociationQ[subtractionAudit],KeyTake[subtractionAudit,
   {"Status","ChecksByStage","DistinctMultiplierChecks","RepeatedMultiplierChecksReused"}],None],
 "ColorComponentCount"->Length[Lookup[subtractionResult,"ColorComponents",{}]],
 "OutputBytes"->FileByteCount[subtractionFile],
 "DeltaTermCount"->subtractionTermCounts["DeltaTermCount"],"PlusTermCount"->subtractionTermCounts["PlusTermCount"],
 "AlgebraicDefinitionCount"->Length[subtractionResult["AlgebraicDefinitions"]],
 "IntegralDefinitionCount"->Length[subtractionResult["IntegralDefinitions"]],
 "KernelDefinitionCount"->Length[subtractionResult["KernelDefinitions"]]|>];
Export[subtractionFile<>".summary.json",subtractionSummary,"RawJSON"];
Print["PASS ",subtractionSummary];Exit[0];
