(* Physical unobserved gluon states, without PDF/FF normalization factors.
   A complete on-shell gauge amplitude may replace at most one such sum by
   -g_D without an explicit BRST state completion. Current tensor indices
   remain open; no componentwise real part is taken here. *)
BeginPackage["FeynFacet`"];
GluonPolarizationProjector::usage="GluonPolarizationProjector[k,n,{mu,nu}] gives the full D-dimensional physical massless polarization sum with reference n, without a spin average. Its domain requires k.n != 0.";
SumUnobservedGluonPolarizations::usage="SumUnobservedGluonPolarizations[expression,states] contracts each declared unobserved gluon. States have Momentum and Sum (Physical or Covariant); Physical also requires ReferenceMomentum. At most one covariant sum is admitted without explicit ghost state completion. All other external gluons must have physical PDF/FF or unobserved-state projectors.";
Begin["`Private`"];
GluonPolarizationProjector[k_,reference_,{mu_Symbol,nu_Symbol}]:=
 -FeynCalc`MTD[mu,nu]+
 (FeynCalc`FVD[k,mu]FeynCalc`FVD[reference,nu]+FeynCalc`FVD[reference,mu]FeynCalc`FVD[k,nu])/FeynCalc`SPD[k,reference]-
 FeynCalc`SPD[reference]FeynCalc`FVD[k,mu]FeynCalc`FVD[k,nu]/FeynCalc`SPD[k,reference]^2;

SumUnobservedGluonPolarizations[expression_,states_List]:=Catch[Module[
 {momenta,result,k,kind,reference,mu,nu,plus,minus,spin},
 If[!AllTrue[states,AssociationQ]||!AllTrue[states,ContainsAll[Keys[#],{"Momentum","Sum"}]&],
  Throw[Failure["UnobservedGluonStatesRequired",<||>],"GluonStates"]];
 momenta=If[states==={},{},Lookup[states,"Momentum"]];
 If[!MatchQ[momenta,{_Symbol...}]||!DuplicateFreeQ[momenta],
  Throw[Failure["DistinctUnobservedGluonMomentaRequired",<||>],"GluonStates"]];
 If[!AllTrue[states,MemberQ[{"Physical","Covariant"},#["Sum"]]&],
  Throw[Failure["PhysicalOrCovariantGluonSumRequired",<||>],"GluonStates"]];
 If[Count[Lookup[states,"Sum",{}],"Covariant"]>1,
  Throw[Failure["MultipleCovariantGluonsRequireGhostCompletion",<||>],"GluonStates"]];
 result=FeynCalc`FCI[expression];
 Do[
  k=state["Momentum"];kind=state["Sum"];
  reference=Lookup[state,"ReferenceMomentum",None];
  If[kind==="Physical"&&(!MatchQ[reference,_Symbol|_Plus|_Times]||reference===0||
    !FreeQ[reference,_Real|_Failure|_Missing|$Failed]||TrueQ[Expand[reference-k]===0]),
   Throw[Failure["NoncollinearGluonReferenceRequired",<|"Momentum"->k|>],"GluonStates"]];
  If[result===0,Continue[]];
  plus=FeynCalc`Momentum[FeynCalc`Polarization[k,I],D];
  minus=FeynCalc`Momentum[FeynCalc`Polarization[k,-I],D];
  If[polarizationDegree[result,plus]=!=1||polarizationDegree[result,minus]=!=1,
   Throw[Failure["OnePolarizationPerAmplitudeSideRequired",<|"Momentum"->k|>],"GluonStates"]];
  If[kind==="Covariant",
   result=Quiet[FeynCalc`DoPolarizationSums[result,k,0],FeynCalc`PolarizationSum::notmassless],
   mu=Unique["gluonAmplitude$"];nu=Unique["gluonConjugate$"];
   spin=FeynCalc`FCI[GluonPolarizationProjector[k,reference,{mu,nu}]];
   result=(result/.{plus->FeynCalc`LorentzIndex[mu,D],minus->FeynCalc`LorentzIndex[nu,D]})spin
  ],
 {state,states}];
 result
],"GluonStates"];
End[];EndPackage[];
