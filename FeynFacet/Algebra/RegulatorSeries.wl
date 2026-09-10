(* Finite expansion in a regulator with exact coefficient-field substitution.
   Temporary symbols are restored before any mathematical result is returned. *)
Begin["FeynFacet`Private`"];
Clear[regulatorSeries,regulatorSeriesCoefficients];
regulatorSeriesCoefficients[expression_,e_,range:{_Integer,_Integer}]:=
 regulatorSeries[expression,e,Last[range],range];
regulatorSeries[expression_,e_,upper_,requestedRange_:None] := Catch[Module[
 {constants=<||>,rules={},constant,reduce,small,series,lower,result,free,dependent,shift,polynomial,hypergeometric},
 If[expression===0,Return[If[requestedRange===None,{Infinity,0},Association@Table[k->0,{k,First[requestedRange],Last[requestedRange]}]]]];
 If[FreeQ[expression,e],Return[If[requestedRange===None,{0,expression},
   Association@Table[k->If[k===0,expression,0],{k,First[requestedRange],Last[requestedRange]}]]]];
 (* A zero or negative parameter excess at unit argument is not obtained
    by substituting epsilon=0 into the terminating series. Keep the regulated
    hypergeometric family intact until its continuation has been expanded. *)
 If[Cases[expression,h_HypergeometricPFQ/;Last[h]===1&&!FreeQ[h,e],{0,Infinity}]=!={},
  hypergeometric=FeynFacet`ExpandHypergeometricLaurentSeries[expression,e,upper];
  If[FailureQ[hypergeometric],Throw[hypergeometric,"RegulatorSeries"]];
  lower=hypergeometric["LaurentLowerBound"];polynomial=hypergeometric["Polynomial"];
  Return[If[requestedRange===None,{lower,polynomial},
    Association@Table[k->Coefficient[Expand[e^-Min[lower,First[requestedRange]]polynomial],e,
       k-Min[lower,First[requestedRange]]],{k,First[requestedRange],Last[requestedRange]}]],Module]];
 If[Head[expression]===Plus,
   series=regulatorSeries[#,e,upper,requestedRange]& /@ List@@expression;
   If[AnyTrue[series,FailureQ],Throw[First[Select[series,FailureQ]],"RegulatorSeries"]];
   Return[If[requestedRange===None,{Min[First/@series],Total[Last/@series]},Merge[series,Total]]]];
 constant[z_] := If[AtomQ[z] || NumberQ[z],z,Module[{symbol=Lookup[constants,Key[z],None]},
   If[symbol===None,symbol=Unique["epsilonCoefficient"];AssociateTo[constants,z->symbol];
     AppendTo[rules,symbol->z]];symbol]];
 reduce[z_] := Which[
  z===e,e,FreeQ[z,e],constant[z],
  Head[z]===Power,Power[reduce[z[[1]]],Expand[reduce[z[[2]]]]],
  PolynomialQ[z,e],Module[{monomials=CoefficientRules[z,{e}]},
    If[ListQ[monomials]&&AllTrue[monomials,
       MatchQ[First[#],{_Integer}]&&FreeQ[Last[#],e]&],
     Total[(constant[Last[#]] e^First[First[#]])&/@monomials],
     Map[reduce,z]]],
  MemberQ[{Plus,Times},Head[z]],Module[{parts=List@@z,freeParts,dependentParts},
    freeParts=Select[parts,FreeQ[#,e]&];dependentParts=Select[parts,!FreeQ[#,e]&];
    Apply[Head[z],Join[{constant[Apply[Head[z],freeParts]]},reduce /@ dependentParts]]],
  True,Map[reduce,z]];
 small=reduce[expression];
 series=Quiet[Check[Series[small,{e,0,upper}],$Failed]];
 If[series===$Failed || !FreeQ[series,_Series | Indeterminate | ComplexInfinity],
   Throw[Failure["RegulatorSeriesNotConstructed",<||>],"RegulatorSeries"]];
 (* Series may return Exp[SeriesData[...]] for an essential singularity.
    Such a nested, unfinished expansion is not a finite Laurent series.
    Validate before coefficient lookup can mistake the missing terms for zero. *)
 lower=If[Head[series]===SeriesData,
   If[series[[1]]=!=e||series[[2]]=!=0||series[[6]]=!=1,
     Throw[Failure["NonintegerRegulatorPowers",<||>],"RegulatorSeries"]];
   If[!FreeQ[series[[3]],e|_SeriesData],
     Throw[Failure["NonLaurentRegulatorDependence",<||>],"RegulatorSeries"]];
   series[[4]],
   If[!FreeQ[series,_SeriesData],
     Throw[Failure["NonLaurentRegulatorDependence",<||>],"RegulatorSeries"]];
   Exponent[series,e,Min]];
 If[!(IntegerQ[lower]||lower===Infinity)||
   (IntegerQ[lower]&&!PolynomialQ[Expand[e^-lower Normal[series],e],e]),
   Throw[Failure["NonLaurentRegulatorDependence",<||>],"RegulatorSeries"]];
 (* Extract epsilon coefficients while the large kinematic coefficient field
    is still represented by temporary symbols. Expanding after restoration
    needlessly distributes those coefficients into huge repeated sums. *)
 result=Which[requestedRange===None,Normal[series],
   Head[series]===SeriesData,
   Association@Table[k->If[1<=k-series[[4]]+1<=Length[series[[3]]],
     series[[3,k-series[[4]]+1]],0],{k,First[requestedRange],Last[requestedRange]}],
   True,
   shift=Min[First[requestedRange],lower];
   polynomial=Expand[e^-shift Normal[series],e];
   If[!PolynomialQ[polynomial,e],Throw[Failure["NonintegerRegulatorPowers",<||>],"RegulatorSeries"]];
   Association@Table[k->Coefficient[polynomial,e,k-shift],{k,First[requestedRange],Last[requestedRange]}]];
 result=result/.Dispatch[rules];
 If[Cases[result,_Derivative,{0,Infinity},Heads->True]=!={},
   Throw[Failure["UnevaluatedSpecialFunctionParameterDerivatives",<||>],"RegulatorSeries"]];
 If[!FreeQ[result,Alternatives@@(First/@rules)] && rules=!={},
   Throw[Failure["RegulatorCoefficientRestorationFailed",<||>],"RegulatorSeries"]];
 If[requestedRange===None,{lower,result},result]
],"RegulatorSeries"];
End[];
