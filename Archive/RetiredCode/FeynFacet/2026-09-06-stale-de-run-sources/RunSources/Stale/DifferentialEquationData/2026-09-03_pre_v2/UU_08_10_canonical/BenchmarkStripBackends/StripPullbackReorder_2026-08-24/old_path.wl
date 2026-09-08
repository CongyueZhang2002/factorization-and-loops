(* OLD (HEAD 1833bf4) strip-pullback code path, kept callable OUTSIDE the
   package for the exact-equivalence comparison of the 2026-08-24
   reordering.  Nothing here is loaded by FeynFacet; the package keeps no
   copy of the old ordering. *)

Begin["FeynFacet`Private`"];

oldTransportChartPullBackStrip[strip : {e_List, c_List, bbar_List},
    data_Association] := Module[{pull},
  pull[pair_] := Module[{components},
    components = Map[
      Map[Together, # /. data["Subst"], {2}] &, pair];
    masterTransportPullBackOneForm[
      components[[1]], components[[2]], data["Jacobian"]]
  ];
  pull /@ {e, c, bbar}
];

oldSolveEpsFormStripInFrame[
    strip : {e_List, c_List, bbar_List},
    variables : {_Symbol, _Symbol}, epsilon_Symbol,
    frame_Association, opts : OptionsPattern[]] := Module[
  {allRoots, classification, rootIndices, usedRoots, rootSquares, chart,
   chartVariables, rekeyed, data, chartStrip, inner, chartGauge,
   identityData, coordinateMap, sourceGauge, chartRoots, rootImages,
   chartBranchRoots,
   signChoices, acceptedSigns, branchImages, branchedGauge,
   sourceTransformed, chartTransformed, pulledTransformed,
   sourceAlphabet, zeroMatrixQ, pullPair, optionRules,
   finiteFieldQ, finiteFieldFirstQ, finiteFieldOptions, canonicalKernelCount,
   scratchDirectory, stripTag, verbose, solveRationalStrip, innerSolvedQ,
   multiquadraticOptions, multiquadraticResult, multiquadraticStatus},

  allRoots = transportChartCurrentRoots[frame, variables];
  If[allRoots === $Failed,
    Return[<|"Status" -> "AlgebraicFrameNotWellFormed"|>]];
  classification = transportChartRootIndices[strip, allRoots];
  If[classification["UnclassifiedRadicalBases"] =!= {},
    Return[<|"Status" -> "StripContainsUndeclaredRadicals",
      "RadicalBases" -> classification["UnclassifiedRadicalBases"]|>]];
  (* 2026-08-24: the classifier now also accepts nested and numeric
     radicands by exact denesting.  Everything downstream of this solver
     -- CANONICA/Libra, the finite-field sampler, the multiquadratic
     grade engine -- works over a RATIONAL chart, and neither a numeric
     radical constant nor a rewritten nested radical has been carried
     through it.  The strip therefore still STOPS here, now with the
     denesting recorded, instead of proceeding on an untested path. *)
  If[Lookup[classification, "DenestedRadicalBases", <||>] =!= <||>,
    Return[<|"Status" -> "StripContainsDenestedRadicals",
      "RadicalBases" -> Keys[classification["DenestedRadicalBases"]],
      "NumericRadicalClasses" ->
        Lookup[classification, "NumericRadicalClasses", {}]|>]];
  rootIndices = classification["RootIndices"];
  usedRoots = allRoots[[rootIndices]];
  rootSquares = Lookup[usedRoots, "RootSquare", {}];
  (* dD = eps (e.D-D.c)+bbar is solved identically by D=0 when the
     forcing vanishes.  This must precede chart selection: the diagonal
     blocks may span a root set with no joint rational chart even though
     this off-diagonal problem needs no field arithmetic at all. *)
  If[AllTrue[Flatten[bbar], SameQ[#, 0] &],
    Return[<|"Status" -> "Solved", "Method" -> "ZeroForcing",
      "Gauge" -> ConstantArray[0, Dimensions[bbar[[1]]]],
      "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
      "Chart" -> None, "Alphabet" -> {}, "ExactDLog" -> True,
      "Certificate" -> "ExactDLog", "FrameCertificate" -> <|
        "Chart" -> None, "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True, "SourceDLog" -> True,
        "SamplingEntered" -> False, "Exact" -> True|>|>]];
  optionRules = FilterRules[{opts}, Options[SolveEpsFormStrip]];
  finiteFieldQ = TrueQ[OptionValue["FiniteFieldFallback"]] ||
    TrueQ[OptionValue["FiniteFieldFirst"]];
  finiteFieldFirstQ = TrueQ[OptionValue["FiniteFieldFirst"]];
  finiteFieldOptions = OptionValue["FiniteFieldOptions"];
  If[! MatchQ[finiteFieldOptions, {___Rule}],
    Return[<|"Status" -> "InvalidFiniteFieldOptions"|>]];
  canonicalKernelCount = OptionValue["CANONICAKernels"];
  scratchDirectory = OptionValue["ScratchDirectory"];
  stripTag = OptionValue["Tag"];
  verbose = OptionValue["Verbose"];
  (* a solved inner strip: exact dlog, or (production check level) the
     finite-field solve's numerical certificate, whose exact statement is
     deferred to the family certificate (2026-08-23) *)
  innerSolvedQ[candidate_] := AssociationQ[candidate] &&
    Lookup[candidate, "Status", None] === "Solved" &&
    (TrueQ[Lookup[candidate, "ExactDLog", False]] ||
      Lookup[candidate, "Certificate", None] === "NumericalResidual");
  solveRationalStrip = Function[{rationalStrip, rationalVariables},
    Module[{candidate, directory, defaults, finiteOptions},
      (* "FiniteFieldFirst" -> True: no CANONICA/Maple ladder in the
         production loop (user decision 2026-08-22); the finite field
         solves the strip in the targeted chart directly *)
      candidate = If[finiteFieldFirstQ, $Failed,
        SolveEpsFormStrip[
          rationalStrip, rationalVariables, epsilon,
          Sequence @@ optionRules]];
      If[finiteFieldQ && ! innerSolvedQ[candidate],
        directory = Replace[scratchDirectory, {
          Automatic :> FileNameJoin[{$TemporaryDirectory,
            "FeynFacetFiniteField", stripTag}],
          value_String :> FileNameJoin[{value,
            stripTag <> "_finite_field"}]
        }];
        defaults = {
          "KernelCount" -> canonicalKernelCount,
          "ArtifactDirectory" -> directory,
          "ArtifactPrefix" -> stripTag,
          "Verbose" -> verbose
        };
        finiteOptions = DeleteDuplicatesBy[
          Join[FilterRules[finiteFieldOptions,
            Options[SolveEpsFormStripFiniteField]], defaults], First];
        candidate = SolveEpsFormStripFiniteField[
          <|"Strip" -> rationalStrip, "Variables" -> rationalVariables,
            "Regulator" -> epsilon|>, Sequence @@ finiteOptions];
      ];
      candidate
    ]
  ];

  If[rootIndices === {},
    inner = solveRationalStrip[strip, variables];
    If[! innerSolvedQ[inner], Return[inner]];
    Return[Join[inner, <|"Method" -> "RationalFrame/" <> inner["Method"],
      "RootIndices" -> {}, "FrameCertificate" -> <|
        "Chart" -> None, "GaugeRoundTrip" -> True,
        "TransformedOneFormPullBack" -> True, "Exact" -> True|>|>]]];

  chart = TransportRootSetChart[rootSquares, variables];
  If[MissingQ[chart],
    (* F2 (Design/GeneralityFixes2.md, 2026-08-23): no joint rational
       chart is not the end of the road.  The direct multiquadratic
       engine solves such a strip in the grade basis of the declared
       root set; its terminal success status is "ModularConsistent" and
       NEVER "Solved" -- it returns closed one-forms, not certified dlog
       potentials, so the caller RECORDS the result and never installs
       it (Design/MultiquadraticPromotion.md section 3).  The result is
       returned exactly as the engine typed it. *)
    If[! TrueQ[OptionValue["MultiquadraticDispatch"]],
      Return[<|"Status" -> "NoRationalStripChart",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "MultiquadraticDispatch" -> "Disabled"|>]];
    multiquadraticOptions = OptionValue["MultiquadraticOptions"];
    If[! MatchQ[multiquadraticOptions, {___Rule}],
      Return[<|"Status" -> "InvalidMultiquadraticOptions",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares|>]];
    If[verbose, Print["[strip-in-frame] no rational chart for root squares ",
      rootSquares, "; dispatching to the multiquadratic engine"]];
    multiquadraticResult = solveEpsFormStripMultiquadratic[
      <|"Variables" -> variables, "Regulator" -> epsilon, "Strip" -> strip|>,
      frame,
      Sequence @@ DeleteDuplicatesBy[
        Join[multiquadraticOptions, {"Verbose" -> TrueQ[verbose]}], First]];
    If[! AssociationQ[multiquadraticResult],
      Return[<|"Status" -> "MultiquadraticDispatchNotTyped",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "Result" -> multiquadraticResult|>]];
    multiquadraticStatus = Lookup[multiquadraticResult, "Status", None];
    If[MemberQ[$transportChartMultiquadraticScopeRefusals, multiquadraticStatus],
      Return[<|"Status" -> "NoRationalStripChart",
        "RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "MultiquadraticDispatch" -> "OutOfScope",
        "MultiquadraticRefusal" -> multiquadraticResult|>]];
    (* verbatim, with the frame's own root census added where the engine
       does not carry it (the typed failures do not) *)
    Return[Join[
      <|"RootIndices" -> rootIndices, "RootSquares" -> rootSquares,
        "MultiquadraticDispatch" -> "Engine"|>,
      multiquadraticResult]]];

  chartVariables = {
    Symbol["FeynFacet`Private`stripChartX"],
    Symbol["FeynFacet`Private`stripChartY"]};
  rekeyed = transportChartRekey[chart, variables, chartVariables];
  data = masterTransportChartData[rekeyed, variables];
  If[Lookup[data, "Status", None] =!= "OK", Return[data]];
  chartStrip = oldTransportChartPullBackStrip[strip, data];
  chartRoots = Lookup[rekeyed, "Roots", {}];
  rootImages = Table[Module[{matching = SelectFirst[chartRoots,
      TrueQ[Together[#["RootSquare"] -
          usedRoots[[i]]["RootSquare"]] === 0] &,
      Missing["RootNotRationalized"]]},
    If[MissingQ[matching], matching, matching["Root"]]],
    {i, Length[usedRoots]}];
  If[AnyTrue[rootImages, MissingQ],
    Return[<|"Status" -> "StripChartRootMapMissing"|>]];
  chartBranchRoots = Map[
    <|"RootSquare" -> Together[#["RootSquare"] /. data["Subst"]]|> &,
    usedRoots];
  chartStrip = Map[Together,
    transportChartApplyRootBranches[
      chartStrip, chartBranchRoots, rootImages], {4}];
  inner = solveRationalStrip[chartStrip, chartVariables];
  If[! innerSolvedQ[inner], Return[inner]];
  chartGauge = inner["Gauge"];

  identityData = <|"Status" -> "OK", "Kind" -> "TwoVariable",
    "CoefficientField" -> "Multiquadratic",
    "Variables" -> variables, "SourceVariables" -> variables,
    "Subst" -> Thread[variables -> variables],
    "Jacobian" -> IdentityMatrix[2], "JacobianDet" -> 1,
    "Root" -> If[allRoots === {}, None, allRoots[[1]]["Root"]],
    "RootSquare" -> If[allRoots === {}, None,
      allRoots[[1]]["RootSquare"]], "Roots" -> allRoots|>;
  coordinateMap = masterTransportRecordCoordinateMap[
    <|"Variables" -> chartVariables, "Chart" -> rekeyed|>,
    identityData, Automatic];
  If[Lookup[coordinateMap, "Status", None] =!= "OK",
    Return[<|"Status" -> "StripGaugePullBackFailed",
      "CoordinateMap" -> coordinateMap|>]];
  sourceGauge = Map[Together, chartGauge /. coordinateMap["Map"], {2}];
  sourceAlphabet = DeleteDuplicates[Together /@
    (Lookup[inner, "Alphabet", {}] /. coordinateMap["Map"])];

  signChoices = Tuples[{1, -1}, Length[usedRoots]];
  zeroMatrixQ[matrix_] := AllTrue[Flatten[Map[Together, matrix, {2}]],
    TrueQ[# === 0] &];
  acceptedSigns = Select[signChoices, Function[signs,
    branchImages = MapThread[Times, {signs, rootImages}];
    branchedGauge = transportChartApplyRootBranches[
      sourceGauge, usedRoots, branchImages];
    zeroMatrixQ[(branchedGauge /. data["Subst"]) - chartGauge]]];
  If[acceptedSigns === {},
    Return[<|"Status" -> "StripGaugeRoundTripFailed"|>]];
  branchImages = MapThread[Times, {First[acceptedSigns], rootImages}];

  sourceTransformed = Table[Map[Together,
    bbar[[mu]] + epsilon (e[[mu]] . sourceGauge -
      sourceGauge . c[[mu]]) - D[sourceGauge, variables[[mu]]], {2}],
    {mu, 2}];
  chartTransformed = Table[Map[Together,
    chartStrip[[3, mu]] + epsilon (chartStrip[[1, mu]] . chartGauge -
      chartGauge . chartStrip[[2, mu]]) -
      D[chartGauge, chartVariables[[mu]]], {2}], {mu, 2}];
  branchedGauge = transportChartApplyRootBranches[
    sourceTransformed, usedRoots, branchImages];
  pullPair[pair_] := Module[{components},
    components = Map[
      Map[Together, # /. data["Subst"], {2}] &, pair];
    masterTransportPullBackOneForm[
      components[[1]], components[[2]], data["Jacobian"]]
  ];
  pulledTransformed = pullPair[branchedGauge];
  If[! zeroMatrixQ[pulledTransformed[[1]] - chartTransformed[[1]]] ||
      ! zeroMatrixQ[pulledTransformed[[2]] - chartTransformed[[2]]],
    Return[<|"Status" -> "StripGaugeSourceFrameIdentityFailed"|>]];

  <|"Status" -> "Solved",
    "Method" -> "RationalChart/" <> chart["Name"] <> "/" <> inner["Method"],
    "Gauge" -> sourceGauge, "RootIndices" -> rootIndices,
    "RootSquares" -> rootSquares, "Chart" -> chart,
    "Alphabet" -> sourceAlphabet,
    "InnerSolution" -> KeyDrop[inner, "Gauge"],
    "ExactDLog" -> TrueQ[Lookup[inner, "ExactDLog", False]],
    "Certificate" -> Lookup[inner, "Certificate", "ExactDLog"],
    "FrameCertificate" -> <|
      "CoordinateComposition" -> coordinateMap["CompositionExact"],
      "BranchSigns" -> First[acceptedSigns],
      "GaugeRoundTrip" -> True,
      "TransformedOneFormPullBack" -> True,
      "SourceDLog" -> True,
      "Exact" -> True|>|>
];


Options[oldSolveEpsFormStripInFrame] = Options[SolveEpsFormStripInFrame];

(* ---- the two reordered pipelines, isolated -------------------------- *)

(* OLD: pull back with Together over entries that STILL CARRY RADICALS,
   then substitute the rational root images, then Together again. *)
oldChartStripPipeline[strip_, data_, chartBranchRoots_, rootImages_] :=
  Module[{chartStrip},
    chartStrip = oldTransportChartPullBackStrip[strip, data];
    Map[Together,
      transportChartApplyRootBranches[
        chartStrip, chartBranchRoots, rootImages], {4}]];

(* NEW: the package function -- root images first, Together after. *)
newChartStripPipeline[strip_, data_, chartBranchRoots_, rootImages_] :=
  transportChartPullBackStrip[strip, data, chartBranchRoots, rootImages];

(* pullPair, verbatim from both versions of SolveEpsFormStripInFrame *)
scratchPullPair[pair_, data_] := Module[{components},
  components = Map[Map[Together, # /. data["Subst"], {2}] &, pair];
  masterTransportPullBackOneForm[
    components[[1]], components[[2]], data["Jacobian"]]];

(* OLD source-frame identity pipeline: Together over radical entries,
   then the branch images, then the pullback. *)
oldSourceIdentityPipeline[strip : {e_, c_, bbar_}, data_, variables_,
    epsilon_, sourceGauge_, usedRoots_, branchImages_] :=
  Module[{sourceTransformed, branchedGauge},
    sourceTransformed = Table[Map[Together,
      bbar[[mu]] + epsilon (e[[mu]] . sourceGauge -
        sourceGauge . c[[mu]]) - D[sourceGauge, variables[[mu]]], {2}],
      {mu, 2}];
    branchedGauge = transportChartApplyRootBranches[
      sourceTransformed, usedRoots, branchImages];
    scratchPullPair[branchedGauge, data]];

(* NEW source-frame identity pipeline: branch images first. *)
newSourceIdentityPipeline[strip : {e_, c_, bbar_}, data_, variables_,
    epsilon_, sourceGauge_, usedRoots_, branchImages_] :=
  Module[{sourceTransformed, branchedGauge},
    sourceTransformed = Table[
      bbar[[mu]] + epsilon (e[[mu]] . sourceGauge -
        sourceGauge . c[[mu]]) - D[sourceGauge, variables[[mu]]],
      {mu, 2}];
    branchedGauge = transportChartApplyRootBranches[
      sourceTransformed, usedRoots, branchImages];
    scratchPullPair[branchedGauge, data]];

End[];
