(* Exact Taylor subtraction for integration on a complete resolved cube.
   Boundary monomials are integrated before the regulator is expanded. *)
BeginPackage["FeynFacet`"];
ConstructResolvedEndpointIntegralSubtractions::usage="ConstructResolvedEndpointIntegralSubtractions[resolved,assumptions] constructs exact-in-epsilon Taylor subtractions and partially integrated face contributions on a verified closed unit cube. The original density minus BulkSubtraction is integrable near epsilon zero; every IntegratedStratum is likewise integrable in its remaining variables after finite regulator poles are cleared. Integer endpoint powers determine the required Taylor depths automatically. No scalar integral is evaluated and no endpoint pole is dropped.";
Begin["`Private`"];
ConstructResolvedEndpointIntegralSubtractions[resolved_Association,assumptions_:True]:=Catch[Module[
 {proof,xs,e,labels,bulk,faces=<||>,term,powers,integer,slopes,singular,orders,subsets,jets,
  one,jet,s,rest,b,coefficient,integrated,normal,subtraction,details={},record,key,values},
 proof=FeynFacet`VerifyResolvedEndpointCube[resolved,assumptions];
 If[!AssociationQ[proof],Throw[proof,"OneLoopEndpoint"]];
 {xs,e,labels}=Lookup[resolved,{"NormalVariables","DimensionalRegulator","CoefficientRowLabels"}];
 If[!ListQ[labels]||labels==={},loopEndpointFail["NamedScalarEndpointRowsRequired"]];
 bulk=AssociationThread[labels,ConstantArray[0,Length[labels]]];
 Do[
  powers=term["Powers"];integer=powers/.e->0;slopes=Coefficient[#,e]&/@powers;
  If[!VectorQ[integer,IntegerQ]||!AllTrue[powers,PolynomialQ[#,e]&&Exponent[#,e]<=1&],
   loopEndpointFail["IntegerAffineEndpointPowersRequired"]];
  singular=Select[Range[Length[xs]],integer[[#]]<=-1&];
  If[!AllTrue[singular,TrueQ[FullSimplify[slopes[[#]]!=0,Assumptions->assumptions]]&],
   loopEndpointFail["DimensionalRegulatorForEachSingularFaceRequired"]];
  If[singular==={},Continue[]];
  orders=AssociationThread[xs[[singular]],-1-integer[[singular]]];
  one=Join[resolved,<|"Terms"->{term}|>];jets=<||>;subsets=Rest[Subsets[singular]];
  Do[
   jet=FeynFacet`ExpandAnalyticEndpointFaceJets[one,KeyTake[orders,xs[[s]]]];
   If[!AssociationQ[jet],loopEndpointFail["ExactEndpointTaylorSubtractionsRequired",<|"Cause"->jet|>]];
   AssociateTo[jets,s->First[jet["Terms"]]["NormalTaylorCoefficients"]],{s,subsets}];
  normal=Times@@MapThread[Power,{xs,powers}];
  subtraction=Total[Table[(-1)^(Length[s]+1)normal Total[KeyValueMap[
     #2 Times@@MapThread[Power,{xs[[s]],#1}]&,jets[s]]],{s,subsets}]];
  key=labels[[term["Row"]]];AssociateTo[bulk,key->(bulk[key]+subtraction)];
  Do[
   rest=Complement[Range[Length[xs]],b];integrated=0;
   Do[
    s=Union[b,c];
    integrated+=(-1)^Length[c]Times@@MapThread[Power,{xs[[rest]],powers[[rest]]}]*
     Total[KeyValueMap[Function[{multiIndex,value},value Times@@Table[
        If[MemberQ[b,s[[j]]],1/(powers[[s[[j]]]]+multiIndex[[j]]+1),xs[[s[[j]]]]^multiIndex[[j]]],
       {j,Length[s]}]],jets[s]]],
   {c,Subsets[Complement[singular,b]]}];
   values=Lookup[faces,Key[b],AssociationThread[labels,ConstantArray[0,Length[labels]]]];
   AssociateTo[values,key->(values[key]+integrated)];AssociateTo[faces,b->values],
  {b,subsets}];
  AppendTo[details,<|"Row"->term["Row"],"Powers"->powers,"TaylorOrders"->orders|>],
 {term,resolved["Terms"]}];
 record=KeyValueMap[<|"IntegratedVariables"->xs[[#1]],"RemainingVariables"->xs[[Complement[Range[Length[xs]],#1]]],
     "Values"->#2|>&,faces];
 <|"DataType"->"ResolvedEndpointIntegralSubtractions","DimensionalRegulator"->e,
  "NormalVariables"->xs,"CoefficientRowLabels"->labels,"BulkSubtraction"->bulk,
  "IntegratedStrata"->record,"TaylorRequirements"->details,"ClosedCubeVerification"->proof,
  "ExactInEpsilon"->True,"RemaindersIntegrableNearZero"->True,"IntegralEvaluated"->False,
  "Identity"->"The full integral equals the integral of the original scalar density minus BulkSubtraction, plus the integrals of IntegratedStrata in their RemainingVariables. All intervals are [0,1]. Taylor monomials integrated in each boundary variable produce 1/(power+TaylorIndex+1) before epsilon expansion. Inclusion-exclusion makes each remaining density integrable after finite regulator poles are cleared."|>
],"OneLoopEndpoint"];
End[];EndPackage[];
