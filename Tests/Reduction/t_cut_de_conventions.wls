Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|"Name"->conventionSource,
 "FinalMomenta"->{ck1,ck2,ck3},"TotalMomentum"->cP+cQ,"ExternalMomenta"->{cP,cQ},
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[cP]->0,FeynCalc`SPD[cQ]->-cS,
  FeynCalc`SPD[cP,cQ]->cS/(2cX)}],"ReferenceMomentum"->cP,"TaggedMomentum"->ck1,
 "MeasurementVariable"->cZ,"Assumptions"->cS>0&&0<cX<1&&0<cZ<1|>];
prepared=FeynFacet`PrepareMeasuredCutIntegrand[FeynCalc`FCI[FeynCalc`SFAD[cP-ck2]],geometry,
 <|"ExternalKinematicConditions"->cS>0&&0<cX<1|>];
family=First[FeynFacet`DecomposeMeasuredCutIntegrand[prepared]["Families"]];
name=family["Topology"][[1]];unit=FeynCalc`GLI[name,{1,1,1,1,0,0,0}];
work=CreateDirectory[];
moving=<|cX-><|cP->-cP/cX,cQ->0|>|>;
system=FeynFacet`ConstructCutDifferentialSystem[{family},{unit},{cX,cZ},
 <|"WorkingDirectory"->work<>"/Closure","Threads"->1,"MomentumDerivatives"->moving,
  "ValidationPoints"->{{cX->2/7,cZ->3/8,cS->1,D->11/5}}|>];
FTTest`FTAssert["the mathematical reduction does not duplicate the native integral index",
 AssociationQ[system]&&!KeyExistsQ[system["Reduction"],"IndexedIntegrals"]&&
 IntegerQ[system["Reduction"]["IndexedIntegralCount"]]&&
 FileExistsQ[system["Reduction"]["InputWorkspace"]<>"/IntegralIdentifiers.wxf"]];
FTTest`FTAssert["physical phase-volume constructor retains its derivative operators",
 AssociationQ[system]&&system["MomentumDerivatives"]===moving&&system["MasterIntegralBasis"]==={unit}];
If[!AssociationQ[system],Print[system];FTTest`FTReport[]];
reduced=FeynFacet`ReduceMasterDifferentialSystem[system,<|"Masters"->{unit},"Rules"->{}|>];
FTTest`FTAssert["fresh constructor output is consumed directly by the subset reducer",AssociationQ[reduced]];
stored=FeynFacet`IntegralRelationsFromCutDifferentialSystem[system];
explicit=FeynFacet`IntegralRelationsFromCutDifferentialSystem[system,<|"MomentumDerivatives"->moving|>];
FTTest`FTAssert["supplemental equations use the retained derivative convention",
 AssociationQ[stored]&&stored["Rows"]===explicit["Rows"]];
FTTest`FTAssert["incompatible derivative override fails",
 FailureQ[FeynFacet`IntegralRelationsFromCutDifferentialSystem[system,<|"MomentumDerivatives"-><||>|>]]];
dimensionRows=Table[
 dSystem=Join[system,<|"KinematicVariables"->{cS},"DimensionRule"->D->referenceD-2cE,
  "DimensionalRegulator"->cE,"MomentumDerivatives"-><||>,
  "ConnectionMatrices"->{{{(referenceD-3-2cE)/cS}}}|>];
 FeynFacet`IntegralRelationsFromCutDifferentialSystem[dSystem],
 {referenceD,{4,6}}];
typedSystem=Join[system,<|"KinematicVariables"->{cS},"MomentumDerivatives"-><||>,
 "ConnectionMatrices"->{{{(D-3)/cS}}}|>];
typedRows=FeynFacet`IntegralRelationsFromCutDifferentialSystem[typedSystem];
FTTest`FTAssert["four- and six-dimensional regulator conventions give identical typed-D relations",
 AllTrue[dimensionRows,AssociationQ]&&FreeQ[dimensionRows[[All,"Rows"]],cE]&&
 dimensionRows[[1]]["Rows"]===dimensionRows[[2]]["Rows"]===typedRows["Rows"]];
replica=FeynFacet`CreateCutIntegralFamily[Join[family,<|
 "Topology"->ReplacePart[family["Topology"],1->conventionReplica]|>]];
duplicate=FeynCalc`GLI[conventionReplica,unit[[2]]];
duplicated=Join[system,<|"MasterIntegralBasis"->{unit,duplicate},"Families"->{family,replica},
 "ConnectionMatrices"->(DiagonalMatrix[{#[[1,1]],#[[1,1]]}]&/@system["ConnectionMatrices"]),
 "RequestedMasterIntegrals"->{unit,duplicate},"RequestedMasterValues"->{unit,duplicate},
 "Reduction"-><|"Masters"->{unit,duplicate},"Rules"->{},"Families"->{family,replica}|>|>];
equivalent=FeynFacet`ReduceEquivalentMasterIntegrals[duplicated,
 <|"ValidationPoints"->{{cX->2/7,cZ->3/8,cS->1,Global`Epsilon->1/7}}|>];
FTTest`FTAssert["equivalent physical masters are reduced with exact DE compatibility",
 AssociationQ[equivalent]&&Length[equivalent["MasterIntegralBasis"]]===1&&
 SameQ@@equivalent["RequestedMasterValues"]&&
 equivalent["Reduction"]["Masters"]===equivalent["MasterIntegralBasis"]];
FTTest`FTAssert["removed original masters remain available as exact reduction targets",
 AssociationQ[equivalent]&&
 (({unit,duplicate}/.equivalent["Reduction"]["Rules"])===equivalent["RequestedMasterValues"])];
If[StringStartsQ[ExpandFileName[work],ExpandFileName[$TemporaryDirectory]<>"/"],
 DeleteDirectory[work,DeleteContents->True]];
Print["AFFINE REGRESSION COMPLETE"];FTTest`FTReport[];
