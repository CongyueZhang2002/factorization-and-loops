(* Reuse only complete sampled auxiliary systems with identical mathematical
   inputs and numerical settings. No production DE or boundary enters this cache. *)
BeginPackage["FeynFacetAMFlowRuntime`"];
Begin["`Private`"];
amflowSystemSnapshot[file_String,requireFresh_:False] := Module[
 {script=ExpandFileName[file],folder,source,gets,solver,inputs,output,values,eps,
  template,files,bytes,basis,expectedKeys,dependencies,finiteNumberQ},
 If[FileNameTake[script]=!="solution.wl"||!FileExistsQ[script],Return[None]];
 folder=DirectoryName[script];source=ReadString[script];
 (* This is the upstream quadratic-AMF script format. Other scripts execute
    normally until a dependency specification is supplied for their format. *)
 gets=StringCases[source,RegularExpression["Get\\[\"([^\"]+)\"\\]"]:>"$1"];
 inputs={"basischange","masters","diffeq","boundary","direction","epslist","boundarymi","bpattern"};
 solver=Select[gets,StringEndsQ[#,"/DESolver.m"]&];
 If[Length[solver]=!=1||Sort[Complement[gets,solver]]=!=Sort[inputs]||!StringContainsQ[source,"SetDefaultOptions[]"]||
   !StringContainsQ[source,"Put[Thread[Keys[basischange[[2]]] -> Transpose[results]], \"solution\"]"],Return[None]];
 dependencies=Join[inputs,{"config","globalconfig","preferred"}];
 output=folder<>"/solution";files=FileNameJoin[{folder,#}]&/@dependencies;
 If[!And@@(FileExistsQ/@Join[{output,First[solver]},files]),Return[None]];
 If[TrueQ[requireFresh]&&AbsoluteTime[FileDate[output]]<Max[AbsoluteTime[FileDate[#]]&/@Prepend[files,script]],Return[None]];
 eps=Quiet[Get[folder<>"/epslist"]];values=Quiet[Get[output]];basis=Quiet[Get[folder<>"/basischange"]];
 finiteNumberQ[z_]:=NumberQ[z]&&FreeQ[z,Indeterminate|_DirectedInfinity|System`Overflow[]|System`Underflow[]];
 If[!MatchQ[basis,{_,_List|_Association}],Return[None]];expectedKeys=Keys[basis[[2]]];
 If[!ListQ[eps]||eps==={}||!VectorQ[eps,finiteNumberQ]||!MatchQ[values,{_Rule..}]||Keys[values]=!=expectedKeys||
   !DuplicateFreeQ[Keys[values]]||!AllTrue[Values[values],ListQ[#]&&Length[#]===Length[eps]&&VectorQ[#,finiteNumberQ]&],Return[None]];
 template=StringReplace[source,{First[solver]->"UPSTREAM_DESOLVER",
   "\"Solver\" -> \"MMA\""->"\"Solver\" -> BACKEND",
   "\"Solver\" -> \"CPP\""->"\"Solver\" -> BACKEND"}];
 bytes[path_] := ByteArray[BinaryReadList[path]];
 <|"Version"->1,"ScriptTemplate"->template,
   "Backend"->If[StringContainsQ[source,"\"Solver\" -> \"CPP\""],"CPP","MMA"],"SolverSource"->bytes[First[solver]],
   "Inputs"->AssociationThread[dependencies,bytes/@files],"Output"->bytes[output]|>
];
writeAMFlowSystemCache[file_String] := Module[{snapshot=amflowSystemSnapshot[file,True],path=file<>".complete.wxf"},
 If[!AssociationQ[snapshot],Return[False]];
 Export[path<>".tmp",snapshot,"WXF"];RenameFile[path<>".tmp",path,OverwriteTarget->True];True
];
reuseAMFlowSystemCache[file_String] := Module[{path=file<>".complete.wxf",saved,current},
 If[!FileExistsQ[path],Return[False]];
 saved=Quiet[Import[path,"WXF"]];If[!AssociationQ[saved],Return[False]];
 current=amflowSystemSnapshot[file];AssociationQ[current]&&KeyDrop[current,"Backend"]===KeyDrop[saved,"Backend"]
];
indexCompletedAMFlowSystems[folder_String] := Association@Table[
 file->writeAMFlowSystemCache[file],{file,FileNames["solution.wl",folder,Infinity]}];
End[];EndPackage[];
