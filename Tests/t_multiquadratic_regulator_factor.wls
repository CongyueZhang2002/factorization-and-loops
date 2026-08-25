(* FactorFamilyRegulatorDependenceMultiquadratic (2026-08-25, CF259).

   A root set with no joint rational chart (CF259's three declared
   squares: the triple cover is a K3 surface) used to be a typed stop.
   The constant T(eps) is now sought in the graded algebra
   Q(x,y)[r1,r2,r3]/(ri^2 - qi) itself: T lies in grade 0, so conjugation
   acts grade by grade and the 2^k grade components -- ordinary rational
   matrices -- carry the same linear problem the rational route solves.

   Checks here:
     planted-T recovery on a clean 3-root eps-form conjugated by a known
       eps-dependent T, with the gauge identity re-verified in the algebra;
     sign-sheet consistency (all 2^k embeddings of a split point agree);
     a rational-frame input still routes to the rational path unchanged;
     a connection with genuinely non-factorable regulator dependence is
       refused, typed, and the driver's terminal stop survives. *)
root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]]);
x = Symbol["Global`x"]; y = Symbol["Global`y"]; eps = Symbol["Global`eps"];
v = Symbol["Global`v"]; w = Symbol["Global`w"];

(* CF259's declared root squares, in the identity frame *)
q1 = (1 - x - y)^2 - 4 x y;
q2 = (1 - x + y)^2 + 4 x y;
q3 = 4 x + y^2;
frame = <|"Name" -> "TestTripleRoot", "Kind" -> "TwoVariable",
  "CoefficientField" -> "Multiquadratic", "Variables" -> {x, y},
  "Subst" -> {v -> x, w -> y},
  "Roots" -> {<|"Root" -> Sqrt[q1], "RootSquare" -> (1 - v - w)^2 - 4 v w|>,
    <|"Root" -> Sqrt[q2], "RootSquare" -> (1 - v + w)^2 + 4 v w|>,
    <|"Root" -> Sqrt[q3], "RootSquare" -> 4 v + w^2|>}|>;
r1 = Sqrt[q1]; r2 = Sqrt[q2]; r3 = Sqrt[q3];
dl[L_] := Map[Together, {D[Log[L], x], D[Log[L], y]}];

check["the catalog has no joint rational chart for the CF259 triple",
  MissingQ[FeynFacet`TransportRootSetChart[
    {(1 - v - w)^2 - 4 v w, (1 - v + w)^2 + 4 v w, 4 v + w^2}, {v, w}]]];

(* ---- a clean 3-root eps-form and a planted eps-dependent T ---- *)
k1 = {{1, 0, 0}, {0, -1, 0}, {2, 0, 0}};
k2 = {{0, 1, 0}, {1, 0, 0}, {0, 0, 3}};
k3 = {{2, 0, 1}, {0, 0, 0}, {0, 1, -2}};
k4 = {{0, 0, 0}, {1, 0, 0}, {0, 2, 0}};
k5 = {{1, 1, 0}, {0, 0, 2}, {0, 0, 1}};
k6 = {{0, 0, 3}, {0, 1, 0}, {1, 0, 0}};
letters = {x, y, 1 - x - y,
  (1 - x - y + r1)/(1 - x - y - r1),
  (1 - x + y + r2)/(1 - x + y - r2),
  (y + r3)/(y - r3)};
residues = {k1, k2, k3, k4, k5, k6};
canonical = Table[
  eps Sum[residues[[a]] dl[letters[[a]]][[mu]], {a, Length[letters]}], {mu, 2}];
check["the planted eps-form is eps-factored",
  FeynFacet`Private`familyRegulatorFactoredQ[canonical[[1]], eps] &&
    FeynFacet`Private`familyRegulatorFactoredQ[canonical[[2]], eps]];
tKnown = {{1, eps, 0}, {0, 1 + 4 eps, 0}, {eps^2, 0, 1/(1 - 2 eps)}};
tKnownInverse = Map[Together, Inverse[tKnown], {2}];
connection = Table[
  Map[Together, tKnown . canonical[[mu]] . tKnownInverse, {2}], {mu, 2}];
(* the radicands are compared through the frame's classifier, not
   syntactically: Together writes Sqrt[(1-x-y)^2-4xy] in expanded form
   and a FreeQ on the unexpanded radicand is then false for a connection
   that does carry the root *)
check["the conjugated input carries all three declared roots",
  FeynFacet`Private`transportChartRootIndices[connection,
    FeynFacet`Private`transportChartCurrentRoots[frame, {x, y}]][
      "RootIndices"] === {1, 2, 3}];
check["the conjugated input is not eps-factored",
  ! (FeynFacet`Private`familyRegulatorFactoredQ[connection[[1]], eps] &&
     FeynFacet`Private`familyRegulatorFactoredQ[connection[[2]], eps])];

(* a generous ABSOLUTE deadline must not change the accepted result:
   the plumbing of Codex 0830 P2 is a cooperative stop, not a new gate *)
{sec, f} = AbsoluteTiming[FeynFacet`FactorFamilyRegulatorDependenceInFrame[
  connection, {x, y}, eps, frame, "Deadline" -> AbsoluteTime[] + 3600,
  "Verbose" -> False]];
Print["planted T: ", If[AssociationQ[f],
  KeyTake[f, {"Status", "Method", "Chart", "RootIndices", "Rank", "GradeCount",
    "Points", "ExactEpsFactorization", "ExactInverse"}], f],
  " (", Round[sec, 0.1], " s)"];
check["planted T: status OK", AssociationQ[f] && f["Status"] === "OK"];
check["planted T: routed through the graded algebra, no chart",
  AssociationQ[f] && StringQ[f["Method"]] &&
    StringMatchQ[f["Method"], "MultiquadraticGradedAlgebra/*"] &&
    f["Chart"] === None && Sort[f["RootIndices"]] === {1, 2, 3}];
check["planted T: rank 3, 8 grades",
  AssociationQ[f] && f["Rank"] === 3 && f["GradeCount"] === 8];
If[AssociationQ[f] && f["Status"] === "OK",
  tRec = f["Transformation"]; tRecInverse = f["Inverse"];
  check["planted T: T is constant in the variables and eps-dependent",
    FreeQ[tRec, x | y] && ! FreeQ[tRec, eps]];
  check["planted T: the inverse identity is exact",
    And @@ Flatten[Map[TrueQ[# === 0] &,
      Together[tRec . tRecInverse - IdentityMatrix[3]], {2}]] &&
    And @@ Flatten[Map[TrueQ[# === 0] &,
      Together[tRecInverse . tRec - IdentityMatrix[3]], {2}]]];
  check["planted T: the route reports the exact grade-wise statement",
    TrueQ[f["ExactEpsFactorization"]] && TrueQ[f["ExactInverse"]]];
  (* the returned connection is eps-factored, decided grade by grade in
     the algebra (never by Together on an entry carrying a radical) *)
  gradedRoots = FeynFacet`Private`familyRegulatorGradedRoots[
    FeynFacet`Private`transportChartCurrentRoots[frame, {x, y}],
    Lookup[f, "NumericRadicalClasses", {}]];
  newGrades = FeynFacet`Private`familyRegulatorGradedMatrices[
    f["Connection"], gradedRoots];
  check["planted T: the output decomposes in the declared algebra",
    AssociationQ[newGrades] && newGrades["Status"] === "OK"];
  check["planted T: every grade of the output is eps-factored",
    AssociationQ[newGrades] && newGrades["Status"] === "OK" &&
      FeynFacet`Private`familyRegulatorFactoredQ[newGrades["Grades"], eps]];
  (* the gauge identity itself, in the algebra: r-symbol reduction, not
     Together (2026-08-25) *)
  check["planted T: the gauge identity holds in the algebra (all entries)",
    And @@ Flatten[Table[
      FeynFacet`Private`transportChartAlgebraicZeroQ[
        Sum[tRecInverse[[i, a]] connection[[mu, a, b]] tRec[[b, j]],
          {a, 3}, {b, 3}] - f["Connection"][[mu, i, j]],
        FeynFacet`Private`transportChartCurrentRoots[frame, {x, y}]] === True,
      {mu, 2}, {i, 3}, {j, 3}]]];
  (* the recovered T is equivalent to the planted one: the residual
     conjugation tKnown . tRec is eps-free up to the free constants Libra
     leaves, so the composite connection is the same eps-form *)
  check["planted T: the recovered connection is an eps-form with constant residues",
    And @@ Flatten[Table[FreeQ[Together[f["Connection"][[mu, i, j]]/eps], eps],
      {mu, 2}, {i, 3}, {j, 3}]]];
  corr = Lookup[f, "ModularCorroboration", <||>];
  Print["planted T: corroboration ", KeyTake[corr, {"Status", "Primes"}]];
  (* the corroboration must not be vacuous: two DISTINCT primes, two
     records, and a real split point in each.  Measured 2026-08-25: a
     Module local named after a pattern variable made "Primes" an
     unevaluated Module, the record list empty, and AllTrue[{}, ...]
     reported "Corroborated" on no evidence at all. *)
  check["planted T: sign-sheet corroboration at two DISTINCT fresh primes",
    AssociationQ[corr] && corr["Status"] === "Corroborated" &&
      VectorQ[corr["Primes"], PrimeQ] &&
      Length[DeleteDuplicates[corr["Primes"]]] === 2 &&
      corr["RecordCount"] === 2 && Length[corr["Records"]] === 2 &&
      AllTrue[corr["Records"], Lookup[#, "Status", None] === "OK" &] &&
      AllTrue[corr["Records"], VectorQ[Lookup[#, "Point", None], IntegerQ] &] &&
      AllTrue[corr["Records"],
        Length[DeleteDuplicates[Lookup[#, "RegulatorValues", {}]]] === 2 &]];
  check["planted T: all 8 sign-sheet embeddings agree at every prime",
    AssociationQ[corr] && AllTrue[corr["Records"], Function[record,
      Lookup[record, "SheetCount", 0] === 8 &&
        Length[Lookup[record, "SheetsEpsilonIndependent", {}]] === 16 &&
        TrueQ[Lookup[record, "AllSheetsAgree", False]]]]];
  check["planted T: the composition round trip was spot-checked exactly",
    AssociationQ[Lookup[f, "CompositionSpotCheck", None]] &&
      TrueQ[f["CompositionSpotCheck"]["Zero"]] &&
      f["CompositionSpotCheck"]["Checked"] >= 1];
  check["planted T: a propagation seal is attached",
    AssociationQ[Lookup[f, "PropagationSeal", None]] &&
      f["PropagationSeal"]["Schema"] === "FeynFacetRegulatorPropagationSeal"];
  check["planted T: a generous deadline skipped no evidence stage",
    Lookup[f, "DeadlineSkippedStages", $Failed] === {} &&
      NumericQ[Lookup[f, "GradeDecompositionSeconds", $Failed]]];
  g = FeynFacet`FactorFamilyRegulatorDependenceInFrame[
    f["Connection"], {x, y}, eps, frame];
  check["planted T: idempotent (AlreadyEpsFactored on the output)",
    AssociationQ[g] && g["Status"] === "AlreadyEpsFactored"]];

(* ---- a rational-frame input must not change behavior ---- *)
letters0 = {x, y, 1 - x - y};
canonical0 = Table[
  eps Sum[{k1, k2, k3}[[a]] dl[letters0[[a]]][[mu]], {a, 3}], {mu, 2}];
connection0 = Table[
  Map[Together, tKnown . canonical0[[mu]] . tKnownInverse, {2}], {mu, 2}];
f0 = FeynFacet`FactorFamilyRegulatorDependenceInFrame[
  connection0, {x, y}, eps, frame];
Print["rational input: ", If[AssociationQ[f0],
  KeyTake[f0, {"Status", "Method", "RootIndices"}], f0]];
check["rational input still routes to the rational path unchanged",
  AssociationQ[f0] && f0["Status"] === "OK" && f0["RootIndices"] === {} &&
    f0["Method"] === "ExactRationalSamples"];

(* ---- genuinely non-factorable regulator dependence ---- *)
(* diag(1, eps, 1) as a residue: its eigenvalues are conjugation
   invariants and two of them differ in eps, so NO constant T removes the
   regulator.  With an algebraic letter present the connection enters the
   graded route, which must refuse -- typed -- and leave the caller's
   terminal stop in place. *)
(* all THREE roots must be present, or the pair {q1, q3} finds a joint
   catalogued chart and the connection never reaches the graded route
   (measured 2026-08-25: with only r1 and r3 the chart route runs and
   returns its own "NotFactored") *)
bad1 = {{1, 0, 0}, {0, eps, 0}, {0, 0, 1}};
lettersBad = {x, y, (1 - x - y + r1)/(1 - x - y - r1),
  (1 - x + y + r2)/(1 - x + y - r2), (y + r3)/(y - r3)};
residuesBad = {bad1, k2, k4, k5, k6};
connectionBad = Table[
  Map[Together, eps Sum[residuesBad[[a]] dl[lettersBad[[a]]][[mu]],
    {a, Length[lettersBad]}], {2}], {mu, 2}];
check["the non-factorable input is not already eps-factored",
  ! (FeynFacet`Private`familyRegulatorFactoredQ[connectionBad[[1]], eps] &&
     FeynFacet`Private`familyRegulatorFactoredQ[connectionBad[[2]], eps])];
{secBad, fBad} = AbsoluteTiming[
  FeynFacet`FactorFamilyRegulatorDependenceInFrame[
    connectionBad, {x, y}, eps, frame, "PointLadder" -> {1, 2},
    "TimeLimit" -> 120]];
Print["non-factorable: ", If[AssociationQ[fBad],
  KeyTake[fBad, {"Status", "RootIndices"}], fBad], " inner ",
  If[AssociationQ[fBad],
    Lookup[Lookup[fBad, "MultiquadraticFactorization", <||>], "Status", None],
    None], " (", Round[secBad, 0.1], " s)"];
check["non-factorable: the typed stop NoRationalChart survives",
  AssociationQ[fBad] && fBad["Status"] === "NoRationalChart"];
check["non-factorable: the graded route's diagnostics are attached",
  AssociationQ[fBad] &&
    AssociationQ[Lookup[fBad, "MultiquadraticFactorization", None]] &&
    MemberQ[{"NotFactored", "GradeNotEpsFactored",
      "TransformationInverseInvalid", "TransformationNotConstant"},
      fBad["MultiquadraticFactorization"]["Status"]]];
check["non-factorable: no transformation is returned",
  AssociationQ[fBad] && ! KeyExistsQ[fBad, "Transformation"]];

(* ---- the graded decomposition itself ---- *)
gr = FeynFacet`Private`transportChartCurrentRoots[frame, {x, y}];
ch = FeynFacet`Private`familyRegulatorGradedDecompose[
  (3 + r1 r3)/(2 - r2 + x r1 r2 r3), gr];
check["graded decompose: a rank-3 field element gives 8 rational channels",
  ListQ[ch] && Length[ch] === 8 && FreeQ[ch, Power[_, _Rational]]];
check["graded decompose: the compose check reproduces the element",
  ListQ[ch] && TrueQ[FeynFacet`Private`transportChartAlgebraicZeroQ[
    FeynFacet`Private`multiquadraticFieldCompose[ch, gr] -
      (3 + r1 r3)/(2 - r2 + x r1 r2 r3), gr] === True]];
check["graded decompose: an undeclared radical fails closed",
  FeynFacet`Private`familyRegulatorGradedDecompose[Sqrt[1 + x + y^3], gr] === $Failed];
(* a numeric square class becomes an extra graded generator *)
gr4 = FeynFacet`Private`familyRegulatorGradedRoots[gr, {2}];
check["graded roots: a numeric square class raises the rank to 4",
  Length[gr4] === 4 && TrueQ[Together[gr4[[4]]["RootSquare"] - 2] === 0]];
ch4 = FeynFacet`Private`familyRegulatorGradedDecompose[
  (1 + r1)/(1 + Sqrt[2] r2), gr4];
check["graded decompose: Sqrt[2] is carried as a generator, 16 channels",
  ListQ[ch4] && Length[ch4] === 16 && FreeQ[ch4, Power[_, _Rational]]];
check["graded roots: a rational square is not made a generator",
  Length[FeynFacet`Private`familyRegulatorGradedRoots[gr, {4, 1}]] === 3];

(* ------------------------------------------------------------------ *)
(* Codex 0830 P2 -- the grade-zero completeness caveat, made typed      *)
(* ------------------------------------------------------------------ *)
(* The theorem "a constant T lies in grade zero" is exact for the
   non-isotrivial roots: their squares depend on (x, y), so a
   transformation containing them is not constant.  It is NOT correct
   for the NUMERIC square classes the same implementation adds as graded
   generators -- Sqrt[2] eps is constant in {x, y} and has nonzero
   numeric-root grade.  The solve feeds ordinary rational grade matrices
   to Libra and admits only a rational grade-zero candidate, so such a
   valid factorization is missed.  The adversarial fixture below plants
   exactly that T and requires the NARROWED typed refusal, not a silent
   "NotFactored" and not a false success. *)
tAlgebraic = {{1, Sqrt[2] eps, 0}, {0, 1, 0}, {0, 0, 1}};
tAlgebraicInverse = Map[Together, Inverse[tAlgebraic], {2}];
connectionAlgebraic = Table[
  Map[Together, tAlgebraic . canonical[[mu]] . tAlgebraicInverse, {2}], {mu, 2}];
classificationAlgebraic = FeynFacet`Private`transportChartRootIndices[
  connectionAlgebraic, gr];
check["adversarial Sqrt[2] T: the numeric square class 2 is classified",
  MemberQ[Together /@ Lookup[classificationAlgebraic, "NumericRadicalClasses", {}], 2] &&
    classificationAlgebraic["UnclassifiedRadicalBases"] === {}];
grAdversarial = FeynFacet`Private`familyRegulatorGradedRoots[gr,
  Lookup[classificationAlgebraic, "NumericRadicalClasses", {}]];
check["adversarial Sqrt[2] T: the graded generator list is rank 4",
  Length[grAdversarial] === 4];
{secAdv, fAdv} = AbsoluteTiming[
  FeynFacet`FactorFamilyRegulatorDependenceMultiquadratic[
    connectionAlgebraic, {x, y}, eps, grAdversarial,
    "PointLadder" -> {1, 2}, "TimeLimit" -> 120]];
Print["adversarial Sqrt[2] T: ", If[AssociationQ[fAdv],
  KeyTake[fAdv, {"Status", "Rank", "GradeCount", "Complete",
    "NumericGradeGeneratorCount", "NumericGradeGenerators"}], fAdv],
  " (", Round[secAdv, 0.1], " s)"];
check["adversarial Sqrt[2] T: the refusal is the NARROWED ConstantFieldRestriction, \
not an unqualified NotFactored",
  AssociationQ[fAdv] && fAdv["Status"] === "ConstantFieldRestriction"];
check["adversarial Sqrt[2] T: the refusal says the claim is not complete \
and names the generators responsible",
  AssociationQ[fAdv] && fAdv["Complete"] === False &&
    fAdv["NumericGradeGeneratorCount"] === 1 &&
    (Together /@ fAdv["NumericGradeGenerators"]) === {2} &&
    StringQ[fAdv["Reason"]]];
check["adversarial Sqrt[2] T: no transformation is returned",
  AssociationQ[fAdv] && ! KeyExistsQ[fAdv, "Transformation"]];
fAdvFrame = FeynFacet`FactorFamilyRegulatorDependenceInFrame[
  connectionAlgebraic, {x, y}, eps, frame, "PointLadder" -> {1, 2},
  "TimeLimit" -> 120];
check["adversarial Sqrt[2] T: the in-frame route carries the narrowed \
diagnostic to the caller",
  AssociationQ[fAdvFrame] && fAdvFrame["Status"] === "NoRationalChart" &&
    Lookup[Lookup[fAdvFrame, "MultiquadraticFactorization", <||>], "Status",
      None] === "ConstantFieldRestriction"];
(* without a numeric class present the refusal stays unqualified: the
   grade-zero argument IS complete over a purely variable-root field *)
check["no numeric class: the refusal is the unqualified NotFactored",
  AssociationQ[fBad] &&
    Lookup[fBad["MultiquadraticFactorization"], "Status", None] =!=
      "ConstantFieldRestriction"];

(* ------------------------------------------------------------------ *)
(* Codex 0830 P2 -- modular corroboration with RATIONAL root squares    *)
(* ------------------------------------------------------------------ *)
(* The split-point search used raw Mod on the root squares.  Wolfram's
   Mod leaves a rational value a Rational, so the following
   VectorQ[..., IntegerQ] rejected every point of a strip whose q_i is a
   genuine rational function -- e.g. (1 + x)/(1 - y) -- and the
   corroboration could never find a split point.  CF259's squares happen
   to be polynomials, which is why its two corroborations were
   unaffected. *)
check["raw Mod leaves a rational root square a Rational (the defect)",
  ! IntegerQ[Mod[(1 + x)/(1 - y) /. {x -> 3, y -> 7}, 101]]];
check["the modular-rational image maps it into the prime field",
  IntegerQ[FeynFacet`Private`familyRegulatorModularImage[
    (1 + x)/(1 - y), {x -> 3, y -> 7}, 101]] &&
    Mod[FeynFacet`Private`familyRegulatorModularImage[
      (1 + x)/(1 - y), {x -> 3, y -> 7}, 101] (1 - 7) - (1 + 3), 101] === 0];
check["the modular-rational image fails closed on a vanishing denominator",
  FeynFacet`Private`familyRegulatorModularImage[
    1/(x - y), {x -> 3, y -> 3}, 101] === $Failed];
rationalRoots = {
  <|"Root" -> Sqrt[(1 + x)/(1 - y)], "RootSquare" -> (1 + x)/(1 - y)|>,
  <|"Root" -> Sqrt[(2 + y)/(1 + x y)], "RootSquare" -> (2 + y)/(1 + x y)|>};
constantGrades = {{{1, 2}, {0, -1}}, {{0, 1}, {3, 0}}, {{2, 0}, {0, 2}},
  {{0, 0}, {1, 1}}};
(* an eps-factored graded connection: every grade is eps times a constant
   matrix, so every sheet at every regulator value must agree *)
rationalGradeMatrices = Table[eps constantGrades[[g]], {mu, 2}, {g, 4}];
corrRational = FeynFacet`Private`familyRegulatorGradedCorroborate[
  rationalGradeMatrices, rationalRoots, {x, y}, eps,
  IdentityMatrix[2], IdentityMatrix[2], 2];
Print["rational root squares: corroboration ",
  KeyTake[corrRational, {"Status", "Primes", "RecordCount"}]];
check["rational root squares: a split point IS found at both fresh primes",
  AssociationQ[corrRational] && corrRational["Status"] === "Corroborated" &&
    corrRational["RecordCount"] === 2 &&
    AllTrue[corrRational["Records"], Lookup[#, "Status", None] === "OK" &] &&
    AllTrue[corrRational["Records"],
      VectorQ[Lookup[#, "Point", None], IntegerQ] &]];
check["rational root squares: all 4 sign sheets agree at both primes",
  AssociationQ[corrRational] && AllTrue[corrRational["Records"],
    Lookup[#, "SheetCount", 0] === 4 && TrueQ[Lookup[#, "AllSheetsAgree", False]] &]];
(* the root images really are square roots of the rational squares in F_p *)
check["rational root squares: each recorded root image squares to the \
modular image of its root square",
  AssociationQ[corrRational] && AllTrue[corrRational["Records"],
    Function[recordEntry, Module[{p = recordEntry["Prime"],
        pt = recordEntry["Point"], rv = recordEntry["RootValues"]},
      AllTrue[Range[2], Mod[rv[[#]]^2 -
        FeynFacet`Private`familyRegulatorModularImage[
          rationalRoots[[#]]["RootSquare"], Thread[{x, y} -> pt], p], p] === 0 &]]]]];

(* ------------------------------------------------------------------ *)
(* Codex 0830 P2 -- the cooperative absolute deadline                   *)
(* ------------------------------------------------------------------ *)
check["\"Deadline\" is a declared option of all three entry points",
  AllTrue[{FeynFacet`FactorFamilyRegulatorDependence,
      FeynFacet`FactorFamilyRegulatorDependenceInFrame,
      FeynFacet`FactorFamilyRegulatorDependenceMultiquadratic},
    KeyExistsQ[Association[Options[#]], "Deadline"] &]];
check["the default deadline is unbounded (the former behaviour)",
  AllTrue[{FeynFacet`FactorFamilyRegulatorDependence,
      FeynFacet`FactorFamilyRegulatorDependenceInFrame,
      FeynFacet`FactorFamilyRegulatorDependenceMultiquadratic},
    Lookup[Association[Options[#]], "Deadline"] === Infinity &]];
deadlineStages = {"Entry", "FrameEntry", "SamplePoints", "GradeDecomposition",
  "PointLadder", "ExactGradeCheck", "GradeComposition",
  "RadicalCanonicalization", "ChartPullBack"};
typedStopQ[result_] := AssociationQ[result] &&
  result["Status"] === "RegulatorFactorizationDeadlineExpired" &&
  TrueQ[result["Resumable"]] && MemberQ[deadlineStages, result["Stage"]] &&
  NumericQ[result["Seconds"]];
expiredRational = FeynFacet`FactorFamilyRegulatorDependence[
  connection0, {x, y}, eps, "Deadline" -> AbsoluteTime[] - 1];
check["an expired deadline stops the rational route, typed and resumable",
  typedStopQ[expiredRational] && expiredRational["Stage"] === "Entry"];
expiredGraded = FeynFacet`FactorFamilyRegulatorDependenceMultiquadratic[
  connection, {x, y}, eps, gr, "Deadline" -> AbsoluteTime[] - 1];
check["an expired deadline stops the graded route, typed and resumable",
  typedStopQ[expiredGraded] && expiredGraded["Stage"] === "Entry"];
expiredFrame = FeynFacet`FactorFamilyRegulatorDependenceInFrame[
  connection, {x, y}, eps, frame, "Deadline" -> AbsoluteTime[] - 1];
check["an expired deadline stops the in-frame dispatcher before any work",
  typedStopQ[expiredFrame] && expiredFrame["Stage"] === "FrameEntry"];
(* a deadline that falls DURING the stage: the entry check passes and a
   later boundary (or the capped decomposition subcall) catches it.  The
   test does not pin WHICH boundary -- that is a timing accident -- only
   that a boundary catches it and the stop is typed and resumable, and
   that no transformation is handed back from an unfinished stage. *)
midStage = FeynFacet`FactorFamilyRegulatorDependenceMultiquadratic[
  connection, {x, y}, eps, gr, "Deadline" -> AbsoluteTime[] + 0.02,
  "PointLadder" -> {1, 2}, "TimeLimit" -> 120];
Print["mid-stage deadline: ", If[AssociationQ[midStage],
  KeyTake[midStage, {"Status", "Stage", "Resumable"}], midStage]];
check["a deadline falling mid-stage is caught at a stage boundary",
  typedStopQ[midStage] && midStage["Stage"] =!= "Entry"];
check["a mid-stage deadline stop hands back no transformation",
  AssociationQ[midStage] && ! KeyExistsQ[midStage, "Transformation"]];
(* a deadline expiry inside the graded route is NOT the family's typed
   terminal: "NoRationalChart" stops the family, a budget expiry resumes *)
midFrame = FeynFacet`FactorFamilyRegulatorDependenceInFrame[
  connection, {x, y}, eps, frame, "Deadline" -> AbsoluteTime[] + 0.02,
  "PointLadder" -> {1, 2}, "TimeLimit" -> 120];
check["a budget expiry never masquerades as the NoRationalChart terminal",
  AssociationQ[midFrame] && midFrame["Status"] =!= "NoRationalChart" &&
    typedStopQ[midFrame]];

Print["t_multiquadratic_regulator_factor: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
