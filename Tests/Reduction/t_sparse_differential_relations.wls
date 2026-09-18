Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
base=<|"KinematicVariables"->{rx},"DimensionalRegulator"->re,"DimensionRule"->D->4-2re|>;
sys[m_]:=Join[base,<|"ConnectionMatrices"->{m}|>];
missed=FeynFacet`RestrictDifferentialSystemToRelations[sys[ConstantArray[0,{3,3}]],
 {{1,0,0},{0,(rx-1/3)(rx-2/5),0}},
 <|"ValidationPoints"->{{rx->1/3,D->5},{rx->2/5,D->7}}|>];
FTTest`FTAssert["exact containment recovers a relation missed by every rational sample",
 AssociationQ[missed]&&missed["Dimension"]===1&&missed["FreeColumns"]==={3}];
chain=FeynFacet`RestrictDifferentialSystemToRelations[
 sys[{{0,1,0,0},{0,0,1,0},{0,0,0,0},{0,0,0,0}}],{{1,0,0,0}},
 <|"ValidationPoints"->{{rx->1/3,D->5}}|>];
FTTest`FTAssert["successive differential consequences close before stopping",
 AssociationQ[chain]&&chain["FreeColumns"]==={4}&&
 Lookup[chain["RelationClosure"]["History"],"RelationRank"]==={1,2,3,3}];
moving=FeynFacet`RestrictDifferentialSystemToRelations[sys[ConstantArray[0,{3,3}]],
 {{rx,1,0}},<|"ValidationPoints"->{{rx->1/3,D->5}}|>];
FTTest`FTAssert["derivatives of coordinate-dependent relation coefficients are retained",
 AssociationQ[moving]&&moving["FreeColumns"]==={3}];
FTTest`FTAssert["inconsistent D and epsilon samples are rejected",
 FailureQ[FeynFacet`RestrictDifferentialSystemToRelations[sys[{{0,0},{0,0}}],{{1,0}},
  <|"ValidationPoints"->{{rx->1/3,D->5,re->1/7}}|>]]];
FTTest`FTAssert["a corrupted embedding fails the actual differential identity",
 !AllTrue[Flatten[FeynFacet`Private`globalDEEmbeddingResidual[
  {{{0,0},{0,0}}},{{rx},{1}},{{{0}}},{rx}]],#===0&]];
ri=FeynCalc`GLI[rf,{1,0}];rj=FeynCalc`GLI[rf,{0,1}];rk=FeynCalc`GLI[rf,{1,1}];
family=<|"Topology"->FeynCalc`FCTopology[rf,{}, {}, {}, {}, {}]|>;
matrix={{0,1,0},{0,D,0},{D,0,0}};
results=Table[FeynFacet`ReduceMasterDifferentialSystem[
 Join[base,<|"MasterIntegralBasis"->{ri,rj,rk},"Families"->{family},
  "ConnectionMatrices"->{representation[matrix]}|>],
 <|"Masters"->{ri,rj},"Rules"->{rk->ri}|>,
 <|"CloseDifferentialRelations"->True,"ValidationPoints"->{{rx->1/3,D->5}}|>],
 {representation,{Identity,SparseArray}}];
FTTest`FTAssert["dense and sparse D-form sources close to the same integral basis",
 AllTrue[results,AssociationQ]&&
 results[[1]]["MasterIntegralBasis"]===results[[2]]["MasterIntegralBasis"]&&
 results[[1]]["MasterBasisReduction"]["EmbeddingMatrix"]===
 results[[2]]["MasterBasisReduction"]["EmbeddingMatrix"]];
FTTest`FTAssert["the return map contains D and no independent epsilon",
 AllTrue[results,AssociationQ]&&
 AllTrue[results,Normal[#["MasterBasisReduction"]["EmbeddingMatrix"]]==={{1},{D},{1}}&&
  FreeQ[#["MasterBasisReduction"]["EmbeddingMatrix"],re]&]];
inverse=FeynFacet`Private`globalDEExactInverse[{{rx,1},{1,rx}}];
FTTest`FTAssert["exact sparse inversion certifies the complete rational inverse",
 MatrixQ[inverse]&&Map[Together,{{rx,1},{1,rx}}.inverse,{2}]===IdentityMatrix[2]];
failure=Internal`InheritedBlock[{FeynFacet`CancelRationalCoefficients},
 Clear[FeynFacet`CancelRationalCoefficients];calls=0;
 FeynFacet`CancelRationalCoefficients[items_List]:=
  If[++calls===2,Failure["ExpectedPivotFailure",<||>],items];
 FeynFacet`Private`globalDERowReduction[{{rx,1},{1,rx}}]];
FTTest`FTAssert["an elimination backend failure cannot yield a partial row-space certificate",
 FailureQ[failure]&&calls===2];
noSample=FeynFacet`RestrictDifferentialSystemToRelations[sys[ConstantArray[0,{2,2}]],
 {{0,0}},<|"ValidationPoints"->{}|>];
exactOnly=FeynFacet`RestrictDifferentialSystemToRelations[sys[ConstantArray[0,{2,2}]],
 {{1,-parameter}},<|"ValidationPoints"->{}|>];
FTTest`FTAssert["optional sampling can be omitted for zero and nonzero exact relations",
 AssociationQ[noSample]&&noSample["SolutionEmbedding"]===IdentityMatrix[2]&&
 AssociationQ[exactOnly]&&exactOnly["Dimension"]===1&&
 {{1,-parameter}}.exactOnly["SolutionEmbedding"]==={{0}}];
FTTest`FTReport[];
