root=DirectoryName[ExpandFileName[$InputFileName],3];$HistoryLength=0;$MaxExtraPrecision=50;
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;passed=0;failed=0;
check[label_,test_]:=If[TrueQ[test],passed++;Print["PASS ",label],failed++;Print["FAIL ",label]];
master=FeynCalc`GLI["test",{1,1}];
table=<|"PreFactor"->1,"DimensionalRegulator"->epTest,"Masters"->{<|"Master"->master,"Terms"->{<|"PreFactor"->1,"Coefficient"->1/epTest,"Representation"->"Exact"|>}|>},"RemainderTerms"->{},"PhaseSpace"->1|>;
value=<|"MasterIntegral"->master,"DimensionalRegulator"->epTest,"LaurentLowerBound"->-1,"KnownThroughOrder"->1,
 "Coefficients"-><|-1->bm1,0->b0,1->b1|>,"ExactInEpsilon"->False|>;
request=<|"EpsilonOrderRange"->{0,0},"Normalization"->1,"MeasureConversions"-><|master->1|>|>;
out=FeynFacet`WithEpsilonRemainderChecks[FeynFacet`ContractAnalyticMasterCoefficients[table,<|1->value|>,request]];
check["simple coefficient pole requests epsilon one of master",out["Result"]["Coefficients"][0]===b1];
check["independent omitted-master term check passed",out["EpsilonRemainderAudit"]["Status"]==="Passed"];
short=Join[value,<|"KnownThroughOrder"->0,"Coefficients"->KeyDrop[value["Coefficients"],1]|>];
check["insufficient supplied order rejected",FailureQ[FeynFacet`ContractAnalyticMasterCoefficients[table,<|1->short|>,request]]];
hole=Join[value,<|"Coefficients"->KeyDrop[value["Coefficients"],0]|>];
check["missing middle epsilon coefficient rejected",FailureQ[FeynFacet`ContractAnalyticMasterCoefficients[table,<|1->hole|>,request]]];
shortAudit=FeynFacet`WithEpsilonRemainderChecks[FeynFacet`ContractAnalyticMasterCoefficients[table,<|1->value|>,request],"TruncationOrderShift"->-1];
check["deliberately shortened cutoff independently detected",shortAudit["EpsilonRemainderAudit"]["Status"]==="Failed"];
check["missing measure conversion rejected",FailureQ[FeynFacet`ContractAnalyticMasterCoefficients[table,<|1->value|>,Join[request,<|"MeasureConversions"-><||>|>]]]];
check["missing master rejected",FailureQ[FeynFacet`ContractAnalyticMasterCoefficients[table,<||>,request]]];

explicitSolution=<|"MasterIntegralBasis"->{master},"DimensionalRegulator"->epTest,
 "OriginalMasterLaurentLowerBounds"->{-1},"MasterIntegralUpperOrders"->{1},
 "BoundaryValuesApplied"->True,"AlgebraicDefinitions"->{},"KernelDefinitions"->{},
 "IntegralDefinitions"->{},"Coefficients"-><|{1,-1}->bm1,{1,0}->b0,{1,1}->b1|>|>;
explicitRows=<|"channel"-><|master->1/epTest|>|>;
explicitAudit=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`ContractExplicitMasterSolution[explicitRows,explicitSolution,<|"EpsilonOrderRange"->{0,0}|>]];
check["sparse rows contract a matched explicit solution with the same order audit",
 AssociationQ[explicitAudit["Result"]]&&explicitAudit["Result"]["Rows"]["channel"]["Coefficients"][0]===b1&&
 explicitAudit["EpsilonRemainderAudit"]["Status"]==="Passed"];
largeMultiplier=(Sum[(ax+az)^j epTest^j,{j,0,30}])Gamma[1-epTest]^2/epTest^2;
largeAudit=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`Private`epsilonAuditMultiplier[largeMultiplier,epTest,0,2,0,"LargeRational",master]];
check["a large rational coefficient does not need a full marked-function series",
 largeAudit["EpsilonRemainderAudit"]["Status"]==="Passed"];
gammaPole=FeynFacet`WithEpsilonRemainderChecks[
 FeynFacet`Private`epsilonAuditMultiplier[Gamma[epTest]/epTest,epTest,0,0,0,"GammaPole",master]];
check["analytic-factor poles cannot be ignored by the fast remainder check",
 gammaPole["EpsilonRemainderAudit"]["Status"]==="Failed"];
Print["ANALYTIC_CONTRACTION_TESTS ",passed,"/",passed+failed];Exit[If[failed===0,0,1]];
