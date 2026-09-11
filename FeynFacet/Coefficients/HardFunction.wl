(* Weighted physical cut contributions in the common final coefficient format.
   Scalar master identities are applied before exact terms are combined. *)

(* (-1) per ghost-antighost pair among the outgoing partons. *)
assemblyGhostSign[setup_Association] := Module[
  {partons, outgoing, ghostCount},
  partons = Lookup[setup, "Partons", Missing["NotFound"]];
  If[! MatchQ[partons, Rule[_List, _List]], Return[$Failed]];
  outgoing = Last[partons];
  ghostCount = Count[
    outgoing,
    field_ /; ! FreeQ[Hold[field], FeynArts`U]
  ];
  If[OddQ[ghostCount], Return[$Failed]];
  (-1)^(ghostCount/2)
];

assemblyWeight[setup_Association] := Module[{symmetry, sign},
  symmetry = IdenticalParticleSymmetryFactor[setup];
  sign = assemblyGhostSign[setup];
  If[symmetry === $Failed || sign === $Failed,
    $Failed,
    symmetry sign
  ]
];

(* Incoming species and observed outgoing species identify the physical
   channel. Unobserved species may differ in a gluon/ghost completion. *)
assemblyPhysicalPartons[setup_Association] := Module[{partons,hadrons,observed},
 partons=Lookup[setup,"Partons",None];hadrons=Lookup[setup,"HadronMomentum",None];
 If[!MatchQ[partons,Rule[_List,_List]] || !MatchQ[hadrons,Rule[_List,_List]] ||
   (Length /@ (List@@partons))=!=(Length /@ (List@@hadrons)),
  coefficientAssemblyFail["PhysicalPartonDefinitionsRequired"]];
 observed=Select[Range[Length[Last[partons]]],
   !MissingQ[Last[hadrons][[#]]] && Last[hadrons][[#]]=!=FeynFacet`NA&];
 <|"IncomingPartons"->First[partons],
   "ObservedOutgoingPartons"->Association@Table[j->Last[partons][[j]],{j,observed}]|>
];
assemblySameQ[first_, second_] := TrueQ[SameQ[first, second] || exactZeroQ[first - second]];
coefficientTopologyMetadata[t_Association]:=cutTopologyDefinitionMetadata[t];
coefficientTopologyRecords[records_List,source_:False]:=Module[{normalized,names},
 normalized=normalizeCutTopologyRecord/@records;
 If[AnyTrue[normalized,FailureQ],coefficientAssemblyFail["InvalidIntegralTopologyDefinition",
  <|"Causes"->Select[normalized,FailureQ]|>]];
 names=If[StringQ[#],#,SymbolName[#]]&/@(#[["Topology",1]]&/@normalized);
 If[TrueQ[source]&&!DuplicateFreeQ[names],
  coefficientAssemblyFail["DuplicateSourceTopologyNames"]];
 normalized
];
assemblyPhysicalProjection[record_Association]:=Module[{setup,observed,fields,projection,parts,value,context},
 setup=record["Definitions"]["Setup"];
 observed=Keys[assemblyPhysicalPartons[setup]["ObservedOutgoingPartons"]];
 parts=setup["Partons"];projection=<||>;
 fields={"HadronLongSpin","HadronTransSpin","HadronLongDirection","HadronDualDirection"};
 Do[If[KeyExistsQ[setup,field],
  value=setup[field];
  If[!MatchQ[value,Rule[_List,_List]]||(Length/@(List@@value))=!=(Length/@(List@@parts)),
   coefficientAssemblyFail["PhysicalPolarizationProjectionRequired",<|"Field"->field|>]];
  AssociateTo[projection,field->{First[value],Last[value][[observed]]}]],{field,fields}];
 context=Lookup[record["Definitions"],"AnalyticContext",<||>];
 Join[projection,KeyTake[setup,{"SetDistributionZero","Gamma5Scheme","DimensionRule"}],
  <|"AnalyticConventions"->KeyTake[context,{"Gamma5Scheme","LoopDimension","DimensionRule",
    "CutConvention","DistributionConvention","GlobalBasis","GlobalBasisGram","SetEvanescentZero"}]|>]
];

(* Combining terms with a common prefactor avoids expanding the large
   rational functions. A zero finite prefix retains its unknown remainder. *)
coefficientCombineTerms[terms_List] := Module[{groups,combine,all},
 groups=Values@GroupBy[terms,Function[t,{t["PreFactor"],t["Representation"],
   If[t["Representation"]==="LaurentSeries",t["Coefficient"]["SeriesTruncation"],None],
   Lookup[t,"LaurentRemainderClass",None]}]];
 combine[group_] := Module[{first=First[group],orders,low,high,e,coeff},
  If[first["Representation"]==="Exact",
   Return[Join[first,<|"Coefficient"->Total[Lookup[group,"Coefficient"]]|>]]];
  e=first["Coefficient"]["SeriesVariable"];high=first["Coefficient"]["SeriesTruncation"];
  orders=(#["Coefficient"]["Orders"]&/@group);low=Min[First[Keys[#]]&/@orders];
  coeff=Association@Table[k->Total[Lookup[#,k,0]&/@orders],{k,low,high}];
  Join[first,<|"Coefficient"-><|"SeriesVariable"->e,"Orders"->coeff,"SeriesTruncation"->high|>|>]
 ];
 all=combine/@groups;Select[all,!coefficientExactZeroTermQ[#]&]
];

Options[AssembleCutContributions]={"MasterIntegralRules"->{},"MasterIntegralRulesByContribution"->Automatic,"TargetTopologies"->Automatic,"TargetCatalog"->Automatic,
 "Weights"->Automatic,"AdditionalFactor"->1};
AssembleCutContributions[items_List,OptionsPattern[]] := Catch[Module[
 {contributions,weights=OptionValue["Weights"],reference,e,rules=OptionValue["MasterIntegralRules"],
  topologyRecords=OptionValue["TargetTopologies"],byName,common,sourceFactor,
  grouped=<||>,representatives=<||>,remainders={},provenance={},parts,termList,metadata,masters,record,master,key,
  coefficient,terms,add,setupFields,physicalPartons,i,extra=OptionValue["AdditionalFactor"],definitions,
  maps,identity,sourceTopologies,sourceMetadata,ruleSets,perContribution=OptionValue["MasterIntegralRulesByContribution"],
  catalog=OptionValue["TargetCatalog"],boundCatalog=None,mapRecord,sourceRecords,projection},
 If[items==={},coefficientAssemblyFail["CoefficientContributionsRequired"]];
 contributions=FeynFacet`ReadMasterIntegralCoefficients/@items;
 If[AnyTrue[contributions,FailureQ],
  coefficientAssemblyFail["CoefficientContributionReadFailed",<|"Failures"->Select[contributions,FailureQ]|>]];
 reference=First[contributions];e=reference["DimensionalRegulator"];
 If[perContribution===Automatic,
  ruleSets=ConstantArray[rules,Length[contributions]],
  If[rules=!={}||!ListQ[perContribution]||Length[perContribution]=!=Length[contributions],
   coefficientAssemblyFail["OneMasterIntegralRuleSetPerContributionRequired"]];
  ruleSets=perContribution];
 Do[
  mapRecord=ruleSets[[i]];
  If[AssociationQ[mapRecord],
   If[Lookup[mapRecord,"DataType",None]=!="CutIntegralCatalogMatch"||
     Lookup[mapRecord,"Status",None]=!="Complete"||
     !ContainsAll[Keys[mapRecord],{"SourceDefinitions","SourceIntegrals","TargetCatalog","Rules"}]||
     mapRecord["SourceDefinitions"]=!=contributions[[i]]["Definitions"]||
     mapRecord["SourceIntegrals"]=!=Lookup[contributions[[i]]["Masters"],"Master"],
    coefficientAssemblyFail["MatchingCompleteSourceCatalogRequired",<|"ContributionIndex"->i|>]];
   If[!AssociationQ[mapRecord["TargetCatalog"]]||
     !ContainsAll[Keys[mapRecord["TargetCatalog"]],{"Families","Normalization","Integrals"}],
    coefficientAssemblyFail["BoundTargetIntegralCatalogRequired"]];
   If[boundCatalog===None,boundCatalog=mapRecord["TargetCatalog"],
    If[boundCatalog=!=mapRecord["TargetCatalog"],coefficientAssemblyFail["BoundTargetCatalogMismatch"]]];
   ruleSets[[i]]=mapRecord["Rules"]],
 {i,Length[ruleSets]}];
 If[boundCatalog=!=None,
  If[catalog===Automatic,catalog=boundCatalog,
   If[catalog=!=boundCatalog,coefficientAssemblyFail["BoundTargetCatalogMismatch"]]]];
 If[catalog=!=Automatic,
  If[!AssociationQ[catalog]||!ListQ[Lookup[catalog,"Families",None]],
   coefficientAssemblyFail["TargetIntegralCatalogRequired"]];
  If[topologyRecords===Automatic,topologyRecords=catalog["Families"],
   If[topologyRecords=!=catalog["Families"],coefficientAssemblyFail["BoundTargetTopologyMismatch"]]]];
 If[!AllTrue[ruleSets,ListQ[#]&&AllTrue[#,MatchQ[#,_Rule]&]&]||
   !coefficientExactDataQ[Last/@#&/@ruleSets],
  coefficientAssemblyFail["ExactMasterIntegralRulesRequired"]];
 ruleSets=coefficientRegulatorNormalize[ruleSets,e];
 If[!AllTrue[ruleSets,DuplicateFreeQ[coefficientMasterID/@(First/@#)]&],
  coefficientAssemblyFail["DuplicateMasterIntegralRules"]];
 If[weights===Automatic,weights=assemblyWeight[#["Definitions"]["Setup"]]&/@contributions];
 If[!ListQ[weights]||Length[weights]=!=Length[contributions]||
   !coefficientExactDataQ[{weights,extra}],
  coefficientAssemblyFail["ExactContributionWeightsRequired"]];
 physicalPartons=assemblyPhysicalPartons[reference["Definitions"]["Setup"]];
 projection=assemblyPhysicalProjection[reference];
 setupFields={"PartonMomentum","PhaseSpaceMomentum","PartonIntegrated","MomentumFraction","HadronMomentum"};
 Do[
  If[assemblyPhysicalPartons[c["Definitions"]["Setup"]]=!=physicalPartons,
   coefficientAssemblyFail["ContributionPhysicalPartonsMismatch",
    <|"CardName"->Lookup[c["Definitions"],"CardName",None]|>]];
  If[assemblyPhysicalProjection[c]=!=projection,
   coefficientAssemblyFail["ContributionPolarizationOrConventionMismatch"]];
  If[KeyTake[c["Definitions"]["Setup"],setupFields]=!=KeyTake[reference["Definitions"]["Setup"],setupFields]||
    !assemblySameQ[c["FractionMeasure"],reference["FractionMeasure"]]||
    !assemblySameQ[c["PhaseSpace"],reference["PhaseSpace"]],
   coefficientAssemblyFail["ContributionMeasureOrKinematicsMismatch",
    <|"CardName"->Lookup[c["Definitions"],"CardName",None]|>]],
 {c,Rest[contributions]}];
 If[topologyRecords===Automatic,
  topologyRecords=Flatten[Lookup[Lookup[contributions,"Definitions"],"Topologies",{}],1]];
 If[!ListQ[topologyRecords]||!AllTrue[topologyRecords,AssociationQ],
  coefficientAssemblyFail["TargetTopologyDefinitionsRequired"]];
 topologyRecords=coefficientTopologyRecords[topologyRecords];
 byName=Association[];
 Do[
  If[!KeyExistsQ[t,"Topology"],coefficientAssemblyFail["TopologyDefinitionMissing"]];
  key=If[StringQ[t["Topology"][[1]]],t["Topology"][[1]],SymbolName[t["Topology"][[1]]]];
  metadata=coefficientTopologyMetadata[t];
  If[KeyExistsQ[byName,key]&&coefficientTopologyMetadata[byName[key]]=!=metadata,
   coefficientAssemblyFail["InconsistentTargetTopology",<|"Family"->key|>]];
  AssociateTo[byName,key->t],
 {t,topologyRecords}];
 common=If[reference["PreFactor"]===0,1,reference["PreFactor"]];
 add[target_,factor_,sourceTerms_] := Module[{targetKey=coefficientMasterID[target],newTerms},
  newTerms=Join[#,<|"PreFactor"->factor #["PreFactor"]|>]&/@sourceTerms;
  If[!KeyExistsQ[representatives,targetKey],AssociateTo[representatives,targetKey->target]];
  If[KeyExistsQ[grouped,targetKey],
   AssociateTo[grouped,targetKey->Join[grouped[targetKey],newTerms]],
   AssociateTo[grouped,targetKey->newTerms]]];
 Do[
  record=contributions[[i]];sourceFactor=weights[[i]] record["PreFactor"]/common;
  maps=Association[(coefficientMasterID[First[#]]->coefficientCanonicalMasterExpression[Last[#]])&/@ruleSets[[i]]];
  sourceRecords=coefficientTopologyRecords[Lookup[record["Definitions"],"Topologies",{}],True];
  sourceTopologies=Association[
   (With[{name=#["Topology"][[1]]},If[StringQ[name],name,SymbolName[name]]]->#)&/@sourceRecords];
  Do[
   master=entry["Master"];identity=coefficientMasterID[master];
   If[!KeyExistsQ[maps,identity],
    If[!KeyExistsQ[sourceTopologies,First[identity]]||!KeyExistsQ[byName,First[identity]]||
      coefficientTopologyMetadata[sourceTopologies[First[identity]]]=!=coefficientTopologyMetadata[byName[First[identity]]],
     coefficientAssemblyFail["UnmappedMasterTopologyMismatch",<|"Master"->master|>]]];
   parts=linearIntegralSum[If[KeyExistsQ[maps,identity],maps[identity],master]];
   If[FailureQ[parts],coefficientAssemblyFail["MasterIntegralMapNotLinear",<|"Master"->master,"Result"->parts|>]];
   KeyValueMap[add[#1,sourceFactor #2,entry["Terms"]]&,parts["Terms"]];
   If[parts["Remainder"]=!=0,remainders=Join[remainders,
    (Join[#,<|"PreFactor"->sourceFactor parts["Remainder"] #["PreFactor"]|>]&/@entry["Terms"])]],
  {entry,record["Masters"]}];
  remainders=Join[remainders,(Join[#,<|"PreFactor"->sourceFactor #["PreFactor"]|>]&/@record["RemainderTerms"])];
  AppendTo[provenance,<|"CardName"->Lookup[record["Definitions"],"CardName",None],
    "Source"->record["Source"],"Weight"->weights[[i]],"MasterCount"->Length[record["Masters"]],
    "ExactZeroMasterIntegrals"->record["ExactZeroMasterIntegrals"],
    "InputFormat"->record["InputFormat"]|>],
 {i,Length[contributions]}];
 masters=KeyValueMap[Function[{identity,sourceTerms},
   terms=coefficientCombineTerms[sourceTerms];
   If[terms==={},Nothing,
    If[!KeyExistsQ[byName,First[identity]],
     coefficientAssemblyFail["MappedMasterTopologyMissing",<|"Master"->identity|>]];
    metadata=byName[First[identity]];
    <|"Master"->representatives[identity],"Terms"->terms,
      "TopologyName"->First[identity],"CutMomenta"->Lookup[metadata,"CutMomenta",{}],
      "CutIndices"->Lookup[metadata,"CutIndices",{}],"CutDirections"->Lookup[metadata,"CutDirections",{}]|>]],
  grouped];
 masters=SortBy[masters,coefficientMasterID[#["Master"]]&];
 definitions=Join[reference["Definitions"],<|"Topologies"->Values[byName]|>];
 <|"Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
   "DimensionalRegulator"->e,"PreFactor"->common extra,
   "FractionMeasure"->reference["FractionMeasure"],"PhaseSpace"->reference["PhaseSpace"],
   "Masters"->masters,"RemainderTerms"->coefficientCombineTerms[remainders],
   "Definitions"->definitions,"Variables"->DeleteDuplicates@Flatten[Lookup[contributions,"Variables",{}]],
   "CompleteTargetSet"->True,"ExactZeroMasterIntegrals"->{},
   "Contributions"->provenance,"MasterIntegralRulesByContribution"->ruleSets,"TargetCatalog"->catalog,
   "AdditionalFactor"->extra,"Status"->"CutContributionsAssembled",
   "CoefficientConvention"->"NormalizedGLI","PhysicalMasterNormalizationApplied"->False|>
 ],"CoefficientAssembly"];
AssembleCutContributions[arguments___] :=
 Failure["CoefficientContributionsRequired",<|"Arguments"->HoldForm[arguments]|>];
