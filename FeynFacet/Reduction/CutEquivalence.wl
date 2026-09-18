
(* Exact equivalences of powered cut integrals under affine loop changes.
   Canonical loop coordinates are independent, positively oriented cut
   momenta. Only unit-Jacobian maps are used; uncut prescriptions, cut
   derivatives, external kinematics and normalization stay in the key.
   No equality is inferred from a denominator support or a mode label. *)

Clear[FindCutIntegralEquivalences];
ClearAll[cutEquivalenceFamilyName, cutEquivalenceIntegral, cutEquivalenceVector,
  cutEquivalenceScalarProducts, cutEquivalenceTopology,
  cutEquivalenceFrames, cutEquivalenceSignature];

cutEquivalenceFamilyName[x_] := If[StringQ[x], x, SymbolName[x]];

cutEquivalenceIntegral[expr_] := Replace[expr,
  (h_Symbol)[f_, powers_List] /; SymbolName[h] === "GLI" :>
    FeynCalc`GLI[If[StringQ[f], f, SymbolName[f]], powers]];

cutEquivalenceVector[q_, momenta_List] := Module[{v},
  v = Coefficient[Expand[q], #] & /@ momenta;
  If[! VectorQ[v, MatchQ[#, _Integer | _Rational] &] ||
      Expand[q - v.momenta] =!= 0, Return[$Failed]];
  v
];

cutEquivalenceScalarProducts[expr_, momenta_List, gram_] :=
  Expand[expr /. FeynCalc`Pair[FeynCalc`Momentum[a_, ___],
      FeynCalc`Momentum[b_, ___]] :>
    With[{va = cutEquivalenceVector[a, momenta],
      vb = cutEquivalenceVector[b, momenta]},
      If[MemberQ[{va, vb}, $Failed], $Failed, va.gram.vb]]];

