(* Exact rational-function cancellation, with no kinematic specialization. *)
BeginPackage["FeynFacet`"];
CancelRationalExpressions::usage =
 "CancelRationalExpressions[expressions,variables] reduces a list of exact rational functions over Q in the declared symbols with FLINT. Analytic prefactors should be kept separate or explicitly represented by independent coefficient-field symbols.";
RationalLaurentCoefficients::usage =
 "RationalLaurentCoefficients[expressions,variables,variable,{low,high}] returns every requested explicit Laurent coefficient using the exact rational recurrence N=D Q over the remaining symbolic coefficient field.";
Begin["`Private`"];
$rationalFunctionBackend=FileNameJoin[{DirectoryName[ExpandFileName[$InputFileName],2],
 "Backends","flint","bin","rational_functions"}];
rationalFunctionRun[expressions_List,variables_List,arguments_List]:=Module[
 {directory,input,output,stream,process,result,context,rules},
 If[expressions==={},Return[{}]];
 If[variables==={}||!VectorQ[variables,MatchQ[#,_Symbol]&]||!DuplicateFreeQ[variables],
  Return[Failure["DistinctRationalFunctionVariablesRequired",<||>]]];
 If[!FileExistsQ[$rationalFunctionBackend],Return[Failure["RationalFunctionBackendNotBuilt",<|
   "BuildScript"->DirectoryName[$rationalFunctionBackend,2]<>"/build_rational_functions.sh"|>]]];
 directory=CreateDirectory[];input=directory<>"/input.wxf";output=directory<>"/output.wl";
 result=CheckAbort[
  stream=OpenWrite[input,BinaryFormat->True];
  BinaryWrite[stream,Normal[BinarySerialize[{variables,Developer`FromPackedArray[expressions]},
    PerformanceGoal->"Speed"]],"Byte"];Close[stream];
  process=RunProcess[Join[{$rationalFunctionBackend,input,output},arguments]];
  If[!AssociationQ[process]||Lookup[process,"ExitCode",-1]=!=0||!FileExistsQ[output],
   Failure["ExactRationalCancellationFailed",<|"Process"->process|>],
   context="FeynFacetRationalRead"<>StringReplace[CreateUUID[],"-"->""]<>"`";
   rules=MapIndexed[Symbol[context<>"x"<>ToString[First[#2]-1]]->#1&,variables];
   result=Block[{$Context=context,$ContextPath={"System`"}},Get[output]]/.rules;
   If[!ListQ[result]||Length[result]=!=Length[expressions],
    Failure["RationalCancellationOutputInvalid",<||>],result]
  ],$Aborted];
 DeleteDirectory[directory,DeleteContents->True];
 If[result===$Aborted,Abort[],result]
];
CancelRationalExpressions[expressions_List,variables_List]:=rationalFunctionRun[expressions,variables,{}];
RationalLaurentCoefficients[expressions_List,variables_List,variable_Symbol,{low_Integer,high_Integer}]:=Module[{index,result},
 If[low>high||!MemberQ[variables,variable],Return[Failure["DeclaredVariableAndLaurentRangeRequired",<||>]]];
 index=First[FirstPosition[variables,variable]]-1;
 result=rationalFunctionRun[expressions,variables,ToString/@{index,low,high}];
 If[FailureQ[result],Return[result]];
 If[!AllTrue[result,ListQ[#]&&Length[#]===high-low+1&&FreeQ[#,variable]&],
  Return[Failure["ExplicitRationalLaurentCoefficientsRequired",<||>]]];
 AssociationThread[Range[low,high],#]&/@result
];
RationalLaurentCoefficients[___]:=Failure["RationalExpressionsVariablesAndLaurentRangeRequired",<||>];
CancelRationalExpressions[___]:=Failure["RationalExpressionListAndVariablesRequired",<||>];
End[];
EndPackage[];
