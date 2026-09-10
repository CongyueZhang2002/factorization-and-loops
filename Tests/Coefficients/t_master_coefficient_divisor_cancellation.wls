$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
pcI=FeynCalc`GLI[pcFamily,{1,0}];pcJ=FeynCalc`GLI[pcFamily,{0,1}];
pcSystem=<|"MasterIntegralBasis"->{pcI,pcJ},"KinematicVariables"->{px,pz},
 "DimensionalRegulator"->pe,"ConnectionMatrices"->{{{0,0},{2px,0}},ConstantArray[0,{2,2}]}|>;
pcReduction=<|"Targets"->{pcI,pcJ},"Masters"->{pcI},"Rules"->{pcJ->pz^2 pcI}|>;
pcRows=<|"Physical"-><|pcI->-(pz^2+2pz(px-pz))/(px-pz)^2,pcJ->1/(px-pz)^2|>|>;
pcCheck=FeynFacet`VerifyMasterCoefficientDivisorCancellation[pcRows,pcSystem,pcReduction,
 <|"Variable"->px,"DivisorLocation"->pz|>];
FTTest`FTAssert["a double apparent pole cancels only after the first DE Taylor jet is included",
 AssociationQ[pcCheck]&&pcCheck["Status"]==="ExactDivisorPoleCancellationVerified"&&
 pcCheck["MaximumPoleOrder"]===2&&Length[pcCheck["NormalTaylorMatrices"]]===2];
pcBad=FeynFacet`VerifyMasterCoefficientDivisorCancellation[
 <|"Physical"-><|pcI->-pz^2/(px-pz)^2,pcJ->1/(px-pz)^2|>|>,pcSystem,pcReduction,
 <|"Variable"->px,"DivisorLocation"->pz|>];
FTTest`FTAssert["a surviving simple pole is not erased by cancellation of its leading double pole",
 MatchQ[pcBad,Failure["MasterCoefficientDivisorPrincipalPartNonzero",_]]];
pcWeighted=Map[Function[row,Map[Gamma[1+pe]#&,row]],pcRows];
pcExact=FeynFacet`VerifyMasterCoefficientDivisorCancellation[pcWeighted,pcSystem,pcReduction,
 <|"Variable"->px,"DivisorLocation"->pz|>];
FTTest`FTAssert["meromorphic dimensional factors are retained without epsilon expansion",
 AssociationQ[pcExact]&&pcExact["EpsilonExpansionUsed"]===False&&
 pcExact["ExternalEndpointUniformityEstablished"]===False];
FTTest`FTAssert["coordinate-dependent analytic factors require their own Taylor data",
 MatchQ[FeynFacet`VerifyMasterCoefficientDivisorCancellation[Map[Function[row,Map[px^pe #&,row]],pcRows],pcSystem,pcReduction,
 <|"Variable"->px,"DivisorLocation"->pz|>],
 Failure["CoordinateDependentAnalyticCoefficientFactorRequiresTaylorExpansion",_]]];

pcDerivatives=FeynFacet`ConstructMasterCoefficientDivisorDerivatives[pcRows,pcSystem,pcReduction,
 <|"Variable"->px,"DivisorLocation"->pz|>];
FTTest`FTAssert["the highest normal derivative gives the exact quotient value with its factorial",
 AssociationQ[pcDerivatives]&&pcDerivatives["QuotientOrders"]["Physical"]===2&&
 Simplify[Last[pcDerivatives["RegularNumeratorDerivativeRows"]["Physical"]]-{2,0}]==={0,0}&&
 pcDerivatives["DiagonalValueRows"]["Physical"]==={1,0}&&
 pcDerivatives["UniformBoundEstablished"]===False];
(* M=(f(x),f(z),f'(z)); x differentiation holds z fixed. *)
pdBasis=FeynCalc`GLI[pdFamily,{#}]&/@Range[3];
pdA=DiagonalMatrix[{-plambda/(1-px),0,0}];
pdSystem=<|"MasterIntegralBasis"->pdBasis,"KinematicVariables"->{px,pz},
 "DimensionalRegulator"->pe,"ConnectionMatrices"->{pdA,
  {{0,0,0},{0,0,1},{0,0,-(plambda-1)/(1-pz)}}}|>;
pdReduction=<|"Targets"->pdBasis,"Masters"->{pdBasis[[2]]},
 "Rules"->{pdBasis[[1]]->pdBasis[[2]],pdBasis[[3]]->-plambda pdBasis[[2]]/(1-pz)}|>;
pdRows=<|"First"->AssociationThread[pdBasis,{1,-1,0}/(px-pz)],
 "Second"->AssociationThread[pdBasis,{1,-1,-(px-pz)}/(px-pz)^2]|>;
pdResult=FeynFacet`ConstructMasterCoefficientDivisorDerivatives[pdRows,pdSystem,pdReduction,
 <|"Variable"->px,"DivisorLocation"->pz|>];
FTTest`FTAssert["first and second divided differences retain the correct normal derivatives",
 AssociationQ[pdResult]&&pdResult["QuotientOrders"]===<|"First"->1,"Second"->2|>&&
 Simplify[pdResult["DiagonalValueRows"]["Second"]-
  {plambda(plambda-1)/(2(1-pz)^2),0,0}]==={0,0,0}];
FTTest`FTAssert["interior removability alone does not assert a bounded corner for a pole",
 AssociationQ[pdResult/.plambda->-1]&&
 (pdResult/.plambda->-1)["UniformBoundEstablished"]===False];
FTTest`FTReport[];
