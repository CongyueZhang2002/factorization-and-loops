
(* Finite coefficient substitutions for exact amplitude relations. These
   routines depend on stored matrices and coefficient availability, not on
   the symbolic DE constructor. *)
Begin["FeynFacetSolution`Private`"];
FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions::usage="BoundaryAmplitudeCoefficientExpressions[reduction,requests] returns explicit original-amplitude coefficients in known boundary values and the remaining regular amplitude coefficients.";
FeynFacetSolution`EvaluateBoundaryAmplitudeCoefficientValues::usage="EvaluateBoundaryAmplitudeCoefficientValues[reduction,freeValues,requests,opts] evaluates finite amplitude substitutions, rejecting missing coefficients.";
FeynFacetSolution`ApplyBoundaryAmplitudeReduction::usage="ApplyBoundaryAmplitudeReduction[shared,reduction] substitutes exact finite amplitude relations into all shared boundary coefficients.";
amplitudeCoefficientFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"AmplitudeCoefficients"];
amplitudeCoefficientValuation[value_,eps_]:=If[value===0,Infinity,With[
 {nd=NumeratorDenominator[Cancel[Together[value]]]},
 If[!AllTrue[nd,PolynomialQ[#,eps]&],amplitudeCoefficientFail["RationalAmplitudeMultiplierRequired"]];
 Exponent[nd[[1]],eps,Min]-Exponent[nd[[2]],eps,Min]]];
FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[reduction_Association,requests_List] :=
 Catch[Module[
 {eps=reduction["DimensionalRegulator"],mat=reduction["BoundaryInputMatrix"],
  free=reduction["FreeAmplitudeMatrix"],inputs=reduction["BoundaryInputs"],high,
  available=<||>,coeffCache=<||>,coef,beta,lo,series,missing={},result=<||>,
  row,k,value,val,lower,t,oldLower=reduction["AmplitudeLaurentLowerBounds"],needed,
  c,nb},
 c=Length[First[free]];nb=Length[inputs];
 If[reduction["ParticularSolutionCompatibility"]=!="AutomaticFromInputBounds",
   amplitudeCoefficientFail["BoundaryCompatibilityVerificationRequired"]];
 If[!AllTrue[requests,MatchQ[#,{_Integer,_Integer}]&&1<=First[#]<=Length[mat]&],
   amplitudeCoefficientFail["AmplitudeCoefficientRequestsInvalid"]];
 high=ConstantArray[-Infinity,nb];
 Do[{row,k}=request;Do[If[mat[[row,j]]===0,Continue[]];
    high[[j]]=Max[high[[j]],k-amplitudeCoefficientValuation[mat[[row,j]],eps]],{j,nb}],{request,requests}];
 Do[lo=inputs[[j,"LaurentLowerBound"]];If[high[[j]]<lo,Continue[]];
  If[KeyExistsQ[inputs[[j]],"AnalyticExpression"]&&!MatchQ[inputs[[j,"AnalyticExpression"]],_Missing],
   series=Normal[Series[inputs[[j,"AnalyticExpression"]],{eps,0,high[[j]]}]];
   If[!FreeQ[series,_Missing|_Series|_SeriesCoefficient|Indeterminate|_DirectedInfinity],
    amplitudeCoefficientFail["BoundaryAnalyticExpressionExpansionFailed"]];
   Do[AssociateTo[available,{j,t}->Coefficient[Expand[series],eps,t]],{t,lo,high[[j]]}],
   Do[
    If[KeyExistsQ[inputs[[j,"LaurentCoefficients"]],t],
      If[!FreeQ[inputs[[j,"LaurentCoefficients"]][t],_Missing|_Series|_SeriesCoefficient|Indeterminate|_DirectedInfinity],
        amplitudeCoefficientFail["BoundaryLaurentCoefficientUnavailable",<|"Index"->j,"Order"->t|>]];
      AssociateTo[available,{j,t}->inputs[[j,"LaurentCoefficients"]][t]],
      AppendTo[missing,{j,t}]],
   {t,lo,high[[j]]}]],
 {j,nb}];
 If[missing=!={},amplitudeCoefficientFail["BoundaryInputOrdersUnavailable",<|"MissingCoefficients"->missing|>]];
 coef[expression_,q_]:=If[KeyExistsQ[coeffCache,{expression,q}],coeffCache[[Key[{expression,q}]]],
  With[{v=SeriesCoefficient[expression,{eps,0,q}]},AssociateTo[coeffCache,{expression,q}->v];v]];
 Do[
  {row,k}=request;value=0;
  If[k>=oldLower[[row]],
   Do[If[mat[[row,j]]===0,Continue[]];
    val=amplitudeCoefficientValuation[mat[[row,j]],eps];lo=inputs[[j,"LaurentLowerBound"]];
    Do[value+=coef[mat[[row,j]],k-t]available[[Key[{j,t}]]],{t,lo,k-val}],{j,nb}];
   Do[If[free[[row,j]]===0,Continue[]];
    val=amplitudeCoefficientValuation[free[[row,j]],eps];
    Do[value+=coef[free[[row,j]],k-t]FeynFacetSolution`C[j,t],{t,0,k-val}],{j,c}]];
  AssociateTo[result,request->value],
 {request,DeleteDuplicates[requests]}];
 result
],"AmplitudeCoefficients"];
Options[FeynFacetSolution`EvaluateBoundaryAmplitudeCoefficientValues]={"WorkingPrecision"->80};
FeynFacetSolution`EvaluateBoundaryAmplitudeCoefficientValues[reduction_Association,
 freeValues_Association,requests_List,OptionsPattern[]] := Catch[Module[
 {expressions,rules,required,missing,gpls,gvalues,wp=OptionValue["WorkingPrecision"],result},
 expressions=FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[reduction,requests];
 If[FailureQ[expressions],Throw[expressions,"AmplitudeCoefficients"]];
 required=DeleteDuplicates@Cases[expressions,FeynFacetSolution`C[i_Integer,k_Integer]:>{i,k},Infinity];
 missing=Select[required,!KeyExistsQ[freeValues,#]&];
 If[missing=!={},amplitudeCoefficientFail["FreeAmplitudeCoefficientsMissing",<|"Coefficients"->missing|>]];
 rules=Dispatch[(Apply[FeynFacetSolution`C,#]->freeValues[[Key[#]]])&/@required];
 gpls=DeleteDuplicates[Cases[expressions,_FeynFacetSolution`G,Infinity]];
 gvalues=FeynFacetSolution`EvaluateGPLExpression[#,"WorkingPrecision"->wp+15]&/@gpls;
 If[AnyTrue[gvalues,FailureQ],amplitudeCoefficientFail["BoundaryGPLValueUnavailable"]];
 expressions=replaceFiniteExpressionReferences[expressions,Thread[gpls->gvalues]];
 result=Association@KeyValueMap[#1->N[#2/.rules,wp]&,expressions];
 If[!AllTrue[Values[result],NumericQ[#]&&FreeQ[#,Indeterminate|_DirectedInfinity]&],
   amplitudeCoefficientFail["BoundaryAmplitudeValuesNotNumerical"]];
 result
],"AmplitudeCoefficients"];
FeynFacetSolution`ApplyBoundaryAmplitudeReduction[shared_Association,reduction_Association] :=
 Catch[Module[
 {requests,expressions,rules,definitions,requirements,free=reduction["FreeAmplitudeOriginalIndices"],
  bounds=reduction["AmplitudeLaurentLowerBounds"],old=shared["BoundaryAmplitudes"],amplitudes,complete},
 requests=DeleteDuplicates@Cases[shared["BoundaryCoefficientDefinitions"],
   FeynFacetSolution`C[i_Integer,k_Integer]:>{i,k},Infinity];
 expressions=FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[reduction,requests];
 If[FailureQ[expressions],Throw[expressions,"AmplitudeCoefficients"]];
 rules=Dispatch[KeyValueMap[Apply[FeynFacetSolution`C,#1]->#2&,expressions]];
 definitions=replaceFiniteExpressionReferences[shared["BoundaryCoefficientDefinitions"],rules];
 requirements=Sort[DeleteDuplicates@Cases[definitions,
   FeynFacetSolution`C[i_Integer,k_Integer]:>{i,k},Infinity]];
 If[AnyTrue[requirements,Last[#]<0&],amplitudeCoefficientFail["RegularFreeAmplitudeHasNegativeOrder"]];
 amplitudes=Table[<|"Index"->j,"LaurentLowerBound"->0,"Definition"-><|
   "Type"->"FrobeniusAmplitude","OriginalAmplitudeIndex"->free[[j]],
   "OriginalDefinition"->old[[free[[j]],"Definition"]],
   "EpsilonNormalizationPower"->-bounds[[free[[j]]]],
   "Normalization"->"f_j=epsilon^(-L_i) c_i for the retained original amplitude i; the integration measure is unchanged."|>|>,
 {j,Length[free]}];
 complete=Length[free]===0&&TrueQ[Lookup[reduction,"AllBoundaryInputsPhysicallyDetermined",False]];
 Join[shared,<|"BoundaryCoefficientDefinitions"->definitions,"BoundaryAmplitudes"->amplitudes,
   "InitialConstantLaurentLowerBounds"->ConstantArray[0,Length[free]],
   "UnknownBoundarySeriesCount"->Length[free],"RequiredInitialConstantCoefficients"->requirements,
   "UnknownLaurentCoefficientCount"->Length[requirements],"AmplitudeReduction"->reduction,
   "NumericalEndpointStatus"->"FrobeniusInitializationAvailable",
   "PhysicalBoundaryValuesComplete"->complete,"PhysicalBoundaryValuesCompleteForStoredOrders"->complete|>]
],"AmplitudeCoefficients"];
End[];
