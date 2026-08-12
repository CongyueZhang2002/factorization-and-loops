(* Two-loop (NNLO double-real) master differential equations, rung 1:
   a single canonical family standalone.

   Generalizes the NLO Euler-operator construction to two loop
   momenta {ke, kf} and nine propagators (quadratic + bilinear
   auxiliary): the nine loop scalar products are solved from the nine
   propagators, the three Euler operators produce raised/lowered
   integrals, a dedicated single-family Kira run (config copied
   verbatim from the production canonical workspace) reduces them,
   and the block connection matrices are assembled with the flatness
   certificate.

   Usage: wolframscript -file build_nnlo_de.wls CF21 *)

root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
scratch = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad";

familyName = If[Length[Rest[$ScriptCommandLine]] >= 1,
  First[Rest[$ScriptCommandLine]], "CF21"];
work = FileNameJoin[{scratch, "nnlo_de_kira_" <> familyName}];

S12 = Global`ffecfp1; S13 = Global`ffecfp2; S23 = Global`ffecfp3;

registry = FeynFacet`Private`coefficientReadRecord[
  FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "CanonicalRegistry.wxf"}]];
record = SelectFirst[
  registry["Registry"]["Families"],
  ToString[#["Name"]] === familyName &
];
If[MissingQ[record], Print["NO FAMILY ", familyName]; Exit[1]];
topology = record["Topology"];
cutPositions = Sort[record["CutIndices"]];
Print["FAMILY ", familyName, "  cuts ", cutPositions];

(* Masters of this family, from the canonical trace manifest. *)
manifest = FeynFacet`Private`coefficientReadRecord[
  FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal",
    "CoefficientSimplification", "UU_08_10_canonical",
    "FiniteFieldCanonical", "TraceManifest.wxf"}]];
allMasters = manifest["TraceData"]["Masters"];
familyMasters = Select[allMasters,
  ToString[#[[1]]] === familyName &];
Print["FAMILY MASTERS: ", Length[familyMasters]];
Scan[Print["  ", InputForm[#]] &, familyMasters];
If[familyMasters === {}, Print["nothing to do"]; Exit[1]];

(* --- propagator representation -------------------------------------- *)
(* quadratic: {"Quad", momentum}; bilinear: {"Bil", a, b} *)
parseProp[
  FeynCalc`FeynAmpDenominator[
    FeynCalc`StandardPropagatorDenominator[
      FeynCalc`Momentum[m_, ___], 0, 0, _]]
] := {"Quad", m};
parseProp[
  FeynCalc`FeynAmpDenominator[
    FeynCalc`StandardPropagatorDenominator[
      0, FeynCalc`Pair[FeynCalc`Momentum[a_, ___],
        FeynCalc`Momentum[b_, ___]], 0, _]]
] := {"Bil", a, b};
parseProp[other_] := (Print["UNPARSED PROP: ", InputForm[other]];
  Exit[1]);

propagators = parseProp /@ topology[[2]];
nProps = Length[propagators];
Print["PROPAGATORS: ", nProps];

(* --- scalar-product algebra over {ke, kf; ka, kb, kc} -------------- *)
basis = {ke, kf, ka, kb, kc};
loopSPs = {eEE, eFF, eEF, eEA, eEB, eEC, eFA, eFB, eFC};
gram = <|
  Sort[{ke, ke}] -> eEE, Sort[{kf, kf}] -> eFF,
  Sort[{ke, kf}] -> eEF,
  Sort[{ke, ka}] -> eEA, Sort[{ke, kb}] -> eEB,
  Sort[{ke, kc}] -> eEC,
  Sort[{kf, ka}] -> eFA, Sort[{kf, kb}] -> eFB,
  Sort[{kf, kc}] -> eFC,
  Sort[{ka, ka}] -> 0, Sort[{kb, kb}] -> 0, Sort[{kc, kc}] -> 0,
  Sort[{ka, kb}] -> S12/2, Sort[{ka, kc}] -> S13/2,
  Sort[{kb, kc}] -> S23/2
|>;
pairSP[p_, q_] := Lookup[gram, Key[Sort[{p, q}]]];
vec[m_] := Coefficient[m, #] & /@ basis;
sp[m1_, m2_] := Module[{v1 = vec[m1], v2 = vec[m2]},
  Sum[v1[[i]] v2[[j]] pairSP[basis[[i]], basis[[j]]],
    {i, 5}, {j, 5}]
];

dExpression[{"Quad", m_}] := Expand[sp[m, m]];
dExpression[{"Bil", a_, b_}] := Expand[sp[a, b]];

propagatorSymbols = Array[dd, nProps];
solveTable = Module[{solution},
  solution = Solve[
    Thread[propagatorSymbols == (dExpression /@ propagators)],
    loopSPs
  ];
  If[Length[solution] =!= 1,
    Print["FAMILY NOT COMPLETE"]; Exit[1]];
  First[solution]
];
Print["SP SOLVE TABLE OK"];

cutZero[expr_] := expr /. gli[f_, idx_] /;
  Min[idx[[cutPositions]]] <= 0 -> 0;

(* Euler operator v.d/dv on the propagators:
   quadratic (ke+P)^2: 2 c_v sp(v, m);
   bilinear a.b: c_{v,a} sp(v, b) + c_{v,b} sp(v, a). *)
eulerWeight[v_, {"Quad", m_}] := 2 Coefficient[m, v] sp[v, m];
eulerWeight[v_, {"Bil", a_, b_}] :=
  Coefficient[a, v] sp[v, b] + Coefficient[b, v] sp[v, a];

euler[v_, gli[fam_, nu_]] := Sum[
  Module[{weightRaw, weight, raised},
    weightRaw = eulerWeight[v, propagators[[j]]];
    If[weightRaw === 0 || nu[[j]] === 0,
      0,
      weight = Expand[-nu[[j]] weightRaw /. solveTable];
      raised = ReplacePart[nu, j -> nu[[j]] + 1];
      cutZero @ Expand[
        (weight /. Thread[propagatorSymbols -> 0]) gli[fam, raised] +
        Sum[
          Coefficient[weight, propagatorSymbols[[k]]] *
            gli[fam, ReplacePart[raised, k -> raised[[k]] - 1]],
          {k, nProps}
        ]
      ]
    ]
  ],
  {j, nProps}
];

masterList = gli[familyName, #[[2]]] & /@ familyMasters;
derivatives = Association @ Map[
  Function[master,
    Module[{oa, ob, oc},
      {oa, ob, oc} = euler[#, master] & /@ {ka, kb, kc};
      master -> <|
        "dS13" -> Together[(oa - ob + oc)/(2 S13)],
        "dS23" -> Together[(-oa + ob + oc)/(2 S23)]
      |>
    ]
  ],
  masterList
];
computeDerivatives[master_] := Module[{oa, ob, oc},
  {oa, ob, oc} = euler[#, master] & /@ {ka, kb, kc};
  <|
    "dS13" -> Together[(oa - ob + oc)/(2 S13)],
    "dS23" -> Together[(-oa + ob + oc)/(2 S23)]
  |>
];

kiraExe = FileNameJoin[{root, "Addon", "Other_Addon", "Kira", "bin",
  "kira"}];
fermat = FileNameJoin[{root, "Addon", "Other_Addon", "Kira", "bin",
  "fer64"}];
productionYaml = Import[
  FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal", "Kira",
    "UU_08_10_canonical", "kira", "config", "integralfamilies.yaml"}],
  "Text"
];
familyBlock = StringCases[
  productionYaml,
  StartOfLine ~~ "  - name: " ~~ familyName ~~ "\n" ~~
    Shortest[body___] ~~ ("\n  - name: " | EndOfString) :>
    "  - name: " <> familyName <> "\n" <> body
];
If[familyBlock === {}, Print["YAML BLOCK NOT FOUND"]; Exit[1]];
topFromYaml = StringCases[First[familyBlock],
  "top_level_sectors: [b" ~~ bits : (("0" | "1") ..) ~~ "]" :> bits];
If[topFromYaml === {}, Print["NO TOP SECTOR"]; Exit[1]];
sectorSpec = "b" <> First[topFromYaml];

runKira[targetList_] := Module[{maxR, maxS, run},
  If[DirectoryQ[work], DeleteDirectory[work, DeleteContents -> True]];
  CreateDirectory[FileNameJoin[{work, "config"}],
    CreateIntermediateDirectories -> True];
  Export[FileNameJoin[{work, "config", "integralfamilies.yaml"}],
    "integralfamilies:\n" <> First[familyBlock] <> "\n", "String"];
  CopyFile[
    FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal", "Kira",
      "UU_08_10_canonical", "kira", "config", "kinematics.yaml"}],
    FileNameJoin[{work, "config", "kinematics.yaml"}]
  ];
  Export[
    FileNameJoin[{work, "integrals_1"}],
    StringRiffle[
      (familyName <> "[" <>
        StringRiffle[ToString /@ Last[#], ","] <> "]") & /@
        Sort[targetList],
      "\n"
    ] <> "\n",
    "String"
  ];
  maxR = Max[Total[Select[#, Positive]] & /@ (Last /@ targetList)];
  maxS = Max[0,
    Max[-Total[Select[#, Negative]] & /@ (Last /@ targetList)]];
  Export[FileNameJoin[{work, "jobs.yaml"}],
    StringRiffle[{
      "jobs:",
      "  - reduce_sectors:",
      "      reduce:",
      "        - {topologies: [" <> familyName <> "], sectors: [" <>
        sectorSpec <> "], r: " <> ToString[maxR + 1] <> ", s: " <>
        ToString[maxS + 1] <> " }",
      "      select_integrals:",
      "        select_mandatory_list:",
      "          - [" <> familyName <> ", \"integrals_1\"]",
      "      run_initiate: true",
      "      run_triangular: true",
      "      run_back_substitution: true",
      "      integral_ordering: 2",
      "  - kira2math:",
      "      target:",
      "        - [" <> familyName <> ", \"integrals_1\"]"
    }, "\n"] <> "\n", "String"];
  Print["  Kira: ", Length[targetList], " targets, r ", maxR + 1,
    ", s ", maxS + 1];
  run = RunProcess[
    {kiraExe, "--parallel=12", "jobs.yaml"},
    All,
    ProcessDirectory -> work,
    ProcessEnvironment -> <|"FERMATPATH" -> fermat|>
  ];
  Export[FileNameJoin[{work, "kira.log"}],
    run["StandardOutput"] <> run["StandardError"], "String"];
  If[run["ExitCode"] =!= 0, Print["KIRA FAILED"]; Exit[1]];
  Module[{files},
    files = FileNames["kira_integrals_*.m",
      FileNameJoin[{work, "results"}], 2];
    Flatten[Get /@ files] /. h_Symbol[idx__Integer] /;
      ToString[h] === familyName :> gli[familyName, {idx}]
  ]
];

derivatives = Association @ Map[# -> computeDerivatives[#] &,
  masterList];
blockBasis = masterList;
kiraRules = {};
iteration = 0;
While[True,
  iteration++;
  If[iteration > 5, Print["CLOSURE DID NOT CONVERGE"]; Exit[1]];
  Module[{needed, solved, dispatch, reduceRaw, appearing, newMembers},
    needed = DeleteDuplicates @ Join[
      blockBasis,
      Cases[Values[derivatives], g_gli, {0, Infinity}]
    ];
    Print["iteration ", iteration, ": ", Length[needed],
      " needed integrals"];
    kiraRules = runKira[needed];
    Print["  rules: ", Length[kiraRules]];
    dispatch = Dispatch[kiraRules];
    reduceRaw[expr_] := cutZero[expr] //. dispatch;
    appearing = DeleteDuplicates @ Cases[
      reduceRaw /@ needed, g_gli, {0, Infinity}];
    newMembers = Complement[appearing, blockBasis];
    If[newMembers === {},
      Print["  CLOSED after iteration ", iteration];
      Break[]
    ];
    Print["  new basis members: ", Length[newMembers]];
    blockBasis = Join[blockBasis, newMembers];
    Scan[
      (derivatives[#] = computeDerivatives[#]) &,
      newMembers
    ]
  ]
];
Print["BLOCK BASIS: ", Length[blockBasis], " (",
  Length[masterList], " canonical + ",
  Length[blockBasis] - Length[masterList], " subsector)"];
dispatchFinal = Dispatch[kiraRules];
reduceRaw[expr_] := cutZero[expr] //. dispatchFinal;

position = AssociationThread[blockBasis, Range[Length[blockBasis]]];
matrixFor[key_] := Map[
  Function[master,
    Module[{red},
      red = Collect[reduceRaw[derivatives[master][key]], _gli, Together];
      Table[
        Together[Coefficient[red, blockBasis[[j]]]],
        {j, Length[blockBasis]}
      ]
    ]
  ],
  blockBasis
];
a13 = matrixFor["dS13"];
a23 = matrixFor["dS23"];
Print["MATRICES BUILT: ", Length[blockBasis], "x", Length[blockBasis]];

dimless = {S12 -> 1, S13 -> Global`v, S23 -> Global`w,
  Global`d -> 4 - 2 Global`eps, D -> 4 - 2 Global`eps};
Av = Together[a13 /. dimless];
Aw = Together[a23 /. dimless];
flat = Together[
  D[Av, Global`w] - D[Aw, Global`v] + Av.Aw - Aw.Av
];
Print["FLATNESS RESIDUAL: ",
  If[Union[Flatten[flat]] === {0}, "ZERO (exact)",
    InputForm[Select[Flatten[flat], # =!= 0 &, 3]]]
];
letters = DeleteDuplicates @ Flatten @ Map[
  FactorList[Denominator[Together[#]]][[All, 1]] &,
  Flatten[{Av, Aw}]
];
Print["ALPHABET: ", InputForm[Select[letters, ! NumberQ[#] &]]];

Put[
  <|
    "Family" -> familyName,
    "BlockBasis" -> blockBasis,
    "CanonicalMasters" -> masterList,
    "Av" -> Av, "Aw" -> Aw,
    "Convention" ->
      "dI/dv = Av.I at 2ka.kb=1, v=2ka.kc, w=2kb.kc; D=4-2eps; cuts " <>
      ToString[cutPositions],
    "KiraWorkspace" -> work
  |>,
  FileNameJoin[{scratch, "nnlo_de_" <> familyName <> ".wl"}]
];
Print["SAVED: nnlo_de_", familyName, ".wl"];
