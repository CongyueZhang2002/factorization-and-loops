# Codex assessment of Fable's overnight Private overhaul

**Timestamp:** 2026-09-02 10:41 PDT
**Committed state reviewed:** `main` at `4adfa4cc` (22 commits ahead of `origin/main`)
**Audience:** Fable

## Bottom line

The overhaul is meaningful, but it should not be signed off yet. The seven-folder
layout and load manifest are useful, ordinary-record compatibility is repaired,
and CF259 genuinely completed observable transport. However, two committed
observable-transport correctness gaps remain, reused-pool cleanup is defective,
and the dominant CF259 performance stage remains unsolved. Fable also began a
large uncommitted follow-up while this review was running; it is separated below.

## Correctness

- 🔴 **Transport epsilon valuations are trusted rather than certified.**
  `FeynFacet/Private/Transport/ObservableTransport.wl:1664-1672` accepts
  `TransportEpsilonValuations` after integer/length checks only. `TMin` and
  `BlockLower` then determine the Laurent range and physical convolution at
  lines 1793-1796 and 2044-2054. `AcceptedObservableTransportQ` (line 2566)
  never validates or binds that metadata. A stale/high `TMin` can omit a real
  leading coefficient, make a requested row look zero, and still yield an
  accepted object.

  This does not show CF259 is wrong: its `TMin -> -3` and 27 block bounds came
  from `ExactAlgebraicPointValuation` and are plausible. It shows the public
  acceptance claim does not protect that premise.

  **Fix:** certify valuations once during compact-record construction. Evaluate
  the relevant `TTotal`/`TTotalInverse` entries as rational functions of epsilon
  at two or three independent kinematic points modulo fresh primes, extract the
  minimum orders, and store a certificate bound to the record inputs. Require
  that certificate in production; do not repeat a symbolic valuation scan.

- 🔴 **Radical constants are omitted from final acceptance-prime selection.**
  `ObservableTransportFiniteField.wl:449` records `RadicalConstants`, and the
  rank/pivot samplers gate them correctly. The fresh-prime selectors at lines
  954-976 and 1090-1115 test only declared constant root squares. For an entry
  containing `Sqrt[5]`, a selected prime with `(5|p)=-1` makes every validation
  point fail. This is fail-closed, not false acceptance, but it makes production
  seed-dependent. The new test explicitly chooses `(5|p)=1` and cannot expose it.

  **Fix:** add `Lookup[compiled, "RadicalConstants", {}]` to both prime
  admissibility predicates. Test a seed whose first candidate has `(5|p)=-1`;
  it must skip that prime and succeed at a later one. This is selection logic,
  not an additional certificate.

- 🔴 **The modular test does not restore its context.**
  `Tests/FiniteField/t_modular_arithmetic.wls:74` saves contexts in a symbol
  resolved before changing `$Context`; line 469 resolves the same spelling in
  the new context, where it is unset. My fresh run printed:

  ```text
  Set::shape: Lists {$Context, $ContextPath} and ftModularSavedContexts
  are not the same shape.
  ```

  The test still reported 61/61 and exited zero. In a reused pool it can poison
  the next mission, precisely the B11 failure this attempted to repair. Fully
  qualify the saved symbol (or use a genuine inherited context block), and make
  failed restoration fail the test.

- 🟡 **Known-bad automatic samples can be retained.** At
  `ObservableTransport.wl:1713-1736`, if the finite grid cannot supply the full
  requested count, the original samples remain even after some were proved
  inadmissible. Return a typed exhaustion result immediately.

- 🟡 **Coefficient-field fallback is incomplete.**
  `observableTransportCoefficientField` at `ObservableTransport.wl:99-116`
  scans only `Letters` and `TTotal`, not `TTotalInverse`, epsilon-form matrices,
  dlog data, or chart roots. `FindObservableTransportPath` also converts a
  missing field to `"Rational"`. Require an explicit field for transport-ready
  records and make legacy inference inspect all computational fields.

## Efficiency

- 🟡 **Major speed opportunities are not exhausted.** Accepted CF259 timing:

  | stage | wall time |
  |---|---:|
  | Laurent extraction | 439 s (78%) |
  | first closure | about 60 s |
  | boundary plus second closure | about 60 s |
  | remaining work | about 3-4 s |

  Total: 564 s on one E-core. The epsilon-jet parser is fast in isolation, but
  its output is still canonicalized coefficient-by-coefficient through
  `Cancel[Together]`. That route did not finish after 21 minutes, so line 512
  correctly leaves production on `"SeriesCoefficient"`. The overhaul enabled
  CF259 but did not optimize the dominant stage.

  **Next algorithm:** retain jets as shared uncanonical DAGs, evaluate them
  modulo primes, and reconstruct only demanded/constraint maps surviving the
  observable closure. Do not materialize and canonicalize the complete
  characteristic-zero Laurent tensor. The existing finite-field observable
  compiler is the natural backend. Parallelizing the current symbolic form
  gives at most a constant-factor improvement.

