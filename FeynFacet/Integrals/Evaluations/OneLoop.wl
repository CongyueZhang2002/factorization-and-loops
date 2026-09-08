(* Analytic massless one-loop scalar integrals, detected from momentum
   geometry. Normalization is d^D l/(i pi^(D/2)) and its conjugate.
   Bubbles are exact Gamma expressions; the on-shell box is known through
   epsilon^0. The finite-order contract rejects deeper box requests. *)
FeynFacet`EvaluateOneLoopIntegral::usage="EvaluateOneLoopIntegral[definition,{low,high}] returns explicit Laurent coefficients for a massless one-loop bubble or on-shell scalar box, recognized without family names. Bubbles allow arbitrary positive powers and orders; unit-power boxes currently support high<=0. Causal phases follow the declared loop prescription and kinematic conditions.";
oneLoopCausalLog[value_,prescription_,conditions_]:=Which[
 TrueQ[FullSimplify[value>0,Assumptions->conditions]],Log[value]-I Pi prescription,
 TrueQ[FullSimplify[value<0,Assumptions->conditions]],Log[-value],
 True,epsOrderFail["OneLoopCausalDomainRequired",<|"Invariant"->value,"Conditions"->conditions|>]];
FeynFacet`EvaluateOneLoopIntegral[definition_Association,{low_Integer,high_Integer}]:=Catch[Module[
 {loops,ell,e,dim,prescription,powers,active,momenta,kin,conditions,lambda,shifts,
  normal,factor,masses,distances,nonzero,channel,aa,bb,expr,poly,coeffs,method,
  exact=True,ss,tt,ls,lt,rGamma,lower,nonzeroPairs},
 loops=Lookup[definition,"LoopMomenta",{}];e=Lookup[definition,"DimensionalRegulator",None];
 dim=Lookup[definition,"Dimension",None];powers=Lookup[definition,"PropagatorPowers",{}];
 If[Length[loops]=!=1||Lookup[definition,"CutIndices",None]=!={}||low>high||
  !MatchQ[e,_Symbol]||!TrueQ[Expand[dim-(4-2e)]===0]||!VectorQ[powers,IntegerQ]||AnyTrue[powers,#<0&],
  epsOrderFail["ScalarOneLoopIntegralRequired"]];
 ell=First[loops];prescription=Lookup[definition,"Prescription",{}];
 If[!MatchQ[prescription,{1}|{-1}],epsOrderFail["OneLoopPrescriptionRequired"]];prescription=First[prescription];
 active=Select[Range[Length[powers]],powers[[#]]>0&];
 If[!MemberQ[{2,4},Length[active]]||!AllTrue[definition["PropagatorTypes"][[active]],#==="QuadraticLorentzian"&],
  epsOrderFail["OneLoopAnalyticGeometryUnsupported"]];
 momenta=definition["PropagatorMomenta"][[active]];kin=definition["KinematicRules"];
 conditions=Lookup[definition,"KinematicConditions",True];
 lambda=Coefficient[#,ell]& /@ momenta;
 If[!AllTrue[lambda,MatchQ[#,_Integer|_Rational]&&#=!=0&],epsOrderFail["LinearOneLoopRoutingRequired"]];
 shifts=MapThread[Expand[#1/#2-ell]&,{momenta,lambda}];
 If[!FreeQ[shifts,ell],epsOrderFail["LinearOneLoopRoutingRequired"]];
 masses=MapThread[Expand[(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#1]]]/.kin)-#2]&, 
   {momenta,definition["InversePropagators"][[active]]}];
 If[!AllTrue[masses,epsOrderZero],epsOrderFail["MasslessOneLoopPropagatorsRequired"]];
 normal=Simplify[definition["MeasurePrefactor"]prescription I Pi^(dim/2)];
 factor=definition["MasterIntegralPrefactor"]normal (Times@@MapThread[#1^(-2#2)&,{lambda,powers[[active]]}]);
 distances=Flatten[Table[FullSimplify[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[shifts[[i]]-shifts[[j]]]]]/.kin,Assumptions->conditions],
   {i,Length[shifts]},{j,i+1,Length[shifts]}]];
 If[Length[active]===2,
  channel=First[distances];{aa,bb}=powers[[active]];method="MasslessBubbleGammaFormula";
  expr=If[epsOrderZero[channel],0,
   factor (-1)^(aa+bb) Exp[(dim/2-aa-bb)oneLoopCausalLog[channel,prescription,conditions]]
    Gamma[aa+bb-dim/2]Gamma[dim/2-aa]Gamma[dim/2-bb]/(Gamma[aa]Gamma[bb]Gamma[dim-aa-bb])],
  If[!AllTrue[powers[[active]],#===1&]||high>0,epsOrderFail["OnShellBoxKnownOnlyThroughFiniteOrder"]];
  nonzero=Select[distances,!epsOrderZero[#]&];
  nonzeroPairs=Pick[Subsets[Range[Length[shifts]],{2}],(!epsOrderZero[#]& /@ distances),True];
  If[Length[nonzero]=!=2||Length[Union[Flatten[nonzeroPairs]]]=!=4,epsOrderFail["FourMasslessExternalLegsRequired"]];
  {ss,tt}=nonzero;ls=oneLoopCausalLog[ss,prescription,conditions];lt=oneLoopCausalLog[tt,prescription,conditions];
  rGamma=Gamma[1+e]Gamma[1-e]^2/Gamma[1-2e];
  expr=factor 2rGamma/(ss tt)((Exp[-e ls]+Exp[-e lt])/e^2-(ls-lt)^2/2-Pi^2/2);
  exact=False;method="MasslessOnShellBoxLaurentFormula"];
 poly=Normal[Series[expr,{e,0,high}]];
 If[!FreeQ[poly,_SeriesData|_Series|_SeriesCoefficient|_Integrate|_Failure|Indeterminate|_DirectedInfinity],epsOrderFail["ExplicitOneLoopLaurentCoefficientsRequired"]];
 lower=Min[low,If[Length[active]===4,-2,-1]];
 coeffs=Association@Table[j->Coefficient[Expand[e^-lower poly],e,j-lower],{j,lower,high}];
 <|"MasterIntegral"->definition["MasterIntegral"],"DimensionalRegulator"->e,
  "LaurentLowerBound"->lower,"KnownThroughOrder"->high,"RequestedRange"->{low,high},
  "Coefficients"->coeffs,"ExactInEpsilon"->TrueQ[expr===0],
  "AnalyticExpression"->If[exact,expr,Missing["FiniteLaurentExpression"]],
  "EvaluationMethod"->method,"LoopPrescription"->prescription,
  "Normalization"->"d^D l/(i pi^(D/2)), conjugated for negative prescription"|>
 ],"EpsilonOrders"];
