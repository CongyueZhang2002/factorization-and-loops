(* Correlated moments of an orthogonal projection at fixed full transverse Gram
   matrix. The polynomial identity is continued rationally in its dimensions;
   the caller must leave only rotation-invariant factors outside this average. *)
BeginPackage["FeynFacet`"];
AverageEvanescentScalarProducts::usage="AverageEvanescentScalarProducts[polynomial,kappaMatrix,transverseGram,epsilon,physicalRank] averages the complete polynomial in signed evanescent scalar products of any number of vectors. The full transverse Gram matrix is held fixed, with ambient dimension 4-physicalRank-2 epsilon and projected dimension -2 epsilon. This is an angular integral identity, not a pointwise replacement. All remaining integration weights and constraints must be invariant under simultaneous transverse rotations. The two-argument form AverageEvanescentScalarProducts[expression,request] constructs the transverse Gram matrix from declared physical and integrated momenta, validates a timelike physical span, and preserves ordinary full-D propagators.";
Begin["`Private`"];
angularAverageFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"AngularAverage"];
orthogonalPairings[{}]:={{}};
orthogonalPairings[labels_List]:=Flatten[Table[
 Prepend[#,{First[labels],labels[[j]]}]&/@orthogonalPairings[Delete[Rest[labels],j-1]],
 {j,2,Length[labels]}],1];
orthogonalPairingType[first_List,second_List]:=Reverse[Sort[
 Length[#]/2&/@ConnectedComponents[Graph[UndirectedEdge@@@Join[first,second]]]]];
(* Symmetry under permutation of projection factors and their two indices
   reduces (2m-1)!! tensor coefficients to p(m) unknowns. Contracting with a
   pairing gives h^(number of closed projector traces); metric contractions
   give n^(number of loops). Solve this small exact Gram system once. *)
orthogonalProjectionMomentData[degree_Integer?Positive]:=
 orthogonalProjectionMomentData[degree]=Module[
 {pairings,standard,grouped,types,groups,representatives,matrix,right,coefficients},
 pairings=orthogonalPairings[Range[2degree]];standard=Partition[Range[2degree],2];
 grouped=GroupBy[pairings,orthogonalPairingType[standard,#]&];
 types=Keys[grouped];groups=Values[grouped];representatives=First/@groups;
 matrix=Table[Total[($angularAmbientDimension^Length[orthogonalPairingType[representatives[[i]],#]]&)/@groups[[j]]],
  {i,Length[groups]},{j,Length[groups]}];
 right=($angularProjectedDimension^Length[#]&)/@types;
 coefficients=Factor/@LinearSolve[matrix,right];
 <|"PairingGroups"->groups,"Coefficients"->coefficients,"PartitionTypes"->types|>
];
(* Only the evanescent variables are expanded. Maximal coefficient-field
   subexpressions stay opaque until coefficient extraction has finished. *)
angularCompactPolynomial[value_]:=If[ByteCount[value]<1024^2,Factor[value],value];
AverageEvanescentScalarProducts[expression_,kappa_List,gram_List,e_Symbol,physicalRank_Integer:2]:=
 Catch[Module[{size,positions,variables,rational,numerator,denominator,terms,ambient,projected,moment,average},
 size=Length[kappa];
 If[!MemberQ[Range[1,4],physicalRank]||size===0||Dimensions[kappa]=!={size,size}||
  Dimensions[gram]=!={size,size}||kappa=!=Transpose[kappa]||gram=!=Transpose[gram],
  angularAverageFail["SymmetricProjectionAndTransverseGramMatricesRequired"]];
 positions=Flatten[Table[{i,j},{i,size},{j,i,size}],1];variables=Extract[kappa,#]&/@positions;
 If[!MatchQ[variables,{_Symbol..}]||!DuplicateFreeQ[variables]||MemberQ[variables,e]||
  !FreeQ[gram,Alternatives@@Append[variables,e]]||
  !FreeQ[{expression,gram},_Real|_Failure|_Missing|$Failed|$Aborted|Indeterminate|_DirectedInfinity],
  angularAverageFail["ExactIndependentEvanescentScalarProductsRequired"]];
 terms=FeynFacet`PolynomialCoefficientRules[expression,variables];
 If[FailureQ[terms],angularAverageFail["PolynomialEvanescentDependenceRequired"]];
 If[physicalRank===4,Return[angularCompactPolynomial[expression/.Thread[variables->(Extract[gram,#]&/@positions)]]]];
 ambient=4-physicalRank-2e;projected=-2e;
 moment[powers_List]:=moment[powers]=Module[{degree=Total[powers],labels,data,weights},
  If[degree===0,Return[1]];
  labels=Flatten[MapThread[ConstantArray,{positions,powers}],2];
  data=orthogonalProjectionMomentData[degree];
  weights=Total[Function[pairing,Times@@(gram[[labels[[#[[1]]]],labels[[#[[2]]]]]]&/@pairing)]/@#]&/@data["PairingGroups"];
  Factor[(data["Coefficients"].weights)/.{$angularAmbientDimension->ambient,$angularProjectedDimension->projected}]
 ];
 average=Total[(Last[#]moment[First[#]]&)/@terms];
 angularCompactPolynomial[average]
],"AngularAverage"];
angularLinearMomentumQ[expression_,momenta_List]:=PolynomialQ[expression,momenta]&&
 TrueQ[(expression/.Thread[momenta->0])===0]&&
 AllTrue[First/@CoefficientRules[expression,momenta],Total[#]<=1&];
angularFullDimensionPropagatorQ[denominator_,momenta_List]:=Module[{objects},
 objects=DeleteDuplicates[Cases[denominator,_FeynCalc`Momentum,Infinity]];
 FreeQ[denominator,_FeynCalc`LorentzIndex|_FeynCalc`Eps]&&
 AllTrue[objects,MatchQ[#,FeynCalc`Momentum[_,D]]&&angularLinearMomentumQ[First[#],momenta]&]
];
AverageEvanescentScalarProducts[expression_,request_Association]:=Catch[Module[
 {physical,integrated,all,e,assumptions,kinematics,momentumRules,witness,physicalGram,determinant,
  witnessCoefficients,size,kappa,indices,hat,rules,expanded,denominators,denominatorSymbols,
  scalar,projections,transverseGram,regulator,averaged,degree,variables,polynomialCoefficients},
 If[!ContainsAll[Keys[request],{"PhysicalMomenta","IntegratedMomenta","KinematicRules",
  "TimelikeMomentum","DimensionalRegulator","Assumptions"}],angularAverageFail["JointAngularGeometryRequired"]];
 {physical,integrated,e,assumptions,witness}=Lookup[request,
  {"PhysicalMomenta","IntegratedMomenta","DimensionalRegulator","Assumptions","TimelikeMomentum"}];
 all=Join[physical,integrated];size=Length[integrated];
 If[!MatchQ[physical,{_Symbol..}]||!MatchQ[integrated,{_Symbol..}]||
  !MemberQ[Range[1,4],Length[physical]]||!DuplicateFreeQ[all]||!MatchQ[e,_Symbol]||
  MemberQ[all,e]||!angularLinearMomentumQ[witness,physical],
  angularAverageFail["IndependentPhysicalAndIntegratedMomentaRequired"]];
 momentumRules=Lookup[request,"MomentumRules",{}];kinematics=FeynCalc`FCI[request["KinematicRules"]];
 If[!MatchQ[kinematics,{(_Rule)...}]||!AllTrue[kinematics,
  MatchQ[First[#],_FeynCalc`Pair]&&
  AllTrue[Cases[First[#],FeynCalc`Momentum[m_,___]:>m,Infinity],MemberQ[physical,#]&]&],
  angularAverageFail["PhysicalSpanScalarProductRulesRequired"]];
 physicalGram=FullSimplify[FeynCalc`FCI[Outer[FeynCalc`SPD,physical,physical]]/.kinematics,
  Assumptions->assumptions];
 If[!FreeQ[physicalGram,_FeynCalc`Pair|e|_Real|_Failure|_Missing|Indeterminate|_DirectedInfinity],
  angularAverageFail["ExactPhysicalGramMatrixRequired"]];
 determinant=Factor[Det[physicalGram]];
 witnessCoefficients=Coefficient[witness,#]&/@physical;
 If[!TrueQ[FullSimplify[determinant!=0&&witnessCoefficients.physicalGram.witnessCoefficients>0,
   Assumptions->assumptions]],angularAverageFail["NondegeneratePhysicalSpanWithTimelikeDirectionRequired"]];
 kappa=ConstantArray[0,{size,size}];
 Do[kappa[[i,j]]=kappa[[j,i]]=Unique["evanescentScalarProduct$"],{i,size},{j,i,size}];
 indices=AssociationThread[integrated,Range[size]];
 hat[a_,b_]:=If[MemberQ[physical,a]||MemberQ[physical,b],0,kappa[[indices[a],indices[b]]]];
 rules=Flatten[Table[{
  FeynCalc`Pair[FeynCalc`Momentum[a],FeynCalc`Momentum[b]]->
   FeynCalc`Pair[FeynCalc`Momentum[a,D],FeynCalc`Momentum[b,D]]-hat[a,b],
  FeynCalc`Pair[FeynCalc`Momentum[a,D-4],FeynCalc`Momentum[b,D-4]]->hat[a,b]},
 {a,all},{b,all}],2];
 expanded=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[expression]/.momentumRules];
 denominators=DeleteDuplicates[Cases[expanded,_FeynCalc`FeynAmpDenominator,{0,Infinity}]];
 If[!AllTrue[denominators,angularFullDimensionPropagatorQ[#,all]&],
  angularAverageFail["JointRotationInvariantPropagatorsRequired"]];
 denominatorSymbols=Unique["fullDimensionalPropagator$"]&/@denominators;
 scalar=(expanded/.Thread[denominators->denominatorSymbols])/.rules/.kinematics;
 If[!FreeQ[scalar,_FeynCalc`Eps|_FeynCalc`LorentzIndex|_FeynCalc`DiracTrace|_FeynCalc`DiracGamma|
   _FeynCalc`DOT|_FeynCalc`Spinor|_FeynCalc`Polarization|_FeynCalc`SUNIndex|_FeynCalc`SUNFIndex]||
  !AllTrue[Cases[scalar,_FeynCalc`Momentum,Infinity],
   MatchQ[#,FeynCalc`Momentum[_,D]]&&MemberQ[all,First[#]]&],
  angularAverageFail["FullyContractedDeclaredJointAngularScalarRequired"]];
 projections=FeynCalc`FCI[Outer[FeynCalc`SPD,integrated,physical]]/.kinematics;
 transverseGram=FeynCalc`FCI[Outer[FeynCalc`SPD,integrated,integrated]]-
  projections.Inverse[physicalGram].Transpose[projections];
 transverseGram=Map[Factor,transverseGram,{2}];
 variables=DeleteDuplicates[Flatten[kappa]];
 If[FreeQ[scalar,Alternatives@@variables],
  Return[<|"Value"->(scalar/.Thread[denominatorSymbols->denominators]),
   "PhysicalGramMatrix"->physicalGram,"TransverseGramMatrix"->transverseGram,
   "PhysicalMomenta"->physical,"IntegratedMomenta"->integrated,"EvanescentPolynomialDegree"->0,
   "DimensionalRegulator"->e,"DimensionRule"->(D->4-2e),"PreservedPropagators"->denominators,
   "Scope"->"Full-D scalar integrand is already invariant under the joint transverse rotation."|>]];
 polynomialCoefficients=FeynFacet`PolynomialCoefficientRules[scalar,variables];
 If[FailureQ[polynomialCoefficients],Throw[polynomialCoefficients,"AngularAverage"]];
 degree=Max[Prepend[Total/@(First/@polynomialCoefficients),0]];
 regulator=Unique["angularRegulator$"];
 averaged=AverageEvanescentScalarProducts[scalar,kappa,transverseGram,regulator,Length[physical]];
 If[FailureQ[averaged],Throw[averaged,"AngularAverage"]];
 (* Retain FeynCalc's D-dimensional momentum labels for IBP. The scalar
    coefficient dimension is converted by the ordinary coefficient stage. *)
 averaged=(averaged/.regulator->(4-D)/2)/.Thread[denominatorSymbols->denominators];
 <|"Value"->averaged,"PhysicalGramMatrix"->physicalGram,"TransverseGramMatrix"->transverseGram,
  "PhysicalMomenta"->physical,"IntegratedMomenta"->integrated,"EvanescentPolynomialDegree"->degree,
  "DimensionalRegulator"->e,"DimensionRule"->(D->4-2e),"PreservedPropagators"->denominators,
  "Scope"->"Combined integral under simultaneous transverse rotations at fixed full-D scalar products; causal prescriptions are retained."|>
],"AngularAverage"];
End[];EndPackage[];
