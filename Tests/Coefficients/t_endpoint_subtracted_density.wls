#!/usr/bin/env wolframscript
subtractionTestRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[subtractionTestRoot<>"/Tests/TestKit.wl"];
Get[subtractionTestRoot<>"/FeynFacet/Solutions/Orders/LaurentBounds.wl"];
Get[subtractionTestRoot<>"/FeynFacet/Solutions/SharedDefinitions.wl"];
Get[subtractionTestRoot<>"/FeynFacet/Coefficients/EndpointOrders.wl"];
Get[subtractionTestRoot<>"/FeynFacet/Coefficients/Distributions.wl"];
Get[subtractionTestRoot<>"/FeynFacet/Coefficients/FiniteDensity.wl"];
Get[subtractionTestRoot<>"/FeynFacet/Coefficients/PoleCancellation.wl"];
Get[subtractionTestRoot<>"/FeynFacet/Coefficients/EndpointSubtraction.wl"];
Clear[subtractionTestE,subtractionTestX,subtractionTestW,subtractionTestV,subtractionTestZ,subtractionTestT,subtractionTestU];
subtractionTestKernel[x_]:=<|"Index"->1,"Parameter"->subtractionTestT,"Expression"->x|>;
subtractionTestIntegral=<|"Index"->1,"IntegrationVariable"->subtractionTestT,
 "UpperLimitVariable"->subtractionTestU,"LowerLimit"->0,"Integrand"->FeynFacetSolution`K[1,subtractionTestT]|>;
subtractionTestFull=<|"DataType"->"FiniteMasterIntegralDensity",
 "PhysicalMasterNormalizationApplied"->True,"PhysicalBoundaryCoefficientsResolved"->True,
 "UnknownInitialConstantCount"->0,"EndpointSubtractionsApplied"->False,
 "DimensionalRegulator"->subtractionTestE,"KinematicVariables"->{subtractionTestX,subtractionTestW},
 "EpsilonOrderRange"->{0,0},"EpsilonIndependentPrefactor"->3,
 "Coefficients"-><|0->3((FeynFacetSolution`a[1]+FeynFacetSolution`a[2])/(1-subtractionTestX-subtractionTestW)+
   FeynFacetSolution`F[1,subtractionTestX]+subtractionTestW)|>,
 "MasterOrderRequirements"->{<|"Master"->{"A",{1}}|>,<|"Master"->{"B",{1}}|>},
 "AlgebraicDefinitions"->{2+11subtractionTestX,5},"KernelDefinitions"->{subtractionTestKernel[7]},
 "IntegralDefinitions"->{subtractionTestIntegral},"SourceCoefficientFile"->"physical-coefficients.wxf"|>;
subtractionTestTerm[c_]:=<|"Power"->-1,"RegulatorExponent"->-2,"LogPower"->0,
 "LaurentLowerBound"->0,"KnownThroughOrder"->1,"Coefficients"->c,"ExactInEpsilon"->True|>;
subtractionTestEndpoint[id_,coef_,aa_,kk_,ff_]:=<|
 "DataType"->"FiniteScalarEndpointSolution","DimensionalRegulator"->subtractionTestE,
 "NormalVariable"->subtractionTestZ,"TangentialVariable"->subtractionTestV,
 "ThroughOrder"->0,"PhysicalBoundaryValuesApplied"->True,"RequiredInitialConstantCoefficients"->{},
 "GlobalPrefactorIncluded"->True,"GlobalPrefactor"->3,
 "CoefficientTailSufficiency"-><|"Status"->"SufficientOrdersDetermined","MissingCoefficientOrders"->{},
   "UnresolvedCoefficientRemainderClasses"->{}|>,
 "ProjectedMasterIdentities"->{id},"SourceCoefficientFile"->"physical-coefficients.wxf",
 "EndpointTerms"->{subtractionTestTerm[coef]},
 "AlgebraicDefinitions"->aa,"KernelDefinitions"->kk,"IntegralDefinitions"->ff|>;
