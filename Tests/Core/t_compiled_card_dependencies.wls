$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Do[
 directory=root<>"/Projects/"<>project<>"/Raw/LO/"<>channel;
 card=FeynFacet`ReadContributionCard[directory,"Born"];
 setup=FeynFacet`ReadProcessCard[card];
 FTAssert[project<>" compiled and file-based process views agree",
  setup===FeynFacet`ReadProcessCard[directory,"Born"]];
 FTAssert[project<>" request selection comes from the compiled card",
  FeynFacet`ProjectAssemblyRequest[card]===FeynFacet`ProjectAssemblyRequest[card,channel,"Born"]];
 modified=card;modified["Assembly"]=Join[card["Assembly"],<|"Assumptions"->testCondition|>];
 FTAssert[project<>" in-memory contribution override is not replaced by a second disk read",
  FeynFacet`ProjectAssemblyRequest[modified]["Assumptions"]===testCondition],
 {selection,{{"SIDIS_UU","q-q"},{"ppHX_TT","qqp-qqp"}}},
 {project,{First[selection]}},{channel,{Last[selection]}}];


nnloCard=Join[card,<|"Order"->"NNLO","Contribution"->"DoubleReal"|>];
FTAssert["the shared request uses the actual perturbative order",
 FeynFacet`ProjectAssemblyRequest[nnloCard]["CouplingPower"]===nnloCard["BornCouplingPower"]+2&&
 FeynFacet`ProjectAssemblyRequest[card]["CouplingPower"]===card["BornCouplingPower"]];
FTAssert["a project without an explicit radiative order is not silently treated as NLO",
 FailureQ[FeynFacet`ProjectAssemblyRequest[FeynFacet`ReadProjectCard[
  root<>"/Projects/ppHX_UU"],"qqp-qqp","Real"]]];
temp=CreateDirectory[];channel="q-q";
CopyFile[root<>"/Projects/SIDIS_UU/Common-Card.wl",temp<>"/Common-Card.wl"];
CreateDirectory[temp<>"/Raw/NLO/q-q",CreateIntermediateDirectories->True];
consumer=FeynFacet`BuildCountertermProjectCard[temp<>"/Raw/NLO/q-q"];
compiledSource=FeynFacet`CompileBareSourceCard[consumer,"LO",channel,"Born",2];
FTAssert["a consuming NLO card compiles its Born source at exactly the demanded epsilon order",
 AssociationQ[compiledSource]&&compiledSource["Order"]==="LO"&&compiledSource["EpsilonRange"]==={0,2}&&
 compiledSource["Directory"]===consumer["Directory"]&&
 compiledSource["ContributionPath"]==="Counterterm/Sources/LO/q-q/Born"];
FTAssert["source compilation requires neither an LO folder nor an LO result",
 !DirectoryQ[temp<>"/Raw/LO"]&&FreeQ[compiledSource["BareSourceContributions"],"LowerOrderResults"]];
standalone=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_UU/Raw/LO/q-q","Born"];
standaloneResult=FeynFacet`ConstructBornResult[FeynFacet`ReadProcessCard[standalone],
 Join[FeynFacet`ProjectAssemblyRequest[standalone],<|"EpsilonRange"->standalone["EpsilonRange"]|>]];
FTAssert["standalone pure LO computes only its epsilon-zero coefficient",
 standalone["EpsilonRange"]==={0,0}&&AssociationQ[standaloneResult]&&Keys[standaloneResult["Coefficients"]]==={0}];
generated=FeynFacet`GenerateBornPartonicSources[consumer,<|channel->1|>];
file=temp<>"/Raw/NLO/q-q/Counterterm/Work/Sources/LO/q-q/Results.wl";
FTAssert["a fresh NLO consumer generates its needed Born coefficient without any LO result tree",
 AssociationQ[generated]&&generated["Results"][channel]["EpsilonRange"]==={0,1}&&
 generated["Results"][channel]["RenormalizationStage"]==="Bare"&&FileExistsQ[file]&&!DirectoryQ[temp<>"/Raw/LO"]];
FTAssert["the generated source records the consuming NLO ownership",
 KeyExistsQ[generated,"GeneratedSources"]&&
 !FreeQ[generated["GeneratedSources"],path_String/;StringStartsQ[path,temp<>"/Raw/NLO/q-q/Counterterm/Work/Sources/"]]];
DeleteFile[file];
regenerated=FeynFacet`GenerateBornPartonicSources[consumer,<|channel->2|>];
FTAssert["a missing source is regenerated at a newly increased epsilon demand",
 AssociationQ[regenerated]&&regenerated["Results"][channel]["EpsilonRange"]==={0,2}&&FileExistsQ[file]&&
 TrueQ[FeynFacet`RequirePartonicEpsilonRange[FeynFacet`ReadPartonicResult[file],{0,2}]]];
FTAssert["source generation does not change the pure LO card default",
 FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_UU/Raw/LO/q-q","Born"]["EpsilonRange"]==={0,0}];
DeleteDirectory[temp,DeleteContents->True];
FTReport[];
