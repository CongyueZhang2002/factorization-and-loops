Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
basis=FeynCalc`GLI[CheckKnownValues,{#}]&/@Range[3];
system=<|"KinematicVariables"->{x},"DimensionalRegulator"->e,"DimensionRule"->D->4-2e,
 "MasterIntegralBasis"->basis,"ConnectionMatrices"->{{{0,1,0},{-1,0,0},{0,0,e/x}}}|>;
result=FeynFacet`ExtendMasterValuesUsingDifferentialEquations[system,<|basis[[1]]->Sin[x]|>];
FTTest`FTAssert["known physical function determines its derivative partner without an integration constant",
 AssociationQ[result]&&FullSimplify[result["Values"][basis[[2]]]-Cos[x]]===0];
FTTest`FTAssert["an independent homogeneous solution remains unresolved",
 result["UnresolvedMasterIntegrals"]==={basis[[3]]}&&!result["AllBasisValuesKnown"]];
FTTest`FTAssert["all supported closed rows retain exact zero compatibility residuals",
 AllTrue[result["KnownRowCompatibilityResiduals"],FullSimplify[#["Residual"]]===0&]];
bad=FeynFacet`ExtendMasterValuesUsingDifferentialEquations[system,<|basis[[1]]->x|>];
FTTest`FTAssert["inconsistent input functions leave a nonzero DE residual instead of a passing flag",
 AnyTrue[bad["KnownRowCompatibilityResiduals"],FullSimplify[#["Residual"]]=!=0&]];
FTTest`FTAssert["unknown integral identities cannot enter supplied physical functions",
 FailureQ[FeynFacet`ExtendMasterValuesUsingDifferentialEquations[system,<|basis[[1]]->basis[[3]]|>]]];
orderSystem=<|"KinematicVariables"->{x},"DimensionalRegulator"->e,"DimensionRule"->D->4-2e,
 "MasterIntegralBasis"->Take[basis,2],"ConnectionMatrices"->{{{0,e},{0,0}}}|>;
short=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[orderSystem,
 <|basis[[1]]-><|"Coefficients"-><|0->1|>,"LaurentLowerBound"->0,"KnownThroughOrder"->0,"ExactTail"->False|>|>,<|basis[[2]]->0|>];
FTTest`FTAssert["division by an epsilon-valued DE coefficient refuses a missing input order",
 AssociationQ[short]&&KeyExistsQ[short["UnresolvedRequests"],basis[[2]]]&&
 short["Values"][basis[[2]]]["KnownThroughOrder"]===-1&&
 short["Values"][basis[[2]]]["Coefficients"]===<|-1->0|>];
sufficient=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[orderSystem,
 <|basis[[1]]-><|"Coefficients"-><|0->1,1->x|>,"LaurentLowerBound"->0,"KnownThroughOrder"->1,"ExactTail"->False|>|>,<|basis[[2]]->0|>];
FTTest`FTAssert["the next input order determines the finite partner with the omitted-tail audit",
 AssociationQ[sufficient]&&sufficient["UnresolvedRequests"]===<||>&&
 sufficient["Values"][basis[[2]]]["Coefficients"][0]===1&&
 TrueQ[sufficient["Values"][basis[[2]]]["OrderCoverageVerified"]]];
chainBasis=FeynCalc`GLI[ChainedKnownValues,{#}]&/@Range[4];
chainSystem=<|"KinematicVariables"->{x},"DimensionalRegulator"->e,"DimensionRule"->D->4-2e,
 "MasterIntegralBasis"->chainBasis,"ConnectionMatrices"->{{{0,0,1,0},{0,0,1,1},{0,0,0,0},{0,0,1,0}}}|>;
record[value_]:=<|"Coefficients"-><|0->value|>,"LaurentLowerBound"->0,"KnownThroughOrder"->0,"ExactTail"->False|>;
chain=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[chainSystem,
 <|chainBasis[[1]]->record[x],chainBasis[[2]]->record[x^2/2]|>,AssociationThread[chainBasis[[{3,4}]],{0,0}]];
FTTest`FTAssert["a value derived earlier in the same pass is included in later subtractions",
 AssociationQ[chain]&&chain["Values"][chainBasis[[3]]]["Coefficients"][0]===1&&
 Factor[chain["Values"][chainBasis[[4]]]["Coefficients"][0]-(x-1)]===0];
partial=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[orderSystem,
 <|basis[[1]]-><|"Coefficients"-><|0->1,1->x,2->2x|>,
     "LaurentLowerBound"->0,"KnownThroughOrder"->2,"ExactTail"->False|>,
   basis[[2]]->Join[record[1],<|"PhysicalConvention"->"RetainedInput"|>]|>,<|basis[[2]]->1|>];
FTTest`FTAssert["a partially known target is extended without subtracting its own old value",
 AssociationQ[partial]&&partial["UnresolvedRequests"]===<||>&&
 partial["Values"][basis[[2]]]["Coefficients"]===<|0->1,1->2|>&&
 partial["Values"][basis[[2]]]["PhysicalConvention"]==="RetainedInput"];
partialShort=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[orderSystem,
 <|basis[[1]]-><|"Coefficients"-><|0->1,1->x|>,
     "LaurentLowerBound"->0,"KnownThroughOrder"->1,"ExactTail"->False|>,
   basis[[2]]->record[1]|>,<|basis[[2]]->1|>];
FTTest`FTAssert["an existing partial target still requires adequate source orders",
 AssociationQ[partialShort]&&partialShort["Values"][basis[[2]]]===record[1]&&
 KeyExistsQ[partialShort["UnresolvedRequests"],basis[[2]]]&&
 partialShort["Derivations"]==={}];
FTTest`FTAssert["partial extension retains overlap consistency separately from order coverage",
 AllTrue[partial["KnownCoefficientCompatibilityResiduals"],TrueQ[#["ExactlyZero"]]&]];
inconsistent=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[orderSystem,
 <|basis[[1]]-><|"Coefficients"-><|0->x,1->x,2->2x|>,
     "LaurentLowerBound"->0,"KnownThroughOrder"->2,"ExactTail"->False|>,
   basis[[2]]->record[7]|>,<|basis[[2]]->1|>];
FTTest`FTAssert["conflicting old coefficients and a violated lower bound leave explicit residuals",
 inconsistent["Values"][basis[[2]]]["Coefficients"][0]===7&&
 First[inconsistent["KnownCoefficientCompatibilityResiduals"]]["ResidualCoefficients"]===<|-1->1,0->-6|>&&
 !TrueQ[First[inconsistent["KnownCoefficientCompatibilityResiduals"]]["ExactlyZero"]]];
intermediate=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[orderSystem,
 <|basis[[1]]-><|"Coefficients"-><|0->1,1->x,2->2x|>,
     "LaurentLowerBound"->0,"KnownThroughOrder"->2,"ExactTail"->False|>,
   basis[[2]]->record[1]|>,<|basis[[2]]->3|>];
FTTest`FTAssert["useful intermediate orders are retained without claiming the full request",
 intermediate["Values"][basis[[2]]]["KnownThroughOrder"]===1&&
 intermediate["Values"][basis[[2]]]["Coefficients"]===<|0->1,1->2|>&&
 KeyExistsQ[intermediate["UnresolvedRequests"],basis[[2]]]&&
 Length[intermediate["Derivations"]]===1];
higherBoundSystem=Join[orderSystem,<|"ConnectionMatrices"->{{{0,1},{0,0}}}|>];
higherBound=FeynFacet`ExtendMasterLaurentCoefficientsUsingDifferentialEquations[higherBoundSystem,
 <|basis[[1]]-><|"Coefficients"-><|2->x|>,"LaurentLowerBound"->2,"KnownThroughOrder"->2,"ExactTail"->False|>,
  basis[[2]]->record[7]|>,<|basis[[2]]->2|>];
FTTest`FTAssert["a higher derived lower bound also checks old coefficients against zero",
 First[higherBound["KnownCoefficientCompatibilityResiduals"]]["ResidualCoefficients"]===<|0->-7|>];
Print["DIFFERENTIAL MASTER VALUES TEST COMPLETE"];FTTest`FTReport[];
