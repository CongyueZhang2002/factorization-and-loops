# Exact cut-catalog matching and source-specific coefficient assembly

Verified model: gpt-6-pro. Conversation: 6aa2eb2d-5588-83e8-bf9d-d35cd8d66f3b. Request: ca247dfb-0789-41d2-a278-d149372c5a6f.

## Question

Please review these changes for concrete correctness defects, especially false integral equivalences or mixing source catalogs. This is a bounded code review; please do not propose proving the higher endpoint terms zero now.

The user requested a fresh ppHX UU NNLO double-real regeneration (u d -> observed u + d g g plus ghost subtraction). The user explicitly chose retaining higher delta derivatives and generalized plus terms. We regenerate coefficients, then reuse exactly matched bare master definitions/DE solutions with sufficient saved orders, and freshly contract all coefficient-dependent endpoint rows. We do not reuse old scalar endpoint contractions merely because their values agree at one point.

The 25 freshly regenerated ghost-family definitions exactly equal their old definitions. All 27 coefficient columns agree at three exact rational specializations (varying scale, regulator, SU(N) color, and formal coupling/Pi monomial parameters), with identical global measure/prefactor. This is a diagnostic, not an identity proof. The gluon generation is still running with seven subkernels plus one parent on eight cores; Wolfram tests for these new APIs are queued until kernels are free.

Current Git baseline is https://github.com/CongyueZhang2002/factorization-and-loops/commit/8bfd19c584a5f79a2090def3043bc1f55a03ca5d ; the code below is uncommitted and authoritative for this review.

The matching catalog contains bare normalized GLIs, not already gauge-rescaled solution components. Actual physical measure conversion and any per-master normalization are applied later from the exact saved physical definitions. Source catalogs have independent family names; the new wrapper creates disjoint internal names, matches powered off-shell polynomials, cut orientations and ordinary prescriptions, and restores original names separately. Domain declarations are now included in the exact key; extra/loop-dependent domain conditions permit only the identity frame. A passing match is not a new proof of prescription-removal uniformity at an external endpoint.

AssembleCutContributions now accepts one exact rule list per source contribution, preventing a source family called CF1 in the gluon reduction from sharing the ghost CF1 map. The CLI binds catalog-match records to source definitions/integrals and the exact target catalog.

Please identify actual defects and missing high-value tests in these files. In particular, inspect Wolfram pattern/scoping semantics, source/target preference handling, and whether the domain-data change is conservative and sound.



