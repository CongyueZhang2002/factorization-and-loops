(* Conserved electromagnetic DIS tensor projections.
   Current index order is conjugate amplitude first, amplitude second.
   The current includes dimensionless flavor charges, but no QED coupling. *)
BeginPackage["FeynFacet`"];
DISCurrentProjectors::usage="DISCurrentProjectors[p,q,{mu,nu}] gives exact-D symmetric and four-dimensional BMHV antisymmetric dual tensors for p^2=0 and q^2<0. CoefficientProjectors extract the coefficients of 2F1, FL/x, and 2g1 from the tensor normalized by 1/(4 Pi). Physical p and q do not restrict the vector-current indices to four dimensions.";
GenerateCurrentAmplitudes::usage="GenerateCurrentAmplitudes[setup] generates the selected amplitudes with external colorless vector-current indices open. Currents explicitly declare Momentum, Indices by amplitude side, and the single current Coupling to remove. The same FeynArts conversion is used by hadronic amplitudes; contraction is deferred until the current wavefunction is amputated.";
VectorCurrentPolarizationSum::usage="VectorCurrentPolarizationSum[q,{mu,nu}] gives -g_D(mu,nu)+q_D(mu)q_D(nu)/q_D^2 for the conserved timelike electromagnetic current, without a polarization average. The current momentum remains D-dimensional.";
Begin["`Private`"];
VectorCurrentPolarizationSum[q_Symbol,{mu_Symbol,nu_Symbol}]:=
 -FeynCalc`MTD[mu,nu]+FeynCalc`FVD[q,mu]FeynCalc`FVD[q,nu]/FeynCalc`SPD[q];

(* The off-shell current is represented by an external vector wavefunction
   solely during graph generation. Remove it before Contract can apply any
   real-photon on-shell or transversality identity. *)
