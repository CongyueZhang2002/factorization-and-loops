#!/usr/bin/env wolframscript
assemblyTestRoot=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{assemblyTestRoot,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{assemblyTestRoot,"FeynFacet","Solutions","Orders","LaurentBounds.wl"}]];
BeginPackage["FeynFacet`"];
AssembleCutContributions::usage="Assemble weighted cut contributions.";
NA::usage="An unobserved external leg.";
Begin["`Private`"];
Get[FileNameJoin[{Global`assemblyTestRoot,"FeynFacet","Algebra","ExactArithmetic.wl"}]];
Get[FileNameJoin[{Global`assemblyTestRoot,"FeynFacet","Integrals","LinearCombinations.wl"}]];
Get[FileNameJoin[{Global`assemblyTestRoot,"FeynFacet","Coefficients","FinalResults.wl"}]];
Get[FileNameJoin[{Global`assemblyTestRoot,"FeynFacet","Coefficients","HardFunction.wl"}]];
$feynFacetEpsilon=Global`assemblyTestEpsilon;
End[];
EndPackage[];
Clear[assemblyTestEpsilon,assemblyTestSource,assemblyTestTarget,assemblyTestLoop,assemblyTestMomentum];
assemblyTestSetup=<|"Partons"->({FeynArts`F[3,{1}],FeynArts`F[4,{1}]}->
 {FeynArts`F[3,{1}],FeynArts`F[4,{1}],FeynArts`V[5],FeynArts`V[5]}),
 "HadronMomentum"->({assemblyTestPa,assemblyTestPb}->{assemblyTestPh,FeynFacet`NA,FeynFacet`NA,FeynFacet`NA})|>;
assemblyTestGhostSetup=Join[assemblyTestSetup,<|"Partons"->({FeynArts`F[3,{1}],FeynArts`F[4,{1}]}->
 {FeynArts`F[3,{1}],FeynArts`F[4,{1}],FeynArts`U[5],-FeynArts`U[5]})|>];
