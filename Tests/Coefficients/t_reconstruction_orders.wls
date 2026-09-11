Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;$HistoryLength=0;
Clear[e,z,v,m];tests=0;
check[label_,condition_]:=If[TrueQ[condition],tests++,Print["FAIL ",label];Exit[1]];
endpoint=<|"DataType"->"TangentialEndpointSystem","DimensionalRegulator"->e,"NormalVariable"->z,
 "Dimension"->1,"PrimarySectors"->{<|"Exponent"->-2e,"NilpotencyIndex"->1|>},
 "NormalGaugeMatrix"->{{z}},"OriginalMasterIntegralBasis"->{m}|>;
bounds=<|"DataType"->"TangentialEndpointLaurentBounds",
 "UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"-><|-2e->{0}|>|>;
req=<|"MasterRow"->1,"ThroughOrder"->0,"AliasNames"->{"aliasE","aliasZ","aliasV"},
 "AliasOriginals"-><|"aliasE"->e,"aliasZ"->z,"aliasV"->v|>,"KinematicRules"->{},
 "Assumptions"->0<v<1/3,"PreFactor"->1,"Source"->"test"|>;
inv[text_]:=<|"Divisors"->{StringReplace[text,{"e"->"aliasE","z"->"aliasZ","v"->"aliasV"}]},"Products"->{<|"Factors"->{{1,1}}|>}|>;
plan[text_,ep_:endpoint,b_:bounds,q_:req]:=FeynFacet`DetermineCoefficientReconstructionOrders[inv[text],ep,b,q];
a=plan["e^3*z^4*(1+e)*(v+z+e)"];
check["mixed unit and fixed pole",AssociationQ[a]&&a["RequiredCoefficientUpperOrder"]===1&&
 a["NormalPoleOrderUpperBound"]===4&&a["CoefficientLaurentLowerBound"]===-3&&
 a["LaurentRemainderClass"]["EpsilonOrderLowerBound"]===2];
check["source domain preserved",a["LaurentRemainderClass"]["Justification"]["TangentialAssumptions"]===req["Assumptions"]];
check["moving pole rejected",MatchQ[plan["z+e"],Failure["TangentialDivisorUnitNotEstablished",_]]];
check["tangential zero rejected",MatchQ[plan["v-1/4+z"],Failure["TangentialDivisorUnitNotEstablished",_]]];
check["prefactor pole",plan["z",endpoint,bounds,Append[req,"PreFactor"->e^-2]]["RequiredCoefficientUpperOrder"]===3];
ep=Append[endpoint,"PrimarySectors"->{<|"Exponent"->-2e,"NilpotencyIndex"->3|>}];
check["Jordan logarithm loss",plan["z",ep]["RequiredCoefficientUpperOrder"]===3];
ep=Join[endpoint,<|"PrimarySectors"->{<|"Exponent"->0,"NilpotencyIndex"->1|>},"NormalGaugeMatrix"->{{1}}|>];
b=Append[bounds,"UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"-><|0->{0}|>];
check["unregulated endpoint pole",MatchQ[plan["z",ep,b],Failure["ZeroSlopeCoefficientTailNeedsCancellation",_]]];
ep=Append[endpoint,"PrimarySectors"->{<|"Exponent"->1/2,"NilpotencyIndex"->1|>}];
b=Append[bounds,"UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"-><|1/2->{0}|>];
check["unsupported exponent rejected",MatchQ[plan["z",ep,b],Failure["LinearRegulatorPrimaryExponentsRequired",_]]];
check["normal prefactor not ignored",MatchQ[plan["e",endpoint,bounds,Append[req,"PreFactor"->1/z]],Failure["NormalDependentPrefactorNeedsTailAnalysis",_]]];
check["coordinate numerator cannot introduce an untracked pole",
 MatchQ[plan["e",endpoint,bounds,Append[req,"KinematicRules"->{v->1/(1-z)}]],
 Failure["PolynomialCoefficientCoordinateRulesRequired",_]]];
check["nonpolynomial coordinate map cannot bypass divisor analysis",
 MatchQ[plan["e",endpoint,bounds,Append[req,"KinematicRules"->{v->Sin[z]}]],
 Failure["PolynomialCoefficientCoordinateRulesRequired",_]]];
Print["RECONSTRUCTION ORDER TESTS PASS ",tests];
