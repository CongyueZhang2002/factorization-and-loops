(* Total differentials of iterated integrals, including moving letters. *)
FeynFacetSolution`DifferentiateGPLExpression::usage="DifferentiateGPLExpression[expression,x] differentiates rational/special-function coefficients and GPL endpoints and letters with respect to x. Coincident adjacent letters are combined before their difference is divided; fixed trailing zero letters retain the standard tangential-basepoint convention. An unresolved moving singular upper endpoint is rejected.";
gplTotalDerivative[FeynFacetSolution`G[word_List,point_],variable_Symbol]:=Module[
 {n=Length[word],value=0,difference,multiplier,logDerivative,omit},
 If[n===0||FreeQ[{word,point},variable],Return[0]];
 omit[i_]:=gplMake[Delete[word,i],point];
 logDerivative[arg_]:=Module[{derivative=D[arg,variable]},
  If[derivative===0,Return[0]];
  If[TrueQ[arg===0],gplFail["MovingSingularGPLBoundaryRequired"]];derivative/arg];
 difference=point-First[word];
 If[difference===0&&!FreeQ[{word,point},variable],gplFail["MovingSingularGPLUpperEndpointUnsupported"]];
 value=omit[1]logDerivative[difference]-omit[n]logDerivative[-Last[word]];
 Do[multiplier=omit[i+1]-omit[i];
  If[multiplier=!=0,value+=multiplier logDerivative[word[[i]]-word[[i+1]]]],{i,n-1}];
 value
];
FeynFacetSolution`DifferentiateGPLExpression[expression_,variable_Symbol]:=Catch[Module[
 {objects,aliases,polynomial,result},
 objects=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 If[!AllTrue[objects,MatchQ[#,FeynFacetSolution`G[_List,_]]&],gplFail["ExplicitGPLWordsRequired"]];
 aliases=Unique["differentiatedGPL$"]&/@objects;
 polynomial=expression/.Thread[objects->aliases];
 result=(D[polynomial,variable]+Total[MapThread[
   D[polynomial,#1]gplTotalDerivative[#2,variable]&,{aliases,objects}]])/.Thread[aliases->objects];
 result=result/.FeynFacetSolution`G[zeros:{0..},point_]:>Log[point]^Length[zeros]/Factorial[Length[zeros]];
 gplCollectCoefficients[result,True]
],"GPLIntegration"];
