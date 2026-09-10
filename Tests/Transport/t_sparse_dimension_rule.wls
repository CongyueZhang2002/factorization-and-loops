$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
sdSystem=<|"KinematicVariables"->{sdX},"DimensionalRegulator"->sdEps,
 "DimensionRule"->(D->4-2sdEps),"ConnectionMatrices"->{SparseArray[{{(D-4)/sdX}}]}|>;
sdPreparation=FeynFacet`PrepareDifferentialSystemForFiniteIntegration[sdSystem];
FTTest`FTAssert["preparation applies the declared dimension to sparse coefficients",
 AssociationQ[sdPreparation]&&sdPreparation["ConnectionMatrices"]==={{{-2sdEps/sdX}}}];
sdApplied=FeynFacet`ApplyFiniteIntegrationPreparation[sdSystem,sdPreparation];
FTTest`FTAssert["application preserves consistently normalized source matrices",
 AssociationQ[sdApplied]&&
 FreeQ[Lookup[sdApplied,{"ConnectionMatrices","OriginalConnectionMatrices","ConnectionCoefficientSource"}],D]];
sdRequest=<|"BasePoint"->{1/5},"RequestedEpsilonOrders"->{0,1},
 "AnalyticDomain"->"Positive real sdX","BranchPrescription"->"Real positive-axis continuation"|>;
sdSolution=FeynFacet`ConstructMasterIntegralSolution[sdSystem,sdRequest,"FlatnessCheck"->"Exact"];
If[FailureQ[sdSolution],Print[sdSolution]];
FTTest`FTAssert["direct finite construction uses the same sparse dimension conversion",
 FeynFacet`MasterIntegralSolutionQ[sdSolution]&&
 sdSolution["ConnectionMatrices"]==={{{-2sdEps/sdX}}}&&
 FeynFacet`MasterIntegralSolutionCoefficient[sdSolution,1,0]==={1}];
sdVerified=FeynFacet`VerifyMasterIntegralSolution[sdSolution];
FTTest`FTAssert["the stored finite coefficients satisfy the complete declared DE",
 AssociationQ[sdVerified]&&sdVerified["Status"]==="FiniteSolutionCoefficientIdentitiesVerified"];
(* A nontrivial two-coordinate block checks that D is substituted before
   the epsilon-zero homogeneous problem is formed, including a scale parameter. *)
sdCoupled=<|"KinematicVariables"->{sdX,sdZ},"DimensionalRegulator"->sdEps,
 "DimensionRule"->(D->4-2sdEps),"ConnectionMatrices"->(SparseArray/@{
  {{-(3-D+sdX)/((sdX-1)sdX),0},{0,(D-4)/((sdX-1)sdX)}},
  {{(D-4)/(2sdZ),(D-2)sdQ/(2sdX)},
   {(2-D)sdX/(2sdQ(sdZ-1)sdZ),(-10+3D)/(2(sdZ-1))}}})|>;
sdCP=FeynFacet`PrepareDifferentialSystemForFiniteIntegration[sdCoupled];
FTTest`FTAssert["the sparse two-variable homogeneous block is reduced automatically",
 AssociationQ[sdCP]&&FreeQ[sdCP["ConnectionMatrices"],D]&&
 TrueQ[sdCP["Validation"]["AllTransformationsVerified"]]];
sdNormalized=FeynFacet`Private`solutionNormalizeDifferentialSystem[
 Join[sdSystem,<|"BasisTransformationMatrix"->SparseArray[{{D-3}}]|>]];
FTTest`FTAssert["basis matrices use the same dimension convention",
 sdNormalized["BasisTransformationMatrix"]==={{1-2sdEps}}];

sdOrderRequest=<|"BasePoint"->{1/5},"RequestedMasterIntegralOrderRanges"-><|1->{0,1}|>,
 "MasterIntegralLaurentLowerBounds"-><|1->-1|>|>;
sdPlan=FeynFacet`DetermineMasterIntegralExpansionOrders[sdSystem,sdOrderRequest];
FTTest`FTAssert["order planning receives the same sparse dimension conversion",
 AssociationQ[sdPlan]&&sdPlan["Status"]==="SufficientForAssumedLaurentBounds"&&
 FreeQ[sdPlan["PreparedDifferentialSystem"]["ConnectionMatrices"],D]&&
 sdPlan["OriginalFundamentalMatrixCoefficientUpperOrders"]==={{2}}];

sdAliases=FeynFacet`Private`solutionNormalizeDifferentialSystem[<|
 "KinematicVariables"->{sdX},"DimensionalRegulator"->sdEps,
 "ConnectionMatrices"->{SparseArray[{{CANONICA`eps/sdX}}]},
 "BasisTransformationMatrix"->SparseArray[{{Global`Epsilon^-1}}],
 "ConnectionCoefficientSource"-><|"ConnectionMatrices"->{SparseArray[{{FeynCalc`Epsilon/sdX}}]}|>|>];
FTTest`FTAssert["all scalar connection and gauge fields normalize regulator aliases together",
 sdAliases["ConnectionMatrices"]==={{{sdEps/sdX}}}&&
 sdAliases["BasisTransformationMatrix"]==={{sdEps^-1}}&&
 sdAliases["ConnectionCoefficientSource"]["ConnectionMatrices"]==={{{sdEps/sdX}}}];
FTTest`FTAssert["the dimension and regulator cannot be the same declared symbol",
 FailureQ[FeynFacet`PrepareDifferentialSystemForFiniteIntegration[
  Append[sdSystem,"DimensionRule"->(sdEps->4-2sdEps)]]]];

sdAssociation=FeynFacet`Private`solutionNormalizeDifferentialSystem[
 Join[sdCoupled,<|"ConnectionMatrices"->AssociationThread[Reverse[sdCoupled["KinematicVariables"]],
   Reverse[sdCoupled["ConnectionMatrices"]]]|>]];
FTTest`FTAssert["coordinate-indexed matrices normalize dimension and restore the declared axis order",
 sdAssociation["ConnectionMatrices"]===FeynFacet`Private`solutionNormalizeDifferentialSystem[sdCoupled]["ConnectionMatrices"]&&
 FreeQ[sdAssociation["ConnectionMatrices"],D]];
FTTest`FTAssert["an association with a missing or foreign DE axis is rejected",
 FailureQ[FeynFacet`Private`solutionNormalizeDifferentialSystem[
 Join[sdSystem,<|"ConnectionMatrices"-><|sdZ->{{1}}|>|>]]]];

FTTest`FTReport[];
