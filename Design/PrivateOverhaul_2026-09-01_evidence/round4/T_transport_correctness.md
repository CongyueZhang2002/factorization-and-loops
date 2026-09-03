# Round 4, agent T: observable-transport correctness points (Codex review 2026-09-02)

Scope: `FeynFacet/Private/Transport/ObservableTransport.wl`,
`FeynFacet/Private/Transport/ObservableTransportFiniteField.wl`,
`Tests/Transport/`. Source of the points:
`Exchange/Codex/2026-09-02/01_private_overhaul_assessment.md`, sections
"Correctness" and the Laurent comment. No other package file was edited;
what other owners need to do is listed at the end. Nothing was committed.

Every kernel run went through the two-seat launcher
(`scratchpad/bench/seat_run.sh`, 300 s cap); wall times below are the
launcher's seat-acquired/released stamps (they include the package load).

## 1. Epsilon valuations are now certified, and the certificate is required

Problem (verified at the old lines 1664-1675): a record's
`TransportEpsilonValuations` (`TMin`, `BlockLower`) were accepted after
integer/length checks only, then set the Laurent range and the physical
convolution; `AcceptedObservableTransportQ` never bound them. A stale
or high value would silently drop a real leading coefficient.

Fix (`ObservableTransport.wl`):

- Certificate machinery, lines 200-620 (new, after the sample-fraction
  grid):
  - `observableTransportEpsilonValuationFingerprint` (line 226): binds a
    certificate to the record's `TTotal`, `TTotalInverse`, `Ranges`,
    variables and regulator (structural `Hash`, stable across kernels in
    one Wolfram version -- checked in two fresh 14.2 kernels; the version
    is recorded and a mismatch is a typed refusal, never a re-trust).
  - `observableTransportExactPointValuations`: one trial, EXACT. The
    entries are specialized at a random rational point; each is then a
    rational function of eps alone with algebraic-number coefficients
    (numeric radicals). Its order is ord(numerator) - ord(denominator)
    at eps = 0 read off the coefficient lists of `Together`'s fraction (a
    common factor changes neither order, so no reduced form is needed);
    numeric radicals are first put in canonical form rational x
    Sqrt[square-free integer] (`observableTransportCanonicalRadicals`),
    and the first nonzero coefficient is decided exactly with
    `RootReduce` (`observableTransportAlgebraicZeroQ`; an undecidable
    coefficient is the typed refusal `CoefficientZeroTestUndecided`,
    never a numeric guess). No prime, no lifting, no series. TMin is the
    minimum over `TTotal`, BlockLower the per-block minimum over the rows
    of `TTotalInverse`, with the same zero-row convention (0) as the
    exact gauge scan; an identically vanishing entry is Infinity, a
    vanishing denominator refuses the point (`PointSingular`).
    Measured on agent L's CF259 entry fixture (8 entries up to 87 KB,
    `scratchpad/round4/T/fixture_profile.wls`): substitution 0.01 s,
    `Together` at most 0.04 s per entry, numerator/denominator degrees
    at most 6, orders -3/-3/-2/0 and one entry identically zero at the
    point; the gcd-free fraction arithmetic tried as an alternative
    blows up to degree 1420 and 5 s per entry, so `Together` it is.
    Two earlier designs, both p-adic (eps = p, Hensel-lifted roots),
    were measured wrong on CF259 and discarded: rooting the prime
    factors of the merged numeric radicands needed 7-13 residue
    conditions per trial (probe run 1: 24 of 24 attempts refused), and
    with symbols per root (probe run 3) a hidden exact zero of an entry
    appears as p-adic noise at every finite precision
    (`PrecisionExhausted` at p^64 in the diagnostic, precision doubling
    until the 300 s cap).
  - `observableTransportCertifyEpsilonValuations`: three trials at
    distinct points drawn from a recorded seed (only where every letter
    and root square is a nonzero rational, via the existing
    `observableTransportPointAdmissibleQ` and
    `transportChartCurrentRoots`). The
    trials must agree with each
    other. A specialization can only RAISE an order, so the observed
    minima are upper bounds that equal the true ones with probability
    1 - O(degree/p) per trial: a claim ABOVE the observation is refused
    (`TransportEpsilonValuationsTooHigh`, with claimed and observed
    values); a claim at or below it is certified, `Tight -> True` when
    equal (a lower claim is conservative: it adds only zero
    coefficients). A record without valuations gets them derived from
    the trials. No symbolic valuation scan anywhere.
  - `observableTransportEpsilonValuationStatus` (line 519): the typed
    status of a record: `TransportEpsilonValuationsNotAvailable`,
    `...Invalid`, `...Uncertified`, `TransportEpsilonValuationCertificateInvalid`
    (flags, trial agreement, claim above observation, certificate not
    naming the record's values), `...CertificateMismatch` (fingerprint),
    `TransportEpsilonValuationsCertified`.
  - `observableTransportCertifyEpsilonValuationsFile` (line 583): the
    in-place certifier for records on disk (`FamilyArtifactRead`, atomic
    replace; `"Write" -> False` for a dry run, `"OutputFile"` for a copy).
- Production path, `BuildObservableTransport` lines 2139-2170: a record
  carrying `TransportEpsilonValuations` is used only when the status is
  `TransportEpsilonValuationsCertified`; every other status is returned
  as the typed refusal. A record without valuations keeps the exact
  gauge scan (never for a transport-ready record, as before). The result
  now carries `TransportEpsilonValuationCertificate` (line 3010: the
  record's certificate with `FingerprintVerified -> True`, or
  `ExactGaugeValuationScan` for the scan) and the certificate entry
  `TransportEpsilonValuationsBound` (line 3059), computed by
  `observableTransportEpsilonValuationCertificateBoundQ` (line 558), not
  a literal `True`.
- `AcceptedObservableTransportQ` (lines 3087-3115): requires
  `TransportEpsilonValuationsBound` among the exact certificates and
  re-checks the binding on the result (source, certificate shape, the
  certificate names the valuations the transport used). A result from
  the previous code (no certificate) is refused.

Tests (`Tests/Transport/t_algebraic_observable_transport.wls`, on the
1x1 fixture with `TTotal = {{eps}}`, `TTotalInverse = {{1/eps}}`, true
orders 1 and {-1}): good record certifies tight (3 trials, distinct
primes, observed 1 / {-1}) and transports accepted with the certificate;
uncertified valuations refused; stale/high `TMin -> 2` and
`BlockLower -> {0}` refused by the certifier with the observed orders; a
claim raised after certification refused (`CertificateInvalid`); a gauge
changed after certification refused (`CertificateMismatch`); a
conservative claim certifies as not tight and transports; a record
without valuations gets them derived; the accept predicate refuses a
result without the certificate, with an altered one, or without the
bound flag; an exact record's scan is bound as `ExactGaugeValuationScan`;
the in-place file certifier on a fixture written to disk: a dry run
leaves it uncertified, the write certifies it (re-read through
`FamilyArtifactRead`), a repeat reports `AlreadyCertified`.
Verdict: 25/25, 5 s wall (13:54:58-13:55:03).

Records on disk: the CF259 transport inputs
(`.../CF259/transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl`)
carry Codex's `ExactAlgebraicPointValuation` values without a
certificate; their typed status is `TransportEpsilonValuationsUncertified`
and the production transport now refuses them until
`observableTransportCertifyEpsilonValuationsFile[file]` has been run
(one load, three p-adic trials, atomic replace; no transport rerun).
CF259: certified in place on 2026-09-02 14:28 (run 5 below): the
certificate is tight, i.e. the exact orders at three random rational
points reproduce Codex's TMin -3 and 27 block bounds; the record's
typed status is now `TransportEpsilonValuationsCertified` and the
production transport accepts it.

Original preserved (coordinator's request, copied with `cp -p` at 13:56
before any write, both files identical at that moment):

| File | SHA-256 |
|---|---|
| `.../CF259/transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl` (before certification, 47,649,635 bytes, mtime 2026-09-02 03:43) | `a470ed037e3538241034804a0c8e4c63ff189f045a71632d81b4cf56b27cb86d` |
| `.../CF259/transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl.before_certificate_2026-09-02.wl` (the copy) | `a470ed037e3538241034804a0c8e4c63ff189f045a71632d81b4cf56b27cb86d` |
| the certified record at the first path (after the write, 14:28:40, 47,651,636 bytes) | `d591dc6f957d039cc03b1fe909b92925e5c158a918c3414c7e760e07924e762f` |

## 2. Radical constants in both fresh-prime selectors

`ObservableTransportFiniteField.wl`: the materialized selector
(`observableTransportModularAlgebraicSubspaceInclusion`, lines 943, 962,
983, 994) and the covariant selector
(`...CovariantSubspaceInclusion`, lines 1098, 1114, 1135, 1146) now read
`RadicalConstants` from the compiled matrix (both compiled parts for the
covariant one) and admit a prime only when every radical constant is a
nonzero quadratic residue at it, next to the declared constant root
squares; the attempt limit and the `InsufficientSplitValidationPrimes`
record include them.

Test `Tests/Transport/t_observable_transport_ff_radical_prime.wls`
(new): replicates the selector's own draw (`SeedRandom[seed]`,
`RandomPrime[{2^30, 2^31-1}]` until p = 3 mod 4) to pick a seed whose
FIRST candidate prime has (5|p) = -1, on a matrix with `Sqrt[5] Sqrt[1+u]`
(radical constant 5, no constant root square). Both selectors must
accept at later primes, none of the primes used is the non-residue one
and all have (5|p) = 1; false inclusions at the same seed are still
rejected. Verdict: 7/7, 3 s wall (13:48:49-13:48:52). Before the fix the
old selector accepted that prime and every point failed inside the
matrix evaluation (`BranchEvaluationFailed`).

