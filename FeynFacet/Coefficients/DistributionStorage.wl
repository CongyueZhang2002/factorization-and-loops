(* Final color-resolved distribution storage. Shared definitions contain
   the actual finite expressions; discarded fields are redundant views. *)
BeginPackage["FeynFacet`"];
CompactFiniteDistributionResult::usage="CompactFiniteDistributionResult[source] retains explicit color-resolved delta/plus/regular coefficients and their closed shared definitions, with exact index-correspondence checks. CompactFiniteDistributionResult[source,prepared] accepts a prepared CompactFiniteSolutionDefinitions result but independently verifies it. Source domains, branch data, normalization and order declarations are preserved.";
VerifyFiniteDistributionCompaction::usage="VerifyFiniteDistributionCompaction[source,compact] checks a saved compact distribution against its source, including every retained definition, full output, semantic contexts and retained metadata. Use in a fresh kernel to check serialization without reevaluating integrals.";
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
End[];EndPackage[];
