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
