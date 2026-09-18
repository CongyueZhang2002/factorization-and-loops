(* Rational scalar coefficients must be checked in the same logarithmic
   frame as the master system. A master DE alone cannot resolve their poles. *)
BeginPackage["FeynFacet`"];
AnalyzeNormalCrossingScalarCoefficients::usage="AnalyzeNormalCrossingScalarCoefficients[intersection,rows,request] contracts the exact physical coefficient rows with a verified logarithmic gauge and an explicit normalization factor. It reports all coordinate valuations and rejects no non-coordinate divisor silently. It does not by itself prove cancellation against a physical solution.";
VerifyUniformNormalCrossingPhysicalGerm::usage="VerifyUniformNormalCrossingPhysicalGerm[intersection,matching,scalarCoefficients,constantLowerBounds] verifies an epsilon-regular logarithmic frame, nonresonance at epsilon zero, the selected joint eigenvector seed, and finite Laurent bounds for the normalized scalar germ. The source matching must describe the complete physical germ.";
VerifyRadialEndpointCollar::usage="VerifyRadialEndpointCollar[endpoint,values,rows,request] checks an epsilon-regular radial logarithmic system, complete normalized scalar rows and its physical leading vector uniformly on compact subsets of a declared open tangential interval.";
ScaleNormalCrossingScalarCoefficients::usage="ScaleNormalCrossingScalarCoefficients[analysis,integerShifts] multiplies previously analyzed scalar rows by an exact coordinate monomial and updates their valuations without repeating the gauge contraction or divisor factorization.";
VerifyRemovableEndpointDivisor::usage="VerifyRemovableEndpointDivisor[endpoint,boundary,rows,request] verifies a log-free zero-exponent physical branch, vanishing of every negative integer normal coefficient, and a uniform meromorphic collar after clearing its finite scalar poles. It proves removability along the declared tangential interval; a joint-corner envelope remains separate.";
VerifyNormalCrossingDivisorCollars::usage="VerifyNormalCrossingDivisorCollars[intersection,matching,scalar,jointCertificate,request] extends a verified joint meromorphic Frobenius class over the complete open coordinate-divisor intervals by checking all coordinate denominator units. Flatness transports the normal residue and the physical boundary class; full connection and seed checks already in the joint certificate are not repeated.";
Begin["`Private`"];

(* Formal analytic generators may occur as multiplicative meromorphic
   prefactors, but never conceal a coordinate-dependent denominator. *)
(* Factor each distinct denominator once: large scalar matrices repeat
   the same few divisors across many entries and regulator prefactors. *)
