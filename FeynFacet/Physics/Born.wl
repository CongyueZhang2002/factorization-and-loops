(* Physical invariant Born density from generated collinear amplitudes.
   The front end includes spin averaging and correlator fractions. Here the
   hadronic distributions are removed and flux, color averages and the
   observed-particle measure are supplied explicitly. *)
BeginPackage["FeynFacet`"];
ConstructBornInvariantDensity::usage="ConstructBornInvariantDensity[setup,request] generates all selected Born diagram interferences and returns b(s,t,u;epsilon) multiplying delta(s+t+u) in E_c d sigma/d^(D-1)p_c. Request declares Scale, MandelstamVariables and DimensionalRegulator. Incoming color averages follow the declared QCD field representations.";
ConstructBornResult::usage="ConstructBornResult[setup,request] computes a Born density and returns explicit epsilon coefficients in the common result format. Request includes Variables and EpsilonRange.";
Begin["`Private`"];
bornInterferenceRows[setup_,selectedPair_,normalization_,prepared_:Automatic]:=Catch[Module[
 {pairSetup,diagrams,interferences,preibp,expression,rows={}},
 diagrams=If[prepared===Automatic,PrepareProcessDiagrams[setup],prepared];
 If[!AssociationQ[diagrams],collinearKernelFail["BornDiagramGenerationFailed"]];
 pairSetup=interferencePairSetup[setup,selectedPair];
 pairSetup=Join[pairSetup,<|"DiagramsBySide"->diagrams["DiagramsBySide"]|>];
 interferences=FeynFacet`CollinearFactorizeInterferencesPreIBP[pairSetup,"PreparedDiagrams"->diagrams];
 If[!ListQ[interferences],collinearKernelFail["BornInterferenceFailed"]];
 Do[
  preibp=interference["Result"];
  If[!MatchQ[preibp,{_,_,_,_,{}}],collinearKernelFail["BornInterferenceFailed",<|"Pair"->selectedPair|>]];
  (* Individual gluon interferences depend on reference vectors and can
     simplify very slowly. Normalize them exactly and simplify their
     gauge-complete sum once in ConstructBornInvariantDensity. *)
  expression=preibp[[2]]preibp[[4]]normalization;
  AppendTo[rows,<|"Pair"->Lookup[Lookup[interference["Setup"],{"ForwardAmplitudes","ConjugateAmplitudes"}],"SelectedIndex"],
   "Coefficient"->expression,"ConstructionMethod"->interference["ConstructionMethod"]|>],
 {interference,interferences}];rows
],"CollinearCounterterms"];

bornParallelInterferenceRows[setup_,pairs_,normalization_,count_]:=Module[{opened,result},
 opened=facetLaunchKernels[count];
 If[Length[opened]<2,If[opened=!={},CloseKernels[opened]];Return[$Failed]];
 Internal`WithLocalSettings[Null,
  With[{load=FileNameJoin[{$feynFacetRoot,"Addon","Load","LoadFACET.wl"}]},
   ParallelEvaluate[$HistoryLength=0;$MaxExtraPrecision=50;
    SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
    Block[{$Output={}},Quiet[Get[load],General::shdw]],opened]];
  result=WaitAll[Table[With[{spec=setup,pair=selected,norm=normalization},
   ParallelSubmit[Block[{Print},FeynFacet`Private`bornInterferenceRows[spec,pair,norm]]]],{selected,pairs}]],
  CloseKernels[opened]];
 result
];
ConstructBornInvariantDensity[setup_Association,request_Association]:=Catch[Module[
 {e,s,mandel,forward,conjugate,diagrams,partons,hadrons,fractions,observed,
  dimensions,distribution,fractionFactor,colorFactor,flux,observedMeasure,
  rows={},pairSetup,preibp,expression,total,seconds,context,plan,interferences,hadronic,assumptions,colorRules,kernelCount,pairRows},
 If[!ContainsAll[Keys[request],{"Scale","MandelstamVariables","DimensionalRegulator"}],collinearKernelFail["BornDensityRequestRequired"]];
 {s,mandel,e}=Lookup[request,{"Scale","MandelstamVariables","DimensionalRegulator"}];
 If[!MatchQ[mandel,{_Symbol,_Symbol,_Symbol}]||!MatchQ[{s,e},{_Symbol,_Symbol}]||s===e,collinearKernelFail["BornKinematicVariablesRequired"]];
 forward=setup["ForwardAmplitudes"];conjugate=setup["ConjugateAmplitudes"];
 If[forward["LoopOrder"]=!=0||conjugate["LoopOrder"]=!=0||Length[setup["PhaseSpaceMomentum"]]=!=1,
  collinearKernelFail["TwoBodyBornProcessRequired"]];
 context=FeynFacet`PartonicInvariantDensityNormalization[setup,request];
 If[FailureQ[context],collinearKernelFail["BornNormalizationFailed",<|"Cause"->context|>]];
 distribution=context["RemovedDistributionFactor"];fractionFactor=context["RemovedFractionDenominator"];
 colorFactor=context["IncomingColorAverage"];flux=context["FluxFactor"];
 observedMeasure=context["ObservedMeasure"]/.e->(4-D)/2;
 diagrams=PrepareProcessDiagrams[setup];If[!AssociationQ[diagrams],collinearKernelFail["BornDiagramGenerationFailed"]];
 plan=FeynFacet`DiagramInterferencePlan[setup];
 If[!AssociationQ[plan],collinearKernelFail["BornInterferencePlanFailed"]];
 kernelCount=Lookup[request,"Kernels",1];
 If[!IntegerQ[kernelCount]||!TrueQ[1<=kernelCount<=8],collinearKernelFail["BornKernelCountRequired"]];
 kernelCount=facetKernelCount[kernelCount,Length[plan["Pairs"]]];
 pairRows=If[kernelCount>1&&Length[plan["Pairs"]]>=8&&Kernels[]==={},
  bornParallelInterferenceRows[setup,plan["Pairs"],fractionFactor/distribution,Min[kernelCount,Length[plan["Pairs"]]]],$Failed];
 If[pairRows===$Failed,pairRows=bornInterferenceRows[setup,#,fractionFactor/distribution,diagrams]&/@plan["Pairs"]];
 If[!ListQ[pairRows]||!AllTrue[pairRows,ListQ],collinearKernelFail["BornInterferenceFailed",<|"Cause"->Select[pairRows,FailureQ]|>]];
 rows=Flatten[pairRows,1];
 hadronic=cardHadronicVariables[setup];assumptions=cardAssumptions[setup,hadronic];
  colorRules=Lookup[request,"ColorRules",{}];
  If[!MatchQ[colorRules,{(_Rule|_RuleDelayed)...}],collinearKernelFail["ColorIdentityRulesRequired"]];
  total=applyHadronicVariables[Total[Lookup[rows,"Coefficient"]],hadronic]/.colorRules;
  If[MemberQ[{total,assumptions},$Failed|$Aborted],collinearKernelFail["BornSimplificationFailed"]];
  total=FullSimplify[Factor[expandPositiveMonomialPowers[total,assumptions]],Assumptions->assumptions] colorFactor flux observedMeasure;
  If[MemberQ[{total},$Failed|$Aborted],collinearKernelFail["BornSimplificationFailed"]];
 (* FullSimplify may recombine positive square roots and hide exact
    fraction cancellation. Finish with the declared real-root algebra. *)
 total=Factor[expandPositiveMonomialPowers[total/.D->4-2e,assumptions]];
 If[!FreeQ[total,Alternatives@@$twist2DistributionHeads],
  collinearKernelFail["BornDistributionProjectionIncomplete"]];
 If[!FreeQ[total,_FeynCalc`SMP|_FeynCalc`Pair|_FeynCalc`GLI|_Cut|_Integrate|_DiracTrace|_Failure|_Missing|_SeriesData|$Failed|$Aborted],
  collinearKernelFail["ExplicitBornDensityRequired",<|"Expression"->total|>]];
 <|"Format"->"FeynFacet-BornInvariantDensity","FormatVersion"->1,"Coefficient"->total,
  "MandelstamVariables"->mandel,"DimensionalRegulator"->e,"Support"->"delta(s+t+u)",
  "DensityConvention"->"E_c d sigma / d^(D-1) p_c","Setup"->setup,"Pairs"->rows,
  "Normalization"-><|"FluxFactor"->flux,"ObservedMeasure"->(observedMeasure/.D->4-2e),
   "IncomingColorAverage"->colorFactor,"RemovedDistributionFactor"->distribution,
   "RemovedFractionDenominator"->fractionFactor,"IncomingSpinAverage"->"Included by quark/gluon correlator projectors"|>|>
 ],"CollinearCounterterms"];
ConstructBornResult[setup_Association,request_Association]:=Catch[Module[
 {raw,e,s,v,w,range,delta,series,cs,meta,alpha,power,fractionVariables},
 If[KeyExistsQ[setup,"Currents"],Return[FeynFacet`ConstructCurrentBornResult[setup,request]]];
 If[!ContainsAll[Keys[request],{"Scale","Variables","MandelstamVariables","DimensionalRegulator","EpsilonRange","Coupling"}],
  partonicResultFail["BornResultRequestIncomplete"]];
 {e,s,range,alpha}=Lookup[request,{"DimensionalRegulator","Scale","EpsilonRange","Coupling"}];{v,w}=request["Variables"];
 If[!(MatchQ[range,{0,_Integer}]&&Last[range]>=0),partonicResultFail["NonnegativeBornEpsilonRangeRequired"]];
 raw=FeynFacet`ConstructBornInvariantDensity[setup,request];If[FailureQ[raw]||!AssociationQ[raw],partonicResultFail["BornDensityConstructionFailed",<|"Cause"->raw|>]];
 delta=Factor[(raw["Coefficient"]/.Thread[raw["MandelstamVariables"]->{s,s(v-1),-s v}])/(s v)];
 fractionVariables=DeleteDuplicates[Cases[List@@setup["MomentumFraction"],_Symbol,Infinity]];
 If[!FreeQ[delta,Alternatives@@fractionVariables],partonicResultFail["BornFractionDependenceRemaining",
  <|"Variables"->Select[fractionVariables,!FreeQ[delta,#]&]|>]];
 series=Normal[Series[delta,{e,0,Last[range]}]];
 cs=Association@Table[j->partonicDistribution[Factor[FunctionExpand[Coefficient[Expand[series],e,j]]],<||>,0],{j,0,Last[range]}];
 power=If[raw["Coefficient"]===0,Lookup[request,"BornCouplingPower",0],Exponent[raw["Coefficient"],alpha]];
 If[raw["Coefficient"]=!=0&&(!PolynomialQ[raw["Coefficient"],alpha]||
 !FreeQ[Cancel[raw["Coefficient"]/alpha^power],alpha]),partonicResultFail["HomogeneousBornCouplingRequired"]];
 meta=Join[KeyTake[request,{"Project","Channel","Scale","Variables","MandelstamVariables","DimensionalRegulator","Coupling","DimensionalPrefactor","Domain","PhysicalChannel","Polarization","ProcessDefinition"}],
  <|"Order"->"LO","Contribution"->"Born","CouplingPower"->power,"GeneratedInterferenceCount"->Length[raw["Pairs"]]|>];
 CreatePartonicResult[cs,meta]],"PartonicResults"];


FeynFacet`ConstructCurrentBornResult::usage="ConstructCurrentBornResult[setup,request] generates a one-particle current Born contribution with exact on-shell and tagging Jacobian, and stores explicit epsilon coefficients in the common endpoint format.";
partonicCornerDistribution[value_,0]:=value;
partonicCornerDistribution[value_,1]:=partonicDistribution[value,<||>,0];
partonicCornerDistribution[value_,n_Integer?Positive]:=
 partonicDistribution[partonicCornerDistribution[value,n-1],<||>,partonicDistributionZero[n-1]];
currentBornSupport[request_Association]:=Module[
 {variables=request["Variables"],axes=request["DistributionBasis"],point,kinematics,momentumRules,
  constraints,solutions,determinant,measure},
 axes=axes["Axes"];variables=Lookup[axes,"Variable"];point=Thread[variables->Lookup[axes,"Endpoint"]];
 (* Support rules override matching invariants; they do not discard the
    four-dimensional rules for explicitly physical external momenta. *)
 kinematics=Normal[Association[FeynCalc`FCI[Join[request["KinematicRules"],
   Lookup[request,"BornSupportKinematicRules",{}]]]]];
 momentumRules=request["BornMomentumRules"];
 constraints=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[#]/.momentumRules]/.kinematics]&/@request["BornConstraints"];
 If[Length[constraints]=!=Length[variables],partonicResultFail["IsolatedBornSupportRequired"]];
 solutions=Solve[Thread[constraints==0],variables];
 If[Length[solutions]=!=1||!And@@MapThread[TrueQ[Factor[#1-#2]===0]&,{variables/.First[solutions],variables/.point}],
  partonicResultFail["UniqueDeclaredBornSupportRequired"]];
 determinant=Det[Outer[D,constraints,variables]];
 determinant=FullSimplify[Abs[determinant/.point],Assumptions->Lookup[request,"Assumptions",True]];
 If[!TrueQ[FullSimplify[determinant>0,Assumptions->Lookup[request,"Assumptions",True]]],
  partonicResultFail["NondegenerateBornSupportRequired"]];
 measure=2Pi/determinant*request["CurrentNormalization"];
 <|"Variables"->variables,"Axes"->axes,"Point"->point,"KinematicRules"->kinematics,
  "MomentumRules"->momentumRules,"JacobianDeterminant"->determinant,"Measure"->measure|>
];
FeynFacet`ConstructCurrentBornResult[setup_Association,request_Association]/;
 Length[Last[setup["Partons"]]]===2&&AnyTrue[Lookup[setup,"SpinDensities",{}],
  Lookup[#,"Role",None]==="FF"&&Lookup[#,"MomentumSpace",None]==="Physical4"&]:=
 FeynFacet`ConstructFixedObservedBornResult[setup,request];

FeynFacet`ConstructFixedObservedBornResult::usage="ConstructFixedObservedBornResult[setup,request] integrates the single unobserved on-shell recoil at tree level while keeping the tagged momentum physical and fixed. It derives the endpoint Jacobian, verifies that ordinary Born denominators do not vanish in the stated domain, and retains the requested epsilon coefficients.";
FeynFacet`ConstructFixedObservedBornResult[setup_Association,request_Association]:=Catch[Module[
 {generated,support,scalar,kin,physical,conditions,e,range,denominators,cores,series,coefficients,meta},
 If[!ContainsAll[Keys[request],{"CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints",
   "CurrentNormalization","DistributionBasis","Variables","DimensionalRegulator","EpsilonRange","BareCouplingRules"}]||
   Lookup[setup["ForwardAmplitudes"],"LoopOrder"]!=0||Lookup[setup["ConjugateAmplitudes"],"LoopOrder"]!=0||
   Length[Last[setup["Partons"]]]=!=2||Length[request["DistributionBasis"]["Axes"]]=!=1||
   !MatchQ[request["EpsilonRange"],{0,_Integer?NonNegative}],
  partonicResultFail["FixedObservedTreeCurrentAndOneRecoilRequired"]];
 support=currentBornSupport[request];
 generated=FeynFacet`ConstructCurrentIntegrands[setup,request];
 If[!AssociationQ[generated],partonicResultFail["CurrentBornGenerationFailed",<|"Cause"->generated|>]];
 e=request["DimensionalRegulator"];range=request["EpsilonRange"];
 conditions=Lookup[request,"Assumptions",True]/.support["Point"];
 kin=Normal[Association[Join[support["KinematicRules"],
  support["KinematicRules"]/.FeynCalc`Momentum[a_,D]:>FeynCalc`Momentum[a]]]];
 physical=DeleteDuplicates[Join[setup["PhysicalMomenta"],Flatten[
  Values[Lookup[#,"SpinVectors",<||>]]&/@Lookup[request,"SpinCorrelations",{}]]]];
 scalar=FeynCalc`ExpandScalarProduct[FeynCalc`FCI[#]/.support["MomentumRules"]]&/@Values[generated["Values"]];
 denominators=DeleteDuplicates[Cases[scalar,_FeynCalc`FeynAmpDenominator,Infinity]];
 cores=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FeynAmpDenominatorExplicit[#]]/.kin/.support["Point"]]&/@denominators;
 If[!AllTrue[cores,FreeQ[#,_FeynCalc`Pair|_FeynCalc`FeynAmpDenominator|_FeynCalc`SmallVariable]&&
   TrueQ[FullSimplify[Element[#,Reals]&&#!=0,Assumptions->conditions]]&],
  partonicResultFail["NonvanishingOrdinaryBornPropagatorsRequired",<|"Values"->cores|>]];
 scalar=FullSimplify[Factor[setEvanescentZero[
   FeynCalc`ExpandScalarProduct[#/.Thread[denominators->cores]],physical]/.kin/.
   support["Point"]],Assumptions->conditions]&/@scalar;
 scalar=FeynFacet`SubstituteScalarPowers[support["Measure"]scalar,request["BareCouplingRules"]]/.
  Lookup[request,"ColorRules",{}]/.D->4-2e;
 If[!FreeQ[scalar,_FeynCalc`Pair|_FeynCalc`DiracTrace|_FeynCalc`Polarization|_FeynCalc`SMP|_Failure|_Integrate],
  partonicResultFail["ExplicitFixedObservedBornCoefficientRequired",<|"Value"->scalar|>]];
 series=Normal[Series[scalar,{e,0,Last[range]}]];
 coefficients=Association@Table[n->partonicCornerDistribution[FullSimplify[Coefficient[series,e,n],
  Assumptions->conditions],1],{n,0,Last[range]}];
 meta=Join[KeyDrop[request,{"CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints","BareCouplingRules"}],
  <|"Order"->"LO","Contribution"->"Born","StructureFunctions"->Keys[generated["Values"]],
   "ProcessDefinition"->setup,"BornSupportJacobian"->support["JacobianDeterminant"],
   "OrdinaryBornPropagatorValues"->cores,"ObservedMeasureIncluded"->False,
   "UnobservedPhaseSpace"->"2 Pi delta_+((p_total-k_observed)^2)"|>];
 CreatePartonicResult[coefficients,meta]
],"PartonicResults"];

FeynFacet`ConstructCurrentBornResult[setup_Association,request_Association]:=Catch[Module[
 {generated,amplitudes,interference,tensor,projectors,kinematics,momentumRules,variables,axes,point,
  constraints,solutions,determinant,measure,scalar,e,range,coefficients,meta,series},
 If[!ContainsAll[Keys[request],{"CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints",
  "CurrentNormalization","DistributionBasis","Variables","DimensionalRegulator","EpsilonRange"}],
  partonicResultFail["CurrentBornGeometryRequired"]];
 If[Lookup[setup["ForwardAmplitudes"],"LoopOrder"]!=0||Lookup[setup["ConjugateAmplitudes"],"LoopOrder"]!=0||
  Length[Last[setup["Partons"]]]=!=1||!MatchQ[request["EpsilonRange"],{0,_Integer?NonNegative}],
  partonicResultFail["OneParticleTreeCurrentRequired"]];
 generated=GenerateCurrentAmplitudes[setup];If[!AssociationQ[generated],partonicResultFail["CurrentBornGenerationFailed"]];
 amplitudes=generated["Amplitudes"];
 interference=Total[Values[amplitudes["Amplitude"]]]*
  conjugatePhysicalAmplitude[Total[Values[amplitudes["Conjugate"]]],setup];
 tensor=ContractPartonicSpinDensities[interference,setup["SpinDensities"],
  KeyTake[setup,{"PhysicalMomenta","MasslessMomenta","SummedGluons","UnobservedGluonStates"}]];
 If[tensor===$Failed||FailureQ[tensor],partonicResultFail["CurrentBornSpinContractionFailed"]];
 {variables,e,range,axes}=Lookup[request,{"Variables","DimensionalRegulator","EpsilonRange","DistributionBasis"}];
 With[{support=currentBornSupport[request]},
  {axes,point,kinematics,momentumRules,measure}=Lookup[support,{"Axes","Point","KinematicRules","MomentumRules","Measure"}]];
 projectors=request["CurrentProjectors"];
 scalar=Table[
  Factor[(FeynCalc`ExpandScalarProduct[FeynCalc`Contract[
   FeynCalc`FCI[tensor projection]/.momentumRules]]/.kinematics/.point)*measure],
 {projection,Values[projectors]}]/.D->4-2e;
 If[!FreeQ[scalar,_FeynCalc`Pair|_FeynCalc`DiracTrace|_FeynCalc`Polarization|_Failure|_Integrate],
  partonicResultFail["ExplicitCurrentBornCoefficientRequired"]];
 series=Normal[Series[scalar,{e,0,Last[range]}]];
 coefficients=Association@Table[n->partonicCornerDistribution[
  Factor[Coefficient[series,e,n]],Length[axes]],{n,0,Last[range]}];
 meta=Join[KeyDrop[request,{"CurrentProjectors","KinematicRules","BornMomentumRules","BornConstraints"}],
  <|"Order"->"LO","Contribution"->"Born","CouplingPower"->0,"StructureFunctions"->Keys[projectors],"ProcessDefinition"->setup|>];
 CreatePartonicResult[coefficients,meta]
],"PartonicResults"];

End[];EndPackage[];
