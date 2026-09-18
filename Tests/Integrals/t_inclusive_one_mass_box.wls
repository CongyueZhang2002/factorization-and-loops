Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Module[{phase,prop,source,data,family,master,value,normalized,normalValue,wrong,wrongValue},
 phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->inclusiveBoxTest,
  "FinalMomenta"->{ip1,ip2,ip3},"TotalMomentum"->iq,"ExternalMomenta"->{iq},
  "KinematicRules"->{FeynCalc`SPD[iq]->is},"Assumptions"->is>0|>];
 prop[p_]:=FeynCalc`FCI[FeynCalc`SFAD[p]];
 source=Times@@(prop/@{il,il-ip1,il-ip1-ip3,il-iq,ip1+ip2});
 data=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->source|>,phase,{il},<|"FamilyNamePrefix"->"BoxPhaseTest"|>];
 family=First[data["Families"]];master=First[data["Targets"]];
 value=FeynFacet`EvaluateOneLoopPhaseSpaceBox[family,master,ie,{-4,0}];
 FTTest`FTAssert["the inclusive box requires and retains an exact causal momentum-map witness",
  AssociationQ[value]&&value["ReferenceMomentumMap"]["Source"]===master&&value["KnownThroughOrder"]===0];
 If[!AssociationQ[value],Print[InputForm[value]];Exit[1]];
 FTTest`FTAssert["the raw loop conversion gives the expected leading scalar pole",
  Factor[value["Coefficients"][-4]-5I/(256Pi is^2)]===0];
 FTTest`FTAssert["the absorptive phase survives before Hermitian amplitude completion",
  FullSimplify[ComplexExpand[Re[value["Coefficients"][-3]/.is->1]]]+5/256===0];
 normalized=Join[family,<|"MeasurePrefactor"->family["MeasurePrefactor"]/(I Pi^(D/2))|>];
 normalValue=FeynFacet`EvaluateOneLoopPhaseSpaceBox[normalized,master,ie,{-4,-4}];
 FTTest`FTAssert["an already normalized loop does not acquire the conversion twice",
  AssociationQ[normalValue]&&Factor[normalValue["Coefficients"][-4]-5/(256Pi^3 is^2)]===0];
 FTTest`FTAssert["unavailable positive universal orders are rejected explicitly",
  MatchQ[FeynFacet`EvaluateOneLoopPhaseSpaceBox[family,master,ie,{-4,1}],
   Failure["UniversalInclusiveBoxOrderNotAvailable",_]]];
 FTTest`FTAssert["a normalization pole increases the required universal order",
  MatchQ[FeynFacet`EvaluateOneLoopPhaseSpaceBox[Join[family,<|"MeasurePrefactor"->family["MeasurePrefactor"]/ie|>],master,ie,{-5,0}],
   Failure["UniversalInclusiveBoxOrderNotAvailable",_]]];
 wrong=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->Times@@(prop/@{il,il-ip1,il-ip1-ip3,il-iq,ip1+ip3})|>,
   phase,{il},<|"FamilyNamePrefix"->"DifferentBoxPhaseTest"|>];
 wrongValue=FeynFacet`EvaluateOneLoopPhaseSpaceBox[First[wrong["Families"]],First[wrong["Targets"]],ie,{-4,0}];
 FTTest`FTAssert["a different external invariant cannot be assigned the universal box by denominator count alone",
  MatchQ[wrongValue,Failure["UniversalInclusiveBoxMomentumMapNotEstablished",_]]];
];
Print["INCLUSIVE ONE MASS BOX TEST COMPLETE"];FTTest`FTReport[];
