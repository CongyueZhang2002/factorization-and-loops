Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
base=root<>"/Projects/EE_EEC/Raw/NLO/q-qb/Real/Work";
de=FeynFacet`FamilyArtifactRead[base<>"/DifferentialSystem.wl"]["DifferentialSystem"];
values=FeynFacet`FamilyArtifactRead[base<>"/MasterValues.wl"];
definitions=FeynFacet`ConstructMasterIntegralDefinitions[Join[de,<|"KinematicConditions"->values["KinematicConditions"]|>]];
FTTest`FTAssert["quadratic cut masters have shared physical definitions",AssociationQ[definitions]&&
 Length[definitions["MasterIntegralDefinitions"]]===Length[values["Values"]]];
If[!AssociationQ[definitions],Print[InputForm[definitions]];FTTest`FTReport[]];
dir=CreateDirectory[];request=<|"LibraryDirectory"->dir,"Mode"->"ReadWrite"|>;
Do[
 definition=definitions["MasterIntegralDefinitions"][i];
 stored=FeynFacet`StoreMasterIntegralValue[definition,<|"AnalyticExpression"->values["Values"][[i]]|>,request];
 FTTest`FTAssert["explicit native polynomial master "<>ToString[i]<>" enters the structural library",AssociationQ[stored]];
 If[!AssociationQ[stored],Print[InputForm[stored]];FTTest`FTReport[]];
 found=FeynFacet`FindMasterIntegralValue[definition,Automatic,request];

 FTTest`FTAssert["native polynomial master "<>ToString[i]<>" is reusable with its exact normalization",
 AssociationQ[found]&&found["ExactValue"]===values["Values"][[i]]],
 {i,Length[values["Values"]]}];
If[StringStartsQ[ExpandFileName[dir],ExpandFileName[$TemporaryDirectory]<>"/"],DeleteDirectory[dir,DeleteContents->True]];
Print["POLYNOMIAL MASTER LIBRARY TEST COMPLETE"];
FTTest`FTReport[];
