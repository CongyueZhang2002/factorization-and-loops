Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
def=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->thresholdTest,
 "FinalMomenta"->{r1,r2},"TotalMomentum"->Ptot,"ExternalMomenta"->{beam,Ptot},
 "KinematicRules"->{SPD[beam]->0,SPD[Ptot]->s,SPD[beam,Ptot]->j},"Assumptions"->s>0&&2j>s|>];
prepared=FeynFacet`PrepareCutIntegrand[FCI[SFAD[beam-r1]],def,
 <|"ExternalKinematicConditions"->s>0&&2j>s,"CancelDenominators"->False|>];
data=FeynFacet`DecomposeMeasuredCutIntegrand[prepared];
If[!AssociationQ[data],Print[data];Exit[1]];
family=First[data["Families"]];master=First[data["Targets"]];
req=<|"DimensionalRegulator"->eps,"ExternalKinematicConditions"->s>0&&2j>s,
 "AngularEndpointDomain"-><|"Variable"->t,"CoordinateRules"->{s->t,j->1},"Assumptions"->True|>,
 "ScalarCoefficients"->{1/s^3}|>;
cert=FeynFacet`CertifyOrdinaryPrescriptionRemoval[family,master,req];
If[!AssociationQ[cert],Print[cert];Exit[1]];
FTTest`FTAssert["the uniform angular proof extends the existing ordinary certificate",
 FeynFacet`RequireOrdinaryPrescriptionCertificate[cert,"EndpointDistributions"]===True];
FTTest`FTAssert["the convergence half-plane includes the scalar endpoint pole loss",
 cert["EpsilonRealPartUpperBound"]===-2&&cert["JointEndpointPowerBound"]===3];
FTTest`FTAssert["cut prescriptions and dimensional endpoint distributions are retained",
 cert["CutPrescriptionsRemoved"]===False&&cert["AdditionalPrescriptionDependentEndpointAtoms"]===False&&cert["EndpointCoefficientsComputed"]===False];
bad=FeynFacet`CertifyOrdinaryPrescriptionRemoval[family,master,Join[req,<|"ScalarCoefficients"->{1/(s+eps)}|>]];
FTTest`FTAssert["mixed epsilon and endpoint poles cannot pass a pointwise valuation test",FailureQ[bad]];
over=FeynFacet`PrepareCutIntegrand[FCI[SFAD[beam-r1]SFAD[beam+r1]SFAD[beam+Ptot-r1]],def,
 <|"ExternalKinematicConditions"->s>0&&2j>s,"CancelDenominators"->False|>];
wholeRequest=Join[KeyDrop[req,"ScalarCoefficients"],<|"AngularEndpointDomain"->Join[req["AngularEndpointDomain"],
 <|"TimeDirection"->beam+Ptot,"TangentialVariables"->{}|>]|>];
whole=FeynFacet`CertifyOrdinaryPrescriptionRemoval[over,Automatic,wholeRequest];
If[!AssociationQ[whole],Print[whole]];
FTTest`FTAssert["the original overcomplete prescribed product is certified before partial fractions",
 AssociationQ[whole]&&FeynFacet`RequireOrdinaryPrescriptionCertificate[whole,"EndpointDistributions"]===True&&
 whole["PreparedSourcePolynomialDomination"]["PartialFractionsUsedForCertification"]===False];
Print["ANGULAR ENDPOINT CERTIFICATE TEST COMPLETE"];FTTest`FTReport[];
