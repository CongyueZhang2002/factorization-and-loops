Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Solution.m"];
Clear[x,t];f=FeynFacetSolution`F;k=FeynFacetSolution`K;
data=<|"KinematicVariables"->{x},"BasePoint"->{1/2},"RequestedRows"->{1},
 "Path"-><|"Parameter"->t,"Coordinates"->{1/2+t(x-1/2)}|>,
 "KernelDefinitions"->{<|"Index"->1,"Parameter"->t,"Expression"->(x-1/2)/(1/2-t(x-1/2))|>},
 "IntegralDefinitions"->{
  <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t]|>,
  <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->k[1,t]f[1,t]|>},
 "AlgebraicDefinitions"->{},"Coefficients"-><|0->{1->{1}},1->{1->{f[1,1]}},2->{1->{f[2,1]}}|>|>;
right=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data,
 "Assumptions"->1/2<x<1,"RescalePathParameter"->True];
If[!AssociationQ[right],Print[InputForm[right]];Exit[1]];
FTAssert["one-dimensional path rescaling leaves the finite solution unchanged",
 KeyDrop[right,{"GPLRepresentation"}]===data&&
 right["GPLRepresentation"]["Status"]==="RequiredIntegralsConvertedToGPL"&&
 right["GPLRepresentation"]["PathParameterScale"]===x-1/2];
words=Cases[Values[right["GPLRepresentation"]["IntegralExpressions"]],
 FeynFacetSolution`G[w_List,_]:>w,Infinity];
FTAssert["nested GPLs have an endpoint-independent alphabet",Length[words]>0&&FreeQ[words,x]];
nr=FeynFacetSolution`EvaluateMasterIntegralSolution[right,{3/4},"NumericalBackend"->"GiNaC",
 "AccuracyGoal"->25,"PrecisionGoal"->25];
FTAssert["rightward nested integration agrees with its elementary value",
 AssociationQ[nr]&&Abs[nr["EpsilonCoefficients"][2][[1,1]]-N[Log[2]^2/2,60]]<10^-25];
left=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data,
 "Assumptions"->0<x<1/2,"RescalePathParameter"->True];
nl=FeynFacetSolution`EvaluateMasterIntegralSolution[left,{1/4},"NumericalBackend"->"GiNaC",
 "AccuracyGoal"->25,"PrecisionGoal"->25];
FTAssert["leftward paths retain their sign under a positive parameter scale",
 AssociationQ[nl]&&left["GPLRepresentation"]["PathParameterScale"]===1/2-x&&
 Abs[nl["EpsilonCoefficients"][1][[1,1]]-N[Log[2/3],60]]<10^-25&&
 Abs[nl["EpsilonCoefficients"][2][[1,1]]-N[Log[2/3]^2/2,60]]<10^-25];
FTAssert["a conversion cannot be evaluated on the opposite scale domain",
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[right,{1/4},"NumericalBackend"->"GiNaC"],
  Failure["GPLPathRescalingDomainNotEstablished",_]]];
reused=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[right,
 "Assumptions"->1/2<x<1,"RescalePathParameter"->False];
FTAssert["changing the rescaling policy cannot discard reused expression domains",
 reused["GPLRepresentation"]["ReusedIntegralExpressions"]===2&&
 MatchQ[FeynFacetSolution`EvaluateMasterIntegralSolution[reused,{1/4},"NumericalBackend"->"GiNaC"],
  Failure["GPLConversionAssumptionsNotEstablished",_]]];
base=FeynFacetSolution`EvaluateMasterIntegralSolution[right,{1/2},"NumericalBackend"->"GiNaC"];
FTAssert["the stationary path uses its original exact value",
 AssociationQ[base]&&Flatten[Values[base["EpsilonCoefficients"]]]=={1,0,0}];
FTAssert["unresolved sign and nonlinear paths cannot be forced into the rescaling",
 FailureQ[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[data,"RescalePathParameter"->True]]&&
 FailureQ[FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[
  Join[data,<|"Path"-><|"Parameter"->t,"Coordinates"->{1/2+t^2(x-1/2)}|>|>],
  "Assumptions"->x>1/2,"RescalePathParameter"->True]]];
Do[
 {integrand,expected}=row;
 tangent=Join[data,<|"KernelDefinitions"->{},"IntegralDefinitions"->{
   <|"IntegrationVariable"->t,"LowerLimit"->0,"Integrand"->integrand|>},
   "Coefficients"-><|0->{1->{f[1,1]}}|>|>];
 Do[
  {assumptions,point}=side;
  value=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[tangent,
   "Assumptions"->assumptions,"RescalePathParameter"->True];
  value=FeynFacetSolution`EvaluateGPLExpression[
    First[Values[value["GPLRepresentation"]["IntegralExpressions"]]]/.
      value["GPLRepresentation"]["Parameter"]->1,{x->point},"WorkingPrecision"->60];
  FTAssert["tangential logarithm constants survive "<>ToString[InputForm[integrand]]<>
    " at "<>ToString[point],NumberQ[value]&&Abs[value-N[expected,60]]<10^-25],
  {side,{{1/2<x<1,3/4},{0<x<1/2,1/4}}}],
 {row,{{Log[t],-1},{FeynFacetSolution`G[{2,0},t],1-PolyLog[2,1/2]}}}];
boundaryData=Join[KeyDrop[data,{"BasePoint"}],<|
 "Path"-><|"Parameter"->t,"Coordinates"->{t x}|>,
 "KernelDefinitions"->{<|"Index"->1,"Parameter"->t,"Expression"->x/(1-x t)|>}|>];
boundaryGPL=FeynFacetSolution`ConvertMasterIntegralSolutionToGPL[boundaryData,
 "Assumptions"->0<x<1,"RescalePathParameter"->True];
FTAssert["a boundary path origin permits rescaling without assigning ordinary-point constants",
 AssociationQ[boundaryGPL]&&boundaryGPL["GPLRepresentation"]["Status"]==="RequiredIntegralsConvertedToGPL"&&
 boundaryGPL["GPLRepresentation"]["PathParameterScale"]===x&&!KeyExistsQ[boundaryGPL,"BasePoint"]];
Print["AFFINE GPL PATH TEST COMPLETE"];FTReport[];