FILE: FeynFacet/Reduction/CutEquivalence.wl


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
   kinematics, cutVectors, indices, directions, typed, validated, particles, cutTypes, particleIndices},
  typed=MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"},Lookup[record,"Format",None]];
  validated=If[typed,FeynFacet`CreateCutIntegralDefinition[record],record];
  If[!AssociationQ[validated],Return[$Failed]];
  top = Lookup[validated, "Topology", None];
  If[! MatchQ[top, _FeynCalc`FCTopology], Return[$Failed]];
  loops = top[[3]]; external = top[[4]];
  momenta = Join[loops, external]; n = Length[momenta];
  gram = Table[cutScalarProduct[Min[i, j], Max[i, j]], {i, n}, {j, n}];
  descriptors = propagatorDescriptor[#, {}] & /@ top[[2]];
  If[MemberQ[descriptors, $Failed] ||
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
    "DomainData" -> KeyTake[validated,{"AdditionalAcceptanceBoundaries","Assumptions",
      "TimeDirection","CutConvention","Definition"}],
    "LoopFrameChangesPermitted" -> (
      MemberQ[{None,{},True},Lookup[validated,"AdditionalAcceptanceBoundaries",None]]&&
      FreeQ[{KeyTake[validated,{"Assumptions","TimeDirection"}],
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
     Until such a domain map is supplied, only the identity frame is valid. *)
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
      top["Normalization"],Lookup[top,"DomainData",<||>],
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
  certificate=FeynFacet`CertifyOrdinaryPrescriptionRemoval[family,master,geometry];
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


FILE: FeynFacet/Coefficients/HardFunction.wl

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
coefficientTopologyMetadata[t_Association] := Module[{top=t["Topology"],name},
 name=If[StringQ[top[[1]]],top[[1]],SymbolName[top[[1]]]];
 Join[KeyTake[t,{"CutMomenta","CutIndices","CutDirections"}],
  <|"Topology"->ReplacePart[top,1->name]|>]];

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

Options[AssembleCutContributions]={"MasterIntegralRules"->{},"MasterIntegralRulesByContribution"->Automatic,"TargetTopologies"->Automatic,
 "Weights"->Automatic,"AdditionalFactor"->1};
AssembleCutContributions[items_List,OptionsPattern[]] := Catch[Module[
 {contributions,weights=OptionValue["Weights"],reference,e,rules=OptionValue["MasterIntegralRules"],
  topologyRecords=OptionValue["TargetTopologies"],byName,common,sourceFactor,
  grouped=<||>,representatives=<||>,remainders={},provenance={},parts,termList,metadata,masters,record,master,key,
  coefficient,terms,add,setupFields,physicalPartons,i,extra=OptionValue["AdditionalFactor"],definitions,
  maps,identity,sourceTopologies,sourceMetadata,ruleSets,perContribution=OptionValue["MasterIntegralRulesByContribution"]},
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
 If[!AllTrue[ruleSets,ListQ[#]&&AllTrue[#,MatchQ[#,_Rule]&]&]||
   !FreeQ[(Last/@#&/@ruleSets),_Real|_Missing|_Failure|$Failed|Indeterminate|_DirectedInfinity|
     _SeriesData|_Series|_SeriesCoefficient],
  coefficientAssemblyFail["ExactMasterIntegralRulesRequired"]];
 ruleSets=coefficientRegulatorNormalize[ruleSets,e];rules=coefficientRegulatorNormalize[rules,e];
 If[!AllTrue[ruleSets,DuplicateFreeQ[coefficientMasterID/@(First/@#)]&],
  coefficientAssemblyFail["DuplicateMasterIntegralRules"]];
 If[weights===Automatic,weights=assemblyWeight[#["Definitions"]["Setup"]]&/@contributions];
 If[!ListQ[weights]||Length[weights]=!=Length[contributions]||
   !FreeQ[{weights,extra},_Real|_Missing|_Failure|$Failed|Indeterminate|_DirectedInfinity],
  coefficientAssemblyFail["ExactContributionWeightsRequired"]];
 physicalPartons=assemblyPhysicalPartons[reference["Definitions"]["Setup"]];
 setupFields={"PartonMomentum","PhaseSpaceMomentum","PartonIntegrated","MomentumFraction","HadronMomentum"};
 Do[
  If[assemblyPhysicalPartons[c["Definitions"]["Setup"]]=!=physicalPartons,
   coefficientAssemblyFail["ContributionPhysicalPartonsMismatch",
    <|"CardName"->Lookup[c["Definitions"],"CardName",None]|>]];
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
  sourceTopologies=Association[
   (With[{name=#["Topology"][[1]]},If[StringQ[name],name,SymbolName[name]]]->#)&/@
    Lookup[record["Definitions"],"Topologies",{}]];
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
   "Contributions"->provenance,"MasterIntegralRules"->rules,"MasterIntegralRulesByContribution"->ruleSets,
   "AdditionalFactor"->extra,"Status"->"CutContributionsAssembled",
   "CoefficientConvention"->"NormalizedGLI","PhysicalMasterNormalizationApplied"->False|>
 ],"CoefficientAssembly"];
AssembleCutContributions[arguments___] :=
 Failure["CoefficientContributionsRequired",<|"Arguments"->HoldForm[arguments]|>];


FILE: Scripts/Coefficients/assemble_cut_coefficients.wls

#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
(* General weighted assembly of retained coefficient files and exact maps. *)
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Addon/Load/LoadFACET.wl"];
args=Rest[$ScriptCommandLine];
If[Length[args]=!=1,Print["Expected ASSEMBLY_REQUEST.wl"];Exit[2]];
request=Get[ExpandFileName[First[args]]];
read[file_]:=If[ToLowerCase[FileExtension[file]]==="wxf",Import[file,"WXF"],Get[file]];
rules=If[KeyExistsQ[request,"MasterIntegralRulesFile"],read[request["MasterIntegralRulesFile"]],
 Lookup[request,"MasterIntegralRules",{}]];
If[AssociationQ[rules],rules=rules["Rules"]];
mapOptions={};topologyOptions={};
If[KeyExistsQ[request,"MasterIntegralRulesFiles"],
 mapFiles=request["MasterIntegralRulesFiles"];
 If[!ListQ[mapFiles]||Length[mapFiles]=!=Length[request["CoefficientFiles"]],
  Print["One master-map file per coefficient contribution is required"];Exit[2]];
 mapRecords=read/@mapFiles;perRules={};
 Do[
  mapRecord=mapRecords[[j]];
  If[AssociationQ[mapRecord]&&Lookup[mapRecord,"DataType",None]==="CutIntegralCatalogMatch",
   sourceRecord=FeynFacet`ReadMasterIntegralCoefficients[request["CoefficientFiles"][[j]]];
   If[FailureQ[sourceRecord]||mapRecord["Status"]=!="Complete"||
     mapRecord["SourceDefinitions"]=!=sourceRecord["Definitions"]||
     mapRecord["SourceIntegrals"]=!=Lookup[sourceRecord["Masters"],"Master"],
    Print["Master catalog match does not describe this complete coefficient input"];Exit[1]]];
  AppendTo[perRules,If[AssociationQ[mapRecord],Lookup[mapRecord,"Rules",None],mapRecord]],
 {j,Length[mapRecords]}];
 mapOptions={"MasterIntegralRulesByContribution"->perRules}];
If[KeyExistsQ[request,"TargetCatalogFile"],
 targetCatalog=read[request["TargetCatalogFile"]];
 If[!AssociationQ[targetCatalog]||!ListQ[Lookup[targetCatalog,"Families",None]]||
   KeyExistsQ[request,"TargetTopologies"],
  Print["Supply one explicit target topology catalog"];Exit[2]];
 If[ValueQ[mapRecords]&&!AllTrue[mapRecords,
   !AssociationQ[#]||Lookup[#,"DataType",None]=!="CutIntegralCatalogMatch"||
    Lookup[#,"TargetCatalog",None]===targetCatalog&],
  Print["Master maps refer to different target definitions"];Exit[1]];
 topologyOptions={"TargetTopologies"->targetCatalog["Families"]}];
elapsed=First[AbsoluteTiming[
 result=FeynFacet`AssembleCutContributions[request["CoefficientFiles"],
  "MasterIntegralRules"->rules,Sequence@@mapOptions,Sequence@@topologyOptions,
  Sequence@@Normal[KeyTake[request,{"Weights","AdditionalFactor","TargetTopologies"}]]]]];
If[FailureQ[result],Print[result];Exit[1]];
file=ExpandFileName[request["OutputFile"]];
If[!DirectoryQ[DirectoryName[file]],CreateDirectory[DirectoryName[file],CreateIntermediateDirectories->True]];
temporary=file<>".tmp";stream=OpenWrite[temporary,BinaryFormat->True];
BinaryWrite[stream,Normal[BinarySerialize[result,PerformanceGoal->"Size"]],"Byte"];
Close[stream];
If[Import[temporary,"WXF"]=!=result,Print["Coefficient serialization read-back failed"];Exit[1]];
RenameFile[temporary,file,OverwriteTarget->True];
summary=<|"Status"->result["Status"],"MasterCount"->Length[result["Masters"]],
 "TermCount"->Total[Length[#["Terms"]]&/@result["Masters"]],
 "LaurentTermCount"->Count[Flatten[Lookup[result["Masters"],"Terms"],1],t_Association/;t["Representation"]==="LaurentSeries"],
 "RemainderTermCount"->Length[result["RemainderTerms"]],
 "ContributionWeights"->Lookup[result["Contributions"],"Weight"],
 "ElapsedSeconds"->elapsed,"OutputFile"->file,"OutputBytes"->FileByteCount[file]|>;
Export[file<>".json",summary,"RawJSON"];Print["COMPLETED CUT ASSEMBLY ",summary];Exit[0];


## Pro response

The per-contribution rule separation is correct, but I would not accept these changes yet. Three concrete gaps can attach coefficients to the wrong integral definition: the restricted-frame domain comparison, the assembler’s incomplete definition comparison, and bypasses in the CLI’s catalog binding.

This is a static review of the supplied edits. I checked the relevant baseline validators and coefficient reader, but did not execute Wolfram tests.

1. P1: “Identity frame only” does not prevent an implicit loop permutation

Location: cutEquivalenceFrames and cutEquivalenceSignature.

Adding DomainData to the key is necessary, but the current restricted-frame branch is not fully sound.

The polynomials and cut momenta are expressed in positional coordinates determined by top["Loops"]. The domain expressions remain in their original momentum symbols. However, the signature does not include the ordered original loop list.

Consequently, these two records can receive identical signatures:

	Source	Target
Ordered loops	{q1,q2}	{q2,q1}
Ordered particle cuts	{q1,q2,P-q1-q2}	{q2,q1,P-q1-q2}
A numerator slot	p.q1	p.q2
Additional acceptance condition	p.q1 > p.P/2	p.q1 > p.P/2

Both take the identity-frame branch. Their positional cut vectors and numerator polynomials agree, and their literal DomainData agrees. Nevertheless, the implicit identification of the first loop coordinate exchanges q1 and q2, without exchanging them in the acceptance condition.

This is not merely an incomplete certificate. For three future massless momenta summing to P, put

x
i
	​

=
p⋅P
p⋅q
i
	​

	​

.

On the stated domain x
1
	​

>1/2, one has x
2
	​

<1/2. Integrating the numerator x
1
	​

 is therefore not equivalent to integrating x
2
	​

 over that same domain.

Minimal conservative correction: for a restricted frame, include a mode marker and the exact ordered loop-symbol list in the signature, for example

Wolfram Language
{"LiteralLoopFrame", top["Loops"]}

and prevent comparison with an unrestricted canonical-cut frame unless the complete domain transformation is established. Alternatively, canonicalize every loop-dependent domain and normalization expression under the same map—but that is more work than needed here.

The same issue applies to a loop-dependent normalization retained literally in the key.

One additional scope detail: at the stated baseline, CreateCutIntegralDefinition rejects every non-None AdditionalAcceptanceBoundaries value before your frame logic runs. Thus nontrivial acceptance-boundary support in this patch is currently reachable through the legacy/untyped path, not through that typed constructor. This is conservative rejection, not a false equivalence, but the tests should distinguish the two paths.

2. P1: Assembly still uses a weaker identity than catalog matching

Location: coefficientTopologyMetadata, the unmapped-master fallback, and construction of byName/sourceTopologies.

The matcher now distinguishes domain data, but the assembler compares only

Wolfram Language
{"CutMomenta", "CutIndices", "CutDirections", "Topology"}

through coefficientTopologyMetadata.

This omits typed "Cuts", "TimeDirection", "CutConvention", "Definition", assumptions, acceptance boundaries, and normalization/dimension declarations.

There are two concrete consequences.

An absent rule can silently become a false identity. Two typed records can have identical FCTopology and CutIndices, but different particle EnergyDirection inside "Cuts". If the legacy cut fields are absent, coefficientTopologyMetadata considers them identical. The unmapped branch then retains the source GLI under the target definition.

Duplicate target names can overwrite different definitions. byName accepts two records with the same family name when their reduced metadata agrees, even when their domain or typed cut definition differs. AssociateTo then retains the later record. Moreover, sourceTopologies is constructed directly as an association without any duplicate-name check; duplicate keys retain only the last value. 
Wolfram Documentation Center

Correction: use a common, conservative mathematical-definition comparison for identity fallback and duplicate-name checking. It need not search for affine equivalences: literal equality of validated, normalized defining data is sufficient. It must include the cut semantics and domain information that the matcher now protects.

Also reject duplicate normalized family names within each source before constructing sourceTopologies. The baseline coefficient reader checks duplicate master entries, but does not establish uniqueness of the topology catalog.

With complete explicitly bound maps, the identity fallback should be unnecessary. It must nevertheless remain safe when the API permits partial rule lists.

3. P1: CLI catalog binding can be bypassed in two ordinary request forms

Location: assemble_cut_coefficients.wls.

Singular map-file path discards the binding record

This line runs before any catalog validation:

Wolfram Language
If[AssociationQ[rules], rules = rules["Rules"]];

Thus a CutIntegralCatalogMatch supplied through "MasterIntegralRulesFile" loses its source and target bindings immediately. Neither the source check nor the target check is subsequently applied to it.

A legitimate map for target catalog A can therefore be used with target catalog B having the same family names but different definitions.

Per-contribution maps are not bound unless TargetCatalogFile is present

The exact target check is inside:

Wolfram Language
If[KeyExistsQ[request, "TargetCatalogFile"], ...]

A request can instead supply "TargetTopologies" directly. Then catalog-match records pass their source checks, but their recorded target catalog is never compared with the actual target definitions used for assembly.

For example, use a valid source-to-A match and set:

Wolfram Language
"TargetTopologies" -> catalogB["Families"]

where B reuses A’s family names. Explicitly mapped masters bypass the assembler’s source/target identity fallback, so the wrong target can be accepted.

Correction: preserve and validate catalog-match records before extracting any rules, regardless of singular or plural input syntax. Whenever a catalog-match record is used, derive the target from the agreed bound catalog or require an explicitly identical target catalog. Do not permit "TargetTopologies" to substitute different definitions.

Raw exact rule lists can remain an explicitly caller-supplied interface; they should not accidentally inherit the status of a validated catalog match.

4. Other concrete corrections and integration gaps
Physical-channel compatibility is still too weak

assemblyPhysicalPartons checks incoming and observed species, while setupFields checks momentum/measurement layout. Neither checks the physical polarization projection or compatible dimensional/analytic conventions.

Two files differing only in incoming/observed spin settings or distribution-selection flags can pass these checks and be summed, while the output retains the first contribution’s "Definitions".

This does not establish that your current UU inputs are mixed. It is a concrete acceptance hole in this general assembly API.

Compare a physical-channel compatibility projection containing the relevant incoming/observed polarization data and dimensional/analytic conventions. Do not compare the entire source fingerprint or require equality of unobserved species: those legitimately differ between gluon and ghost contributions.

The matcher result does not contain the bindings the CLI requires

The displayed MatchCutIntegralCatalogs return value lacks:

Wolfram Language
"SourceDefinitions"
"SourceIntegrals"
"TargetCatalog"

but the CLI expects those fields for a CutIntegralCatalogMatch.

Therefore, a direct matcher-result → file → CLI round trip fails as shown. An unshown producer may intentionally add these fields; in that case, test that actual producer/consumer path. The three supplied files alone do not complete this contract.

The source binding should use the same normalized reader output as the CLI, including its removal of exact-zero master entries.

The writer can create a file its own reader cannot read

The CLI always writes WXF bytes, but accepts an arbitrary "OutputFile" extension. Both read and ReadMasterIntegralCoefficients choose WXF only for .wxf; otherwise they use Get. Thus an output called Result.wl can pass the temporary-file readback and then fail on the next normal read. The baseline reader indeed dispatches by extension.

Require .wxf for this writer, or select serialization according to the declared output format. Also check the result of RenameFile; the current script can continue to print completion after a failed publication.

$Aborted passes the “exact” input guards

The rule-RHS, weight, and AdditionalFactor guards reject $Failed but not $Aborted. For example, "AdditionalFactor" -> $Aborted can propagate into the returned prefactor without producing a Failure.

Use the shared invalid-result check for these scalar inputs, including $Aborted. This is an acceptance check, not a request for another independent blacklist.

5. Parts I would not flag as defects
Source/target preference handling is correct for a preference set

Passing all targetIDs as the underlying preferred representatives ensures a class with any target member selects a target representative. The later destinations pass then chooses a target member belonging to the target’s "PreferredIntegrals" set.

That second pass is why the first call’s use of targetIDs, rather than preferred, is not a bug. Replacing "RepresentativeFrame" with the chosen destination’s "SourceFrame" is also the correct adjustment.

Two semantics should remain explicit: "PreferredIntegrals" is an unordered preference set, not an eligibility whitelist, and source preferences do not control a source-to-target match. Saved-order eligibility must already be enforced by the reuse stage or the eligible target set, as you described.

The inspected pattern/scoping constructs are not inherently broken

The nested pure functions in destinations use the outer slot for the group and the inner slot for the sorting element. I do not find an unintended cross-capture there. Named Function parameters in MapThread and MapIndexed likewise avoid a slot ambiguity. Wolfram’s nested-function scoping distinguishes these constructions. 
Wolfram Documentation Center
+1

This is also correct:

Wolfram Language
FirstPosition[..., index, None, {1}, Heads -> False]

It returns the top-level particle position, and Extract then selects the corresponding cut vector. It avoids the default head/deep-search behavior. 
Wolfram Documentation Center

The conditional GLI replacement using /; ... :> is valid syntax; it is not a precedence defect.

The Laurent grouping concerns are covered by the reader

I would not report either unsorted Orders keys or differing input regulator aliases as a demonstrated defect here. The baseline reader normalizes the declared regulator, KeySorts the order association, verifies a contiguous stored range, and requires the series variable to match. It also preserves zero finite Laurent prefixes rather than treating them as exact zero.

Exact domain comparison is appropriately conservative—after the frame fix

Distinguishing absent versus explicitly declared domain data, or rejecting equivalent assumptions written differently, creates false negatives rather than false integral equivalences. That is acceptable for this reuse gate.

Likewise, retaining the off-shell polynomial, each cut power/type/orientation, and ordinary prescription is the correct direction. A successful catalog match should retain precisely the limited scope stated in your returned record.

6. Highest-value tests before accepting the new APIs

These can use small synthetic catalogs and coefficient records; they do not need the production endpoint contraction.

Test	Required result
Restricted-domain loop-order counterexample from §1	No equivalence without transforming the domain. Identical literal loop frame and defining data should still match.
Two independent source catalogs both named CF1, with different definitions and different target destinations	Each contribution uses only its own rule list; no cross-source substitution.
Identity fallback with differing typed cuts/domain/normalization, and duplicate source/target names	Reject instead of retaining the GLI or overwriting a different definition.
One-field equivalence mutations: cut orientation, cut power, cut type, ordinary prescription, off-shell polynomial	Each physically different definition must cease matching. Include particle/measurement cut orders interleaved in the slot list.
Target preference: two equivalent targets, only the second preferred	Choose that target and its frame; no internal catalog names leak into restored rules. Empty preferences should still select a target.
CLI binding matrix: singular/plural map files, correct/wrong source, correct/wrong target, and direct TargetTopologies	All mismatched catalog-match combinations fail before assembly.
Actual match-record producer → serialized file → CLI	Required bindings survive and compare against normalized source data.
Same species/kinematics but different physical spin projection or dimensional convention	Reject unintended cross-channel assembly while accepting the intended gluon/ghost completion.
Laurent zero-prefix cancellation and insufficient saved orders	Preserve unknown remainders; fail requests exceeding known orders.
CLI output round trip, failed rename, and $Aborted scalar input	Re-readable output on success; nonzero exit on publication failure or invalid scalar data.

Also add negative tests for unsupported dimensional tags and nonunit powers inside topology propagators on the legacy path. Momentum[p] and Momentum[p,D] are not interchangeable FeynCalc representations, and StandardPropagatorDenominator’s stored power is semantic data; the scalar-product conversion must not erase distinctions unless validation has already excluded them. 
FeynCalc
+1

The immediate priorities are the literal-frame domain fix, a complete definition comparison in assembly, and unconditional validation of catalog-match bindings. Those corrections preserve the requested regeneration scope and the retained generalized endpoint records.