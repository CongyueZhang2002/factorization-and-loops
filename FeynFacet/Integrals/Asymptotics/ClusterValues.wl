
(* Unit-power cluster coefficients. Their physical completeness is supplied
   by a convergent bubble majorant, separately from these analytic kernels. *)
Begin["FeynFacet`Private`"];
FeynFacet`EvaluateClusterBoundaryIntegral::usage="EvaluateClusterBoundaryIntegral[physicalDefinition,{low,high}] materializes unit-power external-only double-collinear coefficients using Gamma, digamma and classical polylogarithms. The result contains explicit Laurent coefficients.";
clusterSharingWeight[ratio_,regulator_Symbol,order_Integer] := Module[{q,weight,jm},
 If[ratio===1,Return[1/2]];
 If[TrueQ[ratio<1],Return[1-clusterSharingWeight[1/ratio,regulator,order]]];
 q=1/ratio;
 jm[m_]:=Sum[(-1)^j Factorial[m]/Factorial[m-j]Log[q]^(m-j)PolyLog[j+1,q],{j,0,m}];
 weight=Tan[Pi regulator]/(2Pi)(q^regulator/regulator+
   2Sum[regulator^m/Factorial[m]jm[m],{m,1,Max[1,order],2}]);
 Normal[Series[weight,{regulator,0,order}]]
];
FeynFacet`EvaluateClusterBoundaryIntegral[physical_Association,range:{_Integer,_Integer}] :=
 Catch[Module[{definition=physical["OriginalIntegralDefinition"],eps=physical["DimensionalRegulator"],
 dim,alpha,delta,formal=Unique["dimensionShift"],base,external,singles,clusters,caps,
 common,one,two,center,firstDirection,secondDirection,gram,distance,ij,ratio,
 pref,weight,series,lo,needed,kind,value,started=AbsoluteTime[]},
 If[!TrueQ[Lookup[physical,"PhysicalLimitEstablished",False]]||
   !KeyExistsQ[physical,"DominatingBubbleProduct"],boundaryIntegrationFail["CompleteBubbleDominationRequired"]];
 dim=definition["Dimension"];alpha=Cancel[Together[(dim-2)/2]];delta=Cancel[Together[alpha-1]];
 If[!PolynomialQ[delta,eps]||Exponent[delta,eps]=!=1||!TrueQ[(delta/.eps->0)===0],
  boundaryIntegrationFail["ExpansionAboutFourDimensionsRequired"]];
 base=FeynFacet`ConstructCoalescingNullBoundaryIntegral[definition,<|"NormalVariable"->physical["NormalVariable"],
   "BoundaryKinematicRules"->(definition["KinematicRules"]/.physical["NormalVariable"]->0)|>];
 If[FailureQ[base],Throw[base,"BoundaryIntegration"]];
 external=Select[base["PropagatorLimits"],Lookup[#,"Type",None]==="ExternalSubsetInvariant"&&Length[#["Subset"]]<3&];
 If[Length[external]=!=4||!AllTrue[external,#["Power"]===1&],boundaryIntegrationFail["FourUnitPowerExternalDenominatorsRequired"]];
 singles=Select[external,Length[#["Subset"]]===1&];clusters=Select[external,Length[#["Subset"]]===2&];
 caps=physical["CollinearParticleIndices"];gram=physical["ExternalOffsetGramMatrix"];
 distance[p_,q_]:=Module[{ids=Flatten[FirstPosition[definition["ExternalMomenta"],#]&/@{p,q}]},
  Cancel[Together[gram[[ids[[1]],ids[[1]]]]+gram[[ids[[2]],ids[[2]]]]-2gram[[ids[[1]],ids[[2]]]]]]];
 Which[
  Length[clusters]===1&&Length[singles]===3,
   center=clusters[[1,"ExternalMomentum"]];
   common=SelectFirst[caps,Count[Lookup[singles,"Subset"],{#}]===2&,None];
   one=Select[singles,#["Subset"]==={common}&];two=Select[singles,#["Subset"]=!={common}&];
   If[common===None||!MemberQ[Lookup[one,"ExternalMomentum"],center],boundaryIntegrationFail["ClusterAndRepeatedConstituentDirectionRequired"]];
   firstDirection=First[DeleteCases[Lookup[one,"ExternalMomentum"],center]];secondDirection=two[[1,"ExternalMomentum"]];
   ratio=distance[center,firstDirection]/distance[center,secondDirection];
   ij={distance[center,firstDirection],distance[center,secondDirection]};kind="OneCluster",
  Length[clusters]===2&&Length[singles]===2&&
    Sort[Lookup[clusters,"ExternalMomentum"]]===Sort[Lookup[singles,"ExternalMomentum"]],
   ij=ConstantArray[distance[Sequence@@Lookup[clusters,"ExternalMomentum"]],2];
   kind=If[singles[[1,"Subset"]]===singles[[2,"Subset"]],"SameConstituent","OppositeConstituents"],
  True,boundaryIntegrationFail["SupportedClusterProfileRequired"]
 ];
 If[!AllTrue[ij,NumberQ[#]&&TrueQ[#>0]&],boundaryIntegrationFail["DistinctPositiveNullDirectionSeparationRequired"]];
 pref=physical["EuclideanIntegralInput"]["Prefactor"] Pi^(2alpha)(Times@@ij)^(alpha-2)*
   Gamma[2-alpha]^2 Gamma[alpha-1]^4/Gamma[4alpha-4];
 lo=FeynFacet`DetermineLaurentValuation[pref,eps];
 If[!IntegerQ[lo],boundaryIntegrationFail["ClusterPrefactorOrderUnresolved"]];
 needed=Max[0,Last[range]-lo];
 weight=If[kind==="OneCluster",clusterSharingWeight[ratio,formal,needed],
   Normal[Series[Tan[Pi formal]/(2Pi)(PolyGamma[0,1]-PolyGamma[0,2formal]),{formal,0,needed}]]];
 If[kind==="SameConstituent",weight=1/2-weight];
 value=pref(weight/.formal->delta);
 series=Series[value,{eps,0,Last[range]}];
 If[!FreeQ[series,_Series|Indeterminate|_DirectedInfinity],boundaryIntegrationFail["ClusterLaurentExpansionFailed"]];
 <|"DataType"->"EvaluatedBoundaryIntegral","Status"->"AnalyticallyEvaluated",
  "IntegralDefinition"->physical,"DimensionalRegulator"->eps,"EpsilonOrderRange"->range,
  "LaurentCoefficients"->Association@Table[k->SeriesCoefficient[series,{eps,0,k}],{k,First[range],Last[range]}],
  "AnalyticExpression"->Missing["LaurentSeriesOnly"],"IntegrationMethods"->{"GammaClassicalPolylogarithms"},
  "ClusterIntegralClass"->kind,"SharingWeightExpansionOrder"->needed,
  "ElapsedSeconds"->AbsoluteTime[]-started,"PhysicalCoefficientIdentificationEstablished"->True,
  "NormalizationChanged"->False|>
 ],"BoundaryIntegration"];
End[];
