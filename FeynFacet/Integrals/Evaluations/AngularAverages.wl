(* Correlated moments of an orthogonal projection at fixed full transverse Gram
   matrix. The polynomial identity is continued rationally in its dimensions;
   the caller must leave only rotation-invariant factors outside this average. *)
BeginPackage["FeynFacet`"];
AverageEvanescentScalarProducts::usage="AverageEvanescentScalarProducts[polynomial,kappaMatrix,transverseGram,epsilon,physicalRank] averages the complete polynomial in signed evanescent scalar products of any number of vectors. The full transverse Gram matrix is held fixed, with ambient dimension 4-physicalRank-2 epsilon and projected dimension -2 epsilon. This is an angular integral identity, not a pointwise replacement. All remaining integration weights and constraints must be invariant under simultaneous transverse rotations. The two-argument form AverageEvanescentScalarProducts[expression,request] constructs the transverse Gram matrix from declared physical and integrated momenta, validates a timelike physical span, and preserves ordinary full-D propagators.";
AverageSingleNormalNumerator::usage="AverageSingleNormalNumerator[expression,request] integrates polynomial dependence on one physical spacelike unit normal to the external momentum span by rotational tensor identities. There must be one IntegratedMomentum, a NormalMomentum orthogonal to PhysicalMomenta, full-D scalar products, and propagators independent of the normal. Even moments use Pochhammer[1/2,n]/Pochhammer[(D-rank)/2,n]; odd moments vanish.";
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
angularCompactPolynomial[value_]:=FactorTerms[value];
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
  scalar,projections,transverseGram,regulator,averaged,degree,variables,polynomialCoefficients,scalarProducts,images,unitRules},
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
 unitRules=Lookup[request,"UnitCutScalarProductRules",{}];
 If[!AllTrue[momentumRules,MatchQ[#,_Rule]&&angularLinearMomentumQ[Last[#],all]&],
  angularAverageFail["LinearMomentumRulesInDeclaredSpanRequired"]];
 FeynFacet`DeclareScalar[Flatten[Table[Coefficient[Expand[Last[rule]],v],{rule,momentumRules},{v,all}]]];
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
 expanded=FeynCalc`FCI[expression];
 denominators=DeleteDuplicates[Cases[expanded,_FeynCalc`FeynAmpDenominator,{0,Infinity}]];
 denominatorSymbols=Unique["fullDimensionalPropagator$"]&/@denominators;
 scalar=expanded/.Thread[denominators->denominatorSymbols];
 denominators=denominators/.momentumRules;
 If[!AllTrue[denominators,angularFullDimensionPropagatorQ[#,all]&],
  angularAverageFail["JointRotationInvariantPropagatorsRequired"]];
 (* Expand each distinct scalar product once. Expanding the complete amplitude
    first repeats the same linear spin-frame substitution in every trace term. *)
 scalarProducts=DeleteDuplicates[Cases[scalar,_FeynCalc`Pair,{0,Infinity}]];
 images=Factor[(FeynCalc`ExpandScalarProduct[#/.momentumRules]/.rules/.kinematics)/.unitRules]&/@scalarProducts;
 scalar=scalar/.Dispatch[Thread[scalarProducts->images]];
 If[!FreeQ[scalar,_FeynCalc`Eps|_FeynCalc`LorentzIndex|_FeynCalc`DiracTrace|_FeynCalc`DiracGamma|
   _FeynCalc`DOT|_FeynCalc`Spinor|_FeynCalc`Polarization|_FeynCalc`SUNIndex|_FeynCalc`SUNFIndex]||
  !AllTrue[Cases[scalar,_FeynCalc`Momentum,Infinity],
   MatchQ[#,FeynCalc`Momentum[_,D]]&&MemberQ[all,First[#]]&],
  angularAverageFail["FullyContractedDeclaredJointAngularScalarRequired",<|
   "UndeclaredMomenta"->DeleteDuplicates[Select[Cases[scalar,_FeynCalc`Momentum,Infinity],
    !(MatchQ[#,FeynCalc`Momentum[_,D]]&&MemberQ[all,First[#]])&]],
   "ResidualTensorHeads"->DeleteDuplicates[Head/@Cases[scalar,
    _FeynCalc`Eps|_FeynCalc`LorentzIndex|_FeynCalc`DiracTrace|_FeynCalc`DiracGamma|
    _FeynCalc`DOT|_FeynCalc`Spinor|_FeynCalc`Polarization|_FeynCalc`SUNIndex|_FeynCalc`SUNFIndex,Infinity]]|>]];
 projections=FeynCalc`FCI[Outer[FeynCalc`SPD,integrated,physical]]/.kinematics;
 transverseGram=FeynCalc`FCI[Outer[FeynCalc`SPD,integrated,integrated]]-
  projections.Inverse[physicalGram].Transpose[projections];
 transverseGram=Map[Factor,transverseGram/.unitRules,{2}];
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
AverageSingleNormalNumerator[expression_,request_Association]:=Catch[Module[
 {base,loop,normal,kin,conditions,gram,projections,transverse,y=Unique["normalComponent$"],
  value,terms,denominators,moment,rank,sp},
 {base,loop,normal,kin,conditions}=Lookup[request,
  {"PhysicalMomenta","IntegratedMomentum","NormalMomentum","KinematicRules","Assumptions"},None];
 If[!MatchQ[base,{__Symbol}]||!MemberQ[Range[1,3],Length[base]]||
   !MatchQ[{loop,normal},{_Symbol,_Symbol}]||!DuplicateFreeQ[Join[base,{loop,normal}]],
  angularAverageFail["IndependentPhysicalSpanAndOneNormalRequired"]];
 rank=Length[base];kin=FeynCalc`FCI[kin];
 sp[a_,b_]:=FeynCalc`FCI[FeynCalc`SPD[a,b]];
 gram=FullSimplify[Outer[sp,base,base]/.kin,conditions];
 If[!FreeQ[gram,_FeynCalc`Pair]||!TrueQ[FullSimplify[Det[gram]!=0&&
   (sp[normal,normal]/.kin)==-1&&And@@((#==0&)/@(sp[normal,#]&/@base/.kin)),conditions]],
  angularAverageFail["NormalizedOrthogonalPhysicalNormalRequired"]];
 value=FeynCalc`FCI[expression];
 If[!AllTrue[Cases[value,_FeynCalc`Momentum,Infinity],MatchQ[#,FeynCalc`Momentum[_,D]]&],
  angularAverageFail["FullDimensionScalarProductsBeforeNormalAverageRequired"]];
 denominators=DeleteDuplicates[Cases[value,_FeynCalc`FeynAmpDenominator,{0,Infinity}]];
 If[!AllTrue[denominators,angularFullDimensionPropagatorQ[#,Append[base,loop]]&],
  angularAverageFail["PropagatorsIndependentOfPhysicalNormalRequired"]];
 projections=sp[loop,#]&/@base;
 transverse=Factor[(sp[loop,loop]-projections.Inverse[gram].projections)/.Lookup[request,"UnitCutScalarProductRules",{}]];
 value=value/.sp[loop,normal]->y;
 If[!FreeQ[value,normal],angularAverageFail["OnlyIntegratedMomentumMayContractNormal"]];
 terms=FeynFacet`PolynomialCoefficientRules[value,{y}];
 If[FailureQ[terms],angularAverageFail["PolynomialNormalNumeratorRequired"]];
 moment[n_Integer?OddQ]=0;
 moment[n_Integer?EvenQ]:=(-transverse)^(n/2)Pochhammer[1/2,n/2]/Pochhammer[(D-rank)/2,n/2];
 <|"Value"->Total[(Last[#]moment[First[First[#]]])&/@terms],"ExternalRank"->rank,
  "TransverseDimension"->D-rank,"TransverseSquare"->transverse,
  "NormalMomentum"->normal,"IntegratedMomentum"->loop,
  "MomentFormula"->"< (ell.n)^(2j) > = (-ell_perp^2)^j (1/2)_j / ((D-rank)/2)_j; odd moments vanish",
  "Scope"->"Rotational tensor identity at fixed full-D scalar products and fixed external span; propagators retain their prescriptions."|>
],"AngularAverage"];

End[];EndPackage[];
