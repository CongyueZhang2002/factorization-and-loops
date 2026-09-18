Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
card=FeynFacet`ReadContributionCard[root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer/Raw/NLO/q-q","Real.Gluons"];
setup=FeynFacet`ReadProcessCard[card];
labels={p,q,k1,k2,k3,spinX,spinOutX,spinY};
vectors={{2,0,0,2},{0,0,0,-2},{3/4,3/4,0,0},{5/8,-3/8,1/2,0},{5/8,-3/8,-1/2,0},
 {0,1,0,0},{0,0,0,-1},{0,0,1,0}};
metric=DiagonalMatrix[{1,-1,-1,-1}];
kin=Flatten[Table[SPD[labels[[i]],labels[[j]]]->vectors[[i]].metric.vectors[[j]],{i,Length[labels]},{j,i,Length[labels]}]];
point={Q2->4,x->1/2,z->3/8,w->3/5,muR2->1};
baseRequest=FeynFacet`ProjectAssemblyRequest[card]/.point;
request=Join[baseRequest,<|"KinematicRules"->kin,"ApplyKinematicsInFORM"->True,"PrintTimings"->True,
 "CurrentProjectors"->KeyTake[baseRequest["CurrentProjectors"],{"TransversePhoton"}],
 "ColorRules"->{FeynCalc`CA->3,FeynCalc`CF->4/3,eU->2/3}|>];
setup=Join[setup,<|"PhysicalMomenta"->labels|>];
answer=<||>;
Do[
 local=Join[setup,<|"UnobservedGluonStates"->{<|"Momentum"->k2,"Sum"->"Physical","ReferenceMomentum"->ref|>,
  <|"Momentum"->k3,"Sum"->"Covariant"|>}|>];
 value=FeynFacet`ConstructCurrentIntegrands[local,request];
 If[!AssociationQ[value],Print[value];Exit[1]];
 scalars=Map[Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FeynAmpDenominatorExplicit[#]]/.
  Join[FCI[kin],FCI[kin]/.FeynCalc`Momentum[a_,D]:>FeynCalc`Momentum[a]]]&,value["Values"]];
 AssociateTo[answer,ToString[ref,InputForm]->scalars];
 FeynFacet`FamilyArtifactWrite[<|"Reference"->ref,"Values"->scalars,"PhysicalPoint"->point|>,
  root<>"/Tests/Logs/HighPTGluonGauge-"<>If[ref===p,"Null","Timelike"]<>".wl"],
 {ref,{p,p+q}}];
FTTest`FTAssert["null and timelike gluon references agree at a rational physical phase-space point, at exact D",
 AllTrue[MapThread[Factor[#1-#2]&,{Values[answer[[1]]],Values[answer[[2]]]}],#===0&]];
Print["HIGHPT REAL GLUON GAUGE TEST COMPLETE"];
FTTest`FTReport[];
