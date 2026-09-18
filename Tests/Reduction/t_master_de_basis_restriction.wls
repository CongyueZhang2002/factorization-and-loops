Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
drI=FeynCalc`GLI[drFamily,{1,0}];drJ=FeynCalc`GLI[drFamily,{0,1}];
drSystem=<|"MasterIntegralBasis"->{drI,drJ},"KinematicVariables"->{drX},
 "Families"->{<|"Topology"->FeynCalc`FCTopology[drFamily,{}, {}, {}, {}, {}]|>},
 "ConnectionMatrices"-><|drX->DiagonalMatrix[{1/drX,2/drX}]|>|>;
drReduction=<|"Masters"->{drI},"Rules"->{drJ->drX drI}|>;
drResult=FeynFacet`ReduceMasterDifferentialSystem[drSystem,drReduction];
FTTest`FTAssert["a compatible integral identity yields the correct smaller differential system",
 AssociationQ[drResult]&&Normal[drResult["ConnectionMatrices"][drX]]==={{1/drX}}&&
 Normal[drResult["MasterBasisReduction"]["EmbeddingMatrix"]]==={{1},{drX}}&&
 drResult["ExternalEndpointUniformityEstablished"]===False];
drBad=FeynFacet`ReduceMasterDifferentialSystem[drSystem,<|"Masters"->{drI},"Rules"->{drJ->drX^2 drI}|>];
FTTest`FTAssert["differentiation detects an inconsistent alleged integral relation",
 MatchQ[drBad,Failure["MasterReductionDifferentialCompatibilityFailed",_]]];

drK=FeynCalc`GLI[drFamily,{1,1}];
drDependentSystem=Join[drSystem,<|"MasterIntegralBasis"->{drI,drJ,drK},
 "DimensionalRegulator"->drE,"DimensionRule"->D->4-2drE,
 "ConnectionMatrices"-><|drX->{{1/drX,0,0},{1,1/drX,0},{0,0,1/drX}}|>|>];
drClosed=FeynFacet`ReduceMasterDifferentialSystem[drDependentSystem,
 <|"Masters"->{drI,drK},"Rules"->{drJ->drX drK}|>,
 <|"CloseDifferentialRelations"->True|>];
FTTest`FTAssert["differential closure removes a dependency left in a spanning subset",
 AssociationQ[drClosed]&&Length[drClosed["MasterIntegralBasis"]]===1&&
 Normal[drClosed["ConnectionMatrices"][drX]]==={{1/drX}}&&
 drClosed["MasterBasisReduction"]["ExactDifferentialCompatibility"][drX]===True];
FTTest`FTAssert["the smaller basis keeps its exact map and physical relation provenance",
 AssociationQ[drClosed]&&KeyExistsQ[drClosed,"AdditionalMasterRelations"]&&
 Length[drClosed["AdditionalMasterRelations"]["SpanningBasis"]]===2&&
 drClosed["ExternalEndpointUniformityEstablished"]===False];


drCandidate=FeynCalc`GLI[drFamily,{0,0}];
drCandidateSystem=Join[drSystem,<|"DimensionalRegulator"->drE,"DimensionRule"->D->4-2drE|>];
drCandidateReduction=<|"Masters"->{drI,drJ},"Rules"->{drCandidate->drI+drJ},
 "Families"->drSystem["Families"]|>;
drChosen=FeynFacet`SelectMasterIntegralBasis[drCandidateSystem,drCandidateReduction,
 <|"CandidateIntegrals"->{drCandidate},"ValidationPoints"->{{drX->2/7,drE->1/97}}|>];
FTTest`FTAssert["an exact integral outside the old list can be chosen as a simpler DE coordinate",
 AssociationQ[drChosen]&&First[drChosen["MasterIntegralBasis"]]===drCandidate&&
 And@@Values[drChosen["IntegralBasisChange"]["ExactDifferentialCompatibility"]]];
FTTest`FTAssert["the saved inverse map reconstructs every original master",
 AssociationQ[drChosen]&&
 Normal[drChosen["IntegralBasisChange"]["SourceToSelectedMatrix"]].
 Normal[drChosen["IntegralBasisChange"]["SelectedToSourceMatrix"]]===IdentityMatrix[2]];

drUnit=FeynCalc`GLI[drFamily,{1,2}];
drUnitReduction=Join[drCandidateReduction,<|"Rules"->{drUnit->drJ},
 "Families"->{Append[First[drSystem["Families"]],"CutIndices"->{1}]}|>];
drUnitSelected=FeynFacet`SelectMasterIntegralBasis[drCandidateSystem,drUnitReduction,
 <|"CandidateIntegrals"->{drUnit},"ValidationPoints"->{{drX->2/7,drE->1/97}},
   "RequireUnitCutBasis"->True|>];
FTTest`FTAssert["physical unit-cut candidates replace an uncut spanning integral",
 AssociationQ[drUnitSelected]&&AllTrue[drUnitSelected["MasterIntegralBasis"],#[[2,1]]===1&]];
drNoUnit=FeynFacet`SelectMasterIntegralBasis[drCandidateSystem,drUnitReduction,
 <|"CandidateIntegrals"->{},"ValidationPoints"->{{drX->2/7,drE->1/97}},
   "RequireUnitCutBasis"->True|>];
FTTest`FTAssert["unit-cut preference cannot invent missing spanning integrals",FailureQ[drNoUnit]];
drOriginal=FeynCalc`GLI[drFamily,{3}];drTwice=FeynCalc`GLI[drFamily,{2}];drSix=FeynCalc`GLI[drFamily,{1}];
drLifecycle=<|"MasterIntegralBasis"->{drOriginal},"KinematicVariables"->{drX},
 "DimensionalRegulator"->drE,"DimensionRule"->D->6-2drE,
 "Families"->drSystem["Families"],"ConnectionMatrices"->{{{0}}},
 "RequestedMasterValues"->{drOriginal}|>;
drFirstSelection=FeynFacet`SelectMasterIntegralBasis[drLifecycle,
 <|"Masters"->{drOriginal},"Rules"->{drTwice->2drOriginal},"Families"->drSystem["Families"]|>,
 <|"CandidateIntegrals"->{drTwice},"ValidationPoints"->{{drX->2/7,drE->1/97}}|>];
drSecondSelection=FeynFacet`SelectMasterIntegralBasis[drFirstSelection,
 <|"Masters"->{drTwice},"Rules"->{drSix->3drTwice},"Families"->drSystem["Families"]|>,
 <|"CandidateIntegrals"->{drSix},"ValidationPoints"->{{drX->2/7,drE->1/97}}|>];
FTTest`FTAssert["repeated selections compose the original-integral embedding",
 AssociationQ[drSecondSelection]&&
 drSecondSelection["OriginalMasterIntegralEmbedding"]["MasterIntegralBasis"]==={drOriginal}&&
 drSecondSelection["OriginalMasterIntegralEmbedding"]["EmbeddingMatrix"]==={{1/6}}];
FTTest`FTAssert["requested integral values remain in the live basis after two selections",
 drFirstSelection["RequestedMasterValues"]==={drTwice/2}&&
 drSecondSelection["RequestedMasterValues"]==={drSix/6}];
FTTest`FTAssert["inverse dimensional conversion follows the declared reference dimension",
 FeynFacet`Private`cutInverseDimensionRule[drLifecycle]===(drE->(6-D)/2)];
drListInput=Join[drSystem,<|"ConnectionMatrices"->Values[drSystem["ConnectionMatrices"]]|>];
drListResult=FeynFacet`ReduceMasterDifferentialSystem[drListInput,drReduction];
FTTest`FTAssert["subset reduction accepts the constructor matrix-list representation",
 AssociationQ[drListResult]&&drListResult["ConnectionMatrices"]===drResult["ConnectionMatrices"]];
drSamplingFamily=Append[First[drSystem["Families"]],"CutIndices"->{1}];
drSamplingSystem=Join[drLifecycle,<|"Families"->{drSamplingFamily}|>];
drSamplingReduction=<|"Masters"->{drOriginal},"Rules"->{drSix->(drX-2/7)drOriginal},
 "Families"->{drSamplingFamily}|>;
drLaterPoint=FeynFacet`SelectMasterIntegralBasis[drSamplingSystem,drSamplingReduction,
 <|"CandidateIntegrals"->{drSix},"ValidationPoints"->{{drX->2/7,drE->1/97},{drX->3/7,drE->1/97}},
  "RequireUnitCutBasis"->True|>];
FTTest`FTAssert["an unlucky candidate minor uses the next rational point",
 AssociationQ[drLaterPoint]&&drLaterPoint["MasterIntegralBasis"]==={drSix}&&
 (drX/.drLaterPoint["IntegralBasisChange"]["SelectionPoint"])===3/7&&
 Length[drLaterPoint["IntegralBasisChange"]["SelectionAttempts"]]===2];
drUnlucky=FeynFacet`SelectMasterIntegralBasis[drSamplingSystem,drSamplingReduction,
 <|"CandidateIntegrals"->{drSix},"ValidationPoints"->{{drX->2/7,drE->1/97}},"RequireUnitCutBasis"->True|>];
FTTest`FTAssert["failed samples do not certify exact nonspan",
 MatchQ[drUnlucky,Failure["NoFullRankMasterBasisSelectionSample",_Association]]&&
 drUnlucky[[2]]["ExactNonspanEstablished"]===False];
drPermuted=FeynFacet`SelectMasterIntegralBasis[drCandidateSystem,
 Join[drCandidateReduction,<|"Masters"->Reverse[drCandidateSystem["MasterIntegralBasis"]]|>],
 <|"CandidateIntegrals"->{drCandidate},"ValidationPoints"->{{drX->2/7,drE->1/97}}|>];
FTTest`FTAssert["scalar reduction basis order does not change candidate images",AssociationQ[drPermuted]];
FTTest`FTAssert["selected bases retain exact reductions for every former master",
 AssociationQ[drChosen]&&drChosen["Reduction"]["Masters"]===drChosen["MasterIntegralBasis"]&&
 AllTrue[drCandidateSystem["MasterIntegralBasis"],
   MemberQ[drChosen["Reduction"]["Masters"],#]||MemberQ[First/@drChosen["Reduction"]["Rules"],#]&]];
drContracted=FeynFacet`ApplyIntegralReduction[
 <|"old"->AssociationThread[drCandidateSystem["MasterIntegralBasis"],{2,3}]|>,drChosen["Reduction"]];
FTTest`FTAssert["original master coefficients contract after selecting outside integrals",
 AssociationQ[drContracted]&&
 Together[Total[KeyValueMap[Times,drContracted["old"]]]-
   ({2,3}.drChosen["IntegralBasisChange"]["SelectedToSourceMatrix"].drChosen["MasterIntegralBasis"]) ]===0];
FTTest`FTReport[];
