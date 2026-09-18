Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Module[{data,sub,body,bulk,faces,answer,expected,high,bad,finite,parameter=ee,xx=tx,yy=ty},
 data=<|"DataType"->"ResolvedOneLoopScalarEndpointPowers","DimensionalRegulator"->parameter,
  "NormalVariables"->{xx,yy},"CoefficientRowLabels"->{"Scalar"},"JointAnalyticFactorsVerified"->True,
  "Terms"->{<|"Row"->1,"Powers"->{-1-parameter,-1-2parameter},"SmoothFactor"->(1+xx)(1+yy)|>}|>;
 sub=FeynFacet`ConstructResolvedEndpointIntegralSubtractions[data];
 FTTest`FTAssert["overlapping endpoint poles produce exact faces and a corner with no deferred integrals",
  AssociationQ[sub]&&Length[sub["IntegratedStrata"]]===3&&FreeQ[sub,_Integrate|_Series|_SeriesData]];
 If[!AssociationQ[sub],Print[InputForm[sub]];Exit[1]];
 body=xx^(-1-parameter)yy^(-1-2parameter)(1+xx)(1+yy);
 bulk=FullSimplify[(body-sub["BulkSubtraction"]["Scalar"])/(xx^-parameter yy^(-2parameter)),
   Assumptions->xx>0&&yy>0&&Element[parameter,Reals]];
 FTTest`FTAssert["the complete double subtraction leaves the integrable mixed Taylor remainder",bulk===1];
 faces=Table[If[row["RemainingVariables"]==={},row["Values"]["Scalar"],
   Integrate[row["Values"]["Scalar"],Sequence@@({#,0,1}&/@row["RemainingVariables"]),
    Assumptions->-1<parameter<0,GenerateConditions->False]],{row,sub["IntegratedStrata"]}];
 answer=1/((1-parameter)(1-2parameter))+Total[faces];
 expected=(-1/parameter+1/(1-parameter))(-1/(2parameter)+1/(1-2parameter));
 FTTest`FTAssert["the subtracted integral equals the independently integrated product of Euler moments",
  Factor[answer-expected]===0];
 high=Join[data,<|"NormalVariables"->{xx},"Terms"->{<|"Row"->1,"Powers"->{-2-parameter},
    "SmoothFactor"->1+xx+xx^2|>}|>];
 sub=FeynFacet`ConstructResolvedEndpointIntegralSubtractions[high];
 FTTest`FTAssert["a stronger endpoint pole determines the first derivative subtraction automatically",
  AssociationQ[sub]&&First[sub["TaylorRequirements"]]["TaylorOrders"]===<|xx->1|>&&
   Factor[Total[#["Values"]["Scalar"]&/@sub["IntegratedStrata"]]+1/(1+parameter)+1/parameter]===0];
 bad=Join[data,<|"Terms"->{<|"Row"->1,"Powers"->{-1,-1-parameter},"SmoothFactor"->1|>}|>];
 FTTest`FTAssert["an unregulated singular face cannot be assigned a finite dimensionally continued integral",
  FailureQ[FeynFacet`ConstructResolvedEndpointIntegralSubtractions[bad]]];
 finite=Join[data,<|"Terms"->{<|"Row"->1,"Powers"->{0,1},"SmoothFactor"->1|>}|>];
 sub=FeynFacet`ConstructResolvedEndpointIntegralSubtractions[finite];
 FTTest`FTAssert["regular source terms acquire no artificial boundary contributions",
  sub["IntegratedStrata"]==={}&&Values[sub["BulkSubtraction"]]==={0}];
];
Print["ENDPOINT INTEGRAL SUBTRACTIONS TEST COMPLETE"];FTTest`FTReport[];
