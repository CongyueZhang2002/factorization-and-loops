(* Finite Frobenius pole bounds in a jointly epsilon-regular Fuchsian frame. *)
Begin["FeynFacet`Private`"];
Clear[epsOrderFrobenius,epsOrderParticularLinearSolution,epsOrderPolynomialSolution];
epsOrderParticularLinearSolution[a_,b_] := Module[{rr,n=Length[First[a]],answer,pivot},
 rr=RowReduce[Join[Normal[a],Transpose[{b}],2]];answer=ConstantArray[0,n];
 Do[
  pivot=SelectFirst[Range[n],!epsOrderZero[row[[#]]]& ,None];
  If[pivot===None,
    If[!epsOrderZero[Last[row]],epsOrderFail["ResonantPolynomialEquationInconsistent"]],
    answer[[pivot]]=Cancel[Last[row]-Total[Table[row[[j]] answer[[j]],{j,pivot+1,n}]]]],
 {row,Reverse[rr]}];
 answer
];
epsOrderPolynomialSolution[operator_,rhs_,log_,maxUnknowns_] := Module[
 {n=Length[operator],degree,unknowns,poly,eq,matrix,constant,values,inverse},
 degree=Max[0,Exponent[rhs,log]//Max];
 If[!epsOrderZero[Det[operator]],
   inverse=Inverse[operator];
   Return[Map[Cancel,Total[Table[(-1)^j MatrixPower[inverse,j+1].D[rhs,{log,j}],{j,0,degree}]]]]];
 degree=degree+n;
 If[n (degree+1)>maxUnknowns,
   epsOrderFail["ResonantPolynomialProblemTooLarge",
    <|"UnknownCount"->n(degree+1),"MaximumUnknowns"->maxUnknowns|>]];
 unknowns=Table[Unique["frobeniusCoefficient"],{n(degree+1)}];
 poly=Partition[unknowns,degree+1].Table[log^k,{k,0,degree}];
 eq=Flatten[Table[Coefficient[Expand[D[poly,log]+operator.poly-rhs],log,k],{k,0,degree}]];
 {constant,matrix}=CoefficientArrays[eq,unknowns];
 values=epsOrderParticularLinearSolution[matrix,-Normal[constant]];
 Map[Cancel,poly/.Thread[unknowns->values]]
];

(* Beyond the resonant prefix, left/right multiplication by the
   epsilon-regular connection/residue can spread, but cannot deepen, poles.
   Closing these entrywise inequalities avoids assigning an off-diagonal
   matching pole to every diagonal entry. *)
epsOrderFrobeniusEntryBounds[prefix_,left_,right_,e_] := Module[
 {n=Length[left],lo,l,r,changed=True,next},
 lo=Table[Min[epsOrderValuation[#[[i,j]],e]& /@ prefix],{i,n},{j,n}];
 l=Map[epsOrderValuation[#,e]&,left,{2}];
 r=Map[epsOrderValuation[#,e]&,right,{2}];
 While[changed,
  next=MapThread[Min,{lo,epsOrderProductBounds[l,lo],epsOrderProductBounds[lo,r]},2];
  changed=next=!=lo;lo=next
 ];lo
];

Options[FeynFacet`DetermineFrobeniusLaurentBounds]={
 "MaximumResonanceIndex"->64,"MaximumPolynomialUnknowns"->4096};
epsOrderFrobenius[d_,maxIndex_,maxUnknowns_] := Module[
 {x,e,connection,a,n,den,conditions,residue,eigen,diffs,indices,m,ac,
  h,g,log,operator,rhs,hn,gn,hBounds={0},gBounds={0},j,hEntry,gEntry,residueEntry,phiEntry,inversePhiEntry},
 x=Lookup[d,"NormalVariable",None];e=Lookup[d,"DimensionalRegulator",None];
 connection=Normal[Lookup[d,"ConnectionMatrix",{}]];n=Length[connection];
 If[x===None || e===None || !MatchQ[x,_Symbol] || !MatchQ[e,_Symbol] || x===e || n<1 ||
   Dimensions[connection]=!={n,n},epsOrderFail["NormalDifferentialSystemRequired"]];
 a=Map[Cancel,x connection,{2}];
 If[!FreeQ[a,_Real] || !AllTrue[Flatten[a],
    PolynomialQ[Numerator[Together[#]],{x,e}] &&
    PolynomialQ[Denominator[Together[#]],{x,e}]&],
   epsOrderFail["RationalFuchsianFrameRequired"]];
 den=DeleteDuplicates[Denominator[Together[#]]& /@ Flatten[a]];
 conditions=DeleteDuplicates[Cancel[#/.{x->0,e->0}]& /@ den];
 If[AnyTrue[conditions,epsOrderZero],
   epsOrderFail["UniformFuchsianNeighborhoodNotEstablished",
    <|"Reason"->"The frame is not jointly regular at normal coordinate=epsilon=0."|>]];
 residue=Map[Cancel,a/.x->0,{2}];
 eigen=RootReduce /@ Eigenvalues[residue/.e->0];
 If[!AllTrue[eigen,TrueQ[Element[#,Algebraics]]&],
   epsOrderFail["ResonanceIndicesNotEstablished",
    <|"ResidueEigenvaluesAtEpsilonZero"->eigen|>]];
 diffs=Flatten[Outer[Subtract,eigen,eigen]];
 indices=Sort[DeleteDuplicates[Select[RootReduce /@ diffs,IntegerQ[#]&&#>0&]]];
 m=Max[Prepend[indices,0]];
 If[m>maxIndex,epsOrderFail["ResonanceRangeTooLarge",<|"MaximumIndex"->m|>]];
 ac=Table[Map[Cancel,Map[SeriesCoefficient[#,{x,0,j}]&,a,{2}],{2}],{j,1,m}];
 h={IdentityMatrix[n]};g={IdentityMatrix[n]};log=Unique["frobeniusLog"];
 Do[
  operator=j IdentityMatrix[n^2]-KroneckerProduct[residue,IdentityMatrix[n]]+
     KroneckerProduct[IdentityMatrix[n],Transpose[residue]];
  rhs=Flatten[Total[Table[ac[[k]].h[[j-k+1]],{k,1,j}]]];
  hn=Partition[epsOrderPolynomialSolution[operator,rhs,log,maxUnknowns],n];
  AppendTo[h,hn];
  gn=Map[Cancel,-Total[Table[g[[j-k+1]].h[[k+1]],{k,1,j}]],{2}];
  AppendTo[g,gn];
  AppendTo[hBounds,Max[0,-Min[epsOrderValuation[#,e]& /@ Flatten[hn]]]];
  AppendTo[gBounds,Max[0,-Min[epsOrderValuation[#,e]& /@ Flatten[gn]]]],
 {j,1,m}];
 hEntry=epsOrderFrobeniusEntryBounds[h,a,residue,e];
 gEntry=epsOrderFrobeniusEntryBounds[g,residue,a,e];
 residueEntry=epsOrderDistances[Map[epsOrderValuation[#,e]&,residue,{2}]];
 phiEntry=epsOrderProductBounds[hEntry,residueEntry];
 inversePhiEntry=epsOrderProductBounds[residueEntry,gEntry];
 <|"DataType"->"FrobeniusLaurentBounds","Status"->"LocalLaurentBoundsEstablished",
  "NormalVariable"->x,"DimensionalRegulator"->e,"ResidueMatrix"->residue,
  "ResonantIndices"->indices,"LastResonantIndex"->m,
  "LocalFundamentalMatrixLaurentLowerBound"->-Max[hBounds],
  "InverseLocalFundamentalMatrixLaurentLowerBound"->-Max[gBounds],
  "ResidueExponentialEntryLowerBounds"->residueEntry,
  "FrobeniusSeriesEntryLowerBounds"->hEntry,
  "InverseFrobeniusSeriesEntryLowerBounds"->gEntry,
  "LocalFundamentalMatrixEntryLowerBounds"->phiEntry,
  "InverseLocalFundamentalMatrixEntryLowerBounds"->inversePhiEntry,
  "LogarithmVariable"->log,"FrobeniusCoefficientMatrices"->h,
  "InverseFrobeniusCoefficientMatrices"->g,
  "TangentialNonvanishingConditions"->(#!=0& /@ DeleteCases[conditions,_?NumericQ]),
  "Normalization"->"Phi=H(x,log(x),epsilon) x^R(epsilon), H_0=identity; polynomial free constants fixed to zero in the finite resonant solves.",
  "TailArgument"->"Beyond the last resonant index the Sylvester inverse is epsilon-regular. Neither Laurent pole order nor logarithmic degree increases. Joint holomorphy gives uniform convergence at a fixed ordinary matching point.",
  "MatchingMapStatus"->"Requires a uniform nonsingular epsilon-independent path and valuations of any additional meromorphic normalizations.",
  "GlobalMatchingFunctionsComputed"->False|>
];
FeynFacet`DetermineFrobeniusLaurentBounds[d_Association,OptionsPattern[]] :=
 Catch[epsOrderFrobenius[epsOrderNormalize[d,Lookup[d,"DimensionalRegulator",None]],OptionValue["MaximumResonanceIndex"],
   OptionValue["MaximumPolynomialUnknowns"]],"EpsilonOrders"];
End[];
