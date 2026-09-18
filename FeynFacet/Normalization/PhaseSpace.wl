(* Canonical state measure and flux, shared by Born, real and virtual densities. *)
BeginPackage["FeynFacet`"];
OnShellInvariantDensityFactor::usage="OnShellInvariantDensityFactor[dimension] is the coefficient of d^(dimension-1)p/E in d^dimension p (2 Pi) delta_+(p^2)/(2 Pi)^dimension. The energy delta derivative supplies 1/(2E).";
LorentzInvariantIncidentFlux::usage="LorentzInvariantIncidentFlux[s,m1Squared,m2Squared,assumptions] derives the two-particle incident flux 2 sqrt(lambda(s,m1Squared,m2Squared)). No incoming identical-particle factorial is included.";
Begin["`Private`"];
OnShellInvariantDensityFactor[dimension_]:=(2Pi)/(2(2Pi)^dimension);
LorentzInvariantIncidentFlux[s_,m1_,m2_,assumptions_:True]:=
 FullSimplify[2Sqrt[(s-m1-m2)^2-4m1 m2],Assumptions->assumptions];
FeynFacet`PartonicInvariantDensityNormalization::usage="PartonicInvariantDensityNormalization[setup,request] supplies the common flux, incoming color average, observed measure and removal of PDF/FF fractions for E_c d sigma/d^(D-1)p_c. It applies equally to Born, real and virtual contributions; loop and unobserved phase-space measures belong to the amplitude and master definitions.";
FeynFacet`PartonicInvariantDensityNormalization[setup_Association,request_Association]:=Catch[Module[
 {s,e,partons,hadrons,fractions,observed,dimensions,distribution,fractionFactor,colorFactor,flux,observedMeasure},
 If[!ContainsAll[Keys[request],{"Scale","DimensionalRegulator"}],collinearKernelFail["InvariantDensityNormalizationRequestRequired"]];
 {s,e}=Lookup[request,{"Scale","DimensionalRegulator"}];
 {partons,hadrons,fractions}=Lookup[setup,{"Partons","HadronMomentum","MomentumFraction"}];
 observed=Flatten[Position[(!MissingQ[#]& /@ Last[hadrons]),True]];
 If[Length[First[partons]]=!=2||Length[observed]=!=1,collinearKernelFail["OneObservedPartonAndTwoIncomingRequired"]];
  If[KeyExistsQ[request,"IncomingColorDimensions"],collinearKernelFail["IndependentIncomingColorAverageIsNotAnObservableDefinition"]];
  dimensions=Map[Which[
  MatchQ[#,FeynArts`F[__]|-FeynArts`F[__]],FeynCalc`CA,
  MatchQ[#,FeynArts`V[5]],FeynCalc`CA^2-1,
   True,collinearKernelFail["IncomingColorRepresentationRequired",<|"Parton"->#|>]]&,First[partons]];
 If[!MatchQ[dimensions,{_,_}],collinearKernelFail["TwoIncomingColorDimensionsRequired"]];
 distribution=setup["CoefficientKinematics"]["DistributionFactor"];
 fractionFactor=(Times@@First[fractions]) Last[fractions][[First[observed]]]^2;
 colorFactor=1/(Times@@dimensions);flux=1/FeynFacet`LorentzInvariantIncidentFlux[s,0,0,s>0];
  observedMeasure=FeynFacet`OnShellInvariantDensityFactor[4-2e];
 <|"Factor"->fractionFactor/distribution colorFactor flux observedMeasure,
  "FluxFactor"->flux,"ObservedMeasure"->observedMeasure,"IncomingColorAverage"->colorFactor,
  "RemovedDistributionFactor"->distribution,"RemovedFractionDenominator"->fractionFactor,
  "IncomingSpinAverage"->"Included by quark/gluon correlator projectors"|>
 ],"CollinearCounterterms"];

End[];EndPackage[];
