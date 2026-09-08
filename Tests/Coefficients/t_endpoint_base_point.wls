root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Get[root<>"/FeynFacet/Coefficients/EndpointValidation.wl"];
Clear[v,t,x];
d=<|"DataType"->"FiniteScalarEndpointSolution","TangentialVariable"->v,"TangentialBasePoint"->1/4,
 "KernelDefinitions"->{<|"Parameter"->t,"Expression"->2 t|>},
 "IntegralDefinitions"->{
  <|"IntegrationVariable"->t,"Integrand"->FeynFacetSolution`K[1,t],"LowerLimit"->0|>,
  <|"IntegrationVariable"->t,"Integrand"->FeynFacetSolution`F[1,t],"LowerLimit"->1/2|>},
 "AlgebraicDefinitions"->{x FeynFacetSolution`F[2,1],FeynFacetSolution`a[1]+v},
 "EndpointTerms"->{<|"Power"->-1,"RegulatorExponent"->-2,"LogPower"->0,
  "Coefficients"-><|0->FeynFacetSolution`a[2]|>|>}|>;
r=EvaluateScalarEndpointAtBasePoint[d,"ParameterRules"->{x->3},"WorkingPrecision"->60];
FTAssert["nested polynomial integrals and their nonzero lower limits are evaluated at the base point",
 AssociationQ[r]&&Abs[r["EndpointTerms"][[1,"Coefficients"]][0]-9/8]<10^-55];
bad=Join[d,<|"IntegralDefinitions"->{<|"IntegrationVariable"->t,"Integrand"->1/(1+t),"LowerLimit"->0|>},
 "AlgebraicDefinitions"->{},"EndpointTerms"->{<|"Power"->-1,"RegulatorExponent"->-2,"LogPower"->0,
 "Coefficients"-><|0->FeynFacetSolution`F[1,1]|>|>}|>];
FTAssert["a needed nonpolynomial integral is rejected rather than treated as zero",
 MatchQ[EvaluateScalarEndpointAtBasePoint[bad],Failure["EndpointBasePointCoefficientNotNumeric",_]]];
FTAssert["missing external parameters are rejected",
 MatchQ[EvaluateScalarEndpointAtBasePoint[d],Failure["EndpointBasePointCoefficientNotNumeric",_]]];
FTReport[];
