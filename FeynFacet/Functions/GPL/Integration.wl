(* Finite hyperlogarithmic integration. Loaded in FeynFacetSolution`Private`.
   GPL letters are constant with respect to the integration variable.
   The algorithms operate on explicit finite expressions, never a DE generator. *)
FeynFacetSolution`G::usage="G[{a1,...,an},z] is the Goncharov polylogarithm with kernels dt/(t-ai) and the standard logarithmic regularization at zero. The empty word equals one.";
FeynFacetSolution`IntegrateGPL::usage="IntegrateGPL[expression,{t,0,s}] constructs an explicit primitive in rational functions and GPLs, with its finite lower-end value subtracted, including integrable logarithmic lower-end singularities. The upper point must permit finite direct substitution, and the caller supplies the path/branch domain. Rational higher poles are reduced by integration by parts; classical polylogarithms of rational arguments are pulled back with their finite basepoint constants. Unsupported function dependence is reported.";
Clear[FeynFacetSolution`G];
FeynFacetSolution`G[{},z_]:=1;
FeynFacetSolution`G /: D[FeynFacetSolution`G[word_List,z_],v_Symbol] /; word=!={} && FreeQ[word,v] :=
 D[z,v] FeynFacetSolution`G[Rest[word],z]/(z-First[word]);
Derivative[orders_List,1][FeynFacetSolution`G] /; AllTrue[orders,#===0&] :=
 Function[{word,z},FeynFacetSolution`G[Rest[word],z]/(z-First[word])];
gplFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"GPLIntegration"];
gplRationalQ[z_,t_]:=Module[{q=Together[z]},
 PolynomialQ[Numerator[q],t]&&PolynomialQ[Denominator[q],t]];
gplBound[z_]:=With[{leaves=LeafCount[z]},If[leaves>$gplMaxLeaves,
 gplFail["GPLExpressionSizeLimit",<|"ExpressionLeaves"->leaves,"Limit"->$gplMaxLeaves|>]]];
(* Compact a growing primitive before unrelated word contributions make its
   external coefficient field too large. Limits apply to the compact explicit
   expression, and remain unchanged. This is exact rational collection. *)
gplCompactPrimitive[expression_]:=If[LeafCount[expression]>Min[20000,$gplMaxLeaves/4],
 gplCollectCoefficients[expression],expression];
gplPrimitiveSum[terms_List]:=gplCompactPrimitive[Total[terms]];

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
    If[FreeQ[q[[1]],t],<|q[[1]]->1|>,gplFail["GPLVariableOrLettersNotSupported",<|"GPL"->q,"IntegrationVariable"->t|>]],
  Head[q]===Plus,Fold[add,<||>,visit /@ List@@q],
  Head[q]===Times,Fold[multiply,<|{}->1|>,visit /@ List@@q],
  Head[q]===Power&&IntegerQ[q[[2]]]&&q[[2]]>=0,
    Nest[multiply[#,visit[q[[1]]]]&,<|{}->1|>,q[[2]]],
  MatchQ[q,_FeynFacetSolution`G],gplFail["GPLVariableOrLettersNotSupported",<|"GPL"->q,"IntegrationVariable"->t|>],
  True,gplFail["NonPolynomialDependenceOnGPL"]];
 out=visit[z];
 If[Length[out]>$gplMaxTerms,gplFail["GPLWordCountLimit"]];
 (* Large coefficients can contain thousands of cancelling rational
    summands after a pullback. Cancel the whole coefficient of each GPL word
    in one exact native batch before integrating or forming endpoint series. *)
 If[LeafCount[out]>20000,
  With[{values=FeynFacet`CancelRationalCoefficients[Values[out]]},
   If[!ListQ[values],gplFail["GPLRationalCoefficientCancellationFailed",<|"Cause"->values|>]];
   out=AssociationThread[Keys[out],values]]];
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
  If[degree>$gplMaxDegree,gplFail["GPLPoleDegreeLimit",<|"Degree"->degree,"Factor"->fac,"Variable"->t|>]];
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

gplIntegrateWord[r_,word_List,t_]:=gplIntegrateWord[r,word,t]=Module[{parts,primitive,residues,result,free,dependent,expanded},
 If[Head[r]===Plus,Return[gplPrimitiveSum[gplIntegrateWord[#,word,t]& /@ List@@r]]];
 If[Head[r]===Times,
  free=Times@@Select[List@@r,FreeQ[#,t]&];dependent=Times@@Select[List@@r,!FreeQ[#,t]&];
  If[free=!=1,Return[free gplIntegrateWord[dependent,word,t]]]];
 (* Expand only in the integration variable. External color factors,
    kinematic coefficients and transcendental constants stay factored.
    Integrating these rational summands before taking the complete endpoint
    limit avoids an enormous multivariate common numerator in Cancel. *)
 expanded=If[LeafCount[r]<=4000,r,Expand[r,t]];
 If[Head[expanded]===Plus,
  If[Length[expanded]>$gplMaxTerms,gplFail["GPLRationalTermCountLimit"]];
  Return[gplPrimitiveSum[gplIntegrateWord[#,word,t]&/@List@@expanded]]];
 If[Length[word]+1>$gplMaxWeight,gplFail["GPLWeightLimit"]];
 If[r===0,Return[0]];
 parts=gplRationalDecomposition[Cancel[r],t];{primitive,residues}=parts;
 result=primitive gplMake[word,t]+Total[(#[[2]] gplMake[Prepend[word,#[[1]]],t])& /@ residues];
 If[word=!={}&&primitive=!=0,
  result-=gplIntegrateWord[Cancel[primitive/(t-First[word])],Rest[word],t]];
 result=gplCompactPrimitive[result];gplBound[result];result
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
gplEndpointLog[log_,assumptions_]:=gplEndpointLog[log,assumptions]=Module[{value},
 value=FeynFacetSolution`ExpandPositiveLogarithms[log,assumptions];
 If[FailureQ[value],log,value]
];
(* A source endpoint may already contain a classical polylogarithm while
   a pulled-back term produces the same value with a reduced rational
   argument. Canonicalize both arguments before coefficient cancellation.
   This changes no function branch: only identical rational arguments merge. *)
gplCanonicalPolylogArguments[expression_]:=Module[{objects,rules},
 objects=DeleteDuplicates[Cases[expression,PolyLog[_Integer,_],{0,Infinity}]];
 rules=(#->PolyLog[#[[1]],Cancel[#[[2]]]])&/@objects;
 expression/.rules
];
gplEndpointScalars[expression_]:=Module[{value=gplCanonicalPolylogArguments[expression]},
 If[!ValueQ[$gplAssumptions]||$gplAssumptions===True,value,
  value/.log_Log:>gplEndpointLog[log,$gplAssumptions]]
];
(* Expand each rational summand locally in t, with all independent factors
   outside the recurrence. A global Series first combines unrelated external
   coefficients and can dominate the integration. The recurrence is formal
   division of numerator and denominator series; no endpoint value is guessed. *)
gplRationalLaurent[r_,t_]:=gplRationalLaurent[r,t]=Module[
 {expanded,free,dependent,q,num,den,nv,dv,valuation,count,d0,coefficients},
 If[r===0,Return[<||>]];
 If[FreeQ[r,t],Return[<|0->r|>]];
 If[Head[r]===Plus,Return[Merge[gplRationalLaurent[#,t]&/@List@@r,Total]]];
 If[Head[r]===Times,
  free=Times@@Select[List@@r,FreeQ[#,t]&];
  dependent=Times@@Select[List@@r,!FreeQ[#,t]&];
  If[free=!=1,Return[Map[free #&,gplRationalLaurent[dependent,t]]]]];
 expanded=Expand[r,t];
 If[Head[expanded]===Plus,
  If[Length[expanded]>$gplMaxTerms,gplFail["GPLRationalTermCountLimit"]];
  Return[Merge[gplRationalLaurent[#,t]&/@List@@expanded,Total]]];
 q=Together[r];{num,den}=NumeratorDenominator[q];
 If[!PolynomialQ[num,t]||!PolynomialQ[den,t],gplFail["NonRationalGPLCoefficient"]];
 If[num===0,Return[<||>]];
 nv=Exponent[num,t,Min];dv=Exponent[den,t,Min];valuation=nv-dv;
 If[!IntegerQ[valuation],gplFail["IntegerGPLLocalOrderRequired"]];
 If[valuation>0,Return[<||>]];
 If[-valuation>$gplMaxEndpointOrder,gplFail["GPLEndpointExpansionLimit"]];
 count=-valuation;d0=Coefficient[den,t,dv];coefficients={};
 Do[AppendTo[coefficients,
   (Coefficient[num,t,nv+j]-Sum[
    Coefficient[den,t,dv+i]coefficients[[j-i+1]],{i,1,j}])/d0],
 {j,0,count}];
 AssociationThread[Range[valuation,0],coefficients]
];
gplAtZero[expression_,t_]:=Module[
 {words,terms=<||>,ell=Unique["logarithm"],finite,coefficient,add},
 words=gplWords[expression,t];
 add[key_,value_]:=AssociateTo[terms,key->(Lookup[terms,Key[key],0]+value)];
 KeyValueMap[Function[{word,rational},Module[{laurent,order,local},
  laurent=gplRationalLaurent[rational,t];
  If[Length[laurent]>0,
   order=Max[0,-Min[Keys[laurent]]];
   local=CoefficientRules[Expand[gplSeries[word,order,t]/.Log[t]->ell],{t,ell}];
   KeyValueMap[Function[{power,c},
    Do[If[power+rule[[1,1]]<=0,
      add[{power+rule[[1,1]],rule[[1,2]]},c Last[rule]]],
     {rule,local}]],laurent]]
 ]],words];
 finite=gplEndpointScalars[Lookup[terms,Key[{0,0}],0]];
 KeyValueMap[Function[{power,c},If[power=!={0,0},
  coefficient=Cancel[Together[gplEndpointScalars[c]]];
  (* Factored conjugate radical factors can hide an exact zero from
     rational cancellation. Expand only this candidate residual numerator;
     ordinary coefficient expressions remain compact. *)
  If[coefficient=!=0,
   coefficient=Cancel[Expand[Numerator[coefficient]]/Denominator[coefficient]]];
  If[coefficient=!=0,gplFail[
   If[TrueQ[coefficient!=0],"GPLLowerEndpointNotFinite","GPLEndpointCancellationNotEstablished"],
   <|"PowerAndLogarithm"->power,"Coefficient"->Short[coefficient]|>]]]],terms];
 If[!FreeQ[finite,t|ell|Indeterminate|_DirectedInfinity],
  gplFail["GPLLowerEndpointNotFinite",<|"EndpointValue"->Short[finite]|>]];
 finite
];
(* Definite integration here uses a regular upper matching point. Singular
   upper limits need GPL connection constants in a new local coordinate and
   cannot be replaced by a direct 0/0 substitution. The invariant caller
   supplies two endpoint-to-interior paths under its physical assumptions. *)
gplUpperValue[primitive_,t_,s_]:=Module[{value=primitive/.t->s},
 If[!FreeQ[value,Indeterminate|_DirectedInfinity],
  gplFail["RegularGPLUpperPointRequired",<|"UpperPoint"->s|>]];
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
(* Classical polylogarithms of a rational argument are pulled back by
   their differential equation, with the actual value at the lower endpoint.
   A nonzero basepoint is retained; dropping it would change the integral.
   The common real collinear charts have finite rational arguments there,
   including Li_n(1), n>1. Singular infinity branches require a prior explicit
   analytic continuation and are never inferred by PowerExpand. *)
gplNormalizeClassicalPolylogs[expression_,t_]:=Module[{objects,pull,rules},
 pull[1,r_]:=-gplNormalizeLogs[Log[1-r],t];
 pull[n_Integer,r_]/;n>1:=pull[n,r]=Module[{base,derivative,primitive},
  If[!gplRationalQ[r,t],gplFail["RationalClassicalPolylogarithmArgumentRequired"]];
  base=Quiet[Cancel[Cancel[r]/.t->0]];
  If[!FreeQ[base,Indeterminate|_DirectedInfinity],
   base=Quiet[Limit[r,t->0,Direction->"FromAbove"]]];
  If[!FreeQ[base,Indeterminate|_DirectedInfinity|_Limit],
   gplFail["FiniteClassicalPolylogarithmBasePointRequired",<|"Argument"->r|>]];
  derivative=Cancel[D[r,t]/r]pull[n-1,r];
  primitive=gplRationalPrimitive[derivative,t];
  primitive-gplAtZero[primitive,t]+PolyLog[n,base]
 ];
 objects=DeleteDuplicates[Cases[expression,
  z:PolyLog[n_Integer,r_]/;n>0&&!FreeQ[r,t],{0,Infinity}]];
 rules=Table[obj->pull[obj[[1]],Cancel[obj[[2]]]],{obj,objects}];
 expression/.rules
];
(* The integration recursion deliberately preserves sparse rational
   summands. Collect identical GPL atoms before a growing primitive becomes
   unwieldy and after finite upper-end substitution. This keeps explicit
   results compact by exact coefficient-field arithmetic. *)
(* Transcendental functions are explicit polynomial atoms here. Separate
   their coefficients before rational factorization, which otherwise expands
   one enormous polynomial in both kinematic variables and logarithms. This
   is an algebraic collection identity, not an assumed independence relation. *)
gplFactorCoefficient[coefficient_]:=Module[{atoms},
 atoms=DeleteDuplicates[Cases[coefficient,
  _Log|_PolyLog|_PolyGamma|_Zeta|System`EulerGamma,{0,Infinity}]];
 If[atoms==={},Factor[coefficient],Collect[coefficient,atoms,Factor]]
];
gplCollectCoefficients[expression_]:=Module[{objects},
 If[LeafCount[expression]<=1000,Return[expression]];
 objects=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 If[objects==={},gplFactorCoefficient[expression],
  Collect[expression,objects,gplFactorCoefficient]]
];
(* Share exact recurrence results only while assumptions and all mathematical
   limits agree. The outer scope restores every memo table on success, failure
   or timeout; standalone calls retain the same bounded lifetime. *)
SetAttributes[gplWithMemoization,HoldAll];
gplWithMemoization[settings_,body_]:=If[
 ValueQ[$gplMemoSettings]&&$gplMemoSettings===settings,body,
 Block[{$gplMemoSettings=settings},
  Internal`InheritedBlock[{gplShuffle,gplIntegrateWord,gplRationalDecomposition,
   gplRationalLaurent,gplSeries,gplEndpointLog,gplRefineRadical,gplPullbackWord},body]]];
gplRefineRadical[value_Power,assumptions_]:=gplRefineRadical[value,assumptions]=
 Refine[Factor[value[[1]]]^value[[2]],assumptions];
gplRefineConstantRadicals[expression_,t_]:=Module[{objects},
 If[!ValueQ[$gplAssumptions]||$gplAssumptions===True,Return[expression]];
 objects=DeleteDuplicates[Cases[expression,
  q:Power[_,power_Rational]/;Denominator[power]===2&&FreeQ[q,t],{0,Infinity}]];
 expression/.((#->gplRefineRadical[#,$gplAssumptions])&/@objects)
];
gplNormalizeRationalIntegrand[expression_,t_]:=Module[{normalized},
 normalized=gplNormalizeClassicalPolylogs[gplRefineConstantRadicals[expression,t],t];
 gplEndpointScalars[gplNormalizeLogs[gplNormalizeArguments[normalized,t],t]]
];
Options[FeynFacetSolution`IntegrateGPL]={
 "TimeLimit"->30,"Assumptions"->True,"MaxExpressionLeaves"->200000,"MaxTerms"->10000,
 "MaxWeight"->16,"MaxPoleDegree"->4,"MaxEndpointExpansionOrder"->32};
FeynFacetSolution`IntegrateGPL[expression_,{t_Symbol,0,s_},OptionsPattern[]]:=
 Block[{$gplAssumptions=OptionValue["Assumptions"],$gplMaxLeaves=OptionValue["MaxExpressionLeaves"],$gplMaxTerms=OptionValue["MaxTerms"],
  $gplMaxWeight=OptionValue["MaxWeight"],$gplMaxDegree=OptionValue["MaxPoleDegree"],
  $gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 gplWithMemoization[{$gplAssumptions,$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
 TimeConstrained[Catch[Module[{normalized,words,primitive,lower,result},
  If[!NumericQ[OptionValue["TimeLimit"]]||!TrueQ[OptionValue["TimeLimit"]>0],
    gplFail["InvalidGPLIntegrationOptions"]];
  If[!AllTrue[{$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
    IntegerQ[#]&&#>0&],gplFail["InvalidGPLIntegrationOptions"]];
  (* All memoization is confined to this conversion, with the current bounds. *)
  If[!FreeQ[expression,Power[base_,power_Rational]/;Denominator[power]===2&&!FreeQ[base,t]],
   Return[gplIntegrateQuadraticRoot[expression,t,s],Module]];
  normalized=gplNormalizeRationalIntegrand[expression,t];gplBound[normalized];
  words=gplWords[normalized,t];
  primitive=gplPrimitiveSum[KeyValueMap[gplIntegrateWord[#2,#1,t]&,words]];
  lower=gplAtZero[primitive,t];
  result=gplCollectCoefficients[gplUpperValue[primitive,t,s]-lower];gplBound[result];result
 ],"GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLIntegrationTimeLimit",<||>]]]];
