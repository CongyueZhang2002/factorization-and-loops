(* Global two-loop DE system on the canonical 347-master basis.

   Routes the Euler-derivative reduction of ALL canonical masters
   through the full 374-family canonical Kira configuration, so
   subsector integrals land on canonical names and the 91 standalone
   blocks consolidate into one system.  Stages checkpoint to a
   persistent workspace and the script resumes after interruption:

     A: derivative construction for all masters      (targets.wl)
     B: full Kira job                                 (kira workspace)
     C: import + closure (iterate A'/B on extension)  (rules import)
     D: global matrices + flatness                    (GlobalSystem.wl)

   Usage: wolframscript -file Scripts/build_nnlo_global_de.wls *)

root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
work = FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Kira",
  "UU_08_12_derivatives"}];
If[! DirectoryQ[work],
  CreateDirectory[work, CreateIntermediateDirectories -> True]];

S12 = Global`ffecfp1; S13 = Global`ffecfp2; S23 = Global`ffecfp3;

registry = FeynFacet`Private`coefficientReadRecord[
  FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "CanonicalRegistry.wxf"}]];
familyRecords = registry["Registry"]["Families"];
recordOf = Association @ Map[
  ToString[#["Name"]] -> # &, familyRecords];

manifest = FeynFacet`Private`coefficientReadRecord[
  FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal",
    "CoefficientSimplification", "UU_08_10_canonical",
    "FiniteFieldCanonical", "TraceManifest.wxf"}]];
canonicalMasters = manifest["TraceData"]["Masters"];
Print["CANONICAL MASTERS: ", Length[canonicalMasters]];

(* --- per-family Euler machinery (as in the per-family blocks) ------ *)
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
dExpression[{"Quad", m_}] := Expand[sp[m, m]];
dExpression[{"Bil", a_, b_}] := Expand[sp[a, b]];
eulerWeight[v_, {"Quad", m_}] := 2 Coefficient[m, v] sp[v, m];
eulerWeight[v_, {"Bil", a_, b_}] :=
  Coefficient[a, v] sp[v, b] + Coefficient[b, v] sp[v, a];

familyData = <||>;
familyFor[name_String] := Lookup[familyData, name,
  familyData[name] = Module[
    {record, propagators, nProps, solution},
    record = recordOf[name];
    propagators = parseProp /@ record["Topology"][[2]];
    nProps = Length[propagators];
    solution = Solve[
      Thread[Array[dd, nProps] == (dExpression /@ propagators)],
      loopSPs
    ];
    If[Length[solution] =!= 1,
      Print["INCOMPLETE FAMILY ", name]; Exit[1]];
    <|
      "Propagators" -> propagators,
      "N" -> nProps,
      "SolveTable" -> First[solution],
      "Cuts" -> Sort[record["CutIndices"]]
    |>
  ]
];

cutZeroFor[name_String][expr_] := With[
  {cuts = familyFor[name]["Cuts"]},
  expr /. gli[f_, idx_] /; Min[idx[[cuts]]] <= 0 -> 0
];

euler[v_, gli[fam_, nu_]] := Module[
  {fd = familyFor[fam], propagators, nProps, table},
  propagators = fd["Propagators"]; nProps = fd["N"];
  table = fd["SolveTable"];
  Sum[
    Module[{weightRaw, weight, raised},
      weightRaw = eulerWeight[v, propagators[[j]]];
      If[weightRaw === 0 || nu[[j]] === 0,
        0,
        weight = Expand[-nu[[j]] weightRaw /. table];
        raised = ReplacePart[nu, j -> nu[[j]] + 1];
        cutZeroFor[fam] @ Expand[
          (weight /. Thread[Array[dd, nProps] -> 0]) gli[fam, raised] +
          Sum[
            Coefficient[weight, dd[k]] *
              gli[fam, ReplacePart[raised, k -> raised[[k]] - 1]],
            {k, nProps}
          ]
        ]
      ]
    ],
    {j, nProps}
  ]
];
computeDerivatives[master_gli] := Module[{oa, ob, oc},
  {oa, ob, oc} = euler[#, master] & /@ {ka, kb, kc};
  <|
    "dS13" -> Together[(oa - ob + oc)/(2 S13)],
    "dS23" -> Together[(-oa + ob + oc)/(2 S23)]
  |>
];

masterGli[FeynCalc`GLI[name_, idx_]] := gli[ToString[name], idx];
masterList = masterGli /@ canonicalMasters;

