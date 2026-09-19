(* Algebraic selection of complete Frobenius amplitude subspaces. Physical
   applicability of the supplied slope bound is established by the caller. *)
BeginPackage["FeynFacet`"];
SelectFrobeniusModesByRegulatorSlope::usage=
 "SelectFrobeniusModesByRegulatorSlope[primaryDecomposition,maximumSlope] retains complete generalized eigenspaces with affine regulator exponents whose slopes do not exceed the supplied bound. It returns amplitude columns, never equations setting finite-point residue coordinates to zero. The caller must retain the physical endpoint-scaling proof and coordinate ramification.";
Begin["`Private`"];
SelectFrobeniusModesByRegulatorSlope[data_Association,maximum_]:=Module[
 {e,groups,exponents,slopes,selected,columns,n},
 e=Lookup[data,"DimensionalRegulator",None];groups=Lookup[data,"Eigenspaces",{}];
 If[!MatchQ[e,_Symbol]||groups==={}||!MatchQ[maximum,_Integer|_Rational]||
   !MatrixQ[Lookup[data,"BasisTransformationMatrix",None]],
  Return[Failure["ExactPrimaryDecompositionAndRationalSlopeRequired",<||>]]];
 exponents=Lookup[groups,"Exponent"];n=Length[data["BasisTransformationMatrix"]];
 If[!AllTrue[exponents,PolynomialQ[#,e]&&Exponent[#,e]<=1&],
  Return[Failure["ExactAffineRegulatorExponentsRequired",<||>]]];
 slopes=Coefficient[#,e]&/@exponents;
 If[!AllTrue[slopes,MatchQ[#,_Integer|_Rational]&],
  Return[Failure["RationalRegulatorSlopesRequired",<||>]]];
 If[Sort[Flatten[Lookup[groups,"Columns"]]]=!=Range[n],
  Return[Failure["CompletePrimaryColumnPartitionRequired",<||>]]];
 selected=Pick[groups,(#<=maximum&/@slopes)];columns=Flatten[Lookup[selected,"Columns",{}]];
 <|"DataType"->"FrobeniusRegulatorSlopeSelection","MaximumRegulatorSlope"->maximum,
  "RetainedEigenspaces"->selected,"RetainedColumns"->columns,
  "ExcludedColumns"->Complement[Range[n],columns],
  "SeedMatrix"->data["BasisTransformationMatrix"][[All,columns]],
  "FullGeneralizedEigenspacesRetained"->True,"PhysicalBoundProvedByThisSelection"->False|>
];
End[];EndPackage[];
