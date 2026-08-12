(* Write the solved NLO UU masters as a repo artifact, in pipeline
   conventions (FeynCalc GLI heads, Global`Epsilon). *)
root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
scratch = "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad";
exact = Get[FileNameJoin[{scratch, "nlo_masters_exact.wl"}]];
system = Get[FileNameJoin[{scratch, "nlo_de_system.wl"}]];

eps = Global`Epsilon; vv = Global`v; ww = Global`w;
toPipeline = {ep -> eps, Global`eps -> eps, Global`d -> 4 - 2 eps,
  v -> vv, w -> ww};

volN = (2^(1 - (4 - 2 eps)) 2 Pi^((3 - 2 eps)/2)/
  Gamma[(3 - 2 eps)/2]);
vol = volN (1 - vv - ww)^(-eps);

(* soft-surface connection: F(1,1;1-e;z) =
     c1 F(1,1;2+e;1-z) + c2 (1-z)^(-1-e) z^e  (checked numerically) *)
c1soft = Gamma[1 - eps] Gamma[-1 - eps]/Gamma[-eps]^2;
c2soft = Gamma[1 - eps] Gamma[1 + eps];
softCheck = Module[{e = -3/20, z = 7/10},
  Abs @ N[
    (Hypergeometric2F1[1, 1, 1 - e, z] -
      ((c1soft /. eps -> e) Hypergeometric2F1[1, 1, 2 + e, 1 - z] +
       (c2soft /. eps -> e) (1 - z)^(-1 - e) z^e)) /
    Hypergeometric2F1[1, 1, 1 - e, z], 20]
];
If[! TrueQ[softCheck < 10^-18],
  Print["SOFT CONNECTION CHECK FAILED: ", softCheck]; Exit[1]];
Print["soft connection check: ", N[softCheck, 3]];

masters = system["Masters"] /. gli -> List;
gliOf[{name_, idx_}] := FeynCalc`GLI[Symbol[name], idx];

entries = <|gliOf[masters[[1]]] -> <|
  "Exact" -> vol,
  "SoftBranches" -> {
    <|"Exponent" -> -eps, "Coefficient" -> volN|>
  }
|>|>;
KeyValueMap[
  Function[{i, sol},
    Module[{z, R, cc, exactExpr, zAtSurface, branches},
      z = sol["z"] /. toPipeline;
      R = sol["R"] /. toPipeline;
      cc = sol["cc"] /. toPipeline;
      exactExpr = cc (1 - vv - ww)^(-eps) R *
        Hypergeometric2F1[1, 1, 1 - eps, z];
      zAtSurface = Limit[z /. ww -> 1 - vv - delta, delta -> 0,
        Direction -> "FromAbove"];
      branches = If[TrueQ[Simplify[zAtSurface] == 1],
        (* two branches via the soft connection; the second is
           elementary: (1-z)^(-1-eps) z^eps *)
        {
          <|"Exponent" -> -eps,
            "Coefficient" ->
              cc R c1soft Hypergeometric2F1[1, 1, 2 + eps, 1 - z]|>,
          <|"Exponent" -> -1 - 2 eps,
            "Coefficient" -> cc R c2soft *
              Simplify[((1 - z)/(1 - vv - ww))]^(-1 - eps) z^eps|>
        },
        {
          <|"Exponent" -> -eps,
            "Coefficient" -> cc R Hypergeometric2F1[1, 1, 1 - eps, z]|>
        }
      ];
      entries[gliOf[masters[[i]]]] = <|
        "Exact" -> exactExpr,
        "CrossRatio" -> z,
        "PrefactorR" -> R,
        "Normalization" -> cc,
        "SoftBranches" -> branches
      |>
    ]
  ],
  exact["Solutions"]
];

artifact = <|
  "Format" -> "FeynFacet-NLOMasters",
  "FormatVersion" -> 1,
  "Created" -> DateString[],
  "Conventions" -> <|
    "Measure" ->
      "GLI = Int d^d ke delta+(ke^2) delta+((ka+kb-kc-ke)^2) / (D2 D3), no 2Pi factors",
    "Dimension" -> (Global`D -> 4 - 2 eps),
    "Variables" -> <|
      vv -> "2 ka.kc / 2 ka.kb", ww -> "2 kb.kc / 2 ka.kb",
      "Region" -> "0 < v, 0 < w, v + w < 1"
    |>,
    "ScaleRestoration" ->
      "multiply by (2 ka.kb)^h, h = -Epsilon (volume) or -2-Epsilon (four-index masters)",
    "SoftConnection" ->
      "F(1,1;1-e;z) = c1 F(1,1;2+e;1-z) + c2 (1-z)^(-1-e) z^e",
    "VolumeNormalization" -> volN
  |>,
  "Masters" -> entries,
  "DifferentialSystem" -> <|
    "Basis" -> gliOf /@ masters,
    "Av" -> (system["Av"] /. toPipeline),
    "Aw" -> (system["Aw"] /. toPipeline),
    "Convention" -> "dI/dv = Av.I, dI/dw = Aw.I at 2 ka.kb = 1"
  |>,
  "Validation" -> <|
    "FlatnessResidual" -> 0,
    "NumericAgreement" ->
      "two-angle phase-space integration, 5 (v,w,eps) points: ratios 1 within numeric precision (1e-18 at eps=-0.15, 1e-4 at eps=-0.05)",
    "CrossImplementation" ->
      "shared family TopologyF10C2N2 matches the independent Codex evaluation after the (2Pi)^(d-2) measure conversion"
  |>
|>;

file = FileNameJoin[{root, "ppHX_NLO", "Results", "NLO_UU_Masters.wl"}];
Put[artifact, file];
Print["WROTE: ", file, " (", FileByteCount[file], " bytes)"];
