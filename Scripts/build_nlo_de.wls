(* Differential equations for the 7 NLO UU masters.

   Construction: Euler operators ka.d/dka, kb.d/dkb, kc.d/dkc applied
   under the integral sign; loop scalar products rewritten through the
   family's propagators; the resulting raised/lowered-index integrals
   reduced by a dedicated small Kira run (the stored amplitude rules
   never raise a cut index).  Output: connection matrices Av, Aw in
   v = 2ka.kc/(2ka.kb), w = 2kb.kc/(2ka.kb), with the flatness check
   dw Av - dv Aw + [Av, Aw] = 0 as the end-to-end certificate. *)

root = "/home/maxzhang/factorization-and-loops";
scratch = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad";
work = FileNameJoin[{scratch, "nlo_de_kira"}];

S12 = Global`ffecfp1; S13 = Global`ffecfp2; S23 = Global`ffecfp3;

(* Family definitions: propagator momenta over {ke; ka, kb, kc},
   matching the stored FCTopology records; cut indices {1, 4}. *)
families = <|
  "TopologyF10C10N1" -> {ke, -kc - ke, ka - kc - ke, ka + kb - kc - ke},
  "TopologyF10C2N2" -> {ke, -kb + ke, -kc - ke, ka + kb - kc - ke},
  "TopologyF10C4N2" -> {ke, -kb + kc + ke, -kc - ke, ka + kb - kc - ke},
  "TopologyF10C4N3" -> {ke, -kb + kc + ke, ka - kc - ke, ka + kb - kc - ke},
  "TopologyF10C5N2" -> {ke, -ka + ke, -kc - ke, ka + kb - kc - ke},
  "TopologyF10C5N3" -> {ke, -ka + ke, ka - kc - ke, ka + kb - kc - ke}
|>;
cutPositions = {1, 4};

masterList = {
  gli["TopologyF10C10N1", {1, 0, 0, 1}],
  gli["TopologyF10C10N1", {1, 1, 1, 1}],
  gli["TopologyF10C2N2", {1, 1, 1, 1}],
  gli["TopologyF10C4N2", {1, 1, 1, 1}],
  gli["TopologyF10C4N3", {1, 1, 1, 1}],
  gli["TopologyF10C5N2", {1, 1, 1, 1}],
  gli["TopologyF10C5N3", {1, 1, 1, 1}]
};

(* --- scalar-product algebra over the basis {ke, ka, kb, kc} ------- *)
basis = {ke, ka, kb, kc};
(* Keys stored in Sort order, matching the lookup below. *)
gram = <|
  Sort[{ke, ke}] -> spEE, Sort[{ke, ka}] -> spEA,
  Sort[{ke, kb}] -> spEB, Sort[{ke, kc}] -> spEC,
  Sort[{ka, ka}] -> 0, Sort[{kb, kb}] -> 0, Sort[{kc, kc}] -> 0,
  Sort[{ka, kb}] -> S12/2, Sort[{ka, kc}] -> S13/2,
  Sort[{kb, kc}] -> S23/2
|>;
pairSP[p_, q_] := Lookup[gram, Key[Sort[{p, q}]]];
vec[m_] := Coefficient[m, #] & /@ basis;
sp[m1_, m2_] := Module[{v1 = vec[m1], v2 = vec[m2]},
  Sum[
    v1[[i]] v2[[j]] pairSP[basis[[i]], basis[[j]]],
    {i, 4}, {j, 4}
  ]
];
loopSPs = {spEE, spEA, spEB, spEC};

(* Per family: solve the loop scalar products from the propagators. *)
propagatorSymbols = {dd1, dd2, dd3, dd4};
solveTables = Association @ KeyValueMap[
  Function[{name, momenta},
    Module[{expansions, solution},
      expansions = Expand[sp[#, #]] & /@ momenta;
      solution = Solve[
        Thread[propagatorSymbols == expansions], loopSPs
      ];
      If[Length[solution] =!= 1,
        Print["INCOMPLETE FAMILY: ", name]; Exit[1]];
      name -> First[solution]
    ]
  ],
  families
];

(* Cut rule: a cut index at or below zero kills the integral. *)
cutZero[expr_] := expr /. gli[f_, idx_] /;
  Min[idx[[cutPositions]]] <= 0 -> 0;

(* Euler operator v.d/dv on gli[fam, nu]:
   contribution from propagator j is
   -nu_j * 2 * (coefficient of v in m_j) * sp(v, m_j) * gli[nu + e_j],
   with loop scalar products replaced through the propagators and
   dd_k * gli[nu'] -> gli[nu' - e_k]. *)
euler[v_, gli[fam_, nu_]] := Module[{momenta, table, total},
  momenta = families[fam];
  table = solveTables[fam];
  total = Sum[
    Module[{cv, weight, raised},
      cv = Coefficient[momenta[[j]], v];
      If[cv === 0 || nu[[j]] === 0,
        0,
        weight = Expand[-nu[[j]] 2 cv sp[v, momenta[[j]]] /. table];
        raised = ReplacePart[nu, j -> nu[[j]] + 1];
        cutZero @ Expand[
          (weight /. Thread[propagatorSymbols -> 0]) gli[fam, raised] +
          Sum[
            Coefficient[weight, propagatorSymbols[[k]]] *
              gli[fam, ReplacePart[raised, k -> raised[[k]] - 1]],
            {k, 4}
          ]
        ]
      ]
    ],
    {j, 4}
  ];
  total
];

(* d/dS13 = (Oa - Ob + Oc)/(2 S13); d/dS23 = (-Oa + Ob + Oc)/(2 S23) *)
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

(* Every integral the reduction must cover. *)
targets = DeleteDuplicates @ Join[
  masterList,
  Cases[Values[derivatives], gli[f_, i_] :> gli[f, i], {0, Infinity}]
];
Print["TARGETS: ", Length[targets]];

(* --- write and run the Kira project ------------------------------- *)
If[DirectoryQ[work], DeleteDirectory[work, DeleteContents -> True]];
CreateDirectory[FileNameJoin[{work, "config"}],
  CreateIntermediateDirectories -> True];

familyNames = Keys[families];
familyBlocks = Map[
  Function[name,
    StringJoin[
      "  - name: ", name, "\n",
      "    loop_momenta: [ke]\n",
      "    top_level_sectors: [b1111]\n",
      "    cut_propagators: [1, 4]\n",
      "    propagators:\n",
      StringJoin @@ Map[
        "      - [ \"" <> ToString[#, InputForm] <> "\", 0]\n" &,
        families[name]
      ]
    ]
  ],
  familyNames
];
Export[FileNameJoin[{work, "config", "integralfamilies.yaml"}],
  "integralfamilies:\n" <> StringJoin[familyBlocks], "String"];

Export[FileNameJoin[{work, "config", "kinematics.yaml"}],
"kinematics:
  incoming_momenta: [ka, kb, kc]
  outgoing_momenta: []
  momentum_conservation: []
  kinematic_invariants:
    - [ffecfp1, 2]
    - [ffecfp2, 2]
    - [ffecfp3, 2]
  scalarproduct_rules:
    - [ [ ka, ka],0]
    - [ [ kb, kb],0]
    - [ [ kc, kc],0]
    - [ [ ka, kb],ffecfp1/2]
    - [ [ ka, kc],ffecfp2/2]
    - [ [ kb, kc],ffecfp3/2]
", "String"];

Do[
  Module[{mine},
    mine = Cases[targets, gli[familyNames[[n]], idx_] :> idx];
    Export[
      FileNameJoin[{work, "integrals_" <> ToString[n]}],
      StringRiffle[
        (familyNames[[n]] <> "[" <> StringRiffle[ToString /@ #, ","] <>
          "]") & /@ Sort[mine],
        "\n"
      ] <> "\n",
      "String"
    ]
  ],
  {n, Length[familyNames]}
];

jobLines = Join[
  {"jobs:", "  - reduce_sectors:", "      reduce:"},
  Flatten @ Table[
    {
      "        - {topologies: [" <> familyNames[[n]] <>
        "], sectors: [b1111], r: 7, s: 2 }",
      "        - {topologies: [" <> familyNames[[n]] <>
        "], sectors: [b1001], r: 4, s: 2 }"
    },
    {n, Length[familyNames]}
  ],
  {"      select_integrals:", "        select_mandatory_list:"},
  Table[
    "          - [" <> familyNames[[n]] <> ", \"integrals_" <>
      ToString[n] <> "\"]",
    {n, Length[familyNames]}
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
    "        - [" <> familyNames[[n]] <> ", \"integrals_" <>
      ToString[n] <> "\"]",
    {n, Length[familyNames]}
  ]
];
Export[FileNameJoin[{work, "jobs.yaml"}],
  StringRiffle[jobLines, "\n"] <> "\n", "String"];

kiraExe = FileNameJoin[{root, "Addon", "Other_Addon", "Kira", "bin", "kira"}];
fermat = FileNameJoin[{root, "Addon", "Other_Addon", "Kira", "bin", "fer64"}];
Print["Running Kira..."];
run = RunProcess[
  {kiraExe, "--parallel=8", "jobs.yaml"},
  All,
  ProcessDirectory -> work,
  ProcessEnvironment -> <|"FERMATPATH" -> fermat|>
];
Export[FileNameJoin[{work, "kira.log"}],
  run["StandardOutput"] <> run["StandardError"], "String"];
Print["KIRA EXIT: ", run["ExitCode"]];
If[run["ExitCode"] =!= 0, Exit[1]];

(* --- import the reduction and build the connection ----------------- *)
ruleFiles = FileNames["kira_integrals_*.m",
  FileNameJoin[{work, "results"}], 2];
Print["RULE FILES: ", Length[ruleFiles]];
kiraRules = Flatten[Get /@ ruleFiles];
(* head[indices__] -> gli[name, {indices}] *)
toGLI = expr_ /; MemberQ[familyNames, ToString[Head[expr]]] :>
  gli[ToString[Head[expr]], List @@ expr];
kiraRules = kiraRules /. h_Symbol[idx__Integer] /;
  MemberQ[familyNames, ToString[h]] :> gli[ToString[h], {idx}];
Print["RULES: ", Length[kiraRules]];

reduce[expr_] := Together[
  cutZero[expr] //. Dispatch[kiraRules]
];

(* Verify closure and build matrices. *)
position = AssociationThread[masterList, Range[Length[masterList]]];
matrixFor[key_] := Module[{rows},
  rows = Map[
    Function[master,
      Module[{red, leftover},
        red = Collect[reduce[derivatives[master][key]], _gli, Together];
        leftover = DeleteDuplicates @ Cases[
          {red}, g_gli /; ! KeyExistsQ[position, g], {0, Infinity}
        ];
        If[leftover =!= {},
          Print["UNREDUCED in ", InputForm[master], " ", key, ": ",
            InputForm[leftover]];
          Exit[1]
        ];
        Table[
          Together[Coefficient[red, masterList[[j]]]],
          {j, Length[masterList]}
        ]
      ]
    ],
    masterList
  ];
  rows
];

a13 = matrixFor["dS13"];
a23 = matrixFor["dS23"];
Print["MATRICES BUILT"];

(* Dimensionless: S12 -> 1, S13 -> v, S23 -> w (homogeneity restores
   the overall S12 power).  D -> 4 - 2 eps. *)
(* Bare D below is System`D, the symbol Kira's tables use for the
   dimension; replacing it in an expression is legal even though the
   symbol is Protected. *)
