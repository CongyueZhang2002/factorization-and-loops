(* Explicit finite GPL coefficients of the massless angular Gauss function.
   The constructor solves the two-by-two epsilon-form system by finite
   words. No recurrence or matrix exponential is stored in the result. *)
FeynFacetSolution`GaussHypergeometricEpsilonCoefficients::usage="GaussHypergeometricEpsilonCoefficients[{a,b,c},z,epsilon,n] returns explicit coefficients through epsilon^n for {-epsilon,-epsilon,1-epsilon} or {1,1,1-epsilon}. Endpoint z=1 is evaluated by dimensional continuation before epsilon expansion.";
Clear[gaussEpsilonWordValue,gaussEpsilonClassical];
gaussEpsilonWordValue[word_]:=With[{matrices={{{0,1},{0,1}},{{0,0},{-1,1}}}},
 First[Fold[#2.#1&,{1,0},Reverse[matrices[[word+1]]]]]];
gaussEpsilonClassical[expression_]:=expression/.{
 FeynFacetSolution`G[{0,1},z_]:>-PolyLog[2,z],
 FeynFacetSolution`G[{0,0,1},z_]:>-PolyLog[3,z],
 FeynFacetSolution`G[{0,1,1},z_]:>Log[z]Log[1-z]^2/2+
  Log[1-z]PolyLog[2,1-z]-PolyLog[3,1-z]+Zeta[3]};
FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[parameters_List,z_,e_Symbol,n_Integer?NonNegative]:=Module[
 {kind,ys,words,coefficients,endpoint,polynomial},
 kind=Which[parameters==={-e,-e,1-e},"Y",parameters==={1,1,1-e},"Angular",True,None];
 If[kind===None||!FreeQ[z,e],Return[Failure["GaussEpsilonParametersUnsupported",<|"Parameters"->parameters|>]]];
 If[2^n>100000,Return[Failure["GaussEpsilonExpressionSizeLimit",<|"WordCountBound"->2^n|>]]];
 If[z===0,Return[Association@Table[j->If[j===0,1,0],{j,0,n}]]];
 If[z===1,
  endpoint=If[kind==="Y",Gamma[1-e]Gamma[1+e],e/(1+e)];
  polynomial=Normal[Series[endpoint,{e,0,n}]];
  Return[Association@Table[j->Coefficient[polynomial,e,j],{j,0,n}]]];
 ys=Association@Table[j->If[j===0,1,
   words=Tuples[{0,1},j];
   gaussEpsilonClassical[Total[(gaussEpsilonWordValue[#]FeynFacetSolution`G[#,z]& /@ words)]]],{j,0,n}];
 If[kind==="Y",Return[ys]];
 Association@Table[j->Sum[ys[k]If[j===k,1,(-Log[1-z])^(j-k)]/(j-k)!,{k,0,j}]/(1-z),{j,0,n}]
];
