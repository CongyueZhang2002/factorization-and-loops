# Request to Fable: canonical pullback and CF259 first-run compiler

Date: 2026-08-28 17:35 PDT  
From: Codex  
Status: implementation and all three family missions paused pending this assessment

Fable, please assess the mathematical/algorithmic choices below before Codex changes or relaunches anything. The user explicitly rejected carrying a non-canonical compositional gauge through the workflow. Please distinguish a genuine first-run improvement from checkpoint/retry avoidance.

## 1. Gauge pullback: canonical output is required

The hard rational-chart solves themselves succeeded:

- CF300 `(12,7)`: inner finite-field solve 109.5 s.
- CF303 `(21,18)`: inner finite-field solve 123 s in the preceding run.
- CF259 `(21,16)`: inner finite-field solve 24.2 s.

The old source-gauge pullback then called symbolic `Together` on the substituted gauge. CF300 and CF303 were still inside this operation after more than 19 minutes and were canceled. CF259's smaller Kallen1 source substitution took 2.1 s, but the old full-gauge branch round-trip took another 22.3 s and falsely rejected it as `StripGaugeRoundTripUndeclaredRadicals`.

Codex implemented `"GaugePullBackMode" -> "CompactCompositional"` in commits `d4512b2` and `d89165b`: exact inverse-map substitution without a common fraction, with branch selection proved on the small coordinate map. It passed the package tests. However, this is a bypass of canonical normalization, not a faster canonical normalizer. The user has rejected this representation for production. No family should be relaunched through this mode.

Measured normalization alternatives on the captured physical gauge payload (`40,092` leaves for the tested entry):

- raw exact substitution only: 0.001867 s (not canonicalization);
- Mathematica `Together`: physical 2x2 pullbacks exceeded 1,140 s;
- Maple `evala(Normal(...))`: 93.573 s for the captured entry, Maple exact difference zero, 89,464 output characters;
- Fermatica plain `FTogether`: 363.6 s, produced a 12,853,339-leaf result and failed the independent numerical comparison;
- Fermatica quotient pilot: no result after more than 13 minutes; canceled.

Please assess:

1. Is entrywise Maple `evala(Normal)` the smallest sound general production route for a canonical source gauge, provided every imported result is independently checked in the declared multiquadratic field?
2. Is there existing package/Exchange Maple serialization code that should be reused rather than adding another translator?
3. If you recommend a non-Maple canonical route, specify an implementable quotient-field algorithm and why it is smaller/safer than Maple integration. Merely retaining the compact composition is not an option under the user's decision.
4. Should `CompactCompositional` be removed entirely now, or retained only as a diagnostic option with Production restored to canonical `Exact`?

## 2. CF259 `(21,16)`: the real 2,451-second first-run bottleneck

This is one specific off-diagonal block, sector pair `(21,16)`, gauge dimensions `2 x 4`; it is not a once-per-family initialization.

Measured decomposition:

- total strip construction: 2,450.9 s;
- deferred bundle `CompileSeconds`: 2,330.609512 s;
- preparation plus raw census: about 13.9 s;
- parallel materialization of 16 forcing entries: 106.4 s;
- subsequent finite-field solve: 24.2 s.

Thus bundle compilation is 95.1% of construction and 99.4% of the pre-materialization interval. Saved-input reuse prevents repeating this on a retry, but the user correctly notes that this is checkpointing, not a solution to first-run cost.

Current-main inspection shows exact factor interning is absent. `BlockEquationDeferred.wl` still has `registerFactor` linearly scan the complete factor table and call `factorMatchQ` for every registration. The persisted bundle has:

- 96 operands;
- only 21 distinct factors, 7 algebraic;
- 3,488 divisor occurrences;
- roughly 680 canonical denominator-factor registrations before explicit-negative-power registrations.

The proposed smallest genuine first-run fix is a local exact-expression index:

- map each exact factor spelling and its negative to the already assigned factor index;
- return immediately on an exact `SameQ` hit;
- retain the current exact `factorMatchQ`/algebraic-zero scan on a miss;
- memoize a spelling after either a fallback match or a new insertion;
- preserve first-occurrence numbering and bundle output exactly.

This should reduce hundreds of repeated algebraic equivalence scans to O(1) lookups while leaving nonidentical-but-equal factors on the existing exact fallback. A cold compile below 1,550 s would prove at least 1.5x; the 680-to-21 repetition ratio suggests a larger gain may be possible.

Please assess:

1. Is this exact-spelling factor index the correct first optimization?
2. What minimal counters are worth retaining (`registration calls`, `exact hits`, `fallback comparisons`, `factor-match seconds`) without adding defensive-code clutter?
3. Do you see a stronger concise first-run algorithmic improvement in the compiler? Pure-operand TaskBroker parallelism already measured only 144.3 -> 142.1 s on a smaller compile and should not be repeated.

## 3. Resume cache and process policy

Codex added a generic sealed-strip input cache so a failed solve can reuse an already constructed exact strip/bundle. In the clean trial it did not accept the available CF300/CF303/CF259 inputs, so those runs began reconstruction. The missions were stopped. Please inspect the cache gate in `Scripts/family_epsform_sector.wls` and identify the actual failing predicate; do not recommend more hashes as a substitute for the algorithmic fixes above.

The ad-hoc mid-run family reload wrapper has been deleted. From now on package changes require terminating Codex's pool and starting one clean main kernel with eight clean subkernels. This is a process rule, not package machinery.

## Requested response

Please answer with a concrete disposition:

- canonical pullback backend and exact validation contract;
- remove or diagnostic-only status for compact composition;
- go/no-go and exact implementation shape for factor interning;
- the resume-cache predicate failure;
- the smallest test/benchmark gate required before the three families are relaunched.

