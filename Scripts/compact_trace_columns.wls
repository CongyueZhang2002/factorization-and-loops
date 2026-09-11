Print["FEYNFACET DRIVER ENTERED"];
(* Generic recovery/replay driver. Production calls this same compaction from
   CoefficientSimplification. Original normalized expressions are retained. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],2];
Get[root<>"/Addon/Load/LoadFACET.wl"];
args=Rest[$ScriptCommandLine];
If[Length[args]<1,
 Print["Usage: compact_trace_columns.wls <traceDirectory> [kernels] [thresholdBytes]"];
 Exit[1]];
directory=ExpandFileName[First[args]];
kernels=If[Length[args]>=2,ToExpression[args[[2]]],Automatic];
threshold=If[Length[args]>=3,ToExpression[args[[3]]],10*2^20];
checkpoint=FeynFacet`Private`reconstructionTraceRecord[directory];
If[!AssociationQ[checkpoint],Print["TRACE CHECKPOINT FAILED"];Exit[1]];
result=FeynFacet`Private`finiteFieldCompactTrace[checkpoint["TraceData"],directory,
 kernels,threshold,30,600];
If[!AssociationQ[result],Print["COMPACTION FAILED ",result];Exit[1]];
Print["COMPACTION COMPLETE ",Total[FileByteCount/@result["OutputFiles"]]," bytes"];
