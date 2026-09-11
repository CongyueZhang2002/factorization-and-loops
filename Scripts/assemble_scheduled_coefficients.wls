Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[!MemberQ[{3,4},Length[args]],Print["Expected TRACE_DIRECTORY PLAN.wl RESULT.wl CURRENT_ORDER_INPUTS.wl or finalize-candidate CANDIDATE.wxf RESULT.wl"];Exit[2]];
resultFile=ExpandFileName[args[[3]]];started=AbsoluteTime[];
If[args[[1]]==="finalize-candidate",
 candidate=Import[ExpandFileName[args[[2]]],"WXF"];
 result=FeynFacet`ReadMasterIntegralCoefficients[candidate];
 If[!AssociationQ[result],Print["CANDIDATE FORMAT FAILED ",result];Exit[1]];
 nativeRecords=result["FiniteFieldReconstruction"];
 If[!AssociationQ[nativeRecords]||
   FeynFacet`Private`coefficientFileHashes[nativeRecords["ResultFiles"]]=!=nativeRecords["ResultFileHashes"],
  Print["CANDIDATE RECONSTRUCTION BINDING FAILED"];Exit[1]],
directory=ExpandFileName[args[[1]]];plan=FeynFacet`FamilyArtifactRead[ExpandFileName[args[[2]]]];
If[!AssociationQ[plan]||!TrueQ[Lookup[plan,"ResumeOnly",False]],
 Print["COMPLETED JOB PLAN REQUIRED"];Exit[1]];
inputs=FeynFacet`Private`reconstructionInputs[directory,<|"CoefficientSetup"->Automatic|>];
If[!AssociationQ[inputs],Print["SOURCE INPUTS FAILED ",inputs];Exit[1]];
data=FeynFacet`Private`finiteFieldCompactTrace[inputs["TraceData"],directory,1,10*2^20,30,600];
If[!AssociationQ[data],Print["COMPACTION CHECKPOINT FAILED"];Exit[1]];
native=If[KeyExistsQ[data,"Compaction"],data["Compaction"]["Directory"],directory];
executable=FeynFacet`Private`finiteFieldResolveExecutable[Automatic];
threads=FeynFacet`Private`finiteFieldThreadCount[Automatic];
orderInputs=If[Length[args]===4,FeynFacet`FamilyArtifactRead[ExpandFileName[args[[4]]]],None];
raw=FeynFacet`Private`finiteFieldExecuteCoefficientPlan[inputs,data,native,executable,
 <|"Threads"->threads,"ReconstructionOrderInputs"->orderInputs|>,plan];
If[!AssociationQ[raw],Print["SCHEDULED ASSEMBLY FAILED ",raw];Exit[1]];
result=FeynFacet`Private`coefficientResultFromReconstruction[raw];
If[!AssociationQ[result],Print["FINAL FORMAT FAILED ",result];Exit[1]];
];
result=Append[result,"CoefficientResultFile"->resultFile];
candidateFile=resultFile<>".assembled.wxf";
If[Export[candidateFile,result,"WXF",PerformanceGoal->"Size"]===$Failed,
 Print["CANDIDATE WRITE FAILED"];Exit[1]];
Print["ASSEMBLED COEFFICIENT CANDIDATE ",candidateFile];
If[!FeynFacet`Private`coefficientWriteFinalResult[result,resultFile],Print["FINAL WRITE FAILED"];Exit[1]];
summary=<|"Status"->"Complete","MasterCount"->Length[result["Masters"]],
 "ExactTermCount"->Count[Flatten[Lookup[result["Masters"],"Terms"],1],a_Association/;a["Representation"]==="Exact"],
 "FiniteLaurentTermCount"->Count[Flatten[Lookup[result["Masters"],"Terms"],1],a_Association/;a["Representation"]==="LaurentSeries"],
 "ExecutionMode"->If[args[[1]]==="finalize-candidate","FinalizeCandidate","AssembleCompletedJobs"],
 "ElapsedSeconds"->N[AbsoluteTime[]-started],"ResultFile"->resultFile,"ResultBytes"->FileByteCount[resultFile]|>;
Export[resultFile<>".summary.json",summary,"RawJSON"];
Print["SCHEDULED COEFFICIENT ASSEMBLY COMPLETE ",summary];
