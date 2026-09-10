(* Final color-resolved distribution storage. Shared definitions contain
   the actual finite expressions; discarded fields are redundant views. *)
BeginPackage["FeynFacet`"];
CompactFiniteDistributionResult::usage="CompactFiniteDistributionResult[source] retains explicit color-resolved delta/plus/regular coefficients and their closed shared definitions, with exact index-correspondence checks. CompactFiniteDistributionResult[source,prepared] accepts a prepared CompactFiniteSolutionDefinitions result but independently verifies it. Source domains, branch data, normalization and order declarations are preserved.";
VerifyFiniteDistributionCompaction::usage="VerifyFiniteDistributionCompaction[source,compact] checks a saved compact distribution against its source, including every retained definition, full output, semantic contexts and retained metadata. Use in a fresh kernel to check serialization without reevaluating integrals.";
PartonicResultFromEndpointDensity::usage="PartonicResultFromEndpointDensity[density,metadata] writes the assembled endpoint density in the common result format, retaining its finite shared definitions and explicit distribution coordinate and interval.";
Begin["`Private`"];
distributionCompactFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"DistributionCompaction"];
distributionCompactMetadata[source_]:=KeyDrop[source,{
 "AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions","ColorComponents",
 "Coefficients","Expression","DeltaTerms","PlusTerms","RegularRemainderCoefficients",
 "SingularModelCoefficients","InteriorCoefficients","DefinitionScopes",
 "ExpandedColorDependentAlgebraicDefinitions","ComputationTimings"}];
CompactFiniteDistributionResult[source_Association]:=Module[{prepared},
 prepared=FeynFacetSolution`CompactFiniteSolutionDefinitions[source,source["ColorComponents"]];
 If[FailureQ[prepared],prepared,CompactFiniteDistributionResult[source,prepared]]];
CompactFiniteDistributionResult[source_Association,prepared_Association]:=Catch[Module[
 {metadata,colors,report,result,sourceType},
 colors=Lookup[source,"ColorComponents",None];metadata=distributionCompactMetadata[source];
 If[!ListQ[colors]||colors==={}||!AllTrue[colors,AssociationQ[#]&&ContainsAll[Keys[#],
   {"ColorFactor","CouplingPower","ExternalFactor","DeltaTerms","PlusTerms","RegularRemainderCoefficients"}]&],
  distributionCompactFail["ExplicitColorResolvedDistributionsRequired"]];
 If[!FreeQ[metadata,_FeynFacetSolution`a|_FeynFacetSolution`F|_FeynFacetSolution`K],
  distributionCompactFail["RetainedMetadataNeedsAdditionalDefinitionRoots"]];
 report=FeynFacetSolution`VerifyFiniteSolutionCompaction[source,colors,prepared];
 If[FailureQ[report],distributionCompactFail["FiniteDistributionCompactionNotVerified",<|"Cause"->report|>]];
 sourceType=Lookup[source,"DataType",Missing["NotDeclared"]];
 result=Join[metadata,KeyTake[prepared,{"AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions","DefinitionSemanticContexts"}],
  <|"DataType"->"CompactFinitePartonicDistributions","SchemaVersion"->1,"SourceDataType"->sourceType,
   "ColorComponents"->prepared["Expressions"],"SourceDefinitionScopes"->Lookup[source,"DefinitionScopes",{}],
   "SourceToRetainedDefinitionIndices"->report["OriginalToRetainedIndices"],
   "Compaction"->Join[KeyDrop[prepared["Compaction"],{"OriginalToDistinctIndices","RetainedDistinctIndices"}],
     <|"Verification"->KeyDrop[report,"OriginalToRetainedIndices"],
       "DiscardedViews"->{"Uncolored coefficients/expression","Uncolored delta/plus/regular terms","Interior and singular-model coefficient views"},
       "StoredExpressionKind"->"Explicit finite color-resolved expressions with shared exact definitions; no coefficient generation or DE solution required on reading"|>]|>];result
 ],"DistributionCompaction"];
VerifyFiniteDistributionCompaction[source_Association,compact_Association]:=Catch[Module[
 {metadata,maps,report,prepared,counts,kinds={"Kernel","Integral","Algebraic"},oldMaps,retained,field,result},
 If[Lookup[compact,"DataType",None]=!="CompactFinitePartonicDistributions",
  distributionCompactFail["CompactFinitePartonicDistributionsRequired"]];
 metadata=KeyDrop[distributionCompactMetadata[source],{"DataType","SchemaVersion"}];
 If[KeyTake[compact,Keys[metadata]]=!=metadata||
   Lookup[compact,"SourceDataType",None]=!=Lookup[source,"DataType",Missing["NotDeclared"]]||
   Lookup[compact,"SourceDefinitionScopes",None]=!=Lookup[source,"DefinitionScopes",{}],
  distributionCompactFail["CompactedDistributionMetadataChanged"]];
 maps=Lookup[compact,"SourceToRetainedDefinitionIndices",<||>];
 counts=Association@Table[kind->Length[Lookup[compact,kind<>"Definitions",{}]],{kind,kinds}];
 If[!AllTrue[kinds,KeyExistsQ[maps,#]&&VectorQ[maps[#],IntegerQ]&&
    Length[maps[#]]===Length[Lookup[source,#<>"Definitions",{}]]&&
    AllTrue[maps[#],Between[{0,counts[#]}]]&],distributionCompactFail["InvalidSourceToRetainedIndices"]];
 Do[field=kind<>"Definitions";
  If[Lookup[compact[field],"Index",{}]=!=Range[counts[kind]],
   distributionCompactFail["CompactedDefinitionIndicesChanged",<|"Type"->kind|>]],{kind,{"Kernel","Integral"}}];
 (* A dummy unused distinct index represents all discarded definitions. *)
 oldMaps=Association@Table[kind->(maps[kind] /. 0 ->(counts[kind]+1)),{kind,kinds}];
 retained=Association@Table[kind->Range[counts[kind]],{kind,kinds}];
 prepared=Join[KeyTake[compact,{"KernelDefinitions","IntegralDefinitions","AlgebraicDefinitions","DefinitionSemanticContexts"}],
  <|"Expressions"->compact["ColorComponents"],"Compaction"-><|"OriginalToDistinctIndices"->oldMaps,
    "DistinctCountsBeforePruning"->Map[# + 1&,counts],"RetainedDistinctIndices"->retained|>|>];
 result=FeynFacetSolution`VerifyFiniteSolutionCompaction[source,source["ColorComponents"],prepared];
 If[FailureQ[result],distributionCompactFail["SavedDistributionCompactionNotVerified",<|"Cause"->result|>]];
 Join[KeyDrop[result,"OriginalToRetainedIndices"],<|"RetainedMetadata"->"Exact source equality"|>]
 ],"DistributionCompaction"];
