(* Complete massless-QCD final states and sums over unobserved quark flavors. *)
BeginPackage["FeynFacet`"];
EnumerateNLORealChannels::usage="EnumerateNLORealChannels[channel,request] enumerates the two unobserved partons for a single-inclusive massless QCD NLO channel. Species supplies explicit flavor representatives; FlavorCount supplies the total active massless flavors. Unmentioned flavors are summed using flavor symmetry. Ghost completion accompanies a pair of unobserved gluons.";
Begin["`Private`"];
qcdFlavorLabels[parts_]:=DeleteDuplicates[Cases[parts,{"q"|"qb",flavor_}:>flavor,Infinity],SameQ];
qcdFixedFlavors[channel_]:=qcdFlavorLabels[Join[channel["Incoming"],{channel["Observed"]}]];
qcdRequireConjugateSpecies[species_List]:=If[
 !MemberQ[species,"g"]||!AllTrue[qcdFlavorLabels[species],
  MemberQ[species,{"q",#}]&&MemberQ[species,{"qb",#}]&],
 collinearKernelFail["GluonAndConjugateFlavorSpeciesRequired"]];
qcdFlavorSummedRows[rows_List,channel_,flavorCount_,rowKey_]:=Module[
 {fixed=qcdFixedFlavors[channel],other,representative,result={},free,multiplicity},
 If[IntegerQ[flavorCount]&&flavorCount<Length[fixed],
  collinearKernelFail["FlavorCountBelowExternalFlavorCount"]];
 other=DeleteDuplicates[Flatten[qcdFlavorLabels[#[rowKey]]& /@ rows],SameQ];
 other=Complement[other,fixed];representative=If[other==={},None,First[other]];
 Do[
  free=Complement[qcdFlavorLabels[row[rowKey]],fixed];
  If[Length[free]>1,collinearKernelFail["MultipleUnresolvedFlavorSumsRequireExtension"]];
  If[free=!={}&&free=!={representative},Continue[]];
  multiplicity=If[free==={},1,flavorCount-Length[fixed]];
  If[TrueQ[multiplicity===0],Continue[]];
  AppendTo[result,Join[row,<|"FlavorMultiplicity"->multiplicity,"FlavorSum"->free|>]],
 {row,rows}];
 result
];
EnumerateNLORealChannels[channel_Association,request_Association]:=Catch[Module[
 {species,flavors,charge,pairs,rows,components,weight,nf},
 If[!ContainsAll[Keys[channel],{"Incoming","Observed"}]||
  !ContainsAll[Keys[request],{"Species","FlavorCount"}],
  collinearKernelFail["QCDRealChannelRequestRequired"]];
 species=request["Species"];nf=request["FlavorCount"];
 If[!MatchQ[channel["Incoming"],{_,_}]||!ListQ[species]||!DuplicateFreeQ[species]||!AllTrue[species,collinearKernelSpeciesQ]||
  !AllTrue[Join[channel["Incoming"],{channel["Observed"]}],MemberQ[species,#]&],
  collinearKernelFail["CompleteDeclaredPartonSpeciesRequired"]];
 qcdRequireConjugateSpecies[species];
 flavors=qcdFlavorLabels[species];
 charge[parton_]:=If[parton==="g",ConstantArray[0,Length[flavors]],
  If[First[parton]==="q",1,-1](Boole[#===Last[parton]]& /@ flavors)];
 If[Complement[flavors,qcdFixedFlavors[channel]]==={}&&
  !TrueQ[nf-Length[qcdFixedFlavors[channel]]===0]&&
  Total[charge /@ channel["Incoming"]]===charge[channel["Observed"]],
  collinearKernelFail["AdditionalUnobservedFlavorRepresentativeRequired"]];
 pairs=DeleteDuplicates[Sort /@ Tuples[species,2],SameQ];
 pairs=Select[pairs,Total[charge /@ channel["Incoming"]]===charge[channel["Observed"]]+Total[charge /@ #]&];
 rows=(<|"UnobservedPartons"->#|>& /@ pairs);
 rows=qcdFlavorSummedRows[rows,channel,nf,"UnobservedPartons"];
 components=Association@MapIndexed[Function[{row,index},
  weight=FeynFacet`FinalStateSymmetryFactor[row["UnobservedPartons"]];
  "State"<>IntegerString[First[index],10,2]->Join[row,<|"AssemblyWeight"->weight|>]],rows];
 If[MemberQ[pairs,{"g","g"}],AssociateTo[components,"Ghosts"-><|
  "UnobservedPartons"->{"ghost","antighost"},"FlavorMultiplicity"->1,"AssemblyWeight"->-1|>]];
 <|"Components"->components,"FlavorCount"->nf,
  "ExternalFlavors"->qcdFixedFlavors[channel],
  "FlavorSummation"->"MasslessQCD",
  "Coverage"->"All flavor-conserving two-parton recoil states; one representative per indistinguishable unobserved quark flavor, with the physical gluon/ghost completion."|>
],"CollinearCounterterms"];
End[];EndPackage[];
