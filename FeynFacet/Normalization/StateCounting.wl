(* External-state counting is independent of perturbative order and integrator. *)
BeginPackage["FeynFacet`"];
FinalStateSymmetryFactor::usage="FinalStateSymmetryFactor[species,taggedPositions] gives the phase-space factor for labelled amplitudes. Tagged positions are distinguished; identical untagged species contribute reciprocal factorials. A sum over tags or measurement tuples is a separate operation.";
FinalStateMeasurementNormalization::usage="FinalStateMeasurementNormalization[species,selection] derives full-state or tuple-orbit weights. Representation is FullTupleSum or OneTuplePerOrbit. The latter requires Tuple and Ordered and assumes complete contributions related by identical-particle relabeling; it is not a leading-particle selection.";
FlavorAssignmentMultiplicity::usage="FlavorAssignmentMultiplicity[unobserved,fixedSpecies,summedFlavors,classes] counts flavor assignments represented by an unobserved species multiset. Class Multiplicity is the number of physically equivalent active flavors. Fixed external flavors are excluded from dummy sums; dummy-label automorphisms are divided out once.";
VerifyDisjointFlavorStateSums::usage="VerifyDisjointFlavorStateSums[components,fixedSpecies,classes] checks that component flavor sums with the same complete-amplitude/measurement Context do not overlap. Components provide UnobservedPartons and optional FlavorSum labels. A finite set of fresh representatives tests equality-pattern overlap without evaluating amplitudes.";
Begin["`Private`"];
(* The sign of a cut ghost pair is separate from Bose symmetry and from
   Hermitian interference multiplicities. Balance particle and antiparticle
   fields, rather than accepting any even number of ghosts. *)
