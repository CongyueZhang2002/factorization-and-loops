Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
projectDirectory=root<>"/Projects/SIDIS_HighPT_TT_SpinTransfer";
plan=FeynFacet`PlanProjectResult[projectDirectory<>"/Results/NLO/q-q/Result_Card.wl"];
If[!AssociationQ[plan],Print[plan];Exit[1]];
parts=FeynFacet`ReadRawContributionResult/@plan["RawCards"];
If[!AllTrue[Values[parts],AssociationQ],Print["Matching raw inputs required"];Exit[1]];
sum=FeynFacet`CombinePartonicResults[parts,<|"Contribution"->"Total"|>];
cs=KeySelect[FeynFacet`PartonicScalarCoefficientRules[sum],First[#]<0&];
fixed={Q2->1,muR2->2,muF2->3,muD2->5,FeynCalc`CA->3,FeynCalc`CF->4/3,FeynCalc`TR->1/2,
 eU->2/3,eD->-1/3,nU->2,nD->3,FeynFacet`\[Alpha]s->1};
Do[
 values=N[Values[cs]/.Join[point,fixed],35];
 Print["NUMERICAL POLE VALUES ",AssociationThread[Keys[cs],values]];
 FTTest`FTAssert["all distribution and photon-structure poles cancel at physical rational kinematics",
 VectorQ[values,NumericQ]&&Max[Abs[values]]<10^-24],
 {point,{{x->1/3,z->2/5,w->3/4},{x->3/5,z->1/4,w->2/3}}}];
Print["HIGHPT QUARK POLE TEST COMPLETE"];FTTest`FTReport[];
