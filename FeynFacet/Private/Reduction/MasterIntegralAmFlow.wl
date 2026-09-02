(* Numerical evaluation of cut or uncut master integrals with AMFlow. *)

MasterIntegralAmFlow::data =
  "The master data must contain Master and Topology together with CutIndices and either Prescription or Setup.";

MasterIntegralAmFlow::master =
  "The requested master `1` does not belong to topology `2` or has an invalid index list.";

MasterIntegralAmFlow::kinematics =
  "Numerical kinematics must be an Association or a list of rules. Invalid input: `1`.";

MasterIntegralAmFlow::cut =
  "The cut data are inconsistent with the topology: `1`.";

MasterIntegralAmFlow::amflow =
  "AMFlow could not be loaded from `1`.";

MasterIntegralAmFlow::executable =
  "The required executable does not exist: `1`.";

MasterIntegralAmFlow::option =
  "Invalid option value `1` for `2`.";

MasterIntegralAmFlow::solve =
  "AMFlow did not return numerical values for `1`. It returned `2`. The working directory is `3`.";

MasterIntegralAmFlow::result =
  "The coefficient result does not contain topology data for master `1`.";

$masterIntegralFailure = "FeynFacetMasterIntegralFailure";

SetAttributes[masterIntegralFail, HoldFirst];


Options[MasterIntegralAmFlow] = {
  "AMFlowPath" -> Automatic,
  "KiraExecutable" -> Automatic,
  "FermatExecutable" -> Automatic,
  "PrecisionGoal" -> 20,
  "EpsilonOrder" -> 0,
  "Threads" -> 1,
  "D0" -> 4,
  "ReductionMode" -> "Kira",
  "WorkingDirectory" -> Automatic,
  "KeepWorkingDirectory" -> False,
  "TimeConstraint" -> Infinity,
  "Verbose" -> False
};


masterIntegralFail[message_, arguments___] := (
  Message[message, arguments];
  Throw[$Failed, $masterIntegralFailure]
);


masterIntegralRules[rules_Association] := Normal[rules];

