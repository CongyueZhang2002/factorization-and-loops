(* One exact bare-to-renormalized coupling convention for every consumer. *)
BeginPackage["FeynFacet`"];
MSbarCouplingNormalization::usage="MSbarCouplingNormalization[epsilon,Cepsilon] derives the exact relation between the generated bare-coupling convention aB=muR^(2epsilon) Cepsilon a Z(a) and the reference MSbar coupling. PoleNormalization=S_epsilon Cepsilon and abar=PoleNormalization a; Cepsilon is analytic at zero with value one and independent of scales, coupling and kinematics.";
BareStrongCouplingRules::usage="BareStrongCouplingRules[definition,epsilon] derives g_s0^2 from the declared alpha_s, scale and exact dimensional normalization. Assembly and counterterms consume the same relation.";
Begin["`Private`"];
MSbarCouplingNormalization[e_Symbol,c_]:=Catch[Module[{s,n,lower},
 s=Exp[e(Log[4Pi]-EulerGamma)];
 If[!FreeQ[c,_Real|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity]||
   !TrueQ[(c/.e->0)===1],collinearKernelFail["RegularUnitBareCouplingFactorRequired"]];
 lower=FeynFacet`DetermineMeromorphicLaurentLowerBound[c,e];
 If[lower=!=0,collinearKernelFail["AnalyticBareCouplingNormalizationRequired",<|"LowerBound"->lower|>]];
 n=FullSimplify[s c];
 <|"Format"->"FeynFacet-MSbarCouplingNormalization","FormatVersion"->1,
   "DimensionalRegulator"->e,"BareCouplingFactor"->c,
   "ReferenceBareCouplingFactor"->1/s,"PoleNormalization"->n,
   "ReferenceCouplingRelation"->"abar=PoleNormalization a; aB=muR^(2epsilon) BareCouplingFactor a Z_MSbar(abar)",
   "DimensionalBetaFunctionConvention"->"-epsilon a-b0 PoleNormalization a^2-b1 PoleNormalization^2 a^3+O(a^4)"|>
],"CollinearCounterterms"];
BareStrongCouplingRules[definition_Association,e_Symbol]:=Module[{normalization},
 If[!ContainsAll[Keys[definition],{"Coupling","RenormalizationScaleSquared","BareCouplingFactor"}],
  Return[Failure["BareStrongCouplingDefinitionRequired",<||>]]];
 normalization=FeynFacet`MSbarCouplingNormalization[e,definition["BareCouplingFactor"]];
 If[!AssociationQ[normalization],Return[normalization]];
 {FeynCalc`SMP["g_s"]^2->4Pi definition["Coupling"] definition["RenormalizationScaleSquared"]^e normalization["BareCouplingFactor"]}
];
End[];EndPackage[];
