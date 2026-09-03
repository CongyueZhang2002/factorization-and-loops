# Round 8, agent T: transport of a non-epsilon-form final layer (user mandate "like CF303")

Report written as the work proceeds. Rules: every kernel through the seat
launcher; nothing committed; the EpsForm solver files untouched (agent M);
Codex's tree read only. Sources read for section 1: the plan's Round 8
section; `Exchange/Codex/2026-08-30/05_cf303_dlog_no_go_and_rational_kernel_route.md`;
Codex's reports `CF303_FINAL45_ELLIPTIC_TRANSPORT.md`,
`cf303_hybrid_path_gauge_operator_2026-09-01.md`,
`cf303_hybrid_baseline_lazy_adapter_2026-09-01.md`,
`CF303_DEPTH2_EMPL_MILESTONE.md`, `CF303_HYBRID40_ELLIPTIC_OPERATOR.md`,
`cf303_modular_exception_hermite_pilot_2026-09-01.md`,
`cf303_block1_finite_gauge_circuit_2026-09-01.md`; the scripts
`cf303_lazy_final_elliptic_transport.wl` (431 lines),
`cf303_hybrid_circuit_path_gauge_adapter.wl` (407),
`cf303_hybrid_baseline_lazy_circuit_adapter.wl` (366),
`cf303_hybrid_baseline_modular_circuit.py` (1,414),
`cf303_block1_circuit_point_resolver.py` (308), the two JSON manifests,
and a kernel probe of the accepted artifacts' shapes
(`scratchpad/round4/T/keys_probe*.wls`).

## 1. Assessment of Codex's provisional CF303 route (no code)

**What the object is.** CF303 has 45 masters. The first 43 form an
epsilon-linear Chen operator on the direct path `z: 1/2 -> uFinal` in the
chart variable `u` with parameter `p` (Codex artifact
`cf303_hybrid_elliptic_operator_15_17_21.wl`: 43 masters, 107 letters, 107
residue matrices 43x43, 287 boundary columns, source orders up to 5). Its
letters are ordinary `GPLPole`/`GPLFactor` forms and, for blocks 15/17/21,
curve letters on the quartic `Y^2 = P4(p,u)` (`E4Pole`, `E4Factor`,
`E4Omega0`, `E4OmegaInf`; no second-kind `eta2` occurs on this path). The
final block 25 (rows 44,45) is dlog on the curve but its 72 incoming path
entries are RATIONAL IN EPSILON with valuation -2 (the 76-entry transfer
`cf303_block25_general_elliptic_transfer.wl`, 409 KB: each entry record is
`{target, epsilonProfile, primitivePair, letterTerms}` with letter terms
`{rational function of (eps, p, u), letter label}`; label census over the
76 records: GPLFactor 446, GPLPole 350, E4Pole 36, E4Factor 28, E4Omega0
16, E4OmegaInf 16); the 2x2 diagonal has 6 letters whose residues span 3
constant generator matrices. Block (25,18) has no rational dlog form (note
05: defect 1 at three modular images, gauge-eliminated, closed), which is
why the final layer cannot be brought to a global epsilon form; the
obstruction is only to a single global eps-form, every one-form is still
dlog on the curve. Target window: orders -4..2 of the physical masters,
which needs incoming orders -2..4 (H window -3..4) and the source operator
to order 5. The physical gauge `T25` (orders 0..2, `I_25 = T25 . F_25`)
is a separate accepted artifact.

**General versus CF303-specific.**