PartonicResultFromEndpointDensity[source_Association,metadata_Association]:=Catch[Module[
 {components,range,z,interval,alpha,cs,plusOrders,componentRow,weight,rows,definitions,meta},
 If[!ContainsAll[Keys[source],{"EpsilonOrderRange","NormalVariable","Interval","DimensionalRegulator"}]||
   !ContainsAll[Keys[metadata],{"Order","Contribution","Scale","Variables","DensityConvention"}],
  partonicResultFail["EndpointResultMetadataRequired"]];
 range=source["EpsilonOrderRange"];z=source["NormalVariable"];interval=source["Interval"];
 If[First[interval]=!=0||Last[metadata["Variables"]]=!=z,partonicResultFail["EndpointResultCoordinatesMismatch"]];
 components=Lookup[source,"ColorComponents",{Join[source,<|"ColorFactor"->1,"CouplingPower"->0,"ExternalFactor"->1|>]}];
 alpha=Lookup[metadata,"Coupling",1];
 If[!AllTrue[components,ContainsAll[Keys[#],{"DeltaTerms","PlusTerms","RegularRemainderCoefficients"}]&]||
  !AllTrue[Flatten[Lookup[components,"DeltaTerms"],1],#["DerivativeOrder"]===0&]||
  !AllTrue[Flatten[Lookup[components,"PlusTerms"],1],#["Power"]===-1&&#["SubtractionOrder"]===1&],
  partonicResultFail["StandardDeltaAndLogarithmicPlusBasisRequired"]];
 plusOrders=Union[Lookup[Flatten[Lookup[components,"PlusTerms"],1],"LogPower",{}]];
 componentRow[c_,j_]:=Module[{delta,plus,regular,factor},
  factor=c["ColorFactor"] alpha^c["CouplingPower"] c["ExternalFactor"];
  delta=Total[Lookup[#["Coefficients"],j,0]& /@ c["DeltaTerms"]];
  plus=Association@Table[k->Total[Lookup[#["Coefficients"],j,0]& /@
    Select[c["PlusTerms"],#["LogPower"]===k&]],{k,plusOrders}];
  regular=Lookup[c["RegularRemainderCoefficients"],j,0];
  partonicMap[factor #&,partonicDistribution[delta,plus,regular]]];
 cs=Association@Table[j->Module[{rr=componentRow[#,j]& /@ components},
  partonicDistribution[Total[Lookup[rr,"DeltaCoefficient"]],
   Association@Table[k->Total[Lookup[#["PlusCoefficients"],k,0]& /@ rr],{k,plusOrders}],Total[Lookup[rr,"RegularCoefficient"]]]],
  {j,First[range],Last[range]}];
 definitions=KeyTake[source,{"AlgebraicDefinitions","IntegralDefinitions","KernelDefinitions","DefinitionSemanticContexts"}];
 meta=Join[KeyDrop[source,{"Format","Coefficients","Expression","DeltaTerms","PlusTerms","RegularRemainderCoefficients",
  "ColorComponents","InteriorCoefficients","SingularModelCoefficients","DistributionBasis","EpsilonRange","PlusConvention"}],
  metadata,definitions,<|"DimensionalRegulator"->source["DimensionalRegulator"],
  "DistributionBasis"-><|"Variable"->z,"Endpoint"->0,"Interval"->interval,"Distance"->z|>|>];
 CreatePartonicResult[cs,meta]],"PartonicResults"];

End[];EndPackage[];
