(* Only numerical pole evaluation belongs here; result algebra and finite
   extraction live in Coefficients/PartonicResults and PartonicFinalization. *)
BeginPackage["FeynFacet`"];
Begin["`Private`"];
VerifyPartonicPoleCancellation[results_Association,points_List,request_Association:<||>]:=Module[
 {input,wp,tolerance,timelimit,numerical,rows={},errors},
 If[!MatchQ[points,{{__Rule}..}]||!FreeQ[points,_Real],
   Return[Failure["ExactParameterPointsRequired",<||>]]];
 input=partonicPoleInput[results];If[FailureQ[input],Return[input]];
 wp=Lookup[request,"WorkingPrecision",50];
 tolerance=Lookup[request,"AbsoluteTolerance",10^-30];timelimit=Lookup[request,"TimeLimit",120];
 Do[
  numerical=Quiet[FeynFacetSolution`EvaluateGPLExpression[Values[input],rules,"WorkingPrecision"->wp,
   "TimeLimit"->timelimit,"RealLetterPrescription"->Lookup[request,"RealLetterPrescription",None]],N::meprec];
  If[!VectorQ[numerical,NumericQ]||!FreeQ[numerical,Indeterminate|_DirectedInfinity],
   Return[Failure["FiniteNumericalPoleCoefficientsRequired",<|"Cause"->numerical|>],Module]];
  errors=Abs[numerical];AppendTo[rows,<|"ParameterRules"->rules,
   "MaximumAbsoluteResidual"->Max[Append[errors,0]],"FailedKeys"->Pick[Keys[input],#>tolerance&/@errors,True]|>],
 {rules,points}];
 <|"DataType"->"PartonicPoleCancellationCheck","Status"->If[AllTrue[rows,#["FailedKeys"]==={}&],"Passed","Failed"],
  "Method"->"NumericalEvaluationAtExactParameterPoints","AlgebraicIdentityProof"->False,
  "InputPoleCoefficients"->input,"InputConventions"->partonicPoleConventions[results],"CoefficientCount"->Length[input],"WorkingPrecision"->wp,
  "AbsoluteTolerance"->tolerance,"PointChecks"->rows|>
];
End[];EndPackage[];