masterIntegralRules[rules_List] /;
    AllTrue[rules, MatchQ[#, _Rule | _RuleDelayed] &] :=
  rules /. RuleDelayed -> Rule;

masterIntegralRules[rules_] :=
  masterIntegralFail[MasterIntegralAmFlow::kinematics, HoldForm[rules]];


masterIntegralKinematicsQ[rules_] :=
  AssociationQ[rules] ||
    (ListQ[rules] &&
      AllTrue[rules, MatchQ[#, _Rule | _RuleDelayed] &]);


masterIntegralRestoreSPD[expression_] := expression /.
  HoldPattern[(Hold[FeynCalc`SPD])[arguments___]] :>
    FeynCalc`SPD[arguments];


masterIntegralPolynomial[expression_] := Expand[
  FeynCalc`FCI[masterIntegralRestoreSPD[expression]] /. {
    FeynCalc`Pair[
      FeynCalc`Momentum[first_, ___],
      FeynCalc`Momentum[second_, ___]
    ] :> first second
  }
];


masterIntegralRule[Rule[left_, right_]] :=
  masterIntegralPolynomial[left] -> masterIntegralPolynomial[right];


masterIntegralLastRules[rules_List] :=
  Reverse @ DeleteDuplicatesBy[Reverse[rules], First];


masterIntegralPropagator[propagator_] := Module[
  {internal, explicit, inverse},
  internal = Quiet @ Check[FeynCalc`FCI[propagator], $Failed];
  If[internal === $Failed,
    masterIntegralFail[MasterIntegralAmFlow::data]
  ];
  explicit = Quiet @ Check[
    FeynCalc`FeynAmpDenominatorExplicit[
      internal,
      FeynCalc`FCI -> True
    ],
    $Failed
  ];
  If[
    explicit === $Failed ||
      ! FreeQ[
        explicit,
        FeynCalc`FeynAmpDenominator |
          FeynCalc`PropagatorDenominator |
          FeynCalc`StandardPropagatorDenominator
      ],
    masterIntegralFail[MasterIntegralAmFlow::data]
  ];
  inverse = Quiet @ Check[Cancel[1/explicit], $Failed];
  If[inverse === $Failed || exactZeroQ[inverse],
    masterIntegralFail[MasterIntegralAmFlow::data]
  ];
  masterIntegralPolynomial[inverse]
];


masterIntegralList[master_FeynCalc`GLI] := {master};

masterIntegralList[masters_List] /;
    masters =!= {} && AllTrue[masters, MatchQ[#, _FeynCalc`GLI] &] :=
  masters;

masterIntegralList[master_] :=
  masterIntegralFail[MasterIntegralAmFlow::master, HoldForm[master], None];


masterIntegralTopologyData[data_Association] := Module[
  {
    record, topology, setup, flow, cutIndices, cutDirections,
    prescription, topologyLoops, flowLoops, prescriptionByMomentum,
    sideSets, mixedIndices, invalidCuts
  },

  record = Lookup[data, "TopologyRecord", Missing["NotAvailable"]];
  topology = Which[
    MatchQ[record, _Association] && KeyExistsQ[record, "Topology"],
      record["Topology"],
    KeyExistsQ[data, "Topology"],
      data["Topology"],
    topologyRecordQ[data],
      data["Topology"],
    True,
      Missing["NotAvailable"]
  ];
  If[! MatchQ[topology, _FeynCalc`FCTopology],
    masterIntegralFail[MasterIntegralAmFlow::data]
  ];

  cutIndices = Lookup[
    data,
    "CutIndices",
    If[AssociationQ[record], Lookup[record, "CutIndices", {}], {}]
  ];
  cutDirections = Lookup[
    data,
    "CutDirections",
    If[
      AssociationQ[record],
      Lookup[record, "CutDirections", ConstantArray[1, Length[cutIndices]]],
      ConstantArray[1, Length[cutIndices]]
    ]
  ];
  setup = Lookup[data, "Setup", Missing["NotAvailable"]];
  flow = Which[
    AssociationQ[setup],
      AMFlowPrescription[setup],
    AssociationQ[Lookup[data, "AMFlowInfo", Missing[]]],
      data["AMFlowInfo"],
    ListQ[Lookup[data, "Prescription", Missing[]]],
      <|"Prescription" -> data["Prescription"]|>,
    True,
      $Failed
  ];
  If[! AssociationQ[flow], masterIntegralFail[MasterIntegralAmFlow::data]];

  topologyLoops = topology[[3]];
  prescription = Lookup[flow, "Prescription", Missing["NotAvailable"]];
  flowLoops = Lookup[flow, "LoopMomenta", topologyLoops];
  If[
    MatchQ[flowLoops, {_Symbol ...}] &&
      MatchQ[prescription, {___Integer}] &&
      Length[flowLoops] === Length[prescription] &&
      Sort[flowLoops] === Sort[topologyLoops],
    prescriptionByMomentum = AssociationThread[flowLoops, prescription];
    prescription = Lookup[prescriptionByMomentum, topologyLoops]
  ];

  If[
    ! ListQ[cutIndices] ||
      ! DuplicateFreeQ[cutIndices] ||
      ! AllTrue[
        cutIndices,
        IntegerQ[#] && 1 <= # <= Length[topology[[2]]] &
      ] ||
      ! MatchQ[cutDirections, {___Integer}] ||
      Length[cutDirections] =!= Length[cutIndices] ||
      ! AllTrue[cutDirections, # === 1 &] ||
      ! MatchQ[prescription, {___Integer}] ||
      Length[prescription] =!= Length[topologyLoops] ||
      ! AllTrue[prescription, MemberQ[{-1, 0, 1}, #] &],
    masterIntegralFail[
      MasterIntegralAmFlow::cut,
      HoldForm[{cutIndices, cutDirections, prescription}]
    ]
  ];

  sideSets = Function[propagator,
      DeleteDuplicates @ DeleteCases[
        Pick[
          prescription,
          (! FreeQ[FeynCalc`FCI[propagator], #] &) /@ topologyLoops
        ],
        0
      ]
    ] /@ topology[[2]];
  mixedIndices = Flatten @ Position[
    sideSets,
    sides_ /; Length[sides] > 1,
    {1}
  ];
  invalidCuts = Select[cutIndices, sideSets[[#]] =!= {} &];
  If[mixedIndices =!= {} || invalidCuts =!= {},
    masterIntegralFail[
      MasterIntegralAmFlow::cut,
      HoldForm[<|
        "MixedVirtualSides" -> mixedIndices,
        "VirtualLoopCuts" -> invalidCuts
      |>]
    ]
  ];

  <|
    "Topology" -> topology,
    "CutIndices" -> cutIndices,
    "Prescription" -> prescription,
    "Cut" -> (
      Boole[MemberQ[cutIndices, #]] & /@
        Range[Length[topology[[2]]]]
    )
  |>
];


masterIntegralAutomaticFile[option_, relative_List] := Module[{candidate},
  candidate = If[
    option === Automatic,
    FileNameJoin[Prepend[relative, $feynFacetRoot]],
    ExpandFileName[option]
  ];
  candidate
];


masterIntegralAMFlowBase[] := Module[{input},
  input = If[$FrontEnd === Null, $InputFileName, NotebookFileName[]];
  Replace[DirectoryName[input], "" -> Directory[]]
];


masterIntegralRelativePath[from_, to_] := Module[
  {fromParts, toParts, common, parts},
  fromParts = FileNameSplit[ExpandFileName[from]];
  toParts = FileNameSplit[ExpandFileName[to]];
  common = 0;
  While[
    common < Min[Length[fromParts], Length[toParts]] &&
      SameQ[fromParts[[common + 1]], toParts[[common + 1]]],
    common++
  ];
  If[common === 0, Return[ExpandFileName[to]]];
  parts = Join[
    ConstantArray["..", Length[fromParts] - common],
    Drop[toParts, common]
  ];
  If[parts === {}, ".", FileNameJoin[parts]]
];


masterIntegralLoadAMFlow[path_] := Module[{loaded},
  If[
    Length[DownValues[AMFlow`SolveIntegrals]] > 0 &&
      Length[DownValues[AMFlow`WithGlobalVariables]] > 0,
    Return[True]
  ];
  loaded = Quiet @ Check[Block[{Print}, Get[path]], $Failed];
  If[
    loaded === $Failed ||
      Length[DownValues[AMFlow`SolveIntegrals]] === 0 ||
      Length[DownValues[AMFlow`WithGlobalVariables]] === 0,
    masterIntegralFail[MasterIntegralAmFlow::amflow, path]
  ];
  True
];


masterIntegralValidateOptions[precision_, order_, threads_, d0_, time_] := (
  If[! IntegerQ[precision] || precision <= 0,
    masterIntegralFail[MasterIntegralAmFlow::option, precision, "PrecisionGoal"]
  ];
  If[! IntegerQ[order],
    masterIntegralFail[MasterIntegralAmFlow::option, order, "EpsilonOrder"]
  ];
  If[! IntegerQ[threads] || threads <= 0,
    masterIntegralFail[MasterIntegralAmFlow::option, threads, "Threads"]
  ];
  If[! IntegerQ[d0] || d0 <= 0,
    masterIntegralFail[MasterIntegralAmFlow::option, d0, "D0"]
  ];
  If[time =!= Infinity && (! NumericQ[time] || time <= 0),
    masterIntegralFail[MasterIntegralAmFlow::option, time, "TimeConstraint"]
  ];
);


masterIntegralEvaluate[
    data_Association,
    numericalKinematics_,
    options : OptionsPattern[MasterIntegralAmFlow]
  ] := Catch[Module[
  {
    masters, topologyData, topology, family, propagators, loops, legs,
    inputRules, convertedRules, directReplacement, numericalRules,
    topologyReplacement, replacement, conservation, targets,
    amflowPath, kiraExecutable, fermatExecutable, precision, order,
    threads, d0, reductionMode, workOption, keepWork, timeConstraint,
    workDirectory, createdWork, cacheName, oldDirectory, solve, rules,
    values, verbose, configuration, computation
  },

  masters = masterIntegralList @ Lookup[
    data,
    "Master",
    Lookup[data, "BaseGLI", Missing["NotAvailable"]]
  ];
  topologyData = masterIntegralTopologyData[data];
  topology = topologyData["Topology"];
  family = topology[[1]];
  If[
    ! AllTrue[
      masters,
      SameQ[#[[1]], family] &&
        Length[#[[2]]] === Length[topology[[2]]] &&
        AllTrue[#[[2]], IntegerQ] &&
        AllTrue[#[[2, topologyData["CutIndices"]]], # > 0 &] &
    ],
    masterIntegralFail[
      MasterIntegralAmFlow::master,
      HoldForm[masters],
      family
    ]
  ];

  inputRules = masterIntegralRules[numericalKinematics];
  convertedRules = masterIntegralRule /@ inputRules;
  loops = topology[[3]];
  legs = topology[[4]];
  directReplacement = Select[
    convertedRules,
    ! FreeQ[First[#], Alternatives @@ legs] &
  ];
  numericalRules = Select[
    convertedRules,
    FreeQ[First[#], Alternatives @@ legs] &
  ] /. Rule[left_, right_] :> Rule[
    If[
      SameQ[left, $feynFacetEpsilon] ||
        (Head[left] === Symbol && SymbolName[left] === "Epsilon"),
      Symbol["Global`eps"],
      left
    ],
    right
  ];
  topologyReplacement = masterIntegralRule /@
    masterIntegralRules[topology[[5]]];
  replacement = masterIntegralLastRules @ Join[
    topologyReplacement,
    directReplacement
  ];
  numericalRules = masterIntegralLastRules[numericalRules];
  If[! AllTrue[numericalRules, NumericQ[Last[#]] &],
    masterIntegralFail[
      MasterIntegralAmFlow::kinematics,
      HoldForm[numericalKinematics]
    ]
  ];
  conservation = masterIntegralRules @ Lookup[data, "Conservation", {}];
  conservation = masterIntegralRule /@ conservation;
  propagators = masterIntegralPropagator /@ topology[[2]];
  targets = Apply[
      Symbol["Global`j"],
      Prepend[#[[2]], family]
    ] & /@ masters;

  amflowPath = masterIntegralAutomaticFile[
    OptionValue["AMFlowPath"],
    {"Addon", "Mathematica_Addon", "AMFlow", "AMFlow.m"}
  ];
  kiraExecutable = masterIntegralAutomaticFile[
    OptionValue["KiraExecutable"],
    {"Addon", "Other_Addon", "Kira", "bin", "kira"}
  ];
  fermatExecutable = masterIntegralAutomaticFile[
    OptionValue["FermatExecutable"],
    {"Addon", "Other_Addon", "Kira", "bin", "fer64"}
  ];
  If[! FileExistsQ[amflowPath],
    masterIntegralFail[MasterIntegralAmFlow::amflow, amflowPath]
  ];
  If[! FileExistsQ[kiraExecutable],
    masterIntegralFail[MasterIntegralAmFlow::executable, kiraExecutable]
  ];
  If[! FileExistsQ[fermatExecutable],
    masterIntegralFail[MasterIntegralAmFlow::executable, fermatExecutable]
  ];

  precision = OptionValue["PrecisionGoal"];
  order = OptionValue["EpsilonOrder"];
  threads = OptionValue["Threads"];
  d0 = OptionValue["D0"];
  reductionMode = OptionValue["ReductionMode"];
  workOption = OptionValue["WorkingDirectory"];
  keepWork = TrueQ[OptionValue["KeepWorkingDirectory"]];
  timeConstraint = OptionValue["TimeConstraint"];
  verbose = OptionValue["Verbose"];
  masterIntegralValidateOptions[
    precision, order, threads, d0, timeConstraint
  ];
  If[! StringQ[reductionMode],
    masterIntegralFail[
      MasterIntegralAmFlow::option,
      reductionMode,
      "ReductionMode"
    ]
  ];
  If[! MemberQ[{True, False}, verbose],
    masterIntegralFail[MasterIntegralAmFlow::option, verbose, "Verbose"]
  ];

  masterIntegralLoadAMFlow[amflowPath];

  createdWork = workOption === Automatic;
  workDirectory = If[
    createdWork,
    CreateDirectory @ FileNameJoin[{
      $TemporaryDirectory,
      "FeynFacetMasterIntegral-" <> CreateUUID[]
    }],
    ExpandFileName[workOption]
  ];
  If[! DirectoryQ[workDirectory],
    CreateDirectory[workDirectory, CreateIntermediateDirectories -> True]
  ];
  cacheName = masterIntegralRelativePath[
    masterIntegralAMFlowBase[],
    workDirectory
  ];

  configuration := (
    AMFlow`SetAMFOptions[
      "DESolver" -> "CPP",
      "D0" -> d0,
      "UseCache" -> False,
      "CacheName" -> cacheName
    ];
    AMFlow`SetReductionOptions["IBPReducer" -> "Kira"];
    Kira`$KiraExecutable = kiraExecutable;
    Kira`$FermatExecutable = fermatExecutable;
    AMFlow`SetReducerOptions["ReductionMode" -> reductionMode];
  );
  If[TrueQ[verbose], configuration, Block[{Print}, configuration]];

  computation := AMFlow`WithGlobalVariables[
    AMFlow`AMFlowInfo["Family"] = family;
    AMFlow`AMFlowInfo["Loop"] = loops;
    AMFlow`AMFlowInfo["Leg"] = legs;
    AMFlow`AMFlowInfo["Conservation"] = conservation;
    AMFlow`AMFlowInfo["Replacement"] = replacement;
    AMFlow`AMFlowInfo["Propagator"] = propagators;
    AMFlow`AMFlowInfo["Numeric"] = numericalRules;
    AMFlow`AMFlowInfo["NThread"] = threads;
    AMFlow`AMFlowInfo["Prescription"] = topologyData["Prescription"];
    AMFlow`AMFlowInfo["Cut"] = topologyData["Cut"];
    If[
      timeConstraint === Infinity,
      AMFlow`SolveIntegrals[targets, precision, order],
      TimeConstrained[
        AMFlow`SolveIntegrals[targets, precision, order],
        timeConstraint,
        $TimedOut
      ]
    ]
  ];

  oldDirectory = Directory[];
  solve = CheckAbort[
    SetDirectory[workDirectory];
    If[
      TrueQ[verbose],
      Check[computation, $Failed],
      Block[{Print}, Check[computation, $Failed]]
    ],
    Quiet[SetDirectory[oldDirectory]];
    If[
      createdWork && ! keepWork && DirectoryQ[workDirectory],
      Quiet @ DeleteDirectory[workDirectory, DeleteContents -> True]
    ];
    Abort[]
  ];
  Quiet[SetDirectory[oldDirectory]];
  If[
    createdWork && ! keepWork && DirectoryQ[workDirectory],
    Quiet @ DeleteDirectory[workDirectory, DeleteContents -> True]
  ];

  rules = solve;
  If[
    ! MatchQ[rules, {_Rule ..}] ||
      ! ContainsAll[First /@ rules, targets],
    masterIntegralFail[
      MasterIntegralAmFlow::solve,
      masters,
      Short[solve, 3],
      workDirectory
    ]
  ];
  values = targets /. rules /. Symbol["Global`eps"] -> $feynFacetEpsilon;
  If[Length[values] === 1, First[values], values]
], $masterIntegralFailure];


MasterIntegralAmFlow[
    data_Association,
    numericalKinematics_?masterIntegralKinematicsQ,
    options : OptionsPattern[]
  ] := masterIntegralEvaluate[data, numericalKinematics, options];


MasterIntegralAmFlow[
    result_Association,
    master : (_FeynCalc`GLI | {__FeynCalc`GLI}),
    numericalKinematics_,
    options : OptionsPattern[]
  ] /; KeyExistsQ[result, "Topologies"] := Module[
  {masters, family, records, record, data},
  masters = If[MatchQ[master, _FeynCalc`GLI], {master}, master];
  family = DeleteDuplicates[#[[1]] & /@ masters];
  If[Length[family] =!= 1,
    Message[MasterIntegralAmFlow::result, HoldForm[master]];
    Return[$Failed]
  ];
  records = Lookup[result, "Topologies", {}];
  record = SelectFirst[
    records,
    MatchQ[Lookup[#, "Topology", None], _FeynCalc`FCTopology] &&
      SameQ[#["Topology"][[1]], First[family]] &,
    Missing["NotAvailable"]
  ];
  If[! AssociationQ[record],
    Message[MasterIntegralAmFlow::result, HoldForm[master]];
    Return[$Failed]
  ];
  data = <|
    "Master" -> master,
    "TopologyRecord" -> record,
    "Setup" -> Lookup[result, "Setup", <||>]
  |>;
  masterIntegralEvaluate[data, numericalKinematics, options]
];


MasterIntegralAmFlow[
    data_Association,
    numericalKinematics_,
    OptionsPattern[]
  ] := (
  Message[
    MasterIntegralAmFlow::kinematics,
    HoldForm[numericalKinematics]
  ];
  $Failed
);


MasterIntegralAmFlow[___] := (
  Message[MasterIntegralAmFlow::data];
  $Failed
);
