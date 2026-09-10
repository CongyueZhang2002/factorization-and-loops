$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
cases={1/(1-x)+1/(1-y),1/(1-x)^2/(1-x)^3,((1-x)/(1+y))^-2,
 ((a+x)/(1-y)+(b+x)/(1-y)^2)/(1-x),c/(1-x)+d/(1-x)^2};
Do[
 record=FeynFacet`CommonKinematicDenominator[{expr},{x,y}];den=record["CommonDenominator"];
 FTAssert["the structural denominator clears example "<>ToString[i],
  AssociationQ[record]&&PolynomialQ[den,{x,y}]&&PolynomialQ[Cancel[Together[den expr]],{x,y}]],
 {i,Length[cases]},{expr,{cases[[i]]}}];
FTAssert["product factors add their multiplicities",
 Cancel[FeynFacet`CommonKinematicDenominator[{cases[[2]]},{x,y}]["CommonDenominator"]/(1-x)^5]===-1||
 Cancel[FeynFacet`CommonKinematicDenominator[{cases[[2]]},{x,y}]["CommonDenominator"]/(1-x)^5]===1];
FTReport[];
