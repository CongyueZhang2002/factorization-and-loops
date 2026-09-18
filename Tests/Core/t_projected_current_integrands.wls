$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
pciEqual[a_Association,b_Association]:=AllTrue[Union[Keys[a],Keys[b]],
 pciEqual[Lookup[a,#,0],Lookup[b,#,0]]&];
pciEqual[a_Association,0]:=AllTrue[Values[a],pciEqual[#,0]&];
pciEqual[0,b_Association]:=pciEqual[b,0];
pciEqual[a_,b_]:=TrueQ[FullSimplify[a==b,Assumptions->Q2>0&&muR2>0&&0<x<1&&0<z<1]];
Do[
 pciDirectory=root<>"/Projects/"<>pciCase[[1]]<>"/Raw/NLO/"<>pciCase[[2]];
 pciCard=FeynFacet`ReadContributionCard[pciDirectory,"Real"];
 pciSetup=FeynFacet`ReadProcessCard[pciDirectory,"Real"];
 pciRequest=FeynFacet`ProjectAssemblyRequest[pciCard,pciCase[[2]],"Real"];
 pciOld=FeynFacet`ConstructCurrentRealDensity[pciSetup,pciRequest];

 pciContractionRequest=If[pciCase[[1]]==="SIDIS_LL",
  Join[pciRequest,<|"AngularAverage"->pciRequest["JointAngularAverage"],
   "LongitudinalCurrentAverage"->"BeforeContraction"|>],pciRequest];
 pciNew=FeynFacet`ConstructCurrentIntegrands[pciSetup,pciContractionRequest];
 If[pciCase[[1]]==="SIDIS_LL",
  FTTest`FTAssert[pciCase[[2]]<>" uses the proven joint helicity-current average",
   AssociationQ[pciNew]&&Keys[pciNew["LongitudinalCurrentAverage"]]==={"2g1"}]];

 FTTest`FTAssert[pciCase[[1]]<>"/"<>pciCase[[2]]<>" projected traces close to scalar integrands",AssociationQ[pciNew]];
 If[AssociationQ[pciNew]&&AssociationQ[pciOld],
  pciSaved=FeynFacet`ReadPartonicResult[pciDirectory<>"/Results/Real/Result.wl"];
  pciExpanded=FeynFacet`ConstructCurrentRealContribution[pciOld,
   Join[pciRequest["EndpointExpansion"],<|"EpsilonRange"->pciCard["EpsilonRange"]|>]];
  FTTest`FTAssert[pciCase[[1]]<>"/"<>pciCase[[2]]<>" all epsilon coefficients agree with the independently validated saved real contribution",
   AssociationQ[pciSaved]&&AssociationQ[pciExpanded]&&pciEqual[pciExpanded["Coefficients"],pciSaved["Coefficients"]]];
  pciGeometry=FeynFacet`ConstructTwoParticleMeasurement[Join[pciRequest["TwoParticleMeasurement"],
   <|"DimensionalRegulator"->pciRequest["DimensionalRegulator"]|>]];
  pciMeasured=FeynFacet`EvaluateTwoParticleMeasurement[FeynCalc`FeynAmpDenominatorExplicit[#],pciGeometry]&/@Values[pciNew["Values"]];
  pciValues=Factor[(pciRequest["CurrentNormalization"]#["Value"])/.pciRequest["BareCouplingRules"]/.pciRequest["ColorRules"]]&/@pciMeasured;
  FTTest`FTAssert[pciCase[[1]]<>"/"<>pciCase[[2]]<>" early projection agrees with the established exact-epsilon real density",
   And@@(TrueQ[FullSimplify[#,pciGeometry["Assumptions"]&&0<x<1&&0<z<1]===0]&/@(pciValues-pciOld["Values"]))],
  FTTest`FTAssert["both generated comparison values exist",False]],
 {pciCase,{{"SIDIS_UU","q-q"},{"SIDIS_LL","g-q"},{"SIDIS_LL","q-q"},{"SIDIS_LL","q-g"}}}];
FTTest`FTReport[];
