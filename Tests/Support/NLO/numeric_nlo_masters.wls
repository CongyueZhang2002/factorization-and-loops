(* Independent numeric evaluation of the 7 NLO masters.

   In the rest frame of P = ka+kb-kc (P^2 = M^2 = 1-v-w at S12=1) the
   cut integral collapses to a two-angle integral:
     GLI = (M/2)^(d-3)/(4M) * Omega_{d-3} *
           Int_0^Pi dth sin^{d-3}th Int_0^Pi dph sin^{d-4}ph / (D2 D3),
   with D_j = K_j^2 + M K_j^0 - M |Kvec_j| (cos x_j cos th +
   sin x_j sin th cos ph) for propagator (ke + K_j)^2, z-axis along
   Kvec_2.  Valid for eps < 0 (collinear edges integrable).  Usage:
     wolframscript -file numeric_nlo_masters.wls v w eps prec *)

(* usage: v w |eps| [prec] -- eps is NEGATED internally, since
   wolframscript swallows dash-prefixed arguments as options. *)
args = Rest[$ScriptCommandLine];
If[Length[args] < 3, Print["NEED: v w |eps| [prec]"]; Exit[1]];
{vN, wN, epsN} = ToExpression /@ Take[args, 3];
epsN = -Abs[epsN];
prec = If[Length[args] >= 4, ToExpression[args[[4]]], 30];
If[! (NumericQ[vN] && NumericQ[wN] && NumericQ[epsN]),
  Print["BAD ARGS: ", InputForm[args]]; Exit[1]];

vN = Rationalize[vN, 0]; wN = Rationalize[wN, 0];
epsN = Rationalize[epsN, 0];
d = 4 - 2 epsN;
M2 = 1 - vN - wN; M = Sqrt[M2];

(* Frame: energies from 2k.P, unit spatial vectors from invariants. *)
Ea = (1 - vN)/(2 M); Eb = (1 - wN)/(2 M); Ec = (vN + wN)/(2 M);
cosAB = (Ea Eb - 1/2)/(Ea Eb);
cosAC = (Ea Ec - vN/2)/(Ea Ec);
cosBC = (Eb Ec - wN/2)/(Eb Ec);
ea = {0, 0, 1};
eb = {Sqrt[1 - cosAB^2], 0, cosAB};
ecx = (cosBC - cosAB cosAC)/Sqrt[1 - cosAB^2];
ec = {ecx, Sqrt[1 - cosAC^2 - ecx^2], cosAC};
(* four-vectors {E, vec} *)
ka4 = {Ea, Ea ea}; kb4 = {Eb, Eb eb}; kc4 = {Ec, Ec ec};
minkSP[{e1_, p1_}, {e2_, p2_}] := e1 e2 - p1.p2;

(* consistency *)
check = {
  2 minkSP[ka4, kb4] - 1, 2 minkSP[ka4, kc4] - vN,
  2 minkSP[kb4, kc4] - wN
};
If[! TrueQ[Max[Abs[N[check, 30]]] < 10^-20],
  Print["FRAME FAILED: ", InputForm[N[check, 5]]]; Exit[1]];

families = <|
  "TopologyF10C10N1" -> {-kc - ke, ka - kc - ke},
  "TopologyF10C2N2" -> {-kb + ke, -kc - ke},
  "TopologyF10C4N2" -> {-kb + kc + ke, -kc - ke},
  "TopologyF10C4N3" -> {-kb + kc + ke, ka - kc - ke},
  "TopologyF10C5N2" -> {-ka + ke, -kc - ke},
  "TopologyF10C5N3" -> {-ka + ke, ka - kc - ke}
|>;
vectors = <|ka -> ka4, kb -> kb4, kc -> kc4|>;

kVector[m_] := Module[{sign, shift},
  sign = Coefficient[m, ke];
  shift = Expand[sign m /. ke -> 0];
  (* K as a numeric 4-vector *)
  Sum[
    Coefficient[shift, s] vectors[s],
    {s, {ka, kb, kc}}
  ]
];

omega[n_] := 2 Pi^(n/2)/Gamma[n/2];

(* phi-integral in closed form:
     Int_0^Pi sin^(d-4)phi/(A - B cos phi) dphi
       = Beta[(d-3)/2, 1/2] A^-1 2F1[1/2, 1; (d-2)/2; B^2/A^2]
   (verified numerically below); the remaining x-integral is 1D with
   its interior singular points (the massless collinear cone of the
   second propagator, A^2 = B^2) passed to NIntegrate explicitly. *)
phiIntegral[A_, B_] := Beta[(d - 3)/2, 1/2] *
  Hypergeometric2F1[1/2, 1, (d - 2)/2, B^2/A^2]/A;

phiCheck = Module[{A = 17/8, B = 6/7, direct},
  direct = NIntegrate[
    N[Sin[ph]^(d - 4)/(A - B Cos[ph]), 40],
    {ph, 0, Pi}, WorkingPrecision -> 30, PrecisionGoal -> 20
  ];
  Abs[N[phiIntegral[A, B]/direct - 1, 20]]
];
If[! TrueQ[phiCheck < 10^-15],
  Print["PHI FORMULA CHECK FAILED: ", phiCheck]; Exit[1]
];
Print["phi formula check: ", N[phiCheck, 3]];

