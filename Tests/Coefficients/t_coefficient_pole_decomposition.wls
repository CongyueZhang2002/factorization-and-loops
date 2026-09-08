#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Algebra/RegulatorSeries.wl"];
Begin["FeynFacet`Private`"];Get[Global`root<>"/FeynFacet/Coefficients/FinalResults.wl"];End[];
Get[root<>"/FeynFacet/Coefficients/PoleCancellation.wl"];
Clear[e,z];
ent=<|"Master"->GLI[A,{1}],"Terms"->{<|"PreFactor"->3,"Representation"->"LaurentSeries",
 "Coefficient"-><|"SeriesVariable"->e,"SeriesTruncation"->2,
 "Orders"-><|0->1/z+1,1->-1/z^2+z,2->1/z^3+z^2|>|>|>}|>;
pole=<|"PoleLabel"->"M1","SourceTermIndex"->1,"Residue"->1,"DivisorLocation"->-e,
 "SourceResidueCertificate"-><|"Status"->"ExactSourceResidueProportionalityEstablished"|>|>;
req=<|"DimensionalRegulator"->e,"NormalVariable"->z,"ThroughOrder"->2,
 "ResidualDivisorCertificate"-><|"Status"->"FixedResidualDivisorsEstablished",
 "UniformOnTangentialCompactSets"->True,"NormalPoleOrderUpperBound"->0,"RemovedPoleLabels"->{"M1"}|>|>;
d=SeparateMasterCoefficientPoles[ent,{pole},req];
FTAssert["pole subtraction leaves the independently known regular coefficients",
 AssociationQ[d]&&Values[d["RemainderEntry"]["Terms"][[1,"Coefficient","Orders"]]]==={1,z,z^2}];
FTAssert["a finite coefficient remains finite with the correct unknown tail",
 d["RemainderEntry"]["Terms"][[1,"Coefficient","SeriesTruncation"]]===2&&
 d["RemainderEntry"]["Terms"][[1,"LaurentRemainderClass","EpsilonOrderLowerBound"]]===3];
FTAssert["the exact pole part retains the prefactor once",
 d["PoleEntries"]["M1"]["PartialCoefficientContributions"][[1,"PoleExpression"]]===3/(z+e)];
r=d["RemainderEntry"]["SeparatedCoefficientPoles"];a=d["PoleEntries"]["M1"]["PartialCoefficientContributions"];
FTAssert["matching removed and restored parts close the original coefficient",
 FeynFacet`Private`coefficientPoleCoverage[r,a,{{"A",{1}}}]];
FTAssert["missing, duplicated, and altered pole parts are rejected",
 !FeynFacet`Private`coefficientPoleCoverage[r,{},{{"A",{1}}}]&&
 !FeynFacet`Private`coefficientPoleCoverage[r,Join[a,a],{{"A",{1}}}]&&
 !FeynFacet`Private`coefficientPoleCoverage[r,{Join[First[a],<|"PoleExpression"->1|>]},{{"A",{1}}}]];
FTAssert["a certificate missing a second removed divisor is rejected",
 MatchQ[SeparateMasterCoefficientPoles[ent,{pole,Join[pole,<|"PoleLabel"->"M2"|>]},req],
 Failure["CompleteResidualDivisorCertificateRequired",_]]];
FTAssert["a residue varying in the normal coordinate is rejected",
 MatchQ[SeparateMasterCoefficientPoles[ent,{Join[pole,<|"Residue"->z|>]},req],
 Failure["ExactSourcePoleResidueRequired",_]]];
d2=SeparateMasterCoefficientPoles[ent,{pole},Join[req,<|"ThroughOrder"->0|>]];
FTAssert["only requested finite orders are stored with a new remainder threshold",
 Keys[d2["RemainderEntry"]["Terms"][[1,"Coefficient","Orders"]]]==={0}&&
 d2["RemainderEntry"]["Terms"][[1,"LaurentRemainderClass","EpsilonOrderLowerBound"]]===1];
FTAssert["partial pole entries are distinguished from their full master coefficient",
 FeynFacet`Private`coefficientPoleCoverage[{}, {}, {}]&&
 !FeynFacet`Private`coefficientPoleCoverage[r,a,{}]];
FTReport[];
