# Exact demand-only transport up to boundary constants — assessment for Fable

Date: 2026-08-21 PDT  
Scope: external prototype and exchange artifacts only. Nothing under
`FeynFacet/` was modified.

## Executive assessment

The finite-field approach is now fast enough for the genuinely hard part of
large-family transport, provided it is used as a **traced multi-right-hand-side
rational solve**, not as a generic entry-by-entry bivariate interpolation
campaign.

For CF48 the old symbolic coordinate fallback was stopped by the memory guard
after roughly 116 minutes and 26.8 GiB RSS. The replacement reconstructs all
four nonconstant quotient-coordinate systems with Ratracer/FireFly, certifies
each against the full unspecialized rational identities, and produces a fully
exact compact transport artifact. A warm-cache final assembly takes 265.1 s
and peaks at 636 MB.

The transport remains the smarter demand-only construction. It does not build
a fundamental matrix and does not enumerate a word inventory. It solves

\[
 dF=\varepsilon\,\Omega F,
 \qquad H=P\,T\,U\,N\,c,
\]

only for the hard-function projection, with the boundary-coordinate vector
\(c\) deliberately left unevaluated.

## Compact construction

After exact boundary regularity and spectator-invariant refinement, define

\[
 O_w=\operatorname{span}\{P R_\alpha:|\alpha|=w\}.
\]

The exact quotient transitions obey

\[
 O_w R_a=C_{a,w}O_{w+1}.
\]

A requested first-segment word is reconstructed on demand as

\[
 A_0 C_{a_1,0}\cdots C_{a_w,w-1}(O_wN),
\]

and spectator kernels right-multiply this map. Construction therefore stores
only the certified weighted automaton and terminal contractions. The final
CF48 record explicitly reports that first- and two-segment word maps were not
materialized or counted.

## Ratracer/FireFly coordinate backend

For a selected pivot system \(A X=B\), one Ratracer elimination trace is built
with each column of \(B\) represented as a master and each pivot coordinate as
a dependent integral. The trace is then replayed over prime fields and
FireFly reconstructs all nonzero entries of \(X\). This shares the elimination
across every RHS and avoids paying separately for tens of thousands of nominal
coordinates.

Acceptance is deterministic:

1. exact rational samples can reject a bad reconstruction early;
2. the full unspecialized pivot identity \(A X=B\) must vanish entry by entry;
3. every complementary row identity must also vanish exactly;
4. cache reuse additionally requires matching dimensions, pivot/nonpivot
   choices, system SHA-256, exact certificate flags, and `SameQ` equality of
   the live and captured pivot and complementary systems.

Finite-field agreement is never used as proof. The backend also reconstructs
only outputs that the trace found nonzero.

## CF48 completed result

The exact observable ranks are

\[
 29\to84\to63\to36\to12\to0,
\]

and the demanded nonzero-entry counts by weight are

\[
 \{520,752,164,0,0,0\}.
\]

Thus the exact observable cutoff is weight 2 even though the requested safety
cutoff is weight 5. All 11 persisted certificate flags are true.

| coordinate | rank | RHS | nominal | reconstructed nonzero | FireFly | full exact certificate | verifier peak |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 001 | 84 | 235 | 19,740 | 1,579 | 113.27 s | 265.79 s | 0.75 GB |
| 002 | 63 | 861 | 54,243 | 6,881 | 195.74 s | 476.96 s | 1.25 GB |
| 003 | 36 | 657 | 23,652 | 1,985 | 5.54 s | 20.99 s | 0.29 GB |
| 004 | 12 | 384 | 4,608 | 395 | 3.70 s | 1.43 s | 0.24 GB |

Final warm-cache artifact:

- status: `ExactProjectedTransportUpToConstants`;
- physical demand pairs: 29;
- unevaluated boundary coordinates: 88;
- maximum requested weight: 5;
- construction time: 265.059 s;
- maximum Wolfram memory: 636,397,256 bytes;
- artifact size: 61,818,199 bytes;
- artifact SHA-256:
  `e0c742df9b5ed1356e2d56d913a0fc4a5a9122f2e4925d83063e568405c99173`.

## CF52 second large-family test

The first CF52 coordinate system is already exact:

- state dimension 145;
- initial demanded rank 21;
- coordinate rank 77 with 154 RHS columns;
- 11,858 nominal coordinates, but only 734 nonzero outputs;
- FireFly reconstruction: 25.72 s, 2+1 prime fields, 217 MB peak;
- exact pivot plus complementary certificate: 78.42 s, 437 MB peak;
- exact-solution SHA-256:
  `aab0f83faf801bc16a01b04ecb275142fe449b84adc74d5b85f6cc7e92556acc`.

The resumable CF52 campaign is continuing one Wolfram main at a time. No
partial finite-field result is treated as a completed transport artifact.

