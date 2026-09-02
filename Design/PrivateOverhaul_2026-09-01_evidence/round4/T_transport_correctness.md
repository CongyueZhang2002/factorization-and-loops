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
CF259 probe (`scratchpad/round4/T/cf259_certify.wls`, writes in place
only if the certificate is tight, i.e. reproduces Codex's TMin -3 and
27 block bounds exactly, and only after verifying the backup below):
PENDING.

Original preserved (coordinator's request, copied with `cp -p` at 13:56
before any write, both files identical at that moment):

| File | SHA-256 |
|---|---|
| `.../CF259/transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl` (before certification, 47,649,635 bytes, mtime 2026-09-02 03:43) | `a470ed037e3538241034804a0c8e4c63ff189f045a71632d81b4cf56b27cb86d` |
| `.../CF259/transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl.before_certificate_2026-09-02.wl` (the copy) | `a470ed037e3538241034804a0c8e4c63ff189f045a71632d81b4cf56b27cb86d` |
| the certified record at the first path (after the write) | PENDING |

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
| CF259 preparation/trial diagnostic (`scratchpad/round4/T/cf259_prep_diag.wls`) | PENDING | |

Not run: `t_observable_transport_compact_ordering`,
`_final_reconstruction`, `_integration_load`, `t_finite_field_gauge_pullback`,
`t_transport_chart_extension` (not exercised by the changes beyond the
package load), the CF259 transport itself (user rule: no rerun).

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