- 🟢 Radical rescaling and automatic admissible samples are useful, general
  fixes. They converted CF259 from repeated rank refusal into a completed run.

- 🟡 Since the 564 s run used one E-core, rebenchmark the existing row-parallel
  pool after correctness fixes. It is not yet a performance ceiling.

## Generality

- 🟢 Renamed-variable generality passed 53/53. No live algorithm branches on
  `CF259`, `CF300`, or `CF303`; those names occur only in comments and benchmark
  narratives. The two-variable limitation is accepted project scope.

- 🟡 The seven layers are not actually acyclic. Geometry loads after EpsForm
  because `TransportCharts.wl` inherits `Options[SolveEpsFormStrip]` at load
  time, while the design note admits EpsForm calls helpers from Transport.
  Move shared helpers downward and replace load-time option inheritance with a
  shared option list or call-time filtering.

- 🟡 `GaugePullBackMode -> "MapleCanonical"` is accepted at
  `Geometry/TransportCharts.wl:1844`, but its implementation at line 3225
  returns `RouteRetired`. Remove it from the live allowed set and usage text;
  do not resurrect the symbolic route.

## Conciseness and ghost code

- 🟢 Seven directories plus `Private/LoadOrder.wl` are a real improvement.

- 🟡 `EpsForm/MultiquadraticStripSolve.wl` remains about 17,000 lines / 948 KB.
  After correctness and performance stabilize, split it by responsibility:
  provider/compiler, sampling and affine solve, interpolation/lift, persistence,
  and terminal acceptance.

- 🟡 The rejected Laurent jet occupies roughly 100 live production lines but
  is disabled. Move it to Diagnostics until its modular consumer exists. Its
  comment also says Jet is the default while the next line selects
  `SeriesCoefficient`.

- 🟡 `Core/ModularArithmetic.wl` is only a partial consolidation.
  `modularLift`, `modularResidueQ`, `modularSplitPoints`, and `modularPrimes`
  have no production callers in committed `4adfa4cc`, while production routes
  retain equivalents. Either complete migration in a tested pass or move
  reference-only functions out of the live package.

- 🟡 Two observable-transport campaign scripts expose overlapping process and
  kernel-pool schedulers. Designate the kernel-pool driver as canonical and
  label the other explicitly standalone.

- 🟡 `HANDOFF.md` contradicts itself: lines 35-44 say CF259 is transported,
  while lines 147-149 say CF259 and CF300 are unfinished. It also calls the
  rejected jet route active. Keep one current status block above history.

## Evidence

Fresh-kernel checks against committed `4adfa4cc`:

- `t_modular_arithmetic.wls`: 61/61, with the context-restoration error above;
- `t_observable_transport_laurent_jet.wls`: 7/7;
- `t_observable_transport_ff_radical_scale.wls`: 10/10;
- `t_generality_renamed_variables.wls`: 53/53.

`t_algebraic_observable_transport.wls` did not finish inside my 180-second
smoke-test window. I terminated only that test after its kernel ignored the
initial timeout signal. Fable's stored evidence reports it green, so this run
is inconclusive rather than a regression finding.

The stored comparison also has nine failures shared with baseline and three
long multiquadratic tests with no verdict on either tree. The defensible claim
is **no detected regression on exercised paths**, not unqualified “no
regression.”

CF259's 9.26 MB output is at
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsSolving/triple_root_2026-08-28_codex_clean/CF259/observable_transport_2026-09-02/observable_transport_CF259.wl`.
It reports `ModularlyVerifiedObservableTransport`, 20 demanded pairs, 167
boundary coordinates, maximum weight 5, and operator-automaton representation.
Treat it as credible but provisional until valuation metadata is bound.

## Live uncommitted follow-up observed during review

The tree was clean at review start. At 10:38-10:41 Fable began editing dozens
of files. These WIP edits were not included in the committed-state tests. One
immediate defect existed in the 10:41 snapshot:

- `ModularArithmetic.wl` added a `"Below"` argument in its body, and
  `FiniteFieldStripSolve.wl` started calling it, but
  `Options[modularPrimes]` at lines 453-456 did not declare `"Below"`.
  Because unknown option keys are refused, the reserve-prime call returns
  `$Failed`. Add `"Below" -> Automatic`, validate it, and test the exact call.

Fable fixed a separate stale `SourceSHA256` lookup to `ABIVersion` while Codex
was observing the edit. Before committing the ABI conversion, test one real
pre-overhaul checkpoint. The prose says old `SourceSHA256` records remain
admissible, but new validators mostly require `ABIVersion`, and changed tests
construct only new-format records.

## Recommended order

1. Stabilize live WIP and fix the undeclared `"Below"` option.
2. Bind epsilon valuations to a cheap modular certificate.
3. Include radical constants in both fresh-prime selectors.
4. Fix context restoration and add the adversarial cases above.
5. Run focused transport/persistence tests in fresh kernels, then one reused
   pool ordering test.
6. Implement and benchmark the uncanonical jet-to-modular-map route on CF259.
7. Push `main`; committed `4adfa4cc` was still 22 commits ahead of
   `origin/main` at review time.
