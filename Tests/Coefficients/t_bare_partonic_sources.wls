$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
bsCard=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_UU_NNLO/NNLO/q-q","Counterterm"];
bsCatalog=FeynFacet`ReadBarePartonicSourceCatalog[bsCard];
If[!AssociationQ[bsCatalog],Print[bsCatalog]];
FTTest`FTAssert["explicit card dependencies load complete bare LO and NLO distributions",
 AssociationQ[bsCatalog]&&Length[bsCatalog["Sources"][0]]===2&&Length[bsCatalog["Sources"][1]]===6];
bsSource=FeynFacet`ResolveBarePartonicSource[bsCatalog,1,{{"q","newDown"},{"q","newDown"}},
 <|"newDown"->"DownType"|>,1];
bsOriginal=bsCatalog["Sources"][1]["q-q"];
If[!AssociationQ[bsSource],Print["SOURCE FAILURE ",bsSource]];
bsRestored=Map[FeynFacet`Private`partonicMap[Function[value,Cancel[Together[eU^2 value/eD^2]]],#]&,bsSource["Coefficients"]];
bsSubtracted=MapThread[FeynFacet`Private`partonicDistributionSum[{#1,
 FeynFacet`Private`partonicMap[Function[value,-value],#2]},2]&, {Values[bsRestored],Values[bsOriginal["Coefficients"]]}];
bsResidual=Map[FeynFacet`Private`partonicMap[Function[value,Cancel[Together[value]]],#]&,bsSubtracted];
FTTest`FTAssert["flavor relabeling proves the charge factor throughout the full distribution",
 AssociationQ[bsSource]&&bsSource["FlavorRelabeling"]["ChargeIndependentRemainderVerified"]&&
 FreeQ[bsSource["Coefficients"],eU]&&!FreeQ[bsSource["Coefficients"],eD]&&
 FeynFacet`Private`partonicZeroTreeQ[bsResidual]];
FTTest`FTAssert["a distinct-flavor channel is zero only below its explicit minimum order",
 FeynFacet`ResolveBarePartonicSource[bsCatalog,1,{{"q","u"},{"q","d"}},
 <|"u"->"UpType","d"->"DownType"|>,1]===0];
bsMissing=Join[bsCatalog,<|"Sources"->Join[bsCatalog["Sources"],<|1->KeyDrop[bsCatalog["Sources"][1],"q-q"]|>]|>];
FTTest`FTAssert["a missing allowed channel is not inferred to be zero",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsMissing,1,{{"q","u"},{"q","u"}},<|"u"->"UpType"|>,1]]];
FTTest`FTAssert["positive epsilon coverage is mandatory",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsCatalog,1,{{"q","u"},{"q","u"}},<|"u"->"UpType"|>,2]]];
bsContaminated=bsCatalog;
bsBadBorn=Join[bsCatalog["Sources"][0]["q-q"],<|"Coefficients"->Map[
 FeynFacet`Private`partonicMap[Function[value,value+nD eD^2],#]&,bsCatalog["Sources"][0]["q-q"]["Coefficients"]]|>];
bsContaminated=Join[bsCatalog,<|"Sources"->Join[bsCatalog["Sources"],
 <|0->Join[bsCatalog["Sources"][0],<|"q-q"->bsBadBorn|>]|>]|>];
FTTest`FTAssert["an internal flavor-charge sum cannot be relabeled as an external squared charge",
 FailureQ[FeynFacet`ResolveBarePartonicSource[bsContaminated,0,{{"q","newDown"},{"q","newDown"}},
 <|"newDown"->"DownType"|>,2]]];
FTTest`FTReport[];