### 2b. `modularResidueQ` consolidation (coordinator's request, 14:05)

All ten `JacobiSymbol[...] === 1` sites of
`ObservableTransportFiniteField.wl` (the eight pre-existing ones at the
old lines 542, 551, 753, 761, 975, 997, 1114, 1136 and the two added
above for the radical constants) now call
`modularResidueQ[#, prime] &` from `Core/ModularArithmetic.wl`
(`Mod[value, p] =!= 0 && JacobiSymbol[value, p] === 1`, `$Failed` for an
even or tiny modulus). Identical for the 31-bit primes used there; the
explicit `Mod[#, prime] =!= 0 &&` guards became redundant and were
dropped; the four `deltaValues` sites already exclude 0 beforehand. No
`JacobiSymbol` remains in the file (grep). Re-run after the change:
`t_observable_transport_finite_field` 18/18, 3 s (14:05:26-14:05:29);
`t_observable_transport_ff_radical_scale` 10/10, 4 s (14:06:08-14:06:12);
`t_observable_transport_ff_radical_prime` 7/7, 3 s (14:06:20-14:06:23).

## 3. Sample exhaustion is a typed status

`ObservableTransport.wl` lines 2196-2252: when the fraction grid cannot
supply the full count of admissible rank or residue samples, the run
returns `<|"Status" -> "AdmissibleSamplesExhausted", "SampleKind" ->
"Rank"|"Residue", "Requested", "Available", "Candidates", "Family",
"CoefficientField", "LetterCount", "RootSquareCount"|>` at once; the
former code kept the original (partly inadmissible) samples.

