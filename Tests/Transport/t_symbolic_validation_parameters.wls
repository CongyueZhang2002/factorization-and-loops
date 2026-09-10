$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
vpSys=<|"KinematicVariables"->{vpX,vpY},"DimensionalRegulator"->vpEps,
 "ConnectionMatrices"->{{{0,vpEps vpScale},{0,0}},{{0,2vpEps vpScale vpY},{0,0}}},
 "OriginalConnectionMatrices"->{{{0,vpEps vpScale},{0,0}},{{0,2vpEps vpScale vpY},{0,0}}}|>;
vpRequest=<|"BasePoint"->{1/3,1/4},"RequestedEpsilonOrders"->{0,1},
 "AnalyticDomain"->"Positive ordinary neighborhood.","BranchPrescription"->"Real branch."|>;
vpSol=FeynFacet`ConstructMasterIntegralSolution[vpSys,vpRequest];
FTTest`FTAssert["automatic numerical validation includes constant symbolic parameters",
 AssociationQ[vpSol]&&FeynFacet`MasterIntegralSolutionQ[vpSol]];
If[AssociationQ[vpSol],
 FTTest`FTAssert["automatic validation preserves the symbolic scale in the solution",
  !FreeQ[{vpSol["Coefficients"],vpSol["KernelDefinitions"],vpSol["AlgebraicDefinitions"]},vpScale]];
 vpCheck=FeynFacet`VerifyMasterIntegralSolution[vpSol];
 FTTest`FTAssert["the independent coefficient verifier samples the same scalar-parameter scope",
  AssociationQ[vpCheck]]];
vpPoints=FeynFacet`Private`solutionValidationPoints[{vpX,vpY},{1/3,1/4},vpEps];
vpIncomplete=FeynFacet`ConstructMasterIntegralSolution[vpSys,vpRequest,"ValidationPoints"->vpPoints];
FTTest`FTAssert["incomplete explicit samples are distinguished from a failed DE identity",
 FailureQ[vpIncomplete]&&vpIncomplete[[1]]==="IncompleteNumericalValidationPoint"];
vpChanged=Join[vpSys,<|"OriginalConnectionMatrices"->{{{0,vpEps vpScale^2},{0,0}},
 {{0,2vpEps vpScale vpY},{0,0}}}|>];
vpBad=FeynFacet`ConstructMasterIntegralSolution[vpChanged,vpRequest];
FTTest`FTAssert["parameter sampling does not hide an identity valid only at unit scale",
 FailureQ[vpBad]&&vpBad[[1]]==="OriginalBasisDifferentialEquationMismatch"];

vpGauge={{vpScale,0},{0,1}};
vpGaugeSys=Join[vpSys,<|"BasisTransformationMatrix"->vpGauge,
 "InverseBasisTransformationMatrix"->Inverse[vpGauge],
 "OriginalConnectionMatrices"->(vpGauge.#.Inverse[vpGauge]&/@vpSys["ConnectionMatrices"])|>];
vpGaugeSol=FeynFacet`ConstructMasterIntegralSolution[vpGaugeSys,vpRequest];
vpGaugeCheck=If[AssociationQ[vpGaugeSol],FeynFacet`VerifyMasterIntegralSolution[vpGaugeSol],vpGaugeSol];
FTTest`FTAssert["the initial inverse gauge is checked at every parameter sample",
 AssociationQ[vpGaugeCheck]];

vpM={{1+vpX,0},{vpX/(1+vpX),1+vpX^2}};vpMi=Inverse[vpM];vpB={{0,0},{vpEps,0}};
vpA=Map[Cancel,D[vpM,vpX].vpMi+vpM.vpB.vpMi,{2}];
vpPlanned=<|"KinematicVariables"->{vpX},"DimensionalRegulator"->vpEps,
 "OriginalMasterIntegralBasis"->{1,2},"ConnectionMatrices"->{vpB},
 "OriginalConnectionMatrices"->{vpA},"BasisTransformationMatrix"->vpM,
 "InverseBasisTransformationMatrix"->vpMi,"ConnectionCoefficientSource"-><|
 "ConnectionMatrices"->{vpA},"BasisTransformationMatrix"->vpM,
 "InverseBasisTransformationMatrix"->vpMi|>|>;
vpPlannedSol=FeynFacet`ConstructMasterIntegralSolution[vpPlanned,<|"BasePoint"->{1/3},
 "RequestedMasterIntegralOrderRanges"-><|1->{-1,0},2->{-1,0}|>,
 "MasterIntegralLaurentLowerBounds"-><|1->-1,2->-1|>|>,"AutomaticPreparation"->False];
vpPlannedCheck=If[AssociationQ[vpPlannedSol],FeynFacet`VerifyMasterIntegralSolution[vpPlannedSol],vpPlannedSol];
Print["PLANNED GAUGE ",If[FailureQ[vpPlannedCheck],vpPlannedCheck,"passed"]];
FTTest`FTAssert["exact cancellations below a planned connection valuation are literal zeros",
 AssociationQ[vpPlannedCheck]&&vpPlannedSol["KernelMatrices"][0]===ConstantArray[0,{2,2}]];
FTTest`FTReport[];
