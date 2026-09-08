(* Explicit scalar functions in dependency order, including common arithmetic.
   Every definition is fixed before export; this does not generate coefficients. *)
Begin["FeynFacet`Private`"];
Clear[solutionBuildKernelDefinitions,solutionResolveKernelDefinitions,
 solutionEvaluateKernelDefinitions];
solutionBuildKernelDefinitions[coefficients_,vars_,base_,t_,upper_,n_] := Module[
 {definitions={},indices=<||>,intern,add,coordinateMatrices,kernels,path,
  arithmeticCount,append},
 append[body_,kind_] := Module[{index=Length[definitions]+1},
  AppendTo[definitions,<|"Index"->index,"Parameter"->t,"Expression"->body,
    "Kind"->kind|>];FeynFacetSolution`K[index,t]];
 intern[value_] := If[AtomQ[value] || NumberQ[value],value,
  Module[{known=Lookup[indices,Key[value],None],body,reference},
   If[known=!=None,Return[known]];
   If[LeafCount[value]<=8,Return[value]];
   body=Map[intern,value];
   reference=append[body,"ScalarExpression"];
   AssociateTo[indices,value->reference];reference]];
 If[!FreeQ[coefficients,_FeynFacetSolution`K|_FeynFacetSolution`F|_FeynFacetSolution`a],
  solutionFail["ExplicitSourceKernelFunctionsRequired"]];
 coordinateMatrices=Table[Map[Map[intern,#,{2}]&,coordinate],{coordinate,coefficients}];
 path=Thread[vars->(base+t(vars-base))];
 arithmeticCount=Length[definitions];
 coordinateMatrices=coordinateMatrices/.path;
 definitions=Map[Join[#,<|"Expression"->(#["Expression"]/.path)|>]&,definitions];
 (* These factors are d gamma/dt, hence contain endpoint coordinates rather
    than coordinates on the path. Only the coefficient functions above were
    pulled back. *)
 kernels=Association@Table[q->Total[Table[
   (vars[[v]]-base[[v]]) solutionCoefficient[coordinateMatrices[[v]],q,n],
   {v,Length[vars]}]],{q,0,upper}];
 indices=<||>;
 add[value_] := If[value===0,0,Module[{body=value,prefactor=1,known,reference},
  If[Head[value]===Times && NumberQ[First[value]],prefactor=First[value];body=value/prefactor];
  known=Lookup[indices,Key[body],None];
  If[known===None,reference=append[body,"IntegrationKernel"];AssociateTo[indices,body->reference],reference=known];
  prefactor reference]];
 kernels=Map[Map[add,#,{2}]&,kernels];
 <|"Matrices"->kernels,"Definitions"->definitions,
   "SharedScalarExpressionCount"->arithmeticCount,
   "IntegrationKernelCount"->Length[definitions]-arithmeticCount|>
];
solutionResolveKernelDefinitions[definitions_List] := Module[{result={},body},
 Do[
  body=definition["Expression"]/.FeynFacetSolution`K[j_Integer,u_]:>
    (result[[j]]/.definitions[[j,"Parameter"]]->u);
  AppendTo[result,body],{definition,definitions}];result
];
solutionEvaluateKernelDefinitions[definitions_List,rules_List,precision_Integer] := Module[
 {result=ConstantArray[0,Length[definitions]],body},
 Do[
  body=definitions[[i,"Expression"]]/.FeynFacetSolution`K[j_Integer,_]:>result[[j]];
  result[[i]]=N[body/.rules,precision],{i,Length[definitions]}];result
];
End[];
