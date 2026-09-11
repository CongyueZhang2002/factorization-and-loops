(* Finite extraction is independent of how pole cancellation was established. *)
BeginPackage["FeynFacet`"];
VerifyPartonicPoleCancellation::usage="VerifyPartonicPoleCancellation[results] checks already simplified poles for exact zero. VerifyPartonicPoleCancellation[results,exactPoints,request] evaluates poles numerically and labels that evidence separately. Both require complete Laurent coverage and retain source coefficients and conventions.";
FinalizePartonicResults::usage="FinalizePartonicResults[results,check,request] retains requested finite epsilon ranges after matching a successful pole check to the complete input. It refuses unresolved integrals and does not read reference coefficients.";
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
  "EpsilonRange","LaurentLowerBound","Assumptions","Domain","RealLetterPrescription"}]&,results];

VerifyPartonicPoleCancellation[results_Association]:=Module[{input,failed},
  input=partonicPoleInput[results];If[FailureQ[input],Return[input]];
  failed=Keys[Select[input,#=!=0&]];
  <|"DataType"->"PartonicPoleCancellationCheck",
    "Status"->If[failed==={},"Passed","Failed"],"Method"->"ExactSymbolicZero",
    "AlgebraicIdentityProof"->(failed==={}),"InputPoleCoefficients"->input,
    "InputConventions"->partonicPoleConventions[results],
    "CoefficientCount"->Length[input],"FailedKeys"->failed|>
];

partonicExplicitConstants[coefficients_]:=coefficients/.{
  HoldPattern[PolyGamma[0,k_Integer?Positive]]:>HarmonicNumber[k-1]-EulerGamma,
  HoldPattern[PolyGamma[m_Integer?Positive,k_Integer?Positive]]:>
    (-1)^(m+1)Factorial[m](Zeta[m+1]-HarmonicNumber[k-1,m+1])};
partonicExplicitCoefficientsQ[coefficients_]:=
  FreeQ[coefficients,_Integrate|_NIntegrate|_Inactive|_FeynCalc`GLI|_FeynCalc`PaVe|
    _FeynCalc`B0|_FeynCalc`C0|_FeynCalc`D0|_Gamma|_PolyGamma|_HypergeometricPFQ|
    _Hypergeometric2F1|_Conjugate|_Re|_Im|_FeynFacetSolution`F|_FeynFacetSolution`K|
    _FeynFacetSolution`a|_FeynFacetSolution`G|_FeynFacetSolution`B|_FeynFacetSolution`C|
    _SeriesData|_Series|_SeriesCoefficient|_Failure|_Missing|$Failed|$Aborted|
    Indeterminate|_DirectedInfinity]&&
    Cases[coefficients,_Derivative,{0,Infinity},Heads->True]==={};

FinalizePartonicResults[results_Association,check_Association,request_Association]:=Module[
 {ranges,metadata,out=<||>,result,range,coefficients,summary,input,conventions},
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
  AssociateTo[out,name->FeynFacet`CreatePartonicResult[coefficients,
   Join[KeyDrop[result,{"Coefficients","EpsilonRange","LaurentLowerBound","Assumptions","Domain","RealLetterPrescription"}],metadata,
    Lookup[Lookup[request,"MetadataByResult",<||>],name,<||>],
    <|"LaurentLowerBound"->Max[0,result["LaurentLowerBound"]],"PoleCancellationVerified"->True,
      "PoleCancellationVerificationMethod"->check["Method"],"PoleCancellationCheck"->summary,
      "FiniteExpressionBasis"->Lookup[request,"FiniteExpressionBasis","Explicit scalar functions"],
      "UnresolvedIntegrals"->False|>]]],
 {name,Keys[results]}];out
];

End[];EndPackage[];
