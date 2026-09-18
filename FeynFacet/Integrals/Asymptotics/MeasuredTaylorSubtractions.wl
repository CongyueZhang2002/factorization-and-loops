(* Taylor subtraction acts on the complete measured action. These algebraic
   records are inputs to, not substitutes for, a resolved-chart L1 proof. *)
BeginPackage["FeynFacet`"];
TestFunction::usage="TestFunction[z] is a formal smooth test function used in measurement-aware Taylor records. Derivative[n][TestFunction][z] retains its actual nth derivative; it is not a coefficient or a fitted endpoint datum.";
ConstructMeasuredTaylorSubtractions::usage="ConstructMeasuredTaylorSubtractions[terms,normalPowers,epsilon] applies iterated endpoint Taylor subtraction to a resolved unit-cube action. Each term supplies Coefficient and Measurement; normalPowers maps normal coordinates to affine regulated powers. The full Coefficient TestFunction[Measurement] is differentiated. Face terms retain exact regulator denominators and higher test-function derivatives. This algebraic identity does not certify chart coverage, smooth-factor bounds, fixed-measurement L1 convergence or endpoint contact order.";
Begin["`Private`"];
ConstructMeasuredTaylorSubtractions[terms:{__Association},powers_Association,e_Symbol]:=Catch[Module[
 {axes=Keys[powers],exponents=Values[powers],orders,slopes,action,states,next,u,a,n,jets,
  polynomial,remainder,faces,history={},normal,realRegulator,convergence,derivativeOrders},
 If[axes==={}||!VectorQ[axes,MatchQ[#,_Symbol]&&#=!=e&]||
   !AllTrue[exponents,PolynomialQ[#,e]&&Exponent[#,e]<=1&&FreeQ[#,Alternatives@@axes]&]||
   !AllTrue[terms,ContainsAll[Keys[#],{"Coefficient","Measurement"}]&&FreeQ[#["Measurement"],e]&],
  cutFamilyFail["ResolvedMeasuredTaylorInputRequired"]];
 orders=exponents/.e->0;slopes=Coefficient[#,e]&/@exponents;
 If[!VectorQ[orders,IntegerQ]||!VectorQ[slopes,MatchQ[#,_Integer|_Rational]&]||
   AnyTrue[Transpose[{orders,slopes}],#[[1]]<=-1&&#[[2]]===0&],
  cutFamilyFail["RegulatedIntegerNormalPowersRequired"]];
 realRegulator=Unique["realTaylorRegulator"];
 convergence=And@@Thread[(exponents/.e->realRegulator)>-1];
 If[!TrueQ[With[{v=realRegulator,c=convergence},Resolve[Exists[{v},c],Reals]]],
  cutFamilyFail["CommonTaylorContinuationDomainRequired"]];
 action=Total[(#["Coefficient"]FeynFacet`TestFunction[#["Measurement"]]&/@terms)];
 states={<|"Coefficient"->1,"Action"->action,"NormalPowers"->powers,"Faces"->{}|>};
 Do[u=axes[[axis]];a=exponents[[axis]];n=Max[-1,-orders[[axis]]-1];
  If[n<0,Continue[]];next={};
  Do[
   jets=Table[Quiet[D[state["Action"],{u,k}]/k!/.u->0],{k,0,n}];
   If[!FreeQ[jets,Indeterminate|_DirectedInfinity|_Limit|_ConditionalExpression],
    cutFamilyFail["RegularMeasuredFaceJetNotEstablished",<|"Coordinate"->u,"Jets"->jets|>]];
   polynomial=Sum[u^k jets[[k+1]],{k,0,n}];
   remainder=state["Action"]-polynomial;
   If[remainder=!=0,AppendTo[next,Join[state,<|"Action"->remainder|>]]];
   Do[If[jets[[k+1]]=!=0,
    AppendTo[next,<|"Coefficient"->state["Coefficient"]/(a+k+1),
      "Action"->jets[[k+1]],"NormalPowers"->KeyDrop[state["NormalPowers"],u],
      "Faces"->Append[state["Faces"],<|"Coordinate"->u,"TaylorOrder"->k|>]|>]],{k,0,n}];
   AppendTo[history,<|"Coordinate"->u,"ThroughTaylorOrder"->n,
    "InputAction"->state["Action"],"TaylorCoefficients"->jets,
    "RemainderAction"->remainder,"IntegratedTaylorMultipliers"->Table[1/(a+k+1),{k,0,n}]|>],
  {state,states}];states=next,
 {axis,Length[axes]}];
 derivativeOrders=Cases[Lookup[states,"Action"],HoldPattern[Derivative[k_Integer][FeynFacet`TestFunction][_]]:>k,Infinity];
 <|"Format"->"FeynFacet-MeasuredTaylorSubtractions","SourceTerms"->terms,
  "SourceAction"->action,"SourceNormalPowers"->powers,"DimensionalRegulator"->e,
  "UnitCubeCoordinates"->axes,"SubtractedTerms"->states,"TaylorIdentities"->history,
  "MaximumTestFunctionDerivativeOrder"->Max[Prepend[derivativeOrders,0]],
  "RegulatorDenominatorsRetained"->True,"ChartCoverageVerified"->False,
  "WeightedL1ConvergenceVerified"->False,"EndpointContactOrderEstablished"->False,
  "Scope"->"Exact iterated Taylor decomposition of the measured action, conditional on the resolved smooth factors. Remaining coordinate integrals, analytic-unit bounds and the strong measured pushforward proof are not supplied."|>
],"CutFamily"];
End[];EndPackage[];
