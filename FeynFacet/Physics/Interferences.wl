(* Hermitian diagram interferences, before master-integral normalization. *)
BeginPackage["FeynFacet`"];
DiagramInterferencePlan::usage="DiagramInterferencePlan[setup] selects independent Hermitian pairs when both sides have the same diagram set and loop order. Different sets or loop orders retain the full rectangle. HermitianReduction->False requests a full independent calculation.";
CollinearFactorizeInterferencesPreIBP::usage="CollinearFactorizeInterferencesPreIBP[setup] calculates one selected interference and, for an eligible off-diagonal pair, its Hermitian partner from the physical contraction before normalization. Each returned row contains Setup, Result and ConstructionMethod.";
Begin["`Private`"];
Options[FeynFacet`DiagramInterferencePlan]={"HermitianReduction"->Automatic};
FeynFacet`DiagramInterferencePlan[setup_Association,OptionsPattern[]]:=Module[
 {f=setup["ForwardAmplitudes"],c=setup["ConjugateAmplitudes"],eligible,pairs},
 If[!MemberQ[{Automatic,True,False},OptionValue["HermitianReduction"]],Return[$Failed]];
 If[normalizeAmplitudeSelection[All,f,"ForwardAmplitudes"]===$Failed||
    normalizeAmplitudeSelection[All,c,"ConjugateAmplitudes"]===$Failed,Return[$Failed]];
 eligible=f["LoopOrder"]===c["LoopOrder"] && Sort[f["DiagramIndices"]]===Sort[c["DiagramIndices"]] &&
   (f["LoopOrder"]===0 || Intersection[f["LoopMomenta"],c["LoopMomenta"]]==={});
 If[OptionValue["HermitianReduction"]===True && !eligible,Return[$Failed]];
 eligible=eligible && OptionValue["HermitianReduction"]=!=False;
 pairs=Tuples[{f["DiagramIndices"],c["DiagramIndices"]}];
 <|"Pairs"->If[eligible,Select[pairs,#[[1]]<=#[[2]]&],pairs],
   "FullPairCount"->Length[pairs],"HermitianReduction"->eligible|>
];
interferencePairSetup[setup_,pair_]:=Join[setup,<|
 "ForwardAmplitudes"->Append[setup["ForwardAmplitudes"],"SelectedIndex"->pair[[1]]],
 "ConjugateAmplitudes"->Append[setup["ConjugateAmplitudes"],"SelectedIndex"->pair[[2]]]|>];
(* FeynCalc ComplexConjugate intentionally leaves propagator eta signs alone.
   Mask denominators during scalar/tensor conjugation and reverse their signs
   explicitly, once. Cut distributions never pass through this function. *)
conjugatePhysicalAmplitude[expression_,setup_,rename_:True]:=Module[{internal,objects,tags,rules,scalar,denominators},
 internal=FeynCalc`ToSFAD[FeynCalc`FCI[expression]];
 objects=DeleteDuplicates[Cases[internal,_FeynCalc`FeynAmpDenominator,{0,Infinity}],SameQ];
 tags=Table[Unique["ordinaryDenominator"],{Length[objects]}];rules=Thread[objects->tags];
 scalar=FeynCalc`ComplexConjugate[internal/.rules,
   System`Conjugate->Lookup[setup,"ComplexParameters",{}],FeynCalc`FCRenameDummyIndices->rename];
 denominators=objects/.FeynCalc`StandardPropagatorDenominator[q_,sp_,mass_,{power_,eta_}]:>
   FeynCalc`StandardPropagatorDenominator[q,
     FeynCalc`ComplexConjugate[sp,System`Conjugate->Lookup[setup,"ComplexParameters",{}]],
     FeynCalc`ComplexConjugate[mass,System`Conjugate->Lookup[setup,"ComplexParameters",{}]],{power,-eta}];
 scalar/.Thread[tags->denominators]
];
hermitianConjugateContraction[seed_,setup_]:=Module[{f,c,rules},
 f=setup["ForwardAmplitudes"]["LoopMomenta"];c=setup["ConjugateAmplitudes"]["LoopMomenta"];
 rules=Thread[Join[f,c]->Join[c,f]];
 Map[conjugatePhysicalAmplitude[#,setup,False]& ,seed]/.rules
];
Options[FeynFacet`CollinearFactorizeInterferencesPreIBP]={"PreparedDiagrams"->Automatic,"HermitianReduction"->Automatic};
FeynFacet`CollinearFactorizeInterferencesPreIBP[setup_Association,OptionsPattern[]]:=Catch[Module[
 {plan,pair,diagrams,config,factorized,rows,result,partner,partnerFactorized},
 plan=FeynFacet`DiagramInterferencePlan[setup,"HermitianReduction"->OptionValue["HermitianReduction"]];
 If[!AssociationQ[plan],preIBPFail["interference plan"]];
 pair=Lookup[Lookup[setup,{"ForwardAmplitudes","ConjugateAmplitudes"}],"SelectedIndex",None];
 If[!MatchQ[pair,{_Integer,_Integer}],preIBPFail["diagram selection"]];
 diagrams=GenerateDiagram[setup,"PreparedDiagrams"->OptionValue["PreparedDiagrams"]];
 If[!AssociationQ[diagrams],preIBPFail["GenerateDiagram"]];
 config=Append[setup,"DiagramsBySide"->diagrams];factorized=factorizePair[config];
 If[!AssociationQ[factorized],preIBPFail["CollinearFactorize"]];
 result=factorizedToPreIBP[config,factorized];
 If[!MatchQ[result,{_,_,_,_,_List}],preIBPFail["first interference"]];
 rows={<|"Setup"->setup,"Result"->result,"ConstructionMethod"->"Direct amplitude contraction"|>};
 If[TrueQ[plan["HermitianReduction"]] && pair[[1]]=!=pair[[2]],
   partner=interferencePairSetup[setup,Reverse[pair]];
   partnerFactorized=factorizePair[Append[partner,"DiagramsBySide"->diagrams],
     hermitianConjugateContraction[factorized["Contraction"],setup]];
   If[!AssociationQ[partnerFactorized],preIBPFail["Hermitian contraction"]];
   result=factorizedToPreIBP[partner,partnerFactorized];
   If[!MatchQ[result,{_,_,_,_,_List}],preIBPFail["Hermitian interference"]];
   AppendTo[rows,<|"Setup"->partner,"Result"->result,
     "ConstructionMethod"->"Hermitian conjugation before integral normalization"|>]];
 rows],$preIBPFailure];
End[];EndPackage[];
