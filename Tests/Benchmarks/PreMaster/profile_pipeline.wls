#!/usr/bin/env wolframscript
(* Inclusive timings of named upstream operations. Profiling uses a fresh
   kernel and leaves the production source definitions unchanged on disk. *)
$HistoryLength=0;$MaxExtraPrecision=50;SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],4];args=Rest[$ScriptCommandLine];
If[Length[args]=!=2,Print["Usage: profile_pipeline.wls INPUT.wl OUTPUT_DIRECTORY"];Exit[2]];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
input=Get[args[[1]]];output=ExpandFileName[args[[2]]];If[!DirectoryQ[output],CreateDirectory[output,CreateIntermediateDirectories->True]];
profiles=<||>;profileStack={};SetAttributes[profileEvaluation,HoldRest];
profileEvaluation[tag_String,expr_]:=Module[{seconds,value,old},
 AppendTo[profileStack,tag];{seconds,value}=AbsoluteTiming[expr];profileStack=Most[profileStack];old=Lookup[profiles,tag,<|"Calls"->0,"InclusiveSeconds"->0.|>];
 AssociateTo[profiles,tag-><|"Calls"->(old["Calls"]+1),"InclusiveSeconds"->(old["InclusiveSeconds"]+seconds)|>];value];
symbols={FeynFacet`Private`dimensionalShiftNormalizeNumerator,FeynFacet`Private`dimensionalShiftReduceNumerator,FeynFacet`Private`dimensionalShiftSplitNumerator,FeynFacet`Private`dimensionalShiftRaiseToD,FeynFacet`Private`dimensionalShiftRaiseOnce,FeynFacet`Private`dimensionalShiftPreserveCuts,FeynCalc`FCLoopTensorReduce,FeynCalc`FCLoopGLIRaiseDimension,FeynFacet`Private`linearDropZeros,FeynFacet`Private`linearAdd,FeynFacet`Private`linearIntegralSum,FeynFacet`GenerateDiagram,FeynFacet`CollinearFactorizePreIBP,FeynFacet`PartialFraction,FeynFacet`BuildTopologies,FeynFacet`DimensionalShift,FeynFacet`CommonFactorSafe,
 FeynFacet`Private`factorizePair,FeynFacet`Private`collinearContractAmplitude,FeynFacet`Private`convertAmplitudePair,FeynFacet`Private`normalizeProcess,FeynFacet`Private`prepareProcess,
 FeynFacet`Private`reduceCollinearLoopProducts,FeynFacet`Private`checkCompletedPropagators,FeynFacet`Private`safePropagatorData,FeynFacet`Private`topologyPropagatorIndex,
 FeynCalc`Calc,FeynCalc`Trick,FeynCalc`SUNSimplify,FeynCalc`DiracSimplify,FeynCalc`Explicit,FeynCalc`Contract,FeynCalc`EpsEvaluate,FeynCalc`PowerSimplify,FeynCalc`Expand2,FeynCalc`FCLoopToGLI,FeynCalc`FCLoopBasisFindCompletion,
 FeynFacet`Private`CanonicalizePairArtifacts,FeynFacet`Private`KiraSolve,FeynFacet`Private`KiraStreamImport,
 FeynFacet`Private`finiteFieldCoefficientSimplificationCore,FeynFacet`Private`coefficientEnsureKiraStore,FeynFacet`Private`ibpInputData,
 FeynFacet`Private`BuildSimplificationContext,FeynFacet`BuildSimplificationContext,FeynFacet`Private`coefficientCollectTargetRecords,
 FeynFacet`Private`finiteFieldTraceInputs,FeynFacet`Private`finiteFieldNormalizeTarget,FeynFacet`Private`finiteFieldPrepareReductionCoefficient,
 FeynFacet`Private`applyHadronicVariables,FeynFacet`Private`finiteFieldRationalize,FeynFacet`Private`finiteFieldCancel,
 FeynFacet`Private`finiteFieldDescendEntries,FeynFacet`Private`finiteFieldEntryModule,FeynFacet`Private`finiteFieldTraceGrammarViolation,
 FeynFacet`Private`finiteFieldCanonicalizeSignature,FeynFacet`Private`finiteFieldReconstructTrace,FeynFacet`Private`finiteFieldReadReconstruction};
Do[With[{f=symbol,tag=ToString[symbol,InputForm]},
 If[DownValues[f]=!={},DownValues[f]=DownValues[f]/.RuleDelayed[lhs_,rhs_]:>RuleDelayed[lhs,profileEvaluation[tag,rhs]]]],{symbol,symbols}];
write[value_,name_]:=(Put[value,output<>"/"<>name<>".tmp"];RenameFile[output<>"/"<>name<>".tmp",output<>"/"<>name,OverwriteTarget->True]);
rows={};
Switch[input["Mode"],
 "Pairs",card=FeynFacet`ReadProcessCard[FileNameJoin[{root,input["Project"]}],input["Card"]];
 Do[profiles=<||>;setup=Join[card,<|"ForwardAmplitudes"->Join[card["ForwardAmplitudes"],<|"SelectedIndex"->pair[[1]]|>],
  "ConjugateAmplitudes"->Join[card["ConjugateAmplitudes"],<|"SelectedIndex"->pair[[2]]|>]|>];
 {seconds,value}=AbsoluteTiming[TimeConstrained[FeynFacet`CollinearFactorizePreIBP[setup],Lookup[input,"PerPairTimeLimit",600],$Aborted]];
 passed=MatchQ[value,{_,_,_,_,_List}];
 row=<|"Pair"->pair,"Passed"->passed,"ElapsedSeconds"->seconds,"InclusiveTimings"->profiles,"OperationStackAtStop"->profileStack,
  "ResultBytes"->If[passed,ByteCount[value],0],"TopologyCount"->If[passed,Length[Last[value]],0]|>;
 AppendTo[rows,row];write[value,"pair_"<>ToString[pair[[1]]]<>"_"<>ToString[pair[[2]]]<>".wl"];
 write[rows,"profile.wl"];Print["PAIR_PROFILE ",InputForm[row]];If[!passed,Exit[1]],{pair,input["Pairs"]}],
 "Coefficients",profiles=<||>;
 files=Sort[FileNames["F*_C*.wl",FileNameJoin[{input["ReductionDirectory"],"Pairs"}]]];
 {seconds,value}=AbsoluteTiming[FeynFacet`CoefficientSimplification[files,input["ReductionDirectory"]<>"/KiraResult.wl",
  "Threads"->Lookup[input,"Threads",8],"NormalizationKernels"->1]];
 passed=AssociationQ[value];write[<|"Passed"->passed,"ElapsedSeconds"->seconds,"InclusiveTimings"->profiles|>,"profile.wl"];
 If[passed,write[value,"CoefficientResult.wl"]];Print["COEFFICIENT_PROFILE ",seconds," ",passed," ",InputForm[profiles]];
 If[!passed,Exit[1]],_,Print["Unknown profile mode"];Exit[2]];
Print["PREMASTER_PROFILE_PASSED"];
