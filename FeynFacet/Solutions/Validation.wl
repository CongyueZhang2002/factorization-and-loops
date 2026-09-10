(* Generic identities for the actual finite expressions. *)
Begin["FeynFacet`Private`"];
Options[FeynFacet`VerifyMasterIntegralSolution]={"RecheckFlatness"->True,"Verbose"->False,
 "IdentityCheck"->"NumericalPoints","ValidationPoints"->Automatic};
FeynFacet`VerifyMasterIntegralSolution[r_Association,OptionsPattern[]] := Catch[Module[
 {vars,e,a,b,m,values,kernels,t,path,funcs,n,orders,derivative,rhs,
  pathChecks={},kernelChecks={},gaugeChecks,flatness,expected,normalChecks,
  conv,lc,rc,w,algebra,expandOne,g,g0inv,leftExpected,rightExpected,
  leftChecks,rightChecks,convolutionChecks,finalChecks,source,sourceChecks,coefficients,progress,method,points,coordinatePoints,sampleCoefficients,sampleRules,
  samplePathRules,taus={1/4,1/2,3/4},numericKernels,leftUpper,rightUpper,verbose,entryOrders,masterChecks=None,expectedMaster,resolvedKernels,sampledKernelValues,allSampledKernelValues},
 verbose=OptionValue["Verbose"];progress[msg_]:=If[TrueQ[verbose],Print[msg]];
 If[!FeynFacet`MasterIntegralSolutionQ[r],solutionFail["FiniteSolutionRequired"]];
 vars=r["KinematicVariables"];e=r["DimensionalRegulator"];
 method=OptionValue["IdentityCheck"];points=OptionValue["ValidationPoints"];
 If[points===Automatic,points=solutionValidationPoints[vars,r["BasePoint"],e,solutionValidationExpressions[r]]];
 If[!MemberQ[{"Exact","NumericalPoints"},method],solutionFail["UnknownIdentityCheck"]];
 If[method==="NumericalPoints" && Length[points]<3,
   solutionFail["AtLeastThreeValidationPointsRequired"]];
 coordinatePoints=DeleteCases[#,Rule[e,_]]& /@ points;
 a=r["ConnectionMatrices"];b=r["PreparedConnectionMatrices"];
 m=r["HomogeneousFundamentalMatrix"].r["AdditionalBasisTransformationMatrix"];
 values=r["TransformedSolutionCoefficients"];kernels=r["KernelMatrices"];
 t=r["Path"]["Parameter"];path=Thread[vars->r["Path"]["Coordinates"]];
 funcs=r["IntegralDefinitions"];n=Length[First[a]];orders=Keys[values];
 entryOrders=Lookup[r,"TransformedCoefficientUpperOrders",ConstantArray[Max[orders],{n,n}]];
 progress["Verifying source and preparation identities"];
 source=Lookup[r,"OriginalConnectionMatrices",None];
 sourceChecks=If[ListQ[source],
   solutionGaugeChecks[r["BasisTransformationMatrix"],source,a,vars,method,points],
   Missing["IndependentOriginalConnectionNotProvided"]];
 If[ListQ[sourceChecks] && !And@@sourceChecks,
   solutionFail["OriginalBasisDifferentialEquationMismatch",<|"CoordinateChecks"->sourceChecks|>]];
 gaugeChecks=solutionGaugeChecks[m,a,b,vars,method,points];
 If[!And@@gaugeChecks,solutionFail["GaugeIdentityFailed",<|"CoordinateChecks"->gaugeChecks|>]];
 (* Epsilon expansion commutes with the epsilon-independent path substitution.
    Expand the original coordinate expressions once, before the larger pullback. *)
 progress["Verifying explicit kernel pullbacks and finite integral identities"];
 If[method==="Exact",
  resolvedKernels=solutionResolveKernelDefinitions[r["KernelDefinitions"]];
  coefficients=solutionLaurentCoefficients[#,e,Max[orders],True]& /@ b,
  sampleCoefficients=Table[
    samplePathRules=Join[Thread[vars->(r["Path"]["Coordinates"]/.pt/.t->taus[[1+Mod[j-1,Length[taus]]]])],
     Select[pt,!MemberQ[vars,First[#]]&]];
    solutionLaurentCoefficients[N[#/.N[samplePathRules,80],80],e,Max[orders],True]& /@ b,
    {j,Length[coordinatePoints]},{pt,{coordinatePoints[[j]]}}][[All,1]];
  allSampledKernelValues=Table[
    sampleRules=Append[coordinatePoints[[j]],t->taus[[1+Mod[j-1,Length[taus]]]]];
    solutionEvaluateKernelDefinitions[r["KernelDefinitions"],N[sampleRules,80],80],
    {j,Length[coordinatePoints]}]
 ];
 Do[
  If[method==="Exact",
   expected=Total[Table[(solutionCoefficient[coefficients[[i]],k,n]/.path)
      D[r["Path"]["Coordinates"][[i]],t],{i,Length[vars]}]];
   AppendTo[kernelChecks,solutionMatrixZero[
     (kernels[k]/.FeynFacetSolution`K[j_Integer,t]:>
       resolvedKernels[[j]])-expected]],
   AppendTo[kernelChecks,And@@Table[
     sampleRules=Append[coordinatePoints[[j]],t->taus[[1+Mod[j-1,Length[taus]]]]];
     expected=Total[Table[solutionCoefficient[sampleCoefficients[[j,i]],k,n]
       N[D[r["Path"]["Coordinates"][[i]],t]/.N[sampleRules,80],80],{i,Length[vars]}]];
     sampledKernelValues=allSampledKernelValues[[j]];
     numericKernels=N[kernels[k]/.FeynFacetSolution`K[l_Integer,t]:>sampledKernelValues[[l]],80];
     solutionNumericalZero[{numericKernels,-expected}],{j,Length[coordinatePoints]}]]
  ];
  derivative=D[values[k],t]/.
    Derivative[0,1][FeynFacetSolution`F][j_Integer,t]:>
      (funcs[[j,"Integrand"]]/.funcs[[j,"IntegrationVariable"]]->t);
  rhs=Total[Table[kernels[q].values[k-q],{q,0,k}]];
  AppendTo[pathChecks,solutionMatrixZero[MapIndexed[If[k<=Extract[entryOrders,#2],#1,0]&,Expand[derivative-rhs],{2}]]],
 {k,orders}];
 If[!And@@Join[pathChecks,kernelChecks],solutionFail["StoredCoefficientIdentityFailed",
   <|"Orders"->orders,"PathCoefficientChecks"->pathChecks,"KernelPullbackChecks"->kernelChecks|>]];

 progress["Verifying normalization and basis convolutions"];
 normalChecks=Table[solutionMatrixZero[(values[k]/.FeynFacetSolution`F[_,_]->0)-
   If[k===0,IdentityMatrix[n],ConstantArray[0,{n,n}]]],{k,orders}];
 conv=r["BasisConvolutionCoefficients"];lc=conv["LeftCoefficients"];
 rc=conv["RightCoefficients"];w=conv["RightConvolutionCoefficients"];
 algebra=r["AlgebraicDefinitions"];
 expandOne[z_]:=Map[Replace[#,FeynFacetSolution`a[j_Integer]:>algebra[[j]]]&,z,{2}];
 g=r["BasisTransformationMatrix"].m;
 g0inv=r["InverseTotalBasisTransformationAtBasePoint"];
 If[!solutionMatrixZero[(g/.Thread[vars->r["BasePoint"]]).g0inv-IdentityMatrix[n]],
   solutionFail["BasePointInverseIdentityFailed"]];
 leftUpper=Max[0,Max[r["RequestedEpsilonOrders"]]]-r["BasisTransformationLaurentLowerBounds"][[2]];
 rightUpper=Max[0,Max[r["RequestedEpsilonOrders"]]]-r["BasisTransformationLaurentLowerBounds"][[1]];
 If[method==="Exact",
  leftExpected=solutionLaurentCoefficients[g,e,leftUpper,True];
  rightExpected=solutionLaurentCoefficients[g0inv,e,rightUpper,True];
  leftChecks=Keys[lc]===Keys[leftExpected] &&
    And@@Table[solutionMatrixZero[expandOne[lc[k]]-leftExpected[k]],{k,Keys[lc]}];
  rightChecks=Keys[rc]===Keys[rightExpected] &&
    And@@Table[solutionMatrixZero[expandOne[rc[k]]-rightExpected[k]],{k,Keys[rc]}],
  leftChecks=And@@Table[
    leftExpected=solutionLaurentCoefficients[N[g/.N[pt,80],80],e,leftUpper,True];
    And@@Table[solutionNumericalZero[{N[expandOne[solutionCoefficient[lc,k,n]]/.N[pt,80],80],
       -solutionCoefficient[leftExpected,k,n]}],{k,Union[Keys[lc],Keys[leftExpected]]}],
    {pt,coordinatePoints}];
  rightChecks=And@@Table[
    rightExpected=solutionLaurentCoefficients[N[g0inv/.N[pt,80],80],e,rightUpper,True];
    And@@Table[solutionNumericalZero[{N[expandOne[solutionCoefficient[rc,k,n]]/.N[pt,80],80],
     -solutionCoefficient[rightExpected,k,n]}],{k,Union[Keys[rc],Keys[rightExpected]]}],
    {pt,coordinatePoints}]
 ];
 convolutionChecks=Table[solutionMatrixZero[Expand[expandOne[w[k]]-
   Total[Table[(values[b]/.FeynFacetSolution`F[j_,t]:>FeynFacetSolution`F[j,1]).
     solutionCoefficient[rc,k-b,n],{b,orders}]]]],{k,Keys[w]}];
 finalChecks=Table[
  expected=Total[Table[lc[q].solutionCoefficient[w,k-q,n],{q,Keys[lc]}]];
  solutionMatrixZero[Expand[MapThread[
    If[#1===Missing["NotComputed"],0,#1-#2]&,
    {Last/@r["Coefficients"][k],expected[[r["RequestedRows"]]]},2]]],
 {k,r["RequestedEpsilonOrders"]}];
 If[!And@@Join[normalChecks,{leftChecks,rightChecks},convolutionChecks,finalChecks],
  solutionFail["StoredBasisConvolutionIdentityFailed",<|"Normalization"->normalChecks,
    "LeftBasis"->leftChecks,"RightBasis"->rightChecks,
    "RightConvolution"->convolutionChecks,"OriginalCoefficients"->finalChecks|>]];
 If[AssociationQ[Lookup[r,"ExpansionOrderDetermination",None]],
   expectedMaster=solutionMasterCoefficientsFromOrders[r,r["ExpansionOrderDetermination"]];
   masterChecks=And@@Flatten[Table[
     solutionMatrixZero[Expand[Last /@ r["MasterIntegralCoefficients"][k]-
       Last /@ expectedMaster["MasterIntegralCoefficients"][k]]],
     {k,r["RequestedMasterIntegralEpsilonOrders"]}]];
   If[!TrueQ[masterChecks],solutionFail["StoredInitialConstantConvolutionFailed"]]
 ];
 progress["Completing the multivariate verification"];
 flatness=If[TrueQ[OptionValue["RecheckFlatness"]],solutionFlatness[If[ListQ[source],source,a],vars,method,points],
   <|"Rechecked"->False,"PreviousResult"->r["Validation"]["Flatness"]|>];
 <|"Status"->"FiniteSolutionCoefficientIdentitiesVerified",
   "IdentityCheckMethod"->method,"ExactGenericIdentityProof"->(method==="Exact" &&
     TrueQ[Lookup[flatness,"ExactIdentity",
       Lookup[Lookup[flatness,"PreviousResult",<||>],"ExactIdentity",False]]]),
   "ValidationPoints"->points,
   "NumericalParameters"->If[method==="NumericalPoints",
     <|"WorkingPrecision"->80,"RelativeTolerance"->10^-50,"PathParameters"->taus|>,None],
   "EpsilonOrdersInTransformedBasis"->orders,"TransformedCoefficientUpperOrders"->entryOrders,"GaugeIdentitiesInAllCoordinates"->gaugeChecks,
   "KernelPullbackIdentities"->kernelChecks,"PathCoefficientIdentities"->pathChecks,
   "OriginalInputBasisIdentities"->sourceChecks,"BasePointNormalization"->normalChecks,
   "LeftBasisCoefficients"->leftChecks,"RightBasisCoefficients"->rightChecks,
   "RightConvolutionCoefficients"->convolutionChecks,
   "OriginalBasisCoefficients"->finalChecks,"InitialConstantConvolutionIdentities"->masterChecks,"Flatness"->flatness,
   "MultivariateJustification"->"When flatness holds, for E_mu=partial_mu V-A(partial_mu gamma)V, flatness gives partial_t E_mu=A(partial_t gamma) E_mu and E_mu(0)=0. The finite epsilon and triangular row ordering proves E_mu=0 coefficient by coefficient.",
   "Scope"->If[method==="Exact",
     "Generic coefficient and gauge identities; the flatness evidence is stated separately. Physical constants are not evaluated.",
     "Finite integral and convolution identities are exact. Source gauges, kernel pullbacks and basis coefficients are checked numerically at rational points, not proved at generic kinematics. Physical constants are not evaluated."]|>
],"FiniteSolution"];
End[];