| general (belongs in the package) | CF303-specific (stays data) |
|---|---|
| a lower-triangular final layer whose incoming connection is rational in eps: transported ORDER BY ORDER; a word reaching the final rows has exactly one incoming edge, `D...D` or `D...D B_r S...S` (the "one-incoming-edge weighted Chen" grammar, `cf303FinalEllipticWordCoefficient`) | master numbering, the direct path and its parameter `p`, the base point 1/2, the support graph `{1,2,12,21,22,29,30}`, the constant generators, `q7`, the extension `omega^2 = 2` |
| the path gauge that removes the non-dlog part of each incoming order: `K_n = B_n + D H_(n-1) - H_(n-1) S - dH_n`, `H(base) = 0`, with `H_n` the exact (Hermite primitive) part and `K_n` the residue part of the one-forms at order n | the seven lower-block forcings (blocks 1, 2, 11, 14, 18, seven source masters) as 3-72 MB Maple text plus Python-parsed censuses |
| Hermite reduction of univariate rational one-forms on the path (rational channel) and, on a quartic curve, the split into exact part + simple poles + the cohomology basis `{1, u, u^2}` (elliptic channel) | the T25 gauge values, the block-1 138-node DAG, the eps/p degree profiles (203, 127) |
| the deferred exact circuit: leaves specialized FIRST (path point, `p`, eps image), recurrence executed over `F_q` or `F_q2`, no characteristic-zero `H/K` matrix ever expanded, only the demanded coordinates carried | the artifact chain (Maple -> Wolfram -> JSON -> Python) and its file names |
| `GPLFactor[q,k]`/`E4Factor[q,k]` root-free labels split into marked points only at output | the paper conventions of the elliptic branch |

**Correctness contract as built.** (i) The source operator and the 76-entry
transfer come from Maple reductions with exact derivative residuals
(`census_cf303_remaining_elliptic_layers.mpl`: 48/48 block-21 entries;
block 15: derivative residual (0,0)); (ii) the lazy final operator is
checked against an independent full-residue-matrix reference on six word
shapes (empty, one and two diagonal letters, one incoming, diagonal/incoming,
incoming/source) -- a structural check, not an identity over all words;
(iii) the deferred circuit is accepted by MODULAR IMAGES only: at two
`(q7, p)` points, 688/688 recurrence coordinates, 688/688 `H(1/2) = 0`,
2,408 merged-H and 672 cross-K `T25` scalar-channel comparisons per point
(6,160 total); the exact object is "the provenance-sealed circuit", the
images are its evaluator evidence -- no cross-prime lift, no
characteristic-zero identity, no fresh-prime validation of a reconstructed
result; (iv) the block-1 circuit: 15,024/15,024 coefficient comparisons
across q1-q7 at two `p`. There is no acceptance PREDICATE in the sense of
`AcceptedObservableTransportQ`: acceptance is the status string of each
artifact plus the manifests' counts; a consumer cannot re-verify a claim
from the artifact alone.

