(* Model adapter: scalar generation sums must survive FCFAConvert's
   removal of spin/color SumOver wrappers. For declared degenerate massless
   SMQCD classes, the generation sum is exactly its flavor multiplicity. *)
modelMasslessFlavorDeclarations[config_Association] := Module[{counts},
 counts=Lookup[config,"MasslessQuarkFlavors",<||>];
 If[!AssociationQ[counts]||Complement[Keys[counts],{"UpType","DownType"}]=!={}||
  !AllTrue[Values[counts],MatchQ[#,_Symbol|_Integer?NonNegative]&],
  fail["MasslessQuarkFlavors",counts,"Declare nonnegative integer or symbolic multiplicities for UpType and DownType massless quark classes."]];
 If[counts=!=<||>&&Lookup[config,"Model",None]=!="SMQCD",
  fail["MasslessQuarkFlavors",counts,"This massless flavor adapter is defined for the SMQCD model."]];counts
];
modelResolveFlavorSums[amplitude_,process_Association] := Module[
 {result=amplitude,counts=Lookup[process,"MasslessQuarkFlavors",<||>],sums,index,masses,classes,
  massTypes=<|"MQU"->"UpType","MQD"->"DownType"|>},
 sums=DeleteDuplicates[Cases[result,
  sum:HoldPattern[FeynArts`SumOver[FeynArts`Index[kind_Symbol,_],_Integer]] /;
    SymbolName[kind]==="Generation":>sum,{0,Infinity}]];
 Do[index=sum[[1]];
  masses=DeleteDuplicates[Cases[result,obj:head_Symbol[arg_] /;
    arg===index&&KeyExistsQ[massTypes,SymbolName[head]]:>obj,{0,Infinity}]];
  classes=DeleteDuplicates[massTypes[SymbolName[Head[#]]]& /@ masses];
  If[Length[classes]=!=1||!KeyExistsQ[counts,First[classes]],
   fail["MasslessQuarkFlavors",classes,"A closed generation sum requires an explicit massless flavor multiplicity; it cannot be dropped."]];
  result=result/.((#->0)& /@ masses)/.sum->counts[First[classes]];
  If[!FreeQ[result,index],fail["FlavorSum",index,"The amplitude retains generation dependence beyond the declared degenerate masses."]],
 {sum,sums}];result
];


(* Masslessness belongs to the declared model classes or external legs.
   It is never inferred from the spelling of three favored quark flavors. *)
modelMasslessQuarkMassRules[process_Association]:=Module[
 {counts,classes=<|"UpType"->{"m_u","m_c","m_t"},"DownType"->{"m_d","m_s","m_b"}|>,
  masses={},massless,legs,field,class,generation},
 If[Lookup[process,"Model",None]=!="SMQCD",Return[{}]];
 counts=Lookup[process,"MasslessQuarkFlavors",<||>];
 masses=Flatten[Lookup[classes,Keys[counts],{}]];
 massless=Join[Lookup[process,"MasslessMomenta",{}],Lookup[process,"SetMassZero",{}]];
 legs=Join[Lookup[process,"Incoming",{}],Lookup[process,"Outgoing",{}]];
 Do[
  If[!MemberQ[massless,Lookup[leg,"Momentum",None]],Continue[]];
  field=Lookup[leg,"Parton",None]/.-FeynArts`F[a___]:>FeynArts`F[a];
  If[!MatchQ[field,FeynArts`F[3|4,{_Integer}]],Continue[]];
  class=If[field[[1]]===3,"UpType","DownType"];generation=field[[2,1]];
  If[1<=generation<=3,AppendTo[masses,classes[class][[generation]]]],
 {leg,legs}];
 Thread[(FeynCalc`SMP/@DeleteDuplicates[masses])->0]
];


(* Change the photon-quark vertex in the model before FeynArts constructs
   amplitudes. Both chiral tree components receive the same declared charge.
   Numeric constants elsewhere in the model and complete amplitudes are never
   replaced. Fermion-flow and antiquark signs remain FeynArts' responsibility. *)
modelElectromagneticCharges[config_Association]:=Module[{charges},
 charges=Lookup[config,"ElectromagneticCharges",<||>];
 If[!AssociationQ[charges]||Complement[Keys[charges],{"UpType","DownType"}]=!={}||
  !AllTrue[Values[charges],FreeQ[#,_Real|_List|_Association|_Rule|_RuleDelayed|_Failure|_Missing]&]||
  (charges=!=<||>&&Lookup[config,"Model",None]=!="SMQCD"),
  fail["ElectromagneticCharges",charges,"Declare exact UpType and DownType photon-quark charges for SMQCD."]];
 charges
];
modelReplacePhotonQuarkCharges[charges_Association]:=Module[
 {counts=<||>,types=<|3->"UpType",4->"DownType"|>,baseline=<|3->2/3,4->-1/3|>,replace},
 replace[entry_]:=Module[{fields,classes,type,rows,quarkClass},
  If[Head[entry]=!=Equal,Return[entry]];
  fields=First[entry];
  If[Length[fields]=!=3||FreeQ[fields,FeynArts`V[1]],Return[entry]];
  classes=Cases[fields,FeynArts`F[c:(3|4),_List]:>c,Infinity];
  If[Length[classes]=!=2||Length[DeleteDuplicates[classes]]=!=1,Return[entry]];
  quarkClass=First[classes];type=types[quarkClass];
  If[!KeyExistsQ[charges,type],Return[entry]];
  rows=Last[entry];
  If[!MatrixQ[rows]||Length[rows]=!=2||
   !TrueQ[Simplify[rows[[1,1]]-rows[[2,1]]]===0],
   fail["ElectromagneticCharges",entry,"Expected the two equal tree chiral components of the vector vertex."]];
  rows[[All,1]]*=charges[type]/baseline[quarkClass];
  AssociateTo[counts,type->(Lookup[counts,type,0]+1)];
  Equal[fields,rows]
 ];
 FeynArts`M$CouplingMatrices=replace/@FeynArts`M$CouplingMatrices;
 If[!AllTrue[Keys[charges],Lookup[counts,#,0]===1&],
  fail["ElectromagneticCharges",counts,"Each requested photon-quark vertex must be replaced exactly once."]];
 Null
];
modelInitializeCurrentCharges[setup_Association]:=Module[{charges=modelElectromagneticCharges[setup],result},
 If[charges===<||>&&!TrueQ[$feynFacetModelHasCurrentCharges],Return[True]];
 result=Quiet[FeynArts`InitializeModel[setup["Model"],FeynArts`Reinitialize->True,
  FeynArts`ModelEdit:>modelReplacePhotonQuarkCharges[charges]],RuleDelayed::rhs];
 $feynFacetModelHasCurrentCharges=(charges=!=<||>);
 result
];
