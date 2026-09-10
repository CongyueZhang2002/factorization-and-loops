(* Physical final-state completeness and unresolved flavor multiplicities. *)
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
$PrePrint=.;
channelSpecies={"g",{"q","u"},{"qbar","u"},{"q","d"},{"qbar","d"},{"q","s"},{"qbar","s"}};
channelQG=<|"Incoming"->{{"q","u"},"g"},"Observed"->{"q","u"},"Recoil"->"g"|>;
channelRequest=<|"Species"->channelSpecies,"FlavorCount"->channelNF|>;
channelReal=FeynFacet`EnumerateNLORealChannels[channelQG,channelRequest];
FTTest`FTAssert["qg observed quark includes three physical final states and ghost completion",
 AssociationQ[channelReal]&&Length[channelReal["Components"]]===4&&
 Count[Lookup[Values[channelReal["Components"]],"UnobservedPartons"],{"g","g"}]===1];
channelRows=Values[channelReal["Components"]];
FTTest`FTAssert["unobserved identical gluons carry one half",
 SelectFirst[channelRows,#["UnobservedPartons"]==={"g","g"}&]["AssemblyWeight"]===1/2];
FTTest`FTAssert["ghost completion carries minus one",
 channelReal["Components"]["Ghosts"]["AssemblyWeight"]===-1];
FTTest`FTAssert["same-flavor pair counted once",
 SelectFirst[channelRows,Sort[#["UnobservedPartons"]]===Sort[{{"q","u"},{"qbar","u"}}]&]["FlavorMultiplicity"]===1];
FTTest`FTAssert["other massless flavors are summed once",
 Count[Lookup[channelRows,"FlavorMultiplicity"],channelNF-1]===1];
channelObservedG=Join[channelQG,<|"Observed"->"g","Recoil"->{"q","u"}|>];
channelG=FeynFacet`EnumerateNLORealChannels[channelObservedG,channelRequest];
FTTest`FTAssert["qg observed gluon needs only the gluon-quark recoil",
 Length[channelG["Components"]]===1&&Sort[First[Values[channelG["Components"]]]["UnobservedPartons"]]===Sort[{"g",{"q","u"}}]];
channelAnnihilation=<|"Incoming"->{{"q","u"},{"qbar","u"}},"Observed"->{"q","d"},"Recoil"->{"qbar","d"}|>;
channelA=FeynFacet`EnumerateNLORealChannels[channelAnnihilation,channelRequest];
FTTest`FTAssert["distinct-flavor annihilation has one real final state",
 Length[channelA["Components"]]===1&&Sort[First[Values[channelA["Components"]]]["UnobservedPartons"]]===Sort[{"g",{"qbar","d"}}]];
channelOne=FeynFacet`EnumerateNLORealChannels[channelQG,Join[channelRequest,<|"FlavorCount"->1|>]];
FTTest`FTAssert["one active flavor removes the different-flavor pair",
 Length[channelOne["Components"]]===3&&FreeQ[Lookup[Values[channelOne["Components"]],"FlavorMultiplicity"],0]];
FTTest`FTAssert["too few active flavors for external particles fails",
 FailureQ[FeynFacet`EnumerateNLORealChannels[channelAnnihilation,Join[channelRequest,<|"FlavorCount"->1|>]]]];
channelCTRequest=<|"Species"->channelSpecies,"Polarization"-><|"Incoming"->{"U","U"},"Observed"->"U"|>,
 "Schemes"-><|"IncomingA"->"MSbar","IncomingB"->"MSbar","Observed"->"MSbar"|>,
 "SplittingVariable"->channelXi,"FlavorSummation"->"MasslessQCD",
 "KernelParameters"-><|"CA"->channelCA,"CF"->channelCF,"TR"->1/2,"FlavorCount"->channelNF|>|>;
channelCT=FeynFacet`EnumerateNLOCollinearChannels[channelQG,channelCTRequest];
FTTest`FTAssert["quark and antiquark Born mixing each sum all other flavors",
 AssociationQ[channelCT]&&Count[Lookup[channelCT["Channels"],"FlavorMultiplicity"],channelNF-1]===2];
channelIncomplete={"g",{"q","u"},{"qbar","u"}};
FTTest`FTAssert["missing free-flavor representative cannot silently omit real states",
 FailureQ[FeynFacet`EnumerateNLORealChannels[channelQG,
 Join[channelRequest,<|"Species"->channelIncomplete|>]]]];
FTTest`FTAssert["missing free-flavor representative cannot silently omit Born mixing",
 MatchQ[FeynFacet`EnumerateNLOCollinearChannels[channelQG,
 Join[channelCTRequest,<|"Species"->channelIncomplete|>]],
 Failure["AdditionalUnobservedFlavorRepresentativeRequired",_]]];
FTTest`FTAssert["single active flavor needs no unused representative",
 AssociationQ[FeynFacet`EnumerateNLORealChannels[channelQG,
 Join[channelRequest,<|"Species"->channelIncomplete,"FlavorCount"->1|>]]]];
FTTest`FTAssert["incomplete quark-antiquark species pair is rejected",
 FailureQ[FeynFacet`EnumerateNLORealChannels[channelQG,
 Join[channelRequest,<|"Species"->{"g",{"q","u"}}|>]]]];
FTTest`FTAssert["annihilation does not require an unrelated flavor representative",
 AssociationQ[FeynFacet`EnumerateNLOCollinearChannels[channelAnnihilation,
 Join[channelCTRequest,<|"Species"->DeleteCases[channelSpecies,{"q"|"qbar","s"}]|>]]]];
FTTest`FTReport[];
