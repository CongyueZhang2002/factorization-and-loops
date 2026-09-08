(* Materialized ordinary-point boundary coefficients, shared by all
   family solutions. The only free symbols are the declared Frobenius
   amplitudes. Reading this record performs no coefficient construction. *)
Clear[ConstructSharedBoundaryCoefficientDefinitions];
Options[ConstructSharedBoundaryCoefficientDefinitions]={"Verbose"->False};
ConstructSharedBoundaryCoefficientDefinitions[connection_Association,
 spec_Association,OptionsPattern[]] := Catch@Module[
 {e=connection["DimensionalRegulator"],vars=connection["KinematicVariables"],
  basis=spec["OrdinaryPointBoundaryBasis"],sourceRows=spec["SourceMasterRows"],
  pairs=spec["RequiredBoundaryCoefficients"],values=spec["ReferencePointCoordinates"],
  bounds=spec["AmplitudeLaurentLowerBounds"],known=Lookup[spec,"KnownAmplitudeExpressions",<||>],
  amplitudes=spec["UnknownAmplitudeDefinitions"],count,unknown,unknownIndex,
  matrices,knownValues=<||>,knownRules={},algebra={},functions={},kernels={},
  definitions=<||>,pointPairs,coordinates,raw,terms,coefficient,row,high,m,k,c,
  maxOrder,series,value,pruned,counts,shiftRules,shift,pointRules,shifted,keys,
  result,requirements,tag=Unique["knownCoefficient"],fail,progress,col,
  rowMap,knownIndices,allPointValues,pair,scalar,definition,indices,idx,knownOrdinary,ordinaryCoefficients=<||>,entryLower,columnTerms,done=0,
  knownUpper,connectionExpression},
 fail[name_,data_:<||>]:=Throw[Failure[name,data]];
 progress[text_]:=If[TrueQ[OptionValue["Verbose"]],Print[text]];
 count=Length[bounds];knownIndices=Keys[known];unknown=Complement[Range[count],knownIndices];
 If[count=!=connection["BoundaryDimension"]||Length[amplitudes]=!=Length[unknown]||
   !AllTrue[pairs,MatchQ[#,{_Integer,_Integer}]&],fail["BoundaryCoefficientSpecificationInvalid"]];
 unknownIndex=AssociationThread[unknown,Range[Length[unknown]]];
 rowMap=Lookup[spec,"BoundaryIndexToConnectionRow",AssociationThread[sourceRows,Range[Length[sourceRows]]]];
 matrices=Association@KeyValueMap[Function[{q,rows},q->Association[rows]],connection["Coefficients"]];
 maxOrder=Max[Last/@pairs];
 knownOrdinary=Lookup[spec,"KnownOrdinaryPointValues",<||>];
 entryLower=Lookup[connection,"MatrixEntryLaurentLowerBounds",
  ConstantArray[0,{connection["Dimension"],count}]];
 knownUpper=Association@Table[col->Max[Prepend[Table[
   If[KeyExistsQ[knownOrdinary,First[pair]]||entryLower[[rowMap[First[pair]],col]]===Infinity,Nothing,
    Last[pair]-entryLower[[rowMap[First[pair]],col]]],{pair,pairs}],bounds[[col]]-1]],{col,knownIndices}];
 Do[
  series=Expand[Normal[Series[known[col],{e,0,knownUpper[col]}]],e];
  Do[value=Coefficient[series,e,k];
   AssociateTo[knownValues,{col,k}->value];
   If[value=!=0,
    AppendTo[algebra,value];
    AppendTo[knownRules,With[{j=Length[algebra],column=col,order=k},
      tag[column,order]->FeynFacetSolution`a[j]]]],
   {k,bounds[[col]],knownUpper[col]}],{col,knownIndices}];
 (* All absent coefficients of a known amplitude in the declared range are
    exactly zero, not extra inputs. *)
 
 Do[
  If[KeyExistsQ[knownOrdinary,First[pair]],
   value=SeriesCoefficient[knownOrdinary[First[pair]],{e,0,Last[pair]}];
   AssociateTo[ordinaryCoefficients,pair->value];
   If[value=!=0,AppendTo[algebra,value];
    AppendTo[knownRules,With[{j=Length[algebra],index=First[pair],order=Last[pair]},
      tag["Ordinary",index,order]->FeynFacetSolution`a[j]]]]],
  {pair,pairs}];
 knownRules=Dispatch[knownRules];
 allPointValues=DeleteDuplicates[values[[Union[First/@pairs]]]];
 Do[
  pointPairs=Select[pairs,values[[First[#]]]===coordinates&];
  progress["Materializing "<>ToString[Length[pointPairs]]<>
    " original-master boundary coefficients at "<>ToString[coordinates,InputForm]<>"."];
  raw=Association@Table[
   If[Mod[++done,250]===0,progress["Constructed "<>ToString[done]<>" boundary coefficient expressions."]];
   {row,k}=pair;If[!KeyExistsQ[rowMap,row],fail["BoundaryIndexOutsideRequestedClosure",<|"Index"->row|>]];
   If[KeyExistsQ[ordinaryCoefficients,pair],
    value=If[ordinaryCoefficients[[Key[pair]]]===0,0,
      With[{index=row,order=k},tag["Ordinary",index,order]]],
    terms=Flatten@Table[
     If[entryLower[[rowMap[row],c]]===Infinity,{},
      high=k-bounds[[c]];
      If[high>connection["ColumnUpperOrders"][[c]],
       fail["BoundaryConnectionOrdersInsufficient",<|"Index"->row,"Column"->c,"Needed"->high|>]];
      epsilonAuditProduct[{epsilonAuditSpec[{"BoundaryConnection",row,c},entryLower[[rowMap[row],c]],
         connection["ColumnUpperOrders"][[c]]],epsilonAuditSpec[{"BoundaryAmplitude",c},bounds[[c]],
         If[KeyExistsQ[known,c],knownUpper[c],k-entryLower[[rowMap[row],c]]]]},k,
         "Stage3/SharedBoundaryConvolution",{row,c}];
      If[TrueQ[$epsilonRemainderChecks]&&KeyExistsQ[known,c],
       connectionExpression=Total[Table[matrices[order][rowMap[row]][[c]] e^order,{order,Keys[matrices]}]];
       epsilonAuditMultiplier[connectionExpression,e,bounds[[c]],knownUpper[c],k,
         "Stage3/KnownBoundaryAmplitude",{row,c}]];
      Table[
       coefficient=matrices[m][rowMap[row]][[c]];
       If[coefficient===0,Nothing,
        If[KeyExistsQ[known,c],
         scalar=knownValues[[Key[{c,k-m}]]];
         If[scalar===0,Nothing,With[{column=c,order=k-m},coefficient tag[column,order]]],
         With[{column=unknownIndex[c],order=k-m},coefficient FeynFacetSolution`C[column,order]]]],
       {m,entryLower[[rowMap[row],c]],high}]],
     {c,count}];value=Total[terms]];
   pair->value,
   {pair,pointPairs}];
  progress["Pruning unused finite definitions."];
  pruned=FeynFacetSolution`PruneFiniteSolutionDefinitions[connection,raw,"Verbose"->OptionValue["Verbose"]];
  progress["Finished pruning finite definitions."];
  If[FailureQ[pruned],Throw[pruned]];
  counts=Length/@{kernels,functions,algebra};
  shiftRules=With[{ao=counts[[3]],fo=counts[[2]],ko=counts[[1]]},{
   FeynFacetSolution`a[i_Integer]:>FeynFacetSolution`a[i+ao],
   FeynFacetSolution`F[i_Integer,u_]:>FeynFacetSolution`F[i+fo,u],
   FeynFacetSolution`K[i_Integer,u_]:>FeynFacetSolution`K[i+ko,u]}];
  pointRules=Thread[vars->coordinates];
  shift[value_] := FeynFacetSolution`Private`replaceFiniteExpressionReferences[
    value,shiftRules]/.pointRules;
  shifted=shift[pruned];
  kernels=Join[kernels,MapIndexed[Join[#1,<|"Index"->counts[[1]]+First[#2]|>]&,shifted["KernelDefinitions"]]];
  functions=Join[functions,MapIndexed[Join[#1,<|"Index"->counts[[2]]+First[#2]|>]&,shifted["IntegralDefinitions"]]];
  algebra=Join[algebra,shifted["AlgebraicDefinitions"]];
  definitions=Join[definitions,shifted["Expressions"]/.knownRules];
  progress["Shared definitions now contain "<>ToString[Length[kernels]]<>
    " scalar kernels and "<>ToString[Length[functions]]<>" proper integrals."],
  {coordinates,allPointValues}];
 If[!FreeQ[definitions,tag[___]],fail["KnownAmplitudeCoefficientNotMaterialized"]];
 requirements=Sort@DeleteDuplicates@Cases[definitions,
  FeynFacetSolution`C[i_Integer,q_Integer]:>{i,q},Infinity];
 <|"DataType"->"SharedBoundaryCoefficientDefinitions","SchemaVersion"->1,
  "BoundaryCoefficientDefinitions"->definitions,"BoundaryAmplitudes"->amplitudes,
  "InitialConstantLaurentLowerBounds"->bounds[[unknown]],
  "UnknownBoundarySeriesCount"->Length[unknown],
  "RequiredInitialConstantCoefficients"->requirements,
  "UnknownLaurentCoefficientCount"->Length[requirements],
  "KernelDefinitions"->kernels,"IntegralDefinitions"->functions,
  "AlgebraicDefinitions"->algebra,
  "KnownAmplitudeExpressions"->known,"KnownOrdinaryPointValues"->knownOrdinary,
  "OrdinaryPointBoundaryBasis"->basis,"SourceMasterRows"->sourceRows,
  "NormalPath"->connection["Path"],"ContourDeformation"->connection["ContourDeformation"],
  "EndpointPower"->connection["EndpointPower"],
  "BranchPrescription"->connection["BranchPrescription"],
  "CountertermNormalOrder"->connection["CountertermNormalOrder"],
  "EndpointOrderDetermination"->Lookup[connection,"EndpointOrderDetermination",None],
  "SingularBoundaryMatchingApplied"->True,
  "DefinitionScope"->"Every boundary coefficient and scalar integral definition is explicit and finite. No DE solver, Frobenius recurrence or coefficient generator is called by the reader."|>
];

(* Reuse an existing prepared DE and extend only coefficient orders made
   necessary by a new bound on ordinary-point data. The original finite
   fundamental matrix remains available even after shared-constant changes. *)
Clear[ExtendMasterIntegralSolutionForBoundaryBounds];
Options[ExtendMasterIntegralSolutionForBoundaryBounds]={"Verbose"->False};
ExtendMasterIntegralSolutionForBoundaryBounds[old_Association,bounds_List,
 OptionsPattern[]] := Catch@Module[
 {local,plan=old["ExpansionOrderDetermination"],previous,n,updated,needed,
  prepared,request,result,originalConstants,drop},
 n=Length[old["OriginalMasterIntegralBasis"]];
 previous=Lookup[old,"LocalInitialConstantLaurentLowerBounds",
   old["InitialConstantLaurentLowerBounds"]];
 If[Length[bounds]=!=n||!AllTrue[bounds,IntegerQ[#]||#===Infinity&],
  Throw[Failure["OrdinaryPointLaurentBoundsRequired",<||>]]];
 updated=MapThread[If[MissingQ[#1],#2,Min[#1,#2]]&,{previous,bounds}];
 needed=AnyTrue[Range[n],IntegerQ[previous[[#]]]&&updated[[#]]<previous[[#]]&];
 originalConstants=Lookup[old,"LocalInitialConstants",old["InitialConstants"]];
 drop={"BoundaryAmplitudes","SharedBoundaryDefinitionFile","SharedBoundaryDefinitionSource",
  "SharedBoundaryDefinitionsResolved","OrdinaryPointIntegralEmbedding","BoundaryOrderExtension",
  "SystemDimension","LocalInitialConstants","LocalInitialConstantLaurentLowerBounds",
  "LocalInitialConstantLowerBoundInputs","BoundaryBasis","LocalBoundaryCoefficientSubstitutions",
  "FixedPointSolutionImports","BoundaryReduction","BoundaryOrderRequirements","KnownBoundaryValues",
  "MasterIntegralCoefficients","InitialConstantLaurentLowerBounds","InitialConstantLowerBoundInputs",
  "InitialConstantLowerBoundStatus","RequiredInitialConstantCoefficients","RequestedMasterOrderCoverage"};
 If[!needed,
  local=Join[KeyDrop[old,drop],<|"SchemaVersion"->3,"InitialConstants"->originalConstants|>];
  result=Catch[solutionMasterCoefficientsFromOrders[local,plan],"FiniteSolution"],
  prepared=Join[plan["PreparedDifferentialSystem"],<|"Family"->old["Family"],
   "OriginalConnectionMatrices"->old["OriginalConnectionMatrices"]|>];
  request=<|"BasePoint"->old["BasePoint"],
   "RequestedMasterIntegralOrderRanges"->old["RequestedMasterIntegralOrderRanges"],
   "BoundaryNormalization"-><|"Type"->"OrdinaryPoint"|>,
   "MasterIntegralLaurentLowerBounds"->AssociationThread[Range[n],updated],
   "AnalyticDomain"->old["AnalyticDomain"],"BranchPrescription"->old["BranchPrescription"]|>;
  result=ConstructMasterIntegralSolution[prepared,request,
   "AutomaticPreparation"->False,"Verbose"->OptionValue["Verbose"]]];
 If[FailureQ[result],Throw[result]];
 Join[result,<|"BoundaryOrderExtension"-><|"Extended"->needed,
  "PreviousOrdinaryPointLowerBounds"->previous,"RequestedOrdinaryPointLowerBounds"->updated,
  "Justification"->"The previous established integral bounds are weakened where needed to cover the explicit boundary-amplitude connection without dropping transport coefficients.",
  "PreviousMaximumFundamentalOrder"->Max[old["RequestedEpsilonOrders"]],
  "MaximumFundamentalOrder"->Max[result["RequestedEpsilonOrders"]]|>|>]
];

(* Use the exact family embeddings at each family's own ordinary point.
   This avoids manufacturing a second connection from a demand-restricted
   lower-sector solution when different families have different base points. *)
Clear[ExpressFamilyBoundaryConstantsInGlobalBasis];
ExpressFamilyBoundaryConstantsInGlobalBasis[solutions_Association,
 global_Association,closed_Association,lowerBounds_List,
 normalCoordinates_Association] := Catch@Module[
 {n=closed["Dimension"],source=closed["SourceMasterRows"],sourceIndex,
  maps,points,pointIndex,candidates,basis,drafts=<||>,pairs={},used,renumber,
  data,fmap,embedding,pointEmbedding,localPairs,seriesCache,rules,terms,
  c,index,k,col,lo,hi,series,coeff,q,globalRow,pt,pid,result,fail,other,
  referenceCoordinates,rowRules,expr,allRules,fields,coordinateMap=Association[Normal[normalCoordinates]]},
 fail[tag_,detail_:<||>]:=Throw[Failure[tag,detail]];
 If[Length[lowerBounds]=!=n,fail["GlobalBoundaryLowerBoundsRequired"]];
 sourceIndex=AssociationThread[source,Range[n]];
 maps=Association@Table[ToString[m["Family"]]->m,{m,global["FamilyMaps"]}];
 points=DeleteDuplicates[Lookup[Values[solutions],"BasePoint"]];
 If[!AllTrue[points,KeyExistsQ[coordinateMap,#]&],fail["NormalCoordinatesForEveryBasePointRequired"]];
 pointIndex=AssociationThread[points,Range[Length[points]]];
 candidates=Flatten[Table[
  <|"Index"->((p-1)n+i),"MasterIntegral"->closed["MasterIntegralBasis"][[i]],
    "GlobalMasterIndex"->source[[i]],"ConnectionRow"->i,
    "ReferencePoint"->points[[p]],
    "NormalCoordinates"->coordinateMap[[Key[points[[p]]]]],
    "LaurentLowerBound"->lowerBounds[[i]]|>,
  {p,Length[points]},{i,n}],1];
 other=Complement[Range[global["GlobalSpanningMasterCount"]],source];
 Do[
  data=solutions[family];fmap=maps[family];
  If[(cutEquivalenceIntegral/@data["OriginalMasterIntegralBasis"])=!=
     (cutEquivalenceIntegral/@fmap["OriginalMasterIntegralBasis"]),
    fail["FamilyIntegralOrderingMismatch",<|"Family"->family|>]];
  embedding=Normal[fmap["IntegralEmbedding"]];
  If[other=!={}&&!AllTrue[Flatten[embedding[[data["RequestedRows"],other]]],globalDEZeroQ],
    fail["RequestedOutputsDependOnExcludedMasters",<|"Family"->family|>]];
  pt=data["BasePoint"];pid=pointIndex[[Key[pt]]];
  pointEmbedding=embedding/.Thread[data["KinematicVariables"]->pt];
  localPairs=data["RequiredInitialConstantCoefficients"];
  seriesCache=<||>;rules={};
  Do[
   {index,k}=pair;terms={};
   Do[
    globalRow=source[[col]];expr=pointEmbedding[[index,globalRow]];
    If[expr===0,Continue[]];
    hi=k-lowerBounds[[col]];
    lo=solutionValuation[expr,data["DimensionalRegulator"]];
    If[lo>hi,Continue[]];
    If[KeyExistsQ[seriesCache,{expr,hi}],series=seriesCache[[Key[{expr,hi}]]],
      series=Expand[Last[solutionRegulatorSeries[expr,data["DimensionalRegulator"],hi]],data["DimensionalRegulator"]];
      AssociateTo[seriesCache,{expr,hi}->series]];
    Do[coeff=Coefficient[series,data["DimensionalRegulator"],q];
     If[coeff=!=0,AppendTo[terms,With[{label=(pid-1)n+col,order=k-q},
      coeff FeynFacetSolution`B[label,order]]]],{q,lo,hi}],
    {col,n}];
   AppendTo[rules,With[{i=index,order=k},FeynFacetSolution`C[i,order]->Total[terms]]],
   {pair,localPairs}];
  rules=Dispatch[rules];
  result=Join[data,<|"MasterIntegralCoefficients"->(data["MasterIntegralCoefficients"]/.rules),
    "OrdinaryPointIntegralEmbedding"-><|"GlobalMasterRows"->source,
      "Matrix"->pointEmbedding[[All,source]],"ReferencePoint"->pt,
      "ExcludedGlobalRows"->other,"RequestedOutputExclusionChecked"->True|>|>];
  AssociateTo[drafts,family->result],
  {family,Keys[solutions]}];
 pairs=Sort@DeleteDuplicates@Cases[Lookup[Values[drafts],"MasterIntegralCoefficients"],
   FeynFacetSolution`B[i_Integer,q_Integer]:>{i,q},Infinity];
 used=Union[First/@pairs];
 renumber=AssociationThread[used,Range[Length[used]]];
 allRules=Dispatch@Table[With[{old=i,new=renumber[i]},
  HoldPattern[FeynFacetSolution`B[old,q_]]:>FeynFacetSolution`B[new,q]],{i,used}];
 drafts=Map[Join[#,<|"MasterIntegralCoefficients"->(#[ "MasterIntegralCoefficients"]/.allRules)|>]&,drafts];
 basis=MapIndexed[Join[#1,<|"Index"->First[#2]|>]&,candidates[[used]]];
 pairs=Sort@DeleteDuplicates@Cases[Lookup[Values[drafts],"MasterIntegralCoefficients"],
   FeynFacetSolution`B[i_Integer,q_Integer]:>{i,q},Infinity];
 <|"DataType"->"FamilyBoundaryCoefficientExpressions","Solutions"->drafts,
  "OrdinaryPointBoundaryBasis"->basis,"RequiredBoundaryCoefficients"->pairs,
  "BoundaryIndexToConnectionRow"->AssociationThread[Lookup[basis,"Index"],Lookup[basis,"ConnectionRow"]],
  "ReferencePointCoordinates"->Lookup[basis,"NormalCoordinates"],
  "SourceMasterRows"->source,
  "Scope"->"Every local ordinary-point constant is replaced using exact global integral embeddings at that same point. Excluded directions cannot affect the requested closed subsystem."|>
];

Clear[ApplySharedBoundaryCoefficientDefinitions];
ApplySharedBoundaryCoefficientDefinitions[solution_Association,
 shared_Association,file_String] := Module[
 {stored,resolved,oldConstants=solution["InitialConstants"],oldBounds,
  oldInputs,coverage,required,amplitudes=shared["BoundaryAmplitudes"]},
 oldBounds=solution["InitialConstantLaurentLowerBounds"];
 oldInputs=Lookup[solution,"InitialConstantLowerBoundInputs",{}];
 coverage=Lookup[solution,"RequestedMasterOrderCoverage",<||>];
 stored=Join[KeyDrop[solution,{"GPLRepresentation","NumericalPreparation","TaylorExpansion",
   "TaylorRepresentation","BoundaryBasis","FixedPointSolutionImports","LocalBoundaryCoefficientSubstitutions"}],<|
  "SchemaVersion"->5,"SystemDimension"->Length[solution["OriginalMasterIntegralBasis"]],
  "LocalInitialConstants"->Join[oldConstants,<|
    "Definition"->"Integral values in the local original-master basis at the ordinary base point; these are supplied by the shared boundary definitions."|>],
  "LocalInitialConstantLaurentLowerBounds"->oldBounds,
  "LocalInitialConstantLowerBoundInputs"->oldInputs,
  "InitialConstants"-><|"Count"->Length[amplitudes],"KinematicsIndependent"->True,
    "Definition"->"C_a(epsilon) are the unknown Frobenius amplitudes specified by BoundaryAmplitudes. Known amplitudes are already included in the shared coefficient definitions."|>,
  "BoundaryAmplitudes"->amplitudes,
  "InitialConstantLaurentLowerBounds"->shared["InitialConstantLaurentLowerBounds"],
  "InitialConstantLowerBoundInputs"->(<|"LowerBound"->#,
    "Method"->"InverseGaugeAndEpsilonRegularInverseTransport"|>&/@shared["InitialConstantLaurentLowerBounds"]),
  "InitialConstantLowerBoundStatus"->"BoundsDerivedForTheDeclaredFrobeniusAmplitudes",
  "KnownBoundaryValues"->KeyValueMap[<|"ConnectionColumn"->#1,"ExactAmplitude"->#2|>&,shared["KnownAmplitudeExpressions"]],
  "SharedBoundaryDefinitionFile"->file,
  "RequiredInitialConstantCoefficients"->Automatic,
  "RequestedMasterOrderCoverage"->Join[
    KeyDrop[coverage,{"RequiredInitialConstantCoefficients","InitialConstantUpperOrders"}],
    <|"LocalOrdinaryPointCoefficientRequirements"->KeyTake[coverage,
       {"RequiredInitialConstantCoefficients","InitialConstantUpperOrders"}]|>],
  "CoefficientConvention"->"Coefficients store the ordinary-point fundamental matrix in the local original-master basis. MasterIntegralCoefficients use the declared Frobenius amplitudes after the shared finite boundary definitions are read.",
  "BoundaryReduction"-><|"SingularBoundaryMatchingApplied"->True,
    "UnknownBoundarySeriesCount"->Length[amplitudes],
    "Representation"->"Explicit finite shared boundary coefficients and proper residual integrals."|>|>];
 resolved=FeynFacetSolution`ResolveSharedBoundaryDefinitions[stored,shared];
 If[FailureQ[resolved],Return[resolved]];
 If[!MasterIntegralSolutionQ[resolved],Return[Failure["BoundaryMatchedSolutionValidationFailed",<|"Family"->Lookup[solution,"Family",None]|>]]];
 required=resolved["RequiredInitialConstantCoefficients"];
 stored=Join[stored,<|"RequiredInitialConstantCoefficients"->required,
  "BoundaryOrderRequirements"-><|"RequiredBoundaryAmplitudeCoefficients"->required,
    "RequiredUnknownSeriesCount"->Length[Union[First/@required]],
    "RequiredLaurentCoefficientCount"->Length[required],
    "SingularBoundaryMatchingApplied"->True|>|>];
 <|"StoredSolution"->stored,"ResolvedSolution"->resolved,
   "RequiredBoundaryAmplitudeCoefficients"->required,
   "Validation"-><|"EverySharedDefinitionResolved"->True,
     "FiniteSolutionFormatVerified"->True|>|>
];
