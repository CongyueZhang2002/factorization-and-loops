$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mpBilinear[a_,b_,constant_:0]:=FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[0,2FeynCalc`FCI[FeynCalc`SPD[a,b]],constant,{1,1}]];
mpTop=FeynCalc`FCTopology[MeasuredThreeParticle,{
 FeynCalc`FCI[FeynCalc`SFAD[mpK1]],FeynCalc`FCI[FeynCalc`SFAD[mpK2]],
 FeynCalc`FCI[FeynCalc`SFAD[mpP+mpR-mpK1-mpK2]],
 mpBilinear[mpP,mpK1,-mpZ mpQ/mpX],mpBilinear[mpP,mpK2],
 mpBilinear[mpR,mpK1],mpBilinear[mpR,mpK2]},
 {mpK1,mpK2},{mpP,mpR},FeynCalc`FCI[{FeynCalc`SPD[mpP]->0,
 FeynCalc`SPD[mpR]->-mpQ,FeynCalc`SPD[mpP,mpR]->mpQ/(2mpX)}],{}];
mpFamily=FeynFacet`CreateCutIntegralFamily[<|"Topology"->mpTop,
 "Cuts"->{<|"Index"->1,"Type"->"Particle","Momentum"->mpK1|>,
  <|"Index"->2,"Type"->"Particle","Momentum"->mpK2|>,
  <|"Index"->3,"Type"->"Particle","Momentum"->mpP+mpR-mpK1-mpK2|>,
  <|"Index"->4,"Type"->"Measurement"|>},
 "TimeDirection"->mpP+mpR,"Assumptions"->mpQ>0&&0<mpX<1&&0<mpZ<1,
 "Dimension"->D,"MeasurePrefactor"->(2Pi)^(3-2D)mpQ/mpX|>];
mpPrescribedTop=ReplacePart[mpTop,{2,5}->FeynCalc`FCI[FeynCalc`SFAD[mpP-mpK2]]];
mpPrescribed=FeynFacet`CreateCutIntegralFamily[Join[mpFamily,<|"Topology"->mpPrescribedTop|>]];
mpRequest=<|"MeasurementVariable"->mpZ,"ReferenceMomentum"->mpP,"TaggedMomentum"->mpK1,
 "ExternalKinematicConditions"->mpQ>0&&0<mpX<1|>;

mpMaster=FeynCalc`GLI[MeasuredThreeParticle,{1,1,1,1,2,0,0}];
mpJoint=Join[mpRequest,<|"JointExternalDomain"-><|
 "ExternalIntervals"-><|mpX->{mpMin,1}|>,"Assumptions"->mpQ>0&&0<mpMin<1,
 "TimeDirection"->2mpP+mpR|>,
 "ScalarCoefficients"->{1/((1-mpX)^3 mpZ (1-mpZ)^2 (D-6))}|>];
mpResult=FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpPrescribed,mpMaster,mpJoint];
If[!AssociationQ[mpResult],Print[mpResult]];
FTTest`FTAssert["unit cuts and endpoint divisors admit the joint compact-domain certificate",
 AssociationQ[mpResult]&&mpResult["Status"]==="CertifiedJointEndpointDistributions"&&
 mpResult["CommonConvergenceDomainExists"]===True&&mpResult["ExplicitDimensionThresholdKnown"]===False&&
 FeynFacet`RequireOrdinaryPrescriptionCertificate[mpResult,"EndpointDistributions"]===True];
FTTest`FTAssert["the certificate retains the full unscaled transverse Gram and atom-free joint measure",
 AssociationQ[mpResult]&&Dimensions[mpResult["JointTransverseGramMatrix"]]==={2,2}&&
 mpResult["JointMeasureHasNoEndpointAtoms"]===True&&mpResult["EndpointCoefficientsComputed"]===False&&
 Factor[mpResult["GramPolynomial"]-Det[mpResult["JointTransverseGramMatrix"]]]===0];
FTTest`FTAssert["a divisor with a zero inside the physical chamber is rejected",
 MatchQ[FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpPrescribed,mpMaster,
 Join[mpJoint,<|"ScalarCoefficients"->{1/(mpX-mpZ)}|>]],
 Failure["JointCoefficientDivisorGramContainmentNotEstablished",_]]];
FTTest`FTAssert["moving poles cannot be removed by a large-dimension assertion",
 MatchQ[FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpPrescribed,mpMaster,
 Join[mpJoint,<|"ScalarCoefficients"->{1/(D(1-mpX)-1)}|>]],
 Failure["MixedDimensionKinematicDivisorNeedsUniformProof",_]]];
FTTest`FTAssert["dotted final cuts require a joint normal-derivative theorem",
 MatchQ[FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpPrescribed,
 FeynCalc`GLI[MeasuredThreeParticle,{2,1,1,1,2,0,0}],mpJoint],
 Failure["JointUnitCutPhaseSpaceRequired",_]]];
FTTest`FTAssert["an endpoint-dependent dimensional rescaling cannot hide lost Gram powers",
 MatchQ[FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpPrescribed,mpMaster,
 Join[mpJoint,<|"ScalarCoefficients"->{(1-mpX)^(-D)}|>]],
 Failure["RationalJointSpatialCoefficientRequired",_]]];

mpMixedSafe=FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpPrescribed,mpMaster,
 Join[mpJoint,<|"ScalarCoefficients"->{1/((D-4)+(D-2)mpX)}|>]];
FTTest`FTAssert["a uniform nonzero leading coefficient bounds all moving dimension roots",
 AssociationQ[mpMixedSafe]&&MemberQ[Lookup[mpMixedSafe["JointCoefficientDivisorCertificates"],"Method"],
 "UniformPolynomialRootBound"]];

FTTest`FTReport[];
