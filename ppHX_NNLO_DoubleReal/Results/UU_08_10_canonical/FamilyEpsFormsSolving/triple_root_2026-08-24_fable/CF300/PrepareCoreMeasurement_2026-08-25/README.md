# CF300 (12,9) prepare/compile measurement — serial-phase wave, 2026-08-25

Evidence for the serial-phase agent's headline measurement on the real
CF300 off-diagonal block (12,9) (strip leaf count 1,133,532; root rank 2;
52 letters after norm filtering).

## Measured result (`cf300_prepare_result.wl`, schema CF300PrepareCoreMeasurementV1)

Two end-to-end runs of preparation + compilation on identical inputs,
differing only in the `"CompileCore"` option:

| run                  | prepare (s) | compile (s) | total (s) | peak RSS (MB) |
|----------------------|-------------|-------------|-----------|----------------|
| HEAD (CompileCore off) | 2710.9      | 91.3        | 2802.2    | 1795           |
| NEW  (CompileCore on)  | 2810.7      | 89.8        | 2900.5    | 2020           |

Both runs reach `CompiledMultiquadraticStripV1`; `PreparationEquivalent ->
True` and the assembly fingerprints agree exactly
(`c5fa06a1995118f21819498922a8ae747b3d6cefa7cbf32fe72e7713528f529d`).

Interpretation recorded at the time: the compile's core stage costs only
0.16 s, so letting prepare consume the compiled core cannot pay — the
option ships DEFAULT OFF. Preparation's own 2710.9 s is the remaining
cost target for this block; `cf300_attribute.wls` is the attribution
driver written to decompose that 2710.9 s into its stages (NOT yet run —
scheduled for the hardening wave).

## Files

- `cf300_prepare.wls` — the measurement driver (both runs + equivalence
  and fingerprint comparison).
- `cf300_prepare_result.wl` — the measured record quoted above.
- `cf300_prepare.log` — run log.
- `cf300_attribute.wls` — prepare-cost attribution driver, unrun.
- `suite/`, `suite2/` — the serial-phase agent's full test-suite logs
  (all suites green) taken with the wave applied, before commit.

---

## Prepare-cost attribution, run 2026-08-25 (hardening wave)

`cf300_attribute.wls` was the unrun driver above. It is now run, in two
modes, both recorded here.

### Cheap predictive gate (house rule for a >10-minute stage)

`cf300_attribute.wls cheap`, 2.5 s, on the small synthetic rank-2 block
the acceptance suite builds from a known gauge (BBar 2904 leaves).
Result: `cf300_attribute_cheap_result.wl`. Every stage executed and every
consistency invariant held — interned decomposition `SameQ` the
uninterned one, the sealed core's BBar channels `SameQ` the independent
decomposition, 29 letters built, denominator degrees `{1,1}`, equation
text 6512 chars. **Stated as measured:** at that fixture scale five of the
six stage timings are below the 0.1 s reporting resolution, so the gate
establishes *wiring and consistency*, not nonzero buckets.

### The real block, CF300 (12,9)

`cf300_attribute.wls cf300`, **52 min 53 s wall**, one main kernel, no
subkernels. Peak RSS **1039 MB** (observed); the record's own
`PeakMemoryBytes` is 783,029,608. Watchdog armed in the same turn,
zero anomalies. Result: `cf300_attribute_cf300_result.wl`; log:
`cf300_attribute_cf300.log`.

| stage | seconds | note |
|---|---|---|
| forcing channel decomposition (interned) | **1400.5** | 8 entries, **8 structurally distinct**, root-free fast path **0**, algebraic path **8** |
| rational gauge denominator from the channels | 0.1 | degrees `{4,5}` |
| ABI canonical data (equation + root texts) | 21.4 | equation text 3,691,398 chars |
| algebraic-letter norm denominator factor | 0.0 | |
| *(candidate letters)* | *(184.5)* | **not part of the 2710.9 s**: `cf300_prepare.wls` supplied `LetterRecords`, so prepare never built the alphabet |
| *(sealed compile core, E+C+BBar decomposed AND compiled)* | *(1560.7)* | *a different route*, not a stage of the reference run; its BBar channels are `SameQ` the independent decomposition |

**Attributed against the 2710.9 s reference prepare: 1422.0 s = 52.5%.**
**Unattributed: 1288.9 s = 47.5%.** That 47.5% is *not attributed to any
stage by measurement* — it is the residual between the reference run and
the buckets this driver instruments. The stages that hold it are named in
"Phase 2" below. The 1606.5 s the script prints includes the
candidate-letter stage, which the reference run did not pay; 1422.0 s is
the figure to quote.

