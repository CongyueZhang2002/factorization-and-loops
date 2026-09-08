(* Preparation depends only on the differential system. Physical mode
   selection is a separate input and must include complete generalized
   eigenspaces. No exponent bound is inferred from a process name. *)
Clear[PrepareSingularBoundarySystem];
Options[PrepareSingularBoundarySystem]={"Verbose"->False,"HomogeneousSolveTimeLimit"->20};
PrepareSingularBoundarySystem[system_Association,OptionsPattern[]] := Catch@Module[
 {clean,normal,primary,rescaling,prepared,gauge,moving,regular,original,
  toPrepared,production,e,z,step,fail},
 fail[x_]:=If[FailureQ[x]||!AssociationQ[x],Throw[x]];
 e=system["DimensionalRegulator"];z=system["Variable"];
 clean=RemoveCoalescingApparentSingularities[system];fail[clean];
 moving=RegularSingularGaugeMatrix[clean];
 normal=NormalizeRegularSingularSystem[clean,"Verbose"->OptionValue["Verbose"]];fail[normal];
 primary=DecomposeResidueEigenspaces[normal];fail[primary];
 rescaling=FindEpsilonRescaling[{normal["ConnectionMatrix"]},e];fail[rescaling];
 prepared=PrepareDifferentialSystemForFiniteIntegration[
  <|"KinematicVariables"->{z},"DimensionalRegulator"->e,
    "ConnectionMatrices"->{clean["ConnectionMatrix"]}|>,
  "Verbose"->OptionValue["Verbose"],
  "HomogeneousSolveTimeLimit"->OptionValue["HomogeneousSolveTimeLimit"]];fail[prepared];
 gauge=RegularSingularGaugeMatrix[normal];
 regular=exactRationalMatrix[rescaling["InverseBasisTransformationMatrix"].
   normal["ConnectionMatrix"].rescaling["BasisTransformationMatrix"]];
 original=exactRationalMatrix[moving.gauge.rescaling["BasisTransformationMatrix"]];
 toPrepared=exactRationalMatrix[prepared["InverseBasisTransformationMatrix"].
   gauge.rescaling["BasisTransformationMatrix"]];
 production=Join[prepared,<|
  "BasisTransformationMatrix"->exactRationalMatrix[moving.prepared["BasisTransformationMatrix"]],
  "InverseBasisTransformationMatrix"->exactRationalMatrix[
    prepared["InverseBasisTransformationMatrix"].Inverse[moving]]|>];
 <|"DataType"->"SingularBoundarySystemPreparation",
   "OriginalDifferentialSystem"->system,"ApparentSingularityRemoval"->clean,
   "RegularSingularNormalization"->normal,"PrimaryDecomposition"->primary,
   "EpsilonRescaling"->rescaling,
   "NormalizedDifferentialSystem"-><|"Variable"->z,"DimensionalRegulator"->e,
     "ConnectionMatrix"->regular|>,
   "PrimarySeedMatrix"->exactRationalMatrix[
     rescaling["InverseBasisTransformationMatrix"].primary["BasisTransformationMatrix"]],
   "PreparedDifferentialSystem"->production,
   "NormalizedToPreparedGauge"->toPrepared,"NormalizedToOriginalGauge"->original,
   "OriginalToNormalizedGauge"->exactRationalMatrix[Inverse[original]],
   "PhysicalModesSelected"->False|>
];

(* Bounds follow all directed connection paths. A zero entry of one
   fundamental matrix is not used to declare an inverse-propagator zero. *)
