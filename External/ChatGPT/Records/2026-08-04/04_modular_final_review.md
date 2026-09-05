# Modular Final Review

## Question

Continue reviewing the same FACET/FeynFacet implementation from our previous turn. Below is the complete current modular source after implementing your P0 recommendations and running the real NLO end-to-end test.

Scientific contract: this must preserve exact analytic epsilon dependence, BMHV information, oriented physical cuts, causal prescriptions, branch metadata, and distribution conventions. Numerical output is verification only. Fail closed rather than infer missing physics.

Current architecture:
- FeynFacet.m: thin public facade, formatting, source-tree fingerprint, ordered module loader.
- Distributions.wl: twist-2 correlators.
- Private/Core.wl: exact shared algebra, basis, metadata, CommonFactorSafe, sparse LinearIntegralSum.
- Private/Process.wl: process-card normalization, FeynArts generation, phase-space routing, analytic context, AMFlow prescription.
- Private/Topologies.wl: exact denominator descriptors, oriented cuts, cut-aware partial fractions, FCTopology records, certified equivalence.
- Private/DimensionalShift.wl: BMHV Gram moments and topology-dependent Tarasov shifts.
- Private/Collinear.wl: projector algebra and pair-local pre-IBP orchestration.
- Private/Reduction.wl: Kira adapter/cache/import, sparse rule closure/application, master coefficient construction.

Implemented from your previous review:
1. Missing causal records fail closed; topology records require schema and PhysicalCausalStatus.
2. BMHV and complete analytic contexts are enforced at construction and persistence boundaries.
3. BaseGLI and FamilyCoefficient are explicit, validated fields.
4. Exact denominator cores distinguish masses, eikonal offsets, eta signs, and powers.
5. DimensionalShift rejects loop-dependent coefficients, accepts SPE[k] and SPE[k,k], and emits no independent D.
6. Kira imports and masters are parsed without general evaluation, validated exactly, and checked against cut pinching.
7. Physical topology records remain separate from Kira-exported algebraic families.
8. Kinematic mass dimensions are explicit and cache fingerprints are verified WXF payloads.
9. Inexact input is rejected.
10. The same public pipeline handles LO without a separate external workflow.
11. Generic exact and sparse helpers now live in Core; module ownership is documented.
12. Kira auxiliary invariant identifiers are short deterministic names because Fermat stalled on long identifiers.
13. Coefficient normalization atomizes protected analytic objects before Together/Cancel and permits exact canonical rewriting after restoration.

Verified tests (all pass): reload safety; cache safety; sparse linear algebra; loader infrastructure; causal/branch safety; two-loop partial fractions; topology building; one- and two-loop dimensional shifts; Gram moments; full LO flow; real NLO pre-IBP; strict analytic contracts; topology equivalence; adversarial topology-equivalence stress (800 random GLI applications); and a fresh real NLO F1/C2 run through Kira and coefficient reconstruction. The real NLO test reduced 16 targets to one cut master in about 12 s; all checks for exactness, cut survival, master metadata, BMHV context, and absence of an independent D passed.

Please review the complete source below. Focus on:
A. any remaining scientific correctness or fail-closed defect;
B. module-boundary violations or duplicated mechanisms that should be unified;
C. concrete deletions or simplifications that reduce code without weakening contracts;
D. whether the public facade and durable artifact schemas are coherent.

Do not propose a wholesale rewrite or numerical substitutes. Rank findings P0/P1/P2 and cite file/function. If no P0 remains, say so explicitly. For simplifications, give minimal replacement code or a precise deletion/refactor.



===== FILE: FeynFacet.m =====

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
  "SimplifyAssum[expr, assumptions] applies Simplify with assumptions.";

FullSimplifyAssum::usage =
  "FullSimplifyAssum[expr, assumptions] applies FullSimplify with assumptions.";

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

TopologyEquivalence::usage =
  "TopologyEquivalence[topologies] finds conservative multiloop equivalence classes. Accepted mappings have exact rational unit Jacobian and preserve every propagator, eta sign, cut slot, cut energy direction and AMFlow loop prescription.";

GenerateDiagram::usage =
  "GenerateDiagram[setup] generates and returns the complete FeynArts diagram lists for Setup[\"ForwardAmplitudes\"] and Setup[\"ConjugateAmplitudes\"].";

DimensionalShift::usage =
  "DimensionalShift[integrand,families,{k1,...}] applies the topology-dependent dimensional shift to every integral family, collects the GLI coefficients without expensive simplification, prints a result summary, and returns the collected expression. With no families and no loop momenta, it returns integrand unchanged. Coefficients should be simplified after IBP and master aggregation. DimensionalShift[integrand,propagators,{k1,...},topology] applies the shift to one family.";

CommonFactorSafe::usage =
  "CommonFactorSafe[expr,{k1,...}] extracts a common prefactor while retaining scalar products that depend on loop momenta, propagators, cuts, measures and GLI master integrals in the remainder.";

CollinearFactorize::usage =
  "CollinearFactorize[config] returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Propagators,LoopMomentum}. LoopMomentum contains the remaining phase-space momenta followed by the forward and conjugate virtual-loop momenta.";

CollinearFactorizePreIBP::usage =
  "CollinearFactorizePreIBP[config] runs diagram generation, collinear factorization, partial fractioning, topology construction and dimensional shifting from one configuration Association. It returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Topologies}, where Integrand is the GLI expression and every topology record contains cut and AMFlow prescription metadata.";

GenerateCollinearFactorizePreIBPResult::usage =
  "GenerateCollinearFactorizePreIBPResult[setup,fractionMeasure,preFactor,phaseSpace,integrand,topologies,resultDirectory] validates and packages one selected diagram-pair result. resultDirectory is optional for saved-file compatibility but required for an in-memory IBP input.";

KiraReduction::usage =
  "KiraReduction[inputs] identifies equivalent cut topologies, runs one combined Kira reduction and returns exact reduction rules. inputs is a list of saved result files or pre-IBP Associations.";

CoefficientSimplification::usage =
  "CoefficientSimplification[inputs,kiraReduction] reconstructs and simplifies the master coefficients. Saved files are read one at a time; only final master coefficients enter the dynamic kernel pool.";

IBP::usage =
  "IBP[results] is equivalent to CoefficientSimplification[results,KiraReduction[results]].";

AMFlowPrescription::usage =
  "AMFlowPrescription[config] returns the loop-momentum ordering and Feynman-prescription list required by AMFlow: 0 for phase-space integrations, +1 for forward virtual loops and -1 for conjugate virtual loops.";

\[Alpha]s::usage = "\[Alpha]s is the strong coupling used by FeynFacet.";

SyntaxInformation[DeclareScalar] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[BuildBasis] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[Build4Vec] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BuildGlobalBasis] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[FullSimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CommonFactorSafe] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CollinearFactorize] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CollinearFactorizePreIBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[GenerateCollinearFactorizePreIBPResult] =
  {"ArgumentsPattern" -> {_, _, _, _, _, _, _.}};
SyntaxInformation[KiraReduction] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CoefficientSimplification] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[IBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[AMFlowPrescription] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[PartialFraction] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildTopologies] = {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[TopologyEquivalence] = {"ArgumentsPattern" -> {_}};
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
    "Core.wl", "Process.wl", "Topologies.wl",
    "DimensionalShift.wl", "Collinear.wl", "Reduction.wl"
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


===== FILE: Distributions.wl =====

(* Twist-2 collinear distribution and fragmentation correlators. *)

\[CapitalPhi]::usage =
  "\[CapitalPhi][x,P,lambda,ST,n] is the incoming quark correlator.";

\[CapitalDelta]::usage =
  "\[CapitalDelta][z,P,lambda,ST,n] is the outgoing quark correlator.";

\[CapitalPhi]b::usage =
  "\[CapitalPhi]b[x,P,lambda,ST,n] is the incoming antiquark correlator.";

\[CapitalDelta]b::usage =
  "\[CapitalDelta]b[z,P,lambda,ST,n] is the outgoing antiquark correlator.";

f1::usage = "f1[x] is the unpolarized collinear parton distribution.";
g1L::usage = "g1L[x] is the longitudinal-helicity parton distribution.";
h1::usage = "h1[x] is the transversity parton distribution.";
D1::usage = "D1[z] is the unpolarized collinear fragmentation function.";
G1L::usage = "G1L[z] is the longitudinal-helicity fragmentation function.";
H1::usage = "H1[z] is the transversity fragmentation function.";

SyntaxInformation[\[CapitalPhi]] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalDelta]] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalPhi]b] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalDelta]b] = {"ArgumentsPattern" -> {_, _, _, _, _}};

Begin["`Private`"];

ClearAll[iSigmaSlash];
Clear[\[CapitalPhi], \[CapitalDelta], \[CapitalPhi]b, \[CapitalDelta]b];

iSigmaSlash[a_, b_] := I (I/2) (
  FeynCalc`GS[a] . FeynCalc`GS[b] -
  FeynCalc`GS[b] . FeynCalc`GS[a]
);

\[CapitalPhi][x_, P_, lambda_, ST_, n_] := (
  FeynFacet`DeclareScalar[{x, lambda, f1, g1L, h1}];
  1/2 (
    f1[x] FeynCalc`GS[n] +
    lambda g1L[x] FeynCalc`GA[5] . FeynCalc`GS[n] +
    h1[x] iSigmaSlash[n, ST] . FeynCalc`GA[5]
  )
);

\[CapitalDelta][z_, P_, lambda_, ST_, n_] := (
  FeynFacet`DeclareScalar[{z, lambda, D1, G1L, H1}];
  1/2 (
    D1[z] FeynCalc`GS[n] +
    lambda G1L[z] FeynCalc`GA[5] . FeynCalc`GS[n] +
    H1[z] iSigmaSlash[n, ST] . FeynCalc`GA[5]
  )
);

\[CapitalPhi]b[x_, P_, lambda_, ST_, n_] := (
  FeynFacet`DeclareScalar[{x, lambda, f1, g1L, h1}];
  1/2 (
    f1[x] FeynCalc`GS[n] -
    lambda g1L[x] FeynCalc`GA[5] . FeynCalc`GS[n] +
    h1[x] iSigmaSlash[n, ST] . FeynCalc`GA[5]
  )
);

\[CapitalDelta]b[z_, P_, lambda_, ST_, n_] := (
  FeynFacet`DeclareScalar[{z, lambda, D1, G1L, H1}];
  1/2 (
    D1[z] FeynCalc`GS[n] -
    lambda G1L[z] FeynCalc`GA[5] . FeynCalc`GS[n] +
    H1[z] iSigmaSlash[n, ST] . FeynCalc`GA[5]
  )
);

End[];


===== FILE: Private\Core.wl =====

(* Shared exact algebra, basis definitions, and result metadata. *)

NA = Missing["NotApplicable"];

GlobalBasisGram = {
  {0, 1, 0, 0},
  {1, 0, 0, 0},
  {0, 0, -1, 0},
  {0, 0, 0, -1}
};

globalBasis = Missing["NotSet"];
internalSetEvanescentZero = Missing["NotSet"];

resultHeader[format_, version_Integer] := <|
  "Format" -> format,
  "FormatVersion" -> version,
  "Created" -> DateString[{"ISODate", "T", "Time"}]
|>;

resultContext[data_Association] := KeyTake[
  data,
  {"CardName", "ResultDirectory", "Pairs", "Setup", "AnalyticContext"}
];

reductionFingerprint[payload_] := Hash[payload, "SHA256", "HexString"];


DeclareScalar[scalars_List] := Module[{pieces},
  pieces = DeleteDuplicates @ Cases[
    scalars,
    x_ /; ! ListQ[Unevaluated[x]] &&
      ! MatchQ[x, _Integer | _Rational] &&
      ! TrueQ[x === 0],
    {1, Infinity},
    Heads -> False
  ];
  Scan[(FeynCalc`DataType[#, FeynCalc`FCVariable] = True) &, pieces];
  scalars
];

DeclareScalar[scalar_] := First[DeclareScalar[{scalar}]];

BuildBasis::length = "Expected four basis vectors, but received `1`.";
BuildBasis::relation = "Basis relations failed: `1`.";


