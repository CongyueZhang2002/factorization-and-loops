(* Defining a tensor is a physics choice; conversion from that definition is
   computed here. A generated reference is not an absolute-normalization test. *)
BeginPackage["FeynFacet`"];
CurrentObservableNormalization::usage="CurrentObservableNormalization[definition,reference] resolves the normalization of a canonical current cut tensor. HadronicTensor is the measured spectral definition W=(1/(4 Pi)) sum_X (2 Pi)^D delta^D |J|^2 M; CutTensor omits that conventional prefactor. A BornNormalized coefficient additionally divides by an explicitly generated canonical cut-tensor reference at the declared epsilon order; the common spectral convention cancels in the ratio.";
Begin["`Private`"];
CurrentObservableNormalization[definition_Association,reference_:None]:=Module[
 {tensor,coefficient,factor,e,value,order},
 tensor=Lookup[definition,"Tensor",None];coefficient=Lookup[definition,"Coefficient",None];
 factor=Switch[tensor,"CutTensor",1,"HadronicTensor",1/(4Pi),_,
  Return[Failure["ExplicitSpectralTensorDefinitionRequired",<||>]]];
 Switch[coefficient,
  "TensorProjection",Null,
  "BornNormalized",
   If[!AssociationQ[reference]||!ContainsAll[Keys[reference],{"Coefficient","DimensionalRegulator"}]||
     !IntegerQ[Lookup[definition,"ReferenceEpsilonOrder",None]],
    Return[Failure["GeneratedBornReferenceAndExpansionOrderRequired",<||>]]];
   e=reference["DimensionalRegulator"];order=definition["ReferenceEpsilonOrder"];
   If[order=!=0,Return[Failure["FourDimensionalBornReferenceNormalizationRequired",<||>]]];
   value=reference["Coefficient"];
   If[!FreeQ[value,e|_Real|_Missing|_Failure|_Integrate|Indeterminate|_DirectedInfinity]||value===0,
    Return[Failure["ExplicitNonzeroBornReferenceCoefficientRequired",<||>]]];
   (* The reference is the generated canonical cut tensor. A common spectral
      convention multiplies both numerator and Born denominator and cancels. *)
   factor=Cancel[1/value],
  _,Return[Failure["ExplicitScalarCoefficientDefinitionRequired",<||>]]];
 <|"Factor"->factor,"Definition"->definition,
   "SpectralConvention"->"Complete cut sum with canonical relativistic states; not Im(T) or Disc(T).",
   "Reference"->reference|>
];
CurrentObservableNormalization[___]:=Failure["CurrentObservableDefinitionRequired",<||>];
End[];EndPackage[];
