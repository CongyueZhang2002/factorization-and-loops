Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
r=FeynFacet`RegularAnalyticLimit[(Log[x/z]-(x-z)/z)/(x-z)^2,x->z,x>0&&z>0];
FTTest`FTAssert["rational pole cancellation leaves an exact logarithmic limit",AssociationQ[r]&&Cancel[Together[r["Value"]+1/(2z^2)]]===0&&TrueQ[r["PrincipalPartsVerified"]]];
r=FeynFacet`RegularAnalyticLimit[(PolyLog[2,(x-z)/z]-(x-z)/z)/(x-z)^2,x->z,z>0&&0<x<2z];
FTTest`FTAssert["the dilogarithm is expanded only as deep as the rational pole requires",AssociationQ[r]&&Cancel[Together[r["Value"]-1/(4z^2)]]===0&&r["PoleOrder"]===2];
r=FeynFacet`RegularAnalyticLimit[(Log[Abs[x-z]^2]-2Log[Abs[x-z]])/(x-z)^2,x->z,z>0];
FTTest`FTAssert["logarithmic terms cancel on both real approaches",AssociationQ[r]&&r["Value"]===0];
FTTest`FTAssert["a genuine pole is rejected",FailureQ[FeynFacet`RegularAnalyticLimit[1/(x-z),x->z,z>0]]];
FTTest`FTAssert["different one-sided values are rejected",FailureQ[FeynFacet`RegularAnalyticLimit[Abs[x-z]/(x-z),x->z,z>0]]];
r=FeynFacet`RegularAnalyticLimit[(Log[z]-Log[1-z])/(2z-1) Sin[x-z]/(x-z),x->z,0<z<1&&0<x<1];
FTTest`FTAssert["a rational exceptional point of the returned limit is discovered and filled",
 AssociationQ[r]&&Quiet[r["Value"]/.z->1/2]===2&&Length[r["AdditionalRemovablePoints"]]===1];
Print["REGULAR ANALYTIC LIMIT TEST COMPLETE"];FTTest`FTReport[];