amputateCurrentPolarization[expression_,current_Association,side_String]:=Module[
 {q,index,coupling,vectors,vector,result},
 {q,coupling}=Lookup[current,{"Momentum","Coupling"}];index=current["Indices"][side];
 vectors=DeleteDuplicates[Cases[expression,
  v:FeynCalc`Momentum[FeynCalc`Polarization[k_,___],___]/;k===q:>v,{0,Infinity}]];
 If[expression===0,Return[0]];
 If[Length[vectors]=!=1,fail["CurrentPolarization",q,"Exactly one uncontracted current polarization is required."]];
 vector=First[vectors];
 If[polarizationDegree[expression,vector]=!=1,
  fail["CurrentPolarization",q,"The amplitude must be linear in the external current wavefunction."]];
 result=expression/.vector->FeynCalc`LorentzIndex[index,D];
 If[!FreeQ[result,FeynCalc`Polarization[q,___]],
  fail["CurrentPolarization",q,"Current wavefunction removal was incomplete."]];
 (* The generated electromagnetic current keeps its flavor charge. Only the
    declared external electromagnetic coupling is removed, exactly once. *)
 If[polarizationDegree[result,coupling]=!=1,fail["CurrentCoupling",coupling,
   "Expected exactly one power of the declared current coupling."]];
 result=result/.coupling->1;
 result
];
GenerateCurrentAmplitudes[setup_Association]:=Catch[Module[
 {currents,momenta,partons,diagrams,process,sides,amplitudes,external,indices,allLoops},
 currents=Lookup[setup,"Currents",{}];momenta=Lookup[setup,"PartonMomentum",None];
 partons=Lookup[setup,"Partons",None];
 If[!MatchQ[momenta,Rule[{__Symbol},{__Symbol}]]||
  !MatchQ[partons,Rule[_List,_List]]||Length/@momenta=!=Length/@partons||
  !ListQ[currents]||currents==={}||!AllTrue[currents,AssociationQ],
  fail["CurrentProcess",setup,"Declare external momenta, fields and current insertions."]];
 external=Flatten[List@@momenta];
 If[!DuplicateFreeQ[external],fail["CurrentProcess",external,"External momentum labels must be distinct."]];
 Do[
  If[!ContainsAll[Keys[current],{"Momentum","Indices","Coupling"}]||
   !MemberQ[external,current["Momentum"]]||!AssociationQ[current["Indices"]]||
   Sort[Keys[current["Indices"]]]=!=Sort[sideNames]||
   !MatchQ[Values[current["Indices"]],{_Symbol,_Symbol}]||
   !DuplicateFreeQ[Values[current["Indices"]]]||
   !FreeQ[current["Coupling"],_Real|_Missing|_Failure|$Failed|$Aborted]||current["Coupling"]===0,
   fail["CurrentInsertion",current,"A current requires distinct open indices and an explicit nonzero coupling."]];
  If[Extract[partons,First@Position[momenta,current["Momentum"]]]=!=FeynArts`V[1],
   fail["CurrentInsertion",current,"The electromagnetic current must replace the declared external photon field."]],
 {current,currents}];
 indices=Flatten[Values[#["Indices"]]&/@currents];
 If[!DuplicateFreeQ[indices]||Intersection[external,indices]=!={},
  fail["CurrentIndices",indices,"Current indices must be distinct from each other and all momentum labels."]];
 diagrams=GenerateDiagram[setup];If[!AssociationQ[diagrams],Throw[$Failed,$collinearFailure]];
 sides=Association@MapThread[#1->Join[#2,<|"Diagrams"->diagrams[#1]|>]&,
  {sideNames,Lookup[setup,{"ForwardAmplitudes","ConjugateAmplitudes"}]}];
 allLoops=Flatten[Lookup[Values[sides],"LoopMomenta"]];
 If[!DuplicateFreeQ[Join[external,allLoops]],fail["LoopMomenta",allLoops,"External and virtual-loop labels must be distinct."]];
 process=Join[KeyTake[setup,{"Model","MasslessQuarkFlavors","ElectromagneticCharges","MasslessMomenta","ComplexParameters"}],<|
  "Incoming"->MapThread[<|"Momentum"->#1,"Parton"->#2|>&,{First[momenta],First[partons]}],
  "Outgoing"->MapThread[<|"Momentum"->#1,"Parton"->#2|>&,{Last[momenta],Last[partons]}],"Sides"->sides,"Currents"->currents|>];
 amplitudes=AssociationMap[Function[side,
  Association@Table[index->convertAmplitudeSide[
   Join[process,<|"Sides"->Append[sides,side->Append[sides[side],"DiagramIndex"->index]]|>],side],
   {index,sides[side]["DiagramIndices"]}]],sideNames];
 <|"Format"->"FeynFacet-CurrentAmplitudes","Amplitudes"->amplitudes,
  "Currents"->currents,"Partons"->partons,"PartonMomentum"->momenta,
  "CurrentIndexOrder"->"ConjugateThenAmplitude","Setup"->setup|>
],$collinearFailure];
DISCurrentProjectors[p_Symbol,q_Symbol,{mu_Symbol,nu_Symbol}] := Module[
 {longitudinal,transverse,antisymmetric,r,virtuality,pq},
 If[!DuplicateFreeQ[{p,q,mu,nu}],Return[Failure["DistinctCurrentMomentaAndIndicesRequired",<||>]]];
 virtuality=FeynCalc`SPD[q];pq=FeynCalc`SPD[p,q];
 r[index_]:=FeynCalc`FVD[p,index]-pq/virtuality FeynCalc`FVD[q,index];
 longitudinal=-virtuality/pq^2 r[mu]r[nu];
 transverse=-FeynCalc`MTD[mu,nu]+FeynCalc`FVD[q,mu]FeynCalc`FVD[q,nu]/virtuality+longitudinal;
 antisymmetric=I FeynCalc`LC[mu,nu][p,q]/FeynCalc`SP[p,q];
 <|"TensorBasis"-><|"Transverse"->transverse,"Longitudinal"->longitudinal,"Antisymmetric"->antisymmetric|>,
  "DualProjectors"-><|"Transverse"->transverse/(D-2),"Longitudinal"->longitudinal,"Antisymmetric"->-antisymmetric/2|>,
  "CoefficientProjectors"-><|"2F1"->2transverse/(D-2),"FL/x"->2longitudinal,"2g1"->-antisymmetric|>,
  "GramMatrix"->DiagonalMatrix[{D-2,1,-2}],"CurrentTensorNormalization"->1/(4Pi),
  "PhysicalMomenta"->{p,q},"CurrentIndexOrder"->"ConjugateThenAmplitude",
  "KinematicConditions"->(FeynCalc`SPD[p]==0&&FeynCalc`SPD[q]<0),
  "QEDCouplingIncluded"->False,"DiracScheme"->"BMHV"|>
];
End[];EndPackage[];
