(* Linear measurement constraints, with their exact Dirac-delta Jacobian.
   Integration variables are real scalar coordinates (including named loop
   scalar products). Their momentum representation is supplied by the caller. *)
BeginPackage["FeynFacet`"];
CompileLinearMeasurement::usage="CompileLinearMeasurement[request] rewrites delta(Value-Observable) as Jacobian delta(CutPolynomial), monic in the first nonzero integration variable. Request specifies Observable, Value, IntegrationVariables and Assumptions. Measurement cuts carry no independent positive-energy condition.";
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
End[];EndPackage[];
