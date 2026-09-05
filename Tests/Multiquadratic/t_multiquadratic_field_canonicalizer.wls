#!/usr/bin/env wolframscript
(* ONE SHARED FIELD CANONICALIZER between transport and the strip solver
   (round-2 wave item 4; Codex review 2026-08-25 section 1.4).

   THE DEFECT.  TransportCharts.wl has recognized since 2026-08-24 that a
   radicand which is not LITERALLY a declared square may still lie in the
   declared multiquadratic field, and denests it exactly
   (transportChartDenestRadicalBase: the identity rewrite^2 == base is
   checked exactly and the global sign is fixed numerically).  The strip
   solver's own census matched radicands against the declared squares
   directly and refused anything else, so the two halves of the package
   disagreed about what "in the field" means:

     declared roots Sqrt[x], Sqrt[y]; an input containing Sqrt[x y]
       transport  -> Sqrt[x] Sqrt[y], classified, rank 2
       solver     -> "StripContainsUndeclaredRadicals", and
                     multiquadraticFieldDecompose returns $Failed

   A block transport can carry was therefore unsolvable, for no
   mathematical reason.

   ACCEPTANCE CRITERIA, stated before the run.

   C1  transportChartRootIndices (the transport side) denests x y against
       the declared roots and reports root indices {1, 2}.  This is the
       behaviour the solver has to match, established here as the
       reference rather than assumed.
   C2  multiquadraticOffDiagonalBlockRootCensus (the solver side) reports
       "ExactRootClassification" with root indices {1, 2} and an EMPTY
       unclassified list on a strip containing Sqrt[x y].
       (Pre-fix: "UnclassifiedRadicals", indices {}.)
   C3  The census carries the verified rewrite for the base it denested.
   C4  multiquadraticOffDiagonalBlockCanonicalizeRadicals rewrites the strip into
       declared radicals: no Sqrt[x y] survives, and every rewritten
       entry is EQUAL to the original as an expression (the rewrite is a
       change of spelling, not of value).
   C5  multiquadraticFieldDecompose FAILS on the raw entry and SUCCEEDS
       on the canonicalized one, and the channels it returns recompose
       exactly to the original entry.  This is the concrete consequence
       Codex named.
   C6  multiquadraticOffDiagonalBlockPrepare accepts the strip end to end: rank 2,
       and the preparation's stored record carries the canonical strip,
       so everything downstream (the compiler, the exact verifier) sees
       declared radicals only.  (Pre-fix: typed refusal
       "StripContainsUndeclaredRadicals".)
   C7  The census records what it canonicalized, as provenance.
   C8  NEGATIVE CONTROL: a genuinely undeclared radical -- Sqrt[1+x+y]
       with only Sqrt[x], Sqrt[y] declared -- is STILL refused, by both
       the census and prepare.  A canonicalizer that accepted everything
       would pass C2-C6 and fail here.
   C9  The canonicalizer is a NO-OP on a strip whose radicals are all
       declared squares: it returns the input untouched and reports
       "NoRadicalCanonicalizationNeeded".  This is the measured common
       case (every CF259/CF300/CF303 strip so far) and is what keeps the
       repair free on it. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 6]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{census, canonicalize, prepare, decompose, compose, currentRoots,
  frameIndices} = mq /@ {"multiquadraticOffDiagonalBlockRootCensus",
  "multiquadraticOffDiagonalBlockCanonicalizeRadicals", "multiquadraticOffDiagonalBlockPrepare",
  "multiquadraticFieldDecompose", "multiquadraticFieldCompose",
  "coefficientPresentationSquareRootsInVariables", "transportChartRootIndices"};

Clear[v, w, cx, cy, ce];
frame = BuildSquareRootGeneratorsAndQuadraticRelations[
  {v, w}, {v, w}, {cx, cy}];
declaredRoots = currentRoots[frame, {cx, cy}];
check["the frame declares the two roots Sqrt[x] and Sqrt[y]",
  MatchQ[declaredRoots, {_Association, _Association}] &&
    Lookup[declaredRoots, "QuadraticRadicand", {}] === {cx, cy}];

(* the strip: a 1x1 block whose inhomogeneity carries Sqrt[x y], which is
   Sqrt[x] Sqrt[y] and therefore IN the declared field, spelled the way
   the kernel leaves it *)
