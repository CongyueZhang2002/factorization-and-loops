Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
temp=CreateDirectory[];
CopyFile[root<>"/Projects/DrellYan_UU/Common-Card.wl",temp<>"/Common-Card.wl"];
prepared=FeynFacet`PrepareProjectChannel[temp,"NLO","q-g"];
If[FailureQ[prepared],Print[InputForm[prepared]];Exit[1]];
FTTest`FTAssert["qg counterterms belong to the Born qqb channel",
 !DirectoryQ[temp<>"/Raw/NLO/q-g/Counter-PDFB"]&&FileExistsQ[temp<>"/Raw/NLO/q-qb/Counter-PDFB/Card.wl"]];
selection=Get[prepared["ResultCard"]];
FTTest`FTAssert["result selection explicitly chooses the cross-channel counterterm component",
 MemberQ[selection["Inputs"],<|"Path"->"../../../Raw/NLO/q-qb/Counter-PDFB","OutputChannel"->"q-g","Weight"->1|>]];
owner=FeynFacet`ReadContributionCard[temp<>"/Raw/NLO/q-qb","Counter-PDFB"];
If[FailureQ[owner],Print[InputForm[owner]];Exit[1]];
FTTest`FTAssert["one source-owned PDF operator resolves its diagonal and off-diagonal outputs",
 owner["SourceChannel"]==="q-qb"&&ContainsAll[Keys[owner["TargetCards"]],{"q-g","q-qb"}]];
orderPlan=FeynFacet`PlanCountertermContribution[owner];
FTTest`FTAssert["source-owned order planning keeps independent target-channel demands",
 AssociationQ[orderPlan]&&Sort[Keys[orderPlan["ChannelPlans"]]]===Sort[Keys[owner["TargetCards"]]]];
finiteDefinition=<|"Contribution"->"Counterterm","SourceRenormalizationStage"->"Renormalized",
 "OutputChannels"->{"q-qb"},"EpsilonRange"->{0,0},"OperatorInsertions"->{<|
 "IncomingB"-><|"Distribution"->"PDFCounterterm","PerturbativeOrder"->1,"Operation"->"FiniteSchemeChange",
 "OperatorRedefinition"-><|"FiniteKernels"-><|{{"qb","u"},{"qb","u"},"U"}-><|
 "Variable"->owner["Assembly"]["FactorizationLegs"]["IncomingB"]["Variable"],"DeltaCoefficient"->lambda,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>|>|>|>|>}|>;
FeynFacet`WriteProjectCard[finiteDefinition,temp<>"/Raw/NLO/q-qb/Counter-PDFB-Finite/Card.wl"];
finiteCard=FeynFacet`ReadContributionCard[temp<>"/Raw/NLO/q-qb","Counter-PDFB-Finite","q-qb"];
finitePlan=If[AssociationQ[finiteCard],FeynFacet`PlanCountertermContribution[finiteCard],finiteCard];
If[FailureQ[finitePlan],Print[InputForm[finitePlan]]];
FTTest`FTAssert["source ownership preserves explicitly requested finite counterterm operators",
 AssociationQ[finiteCard]&&AssociationQ[FeynFacet`PlanCountertermContribution[finiteCard]]];
FTTest`FTAssert["selecting a component cannot bypass a raw card's declared output scope",
 FailureQ[FeynFacet`ReadContributionCard[temp<>"/Raw/NLO/q-qb","Counter-PDFB-Finite","q-g"]]];
FTTest`FTAssert["source channels need no repeated source declaration in the card",
 !KeyExistsQ[Get[temp<>"/Raw/NLO/q-qb/Counter-PDFB/Card.wl"],"SourceChannel"]];
planned=FeynFacet`PlanProjectResult[prepared["ResultCard"]];
If[FailureQ[planned],Print[InputForm[planned]];Exit[1]];
FTTest`FTAssert["cross-channel selection has exact counterterm coverage",planned["Coverage"]["Status"]==="Passed"];
wrong=Join[selection,<|"Inputs"->(If[KeyExistsQ[#,"OutputChannel"],Join[#,<|"OutputChannel"->"q-qb"|>],#]&/@selection["Inputs"])|>];
FeynFacet`WriteProjectCard[wrong,prepared["ResultCard"]];
FTTest`FTAssert["a component belonging to another final channel is rejected",
 FailureQ[FeynFacet`PlanProjectResult[prepared["ResultCard"]]]];
FeynFacet`WriteProjectCard[selection,prepared["ResultCard"]];
made=FeynFacet`RunRawContribution[owner,"all"];
If[FailureQ[made],Print[InputForm[made]];Exit[1]];
stored=FeynFacet`FamilyArtifactRead[owner["ResultFile"]];
FTTest`FTAssert["raw operator outputs contain explicit common-format results",
 AssociationQ[made]&&stored["Format"]==="FeynFacet-PartonicChannelResults"&&
 AllTrue[stored["Results"],AssociationQ[FeynFacet`ReadPartonicResult[#]]&]];
FTTest`FTAssert["all source-owned outputs retain their distinct target identities",
 AllTrue[Keys[stored["Results"]],stored["Results"][#]["Channel"]===#&]];
again=FeynFacet`RunRawContribution[owner,"resume"];
FTTest`FTAssert["each matching channel component can be resumed",
 AssociationQ[again]&&AllTrue[again["ChannelResults"],TrueQ[#["Reused"]]&]];
result=FeynFacet`RunProjectResult[prepared["ResultCard"],"all"];
If[FailureQ[result],Print[InputForm[result]];Exit[1]];
FTTest`FTAssert["fresh full qg assembly cancels poles with a counterterm from qqb",
 result["PoleCancellation"]==="Passed"];
stored2=FeynFacet`FamilyArtifactRead[owner["ResultFile"]];
FTTest`FTAssert["evaluating one selected component preserves other computed outputs",
 Keys[stored2["Results"]]===Keys[stored["Results"]]&&
 stored2["Results"]["q-qb"]["Coefficients"]===stored["Results"]["q-qb"]["Coefficients"]];
selection2=FeynFacet`PrepareProjectChannel[temp,"NLO","q-qb"];
FTTest`FTAssert["a second result reuses the same operator card without duplicating it",
 AssociationQ[selection2]&&Length[FileNames["Counter-PDFB/Card.wl",temp<>"/Raw/NLO/q-qb"]]===1];
DeleteDirectory[temp,DeleteContents->True];
FTTest`FTReport[];
