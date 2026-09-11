(* Pre-interpolation epsilon demands from the full regulated endpoint germ.
   The rational numerator is polynomial, hence its epsilon valuation is >=0.
   Every denominator has fixed epsilon/normal powers and a proved joint analytic unit. *)
BeginPackage["FeynFacet`"];
DetermineCoefficientReconstructionOrders::usage =
 "DetermineCoefficientReconstructionOrders[inventory,endpoint,bounds,request] proves a fixed normal-pole class for rational coefficient tails and derives sufficient epsilon reconstruction orders. The request supplies alias decoding, kinematic rules, the matched master row, prefactors and the endpoint domain.";
Begin["`Private`"];
coefficientDivisorSeparation[expression_,e_Symbol] := Module[
 {poly=Expand[expression],variables,coefficients,ep,order,constant,kin,factors,mixed=1},
 variables=DeleteCases[Variables[poly],e];
 If[!PolynomialQ[poly,Append[variables,e]]||poly===0,
  Return[Failure["PolynomialDivisorRequired",<||>]]];
 If[variables==={},Return[<|"RegulatorFactor"->poly,"KinematicFactor"->1,
   "EpsilonValuation"->Exponent[poly,e,Min],"MixedUnit"->1|>]];
 coefficients=CoefficientRules[poly,variables];
 ep=Last[First[coefficients]];order=Exponent[ep,e,Min];constant=Coefficient[ep,e,order];
 kin=Expand[Coefficient[poly,e,order]/constant];
 If[Expand[poly-ep kin]=!=0||!FreeQ[kin,e],
  factors=FactorList[poly];ep=1;kin=1;
  Do[Which[FreeQ[factor[[1]],e],kin*=factor[[1]]^factor[[2]],
    FreeQ[factor[[1]],Alternatives@@variables],ep*=factor[[1]]^factor[[2]],
    True,mixed*=factor[[1]]^factor[[2]]],{factor,factors}];
  If[Expand[poly-ep kin mixed]=!=0,Return[Failure["DivisorFactorizationIdentityFailed",<||>]]];
  order=Exponent[Expand[ep],e,Min]];
 <|"RegulatorFactor"->ep,"KinematicFactor"->kin,"MixedUnit"->mixed,"EpsilonValuation"->order|>
];

(* The same exact divisor classification drives partition discovery and the
   final order proof. An unproved unit stays in the exact coefficient part. *)
coefficientAnalyzeDivisors[inventory_,e_,z_,names_,originals_,rules_,domain_] := Module[
 {unitCache=<||>},
 Map[Function[text,Catch[Module[
  {expression,separated,mapped,normal,mixedLeading,leading,variables,ok},
  expression=reconstructionParseBlock[text,names,originals];
  If[FailureQ[expression],Throw[expression]];
  expression=coefficientRegulatorNormalize[expression,e];
  separated=coefficientDivisorSeparation[expression,e];
  If[FailureQ[separated],Throw[separated]];
  mapped=Expand[separated["KinematicFactor"]/.rules];
  If[!PolynomialQ[mapped,z]||mapped===0,
   Throw[Failure["PolynomialNormalDivisorRequired",<||>]]];
  normal=Exponent[mapped,z,Min];
  mixedLeading=Expand[(separated["MixedUnit"]/.rules)/.{e->0,z->0}];
  leading=Factor[Coefficient[mapped,z,normal]*mixedLeading];
  If[!KeyExistsQ[unitCache,leading],
   variables=DeleteDuplicates@Join[Variables[leading],Cases[domain,s_Symbol/;Context[s]=!="System`",{0,Infinity}]];
   ok=If[variables==={},leading=!=0,
    With[{vars=variables,condition=domain&&leading==0},
     TrueQ[TimeConstrained[Resolve[Exists[vars,condition],Reals],5,$Failed]===False]]];
   AssociateTo[unitCache,leading->ok]];
  If[!TrueQ[unitCache[leading]],
   Throw[Failure["TangentialDivisorUnitNotEstablished",<|"LeadingDivisor"->leading,
     "Domain"->domain,"Divisor"->expression,"Separation"->separated|>]]];
  Join[separated,<|"NormalOrder"->normal,"LeadingNormalCoefficient"->leading|>]
 ]]],inventory["Divisors"]]
];

