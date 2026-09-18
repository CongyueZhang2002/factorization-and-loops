(* Independent defining-integral checks for arbitrary invariant densities.
   Test kernels are monomials, so expected integrals are elementary. *)
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
icRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[icRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[icRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
icRow[d_,p_,r_]:=<|"DeltaCoefficient"->d,"PlusCoefficients"->p,"RegularCoefficient"->r|>;
icZero=icRow[0,<||>,0];
icMetadata=<|"Order"->"NLO","Contribution"->"BareSource","RenormalizationStage"->"Bare",
 "Scale"->icS,"Variables"->{icV,icW},"Variable"->icW,"DimensionalRegulator"->icE,
 "DimensionalPrefactor"->1,"CouplingPower"->1|>;
icSource[rows_]:=FeynFacet`CreatePartonicResult[rows,icMetadata];
icBase=<|"Spin"->"U","Variable"->icXi,"DimensionalRegulator"->icE,
 "KernelParameters"-><|"CA"->3,"CF"->4/3,"TR"->1/2,"FlavorCount"->5|>,
 "ScaleLog"->0,"PoleNormalization"->1,"Operation"->"CollinearSubtraction"|>;
icDistribution[role_,n_]:=If[role==="FF",FeynFacet`FFCountertermDistribution,
 FeynFacet`PDFCountertermDistribution][{"q","u"},{"q","u"},Join[icBase,<|"PerturbativeOrder"->n|>]];
(* Replace the scalar input only: this tests the convolution as a linear
   operator, independently of a particular QCD splitting polynomial. *)
icKernel[role_,f_]:=Join[icDistribution[role,1],<|"DeltaCoefficient"->0,
 "PlusCoefficients"-><||>,"RegularCoefficient"->f/icE,"LaurentLowerBound"->-1|>];
icRequest[leg_,range_]:=<|"Convolution"->"InvariantSingleInclusive","Leg"->leg,
 "Scale"->icS,"Variables"->{icV,icW},"PerturbativeParameter"->1,"EpsilonRange"->range|>;
icConditions=icS>0&&0<icV<1&&0<icW<1;
icEqual[a_,b_]:=TrueQ[Cancel[Together[
 FeynFacet`ExpandPositiveLogarithms[a-b,icConditions]]]==0];
icMixed=icSource[<|-1->icRow[1,<|0->2|>,icW],
 0->icRow[icV,<|0->3,1->5|>,icV+icW^2]|>];
