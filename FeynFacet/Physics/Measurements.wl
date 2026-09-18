(* Linear measurement constraints, with their exact Dirac-delta Jacobian.
   Integration variables are real scalar coordinates (including named loop
   scalar products). Their momentum representation is supplied by the caller. *)
BeginPackage["FeynFacet`"];
CompileLinearMeasurement::usage="CompileLinearMeasurement[request] rewrites delta(Value-Observable) as Jacobian delta(CutPolynomial), monic in the first nonzero integration variable. Request specifies Observable, Value, IntegrationVariables and Assumptions. Measurement cuts carry no independent positive-energy condition.";
CompileMeasurement::usage="CompileMeasurement[request] compiles delta(Value-Observable) to a degree-at-most-two polynomial measurement cut and its exact unit-cut Jacobian. Rational observables require a denominator with proved fixed nonzero sign on the declared open domain. The polynomial is kept unchanged for raised cuts; constants in integration coordinates are explicit contact constraints.";
FinalStateMeasurementTerms::usage="FinalStateMeasurementTerms[specification,momenta] instantiates a card-defined observable and weight for ordered or unordered final-state tuples. Arguments, Observable, Variable, Weight and Tuples specify the mathematics; repeated entries are retained when requested, including contact contributions.";
ConstructFinalStateMeasurementMoments::usage="ConstructFinalStateMeasurementMoments[phaseSpace,specification,orders] derives the inclusive momentum-space weights obtained by integrating each measurement delta against a nonnegative integer power of its measured variable. Tuple ordering/repetitions, momentum conservation and massless unit cuts are applied exactly. ConstantWeights identifies moments proportional to the unweighted inclusive rate; no amplitude or inclusive rate is evaluated.";
Begin["`Private`"];
CompileLinearMeasurement[request_Association]:=Catch[Module[
 {variables,assumptions,constraint,fraction,num,den,coefficients,constant,selected,scale,polynomial,jacobian},
 variables=Lookup[request,"IntegrationVariables",{}];assumptions=Lookup[request,"Assumptions",True];
 If[variables==={}||!MatchQ[variables,{_Symbol...}]||!DuplicateFreeQ[variables]||
  !ContainsAll[Keys[request],{"Observable","Value"}],
  Throw[Failure["LinearMeasurementRequestRequired",<||>],"LinearMeasurement"]];
 constraint=request["Value"]-request["Observable"];
 If[!FreeQ[constraint,_Failure|_Missing|$Failed|$Aborted|Indeterminate|_DirectedInfinity],
  Throw[Failure["ExplicitMeasurementRequired",<||>],"LinearMeasurement"]];
 fraction=Together[constraint];num=Numerator[fraction];den=Denominator[fraction];
 If[!FreeQ[den,Alternatives@@variables]||!PolynomialQ[num,variables]||
  !AllTrue[First/@CoefficientRules[num,variables],Total[#]<=1&],
  Throw[Failure["LinearMeasurementConstraintRequired",<||>],"LinearMeasurement"]];
 coefficients=Coefficient[num,#]&/@variables;constant=num/.Thread[variables->0];
 selected=SelectFirst[Range[Length[variables]],coefficients[[#]]=!=0&,Missing[]];
 If[MissingQ[selected],Throw[Failure["NonconstantMeasurementRequired",<||>],"LinearMeasurement"]];
 scale=Cancel[coefficients[[selected]]/den];
 If[!TrueQ[FullSimplify[scale!=0&&Element[scale,Reals]&&
   And@@(Element[#,Reals]&/@Append[coefficients,constant]),Assumptions->assumptions]],
  Throw[Failure["RealNondegenerateMeasurementRequired",<||>],"LinearMeasurement"]];
 polynomial=Cancel[num/coefficients[[selected]]];
 jacobian=FullSimplify[1/Abs[scale],Assumptions->assumptions];
 <|"CutType"->"Measurement","OriginalConstraint"->constraint,
  "CutPolynomial"->polynomial,"Jacobian"->jacobian,"ConstraintScale"->scale,
  "NormalizationVariable"->variables[[selected]],"IntegrationVariables"->variables,
  "InitialCutPower"->1,"PositiveEnergyCondition"->None,
  "Assumptions"->assumptions|>
],"LinearMeasurement"];

CompileMeasurement[request_Association]:=Catch[Module[
 {variables,assumptions,observable,value,constraint,fraction,num,den,degree,jacobian,kind},
 variables=Lookup[request,"IntegrationVariables",{}];
 assumptions=Lookup[request,"Assumptions",True];
 If[!MatchQ[variables,{_Symbol...}]||!DuplicateFreeQ[variables]||
   !ContainsAll[Keys[request],{"Observable","Value"}],
   Throw[Failure["PolynomialMeasurementRequestRequired",<||>],"PolynomialMeasurement"]];
 {observable,value}=Lookup[request,{"Observable","Value"}];
 constraint=value-observable;
 If[!FreeQ[constraint,_Real|_Failure|_Missing|$Failed|$Aborted|Indeterminate|_DirectedInfinity],
   Throw[Failure["ExactMeasurementRequired",<||>],"PolynomialMeasurement"]];
 fraction=Together[constraint];num=Expand[Numerator[fraction]];den=Denominator[fraction];
 If[!PolynomialQ[num,variables]||!PolynomialQ[den,variables],
   Throw[Failure["RationalScalarProductMeasurementRequired",<||>],"PolynomialMeasurement"]];
 degree=If[num===0,0,Max[Total/@(First/@CoefficientRules[num,variables])]];
 If[degree>2,Throw[Failure["AtMostQuadraticMeasurementRequired",<|"Degree"->degree|>],"PolynomialMeasurement"]];
 jacobian=Which[
   TrueQ[FullSimplify[den>0,Assumptions->assumptions]],den,
   TrueQ[FullSimplify[den<0,Assumptions->assumptions]],-den,
   True,Throw[Failure["MeasurementDenominatorSignRequired",<|"Denominator"->den|>],"PolynomialMeasurement"]];
 If[!TrueQ[FullSimplify[Element[num,Reals],Assumptions->assumptions]],
   Throw[Failure["RealMeasurementConstraintRequired",<||>],"PolynomialMeasurement"]];
 kind=If[degree===0,"Contact","PolynomialCut"];
 If[num===0,Throw[Failure["IdenticallyZeroMeasurementConstraint",<||>],"PolynomialMeasurement"]];
 <|"CutType"->"Measurement","Kind"->kind,"Observable"->observable,"Value"->value,
   "OriginalConstraint"->constraint,"CutPolynomial"->num,"Jacobian"->jacobian,
   "PolynomialDegree"->degree,"IntegrationVariables"->variables,"InitialCutPower"->1,
   "PositiveEnergyCondition"->None,"Assumptions"->assumptions,
   "EqualityScope"->"Unit measurement cut on the declared open nonzero-denominator domain; endpoint continuation is a separate requirement.",
   "RaisedCutConvention"->"Differentiate the retained polynomial and numerator; do not reapply the unit-cut Jacobian rule to raised cuts."|>
],"PolynomialMeasurement"];

FinalStateMeasurementTerms[specification_Association,momenta:{__Symbol}]:=Catch[Module[
 {arguments,tuples,rank,ordered,repeated,indices,observable,weight,variable,rules},
 If[!ContainsAll[Keys[specification],{"Arguments","Observable","Weight","Variable","Tuples"}]||
   !DuplicateFreeQ[momenta],Throw[Failure["FinalStateMeasurementSpecificationRequired",<||>]]];
 arguments=specification["Arguments"];tuples=specification["Tuples"];
 If[!MatchQ[arguments,{__Symbol}]||!DuplicateFreeQ[arguments]||!AssociationQ[tuples]||
   Intersection[arguments,momenta]=!={},Throw[Failure["DistinctMeasurementArgumentsRequired",<||>]]];
 rank=Length[arguments];ordered=Lookup[tuples,"Ordered",True];repeated=Lookup[tuples,"IncludeRepeated",False];
 If[!MemberQ[{True,False},ordered]||!MemberQ[{True,False},repeated],
   Throw[Failure["ExplicitTupleOrderingAndRepetitionRequired",<||>]]];
 indices=If[ordered,Tuples[Range[Length[momenta]],rank],
   If[repeated,Select[Tuples[Range[Length[momenta]],rank],OrderedQ],Subsets[Range[Length[momenta]],{rank}]]];
 If[!repeated,indices=Select[indices,DuplicateFreeQ]];
 {observable,weight,variable}=Lookup[specification,{"Observable","Weight","Variable"}];
 If[!MatchQ[variable,_Symbol]||!FreeQ[{observable,weight},variable]||
   !FreeQ[{observable,weight},_Real|_Failure|_Missing],
   Throw[Failure["ExactVariableIndependentObservableAndWeightRequired",<||>]]];
 Map[Function[index,rules=Thread[arguments->momenta[[index]]];
   <|"ParticleIndices"->index,"Momenta"->momenta[[index]],"Variable"->variable,
     "Observable"->(observable/.rules),"Weight"->(weight/.rules),
     "TupleConvention"->tuples|>],indices]
]];

ConstructFinalStateMeasurementMoments[phaseSpace_Association,specification_Association,
 orders:{__Integer}]:=Catch[Module[{definition,terms,unitRules,routing,kin,weights,loops},
 If[!DuplicateFreeQ[orders]||Min[orders]<0,
  Throw[Failure["DistinctNonnegativeMeasurementMomentOrdersRequired",<||>],"MeasurementMoment"]];
 terms=FeynFacet`FinalStateMeasurementTerms[specification,phaseSpace["FinalMomenta"]];
 definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[KeyDrop[phaseSpace,"Measurements"]];
 If[!ListQ[terms]||!AssociationQ[definition],
  Throw[Failure["MasslessFinalStateMeasurementMomentDefinitionRequired",<|"Terms"->terms,"Definition"->definition|>],"MeasurementMoment"]];
 unitRules=FeynFacet`UnitCutScalarProductRules[definition];
 If[!ListQ[unitRules],Throw[Failure["PhysicalUnitCutMomentRelationsRequired",<||>],"MeasurementMoment"]];
 routing=definition["MomentumConservationRules"];kin=definition["Topology"][[5]];
 loops=definition["Topology"][[3]];
 weights=Association@Table[n->Cancel[Together[
   (FeynCalc`ExpandScalarProduct[FeynCalc`FCI[
      Total[(#["Weight"]#["Observable"]^n)&/@terms]]/.routing]/.kin)/.unitRules]],{n,orders}];
 If[!FreeQ[weights,_Failure|_Missing|Indeterminate|_DirectedInfinity],
  Throw[Failure["ExplicitInclusiveMeasurementMomentWeightsRequired",<||>],"MeasurementMoment"]];
 <|"Format"->"FeynFacet-FinalStateMeasurementMoments","Variable"->specification["Variable"],
  "Orders"->orders,"InclusiveWeights"->weights,
  "ConstantWeights"->Select[weights,FreeQ[#,Alternatives@@loops]&],
  "TupleConvention"->specification["Tuples"],"TupleCount"->Length[terms],
  "PhaseSpaceDefinition"->definition,"InclusiveRateEvaluated"->False,
  "Convention"->"Each measurement delta is integrated first: its nth moment is Weight times Observable^n. No cut-polynomial Jacobian remains after this exact measurement integral. State, flavor, amplitude and coupling factors are supplied by the same raw contribution."|>
],"MeasurementMoment"];
End[];EndPackage[];