assemblyTestTopology[family_,shift_:0] := <|
 "Topology"->FeynCalc`FCTopology[family,{assemblyTestLoop^2-shift},{assemblyTestLoop},{assemblyTestMomentum},{}],
 "CutMomenta"->{assemblyTestLoop},"CutIndices"->{1},"CutDirections"->{1}|>;
assemblyTestExact[x_,pref_:1] := <|"Representation"->"Exact","PreFactor"->pref,"Coefficient"->x|>;
assemblyTestFinite[values_List,lo_:0,pref_:1] := <|"Representation"->"LaurentSeries","PreFactor"->pref,
 "Coefficient"-><|"SeriesVariable"->assemblyTestEpsilon,
 "Orders"->AssociationThread[Range[lo,lo+Length[values]-1],values],"SeriesTruncation"->lo+Length[values]-1|>|>;
assemblyTestRecord[master_,terms_,topology_,setup_:assemblyTestSetup] := <|
 "Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,"DimensionalRegulator"->assemblyTestEpsilon,
 "PreFactor"->1,"FractionMeasure"->1,"PhaseSpace"->1,"CompleteTargetSet"->True,
 "Masters"->{<|"Master"->master,"Terms"->terms|>},"RemainderTerms"->{},
 "Definitions"-><|"Setup"->setup,"Topologies"->{topology}|>|>;
assemblyTestExpand[entry_,range_] := FeynFacet`ExpandMasterIntegralCoefficient[entry,assemblyTestEpsilon,range];
assemblyTestSourceRecord=assemblyTestRecord[AssemblyForeignContext`GLI["assemblyTestSource",{1}],
 {assemblyTestFinite[{2,3}]},assemblyTestTopology["assemblyTestSource"]];
assemblyTestMapped=FeynFacet`AssembleCutContributions[{assemblyTestSourceRecord},"Weights"->{1},
 "MasterIntegralRules"->{FeynCalc`GLI[assemblyTestSource,{1}]->
   AssemblyAlternateContext`GLI[assemblyTestTarget,{1}]/assemblyTestEpsilon+5/assemblyTestEpsilon},
 "TargetTopologies"->{assemblyTestTopology["assemblyTestTarget"]}];
FTAssert["master maps use the same identity for string and symbolic family labels",
 AssociationQ[assemblyTestMapped] && Length[assemblyTestMapped["Masters"]]===1 &&
 FeynFacet`Private`coefficientMasterID[assemblyTestMapped["Masters"][[1,"Master"]]]==={"assemblyTestTarget",{1}}];
FTAssert["foreign GLI heads are normalized before linear master parsing",
 FreeQ[assemblyTestMapped["Masters"],_AssemblyForeignContext`GLI|_AssemblyAlternateContext`GLI] &&
 FreeQ[assemblyTestMapped["RemainderTerms"],_FeynCalc`GLI|_AssemblyForeignContext`GLI|_AssemblyAlternateContext`GLI]];
FTAssert["epsilon-pole master maps shift the finite coefficient demands",
 assemblyTestExpand[assemblyTestMapped["Masters"][[1]],{-1,0}]["Coefficients"]===<|-1->2,0->3|> &&
 MatchQ[assemblyTestExpand[assemblyTestMapped["Masters"][[1]],{-1,1}],Failure["CoefficientEpsilonOrdersInsufficient",_Association]]];
FTAssert["scalar parts of a linear map preserve the same finite remainder orders",
 assemblyTestExpand[<|"Terms"->assemblyTestMapped["RemainderTerms"]|>,{-1,0}]["Coefficients"]===<|-1->10,0->15|> &&
 MatchQ[assemblyTestExpand[<|"Terms"->assemblyTestMapped["RemainderTerms"]|>,{-1,1}],Failure["CoefficientEpsilonOrdersInsufficient",_Association]]];
assemblyTestUnmapped=FeynFacet`AssembleCutContributions[{assemblyTestSourceRecord},"Weights"->{1}];
FTAssert["an unmapped foreign-head GLI remains a master rather than a scalar remainder",
 Length[assemblyTestUnmapped["Masters"]]===1 && assemblyTestUnmapped["RemainderTerms"]==={} &&
 Head[assemblyTestUnmapped["Masters"][[1,"Master"]]]===FeynCalc`GLI];
assemblyTestString=assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],
 {assemblyTestExact[2]},assemblyTestTopology["assemblyTestSource"]];
assemblyTestSymbol=assemblyTestRecord[FeynCalc`GLI[assemblyTestSource,{1}],
 {assemblyTestExact[7]},assemblyTestTopology[assemblyTestSource]];
assemblyTestCombined=FeynFacet`AssembleCutContributions[{assemblyTestString,assemblyTestSymbol},"Weights"->{1,1}];
FTAssert["identical topologies differing only in family-label representation merge exactly",
 AssociationQ[assemblyTestCombined] && Length[assemblyTestCombined["Masters"]]===1 &&
 Length[assemblyTestCombined["Masters"][[1,"Terms"]]]===1 &&
 assemblyTestExpand[assemblyTestCombined["Masters"][[1]],{0,0}]["Coefficients"]===<|0->9|>];
FTAssert["an unmapped source topology cannot be replaced by a different target topology",
 MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString},"Weights"->{1},
  "TargetTopologies"->{assemblyTestTopology["assemblyTestSource",1]}],Failure["UnmappedMasterTopologyMismatch",_Association]]];
FTAssert["duplicate master rules are detected across family-label representations",
 MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString},"Weights"->{1},
 "MasterIntegralRules"->{FeynCalc`GLI["assemblyTestSource",{1}]->0,FeynCalc`GLI[assemblyTestSource,{1}]->0}],
 Failure["DuplicateMasterIntegralRules",_Association]]];
assemblyTestCancelA=assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],
 {assemblyTestFinite[{2,3}]},assemblyTestTopology["assemblyTestSource"]];
assemblyTestCancelB=assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],
 {assemblyTestFinite[{-2,-3}]},assemblyTestTopology["assemblyTestSource"]];
assemblyTestCancelled=FeynFacet`AssembleCutContributions[{assemblyTestCancelA,assemblyTestCancelB},"Weights"->{1,1}];
FTAssert["cancelling known finite prefixes retain their unknown higher-order tail",
 Length[assemblyTestCancelled["Masters"]]===1 &&
 assemblyTestExpand[assemblyTestCancelled["Masters"][[1]],{0,1}]["Coefficients"]===<|0->0,1->0|> &&
 MatchQ[assemblyTestExpand[assemblyTestCancelled["Masters"][[1]],{0,2}],Failure["CoefficientEpsilonOrdersInsufficient",_Association]]];
assemblyTestShallow=assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],
 {assemblyTestFinite[{2}]},assemblyTestTopology["assemblyTestSource"]];
assemblyTestMixed=FeynFacet`AssembleCutContributions[{assemblyTestShallow,assemblyTestCancelA},"Weights"->{1,1}];
FTAssert["different finite truncation orders are retained separately",
 Length[assemblyTestMixed["Masters"][[1,"Terms"]]]===2 &&
 assemblyTestExpand[assemblyTestMixed["Masters"][[1]],{0,0}]["Coefficients"]===<|0->4|> &&
 MatchQ[assemblyTestExpand[assemblyTestMixed["Masters"][[1]],{0,1}],Failure["CoefficientEpsilonOrdersInsufficient",_Association]]];
FTAssert["inexact master-map factors are rejected before assembly",
 MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString},"Weights"->{1},
  "MasterIntegralRules"->{FeynCalc`GLI["assemblyTestSource",{1}]->0.5FeynCalc`GLI[assemblyTestTarget,{1}]}],
 Failure["ExactMasterIntegralRulesRequired",_Association]]];
FTAssert["missing and failed master-map factors are rejected before assembly",
 AllTrue[{Missing["UnknownMap"],Failure["UnknownMap",<||>],$Failed},Function[bad,
  MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString},"Weights"->{1},
   "MasterIntegralRules"->{FeynCalc`GLI["assemblyTestSource",{1}]->bad}],
  Failure["ExactMasterIntegralRulesRequired",_Association]]]]];