### The finding, and why it is a proposal and not a patch

The dominant stage is the forcing channel decomposition at 1400.5 s, and
its population says exactly what is and is not available:

- **8 entries, 8 structurally distinct.** Interning has nothing to
  deduplicate on this block. The intern layer is still correct and still
  pays on sparse blocks; it cannot pay here.
- **0 root-free fast-path hits, 8 algebraic.** Every entry takes the full
  field reduction plus inversion.
- So the cost is **~175 s per entry on a ~140,000-leaf expression**, in
  8 calls. It is not a loop to parallelise and not a duplication to
  remove.

Per the wave's own rule — implement a clear algorithmic win, otherwise
record a proposal — this is **recorded as a proposal, not implemented**:

> **Proposal (not built).** Give `multiquadraticFieldDecompose` the
> evaluate-and-reconstruct treatment that `applyRowGauge` got on
> 2026-08-23: decompose at sampled points over a finite field, interpolate
> and lift the channels, and accept only on the existing exact recompose
> check, falling back to the symbolic path on any failure. The acceptance
> gate already exists (`multiquadraticFieldCompose` + the exact
> difference test), which is what makes the substitution safe. This is a
> new modular route for the channel decomposition, well beyond the ~2 h
> bar, and it needs its own adversarial tests.
>
> **Required phase-2 scope before this proposal is acted on.** The
> proposal above targets 52.5% of the reference prepare. The other 47.5%
> is unattributed, and the phase-2 section below names the six stages
> that hold it. If phase 2 finds the residual in the ABI payload's
> `Expand` (candidate 3) or its context-freedom traversal (candidate 4),
> that half is a cheap fix and should be taken *first* — it would be
> wrong to spend a modular-decomposition redesign on 52.5% while a
> comparable share sits behind a `Together`/`Expand` that can be dropped.

The recursive quadratic-tower inversion landed in this wave already
removes the 2^r x 2^r symbolic solve *inside* each of those 8 calls; what
remains is the field reduction on the expression itself.

### Phase 2: the 47.5% the first pass does not instrument

**Status: scoped and implemented as a driver mode; not yet run.** Until it
is run, nothing here is a measurement — the paragraphs below name
*candidate holders* of the 1288.9 s and say why each is a candidate. No
percentage is claimed for any of them.

The first pass timed the four buckets in the table above. Prepare does
more than those four, and the following stages are exactly what it does
between and around them — every one of them is uninstrumented by
`cf300_attribute.wls cf300`:

1. **`multiquadraticStripRootCensus` + `multiquadraticStripRootOrder`.**
   Classify every radical appearing in a 1,133,532-leaf strip, then
   denest and square-class-match each declared root. Runs before any
   bucket the first pass measures.
2. **`multiquadraticStripMergeGaugeDenominator`.** The first pass measured
   only `multiquadraticRationalGaugeDenominator` (0.1 s). The *merge*
   with the algebraic-letter norm factor — which raises the denominator
   to degrees `{4,5}` — was not measured at all.
3. **`multiquadraticStripABIPayload` as a whole.** The first pass timed
   only its `multiquadraticStripCoreCanonicalData` part (21.4 s: the
   equation and root texts). The payload additionally canonicalizes the
   gauge denominator, **all 52 one-forms**, and the normalizations.
   `multiquadraticStripCanonicalText` is `Together` followed by
   `Expand[Numerator]` **and** `Expand[Denominator]`, so 52 one-forms
   cost 104 `Together` plus 208 `Expand` on algebraic rational functions.
4. **`multiquadraticStripContextFreeQ[payload]`.** A
   `Cases[..., {0, Infinity}, Heads -> True]` traversal of a payload that
   contains the 3,691,398-character equation text.
5. **`multiquadraticStripFingerprint[payload]`.** `ToString[InputForm[...]]`
   plus SHA-256 over that same payload.
6. Support construction, the dimension checks and
   `multiquadraticStripCompileNormalizations`. Listed for completeness;
   all are O(support) on integers and are expected to be small, which
   phase 2 will confirm rather than assume.

