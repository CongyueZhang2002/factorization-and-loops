(* Positive rescaling and convergent local GPL expansions. The trailing-zero
   terms implement tangential-basepoint rescaling, rather than PowerExpand. *)
FeynFacetSolution`RescaleGPLArguments::usage="RescaleGPLArguments[expression,scale,assumptions] changes G[word,z] to GPLs with letters scale word and argument scale z for positive real scale, including all trailing-zero logarithms.";
FeynFacetSolution`ExpandGPLAtOrigin::usage="ExpandGPLAtOrigin[expression,{t,upper}] returns the explicit Laurent-logarithmic expansion through t^upper along t>0. GPL letters must be independent of t after normalization. The coefficients are finite polynomials in Log[t].";
FeynFacetSolution`ExpandGPLAtFiniteEndpoint::usage="ExpandGPLAtFiniteEndpoint[expression,{x,a},{rho,upper}] expands at x=a-rho with a>0 and rho approaching zero from above. It uses path composition and shuffle-regularized endpoint constants, preserving tangential logarithms and trailing zeros. Nonzero GPL letters on the open path (0,a), or unresolved letter collisions, are refused. Constants are convergent GPLs at one; no independent contour prescription is chosen.";
FeynFacetSolution`RegularizeGPLTrailingZeros::usage="RegularizeGPLTrailingZeros[expression] removes trailing zero letters using the exact shuffle identity and G[{0},z]=Log[z]. In particular it resolves identities involving GPL constants at argument one without treating the different words as algebraically independent.";
FeynFacetSolution`ReduceGPLWeightOne::usage="ReduceGPLWeightOne[expression,assumptions] replaces one-letter GPLs by their logarithms only when the positive endpoint and absence of a letter on the integration segment establish the principal branch. Other GPLs are retained.";
FeynFacetSolution`ReduceGPLWeightTwo::usage="ReduceGPLWeightTwo[expression] uses the shuffle identity to express weight-two GPLs in deterministically ordered letter pairs and products of weight-one GPLs. Equal letters give one half of the square. This is an algebraic identity on the same path and does not select a new branch.";
FeynFacetSolution`ReduceGPLWeightTwo[expression_]:=Expand[expression/.
 FeynFacetSolution`G[{a_,b_},z_]:>Which[a===b,FeynFacetSolution`G[{a},z]^2/2,
  OrderedQ[{a,b}],FeynFacetSolution`G[{a,b},z],
  True,FeynFacetSolution`G[{a},z]FeynFacetSolution`G[{b},z]-FeynFacetSolution`G[{b,a},z]]];
FeynFacetSolution`RegularizeGPLTrailingZeros[expression_]:=Module[{regularize,objects,result},
 regularize[word_List,z_]:=regularize[word,z]=Module[{rest,shuffles,count,others},
  Which[word==={},1,AllTrue[word,#===0&],If[word==={},1,Log[z]^Length[word]/Factorial[Length[word]]],
   Last[word]=!=0,FeynFacetSolution`G[word,z],
   True,rest=Most[word];shuffles=Insert[rest,0,#]&/@Range[Length[rest]+1];
   count=Count[shuffles,word];others=DeleteCases[shuffles,word];
   (regularize[rest,z]Log[z]-Total[regularize[#,z]&/@others])/count]];
 objects=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 result=expression/.((#->regularize[First[#],Last[#]])&/@objects);
 Clear[regularize];result
];
FeynFacetSolution`ReduceGPLWeightOne[expression_,assumptions_:True]:=Module[{objects,rules,a,z,value},
 objects=DeleteDuplicates[Cases[expression,FeynFacetSolution`G[{_},_],{0,Infinity}]];
 rules=Table[a=First[First[g]];z=Last[g];
  value=Which[a===0,Log[z],
   TrueQ[Refine[z>0&&(!Element[a,Reals]||a<0||a>z),assumptions]],
    If[NumericQ[1-z/a],ComplexExpand[Log[Cancel[1-z/a]]],Log[Cancel[1-z/a]]],
   True,g];g->value,{g,objects}];expression/.rules
];
FeynFacetSolution`RescaleGPLArguments[expression_,scale_,assumptions_:True]:=Catch[Module[
 {objects,rules,word,z,zeros},
 If[!TrueQ[FullSimplify[scale>0,Assumptions->assumptions]],
  gplFail["PositiveGPLArgumentRescalingRequired"]];
 objects=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 rules=Table[
  {word,z}=List@@object;
  If[!ListQ[word],gplFail["ExplicitGPLWordRequired"]];
  zeros=Length[TakeWhile[Reverse[word],#===0&]];
  object->Sum[If[k===0,1,(-Log[scale])^k/Factorial[k]] gplMake[Cancel/@(scale Drop[word,-k]),scale z],
    {k,0,zeros}],{object,objects}];
 expression/.rules
],"GPLIntegration"];
Options[FeynFacetSolution`ExpandGPLAtOrigin]={
 "TimeLimit"->60,"MaxTerms"->20000,"MaxWeight"->16,"MaxEndpointExpansionOrder"->32,"Assumptions"->True};
(* A fixed finite path permits a uniform limit of rational parameter letters
   that remain separated from the path. Letters tending to infinity contribute
   a vanishing kernel. Reject poles in their multiplying coefficients: a limit
   alone cannot determine the derivatives then required. Fixed zero letters
   retain their tangential convention; moving letters colliding with zero or
   the endpoint require a different local expansion. *)
gplFixedPathParameterLimit[expression_,t_]:=Module[
 {objects,atoms,polynomial,terms,limits,letterLimit,wordLimit,coefficientLimit,
  coefficients,local,ell=Unique["parameterLog"],powers,word,z,limitsForWord},
 objects=DeleteDuplicates[Cases[expression,g:FeynFacetSolution`G[w_List,a_]/;
   !FreeQ[w,t]&&FreeQ[a,t]:>g,{0,Infinity}]];
 If[objects==={},Return[expression]];
 letterLimit[a_]:=letterLimit[a]=Module[{q=Cancel[Together[a]],v,value,nd,orders,leading,specialize},
  If[FreeQ[q,t],Return[q]];
  If[!PolynomialQ[Numerator[q],t]||!PolynomialQ[Denominator[q],t],
   gplFail["RationalFixedPathGPLLettersRequired"]];
  specialize[p_]:=Sum[With[{coefficient=Coefficient[p,t,j]},
    If[TrueQ[Refine[coefficient==0,$gplAssumptions]],0,coefficient]t^j],
    {j,0,Max[0,Exponent[p,t]]}];
  nd=specialize/@NumeratorDenominator[q];
  If[Last[nd]===0,gplFail["FixedPathGPLLetterDenominatorVanishes"]];
  q=Cancel[First[nd]/Last[nd]];
  If[FreeQ[q,t],Return[q]];
  nd=NumeratorDenominator[q];orders=Exponent[#,t,Min]&/@nd;
  leading=MapThread[Coefficient[#1,t,#2]&,{nd,orders}];
  If[!AllTrue[leading,TrueQ[Refine[#!=0&&Element[#,Complexes],$gplAssumptions]]&],
   gplFail["FixedPathGPLLetterLeadingCoefficientNotEstablished"]];
  v=Subtract@@orders;
  If[v<0,Return[DirectedInfinity[]]];
  value=If[v>0,0,Cancel[SeriesCoefficient[q,{t,0,0}]]];value];
 wordLimit[g_]:=Module[{},
  {word,z}=List@@g;
  If[!TrueQ[Refine[z>0,$gplAssumptions]],gplFail["PositiveFixedGPLPathRequired"]];
  limitsForWord=letterLimit/@word;
  If[!And@@MapThread[Function[{a,b},
    If[FreeQ[a,t]&&a===0,True,
     b===DirectedInfinity[]||TrueQ[Refine[!Element[b,Reals]||b<0||b>z,$gplAssumptions]]]],
    {word,limitsForWord}],gplFail["GPLParameterLetterCollidesWithFixedPath"]];
  If[MemberQ[limitsForWord,DirectedInfinity[]],0,gplMake[limitsForWord,z]]];
 limits=wordLimit/@objects;atoms=Table[Unique["parameterGPL"],Length[objects]];
 polynomial=expression/.Thread[objects->atoms];
 If[!PolynomialQ[polynomial,atoms],gplFail["PolynomialFixedPathGPLDependenceRequired"]];
 terms=CoefficientRules[polynomial,atoms];
 coefficientLimit[c_]:=coefficientLimit[c]=Module[{expanded},
  expanded=FeynFacetSolution`ExpandGPLAtOrigin[c,{t,0},"Assumptions"->$gplAssumptions,
   "TimeLimit"->30,"MaxTerms"->$gplMaxTerms,"MaxWeight"->$gplMaxWeight,
   "MaxEndpointExpansionOrder"->$gplMaxEndpointOrder];
  If[FailureQ[expanded],Throw[expanded,"GPLIntegration"]];
  local=Expand[expanded/.Log[t]->ell];
  If[local=!=0&&Exponent[local,t,Min]<0,
   gplFail["FixedPathGPLParameterJetRequired"]];expanded];
 Total[Map[Function[term,powers=First[term];
   If[Total[powers]===0,Last[term],
    coefficientLimit[Last[term]] (Times@@MapThread[If[#2===0,1,#1^#2]&,{limits,powers}])]],terms]]
];
(* Classical local series need no global rational pullback. Accept only an
   explicit integer-power Laurent polynomial with polynomial logarithms;
   unresolved special functions of t fall back to the GPL construction. *)
gplDirectClassicalLocalSeries[expression_,t_,upper_]:=Module[
 {answer,ell=Unique["classicalLocalLog"],q,low},
 If[!FreeQ[expression,g_FeynFacetSolution`G/;!FreeQ[g,t]],Return[$Failed]];
 answer=TimeConstrained[Quiet[Assuming[$gplAssumptions&&t>0,
   Normal[Series[expression,{t,0,upper}]]]],5,$Failed];
 If[answer===$Failed||!FreeQ[answer,_Series|_SeriesData|_Derivative|Indeterminate|_DirectedInfinity],
  Return[$Failed]];
 q=Cancel[Together[answer/.Log[t]->ell]];
 low=Exponent[Numerator[q],t,Min]-Exponent[Denominator[q],t,Min];
 If[answer===0,Return[0]];
 If[!IntegerQ[low]||!PolynomialQ[Cancel[t^Max[0,-low] q],{t,ell}],Return[$Failed]];
 q/.ell->Log[t]
];
FeynFacetSolution`ExpandGPLAtOrigin[expression_,{t_Symbol,upper_Integer},OptionsPattern[]]:=
 Block[{$gplAssumptions=OptionValue["Assumptions"],$gplMaxLeaves=1000000,$gplMaxTerms=OptionValue["MaxTerms"],$gplMaxWeight=OptionValue["MaxWeight"],
  $gplMaxDegree=4,$gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 gplWithMemoization[{$gplAssumptions,$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
 TimeConstrained[Catch[Module[{normalized,words,bounds,depth,poly,ell=Unique["localLogarithm"],result},
  normalized=If[upper===0,gplFixedPathParameterLimit[expression,t],expression];
  result=gplDirectClassicalLocalSeries[normalized,t,upper];
  If[result=!=$Failed,Return[result,Module]];
  normalized=gplNormalizeRationalIntegrand[normalized,t];
  words=gplWords[normalized,t];
  bounds=Map[Function[c,With[{q=Cancel[Together[c]]},
   If[q===0,Infinity,Exponent[Numerator[q],t,Min]-Exponent[Denominator[q],t,Min]]]],Values[words]];
  If[!AllTrue[bounds,IntegerQ[#]||#===Infinity&],gplFail["RationalGPLCoefficientValuationsRequired"]];
  depth=Max[0,upper-Min[Append[bounds,0]]];
  If[depth>$gplMaxEndpointOrder,gplFail["GPLEndpointExpansionLimit"]];
  poly=Total[KeyValueMap[#2 gplSeries[#1,depth,t]&,words]]/.Log[t]->ell;
  result=Cancel[Together[Normal[Series[poly,{t,0,upper}]]]];
  If[!FreeQ[result,_Series|_SeriesData|_Derivative|Indeterminate|_DirectedInfinity]||
     !FreeQ[result,g_FeynFacetSolution`G/;!FreeQ[g,t]],
   gplFail["ExplicitGPLLocalExpansionRequired"]];
  result/.ell->Log[t]
 ],"GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLLocalExpansionTimeLimit",<||>]]]];

Options[FeynFacetSolution`ExpandGPLAtFiniteEndpoint]=Options[FeynFacetSolution`ExpandGPLAtOrigin];
FeynFacetSolution`ExpandGPLAtFiniteEndpoint[expression_,{x_Symbol,a_},
 {rho_Symbol,upper_Integer},OptionsPattern[]]:=Module[
 {regularized,reflect,continue,normalized,objects,letters,rules,result,
  assumptions=OptionValue["Assumptions"],seconds=OptionValue["TimeLimit"]},
 If[!NumericQ[seconds]||!TrueQ[seconds>0],
  Return[Failure["InvalidGPLIntegrationOptions",<||>]]];
 result=TimeConstrained[Catch[Block[{$gplAssumptions=assumptions,$gplMaxLeaves=1000000,
   $gplMaxTerms=OptionValue["MaxTerms"],$gplMaxWeight=OptionValue["MaxWeight"],
   $gplMaxDegree=4,$gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 gplWithMemoization[{$gplAssumptions,$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
  If[!AllTrue[{$gplMaxTerms,$gplMaxWeight,$gplMaxEndpointOrder},IntegerQ[#]&&#>0&],
   gplFail["InvalidGPLIntegrationOptions"]];
  If[x===rho||!FreeQ[a,x|rho]||!TrueQ[Refine[a>0,assumptions]],
   gplFail["PositiveFixedGPLMatchingEndpointRequired"]];
  normalized=gplNormalizeRationalIntegrand[expression,x];
  objects=DeleteDuplicates[Cases[normalized,g:FeynFacetSolution`G[w_List,x]:>g,{0,Infinity}]];
  letters=DeleteDuplicates[Flatten[First/@objects]];
  If[!AllTrue[letters,FreeQ[#,x|rho]&&TrueQ[Refine[
      !Element[#,Reals]||#<=0||#>=a,assumptions]]&],
   gplFail["GPLLetterInsideMatchingPathOrDomainUnresolved"]];
  (* Reg[G[1,1]]=0 uses the dimensionless tangent 1-x. A leading
     endpoint letter is removed by shuffle, keeping finite endpoint words. *)
  regularized[word_List]:=regularized[word]=Module[{rest,shuffles,count,others},
   Which[word==={},1,
    AllTrue[word,#===0&]||AllTrue[word,#===1&],0,
    First[word]=!=1,
     If[!TrueQ[Refine[First[word]!=1,assumptions]],
      gplFail["EndpointGPLLetterCollisionNotResolved"]];FeynFacetSolution`G[word,1],
    True,rest=Rest[word];shuffles=Insert[rest,1,#]&/@Range[Length[rest]+1];
     count=Count[shuffles,word];others=DeleteCases[shuffles,word];
     -Total[regularized/@others]/count]];
  reflect[word_List]:=reflect[word]=Sum[
    gplMake[1-Take[word,k],rho/a]regularized[Drop[word,k]],{k,0,Length[word]}];
  (* First scale x/a, including all trailing-zero shifts, then compose
     the path with its reflected final segment. Coefficients are unchanged. *)
  continue[word_List]:=Sum[If[k===0,1,Log[a]^k/Factorial[k]]*
    reflect[Cancel/@(Drop[word,-k]/a)],
    {k,0,Length[TakeWhile[Reverse[word],#===0&]]}];
  rules=(#->continue[First[#]])&/@objects;
  normalized=(normalized/.rules)/.x->a-rho;
  FeynFacetSolution`ExpandGPLAtOrigin[normalized,{rho,upper},
   "Assumptions"->assumptions,
   "TimeLimit"->seconds,"MaxTerms"->OptionValue["MaxTerms"],
   "MaxWeight"->OptionValue["MaxWeight"],
   "MaxEndpointExpansionOrder"->OptionValue["MaxEndpointExpansionOrder"]]
 ]],"GPLIntegration"],seconds,Failure["GPLFiniteEndpointExpansionTimeLimit",<||>]];
 Clear[regularized,reflect,continue];result
];

FeynFacetSolution`IntegrateGPLHadamardFinitePart::usage=
 "IntegrateGPLHadamardFinitePart[expression,{x,0,a},options] integrates a rational/GPL expression by extracting the constant power-and-log terms of its primitive at both endpoints. The cutoffs use the coordinates x and a-x. This is a Hadamard finite part; dimensional pole corrections and physical admissibility are separate inputs.";
Options[FeynFacetSolution`IntegrateGPLHadamardFinitePart]=Options[FeynFacetSolution`IntegrateGPL];
FeynFacetSolution`IntegrateGPLHadamardFinitePart[expression_,{x_Symbol,0,a_},OptionsPattern[]]:=
 Block[{$gplAssumptions=OptionValue["Assumptions"],$gplMaxLeaves=OptionValue["MaxExpressionLeaves"],
  $gplMaxTerms=OptionValue["MaxTerms"],$gplMaxWeight=OptionValue["MaxWeight"],
  $gplMaxDegree=OptionValue["MaxPoleDegree"],$gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 gplWithMemoization[{$gplAssumptions,$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
 TimeConstrained[Catch[Module[{normalized,words,primitive,lower,upper,rho=Unique["endpointDistance"],
   ell=Unique["endpointLogarithm"],constant,options,denominators,pole},
  If[!NumericQ[OptionValue["TimeLimit"]]||!TrueQ[OptionValue["TimeLimit"]>0]||
    !AllTrue[{$gplMaxLeaves,$gplMaxTerms,$gplMaxWeight,$gplMaxDegree,$gplMaxEndpointOrder},
      IntegerQ[#]&&#>0&],gplFail["InvalidGPLIntegrationOptions"]];
  If[!FreeQ[a,x]||!TrueQ[Refine[a>0,$gplAssumptions]],
   gplFail["PositiveFixedGPLMatchingEndpointRequired"]];
  normalized=gplNormalizeRationalIntegrand[expression,x];words=gplWords[normalized,x];gplBound[words];
  denominators=DeleteDuplicates[Denominator[Together[#]]&/@Values[words]];
  Do[If[FreeQ[denominator,x],Continue[]];
   pole=With[{variable=x,den=denominator,endpoint=a},
    Resolve[Exists[{variable},0<variable<endpoint&&den==0],Reals]];
   If[!TrueQ[Refine[!pole,$gplAssumptions]],
    gplFail["GPLRationalPoleInsideFinitePartPathOrDomainUnresolved"]],{denominator,denominators}];
  primitive=gplCollectCoefficients[gplPrimitiveSum[KeyValueMap[gplIntegrateWord[#2,#1,x]&,words]],True];
  options={"TimeLimit"->OptionValue["TimeLimit"],"MaxTerms"->$gplMaxTerms,
   "MaxWeight"->$gplMaxWeight,"MaxEndpointExpansionOrder"->$gplMaxEndpointOrder};
  lower=FeynFacetSolution`ExpandGPLAtOrigin[primitive,{x,0},"Assumptions"->$gplAssumptions,Sequence@@options];
  upper=FeynFacetSolution`ExpandGPLAtFiniteEndpoint[primitive,{x,a},{rho,0},
   "Assumptions"->$gplAssumptions,Sequence@@options];
  If[FailureQ[lower],Throw[lower,"GPLIntegration"]];
  If[FailureQ[upper],Throw[upper,"GPLIntegration"]];
  constant[value_,variable_]:=Coefficient[Coefficient[
    Expand[value/.Log[variable]->ell],variable,0],ell,0];
  <|"DataType"->"GPLHadamardFinitePart","Value"->
    gplCollectCoefficients[constant[upper,rho]-constant[lower,x],True],
   "Primitive"->primitive,"LowerEndpointExpansion"->lower,"UpperEndpointExpansion"->upper,
   "LowerCoordinate"->x,"UpperCoordinate"->rho,"UpperCoordinateDefinition"->(rho->a-x),
   "MeromorphicDimensionalIntegralEstablished"->False|>
 ],"GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLHadamardFinitePartTimeLimit",<||>]]]];
