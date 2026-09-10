$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
aaK={{aaK11,aaK12},{aaK12,aaK22}};aaGram={{aaG11,aaG12},{aaG12,aaG22}};
aaN=2-2aaE;aaH=-2aaE;
aaLinear=FeynFacet`AverageEvanescentScalarProducts[aaK12,aaK,aaGram,aaE];
FTTest`FTAssert["one projected scalar product has the projected-to-ambient dimension ratio",
 Factor[aaLinear-aaH/aaN aaG12]===0];
aaA=aaH((aaN+1)aaH-2)/(aaN(aaN-1)(aaN+2));
aaB=aaH(aaN-aaH)/(aaN(aaN-1)(aaN+2));
aaMixed=FeynFacet`AverageEvanescentScalarProducts[aaK11 aaK22,aaK,aaGram,aaE];
aaCross=FeynFacet`AverageEvanescentScalarProducts[aaK12^2,aaK,aaGram,aaE];
FTTest`FTAssert["mixed second moments retain correlations between transverse vectors",
 Factor[aaMixed-aaA aaG11 aaG22-2aaB aaG12^2]===0&&
 Factor[aaCross-(aaA+aaB)aaG12^2-aaB aaG11 aaG22]===0];
FTTest`FTAssert["averaging the complete product differs from multiplying separate averages",
 Factor[aaMixed-aaH^2/aaN^2 aaG11 aaG22]=!=0];
Do[
 aaSingle=FeynFacet`AverageEvanescentScalarProducts[aaK11^degree,aaK,aaGram,aaE];
 aaExpected=FeynFacet`AverageEvanescentPowers[aaK11^degree,aaK11,aaG11,aaE];
 FTTest`FTAssert["degree "<>ToString[degree]<>" single-vector moment agrees with the independent beta integral",
 Factor[aaSingle-aaExpected]===0],{degree,1,4}];
aaPositive=FeynFacet`AverageEvanescentScalarProducts[aaK11 aaK22,aaK,{{1,0},{0,1}},aaE,3]/.aaE->-1/2;
(* h=1, n=2: the off-diagonal product is cos(theta)^2 sin(theta)^2. *)
FTTest`FTAssert["a positive-dimensional correlated moment agrees with an ordinary angle integral",
 Factor[aaPositive-Integrate[Cos[aaTheta]^2 Sin[aaTheta]^2,{aaTheta,0,2Pi}]/(2Pi)]===0];
FTTest`FTAssert["when the physical span has rank four, the whole transverse space is evanescent",
 FeynFacet`AverageEvanescentScalarProducts[aaK11 aaK22-aaK12^2,aaK,aaGram,aaE,4]===
 Factor[aaG11 aaG22-aaG12^2]];
FTTest`FTAssert["an angular denominator is not silently treated as invariant",
 FailureQ[FeynFacet`AverageEvanescentScalarProducts[1/(1+aaK12),aaK,aaGram,aaE]]];
FTTest`FTAssert["a nonsymmetric transverse Gram matrix is rejected",
 FailureQ[FeynFacet`AverageEvanescentScalarProducts[aaK11,aaK,{{1,2},{3,4}},aaE]]];
aaGeometry=<|"PhysicalMomenta"->{aaPa,aaPb},"IntegratedMomenta"->{aaL1,aaL2},
 "KinematicRules"->{FeynCalc`SPD[aaPa]->0,FeynCalc`SPD[aaPb]->0,FeynCalc`SPD[aaPa,aaPb]->aaS/2},
 "TimelikeMomentum"->aaPa+aaPb,"DimensionalRegulator"->aaE,"Assumptions"->aaS>0|>;
aaReduced=FeynFacet`AverageEvanescentScalarProducts[FeynCalc`SP[aaL1,aaL2],aaGeometry];
aaFullPair=FeynCalc`FCI[FeynCalc`SPD[aaL1,aaL2]];
FTTest`FTAssert["geometry-aware reduction derives the full transverse Gram without using cut equations",
 AssociationQ[aaReduced]&&Factor[aaReduced["Value"]-aaFullPair+
 (D-4)/(D-2)aaReduced["TransverseGramMatrix"][[1,2]]]===0];
aaDenominator=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
 FeynCalc`Momentum[aaL1+aaL2,D],0,0,{2,-1}]];
aaWithDenominator=FeynFacet`AverageEvanescentScalarProducts[
 aaDenominator FeynCalc`SP[aaL1,aaL2],aaGeometry];
FTTest`FTAssert["a full-dimensional causal propagator is preserved exactly through joint averaging",
 AssociationQ[aaWithDenominator]&&aaWithDenominator["PreservedPropagators"]==={aaDenominator}&&
 Factor[aaWithDenominator["Value"]-aaDenominator aaReduced["Value"]]===0];
aaDependent=FeynFacet`AverageEvanescentScalarProducts[FeynCalc`SP[aaL3]^2,
 Join[aaGeometry,<|"MomentumRules"->{aaL3->aaPa+aaPb-aaL1-aaL2}|>]];
aaDirect=FeynFacet`AverageEvanescentScalarProducts[
 FeynCalc`SP[aaPa+aaPb-aaL1-aaL2]^2,aaGeometry];
FTTest`FTAssert["momentum conservation eliminates dependent evanescent components before averaging",
 AssociationQ[aaDependent]&&AssociationQ[aaDirect]&&Factor[aaDependent["Value"]-aaDirect["Value"]]===0];
FTTest`FTAssert["an undeclared physical transverse reference is rejected",
 FailureQ[FeynFacet`AverageEvanescentScalarProducts[FeynCalc`SP[aaL1,aaExtra],aaGeometry]]];
FTTest`FTAssert["propagators with an undeclared integrated direction are rejected",
 FailureQ[FeynFacet`AverageEvanescentScalarProducts[
 FeynCalc`FAD[aaL1+aaExtra] FeynCalc`SP[aaL1],aaGeometry]]];
FTTest`FTAssert["geometry-aware reduction rejects evanescent angular denominators",
 FailureQ[FeynFacet`AverageEvanescentScalarProducts[
 1/(1+FeynCalc`Pair[FeynCalc`Momentum[aaL1,D-4],FeynCalc`Momentum[aaL1,D-4]]),aaGeometry]]];
FTTest`FTAssert["a null vector is not accepted as a timelike physical witness",
 FailureQ[FeynFacet`AverageEvanescentScalarProducts[FeynCalc`SP[aaL1],
 Join[aaGeometry,<|"TimelikeMomentum"->aaPa|>]]]];
FTTest`FTAssert["geometry-aware angular polynomial degrees are explicit integers",
 aaReduced["EvanescentPolynomialDegree"]===1&&
 aaDependent["EvanescentPolynomialDegree"]===2&&aaDirect["EvanescentPolynomialDegree"]===2];
FTTest`FTReport[];
