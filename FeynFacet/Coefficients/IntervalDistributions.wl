(* Both endpoints of one measured interval. Each endpoint subtraction
   acts on the same test function; the two endpoints are not tensor axes. *)
BeginPackage["FeynFacet`"];
ExpandUnitIntervalDistribution::usage="ExpandUnitIntervalDistribution[interior,endpointSeries,contacts,{z,epsilon},{low,high},assumptions] combines a known interior Laurent expansion, regulator-exact Gauss endpoint series and explicit contacts into full closed-unit-interval distributions. Contacts maps endpoint 0 or 1 to its exact epsilon-dependent coefficient. The present constructor requires endpoint powers -1+b epsilon; more singular powers fail. It retains raw Laurent poles and computes delta coefficients by meromorphic continuation, not by fitting moments.";
UnitIntervalDistributionExpression::usage="UnitIntervalDistributionExpression[row,z] renders DeltaCoefficients, PlusCoefficients and RegularCoefficient as explicit EndpointDeltaDerivative and EndpointPlusDistribution expressions.";
UnitIntervalDistributionMoment::usage="UnitIntervalDistributionMoment[row,z,n,assumptions] integrates a completed distribution against z^n, including both endpoints with unit delta mass.";
Begin["`Private`"];
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
UnitIntervalDistributionExpression[row_Association,z_Symbol]:=row["RegularCoefficient"]+
 Total[KeyValueMap[#2 FeynFacet`EndpointDeltaDerivative[If[#1===0,z,1-z],0,1]&,row["DeltaCoefficients"]]]+
 Total[KeyValueMap[Function[{point,terms},Total[KeyValueMap[
  #2 FeynFacet`EndpointPlusDistribution[If[point===0,z,1-z],-1,#1,1,1]&,terms]]],row["PlusCoefficients"]]];
UnitIntervalDistributionMoment[row_Association,z_Symbol,n_Integer?NonNegative,assumptions_:True]:=Module[{regular,delta,plus},
 regular=Integrate[z^n row["RegularCoefficient"],{z,0,1},Assumptions->assumptions,GenerateConditions->False];
 delta=Total[KeyValueMap[#2 If[n===0,1,#1^n]&,row["DeltaCoefficients"]]];
 plus=Total[KeyValueMap[Function[{point,terms},Total[KeyValueMap[
  #2 Integrate[Log[If[point===0,z,1-z]]^#1/If[point===0,z,1-z]*(z^n-If[n===0,1,point^n]),
   {z,0,1},GenerateConditions->False]&,terms]]],row["PlusCoefficients"]]];
 FullSimplify[regular+delta+plus,Assumptions->assumptions]
];
End[];EndPackage[];
