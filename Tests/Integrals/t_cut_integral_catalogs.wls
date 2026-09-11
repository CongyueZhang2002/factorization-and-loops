Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
base=<|"FinalMomenta"->{k1,k2,k3},"TotalMomentum"->p+q,
 "ExternalMomenta"->{p,q},"ReferenceMomentum"->p,"TaggedMomentum"->k1,
 "MeasurementVariable"->z,"KinematicRules"->{
  FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->0,FeynCalc`SPD[p,q]->s/2},
 "Assumptions"->s>0&&0<z<1|>;
family[momentum_,eta_:1]:=FeynFacet`CreateMeasuredPhaseSpaceDefinition[
 Join[base,<|"Name"->CF1,"OrdinaryPropagators"->{
  FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[
   FeynCalc`Momentum[momentum,D],0,0,{1,eta}]]}|>]];
master=FeynCalc`GLI[CF1,{1,1,1,1,1}];
catalog[record_,m_:master]:=<|"Integrals"->{m},"Families"->{record},
 "Normalization"->"Explicit typed measures"|>;
a=catalog[family[p-k2]];b=catalog[family[p-k3]];
match=FeynFacet`MatchCutIntegralCatalogs[a,b];
FTTest`FTAssert["same family names in different catalogs do not collide",
 AssociationQ[match]&&match["Status"]==="Complete"&&match["Rules"]==={master->master}];
FTTest`FTAssert["the exact loop transformations are retained",
 ContainsAll[Keys[First[match["Mappings"]]],{"SourceFrame","RepresentativeFrame"}]];
FTTest`FTAssert["same name with different causal prescription stays unmatched",
 FeynFacet`MatchCutIntegralCatalogs[a,catalog[family[p-k3,-1]]]["UnmatchedIntegrals"]==={master}];
FTTest`FTAssert["measurement derivatives remain part of an integral definition",
 FeynFacet`MatchCutIntegralCatalogs[a,catalog[family[p-k3],
  FeynCalc`GLI[CF1,{1,1,1,2,1}]]]["Status"]==="UnmatchedIntegralsRemain"];
FTTest`FTAssert["normalization mismatches cannot be hidden by names",
 FailureQ[FeynFacet`MatchCutIntegralCatalogs[a,Append[b,"Normalization"->2]]]];
FTTest`FTAssert["unlisted source family is rejected",
 FailureQ[FeynFacet`MatchCutIntegralCatalogs[Append[a,"Integrals"->{FeynCalc`GLI[CF2,{1,1,1,1,1}]}],b]]];
FTTest`FTAssert["typed normalization is still checked inside each catalog",
 FeynFacet`MatchCutIntegralCatalogs[a,catalog[Append[First[b["Families"]],
  "MeasurePrefactor"->2First[b["Families"]]["MeasurePrefactor"]]]]["Status"]==="UnmatchedIntegralsRemain"];

preferredMaster=FeynCalc`GLI["PreferredFamily",{1,1,1,1,1}];
preferredFamily=Join[First[b["Families"]],<|"Topology"->ReplacePart[First[b["Families"]]["Topology"],1->"PreferredFamily"]|>];
extended=Join[b,<|"Integrals"->{master,preferredMaster},
 "Families"->Append[b["Families"],preferredFamily],"PreferredIntegrals"->{preferredMaster}|>];
FTTest`FTAssert["a preferred saved solution is selected within its exact equivalence class",
 FeynFacet`MatchCutIntegralCatalogs[a,extended]["Rules"]==={master->preferredMaster}];
FTTest`FTAssert["nonpreferred target integrals remain eligible",
 FeynFacet`MatchCutIntegralCatalogs[a,Append[b,"PreferredIntegrals"->{}]]["Status"]==="Complete"];
FTTest`FTAssert["missing preferred integrals are rejected",
 FailureQ[FeynFacet`MatchCutIntegralCatalogs[a,Append[b,"PreferredIntegrals"->{preferredMaster}]]]];


plain=<|"Name"->CF1,
 "Topology"->FeynCalc`FCTopology[CF1,{
  FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[k1,D],0,0,{1,1}]],
  FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[k1-p,D],0,0,{1,1}]]},
  {k1},{p},{}],
 "CutMomenta"->{k1},"CutIndices"->{1},"CutDirections"->{1}|>;
plainMaster=FeynCalc`GLI[CF1,{1,1}];
restricted[c_]:=catalog[Append[plain,"AdditionalAcceptanceBoundaries"->c],plainMaster];
FTTest`FTAssert["distinct integration boundaries cannot disappear from untyped catalogs",
 FeynFacet`MatchCutIntegralCatalogs[restricted[k1>0],restricted[k1>1]]["Status"]==="UnmatchedIntegralsRemain"];
FTTest`FTAssert["an identical additional domain still admits the identity map",
 FeynFacet`MatchCutIntegralCatalogs[restricted[k1>0],restricted[k1>0]]["Status"]==="Complete"];
