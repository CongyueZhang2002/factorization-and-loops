(* Bare operator sewing and its adjoint on stored coefficient densities. *)
BeginPackage["FeynFacet`"];
BareCollinearOperatorNormalization::usage = "BareCollinearOperatorNormalization[role,species,z,dimension] gives the standard bare light-ray scalar extraction and its canonical cut-tensor sewing weight. Stripped spin projectors remain unchanged. The outgoing gluon tensor has dimension-2 polarization states; no extra outgoing spin/color average is introduced.";
CollinearPairingAdjointWeight::usage = "CollinearPairingAdjointWeight[sourceOperator,targetOperator,xi,y,sourceDensityPrefactor,targetDensityPrefactor,map] derives the scalar weight of the hard adjoint of ordinary Mellin replacement. Stored densities are h=N H; source N is evaluated at the rescaled momentum. Species-dependent weights retain any remaining y dependence.";
Begin["`Private`"];
BareCollinearOperatorNormalization[role:("PDF"|"FF"),species_,z_Symbol,dimension_]:=Module[
 {kind=If[ListQ[species],First[species],species],m=dimension-2,extraction,reconstruction,jacobian,weight},
 If[!MemberQ[{"q","qb","g"},kind],Return[Failure["SupportedCollinearFieldRequired",<||>]]];
 If[role==="FF",
  (* quark: z^(m-1) Tr[slash n C]/4; gluon field-strength tensor:
     -z^m g_T.Delta/m. Delta=(Pplus/z^2) C_A. Both yield the same
     coefficient of the already-normalized outgoing hard insertion. *)
  extraction=If[kind==="g",-z^m/m,z^(m-1)/4];
  reconstruction=z^(2-m);jacobian=1/z^2,
  extraction=None;
  reconstruction=1/z;jacobian=1];
 weight=Simplify[jacobian reconstruction];
 Join[<|"Role"->role,"Species"->species,"Variable"->z,"Dimension"->dimension,
   "InsertionCoefficientTimesLongitudinalScale"->reconstruction,
   "LongitudinalJacobianOverScale"->jacobian,"PairingWeight"->weight,
   "OutgoingColorAverage"->1,"ScalarRenormalizationMeasure"->"Mellin"|>,
   If[role==="FF",<|"ScalarExtractionPrefactor"->extraction|>,
    If[kind==="g",<|"ColorConvention"->"Adjoint-color-summed PDF; hard contains its incoming color average",
      "FieldStrengthExtractionTimesLongitudinalScale"->-1/z,
      "FieldStrengthReconstructionOverLongitudinalScale"->z,
      "FieldStrengthPairMomentumFactorOverScaleSquared"->z^2,
      "GaugeFieldExtractionOverLongitudinalScale"->-z,
      "TransverseTraceDimension"->m,"HardTransverseMetricCoefficient"->-1/m|>,<||>]]]
];
BareCollinearOperatorNormalization[___]:=Failure["BareCollinearOperatorDefinitionRequired",<||>];
CollinearPairingAdjointWeight[source_Association,target_Association,xi_Symbol,y_Symbol,
 sourceN_,targetN_,map_List]:=Module[{weight},
 If[!ContainsAll[Keys[source],{"Variable","PairingWeight","Role"}]||
   !ContainsAll[Keys[target],{"Variable","PairingWeight","Role"}]||source["Role"]=!=target["Role"],
  Return[Failure["CompatibleCollinearPairingsRequired",<||>]]];
 weight=(source["PairingWeight"]/.source["Variable"]->xi y)/
   (target["PairingWeight"]/.target["Variable"]->y)*targetN/(sourceN/.map);
 FullSimplify[weight,Assumptions->0<xi<1&&0<y<1&&Element[source["Dimension"],Reals]]
];
End[];EndPackage[];
