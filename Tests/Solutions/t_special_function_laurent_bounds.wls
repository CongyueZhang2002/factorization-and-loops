
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
FTAssert["Euler beta valuations use the exact gamma quotient",
 FeynFacet`DetermineLaurentValuation[Beta[-be,-be],be]===-1&&
 FeynFacet`DetermineLaurentValuation[1/Beta[-be,-be],be]===1];
FTAssert["coincident beta poles and a nonlinear denominator shift are counted",
 FeynFacet`DetermineLaurentValuation[Beta[be,-be+be^2],be]===0];
(* The n=0 term is one; the large-n tail contributes (-epsilon)/(-2epsilon)=1/2. *)
critical=HypergeometricPFQ[{1,1,-be},{1-2be,1-be},1];
expansion=FeynFacet`ExpandHypergeometricLaurentSeries[critical,be,0];
FTAssert["critical unit-argument continuation precedes regulator substitution",
 AssociationQ[expansion]&&expansion["Polynomial"]===3/2&&
 FeynFacet`DetermineLaurentValuation[critical,be]===0];
FTAssert["a beta and hypergeometric product has a finite sufficient pole bound",
 FeynFacet`DetermineMeromorphicLaurentLowerBound[Beta[-be,1-be]critical Gamma[-be]^2/
  (Beta[1-be,1-be]Gamma[-2be]),be]===-2];
FTReport[];