(* Coordinate substitutions must preserve polynomial epsilon numerators.
   Rational parameter coefficients are allowed only with proved nonzero
   denominators independent of the regulator and the normal coordinate. *)
coefficientOrderCoordinateRulesQ[rules_,e_,z_,domain_] := Module[
 {normalized,values,variables,denominators,analysis},
 normalized=coefficientRegulatorNormalize[rules,e];
 If[!coefficientPlanRulesQ[normalized],Return[False]];
 If[AnyTrue[normalized,If[First[#]===e,Last[#]=!=e,!FreeQ[Last[#],e]]&],Return[False]];
 values=Last/@Select[normalized,First[#]=!=e&];
 variables=DeleteDuplicates@Cases[values,s_Symbol/;Context[s]=!="System`",{0,Infinity}];
 If[!AllTrue[values,PolynomialQ[Numerator[Together[#]],variables]&&
    PolynomialQ[Denominator[Together[#]],variables]&],Return[False]];
 denominators=DeleteDuplicates[Denominator[Together[#]]&/@values];
 If[!FreeQ[denominators,e|z],Return[False]];
 analysis=coefficientAnalyzeDivisors[<|"Divisors"->(("coordinateDen"<>ToString[#]&/@Range[Length[denominators]]))|>,
   e,z,("coordinateDen"<>ToString[#]&/@Range[Length[denominators]]),
   AssociationThread[("coordinateDen"<>ToString[#]&/@Range[Length[denominators]]),denominators],{},domain];
 !AnyTrue[analysis,FailureQ]
];

DetermineCoefficientReconstructionOrders[inventory_Association,endpoint_Association,
 bounds_Association,request_Association] := Catch[Module[
 {e,z,row,target,names,originals,rules,domain,pref,pv,uniform,sectors,active,sectorLow,
  low,upper,divisors,profiles,epsilonPoles,normalPoles,maximumPole,minimumEpsilon,
  source,scope,normalGaugeLower},
 {e,z}=Lookup[endpoint,{"DimensionalRegulator","NormalVariable"}];
 {row,target,names,originals,rules,domain,pref}=Lookup[request,
   {"MasterRow","ThroughOrder","AliasNames","AliasOriginals","KinematicRules","Assumptions","PreFactor"}];
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem"||
   Lookup[bounds,"DataType",None]=!="TangentialEndpointLaurentBounds"||
   !IntegerQ[row]||!TrueQ[1<=row<=endpoint["Dimension"]]||!IntegerQ[target]||
   !ListQ[names]||!AssociationQ[originals]||!ListQ[rules]||MissingQ[domain],
   Throw[Failure["CoefficientOrderInputsRequired",<||>]]];
 If[!coefficientOrderCoordinateRulesQ[rules,e,z,domain],
  Throw[Failure["PolynomialCoefficientCoordinateRulesRequired",<||>]]];
 source=Lookup[request,"Source",None];
 If[AssociationQ[source]&&KeyExistsQ[source,"ExpressionFile"],
  If[projectAbsolutePath[Lookup[inventory,"Source",""]]=!=projectAbsolutePath[source["ExpressionFile"]]||
    Lookup[inventory,"SourceSHA256",None]=!=coefficientFileHash[source["ExpressionFile"]],
   Throw[Failure["DivisorInventorySourceBindingMismatch",<|"InventorySource"->Lookup[inventory,"Source",None],"RequestedSource"->source["ExpressionFile"],"InventoryHash"->Lookup[inventory,"SourceSHA256",None],"ActualHash"->coefficientFileHash[source["ExpressionFile"]]|>]]]];
 pref=coefficientRegulatorNormalize[If[TrueQ[Lookup[request,"PreFactorInEndpointCoordinates",False]],pref,pref/.rules],e];
 If[!FreeQ[pref,z],Throw[Failure["NormalDependentPrefactorNeedsTailAnalysis",<||>]]];
 pv=FeynFacet`DetermineMeromorphicLaurentLowerBound[pref,e];
 If[!IntegerQ[pv],Throw[Failure["PrefactorLaurentBoundRequired",<|"Value"->pv|>]]];
 sectors=endpoint["PrimarySectors"];
 uniform=Lookup[bounds,"UniformPrimarySectorOriginalCoefficientLaurentLowerBounds",<||>];
 If[!AssociationQ[uniform]||!AllTrue[Lookup[sectors,"Exponent"],KeyExistsQ[uniform,#]&],
  Throw[Failure["UniformPrimarySectorBoundsRequired",<||>]]];
 active=Select[sectors,uniform[#["Exponent"]][[row]]=!=Infinity&];
 If[active==={},Throw[Failure["StructurallyAbsentMasterRequiresExactZeroHandling",<||>]]];
 If[!AllTrue[Lookup[active,"Exponent"],PolynomialQ[#,e]&&Exponent[#,e]<=1&&TrueQ[(#/.e->0)===0]&],
  Throw[Failure["LinearRegulatorPrimaryExponentsRequired",<||>]]];
 divisors=coefficientAnalyzeDivisors[inventory,e,z,names,originals,rules,domain];
 If[AnyTrue[divisors,FailureQ],Throw[First[Select[divisors,FailureQ]]]];
 profiles=inventory["Products"];
 If[profiles==={},Throw[Failure["NonemptyDenominatorProductInventoryRequired",<||>]]];
 epsilonPoles=Table[Total[(#[[2]] divisors[[#[[1]]]]["EpsilonValuation"])&/@profile["Factors"]],
   {profile,profiles}];
 normalPoles=Table[Total[(#[[2]] divisors[[#[[1]]]]["NormalOrder"])&/@profile["Factors"]],
   {profile,profiles}];
 minimumEpsilon=-Max[epsilonPoles];maximumPole=Max[normalPoles];
 (* A zero-slope singular sector has no dimensional continuation for an
    arbitrary omitted tail. It cannot be assigned a fictitious 1/epsilon. *)
 normalGaugeLower=Min[coefficientEndpointNormalOrder[#,z]&/@endpoint["NormalGaugeMatrix"][[row]]];
 If[AnyTrue[active,#["Exponent"]===0&]&&maximumPole>normalGaugeLower,
  Throw[Failure["ZeroSlopeCoefficientTailNeedsCancellation",<||>]]];
 sectorLow=Table[uniform[sector["Exponent"]][[row]]-sector["NilpotencyIndex"],{sector,active}];
 If[!VectorQ[sectorLow,IntegerQ],Throw[Failure["IntegerEndpointPoleBoundsRequired",<||>]]];
 low=Min[sectorLow];upper=target-pv-low;
 scope="The supplied complete physical endpoint germ, uniformly on compact subsets of its stated tangential domain, and generic interior kinematics away from fixed divisors.";
 <|"DataType"->"CoefficientReconstructionOrders","Status"->"SufficientOrdersDetermined",
   "MasterRow"->row,"Master"->endpoint["OriginalMasterIntegralBasis"][[row]],
   "ThroughOrder"->target,"DimensionalRegulator"->e,
   "CoefficientLaurentLowerBound"->minimumEpsilon,
   "RequiredCoefficientUpperOrder"->upper,"PrefactorLaurentLowerBound"->pv,
   "EndpointDistributionLaurentLowerBound"->low,"NormalPoleOrderUpperBound"->maximumPole,
   "LaurentRemainderClass"-><|"Status"->"EstablishedForSourceCoefficient",
     "NormalDivisor"->z,"EpsilonOrderLowerBound"->upper+1,
     "NormalPoleOrderUpperBound"->maximumPole,"UniformOnTangentialCompactSets"->True,
     "Justification"-><|"Method"->"Exact regulator/kinematic factors, proved joint analytic units and uniform physical primary-sector bounds",
       "Source"->Lookup[request,"Source",None],"SourceSHA256"->Lookup[inventory,"SourceSHA256",None],"TangentialAssumptions"->domain|>|>,
   "DivisorAnalysis"->divisors,"DenominatorProductCount"->Length[profiles],
   "Scope"->scope,"InputBindings"->Join[KeyTake[request,{"Source","CatalogMapping","PreFactor","KinematicRules",
     "Assumptions","TraceColumnBinding","SourceDefinitions","PhysicalNormalizationRequest",
     "PhysicalNormalizationConstruction","AcceptedEndpointBinding","PhysicalFrameBinding",
     "PreFactorInEndpointCoordinates"}],
      <|"SourceSHA256"->Lookup[inventory,"SourceSHA256",None],
        "EndpointSystem"->endpoint,"LaurentBounds"->bounds|>]|>
]];
End[];
EndPackage[];