nested = Sqrt[cx cy];
zero11 = {{{0}}, {{0}}};
inhomogeneity = {{{ce (1 + nested)/(1 + cx)}}, {{ce nested/(1 + cy)}}};
record = <|"Family" -> "FIELD_CANONICALIZER", "Sector" -> 2,
  "LowerSector" -> 1, "Variables" -> {cx, cy}, "Regulator" -> ce,
  "OffDiagonalBlockEquation" -> {zero11, zero11, inhomogeneity}|>;
report["the strip's inhomogeneity", inhomogeneity];

(* ---- C1: the transport side is the reference ---- *)
transportCensus = frameIndices[record["OffDiagonalBlockEquation"], declaredRoots];
check["C1 the TRANSPORT census denests x y and reports root indices {1,2}",
  Lookup[transportCensus, "RootIndices", {}] === {1, 2} &&
    Lookup[transportCensus, "UnclassifiedRadicalBases", {1}] === {}];
report["C1 transport census", KeyTake[transportCensus,
  {"RootIndices", "RadicalBases", "UnclassifiedRadicalBases"}]];

(* ---- C2 / C3: the solver census now agrees ---- *)
solverCensus = census[record["OffDiagonalBlockEquation"], declaredRoots];
check["C2 the SOLVER census classifies the same strip exactly",
  Lookup[solverCensus, "Status", None] === "ExactRootClassification" &&
    Lookup[solverCensus, "RootIndices", {}] === {1, 2} &&
    Lookup[solverCensus, "UnclassifiedRadicalBases", {1}] === {}];
report["C2 solver census", KeyTake[solverCensus,
  {"Status", "RootIndices", "UnclassifiedRadicalBases",
   "DenestedRootIndices"}]];
check["C3 the census carries the verified rewrite of the denested base",
  AssociationQ[Lookup[solverCensus, "DenestedRadicalBases", None]] &&
    Length[solverCensus["DenestedRadicalBases"]] === 1 &&
    TrueQ[Together[First[Keys[solverCensus["DenestedRadicalBases"]]] -
      cx cy] === 0] &&
    TrueQ[Lookup[First[Values[solverCensus["DenestedRadicalBases"]]],
      "SquareIdentity", False]]];

(* ---- C4: the rewrite ---- *)
canonical = canonicalize[record["OffDiagonalBlockEquation"], declaredRoots, solverCensus];
check["C4 the canonicalizer rewrites the strip into declared radicals",
  Lookup[canonical, "Status", None] === "RadicalsCanonicalized" &&
    canonical["Rewritten"] >= 1 &&
    FreeQ[canonical["Expression"], Sqrt[cx cy]] &&
    FreeQ[canonical["Expression"], Power[cx cy, _Rational]]];
canonicalInhomogeneity = canonical["Expression"][[3]];
(* the rewrite is exact where the declared squares are positive, which is
   the region transportChartDenestSign fixes the global sign in; that is
   the statement to make, not an unassumed Simplify (Sqrt[x y] and
   Sqrt[x] Sqrt[y] differ by a branch sign off that region) *)
