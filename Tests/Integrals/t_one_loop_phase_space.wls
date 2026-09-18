Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Module[{phase,prop,source,decomposition,family,master,result,pair,pairResult,moment,
 expected,prefactor,point,numerator,numeratorResult,dotted,values,rescaledCut},
 phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->phaseBubbleTest,
  "FinalMomenta"->{bp1,bp2,bp3},"TotalMomentum"->bq,"ExternalMomenta"->{bq},
  "KinematicRules"->{FeynCalc`SPD[bq]->bs},"Assumptions"->bs>0|>];
 prop[p_]:=FeynCalc`FCI[FeynCalc`SFAD[p]];
 source=prop[bl]prop[bl-bq];
 decomposition=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->source|>,phase,{bl}];
 family=First[decomposition["Families"]];master=First[decomposition["Targets"]];
 result=FeynFacet`EvaluateOneLoopPhaseSpaceBubble[family,master,be];
 FTTest`FTAssert["a unit-cut scalar bubble is evaluated to an exact regulator expression",
  AssociationQ[result]&&result["ExactInRegulator"]&&FreeQ[result["AnalyticExpression"],_FeynCalc`B0|_Integrate|_Series]];
 If[!AssociationQ[result],Print[InputForm[result]];Exit[1]];
 prefactor=I Pi^(2-be)Exp[I Pi be]bs^-be Gamma[be]Gamma[1-be]^2/Gamma[2-2be];
 expected=prefactor FeynFacet`MasslessPhaseSpaceVolume[3,bs,be];point={bs->2,be->-1/4};
 FTTest`FTAssert["the raw virtual measure and absolute phase-space normalization each occur once",
  Abs[N[(result["AnalyticExpression"]-expected)/.point,45]]<10^-38];
 pair=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->prop[bl]prop[bl-bp1-bp2]|>,phase,{bl}];
 pairResult=FeynFacet`EvaluateOneLoopPhaseSpaceBubble[First[pair["Families"]],First[pair["Targets"]],be];
 expected=expected Gamma[1-2be]Gamma[3-3be]/(Gamma[1-be]Gamma[3-4be]);
 FTTest`FTAssert["pair-invariant bubble powers give their independent Dirichlet moment",
  AssociationQ[pairResult]&&Abs[N[(pairResult["AnalyticExpression"]-expected)/.point,45]]<10^-38];
 numerator=FeynFacet`DecomposeCutLoopIntegrands[<|"Scalar"->FeynCalc`FCI[FeynCalc`SPD[bl,bq]]source|>,phase,{bl}];
 values=Association@Table[m->FeynFacet`EvaluateOneLoopPhaseSpaceBubble[First[numerator["Families"]],m,be],
  {m,numerator["Targets"]}];
 FTTest`FTAssert["full-dimensional virtual tensor numerators remain supported",AllTrue[Values[values],AssociationQ]];
 If[AllTrue[Values[values],AssociationQ],
  numeratorResult=Total[KeyValueMap[#2 values[#1]["AnalyticExpression"]&,numerator["CoefficientRules"]["Scalar"]]];
  FTTest`FTAssert["the vector bubble moment equals P squared over two times the scalar bubble",
   Abs[N[(numeratorResult-bs/2 result["AnalyticExpression"])/.point,45]]<10^-38]];
 dotted=ReplacePart[master,{2,First[family["CutIndices"]]}->2];
 FTTest`FTAssert["dotted particle cuts cannot use on-shell unit-cut moment formulas",
  FailureQ[FeynFacet`EvaluateOneLoopPhaseSpaceBubble[family,dotted,be]]];
 FTTest`FTAssert["particle labels alone cannot replace the actual conserved cut momenta",
  FailureQ[FeynFacet`EvaluateOneLoopPhaseSpaceBubble[
   Join[family,<|"FinalMomenta"->{bp1,bother,bp3}|>],master,be]]];
 rescaledCut=Join[family,<|"Topology"->ReplacePart[family["Topology"],{2,1}->prop[2bp1]],
   "Cuts"->ReplacePart[family["Cuts"],1->Join[First[family["Cuts"]],<|"Momentum"->2bp1|>]]|>];
 FTTest`FTAssert["a consistently rescaled cut cannot acquire the unit-cut phase-space normalization",
  AssociationQ[FeynFacet`CreateCutIntegralFamily[rescaledCut]]&&
  FailureQ[FeynFacet`EvaluateOneLoopPhaseSpaceBubble[rescaledCut,master,be]]];
 FTTest`FTAssert["a different spacetime dimension cannot acquire a four-dimensional-reference scalar value",
  MatchQ[FeynFacet`EvaluateOneLoopPhaseSpaceBubble[Join[family,<|"Dimension"->6-2be|>],master,be],
    Failure["FourMinusTwoEpsilonScalarDimensionRequired",_]]];
 FTTest`FTAssert["an extra phase-space acceptance condition cannot use inclusive Dirichlet moments",
  FailureQ[FeynFacet`EvaluateOneLoopPhaseSpaceBubble[
   Join[family,<|"AdditionalAcceptanceBoundaries"->FeynCalc`SPD[bp1,bq]>bs/4|>],master,be]]];
 moment=FeynFacet`IntegrateSimplexLaurentMonomials[1/(1-ba-bb),{ba,bb,bc},{1-be,1-be,1-be}];
 FTTest`FTAssert["affine simplex denominators are recognized modulo the simplex constraint",
  AssociationQ[moment]&&moment["Value"]===Gamma[1-be]^2 Gamma[-be]/Gamma[2-3be]];
 FTTest`FTAssert["non-monomial simplex kernels are left unsupported rather than assigned Gamma moments",
  FailureQ[FeynFacet`IntegrateSimplexLaurentMonomials[1/(ba+bb),{ba,bb,bc},{1-be,1-be,1-be}]]];
];
Print["ONE LOOP PHASE SPACE TEST COMPLETE"];FTTest`FTReport[];
