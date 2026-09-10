
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
dir=root<>"/Projects/SIDIS_UU_NNLO/NNLO/q-q/Results/DoubleVirtual/OneLoopSquared";
source=FeynFacet`FamilyArtifactRead[dir<>"/IntegralFamilies.wl"];
reduction=FeynFacet`FamilyArtifactRead[dir<>"/Reduction.wl"];
family=First[source["Families"]];top=family["Topology"];
FTTest`FTAssert["mixed causal prescriptions are retained in the completed basis",
 MemberQ[family["OrdinaryPropagatorPrescriptions"],1]&&MemberQ[family["OrdinaryPropagatorPrescriptions"],-1]];
FTTest`FTAssert["complete affine inverse reproduces every denominator",
 AllTrue[MapThread[Factor[#1/.family["ScalarProductRules"]]-#2&,
  {family["InversePropagators"],family["DenominatorVariables"]}],Expand[#]===0&]];
renamed=family/.top[[1]]->testFamily;
targets=source["Targets"]/.top[[1]]->testFamily;
reused=FeynFacet`ReuseIntegralReduction[{renamed},targets,reduction];
FTTest`FTAssert["exact closed reduction is reused after renaming",
 AssociationQ[reused]&&reused["ReductionReuse"]["AllTargetsCovered"]&&Length[reused["Masters"]]===1];
wrong=Join[renamed,<|"MeasurePrefactor"->2|>];
FTTest`FTAssert["measure changes prevent reuse",
 FailureQ[FeynFacet`ReuseIntegralReduction[{wrong},targets,reduction]]];
wrong=Join[renamed,<|"OrdinaryPropagatorPrescriptions"->ConstantArray[1,Length[top[[2]]]]|>];
FTTest`FTAssert["prescription changes prevent reuse",
 FailureQ[FeynFacet`ReuseIntegralReduction[{wrong},targets,reduction]]];
FTTest`FTAssert["uncovered target is not called a master",
 FailureQ[FeynFacet`ReuseIntegralReduction[{renamed},Append[targets,FeynCalc`GLI[testFamily,ConstantArray[7,Length[top[[2]]]]]],reduction]]];
(* Check the generated one-loop square independently against the all-D
   bare form factor, hep-ph/0507061 equation (8). *)
born=FeynFacet`FamilyArtifactRead[root<>"/Projects/SIDIS_UU_NNLO/LO/q-q/Results/Result.wl"];
square=FeynFacet`FamilyArtifactRead[dir<>"/IntegratedScalarCoefficients.wl"];
e=Global`Epsilon;n=FeynCalc`CA;dd=4-2e;
f1=(n^2-1)/n (dd^2-7dd+16)/(2(dd-4));
tree=born["Coefficients"][0]["DeltaCoefficient"]["DeltaCoefficient"][[1]];
reference=-tree FeynFacet`\[Alpha]s^2 Exp[2EulerGamma e]muR2^(2e)/(16Pi^2) f1^2;
FTTest`FTAssert["generated square equals Born times absolute square of one-loop form factor",
 Factor[square["ExactScalarCoefficientMatrix"][[1,1]]-reference]===0&&
 square["ExactScalarCoefficientMatrix"][[2]]==={0}];
FTTest`FTReport[];