check["C4 every rewritten entry EQUALS the original where the declared \
squares are positive",
  AllTrue[Transpose[{Flatten[inhomogeneity], Flatten[canonicalInhomogeneity]}],
    TrueQ[Simplify[Together[#1[[1]] - #1[[2]]],
      Assumptions -> cx > 0 && cy > 0] === 0] &]];
check["C4 and numerically, at two rational points of that region",
  AllTrue[{{cx -> 4, cy -> 9, ce -> 3}, {cx -> 2/5, cy -> 7/3, ce -> 1/2}},
    Function[point, AllTrue[
      Transpose[{Flatten[inhomogeneity], Flatten[canonicalInhomogeneity]}],
      Function[pair, TrueQ[Chop[N[(pair[[1]] - pair[[2]]) /. point, 40]] === 0]]]]]];
report["C4 canonical inhomogeneity", canonicalInhomogeneity];

(* ---- C5: the concrete consequence ---- *)
rawEntry = inhomogeneity[[1, 1, 1]];
canonicalEntry = canonicalInhomogeneity[[1, 1, 1]];
rawChannels = Quiet[decompose[rawEntry, declaredRoots]];
canonicalChannels = Quiet[decompose[canonicalEntry, declaredRoots]];
check["C5 the RAW entry does not decompose (this is the reported defect)",
  rawChannels === $Failed];
check["C5 the CANONICAL entry decomposes into four channels",
  ListQ[canonicalChannels] && Length[canonicalChannels] === 4];
check["C5 those channels recompose exactly to the original entry",
  ListQ[canonicalChannels] &&
    TrueQ[Simplify[Together[compose[canonicalChannels, declaredRoots] -
      rawEntry], Assumptions -> cx > 0 && cy > 0] === 0]];
report["C5 channels", canonicalChannels];

(* ---- C6 / C7: end to end through prepare ---- *)
prepared = prepare[record, frame, "OneForms" -> {}];
check["C6 prepare accepts the strip end to end, at rank 2",
  Lookup[prepared, "Status", None] === "PreparedMultiquadraticOffDiagonalBlockV1" &&
    prepared["RootCount"] === 2 && prepared["GradeCount"] === 4];
check["C6 the preparation's stored record carries the CANONICAL strip",
  AssociationQ[Lookup[prepared, "Record", None]] &&
    FreeQ[prepared["Record"]["OffDiagonalBlockEquation"], Power[cx cy, _Rational]]];
report["C6 prepare", KeyTake[prepared,
  {"Status", "RootCount", "GradeCount", "UnknownCount"}]];
check["C7 the preparation records what the canonicalizer rewrote",
  AssociationQ[Lookup[prepared, "RadicalCanonicalization", None]] &&
    Lookup[prepared["RadicalCanonicalization"], "Status", None] ===
      "RadicalsCanonicalized" &&
    Lookup[prepared["RadicalCanonicalization"], "Rewritten", 0] >= 1];
report["C7 canonicalization provenance",
  Lookup[prepared, "RadicalCanonicalization", None]];

(* ---- C8: the negative control ---- *)
undeclared = Sqrt[1 + cx + cy];
badInhomogeneity = {{{ce undeclared}}, {{0}}};
badRecord = Join[record, <|"OffDiagonalBlockEquation" -> {zero11, zero11, badInhomogeneity}|>];
badCensus = census[badRecord["OffDiagonalBlockEquation"], declaredRoots];
check["C8 NEGATIVE CONTROL: a genuinely undeclared radical is still \
unclassified",
  Lookup[badCensus, "Status", None] === "UnclassifiedRadicals" &&
    Length[Lookup[badCensus, "UnclassifiedRadicalBases", {}]] === 1];
check["C8 and prepare still refuses it, typed",
  Lookup[prepare[badRecord, frame, "OneForms" -> {}], "Status", None] ===
    "OffDiagonalBlockEquationContainsUndeclaredRadicals"];
report["C8 refused bases", Lookup[badCensus, "UnclassifiedRadicalBases", {}]];

(* ---- C9: no-op on an all-declared strip ---- *)
plainInhomogeneity = {{{ce (1 + Sqrt[cx])/(1 + cx)}}, {{ce Sqrt[cy]}}};
plainRecord = Join[record, <|"OffDiagonalBlockEquation" -> {zero11, zero11, plainInhomogeneity}|>];
plainCensus = census[plainRecord["OffDiagonalBlockEquation"], declaredRoots];
plainCanonical = canonicalize[plainRecord["OffDiagonalBlockEquation"], declaredRoots, plainCensus];
check["C9 a strip whose radicals are all declared squares is classified \
without denesting",
  Lookup[plainCensus, "Status", None] === "ExactRootClassification" &&
    Lookup[plainCensus, "RootIndices", {}] === {1, 2} &&
    Lookup[plainCensus, "DenestedRadicalBases", <||>] === <||>];
check["C9 the canonicalizer is then a NO-OP and says so",
  Lookup[plainCanonical, "Status", None] ===
      "NoRadicalCanonicalizationNeeded" &&
    plainCanonical["Expression"] === plainRecord["OffDiagonalBlockEquation"] &&
    plainCanonical["Rewritten"] === 0];

(* ---- C10: literal algebra-generator symbols ---- *)
Clear[taggedRoot, taggedDelta];
taggedRoots = {<|"Generator" -> taggedRoot,
  "QuadraticRadicand" -> taggedDelta|>};
taggedChannels = decompose[(1 + taggedRoot)/(2 + taggedRoot),
  taggedRoots, False, False];
check["C10 a literal declared root symbol enters the algebraic path",
  ListQ[taggedChannels] && Length[taggedChannels] === 2 &&
    FreeQ[taggedChannels, taggedRoot]];
check["C10 literal-root channels are reduced with r^2 equal to its square",
  ListQ[taggedChannels] &&
    And @@ (TrueQ[Together[#1] === 0] & /@
      (taggedChannels - {(2 - taggedDelta)/(4 - taggedDelta),
        1/(4 - taggedDelta)}))];

Print["t_multiquadratic_field_canonicalizer: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