subtractionTestA=subtractionTestEndpoint[{"A",{1}},<|
 0->3(FeynFacetSolution`a[1]+FeynFacetSolution`F[1,subtractionTestV]),1->3FeynFacetSolution`a[2]|>,
 {2,3},{subtractionTestKernel[11]},{subtractionTestIntegral}];
subtractionTestB=subtractionTestEndpoint[{"B",{1}},<|0->3FeynFacetSolution`a[1],1->0|>,{5},{},{}];
subtractionTestEndpoints=<|"A"->subtractionTestA,"B"->subtractionTestB|>;
subtractionTestRequest=<|"NormalVariable"->subtractionTestZ,"TangentialVariable"->subtractionTestV,
 "ThroughOrder"->0,"KinematicRules"->{subtractionTestX->subtractionTestV,
 subtractionTestW->1-subtractionTestV-subtractionTestZ},"CoordinateJacobianIncluded"->True,
 "Interval"->{0,1-subtractionTestV},"Assumptions"->0<subtractionTestV<1,
 "TestFunctionDomain"->"ThresholdCompactSupport","EndpointConditions"-><|
  "NoInteriorSingularities"->True,"UniformEpsilonExpansionOnCompactSubsets"->True,
  "RepresentationValidOnHalfOpenInterval"->True|>|>;
subtractionTestResult=AssembleEndpointSubtractedDensity[subtractionTestFull,subtractionTestEndpoints,subtractionTestRequest];
FTAssert["full master coverage produces explicit delta, plus and regular coefficients",
 AssociationQ[subtractionTestResult]&&subtractionTestResult["MasterCount"]===2&&
 subtractionTestResult["EpsilonOrderRange"]==={-1,0}];
(* Independent evaluation of the elementary integral definitions. *)
subtractionTestResolve[data_,expr_]:=Module[{ks={},fs={},as={},kr,fr,ar,rewrite,def,value},
 {kr,fr,ar}=Lookup[data,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}];
 rewrite[x_]:=x/.{FeynFacetSolution`K[j_Integer,u_]:>(ks[[j]]/.kr[[j,"Parameter"]]->u),
  FeynFacetSolution`F[j_Integer,u_]:>(fs[[j]]/.fr[[j,"UpperLimitVariable"]]->u),
  FeynFacetSolution`a[j_Integer]:>as[[j]]};
 Do[AppendTo[ks,rewrite[def["Expression"]]],{def,kr}];
 Do[value=rewrite[def["Integrand"]];AppendTo[fs,Integrate[value,
  {def["IntegrationVariable"],def["LowerLimit"],def["UpperLimitVariable"]}]],{def,fr}];
 Do[AppendTo[as,rewrite[value]],{value,ar}];rewrite[expr]];
If[AssociationQ[subtractionTestResult],
 subtractionTestDelta=subtractionTestResolve[subtractionTestResult,First[subtractionTestResult["DeltaTerms"]]["Coefficients"]];
 subtractionTestPlus=subtractionTestResolve[subtractionTestResult,First[subtractionTestResult["PlusTerms"]]["Coefficients"]];
 subtractionTestRegular=subtractionTestResolve[subtractionTestResult,subtractionTestResult["RegularRemainderCoefficients"]];
 FTAssert["variable-interval delta coefficients include the epsilon-one endpoint amplitude",
  Expand[subtractionTestDelta[-1]+(21+33subtractionTestV)/2]===0&&
  Expand[subtractionTestDelta[0]-(21+33subtractionTestV)Log[1-subtractionTestV]+9/2]===0];
 FTAssert["plus coefficient includes the global prefactor once",
  Expand[subtractionTestPlus[0]-21-33subtractionTestV]===0];
 FTAssert["regular remainder retains complete interior dependence",
  Expand[subtractionTestRegular[0]-3(1+6subtractionTestV-subtractionTestZ)]===0&&
  subtractionTestRegular[-1]===0];
 FTAssert["independent local kernel integral and algebraic indices remain distinct",
  Length[subtractionTestResult["KernelDefinitions"]]===2&&
  Length[subtractionTestResult["IntegralDefinitions"]]===2&&
  Length[subtractionTestResult["AlgebraicDefinitions"]]===5];
 FTAssert["the upper endpoint remains outside the asserted distribution domain",
  TrueQ[subtractionTestResult["DomainConvention"]["UpperEndpointExcluded"]]];
 FTAssert["all finite coefficients and definitions survive a strict binary round trip",
  BinaryDeserialize[BinarySerialize[subtractionTestResult,PerformanceGoal->"Size"]]===subtractionTestResult]
];
subtractionTestRun[eps_,req_:subtractionTestRequest,full_:subtractionTestFull]:=
 AssembleEndpointSubtractedDensity[full,eps,req];
FTAssert["missing weighted master endpoint is rejected",
 MatchQ[subtractionTestRun[KeyDrop[subtractionTestEndpoints,"B"]],Failure["EndpointMasterCoverageMismatch",_Association]]];
FTAssert["duplicate weighted master endpoint is rejected",
 MatchQ[subtractionTestRun[Join[subtractionTestEndpoints,<|"duplicate"->subtractionTestA|>]],
 Failure["EndpointMasterCoverageMismatch",_Association]]];
FTAssert["unresolved coalescing coefficient tail cannot be accepted",
 MatchQ[subtractionTestRun[Join[subtractionTestEndpoints,<|"A"->Join[subtractionTestA,<|
 "CoefficientTailSufficiency"-><|"Status"->"CoefficientRemainderClassUnresolved","MissingCoefficientOrders"->{}|>|>]|>]],
 Failure["UniformEndpointCoefficientTailRequired",_Association]]];
FTAssert["mismatched physical coefficient source is rejected",
 MatchQ[subtractionTestRun[Join[subtractionTestEndpoints,<|"A"->Join[subtractionTestA,
 <|"SourceCoefficientFile"->"another-physical-table.wxf"|>]|>]],
 Failure["EndpointCoefficientSourceMismatch",_Association]]];
FTAssert["missing epsilon order in full density is rejected",
 MatchQ[subtractionTestRun[subtractionTestEndpoints,Join[subtractionTestRequest,<|"ThroughOrder"->1|>]],
 Failure["FullInteriorCoefficientOrdersInsufficient",_Association]]];
FTAssert["unresolved boundary constants cannot enter final result",
 MatchQ[subtractionTestRun[subtractionTestEndpoints,subtractionTestRequest,Join[subtractionTestFull,
 <|"AlgebraicDefinitions"->{FeynFacetSolution`B[1,0],5}|>]],
 Failure["ExplicitAcyclicFiniteDefinitionsRequired",_Association]]];
