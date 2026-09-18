(* Independent physical defining-integral check for IncomingA at order
   epsilon^-2. The real source epsilon^-1 has delta, D0 and regular terms.
   No production invariant or Mellin convolution helper is used below. *)
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
cnRoot=DirectoryName[ExpandFileName[$InputFileName],3];Get[cnRoot<>"/Tests/TestKit.wl"];
Block[{Print},Get[cnRoot<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[cnRoot<>"/FeynFacet/Solution.m"];
cnBase=cnRoot<>"/Projects/ppHX_UU/Results/NLO/qqp-qqp/Validation/SourceOrders";
cnArguments=Rest[$ScriptCommandLine];cnRun=If[cnArguments==={},"FinalCollection",First[cnArguments]];
cnOutput=cnBase<>"/RealCountertermConvolution/"<>cnRun;
cnSource=FeynFacet`ReadPartonicResult[cnBase<>"/RetainedInputAnalytic/RealResult.wl"];
cnResult=FeynFacet`ReadPartonicResult[cnOutput<>"/Result.wl"];
If[!AssociationQ[cnSource]||!AssociationQ[cnResult],Print["EXPLICIT PHYSICAL CONVOLUTION REQUIRED"];Exit[2]];
cnRow=cnSource["Coefficients"][-1];
FTTest`FTAssert["the numerical check uses a real source with both D0 and regular terms",
 Lookup[cnRow["PlusCoefficients"],0,0]=!=0&&cnRow["RegularCoefficient"]=!=0&&
 AllTrue[Values[KeyDrop[cnRow["PlusCoefficients"],0]],#===0&]];
cnS=cnSource["Scale"];{cnV,cnW}=cnSource["Variables"];
cnW0=2/5;cnCF=4/3;cnAlpha=1/(2Pi);
cnPoint={cnV->1/3,cnW->cnW0,cnS->5,Global`muR2->7,
 FeynCalc`CA->3,FeynCalc`CF->cnCF,Global`nU->2,Global`nD->3,FeynFacet`\[Alpha]s->1};
(* For d or c multiplying delta(1-y) or D0(y), the Mellin weight is
   x d(xs,v) or x c(xs,v). Its endpoint is the coefficient at x=1. *)
cnDeltaWeight=cnX (cnRow["DeltaCoefficient"]/.cnS->cnS cnX)/.cnPoint;
cnPlusWeight=cnX (cnRow["PlusCoefficients"][0]/.cnS->cnS cnX)/.cnPoint;
cnRegularBody=cnRow["RegularCoefficient"]/.{cnS->cnS cnX,cnW->cnW/cnX}/.cnPoint;
cnD1=cnDeltaWeight/.cnX->1;cnB1=cnPlusWeight/.cnX->1;cnR1=cnRegularBody/.cnX->1;
cnDw=cnDeltaWeight/.cnX->cnW0;
(* Pqq=CF(3/2 delta+2 D0-1-x). Multiplication by the smooth B(x)
   moves B(x)-B(1) into the regular part before the source subtraction. *)
cnRegularKernel=-cnCF(1+cnX)cnPlusWeight+2cnCF(cnPlusWeight-cnB1)/(1-cnX);
cnRegularKernelAtLower=cnRegularKernel/.cnX->cnW0;
cnSourcePlusIntegrand=(cnRegularKernel-cnW0 cnRegularKernelAtLower/cnX)/(cnX-cnW0);
cnSourceRegularIntegrand=-cnCF(1+cnX)cnRegularBody+
 2cnCF(cnRegularBody-cnR1)/(1-cnX);
(* The regular part of D0 convolution D0 is -Log[w]/(1-w), obtained
   by expanding the two regulated endpoint powers before removing the
   regulators. The other terms below are their explicit defining subtractions. *)
cnAlgebraic=-cnCF(1+cnW0)cnDw+2cnCF(cnDw-cnD1)/(1-cnW0)-
 2cnCF cnB1 Log[cnW0]/(1-cnW0)+cnRegularKernelAtLower Log[1-cnW0]+
 3cnCF cnR1/2+2cnCF cnR1 Log[1-cnW0];
{cnIntegrationSeconds,cnIntegrals}=AbsoluteTiming[Table[
 NIntegrate[Evaluate[cnIntegrand],{cnX,cnW0,1},WorkingPrecision->45,
  AccuracyGoal->30,PrecisionGoal->30,Method->{"GlobalAdaptive","SymbolicProcessing"->0}],
 {cnIntegrand,{cnSourcePlusIntegrand,cnSourceRegularIntegrand}}]];
cnExpected=N[cnAlpha(cnAlgebraic+Total[cnIntegrals]),35];
cnActualExpression=FeynFacetSolution`ExpandPositiveLogarithms[
 cnResult["Coefficients"][-2]["RegularCoefficient"]/.cnPoint,True];
{cnEvaluationSeconds,cnActual}=AbsoluteTiming[
 FeynFacetSolution`EvaluateGPLExpression[cnActualExpression,{},"WorkingPrecision"->45]];
cnPassed=NumberQ[cnExpected]&&NumberQ[cnActual]&&Abs[cnActual-cnExpected]<10^-25;
FTTest`FTAssert["the non-Born regular coefficient agrees with the independently subtracted physical integral",cnPassed];
cnSizes=Map[Function[value,<|"Leaves"->LeafCount[value],
 "GPLAtoms"->Length[DeleteDuplicates[Cases[value,_FeynFacetSolution`G,Infinity]]]|>],
 FeynFacet`PartonicScalarCoefficientRules[cnResult]];
cnReport=<|"SourceOrder"->-1,"CountertermOrder"->-2,"DistributionCoefficient"->"Regular",
 "Source"->cnBase<>"/RetainedInputAnalytic/RealResult.wl","Result"->cnOutput<>"/Result.wl",
 "Point"->cnPoint,"Expected"->cnExpected,"Actual"->cnActual,
 "Residual"->cnActual-cnExpected,"Passed"->cnPassed,
 "SubtractedIntegrands"->{cnSourcePlusIntegrand,cnSourceRegularIntegrand},
 "AlgebraicEndpointTerms"->cnAlgebraic,"IntegrationValues"->cnIntegrals,
 "IntegrationSeconds"->cnIntegrationSeconds,"EvaluationSeconds"->cnEvaluationSeconds,
 "FinalScalarSizes"->cnSizes,
 "Method"->"Physical x rescaling with explicit source and kernel endpoint subtractions; universal D0-D0 regular identity; independent45-digit quadrature."|>;
FeynFacet`FamilyArtifactWrite[cnReport,cnOutput<>"/SubtractedIntegralComparison.wl"];
Print["SUBTRACTED INTEGRAL VALUES ",(If[NumberQ[#],#,Head[#]]&/@{cnExpected,cnActual}),
 " RESIDUAL ",If[NumberQ[cnExpected]&&NumberQ[cnActual],cnActual-cnExpected,"NotNumeric"]];
Print["MAXIMUM FINAL SCALAR LEAVES ",Max[Lookup[Values[cnSizes],"Leaves"]],
 " GPL ATOMS ",Max[Lookup[Values[cnSizes],"GPLAtoms"]]];
FTTest`FTReport[];
