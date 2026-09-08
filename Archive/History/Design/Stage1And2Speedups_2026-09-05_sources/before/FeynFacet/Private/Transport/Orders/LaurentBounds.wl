(* Exact Laurent valuations and pole bounds for explicitly resolved integrals. *)
Begin["FeynFacet`Private`"];
Clear[epsOrderFail,epsOrderZero,epsOrderValuation,epsOrderBound,epsOrderKnownBoundQ,
 epsOrderRegularRationalQ,epsOrderIntegralBound,epsOrderSectorBound,epsOrderNormalize];
epsOrderFail[tag_,data_:<||>] := Throw[Failure[tag,data],"EpsilonOrders"];
(* Normalize package-specific copies of the declared regulator once at entry. *)
epsOrderNormalize[z_,e_Symbol] := z /. s_Symbol /;
  MemberQ[DeleteDuplicates[{SymbolName[e],"eps","ep","Epsilon"}],SymbolName[s]] :> e;
epsOrderZero[z_] := TrueQ[z===0] || TrueQ[Cancel[Together[z]]===0];

epsOrderValuation[z_,e_] := Module[{r,arg,a,v,parts},
 If[!FreeQ[z,_Real|Indeterminate|DirectedInfinity[_]],epsOrderFail["ExactMeromorphicExpressionRequired"]];
 If[epsOrderZero[z],Return[Infinity]];
 If[FreeQ[z,e],Return[0]];
 r=Together[z];
 If[PolynomialQ[Numerator[r],e] && PolynomialQ[Denominator[r],e],
  Return[Exponent[Numerator[r],e,Min]-Exponent[Denominator[r],e,Min]]];
 Which[
 Head[z]===Times,Total[epsOrderValuation[#,e]& /@ List@@z],
 Head[z]===Power && IntegerQ[z[[2]]],z[[2]] epsOrderValuation[z[[1]],e],
 Head[z]===Gamma,
  arg=z[[1]];a=Quiet[Limit[arg,e->0]];
  If[!NumericQ[a] || !FreeQ[a,Indeterminate|DirectedInfinity[_]],
    epsOrderFail["GammaArgumentLimitNotEstablished"]];
  If[IntegerQ[a] && a<=0,
    v=epsOrderValuation[arg-a,e];
    If[!IntegerQ[v] || v<=0,epsOrderFail["UnregulatedGammaPole"]];
    -v,0],
 Head[z]===Exp,
  v=epsOrderValuation[z[[1]],e];
  If[v<0,epsOrderFail["EssentialRegulatorSingularity"]];0,
 Head[z]===Power && FreeQ[z[[1]],e] && !epsOrderZero[z[[1]]],
  v=epsOrderValuation[z[[2]],e];
  If[v<0,epsOrderFail["EssentialRegulatorSingularity"]];0,
 True,epsOrderFail["LaurentValuationNotEstablished",<|"Expression"->z|>]]
];
FeynFacet`DetermineLaurentValuation[z_,e_Symbol] :=
 Catch[epsOrderValuation[epsOrderNormalize[z,e],e],"EpsilonOrders"];

epsOrderKnownBoundQ[z_] := AssociationQ[z] &&
 Lookup[z,"DataType",None]==="IntegralLaurentBound" &&
 Lookup[z,"Status",None]==="BoundEstablishedForRepresentation" &&
 (IntegerQ[Lookup[z,"LowerBound",None]] || Lookup[z,"LowerBound",None]===Infinity);
epsOrderBound[z_] := Which[
 IntegerQ[z] || z===Infinity,z,
 epsOrderKnownBoundQ[z],z["LowerBound"],
 True,Missing["LaurentLowerBoundNotEstablished"]];

(* A nonvanishing denominator on the closed parameter cube establishes a
   common epsilon neighborhood for a rational regular part. No numerical
   zero samples are used. *)
epsOrderRegularRationalQ[g_,xs_,e_,seconds_] := Module[{r,den,constants,condition,coefficients,constant},
 r=Together[g];
 If[!PolynomialQ[Numerator[r],Append[xs,e]] ||
    !PolynomialQ[Denominator[r],Append[xs,e]],Return[False]];
 den=Expand[Denominator[r]/.e->0];
 constants=Variables[den];If[Complement[constants,xs]=!={},Return[False]];
 If[!FreeQ[den,_Real] || !PolynomialQ[den,xs],Return[False]];
 If[FreeQ[den,Alternatives@@xs],Return[!epsOrderZero[den]]];
 coefficients=Last /@ CoefficientRules[den,xs];
 constant=den/.Thread[xs->0];
 If[(TrueQ[constant>0] && AllTrue[coefficients,TrueQ[#>=0]&]) ||
    (TrueQ[constant<0] && AllTrue[coefficients,TrueQ[#<=0]&]),Return[True]];
 condition=And@@Join[Thread[xs>=0],Thread[xs<=1]];
 TrueQ[TimeConstrained[Resolve[Exists[xs,condition && den==0],Reals],seconds,$Failed]===False]
];

epsOrderSectorBound[s_,e_,seconds_] := Module[
 {xs,powers,logs,g,pref,atZero,resonant,loss,bound,monomials,integrated,coeff,exps,moment},
 xs=Lookup[s,"IntegrationVariables",{}];powers=Lookup[s,"EndpointPowers",{}];
 logs=Lookup[s,"LogPowers",ConstantArray[0,Length[xs]]];
 g=Lookup[s,"RegularFactor",1];pref=Lookup[s,"Prefactor",1];
 If[xs==={} || !VectorQ[xs,MatchQ[#,_Symbol]&] || !DuplicateFreeQ[xs] ||
   MemberQ[xs,e] || Length[powers]=!=Length[xs] || Length[logs]=!=Length[xs] ||
   !VectorQ[logs,IntegerQ[#]&&#>=0&] || !FreeQ[pref,Alternatives@@xs],
   epsOrderFail["ResolvedIntegralVariablesInvalid"]];
 If[!epsOrderRegularRationalQ[g,xs,e,seconds],
   epsOrderFail["UniformRegularPartNotEstablished",
    <|"Required"->"A rational regular factor with denominator nonzero on the closed parameter cube at epsilon=0."|>]];
 If[epsOrderZero[g] || epsOrderZero[pref],Return[<|"LowerBound"->Infinity,"Method"->"IdenticallyZeroIntegrand"|>]];
 If[!AllTrue[powers,With[{z=Together[#]},
   PolynomialQ[Numerator[z],e] && PolynomialQ[Denominator[z],e]]&],
   epsOrderFail["RationalEndpointExponentRequired"]];
 atZero=Quiet[Limit[#,e->0]]& /@ powers;
 If[!VectorQ[atZero,MatchQ[#,_Integer|_Rational]&],
   epsOrderFail["EndpointExponentLimitsNotEstablished"]];
 resonant=Table[If[IntegerQ[atZero[[j]]] && atZero[[j]]<=-1,
   moment=powers[[j]]-atZero[[j]];
   If[epsOrderZero[moment],Infinity,(logs[[j]]+1) epsOrderValuation[moment,e]],0],{j,Length[xs]}];
 If[epsOrderZero[g] || epsOrderZero[pref],Return[<|"LowerBound"->Infinity,"Method"->"IdenticallyZeroIntegrand"|>]];
 (* Polynomial regular parts permit exact moment combination, often removing
    an apparent pole before any integral has to be evaluated numerically. *)
 If[PolynomialQ[g,xs],
  monomials=CoefficientRules[g,xs];
  integrated=Total[Table[
    exps=First[term];coeff=Last[term];
    coeff Times@@Table[
      moment=powers[[j]]+exps[[j]]+1;
      If[epsOrderZero[moment],epsOrderFail["EndpointNotRegulated"]];
      (-1)^logs[[j]] Factorial[logs[[j]]]/moment^(logs[[j]]+1),
    {j,Length[xs]}],{term,monomials}]];
  bound=If[epsOrderZero[integrated],Infinity,
    epsOrderValuation[pref,e]+epsOrderValuation[Cancel[integrated],e]];
  <|"LowerBound"->bound,"Method"->"ExactPolynomialMoments",
    "IntegratedRegularPart"->Cancel[integrated],"PrefactorValuation"->epsOrderValuation[pref,e]|>,
  If[MemberQ[resonant,Infinity],epsOrderFail["EndpointNotRegulated"]];
  loss=Total[resonant];
  bound=epsOrderValuation[pref,e]-loss;
  <|"LowerBound"->bound,"Method"->"ResolvedEndpointTaylorSubtraction",
    "PrefactorValuation"->epsOrderValuation[pref,e],"PotentialEndpointPoleOrders"->resonant|>
 ]
];
epsOrderIntegralBound[rep_,seconds_] := Module[{e,terms,reports},
 e=Lookup[rep,"DimensionalRegulator",None];terms=Lookup[rep,"Terms",{}];
 If[!TrueQ[seconds>0] || e===None || !MatchQ[e,_Symbol] || terms==={} || !AllTrue[terms,AssociationQ],
  epsOrderFail["ResolvedIntegralRepresentationRequired"]];
 reports=epsOrderSectorBound[#,e,seconds]& /@ terms;
 <|"DataType"->"IntegralLaurentBound","Status"->"BoundEstablishedForRepresentation",
   "LowerBound"->Min[Lookup[reports,"LowerBound"]],"TermBounds"->reports,
   "Representation"->rep,
   "Scope"->"The explicitly supplied sum of resolved integrals with its normalization. Identifying it with a cut or loop master requires the corresponding representation identity.",
   "IntegralValuesEvaluatedNumerically"->False|>
];
Options[FeynFacet`DetermineIntegralLaurentBound]={"RegularityProofTimeLimit"->5,
 "MaximumSectors"->512,"MaximumSectorDepth"->32};
FeynFacet`DetermineIntegralLaurentBound[rep_Association,OptionsPattern[]] :=
 Catch[Module[{d,e,seconds},
  e=Lookup[rep,"DimensionalRegulator",None];seconds=OptionValue["RegularityProofTimeLimit"];
  If[e===None || !MatchQ[e,_Symbol] || !TrueQ[seconds>0],
    epsOrderFail["IntegralRegulatorAndProofTimeRequired"]];
  d=epsOrderNormalize[rep,e];
  epsOrderParametricBound[d,e,seconds,OptionValue["MaximumSectors"],OptionValue["MaximumSectorDepth"]]
 ],"EpsilonOrders"];
End[];
