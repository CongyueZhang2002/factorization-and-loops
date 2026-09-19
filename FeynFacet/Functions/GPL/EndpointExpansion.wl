(* Positive rescaling and convergent local GPL expansions. The trailing-zero
   terms implement tangential-basepoint rescaling, rather than PowerExpand. *)
FeynFacetSolution`RescaleGPLArguments::usage="RescaleGPLArguments[expression,scale,assumptions] changes G[word,z] to GPLs with letters scale word and argument scale z for positive real scale, including all trailing-zero logarithms.";
FeynFacetSolution`ExpandGPLAtOrigin::usage="ExpandGPLAtOrigin[expression,{t,upper}] returns the explicit Laurent-logarithmic expansion through t^upper along t>0. GPL letters must be independent of t after normalization. The coefficients are finite polynomials in Log[t].";
FeynFacetSolution`ExpandGPLAtFiniteEndpoint::usage="ExpandGPLAtFiniteEndpoint[expression,{x,a},{rho,upper}] expands at x=a-rho with a>0 and rho approaching zero from above. It uses path composition and shuffle-regularized endpoint constants, preserving tangential logarithms and trailing zeros. Nonzero GPL letters on the open path (0,a), or unresolved letter collisions, are refused. Constants are convergent GPLs at one; no independent contour prescription is chosen.";
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
 "TimeLimit"->60,"MaxTerms"->20000,"MaxWeight"->16,"MaxEndpointExpansionOrder"->32};
FeynFacetSolution`ExpandGPLAtOrigin[expression_,{t_Symbol,upper_Integer},OptionsPattern[]]:=
 Block[{$gplMaxLeaves=1000000,$gplMaxTerms=OptionValue["MaxTerms"],$gplMaxWeight=OptionValue["MaxWeight"],
  $gplMaxDegree=4,$gplMaxEndpointOrder=OptionValue["MaxEndpointExpansionOrder"]},
 Internal`InheritedBlock[{gplShuffle,gplIntegrateWord,gplRationalDecomposition,gplSeries},
 TimeConstrained[Catch[Module[{normalized,words,bounds,depth,poly,ell=Unique["localLogarithm"],result},
  normalized=gplNormalizeLogs[gplNormalizeArguments[expression,t],t];
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

Options[FeynFacetSolution`ExpandGPLAtFiniteEndpoint]=Join[
 Options[FeynFacetSolution`ExpandGPLAtOrigin],{"Assumptions"->True}];
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
   "TimeLimit"->seconds,"MaxTerms"->OptionValue["MaxTerms"],
   "MaxWeight"->OptionValue["MaxWeight"],
   "MaxEndpointExpansionOrder"->OptionValue["MaxEndpointExpansionOrder"]]
 ]],"GPLIntegration"],seconds,Failure["GPLFiniteEndpointExpansionTimeLimit",<||>]];
 Clear[regularized,reflect,continue];result
];
