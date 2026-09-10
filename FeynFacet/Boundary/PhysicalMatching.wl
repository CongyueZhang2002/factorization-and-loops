(* Physical asymptotic coefficient values fix a generic-epsilon Frobenius
   normalization. All observable rows and allowed regulator slopes are inputs
   from separately derived integral asymptotics. *)
BeginPackage["FeynFacet`"];
MatchPhysicalBoundaryCoefficients::usage =
 "MatchPhysicalBoundaryCoefficients[preparation,request] constructs generic-epsilon Frobenius jets, matches physical asymptotic coefficient values to their amplitudes, requires full exact matching rank, and checks unused coefficient equations at rational regulator/parameter points.";
Begin["`Private`"];
MatchPhysicalBoundaryCoefficients[preparation_Association,request_Association] :=
 Catch[Module[
 {normal,z,e,n,observable,physical,allowed,groups,selected,excluded,columns,seed,left,
  dimension,w,low,orders,depth,jetCache=<||>,coefficient,group,basis,groupLeft,
  expansion,spectral,rows={},row,term,integer,slope,offset=0,globalRow,
  candidates,chosen={},chosenMatrix={},sample,rank=0,nextRank,points,matrix,values,
  constants,residual,checks={},numeric,scale,maximumResidual,identity,
  progress,allCoefficients=<||>,completeSlopes,knownTerms,zeroUpper,q},
 If[Lookup[preparation,"DataType",None]=!="SingularBoundarySystemPreparation",
  cutFamilyFail["SingularBoundaryPreparationRequired"]];
 normal=preparation["NormalizedDifferentialSystem"];z=normal["Variable"];
 e=normal["DimensionalRegulator"];n=Length[normal["ConnectionMatrix"]];
 observable=Normal[Lookup[request,"ObservableMatrix",{}]];
 physical=Lookup[request,"PhysicalCoefficients",<||>];
 progress[text_]:=If[TrueQ[Lookup[request,"Verbose",False]],Print[text]];
 If[!MatrixQ[observable]||Last[Dimensions[observable]]=!=n||
   Keys[physical]=!=Range[Length[observable]]||
   !AllTrue[Values[physical],AssociationQ[#]&&KeyExistsQ[#,"AllowedRegulatorSlopes"]&],
  cutFamilyFail["ObservableMatrixAndCompleteAsymptoticSlopesRequired"]];
 (* If these rows span the entire vector, meromorphic rational inversion
    preserves regulator slopes. Only then can their absent slopes be excluded
    from the Frobenius initial data. *)
 If[MatrixRank[observable]=!=n,cutFamilyFail["PhysicalObservableRowsDoNotSpanSystem"]];
 completeSlopes=Lookup[Values[physical],"AllowedRegulatorSlopes"];
 allowed=Union@@completeSlopes;
 groups=preparation["PrimaryDecomposition"]["Eigenspaces"];
 If[!AllTrue[groups,PolynomialQ[#["Exponent"],e]&&
   Exponent[#["Exponent"],e]<=1&&TrueQ[(#["Exponent"]/.e->0)===0]&],
  cutFamilyFail["NormalizedAffineResidueExponentsRequired"]];
 selected=Select[groups,MemberQ[allowed,Coefficient[#["Exponent"],e]]&];
 excluded=Complement[Lookup[groups,"Exponent"],Lookup[selected,"Exponent"]];
 If[selected==={}||!AllTrue[selected,AllTrue[Flatten[#["NilpotentPart"]],epsOrderZero]&],
  cutFamilyFail["NonemptyLogFreePhysicalPrimarySectorsRequired"]];
 columns=Flatten[Lookup[selected,"Columns"]];dimension=Length[columns];
 seed=preparation["PrimarySeedMatrix"][[All,columns]];
 left=Inverse[preparation["PrimarySeedMatrix"]][[columns]];
 w=Map[Together,observable.preparation["NormalizedToOriginalGauge"],{2}];
 low=Min[boundaryLocalOrder[#,z]&/@#]&/@w;
 orders=Table[
  With[{j=i},(Cancel[#["Exponent"]-e Coefficient[#["Exponent"],e]]&/@physical[j]["Terms"])],
  {i,Length[observable]}];
 If[!AllTrue[Flatten[orders],IntegerQ]||!AllTrue[low,IntegerQ],
  cutFamilyFail["FiniteIntegerObservableNormalOrdersRequired"]];
 depth=Max[0,Max[MapThread[Max[#1]-#2&,{orders,low}]]];
 If[depth>Lookup[request,"MaximumNormalOrder",32],
  cutFamilyFail["PhysicalMatchingNormalDepthLimit",<|"RequiredOrder"->depth|>]];
 coefficient[expr_,k_]:=If[KeyExistsQ[jetCache,{expr,k}],jetCache[[Key[{expr,k}]]],
  With[{answer=Cancel[SeriesCoefficient[expr,{z,0,k}]]},
   AssociateTo[jetCache,{expr,k}->answer];answer]];
 progress["Constructing "<>ToString[dimension]<>" physical Frobenius columns through order "<>ToString[depth]<>"."];
 Do[
  basis=preparation["PrimarySeedMatrix"][[All,group["Columns"]]];
  groupLeft=Inverse[preparation["PrimarySeedMatrix"]][[group["Columns"]]];
  spectral=Unique["boundaryEigenvalue"];
  expansion=FeynFacet`ConstructPrimaryFrobeniusExpansion[normal,
   <|"Basis"->basis,"LeftInverse"->groupLeft|>,
   <|"ResidueEigenvalue"->group["Exponent"],"SpectralVariable"->spectral,
    "ResidueAnnihilatingPolynomial"->spectral-group["Exponent"],
    "MaximumNormalOrder"->depth|>];
  If[FailureQ[expansion],Throw[expansion,"CutFamily"]];
  AssociateTo[allCoefficients,group["Exponent"]->expansion];
  Do[
   knownTerms=Select[physical[i]["Terms"],
    epsOrderZero[group["Exponent"]-e Coefficient[#["Exponent"],e]]&];
   zeroUpper=If[knownTerms==={},low[[i]]+depth,
    Min[Cancel[#["Exponent"]-group["Exponent"]]&/@knownTerms]-1];
   Do[
    row=Total@Table[
     (coefficient[#,q-k]&/@w[[i]]).Normal[expansion["Coefficients"][[k+1,1]]],
     {k,0,q-low[[i]]}];
    globalRow=ConstantArray[0,dimension];
    globalRow[[offset+Range[Length[group["Columns"]]]]]=Cancel/@row;
    If[!AllTrue[globalRow,epsOrderZero],
     AppendTo[rows,<|"ObservableIndex"->i,"Exponent"->q+group["Exponent"],
      "Value"->0,"Row"->globalRow,"Branch"->"VanishingPhysicalCoefficient",
      "Reason"->If[knownTerms==={},"Regulator slope absent from the complete integral asymptotics.",
        "Integer power lies below the established onset of this physical branch."]|>]],
   {q,low[[i]],Min[zeroUpper,low[[i]]+depth]}];
   Do[
    slope=Coefficient[term["Exponent"],e];
    If[!epsOrderZero[group["Exponent"]-e slope],Continue[]];
    integer=Cancel[term["Exponent"]-group["Exponent"]];
    row=Total@Table[
     (coefficient[#,integer-k]&/@w[[i]]).Normal[expansion["Coefficients"][[k+1,1]]],
     {k,0,integer-low[[i]]}];
    globalRow=ConstantArray[0,dimension];
    globalRow[[offset+Range[Length[group["Columns"]]]]]=Cancel/@row;
    AppendTo[rows,<|"ObservableIndex"->i,"Exponent"->term["Exponent"],
     "Value"->term["Value"],"Row"->globalRow,"Branch"->Lookup[term,"Branch",None]|>],
    {term,physical[i]["Terms"]}],
   {i,Length[observable]}];
  offset+=Length[group["Columns"]],
 {group,selected}];
 points=Lookup[request,"ValidationPoints",{}];
 If[!MatchQ[points,{__List}],cutFamilyFail["RationalPhysicalMatchingValidationPointsRequired"]];
 sample=First[points];
 candidates=SortBy[Range[Length[rows]],
  {Count[rows[[#]]["Value"],_HypergeometricPFQ,Infinity],
   LeafCount[rows[[#]]["Value"]],LeafCount[rows[[#]]["Row"]]}&];
 Do[
  matrix=Append[chosenMatrix,rows[[j]]["Row"]];
  If[!AllTrue[Flatten[matrix/.sample],MatchQ[#,_Integer|_Rational]&],
   cutFamilyFail["CompleteRationalBoundaryMatchingPointRequired"]];
  nextRank=MatrixRank[matrix/.sample];
  If[nextRank>rank,AppendTo[chosen,j];chosenMatrix=matrix;rank=nextRank];
  If[rank===dimension,Break[]],
 {j,candidates}];
 If[rank<dimension,
  rank=MatrixRank[Lookup[rows,"Row"]];
  cutFamilyFail["PhysicalBoundaryMatchingRankDeficient",<|"Rank"->rank,
   "Dimension"->dimension,"RequiredNormalOrder"->depth,"CandidateRows"->rows|>]];
 matrix=chosenMatrix;
 identity=Map[Cancel,Inverse[matrix].matrix-IdentityMatrix[dimension],{2}];
 If[!AllTrue[Flatten[identity],epsOrderZero],cutFamilyFail["BoundaryMatchingInverseFailed"]];
 values=Lookup[rows[[chosen]],"Value"];
 constants=Inverse[matrix].values;
 progress["Full exact matching rank "<>ToString[dimension]<>"; checking unused physical values."];
 residual=Map[#["Row"].constants-#["Value"]&,rows];
 Do[
  numeric=Quiet[N[residual/.point,50]];
  scale=Quiet[N[(Lookup[rows,"Value"]/.point),50]];
  If[numeric===$Failed||scale===$Failed||!VectorQ[numeric,NumberQ]||!VectorQ[scale,NumberQ],
   cutFamilyFail["PhysicalBoundaryValueCheckNotNumerical",<|"Point"->point,
    "NonNumericalResiduals"->Select[numeric,!NumberQ[#]&],
    "NonNumericalValues"->Select[scale,!NumberQ[#]&]|>]];
  maximumResidual=Max[Abs[numeric]/(1+Abs[scale])];
  AppendTo[checks,<|"Point"->point,"MaximumScaledResidual"->maximumResidual|>];
  If[!TrueQ[maximumResidual<10^-30],
   cutFamilyFail["UnusedPhysicalBoundaryCoefficientMismatch",<|"Checks"->checks,"Rows"->rows|>]],
 {point,points}];
 <|"DataType"->"PhysicalFrobeniusBoundaryValues","Status"->"PhysicalBoundaryValuesDetermined",
  "Variable"->z,"DimensionalRegulator"->e,"SourceDimension"->n,"BoundaryConstantCount"->dimension,
  "SelectedResidueColumns"->columns,"ExcludedResidueExponents"->excluded,
  "NormalizedSeedMatrix"->seed,"NormalizedSeedLeftInverse"->left,
  "InitialConstantValues"->constants,"SelectedMatchingEquations"->rows[[chosen]],
  "CandidateCoefficientCount"->Length[rows],"FrobeniusNormalOrder"->depth,
  "MatchingMatrix"->matrix,"MatchingInverse"->Inverse[matrix],
  "FrobeniusExpansions"->allCoefficients,"Verification"-><|
   "FullExactMatchingRank"->True,"ExactInverse"->True,
   "UnusedPhysicalCoefficientChecks"->checks|>,
  "PhysicalCoefficientProvenance"->Lookup[request,"PhysicalCoefficientProvenance",None],
  "OrderPlanningRequirement"->"Propagate Laurent valuations of the matching inverse and exact boundary values before requesting finite-regulator transport coefficients."|>
 ],"CutFamily"];
End[];EndPackage[];
