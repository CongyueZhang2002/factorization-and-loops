Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
geometry=<|"Name"->ScalarThreeBody,"FinalMomenta"->{pk1,pk2,pk3},"TotalMomentum"->pq,
 "ExternalMomenta"->{pq},"KinematicRules"->{FeynCalc`SPD[pq]->ps},"Assumptions"->ps>0|>;
spec=<|"Arguments"->{pa,pb},"Observable"->ps FeynCalc`SPD[pa,pb]/(2FeynCalc`SPD[pq,pa]FeynCalc`SPD[pq,pb]),
 "Weight"->FeynCalc`SPD[pq,pa]FeynCalc`SPD[pq,pb]/ps^2,"Variable"->pz,
 "Tuples"-><|"Ordered"->True,"IncludeRepeated"->True|>|>;
terms=FeynFacet`FinalStateMeasurementTerms[spec,geometry["FinalMomenta"]];
definitions=Map[FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[geometry,<|
 "Measurements"->{KeyTake[#,{"Variable","Observable"}]}|>]]&,terms];
FTTest`FTAssert["a rational pair-observable compiles on the three-particle phase space",AllTrue[definitions,AssociationQ]];
If[!AllTrue[definitions,AssociationQ],Print[InputForm[definitions]];FTTest`FTReport[]];
FTTest`FTAssert["self pairs are retained as contact measurements",Count[Lookup[definitions,"MeasurementCutIndices"],{}]===3&&
 Total[Length/@Lookup[definitions,"ContactMeasurements"]]===3];
pair=definitions[[2]];weighted=terms[[2,"Weight"]];
FTTest`FTAssert["the native measurement stays quadratic before IBP",pair["DenominatorDegrees"]==={1,1,1,2}];
prep=FeynFacet`PrepareCutIntegrand[weighted,pair,<|"ExternalKinematicConditions"->ps>0|>];
FTTest`FTAssert["unit Jacobian enters the polynomial numerator exactly once",AssociationQ[prep]];
If[!AssociationQ[prep],Print[InputForm[prep]];FTTest`FTReport[]];
decomp=FeynFacet`DecomposeMeasuredCutIntegrand[prep,<|"Assumptions"->ps>0&&0<pz<1,"FamilyNamePrefix"->"ScalarEEC"|>];
FTTest`FTAssert["generic decomposition completes an affine basis without eliminating the quadratic cut",AssociationQ[decomp]];
If[!AssociationQ[decomp],Print[InputForm[decomp]];FTTest`FTReport[]];
Print["DECOMPOSITION KEYS ",Keys[decomp]];
FTTest`FTAssert["raised-cut pairing has the orientation sign and no extra delta-derivative sign",
 FeynFacet`ApplyMeasurementCutToTestFunction[FeynFacet`CutPropagator[pb pz-pa,2],pz,pz^3,pa>0&&pb>0]===3pa^2/pb^4];
born=Map[FeynFacet`CreateMasslessPhaseSpaceDefinition[Join[geometry,<|"FinalMomenta"->{pk1,pk2},
 "Measurements"->{KeyTake[#,{"Variable","Observable"}]}|>]]&,
 FeynFacet`FinalStateMeasurementTerms[spec,{pk1,pk2}]];
FTTest`FTAssert["all four Born pair terms are contacts at zero or one",AllTrue[born,AssociationQ]&&
 Lookup[born,"MeasurementCutIndices"]===ConstantArray[{},4]&&
 Sort[Flatten[Lookup[#,"Observable"]&/@Lookup[born,"ContactMeasurements"]]]==={0,0,1,1}];
Print["POLYNOMIAL PHASE SPACE TEST COMPLETE"];
FTTest`FTReport[];
