$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Algebra/AffinePartialFractions.wl"];
afRecompose[result_]:=Total[(#["Coefficient"]Times@@(result["Denominators"]^(-#["Powers"])))&/@result["Terms"]];
afCases={
 {{afX,1-afX},{2,3},{afX}},
 {{afX,afY,afX+afY},{2,1,2},{afX,afY}},
 {{afX,afY,afX+afY,afX-afY,afA-afX},{1,1,1,1,2},{afX,afY}},
 {{2afX,3afX},{1,2},{afX}},
 {{afA,afX,afY},{3,2,1},{afX,afY}},
 {{afX,afY,afX+afY-afA,afX+afY-afB},{1,2,1,2},{afX,afY}},
 {{afX,afY},{0,0},{afX,afY}}
};
afResults=FeynFacet`PartialFractionAffineDenominators@@#&/@afCases;
MapIndexed[FTTest`FTAssert["exact multivariate identity "<>ToString[First[#2]],
 AssociationQ[#1]&&Cancel[Together[afRecompose[#1]-Times@@(afCases[[First[#2],1]]^(-afCases[[First[#2],2]]))]]===0]&,afResults];
FTTest`FTAssert["every output support has independent linear parts",
 And@@Map[Function[result,And@@Map[Function[term,
  With[{active=Pick[result["Denominators"],(#>0&/@term["Powers"])]},
   active==={}||MatrixRank[Table[Coefficient[p,v],{p,active},{v,result["Variables"]}]]===Length[active]]],result["Terms"]]],afResults]];
FTTest`FTAssert["only the original loop denominator polynomials occur",
 And@@MapThread[#1["Denominators"]===#2[[1]]&&#1["NewLoopDependentDenominators"]===False&,{afResults,afCases}]];
FTTest`FTAssert["external exceptional loci are retained",
 !TrueQ[afResults[[6]]["ValidityConditions"]/.afB->afA]];
FTTest`FTAssert["a vanishing homogeneous denominator is rejected",
 FailureQ[FeynFacet`PartialFractionAffineDenominators[{0,afX},{1,1},{afX}]]];
FTTest`FTAssert["non-affine denominators are rejected",
 FailureQ[FeynFacet`PartialFractionAffineDenominators[{afX^2,afY},{1,1},{afX,afY}]]];
FTTest`FTReport[];