FTTest`FTAssert["different domain assumptions are retained conservatively",
 FeynFacet`MatchCutIntegralCatalogs[catalog[Append[plain,"Assumptions"->s>0],plainMaster],
  catalog[Append[plain,"Assumptions"->s<0],plainMaster]]["Status"]==="UnmatchedIntegralsRemain"];


plainProp[q_]:=FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[q,D],0,0,{1,1}]];
plainTwo=<|"Name"->CF1,
 "Topology"->FeynCalc`FCTopology[CF1,plainProp/@{k1,k2,p+q-k1-k2,p-k1},{k1,k2},{p,q},{}],
 "CutMomenta"->{k1,k2,p+q-k1-k2},"CutIndices"->{1,2,3},"CutDirections"->{1,1,1}|>;
plainSwapped=plainTwo/.{k1->k2,k2->k1};
domain=FeynCalc`Pair[FeynCalc`Momentum[p,D],FeynCalc`Momentum[k1,D]]>s/4;
FTTest`FTAssert["index-space identity cannot relabel a loop with an unmapped acceptance condition",
 FeynFacet`MatchCutIntegralCatalogs[
  catalog[Append[plainTwo,"AdditionalAcceptanceBoundaries"->domain],FeynCalc`GLI[CF1,{1,1,1,1}]],
  catalog[Append[plainSwapped,"AdditionalAcceptanceBoundaries"->domain],FeynCalc`GLI[CF1,{1,1,1,1}]]]["Status"]==="UnmatchedIntegralsRemain"];


plainFour=plain/.FeynCalc`Momentum[m_,D]:>FeynCalc`Momentum[m,4];
FTTest`FTAssert["distinct Lorentz-dimension annotations are not identified",
 FeynFacet`MatchCutIntegralCatalogs[catalog[plain,plainMaster],catalog[plainFour,plainMaster]]["Status"]==="UnmatchedIntegralsRemain"];
plainMixed=Join[plain,<|"Topology"->ReplacePart[plain["Topology"],
 {2,2}->(plain["Topology"][[2,2]]/.FeynCalc`Momentum[m_,D]:>FeynCalc`Momentum[m,4])]|>];
FTTest`FTAssert["mixed projected and full-dimensional propagators require explicit projector algebra",
 FailureQ[FeynFacet`MatchCutIntegralCatalogs[catalog[plain,plainMaster],catalog[plainMixed,plainMaster]]]];
FTTest`FTAssert["untyped records retain declared measure factors too",
 FeynFacet`MatchCutIntegralCatalogs[catalog[Append[plain,"MeasurePrefactor"->1],plainMaster],
  catalog[Append[plain,"MeasurePrefactor"->2],plainMaster]]["Status"]==="UnmatchedIntegralsRemain"];

plainSquared=plain/.FeynCalc`StandardPropagatorDenominator[m_,a_,b_,{1,eta_}]:>
 FeynCalc`StandardPropagatorDenominator[m,a,b,{2,eta}];
FTTest`FTAssert["powers stored inside topology propagators are not silently normalized",
 FailureQ[FeynFacet`MatchCutIntegralCatalogs[catalog[plain,plainMaster],catalog[plainSquared,plainMaster]]]];

FTTest`FTReport[];
