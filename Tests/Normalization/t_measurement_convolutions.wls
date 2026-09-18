Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
kernel=Values[FeynFacet`DISCurrentProjectors[p,q,{mu,nu}]["CoefficientProjectors"]]/(4Pi);
definition=<|"Kernel"->kernel,"Measurement"->FeynCalc`SPD[p,k]/FeynCalc`SPD[p,q],
 "IncomingMomenta"->{p},"TaggedMomentum"->k,"Dimension"->D,"TaggedDimension"->D|>;
check=FeynFacet`VerifyCollinearMeasurementCovariance[definition];
FTTest`FTAssert["all exact-dimensional DIS tensor projections have Mellin closure",AssociationQ[check]];
FTTest`FTAssert["physical tagged measure is rejected with dimensional FF operator",FailureQ[
 FeynFacet`VerifyCollinearMeasurementCovariance[Join[definition,<|"TaggedDimension"->4|>]]]];
FTTest`FTAssert["extra tagged energy weight is not silently treated as Mellin",FailureQ[
 FeynFacet`VerifyCollinearMeasurementCovariance[Join[definition,<|"Kernel"->kernel FeynCalc`SPD[q,k]/FeynCalc`SPD[q]|>]]]];
FTTest`FTAssert["fixed acceptance cut requires a larger observable space",FailureQ[
 FeynFacet`VerifyCollinearMeasurementCovariance[Join[definition,<|"Kernel"->kernel UnitStep[FeynCalc`SPD[q,k]-cut]|>]]]];
FTTest`FTAssert["derived variables are substituted before testing covariance",FailureQ[
 FeynFacet`VerifyCollinearMeasurementCovariance[Join[definition,<|"Kernel"->z kernel,
  "CoordinateDefinitions"->{z->FeynCalc`SPD[p,k]/FeynCalc`SPD[p,q]}|>]]]];
Do[card=FeynFacet`ReadContributionCard[root<>"/Projects/"<>name<>"/Raw/LO/q-q","Born"];
 request=FeynFacet`ProjectAssemblyRequest[card];
 FTTest`FTAssert[name<>" production assembly derives its closure",AssociationQ[request]&&AssociationQ[request["CollinearMeasurementDerivation"]]],
 {name,{"SIDIS_UU","SIDIS_LL"}}];
bad=Join[card,<|"ObservedMomentumSpace"->"Physical4"|>];
FTTest`FTAssert["production refuses a physical-only hard tensor for dimensional tagged integration",FailureQ[FeynFacet`ProjectAssemblyRequest[bad]]];
op=FeynFacet`BareCollinearOperatorNormalization["PDF","g",x,4-2e];
m=op["TransverseTraceDimension"];
FTTest`FTAssert["gluon scalar extraction inverts field-strength reconstruction",
 Cancel[op["FieldStrengthExtractionTimesLongitudinalScale"]op["FieldStrengthReconstructionOverLongitudinalScale"]op["HardTransverseMetricCoefficient"]m]===1];
FTTest`FTAssert["both field derivatives supply the required squared fraction",
 Cancel[op["FieldStrengthReconstructionOverLongitudinalScale"]/op["FieldStrengthPairMomentumFactorOverScaleSquared"]-op["InsertionCoefficientTimesLongitudinalScale"]]===0];
FTTest`FTAssert["free-gluon extraction and sewing have no extra state average",
 (op["PairingWeight"]/.x->1)===1&&Cancel[op["GaugeFieldExtractionOverLongitudinalScale"]op["InsertionCoefficientTimesLongitudinalScale"]op["HardTransverseMetricCoefficient"]m]===1];
FTTest`FTAssert["nontrivial gluon fraction tests distinguish the power of x",
 Integrate[x^2 x^3 op["PairingWeight"],{x,0,1}]===1/5];
Print["MEASUREMENT CONVOLUTIONS COMPLETED"];FTTest`FTReport[];
