$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[x,t,s];
shared=<|"DataType"->"SharedBoundaryCoefficientDefinitions",
 "KernelDefinitions"->{
  <|"Index"->1,"Parameter"->t,"Expression"->1|>,
  <|"Index"->2,"Parameter"->t,"Expression"->FeynFacetSolution`K[1,t]/(1+t)|>,
  <|"Index"->3,"Parameter"->t,"Expression"->1/(t-1/2)|>},
 "IntegralDefinitions"->{
  <|"Index"->1,"IntegrationVariable"->t,"UpperLimitVariable"->s,"LowerLimit"->0,"Integrand"->FeynFacetSolution`K[1,t]|>,
  <|"Index"->2,"IntegrationVariable"->t,"UpperLimitVariable"->s,"LowerLimit"->0,"Integrand"->FeynFacetSolution`K[2,t]FeynFacetSolution`F[1,t]|>,
  <|"Index"->3,"IntegrationVariable"->t,"UpperLimitVariable"->s,"LowerLimit"->0,"Integrand"->FeynFacetSolution`K[3,t]|>},
 "AlgebraicDefinitions"->{FeynFacetSolution`F[2,1],1+FeynFacetSolution`a[1]},
 "BoundaryCoefficientDefinitions"-><|
  {7,0}->FeynFacetSolution`a[2]FeynFacetSolution`C[1,0],
  {7,1}->FeynFacetSolution`C[1,1]+FeynFacetSolution`a[1]|>|>;
family=<|"DataType"->"MasterIntegralSolution","SchemaVersion"->5,
 "SolutionRepresentation"->"FiniteNestedIntegrals","SystemDimension"->1,
 "KinematicVariables"->{x},"RequestedRows"->{1},"RequestedEpsilonOrders"->{0},
 "RequestedMasterIntegralEpsilonOrders"->{0},
 "InitialConstants"-><|"Count"->1|>,"InitialConstantLaurentLowerBounds"->{0},
 "BoundaryAmplitudes"->{<|"Index"->1,"LaurentLowerBound"->0,"Definition"->"Test amplitude"|>},
 "SharedBoundaryDefinitionFile"->"shared.wxf","RequiredInitialConstantCoefficients"->{{1,0},{1,1}},
 "KnownBoundaryValues"->{<|"Definition"->"Known affine contribution"|>},
 "KernelDefinitions"->{<|"Index"->1,"Parameter"->t,"Expression"->t^2|>},
 "IntegralDefinitions"->{<|"Index"->1,"IntegrationVariable"->t,"UpperLimitVariable"->s,
   "LowerLimit"->0,"Integrand"->FeynFacetSolution`K[1,t]|>},
 "AlgebraicDefinitions"->{FeynFacetSolution`F[1,1]},
 "Coefficients"-><|0->{1->{1}}|>,
 "MasterIntegralCoefficients"-><|0->{1->(FeynFacetSolution`B[7,0]+
   FeynFacetSolution`a[1]FeynFacetSolution`B[7,1])}|>|>;
resolved=FeynFacetSolution`ResolveSharedBoundaryDefinitions[family,shared];
If[FailureQ[resolved],Print["RESOLUTION FAILURE ",resolved]];
FTAssert["only reachable shared definitions are imported",AssociationQ[resolved]&&
 Length[resolved["KernelDefinitions"]]===3&&Length[resolved["IntegralDefinitions"]]===3&&
 Length[resolved["AlgebraicDefinitions"]]===3&&
 FreeQ[resolved["KernelDefinitions"],1/(t-1/2)]];
FTAssert["derived boundary symbols are replaced by the actual amplitude expressions",
 AssociationQ[resolved]&&FreeQ[resolved["MasterIntegralCoefficients"],_FeynFacetSolution`B]&&
 MasterIntegralSolutionQ[resolved]];
bad=FeynFacetSolution`ResolveSharedBoundaryDefinitions[
 family/.FeynFacetSolution`B[7,0]->FeynFacetSolution`B[8,0],shared];
FTAssert["a missing shared boundary coefficient is an error",
 MatchQ[bad,Failure["SharedBoundaryCoefficientMissing",_]]];
Block[{Print},Get[root<>"/FeynFacet/Solution.m"]];
readerResolved=FeynFacetSolution`ResolveSharedBoundaryDefinitions[family,shared];
FTAssert["the standalone reader preserves the same shared algebraic dependencies",
 readerResolved===resolved];
numeric=EvaluateMasterIntegralSolution[readerResolved,{1},"NumericalBackend"->"Wolfram",
 "WorkingPrecision"->50,"QuadratureOrder"->32,"CheckConvergence"->False,"PathCheck"->None,
 "InitialConstantValues"->{FeynFacetSolution`C[1,0]->2,FeynFacetSolution`C[1,1]->3}];
FTAssert["the shared and family scalar-definition indices evaluate independently",
 AssociationQ[numeric]&&TrueQ[Abs[
  Last[First[numeric["MasterIntegralEpsilonCoefficients"][0]]]-
  N[16/3-7Log[2]/3,40]]<10^-25]];

pointMap=BinaryDeserialize[BinarySerialize[<|{1/4,1/6}->{7/12}|>]];
FTAssert["serialized exact point keys can be rebuilt for boundary-coordinate lookup",
 KeyExistsQ[Association[Normal[pointMap]],{1/4,1/6}]];
FTReport[];

