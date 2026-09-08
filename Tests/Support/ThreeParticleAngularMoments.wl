(* Independent four-dimensional angular representation for comparison. *)
FeynFacetTest`TwoPairAngularEulerTerms[alpha_,single_,complement_,pairPowerList_,constant_,variables_] := Module[
 {t=variables[[1]],u=variables[[2]],v=variables[[3]],w=variables[[4]],
 x,rr,hh,den,s12,s13,pairs,terms={},factors,pref},
 x={t,(1-t)u,(1-t)(1-u)};hh=w/(1-w);
 pref=constant 2 4^(alpha-1/2)/(Beta[alpha,alpha]Beta[1/2,alpha-1/2]);
 Do[
  rr=If[side===0,1-v,1/(1-v)];
  den=x[[2]]x[[3]]+x[[1]]rr^2;
  s12=(x[[1]]+x[[2]])x[[1]]rr^2/den;
  s13=x[[1]]x[[2]]x[[3]]((1-rr)^2+(1+rr)^2hh^2)/
       ((x[[1]]+x[[2]])den(1+hh^2));
  factors=Join[
    MapThread[{#1,alpha-1-#2}&,{x,single}],
    MapThread[{1-#1,-#2}&,{x,complement}],
    {{1-t,1},{Times@@x,alpha},{rr,2alpha-1},{den,-2alpha},
     {hh,2alpha-2},{1+hh^2,1-2alpha},{1-w,-2},
     {1-v,If[side===0,0,-2]},{s12,-pairPowerList[[1]]},{s13,-pairPowerList[[2]]}}];
  AppendTo[terms,Join[FeynFacet`Private`positiveRationalEulerTerm[variables,factors,pref],
   <|"ConditionalCoordinateMap"-><|"Rho"->x[[1]]rr^2/den,"RelativeCosine"->(hh^2-1)/(hh^2+1),
    "PairInvariantsDividedByRecoilMassSquared"->{s12,s13},"RadialRatio"->rr,
    "RadialInterval"->If[side===0,{0,1},{1,Infinity}]|>|>]],
 {side,0,1}];
 terms
];
