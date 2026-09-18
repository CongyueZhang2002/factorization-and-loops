Print["FEYNFACET DRIVER ENTERED"];
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
mpMaster=FeynCalc`GLI[MeasuredThreeParticle,{2,1,1,3,2,0,0}];
mpCertificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpPrescribed,mpMaster,mpRequest];
If[!AssociationQ[mpCertificate],Print[mpCertificate]];
FTTest`FTAssert["the same compact-cut certificate covers measured distributions with repeated cuts",
 AssociationQ[mpCertificate]&&mpCertificate["Status"]==="CertifiedGenericKinematics"&&
 mpCertificate["OrdinaryPrescriptionRemoved"]===True];
If[AssociationQ[mpCertificate],
 FTTest`FTAssert["particle mass derivatives and measurement derivatives remain distinct",
  mpCertificate["ParticleCutDerivativeOrders"]==={1,0,0}&&
  mpCertificate["MeasurementTestFunctionDerivativeOrder"]===2&&
  Factor[mpCertificate["MeasurementTestFunctionCoefficient"]-mpX^2/(2mpQ^2)]===0];
 FTTest`FTAssert["the SIDIS subset lemma supplies a Gram-boundary witness inside the existing proof",
  MemberQ[Lookup[Values[mpCertificate["PropagatorBoundaryCertificates"]],"Method"],"NullReferenceMinusFutureSubset"]];
 FTTest`FTAssert["fixed-x distributional equality makes no pointwise or external-endpoint claim",
  mpCertificate["PointwiseRegulatedConvergenceEstablished"]===False&&
  mpCertificate["ExternalEndpointUniformityEstablished"]===False&&
  FailureQ[FeynFacet`RequireOrdinaryPrescriptionCertificate[mpCertificate,"EndpointDistributions"]]]];
mpBadTop=ReplacePart[mpPrescribedTop,{2,5}->FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[mpP-mpK2,D],0,mpZ mpQ,{1,1}]]];
mpBad=FeynFacet`CreateCutIntegralFamily[Join[mpFamily,<|"Topology"->mpBadTop|>]];
FTTest`FTAssert["explicit z-dependent ordinary denominators need the full product-derivative proof",
 FailureQ[FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpBad,mpMaster,mpRequest]]];
mpAction[n_,phi_]:=FeynFacet`ApplyMeasurementCutToTestFunction[
 FeynFacet`CutPropagator[mpJ(mpF-mpZ),n],mpZ,mpJ phi,mpJ>0&&Element[mpF,Reals]];
FTTest`FTAssert["raised measurement cuts have the exact signed action on endpoint-sensitive test functions",
 mpAction[2,1]===0&&mpAction[2,mpZ]===-1/mpJ&&mpAction[3,mpZ^2]===1/mpJ^2];
FTTest`FTAssert["measurement differentiation acts on the entire explicit-z multiplier",
 Factor[mpAction[2,(1+mpZ)mpPhi[mpZ]]+
  (mpPhi[mpF]+(1+mpF)mpPhi'[mpF])/mpJ]===0];
mpMassive=FeynFacet`ConstructTwoParticleMeasurement[<|
 "ReferenceMomentum"->mpP,"TotalMomentum"->mpTotal,"FinalMomenta"->{mpK1,mpK2},
 "InvariantMassSquared"->mpS,"ReferenceProjection"->mpS/2,"MassesSquared"->{0,mpMass},
 "MeasurementVariable"->mpAngular,"EvanescentSquare"->mpHat,"DimensionalRegulator"->mpE,
 "Assumptions"->mpS>mpMass>0&&0<mpAngular<1|>];
mpWeighted=FeynFacet`IntegrateTwoParticleMeasurement[2FeynCalc`SPD[mpP,mpK1]/mpS,mpMassive];
FTTest`FTAssert["the deformed integral retains the nonconstant measurement insertion",
 AssociationQ[mpWeighted]&&FullSimplify[mpWeighted["Value"]-
  mpMassive["IntegratedPhaseSpace"]*(1-mpMass/mpS)/2,mpS>mpMass>0]===0];
FTTest`FTAssert["a particle-mass derivative acts on the smooth insertion as well as the volume",
 FullSimplify[D[mpWeighted["Value"],mpMass]-
  (1-mpMass/mpS)D[mpMassive["IntegratedPhaseSpace"],mpMass]/2+
  mpMassive["IntegratedPhaseSpace"]/(2mpS),mpS>mpMass>0]===0];
mpRawTop=ReplacePart[mpPrescribedTop,2->Append[mpPrescribedTop[[2]],FeynCalc`FCI[FeynCalc`SFAD[mpK1+mpK2]]]];
mpRaw=FeynFacet`CreateCutIntegralDefinition[Join[mpPrescribed,<|"Topology"->mpRawTop|>]];
mpRawMaster=FeynCalc`GLI[MeasuredThreeParticle,Append[mpMaster[[2]],1]];
mpRawCertificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpRaw,mpRawMaster,mpRequest];
FTTest`FTAssert["raw products can be certified before linearly dependent denominators are partial-fractioned",
 AssociationQ[mpRaw]&&AssociationQ[mpRawCertificate]&&mpRawCertificate["OrdinaryPrescriptionRemoved"]===True&&
 AssociationQ[FeynFacet`CreateCutIntegralFamily[mpRaw]]&&
 Length[FeynFacet`CreateCutIntegralFamily[mpRaw]["DependentDenominatorRelations"]]===1];
mpReferenceProp=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
 0,FeynCalc`FCI[FeynCalc`SPD[mpP+mpR,mpK2]],0,{1,1}]];
mpReferenceTop=ReplacePart[mpRawTop,2->Append[mpRawTop[[2]],mpReferenceProp]];
mpReference=FeynFacet`CreateCutIntegralDefinition[Join[mpRaw,<|"Topology"->mpReferenceTop|>]];
mpReferenceCertificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[mpReference,
 FeynCalc`GLI[MeasuredThreeParticle,Append[mpRawMaster[[2]],2]],mpRequest];
FTTest`FTAssert["a timelike polarization reference uses the same future-causal Gram-boundary proof",
 AssociationQ[mpReferenceCertificate]&&mpReferenceCertificate["OrdinaryPrescriptionRemoved"]===True];
FTTest`FTAssert["a complex measurement root is rejected",
 FailureQ[FeynFacet`ApplyMeasurementCutToTestFunction[
  FeynFacet`CutPropagator[mpJ(I-mpZ),1],mpZ,1,mpJ>0]]];
Print["AFFINE REGRESSION COMPLETE"];FTTest`FTReport[];
