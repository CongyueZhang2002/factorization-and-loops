Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
ccDirectory=root<>"/Projects/SIDIS_LL/Raw/NLO/q-q";
ccDefinitions=FeynFacet`PlanCountertermContributionCards[ccDirectory];
ccCards=Association@MapIndexed[("Contribution"<>ToString[First[#2]])->
 FeynFacet`CompileCountertermCard[ccDirectory,#1]&,ccDefinitions];
ccCheck=FeynFacet`VerifyCountertermCardCoverage[ccDirectory,ccCards];
FTTest`FTAssert["the complete resolved NLO counterterm set has exact mathematical coverage",
 AssociationQ[ccCheck]&&ccCheck["Status"]==="Passed"];
ccRenamed=Association@KeyValueMap[("Renamed"<>#1)->Join[#2,<|"CardName"->"Renamed"<>#1|>]&,ccCards];
FTTest`FTAssert["renaming contribution cards does not change counterterm coverage",
 FeynFacet`VerifyCountertermCardCoverage[ccDirectory,ccRenamed]["Status"]==="Passed"];
ccFirstName=First[Keys[ccCards]];ccFirst=ccCards[ccFirstName];
ccSplit=Association@MapIndexed[("Term"<>ToString[First[#2]])->
 Join[ccFirst,<|"CardName"->"Term"<>ToString[First[#2]],"OperatorInsertions"->{#1}|>]&,ccFirst["OperatorInsertions"]];
ccSplit=Join[KeyDrop[ccCards,ccFirstName],ccSplit];
FTTest`FTAssert["splitting operator products into separate source-channel cards preserves coverage",
 FeynFacet`VerifyCountertermCardCoverage[ccDirectory,ccSplit]["Status"]==="Passed"];
ccDuplicate=Join[ccCards,<|"Duplicate"->Join[ccFirst,<|"CardName"->"Duplicate"|>]|>];
ccCheck=FeynFacet`VerifyCountertermCardCoverage[ccDirectory,ccDuplicate];
FTTest`FTAssert["a differently named duplicate mathematical contribution is rejected",
 AssociationQ[ccCheck]&&ccCheck["Status"]==="Failed"&&ccCheck["DuplicateTerms"]=!={}];
ccMissing=Join[ccFirst,<|"OperatorInsertions"->Rest[ccFirst["OperatorInsertions"]]|>];
ccCheck=FeynFacet`VerifyCountertermCardCoverage[ccDirectory,Join[ccCards,<|ccFirstName->ccMissing|>]];
FTTest`FTAssert["a missing operator product is reported before any source is generated",
 AssociationQ[ccCheck]&&ccCheck["Status"]==="Failed"&&ccCheck["MissingTerms"]=!={}];
ccProducts=ccFirst["OperatorInsertions"];ccLeg=First[Keys[First[ccProducts]]];
ccProducts[[1]]=Join[ccProducts[[1]],<|ccLeg->Join[ccProducts[[1]][ccLeg],<|"FlavorMultiplicity"->2|>]|>];
ccChanged=Join[ccFirst,<|"OperatorInsertions"->ccProducts|>];
ccCheck=FeynFacet`VerifyCountertermCardCoverage[ccDirectory,Join[ccCards,<|ccFirstName->ccChanged|>]];
FTTest`FTAssert["counterterm coverage includes the exact flavor multiplicity",
 AssociationQ[ccCheck]&&ccCheck["Status"]==="Failed"&&ccCheck["UnexpectedTerms"]=!={}];
ccBad[field_,value_]:=Module[{products=ccFirst["OperatorInsertions"]},
 products[[1]]=Join[products[[1]],<|ccLeg->Join[products[[1]][ccLeg],<|field->value|>]|>];
 FeynFacet`PlanCountertermContribution[Join[ccFirst,<|"OperatorInsertions"->products|>]]];
FTTest`FTAssert["a counterterm insertion cannot change the physical source spin",
 FailureQ[ccBad["Spin","T"]]];
FTTest`FTAssert["a counterterm insertion cannot change the derived pole normalization",
 FailureQ[ccBad["PoleNormalization",1+Global`Epsilon]]];
FTTest`FTAssert["unknown insertion fields are rejected instead of silently ignored",
 FailureQ[ccBad["UnknownPhysicalConvention",1]]];
ccUVDirectory=root<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp";
ccUV=FeynFacet`CompileCountertermCard[ccUVDirectory,<|"Contribution"->"Counterterm","SourceOrder"->"LO",
 "SourceChannel"->"qqp-qqp","SourceRenormalizationStage"->"Bare","EpsilonRange"->{-1,0},
 "OperatorInsertions"->{<|"Coupling"-><|"Distribution"->"CouplingCounterterm","PerturbativeOrder"->1,
   "Operation"->"CollinearSubtraction","ScaleLog"->1|>|>}|>];
FTTest`FTAssert["unsupported coupling insertion fields are rejected instead of ignored",
 FailureQ[FeynFacet`PlanCountertermContribution[ccUV]]];
ccNNLODirectory=root<>"/Projects/SIDIS_LL/Raw/NNLO/q-q";
ccNNLODefinitions=FeynFacet`PlanCountertermContributionCards[ccNNLODirectory];
ccNNLOCards=Association@MapIndexed[("NNLO"<>ToString[First[#2]])->
 FeynFacet`CompileCountertermCard[ccNNLODirectory,#1]&,ccNNLODefinitions];
ccCheck=FeynFacet`VerifyCountertermCardCoverage[ccNNLODirectory,ccNNLOCards];
If[!AssociationQ[ccCheck]||ccCheck["Status"]=!="Passed",Print["NNLO_COVERAGE ",ccCheck]];
FTTest`FTAssert["correlated NNLO raw and finite operator products have complete nonduplicate coverage",
 AssociationQ[ccCheck]&&ccCheck["Status"]==="Passed"&&
 AnyTrue[Values[ccNNLOCards],#["SourceRenormalizationStage"]==="Renormalized"&]];
ccFiniteName=SelectFirst[Keys[ccNNLOCards],ccNNLOCards[#]["SourceRenormalizationStage"]==="Renormalized"&];
ccCheck=FeynFacet`VerifyCountertermCardCoverage[ccNNLODirectory,KeyDrop[ccNNLOCards,ccFiniteName]];
FTTest`FTAssert["omitting a finite NNLO counterterm is rejected even though it introduces no uncancelled pole",
 AssociationQ[ccCheck]&&ccCheck["Status"]==="Failed"&&ccCheck["MissingTerms"]=!={}];
ccRawName=SelectFirst[Keys[ccNNLOCards],ccNNLOCards[#]["SourceRenormalizationStage"]==="Bare"&];
ccTruncated=Join[ccNNLOCards,<|ccRawName->Join[ccNNLOCards[ccRawName],<|"EpsilonRange"->{-4,-1}|>]|>];
ccCheck=FeynFacet`VerifyCountertermCardCoverage[ccNNLODirectory,ccTruncated];
FTTest`FTAssert["complete counterterm coverage requires every card through the requested final epsilon order",
 AssociationQ[ccCheck]&&ccCheck["Status"]==="Failed"&&ccCheck["InsufficientEpsilonRanges"]=!={}];
FTTest`FTReport[];
