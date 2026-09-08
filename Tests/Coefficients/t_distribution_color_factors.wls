root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Coefficients/ColorDecomposition.wl"];
Clear[ca,cf,as,v,z];
d=<|"DataType"->"FiniteEndpointSubtractedDensity","EpsilonOrderRange"->{-1,0},
 "AlgebraicDefinitions"->{},"IntegralDefinitions"->{},"KernelDefinitions"->{},
 "DeltaTerms"->{<|"DerivativeOrder"->0,"Coefficients"-><|-1->as^4 pdf[v](ca^2+cf/ca),0->as^4 pdf[v] cf Log[v]|>|>},
 "PlusTerms"->{<|"Power"->-1,"LogPower"->0,"SubtractionOrder"->1,
 "Coefficients"-><|-1->0,0->as^4 pdf[v] ca^2/(1-v)|>|>},
 "RegularRemainderCoefficients"-><|-1->0,0->as^4 pdf[v](cf/ca*z+ca^2 Log[z])|>|>;
r=CollectDistributionColorFactors[d,<|"ColorVariables"->{ca,cf},"CouplingVariable"->as,"ExternalFactors"->{pdf[v]}|>];
FTAssert["color, coupling and external distribution factors are collected explicitly",
 AssociationQ[r]&&Sort[Lookup[r["ColorComponents"],"ColorFactor"]]===Sort[{ca^2,cf/ca,cf}]&&
 Union[Lookup[r["ColorComponents"],"CouplingPower"]]==={4}&&Union[Lookup[r["ColorComponents"],"ExternalFactor"]]==={pdf[v]}];
FTAssert["all three distribution categories reconstruct the original expressions",
 And@@Flatten[Table[
  expression=Switch[kind,"Regular",#["RegularRemainderCoefficients"][q],
   _,First[#[kind<>"Terms"]]["Coefficients"][q]]&;
  reconstructed=Total[#["ColorFactor"] as^#["CouplingPower"] #["ExternalFactor"] expression[#]&/@r["ColorComponents"]];
  original=If[kind==="Regular",d["RegularRemainderCoefficients"][q],First[d[kind<>"Terms"]]["Coefficients"][q]];
  Together[reconstructed-original]===0,{kind,{"Delta","Plus","Regular"}},{q,-1,0}]]];
FTAssert["nonmonomial color denominators are not silently Taylor expanded",
 FailureQ[CollectDistributionColorFactors[Join[d,<|"RegularRemainderCoefficients"-><|0->1/(ca+cf)|>|>],
  <|"ColorVariables"->{ca,cf}|>]]];
interned=Join[d,<|"AlgebraicDefinitions"->{as^4 pdf[v],FeynFacetSolution`a[1] ca^2},
 "RegularRemainderCoefficients"-><|-1->0,0->FeynFacetSolution`a[2] z|>|>];
ir=CollectDistributionColorFactors[interned,<|"ColorVariables"->{ca,cf},"CouplingVariable"->as,"ExternalFactors"->{pdf[v]}|>];
colorValues={};
Do[AppendTo[colorValues,expression/.FeynFacetSolution`a[j_Integer]:>colorValues[[j]]],
 {expression,ir["AlgebraicDefinitions"]}];
FTAssert["color-dependent algebraic definitions are expanded and original definitions are preserved",
 AssociationQ[ir]&&ir["ExpandedColorDependentAlgebraicDefinitions"]==={1,2}&&
 ir["AlgebraicDefinitions"]===interned["AlgebraicDefinitions"]&&
 Together[(Total[#["ColorFactor"] as^#["CouplingPower"] #["ExternalFactor"] #["RegularRemainderCoefficients"][0]&/@ir["ColorComponents"]]/.
  FeynFacetSolution`a[j_Integer]:>colorValues[[j]])-as^4 pdf[v] ca^2 z]===0];
parallel=CollectDistributionColorFactors[interned,<|"ColorVariables"->{ca,cf},"CouplingVariable"->as,
 "ExternalFactors"->{pdf[v]},"Workers"->2|>];
FTAssert["parallel collection preserves every scalar factor and closes its workers",
 parallel["ColorComponents"]===ir["ColorComponents"]&&Kernels[]==={}];
freeFunction=Join[d,<|"AlgebraicDefinitions"->{v},
 "RegularRemainderCoefficients"-><|-1->0,0->ca Log[FeynFacetSolution`a[1]]|>|>];
fr=CollectDistributionColorFactors[freeFunction,<|"ColorVariables"->{ca,cf}|>];
FTAssert["functions of color-independent shared coefficients remain valid coefficient functions",
 AssociationQ[fr]&&AnyTrue[fr["ColorComponents"],#["ColorFactor"]===ca&&
   #["RegularRemainderCoefficients"][0]===Log[FeynFacetSolution`a[1]]&]];
cyclic=Join[interned,<|"AlgebraicDefinitions"->{ca FeynFacetSolution`a[1]}|>];
FTAssert["cyclic color definitions are rejected",FailureQ[CollectDistributionColorFactors[cyclic,<|"ColorVariables"->{ca,cf}|>]]];
outside=Join[d,<|"RegularRemainderCoefficients"-><|0->ca FeynFacetSolution`a[999]|>|>];
FTAssert["missing shared color definitions cannot silently become independent coefficients",
 FailureQ[CollectDistributionColorFactors[outside,<|"ColorVariables"->{ca,cf}|>]]];

endpointFactorData=Join[d,<|"NormalVariable"->z,"DimensionalRegulator"->eps|>];
FTAssert["factors depending on the endpoint variable cannot be pulled outside distributions",
 MatchQ[CollectDistributionColorFactors[endpointFactorData,
 <|"ColorVariables"->{ca,cf},"ExternalFactors"->{pdf[z]}|>],
 Failure["RegulatorAndEndpointIndependentFactorsRequired",_]]];
FTAssert["factors depending on epsilon cannot label Laurent coefficients",
 MatchQ[CollectDistributionColorFactors[endpointFactorData,<|"ColorVariables"->{eps}|>],
 Failure["RegulatorAndEndpointIndependentFactorsRequired",_]]];
FTAssert["a shared definition cannot hide epsilon from color collection",
 MatchQ[CollectDistributionColorFactors[Join[endpointFactorData,<|"AlgebraicDefinitions"->{1+eps}|>],
 <|"ColorVariables"->{ca,cf}|>],Failure["EpsilonIndependentAlgebraicCoefficientsRequired",_]]];
FTReport[];

