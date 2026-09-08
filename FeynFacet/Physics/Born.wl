(* Physical invariant Born density from generated collinear amplitudes.
   The front end includes spin averaging and correlator fractions. Here the
   hadronic distributions are removed and flux, color averages and the
   observed-particle measure are supplied explicitly. *)
BeginPackage["FeynFacet`"];
ConstructBornInvariantDensity::usage="ConstructBornInvariantDensity[setup,request] generates all selected Born diagram interferences and returns b(s,t,u;epsilon) multiplying delta(s+t+u) in E_c d sigma/d^(D-1)p_c. Request declares Scale, MandelstamVariables and DimensionalRegulator. IncomingColorDimensions can override the QCD representation dimensions.";
Begin["`Private`"];
FeynFacet`PartonicInvariantDensityNormalization::usage="PartonicInvariantDensityNormalization[setup,request] supplies the common flux, incoming color average, observed measure and removal of PDF/FF fractions for E_c d sigma/d^(D-1)p_c. It applies equally to Born, real and virtual contributions; loop and unobserved phase-space measures belong to the amplitude and master definitions.";
FeynFacet`PartonicInvariantDensityNormalization[setup_Association,request_Association]:=Catch[Module[
 {s,e,partons,hadrons,fractions,observed,dimensions,distribution,fractionFactor,colorFactor,flux,observedMeasure},
 If[!ContainsAll[Keys[request],{"Scale","DimensionalRegulator"}],collinearKernelFail["InvariantDensityNormalizationRequestRequired"]];
 {s,e}=Lookup[request,{"Scale","DimensionalRegulator"}];
 {partons,hadrons,fractions}=Lookup[setup,{"Partons","HadronMomentum","MomentumFraction"}];
 observed=Flatten[Position[(!MissingQ[#]& /@ Last[hadrons]),True]];
 If[Length[First[partons]]=!=2||Length[observed]=!=1,collinearKernelFail["OneObservedPartonAndTwoIncomingRequired"]];
 dimensions=Lookup[request,"IncomingColorDimensions",Automatic];
 If[dimensions===Automatic,dimensions=Map[Which[
  MatchQ[#,FeynArts`F[__]|-FeynArts`F[__]],FeynCalc`CA,
  MatchQ[#,FeynArts`V[5]],FeynCalc`CA^2-1,
  True,collinearKernelFail["IncomingColorRepresentationRequired",<|"Parton"->#|>]]&,First[partons]]];
 If[!MatchQ[dimensions,{_,_}],collinearKernelFail["TwoIncomingColorDimensionsRequired"]];
 distribution=setup["CoefficientKinematics"]["DistributionFactor"];
 fractionFactor=(Times@@First[fractions]) Last[fractions][[First[observed]]]^2;
 colorFactor=1/(Times@@dimensions);flux=1/(2s);observedMeasure=1/(2(2Pi)^(3-2e));
 <|"Factor"->fractionFactor/distribution colorFactor flux observedMeasure,
  "FluxFactor"->flux,"ObservedMeasure"->observedMeasure,"IncomingColorAverage"->colorFactor,
  "RemovedDistributionFactor"->distribution,"RemovedFractionDenominator"->fractionFactor,
  "IncomingSpinAverage"->"Included by quark/gluon correlator projectors"|>
 ],"CollinearCounterterms"];
ConstructBornInvariantDensity[setup_Association,request_Association]:=Catch[Module[
 {e,s,mandel,forward,conjugate,diagrams,partons,hadrons,fractions,observed,
  dimensions,distribution,fractionFactor,colorFactor,flux,observedMeasure,
  rows={},pairSetup,preibp,expression,total,seconds,context},
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
 diagrams=GenerateDiagram[setup];If[!AssociationQ[diagrams],collinearKernelFail["BornDiagramGenerationFailed"]];
 Do[
  pairSetup=Join[setup,<|"ForwardAmplitudes"->Join[forward,<|"SelectedIndex"->fi|>],
   "ConjugateAmplitudes"->Join[conjugate,<|"SelectedIndex"->ci|>],"DiagramsBySide"->diagrams|>];
  {seconds,preibp}=AbsoluteTiming[CollinearFactorizePreIBP[pairSetup]];
  If[!MatchQ[preibp,{_,_,_,_,{}}],collinearKernelFail["BornInterferenceFailed",<|"Pair"->{fi,ci}|>]];
  expression=SimplifyAssum[preibp[[2]]preibp[[4]]fractionFactor/distribution,setup];
  If[!FreeQ[expression,Alternatives@@$twist2DistributionHeads],collinearKernelFail["BornDistributionProjectionIncomplete"]];
  AppendTo[rows,<|"Pair"->{fi,ci},"Coefficient"->expression,"Seconds"->seconds|>],
  {fi,forward["DiagramIndices"]},{ci,conjugate["DiagramIndices"]}];
 total=FullSimplifyAssum[Total[Lookup[rows,"Coefficient"]]colorFactor flux observedMeasure,setup];
 total=total/.D->4-2e;
 If[!FreeQ[total,_FeynCalc`SMP|_FeynCalc`Pair|_FeynCalc`GLI|_Cut|_Integrate|_DiracTrace|_Failure|_Missing|_SeriesData],
  collinearKernelFail["ExplicitBornDensityRequired",<|"Expression"->total|>]];
 <|"Format"->"FeynFacet-BornInvariantDensity","FormatVersion"->1,"Coefficient"->total,
  "MandelstamVariables"->mandel,"DimensionalRegulator"->e,"Support"->"delta(s+t+u)",
  "DensityConvention"->"E_c d sigma / d^(D-1) p_c","Setup"->setup,"Pairs"->rows,
  "Normalization"-><|"FluxFactor"->flux,"ObservedMeasure"->(observedMeasure/.D->4-2e),
   "IncomingColorAverage"->colorFactor,"RemovedDistributionFactor"->distribution,
   "RemovedFractionDenominator"->fractionFactor,"IncomingSpinAverage"->"Included by quark/gluon correlator projectors"|>|>
 ],"CollinearCounterterms"];
FeynFacet`ConstructCollinearBornProcessCards::usage="ConstructCollinearBornProcessCards[template,enumeration,speciesMap] builds the distinct Born process cards required by EnumerateNLOCollinearChannels. The template supplies geometry and beam polarization; speciesMap declares the model particle for every abstract quark, antiquark and gluon species. Generated diagram counts determine the complete selected interference set.";
FeynFacet`ConstructCollinearBornProcessCards[template_Association,enumeration_Association,speciesMap_Association]:=Catch[Module[
 {channels,unique,cards=<||>,rows={},row,channel,id,card,partons,old,new,fractions,distribution,replaceDistribution,ids},
 channels=Lookup[enumeration,"Channels",None];If[!ListQ[channels],collinearKernelFail["CollinearChannelEnumerationRequired"]];
 unique=DeleteDuplicates[Lookup[channels,"BornChannel"]];ids=AssociationThread[unique,Table["Born"<>IntegerString[i,10,2],{i,Length[unique]}]];
 fractions=template["MomentumFraction"];
 replaceDistribution[expr_,oldParton_,newParton_,fraction_,side_]:=Module[{rules},
  If[MatchQ[oldParton,FeynArts`V[5]]===MatchQ[newParton,FeynArts`V[5]],Return[expr]];
  rules=If[side==="Incoming",{f1[fraction]->f1g[fraction],g1L[fraction]->g1g[fraction]},
   {D1[fraction]->D1g[fraction],G1L[fraction]->G1g[fraction]}];
  If[MatchQ[oldParton,FeynArts`V[5]],rules=Reverse /@ rules];expr/.rules];
 Do[
  id=ids[channel];new=Join[channel["Incoming"],{channel["Observed"],channel["Recoil"]}];
  If[!AllTrue[new,KeyExistsQ[speciesMap,#]&],collinearKernelFail["CompleteModelSpeciesMapRequired"]];
  new=Lookup[speciesMap,Key[#]]& /@ new;old=Join[First[template["Partons"]],Last[template["Partons"]]];
  If[Length[old]=!=4||Length[Last[fractions]]=!=2||MissingQ[Last[fractions][[1]]],collinearKernelFail["BornTemplateWithFirstFinalPartonObservedRequired"]];
  distribution=template["CoefficientKinematics"]["DistributionFactor"];
  Do[distribution=replaceDistribution[distribution,old[[k]],new[[k]],First[fractions][[k]],"Incoming"],{k,2}];
  distribution=replaceDistribution[distribution,old[[3]],new[[3]],Last[fractions][[1]],"Observed"];
  card=Join[template,<|"Partons"->(Take[new,2]->Drop[new,2]),
   "CoefficientKinematics"->Join[template["CoefficientKinematics"],<|"DistributionFactor"->distribution|>]|>];
  card=FeynFacet`CompleteProcessDiagramSelection[card];
  If[!AssociationQ[card],collinearKernelFail["CollinearBornDiagramGenerationFailed",<|"Channel"->channel|>]];
  AssociateTo[cards,id->card],{channel,unique}];
 rows=(Join[#,<|"BornCard"->ids[#["BornChannel"]]|>]& /@ channels);
 <|"BornCards"->cards,"Channels"->rows,"SpeciesMap"->speciesMap,"DiagramCoverage"->"Complete generated insertion graph sets"|>
 ],"CollinearCounterterms"];

End[];EndPackage[];
