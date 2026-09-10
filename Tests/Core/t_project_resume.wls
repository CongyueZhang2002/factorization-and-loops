$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
resumeDirectory=root<>"/Projects/ppHX_UU_NNLO/NLO/qqp-qqp";
resumeSetup=FeynFacet`ReadProcessCard[resumeDirectory,"Real"];
resumePairs=FeynFacet`Private`projectAmplitudeInputs[resumeDirectory<>"/Results/Real/Amplitudes",resumeSetup,"Real"];
resumeReduction=FeynFacet`Private`projectReductionInput[resumeDirectory<>"/Results/Real/Reduction",resumeSetup,"Real"];
FTTest`FTAssert["complete matching diagram pairs and reduction can be resumed",
 ListQ[resumePairs]&&AssociationQ[resumeReduction]];
FTTest`FTAssert["saved reduced coefficients accept the same regulator under either package context",
 AssociationQ[FeynFacet`Private`projectCoefficientInput[resumeDirectory<>"/Results/Real/Reduction",resumeSetup,resumeReduction]]];
FTTest`FTAssert["a different amplitude process cannot reuse this reduction",
 FeynFacet`Private`projectReductionInput[resumeDirectory<>"/Results/Real/Reduction",
  Join[resumeSetup,<|"Partons"->({FeynArts`V[5],FeynArts`V[5]}->Last[resumeSetup["Partons"]])|>],"Real"]===$Failed];
FTTest`FTAssert["a different reduction cannot reuse the saved coefficients",
 FeynFacet`Private`projectCoefficientInput[resumeDirectory<>"/Results/Real/Reduction",resumeSetup,
  Join[resumeReduction,<|"ReductionInputFingerprint"->"different"|>]]===$Failed];
FTTest`FTAssert["association key order and bookkeeping do not change amplitude identity",
 FeynFacet`Private`projectAmplitudeIdentity[resumeSetup]===
 FeynFacet`Private`projectAmplitudeIdentity[Join[Reverse[resumeSetup],<|"CardName"->"display","SourceNotebook"->"display"|>]]];
FTTest`FTReport[];
