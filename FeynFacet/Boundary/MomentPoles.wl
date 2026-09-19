(* Dimensional pole terms of local Frobenius moment densities. The finite
   part of the full interval integral is computed separately. *)
BeginPackage["FeynFacet`"];
ConstructFrobeniusMomentPoleMatrix::usage=
 "ConstructFrobeniusMomentPoleMatrix[normalizedSystem,primaryDecomposition,densityRows,request] extracts every t^(-1+beta epsilon) Log[t]^p term of the local density. Its exact integral contributes (-1)^p p!/(beta epsilon)^(p+1). Rational density poles determine the sufficient normal jet. Zero-slope amplitude columns are retained as explicit unresolved admissibility conditions, never assigned dimensional integrals. SelectedColumns optionally restricts to complete primary groups.";
VerifyRegulatorUniformFrobeniusExpansion::usage=
 "VerifyRegulatorUniformFrobeniusExpansion[normalizedSystem,rationalMultipliers,conditions] verifies a rational regular-singular endpoint with an epsilon-regular frame and no denominator coalescing with the endpoint at epsilon zero. Multipliers may have fixed integer endpoint powers and finite regulator poles. A failure requires further resolution; generic-epsilon Frobenius coefficients alone do not justify termwise moment integration.";
Begin["`Private`"];
VerifyRegulatorUniformFrobeniusExpansion[system_Association,multipliers_List,conditions_]:=Catch[Module[
 {x,e,a,rescaling,regular,objects,factors={},q,num,den,fac,value,unresolved={},fail},
 fail[tag_]:=Throw[Failure[tag,<||>],"UniformFrobeniusExpansion"];
 {x,e}=Lookup[system,{"Variable","DimensionalRegulator"}];a=Normal[system["ConnectionMatrix"]];
 If[!MatrixQ[a]||!AllTrue[multipliers,MatrixQ],fail["RationalEndpointMatricesRequired"]];
 rescaling=FeynFacet`FindEpsilonRescaling[{a},e];
 If[!AssociationQ[rescaling],Throw[Failure["EpsilonRegularEndpointFrameNotEstablished",<|"Cause"->rescaling|>],
   "UniformFrobeniusExpansion"]];
 regular=Map[Cancel,Normal[rescaling["InverseBasisTransformationMatrix"].a.
   rescaling["BasisTransformationMatrix"]],{2}];
 If[Min[exactRationalLaurentValuation[#,x]&/@Flatten[regular]]< -1||
    Min[exactRationalLaurentValuation[#,e]&/@Flatten[regular]]<0,
  fail["RegularSingularEpsilonRegularConnectionRequired"]];
 objects=DeleteDuplicates[Flatten[Join[{x regular},Normal/@multipliers]]];
 Do[
  q=Together[object];{num,den}=NumeratorDenominator[q];
  If[!PolynomialQ[num,{x,e}]||!PolynomialQ[den,{x,e}],fail["RationalJointEndpointDependenceRequired"]];
  factors=Join[factors,First/@Rest[FactorList[den]]],{object,objects}];
 factors=DeleteDuplicates[factors];
 Do[
  (* Pure powers can be extracted uniformly. A mixed t+epsilon divisor
     cannot be treated as either a fixed endpoint power or an epsilon pole. *)
  If[fac===x||fac===e,Continue[]];
  value=fac/.{x->0,e->0};
  If[!TrueQ[Refine[value!=0,conditions]],AppendTo[unresolved,fac]],{fac,factors}];
 If[unresolved=!={},Throw[Failure["RegulatorDependentEndpointDivisorNotResolved",
   <|"Divisors"->unresolved,"Variable"->x,"DimensionalRegulator"->e|>],"UniformFrobeniusExpansion"]];
 <|"DataType"->"RegulatorUniformFrobeniusExpansion","Variable"->x,"DimensionalRegulator"->e,
  "EpsilonRescaling"->rescaling,"CheckedDenominatorFactors"->factors,"Conditions"->conditions,
  "RegulatorUniformEndpointExpansionEstablished"->True,
  "Scope"->"The epsilon-regular Fuchsian connection and rational multipliers have fixed endpoint divisors. After finite endpoint/regulator powers are extracted their rational coefficients are jointly holomorphic near the endpoint. Apply the exact primary decomposition away from discrete regulator resonances. This does not prove absence of interior singularities, physical amplitudes or their epsilon coverage."|>
],"UniformFrobeniusExpansion"];
ConstructFrobeniusMomentPoleMatrix[system_Association,primary_Association,density_?MatrixQ,
 request_Association:<||>]:=Catch[Module[
 {x,e,n,seed,left,groups,columns,c,low,depth,coefficient,poles,unregulated={},jets={},
  group,cols,positions,ev,beta,power,spectral=Unique["spectral"],jet,h,local,uniform,fail},
 fail[tag_]:=Throw[Failure[tag,<||>],"FrobeniusMomentPoles"];
 {x,e}=Lookup[system,{"Variable","DimensionalRegulator"}];n=Length[system["ConnectionMatrix"]];
 seed=primary["BasisTransformationMatrix"];left=primary["InverseBasisTransformationMatrix"];
 columns=Lookup[request,"SelectedColumns",Range[n]];c=Length[columns];
 If[Last[Dimensions[density]]=!=n||Dimensions[seed]=!={n,n}||Dimensions[left]=!={n,n}||
   c===0||!DuplicateFreeQ[columns]||!AllTrue[columns,IntegerQ[#]&&1<=#<=n&],
  fail["CompatibleMomentDensityAndPrimaryColumnsRequired"]];
 uniform=VerifyRegulatorUniformFrobeniusExpansion[system,{density},Lookup[request,"Assumptions",True]];
 If[!AssociationQ[uniform],Throw[uniform,"FrobeniusMomentPoles"]];
 groups=Select[primary["Eigenspaces"],Intersection[#["Columns"],columns]=!={}&];
 If[Sort[Flatten[Lookup[groups,"Columns"]]]=!=Sort[columns],fail["CompletePrimaryAmplitudeSpacesRequired"]];
 low=Min[exactRationalLaurentValuation[#,x]&/@Flatten[Normal[density]]];
 If[low===Infinity,low=0];If[!IntegerQ[low],fail["RationalMomentDensityRequired"]];
 depth=Max[0,-1-low];
 If[depth>Lookup[request,"MaximumNormalOrder",32],fail["MomentFrobeniusDepthLimit"]];
 coefficient[value_,q_]:=coefficient[value,q]=Cancel[SeriesCoefficient[value,{x,0,q}]];
 poles=ConstantArray[0,{Length[density],c}];
 Do[
  cols=group["Columns"];ev=group["Exponent"];
  If[!PolynomialQ[ev,e]||Exponent[ev,e]>1||(ev/.e->0)=!=0,
   fail["NormalizedAffineResidueExponentsRequired"]];
  beta=Coefficient[ev,e];If[!MatchQ[beta,_Integer|_Rational],fail["RationalRegulatorSlopeRequired"]];
  If[beta===0,unregulated=Join[unregulated,cols];Continue[]];
  power=SelectFirst[Range[Length[cols]],solutionMatrixZero[MatrixPower[group["NilpotentPart"],#]]&,None];
  If[power===None,fail["ExactPrimaryNilpotencyRequired"]];
  jet=FeynFacet`ConstructPrimaryFrobeniusExpansion[system,
   <|"Basis"->seed[[All,cols]],"LeftInverse"->left[[cols]]|>,
   <|"ResidueEigenvalue"->ev,"SpectralVariable"->spectral,
     "ResidueAnnihilatingPolynomial"->(spectral-ev)^power,"MaximumNormalOrder"->depth|>,
   "TimeLimit"->Lookup[request,"TimeLimit",240]];
  If[!AssociationQ[jet],Throw[jet,"FrobeniusMomentPoles"]];
  h=Table[Map[Cancel,Sum[Map[coefficient[#,-1-j]&,Normal[density],{2}].
    Normal[jet["Coefficients"][[j+1,p+1]]],{j,0,depth}],{2}],{p,0,power-1}];
  local=Map[Cancel,Sum[(-1)^p Factorial[p]h[[p+1]]/(beta e)^(p+1),{p,0,power-1}],{2}];
  positions=Flatten[FirstPosition[columns,#]&/@cols];poles[[All,positions]]=local;
  AppendTo[jets,<|"Exponent"->ev,"Columns"->cols,"NormalDepth"->depth,
    "LogarithmicResidueMatrices"->h,"FrobeniusExpansion"->jet|>],{group,groups}];
 <|"DataType"->"FrobeniusMomentPoleMatrix","DimensionalRegulator"->e,
  "PoleMatrix"->poles,"SelectedColumns"->columns,"UnregulatedPrimaryColumns"->unregulated,
  "NormalDepth"->depth,"PrimaryTerms"->jets,
  "RegulatorUniformEndpointEvidence"->uniform,
  "CompleteDimensionalMomentEstablished"->False,
  "RequiredCompletion"->"Add the Hadamard finite part in the same inward endpoint coordinate at both ends, impose the original physical admissibility conditions, and propagate Laurent orders through all amplitude maps."|>
],"FrobeniusMomentPoles"];
End[];EndPackage[];
