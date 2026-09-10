(* Collect only in the requested polynomial variables; leave coefficient
   expressions factored. This avoids expanding large external scalar factors. *)
BeginPackage["FeynFacet`"];
PolynomialCoefficientRules::usage="PolynomialCoefficientRules[expression,variables] returns exact monomial coefficient rules while keeping expressions independent of variables unexpanded. Non-polynomial dependence returns Failure.";
Begin["`Private`"];
(* CoefficientRules[expr,{}] infers variables in Wolfram. The explicit empty
   coefficient-variable list instead means that the entire expression is scalar. *)
PolynomialCoefficientRules[expression_,{}]:=If[expression===0,{},{{}->expression}];
PolynomialCoefficientRules[expression_,variables_List]:=Catch[Module[
 {objects={},aliases=<||>,encode,compiled,terms},
 encode[value_]:=Which[
  MemberQ[variables,value]||NumberQ[value],value,
  FreeQ[value,Alternatives@@variables],
   If[KeyExistsQ[aliases,value],aliases[value],
    AppendTo[objects,value];With[{symbol=Unique["polynomialCoefficient$"]},AssociateTo[aliases,value->symbol];symbol]],
  MemberQ[{Plus,Times},Head[value]],Map[encode,value],
  Head[value]===Power&&IntegerQ[value[[2]]]&&value[[2]]>=0,encode[value[[1]]]^value[[2]],
  True,Throw[Failure["PolynomialDependenceRequired",<||>],"PolynomialCoefficients"]];
 compiled=encode[expression];
 terms=CoefficientRules[compiled,variables];
 (First[#]->(Last[#]/.Dispatch[Thread[Values[aliases]->objects]]))&/@terms
],"PolynomialCoefficients"];

(* Avoid copying a large sum to subkernels. The exact native rational
   backend accepts the whole coefficient row in one transfer; small rows use
   Wolfram directly. Neither route specializes kinematics or truncates data. *)
cancelCoefficientRow[values_List]:=Module[{answer},
 If[ByteCount[values]>128000&&FileExistsQ[$rationalFunctionBackend],
  answer=FeynFacet`CancelRationalCoefficients[values];
  If[ListQ[answer],Return[answer]]];
 Cancel[Together[#]]&/@values
];
(* Cancel common rational factors in independent external coefficients in an explicitly bounded pool.
   A caller-owned pool is preserved; the serial route remains valid there. *)
cancelIndependentCoefficients[values_List,workers_Integer]:=Module[{opened={},answer},
 If[ByteCount[values]>128000,Return[cancelCoefficientRow[values]]];
 If[workers<=1||Length[values]<32||Kernels[]=!={},Return[Cancel[Together[#]]&/@values]];
 Internal`WithLocalSettings[Null,
  opened=facetLaunchKernels[Min[workers,Length[values]]];
  If[opened==={},answer=Cancel[Together[#]]&/@values,
   ParallelEvaluate[
    $HistoryLength=0;$MaxExtraPrecision=50;
    SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}],opened];
   answer=ParallelMap[Function[value,System`Cancel[System`Together[value]]],values,Method->"FinestGrained",DistributedContexts->None]],
  If[opened=!={},CloseKernels[opened]]];
 answer
];
End[];EndPackage[];
