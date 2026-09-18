Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
temp=CreateDirectory[];
CopyFile[root<>"/Projects/DrellYan_UU/Common-Card.wl",temp<>"/Common-Card.wl"];
rawDir=temp<>"/Raw/NLO/q-qb";resultDir=temp<>"/Results/NLO/q-qb";
realDef=Get[root<>"/Projects/DrellYan_UU/Raw/NLO/q-qb/Real/Card.wl"];
FeynFacet`WriteProjectCard[realDef,rawDir<>"/Real/Card.wl"];
resultCard=<|"ResultType"->"SelectedSum","EpsilonRange"->{-2,0},"RequireFinite"->False,
 "Inputs"->{<|"Path"->"../../../Raw/NLO/q-qb/Real","Weight"->1|>}|>;
write[c_]:=FeynFacet`WriteProjectCard[c,resultDir<>"/Result_Card.wl"];
plan[c_]:=FeynFacet`PlanProjectResult[write[c]];
p=plan[resultCard];
FTTest`FTAssert["a selected real contribution can be planned without virtual, counterterms or lower-order folders",AssociationQ[p]];
v=FeynFacet`RunRawContribution[p["RawCards"]["Real"],"all"];
FTTest`FTAssert["raw generation succeeds with uncancelled poles",AssociationQ[v]&&
 FeynFacet`ReadPartonicResult[v["File"]]["LaurentLowerBound"]===-2];
a=FeynFacet`AssembleProjectResult[p];
FTTest`FTAssert["a selected Laurent sum retains its poles without claiming finiteness",AssociationQ[a]&&
 !TrueQ[Lookup[FeynFacet`ReadPartonicResult[a["ResultFile"]],"PoleCancellationVerified",False]]&&
 FeynFacet`ReadPartonicResult[a["ResultFile"]]["EpsilonRange"]==={-2,0}];
FTTest`FTAssert["complete coverage and pole cancellation are separate from raw execution",
 FailureQ[plan[Join[resultCard,<|"ResultType"->"CompleteCoefficient","RequireFinite"->True,"EpsilonRange"->{0,0}|>]]]];
FTTest`FTAssert["a complete physical coefficient cannot disable its finiteness requirement",
 FailureQ[plan[Join[resultCard,<|"ResultType"->"CompleteCoefficient"|>]]]];
FTTest`FTAssert["duplicate selected paths are rejected",FailureQ[plan[Join[resultCard,
 <|"Inputs"->Join[resultCard["Inputs"],resultCard["Inputs"]]|>]]]];
var=First[p["RawCards"]["Real"]["Assembly"]["Variables"]];
FTTest`FTAssert["a coordinate-dependent weight cannot multiply plus coefficients as scalars",
 FailureQ[plan[Join[resultCard,<|"Inputs"->{Join[First[resultCard["Inputs"]],<|"Weight"->var|>]}|>]]]];
coupling=p["RawCards"]["Real"]["Counterterms"]["Coupling"];
FTTest`FTAssert["result weights cannot silently change perturbative order",
 FailureQ[plan[Join[resultCard,<|"Inputs"->{Join[First[resultCard["Inputs"]],<|"Weight"->coupling|>]}|>]]]];
FTTest`FTAssert["requested higher epsilon orders propagate to raw generation",
 With[{higher=plan[Join[resultCard,<|"EpsilonRange"->{-2,1}|>]]},
  AssociationQ[higher]&&higher["RawCards"]["Real"]["EpsilonRange"]==={-2,1}&&
  FailureQ[FeynFacet`AssembleProjectResult[higher]]]];