FTAssert["a truncated master map cannot be treated as an exact identity",
 MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString},"Weights"->{1},
 "MasterIntegralRules"->{FeynCalc`GLI["assemblyTestSource",{1}]->SeriesData[assemblyTestEpsilon,0,{1},0,1,1]}],
 Failure["ExactMasterIntegralRulesRequired",_Association]]];
FTAssert["nonlinear master maps are rejected",
 MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString},"Weights"->{1},
 "MasterIntegralRules"->{FeynCalc`GLI["assemblyTestSource",{1}]->FeynCalc`GLI[assemblyTestTarget,{1}]^2}],
 Failure["MasterIntegralMapNotLinear",_Association]]];
assemblyTestWrongIncoming=Join[assemblyTestSetup,<|"Partons"->
 ({FeynArts`F[3,{1}],FeynArts`F[3,{1}]}->Last[assemblyTestSetup["Partons"]])|>];
assemblyTestWrongObserved=Join[assemblyTestSetup,<|"Partons"->
 (First[assemblyTestSetup["Partons"]]->{FeynArts`F[4,{1}],FeynArts`F[4,{1}],FeynArts`V[5],FeynArts`V[5]})|>];
FTAssert["different incoming partonic channels are rejected",
 MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString,
 assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],{assemblyTestExact[2]},assemblyTestTopology["assemblyTestSource"],assemblyTestWrongIncoming]},
 "Weights"->{1,1}],Failure["ContributionPhysicalPartonsMismatch",_Association]]];
FTAssert["different observed outgoing partons are rejected",
 MatchQ[FeynFacet`AssembleCutContributions[{assemblyTestString,
 assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],{assemblyTestExact[2]},assemblyTestTopology["assemblyTestSource"],assemblyTestWrongObserved]},
 "Weights"->{1,1}],Failure["ContributionPhysicalPartonsMismatch",_Association]]];
assemblyTestGhost=assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],
 {assemblyTestExact[2]},assemblyTestTopology["assemblyTestSource"],assemblyTestGhostSetup];
assemblyTestPhysical=FeynFacet`AssembleCutContributions[{assemblyTestString,assemblyTestGhost},"Weights"->{1/2,-1}];
FTAssert["unobserved gluon and ghost-antighost substitutions remain allowed",
 AssociationQ[assemblyTestPhysical] &&
 assemblyTestExpand[assemblyTestPhysical["Masters"][[1]],{0,0}]["Coefficients"]===<|0->-1|>];
assemblyTestMalformed=Join[assemblyTestSetup,<|"HadronMomentum"->({assemblyTestPa,assemblyTestPb}->{assemblyTestPh,FeynFacet`NA})|>];
FTAssert["incomplete observed-parton declarations are rejected",
 MatchQ[FeynFacet`AssembleCutContributions[{
 assemblyTestRecord[FeynCalc`GLI["assemblyTestSource",{1}],{assemblyTestExact[2]},assemblyTestTopology["assemblyTestSource"],assemblyTestMalformed]},
 "Weights"->{1}],Failure["PhysicalPartonDefinitionsRequired",_Association]]];
FTReport[];