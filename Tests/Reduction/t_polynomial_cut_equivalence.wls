Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Name"->EquivalenceFourBody,"FinalMomenta"->{pk1,pk2,pk3,pk4},"TotalMomentum"->pq,
 "ExternalMomenta"->{pq},"KinematicRules"->{FeynCalc`SPD[pq]->ps},"Assumptions"->ps>0|>;
spec=<|"Arguments"->{pa,pb},"Observable"->ps FeynCalc`SPD[pa,pb]/(2FeynCalc`SPD[pq,pa]FeynCalc`SPD[pq,pb]),
 "Weight"->1,"Variable"->pz,"Tuples"-><|"Ordered"->True,"IncludeRepeated"->False|>|>;
prepared=FeynFacet`PrepareFinalStateMeasurementIntegrands[FeynCalc`FCI[FeynCalc`FAD[{pk1+pk3,0}]],geometry,spec];
data=FeynFacet`DecomposeMeasuredCutIntegrand[First[prepared]["PreparedIntegrand"]];
If[!AssociationQ[data],Print[InputForm[data]];Exit[1]];
original=First[data["Families"]];firstName=original["Topology"][[1]];
integral=SelectFirst[data["Targets"],#[[1]]===firstName&];
permuted=original/.{pk2->pk3,pk3->pk2};
permuted=FeynFacet`CreateCutIntegralFamily[Join[permuted,<|"Topology"->ReplacePart[permuted["Topology"],
 {1->EquivalentPolynomialFamily,3->original["Topology"][[3]]}]|>]];
other=FeynCalc`GLI[EquivalentPolynomialFamily,integral[[2]]];
matched=FeynFacet`FindCutIntegralEquivalences[{integral,other},{original,permuted},"Normalization"->"TypedPhysicalMeasures"];
FTTest`FTAssert["a polynomial measurement maps exactly under a final-state momentum permutation",
 AssociationQ[matched]&&matched["EquivalenceClassCount"]===1];
If[!AssociationQ[matched],Print[InputForm[matched]]];
different=FeynFacet`CreateCutIntegralFamily[permuted/.{pz->pzOther,EquivalentPolynomialFamily->DifferentMeasurementFamily}];
separate=FeynFacet`FindCutIntegralEquivalences[{integral,FeynCalc`GLI[DifferentMeasurementFamily,integral[[2]]]},{original,different},
 "Normalization"->"TypedPhysicalMeasures"];
FTTest`FTAssert["a different measured variable is not identified by propagator support alone",
 AssociationQ[separate]&&separate["EquivalenceClassCount"]===2];
dotted=ReplacePart[other,{2,First[permuted["MeasurementCutIndices"]]}->2];
separate=FeynFacet`FindCutIntegralEquivalences[{integral,dotted},{original,permuted},"Normalization"->"TypedPhysicalMeasures"];
FTTest`FTAssert["measurement derivatives retain their actual cut powers during matching",
 AssociationQ[separate]&&separate["EquivalenceClassCount"]===2];
combined=<|"Format"->"FeynFacet-CombinedCutIntegralDecompositions",
 "Families"->{original,permuted},"Targets"->{integral,other},
 "Coefficients"-><|"Scalar"-><|integral->pc,other->pd-pc|>|>,"ExceptionalDivisors"->{pz}|>;
reduced=FeynFacet`ReduceEquivalentCutIntegralTargets[combined];
FTTest`FTAssert["equivalent integral coefficients combine before IBP without losing exceptional points",
 AssociationQ[reduced]&&Length[reduced["Targets"]]===1&&Length[reduced["Families"]]===1&&
 Total[Values[reduced["Coefficients"]["Scalar"]]]===pd&&reduced["ExceptionalDivisors"]==={pz}];
FTTest`FTAssert["the family numerator mapper verifies a nontrivial particle-cut frame permutation",
 AnyTrue[reduced["FamilyMaps"]["Mappings"],
  TrueQ[#["OffShellPropagatorsAndDirectedCutsVerified"]]&&
   AnyTrue[#["LoopMomentumRules"],Expand[First[#]-Last[#]]=!=0&]&]];
grouped=FeynFacet`ReduceEquivalentCutIntegralTargets[Join[combined,<|"Coefficients"->
 <|"First"-><|integral->pc|>,"Second"-><|other->pd-pc|>|>|>],
 <|"CoefficientGroups"-><|"First"->"Scalar","Second"->"Scalar"|>|>];
FTTest`FTAssert["declared scalar structures combine the equivalent terms before reduction",
 AssociationQ[grouped]&&Keys[grouped["Coefficients"]]==={"Scalar"}&&
 Total[Values[grouped["Coefficients"]["Scalar"]]]===pd];
Print["POLYNOMIAL CUT EQUIVALENCE TEST COMPLETE"];
FTTest`FTReport[];
