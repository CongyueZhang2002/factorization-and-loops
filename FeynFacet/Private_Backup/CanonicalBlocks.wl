
(* ==== moved from Private/CanonicalBlocks.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: no reference anywhere (reachability.py 2026-09-02)
   Symbols: canonicalBlocksOrbitAct
   This file is never loaded by FeynFacet.m. *)


(* The group element (swap, q) acting on a raw block: relabel the
   variables if asked, then conjugate the basis.  Row i of the result is
   row q[[i]] of the source. *)
canonicalBlocksOrbitAct[{av_, aw_}, swapQ_, permutation_, variables_] :=
  Module[{pair},
    pair = If[TrueQ[swapQ],
      canonicalBlocksSwapPair[{av, aw}, variables],
      {av, aw}];
    {pair[[1]][[permutation, permutation]],
      pair[[2]][[permutation, permutation]]}
  ];

(* ==== moved from Private/CanonicalBlocks.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: CANONICA class ladder and CANONICA loader/regulator bridge (user decision N3, 2026-09-02); ValidateCanonicalForm is CANONICA-free since the same day and the finite-field diagonal-block route is the class canonicalizer
   Symbols: CanonicalizeClasses, canonicalBlocksAttempt, canonicalBlocksChartParameter, canonicalBlocksFormFile, canonicalBlocksFromCanonica, canonicalBlocksLoadCanonica, canonicalBlocksProgressLine, canonicalBlocksSolve, canonicalBlocksToCanonica
   This file is never loaded by FeynFacet.m. *)


(* --- environment -------------------------------------------------- *)

(* CANONICA is a GPL add-on loaded on demand, never at package-load
   time: it prints a banner and installs $ComputeParallel, and most
   FeynFacet sessions never canonicalize anything.  The CANONICA`
   symbols referenced below are created when this file is read and
   acquire their definitions when the add-on loads; that is the normal
   forward-reference behaviour of the context system. *)
canonicalBlocksLoadCanonica[] := Module[{file, path},
  If[TrueQ[$canonicalBlocksCanonicaLoaded], Return[True]];
  file = FileNameJoin[{$feynFacetAddonRoot, "Addon", "Mathematica_Addon",
    "CANONICA", "src", "CANONICA.m"}];
  If[! FileExistsQ[file],
    canonicalBlocksFail[CanonicalizeClasses, "canonica", file]];
  (* restore $ContextPath: leaving CANONICA` on the path makes every
     later bare Get in the session parse eps/x/y into CANONICA` -- the
     measured cause of the 2026-08-20 certification failures. All
     CANONICA references in this package are fully qualified. *)
  path = $ContextPath;
  Quiet[Get[file], General::shdw];
  $ContextPath = path;
  (* inside a subkernel CANONICA's internal parallelism would launch
     sub-subkernels on the shared license and escape TimeConstrained
     (measured 2026-08-18); force serial at every load site *)
  CANONICA`$ComputeParallel = False;
  CANONICA`Private`$ComputeParallel = False;
  $canonicalBlocksCanonicaLoaded = True;
  True
];

(* The only place the regulator changes identity.  Matching on
   SymbolName rather than on the symbol keeps a Global`eps system and a
   Global`Epsilon system on one code path and never touches the
   protected CANONICA`eps except as the substitution target. *)
canonicalBlocksToCanonica[regulator_Symbol] :=
  (s_Symbol /; SymbolName[s] === SymbolName[regulator]) :> CANONICA`eps;

canonicalBlocksFromCanonica[regulator_Symbol] :=
  CANONICA`eps -> regulator;

(* The conic parameter.  Automatic keeps this project's Global`t -- the
   class records that carry a conic chart name it, and their variables
   are (v, w) -- unless t is a variable of the class, its regulator, or a
   symbol occurring in its matrices, in which case a fresh private
   symbol is used.  An explicitly given parameter is taken as given and
   canonicalBlocksBuildChart refuses it if it collides (generality pass
   2026-08-23). *)
(* canonicalBlocksChartParameter: moved back to Private/EpsForm/CanonicalBlocks.wl on 2026-09-02 (round 2); a test cross-checks it. The ladder statements below follow. *)
canonicalBlocksSolve[Automatic] :=
  Function[{matrices, variables, degree},
    Module[{boundaries},
      boundaries = CANONICA`SectorBoundariesFromDE[matrices];
      Quiet @ CANONICA`RecursivelyTransformSectors[
        matrices, variables, boundaries, {1, Length[boundaries]},
        CANONICA`TDeltaNumeratorDegree -> degree,
        CANONICA`TDeltaDenominatorDegree -> degree,
        CANONICA`DDeltaNumeratorDegree -> degree,
        CANONICA`DDeltaDenominatorDegree -> degree]
    ]];

