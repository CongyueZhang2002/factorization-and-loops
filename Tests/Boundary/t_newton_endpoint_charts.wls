Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
cover=FeynFacet`ConstructNewtonEndpointCharts[{cx,cy},{cx-cy,cx^2+4cy(1-cx)},
 <|"Ramification"->2|>];
FTAssert["Newton rays give the complete regularly subdivided monomial cover",
 AssociationQ[cover]&&cover["RegularFanRays"]==={{1,0},{1,1},{1,2},{0,1}}&&
 Length[cover["Charts"]]===3&&cover["CoverageVerified"]&&cover["DisjointInteriorsVerified"]&&
 cover["ResolutionVerified"]===False];
refined=FeynFacet`ConstructNewtonEndpointCharts[{cx,cy},{cx^3+cy^2}];
FTAssert["nonunimodular Newton cones are subdivided by exact lattice identities",
 AssociationQ[refined]&&AllTrue[refined["Charts"],Abs[Det[#["ExponentMatrix"]]]===1&]];
signPlus=FeynFacet`ConstructNewtonEndpointCharts[{cx,cy},{cx+cy}];
signMinus=FeynFacet`ConstructNewtonEndpointCharts[{cx,cy},{cx-cy}];
FTAssert["equal Newton supports do not claim equal seam regularity",
 signPlus["RegularFanRays"]===signMinus["RegularFanRays"]&&
 !signPlus["ResolutionVerified"]&&!signMinus["ResolutionVerified"]];
productCover=FeynFacet`ConstructMonomialEndpointCharts[{cx,cy},
 {{{1,1},{1,0}},{{1,0},{1,1}}},<|"ChartVariables"->{{cr1,ct1},{cr2,ct2}}|>];
jet[r_,t_,beta_]:=<|"Status"->"ContractedPhysicalEndpointJetsConstructed",
 "NormalVariable"->r,"TangentialVariable"->t,"DimensionalRegulator"->ce,
 "CoefficientRowLabels"->{"density"},"InitialConstantValues"->{1},
 "NormalExponent"->(ca+cb)ce,"TangentialRegulatorExponent"->beta ce,
 "IntegerOrderThrough"->-1,"RetainedIntegerPowers"->{-1},
 "CoefficientMatrices"-><|-1->{{1/t}}|>,"TangentialAnalyticFactor"->1|>;
records={<|"ChartIndex"->1,"CoefficientJets"->jet[cr1,ct1,ca]|>,
 <|"ChartIndex"->2,"CoefficientJets"->jet[cr2,ct2,cb]|>};
product=FeynFacet`IdentifyProductCornerTerm[productCover,records];
FTAssert["the unmodified product corner is recognized exactly",AssociationQ[product]];
records[[1,"CoefficientJets","TangentialAnalyticFactor"]]=(1+ct1)^ce;
FTAssert["a coordinate-dependent analytic unit is included in the product comparison",
 FailureQ[FeynFacet`IdentifyProductCornerTerm[productCover,records]]];
FTAssert["the three sector contact factors reproduce the original double pole",
 Together[1/(ca(ca+cb))+1/((ca+cb)(ca+2cb))+1/(cb(ca+2cb))-1/(ca cb)]===0];
FTReport[];
