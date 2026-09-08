(* Scalar endpoint coefficients in I=T H z^R c. The complete density row
   is first combined with T; only the normalized H coefficients are used. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructScalarEndpointProjection::usage =
 "ConstructScalarEndpointProjection[orderPlan,endpoint,bounds] forms every singular scalar row from DensityNormalGaugeRow and the normalized primary Frobenius coefficients, then determines entrywise tangential-function epsilon demands including endpoint contact poles.";
FeynFacet`ConstructScalarEndpointSolution::usage =
 "ConstructScalarEndpointSolution[projection,endpoint,request] constructs explicit finite scalar endpoint coefficients with a matched complete physical seed. The result includes finite F/K/a definitions and monomial terms ready for endpoint distribution extraction; no unknown constants remain.";
Clear[scalarEndpointFail,scalarEndpointNormalizePowers,scalarEndpointCancel,scalarEndpointRow,scalarEndpointValuation,scalarEndpointNormalOrder,
 scalarEndpointSeriesCoefficient,scalarEndpointFiniteSeries,scalarEndpointMatchingCheck,
 scalarEndpointDefinitionMerge,scalarEndpointCoefficientFieldAtoms,scalarEndpointDefinitionsValidQ];
scalarEndpointFail[tag_,data_:<||>] := Throw[Failure[tag,data],"ScalarEndpoint"];
scalarEndpointNormalOrder[x_,z_] := Catch[coefficientEndpointNormalOrder[x,z],"CoefficientEndpoint",
 Function[{value,tag},scalarEndpointFail["ScalarEndpointNormalOrderRequired",<|"Cause"->value|>]]];
(* Simplification is applied only after extracting a normal coefficient.
   An unfinished cancellation keeps the exact expression and a conservative
   common Laurent bound; it never discards a summand. *)
scalarEndpointNormalizePowers[x_] := x/.Power[b_,q_]:>b^Expand[q];
scalarEndpointCancel[x_] := Module[{normalized=scalarEndpointNormalizePowers[x],reduced},
 If[LeafCount[normalized]>500&&Length[DownValues[FeynFacet`SimplifyMasterCoefficientEntries]]>0&&
   StringQ[$rationalFunctionBackend]&&FileExistsQ[$rationalFunctionBackend],
  reduced=FeynFacet`SimplifyMasterCoefficientEntries[{<|"Terms"->{<|
    "Representation"->"Exact","PreFactor"->1,"Coefficient"->normalized|>}|>}];
  If[AssociationQ[reduced],Return[reduced["CoefficientEntries"][[1,"Terms",1,"Coefficient"]]]]];
 TimeConstrained[Cancel[Together[normalized]],5,normalized]];
scalarEndpointRow[x_] := Module[{normalized=scalarEndpointNormalizePowers[Flatten[Normal[x]]]},
 scalarEndpointCancel/@normalized];
scalarEndpointValuation[x_,e_] := Module[{value,bound},
 If[LeafCount[x]>500&&Length[DownValues[coefficientEndpointValuation]]>0,
  bound=Catch[coefficientEndpointValuation[x,e],"CoefficientEndpoint"];
  If[IntegerQ[bound]||bound===Infinity,Return[<|"LowerBound"->bound,"Exact"->False|>]]];
 value=TimeConstrained[FeynFacet`DetermineLaurentValuation[x,e],5,$Failed];
 If[IntegerQ[value]||value===Infinity,Return[<|"LowerBound"->value,"Exact"->True|>]];
 bound=FeynFacet`DetermineMeromorphicLaurentLowerBound[x,e];
 If[!IntegerQ[bound]&&bound=!=Infinity,
  scalarEndpointFail["ScalarEndpointLaurentValuationRequired",<|"Cause"->bound|>]];
 <|"LowerBound"->bound,"Exact"->False|>
];
scalarEndpointFiniteSeries[x_,e_,lo_Integer,hi_Integer] := Module[{expanded,lower,series,poly,result},
 expanded=regulatorSeries[scalarEndpointNormalizePowers[x],e,hi];
 If[FailureQ[expanded]||!MatchQ[expanded,{_,_}],
  scalarEndpointFail["ScalarEndpointSeriesNotConstructed",<|"Cause"->expanded,"RequestedRange"->{lo,hi}|>]];
 {lower,series}=expanded;
 If[lower===Infinity,Return[Association@Table[k->0,{k,lo,hi}]]];
 If[!IntegerQ[lower],scalarEndpointFail["IntegerScalarEndpointLaurentPowersRequired"]];
 lower=Min[lower,lo];poly=Expand[e^-lower series,e];
 If[!PolynomialQ[poly,e],scalarEndpointFail["IntegerScalarEndpointLaurentPowersRequired"]];
 result=Association@Table[k->scalarEndpointNormalizePowers[Coefficient[poly,e,k-lower]],{k,lo,hi}];
 If[!FreeQ[Values[result],e|_SeriesCoefficient|_Series|_SeriesData|_Missing|_Failure|Indeterminate|_DirectedInfinity],
  scalarEndpointFail["ExplicitScalarEndpointCoefficientRequired",<|"RequestedRange"->{lo,hi}|>]];
 result
];
scalarEndpointSeriesCoefficient[x_,e_,k_Integer] := scalarEndpointCancel[scalarEndpointFiniteSeries[x,e,k,k][k]];
scalarEndpointNormalSeries[x_,z_,lo_Integer,hi_Integer] := Module[{reduced,restore,vars,result},
 If[FreeQ[x,z],Return[Association@Table[k->If[k===0,x,0],{k,lo,hi}]]];
 If[Length[DownValues[coefficientRationalFieldReduce]]>0&&
   Length[DownValues[FeynFacet`RationalLaurentCoefficients]]>0&&
   StringQ[$rationalFunctionBackend]&&FileExistsQ[$rationalFunctionBackend],
  {reduced,restore}=coefficientRationalFieldReduce[x];
  (* The coefficient field is constant in the expansion variable. A root
     or analytic function depending on z must use the general series path. *)
  If[FreeQ[Last/@restore,z],
   vars=DeleteDuplicates[Cases[reduced,_Symbol,{0,Infinity}]];
   If[MemberQ[vars,z],
    result=FeynFacet`RationalLaurentCoefficients[{reduced},vars,z,{lo,hi}];
    If[ListQ[result]&&Length[result]===1,Return[First[result]/.restore]]]]];
 scalarEndpointFiniteSeries[x,z,lo,hi]
];

FeynFacet`ConstructScalarEndpointProjection[plan_Association,endpoint_Association,bounds_Association] :=
 Catch[Module[{e,z,v,n,target,depth,w,minimum,actualDepth,coefficients,sectors,jet,
  a,b,l,k,row,values,lower,normalSeries,functionBounds,upper,termUpper,terms={},rows,orders,
  coefficientLower,scalarLower,sector,checks,gaugeOrders,activeRows,originalExpressions,uniformOriginal,sectorBounds,canonicalBasis,projectedIDs,skippedSectors={}},
 If[Lookup[plan,"DataType",None]=!="MasterCoefficientEndpointOrders"||
   Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem"||
   Lookup[bounds,"DataType",None]=!="TangentialEndpointLaurentBounds",
  scalarEndpointFail["ScalarEndpointOrderPlanSystemAndBoundsRequired"]];
 {e,z,v,n}=Lookup[endpoint,{"DimensionalRegulator","NormalVariable","TangentialVariable","Dimension"}];
 {target,depth,w}=Lookup[plan,{"ThroughOrder","MaximumNormalOrder","DensityNormalGaugeRow"}];
 If[Lookup[plan,"Status",None]=!="SufficientOrdersDetermined"||
   !TrueQ[Lookup[plan,"NormalDepthSufficientForTargetOrder",False]]||
   Lookup[plan,"MissingCoefficientOrders",None]=!={}||
   !AllTrue[Lookup[plan,"CoefficientTermRequirements",{}],TrueQ[Lookup[#,"Sufficient",False]]&],
  scalarEndpointFail["EndpointCoefficientTailSufficiencyNotEstablished"]];
 If[!IntegerQ[target]||!IntegerQ[depth]||depth<0||!VectorQ[w]||Length[w]=!=n||
   Lookup[plan,"DimensionalRegulator",None]=!=e||Lookup[plan,"NormalVariable",None]=!=z||
   Lookup[plan,"OriginalMasterIntegralBasis",None]=!=Lookup[endpoint,"OriginalMasterIntegralBasis",None]||
   (KeyExistsQ[plan,"NormalGaugeMatrix"]&&plan["NormalGaugeMatrix"]=!=endpoint["NormalGaugeMatrix"]),
  scalarEndpointFail["EndpointProjectionOrderPlanMismatch"]];
 functionBounds=Lookup[bounds,"TangentialFunctionLaurentLowerBounds",None];
 If[!VectorQ[functionBounds,IntegerQ[#]||#===Infinity&]||Length[functionBounds]=!=n,
  scalarEndpointFail["CompleteTangentialFunctionLaurentBoundsRequired"]];
 gaugeOrders=Lookup[plan,"DensityNormalGaugeEntryLowerBounds",None];
 If[gaugeOrders===None,gaugeOrders=scalarEndpointNormalOrder[#,z]&/@w];
 If[!VectorQ[gaugeOrders,IntegerQ[#]||#===Infinity&]||Length[gaugeOrders]=!=n,
  scalarEndpointFail["DensityNormalGaugeEntryBoundsRequired"]];
 minimum=Min[gaugeOrders];actualDepth=If[minimum===Infinity,0,Max[0,-1-minimum]];
 If[actualDepth>depth||Lookup[endpoint,"MaximumNormalOrder",-1]<depth,
  scalarEndpointFail["NormalizedEndpointCoefficientsInsufficient",<|"RequiredNormalOrder"->actualDepth,
   "PlannedNormalOrder"->depth,"AvailableNormalOrder"->Lookup[endpoint,"MaximumNormalOrder",None]|>]];
 upper=ConstantArray[-Infinity,n];
 (* Expand each scalar row once through the highest normal power. Repeating
    the entire series for each requested coefficient multiplied this cost
    by the subtraction depth. *)
 coefficients=If[minimum===Infinity||minimum>=0,<||>,
  normalSeries=scalarEndpointNormalSeries[#,z,minimum,-1]&/@w;
  Association@Table[k->(scalarEndpointCancel[#[k]]&/@normalSeries),{k,minimum,-1}]];
 originalExpressions=Lookup[plan,"CoefficientExpressions",None];
 If[!ListQ[originalExpressions]||Length[originalExpressions]=!=n,
  scalarEndpointFail["OriginalCoefficientSupportRequired"]];
 activeRows=Union[Select[Range[n],originalExpressions[[#]]=!=0&],
   Lookup[Select[Lookup[plan,"CoefficientTermRequirements",{}],
     Lookup[#,"Representation",None]==="LaurentSeries"&],"Row",{}]];
 canonicalBasis=Map[If[MatchQ[#,head_[_,{__Integer}]]&&SymbolName[Head[#]]==="GLI",
    coefficientMasterID[#],#]&,endpoint["OriginalMasterIntegralBasis"]];
 projectedIDs=Lookup[plan,"ProjectedMasterIdentities",canonicalBasis[[activeRows]]];
 activeRows=Union[activeRows,Select[Range[n],MemberQ[projectedIDs,canonicalBasis[[#]]]&]];
 uniformOriginal=Lookup[bounds,"UniformPrimarySectorOriginalCoefficientLaurentLowerBounds",<||>];
 sectors=endpoint["PrimarySectors"];
 Do[
  sectorBounds=Lookup[uniformOriginal,sector["Exponent"],None];
  If[VectorQ[sectorBounds,IntegerQ[#]||#===Infinity&]&&Length[sectorBounds]===n&&
    AllTrue[activeRows,sectorBounds[[#]]===Infinity&],
   AppendTo[skippedSectors,<|"Exponent"->sector["Exponent"],"ActiveOriginalRows"->activeRows,
     "Reason"->"Uniform physical primary-sector bounds are Infinity on the entire original coefficient support."|>];Continue[]];
  jet=Lookup[sector,"NormalizedCoefficients",None];
  If[!ListQ[jet]||Length[jet]<depth+1||
    !AllTrue[Take[jet,depth+1],Dimensions[#]==={sector["NilpotencyIndex"],n,n}&],
   scalarEndpointFail["NormalizedPrimaryFrobeniusCoefficientsRequired"]];
  b=Cancel[sector["Exponent"]/e];
  If[!FreeQ[b,e|z|v],scalarEndpointFail["ConstantPrimaryRegulatorExponentRequired"]];
  If[minimum===Infinity||minimum>=0,Continue[]];
  Do[
   row=scalarEndpointRow[Total@Table[
     If[a-k<minimum,ConstantArray[0,n],coefficients[a-k].Normal[jet[[k+1,l+1]]]],
    {k,0,Min[depth,a-minimum]}]];
   If[AllTrue[row,#===0&],Continue[]];
   values=scalarEndpointValuation[#,e]&/@row;lower=Lookup[values,"LowerBound"];
   termUpper=Table[If[lower[[j]]===Infinity||functionBounds[[j]]===Infinity,-Infinity,
      target+l+1-lower[[j]]],{j,n}];
   upper=MapThread[Max,{upper,termUpper}];
   scalarLower=Min[MapThread[If[#1===Infinity||#2===Infinity,Infinity,#1+#2]&,{lower,functionBounds}]];
   AppendTo[terms,<|"Power"->a,"RegulatorExponent"->b,"LogPower"->l,
     "CoefficientRowMatrix"->{row},"CoefficientRowLaurentLowerBounds"->lower,
     "CoefficientRowValuationExact"->Lookup[values,"Exact"],
     "CoefficientLaurentLowerBound"->scalarLower,"EndpointContactPoleOrder"->l+1,
     "RequiredCoefficientUpperOrder"->target+l+1,
     "RequiredTangentialFunctionUpperOrders"->AssociationThread[Range[n],termUpper]|>],
   {a,minimum,-1},{l,0,sector["NilpotencyIndex"]-1}],
 {sector,sectors}];
 rows=Select[Range[n],IntegerQ[upper[[#]]]&&IntegerQ[functionBounds[[#]]]&&upper[[#]]>=functionBounds[[#]]&];
 orders=Association@Table[j->{functionBounds[[j]],upper[[j]]},{j,rows}];
 <|"DataType"->"ScalarEndpointProjection","SchemaVersion"->1,"Status"->"SingularCoefficientRowsConstructed",
   "NormalVariable"->z,"TangentialVariable"->v,"DimensionalRegulator"->e,"Dimension"->n,
   "OriginalMasterIntegralBasis"->endpoint["OriginalMasterIntegralBasis"],
   "ProjectedMasterIdentities"->projectedIDs,
   "SeparatedCoefficientPoles"->Lookup[plan,"SeparatedCoefficientPoles",{}],
   "PartialCoefficientContributions"->Lookup[plan,"PartialCoefficientContributions",{}],
   "SourceCoefficientFile"->Lookup[plan,"SourceCoefficientFile",None],
   "CoefficientSourceProvenance"->KeyTake[plan,{"SourceCoefficientFile","CoefficientSourceProvenance","Source","Contributions"}],
   "GlobalPrefactorIncluded"->True,
   "GlobalPrefactor"->Lookup[plan,"GlobalPrefactor",Missing["NotRecordedInOrderPlan"]],
   "GlobalPrefactorConvention"->"The order plan's GlobalPrefactor is already included in the projected coefficient rows and is not multiplied again.",
   "NormalGaugeMatrix"->endpoint["NormalGaugeMatrix"],
   "KnownDataTargetThroughOrder"->target,"MaximumNormalOrder"->depth,
   "DensityNormalGaugeRow"->w,"MinimumDensityNormalGaugeOrder"->minimum,
   "Terms"->terms,"StructurallyAbsentPrimarySectors"->skippedSectors,"ActiveOriginalCoefficientRows"->activeRows,"TangentialFunctionLaurentLowerBounds"->functionBounds,
   "InitialConstantLaurentLowerBounds"->bounds["InitialConstantLaurentLowerBounds"],
   "RequiredTangentialFunctionUpperOrders"->AssociationThread[Range[n],upper],
   "RequestedTangentialFunctionOrderRanges"->orders,
   "CoefficientTailSufficiency"->KeyTake[plan,{"Status","ThroughOrder","CoefficientTermRequirements","MissingCoefficientOrders","CoefficientRemainderClasses","UnresolvedCoefficientRemainderClasses","CoefficientRemainderDomainConditions"}],
   "CoefficientConvention"->"Each row multiplies c(v,epsilon) and z^(Power+epsilon RegulatorExponent) Log[z]^LogPower. Row construction uses only DensityNormalGaugeRow and NormalizedCoefficients, after c^T T cancellation.",
   "Scope"->"Singular scalar endpoint terms through the declared distribution epsilon target. The locally integrable remainder of the full density is separate."|>
 ],"ScalarEndpoint"];

scalarEndpointMatchingCheck[endpoint_,physical_,base_] := Module[
 {matching,bounds,e,z,v,n,matrix,construction,columns,known,unknown},
 matching=Lookup[physical,"BoundaryBasisMatching",<||>];bounds=Lookup[physical,"AmplitudeLaurentLowerBounds",{}];
 {e,z,v,n}=Lookup[endpoint,{"DimensionalRegulator","NormalVariable","TangentialVariable","Dimension"}];
 matrix=Lookup[matching,"AmplitudeToInitialVectorMatrix",{}];
 If[Lookup[matching,"DataType",None]=!="TangentialEndpointBoundaryBasisMatching"||
   Lookup[matching,"TangentialBasePoint",None]=!=base||
   !tangentialEndpointZeroQ[Lookup[matching,"NormalGaugeAtBasePoint",{}]-(endpoint["NormalGaugeMatrix"]/.v->base)]||
   !tangentialEndpointZeroQ[Lookup[matching,"NormalResidueAtBasePoint",{}]-(endpoint["NormalResidue"]/.v->base)]||
   !MatrixQ[matrix]||Dimensions[matrix]=!={n,Lookup[matching,"SourceAmplitudeCount",0]}||
   Length[bounds]=!=Lookup[matching,"SourceAmplitudeCount",None]||
   !VectorQ[bounds,IntegerQ[#]||#===Infinity&],scalarEndpointFail["MatchingCompletePhysicalEndpointSeedRequired"]];
 construction=Lookup[Lookup[physical,"AmplitudeCoefficients",<||>],"PhysicalBoundaryConstruction",None];
 If[construction=!=None,
  known=Lookup[construction,"KnownAmplitudeExpressions",<||>];unknown=Lookup[construction,"UnknownAmplitudeDefinitions",{}];
  columns=Join[Keys[known],Lookup[Lookup[unknown,"Definition",{}],"SeedColumn",{}]];
  If[!DuplicateFreeQ[columns]||Sort[columns]=!=Range[Length[bounds]],
   scalarEndpointFail["PhysicalSeedColumnAssignmentIncomplete",<|"SourceAmplitudeCount"->Length[bounds],"AssignedColumns"->columns|>]]];
 <|"Matching"->matching,"SourceBounds"->bounds,
   "InitialBounds"->tangentialEndpointMappedBounds[Map[solutionValuation[#,e]&,matrix,{2}],bounds]|>
];

(* Physical seed coefficients may carry their own finite definitions. Keep
   the two definition lists disjoint before substituting into the new solve. *)
scalarEndpointDefinitionMerge[solution_,source_,values_] := Module[
 {kd=Lookup[solution,"KernelDefinitions",{}],fd=Lookup[solution,"IntegralDefinitions",{}],
  ad=Lookup[solution,"AlgebraicDefinitions",{}],sk,sf,sa,nk,nf,na,shift,new},
 {sk,sf,sa}=Lookup[source,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"},{}];
 If[!AllTrue[{sk,sf,sa},ListQ],scalarEndpointFail["PhysicalSeedFiniteDefinitionsInvalid"]];
 {nk,nf,na}=Length/@{kd,fd,ad};
 shift[x_]:=FeynFacetSolution`Private`replaceFiniteExpressionReferences[x,{
   FeynFacetSolution`K[i_Integer,u_]:>With[{j=i+nk},FeynFacetSolution`K[j,u]],
   FeynFacetSolution`F[i_Integer,u_]:>With[{j=i+nf},FeynFacetSolution`F[j,u]],
   FeynFacetSolution`a[i_Integer]:>With[{j=i+na},FeynFacetSolution`a[j]]}];
 If[(!FreeQ[values,_FeynFacetSolution`K]&&sk==={})||
    (!FreeQ[values,_FeynFacetSolution`F]&&sf==={})||(!FreeQ[values,_FeynFacetSolution`a]&&sa==={}),
  scalarEndpointFail["PhysicalSeedFiniteDefinitionsRequired"]];
 sk=MapIndexed[With[{index=First[#2]+nk},Join[shift[#1],<|"Index"->index|>]]&,sk];
 sf=MapIndexed[With[{index=First[#2]+nf},Join[shift[#1],<|"Index"->index|>]]&,sf];sa=shift[sa];
 <|"Values"->shift[values],"KernelDefinitions"->Join[kd,sk],
   "IntegralDefinitions"->Join[fd,sf],"AlgebraicDefinitions"->Join[ad,sa]|>
];
(* Opaque factors inherited from the coefficient row are constants in
   the endpoint/regulator coefficient field. They never authorize a lazy
   function or an unresolved reference in the constructed definitions. *)
scalarEndpointCoefficientFieldAtoms[row_,variables_] := DeleteDuplicates@Cases[row,
 value:h_[___]/;FreeQ[value,Alternatives@@variables]&&!MemberQ[{Rational,Complex},h]&&
  !solutionExplicitExpressionQ[h[scalarEndpointCoefficientFieldProbe]]&&
  FreeQ[value,FeynFacetSolution`C[__]|_Function|_SeriesCoefficient|_Series|_SeriesData|_Missing|_Failure|
   FeynFacetSolution`F[__]|FeynFacetSolution`K[__]|FeynFacetSolution`a[__]|$Failed|Indeterminate|_DirectedInfinity]:>value,{0,Infinity}];
scalarEndpointDefinitionsValidQ[expressions_,data_,coefficientField_:{}] := Module[{all,k,f,a,fieldRules},
 fieldRules=Thread[coefficientField->Table[Unique["coefficientField"],{Length[coefficientField]}]];
 {k,f,a}=Lookup[data,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"},{}];
 all={expressions,k,f,a};
 AllTrue[Flatten[Values /@ expressions]/.fieldRules,solutionExplicitExpressionQ]&&
 AllTrue[Join[Lookup[k,"Expression",{}],Lookup[f,"Integrand",{}],a],solutionExplicitExpressionQ]&&
 FreeQ[all,FeynFacetSolution`C[__]|_Function|_SeriesCoefficient|_Series|_SeriesData|_Missing|_Failure|$Failed|Indeterminate|_DirectedInfinity]&&
 AllTrue[Cases[all,FeynFacetSolution`K[i_,_]:>i,Infinity],IntegerQ[#]&&1<=#<=Length[k]&]&&
 AllTrue[Cases[all,FeynFacetSolution`F[i_,_]:>i,Infinity],IntegerQ[#]&&1<=#<=Length[f]&]&&
 AllTrue[Cases[all,FeynFacetSolution`a[i_]:>i,Infinity],IntegerQ[#]&&1<=#<=Length[a]&]
];

Options[FeynFacet`ConstructScalarEndpointSolution]={"Verbose"->False,"HomogeneousSolveTimeLimit"->30};
FeynFacet`ConstructScalarEndpointSolution[projection_Association,endpoint_Association,request_Association,OptionsPattern[]] :=
 Catch[Catch[Module[{e,z,v,n,target,base,physical,seed,matching,sourceBounds,initial,functionBounds,
  ranges,system,solverRequest,solution,terms={},row,lo,hi,values,q,j,m,cv,pair,
  requiredConstants,constantData,merge,initialRules,definitions,sourceDefinitions,
  sourceValues,rawTerms,coef,columnLower,range,series,distributionTerms,zeroSeries,term,pruned,physicalDefinitions,
  coefficientCache=<||>,seriesCache=<||>,getCoefficient,getFunction,pairs,metadata,coefficientField},
 If[Lookup[projection,"DataType",None]=!="ScalarEndpointProjection"||
   Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem",
  scalarEndpointFail["ScalarProjectionAndEndpointSystemRequired"]];
 {e,z,v,n}=Lookup[endpoint,{"DimensionalRegulator","NormalVariable","TangentialVariable","Dimension"}];
 target=Lookup[request,"ThroughOrder",projection["KnownDataTargetThroughOrder"]];
 base=Lookup[request,"TangentialBasePoint",None];physical=Lookup[request,"PhysicalBoundaryValues",None];
 If[!IntegerQ[target]||target>projection["KnownDataTargetThroughOrder"],
  scalarEndpointFail["EndpointCoefficientReplanningRequired",<|"KnownDataTargetThroughOrder"->projection["KnownDataTargetThroughOrder"],"RequestedThroughOrder"->target|>]];
 If[Lookup[projection,"NormalGaugeMatrix",None]=!=endpoint["NormalGaugeMatrix"]||
   Lookup[projection,"DimensionalRegulator",None]=!=e||Lookup[projection,"NormalVariable",None]=!=z||
   Lookup[projection,"Dimension",None]=!=n||!AssociationQ[physical]||
   !NumericQ[base]||!FreeQ[base,_Real|e|z|v],scalarEndpointFail["ScalarEndpointPhysicalSolutionRequestInvalid"]];
 seed=scalarEndpointMatchingCheck[endpoint,physical,base];
 {matching,sourceBounds,initial}=Lookup[seed,{"Matching","SourceBounds","InitialBounds"}];
 If[initial=!=projection["InitialConstantLaurentLowerBounds"],scalarEndpointFail["ProjectionPhysicalSeedBoundsMismatch"]];
 functionBounds=projection["TangentialFunctionLaurentLowerBounds"];
 ranges=projection["RequestedTangentialFunctionOrderRanges"];
 ranges=Map[{First[#],Last[#]+target-projection["KnownDataTargetThroughOrder"]}&,ranges];
 ranges=Select[ranges,Last[#]>=First[#]&];
 system=<|"KinematicVariables"->{v},"DimensionalRegulator"->e,"ConnectionMatrices"->{endpoint["TangentialConnectionMatrix"]}|>;
 If[ranges===<||>,
  solution=<|"KernelDefinitions"->{},"IntegralDefinitions"->{},"AlgebraicDefinitions"->{},"MasterIntegralCoefficients"-><||>|>,
  solverRequest=<|"BasePoint"->{base},"RequestedMasterIntegralOrderRanges"->ranges,
    "MasterIntegralLaurentLowerBounds"->AssociationThread[Range[n],initial],
    "AnalyticDomain"->endpoint["AnalyticDomain"],"BranchPrescription"->endpoint["BranchPrescription"]|>;
  solution=FeynFacet`ConstructMasterIntegralSolution[system,solverRequest,
    "FlatnessCheck"->"Exact","Verbose"->OptionValue["Verbose"],"HomogeneousSolveTimeLimit"->OptionValue["HomogeneousSolveTimeLimit"]];
  If[FailureQ[solution],scalarEndpointFail["ScalarEndpointTangentialSolveFailed",<|"Cause"->solution|>]]];
 getFunction[column_,order_]:=Module[{stored=Lookup[solution["MasterIntegralCoefficients"],order,Missing["Order"]],entry},
  If[MissingQ[stored],scalarEndpointFail["TangentialFunctionOrderMissing",<|"Column"->column,"Order"->order|>]];
  entry=column/.stored;
  If[entry===column,scalarEndpointFail["TangentialFunctionOrderMissing",<|"Column"->column,"Order"->order|>]];entry];
 getCoefficient[column_,order_,expression_]:=Module[{key={expression,order},value},
  If[KeyExistsQ[coefficientCache,key],Return[coefficientCache[[Key[key]]]]];
  value=scalarEndpointSeriesCoefficient[expression,e,order];AssociateTo[coefficientCache,key->value];value];
 Do[
  row=First[term["CoefficientRowMatrix"]];lo=term["CoefficientLaurentLowerBound"];hi=target+term["EndpointContactPoleOrder"];
  If[lo===Infinity||lo>hi,Continue[]];
  If[TrueQ[$epsilonRemainderChecks],Do[
   If[KeyExistsQ[ranges,j],epsilonAuditMultiplier[row[[j]],e,functionBounds[[j]],Last[ranges[j]],hi,
     "Stage4/TangentialEndpointConvolution",{term["Power"],term["LogPower"],j}]],{j,n}]];
  values=Association@Table[q->Total[Flatten[Table[
     cv=term["CoefficientRowLaurentLowerBounds"][[j]];columnLower=functionBounds[[j]];
     If[cv===Infinity||columnLower===Infinity||q-cv<columnLower,{},
      Table[coef=getCoefficient[j,q-m,row[[j]]];
       If[coef===0,0,coef getFunction[j,m]],{m,columnLower,q-cv}]],{j,n}]]],{q,lo,hi}];
  AppendTo[terms,<|"Power"->term["Power"],"RegulatorExponent"->term["RegulatorExponent"],"LogPower"->term["LogPower"],
    "LaurentLowerBound"->lo,"KnownThroughOrder"->hi,"Coefficients"->values,"ExactInEpsilon"->False|>],
 {term,projection["Terms"]}];
 (* Only definitions reached by the projected scalar coefficients can
    request physical constants. A C coefficient hidden behind a finite
    reference is treated in the same way as a directly occurring C. *)
 pruned=FeynFacetSolution`PruneFiniteSolutionDefinitions[solution,terms];
 If[FailureQ[pruned],scalarEndpointFail["ScalarEndpointDefinitionClosureFailed",<|"Cause"->pruned|>]];
 terms=pruned["Expressions"];
 definitions=KeyTake[pruned,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}];
 pairs=Sort[DeleteDuplicates[Cases[{terms,definitions},FeynFacetSolution`C[i_Integer,q_Integer]:>{i,q},Infinity]]];
 constantData=tangentialEndpointPhysicalConstants[matching,Lookup[physical,"AmplitudeCoefficients",<||>],sourceBounds,pairs,e];
 sourceDefinitions=Lookup[physical,"FiniteDefinitions",<||>];
 sourceValues=Last/@constantData["InitialConstantRules"];
 physicalDefinitions=FeynFacetSolution`PruneFiniteSolutionDefinitions[sourceDefinitions,sourceValues];
 If[FailureQ[physicalDefinitions],scalarEndpointFail["PhysicalSeedDefinitionClosureFailed",<|"Cause"->physicalDefinitions|>]];
 merge=scalarEndpointDefinitionMerge[definitions,physicalDefinitions,physicalDefinitions["Expressions"]];
 initialRules=Thread[(First/@constantData["InitialConstantRules"])->merge["Values"]];
 terms=FeynFacetSolution`Private`replaceFiniteExpressionReferences[terms,initialRules];
 definitions=FeynFacetSolution`Private`replaceFiniteExpressionReferences[
   KeyTake[merge,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions"}],initialRules];
 coefficientField=scalarEndpointCoefficientFieldAtoms[projection["DensityNormalGaugeRow"],{e,z,v}];
 If[!scalarEndpointDefinitionsValidQ[Lookup[terms,"Coefficients",{}],definitions,coefficientField],
  scalarEndpointFail["ScalarEndpointFiniteDefinitionsOrPhysicalConstantsIncomplete",<|
   "UnresolvedConstants"->DeleteDuplicates@Cases[{terms,definitions},FeynFacetSolution`C[__],Infinity],
   "FirstInvalidCoefficient"->SelectFirst[Flatten[Values/@Lookup[terms,"Coefficients",{}]],
     !solutionExplicitExpressionQ[#/.Thread[coefficientField->ConstantArray[1,Length[coefficientField]]]]&,None],
   "FirstInvalidDefinition"->SelectFirst[Join[Lookup[definitions["KernelDefinitions"],"Expression",{}],
     Lookup[definitions["IntegralDefinitions"],"Integrand",{}],definitions["AlgebraicDefinitions"]],
     !solutionExplicitExpressionQ[#]&,None]|>]];
 zeroSeries[low_,high_]:=<|"LaurentLowerBound"->low,"KnownThroughOrder"->Max[low-1,high],
   "Coefficients"->Association@Table[k->0,{k,low,Max[low-1,high]}],"ExactInEpsilon"->True|>;
 distributionTerms=Table[
  series=KeyTake[term,{"LaurentLowerBound","KnownThroughOrder","Coefficients","ExactInEpsilon"}];
  <|"Power"->term["Power"]+e term["RegulatorExponent"],"LogPower"->term["LogPower"],"Prefactor"->1,
    "TaylorCoefficients"->Association@Table[j->If[j===0,series,zeroSeries[0,term["KnownThroughOrder"]]],{j,0,-term["Power"]-1}],
    "Remainder"->zeroSeries[0,Max[0,target]],"RemainderEndpointPowerLowerBound"->0,
    "Labels"-><|"Power"->term["Power"],"RegulatorExponent"->term["RegulatorExponent"],"LogPower"->term["LogPower"]|>|>,
 {term,terms}];
 Join[<|"DataType"->"FiniteScalarEndpointSolution","SchemaVersion"->1,
   "Status"->"ExplicitPhysicalScalarEndpointCoefficients","NormalVariable"->z,"TangentialVariable"->v,
   "OriginalMasterIntegralBasis"->projection["OriginalMasterIntegralBasis"],
   "ProjectedMasterIdentities"->projection["ProjectedMasterIdentities"],
   "SeparatedCoefficientPoles"->Lookup[projection,"SeparatedCoefficientPoles",{}],
   "PartialCoefficientContributions"->Lookup[projection,"PartialCoefficientContributions",{}],
   "SourceCoefficientFile"->projection["SourceCoefficientFile"],
   "CoefficientSourceProvenance"->projection["CoefficientSourceProvenance"],
   "GlobalPrefactorIncluded"->projection["GlobalPrefactorIncluded"],
   "GlobalPrefactor"->projection["GlobalPrefactor"],
   "GlobalPrefactorConvention"->projection["GlobalPrefactorConvention"],
   "DimensionalRegulator"->e,"TangentialBasePoint"->base,"KnownDataTargetThroughOrder"->projection["KnownDataTargetThroughOrder"],
   "CoefficientFieldConstants"->coefficientField,
   "ThroughOrder"->target,"EndpointTerms"->terms,"DistributionInputTerms"->distributionTerms,
   "RequestedTangentialFunctionOrderRanges"->ranges,"PhysicalBoundaryValuesApplied"->True,
   "SourceAmplitudeCount"->Length[sourceBounds],"AmplitudeLaurentLowerBounds"->sourceBounds,
   "ResolvedInitialConstantCoefficients"->AssociationThread[pairs,merge["Values"]],
   "RequiredPhysicalAmplitudeCoefficients"->constantData["RequiredPhysicalAmplitudeCoefficients"],
   "RequiredInitialConstantCoefficients"->{},"AnalyticDomain"->endpoint["AnalyticDomain"],
   "BranchPrescription"->endpoint["BranchPrescription"],
   "CoefficientTailSufficiency"->projection["CoefficientTailSufficiency"],
   "Scope"->"Explicit singular monomials of the scalar density on a smooth endpoint divisor. DistributionInputTerms describes this singular model only; the integrable remainder of the full density is not asserted to vanish."|>,definitions]
 ],"TangentialEndpoint",Function[{value,tag},If[FailureQ[value],value,Failure["PhysicalScalarEndpointConstructionFailed",<|"Cause"->value|>]]]],"ScalarEndpoint"];
FeynFacet`ConstructScalarEndpointProjection[___] :=Failure["ScalarEndpointOrderPlanSystemAndBoundsRequired",<||>];
FeynFacet`ConstructScalarEndpointSolution[___] :=Failure["ScalarProjectionEndpointAndPhysicalRequestRequired",<||>];
End[];
