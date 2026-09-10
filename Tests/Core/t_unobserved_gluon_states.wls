$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
ugRules=FeynCalc`FCI[{FeynCalc`SPD[ugK]->0,FeynCalc`SPD[ugL]->0,
 FeynCalc`SPD[ugK,ugL]->ugS,FeynCalc`SPD[ugP]->ugP2,
 FeynCalc`SPD[ugK,ugP]->ugA,FeynCalc`SPD[ugL,ugP]->ugB}];
ugContract[expr_]:=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`Contract[FeynCalc`FCI[expr]]]/.ugRules];
ugD[k_,ref_,a_,b_]:=FeynFacet`GluonPolarizationProjector[k,ref,{a,b}];
FTTest`FTAssert["physical projector is transverse to the gluon and a non-null reference",
 ugContract[ugD[ugK,ugP,ugM,ugN]FeynCalc`FVD[ugK,ugM]]===0&&
 ugContract[ugD[ugK,ugP,ugM,ugN]FeynCalc`FVD[ugP,ugM]]===0];
FTTest`FTAssert["unobserved gluon sum contains D-2 states without an average",
 ugContract[-ugD[ugK,ugP,ugM,ugN]FeynCalc`MTD[ugM,ugN]]===D-2];
(* A Ward-compatible tensor with a nonzero longitudinal Slavnov-Taylor
   remainder: k.M = c l and M.l = c k. The two-covariant sum differs by 2 c^2. *)
ugTensor[a_,b_]:=FeynCalc`MTD[a,b]-FeynCalc`FVD[ugL,a]FeynCalc`FVD[ugK,b]/ugS+
 ugC(FeynCalc`FVD[ugK,a]FeynCalc`FVD[ugK,b]+FeynCalc`FVD[ugL,a]FeynCalc`FVD[ugL,b])/ugS;
ugPair=ugTensor[ugM,ugR]ugTensor[ugN,ugT];
ugDD=ugContract[ugPair ugD[ugK,ugP,ugM,ugN]ugD[ugL,ugP,ugR,ugT]];
ugDC=ugContract[-ugPair ugD[ugK,ugP,ugM,ugN]FeynCalc`MTD[ugR,ugT]];
ugCC=ugContract[ugPair FeynCalc`MTD[ugM,ugN]FeynCalc`MTD[ugR,ugT]];
FTTest`FTAssert["one physical and one covariant sum equals two physical sums",
 ugDD===D-2&&Factor[ugDC-ugDD]===0];
FTTest`FTAssert["the longitudinal state contribution makes two bare covariant sums wrong",
 Factor[ugCC-ugDD-2ugC^2]===0];
ugPolarized=ugPair FeynCalc`FVD[FeynCalc`Polarization[ugK,I],ugM]*
 FeynCalc`FVD[FeynCalc`Polarization[ugK,-I],ugN]*
 FeynCalc`FVD[FeynCalc`Polarization[ugL,I],ugR]*
 FeynCalc`FVD[FeynCalc`Polarization[ugL,-I],ugT];
ugStates={<|"Momentum"->ugK,"Sum"->"Physical","ReferenceMomentum"->ugP|>,
 <|"Momentum"->ugL,"Sum"->"Covariant"|>};
ugSummed=FeynFacet`SumUnobservedGluonPolarizations[ugPolarized,ugStates];
FTTest`FTAssert["declared mixed state contraction gives the physical Ward tensor norm",
 !FailureQ[ugSummed]&&ugContract[ugSummed]===D-2];
FTTest`FTAssert["an unsupported double-covariant state sum is rejected",
 FailureQ[FeynFacet`SumUnobservedGluonPolarizations[ugPolarized,
 {<|"Momentum"->ugK,"Sum"->"Covariant"|>,<|"Momentum"->ugL,"Sum"->"Covariant"|>}]]];
FTTest`FTAssert["a state cannot be summed twice",
 FailureQ[FeynFacet`SumUnobservedGluonPolarizations[ugPolarized,{First[ugStates],First[ugStates]}]]];
FTTest`FTReport[];
