#!/usr/bin/env wolframscript
(* Deferred (sparse tagged term DAG) construction of the off-diagonal
   block equation's source -- FeynFacet/Private/BlockEquationDeferred.wl.

   MEASURED MOTIVATION.  On CF259 sector 21 the driver spent 536 s of
   silent wall time constructing the source of block (21,18) (run log:
   strip {21,19} announced at +607-536 = +71 s, strip {21,18} at +607 s),
   and 2+ h were measured twice by the campaign watchdog between blocks
   of the 28x28 / 37x37 truncations.  The cost is the symbolic
   materialization Map[Together, A_kj - Sum_m D_km A_mj, {2}], whose
   Together does one polynomial gcd per pair of terms.

   Acceptance criteria, stated before the run:

   (a) EXACT EQUALITY.  For a block-lower-triangular fixture with
       feeders, the deferred route's forcing equals the symbolic route's
       forcing entry by entry as an exact rational identity
       (Together[difference] === 0), and its MODULAR IMAGES equal the
       symbolic route's images exactly over F_p at three
       (prime, regulator, point) triples.

   (b) ABI FAILS CLOSED.  A preparation whose pinned ABI no longer
       matches its own content -- a mutated row index, a mutated feeder
       list, a mutated term operand -- is refused by BOTH the modular
       evaluator and the materializer with
       Status "PreparationFingerprintMismatch".  No value is returned.

   (c) TYPED POINT REJECTIONS.  A denominator-zero point, a prime
       dividing a coefficient denominator, an unassigned symbol and a
       missing parameter rule each produce their own typed status
       (SingularPoint / BadPrime / UnassignedSymbol / MissingParameters),
       are recorded by the census as REJECTIONS, and never contribute a
       zero value to the nonzero census.

   (d) UNTOUCHED ENTRIES PRESERVED BY SameQ.  An entry no feeder touches
       is returned as the connection entry ITSELF (SameQ, not merely
       equal, and not Together'd).

   (e) STRUCTURAL BLOCK PRECONDITION.  A connection whose strict upper
       block triangle is not structurally zero on the blocks the
       truncated row formula reads is refused with Status
       "InvalidBlockStructure" before any term is recorded.

   (f) EXACT ZERO WITHOUT A GCD.  A block whose forcing vanishes
       identically is materialized to exact 0 for every entry, the
       census proves no entry nonzero, and the zero-forcing decision is
       therefore available without the driver's Together pass.

   (g) THE ENVIRONMENT SWITCH REVERTS.  FACET_CONSTRUCTION_ROUTE=Symbolic
       selects the symbolic route; absent or any other value selects the
       deferred route (default on).  The driver dispatches on exactly
       that predicate.

   (h) THE BUDGET BOUNDARIES OF COMMIT 5881d6f ARE NOT REGRESSED.  In the
       driver source the deferred dispatch sits between the
       constructionCheck["Entry"] boundary and the
       constructionCheck["EquationConstructed"] boundary, so the
       cooperative deadline still brackets the construction on both
       routes.  (Tests/Infrastructure/t_construction_budget.wls remains the behavioural
       test of those boundaries and is run unchanged.)

   (i) PHASE TELEMETRY, RATE LIMITED (Codex 2026-08-25 06:30, item A).
       The materializer emits a start record and a progress record
       carrying targets done/total, the interned-operand count and the
       accumulated intern/expand/cancel/canonicalize seconds.  The
       progress record is RATE LIMITED by wall clock: on a fixture that
       finishes inside the interval exactly two records are emitted (the
       forced start and the forced final one), and at interval 0 exactly
       one per target in addition.  FACET_MATERIALIZE_PROGRESS_SECONDS
       moves the default and a malformed value is ignored.

   (j) SERIAL == PARALLEL, EXACTLY (Codex 2026-08-25 06:30, item B).
       Both expensive phases run only after their deterministic IDs exist:
       phase 1 farms independent Together/FactorList canonicalizations, and
       phase 2 farms per-target numerator expansion, per-factor cancellation
       and the final algebraic Together.  The acceptance is
       SameQ, not equality as a rational function: every target's value
       from the parallel route is the SAME EXPRESSION as the serial
       route's, on the rational and on the algebraic fixture alike.  The
       batch plan is a deterministic partition of the targets in target
       order; batch size obeys the estimated-byte cap rather than an
       entry count; a helper that returns nothing costs time and never a
       value (its jobs are recomputed locally, not through the Together
       fallback); with no free helper the route IS the serial route; and
       FACET_MATERIALIZE_PARALLEL=Off reverts it.  No helper kernel is
       ever asked for here: the batch dispatcher is injected, exactly as
       t_broker_adaptive pins its helper ceiling to zero. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];

Clear[x, y, eps, mu0];
prepare = FeynFacet`Private`blockEquationDeferredPrepare;
evaluate = FeynFacet`Private`blockEquationDeferredEvaluate;
census = FeynFacet`Private`blockEquationDeferredNonzeroCensus;
materialize = FeynFacet`Private`blockEquationDeferredMaterialize;
canonicalOperandValue =
  FeynFacet`Private`blockEquationDeferredCanonicalOperandValue;
forcing = FeynFacet`Private`blockEquationDeferredForcing;
routeQ = FeynFacet`Private`blockEquationDeferredRouteQ;
fingerprint = FeynFacet`Private`blockEquationDeferredFingerprint;

(* ---- the fixture: four blocks, feeders 2 and 3 ---------------------- *)
ranges = {{1, 2}, {3}, {4, 5}, {6, 7}};
n = 7;
blockOf[i_] := First[Select[Range[Length[ranges]], MemberQ[ranges[[#]], i] &]];
(* a block-lower-triangular connection with rational entries whose
   denominators are products of the usual letters *)
entry[i_, j_] := With[{s = i + 2 j},
  (eps s + x (i - j) + y j + 1)/((x + i)^Mod[s, 2] (1 - x - y) (y + j))];
connection = Table[
  Table[If[blockOf[i] < blockOf[j], 0, entry[i, j] + muI], {i, n}, {j, n}],
  {muI, 2}];

gauge2 = {{(1 + x)/(y (1 - x))}, {(2 - y)/(x + 3)}};
gauge3 = {{x/(1 + y), (1 - y)/(x + 2)}, {0, (3 + x y)/(1 - x)}};
solved = <|2 -> gauge2, 3 -> gauge3|>;
k = 4; j = 1;
rk = ranges[[k]]; rj = ranges[[j]];

symbolicForcing[conn_, sol_] := Table[
  Map[Together, conn[[mu, rk, rj]] -
    Sum[sol[m] . conn[[mu, ranges[[m]], rj]],
      {m, Select[Sort[Keys[sol]], j < # < k &]}], {2}],
  {mu, 2}];

(* the solver reads its gauge denominator off the forcing entries *)
gaugeDenominatorOf[forcing_] := Module[{pairs, factors, powers},
  pairs = Flatten[
    FeynFacet`Private`finiteFieldStripEntryFactorList /@ Flatten[forcing], 1];
  factors = If[pairs === {}, {}, DeleteDuplicates[pairs[[All, 1]], SameQ]];
  powers = Table[{f, Max[Cases[pairs, {g_, p_} /; SameQ[g, f] :> p]]},
    {f, factors}];
  Times @@ ((First[#]^(Last[#] - 1)) & /@ Select[powers, Last[#] > 1 &])];

prep = prepare[connection, ranges, k, j, solved, {x, y}, eps];
FTAssert["preparation succeeds on the block-lower-triangular fixture",
  Lookup[prep, "Status", None] === "Prepared"];
FTAssert["preparation records both feeders",
  Lookup[prep, "Feeders", {}] === {2, 3}];
FTAssert["preparation records one term DAG entry per candidate entry",
  Length[Lookup[prep, "Records", {}]] ===
    2 Length[rk] Length[rj]];
FTAssert["preparation forms no Together of any accumulated sum",
  FreeQ[Lookup[prep, "Records", {}], Together]];
(* A Plus-headed connection entry stays ONE Base term.  Splitting it
   into one term per summand was measured on CF259 (21,18) on
   2026-08-25: term count 46 -> 110 and materialization 166 s -> more
   than 630 s, because the common denominator is a per-factor MAXIMUM
   and every added term can only enlarge it.  The pinned behaviour is
   the measured one. *)
plusBaseConnection = connection;
Do[plusBaseConnection[[a, rk[[1]], rj[[1]] ]] =
    1/(1 + x) + eps/(1 - y) + x y/(1 - x - y), {a, 2}];
prepWhole = prepare[plusBaseConnection, ranges, k, j, solved, {x, y}, eps];
FTAssert["a Plus-headed base stays one Base term",
  Count[Lookup[FirstCase[prepWhole["Records"],
      r_ /; r["Target"] === {1, 1, 1} :> r, <||>], "Terms", {}],
    term_ /; term["Kind"] === "Base"] === 1];
FTAssert["the Base term reads back as the connection entry SameQ",
  FeynFacet`Private`blockEquationDeferredRecordBase[
      FirstCase[prepWhole["Records"],
        r_ /; r["Target"] === {1, 1, 1} :> r, <||>]] ===
    plusBaseConnection[[1, rk[[1]], rj[[1]] ]]];
FTAssert["a Plus-headed base still materializes exactly",
  Module[{ms = materialize[prepWhole],
     ss = symbolicForcing[plusBaseConnection, solved]},
   Lookup[ms, "Status", None] === "OK" &&
     AllTrue[Flatten[Table[
        Together[ms["Values"][{a, b, c}] - ss[[a, b, c]]],
        {a, 2}, {b, Length[rk]}, {c, Length[rj]}]], TrueQ[# === 0] &]]];

bbarSymbolic = symbolicForcing[connection, solved];
mat = materialize[prep];
FTAssert["materialization succeeds",
  Lookup[mat, "Status", None] === "OK"];
(* the factored-LCM assembly must actually run: a silent fall back to
   Together[Total[terms]] would pass every value assertion below while
   reintroducing exactly the cost this file exists to remove *)
FTAssert["materialization uses the factored assembly, not the fallback",
  Lookup[mat, "Fallbacks", -1] === 0];
FTAssert["materialization interns its operands once",
  0 < Lookup[Lookup[mat, "Statistics", <||>], "InternedOperands", 0] <=
    Total[Length[Lookup[#, "Terms", {}]] & /@ prep["Records"]] 2];
dims = prep["Dimensions"];
bbarDeferred = Table[mat["Values"][{a, b, c}],
  {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}];

(* (a) exact equality *)
FTAssert["(a) deferred forcing equals symbolic forcing exactly",
  AllTrue[Flatten[Table[
      Together[bbarDeferred[[a, b, c]] - bbarSymbolic[[a, b, c]]],
      {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}]],
    TrueQ[# === 0] &]];

(* (a) modular image equality at three (prime, regulator, point) triples *)
imageTriples = {{{12345, 54321}, 7, 1000003},
   {{99991, 31337}, -3, 1000033}, {{4242, 8484}, 1/5, 1000037}};
imageAgreement = Table[
  Module[{ev, sym},
   ev = evaluate[prep, t[[1]], t[[2]], t[[3]]];
   If[Lookup[ev, "Status", None] =!= "OK", False,
    sym = Table[
      Module[{q = Together[bbarSymbolic[[a, b, c]] /.
          {x -> t[[1, 1]], y -> t[[1, 2]], eps -> t[[2]]}]},
       Mod[Numerator[q] PowerMod[Denominator[q], -1, t[[3]]], t[[3]]]],
      {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}];
    sym === ev["Image"]]],
  {t, imageTriples}];
FTAssert["(a) modular images agree with the symbolic route at 3 triples",
  imageAgreement === {True, True, True}];

(* (b) the ABI fails closed *)
mutatedRow = prep; mutatedRow["RowIndices"] = {6, 6};
mutatedFeeders = prep; mutatedFeeders["Feeders"] = {2};
mutatedTerm = prep;
mutatedTerm["Records"] = MapAt[
  Function[terms, MapAt[Append[#, "Coefficient" -> -2] &, terms, 1]],
  prep["Records"], {1, "Terms"}];
FTAssert["(b) a mutated row index is refused by the evaluator",
  Lookup[evaluate[mutatedRow, {11, 13}, 3, 1000003], "Status", None] ===
    "PreparationFingerprintMismatch"];
FTAssert["(b) a mutated feeder list is refused by the evaluator",
  Lookup[evaluate[mutatedFeeders, {11, 13}, 3, 1000003], "Status", None] ===
    "PreparationFingerprintMismatch"];
FTAssert["(b) a mutated term operand is refused by the evaluator",
  Lookup[evaluate[mutatedTerm, {11, 13}, 3, 1000003], "Status", None] ===
    "PreparationFingerprintMismatch"];
FTAssert["(b) a mutated ABI is refused by the materializer",
  Lookup[materialize[mutatedTerm], "Status", None] ===
    "PreparationFingerprintMismatch"];
FTAssert["(b) the intact preparation carries a self-consistent ABI",
  prep["Fingerprint"] === fingerprint[KeyDrop[prep, "Fingerprint"]]];

(* (c) typed point rejections *)
(* a denominator-zero point: the letter (1 - x - y) vanishes *)
singular = evaluate[prep, {3, 1000001}, 5, 1000003];
FTAssert["(c) a denominator-zero point is typed SingularPoint",
  Lookup[singular, "Status", None] === "SingularPoint"];
FTAssert["(c) a denominator-zero point returns no image",
  ! KeyExistsQ[singular, "Image"]];
(* a bad prime: the regulator value has a denominator divisible by p *)
FTAssert["(c) a prime dividing the regulator denominator is typed BadPrime",
  Lookup[evaluate[prep, {11, 13}, 1/1000003, 1000003], "Status", None] ===
    "BadPrime"];
FTAssert["(c) a non-prime modulus is typed InvalidPrime",
  Lookup[evaluate[prep, {11, 13}, 3, 1000000], "Status", None] ===
    "InvalidPrime"];
FTAssert["(c) a non-integer point is typed InvalidPoint",
  Lookup[evaluate[prep, {11/2, 13}, 3, 1000003], "Status", None] ===
    "InvalidPoint"];
(* an unassigned symbol: a free parameter with no rule *)
parametricGauge = <|2 -> gauge2, 3 -> gauge3 * Global`lambdaP|>;
prepParametric = prepare[connection, ranges, k, j, parametricGauge,
  {x, y}, eps];
FTAssert["(c) a free parameter is collected into the pinned ABI",
  MemberQ[Lookup[prepParametric, "Parameters", {}], Global`lambdaP]];
FTAssert["(c) a missing parameter rule is typed MissingParameters",
  Lookup[evaluate[prepParametric, {11, 13}, 3, 1000003], "Status", None] ===
    "MissingParameters"];
FTAssert["(c) an unknown parameter rule is typed UnknownParameters",
  Lookup[evaluate[prep, {11, 13}, 3, 1000003, {Global`lambdaP -> 2}],
    "Status", None] === "UnknownParameters"];
FTAssert["(c) an unassigned symbol is typed UnassignedSymbol",
  Lookup[FeynFacet`Private`blockEquationDeferredModEvaluate[
    x + Global`unassignedQ, <|x -> 3|>, {}, 1000003], "Status", None] ===
    "UnassignedSymbol"];
(* an ALGEBRAIC frame (CF259/CF300/CF303) carries square roots in every
   connection entry; the census must refuse such a point with its own
   status, so the caller falls back to its exact zero test instead of
   reading the refusal as a value *)
FTAssert["(c) an algebraic operand is typed AlgebraicOperandUnsupported",
  Lookup[FeynFacet`Private`blockEquationDeferredModEvaluate[
    Sqrt[x + y]/(1 + x), <|x -> 3, y -> 5|>, {}, 1000003],
    "Status", None] === "AlgebraicOperandUnsupported"];
(* the radical must sit in a DENOMINATOR, as it does in the production
   frames: an algebraic numerator factor never reaches the cancellation
   pass, and CF259 (21,18) carries (1 + x - y + Sqrt[...]) in every
   denominator of the block *)
algebraicRoot = Sqrt[1 - 2 x + x^2 - 2 y - 2 x y + y^2];
algebraicLetter = 1 + x - y + algebraicRoot;
algebraicConnection = connection;
Do[algebraicConnection[[a, ranges[[3]], rj]] =
    connection[[a, ranges[[3]], rj]]/algebraicLetter;
  algebraicConnection[[a, rk, rj]] =
    connection[[a, rk, rj]]/algebraicLetter^2, {a, 2}];
prepAlgebraic = prepare[algebraicConnection, ranges, k, j, solved,
  {x, y}, eps];
algebraicCensus = census[prepAlgebraic, {{{11, 13}, 3, 1000003}}];
FTAssert["(c) an algebraic frame rejects every point and proves nothing",
  Lookup[algebraicCensus, "Status", None] === "AllPointsRejected" &&
    Lookup[algebraicCensus, "NonzeroProvedQ", True] === False &&
    (Lookup[#, "Status", None] & /@
        Lookup[algebraicCensus, "Rejections", {}]) ===
      {"AlgebraicOperandUnsupported"}];
algebraicMaterialized = materialize[prepAlgebraic];
algebraicSymbolic = symbolicForcing[algebraicConnection, solved];
FTAssert["(c) an algebraic frame still materializes exactly",
  Lookup[algebraicMaterialized, "Status", None] === "OK" &&
    AllTrue[Flatten[Table[
       Together[algebraicMaterialized["Values"][{a, b, c}] -
         algebraicSymbolic[[a, b, c]]],
       {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}]],
     TrueQ[# === 0] &]];
FTAssert["(c) an algebraic frame reaches the algebraic canonicalization",
  Lookup[algebraicMaterialized, "AlgebraicEntries", 0] > 0];
(* (a'') CONSERVATIVENESS on an algebraic frame: Together is not
   canonical there, so the deferred entry may keep extra powers of an
   algebraic factor.  The criterion is that the symbolic gauge
   denominator DIVIDES the deferred one -- the solver's ansatz is a
   superset and no gauge can be missed.  MEASURED on CF259 (21,18):
   exponent 5 against the symbolic route's 4 on one factor. *)
algebraicDeferred = Table[algebraicMaterialized["Values"][{a, b, c}],
  {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}];
FTAssert["(a'') on an algebraic frame the symbolic gauge denominator divides the deferred one",
  Module[{gs = gaugeDenominatorOf[algebraicSymbolic],
     gd = gaugeDenominatorOf[algebraicDeferred], ratio},
   ratio = Cancel[gd/gs];
   PolynomialQ[ratio, {x, y, eps, algebraicRoot}]]];
rejectionCensus = census[prep, {
   {{3, 1000001}, 5, 1000003},              (* denominator zero *)
   {{11, 13}, 1/1000003, 1000003},          (* bad prime *)
   {{11, 13}, 3, 1000003}}];                (* accepted *)
FTAssert["(c) the census counts rejections separately from images",
  Lookup[rejectionCensus, "AcceptedSamples", -1] === 1 &&
    Length[Lookup[rejectionCensus, "Rejections", {}]] === 2];
FTAssert["(c) census rejections carry their own typed status",
  Sort[Lookup[#, "Status", None] & /@
      Lookup[rejectionCensus, "Rejections", {}]] ===
    Sort[{"SingularPoint", "BadPrime"}]];

(* (a') THE SOLVER-VISIBLE FORM, stated separately from the value.
   On a RATIONAL frame the factored cancellation is complete and the
   deferred entry's denominator is the symbolic entry's denominator.  On
   an ALGEBRAIC frame Together is not a canonical form, and the deferred
   entry can keep extra powers of an algebraic factor; the criterion
   there is CONSERVATIVENESS -- the symbolic gauge denominator must
   DIVIDE the deferred one, so the solver's ansatz is a superset and no
   gauge can be missed.  MEASURED on CF259 (21,18): exponent 5 against
   the symbolic route's 4 on one algebraic factor. *)
FTAssert["(a') on a rational frame the denominators agree entry by entry",
  And @@ Flatten[Table[
     TrueQ[Together[Denominator[Together[bbarDeferred[[a, b, c]]]] -
        Denominator[Together[bbarSymbolic[[a, b, c]]]]] === 0],
     {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}]]];
FTAssert["(a') on a rational frame the gauge denominator is unchanged",
  TrueQ[Together[gaugeDenominatorOf[bbarDeferred] -
     gaugeDenominatorOf[bbarSymbolic]] === 0]];

(* (d) untouched entries preserved by SameQ *)
(* block 3 columns of block 1 set to zero and block 2 gauge column zero
   makes the entry (1,1,1) receive no feeder term *)
untouchedConnection = connection;
Do[untouchedConnection[[a, ranges[[2]], rj[[1]] ]] = 0;
  untouchedConnection[[a, ranges[[3]], rj[[1]] ]] = 0,
  {a, 2}];
prepUntouched = prepare[untouchedConnection, ranges, k, j, solved,
  {x, y}, eps];
matUntouched = materialize[prepUntouched];
FTAssert["(d) untouched entries are counted",
  Lookup[matUntouched, "UntouchedEntries", 0] === 2 Length[rk]];
FTAssert["(d) an untouched entry is the connection entry itself (SameQ)",
  And @@ Flatten[Table[
     matUntouched["Values"][{a, b, 1}] ===
       untouchedConnection[[a, rk[[b]], rj[[1]] ]],
     {a, 2}, {b, Length[rk]}]]];
FTAssert["(d) untouched entries are not Together'd into a new expression",
  And @@ Flatten[Table[
     SameQ[matUntouched["Values"][{a, b, 1}],
       untouchedConnection[[a, rk[[b]], rj[[1]] ]]],
     {a, 2}, {b, Length[rk]}]]];
(* the driver deliberately overrides that default: the downstream
   alphabet builder reads the entry through CANONICA's
   ExtractIrreducibles and would count the denominators of an
   un-normalized sum as letters *)
matCanonical = materialize[prepUntouched, "CanonicalizeUntouched" -> True];
FTAssert["(d) CanonicalizeUntouched restores the previous canonical form",
  And @@ Flatten[Table[
     SameQ[matCanonical["Values"][{a, b, 1}],
       Together[untouchedConnection[[a, rk[[b]], rj[[1]] ]]]],
     {a, 2}, {b, Length[rk]}]]];
FTAssert["(d) the driver entry point canonicalizes untouched entries",
  Module[{f = forcing[untouchedConnection, ranges, k, j, solved,
      {x, y}, eps]},
   Lookup[f, "Status", None] === "OK" &&
     And @@ Flatten[Table[
        SameQ[f["Forcing"][[a, b, 1]],
          Together[untouchedConnection[[a, rk[[b]], rj[[1]] ]]]],
        {a, 2}, {b, Length[rk]}]]]];

(* (e) structural block precondition *)
badConnection = connection;
badConnection[[1, ranges[[1]][[1]], ranges[[3]][[1]] ]] = 1/(1 + x);
FTAssert["(e) a nonzero strict upper block triangle is refused",
  Lookup[prepare[badConnection, ranges, k, j, solved, {x, y}, eps],
    "Status", None] === "InvalidBlockStructure"];
FTAssert["(e) the refusal names the offending block pair",
  Lookup[prepare[badConnection, ranges, k, j, solved, {x, y}, eps],
    "BlockPair", None] === {1, 3}];

(* (f) exact zero without a gcd *)
zeroConnection = connection;
Do[zeroConnection[[a, ranges[[2]], rj]] =
    ConstantArray[0, {Length[ranges[[2]]], Length[rj]}],
  {a, 2}];
Do[zeroConnection[[a, rk, rj]] =
    gauge3 . zeroConnection[[a, ranges[[3]], rj]],
  {a, 2}];
prepZero = prepare[zeroConnection, ranges, k, j, solved, {x, y}, eps];
matZero = materialize[prepZero];
FTAssert["(f) an identically vanishing forcing materializes to exact 0",
  AllTrue[Values[matZero["Values"]], TrueQ[# === 0] &]];
FTAssert["(f) every entry is reported zero by the materializer",
  Lookup[matZero, "ZeroEntries", 0] === 2 Length[rk] Length[rj]];
zeroCensus = census[prepZero, Flatten[Table[{pt, e0, p0},
   {p0, {1000003, 1000033}}, {pt, {{11, 13}, {101, 307}}},
   {e0, {5, 17}}], 2]];
FTAssert["(f) the census proves no entry nonzero on a zero-forced block",
  Lookup[zeroCensus, "NonzeroProvedQ", True] === False &&
    Lookup[zeroCensus, "AcceptedSamples", 0] > 0];
nonzeroCensus = census[prep, Flatten[Table[{pt, e0, p0},
   {p0, {1000003, 1000033}}, {pt, {{11, 13}, {101, 307}}},
   {e0, {5, 17}}], 2]];
FTAssert["(f) a nonzero image is an exact proof that the block is not zero-forced",
  Lookup[nonzeroCensus, "NonzeroProvedQ", False] === True];

(* the driver entry point agrees with both *)
forced = forcing[connection, ranges, k, j, solved, {x, y}, eps];
FTAssert["the driver entry point returns the same forcing",
  Lookup[forced, "Status", None] === "OK" &&
    AllTrue[Flatten[Table[
        Together[forced["Forcing"][[a, b, c]] - bbarSymbolic[[a, b, c]]],
        {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}]],
      TrueQ[# === 0] &]];
FTAssert["the driver entry point reports the zero-forcing decision",
  Lookup[forced, "ZeroForcingCandidateQ", True] === False &&
    Lookup[forcing[zeroConnection, ranges, k, j, solved, {x, y}, eps],
      "ZeroForcingCandidateQ", False] === True];

(* (g) the environment switch *)
previousRoute = Environment["FACET_CONSTRUCTION_ROUTE"];
SetEnvironment["FACET_CONSTRUCTION_ROUTE" -> "Symbolic"];
FTAssert["(g) FACET_CONSTRUCTION_ROUTE=Symbolic selects the symbolic route",
  routeQ[] === False];
SetEnvironment["FACET_CONSTRUCTION_ROUTE" -> "Deferred"];
FTAssert["(g) FACET_CONSTRUCTION_ROUTE=Deferred selects the deferred route",
  routeQ[] === True];
SetEnvironment["FACET_CONSTRUCTION_ROUTE" -> None];
FTAssert["(g) the deferred route is the default when unset",
  routeQ[] === True];
If[StringQ[previousRoute],
  SetEnvironment["FACET_CONSTRUCTION_ROUTE" -> previousRoute]];

(* (h) the budget boundaries of commit 5881d6f still bracket the
   construction on the deferred route *)
driverSource = Import[FileNameJoin[{root, "Scripts",
   "family_epsform_sector.wls"}], "Text"];
entryBoundary = First[StringPosition[driverSource,
   "constructionCheck[\"Entry\"]"], {0, 0}][[1]];
constructedBoundary = First[StringPosition[driverSource,
   "constructionCheck[\"EquationConstructed\"]"], {0, 0}][[1]];
dispatch = First[StringPosition[driverSource,
   "blockEquation[k, nlow, solvedBlocks]"], {0, 0}][[1]];
probeBoundary = First[StringPosition[driverSource,
   "constructionCheck[\"ZeroForcingProbe\"]"], {0, 0}][[1]];
FTAssert["(h) the driver dispatches on the deferred route predicate",
  StringContainsQ[driverSource, "blockEquationDeferredRoute[]"]];
FTAssert["(h) the driver keeps the symbolic construction as the revert path",
  StringContainsQ[driverSource, "blockEquationSymbolicForcing"]];
FTAssert["(h) the block-equation dispatch sits inside the budget boundaries",
  entryBoundary > 0 && dispatch > 0 && constructedBoundary > 0 &&
    entryBoundary < dispatch < constructedBoundary];
FTAssert["(h) the zero-forcing probe still follows its own boundary",
  probeBoundary > constructedBoundary &&
    StringContainsQ[driverSource, "ZeroForcingCandidateQ"]];

(* ==== (i) phase telemetry ============================================ *)
assembleJob = FeynFacet`Private`blockEquationDeferredAssembleJob;
batchPlan = FeynFacet`Private`blockEquationDeferredBatchPlan;
progressDefault = FeynFacet`Private`blockEquationDeferredProgressIntervalDefault;
parallelRouteQ = FeynFacet`Private`blockEquationDeferredParallelRouteQ;
parallelWorthwhileQ =
  FeynFacet`Private`blockEquationDeferredParallelWorthwhileQ;

FTAssert["(i) tiny four-target rational batches stay below a broker trip",
  ! parallelWorthwhileQ[False, False, 4, ConstantArray[1000, 4]]];
FTAssert["(i) large four-target rational batches use available helpers",
  parallelWorthwhileQ[False, False, 4, ConstantArray[2^19, 4]]];
FTAssert["(i) one target cannot benefit from helper dispatch",
  ! parallelWorthwhileQ[False, False, 1, {2^22}]];

(* The materializer prints its telemetry; capture $Output rather than
   redefining the protected Print.  Two environment defences, both
   measured 2026-08-25 on a KernelPool subkernel: PageWidth -> Infinity,
   because a wrapped record puts its later fields on continuation lines
   and every assertion below reads ONE line; and the quote strip, because
   a pool subkernel formats Print's string arguments in InputForm, so the
   same record arrives as "[deferred-materialize] ""start"": ..." there
   and unquoted in a standalone kernel.  The assertions are then about
   the record's CONTENT in either environment. *)
captureRecords[preparation_, opts___] := Module[
  {file, stream, result, text},
  file = FileNameJoin[{$TemporaryDirectory,
    "t_construction_dag_" <> ToString[$ProcessID] <> "_" <>
      ToString[RandomInteger[10^9]] <> ".txt"}];
  stream = OpenWrite[file, PageWidth -> Infinity,
    FormatType -> OutputForm];
  result = Block[{$Output = {stream}}, materialize[preparation, opts]];
  Close[stream];
  text = Import[file, "Text"];
  Quiet[DeleteFile[file]];
  {result, Select[
    StringTrim /@ StringSplit[
      StringReplace[If[StringQ[text], text, ""], "\"" -> ""], "\n"],
    StringStartsQ[#, "[deferred-materialize]"] &]}];

{matDefaultProgress, linesDefault} = captureRecords[prep, "Parallel" -> False];
FTAssert["(i) a start record and a final record are emitted",
  Length[linesDefault] === 2 &&
    StringContainsQ[First[linesDefault], "start:"] &&
    StringContainsQ[Last[linesDefault], "done:"]];
FTAssert["(i) the start record names the block and the record count",
  StringContainsQ[First[linesDefault], "block {4, 1}"] &&
    StringContainsQ[First[linesDefault], "records 8"] &&
    StringContainsQ[First[linesDefault], "terms"]];
FTAssert["(i) the final record carries targets done/total and every substage",
  StringContainsQ[Last[linesDefault], "targets done 8"] &&
    StringContainsQ[Last[linesDefault], "of 8"] &&
    AllTrue[{"interned operands", "intern seconds", "expand seconds",
       "cancel seconds", "canonicalize seconds"},
      StringContainsQ[Last[linesDefault], #] &]];
FTAssert["(i) the progress record is rate limited by the wall clock",
  Lookup[matDefaultProgress["Statistics"], "ProgressRecords", -1] === 2];
{matEveryTarget, linesEvery} =
  captureRecords[prep, "Parallel" -> False, "ProgressInterval" -> 0.];
(* the SHARED interning phase is 156 of the 196 s of the real CF259
   (21,18) block, so it must report progress of its own; at interval 0
   there is one record per interned record and one per assembled target *)
FTAssert["(i) at interval 0 both phases report one record per entry",
  Length[linesEvery] === 18 &&
    Lookup[matEveryTarget["Statistics"], "ProgressRecords", -1] === 18 &&
    Count[linesEvery, line_ /; StringContainsQ[line, "intern:"]] === 8 &&
    Count[linesEvery, line_ /; StringContainsQ[line, "progress:"]] === 8];
FTAssert["(i) the interning record reports the running record count and pool size",
  StringContainsQ[linesEvery[[2]], "records interned 1"] &&
    StringContainsQ[linesEvery[[9]], "records interned 8"] &&
    StringContainsQ[linesEvery[[2]], "interned operands"] &&
    StringContainsQ[linesEvery[[2]], "target {"]];
FTAssert["(i) a progress record reports the running target count",
  StringContainsQ[linesEvery[[10]], "targets done 1"] &&
    StringContainsQ[linesEvery[[17]], "targets done 8"]];
{matSilent, linesSilent} =
  captureRecords[prep, "Parallel" -> False, "Progress" -> False];
FTAssert["(i) Progress -> False emits no record at all",
  linesSilent === {} &&
    Lookup[matSilent["Statistics"], "ProgressRecords", -1] === 0];
FTAssert["(i) telemetry never changes a value",
  AllTrue[Flatten[Table[
      SameQ[matDefaultProgress["Values"][{a, b, c}],
        matSilent["Values"][{a, b, c}]] &&
      SameQ[matEveryTarget["Values"][{a, b, c}],
        matSilent["Values"][{a, b, c}]],
      {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}]], TrueQ]];
previousProgressSeconds = Environment["FACET_MATERIALIZE_PROGRESS_SECONDS"];
SetEnvironment["FACET_MATERIALIZE_PROGRESS_SECONDS" -> "5"];
FTAssert["(i) FACET_MATERIALIZE_PROGRESS_SECONDS moves the default interval",
  progressDefault[] === 5.];
SetEnvironment["FACET_MATERIALIZE_PROGRESS_SECONDS" -> "not a number"];
FTAssert["(i) a malformed interval is ignored in favour of 60 s",
  progressDefault[] === 60.];
SetEnvironment["FACET_MATERIALIZE_PROGRESS_SECONDS" ->
  If[StringQ[previousProgressSeconds], previousProgressSeconds, None]];

(* ==== (j) serial == parallel, exactly ================================ *)
(* the injected dispatcher runs the SAME pure batch function the pool
   helper runs (blockEquationDeferredMaterializeTask calls it), in this
   kernel: batching, reassembly and the recomputation path are exercised
   and no helper kernel is ever asked for *)
localDispatcher[data_Association, batchList_List] := Map[
  Function[batch,
    Map[Function[job, Quiet[Check[assembleJob[data["Operands"], job,
        data["Cancel"], data["PolynomialSymbols"]], $Failed]]],
      data["Jobs"][[batch]]]],
  batchList];
deadDispatcher[data_Association, batchList_List] :=
  ConstantArray[$Failed, Length[batchList]];
localInternDispatcher[data_Association, batchList_List] := Map[
  Function[batch, canonicalOperandValue /@ data["Expressions"][[batch]]],
  batchList];
deadInternDispatcher[data_Association, batchList_List] :=
  ConstantArray[$Failed, Length[batchList]];

matSerial = materialize[prep, "Parallel" -> False, "Progress" -> False];
matParallel = materialize[prep, "Parallel" -> True, "Helpers" -> 3,
  "BatchDispatcher" -> localDispatcher, "Progress" -> False];
sameValuesQ[a_, b_] := AllTrue[Flatten[Table[
    SameQ[a["Values"][{mu, i, jj}], b["Values"][{mu, i, jj}]],
    {mu, dims[[1]]}, {i, dims[[2]]}, {jj, dims[[3]]}]], TrueQ];
FTAssert["(j) the parallel route returns the SAME EXPRESSION as the serial route",
  sameValuesQ[matSerial, matParallel]];
FTAssert["(j) the parallel route really batched to the helpers",
  Lookup[matParallel["Statistics"], "Route", None] === "Parallel" &&
    Lookup[matParallel["Statistics"], "Batches", 0] === 4 &&
    Lookup[matParallel["Statistics"], "DispatchedBatches", 0] === 3 &&
    Total[Lookup[matParallel["Statistics"], "BatchSizes", {}]] === 8];
FTAssert["(j) the parallel route reports the same counters as the serial one",
  Lookup[matParallel, "ZeroEntries", -1] === Lookup[matSerial, "ZeroEntries", -2] &&
    Lookup[matParallel, "AlgebraicEntries", -1] ===
      Lookup[matSerial, "AlgebraicEntries", -2] &&
    Lookup[matParallel, "Fallbacks", -1] === 0];
matParallelIntern = materialize[prep, "Parallel" -> True, "Helpers" -> 3,
  "InternDispatcher" -> localInternDispatcher,
  "BatchDispatcher" -> localDispatcher, "Progress" -> False];
FTAssert["(j) phase-1 parallel canonicalization is exactly the serial result",
  sameValuesQ[matSerial, matParallelIntern]];
FTAssert["(j) phase 1 dispatches immutable canonicalization batches",
  Lookup[matParallelIntern["Statistics"], "InternRoute", None] ===
      "Parallel" &&
    Lookup[matParallelIntern["Statistics"],
      "InternDispatchedBatches", 0] > 0];
matDeadIntern = materialize[prep, "Parallel" -> True, "Helpers" -> 3,
  "InternDispatcher" -> deadInternDispatcher,
  "BatchDispatcher" -> localDispatcher, "Progress" -> False];
FTAssert["(j) a failed phase-1 helper batch is recomputed exactly on mission",
  sameValuesQ[matSerial, matDeadIntern]];
FTAssert["(j) the batch plan is a deterministic partition in target order",
  Module[{bytes = {7, 3, 11, 2, 5, 13, 1, 9}},
   batchPlan[bytes, 4, 10^9] === batchPlan[bytes, 4, 10^9] &&
     Flatten[batchPlan[bytes, 4, 10^9]] === Range[8] &&
     Length[batchPlan[bytes, 4, 10^9]] === 4]];
FTAssert["(j) large singleton canonicalizations queue largest estimate first",
  FeynFacet`Private`blockEquationDeferredInternQueueOrder[
    Range[4], List /@ Range[4], {10, 100, 100, 3}] === {2, 3, 1, 4}];
FTAssert["(j) four costly targets occupy all three available workers",
  Length[batchPlan[ConstantArray[10, 4], 3, 10^9]] === 3 &&
    Sort[Length /@ batchPlan[
      ConstantArray[10, 4], 3, 10^9]] === {1, 1, 2}];
FTAssert["(j) the batch plan splits on the byte cap, never on an entry count",
  Module[{bytes = ConstantArray[10, 8]},
   batchPlan[bytes, 4, 1] === List /@ Range[8] &&
     batchPlan[bytes, 1, 10^9] === {Range[8]} &&
     Flatten[batchPlan[bytes, 4, 25]] === Range[8]]];
matTinyCap = materialize[prep, "Parallel" -> True, "Helpers" -> 3,
  "BatchByteCap" -> 1, "BatchDispatcher" -> localDispatcher,
  "Progress" -> False];
FTAssert["(j) a byte cap below one entry gives singleton batches and the same values",
  Lookup[matTinyCap["Statistics"], "Batches", 0] === 8 &&
    Lookup[matTinyCap["Statistics"], "BatchSizes", {}] === ConstantArray[1, 8] &&
    sameValuesQ[matSerial, matTinyCap]];
matDeadHelpers = materialize[prep, "Parallel" -> True, "Helpers" -> 3,
  "BatchDispatcher" -> deadDispatcher, "Progress" -> False];
FTAssert["(j) a helper that returns nothing costs time, never a value",
  sameValuesQ[matSerial, matDeadHelpers] &&
    Lookup[matDeadHelpers, "Fallbacks", -1] === 0 &&
    Lookup[matDeadHelpers["Statistics"], "Route", None] === "Parallel"];
matNoHelper = materialize[prep, "Parallel" -> True, "Helpers" -> 0,
  "BatchDispatcher" -> localDispatcher, "Progress" -> False];
FTAssert["(j) with no free helper the route IS the serial route",
  Lookup[matNoHelper["Statistics"], "Route", None] === "Serial" &&
    Lookup[matNoHelper["Statistics"], "DispatchedBatches", -1] === 0 &&
    sameValuesQ[matSerial, matNoHelper]];
(* the algebraic frame exercises the final one-quotient Together inside
   the batched job, which is where an expression could drift in FORM *)
matAlgebraicSerial = materialize[prepAlgebraic, "Parallel" -> False,
  "Progress" -> False];
matAlgebraicParallel = materialize[prepAlgebraic, "Parallel" -> True,
  "Helpers" -> 3, "BatchDispatcher" -> localDispatcher, "Progress" -> False];
FTAssert["(j) on an algebraic frame the two routes agree as expressions too",
  AllTrue[Flatten[Table[
      SameQ[matAlgebraicSerial["Values"][{mu, i, jj}],
        matAlgebraicParallel["Values"][{mu, i, jj}]],
      {mu, dims[[1]]}, {i, dims[[2]]}, {jj, dims[[3]]}]], TrueQ] &&
    Lookup[matAlgebraicParallel, "AlgebraicEntries", 0] > 0];
previousParallel = Environment["FACET_MATERIALIZE_PARALLEL"];
SetEnvironment["FACET_MATERIALIZE_PARALLEL" -> "Off"];
FTAssert["(j) FACET_MATERIALIZE_PARALLEL=Off reverts the second phase",
  parallelRouteQ[] === False &&
    Lookup[materialize[prep, "Helpers" -> 3,
       "BatchDispatcher" -> localDispatcher, "Progress" -> False][
      "Statistics"], "Route", None] === "Serial"];
SetEnvironment["FACET_MATERIALIZE_PARALLEL" -> None];
FTAssert["(j) the parallel second phase is the default when unset",
  parallelRouteQ[] === True &&
    Lookup[materialize[prep, "Helpers" -> 3,
       "BatchDispatcher" -> localDispatcher, "Progress" -> False][
      "Statistics"], "Route", None] === "Parallel"];
SetEnvironment["FACET_MATERIALIZE_PARALLEL" ->
  If[StringQ[previousParallel], previousParallel, None]];
FTAssert["(j) the driver entry point passes the second-phase options through",
  Module[{f = forcing[connection, ranges, k, j, solved, {x, y}, eps,
      "Parallel" -> True, "Helpers" -> 3,
      "BatchDispatcher" -> localDispatcher, "Progress" -> False]},
   Lookup[f, "Status", None] === "OK" &&
     Lookup[Lookup[f["Materialization"], "Statistics", <||>], "Route",
       None] === "Parallel" &&
     And @@ Flatten[Table[
        SameQ[f["Forcing"][[a, b, c]], matSerial["Values"][{a, b, c}]],
        {a, dims[[1]]}, {b, dims[[2]]}, {c, dims[[3]]}]]]];

FTReport[];
