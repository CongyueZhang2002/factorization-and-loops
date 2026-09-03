# R1: adversarial review of agent T's non-eps-form transport (round 8)

Subject: `Design/PrivateOverhaul_2026-09-01_evidence/round8/T_noneps_transport.md`,
`FeynFacet/Private/Transport/Observable/RationalEpsilonLayer.wl` (618 lines),
`Tests/Transport/t_rational_epsilon_layer.wls`, all at HEAD `f2965aed`.
Reference: Codex's CF303 reports and scripts (read only), note 05 of
2026-08-30. Package read only; nothing committed; every kernel through the
seat launcher under a 300 s cap. Evidence under
`scratchpad/round4/R1/` (`test_run.log`, `r1_adversarial.wls` +
`r1_adversarial2.log`, `r1_order2.wls` + `r1_order2b.log`).

**Reproduction of T's test.** `t_rational_epsilon_layer.wls` through the
launcher: 19 assertions, 0 failed, 2.6 s after the TestKit load (the
report's "19/19 in about 3 s" is confirmed). Route on the fixture 0.06 s.

**Adversarial fixture** (`r1_adversarial.wls`, 9.3 s after load): the test's
own 2x2 layer and 2-master source with (i) a source boundary selector at
order -1 (CF303's source has orders -2..5), (ii) a numerical solution of the
ODE `dF = A F` order by order (NDSolve, 30 digits) compared with the
route's word sums evaluated as numerical iterated integrals, (iii) a
coefficient whose lowest eps order vanishes at the three fixed valuation
probe points, (iv) non-constant residue matrices, (v) refusal probes
(pole at the base point, an undefined coefficient, a non-quartic curve,
`ZeroColumns` hygiene, a mixed eps/u denominator, a bad prime).

## Findings, ranked by severity

### S1 (high, correctness): the eps window stops at the highest DEMANDED order, so every word with a negative source boundary order is missing; accepted status, predicate True

`RationalEpsilonLayer.wl:427-429`: `high = Max[demandPairs[[All, 1]]]`,
`orders = Range[low, high]`. A word `D^a K_r S^b Sel[q]` contributes at
`q + a + r + b`, so with a source boundary order `q < 0` the demanded
order `N` needs `K_r` up to `r = N - q_min`, not `N`. Only the orders in
`orders` are Laurent-expanded (431-437), enter the recurrence (233-266)
and become K letters (312, 339), so those words never exist. Failing
input (fixture A): the test's source with `BoundarySelectors` at orders
`{-1, 0, 1}`, demand `{{0,1}}`: 73 words (direct route) / 83 (modular);
demand `{{0,1},{1,1}}`: 74 / 86 for the SAME pair `{0,1}` -- the
additional words are `K_1 Sel[-1]` on `{1+u^2, 1}` (direct) and on
`{1+u, 0}, {1+u^2, 0}, {1+u^2, 1}` (modular). Numerically (fixture D,
direct route, path 1/2 -> 1/4): the order-1 transported value of row 1 on
the first source boundary constant is 0.07400 by the ODE and 0.00726 from
the route's words when order 1 is the highest demand, row 2 on the second
constant 9.6298 versus 4.0846; with the window widened (order 3 also
demanded) the word sums agree with the ODE to 1e-9 on every component of
orders -1..2. Both results carry `RationalEpsilonLayerTransportAccepted`
and pass `AcceptedRationalEpsilonLayerTransportQ`.

This is exactly the CF303 measurement's situation: the stored artifact
`.../CF303/rational_layer_2026-09-02/rational_sublayer_p9d8.wl` has
`"Window" -> {-2, -2}`, all 7,342 words have `"IncomingOrder" -> -2`, and
they sit on boundary orders -2 (5,592), -1 (1,708) and 0 (42): the words
`K_0 Sel[-2]`, `K_{-1} Sel[-1]`, `D K_{-1} Sel[-2]`, `K_{-1} S Sel[-2]`
that the demand (orders -4..-2) needs are absent. Codex states the
requirement correctly ("only orders -2..4 are needed for the requested
target window -4..2", `CF303_FINAL45_ELLIPTIC_TRANSPORT.md:41`; "H window
-3..4"); T's formula would give -2..2 for that target. The fixture test
cannot see it because its source has no boundary order below 0.

Fix: `high = Max[demanded orders] - Min[Keys[source["BoundarySelectors"]]]`
(and the target selectors' minimum for the D-only words), then a
fixture assertion with a negative boundary order.

### S2 (high, correctness): `"MaximumWeight" -> 4` truncates the word list silently

`RationalEpsilonLayer.wl:325` (`0 <= a <= maximumWeight`), `:340`, `:353`
(`Min[maximumWeight, ...]`), `:298` (`Min[maximumWeight, needed[q]]`).
Words with `a + b` above the cap are dropped with no status, while
`"MaximumWords"` is typed (`WordEnumerationCapped`). Failing input
(fixture B): demand `{{3,1}}` on the order -1 source: 559 words at the
default, 812 at `"MaximumWeight" -> 8`, no capped status, predicate True.
The CF303 run used `"MaximumWeight" -> 3`, harmless for orders <= -2 but
silently wrong for the real target (orders up to 2 from `q = -2`, `r =
-2`: weight up to 6). The option is not in the usage message. Fix: derive
the weight from the demand and the window (it is already computed as
`weightByOrder`), keep the option only as a typed cap.

### S2b (medium-high, correctness): the two word kinds are stored with opposite letter orders

`RationalEpsilonLayer.wl:328` stores a target-boundary word as
`state[[1]]` (application order, innermost letter first); `:347` stores a
source-boundary word as `Reverse[state[[1]]]` (outermost first,
`D...D K S...S`). The diagonal residues do not commute, so a consumer
reading `"Word"` with one convention evaluates one of the two kinds
wrongly. Failing input (`r1_order2.wls`, direct route, demand `{{2,1},{2,2}}`
with the window widened by also demanding order 4): four length-2 target
words at order 2; word sums against the ODE: as stored 0.0214 (row 1)
and 0.0214 (row 2), with the target words reversed 7e-11 and 1.5e-9.
The test cannot see it: its demand reaches at most order 0, where every
target word is empty. Fix: `Reverse` at `:328` as at `:347`, and an
assertion with a length-2 target word.

### S3 (high, design): for a u-dependent layer the route's output cannot be consumed

`F_T = G + H F_S`; the words give `G` only. `H` is kept as modular images
over `F_q(u)` (`"GaugeStatus" -> "GaugeNotReconstructed"`, 587-588) and
is never lifted, not even its value at the endpoint (d x n rationals per
order, cheap). So on any layer where the Hermite gauge is nonzero -- the
only case that justifies the route, i.e. CF303's exception forcings --
no consumer can form the transported value, and the certificate says
nothing about it. Codex's route replays the merged `H` through `T25` for
this reason. The direct route (`H = 0`) is complete, but there the layer
is already dlog order by order and "non-eps-form transport" reduces to
the weighted-word grammar.

### S4 (medium, contract): the predicate is a shape check, not a re-verification

`rationalLayerCertificateShapeQ` (595-610) and
`AcceptedRationalEpsilonLayerTransportQ` (612-618) test status strings,
counts > 0, mismatches == 0 and that the fresh prime is not among the
primes. Nothing binds the certificate to the inputs or to `KResidues`
(no fingerprint of source/layer/demand, no residue re-check at the fresh
prime); replacing `KResidues` by anything leaves the predicate True. The
report's "re-checks the shape and binding" overstates it, and CLAUDE.md
says structural shape checks are never success criteria. The tampered-
certificate assertion only flips `ResidueMismatches`.

### S5 (medium, silent acceptance): non-constant residue matrices pass

Diagonal and source residues are checked for dimensions only (391, 396).
Fixture F: a diagonal residue `{{u, 0}, {0, 2}}` (direct route) and a
source residue containing `eps` both give `RationalEpsilonLayerTransportAccepted`
with the symbols inside the word coefficients, predicate True; the
modular route also accepts the u-dependent diagonal residue and then
treats that letter as a constant-residue dlog letter in the word growth.
Fix: refuse typed unless every residue entry is `_Integer | _Rational`
(or a declared constant).

### S6 (medium): the valuation "certificate" is three fixed points, not random, and its miss is silent

`:420`: points `base, base + 1/3, base + 2/7` (the report says "random
rational points"). Fixture E: coefficient
`(u-1/2)(u-5/6)(u-11/14)/eps^3 + 1/eps^2` is certified at -2, the eps^-3
term is dropped by `observableTransportLaurentEntrySeries` (which only
counts it in `$observableTransportLaurentDiagnostics["ValuationBelowRange"]`,
never read here), status accepted, window {-2,-2}, predicate True.
Contrived, but the fix is one line: take the Series' own `nmin` (or read
the diagnostic) and refuse when it is below the certified valuation.

### S7 (low-medium): bad primes are fatal with a misleading status, not skipped

A prime at which a pole factor is not square-free, or a coefficient
denominator vanishes, ends the whole route: fixture G6 with the schedule
`{1000003, ...}` and factor `u^2 - 1000003` returns
`ResiduePoleNotInAlphabet` at prime 1000003 (`:250`); a vanishing
coefficient denominator is `CoefficientNotDefinedAtPrime` (`:244`). Both
should skip the prime. With random 31-bit primes the probability is
negligible; the status text is the defect. Related: the Hermite
correctness at a prime rests on `PolynomialGCD[..., Modulus]` returning a
monic result (the extra division at `:200` by `Coefficient[reduced, u, 0]`
is a no-op only then); it holds on the fixture (residues SameQ with the
reference) but is not asserted.

### S8 (low): claims in the report that the code does not implement

- "curve letters admitted only when a curve `Y^2 = P4(u)` is declared and
  the degree is 4": `:86` checks `curve === None` only; fixture G3 with
  `"Curve" -> u^2` passes the gate (`CurveChannelNotImplemented`).
- `"PhysicalGaugeNotApplied"` / the T25 step: absent from the package
  (grep), the report presents it as "the typed status the route would
  carry".
- `LowerBlockExceptionRequired` is a column-presence proxy (`:402`): a
  column with one declared term and a missing forcing is not detected.
  `ZeroColumns` naming a present column or an out-of-range column is
  accepted (fixture G4).
- The curve alphabet (`:48`) lacks `E4Eta2`, which Codex's block-1 circuit
  resolver emits for elliptic quotients
  (`cf303_hybrid_path_gauge_operator_2026-09-01.md`, "Circuit resolver").

### S9 (low, provenance): the commit mixes M's work under T's message

`f2965aed` changes `EpsForm/FiniteField/FiniteFieldGaugePullBack.wl`
(timing instrumentation) and `FiniteFieldStripSolve.wl` (146 lines) while
the report says the EpsForm solver files were untouched. Mixed-authorship
commit; should be recorded in the log.

### S10 (low, test design): what the "independent reference" does and does not cover

Independent: the Hermite reduction (extended-gcd versus Horowitz-
Ostrogradsky) and the exact recurrence. Not independent: the demanded-
word assertion rebuilds the words with the route's own
`rationalLayerWords`; the counts (1, 0, 7, 5, 26, 23) are pinned from an
earlier run of the same code; no target word of length >= 2, no source
boundary order below 0, no evaluation of any word. My ODE check supplies
the missing end-to-end test for the direct route: recurrence sign and
order conventions, the coefficient conventions (source boundary constants
shared across orders, target constants per order, 6-vector = 2 + 2 + 2)
and, once the target words are read in the source words' letter order (S2b), all agree with the ODE to 1e-9 when the window is wide enough.

## Generality (point 2)

No family logic in package code: `CF303`, `9/8`, `3/4` occur in comments
only (`:3, 55-56, 134, 218, 283, 296, 449, 456, 492`). The CF303-specific
steps live in the scratch adapter (`scratchpad/round4/T/round8/cf303_adapter.wls`):
the specialization at `p = 9/8`, `uFinal = 3/2`, the merge of conjugate
algebraic pole pairs into `GPLFactor` letters with residues `R+ + R-` and
`-(R+ c- + R- c+)`, the diagonal residues from the constant generators,
the dropping of curve terms. The merge is general and belongs in the
package; without it the gate's `AlgebraicPoleNotAdmitted` makes every
generic-p source unusable. The gate rejects what it claims for the
rational letters (algebraic pole, non-square-free factor, unknown head,
power >= degree); the curve degree claim is not implemented (S8). The
curve channel's absence is typed at the gate (`:408`) and the words never
see a curve letter; the K-key schema `{order, factor, power}` and the
K-letter label have no slot for a cohomology component or a sheet, so the
elliptic channel cannot be added without changing them.

## Measurement honesty (point 3)

What was measured (run 6 -> run 8 logs, confirmed): the rational
sub-layer of CF303 block 25 at `p = 9/8` -- 96 curve terms of 874
dropped, 30 of 107 source letters dropped, the seven exception columns
declared zero -- with demand orders -4..-2, `"MaximumWeight" -> 3`, and the
window {-2,-2}, which by S1 misses the `K_{-1}`/`K_0` words of that very
demand. "46.7 s -> 1.1 s" is the removal of twelve modular images that
computed residues which are exact Laurent coefficients (the transfer's
coefficients are u-free, so the gauge vanishes identically) plus the
demand-pruned source growth (89,445 -> 278 states). The modular circuit's
own cost is unchanged (about 3 s per order-image for 86 entries and 17
factors; 38.9 s in the run-8 cross-check). The 7,342-word count and the
SameQ cross-check are for the same demand and options (both `MaximumWeight
3`, `MaximumWords 20000`, run 8), so the SameQ is genuine -- between two
equally incomplete enumerations.

What a real CF303 run would cost by the report's own numbers: window
-2..4 (7 orders) instead of 1; the u-dependent exception forcings through
the modular circuit at >= 12 primes (7 x 12 x 3 s = 250 s if they were as
cheap as the transfer entries -- Codex measured 21-27 s of leaf
specialization per image for them); and the word enumeration to weight 6
(89,445 states at weight 3 took 10 s; Codex's order -1 exceeded a
20,000-word cap). The enumeration is exponential in the weight, so the
real target is out of reach of this enumerator regardless of the 1.1 s;
the report gives no estimate for it.

## What remains for CF303 and what the design would have to undo (point 4)

- Elliptic channel: `rationalLayerModularFunction`/`rationalLayerHermite`
  are `F_q[u]`-only; the curve needs `F_q2` (the split field of the
  quartic, Codex's q7), `Q(Y)`-valued residues, the three-component
  cohomology part (`E4Omega0`, `E4OmegaInf`, `E4Eta2`), a sheet
  convention. The K-key schema and the K-letter label must change (S8).
- Exception forcings: Maple text only; an importer is needed before the
  modular circuit does anything real; then S3 (lifting `H`) becomes
  mandatory, and the per-image cost has no native batch path (the report
  says the finite-field compiler was not applied).
- T25: nothing in the package (S8); it is where `H` is consumed in
  Codex's route, so S3 and T25 are one design item.
- p-dependence: fixed rational `p`; the conjugate-pair merge is in the
  adapter; the direct route's `Exact -> True` holds at that `p` only.
- Source layer from a family record: not started; the source is consumed
  as Codex's artifact. The charter said "on top of
  `BuildObservableTransport`'s machinery"; the implementation shares the
  Laurent helper and the valuation probe only, and its word enumerator is
  not the operator automaton.
- Window (S1) and weight (S2) are fixes, not undo; `H` kept modular (S3)
  is a design decision to undo for every u-dependent layer.

## Recommendations, in priority order

1. Fix S1 (window from the minimum source and target boundary orders),
   S2 (weight from the demand; the option a typed cap) and S2b (one letter
   order for both word kinds), add fixture assertions with a negative
   boundary order and a length-2 target word,
   and add the ODE check of `r1_adversarial.wls` section D to the test
   as the independent end-to-end reference; re-run the CF303 sub-layer
   and replace the 7,342 figure.
2. Lift `H` at the endpoint (and record it in the certificate) or refuse
   typed any u-dependent layer whose demand needs the transported value;
   do not ship a route whose only consumable case is the trivial one (S3).
3. Bind the certificate: fingerprint of source/layer/demand and of
   `KResidues`, re-check of every residue at the fresh prime inside the
   predicate (S4); refuse non-constant residues typed (S5); read the
   Series valuation and refuse below the certified one (S6).
4. Move the conjugate-pair merge from the adapter into the package (the
   generic-p case); implement the curve-degree gate; add `E4Eta2` to the
   curve alphabet; skip bad primes instead of failing (S7, S8).
5. Before any elliptic work, decide the word representation: the
   enumeration cannot reach weight 6 on 107 letters; either the operator
   automaton of `BuildObservableTransport` or a lazy per-word evaluator as
   in Codex's route.
6. Record S9 in the log; state the measurement in the plan as "rational
   sub-layer, incomplete window" until item 1 is done.

## Verdict

Not finished: the route as committed returns accepted, predicate-True
results that are incomplete whenever the source has a negative boundary
order (S1, numerically wrong at order 1 on the fixture, and the case of
every CF303 demand) or the demand needs weight above 4 (S2), its two
word kinds carry opposite letter orders (S2b), and its
output is not consumable on the only class of layers it was built for
(S3); the general skeleton, the typed gate, the Hermite circuit and the
direct route are sound where tested.