assemblyGhostSign[setup_Association]:=Module[{partons,outgoing,positive,negative},
 partons=Lookup[setup,"Partons",None];If[!MatchQ[partons,Rule[_List,_List]],Return[$Failed]];
 outgoing=Last[partons];positive=Cases[outgoing,FeynArts`U[a___]:>{a}];
 negative=Cases[outgoing,-FeynArts`U[a___]:>{a}];
 If[Sort[positive]=!=Sort[negative],Return[$Failed]];(-1)^Length[positive]
];
FinalStateSymmetryFactor[species_List,tagged_List:{}]:=Module[{untagged},
 If[!DuplicateFreeQ[tagged]||!AllTrue[tagged,IntegerQ[#]&&1<=#<=Length[species]&]||
   !FreeQ[species,_Missing|_Failure],Return[Failure["ExplicitFinalSpeciesAndTagPositionsRequired",<||>]]];
 untagged=species[[Complement[Range[Length[species]],tagged]]];
 1/(Times@@(Factorial[Last[#]]&/@Tally[untagged,SameQ]))
];
FinalStateSymmetryFactor[___]:=Failure["ExplicitFinalSpeciesAndTagPositionsRequired",<||>];
FinalStateMeasurementNormalization[species_List,selection_Association]:=Module[
 {full,representation,tuple,ordered,orbit=1,positions,chosen,counts,stabilizer,n,k},
 full=FeynFacet`FinalStateSymmetryFactor[species];If[FailureQ[full],Return[full]];
 representation=Lookup[selection,"Representation",None];
 Switch[representation,
  "FullTupleSum",Null,
  "OneTuplePerOrbit",
   tuple=Lookup[selection,"Tuple",None];ordered=Lookup[selection,"Ordered",None];
   If[!ListQ[tuple]||!AllTrue[tuple,IntegerQ[#]&&1<=#<=Length[species]&]||!MemberQ[{True,False},ordered],
    Return[Failure["ExplicitMeasurementTupleRequired",<||>]]];
   Do[positions=Flatten[Position[species,s,{1},Heads->False]];
    chosen=Select[tuple,MemberQ[positions,#]&];counts=Last/@Tally[chosen];n=Length[positions];k=Length[counts];
    stabilizer=If[ordered,1,Times@@(Factorial[Last[#]]&/@Tally[counts])];
    orbit*=Factorial[n]/Factorial[n-k]/stabilizer,{s,DeleteDuplicates[species,SameQ]}],
  _,Return[Failure["ExplicitStateSumRepresentationRequired",<||>]]];
 <|"Factor"->full orbit,"FullStateFactor"->full,"TupleOrbitSize"->orbit,"Selection"->selection|>
];
FinalStateMeasurementNormalization[___]:=Failure["FinalStateAndMeasurementRepresentationRequired",<||>];

stateFlavor[q_]:=If[MatchQ[q,{("q"|"qb"),_}],Last[q],None];
FlavorAssignmentMultiplicity[unobserved_List,fixed_List,summed_List,classes_Association]:=Catch[Module[
 {all,fixedLabels,labels,owners,counts=<||>,factors={},members,count,used,dummies,k,permutations,automorphisms,rename},
 If[!DuplicateFreeQ[summed]||!AllTrue[Values[classes],AssociationQ[#]&&
   ContainsAll[Keys[#],{"Members","Multiplicity"}]&&ListQ[#["Members"]]&&DuplicateFreeQ[#["Members"]]&],
  Throw[Failure["DisjointFlavorClassesAndDistinctSummationLabelsRequired",<||>]]];
 all=Flatten[Lookup[Values[classes],"Members",{}],1];
 If[!DuplicateFreeQ[all],Throw[Failure["DisjointFlavorClassesRequired",<||>]]];
 fixedLabels=DeleteDuplicates[DeleteCases[stateFlavor/@fixed,None]];
 labels=DeleteDuplicates[DeleteCases[stateFlavor/@unobserved,None]];
 If[!ContainsAll[labels,summed]||Intersection[fixedLabels,summed]=!={}||!ContainsAll[all,summed],
  Throw[Failure["UnobservedDummyFlavorsDisjointFromFixedFlavorsRequired",<||>]]];
 (* Unsummed explicit unobserved flavors also name fixed physical species. *)
 fixedLabels=Union[fixedLabels,Complement[labels,summed]];
 owners=Association@Table[label->SelectFirst[Keys[classes],MemberQ[classes[#]["Members"],label]&],{label,summed}];
 Do[members=classes[name]["Members"];count=classes[name]["Multiplicity"];
  used=Length[Intersection[members,fixedLabels]];dummies=Select[summed,owners[#]===name&];k=Length[dummies];
  If[!FreeQ[count,_Real|_Missing|_Failure]||(IntegerQ[count]&&count<used),
   Throw[Failure["EnoughActiveFlavorsForFixedSpeciesRequired",<|"Class"->name|>]]];
  AssociateTo[counts,name-><|"Active"->count,"Fixed"->used,"SummedDistinct"->k|>];
  AppendTo[factors,Product[count-used-j,{j,0,k-1}]],{name,Keys[classes]}];
 rename[permutation_]:=Sort[unobserved/.Thread[summed->permutation]];
 permutations=Select[Permutations[summed],And@@MapThread[owners[#1]===owners[#2]&,{summed,#}]&];
 automorphisms=Count[rename/@permutations,Sort[unobserved]];
 If[automorphisms<1,Throw[Failure["FlavorAssignmentAutomorphismRequired",<||>]]];
 <|"Multiplicity"->Factor[Times@@factors/automorphisms],"FlavorCounts"->counts,
   "DummyFlavorAutomorphisms"->automorphisms|>
]];
FlavorAssignmentMultiplicity[___]:=Failure["FlavorAssignmentDefinitionRequired",<||>];
VerifyDisjointFlavorStateSums[components_Association,fixed_List,classes_Association]:=Catch[Module[
 {names=Keys[components],rows=Values[components],universe=<||>,allFixed,maximum,states=<||>,summed,unobserved,
  fixedLabels,available,assignments,owner,candidates,count,pairs,intersection},
 If[Length[names]<2,Return[True]];
 If[!AllTrue[rows,AssociationQ[#]&&ListQ[Lookup[#,"UnobservedPartons",None]]&&ListQ[Lookup[#,"FlavorSum",{}]]&],
  Throw[Failure["ExplicitExternalFlavorComponentStatesRequired",<||>]]];
 allFixed=DeleteDuplicates[Join[DeleteCases[stateFlavor/@fixed,None],Flatten[
   Complement[DeleteCases[stateFlavor/@#["UnobservedPartons"],None],Lookup[#,"FlavorSum",{}]]&/@rows]]];
 maximum=Max[1,Max[Length[Lookup[#,"FlavorSum",{}]]&/@rows]];
 Do[count=classes[name]["Multiplicity"];
  candidates=DeleteDuplicates[Join[Intersection[allFixed,classes[name]["Members"]],classes[name]["Members"],
    Table[flavorCandidate[name,j],{j,maximum}]]];
  If[IntegerQ[count],candidates=Take[candidates,Min[count,Length[candidates]]]];
  AssociateTo[universe,name->candidates],{name,Keys[classes]}];
 Do[unobserved=rows[[i]]["UnobservedPartons"];summed=Lookup[rows[[i]],"FlavorSum",{}];
  fixedLabels=Union[DeleteCases[stateFlavor/@fixed,None],Complement[DeleteCases[stateFlavor/@unobserved,None],summed]];
  available=Table[owner=Select[Keys[classes],MemberQ[classes[#]["Members"],label]&];
    If[Length[owner]=!=1,Throw[Failure["UniqueExternalFlavorClassRequired",<|"Flavor"->label|>]]];
    Complement[universe[First[owner]],fixedLabels],{label,summed}];
  assignments=If[summed==={},{{}},Select[Tuples[available],DuplicateFreeQ]];
  AssociateTo[states,names[[i]]->DeleteDuplicates[Sort[unobserved/.Thread[summed->#]]&/@assignments]],{i,Length[rows]}];
 pairs=Subsets[Range[Length[rows]],{2}];
 Do[If[Lookup[rows[[pair[[1]]]],"Context",<||>]=!=Lookup[rows[[pair[[2]]]],"Context",<||>],Continue[]];
  intersection=Intersection[states[names[[pair[[1]]]]],states[names[[pair[[2]]]]]];
  If[intersection=!={},Throw[Failure["OverlappingExternalFlavorComponents",<|
    "Components"->names[[pair]],"ExampleState"->First[intersection]|>]]],{pair,pairs}];
 True
]];
VerifyDisjointFlavorStateSums[___]:=Failure["ExternalFlavorComponentsRequired",<||>];
End[];EndPackage[];
