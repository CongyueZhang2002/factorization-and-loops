Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
parameters=<|"CA"->pcA,"CF"->pcF,"TR"->1/2,"FlavorCount"->pnf|>;
normalization=FeynFacet`MSbarCouplingNormalization[pe,Exp[(pk+EulerGamma)pe]/(4Pi)^pe];
request=<|"PerturbativeOrder"->2,"ThroughOrder"->0,"DimensionalRegulator"->pe,
 "PerturbativeParameter"->pa,"BornCouplingPower"->0,"Legs"->{},"FlavorClasses"-><||>,
 "KernelParameters"->parameters,"CouplingNormalization"->normalization|>;
plan=FeynFacet`PlanCollinearRenormalization[{},request];
FTTest`FTAssert["a colorless decay permits coupling renormalization without collinear legs",AssociationQ[plan]];
If[!AssociationQ[plan],Print[InputForm[plan]];FTTest`FTReport[]];
uv=Join[plan,<|"Terms"->Select[plan["Terms"],#["SourceOrder"]<2&]|>];
b0=(11pcA-2pnf)/6;
FTTest`FTAssert["the generated power of Z alpha selects only the order-one source",
 Length[uv["Terms"]]===1&&uv["Terms"][[1]]["SourceOrder"]===1&&
 FullSimplify[uv["Terms"][[1]]["Factor"]+pa b0 Exp[pk pe]/pe]===0];
FTTest`FTAssert["the UV pole requires epsilon one without a guessed safety margin",
 uv["Terms"][[1]]["RequiredSourceThroughOrder"]===1];
basis=<|"Representation"->"UnitInterval","Variable"->pz,"Interval"->{0,1},"Endpoints"->{0,1}|>;
metadata=<|"Scale"->ps,"Variables"->{pz},"DimensionalRegulator"->pe,
 "DensityConvention"->"Test scalar density","DistributionBasis"->basis,
 "Order"->"NLO","Contribution"->"Bare","RenormalizationStage"->"Bare"|>;
shape=<|"DeltaCoefficients"-><|0->2,1->3|>,
 "PlusCoefficients"-><|0-><|0->5|>,1-><|1->7|>|>,"RegularCoefficient"->11pz|>;
scale[f_,row_]:=<|"DeltaCoefficients"->(f #&/@row["DeltaCoefficients"]),
 "PlusCoefficients"->(Map[f #&,#]&/@row["PlusCoefficients"]),"RegularCoefficient"->f row["RegularCoefficient"]|>;
source=FeynFacet`CreatePartonicResult[Association@Table[n->scale[pa pl^(n+2)/(n+2)!,shape],{n,-2,1}],metadata];
answer=FeynFacet`ApplyPartonicRenormalization[uv,Function[{n,sp,cl,hi},source],
 Join[metadata,<|"Order"->"NNLO","Contribution"->"Counterterm","RenormalizationStage"->"Counterterm"|>]];
FTTest`FTAssert["finite coupling normalization multiplies poles before truncation at both endpoints",
 AssociationQ[answer]&&And@@Table[TrueQ[FullSimplify[
  answer["Coefficients"][0]["DeltaCoefficients"][point]+b0 pa^2(pl+pk)^3 shape["DeltaCoefficients"][point]/6]===0],
  {point,{0,1}}]];
(* Compare every mathematical leaf independently of the association layout. *)
expected=scale[-b0 pa^2(pl+pk)^3/6,shape];
FTTest`FTAssert["all delta, plus and regular leaves retain the same scalar UV factor",
 AssociationQ[answer]&&And@@Map[TrueQ[FullSimplify[#]===0]&,
  {answer["Coefficients"][0]["PlusCoefficients"][0][0]-expected["PlusCoefficients"][0][0],
   answer["Coefficients"][0]["PlusCoefficients"][1][1]-expected["PlusCoefficients"][1][1],
   answer["Coefficients"][0]["RegularCoefficient"]-expected["RegularCoefficient"]}]];
short=FeynFacet`CreatePartonicResult[KeySelect[source["Coefficients"],#<=0&],metadata];
FTTest`FTAssert["a finite-only source cannot silently supply a missing epsilon coefficient",
 FailureQ[FeynFacet`ApplyPartonicRenormalization[uv,Function[{n,sp,cl,hi},short],metadata]]];
zero=FeynFacet`MultiplyPartonicLaurentFactor[source,0,{-3,0}];
FTTest`FTAssert["zero scalar products preserve the two-endpoint distribution format",
 AssociationQ[zero]&&AllTrue[Values[zero["Coefficients"]],KeyExistsQ[#,"DeltaCoefficients"]&]];
FTTest`FTAssert["a distribution-variable factor is not misclassified as an external Laurent scalar",
 FailureQ[FeynFacet`MultiplyPartonicLaurentFactor[source,pz,{-2,0}]]];
card=FeynFacet`ReadContributionCard[root<>"/Projects/EE_EEC/Raw/NNLO/q-qb","Counter-UV","q-qb"];
If[!AssociationQ[card],Print[InputForm[card]]];
cardPlan=If[AssociationQ[card],FeynFacet`PlanCountertermContribution[card],card];
FTTest`FTAssert["the physical counterterm card uses the common operator planner",
 AssociationQ[cardPlan]&&Length[cardPlan["Terms"]]===1&&cardPlan["Terms"][[1]]["RequiredSourceThroughOrder"]===1];
sourceCard=If[AssociationQ[card],FeynFacet`CompileBareSourceCard[card,"NLO","q-qb","Real",1],card];
FTTest`FTAssert["source epsilon coverage and paths belong to the counterterm consumer",
 AssociationQ[sourceCard]&&sourceCard["EpsilonRange"]==={-2,1}&&
 StringStartsQ[sourceCard["WorkDirectory"],card["WorkDirectory"]<>"/Sources/"]&&
 sourceCard["UnobservedPartons"]==={{"q","u"},{"qb","u"},"g"}];
Print["COUPLING ONLY RENORMALIZATION TEST COMPLETE"];
FTTest`FTReport[];
