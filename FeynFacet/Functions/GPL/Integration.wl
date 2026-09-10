(* Finite hyperlogarithmic integration. Loaded in FeynFacetSolution`Private`.
   GPL letters are constant with respect to the integration variable.
   The algorithms operate on explicit finite expressions, never a DE generator. *)
FeynFacetSolution`G::usage="G[{a1,...,an},z] is the Goncharov polylogarithm with kernels dt/(t-ai) and the standard logarithmic regularization at zero. The empty word equals one.";
FeynFacetSolution`IntegrateGPL::usage="IntegrateGPL[expression,{t,0,s}] constructs an explicit primitive in rational functions and GPLs, with its finite lower-end value subtracted, including integrable logarithmic endpoint singularities. Rational higher poles are reduced by integration by parts. Unsupported function dependence is reported.";
Clear[FeynFacetSolution`G];
FeynFacetSolution`G[{},z_]:=1;
FeynFacetSolution`G /: D[FeynFacetSolution`G[word_List,z_],v_Symbol] /; word=!={} && FreeQ[word,v] :=
 D[z,v] FeynFacetSolution`G[Rest[word],z]/(z-First[word]);
Derivative[orders_List,1][FeynFacetSolution`G] /; AllTrue[orders,#===0&] :=
 Function[{word,z},FeynFacetSolution`G[Rest[word],z]/(z-First[word])];
gplFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"GPLIntegration"];
gplRationalQ[z_,t_]:=Module[{q=Together[z]},
 PolynomialQ[Numerator[q],t]&&PolynomialQ[Denominator[q],t]];
gplBound[z_]:=If[LeafCount[z]>$gplMaxLeaves,gplFail["GPLExpressionSizeLimit"]];
gplMake[{},t_]:=1;
gplMake[word_List,t_]:=FeynFacetSolution`G[word,t];
gplWords[z_,t_]:=Module[{visit,add,multiply,check,out},
 add[a_,b_]:=Module[{v=a},KeyValueMap[
   AssociateTo[v,#1->(Lookup[v,Key[#1],0]+#2)]&,b];v];
 multiply[a_,b_]:=Module[{v=<||>},
  KeyValueMap[Function[{wa,ca},KeyValueMap[Function[{wb,cb},
    KeyValueMap[Function[{wc,cc},AssociateTo[v,wc->(Lookup[v,Key[wc],0]+ca cb cc)]],
      gplShuffle[wa,wb]]],b]],a];
  If[Length[v]>$gplMaxTerms,gplFail["GPLWordCountLimit"]];v];
 (* This structural test does not form a large common denominator merely
    to establish rationality in t. Endpoint-parameter expressions are scalars. *)
 check[q_]:=Which[FreeQ[q,t],True,q===t,True,
  MemberQ[{Plus,Times},Head[q]],AllTrue[List@@q,check],
  Head[q]===Power&&IntegerQ[q[[2]]],check[q[[1]]],True,False];
 visit[q_]:=Which[
  FreeQ[q,t],<|{}->q|>,
  FreeQ[q,_FeynFacetSolution`G],If[check[q],<|{}->q|>,
    gplFail["NonRationalGPLCoefficient",<|"Coefficient"->Short[q]|>]],
  MatchQ[q,FeynFacetSolution`G[_List,t]],
    If[FreeQ[q[[1]],t],<|q[[1]]->1|>,gplFail["GPLVariableOrLettersNotSupported"]],
  Head[q]===Plus,Fold[add,<||>,visit /@ List@@q],
  Head[q]===Times,Fold[multiply,<|{}->1|>,visit /@ List@@q],
  Head[q]===Power&&IntegerQ[q[[2]]]&&q[[2]]>=0,
    Nest[multiply[#,visit[q[[1]]]]&,<|{}->1|>,q[[2]]],
  MatchQ[q,_FeynFacetSolution`G],gplFail["GPLVariableOrLettersNotSupported"],
  True,gplFail["NonPolynomialDependenceOnGPL"]];
 out=visit[z];
 If[Length[out]>$gplMaxTerms,gplFail["GPLWordCountLimit"]];
 Select[out,#=!=0&]
];

gplShuffle[a_List,b_List]:=gplShuffle[a,b]=Which[
 a==={},<|b->1|>,b==={},<|a->1|>,
 True,Module[{out=<||>,add},
  add[head_,tail_]:=KeyValueMap[Function[{w,c},With[{v=Prepend[w,head]},
    AssociateTo[out,v->(Lookup[out,Key[v],0]+c)]]],tail];
  add[First[a],gplShuffle[Rest[a],b]];add[First[b],gplShuffle[a,Rest[b]]];
  If[Length[out]>$gplMaxTerms,gplFail["GPLWordCountLimit"]];out]
];
(* Hermite reduction is done in the rational coefficient field before any
   algebraic roots are introduced. Exact differentials often remove all
   higher-degree factors, which is essential for prepared non-epsilon forms. *)
gplRationalDecomposition[r_,t_]:=gplRationalDecomposition[r,t]=Module[
 {q=Cancel[Together[r]],apart,terms,num,den,factors,variableFactors,fac,m,
  a,b,gcd,inverse,remainder,quotient,primitive=0,simple={},residues={},degree,
  roots,discriminant,leading,root,c,extended,integratePolynomial},
 integratePolynomial[poly_]:=Sum[Coefficient[poly,t,j] t^(j+1)/(j+1),
  {j,0,Max[0,Exponent[poly,t]]}];
 If[!gplRationalQ[q,t],gplFail["NonRationalIntegrationKernel"]];
 apart=Apart[q,t];terms=If[Head[apart]===Plus,List@@apart,{apart}];
 Do[
  num=Numerator[Together[term]];den=Denominator[Together[term]];
  If[FreeQ[den,t],primitive+=integratePolynomial[num/den];Continue[]];
  factors=Rest[FactorList[den]];
  variableFactors=Select[factors,!FreeQ[#[[1]],t]&];
  If[Length[variableFactors]=!=1,gplFail["RationalPartialFractionsNotSeparated"]];
  {fac,m}=First[variableFactors];a=Cancel[num/(den/fac^m)];
  If[m>1,
   extended=PolynomialExtendedGCD[fac,D[fac,t],t];
   If[!FreeQ[First[extended],t],gplFail["NonSquareFreeHermiteFactor"]];
   inverse=Cancel[extended[[2,2]]/First[extended]];
   While[m>1,
    b=Cancel[-PolynomialRemainder[a inverse,fac,t]/(m-1)];
    primitive+=b/fac^(m-1);
    remainder=Cancel[Together[a-D[b,t] fac+(m-1)b D[fac,t]]];
    quotient=PolynomialQuotient[remainder,fac,t];
    If[!TrueQ[Cancel[Together[remainder-quotient fac]]===0],
     gplFail["RationalHermiteDivisionFailed"]];
    a=Cancel[quotient];m--]
  ];
  quotient=PolynomialQuotient[a,fac,t];primitive+=integratePolynomial[quotient];
  a=Cancel[Together[a-quotient fac]];
  If[a=!=0,AppendTo[simple,{fac,a}]],
 {term,terms}];
 (* Cancellation between rational partial fractions can remove a residual
    pole. Group identical factors before splitting the square-free part. *)
 simple=GatherBy[simple,First];
 simple=({#[[1,1]],Cancel[Together[Total[#[[All,2]]]]]}& /@ simple);
 simple=Select[simple,Last[#]=!=0&];
 Do[
  {fac,a}=entry;degree=Exponent[fac,t];
  If[degree>$gplMaxDegree,gplFail["GPLPoleDegreeLimit",<|"Degree"->degree|>]];
  roots=Switch[degree,
   1,{-Coefficient[fac,t,0]/Coefficient[fac,t,1]},
   2,discriminant=Coefficient[fac,t,1]^2-4 Coefficient[fac,t,2] Coefficient[fac,t,0];
     Table[(-Coefficient[fac,t,1]+sign Sqrt[discriminant])/(2 Coefficient[fac,t,2]),{sign,{-1,1}}],
   _,Quiet[Check[t/.Solve[fac==0,t,Cubics->False,Quartics->False],$Failed]]];
  If[!ListQ[roots]||Length[roots]=!=degree||!FreeQ[roots,t]||!DuplicateFreeQ[roots],
   gplFail["GPLPolynomialRootsNotConstructed"]];
  Do[
   c=Cancel[(a/D[fac,t])/.t->root];
   If[!FreeQ[c,Indeterminate|_DirectedInfinity],gplFail["GPLDegenerateAlphabet"]];
   If[c=!=0,AppendTo[residues,{root,c}]],
  {root,roots}],
 {entry,simple}];
 {Cancel[Together[primitive]],residues}
];

gplIntegrateWord[r_,word_List,t_]:=gplIntegrateWord[r,word,t]=Module[{parts,primitive,residues,result,free,dependent},
 If[Head[r]===Plus,Return[Total[gplIntegrateWord[#,word,t]& /@ List@@r]]];
 If[Head[r]===Times,
  free=Times@@Select[List@@r,FreeQ[#,t]&];dependent=Times@@Select[List@@r,!FreeQ[#,t]&];
  If[free=!=1,Return[free gplIntegrateWord[dependent,word,t]]]];
 If[Length[word]+1>$gplMaxWeight,gplFail["GPLWeightLimit"]];
 If[r===0,Return[0]];
 parts=gplRationalDecomposition[Cancel[r],t];{primitive,residues}=parts;
 result=primitive gplMake[word,t]+Total[(#[[2]] gplMake[Prepend[word,#[[1]]],t])& /@ residues];
 If[word=!={}&&primitive=!=0,
  result-=gplIntegrateWord[Cancel[primitive/(t-First[word])],Rest[word],t]];
 gplBound[result];result
];

(* Local power/log series retain the finite endpoint contribution of a
   rational pole times a vanishing GPL. Setting every GPL(0) to zero is wrong. *)
gplIntegrateMonomial[n_Integer,k_Integer,t_]:=If[n===-1,Log[t]^(k+1)/(k+1),
 t^(n+1) Sum[(-1)^j Factorial[k]/Factorial[k-j] Log[t]^(k-j)/(n+1)^(j+1),{j,0,k}]];
gplSeries[word_List,n_Integer,t_]:=gplSeries[word,n,t]=Module[{rest,derivative,ell=Unique["logarithm"],out=0,cr},
 If[word==={},Return[1]];
 If[AllTrue[word,#===0&],Return[Log[t]^Length[word]/Factorial[Length[word]]]];
 If[n<=0,Return[0]];
 rest=gplSeries[Rest[word],n,t];
 derivative=If[First[word]===0,rest/t,
  rest (-Sum[t^j/First[word]^(j+1),{j,0,n-1}])];
 derivative=Expand[derivative/.Log[t]->ell];
 (* t*derivative is polynomial, including the first-letter-zero case. *)
 cr=CoefficientRules[Expand[t derivative],{t,ell}];
 Do[If[rule[[1,1]]<=n,
  out+=Last[rule] gplIntegrateMonomial[rule[[1,1]]-1,rule[[1,2]],t]],{rule,cr}];
 out
];
gplAtZero[expression_,t_]:=Module[{words,poles,order,expanded,ell=Unique["logarithm"],value},
 words=gplWords[expression,t];
 poles=Map[Function[q,Module[{v=Together[q]},
  Max[0,Exponent[Denominator[v],t,Min]-Exponent[Numerator[v],t,Min]]]],Values[words]];
 order=Max[Append[poles,0]];
 If[order>$gplMaxEndpointOrder,gplFail["GPLEndpointExpansionLimit"]];
 expanded=Total[KeyValueMap[#2 gplSeries[#1,order,t]&,words]]/.Log[t]->ell;
 value=Quiet[Check[Normal[Series[expanded,{t,0,0}]],$Failed]];
 If[value===$Failed,gplFail["GPLEndpointValueNotConstructed"]];
 value=Cancel[Together[value]];
 If[!FreeQ[value,t|ell|Indeterminate|_DirectedInfinity],
  gplFail["GPLLowerEndpointNotFinite",<|"EndpointExpansion"->Short[value]|>]];
 value
];
gplNormalizeLogs[expression_,t_]:=expression/.Log[r_]/;!FreeQ[r,t]:>Module[{v0,derivative,p,q,num,den,order},
 If[!gplRationalQ[r,t],gplFail["NonRationalLogarithmArgument"]];
 q=Cancel[Together[r]];{num,den}=NumeratorDenominator[q];
 If[num===0,gplFail["ZeroLogarithmArgument"]];
 order=Exponent[num,t,Min]-Exponent[den,t,Min];
 If[!IntegerQ[order],gplFail["IntegerLogarithmEndpointOrderRequired"]];
 q=Cancel[q/t^order];v0=Cancel[q/.t->0];
 If[v0===0||!FreeQ[v0,Indeterminate|_DirectedInfinity],gplFail["SingularLogarithmBasePoint"]];
 derivative=Cancel[D[q,t]/q];
 p=gplIntegrateWord[derivative,{},t];
 (* For positive real integration parameter t near zero, t^order has
    positive phase. Log[v0] fixes the branch of the remaining analytic factor.
    The full primitive must still have a finite lower endpoint. *)
 order gplMake[{0},t]+p-gplAtZero[p,t]+Log[v0]
];
Options[FeynFacetSolution`IntegrateGPL]={
 "TimeLimit"->30,"MaxExpressionLeaves"->200000,"MaxTerms"->10000,
 "MaxWeight"->16,"MaxPoleDegree"->4,"MaxEndpointExpansionOrder"->32};
FeynFacetSolution`IntegrateGPL[expression_,{t_Symbol,0,s_},OptionsPattern[]]:=
 Block[{$gplMaxLeaves=OptionValue["MaxExpressionLeaves"],$gplMaxTerms=OptionValue["MaxTerms"],
  $gplMaxWeight=OptionValue["MaxWeight"],$gplMaxDegree=OptionValue["MaxPoleDegree"],
  $gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 Internal`InheritedBlock[{gplShuffle,gplIntegrateWord,gplRationalDecomposition,gplSeries},
 TimeConstrained[Catch[Module[{normalized,words,primitive,lower,result},
  If[!NumericQ[OptionValue["TimeLimit"]]||!TrueQ[OptionValue["TimeLimit"]>0],
    gplFail["InvalidGPLIntegrationOptions"]];
  If[!AllTrue[{$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
    IntegerQ[#]&&#>0&],gplFail["InvalidGPLIntegrationOptions"]];
  (* All memoization is confined to this conversion, with the current bounds. *)
  If[!FreeQ[expression,Power[base_,power_Rational]/;Denominator[power]===2&&!FreeQ[base,t]],
   Return[gplIntegrateQuadraticRoot[expression,t,s],Module]];
  normalized=gplNormalizeLogs[gplNormalizeArguments[expression,t],t];gplBound[normalized];
  words=gplWords[normalized,t];
  primitive=Total[KeyValueMap[gplIntegrateWord[#2,#1,t]&,words]];
  lower=gplAtZero[primitive,t];
  result=(primitive/.t->s)-lower;gplBound[result];result
 ],"GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLIntegrationTimeLimit",<||>]]]];
