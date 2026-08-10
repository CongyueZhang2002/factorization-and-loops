(* ::Package:: *)

If[Names["FeynCalc`$FeynCalcVersion"] === {}, Needs["FeynCalc`"]];

BeginPackage["FeynFacet`"];

ClearAll["FeynFacet`*"];
ClearAll["FeynFacet`Private`*"];

Get[FileNameJoin[{DirectoryName[$InputFileName], "Distributions.wl"}]];

DeclareScalar::usage =
  "DeclareScalar[expr] declares the scalar pieces of expr as FeynCalc variables.";

BuildBasis::usage =
  "BuildBasis[{nb,n,xhat,yhat}, assumptions] validates a light-cone basis.";

Build4Vec::usage =
  "Build4Vec[coordinates, basis] constructs a vector from basis coordinates.";

BuildGlobalBasis::usage =
  "BuildGlobalBasis[{nb,n,xhat,yhat}] installs and validates the global basis.";

GlobalBasisGram::usage =
  "GlobalBasisGram is the Gram matrix of {nb,n,xhat,yhat}.";

NA::usage =
  "NA marks a parton with no associated hadron quantity.";

SimplifyAssum::usage =
  "SimplifyAssum[expr, assumptions] applies Simplify with assumptions. A process card may be supplied to infer its momentum-fraction domain.";

FullSimplifyAssum::usage =
  "FullSimplifyAssum[expr, assumptions] applies FullSimplify with assumptions. A process card may be supplied to infer its momentum-fraction domain.";

BuildSimplificationContext::usage =
  "BuildSimplificationContext[setup] validates the required CoefficientKinematics block. It certifies the source and dimensionless physical chambers, mass dimensions, invertible coordinate map, positive fractions and scale, twist-2 factor, Laurent valuation, forbidden variables, and branch grammar.";

SimplifyHardCoefficients::usage =
  "SimplifyHardCoefficients[data,setup] applies one card-defined exact normalization to NLO or NNLO coefficients. Both assembled coefficients and contribution groups use the same twist-2, fraction-root, branch-preserving, forbidden-variable, and dimensionless-coordinate kernel. data may be {c1,...} with Method->\"Assembled\" or {{c11,c12,...},...} with Method->\"ContributionWise\"; Automatic infers the input form.";

ToFeynFacetForm::usage =
  "ToFeynFacetForm[expr] converts FeynCalc internal expressions to compact external FeynCalc syntax such as SP, SPD, SPE, FAD and SFAD. It preserves the dimensional meaning of scalar products and returns $Failed if an internal scalar-product object remains.";

