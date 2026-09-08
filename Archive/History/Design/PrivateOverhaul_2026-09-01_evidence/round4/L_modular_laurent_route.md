# Round 4, agent L: the Laurent extraction of the observable transport

Task (from Codex's review of 2026-09-02, "Efficiency"): the dominant stage of
the CF259 observable transport is the Laurent extraction of the 47 x 47
transformation `TTotal`, 439 s of the accepted 564 s run (78%), because the
coefficients are canonicalized one by one through `Cancel[Together]`; the
rejected epsilon-jet route did not finish in 21 minutes.  Codex's proposed
next algorithm: keep the jets as shared uncanonical DAGs, evaluate them
modulo primes at the transport's sample points, reconstruct only the
demanded/constraint maps that survive the closure, never canonicalize the
complete Laurent tensor.

Worktree `/home/maxzhang/factorization-and-loops-L`, branch `round4-laurent`.
Scratch (calibration scripts, logs, fixtures, benchmark output):
`/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad/round4/L/`.
Every kernel run went through the seat launcher; every log carries the
script's own tally line.  The worktree lacks the untracked add-on and
`Results` fixture directories; they were supplied as gitignored symlinks
into the primary tree (read-only use; `git status` shows only the four
intended paths).  Nothing was written into the primary tree: the CF259
record benchmarked (`family_epsform_CF259_compact_valuations.wl`, 47,649,635
bytes, mtime 03:43:31) has the size and modification time it had at the
accepted run (03:43, before probe 5), i.e. it is unchanged; the
copy `...compact_valuations.wl.before_certificate_2026-09-02.wl` that
appeared beside it at 13:54:39 is another agent's backup, not this
round's.

## 1. Calibration first: what the 439 s actually are

Before designing, the candidate routes were timed on REAL `TTotal` entries
of the CF259 compact record (extracted verbatim from
`.../CF259/transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl`,
orders -3..2 as in the accepted run; scripts `calibrate_laurent.wls`,
`calibrate_laurent2.wls`, logs beside them).  Facts the design rests on:

- Shape of the raw tensor: 417 nonzero entries, 11.8 MB of text; the entries
  are sums of quotients of products of expanded polynomials in
  (eps, x, y, Sqrt[q_i]) with the three declared radicals; median entry
  12 KB, largest 496 KB (rows 46 and 47 hold 7.2 MB).  **The nine demanded
  components (rows 14,15,16,17,19,42,43,46,47) hold 72% of the text**; the
  38 components read only by the forbidden map hold 28%.
- Route A (production, `SeriesCoefficient` per entry and order +
  `Cancel[Together]`) versus route B (ONE `Series` per entry, coefficients
  read off the `SeriesData`, the same `Cancel[Together]` per coefficient):

  | entry (row,col) | bytes | LeafCount | A | B | B coefficients SameQ with A |
  |---|---:|---:|---:|---:|---|
  | (16,5) | 1,237 | 430 | 0.03 s | 0.00 s | yes |
  | (42,21) | 1,888 | 901 | 0.05 s | 0.00 s | yes |
  | (34,34) | 6,060 | 2,317 | 0.32 s (series 0.04 + Cancel 0.28) | 0.03 s | yes |
  | (42,20) nested quotients | 11,861 | 4,294 | 0.29 s | 0.01 s | yes |
  | (28,23) | 25,013 | 9,453 | 0.80 s | 0.59 s | yes |
  | (46,32) | 49,921 | 13,780 | 0.60 s | 0.40 s | yes |
  | (17,1) | 86,845 | 31,629 | 2.24 s | 1.61 s | yes |
  | (46,20) | 157,183 | 43,284 | not run | 1.20 s | -- |
  | (47,11) | 220,147 | 39,897 | not run | 1.66 s | -- |
  | (47,6) | 300,102 | 47,426 | not run | 1.67 s | -- |
  | (47,1) largest | 495,810 | 65,047 | not run | 3.38 s | -- |

  The canonical coefficients of B are IDENTICAL (`SameQ`) to A's on every
  entry where both ran.  A's cost on small entries is dominated by the
  `Cancel[Together]` of `SeriesCoefficient`'s bulkier output (0.28 of 0.32 s
  on (34,34)); on the large entries the gain shrinks to about 1.4x because
  the algebraic series arithmetic itself dominates.
