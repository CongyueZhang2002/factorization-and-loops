Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Block[{Print},Get[root<>"/FeynFacet/Solution.m"]];
param=<|"DataType"->"RationalizingParametrization","SchemaVersion"->2,
 "SourceVariables"->{z},"ParametrizingVariables"->{u},
 "SourceVariableSubstitution"->{z->4u^2/(1+u^2)^2},
 "RationalizedSquareRoots"->{<|"SourceRadicand"->z,"RationalRoot"->2u/(1+u^2)|>,
  <|"SourceRadicand"->1-z,"RationalRoot"->(1-u^2)/(1+u^2)|>}|>;
v=FeynFacet`VerifyRationalizingParametrization[param];
FTTest`FTAssert["one-variable forward map verifies roots and nonzero Jacobian",
 TrueQ[v["Verified"]]&&Cancel[Together[v["JacobianDeterminant"]-8u(1-u^2)/(1+u^2)^3]]===0];
three=<|"DataType"->"RationalizingParametrization","SchemaVersion"->2,
 "SourceVariables"->{a,b,c},"ParametrizingVariables"->{x,y,z},
 "SourceVariableSubstitution"->{a->x+y,b->x-y,c->z},"RationalizedSquareRoots"->{}|>;
FTTest`FTAssert["dimension-independent Jacobian verification covers three variables",
 TrueQ[FeynFacet`VerifyRationalizingParametrization[three]["Verified"]]&&
 FeynFacet`VerifyRationalizingParametrization[three]["JacobianDeterminant"]===-2];
FTTest`FTAssert["mismatched dimensions and repeated source coordinates are refused",
 !TrueQ[FeynFacet`VerifyRationalizingParametrization[Join[param,<|"ParametrizingVariables"->{u,v}|>]]["Verified"]]&&
 !TrueQ[FeynFacet`VerifyRationalizingParametrization[Join[three,<|"SourceVariableSubstitution"->{a->x+y,a->x-y,c->z}|>]]["Verified"]]];
child=Join[param,<|"ParametrizingVariables"->{t},
 "SourceVariableSubstitution"->(param["SourceVariableSubstitution"]/.u->t/2),
 "RationalizedSquareRoots"->(param["RationalizedSquareRoots"]/.u->t/2),
 "ParentParametrizationMaps"-><|"Parent"->{u->t/2}|>,"ParentParametrizations"-><|"Parent"->param|>|>];
FTTest`FTAssert["parent compositions use the declared dimension",
 TrueQ[FeynFacet`VerifyRationalizingParametrization[child]["Verified"]]];
system=<|"KinematicVariables"->{z},"DimensionalRegulator"->e,
 "ConnectionMatrices"->{{{e/(z Sqrt[1-z])}}},"BasePoint"->{1/3},
 "BasisTransformationMatrix"->{{Sqrt[z]}},"InverseBasisTransformationMatrix"->{{1/Sqrt[z]}}|>;
pulled=FeynFacet`PullBackMasterIntegralDifferentialSystem[system,param,{Sqrt[3]-Sqrt[2]}];
FTTest`FTAssert["complete one-variable pullback fixes roots from the exact lifted basepoint",
 AssociationQ[pulled]&&pulled["KinematicVariables"]==={u}&&
 FullSimplify[pulled["RationalizingCoordinates"]["SourceBasePoint"]-{1/3}]==={0}&&
 Length[pulled["RationalizingCoordinates"]["RootBranches"]]===2&&
 Cancel[Together[pulled["ConnectionMatrices"][[1,1,1]]-2e/u]]===0&&
 Cancel[Together[pulled["BasisTransformationMatrix"][[1,1]]-2u/(1+u^2)]]===0&&
 Cancel[Together[pulled["InverseBasisTransformationMatrix"][[1,1]]-(1+u^2)/(2u)]]===0];
generated=FeynFacet`ConstructAffineRootPairParametrization[{z,1-z},z,u];
FTTest`FTAssert["affine conic construction derives a common root parametrization",
 AssociationQ[generated]&&TrueQ[generated["RationalizingParametrizationVerification"]["Verified"]]&&
 Cancel[Together[(z/.generated["SourceVariableSubstitution"])-4u^2/(1+u^2)^2]]===0&&
 FullSimplify[(generated["ParameterFromRootValues"]/.z->1/3)-(Sqrt[3]-Sqrt[2])]===0];
FTTest`FTAssert["an unavailable rational conic point makes no nonexistence claim",
 MatchQ[FeynFacet`ConstructAffineRootPairParametrization[{z,2-z},z,u],
  Failure["RationalConicPointNotFound",KeyValuePattern["RationalizabilityRuledOut"->False]]]];
Print["PARAMETRIZATION DIMENSIONS TEST COMPLETE"];FTTest`FTReport[];
