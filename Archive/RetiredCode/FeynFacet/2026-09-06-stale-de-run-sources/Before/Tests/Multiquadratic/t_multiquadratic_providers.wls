#!/usr/bin/env wolframscript
(* DIRECT COEFFICIENT PROVIDERS (round-2 wave item 9; Codex review 2.1
   and 2.7, ChatGPT Pro items 1-3 and 8).

   THE MEASUREMENT.  Preparation of the real CF300 (12,9) block is
   1439.7 s, of which 1400.5 s (97.3%) is global exact decomposition of
   the inhomogeneity into characteristic-zero channels.  The modular solve
   never needs those functions -- only their VALUES at finite-field
   points.  Codex's bounded benchmark on the same frozen block showed
   that evaluating the ORIGINAL inhomogeneity directly on all Galois branches
   reproduces every frozen exact channel projection, 32 of 32.

   THIS SUITE is the acceptance for the two providers that generalize
   that benchmark, and the anchor is the same frozen fixture.

   ACCEPTANCE CRITERIA, stated before the run.

   The modular grade algebra.
   D1  The modular tower inverse is a genuine inverse: a * a^-1 = 1 in
       F_p[r]/(r^2 - delta) at ranks 1, 2 and 3, and a zero-norm element
       is REFUSED, not inverted.

   The providers on a synthetic entry with a known decomposition.
   D2  The quotient-grade provider reproduces the channel values of
       multiquadraticFieldDecompose (the exact oracle) at a point.
   D3  The split-branch provider agrees with the quotient-grade provider
       at a split point.
   D4  At a NONSPLIT point the split-branch provider refuses typed
       ("PointNotSplitOverPrime") while the quotient-grade provider
       still evaluates -- which is the reason the quotient provider
       exists at rank three.
   D5  A point where the gauge/denominator norm vanishes is a TYPED
       rejection of the point, never a zero value.

   Per-entry active-root reduction.
   D6  An entry that uses only one of two declared roots is evaluated at
       LOCAL rank 1 and lifted into the declared global grade ABI: its
       channels are supported exactly on the masks of that root's
       subfield.
   D7  The provider's per-entry active-root census is recorded, and its
       histogram shows entries below the declared rank.

   THE ANCHOR: the real frozen CF300 (12,9) block.
   D8  At Codex's benchmark image (p = 10007 is not an admissible screen
       prime, so the check is run at the fixture's own admissible prime),
       both providers reproduce the FROZEN EXACT CHANNELS of every
       inhomogeneity entry -- the same equality Codex measured, now as a
       standing test.
   D9  The two providers agree with each other at fresh split points.
   D10 MEASURED, NOT ASSERTED: per-entry provider seconds against the
       symbolic oracle multiquadraticFieldDecompose on the dominant
       entries of that block.  This replaces the retired retiming
       question. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{modularInverse, gradeEvaluate, activeRoots, provider, providerChannels,
  decompose, compose, currentRoots, rootCensus, rootOrder, multiply,
  liftLocal} =
 mq /@ {"multiquadraticOffDiagonalBlockModularInverse",
   "multiquadraticOffDiagonalBlockModularGradeEvaluate",
   "multiquadraticOffDiagonalBlockEntryActiveRoots",
   "multiquadraticOffDiagonalBlockDirectProvider",
   "multiquadraticOffDiagonalBlockProviderChannels",
   "multiquadraticFieldDecompose", "multiquadraticFieldCompose",
   "coefficientPresentationSquareRootsInVariables", "multiquadraticOffDiagonalBlockRootCensus",
   "multiquadraticOffDiagonalBlockRootOrder", "multiquadraticMultiply",
   "multiquadraticLiftLocalChannels"};

prime = 2147483423;   (* an admissible screen prime: 3 mod 4, below 2^31 *)

(* ------------------------------------------------------------------ *)
(* D1: the modular tower inverse                                        *)
(* ------------------------------------------------------------------ *)

SeedRandom[20260826];
inverseOK[deltas_] := Module[{a, inverse, product, width = 2^Length[deltas]},
  a = RandomInteger[{1, prime - 1}, width];
  inverse = modularInverse[a, deltas, prime];
  If[! ListQ[inverse], Return[False]];
  product = Mod[multiply[a, inverse, deltas, prime], prime];
  product === PadRight[{1}, width, 0]];
check["D1 the modular tower inverse is a genuine inverse at ranks 1, 2, 3",
  AllTrue[{{7}, {7, 11}, {7, 11, 13}},
    Function[deltas, AllTrue[Range[5], inverseOK[deltas] &]]]];
(* a zero divisor: u + v r with u^2 - delta v^2 = 0 needs delta a square;
   take delta = 4, u = 2, v = 1 -> norm 4 - 4 = 0 *)
check["D1 a zero-norm element is refused, not inverted",
  modularInverse[{2, 1}, {4}, prime] === $Failed];
check["D1 a zero element is refused at rank 0",
  modularInverse[{0}, {}, prime] === $Failed];

(* ------------------------------------------------------------------ *)
(* D2 - D7: a synthetic rank-2 entry with a known decomposition          *)
(* ------------------------------------------------------------------ *)

Clear[dx, dy, de];
delta1 = 1 + dx;
delta2 = 1 + dy;
roots = {<|"Generator" -> Sqrt[delta1], "QuadraticRadicand" -> delta1|>,
  <|"Generator" -> Sqrt[delta2], "QuadraticRadicand" -> delta2|>};
(* an entry using BOTH roots, with an algebraic denominator so the tower
   inverse is genuinely exercised *)
entryBoth = Together[(de + dx Sqrt[delta1] + dy Sqrt[delta2] +
  Sqrt[delta1] Sqrt[delta2])/(2 + dx + Sqrt[delta1])];
(* an entry using only the SECOND root *)
entryOne = Together[(1 + de dy Sqrt[delta2])/(3 + dy)];
zero11 = {{{0}}, {{0}}};
providerRecord = <|"Family" -> "PROVIDERS", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {dx, dy}, "Regulator" -> de,
  "OffDiagonalBlockEquation" -> {zero11, zero11, {{{entryBoth}}, {{entryOne}}}}|>;

quotient = provider[providerRecord, roots, "Kind" -> "QuotientGrade"];
split = provider[providerRecord, roots, "Kind" -> "SplitBranch"];
check["the two providers are built",
  Lookup[quotient, "Status", None] === "MultiquadraticDirectProviderV1" &&
    Lookup[split, "Status", None] === "MultiquadraticDirectProviderV1"];
report["D7 active-root histogram", Lookup[quotient, "ActiveRootHistogram",
  None]];
check["D7 the per-entry active-root census is recorded and is not uniform",
  quotient["ActiveRoots"]["Inhomogeneity"][[1, 1, 1]] === {1, 2} &&
    quotient["ActiveRoots"]["Inhomogeneity"][[2, 1, 1]] === {2}];
check["D7 the census agrees with the standalone entry classifier",
  activeRoots[entryBoth, roots] === {1, 2} &&
    activeRoots[entryOne, roots] === {2} &&
    activeRoots[1 + dx + dy, roots] === {}];

(* a split point: both radicands are quadratic residues *)
epsValue = 5;
splitPoint = SelectFirst[Table[{a, 3 a + 1}, {a, 2, 400}],
  Function[point, Module[{d = Mod[{delta1, delta2} /.
      Thread[{dx, dy} -> point], prime]},
    FreeQ[d, 0] && AllTrue[d, JacobiSymbol[#1, prime] === 1 &]]],
  Missing["NoSplitPoint"]];
check["a split point exists over the test prime", ! MissingQ[splitPoint]];
report["split point", splitPoint];

quotientChannels = providerChannels[quotient, epsValue, prime, splitPoint];
splitChannels = providerChannels[split, epsValue, prime, splitPoint];
check["both providers evaluate at the split point",
  Lookup[quotientChannels, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    Lookup[splitChannels, "Status", None] ===
      "MultiquadraticPointCoefficientsV1"];

(* the exact oracle: decompose symbolically, then reduce at the point *)
modAt[value_] := Module[{q = Together[value], den},
  If[! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  den = Mod[Denominator[q], prime];
  If[den === 0, Return[$Failed]];
  Mod[Mod[Numerator[q], prime] PowerMod[den, -1, prime], prime]];
oracleChannels[entry_] := Module[{channels},
  channels = decompose[entry, roots];
  If[channels === $Failed, Return[$Failed]];
  modAt[#1 /. Thread[{dx, dy} -> splitPoint] /. de -> epsValue] & /@ channels];

check["D2 the quotient-grade provider reproduces the exact oracle's channels",
  quotientChannels["Inhomogeneity"][[1, 1, 1]] === oracleChannels[entryBoth] &&
    quotientChannels["Inhomogeneity"][[2, 1, 1]] === oracleChannels[entryOne]];
report["D2 quotient channels / oracle",
  {quotientChannels["Inhomogeneity"][[1, 1, 1]], oracleChannels[entryBoth]}];

check["D3 the split-branch provider agrees with the quotient-grade provider",
  splitChannels["Inhomogeneity"] === quotientChannels["Inhomogeneity"]];

check["D6 the single-root entry is evaluated locally and lifted: its \
channels live on the masks of that root's subfield only",
  quotientChannels["Inhomogeneity"][[2, 1, 1, {2, 4}]] === {0, 0} &&
    quotientChannels["Inhomogeneity"][[2, 1, 1, 3]] =!= 0];
report["D6 single-root entry channels", quotientChannels["Inhomogeneity"][[2, 1, 1]]];

(* a NONSPLIT point *)
nonsplitPoint = SelectFirst[Table[{a, 3 a + 1}, {a, 2, 4000}],
  Function[point, Module[{d = Mod[{delta1, delta2} /.
      Thread[{dx, dy} -> point], prime]},
    FreeQ[d, 0] && ! AllTrue[d, JacobiSymbol[#1, prime] === 1 &]]],
  Missing["NoNonsplitPoint"]];
check["a nonsplit point exists over the test prime", ! MissingQ[nonsplitPoint]];
check["D4 the split-branch provider refuses a nonsplit point, typed",
  Lookup[providerChannels[split, epsValue, prime, nonsplitPoint], "Status",
    None] === "PointNotSplitOverPrime"];
check["D4 the quotient-grade provider evaluates there anyway",
  Lookup[providerChannels[quotient, epsValue, prime, nonsplitPoint], "Status",
    None] === "MultiquadraticPointCoefficientsV1"];

(* D5: a point where an algebraic denominator has zero norm.  The
   denominator of entryBoth is 2 + x + Sqrt[1 + x]; its norm is
   (2 + x)^2 - (1 + x) = 3 + 3x + x^2, so a root of that polynomial mod p
   is a zero-norm point. *)
(* a zero-norm point built by construction rather than found: the
   denominator 5 + Sqrt[1 + x] has norm 25 - (1 + x), which vanishes at
   x = 24 while the radicand itself is 25 and is NOT degenerate.  So the
   element is a genuine zero divisor there, and the provider must reject
   the POINT rather than record a value. *)
zeroNormEntry = 1/(5 + Sqrt[delta1]);
zeroNormRecord = Join[providerRecord,
  <|"OffDiagonalBlockEquation" -> {zero11, zero11, {{{zeroNormEntry}}, {{0}}}}|>];
zeroNormProvider = provider[zeroNormRecord, roots,
  "Kind" -> "QuotientGrade"];
zeroNormPoint = {24, 7};
report["D5 zero-norm point", zeroNormPoint];
If[! MissingQ[zeroNormPoint],
  check["D5 a zero-norm point is a TYPED rejection of the point",
    Module[{verdict = Lookup[providerChannels[zeroNormProvider, epsValue,
        prime, zeroNormPoint], "Status", None]},
      report["D5 verdict", verdict];
      StringQ[verdict] && verdict =!= "MultiquadraticPointCoefficientsV1"]],
  check["D5 a zero-norm point exists to test", False]];
check["D5 the SAME entry at a regular point evaluates normally, so D5 is \
about the zero norm and not about the entry",
  Lookup[providerChannels[zeroNormProvider, epsValue, prime, {23, 7}],
    "Status", None] === "MultiquadraticPointCoefficientsV1"];

(* ------------------------------------------------------------------ *)
(* D8 - D10: the frozen CF300 (12,9) anchor                             *)
(* ------------------------------------------------------------------ *)

fixtureDirectory = FileNameJoin[{root, "Stale", "DifferentialEquationData",
  "2026-09-03_pre_v2", "UU_08_10_canonical", "FamilyEpsFormsSolving",
  "FrozenTestFixtures_2026-08-25"}];
stripFile = FileNameJoin[{fixtureDirectory, "cf300_frozen_strip_12_9_input.wl"}];
channelFile = FileNameJoin[{fixtureDirectory,
  "cf300_frozen_channel_forcing.wl"}];
check["the frozen CF300 (12,9) strip and its exact channels are in the \
repository",
  FileExistsQ[stripFile] && FileExistsQ[channelFile]];

legacyCFRecord = FeynFacet`FamilyArtifactRead[stripFile, "Global`"];
cfRecord = Join[KeyTake[legacyCFRecord,
    {"Family", "Sector", "LowerSector", "Variables", "Regulator"}],
  <|"OffDiagonalBlockEquation" -> legacyCFRecord["Strip"]|>];
frozenChannels = FeynFacet`FamilyArtifactRead[channelFile, "Global`"];
cfVariables = cfRecord["Variables"];
cfRegulator = cfRecord["Regulator"];
chart = BuildSquareRootGeneratorsAndQuadraticRelations[
  {(1 + Global`v - Global`w)^2 + 4 Global`v Global`w,
    (1 - Global`v + Global`w)^2 + 4 Global`v Global`w,
    1 - 4 Global`v Global`w},
  {Global`v, Global`w}, cfVariables];
cfAllRoots = currentRoots[chart, cfVariables];
cfCensus = rootCensus[cfRecord["OffDiagonalBlockEquation"], cfAllRoots];
cfOrder = rootOrder[chart, cfVariables, cfCensus["RootIndices"], cfRegulator];
cfRoots = cfOrder["Roots"];
check["the fixture is a rank-2 multiquadratic strip",
  Lookup[cfOrder, "Status", None] === "StableRootOrder" &&
    Length[cfRoots] === 2 && ListQ[frozenChannels]];

cfQuotient = provider[cfRecord, cfRoots, "Kind" -> "QuotientGrade"];
cfSplit = provider[cfRecord, cfRoots, "Kind" -> "SplitBranch"];
report["D7 CF300 active-root histogram",
  Lookup[cfQuotient, "ActiveRootHistogram", None]];
report["D7 CF300 census seconds",
  Round[Lookup[cfQuotient, "CensusSeconds", 0], 0.01]];

cfEpsilon = 5;
cfDeltas = Lookup[cfRoots, "QuadraticRadicand", {}];
cfSplitPoint = SelectFirst[Tuples[Range[2, 60], 2],
  Function[point, Module[{d = Mod[cfDeltas /.
      Thread[cfVariables -> point], prime]},
    FreeQ[d, 0] && AllTrue[d, JacobiSymbol[#1, prime] === 1 &]]],
  Missing["NoSplitPoint"]];
check["a split point of the real block exists over the test prime",
  ! MissingQ[cfSplitPoint]];
report["D8 CF300 split point", cfSplitPoint];

(* the frozen EXACT channels, reduced at the same image: the reference *)
cfFrozenImages = Map[modCF, frozenChannels, {4}];
modCF[value_] := Module[{q = Together[value], den},
  If[! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  den = Mod[Denominator[q], prime];
  If[den === 0, Return[$Failed]];
  Mod[Mod[Numerator[q], prime] PowerMod[den, -1, prime], prime]];
cfFrozenImages = Map[
  modCF[#1 /. Thread[cfVariables -> cfSplitPoint] /.
    cfRegulator -> cfEpsilon] &, frozenChannels, {4}];

{cfQuotientSeconds, cfQuotientChannels} = AbsoluteTiming[
  providerChannels[cfQuotient, cfEpsilon, prime, cfSplitPoint]];
{cfSplitSeconds, cfSplitChannels} = AbsoluteTiming[
  providerChannels[cfSplit, cfEpsilon, prime, cfSplitPoint]];
check["D8 both providers evaluate the real block at that image",
  Lookup[cfQuotientChannels, "Status", None] ===
      "MultiquadraticPointCoefficientsV1" &&
    Lookup[cfSplitChannels, "Status", None] ===
      "MultiquadraticPointCoefficientsV1"];
check["D8 THE ANCHOR: the split-branch provider reproduces every frozen \
exact channel of the real block",
  cfSplitChannels["Inhomogeneity"] === cfFrozenImages];
check["D8 and so does the quotient-grade provider",
  cfQuotientChannels["Inhomogeneity"] === cfFrozenImages];
report["D8 entry count / channel count",
  {Times @@ Dimensions[frozenChannels][[1 ;; 3]],
   Times @@ Dimensions[frozenChannels]}];
report["D10 provider seconds (quotient / split-branch), whole block",
  {Round[cfQuotientSeconds, 0.001], Round[cfSplitSeconds, 0.001]}];

(* D9: fresh split points *)
freshPoints = Take[Select[Tuples[Range[61, 140], 2],
  Function[point, Module[{d = Mod[cfDeltas /.
      Thread[cfVariables -> point], prime]},
    FreeQ[d, 0] && AllTrue[d, JacobiSymbol[#1, prime] === 1 &]]]], UpTo[3]];
check["D9 the two providers agree at three fresh split points",
  Length[freshPoints] === 3 &&
    AllTrue[freshPoints, Function[point,
      Module[{a = providerChannels[cfQuotient, 7, prime, point],
        b = providerChannels[cfSplit, 7, prime, point]},
        Lookup[a, "Status", None] === "MultiquadraticPointCoefficientsV1" &&
          Lookup[b, "Status", None] === "MultiquadraticPointCoefficientsV1" &&
          a["Inhomogeneity"] === b["Inhomogeneity"]]]]];

(* D10: the measurement the round-2 disposition asks for -- per-entry
   provider cost against the symbolic oracle on the dominant entries *)
cfEntries = Flatten[cfRecord["OffDiagonalBlockEquation"][[3]]];
cfLeaves = LeafCount /@ cfEntries;
dominant = Take[Ordering[cfLeaves, -Length[cfLeaves]] // Reverse, UpTo[3]];
report["D10 entry leaf counts", cfLeaves];
Do[
  Module[{entry = cfEntries[[index]], activeIndices, oracleSeconds,
    quotientSeconds, splitSeconds, oracleValue, scalarRules, deltaValues,
    rootValues},
   activeIndices = activeRoots[entry, cfRoots];
   scalarRules = Join[
     AssociationThread[cfVariables, Mod[cfSplitPoint, prime]],
     <|cfRegulator -> Mod[cfEpsilon, prime]|>];
   deltaValues = Mod[cfDeltas /. Thread[cfVariables -> cfSplitPoint], prime];
   rootValues = PowerMod[deltaValues, (prime + 1)/4, prime];
   {oracleSeconds, oracleValue} = AbsoluteTiming[decompose[entry, cfRoots]];
   {quotientSeconds, quotient} = AbsoluteTiming[
     mq["multiquadraticOffDiagonalBlockQuotientGradeEntry"][entry, cfRoots,
       activeIndices, scalarRules, deltaValues, prime]];
   {splitSeconds, split} = AbsoluteTiming[
     mq["multiquadraticOffDiagonalBlockSplitBranchEntry"][entry, cfRoots,
       activeIndices, scalarRules, deltaValues, rootValues, prime]];
   report["D10 entry " <> ToString[index] <> " leaves / active roots / \
oracle s / quotient s / split s / split method",
     {cfLeaves[[index]], activeIndices, Round[oracleSeconds, 0.001],
      Round[quotientSeconds, 0.001], Round[splitSeconds, 0.001],
      Lookup[split, "Method", None]}]],
  {index, dominant}];

Print["t_multiquadratic_providers: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