FeynFacet`dD::usage =
  "dD[k] is the remaining D-dimensional integration measure for k.";

dFraction::usage =
  "dFraction[x] is the differential measure for a momentum fraction x.";

Cut::usage =
  "Cut[SPD[q],direction] is an oriented on-shell cut propagator. direction=1 denotes theta(q^0) delta(q^2), direction=-1 denotes theta(-q^0) delta(q^2), and Cut[SPD[q]] is shorthand for direction=1.";

PartialFraction::usage =
  "PartialFraction[expr,{k1,...}] applies ApartFF while retaining every Cut propagator and its positive-energy orientation in each returned term. With no loop momenta, PartialFraction[expr,{}] returns expr unchanged.";

BuildTopologies::usage =
  "BuildTopologies[fractions,{k1,...},setup] constructs a complete cut-aware FCTopology for every denominator family in a partial-fraction result, names it TopologyF<forward SelectedIndex>C<conjugate SelectedIndex>N<n>, prints a topology summary including cut directions, and returns the family data with CutMomenta, CutIndices and CutDirections. External momenta and on-shell rules are inferred from the denominators and setup. With no loop momenta and fractions equal to 1, it returns an empty family list.";

IdentifySafePropagator::usage =
  "IdentifySafePropagator[setup,propagator] returns True when a massless phase-space propagator Q^2 has one fixed sign, allowing zeros on the phase-space boundary, and returns $Failed otherwise.";

TopologyEquivalence::usage =
  "TopologyEquivalence[topologies,setup] finds conservative multiloop equivalence classes. Accepted mappings have exact rational unit Jacobian and preserve every propagator, cut slot, cut energy direction and the phase-space/forward/conjugate loop partition inferred from setup.";

GenerateDiagram::usage =
  "GenerateDiagram[setup] generates and returns the complete FeynArts diagram lists for Setup[\"ForwardAmplitudes\"] and Setup[\"ConjugateAmplitudes\"].";

DimensionalShift::usage =
  "DimensionalShift[integrand,families,{k1,...}] applies the topology-dependent dimensional shift to every integral family, collects the GLI coefficients without expensive simplification, prints a result summary, and returns the collected expression. With no families and no loop momenta, it returns integrand unchanged. Coefficients should be simplified after IBP and master aggregation. DimensionalShift[integrand,propagators,{k1,...},topology] applies the shift to one family.";

CommonFactorSafe::usage =
  "CommonFactorSafe[expr,{k1,...}] extracts a common prefactor while retaining scalar products that depend on loop momenta, propagators, cuts, measures and GLI master integrals in the remainder.";

CollinearFactorize::usage =
  "CollinearFactorize[config] returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Propagators,LoopMomentum}. LoopMomentum contains the remaining phase-space momenta followed by the forward and conjugate virtual-loop momenta.";

CollinearFactorizePreIBP::usage =
  "CollinearFactorizePreIBP[config] runs diagram generation, collinear factorization, partial fractioning, topology construction and dimensional shifting from one configuration Association. It returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Topologies}, where Integrand is the GLI expression and topology records contain algebraic and cut metadata. Causal prescriptions are inferred from config when needed.";

GenerateCollinearFactorizePreIBPResult::usage =
  "GenerateCollinearFactorizePreIBPResult[setup,fractionMeasure,preFactor,phaseSpace,integrand,topologies,resultDirectory] validates and packages one selected diagram-pair result. resultDirectory is optional for saved-file compatibility but required for an in-memory IBP input.";

KiraReduction::usage =
  "KiraReduction[inputs,file] identifies equivalent cut topologies, runs one exact-target Kira reduction, closes its exported rules against the solved database, writes and verifies the compact artifact, then removes the temporary Kira workspace.";

KiraImportReduction::usage =
  "KiraImportReduction[inputs,file] validates and imports the matching solved Kira workspace, closes its exact reduction rules, writes and verifies the compact artifact, then removes the workspace. It never reruns Kira.";

CoefficientSimplification::usage =
  "CoefficientSimplification[inputs,kiraReduction] reconstructs exact master coefficients. CoefficientSimplification[projectDirectory,cardName,resultFolder] automatically loads one saved diagram-pair set and KiraResult.wl, reconstructs the coefficients and writes CoefficientResult.wl. resultFolder may be Automatic. The option \"NormalizationKernels\" controls the Mathematica workers; \"Threads\" controls FireFly.";

CoefficientProgressPanel::usage =
  "CoefficientProgressPanel[] displays the current coefficient-reconstruction stage, target progress, elapsed time and estimated remaining time.";

$CoefficientSimplificationProgress::usage =
  "$CoefficientSimplificationProgress stores the current coefficient-reconstruction progress data.";

IdenticalParticleSymmetryFactor::usage =
  "IdenticalParticleSymmetryFactor[setup] is the exact phase-space symmetry factor 1/n! per species of identical, hadron-untagged outgoing partons declared by the process card. The measured fragmenting leg is excluded; a ghost-antighost pair is distinct and gives 1.";

AMFlowPrescription::usage =
  "AMFlowPrescription[setup] derives AMFlow loop prescriptions from Setup: 0 for phase-space integrations, +1 for forward virtual loops and -1 for conjugate virtual loops. AMFlowPrescription[setup,topology] additionally derives the cut mask and rejects active denominators that mix forward and conjugate virtual loops; it does not persist denominator-sign metadata.";

MasterIntegralAmFlow::usage =
  "MasterIntegralAmFlow[data,numericalKinematics] evaluates one master integral numerically with AMFlow. data contains Master, Topology, CutIndices and either Prescription or Setup; numericalKinematics is a rule list or Association. MasterIntegralAmFlow[result,master,numericalKinematics] obtains the topology data from a FeynFacet coefficient result. Set \"Verbose\" -> True to print AMFlow progress. The return value is numerical verification data, not an analytic master integral.";

\[Alpha]s::usage = "\[Alpha]s is the strong coupling used by FeynFacet.";

SyntaxInformation[DeclareScalar] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[BuildBasis] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[Build4Vec] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BuildGlobalBasis] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[FullSimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[BuildSimplificationContext] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyHardCoefficients] = {
  "ArgumentsPattern" -> {_, _, OptionsPattern[]}
};
SyntaxInformation[ToFeynFacetForm] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CommonFactorSafe] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CollinearFactorize] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CollinearFactorizePreIBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[GenerateCollinearFactorizePreIBPResult] =
  {"ArgumentsPattern" -> {_, _, _, _, _, _, _.}};
SyntaxInformation[KiraReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[KiraImportReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[CoefficientSimplification] =
  {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};
SyntaxInformation[CoefficientProgressPanel] = {"ArgumentsPattern" -> {}};
SyntaxInformation[IdenticalParticleSymmetryFactor] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[AMFlowPrescription] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[MasterIntegralAmFlow] =
  {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};
SyntaxInformation[PartialFraction] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildTopologies] = {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[IdentifySafePropagator] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[TopologyEquivalence] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[GenerateDiagram] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[DimensionalShift] = {"ArgumentsPattern" -> {_, _, _, _.}};

Options[PartialFraction] = {
  FeynCalc`DropScaleless -> False,
  FeynCalc`FDS -> False
};


Begin["`Private`"];

$feynFacetDirectory = DirectoryName[ExpandFileName[$InputFileName]];
$feynFacetRoot = DirectoryName[$feynFacetDirectory];
$feynFacetPrivateDirectory = FileNameJoin[{$feynFacetDirectory, "Private"}];
$feynFacetPrivateFiles = FileNameJoin[{$feynFacetPrivateDirectory, #}] & /@ {
    "Core.wl", "Process.wl", "Topologies.wl", "CanonicalFamilies.wl",
    "DimensionalShift.wl", "Collinear.wl", "Reduction.wl",
    "StreamingKira.wl",
    "MasterIntegralAmFlow.wl", "Simplification.wl",
    "CoefficientStore.wl", "CoefficientModules.wl"
};
$feynFacetSourceFiles = Join[
  {ExpandFileName[$InputFileName], FileNameJoin[{$feynFacetDirectory, "Distributions.wl"}]},
  $feynFacetPrivateFiles
];
If[! AllTrue[$feynFacetSourceFiles, FileExistsQ],
  Print["FeynFacet: missing source files: ",
    Select[$feynFacetSourceFiles, ! FileExistsQ[#] &]];
  Abort[]
];
$feynFacetSourceHash = Hash[
  FileHash[#, "SHA256"] & /@ $feynFacetSourceFiles,
  "SHA256",
  "HexString"
];
$feynFacetEpsilon = Symbol["Global`Epsilon"];
$dimensionRule = System`D -> 4 - 2 $feynFacetEpsilon;

SetAttributes[Cut, HoldAll];

FeynFacet`dD /: MakeBoxes[
    FeynFacet`dD[k_, dim_: D],
    form : StandardForm | TraditionalForm
  ] := RowBox[{
  SuperscriptBox["d", ToBoxes[dim, form]],
  ToBoxes[k, form]
}];

dFraction /: MakeBoxes[
    dFraction[x_],
    form : StandardForm | TraditionalForm
  ] := With[
  {xBoxes = ToBoxes[x, form]},
  InterpretationBox[
    RowBox[{"\[DifferentialD]", xBoxes}],
    dFraction[x]
  ]
];

Cut /: MakeBoxes[
    cut : Cut[argument_, direction_: 1],
    form : StandardForm | TraditionalForm
  ] := Module[{shown, boxes, sign},
  shown = argument /. FeynCalc`SPD[q_] :> HoldForm[q^2];
  boxes = MakeBoxes[shown, form];
  sign = Switch[direction, 1, "+", -1, "-", _, ToBoxes[direction, form]];
  InterpretationBox[
    RowBox[{SubscriptBox["\[Delta]", sign], "(", boxes, ")"}],
    cut
  ]
];

Scan[If[Get[#] === $Failed, Abort[]] &, $feynFacetPrivateFiles];

End[];

Quiet[EndPackage[], General::shdw];

If[Length[DownValues[FeynCalc`Calc]] === 0,
  Quiet[
    Block[{FeynCalc`$FeynCalcStartupMessages = False},
      FeynCalc`FCReloadAddOns[{"FeynCalcLegacy"}]
    ],
    General::shdw
  ]
];

If[Length[DownValues[FeynCalc`Calc]] === 0,
  Print["FeynFacet: the FeynCalcLegacy add-on is required but could not be loaded."];
  Abort[]
];

Print[
  Style["FeynFacet ", "Text", Bold],
  Style["0.1", "Text"]
];
