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
 difference=If[AssociationQ[direct],restore[shared[[i]]["PreparedIntegrand"]]-restore[direct],$Failed];
 slots=definitions[[i]]["Definition"]["MeasurementCutIndices"];
 If[slots=!={}&&AssociationQ[direct],
  constraint=definitions[[i]]["Definition"]["InversePropagators"][[First[slots]]];
  constraint=(constraint/.(Reverse/@direct["ScalarProductVariables"])/.direct["UnitCutRules"])/.direct["ScalarProductVariables"];
  difference=difference/.pz->-(constraint/.pz->0)/Coefficient[constraint,pz]];
 FTTest`FTAssert["shared and direct rational densities agree for constraint "<>ToString[i],
   AssociationQ[direct]&&Cancel[Together[difference]]===0];
 FTTest`FTAssert["original off-shell propagators retain the causal proof for constraint "<>ToString[i],
  FeynFacet`RequireOrdinaryPrescriptionCertificate[shared[[i]]["PreparedIntegrand"],"GenericKinematics"]===True],
 {i,Length[definitions]}];
FTTest`FTAssert["dimensional scale powers remain coefficients of rational cancellation",
 FreeQ[Lookup[# ["UnmeasuredPreparation"]["RationalCancellation"],"Reason",None]&/@shared,
   "RationalCoefficientDependenceRequired"]];
FTTest`FTAssert["quadratic cuts reduce the degree of the measured numerator before amplitude expansion",
 AllTrue[Select[shared,#["ContactMeasurements"]==={}&],
  With[{r=Lookup[#["PreparedIntegrand"],"UnitMeasurementPolynomialReduction",<||>]},
   Lookup[r,"ReducedDegree",Infinity]<Lookup[r,"OriginalDegree",0]]&]];
phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[geometry];
cancelSource=FeynCalc`FCI[(FeynCalc`SPD[pk1+pk2]+FeynCalc`SPD[pk1])*
 FeynCalc`FAD[{pk1+pk2,0},{pq-pk1-pk3,0}]];
cancelRows=FeynFacet`PrepareFinalStateMeasurementIntegrands[cancelSource,geometry,spec];
FTTest`FTAssert["unit-cut cancellation retains the original unrestricted surviving propagator",
 ListQ[cancelRows]&&Length[cancelRows]===7&&AllTrue[cancelRows,
  With[{p=#["PreparedIntegrand"]},
   Length[p["OrdinaryInversePropagators"]]===1&&
   Expand[First[p["OrdinaryInversePropagators"]]-
    FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[pq-pk1-pk3]]]/.FeynCalc`FCI[{FeynCalc`SPD[pq]->ps}]]===0]&]];
testFunction=1+px+px^2;
FTTest`FTAssert["a cut normal derivative retains the term discarded by a unit delta",
 (-D[px testFunction,px]/.px->0)===-(testFunction/.px->0)];
dotted=Join[shared[[2]]["PreparedIntegrand"],<|"CutPowers"->
 ReplacePart[shared[[2]]["PreparedIntegrand"]["CutPowers"],1->2]|>];
FTTest`FTAssert["rational unit-cut cancellation rejects a differentiated-cut record",
 FailureQ[FeynFacet`CancelMeasuredCutIntegrandDenominators[dotted]]];
FTTest`FTAssert["unit-cut numerator decomposition rejects a differentiated-cut record",
 FailureQ[FeynFacet`DecomposeMeasuredCutIntegrand[dotted]]];
interiorPole=FeynFacet`PrepareCutIntegrand[1/(FeynCalc`SPD[pk1+pk2]-ps/8),phase,
 <|"ExternalKinematicConditions"->ps>0|>];
FTTest`FTAssert["a propagator with an interior physical zero cannot lose its causal prescription",
 FailureQ[interiorPole]];
reduction=shared[[2]]["PreparedIntegrand"]["UnitMeasurementPolynomialReduction"];
FTTest`FTAssert["denominator clearing certifies the identity in the original measurement polynomial",
 TrueQ[reduction["DenominatorClearedIdentityVerified"]]&&Expand[
  reduction["DenominatorClearingFactor"](reduction["OriginalWeightTimesJacobian"]-reduction["ReducedWeightTimesJacobian"])-
  reduction["OriginalGeneratorMultipliers"].reduction["UnitMeasurementPolynomials"]]===0&&
 MemberQ[reduction["ExceptionalDivisors"],pz]];
decomposition=FeynFacet`DecomposeMeasuredCutIntegrand[shared[[2]]["PreparedIntegrand"]];
merged=FeynFacet`MergeCutIntegralDecompositions[<|"First"->decomposition,"Second"->decomposition|>];
FTTest`FTAssert["merging retains each source's exceptional locus and its union",
 AssociationQ[merged]&&MemberQ[merged["ExceptionalDivisors"],pz]&&
 merged["SourceExceptionalDivisors"]["First"]===decomposition["ExceptionalDivisors"]];
weightDifference=pbeta^2/4-palpha^2/(4pz^2);probe=1+palpha+palpha^2;
FTTest`FTAssert["differentiating the full source identity includes both the coefficient and the cut",
 Together[(D[weightDifference,pz]probe+D[pbeta weightDifference probe,palpha])/.palpha->pz pbeta]===0];
Print["SHARED MEASUREMENT PREPARATION TEST COMPLETE"];
FTTest`FTReport[];
