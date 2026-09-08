(* A basis of a rational column space regular at the regulator origin.
   Exact operations saturate the column lattice over the local power-series
   ring; the generic column space is unchanged. *)
Clear[SaturateLaurentColumnBasis];
SaturateLaurentColumnBasis[input_?MatrixQ,e_Symbol] := Catch@Module[
 {b=exactRationalMatrix[input],n=Length[input],c=Dimensions[input][[2]],
  change=IdentityMatrix[Dimensions[input][[2]]],low,leading,good,bad,rows,
  coefficients,old,step=0,rank,check,left,point={e->1/97}},
 If[n<c,Throw[Failure["ColumnBasisHasTooManyColumns",<||>]]];
 If[!AllTrue[Flatten[b],PolynomialQ[Numerator[#],e]&&PolynomialQ[Denominator[#],e]&],
  Throw[Failure["LaurentRationalColumnBasisRequired",<||>]]];
 Do[
  low=Min[exactRationalLaurentValuation[#,e]&/@b[[All,j]]];
  If[low===Infinity,Throw[Failure["ZeroColumnInLaurentBasis",<|"Column"->j|>]]];
  b[[All,j]]=Cancel[Together[#/e^low]]&/@b[[All,j]];
  change[[All,j]]=change[[All,j]]/e^low,{j,c}];
 While[True,
  leading=b/.e->0;
  If[!MatrixQ[leading,MatchQ[#,_Integer|_Rational]&],
    Throw[Failure["RationalLeadingColumnMatrixRequired",<||>]]];
  good=exactIndependentRowIndices[Transpose[leading]];rank=Length[good];
  If[rank===c,Break[]];
  step++;If[step>64,Throw[Failure["LaurentSaturationDidNotTerminate",<||>]]];
  If[rank===0,Throw[Failure["NormalizedColumnsHaveZeroLeadingRank",<||>]]];
  bad=Complement[Range[c],good];
  rows=exactIndependentRowIndices[leading[[All,good]]];
  Do[
   coefficients=LinearSolve[leading[[rows,good]],leading[[rows,j]]];
   b[[All,j]]=Cancel[Together[#]]&/@(b[[All,j]]-b[[All,good]].coefficients);
   change[[All,j]]=Cancel[Together[#]]&/@(change[[All,j]]-change[[All,good]].coefficients);
   low=Min[exactRationalLaurentValuation[#,e]&/@b[[All,j]]];
   If[!IntegerQ[low]||low<1,Throw[Failure["LaurentColumnEliminationFailed",<||>]]];
   b[[All,j]]=Cancel[Together[#/e^low]]&/@b[[All,j]];
   change[[All,j]]=Cancel[Together[#/e^low]]&/@change[[All,j]],
   {j,bad}]];
 rows=exactIndependentRowIndices[leading];
 left=exactRationalMatrix[Inverse[b[[rows,All]]].IdentityMatrix[n][[rows]]];
 check=AllTrue[Flatten[(input/.point).(change/.point)-(b/.point)],#===0&]&&
   AllTrue[Flatten[(left/.point).(b/.point)-IdentityMatrix[c]],#===0&];
 If[!check,Throw[Failure["LaurentColumnSaturationVerificationFailed",<||>]]];
 <|"DataType"->"SaturatedLaurentColumnBasis","SchemaVersion"->1,
  "DimensionalRegulator"->e,"Basis"->b,"BasisChangeMatrix"->change,
  "LeftInverse"->left,"CoordinateRows"->rows,"LeadingRank"->rank,
  "SaturationSteps"->step,"VerificationPoint"->point,
  "Convention"->"InputBasis.BasisChangeMatrix = Basis; old amplitudes = BasisChangeMatrix.new amplitudes."|>
];
