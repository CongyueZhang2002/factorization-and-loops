Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Physics/Measurements.wl"];
pm=FeynFacet`CompileMeasurement[<|"Observable"->q2 c/(2 a b),"Value"->z,
 "IntegrationVariables"->{a,b,c},"Assumptions"->a>0&&b>0&&q2>0&&Element[{c,z},Reals]|>];
FTTest`FTAssert["rational quadratic measurement retains its integration-dependent Jacobian",
 AssociationQ[pm]&&pm["PolynomialDegree"]===2&&pm["Jacobian"]===2 a b&&
 Expand[pm["CutPolynomial"]-(2 a b z-q2 c)]===0];
FTTest`FTAssert["the original unit-cut constraint is recovered exactly",
 Cancel[Together[pm["CutPolynomial"]/pm["Jacobian"]-z+q2 c/(2 a b)]]===0];
negative=FeynFacet`CompileMeasurement[<|"Observable"->c/a,"Value"->z,
 "IntegrationVariables"->{a,c},"Assumptions"->a<0&&Element[{c,z},Reals]|>];
FTTest`FTAssert["a negative rational denominator gets an absolute Jacobian",
 AssociationQ[negative]&&negative["Jacobian"]===-a];
FTTest`FTAssert["unknown denominator sign is rejected",
 FailureQ[FeynFacet`CompileMeasurement[<|"Observable"->c/a,"Value"->z,
 "IntegrationVariables"->{a,c},"Assumptions"->Element[{a,c,z},Reals]|>]]];
contact=FeynFacet`CompileMeasurement[<|"Observable"->0,"Value"->z,
 "IntegrationVariables"->{a,b},"Assumptions"->Element[z,Reals]|>];
FTTest`FTAssert["constant observables are recorded as contacts, never zero integral denominators",
 AssociationQ[contact]&&contact["Kind"]==="Contact"&&contact["CutPolynomial"]===z];
FTTest`FTAssert["cubic measurements fail explicitly",
 FailureQ[FeynFacet`CompileMeasurement[<|"Observable"->a^3,"Value"->z,
 "IntegrationVariables"->{a},"Assumptions"->Element[{a,z},Reals]|>]]];
spec=<|"Arguments"->{aa,bb},"Variable"->z,"Observable"->(aa-bb)^2,
 "Weight"->aa bb,"Tuples"-><|"Ordered"->True,"IncludeRepeated"->True|>|>;
terms=FeynFacet`FinalStateMeasurementTerms[spec,{p1,p2,p3}];
FTTest`FTAssert["ordered pair enumeration retains all three self-correlations",
 Length[terms]===9&&Count[Lookup[terms,"Observable"],0]===3];
un=FeynFacet`FinalStateMeasurementTerms[Join[spec,<|"Tuples"-><|"Ordered"->False,"IncludeRepeated"->False|>|>],{p1,p2,p3}];
FTTest`FTAssert["unordered pairs are counted once without an implicit factor of two",Length[un]===3];
Print["POLYNOMIAL MEASUREMENT TEST COMPLETE"];
FTTest`FTReport[];
