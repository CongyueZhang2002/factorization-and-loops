
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/Tests/TestKit.wl"];
positive[p_,closed_]:=FeynFacet`Private`epsOrderBernsteinPositiveQ[p,{x,y},closed];
FTAssert["mixed monomial coefficients can certify strict closed-cube positivity",positive[1+x(1-y)+y(1-x),True]];
FTAssert["open-cube positivity allows a lower endpoint zero",positive[x+y-x y,False]];
FTAssert["closed-cube positivity rejects that endpoint zero",!positive[x+y-x y,True]];
FTAssert["an interior zero is never certified as strictly positive",!positive[(x-1/2)^2+(y-1/2)^2,False]];
FTAssert["a polynomial changing sign is not certified",!positive[1-2x,False]];

pairEuler=<|"Representation"->"UnitCube","DimensionalRegulator"->ee,
 "Terms"->{<|"IntegrationVariables"->{x,y},"EndpointPowers"->{ee-1,ee-1},
 "UpperEndpointPowers"->{2ee-1,0},
 "PolynomialFactors"->{<|"Polynomial"->1-x y,"Exponent"->ee-1|>}|>}|>;
bound=FeynFacet`DetermineIntegralLaurentBound[pairEuler];
FTAssert["a polynomial upper-face zero is resolved even with no upper monomial",
 AssociationQ[bound]&&bound["LowerBound"]===-2];
FTReport[];

