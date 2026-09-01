# CF230 observable-transport boundary-kernel bottleneck

Date: 2026-09-01 PDT

The first clean production result after the certified-dlog reuse changes was
CF230. The family computation reported 2,989.475786 s and the pool wrapper
reported 3,012.2 s wall. The exact text artifact is 509,279,040 bytes.

Top-level byte offsets show that this is not primarily GPL word data:

| component | byte interval | approximate size |
|---|---:|---:|
| `BoundaryConstraintMatrix` | 794--26,009 | 25,216 B |
| `BoundaryKernel` | 26,010--498,295,458 | 498,269,449 B |
| first-segment word maps | 498,321,572--499,332,596 | 1,011,025 B |
| two-segment word maps | 499,406,779--509,277,446 | 9,870,668 B |

Thus the generic symbolic `NullSpace` basis is 97.84% of the persisted result.
It has 49 boundary coordinates, constraint rank 15 and closure-rank history
`{17,21,21}`. The physical two-segment maps occupy only about 1.94%.

The completed worker wrote its `.kernel.done` marker at 09:59:37 but did not
release the scheduler. One of eight subkernels was observed sleeping at 0%
while the other seven continued. The broker then used the marker to call
`WaitAll` on a scalar EvaluationObject slot that resubmission could overwrite;
the marker and tracked EvaluationObject were therefore not bound to the same
attempt. The wrapper also retained a generic `Result` field whose `Short`
fallback would still hold a large expression if a mission returned one,
although the current family mission normally returns `Null`. Both hazards
were removed. The run was stopped on the user's instruction after all
completed artifacts and queued missions were preserved.

Optimization target:

1. return only bounded status metadata from pool missions;
2. retain the fast moving-kernel route for structurally small constraints;
3. evolve the sparse Laurent state and impose a constant base-point kernel
   when the generic moving kernel is forecast to swell;
4. reconstruct only demanded maps over finite fields for genuinely hard
   cases, never the full rational boundary-nullspace basis.

## Implemented result

The corrected large-family path now retains an exact lazy operator chain.  It
closes the forbidden row space covariantly in both path directions, evolves
the ambient Laurent state, and forms the boundary kernel only at the constant
base point.  No generic rational moving nullspace and no Cartesian word
inventory are persisted.

Post-fix CF230 measurements on the same host:

| path | wall time | in-kernel size / output | validation |
|---|---:|---:|---:|
| exact `OperatorAutomaton` build | 3.361 s | 2.16 MB `ByteCount` | accepted |
| materialized reference, weight ≤ 2 | 48.104 s | 37.60 MB `ByteCount` | accepted |
| final reconstruction, cached candidate | 15.156 s | 3.54 MB solution | 120/120 maps |
| final reconstruction, fresh candidate | 37.096 s | 3.54 MB solution | 120/120 maps |

The fresh final run spends 1.733 s tracing and 2.415 s in reconstruction.  Its
remaining time is Wolfram batch assembly, equation serialization, parsing and
two fresh full-row modular images.  Shared expression compilation/evaluation,
the known identity-prefix rank, and removal of unused reserve images reduced
the first 88.43 s implementation to 15.16 s on a cache hit.  A subsequent
string-render memoization changed the fresh time by less than one second and
was not treated as a major result.

The post-fix operator and independently regenerated materialized result agree
for all 120 words of weight at most two at three exact rational points.  The
small CF27 stress case builds in 0.323 s (operator) versus 0.693 s
(materialized weight two), with 33/33 maps agreeing.

Correctness fixes discovered during adversarial review are part of this
result: a sampled pivot update can no longer discard an earlier forbidden
row; sampled rank zero cannot erase a symbolic nonzero constraint; and public
acceptance now checks the dimensions of the stored operator/compact payload.
Constrained multiquadratic closure is checked at split finite-field points,
including constant-radicand prime filtering and all eight embeddings in the
three-root regression.
