(* Universal massless scalar box, with at most one off-shell external leg.
   Haug and Wunder, JHEP 02 (2023) 177, arXiv:2211.14110v3,
   equations (37), (51), (60), (94) in the arXiv HTML numbering.
   The real hypergeometric combination has no auxiliary branch prescription.
   Only the signs of the original external invariants fix causal phases. *)
BeginPackage["FeynFacet`"];
EvaluateMasslessBoxIntegral::usage=
 "EvaluateMasslessBoxIntegral[{s,t,qSquared},epsilon,{low,high},conditions] returns explicit arbitrary-order Laurent coefficients of the unit-power massless box with at most one off-shell external leg, normalized by d^D ell/(i pi^(D/2)). Real physical invariant signs determine the causal phases. The on-shell qSquared=0 limit is taken before epsilon expansion.";
Begin["`Private`"];
boxFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"MasslessBox"];
boxSign[invariant_,conditions_]:=Which[
 TrueQ[FullSimplify[invariant>0,Assumptions->conditions]],1,
 TrueQ[FullSimplify[invariant<0,Assumptions->conditions]],-1,
 True,boxFail["NonzeroRealBoxInvariantSignRequired",<|"Invariant"->invariant|>]];
boxLogAbs[x_,conditions_]:=Log[FullSimplify[Abs[x],Assumptions->conditions]];
boxWeightedLog[coefficient_,x_,conditions_]:=If[coefficient===0,0,
 coefficient boxLogAbs[x,conditions]];
(* The n>=2 continuous single-valued combination is expanded into ordinary
   logarithms and Li_n. Positive arguments above one are inverted first.
   This avoids subtracting large imaginary terms numerically. *)
boxContinuousPolyLogBelowOne[n_Integer,x_,conditions_]:=
 Sum[(-1)^k/Factorial[k] If[k===0,1,boxLogAbs[x,conditions]^k]
  If[n-k===1,-Log[1-x],PolyLog[n-k,x]],{k,0,n-1}]+
 (-1)^(n-1)/Factorial[n] boxLogAbs[x,conditions]^(n-1)boxLogAbs[1-x,conditions];
