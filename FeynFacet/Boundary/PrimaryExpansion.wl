
(* Generic-regulator Frobenius coefficients for one complete primary
   component. Unlike the numerical initializer, epsilon is not expanded. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructPrimaryFrobeniusExpansion::usage="ConstructPrimaryFrobeniusExpansion[system,seed,request] constructs finite normal/logarithm coefficients for a generic-regulator primary component, verifying a supplied residue annihilating polynomial.";
primaryRationalMatrix[value_] := SparseArray[Map[Cancel[Together[#]]&,Normal[value],{2}]];
primaryZeroMatrixQ[value_] := Length[ArrayRules[primaryRationalMatrix[value]]]===1;
primaryMatrixPolynomial[poly_,var_,matrix_] := Module[{coeff=CoefficientList[poly,var],result,n=Length[matrix]},
 result=SparseArray[{},{n,n}];
 Do[result=primaryRationalMatrix[result.matrix+coeff[[j]] IdentityMatrix[n,SparseArray]],
 {j,Length[coeff],1,-1}];result];

primarySolveByBlocks[matrix_,rhs_,blocks_] := Module[
 {solution=ConstantArray[0,Dimensions[rhs]],done={},local,diag,rows},
 Do[
  local=rhs[[rows]]-If[done==={},ConstantArray[0,{Length[rows],Dimensions[rhs][[2]]}],
    matrix[[rows,done]].solution[[done]]];
  local=Normal[primaryRationalMatrix[local]];
  diag=Normal[matrix[[rows,rows]]];
  solution[[rows]]=Normal[primaryRationalMatrix[
    If[Length[rows]===1,local/diag[[1,1]],LinearSolve[diag,local]]]];
  done=Join[done,rows],
 {rows,blocks}];
 SparseArray[solution]];

Options[FeynFacet`ConstructPrimaryFrobeniusExpansion]={"Verbose"->False,"TimeLimit"->3600};
FeynFacet`ConstructPrimaryFrobeniusExpansion[system_Association,seed_Association,
 request_Association,OptionsPattern[]] := TimeConstrained[Catch[Module[
 {z=system["Variable"],eps=system["DimensionalRegulator"],connection=system["ConnectionMatrix"],
  basis=seed["Basis"],left=seed["LeftInverse"],eigenvalue=request["ResidueEigenvalue"],
  spectral=request["SpectralVariable"],annihilator=request["ResidueAnnihilatingPolynomial"],
  order=request["MaximumNormalOrder"],residue,reduced,n,c,factors,power,other,
  projectorPolynomial,projector,nilpotent,coefficients,source,solver,jet,polys,zero,
  rhs,next,m,l,nu,positions,cache=<||>,value,coefficient,helper=Unique["localSpectral"],
  verbose=OptionValue["Verbose"],started=AbsoluteTime[],blocks,linearMatrix},
 {n,c}=Dimensions[basis];
 If[Dimensions[connection]=!={n,n}||Dimensions[left]=!={c,n}||!IntegerQ[order]||order<0||
   !PolynomialQ[annihilator,spectral],boundaryIntegrationFail["PrimaryFrobeniusInputInvalid"]];
 residue=primaryRationalMatrix[Map[Cancel[Together[z#]]/.z->0&,connection,{2}]];
 reduced=primaryRationalMatrix[left.residue.basis];
 If[!primaryZeroMatrixQ[left.basis-IdentityMatrix[c]]||
   !primaryZeroMatrixQ[residue.basis-basis.reduced],
   boundaryIntegrationFail["InvariantFrobeniusSeedRequired"]];
 If[verbose,Print["Verifying the residue annihilating polynomial."]];
 If[!primaryZeroMatrixQ[primaryMatrixPolynomial[annihilator,spectral,reduced]],
   boundaryIntegrationFail["ResidueAnnihilatingPolynomialInvalid"]];
 power=Exponent[annihilator/.spectral->helper+eigenvalue,helper,Min];
 If[!IntegerQ[power]||power<1,boundaryIntegrationFail["RequestedResidueEigenvalueAbsent"]];
 other=Cancel[annihilator/(spectral-eigenvalue)^power];
 projectorPolynomial=Expand[other(Normal[Series[1/(other/.spectral->helper+eigenvalue),
   {helper,0,power-1}]]/.helper->spectral-eigenvalue)];
 projector=primaryMatrixPolynomial[projectorPolynomial,spectral,reduced];
 nilpotent=primaryRationalMatrix[(reduced-eigenvalue IdentityMatrix[c]).projector];
 If[!primaryZeroMatrixQ[projector.projector-projector]||
   !primaryZeroMatrixQ[MatrixPower[reduced-eigenvalue IdentityMatrix[c],power].projector],
   boundaryIntegrationFail["ResiduePrimaryProjectorInvalid"]];
 If[verbose,Print["Primary component dimension ",Cancel[Together[Tr[projector]]],
   ", maximum logarithm degree ",power-1]];
 zero=SparseArray[{},{n,c}];polys=Table[zero,{order+1},{power}];
 polys[[1,1]]=primaryRationalMatrix[basis.projector];
 Do[polys[[1,l+1]]=primaryRationalMatrix[polys[[1,l]].nilpotent/l],{l,1,power-1}];
 positions=Position[Normal[connection],x_/;x=!=0,{2},Heads->False];
 jet=Table[SparseArray[{},{n,n}],{order}];
 Do[
  source={};
  Do[value=Cancel[Together[z Extract[connection,pos]]];
   coefficient=If[KeyExistsQ[cache,{value,m}],cache[[Key[{value,m}]]],
     nu=Cancel[Together[SeriesCoefficient[value,{z,0,m}]]];AssociateTo[cache,{value,m}->nu];nu];
   If[coefficient=!=0,AppendTo[source,pos->coefficient]],{pos,positions}];
  jet[[m]]=SparseArray[source,{n,n}],{m,1,order}];
 blocks=familyBlockDecompositionComponents[Map[#===0&,Normal[residue],{2}]]["OrderedComponents"];
 If[!ListQ[blocks],boundaryIntegrationFail["ResidueBlockOrderingFailed"]];
 If[verbose,Print["Residue linear solves use ",Length[blocks]," diagonal blocks; largest dimension ",Max[Length/@blocks]]];
 Do[
  If[verbose,Print["Generic-epsilon Frobenius normal order ",m," of ",order]];
  linearMatrix=primaryRationalMatrix[(m+eigenvalue)IdentityMatrix[n,SparseArray]-residue];
  next=zero;
  Do[
   rhs=Total[Table[jet[[j]].polys[[m-j+1,l+1]],{j,1,m}]];
   next=primarySolveByBlocks[linearMatrix,Normal[rhs-(l+1)next],blocks];
   polys[[m+1,l+1]]=next,
   {l,power-1,0,-1}],
  {m,1,order}];
 <|"DataType"->"PrimaryFrobeniusExpansion","Variable"->z,"DimensionalRegulator"->eps,
   "ResidueEigenvalue"->eigenvalue,"MaximumNormalOrder"->order,"MaximumLogarithmPower"->power-1,
   "Coefficients"->polys,"PrimaryProjector"->projector,"SeedResidue"->reduced,
   "ResidueAnnihilatingPolynomial"->annihilator,"SpectralVariable"->spectral,
   "CoefficientConvention"->"Coefficients[[n+1,l+1]] multiplies z^(n+eigenvalue) Log[z]^l in the original seed-amplitude coordinates.",
   "ElapsedSeconds"->AbsoluteTime[]-started|>
],"BoundaryIntegration"],OptionValue["TimeLimit"],Failure["PrimaryFrobeniusExpansionTimeLimit",<||>]];
End[];
