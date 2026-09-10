$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
weCharts=FeynFacet`ConstructWeightedEndpointCharts[{rr,ss},{1,2},
 <|"RadialVariable"->rad,"AngularVariables"->{{tt},{uu}}|>];
weA=weCharts["Charts"][[1]];weB=weCharts["Charts"][[2]];
FTTest`FTAssert["weighted charts have the full absolute Jacobians and opposite orientations",
 weA["AbsoluteJacobian"]===rad^2&&weB["AbsoluteJacobian"]===2rad^2&&weB["SignedJacobian"]===-2rad^2];
weMoment[m_,n_]:=1/((n+1)(m+2n+3))+2/((m+1)(m+2n+3));
FTTest`FTAssert["the two sectors cover the square exactly for independent monomial moments",
 And@@Flatten[Table[weMoment[m,n]===1/((m+1)(n+1)),{m,0,5},{n,0,5}]]];
weQ=rr^2+4(1-rr)ss;
weUnits={Factor[(weQ/.weA["SourceVariableSubstitution"])/rad^2],
 Factor[(weQ/.weB["SourceVariableSubstitution"])/rad^2]};
FTTest`FTAssert["the mixed quadratic divisor becomes a radial power and a uniform positive unit",
 FullSimplify[weUnits[[1]]>=1,0<=rad<=1/2&&0<=tt<=1]===True&&
 FullSimplify[weUnits[[2]]>=2,0<=rad<=1/2&&0<=uu<=1]===True];
weAngularA=Integrate[(1+4tt)^(-3/2),{tt,0,1}];
weAngularB=Integrate[2(uu^2+4)^(-3/2),{uu,0,1}];
weContact=FullSimplify[-(weAngularA+weAngularB)/2];
FTTest`FTAssert["an epsilon-suppressed density has its nonzero hidden finite corner contact",
 weContact===-1/4&&Coefficient[ee(rr^2+4ss)^(-3/2),ee,0]===0];
wePush=FeynFacet`PushForwardRadialEndpointDerivative[weA,2,<|{0}->moment0,{1}->moment1|>];
FTTest`FTAssert["nonlinear radial delta derivatives act on every original-coordinate weighted jet",
 AssociationQ[wePush]&&Expand[wePush["Expression"]-
 moment0 FeynFacet`EndpointDeltaDerivative[rr,2,1]FeynFacet`EndpointDeltaDerivative[ss,0,1]+
 2moment1 FeynFacet`EndpointDeltaDerivative[rr,0,1]FeynFacet`EndpointDeltaDerivative[ss,1,1]]===0];
FTTest`FTAssert["unevaluated angular moments cannot masquerade as computed contact coefficients",
 FailureQ[FeynFacet`PushForwardRadialEndpointDerivative[weA,2,<|{0}->moment0|>]]];
weSystem=<|"KinematicVariables"->{rr,ss},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{2aa rr/(rr^2+4ss)}},{{4aa/(rr^2+4ss)}}}|>;
wePull=FeynFacet`PullBackRationalDifferentialSystem[weSystem,{rad,tt},weA["SourceVariableSubstitution"]];
FTTest`FTAssert["the rational DE pullback includes both coordinate derivatives",
 AssociationQ[wePull]&&wePull["ConnectionMatrices"]==={{{2aa/rad}},{{4aa/(1+4tt)}}}];

weFan=FeynFacet`ConstructMonomialEndpointCharts[{rr,ss},
 {{{1,0},{2,1}},{{2,1},{2,2}},{{2,1},{2,0}}},
 <|"ChartVariables"->{{rad,tt},{rad,tt},{rad,tt}}|>];
FTTest`FTAssert["a refined ramified fan is an exact disjoint cover of the positive square",
 AssociationQ[weFan]&&weFan["CoverageVerified"]&&weFan["DisjointInteriorsVerified"]&&
 Lookup[weFan["Charts"],"AbsoluteJacobian"]==={rad^2,2rad^3 tt^2,2rad^3}];
weMixedPush=FeynFacet`PushForwardMonomialEndpointDerivatives[weFan["Charts"][[2]],
 <|rad->2|>,<|{1}->moment1,{2}->moment2|>];
FTTest`FTAssert["a general monomial chart retains the mixed angular powers in contact pushforward",
 AssociationQ[weMixedPush]&&
 weMixedPush["DeltaDerivativeCoefficients"]===<|{0,1}->-2moment2,{1,0}->-2moment1|>];
FTTest`FTAssert["overlapping chart interiors cannot be counted as a sector cover",
 FailureQ[FeynFacet`ConstructMonomialEndpointCharts[{rr,ss},{IdentityMatrix[2],IdentityMatrix[2]}]]];

FTTest`FTReport[];
