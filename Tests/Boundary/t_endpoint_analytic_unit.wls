Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
request=<|"MaximumNormalOrder"->0,"AnalyticDomain"->"r,t>0",
 "BranchPrescription"->"Positive real coordinates"|>;
source=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->r,"TangentialVariable"->s,"DimensionalRegulator"->ee,
 "NormalConnectionMatrix"->{{ee/r}},"TangentialConnectionMatrix"->{{ee/s}}|>,request];
target=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->r,"TangentialVariable"->t,"DimensionalRegulator"->ee,
 "NormalConnectionMatrix"->{{ee/r}},"TangentialConnectionMatrix"->{{ee/(1+t)}}|>,request];
values=<|"Status"->"PhysicalEndpointBoundaryValuesDetermined","DimensionalRegulator"->ee,
 "MasterIntegralBasis"->source["OriginalMasterIntegralBasis"],"NormalExponent"->ee,
 "TangentialRegulatorExponent"->ee,"RationalCoefficientMatrix"->{{1}},
 "InitialConstantValues"->{1},"BoundaryConstantCount"->1|>;
mapped=FeynFacet`PullBackEndpointBoundaryValues[source,target,values,
 <|"TangentialImage"->1+t,"Assumptions"->t>0|>];
FTAssert["ordinary-point transfer retains the analytic regulator power",
 AssociationQ[mapped]&&mapped["TangentialAnalyticFactor"]===(1+t)^ee];
rows=<|"row"-><|First[source["OriginalMasterIntegralBasis"]]->1/r|>|>;
jets=FeynFacet`ConstructPhysicalEndpointCoefficientJets[target,mapped,rows,
 <|"DensityJacobian"->1,"IntegerOrderThrough"->-1|>];
FTAssert["physical jets use the analytic unit's full tangential connection",
 AssociationQ[jets]&&jets["CoefficientMatrices"][-1]==={{1}}&&
 jets["TangentialAnalyticFactor"]===(1+t)^ee];
bad=FeynFacet`ConstructPhysicalEndpointCoefficientJets[target,
 Join[mapped,<|"TangentialAnalyticLogDerivative"->0|>],rows,
 <|"DensityJacobian"->1,"IntegerOrderThrough"->-1|>];
FTAssert["dropping the analytic logarithmic derivative fails the equation",
 MatchQ[bad,Failure["PhysicalEndpointJetTangentialEquationMismatch",_]]];
ramified=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->r,"TangentialVariable"->u,"DimensionalRegulator"->ee,
 "NormalConnectionMatrix"->{{ee/r}},"TangentialConnectionMatrix"->{{2u ee/(1+u^2)}}|>,request];
twice=FeynFacet`PullBackEndpointBoundaryValues[target,ramified,mapped,
 <|"NormalUnitPower"->0,"TangentialPower"->2|>];
FTAssert["a second monomial transfer composes the analytic factor and derivative",
 AssociationQ[twice]&&twice["TangentialAnalyticFactor"]===(1+u^2)^ee&&
 Cancel[twice["TangentialAnalyticLogDerivative"]-2u ee/(1+u^2)]===0];
FTAssert["reciprocal analytic-unit continuation is not inferred from its old origin",
 MatchQ[FeynFacet`PullBackEndpointBoundaryValues[target,ramified,mapped,
  <|"NormalUnitPower"->0,"TangentialPower"->-1|>],
  Failure["AnalyticUnitAtReciprocalEndpointRequiresContinuation",_]]];
FTReport[];
