(* Measurement normalization is derived from the constraint, not fitted. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
lmRequest=<|"Observable"->lx lmPQ/lmQ2,"Value"->lz,
 "IntegrationVariables"->{lmPQ},"Assumptions"->lmQ2>0&&0<lx<1&&0<lz<1|>;
lmResult=FeynFacet`CompileLinearMeasurement[lmRequest];
FTTest`FTAssert["SIDIS fragmentation measurement keeps its Q2/x Jacobian",
 AssociationQ[lmResult]&&Factor[lmResult["CutPolynomial"]-(lmPQ-lz lmQ2/lx)]===0&&
 lmResult["Jacobian"]===lmQ2/lx];
FTTest`FTAssert["constraint rescaling preserves the exact defining equation",
 AssociationQ[lmResult]&&Factor[lmResult["OriginalConstraint"]-lmResult["ConstraintScale"]lmResult["CutPolynomial"]]===0];
FTTest`FTAssert["a measurement cut has no particle-energy theta function",
 lmResult["PositiveEnergyCondition"]===None&&lmResult["InitialCutPower"]===1];
lmReverse=FeynFacet`CompileLinearMeasurement[Join[lmRequest,<|"Observable"->-lx lmPQ/lmQ2,"Value"->-lz|>]];
FTTest`FTAssert["reversing the constraint does not change its delta distribution",
 AssociationQ[lmReverse]&&lmReverse["CutPolynomial"]===lmResult["CutPolynomial"]&&lmReverse["Jacobian"]===lmResult["Jacobian"]];
FTTest`FTAssert["a quadratic constraint is not silently treated as linear",
 FailureQ[FeynFacet`CompileLinearMeasurement[Join[lmRequest,<|"Observable"->lmPQ^2|>]]]];
FTTest`FTAssert["an unproved normalization zero is rejected",
 FailureQ[FeynFacet`CompileLinearMeasurement[Join[lmRequest,<|"Assumptions"->True|>]]]];
FTTest`FTReport[];
