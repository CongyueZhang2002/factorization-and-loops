$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
cgBase=root<>"/Projects/SIDIS_UU_NNLO";
cgReal[project_,channel_]:=Module[{directory,card,setup,request},
 directory=root<>"/Projects/"<>project<>"/NLO/"<>channel;card=FeynFacet`ReadContributionCard[directory,"Real"];
 setup=FeynFacet`ReadProcessCard[directory,"Real"];request=FeynFacet`Private`projectAssemblyRequest[card,channel,"Real"];
 FeynFacet`ConstructCurrentRealDensity[setup,request]];
cgU=cgReal["SIDIS_UU_NNLO","q-q"];cgG=cgReal["SIDIS_UU_NNLO","q-g"];
FTTest`FTAssert["tagging either final parton gives the same exact unpolarized current density",
 FullSimplify[cgG["Values"]-(cgU["Values"]/.z->1-z),Assumptions->Q2>0&&muR2>0&&0<x<1&&0<z<1]==={0,0}];
cgL=cgReal["SIDIS_LL_NNLO","q-q"];cgLG=cgReal["SIDIS_LL_NNLO","q-g"];
FTTest`FTAssert["the helicity current retains the exact final-state tagging identity",
 FullSimplify[cgLG["Values"]-(cgL["Values"]/.z->1-z),Assumptions->Q2>0&&muR2>0&&0<x<1&&0<z<1]==={0}];
cgUbar=cgReal["SIDIS_UU_NNLO","qbar-qbar"];cgLbar=cgReal["SIDIS_LL_NNLO","qbar-qbar"];
FTTest`FTAssert["charge conjugation preserves the generated quark and antiquark real densities",
 FullSimplify[cgUbar["Values"]-cgU["Values"],Assumptions->Q2>0&&muR2>0&&0<x<1&&0<z<1]==={0,0}&&
 FullSimplify[cgLbar["Values"]-cgL["Values"],Assumptions->Q2>0&&muR2>0&&0<x<1&&0<z<1]==={0}];
cgVirtual[project_]:=Module[{directory,card,setup,request},
 directory=root<>"/Projects/"<>project<>"/NLO/q-q";card=FeynFacet`ReadContributionCard[directory,"Virtual"];
 setup=FeynFacet`ReadProcessCard[directory,"Virtual"];
 request=Join[FeynFacet`Private`projectAssemblyRequest[card,"q-q","Virtual"],<|"EpsilonRange"->{-2,1}|>];
 FeynFacet`ConstructCurrentVirtualContribution[setup,request]];
cgVU=cgVirtual["SIDIS_UU_NNLO"];cgVL=cgVirtual["SIDIS_LL_NNLO"];
FTTest`FTAssert["generated vector virtual correction agrees for UU and helicity through epsilon one",
 AssociationQ[cgVU]&&AssociationQ[cgVL]&&AllTrue[Range[-2,1],
 Factor[First[cgVU["Coefficients"][#]["DeltaCoefficient"]["DeltaCoefficient"]]-
 First[cgVL["Coefficients"][#]["DeltaCoefficient"]["DeltaCoefficient"]]]===0&]];
cgCard=FeynFacet`ReadContributionCard[cgBase<>"/NLO/q-q","Real"];
cgExpanded=FeynFacet`ConstructCurrentRealContribution[cgU,Join[cgCard["Assembly"]["EndpointExpansion"],<|"EpsilonRange"->{-2,1}|>]];
FTTest`FTAssert["the generated real and virtual double endpoint poles cancel",
 AssociationQ[cgExpanded]&&Factor[cgExpanded["Coefficients"][-2]["DeltaCoefficient"]["DeltaCoefficient"]+
 cgVU["Coefficients"][-2]["DeltaCoefficient"]["DeltaCoefficient"]]==={0,0}];
FTTest`FTAssert["NLO through epsilon one requests smooth corner data through epsilon three",
 Max[Flatten[Map[Function[requirements,Map[Lookup[#["Strata"],"RequiredSmoothFactorOrder"]&,requirements["TermRequirements"]]],
 cgExpanded["EndpointOrderRequirements"]]]]===3];
FTTest`FTReport[];
