$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
miRequest=<|"Name"->MeasuredSource,"FinalMomenta"->{miK1,miK2,miK3},
 "TotalMomentum"->miP+miQ,"ExternalMomenta"->{miP,miQ},
 "KinematicRules"->FeynCalc`FCI[{FeynCalc`SPD[miP]->0,FeynCalc`SPD[miQ]->-miS,
  FeynCalc`SPD[miP,miQ]->miS/(2miX)}],
 "ReferenceMomentum"->miP,"TaggedMomentum"->miK1,"MeasurementVariable"->miZ,
 "Assumptions"->miS>0&&0<miX<1&&0<miZ<1|>;
miDefinition=FeynFacet`CreateMeasuredPhaseSpaceDefinition[miRequest];
miSource=FeynCalc`FCI[(1+FeynCalc`SPD[miK1,miK2]^2)*
 FeynCalc`SFAD[miP-miK2]*FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[miP-miK2,D],0,0,{1,-1}]]/
 FeynCalc`SPD[miP+miQ,miK2]^2+FeynCalc`SFAD[miK1+miK2]];
miPrepared=FeynFacet`PrepareMeasuredCutIntegrand[miSource,miDefinition,
 <|"ExternalKinematicConditions"->miS>0&&0<miX<1|>];
If[FailureQ[miPrepared],Print[miPrepared]];
FTTest`FTAssert["a source with opposite prescriptions is certified before combining its cores",
 AssociationQ[miPrepared]&&miPrepared["OrdinaryPrescriptionCertificate"]["OrdinaryPrescriptionRemoved"]===True];