Clear[DetermineBoundaryAmplitudeOrders];
DetermineBoundaryAmplitudeOrders[preparation_Association,seed_Association,
 originalBounds_List] := Catch@Module[
 {normal=preparation["NormalizedDifferentialSystem"],a,e,n,c,valuation,
  inverseGauge,gauge,left,beta,initial,backward,forward,gval,entry,
  deps,indices,next,changed,lower,ordinary,step},
 a=normal["ConnectionMatrix"];e=normal["DimensionalRegulator"];n=Length[a];
 c=Dimensions[seed["Basis"]][[2]];
 If[Length[originalBounds]=!=n||!AllTrue[originalBounds,IntegerQ[#]||#===Infinity&],
  Throw[Failure["OriginalIntegralLaurentBoundsRequired",<||>]]];
 valuation[x_]:=exactRationalLaurentValuation[x,e];
 beta=Map[valuation,a,{2}];
 If[Min[Flatten[beta]]<0,Throw[Failure["EpsilonRegularNormalizedConnectionRequired",<||>]]];
 inverseGauge=Map[valuation,preparation["OriginalToNormalizedGauge"],{2}];
 backward=Table[Min[inverseGauge[[i]]+originalBounds],{i,n}];
 deps=Table[Select[Range[n],beta[[i,#]]=!=Infinity&],{i,n}];
 Do[
  next=Table[Min[Prepend[(backward[[#]]+beta[[i,#]]&/@deps[[i]]),backward[[i]]]],{i,n}];
  If[next===backward,Break[]];backward=next,{n}];
 left=Map[valuation,seed["LeftInverse"],{2}];
 lower=Table[Min[left[[i]]+backward],{i,c}];
 forward=Map[valuation,seed["Basis"],{2}];
 Do[changed=False;
  Do[next=Min/@Transpose[Prepend[
    (forward[[#]]+beta[[i,#]]&/@deps[[i]]),forward[[i]]]];
   If[next=!=forward[[i]],forward[[i]]=next;changed=True],{i,n}];
  If[!changed,Break[]],{n}];
 gval=Map[valuation,preparation["NormalizedToOriginalGauge"],{2}];
 entry=Table[indices=Select[Range[n],gval[[i,#]]=!=Infinity&];
   If[indices==={},ConstantArray[Infinity,c],
    Min/@Transpose[(gval[[i,#]]+forward[[#]]&/@indices)]],{i,n}];
 ordinary=Table[Min[entry[[i]]+lower],{i,n}];
 <|"DataType"->"BoundaryAmplitudeOrders","AmplitudeLaurentLowerBounds"->lower,
   "MatrixEntryLaurentLowerBounds"->entry,"OrdinaryPointLaurentLowerBounds"->ordinary,
   "InverseTransportLaurentLowerBounds"->backward,
   "Method"->"Laurent valuations of exact gauges, a regular seed left inverse, and all paths of the epsilon-regular normalized connection."|>
];

Clear[ConstructSingularBoundaryConnection];
Options[ConstructSingularBoundaryConnection]=Options[ConstructBoundaryConnection];
ConstructSingularBoundaryConnection[preparation_Association,seed_?MatrixQ,
 request_Association,OptionsPattern[]] := Catch@Module[
 {normal=preparation["NormalizedDifferentialSystem"],upper,depth,expansion,result,high},
 upper=Lookup[request,"ColumnUpperOrders",Missing["Required"]];
 If[!VectorQ[upper,IntegerQ]||Length[upper]=!=Dimensions[seed][[2]]||Min[upper]<0,
  Throw[Failure["NonnegativeBoundaryColumnOrdersRequired",<||>]]];
 high=Max[upper];
 depth=DetermineBoundaryCountertermOrder[
  First[preparation["PreparedDifferentialSystem"]["ConnectionMatrices"]],
  preparation["NormalizedToPreparedGauge"],
  {normal["Variable"],normal["DimensionalRegulator"]},{0,high}];
 If[FailureQ[depth],Throw[depth]];
 expansion=ConstructFrobeniusBoundaryExpansion[normal,seed,
  <|"MaximumNormalOrder"->depth["MaximumNormalOrder"],"EpsilonOrderRange"->{0,high},
    "ColumnUpperOrders"->upper|>];
 If[FailureQ[expansion],Throw[expansion]];
 result=ConstructBoundaryConnection[Join[preparation,<|"FrobeniusExpansion"->expansion|>],
  request,"Verbose"->OptionValue["Verbose"],
  "ContourDeformation"->OptionValue["ContourDeformation"],"EndpointPower"->OptionValue["EndpointPower"]];
 result
];
