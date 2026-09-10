$HistoryLength=0;$MaxExtraPrecision=50;
projectTestRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];Get[projectTestRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[projectTestRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
layoutChannel=projectTestRoot<>"/Projects/ppHX_UU_NNLO/NLO/qqp-qqp";
layoutPlan=FeynFacet`PlanNLOProject[layoutChannel];
FTTest`FTAssert["redundant separators do not change the project identity",AssociationQ[FeynFacet`PlanNLOProject[projectTestRoot<>"//Projects/ppHX_UU_NNLO/NLO/qqp-qqp"]]];
FTTest`FTAssert["explicit LO dependencies span two channels",
 AssociationQ[layoutPlan]&&Sort[Keys[layoutPlan["LowerOrderResults"]]]==={"qg-qg","qqp-qqp"}];
FTTest`FTAssert["finite counterterms require Born through epsilon one",
 AllTrue[Values[layoutPlan["LowerOrderResults"]],#["RequiredEpsilonRange"]==={0,1}&]];
FTTest`FTAssert["paths resolve relative to Cards, including the perturbative order",
 layoutPlan["LowerOrderResults"]["qg-qg"]["File"]===projectTestRoot<>"/Projects/ppHX_UU_NNLO/LO/qg-qg/Results/Result.wl"];
layoutMerged=FeynFacet`Private`projectMerge[<|"A"-><|"a"->1,"b"->2|>,"L"->{1,2}|>,<|"A"-><|"a"->3|>,"L"->{4}|>];
FTTest`FTAssert["nested settings merge; lists replace",
 layoutMerged["A"]===<|"a"->3,"b"->2|>&&layoutMerged["L"]==={4}];
layoutReal=FeynFacet`ReadProcessCard[layoutChannel,"Real"];
layoutVirtual=FeynFacet`ReadProcessCard[layoutChannel,"Virtual"];
FTTest`FTAssert["radiation and virtual support come from actual multiplicities",
 Length[Last[layoutReal["Partons"]]]===3&&Length[Last[layoutVirtual["Partons"]]]===2&&
 layoutReal["CoefficientKinematics"]["PhysicalRegion"]=!=layoutVirtual["CoefficientKinematics"]["PhysicalRegion"]];
layoutLL=FeynFacet`ReadProcessCard[projectTestRoot<>"/Projects/ppHX_LL_NLO/LO/qg-qg","Born"];
FTTest`FTAssert["longitudinal qg dependency uses both incoming helicities",
 !FreeQ[layoutLL["CoefficientKinematics"]["DistributionFactor"],h_[__]/;SymbolName[h]==="g1g"]&&
 AllTrue[First[layoutLL["HadronLongSpin"]],#=!=0&]&&First[Last[layoutLL["HadronLongSpin"]]]===0];
layoutG=FeynFacet`ReadContributionCard[projectTestRoot<>"/Projects/ppHX_UU_NNLO/NNLO/qqp-qqp","DoubleReal.Gluons"];
layoutH=FeynFacet`ReadContributionCard[projectTestRoot<>"/Projects/ppHX_UU_NNLO/NNLO/qqp-qqp","DoubleReal.Ghosts"];
FTTest`FTAssert["one double-real card declares both weights exactly once",
 layoutG["AssemblyWeight"]===1/2&&layoutH["AssemblyWeight"]===-1&&layoutH["Radiation"]==={"ghost","antighost"}];
layoutGG=FeynFacet`ReadProcessCard[projectTestRoot<>"/Projects/ppHX_UU_NNLO/NNLO/qqp-qqp","DoubleReal.Gluons"];
layoutGhost=FeynFacet`ReadProcessCard[projectTestRoot<>"/Projects/ppHX_UU_NNLO/NNLO/qqp-qqp","DoubleReal.Ghosts"];
FTTest`FTAssert["NNLO amplitude setups derive the declared symmetry and ghost weights",
 AssociationQ[layoutGG]&&AssociationQ[layoutGhost]&&FeynFacet`Private`assemblyWeight[layoutGG]===1/2&&FeynFacet`Private`assemblyWeight[layoutGhost]===-1];
layoutLoc=FeynFacet`Private`projectResultLocation[layoutChannel<>"/Results/Real/Reduction",projectTestRoot];
FTTest`FTAssert["all project order channel and contribution path levels survive",
 layoutLoc["OwnerParts"]==={"Projects","ppHX_UU_NNLO","NLO","qqp-qqp"}&&layoutLoc["RunParts"]==={"Real","Reduction"}];
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
layoutHigher=FeynFacet`ConstructBornResult[FeynFacet`ReadProcessCard[projectTestRoot<>"/Projects/ppHX_UU_NNLO/LO/qqp-qqp","Born"],
 Join[FeynFacet`Private`projectAssemblyRequest[FeynFacet`ReadProjectCard[projectTestRoot<>"/Projects/ppHX_UU_NNLO"],"qqp-qqp","Born"],<|"EpsilonRange"->{0,2},"BornCouplingPower"->2|>]];
FTTest`FTAssert["Born producer computes requested epsilon two explicitly",
 AssociationQ[layoutHigher]&&layoutHigher["EpsilonRange"]==={0,2}&&FreeQ[layoutHigher["Coefficients"],_SeriesData|_SeriesCoefficient]];
FTTest`FTAssert["physical Born coupling power is homogeneous",layoutHigher["CouplingPower"]===2];
(* Alter only a temporary project to test card-level epsilon and scheme demands. *)
layoutTemp=CreateDirectory[];CopyFile[projectTestRoot<>"/Projects/ppHX_TT_NLO/card.wl",layoutTemp<>"/card.wl"];
CreateDirectory[layoutTemp<>"/NLO/qqp-qqp/Cards",CreateIntermediateDirectories->True];
layoutCT=Get[projectTestRoot<>"/Projects/ppHX_TT_NLO/NLO/qqp-qqp/Cards/Counterterm.wl"];
layoutBad=layoutCT;layoutBad["LowerOrderResults"]=<|"qqp-qqp"-><|"File"->"../../../LO/qqp-qqp/Results/Result.wl","EpsilonRange"->{0,0}|>|>;
Put[layoutBad,layoutTemp<>"/NLO/qqp-qqp/Cards/Counterterm.wl"];
FTTest`FTAssert["insufficient declared Born orders fail during planning",FailureQ[FeynFacet`PlanNLOProject[layoutTemp<>"/NLO/qqp-qqp"]]];
layoutFinite=<|"Variable"->xi,"DeltaCoefficient"->0,"PlusCoefficients"-><||>,"RegularCoefficient"->1-xi|>;
layoutBad=Join[layoutCT,<|"Counterterms"-><|"Schemes"-><|"IncomingB"-><|"FiniteKernels"-><|{{"q","u"},{"q","d"},"T"}->layoutFinite|>|>|>|>|>];
Put[layoutBad,layoutTemp<>"/NLO/qqp-qqp/Cards/Counterterm.wl"];
FTTest`FTAssert["finite scheme mixing requires an explicitly declared extra Born channel",
 MatchQ[FeynFacet`PlanNLOProject[layoutTemp<>"/NLO/qqp-qqp"],Failure["AdditionalLowerOrderChannelDeclarationRequired",_]]];
DeleteDirectory[layoutTemp,DeleteContents->True];
FTTest`FTReport[];