**Prior suspect, stated as a hypothesis and not a result: (3) and (4).**
The `Expand` in `multiquadraticStripCanonicalText` is unbounded on an
algebraic one-form, and this same wave removed exactly that `Expand` from
the letter dlog certificate for exactly this reason (the certificate now
hashes the `Together`-only form key the letter builder already computes).
If (3) dominates, the fix is the same one-line class of change — hash the
already-canonical pair instead of re-expanding it — which *would* be a
clear algorithmic win inside the ~2 h bar. That is precisely why phase 2
is worth running before the proposal below is acted on: it decides
whether the remaining 47.5% is a cheap fix or more of the same symbolic
wall.

**How phase 2 is run.** `cf300_attribute.wls payload` times stages 2-5
individually *and* `multiquadraticStripABIPayload` as a whole, so the
parts can be checked against the whole rather than trusted. It reads the
already-measured channel decomposition from
`FrozenTestFixtures_2026-08-25/cf300_frozen_channel_forcing.wl` instead
of re-paying the 1400.5 s that produced it, so it is minutes rather than
an hour. Two constraints are honoured:

- **cheap gate first, enforced by the driver** — `cf300_attribute.wls
  payloadgate` runs the identical phase-2 instrumentation on the small
  synthetic block. The real mode does not merely recommend it: it
  REFUSES to start (exit 3, typed message) until
  `cf300_attribute_payloadgate_result.wl` exists, so the house rule lives
  in the driver rather than in whichever shell invokes it;
- **one main kernel** — it is queued *behind* the full regression and
  starts only when that releases the licence seat. It is never run
  concurrently with the suite.

Its result lands in `cf300_attribute_payload_result.wl` and is appended
here. Until then the figure to quote remains **1422.0 s attributed,
1288.9 s unattributed**.

### Phase 2, run: the hypothesis is REFUTED

`cf300_attribute.wls payload`, **231.9 s**. Result:
`cf300_attribute_payload_result.wl`; log: `cf300_attribution_payload.log`.
The cheap gate (`payloadgate`, 2.5 s) ran first and is a hard
precondition in the driver.

| stage | seconds |
|---|---|
| P1 candidate letters (**excluded**: the reference supplied `LetterRecords`) | *179.6* |
| P2 norm denominator factor | 0.0 |
| P3 rational gauge denominator | 0.1 |
| P4 gauge denominator **merge** | 0.0 |
| P5 `multiquadraticStripABIPayload` (whole) | 35.1 |
| P6 canonical text of the gauge denominator | 0.0 |
| P7 canonical text of **52 one-forms** (2 `Together` + 2 `Expand` each) | **13.5** |
| P8 canonical text of the normalizations | 0.0 |
| P9 context-freedom traversal of the whole payload | 0.0 |
| P10 ABI fingerprint (`InputForm` + SHA-256) | 0.2 |

**The prior suspect was wrong, and it is worth saying so plainly.** The
`Expand` on 52 algebraic one-forms — candidate (3) — costs **13.5 s**,
and the context-freedom traversal over the 3.69-million-character
payload — candidate (4) — costs **0.0 s**. Neither is the missing half.
The hypothesis recorded in the previous section is refuted by
measurement, and the cheap fix it implied does not exist.

#### Why the parts table sums to less than the whole

P6-P10 sum to **13.7 s** against a 35.1 s whole: 61% of that call looked
unmeasured. It is not. The remainder is **21.4 s, exactly the phase-1
`CoreCanonicalData` figure**, and the reason is the call shape: the
harness invoked the NINE-argument `multiquadraticStripABIPayload`, which
delegates with `canonicalData -> Automatic` and therefore **recomputes**
the equation and root texts inside. `13.7 + 21.4 = 35.1`, exactly.
Prepare itself calls the TEN-argument form and hands in the
`coreCanonical` it already paid for, so prepare pays that 21.4 s once.

**Consequence for the total, and it moves the number the wrong way for
me:** counting the 35.1 s whole double-counts the canonical data.
Attributed is therefore **1435.7 s = 53.0%**, not the 1457.1 s / 53.8%
the script printed, and unattributed is **1275.2 s = 47.0%**.

#### Caveat: the cheap gate certifies wiring, never cost

The synthetic gate fixture understates the real payload by roughly
**370x** — gauge denominator degrees `{2,2}` and support 9 on the gate
against `{9,9}` and support 100 on the real block, with 29 one-forms
against 52. Its 0.1 s ABI payload predicted nothing about the real
35.1 s. That is by design and must stay understood: the gate exists to
prove every bucket is wired and every consistency invariant holds before
an expensive run is entered. It is never evidence about how long the
expensive run will take.

### Phase 3, run: the inventory closes, and the residual is not a stage

