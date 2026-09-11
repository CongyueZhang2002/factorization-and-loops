(* Orders for a scalar coefficient row multiplying a normalized local DE.
   The input remains a finite epsilon record whenever its tail is unknown. *)
Begin["FeynFacet`Private`"];
FeynFacet`DetermineMasterCoefficientEndpointOrders::usage =
 "DetermineMasterCoefficientEndpointOrders[entries,endpoint,bounds,request] combines a coefficient row with the symbolic normal gauge, determines sufficient normal depth, and propagates epsilon demands for endpoint distributions. Entries are aligned with the endpoint's original master basis; unknown finite coefficient tails remain explicit.";
Clear[coefficientEndpointFail,coefficientEndpointValuation,
 coefficientEndpointNormalOrder,coefficientEndpointTermExpression,
 coefficientEndpointSumBound,coefficientEndpointCoalescingDivisors];
coefficientEndpointFail[tag_,data_:<||>]:=
 Throw[Failure[tag,data],"CoefficientEndpoint"];
(* All callers have already normalized their regulator symbols. *)
coefficientEndpointValuation[x_,e_]:=Module[{v,bound},
 (* Numerator sums need a sufficient lower bound, so do not expand all
    other kinematic variables merely to find their epsilon degree. Exact
    denominator valuations still use the common meromorphic routine. *)
 bound[a_]:=Which[a===0,Infinity,FreeQ[a,e],0,
   Head[a]===Times,Total[bound/@(List@@a)],
   Head[a]===Plus,Min[bound/@(List@@a)],
   Head[a]===Power&&IntegerQ[a[[2]]]&&a[[2]]>0,a[[2]] bound[a[[1]]],
   True,epsOrderMeromorphicBound[a,e]];
 v=Catch[If[!FreeQ[x,_Real|Indeterminate|_DirectedInfinity|_Missing|_Failure|$Failed],
    epsOrderFail["ExactMeromorphicExpressionRequired"]];bound[x],"EpsilonOrders"];
 If[!IntegerQ[v]&&v=!=Infinity,
  coefficientEndpointFail["CoefficientEndpointLaurentValuationRequired",<|"Cause"->v|>]];
 v];
coefficientEndpointNormalOrder[x_,z_]:=Module[{lower,leading,germ,data},
 If[x===0,Return[Infinity]];
 (* Form the leading coefficient structurally. A generic SeriesCoefficient
    on a million-term rational expression needlessly expands the whole
    coefficient field even when only its first normal coefficient is used. *)
 germ[a_]:=Which[
  a===0,{Infinity,0},FreeQ[a,z],{0,a},
  Head[a]===Times,With[{parts=germ/@(List@@a)},{Total[First/@parts],Times@@(Last/@parts)}],
  Head[a]===Plus,Module[{parts=germ/@(List@@a),order},
    order=Min[First/@parts];{order,Total[Last/@Select[parts,First[#]===order&]]}],
  Head[a]===Power&&IntegerQ[a[[2]]]&&a[[2]]>0,
    With[{part=germ[a[[1]]]},{a[[2]] First[part],Last[part]^a[[2]]}],
  Head[a]===Power&&IntegerQ[a[[2]]]&&a[[2]]<0&&PolynomialQ[a[[1]],z],
    With[{order=Exponent[a[[1]],z,Min]},
      {a[[2]] order,Coefficient[a[[1]],z,order]^a[[2]]}],
  True,Module[{order=coefficientEndpointValuation[a,z]},
    {order,If[order===Infinity,0,SeriesCoefficient[a,{z,0,order}]]}]];
 data=germ[x];lower=First[data];
 If[!IntegerQ[lower]&&lower=!=Infinity,
  coefficientEndpointFail["MeromorphicCoefficientNormalDependenceRequired",<|"Cause"->lower|>]];
 If[lower===Infinity,Return[Infinity]];
 leading=TimeConstrained[Cancel[Together[Last[data]]],5,$Aborted];
 If[leading===$Aborted||!TrueQ[leading===0],Return[lower]];
 Do[
  lower++;
  leading=TimeConstrained[Cancel[Together[SeriesCoefficient[x,{z,0,lower}]]],5,$Aborted];
  If[leading===$Aborted||!TrueQ[leading===0],Return[lower]],
 {7}];
 lower+1];
coefficientEndpointCoalescingDivisors[x_,z_,e_]:=Module[{bases,divisors,inspect},
 bases=DeleteDuplicates@Cases[x,Power[b_,n_Integer?Negative]/;!FreeQ[b,z]:>b,{0,Infinity}];
 inspect[b_]:=Module[{small=b,restore={},a,c,leading,factors,atOrigin},
  (* Analytic normalization factors such as s^epsilon are units, but their
     actual endpoint values must be restored when testing a joint unit.
     Treating them as unrelated constants would miss s^epsilon-1+z. *)
  If[!PolynomialQ[b,{z,e}]&&Length[DownValues[coefficientRationalFieldReduce]]>0,
   {small,restore}=coefficientRationalFieldReduce[b]];
  If[PolynomialQ[small,{z,e}],
   {a,c}={Exponent[small,e,Min],Exponent[small,z,Min]};
   If[IntegerQ[a]&&IntegerQ[c],
    leading=TimeConstrained[Cancel[Together[
      (Coefficient[Coefficient[small,e,a],z,c]/.restore)/.{z->0,e->0}]],5,$Aborted];
    If[leading=!=$Aborted&&FreeQ[leading,Indeterminate|_DirectedInfinity]&&leading=!=0,Return[{}]]];
   factors=(First/@Rest[FactorList[small]])/.restore,
   factors={b}];
  Select[factors,Function[f,
    atOrigin=Quiet[f/.{z->0,e->0}];
    !FreeQ[f,z]&&!FreeQ[f,e]&&
     (TrueQ[atOrigin===0]||!FreeQ[atOrigin,Indeterminate|_DirectedInfinity])]]
 ];
 DeleteDuplicates[Flatten[inspect/@bases,1]]
];
coefficientEndpointTermExpression[t_,upper_:Infinity]:=t["PreFactor"] If[t["Representation"]==="Exact",
 t["Coefficient"],Total[KeyValueMap[#2 t["Coefficient"]["SeriesVariable"]^#1&,
 KeySelect[t["Coefficient"]["Orders"],#<=upper&]]]];
coefficientEndpointSumBound[terms_,e_]:=If[terms==={},Infinity,
 Min[coefficientEndpointValuation[#,e]&/@terms]];

FeynFacet`DetermineMasterCoefficientEndpointOrders[entries_List,
 endpoint_Association,bounds_Association,request_Association]:=Catch[Module[
 {e,z,n,target,rules,pref,uniform,sectors,sectorBounds,sectorLogs,allLow,
  normalizedEntries,expressions,termRecords={},coefficientBounds,missing={},
  i,j,t,pv,cv,known,need,tailLow,validPrefix,terms,entry,
  row,gaugeRow,gaugeOrders,depth,endpointUpper,rawOrders,termBound,
  densityLow,normalDepthSufficient,active,checks,coalescing,remainderClass,
  unresolvedRemainders={},remainderClasses={},termIndex,candidateRows,simplifiedRow,rationalRows},
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem"||
  Lookup[bounds,"DataType",None]=!="TangentialEndpointLaurentBounds",
  coefficientEndpointFail["TangentialEndpointAndLaurentBoundsRequired"]];
 {e,z,n}=Lookup[endpoint,{"DimensionalRegulator","NormalVariable","Dimension"}];
 target=Lookup[request,"ThroughOrder",None];rules=Lookup[request,"KinematicRules",{}];
 pref=coefficientRegulatorNormalize[Lookup[request,"GlobalPrefactor",1]/.rules,e];
 If[!IntegerQ[target]||Length[entries]=!=n||!AllTrue[entries,AssociationQ]||
   !ListQ[rules],
  coefficientEndpointFail["AlignedCoefficientEntriesAndTargetOrderRequired"]];
 sectors=endpoint["PrimarySectors"];
 uniform=Lookup[bounds,"UniformPrimarySectorOriginalCoefficientLaurentLowerBounds",None];
 If[AssociationQ[uniform],uniform=Lookup[uniform,Lookup[sectors,"Exponent"]]];
 If[!ListQ[uniform]||Length[uniform]=!=Length[sectors]||
   !AllTrue[uniform,VectorQ[#,IntegerQ[#]||#===Infinity&]&&Length[#]===n&],
  coefficientEndpointFail["UniformPrimarySectorLaurentBoundsRequired",
   <|"Reason"->"Bounds on the full epsilon-expanded master alone do not bound separate regulated powers, whose poles can cancel."|>]];
 sectorLogs=Lookup[sectors,"NilpotencyIndex"]-1;
 allLow=Table[Min[Table[If[uniform[[j,i]]===Infinity,Infinity,
     uniform[[j,i]]-sectorLogs[[j]]-1],{j,Length[sectors]}]],{i,n}];
 normalizedEntries=coefficientRegulatorNormalize[entries/.rules,e];
 expressions=ConstantArray[0,n];coefficientBounds=ConstantArray[Infinity,n];
 Do[
  If[TrueQ[Lookup[request,"Verbose",False]],Print["Coefficient endpoint orders: raw row ",i,"/",n]];
  entry=normalizedEntries[[i]];terms=Lookup[entry,"Terms",None];
  If[!ListQ[terms],coefficientEndpointFail["CanonicalCoefficientTermsRequired",<|"Row"->i|>]];
  validPrefix={};termIndex=0;
  Do[
   termIndex++;
   t=coefficientTermRead[term,e];pv=coefficientEndpointValuation[pref t["PreFactor"],e];
   If[pv===Infinity,Continue[]];
   need=If[allLow[[i]]===Infinity,-Infinity,target-pv-allLow[[i]]];
   If[t["Representation"]==="LaurentSeries",
    known=t["Coefficient"]["SeriesTruncation"];
    tailLow=known+1+pv;
    remainderClass=Lookup[t,"LaurentRemainderClass",<||>];
    If[!AssociationQ[remainderClass]||
      Lookup[remainderClass,"Status",None]=!="EstablishedForSourceCoefficient"||
      !TrueQ[Expand[Lookup[remainderClass,"NormalDivisor",0]-z]===0]||
      Lookup[remainderClass,"EpsilonOrderLowerBound",None]=!=known+1||
      !IntegerQ[Lookup[remainderClass,"NormalPoleOrderUpperBound",None]]||
      !TrueQ[Lookup[remainderClass,"NormalPoleOrderUpperBound",-1]>=0]||
      !TrueQ[Lookup[remainderClass,"UniformOnTangentialCompactSets",False]]||
      !AssociationQ[Lookup[remainderClass,"Justification",None]],
     AppendTo[unresolvedRemainders,<|"Row"->i,"TermIndex"->termIndex,
       "Master"->Lookup[entry,"Master",i],"KnownCoefficientUpperOrder"->known,
       "Required"->"A fixed finite normal-pole bound for the full epsilon remainder, uniform on tangential compact sets, with source justification."|>],
     AppendTo[remainderClasses,<|"Row"->i,"TermIndex"->termIndex,"Class"->remainderClass|>]];
    If[need>known,AppendTo[missing,<|"Row"->i,
      "Master"->Lookup[entry,"Master",i],"KnownCoefficientUpperOrder"->known,
      "RequiredCoefficientUpperOrder"->need,
      "PrefactorLaurentLowerBound"->pv,
      "EndpointDistributionLaurentLowerBound"->allLow[[i]]|>]];
    cv=Min[Select[Keys[t["Coefficient"]["Orders"]],
       !TrueQ[t["Coefficient"]["Orders"][#]===0]&]/.{}->{known+1}];
    termBound=pv+cv;
    AppendTo[termRecords,<|"Row"->i,"Representation"->"LaurentSeries",
      "CoefficientLaurentLowerBound"->cv,"PrefactorLaurentLowerBound"->pv,
      "KnownCoefficientUpperOrder"->known,"RequiredCoefficientUpperOrder"->need,
      "UnknownTailLowerBound"->tailLow,"Sufficient"->TrueQ[need<=known]|>],
    cv=coefficientEndpointValuation[t["Coefficient"],e];termBound=pv+cv;
    AppendTo[termRecords,<|"Row"->i,"Representation"->"Exact",
      "CoefficientLaurentLowerBound"->cv,"PrefactorLaurentLowerBound"->pv,
      "RequiredCoefficientUpperOrder"->need,"Sufficient"->True|>]];
   coefficientBounds[[i]]=Min[coefficientBounds[[i]],termBound];
   AppendTo[validPrefix,pref coefficientEndpointTermExpression[t,need]],
  {term,terms}];
  expressions[[i]]=Total[validPrefix],
 {i,n}];
 (* Cancellations between masters are performed before the normal valuation.
    Epsilon bounds remain conservative when distinct analytic prefactors occur. *)
 gaugeRow=expressions.endpoint["NormalGaugeMatrix"];
 If[TrueQ[Lookup[request,"CancelNormalizedCoefficientRow",False]],
  rationalRows=FeynFacet`SimplifyMasterCoefficientEntries[
    (<|"Terms"->{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->#|>}|>&/@gaugeRow),
    "Verbose"->TrueQ[Lookup[request,"Verbose",False]]];
  If[FailureQ[rationalRows],coefficientEndpointFail["NormalizedCoefficientCancellationFailed",<|"Cause"->rationalRows|>]];
  gaugeRow=#["Terms"][[1,"Coefficient"]]&/@rationalRows["CoefficientEntries"]];
 If[TrueQ[Lookup[request,"Verbose",False]],Print["Coefficient endpoint orders: checking normalized row divisors."]];
 (* Exact coefficient poles may be removed by the accepted gauge. Only
    the complete normalized row must have fixed normal divisors. Unknown
    finite tails still need their separate source remainder certificate. *)
 candidateRows=Select[Range[n],coefficientEndpointCoalescingDivisors[{gaugeRow[[#]]},z,e]=!={}&];
 Do[
  simplifiedRow=TimeConstrained[Cancel[Together[gaugeRow[[i]]]],10,gaugeRow[[i]]];
  gaugeRow[[i]]=simplifiedRow,
 {i,candidateRows}];
 coalescing=coefficientEndpointCoalescingDivisors[gaugeRow,z,e];
 If[coalescing=!={},coefficientEndpointFail["CoalescingCoefficientEndpointDivisor",
   <|"Divisors"->coalescing,
    "Reason"->"A divisor approaching the endpoint invalidates the joint normal/epsilon order argument."|>]];
 If[TrueQ[Lookup[request,"Verbose",False]],Print["Coefficient endpoint orders: normal orders."]];
 gaugeOrders=coefficientEndpointNormalOrder[#,z]&/@gaugeRow;
 depth=If[AllTrue[gaugeOrders,#===Infinity&],0,Max[0,-1-Min[gaugeOrders]]];
 rawOrders=coefficientEndpointNormalOrder[#,z]&/@expressions;
 endpointUpper=Association@Table[i->If[coefficientBounds[[i]]===Infinity,-Infinity,
    target-coefficientBounds[[i]]+Max[sectorLogs]+1],{i,n}];
 densityLow=Min[Table[If[coefficientBounds[[i]]===Infinity||allLow[[i]]===Infinity,
     Infinity,coefficientBounds[[i]]+allLow[[i]]],{i,n}]];
 normalDepthSufficient=missing==={}&&unresolvedRemainders==={};
 <|"DataType"->"MasterCoefficientEndpointOrders","SchemaVersion"->1,
  "Status"->Which[normalDepthSufficient,"SufficientOrdersDetermined",
    unresolvedRemainders=!={},"CoefficientRemainderClassUnresolved",True,"CoefficientOrdersMissing"],
  "ThroughOrder"->target,"DimensionalRegulator"->e,"NormalVariable"->z,
  "OriginalMasterIntegralBasis"->Lookup[endpoint,"OriginalMasterIntegralBasis",Range[n]],
  "ProjectedMasterIdentities"->If[AllTrue[normalizedEntries,KeyExistsQ[#,"Master"]&],
    coefficientMasterID[#["Master"]]&/@
     Select[normalizedEntries,Lookup[#,"PartialCoefficientContributions",{}]==={}&&(AnyTrue[#["Terms"],!coefficientExactZeroTermQ[#]&]||Lookup[#,"SeparatedCoefficientPoles",{}]=!={})&],{}],
  "SeparatedCoefficientPoles"->Flatten[Lookup[normalizedEntries,"SeparatedCoefficientPoles",{}],1],
  "PartialCoefficientContributions"->Flatten[Lookup[normalizedEntries,"PartialCoefficientContributions",{}],1],
  "GlobalPrefactorIncluded"->True,"GlobalPrefactor"->pref,
  "SourceCoefficientFile"->Lookup[request,"SourceCoefficientFile",None],
  "CoefficientExpressions"->expressions,"CoefficientLaurentLowerBounds"->coefficientBounds,
  "NormalGaugeMatrix"->endpoint["NormalGaugeMatrix"],
  "CoefficientNormalLowerBounds"->rawOrders,"DensityNormalGaugeRow"->gaugeRow,
  "DensityNormalGaugeEntryLowerBounds"->gaugeOrders,
  "MaximumNormalOrder"->depth,"NormalDepthSufficientForTargetOrder"->normalDepthSufficient,
  "RequiredEndpointMasterUpperOrders"->endpointUpper,
  "EndpointMasterLaurentLowerBounds"->(Min/@Transpose[uniform]),
  "DistributionLaurentLowerBound"->densityLow,
  "CoefficientTermRequirements"->termRecords,"MissingCoefficientOrders"->missing,
  "UnresolvedCoefficientRemainderClasses"->unresolvedRemainders,
  "CoefficientRemainderClasses"->remainderClasses,
  "CoefficientRemainderDomainConditions"->DeleteDuplicates[
    Lookup[Lookup[#["Class"],"Justification",<||>],"TangentialAssumptions",True]&/@remainderClasses],
  "LaurentBoundMethod"->"Structural meromorphic lower bounds; bounded exact normal-leading-coefficient cancellation checks. Unproved cancellations are not assumed.",
  "PrimarySectorMaximumLogarithmPowers"->sectorLogs,
  "Convention"->"The requested normal depth is for H in I=T H z^R c. It is computed after combining the complete known scalar coefficient row with T. A finite coefficient tail is discarded only above a proved distribution epsilon bound.",
  "Scope"->"Sufficient orders for one smooth endpoint divisor. This does not establish uniformity at its intersections with other divisors."|>
],"CoefficientEndpoint"];
FeynFacet`DetermineMasterCoefficientEndpointOrders[___]:=
 Failure["CoefficientEntriesEndpointBoundsAndRequestRequired",<||>];
End[];
