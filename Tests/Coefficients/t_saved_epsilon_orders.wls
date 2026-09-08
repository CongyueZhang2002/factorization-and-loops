root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;Clear[e,v,z];
id={"A",{1}};
d=<|"DataType"->"FiniteMasterIntegralDensity","PhysicalBoundaryCoefficientsResolved"->True,
 "EpsilonOrderRange"->{-2,0},"SourceCoefficientFile"->"physical.wxf",
 "MasterOrderRequirements"->{<|"Master"->id,"MasterLaurentLowerBound"->-1,"CoefficientLaurentLowerBound"->-1|>},
 "MasterCoefficientIndex"->Table[<|"Master"->id,"EpsilonOrder"->q|>,{q,-1,1}],
 "CoefficientFunctionIndex"->Table[<|"Master"->id,"EpsilonOrder"->q|>,{q,-1,1}]|>;
endpoint=<|"DataType"->"FiniteScalarEndpointSolution","DimensionalRegulator"->e,"NormalVariable"->z,
 "TangentialVariable"->v,"ThroughOrder"->0,"PhysicalBoundaryValuesApplied"->True,
 "GlobalPrefactorIncluded"->True,"RequiredInitialConstantCoefficients"->{},"ProjectedMasterIdentities"->{id},
 "SourceCoefficientFile"->"physical.wxf","CoefficientTailSufficiency"-><|"Status"->"SufficientOrdersDetermined",
 "MissingCoefficientOrders"->{},"UnresolvedCoefficientRemainderClasses"->{}|>,
 "EndpointTerms"->{<|"Power"->-1,"RegulatorExponent"->2,"LogPower"->1,"LaurentLowerBound"->0,
 "KnownThroughOrder"->2,"Coefficients"-><|0->1,1->v,2->v^2|>,"ExactInEpsilon"->False|>}|>;
request=<|"ThroughOrder"->0,"Interval"->{0,1-v},"NormalVariable"->z,"TangentialVariable"->v|>;
r=CheckStage4EpsilonRemainders[d,<|"A"->endpoint|>,request];
If[r["EpsilonRemainderAudit"]["Status"]=!="Passed",Print[r]];
FTAssert["saved stage 4 audits coefficient poles and logarithmic endpoint moments without new integrals",
 r["EpsilonRemainderAudit"]["Status"]==="Passed"&&r["Result"]["NewIntegralEvaluations"]===0];
bad=endpoint;bad["EndpointTerms"]=ReplacePart[bad["EndpointTerms"],{1,"Coefficients"}-><|0->1,1->v|>];
FTAssert["the actual missing endpoint order is detected even when metadata claims it exists",
 CheckStage4EpsilonRemainders[d,<|"A"->bad|>,request]["EpsilonRemainderAudit"]["Status"]==="Failed"];
bad=d;bad["MasterCoefficientIndex"]=Delete[bad["MasterCoefficientIndex"],2];
FTAssert["holes inside the stored master range cannot pass an upper-order check",
 CheckStage4EpsilonRemainders[bad,<|"A"->endpoint|>,request]["EpsilonRemainderAudit"]["Status"]==="CalculationFailed"];
FTAssert["missing endpoint coverage cannot be reported as a complete order audit",
 CheckStage4EpsilonRemainders[d,<||>,request]["EpsilonRemainderAudit"]["Status"]==="CalculationFailed"];
FTAssert["a shortened interior expansion fails the saved audit",
 CheckStage4EpsilonRemainders[d,<|"A"->endpoint|>,request,"TruncationOrderShift"->-1]["EpsilonRemainderAudit"]["Status"]==="Failed"];
map=<|"DimensionalRegulator"->e,"ReductionMatrix"->{{1/e^2}},"BoundaryIntegralLaurentLowerBounds"->{0}|>;
values=<|1-><|"LaurentCoefficients"-><|0->1,1->1,2->1|>|>|>;
r=CheckBoundaryIntegralEpsilonRemainders[map,{{1,0}},values];
FTAssert["saved stage 3 reduction checks use the available integral coefficients",
 r["EpsilonRemainderAudit"]["Status"]==="Passed"&&r["Result"]["NewIntegralEvaluations"]===0];
FTAssert["a missing positive boundary order contaminates the finite amplitude",
 CheckBoundaryIntegralEpsilonRemainders[map,{{1,0}},<|1-><|"LaurentCoefficients"-><|0->1,1->1|>|>|>]["EpsilonRemainderAudit"]["Status"]==="Failed"];
FTAssert["a missing boundary integral cannot silently count as zero",
 CheckBoundaryIntegralEpsilonRemainders[map,{{1,0}},<||>]["EpsilonRemainderAudit"]["Status"]==="Failed"];
r=WithEpsilonRemainderChecks[
 FeynFacet`Private`epsilonAuditMultiplier[1/e^2,e,0,2,0,"A",1];
 FeynFacet`Private`epsilonAuditMultiplier[1/e^2,e,0,2,0,"B",2]];
FTAssert["identical multiplier checks are reused while distinct source checks remain counted",
 r["EpsilonRemainderAudit"]["Status"]==="Passed"&&r["EpsilonRemainderAudit"]["DistinctMultiplierChecks"]===1&&
 r["EpsilonRemainderAudit"]["RepeatedMultiplierChecksReused"]===1&&Total[Values[r["EpsilonRemainderAudit"]["ChecksByStage"]]]===2];

r=WithEpsilonRemainderChecks[
 FeynFacet`Private`epsilonAuditMultiplier[Gamma[e]/e,e,0,1,0,"Stage4/TestGammaAndMoment",1]];
FTAssert["an omitted epsilon squared coefficient survives a Gamma pole and an endpoint moment at finite order",
 r["EpsilonRemainderAudit"]["Status"]==="Failed"];
r=WithEpsilonRemainderChecks[
 FeynFacet`Private`epsilonAuditMultiplier[Gamma[e]/e,e,0,2,0,"Stage4/TestGammaAndMoment",1]];
FTAssert["one additional input order removes contamination through finite order",
 r["EpsilonRemainderAudit"]["Status"]==="Passed"];
FTAssert["an empty boundary reduction is rejected cleanly",
 CheckBoundaryIntegralEpsilonRemainders[<|"DimensionalRegulator"->e,"ReductionMatrix"->{},
 "BoundaryIntegralLaurentLowerBounds"->{}|>,{},<||>]["EpsilonRemainderAudit"]["Status"]==="CalculationFailed"];
FTReport[];

