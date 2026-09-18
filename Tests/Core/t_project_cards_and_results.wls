Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
projectTestRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];Get[projectTestRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[projectTestRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
layoutChannel=projectTestRoot<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp";
layoutPlan=FeynFacet`PlanNLOCounterterms[layoutChannel];
FTTest`FTAssert["redundant separators do not change the project identity",AssociationQ[FeynFacet`PlanNLOCounterterms[projectTestRoot<>"//Projects/ppHX_UU/Raw/NLO/qqp-qqp"]]];
FTTest`FTAssert["physical counterterm insertions derive two required Born channels",
 AssociationQ[layoutPlan]&&Sort[Keys[layoutPlan["BornSourceOrders"]]]==={"qg-qg","qqp-qqp"}];
FTTest`FTAssert["finite counterterms derive Born through epsilon one",
 AllTrue[Values[layoutPlan["BornSourceOrders"]],#===1&]];
FTTest`FTAssert["NLO planning exposes PDF and FF distributions without external LO result paths",
 !KeyExistsQ[layoutPlan,"LowerOrderResults"]&&
 AllTrue[layoutPlan["CountertermDistributions"],
 (Lookup[#["Distribution"],"Format",None]==="FeynFacet-CollinearCountertermDistribution"||
 #["Distribution"]["Role"]==="Coupling")&]];
layoutMerged=FeynFacet`Private`projectMerge[<|"A"-><|"a"->1,"b"->2|>,"L"->{1,2}|>,<|"A"-><|"a"->3|>,"L"->{4}|>];
FTTest`FTAssert["nested settings merge; lists replace",
 layoutMerged["A"]===<|"a"->3,"b"->2|>&&layoutMerged["L"]==={4}];
layoutReal=FeynFacet`ReadProcessCard[layoutChannel,"Real"];
layoutVirtual=FeynFacet`ReadProcessCard[layoutChannel,"Virtual"];
FTTest`FTAssert["radiation and virtual support come from actual multiplicities",
 Length[Last[layoutReal["Partons"]]]===3&&Length[Last[layoutVirtual["Partons"]]]===2&&
 layoutReal["CoefficientKinematics"]["PhysicalRegion"]=!=layoutVirtual["CoefficientKinematics"]["PhysicalRegion"]];
layoutLL=FeynFacet`ReadProcessCard[projectTestRoot<>"/Projects/ppHX_LL/Raw/LO/qg-qg","Born"];
FTTest`FTAssert["longitudinal qg dependency uses both incoming helicities",
 !FreeQ[layoutLL["CoefficientKinematics"]["DistributionFactor"],h_[__]/;SymbolName[h]==="g1g"]&&
 AllTrue[First[layoutLL["HadronLongSpin"]],#=!=0&]&&First[Last[layoutLL["HadronLongSpin"]]]===0];
layoutFixture=CreateDirectory[];
CopyFile[projectTestRoot<>"/Projects/ppHX_UU/Common-Card.wl",layoutFixture<>"/Common-Card.wl"];
FeynFacet`WriteProjectCard[Get[projectTestRoot<>"/Projects/ppHX_UU/Raw/NNLO/qqp-qqp/DoubleReal/Card.wl"],
 layoutFixture<>"/Raw/NNLO/qqp-qqp/DoubleReal/Card.wl"];
layoutG=FeynFacet`ReadContributionCard[layoutFixture<>"/Raw/NNLO/qqp-qqp","DoubleReal.Gluons"];
layoutH=FeynFacet`ReadContributionCard[layoutFixture<>"/Raw/NNLO/qqp-qqp","DoubleReal.Ghosts"];
FTTest`FTAssert["one double-real card declares both weights exactly once",
 layoutG["AssemblyWeight"]===1/2&&layoutH["AssemblyWeight"]===-1&&layoutH["Radiation"]==={"ghost","antighost"}];
layoutGG=FeynFacet`ReadProcessCard[layoutFixture<>"/Raw/NNLO/qqp-qqp","DoubleReal.Gluons"];
layoutGhost=FeynFacet`ReadProcessCard[layoutFixture<>"/Raw/NNLO/qqp-qqp","DoubleReal.Ghosts"];
FTTest`FTAssert["NNLO amplitude setups derive the declared symmetry and ghost weights",
 AssociationQ[layoutGG]&&AssociationQ[layoutGhost]&&FeynFacet`Private`assemblyWeight[layoutGG]===1/2&&FeynFacet`Private`assemblyWeight[layoutGhost]===-1];
layoutLoc=FeynFacet`Private`projectResultLocation[layoutChannel<>"/Real/Work/Reduction",projectTestRoot];
FTTest`FTAssert["all project order channel and contribution path levels survive",
 layoutLoc["OwnerParts"]==={"Projects","ppHX_UU","Raw","NLO","qqp-qqp","Real","Work"}&&layoutLoc["RunParts"]==={"Reduction"}];
layoutRow[d_]:=<|"DeltaCoefficient"->d,"PlusCoefficients"-><||>,"RegularCoefficient"->0|>;
layoutMeta=<|"Order"->"LO","Contribution"->"Born","Scale"->layoutS,"Variables"->{layoutV,layoutW},"DimensionalRegulator"->layoutE|>;
layoutBorn=FeynFacet`CreatePartonicResult[<|0->layoutRow[2],1->layoutRow[3]|>,layoutMeta];
FTTest`FTAssert["missing epsilon order never silently becomes zero",
 TrueQ[FeynFacet`RequirePartonicEpsilonRange[layoutBorn,{0,1}]]&&FailureQ[FeynFacet`RequirePartonicEpsilonRange[layoutBorn,{0,2}]]];
FTTest`FTAssert["noncontiguous epsilon coefficients are rejected",
 FailureQ[FeynFacet`CreatePartonicResult[<|0->layoutRow[1],2->layoutRow[2]|>,layoutMeta]]];
FTTest`FTAssert["aborted or failed arithmetic cannot become stored coefficients",
 FailureQ[FeynFacet`CreatePartonicResult[<|0->layoutRow[$Aborted]|>,layoutMeta]]&&
 FailureQ[FeynFacet`CreatePartonicResult[<|0->layoutRow[1+$Failed]|>,layoutMeta]]];
layoutSlice=FeynFacet`CreatePartonicResult[<|1->layoutRow[3]|>,Join[layoutMeta,<|"LaurentLowerBound"->0|>]];
FTTest`FTAssert["adding a partial epsilon window cannot invent missing lower coefficients",
 FailureQ[FeynFacet`CombinePartonicResults[<|"A"->layoutBorn,"B"->layoutSlice|>,<|"Contribution"->"Total"|>]]];
FTTest`FTAssert["different normalization and different endpoint bases cannot be added",
 FailureQ[FeynFacet`CombinePartonicResults[<|"A"->layoutBorn,"B"->Join[layoutBorn,<|"DimensionalPrefactor"->layoutS^layoutE|>]|>,<||>]]&&
 FailureQ[FeynFacet`CombinePartonicResults[<|"A"->layoutBorn,"B"->Join[layoutBorn,<|"DistributionBasis"-><|"Variable"->layoutW,"Endpoint"->0|>|>]|>,<||>]]];
layoutSource=<|"EpsilonOrderRange"->{-1,0},"NormalVariable"->layoutW,"Interval"->{0,1-layoutV},
 "DimensionalRegulator"->layoutE,"DeltaTerms"->{<|"DerivativeOrder"->0,"Coefficients"-><|-1->2,0->3|>|>},
 "PlusTerms"->{<|"Power"->-1,"LogPower"->1,"SubtractionOrder"->1,"Coefficients"-><|-1->0,0->5|>|>},
 "RegularRemainderCoefficients"-><|-1->0,0->Log[layoutW]|>,"AlgebraicDefinitions"->{},"IntegralDefinitions"->{},"KernelDefinitions"->{}|>;
layoutNNLO=FeynFacet`PartonicResultFromEndpointDensity[layoutSource,Join[layoutMeta,<|"Order"->"NNLO","Contribution"->"DoubleReal","DensityConvention"->"test density"|>]];
FTTest`FTAssert["NNLO uses the same epsilon and distribution coefficient access",
 AssociationQ[layoutNNLO]&&layoutNNLO["Coefficients"][0]["DeltaCoefficient"]===3&&layoutNNLO["Coefficients"][0]["PlusCoefficients"][1]===5&&
 layoutNNLO["DistributionBasis"]["Interval"]==={0,1-layoutV}];
layoutColor=Join[layoutSource,<|"ColorComponents"->{Join[KeyTake[layoutSource,{"DeltaTerms","PlusTerms","RegularRemainderCoefficients"}],
 <|"ColorFactor"->layoutCA,"CouplingPower"->4,"ExternalFactor"->1|>]}|>];
layoutColored=FeynFacet`PartonicResultFromEndpointDensity[layoutColor,Join[layoutMeta,<|"Order"->"NNLO","Contribution"->"DoubleReal","DensityConvention"->"test density","Coupling"->layoutAlpha|>]];
FTTest`FTAssert["color and physical coupling factors retained once",
 layoutColored["Coefficients"][0]["DeltaCoefficient"]===3layoutCA layoutAlpha^4];
layoutFile=CreateTemporary[];Put[layoutBorn,layoutFile];
FTTest`FTAssert["common file reader checks identity",AssociationQ[FeynFacet`ReadPartonicResult[layoutFile,<|"Order"->"LO","EpsilonRange"->{0,1}|>]]&&
 FailureQ[FeynFacet`ReadPartonicResult[layoutFile,<|"Order"->"NLO"|>]]];DeleteFile[layoutFile];
layoutHigher=FeynFacet`ConstructBornResult[FeynFacet`ReadProcessCard[projectTestRoot<>"/Projects/ppHX_UU/Raw/LO/qqp-qqp","Born"],
 Join[FeynFacet`ProjectAssemblyRequest[FeynFacet`ReadProjectCard[projectTestRoot<>"/Projects/ppHX_UU"],"qqp-qqp","Born"],<|"EpsilonRange"->{0,2},"BornCouplingPower"->2|>]];
FTTest`FTAssert["Born producer computes requested epsilon two explicitly",
 AssociationQ[layoutHigher]&&layoutHigher["EpsilonRange"]==={0,2}&&FreeQ[layoutHigher["Coefficients"],_SeriesData|_SeriesCoefficient]];
FTTest`FTAssert["physical Born coupling power is homogeneous",layoutHigher["CouplingPower"]===2];
(* Change a temporary consumer card, with no LO folder or results present. *)
layoutTemp=CreateDirectory[];CopyFile[projectTestRoot<>"/Projects/ppHX_TT/Common-Card.wl",layoutTemp<>"/Common-Card.wl"];
CreateDirectory[layoutTemp<>"/Raw/NLO/qqp-qqp",CreateIntermediateDirectories->True];
layoutCTs=FeynFacet`ReadCountertermCards[projectTestRoot<>"/Projects/ppHX_TT/Raw/NLO/qqp-qqp"];
layoutName=SelectFirst[Keys[layoutCTs],
  MemberQ[Keys[First[layoutCTs[#]["OperatorInsertions"]]],"IncomingA"]&];layoutCT=Get[layoutCTs[layoutName]["CardFile"]];
layoutName=FileNameTake[DirectoryName[layoutCTs[layoutName]["CardFile"]]];
layoutHigh=Join[layoutCT,<|"EpsilonRange"->{-1,1}|>];
FeynFacet`WriteProjectCard[layoutHigh,layoutTemp<>"/Raw/NLO/qqp-qqp/"<>layoutName<>"/Card.wl"];
layoutHighPlan=FeynFacet`PlanNLOCounterterms[layoutTemp<>"/Raw/NLO/qqp-qqp"];
FTTest`FTAssert["a requested positive NLO epsilon coefficient automatically raises its Born source order",
 AssociationQ[layoutHighPlan]&&layoutHighPlan["BornSourceOrders"]["qqp-qqp"]===2&&
 !DirectoryQ[layoutTemp<>"/Raw/LO"]];
layoutFinite=<|"Variable"->xi,"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->1-xi|>;
layoutChanged=Join[layoutCT,<|"Counterterms"-><|"Schemes"-><|"IncomingA"->
 <|"FiniteKernels"-><|{{"q","u"},{"q","u"},"T"}->layoutFinite|>|>|>|>|>];
FeynFacet`WriteProjectCard[layoutChanged,layoutTemp<>"/Raw/NLO/qqp-qqp/"<>layoutName<>"/Card.wl"];
layoutChangedPlan=FeynFacet`PlanNLOCounterterms[layoutTemp<>"/Raw/NLO/qqp-qqp"];
FTTest`FTAssert["a finite scheme is planned from its physical operator without lower-order file declarations",
 AssociationQ[layoutChangedPlan]&&layoutChangedPlan["BornSourceOrders"]===<|"qqp-qqp"->1|>&&
 !KeyExistsQ[layoutChangedPlan,"LowerOrderResults"]];
layoutWrongRole=Join[layoutCT,<|"OperatorInsertions"->{<|"IncomingA"-><|
 "Distribution"->"FFCounterterm","PerturbativeOrder"->1,"Operation"->"Factorization"|>|>}|>];
FeynFacet`WriteProjectCard[layoutWrongRole,layoutTemp<>"/Raw/NLO/qqp-qqp/"<>layoutName<>"/Card.wl"];
FTTest`FTAssert["a fragmentation operator cannot be assigned to an incoming PDF leg",
 FailureQ[FeynFacet`PlanNLOCounterterms[layoutTemp<>"/Raw/NLO/qqp-qqp"]]];
layoutDouble=Join[layoutCT,<|"SourceChannel"->"qqp-qqp","SourceOrder"->"LO","OperatorInsertions"->{<|
 "IncomingA"-><|"Distribution"->"PDFCounterterm","PerturbativeOrder"->1,"Operation"->"Factorization"|>,
 "Observed"-><|"Distribution"->"FFCounterterm","PerturbativeOrder"->1,"Operation"->"Factorization"|>|>}|>];
FTTest`FTAssert["two first-order insertions cannot be mislabeled as one NLO counterterm",
 FailureQ[FeynFacet`CompileCountertermCard[layoutTemp<>"/Raw/NLO/qqp-qqp",layoutDouble]]];
DeleteDirectory[layoutTemp,DeleteContents->True];
layoutMany=FeynFacet`ReadCountertermCards[projectTestRoot<>"/Projects/ppHX_UU/Raw/NLO/qg-qg"];
FTTest`FTAssert["each lower Born source has a concrete counterterm contribution card",
 AssociationQ[layoutMany]&&Length[DeleteDuplicates[Lookup[Values[layoutMany],"SourceChannel"]]]===7&&
 AllTrue[Values[layoutMany],#["Contribution"]==="Counterterm"&&#["SourceOrder"]==="LO"&&
 MatchQ[#["OperatorInsertions"],{_Association..}]&&!KeyExistsQ[#,"LowerOrderResults"]&]];
layoutNames=Keys[layoutMany];
FTTest`FTAssert["different source-owned counterterm cards have distinct result files",
 DuplicateFreeQ[Lookup[Values[layoutMany],"ResultFile"]]&&
 AllTrue[Values[layoutMany],FileExistsQ[#["CardFile"]]&]];
DeleteDirectory[layoutFixture,DeleteContents->True];
FTTest`FTReport[];
