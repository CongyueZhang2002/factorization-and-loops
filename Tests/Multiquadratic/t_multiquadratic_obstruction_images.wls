#!/usr/bin/env wolframscript
(* Obstruction evidence and its wording (round-2 wave item 3; Codex
   review 2026-08-25 section 1.5).

   THE DEFECT.  A rank defect measured at the TWO CONFIGURED primes was
   promoted to the top-level contract "NoGaugeExistsWithThisAnsatz",
   which is theorem-level language.  Two FIXED primes do not make modular
   inconsistency one-sided: with P = p1 p2 the exact scalar equation
   P g = 1 has the rational solution g = 1/P and is inconsistent modulo
   either configured prime.  That case is rare in physical input; the
   wording must survive it anyway, and the project's accepted standard
   (CLAUDE.md: a negative verdict needs evidence, like a positive one) is
   several fresh random good images with a recorded count and an
   ansatz-relative statement.

   ACCEPTANCE CRITERIA, stated before the run.

   The mathematics of the counterexample.
   O1  In the package's own affine solver, the system P g = 1 with
       P = p1 p2 (the two configured screen primes) is INCONSISTENT at
       p1 and at p2, and CONSISTENT at a third prime.  Two fixed primes
       are therefore evidence, not a theorem.

   The fresh-image generator.
   O2  It returns the requested number of images; every prime is an
       admissible screen prime (3 mod 4, below 2^31), all are distinct,
       and none repeats a configured prime.
   O3  Every regulator value it returns is distinct from the configured
       ones and is a value the forcing is regular at.
   O4  A regulator value at which the ANSATZ'S OWN gauge denominator
       collapses is REJECTED: with denominator (1 - eps)(1 + x) the
       value eps = 1 never appears among the returned images.
   O5  Two calls with different seeds draw different images (the draw is
       random, not a second fixed list).

   The two-image screen keeps its cheap-first-pass role.
   O6  A CONSISTENT first image still ends the screen at one image and
       runs no fresh images.
   O7  "FreshImageCount" -> 0 reproduces the pre-2026-08-26 verdict
       exactly: two images, defects {1,1}, status GaugeImageObstruction.
   O8  With the default, a defect that survives both configured images is
       re-tested at fresh images: the record carries ConfiguredImageCount
       2, FreshImageCount 3, ImageCount 5, a FreshImages list of three
       and the ansatz fingerprint, and every defect is positive.

   The top-level wording.
   O9  On a confirmed gauge obstruction the driver's SolutionContract is
       "GaugeObstructionWithinAnsatz", it carries ImageCount, the
       configured/fresh split and an ansatz fingerprint, and its
       ContractNote says in words that this is a high-confidence modular
       obstruction WITHIN the stated ansatz and not a theorem over
       Q(eps).  (Pre-fix: "NoGaugeExistsWithThisAnsatz", ImageCount 2,
       no fingerprint.)
   O10 The string "NoGaugeExistsWith" does not occur anywhere in the
       executable source any more: a second copy of the wording would be
       invisible to O9. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{affineSolve, freshImages, gaugeAnsatz, gaugeScreenImages, solve,
  defaultPrimes, defaultValues, defaultFresh} =
 {mq["multiquadraticStripAffineSolve"],
  mq["multiquadraticStripFreshScreenImages"],
  mq["multiquadraticStripGaugeAnsatz"],
  mq["multiquadraticStripGaugeScreenImages"],
  mq["solveEpsFormStripMultiquadratic"],
  mq["$multiquadraticStripDefaultPrimes"],
  mq["$multiquadraticStripDefaultRegulatorValues"],
  mq["$multiquadraticStripDefaultFreshImageCount"]};

report["configured images", Transpose[{defaultPrimes, defaultValues}]];
report["default fresh image count", defaultFresh];

(* ------------------------------------------------------------------ *)
(* O1: Codex's counterexample, in the package's own affine solver       *)
(* ------------------------------------------------------------------ *)

{p1, p2} = defaultPrimes;
bigP = p1 p2;
solveAt[prime_] := affineSolve[{{Mod[bigP, prime]}}, {Mod[1, prime]}, prime];
(* the first prime above 10^9 that is 3 mod 4: admissible for the screen,
   below 2^31, and neither of the configured two *)
thirdPrime = NestWhile[NextPrime, NextPrime[10^9],
  Mod[#1, 4] =!= 3 || MemberQ[defaultPrimes, #1] &];
check["O1 the third prime is admissible and not one of the configured two",
  PrimeQ[thirdPrime] && Mod[thirdPrime, 4] === 3 && thirdPrime < 2^31 &&
    ! MemberQ[defaultPrimes, thirdPrime]];
check["O1 P g = 1 with P = p1 p2 is INCONSISTENT at both configured primes",
  Lookup[solveAt[p1], "Status", None] === "InconsistentModularSystem" &&
    Lookup[solveAt[p2], "Status", None] === "InconsistentModularSystem"];
check["O1 the same system is CONSISTENT at a third prime, so two fixed \
primes are evidence and not a theorem",
  Lookup[solveAt[thirdPrime], "Status", None] ===
    "MultiquadraticAffineSolution"];
report["O1 verdicts at p1 / p2 / third",
  Lookup[solveAt[#], "Status", None] & /@ {p1, p2, thirdPrime}];

(* ------------------------------------------------------------------ *)
(* the synthetic block: a known gauge, known residues, a flat 1x1       *)
(* diagonal pair -- the same construction the gauge-screen suite uses   *)
(* ------------------------------------------------------------------ *)

Clear[ox, oy, oe];
letters = {ox, oy, 1 - ox - oy, 1 + ox + oy};
forms = {Together[D[Log[#1], ox]], Together[D[Log[#1], oy]]} & /@ letters;
zero11 = {{{0}}, {{0}}};
knownGauge = {{(1 + 2 ox - 3 oy + ox oy)/(1 - ox - oy)}};
knownResidues = {{{0}}, {{0}}, {{5/2}}, {{-3}}};
forcing = Table[Map[Together,
    D[knownGauge, {ox, oy}[[mu]]] +
      oe Sum[knownResidues[[a]] forms[[a, mu]], {a, Length[letters]}], {2}],
  {mu, 2}];
record = <|"Family" -> "OBSTRUCTION_IMAGES", "Sector" -> 3,
  "LowerSector" -> 1, "Variables" -> {ox, oy}, "Regulator" -> oe,
  "Strip" -> {zero11, zero11, forcing}|>;
fullAnsatz = gaugeAnsatz[record, {}, forms, 1 - ox - oy];
(* letter 3 carries a nonzero residue; removing it is a genuine
   obstruction of the ansatz *)
strippedAnsatz = gaugeAnsatz[record, {}, Drop[forms, {3}], 1 - ox - oy];
check["the synthetic ansatzes are built",
  Lookup[fullAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1" &&
    Lookup[strippedAnsatz, "Status", None] === "MultiquadraticGaugeAnsatzV1"];

(* ------------------------------------------------------------------ *)
(* O2 - O5: the fresh-image generator                                   *)
(* ------------------------------------------------------------------ *)

fresh = freshImages[strippedAnsatz, 3, 20260826, defaultPrimes, defaultValues];
check["O2 the generator returns the requested number of images",
  Lookup[fresh, "Status", None] === "FreshScreenImages" &&
    Length[Lookup[fresh, "Images", {}]] === 3];
freshList = Lookup[fresh, "Images", {}];
report["O2 fresh images", freshList];
check["O2 every fresh prime is admissible, distinct, and not configured",
  MatchQ[freshList, {{_Integer, _} ..}] &&
    AllTrue[freshList[[All, 1]],
      PrimeQ[#1] && Mod[#1, 4] === 3 && 3 < #1 < 2^31 &] &&
    DuplicateFreeQ[freshList[[All, 1]]] &&
    Intersection[freshList[[All, 1]], defaultPrimes] === {}];
check["O3 every fresh regulator value is new and admissible",
  MatchQ[freshList, {{_, _Integer | _Rational} ..}] &&
    Intersection[freshList[[All, 2]], defaultValues] === {} &&
    AllTrue[freshList[[All, 2]],
      FreeQ[Together[forcing /. oe -> #1],
        DirectedInfinity | Indeterminate] &]];

(* O4: an ansatz whose gauge denominator collapses at eps = 1 *)
collapsing = gaugeAnsatz[record, {}, forms, (1 - oe) (1 - ox - oy)];
collapsingFresh = freshImages[collapsing, 4, 4242, defaultPrimes,
  defaultValues];
check["O4 a regulator value that collapses the ansatz's own gauge \
denominator is rejected",
  Lookup[collapsing, "Status", None] === "MultiquadraticGaugeAnsatzV1" &&
    ListQ[Lookup[collapsingFresh, "Images", None]] &&
    ! MemberQ[Lookup[collapsingFresh, "Images", {}][[All, 2]], 1]];
report["O4 images for the collapsing denominator",
  Lookup[collapsingFresh, "Images", None]];

otherSeed = freshImages[strippedAnsatz, 3, 777001, defaultPrimes,
  defaultValues];
check["O5 a different seed draws different images",
  Lookup[otherSeed, "Status", None] === "FreshScreenImages" &&
    Lookup[otherSeed, "Images", {}] =!= freshList];
report["O5 second draw", Lookup[otherSeed, "Images", {}]];

(* ------------------------------------------------------------------ *)
(* O6 - O8: the screen driver                                           *)
(* ------------------------------------------------------------------ *)

consistent = gaugeScreenImages[fullAnsatz];
check["O6 a consistent first image still ends the screen at one image, \
with no fresh images",
  Lookup[consistent, "Status", None] === "GaugeImageConsistent" &&
    consistent["ImageCount"] === 1 && consistent["FreshImageCount"] === 0];

twoImage = gaugeScreenImages[strippedAnsatz, "FreshImageCount" -> 0];
check["O7 FreshImageCount -> 0 reproduces the two-image verdict exactly",
  Lookup[twoImage, "Status", None] === "GaugeImageObstruction" &&
    twoImage["ImageCount"] === 2 && twoImage["Defects"] === {1, 1} &&
    twoImage["ConfiguredImageCount"] === 2 &&
    twoImage["FreshImageCount"] === 0];

confirmed = gaugeScreenImages[strippedAnsatz];
report["O8 confirmed verdict", KeyTake[confirmed,
  {"Status", "ImageCount", "ConfiguredImageCount", "FreshImageCount",
   "Defects", "FreshImages"}]];
check["O8 the surviving defect is re-tested at three fresh random images",
  Lookup[confirmed, "Status", None] === "GaugeImageObstruction" &&
    confirmed["ConfiguredImageCount"] === 2 &&
    confirmed["FreshImageCount"] === defaultFresh &&
    confirmed["ImageCount"] === 2 + defaultFresh &&
    Length[confirmed["FreshImages"]] === defaultFresh &&
    AllTrue[confirmed["Defects"], IntegerQ[#1] && #1 > 0 &]];
check["O8 the fresh images are recorded with the verdict, and none of \
them repeats a configured image",
  MatchQ[confirmed["FreshImages"], {{_Integer, _} ..}] &&
    Intersection[confirmed["FreshImages"][[All, 1]], defaultPrimes] === {}];
check["O8 the verdict names the ansatz it is relative to",
  StringQ[Lookup[confirmed, "AnsatzFingerprint", None]] ||
    AssociationQ[Lookup[confirmed, "Ansatz", None]]];

(* ------------------------------------------------------------------ *)
(* O9: the top-level contract                                          *)
(* ------------------------------------------------------------------ *)

frame = <|"Name" -> "Round2Rational", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Rational", "Variables" -> {ox, oy},
  "Subst" -> {ox -> ox, oy -> oy}, "Root" -> None, "RootSquare" -> None,
  "Roots" -> {}|>;
driven = solve[record, frame, "OneForms" -> Drop[forms, {3}],
  "IntegrabilityScreen" -> False, "DegreeOffsetLadder" -> None,
  "GaugeScreenPointCount" -> 12];
report["O9 top-level verdict", KeyTake[driven,
  {"Status", "SolutionContract", "ContractStrength", "ImageCount",
   "ConfiguredImageCount", "FreshImageCount", "Defects"}]];
check["O9 the contract is ansatz-relative and bounded, not theorem-level",
  Lookup[driven, "Status", None] === "GaugeImageObstruction" &&
    Lookup[driven, "SolutionContract", None] ===
      "GaugeObstructionWithinAnsatz" &&
    Lookup[driven, "ContractStrength", None] ===
      "HighConfidenceModularObstruction"];
check["O9 it records the image count and the configured/fresh split",
  IntegerQ[Lookup[driven, "ImageCount", None]] &&
    driven["ImageCount"] >= 3 &&
    driven["ConfiguredImageCount"] === 2 &&
    IntegerQ[Lookup[driven, "FreshImageCount", None]] &&
    driven["FreshImageCount"] >= 1];
check["O9 it carries the ansatz fingerprint",
  StringQ[Lookup[driven, "AnsatzFingerprint", None]] &&
    StringLength[driven["AnsatzFingerprint"]] === 64];
check["O9 the note states the bounded claim in words",
  StringQ[Lookup[driven, "ContractNote", None]] &&
    StringContainsQ[driven["ContractNote"], "not a theorem over Q(eps)"] &&
    StringContainsQ[driven["ContractNote"], "WITHIN THE STATED"] &&
    StringContainsQ[driven["ContractNote"], "drawn fresh at random"]];
report["O9 contract note", Lookup[driven, "ContractNote", None]];

(* ------------------------------------------------------------------ *)
(* O10: no surviving theorem-level wording                              *)
(* ------------------------------------------------------------------ *)

source = Import[FileNameJoin[{root, "FeynFacet", "Private", "EpsForm",
  "MultiquadraticStripSolve.wl"}], "Text"];
executable = FTTest`FTStripComments[source];
check["O10 no theorem-level contract name survives in the executable source",
  ! StringContainsQ[executable, "NoGaugeExistsWith"]];

Print["t_multiquadratic_obstruction_images: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