If[AssociationQ[miPrepared],
 FTTest`FTAssert["gauge denominators and repeated powers remain explicit",
 Sort[miPrepared["OrdinaryPowerBounds"]]==={1,2,2}&&Length[miPrepared["FreeScalarProductVariables"]]===3];
 miExplicit=FeynCalc`FeynAmpDenominatorExplicit[miSource];
 miLeft=(FeynCalc`ExpandScalarProduct[miExplicit]/.miDefinition["Topology"][[5]])/.
  Reverse/@miPrepared["ScalarProductVariables"]/.miPrepared["UnitCutRules"];
 miRight=Total[(#["Numerator"]Times@@(miPrepared["OrdinaryUnitCutPolynomials"]^(-#["Powers"])))&/@miPrepared["Terms"]];
 FTTest`FTAssert["the prepared rational integrand equals the source on all unit cuts",
  Cancel[Together[miLeft-miRight]]===0];
 FTTest`FTAssert["the unrestricted denominator definitions remain available for differentiation",
  !FreeQ[miPrepared["SourceDefinition"]["InversePropagators"],FeynCalc`FCI[FeynCalc`SPD[miK1]]]]];
miDecomposed=FeynFacet`DecomposeMeasuredCutIntegrand[miPrepared,
 <|"ExternalKinematicConditions"->miS>0&&0<miX<1|>];
If[FailureQ[miDecomposed],Print[miDecomposed]];
FTTest`FTAssert["explicit GLI coefficients and complete off-shell families are generated",
 AssociationQ[miDecomposed]&&Length[miDecomposed["Targets"]]>0&&
 AllTrue[miDecomposed["Families"],#["Format"]==="FeynFacet-CutIntegralFamily"&]];
If[AssociationQ[miDecomposed],
 FTTest`FTAssert["integral coefficients contain no loop coordinates or inverse propagators",
  FreeQ[Values[miDecomposed["Coefficients"]],
   Alternatives@@Join[First/@miPrepared["ScalarProductVariables"],
    Flatten[Lookup[miDecomposed["Families"],"DenominatorVariables"]],
    {FeynCalc`Pair,FeynCalc`Momentum}]]];
 FTTest`FTAssert["nonconstant numerator becomes shifted integral powers",
  AnyTrue[miDecomposed["Targets"],AnyTrue[#[[2]],#<0&]&]];
 miFamilyByName=Association[(#["Topology"][[1]]->#)&/@miDecomposed["Families"]];
 miGLIValue[miG_FeynCalc`GLI]:=With[{family=miFamilyByName[miG[[1]]]},
  Times@@(Drop[family["InversePropagators"],4]^(-Drop[miG[[2]],4]))];
 miReconstructed=Total[KeyValueMap[miGLIValue[#1]#2&,miDecomposed["Coefficients"]]];
 miReconstructed=miReconstructed/.Reverse/@miPrepared["ScalarProductVariables"]/.miPrepared["UnitCutRules"];
 FTTest`FTAssert["family numerator conversion preserves the complete rational source",
  Cancel[Together[miReconstructed-miRight]]===0]];
miDependentSource=Times@@(FeynCalc`FCI[FeynCalc`SFAD[miP-#]]&/@{miK1,miK2,miK3});
miDependent=FeynFacet`PrepareMeasuredCutIntegrand[miDependentSource,miDefinition,
 <|"ExternalKinematicConditions"->miS>0&&0<miX<1|>];
miPartial=FeynFacet`DecomposeMeasuredCutIntegrand[miDependent,<|
 "ExternalKinematicConditions"->miS>0&&0<miX<1,"FamilyNamePrefix"->"DependentMeasurement"|>];
If[FailureQ[miPartial],Print[miPartial]];
FTTest`FTAssert["linearly dependent measured fractions produce valid independent families",
 AssociationQ[miPartial]&&Length[miPartial["Families"]]===2&&
 AllTrue[miPartial["Families"],Length[#["SourceOrdinaryIndices"]]===1&]];
If[AssociationQ[miDecomposed],
 miMixedFamily=First[miDecomposed["Families"]];
 miMixedTop=ReplacePart[miMixedFamily["Topology"],{2,5}->(miMixedFamily["Topology"][[2,5]]/.
  FeynCalc`StandardPropagatorDenominator[a_,b_,c_,{n_,eta_}]:>
   FeynCalc`StandardPropagatorDenominator[a,b,c,{n,-eta}])];
 miMixed=FeynFacet`CreateCutIntegralFamily[Join[miMixedFamily,<|"Topology"->miMixedTop|>]];
 FTTest`FTAssert["basis completeness does not require equal causal prescriptions",
  AssociationQ[miMixed]&&MemberQ[miMixed["OrdinaryPropagatorPrescriptions"],-1]&&
  miMixed["OrdinaryPrescriptionLimitEstablished"]===False]];
If[AssociationQ[miDecomposed],
 miRenaming=MapIndexed[#1["Topology"][[1]]->Symbol["Global`RenamedMeasured"<>ToString[First[#2]]]&,miDecomposed["Families"]];
 miClone=miDecomposed/.miRenaming;
 AssociateTo[miClone,"Coefficients"->Association[Normal[miDecomposed["Coefficients"]]/.miRenaming]];
 miMerged=FeynFacet`MergeCutIntegralDecompositions[<|"First"->miDecomposed,"Second"->miClone|>];
 If[FailureQ[miMerged],Print[miMerged],Print["MERGE COUNTS ",
  {Length[miMerged["Families"]],Length[miDecomposed["Families"]]},
  " COEFFICIENTS ",miMerged["Coefficients"]["First"]===miMerged["Coefficients"]["Second"],
  " TARGETS ",miMerged["Targets"]===Sort[miDecomposed["Targets"]]]];
 FTTest`FTAssert["identical typed definitions share one reduction between scalar structures",
  AssociationQ[miMerged]&&Length[miMerged["Families"]]===Length[miDecomposed["Families"]]&&
  miMerged["Coefficients"]["First"]===miMerged["Coefficients"]["Second"]&&
  miMerged["Targets"]===Sort[miDecomposed["Targets"]]]];

If[AssociationQ[miDecomposed],
 miLocal=miDecomposed;
 miScaledFirst=Join[First[miLocal["Families"]],<|
  "MeasurePrefactor"->2First[miLocal["Families"]]["MeasurePrefactor"]|>];
 AssociateTo[miLocal,"Families"->ReplacePart[miLocal["Families"],1->miScaledFirst]];
 miDistinct=FeynFacet`MergeCutIntegralDecompositions[<|"First"->miDecomposed,"SeparateInput"->miLocal|>];
 FTTest`FTAssert["source-local family names cannot merge different normalized measures",
  AssociationQ[miDistinct]&&Length[miDistinct["Families"]]===1+Length[miDecomposed["Families"]]&&
  DuplicateFreeQ[(#["Topology"][[1]]&/@miDistinct["Families"])]];
];


miCheckpoint=None;
miAgain=FeynFacet`DecomposeMeasuredCutIntegrand[miPrepared,
 <|"CoefficientCheckpointFunction"->Function[data,miCheckpoint=data]|>];
miFinished=FeynFacet`SimplifyMeasuredIntegralDecomposition[miCheckpoint];
FTTest`FTAssert["checkpoint completion retains the exact integral map",
 AssociationQ[miCheckpoint]&&!miCheckpoint["CoefficientCancellationComplete"]&&
 AssociationQ[miFinished]&&miFinished===miAgain];
FTTest`FTAssert["an unfinished coefficient checkpoint cannot enter reduction",
 FailureQ[FeynFacet`MergeCutIntegralDecompositions[<|"Unfinished"->miCheckpoint|>]]];
FTTest`FTAssert["changed generated-process charges require regeneration",
 FeynFacet`RequireMatchingProcessDefinition[<|"ProcessDefinition"-><|"Charges"->{qu,qd}|>|>,<|"Charges"->{qu,qd}|>]===True&&
 FailureQ[FeynFacet`RequireMatchingProcessDefinition[<|"ProcessDefinition"-><|"Charges"->{2/3,-1/3}|>|>,<|"Charges"->{qu,qd}|>]]];
FTTest`FTReport[];
