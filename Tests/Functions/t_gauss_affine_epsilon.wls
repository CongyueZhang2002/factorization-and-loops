Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[root<>"/FeynFacet/Solution.m"];
Do[
 pars={1+slopes[[1]]ge,1+slopes[[2]]ge,2+slopes[[3]]ge};
 coefficients=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[pars,gz,ge,3];
 polynomial=Total[KeyValueMap[ge^#1 #2&,coefficients]];
 values=Table[FeynFacetSolution`EvaluateGPLExpression[polynomial,{gz->point,ge->1/10000},"WorkingPrecision"->40],
  {point,{1/4,2/3}}];
 references=Table[N[Hypergeometric2F1[Sequence@@pars,point]/.ge->1/10000,40],{point,{1/4,2/3}}];
 If[!VectorQ[values,NumberQ],Print[InputForm[values]]];
 FTTest`FTAssert["affine Gauss coefficients agree with independent numerical functions "<>ToString[slopes],
  VectorQ[values,NumberQ]&&Max[Abs[values-references]]<10^-13],
 {slopes,{{-2,-2,-4},{0,1,3},{2,0,-1},{0,0,0}}}];
zero=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{1,1,2},gz,ge,3];
FTTest`FTAssert["vanishing regulator slopes give the exact logarithm and no spurious orders",
 FullSimplify[zero[0]+Log[1-gz]/gz,0<gz<1]===0&&Values[KeyDrop[zero,0]]==={0,0,0}];
FTTest`FTAssert["the resonant endpoint is not confused with a finite value",
 FailureQ[FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[{1-2ge,1-2ge,2-4ge},1,ge,3]]];
FTTest`FTAssert["the expansion stores explicit finite GPL expressions",
 FreeQ[coefficients,_Integrate|_Inactive|_Sum|_Product|_Hypergeometric2F1|_SeriesCoefficient]];
Do[
 pars=integers+{-2,-2,-4}ge;
 coefficients=FeynFacetSolution`GaussHypergeometricEpsilonCoefficients[pars,gz,ge,3];
 polynomial=Total[KeyValueMap[ge^#1 #2&,coefficients]];
 value=FeynFacetSolution`EvaluateGPLExpression[polynomial,{gz->1/3,ge->1/10000},"WorkingPrecision"->40];
 reference=N[Hypergeometric2F1[Sequence@@pars,1/3]/.ge->1/10000,40];
 FTTest`FTAssert["integer contiguous transformations preserve the independently evaluated function "<>ToString[integers],
  NumberQ[value]&&Abs[value-reference]<10^-13],
 {integers,{{1,1,3},{2,1,3},{1,2,4},{2,2,2}}}];
Print["AFFINE GAUSS EPSILON TEST COMPLETE"];
FTTest`FTReport[];
