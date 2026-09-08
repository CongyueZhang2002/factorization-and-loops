
(* Complete coefficients for integrable double-collinear profiles.
   Bubble/sunset integration and exact conditional two-body moments. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructDoubleCollinearBoundaryIntegral::usage="ConstructDoubleCollinearBoundaryIntegral[definition,boundary] evaluates complete double-collinear coefficients for a two-loop sunset, a product of bubbles, two cluster denominators, or a cluster denominator and one constituent denominator. Other profiles remain unresolved.";
Options[FeynFacet`ConstructDoubleCollinearBoundaryIntegral]={"RegionIntegrands"->Automatic};
euclideanBubbleValue[alpha_,a_,b_,separation_]:=
 Pi^alpha separation^(alpha-a-b) Gamma[a+b-alpha]Gamma[alpha-a]Gamma[alpha-b]/
 (Gamma[a]Gamma[b]Gamma[2alpha-a-b]);
FeynFacet`ConstructDoubleCollinearBoundaryIntegral[definition_Association,boundary_Association,OptionsPattern[]] :=
 Catch[Module[{base,all=OptionValue["RegionIntegrands"],eps=definition["DimensionalRegulator"],
 alpha=Cancel[(definition["Dimension"]-2)/2],descriptors,external,pairs,groups,
 candidates={},record,caps,singles,clusters,left,right,profile=None,powers,value,
 a,b,c,s,lo,hi,separation,dirs,indices,gram,angular,energyMoment,proof,conditional=1},
 base=FeynFacet`ConstructCoalescingNullBoundaryIntegral[definition,boundary];
 If[FailureQ[base],Throw[base,"BoundaryIntegration"]];
 descriptors=base["PropagatorLimits"];
 external=Select[descriptors,Lookup[#,"Type",None]==="ExternalSubsetInvariant"&&Length[#["Subset"]]<3&];
 groups=GatherBy[external,{#["Subset"],#["ExternalMomentum"]}&];
 external=(Join[First[#],<|"Power"->Total[Lookup[#,"Power"]]|>]&/@groups);
 external=Select[external,#["Power"]=!=0&];
 pairs=base["FinalStatePairPowers"];
 If[!AllTrue[external,IntegerQ[#["Power"]]&&#["Power"]>0&]||
    !AllTrue[Values[pairs],IntegerQ[#]&&#>0&],
   boundaryIntegrationFail["PositiveDoubleCollinearPowersRequired"]];
 If[all===Automatic,all=FeynFacet`ConstructDoubleCollinearIntegrands[definition,boundary]];
 If[FailureQ[all],Throw[all,"BoundaryIntegration"]];
 If[!AssociationQ[all]||!AssociationQ[Lookup[all,"Regions",None]],
  boundaryIntegrationFail["DoubleCollinearRegionRecordsRequired"]];
 Do[
  profile=None;record=all["Regions"][[Key[caps]]];
  If[!AssociationQ[record],Continue[]];
  If[record["OriginalIntegralDefinition"]=!=definition,
   boundaryIntegrationFail["DoubleCollinearRegionDefinitionMismatch"]];
  If[!AllTrue[external,SubsetQ[caps,#["Subset"]]&]||
    !AllTrue[Keys[pairs],#===caps&],Continue[]];
  singles=Select[external,Length[#["Subset"]]===1&];
  clusters=Select[external,Length[#["Subset"]]===2&];
  left=Select[singles,#["Subset"]==={caps[[1]]}&];
  right=Select[singles,#["Subset"]==={caps[[2]]}&];
  gram=record["ExternalOffsetGramMatrix"];
  separation[one_,two_]:=Module[{ij=Flatten[FirstPosition[definition["ExternalMomenta"],#]&/@{one,two}]},
    With[{distance=Cancel[Together[gram[[ij[[1]],ij[[1]]]]+gram[[ij[[2]],ij[[2]]]]-2gram[[ij[[1]],ij[[2]]]]]]},
     If[!NumberQ[distance]||!TrueQ[distance>0],boundaryIntegrationFail["DistinctPositiveNullDirectionSeparationRequired"]];distance]];
  Which[
   Length[pairs]===1&&clusters==={}&&Length[left]===1&&Length[right]===1&&
     left[[1,"ExternalMomentum"]]=!=right[[1,"ExternalMomentum"]],
    profile="EuclideanSunset";
    {a,b,c}={left[[1,"Power"]],right[[1,"Power"]],First[Values[pairs]]};s=a+b+c;
    lo=Max[a,b,c];hi=s/2;
    angular=Pi^(2alpha)separation[left[[1,"ExternalMomentum"]],right[[1,"ExternalMomentum"]]]^(2alpha-s)*
      Gamma[s-2alpha]Gamma[alpha-a]Gamma[alpha-b]Gamma[alpha-c]/
      (Gamma[a]Gamma[b]Gamma[c]Gamma[3alpha-s]);
    energyMoment=Beta[2alpha-a-c,2alpha-b-c];
    proof="Exact finite-z energy-angle phase space; two-particle cap localization. Sunset ultraviolet and pair/center infrared bounds and the energy Beta integral give dominated convergence in the stated strip.",
   pairs===<||>&&clusters==={}&&Length[left]===2&&Length[right]===2,
    profile="ProductOfEuclideanBubbles";
    powers=Lookup[Join[left,right],"Power"];{a,b}={Total[Lookup[left,"Power"]],Total[Lookup[right,"Power"]]};
    lo=Max[powers];hi=Min[a,b];
    angular=Times@@Table[euclideanBubbleValue[alpha,side[[1,"Power"]],side[[2,"Power"]],
      separation[side[[1,"ExternalMomentum"]],side[[2,"ExternalMomentum"]]]],{side,{left,right}}];
    energyMoment=Beta[2alpha-a,2alpha-b];
    proof="Exact finite-z energy-angle phase space and product angular-cap localization. Each rescaled bubble converges in the stated strip; the energy kernel is uniformly integrable and the one-cap complement is suppressed.",
   pairs===<||>&&singles==={}&&Length[clusters]===2,
    profile="TwoClusterDenominators";{a,b}=Lookup[clusters,"Power"];
    lo=Max[a,b]/2;hi=(a+b)/2;
    angular=euclideanBubbleValue[2alpha,a,b,separation[clusters[[1,"ExternalMomentum"]],clusters[[2,"ExternalMomentum"]]]];
    energyMoment=Beta[alpha,alpha];
    proof="Exact massive-cluster factorization followed by global mass and stereographic rescaling. The resulting bubble in 2(D-2) dimensions converges in the stated strip, including the cluster-mass and recoil complements.",
   pairs===<||>&&Length[singles]===1&&Length[clusters]===1&&
     singles[[1,"ExternalMomentum"]]=!=clusters[[1,"ExternalMomentum"]],
    profile="ClusterAndConstituentDenominators";
    {a,b}={clusters[[1,"Power"]],singles[[1,"Power"]]};
    lo=Max[a,b]/2;hi=(a+b)/2;
    conditional=Gamma[alpha-b]Gamma[2alpha]/(Gamma[alpha]Gamma[2alpha-b]);
    angular=conditional euclideanBubbleValue[2alpha,a,b,
      separation[clusters[[1,"ExternalMomentum"]],singles[[1,"ExternalMomentum"]]]];
    energyMoment=Beta[alpha,alpha];
    proof="First perform the exact two-body conditional integral at fixed cluster momentum: (R.k)/(R.K) has Beta(alpha,alpha) distribution. Meromorphic continuation of this finite-z identity reduces to two cluster denominators; their complete coefficient is established in the displayed strip. That strip applies to the reduced integral, not the unreduced conditional moment."
  ];
  If[profile===None,Continue[]];
  If[!TrueQ[lo<hi],Continue[]];
  value=record["EuclideanIntegralInput"]["Prefactor"] energyMoment angular;
  value=value/.Beta[x_,y_]:>Gamma[Expand[x]]Gamma[Expand[y]]/Gamma[Expand[x+y]];
  AppendTo[candidates,Join[record,<|"DataType"->"DoubleCollinearBoundaryIntegral","Representation"->"UnitCube",
    "Terms"->{<|"IntegrationVariables"->{},"Prefactor"->value|>},"AnalyticExpression"->value,
    "DoubleCollinearIntegralClass"->profile,"InitialConvergenceStrip"->lo<alpha<hi,
    "EnergyIntegral"->energyMoment,"TransverseIntegral"->angular,
    "ConditionalTwoBodyMoment"->conditional,"PhysicalLimitEstablished"->True,
    "PhysicalRegionCompleteness"->proof,"AllOtherCapAssignmentsExcludedByProof"->True|>]],
 {caps,Keys[all["Regions"]]}];
 If[Length[candidates]=!=1,boundaryIntegrationFail["CompleteDoubleCollinearCoefficientRequiresAnotherProfile",
   <|"RecognizedCoefficientCount"->Length[candidates]|>]];
 First[candidates]
 ],"BoundaryIntegration"];
End[];
