#!/usr/bin/env wolframscript
(* The exact per-regulator-value channel verifier
   multiquadraticStripExactChannelResidual (round-2 wave item 2; Codex
   review 2026-08-25 section 1.3).

   THE DEFECT.  The verifier substituted the regulator VALUE into the
   strip and into the one-forms, and then differentiated and multiplied
   the reconstructed GAUGE and RESIDUES with the regulator still
   SYMBOLIC in them, mixing symbolic eps with the numeric image.  The
   gauge can carry the regulator two ways the ansatz explicitly permits:

     - the gauge DENOMINATOR is derived from the forcing, and the
       forcing's poles routinely carry eps
       (multiquadraticStripUnpackVector divides the numerator by it);
     - after the rational-in-eps reconstruction the gauge and residue
       COORDINATES are themselves rational functions of eps.

   Either way an EXACT identity was reported as a nonzero residual, and
   the driver turns that into the typed stop
   "ExactChannelResidualNonzero" -- a correct solve refused.

   THE FIXTURE is Codex's minimal counterexample, built so the identity
   is exact by construction: E = C = 0, no letters, and a gauge whose
   denominator carries the regulator, so that Bbar = dG is the whole
   equation.

     G   = 1/(1 + eps x),        Bbar_x = -eps/(1 + eps x)^2, Bbar_y = 0.

   The engine's own gauge-denominator rule (one power below the worst
   forcing pole) then produces exactly 1 + eps x, and the two-monomial
   support {{0,0},{1,0}} makes the coefficient vector {1, 0} the exact
   solution.

   ACCEPTANCE CRITERIA, stated before the run.

   V1  The preparation built from that record is the intended ansatz:
       gauge denominator 1 + eps x, support {{0,0},{1,0}}, 2 unknowns,
       no residue unknowns, rank 0.
   V2  Unpacking the coefficient vector {1, 0} returns exactly
       G = 1/(1 + eps x).
   V3  GENERIC eps (the Automatic image): the residual is zero.  This
       held before the fix too and is the control -- it is the numeric
       image that was broken, not the symbolic one.
   V4  THE COUNTEREXAMPLE: at eps = 2 the residual is zero, and every
       channel of it is identically zero as an expression.  (Pre-fix:
       "ExactChannelResidualNonzero".)
   V5  The same at two further images, eps = 5 and eps = 1/3, so V4 is
       not an accident of the value 2.
   V6  NEGATIVE CONTROL: the vector {0, 1} -- the gauge vx/(1 + eps x),
       which does not solve the equation -- is reported nonzero at
       eps = 2.  A verifier that returned zero for everything would pass
       V4 and fail here.
   V7  A RATIONAL-IN-eps COEFFICIENT VECTOR, which is the shape the
       round-2 reconstruction layer produces: with
       G = 1/((1 + eps)(1 + eps x)) the exact solution vector is
       {1/(1 + eps), 0}, whose entries are rational functions of the
       regulator.  The residual is zero at eps = 2, at eps = 5 and
       generically.  (Pre-fix: nonzero at every numeric image.)
   V8  The residues are specialized as well as the gauge: with one
       letter carrying an eps-dependent residue K(eps) = eps/(1 + eps),
       the exactly-solved system verifies zero at a numeric image.
   V9  A gauge that is SINGULAR at the requested image is refused typed
       ("ExactChannelGaugeSingularAtRegulator"), not silently divided
       by zero. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 6]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{prepare, residual, unpack} = mq /@ {"multiquadraticStripPrepare",
  "multiquadraticStripExactChannelResidual",
  "multiquadraticStripUnpackVector"};

Clear[vx, vy, ve];
frame = <|"Name" -> "Round2Rational", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> {vx, vy},
  "Subst" -> {vx -> vx, vy -> vy}, "Root" -> None, "RootSquare" -> None,
  "Roots" -> {}|>;

zero11 = {{{0}}, {{0}}};

(* a record whose forcing is EXACTLY the left-hand side of the equation
   for the given gauge, diagonal blocks and residues: the identity then
   holds by construction at every eps, which is what makes a nonzero
   residual a defect of the verifier and nothing else *)
recordFor[gauge_, e_, c_, oneForms_List, residues_List] := Module[{bbar},
  bbar = Table[Map[Together,
      D[gauge, {vx, vy}[[mu]]] -
        ve (e[[mu]] . gauge - gauge . c[[mu]]) +
        ve Sum[residues[[a]] oneForms[[a, mu]], {a, Length[oneForms]}],
      {2}],
    {mu, 2}];
  <|"Family" -> "EXACT_VERIFIER", "Sector" -> 2, "LowerSector" -> 1,
    "Variables" -> {vx, vy}, "Regulator" -> ve,
    "Strip" -> {e, c, bbar}|>];

(* ------------------------------------------------------------------ *)
(* V1 / V2: the intended ansatz                                         *)
(* ------------------------------------------------------------------ *)

gaugeA = {{1/(1 + ve vx)}};
recordA = recordFor[gaugeA, zero11, zero11, {}, {}];
report["V1 forcing", recordA["Strip"][[3]]];
prepA = prepare[recordA, frame, "OneForms" -> {}];
check["V1 the preparation is the intended ansatz",
  Lookup[prepA, "Status", None] === "PreparedMultiquadraticStripV1" &&
    TrueQ[Together[prepA["GaugeDenominator"] - (1 + ve vx)] === 0] &&
    prepA["GaugeSupport"] === {{0, 0}, {1, 0}} &&
    prepA["UnknownCount"] === 2 && prepA["ResidueUnknownCount"] === 0 &&
    prepA["RootCount"] === 0];
