(* Exact rational-function cancellation, with no kinematic specialization. *)
BeginPackage["FeynFacet`"];
CancelRationalExpressions::usage =
 "CancelRationalExpressions[expressions,variables] reduces a list of exact rational functions over Q in the declared symbols with FLINT. Analytic prefactors should be kept separate or explicitly represented by independent coefficient-field symbols.";
RationalLaurentCoefficients::usage =
 "RationalLaurentCoefficients[expressions,variables,variable,{low,high}] returns every requested explicit Laurent coefficient using the exact rational recurrence N=D Q over the remaining symbolic coefficient field.";
CancelRationalCoefficients::usage =
 "CancelRationalCoefficients[expressions] cancels exact rational coefficient expressions with FLINT, representing their analytic prefactors by independent symbols after exact integer-power identities. It does not specialize any kinematic variable.";
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
Clear[coefficientRationalFieldReduce];
coefficientRationalFieldReduce[expression_]:=Module[
 {atoms,constants=<||>,restore={},constant,power,termPower,rules,baseFactors,exponentPower},
 constant[x_]:=Module[{s=Lookup[constants,Key[x],None]},
   If[s===None,s=Unique["coefficientField"];AssociateTo[constants,x->s];AppendTo[restore,s->x]];s];
 termPower[b_,t_]:=Module[{n=1,rest=t,parts},
   If[MatchQ[t,_Integer|_Rational],n=t;rest=1,
    If[Head[t]===Times&&MatchQ[First[t],_Integer|_Rational],n=First[t];rest=Times@@Rest[t]]];
   If[rest===1&&IntegerQ[n],b^n,
    constant[b^(rest/Denominator[n])]^Numerator[n]]];
 (* Preserve additive exponent identities before introducing independent
    field symbols. For example 2^(3-4 epsilon)=8 (2^epsilon)^(-4).
    Only integer outer powers are used; no PowerExpand is involved. *)
 baseFactors[b_]:=Module[{parts=If[Head[b]===Times,List@@b,{b}],positive={},rest=1,base,exponent},
  Do[
   Which[
    MatchQ[part,_Integer|_Rational]&&part=!=0,
     positive=Join[positive,FactorInteger[Abs[part]]];rest*=Sign[part],
    MemberQ[{Pi,E},part],AppendTo[positive,{part,1}],
    MatchQ[part,Power[Pi|E,_Rational|_Integer]],AppendTo[positive,List@@part],
    True,rest*=part],
  {part,parts}];
  If[rest=!=1,AppendTo[positive,{rest,1}]];positive];
 exponentPower[b_,p_]:=With[{expanded=Expand[p]},Times@@
   (termPower[b,#]&/@If[Head[expanded]===Plus,List@@expanded,{expanded}])];
 (* Positive numerical factors do not change the principal argument. Split
    them before introducing formal symbols: (16 Pi)^epsilon must use the
    same field generators as 2^(4 epsilon) Pi^epsilon. Unknown-sign factors
    stay together, so no general product-power identity is assumed. *)
 power[b_,p_]:=Times@@(exponentPower[#[[1]],#[[2]]p]&/@baseFactors[b]);
 atoms=DeleteDuplicates@Join[
   Cases[expression,Power[_,p_]/;!IntegerQ[p],{0,Infinity}],
   Cases[expression,a:h_[___]/;!MemberQ[{List,Plus,Times,Power,Rational},h]:>a,{0,Infinity}]];
 rules=Map[Function[x,x->If[Head[x]===Power,power[x[[1]],x[[2]]],constant[x]]],atoms];
 {expression/.rules,restore}
];

CancelRationalCoefficients[expressions_List]:=Module[{reduced,restore,variables,result,physicalVariables},
 If[expressions==={},Return[{}]];
 {reduced,restore}=coefficientRationalFieldReduce[expressions];
 variables=DeleteDuplicates[Cases[reduced,_Symbol,{0,Infinity}]];
 If[variables==={},Return[reduced/.restore]];
 result=CancelRationalExpressions[reduced,variables];
 If[FailureQ[result],Return[result]];
 (* Keep common analytic normalizations outside a large rational numerator.
    Otherwise restoration repeats 2^(a+b epsilon), Gamma factors, etc. in every
    monomial, making structural epsilon bounds and serialization needlessly
    expensive. This is an exact polynomial-content operation in the same
    formal coefficient field, before restoring the analytic factors. *)
 physicalVariables=Complement[variables,First/@restore];
 If[restore=!={}&&physicalVariables=!={},
  result=Map[Function[value,FactorTerms[Numerator[value],physicalVariables]/Denominator[value]],result]];
 result/.restore
];
End[];
EndPackage[];
