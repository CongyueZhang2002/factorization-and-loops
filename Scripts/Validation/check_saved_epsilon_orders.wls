#!/usr/bin/env wolframscript
(* Read-only stage-3 or stage-4 audit. No DE or integration calls. *)
$HistoryLength=0;$MaxExtraPrecision=50;
auditRoot=DirectoryName[ExpandFileName[$InputFileName],3];auditArgs=Rest[$ScriptCommandLine];
If[Length[auditArgs]=!=2,Print["Expected MANIFEST.wl REPORT.wxf"];Exit[2]];
auditInputFile=ExpandFileName[First[auditArgs]];auditOutput=ExpandFileName[Last[auditArgs]];
Block[{Print},Get[auditRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
auditReadFiles={};auditBaseDirectory=DirectoryName[auditInputFile];
auditRead[file_String]:=Module[{path=ExpandFileName[If[StringStartsQ[file,"/"]||StringMatchQ[file,LetterCharacter~~":"~~__],file,FileNameJoin[{auditBaseDirectory,file}]]]},AppendTo[auditReadFiles,path];
 If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],FeynFacetRecords`ReadRecord[path]]];
auditRead[value_]:=value;
auditInput=auditRead[auditInputFile];
If[!AssociationQ[auditInput],Print["An audit manifest association is required."];Exit[2]];
auditOptions={"TruncationOrderShift"->Lookup[auditInput,"TruncationOrderShift",0],
 "TimeLimitPerCheck"->Lookup[auditInput,"TimeLimitPerCheck",10]};
Switch[Lookup[auditInput,"Stage",None],
 3,auditMap=auditRead[auditInput["Reduction"]];auditValues=Map[auditRead,auditInput["EvaluatedBoundaryIntegrals"]];
   {auditSeconds,auditResult}=AbsoluteTiming[CheckBoundaryIntegralEpsilonRemainders[
     auditMap,auditInput["RequestedAmplitudeCoefficients"],auditValues,Sequence@@auditOptions]],
 4,auditAssemblyFile=auditInput["AssemblyInput"];auditAssembly=auditRead[auditAssemblyFile];
   If[StringQ[auditAssemblyFile],auditBaseDirectory=DirectoryName[Last[auditReadFiles]]];
   auditInterior=auditRead[auditAssembly["InteriorDensity"]];
   auditEndpoints=Map[auditRead,auditAssembly["EndpointSolutions"]];
   {auditSeconds,auditResult}=AbsoluteTiming[CheckStage4EpsilonRemainders[
     auditInterior,auditEndpoints,auditAssembly["Request"],Sequence@@auditOptions]],
 _,Print["Stage must be 3 or 4."];Exit[2]];
If[!AssociationQ[auditResult],Print[auditResult];Exit[1]];
If[MemberQ[auditReadFiles,auditOutput],Print["The report must be distinct from every input file."];Exit[2]];
If[!DirectoryQ[DirectoryName[auditOutput]],CreateDirectory[DirectoryName[auditOutput],CreateIntermediateDirectories->True]];
auditResult=Join[auditResult,<|"CheckSecondsExcludingLoading"->auditSeconds|>];
Export[auditOutput<>".partial",auditResult,"WXF"];
If[Import[auditOutput<>".partial","WXF"]=!=auditResult,Print["Audit report round trip failed."];Exit[1]];
RenameFile[auditOutput<>".partial",auditOutput,OverwriteTarget->True];
auditSummary=Join[KeyTake[auditResult["EpsilonRemainderAudit"],
 {"Status","ChecksByStage","DistinctMultiplierChecks","RepeatedMultiplierChecksReused"}],
 <|"CheckSecondsExcludingLoading"->auditSeconds,"Stage"->auditInput["Stage"],
   "Result"->ToString[auditResult["Result"],InputForm]|>];
Export[auditOutput<>".json",auditSummary,"RawJSON"];Print[auditSummary];
Exit[If[auditSummary["Status"]==="Passed",0,1]];
