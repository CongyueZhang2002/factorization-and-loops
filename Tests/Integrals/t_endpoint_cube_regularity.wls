Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
record[factor_]:=<|"JointAnalyticFactorsVerified"->True,"NormalVariables"->{rx,ry},
 "DimensionalRegulator"->re,"Terms"->{<|"Powers"->{-re,-2re},"SmoothFactor"->factor|>}|>;
good=Gamma[1+re]/re^2*(1+rx+ry)^re/(2-rx ry)*
 Hypergeometric2F1[1,1+re,2+re,-rx/(2-ry)];
FTTest`FTAssert["closed-cube verification includes regular rational and real Gauss factors",
 AssociationQ[FeynFacet`VerifyResolvedEndpointCube[record[good]]]];
FTTest`FTAssert["an inactive Gauss function with a rational sum argument is verified without expansion",
 AssociationQ[FeynFacet`VerifyResolvedEndpointCube[record[
  Inactive[Hypergeometric2F1][1,3+re,4,1+(-2+rx)(-2+rx ry)/(2(-2-2ry+rx ry))]]]]];
FTTest`FTAssert["an interior pole cannot pass a corner-only analyticity check",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[1/(1-rx-ry)]]]];
FTTest`FTAssert["artificial sector seams are included in the nonzero-unit check",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[1/(1-rx)]]]];
FTTest`FTAssert["a regulator-dependent denominator with a moving interior zero is rejected",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[1/(rx+re)]]]];
FTTest`FTAssert["a Gauss branch reaching one on a seam is not claimed uniformly analytic",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[Hypergeometric2F1[1,1+re,2+re,rx]]]]];
FTTest`FTAssert["empty assumptions cannot establish an endpoint proof vacuously",
 MatchQ[FeynFacet`VerifyResolvedEndpointCube[record[1],False],Failure["NonemptyEndpointParameterDomainRequired",_]]];
FTTest`FTAssert["caller assumptions cannot exclude part of the normal-coordinate cube",
 MatchQ[FeynFacet`VerifyResolvedEndpointCube[record[1/(1-rx)],rx<1/2],
 Failure["CoordinateIndependentEndpointParameterConditionsRequired",_]]];
FTTest`FTAssert["coordinate-independent essential regulator singularities cannot be cleared as finite poles",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[Exp[1/re]/(1+rx)]]]];
FTTest`FTAssert["an essential regulator dependence in a hypergeometric parameter is rejected",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[Hypergeometric2F1[Exp[1/re],1,2,-rx]]]]];
FTTest`FTAssert["constant Gamma poles and causal scale powers have an explicit meromorphic check",
 AssociationQ[FeynFacet`VerifyResolvedEndpointCube[record[Gamma[-re]Exp[I Pi re]rs^-re/(2-rx)],rs>0]]];
FTTest`FTAssert["parameter-domain zeros in regulator-independent denominators are rejected",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[1/(re (ca-cb))],ca==cb]]];
FTTest`FTAssert["analytic regulator exponents require finite coefficients on the parameter domain",
 FailureQ[FeynFacet`VerifyResolvedEndpointCube[record[Exp[re/(ca-cb)]],ca==cb]]];
Print["ENDPOINT CUBE REGULARITY TEST COMPLETE"];FTTest`FTReport[];