canonicalBlocksSolve[solver_] := solver;

(* One attempt ladder.  Note what is NOT accepted: a two-element list of
   two matrices.  CANONICA returns exactly that on failure, and the only
   discriminator is ValidateCanonicalForm. *)
canonicalBlocksAttempt[matrices_, dimension_, variables_, degrees_,
    timeConstraint_, memoryConstraint_, solver_, regulator_, verbose_] :=
  Module[{result = None},
    Catch[
      Do[
        Module[{raw, seconds, start = AbsoluteTime[], status},
          raw = TimeConstrained[
            MemoryConstrained[solver[matrices, variables, degree],
              memoryConstraint, $Failed],
            timeConstraint, $TimedOut];
          seconds = Round[AbsoluteTime[] - start];
          status = Which[
            raw === $TimedOut, "timeout",
            raw === $Failed, "memory",
            ! (ListQ[raw] && Length[raw] === 2), "malformed",
            raw[[1]] === False, "refused",
            ! (MatrixQ[raw[[1]]] && Length[raw[[1]]] === dimension),
              "malformed",
            ! TrueQ[ValidateCanonicalForm[raw[[2]], variables,
                "Regulator" -> CANONICA`eps]], "unvalidated",
            True, "ok"];
          If[verbose,
            Print["[CanonicalizeClasses]   degree=", degree,
              " status=", status, " seconds=", seconds]];
          If[status === "ok",
            result = <|"Transformation" -> raw[[1]], "EpsForm" -> raw[[2]],
              "AnsatzDegree" -> degree, "Seconds" -> seconds|>;
            Throw[Null, $canonicalBlocksBreak]]],
        {degree, degrees}],
      $canonicalBlocksBreak];
    result
  ];

canonicalBlocksFormFile[directory_, class_] :=
  FileNameJoin[{directory,
    "class" <> ToString[canonicalBlocksClassLabel[class]] <> ".wl"}];

canonicalBlocksProgressLine[class_, status_, record_, seconds_] :=
  Print["[CanonicalizeClasses] class=", canonicalBlocksClassLabel[class],
    " address=", Lookup[class, "ContentAddress", "-"],
    " dim=", Lookup[class, "Dim", "-"],
    " status=", status,
    " degree=", Lookup[record, "AnsatzDegree", "-"],
    " frame=", Lookup[record, "Frame", "-"],
    " seconds=", seconds];

Options[CanonicalizeClasses] = {
  "OutputDirectory" -> Automatic,
  "Card" -> None,
  "AnsatzDegrees" -> Automatic,
  "TimeConstraint" -> Automatic,
  "MemoryConstraint" -> Automatic,
  "Chart" -> True,
  "ChartParameter" -> Automatic,
  "Resume" -> True,
  "Classes" -> All,
  "Solver" -> Automatic,
  "Variables" -> Automatic,
  "Regulator" -> Automatic,
  "Progress" -> True,
  "Verbose" -> False,
  "Order" -> "Dimension"
};

CanonicalizeClasses[input_, OptionsPattern[]] := Catch[
  Module[{classes, directory, card, cardSetting, degrees, timeConstraint,
      memoryConstraint, chartEnabled, parameter, resume, selection, solver,
      progress, verbose, order, results = {}, count, canonicalized = 0,
      unresolved = 0, skipped = 0},
    classes = canonicalBlocksClassList[input];
    If[classes === $Failed,
      canonicalBlocksFail[CanonicalizeClasses, "classes", input]];

    directory = OptionValue["OutputDirectory"];
    (* Automatic writes into the SESSION's scratch space, not into
       whatever Directory[] happens to be: a campaign started from a
       user's home or from the repository root used to create
       CanonicalClassForms/ there and, worse, to resume from a directory
       of the same name that belonged to another run (generality pass
       2026-08-23).  Every caller in this repository passes the output
       directory explicitly, so nothing here changes. *)
    If[directory === Automatic,
      directory = FileNameJoin[{$TemporaryDirectory, "FeynFacet",
        "CanonicalClassForms"}]];
    If[! StringQ[directory],
      canonicalBlocksFail[CanonicalizeClasses, "option", "OutputDirectory",
        directory]];
    directory = ExpandFileName[directory];
    If[! DirectoryQ[directory], Quiet[CreateDirectory[directory]]];
    If[! DirectoryQ[directory],
      canonicalBlocksFail[CanonicalizeClasses, "directory", directory]];

    (* card-sourced defaults: explicit option > card key > built-in.
       The card is the channel's declarative configuration; keys
       "CanonicalizationAnsatzDegrees", "CanonicalizationTimeConstraint",
       "CanonicalizationMemoryConstraint" let a process card set the
       budget without touching code.  Built-ins encode the measured
       lessons (WORKLOG 2026-08-14: 300s missed class 26 by 24s;
       nothing in the residual geometry cracked past the ~700s tier). *)
    card = OptionValue["Card"];
    If[StringQ[card] && FileExistsQ[card],
      card = Quiet @ Check[Get[card], $Failed]];
    If[card =!= None && ! AssociationQ[card],
      canonicalBlocksFail[CanonicalizeClasses, "option", "Card",
        OptionValue["Card"]]];
    cardSetting = Function[{explicit, key, builtin},
      If[explicit =!= Automatic, explicit,
        If[AssociationQ[card], Lookup[card, key, builtin], builtin]]];
    degrees = cardSetting[OptionValue["AnsatzDegrees"],
      "CanonicalizationAnsatzDegrees", {0, 1, 2}];
    If[! (ListQ[degrees] && degrees =!= {} &&
        AllTrue[degrees, IntegerQ[#] && # >= 0 &]),
      canonicalBlocksFail[CanonicalizeClasses, "option", "AnsatzDegrees",
        degrees]];
    timeConstraint = cardSetting[OptionValue["TimeConstraint"],
      "CanonicalizationTimeConstraint", 1200];
    If[! (NumericQ[timeConstraint] && timeConstraint > 0),
      canonicalBlocksFail[CanonicalizeClasses, "option", "TimeConstraint",
        timeConstraint]];
    memoryConstraint = cardSetting[OptionValue["MemoryConstraint"],
      "CanonicalizationMemoryConstraint", 6 1024^3];
    chartEnabled = TrueQ[OptionValue["Chart"]];
    (* Automatic is resolved per class, once the class's own variables
       and regulator are known (generality pass 2026-08-23) *)
    parameter = OptionValue["ChartParameter"];
    If[! MatchQ[parameter, _Symbol],
      canonicalBlocksFail[CanonicalizeClasses, "option", "ChartParameter",
        parameter]];
    resume = TrueQ[OptionValue["Resume"]];
    selection = OptionValue["Classes"];
    solver = canonicalBlocksSolve[OptionValue["Solver"]];
    progress = TrueQ[OptionValue["Progress"]];
    verbose = TrueQ[OptionValue["Verbose"]];
    order = OptionValue["Order"];

    If[selection =!= All,
      classes = Select[classes,
        MemberQ[Flatten[{selection}], Lookup[#, "ClassID", None]] ||
          MemberQ[Flatten[{selection}], Lookup[#, "ContentAddress", None]] &]];
    classes = Switch[order,
      "Dimension", SortBy[classes, Lookup[#, "Dim", 0] &],
      "Given", classes,
      _, SortBy[classes, Lookup[#, "Dim", 0] &]];

    canonicalBlocksLoadCanonica[];
    count = Length[classes];

    Do[
      Module[{class = classes[[k]], file, dimension, variables, regulator,
          matrices, converted, attempt = None, chart = None,
          frame = "direct", frameVariables, start = AbsoluteTime[], record,
          quadratics, chartSystem, chartParameter},
        file = canonicalBlocksFormFile[directory, class];
        dimension = Lookup[class, "Dim", Length[class["RepAv"]]];

        If[resume && FileExistsQ[file],
          skipped++;
          If[progress,
            canonicalBlocksProgressLine[class, "SKIP", <||>, 0]];
          AppendTo[results, <|"ClassID" -> Lookup[class, "ClassID", None],
            "ContentAddress" -> Lookup[class, "ContentAddress", None],
            "Status" -> "SKIP", "File" -> file|>];
          Continue[]];

        variables = canonicalBlocksResolveVariables[
          If[OptionValue["Variables"] === Automatic,
            Lookup[class, "Variables", Automatic], OptionValue["Variables"]],
          {Lookup[class, "RepAv", {}], Lookup[class, "RepAw", {}]}];
        If[variables === $Failed,
          variables = canonicalBlocksDefaultVariables[]];
        If[AssociationQ[variables],
          canonicalBlocksFail[CanonicalizeClasses, "variables",
            Lookup[class, "ClassID", None], variables["FoundSymbols"]]];
        regulator = canonicalBlocksResolveRegulator[
          If[OptionValue["Regulator"] === Automatic,
            Lookup[class, "Regulator", Automatic], OptionValue["Regulator"]],
          class["RepAv"], variables];
        If[regulator === $Failed || ! MatchQ[regulator, _Symbol],
          canonicalBlocksFail[CanonicalizeClasses, "option", "Regulator",
            OptionValue["Regulator"]]];

        matrices = {class["RepAv"], class["RepAw"]};
        converted = matrices /. canonicalBlocksToCanonica[regulator];
        frameVariables = variables;

        attempt = canonicalBlocksAttempt[converted, dimension, variables,
          degrees, timeConstraint, memoryConstraint, solver, regulator,
          verbose];

        (* Chart retry: exactly one irreducible quadratic denominator
           means one conic, hence a genus-0 rational parametrization. *)
        If[attempt === None && chartEnabled && Length[variables] === 2,
          quadratics = canonicalBlocksQuadraticFactors[matrices, variables];
          If[Length[quadratics] === 1,
            chartParameter = canonicalBlocksChartParameter[parameter,
              matrices, variables, regulator];
            chart = canonicalBlocksBuildChart[First[quadratics], variables,
              chartParameter];
            If[AssociationQ[chart] && KeyExistsQ[chart, "Status"],
              canonicalBlocksFail[CanonicalizeClasses, "chartparameter",
                chartParameter, variables]];
            If[verbose,
              Print["[CanonicalizeClasses]   chart=",
                If[chart === None, "NONE",
                  ToString[InputForm[chart["Subst"]]]]]];
            If[chart =!= None,
              {chartSystem, frameVariables} = canonicalBlocksApplyChart[
                converted, chart, variables, chartParameter];
              frame = "chart";
              attempt = canonicalBlocksAttempt[chartSystem, dimension,
                frameVariables, degrees, timeConstraint, memoryConstraint,
                solver, regulator, verbose]]]];

        If[attempt =!= None,
          record = <|
            "Format" -> "FeynFacet-CanonicalClassForm",
            "FormatVersion" -> $canonicalBlocksArtifactVersion,
            "ClassID" -> Lookup[class, "ClassID", None],
            "ContentAddress" -> Lookup[class, "ContentAddress", None],
            "RepFamily" -> Lookup[class, "RepFamily", None],
            "RepRows" -> Lookup[class, "RepRows", None],
            "RepBasis" -> Lookup[class, "RepBasis", Missing[]],
            "Dim" -> dimension,
            "Transformation" ->
              (attempt["Transformation"] /.
                canonicalBlocksFromCanonica[regulator]),
            "EpsForm" ->
              (attempt["EpsForm"] /. canonicalBlocksFromCanonica[regulator]),
            "Variables" -> frameVariables,
            "Regulator" -> regulator,
            "Chart" -> chart,
            "Frame" -> frame,
            "AnsatzDegree" -> attempt["AnsatzDegree"],
            "TimeConstraint" -> timeConstraint,
            "Seconds" -> Round[AbsoluteTime[] - start],
            "Validated" -> True
          |>;
          canonicalBlocksPutAtomic[record, file];
          canonicalized++;
          If[progress,
            canonicalBlocksProgressLine[class, "CANONICALIZED",
              <|"AnsatzDegree" -> attempt["AnsatzDegree"], "Frame" -> frame|>,
              Round[AbsoluteTime[] - start]]];
          AppendTo[results, <|"ClassID" -> Lookup[class, "ClassID", None],
            "ContentAddress" -> Lookup[class, "ContentAddress", None],
            "Status" -> "CANONICALIZED", "File" -> file,
            "AnsatzDegree" -> attempt["AnsatzDegree"], "Frame" -> frame,
            "Seconds" -> Round[AbsoluteTime[] - start]|>],
          unresolved++;
          If[progress,
            canonicalBlocksProgressLine[class, "UNRESOLVED",
              <|"Frame" -> frame|>, Round[AbsoluteTime[] - start]]];
          AppendTo[results, <|"ClassID" -> Lookup[class, "ClassID", None],
            "ContentAddress" -> Lookup[class, "ContentAddress", None],
            "Status" -> "UNRESOLVED", "Frame" -> frame,
            "Seconds" -> Round[AbsoluteTime[] - start]|>]]
      ],
      {k, count}];

    If[progress,
      Print["[CanonicalizeClasses] classes=", count,
        " canonicalized=", canonicalized,
        " unresolved=", unresolved,
        " skipped=", skipped,
        " directory=", directory]];

    <|
      "Format" -> $canonicalBlocksArtifactFormat,
      "FormatVersion" -> $canonicalBlocksArtifactVersion,
      "Stage" -> "Canonicalization",
      "Created" -> DateString[],
      "OutputDirectory" -> directory,
      "AnsatzDegrees" -> degrees,
      "TimeConstraint" -> timeConstraint,
      "Classes" -> count,
      "Canonicalized" -> canonicalized,
      "Unresolved" -> unresolved,
      "Skipped" -> skipped,
      "Results" -> results
    |>
  ],
  $canonicalBlocksFailure
];