`cf300_attribute.wls assembly`, **217.4 s** (expected ~25 min; it was not).
Result: `cf300_attribute_assembly_result.wl`; log:
`cf300_attribution_assembly.log`. Peak RSS 916 MB. Its cheap gate
(`assemblygate`) is a hard precondition and was required to reach
`PreparedMultiquadraticStripV1` before the real mode would start — the
check that the harness can run prepare *without* re-paying the
decomposition.

| stage | seconds |
|---|---|
| A1 `transportChartCurrentRoots` | 0.0 |
| A2 `multiquadraticStripRootCensus` over the whole 1.13M-leaf strip | **0.7** |
| A3 `multiquadraticStripRootOrder` (denest + square-class match) | 0.0 |
| A4 candidate letters (**excluded**: reference supplied `LetterRecords`) | *173.2* |
| A5 norm factor / rational denominator / merge | 0.0 / 0.1 / 0.0 |
| A6 support (100 points) + normalizations | 0.0 / 0.0 |
| A7 sealed forcing-channel record (V2, **wave-added**) | 1.2 |
| A8 final `Together` on the denominator pair | 0.0 |
| **A9 prepare END TO END, channels + letters supplied** | **39.2** |

Every stage the earlier passes had not measured is negligible: the root
census over a 1.13-million-leaf strip is **0.7 s**, not the multi-minute
stage the candidate list anticipated. Bucket total 2.0 s.

**A9 is the decisive number.** Prepare run end to end with the forcing
channels and letter records supplied — everything prepare does except
the decomposition — is **39.2 s**. The 2710.9 s reference implies that
same work should be **1310.4 s**. It is not.

#### The strip is the same strip, so this is not a fixture mismatch

Checked before drawing any conclusion:

- reference `StripLeafCount` = **1133532**; the attribution runs measure
  E 87 + C 99 + BBar 1133345 leaves, and `LeafCount[{e,c,bbar}]` =
  `1 + 87 + 99 + 1133345` = **1133532**. Identical.
- reference `LetterCount` 52 / `LetterSeconds` 183.4; phase 3 measures
  52 one-forms / 173.2 s. Consistent.
- `cf300_prepare.wls` passes `"LetterRecords" -> letterRecords`, so the
  alphabet is outside the 2710.9 s in both accounts.

#### What the residual actually is

With the inventory complete and the strip identical, the ~1271 s cannot
be an unmeasured stage of prepare. The arithmetic forces the conclusion:

```
  reference prepare            2710.9 s   (pre-wave code, 2026-08-25 15:58)
  current: decomposition       1400.5 s   (phase 1, measured)
  current: everything else       39.2 s   (phase 3 A9, measured)
  current prepare total        1439.7 s
  implied pre-wave decomposition = 2710.9 - 39.2 = 2671.7 s
```

**METHODOLOGICAL CAVEAT, stated because it changes what the numbers
mean:** every stage figure in phases 1-3 was measured on the CURRENT
code, while the 2710.9 s reference was measured before this wave. The
"unattributed" residual was therefore never a missing stage — it is the
difference between two code versions being compared as if they were one.
The wave's own change to that path is the recursive quadratic-tower
inversion, which replaced the symbolic 2^r x 2^r solve inside
`multiquadraticFieldInverse` that `multiquadraticFieldDecompose` calls
once per entry. Phase 4 measures that directly rather than asserting it.

### Phase 4, run: the tower inverse is exact and faster — but this does NOT establish the stage attribution

`cf300_inverse_route.wls cf300`, **48.8 s**. Result:
`cf300_inverse_route_cf300_result.wl`; log: `cf300_inverse_route.log`.
One forcing entry of the real block, decomposed twice — once through the
recursive quadratic-tower inverse this wave introduced, once through the
older symbolic 2^r x 2^r `LinearSolve` inverse. Both routes are held to
the same exact product check, so this is a cost comparison between two
accepted answers.

| | seconds |
|---|---|
| entry leaf count | 72,021 |
| `multiquadraticFieldDecompose`, **RecursiveTower** | **2.7** |
| `multiquadraticFieldDecompose`, **LinearSolve** | **43.0** |
| the two routes agree **exactly** | yes |
| per-entry speedup | **15.76x** |

