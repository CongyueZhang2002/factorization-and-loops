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

rows=FeynFacet`PrepareFinalStateMeasurementIntegrands[1,geometry,spec];
FTTest`FTAssert["ordered tuple weights combine only identical constraints",ListQ[rows]&&Length[rows]===4&&
 Total[Length/@Lookup[rows,"ParticleTuples"]]===9];
If[!ListQ[rows],Print[InputForm[rows]];FTTest`FTReport[]];
contact=SelectFirst[rows,#["ContactMeasurements"]=!={}&];
inclusive=FeynFacet`IntegrateMasslessInvariantMoments[contact["PreparedIntegrand"],pe];
FTTest`FTAssert["self pairs integrate to the exact three-body Dirichlet moment",AssociationQ[inclusive]&&
 FullSimplify[inclusive["Value"]/(FeynFacet`MasslessPhaseSpaceVolume[3,ps,pe])-(3-2pe)/(2(4-3pe)),ps>0&&pe<0]===0];
If[!AssociationQ[inclusive],Print[InputForm[inclusive]]];
bulk=SelectFirst[rows,#["ContactMeasurements"]==={}&];
direct=FeynFacet`EvaluateThreeParticleMeasurementInterior[bulk["PreparedIntegrand"],<|"Parameters"->{px,py},"Assumptions"->ps>0&&0<pz<1|>];
FTTest`FTAssert["the actual quadratic cut has an explicit direct interior integral",AssociationQ[direct]];
If[!AssociationQ[direct],Print[InputForm[direct]];FTTest`FTReport[]];
reference=ps/(256Pi^3)Beta[3,3]Hypergeometric2F1[3,3,6,pz];
FTTest`FTAssert["direct root integration agrees with independent all-epsilon scalar EEC at epsilon zero",
 FullSimplify[direct["Value"]-FunctionExpand[reference],0<pz<1&&ps>0]===0];
FTTest`FTAssert["the direct result explicitly excludes endpoint completion",direct["EndpointDistributionIncluded"]===False];
exact=FeynFacet`EvaluateThreeParticleMeasurementInterior[bulk["PreparedIntegrand"],<|"Parameters"->{px,py},
 "DimensionalRegulator"->pe,"Assumptions"->ps>0&&0<pz<1|>];
FTTest`FTAssert["the native cut also evaluates exactly in the dimensional regulator",AssociationQ[exact]];
If[!AssociationQ[exact],Print[InputForm[exact]];FTTest`FTReport[]];
allEpsilon=ps^(1-2pe)(4Pi)^(2pe)/(256Pi^3 Gamma[2-2pe])*
 (pz(1-pz))^-pe Beta[3-2pe,3-2pe]Hypergeometric2F1[3-2pe,3-2pe,6-4pe,pz];
FTTest`FTAssert["Euler factorization preserves the independent all-epsilon physical normalization",
 FullSimplify[exact["Value"]/allEpsilon,ps>0&&0<pz<1&&Element[pe,Reals]]===1];
Print["INVARIANT POLYNOMIAL TEST COMPLETE"];
FTTest`FTReport[];
