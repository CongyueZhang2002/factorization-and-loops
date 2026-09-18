Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->ScaleTest,
 "FinalMomenta"->{sk1,sk2},"TotalMomentum"->sq,"ExternalMomenta"->{sq},
 "KinematicRules"->{FeynCalc`SPD[sq]->ss},"Assumptions"->ss>0|>];
family=FeynFacet`CreateCutIntegralFamily[definition];name=family["Topology"][[1]];
targets=FeynCalc`GLI[name,#]&/@{{1,1},{2,1},{1,2}};
directory=CreateDirectory[];
request=<|"SeedPolicy"->"TargetDownsets","Threads"->1,"PreferredMasterIntegrals"->{First[targets]}|>;
original=FeynFacet`KiraReduction[{family},targets,Join[request,<|"WorkingDirectory"->directory<>"/Original"|>]];
scaled=FeynFacet`KiraReduction[{family},targets,Join[request,<|"WorkingDirectory"->directory<>"/Scaled","HomogeneousScale"->ss|>]];
FTTest`FTAssert["homogeneous IBP scaling restores the exact physical-scale reduction",
 AssociationQ[original]&&AssociationQ[scaled]&&original["Masters"]===scaled["Masters"]&&
 AllTrue[Factor/@((targets/.original["Rules"])-(targets/.scaled["Rules"])),#===0&]];
ids=FeynFacet`FamilyArtifactRead[directory<>"/Scaled/IntegralIdentifiers.wxf"];
FTTest`FTAssert["the rational solver no longer treats the verified scale as an independent variable",
 AssociationQ[ids]&&FreeQ[ids["CoefficientVariables"],ss]&&
 TrueQ[scaled["EquationScaleNormalization"]["ExactChangeOfUnknownsEstablished"]]];
reused=FeynFacet`KiraReduction[{family},targets,Join[request,<|"WorkingDirectory"->directory<>"/Scaled","HomogeneousScale"->ss|>]];
FTTest`FTAssert["cached scaled reductions retain restored units exactly once",
 AssociationQ[reused]&&TrueQ[reused["ReusedSolvedReduction"]]&&reused["Rules"]===scaled["Rules"]];
prop[m_]:=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[m,D],0,0,{1,1}]];
polynomial=FeynCalc`FeynAmpDenominator[FeynCalc`GenericPropagatorDenominator[
 FeynCalc`FCI[sz FeynCalc`SPD[sk,sq]^2-ss^2],{1,1}]];
quadratic=FeynFacet`CreateCutIntegralFamily[<|"Topology"->FeynCalc`FCTopology[QuadraticScale,
 {prop[sk],prop[sq-sk],polynomial,prop[sk+3sq]},{sk},{sq},FeynCalc`FCI[{FeynCalc`SPD[sq]->ss}],{}],
 "Cuts"->{<|"Index"->1,"Type"->"Particle","Momentum"->sk,"EnergyDirection"->1|>,
 <|"Index"->2,"Type"->"Particle","Momentum"->sq-sk,"EnergyDirection"->1|>,
 <|"Index"->3,"Type"->"Measurement"|>},"MeasurePrefactor"->1,"TimeDirection"->sq,"Assumptions"->ss>0|>];
qt={FeynCalc`GLI[QuadraticScale,{1,1,1,1}]};
qr=FeynFacet`GenerateCutIBPEquations[quadratic,qt];
qn=FeynFacet`Private`cutKiraNormalizeScale[{quadratic},qr["Rows"],qt,ss];
FTTest`FTAssert["quadratic measurement denominators receive their actual mass-squared degree",
 AssociationQ[qn]&&qn["PropagatorScaleWeights"][QuadraticScale]==={1,1,2,1}];
FTTest`FTAssert["each normalized polynomial-cut equation reconstructs its original row exactly",
 AssociationQ[qn]&&MapThread[Function[{old,new,power},
  AllTrue[Keys[old],Factor[old[#]-Lookup[new,#,0]ss^(power-qn["IntegralWeights"][#])]===0&]],
 {qr["Rows"],qn["Rows"],qn["OriginalRowScaleDegrees"]}]===ConstantArray[True,Length[qr["Rows"]]]];
reconstructed=FeynFacet`KiraReduction[{family},targets,Join[request,<|"WorkingDirectory"->directory<>"/Reconstructed",
 "HomogeneousScale"->ss,"RationalSolver"->"FireFly"|>]];
FTTest`FTAssert["finite-field reconstruction agrees with direct rational reduction",
 AssociationQ[reconstructed]&&reconstructed["RationalSolver"]==="FireFly"&&
 AllTrue[Factor/@((targets/.original["Rules"])-(targets/.reconstructed["Rules"])),#===0&]];
If[StringStartsQ[ExpandFileName[directory],ExpandFileName[$TemporaryDirectory]<>"/"],DeleteDirectory[directory,DeleteContents->True]];
Print["CUT IBP SCALE TEST COMPLETE"];
FTTest`FTReport[];
