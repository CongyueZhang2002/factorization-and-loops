(* Exact residue compatibility for a CANONICA off-diagonal strip.

   CANONICA's NextEquationD returns {e,c,bbar,...}, where the diagonal
   connections are eps e and eps c.  We seek a rational gauge D from

     d_mu D = eps (e_mu D - D c_mu) + F_mu,
     F_mu   = bbar_mu - eps Sum_a K_a d_mu log(phi_a).

   Flatness of this inhomogeneous system determines the constant-in-
   kinematics residue matrices K_a, leaving genuine free residues symbolic.
*)

ClearAll[BuildResidueCompatibility];

BuildResidueCompatibility::shape =
  "Expected {e,c,bbar} to contain two equally shaped matrix components.";
BuildResidueCompatibility::canonica =
  "CANONICA functions ExtractIrreducibles and RatFunctionZeroCoeffs are not loaded.";
BuildResidueCompatibility::inconsistent =
  "No residue matrices satisfy the exact strip-compatibility equations.";
BuildResidueCompatibility::certificate =
  "The solved residue rules do not make the exact compatibility residual vanish.";

BuildResidueCompatibility[
    {e_List, c_List, bbar_List}, variables : {_, _}, epsilon_Symbol] :=
 Module[
  {extractIrreducibles, ratFunctionZeroCoeffs, allowEpsDependence,
   dimensions, alphabet, residueTag, rawResidueMatrices, residueVariables,
   dlog, forcing, compatibility, equations, solutions, residueRules,
   residueMatrices, freeResidues, solvedForcing, solvedCompatibility,
   compatibilitySeconds, equationSeconds, solveSeconds},

  If[Length[e] =!= 2 || Length[c] =!= 2 || Length[bbar] =!= 2 ||
     ! SameQ @@ (Dimensions /@ e) || ! SameQ @@ (Dimensions /@ c) ||
     ! SameQ @@ (Dimensions /@ bbar),
   Message[BuildResidueCompatibility::shape]; Return[$Failed]
  ];

  extractIrreducibles = Which[
    DownValues[CANONICA`ExtractIrreducibles] =!= {},
      CANONICA`ExtractIrreducibles,
    DownValues[CANONICA`Private`ExtractIrreducibles] =!= {},
      CANONICA`Private`ExtractIrreducibles,
    True, Missing["NotLoaded"]
  ];
  ratFunctionZeroCoeffs = Which[
    DownValues[CANONICA`RatFunctionZeroCoeffs] =!= {},
      CANONICA`RatFunctionZeroCoeffs,
    DownValues[CANONICA`Private`RatFunctionZeroCoeffs] =!= {},
      CANONICA`Private`RatFunctionZeroCoeffs,
    True, Missing["NotLoaded"]
  ];
  allowEpsDependence = Which[
    NameQ["CANONICA`AllowEpsDependence"],
      CANONICA`AllowEpsDependence,
    NameQ["CANONICA`Private`AllowEpsDependence"],
      CANONICA`Private`AllowEpsDependence,
    True, AllowEpsDependence
  ];
  If[MissingQ[extractIrreducibles] || MissingQ[ratFunctionZeroCoeffs],
   Message[BuildResidueCompatibility::canonica]; Return[$Failed]
  ];

  dimensions = Dimensions[bbar[[1]]];
  alphabet = With[{option = allowEpsDependence},
    Union[
     variables,
     Select[
      extractIrreducibles[{e, c, bbar}, option -> True],
      FreeQ[#, epsilon] &
     ]
    ]
  ];

  residueTag = StringReplace[SymbolName[Unique["r"]], "$" -> "u"];
  rawResidueMatrices = Table[
    Table[
      Symbol["Global`k" <> residueTag <> "a" <> ToString[a] <>
        "i" <> ToString[i] <> "j" <> ToString[j]],
      {i, dimensions[[1]]}, {j, dimensions[[2]]}
    ],
    {a, Length[alphabet]}
  ];
  residueVariables = Flatten[rawResidueMatrices];
  dlog = Table[
    Together[D[Log[alphabet[[a]]], variables[[mu]]]],
    {a, Length[alphabet]}, {mu, 2}
  ];

  forcing = Table[
    bbar[[mu]] - epsilon Sum[
      rawResidueMatrices[[a]] dlog[[a, mu]], {a, Length[alphabet]}],
    {mu, 2}
  ];

  {compatibilitySeconds, compatibility} = AbsoluteTiming[
    Together[
      D[forcing[[2]], variables[[1]]] -
      epsilon (e[[1]].forcing[[2]] - forcing[[2]].c[[1]]) -
      D[forcing[[1]], variables[[2]]] +
      epsilon (e[[2]].forcing[[1]] - forcing[[1]].c[[2]])
    ]
  ];

  {equationSeconds, equations} = AbsoluteTiming[
    DeleteCases[
     DeleteDuplicates@Flatten[
       ratFunctionZeroCoeffs[#, variables] & /@ Flatten[compatibility]
     ],
     0
    ]
  ];

  {solveSeconds, solutions} = AbsoluteTiming[
    Quiet[Solve[Thread[equations == 0], residueVariables]]
  ];
  If[solutions === {},
   Message[BuildResidueCompatibility::inconsistent]; Return[$Failed]
  ];

  residueRules = FixedPoint[
    Function[rules,
      Thread[First /@ rules -> Together[(Last /@ rules) /. rules]]
    ],
    First[solutions],
    50
  ];
  residueMatrices = rawResidueMatrices /. residueRules;
  freeResidues = Select[
    residueVariables,
    ! FreeQ[residueMatrices, #] &
  ];
  solvedForcing = Map[Together, forcing /. residueRules, {3}];
  solvedCompatibility = Map[Together, compatibility /. residueRules, {2}];

  If[! AllTrue[Flatten[solvedCompatibility], TrueQ[# === 0] &],
   Message[BuildResidueCompatibility::certificate]; Return[$Failed]
  ];

  <|
    "Alphabet" -> alphabet,
    "ResidueMatrices" -> residueMatrices,
    "ResidueVariables" -> residueVariables,
    "ResidueRules" -> residueRules,
    "FreeResidues" -> freeResidues,
    "DLog" -> dlog,
    "Forcing" -> solvedForcing,
    "EquationCount" -> Length[equations],
    "CompatibilityZero" -> True,
    "CompatibilitySeconds" -> compatibilitySeconds,
    "EquationSeconds" -> equationSeconds,
    "SolveSeconds" -> solveSeconds
  |>
 ]
