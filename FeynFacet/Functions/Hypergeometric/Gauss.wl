(* Explicit finite GPL coefficients of supported Gauss parameter families.
   The constructor solves the two-by-two epsilon-form system by finite
   words. No recurrence or matrix exponential is stored in the result. *)
FeynFacetSolution`GaussHypergeometricEpsilonCoefficients::usage="GaussHypergeometricEpsilonCoefficients[{a,b,c},z,epsilon,n] returns explicit coefficients through epsilon^n for {-epsilon,-epsilon,1-epsilon}, {1,1,1-epsilon}, affine perturbations of integer parameters with a,b>=1 and c>=2, and nonnegative integer shifts and argument derivatives of {1,b epsilon,1+b epsilon}. Endpoint z=1 is evaluated by dimensional continuation before epsilon expansion.";
Clear[gaussEpsilonWordValue,gaussEpsilonClassical];
gaussEpsilonWordValue[word_]:=With[{matrices={{{0,1},{0,1}},{{0,0},{-1,1}}}},
 First[Fold[#2.#1&,{1,0},Reverse[matrices[[word+1]]]]]];
gaussEpsilonClassical[expression_]:=expression/.{
 FeynFacetSolution`G[{1},z_]:>Log[1-z],
 FeynFacetSolution`G[word:{Repeated[0],1},z_]:>-PolyLog[Length[word],z],
 FeynFacetSolution`G[word:{Repeated[1]},z_]:>Log[1-z]^Length[word]/Factorial[Length[word]],
 FeynFacetSolution`G[{1,0,1},z_]:>-Log[1-z]PolyLog[2,z]-Log[z]Log[1-z]^2-
  2Log[1-z]PolyLog[2,1-z]+2PolyLog[3,1-z]-2Zeta[3],
 FeynFacetSolution`G[{0,1,1},z_]:>Log[z]Log[1-z]^2/2+
  Log[1-z]PolyLog[2,1-z]-PolyLog[3,1-z]+Zeta[3]};
