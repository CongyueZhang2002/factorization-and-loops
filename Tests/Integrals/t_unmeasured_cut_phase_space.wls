Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
request=<|"Name"->unmeasuredSource,"FinalMomenta"->{r1,r2},"TotalMomentum"->Ptot,
 "ExternalMomenta"->{beam,Ptot},"KinematicRules"->{SPD[beam]->0,SPD[Ptot]->s,SPD[beam,Ptot]->j},
 "Assumptions"->s>0&&2j>s|>;
def=FeynFacet`CreateMasslessPhaseSpaceDefinition[request];
FTTest`FTAssert["fixed external recoil has two particle cuts and no invented measurement cut",
 AssociationQ[def]&&def["ParticleCutIndices"]==={1,2}&&def["MeasurementCutIndices"]==={}];
FTTest`FTAssert["unmeasured Lorentz-invariant phase space retains its exact normalization",
 AssociationQ[def]&&def["MeasurePrefactor"]===(2Pi)^(2-D)&&def["MomentumConservationRules"]==={r2->Ptot-r1}];
prepared=FeynFacet`PrepareCutIntegrand[FCI[SFAD[beam-r1]],def,
 <|"ExternalKinematicConditions"->s>0&&2j>s,"CancelDenominators"->False|>];
If[!AssociationQ[prepared],Print[prepared]];
FTTest`FTAssert["unmeasured ordinary product receives the shared prescription certificate",
 AssociationQ[prepared]&&FeynFacet`RequireOrdinaryPrescriptionCertificate[prepared["OrdinaryPrescriptionCertificate"],"GenericKinematics"]===True];
volume=FeynFacet`PrepareCutIntegrand[1,def,
 <|"ExternalKinematicConditions"->s>0&&2j>s,"CancelDenominators"->False|>];
FTTest`FTAssert["pure phase volume does not need a fictitious prescription-removal proof",AssociationQ[volume]];
measured=FeynFacet`CreateMeasuredPhaseSpaceDefinition[Join[request,<|
 "ReferenceMomentum"->beam,"TaggedMomentum"->r1,"MeasurementVariable"->z,
 "Assumptions"->s>0&&2j>s&&0<z<1|>]];
FTTest`FTAssert["the existing measured geometry still includes exactly one delta and Jacobian",
 AssociationQ[measured]&&measured["MeasurementCutIndices"]==={3}&&
 measured["MeasurementJacobian"]===2j&&measured["MeasurePrefactor"]===2j(2Pi)^(2-D)];
shifted=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->spacelikeShiftSource,
 "FinalMomenta"->{r1,r2},"TotalMomentum"->Ptot,"TimeDirection"->q+Ptot,"ExternalMomenta"->{q,Ptot},
 "KinematicRules"->{SPD[q]->-3,SPD[Ptot]->4,SPD[q,Ptot]->2},"Assumptions"->True|>];
shiftedPrepared=FeynFacet`PrepareCutIntegrand[FCI[SFAD[q-r1]],shifted,
 <|"ExternalKinematicConditions"->True,"CancelDenominators"->False|>];
FTTest`FTAssert["two spacelike endpoints give a nonvanishing propagator throughout the future causal interval",
 AssociationQ[shiftedPrepared]&&!FreeQ[shiftedPrepared,"SpacelikeShiftOfForwardCutSubset"]];
decomposed=FeynFacet`DecomposeMeasuredCutIntegrand[shiftedPrepared];
If[!AssociationQ[decomposed],Print[decomposed];Exit[1]];
family=First[decomposed["Families"]];target=First[decomposed["Targets"]];
angular=FeynFacet`ConstructTwoBodyAngularGeometry[family,eps];
FTTest`FTAssert["typed scalar denominator gives the independently known rest-frame scale and velocity",
 AssociationQ[angular]&&angular["DenominatorScales"]==={-5}&&angular["BetaGram"]==={{16/25}}];
integrated=FeynFacet`EvaluateTwoBodyCutIntegral[angular,target];
If[!AssociationQ[integrated],Print[integrated];Exit[1]];
expanded=FeynFacet`ExpandTwoBodyAngularSeeds[integrated,0];
FTTest`FTAssert["massive scalar cut integral includes the exact standard phase volume",
 FullSimplify[(integrated["PhysicalPrefactor"]/.eps->0)expanded["Coefficients"][0]+Log[9]/(64Pi)]===0];
FTTest`FTAssert["bulk integration preserves the distinction from endpoint certification",
 integrated["OrdinaryPrescriptionRemoved"]===True&&integrated["EndpointExpansionIncluded"]===False];

(* A summed physical time direction changes term order under dummy-momentum
   renaming; persisted catalog keys must still identify the same integral. *)
angular["Family"]=Join[angular["Family"],<|"TimeDirection"->q+Ptot|>];
libraryDirectory=CreateDirectory[];
libraryRequest=<|"Mode"->"ReadWrite","LibraryDirectory"->libraryDirectory|>;
seedDensity=<|"Format"->"FeynFacet-TwoBodyAngularDensity","DimensionalRegulator"->eps,
 "FamilyGeometries"-><|target[[1]]->angular|>,"IntegralEvaluations"-><|target->integrated|>|>;
publication=FeynFacet`PublishTwoBodyAngularSeeds[seedDensity,libraryRequest];
FTTest`FTAssert["the physical angular volume and massive seed are automatically published",
 AssociationQ[publication]&&publication["SeedCount"]===2&&publication["StoredCount"]===2];
republication=FeynFacet`PublishTwoBodyAngularSeeds[seedDensity,libraryRequest];
FTTest`FTAssert["republication finds both explicit seeds without duplicate storage",
 AssociationQ[republication]&&republication["StoredCount"]===0&&republication["ReusedCount"]===2];
DeleteDirectory[libraryDirectory,DeleteContents->True];
Print["UNMEASURED CUT PHASE SPACE TEST COMPLETE"];FTTest`FTReport[];