Do[
 icRole=If[icLeg==="Observed","FF","PDF"];
 icIdentity=FeynFacet`ApplyCountertermDistribution[icMixed,icDistribution[icRole,0],icRequest[icLeg,{-1,0}]];
 If[!AssociationQ[icIdentity],Print["IDENTITY FAILURE ",icLeg," ",System`Short[icIdentity,8]]];
 FTTest`FTAssert[icLeg<>" identity preserves a non-Born pole source and every endpoint component",
  AssociationQ[icIdentity]&&icIdentity["Coefficients"]===icMixed["Coefficients"]],
 {icLeg,{"IncomingA","IncomingB","Observed"}}];

icConstant=icSource[<|0->icRow[0,<||>,1],1->icZero|>];
icLowerB=(1-icV)/(1-icV icW);icLowerF=1-icV+icV icW;
Do[
 icRole=If[icLeg==="Observed","FF","PDF"];
 icResult=FeynFacet`ApplyCountertermDistribution[icConstant,icKernel[icRole,1],icRequest[icLeg,{-1,0}]];
 If[!AssociationQ[icResult],Print["CONVOLUTION FAILURE ",icLeg," ",System`Short[icResult,8]]];
 icExpected=Switch[icLeg,"IncomingA",1-icW,"IncomingB",1-icLowerB,"Observed",1/icLowerF-1];
 icExpectedFinite=If[icLeg==="Observed",2((Log[icLowerF]+1)/icLowerF-1),0];
 FTTest`FTAssert[icLeg<>" regular-density integral has the physical lower limit and dimensional measure",
  AssociationQ[icResult]&&icEqual[icResult["Coefficients"][-1]["RegularCoefficient"],icExpected]&&
  icEqual[icResult["Coefficients"][0]["RegularCoefficient"],icExpectedFinite]&&
  icResult["Coefficients"][-1]["DeltaCoefficient"]===0&&
  AllTrue[Values[icResult["Coefficients"][-1]["PlusCoefficients"]],#===0&]],
 {icLeg,{"IncomingA","IncomingB","Observed"}}];
icFFMonomial=FeynFacet`ApplyCountertermDistribution[icConstant,icKernel["FF",icXi],icRequest["Observed",{-1,0}]];
FTTest`FTAssert["a nonconstant FF kernel retains the epsilon-dependent Jacobian integral",
 AssociationQ[icFFMonomial]&&icEqual[icFFMonomial["Coefficients"][-1]["RegularCoefficient"],-Log[icLowerF]]&&
 icEqual[icFFMonomial["Coefficients"][0]["RegularCoefficient"],-Log[icLowerF]^2]];

(* Transform the input plus distribution to y=wPrime. Its action is
   integral_w^1 (g[y]-g[1])/(1-y) dy + g[1] Log[1-w]. *)
icPlusSource=icSource[<|0->icRow[0,<|0->1|>,0]|>];
icKinematic=icV icW;
Do[
 icRole=If[icLeg==="Observed","FF","PDF"];
 icResult=FeynFacet`ApplyCountertermDistribution[icPlusSource,icKernel[icRole,1],icRequest[icLeg,{-1,-1}]];
 If[!AssociationQ[icResult],Print["CONVOLUTION FAILURE ",icLeg," ",System`Short[icResult,8]]];
 icExpected=Switch[icLeg,
 "IncomingA",1-icW-icW Log[icW]+icW Log[1-icW],
 "IncomingB",(1-icV)icKinematic/(1-icKinematic)^2*
  (Log[1-icKinematic]-Log[1-icV]-Log[icW]-1+(1-icKinematic)/((1-icV)icW)+Log[1-icW]),
 "Observed",icKinematic/icLowerF^2*(Log[icLowerF]-Log[icW]-1+icLowerF/icW+Log[1-icW])];
 FTTest`FTAssert[icLeg<>" convolves a non-Born plus distribution with its exact endpoint subtraction",
  AssociationQ[icResult]&&icEqual[icResult["Coefficients"][-1]["RegularCoefficient"],icExpected]&&
  icResult["Coefficients"][-1]["DeltaCoefficient"]===0&&
  AllTrue[Values[icResult["Coefficients"][-1]["PlusCoefficients"]],#===0&]],
 {icLeg,{"IncomingA","IncomingB","Observed"}}];

icBorn=Join[icSource[<|0->icRow[1/(icS icV),<||>,0],1->icZero|>],<|"Order"->"LO","CouplingPower"->0|>];
Do[
 icRole=If[icLeg==="Observed","FF","PDF"];
 icResult=FeynFacet`ApplyCountertermDistribution[icBorn,icKernel[icRole,1],icRequest[icLeg,{-1,0}]];
 If[!AssociationQ[icResult],Print["CONVOLUTION FAILURE ",icLeg," ",System`Short[icResult,8]]];
 icExpected=Switch[icLeg,"IncomingA",1/(icS icV),"IncomingB",1/(icS(1-icV icW)),"Observed",1/(icS icLowerF)];
 icExpectedFinite=If[icLeg==="Observed",2Log[icLowerF]/(icS icLowerF),0];
 FTTest`FTAssert[icLeg<>" Born specialization agrees with the independently integrated delta constraint",
  AssociationQ[icResult]&&icEqual[icResult["Coefficients"][-1]["RegularCoefficient"],icExpected]&&
  icEqual[icResult["Coefficients"][0]["RegularCoefficient"],icExpectedFinite]],
 {icLeg,{"IncomingA","IncomingB","Observed"}}];
icShort=icSource[<|0->icRow[0,<||>,1]|>];
FTTest`FTAssert["the general invariant insertion rejects an uncomputed positive source coefficient",
 FailureQ[FeynFacet`ApplyCountertermDistribution[icShort,icKernel["PDF",1],icRequest["IncomingA",{-1,0}]]]];

(* Three genuine physical legs share the same invariant density in v,w.
   The leading order-two pole isolates one product per distinct leg pair. *)
icTarget=ConstantArray[{"q","u"},3];
icLegNames={"IncomingA","IncomingB","Observed"};icLambdas={icLambdaA,icLambdaB,icLambdaF};
icLegs=Map[Function[leg,<|"Variable"->icXi,
 "ConvolutionRequest"->KeyDrop[icRequest[leg,{-2,-2}],{"PerturbativeParameter","EpsilonRange"}]|>],icLegNames];
icTransition[j_,src_,dst_,n_]:=Join[icKernel[If[j===3,"FF","PDF"],
 If[src===dst&&n===1,icLambdas[[j]],0]],<|"PerturbativeOrder"->n,
 "LaurentLowerBound"->If[src===dst&&n===1,-1,Infinity]|>];
icPlan=FeynFacet`PlanPartonicRenormalization[icTarget,<|"PerturbativeOrder"->2,
 "ThroughOrder"->-2,"DimensionalRegulator"->icE,"PerturbativeParameter"->icA,"BornCouplingPower"->0,
 "Legs"->icLegs,"FlavorClasses"-><|"Quarks"-><|"Members"->{"u"},"Multiplicity"->1|>|>,
 "TransitionKernel"->icTransition,"CouplingRenormalization"-><|1->0,2->0|>|>];
FTTest`FTAssert["the common order-two plan retains each physical leg's convolution request",
 AssociationQ[icPlan]&&Length[icPlan["Terms"]]>0&&
 AllTrue[Flatten[Lookup[icPlan["Terms"],"Kernels"]],
  Lookup[Lookup[#,"ConvolutionRequest",<||>],"Convolution",None]==="InvariantSingleInclusive"&]];
icThreeSource[r_,sp_,classes_,hi_]:=If[r===0&&sp===icTarget,
 FeynFacet`CreatePartonicResult[<|0->icRow[1/(icS icV),<||>,0]|>,
  Join[icMetadata,<|"Order"->"LO","CouplingPower"->0|>]],0];
icThree=FeynFacet`ApplyPartonicRenormalization[icPlan,icThreeSource,
 Join[KeyTake[icMetadata,{"Scale","Variables","DimensionalRegulator","DimensionalPrefactor"}],
  <|"Order"->"NNLO","Contribution"->"ThreeLegCounterterm","CouplingPower"->2|>]];
If[!AssociationQ[icThree],Print["THREE LEG FAILURE ",System`Short[icThree,8]]];
icPairAB=(Log[1-icV icW]-Log[1-icV]-Log[icW])/icS;
icPairAF=(Log[icLowerF]-Log[icW])/(icS(1-icV));
icPairBF=(Log[1-icV icW]-Log[1-icV]+Log[icLowerF])/(icS icV icW);
icThreeExpected=icA^2(icLambdaA icLambdaB icPairAB+icLambdaA icLambdaF icPairAF+icLambdaB icLambdaF icPairBF);
FTTest`FTAssert["all three physical leg pairs appear once with their defining invariant integrals",
 AssociationQ[icThree]&&icThree["EpsilonRange"]==={-2,-2}&&
 icEqual[icThree["Coefficients"][-2]["RegularCoefficient"],icThreeExpected]];


(* Kernel endpoint subtractions, including the nonlinear physical limits. *)
icD0Kernel[role_]:=Join[icKernel[role,0],<|"PlusCoefficients"-><|0->1/icE|>,"LaurentLowerBound"->-1|>];
Do[
 icRole=If[icLeg==="Observed","FF","PDF"];
 icResult=FeynFacet`ApplyCountertermDistribution[icConstant,icD0Kernel[icRole],icRequest[icLeg,{-1,-1}]];
 icExpected=Switch[icLeg,"IncomingA",Log[1-icW],
 "IncomingB",Log[icV]+Log[1-icW]-Log[1-icV icW],
 "Observed",1/icLowerF-1-Log[icLowerF]+Log[icV]+Log[1-icW]];
 FTTest`FTAssert[icLeg<>" plus kernel has the complete subtraction on a regular density",
  AssociationQ[icResult]&&icEqual[icResult["Coefficients"][-1]["RegularCoefficient"],icExpected]],
 {icLeg,icLegNames}];
icBornPlus=<||>;
Do[
 icRole=If[icLeg==="Observed","FF","PDF"];
 icResult=FeynFacet`ApplyCountertermDistribution[icBorn,icD0Kernel[icRole],icRequest[icLeg,{-1,-1}]];
 AssociateTo[icBornPlus,icLeg->icResult];
 icExpectedDelta=Switch[icLeg,"IncomingA",0,"IncomingB",(Log[icV]-Log[1-icV])/(icS icV),"Observed",Log[icV]/(icS icV)];
 icExpectedRegular=If[icLeg==="Observed",1/(icS icLowerF),0];
 FTTest`FTAssert[icLeg<>" plus kernel on Born retains the endpoint constant from its physical map",
  AssociationQ[icResult]&&icEqual[icResult["Coefficients"][-1]["DeltaCoefficient"],icExpectedDelta]&&
  icEqual[Lookup[icResult["Coefficients"][-1]["PlusCoefficients"],0,0],1/(icS icV)]&&
  icEqual[icResult["Coefficients"][-1]["RegularCoefficient"],icExpectedRegular]],
 {icLeg,icLegNames}];

icScaledPlus=icSource[<|0->icRow[0,<|0->1/(icS icV)|>,0]|>];
icC00=FeynFacet`ApplyCountertermDistribution[icScaledPlus,icD0Kernel["PDF"],icRequest["IncomingA",{-1,-1}]];
FTTest`FTAssert["the incoming-A double-plus product has the independent standard Mellin endpoint constants",
 AssociationQ[icC00]&&icEqual[icC00["Coefficients"][-1]["DeltaCoefficient"],-Pi^2/(6icS icV)]&&
 icEqual[Lookup[icC00["Coefficients"][-1]["PlusCoefficients"],1,0],2/(icS icV)]&&
 icEqual[Lookup[icC00["Coefficients"][-1]["PlusCoefficients"],0,0],0]&&
 icEqual[icC00["Coefficients"][-1]["RegularCoefficient"],-Log[icW]/(icS icV(1-icW))]];

(* Independent distribution moments integrate w first in the original
   physical action. For m>0 the source D0 moment is -H_m. The remaining
   single xi integral fixes the complete answer, including endpoint deltas. *)
icMoment[row_,m_,rules_]:=Module[{pointRow=row/.rules,moment},
 moment=pointRow["DeltaCoefficient"]+Total[KeyValueMap[
  #2 Integrate[(icW^m-1)Log[1-icW]^#1/(1-icW),{icW,0,1}]&,
  pointRow["PlusCoefficients"]]];
 moment+NIntegrate[Evaluate[icW^m pointRow["RegularCoefficient"]],{icW,0,1},
  WorkingPrecision->35,AccuracyGoal->23,PrecisionGoal->23,MaxRecursion->20]];
Do[
 icRole=If[icLeg==="Observed","FF","PDF"];
 icResult=FeynFacet`ApplyCountertermDistribution[icScaledPlus,icD0Kernel[icRole],icRequest[icLeg,{-1,-1}]];
 icMomentExpected=If[icLeg==="IncomingB",(1-Log[icV]+Log[1-icV])/(icS icV),
  -(icV Log[icV]+(1-icV)Log[1-icV])/(icS icV^2)];
 icMoments=If[AssociationQ[icResult],TimeConstrained[
  {icMoment[icResult["Coefficients"][-1],0,{icS->2,icV->1/3}],
   icMoment[icResult["Coefficients"][-1],1,{icS->2,icV->1/3}]},60,$Aborted],$Failed];
 FTTest`FTAssert[icLeg<>" double-plus distribution agrees with independent zeroth and first physical moments",
  MatchQ[icMoments,{_?NumberQ,_?NumberQ}]&&Abs[icMoments[[1]]]<10^-18&&
  Abs[icMoments[[2]]-N[icMomentExpected/.{icS->2,icV->1/3},35]]<10^-18],
 {icLeg,{"IncomingB","Observed"}}];

icRowValues[row_]:=Join[{row["DeltaCoefficient"],row["RegularCoefficient"]},
 Table[Lookup[row["PlusCoefficients"],i,0],{i,0,2}]];
Do[
 icLeft=FeynFacet`ApplyCountertermDistribution[icBornPlus[pair[[1]]],
  icD0Kernel[If[pair[[2]]==="Observed","FF","PDF"]],icRequest[pair[[2]],{-2,-2}]];
 icRight=FeynFacet`ApplyCountertermDistribution[icBornPlus[pair[[2]]],
  icD0Kernel[If[pair[[1]]==="Observed","FF","PDF"]],icRequest[pair[[1]],{-2,-2}]];
 icCommutator=If[AssociationQ[icLeft]&&AssociationQ[icRight],
  icRowValues[icLeft["Coefficients"][-2]]-icRowValues[icRight["Coefficients"][-2]],{$Failed}];
 icCommutatorSamples=Flatten[Table[N[icCommutator/.{icS->2,icV->point[[1]],icW->point[[2]]},35],
  {point,{{1/3,2/5},{2/3,1/4},{3/7,4/9}}}]];
 FTTest`FTAssert[StringRiffle[pair," and "]<>" plus insertions commute on every endpoint component",
  AllTrue[icCommutatorSamples,NumberQ]&&Max[Abs[icCommutatorSamples]]<10^-20],
 {pair,Subsets[icLegNames,{2}]}];

icVector=FeynFacet`CreatePartonicResult[<|-1->icRow[{2,3},<|0->{4,5}|>,{icW,icV}],
 0->icRow[{7,11},<|1->{13,17}|>,{icW^2,icV icW}]|>,
 Join[icMetadata,<|"StructureFunctions"->{"First","Second"}|>]];
icVectorIdentity=FeynFacet`ApplyCountertermDistribution[icVector,icDistribution["FF",0],icRequest["Observed",{-1,0}]];
FTTest`FTAssert["a structure-function vector preserves its metadata, negative epsilon keys and identity components",
 AssociationQ[icVectorIdentity]&&icVectorIdentity["StructureFunctions"]==={"First","Second"}&&
 icVectorIdentity["Coefficients"]===icVector["Coefficients"]];
icVectorRegular=FeynFacet`CreatePartonicResult[<|0->icRow[{0,0},<||>,{1,icV}],
 1->icRow[{0,0},<||>,{0,0}]|>,Join[icMetadata,<|"StructureFunctions"->{"First","Second"}|>]];
icVectorApplied=FeynFacet`ApplyCountertermDistribution[icVectorRegular,icKernel["FF",1],icRequest["Observed",{-1,0}]];
icVectorPole={1/icLowerF-1,1/icLowerF-1-(1-icV)(1/icLowerF^2-1)/2};
icVectorFinite={2((Log[icLowerF]+1)/icLowerF-1),
 2((Log[icLowerF]+1)/icLowerF-1)-(1-icV)((Log[icLowerF]+1/2)/icLowerF^2-1/2)};
FTTest`FTAssert["the FF measure acts independently on both structure functions through the finite coefficient",
 AssociationQ[icVectorApplied]&&And@@MapThread[icEqual,
  {icVectorApplied["Coefficients"][-1]["RegularCoefficient"],icVectorPole}]&&
 And@@MapThread[icEqual,{icVectorApplied["Coefficients"][0]["RegularCoefficient"],icVectorFinite}]];

Print["INVARIANT CONVOLUTION TEST COMPLETE"];FTTest`FTReport[];