BuildBasis[basis_List, assumptions_: True] := Module[
  {heads, expected, actual, bad},

  If[Length[basis] =!= 4,
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];

  heads = {FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE};
  expected = {
    GlobalBasisGram,
    GlobalBasisGram,
    ConstantArray[0, {4, 4}]
  };
  actual = FullSimplify[
    Table[
      FeynCalc`ExpandScalarProduct[
        heads[[kind]][basis[[i]], basis[[j]]]
      ],
      {kind, 3}, {i, 4}, {j, 4}
    ],
    Assumptions -> assumptions
  ];
  bad = Position[MapThread[SameQ, {actual, expected}, 3], False];

  If[bad =!= {},
    Message[
      BuildBasis::relation,
      Function[pos, {
        heads[[pos[[1]]]],
        basis[[pos[[2]]]],
        basis[[pos[[3]]]],
        expected[[Sequence @@ pos]],
        actual[[Sequence @@ pos]]
      }] /@ bad
    ];
    Return[$Failed]
  ];

  basis
];

BuildBasis[basis_, assumptions_: True] := (
  Message[BuildBasis::length, basis];
  $Failed
);


Build4Vec[coordinates_List, basis_List] /;
    Length[coordinates] === Length[basis] := (
  DeclareScalar[coordinates];
  Total[coordinates basis]
);


declareGlobalBasis[basis_List] := Do[
  With[
    {p = basis[[i]], q = basis[[j]], value = GlobalBasisGram[[i, j]]},
    FeynCalc`SP[p, q] = value;
    FeynCalc`SPD[p, q] = value;
    FeynCalc`SPE[p, q] = 0
  ],
  {i, 4}, {j, i, 4}
];

BuildGlobalBasis[basis_List] := Module[
  {heads, oldDefinitions, oldBasis, oldEvanescent, result},
  If[
    Length[basis] =!= 4 ||
      ! AllTrue[basis, MatchQ[#, _Symbol] &] ||
      ! DuplicateFreeQ[basis],
    Message[BuildBasis::length, basis];
    Return[$Failed]
  ];

  heads = {FeynCalc`SP, FeynCalc`SPD, FeynCalc`SPE};
  oldDefinitions = DownValues /@ heads;
  oldBasis = globalBasis;
  oldEvanescent = internalSetEvanescentZero;
  declareGlobalBasis[basis];
  result = BuildBasis[basis];
  If[result === $Failed,
    MapThread[(DownValues[#1] = #2) &, {heads, oldDefinitions}];
    globalBasis = oldBasis;
    internalSetEvanescentZero = oldEvanescent;
    Return[$Failed]
  ];
  globalBasis = basis;
  internalSetEvanescentZero = basis[[{2, 1, 3, 4}]];
  result
];


SimplifyAssum[expr_, assumptions_: True] :=
  Simplify[expr, Assumptions -> assumptions];

FullSimplifyAssum[expr_, assumptions_: True] :=
  FullSimplify[expr, Assumptions -> assumptions];


termList[expr_] := With[{expanded = Expand[expr]},
  If[Head[expanded] === Plus, List @@ expanded, {expanded}]
];

exactZeroQ[expr_] := TrueQ[
  Quiet[Cancel[Together[Expand[expr]]]] === 0
];

exactRationalQ[value_] := MatchQ[value, _Integer | _Rational];

inexactNumberQ[value_] := NumberQ[value] && Precision[value] =!= Infinity;

exactDataQ[expression_] := FreeQ[
  HoldComplete[expression],
  value_ /; inexactNumberQ[value]
];

protectedAnalyticObjects[expression_] := Module[{walk},
  walk[value_?AtomQ] := {};
  walk[value_Plus] := Flatten[walk /@ List @@ value];
  walk[value_Times] := Flatten[walk /@ List @@ value];
  walk[Power[base_, power_Integer]] := walk[base];
  walk[value_] := {value};
  DeleteDuplicates[walk[expression], SameQ]
];


CommonFactorSafe[expr_, loopMomenta_List : {}] := Module[
  {
    external, protected, atoms, toAtoms, fromAtoms,
    factored, factors, prefactor
  },

  If[TrueQ[expr === 0], Return[{1, 0}]];

  external = FeynCalc`FCE[expr];
  protected = protectedAnalyticObjects[external];
  If[protected === {},
    factors = If[
      Head[external] === Times,
      List @@ external,
      {external}
    ];
    prefactor = Times @@ Select[factors, Head[#] =!= Plus &];
    Return[{
      prefactor,
      Times @@ Select[factors, Head[#] === Plus &]
    }]
  ];

  atoms = Table[Unique["protected$"], Length[protected]];
  toAtoms = Thread[protected -> atoms];
  fromAtoms = Thread[atoms -> protected];
  factored = Factor[external /. toAtoms];
  factors = If[Head[factored] === Times, List @@ factored, {factored}];
  prefactor = Times @@ Select[
    factors,
    FreeQ[#, Alternatives @@ atoms] &
  ];

  {
    prefactor /. fromAtoms,
    (factored/prefactor) /. fromAtoms
  }
];


linearIntegralSum[expression_] := Module[
  {objects, coefficients, remainder, reconstructed},
  objects = SortBy[
    DeleteDuplicates @ Cases[expression, _FeynCalc`GLI, {0, Infinity}],
    ToString[InputForm[#]] &
  ];
  coefficients = AssociationMap[Coefficient[expression, #] &, objects];
  remainder = expression /. Dispatch[Thread[objects -> 0]];
  reconstructed = Total[KeyValueMap[#1 #2 &, coefficients]] + remainder;
  If[
    ! FreeQ[Values[coefficients], _FeynCalc`GLI] ||
      ! TrueQ[Expand[expression - reconstructed] === 0],
    Return[Failure["NonlinearIntegralSum", <|"Expression" -> expression|>]]
  ];
  <|"Terms" -> coefficients, "Remainder" -> remainder|>
];

linearIntegralSumQ[data_] := AssociationQ[data] &&
  AssociationQ[Lookup[data, "Terms", None]] &&
  AllTrue[Keys[data["Terms"]], MatchQ[#, _FeynCalc`GLI] &] &&
  FreeQ[Values[data["Terms"]], _FeynCalc`GLI] &&
  FreeQ[Lookup[data, "Remainder", 0], _FeynCalc`GLI];

canonicalizeLinearTerms[terms_Association] := KeySortBy[
  terms,
  ToString[InputForm[#]] &
];

linearToExpression[data_?linearIntegralSumQ] :=
  Total[KeyValueMap[#1 #2 &, data["Terms"]]] + data["Remainder"];

linearDropZeros[data_?linearIntegralSumQ] := <|
  "Terms" -> canonicalizeLinearTerms @
    Select[data["Terms"], ! exactZeroQ[#] &],
  "Remainder" -> If[exactZeroQ[data["Remainder"]], 0, data["Remainder"]]
|>;

linearMapCoefficients[data_?linearIntegralSumQ, function_] := <|
  "Terms" -> Map[function, data["Terms"]],
  "Remainder" -> function[data["Remainder"]]
|>;

linearAdd[parts_List] := Module[{result},
  If[! AllTrue[parts, linearIntegralSumQ],
    Return[Failure["InvalidLinearIntegralSum", <||>]]
  ];
  result = linearDropZeros @ <|
    "Terms" -> Merge[Lookup[parts, "Terms"], Total],
    "Remainder" -> Total[Lookup[parts, "Remainder"]]
  |>;
  If[linearIntegralSumQ[result], result,
    Failure["InvalidLinearIntegralSum", <||>]
  ]
];

linearMapIntegrals[data_?linearIntegralSumQ, rules_] := Module[{terms, result},
  terms = KeyValueMap[(Replace[#1, rules, {0}] -> #2) &, data["Terms"]];
  If[! AllTrue[First /@ terms, MatchQ[#, _FeynCalc`GLI] &],
    Return[Failure["InvalidIntegralMap", <||>]]
  ];
  result = linearDropZeros @ <|
    "Terms" -> Merge[terms, Total],
    "Remainder" -> data["Remainder"]
  |>;
  If[linearIntegralSumQ[result], result,
    Failure["InvalidIntegralMap", <||>]
  ]
];

linearApplyReduction[data_?linearIntegralSumQ, rules_, reverseRules_] :=
  linearAdd @ Join[
    KeyValueMap[
      linearIntegralSum[#2 ((#1 /. rules) /. reverseRules)] &,
      data["Terms"]
    ],
    {linearIntegralSum[data["Remainder"] /. reverseRules]}
  ];


===== FILE: Private\Process.wl =====

(* Process normalization, diagram generation, and phase-space routing. *)

GenerateDiagram::setup =
  "Setup must contain ForwardAmplitudes, ConjugateAmplitudes, Partons, Model, InsertionLevel, ExcludeTopologies and ExcludeParticles. Received `1`.";

GenerateDiagram::amplitudes =
  "`1` must contain LoopOrder, LoopMomenta and a nonempty list of positive DiagramIndices; SelectedIndex is optional and must belong to DiagramIndices. Received `2`.";

GenerateDiagram::index =
  "`1` contains diagram index `2`, but only `3` diagrams were generated.";


normalizeAmplitudeSelection[
    diagrams_,
    setup_Association,
    label_String,
    required_: False
  ] := Module[
  {allowed, order, loops, indices, selected, invalid, index},

  allowed = {"LoopOrder", "LoopMomenta", "DiagramIndices", "SelectedIndex"};
  order = Lookup[setup, "LoopOrder", -1];
  loops = Lookup[setup, "LoopMomenta", None];
  indices = Lookup[setup, "DiagramIndices", None];
  selected = Lookup[setup, "SelectedIndex", None];
  invalid = Complement[Keys[setup], allowed] =!= {} ||
    ! IntegerQ[order] || order < 0 || ! MatchQ[loops, {_Symbol ...}] ||
    Length[loops] =!= order || ! DuplicateFreeQ[loops] ||
    ! MatchQ[indices, {__Integer?Positive}] || ! DuplicateFreeQ[indices] ||
    (selected =!= None && ! MemberQ[indices, selected]);
  If[invalid,
    Message[GenerateDiagram::amplitudes, label, setup];
    Return[$Failed]
  ];
  If[diagrams =!= All,
    index = FirstCase[indices, _?(# > Length[diagrams] &), None];
    If[index =!= None,
      Message[GenerateDiagram::index, label, index, Length[diagrams]];
      Return[$Failed]
    ]
  ];
  If[selected === None,
    If[required, Message[GenerateDiagram::amplitudes, label, setup]];
    Return[If[required, $Failed, setup]]
  ];
  Join[setup, <|"DiagramIndex" -> selected|>]
];


GenerateDiagram[setup_Association] := Module[
  {
    setupKeys, sideSetups, generateAtLoopOrder,
    loopOrders, diagramsByLoopOrder, diagramsBySide, resolved
  },

  setupKeys = {
    "ForwardAmplitudes", "ConjugateAmplitudes",
    "Partons", "Model", "InsertionLevel",
    "ExcludeTopologies", "ExcludeParticles"
  };
  If[! AllTrue[setupKeys, KeyExistsQ[setup, #] &],
    Message[GenerateDiagram::setup, setup];
    Return[$Failed]
  ];

  sideSetups = <|
    "Amplitude" -> setup["ForwardAmplitudes"],
    "Conjugate" -> setup["ConjugateAmplitudes"]
  |>;
  If[! AllTrue[Values[sideSetups], AssociationQ],
    Message[GenerateDiagram::setup, setup];
    Return[$Failed]
  ];
  resolved = MapThread[
    normalizeAmplitudeSelection,
    {
      ConstantArray[All, Length[sideNames]],
      Values[sideSetups],
      {"ForwardAmplitudes", "ConjugateAmplitudes"}
    }
  ];
  If[MemberQ[resolved, $Failed], Return[$Failed]];
  generateAtLoopOrder[loopOrder_Integer] := FeynArts`InsertFields[
    FeynArts`CreateTopologies[
      loopOrder,
      Length /@ setup["Partons"],
      FeynArts`ExcludeTopologies -> setup["ExcludeTopologies"]
    ],
    setup["Partons"],
    FeynArts`Model -> setup["Model"],
    FeynArts`InsertionLevel -> setup["InsertionLevel"],
    FeynArts`ExcludeParticles -> setup["ExcludeParticles"]
  ];

  loopOrders = DeleteDuplicates @ Lookup[
    Values[sideSetups],
    "LoopOrder"
  ];
  diagramsByLoopOrder = AssociationMap[generateAtLoopOrder, loopOrders];
  diagramsBySide = <|
    "Amplitude" -> diagramsByLoopOrder[
      sideSetups["Amplitude"]["LoopOrder"]
    ],
    "Conjugate" -> diagramsByLoopOrder[
      sideSetups["Conjugate"]["LoopOrder"]
    ]
  |>;
  resolved = MapThread[
    normalizeAmplitudeSelection,
    {
      Values[diagramsBySide],
      Values[sideSetups],
      {"ForwardAmplitudes", "ConjugateAmplitudes"}
    }
  ];
  If[MemberQ[resolved, $Failed], Return[$Failed]];
  diagramsBySide
];

GenerateDiagram[setup_] := (
  Message[GenerateDiagram::setup, setup];
  $Failed
);


printSelectedDiagrams[
    diagramsBySide_Association,
    setup_Association
  ] := Module[{printOne},

  printOne[label_String, side_String, key_String] := Module[
    {index},
    index = setup[key]["SelectedIndex"];
    Print[Style[label <> " " <> ToString[index], Bold, 14]];
    FeynArts`Paint[
      FeynArts`DiagramExtract[diagramsBySide[side], index],
      FeynArts`ColumnsXRows -> {1, 1},
      FeynArts`Numbering -> None,
      FeynArts`SheetHeader -> None,
      DisplayFunction -> (Print /@ FeynArts`Render[#, ImageSize -> 320] &)
    ]
  ];

  printOne["Forward", "Amplitude", "ForwardAmplitudes"];
  printOne["Conjugate", "Conjugate", "ConjugateAmplitudes"];
  Null
];

$collinearFailure = "FeynFacetCollinearFailure";

requiredKeys = {
  "ForwardAmplitudes",
  "ConjugateAmplitudes",
  "Partons",
  "PartonMomentum",
  "PhaseSpaceMomentum",
  "PartonIntegrated",
  "MomentumFraction",
  "HadronMomentum",
  "HadronLongDirection",
  "HadronDualDirection",
  "HadronLongSpin",
  "HadronTransSpin"
};

feynArtsKeys = {
  "Model",
  "InsertionLevel",
  "ExcludeTopologies",
  "ExcludeParticles"
};

optionalKeys = Join[
  {
    "CardName",
    "SourceNotebook",
    "DiagramsBySide",
    "SetDistributionZero",
    "SetMassZero",
    "KinematicMassDimensions"
  },
  feynArtsKeys
];

legInputKeys = {
  "Partons",
  "PartonMomentum",
  "MomentumFraction",
  "HadronMomentum",
  "HadronLongDirection",
  "HadronDualDirection",
  "HadronLongSpin",
  "HadronTransSpin"
};

legFields = {
  "Parton",
  "Momentum",
  "Fraction",
  "HadronMomentum",
  "LongDirection",
  "DualDirection",
  "LongSpin",
  "TransSpin"
};

sideNames = {"Amplitude", "Conjugate"};

amplitudeNames = <|
  "Amplitude" -> "ForwardAmplitudes",
  "Conjugate" -> "ConjugateAmplitudes"
|>;

selectedPairFromSetup[setup_Association] := Module[{indices},
  indices = Lookup[Lookup[setup, #, <||>], "SelectedIndex", Missing[]] & /@
    {"ForwardAmplitudes", "ConjugateAmplitudes"};
  If[
    AllTrue[indices, IntegerQ[#] && Positive[#] &],
    AssociationThread[{"Forward", "Conjugate"}, indices],
    $Failed
  ]
];

CollinearFactorize::config =
  "Expected a configuration Association, but received `1`.";

CollinearFactorize::missing =
  "Configuration is missing required keys `1`.";

CollinearFactorize::unknown =
  "Configuration contains unknown keys `1`.";

CollinearFactorize::invalid =
  "Invalid value for `1`: `2`. `3`";

CollinearFactorize::basis =
  "No global basis is installed. Run BuildGlobalBasis[{nb,n,xhat,yhat}] first.";

CollinearFactorize::polarization =
  "External boson polarizations remain after summing momenta `1`: `2`.";

CollinearFactorize::propagators =
  "Amplitude `1` is not a product of a numerator and literal FAD factors. Remaining denominator objects: `2`.";

CollinearFactorize::algebra =
  "Calc left unresolved algebraic objects: `1`.";

CollinearFactorize::spinprojector =
  "External spin projector tagging failed. Missing before the spin sum: `1`; remaining after the density replacement: `2`.";

CollinearFactorize::mixedeta =
  "The denominator core `1` occurs with both +i0 and -i0 prescriptions. It cannot be represented by one ordinary GLI index.";

CollinearFactorize::eta =
  "A `1` propagator does not carry the required physical eta sign `2`: `3`.";


fail[field_, value_, reason_] := (
  Message[CollinearFactorize::invalid, field, value, reason];
  Throw[$Failed, $collinearFailure]
);


normalizeSides[name_, value_, counts_] := Module[{sides},
  If[Head[value] =!= Rule,
    fail[name, value, "Expected incoming -> outgoing."]
  ];
  sides = List @@ value;
  If[! AllTrue[sides, ListQ],
    fail[name, value, "Both sides must be lists."]
  ];
  If[Length /@ sides =!= counts,
    fail[
      name,
      value,
      "Side lengths must match Partons: " <> ToString[counts, InputForm] <> "."
    ]
  ];
  sides
];


inferFractionAssumptions[momentumFractions_] := Module[{fractions},
  fractions = DeleteDuplicates @ Cases[
    momentumFractions,
    fraction_Symbol /; fraction =!= NA,
    Infinity
  ];
  And @@ ((0 < # < 1) & /@ fractions)
];

normalizeAmplitudeSides[config_Association, externalMomenta_List] := Module[
  {setups, sides, loops},
  setups = AssociationThread[
    sideNames,
    Lookup[config, {"ForwardAmplitudes", "ConjugateAmplitudes"}]
  ];
  sides = AssociationMap[
    normalizeAmplitudeSelection[
      All,
      setups[#],
      amplitudeNames[#],
      True
    ] &,
    sideNames
  ];
  If[MemberQ[Values[sides], $Failed],
    fail[
      "ForwardAmplitudes/ConjugateAmplitudes",
      setups,
      "Both perturbative sides require a selected valid diagram."
    ]
  ];
  loops = Flatten[Lookup[Values[sides], "LoopMomenta"]];
  If[! DuplicateFreeQ[loops] || Intersection[loops, externalMomenta] =!= {},
    fail[
      "ForwardAmplitudes/ConjugateAmplitudes",
      setups,
      "Virtual-loop momenta must be unique and distinct from external momenta."
    ]
  ];
  <|"Sides" -> sides, "VirtualLoopMomenta" -> loops|>
];

prepareProcess[process_Association, diagrams_Association] := Module[{sides},
  If[Sort[Keys[diagrams]] =!= Sort[sideNames],
    fail[
      "DiagramsBySide",
      diagrams,
      "Expected exactly the keys " <> ToString[sideNames, InputForm] <> "."
    ]
  ];
  sides = AssociationMap[Function[name, Module[{list, side},
    list = diagrams[name];
    side = process["Sides"][name];
    If[
      Head[Head[list]] =!= FeynArts`TopologyList ||
        side["DiagramIndex"] > Length[list],
      fail[
        "DiagramsBySide[\"" <> name <> "\"]",
        list,
        "Expected generated diagrams containing the selected index."
      ]
    ];
    Append[side, "Diagrams" -> list]
  ]], sideNames];
  Join[process, <|"Sides" -> sides|>]
];

prepareProcess[_, diagrams_] := fail[
  "DiagramsBySide",
  diagrams,
  "Expected the Association returned by GenerateDiagram."
];

normalizeProcess[config_Association] := Module[
  {
    missing, unknown, partonSides, counts, columns, makeLegs,
    phaseMomenta, integratedMomenta, allMomenta, amplitudeSides,
    declaredVectors, zeroDistributions, zeroEvanescent, zeroMass,
    fractionAssumptions, massDimensions
  },

  missing = Complement[requiredKeys, Keys[config]];
  unknown = Complement[Keys[config], Join[requiredKeys, optionalKeys]];
  If[missing =!= {},
    Message[CollinearFactorize::missing, missing];
    Throw[$Failed, $collinearFailure]
  ];
  If[unknown =!= {},
    Message[CollinearFactorize::unknown, unknown];
    Throw[$Failed, $collinearFailure]
  ];
  If[! exactDataQ[config],
    fail[
      "Setup",
      config,
      "Scientific input must contain exact numbers only."
    ]
  ];

  partonSides = Lookup[config, "Partons"];
  If[Head[partonSides] =!= Rule || ! AllTrue[List @@ partonSides, ListQ],
    fail["Partons", partonSides, "Expected incoming -> outgoing lists."]
  ];
  partonSides = List @@ partonSides;
  counts = Length /@ partonSides;

  columns = AssociationThread[
    legFields,
    normalizeSides[#, Lookup[config, #], counts] & /@ legInputKeys
  ];
  makeLegs[side_] := AssociationThread[legFields, #] & /@
    Transpose[Lookup[columns, legFields][[All, side]]];
  fractionAssumptions = inferFractionAssumptions[
    Lookup[config, "MomentumFraction"]
  ];

  allMomenta = Flatten[columns["Momentum"]];
  If[! DuplicateFreeQ[allMomenta],
    fail["PartonMomentum", columns["Momentum"], "Momenta must be unique."]
  ];

  phaseMomenta = Lookup[config, "PhaseSpaceMomentum"];
  If[! ListQ[phaseMomenta] || phaseMomenta === {},
    fail["PhaseSpaceMomentum", phaseMomenta, "Expected a nonempty list."]
  ];
  If[Complement[phaseMomenta, columns["Momentum"][[2]]] =!= {},
    fail[
      "PhaseSpaceMomentum",
      phaseMomenta,
      "Every phase-space momentum must be an outgoing parton momentum."
    ]
  ];

  integratedMomenta = Lookup[config, "PartonIntegrated"];
  If[! ListQ[integratedMomenta] || Length[integratedMomenta] =!= 1,
    fail[
      "PartonIntegrated",
      integratedMomenta,
      "One overall momentum delta eliminates exactly one outgoing momentum."
    ]
  ];
  If[Complement[integratedMomenta, phaseMomenta] =!= {},
    fail[
      "PartonIntegrated",
      integratedMomenta,
      "The eliminated momentum must belong to PhaseSpaceMomentum."
    ]
  ];

  amplitudeSides = normalizeAmplitudeSides[config, allMomenta];

  zeroDistributions = Lookup[config, "SetDistributionZero", {}];
  If[
    ! ListQ[zeroDistributions] ||
      ! AllTrue[zeroDistributions, MatchQ[#, _Symbol] &],
    fail[
      "SetDistributionZero",
      zeroDistributions,
      "Expected a list of distribution heads."
    ]
  ];

  declaredVectors = DeleteDuplicates @ Cases[
    Flatten @ Lookup[
      columns,
      {"Momentum", "HadronMomentum", "LongDirection", "DualDirection",
        "TransSpin"}
    ],
    vector_Symbol /; vector =!= NA
  ];
  zeroEvanescent = DeleteDuplicates @ Join[
    internalSetEvanescentZero,
    Complement[declaredVectors, phaseMomenta]
  ];

  zeroMass = Lookup[config, "SetMassZero", {}];
  If[
    ! ListQ[zeroMass] || ! AllTrue[zeroMass, MatchQ[#, _Symbol] &],
    fail[
      "SetMassZero",
      zeroMass,
      "Expected a list of momentum symbols."
    ]
  ];

  massDimensions = Lookup[config, "KinematicMassDimensions", <||>];
  If[
    ! AssociationQ[massDimensions] ||
      ! AllTrue[Keys[massDimensions], MatchQ[#, _Symbol] &] ||
      ! AllTrue[Values[massDimensions], IntegerQ],
    fail[
      "KinematicMassDimensions",
      massDimensions,
      "Expected an Association from invariant symbols to integer mass dimensions."
    ]
  ];

  <|
    "Type" -> "FeynFacetProcess",
    "Version" -> 2,
    "Sides" -> amplitudeSides["Sides"],
    "VirtualLoopMomenta" -> amplitudeSides["VirtualLoopMomenta"],
    "Incoming" -> makeLegs[1],
    "Outgoing" -> makeLegs[2],
    "PhaseSpaceMomenta" -> phaseMomenta,
    "IntegratedMomentum" -> First[integratedMomenta],
    "SetDistributionZero" -> DeleteDuplicates[zeroDistributions],
    "SetEvanescentZero" -> zeroEvanescent,
    "SetMassZero" -> DeleteDuplicates[zeroMass],
    "KinematicMassDimensions" -> massDimensions,
    "Assumptions" -> fractionAssumptions
  |>
];


analyticContext[process_Association] := Module[{scheme, context},
  scheme = Quiet @ Check[FeynCalc`FCGetDiracGammaScheme[], $Failed];
  If[scheme =!= "BMHV", Return[$Failed]];
  context = <|
    "Gamma5Scheme" -> scheme,
    "GlobalBasis" -> globalBasis,
    "GlobalBasisGram" -> GlobalBasisGram,
    "SetEvanescentZero" -> process["SetEvanescentZero"],
    "SetMassZero" -> process["SetMassZero"],
    "SetDistributionZero" -> process["SetDistributionZero"],
    "CollinearRelations" -> collinearRelations[process],
    "Assumptions" -> process["Assumptions"],
    "KinematicMassDimensions" -> process["KinematicMassDimensions"],
    "LoopDimension" -> System`D,
    "DimensionRule" -> $dimensionRule,
    "CutConvention" -> "OrientedPositiveEnergyDelta",
    "DistributionConvention" -> "FeynFacet/Distributions.wl",
    "FeynFacetSourceHash" -> $feynFacetSourceHash
  |>;
  Append[context, "Fingerprint" -> reductionFingerprint[context]]
];


collinearRelations[process_Association] := Module[
  {legRelation},

  legRelation[leg_Association, fractionPower_Integer] := If[
    MissingQ[leg["HadronMomentum"]],
    Nothing,
    <|
      "PartonMomentum" -> leg["Momentum"],
      "HadronMomentum" -> leg["HadronMomentum"],
      "HadronScale" -> leg["Fraction"]^fractionPower,
      "LongDirection" -> leg["LongDirection"],
      "DualDirection" -> leg["DualDirection"]
    |>
  ];

  DeleteDuplicates @ Flatten[{
      legRelation[#, -1] & /@ process["Incoming"],
      legRelation[#, 1] & /@ process["Outgoing"]
    }, 1]
];


reduceCollinearLoopProducts[
    expression_,
    process_Association,
    loopMomenta_List
  ] := Module[{external, reduceOne},

  If[loopMomenta === {}, Return[expression]];
  external = FeynCalc`FCI @ FeynCalc`ExpandScalarProduct[expression];
  reduceOne[value_, relation_Association] := With[
    {
      momentum = relation["PartonMomentum"],
      hadron = relation["HadronMomentum"],
      hadronScale = relation["HadronScale"],
      direction = relation["LongDirection"],
      dual = relation["DualDirection"]
    },
    value /. {
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[a_, dimension_],
          FeynCalc`Momentum[hadron, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          hadronScale FeynCalc`Pair[
            FeynCalc`Momentum[a, dimension],
            FeynCalc`Momentum[momentum, dimension]
          ],
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[hadron, dimension_],
          FeynCalc`Momentum[a_, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          hadronScale FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[a, dimension]
          ],
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[a_, dimension_],
          FeynCalc`Momentum[direction, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          FeynCalc`Pair[
            FeynCalc`Momentum[a, dimension],
            FeynCalc`Momentum[momentum, dimension]
          ] / FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[dual, dimension]
          ],
      HoldPattern[FeynCalc`Pair[
          FeynCalc`Momentum[direction, dimension_],
          FeynCalc`Momentum[a_, dimension_]
        ]] /;
        containsListedMomentumQ[a, loopMomenta] :>
          FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[a, dimension]
          ] / FeynCalc`Pair[
            FeynCalc`Momentum[momentum, dimension],
            FeynCalc`Momentum[dual, dimension]
          ]
    }
  ];

  Fold[
    reduceOne,
    external,
    collinearRelations[process]
  ]
];


remainingPhaseSpaceMomenta[process_Association] := DeleteCases[
  process["PhaseSpaceMomenta"],
  process["IntegratedMomentum"],
  {1},
  1
];

amflowPrescription[process_Association] :=
  Module[{phaseLoops, forwardLoops, conjugateLoops},
    phaseLoops = remainingPhaseSpaceMomenta[process];
    forwardLoops = process["Sides"]["Amplitude"]["LoopMomenta"];
    conjugateLoops = process["Sides"]["Conjugate"]["LoopMomenta"];

    <|
      "LoopMomenta" -> Join[phaseLoops, forwardLoops, conjugateLoops],
      "Prescription" -> Join[
        ConstantArray[0, Length[phaseLoops]],
        ConstantArray[1, Length[forwardLoops]],
        ConstantArray[-1, Length[conjugateLoops]]
      ]
    |>
  ];

AMFlowPrescription[config_Association] := Catch[
  amflowPrescription[normalizeProcess[config]],
  $collinearFailure
];

AMFlowPrescription[config_] := (
  Message[CollinearFactorize::config, config];
  $Failed
);


momentumEliminationRule[process_Association] := Module[
  {momentum, incoming, outgoing},

  momentum = process["IntegratedMomentum"];
  incoming = Lookup[process["Incoming"], "Momentum"];
  outgoing = Lookup[process["Outgoing"], "Momentum"];

  momentum -> Expand[
    Total[incoming] - Total[DeleteCases[outgoing, momentum, {1}, 1]]
  ]
];


buildPhaseData[process_Association, eliminationRule_Rule] := Module[
  {momenta, remaining, outgoing, cutSources},

  momenta = process["PhaseSpaceMomenta"];
  remaining = remainingPhaseSpaceMomenta[process];
  outgoing = process["Outgoing"];
  cutSources = Map[
    Function[momentum, Module[{position, leg},
      position = First @ FirstPosition[
        Lookup[outgoing, "Momentum"],
        momentum
      ];
      leg = outgoing[[position]];
      With[{lineMomentum = Expand[momentum /. eliminationRule]},
        <|
          "SourceID" -> {"Cut", position},
          "Role" -> "Cut",
          "Expression" -> Cut[FeynCalc`SPD[lineMomentum], 1],
          "CutID" -> {"OutgoingLeg", position},
          "OriginalMomentum" -> momentum,
          "LineMomentum" -> lineMomentum,
          "Parton" -> leg["Parton"],
          "MeasurementRole" -> If[
            MissingQ[leg["HadronMomentum"]],
            "UnobservedPhaseSpace",
            "ObservedPhaseSpace"
          ],
          "EnergyReference" -> "PhysicalFuture",
          "EnergyDirection" -> 1
        |>
      ]
    ]],
    momenta
  ];

  <|
    "Prefactor" -> (2 Pi)^Expand[D - Length[momenta] (D - 1)],
    "Measure" -> Times @@ (FeynFacet`dD /@ remaining),
    "Cuts" -> Times @@ Lookup[cutSources, "Expression"],
    "CutSources" -> cutSources
  |>
];


lightQuarkMassRules = {
  FeynCalc`SMP["m_u"] -> 0,
  FeynCalc`SMP["m_d"] -> 0,
  FeynCalc`SMP["m_s"] -> 0
};


===== FILE: Private\Topologies.wl =====

(* Cut-aware denominator parsing, partial fractions, and topology records. *)

PartialFraction::loops =
  "Loop momenta must be given as a list, but received `1`.";

PartialFraction::cut =
  "Cut propagators must have the form Cut[SPD[q]] or Cut[SPD[q],direction], with direction equal to 1 or -1. Invalid objects: `1`.";

PartialFraction::cutorientation =
  "The same quadratic cut denominator was assigned incompatible positive-energy orientations: `1`.";

PartialFraction::nocut =
  "ApartFF produced no term retaining all required cut propagators `1`.";

PartialFraction::cutpower =
  "ApartFF produced an unsupported cut power `1` for cut momentum `2`.";

PartialFraction::collision =
  "The denominator core `1` occurs both as a Cut and as an ordinary propagator. This cannot be represented by one GLI index.";


momentumRelativeSign[q_, target_] := Which[
  exactZeroQ[q - target] && ! exactZeroQ[q + target], 1,
  exactZeroQ[q + target] && ! exactZeroQ[q - target], -1,
  True, 0
];

sameMomentumQ[q_, target_] :=
  MemberQ[{1, -1}, momentumRelativeSign[q, target]];

sameOrientedCutQ[first_List, second_List] := Module[{sign},
  sign = momentumRelativeSign[first[[1]], second[[1]]];
  MemberQ[{1, -1}, sign] &&
    TrueQ[first[[2]] sign === second[[2]]]
];

propagatorFactors[expr_] := Cases[
  FeynCalc`FCI[expr],
  denominator : (
      FeynCalc`PropagatorDenominator |
      FeynCalc`StandardPropagatorDenominator
    )[___] :> FeynCalc`FeynAmpDenominator[denominator],
  Infinity
];

propagatorMomentum[propagator_] := Lookup[
  propagatorDescriptor[propagator],
  "Momentum",
  $Failed
];

parseHeldCut[HoldComplete[Cut[FeynCalc`SPD[q_]]]] := {q, 1};
parseHeldCut[
    HoldComplete[Cut[FeynCalc`SPD[q_], direction_]]
  ] := If[MemberQ[{1, -1}, direction], {q, direction}, $Failed];
parseHeldCut[_] := $Failed;

cutData[expr_] := Module[{objects, records, invalid, conflicts},
  objects = Cases[expr, cut_Cut :> HoldComplete[cut], Infinity];
  records = parseHeldCut /@ objects;
  invalid = Pick[
    objects,
    $Failed === # & /@ records
  ];
  If[invalid =!= {},
    Message[PartialFraction::cut, ReleaseHold /@ invalid];
    Return[$Failed]
  ];
  conflicts = Select[
    Subsets[records, {2}],
    sameMomentumQ[#[[1, 1]], #[[2, 1]]] &&
      ! sameOrientedCutQ[#[[1]], #[[2]]] &
  ];
  If[conflicts =!= {},
    Message[PartialFraction::cutorientation, conflicts];
    Return[$Failed]
  ];
  DeleteDuplicates[records, sameOrientedCutQ]
];


cutDescriptors[cutRecords_List] := Map[
  Function[record, Module[{descriptor},
    descriptor = propagatorDescriptor[FeynCalc`SFAD[First[record]]];
    If[descriptor === $Failed, Return[$Failed]];
    <|
      "Momentum" -> First[record],
      "Direction" -> Last[record],
      "UnitCore" -> descriptor["UnitCore"]
    |>
  ]],
  cutRecords
];

cutIndex[propagator_, descriptors_List] := Module[{descriptor},
  descriptor = propagatorDescriptor[propagator];
  If[descriptor === $Failed, Return[$Failed]];
  FirstCase[
  Range[Length[descriptors]],
  i_ /; exactZeroQ[
      descriptor["UnitCore"] - descriptors[[i, "UnitCore"]]
    ] :> i,
  Missing["NotCut"]
  ]
];

propagatorPower[propagator_] := Lookup[
  propagatorDescriptor[propagator],
  "Power",
  $Failed
];

cutOrdinaryCoreCollision[expr_, cutRecords_List] := Module[
  {ordinary, ordinaryData, cutCores, collision},
  ordinary = propagatorFactors[expr];
  ordinaryData = propagatorDescriptor /@ ordinary;
  If[MemberQ[ordinaryData, $Failed], Return[$Failed]];
  cutCores = topologyPropagatorCore[
      FeynCalc`SFAD[First[#]],
      {},
      {}
    ] & /@ cutRecords;
  If[MemberQ[cutCores, $Failed], Return[$Failed]];
  collision = FirstCase[
    Tuples[{cutCores, Lookup[ordinaryData, "UnitCore"]}],
    {cutCore_, ordinaryCore_} /; exactZeroQ[cutCore - ordinaryCore] :>
      cutCore,
    Missing["NotFound"]
  ];
  collision
];

restoreCutTerm[term_, cutRecords_List] := Module[
  {
    internal, propagators, indices, ordinary, coefficient,
    cutMomenta, descriptors, powers, cutPowers, cutFactors, external
  },

  cutMomenta = First /@ cutRecords;
  descriptors = cutDescriptors[cutRecords];
  If[descriptors === $Failed || MemberQ[descriptors, $Failed],
    Return[$Failed]
  ];
  internal = FeynCalc`FCI[term];
  propagators = Cases[
    internal,
    _FeynCalc`PropagatorDenominator |
      _FeynCalc`StandardPropagatorDenominator,
    Infinity
  ];
  indices = cutIndex[#, descriptors] & /@ propagators;
  If[MemberQ[indices, $Failed], Return[$Failed]];
  powers = propagatorPower /@ propagators;

  If[! ContainsAll[DeleteMissing[indices], Range[Length[cutMomenta]]],
    Return[Nothing]
  ];
  cutPowers = Table[
    Total @ Pick[powers, indices, cutPosition],
    {cutPosition, Length[cutMomenta]}
  ];
  If[! VectorQ[cutPowers, IntegerQ[#] && # > 0 &],
    With[{bad = FirstPosition[cutPowers, power_ /; ! IntegerQ[power] || power <= 0]},
      Message[
        PartialFraction::cutpower,
        cutPowers[[First[bad]]],
        cutMomenta[[First[bad]]]
      ]
    ];
    Return[$Failed]
  ];

  ordinary = Pick[propagators, MissingQ /@ indices];
  coefficient = internal /.
    HoldPattern[FeynCalc`FeynAmpDenominator[___]] -> 1;
  external = FeynCalc`FCE[
    coefficient If[
      ordinary === {},
      1,
      Apply[FeynCalc`FeynAmpDenominator, ordinary]
    ]
  ];
  cutFactors = MapIndexed[
    Function[{record, position},
      With[
        {
          power = cutPowers[[First[position]]],
          momentum = record[[1]],
          direction = record[[2]]
        },
        Cut[FeynCalc`SPD[momentum], direction]^power
      ]
    ],
    cutRecords
  ];

  external Times @@ cutFactors
];


PartialFraction[expr_, loopMomenta_List, OptionsPattern[]] := Module[
  {cutRecords, collision, algebraic, reduced, result},

  cutRecords = cutData[expr];
  If[cutRecords === $Failed, Return[$Failed]];
  collision = cutOrdinaryCoreCollision[expr, cutRecords];
  If[collision === $Failed, Return[$Failed]];
  If[! MissingQ[collision],
    Message[PartialFraction::collision, collision];
    Return[$Failed]
  ];
  If[loopMomenta === {}, Return[expr]];

  algebraic = expr /. {
    HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`FAD[q],
    HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`FAD[q]
  };
  reduced = FeynCalc`ApartFF[
    algebraic,
    loopMomenta,
    FeynCalc`DropScaleless -> OptionValue[FeynCalc`DropScaleless],
    FeynCalc`FDS -> OptionValue[FeynCalc`FDS],
    FeynCalc`FCE -> False
  ];

  If[cutRecords === {}, Return[FeynCalc`FCE[reduced]]];
  result = restoreCutTerm[#, cutRecords] & /@ termList[reduced];
  If[MemberQ[result, $Failed], Return[$Failed]];
  If[result === {},
    Message[PartialFraction::nocut, cutRecords];
    Return[$Failed]
  ];
  Total[result]
];

PartialFraction[expr_, loopMomenta_, OptionsPattern[]] := (
  Message[PartialFraction::loops, loopMomenta];
  $Failed
);


BuildTopologies::loops =
  "Loop momenta must be given as a list, but received `1`.";

BuildTopologies::zeroloop =
  "With no loop momenta, the propagator product must be 1 after external cuts and propagators have been separated. Received `1`.";

BuildTopologies::config =
  "SetMassZero in the setup must be a list, but received `1`.";

BuildTopologies::choice =
  "ForwardAmplitudes and ConjugateAmplitudes must identify one diagram each by a positive SelectedIndex. Received `1` and `2`.";

BuildTopologies::term =
  "Could not construct an integral topology from partial-fraction term `1`.";

BuildTopologies::partial =
  "Partial-fraction term `1` still contains linearly dependent propagators.";

BuildTopologies::rules =
  "The setup mass rules conflict with existing topology rules: `1`.";

BuildTopologies::topology =
  "The generated topology is not valid, complete and linearly independent: `1`.";

BuildTopologies::cut =
  "Could not map every cut propagator into the generated topology for term `1`.";

$buildTopologiesFailure = "FeynFacetBuildTopologiesFailure";


topologyPropagatorIndex[
    propagator_,
    topology_FeynCalc`FCTopology,
    loopMomenta_List
  ] := Module[{converted, mapped, glis, positions},
  converted = CheckAbort[
    FeynCalc`FCLoopToGLI[propagator, loopMomenta],
    $Failed
  ];
  If[! MatchQ[converted, {_, _FeynCalc`FCTopology}], Return[$Failed]];
  mapped = CheckAbort[
    converted[[1]] /.
      FeynCalc`FCLoopCreateRuleGLIToGLI[topology, converted[[2]]],
    $Failed
  ];
  If[mapped === $Failed, Return[$Failed]];
  glis = Cases[mapped, _FeynCalc`GLI, {0, Infinity}];
  If[Length[glis] =!= 1, Return[$Failed]];
  positions = Flatten @ Position[
    glis[[1, 2]],
    _?(# =!= 0 &),
    {1},
    Heads -> False
  ];
  If[Length[positions] =!= 1, Return[$Failed]];
  First[positions]
];


BuildTopologies[
    partialFractions_,
    loopMomenta_List,
    config_Association
  ] := Catch[
  Module[{
    massless, forwardAmplitudes, conjugateAmplitudes, pair,
    forwardTag, conjugateTag,
    terms, buildOne, families
  },

    If[loopMomenta === {},
      If[FeynCalc`FCE[partialFractions] =!= 1,
        Message[BuildTopologies::zeroloop, partialFractions];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      Print @ Grid[
        {
          {"Topology", "External momenta", "Cut indices", "Cut directions"},
          {"None", {}, {}, {}}
        },
        Frame -> All
      ];
      Return[{}]
    ];
    massless = Lookup[config, "SetMassZero", {}];
    If[! ListQ[massless],
      Message[BuildTopologies::config, massless];
      Throw[$Failed, $buildTopologiesFailure]
    ];
    forwardAmplitudes = Lookup[config, "ForwardAmplitudes", <||>];
    conjugateAmplitudes = Lookup[config, "ConjugateAmplitudes", <||>];
    pair = selectedPairFromSetup[config];
    If[pair === $Failed,
      Message[
        BuildTopologies::choice,
        forwardAmplitudes,
        conjugateAmplitudes
      ];
      Throw[$Failed, $buildTopologiesFailure]
    ];
    forwardTag = ToString[pair["Forward"]];
    conjugateTag = ToString[pair["Conjugate"]];
    terms = termList[partialFractions];

    buildOne[term_, index_Integer] := Module[
      {
        cutRecords, cutMomenta, cutDirections, algebraic, converted,
        topology, topologyID, external, massRules, conflicts, completed,
        checks, cutIndices, mappedFamily, baseGLIs, baseGLI,
        familyCoefficient
      },

      cutRecords = cutData[term];
      If[cutRecords === $Failed,
        Throw[$Failed, $buildTopologiesFailure]
      ];
      cutMomenta = First /@ cutRecords;
      cutDirections = Last /@ cutRecords;
      algebraic = term /. {
        HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`SFAD[q],
        HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`SFAD[q]
      };
      converted = Quiet @ CheckAbort[
        FeynCalc`FCLoopToGLI[algebraic, loopMomenta],
        $Failed
      ];
      If[! MatchQ[converted, {_, _FeynCalc`FCTopology}],
        Message[BuildTopologies::term, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      topology = converted[[2]];
      If[
        topology[[3]] =!= loopMomenta ||
        TrueQ[Quiet @ FeynCalc`FCLoopBasisOverdeterminedQ[topology]],
        Message[BuildTopologies::partial, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      topologyID = Symbol[
        "Global`TopologyF" <> forwardTag <>
          "C" <> conjugateTag <>
          "N" <> ToString[index]
      ];
      external = topology[[4]];
      massRules = (FeynCalc`SPD[#] -> 0 &) /@
        Select[external, MemberQ[massless, #] &];
      conflicts = Select[
        topology[[5]],
        Function[rule,
          AnyTrue[
            massRules,
            SameQ[First[rule], First[#]] &&
              ! exactZeroQ[Last[rule] - Last[#]] &
          ]
        ]
      ];
      If[conflicts =!= {},
        Message[BuildTopologies::rules, conflicts];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      topology = FeynCalc`FCTopology[
        topologyID,
        topology[[2]],
        loopMomenta,
        external,
        DeleteDuplicates[Join[topology[[5]], massRules]],
        topology[[6]]
      ];
      completed = Quiet @ CheckAbort[
        FeynCalc`FCLoopBasisFindCompletion[
          topology,
          FeynCalc`Names -> (# &)
        ],
        $Failed
      ];
      If[! MatchQ[completed, _FeynCalc`FCTopology],
        Message[BuildTopologies::topology, topology];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      checks = Quiet @ CheckAbort[
        {
          FeynCalc`FCLoopValidTopologyQ[completed],
          ! FeynCalc`FCLoopBasisIncompleteQ[completed],
          ! FeynCalc`FCLoopBasisOverdeterminedQ[completed]
        },
        $Failed
      ];
      If[checks =!= {True, True, True},
        Message[BuildTopologies::topology, completed];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      mappedFamily = Quiet @ CheckAbort[
        converted[[1]] /.
          FeynCalc`FCLoopCreateRuleGLIToGLI[completed, converted[[2]]],
        $Failed
      ];
      baseGLIs = DeleteDuplicates @ Cases[
        mappedFamily,
        _FeynCalc`GLI,
        {0, Infinity}
      ];
      If[Length[baseGLIs] =!= 1,
        Message[BuildTopologies::term, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];
      baseGLI = First[baseGLIs];
      familyCoefficient = mappedFamily /. baseGLI -> 1;
      If[
        ! FreeQ[familyCoefficient, _FeynCalc`GLI] ||
          ! exactZeroQ[mappedFamily - familyCoefficient baseGLI],
        Message[BuildTopologies::term, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      cutIndices = topologyPropagatorIndex[
        FeynCalc`SFAD[#],
        completed,
        loopMomenta
      ] & /@ cutMomenta;
      If[
        ! VectorQ[cutIndices, IntegerQ] ||
        Length[DeleteDuplicates[cutIndices]] =!= Length[cutIndices],
        Message[BuildTopologies::cut, term];
        Throw[$Failed, $buildTopologiesFailure]
      ];

      Association[
        "Propagators" -> term,
        "Topology" -> completed,
        "BaseGLI" -> baseGLI,
        "FamilyCoefficient" -> familyCoefficient,
        "CutMomenta" -> cutMomenta,
        "CutIndices" -> cutIndices,
        "CutDirections" -> cutDirections
      ]
    ];

    families = MapIndexed[buildOne[#1, First[#2]] &, terms];
    Print @ Grid[
      Prepend[
        {
          #["Topology"][[1]],
          #["Topology"][[4]],
          #["CutIndices"],
          #["CutDirections"]
        } & /@ families,
        {"Topology", "External momenta", "Cut indices", "Cut directions"}
      ],
      Frame -> All
    ];
    families
  ],
  $buildTopologiesFailure
];

BuildTopologies[partialFractions_, loopMomenta_, config_] := (
  If[! MatchQ[loopMomenta, {__}],
    Message[BuildTopologies::loops, loopMomenta],
    Message[BuildTopologies::config, config]
  ];
  $Failed
);

TopologyEquivalence::input =
  "Expected a list of cut-aware topology records, but received `1`.";

TopologyEquivalence::record =
  "Topology record `1` is missing or has inconsistent topology, cut or AMFlow metadata.";

TopologyEquivalence::names =
  "Topology names must be unique, but received `1`.";

TopologyEquivalence::mapping =
  "FeynCalc could not determine topology mappings for `1`.";

TopologyEquivalence::coverage =
  "FeynCalc returned incomplete or inconsistent mapping coverage for `1`.";

$topologyEquivalenceFailure = "FeynFacetTopologyEquivalenceFailure";


topologyPhysicalSignature[data_Association] := Module[
  {physical = data["Physical"], factors},
  factors = If[physical["Role"] === "Cut",
    KeyDrop[#, "EnergyDirection"] & /@ physical["Factors"],
    physical["Factors"]
  ];
  <|
    "Role" -> physical["Role"],
    "Factors" -> SortBy[
      factors,
      ToString[InputForm[#]] &
    ]
  |>
];

topologyPropagatorCore[propagator_, shift_List, kinematics_List] :=
  Module[{mapped, explicit, core},
    mapped = FeynCalc`FCReplaceMomenta[
      FeynCalc`FCI[propagator],
      shift
    ];
    explicit = Quiet @ Check[
      FeynCalc`FeynAmpDenominatorExplicit[
        mapped,
        FeynCalc`FCI -> True
      ],
      $Failed
    ];
    If[explicit === $Failed || exactZeroQ[explicit], Return[$Failed]];
    core = Quiet @ Check[
      Cancel[Together[(1/explicit) /. kinematics]],
      $Failed
    ];
    If[
      core === $Failed ||
        ! FreeQ[
          core,
          FeynCalc`FeynAmpDenominator |
            FeynCalc`PropagatorDenominator |
            FeynCalc`StandardPropagatorDenominator
        ],
      $Failed,
      core
    ]
];

propagatorDescriptor[propagator_, kinematics_List : {}] := Module[
  {
    raw, internal, objects, denominator, standard, quadratic, linear,
    type, power, eta, momentum, unitInternal, unitCore
  },
  raw = FeynCalc`FCI[propagator];
  internal = If[
    MatchQ[
      raw,
      (_FeynCalc`PropagatorDenominator |
        _FeynCalc`StandardPropagatorDenominator)
    ],
    FeynCalc`FeynAmpDenominator[raw],
    raw
  ];
  objects = Cases[
    internal,
    denominator : (
        FeynCalc`PropagatorDenominator |
        FeynCalc`StandardPropagatorDenominator
      )[___] :> denominator,
    {0, Infinity}
  ];
  If[Length[objects] =!= 1, Return[$Failed]];
  denominator = First[objects];
  standard = Head[denominator] === FeynCalc`StandardPropagatorDenominator;
  If[standard,
    quadratic = ! exactZeroQ[denominator[[1]]];
    linear = ! exactZeroQ[denominator[[2]]];
    type = Which[
      quadratic && ! linear, "QuadraticLorentzian",
      ! quadratic && linear, "LinearLorentzian",
      True, $Failed
    ];
    If[! MatchQ[denominator[[4]], {_Integer?Positive, 1 | -1}],
      Return[$Failed]
    ];
    {power, eta} = denominator[[4]];
    unitInternal = internal /. HoldPattern[
        FeynCalc`StandardPropagatorDenominator[
          q_, sp_, mass_, {_, eta0_}
        ]
      ] :> FeynCalc`StandardPropagatorDenominator[
        q, sp, mass, {1, eta0}
      ],
    type = "QuadraticLorentzian";
    power = 1;
    eta = Missing["NotAvailable"];
    unitInternal = internal
  ];
  If[type === $Failed, Return[$Failed]];
  momentum = If[type === "QuadraticLorentzian",
    Expand[
      First[denominator] /. {
        FeynCalc`Momentum[q_, ___] :> q,
        I FeynCalc`Momentum[q_, ___] :> q
      }
    ],
    Missing["LinearPropagator"]
  ];
  unitCore = topologyPropagatorCore[unitInternal, {}, kinematics];
  If[unitCore === $Failed, Return[$Failed]];
  <|
    "Representation" -> If[standard, "Standard", "Legacy"],
    "Momentum" -> momentum,
    "Type" -> type,
    "Power" -> power,
    "EtaSign" -> eta,
    "UnitCore" -> unitCore
  |>
];

topologyRecordQ[record_Association] := TrueQ @ Quiet @ CheckAbort[Module[
  {
    required, topology, cutMomenta, cutIndices, cutDirections,
    amflow, cutMask, propagatorInfo, propagatorMomenta, propagatorTypes,
    propagatorPowers, propagatorEtaSigns, incomplete, overdetermined,
    normalizedTopology, propagatorData, physicalData, validPhysicalQ,
    externalPropagatorData, context, contextKeys, baseGLI, baseIndices,
    activeSlots, familyCoefficient
  },

  required = {
    "Type", "Version", "DiagramPair", "Topology", "BaseGLI",
    "FamilyCoefficient", "CutMomenta", "CutIndices", "CutDirections",
    "PropagatorData", "ExternalPropagatorData", "AnalyticContext",
    "AMFlowInfo"
  };
  If[! ContainsAll[Keys[record], required], Return[False]];
  If[
    record["Type"] =!= "FeynFacetTopologyRecord" ||
      record["Version"] =!= 2 ||
      ! AssociationQ[record["DiagramPair"]],
    Return[False]
  ];

  topology = record["Topology"];
  cutMomenta = record["CutMomenta"];
  cutIndices = record["CutIndices"];
  cutDirections = record["CutDirections"];
  propagatorData = record["PropagatorData"];
  externalPropagatorData = record["ExternalPropagatorData"];
  context = record["AnalyticContext"];
  amflow = record["AMFlowInfo"];
  If[
    ! MatchQ[topology, _FeynCalc`FCTopology] ||
      ! AssociationQ[amflow] ||
      ! ContainsAll[
        Keys[amflow],
        {"Family", "Loop", "Prescription", "Cut", "PhysicalCausalStatus"}
      ],
    Return[False]
  ];
  contextKeys = {
    "Gamma5Scheme", "GlobalBasis", "GlobalBasisGram",
    "SetEvanescentZero", "SetMassZero", "SetDistributionZero",
    "CollinearRelations", "Assumptions", "KinematicMassDimensions", "LoopDimension",
    "DimensionRule", "CutConvention", "DistributionConvention",
    "FeynFacetSourceHash", "Fingerprint"
  };
  If[
    ! AssociationQ[context] ||
      ! ContainsAll[Keys[context], contextKeys] ||
      context["Gamma5Scheme"] =!= "BMHV" ||
      context["DimensionRule"] =!= $dimensionRule ||
      context["FeynFacetSourceHash"] =!= $feynFacetSourceHash ||
      Lookup[context, "Fingerprint", Missing[]] =!=
        reductionFingerprint[KeyDrop[context, "Fingerprint"]],
    Return[False]
  ];

  baseGLI = record["BaseGLI"];
  familyCoefficient = record["FamilyCoefficient"];
  If[
    ! MatchQ[baseGLI, _FeynCalc`GLI] ||
      baseGLI[[1]] =!= topology[[1]] ||
      Length[baseGLI[[2]]] =!= Length[topology[[2]]] ||
      ! VectorQ[baseGLI[[2]], IntegerQ] ||
      ! FreeQ[familyCoefficient, _FeynCalc`GLI],
    Return[False]
  ];
  baseIndices = baseGLI[[2]];
  activeSlots = Flatten @ Position[
    baseIndices,
    _Integer?Positive,
    {1},
    Heads -> False
  ];

  cutMask = amflow["Cut"];
  propagatorInfo = propagatorDescriptor[#, topology[[5]]] & /@ topology[[2]];
  If[MemberQ[propagatorInfo, $Failed], Return[False]];
  propagatorMomenta = Lookup[propagatorInfo, "Momentum"];
  propagatorTypes = Lookup[propagatorInfo, "Type"];
  propagatorPowers = Lookup[propagatorInfo, "Power"];
  propagatorEtaSigns = Lookup[propagatorInfo, "EtaSign"];
  If[
    ! ListQ[propagatorData] ||
      Length[propagatorData] =!= Length[propagatorInfo] ||
      ! AllTrue[propagatorData, AssociationQ],
    Return[False]
  ];
  If[
    ! ListQ[externalPropagatorData] ||
      ! AllTrue[
        externalPropagatorData,
        AssociationQ[#] &&
          MemberQ[{"Amplitude", "Conjugate"}, #1["Role"]] &&
          #1["Descriptor", "Representation"] === "Standard" &&
          #1["Descriptor", "EtaSign"] === #1["PhysicalEtaSign"] &
      ],
    Return[False]
  ];
  If[! And @@ MapThread[
      SameQ[Lookup[#1, "Algebraic", Missing[]], #2] &,
      {propagatorData, propagatorInfo}
    ],
    Return[False]
  ];
  physicalData = Lookup[propagatorData, "Physical", Missing[]];
  validPhysicalQ[physical_, index_] := Which[
    ! AssociationQ[physical], False,
    MemberQ[cutIndices, index],
      physical["Role"] === "Cut" &&
        MatchQ[physical["Factors"], {_Association}] &&
        physical["Factors"][[1, "CausalSide"]] === 0 &&
        ContainsAll[
          Keys[First[physical["Factors"]]],
          {
            "SourceID", "SourcePower", "CutID", "Parton",
            "MeasurementRole", "EnergyReference"
          }
        ] &&
        IntegerQ[physical["Factors"][[1, "SourcePower"]]] &&
        physical["Factors"][[1, "SourcePower"]] > 0 &&
        physical["Factors"][[1, "EnergyDirection"]] ===
          cutDirections[[First @ FirstPosition[cutIndices, index]]],
    physical["Role"] === "Auxiliary",
      physical["Factors"] === {},
    physical["Role"] === "Uncut",
      MatchQ[physical["Factors"], {__Association}] &&
        Length[DeleteDuplicates[
          Lookup[physical["Factors"], "PhysicalEtaSign"],
          SameQ
        ]] === 1 &&
        AllTrue[
          physical["Factors"],
          ContainsAll[Keys[#1], {"SourceID", "SourcePower"}] &&
            IntegerQ[#1["SourcePower"]] && #1["SourcePower"] > 0 &&
            MemberQ[{"Amplitude", "Conjugate"}, #1["Role"]] &&
            MemberQ[{1, -1}, #1["CausalSide"]] &&
            #1["CausalSide"] === #1["PhysicalEtaSign"] &
        ],
    True, False
  ];
  normalizedTopology = topology;
  incomplete = Quiet @ CheckAbort[Check[
    FeynCalc`FCLoopBasisIncompleteQ[normalizedTopology],
    $Failed
  ], $Failed];
  overdetermined = Quiet @ CheckAbort[Check[
    FeynCalc`FCLoopBasisOverdeterminedQ[normalizedTopology],
    $Failed
  ], $Failed];
  And[
    TrueQ @ Quiet @ CheckAbort[
      Check[FeynCalc`FCLoopValidTopologyQ[normalizedTopology], False],
      False
    ],
    incomplete === False,
    overdetermined === False,
    topology[[1]] === amflow["Family"],
    topology[[3]] === amflow["Loop"],
    amflow["PhysicalCausalStatus"] === "Verified",
    Length[amflow["Prescription"]] === Length[topology[[3]]],
    AllTrue[amflow["Prescription"], MemberQ[{0, 1, -1}, #] &],
    Length[cutMomenta] === Length[cutIndices] === Length[cutDirections],
    DuplicateFreeQ[cutIndices],
    AllTrue[
      cutIndices,
      IntegerQ[#] && 1 <= # <= Length[topology[[2]]] &
    ],
    AllTrue[cutDirections, MemberQ[{1, -1}, #] &],
    AllTrue[cutMomenta, ! exactZeroQ[#] &],
    AllTrue[propagatorInfo, #1["Representation"] === "Standard" &],
    AllTrue[propagatorEtaSigns, SameQ[#1, 1] &],
    AllTrue[propagatorPowers, SameQ[#, 1] &],
    And @@ MapThread[
      MemberQ[{1, -1}, momentumRelativeSign[#1, #2]] &,
      {cutMomenta, propagatorMomenta[[cutIndices]]}
    ],
    AllTrue[
      propagatorTypes[[cutIndices]],
      SameQ[#, "QuadraticLorentzian"] &
    ],
    ListQ[cutMask] && Length[cutMask] === Length[topology[[2]]],
    Sort[Flatten @ Position[cutMask, 1]] === Sort[cutIndices],
    AllTrue[cutMask, MemberQ[{0, 1}, #] &],
    And @@ MapIndexed[validPhysicalQ[#1, First[#2]] &, physicalData],
    Sort @ Select[
      Range[Length[physicalData]],
      physicalData[[#]]["Role"] =!= "Auxiliary" &
    ] === Sort[activeSlots],
    exactDataQ[KeyDrop[record, "Created"]]
  ]
], False];

topologyRecordQ[_] := False;

topologyRecordQ[record_, pair_Association] :=
  topologyRecordQ[record] &&
    SameQ[Lookup[record, "DiagramPair", Missing[]], pair];

parseTopologyMapping[
    {sourceTopology_FeynCalc`FCTopology, shift_List, gliRule_},
    recordByName_Association
  ] := Module[
  {indices, inputGLI, outputGLI, sourceName, targetName},

  If[
    ! MemberQ[{Rule, RuleDelayed}, Head[gliRule]] ||
      ! AllTrue[shift, MatchQ[#, _Rule | _RuleDelayed] &],
    Return[Failure[
      "MalformedMapping",
      <|"Mapping" -> {sourceTopology, shift, gliRule}|>
    ]]
  ];
  sourceName = sourceTopology[[1]];
  If[! KeyExistsQ[recordByName, sourceName],
    Return[Failure[
      "UnknownMappingSource",
      <|"Source" -> sourceName|>
    ]]
  ];
  indices = Table[
    Unique["topologyIndex$"],
    {Length[sourceTopology[[2]]]}
  ];
  inputGLI = FeynCalc`GLI[sourceName, indices];
  outputGLI = Replace[inputGLI, gliRule, {0}];
  If[
    ! MatchQ[outputGLI, _FeynCalc`GLI] || outputGLI === inputGLI,
    Return[Failure[
      "InapplicableGLIRule",
      <|"Source" -> sourceName, "Rule" -> gliRule|>
    ]]
  ];
  targetName = outputGLI[[1]];
  If[! KeyExistsQ[recordByName, targetName],
    Return[Failure[
      "UnknownMappingTarget",
      <|"Source" -> sourceName, "Target" -> targetName|>
    ]]
  ];
  <|
    "SourceTopology" -> sourceTopology,
    "Source" -> sourceName,
    "Target" -> targetName,
    "LoopMomentumRules" -> shift,
    "GLIRule" -> gliRule,
    "ProbeGLI" -> inputGLI,
    "MappedProbeGLI" -> outputGLI,
    "ProbeIndices" -> indices,
    "MappedProbe" -> outputGLI
  |>
];

parseTopologyMapping[other_, _Association] := Failure[
  "MalformedMapping",
  <|"Mapping" -> other|>
];

topologyGLIIndexMap[parsed_Association, source_, target_] := Module[
  {indices, mappedIndices, positions},

  indices = parsed["ProbeIndices"];
  mappedIndices = parsed["MappedProbe"][[2]];
  If[
    Length[source[[2]]] =!= Length[target[[2]]] ||
      Length[mappedIndices] =!= Length[indices],
    Return[$Failed]
  ];
  If[! VectorQ[mappedIndices, MemberQ[indices, #] &], Return[$Failed]];
  positions = Position[
      mappedIndices,
      #,
      {1},
      Heads -> False
    ] & /@ indices;
  If[
    ! AllTrue[positions, MatchQ[#, {{_Integer}}] &],
    Return[$Failed]
  ];
  positions[[All, 1, 1]]
];

topologyVerifiedGLIRule[sourceName_, targetName_, indexMap_List] := Module[
  {count, variables, left, right},

  count = Length[indexMap];
  If[Sort[indexMap] =!= Range[count], Return[$Failed]];
  variables = Table[Unique["gliIndex$"], {count}];
  left = FeynCalc`GLI[
    sourceName,
    Pattern[#, Blank[]] & /@ variables
  ];
  right = FeynCalc`GLI[
    targetName,
    variables[[Ordering[indexMap]]]
  ];
  With[
    {verifiedLeft = left, verifiedRight = right},
    HoldPattern[verifiedLeft] :> verifiedRight
  ]
];

topologyCutMapping[source_, target_, shift_, indexMap_] := Module[
  {
    sourceIndices, targetIndices, sourceMomenta, targetMomenta,
    sourceDirections, targetDirections, mappedIndices, targetPosition,
    sign, checks, failure
  },

  sourceIndices = source["CutIndices"];
  targetIndices = target["CutIndices"];
  sourceMomenta = source["CutMomenta"];
  targetMomenta = target["CutMomenta"];
  sourceDirections = source["CutDirections"];
  targetDirections = target["CutDirections"];
  mappedIndices = indexMap[[sourceIndices]];
  If[Sort[mappedIndices] =!= Sort[targetIndices],
    Return[{False, "cut indices do not map one-to-one"}]
  ];

  checks = Table[
    targetPosition = First @ FirstPosition[
      targetIndices,
      mappedIndices[[index]]
    ];
    sign = momentumRelativeSign[
      Expand[sourceMomenta[[index]] /. shift],
      targetMomenta[[targetPosition]]
    ];
    Which[
      sign === 0,
        {False, "mapped cut momentum is not the target cut momentum"},
      sign sourceDirections[[index]] =!= targetDirections[[targetPosition]],
        {False, "cut energy direction is reversed"},
      True,
        {True, Null}
    ],
    {index, Length[sourceIndices]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, mappedIndices}
];

topologyAffineMapping[source_, target_, shift_List] := Module[
  {
    sourceTopology, targetTopology, sourceLoops, targetLoops,
    sourceExternal, targetExternal, external, mappedLoops, matrix,
    translation, translationMatrix, remainder, determinant, coefficients,
    leftSides
  },

  sourceTopology = source["Topology"];
  targetTopology = target["Topology"];
  sourceLoops = sourceTopology[[3]];
  targetLoops = targetTopology[[3]];
  sourceExternal = sourceTopology[[4]];
  targetExternal = targetTopology[[4]];
  If[Length[sourceLoops] =!= Length[targetLoops],
    Return[{False, "loop counts differ"}]
  ];
  If[
    Sort[sourceExternal] =!= Sort[targetExternal] ||
      Sort[sourceTopology[[5]]] =!= Sort[targetTopology[[5]]],
    Return[{False, "external momentum bases or kinematic rules differ"}]
  ];
  If[
    ! AllTrue[shift, MatchQ[#, _Rule | _RuleDelayed] &],
    Return[{False, "loop mapping contains malformed rules"}]
  ];
  leftSides = First /@ shift;
  If[
    ! DuplicateFreeQ[leftSides] ||
      ! AllTrue[leftSides, MemberQ[sourceLoops, #] &],
    Return[{False, "mapping contains non-loop replacement rules"}]
  ];

  mappedLoops = Expand[sourceLoops /. shift];
  matrix = Table[
    Coefficient[mappedLoops[[i]], targetLoops[[j]]],
    {i, Length[sourceLoops]},
    {j, Length[targetLoops]}
  ];
  external = Sort[sourceExternal];
  translation = Expand[mappedLoops - matrix.targetLoops];
  translationMatrix = Table[
    Coefficient[translation[[i]], external[[j]]],
    {i, Length[sourceLoops]},
    {j, Length[external]}
  ];
  remainder = Expand[translation - translationMatrix.external];
  coefficients = Flatten[{matrix, translationMatrix}];
  If[! AllTrue[coefficients, exactRationalQ],
    Return[{False, "mapping coefficients are not exact real rationals"}]
  ];
  If[! And @@ (exactZeroQ /@ remainder),
    Return[{False, "loop mapping is not affine-linear in declared momenta"}]
  ];
  determinant = Cancel[Det[matrix]];
  If[
    ! exactZeroQ[determinant - 1] &&
      ! exactZeroQ[determinant + 1],
    Return[{False, "loop mapping does not have unit Jacobian"}]
  ];

  {True, <|
    "LoopMatrix" -> matrix,
    "TranslationMatrix" -> translationMatrix,
    "ExternalBasis" -> external,
    "Determinant" -> determinant
  |>}
];

topologyPropagatorMapping[source_, target_, shift_, indexMap_] := Module[
  {
    sourceTopology, targetTopology, sourcePropagators, targetPropagators,
    sourceInfo, targetInfo, sourceTypes, targetTypes, sourcePowers,
    targetPowers, sourceEta, targetEta, sourcePhysical, targetPhysical,
    sourceCore, targetCore, checks, failure
  },

  sourceTopology = source["Topology"];
  targetTopology = target["Topology"];
  sourcePropagators = sourceTopology[[2]];
  targetPropagators = targetTopology[[2]];
  sourceInfo = Lookup[source["PropagatorData"], "Algebraic"];
  targetInfo = Lookup[target["PropagatorData"], "Algebraic"];
  If[MemberQ[Join[sourceInfo, targetInfo], $Failed],
    Return[{False, "unsupported propagator representation"}]
  ];
  sourceTypes = Lookup[sourceInfo, "Type"];
  targetTypes = Lookup[targetInfo, "Type"];
  sourcePowers = Lookup[sourceInfo, "Power"];
  targetPowers = Lookup[targetInfo, "Power"];
  sourceEta = Lookup[sourceInfo, "EtaSign"];
  targetEta = Lookup[targetInfo, "EtaSign"];
  sourcePhysical = topologyPhysicalSignature /@ source["PropagatorData"];
  targetPhysical = topologyPhysicalSignature /@ target["PropagatorData"];

  checks = Table[
    sourceCore = topologyPropagatorCore[
      sourcePropagators[[index]],
      shift,
      sourceTopology[[5]]
    ];
    targetCore = topologyPropagatorCore[
      targetPropagators[[indexMap[[index]]]],
      {},
      targetTopology[[5]]
    ];
    Which[
      sourceTypes[[index]] =!= targetTypes[[indexMap[[index]]]],
        {False, "propagator types do not match"},
      sourceEta[[index]] =!= targetEta[[indexMap[[index]]]],
        {False, "stored propagator eta signs do not match"},
      sourcePowers[[index]] =!= targetPowers[[indexMap[[index]]]],
        {False, "propagator powers do not match"},
      sourcePhysical[[index]] =!= targetPhysical[[indexMap[[index]]]],
        {False, "physical propagator provenance does not match"},
      sourceCore === $Failed || targetCore === $Failed,
        {False, "could not extract a propagator polynomial"},
      ! exactZeroQ[sourceCore - targetCore],
        {False, "mapped propagator polynomials do not match"},
      True,
        {True, Null}
    ],
    {index, Length[sourcePropagators]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, "Verified"}
];

topologyPrescriptionMapping[source_, target_, matrix_] := Module[
  {
    sourcePrescription, targetPrescription, targetPositions,
    checks, failure
  },

  sourcePrescription = source["AMFlowInfo"]["Prescription"];
  targetPrescription = target["AMFlowInfo"]["Prescription"];

  checks = Table[
    targetPositions = Flatten @ Position[
      matrix[[i]],
      coefficient_ /; coefficient =!= 0,
      {1},
      Heads -> False
    ];
    If[
      targetPositions === {} ||
        ! AllTrue[
          targetPrescription[[targetPositions]],
          SameQ[#, sourcePrescription[[i]]] &
        ],
      {False, "AMFlow loop-routing labels are mixed"},
      {True, Null}
    ],
    {i, Length[sourcePrescription]}
  ];
  failure = FirstCase[checks, check_ /; ! TrueQ[First[check]], Missing[]];
  If[! MissingQ[failure], Return[failure]];
  {True, True}
];

topologyPhysicalMapping[source_, target_, mapping_Association] := Module[
  {
    shift, indexMap, affineCheck, propagatorCheck, cutCheck,
    prescriptionCheck, verifiedGLIRule
  },

  shift = mapping["LoopMomentumRules"];
  indexMap = topologyGLIIndexMap[
    mapping,
    source["Topology"],
    target["Topology"]
  ];
  If[indexMap === $Failed,
    Return[{False, "GLI rule is not a strict propagator permutation"}]
  ];
  affineCheck = topologyAffineMapping[source, target, shift];
  If[! TrueQ[First[affineCheck]], Return[affineCheck]];
  propagatorCheck = topologyPropagatorMapping[
    source,
    target,
    shift,
    indexMap
  ];
  If[! TrueQ[First[propagatorCheck]], Return[propagatorCheck]];
  cutCheck = topologyCutMapping[source, target, shift, indexMap];
  If[! TrueQ[First[cutCheck]], Return[cutCheck]];
  prescriptionCheck = topologyPrescriptionMapping[
    source,
    target,
    affineCheck[[2, "LoopMatrix"]]
  ];
  If[! TrueQ[First[prescriptionCheck]], Return[prescriptionCheck]];
  verifiedGLIRule = topologyVerifiedGLIRule[
    source["Topology"][[1]],
    target["Topology"][[1]],
    indexMap
  ];
  If[verifiedGLIRule === $Failed,
    Return[{False, "could not construct the verified GLI rule"}]
  ];
  If[
    ! SameQ[
      Replace[mapping["ProbeGLI"], verifiedGLIRule, {0}],
      mapping["MappedProbeGLI"]
    ],
    Return[{False, "verified GLI rule disagrees with candidate mapping"}]
  ];

  {
    True,
    <|
      "Source" -> source["Topology"][[1]],
      "Target" -> target["Topology"][[1]],
      "LoopMomentumRules" -> shift,
      "LoopMomentumMatrix" -> affineCheck[[2, "LoopMatrix"]],
      "LoopTranslationMatrix" ->
        affineCheck[[2, "TranslationMatrix"]],
      "JacobianDeterminant" -> affineCheck[[2, "Determinant"]],
      "PropagatorIndexMap" -> indexMap,
      "CutIndexMap" -> Last[cutCheck],
      "CausalStatus" -> Last[propagatorCheck],
      "AMFlowRoutingCompatible" -> True,
      "GLIRule" -> verifiedGLIRule,
      "FeynCalcCandidateGLIRule" -> mapping["GLIRule"]
    |>
  }
];

TopologyEquivalence[topologies_List] := Catch[
  Module[
    {
      names, recordByName, classes = {}, mappings = {},
      rejectedCandidates = {}, partition, classRows, representatives,
      causalStatus, searchStatus
    },

    If[! AllTrue[topologies, topologyRecordQ],
      Message[
        TopologyEquivalence::record,
        FirstCase[
          topologies,
          record_ /; ! topologyRecordQ[record],
          Missing["InvalidRecord"]
        ]
      ];
      Throw[$Failed, $topologyEquivalenceFailure]
    ];
    If[topologies === {},
      Print @ Grid[
        {{"Representative", "Count", "Members"}, {"None", 0, {}}},
        Frame -> All
      ];
      Return[<|
        "Scope" -> "CutAwareIBP",
        "PhysicalCausalStatus" -> "NoTopologies",
        "SearchStatus" -> "Complete",
        "Representatives" -> {},
        "Classes" -> {},
        "Mappings" -> {},
        "GLIRules" -> {},
        "RejectedCandidateMappings" -> {}
      |>]
    ];

    names = #["Topology"][[1]] & /@ topologies;
    If[! DuplicateFreeQ[names],
      Message[TopologyEquivalence::names, names];
      Throw[$Failed, $topologyEquivalenceFailure]
    ];
    recordByName = AssociationThread[names, topologies];

    partition[records_List] := Module[
      {
        result, rawMappings, rawRepresentatives, parsedMappings,
        representativeNames, mappingSources, mappingTargets,
        currentNames, targetName, sourceMaps, representative, members,
        incompatible, check
      },

      If[records === {}, Return[Null]];
      result = Quiet @ CheckAbort[
        FeynCalc`FCLoopFindTopologyMappings[
          Lookup[records, "Topology"],
          FeynCalc`Momentum -> {},
          FeynCalc`SubtopologyMarker -> False,
          FeynCalc`FCVerbose -> -1
        ],
        $Failed
      ];
      If[
        ! MatchQ[result, {{___List}, {___FeynCalc`FCTopology}}],
        Message[
          TopologyEquivalence::mapping,
          Lookup[records, "Topology"][[All, 1]]
        ];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];
      rawMappings = result[[1]];
      rawRepresentatives = result[[2]];
      parsedMappings = parseTopologyMapping[#, recordByName] & /@
        rawMappings;
      If[AnyTrue[parsedMappings, FailureQ],
        Message[
          TopologyEquivalence::mapping,
          FirstCase[parsedMappings, _Failure]
        ];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];
      currentNames = Lookup[records, "Topology"][[All, 1]];
      representativeNames = rawRepresentatives[[All, 1]];
      mappingSources = If[
        parsedMappings === {},
        {},
        Lookup[parsedMappings, "Source"]
      ];
      mappingTargets = If[
        parsedMappings === {},
        {},
        Lookup[parsedMappings, "Target"]
      ];
      If[
        ! DuplicateFreeQ[mappingSources] ||
          Sort[Join[mappingSources, representativeNames]] =!=
            Sort[currentNames] ||
          Complement[mappingTargets, representativeNames] =!= {},
        Message[TopologyEquivalence::coverage, currentNames];
        Throw[$Failed, $topologyEquivalenceFailure]
      ];

      Do[
        targetName = rawRepresentatives[[index, 1]];
        representative = recordByName[targetName];
        sourceMaps = Select[
          parsedMappings,
          #["Target"] === targetName &
        ];
        members = {targetName};
        incompatible = {};
        Do[
          check = topologyPhysicalMapping[
            recordByName[mapping["Source"]],
            representative,
            mapping
          ];
          If[TrueQ[First[check]],
            AppendTo[members, mapping["Source"]];
            AppendTo[mappings, Last[check]],
            AppendTo[incompatible, recordByName[mapping["Source"]]];
            AppendTo[rejectedCandidates, <|
              "Source" -> mapping["Source"],
              "Candidate" -> targetName,
              "Reason" -> Last[check]
            |>]
          ],
          {mapping, sourceMaps}
        ];
        AppendTo[classes, <|
          "Representative" -> targetName,
          "Members" -> members,
          "PhysicalCausalStatus" -> "Verified",
          "SearchStatus" -> If[
            incompatible === {},
            "FeynCalcWitnessesAccepted",
            "ConservativelySeparated"
          ]
        |>];
        partition[incompatible],
        {index, Length[rawRepresentatives]}
      ]
    ];

    partition[topologies];
    classRows = {
      #["Representative"],
      Length[#["Members"]],
      #["Members"]
    } & /@ classes;
    Print @ Grid[
      Prepend[classRows, {"Representative", "Count", "Members"}],
      Frame -> All
    ];
    representatives = recordByName /@ Lookup[classes, "Representative"];
    causalStatus = "Verified";
    searchStatus = If[
      rejectedCandidates === {},
      "AllFeynCalcCandidatesAccepted",
      "ConservativelySeparated"
    ];

    <|
      "Scope" -> "CutAwareIBP",
      "PhysicalCausalStatus" -> causalStatus,
      "SearchStatus" -> searchStatus,
      "Representatives" -> representatives,
      "Classes" -> classes,
      "Mappings" -> mappings,
      "GLIRules" -> If[mappings === {}, {}, Lookup[mappings, "GLIRule"]],
      "RejectedCandidateMappings" -> rejectedCandidates
    |>
  ],
  $topologyEquivalenceFailure
];

TopologyEquivalence[topologies_] := (
  Message[TopologyEquivalence::input, topologies];
  $Failed
);


===== FILE: Private\DimensionalShift.wl =====

(* Topology-dependent BMHV and Tarasov dimensional shifts. *)

DimensionalShift::loops =
  "Loop momenta must be a nonempty list identical to the topology loop-momentum ordering. Received `1`; topology uses `2`.";

DimensionalShift::topology =
  "The supplied object is not a valid complete FCTopology: `1`.";

DimensionalShift::dimension =
  "The topology must use exactly one symbolic loop dimension. Found `1`.";

DimensionalShift::propagators =
  "Could not map the propagator product into the supplied topology: `1`.";

DimensionalShift::cut =
  "Could not identify the required Cut propagators in the supplied topology: `1`.";

DimensionalShift::numerator =
  "The numerator is outside the supported polynomial SP/SPD/SPE grammar: `1`.";

DimensionalShift::evanescent =
  "Evanescent scalar products may contain only declared loop momenta. Unsupported objects: `1`.";

DimensionalShift::shift =
  "The topology-dependent dimensional recurrence failed at `1`.";

DimensionalShift::families =
  "Integral families must be a nonempty list of associations containing Propagators and Topology. Received `1`.";

$dimensionalShiftFailure = "FeynFacetDimensionalShiftFailure";


dimensionalShiftGramMomentFunction[
    covariance_,
    componentDimension_
  ] := Module[
  {
    loopCount, pairs, variables, sourceMatrix,
    determinantRules, beta, coefficient
  },

  loopCount = Length[covariance];
  pairs = Flatten[
    Table[{i, j}, {i, loopCount}, {j, i, loopCount}],
    1
  ];
  variables = Array[gramSource, Length[pairs]];
  sourceMatrix = ConstantArray[0, {loopCount, loopCount}];
  Do[
    With[
      {
        i = pairs[[position, 1]],
        j = pairs[[position, 2]],
        value = variables[[position]]
      },
      If[
        i === j,
        sourceMatrix[[i, i]] = value,
        sourceMatrix[[i, j]] = value/2;
        sourceMatrix[[j, i]] = value/2
      ]
    ],
    {position, Length[pairs]}
  ];
  determinantRules = Select[
    CoefficientRules[
      Expand @ Det[
        IdentityMatrix[loopCount] - 2 covariance . sourceMatrix
      ],
      variables
    ],
    Total[First[#]] > 0 &
  ];
  beta = componentDimension/2;
  coefficient[powers_List] /; Total[powers] === 0 := 1;
  coefficient[powers_List] /; Total[powers] > 0 :=
    coefficient[powers] = Module[{position, admissible},
      position = First @ FirstPosition[powers, _?(# > 0 &)];
      admissible = Select[
        determinantRules,
        And @@ Thread[First[#] <= powers] &
      ];
      -Total[
        Last[#] *
          (powers[[position]] +
            (beta - 1) First[#][[position]]) *
          coefficient[powers - First[#]] & /@ admissible
      ]/powers[[position]]
    ];

  Function[bilinears,
    Module[{normalized, powers},
      normalized = Sort /@ bilinears;
      If[! AllTrue[normalized, MemberQ[pairs, #] &], Return[$Failed]];
      powers = Count[normalized, #] & /@ pairs;
      Times @@ (Factorial /@ powers) coefficient[powers]
    ]
  ]
];

dimensionalShiftParameterPolynomial[
    polynomial_,
    parameters_List,
    positions_List,
    base_FeynCalc`GLI
  ] := Module[{indices, rules, oneTerm},
  indices = base[[2]];
  rules = CoefficientRules[Expand[polynomial], parameters];
  oneTerm[powers_List -> coefficient_] := Module[{dots, factor},
    dots = ConstantArray[0, Length[indices]];
    Scan[
      Function[i, dots[[positions[[i]]]] = powers[[i]]],
      Range[Length[parameters]]
    ];
    factor = (-1)^Total[powers] Times @@ Table[
      Pochhammer[indices[[positions[[i]]]], powers[[i]]],
      {i, Length[powers]}
    ];
    coefficient factor FeynCalc`GLI[base[[1]], indices + dots]
  ];
  Total[oneTerm /@ rules]
];

dimensionalShiftRaiseOnce[
    expression_,
    topology_FeynCalc`FCTopology,
    offset_,
    dimension_
  ] := Module[{glis, rules},
  glis = DeleteDuplicates @ Cases[
    expression,
    _FeynCalc`GLI,
    {0, Infinity}
  ];
  rules = Map[
    Function[gli,
      gli -> CheckAbort[
        FeynCalc`FCLoopGLIRaiseDimension[
          gli,
          topology,
          FeynCalc`Collecting -> False,
          FeynCalc`FCE -> True
        ] /. dimension -> dimension + offset,
        $Failed
      ]
    ],
    glis
  ];
  If[! FreeQ[rules, $Failed], Return[$Failed]];
  Expand[expression /. rules]
];

dimensionalShiftRaiseToD[
    expression_,
    topology_FeynCalc`FCTopology,
    rank_Integer?NonNegative,
    dimension_,
    cutIndices_List
  ] := Module[{offsets},
  If[rank === 0, Return[dimensionalShiftPreserveCuts[expression, cutIndices]]];
  offsets = 2 Reverse[Range[0, rank - 1]];
  Fold[
    If[#1 === $Failed,
      $Failed,
      With[{raised = dimensionalShiftRaiseOnce[#1, topology, #2, dimension]},
        If[
          raised === $Failed,
          $Failed,
          dimensionalShiftPreserveCuts[raised, cutIndices]
        ]
      ]
    ] &,
    expression,
    offsets
  ]
];

dimensionalShiftMultiplyNumerator[
    numerator_,
    integral_,
    rules_List
  ] := Module[{converted},
  converted = FeynCalc`ExpandScalarProduct[numerator] /. rules;
  Expand[converted integral] /.
    FeynCalc`GLI -> FeynCalc`GLIMultiply /.
    FeynCalc`GLIMultiply -> FeynCalc`GLI
];

dimensionalShiftPreserveCuts[expression_, cutIndices_List] := Module[
  {terms, projectTerm, projected},
  If[cutIndices === {}, Return[expression]];
  terms = termList[Expand[expression]];
  projectTerm[term_] := Module[{glis, indices},
    glis = Cases[term, _FeynCalc`GLI, {0, Infinity}];
    If[Length[glis] =!= 1, Return[$Failed]];
    indices = glis[[1, 2, cutIndices]];
    If[! VectorQ[indices, IntegerQ], Return[$Failed]];
    If[AllTrue[indices, Positive], term, 0]
  ];
  projected = projectTerm /@ terms;
  If[MemberQ[projected, $Failed], $Failed, Total[projected]]
];

dimensionalShiftNormalizeNumerator[expression_, loopMomenta_List] := Module[
  {expanded, dependsOnLoopQ},
  dependsOnLoopQ[object_] :=
    ! FreeQ[Unevaluated[object], Alternatives @@ loopMomenta];
  expanded = FeynCalc`FCE @ FeynCalc`ExpandScalarProduct[expression];
  expanded = expanded /. {
    HoldPattern[FeynCalc`SP[a_, b_]] /;
      dependsOnLoopQ[{a, b}] :>
        FeynCalc`SPD[a, b] - FeynCalc`SPE[a, b],
    HoldPattern[FeynCalc`SP[a_]] /;
      dependsOnLoopQ[a] :>
        FeynCalc`SPD[a] - FeynCalc`SPE[a]
  };
  FeynCalc`FCE @ FeynCalc`ExpandScalarProduct[expanded]
];


DimensionalShift[
    integrand_,
    propagators_,
    loopMomenta_List,
    topology_FeynCalc`FCTopology
  ] := Catch[
  Module[
    {
      valid, incomplete, overdetermined, dimensions, dimension,
      cutRecords, cutMomenta, cutDirections, cutIndices,
      algebraicPropagators, convertedPropagators, mappedPropagators,
      baseGLIs, base, propagatorCoefficient,
      rulesToGLI,
      expanded, denominatorObjects, speObjects, badSPE, validSPEQ,
      atoms, polynomial, coefficientRules,
      prepared, powers, matrix, parameters, positions, covariance,
      spePair, gramMoment, oneMonomial, result, unresolved, termGLICounts,
      parts, diagnostics
    },

    If[loopMomenta === {} || loopMomenta =!= topology[[3]],
      Message[DimensionalShift::loops, loopMomenta, topology[[3]]];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    valid = Quiet @ CheckAbort[
      FeynCalc`FCLoopValidTopologyQ[topology],
      $Failed
    ];
    incomplete = Quiet @ CheckAbort[
      FeynCalc`FCLoopBasisIncompleteQ[topology],
      $Failed
    ];
    overdetermined = Quiet @ CheckAbort[
      FeynCalc`FCLoopBasisOverdeterminedQ[topology],
      $Failed
    ];
    If[
      ! TrueQ[valid] || incomplete =!= False || overdetermined =!= False,
      Message[DimensionalShift::topology, topology];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    dimensions = Quiet @ CheckAbort[
      FeynCalc`FCGetDimensions[FeynCalc`FCI[topology[[2]]]],
      $Failed
    ];
    If[! MatchQ[dimensions, {_Symbol}],
      Message[DimensionalShift::dimension, dimensions];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    dimension = First[dimensions];

    cutRecords = cutData[propagators];
    If[cutRecords === $Failed,
      Message[DimensionalShift::cut, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    cutMomenta = First /@ cutRecords;
    cutDirections = Last /@ cutRecords;

    algebraicPropagators = propagators /. {
      HoldPattern[Cut[FeynCalc`SPD[q_]]] :> FeynCalc`SFAD[q],
      HoldPattern[Cut[FeynCalc`SPD[q_], _]] :> FeynCalc`SFAD[q]
    };
    convertedPropagators = CheckAbort[
      FeynCalc`FCLoopToGLI[algebraicPropagators, loopMomenta],
      $Failed
    ];
    If[! MatchQ[
        convertedPropagators,
        {_, _FeynCalc`FCTopology}
      ],
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    mappedPropagators = CheckAbort[
      convertedPropagators[[1]] /.
        FeynCalc`FCLoopCreateRuleGLIToGLI[
          topology,
          convertedPropagators[[2]]
        ],
      $Failed
    ];
    baseGLIs = Cases[
      mappedPropagators,
      _FeynCalc`GLI,
      {0, Infinity}
    ];
    If[mappedPropagators === $Failed || Length[baseGLIs] =!= 1,
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    base = First[baseGLIs];
    rulesToGLI = CheckAbort[
      Flatten @ FeynCalc`FCLoopCreateRulesToGLI[topology],
      $Failed
    ];
    If[rulesToGLI === $Failed,
      Message[DimensionalShift::shift, "rules to GLI"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    propagatorCoefficient = mappedPropagators /. base -> 1;
    If[
      ! FreeQ[propagatorCoefficient, FeynCalc`GLI] ||
      ! FreeQ[
        propagatorCoefficient,
        Alternatives @@ loopMomenta
      ],
      Message[DimensionalShift::propagators, propagators];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    propagatorCoefficient = FeynCalc`FCE @
      FeynCalc`FeynAmpDenominatorExplicit[
        propagatorCoefficient,
        FeynCalc`FCI -> True
      ];

    cutIndices = topologyPropagatorIndex[
      FeynCalc`SFAD[#],
      topology,
      loopMomenta
    ] & /@ cutMomenta;
    If[! FreeQ[cutIndices, $Failed],
      Message[DimensionalShift::cut, cutMomenta];
      Throw[$Failed, $dimensionalShiftFailure]
    ];

    expanded = dimensionalShiftNormalizeNumerator[
      propagatorCoefficient integrand,
      loopMomenta
    ];
    denominatorObjects = Cases[
      expanded,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
      {0, Infinity}
    ];
    If[denominatorObjects =!= {},
      Message[DimensionalShift::numerator, denominatorObjects];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    speObjects = DeleteDuplicates @ Cases[
      expanded,
      HoldPattern[FeynCalc`SPE[__]],
      {0, Infinity}
    ];
    validSPEQ[FeynCalc`SPE[a_]] := MemberQ[loopMomenta, a];
    validSPEQ[FeynCalc`SPE[a_, b_]] :=
      MemberQ[loopMomenta, a] && MemberQ[loopMomenta, b];
    validSPEQ[_] := False;
    badSPE = Select[speObjects, ! TrueQ[validSPEQ[#]] &];
    If[badSPE =!= {},
      Message[DimensionalShift::evanescent, badSPE];
      Throw[$Failed, $dimensionalShiftFailure]
    ];

    If[speObjects === {},
      result = dimensionalShiftMultiplyNumerator[
        expanded,
        base,
        rulesToGLI
      ],
      atoms = Table[Unique["spe$"], Length[speObjects]];
      polynomial = Expand[
        expanded /. Thread[speObjects -> atoms]
      ];
      If[! PolynomialQ[polynomial, atoms],
        Message[DimensionalShift::numerator, integrand];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      coefficientRules = CoefficientRules[polynomial, atoms];
      prepared = CheckAbort[
        FeynCalc`FCFeynmanPrepare[base, topology],
        $Failed
      ];
      If[! MatchQ[prepared, {_, _, _, _, _, _, _, _}],
        Message[DimensionalShift::shift, "FCFeynmanPrepare"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      powers = prepared[[3]];
      matrix = prepared[[4]];
      If[exactZeroQ[Det[matrix]],
        Message[DimensionalShift::shift, "singular loop matrix"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      parameters = powers[[All, 1]];
      positions = topologyPropagatorIndex[
        #[[2]],
        topology,
        loopMomenta
      ] & /@ powers;
      If[! FreeQ[positions, $Failed],
        Message[DimensionalShift::shift, "parameter mapping"];
        Throw[$Failed, $dimensionalShiftFailure]
      ];
      covariance = Adjugate[matrix]/2;
      gramMoment = dimensionalShiftGramMomentFunction[
        covariance,
        dimension - 4
      ];
      spePair[FeynCalc`SPE[a_, b_]] := {
        First @ FirstPosition[loopMomenta, a],
        First @ FirstPosition[loopMomenta, b]
      };
      spePair[FeynCalc`SPE[a_]] := With[
        {index = First @ FirstPosition[loopMomenta, a]},
        {index, index}
      ];
      oneMonomial[atomPowers_List -> coefficient_] := Module[
        {rank, bilinears, moment, shifted},
        rank = Total[atomPowers];
        bilinears = Flatten[
          MapThread[
            ConstantArray[spePair[#1], #2] &,
            {speObjects, atomPowers}
          ],
          1
        ];
        moment = gramMoment[bilinears];
        If[moment === $Failed, Return[$Failed]];
        shifted = dimensionalShiftParameterPolynomial[
          moment,
          parameters,
          positions,
          base
        ];
        shifted = dimensionalShiftRaiseToD[
          shifted,
          topology,
          rank,
          dimension,
          cutIndices
        ];
        If[shifted === $Failed, Return[$Failed]];
        dimensionalShiftMultiplyNumerator[
          coefficient,
          shifted,
          rulesToGLI
        ]
      ];
      result = Total[oneMonomial /@ coefficientRules]
    ];

    If[result === $Failed || ! FreeQ[result, $Failed],
      Message[DimensionalShift::shift, "Tarasov recurrence"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    result = Expand[result];
    unresolved = DeleteDuplicates @ Cases[
      result,
      object : HoldPattern[
        (FeynCalc`SP | FeynCalc`SPD | FeynCalc`SPE)[___]
      ] /; ! FreeQ[object, Alternatives @@ loopMomenta],
      {0, Infinity}
    ];
    If[unresolved =!= {} || ! FreeQ[result, FeynCalc`SPE],
      Message[DimensionalShift::numerator, unresolved];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    If[exactZeroQ[result], Return[0]];
    termGLICounts = Length @ Cases[
      #,
      _FeynCalc`GLI,
      {0, Infinity}
    ] & /@ termList[result];
    If[! AllTrue[termGLICounts, # === 1 &],
      Message[DimensionalShift::shift, "nonlinear GLI output"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    result = dimensionalShiftPreserveCuts[result, cutIndices];
    If[result === $Failed,
      Message[DimensionalShift::shift, "noninteger cut index"];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    parts = linearIntegralSum[result];
    diagnostics = If[
      FailureQ[parts],
      <|"SparseFailure" -> parts|>,
      <|
        "RemainderZero" -> exactZeroQ[parts["Remainder"]],
        "LoopDependentCoefficientCount" -> Count[
          Values[parts["Terms"]],
          coefficient_ /; ! FreeQ[
            coefficient,
            Alternatives @@ loopMomenta
          ]
        ],
        "Exact" -> exactDataQ[parts]
      |>
    ];
    If[
      FailureQ[parts] ||
        ! exactZeroQ[parts["Remainder"]] ||
        ! FreeQ[Values[parts["Terms"]], Alternatives @@ loopMomenta] ||
        ! exactDataQ[parts],
      Message[
        DimensionalShift::numerator,
        diagnostics
      ];
      Throw[$Failed, $dimensionalShiftFailure]
    ];
    result
  ],
  $dimensionalShiftFailure
];

DimensionalShift[
    integrand_,
    families : {__Association},
    loopMomenta_List
  ] := Module[
  {shiftFamily, shifted, sparse, result, masters, size},

  If[! AllTrue[
      families,
      KeyExistsQ[#, "Propagators"] &&
        MatchQ[Lookup[#, "Topology", Missing[]], _FeynCalc`FCTopology] &
    ],
    Message[DimensionalShift::families, families];
    Return[$Failed]
  ];

  shiftFamily[family_Association] := DimensionalShift[
    integrand,
    family["Propagators"],
    loopMomenta,
    family["Topology"]
  ];

  shifted = shiftFamily /@ families;
  If[MemberQ[shifted, $Failed], Return[$Failed]];
  sparse = linearAdd[linearIntegralSum /@ shifted];
  If[FailureQ[sparse],
    Message[DimensionalShift::families];
    Return[$Failed]
  ];
  result = linearToExpression[sparse];
  masters = Keys[sparse["Terms"]];
  size = Round[ByteCount[result]/1024., 0.01];
  Print @ Grid[
    {{"GLI terms", "Size (kB)"}, {Length[masters], size}},
    Frame -> All
  ];
  result
];

DimensionalShift[integrand_, {}, {}] := Module[{size},
  size = Round[ByteCount[integrand]/1024., 0.01];
  Print @ Grid[
    {{"GLI terms", "Size (kB)"}, {0, size}},
    Frame -> All
  ];
  integrand
];

DimensionalShift[integrand_, families_List, loopMomenta_List] := (
  Message[DimensionalShift::families, families];
  $Failed
);

DimensionalShift[
    integrand_,
    propagators_,
    loopMomenta_,
    topology_FeynCalc`FCTopology
  ] := (
  Message[DimensionalShift::loops, loopMomenta, topology[[3]]];
  $Failed
);

DimensionalShift[integrand_, propagators_, loopMomenta_, topology_] := (
  Message[DimensionalShift::topology, topology];
  $Failed
);


===== FILE: Private\Collinear.wl =====

(* Collinear projectors and the factorized pre-IBP pipeline. *)

convertAmplitudeSide[process_Association, name_String] := Module[
  {side, amplitudeFA, converted, momenta, selectedDiagram},

  side = process["Sides"][name];
  momenta = {
    Lookup[process["Incoming"], "Momentum"],
    Lookup[process["Outgoing"], "Momentum"]
  };
  selectedDiagram = FeynArts`DiagramExtract[
    side["Diagrams"],
    side["DiagramIndex"]
  ];
  amplitudeFA = FeynArts`CreateFeynAmp[
    selectedDiagram,
    FeynArts`Truncated -> False,
    FeynArts`PreFactor -> 1
  ];
  converted = FeynCalc`FCFAConvert[
    amplitudeFA,
    FeynCalc`IncomingMomenta -> momenta[[1]],
    FeynCalc`OutgoingMomenta -> momenta[[2]],
    FeynCalc`LoopMomenta -> side["LoopMomenta"],
    FeynCalc`ChangeDimension -> D,
    FeynCalc`DropSumOver -> True,
    FeynCalc`UndoChiralSplittings -> True,
    FeynCalc`SMP -> True,
    FeynCalc`Contract -> True,
    List -> True
  ] /. lightQuarkMassRules;

  If[! ListQ[converted] || Length[converted] =!= 1,
    fail[
      "DiagramsBySide[\"" <> name <> "\"]",
      side["DiagramIndex"],
      "The selected diagram did not convert to exactly one amplitude."
    ]
  ];

  First[converted]
];

convertAmplitudePair[process_Association] := AssociationMap[
  convertAmplitudeSide[process, #] &,
  sideNames
];


setDenominatorEta[expr_, sign : (1 | -1)] := FeynCalc`FCE[
  FeynCalc`ToSFAD[FeynCalc`FCI[expr], FeynCalc`FCI -> True] /.
    FeynCalc`StandardPropagatorDenominator[q_, sp_, mass_, {power_, _}] :>
      FeynCalc`StandardPropagatorDenominator[
        q,
        sp,
        mass,
        {power, sign}
      ]
];

topLevelFactors[expr_] := If[Head[expr] === Times, List @@ expr, {expr}];

commonFactorMultiset[lists_List] := Module[{first, unique},
  first = First[lists];
  unique = DeleteDuplicates[first];
  Flatten[
    Table[factor, {factor, unique},
      {Min[Count[#, factor] & /@ lists]}],
    1
  ]
];

removeFactorOnce[list_List, factor_] := DeleteCases[list, factor, {1}, 1];

splitAmplitude[expr_, side_] := Module[
  {
    external, terms, factorLists, propagatorLists, commonPropagators,
    numeratorLists, propagators, numerator, remaining
  },

  external = FeynCalc`FeynAmpDenominatorSplit[
    setDenominatorEta[
      expr,
      If[side === "conjugate", -1, 1]
    ],
    FeynCalc`FCI -> False,
    FeynCalc`FCE -> True
  ];
  terms = If[Head[external] === Plus, List @@ external, {external}];
  factorLists = topLevelFactors /@ terms;
  propagatorLists = Cases[
      #,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]]
    ] & /@ factorLists;
  commonPropagators = commonFactorMultiset[propagatorLists];
  numeratorLists = Fold[removeFactorOnce[#1, #2] &, #,
      commonPropagators] & /@ factorLists;
  propagators = Times @@ commonPropagators;
  numerator = Total[Times @@@ numeratorLists];
  remaining = DeleteDuplicates @ Cases[
    numerator,
    HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
    Infinity
  ];
  If[remaining =!= {},
    Message[CollinearFactorize::propagators, side, remaining];
    Throw[$Failed, $collinearFailure]
  ];

  {numerator, propagators}
];


splitFactorsByMomentum[expr_, {}] := {expr, 1};

splitFactorsByMomentum[expr_, momenta_List] := Module[
  {factors, independent, dependent},

  factors = topLevelFactors[expr];
  independent = Select[
    factors,
    FreeQ[#, Alternatives @@ momenta] &
  ];
  dependent = Select[
    factors,
    ! FreeQ[#, Alternatives @@ momenta] &
  ];
  {Times @@ independent, Times @@ dependent}
];

splitPropagatorsByMomentum[expr_, momenta_List] := Module[
  {split},

  If[momenta === {}, Return[{expr, 1}]];
  split = FeynCalc`FeynAmpDenominatorSplit[
    FeynCalc`FCI[expr],
    FeynCalc`Momentum -> momenta,
    FeynCalc`FCI -> True,
    FeynCalc`FCE -> True
  ];
  splitFactorsByMomentum[split, momenta]
];


propagatorSources[expr_, role_String, eta : (1 | -1)] := Module[
  {factors, descriptors},
  factors = propagatorFactors[expr];
  descriptors = propagatorDescriptor /@ factors;
  If[
    MemberQ[descriptors, $Failed] ||
      ! AllTrue[
        descriptors,
        #1["Representation"] === "Standard" &&
          #1["EtaSign"] === eta &
      ],
    Message[CollinearFactorize::eta, role, eta, expr];
    Throw[$Failed, $collinearFailure]
  ];
  MapIndexed[
    Function[{item, position}, <|
      "SourceID" -> {role, First[position]},
      "Expression" -> item[[1]],
      "Role" -> role,
      "PhysicalEtaSign" -> eta,
      "Descriptor" -> item[[2]],
      "LineMomentum" -> item[[2, "Momentum"]]
    |>],
    Transpose[{factors, descriptors}]
  ]
];

mixedEtaCore[sources_List] := FirstCase[
  Subsets[sources, {2}],
  {first_, second_} /;
      first["PhysicalEtaSign"] =!= second["PhysicalEtaSign"] &&
      first["Descriptor", "Type"] === second["Descriptor", "Type"] &&
      exactZeroQ[
        first["Descriptor", "UnitCore"] -
          second["Descriptor", "UnitCore"]
      ] :> first["Descriptor", "UnitCore"],
  Missing["NotFound"]
];


sumUnobservedPolarizations[expr_, process_Association] := Module[
  {momenta, result, remaining},

  momenta = Lookup[#, "Momentum"] & /@ Select[
    process["Outgoing"],
    MatchQ[#["Parton"], FeynArts`V[__]] &&
      MissingQ[#["HadronMomentum"]] &
  ];
  result = Fold[
    Function[{current, momentum},
      Quiet[
        FeynCalc`DoPolarizationSums[current, momentum, 0],
        FeynCalc`PolarizationSum::notmassless
      ]
    ],
    expr,
    DeleteDuplicates[momenta]
  ];
  remaining = DeleteDuplicates @ Cases[
    result,
    FeynCalc`Polarization[___],
    Infinity
  ];
  If[remaining =!= {},
    Message[CollinearFactorize::polarization, momenta, remaining];
    Throw[$Failed, $collinearFailure]
  ];
  result
];


unresolvedAlgebraObjects[expr_] := DeleteDuplicates @ Cases[
  FeynCalc`FCI[expr],
  object_ /; MemberQ[
    {
      FeynCalc`Calc,
      FeynCalc`DiracTrace,
      FeynCalc`DiracGamma,
      FeynCalc`DOT,
      FeynCalc`Polarization,
      FeynCalc`LorentzIndex,
      FeynCalc`CartesianIndex,
      FeynCalc`SUNIndex,
      FeynCalc`SUNT,
      FeynCalc`SUNF,
      FeynCalc`SUNDelta
    },
    Head[Unevaluated[object]]
  ] :> object,
  Infinity
];


densityHead[parton_, side_] := Which[
  MatchQ[parton, FeynArts`F[__]],
    If[side === "Incoming", \[CapitalPhi], \[CapitalDelta]],
  MatchQ[parton, -FeynArts`F[__]],
    If[side === "Incoming", \[CapitalPhi]b, \[CapitalDelta]b],
  True,
    fail[
      "Partons",
      parton,
      "A hadron-associated leg must currently be a quark or antiquark."
    ]
];

densityLegs[process_Association] := Select[
  Join[process["Incoming"], process["Outgoing"]],
  ! MissingQ[#["HadronMomentum"]] &
];

externalSpinTags[process_Association] := AssociationThread[
  Lookup[densityLegs[process], "Momentum"],
  Unique["externalSpin$"] & /@ densityLegs[process]
];

tagExternalSpinors[expr_, tags_Association] := expr /.
  spinor_FeynCalc`Spinor :> (spinor /. Normal[tags]);

densityRule[leg_Association, side_, tags_Association] := Module[
  {head, normalization, spinMomentum},

  If[MissingQ[leg["HadronMomentum"]], Return[{}]];
  head = densityHead[leg["Parton"], side];
  spinMomentum = Lookup[tags, leg["Momentum"]];
  normalization = FeynCalc`SPD[
    leg["HadronMomentum"],
    leg["DualDirection"]
  ];
  If[side === "Outgoing",
    normalization *= 2/leg["Fraction"]^3
  ];

  Thread[
    FeynCalc`FCI[{
      FeynCalc`GS[spinMomentum],
      FeynCalc`GSD[spinMomentum]
    }] -> normalization head[
      leg["Fraction"],
      leg["HadronMomentum"],
      leg["LongSpin"],
      leg["TransSpin"],
      leg["LongDirection"]
    ]
  ]
];

densityRules[process_Association, tags_Association] := Join[
  Flatten[densityRule[#, "Incoming", tags] & /@ process["Incoming"]],
  Flatten[densityRule[#, "Outgoing", tags] & /@ process["Outgoing"]]
];


setDistributionsZero[expr_, {}] := expr;

setDistributionsZero[expr_, heads_List] := With[
  {alternatives = Alternatives @@ heads},
  expr /. HoldPattern[alternatives[___]] :> 0
];


containsListedMomentumQ[expr_, momenta_List] :=
  ! FreeQ[Unevaluated[expr], Alternatives @@ momenta];

setEvanescentZero[expr_, {}] := expr;

setEvanescentZero[expr_, momenta_List] := Module[{external},
  external = FeynCalc`FCE[FeynCalc`ExpandScalarProduct[expr]];
  FeynCalc`FCI[external /. {
    HoldPattern[FeynCalc`SPE[a_, b_]] /;
      containsListedMomentumQ[{a, b}, momenta] :> 0,
    HoldPattern[FeynCalc`SPE[a_]] /;
      containsListedMomentumQ[a, momenta] :> 0,
    HoldPattern[FeynCalc`SP[a_, b_]] /;
      containsListedMomentumQ[{a, b}, momenta] :> FeynCalc`SPD[a, b],
    HoldPattern[FeynCalc`SP[a_]] /;
      containsListedMomentumQ[a, momenta] :> FeynCalc`SPD[a]
  }]
];


setMassZero[expr_, {}] := expr;

setMassZero[expr_, momenta_List] :=
  FeynCalc`FCI[expr] /.
    Thread[FeynCalc`FCI[FeynCalc`SPD /@ momenta] -> 0];


applyKinematicZeros[expr_, process_Association] := setMassZero[
  setEvanescentZero[expr, process["SetEvanescentZero"]],
  process["SetMassZero"]
];


fractionMeasure[process_Association] := Module[{fractions},
  fractions = DeleteDuplicates @ Select[
    Lookup[Join[process["Incoming"], process["Outgoing"]], "Fraction"],
    ! MissingQ[#] &
  ];
  Times @@ (dFraction /@ fractions)
];


factorizePair[config_Association] := Catch[
  Module[
    {
      process, eliminationRule, phase, amplitudes, completePair, splitPair,
      result, spinTags, taggedNumerator, missingSpinTags,
      remainingSpinTags, cutLoopMomenta, allLoopMomenta, preFactor, integrand,
      cutNormalizationFactor, loopNormalizationFactor,
      externalCuts, loopCuts, sidePropagators, externalPropagators,
      ordinaryPropagators, propagators, sources, externalSources, mixedCore,
      remainingPropagators,
      remainingAlgebra
    },

    If[! MatchQ[globalBasis, {_, _, _, _}],
      Message[CollinearFactorize::basis];
      Throw[$Failed, $collinearFailure]
    ];
    declareGlobalBasis[globalBasis];

    process = prepareProcess[
      normalizeProcess[config],
      Lookup[config, "DiagramsBySide", Missing["NotAvailable"]]
    ];
    eliminationRule = momentumEliminationRule[process];
    phase = buildPhaseData[process, eliminationRule];
    cutLoopMomenta = remainingPhaseSpaceMomenta[process];
    allLoopMomenta = DeleteDuplicates @ Join[
      cutLoopMomenta,
      process["VirtualLoopMomenta"]
    ];
    loopNormalizationFactor =
      (I Pi^(D/2))^Length[allLoopMomenta];
    cutNormalizationFactor =
      (I Pi^(D/2))^Length[cutLoopMomenta];
    amplitudes = convertAmplitudePair[process];
    splitPair = AssociationMap[
      splitAmplitude[amplitudes[#], ToLowerCase[#]] &,
      sideNames
    ];
    completePair = <|
      "Amplitude" -> First[splitPair["Amplitude"]],
      "Conjugate" -> FeynCalc`ComplexConjugate[
        First[splitPair["Conjugate"]]
      ]
    |>;
    sidePropagators = AssociationMap[
      splitPropagatorsByMomentum[
        Last[splitPair[#]] /. eliminationRule,
        allLoopMomenta
      ] &,
      sideNames
    ];
    externalPropagators = Times @@ (First /@ Values[sidePropagators]);
    ordinaryPropagators = Times @@ (Last /@ Values[sidePropagators]);
    sources = Join[
      propagatorSources[
        Last[sidePropagators["Amplitude"]],
        "Amplitude",
        1
      ],
      propagatorSources[
        Last[sidePropagators["Conjugate"]],
        "Conjugate",
        -1
      ]
    ];
    mixedCore = mixedEtaCore[sources];
    If[! MissingQ[mixedCore],
      Message[CollinearFactorize::mixedeta, mixedCore];
      Throw[$Failed, $collinearFailure]
    ];
    externalSources = Join[
      propagatorSources[
        First[sidePropagators["Amplitude"]],
        "Amplitude",
        1
      ],
      propagatorSources[
        First[sidePropagators["Conjugate"]],
        "Conjugate",
        -1
      ]
    ];
    {externalCuts, loopCuts} = splitFactorsByMomentum[
      phase["Cuts"],
      allLoopMomenta
    ];

    spinTags = externalSpinTags[process];
    taggedNumerator = tagExternalSpinors[
      Times @@ Values[completePair],
      spinTags
    ];
    missingSpinTags = Select[Values[spinTags], FreeQ[taggedNumerator, #] &];
    result = FeynCalc`FermionSpinSum[taggedNumerator];
    result = sumUnobservedPolarizations[result, process];

    result = result /. densityRules[process, spinTags];
    remainingSpinTags = Select[Values[spinTags], ! FreeQ[result, #] &];
    If[missingSpinTags =!= {} || remainingSpinTags =!= {},
      Message[
        CollinearFactorize::spinprojector,
        missingSpinTags,
        remainingSpinTags
      ];
      Throw[$Failed, $collinearFailure]
    ];
    result = setDistributionsZero[
      result,
      process["SetDistributionZero"]
    ];
    result = applyKinematicZeros[result, process];
    result = FeynCalc`Calc[
      result,
      Assumptions -> process["Assumptions"]
    ];
    result = applyKinematicZeros[result, process];
    result = applyKinematicZeros[result /. eliminationRule, process];
    result = reduceCollinearLoopProducts[
      result,
      process,
      allLoopMomenta
    ];
    remainingAlgebra = unresolvedAlgebraObjects[result];
    If[remainingAlgebra =!= {},
      Message[
        CollinearFactorize::algebra,
        Take[remainingAlgebra, UpTo[10]]
      ];
      Throw[$Failed, $collinearFailure]
    ];

    {preFactor, integrand} = CommonFactorSafe[
      result,
      allLoopMomenta
    ];
    remainingPropagators = DeleteDuplicates @ Cases[
      integrand,
      HoldPattern[(FeynCalc`FAD | FeynCalc`SFAD)[___]],
      Infinity
    ];
    If[remainingPropagators =!= {},
      Message[
        CollinearFactorize::propagators,
        "contracted integrand",
        remainingPropagators
      ];
      Throw[$Failed, $collinearFailure]
    ];

    preFactor =
      phase["Prefactor"] loopNormalizationFactor preFactor
        externalPropagators /.
        FeynCalc`SMP["g_s"] -> Sqrt[4 Pi \[Alpha]s];
    propagators = loopCuts setDenominatorEta[ordinaryPropagators, 1];
    result = <|
      "Process" -> process,
      "FractionMeasure" -> fractionMeasure[process],
      "PreFactor" -> preFactor,
      "PhaseSpace" -> phase["Measure"] externalCuts/cutNormalizationFactor,
      "Integrand" -> integrand,
      "Propagators" -> propagators,
      "LoopMomenta" -> allLoopMomenta,
      "PropagatorSources" -> Join[phase["CutSources"], sources],
      "ExternalPropagatorData" -> externalSources
    |>;

    If[! FreeQ[
        Lookup[result, {
          "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
          "Propagators", "LoopMomenta"
        }],
        process["IntegratedMomentum"]
      ],
      fail[
        "PartonIntegrated",
        process["IntegratedMomentum"],
        "The eliminated momentum survived in the output."
      ]
    ];
    If[
      ! exactDataQ @ Lookup[result, {
        "FractionMeasure", "PreFactor", "PhaseSpace", "Integrand",
        "Propagators", "LoopMomenta", "PropagatorSources",
        "ExternalPropagatorData"
      }],
      fail[
        "CollinearFactorize",
        result,
        "The analytic result contains inexact numerical data."
      ]
    ];

    result
  ],
  $collinearFailure
];

CollinearFactorize[config_Association] := Module[{result = factorizePair[config]},
  If[result === $Failed,
    $Failed,
    Lookup[result, {
      "FractionMeasure",
      "PreFactor",
      "PhaseSpace",
      "Integrand",
      "Propagators",
      "LoopMomenta"
    }]
  ]
];

CollinearFactorize[config_] := (
  Message[CollinearFactorize::config, config];
  $Failed
);

CollinearFactorizePreIBP::config =
  "Expected one complete configuration Association, but received `1`.";

CollinearFactorizePreIBP::missing =
  "Setup is missing required amplitude keys `1`.";

CollinearFactorizePreIBP::stage =
  "The pre-IBP pipeline failed at stage `1`.";

CollinearFactorizePreIBP::amflow =
  "Could not attach consistent AMFlow metadata to topology `1`.";

$preIBPFailure = "FeynFacetPreIBPFailure";


preIBPFail[stage_] := (
  Message[CollinearFactorizePreIBP::stage, stage];
  Throw[$Failed, $preIBPFailure]
);

topologyPropagatorData[family_Association, sources_List] := Module[
  {
    topology, kinematics, algebraicData, sourceData, sourceIDs,
    cutIndices, cutDirections, activeSlots, data, consumedIDs
  },

  topology = family["Topology"];
  kinematics = topology[[5]];
  cutIndices = family["CutIndices"];
  cutDirections = family["CutDirections"];
  If[! MatchQ[Lookup[family, "BaseGLI", $Failed], _FeynCalc`GLI],
    Return[$Failed]
  ];
  activeSlots = Flatten @ Position[
    family["BaseGLI"][[2]],
    _Integer?Positive,
    {1},
    Heads -> False
  ];
  algebraicData = propagatorDescriptor[#, kinematics] & /@ topology[[2]];
  sourceData = Map[
    Function[source,
      Append[
        source,
        "Descriptor" -> If[
          source["Role"] === "Cut",
          propagatorDescriptor[
            FeynCalc`SFAD[source["LineMomentum"]],
            kinematics
          ],
          propagatorDescriptor[source["Expression"], kinematics]
        ]
      ]
    ],
    sources
  ];
  sourceIDs = Lookup[sourceData, "SourceID", Missing["Absent"]];
  If[
    MemberQ[algebraicData, $Failed] ||
      AnyTrue[sourceData, #1["Descriptor"] === $Failed &] ||
      MemberQ[sourceIDs, _Missing] || ! DuplicateFreeQ[sourceIDs] ||
      ! AllTrue[
        algebraicData,
        #1["Representation"] === "Standard" && #1["EtaSign"] === 1 &
      ] ||
      ! AllTrue[
        Select[sourceData, #1["Role"] =!= "Cut" &],
        #1["Descriptor", "Representation"] === "Standard" &&
          #1["Descriptor", "EtaSign"] === #1["PhysicalEtaSign"] &
      ],
    Return[$Failed]
  ];

  data = MapIndexed[
    Function[{algebraic, position},
      Module[{index, cutPosition, matches, factors, cutSource},
        index = First[position];
        cutPosition = FirstPosition[cutIndices, index];
        If[! MissingQ[cutPosition],
          matches = Select[
            sourceData,
            #1["Role"] === "Cut" &&
              #1["Descriptor", "Type"] === algebraic["Type"] &&
              exactZeroQ[
                #1["Descriptor", "UnitCore"] - algebraic["UnitCore"]
              ] &
          ];
          If[Length[matches] =!= 1, Return[$Failed]];
          cutSource = First[matches];
          <|
            "Algebraic" -> algebraic,
            "Physical" -> <|
              "Role" -> "Cut",
              "Factors" -> {<|
                "CausalSide" -> 0,
                "PhysicalEtaSign" -> Missing["NotApplicable"],
                "SourceID" -> cutSource["SourceID"],
                "SourcePower" -> cutSource["Descriptor", "Power"],
                "EnergyDirection" -> cutDirections[[First[cutPosition]]],
                "CutID" -> cutSource["CutID"],
                "Parton" -> cutSource["Parton"],
                "MeasurementRole" -> cutSource["MeasurementRole"],
                "EnergyReference" -> cutSource["EnergyReference"]
              |>}
            |>
          |>,
          matches = Select[
            sourceData,
            #1["Role"] =!= "Cut" &&
              #1["Descriptor", "Type"] === algebraic["Type"] &&
              exactZeroQ[
                #1["Descriptor", "UnitCore"] - algebraic["UnitCore"]
              ] &
          ];
          factors = (<|
              "Role" -> #1["Role"],
              "CausalSide" -> If[#1["Role"] === "Amplitude", 1, -1],
              "PhysicalEtaSign" -> #1["PhysicalEtaSign"],
              "SourceID" -> #1["SourceID"],
              "SourcePower" -> #1["Descriptor", "Power"]
            |> &) /@ matches;
          If[
            (MemberQ[activeSlots, index] && factors === {}) ||
              (! MemberQ[activeSlots, index] && factors =!= {}),
            Return[$Failed]
          ];
          <|
            "Algebraic" -> algebraic,
            "Physical" -> If[
              factors === {},
              <|"Role" -> "Auxiliary", "Factors" -> {}|>,
              If[
                Length[DeleteDuplicates[
                  Lookup[factors, "PhysicalEtaSign"],
                  SameQ
                ]] === 1,
                <|"Role" -> "Uncut", "Factors" -> factors|>,
                Return[$Failed]
              ]
            ]
          |>
        ]
      ]
    ],
    algebraicData
  ];
  If[MemberQ[data, $Failed], Return[$Failed]];
  consumedIDs = Cases[
    data,
    factor_Association /; KeyExistsQ[factor, "SourceID"] :>
      factor["SourceID"],
    Infinity
  ];
  If[
    ! DuplicateFreeQ[consumedIDs] ||
      ! ContainsAll[sourceIDs, consumedIDs],
    Return[$Failed]
  ];
  data
];

completeTopologyRecord[
    family_Association,
    amflow_Association,
    pair_Association,
    sources_List,
    externalPropagatorData_List,
    context_Association
  ] := Module[
  {
    topology, loopMomenta, prescription, propagatorCount,
    cutIndices, cutDirections, cutMask, propagatorData, record
  },

  topology = family["Topology"];
  loopMomenta = amflow["LoopMomenta"];
  prescription = amflow["Prescription"];
  propagatorCount = Length[topology[[2]]];
  cutIndices = family["CutIndices"];
  cutDirections = family["CutDirections"];

  If[
    topology[[3]] =!= loopMomenta ||
      Length[prescription] =!= Length[loopMomenta] ||
      ! AllTrue[prescription, MemberQ[{0, 1, -1}, #] &] ||
      Length[cutIndices] =!= Length[cutDirections] ||
      ! DuplicateFreeQ[cutIndices] ||
      ! AllTrue[cutIndices, IntegerQ[#] && 1 <= # <= propagatorCount &] ||
      ! AllTrue[cutDirections, MemberQ[{1, -1}, #] &],
    Message[CollinearFactorizePreIBP::amflow, topology[[1]]];
    Return[$Failed]
  ];

  cutMask = ReplacePart[
    ConstantArray[0, propagatorCount],
    Thread[cutIndices -> ConstantArray[1, Length[cutIndices]]]
  ];
  propagatorData = topologyPropagatorData[family, sources];
  If[propagatorData === $Failed || MemberQ[propagatorData, $Failed],
    Message[CollinearFactorizePreIBP::amflow, topology[[1]]];
    Return[$Failed]
  ];
  record = Join[
    family,
    <|
      "Type" -> "FeynFacetTopologyRecord",
      "Version" -> 2,
      "DiagramPair" -> pair,
      "AnalyticContext" -> context,
      "PropagatorData" -> propagatorData,
      "ExternalPropagatorData" -> externalPropagatorData,
      "AMFlowInfo" -> <|
        "Family" -> topology[[1]],
        "Loop" -> loopMomenta,
        "Prescription" -> prescription,
        "Cut" -> cutMask,
        "PhysicalCausalStatus" -> "Verified"
      |>
    |>
  ];
  If[topologyRecordQ[record], record, $Failed]
];

CollinearFactorizePreIBP[config_Association] := Catch[
  Module[
    {
      amplitudeKeys, missing, forwardAmplitudes,
      conjugateAmplitudes, diagrams, pipelineConfig, factorized,
      fractions, families, amflow, pair, topologies,
      shiftedIntegrand, context, sourceIDs, coveredSourceIDs
    },

    amplitudeKeys = {"ForwardAmplitudes", "ConjugateAmplitudes"};
    missing = Complement[amplitudeKeys, Keys[config]];
    If[missing =!= {},
      Message[CollinearFactorizePreIBP::missing, missing];
      Throw[$Failed, $preIBPFailure]
    ];

    forwardAmplitudes = config["ForwardAmplitudes"];
    conjugateAmplitudes = config["ConjugateAmplitudes"];
    If[
      ! AllTrue[
        {forwardAmplitudes, conjugateAmplitudes},
        AssociationQ[#] && KeyExistsQ[#, "SelectedIndex"] &
      ],
      preIBPFail["diagram selection"]
    ];
    diagrams = GenerateDiagram[config];
    If[diagrams === $Failed, preIBPFail["GenerateDiagram"]];
    printSelectedDiagrams[diagrams, config];

    pipelineConfig = Join[
      config,
      <|
        "DiagramsBySide" -> diagrams
      |>
    ];
    factorized = factorizePair[pipelineConfig];
    If[! AssociationQ[factorized],
      preIBPFail["CollinearFactorize"]
    ];
    fractions = PartialFraction[
      factorized["Propagators"],
      factorized["LoopMomenta"]
    ];
    If[fractions === $Failed, preIBPFail["PartialFraction"]];
    families = BuildTopologies[
      fractions,
      factorized["LoopMomenta"],
      pipelineConfig
    ];
    If[families === $Failed, preIBPFail["BuildTopologies"]];

    amflow = amflowPrescription[factorized["Process"]];
    If[! AssociationQ[amflow], preIBPFail["AMFlowPrescription"]];
    context = analyticContext[factorized["Process"]];
    If[context === $Failed, preIBPFail["BMHV analytic context"]];
    pair = <|
      "Forward" -> forwardAmplitudes["SelectedIndex"],
      "Conjugate" -> conjugateAmplitudes["SelectedIndex"]
    |>;
    topologies = completeTopologyRecord[
        #,
        amflow,
        pair,
        factorized["PropagatorSources"],
        factorized["ExternalPropagatorData"],
        context
      ] & /@ families;
    If[MemberQ[topologies, $Failed], preIBPFail["AMFlow metadata"]];
    sourceIDs = Lookup[
      factorized["PropagatorSources"],
      "SourceID",
      Missing["Absent"]
    ];
    coveredSourceIDs = DeleteDuplicates @ Cases[
      Lookup[topologies, "PropagatorData"],
      factor_Association /; KeyExistsQ[factor, "SourceID"] :>
        factor["SourceID"],
      Infinity
    ];
    If[
      MemberQ[sourceIDs, _Missing] ||
        ! ContainsExactly[sourceIDs, coveredSourceIDs],
      preIBPFail["physical propagator coverage"]
    ];

    shiftedIntegrand = DimensionalShift[
      factorized["Integrand"],
      topologies,
      factorized["LoopMomenta"]
    ];
    If[shiftedIntegrand === $Failed, preIBPFail["DimensionalShift"]];

    Join[
      Lookup[factorized, {"FractionMeasure", "PreFactor", "PhaseSpace"}],
      {shiftedIntegrand, topologies}
    ]
  ],
  $preIBPFailure
];

CollinearFactorizePreIBP[config_] := (
  Message[CollinearFactorizePreIBP::config, config];
  $Failed
);

GenerateCollinearFactorizePreIBPResult::setup =
  "Setup must contain a nonempty CardName and positive selected forward and conjugate diagram indices.";

GenerateCollinearFactorizePreIBPResult::failed =
  "At least one supplied pre-IBP output contains $Failed.";

GenerateCollinearFactorizePreIBPResult::topologies =
  "Topologies contains an invalid or pair-inconsistent topology record.";


sourceNotebookFile[] := Module[{file},
  file = Quiet @ Check[NotebookFileName[], $Failed];
  If[StringQ[file] && StringLength[file] > 0,
    ExpandFileName[file],
    Missing["NotAvailable"]
  ]
];

GenerateCollinearFactorizePreIBPResult[
    setup_Association,
    fractionMeasure_,
    preFactor_,
    phaseSpace_,
    integrand_,
    topologies_List,
    resultDirectory_: Automatic
  ] := Module[
  {cardName, pair, sourceNotebook, directory, contexts, process, context},
  cardName = Lookup[setup, "CardName", Missing["NotAvailable"]];
  pair = selectedPairFromSetup[setup];
  If[
    ! StringQ[cardName] || StringLength[StringTrim[cardName]] === 0 ||
      pair === $Failed,
    Message[GenerateCollinearFactorizePreIBPResult::setup];
    Return[$Failed]
  ];
  If[
    ! FreeQ[
      HoldComplete[
        fractionMeasure, preFactor, phaseSpace, integrand, topologies
      ],
      $Failed
    ],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
    Return[$Failed]
  ];
  If[! AllTrue[topologies, topologyRecordQ[#, pair] &],
    Message[GenerateCollinearFactorizePreIBPResult::topologies];
    Return[$Failed]
  ];
  contexts = DeleteDuplicates[Lookup[topologies, "AnalyticContext"], SameQ];
  context = If[
    topologies === {},
    process = Catch[normalizeProcess[setup], $collinearFailure];
    If[! AssociationQ[process], $Failed, analyticContext[process]],
    If[Length[contexts] === 1, First[contexts], $Failed]
  ];
  If[context === $Failed,
    Message[GenerateCollinearFactorizePreIBPResult::topologies];
    Return[$Failed]
  ];
  If[
    ! exactDataQ @ HoldComplete[
      setup, fractionMeasure, preFactor, phaseSpace, integrand, topologies,
      context
    ],
    Message[GenerateCollinearFactorizePreIBPResult::failed];
    Return[$Failed]
  ];
  sourceNotebook = Lookup[setup, "SourceNotebook", Automatic];
  sourceNotebook = If[
    sourceNotebook === Automatic,
    sourceNotebookFile[],
    If[
      StringQ[sourceNotebook] && StringLength[sourceNotebook] > 0,
      ExpandFileName[sourceNotebook],
      Missing["NotAvailable"]
    ]
  ];
  directory = Replace[
    resultDirectory,
    Automatic :> Lookup[setup, "ResultDirectory", Missing["NotAvailable"]]
  ];
  directory = If[
    StringQ[directory] && StringLength[StringTrim[directory]] > 0,
    ExpandFileName[directory],
    Missing["NotAvailable"]
  ];
  Join[resultHeader["FeynFacet-CollinearFactorizePreIBP", 2], <|
    "CardName" -> StringTrim[cardName],
    "Pair" -> pair,
    "ResultDirectory" -> directory,
    "AnalyticContext" -> context,
    "SourceNotebook" -> sourceNotebook,
    "Setup" -> setup,
    "FractionMeasure" -> fractionMeasure,
    "PreFactor" -> preFactor,
    "PhaseSpace" -> phaseSpace,
    "Integrand" -> integrand,
    "Topologies" -> topologies
  |>]
];

GenerateCollinearFactorizePreIBPResult[___] := (
  Message[GenerateCollinearFactorizePreIBPResult::setup];
  $Failed
);


===== FILE: Private\Reduction.wl =====

(* Kira reduction, sparse master reconstruction, and artifact output. *)

IBP::input =
  "IBP expects a nonempty list of valid FeynFacet pre-IBP result Associations.";

IBP::stage =
  "IBP failed during `1`: `2`.";

KiraReduction::input =
  "KiraReduction expects a nonempty list of valid FeynFacet pre-IBP result Associations or saved result files.";

CoefficientSimplification::input =
  "CoefficientSimplification expects the original pre-IBP result list and its matching FeynFacet-KiraReduction Association.";

$ibpFailure = "FeynFacetIBPFailure";


ibpFail[stage_, detail_] := (
  Message[IBP::stage, stage, detail];
  Throw[$Failed, $ibpFailure]
);

validPreIBPResultQ[result_] := Module[{pair, context},
  If[
    ! AssociationQ[result] ||
      Lookup[result, "Format", None] =!=
        "FeynFacet-CollinearFactorizePreIBP" ||
      Lookup[result, "FormatVersion", None] =!= 2 ||
      ! And @@ (KeyExistsQ[result, #] & /@ {
        "CardName", "Pair", "Setup", "FractionMeasure",
        "PreFactor", "PhaseSpace", "Integrand", "Topologies",
        "ResultDirectory", "AnalyticContext"
      }),
    Return[False]
  ];
  pair = result["Pair"];
  context = result["AnalyticContext"];
  AssociationQ[pair] &&
    IntegerQ[Lookup[pair, "Forward", None]] &&
    IntegerQ[Lookup[pair, "Conjugate", None]] &&
    AssociationQ[context] &&
    Lookup[context, "Gamma5Scheme", Missing[]] === "BMHV" &&
    Lookup[context, "FeynFacetSourceHash", Missing[]] ===
      $feynFacetSourceHash &&
    Lookup[context, "Fingerprint", Missing[]] ===
      reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
    ListQ[result["Topologies"]] &&
    AllTrue[
      result["Topologies"],
      topologyRecordQ[#, pair] &&
        SameQ[#1["AnalyticContext"], context] &
    ] &&
    exactDataQ @ Lookup[result, {
      "Setup", "FractionMeasure", "PreFactor", "PhaseSpace",
      "Integrand", "Topologies", "AnalyticContext"
    }]
];

validateCutGLIs[expression_, records_List] := Module[
  {recordByName, glis, bad},
  recordByName = Association[
    #1["Topology"][[1]] -> #1 & /@ records
  ];
  glis = DeleteDuplicates @ Cases[
    HoldComplete[expression],
    _FeynCalc`GLI,
    Infinity
  ];
  bad = Select[glis, Function[gli, Module[{record, indices},
    record = Lookup[recordByName, gli[[1]], Missing["UnknownFamily"]];
    If[! AssociationQ[record], Return[True]];
    indices = gli[[2]];
    Length[indices] =!= Length[record["Topology"][[2]]] ||
      ! AllTrue[
        indices[[record["CutIndices"]]],
        IntegerQ[#] && # > 0 &
      ]
  ]]];
  If[bad === {}, True, bad]
];

ibpBaseSetup[setup_Association] := Join[
  setup,
  <|
    "ForwardAmplitudes" -> KeyDrop[
      Lookup[setup, "ForwardAmplitudes", <||>],
      "SelectedIndex"
    ],
    "ConjugateAmplitudes" -> KeyDrop[
      Lookup[setup, "ConjugateAmplitudes", <||>],
      "SelectedIndex"
    ]
  |>
];

ibpInputSummary[item_, includeTargets_] := Module[
  {file, result, directory},
  file = If[StringQ[item], ExpandFileName[item], Missing["InMemory"]];
  If[StringQ[item] && ! FileExistsQ[file], Return[$Failed]];
  result = If[StringQ[item], Quiet @ Check[Get[file], $Failed], item];
  If[! validPreIBPResultQ[result], Return[$Failed]];
  directory = Lookup[result, "ResultDirectory", Missing[]];
  If[! StringQ[directory] || ! DirectoryQ[directory],
    directory = If[StringQ[file], DirectoryName[DirectoryName[file]], $Failed]
  ];
  If[directory === $Failed || ! DirectoryQ[directory], Return[$Failed]];
  <|
    "CardName" -> result["CardName"],
    "Pair" -> result["Pair"],
    "Setup" -> ibpBaseSetup[result["Setup"]],
    "FractionMeasure" -> result["FractionMeasure"],
    "PhaseSpace" -> result["PhaseSpace"],
    "AnalyticContext" -> result["AnalyticContext"],
    "ResultDirectory" -> ExpandFileName[directory],
    "Records" -> result["Topologies"],
    "Targets" -> If[TrueQ[includeTargets],
      DeleteDuplicates[
        Cases[result["Integrand"], _FeynCalc`GLI, {0, Infinity}]
      ],
      {}
    ],
    "Source" -> If[StringQ[file], file, result]
  |>
];

ibpInputData[items_List, includeTargets_: False] := Module[
  {summaries, unique, pairs, data},
  If[items === {} || ! (AllTrue[items, AssociationQ] || AllTrue[items, StringQ]),
    ibpFail["input validation", "expected nonempty Associations or saved result files"]
  ];
  summaries = ibpInputSummary[#, includeTargets] & /@ items;
  If[MemberQ[summaries, $Failed],
    ibpFail["input validation", "a pre-IBP result is missing, invalid or has no result directory"]
  ];
  pairs = Lookup[summaries, "Pair"];
  If[! DuplicateFreeQ[pairs],
    ibpFail["input validation", "diagram pairs must be unique"]
  ];
  unique[key_] := DeleteDuplicates[Lookup[summaries, key], SameQ];
  If[! AllTrue[
      {
        "CardName", "Setup", "FractionMeasure", "PhaseSpace",
        "ResultDirectory", "AnalyticContext"
      },
      Length[unique[#]] === 1 &
    ],
    ibpFail["input validation", "results do not share one card, setup, measure and directory"]
  ];
  data = AssociationMap[First[unique[#]] &,
    {
      "CardName", "Setup", "FractionMeasure", "PhaseSpace",
      "ResultDirectory", "AnalyticContext"
    }
  ];
  Join[data, <|
    "Pairs" -> pairs,
    "Records" -> Flatten[Lookup[summaries, "Records"], 1],
    "RawTargets" -> DeleteDuplicates[Flatten[Lookup[summaries, "Targets"], 1]],
    "Sources" -> Lookup[summaries, "Source"]
  |>]
];

ibpCompleteKinematics[records_List, dimensionMap_Association] := Module[
  {
    topologies, externalLists, loopLists, ruleLists, external,
    baseRules, pairs, generatedRules = {}, reverseRules = {},
    counter = 0, lhs, invariant, rhs, augmentedTopologies,
    kiraFamilies, invariants, generatedInvariants, missingDimensions,
    massDimensions, symbolPrefix
  },

  topologies = Lookup[records, "Topology"];
  externalLists = #[[4]] & /@ topologies;
  loopLists = #[[3]] & /@ topologies;
  ruleLists = #[[5]] & /@ topologies;
  If[
    Length[DeleteDuplicates[externalLists, SameQ]] =!= 1 ||
      Length[DeleteDuplicates[loopLists, SameQ]] =!= 1 ||
      Length[DeleteDuplicates[ruleLists, SameQ]] =!= 1,
    ibpFail[
      "kinematic completion",
      "representative topologies do not share one external basis"
    ]
  ];
  external = First[externalLists];
  baseRules = First[ruleLists];
  (* Fermat silently stalls on long invariant identifiers. *)
  symbolPrefix = "Global`f" <>
    StringTake[reductionFingerprint[{external, baseRules}], 4] <> "p";
  pairs = Flatten[
    Table[{external[[i]], external[[j]]},
      {i, Length[external]}, {j, i, Length[external]}],
    1
  ];

  Do[
    lhs = FeynCalc`FCI[FeynCalc`SPD[pair[[1]], pair[[2]]]];
    If[SameQ[lhs /. baseRules, lhs],
      counter++;
      invariant = Symbol[symbolPrefix <> ToString[counter]];
      With[{candidate = invariant},
        If[
          OwnValues[candidate] =!= {} || DownValues[candidate] =!= {} ||
            UpValues[candidate] =!= {} || SubValues[candidate] =!= {},
          ibpFail[
            "kinematic completion",
            "generated invariant already has definitions: " <>
              ToString[candidate, InputForm]
          ]
        ]
      ];
      rhs = If[
        SameQ[pair[[1]], pair[[2]]],
        invariant,
        invariant/2
      ];
      AppendTo[generatedRules, lhs -> rhs];
      AppendTo[
        reverseRules,
        invariant -> If[
          SameQ[pair[[1]], pair[[2]]],
          FeynCalc`SPD[pair[[1]]],
          2 FeynCalc`SPD[pair[[1]], pair[[2]]]
        ]
      ]
    ],
    {pair, pairs}
  ];

  augmentedTopologies = Replace[
    topologies,
    FeynCalc`FCTopology[
        name_, propagators_, loops_, ext_, rules_, options_
      ] :> FeynCalc`FCTopology[
        name,
        propagators,
        loops,
        ext,
        DeleteDuplicates[Join[rules, generatedRules]],
        options
      ],
    {1}
  ];
  If[
    ! AllTrue[
      augmentedTopologies,
      TrueQ[FeynCalc`FCLoopValidTopologyQ[#]] &&
        ! TrueQ[FeynCalc`FCLoopBasisIncompleteQ[#]] &
    ],
    ibpFail[
      "kinematic completion",
      "the completed FCTopology basis is invalid or incomplete"
    ]
  ];
  invariants = FeynCalc`FCLoopGetKinematicInvariants[
    augmentedTopologies,
    Check -> False,
    FeynCalc`FCFeynmanPrepare -> False,
    FeynCalc`FCVerbose -> -1,
    Union -> True
  ];
  invariants = DeleteCases[Flatten[{invariants}], 0 | 1];
  invariants = DeleteDuplicates[invariants];
  generatedInvariants = First /@ reverseRules;
  missingDimensions = Select[
    Complement[invariants, generatedInvariants],
    ! KeyExistsQ[dimensionMap, #] &
  ];
  If[missingDimensions =!= {},
    ibpFail[
      "kinematic completion",
      "missing mass dimensions for " <>
        ToString[missingDimensions, InputForm]
    ]
  ];
  massDimensions = (# -> If[
        MemberQ[generatedInvariants, #],
        2,
        dimensionMap[#]
      ]) & /@ invariants;
  kiraFamilies = MapThread[
    <|"Topology" -> #2, "CutIndices" -> #1["CutIndices"]|> &,
    {records, augmentedTopologies}
  ];

  <|
    "PhysicalRecords" -> records,
    "KiraFamilies" -> kiraFamilies,
    "MassDimensions" -> massDimensions,
    "ReverseRules" -> reverseRules
  |>
];

ibpInsertCuts[path_String, cutIndices_List] := Module[
  {lines, position},
  lines = Import[path, "Lines"];
  lines = DeleteCases[
    lines,
    line_String /;
      StringStartsQ[StringTrim[line], "cut_propagators:"]
  ];
  position = FirstPosition[
    lines,
    line_String /;
      StringStartsQ[StringTrim[line], "top_level_sectors:"]
  ];
  If[MissingQ[position],
    ibpFail["Kira configuration", "missing top_level_sectors"]
  ];
  lines = Insert[
    lines,
    "    cut_propagators: [" <>
      StringRiffle[ToString /@ Sort[cutIndices], ", "] <> "]",
    position[[1]] + 1
  ];
  Export[path, StringRiffle[lines, "\n"] <> "\n", "String"];
];

packageVersion[name_String] := If[
  Names[name] === {},
  Missing["NotAvailable"],
  Quiet @ Check[Symbol[name], Missing["NotAvailable"]]
];

ibpRuntime[] := Module[{kira, fermat, supportFile},
  kira = If[
    ValueQ[Global`$FACETKiraExecutable],
    Global`$FACETKiraExecutable,
    FileNameJoin[{
      $feynFacetRoot, "Addon", "Other_Addon", "Kira", "bin", "kira"
    }]
  ];
  fermat = If[
    ValueQ[Global`$FACETFermatExecutable],
    Global`$FACETFermatExecutable,
    FileNameJoin[{DirectoryName[kira], "fer64"}]
  ];
  supportFile = FileNameJoin[{DirectoryName[fermat], "BACKWARD", "chdat"}];
  If[
    ! FileExistsQ[kira] || ! FileExistsQ[fermat] || ! FileExistsQ[supportFile],
    ibpFail[
      "Kira launch",
      "the complete Kira/Fermat runtime is not installed"
    ]
  ];
  <|
    "KiraExecutable" -> ExpandFileName[kira],
    "KiraExecutableHash" -> FileHash[kira, "SHA256"],
    "FermatExecutable" -> ExpandFileName[fermat],
    "FermatExecutableHash" -> FileHash[fermat, "SHA256"],
    "SupportFile" -> ExpandFileName[supportFile],
    "SupportFileHash" -> FileHash[supportFile, "SHA256"]
  |>
];

reductionInputPayload[
    records_List,
    targets_List,
    massDimensions_List,
    runtime_Association
  ] := <|
  "SchemaVersion" -> 2,
  "Topologies" -> SortBy[records, ToString[InputForm[#1["Topology"][[1]]]] &],
  "Targets" -> SortBy[targets, ToString[InputForm[#]] &],
  "MassDimensions" -> SortBy[massDimensions, ToString[InputForm[First[#]]] &],
  "IntegralOrdering" -> 2,
  "Runtime" -> runtime,
  "FeynFacetSourceHash" -> $feynFacetSourceHash,
  "FeynCalcVersion" -> packageVersion["FeynCalc`$FeynCalcVersion"],
  "FeynHelpersVersion" -> packageVersion["FeynHelpers`$FeynHelpersVersion"]
|>;

sourceInputPayload[records_List, targets_List, context_Association] := <|
  "SchemaVersion" -> 2,
  "TopologyRecords" -> SortBy[
    records,
    ToString[InputForm[#1["Topology"][[1]]]] &
  ],
  "Targets" -> SortBy[targets, ToString[InputForm[#]] &],
  "AnalyticContext" -> context
|>;

ibpResetProject[
    projectDirectory_String,
    allowedRoot_String,
    payload_Association,
    runtime_Association
  ] := Module[
  {
    root, project, payloadPath, fingerprintPath,
    storedPayload, storedFingerprint, fingerprint, resumeEligible
  },
  root = ExpandFileName[allowedRoot];
  project = ExpandFileName[projectDirectory];
  If[! DirectoryQ[root],
    ibpFail["project setup", "the result directory does not exist"]
  ];
  If[
    project === root || ! StringStartsQ[
      project <> $PathnameSeparator,
      root <> $PathnameSeparator
    ],
    ibpFail["project setup", "unsafe IBP project path"]
  ];
  payloadPath = FileNameJoin[{project, "reduction_input.wxf"}];
  fingerprintPath = FileNameJoin[{project, "reduction_input.sha256"}];
  storedPayload = If[
    FileExistsQ[payloadPath],
    Quiet @ Check[Import[payloadPath, "WXF"], $Failed],
    $Failed
  ];
  storedFingerprint = If[
    FileExistsQ[fingerprintPath],
    StringTrim @ Quiet @ Check[Import[fingerprintPath, "String"], ""],
    ""
  ];
  fingerprint = reductionFingerprint[payload];
  resumeEligible = DirectoryQ[project] &&
    TrueQ[Global`$FACETResumeKira] &&
    SameQ[storedPayload, payload] && storedFingerprint === fingerprint;
  If[DirectoryQ[project] && ! resumeEligible,
    DeleteDirectory[project, DeleteContents -> True]
  ];
  If[
    ! DirectoryQ[project],
    CreateDirectory[project, CreateIntermediateDirectories -> True]
  ];
  Export[payloadPath, payload, "WXF"];
  Export[fingerprintPath, fingerprint <> "\n", "String"];
  <|
    "Directory" -> project,
    "ResumeEligible" -> resumeEligible,
    "InputPayload" -> payload,
    "InputFingerprint" -> fingerprint,
    "Runtime" -> runtime
  |>
];

ibpPrepareKiraProject[
    records_List,
    targets_List,
    projectState_Association,
    massDimensions_List
  ] := Module[
  {
    familyRoot, combinedDirectory, manifest, record, topology,
    name, familyTargets, familyDirectory, cutIndices, familyBlocks,
    kinematics, reduceLines, jobLines
  },

  familyRoot = FileNameJoin[{projectState["Directory"], "families"}];
  combinedDirectory = FileNameJoin[{projectState["Directory"], "kira"}];
  If[
    ! DirectoryQ[familyRoot],
    CreateDirectory[familyRoot, CreateIntermediateDirectories -> True]
  ];

  manifest = Table[
    record = records[[index]];
    topology = record["Topology"];
    name = topology[[1]];
    cutIndices = Sort[record["CutIndices"]];
    familyTargets = Select[targets, SameQ[#[[1]], name] &];
    If[familyTargets === {},
      ibpFail["Kira target construction", "empty target family"]
    ];
    If[
      ! AllTrue[
        familyTargets,
        AllTrue[#[[2, cutIndices]], IntegerQ[#] && # > 0 &] &
      ],
      ibpFail[
        "Kira target construction",
        "a requested integral removes an oriented cut propagator"
      ]
    ];

    If[
      CheckAbort[
        Quiet[
          FeynCalc`KiraCreateConfigFiles[
            topology,
            familyTargets,
            familyRoot,
            FeynCalc`KiraMassDimensions -> massDimensions,
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          FeynCalc`KiraCreateIntegralFile[
            Total[familyTargets],
            topology,
            familyRoot,
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          FeynCalc`KiraCreateJobFile[
            topology,
            familyTargets,
            familyRoot,
            FeynCalc`KiraIntegrals -> {"KiraLoopIntegrals"},
            OverwriteTarget -> True,
            FeynCalc`FCVerbose -> -1
          ];
          True
        ],
        False
      ] =!= True,
      ibpFail[
        "Kira configuration",
        "FeynHelpers could not export the topology"
      ]
    ];
    familyDirectory = FileNameJoin[{
      familyRoot,
      ToString[name, InputForm]
    }];
    ibpInsertCuts[
      FileNameJoin[{
        familyDirectory,
        "config",
        "integralfamilies.yaml"
      }],
      cutIndices
    ];
    <|
      "Name" -> name,
      "Directory" -> familyDirectory,
      "Targets" -> familyTargets,
      "CutIndices" -> cutIndices,
      "Ordinal" -> index
    |>,
    {index, Length[records]}
  ];

  If[
    ! DirectoryQ[FileNameJoin[{combinedDirectory, "config"}]],
    CreateDirectory[
      FileNameJoin[{combinedDirectory, "config"}],
      CreateIntermediateDirectories -> True
    ]
  ];
  familyBlocks = Flatten @ Table[
    Rest @ Import[
      FileNameJoin[{
        manifest[[index, "Directory"]],
        "config",
        "integralfamilies.yaml"
      }],
      "Lines"
    ],
    {index, Length[manifest]}
  ];
  Export[
    FileNameJoin[{
      combinedDirectory,
      "config",
      "integralfamilies.yaml"
    }],
    StringRiffle[Prepend[familyBlocks, "integralfamilies:"], "\n"] <>
      "\n",
    "String"
  ];
  kinematics = Import[
    FileNameJoin[{
      #["Directory"],
      "config",
      "kinematics.yaml"
    }],
    "Text"
  ] & /@ manifest;
  If[Length[DeleteDuplicates[kinematics]] =!= 1,
    ibpFail[
      "Kira configuration",
      "families generated different external kinematics"
    ]
  ];
  Export[
    FileNameJoin[{
      combinedDirectory,
      "config",
      "kinematics.yaml"
    }],
    First[kinematics],
    "String"
  ];

  reduceLines = Flatten @ Table[
    Select[
      Import[
        FileNameJoin[{manifest[[index, "Directory"]], "job.yaml"}],
        "Lines"
      ],
      StringStartsQ[StringTrim[#], "- {topologies:"] &
    ],
    {index, Length[manifest]}
  ];
  Do[
    CopyFile[
      FileNameJoin[{
        manifest[[index, "Directory"]],
        "KiraLoopIntegrals"
      }],
      FileNameJoin[{
        combinedDirectory,
        "integrals_" <> ToString[index]
      }],
      OverwriteTarget -> True
    ],
    {index, Length[manifest]}
  ];
  jobLines = Join[
    {"jobs:", "  - reduce_sectors:", "      reduce:"},
    reduceLines,
    {"      select_integrals:", "        select_mandatory_list:"},
    Table[
      "          - [" <>
        ToString[manifest[[index, "Name"]], InputForm] <>
        ", \"integrals_" <> ToString[index] <> "\"]",
      {index, Length[manifest]}
    ],
    {
      "      run_initiate: true",
      "      run_triangular: true",
      "      run_back_substitution: true",
      "      integral_ordering: 2",
      "  - kira2math:",
      "      target:"
    },
    Table[
      "        - [" <>
        ToString[manifest[[index, "Name"]], InputForm] <>
        ", \"integrals_" <> ToString[index] <> "\"]",
      {index, Length[manifest]}
    ]
  ];
  Export[
    FileNameJoin[{combinedDirectory, "jobs.yaml"}],
    StringRiffle[jobLines, "\n"] <> "\n",
    "String"
  ];

  Join[
    projectState,
    <|
      "ProjectRoot" -> projectState["Directory"],
      "Directory" -> combinedDirectory,
      "Manifest" -> manifest
    |>
  ]
];

ibpRunKira[project_Association] := Module[
  {
    directory, manifest, runtime, kira, fermat, parallel,
    process, log, logPath, unreduced, resultPaths
  },

  directory = project["Directory"];
  manifest = project["Manifest"];
  runtime = project["Runtime"];
  kira = runtime["KiraExecutable"];
  fermat = runtime["FermatExecutable"];
  parallel = Min[
    Max[1, $ProcessorCount],
    If[
      ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
      8
    ]
  ];
  logPath = FileNameJoin[{directory, "kira.log"}];
  resultPaths = Table[
    FileNameJoin[{
      directory,
      "results",
      ToString[manifest[[index, "Name"]], InputForm],
      "kira_integrals_" <> ToString[index] <> ".m"
    }],
    {index, Length[manifest]}
  ];
  If[
    TrueQ[project["ResumeEligible"]] &&
      AllTrue[resultPaths, FileExistsQ],
    Return[logPath]
  ];
  process = RunProcess[
    {kira, "--parallel=" <> ToString[parallel], "jobs.yaml"},
    All,
    ProcessDirectory -> directory,
    ProcessEnvironment -> <|"FERMATPATH" -> fermat|>
  ];
  log = StringJoin[
    Lookup[process, "StandardOutput", ""],
    Lookup[process, "StandardError", ""]
  ];
  Export[logPath, log, "String"];
  If[Lookup[process, "ExitCode", 1] =!= 0,
    ibpFail[
      "Kira reduction",
      "Kira exited with code " <>
        ToString[Lookup[process, "ExitCode", "unknown"]] <>
        "; see " <> logPath
    ]
  ];
  unreduced = FromDigits /@ StringCases[
    log,
    RegularExpression["unreduced integrals: ([0-9]+)"] -> "$1"
  ];
  If[
    Length[unreduced] < Length[manifest] ||
      ! AllTrue[unreduced, # === 0 &],
    ibpFail[
      "Kira reduction",
      "Kira did not report zero unreduced integrals for every family"
    ]
  ];
  logPath
];

ibpImportRules[project_Association, records_List] := Module[
  {directory, manifest, tables, imported, rules, path, dimension, cutCheck},
  directory = project["Directory"];
  manifest = project["Manifest"];
  dimension = Symbol["Global`d"] -> System`D;
  tables = Table[
    path = FileNameJoin[{
      directory,
      "results",
      ToString[manifest[[index, "Name"]], InputForm],
      "kira_integrals_" <> ToString[index] <> ".m"
    }];
    If[! FileExistsQ[path],
      ibpFail["Kira import", "missing reduction table " <> path]
    ];
    imported = Quiet @ CheckAbort[
      Check[
        FeynCalc`KiraImportResults[
          manifest[[index, "Name"]],
          path,
          FeynCalc`FCReplaceD -> {dimension},
          FeynCalc`FCVerbose -> -1
        ],
        $Failed
      ],
      $Failed
    ];
    If[
      imported === $Failed || ! ListQ[imported] ||
        ! AllTrue[imported, MatchQ[#, _Rule | _RuleDelayed] &] ||
        ! exactDataQ[imported],
      ibpFail[
        "Kira import",
        "the imported reduction table is not an exact list of rules: " <>
          path
      ]
    ];
    imported,
    {index, Length[manifest]}
  ];
  rules = DeleteDuplicates[Flatten[tables]];
  cutCheck = validateCutGLIs[rules, records];
  If[cutCheck =!= True,
    ibpFail[
      "Kira import",
      "the imported reduction pinches a cut or has invalid GLI arity: " <>
        ToString[Take[cutCheck, UpTo[3]], InputForm]
    ]
  ];
  rules
];

ibpDeclaredMasters[project_Association] := Module[
  {
    directory, manifest, nameMap, paths, lines, parseInteger, parseLine,
    masters
  },
  directory = project["Directory"];
  manifest = project["Manifest"];
  nameMap = Association[
    ToString[#1["Name"], InputForm] -> #1["Name"] & /@ manifest
  ];
  paths = FileNameJoin[{
      directory,
      "results",
      ToString[#1["Name"], InputForm],
      "masters.final"
    }] & /@ manifest;
  If[! AllTrue[paths, FileExistsQ],
    ibpFail["Kira master validation", "a masters.final file is missing"]
  ];
  parseInteger[text_String] := Module[{trimmed, sign},
    trimmed = StringTrim[text];
    If[! StringMatchQ[trimmed, RegularExpression["[+-]?[0-9]+"]],
      Return[$Failed]
    ];
    sign = If[StringStartsQ[trimmed, "-"], -1, 1];
    sign FromDigits[StringTrim[trimmed, "+" | "-"]]
  ];
  parseLine[line_String] := Module[
    {integral, pieces, name, indices},
    integral = StringTrim[First[StringSplit[line, "#"]]];
    pieces = StringSplit[integral, {"[", "]"}];
    If[Length[pieces] < 2 || ! KeyExistsQ[nameMap, First[pieces]],
      ibpFail[
        "Kira master validation",
        "cannot parse master integral " <> integral
      ]
    ];
    name = nameMap[First[pieces]];
    indices = parseInteger /@ StringSplit[pieces[[2]], ","];
    If[! MatchQ[indices, {___Integer}],
      ibpFail[
        "Kira master validation",
        "invalid master indices in " <> integral
      ]
    ];
    FeynCalc`GLI[name, indices]
  ];
  lines = Flatten[Select[Import[#1, "Lines"],
      StringTrim[#1] =!= "" &] & /@ paths];
  masters = DeleteDuplicates[parseLine /@ lines];
  masters
];

ibpCloseReductionRules[rules_List, targets_List] := Module[
  {
    groups, uniqueRules, leftSides, dispatch, current, next,
    converged = False, unresolved, closedRules, masters
  },
  groups = GatherBy[rules, First];
  If[
    ! AllTrue[
      groups,
      Length[DeleteDuplicates[Last /@ #1, SameQ]] === 1 &
    ],
    ibpFail[
      "Kira rule closure",
      "the imported tables contain conflicting rules for one integral"
    ]
  ];
  uniqueRules = First /@ groups;
  leftSides = First /@ uniqueRules;
  dispatch = Dispatch[uniqueRules];
  current = targets;
  Do[
    next = current /. dispatch;
    If[SameQ[next, current],
      converged = True;
      Break[]
    ];
    current = next,
    {Length[uniqueRules] + 2}
  ];
  unresolved = Intersection[
    DeleteDuplicates @ Cases[current, _FeynCalc`GLI, {0, Infinity}],
    leftSides,
    SameTest -> SameQ
  ];
  If[! converged || unresolved =!= {},
    ibpFail[
      "Kira rule closure",
      "the imported tables do not reduce transitively to terminal integrals"
    ]
  ];
  closedRules = Select[
    MapThread[Rule, {targets, current}],
    ! SameQ[First[#1], Last[#1]] &
  ];
  masters = DeleteDuplicates @ Cases[
    current,
    _FeynCalc`GLI,
    {0, Infinity}
  ];
  <|
    "Rules" -> closedRules,
    "Images" -> current,
    "Masters" -> masters
  |>
];

ibpValidateMasters[
    masters_List,
    declaredMasters_List,
    records_List
  ] := Module[{undeclared, cutCheck},
  undeclared = Complement[
    masters,
    declaredMasters,
    SameTest -> SameQ
  ];
  If[undeclared =!= {},
    ibpFail[
      "Kira master validation",
      ToString[Length[undeclared]] <>
        " terminal integrals are absent from Kira's declared master list; " <>
        "the exported rule set is not closed"
    ]
  ];
  cutCheck = validateCutGLIs[masters, records];
  If[cutCheck =!= True,
    ibpFail[
      "cut validation",
      "the reduction returned an invalid master or removed a required cut"
    ]
  ];
  True
];

ibpStructuralCommonFactor[expressions_List] := Module[
  {factorLists, shared, removeShared, common, reduced},
  If[expressions === {}, Return[{1, {}}]];
  factorLists = If[Head[#1] === Times, List @@ #1, {#1}] & /@
    expressions;
  shared = Fold[
    Function[{current, next},
      Select[
        current,
        Function[factor, AnyTrue[next, Function[item, SameQ[factor, item]]]]
      ]
    ],
    First[factorLists],
    Rest[factorLists]
  ];
  shared = DeleteDuplicates[shared, SameQ];
  removeShared[factors_List] := Fold[
    Function[{remaining, factor},
      With[{position = FirstPosition[remaining, factor]},
        If[MissingQ[position], remaining, Delete[remaining, position]]
      ]
    ],
    factors,
    shared
  ];
  common = Times @@ shared;
  reduced = Times @@ removeShared[#1] & /@ factorLists;
  {common, reduced}
];

exactCoefficientNormalize[expression_] := Module[
  {protected, atoms, forward, backward, rational, result},
  protected = protectedAnalyticObjects[expression];
  atoms = Unique["analytic$"] & /@ protected;
  forward = Dispatch[Thread[protected -> atoms]];
  backward = Dispatch[Thread[atoms -> protected]];
  rational = expression /. forward;
  rational = Cancel[Together[rational]];
  result = rational /. backward;
  If[
    (atoms =!= {} && ! FreeQ[result, Alternatives @@ atoms]) ||
      ! exactDataQ[result],
    $Failed,
    result
  ]
];

parallelNormalizeCoefficients[
    expressions_List
  ] := Module[
  {
    count, limit, existingKernels, launchedKernels,
    tasks, pending, nextResult, finishedTask, results, value,
    activeKernels, valid, completed, waitForTasks
  },

  count = Length[expressions];
  If[count === 0, Return[{{}, 0}]];
  If[count === 1,
    value = exactCoefficientNormalize[First[expressions]];
    Return[If[value === $Failed, $Failed, {{value}, 1}]]
  ];
  limit = Min[
    count,
    $ProcessorCount,
    If[
      ValueQ[Global`$FACETKernelLimit] &&
        IntegerQ[Global`$FACETKernelLimit] &&
        Global`$FACETKernelLimit > 0,
      Global`$FACETKernelLimit,
      $ProcessorCount
    ]
  ];
  existingKernels = Kernels[];
  launchedKernels = If[
    Length[existingKernels] < limit,
    LaunchKernels[limit - Length[existingKernels]],
    {}
  ];
  activeKernels = Min[count, Length[Kernels[]]];
  If[activeKernels === 0,
    Return[{
      exactCoefficientNormalize /@ expressions,
      1
    }]
  ];

  DistributeDefinitions[protectedAnalyticObjects, exactCoefficientNormalize];
  tasks = MapIndexed[
    Function[{expression, position}, With[
      {index = First[position], coefficient = expression},
      ParallelSubmit[{
        index,
        exactCoefficientNormalize[coefficient]
      }]
    ]],
    expressions
  ];
  pending = tasks;
  results = ConstantArray[Missing["Pending"], count];
  valid = True;
  completed = 0;
  waitForTasks[] := While[pending =!= {},
    {nextResult, finishedTask, pending} = WaitNext[pending];
    If[
      ! MatchQ[nextResult, {_Integer, _}] || FailureQ[Last[nextResult]],
      valid = False;
      Break[]
    ];
    results[[First[nextResult]]] = Last[nextResult];
    completed++
  ];
  value = CheckAbort[
    Quiet @ Check[
      If[
        TrueQ[$Notebooks],
        Monitor[
          waitForTasks[],
          Column[{
            ProgressIndicator[completed, {0, count}],
            Row[{completed, " / ", count, " master coefficients"}]
          }]
        ],
        waitForTasks[]
      ];
      If[valid, results, $Failed],
      $Failed
    ],
    If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
    Abort[]
  ];
  If[launchedKernels =!= {}, CloseKernels[launchedKernels]];
  If[
    value === $Failed || MemberQ[value, $Failed | $Aborted | _Missing],
    Return[$Failed]
  ];
  {value, activeKernels}
];

normalizeMasterCoefficients[
    parts_Association,
    label_String
  ] := Module[
  {
    coefficientAssociation, masters, coefficients, remainder,
    elapsed, simplified, simplifiedCoefficients, nonzero,
    expressionsForFactor, factorResult, commonPreFactor,
    normalizedExpressions, normalizedCoefficients,
    simplifiedRemainder, coefficientParts, localPreFactors,
    reducedCoefficients, reconstructed, kernelCount
  },
  coefficientAssociation = parts["Terms"];
  masters = Keys[coefficientAssociation];
  coefficients = Values[coefficientAssociation];
  remainder = Lookup[parts, "Remainder", 0];
  If[masters === {},
    simplifiedRemainder = exactCoefficientNormalize[remainder];
    If[simplifiedRemainder === $Failed,
      ibpFail[label, "remainder normalization failed"]
    ];
    Return[<|
      "PreFactor" -> 1,
      "Masters" -> {},
      "PreFactors" -> {},
      "Coefficients" -> {},
      "Remainder" -> simplifiedRemainder,
      "Expression" -> simplifiedRemainder
    |>]
  ];
  {elapsed, simplified} = AbsoluteTiming[
    parallelNormalizeCoefficients[coefficients]
  ];
  If[simplified === $Failed,
    ibpFail[label, "parallel coefficient simplification failed"]
  ];
  {simplifiedCoefficients, kernelCount} = simplified;
  nonzero = Flatten @ Position[
    simplifiedCoefficients,
    coefficient_ /; ! TrueQ[coefficient === 0],
    {1},
    Heads -> False
  ];
  masters = masters[[nonzero]];
  simplifiedCoefficients = simplifiedCoefficients[[nonzero]];
  simplifiedRemainder = exactCoefficientNormalize[remainder];
  If[simplifiedRemainder === $Failed,
    ibpFail[label, "remainder normalization failed"]
  ];
  expressionsForFactor = Join[
    simplifiedCoefficients,
    If[TrueQ[simplifiedRemainder === 0], {}, {simplifiedRemainder}]
  ];
  Print["Extracting overall factor"];
  factorResult = ibpStructuralCommonFactor[expressionsForFactor];
  commonPreFactor = First[factorResult];
  normalizedExpressions = Last[factorResult];
  normalizedCoefficients = Take[
    normalizedExpressions,
    Length[simplifiedCoefficients]
  ];
  simplifiedRemainder = If[
    TrueQ[simplifiedRemainder === 0],
    0,
    Last[normalizedExpressions]
  ];
  coefficientParts = CommonFactorSafe /@ normalizedCoefficients;
  localPreFactors = First /@ coefficientParts;
  reducedCoefficients = Last /@ coefficientParts;
  reconstructed =
    Total[MapThread[Times, {
      localPreFactors,
      reducedCoefficients,
      masters
    }]] + simplifiedRemainder;
  Print[
    label, ": ", Length[masters], " masters on ", kernelCount,
    " kernels in ", Round[elapsed, 0.01], " s"
  ];
  <|
    "PreFactor" -> commonPreFactor,
    "Masters" -> masters,
    "PreFactors" -> localPreFactors,
    "Coefficients" -> reducedCoefficients,
    "Remainder" -> simplifiedRemainder,
    "Expression" -> commonPreFactor reconstructed
  |>
];

ibpKiraReductionCore[data_Association] := Module[
  {
    records, equivalence, targets, representativeNames,
    representatives, completed, projectDirectory, projectState, project,
    runtime, payload, sourceFingerprint, logPath, importedRules, closure,
    declaredMasters, physicalRules, compactSize
  },
  records = data["Records"];
  If[records === {},
    equivalence = <|
      "Scope" -> "CutAwareIBP",
      "PhysicalCausalStatus" -> "NoTopologies",
      "SearchStatus" -> "Complete",
      "Representatives" -> {},
      "Classes" -> {},
      "Mappings" -> {},
      "GLIRules" -> {},
      "RejectedCandidateMappings" -> {}
    |>;
    payload = reductionInputPayload[
      {},
      {},
      {},
      <|"Status" -> "NotApplicable"|>
    ];
    sourceFingerprint = reductionFingerprint[
      sourceInputPayload[{}, {}, data["AnalyticContext"]]
    ];
    Return[Join[
      resultHeader["FeynFacet-KiraReduction", 2],
      resultContext[data],
      <|
      "Targets" -> {},
      "Masters" -> {},
      "DeclaredMasters" -> {},
      "KiraRules" -> {},
      "ReverseRules" -> {},
      "ReductionRules" -> {},
      "Topologies" -> {},
      "TopologyEquivalence" -> equivalence,
      "MassDimensions" -> {},
      "KiraManifest" -> {},
      "KiraProject" -> Missing["NotApplicable"],
      "KiraLog" -> Missing["NotApplicable"],
      "DimensionRule" -> $dimensionRule,
      "ReductionInputPayload" -> payload,
      "ReductionInputFingerprint" -> reductionFingerprint[payload],
      "SourceInputFingerprint" -> sourceFingerprint
      |>
    ]]
  ];

  equivalence = TopologyEquivalence[records];
  If[
    ! AssociationQ[equivalence] ||
      equivalence["PhysicalCausalStatus"] =!= "Verified",
    ibpFail["topology equivalence", "classification failed"]
  ];
  targets = DeleteDuplicates[
    data["RawTargets"] /. equivalence["GLIRules"],
    SameQ
  ];
  representativeNames = DeleteDuplicates[First /@ targets];
  representatives = Select[
    equivalence["Representatives"],
    MemberQ[representativeNames, #1["Topology"][[1]]] &
  ];
  If[targets === {} || representatives === {},
    ibpFail["target extraction", "the input contains no GLI targets"]
  ];
  completed = ibpCompleteKinematics[
    representatives,
    Lookup[
      data["AnalyticContext"],
      "KinematicMassDimensions",
      <||>
    ]
  ];
  runtime = ibpRuntime[];
  payload = reductionInputPayload[
    completed["KiraFamilies"],
    targets,
    completed["MassDimensions"],
    runtime
  ];
  projectDirectory = FileNameJoin[{data["ResultDirectory"], ".Kira"}];
  projectState = ibpResetProject[
    projectDirectory,
    data["ResultDirectory"],
    payload,
    runtime
  ];
  project = ibpPrepareKiraProject[
    completed["KiraFamilies"],
    targets,
    projectState,
    completed["MassDimensions"]
  ];
  Print["Running Kira"];
  logPath = ibpRunKira[project];
  Print["Importing Kira rules"];
  importedRules = ibpImportRules[project, completed["PhysicalRecords"]];
  closure = ibpCloseReductionRules[importedRules, targets];
  If[validateCutGLIs[closure["Images"], completed["PhysicalRecords"]] =!= True,
    ibpFail["Kira rule closure", "a closed reduction image removes a cut"]
  ];
  declaredMasters = ibpDeclaredMasters[project];
  ibpValidateMasters[
    closure["Masters"],
    declaredMasters,
    completed["PhysicalRecords"]
  ];
  physicalRules = closure["Rules"] /. completed["ReverseRules"];
  physicalRules = physicalRules /. $dimensionRule;
  compactSize = ByteCount[{
    closure["Rules"],
    physicalRules,
    closure["Masters"],
    completed["PhysicalRecords"]
  }];
  sourceFingerprint = reductionFingerprint[
    sourceInputPayload[
      records,
      data["RawTargets"],
      data["AnalyticContext"]
    ]
  ];
  Print @ Grid[
    {
      {"Input integrals", Length[targets]},
      {"Master integrals", Length[closure["Masters"]]},
      {"Reduction data size (kB)", Round[compactSize/1024., 0.01]}
    },
    Frame -> All
  ];
  Join[
    resultHeader["FeynFacet-KiraReduction", 2],
    resultContext[data],
    <|
    "Targets" -> targets,
    "Masters" -> closure["Masters"],
    "DeclaredMasters" -> declaredMasters,
    "KiraRules" -> closure["Rules"],
    "ReverseRules" -> completed["ReverseRules"],
    "ReductionRules" -> physicalRules,
    "Topologies" -> completed["PhysicalRecords"],
    "TopologyEquivalence" -> equivalence,
    "MassDimensions" -> completed["MassDimensions"],
    "KiraManifest" -> project["Manifest"],
    "KiraProject" -> project["Directory"],
    "KiraLog" -> logPath,
    "DimensionRule" -> $dimensionRule,
    "ReductionInputPayload" -> payload,
    "ReductionInputFingerprint" -> project["InputFingerprint"],
    "SourceInputFingerprint" -> sourceFingerprint
    |>
  ]
];

KiraReduction[inputs : ({__String} | {__Association})] := Catch[
  Module[{data},
    data = ibpInputData[inputs, True];
    ibpKiraReductionCore[data]
  ],
  $ibpFailure
];


coefficientSimplificationCore[inputs_List, kira_Association] := Catch[
  Module[
    {
      data, sortedPairs, equivalence, targetParts, addSource,
      targets, reductionDispatch, physicalParts, unexpectedMasters,
      coefficientResult, commonPreFactor, masters,
      coefficientPreFactors, reducedCoefficients, recordByName,
      classByName, masterData, reconstructed, compactSize,
      sourceFingerprint, cutCheck
    },
    If[
      Lookup[kira, "Format", None] =!= "FeynFacet-KiraReduction" ||
        Lookup[kira, "FormatVersion", None] =!= 2,
      Message[CoefficientSimplification::input];
      Throw[$Failed, $ibpFailure]
    ];
    data = ibpInputData[inputs, True];
    sourceFingerprint = reductionFingerprint[
      sourceInputPayload[
        data["Records"],
        data["RawTargets"],
        data["AnalyticContext"]
      ]
    ];
    If[
      sourceFingerprint =!=
        Lookup[kira, "SourceInputFingerprint", Missing["NotAvailable"]],
      ibpFail[
        "coefficient input validation",
        "the topology records or GLI targets differ from the Kira input"
      ]
    ];
    sortedPairs[list_List] := SortBy[
      list,
      {Lookup[#1, "Forward"], Lookup[#1, "Conjugate"]} &
    ];
    If[
      data["CardName"] =!= kira["CardName"] ||
        data["ResultDirectory"] =!= kira["ResultDirectory"] ||
        sortedPairs[data["Pairs"]] =!= sortedPairs[kira["Pairs"]],
      ibpFail[
        "coefficient input validation",
        "the Kira reduction does not belong to this result set"
      ]
    ];
    equivalence = kira["TopologyEquivalence"];
    Print["Collecting target coefficients"];
    addSource[parts_, source_] := Module[{result, sourceParts},
      result = If[StringQ[source], Quiet @ Check[Get[source], $Failed], source];
      If[! validPreIBPResultQ[result],
        ibpFail["target coefficient collection", "could not read a pre-IBP result"]
      ];
      sourceParts = linearIntegralSum[
        result["PreFactor"] result["Integrand"]
      ];
      If[FailureQ[sourceParts],
        ibpFail[
          "target coefficient collection",
          "a pre-IBP expression is not linear in explicit GLI objects"
        ]
      ];
      If[AssociationQ[equivalence] && KeyExistsQ[equivalence, "GLIRules"],
        sourceParts = linearMapIntegrals[
          sourceParts,
          equivalence["GLIRules"]
        ];
        If[FailureQ[sourceParts],
          ibpFail[
            "target coefficient collection",
            "a verified topology rule did not return a linear GLI sum"
          ]
        ]
      ];
      result = linearAdd[{parts, sourceParts}];
      If[FailureQ[result],
        ibpFail[
          "target coefficient collection",
          "the sparse integral sums could not be merged"
        ]
      ];
      result
    ];
    targetParts = Fold[
      addSource,
      <|"Terms" -> <||>, "Remainder" -> 0|>,
      data["Sources"]
    ];
    targets = Keys[targetParts["Terms"]];
    If[
      Complement[targets, kira["Targets"], SameTest -> SameQ] =!= {} ||
        Complement[kira["Targets"], targets, SameTest -> SameQ] =!= {},
      ibpFail[
        "target coefficient collection",
        "the collected targets differ from the targets reduced by Kira"
      ]
    ];
    Print["Applying Kira rules"];
    reductionDispatch = Dispatch[kira["KiraRules"]];
    Print["Restoring physical kinematics"];
    Print["Collecting master coefficients"];
    physicalParts = linearApplyReduction[
      targetParts,
      reductionDispatch,
      kira["ReverseRules"]
    ];
    If[FailureQ[physicalParts],
      ibpFail[
        "Kira rule application",
        "the reduction did not produce a linear master-integral sum"
      ]
    ];
    physicalParts = linearMapCoefficients[
      physicalParts,
      Function[coefficient, coefficient /. $dimensionRule]
    ];
    If[
      ! FreeQ[
        {Values[physicalParts["Terms"]], physicalParts["Remainder"]},
        System`D
      ],
      ibpFail[
        "dimension convention",
        "the reduced coefficients still contain an independent D"
      ]
    ];
    unexpectedMasters = Complement[
      Keys[physicalParts["Terms"]],
      kira["Masters"],
      SameTest -> SameQ
    ];
    If[unexpectedMasters =!= {},
      ibpFail[
        "master coefficient collection",
        "the reduction produced a master outside the validated Kira set"
      ]
    ];
    cutCheck = validateCutGLIs[
      Keys[physicalParts["Terms"]],
      kira["Topologies"]
    ];
    If[cutCheck =!= True,
      ibpFail[
        "master coefficient collection",
        "a final master removes a required cut or has invalid arity"
      ]
    ];

    Print["Simplifying master coefficients"];
    coefficientResult = normalizeMasterCoefficients[
      physicalParts,
      "Master coefficients"
    ];
    commonPreFactor = coefficientResult["PreFactor"];
    masters = coefficientResult["Masters"];
    coefficientPreFactors = coefficientResult["PreFactors"];
    reducedCoefficients = coefficientResult["Coefficients"];
    recordByName = Association[
      #1["Topology"][[1]] -> #1 & /@ kira["Topologies"]
    ];
    classByName = If[
      AssociationQ[equivalence] && KeyExistsQ[equivalence, "Classes"],
      Association[
        #1["Representative"] -> #1 & /@ equivalence["Classes"]
      ],
      <||>
    ];
    masterData = MapThread[
      Function[{master, coefficientPreFactor, coefficient},
        With[{record = recordByName[master[[1]]]},
          <|
            "Master" -> master,
            "PreFactor" -> coefficientPreFactor,
            "Coefficient" -> coefficient,
            "TopologyName" -> master[[1]],
            "CutMomenta" -> record["CutMomenta"],
            "CutIndices" -> record["CutIndices"],
            "CutDirections" -> record["CutDirections"],
            "PropagatorData" -> record["PropagatorData"],
            "ExternalPropagatorData" -> record["ExternalPropagatorData"],
            "PhysicalSignature" ->
              (topologyPhysicalSignature /@ record["PropagatorData"]),
            "AMFlowInfo" -> record["AMFlowInfo"],
            "TopologyClass" -> Lookup[
              classByName,
              master[[1]],
              Missing["NotFound"]
            ]
          |>
        ]
      ],
      {masters, coefficientPreFactors, reducedCoefficients}
    ];
    reconstructed = commonPreFactor (
      Total[
        #1["PreFactor"] #1["Coefficient"] #1["Master"] & /@
          masterData
      ] + coefficientResult["Remainder"]
    );
    If[! TrueQ[Expand[coefficientResult["Expression"] - reconstructed] === 0],
      ibpFail[
        "master coefficient extraction",
        "the stored factors do not reconstruct the simplified expression"
      ]
    ];
    If[
      ! exactDataQ @ HoldComplete[
        commonPreFactor, coefficientResult["Remainder"], reconstructed,
        masterData, kira["ReductionRules"], equivalence
      ],
      ibpFail[
        "result validation",
        "the analytic IBP result contains inexact numerical data"
      ]
    ];
    compactSize = ByteCount[{
      commonPreFactor,
      coefficientResult["Remainder"],
      masterData,
      kira["ReductionRules"],
      equivalence
    }];
    Print @ Grid[
      {
        {"Pairs", Length[inputs]},
        {"Topology classes", Length[kira["Topologies"]]},
        {"Input integrals", Length[kira["Targets"]]},
        {"Master integrals", Length[masters]},
        {"Compact result size (kB)", Round[compactSize/1024., 0.01]}
      },
      Frame -> All
    ];
    Join[
      resultHeader["FeynFacet-IBP", 4],
      resultContext[data],
      <|
      "FractionMeasure" -> data["FractionMeasure"],
      "PhaseSpace" -> data["PhaseSpace"],
      "PreFactor" -> commonPreFactor,
      "Remainder" -> coefficientResult["Remainder"],
      "Expression" -> reconstructed,
      "Masters" -> masterData,
      "Topologies" -> kira["Topologies"],
      "ReductionRules" -> kira["ReductionRules"],
      "TopologyEquivalence" -> equivalence,
      "Assumptions" -> data["AnalyticContext", "Assumptions"],
      "AnalyticContext" -> data["AnalyticContext"],
      "MassDimensions" -> kira["MassDimensions"],
      "KiraManifest" -> kira["KiraManifest"],
      "KiraProject" -> kira["KiraProject"],
      "KiraLog" -> kira["KiraLog"],
      "DimensionRule" -> $dimensionRule,
      "ReductionInputFingerprint" -> kira["ReductionInputFingerprint"],
      "SourceInputFingerprint" -> kira["SourceInputFingerprint"]
      |>
    ]
  ],
  $ibpFailure
];

CoefficientSimplification[
    inputs : ({__Association} | {__String}),
    kira_Association
  ] := coefficientSimplificationCore[inputs, kira];

IBP[inputs : ({__Association} | {__String})] := Module[{reduction},
  reduction = KiraReduction[inputs];
  If[reduction === $Failed,
    $Failed,
    CoefficientSimplification[inputs, reduction]
  ]
];

KiraReduction[___] := (
  Message[KiraReduction::input];
  $Failed
);

CoefficientSimplification[___] := (
  Message[CoefficientSimplification::input];
  $Failed
);

IBP[___] := (
  Message[IBP::input];
  $Failed
);

## Follow-up question

The immediately preceding full-source review turn was accepted but ended without an assistant message. Do not repeat the earlier review from scratch. Review the current implementation using the modular source already present in this conversation and this exact delta/status report.

All ten P0 findings from your previous review are implemented and regression-tested: fail-closed causal schema; enforced BMHV and consistent analytic contexts; BaseGLI/FamilyCoefficient provenance; exact cut denominator cores; loop-free dimensional-shift coefficients plus SPE[k]; validated Kira import/closure/masters and cut survival; separate physical records versus Kira families; explicit invariant dimensions; rejection of inexact scientific data; and a complete zero-topology LO reduction artifact.

All generic exact/sparse utilities moved to Core, topology slot lookup moved to Topologies, safeTopologyRecordQ was removed, ProcessEnvironment and WXF cache fingerprints are used, generated symbols use Symbol rather than ToExpression, sparse ordering is deterministic, BuildGlobalBasis is transactional, denominator splitting uses FeynAmpDenominatorSplit, and remainder normalization is checked. The old manual commonFactorMultiset was just replaced by Counts + KeyIntersection + Merge and matched the old algorithm in 500 randomized exact cases. Duplicate SourceTopology/MappedProbeGLI mapping fields and one genuinely unused helper were removed. The supported SimplifyAssum[expr, processCard] overload was retained because its compatibility regression proves it is used.

The source is organized as a thin FeynFacet.m facade plus Distributions.wl and six private modules: Core, Process, Topologies, DimensionalShift, Collinear, Reduction. A static dependency audit finds no references to symbols defined only in later-loaded modules. Large files now have subsystem boundaries; I intentionally did not split coherent topology-record or reduction-artifact state merely by line count.

All 16 current tests pass. They include causal/branch safety, two-loop partial fractions, one/two-loop dimensional shifts, LO end-to-end, strict persisted-artifact contracts, 500 common-factor property cases, topology-equivalence adversarial stress with 800 random GLI applications, and a fresh physical UU F1/C2 run through FeynArts/FeynCalc/Kira/master reconstruction. The latter reduces 16 targets to one cut master in about 12 seconds and passes exactness, cut survival, metadata, BMHV-context, and no-independent-D checks.

Please give a final concise review now. State explicitly whether any P0 correctness defect remains. Then list only concrete P1/P2 deletions or unifications that reduce code without weakening the physical contracts, citing file/function. Assess whether the current module boundaries should be retained. Do not propose a wholesale rewrite or numerical substitute.

## Pro response

P0

No P0 correctness defect remains that I can identify in the supported FACET pipeline. The current implementation fails closed at the relevant trust boundaries and the real FeynArts/FeynCalc/Kira regression materially strengthens that conclusion.

The remaining work is code consolidation and maintainability. None of the changes below should alter the scientific output.

P1 — worthwhile code reductions
1. Use BaseGLI, FamilyCoefficient, and stored CutIndices directly in the internal dimensional-shift path

Files/functions: Private/DimensionalShift.wl, DimensionalShift; Private/Topologies.wl, BuildTopologies

The complete topology records already contain the information that DimensionalShift rediscovers through:

Wolfram Language
FCLoopToGLI
FCLoopCreateRuleGLIToGLI
topologyPropagatorIndex /@ cutMomenta

Introduce one private kernel:

Wolfram Language
dimensionalShiftRecord[
    integrand_,
    family_Association,
    loopMomenta_List
  ] := dimensionalShiftKernel[
    integrand family["FamilyCoefficient"],
    family["BaseGLI"],
    family["Topology"],
    family["CutIndices"],
    loopMomenta
  ];

Move the common BMHV/Tarasov body into dimensionalShiftKernel. Then:

Wolfram Language
DimensionalShift[
    integrand_,
    families : {__Association},
    loopMomenta_List
  ] := ...

calls dimensionalShiftRecord.

Retain the public four-argument overload by constructing a temporary family through the existing conversion checks and then calling the same kernel. This removes the largest remaining repeated exact-topology work without changing the public API.

Regression gate: the legacy four-argument and topology-record paths must return SameQ sparse GLI sums for every one- and two-loop dimensional-shift fixture.

2. Centralize analytic-context validation

Files/functions:

Private/Process.wl, analyticContext

Private/Topologies.wl, topologyRecordQ

Private/Reduction.wl, validPreIBPResultQ

Private/Collinear.wl, GenerateCollinearFactorizePreIBPResult

The BMHV, source-hash, dimension-rule, and fingerprint checks are currently reproduced at multiple persistence boundaries.

Add to Core.wl:

Wolfram Language
analyticContextQ[context_] := TrueQ @ Quiet @ Check[
  AssociationQ[context] &&
    ContainsAll[
      Keys[context],
      {
        "Gamma5Scheme",
        "GlobalBasis",
        "GlobalBasisGram",
        "SetEvanescentZero",
        "SetMassZero",
        "SetDistributionZero",
        "CollinearRelations",
        "Assumptions",
        "KinematicMassDimensions",
        "LoopDimension",
        "DimensionRule",
        "CutConvention",
        "DistributionConvention",
        "FeynFacetSourceHash",
        "Fingerprint"
      }
    ] &&
    context["Gamma5Scheme"] === "BMHV" &&
    context["DimensionRule"] === $dimensionRule &&
    context["FeynFacetSourceHash"] === $feynFacetSourceHash &&
    context["Fingerprint"] ===
      reductionFingerprint[KeyDrop[context, "Fingerprint"]] &&
    exactDataQ[context],
  False
];

Use this predicate everywhere. Retain the separate equality check that every topology record carries the same context as its enclosing artifact.

3. Share the protected-analytic atomization machinery

Files/functions:

Private/Core.wl, CommonFactorSafe

Private/Reduction.wl, exactCoefficientNormalize

Both functions independently construct protected objects, replacement atoms, and restoration rules.

Add to Core.wl:

Wolfram Language
atomizeProtectedAnalyticObjects[expression_] := Module[
  {objects, atoms},

  objects = protectedAnalyticObjects[expression];
  atoms = Table[Unique["analytic$"], Length[objects]];

  <|
    "Expression" ->
      expression /. Dispatch[Thread[objects -> atoms]],
    "RestoreRules" ->
      Dispatch[Thread[atoms -> objects]],
    "Atoms" -> atoms
  |>
];

Then both callers use the same atomization contract. This removes duplicated logic and ensures branch/distribution protection cannot drift between common-factor extraction and coefficient normalization.

4. Share factor-multiset operations between amplitude splitting and final coefficient factoring

Files/functions:

Private/Collinear.wl, topLevelFactors, commonFactorMultiset, removeFactorOnce, splitAmplitude

Private/Reduction.wl, ibpStructuralCommonFactor

Move the generic factor operations to Core.wl:

Wolfram Language
factorList[expression_] :=
  If[Head[expression] === Times, List @@ expression, {expression}];

commonFactorMultiset[lists : {__List}] := Module[
  {counts},

  counts = KeyIntersection[Counts /@ lists];

  Flatten @ KeyValueMap[
    ConstantArray[#1, #2] &,
    Merge[counts, Min]
  ]
];

removeFactorMultiset[list_List, factors_List] := Fold[
  DeleteCases[#1, #2, {1}, 1] &,
  list,
  factors
];

structuralCommonFactor[expressions_List] := Module[
  {lists, common},

  If[expressions === {}, Return[{1, {}}]];

  lists = factorList /@ expressions;
  common = commonFactorMultiset[lists];

  {
    Times @@ common,
    Times @@ removeFactorMultiset[#, common] & /@ lists
  }
];

Use factorList and removeFactorMultiset in splitAmplitude, and replace ibpStructuralCommonFactor with structuralCommonFactor.

This preserves the required overall factor and per-master local factors.

5. Compute cut descriptors once per PartialFraction call

File/functions: Private/Topologies.wl, PartialFraction, cutOrdinaryCoreCollision, restoreCutTerm

cutDescriptors[cutRecords] is recomputed for every partial-fraction term, while the cut set is invariant.

Refactor:

Wolfram Language
PartialFraction[...] := Module[
  {cutRecords, descriptors, collision, algebraic, reduced, result},

  cutRecords = cutData[expr];
  If[cutRecords === $Failed, Return[$Failed]];

  descriptors = cutDescriptors[cutRecords];
  If[
    descriptors === $Failed ||
      MemberQ[descriptors, $Failed],
    Return[$Failed]
  ];

  collision =
    cutOrdinaryCoreCollision[expr, descriptors];

  ...

  result =
    restoreCutTerm[#, cutRecords, descriptors] & /@
      termList[reduced];
]

Change the two helper signatures to accept the prepared descriptors. This removes repeated denominator parsing and exact-core construction.

6. Normalize the process once in the private pre-IBP orchestration

Files/functions:

Private/Process.wl, GenerateDiagram, normalizeAmplitudeSelection, prepareProcess

Private/Collinear.wl, factorizePair, CollinearFactorizePreIBP

The public functions appropriately validate their own raw inputs, but CollinearFactorizePreIBP currently performs overlapping validation through GenerateDiagram and factorizePair.

Use private normalized entry points:

Wolfram Language
generateDiagramsForProcess[
  process_Association,
  config_Association
] := ...

factorizePreparedProcess[
  process_Association
] := ...

The private pipeline becomes:

Wolfram Language
process = normalizeProcess[config];
diagrams = generateDiagramsForProcess[process, config];
process = prepareProcess[process, diagrams];
factorized = factorizePreparedProcess[process];

The public GenerateDiagram and CollinearFactorize remain compatibility wrappers that normalize independently.

After the first amplitude-side validation, the post-generation check only needs to verify that requested indices are within the generated list. It need not rerun the full amplitude schema validator.

7. Unify complete-topology validation

Files/functions:

Private/Topologies.wl, BuildTopologies, topologyRecordQ

Private/DimensionalShift.wl, DimensionalShift

Private/Reduction.wl, ibpCompleteKinematics

Add in Topologies.wl:

Wolfram Language
completeTopologyQ[topology_FeynCalc`FCTopology] :=
  Quiet @ CheckAbort[
    {
      FeynCalc`FCLoopValidTopologyQ[topology],
      FeynCalc`FCLoopBasisIncompleteQ[topology],
      FeynCalc`FCLoopBasisOverdeterminedQ[topology]
    } === {True, False, False},
    False
  ];

completeTopologyQ[_] := False;

Use it wherever the same three checks currently appear. The augmented Kira topology can also use this predicate unless there is a deliberate reason to permit an overdetermined export family.

8. Centralize artifact header checks

Files/functions:

Private/Reduction.wl, validPreIBPResultQ, coefficientSimplificationCore

artifact constructors in Private/Collinear.wl and Private/Reduction.wl

Add in Core.wl:

Wolfram Language
artifactHeaderQ[
    artifact_,
    format_String,
    version_Integer
  ] :=
  AssociationQ[artifact] &&
    Lookup[
      artifact,
      {"Format", "FormatVersion"},
      {Missing["Format"], Missing["FormatVersion"]}
    ] === {format, version};

Use it for pre-IBP and Kira artifacts. Schema-specific scientific validation remains in the corresponding validator.

A kiraReductionQ predicate would also let CoefficientSimplification fail with one controlled message rather than relying on subsequent association indexing. It should verify required keys, payload/fingerprint consistency, exactness, and validated topology records.

P2 — smaller cleanups
1. Move lightQuarkMassRules to Private/Collinear.wl

It is defined in Process.wl but used only during amplitude conversion in Collinear.wl. Moving it makes module ownership exact without changing behavior.

2. Collapse the four correlator implementations

File: Distributions.wl

The four public functions differ only by the distribution triplet and helicity sign. A private constructor removes repeated Dirac structure:

Wolfram Language
twist2Correlator[
    x_, lambda_, ST_, n_,
    {unpolarized_, helicity_, transversity_},
    helicitySign_
  ] :=
  1/2 (
    unpolarized[x] FeynCalc`GS[n] +
    helicitySign lambda helicity[x]
      FeynCalc`GA[5] . FeynCalc`GS[n] +
    transversity[x]
      iSigmaSlash[n, ST] . FeynCalc`GA[5]
  );

The public wrappers retain their current signatures and DeclareScalar calls.

Regression gate: each old and new correlator expression must be SameQ after FCI.

3. Group candidate topology mappings once

Function: TopologyEquivalence

Replace repeated:

Wolfram Language
sourceMaps = Select[
  parsedMappings,
  #["Target"] === targetName &
];

with:

Wolfram Language
mappingsByTarget = GroupBy[
  parsedMappings,
  #["Target"] &
];

sourceMaps = Lookup[
  mappingsByTarget,
  targetName,
  {}
];

This reduces repeated scans and simplifies the nested class loop.

4. Remove single-use wrappers where they no longer aid testing

Candidates:

convertAmplitudePair

coefficientSimplificationCore

convertAmplitudePair can be replaced by its one-line AssociationMap at the call site. coefficientSimplificationCore can become the main definition of CoefficientSimplification if no private test calls it directly.

Retain wrappers that represent genuine public/private trust boundaries.

5. Replace mutable kinematic-rule construction

Function: ibpCompleteKinematics

The counter plus AppendTo construction can become:

Wolfram Language
missingPairs = Select[
  pairs,
  With[
    {lhs = FeynCalc`FCI[FeynCalc`SPD[#[[1]], #[[2]]]]},
    SameQ[lhs /. baseRules, lhs]
  ] &
];

generated = MapIndexed[
  Function[{pair, position},
    Module[{lhs, invariant, rhs, reverse},

      lhs = FeynCalc`FCI[
        FeynCalc`SPD[pair[[1]], pair[[2]]]
      ];
      invariant = Symbol[
        symbolPrefix <> ToString[First[position]]
      ];

      rhs = If[
        SameQ[pair[[1]], pair[[2]]],
        invariant,
        invariant/2
      ];

      reverse = invariant -> If[
        SameQ[pair[[1]], pair[[2]]],
        FeynCalc`SPD[pair[[1]]],
        2 FeynCalc`SPD[pair[[1]], pair[[2]]]
      ];

      {lhs -> rhs, reverse}
    ]
  ],
  missingPairs
];

generatedRules = generated[[All, 1]];
reverseRules = generated[[All, 2]];

Keep the existing generated-symbol collision check.

6. Consolidate summary printing

The repeated Print @ Grid[...] blocks can use one private helper:

Wolfram Language
printSummary[headers_List, rows_List] :=
  Print @ Grid[
    Prepend[rows, headers],
    Frame -> All
  ];

This is cosmetic but removes repeated formatting code from mathematical routines.

Module boundaries and artifact schemas

Retain the current module boundaries. They now correspond to genuine ownership and dependency layers:

Core
├── Process
├── Topologies
│   └── DimensionalShift
└── Collinear
    └── Reduction

The remaining ownership adjustments are small: move lightQuarkMassRules into Collinear.wl, move shared factor machinery into Core.wl, and centralize context/artifact predicates there.

The durable artifact schemas are coherent:

pre-IBP artifact version 2 carries the complete analytic context and physical topology records;

Kira reduction version 2 distinguishes physical records from export-only algebraic families and binds the result to source/runtime fingerprints;

final IBP version 4 preserves overall and local factors, cut/master metadata, BMHV context, and dimension convention.

There is no justification for recombining the files or splitting the coherent topology-record and reduction-artifact modules further.