- Route C (Codex's premise: the existing uncanonical jet compiler,
  `observableTransportEpsJetCompile`, then modular evaluation): the jet
  COMPILE of the nested-quotient entry (42,20) (12 KB) did not terminate in
  30 s (`TimeConstrained`), and the first calibration run was killed at the
  300 s cap inside it.  Cause: the common-denominator cross-multiplication
  of nested sums of quotients grows multiplicatively with the nesting depth
  (the plan's 21-minute rejection was the same effect).  On entries where
  it does compile, the uncanonical order-k coefficient tree grows about
  2^k-fold (LeafCounts 170, 732, 2211, 4435, 7393, 11830 for the six
  orders of (34,34)), and the finite-field interpreter evaluates trees, not
  DAGs.

## 2. Design decision

Codex's diagnosis was right (per-coefficient canonicalization), its proposed
remedy is not the lever on this data:

1. The demanded map (20 x 261, functions of x, y over the three-root field)
   is the physics output and is stored canonically in the accepted object;
   "never canonicalize the tensor" cannot apply to it, and its rows carry
   72% of the raw text.  Reconstructing it from modular samples instead
   (bivariate algebraic rational reconstruction, 8 sheet components, entries
   up to 51 KB canonical with degrees around 20-40 and 30-digit rational
   coefficients) needs of the order of 10^3 sample points x 8 sheets x
   several primes -- far outside a 900 s budget in Wolfram.
2. A modular-only first closure would replace the forbidden-map extraction
   (28% of the text) plus the closure's symbolic covariant rows, at the
   price of a truncated-series evaluator over the raw expression DAGs (the
   existing jet compiler is unusable on nested quotients, see C above) and
   of a new univariate materialization of the constraint basis at the base
   point.  Estimated at 60-150 s per CF259 run against the 40-60 s it would
   remove once route B is in place, for roughly 800 lines of new code.
   Not built; the estimate and its inputs are recorded above so the
   decision can be revisited if the closure ever dominates.
3. Route B removes the measured waste exactly: one `Series` per entry
   (identical canonical output), and -- Codex's principle applied where it
   pays -- each row expanded only to the order the transport reads it at:
   a demanded component to its highest demanded order - flow, every other
   component to valuation - 1 - flow (for CF259: rows 14,15 to order 2,
   the other seven demanded rows to order 1, the 38 remaining rows to
   order -1 instead of 2 for all).  Orders above a row's cap are stored as
   0 and never read; both consumers assert that (typed failure
   `LaurentOrderNotExtracted`).

Exactness: the route computes the same canonical expressions as before
(verified `SameQ` on real entries and on three end-to-end fixtures, section
4); nothing probabilistic was added to the Laurent stage, so no modular
certificate was needed for it.  One correctness improvement was added: a
pole below the record's `TMin` (the valuation record the transport trusts)
is now refused with the typed status `LaurentValuationBelowRecord` where the
former route silently dropped the order.

## 3. Changes (all in the worktree; line numbers of the final state)

`FeynFacet/Private/Transport/ObservableTransport.wl` (`git diff --stat`:
212 insertions, 49 deletions)

- 35-37: new private symbols in the `ClearAll` list
  (`$observableTransportLaurentDiagnostics`,
  `observableTransportLaurentEntrySeries`,
  `observableTransportLaurentRowHighs`).
- 500-532: the route comment rewritten (three routes, the measured facts,
  the jet's rejection with its cause); default
  `$observableTransportLaurentMethod = "Series"` (was
  `"SeriesCoefficient"`; `"SeriesCoefficient"` and `"Jet"` stay
  selectable).
- 630-665: `observableTransportLaurentEntrySeries` (one `Series` per entry;
  eps-free and zero entries handled; a non-`SeriesData` result, a Puiseux
  denominator or an insufficient truncation returns `$Failed` so the caller
  falls back to `SeriesCoefficient` for that entry; a pole below `low` is
  counted in `$observableTransportLaurentDiagnostics`, line 638).
- 667-675: `observableTransportLaurentRowHighs` (per-component order caps).
- 677-713: `observableTransportLaurentRows` takes optional row caps and
  dispatches Jet / Series / SeriesCoefficient; the caps apply to the two
  series routes; placeholders above a cap are 0.
- 715-731 and 733-787: the task-broker task returns
  `<|"Coefficients", "Diagnostics"|>` and the collector merges helper
  diagnostics (retrying a chunk locally on a malformed result, as before);
  `observableTransportLaurentMatrices` takes the caps and validates them.
- 1908-1935: `BuildObservableTransport` computes the caps, passes them,
  refuses `LaurentValuationBelowRecord` (1925-1930), and prints the method,
  caps and fallback count under `Verbose`.
- 1936-1955 and 2196-2217: the forbidden-map and demanded-map loops assert
  that no order above a row's cap is read (`LaurentOrderNotExtracted`).
- 1960-1964, 2007-2009, 2072-2076, 2219-2223: cumulative wall time added
  to the `Verbose` milestone prints of the forbidden map, first closure,
  boundary evolution and demanded map (the benchmark table below).
- 956-961, 2122-2128, 2166-2168, 2180-2185: a record without forbidden
  constraints on the `AmbientBasePoint` branch (found by the new 2 x 2
  algebraic fixture): `SparseArray[{}, {0, n}]` evaluates to the plain list
  `{}`, so the former code dotted `{}` with the boundary selector
  (`Dot::dotsh`) and the closure refused the empty row set
  (`CovariantClosureInputsInvalid`).  The closure now takes the state
  dimension from the connection for an empty row set, and the ambient
  branch carries the empty constraint explicitly.  Pre-existing defect,
  independent of the Laurent route; fixed because the fixture needed it.

`Tests/Transport/t_observable_transport_laurent_series.wls` (new, 19
assertions, 15 s) and `Tests/Transport/Fixtures/cf259_ttotal_entries.wl`
(new, 47 KB: five real CF259 entries with provenance in the header).

Not changed: `ObservableTransportFiniteField.wl`, the pool/campaign scripts,
the jet code (kept for its unit test; its rejection and cause are now in the
route comment -- retiring it to `Private_Backup` is the main session's call).

## 4. Small-fixture verdicts (fresh kernels, seat launcher, 300 s cap each)

Acceptance criterion of the new test: every canonical coefficient of the
Series route is `SameQ` with the SeriesCoefficient route's, and every
deterministic part of a transported object (demanded rows, constraint
matrix, base kernel and embedding, operator automaton or word maps, kernels
modulo the per-call path symbol, rank histories) is `SameQ` between the two
routes.

| test | result |
|---|---|
| t_observable_transport_laurent_series (new) | 19/19: synthetic 3x3 radical matrix (incl. a Puiseux entry that takes the fallback) SameQ over orders -3..3; five real CF259 entries SameQ over -3..2 (Series 0.9-1.0 s vs SeriesCoefficient 0.9-3.0 s across three runs); row caps; a pole below TMin refused; end to end SameQ on CF27 (certified rational, both routes accepted), the 1 x 1 algebraic toy, a new 2 x 2 algebraic toy with radical TTotal entries and poles (`ExactObservableTransport`, 4 physical rows), and the certified CF230 chart record (both routes accepted, 6 s) |
| t_observable_transport_laurent_jet | 7/7 |
| t_observable_transport | all checks True |
| t_algebraic_observable_transport | 13/13 |
| t_observable_transport_covariant_closure | all checks True |
| t_observable_transport_compact_ordering | all checks True |
| t_observable_transport_final_reconstruction | 3/3 |
| t_observable_transport_integration_load | all checks True |
| t_observable_transport_ff_radical_scale | 10/10 |
| t_observable_transport_finite_field | 18/18 |

The only certified multiquadratic family record is CF300 (16 MB, triple
root), so the multiquadratic end-to-end fixtures are the two algebraic toys;
CF259 itself is the multiquadratic benchmark below.

## 5. CF259 benchmark

One run, as allowed: `bench_cf259_series.wls` (scratch), 2026-09-02
14:13:55-14:18:28, seat A of the seat launcher (CPUs 2-5,10-13: E-cores,
the same core class as the accepted run's "one E-core"), cap 900 s, watchdog
armed in the same turn (round 1 verdict OK; the run drained with exit 0
inside the cap).  Inputs: exactly the accepted
run's (the compact record with Codex's valuations, `nnlo_de_CF259.wl`,
`MasterCoefficientValuations.wl`, the accepted run's card: path base
(14/45, 11/90), target sample 13/45, Verbose), read from the primary tree by
absolute path; package loaded from the worktree; output written to scratch
only (`cf259_bench/observable_transport_CF259_round4.wl`, 9.26 MB; log
`cf259_bench.log`).

Result: status `ModularlyVerifiedObservableTransport`, accepted by
`AcceptedObservableTransportQ`; 20 demanded (order,row) pairs, 167 boundary
coordinates, maximum weight 5, operator-automaton representation --
**265.1 s against the accepted 564.2 s (2.13x)**.

| stage (cumulative Verbose milestones) | accepted run, probe 5 | this run |
|---|---:|---:|
| input preparation, valuations (from record), structural support | 0.4 s | 0.4 s |
| Laurent extraction of the 47 x 47 transformation, orders -3..2 | 439.2 s (SeriesCoefficient; every row to order 2) | 150.5 s (Series; 38 rows capped at order -1, 7 at 1, 2 at 2; 0 fallbacks; no pole below TMin) |
| forbidden map {102, 120} (zero tests, path substitution) | not timed separately | 13.5 s |
| first covariant closure (93 -> 97 -> 97) and constraint cancellation at the base | not timed separately (the plan's table: ~60 s for this and the row above) | 37.2 s |
| boundary evolution choice (AmbientBasePoint, 187,988 constraint leaves, constraint rank 77) | not timed separately | 2.3 s |
| second closure (77 -> 94 -> 94), base constraint {94, 261} (0.2 s), base kernel {261, 167} (0.1 s), demanded map {20, 261} | not timed separately (the plan's table: ~60 s) | 27.0 s |
| ambient invariance certificate, segment kernels, lifted residues, automaton assembly | not timed separately (the plan's table: ~3-4 s) | 34.2 s |
| total (`Seconds`) | 564.2 s | 265.1 s |

The Laurent stage is 2.9x faster and is no longer the majority of the run
(57% instead of 78%); the remaining 115 s are the closures and certificates,
which this round did not touch.

Reproduction of the accepted object, compared key by key with `SameQ`
against `observable_transport_CF259.wl` (the 564 s artifact): `Status`,
`PhysicalRows`, `PhysicalDemandPairs`, `PhysicalValuation`, `BoundarySlots`,
`BoundaryConstraintMatrix` (97 x 100, symbolic in y with the three
radicals), `BoundaryAmbientSlots`, `BoundaryKernelAtBase` and
`BoundaryBaseEmbedding` (261 x 167 rational), `BoundaryEvolutionMethod`,
`BoundaryConstraintLeafCount` (187,988), `ConstraintRank` (77), both
rank histories, `FirstSegmentKernels` (modulo the per-call path symbol),
`FirstSegmentKernelMatrices`, `SecondSegmentKernels`,
`SecondSegmentKernelMatrices`, both active-letter lists,
`WordRepresentation`, `MaximumWeight`, `TransportEpsilonValuations`,
`BoundaryCoordinates`, `CoefficientField`, and every field of
`ExactOperatorAutomaton` including `InitialDemandMap` (20 x 261, symbolic
in x, y) -- all 35 `SameQ`.  The demanded maps and the constraint matrix
are therefore not merely equal functions but the identical canonical
expressions.  The probabilistic certificates carry the same key set
(`DualClosureInitialSpan`, `DualClosureStabilization`,
`SecondBoundaryClosureInitialSpan`, `SecondBoundaryClosureStabilization`,
`AmbientBoundaryInvariance`, `FamilyDLogResidues`) with fresh random
primes/points, as designed: the ten certificate primes of this run
(1212092587, 1309100831, 1515168491, 1782924763, 1820229067, ...) share
none with the accepted run's ten, so the modular acceptance was re-earned
on unseen primes while the deterministic object stayed identical -- the
strongest form of the comparison this artifact admits.  Nothing probabilistic was added by this round: the
Laurent stage stays exact, so no reconstruction certificate exists or is
needed for it.

Honest framing of the number: this is not Codex's modular-reconstruction
route; it is the cheap exact route the calibration pointed to.  It keeps
production on canonical `Series` output, so the closures downstream are
unchanged, and the new default is selected by
`$observableTransportLaurentMethod = "Series"` with the former route one
assignment away.

## 6. What is left

- Codex's modular route proper (uncanonical DAGs evaluated mod p, closure
  without symbolic rows, reconstruction of the surviving maps) is not
  built; the calibration above bounds its value on CF259 and names its two
  prerequisites (a truncated-series evaluator over the raw DAGs that does
  not cross-multiply nested quotients; univariate materialization of the
  constraint basis at the base point).  Revisit only if the closure stages
  (now 115 of 265 s on CF259) become the target.
- The `"Jet"` route is demonstrably pathological on nested-quotient entries
  (compile does not terminate); retire it to `Private_Backup` with its test
  (Codex's conciseness point), main session's call.
- The row-parallel task-broker path of the Laurent stage was not
  re-measured (no broker in a standalone run); it now carries the caps and
  merges helper diagnostics, untested on a live pool.
- Valuation certification (Codex's correctness point): the transport now
  refuses a record whose `TMin` lies above an entry's true valuation, but
  `BlockLower` is still trusted as given.