dimless = {S12 -> 1, S13 -> Global`v, S23 -> Global`w,
  D -> 4 - 2 Global`eps};
Av = Together[a13 /. dimless];
Aw = Together[a23 /. dimless];

(* Flatness: dw Av - dv Aw + Av.Aw - Aw.Av == 0 *)
flat = Together[
  D[Av, Global`w] - D[Aw, Global`v] + Av.Aw - Aw.Av
];
Print["FLATNESS RESIDUAL: ",
  If[flat === Table[0, {7}, {7}] || Union[Flatten[flat]] === {0},
    "ZERO (exact)",
    InputForm[Select[Flatten[flat], # =!= 0 &, 3]]
  ]
];

(* Denominator alphabet of the connection. *)
letters = DeleteDuplicates @ Flatten @ Map[
  FactorList[Denominator[Together[#]]][[All, 1]] &,
  Flatten[{Av, Aw}]
];
Print["ALPHABET (denominators): ", InputForm[letters]];

Put[
  <|
    "Masters" -> masterList,
    "Av" -> Av,
    "Aw" -> Aw,
    "Variables" -> {Global`v, Global`w, Global`eps},
    "Convention" -> "dI/dv = Av.I, dI/dw = Aw.I; v = 2ka.kc/2ka.kb, w = 2kb.kc/2ka.kb, S12 = 2ka.kb -> 1; D = 4 - 2 eps; cut propagators {1,4}",
    "KiraWorkspace" -> work
  |>,
  FileNameJoin[{scratch, "nlo_de_system.wl"}]
];
Print["SAVED: nlo_de_system.wl"];