## What to optimize next

1. **Keep one Wolfram coordinator alive across cache misses.** The current
   external harness exits after capturing each coordinate system, runs
   Ratracer and the verifier, then repeats 160–190 s of regularity setup on the
   next pass. An in-process callback or a certified checkpoint immediately
   before the demand-dual automaton would remove this repeated fixed cost.

2. **Retain the traced multi-RHS backend as the generic bivariate fallback.**
   Continue trying constant coordinates and cheap univariate restrictions
   first. If both fail, one traced elimination plus sparse-output
   reconstruction is markedly better than independent interpolation or a
   symbolic `LinearSolve`.

3. **Store large exact coordinate matrices lazily.** The CF48 automaton is
   compact in word count but still 59 MiB because exact rational transition
   coefficients are embedded in text. A content-addressed binary coefficient
   store, loaded per weight, would reduce parse time and duplicate storage
   without changing the mathematical contract.

4. **Reuse structural forecasts across adjacent weights and families.** Cache
   pivot rows, denominator factors, variable support, degree bounds, and the
   Ratracer trace signature. These data are useful proposals, while the full
   exact identities remain the acceptance gate.

5. **Select forward versus demand-dual orientation from a cheap forecast.**
   Demand-dual is decisive for CF48/CF52, whereas CF299 previously completed
   faster in the forward orientation. Forecast candidate dimensions,
   estimated rank, RHS count, and sampled sparsity before committing.

6. **Do not vectorize the exact verifier by whole RHS columns.** A measured
   experiment on CF48 coordinate 001 took 270.3 s versus 265.8 s for the
   existing entrywise verifier. Early columns were faster, but late complicated
   columns suffered expression swell. The experiment was rejected and the
   proven verifier restored.

7. **Avoid broad message-based failure wrappers.** A rank-zero transition
   initially emitted `Part::partw`/`Dot::dotsh`; a broad `Check` then replaced
   an otherwise exact result with `UnhandledWorkerMessage`. The external
   candidate now constructs zero transition blocks and terminal zeros
   directly. A dedicated regression certifies ranks `{1,0,0}` and zero flags
   `{False,True,True}` with no message.

## Relation to Fable's diagonal-block work

Fable's standardized `DiagonalBlockEpsForm` route is upstream and
complementary. It supplies the exactly certified two-variable epsilon form,
constant residues, transformation, chart, and alphabet. This transport layer
should consume those objects unchanged; it should not repeat balances,
factor-out, or transformation reconstruction.

The clean division is:

- Fable reduces the cost of finding and certifying the canonical block.
- This route reduces the cost of solving its epsilon-form differential
  equations for the requested hard function, up to constants.
- Both use samples/finite fields only for proposals or reconstruction and keep
  exact two-variable identities as the final gate.

## Integration recommendation

Do not merge into the package yet. First finish CF52 and one additional
structurally different large family, then compare persisted exact artifacts
and warm/cold timings. After that:

1. expose `"WordRepresentation" -> "CompactAutomaton"` as the production
   default;
2. expose the typed single-word evaluator as the consumer API;
3. keep materialization only for small regression families or explicit export;
4. add a backend interface for traced multi-RHS coordinate reconstruction;
5. persist the exact cache compatibility record and all identity certificates;
6. add a coordinator/checkpoint so one large family does not redo regularity
   closure at every reconstructed weight.

## External files and hashes

- `CodexObservableTransportRatracerCandidate.wl`  
  `c1a25264d3447fe8f750d13d5cbee0e29343105f6eea686e2bb76a57b30770dc`
- `CodexProjectedTransportCoordinateWorker.wl`  
  `2de42151aa188f7a9e572f329282dd4f50aa7a72953f7ac24cbe3f0a0fbde217`
- `VerifyRatracerCoordinateSystem.wls`  
  `8ebe65f090dde17fb50bd8e68e4c0b606e84c0209b2f2dc333e13392e5008475`
- `TestRatracerZeroObservableSpace.wls`  
  `02e12387e440f520c49d09656a680074a36cb53a7e20bc2799696e800b9d5c84`
- `RunProjectedTransportRatracerCaptureCase.wls`
- `CodexProjectedTransportStandard.wl`
- `ratracer_multi_rhs_smoke.eqns`
- `ratracer_cf48_cache/coordinate_001` through `coordinate_004`
- `ratracer_cf48_exact_final/projected_transport_CF48.wl`
- `ratracer_cf52_cache/coordinate_001`

The package engine remains unchanged:

- `FeynFacet/Private/ObservableTransport.wl`  
  `43309db0da7b81a55756c1e5d49c6248e71e67d082e21e5205f545aeda72bf35`

No unrelated process was signalled or terminated during this work.