(* --- stage A: derivatives (checkpointed) --------------------------- *)
derivativesFile = FileNameJoin[{work, "derivatives.wl"}];
derivatives = If[FileExistsQ[derivativesFile],
  Print["A: restoring derivatives"];
  Get[derivativesFile],
  Module[{d},
    Print["A: constructing derivatives for ", Length[masterList],
      " masters"];
    d = Association @ Map[# -> computeDerivatives[#] &, masterList];
    Put[d, derivativesFile];
    d
  ]
];
Print["A: derivatives for ", Length[derivatives], " integrals"];

(* --- stage B/C loop ------------------------------------------------- *)
kiraExe = FileNameJoin[{root, "Addon", "Other_Addon", "Kira", "bin",
  "kira"}];
fermat = FileNameJoin[{root, "Addon", "Other_Addon", "Kira", "bin",
  "fer64"}];
configSource = FileNameJoin[{root, "Codex", "ppHX_NNLO_DoubleReal",
  "Kira", "UU_08_10_canonical", "kira", "config"}];
productionYaml = Import[
  FileNameJoin[{configSource, "integralfamilies.yaml"}], "Text"];

sectorOf[name_String] := Module[{block, bits},
  block = StringCases[productionYaml,
    "  - name: " <> name <> "\n" ~~ Shortest[body___] ~~
      ("\n  - name: " | EndOfString) :> body];
  bits = StringCases[First[block],
    "top_level_sectors: [b" ~~ b : (("0" | "1") ..) ~~ "]" :> b];
  "b" <> First[bits]
];

runKiraGlobal[targets_List, iteration_Integer] := Module[
  {kdir, byFamily, names, jobLines, run, maxR, maxS},
  kdir = FileNameJoin[{work, "kira_" <> ToString[iteration]}];
  If[FileNames["kira_integrals_*.m", kdir, 3] =!= {},
    Print["B: iteration ", iteration, " already solved"],
    If[DirectoryQ[kdir],
      DeleteDirectory[kdir, DeleteContents -> True]];
    CreateDirectory[FileNameJoin[{kdir, "config"}],
      CreateIntermediateDirectories -> True];
    CopyFile[FileNameJoin[{configSource, "integralfamilies.yaml"}],
      FileNameJoin[{kdir, "config", "integralfamilies.yaml"}]];
    CopyFile[FileNameJoin[{configSource, "kinematics.yaml"}],
      FileNameJoin[{kdir, "config", "kinematics.yaml"}]];
    byFamily = GroupBy[targets, First -> Last];
    names = Sort[Keys[byFamily]];
    Do[
      Export[
        FileNameJoin[{kdir,
          "integrals_" <> ToString[Position[names, nm][[1, 1]]]}],
        StringRiffle[
          (nm <> "[" <> StringRiffle[ToString /@ #, ","] <> "]") & /@
            Sort[byFamily[nm]],
          "\n"
        ] <> "\n",
        "String"
      ],
      {nm, names}
    ];
    jobLines = Join[
      {"jobs:", "  - reduce_sectors:", "      reduce:"},
      Table[
        Module[{idx = byFamily[nm]},
          maxR = Max[Total[Select[#, Positive]] & /@ idx];
          maxS = Max[0, Max[-Total[Select[#, Negative]] & /@ idx]];
          "        - {topologies: [" <> nm <> "], sectors: [" <>
            sectorOf[nm] <> "], r: " <> ToString[maxR + 1] <>
            ", s: " <> ToString[maxS + 1] <> " }"
        ],
        {nm, names}
      ],
      {"      select_integrals:", "        select_mandatory_list:"},
      Table[
        "          - [" <> nm <> ", \"integrals_" <>
          ToString[Position[names, nm][[1, 1]]] <> "\"]",
        {nm, names}
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
        "        - [" <> nm <> ", \"integrals_" <>
          ToString[Position[names, nm][[1, 1]]] <> "\"]",
        {nm, names}
      ]
    ];
    Export[FileNameJoin[{kdir, "jobs.yaml"}],
      StringRiffle[jobLines, "\n"] <> "\n", "String"];
    Print["B: Kira iteration ", iteration, ": ", Length[targets],
      " targets over ", Length[names], " families"];
    run = RunProcess[
      {kiraExe, "--parallel=14", "jobs.yaml"},
      All,
      ProcessDirectory -> kdir,
      ProcessEnvironment -> <|"FERMATPATH" -> fermat|>
    ];
    Export[FileNameJoin[{kdir, "kira.log"}],
      run["StandardOutput"] <> run["StandardError"], "String"];
    If[run["ExitCode"] =!= 0, Print["KIRA FAILED"]; Exit[1]]
  ];
  Module[{files},
    files = FileNames["kira_integrals_*.m",
      FileNameJoin[{kdir, "results"}], 2];
    Flatten[Get /@ files] /. h_Symbol[idx__Integer] /;
      KeyExistsQ[recordOf, ToString[h]] :>
        gli[ToString[h], {idx}]
  ]
];

cutZeroAll[expr_] := expr /. g : gli[f_, idx_] :>
  With[{cuts = familyFor[f]["Cuts"]},
    If[Min[idx[[cuts]]] <= 0, 0, g]];

blockBasis = masterList;
kiraRules = {};
iteration = 0;
While[True,
  iteration++;
  If[iteration > 4, Print["NO CONVERGENCE"]; Exit[1]];
  Module[{needed, dispatch, reduceRaw, appearing, newMembers},
    needed = DeleteDuplicates @ Join[
      blockBasis,
      Cases[Values[derivatives], g_gli, {0, Infinity}]
    ];
    kiraRules = runKiraGlobal[needed, iteration];
    Print["C: rules ", Length[kiraRules]];
    dispatch = Dispatch[kiraRules];
    reduceRaw[expr_] := cutZeroAll[expr] //. dispatch;
    appearing = DeleteDuplicates @ Cases[
      reduceRaw /@ needed, g_gli, {0, Infinity}];
    newMembers = Complement[appearing, blockBasis];
    If[newMembers === {},
      Print["C: CLOSED after iteration ", iteration];
      Break[]
    ];
    Print["C: ", Length[newMembers], " new basis members"];
    blockBasis = Join[blockBasis, newMembers];
    Scan[(derivatives[#] = computeDerivatives[#]) &, newMembers];
    Put[derivatives, derivativesFile]
  ]
];
Print["GLOBAL BASIS: ", Length[blockBasis], " (",
  Length[masterList], " canonical + ",
  Length[blockBasis] - Length[masterList], " extra)"];

dispatchFinal = Dispatch[kiraRules];
reduceRaw[expr_] := cutZeroAll[expr] //. dispatchFinal;
matrixFor[key_] := Map[
  Function[m,
    Module[{red},
      red = Collect[reduceRaw[derivatives[m][key]], _gli, Together];
      Table[
        Together[Coefficient[red, blockBasis[[j]]]],
        {j, Length[blockBasis]}
      ]
    ]
  ],
  blockBasis
];
a13 = matrixFor["dS13"];
Print["D: Av built"];
a23 = matrixFor["dS23"];
Print["D: Aw built"];
dimless = {S12 -> 1, S13 -> Global`v, S23 -> Global`w,
  Global`d -> 4 - 2 Global`eps, D -> 4 - 2 Global`eps};
Av = Together[a13 /. dimless];
Aw = Together[a23 /. dimless];
flat = Together[
  D[Av, Global`w] - D[Aw, Global`v] + Av.Aw - Aw.Av
];
flatZero = (Union[Flatten[flat]] === {0});
Print["FLATNESS: ", If[flatZero, "ZERO (exact)", "NONZERO!"]];
letters = DeleteDuplicates @ Flatten @ Map[
  FactorList[Denominator[Together[#]]][[All, 1]] &,
  Flatten[{Av, Aw}]
];
Put[
  <|
    "Basis" -> (blockBasis /.
      gli[f_, i_] :> FeynCalc`GLI[Symbol[f], i]),
    "CanonicalMasters" -> canonicalMasters,
    "Av" -> Av, "Aw" -> Aw,
    "FlatnessZero" -> flatZero,
    "Alphabet" -> letters,
    "Convention" ->
      "dI/dv = Av.I, dI/dw = Aw.I at 2ka.kb = 1; v = 2ka.kc, w = 2kb.kc; D = 4-2eps"
  |>,
  FileNameJoin[{root, "ppHX_NNLO_DoubleReal", "Results",
    "UU_08_10_canonical", "DifferentialEquations",
    "GlobalSystem.wl"}]
];
Print["SAVED GlobalSystem.wl"];
