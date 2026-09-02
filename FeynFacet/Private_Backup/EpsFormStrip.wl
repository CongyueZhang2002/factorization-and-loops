
(* ==== moved from Private/EpsFormStrip.wl on 2026-09-02 (overhaul goal 1) ====
   Evidence: CANONICA degree ladder + Maple residue strip solver; production entry SolveEpsFormStripInFrame is called with FiniteFieldFirst -> True by Scripts/family_epsform_sector.wls (line 1399) and skips it; only FACET_STRIP_ROUTE=Legacy and Tests/Infrastructure/t_construction_budget.wls reached it; route_split.py 2026-09-02: 4 route-only symbols
   Symbols: SolveEpsFormStrip, epsFormStripExactPotentialGauge (epsFormStripExactDLogQ and epsFormStripRunCanonica moved back 2026-09-02 07:35: t_canonica_scheduler drives them)
   This file is never loaded by FeynFacet.m. *)



epsFormStripExactPotentialGauge[
    strip : {e_, c_, bbar_}, variables : {x_, y_},
    epsilon_Symbol, alphabet_List] := Module[
  {candidate, remainder, correction, gauge, residuals},
  If[! epsFormStripZeroQ[e] || ! epsFormStripZeroQ[c], Return[$Failed]];
  candidate = Quiet[Check[
    Map[Integrate[#, x] &, bbar[[1]], {2}], $Failed]];
  If[candidate === $Failed || ! FreeQ[candidate, _Integrate],
    Return[$Failed]];
  remainder = Map[Together, bbar[[2]] - D[candidate, y], {2}];
  If[! FreeQ[remainder, x], Return[$Failed]];
  correction = Quiet[Check[
    Map[Integrate[#, y] &, remainder, {2}], $Failed]];
  If[correction === $Failed || ! FreeQ[correction, _Integrate],
    Return[$Failed]];
  gauge = Map[Together, candidate + correction, {2}];
  residuals = Table[
    Map[Together, bbar[[mu]] - D[gauge, variables[[mu]]], {2}],
    {mu, 2}];
  If[epsFormStripZeroQ[residuals] &&
      epsFormStripExactDLogQ[
        gauge, strip, variables, epsilon, alphabet],
    gauge, $Failed]
];

(* epsFormStripRunCanonica: moved back to Private/EpsForm/EpsFormStrip.wl on 2026-09-02 07:35 (a test drives it). *)

SolveEpsFormStrip[
    strip : {e_List, c_List, bbar_List},
    variables : {_, _}, epsilon_Symbol,
    OptionsPattern[]] :=
 Module[
  {degrees, denominatorDegree, canonicaTime, canonicaKernels,
   mapleExecutable, mapleLibrary, mapleTime, mapleMethodTime,
   mapleResidueKernels,
   mapleDenominatorPowers,
   mapleNumeratorOffsets, scratchDirectory,
   tag, verbose, alphabet, converted, irreducibles,
   check, alreadyDLog, exactPotential, canonica, selected, maple, result},

  If[! epsFormStripShapeQ[strip],
    Message[SolveEpsFormStrip::shape]; Return[$Failed]];
  degrees = DeleteDuplicates[OptionValue["CANONICANumeratorDegrees"]];
  (* an EMPTY degree list means "dlog recognition only": the strip-method
     benchmark of 2026-08-22 (20 real strips) showed the finite field
     3-130x faster than the CANONICA ladder wherever both solve and the
     ladder burning 480 s on every strip it cannot solve, so the
     production route runs recognition, then the finite field *)
  If[! AllTrue[degrees, IntegerQ[#] && # >= 0 &],
    Message[SolveEpsFormStrip::degrees]; Return[$Failed]];
  denominatorDegree = OptionValue["CANONICADenominatorDegree"];
  canonicaTime = OptionValue["CANONICATimeLimit"];
  canonicaKernels = facetKernelCount[
    OptionValue["CANONICAKernels"], Length[degrees]];
  mapleExecutable = OptionValue["MapleExecutable"];
  mapleLibrary = OptionValue["MapleLibrary"];
  mapleTime = OptionValue["MapleTimeLimit"];
  mapleMethodTime = OptionValue["MapleMethodTimeLimit"];
  mapleResidueKernels = facetKernelCount[
    OptionValue["MapleResidueKernels"]];
  mapleDenominatorPowers = OptionValue[
    "MapleLetterDenominatorPowers"];
  mapleNumeratorOffsets = OptionValue[
    "MapleNumeratorDegreeOffsets"];
  scratchDirectory = Replace[OptionValue["ScratchDirectory"],
    Automatic :> FileNameJoin[{$TemporaryDirectory, "FeynFacet",
      "EpsFormStrip"}]];
  tag = epsFormStripSafeTag[OptionValue["Tag"]];
  verbose = TrueQ[OptionValue["Verbose"]];
  If[! DirectoryQ[scratchDirectory],
    CreateDirectory[scratchDirectory, CreateIntermediateDirectories -> True]];
  If[! epsFormStripLoadCanonica[],
    Message[SolveEpsFormStrip::canonica, $epsFormStripCanonicaFile];
    Return[$Failed]];

  alphabet = epsFormStripAlphabet[strip, variables, epsilon];
  If[alphabet === $Failed, Return[$Failed]];
  exactPotential = epsFormStripExactPotentialGauge[
    strip, variables, epsilon, alphabet];
  If[ListQ[exactPotential],
    Return[<|
      "Status" -> "Solved",
      "Method" -> "ExactPotential",
      "Gauge" -> exactPotential,
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> {}
    |>]];
  converted = strip /. epsilon -> CANONICA`eps;
  irreducibles = epsFormStripCanonicaSymbol["ExtractIrreducibles"][
    converted, CANONICA`AllowEpsDependence -> True];
  check = epsFormStripCanonicaSymbol["CheckDlogForm"];
  alreadyDLog = FreeQ[irreducibles, CANONICA`eps] &&
    (epsFormStripZeroQ[converted[[3]]] ||
      TrueQ[check[converted[[3]], variables, alphabet]]);
  If[alreadyDLog,
    Return[<|
      "Status" -> "Solved",
      "Method" -> "AlreadyDLog",
      "Gauge" -> ConstantArray[0, Dimensions[bbar[[1]]]],
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> {}
    |>]];

  If[verbose,
    Print["CANONICA strip search: numerator degrees ", degrees,
      ", ", canonicaTime, " s each"]];
  canonica = If[degrees === {}, <|"Attempts" -> {}, "Candidates" -> {}|>,
    epsFormStripRunCanonica[
      strip, variables, epsilon, alphabet, degrees, denominatorDegree,
      canonicaTime, canonicaKernels]];
  If[canonica["Candidates"] =!= {},
    selected = First[canonica["Candidates"]];
    result = <|
      "Status" -> "Solved",
      "Method" -> "CANONICA",
      "Gauge" -> selected["Gauge"],
      "NumeratorDegree" -> selected["NumeratorDegree"],
      "DenominatorDegree" -> denominatorDegree,
      "Alphabet" -> alphabet,
      "ExactDLog" -> True,
      "CANONICAAttempts" -> canonica["Attempts"]
    |>;
    Return[result]];

  (* "UseMaple" -> False: dlog recognition + CANONICA ladder only (the
     strip-method benchmark of 2026-08-21 measures the routes separately) *)
  If[! TrueQ[OptionValue["UseMaple"]],
    Return[<|"Status" -> If[degrees === {}, "NotRecognized", "CANONICAFailed"],
      "Method" -> If[degrees === {}, "Recognition", "CANONICA"],
      "CANONICAAttempts" -> canonica["Attempts"]|>]];
  If[verbose, Print["CANONICA found no exact dlog gauge; invoking Maple"]];
  maple = SolveResidueRationalGauge[
    strip, variables, epsilon,
    "MapleExecutable" -> mapleExecutable,
    "MapleLibrary" -> mapleLibrary,
    "ScratchDirectory" -> scratchDirectory,
    "Tag" -> tag,
    "TimeLimit" -> mapleTime,
    "MethodTimeLimit" -> mapleMethodTime,
    "ResidueKernels" -> mapleResidueKernels,
    "LetterDenominatorPowers" -> mapleDenominatorPowers,
    "NumeratorDegreeOffsets" -> mapleNumeratorOffsets,
    "Verbose" -> verbose];
  If[AssociationQ[maple],
    Return[Join[maple,
      <|"CANONICAAttempts" -> canonica["Attempts"]|>]]];

  Message[SolveEpsFormStrip::failed];
  $Failed
];
