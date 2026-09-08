
(* Unit pair-plus-cross-pair coefficient. A fractional-power positive
   comparator establishes the full physical limit for 5/4<alpha<3/2. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructPairClusterBoundaryIntegral::usage="ConstructPairClusterBoundaryIntegral[definition,boundary] constructs a complete two-dimensional Euler coefficient for one external constituent, one external cluster, its pair invariant and the opposite cross-pair invariant, all with unit powers.";
Options[FeynFacet`ConstructPairClusterBoundaryIntegral]={"RegionIntegrands"->Automatic};
FeynFacet`ConstructPairClusterBoundaryIntegral[definition_Association,boundary_Association,OptionsPattern[]] :=
 Catch[Module[{base,all=OptionValue["RegionIntegrands"],alpha,delta,eps=definition["DimensionalRegulator"],
 external,singles,clusters,caps,particle,opposite,spectator,pairs,record,dirs,ids,gram,L,pref,
 u=Unique["pairEuler"],t=Unique["pairEuler"],proof,hyper},
 base=FeynFacet`ConstructCoalescingNullBoundaryIntegral[definition,boundary];
 If[FailureQ[base],Throw[base,"BoundaryIntegration"]];
 external=Select[base["PropagatorLimits"],Lookup[#,"Type",None]==="ExternalSubsetInvariant"&&Length[#["Subset"]]<3&];
 singles=Select[external,Length[#["Subset"]]===1&];clusters=Select[external,Length[#["Subset"]]===2&];
 pairs=base["FinalStatePairPowers"];
 If[Length[singles]=!=1||Length[clusters]=!=1||Length[pairs]=!=2||
  !AllTrue[Join[Lookup[external,"Power"],Values[pairs]],#===1&],
  boundaryIntegrationFail["UnitPairClusterProfileRequired"]];
 caps=clusters[[1,"Subset"]];particle=singles[[1,"Subset",1]];
 If[!MemberQ[caps,particle],boundaryIntegrationFail["ExternalConstituentMustBelongToCluster"]];
 opposite=First[DeleteCases[caps,particle]];spectator=First[Complement[Range[3],caps]];
 If[Sort[Keys[pairs]]=!=Sort[{caps,Sort[{opposite,spectator}]}],
  boundaryIntegrationFail["ClusterPairAndOppositeCrossPairRequired"]];
 If[all===Automatic,all=FeynFacet`ConstructDoubleCollinearIntegrands[definition,boundary]];
 If[FailureQ[all],Throw[all,"BoundaryIntegration"]];
 record=all["Regions"][[Key[caps]]];
 If[!AssociationQ[record]||record["OriginalIntegralDefinition"]=!=definition,boundaryIntegrationFail["MatchingPairClusterRegionRequired"]];
 dirs={singles[[1,"ExternalMomentum"]],clusters[[1,"ExternalMomentum"]]};
 ids=Flatten[FirstPosition[definition["ExternalMomenta"],#]&/@dirs];gram=record["ExternalOffsetGramMatrix"];
 L=Cancel[Together[gram[[ids[[1]],ids[[1]]]]+gram[[ids[[2]],ids[[2]]]]-2gram[[ids[[1]],ids[[2]]]]]];
 If[!NumberQ[L]||!TrueQ[L>0],boundaryIntegrationFail["DistinctPositiveNullDirectionSeparationRequired"]];
 alpha=Cancel[Together[(definition["Dimension"]-2)/2]];delta=alpha-1;
 pref=record["EuclideanIntegralInput"]["Prefactor"] Pi^(2alpha)L^(2alpha-3)*
  Gamma[1-2delta]Gamma[2delta]Gamma[delta]/Gamma[3delta];
 hyper=Pi^(2alpha)L^(2alpha-3)Gamma[1-2delta]Gamma[2delta]^2 Gamma[delta]^2/
  (delta Gamma[3delta]^2)*HypergeometricPFQ[{1-delta,delta,delta},{1+delta,3delta},1];
 proof="After extracting signs and uniformly linearizing the quadratic cluster, 1/(r1+r2)<=1/(2 sqrt(r1 r2)). The comparator 1/(2 p1 sqrt(r1 r2) s12 s23) has an exact energy integral K_a(lambda), a=2alpha-5/2, bounded by C_a/(1-lambda). Its double-cap angular kernel is integrable at finite centers for alpha>1 and at infinity for alpha<3/2. Energy convergence requires alpha>5/4. The antipodal endpoint remains integrable. The cap complement, relative to z^(4alpha-6), is suppressed by z^(3-2alpha) and z^(3/2-alpha). Thus the comparator measure concentrates fully in the cap for 5/4<alpha<3/2. The target/comparator ratio is 2 sqrt(r1 r2)/(r1+r2) in [0,1]; bounded-weight transfer and the uniform O(z) quadratic correction prove the complete coefficient before meromorphic continuation.";
 Join[record,<|"DataType"->"PairClusterBoundaryIntegral","Representation"->"UnitCube",
 "Terms"->{<|"IntegrationVariables"->{u,t},"EndpointPowers"->{delta-1,delta-1},
 "UpperEndpointPowers"->{2delta-1,0},"Prefactor"->pref,
 "PolynomialFactors"->{<|"Polynomial"->1-u t,"Exponent"->delta-1|>}|>},
 "PhysicalLimitEstablished"->True,"InitialConvergenceStrip"->5/4<alpha<3/2,
 "PhysicalRegionCompleteness"->proof,"AllOtherCapAssignmentsExcludedByProof"->True,
 "SquaredExternalSeparation"->L,"IntegralEquivalenceKey"->{"PairClusterEulerIntegral",definition["Dimension"]},
 "IntegralScaleFactor"->pref,"EquivalentHypergeometricExpression"->record["EuclideanIntegralInput"]["Prefactor"]hyper|>]
 ],"BoundaryIntegration"];
End[];
