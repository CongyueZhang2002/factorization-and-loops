(* AMFlow performs reductions in its parent kernel, but solves DEs in a
   separate Wolfram process. Release only worker kernels created by this
   invocation before launching that process, so they do not occupy its licenses. *)
(* Keep the execution scope outside contexts reset by FeynFacet.m. *)
Get[FileNameJoin[{DirectoryName[$InputFileName],"AMFlowSystemCache.wl"}]];
(* BeginPackage excludes caller Global names while this file is parsed again
   from an isolated script. Plain Begin would bind colliding local names. *)
BeginPackage["FeynFacetAMFlowRuntime`"];
Begin["`Private`"];
selectAMFlowRuntime[request_Association] := Module[
 {source=ExpandFileName[request["AMFlowPath"]],backend=Lookup[request,"AMFlowDESolver",Automatic],
  candidate,sameSource,native},
 If[!MemberQ[{Automatic,"MMA","CPP"},backend],Return[Failure["UnsupportedAMFlowDESolver",<|"Backend"->backend|>]]];
 If[backend==="MMA",Return[<|"AMFlowPath"->source,"AMFlowDESolver"->"MMA"|>]];
 If[FileExistsQ[FileNameJoin[{source,"diffeq_solver","link"}]],
  Return[<|"AMFlowPath"->source,"AMFlowDESolver"->"CPP"|>]];
 candidate=Lookup[request,"AMFlowNativePath",FileNameJoin[{DirectoryName[source],"AMFlowNative"}]];
 native=StringQ[candidate]&&FileExistsQ[FileNameJoin[{candidate,"diffeq_solver","link"}]];
 sameSource=If[native,AllTrue[{"AMFlow.m","diffeq_solver/DESolver.m"},Function[name,
   FileExistsQ[FileNameJoin[{source,name}]]&&FileExistsQ[FileNameJoin[{candidate,name}]]&&
   BinaryReadList[FileNameJoin[{source,name}]]===BinaryReadList[FileNameJoin[{candidate,name}]]]],False];
 If[sameSource,Return[<|"AMFlowPath"->ExpandFileName[candidate],"AMFlowDESolver"->"CPP"|>]];
 If[backend==="CPP",Failure["MatchingAMFlowNativeRuntimeUnavailable",<|"SourceDirectory"->source,"NativeDirectory"->candidate|>],
  <|"AMFlowPath"->source,"AMFlowDESolver"->"MMA"|>]
];
amflowScriptOwnedNames[] := Block[{$Context="System`",$ContextPath={},$ContextAliases},
 DeleteDuplicates@Flatten[System`Names[#<>"*"]&/@Select[Contexts[],
  StringStartsQ[#,"Global`"]||StringStartsQ[#,"DESolver`"]&]]];
amflowClearScriptSymbol[name_String] := ToExpression[name,InputForm,
 Function[s,Unprotect[s];Clear[s];Attributes[s]={};Options[s]={};DefaultValues[s]={};Messages[s]={},HoldAllComplete]];
(* Generated AMFlow solver scripts normally run in a fresh main kernel.
   A family subkernel can run them locally, provided their Global/DESolver
   definitions, process directory and numerical settings are fully scoped. *)
runIsolatedWolframScript[file_String,arguments_List,log_:None] := Module[
 {script=ExpandFileName[file],before,directory=Directory[],directories=DirectoryStack[],held,stream=None,
  code,scriptCode,usedSolver=None,nativeLinkUsed=False,started=AbsoluteTime[],added,initialLinks=Links[]},
 If[!FileExistsQ[script],Return[<|"ExitCode"->66,"ElapsedSeconds"->0,"MissingScript"->script|>]];
 before=amflowScriptOwnedNames[];
 held=ToExpression["{"<>StringRiffle[Join[before,{"System`Exit","System`Quit"}],","]<>"}",InputForm,HoldComplete];
 Internal`WithLocalSettings[
  If[StringQ[log],stream=OpenWrite[log]],
  code=held/.HoldComplete[symbols_List]:>Internal`InheritedBlock[symbols,
   (* ClearAll discards InheritedBlock's saved definitions on Wolfram 14.2.
      Clear and explicit attribute/option assignments preserve restoration. *)
   Scan[amflowClearScriptSymbol,before];
   Unprotect[Exit,Quit];Clear[Exit,Quit];
   Exit[c_:0]:=Throw[c,"FeynFacetIsolatedScriptExit"];
   Quit[c_:0]:=Throw[c,"FeynFacetIsolatedScriptExit"];
   Protect[Exit,Quit];
   Internal`WithLocalSettings[Null,
   Block[{$Context="Global`",$ContextPath={"System`","Global`"},$ContextAliases,
     $Packages=Select[$Packages,!StringStartsQ[#,"DESolver`"]&],
     $ScriptCommandLine=Prepend[arguments,script],$HistoryLength=0,
     $MinPrecision=0,$MaxPrecision=Infinity,$MaxExtraPrecision=50,
     $RecursionLimit=4096,$IterationLimit=Infinity,$Assumptions=True,
     $Pre,$Post,$PrePrint,$PreRead,$Epilog,$Path=$Path,
     $Output=If[stream===None,$Output,{stream}],$Messages=If[stream===None,$Messages,{stream}]},
    scriptCode=CheckAbort[Catch[If[Get[script]===$Failed,1,0],"FeynFacetIsolatedScriptExit"],130];
    If[ValueQ[DESolver`Private`Solver],usedSolver=DESolver`Private`Solver];
    nativeLinkUsed=usedSolver==="CPP"&&Head[DESolver`Private`DESolverLink[$KernelID]]===LinkObject&&
      MemberQ[Complement[Links[],initialLinks],DESolver`Private`DESolverLink[$KernelID]];
    scriptCode],
   (* Uninstall also removes definitions. Do this inside InheritedBlock,
      before restoring the caller's localized DESolver symbols. *)
   Scan[Quiet[Uninstall[#]]&,Complement[Links[],initialLinks]]]],
  While[Length[DirectoryStack[]]>Length[directories],ResetDirectory[]];
  If[Directory[]=!=directory||DirectoryStack[]=!=directories,code=70];
  added=Complement[amflowScriptOwnedNames[],before];
  If[added=!={},Quiet[Remove[Evaluate[Sequence@@added]],{Remove::rmnsm,Remove::relex}]];
  If[stream=!=None,Close[stream]]];
 Join[<|"ExitCode"->If[IntegerQ[code],code,1],"ElapsedSeconds"->AbsoluteTime[]-started|>,
  If[MemberQ[{"MMA","CPP"},usedSolver],<|"DESolver"->usedSolver,"NativeLinkUsed"->nativeLinkUsed|>,<||>]]
];
SetAttributes[withAMFlowKernelRelease,HoldAll];
withAMFlowKernelRelease[expression_,inProcess_:False,requiredSolver_:Automatic,reuseSystems_:False] := Module[
 {initial=Kernels[],definitions=DownValues[AMFlow`RunCommand],
  options=Options[AMFlow`RunCommand],attributes=Attributes[AMFlow`RunCommand],
  dispatcher=Unique["FeynFacetAMFlowRuntime`Private`amflowRunCommand"],remaining,inline=TrueQ[inProcess]},
 Internal`WithLocalSettings[
  With[{saved=dispatcher},
   Options[saved]=options;Attributes[saved]=attributes;
   DownValues[saved]=definitions/.AMFlow`RunCommand->saved],
  With[{saved=dispatcher},Internal`InheritedBlock[{AMFlow`RunCommand},
   Unprotect[AMFlow`RunCommand];Clear[AMFlow`RunCommand];
   Options[AMFlow`RunCommand]=options;Attributes[AMFlow`RunCommand]=attributes;
   AMFlow`RunCommand[command_,opts:OptionsPattern[]] := Module[{owned,script,execution,log,directory,wolframCommand},
    wolframCommand=ListQ[command]&&Length[command]>0&&StringQ[First[command]]&&
      MemberQ[{"WolframKernel","WolframKernel.exe","MathKernel","math","wolfram"},FileNameTake[First[command]]];
    If[inline&&wolframCommand&&(!MemberQ[command,"-script"]||Last[command]==="-script"),
      Print["Unsupported Wolfram command in family worker: ",command];Abort[]];
    If[wolframCommand&&MemberQ[command,"-script"],
      script=command[[First@FirstPosition[command,"-script"]+1]];
      directory=OptionValue[ProcessDirectory];
      If[StringQ[directory]&&!StringStartsQ[script,"/"],script=FileNameJoin[{directory,script}]];
      If[TrueQ[reuseSystems]&&reuseAMFlowSystemCache[script],
       Print["AMFLOW reused complete auxiliary system: ",DirectoryName[script]];Return[0.]];
     If[inline,
      log=OptionValue["log"];
      Print["AMFLOW local Wolfram script: ",script];
      execution=runIsolatedWolframScript[script,{},If[StringQ[log],log<>".out",None]];
      If[KeyExistsQ[execution,"DESolver"],Print["AMFLOW completed script: ",execution]];
      If[requiredSolver==="CPP"&&KeyExistsQ[execution,"DESolver"]&&
        (execution["DESolver"]=!="CPP"||!TrueQ[execution["NativeLinkUsed"]]),
       Print["Requested native AMFlow script did not use its own native link: ",execution];Abort[]];
      If[execution["ExitCode"]=!=0,Print["AMFlow Wolfram script failed: ",execution];Abort[]];
      If[TrueQ[reuseSystems],writeAMFlowSystemCache[script]];
      Return[execution["ElapsedSeconds"]]];
     owned=Complement[Kernels[],initial];
     If[owned=!={},CloseKernels[owned];
      Print["AMFLOW released ",Length[owned]," parent worker kernels before Wolfram subprocess."]]];
    execution=saved[command,opts];
    If[TrueQ[reuseSystems]&&StringQ[script],writeAMFlowSystemCache[script]];
    execution];
   expression]],
  remaining=Complement[Kernels[],initial];If[remaining=!={},CloseKernels[remaining]];
  Remove[Evaluate[dispatcher]]]
];
End[];EndPackage[];
FeynFacet`Private`runIsolatedWolframScript[FeynFacetAMFlowRuntime`Private`arguments___] :=
 FeynFacetAMFlowRuntime`Private`runIsolatedWolframScript[FeynFacetAMFlowRuntime`Private`arguments];
SetAttributes[FeynFacet`Private`withAMFlowKernelRelease,HoldAll];
FeynFacet`Private`withAMFlowKernelRelease[FeynFacetAMFlowRuntime`Private`arguments___] :=
 FeynFacetAMFlowRuntime`Private`withAMFlowKernelRelease[FeynFacetAMFlowRuntime`Private`arguments];
