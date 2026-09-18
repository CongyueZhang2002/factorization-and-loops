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
Print["DIFFERENTIAL MASTER VALUES TEST COMPLETE"];FTTest`FTReport[];
