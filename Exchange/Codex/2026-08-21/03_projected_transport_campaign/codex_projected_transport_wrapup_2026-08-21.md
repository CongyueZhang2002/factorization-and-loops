# Projected epsilon-form transport: Codex wrap-up

Date: 2026-08-21 PDT  
Scope: external prototype only; no package integration.

## Bottom line

The demand-only transport design is working and remains the correct approach:
solve the standardized epsilon-form differential equation only for the hard
function projection and only up to its boundary constants. Do not construct a
fundamental matrix and do not enumerate the full word inventory.

CF48 is complete and exact. CF52 coordinate 001 is complete and exact.
CF52 coordinate 002 completed its Ratracer/FireFly rational reconstruction,
but its full symbolic certificate had not finished when the run was wrapped.
It is therefore a **reconstructed proposal, not an accepted exact result**.
There is no completed CF52 transport artifact yet.

The one-main coordinator succeeded in eliminating repeated setup between
coordinate misses. The next bottleneck is no longer finite-field elimination:
it is loading and exactly certifying a very large reconstructed coordinate
matrix in Wolfram.

At 18:59 PDT I stopped only the Codex launch group (shell `1141876`,
`wolframscript` `1141882`, Wolfram kernel `1141914`). All three exited. The
separate Fable/user Wolfram job visible at wrap-up remained running and was not
signalled.

## Mathematical and computational contract

For

\[
 dF=\varepsilon\,\Omega F,
 \qquad H=P\,T\,U\,N\,c,
\]

the external engine applies exact boundary regularity, spectator-invariant
refinement, and a demand-dual weighted automaton. If

\[
 O_w=\operatorname{span}\{P R_\alpha:|\alpha|=w\},
\]

then only the quotient transitions

\[
 O_w R_a=C_{a,w}O_{w+1}
\]

needed by the requested hard projection are retained. Boundary coordinates
`c` remain unevaluated. Requested words are evaluated through the certified
small transition chain rather than through a materialized fundamental
solution.

For a hard quotient step, the backend captures one exact multi-RHS system
`A X = B`. Ratracer traces the elimination once; FireFly reconstructs all
nonzero entries of `X` together. Samples are rejection filters only. Acceptance
requires both unspecialized rational identities

\[
 A_{\rm pivot}X=B_{\rm pivot},\qquad
 A_{\rm complement}X=B_{\rm complement}
\]

to vanish exactly.

## External-only implementation completed

`CodexObservableTransportRatracerCandidate.wl` now contains an optional
one-main coordinator enabled by `CODEX_RATRACER_INLINE=1`:

1. capture a cache miss;
2. build a Ratracer trace;
3. run one-thread FireFly reconstruction;
4. parse the rational proposal;
5. apply exact sample rejection and full pivot/complement certificates;
6. atomically persist an exact cache entry;
7. continue the demand-dual automaton in the same Wolfram main.

This removes the former exit/restart cycle and avoids repeating the CF52
regularity prefix at every weight. The prefix measured 155.341 s in the final
run.

The candidate also reuses an already-proved coordinate certificate. Constant,
univariate-slice, and Ratracer coordinates already pass the exact pivot and
complement identities before returning, so the outer basis routine no longer
reconstructs the identical complement residual. The symbolic fallback still
passes the full exact residual gate. The CF52 coordinate-001 cache hit exercised
this path and advanced immediately.

The rank-zero transition bug is also fixed: zero transition and terminal
blocks are constructed with their correct shapes rather than reaching invalid
`Part`/`Dot` operations. Its dedicated regression passes.

## Completed reference: CF48

The exact observable ranks are

\[
 29\to84\to63\to36\to12\to0,
\]

with demanded nonzero entries by weight

\[
 \{520,752,164,0,0,0\}.
\]

All 11 persisted certificate flags are true. Warm-cache construction took
265.059 s and peaked at 636,397,256 Wolfram bytes. The exact transport artifact
is 61,818,199 bytes with SHA-256
`e0c742df9b5ed1356e2d56d913a0fc4a5a9122f2e4925d83063e568405c99173`.

## CF52 status at wrap-up

The final one-main run established:

- lifted state dimension: 145;
- initial demanded rank: 21;
- constrained boundary dimensions: `{145,88}`;
- observed rank path before interruption: `21 -> 77 -> 64`;
- regularity closure: 155.341 s;
- coordinate 001 cache reuse: exact and immediate;
- coordinate 002 finite-field reconstruction: complete;
- coordinate 002 exact symbolic certificate: incomplete;
- final CF52 transport artifact: absent.

### Coordinate 001 (accepted exact)

- rank 77, 154 RHS columns;
- 11,858 nominal coordinates, 734 reconstructed nonzero;
- exact sample flags `{True,True,True}`;
- pivot identity `True`, complement identity `True`;
- parse 0.435 s, samples 1.946 s;
- pivot exact gate 66.987 s, complement exact gate 7.943 s;
- total certification record 78.419 s;
- maximum Wolfram memory 436,880,456 bytes;
- exact MX SHA-256
  `aab0f83faf801bc16a01b04ecb275142fe449b84adc74d5b85f6cc7e92556acc`.

### Coordinate 002 (reconstructed, not accepted)

- captured matrix dimensions `{145,847}`;
- rank 64, 783 RHS columns;
- 50,112 nominal coordinates;
- 8,814 reconstructed nonzero coordinates;
- factor scan 173.333 s, 34,978 identified factors;
- full reconstruction 2,113.506 s and 46,135 probes;
- required prime fields `4 + 1`;
- Ratracer process maximum RSS 5.64 GB;
- rational solution text 405,849,877 bytes.