boxContinuousPolyLog[n_Integer,x_,conditions_]:=Module[{below,above},
 If[TrueQ[FullSimplify[x==1,Assumptions->conditions]],Return[Zeta[n]]];
 If[TrueQ[FullSimplify[x<1,Assumptions->conditions]],
  Return[boxContinuousPolyLogBelowOne[n,x,conditions]]];
 above=(1+(-1)^n)Zeta[n]-(-1)^n boxContinuousPolyLogBelowOne[n,1/x,conditions&&x>1];
 If[TrueQ[FullSimplify[x>1,Assumptions->conditions]],Return[above]];
 below=boxContinuousPolyLogBelowOne[n,x,conditions&&x<1];
 Piecewise[{{Zeta[n],x==1},{above,x>1}},below]
];
boxFiniteHypergeometricCoefficient[n_Integer,x_,conditions_]:=Module[{value},
 If[TrueQ[FullSimplify[x==1,Assumptions->conditions]],Return[-Zeta[n]]];
 value=(-1)^n/Factorial[n]boxLogAbs[x,conditions]^(n-1)*
   (boxLogAbs[x,conditions]-boxLogAbs[1-x,conditions])-
    boxContinuousPolyLog[n,x,conditions];
 If[TrueQ[FullSimplify[x!=1,Assumptions->conditions]],value,
  Piecewise[{{-Zeta[n],x==1}},value]]
];
EvaluateMasslessBoxIntegral[{s_,t_,mass_},e_Symbol,{low_Integer,high_Integer},conditions_]:=
 Catch[Module[
 {third=Factor[mass-s-t],onShell,signs,args,phase,phaseMass,depth,core,coefficient,
  prefactor,series,coefficients,logarithmic,logs,values,weight,k,j},
 If[low>high||!FreeQ[{s,t,mass,conditions},e|_Real|_Failure|_Missing|$Failed|$Aborted],
  boxFail["ExactMasslessBoxLaurentRequestRequired"]];
 onShell=TrueQ[FullSimplify[mass==0,Assumptions->conditions]];
 signs={boxSign[s,conditions],boxSign[t,conditions]};
 If[!onShell,AppendTo[signs,boxSign[mass,conditions]]];
 If[!TrueQ[FullSimplify[third!=0&&Element[third,Reals],Assumptions->conditions]],
  boxFail["NonzeroThirdBoxInvariantRequired",<|"Invariant"->third|>]];
 depth=Max[0,high+2];args=Factor/@{-third/s,-third/t};
 If[!onShell,AppendTo[args,Factor[-third mass/(s t)]]];
 phase[sign_,order_Integer]:=If[order===0,1,If[sign===1,(I Pi)^order/Factorial[order],0]];
 phaseMass[order_]:=If[onShell,0,phase[signs[[3]],order]];
 logs=boxLogAbs[#,conditions]&/@args;
 values=Table[boxFiniteHypergeometricCoefficient[j,args[[i]],conditions],
   {i,Length[args]},{j,2,depth}];
 core=Table[
  coefficient=phase[signs[[2]],k]+phase[signs[[1]],k]-phaseMass[k];
  If[k>=1,
   (* Combine the three logarithmic poles before taking any diagonal limit:
      1-y12=(1-y1)(1-y2). The dangerous log has zero multiplier
      whenever its corresponding original invariants coincide. *)
   coefficient+=boxWeightedLog[phase[signs[[2]],k-1]-If[onShell&&k===1,1,phaseMass[k-1]],1-args[[1]],conditions]+
    boxWeightedLog[phase[signs[[1]],k-1]-If[onShell&&k===1,1,phaseMass[k-1]],1-args[[2]],conditions]-
    phase[signs[[2]],k-1]logs[[1]]-phase[signs[[1]],k-1]logs[[2]]+
    If[onShell,0,phaseMass[k-1]logs[[3]]]];
  If[k>=2,coefficient+=Sum[phase[signs[[2]],k-j]values[[1,j-1]]+
    phase[signs[[1]],k-j]values[[2,j-1]]-
    If[onShell,0,phaseMass[k-j]values[[3,j-1]]],{j,2,k}]];
  coefficient,{k,0,depth}];
 prefactor=2/(s t e^2)*Gamma[1+e]Gamma[1-e]^2/Gamma[1-2e]*
   Exp[e boxLogAbs[third/(s t),conditions]];
 coefficients=FeynFacet`Private`regulatorSeriesCoefficients[
  prefactor Sum[core[[k+1]]e^k,{k,0,depth}],e,{low,high}];
 If[FailureQ[coefficients],Throw[coefficients,"MasslessBox"]];
 If[!FreeQ[coefficients,_Integrate|_NIntegrate|_Series|_SeriesData|_SeriesCoefficient|
    _Hypergeometric2F1|Indeterminate|_DirectedInfinity|_Re|_Im],
  boxFail["ExplicitFiniteBoxCoefficientsRequired"]];
 <|"DataType"->"LaurentCoefficientVector","DimensionalRegulator"->e,"Dimension"->1,
  "Coefficients"->Association@KeyValueMap[{1,#1}->#2&,coefficients],
  "LaurentLowerBounds"->{-2},"StoredOrderRanges"->{{low,high}},
  "KnownThroughOrders"->{high},"ExactTails"->{False},
  "Invariants"->{s,t,mass},"Assumptions"->conditions,"LoopPrescription"->1,
  "Normalization"->"d^D ell/(i pi^(D/2))",
  "EvaluationMethod"->"MasslessOneOffShellBoxPolylogarithms",
  "KinematicLimitsTakenBeforeRegulatorExpansion"->If[onShell,{mass->0},{}],
  "EndpointPowers"->"This is an interior Laurent expansion. Endpoint distributions require the regulated kinematic limits."|>
],"MasslessBox"];
End[];EndPackage[];
