(* Generated electromagnetic vertices, dimension continuation and absolute normalization. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
gcSetup=<|"Model"->"SMQCD","InsertionLevel"->{FeynArts`Classes},
 "ExcludeTopologies"->{FeynArts`Tadpoles,FeynArts`WFCorrections},
 "ExcludeParticles"->{FeynArts`S[_],FeynArts`V[2],FeynArts`V[3]},
 "Partons"->({FeynArts`F[3,{1}],FeynArts`V[1]}->{FeynArts`F[3,{1}]}),
 "PartonMomentum"->({gcp,gcq}->{gck}),"MasslessMomenta"->{gcp,gck},
 "Currents"->{<|"Momentum"->gcq,"Indices"-><|"Amplitude"->gcn,"Conjugate"->gcm|>,
  "Coupling"->FeynCalc`SMP["e"]|>},
 "ForwardAmplitudes"-><|"LoopOrder"->0,"LoopMomenta"->{},"DiagramIndices"->{1}|>,
 "ConjugateAmplitudes"-><|"LoopOrder"->0,"LoopMomenta"->{},"DiagramIndices"->{1}|>|>;
gcGenerated=FeynFacet`GenerateCurrentAmplitudes[gcSetup];
FTTest`FTAssert["a current is generated with D-dimensional open indices and no photon wavefunction",
 AssociationQ[gcGenerated]&&FreeQ[gcGenerated["Amplitudes"],_FeynCalc`Polarization|FeynCalc`SMP["e"]]&&
 !FreeQ[gcGenerated["Amplitudes"],FeynCalc`LorentzIndex[gcn,D]]];
gcRules=FeynCalc`FCI[{FeynCalc`SPD[gcp]->0,FeynCalc`SP[gcp]->0,
 FeynCalc`SPD[gcq]->-gcQ2,FeynCalc`SP[gcq]->-gcQ2,
 FeynCalc`SPD[gcp,gcq]->gcQ2/2,FeynCalc`SP[gcp,gcq]->gcQ2/2}];
gcContract[expr_]:=Simplify[FeynCalc`ExpandScalarProduct[FeynCalc`Contract[FeynCalc`FCI[expr]/.{
 FeynCalc`Momentum[gcp,D]->FeynCalc`Momentum[gcp],FeynCalc`Momentum[gcq,D]->FeynCalc`Momentum[gcq]}]]/.gcRules,gcQ2>0&&D>2];
gcProjectors=FeynFacet`DISCurrentProjectors[gcp,gcq,{gcm,gcn}]["CoefficientProjectors"];
gcLegs[species_,spin_]:={<|"Role"->"PDF","Species"->species,"Polarization"->spin,"Momentum"->gcp,"MomentumSpace"->"Physical4"|>,
 <|"Role"->"FF","Species"->species,"Polarization"->"U","Momentum"->gck,"MomentumSpace"->"IntegratedD"|>};
gcTensor[data_,species_,spin_]:=Module[{amps=data["Amplitudes"],result},
 result=FeynFacet`ContractPartonicSpinDensities[amps["Amplitude"][1]*
  FeynFacet`Private`conjugatePhysicalAmplitude[amps["Conjugate"][1],data["Setup"]],
  gcLegs[species,spin],<|"PhysicalMomenta"->{gcq},"MasslessMomenta"->{gcp,gck}|>];
 FeynCalc`ExpandScalarProduct[result/.gck->gcp+gcq]];
gcU=gcTensor[gcGenerated,{"q","u"},"U"];gcL=gcTensor[gcGenerated,{"q","u"},"L"];
FTTest`FTAssert["generated up-quark Born retains its charge, color average and exact-D C_T",
 gcContract[gcU gcProjectors["2F1"]/(2gcQ2)]===4/9];
FTTest`FTAssert["generated vector Born has vanishing longitudinal structure function",
 gcContract[gcU gcProjectors["FL/x"]/(2gcQ2)]===0];
FTTest`FTAssert["generated single-helicity Born has the absolute positive g1 sign",
 gcContract[gcL gcProjectors["2g1"]/(2gcQ2)]===4/9];
FTTest`FTAssert["the generated current satisfies the off-shell Ward identity",
 gcContract[gcU FeynCalc`FVD[gcq,gcm]]===0];
gcAntiSetup=Join[gcSetup,<|"Partons"->({-FeynArts`F[3,{1}],FeynArts`V[1]}->{-FeynArts`F[3,{1}]})|>];
gcAnti=FeynFacet`GenerateCurrentAmplitudes[gcAntiSetup];
gcAntiL=gcTensor[gcAnti,{"qbar","u"},"L"];
FTTest`FTAssert["generated antiquark reversal and antiquark density give the same g1 sign",
 gcContract[gcAntiL gcProjectors["2g1"]/(2gcQ2)]===4/9];
gcDownSetup=Join[gcSetup,<|"Partons"->({FeynArts`F[4,{1}],FeynArts`V[1]}->{FeynArts`F[4,{1}]})|>];
gcDown=FeynFacet`GenerateCurrentAmplitudes[gcDownSetup];
gcDownU=gcTensor[gcDown,{"q","d"},"U"];
FTTest`FTAssert["flavor charges come from the generated electromagnetic vertex",
 gcContract[gcDownU gcProjectors["2F1"]/(2gcQ2)]===1/9];
gcBad=Join[gcSetup,<|"Currents"->{Join[First[gcSetup["Currents"]],<|"Indices"-><|"Amplitude"->gcm,"Conjugate"->gcm|>|>]}|>];
FTTest`FTAssert["colliding current indices fail before contraction",
 Quiet[FeynFacet`GenerateCurrentAmplitudes[gcBad]]===$Failed];
gcCharm=FeynFacet`GenerateCurrentAmplitudes[gcSetup/.FeynArts`F[3,{1}]->FeynArts`F[3,{2}]];
FTTest`FTAssert["declared external charm masslessness is applied without flavor-specific edits",
 AssociationQ[gcCharm]&&FreeQ[gcCharm["Amplitudes"],FeynCalc`SMP["m_c"]]&&
 gcCharm["Amplitudes"]===gcGenerated["Amplitudes"]];
gcMassRules=FeynFacet`Private`modelMasslessQuarkMassRules[<|"Model"->"SMQCD",
 "MasslessQuarkFlavors"-><|"DownType"->gcNf|>|>];
FTTest`FTAssert["a declared degenerate flavor class includes every generation and preserves undeclared classes",
 (FeynCalc`SMP/@{"m_d","m_s","m_b","m_c"}/.gcMassRules)==={0,0,0,FeynCalc`SMP["m_c"]}];
FTTest`FTReport[];