The solution text was written at 17:39 PDT. At wrap-up around 18:59 PDT, no
`coordinate_solution_exact.mx` existed. During the unfinished Wolfram exact
gate I observed RSS reach 20,510,068 KiB (about 20.5 GB decimal). Thus neither
the rational reconstruction nor any derived coordinate matrix should be used
as exact input until the missing identities are fully certified.

The valuable checkpoint is intact: exact captured system, Ratracer equations,
trace, output list, reconstructed rational text, and logs. A verifier redesign
can reuse these files without repeating the 35-minute reconstruction.

## Diagnosis and next implementation

The current verifier imports all 405.85 MB of text, extracts every expression,
constructs a complete sparse coordinate matrix, and then checks entries in
row-major order. Each check forms `basis[[row]] . coordinates[[All,column]]`.
This keeps all reconstructed expressions live and causes severe expression and
memory growth. Whole-column symbolic matrix multiplication was already tested
on CF48 and was slightly slower, so simply vectorizing the same full in-memory
calculation is not the answer.

The next implementation should be an **exact column-streamed certificate**:

1. index or scan `coordinate_solution.txt` by RHS/master column without
   importing the whole file;
2. construct one sparse rank-64 coordinate vector at a time, treating omitted
   trace outputs as zero;
3. certify every pivot and complementary row identity for that column exactly;
4. atomically persist a column shard containing system hash, solution-text
   hash, column number, sparse coordinates, and both exact flags;
5. clear the column expressions before reading the next column;
6. accept the full coordinate transition only when all 783 column shards are
   present and their coverage and hashes match exactly;
7. expose the certified transition through a lazy/content-addressed store so
   later weights do not require one giant parsed expression to stay resident.

Columnwise exact identities are mathematically equivalent to the full matrix
identity. This changes memory lifetime and checkpoint granularity, not the
acceptance standard. Finite-field checks may still reject early, but must never
set an exact certificate flag.

Secondary optimizations, after the streaming gate works:

- iterate column outermost even in the in-memory verifier;
- reuse the existing trace, factor information, and rational output on resume;
- cache structural forecasts (pivot rows, supports, factors, degrees) only as
  proposals;
- choose forward versus demand-dual orientation from sampled rank/RHS/sparsity
  forecasts;
- keep exact transition matrices in binary shards and load only the weight
  required by a requested word.

## Relation to Fable's completed work

Fable's diagonal-block engine is upstream and complementary. Its numeric-
regulator modular balance route now certifies all 173 stage-1 classes in
204.5 s wall with four subkernels, and A2/A3/A4 have been standardized into
the package. Those routines deliver exact standardized epsilon forms,
transformations, residues, charts, and alphabets. This external transport
prototype should consume them unchanged and solve only the downstream
differential equation up to constants.

FLINT accelerates the modular constrained solves in Fable's standardization
stage. It does not replace the unspecialized rational identity gate needed for
transport.

## Reproducibility inventory

External bundle:
`External/CodexExchange/codex_projected_transport_2026-08-21/`.

Important code hashes:

- `CodexObservableTransportRatracerCandidate.wl`:
  `319dfebd8414d60000bc56e182cf5727f0a7fb1d73b5efd739d9ccf667368faa`;
- `CodexProjectedTransportCoordinateWorker.wl`:
  `2de42151aa188f7a9e572f329282dd4f50aa7a72953f7ac24cbe3f0a0fbde217`;
- `VerifyRatracerCoordinateSystem.wls`:
  `8ebe65f090dde17fb50bd8e68e4c0b606e84c0209b2f2dc333e13392e5008475`;
- `TestRatracerZeroObservableSpace.wls`:
  `02e12387e440f520c49d09656a680074a36cb53a7e20bc2799696e800b9d5c84`.

Coordinate-002 checkpoint hashes:

- exact captured system (`coordinate_system_exact.mx`, 1,500,240 bytes):
  `2c116dd46e1bd469f91875a06a7c479431214cf33c547ed9c2a04410cefe4f2c`;
- Ratracer equations (`coordinate_system_ratracer.eqns`, 2,441,828 bytes):
  `26db84ef6033c25ad70cbc340bbdfcf51986152155d4196308ddeef552b7523b`;
- trace (`coordinate_system.trace.gz`, 2,047,154 bytes):
  `799d6d89bcf2be1cd7ab34a545a8025a4003928f8ede486cbd6809fbd324e62e`;
- reconstructed text (`coordinate_solution.txt`, 405,849,877 bytes):
  `87d0207be055d02469c3d511e6db37b5fef103d732c01496cff3a53d442bb36e`;
- reconstruction log:
  `bb48958b2d4e30143af24390dee2b29095aca3b1b6743f896a918352981b7db3`.

The package engine remains unchanged:

- `FeynFacet/Private/ObservableTransport.wl`:
  `43309db0da7b81a55756c1e5d49c6248e71e67d082e21e5205f545aeda72bf35`.

## Recommendation

Do not merge this prototype yet. Implement the streaming exact certificate,
finish CF52 from the existing coordinate-002 checkpoint, and then run one
structurally different large family. Only after those exact results should the
compact automaton, traced multi-RHS backend, lazy coefficient store, and cache
compatibility record be proposed for package integration.
