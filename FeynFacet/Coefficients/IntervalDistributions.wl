(* Both endpoints of one measured interval. Each endpoint subtraction
   acts on the same test function; the two endpoints are not tensor axes. *)
BeginPackage["FeynFacet`"];
ConvertUnitIntervalResultToFinitePart::usage="ConvertUnitIntervalResultToFinitePart[result,assumptions] converts a completed standard delta/logarithmic-plus/regular partonic result to linear endpoint interpolation by retaining its full interior and calculating its original zeroth and first moments. Every moment must evaluate explicitly; unresolved integrals fail. Existing finite-part results are returned unchanged.";
IntervalFinitePart::usage="IntervalFinitePart[f,{z,0,1}] denotes the distribution whose action is integral_0^1 f(z) (phi(z)-(1-z)phi(0)-z phi(1)) dz. The complete weighted kernel z(1-z) f must be integrable. Its zeroth and first moments vanish. It is not an ordinary function or the conventional single-endpoint plus distribution.";
CompleteUnitIntervalDistributionFromMoments::usage="CompleteUnitIntervalDistributionFromMoments[interior,moments,proofs,{z,epsilon},range] fixes an explicit interval finite part and its two endpoint contacts from generated zeroth/first moments. Each proof must establish uniform finite-meromorphic integrability of z(1-z) times the original complete density and contact order zero. No separately computed self contacts may be added afterward. The output convention is LinearEndpointInterpolation, distinct from ordinary logarithmic plus coefficients.";
ExpandUnitIntervalDistribution::usage="ExpandUnitIntervalDistribution[interior,endpointSeries,contacts,{z,epsilon},{low,high},assumptions] combines a known interior Laurent expansion, regulator-exact Gauss endpoint series and explicit contacts into full closed-unit-interval distributions. Contacts maps endpoint 0 or 1 to its exact epsilon-dependent coefficient. The present constructor requires endpoint powers -1+b epsilon; more singular powers fail. It retains raw Laurent poles and computes delta coefficients by meromorphic continuation, not by fitting moments.";
UnitIntervalDistributionExpression::usage="UnitIntervalDistributionExpression[row,z] renders DeltaCoefficients, PlusCoefficients and RegularCoefficient as explicit EndpointDeltaDerivative and EndpointPlusDistribution expressions.";
UnitIntervalDistributionMoment::usage="UnitIntervalDistributionMoment[row,z,n,assumptions] integrates a completed distribution against z^n, including both endpoints with unit delta mass.";
Begin["`Private`"];
ConvertUnitIntervalResultToFinitePart[result_Association,assumptions_:True]:=Catch[Module[
 {record,basis,z,interior,rows,moments},
 record=FeynFacet`ReadPartonicResult[result];
 If[!AssociationQ[record],Throw[record,"IntervalDistribution"]];basis=record["DistributionBasis"];
 If[Lookup[basis,"Representation",None]==="UnitIntervalFinitePart",Return[record,Module]];
 If[Lookup[basis,"Representation",None]=!="UnitInterval",Throw[Failure["CompletedUnitIntervalResultRequired",<||>],"IntervalDistribution"]];
 z=basis["Variable"];interior=FeynFacet`PartonicResultInteriorCoefficients[record];
 moments=Map[Function[row,Table[FeynFacet`UnitIntervalDistributionMoment[row,z,n,assumptions],{n,0,1}]],record["Coefficients"]];
 If[!FreeQ[moments,_Integrate|_NIntegrate|_ConditionalExpression|_Failure|_Missing|Indeterminate|_DirectedInfinity],
  Throw[Failure["ExplicitOriginalIntervalMomentsRequired",<||>],"IntervalDistribution"]];
 rows=Association@KeyValueMap[#1-><|"Variable"->z,"FinitePartKernel"->interior["Coefficients"][#1],
   "DeltaCoefficients"-><|0->(#2[[1]]-#2[[2]]),1->#2[[2]]|>|>&,moments];
 FeynFacet`CreatePartonicResult[rows,Join[record,<|"DistributionBasis"->Join[basis,<|"Representation"->"UnitIntervalFinitePart"|>],
   "DistributionConversion"->"Original zeroth and first moments retained under linear endpoint interpolation."|>]]
],"IntervalDistribution"];
CompleteUnitIntervalDistributionFromMoments[interior_Association,moments_Association,proofs_List,
 {z_Symbol,e_Symbol},range:{lo_Integer,hi_Integer}]:=Catch[Module[{orders,rows},
 orders=Range[lo,hi];
 If[lo>hi||!ContainsAll[Keys[interior],orders]||!ContainsAll[Keys[moments],orders]||
   !AllTrue[Lookup[moments,orders],MatchQ[#,{_,_}]&]||
   !FreeQ[{Lookup[interior,orders],Lookup[moments,orders]},e|_Integrate|_Series|_SeriesData|_Failure|_Missing],
  Throw[Failure["ExplicitIntervalInteriorAndMomentOrdersRequired",<||>],"IntervalDistribution"]];
 If[proofs==={}||!AllTrue[proofs,AssociationQ[#]&&
   Lookup[#,"Format",None]==="FeynFacet-MeasuredEndpointContactOrder"&&Lookup[#,"Variable",None]===z&&
   Lookup[#,"Interval",None]==={0,1}&&Lookup[#,"ContactDerivativeOrderBound",None]===0&&
   TrueQ[Lookup[#,"CompleteEnergyMeasurementCoverVerified",False]]&&
   TrueQ[Lookup[#,"RegulatorMeromorphicityVerified",False]]&&
   TrueQ[Lookup[#,"OriginalExternalPrescriptionsIncluded",False]]&],
  Throw[Failure["UniformWeightedInteriorAndOrdinaryContactProofRequired",<||>],"IntervalDistribution"]];
 rows=Association@Table[n-><|"FinitePartKernel"->interior[n],"Variable"->z,
   "DeltaCoefficients"-><|0->(moments[n][[1]]-moments[n][[2]]),1->moments[n][[2]]|>|>,{n,orders}];
 <|"Format"->"FeynFacet-IntervalFinitePartDistribution","Coefficients"->rows,
   "EpsilonRange"->range,"DimensionalRegulator"->e,"Variable"->z,"Interval"->{0,1},
   "DistributionConvention"->"LinearEndpointInterpolation",
   "FinitePartDefinition"->"Integral of the complete kernel times phi(z)-(1-z) phi(0)-z phi(1) on [0,1]. Its zeroth and first moments vanish; endpoint deltas have unit mass.",
   "EndpointDistributionsSolved"->True,"SelfContactsIncludedThroughMoments"->True|>
],"IntervalDistribution"];
intervalDistributionCollect[value_,assumptions_]:=
 partonicCollect[FeynFacet`ExpandPositiveLogarithms[value,assumptions]];
intervalDistributionSeries[value_,e_,hi_,assumptions_]:=Module[{result},
 result=Normal[Series[value,{e,0,hi}]];
 If[!FreeQ[result,_Series|_SeriesData|_SeriesCoefficient|Indeterminate|_DirectedInfinity|_Failure],
  Throw[Failure["ExplicitIntervalLaurentSeriesRequired",<|"Value"->value|>],"IntervalDistribution"]];
 Collect[Expand[result],e,intervalDistributionCollect[#,assumptions]&]
];
ExpandUnitIntervalDistribution[interior_Association,endpoints_List,contacts_Association,
 {z_Symbol,e_Symbol},range:{lo_Integer,hi_Integer},assumptions_:True]:=Catch[Module[
 {deltas=AssociationThread[{0,1},{0,0}],pluses=<||>,models=<||>,records={},p,b,c,point,log=Unique["endpointLog$"],
  poly,deltaSeries,plusSeries,rows,regular,distance,keys,coefficient,expression,orders},
 If[lo>hi||Sort[Lookup[endpoints,"Endpoint"]]=!={0,1}||!SubsetQ[{0,1},Keys[contacts]]||
  !ContainsAll[Keys[interior],Range[lo,hi]],Throw[Failure["TwoEndpointLaurentDataRequired",<||>],"IntervalDistribution"]];
 Do[
  point=data["Endpoint"];
  If[data["Variable"]=!=z||data["DimensionalRegulator"]=!=e||!TrueQ[data["RemainderLocallyIntegrable"]],
   Throw[Failure["MatchingProvedEndpointExpansionRequired",<||>],"IntervalDistribution"]];
  Do[
   p=term["LogPower"];b=Coefficient[term["Power"],e];c=term["Coefficient"];
   If[(term["Power"]/.e->0)=!=-1||!FreeQ[c,z]||!IntegerQ[p]||p<0||
      !TrueQ[FullSimplify[b!=0,Assumptions->assumptions]],
    Throw[Failure["RegulatedSimpleEndpointPowersRequired",<|"Term"->term|>],"IntervalDistribution"]];
   deltas[point]+=c (-1)^p p!/(b e)^(p+1);
   (* Exp[b epsilon log(t)] determines the plus coefficients. The delta
      moment requires p+1 more epsilon orders, accounted for by Series
      of the complete meromorphic product and the common tail audit. *)
   orders=hi+p+1;
   FeynFacet`Private`epsilonAuditMultiplier[(-1)^p p!/(b e)^(p+1),e,
     FeynFacet`DetermineMeromorphicLaurentLowerBound[c,e],orders,hi,"MeasuredEndpointMoment",{point,p}];
   AppendTo[records,<|"Endpoint"->point,"LogPower"->p,"DeltaPrefactorThroughOrder"->orders|>];
   poly=intervalDistributionSeries[c Exp[b e log]log^p,e,hi,assumptions];
   Do[coefficient=Coefficient[poly,e,n];
    Do[If[Coefficient[coefficient,log,k]=!=0,
      keys={n,point,k};AssociateTo[pluses,keys->(Lookup[pluses,Key[keys],0]+Coefficient[coefficient,log,k])]],
     {k,0,Max[0,Exponent[coefficient,log]]}],{n,lo,hi}],
  {term,data["Terms"]}],{data,endpoints}];
 deltas=Map[intervalDistributionSeries[#,e,hi,assumptions]&,Association@Table[
   point->(deltas[point]+Lookup[contacts,point,0]),{point,{0,1}}]];
 rows=Association@Table[
  models=Association@Table[point->Association@Table[k->intervalDistributionCollect[Lookup[pluses,Key[{n,point,k}],0],
      assumptions],{k,DeleteDuplicates[Last/@Select[Keys[pluses],#[[1]]===n&&#[[2]]===point&]]}],{point,{0,1}}];
  regular=interior[n]-Sum[Total[KeyValueMap[#2 Log[If[point===0,z,1-z]]^#1/If[point===0,z,1-z]&,models[point]]],{point,{0,1}}];
  n-><|"DeltaCoefficients"->Map[intervalDistributionCollect[Coefficient[#,e,n],assumptions]&,deltas],
    "PlusCoefficients"->models,"RegularCoefficient"->intervalDistributionCollect[regular,assumptions&&0<z<1]|>,
  {n,lo,hi}];
 <|"Coefficients"->rows,"EpsilonRange"->range,"DimensionalRegulator"->e,
  "Variable"->z,"Interval"->{0,1},"EndpointOrderRequirements"->records,
  "PlusConvention"->"Full unit interval: each plus term subtracts the test function value at its own endpoint; endpoint deltas have unit mass.",
  "EndpointCoefficientMethod"->"Meromorphic continuation of regulator-exact endpoint terms plus generated explicit contact integrals"|>
],"IntervalDistribution"];
UnitIntervalDistributionExpression[row_Association,z_Symbol]/;KeyExistsQ[row,"FinitePartKernel"]:=
 If[row["FinitePartKernel"]===0,0,FeynFacet`IntervalFinitePart[row["FinitePartKernel"],{z,0,1}]]+
 Total[KeyValueMap[#2 FeynFacet`EndpointDeltaDerivative[If[#1===0,z,1-z],0,1]&,row["DeltaCoefficients"]]];
UnitIntervalDistributionExpression[row_Association,z_Symbol]:=row["RegularCoefficient"]+
 Total[KeyValueMap[#2 FeynFacet`EndpointDeltaDerivative[If[#1===0,z,1-z],0,1]&,row["DeltaCoefficients"]]]+
 Total[KeyValueMap[Function[{point,terms},Total[KeyValueMap[
  #2 FeynFacet`EndpointPlusDistribution[If[point===0,z,1-z],-1,#1,1,1]&,terms]]],row["PlusCoefficients"]]];
UnitIntervalDistributionMoment[row_Association,z_Symbol,n_Integer?NonNegative,assumptions_:True]/;
 KeyExistsQ[row,"FinitePartKernel"]:=If[n===0,Total[Values[row["DeltaCoefficients"]]],
 If[n===1,row["DeltaCoefficients"][1],row["DeltaCoefficients"][1]+
  Integrate[(z^n-z)row["FinitePartKernel"],{z,0,1},Assumptions->assumptions,GenerateConditions->False]]];
UnitIntervalDistributionMoment[row_Association,z_Symbol,n_Integer?NonNegative,assumptions_:True]:=Module[{regular,delta,plus},
 regular=Integrate[z^n row["RegularCoefficient"],{z,0,1},Assumptions->assumptions,GenerateConditions->False];
 delta=Total[KeyValueMap[#2 If[n===0,1,#1^n]&,row["DeltaCoefficients"]]];
 plus=Total[KeyValueMap[Function[{point,terms},Total[KeyValueMap[
  #2 Integrate[Log[If[point===0,z,1-z]]^#1/If[point===0,z,1-z]*(z^n-If[n===0,1,point^n]),
   {z,0,1},GenerateConditions->False]&,terms]]],row["PlusCoefficients"]]];
 FullSimplify[regular+delta+plus,Assumptions->assumptions]
];
End[];EndPackage[];
