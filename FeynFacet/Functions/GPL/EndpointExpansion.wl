(* Positive rescaling and convergent local GPL expansions. The trailing-zero
   terms implement tangential-basepoint rescaling, rather than PowerExpand. *)
FeynFacetSolution`RescaleGPLArguments::usage="RescaleGPLArguments[expression,scale,assumptions] changes G[word,z] to GPLs with letters scale word and argument scale z for positive real scale, including all trailing-zero logarithms.";
FeynFacetSolution`ExpandGPLAtOrigin::usage="ExpandGPLAtOrigin[expression,{t,upper}] returns the explicit Laurent-logarithmic expansion through t^upper along t>0. GPL letters must be independent of t after normalization. The coefficients are finite polynomials in Log[t].";
FeynFacetSolution`RescaleGPLArguments[expression_,scale_,assumptions_:True]:=Catch[Module[
 {objects,rules,word,z,zeros},
 If[!TrueQ[FullSimplify[scale>0,Assumptions->assumptions]],
  gplFail["PositiveGPLArgumentRescalingRequired"]];
 objects=DeleteDuplicates[Cases[expression,_FeynFacetSolution`G,{0,Infinity}]];
 rules=Table[
  {word,z}=List@@object;
  If[!ListQ[word],gplFail["ExplicitGPLWordRequired"]];
  zeros=Length[TakeWhile[Reverse[word],#===0&]];
  object->Sum[(-Log[scale])^k/Factorial[k] gplMake[Cancel/@(scale Drop[word,-k]),scale z],
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
  If[!FreeQ[result,_Series|_SeriesData|_Derivative|_FeynFacetSolution`G|Indeterminate|_DirectedInfinity],
   gplFail["ExplicitGPLLocalExpansionRequired"]];
  result/.ell->Log[t]
 ],"GPLIntegration"],OptionValue["TimeLimit"],Failure["GPLLocalExpansionTimeLimit",<||>]]]];
