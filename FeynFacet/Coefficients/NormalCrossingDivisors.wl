(* Rational scalar coefficients must be checked in the same logarithmic
   frame as the master system. A master DE alone cannot resolve their poles. *)
BeginPackage["FeynFacet`"];
AnalyzeNormalCrossingScalarCoefficients::usage="AnalyzeNormalCrossingScalarCoefficients[intersection,rows,request] contracts the exact physical coefficient rows with a verified logarithmic gauge and an explicit normalization factor. It reports all coordinate valuations and rejects no non-coordinate divisor silently. It does not by itself prove cancellation against a physical solution.";
VerifyUniformNormalCrossingPhysicalGerm::usage="VerifyUniformNormalCrossingPhysicalGerm[intersection,matching,scalarCoefficients,constantLowerBounds] verifies an epsilon-regular logarithmic frame, nonresonance at epsilon zero, the selected joint eigenvector seed, and finite Laurent bounds for the normalized scalar germ. The source matching must describe the complete physical germ.";
VerifyRadialEndpointCollar::usage="VerifyRadialEndpointCollar[endpoint,values,rows,request] checks an epsilon-regular radial logarithmic system, complete normalized scalar rows and its physical leading vector uniformly on compact subsets of a declared open tangential interval.";
Begin["`Private`"];
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

