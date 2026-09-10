$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
rfSetup=FeynFacet`ReadProcessCard[root<>"/Projects/ppHX_UU_NNLO/NLO/u-g_g-u","Real.State01"];
rfContext=FeynFacet`BuildSimplificationContext[rfSetup];
rfModules=FeynFacet`Private`finiteFieldNormalizeTarget[#,1,1,rfContext,5]&/@{rfa+xa,rfb+xa,-xa};
FTTest`FTAssert["unreduced coefficients retain declared rational fraction variables",
 AllTrue[rfModules,AssociationQ]&&!FreeQ[rfModules,xa]];
rfTargets=Total[KeyValueMap[ReleaseHold[#1]#2&,#]]&/@rfModules;
rfReduction={{1,0},{0,1},{1,1}};
rfComplete=Expand[rfTargets.rfReduction];
FTTest`FTAssert["a redundant target relation cancels fractions in the complete master vector",
 rfComplete==={rfa,rfb}];
FTTest`FTAssert["the final physical-variable check accepts only the complete cancellation",
 (FeynFacet`Private`finiteFieldCertifyPhysicalVariables[#,rfContext]&/@rfComplete)==={rfa,rfb}&&
 Quiet[FeynFacet`Private`finiteFieldCertifyPhysicalVariables[rfa+xa,rfContext]]===$Failed];
FTTest`FTAssert["unknown directions are not made admissible by permitting PDF fractions",
 MemberQ[FeynFacet`Private`finiteFieldTargetContext[
  Join[rfContext,<|"ForbiddenVariables"->Append[rfContext["ForbiddenVariables"],rfUndeclared]|>]]["ForbiddenVariables"],rfUndeclared]];

rfColor=Join[rfContext,<|"ColorRules"->{CF->(CA^2-1)/(2CA)}|>];
FTTest`FTAssert["SU(N) color identities are applied before the physical fraction check",
 FeynFacet`Private`finiteFieldCertifyPhysicalVariables[rfa+xa(CA^2-2CA CF-1),rfColor]===rfa];
FTTest`FTAssert["cancellation across analytic prefactors precedes the variable check",
 FeynFacet`Private`finiteFieldCertifyPhysicalVariables[I/(1-xa)-I xa/(1-xa),rfContext]===I];
rfSigns=FeynFacet`Private`finiteFieldCanonicalizeSignature[#,{s}]&/@{HoldComplete[I s],HoldComplete[-I s],HoldComplete[3I s]};
FTTest`FTAssert["equivalent imaginary prefactors share one signature",
 SameQ@@rfSigns[[All,1]]&&rfSigns[[All,2]]==={1,-1,3}];
rfPower=(1-Global`Epsilon)(2Pi)^(2Global`Epsilon)/
 (2^(1+2Global`Epsilon)Pi^(2Global`Epsilon)-(1+Global`Epsilon)(2Pi)^(2Global`Epsilon));
FTTest`FTAssert["equivalent dimensional-normalization powers cancel by rational algebra",
 FeynFacet`Private`finiteFieldNormalizeRegulatorConstants[rfPower,Global`Epsilon]===1];
rfSupport=Join[rfContext,<|"DimensionlessVariables"->{rfX,rfY},"CoordinateEqualities"->{rfX+rfY==1},"ExternalDistribution"->FeynFacet`Cut[rfX+rfY-1,1]|>];
FTTest`FTAssert["fractions vanish on a declared constrained physical coordinate domain",
 FeynFacet`Private`finiteFieldCertifyPhysicalVariables[rfa+xa(rfX+rfY-1),rfSupport]===rfa];
FTTest`FTAssert["a denominator vanishing on that domain is rejected",
 Quiet[FeynFacet`Private`finiteFieldCertifyPhysicalVariables[1/(rfX+rfY-1),rfSupport]]===$Failed];
FTTest`FTAssert["an undefined color specialization is rejected",
 Quiet[FeynFacet`Private`finiteFieldCertifyPhysicalVariables[1/(CA^2-2CA CF-1),rfColor]]===$Failed];
FTTest`FTAssert["negative-base causal powers are not split as positive constants",
 FeynFacet`Private`finiteFieldNormalizeRegulatorConstants[(-rfs-I rfEta)^Global`Epsilon,Global`Epsilon]===(-rfs-I rfEta)^Global`Epsilon];
FTTest`FTAssert["an equality alone does not authorize external support restriction",
 FeynFacet`Private`finiteFieldReduceCoordinateEqualities[rfX+rfY,
 KeyDrop[rfSupport,"ExternalDistribution"]]===$Failed];
FTTest`FTAssert["a differentiated external cut cannot be reduced to its value on support",
 FeynFacet`Private`finiteFieldReduceCoordinateEqualities[rfX+rfY-1,
 Join[rfSupport,<|"ExternalDistribution"->FeynFacet`Cut[rfX+rfY-1,1]^2|>]]===$Failed];
FTTest`FTAssert["another cut does not authorize the Born equality",
 FeynFacet`Private`finiteFieldReduceCoordinateEqualities[rfX+rfY,
 Join[rfSupport,<|"ExternalDistribution"->FeynFacet`Cut[rfX,1]|>]]===$Failed];
rfVirtual=FeynFacet`ReadProcessCard[root<>"/Projects/ppHX_UU_NNLO/NLO/u-g_g-u","Virtual"];
rfVirtualContext=Join[FeynFacet`BuildSimplificationContext[rfVirtual],
 <|"ExternalDistribution"->FeynFacet`Cut[FeynCalc`SPD[ka+kb-kc],1]|>];
FTTest`FTAssert["the generated one-particle recoil cut authorizes its Born coordinate equality",
 FeynFacet`Private`finiteFieldCoordinateSupportQ[rfVirtualContext]];
FTTest`FTReport[];
