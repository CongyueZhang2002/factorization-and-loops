Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
gsTemp=CreateDirectory[];
CopyFile[root<>"/Projects/SIDIS_UU/Common-Card.wl",gsTemp<>"/Common-Card.wl"];
CreateDirectory[gsTemp<>"/Raw/NNLO/q-q",CreateIntermediateDirectories->True];
gsCard=FeynFacet`BuildCountertermProjectCard[gsTemp<>"/Raw/NNLO/q-q"];
gsRequirements={
 <|"SourceOrder"->0,"SourceSpecies"->{{"q","u"},{"q","u"}},"RequiredSourceThroughOrder"->0|>,
 <|"SourceOrder"->0,"SourceSpecies"->{{"q","u"},{"q","u"}},"RequiredSourceThroughOrder"->2|>,
 <|"SourceOrder"->1,"SourceSpecies"->{"g",{"q","u"}},"RequiredSourceThroughOrder"->0|>,
 <|"SourceOrder"->1,"SourceSpecies"->{"g",{"q","u"}},"RequiredSourceThroughOrder"->1|>,
 <|"SourceOrder"->1,"SourceSpecies"->{{"q","u"},{"q","d"}},"RequiredSourceThroughOrder"->3|>};
gsCatalog=FeynFacet`GenerateBarePartonicSourceCatalog[gsCard,gsRequirements];
If[!AssociationQ[gsCatalog],Print[gsCatalog]];
FTTest`FTAssert["a fresh NNLO consumer generates only the allowed demanded LO and NLO source channels",
 AssociationQ[gsCatalog]&&Keys[gsCatalog["Sources"][0]]==={"q-q"}&&
 Keys[gsCatalog["Sources"][1]]==={"g-q"}];
FTTest`FTAssert["repeated demands use the maximum required epsilon order for each source",
 AssociationQ[gsCatalog]&&gsCatalog["Sources"][0]["q-q"]["EpsilonRange"]==={0,2}&&
 Last[gsCatalog["Sources"][1]["g-q"]["EpsilonRange"]]===1];
FTTest`FTAssert["generated lower-order sources remain bare and preserve their complete Laurent ranges",
 AssociationQ[gsCatalog]&&AllTrue[Join[Values[gsCatalog["Sources"][0]],Values[gsCatalog["Sources"][1]]],
 #["RenormalizationStage"]==="Bare"&&First[#["EpsilonRange"]]===#["LaurentLowerBound"]&&
 FreeQ[#["Coefficients"],_Integrate|_SeriesData|_SeriesCoefficient|_Failure|_Missing]&]];
FTTest`FTAssert["NNLO source generation needs no sibling LO or NLO result tree",
 !DirectoryQ[gsTemp<>"/Raw/LO"]&&!DirectoryQ[gsTemp<>"/Raw/NLO"]&&
 FileExistsQ[gsTemp<>"/Raw/NNLO/q-q/Counterterm/Work/Sources/LO/q-q/Results.wl"]&&
 FileExistsQ[gsTemp<>"/Raw/NNLO/q-q/Counterterm/Work/Sources/NLO/g-q/Results.wl"]];
FTTest`FTAssert["forbidden lower-order flavor channels remain exact zero without a generated artifact",
 AssociationQ[gsCatalog]&&FeynFacet`ResolveBarePartonicSource[gsCatalog,1,
 {{"q","u"},{"q","d"}},<|"u"->"UpType","d"->"DownType"|>,3]===0&&
 !DirectoryQ[gsTemp<>"/Raw/NNLO/q-q/Counterterm/Work/Sources/NLO/q-qp"]];
DeleteDirectory[gsTemp,DeleteContents->True];
Print["REGRESSION CHECK COMPLETE"];
FTTest`FTReport[];