**Two caveats, both found by this run and both limiting what may be
claimed.** First, its cheap gate initially certified nothing — it used
radicals that were not the frame's declared roots, so the census
returned rank 0 and both routes returned `$Failed`; the gate caught it,
and it was additionally hardened so that a failing gate no longer writes
the record that unlocks the real run. Second, **the eight forcing
entries are very unequal**: the entry measured carries 72,021 of the
1,133,345 BBar leaves, so the `8 x per-entry` figure the script prints
is NOT a valid extrapolation and is not quoted here. The stage figure
stays the directly measured 1400.5 s.

### Attribution, closed: the four-pass total

```
  CURRENT prepare, CF300 (12,9), all measured on current code
    forcing channel decomposition        1400.5 s   97.3 %
    everything else (phase 3 A9)            39.2 s    2.7 %
      of which ABI payload own work         13.7 s
               CoreCanonicalData            21.4 s
               sealed channel record (V2)    1.2 s
               root census                   0.7 s
               rational gauge denominator    0.1 s
               record assembly, options    ~ 2.1 s
    ------------------------------------------------
    total                                 1439.7 s
```

The parts sum to the whole within ~2 s, which is the account the earlier
passes could not produce.

**The dominant stage, named by measurement, is the forcing channel
decomposition at 97.3% of current prepare.** Not the ABI payload, not
the `Expand` on the one-forms, not the root census — each of those was a
stated hypothesis and each was refuted by a number.

**And the 2710.9 s reference is superseded.** It was measured on pre-wave
code; current prepare on the identical strip is 1439.7 s.

**CORRECTION, caught by the phase-4 watchdog and recorded because the
first draft of this section over-claimed.** It is tempting to read phase
4 as showing the mechanism for that 1271 s. It does not, and the
arithmetic says why:

```
  entry [[1,1,1]]   72,021 leaves =  6.35 % of the stage's leaves
                       2.7 s      =  0.19 % of the measured 1400.5 s
  the other 7 entries 1397.8 s    = 99.81 % of the stage
  per-leaf cost, measured entry   : 0.037 ms/leaf
  per-leaf cost, the other seven  : 1.317 ms/leaf   (35x higher)
```

The entry that was measured is **0.19% of the stage cost**. A 15.76x
speedup on it is not evidence about the stage, and the `8 x per-entry`
line the script prints (21.8 s) contradicts the directly measured
1400.5 s by 64x, which is itself the proof that the entries do not
scale linearly. So:

- **Measured and safe to quote:** on one real entry the two inverse
  routes agree exactly and the tower is 15.76x faster (43.0 -> 2.7 s).
- **NOT established:** that the tower inversion accounts for the
  2671.7 -> 1400.5 s stage-level change. The direction is right and
  nothing contradicts it, but the magnitude is unmeasured.
- **Therefore the pre-wave/post-wave difference remains explained in
  KIND and unexplained in MAGNITUDE.** The 2710.9 s figure should be
  treated as superseded rather than as a baseline for a speedup claim.

**What would settle it, named as the next measurement and deliberately
NOT run tonight:** decompose the DOMINANT entry (not an arbitrary one)
through both routes. Its tower cost alone is of order several hundred
seconds and the LinearSolve route could be an order more, so it is a
scheduled measurement with its own gate and watchdog, not a tail-end
addition to this one. Cheaper and nearly as informative: time the eight
entries individually on the tower route (one 1400.5 s pass) to find
which entry dominates before paying for any comparison on it.

### The proposal, re-scoped to what the numbers say

The earlier proposal targeted 52.5% of a 2710.9 s prepare while a
comparable share sat unexplained. That framing is now obsolete:

> **Proposal (not built), re-scoped.** On current code the forcing
> channel decomposition is **97.3%** of prepare — 1400.5 s of 1439.7 s —
> over 8 entries, all structurally distinct, none root-free, all on the
> algebraic path. Nothing else in prepare is worth attacking: the entire
> remainder is 39.2 s, so even reducing it to zero buys 2.7%. The single
> lever is `multiquadraticFieldDecompose`, and the route is the
> evaluate-and-reconstruct treatment `applyRowGauge` got on 2026-08-23:
> decompose at sampled points over a finite field, interpolate and lift
> the channels, accept only on the existing exact recompose check, fall
> back to the symbolic path on any failure. The acceptance gate already
> exists, which is what makes the substitution safe. Beyond the ~2 h bar;
> needs its own adversarial tests.
>
> **What this wave contributed to that same lever:** the recursive
> quadratic-tower inversion, measured at 15.76x on one real entry with
> both routes agreeing exactly. Its stage-level share is NOT measured
> (that entry is 0.19% of the stage), so no speedup figure for the wave
> is claimed here. The proposal above is what remains regardless.