angularMaster[K2_, K3_] := Module[
  {a2, a3, b2, b3, x23, den2, AA, BB, roots, splits, integrand,
   value, stableLinear},
  a2 = minkSP[K2, K2] + M K2[[1]];
  a3 = minkSP[K3, K3] + M K3[[1]];
  b2 = M Sqrt[K2[[2]].K2[[2]]]; b3 = M Sqrt[K3[[2]].K3[[2]]];
  x23 = If[b2 == 0 || b3 == 0, 0,
    M^2 K2[[2]].K3[[2]]/(b2 b3)];
  stableLinear[a_, b_] := Which[
    TrueQ[FullSimplify[a - b] == 0], 2 b xx,
    TrueQ[FullSimplify[a + b] == 0], -2 b (1 - xx),
    True, (a - b) + 2 b xx
  ];
  den2 = stableLinear[a2, b2];
  (* cos th = 1 - 2 xx, sin th = 2 Sqrt[xx(1-xx)] *)
  AA = a3 - b3 x23 (1 - 2 xx);
  BB = 2 b3 Sqrt[1 - x23^2] Sqrt[xx (1 - xx)];
  roots = Select[
    xx /. Solve[AA^2 - BB^2 == 0 && 0 < xx < 1, xx, Reals],
    NumericQ
  ];
  splits = Sort[N[roots, prec + 10]];
  (* Stable 2F1 via the z -> 1-z connection with the ELEMENTARY
     second branch:
       F(1/2,1;1-ep;z) = A1 F(1/2,1;3/2+ep;1-z)
                         + A2 (1-z)^(-1/2-ep) z^ep,
       A1 = Gamma[1-ep]Gamma[-1/2-ep]/(Gamma[1/2-ep]Gamma[-ep]),
       A2 = Gamma[1-ep]Gamma[1/2+ep]/Sqrt[Pi],
     and 1-z = (A^2-B^2)/A^2 evaluated through the exactly factored
     quadratic in xx, so the cone zero is an explicit power. *)
  Module[{quad, qa, qb, qc, disc, r1, r2, zbar, zz, f21, c1, c2},
    quad = Expand[AA^2 - BB^2];
    qa = Coefficient[quad, xx, 2];
    qb = Coefficient[quad, xx, 1];
    qc = Coefficient[quad, xx, 0];
    zbar = If[roots =!= {} && TrueQ[FullSimplify[qa] != 0],
      disc = Sqrt[FullSimplify[qb^2 - 4 qa qc]];
      r1 = FullSimplify[(-qb - disc)/(2 qa)];
      r2 = FullSimplify[(-qb + disc)/(2 qa)];
      qa (xx - r1) (xx - r2)/AA^2,
      quad/AA^2
    ];
    zz = BB^2/AA^2;
    c1 = Gamma[1 - epsN] Gamma[-1/2 - epsN]/
      (Gamma[1/2 - epsN] Gamma[-epsN]);
    c2 = Gamma[1 - epsN] Gamma[1/2 + epsN]/Sqrt[Pi];
    f21 = If[TrueQ[Simplify[BB] == 0],
      1,
      c1 Hypergeometric2F1[1/2, 1, 3/2 + epsN, zbar] +
        c2 zbar^(-1/2 - epsN) zz^epsN
    ];
    (* constants at very high precision: the factored zbar must stay
       resolvable against 1 at deep refinement (endpoint regions reach
       xx ~ 10^-30 where 1 - zbar ~ xx). *)
    integrand = N[
      2^(d - 3) (xx (1 - xx))^((d - 4)/2) *
        Beta[(d - 3)/2, 1/2] f21/(AA den2),
      200
    ]
  ];
  value = NIntegrate[
    integrand,
    Evaluate[Flatten[{xx, 0, splits, 1}]],
    WorkingPrecision -> prec, PrecisionGoal -> 12,
    MaxRecursion -> 30
  ];
  If[! NumberQ[value],
    Print["NINTEGRATE FAILED"]; Exit[1]
  ];
  (M/2)^(d - 3)/(4 M) omega[d - 3] value
];

(* volume through the same 2d machinery (unit denominators):
   certifies the substitution and prefactors against the closed
   formula printed below. *)
volMeasure = NIntegrate[
  N[2^(d - 3) (xx (1 - xx))^((d - 4)/2) Beta[(d - 3)/2, 1/2],
    prec + 10],
  {xx, 0, 1},
  WorkingPrecision -> prec, PrecisionGoal -> 12, MaxRecursion -> 30
];
volValue = (M/2)^(d - 3)/(4 M) omega[d - 3] volMeasure;
volFormula = 2^(1 - d) omega[d - 1]/2 M2^(-epsN) 2;
Print["VOL numeric  : ", N[volValue, 20]];
Print["VOL formula  : ",
  N[2^(1 - d) (2 Pi^((d - 1)/2)/Gamma[(d - 1)/2]) M2^(-epsN), 20]];

results = KeyValueMap[
  Function[{name, momenta},
    Module[{K2, K3, value},
      {K2, K3} = kVector /@ momenta;
      value = angularMaster[K2, K3];
      Print[name, " : ", N[value, 20]];
      name -> value
    ]
  ],
  families
];

Put[
  <|"v" -> vN, "w" -> wN, "eps" -> epsN,
    "VOL" -> volValue, "Masters" -> Association[results]|>,
  FileNameJoin[{
    "/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad",
    "numeric_masters_" <> ToString[N[vN]] <> "_" <> ToString[N[wN]] <>
      "_" <> ToString[N[epsN]] <> ".wl"
  }]
];
Print["DONE"];
