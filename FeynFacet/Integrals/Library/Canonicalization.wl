(* Integral families and sectors under exact affine momentum transformations.
   Powers are canonicalized under family automorphisms after the topology.
   Positive-energy cuts and measurement denominators are distinct decorations. *)
BeginPackage["FeynFacet`"];
CanonicalMasterIntegral::usage="CanonicalMasterIntegral[definition] returns a canonical active integral family, propagator powers, sector number and exact momentum transformation. Family names and dummy momentum names do not enter identity.";
Begin["`Private`"];
$masterLibraryFrameCache=<||>;
(* Symbol replacement inside an Association can retain an old evaluation
   order for Plus/Times. Serialization rebuilds that order. Rebuild the
   arithmetic here too, so a fresh key equals its own on-disk definition. *)
masterLibraryCanonicalSyntax[value_]:=Which[
 AssociationQ[value],Association@KeyValueMap[
  masterLibraryCanonicalSyntax[#1]->masterLibraryCanonicalSyntax[#2]&,value],
 AtomQ[value],value,
 MemberQ[{List,Rule,RuleDelayed,Plus,Times,Power,And,Or,Equal,Unequal,Less,LessEqual,Greater,GreaterEqual,Inequality},Head[value]],
  Apply[Head[value],masterLibraryCanonicalSyntax/@(List@@value)],
 True,value];
masterLibraryKey[value_]:=FeynFacetLibrary`IntegralKey[masterLibraryCanonicalSyntax[value]];
masterLibraryCanonical[definition_Association]:=Module[
 {required,loops,external,e,rules,d,active,powers,cuts,particles,measurements,n,l,gram,poly,kin,
  cutVectors,momenta,types,signs,source,top,conventions,tags,candidates,frames,frameKey,
  rows,permutation,items,candidateMomenta,best,familyKey,sortedPowers,bucket,sourceIndices,permitted},
 required={"MasterIntegral","LoopMomenta","ExternalMomenta","DimensionalRegulator","Dimension",
  "InversePropagators","PropagatorPowers","CutIndices","MeasurePrefactor",
  "MasterIntegralPrefactor","KinematicRules","KinematicConditions","Prescription"};
 If[!ContainsAll[Keys[definition],required],masterLibraryFail["CompleteMasterIntegralDefinitionRequired",
  <|"Missing"->Complement[required,Keys[definition]]|>]];
 {loops,external,e}=Lookup[definition,{"LoopMomenta","ExternalMomenta","DimensionalRegulator"}];
 If[!MatchQ[e,_Symbol]||!MatchQ[loops,{__Symbol}]||!MatchQ[external,{___Symbol}]||
  !DuplicateFreeQ[Join[loops,external,{e}]],masterLibraryFail["IndependentIntegralSymbolsRequired"]];
 rules=Join[Thread[loops->Table[Symbol["FeynFacetLibrary`k"<>ToString[i]],{i,Length[loops]}]],
  Thread[external->Table[Symbol["FeynFacetLibrary`p"<>ToString[i]],{i,Length[external]}]],
  {e->FeynFacetLibrary`eps}];
 d=definition/.rules;powers=d["PropagatorPowers"];cuts=d["CutIndices"];
 If[!VectorQ[powers,IntegerQ]||Length[powers]=!=Length[d["InversePropagators"]]||
  !DuplicateFreeQ[cuts]||!AllTrue[cuts,IntegerQ[#]&&1<=#<=Length[powers]&],
  masterLibraryFail["ValidPoweredMasterDefinitionRequired"]];
 (* Keep a pinched mandatory cut in the definition. Its zero is exact, but
    pinches must not be confused with an uncut integral of a different measure. *)
 active=Union[cuts,Select[Range[Length[powers]],powers[[#]]=!=0&]];
 l=Length[loops];momenta=Join[d["LoopMomenta"],d["ExternalMomenta"]];n=Length[momenta];
 gram=Table[cutScalarProduct[Min[i,j],Max[i,j]],{i,n},{j,n}];
 poly=cutEquivalenceScalarProducts[FeynCalc`FCI[#],momenta,gram]&/@d["InversePropagators"][[active]];
 kin=cutEquivalenceScalarProducts[FeynCalc`FCI[#],momenta,gram]&/@d["KinematicRules"];
 If[!FreeQ[{poly,kin},$Failed|_FeynCalc`Pair],masterLibraryFail["AffineScalarProductsRequired"]];
 poly=Expand[#/.kin]&/@poly;
 types=Lookup[d,"PropagatorTypes",ConstantArray["Unspecified",Length[powers]]][[active]];
 signs=Lookup[d,"OriginalPropagatorPrescriptions",
   Lookup[d,"PropagatorPrescriptions",ConstantArray[None,Length[powers]]]][[active]];
 source=Lookup[d,"SourceCutDefinition",<||>];
 top=Lookup[d,"MomentumSpaceTopology",Lookup[source,"Topology",None]];
 (* Retain the declared ordinary sign for numerator sectors too, when the
    topology gives it. No prescription is inferred from an unsigned polynomial. *)
 If[MatchQ[top,_FeynCalc`FCTopology],
  signs=MapIndexed[If[MemberQ[cuts,active[[First[#2]]]],0,
   FirstCase[FeynCalc`FCI[top[[2,active[[First[#2]]]]]],
    FeynCalc`StandardPropagatorDenominator[___,{_,eta_}]:>eta,#1,Infinity]]&,signs]];
 particles=Lookup[d,"ParticleCutIndices",cuts];measurements=Lookup[d,"MeasurementCutIndices",{}];
 cutVectors=cutEquivalenceVector[#,momenta]&/@Lookup[d,"OrientedCutMomenta",{}];
 If[Length[cutVectors]=!=Length[particles]||MemberQ[cutVectors,$Failed],
  masterLibraryFail["CompleteOrientedCutMomentaRequired"]];
 conventions=KeySort@Join[
  KeyTake[d,{"Dimension","Prescription","TimeDirection","MomentumSpaceConvention",
   "MeasurePrefactor","MasterIntegralPrefactor","KinematicConditions","VirtualLoopCount",
   "PhaseSpaceLoopCount","MomentumConservationDeltaCount","CutDistributionConvention",
   "MeasureConvention","AdditionalAcceptanceBoundaries","AnalyticContinuation","EvaluationScope"}],
  <|"SourceConventions"->KeyTake[source,{"Definition","CutConvention","Assumptions",
   "TimeDirection","AdditionalAcceptanceBoundaries"}]|>];
 tags=Sort@DeleteDuplicates@Cases[{d["InversePropagators"],d["KinematicRules"]},
   FeynCalc`Momentum[_,args___]:>{args},Infinity];
 permitted=FreeQ[conventions,Alternatives@@d["LoopMomenta"]]&&
  MemberQ[{None,{},True},Lookup[d,"AdditionalAcceptanceBoundaries",
   Lookup[source,"AdditionalAcceptanceBoundaries",None]]];
 candidateMomenta=Lookup[d,"PropagatorMomenta",{}];
 candidateMomenta=If[Length[candidateMomenta]===Length[powers],candidateMomenta[[active]],{}];
 candidates=If[cuts=!={},cutVectors,
  DeleteDuplicates@Flatten[({#,-#}&/@DeleteCases[
   (cutEquivalenceVector[#,momenta]&/@Select[
    candidateMomenta,MatchQ[#,_Symbol|_Plus|_Times]&]),$Failed]),1]];
 frameKey=masterLibraryKey[{momenta,poly,kin,candidates,permitted}];
 If[KeyExistsQ[$masterLibraryFrameCache,frameKey],
  frames=$masterLibraryFrameCache[frameKey],
  frames=cutEquivalenceFrames[<|"Loops"->d["LoopMomenta"],"GramMatrix"->gram,
    "OrientedCutMomenta"->candidates,"KinematicRules"->kin,
    "PropagatorPolynomials"->poly,"LoopFrameChangesPermitted"->permitted|>];
  If[frames==={},frames={<|"LoopTransformation"->IdentityMatrix[n][[1;;l]],
    "CutMomenta"->candidates,"Polynomials"->poly|>}];
  If[Length[$masterLibraryFrameCache]>=128,$masterLibraryFrameCache=<||>];
  AssociateTo[$masterLibraryFrameCache,frameKey->frames]];
 items=Table[
  rows=Table[With[{index=active[[i]],particle=FirstPosition[particles,active[[i]],None,{1}]},
   {frame["Polynomials"][[i]],
    Which[MemberQ[particles,index],"ParticleCut",MemberQ[measurements,index],"MeasurementCut",
     MemberQ[cuts,index],"Cut",True,"Ordinary"],
    types[[i]],If[MemberQ[cuts,index],0,signs[[i]]],
    If[particle===None,None,Extract[frame["CutMomenta"],particle]]}],{i,Length[active]}];
  permutation=Ordering[rows];rows=rows[[permutation]];
  {rows,powers[[active[[permutation]]]],active[[permutation]],frame["LoopTransformation"]},
 {frame,frames}];
 best=First[SortBy[items,Take[#,2]&]];
 {rows,sortedPowers,sourceIndices}=Take[best,3];
 familyKey=masterLibraryCanonicalSyntax[<|"LoopCount"->l,"ExternalMomenta"->d["ExternalMomenta"],
  "KinematicRules"->Sort[kin],"LorentzDimensionAnnotations"->tags,
  "Denominators"->rows,"Conventions"->conventions|>];
 bucket=StringRiffle[{"L"<>ToString[l],"E"<>ToString[Length[external]],
  "C"<>ToString[Length[particles]],"M"<>ToString[Length[measurements]],"N"<>ToString[Length[rows]]},"-"];
 <|"FamilyDefinition"->familyKey,"FamilyKey"->masterLibraryKey[familyKey],
  "Powers"->sortedPowers,"Sector"->Total[MapIndexed[If[#1>0,2^(First[#2]-1),0]&,sortedPowers]],
  "Bucket"->bucket,"ToCanonicalSymbols"->rules,"FromCanonicalSymbols"->Reverse/@rules,
  "SourcePropagatorIndices"->sourceIndices,"LoopTransformation"->best[[4]],
  "IdentityMethod"->If[cuts==={},"ExactAffineVirtualMomentumChanges","ExactAffineCutMomentumChanges"]|>
];
CanonicalMasterIntegral[definition_Association]:=Catch[masterLibraryCanonical[definition],"MasterLibrary"];
End[];EndPackage[];