**What is missing (Codex's own audit, confirmed).** The 76-entry deck omits
the typed transport exceptions of lower blocks {1,2,11,14,18} (seven source
masters); their forcings exist only as Maple text parsed by the Python
circuit; the T25 convolution is applied inside the Python evaluator's
comparisons but NOT to the Wolfram lazy operator (rows 44-45 are canonical,
not physical); the Wolfram adapter of the deferred baseline was never
executed in a kernel; the low-order materialization artifact is stale
(76-entry) and quarantined; nothing is in the package, nothing is
family-neutral, every status string carries the family name.

**Cost distribution (Codex's measurements).** Deferred circuit per
`(q, p)` image: D/S specialization 21-27 s (exact parsing of Maple text +
conjugate-root specialization), primitive specialization 5-6 s, the whole
eight-order recurrence 4 s -- i.e. 80 % of an image is parsing and
specializing leaves, not the recurrence. Modular Hermite of one exception
block: 3.2 s (block 2) against 299 s symbolic; block 1: 1.8 s selected
scalar sampler against 2,532 s symbolic compile. One-time Maple work:
block-21 normalization 16.8 min (peak 2.8 GB); the characteristic-zero
all-at-once recurrence: killed after 3:58 h at 36 GiB. Lazy operator
construction 0.3 s; materialization of orders -4..-2 of rows 44-45
(3,158 words): 59 s; order -1 exceeds a 20,000-word cap. The lesson is the
same as round 4's for CF259: specialize first, never canonicalize the
tensor, reconstruct only what is demanded.

**Dependence on retired code.** The lazy final operator calls
`masterTransportCanonicalChenWordCoefficient` and
`masterTransportCWNonzeroSparseQ`, which live in
`FeynFacet/Private_Backup/CanonicalWordTransport.wl` since round 2 (the
Libra word engines). The package route must therefore be built on
`BuildObservableTransport`'s operator automaton, not on the retired Chen
word engine; Codex's source-operator artifact is consumable as DATA
(letters, residue matrices, boundary selectors), not through its code path.

## 2. Design: a general final-layer route on BuildObservableTransport's machinery

Name: `BuildRationalEpsilonLayerTransport` (public), private helpers
`observableTransportRationalLayer*`. No family name in package code; every
CF303 fact enters as data of the input records.

Inputs.
- `source`: the transported upper part -- an accepted `BuildObservableTransport`
  result (operator automaton: first/second alphabet indices, operator
  matrices, boundary operators) OR a declared source-operator record
  `<|"Letters", "Residues" (constant matrices per letter), "BoundarySelectors" (by order), "Dimension"|>`
  (the shape of Codex's artifact, so CF303's source layer is consumable as
  data); typed refusal `SourceLayerNotAccepted` otherwise.
- `layer`: the final layer `<|"Rows", "Diagonal" -> {letter -> constant residue matrix}, "Incoming" -> entries {targetRow, sourceColumn, terms {coefficient(eps, path variable), letter label}}, "PathVariable", "BasePoint", "Regulator", "Alphabet" -> declared letter grammar, "Curve" -> Y^2 = P4 (optional)|>`.
- `demand`: the `(order, row)` pairs of the final rows and the boundary
  order window.

Steps, each with a typed status.
1. Alphabet gate (`observableTransportRationalLayerAlphabetQ`): a letter is
   admitted only as `{"GPLPole", c}` (dlog of `u - c`), `{"GPLFactor", q, k}`
   (`u^k du/q(u)`, `q` square-free, expands to poles at the roots of `q`),
   or -- ONLY when a curve `Y^2 = P4(u)` is declared and the degree is 4 --
   `{"E4Pole", c}`, `{"E4Factor", q, k}`, `{"E4Omega0"}`, `{"E4OmegaInf"}`;
   any other label is `AlphabetLetterNotAdmitted` with the label; a curve
   letter without a curve is `CurveDeclarationRequired`.
2. Epsilon window: every incoming coefficient is a rational function of eps
   (refusal `IncomingNotRationalInEpsilon` otherwise); its valuation is
   CERTIFIED with the round-4 machinery (exact univariate order at random
   rational points of `(p, u)`, three points, claim never above the
   observation, fingerprint) -- `LayerValuationUncertified` otherwise; the
   needed window follows from the demand as in `observableTransportLaurentRowHighs`.
3. Laurent expansion: one `Series` per incoming coefficient to its row's cap
   (the round-4 Series route, `observableTransportLaurentEntrySeries`),
   giving per order `n` the one-form matrix `B_n = Sum_terms c_(n,term)(u) omega_term`.
4. Path gauge, order by order (`K_n = B_n + D H_(n-1) - H_(n-1) S - dH_n`,
   `H_n(base) = 0`): for each order the coefficient functions of `u` are
   Hermite-reduced -- rational channel: exact part `dh` + simple-pole
   residues (the residue part is dlog again); elliptic channel (curve
   letters): exact part + simple poles + the cohomology basis. Executed as a
   SEALED CIRCUIT: the coefficient functions are compiled once by the
   finite-field compiler (`observableTransportFFCompile*`) with `u` and `p`
   as variables, the recurrence and the Hermite reductions run over `F_q[u]`
   at specialized `(p, prime)` images, never in characteristic zero; the
   nodes are recorded (order, row, column, channel).
5. Demanded maps only: the one-incoming-edge grammar enumerates the words
   that reach a demanded `(order, row)`; their coefficients are assembled
   from the modular images and rationally reconstructed across primes
   (CRT + rational reconstruction from `Core/ModularArithmetic.wl`), then
   validated at a fresh prime; anything not demanded is never
   reconstructed. Curve-channel words are typed `CurveChannelNotReconstructed`
   until the elliptic Hermite is in place.
6. Certificate: `<|"Status" -> "RationalEpsilonLayerTransportAccepted", "Probabilistic" -> True, "Exact" -> False, "Primes", "FreshValidationPrime", "RecurrenceComparisons", "BasePointComparisons", "DemandedWords", "ValuationCertificate", "AlphabetCertificate"|>`
   and a public predicate `AcceptedRationalEpsilonLayerTransportQ` that
   re-checks the shape and binding, in the style of `AcceptedObservableTransportQ`.
   Lower-block exceptions (a source block whose forcing is not in the
   declared incoming entries) are `LowerBlockExceptionRequired` with the
   block list -- never a silent omission; the physical gauge convolution is
   a declared optional step (`PhysicalGaugeNotApplied` when absent).

Order of implementation (stages 2-4): rational channel first on synthetic
2x2/3x3 fixtures with a direct characteristic-zero Series/recurrence
reference (SameQ on the demanded coefficients) and the typed refusals; then
the curve alphabet gate and the elliptic channel; then CF303's Wolfram-
readable inputs (source operator as data, 76-entry transfer, T25) under a
900 s cap with the exception blocks reported as typed refusals; then the
optimizations with before/after per stage.


## 3. Stage 2: the route on synthetic fixtures (rational channel)

Code: `FeynFacet/Private/Transport/Observable/RationalEpsilonLayer.wl` (new,
registered in `Private/LoadOrder.wl` after the finite-field compiler; the
two public names `BuildRationalEpsilonLayerTransport` and
`AcceptedRationalEpsilonLayerTransportQ` declared in `FeynFacet.m`).
Functions and what they do:

- `rationalLayerAlphabetGate` / `rationalLayerLetterFormQ`: the typed
  alphabet -- `{"GPLPole", c}` (numeric c) and `{"GPLFactor", q, k}` (q
  square-free with rational coefficients, k below the degree) admitted;
  `E4Pole`/`E4Factor`/`E4Omega0`/`E4OmegaInf` admitted only with a
  declared curve (`CurveDeclarationRequired` otherwise) and their channel
  refused typed (`CurveChannelNotImplemented`); anything else
  `AlphabetLetterNotAdmitted` with the label.
- `rationalLayerPoleFactors`: the pole alphabet = monic square-free
  factors over Q of the letter polynomials and of the incoming
  coefficients' u-denominators, pairwise coprime.
- `rationalLayerHermite`: Hermite reduction over `F_q[u]`
  (Horowitz-Ostrogradsky: `f = d(B/D*)/du + C/D-`, one linear solve
  `Modulus -> q`), `rationalLayerPartialFractions`: the residue part on the
  declared factors by extended gcd (a factor outside the alphabet is the
  typed `ResiduePoleNotInAlphabet`).
- `rationalLayerRecurrenceImage`: one prime image of the sealed circuit:
  `Omega_n = B_n + D_1 H_(n-1) - H_(n-1) S_1` over `F_q(u)`, Hermite per
  entry, `H_n(base) = 0`, `K_n` residues on the alphabet; the leaves
  (Laurent coefficients, already specialized in every parameter but u)
  are reduced modulo q at entry (`Together[..., Modulus -> q]`).
- `BuildRationalEpsilonLayerTransport`: input validation (typed), lower-
  block exception detection (`LowerBlockExceptionRequired` with the
  columns, unless declared `ZeroColumns`), `PathParameterNotSpecialized`,
  `IncomingNotRationalInEpsilon`, `MixedEpsilonPathDenominator`, the
  epsilon window certified by the round-4 exact order at three rational
  points of u, one `Series` per incoming coefficient
  (`observableTransportLaurentEntrySeries`), N prime images + CRT +
  rational reconstruction of every K residue, a FRESH prime that
  recomputes the circuit and compares every residue
  (`FreshPrimeValidationFailed` on any mismatch), the demanded words by
  the one-incoming-edge grammar (`rationalLayerWords`, canonical letter
  order), the certificate and `GaugeStatus -> "GaugeNotReconstructed"`
  (H kept as modular images only, as in Codex's route).

Test `Tests/Transport/t_rational_epsilon_layer.wls`: a 2x2 final layer
over a 2-master dlog source (poles -1, 2 and the irreducible quadratic
`u^2 + 1`), incoming coefficients with valuation -2 and both a double
pole at a linear factor and a double pole at the quadratic factor (so
the Hermite gauge is genuinely exercised), demand orders -2..0 for both
rows. Reference: an INDEPENDENT characteristic-zero computation --
`Series` in eps, `Apart`, and a Hermite reduction by the extended-gcd
step `N/Q^k -> d[-B/((k-1)Q^(k-1))] + (A + B'/(k-1))/Q^(k-1)` (not the
route's linear-algebra reduction), the recurrence in exact arithmetic.
Assertions: accepted by the predicate; the reconstructed K residues SameQ
with the reference on all nine (order, factor, power) keys; the order-0
gauge image equals the exact gauge at u = 3 modulo every prime used; the
demanded word coefficients (1, 0, 7, 5, 26, 23 words for the six pairs)
SameQ with those built from the reference residues; the typed refusals
(curve letter without curve, curve channel, unknown head, non-rational
eps, lower-block exception with and without the zero declaration,
unspecialized parameter, malformed letter, tampered certificate).
Verdict: 12 assertions, 0 failed, 3.2 s after load (seat launcher, 300 s cap); route 0.07 s on the fixture.
Defects caught by the test on the way, all in my own code: the alphabet
gate's `FreeQ[..., Except[...]]` matched the list itself (every factor
letter refused); `Set` into an association element by Part; `Mod` of a
rational at the base point; the target-selector padding side; negative
word weights; and, in the REFERENCE, a plain `Integrate` of
`1/(u^2+1)^2`-type terms that swallows an arctangent -- a residue -- into
the exact part (the route's Horowitz-Ostrogradsky value 4 at
`{-1, u^2+1, 0}` is the correct one, checked by hand:
`2(u^2+3)/(u^2+1)^2 = d[2u/(u^2+1)] + 4/(u^2+1)`).

What the census of CF303's accepted inputs says for stage 3
(`scratchpad/round4/T/round8/cf303_census.wls`): the 76-entry transfer's
892 letter terms have coefficients rational in `(eps, p)` ONLY (no u), so
its incoming connection is already dlog at every eps order -- the gauge
H vanishes and the route reduces to the weighted-word grammar with the
Laurent residues; the Hermite gauge is needed for the seven exception
forcings, which exist only as Maple text. 96 terms in 16 of the 76
entries carry curve letters; 60 entries are purely rational. The source
operator (43 masters, 107 letters) has 21 curve letters, 9 composite
elliptic letters and 14 `GPLPole` positions that are algebraic in p
(`+-2 Sqrt[p^2 - p]`, written through the endpoint variable); its
residues have 3,589 nonzero entries, boundary orders -2..5.


## 4. Stage 3: CF303's accepted inputs through the route (read only; outputs under `CF303/rational_layer_2026-09-02/`)

Adapter (scratch, `scratchpad/round4/T/round8/cf303_adapter.wls`; the
package stays family-neutral): Codex's accepted artifacts
`cf303_hybrid_elliptic_operator_15_17_21.wl` (source operator: 43
masters, 107 letters, sparse 43x43 residues, boundary selectors for
orders -2..5 with 287 columns) and `cf303_block25_general_elliptic_transfer.wl`
(76 entry records, 892 letter terms) are specialized at the fixed path
parameter `p = 9/8` and endpoint `uFinal = 3/2`: at that p, `p^2 - p =
9/64`, so the fourteen algebraic pole positions `+-2 Sqrt[p^2 - p]` are
the rationals `+-3/4` and every rational letter of the source is a
genuine `GPLPole`/`GPLFactor` over Q (0 radical poles left). The
diagonal's six letters get residue matrices from the three constant
generators through `ConstantCompositeKernels`; the four diagonal entry
records of the transfer are dropped (they are the eps-linear diagonal,
already represented); the 72 off-diagonal records give 874 incoming
terms, 778 with rational letters, over 36 of the 43 source columns.
The seven columns with no incoming entry are masters
{{1, 2, 12, 21, 22, 29, 30}} -- exactly the support set of Codex's
exception blocks -- and the route names them:

| run | input | status | facts |
|---|---|---|---|
| 1 | full alphabet (curve letters, composite elliptic letters) | `LowerBlockExceptionRequired`, columns {{1,2,12,21,22,25,26}} = masters {{1,2,12,21,22,29,30}} | the exception check precedes the alphabet gate; with the columns declared the same input is `CurveChannelNotImplemented` (21 source curve letters, 9 composite letters, 96 transfer terms) |
| 2 | rational sub-layer (curve terms and curve/composite source letters dropped), exceptions undeclared | `LowerBlockExceptionRequired`, same columns | typed, 4 s after load |
| 3 | rational sub-layer with the seven columns declared zero -- a MEASUREMENT of the rational channel at scale, NOT a CF303 transport | see below | demand: rows 44-45 at orders -4..-2 (Codex's low orders), boundary orders -2..5, target boundary orders 0..2 |

Defects the CF303 scale exposed in my code (all fixed, fixture test
15/15 after each):

- the first measurement (18:22) was KILLED at the 900 s cap inside the
  word enumeration, everything before it having taken 4 s (Laurent
  expansion of 778 entries 0.6 s, three prime images 0.1 s): the
  enumeration multiplied dense 43x43 residues into dense 43x287
  selectors for every state and every demanded pair. Replaced by sparse
  matrices, the source-word growth computed once per boundary order and
  shared across pairs, and a column/row support test before applying an
  incoming letter (`rationalLayerSourceStates`, `rationalLayerWords`);
  the source words to weight 3 are 89,445 states in 7.2 s;
- the second (18:38) returned an "accepted" status with 0 residues: the
  recurrence image read the layer's rows and columns off the wrong
  level of the Laurent matrix (`Length[First[m]]` = columns, and the
  term count of an expression for the columns), which the 2x2 fixture
  hid by coincidence; the predicate refused it (0 comparisons). Fixed
  (`Dimensions`, checked against the source dimension), a typed
  `LayerResiduesVanish` added, and the fixture test extended with a
  3-master source and a residue-shape assertion;
- the third (18:40) refused typed `ReconstructionNotConverged`: three
  31-bit primes cannot reconstruct residues whose exact values carry
  58-digit numerators over 28-digit denominators (the transfer's
  coefficients). The prime schedule is now lift-and-verify: images are
  added (1.5x steps) until every residue reconstructs, then the fresh
  prime validates; `MaximumPrimeCount` (24) is the typed limit.

- the fourth (18:41) still refused `ReconstructionNotConverged` at the
  20-prime maximum although the exact residues are at most 40 digits
  over 28 (a direct diagnostic showed every modular image equal to the
  exact residue at two primes): at p = 9/8 the source still has twelve
  pole positions in quadratic extensions (`(-32 +- Sqrt[1105])/36`,
  `(18 +- 3 Sqrt[70])/16`, `(-9 +- 3 I Sqrt[55])/32`, ...), which the
  gate had admitted because `NumericQ` is True for them and the modular
  arithmetic then produced inconsistent images (my adapter's radical
  census had used `|` for `||` and reported 0). The gate now refuses an
  algebraic pole position typed (`AlgebraicPoleNotAdmitted`, fixture
  assertion 16/16), and the adapter merges each conjugate pair into one
  `GPLFactor` letter on its minimal polynomial with residues `R+ + R-`
  (power 1) and `-(R+ c- + R- c+)` (power 0), refusing typed when those
  are not rational: six pairs merged, none dropped.

Measurement (run 6, 18:49, 900 s cap; `cf303_adapter_run6.log`), the
rational sub-layer at p = 9/8 with the seven exception columns declared
zero -- a measurement of the rational channel at scale, NOT a CF303
transport:

| stage | wall |
|---|---:|
| artifacts loaded, specialized, conjugate pairs merged | 4.5 s |
| Laurent expansion of 778 incoming entries (one Series each), window {-2, -2} | 0.5 s |
| 12 prime images of the sealed recurrence (adaptive: 8, then 12) | 35.7 s (about 3 s each) |
| CRT + rational reconstruction of 21 residue keys, fresh-prime validation 1,806 comparisons, 0 mismatches | (inside the above) |
| source words grown to weight 3: 89,445 states | 10.0 s |
| demanded words, rows 44-45 at orders -4, -3, -2: 11+11, 231+231, 3,433+3,425 = 7,342 | 0.4 s |
| total, status `RationalEpsilonLayerTransportAccepted`, predicate True | 46.7 s |

Codex's counts for the FULL alphabet at the same orders (all rows, 76-
entry deck): 10, 193, 2,955 internal words; the sub-layer's counts are
per row on the rational sub-alphabet, so they are comparable in size,
not in value. Artifact: `.../CF303/rational_layer_2026-09-02/rational_sublayer_p9d8.wl`
(9.8 MB, provenance note inside: partial, curve letters and exception
columns dropped, p = 9/8).



## 5. Stage 4: optimization with the transport lessons (measure first; before/after per stage)

The stage-3 profile (run 6, 46.7 s) says where the time is: 36 s in the
twelve modular images of the recurrence and 10 s in growing the source
words of every boundary order to the full weight; the Laurent expansion
(one `Series` per entry) is 0.5 s and the word enumeration 0.4 s.

Two levers, both general and both cross-checked on the fixture (test
18/18):

1. `IncomingDlogDirect` (route branch in `BuildRationalEpsilonLayerTransport`,
   certificate `IncomingRoute`): when every incoming coefficient is free
   of the path variable -- the CF303 transfer is of this kind, its
   coefficients are rational in `(eps, p)` only -- each `B_n` is a
   combination of the declared dlog letters with numerical coefficients,
   `Omega_n = B_n` (inductively `H_(n-1) = 0`), and the Hermite gauge
   vanishes identically: the K residues are the exact Laurent
   coefficients on the letters' own factors. No modular image, no
   reconstruction, no fresh prime: `Exact -> True`, `Probabilistic ->
   False`, `GaugeStatus -> "GaugeVanishes"`, and the predicate accepts
   that shape. The sealed circuit remains the route whenever a
   coefficient depends on u (`IncomingRoute -> "Modular"` forces it; on
   the path-free fixture both routes give SameQ residues and words).
2. Demand-pruned source growth (`rationalLayerSourceStates` with
   `weightByOrder`): from a boundary order q only tails of weight at most
   `max(order - q - r)` over the demanded orders and the incoming orders
   present can reach a demanded pair; selectors that cannot reach any
   are not grown at all (for orders -4..-2 with r >= -2 only q <= 0
   matter, and weights at most 2).

Not applied, with the reason: the finite-field compiler's native batch
evaluation (`observableTransportFFCompile*`) would speed up the modular
images, but on this layer they are no longer executed; the per-image
cost (about 3 s: `Together` over `F_q(u)` of 86 entries with 17 pole
factors, Hermite, partial fractions) is recorded for the day a
u-dependent layer -- the exception forcings -- runs through the circuit.

| stage | before (run 6) | after (run 7) |
|---|---:|---:|
| artifacts loaded, specialized, pairs merged | 4.5 s | 4.6 s |
| Laurent expansion, 778 entries | 0.5 s | 0.5 s |
| residues: 12 modular images + reconstruction + fresh prime | 35.7 s | 0.2 s (direct: 21 exact keys, no image, no reconstruction) |
| source words | 10.0 s (89,445 states, every q to weight 3) | < 0.1 s (278 states, only q <= 0 to weight <= 2) |
| demanded words (7,342 for the six pairs) | 0.4 s | 0.4 s (7,342, the same counts 11/231/3,433) |
| total | 46.7 s | 1.1 s (from 46.7 s; 5.8 s with the load) |

Cross-check at scale (run 8, `cf303_adapter_run8.log`): the same input
through the sealed modular circuit (`"IncomingRoute" -> "Modular"`, 12
adaptive primes, 1,806 fresh-prime comparisons, 0 mismatches, 38.9 s --
itself down from 46.7 s by the demand-pruned growth) gives residues SameQ
and demanded words SameQ with the direct route. An intermediate version
of the direct route (run 7) keyed a reducible letter polynomial whole
(`9/16 - u^2`) and counted 10/204/3,039 words against the modular
route's 11/231/3,433; the direct route now decomposes every letter once
over the irreducible pole factors (`Apart` over Q), and the fixture
locks this with a reducible-factor cross-check (test 19/19).

Test inventory of this campaign: `Tests/Transport/t_rational_epsilon_layer.wls`
19/19 in about 3 s after load (acceptance; residues SameQ with the
independent Hermite reference; gauge image at u = 3 modulo every prime;
words SameQ; residue shapes and a 3-master source; enumeration counts and
a typed cap; the direct/modular cross-checks on a path-free layer and on
a reducible factor; the typed refusals: curve letter without curve, curve
channel, algebraic pole, unknown head, non-rational eps, lower-block
exception with and without the zero declaration, unspecialized
parameter, malformed letter, tampered certificate). Every kernel run
went through the seat launcher; all CF303 runs used the 900 s cap, and
the one killed by it (18:22) was diagnosed and fixed rather than retried.

## 6. What remains for a complete CF303 result (honest list)

- The elliptic channel: 21 curve letters and 9 composite elliptic letters
  of the source, 96 curve-letter terms of the transfer (16 of 76
  entries). The gate admits them only with the declared quartic and the
  route refuses their channel typed (`CurveChannelNotImplemented`); the
  Hermite reduction on `Y^2 = P4(u)` (exact part + simple poles + the
  cohomology basis {1, u, u^2}, the `E4Omega0`/`E4OmegaInf` kernels, the
  sheet convention `Yc[c]^2 = P4(c)`) is not in the package. Codex's
  Python reducer has it over `F_q`/`F_q2`; a package version needs the
  same arithmetic plus the reconstruction of `Q(Y)`-valued residues.
- The seven lower-block exception forcings (masters {1,2,12,21,22,29,30}):
  only Maple text (3-72 MB) plus Python-parsed censuses exist; they are
  u-dependent (the sealed circuit's real use) and would need a Wolfram-
  readable export first. The route names them typed
  (`LowerBlockExceptionRequired`); the measurement declared them zero,
  which is why its artifact is labelled partial.
- The physical gauge `T25` (`I_25 = T25 . F_25`, orders 0..2): declared
  optional, not applied (`PhysicalGaugeNotApplied` is the typed status
  the route would carry; the adapter did not pass the gauge).
- The p-dependence: the route runs at a fixed rational p (9/8 here, where
  the algebraic poles are rational and the six remaining conjugate pairs
  merge with rational residues); a result as a function of p needs either
  a p-reconstruction of the residues or one run per needed p, as in
  Codex's route.
- The source layer as data: Codex's 43-master operator was consumed
  directly (letters, sparse residues, boundary selectors); building it
  from a family record through `BuildObservableTransport` needs the
  elliptic blocks 15/17/21, i.e. the same elliptic channel.
- An adversarial review of the certificate's claims: the direct route is
  exact by construction; the modular route's acceptance is probabilistic
  (fresh prime), like the rest of the observable transport.
