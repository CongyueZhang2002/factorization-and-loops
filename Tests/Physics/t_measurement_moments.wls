Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
specification=<|"Arguments"->{ma,mb},"Variable"->mz,
 "Observable"->ms FeynCalc`SPD[ma,mb]/(2 FeynCalc`SPD[mq,ma]FeynCalc`SPD[mq,mb]),
 "Weight"->FeynCalc`SPD[mq,ma]FeynCalc`SPD[mq,mb]/ms^2,
 "Tuples"-><|"Ordered"->True,"IncludeRepeated"->True|>|>;
geometry[n_]:=<|"Name"->momentSource,"FinalMomenta"->Take[{mk1,mk2,mk3,mk4},n],
 "TotalMomentum"->mq,"ExternalMomenta"->{mq},"KinematicRules"->{FeynCalc`SPD[mq]->ms},"Assumptions"->ms>0|>;
Do[moments=FeynFacet`ConstructFinalStateMeasurementMoments[geometry[n],specification,{0,1,2}];
 FTTest`FTAssert["card weights derive energy moments for "<>ToString[n]<>" particles in generic dimension",
  AssociationQ[moments]&&moments["ConstantWeights"][0]===1&&moments["ConstantWeights"][1]===1/2&&
  moments["TupleCount"]===n^2&&!moments["InclusiveRateEvaluated"]];
 If[!AssociationQ[moments],Print[InputForm[moments]]],{n,2,4}];
unordered=FeynFacet`ConstructFinalStateMeasurementMoments[geometry[3],Join[specification,
 <|"Tuples"-><|"Ordered"->False,"IncludeRepeated"->False|>|>],{0,1}];
FTTest`FTAssert["different tuple conventions change the derived moment instead of using a fixed factor",
 AssociationQ[unordered]&&unordered["TupleCount"]===3&&unordered["ConstantWeights"][1]===1/4&&
 !KeyExistsQ[unordered["ConstantWeights"],0]];
constant=FeynFacet`ConstructFinalStateMeasurementMoments[geometry[3],
 Join[specification,<|"Observable"->2,"Weight"->1|>],{0,1}];
FTTest`FTAssert["general constant measurements retain the explicitly generated tuple multiplicity",
 AssociationQ[constant]&&constant["InclusiveWeights"]===<|0->9,1->18|>];
FTTest`FTAssert["negative moment orders cannot introduce unanalysed measurement poles",
 FailureQ[FeynFacet`ConstructFinalStateMeasurementMoments[geometry[3],specification,{-1}]]];
Print["MEASUREMENT MOMENTS TEST COMPLETE"];FTTest`FTReport[];
