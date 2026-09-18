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
 AssociationQ[short]&&KeyExistsQ[short["UnresolvedRequests"],basis[[2]]]&&!KeyExistsQ[short["Values"],basis[[2]]]];
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
Print["DIFFERENTIAL MASTER VALUES TEST COMPLETE"];FTTest`FTReport[];
