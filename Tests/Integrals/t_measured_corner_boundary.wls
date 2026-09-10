$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
ceBoundary=<|"DataType"->"MeasuredRecoilBoundaryIntegral","AngularAxis"->"TaggedParticle",
 "UniformAnalyticFactorization"->True,"Parameters"->{ceR,ceU,ceB},
 "AngularFractionSymbol"->ceY,"DimensionalRegulator"->ceEps,"MeasurementVariable"->ceZ,
 "Prefactor"->ceZ^-ceEps(1-ceZ)^(1-2ceEps),
 "ScalarIntegrand"->1/(ceZ ceU+(1-ceZ)ceR),"NormalExponent"->-2ceEps,
 "MasterIntegral"->ceIntegral|>;
ceTerms=FeynFacet`ConstructMeasuredCornerBoundaryTerms[ceBoundary,<|"MaximumOrdinarySeriesOrder"->1|>];
FTTest`FTAssert["an additive angular denominator retains both regulator slopes",
 AssociationQ[ceTerms]&&Sort[ceTerms["AllowedRegulatorSlopes"]]==={-3,-2}];
ceHard=Select[ceTerms["Terms"],#["Branch"]==="Ordinary"&];
ceEndpoint=SelectFirst[ceTerms["Terms"],#["Branch"]==="AdditiveDenominatorEndpoint"&];
ceAlpha=1-ceEps;
ceExpected=Gamma[ceAlpha]Gamma[1-ceAlpha]Beta[2ceAlpha-1,ceAlpha]/Beta[ceAlpha,ceAlpha]^2;
FTTest`FTAssert["the suppressed endpoint coefficient has the independent Euler connection normalization",
 FullSimplify[FunctionExpand[ceEndpoint["Value"]-ceExpected]]===0];
FTTest`FTAssert["a second singular radial endpoint is outside the two-family acceptance proof",
 FailureQ[FeynFacet`ConstructMeasuredCornerBoundaryTerms[
  Join[ceBoundary,<|"ScalarIntegrand"->ceBoundary["ScalarIntegrand"]/(1-ceR)|>]]]];
ceNumericEps=-7/5;ceShape=1-ceNumericEps;ceDistance=10^-12;ceZvalue=1-ceDistance;
ceInner[eta_?NumericQ]:=If[TrueQ[eta==0],(2ceShape-1)/(ceShape-1),
 eta^-1 Hypergeometric2F1[1,ceShape,2ceShape,-1/eta]];
ceIntegrand[t_?NumericQ]:=t^(ceShape-1)(1-t)^(ceShape-1)/Beta[ceShape,ceShape]*
 (ceZvalue+ceDistance t)^(-2ceShape) ceInner[ceDistance t/ceZvalue];
{ceSeconds,ceNumeric}=AbsoluteTiming[TimeConstrained[
 ceZvalue^(-2ceNumericEps) NIntegrate[ceIntegrand[ceR],{ceR,0,1},
 WorkingPrecision->60,AccuracyGoal->42,PrecisionGoal->42,
 Method->{"GlobalAdaptive","SymbolicProcessing"->0}],30,$Failed]];
ceOrdinary=(ceHard[[1]]["Value"]+ceDistance ceHard[[2]]["Value"])/.ceEps->ceNumericEps;
ceExpectedNumeric=N[ceEndpoint["Value"]/.ceEps->ceNumericEps,50];
ceExtracted=(ceNumeric-ceOrdinary)/ceDistance^(ceShape-1);
ceError=N[Abs[ceExtracted-ceExpectedNumeric]/(1+Abs[ceExpectedNumeric]),12];
Print["SUPPRESSED BRANCH CHECK SECONDS ",ceSeconds," RELATIVE ERROR ",ceError];
FTTest`FTAssert["a convergent one-dimensional quadrature resolves the suppressed noninteger branch",
 NumberQ[ceError]&&ceError<10^-5];

ceSystem=<|"Variable"->ceSigma,"DimensionalRegulator"->ceEps,
 "ConnectionMatrix"->DiagonalMatrix[{-2ceEps/ceSigma,(-1-2ceEps)/ceSigma}]|>;
cePrep=FeynFacet`PrepareSingularBoundarySystem[ceSystem];
cePhysical=<|1-><|"AllowedRegulatorSlopes"->{-2},"Terms"->{
 <|"Exponent"->-2ceEps,"Value"->Gamma[1-ceEps]|>}|>,
 2-><|"AllowedRegulatorSlopes"->{-2},"Terms"->{
 <|"Exponent"->-2ceEps,"Value"->0|>}|>|>;
ceMatch=FeynFacet`MatchPhysicalBoundaryCoefficients[cePrep,<|"ObservableMatrix"->IdentityMatrix[2],
 "PhysicalCoefficients"->cePhysical,"ValidationPoints"->{{ceEps->-7/5},{ceEps->-8/5}}|>];
FTTest`FTAssert["an onset zero fixes a constant invisible to the supplied nonzero coefficients",
 AssociationQ[ceMatch]&&ceMatch["BoundaryConstantCount"]===2&&
 MemberQ[Lookup[ceMatch["SelectedMatchingEquations"],"Branch"],"VanishingPhysicalCoefficient"]];
If[AssociationQ[ceMatch],
 ceVector=cePrep["NormalizedToOriginalGauge"].ceMatch["NormalizedSeedMatrix"].ceMatch["InitialConstantValues"];
 FTTest`FTAssert["the matched diagonal-system solution has the expected exact amplitude vector",
  FullSimplify[ceVector-{Gamma[1-ceEps],0}]===ConstantArray[0,2]],
 FTTest`FTAssert["the matched diagonal-system solution has the expected exact amplitude vector",False]];

ceCompeting=FeynFacet`ConstructMeasuredCornerBoundaryTerms[Join[ceBoundary,<|
 "ScalarIntegrand"->(ceZ ceU^2+1-ceZ)/(ceZ ceU+(1-ceZ)ceR)|>]];
ceCompetingTerms=Select[ceCompeting["Terms"],#["Branch"]==="AdditiveDenominatorEndpoint"&];
ceCompetingNonzero=Select[ceCompetingTerms,!TrueQ[FullSimplify[#["Value"]]===0]&];
FTTest`FTAssert["the joint endpoint valuation retains a subleading external numerator term",
 AssociationQ[ceCompeting]&&Length[ceCompetingNonzero]>0&&
 First[ceCompetingNonzero]["Exponent"]===2-3ceEps&&
 FullSimplify[FunctionExpand[First[ceCompetingNonzero]["Value"]-ceExpected]]===0];
ceAngularZero=FeynFacet`ConstructMeasuredCornerBoundaryTerms[Join[ceBoundary,<|
 "ScalarIntegrand"->(ceY-ceR)^2/(ceZ ceU+(1-ceZ)ceR)|>]];
ceAngularNonzero=Select[ceAngularZero["Terms"],#["Branch"]==="AdditiveDenominatorEndpoint"&&
 !TrueQ[FullSimplify[#["Value"]]===0]&];
ceAngularExpected=2/ceAlpha*Gamma[ceAlpha+1]Gamma[-ceAlpha]*
 Beta[2ceAlpha+1,ceAlpha+1]/Beta[ceAlpha,ceAlpha]^2;
FTTest`FTAssert["a vanishing pointwise angular numerator keeps its nonzero averaged jet",
 AssociationQ[ceAngularZero]&&First[ceAngularNonzero]["Exponent"]===2-3ceEps&&
 FullSimplify[FunctionExpand[First[ceAngularNonzero]["Value"]-ceAngularExpected]]===0];
FTTest`FTAssert["a possible next power is not labeled as a certified error bound",
 ceTerms["RemainderCertifiedThrough"]===None];

FTTest`FTReport[];