gaussEpsilonDerivative[expression_,z_Symbol]:=Module[{objects,aliases,polynomial,derivatives},
 objects=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 aliases=Table[Unique["gaussGPL"],{Length[objects]}];polynomial=expression/.Thread[objects->aliases];
 derivatives=If[#[[1]]==={},0,
   If[Length[#[[1]]]===1,1,FeynFacetSolution`G[Rest[#[[1]]],z]]/(z-First[#[[1]]])]&/@objects;
 (D[polynomial,z]+Total[MapThread[D[polynomial,#1]#2&,{aliases,derivatives}]])/.Thread[aliases->objects]
];
FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[parameters_List,z_,e_Symbol,n_Integer?NonNegative]:=Module[
 {kind,ys,words,coefficients,endpoint,polynomial,m,beta,auxiliary,h,tail,
  slopes,aa,bb,cc,matrices,second,wordCoefficient,integerParts,current,derivatives,factors,next,level,axis},
 (* Let Y=2F1(a e,b e;1+c e;z) and H=z Y'/(a b e).
    d(Y,H)=e [A0 dz/z+A1 dz/(z-1)] (Y,H), with (Y,H)(0)=(1,0).
    The contiguous derivative gives
    2F1(1+a e,1+b e;2+c e;z)=(1+c e)H/(e z).
    This basis has no division by a or b, so zero slopes are regular limits. *)
 If[Length[parameters]===3&&AllTrue[parameters,PolynomialQ[#,e]&&Exponent[#,e]<=1&]&&
   (parameters/.e->0)==={1,1,2},
  If[!FreeQ[z,e],Return[Failure["RegulatorIndependentGaussArgumentRequired",<||>]]];
  If[2^(n+1)>100000,Return[Failure["GaussEpsilonExpressionSizeLimit",<|"WordCountBound"->2^(n+1)|>]]];
  {aa,bb,cc}=Coefficient[#,e]&/@parameters;
  If[z===0,Return[Association@Table[j->If[j===0,1,0],{j,0,n}]]];
  If[z===1,
   If[TrueQ[cc-aa-bb===0],Return[Failure["UnresolvedLogarithmicGaussEndpoint",<||>]]];
   endpoint=Gamma[2+cc e]Gamma[(cc-aa-bb)e]/(Gamma[1+(cc-aa)e]Gamma[1+(cc-bb)e]);
   polynomial=Normal[Series[endpoint,{e,0,n}]];
   (* This constructor promises nonnegative epsilon coefficients. A pole at
      the argument endpoint must instead be handled by endpoint continuation. *)
   If[!PolynomialQ[polynomial,e],Return[Failure["LaurentGaussEndpointRequiresSeparateContinuation",<||>]]];
   Return[Association@Table[j->Coefficient[polynomial,e,j],{j,0,n}]]];
  matrices={{{0,aa bb},{0,-cc}},{{0,0},{-1,cc-aa-bb}}};
  wordCoefficient[word_]:=Last[Fold[#2.#1&,{1,0},Reverse[matrices[[word+1]]]]];
  second=Association@Table[j->If[j===0,0,
    words=Tuples[{0,1},j];
    gaussEpsilonClassical[Total[(wordCoefficient[#]FeynFacetSolution`G[#,z]&/@words)]]],{j,0,n+1}];
  Return[Association@Table[j->(second[j+1]+cc second[j])/z,{j,0,n}]]
 ];
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
 (* Positive integer parameter shifts are finite contiguous transformations.
    Raise c first, so (c-a)(c-b) has a nonzero epsilon-zero term; then raise
    a and b by F(a+1)=F(a)+z/a dF(a)/dz. This avoids epsilon denominators and
    therefore needs no unplanned deeper coefficients of the initial series. *)
 If[Length[parameters]===3&&AllTrue[parameters,PolynomialQ[#,e]&&Exponent[#,e]<=1&],
  integerParts=parameters/.e->0;
  If[MatchQ[integerParts,{_Integer?Positive,_Integer?Positive,_Integer}]&&Last[integerParts]>=2,
   If[!FreeQ[z,e],Return[Failure["RegulatorIndependentGaussArgumentRequired",<||>]]];
   If[z===0,Return[Association@Table[j->If[j===0,1,0],{j,0,n}]]];
   If[z===1,
    endpoint=Gamma[parameters[[3]]]Gamma[parameters[[3]]-parameters[[1]]-parameters[[2]]]/
     (Gamma[parameters[[3]]-parameters[[1]]]Gamma[parameters[[3]]-parameters[[2]]]);
    polynomial=Quiet[Normal[Series[endpoint,{e,0,n}]]];
    If[!PolynomialQ[polynomial,e]||!FreeQ[polynomial,Indeterminate|_DirectedInfinity],
     Return[Failure["LaurentGaussEndpointRequiresSeparateContinuation",<||>]]];
    Return[Association@Table[j->Coefficient[polynomial,e,j],{j,0,n}]]];
   slopes=Coefficient[#,e]&/@parameters;auxiliary=Unique["gaussArgument"];
   current={1+slopes[[1]]e,1+slopes[[2]]e,2+slopes[[3]]e};
   coefficients=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[current,auxiliary,e,n];
   If[!AssociationQ[coefficients],Return[coefficients]];
   Do[
    {aa,bb,cc}=current;
    derivatives=gaussEpsilonDerivative[#,auxiliary]&/@coefficients;
    factors=Normal[Series[#,{e,0,n}]]&/@{cc(cc-aa-bb)/((cc-aa)(cc-bb)),cc/((cc-aa)(cc-bb))};
    next=Association@Table[j->Sum[Coefficient[factors[[1]],e,k]coefficients[j-k]+
       Coefficient[factors[[2]],e,k](1-auxiliary)derivatives[j-k],{k,0,j}],{j,0,n}];
    coefficients=next;current[[3]]++,{level,2,integerParts[[3]]-1}];
   Do[Do[
    derivatives=gaussEpsilonDerivative[#,auxiliary]&/@coefficients;
    polynomial=Normal[Series[1/current[[axis]],{e,0,n}]];
    next=Association@Table[j->coefficients[j]+auxiliary Sum[
       Coefficient[polynomial,e,k]derivatives[j-k],{k,0,j}],{j,0,n}];
    coefficients=next;current[[axis]]++,{level,1,integerParts[[axis]]-1}],{axis,{1,2}}];
   Return[Map[gaussEpsilonClassical[FactorTerms[#/.auxiliary->z]]&,coefficients]]
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
