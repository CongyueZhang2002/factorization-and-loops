
(* Sufficient regulator orders and assembly for c = known + R B.
   The physical derivation of R and B belongs to the representation/reduction
   layer. This code never interprets missing coefficients as numerical zero. *)
Begin["FeynFacet`Private`"];
FeynFacet`DetermineBoundaryIntegralOrders::usage="DetermineBoundaryIntegralOrders[map,demands] propagates requested amplitude Laurent coefficients through the exact rational reduction c=known+R B.";
FeynFacet`EvaluateBoundaryIntegralSystem::usage="EvaluateBoundaryIntegralSystem[problem,opts] evaluates required Euler boundary integrals and assembles only amplitude coefficients whose dependencies are complete.";
FeynFacet`DetermineBoundaryIntegralOrders[map_Association,demands_List] := Catch[Module[
 {eps=Lookup[map,"DimensionalRegulator",None],matrix=Normal[Lookup[map,"ReductionMatrix",{}]],
  bounds=Lookup[map,"BoundaryIntegralLaurentLowerBounds",{}],n,c,valuation,entry,highest,
  needs,orders,ranges,nonzero,requested},
 If[!MatrixQ[matrix]||matrix==={}||!MatchQ[eps,_Symbol],
   boundaryIntegrationFail["BoundaryReductionMatrixRequired"]];
 {n,c}=Dimensions[matrix];
 If[Length[bounds]=!=c||!VectorQ[bounds,IntegerQ]||
   !AllTrue[demands,MatchQ[#,{_Integer,_Integer}]&&1<=First[#]<=n&],
   boundaryIntegrationFail["BoundaryIntegralOrderInputInvalid"]];
 valuation[value_] := Module[{nd},
  If[value===0,Return[Infinity]];
  nd=NumeratorDenominator[Cancel[Together[value]]];
  If[!AllTrue[nd,PolynomialQ[#,eps]&],boundaryIntegrationFail["RationalBoundaryReductionRequired"]];
  Exponent[First[nd],eps,Min]-Exponent[Last[nd],eps,Min]];
 entry=Map[valuation,matrix,{2}];highest=ConstantArray[-Infinity,c];needs={};
 Do[Do[
   If[entry[[demand[[1]],j]]===Infinity||demand[[2]]<entry[[demand[[1]],j]]+bounds[[j]],Continue[]];
   highest[[j]]=Max[highest[[j]],demand[[2]]-entry[[demand[[1]],j]]];
   AppendTo[needs,<|"AmplitudeCoefficient"->demand,"BoundaryIntegralIndex"->j,
     "BoundaryIntegralOrderRange"->{bounds[[j]],demand[[2]]-entry[[demand[[1]],j]]},
     "ReductionCoefficientOrderRange"->{entry[[demand[[1]],j]],demand[[2]]-bounds[[j]]}|>],
 {j,c}],{demand,DeleteDuplicates[demands]}];
 ranges=Association@Table[j->If[highest[[j]]===-Infinity,{}, {bounds[[j]],highest[[j]]}],{j,c}];
 If[TrueQ[$epsilonRemainderChecks],Do[
  epsilonAuditMultiplier[matrix[[First[demand],j]],eps,bounds[[j]],highest[[j]],Last[demand],
    "Stage3/BoundaryReduction",{demand,j}],{demand,DeleteDuplicates[demands]},{j,c}]];
 <|"DataType"->"BoundaryIntegralOrders","BoundaryIntegralOrderRanges"->ranges,
  "CoefficientDependencies"->needs,"RequestedAmplitudeCoefficients"->DeleteDuplicates[demands],
  "ReductionEntryLaurentValuations"->entry,
  "SufficiencyMethod"->"Finite Laurent convolution through each nonzero exact reduction coefficient, using the stated integral lower bounds."|>
],"BoundaryIntegration"];
Options[FeynFacet`EvaluateBoundaryIntegralSystem]=Options[FeynFacet`IntegrateEulerBoundaryIntegral];
FeynFacet`EvaluateBoundaryIntegralSystem[problem_Association,opts:OptionsPattern[]] := Catch[Module[
 {plan,map=Lookup[problem,"BoundaryAmplitudeReduction",<||>],
  definitions=Lookup[problem,"BoundaryIntegralDefinitions",<||>],demands,
  evaluated=<||>,unresolved=<||>,amplitudes=<||>,missing=<||>,eps,matrix,known,
  value,result,range,dependencies,required,complete,expression,integralCount},
 demands=Lookup[problem,"RequestedAmplitudeCoefficients",{}];
 plan=FeynFacet`DetermineBoundaryIntegralOrders[map,demands];
 If[FailureQ[plan],Throw[plan,"BoundaryIntegration"]];
 eps=map["DimensionalRegulator"];matrix=Normal[map["ReductionMatrix"]];
 known=Lookup[map,"KnownAmplitudeExpressions",ConstantArray[0,Length[matrix]]];
 If[!ListQ[known]||Length[known]=!=Length[matrix],boundaryIntegrationFail["KnownAmplitudeVectorInvalid"]];
 Do[
  range=plan["BoundaryIntegralOrderRanges"][j];If[range==={},Continue[]];
  If[!KeyExistsQ[definitions,j],AssociateTo[unresolved,j->Failure["BoundaryIntegralDefinitionMissing",<||>]];Continue[]];
  result=FeynFacet`IntegrateEulerBoundaryIntegral[Join[definitions[j],<|"DimensionalRegulator"->eps|>],
    range,opts];
  If[FailureQ[result],AssociateTo[unresolved,j->result],AssociateTo[evaluated,j->result]],
 {j,Length[First[matrix]]}];
 Do[
  dependencies=Select[plan["CoefficientDependencies"],#["AmplitudeCoefficient"]===demand&];
  required=Lookup[dependencies,"BoundaryIntegralIndex"];
  If[!AllTrue[required,KeyExistsQ[evaluated,#]&],
    AssociateTo[missing,demand->Select[required,!KeyExistsQ[evaluated,#]&]];Continue[]];
  expression=known[[demand[[1]]]];
  If[TrueQ[$epsilonRemainderChecks],Do[
   epsilonAuditMultiplier[matrix[[First[demand],j]],eps,
     First[evaluated[j]["EpsilonOrderRange"]],Max[Keys[evaluated[j]["LaurentCoefficients"]]],Last[demand],
     "Stage3/EvaluatedBoundaryConvolution",{demand,j}],{j,required}]];
  Do[expression+=matrix[[demand[[1]],j]] Total[
    KeyValueMap[#2 eps^#1&,evaluated[j]["LaurentCoefficients"]]],{j,required}];
  value=SeriesCoefficient[expression,{eps,0,demand[[2]]}];
  If[!FreeQ[value,_SeriesCoefficient|$Failed|Indeterminate|_DirectedInfinity],
    AssociateTo[missing,demand->Failure["AmplitudeCoefficientExpansionFailed",<||>]],
    AssociateTo[amplitudes,demand->value]],
 {demand,plan["RequestedAmplitudeCoefficients"]}];
 <|"DataType"->"BoundaryIntegralEvaluation","Status"->If[missing===<||>,"RequestedAmplitudesEvaluated","SomeBoundaryIntegralsUnresolved"],
   "OrderDetermination"->plan,"EvaluatedBoundaryIntegrals"->evaluated,
   "UnresolvedBoundaryIntegrals"->unresolved,"AmplitudeLaurentCoefficients"->amplitudes,
   "UnresolvedAmplitudeCoefficients"->missing,"PhysicalRegionCompleteness"->Lookup[problem,"PhysicalRegionCompleteness","NotEstablished"]|>
],"BoundaryIntegration"];

FeynFacet`ExtendBoundaryInputOrders::usage="ExtendBoundaryInputOrders[reduction,requests,opts] computes only missing coefficients of previously defined physical boundary inputs. Requests are {input index, highest epsilon order}; each affected input retains its existing coefficients and exact integral definition.";
Options[FeynFacet`ExtendBoundaryInputOrders]=Options[FeynFacet`IntegrateEulerBoundaryIntegral];
FeynFacet`ExtendBoundaryInputOrders[reduction_Association,requests_List,opts:OptionsPattern[]] :=
 Catch[Module[{inputs=Lookup[reduction,"BoundaryInputs",None],e=Lookup[reduction,"DimensionalRegulator",None],
  targets,updated=<||>,evaluations=<||>,report={},i,high,old,available,missing,low,range,result,
  fresh,overlap,difference,checks,analytic,poly,started=AbsoluteTime[]},
 If[!ListQ[inputs]||!MatchQ[e,_Symbol]||
  !AllTrue[requests,MatchQ[#,{_Integer,_Integer}]&&1<=First[#]<=Length[inputs]&],
  boundaryIntegrationFail["BoundaryInputExtensionRequestInvalid"]];
 targets=Merge[(First[#]->Last[#])&/@requests,Max];
 Do[
  old=inputs[[i]];high=targets[i];low=old["LaurentLowerBound"];
  available=Lookup[old,"LaurentCoefficients",<||>];
  missing=Complement[Range[low,high],Keys[available]];
  If[missing==={},AppendTo[report,<|"InputIndex"->i,"Status"->"AlreadyAvailable"|>];Continue[]];
  analytic=Lookup[old,"AnalyticExpression",Missing["LaurentSeriesOnly"]];
  If[!MissingQ[analytic],
   poly=Normal[Series[analytic,{e,0,high}]];
   fresh=Association@Table[q->Coefficient[Expand[poly],e,q],{q,low,high}];
   result=<|"LaurentCoefficients"->fresh,"IntegrationMethods"->{"StoredAnalyticExpression"}|>,
   If[!AssociationQ[Lookup[old,"IntegralDefinition",None]],
    boundaryIntegrationFail["PhysicalBoundaryIntegralDefinitionRequired",<|"InputIndex"->i|>]];
   range={Min[Append[Select[Keys[available],#<Min[missing]&],Min[missing]]],high};
   (* Recompute only the nearest stored order as an overlap check. *)
   range[[1]]=If[Select[Keys[available],#<Min[missing]&]==={},Min[missing],
     Max[Select[Keys[available],#<Min[missing]&]]];
   result=FeynFacet`IntegrateEulerBoundaryIntegral[old["IntegralDefinition"],range,opts];
   If[FailureQ[result]||!AssociationQ[result],
    boundaryIntegrationFail["BoundaryInputExtensionEvaluationFailed",<|"InputIndex"->i,"Cause"->result|>]];
   fresh=Lookup[result,"LaurentCoefficients",<||>]];
  If[!AssociationQ[fresh]||!SubsetQ[Keys[fresh],missing]||
    !FreeQ[Values[fresh],e|_Missing|_Failure|$Failed|_Series|_SeriesCoefficient|_SeriesData|Indeterminate|_DirectedInfinity],
   boundaryIntegrationFail["ExplicitExtendedBoundaryCoefficientsRequired",<|"InputIndex"->i|>]];
  overlap=Intersection[Keys[available],Keys[fresh]];
  checks=Association@Table[q->If[SameQ[available[q],fresh[q]],True,
    difference=TimeConstrained[Expand[available[q]-fresh[q]],10,$Aborted];TrueQ[difference===0]],{q,overlap}];
  If[!AllTrue[Values[checks],TrueQ],
   boundaryIntegrationFail["BoundaryInputExtensionOverlapNotEstablished",<|
    "InputIndex"->i,"Checks"->checks,"Evaluation"->result|>]];
  AssociateTo[updated,i->Join[old,<|"LaurentCoefficients"->KeySort[Join[available,fresh]],
    "EpsilonOrderRange"->{low,Max[high,Max[Keys[available]]]}|>]];
  AssociateTo[evaluations,i->result];
  AppendTo[report,<|"InputIndex"->i,"Status"->"MissingCoefficientsConstructed",
    "NewOrders"->missing,"ExactOverlapChecks"->checks,
    "IntegrationMethods"->Lookup[result,"IntegrationMethods",{}]|>],
 {i,Keys[targets]}];
 <|"DataType"->"BoundaryInputOrderExtension","Status"->"RequestedInputOrdersAvailable",
  "DimensionalRegulator"->e,"RequestedUpperOrders"->targets,"UpdatedBoundaryInputs"->updated,
  "Evaluations"->evaluations,"Reports"->report,"ElapsedSeconds"->AbsoluteTime[]-started|>
 ],"BoundaryIntegration"];

FeynFacet`CheckBoundaryIntegralEpsilonRemainders::usage="CheckBoundaryIntegralEpsilonRemainders[reduction,demands,values] checks actual stored boundary-integral cutoffs through the exact amplitude reduction, without evaluating integrals. values maps integral indices to records containing LaurentCoefficients.";
Options[FeynFacet`CheckBoundaryIntegralEpsilonRemainders]=Options[FeynFacet`WithEpsilonRemainderChecks];
FeynFacet`CheckBoundaryIntegralEpsilonRemainders[map_Association,demands_List,values_Association,opts:OptionsPattern[]]:=
 FeynFacet`WithEpsilonRemainderChecks[Catch[Module[{e,matrix,bounds,cs,hi,low,m},
  {e,matrix,bounds}=Lookup[map,{"DimensionalRegulator","ReductionMatrix","BoundaryIntegralLaurentLowerBounds"}];
  matrix=Normal[matrix];
  If[!MatchQ[e,_Symbol]||!MatrixQ[matrix]||matrix==={}||!VectorQ[bounds,IntegerQ]||Length[bounds]=!=Length[First[matrix]]||
    !AllTrue[demands,MatchQ[#,{_Integer,_Integer}]&&1<=First[#]<=Length[matrix]&],
   boundaryIntegrationFail["BoundaryRemainderAuditInputInvalid"]];
  Do[m=matrix[[First[demand],j]];If[m===0,Continue[]];low=bounds[[j]];
   cs=Lookup[Lookup[values,j,<||>],"LaurentCoefficients",<||>];
   If[!AssociationQ[cs]||!AllTrue[Keys[cs],IntegerQ],boundaryIntegrationFail["ExplicitBoundaryCoefficientsRequired"]];
   hi=If[cs===<||>,low-1,Max[Keys[cs]]];
   If[Complement[Range[low,hi],Keys[cs]]=!={},boundaryIntegrationFail["StoredBoundaryEpsilonOrderGap",<|"Input"->j|>]];
   epsilonAuditMultiplier[m,e,low,hi,Last[demand],"Stage3/SavedBoundaryReduction",{demand,j}],
    {demand,DeleteDuplicates[demands]},{j,Length[bounds]}];
  <|"Status"->"StoredBoundaryOrdersChecked","RequestedAmplitudeCoefficientCount"->Length[DeleteDuplicates[demands]],
    "BoundaryIntegralCount"->Length[bounds],"NewIntegralEvaluations"->0|>
 ],"BoundaryIntegration"],opts];
End[];
