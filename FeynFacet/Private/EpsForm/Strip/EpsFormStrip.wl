(* Exact off-diagonal epsilon-form strip solver.

   For diagonal connections eps e and eps c and an off-diagonal block bbar,
   the gauge D obeys

     d_mu D = eps (e_mu D - D c_mu) + F_mu,

   where the transformed strip must be a dlog one-form.  CANONICA is tried
   first in isolated kernels.  Maple is used only after the configured
   CANONICA ansatz degrees have all failed to produce an exactly checked
   dlog gauge.
*)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[SolveResidueRationalGauge, SolveEpsFormStrip];
ClearAll[
  epsFormStripShapeQ,
  epsFormStripAlphabet,
  epsFormStripSafeTag
];

SolveResidueRationalGauge::shape =
  "The two-variable strip matrices e, c, and bbar have incompatible dimensions.";
SolveResidueRationalGauge::canonica =
  "CANONICA functions needed for the residue equations are unavailable.";
SolveResidueRationalGauge::residue =
  "The exact residue construction failed at stage `1`.";
SolveResidueRationalGauge::maple =
  "Maple did not produce a rational gauge satisfying both differential equations exactly.";
SolveResidueRationalGauge::symbols =
  "Maple serialization found distinct Mathematica symbols with the same unqualified name: `1`.";
SolveResidueRationalGauge::unknownname =
  "The generated Maple unknowns collide with the caller's symbols `1`; \
rename the variables or the regulator.";

SolveEpsFormStrip::shape =
  "The two-variable strip matrices e, c, and bbar have incompatible dimensions.";
SolveEpsFormStrip::canonica =
  "CANONICA could not be loaded from `1`.";
SolveEpsFormStrip::degrees =
  "CANONICA numerator degrees must be a nonempty list of nonnegative integers.";
SolveEpsFormStrip::failed =
  "Neither the configured CANONICA searches nor the exact Maple construction found a gauge.";

epsFormStripShapeQ[{e_List, c_List, bbar_List}] := Module[
  {de, dc, db, ni, nj},
  If[Length[e] =!= 2 || Length[c] =!= 2 || Length[bbar] =!= 2,
    Return[False]];
  de = Dimensions /@ e;
  dc = Dimensions /@ c;
  db = Dimensions /@ bbar;
  If[! SameQ @@ de || ! SameQ @@ dc || ! SameQ @@ db,
    Return[False]];
  If[Length[de[[1]]] =!= 2 || Length[dc[[1]]] =!= 2 ||
     Length[db[[1]]] =!= 2, Return[False]];
  ni = de[[1, 1]];
  nj = dc[[1, 1]];
  de[[1]] === {ni, ni} && dc[[1]] === {nj, nj} &&
    db[[1]] === {ni, nj}
];

(* CANONICA-free since 2026-09-02 (round 2): the alphabet is the set of
   irreducible, regulator-free denominator factors of the strip's entries
   (what CANONICA`ExtractIrreducibles enumerated), plus the variables. *)
epsFormStripIrreducibleFactors[expressions_, variables_List, epsilon_Symbol] :=
 Module[{entries, factors},
  entries = Select[Flatten[{expressions}], ! TrueQ[# === 0] &];
  factors = DeleteDuplicates[Flatten[
    (First /@ Rest[FactorList[Denominator[Together[#]]]]) & /@ entries]];
  factors = Select[factors,
    ! FreeQ[#, Alternatives @@ variables] && FreeQ[#, epsilon] &];
  DeleteDuplicates[factors, PossibleZeroQ[#1 - #2] || PossibleZeroQ[#1 + #2] &]
];
epsFormStripRationalZeroCoefficients[expression_, variables_List] :=
  Module[{numerator = Numerator[Together[expression]]},
    If[TrueQ[numerator === 0], {},
      Values[CoefficientRules[Expand[numerator], variables]]]];

epsFormStripAlphabet[{e_, c_, bbar_}, variables_List, epsilon_Symbol] :=
  Union[variables,
    epsFormStripIrreducibleFactors[{e, c, bbar}, variables, epsilon]];

epsFormStripSafeTag[tag_] := StringReplace[
  ToString[tag], RegularExpression["[^A-Za-z0-9_-]"] -> "_"];

Options[SolveEpsFormStrip] = {
  "CANONICANumeratorDegrees" -> {0, 1, 2, 3},
  "CANONICADenominatorDegree" -> 0,
  "CANONICATimeLimit" -> 120,
  "CANONICAKernels" -> Automatic,
  "MapleExecutable" -> "maple",
  "MapleLibrary" -> Automatic,
  "MapleTimeLimit" -> 1800,
  "MapleMethodTimeLimit" -> 120,
  "MapleResidueKernels" -> Automatic,
  "MapleLetterDenominatorPowers" -> {1, 2, 3},
  "MapleNumeratorDegreeOffsets" -> {0, 1, 2},
  "UseMaple" -> True,
  "ScratchDirectory" -> Automatic,
  "Tag" -> "strip",
  "Verbose" -> False
};

(* Retired route (overhaul 2026-09-02, goal 1): the CANONICA degree ladder
   and the Maple residue solver that implemented SolveEpsFormStrip live in
   FeynFacet/Private_Backup/EpsFormStrip.wl and are not loaded.  The
   production off-diagonal solver is SolveEpsFormStripFiniteField, reached
   through SolveEpsFormStripInFrame.  Options[SolveEpsFormStrip] stays: the
   in-frame solver filters its option set through it. *)
SolveEpsFormStrip[___] := <|"Status" -> "RouteRetired",
  "Route" -> "SolveEpsFormStrip (CANONICA ladder, Maple residue solver)",
  "Replacement" -> "SolveEpsFormStripFiniteField",
  "Code" -> "FeynFacet/Private_Backup/EpsFormStrip.wl"|>;

(* RETIRED ROUTE (user decision N3, 2026-09-02): the Maple residue-gauge
   solver.  Implementation kept, unloaded, in Private_Backup/EpsFormStrip.wl. *)
Options[SolveResidueRationalGauge] = {};
SolveResidueRationalGauge[___] := <|"Status" -> "RouteRetired",
  "Route" -> "SolveResidueRationalGauge (Maple residue gauge)",
  "Replacement" -> "SolveEpsFormStripFiniteField / SolveEpsFormStripInFrame (finite-field route)",
  "Note" -> "implementation kept, unloaded, in FeynFacet/Private_Backup/EpsFormStrip.wl (2026-09-02)"|>;
