boundaryLaurentValuation[value_,eps_] := Module[{order=0,s},
 If[value===0,Return[Infinity]];
 While[order<=64,
  s=Quiet[Series[value,{eps,0,order}]];
  If[Head[s]===SeriesData&&s[[3]]=!={},Return[s[[4]]/s[[6]]]];
  If[FreeQ[s,eps],Return[0]];
  order=If[order===0,1,2 order]];
 boundaryIntegrationFail["BoundaryPrefactorValuationUnresolved"]];