FTAssert["implicit coordinate Jacobian is rejected",
 MatchQ[subtractionTestRun[subtractionTestEndpoints,KeyDrop[subtractionTestRequest,"CoordinateJacobianIncluded"]],
 Failure["EndpointCoordinateMapAndIncludedJacobianRequired",_Association]]];
FTAssert["unresolved interior moving pole cannot be approved by a half-open domain",
 MatchQ[subtractionTestRun[subtractionTestEndpoints,Join[subtractionTestRequest,<|"EndpointConditions"-><|
 "NoInteriorSingularities"->False,"UniformEpsilonExpansionOnCompactSubsets"->True,
 "RepresentationValidOnHalfOpenInterval"->True|>|>]],Failure["EndpointDistributionExtractionFailed",_Association]]];
FTAssert["an additional scalar density term requires its own endpoint treatment",
 MatchQ[subtractionTestRun[subtractionTestEndpoints,subtractionTestRequest,Join[subtractionTestFull,
 <|"ScalarRemainderCoefficients"-><|0->1|>|>]],
 Failure["ScalarRemainderEndpointCoverageRequired",_Association]]];

subtractionPole=<|"Master"->{"A",{1}},"PoleLabel"->"M1","SourceTermIndex"->1,
 "PoleExpression"->5/(subtractionTestZ+subtractionTestE)|>;
subtractionTestRest=Join[subtractionTestA,<|"SeparatedCoefficientPoles"->{subtractionPole},
 "EndpointTerms"->{Join[First[subtractionTestA["EndpointTerms"]],<|
 "Coefficients"->Join[First[subtractionTestA["EndpointTerms"]]["Coefficients"],
  <|0->First[subtractionTestA["EndpointTerms"]]["Coefficients"][0]-5|>]|>]}|>];
subtractionTestPart=Join[subtractionTestB,<|"ProjectedMasterIdentities"->{},
 "AlgebraicDefinitions"->{},"EndpointTerms"->{subtractionTestTerm[<|0->5,1->0|>]},
 "PartialCoefficientContributions"->{subtractionPole}|>];
