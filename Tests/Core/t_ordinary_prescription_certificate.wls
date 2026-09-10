$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
causalSource=<|"Topology"->FeynCalc`FCTopology[causalFamily,
 {FeynCalc`SFAD[causalL],FeynCalc`SFAD[causalKa+causalKb-causalPc-causalL],FeynCalc`SFAD[causalKa-causalL]},
 {causalL},{causalKa,causalKb,causalPc},FeynCalc`FCI[{FeynCalc`SPD[causalKa]->0,FeynCalc`SPD[causalKb]->0,FeynCalc`SPD[causalPc]->0,
 FeynCalc`SPD[causalKa,causalKb]->1/2,FeynCalc`SPD[causalKa,causalPc]->1/8,FeynCalc`SPD[causalKb,causalPc]->1/8}],{}],
 "CutIndices"->{1,2},"CutDirections"->{1,1},"Prescription"->{0},"DimensionalRegulator"->causalEps,"KinematicConditions"->True|>;
causalMaster=FeynCalc`GLI[causalFamily,{1,1,1}];
causalCertificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSource,causalMaster];

FTTest`FTAssert["undotted generic physical integral is certified",AssociationQ[causalCertificate]&&causalCertificate["Status"]==="CertifiedGenericKinematics"];
FTTest`FTAssert["the certificate does not claim endpoint distributions",causalCertificate["EndpointDistributionStatus"]==="NotCertified"];
FTTest`FTAssert["the Gram exponent comes from the actual external frame",causalCertificate["GramExponent"]===(-1-2causalEps)/2];
FTTest`FTAssert["dotted cuts use the same mass-deformation proof",FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSource,FeynCalc`GLI[causalFamily,{2,1,1}]]["Status"]==="CertifiedGenericKinematics"];
FTTest`FTAssert["arbitrarily high finite ordinary powers admit some convergence domain",FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSource,FeynCalc`GLI[causalFamily,{1,1,100}]]["Status"]==="CertifiedGenericKinematics"];
FTTest`FTAssert["noninteger powers fail closed",FailureQ[FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSource,FeynCalc`GLI[causalFamily,{1,1,1/2}]]]];
causalShift=causalSource;causalShift["Topology"]=ReplacePart[causalSource["Topology"],{2,3}->FeynCalc`SFAD[{{I(causalKa-causalL),0},1/4}]];
FTTest`FTAssert["a shifted propagator with an interior pole is not certified",FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalShift,causalMaster]["Status"]==="NotCertified"];
causalSafeShift=causalSource;causalSafeShift["Topology"]=ReplacePart[causalSource["Topology"],{2,3}->FeynCalc`SFAD[{{causalKa-causalL,0},1/4}]];
FTTest`FTAssert["a massive shift that is strictly nonzero is proved by the same fallback",
 FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSafeShift,causalMaster]["PropagatorBoundaryCertificates"][3]["Method"]==="RealAlgebraicZeroContainment"];
causalEndpoint=causalSource;causalEndpoint["Topology"]=causalSource["Topology"]/.Rational[1,8]->1/4;
FTTest`FTAssert["zero recoil mass is excluded from a generic certificate",FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalEndpoint,causalMaster]["Status"]==="NotCertified"];
causalWrongOrientation=Append[causalSource,"CutDirections"->{1,-1}];
FTTest`FTAssert["wrong cut energy orientation violates conservation",FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalWrongOrientation,causalMaster]["Status"]==="NotCertified"];
causalDef=FeynFacet`Private`miRepDefinition[causalSource,causalMaster,causalEps];
FTTest`FTAssert["certified ordinary prescriptions may be removed",causalDef["PropagatorPrescriptions"]==={0,0,0}];
causalDottedDef=FeynFacet`Private`miRepDefinition[causalSource,FeynCalc`GLI[causalFamily,{2,1,1}],causalEps];
FTTest`FTAssert["certified dotted masters remove ordinary prescriptions",causalDottedDef["PropagatorPrescriptions"]==={0,0,0}];
FTTest`FTAssert["dotted cut derivative data are preserved",causalDottedDef["CutDistributions"][[1,"DeltaDerivativeOrder"]]===1];
FTTest`FTAssert["bulk certificate cannot authorize endpoint distributions",FailureQ[FeynFacet`RequireOrdinaryPrescriptionCertificate[causalDef,"EndpointDistributions"]]];
FTTest`FTAssert["bulk certificate authorizes generic values",TrueQ[FeynFacet`RequireOrdinaryPrescriptionCertificate[causalDef,"GenericKinematics"]]];
causalShiftDef=FeynFacet`Private`miRepDefinition[causalShift,causalMaster,causalEps];
FTTest`FTAssert["uncertified ordinary prescriptions are retained",causalShiftDef["PropagatorPrescriptions"]==={0,0,1}];
causalBaikov=Catch[FeynFacet`Private`miRepBaikov[causalShiftDef],"EpsilonOrders"];
FTTest`FTAssert["uncertified Baikov integrand retains positive eta",AssociationQ[causalBaikov]&&!FreeQ[causalBaikov["Integrand"],causalBaikov["OrdinaryPrescriptionParameter"]]];
causalBadGram=causalSource;causalBadGram["Topology"]=causalSource["Topology"]/.Rational[1,8]->0;
FTTest`FTAssert["beam-collinear fixed observed kinematics are rejected",FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalBadGram,causalMaster]["Status"]==="NotCertified"];
causalNegative=causalSource;causalNegative["Topology"]=ReplacePart[causalSource["Topology"],{2,3}->FeynCalc`SFAD[I(causalKa-causalL)]];
causalNegativeDef=FeynFacet`Private`miRepDefinition[causalNegative,causalMaster,causalEps];
FTTest`FTAssert["negative quadratic scales use a real causal routing",
 causalNegativeDef["OrdinaryPrescriptionCertificate"]["Status"]==="CertifiedGenericKinematics"];
causalPositiveAngular=FeynFacet`Private`miRepTwoBodyAngular[causalDef];
causalNegativeAngular=FeynFacet`Private`miRepTwoBodyAngular[causalNegativeDef];
FTTest`FTAssert["analytic angular evaluation retains negative inverse-polynomial scales",
 AssociationQ[causalNegativeAngular]&&FullSimplify[causalPositiveAngular["Terms"][[1,"Prefactor"]]+causalNegativeAngular["Terms"][[1,"Prefactor"]]]===0];
causalBadNumerator=<|"LoopMomenta"->{causalL},"Integrand"->1/FeynCalc`SPD[causalL,causalKa],
 "Propagators"->FeynFacet`Cut[FeynCalc`SPD[causalL]]FeynFacet`Cut[FeynCalc`SPD[causalKa+causalKb-causalPc-causalL]]FeynCalc`SFAD[causalKa-causalL]|>;
causalMinimalSetup=<|"ForwardAmplitudes"-><|"LoopMomenta"->{}|>,"ConjugateAmplitudes"-><|"LoopMomenta"->{}|>|>;
FTTest`FTAssert["a hidden loop denominator blocks whole-term certification",
 FeynFacet`Private`preIBPOrdinaryPrescription[causalMinimalSetup,causalBadNumerator]["Certificate"]["Reason"]==="PolynomialLoopNumeratorRequired"];
causalPlus=FeynCalc`SFAD[causalL];
causalMinus=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[causalL,D],0,0,{1,-1}]];
FTTest`FTAssert["opposite prescriptions cannot cancel to zero",
 !FeynFacet`Private`prescribedPartialFractionIdentityQ[causalPlus-causalMinus,0]];
FTTest`FTAssert["exact core-sign switching preserves the finite regulator",
 FeynFacet`Private`prescribedPartialFractionIdentityQ[causalPlus-causalMinus,FeynCalc`FCLoopSwitchEtaSign[causalPlus-causalMinus,1]]];
causalPartial=Quiet[CheckAbort[FeynFacet`PartialFraction[causalPlus-causalMinus,{causalL}],$Failed]];
FTTest`FTAssert["public partial fractions preserve or reject a pinched difference",
 causalPartial===$Failed||FeynFacet`Private`prescribedPartialFractionIdentityQ[causalPlus-causalMinus,causalPartial]];
FTTest`FTAssert["an unsafe algebra result is rejected by the public driver",
 Block[{FeynCalc`ApartFF=(0&)},Quiet[FeynFacet`PartialFraction[causalPlus-causalMinus,{causalL}]]]===$Failed];
FTTest`FTAssert["explicit and implicit unit cut orientations share one regulator",
 FeynFacet`Private`prescribedPartialFractionIdentityQ[FeynFacet`Cut[FeynCalc`SPD[causalL]],FeynFacet`Cut[FeynCalc`SPD[causalL],1]]];
FTTest`FTAssert["unknown requested certificate scope is rejected",FailureQ[FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSource,causalMaster,<|"PrescriptionScope"->"Misspelled"|>]]];
FTTest`FTAssert["false kinematic assumptions cannot establish a convergence domain",FeynFacet`CertifyOrdinaryPrescriptionRemoval[Append[causalSource,"KinematicConditions"->False],causalMaster]["Status"]==="NotCertified"];
causalShared=FeynFacet`Private`cutIntegralConvergenceCertificate[causalDottedDef];
causalBound=FeynFacet`DetermineIntegralLaurentBound[Join[causalDottedDef,FeynFacet`Private`miRepBaikov[causalDottedDef]]];
FTTest`FTAssert["prescription and Laurent bound consume identical convergence data",
 causalBound["ConvergenceCertificate"]===causalDottedDef["OrdinaryPrescriptionCertificate"] &&
 causalShared===First[FeynFacet`Private`cutDrrGeometry[{causalDottedDef},2]]];
FTTest`FTAssert["the shared certificate records the differentiated cut order",
 causalShared["NormalDerivativeOrder"]===1 && causalShared["NonnegativeCutMassDeformation"]===True];
causalHigher=FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSource,FeynCalc`GLI[causalFamily,{3,2,2}]];
FTTest`FTAssert["higher finite cut powers use the same certificate",
 causalHigher["Status"]==="CertifiedGenericKinematics" && causalHigher["NormalDerivativeOrder"]===3];
causalSymbolic=causalSource;
causalSymbolic["Topology"]=causalSource["Topology"]/.Rational[1,8]->causalInvariant;
causalSymbolic["KinematicConditions"]=0<causalInvariant<1/4;
FTTest`FTAssert["the shared proof accepts a symbolic physical region",
 FeynFacet`CertifyOrdinaryPrescriptionRemoval[causalSymbolic,causalMaster]["Status"]==="CertifiedGenericKinematics"];
causalConstant=Join[causalDottedDef,<|
 "InversePropagators"->Append[causalDottedDef["InversePropagators"],causalExternal],
 "PropagatorPowers"->Append[causalDottedDef["PropagatorPowers"],1],
 "PropagatorMomenta"->Append[causalDottedDef["PropagatorMomenta"],Missing["NotQuadratic"]]|>];
FTTest`FTAssert["a symbolic external denominator needs a nonzero-domain proof",
 FailureQ[Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[causalConstant],"EpsilonOrders"]]];
FTTest`FTAssert["a proved positive external denominator is allowed",
 AssociationQ[Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[
 Append[causalConstant,"KinematicConditions"->causalExternal>0]],"EpsilonOrders"]]];
(* Pro's symbolic-coordinate counterexample and independent-coordinate fallback. *)
causalFallbackSource=<|"Topology"->FeynCalc`FCTopology[causalFallbackFamily,
 {FeynCalc`SFAD[causalL],FeynCalc`SFAD[causalKa+causalKb-causalL]},
 {causalL},{causalKa,causalKb},FeynCalc`FCI[{FeynCalc`SPD[causalKa]->0,
 FeynCalc`SPD[causalKb]->0,FeynCalc`SPD[causalKa,causalKb]->1/2}],{}],
 "CutIndices"->{1,2},"Prescription"->{0}|>;
causalFallbackBase=FeynFacet`Private`miRepDefinition[causalFallbackSource,FeynCalc`GLI[causalFallbackFamily,{1,1}],causalEps];
causalU=FeynCalc`FCI[FeynCalc`SPD[causalL,causalKa]];
causalV=FeynCalc`FCI[FeynCalc`SPD[causalL,causalKb]];
causalExtend[cores_List,assum_]:=Join[causalFallbackBase,<|
 "InversePropagators"->Join[causalFallbackBase["InversePropagators"],cores],
 "PropagatorPowers"->Join[{1,1},ConstantArray[1,Length[cores]]],
 "PropagatorMomenta"->Join[causalFallbackBase["PropagatorMomenta"],ConstantArray[Missing["Bilinear"],Length[cores]]],
 "KinematicConditions"->assum|>];
causalLambda=causalExtend[{causalScale causalU},Element[causalScale,Reals]];
FTTest`FTAssert["a symbolic coordinate change cannot discard the zero-scale locus",
 FailureQ[Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[causalLambda],"EpsilonOrders"]]];
causalLambdaPositive=Append[causalLambda,"KinematicConditions"->causalScale>0];
causalLambdaGeometry=FeynFacet`Private`cutOrderGeometry[causalLambdaPositive];
FTTest`FTAssert["independent scalar-product fallback retains the zero-scale locus",
 !AssociationQ[FeynFacet`Private`cutConvergenceZeroContainment[causalLambda,causalLambdaGeometry,causalScale causalU,2]]];
FTTest`FTAssert["proved nonzero symbolic scales remain supported",
 AssociationQ[Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[causalLambdaPositive],"EpsilonOrders"]]];
causalRedundant=causalExtend[{causalU,causalV,1+causalU+causalV,2},True];
causalRedundantProof=Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[causalRedundant],"EpsilonOrders"];
FTTest`FTAssert["fallback supports redundant denominators and external constants",
 AssociationQ[causalRedundantProof] &&
 causalRedundantProof["PropagatorBoundaryCertificates"][5]["Method"]==="RealAlgebraicZeroContainment"];
FTTest`FTAssert["an interior scalar-product pole is rejected",
 FailureQ[Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[causalExtend[{causalU-1/4},True]],"EpsilonOrders"]]];
FTTest`FTAssert["complex inverse-polynomial coefficients are rejected",
 FailureQ[Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[causalExtend[{1+I(causalU+causalV)},True]],"EpsilonOrders"]]];
FTTest`FTAssert["the affine guard rejects products of independent coordinates",
 !FeynFacet`Private`cutConvergenceAffineQ[{causalCoordinateA causalCoordinateB},{causalCoordinateA,causalCoordinateB},{causalL}]];
causalMismatched=Append[causalFallbackBase,"OrientedCutMomenta"->{2causalL,causalKa+causalKb-2causalL}];
FTTest`FTAssert["cut rays must match the actual off-shell cut polynomials",
 MatchQ[Catch[FeynFacet`Private`cutIntegralConvergenceCertificate[causalMismatched],"EpsilonOrders"],
 Failure["CutMomentumDoesNotMatchPropagator",_]]];
FTTest`FTAssert["external-basis pivots cannot silently exclude symbolic zeros",
 FailureQ[Catch[FeynFacet`Private`cutConvergenceExternalBasis[{{causalScale,1}},Element[causalScale,Reals]],"EpsilonOrders"]]];
FTTest`FTReport[];