report["V1 denominator / support / unknowns",
  {prepA["GaugeDenominator"], prepA["GaugeSupport"], prepA["UnknownCount"]}];

unpackedA = unpack[prepA, {1, 0}];
check["V2 the vector {1,0} unpacks to exactly 1/(1 + eps x)",
  Lookup[unpackedA, "Status", None] === "UnpackedMultiquadraticSolution" &&
    TrueQ[Together[unpackedA["Gauge"][[1, 1]] - 1/(1 + ve vx)] === 0]];

(* ------------------------------------------------------------------ *)
(* V3 - V6: the counterexample and its controls                         *)
(* ------------------------------------------------------------------ *)

genericA = residual[prepA, {1, 0}];
check["V3 CONTROL: the residual at generic (symbolic) eps is zero",
  Lookup[genericA, "Status", None] === "ExactChannelResidualZero"];

atTwo = residual[prepA, {1, 0}, 2];
check["V4 THE COUNTEREXAMPLE: the residual at eps = 2 is zero",
  Lookup[atTwo, "Status", None] === "ExactChannelResidualZero" &&
    TrueQ[atTwo["ResidualZero"]]];
check["V4 every channel of that residual is identically zero",
  AllTrue[Flatten[Lookup[atTwo, "ResidualChannels", {1}]],
    TrueQ[Together[#1] === 0] &]];
report["V4 residual at eps = 2", KeyTake[atTwo,
  {"Status", "ResidualZero", "EpsilonValue"}]];

check["V5 the same at eps = 5 and eps = 1/3",
  Lookup[residual[prepA, {1, 0}, 5], "Status", None] ===
      "ExactChannelResidualZero" &&
    Lookup[residual[prepA, {1, 0}, 1/3], "Status", None] ===
      "ExactChannelResidualZero"];

check["V6 NEGATIVE CONTROL: a vector that does not solve the equation is \
reported nonzero at eps = 2",
  Lookup[residual[prepA, {0, 1}, 2], "Status", None] ===
    "ExactChannelResidualNonzero"];
check["V6 the same wrong vector is nonzero at generic eps too",
  Lookup[residual[prepA, {0, 1}], "Status", None] ===
    "ExactChannelResidualNonzero"];

(* ------------------------------------------------------------------ *)
(* V7: a coefficient vector that is RATIONAL IN THE REGULATOR           *)
(* ------------------------------------------------------------------ *)

gaugeB = {{1/((1 + ve) (1 + ve vx))}};
recordB = recordFor[gaugeB, zero11, zero11, {}, {}];
prepB = prepare[recordB, frame, "OneForms" -> {}];
vectorB = {1/(1 + ve), 0};
check["V7 the second ansatz is prepared and its exact vector is \
rational in the regulator",
  Lookup[prepB, "Status", None] === "PreparedMultiquadraticStripV1" &&
    TrueQ[Together[unpack[prepB, vectorB]["Gauge"][[1, 1]] -
      gaugeB[[1, 1]]] === 0] &&
    ! FreeQ[vectorB, ve]];
report["V7 denominator / support", {prepB["GaugeDenominator"],
  prepB["GaugeSupport"]}];
check["V7 the rational-in-eps vector verifies at eps = 2, eps = 5 and \
generically",
  Lookup[residual[prepB, vectorB], "Status", None] ===
      "ExactChannelResidualZero" &&
    Lookup[residual[prepB, vectorB, 2], "Status", None] ===
      "ExactChannelResidualZero" &&
    Lookup[residual[prepB, vectorB, 5], "Status", None] ===
      "ExactChannelResidualZero"];

(* ------------------------------------------------------------------ *)
(* V8: the RESIDUES are specialized too                                 *)
(* ------------------------------------------------------------------ *)

letterC = 1 + vx + vy;
formC = {Together[D[letterC, vx]/letterC], Together[D[letterC, vy]/letterC]};
residueC = ve/(1 + ve);
recordC = recordFor[gaugeA, zero11, zero11, {formC}, {{{residueC}}}];
prepC = prepare[recordC, frame, "OneForms" -> {formC}];
(* the unknown order is gauge coefficients first, then residues *)
vectorC = {1, 0, residueC};
check["V8 the one-form ansatz is prepared with one residue unknown",
  Lookup[prepC, "Status", None] === "PreparedMultiquadraticStripV1" &&
    prepC["ResidueUnknownCount"] === 1 && prepC["UnknownCount"] === 3];
check["V8 an eps-dependent RESIDUE verifies at a numeric image",
  Lookup[residual[prepC, vectorC], "Status", None] ===
      "ExactChannelResidualZero" &&
    Lookup[residual[prepC, vectorC, 2], "Status", None] ===
      "ExactChannelResidualZero" &&
    Lookup[residual[prepC, vectorC, 7], "Status", None] ===
      "ExactChannelResidualZero"];
report["V8 residue-carrying record",
  KeyTake[prepC, {"UnknownCount", "ResidueUnknownCount", "GaugeDenominator"}]];

(* ------------------------------------------------------------------ *)
(* V9: a gauge singular at the image is refused typed                   *)
(* ------------------------------------------------------------------ *)

check["V9 a coefficient vector singular at the requested image is refused \
typed, not divided by zero",
  Lookup[residual[prepB, {1/(1 + ve), 0}, -1], "Status", None] ===
    "ExactChannelGaugeSingularAtRegulator"];
report["V9 singular-image verdict",
  Lookup[residual[prepB, {1/(1 + ve), 0}, -1], "Status", None]];

Print["t_multiquadratic_exact_verifier: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
