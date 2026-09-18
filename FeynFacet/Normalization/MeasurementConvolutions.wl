(* A reduced density inherits the operator action only when its complete
   measurement and tensor kernel intertwine with momentum rescaling. *)
BeginPackage["FeynFacet`"];
VerifyCollinearMeasurementCovariance::usage="VerifyCollinearMeasurementCovariance[definition] verifies ordinary Mellin closure before reduction. Kernel is the complete normalization times tensor projector and any acceptance weight; Measurement is the dimensionless tagged observable, or None for an inclusive current. IncomingMomenta, TaggedMomentum, TaggedDimension and Dimension specify the integration domain. CoordinateDefinitions replace all derived scalar coordinates before checking homogeneity. Unsupported momentum tensors or noncovariant cuts fail.";
Begin["`Private`"];
$collinearMeasurementCovarianceCache=<||>;
measurementRescale[expression_,momentum_,fraction_]:=Module[{value},
 value=FeynCalc`FCI[expression]/.tensor:(_FeynCalc`Pair|_FeynCalc`Eps):>
   fraction^Length[Cases[tensor,FeynCalc`Momentum[k_Symbol,___]/;k===momentum,Infinity]] tensor;
 value
];
VerifyCollinearMeasurementCovariance[definition_Association]:=Module[
 {kernel,measurement,incoming,tagged,dimension,taggedDimension,definitions,rules,assumptions,xi,
  residuals={},result,cached,ffWeight=None,source},
 cached=Lookup[$collinearMeasurementCovarianceCache,Key[definition],None];
 If[AssociationQ[cached],Return[cached]];
 If[!ContainsAll[Keys[definition],{"Kernel","Measurement","IncomingMomenta","TaggedMomentum","Dimension","TaggedDimension"}],
  Return[Failure["CompleteCollinearMeasurementDefinitionRequired",<||>]]];
 {kernel,measurement,incoming,tagged,dimension,taggedDimension}=Lookup[definition,
  {"Kernel","Measurement","IncomingMomenta","TaggedMomentum","Dimension","TaggedDimension"}];
 definitions=FeynCalc`FCI[Lookup[definition,"CoordinateDefinitions",{}]];
 rules=FeynCalc`FCI[Lookup[definition,"OnShellRules",{}]];
 assumptions=Lookup[definition,"Assumptions",True];xi=measurementRescalingFraction;
 kernel=FeynCalc`FCI[kernel]/.definitions;measurement=FeynCalc`FCI[measurement]/.definitions;
 (* Only elementary multilinear Lorentz tensors are scaled here. Do not
    assert a covariance identity for an opaque tensor or momentum sum. *)
 source={kernel,measurement};
 If[!FreeQ[source,_Failure|_Missing|Indeterminate|_DirectedInfinity]||
   !FreeQ[source/.(t:(_FeynCalc`Pair|_FeynCalc`Eps):>measurementTensorConstant),Alternatives@@Join[incoming,If[tagged===None,{}, {tagged}]]]||
   !FreeQ[source,FeynCalc`Momentum[Except[_Symbol],___]],
  Return[Failure["ExplicitMultilinearMeasurementKernelRequired",<||>]]];
 Do[AppendTo[residuals,measurementRescale[kernel,p,xi]-kernel];
   If[measurement=!=None,AppendTo[residuals,measurementRescale[measurement,p,xi]-measurement]],{p,incoming}];
 If[tagged=!=None,
  If[measurement===None,Return[Failure["TaggedMeasurementRequired",<||>]]];
  AppendTo[residuals,measurementRescale[kernel,tagged,xi]-kernel];
  AppendTo[residuals,measurementRescale[measurement,tagged,xi]-xi measurement];
  (* canonical FF pairing, on-shell measure, and delta Jacobian *)
  ffWeight=xi^(-(dimension-2)) xi^(taggedDimension-2)/xi;
  AppendTo[residuals,ffWeight-1/xi]];
 residuals=FullSimplify[Flatten[residuals]/.rules,Assumptions->assumptions&&0<xi<1&&Element[dimension,Reals]];
 If[!AllTrue[residuals,#===0&],Return[Failure["OrdinaryMellinProjectionDoesNotClose",<|"Residuals"->residuals|>]]];
 result=<|"Status"->"DerivedMeasurementCovariance","IncomingWeight"->1/xi,
   "FragmentationWeight"->ffWeight,"Definition"->definition,
   "Identity"->"P T = Tbar P on the full declared dimensional hard tensor"|>;
 AssociateTo[$collinearMeasurementCovarianceCache,definition->result];result
];
VerifyCollinearMeasurementCovariance[___]:=Failure["CompleteCollinearMeasurementDefinitionRequired",<||>];
End[];EndPackage[];
