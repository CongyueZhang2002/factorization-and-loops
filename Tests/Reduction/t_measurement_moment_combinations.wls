Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
{i1,i2,ix,u1,u2,u3}=FeynCalc`GLI[MomentRelations,{#}]&/@Range[6];
(* This fixture tests the linear selector, not a physical convergence proof. *)
fixture=<|"Topology"->FeynCalc`FCTopology[MomentRelations,{FeynCalc`SFAD[ell]},
  {ell},{},{},{}],"Cuts"->{},"MeasurePrefactor"->1|>;
make[expr_,inclusive_]:=<|"Format"->"FeynFacet-PolynomialMeasurementMoment",
 "CommonConvergenceDomainExists"->True,"Variable"->z,"DimensionalRegulator"->e,
 "Interval"->{0,1},"ParameterConditions"->s>0,"Weight"->1,
 "MeasuredIntegrals"->expr,"UnmeasuredIntegrals"->inclusive,
 "MeasuredFamily"->fixture,"UnmeasuredFamily"->fixture|>;
records={make[i1+z ix,u1],make[i2+2z ix,u2],make[z i1+ix,u3]};
reduction=<|"Masters"->{i1,i2},"Rules"->{},"Families"->{fixture}|>;
result=FeynFacet`ReduceMeasurementMomentCombinations[records,reduction];
If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
FTTest`FTAssert["only measurement-independent cancellations of uncovered integrals survive",
 Length[result["MomentRows"]]===1&&result["UncoveredIntegrals"]==={ix}&&
 First[result["MomentRows"]]["MeasuredMasterCoefficients"]==={-2,1}&&
 First[result["MomentRows"]]["UnmeasuredIntegrals"]===-2u1+u2];
rational=FeynFacet`ReduceMeasurementMomentCombinations[
 {make[i1+(z+e)/(1+z)ix,u1],make[i2+3(z+e)/(1+z)ix,u2]},reduction];
FTTest`FTAssert["rational measurement denominators are cleared before the exact kernel",
 AssociationQ[rational]&&Length[rational["MomentRows"]]===1&&
 With[{row=First[rational["MomentRows"]]["MeasuredMasterCoefficients"]},
  Last[row]=!=0&&Cancel[First[row]+3Last[row]]===0]];
If[!AssociationQ[rational],Print[InputForm[rational]]];
FTTest`FTAssert["zero coefficients disappear before coverage is counted",
 Length[FeynFacet`ReduceMeasurementMomentCombinations[
 {make[i1+(z^2-1)/(z-1)ix-(z+1)ix,u1]},reduction]["MomentRows"]]===1];
FTTest`FTAssert["an empty covered combination space remains explicit",
 FeynFacet`ReduceMeasurementMomentCombinations[{make[i1+ix,u1]},reduction]["MomentRows"]==={}];
FTTest`FTAssert["inconsistent intervals and incomplete exact reduction rules are rejected",
 FailureQ[FeynFacet`ReduceMeasurementMomentCombinations[{First[records],Join[Last[records],<|"Interval"->{0,2}|>]},reduction]]&&
 FailureQ[FeynFacet`ReduceMeasurementMomentCombinations[records,Join[reduction,<|"Rules"->{u3->i1+ix}|>]]]];
FTTest`FTAssert["integral identities do not assert solved moments or physical-constant rank",
 !result["MomentValuesEvaluated"]&&!result["PhysicalConstantRankEstablished"]&&!result["NewIBPEquationsGenerated"]];
FTTest`FTAssert["identical integral names cannot hide different physical definitions",
 FailureQ[FeynFacet`ReduceMeasurementMomentCombinations[records,
  Join[reduction,<|"Families"->{Join[fixture,<|"MeasurePrefactor"->2|>]}|>]]]];
FTTest`FTAssert["approximate coefficients are rejected even without outside-span columns",
 FailureQ[FeynFacet`ReduceMeasurementMomentCombinations[{make[i1+0.1i2,u1]},reduction]]&&
 FailureQ[FeynFacet`ReduceMeasurementMomentCombinations[{make[i1,0.1u1]},reduction]]&&
 FailureQ[FeynFacet`ReduceMeasurementMomentCombinations[{make[ix,u1]},
  Join[reduction,<|"Rules"->{ix->i1+0.1i2}|>]]]];
weighted=FeynFacet`ReduceMeasurementMomentCombinations[
 {make[i1+z ix,u1],Join[make[i2+2ix,u2],<|"Weight"->z|>]},reduction];
FTTest`FTAssert["unequal measured weights are not applied a second time to inclusive values",
 AssociationQ[weighted]&&First[weighted["MomentRows"]]["MeasuredMasterCoefficients"]==={-2,z}&&
 First[weighted["MomentRows"]]["UnmeasuredIntegrals"]===-2u1+u2];
FTTest`FTAssert["the exact supplied reduction and family catalogue remain attached",
 AllTrue[Keys[reduction],result["ReductionInput"][#]===reduction[#]&]&&
 StringQ[result["ExactnessScope"]]];
Print["MEASUREMENT MOMENT COMBINATIONS TEST COMPLETE"];FTTest`FTReport[];