VerifyUniformNormalCrossingPhysicalGerm[intersection_Association,matching_Association,scalar_Association,
 constantBounds_List]:=Catch[Module[
 {xs,e,n,scaling,s,si,matrices,units,bad,residues,zeroEigenvalues,seed,exponents,check,
  valueBounds,seedBounds,qBounds,qRows,qMatrix,rowBounds,unitValues,coordinate,scalarField,scalarRestore,scalarUnits,scalarUnitValues},
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
 scaling=FeynFacet`FindEpsilonRescaling[Normal/@intersection["ConnectionMatrices"],e];
 If[!AssociationQ[scaling],Throw[scaling,"UniformCorner"]];
 {s,si}=Lookup[scaling,{"BasisTransformationMatrix","InverseBasisTransformationMatrix"}];
 matrices=MapThread[Map[Cancel,#1 si.Normal[#2].s,{2}]&,{xs,intersection["ConnectionMatrices"]}];
 units=DeleteDuplicates[Denominator[Cancel[#]]&/@Flatten[matrices]];
 unitValues=Cancel[#/.Thread[Append[xs,e]->0]]&/@units;
 If[AnyTrue[unitValues,#===0||!FreeQ[#,Indeterminate|_DirectedInfinity]&],
  Throw[Failure["JointCoordinateRegulatorRegularityRequired",<||>],"UniformCorner"]];
 residues=Map[#/.Thread[xs->0]&,matrices];
 zeroEigenvalues=Table[Factor[CharacteristicPolynomial[residues[[i]]/.e->0,coordinate]]===(-coordinate)^n,{i,Length[xs]}];
 If[!And@@zeroEigenvalues,Throw[Failure["UniformNonresonantCornerFrameRequired",<|"ResiduesAtEpsilonZero"->(residues/.e->0),"CharacteristicPolynomials"->(CharacteristicPolynomial[#,coordinate]&/@(residues/.e->0))|>],"UniformCorner"]];
 seed=Map[Cancel,si.matching["OrderedConstantToCornerVectorMatrix"],{2}];
 exponents=matching["JointResidueExponents"];
 check=Flatten[Table[Map[Cancel,residues[[i]].seed-exponents[[i]]seed,{2}],{i,Length[xs]}]];
 If[!AllTrue[check,#===0&],Throw[Failure["ExactPhysicalJointEigenvectorSeedRequired",<||>],"UniformCorner"]];
 seedBounds=Table[Min[Map[FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&,seed[[All,j]]]]+constantBounds[[j]],
   {j,Length[constantBounds]}];
 qMatrix=scalar["ScalarGaugeCoefficientMatrix"].s;
 If[!AllTrue[Flatten[qMatrix],Function[value,value===0||And@@Table[
   Exponent[Numerator[Together[value]],x,Min]-Exponent[Denominator[Together[value]],x,Min]>=0,{x,xs}]]],
  Throw[Failure["AnalyticScalarCoordinateRowsRequired",<||>],"UniformCorner"]];
 (* Fixed-coordinate epsilon valuations do not imply joint meromorphy.
    After isolating coordinate-independent analytic prefactors, every rational
    denominator must be a pure epsilon power times a joint analytic unit. *)
 {scalarField,scalarRestore}=coefficientRationalFieldReduce[{qMatrix,seed}];
 If[!FreeQ[Last/@scalarRestore,Alternatives@@xs],
  Throw[Failure["CoordinateDependentScalarPoleEnvelopeUnresolved",<||>],"UniformCorner"]];
 scalarUnits=DeleteDuplicates[Map[Function[value,Module[{den=Denominator[Cancel[value]],power},
   power=Exponent[den,e,Min];Cancel[den/e^power]]],Flatten[scalarField]]];
 scalarUnitValues=Cancel[#/.Thread[Append[xs,e]->0]]&/@scalarUnits;
 If[AnyTrue[scalarUnitValues,#===0||!FreeQ[#,Indeterminate|_DirectedInfinity]&],
  Throw[Failure["JointMeromorphicScalarPoleEnvelopeRequired",<|"DenominatorUnits"->scalarUnits|>],"UniformCorner"]];
 qBounds=Map[FeynFacet`DetermineMeromorphicLaurentLowerBound[#,e]&,qMatrix,{2}];
 If[!AllTrue[Join[seedBounds,Flatten[qBounds]],IntegerQ[#]||#===Infinity&],
  Throw[Failure["FiniteMeromorphicScalarSeedBoundsRequired",<||>],"UniformCorner"]];
 rowBounds=Map[Min[#]+Min[seedBounds]&,qBounds];
 <|"DataType"->"UniformNormalCrossingPhysicalGerm","Status"->"UniformMeromorphicScalarGermEstablished",
  "CoordinateVariables"->xs,"DimensionalRegulator"->e,"JointResidueExponents"->exponents,
  "CoefficientRowLabels"->scalar["CoefficientRowLabels"],"CoefficientLaurentLowerBounds"->rowBounds,
  "ConstantLaurentLowerBounds"->constantBounds,"RegulatorRescaling"->scaling,
  "NonzeroParameterConditions"->DeleteDuplicates[Select[unitValues,!NumericQ[#]&]],
  "Verification"-><|"JointEpsilonRegularLogarithmicConnections"->True,
    "NoPositiveIntegerResonancesAtEpsilonZero"->True,"ExactLogFreePhysicalSeed"->True,
    "AnalyticNormalizedPhysicalCoefficientRows"->True,"JointMeromorphicScalarAndSeedFactors"->True|>,
  "SourcePhysicalMatchingVerification"->matching["Verification"],
  "ConvergenceArgument"->"The flat logarithmic connection is jointly analytic in epsilon and the normal coordinates. At epsilon zero both residues have only zero eigenvalues, so every positive-degree Sylvester operator is invertible. The convergent Frobenius normalizer is analytic on a smaller common polydisc and epsilon disc. Its action on the exact joint eigenvector seed produces only the recorded scalar powers. Meromorphic input constants and rational gauges give the retained finite pole envelope.",
  "EndpointRemainderIntegrabilityInferred"->False|>
],"UniformCorner"];

VerifyRadialEndpointCollar[endpoint_Association,values_Association,rows_Association,request_Association]:=Catch[Module[
 {r,t,e,n,basis,rules,norm,conditions,scaling,s,si,mats,matrix,field,restore,q,seed,
  denominators,units,unitValues,bad,orders,residue,lambda,cancel,leading,logDerivative,factors,parameterUnits,boundaryConnection,boundaryScaling,boundaryS,boundarySI,boundaryMatrix},
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
  "Verification"-><|"CompleteScalarRowsAnalyticNormally"->True,
    "JointRegulatorCoordinateUnitsOnTangentialCompacts"->True,"NonresonantRadialResidue"->True,
    "ExactPhysicalRadialSeed"->True|>,
  "Argument"->"The compatible radial Frobenius normalizer is analytic uniformly on sufficiently small normal and epsilon discs over each compact tangential interval. The exact physical eigenvector retains only the recorded radial power. Rational scalar and seed factors have only finite epsilon poles and analytic units."|>
],"RadialCollar"];

End[];EndPackage[];