subtractionSplit=<|"A"->subtractionTestRest,"B"->subtractionTestB,"M1"->subtractionTestPart|>;
subtractionSplitResult=subtractionTestRun[subtractionSplit];
subtractionEquivalent[x_,y_]:=Which[x===y,True,
 AssociationQ[x]&&AssociationQ[y]&&Keys[x]===Keys[y],
  And@@KeyValueMap[subtractionEquivalent[#2,y[#1]]&,x],
 ListQ[x]&&ListQ[y]&&Length[x]===Length[y],And@@MapThread[subtractionEquivalent,{x,y}],
 True,TrueQ[Expand[x-y]===0]];
FTAssert["an exact coefficient decomposition reproduces delta, plus and the full regular remainder",
 AssociationQ[subtractionSplitResult]&&And@@Table[
  subtractionEquivalent[subtractionTestResolve[subtractionSplitResult,subtractionSplitResult[key]],
   subtractionTestResolve[subtractionTestResult,subtractionTestResult[key]]],
  {key,{"DeltaTerms","PlusTerms","RegularRemainderCoefficients"}}]];
FTAssert["complete master identities alone cannot hide a missing separated pole",
 MatchQ[subtractionTestRun[KeyDrop[subtractionSplit,"M1"]],
  Failure["EndpointCoefficientPoleCoverageMismatch",_Association]]];
FTAssert["a repeated partial contribution is rejected even without a repeated full master",
 MatchQ[subtractionTestRun[Join[subtractionSplit,<|"M1again"->subtractionTestPart|>]],
  Failure["EndpointCoefficientPoleCoverageMismatch",_Association]]];
subtractionDomainA=Join[subtractionTestA,<|"CoefficientTailSufficiency"->Join[
 subtractionTestA["CoefficientTailSufficiency"],<|
 "CoefficientRemainderDomainConditions"->{subtractionTestV!=1/2}|>]|>];
subtractionDomainResult=subtractionTestRun[Join[subtractionTestEndpoints,<|"A"->subtractionDomainA|>]];
FTAssert["tangential restrictions of a finite remainder survive the final assembly",
 AssociationQ[subtractionDomainResult]&&
 (subtractionDomainResult["TangentialAssumptions"]/.subtractionTestV->1/2)===False];


subtractionTestBadMap=Join[subtractionTestRequest,<|"KinematicRules"->{subtractionTestX->FeynFacetSolution`a[999],
 subtractionTestW->1-subtractionTestV-subtractionTestZ}|>];
FTAssert["a coordinate map cannot inject a reference into the already checked definition graph",
 MatchQ[AssembleEndpointSubtractedDensity[subtractionTestFull,subtractionTestEndpoints,subtractionTestBadMap],
 Failure["ScalarKinematicCoordinateRulesRequired",_]]];
subtractionTestUndefined=Join[subtractionTestFull,<|"AlgebraicDefinitions"->{1/subtractionTestX,5}|>];
subtractionTestBadMap=Join[subtractionTestRequest,<|"KinematicRules"->{subtractionTestX->0,
 subtractionTestW->1-subtractionTestV-subtractionTestZ}|>];
FTAssert["undefined values created by coordinate substitution still fail the final check",
 MatchQ[Quiet[AssembleEndpointSubtractedDensity[subtractionTestUndefined,subtractionTestEndpoints,subtractionTestBadMap]],
 Failure["ExplicitClosedPhysicalCoefficientsRequired",_]]];

subtractionTestConstructed=Join[subtractionTestFull,<|"AlgebraicDefinitions"->{1,
 If[subtractionTestX==0,Head[FeynFacetSolution`a[1]][999],1]}|>];
FTAssert["effectful coordinate evaluation retains the full graph check for a constructed out-of-range reference",
 FailureQ[Quiet[AssembleEndpointSubtractedDensity[subtractionTestConstructed,subtractionTestEndpoints,subtractionTestBadMap]]]];
subtractionTestConstructed=Join[subtractionTestFull,<|"AlgebraicDefinitions"->{1,
 If[subtractionTestX==0,Head[FeynFacetSolution`a[1]][2],1]}|>];
FTAssert["effectful coordinate evaluation cannot introduce an in-range self-reference",
 FailureQ[Quiet[AssembleEndpointSubtractedDensity[subtractionTestConstructed,subtractionTestEndpoints,subtractionTestBadMap]]]];
FTAssert["the fast expression grammar excludes expression inspection but admits ordinary finite functions",
 !FeynFacet`Private`endpointSubtractionReferencePreservingQ[If[subtractionTestX==0,Head[FeynFacetSolution`a[1]][2],1]]&&
 FeynFacet`Private`endpointSubtractionReferencePreservingQ[Log[1-subtractionTestX]+FeynFacetSolution`a[1]/(1+subtractionTestX)]];
FTReport[];


