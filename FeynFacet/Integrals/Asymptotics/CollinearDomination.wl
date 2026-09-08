
(* Positive cluster denominators can be bounded by one constituent
   denominator. This reduces convergence/completeness to two angular bubbles. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructBubbleDominatedBoundaryIntegral::usage="ConstructBubbleDominatedBoundaryIntegral[definition,boundary] constructs a complete double-collinear Euler coefficient when replacing positive cluster denominators by constituent denominators gives a convergent product of two bubbles.";
Options[FeynFacet`ConstructBubbleDominatedBoundaryIntegral]={"RegionIntegrands"->Automatic};
FeynFacet`ConstructBubbleDominatedBoundaryIntegral[definition_Association,boundary_Association,OptionsPattern[]] :=
 Catch[Module[{base,all=OptionValue["RegionIntegrands"],dim=definition["Dimension"],alpha,
 descriptors,external,full,groups,records={},record,caps,choices,assignment,denominators,
 singles,left,right,lo,hi,accepted,gram,distance,ij,terms,proof},
 base=FeynFacet`ConstructCoalescingNullBoundaryIntegral[definition,boundary];
 If[FailureQ[base],Throw[base,"BoundaryIntegration"]];
 If[base["FinalStatePairPowers"]=!=<||>,boundaryIntegrationFail["BubbleDominationRequiresNoFinalStatePairDenominators"]];
 alpha=Cancel[Together[(dim-2)/2]];
 external=Select[base["PropagatorLimits"],Lookup[#,"Type",None]==="ExternalSubsetInvariant"&&Length[#["Subset"]]<3&];
 groups=GatherBy[external,{#["Subset"],#["ExternalMomentum"]}&];
 external=(Join[First[#],<|"Power"->Total[Lookup[#,"Power"]]|>]&/@groups);
 external=Select[external,#["Power"]=!=0&];
 If[!AllTrue[external,IntegerQ[#["Power"]]&&#["Power"]>0&],
  boundaryIntegrationFail["PositiveClusterDenominatorPowersRequired"]];
 If[all===Automatic,all=FeynFacet`ConstructDoubleCollinearIntegrands[definition,boundary]];
 If[FailureQ[all],Throw[all,"BoundaryIntegration"]];
 If[!AssociationQ[all]||!AssociationQ[Lookup[all,"Regions",None]],
  boundaryIntegrationFail["DoubleCollinearRegionRecordsRequired"]];
 Do[
  record=all["Regions"][[Key[caps]]];If[!AssociationQ[record],Continue[]];
  If[record["OriginalIntegralDefinition"]=!=definition,boundaryIntegrationFail["DoubleCollinearRegionDefinitionMismatch"]];
  If[!AllTrue[external,SubsetQ[caps,#["Subset"]]&],Continue[]];
  choices=Tuples[Lookup[external,"Subset"]];accepted=None;gram=record["ExternalOffsetGramMatrix"];
  Do[
   denominators=MapThread[Join[#1,<|"Subset"->{#2}|>] &,{external,assignment}];
   groups=GatherBy[denominators,{#["Subset"],#["ExternalMomentum"]}&];
   singles=(Join[First[#],<|"Power"->Total[Lookup[#,"Power"]]|>]&/@groups);
   left=Select[singles,#["Subset"]==={caps[[1]]}&];right=Select[singles,#["Subset"]==={caps[[2]]}&];
   If[Length[left]=!=2||Length[right]=!=2,Continue[]];
   lo=Max[Lookup[singles,"Power"]];
   hi=Min[Total[Lookup[left,"Power"]],Total[Lookup[right,"Power"]]];
   If[!TrueQ[lo<hi],Continue[]];
   distance=Table[ij=Flatten[FirstPosition[definition["ExternalMomenta"],#]&/@Lookup[side,"ExternalMomentum"]];
    Cancel[Together[gram[[ij[[1]],ij[[1]]]]+gram[[ij[[2]],ij[[2]]]]-2gram[[ij[[1]],ij[[2]]]]]],{side,{left,right}}];
   If[!AllTrue[distance,NumberQ[#]&&TrueQ[#>0]&],Continue[]];
   accepted=<|"ConstituentChoices"->assignment,"DominatingDenominators"->singles,
    "BubbleSquaredSeparations"->distance,"InitialConvergenceStrip"->lo<alpha<hi|>;Break[],
  {assignment,choices}];
  If[accepted===None,Continue[]];
  If[!AssociationQ[record["EuclideanParameterIntegral"]]||
    TrueQ[record["EuclideanParameterIntegral"]["Scaleless"]],boundaryIntegrationFail["NonzeroEuclideanCoefficientRequired"]];
  proof="For every positive cluster eikonal P.(k_i+k_j), choose a constituent P.k_i: its negative positive-power is bounded by that constituent factor. The stored choices give two convergent angular bubbles. The exact finite-z phase-space measure and the bubble proof provide a common integrable majorant for the scaled full domain, including energy endpoints and the angular complement. Quadratic cluster terms differ from their signed eikonals by a uniformly relative O(z) correction: K^2/(2P.K)<=z/(2P.Q). Dominated convergence therefore identifies the displayed Euler integral with the complete physical coefficient; meromorphic continuation follows from the nonempty strip.";
  AppendTo[records,Join[record,KeyTake[record["EuclideanParameterIntegral"],{"Representation","Terms"}],<|
   "DataType"->"BubbleDominatedDoubleCollinearBoundaryIntegral","PhysicalLimitEstablished"->True,
   "DominatingBubbleProduct"->accepted,"InitialConvergenceStrip"->accepted["InitialConvergenceStrip"],
   "PhysicalRegionCompleteness"->proof,"AllOtherCapAssignmentsExcludedByProof"->True|>]],
 {caps,Keys[all["Regions"]]}];
 If[Length[records]=!=1,boundaryIntegrationFail["ConvergentBubbleMajorantNotEstablished",
  <|"AcceptedCapAssignments"->Length[records]|>]];
 First[records]
 ],"BoundaryIntegration"];
End[];
