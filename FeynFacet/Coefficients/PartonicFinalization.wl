(* Finite extraction is independent of how pole cancellation was established. *)
BeginPackage["FeynFacet`"];
VerifyPartonicPoleCancellation::usage="VerifyPartonicPoleCancellation[results] checks already simplified poles for exact zero. VerifyPartonicPoleCancellation[results,exactPoints,request] evaluates poles numerically and labels that evidence separately. Both require complete Laurent coverage and retain source coefficients and conventions.";
FinalizePartonicResults::usage="FinalizePartonicResults[results,check,request] retains requested finite epsilon ranges after matching a successful pole check to the complete input. It refuses unresolved integrals and does not read reference coefficients.";
CompleteRemovablePartonicLimits::usage="CompleteRemovablePartonicLimits[result,limits] fills only undefined specializations at declared kinematic loci after verifying exact equality of both one-sided limits. Explicit Piecewise values are stored in the same coefficient format.";
Begin["`Private`"];

partonicPoleInput[results_Association]:=Module[{},
  If[results===<||>||!AllTrue[Values[results],partonicResultValidQ],
    Return[Failure["CommonPartonicResultsRequired",<||>]]];
  If[!AllTrue[Values[results],First[#["EpsilonRange"]]===#["LaurentLowerBound"]&],
    Return[Failure["UncomputedLowerEpsilonCoefficients",<||>]]];
  Association@Flatten@KeyValueMap[Function[{name,result},
    KeyValueMap[Prepend[#1,name]->#2&,
      KeySelect[PartonicScalarCoefficientRules[result],First[#]<0&]]],results]
];
partonicPoleConventions[results_Association]:=Map[KeyTake[#,{
  "Order","Project","Channel","PhysicalChannel","Polarization","StructureFunctions",
  "Scale","Variables","DimensionalRegulator","DistributionBasis","DensityConvention",
  "DimensionalPrefactor","CurrentNormalization","Coupling","CouplingPower",
  "EpsilonRange","LaurentLowerBound","Assumptions","Domain","RealLetterPrescription","GPLContinuation"}]&,results];

VerifyPartonicPoleCancellation[results_Association]:=Module[{input,failed},
  input=partonicPoleInput[results];If[FailureQ[input],Return[input]];
  failed=Keys[Select[input,#=!=0&]];
  <|"DataType"->"PartonicPoleCancellationCheck",
    "Status"->If[failed==={},"Passed","Failed"],"Method"->"ExactSymbolicZero",
    "AlgebraicIdentityProof"->(failed==={}),"InputPoleCoefficients"->input,
    "InputConventions"->partonicPoleConventions[results],
    "CoefficientCount"->Length[input],"FailedKeys"->failed|>
];

partonicExplicitConstants[coefficients_]:=Module[{value,constants},
 value=coefficients/.{
  HoldPattern[PolyGamma[0,k_Integer?Positive]]:>HarmonicNumber[k-1]-EulerGamma,
  HoldPattern[PolyGamma[m_Integer?Positive,k_Integer?Positive]]:>
    (-1)^(m+1)Factorial[m](Zeta[m+1]-HarmonicNumber[k-1,m+1])};
 (* Expand the finite set of special constants, not the full kinematic
    expression. FunctionExpand on large log/dilog coefficients needlessly
    searches functional transformations of already explicit functions. *)
 constants=DeleteDuplicates[Cases[value,
   Gamma[_Integer|_Rational]|PolyGamma[_Integer,_Integer|_Rational]|Zeta[_Integer],{0,Infinity}]];
 value/.Dispatch[(#->FunctionExpand[#])&/@constants]
];
partonicExplicitCoefficientsQ[coefficients_]:=
  FreeQ[coefficients,_Integrate|_NIntegrate|_Inactive|_FeynCalc`GLI|_FeynCalc`PaVe|
    _FeynCalc`B0|_FeynCalc`C0|_FeynCalc`D0|_Gamma|_PolyGamma|_HypergeometricPFQ|
    _Hypergeometric2F1|_AppellF1|_Conjugate|_Re|_Im|_FeynFacetSolution`F|_FeynFacetSolution`K|
    _FeynFacetSolution`a|_FeynFacetSolution`B|_FeynFacetSolution`C|
    _SeriesData|_Series|_SeriesCoefficient|_Failure|_Missing|$Failed|$Aborted|
    Indeterminate|_DirectedInfinity]&&
    Cases[coefficients,_Derivative,{0,Infinity},Heads->True]==={}&&
    AllTrue[Cases[coefficients,_FeynFacetSolution`G,{0,Infinity},Heads->True],
      MatchQ[#,FeynFacetSolution`G[_List,_]]&&
       FreeQ[#[[1]],_List|_Association,{1,Infinity},Heads->True]&&
       FreeQ[#[[2]],_List|_Association,{0,Infinity},Heads->True]&]&&
    Cases[coefficients,expr_/;MatchQ[Head[expr],_FeynFacetSolution`G],{0,Infinity},Heads->True]==={};

FinalizePartonicResults[results_Association,check_Association,request_Association]:=Module[
 {ranges,metadata,out=<||>,result,range,coefficients,summary,input,conventions,finalMetadata},
 input=partonicPoleInput[results];
 If[FailureQ[input],Return[input]];
 conventions=partonicPoleConventions[results];
 If[Lookup[check,"DataType",None]=!="PartonicPoleCancellationCheck"||
   Lookup[check,"Status",None]=!="Passed"||
   Lookup[check,"InputPoleCoefficients",None]=!=input||
   Lookup[check,"InputConventions",None]=!=conventions,
  Return[Failure["MatchingCompletePoleCancellationCheckRequired",<||>]]];
 If[TrueQ[Lookup[request,"RequireAlgebraicIdentityProof",False]]&&
   !(TrueQ[Lookup[check,"AlgebraicIdentityProof",False]]&&
     Lookup[check,"Method",None]==="ExactSymbolicZero"),
  Return[Failure["ExactAlgebraicPoleCancellationRequired",<||>]]];
 ranges=Lookup[request,"EpsilonRanges",<||>];metadata=Lookup[request,"Metadata",<||>];
 summary=KeyDrop[check,{"InputPoleCoefficients","InputConventions"}];
 Do[
  result=results[name];range=Lookup[ranges,name,{0,0}];
  If[!MatchQ[range,{_Integer?NonNegative,_Integer?NonNegative}]||
    FeynFacet`RequirePartonicEpsilonRange[result,range]=!=True,
   Return[Failure["AvailableFiniteResultRangeRequired",<|"Result"->name,"Range"->range|>],Module]];
  coefficients=KeySelect[result["Coefficients"],First[range]<=#<=Last[range]&];
  coefficients=partonicExplicitConstants[coefficients];
  If[!partonicExplicitCoefficientsQ[coefficients],
   Return[Failure["ExplicitIntegralFreeFiniteCoefficientsRequired",<|"Result"->name|>],Module]];
  finalMetadata=partonicMergeAnalyticMetadata[
   KeyDrop[result,{"Coefficients","EpsilonRange","LaurentLowerBound"}],metadata];
  If[FailureQ[finalMetadata],Return[finalMetadata,Module]];
  finalMetadata=partonicMergeAnalyticMetadata[finalMetadata,Lookup[Lookup[request,"MetadataByResult",<||>],name,<||>]];
  If[FailureQ[finalMetadata],Return[finalMetadata,Module]];
  AssociateTo[out,name->FeynFacet`CreatePartonicResult[coefficients,
   Join[finalMetadata,
    <|"LaurentLowerBound"->Max[0,result["LaurentLowerBound"]],"PoleCancellationVerified"->True,
      "PoleCancellationVerificationMethod"->check["Method"],"PoleCancellationCheck"->summary,
      "FiniteExpressionBasis"->Lookup[request,"FiniteExpressionBasis","Explicit scalar functions"],
      "UnresolvedIntegrals"->False|>]]],
 {name,Keys[results]}];out
];


CompleteRemovablePartonicLimits[result_Association,limits_List]:=Catch[Module[
 {out=result,coefficients,assumptions,records={},walk,extend,specialized,limit,rule,variable,location},
 If[!partonicResultValidQ[result]||!MatchQ[limits,{Rule[_Symbol,_]...}],
  Throw[Failure["PartonicResultAndExplicitKinematicLimitsRequired",<||>],"PartonicLimits"]];
 assumptions=Lookup[result,"Assumptions",True]&&Lookup[result,"Domain",True];
 Do[
  {variable,location}=List@@rule;
  extend[value_]:=Module[{specialized,derived},
   specialized=Quiet[value/.rule];
   If[FreeQ[specialized,Indeterminate|_DirectedInfinity],Return[value]];
   derived=FeynFacet`RegularAnalyticLimit[value,rule,assumptions];
   If[FailureQ[derived],Throw[Failure["RemovablePartonicLimitNotVerified",<|"Limit"->rule,"Cause"->derived|>],"PartonicLimits"]];
   AppendTo[records,KeyDrop[derived,{"Value"}]];
   Piecewise[{{derived["Value"],variable==location}},value]];
  walk[node_]:=If[AssociationQ[node]||ListQ[node],Map[walk,node],extend[node]];
  coefficients=walk[out["Coefficients"]];
  out=FeynFacet`CreatePartonicResult[coefficients,out],
 {rule,limits}];
 Join[out,<|"RemovableKinematicLimits"->limits,"RemovableLimitVerification"->records|>]
],"PartonicLimits"];
CompleteRemovablePartonicLimits[___]:=Failure["PartonicResultAndExplicitKinematicLimitsRequired",<||>];

End[];EndPackage[];
