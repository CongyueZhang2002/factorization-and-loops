(* Requested original-master coefficients, sufficient epsilon orders, and
   finite solutions share one ordinary-point normalization throughout. *)
Begin["FeynFacet`Private`"];
Clear[solutionConstructFromOrders,solutionMasterCoefficientsFromOrders];
solutionMasterCoefficientsFromOrders[r_,plan_] := Module[
 {ranges=plan["RequestedMasterIntegralOrderRanges"],rows,n,orders,lower,upper,
  uLower,uUpper,entries,terms,coefficient,constants,requirements,result,sourceBounds,status},
 rows=Keys[ranges];n=r["InitialConstants"]["Count"];
 orders=Union@@(Range@@#& /@ Values[ranges]);
 lower=plan["OrdinaryPointConstantLowerBounds"];
 lower=lower/.m_Missing->Missing["NotRequired"];
 upper=plan["OrdinaryPointConstantUpperOrders"];
 uLower=plan["OriginalFundamentalMatrixEntryLowerBounds"];
 uUpper=plan["OriginalFundamentalMatrixCoefficientUpperOrders"];
 entries=Association@Table[k->Table[
   terms=Flatten[Table[
    If[uUpper[[row,j]]===-Infinity || uLower[[row,j]]===Infinity ||
       lower[[j]]===Infinity,{},Table[
      coefficient=(row/.r["Coefficients"][q])[[j]];
      If[MissingQ[coefficient],solutionFail["RequiredFundamentalMatrixCoefficientMissing",
        <|"Row"->row,"Column"->j,"EpsilonOrder"->q|>]];
      coefficient FeynFacetSolution`C[j,k-q],
     {q,uLower[[row,j]],k-lower[[j]]}]],{j,n}]];
   row->Total[terms],{row,Select[rows,ranges[#][[1]]<=k<=ranges[#][[2]]&]}],
 {k,orders}];
 constants=DeleteDuplicates[Cases[Values[entries],FeynFacetSolution`C[j_,m_]:>{j,m},Infinity]];
 If[!AllTrue[constants,IntegerQ[lower[[#[[1]]]]] &&
    lower[[#[[1]]]]<=#[[2]]<=upper[[#[[1]]]]&],
  solutionFail["BoundaryCoefficientOrderCoverageFailed"]];
 sourceBounds=Table[Lookup[plan["IntegralBoundRecords"],j,Missing["NotRequired"]],{j,n}];
 status=If[plan["AssumedMasterLaurentBounds"]==={},
   "SufficientOrdersDetermined","SufficientForAssumedLaurentBounds"];
 result=Join[r,<|"RequestedMasterIntegralOrderRanges"->ranges,
  "RequestedMasterIntegralEpsilonOrders"->orders,
  "MasterIntegralCoefficients"->entries,
  "InitialConstantLaurentLowerBounds"->lower,
  "InitialConstantLowerBoundInputs"->sourceBounds,
  "InitialConstantLowerBoundStatus"->If[status==="SufficientOrdersDetermined",
    "BoundsEstablishedForSuppliedIntegralRepresentations","ExplicitInputAssumption"],
  "ExpansionOrderDetermination"->plan,
  "RequiredInitialConstantCoefficients"->Sort[constants],
  "RequestedMasterOrderCoverage"-><|"Status"->status,
    "BasePoint"->plan["BasePoint"],"RequestedOrderRanges"->ranges,
    "EveryRequestedCoefficientConstructed"->True,
    "RequiredInitialConstantCoefficients"->Sort[constants],
    "InitialConstantUpperOrders"->upper,
    "BoundaryConstantsDetermined"->False,
    "PhysicalNNLOCoverageInferred"->False|>|>];
 result["Validation"]=Join[result["Validation"],<|
   "RequestedMasterOrderCoverage"->result["RequestedMasterOrderCoverage"]|>];
 If[!FeynFacet`MasterIntegralSolutionQ[result],solutionFail["InvalidRequestedMasterCoefficientExport"]];
 result
];
solutionConstructFromOrders[s_,request_,options_] := Module[
 {plan,prepared,ranges,upper,orders,rows,r,solution,directory,base,original,source},
 If[Lookup[Lookup[request,"BoundaryNormalization",<||>],"Type","OrdinaryPoint"]=!="OrdinaryPoint",
  solutionFail["OrdinaryPointNormalizationRequiredForMasterCoefficientExport",
   <|"Reason"->"Singular-boundary order determination is available separately; this finite export uses C=I(X0)."|>]];
 plan=FeynFacet`DetermineMasterIntegralExpansionOrders[s,request,
  Sequence@@Normal[KeyTake[options,{"AutomaticPreparation","HomogeneousSolveTimeLimit",
    "RegularityProofTimeLimit","MaximumSectors","MaximumSectorDepth"}]]];
 If[FailureQ[plan],Throw[plan,"FiniteSolution"]];
 If[!MemberQ[{"SufficientOrdersDetermined","SufficientForAssumedLaurentBounds"},plan["Status"]],
  solutionFail["MasterIntegralExpansionOrdersUnresolved",<|"OrderDetermination"->plan|>]];
 prepared=plan["PreparedDifferentialSystem"];
 prepared=Join[prepared,<|"Family"->Lookup[s,"Family",None],
   "InputValidation"->Lookup[s,"InputValidation",Lookup[s,"Validation",<||>]]|>];
 original=Lookup[s,"OriginalConnectionMatrices",None];
 If[original===None && Lookup[s,"BasisTransformationMatrix",
     IdentityMatrix[Length[plan["OriginalMasterIntegralBasis"]]]]===
     IdentityMatrix[Length[plan["OriginalMasterIntegralBasis"]]],
  original=Lookup[s,"ConnectionMatrices",None]];
 If[ListQ[original],prepared=Join[prepared,<|"OriginalConnectionMatrices"->original|>]];
 source=Lookup[s,"ConnectionCoefficientSource",None];
 If[AssociationQ[source] && prepared["ConnectionMatrices"]===Lookup[s,"ConnectionMatrices",None] &&
    prepared["BasisTransformationMatrix"]===Lookup[s,"BasisTransformationMatrix",None],
   prepared=Join[prepared,<|"ConnectionCoefficientSource"->source|>]];
 ranges=plan["RequestedMasterIntegralOrderRanges"];rows=Keys[ranges];base=plan["BasePoint"];
 upper=Max[Prepend[DeleteCases[Flatten[plan["OriginalFundamentalMatrixCoefficientUpperOrders"]],-Infinity],0]];
 orders=Range[Min[0,Min[Flatten[plan["OriginalFundamentalMatrixEntryLowerBounds"]]]],upper];
 r=<|"BasePoint"->base,"RequestedRows"->rows,"RequestedEpsilonOrders"->orders,
   "AnalyticDomain"->Lookup[request,"AnalyticDomain",
     "A simply connected ordinary neighborhood of the base point containing the integration paths."],
   "BranchPrescription"->Lookup[request,"BranchPrescription",
     "Analytic continuation of the fixed physical branch from the ordinary base point, with no singularity crossed."]|>;
 solution=solutionConstruct[prepared,r,options["FlatnessCheck"],options["ValidationPoints"],
   None,False,options["HomogeneousSolveTimeLimit"],options["Verbose"],plan];
 solution=solutionMasterCoefficientsFromOrders[solution,plan];
 directory=options["OutputDirectory"];
 If[directory=!=None,
  If[!StringQ[directory],solutionFail["OutputDirectoryMustBeAString"]];
  solutionWrite[solution,directory]];
 solution
];
End[];
