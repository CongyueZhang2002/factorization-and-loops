$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
resumeDirectory=root<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp";
resumeSetup=FeynFacet`ReadProcessCard[resumeDirectory,"Real"];
resumePairs=FeynFacet`Private`projectAmplitudeInputs[resumeDirectory<>"/Real/Work/Amplitudes",resumeSetup,"Real"];
resumeReduction=FeynFacet`Private`projectReductionInput[resumeDirectory<>"/Real/Work/Reduction",resumeSetup,"Real"];
FTTest`FTAssert["complete matching diagram pairs and reduction can be resumed",
 ListQ[resumePairs]&&AssociationQ[resumeReduction]];
FTTest`FTAssert["saved reduced coefficients accept the same regulator under either package context",
 AssociationQ[FeynFacet`Private`projectCoefficientInput[resumeDirectory<>"/Real/Work/Reduction",resumeSetup,resumeReduction]]];
FTTest`FTAssert["a different amplitude process cannot reuse this reduction",
 FeynFacet`Private`projectReductionInput[resumeDirectory<>"/Real/Work/Reduction",
  Join[resumeSetup,<|"Partons"->({FeynArts`V[5],FeynArts`V[5]}->Last[resumeSetup["Partons"]])|>],"Real"]===$Failed];
FTTest`FTAssert["a different reduction cannot reuse the saved coefficients",
 FeynFacet`Private`projectCoefficientInput[resumeDirectory<>"/Real/Work/Reduction",resumeSetup,
  Join[resumeReduction,<|"ReductionInputFingerprint"->"different"|>]]===$Failed];
FTTest`FTAssert["association key order and bookkeeping do not change amplitude identity",
 FeynFacet`Private`projectAmplitudeIdentity[resumeSetup]===
 FeynFacet`Private`projectAmplitudeIdentity[Join[Reverse[resumeSetup],<|"CardName"->"display","SourceNotebook"->"display"|>]]];

FTTest`FTAssert["automatic reconstruction discovery uses the owning raw Work directory",
 FeynFacet`Private`coefficientResolveResultDirectory[resumeDirectory,"Real",Automatic]===
  FileNameJoin[{resumeDirectory,"Real","Work","Reduction"}]];
FTTest`FTAssert["explicit reconstruction paths are relative to the raw channel",
 FeynFacet`Private`coefficientResolveResultDirectory[resumeDirectory,"Real","Real/Work/Reduction"]===
  FileNameJoin[{resumeDirectory,"Real","Work","Reduction"}]];

resumeTemp=CreateDirectory[];
resumeCanonicalFiles=Sort[FileNames["F*_C*.wl",resumeDirectory<>"/Real/Work/Reduction/Pairs"]];
CreateDirectory[resumeTemp<>"/Pairs"];
Scan[CopyFile[#,FileNameJoin[{resumeTemp,"Pairs",FileNameTake[#]}]]&,resumeCanonicalFiles];
resumeTempFiles=Sort[FileNames["F*_C*.wl",resumeTemp<>"/Pairs"]];
resumeTable=FeynFacet`ReadMasterIntegralCoefficients[resumeDirectory<>"/Real/Work/Reduction/CoefficientResult.wl"];
resumeTable=Append[resumeTable,"InputFileFingerprint"->FeynFacet`Private`coefficientInputFileFingerprint[resumeTempFiles]];
FeynFacet`FamilyArtifactWrite[resumeTable,resumeTemp<>"/CoefficientResult.wl"];
FTTest`FTAssert["a matching explicit pair payload accepts its coefficient table",
 AssociationQ[FeynFacet`Private`projectCoefficientInput[resumeTemp,resumeSetup,resumeReduction]]];
resumeChanged=FeynFacet`FamilyArtifactRead[First[resumeTempFiles]];
resumeChanged=Append[resumeChanged,"PreFactor"->2resumeChanged["PreFactor"]];
FeynFacet`FamilyArtifactWrite[resumeChanged,First[resumeTempFiles]];
FTTest`FTAssert["changing a pair weight invalidates cached coefficients while retaining the same IBP targets",
 FeynFacet`Private`projectCoefficientInput[resumeTemp,resumeSetup,resumeReduction]===$Failed];
DeleteDirectory[resumeTemp,DeleteContents->True];

FTTest`FTReport[];
