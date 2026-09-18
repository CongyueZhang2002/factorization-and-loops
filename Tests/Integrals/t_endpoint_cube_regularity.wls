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
Print["ENDPOINT CUBE REGULARITY TEST COMPLETE"];FTTest`FTReport[];
