(* Tensor reduction of a scalar one-loop density at a fixed two-particle
   measurement. Virtual propagator prescriptions are never removed here. *)
BeginPackage["FeynFacet`"];
ReduceMeasuredOneLoopIntegrands::usage=
 "ReduceMeasuredOneLoopIntegrands[values,geometry,request] reduces full-D scalar one-loop numerators at a declared two-particle measurement to scalar B0/C0/D0 functions. Request supplies LoopMomentum. It retains the virtual causal prescription and restores all caller scalar-product settings.";
ReduceOneLoopIntegrands::usage="ReduceOneLoopIntegrands[values,kinematics,request] reduces full-D scalar loop numerators with arbitrary declared external scalar products to B0/C0/D0 functions. Kinematics gives ExternalMomenta, KinematicRules, Assumptions and DimensionalRegulator. Optional MomentumRules are applied before reduction. It retains prescribed external factors separately from their nonzero interior values.";
Begin["`Private`"];
(* Install the external Gram matrix before tensor reduction, including at
   on-shell kinematics. Substitution only after TID can create spurious 0/0.
   The held calculation cannot inherit or overwrite caller scalar products. *)
SetAttributes[withOneLoopKinematics,HoldFirst];
withOneLoopKinematics[body_,rules_List]:=Module[{fullRules=rules},
 Block[{FeynCalc`$ParallelizeFeynCalc=False},
 Internal`InheritedBlock[{FeynCalc`Pair,FeynCalc`ScalarProduct,FeynCalc`SP,FeynCalc`SPD,
   FeynCalc`SPE,FeynCalc`$ScalarProducts},
  DownValues[FeynCalc`Pair]=FeynCalc`Package`initialPairDownValues;
  DownValues[FeynCalc`ScalarProduct]=FeynCalc`Package`initialScalarProductDownValues;
  DownValues[FeynCalc`SP]=FeynCalc`Package`initialSPDownValues;
  DownValues[FeynCalc`SPD]=FeynCalc`Package`initialSPDDownValues;
  DownValues[FeynCalc`SPE]=FeynCalc`Package`initialSPEDownValues;
  FeynCalc`$ScalarProducts=FeynCalc`Package`initialScalarProducts;
  Do[With[{a=rule[[1]],b=rule[[2]],value=rule[[3]]},
   FeynCalc`SPD[a,b]=value],{rule,fullRules}];
  body
 ]]
];

ReduceMeasuredOneLoopIntegrands[values_Association,geometry_Association,request_Association]:=Module[
 {momenta,kinematics,result},
 If[Lookup[geometry,"Geometry",None]=!="TwoParticleMeasurement"||
   Dimensions[Lookup[geometry,"FullDimensionalScalarProductMatrix",None]]=!={4,4},
  Return[Failure["ExplicitMeasuredScalarProductMatrixRequired",<||>]]];
 momenta=geometry["Momenta"];
 kinematics=<|"ExternalMomenta"->momenta,
  "KinematicRules"->Flatten[Table[FeynCalc`SPD[momenta[[i]],momenta[[j]]]->geometry["FullDimensionalScalarProductMatrix"][[i,j]],
   {i,4},{j,i,4}]],
  "MomentumRules"->Join[{momenta[[4]]->momenta[[2]]-momenta[[3]]},geometry["MomentumRules"]],
  "Assumptions"->geometry["Assumptions"],"DimensionalRegulator"->geometry["DimensionalRegulator"]|>;
 result=ReduceOneLoopIntegrands[values,kinematics,request];
 If[AssociationQ[result],Join[result,<|"Format"->"FeynFacet-MeasuredOneLoopIntegrands","Measurement"->geometry|>],result]
];

ReduceOneLoopIntegrands[values_Association,geometry_Association,
 request_Association]:=Catch[Module[
 {loop=Lookup[request,"LoopMomentum",None],limit=Lookup[request,"TimeLimit",300],
  momenta,gram,fullRules,momentumRules,result=<||>,interior=<||>,externalRecords=<||>,timings=<||>,scalar,reduced,seconds,objects,externalObjects,externalRules,externalValues},
 If[!MatchQ[loop,_Symbol]||!ContainsAll[Keys[geometry],
   {"ExternalMomenta","KinematicRules","Assumptions","DimensionalRegulator"}]||
   values===<||>||!NumericQ[limit]||limit<=0,
  Throw[Failure["OneLoopReductionKinematicsRequired",<||>],"MeasuredOneLoop"]];
 momenta=geometry["ExternalMomenta"];
 If[!MatchQ[momenta,{__Symbol}]||!DuplicateFreeQ[Prepend[momenta,loop]],
  Throw[Failure["IndependentVirtualLoopMomentumRequired",<||>],"MeasuredOneLoop"]];
 gram=Factor[FeynCalc`FCI[Outer[FeynCalc`SPD,momenta,momenta]]/.FeynCalc`FCI[geometry["KinematicRules"]]];
 If[!FreeQ[gram,_FeynCalc`Pair|_Failure|_Missing],
  Throw[Failure["CompleteExternalScalarProductsRequired",<||>],"MeasuredOneLoop"]];
 fullRules=Flatten[Table[{momenta[[i]],momenta[[j]],gram[[i,j]]},
  {i,Length[momenta]},{j,i,Length[momenta]}],1];
 momentumRules=Lookup[geometry,"MomentumRules",{}];
 withOneLoopKinematics[
  Do[
   {seconds,reduced}=AbsoluteTiming[TimeConstrained[
    scalar=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[values[name]]/.momentumRules];
    If[TrueQ[Lookup[request,"FactorInput",True]],scalar=Factor[scalar]];
    If[!FreeQ[scalar,FeynCalc`Momentum[_]|FeynCalc`Momentum[_,4]|
       FeynCalc`Momentum[_,D-4]|_FeynCalc`Eps|_FeynCalc`LorentzIndex|_FeynCalc`DiracGamma|_FeynCalc`DiracTrace],
     Throw[Failure["FullDimensionalScalarLoopNumeratorRequired",<|"Structure"->name|>],"MeasuredOneLoop"]];
    reduced=FeynCalc`TID[scalar,loop,FeynCalc`ToPaVe->True];
    externalObjects=DeleteDuplicates[Cases[reduced,_FeynCalc`FeynAmpDenominator,{0,Infinity}]];
    If[!FreeQ[externalObjects,loop]||!FreeQ[reduced/.Thread[externalObjects->1],
       _FeynCalc`TID|_FeynCalc`PaVe|_FeynCalc`GenPaVe|
       _FeynCalc`Pair|_FeynCalc`Momentum|Indeterminate|_DirectedInfinity],
     Throw[Failure["ScalarLoopTensorReductionIncomplete",<|"Structure"->name|>],"MeasuredOneLoop"]];
    objects=DeleteDuplicates[Cases[reduced,_FeynCalc`B0|_FeynCalc`C0|_FeynCalc`D0,{0,Infinity}]];
    externalValues=Factor[FeynCalc`FeynAmpDenominatorExplicit[#]]&/@externalObjects;
    If[!AllTrue[externalValues,FreeQ[#,_FeynCalc`Pair|_FeynCalc`Momentum|Indeterminate|_DirectedInfinity]&&
       TrueQ[FullSimplify[Denominator[Together[#]]!=0,Assumptions->geometry["Assumptions"]]]&],
     Throw[Failure["NonzeroExternalPropagatorOnOpenMeasuredDomainRequired",<|"Structure"->name|>],"MeasuredOneLoop"]];
    externalRules=Thread[externalObjects->externalValues];
    AssociateTo[externalRecords,name->externalRules];
    AssociateTo[interior,name->Collect[reduced/.externalRules,objects,Factor]];
    Collect[reduced,objects,Factor],
    limit,Failure["MeasuredOneLoopTensorReductionTimeLimit",<|"Structure"->name|>]]];
   If[FailureQ[reduced],Throw[reduced,"MeasuredOneLoop"]];
   AssociateTo[result,name->reduced];AssociateTo[timings,name->seconds];
   If[TrueQ[Lookup[request,"PrintTimings",False]],
    Print["MEASURED LOOP REDUCTION ",name," SECONDS ",seconds," SCALAR FUNCTIONS ",Length[objects]]],
  {name,Keys[values]}],fullRules];
 <|"Format"->"FeynFacet-OneLoopIntegrands","FormatVersion"->1,
  "Values"->result,"InteriorValues"->interior,"ExternalPropagatorInteriorValues"->externalRecords,
  "ExternalPropagatorScope"->"The original prescribed external factors remain in Values. InteriorValues uses their ordinary nonzero values on the declared open domain; it does not authorize endpoint distribution limits.",
  "Kinematics"->geometry,"TensorReductionSeconds"->timings,
  "DimensionalRegulator"->geometry["DimensionalRegulator"],
  "DimensionRule"->(D->4-2geometry["DimensionalRegulator"]),
  "ScalarFunctionConvention"->"FeynCalc PaVe, normalized by 1/(i pi^2).",
  "VirtualPrescriptionRemoved"->False,"PhaseSpaceDensityIncluded"->False,
  "ConjugateInterferenceAdded"->False|>
],"MeasuredOneLoop"];
End[];EndPackage[];
