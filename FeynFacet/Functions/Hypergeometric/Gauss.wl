(* Explicit finite GPL coefficients of the massless angular Gauss function.
   The constructor solves the two-by-two epsilon-form system by finite
   words. No recurrence or matrix exponential is stored in the result. *)
FeynFacetSolution`GaussHypergeometricEpsilonCoefficients::usage="GaussHypergeometricEpsilonCoefficients[{a,b,c},z,epsilon,n] returns explicit coefficients through epsilon^n for {-epsilon,-epsilon,1-epsilon} or {1,1,1-epsilon}, and nonnegative integer shifts and argument derivatives of {1,b epsilon,1+b epsilon}. Endpoint z=1 is evaluated by dimensional continuation before epsilon expansion.";
Clear[gaussEpsilonWordValue,gaussEpsilonClassical];
gaussEpsilonWordValue[word_]:=With[{matrices={{{0,1},{0,1}},{{0,0},{-1,1}}}},
 First[Fold[#2.#1&,{1,0},Reverse[matrices[[word+1]]]]]];
gaussEpsilonClassical[expression_]:=expression/.{
 FeynFacetSolution`G[{0,1},z_]:>-PolyLog[2,z],
 FeynFacetSolution`G[{0,0,1},z_]:>-PolyLog[3,z],
 FeynFacetSolution`G[{0,1,1},z_]:>Log[z]Log[1-z]^2/2+
  Log[1-z]PolyLog[2,1-z]-PolyLog[3,1-z]+Zeta[3]};
FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[parameters_List,z_,e_Symbol,n_Integer?NonNegative]:=Module[
 {kind,ys,words,coefficients,endpoint,polynomial,m,beta,auxiliary,h,tail},
 (* For H_b(z)=2F1(1,b;1+b;z),
    H_(beta e)=1+sum_(k>=1) (-1)^(k-1) (beta e)^k Li_k(z).
    Integer argument derivatives supply the shifted Gauss functions
    appearing in exact face jets, including their removable beta=0 limit. *)
 If[Length[parameters]===3&&IntegerQ[parameters[[1]]]&&parameters[[1]]>=1&&
   TrueQ[Cancel[parameters[[3]]-parameters[[2]]-1]===0],
  m=parameters[[1]]-1;
  If[PolynomialQ[parameters[[2]]-m,e]&&Exponent[parameters[[2]]-m,e]<=1&&
    TrueQ[Cancel[(parameters[[2]]-m)/.e->0]===0],
   If[!FreeQ[z,e],Return[Failure["RegulatorIndependentGaussArgumentRequired",<||>]]];
   If[z===0,Return[Association@Table[j->If[j===0,1,0],{j,0,n}]]];
   If[z===1,Return[Failure["UnresolvedLogarithmicGaussEndpoint",<||>]]];
   beta=Coefficient[parameters[[2]]-m,e];
   auxiliary=Unique["gaussArgument"];
   coefficients=Association@Table[j->If[j===0,If[m===0,1,(1-z)^(-m)],
     (beta^j/Factorial[m] D[
       m (-1)^j PolyLog[j+1,auxiliary]+(-1)^(j-1)PolyLog[j,auxiliary],
       {auxiliary,m}])/.auxiliary->z],{j,0,n}];
   Return[coefficients]]
 ];
 (* Positive integer shifts of the same Euler family use its exact
    power series with the first h terms removed. The factor h+beta e
    cancels before differentiating, so no artificial epsilon pole occurs. *)
 If[Length[parameters]===3&&IntegerQ[parameters[[1]]]&&parameters[[1]]>=1&&
   TrueQ[Cancel[parameters[[3]]-parameters[[2]]-1]===0],
  m=parameters[[1]]-1;h=Cancel[(parameters[[2]]-m)/.e->0];
  If[IntegerQ[h]&&h>0&&PolynomialQ[parameters[[2]],e]&&Exponent[parameters[[2]],e]<=1,
   If[!FreeQ[z,e],Return[Failure["RegulatorIndependentGaussArgumentRequired",<||>]]];
   If[z===0,Return[Association@Table[j->If[j===0,1,0],{j,0,n}]]];
   If[z===1,Return[Failure["UnresolvedLogarithmicGaussEndpoint",<||>]]];
   beta=Coefficient[parameters[[2]],e];auxiliary=Unique["gaussArgument"];
   tail[k_]:=auxiliary^-h (PolyLog[k,auxiliary]-Sum[auxiliary^j/j^k,{j,1,h-1}]);
   Return[Association@Table[j->(beta^j/Factorial[m] D[
     If[j===0,(h+m)tail[1],(h+m)(-1)^j tail[j+1]+(-1)^(j-1)tail[j]],
     {auxiliary,m}])/.auxiliary->z,{j,0,n}]]
  ]
 ];
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
