Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Name"->ScalarFourBody,"FinalMomenta"->{pk1,pk2,pk3,pk4},"TotalMomentum"->pq,
 "ExternalMomenta"->{pq},"KinematicRules"->{FeynCalc`SPD[pq]->ps},"Assumptions"->ps>0|>;
spec=<|"Arguments"->{pa,pb},"Observable"->ps FeynCalc`SPD[pa,pb]/(2FeynCalc`SPD[pq,pa]FeynCalc`SPD[pq,pb]),
 "Weight"->FeynCalc`SPD[pq,pa]FeynCalc`SPD[pq,pb]/ps^2,"Variable"->pz,
 "Tuples"-><|"Ordered"->True,"IncludeRepeated"->True|>|>;
expression=Exp[EulerGamma pe]pmu^pe FeynCalc`FCI[FeynCalc`FAD[{pk2+pk4,0}]FeynCalc`SPD[pk1,pk3]];
shared=FeynFacet`PrepareFinalStateMeasurementIntegrands[expression,geometry,spec];
FTTest`FTAssert["one common scalar preparation supplies seven four-body constraints",ListQ[shared]&&Length[shared]===7];
If[!ListQ[shared],Print[InputForm[shared]];FTTest`FTReport[]];
definitions=FeynFacet`CreateFinalStateMeasurementDefinitions[geometry,spec];
restore[prepared_]:=Total[Map[#["Numerator"]Times@@MapThread[Power,
 {prepared["OrdinaryUnitCutPolynomials"],-#["Powers"]}]&,prepared["Terms"]]]/.prepared["ScalarProductVariables"];
Do[
 direct=FeynFacet`PrepareCutIntegrand[expression definitions[[i]]["Weight"],definitions[[i]]["Definition"],
   <|"ExternalKinematicConditions"->ps>0|>];
 FTTest`FTAssert["shared and direct rational densities agree for constraint "<>ToString[i],
   AssociationQ[direct]&&Cancel[Together[restore[shared[[i]]["PreparedIntegrand"]]-restore[direct]]]===0];
 FTTest`FTAssert["original off-shell propagators retain the causal proof for constraint "<>ToString[i],
  FeynFacet`RequireOrdinaryPrescriptionCertificate[shared[[i]]["PreparedIntegrand"],"GenericKinematics"]===True],
 {i,Length[definitions]}];
FTTest`FTAssert["dimensional scale powers remain coefficients of rational cancellation",
 FreeQ[Lookup[# ["PreparedIntegrand"]["RationalCancellation"],"Reason",None]&/@shared,
   "RationalCoefficientDependenceRequired"]];
Print["SHARED MEASUREMENT PREPARATION TEST COMPLETE"];
FTTest`FTReport[];
