(* Resolve finite arithmetic definitions and collect only in special-function
   atoms. Expanding all rational coefficients together made a 25 MB physical
   coefficient vector spend over ten minutes in one Factor call. *)
BeginPackage["FeynFacet`"];
CollectFiniteSolutionCoefficients::usage="CollectFiniteSolutionCoefficients[connection,coefficients,request] resolves acyclic arithmetic definitions and collects polynomial dependence on finite integrals, GPLs and logarithms while keeping rational coefficient fields separate. It returns exactly the same finite expressions; no integral is evaluated or epsilon order discarded.";
ShareFiniteCoefficientVector::usage="ShareFiniteCoefficientVector[connection,vector] stores every nontrivial finite vector coefficient once in the connection's existing acyclic arithmetic definitions, and replaces its repeated occurrences by those references before matrix multiplication. It stores evaluated finite expressions, not an evaluator or differential equation.";
Begin["`Private`"];
ShareFiniteCoefficientVector[connection_Association,vector_Association]:=Module[
 {definitions=Lookup[connection,"AlgebraicDefinitions",{}],values=Lookup[vector,"Coefficients",None],
  shared=<||>,known=<||>,index},
 If[!ListQ[definitions]||!AssociationQ[values],
  Return[Failure["FiniteConnectionAndCoefficientVectorRequired",<||>]]];
 KeyValueMap[Function[{key,value},
  If[NumberQ[value]||MatchQ[value,_FeynFacetSolution`a],AssociateTo[shared,key->value],
   If[KeyExistsQ[known,value],index=known[value],
    AppendTo[definitions,value];index=Length[definitions];AssociateTo[known,value->index]];
   AssociateTo[shared,key->FeynFacetSolution`a[index]]]
 ],values];
 <|"Connection"->Join[connection,<|"AlgebraicDefinitions"->definitions|>],
   "Vector"->Join[vector,<|"Coefficients"->shared|>]|>
];

CollectFiniteSolutionCoefficients[connection_Association,coefficients_Association,request_Association:<||>]:=
 Catch[Module[{definitions=Lookup[connection,"AlgebraicDefinitions",{}],resolve,collect,
  result=<||>,started=AbsoluteTime[],count=0,timeLimit=Lookup[request,"CoefficientTimeLimit",2]},
 resolve[i_Integer]:=resolve[i]=If[1<=i<=Length[definitions],
  If[AnyTrue[Cases[definitions[[i]],FeynFacetSolution`a[j_Integer]:>j,Infinity],#>=i&],
   Throw[Failure["AcyclicFiniteArithmeticDefinitionsRequired",<|"Index"->i|>],"FiniteCoefficientCollection"]];
  definitions[[i]]/.FeynFacetSolution`a[j_Integer]:>resolve[j],
  Throw[Failure["FiniteArithmeticDefinitionMissing",<|"Index"->i|>],"FiniteCoefficientCollection"]];
 collect[expr_]:=Module[{value,objects,aliases,rules,terms},
  value=expr/.FeynFacetSolution`a[i_Integer]:>resolve[i];
  objects=DeleteDuplicates[Cases[value,
   _FeynFacetSolution`F|_FeynFacetSolution`G|_Log|_Zeta,{0,Infinity}]];
  If[objects==={},Return[TimeConstrained[Factor[value],timeLimit,value]]];
  aliases=Table[Unique["finiteSpecialFunction"],{Length[objects]}];
  rules=FeynFacet`PolynomialCoefficientRules[value/.Thread[objects->aliases],aliases];
  If[FailureQ[rules],Throw[rules,"FiniteCoefficientCollection"]];
  terms=Map[Function[rule,With[{c=TimeConstrained[Factor[Last[rule]],timeLimit,Last[rule]]},
    c Times@@MapThread[Power,{objects,First[rule]}]]],rules];
  Total[terms]
 ];
 KeyValueMap[Function[{key,value},
  AssociateTo[result,key->collect[value]];count++;
  If[TrueQ[Lookup[request,"PrintTimings",False]]&&(Mod[count,10]===0||count===Length[coefficients]),
   Print["Collected physical coefficient ",count," of ",Length[coefficients],
    " in ",Round[AbsoluteTime[]-started,0.01]," s"]]
 ],coefficients];result
],"FiniteCoefficientCollection"];
End[];EndPackage[];