r=FeynFacet`ReadPartonicResult[v["File"]];
reordered=Join[r,<|"CouplingNormalization"->Reverse[r["CouplingNormalization"]]|>];
FTTest`FTAssert["normalization comparison ignores association key order",
 AssociationQ[FeynFacet`CombinePartonicResults[<|"A"->r,"B"->reordered|>,<|"Contribution"->"Total"|>]]];
wrong=Join[r,<|"CouplingNormalization"->Join[r["CouplingNormalization"],<|"PoleNormalization"->2|>]|>];
FTTest`FTAssert["different physical coupling normalizations are rejected",
 FailureQ[FeynFacet`CombinePartonicResults[<|"A"->r,"B"->wrong|>,<|"Contribution"->"Total"|>]]];
loc=FeynFacet`Private`projectResultLocation[rawDir<>"/Real/Work/Components/Pair/Work/Reduction",temp];
FTTest`FTAssert["Kira ownership follows the nearest contribution Work directory",
 AssociationQ[loc]&&loc["OwnerParts"]==={"Raw","NLO","q-qb","Real","Work","Components","Pair","Work"}&&
 loc["RunParts"]==={"Reduction"}];

ctName="Counter-PDFA";
ctDef=Get[root<>"/Projects/DrellYan_UU/Raw/NLO/q-qb/"<>ctName<>"/Card.wl"];
FeynFacet`WriteProjectCard[ctDef,rawDir<>"/"<>ctName<>"/Card.wl"];
ct=FeynFacet`ReadContributionCard[rawDir,ctName,"q-qb"];ctPlan=FeynFacet`PlanCountertermContribution[ct];
FTTest`FTAssert["the pole operator derives Born through epsilon one",ctPlan["BornSourceOrders"]===<|"q-qb"->1|>];
ctRun=FeynFacet`RunRawContribution[ct,"all"];
FTTest`FTAssert["a counterterm runs independently and regenerates its own source without LO results",
 AssociationQ[ctRun]&&!DirectoryQ[temp<>"/LO"]&&!DirectoryQ[temp<>"/Raw/LO"]&&
 FileExistsQ[ct["WorkDirectory"]<>"/Sources/LO/q-qb/Results.wl"]];
FTTest`FTAssert["a changed source density kind cannot be silently interpreted as Born",
 FailureQ[FeynFacet`CompileCountertermCard[rawDir,Join[ctDef,<|"SourceContribution"->"Virtual"|>]]]];
loPlan=FeynFacet`PlanProjectResult[root<>"/Projects/DrellYan_UU/Results/LO/q-qb/Result_Card.wl"];
FTTest`FTAssert["standalone LO requests only epsilon zero",AssociationQ[loPlan]&&
 loPlan["RawEpsilonRanges"]===<|"Born"->{0,0}|>];
ll=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_LL/Raw/NLO/q-q","Counter-PDF","q-q"];
FTTest`FTAssert["a finite helicity scheme has no invented positive-epsilon extension",
 FailureQ[FeynFacet`PlanCountertermContribution[Join[ll,<|"EpsilonRange"->{-1,1}|>]]]];
again=FeynFacet`RunRawContribution[p["RawCards"]["Real"],"all"];
FTTest`FTAssert["evaluating a counterterm first does not change an ordinary raw result",
 AssociationQ[again]&&FeynFacet`ReadPartonicResult[again["File"]]["Coefficients"]===r["Coefficients"]];
FTTest`FTAssert["non-LO card preparation refuses an unestablished Laurent lower bound",
 FailureQ[FeynFacet`PrepareProjectChannel[temp,"NLO","qb-q"]]&&
 !FileExistsQ[temp<>"/Raw/NLO/qb-q/Real/Card.wl"]];
prepared=FeynFacet`PrepareProjectChannel[temp,"NLO","qb-q",<|"Real"->-2,"Virtual"->-2|>];
FTTest`FTAssert["new channel cards and a complete explicit result selection are generated from common physics",
 AssociationQ[prepared]&&AssociationQ[FeynFacet`PlanProjectResult[prepared["ResultCard"]]]];
FTTest`FTAssert["preparation does not overwrite existing user cards",
 FailureQ[FeynFacet`PrepareProjectChannel[temp,"NLO","qb-q"]]];
reorderedRecord=Join[r,<|"Coefficients"->Map[Reverse,r["Coefficients"]]|>];
FTTest`FTAssert["readback compares the exact mathematical record independently of nested association order",
 FeynFacet`Private`projectPartonicRecordSameQ[r,reorderedRecord]];
changedRecord=r;
changedRecord["Coefficients"]=Join[r["Coefficients"],<|0->Join[r["Coefficients"][0],<|
 "RegularCoefficient"->(r["Coefficients"][0]["RegularCoefficient"]+1)|>]|>];
FTTest`FTAssert["readback still rejects a changed finite scalar coefficient",
 !FeynFacet`Private`projectPartonicRecordSameQ[r,changedRecord]];
FTTest`FTAssert["readback still rejects a changed coupling normalization",
 !FeynFacet`Private`projectPartonicRecordSameQ[r,wrong]];
DeleteDirectory[temp,DeleteContents->True];
Print["STAGED PROJECT RESULT TEST COMPLETE"];FTTest`FTReport[];
