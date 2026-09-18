(* Contract physical coefficient rows before choosing finite normal depth. *)
BeginPackage["FeynFacet`"];
ConstructPhysicalEndpointCoefficientJets::usage="ConstructPhysicalEndpointCoefficientJets[endpoint,boundaryValues,coefficientRows,request] contracts the exact pulled-back physical coefficients and density Jacobian with the normal gauge, derives the finite normal depth needed through the requested integer power, and constructs full-master Frobenius jets in the physically fixed boundary columns. Epsilon and tangential endpoint expansion remain separate.";
MapEndpointFaceCoefficientJets::usage="MapEndpointFaceCoefficientJets[chart,jets,request] restores an ordinary open-face coefficient to the original coordinates, including its exact monomial Jacobian and regulator-dependent normal-unit factor before epsilon expansion. The remaining positive tangential coordinate substitution is applied after DE integration.";
IdentifyProductCornerTerm::usage="IdentifyProductCornerTerm[cover,records] checks every exceptional divisor of a verified monomial cover against one product of simple original-coordinate powers. Each record supplies ChartIndex and CoefficientJets. It proves equality of the retained exceptional-divisor coefficients at generic epsilon; ordinary open-edge profiles and the joint integrable remainder remain separate.";
Begin["`Private`"];
ConstructPhysicalEndpointCoefficientJets[endpoint_Association,boundary_Association,rows_Association,request_Association]:=
 Catch[Module[{r,t,e,n,basis,count,lambda,beta,through,rules,jacobian,labels,coefficients,
  field,restore,w,variables,lower,depth,seed,left,selection,indices,expansion,jet,
  series,maps=<||>,q,m,flat,orders,one,rank,cancel,tangentJets,checks,boundarySystemQ,boundaryGamma},
 boundarySystemQ=Lookup[boundary,"Status",None]==="PhysicalEndpointBoundarySystemConstructed";
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem"||
  (!boundarySystemQ&&Lookup[boundary,"Status",None]=!="PhysicalEndpointBoundaryValuesDetermined")||
  endpoint["OriginalMasterIntegralBasis"]=!=boundary["MasterIntegralBasis"],
  tangentialEndpointFail["PhysicallyMatchedEndpointSystemRequired"]];
 {r,t,e,n}=Lookup[endpoint,{"NormalVariable","TangentialVariable","DimensionalRegulator","Dimension"}];
 basis=boundary["MasterIntegralBasis"];labels=Keys[rows];
 If[!AllTrue[Values[rows],AssociationQ[#]&&ContainsAll[basis,Keys[#]]&],
  tangentialEndpointFail["SparsePhysicalCoefficientRowsRequired"]];
 through=Lookup[request,"IntegerOrderThrough",-1];rules=Lookup[request,"KinematicRules",{}];
 jacobian=Lookup[request,"DensityJacobian",None];
 If[!IntegerQ[through]||jacobian===None,tangentialEndpointFail["FiniteNormalOrderAndExplicitDensityJacobianRequired"]];
 cancel[a_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[Normal[a]]]},
  If[!ListQ[answer],tangentialEndpointFail["EndpointCoefficientMatrixCancellationFailed"]];
  Partition[answer,Last[Dimensions[a]]]];
 coefficients=Table[Lookup[rows[label],Key[master],0],{label,labels},{master,basis}];
 {field,restore}=coefficientRationalFieldReduce[coefficients];
 field=field/.rules;restore=restore/.rules;
 If[!FreeQ[Last/@restore,r|t],tangentialEndpointFail["CoordinateDependentAnalyticPrefactorNeedsEndpointFactoring"]];
 w=cancel[jacobian field.endpoint["NormalGaugeMatrix"]];
 lower=Min[If[#===0,Infinity,Exponent[Numerator[#],r,Min]-Exponent[Denominator[#],r,Min]]&/@Flatten[w]];
 If[lower===Infinity||lower>through,
  Return[<|"DataType"->"PhysicalEndpointCoefficientJets","Status"->"NoRequestedNormalTerms",
   "NormalVariable"->r,"TangentialVariable"->t,"CoefficientMatrices"-><||>,
   "IntegerOrderThrough"->through,"FirstPossibleIntegerPower"->lower|>,Module]];
 depth=through-lower;
 seed=If[boundarySystemQ,boundary["NormalizedLeadingVectorEmbedding"],boundary["RationalCoefficientMatrix"]];
 rank=Last[Dimensions[seed]];
 indices=boundaryFunctionSystemIndependentRows[seed];
 If[indices===$Failed||Length[indices]=!=rank,tangentialEndpointFail["IndependentPhysicalEndpointSeedColumnsRequired"]];
 left=cancel[Inverse[seed[[indices]]].IdentityMatrix[n][[indices]]];
 lambda=boundary["NormalExponent"];beta=If[boundarySystemQ,0,boundary["TangentialRegulatorExponent"]];
 boundaryGamma=If[boundarySystemQ,boundary["ConnectionMatrix"],
   (beta/t+Lookup[boundary,"TangentialAnalyticLogDerivative",0])IdentityMatrix[rank]];
 expansion=FeynFacet`ConstructPrimaryFrobeniusExpansion[
  <|"Variable"->r,"DimensionalRegulator"->e,"ConnectionMatrix"->endpoint["NormalizedNormalConnectionMatrix"]|>,
  <|"Basis"->seed,"LeftInverse"->left|>,
  <|"ResidueEigenvalue"->lambda,"SpectralVariable"->physicalEndpointEigenvalue,
   "ResidueAnnihilatingPolynomial"->physicalEndpointEigenvalue-lambda,
   "MaximumNormalOrder"->depth|>,"Verbose"->Lookup[request,"Verbose",False]];
 If[FailureQ[expansion],Throw[expansion,"TangentialEndpoint"]];
 If[expansion["MaximumLogarithmPower"]=!=0,tangentialEndpointFail["PhysicalSeedJordanLogarithmsRequireCoefficientTensor"]];
 jet=Normal/@expansion["Coefficients"][[All,1]];
 tangentJets=Table[Map[Cancel[SeriesCoefficient[#,{r,0,j}]]&,
   endpoint["NormalizedTangentialConnectionMatrix"],{2}],{j,0,depth}];
 Do[
  checks=cancel[D[jet[[j+1]],t]+jet[[j+1]].boundaryGamma-
   Sum[tangentJets[[k+1]].jet[[j-k+1]],{k,0,j}]];
  If[!AllTrue[Flatten[checks],#===0&],tangentialEndpointFail["PhysicalEndpointJetTangentialEquationMismatch",<|"NormalOrder"->j|>]],
 {j,0,depth}];
 variables=DeleteDuplicates[Cases[w,_Symbol,{0,Infinity}]];
 If[!MemberQ[variables,r],AppendTo[variables,r]];
 series=FeynFacet`RationalLaurentCoefficients[Flatten[w],variables,r,{lower,through}];
 If[!ListQ[series],tangentialEndpointFail["RationalPhysicalEndpointCoefficientExpansionRequired"]];
 series=Partition[series,n];
 Do[
  one=cancel[Sum[Map[Lookup[#,q-m,0]&,series,{2}].jet[[m+1]],{m,0,q-lower}]];
  If[!AllTrue[Flatten[one],#===0&],AssociateTo[maps,q->(one/.restore)]],
 {q,lower,through}];
 <|"DataType"->"PhysicalEndpointCoefficientJets","Status"->"ContractedPhysicalEndpointJetsConstructed",
  "NormalVariable"->r,"TangentialVariable"->t,"DimensionalRegulator"->e,
  "NormalExponent"->lambda,"TangentialRegulatorExponent"->If[boundarySystemQ,None,beta],
   "TangentialAnalyticFactor"->If[boundarySystemQ,1,Lookup[boundary,"TangentialAnalyticFactor",1]],
  "CoefficientRowLabels"->labels,"CoefficientMatrices"->maps,
  "InitialConstantValues"->If[boundarySystemQ,Missing["BoundaryFunctionsMustBeEvaluated"],boundary["InitialConstantValues"]],
  "BoundaryFunctionSystem"->If[boundarySystemQ,boundary,None],"BoundaryValueDimension"->rank,
  "BoundaryConstantCount"->boundary["BoundaryConstantCount"],
  "IntegerOrderThrough"->through,"UncontractedIntegerLowerBound"->lower,
  "RequiredFrobeniusOrder"->depth,"RetainedIntegerPowers"->Keys[maps],
  "MasterIntegralBasis"->basis,"DensityJacobian"->jacobian,"KinematicRules"->rules,
  "Verification"-><|"ExactPhysicalSeed"->True,"NormalFrobeniusRecurrence"->True,
   "ExactTangentialJetEquations"->True,"CoefficientsContractedBeforeDepthSelection"->True|>,
  "CoefficientConvention"->"For each integer q, r^(q+NormalExponent) t^TangentialRegulatorExponent TangentialAnalyticFactor times CoefficientMatrices[q].InitialConstantValues is the physical density jet.",
  "JointIntegrableRemainderEstablished"->False,
  "Scope"->"Finite normal coefficients at fixed interior tangential coordinate. Tangential faces, joint product subtraction and epsilon moment demands remain separate."|>
],"TangentialEndpoint"];


MapEndpointFaceCoefficientJets[chart_Association,jets_Association,request_Association:<||>]:=Module[
 {matrix,variables,original,positions,normalRows,normalIndex,tangentIndex,q,a,b,k,p,
  lambda,t,factor,coefficient},
 If[Lookup[jets,"Status",None]=!="ContractedPhysicalEndpointJetsConstructed"||
  Dimensions[Lookup[chart,"ExponentMatrix",{}]]=!={2,2},
  Return[Failure["MonomialChartAndContractedFaceJetsRequired",<||>]]];
 variables=chart["Variables"];original=chart["OriginalVariables"];
 If[!ContainsAll[variables,Lookup[jets,{"NormalVariable","TangentialVariable"}]],
  Return[Failure["FaceAndChartCoordinatesMustMatch",<||>]]];
 positions=First@FirstPosition[variables,#]&/@Lookup[jets,{"NormalVariable","TangentialVariable"}];
 matrix=chart["ExponentMatrix"][[All,positions]];
 normalRows=Flatten[Position[matrix[[All,1]],_?(#>0&)]];
 If[Length[normalRows]=!=1,Return[Failure["OrdinaryOriginalCoordinateFaceRequired",<||>]]];
 normalIndex=First[normalRows];tangentIndex=3-normalIndex;
 {q,a}=matrix[[normalIndex]];b=matrix[[tangentIndex,2]];
 If[q<=0||b<=0,Return[Failure["PositiveOrdinaryFacePowersRequired",<||>]]];
 k=Lookup[request,"IntegerNormalPower",-1];p=(k+1)/q-1;
 If[!IntegerQ[p]||!KeyExistsQ[jets["CoefficientMatrices"],k],
  Return[Failure["IntegralOriginalNormalPowerAndExistingJetRequired",<||>]]];
 lambda=First[FeynFacet`CancelRationalCoefficients[{jets["NormalExponent"]/q}]];
 t=jets["TangentialVariable"];
 (* x=u^q t^a, y=t^b: |J| x^p = q b
    u^(q(p+1)-1) t^(a(p+1)+b-1), also at regulated p. *)
 factor=t^(1-b-a(p+1+lambda))/Abs[Det[matrix]];
 coefficient=factor jets["CoefficientMatrices"][k];
 Join[jets,<|"NormalVariable"->original[[normalIndex]],"NormalExponent"->lambda,
  "CoefficientMatrices"-><|p->coefficient|>,"RetainedIntegerPowers"->{p},
  "OutputCoordinateRules"->{t->original[[tangentIndex]]^(1/b)},
  "OutputTangentialVariable"->original[[tangentIndex]],
  "MonomialFaceMap"-><|"ExponentMatrix"->matrix,"OriginalNormalIndex"->normalIndex,
   "SourceIntegerPower"->k,"OriginalIntegerPower"->p,"CoefficientFactor"->factor,
   "Convention"->"Invert the positive monomial density map before regulator expansion; include the whole Jacobian."|>|>]
];

IdentifyProductCornerTerm[cover_Association,records_List]:=Catch[Module[
 {charts,required,supplied={},first,labels,constants,sourceExponents=None,model=None,
  chart,jet,index,matrix,positions,exponents,candidate,rows,norm,canonical,zero,cancel},
 charts=Lookup[cover,"Charts",None];
 If[Lookup[cover,"Format",None]=!="FeynFacet-MonomialEndpointCharts"||
  !TrueQ[Lookup[cover,"CoverageVerified",False]]||!TrueQ[Lookup[cover,"DisjointInteriorsVerified",False]]||
  Length[Lookup[cover,"OriginalVariables",{}]]=!=2||!ListQ[charts]||records==={}||!AllTrue[records,AssociationQ[#]&&ContainsAll[Keys[#],{"ChartIndex","CoefficientJets"}]&],
  tangentialEndpointFail["VerifiedMonomialCoverAndCoefficientJetsRequired"]];
 required=Flatten[Table[Table[If[AllTrue[charts[[j]]["ExponentMatrix"][[All,k]],#>0&],{j,k},Nothing],
  {k,Length[charts[[j]]["Variables"]]}],{j,Length[charts]}],1];
 cancel[a_]:=Module[{answer=FeynFacet`CancelRationalCoefficients[Flatten[a]]},
  If[!ListQ[answer],tangentialEndpointFail["ExactProductCornerComparisonFailed"]];
  Partition[answer,Last[Dimensions[a]]]];
 first=records[[1,"CoefficientJets"]];labels=first["CoefficientRowLabels"];constants=first["InitialConstantValues"];
 Do[
  {index,jet}=Lookup[record,{"ChartIndex","CoefficientJets"}];
  If[!IntegerQ[index]||!Between[index,{1,Length[charts]}],tangentialEndpointFail["KnownMonomialChartRequired"]];
  chart=charts[[index]];matrix=chart["ExponentMatrix"];
  If[Lookup[jet,"Status",None]=!="ContractedPhysicalEndpointJetsConstructed"||
   jet["CoefficientRowLabels"]=!=labels||jet["InitialConstantValues"]=!=constants||
   jet["IntegerOrderThrough"]< -1||Sort[Select[jet["RetainedIntegerPowers"],#<0&]]=!={-1},
   tangentialEndpointFail["CompleteSimpleExceptionalDivisorJetRequired"]];
  positions=First@FirstPosition[chart["Variables"],#]&/@{jet["NormalVariable"],jet["TangentialVariable"]};
  AppendTo[supplied,{index,First[positions]}];
  exponents=ConstantArray[0,2];exponents[[positions]]={jet["NormalExponent"],jet["TangentialRegulatorExponent"]};
  candidate=Cancel/@LinearSolve[Transpose[matrix],exponents];
  If[sourceExponents===None,sourceExponents=candidate,
   If[!AllTrue[Cancel/@(candidate-sourceExponents),#===0&],tangentialEndpointFail["IncompatibleOriginalCornerRegulatorExponents"]]];
  rows=cancel[jet["TangentialVariable"]Lookup[jet,"TangentialAnalyticFactor",1]jet["CoefficientMatrices"][-1]/Abs[Det[matrix]]];
  If[!FreeQ[rows,Alternatives@@chart["Variables"]],tangentialEndpointFail["ExceptionalProfileIsNotAProductCornerTerm"]];
  If[model===None,model=rows,
   If[!AllTrue[Flatten[cancel[rows-model]],#===0&],tangentialEndpointFail["ExceptionalProfilesHaveDifferentProductCoefficients"]]],
 {record,records}];
 If[!ContainsAll[supplied,required],tangentialEndpointFail["AllExceptionalDivisorsMustBeChecked",
  <|"RequiredDivisors"->required,"CheckedDivisors"->supplied|>]];
 <|"DataType"->"ProductCornerTerm","Status"->"ExactProductCornerLeadingTermVerified",
  "NormalVariables"->charts[[1]]["OriginalVariables"],"DimensionalRegulator"->first["DimensionalRegulator"],
  "Powers"->(-1+sourceExponents),"CoefficientRowLabels"->labels,"CoefficientMatrix"->model,
  "InitialConstantValues"->constants,"CheckedExceptionalDivisors"->supplied,
  "LeadingDensity"->"Product of OriginalVariable_i^Powers_i times CoefficientMatrix.InitialConstantValues.",
  "JointIntegrableRemainderEstablished"->False,
  "Scope"->"All exceptional-divisor jets on the exact monomial cover. Complete ordinary edge subtractions are still required for a joint L1 remainder."|>
],"TangentialEndpoint"];

End[];EndPackage[];