Test `Tests/Transport/t_observable_transport_samples_field.wls` (new):
the algebraic 1x1 fixture with one zero-residue extra letter vanishing
at every grid value of the second variable exhausts the rank samples
(requested 3, available 0, 324 candidates); one vanishing at every grid
value of the first variable exhausts the residue samples (requested 7);
an innocuous letter transports; explicit `RankSamples` bypass the grid.
Verdict (with the point-4 assertions below): 12/12, 3 s wall
(13:48:59-13:49:02).

## 4. Coefficient field: explicit for transport-ready, complete inference otherwise

`ObservableTransport.wl` lines 102-166: `observableTransportCoefficientFieldDeclared`
(record's own `CoefficientField`, chart record, certificate);
`observableTransportRadicalFieldNames` scans Letters, TTotal,
TTotalInverse, EpsFormX, EpsFormY, DLog letters and residues, chart
roots; `observableTransportCoefficientField` returns
`Missing["CoefficientFieldDeclarationRequired"]` for an undeclared
transport-ready record and `Missing["CoefficientFieldRequired", fields]`
for a legacy record with a radical anywhere. `FindObservableTransportPath`
(line 844) returns `CoefficientFieldRequired` instead of assuming
"Rational". `BuildObservableTransport` already refused a Missing field
(`ObservableTransportCoefficientFieldMissingOrInvalid`); it now carries
the reason.

Tests (same file as point 3): radical-free legacy record infers
Rational and gets a path; a radical in TTotalInverse alone, in an
epsilon-form matrix alone, in dlog letters or residues alone, or in a
chart root refuses the inference (a rationalizing chart with rational
roots does not); declarations win (record, chart, certificate); the path
finder refuses; a transport-ready record without a declaration is
refused even when radical-free, and accepted once declared.

## 5. Stale Laurent comment

`ObservableTransport.wl` lines 969-980: the comment now states the
measured fact (SeriesCoefficient is production, ~10 min on CF259; the
jet route with per-coefficient canonicalization did not finish in 21 min
and was stopped; the modular jet route is agent L's work). The selection
(line 980, `"SeriesCoefficient"`) is unchanged.

## 6. `t_algebraic_observable_transport.wls`

Measured before any change: 5 s wall through the seat launcher
(13:33:35-13:33:40; TestKit stamps 4 s after load). The "several
minutes" is not reproduced here; Codex's 180 s non-finish matches the
kernel-start hang recorded in round 3 (paclet manager network fetch,
since disabled with `$AllowInternet = False`). Change: the duplicated
run (`constrainedTransport`, identical demand to `transport`) is removed
and its assertion moved to `transport`; the point-1 assertions were
added there (same fixture). After the additions the test is 25
assertions in 5 s wall. Nothing is gated behind `FACET_TEST_LONG`
because nothing is long; the header comment records the measurement.

## Verification runs (seat launcher, 300 s cap)

| Test | Verdict | Wall (seat stamps) |
|---|---|---|
| `t_algebraic_observable_transport` (modified; run 6 = symbol route with the radical fixture; run 4 before the radical fixture was 25/25 in 5 s, run 5 caught a wrong fixture expectation, not a code defect: Wolfram stores `Sqrt[5] Sqrt[(1-x)/45]` as `Sqrt[1-x]/3`) | 27/27 | 4 s (14:05:58-14:06:02) |
| `t_algebraic_observable_transport` run 7 (final code text: prime-draw bookkeeping added after run 6) | 27/27 | 4 s (14:07:05-14:07:09) |
| `t_observable_transport_ff_radical_prime` (new) | 7/7 | 3 s (13:48:49-13:48:52) |
| `t_observable_transport_samples_field` (new) | 12/12 | 3 s (13:48:59-13:49:02) |
| `t_observable_transport_laurent_jet` (comment-only file change) | 7/7 | 3 s (13:50:35-13:50:38) |
| `t_observable_transport` (regression, CF27 certified record; prints its own table, exit 0) | all 12 checks True, both statuses `ModularlyVerifiedObservableTransport`, `Accepted -> True` | 6 s (13:54:48-13:54:54) |
| `t_observable_transport` re-run on the final text (exact-route certificate) | all 12 checks True, exit 0 | 8 s (14:20:25-14:20:33) |
| `t_observable_transport_finite_field` (regression; re-run after 2b: 18/18, 3 s) | 18/18 | 4 s (13:54:26-13:54:30) |
| `t_observable_transport_ff_radical_scale` (regression, FF file; re-run after 2b: 10/10, 4 s) | 10/10 | 3 s (13:54:36-13:54:39) |
| `t_observable_transport_ff_radical_prime` re-run after 2b | 7/7 | 3 s (14:06:20-14:06:23) |
| `t_observable_transport_covariant_closure` (regression; prints its own table, exit 0) | all 4 checks True | 4 s (13:54:58-13:55:02) |
| CF259 in-place certification probe, run 1 (first radical design) | `TransportEpsilonValuationTrialsInsufficient`: 24 of 24 attempts `RadicandNotResidue` -- the design rooted the prime factors of the merged numeric radicands (7-13 residue conditions per trial); no write | 171 s (13:55:11-13:58:05) |
| CF259 in-place certification probe, run 2 (symbol route) | died at kernel start (`LinkConnect::linkc`, no code executed); processes killed by PID 3391005/3391014/3391015 | 14:03:09-14:05:5x |
| CF259 in-place certification probe, run 3 (symbol route, rule-per-radicand preparation) | KILLED by the 300 s cap (exit 137) after load 3.4 s and fingerprint 0.7 s, no further stage line; no write. Diagnosis: the preparation's `ReplaceAll` carried one rule per distinct radicand (Wolfram tries every rule at every node); replaced by one rule with a hash lookup, then measured stage by stage (next row) | 14:06:23-14:11:42 |
| CF259 preparation/trial diagnostic of the p-adic route (`scratchpad/round4/T/cf259_prep_diag.wls`) | load 3.5 s; 205,698 radical occurrences, 3 distinct radicands (the declared squares); preparation 6.2 s; point substitution of TTotal 0.7 s (1.1 MB after substitution); trial `PrecisionExhausted` at p^64 in 2.9 s -- a hidden exact zero appears as p-adic noise: the p-adic route is abandoned | 14 s (14:13:26-14:13:43) |
| CF259 probe run 4 (exact univariate route, `RootReduce` as the zero test, 120 s cap) | KILLED at the cap after load and status (exit 137); no write | 14:20:37-14:22:43 |
| CF259 probe run 5 (the ONE run allowed by the coordinator at 14:23: instrumented, exact route with the syntactic zero test, 300 s cap; `scratchpad/round4/T/cf259_certify_instrumented.wls`, log `cf259_certify_run5.log`) | `TransportEpsilonValuationsCertified`, TIGHT: three exact trials at {34/303, 49/85}, {87/317, 2/11}, {134/351, 149/295} (46 s, 33 s, 66 s) each give TMin -3 and BlockLower {0,2,3,0,0,1,2,3,2,0,0,0,0,0,1,2,0,2,0,3,0,2,2,0,0,0,0}, equal to Codex's `ExactAlgebraicPointValuation` claim; certifier 146 s; backup verified (SHA-256 equal) before the atomic write (2.5 s, 47,651,636 bytes); re-read status `TransportEpsilonValuationsCertified` | 199 s (14:25:22-14:28:45), exit 0 |

Not run: `t_observable_transport_compact_ordering`,
`_final_reconstruction`, `_integration_load`, `t_finite_field_gauge_pullback`,
`t_transport_chart_extension` (not exercised by the changes beyond the
package load), the CF259 transport itself (user rule: no rerun).

## Stage profile of the exact route on CF259 (written 14:25, before the single allowed run)

Measured: load 3.5 s; substitution of the point into `TTotal` 0.7 s (the
417 nonzero entries collapse from 107 MB in memory to 1.1 MB); on agent
L's fixture of 8 real `TTotal` entries up to 87 KB, `Together` at most
0.04 s and the full order (canonical radicals, `Together`,
`CoefficientList`, syntactic zero test) at most 0.054 s per entry, and
`RootReduce` of the leading coefficients 0.01 s -- so on `TTotal` the
per-point cost is about 417 x 0.05 s = 20 s and neither substitution nor
radical handling nor `Together` dominates there. Not measured before run
5: the 420 `TTotalInverse` entries, which are three times larger (299 MB
in memory) and were not in the fixture; run 4 (killed at 120 s with
`RootReduce` as the primary zero test) said that they, or `RootReduce`
on coefficients with more radicals than the fixture's, dominate.

Run 5 (instrumented, syntactic zero test primary), measured on the full
record at the point {34/303, 49/85}: load 3.4 s; substitution of the
point into `TTotal` 1.0 s (33.7 MB after substitution) and into
`TTotalInverse` 2.6 s (102 MB, largest entries 3.6 MB); orders of all
2209 `TTotal` entries 8.0 s, of which one entry (2163, 27 KB) took
2.3 s and everything else at most 0.05 s; orders of the 2209
`TTotalInverse` entries 28.8 s, of which the first 2000 took 3 s and
the last 200 -- the largest entries, up to 3.6 MB after substitution --
about 2.3 s each (`Together` plus the zero tests on those); one point
36.9 s in total, with TMin -3 and the 27 block bounds EQUAL to Codex's
`ExactAlgebraicPointValuation` values at the first point. The dominating
stage is therefore the order computation on the ~200 largest inverse
entries (the entry count times their size), not the substitution and
not the radical handling; `RootReduce` as the primary zero test (run 4)
multiplied that by more than three. Three points cost about 110 s.

File location note: during this work agent G moved
`ObservableTransportFiniteField.wl` to
`FeynFacet/Private/Transport/Observable/` (`git mv`, edits intact,
`LoadOrder.wl` updated); `ObservableTransport.wl` is still at
`FeynFacet/Private/Transport/`. Line numbers above refer to the files at
the time of writing.

## CF259 record status (honest statement)

`family_epsform_CF259_compact_valuations.wl` is CERTIFIED as of
14:28:40: `TransportEpsilonValuations` now carries a tight
`RationalPointEpsilonValuationCertificate` (three exact trials, TMin -3,
27 block bounds equal to Codex's claim, fingerprint bound to the
record's TTotal/TTotalInverse/Ranges); its typed status is
`TransportEpsilonValuationsCertified` and `BuildObservableTransport`
accepts it. The original is preserved unchanged next to it (SHA-256
above). Consequence stated plainly: the accepted CF259 transport result
of 2026-09-02 (`observable_transport_CF259.wl`, 564 s run) was built
from these same values before they were certified; the values are now
proven tight, so its valuation premise holds, but the stored result
object predates the certificate fields and `AcceptedObservableTransportQ`
on it now answers False (it requires `TransportEpsilonValuationsBound`
and the bound certificate). A rerun of the transport on the certified
record (about 10 min) would produce an accepted object; not done (user
rule: no CF259 rerun in this round).

## Next speed-ups for the certificate (not done)

1. One pass per point over all entries with the cheap exact route,
   `TTotalInverse` included, and the syntactic zero test only
   (`RootReduce` never on the hot path); measure the inverse entries
   first (run 5's log gives the worst entry).
2. Numeric-point `Series` per entry instead of `Together`: after the
   substitution each entry is univariate, so `Series[entry, {eps, 0, n}]`
   from a lower bound n and reading the first exactly-nonzero coefficient
   avoids building the full fraction; needs the same exact zero test.
3. The finite-field compiler evaluating the entries at eps = p (already
   compiled for the transport itself): valuations modulo primes with the
   symbol route, but with the hidden-zero problem solved by an exact
   zero test of the leading coefficient rather than precision doubling.
4. Certify at compact-record construction (`compact_family_dlog_record.wls`,
   owner G) where the entries are already in memory, so no reload.

## Left open / for other owners

- `Scripts/compact_family_dlog_record.wls` (owner G, Scripts/): after
  building `compact`, call
  `FeynFacet\`Private\`observableTransportCertifyEpsilonValuations[compact]`
  and write `result["Record"]` (refuse on any other status), so every
  new transport-ready record is certified at construction. Until then,
  `observableTransportCertifyEpsilonValuationsFile` certifies existing
  records in place.
- `FeynFacet/FeynFacet.m` (owner G, usage): the certifier and status are
  private (`FeynFacet\`Private\``); a public name
  (`CertifyTransportEpsilonValuations`) would need a usage line there.
- The certificate is probabilistic (three random points and primes) and
  says so (`Probabilistic -> True, Exact -> False`); an exact record
  without stored valuations still gets the exact gauge scan.
- A rational-field record with a numeric radical constant (no declared
  root) goes through the rational selector, which has no such gate;
  not seen in any record, noted only.


# Round 6 (coordinator's message of 16:45): Jet retirement and the CF259 rerun

## Task 1: the Laurent jet route retired (Codex's conciseness point; L's measurement)

- Moved verbatim to `FeynFacet/Private_Backup/ObservableTransportJet.wl`
  (115 lines with the provenance header): `observableTransportEpsJetTrim`,
  `...Add`, `...Mul`, `...Pow`, `...Compile`, `...Leading`,
  `...Coefficients`, `observableTransportLaurentEntryJet`,
  `$observableTransportLaurentCanonicalize`. Evidence in the header and
  in `Private_Backup/EVIDENCE.md` (new "Round 6" table): agent L's
  measurement (`round4/L_modular_laurent_route.md`, section 1, route C --
  the jet compile of the nested-quotient CF259 entry (42,20) does not
  terminate in 30 s; a calibration run was killed at 300 s inside it).
- Live file `FeynFacet/Private/Transport/Observable/ObservableTransport.wl`
  (its round-4 location): the nine symbols removed from the code and the
  `ClearAll` list; `$observableTransportLaurentJetRetired = <|"Status" ->
  "RouteRetired", "Route" -> "Laurent jet", "Replacement" -> "Series"|>`
  next to the method flag; `observableTransportLaurentRows` and
  `observableTransportLaurentMatrices` answer it when the method is
  `"Jet"`; `BuildObservableTransport` returns a status-carrying Laurent
  result as its own typed status instead of indexing it as a tensor (a
  guard after the `tLaurent` call); the route comment rewritten (Jet
  retired, where it lives, what answers). Production stays `"Series"`.
- `Tests/Transport/t_observable_transport_laurent_jet.wls` moved (plain
  `mv`, no git state touched) to `FeynFacet/Private_Backup/Tests/`.
- `Tests/Transport/t_observable_transport_laurent_series.wls`: one
  assertion added -- `"Jet"` refused typed at the row level and at the
  tensor level, and no `observableTransportEpsJet*` symbol defined
  (`System\`Names`: a package symbol shadows `Names` on the test's
  context path, which the first run of the assertion exposed).

Verification (seat launcher): load check `scratchpad/round4/T/load_check_jet.wls`
-- package loads, method `Series`, jet symbols absent, the Jet selection
answers the typed refusal, the Series route unchanged on a 1x1 -- 5 s
(16:53:30-16:53:35); `t_observable_transport_laurent_series` 20/20 in
15 s after load (16:54:3x-16:54:50; the first run 19/20 failed only on
the `Names` shadowing in the new assertion, fixed as above).

## Task 2: the CF259 rerun on the certified record (user's go, 16:45)

Driven as the 05:51 run was (`Scripts/family_observable_transport.wls`,
`FACET_CHECK_LEVEL=Production`, `FACET_KERNEL_COUNT=1`, the 05:51 path
card), through the seat launcher with a 900 s cap, on the certified
compact record, writing to the NEW directory
`.../CF259/observable_transport_2026-09-02_certified/` (the 05:51
directory untouched). Launched 16:54:50 after task 1 was verified,
exited 0 at 16:59:29. Log copied beside the artifact (`transport_run.log`),
README with provenance written there.

| stage (cumulative wall) | certified rerun | 05:51 run |
|---|---:|---:|
| input preparation | 0.2 s | 0.2 s |
| epsilon valuations (source FamilyRecord, certified) | 0.9 s | 0.2 s |
| structural support | 1.7 s | 0.4 s |
| Laurent extraction (Series, orders -3..2, row caps {-1: 38, 1: 7, 2: 2}, 0 fallbacks) | 150.8 s | 439.6 s (SeriesCoefficient) |
| forbidden map {102, 120}, 120 slots, 100 boundary slots | 165.6 s | -- |
| first covariant closure {93, 97, 97} | 203.4 s | -- |
| boundary evolution (AmbientBasePoint, 187,988 leaves, rank 77) + second closure (77 -> 94 -> 94), cancellation 0.3 s, base kernel {261, 167} | 234 s (demanded map {20, 261}) | -- |
| total, status `ModularlyVerifiedObservableTransport`, 20 demanded pairs, 167 boundary coordinates, weight 5, OperatorAutomaton | 270.4 s | 564.2 s |

Acceptance and comparison (separate kernel, 120 s cap,
`scratchpad/round4/T/cf259_rerun/compare.wls`, 3.6 s): `AcceptedObservableTransportQ`
on the new artifact True; on the 05:51 artifact False under the current
predicate (no certificate fields). Certificate carried: source
`FamilyRecord`, status `RationalPointEpsilonValuationCertificate`,
`Tight -> True`, `FingerprintVerified -> True`,
`Certificates["TransportEpsilonValuationsBound"] -> True`. SameQ with the
05:51 artifact, the way L's benchmark compared: all 25 deterministic keys
(demanded rows, constraint matrix, boundary slots/kernel/embedding, rank
histories, kernels, valuations, ...) and all 10 operator-automaton
sub-keys SameQ -- differing keys `{}`; demanded map SameQ True,
constraint matrix SameQ True, automaton SameQ True; same set of
probabilistic-certificate keys.

Artifact: `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF259/observable_transport_2026-09-02_certified/observable_transport_CF259.wl`,
9,263,077 bytes, SHA-256
`fe0c6f5926e9dcaa6c9bf5e4346207abb281e16f7f4edda496fc18af97cd6060`.
