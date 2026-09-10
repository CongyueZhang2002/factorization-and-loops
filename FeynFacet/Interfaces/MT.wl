(* Analytic Mellin convolutions via the published MT package.
   The adapter consumes ordinary delta/plus/regular records on 0<x<=1.
   It never reads process cross-section tables distributed with MT. *)
BeginPackage["FeynFacet`"];
MellinConvolveDistributions::usage="MellinConvolveDistributions[f,g,x] computes the Mellin convolution of two delta/plus/regular distributions on 0<x<=1. DeltaCoefficient and PlusCoefficients must be x-independent. It returns explicit coefficients and fails if MT leaves an unresolved transform.";
Begin["`Private`"];
mellinConvolutionFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"MellinConvolution"];
initializeMellinConvolution[]:=Module[{directory,entry,hadGlobalMT},
 If[MemberQ[$Packages,"MT`"],Return[True]];
 directory=FileNameJoin[{$feynFacetRoot,"Addon","Mathematica_Addon"}];
 entry=FileNameJoin[{directory,"MT","MT.m"}];
 If[!FileExistsQ[entry],mellinConvolutionFail["MTInstallationRequired"]];
 hadGlobalMT=System`Names["Global`MT"]=!={};
 (* MT declares a Global MT message symbol which would shadow FeynCalc's
    metric shorthand. Preserve an existing symbol and remove only a new one.
    MT's ClearAll affects MT contexts, never the inherited Global MT symbol. *)
 Quiet[ToExpression["Global`MT",InputForm,Function[metric,
  Internal`InheritedBlock[{metric},
   Block[{$ContextPath=$ContextPath,Global`$MTStartupMessages=False},
    If[!MemberQ[$Packages,"HPL`"],Block[{Print},Global`FACETLoadAddon["HPL"]]];
    Block[{$Path=Prepend[$Path,FileNameJoin[{directory,"MT"}]]},Get[entry]]]],
  HoldAllComplete]],General::shdw];
 If[!hadGlobalMT,Remove["Global`MT"]];
 If[!MemberQ[$Packages,"MT`"],mellinConvolutionFail["MTInitializationFailed"]];True
];
mellinDistributionInput[row_,x_]:=Module[{plus},
 If[!AssociationQ[row]||!ContainsAll[Keys[row],{"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]||
  Lookup[row,"Variable",x]=!=x||Lookup[row,"Interval",{0,1}]=!={0,1},
  mellinConvolutionFail["UnitIntervalDistributionRequired"]];
 plus=row["PlusCoefficients"];
 If[!AssociationQ[plus]||!AllTrue[Keys[plus],IntegerQ[#]&&#>=0&]||
  !FreeQ[{row["DeltaCoefficient"],plus},x]||
  !FreeQ[Values[KeyTake[row,{"DeltaCoefficient","PlusCoefficients","RegularCoefficient"}]],
   _Failure|_Missing|_SeriesData|$Failed|$Aborted|Indeterminate|_DirectedInfinity],
  mellinConvolutionFail["ExplicitCanonicalDistributionRequired"]];
 row["DeltaCoefficient"] MT`PlusDistribution[-1,1-x]+
  Total[KeyValueMap[#2 MT`PlusDistribution[#1,1-x]&,plus]]+row["RegularCoefficient"]
];
MellinConvolveDistributions[f_Association,g_Association,x_Symbol]:=Catch[Module[
 {left,right,result,objects,orders,delta,plus,regular,native},
 left=mellinDistributionInput[f,x];right=mellinDistributionInput[g,x];
 native=nativeMellinConvolution[f,g,x];
 If[AssociationQ[native],Return[native]];
 initializeMellinConvolution[];
 result=MT`Convolution[left,right,x];
 (* The published inverse table expects harmonic sums and rational poles
    at a common shifted Mellin argument. Convolution can leave such shifts
    unmatched; harmonize those remaining inverse transforms explicitly. *)
 result=FixedPoint[ReplaceAll[#,HoldPattern[MT`MTInverse[argument_,variable_,moment_]]:>
    MT`MTInverse[MT`MTHarmonize[argument,moment],variable,moment]]&,result,4];
 result=HPL`HPLConvertToKnownFunctions[MT`MTPlusSimplify[result]];

 If[!FreeQ[result,_MT`Convolution|_MT`MTMellinn|_MT`MTInverse|_MT`DReg|_Integrate|
   _Failure|_Missing|_SeriesData|$Failed|$Aborted|Indeterminate|_DirectedInfinity],
  mellinConvolutionFail["MellinConvolutionUnresolved",<|"Variable"->x,"Left"->f,"Right"->g,"UnresolvedResult"->result|>]];
 objects=DeleteDuplicates[Cases[result,_MT`PlusDistribution,{0,Infinity}],SameQ];
 If[!AllTrue[objects,MatchQ[# ,MT`PlusDistribution[_Integer,1-x]]&&First[#]>=-1&]||
  !AllTrue[objects,Exponent[result,#]<=1&],
  mellinConvolutionFail["CanonicalMellinDistributionRequired"]];
 result=Expand[result];delta=Coefficient[result,MT`PlusDistribution[-1,1-x]];
 orders=Sort[DeleteCases[First/@objects,-1]];
 plus=Association@Table[k->Factor[Coefficient[result,MT`PlusDistribution[k,1-x]]],{k,orders}];
 regular=result/._MT`PlusDistribution->0;
 If[!FreeQ[{delta,plus},x]||!FreeQ[{delta,plus,regular},_MT`PlusDistribution],
  mellinConvolutionFail["CanonicalMellinDistributionRequired"]];
 Join[partonicDistribution[Factor[delta],plus,Factor[regular]],<|"Variable"->x,"Interval"->{0,1}|>]
],"MellinConvolution"];
End[];EndPackage[];