cutEquivalenceTopology[record_Association, normalization_] := Module[
  {top, momenta, loops, external, n, gram, descriptors, polynomials,
   kinematics, cutVectors, indices, directions, typed, validated, particles, cutTypes, particleIndices, dimensionTags, definitionData},
  typed=MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"},Lookup[record,"Format",None]];
  validated=If[typed,FeynFacet`CreateCutIntegralDefinition[record],record];
  If[!AssociationQ[validated],Return[$Failed]];
  top = Lookup[validated, "Topology", None];
  If[! MatchQ[top, _FeynCalc`FCTopology], Return[$Failed]];
  dimensionTags=DeleteDuplicates[Cases[{top[[2]],top[[5]]},
    FeynCalc`Momentum[_,tags___]:>{tags},Infinity]];
  (* Mixed projected and full-dimensional scalar products require an explicit
     projector algebra; a single Gram matrix cannot represent both. *)
  If[Length[dimensionTags]=!=1,Return[$Failed]];
  definitionData=cutDefinitionConventions[validated];
  loops = top[[3]]; external = top[[4]];
  momenta = Join[loops, external]; n = Length[momenta];
  gram = Table[cutScalarProduct[Min[i, j], Max[i, j]], {i, n}, {j, n}];
  descriptors = propagatorDescriptor[#, {}] & /@ top[[2]];
  If[MemberQ[descriptors, $Failed] || !AllTrue[descriptors,Lookup[#,"Power",None]===1&] ||
      Length[Cases[top[[2]], _FeynCalc`StandardPropagatorDenominator, Infinity]] =!= Length[top[[2]]], Return[$Failed]];
  polynomials = cutEquivalenceScalarProducts[#, momenta, gram] & /@
    Lookup[descriptors, "UnitCore"];
  kinematics = cutEquivalenceScalarProducts[#, momenta, gram] & /@ top[[5]];
  indices = Lookup[validated, "CutIndices", {}];
  If[typed,
    particles=Select[validated["Cuts"],#["Type"]==="Particle"&];
    particleIndices=Lookup[particles,"Index",{}];
    directions=Lookup[particles,"EnergyDirection",{}];
    cutTypes=Lookup[validated["Cuts"],"Type"];
    cutVectors=cutEquivalenceVector[#,momenta]&/@Lookup[particles,"Momentum",{}],
    particleIndices=indices;directions=Lookup[record,"CutDirections",{}];
    cutTypes=ConstantArray["Particle",Length[indices]];
    cutVectors=cutEquivalenceVector[#,momenta]&/@Lookup[record,"CutMomenta",{}]];
  If[Length[particleIndices] =!= Length[cutVectors] ||
      Length[directions] =!= Length[particleIndices] || ! DuplicateFreeQ[indices] ||
      ! AllTrue[indices, IntegerQ[#] && 1 <= # <= Length[polynomials] &] ||
      ! AllTrue[directions, MemberQ[{1, -1}, #] &] ||
      MemberQ[cutVectors, $Failed] || ! FreeQ[polynomials, $Failed],
    Return[$Failed]];
  <|"Family" -> cutEquivalenceFamilyName[top[[1]]], "Loops" -> loops,
    "External" -> external, "GramMatrix" -> gram,
    "KinematicRules" -> kinematics, "PropagatorPolynomials" -> polynomials,
    "Prescriptions" -> (Last[#[[4]]] & /@
      Cases[top[[2]], _FeynCalc`StandardPropagatorDenominator, Infinity]),
    "CutIndices" -> indices, "ParticleCutIndices"->particleIndices, "CutTypes"->cutTypes,
    "OrientedCutMomenta" -> MapThread[Times, {directions, cutVectors}],
    "DefinitionData" -> definitionData,"LorentzDimensionAnnotations"->First[dimensionTags],
    "LoopFrameChangesPermitted" -> (
      MemberQ[{None,{},True},Lookup[validated,"AdditionalAcceptanceBoundaries",None]]&&
      FreeQ[{definitionData,
        If[typed,validated["MeasurePrefactor"],Lookup[record,"Normalization",normalization]]},
       Alternatives@@loops]),
    "Normalization" -> If[typed,
     {validated["MeasurePrefactor"],Lookup[validated,"Dimension",D],
      validated["CutConvention"],validated["Definition"],Lookup[validated,"AdditionalAcceptanceBoundaries",None],
      Lookup[validated,"Assumptions",True],Lookup[validated,"TimeDirection",None]},
     Lookup[record,"Normalization",normalization]]|>
];

cutEquivalenceFrames[top_Association] := Module[
  {l, n, cuts, choices, frames = {}, a, b, t, mappedGram, rules},
  l = Length[top["Loops"]]; n = Length[top["GramMatrix"]];
  cuts = top["OrientedCutMomenta"];
  (* A loop-dependent measure or acceptance condition must itself be mapped.
     Without that map, require an identity frame in the same ordered loop
     coordinates. Index-space identity alone could relabel a restricted loop. *)
  If[!TrueQ[Lookup[top,"LoopFrameChangesPermitted",False]],
   Return[{<|"ChosenCutMomenta"->{},
     "LoopTransformation"->IdentityMatrix[n][[1;;l]],
     "CutMomenta"->cuts,
     "Polynomials"->(Expand[#/.top["KinematicRules"]]&/@top["PropagatorPolynomials"])|>}]];
  choices = Flatten[Permutations /@ Subsets[Range[Length[cuts]], {l}], 1];
  Do[
    a = cuts[[chosen, 1 ;; l]];
    If[! MemberQ[{1, -1}, Det[a]], Continue[]];
    b = cuts[[chosen, l + 1 ;; n]];
    t = Join[Join[Inverse[a], -Inverse[a].b, 2],
      Join[ConstantArray[0, {n - l, l}], IdentityMatrix[n - l], 2]];
    mappedGram = Expand[t.top["GramMatrix"].Transpose[t]];
    rules = DeleteDuplicates[Thread[
      Flatten[top["GramMatrix"]] -> Flatten[mappedGram]]];
    AppendTo[frames, <|"ChosenCutMomenta" -> chosen,
      "LoopTransformation" -> t[[1 ;; l]],
      "CutMomenta" -> (Expand[#.t] & /@ cuts),
      "Polynomials" -> (Expand[# /. rules /. top["KinematicRules"]] & /@
        top["PropagatorPolynomials"])|>],
    {chosen, choices}];
  frames
];

cutEquivalenceSignature[integral_, top_, frames_] := Module[
  {powers, cuts, ordinary, candidates, key,cutRows,particleIndex},
  powers = integral[[2]]; cuts = top["CutIndices"];
  If[Length[powers] =!= Length[top["PropagatorPolynomials"]] ||
      ! VectorQ[powers, IntegerQ], Return[$Failed]];
  If[AnyTrue[cuts, powers[[#]] <= 0 &],
    Return[<|"Zero" -> True, "Key" -> {"MissingReverseUnitarityCut"}|>]];
  If[frames === {}, Return[<|"Zero" -> False,
    "Key" -> {"UnmappedIntegral", integral}, "Frame" -> Missing["CutRank"]|>]];
  ordinary = Complement[Range[Length[powers]], cuts];
  candidates = Table[
    key = {top["External"], Sort[top["KinematicRules"]],
      top["Normalization"],Lookup[top,"DefinitionData",<||>],Lookup[top,"LorentzDimensionAnnotations",None],
      If[TrueQ[Lookup[top,"LoopFrameChangesPermitted",False]],None,top["Loops"]],
      Sort[MapIndexed[Function[{index,position},
        particleIndex=FirstPosition[top["ParticleCutIndices"],index,None,{1},Heads->False];
        {top["CutTypes"][[First[position]]],powers[[index]],frame["Polynomials"][[index]],
         If[particleIndex===None,None,Extract[frame["CutMomenta"],particleIndex]]}],cuts]],
      Sort[Select[Table[{frame["Polynomials"][[i]],
          top["Prescriptions"][[i]], powers[[i]]}, {i, ordinary}],
        Last[#] =!= 0 &]]};
    <|"Zero" -> False, "Key" -> key, "Frame" -> frame|>,
    {frame, frames}];
  First[SortBy[candidates, #["Key"] &]]
];

Options[FindCutIntegralEquivalences] = {
  "PreferredMasterIntegrals" -> {}, "Normalization" -> Automatic,
  "OrdinaryPrescriptionGeometry" -> None};

FindCutIntegralEquivalences[integrals_List, records_List,
    OptionsPattern[]] := Catch@Module[
  {ms, tops, selectedRecords, frames, signatures, groups, mappings = {},
   representatives = {}, preferred, rep, repSig, sig, original, fam,
   normalization = OptionValue["Normalization"], originalByIntegral},
  If[OptionValue["OrdinaryPrescriptionGeometry"]=!=None,
    Return[cutCertifiedPrescriptionEquivalences[integrals,records,
      OptionValue["OrdinaryPrescriptionGeometry"],normalization,
      OptionValue["PreferredMasterIntegrals"]]]];
  If[normalization === Automatic,
    Throw[Failure["NormalizationRequired", <|
      "MessageTemplate" -> "Supply the common integral normalization explicitly."|>]]];
  ms = cutEquivalenceIntegral /@ integrals;
  If[! AllTrue[ms, MatchQ[#, FeynCalc`GLI[_String, {_Integer ..}]] &] ||
      ! DuplicateFreeQ[ms], Throw[Failure["InvalidMasterIntegrals", <||>]]];
  originalByIntegral=AssociationThread[ms,integrals];
  preferred = cutEquivalenceIntegral /@ OptionValue["PreferredMasterIntegrals"];
  selectedRecords = Select[records,
    MemberQ[DeleteDuplicates[ms[[All, 1]]], cutEquivalenceFamilyName[#["Topology"][[1]]]] &];
  tops = cutEquivalenceTopology[#, normalization] & /@ selectedRecords;
  If[MemberQ[tops, $Failed], Throw[Failure["UnsupportedCutTopology", <||>]]];
  If[!DuplicateFreeQ[Lookup[tops,"Family"]],
    Throw[Failure["DistinctCutEquivalenceFamilyNamesRequired",<||>]]];
  tops = Association[(#["Family"] -> #) & /@ tops];
  If[Complement[ms[[All, 1]], Keys[tops]] =!= {},
    Throw[Failure["MissingCutTopology", <||>]]];
  frames = cutEquivalenceFrames /@ tops;
  signatures = Association[Table[
    fam = m[[1]]; sig = cutEquivalenceSignature[m, tops[fam], frames[fam]];
    If[sig === $Failed, Throw[Failure["InvalidPoweredCutIntegral", <|"Integral" -> m|>]]];
    m -> sig, {m, ms}]];
  groups = GatherBy[ms, signatures[#]["Key"] &];
  representatives=Map[Function[group,
    First[SortBy[group,{If[MemberQ[preferred,#],0,1]&,LeafCount,ToString[#,InputForm]&}]]],groups];
  mappings=Flatten[MapThread[Function[{group,representative},
    Map[Function[member,
      <|"Source"->originalByIntegral[member],
        "Representative"->originalByIntegral[representative],
        "Factor"->If[TrueQ[signatures[member]["Zero"]],0,1],
        "SourceFrame"->KeyTake[Replace[Lookup[signatures[member],"Frame",<||>],_Missing-><||>],
          {"ChosenCutMomenta","LoopTransformation"}],
        "RepresentativeFrame"->KeyTake[Replace[Lookup[signatures[representative],"Frame",<||>],_Missing-><||>],
          {"ChosenCutMomenta","LoopTransformation"}]|>],group]],{groups,representatives}],1];
  <|"DataType" -> "CutIntegralEquivalences", "SchemaVersion" -> 1,
    "Method" -> "ExactAffineLoopMomentumChanges",
    "InputCount" -> Length[ms], "EquivalenceClassCount" -> Length[groups],
    "Normalization" -> normalization, "Mappings" -> mappings,
    "RepresentativeMasterIntegrals" ->
      (originalByIntegral /@ representatives),
    "UnmappedMasterIntegrals" ->
      Select[ms, MatchQ[Lookup[signatures[#], "Frame", None], _Missing] &],
    "MinimalIBPMasterCountDetermined" -> False|>
];


(* The existing compact-cut certificate is applied separately to each powered
   integral. A certificate for the original source product is not transferred
   to its partial fractions. These are generic-kinematic identities only. *)
cutCertifiedPrescriptionEquivalences[integrals_List,records_List,geometry_,
 normalization_,preferred_List]:=Catch[Module[
 {families,certificates=<||>,certificate,family,top,props,normalized,result,name},
 If[!AssociationQ[geometry]||normalization===Automatic,
  Throw[Failure["ExplicitPrescriptionGeometryAndNormalizationRequired",<||>]]];
 If[Lookup[geometry,"PrescriptionScope","GenericKinematics"]=!="GenericKinematics",
  Throw[Failure["JointEndpointPrescriptionEqualityNotEstablished",<||>]]];
 If[!AllTrue[records,AssociationQ]||!AllTrue[integrals,MatchQ[#,_FeynCalc`GLI]&],
  Throw[Failure["TypedPrescribedCutIntegralsRequired",<||>]]];
 families=Association[(#["Topology"][[1]]->#)&/@records];
 If[Length[families]=!=Length[records],
  Throw[Failure["DistinctCutEquivalenceFamilyNamesRequired",<||>]]];
 Do[
  family=Lookup[families,master[[1]],Missing[]];
  If[!AssociationQ[family],Throw[Failure["MissingCutTopology",<|"Integral"->master|>]]];
  certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[family,master,
    Join[KeyTake[family,{"MeasurementVariable","ReferenceMomentum","TaggedMomentum"}],geometry]];
  If[!AssociationQ[certificate]||
    FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
   Throw[Failure["PoweredIntegralPrescriptionLimitRequired",<|"Integral"->master,"Cause"->certificate|>]]];
  AssociateTo[certificates,master->certificate],
 {master,integrals}];
 normalized=Map[Function[record,
  top=record["Topology"];
  props=MapIndexed[If[MemberQ[record["CutIndices"],First[#2]],#1,
    #1/.FeynCalc`StandardPropagatorDenominator[a_,b_,c_,{power_,eta_}]:>
      FeynCalc`StandardPropagatorDenominator[a,b,c,{power,1}]]&,top[[2]]];
  FeynFacet`CreateCutIntegralFamily[Join[record,<|"Topology"->ReplacePart[top,2->props]|>]]
 ],Select[records,MemberQ[First/@integrals,#["Topology"][[1]]]&]];
 If[!AllTrue[normalized,AssociationQ],Throw[Failure["NormalizedTypedCutFamiliesRequired",<||>]]];
 result=FindCutIntegralEquivalences[integrals,normalized,
  "Normalization"->normalization,"PreferredMasterIntegrals"->preferred];
 If[!AssociationQ[result],Throw[result]];
 Join[result,<|"Method"->"CertifiedOrdinaryPrescriptionLimitsAndExactAffineLoopChanges",
  "OrdinaryPrescriptionCertificates"->certificates,
  "OriginalIntegralDefinitions"->Select[records,MemberQ[First/@integrals,#["Topology"][[1]]]&],
  "OrdinaryPrescriptionEqualityScope"->"GenericKinematics",
  "ExternalEndpointUniformityEstablished"->False,
  "Scope"->"Equality of the stated powered integrals at generic external kinematics. Measurement-distribution scope is recorded by each certificate. No joint external-endpoint distribution identity is asserted."|>]
]];


(* Family names belong to a catalog, not to the integral definition. Give
   independently generated catalogs disjoint internal names before matching. *)
MatchCutIntegralCatalogs[source_Association, target_Association] := Catch[Module[
 {catalogs={source,target},renamed,restore=<||>,all,preferred,equivalences,
  mappings={},unmatched={},rules={},normalization,prepare,sourceIDs,targetIDs,
  destinations,destination,src,dst},
 If[!AllTrue[catalogs,ContainsAll[Keys[#],{"Integrals","Families","Normalization"}]&&
     ListQ[#["Integrals"]]&&ListQ[#["Families"]]&],
  Throw[Failure["CutIntegralCatalogRequired",<||>]]];
 normalization=source["Normalization"];
 If[MemberQ[{Automatic,None},normalization]||MissingQ[normalization]||normalization=!=target["Normalization"],
  Throw[Failure["CutIntegralCatalogNormalizationMismatch",<||>]]];
 prepare[catalog_,prefix_] := Module[{families,names,ids,integrals,records,selected},
  families=catalog["Families"];
  If[!AllTrue[families,AssociationQ[#]&&MatchQ[Lookup[#,"Topology",None],_FeynCalc`FCTopology]&],
   Throw[Failure["CutIntegralCatalogFamiliesRequired",<||>]]];
  names=cutEquivalenceFamilyName[#["Topology"][[1]]]&/@families;
  If[!DuplicateFreeQ[names],Throw[Failure["DistinctCutEquivalenceFamilyNamesRequired",<||>]]];
  ids=AssociationThread[names,Table[prefix<>ToString[j],{j,Length[names]}]];
  integrals=cutEquivalenceIntegral/@catalog["Integrals"];
  If[!AllTrue[integrals,MatchQ[#,FeynCalc`GLI[_String,{_Integer..}]]&]||
     !DuplicateFreeQ[integrals]||!ContainsAll[names,First/@integrals],
   Throw[Failure["InvalidCatalogMasterIntegrals",<||>]]];
  MapThread[Function[{canonical,original},
    AssociateTo[restore,FeynCalc`GLI[ids[canonical[[1]]],canonical[[2]]]->original]],
   {integrals,catalog["Integrals"]}];
  records=Map[Function[record,With[{id=ids[cutEquivalenceFamilyName[record["Topology"][[1]]]]},
    Join[record,<|"Name"->id,"Topology"->ReplacePart[record["Topology"],1->id]|>]]],families];
  selected=cutEquivalenceIntegral/@Lookup[catalog,"PreferredIntegrals",catalog["Integrals"]];
  If[!ListQ[selected]||!ContainsAll[integrals,selected],
   Throw[Failure["PreferredCatalogIntegralsMissing",<||>]]];
  <|"Integrals"->(FeynCalc`GLI[ids[#[[1]]],#[[2]]]&/@integrals),"Families"->records,
    "PreferredIntegrals"->(FeynCalc`GLI[ids[#[[1]]],#[[2]]]&/@selected)|>
 ];
 renamed={prepare[source,"SourceCatalog"],prepare[target,"TargetCatalog"]};
 sourceIDs=renamed[[1]]["Integrals"];targetIDs=renamed[[2]]["Integrals"];
 all=Join[sourceIDs,targetIDs];preferred=renamed[[2]]["PreferredIntegrals"];
 equivalences=FindCutIntegralEquivalences[all,Join@@Lookup[renamed,"Families"],
   "PreferredMasterIntegrals"->targetIDs,"Normalization"->normalization];
 If[FailureQ[equivalences],Throw[equivalences]];
 destinations=Map[First@SortBy[#,If[MemberQ[preferred,#["Source"]],0,1]&]&,
  GroupBy[Select[equivalences["Mappings"],MemberQ[targetIDs,#["Source"]]&],#["Representative"]&]];
 Do[
  src=entry["Source"];dst=entry["Representative"];
  If[!MemberQ[sourceIDs,src],Continue[]];
  If[entry["Factor"]===0,
   AppendTo[rules,restore[src]->0];
   AppendTo[mappings,Join[entry,<|"Source"->restore[src],"Representative"->None|>]],
   If[KeyExistsQ[destinations,dst],
    destination=destinations[dst];dst=destination["Source"];
    AppendTo[rules,restore[src]->restore[dst]];
    AppendTo[mappings,Join[entry,<|"Source"->restore[src],"Representative"->restore[dst],
      "RepresentativeFrame"->destination["SourceFrame"]|>]],
    AppendTo[unmatched,restore[src]]]],
 {entry,equivalences["Mappings"]}];
 <|"DataType"->"CutIntegralCatalogMatch","SchemaVersion"->1,
   "Status"->If[unmatched==={},"Complete","UnmatchedIntegralsRemain"],
   "Normalization"->normalization,"Rules"->rules,"Mappings"->mappings,
   "UnmatchedIntegrals"->unmatched,"SourceCount"->Length[sourceIDs],
   "TargetCount"->Length[targetIDs],"Method"->equivalences["Method"],
   "Scope"->"Exact powered-integral definitions under unit-Jacobian loop changes. No prescription removal or endpoint distribution extension is inferred."|>
]];