endpointDenominatorFactors[expressions_]:=Module[{denominators},
 denominators=DeleteDuplicates[Denominator[Cancel[#]]&/@DeleteDuplicates[Flatten[expressions]]];
 DeleteDuplicates[Flatten[(First/@Rest[FactorList[#]])&/@denominators]]
];
(* Polynomial content is sufficient here: a denominator's factors
   independent of the coordinates cannot create a moving coordinate divisor.
   Avoid full multivariate irreducible factorization before epsilon=0. *)
endpointCoordinateDenominatorParts[expressions_,xs_List]:=Module[{denominators,parts},
 denominators=DeleteDuplicates[Denominator[Cancel[#]]&/@DeleteDuplicates[Flatten[expressions]]];
 denominators=Select[denominators,!FreeQ[#,Alternatives@@xs]&];
 parts=Flatten[Map[Function[den,With[{value=FactorTerms[den,xs]},
   If[Head[value]===Times,List@@value,{value}]]],denominators]];
 DeleteDuplicates[Select[parts,!FreeQ[#,Alternatives@@xs]&]]
];
endpointMixedAnalyticDenominators[field_,restore_List,xs_List]:=Module[{generators,parts},
 generators=First/@restore;If[generators==={},Return[{}]];
 parts=endpointCoordinateDenominatorParts[field,xs];
 Select[parts,!FreeQ[#,Alternatives@@generators]&]
];
endpointCoordinateUnitOrigins[expressions_,xs_List,rules_List]:=
 Factor[#/.rules]&/@endpointCoordinateDenominatorParts[expressions,xs];

AnalyzeNormalCrossingScalarCoefficients[intersection_Association,rows_Association,request_Association]:=Module[
 {xs,basis,labels,matrix,rules,norm,field,restore,contracted,orders,units,bad,entry,powers,unit,
   nrow,ncol,zero},
 If[Lookup[intersection,"Status",None]=!="ExactLogarithmicIntersectionEstablished",
  Return[Failure["VerifiedLogarithmicIntersectionRequired",<||>]]];
 xs=intersection["KinematicVariables"];basis=intersection["OriginalMasterIntegralBasis"];labels=Keys[rows];
 rules=Lookup[request,"KinematicRules",{}];norm=Lookup[request,"NormalizationFactor",None];
 If[norm===None||!AllTrue[Values[rows],AssociationQ[#]&&ContainsAll[basis,Keys[#]]&],
  Return[Failure["MatchedScalarCoefficientRowsAndNormalizationRequired",<||>]]];
 matrix=Table[Lookup[rows[label],Key[master],0],{label,labels},{master,basis}];
 {field,restore}=coefficientRationalFieldReduce[matrix/.rules];
 If[!FreeQ[Last/@restore,Alternatives@@xs],
  Return[Failure["CoordinateDependentAnalyticCoefficientFactorsRequireResolution",<||>]]];
 nrow=Length[labels];ncol=Length[basis];
 contracted=FeynFacet`CancelRationalCoefficients[Flatten[norm field.intersection["GaugeMatrix"]]];
 If[!ListQ[contracted],Return[contracted]];
 contracted=Partition[contracted,ncol];
 orders=Map[Function[c,If[c===0,ConstantArray[Infinity,Length[xs]],
  Table[Exponent[Numerator[c],x,Min]-Exponent[Denominator[c],x,Min],{x,xs}]]],contracted,{2}];
 units=DeleteDuplicates[Flatten[Map[Function[c,Module[{den=Denominator[c],ds},
  ds=Table[Exponent[den,x,Min],{x,xs}];
  Cancel[den/(Times@@MapThread[Power,{xs,ds}])]]],contracted,{2}]]];
 bad=Select[units,Function[d,With[{v=Cancel[d/.Thread[xs->0]]},
  v===0||!FreeQ[v,Indeterminate|_DirectedInfinity]]]];
 <|"DataType"->"NormalCrossingScalarCoefficientDivisors",
  "CoordinateVariables"->xs,"CoefficientRowLabels"->labels,"MasterIntegralBasis"->basis,
  "ScalarGaugeCoefficientMatrix"->(contracted/.restore),"EntryIntegerLaurentLowerBounds"->orders,
  "RowIntegerLaurentLowerBounds"->(Min/@Transpose[#]&/@orders),
  "NonCoordinateDenominatorUnits"->(units/.restore),"UnresolvedCornerDivisors"->(bad/.restore),
  "OnlyCoordinatePolesAtCorner"->(bad==={}),
  "NormalizedScalarCoefficientsAnalyticAtCorner"->(bad==={}&&AllTrue[Flatten[orders],#>=0&]),
  "NormalizationFactor"->norm,"KinematicRules"->rules,
  "PhysicalSolutionContractionRequired"->True|>
];


ScaleNormalCrossingScalarCoefficients[data_Association,shifts:{__Integer}]:=Module[
 {xs,monomial,orders},
 xs=Lookup[data,"CoordinateVariables",{}];
 If[Lookup[data,"DataType",None]=!="NormalCrossingScalarCoefficientDivisors"||Length[xs]=!=Length[shifts],
  Return[Failure["AnalyzedScalarRowsAndCoordinateShiftsRequired",<||>]]];
 monomial=Times@@MapThread[Power,{xs,shifts}];
 orders=Map[# + shifts&,data["EntryIntegerLaurentLowerBounds"],{2}];
 Join[data,<|"ScalarGaugeCoefficientMatrix"->monomial data["ScalarGaugeCoefficientMatrix"],
  "EntryIntegerLaurentLowerBounds"->orders,
  "RowIntegerLaurentLowerBounds"->(# + shifts&/@data["RowIntegerLaurentLowerBounds"]),
  "NormalizationFactor"->monomial data["NormalizationFactor"],
  "NormalizedScalarCoefficientsAnalyticAtCorner"->(
   TrueQ[data["OnlyCoordinatePolesAtCorner"]]&&AllTrue[Flatten[orders],#>=0&]),
  "CoordinateMonomialShift"->shifts|>]
];

VerifyRemovableEndpointDivisor[endpoint_Association,boundary_Association,rows_Association,request_Association]:=
 Module[{r,lambda,jets,order,collar,rules,jacobian},
 r=endpoint["NormalVariable"];lambda=Lookup[boundary,"NormalExponent",None];
 If[lambda===None||!TrueQ[Cancel[Together[lambda]]===0],
  Return[Failure["RemovableDivisorRequiresZeroPhysicalNormalExponent",<||>]]];
 rules=Lookup[request,"KinematicRules",{}];jacobian=Lookup[request,"DensityJacobian",None];
 If[jacobian===None,Return[Failure["ExplicitDivisorDensityJacobianRequired",<||>]]];
 jets=FeynFacet`ConstructPhysicalEndpointCoefficientJets[endpoint,boundary,rows,
  <|"KinematicRules"->rules,"DensityJacobian"->jacobian,"IntegerOrderThrough"->-1|>];
 If[FailureQ[jets],Return[jets]];
 If[Lookup[jets,"CoefficientMatrices",None]=!=<||>,
  Return[Failure["PhysicalScalarDivisorPolesRemain",<|"IntegerPowers"->Keys[jets["CoefficientMatrices"]],
   "CoefficientJets"->jets|>]]];
 order=Max[0,-Lookup[jets,"UncontractedIntegerLowerBound",0]];
 collar=FeynFacet`VerifyRadialEndpointCollar[endpoint,boundary,rows,
  <|"KinematicRules"->rules,"NormalizationFactor"->r^order jacobian,
   "TangentialConditions"->Lookup[request,"TangentialConditions",None]|>];
 If[FailureQ[collar],Return[collar]];
 <|"DataType"->"RemovablePhysicalScalarDivisor","Status"->"PhysicalScalarDivisorRemovable",
  "NormalVariable"->r,"TangentialVariable"->endpoint["TangentialVariable"],
  "NormalExponent"->0,"ScalarPoleOrderCleared"->order,
  "RequiredFrobeniusOrder"->Lookup[jets,"RequiredFrobeniusOrder",0],
  "CoefficientRowLabels"->Keys[rows],"NegativeCoefficientMatrices"-><||>,
  "PhysicalJetVerification"->Lookup[jets,"Verification",<||>],"UniformScaledCollar"->collar,
  "Argument"->"The complete physical branch is log-free with zero normal exponent. After clearing the finite scalar pole its Frobenius germ is uniformly meromorphic and analytic normally on tangential compact subsets. Every coefficient below the clearing order vanishes exactly in the full physical boundary columns, so analytic divisibility removes the scalar pole.",
  "JointCornerEnvelopeRequired"->True|>
];
VerifyUniformNormalCrossingPhysicalGerm[intersection_Association,matching_Association,scalar_Association,
 constantBounds_List,request_Association:<||>]:=Catch[Module[
 {xs,e,n,scaling,s,si,matrices,units,bad,residues,zeroEigenvalues,seed,exponents,check,
  valueBounds,seedBounds,qBounds,qRows,qMatrix,rowBounds,unitValues,coordinate,scalarField,scalarRestore,scalarUnits,scalarUnitValues,coordinateUnits,assumptions,cancel,report,progress,bound},
 If[Lookup[intersection,"Status",None]=!="ExactLogarithmicIntersectionEstablished"||
  Lookup[matching,"Status",None]=!="PhysicalJointBoundaryConstantsMatched"||
  !TrueQ[Lookup[scalar,"NormalizedScalarCoefficientsAnalyticAtCorner",False]]||
  intersection["OriginalMasterIntegralBasis"]=!=matching["MasterIntegralBasis"]||
  matching["MasterIntegralBasis"]=!=scalar["MasterIntegralBasis"],
  Throw[Failure["MatchedAnalyticNormalCrossingScalarGermRequired",<||>],"UniformCorner"]];
 {xs,e,n}=Lookup[intersection,{"KinematicVariables","DimensionalRegulator","Dimension"}];
 If[xs=!=matching["KinematicVariables"]||!VectorQ[constantBounds,IntegerQ]||
   Length[constantBounds]=!=matching["BoundaryConstantCount"],
  Throw[Failure["MatchedCornerCoordinatesAndConstantPoleBoundsRequired",<||>],"UniformCorner"]];
 progress=Lookup[request,"ProgressFunction",None];report[label_]:=If[progress=!=None,progress[label]];
 bound[value_]:=bound[value]=FeynFacet`DetermineMeromorphicLaurentLowerBound[value,e];
 report["RegulatorScaling"];
 cancel[m_]:=Module[{v=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[v],Throw[v,"UniformCorner"]];Partition[v,Last[Dimensions[m]]]];
 scaling=FeynFacet`FindEpsilonRescaling[Normal/@intersection["ConnectionMatrices"],e];
 If[!AssociationQ[scaling],Throw[scaling,"UniformCorner"]];
 {s,si}=Lookup[scaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}];
 report["ScaledConnections"];
 matrices=MapThread[cancel[#1 si.Normal[#2].s]&,{xs,intersection["ConnectionMatrices"]}];
 units=DeleteDuplicates[Denominator[Cancel[#]]&/@Flatten[matrices]];
 unitValues=Cancel[#/.Thread[Append[xs,e]->0]]&/@units;
 If[AnyTrue[unitValues,#===0||!FreeQ[#,Indeterminate|_DirectedInfinity]&],
  Throw[Failure["JointCoordinateRegulatorRegularityRequired",<||>],"UniformCorner"]];
 report["CornerResidues"];
 residues=Map[#/.Thread[xs->0]&,matrices];
 zeroEigenvalues=Table[Factor[CharacteristicPolynomial[residues[[i]]/.e->0,coordinate]]===(-coordinate)^n,{i,Length[xs]}];
 If[!And@@zeroEigenvalues,Throw[Failure["UniformNonresonantCornerFrameRequired",<|"ResiduesAtEpsilonZero"->(residues/.e->0),"CharacteristicPolynomials"->(CharacteristicPolynomial[#,coordinate]&/@(residues/.e->0))|>],"UniformCorner"]];
 seed=cancel[si.matching["OrderedConstantToCornerVectorMatrix"]];
 exponents=matching["JointResidueExponents"];
 check=Flatten[Table[cancel[residues[[i]].seed-exponents[[i]]seed],{i,Length[xs]}]];
 If[!AllTrue[check,#===0&],Throw[Failure["ExactPhysicalJointEigenvectorSeedRequired",<||>],"UniformCorner"]];
 report["SeedPoleBounds"];
 seedBounds=Table[Min[Map[bound,seed[[All,j]]]]+constantBounds[[j]],
   {j,Length[constantBounds]}];
 report["ScalarPoleEnvelope"];
 qMatrix=cancel[scalar["ScalarGaugeCoefficientMatrix"].s];
 (* The scalar rows were already certified analytic. A coordinate-independent
    regulator rescaling preserves this; re-expanding every entry adds no check. *)
 If[!FreeQ[{s,si},Alternatives@@xs],
  Throw[Failure["CoordinateIndependentRegulatorRescalingRequired",<||>],"UniformCorner"]];
 report["ScalarCoordinateAnalyticity"];
 (* Fixed-coordinate epsilon valuations do not imply joint meromorphy.
    After isolating coordinate-independent analytic prefactors, every rational
    denominator must be a pure epsilon power times a joint analytic unit. *)
 {scalarField,scalarRestore}=coefficientRationalFieldReduce[{qMatrix,seed}];
 If[!FreeQ[Last/@scalarRestore,Alternatives@@xs],
  Throw[Failure["CoordinateDependentScalarPoleEnvelopeUnresolved",<||>],"UniformCorner"]];
 bad=endpointMixedAnalyticDenominators[scalarField,scalarRestore,xs];
 If[bad=!={},Throw[Failure["MixedAnalyticCoordinateDenominatorNotSupported",
  <|"Factors"->(bad/.scalarRestore)|>],"UniformCorner"]];
 scalarUnits=DeleteDuplicates[Map[Function[den,Cancel[den/e^Exponent[den,e,Min]]],
   DeleteDuplicates[Denominator[Cancel[#]]&/@DeleteDuplicates[Flatten[scalarField]]]]];
 scalarUnitValues=Cancel[#/.Thread[Append[xs,e]->0]]&/@scalarUnits;
 If[AnyTrue[scalarUnitValues,#===0||!FreeQ[#,Indeterminate|_DirectedInfinity]&],
  Throw[Failure["JointMeromorphicScalarPoleEnvelopeRequired",<|"DenominatorUnits"->scalarUnits|>],"UniformCorner"]];
 report["ScalarLaurentBounds"];
 qBounds=Map[bound,qMatrix,{2}];
 If[!AllTrue[Join[seedBounds,Flatten[qBounds]],IntegerQ[#]||#===Infinity&],
  Throw[Failure["FiniteMeromorphicScalarSeedBoundsRequired",<||>],"UniformCorner"]];
 report["ParameterUnits"];
 coordinateUnits=DeleteDuplicates[endpointCoordinateUnitOrigins[
  {matrices,scalarField},xs,Thread[Append[xs,e]->0]]];
 assumptions=Lookup[request,"Assumptions",True];
 bad=Select[coordinateUnits,!TrueQ[FullSimplify[#!=0,assumptions]]&];
 If[bad=!={},Throw[Failure["CornerParameterUnitsUnresolved",
  <|"OriginValues"->bad,"Assumptions"->assumptions|>],"UniformCorner"]];
 report["UniformGermComplete"];
 rowBounds=Map[Min[#]+Min[seedBounds]&,qBounds];
 <|"DataType"->"UniformNormalCrossingPhysicalGerm","Status"->"UniformMeromorphicScalarGermEstablished",
  "CoordinateVariables"->xs,"DimensionalRegulator"->e,"JointResidueExponents"->exponents,
  "CoefficientRowLabels"->scalar["CoefficientRowLabels"],"CoefficientLaurentLowerBounds"->rowBounds,
  "ConstantLaurentLowerBounds"->constantBounds,"RegulatorRescaling"->scaling,
  "CoordinateUnitOriginValues"->coordinateUnits,"ParameterAssumptions"->assumptions,
  "NonzeroParameterConditions"->DeleteDuplicates[Select[unitValues,!NumericQ[#]&]],
  "Verification"-><|"JointEpsilonRegularLogarithmicConnections"->True,
    "NoPositiveIntegerResonancesAtEpsilonZero"->True,"ExactLogFreePhysicalSeed"->True,
    "AnalyticNormalizedPhysicalCoefficientRows"->True,"JointMeromorphicScalarAndSeedFactors"->True|>,
  "SourcePhysicalMatchingVerification"->matching["Verification"],
  "ConvergenceArgument"->"The flat logarithmic connection is jointly analytic in epsilon and the normal coordinates. At epsilon zero both residues have only zero eigenvalues, so every positive-degree Sylvester operator is invertible. The convergent Frobenius normalizer is analytic on a smaller common polydisc and epsilon disc. Its action on the exact joint eigenvector seed produces only the recorded scalar powers. Meromorphic input constants and rational gauges give the retained finite pole envelope.",
  "EndpointRemainderIntegrabilityInferred"->False|>
],"UniformCorner"];


VerifyNormalCrossingDivisorCollars[intersection_Association,matching_Association,scalar_Association,
 uniform_Association,request_Association:<||>]:=Module[
 {xs,e,parameters,ends,field,restore,parts,values,bad,conditions,reports},
 {xs,e}=Lookup[intersection,{"KinematicVariables","DimensionalRegulator"}];
 If[Lookup[intersection,"Status",None]=!="ExactLogarithmicIntersectionEstablished"||
  Lookup[uniform,"Status",None]=!="UniformMeromorphicScalarGermEstablished"||
  !TrueQ[Lookup[scalar,"NormalizedScalarCoefficientsAnalyticAtCorner",False]]||
  uniform["CoordinateVariables"]=!=xs||matching["KinematicVariables"]=!=xs||
  scalar["CoordinateVariables"]=!=xs||uniform["CoefficientRowLabels"]=!=scalar["CoefficientRowLabels"]||
  !And@@Thread[(Cancel[Together[#]]&/@(uniform["JointResidueExponents"]-matching["JointResidueExponents"]))==0],
  Return[Failure["MatchingUniformCornerCertificateAndScalarRowsRequired",<||>]]];
 parameters=Lookup[request,"Assumptions",True];
 ends=Lookup[request,"TangentialUpperBounds",{1,1}];
 If[Length[xs]=!=2||!FreeQ[parameters,Alternatives@@Append[xs,e]]||
  Length[ends]=!=2||!AllTrue[ends,MatchQ[#,_Integer|_Rational]&&#>0&],
  Return[Failure["PositiveDivisorIntervalsConnectedToTheCornerRequired",<||>]]];
 {field,restore}=coefficientRationalFieldReduce[{
   MapThread[#1 Normal[#2]&,{xs,intersection["ConnectionMatrices"]}],
   scalar["ScalarGaugeCoefficientMatrix"]}];
 If[!FreeQ[Last/@restore,Alternatives@@xs],
  Return[Failure["CoordinateIndependentMeromorphicFactorsRequired",<||>]]];
 parts=endpointCoordinateDenominatorParts[field,xs];
 reports=Table[
  conditions=parameters&&0<xs[[3-i]]<ends[[i]];
  values=DeleteDuplicates[Factor[#/.{xs[[i]]->0,e->0}]&/@parts];
  bad=Select[values,!TrueQ[FullSimplify[#!=0,conditions]]&];
  If[bad=!={},Return[Failure["OpenDivisorUnitFactorsUnresolved",
    <|"NormalVariable"->xs[[i]],"TangentialConditions"->conditions,"Factors"->bad|>],Module]];
  <|"NormalVariable"->xs[[i]],"TangentialVariable"->xs[[3-i]],
   "TangentialConditions"->conditions,"CoordinateDenominatorOriginValues"->values,
   "NormalExponent"->matching["JointResidueExponents"][[i]],
   "CoefficientLaurentLowerBounds"->uniform["CoefficientLaurentLowerBounds"]|>,
 {i,2}];
 <|"DataType"->"UniformNormalCrossingDivisorCollars","Status"->"UniformDivisorCollarsEstablished",
  "CoordinateVariables"->xs,"CoefficientRowLabels"->scalar["CoefficientRowLabels"],
  "NormalizationFactor"->scalar["NormalizationFactor"],"DivisorCollars"->reports,
  "Argument"->"The checked denominator units extend the same epsilon-regular logarithmic frame and normalized scalar rows to every tangential compact subset of the declared intervals. Flatness makes the radial residue horizontal under the tangential connection, preserving its spectrum and the exactly matched physical eigenspace. Nonresonance and the finite meromorphic input bound established at the corner therefore extend by analytic parameter-dependent ODE transport. The radial Frobenius germ is uniformly analytic after the recorded normalization.",
  "Scope"->"Uniformity of the recorded normalized scalar germ. Vanishing restrictions or complete pole-coefficient cancellations are still needed before claiming an integrable or removable unnormalized density."|>
];
VerifyRadialEndpointCollar[endpoint_Association,values_Association,rows_Association,request_Association]:=Catch[Module[
 {r,t,e,n,basis,rules,norm,conditions,scaling,s,si,mats,matrix,field,restore,q,seed,
  denominators,units,unitValues,bad,orders,residue,lambda,cancel,leading,logDerivative,factors,parameterUnits,boundaryConnection,boundaryScaling,boundaryS,boundarySI,boundaryMatrix,coordinateUnits},
 {r,t,e,n}=Lookup[endpoint,{"NormalVariable","TangentialVariable","DimensionalRegulator","Dimension"}];
 basis=endpoint["OriginalMasterIntegralBasis"];
 If[!MemberQ[{"PhysicalEndpointBoundaryValuesDetermined","PhysicalEndpointBoundarySystemConstructed"},Lookup[values,"Status",None]]||
   values["MasterIntegralBasis"]=!=basis||!AllTrue[Values[rows],AssociationQ[#]&&ContainsAll[basis,Keys[#]]&],
  Throw[Failure["CompletePhysicalEndpointRowsRequired",<||>],"RadialCollar"]];
 {rules,norm,conditions}=Lookup[request,{"KinematicRules","NormalizationFactor","TangentialConditions"},None];
 If[MemberQ[{rules,norm,conditions},None]||!FreeQ[conditions,r|e],
  Throw[Failure["ExplicitRadialCollarGeometryRequired",<||>],"RadialCollar"]];
 cancel[m_]:=Module[{v=FeynFacet`CancelRationalCoefficients[Flatten[Normal[m]]]},
  If[!ListQ[v],Throw[v,"RadialCollar"]];Partition[v,Last[Dimensions[m]]]];
 mats=Normal/@Lookup[endpoint,{"NormalizedNormalConnectionMatrix","NormalizedTangentialConnectionMatrix"}];
 scaling=FeynFacet`FindEpsilonRescaling[mats,e];If[!AssociationQ[scaling],Throw[scaling,"RadialCollar"]];
 {s,si}=Lookup[scaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}];
 mats={cancel[r si.mats[[1]].s],cancel[si.mats[[2]].s]};
 matrix=Table[Lookup[rows[label],Key[master],0],{label,Keys[rows]},{master,basis}];
 {field,restore}=coefficientRationalFieldReduce[matrix/.rules];
 If[!FreeQ[Last/@restore,r|t],Throw[Failure["CoordinateDependentAnalyticPrefactorRequiresCollarProof",<||>],"RadialCollar"]];
 q=cancel[norm field.endpoint["NormalGaugeMatrix"].s];
 bad=endpointMixedAnalyticDenominators[q,restore,{r,t}];
 If[bad=!={},Throw[Failure["MixedAnalyticCoordinateDenominatorNotSupported",
  <|"Factors"->(bad/.restore)|>],"RadialCollar"]];
 If[values["Status"]==="PhysicalEndpointBoundarySystemConstructed",
  boundaryConnection=Normal[values["ConnectionMatrix"]];
  boundaryScaling=FeynFacet`FindEpsilonRescaling[{boundaryConnection},e];
  If[!AssociationQ[boundaryScaling],Throw[boundaryScaling,"RadialCollar"]];
  {boundaryS,boundarySI}=Lookup[boundaryScaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}];
  boundaryConnection=cancel[boundarySI.boundaryConnection.boundaryS];
  boundaryMatrix=values["NormalizedLeadingVectorEmbedding"].boundaryS,
  boundaryMatrix=values["RationalCoefficientMatrix"];
  boundaryConnection=(values["TangentialRegulatorExponent"]/t+
    Lookup[values,"TangentialAnalyticLogDerivative",0])IdentityMatrix[Last[Dimensions[boundaryMatrix]]]
 ];
 seed=cancel[si.boundaryMatrix];
 If[!AllTrue[Flatten[cancel[D[seed,t]+seed.boundaryConnection-(mats[[2]]/.r->0).seed]],#===0&],
  Throw[Failure["ExactPhysicalTangentialCollarEquationRequired",<||>],"RadialCollar"]];
 orders=If[#===0,Infinity,Exponent[Numerator[#],r,Min]-Exponent[Denominator[#],r,Min]]&/@Flatten[q];
 If[!AllTrue[orders,#>=0&],Throw[Failure["ScalarRadialCollarPolesUnresolved",<|"Orders"->orders|>],"RadialCollar"]];
 denominators=DeleteDuplicates[Denominator[Cancel[#]]&/@Flatten[{q,seed}]];
 units=Cancel[#/e^Exponent[#,e,Min]]&/@denominators;
 units=Join[units,DeleteDuplicates[Denominator[Cancel[#]]&/@Flatten[{mats,boundaryConnection}]]];
 unitValues=Factor[#/.{r->0,e->0}]&/@units;
 factors=DeleteDuplicates[Flatten[Map[Function[value,
   First/@Rest[FactorList[value]]],unitValues]]];
 parameterUnits=Select[factors,FreeQ[#,t]&];
 bad=Select[Select[factors,!FreeQ[#,t]&],!TrueQ[FullSimplify[#!=0,conditions]]&];
 If[MemberQ[unitValues,0],AppendTo[bad,0]];
 If[bad=!={},Throw[Failure["RadialCollarUnitFactorsUnresolved",<|"Factors"->bad|>],"RadialCollar"]];
 coordinateUnits=DeleteDuplicates[endpointCoordinateUnitOrigins[
  {q,seed,mats,boundaryConnection},{r,t},{r->0,e->0}]];
 bad=Select[coordinateUnits,!TrueQ[FullSimplify[#!=0,conditions]]&];
 If[bad=!={},Throw[Failure["RadialCollarParameterUnitsUnresolved",
  <|"OriginValues"->bad,"TangentialConditions"->conditions|>],"RadialCollar"]];
 residue=mats[[1]]/.r->0;
 If[Factor[CharacteristicPolynomial[residue/.e->0,lambda]]=!=(-lambda)^n,
  Throw[Failure["NonresonantRadialCollarFrameRequired",<||>],"RadialCollar"]];
 lambda=values["NormalExponent"];
 If[!AllTrue[Flatten[cancel[residue.seed-lambda seed]],#===0&],
  Throw[Failure["PhysicalRadialCollarSeedRequired",<||>],"RadialCollar"]];
 leading=cancel[(q/.r->0).seed]/.restore;
 <|"DataType"->"UniformRadialEndpointCollar","Status"->"UniformMeromorphicRadialCollarEstablished",
  "NormalVariable"->r,"TangentialVariable"->t,"TangentialConditions"->conditions,
  "CoefficientRowLabels"->Keys[rows],"RadialExponent"->lambda,
  "LeadingScalarCoefficientMatrix"->leading,
  "TangentialRegulatorExponent"->Lookup[values,"TangentialRegulatorExponent",None],
  "TangentialAnalyticFactor"->Lookup[values,"TangentialAnalyticFactor",1],
  "InitialConstantValues"->values["InitialConstantValues"],"RegulatorRescaling"->scaling,
  "NonzeroParameterFactors"->(parameterUnits/.restore),
  "CoordinateUnitOriginValues"->coordinateUnits,
  "Verification"-><|"CompleteScalarRowsAnalyticNormally"->True,
    "JointRegulatorCoordinateUnitsOnTangentialCompacts"->True,"NonresonantRadialResidue"->True,
    "ExactPhysicalRadialSeed"->True|>,
  "Argument"->"The compatible radial Frobenius normalizer is analytic uniformly on sufficiently small normal and epsilon discs over each compact tangential interval. The exact physical eigenvector retains only the recorded radial power. Rational scalar and seed factors have only finite epsilon poles and analytic units."|>
],"RadialCollar"];

End[];EndPackage[];
