#!/usr/bin/env wolframscript
$HistoryLength=0;$MaxExtraPrecision=50;
transferRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Block[{Print},Get[transferRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
transferRows={};transferFailures=0;
transferCheck[name_,value_]:=(AppendTo[transferRows,<|"Check"->name,"Passed"->TrueQ[value]|>];If[!TrueQ[value],transferFailures++];Print[If[TrueQ[value],"PASS ","FAIL "],name]);
transferRead[project_,order_,channel_:"qqp-qqp"]:=Module[{z=FeynFacet`ReadPartonicResult[transferRoot<>"/Projects/"<>project<>"/"<>order<>"/"<>channel<>"/Results/Result.wl"]},
 If[FailureQ[z],Print[z];Exit[1]];z];
transferColor={FeynCalc`CF->(FeynCalc`CA^2-1)/(2FeynCalc`CA)};
transferZero[expr_]:=TrueQ[Factor[TrigExpand[expr]/.transferColor]===0];
transferUU=transferRead["ppHX_UU_NNLO","NLO"];
transferLL=transferRead["ppHX_LL_SpinTransfer_NLO","NLO"];
transferTT=transferRead["ppHX_TT_SpinTransfer_NLO","NLO"];
transferCompare[one_,two_,label_]:=Module[{r1=one["Coefficients"][0],r2=two["Coefficients"][0]},
 transferCheck[label<>"/delta",transferZero[r1["DeltaCoefficient"]-r2["DeltaCoefficient"]]];
 Do[transferCheck[label<>"/plus"<>ToString[k],transferZero[Lookup[r1["PlusCoefficients"],k,0]-Lookup[r2["PlusCoefficients"],k,0]]],
  {k,Union[Keys[r1["PlusCoefficients"]],Keys[r2["PlusCoefficients"]]]}];
 transferCheck[label<>"/regular",transferZero[r1["RegularCoefficient"]-r2["RegularCoefficient"]]]];
transferCompare[transferLL,transferUU,"NLO helicity conservation"];
Do[
 transferUB=transferRead["ppHX_UU_NNLO","LO",transferChannel];
 transferLB=transferRead["ppHX_LL_SpinTransfer_NLO","LO",transferChannel];
 transferTB=transferRead["ppHX_TT_SpinTransfer_NLO","LO",transferChannel];
 transferCompare[transferLB,transferUB,"LO helicity conservation "<>transferChannel];
 {transferV,transferW}=transferUB["Variables"];
 transferExpected=2transferV/(1+transferV^2) STa STh Cos[phiA-\[Phi]h] transferUB["Coefficients"][0]["DeltaCoefficient"];
 transferCheck["TT Born transfer ratio "<>transferChannel,transferZero[transferTB["Coefficients"][0]["DeltaCoefficient"]-transferExpected]],
 {transferChannel,{"qqp-qqp","qg-qg"}}];
transferTB=transferRead["ppHX_TT_SpinTransfer_NLO","LO"];
transferCheck["TT leading soft logarithm",transferZero[transferTT["Coefficients"][0]["PlusCoefficients"][1]-
 transferTT["Coupling"]/Pi*5FeynCalc`CF*transferTB["Coefficients"][0]["DeltaCoefficient"]]];
transferCheck["TT finite transfer is nonzero",transferTT["Coefficients"][0]["DeltaCoefficient"]=!=0];
transferAngular=transferTT["Coefficients"][0];
transferAligned=Function[expr,expr/.{phiA->0,\[Phi]h->0}];
transferAngularValues=Join[{transferAngular["DeltaCoefficient"]},Values[transferAngular["PlusCoefficients"]],{transferAngular["RegularCoefficient"]}];
Do[transferCheck["TT helicity spin-angle correlation/"<>ToString[transferIndex],
 transferZero[transferAngularValues[[transferIndex]]-
  transferAligned[transferAngularValues[[transferIndex]]] Cos[phiA-\[Phi]h]]],
 {transferIndex,Length[transferAngularValues]}];

Do[
 transferValue=transferRead[transferProject,"NLO"];
 transferCheck[transferProject<>"/integral free",FreeQ[transferValue["Coefficients"],_Integrate|_NIntegrate|_FeynCalc`GLI|_FeynFacetSolution`F|_Inactive|_SeriesData|_SeriesCoefficient|_Failure|_Missing]];
 transferCheck[transferProject<>"/incoming and observed identity",transferValue["Polarization"]===FeynFacet`ReadProjectCard[transferRoot<>"/Projects/"<>transferProject]["Polarization"]];
 transferCheck[transferProject<>"/exact pole cancellation",transferValue["PoleCancellation"]==="Exact symbolic zero in every delta, plus and regular coefficient"],
 {transferProject,{"ppHX_UU_NNLO","ppHX_LL_NLO","ppHX_TT_NLO","ppHX_LL_SpinTransfer_NLO","ppHX_TT_SpinTransfer_NLO"}}];

(* A finite factorization-scale derivative is fixed by the LO splitting
   convolution. This also checks that every required mixing channel contributes. *)
transferScaleZero[expr_]:=transferZero[FeynFacetSolution`ExpandPositiveLogarithms[expr,transferValue["Domain"]]];
transferCompareDistributions[one_,two_,label_]:=Module[{orders},
 transferCheck[label<>"/delta",transferScaleZero[one["DeltaCoefficient"]-two["DeltaCoefficient"]]];
 orders=Union[Keys[one["PlusCoefficients"]],Keys[two["PlusCoefficients"]]];
 Do[transferCheck[label<>"/plus"<>ToString[k],transferScaleZero[Lookup[one["PlusCoefficients"],k,0]-Lookup[two["PlusCoefficients"],k,0]]],{k,orders}];
 transferCheck[label<>"/regular",transferScaleZero[one["RegularCoefficient"]-two["RegularCoefficient"]]]];
transferMap[fn_,distribution_]:=<|"DeltaCoefficient"->fn[distribution["DeltaCoefficient"]],
 "PlusCoefficients"->(fn /@ distribution["PlusCoefficients"]),"RegularCoefficient"->fn[distribution["RegularCoefficient"]]|>;
Do[
 transferPlan=FeynFacet`PlanNLOProject[transferRoot<>"/Projects/"<>transferProject<>"/NLO/qqp-qqp"];
 If[FailureQ[transferPlan],Print[transferPlan];Exit[1]];
 transferValue=transferRead[transferProject,"NLO"];
 transferSettings=transferPlan["CountertermCard"]["Counterterms"];
 Do[
  transferScale=transferSettings["FactorizationScalesSquared"][transferLeg];
  transferConvolutions=Table[
   transferBorn=transferRead[transferProject,"LO",transferRow["BornChannelName"]];
   transferConv=FeynFacet`ConvolveBornCollinearKernel[transferBorn,
    FeynFacet`LeadingSplittingKernel[transferRow["Daughter"],transferRow["Parent"],transferRow["Spin"],
     transferSettings["SplittingVariable"],transferSettings["KernelParameters"]],
    Join[transferSettings,<|"Leg"->transferLeg,"BornThroughOrder"->0|>]];
   If[FailureQ[transferConv],Print[transferConv];Exit[1]];
   transferMap[(-transferValue["Coupling"]/(2Pi)# /. transferBorn["DimensionalRegulator"]->0)&,transferConv],
   {transferRow,Select[transferPlan["CollinearChannels"],#["Leg"]===transferLeg&]}];
  transferExpected=<|"DeltaCoefficient"->Total[Lookup[transferConvolutions,"DeltaCoefficient"]],
   "PlusCoefficients"->Merge[Lookup[transferConvolutions,"PlusCoefficients"],Total],
   "RegularCoefficient"->Total[Lookup[transferConvolutions,"RegularCoefficient"]]|>;
  transferCompareDistributions[
   transferMap[Function[expr,transferScale D[expr,transferScale]],transferValue["Coefficients"][0]],
   transferExpected,transferProject<>"/d ln "<>ToString[transferScale,InputForm]],
  {transferLeg,{"IncomingA","IncomingB","Observed"}}],
 {transferProject,{"ppHX_UU_NNLO","ppHX_LL_NLO","ppHX_TT_NLO","ppHX_LL_SpinTransfer_NLO","ppHX_TT_SpinTransfer_NLO"}}];

transferOutput=transferRoot<>"/Projects/ppHX_UU_NNLO/NLO/qqp-qqp/Results/Validation/NLOSpinTransferChecks.wl";
Put[<|"Passed"->Length[transferRows]-transferFailures,"Failed"->transferFailures,"Checks"->transferRows,
 "Scope"->"Exact helicity conservation, polarized Born ratios, spin-angle correlation, leading soft logarithm, all three factorization-scale derivatives including mixing channels, integral-free output and polarization identity. No independent complete finite TT reference is claimed."|>,transferOutput];
Print["NLO_SPIN_TRANSFER_CHECKS ",Length[transferRows]-transferFailures,"/",Length[transferRows]];
Exit[If[transferFailures===0,0,1]];
